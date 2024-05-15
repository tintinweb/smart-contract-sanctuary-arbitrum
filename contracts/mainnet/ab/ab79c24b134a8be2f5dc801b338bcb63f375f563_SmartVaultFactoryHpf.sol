// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/proxy/beacon/UpgradeableBeacon.sol";
import "./interfaces/IAction.sol";
import "./interfaces/IAssetGroupRegistry.sol";
import "./interfaces/IGuardManager.sol";
import "./interfaces/IRiskManager.sol";
import "./interfaces/ISmartVault.sol";
import "./interfaces/ISmartVaultManager.sol";
import "./interfaces/ISpoolAccessControl.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/CommonErrors.sol";
import "./interfaces/Constants.sol";
import "./interfaces/RequestType.sol";
import "./access/Roles.sol";
import "./access/SpoolAccessControllable.sol";
import "./SmartVault.sol";
import "./SmartVaultFactory.sol";

/* ========== CONSTANTS ========== */

/**
 * @dev Maximal smart vault performance fee that can be set on a smart vault using this factory. Expressed in terms of FULL_PERCENT.
 */
uint256 constant SV_PERFORMANCE_FEE_HIGH_MAX = 90_00;

/**
 * @dev Grants permission to deploy smart vaults via the SmartVaultFactoryHpf.
 */
bytes32 constant ROLE_HPF_SMART_VAULT_DEPLOYER = keccak256("HPF_SMART_VAULT_DEPLOYER");

/* ========== CONTRACTS ========== */

/**
 * @notice Factory for deploying smart vaults with high performance fees.
 * @dev Requires roles:
 * - ROLE_SMART_VAULT_INTEGRATOR
 * - ADMIN_ROLE_SMART_VAULT_ALLOW_REDEEM
 */
contract SmartVaultFactoryHpf is UpgradeableBeacon, SpoolAccessControllable {
    using uint16a16Lib for uint16a16;

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when a new smart vault is deployed.
     * @param smartVault Address of the newly deployed smart vault.
     * @param deployer Address of the deployer.
     */
    event SmartVaultDeployed(address indexed smartVault, address indexed deployer);

    /* ========== CONSTANTS ========== */

    /**
     * @notice Action manager contract.
     */
    IActionManager immutable _actionManager;

    /**
     * @notice Guard manager contract.
     */
    IGuardManager immutable _guardManager;

    /**
     * @notice Smart vault manager contract.
     */
    ISmartVaultRegistry immutable _smartVaultRegistry;

    /**
     * @notice Asset group registry contract.
     */
    IAssetGroupRegistry immutable _assetGroupRegistry;

    /**
     * @notice Risk manager contract.
     */
    IRiskManager immutable _riskManager;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address implementation,
        ISpoolAccessControl accessControl_,
        IActionManager actionManager_,
        IGuardManager guardManager_,
        ISmartVaultRegistry smartVaultRegistry_,
        IAssetGroupRegistry assetGroupRegistry_,
        IRiskManager riskManager_
    ) UpgradeableBeacon(implementation) SpoolAccessControllable(accessControl_) {
        if (address(accessControl_) == address(0)) revert ConfigurationAddressZero();
        if (address(actionManager_) == address(0)) revert ConfigurationAddressZero();
        if (address(guardManager_) == address(0)) revert ConfigurationAddressZero();
        if (address(smartVaultRegistry_) == address(0)) revert ConfigurationAddressZero();
        if (address(assetGroupRegistry_) == address(0)) revert ConfigurationAddressZero();
        if (address(riskManager_) == address(0)) revert ConfigurationAddressZero();

        _actionManager = actionManager_;
        _guardManager = guardManager_;
        _smartVaultRegistry = smartVaultRegistry_;
        _assetGroupRegistry = assetGroupRegistry_;
        _riskManager = riskManager_;
    }

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Deploys a new smart vault into the Spool ecosystem.
     * @dev Requirements:
     * - caller must have role ROLE_HPF_SMART_VAULT_DEPLOYER
     * @param specification Specifications for the new smart vault.
     * @return smartVault Deployed smart vault.
     */
    function deploySmartVault(SmartVaultSpecification calldata specification)
        external
        onlyRole(ROLE_HPF_SMART_VAULT_DEPLOYER, msg.sender)
        returns (ISmartVault)
    {
        _validateSpecification(specification);

        address smartVaultAddress = address(
            new BeaconProxy(
                address(this),
                _encodeInitializationCalldata(specification)
            )
        );

        _integrateSmartVault(smartVaultAddress, specification);

        emit SmartVaultDeployed(smartVaultAddress, msg.sender);

        return ISmartVault(smartVaultAddress);
    }

    /**
     * @notice Deploys a new smart vault to a deterministic address.
     * @dev Requirements:
     * - caller must have role ROLE_HPF_SMART_VAULT_DEPLOYER
     * @param specification Specifications for the new smart vault.
     * @param salt Salt for address determination.
     * @return smartVault Deployed smart vault.
     */
    function deploySmartVaultDeterministically(SmartVaultSpecification calldata specification, bytes32 salt)
        external
        onlyRole(ROLE_HPF_SMART_VAULT_DEPLOYER, msg.sender)
        returns (ISmartVault)
    {
        _validateSpecification(specification);

        address smartVaultAddress = address(
            new BeaconProxy{salt: salt}(
                address(this),
                _encodeInitializationCalldata(specification)
            )
        );

        _integrateSmartVault(smartVaultAddress, specification);

        emit SmartVaultDeployed(smartVaultAddress, msg.sender);

        return ISmartVault(smartVaultAddress);
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Predicts deployment address deterministically deployed smart vault.
     * @param specification Specifications for the new smart vault.
     * @param salt Salt for address determination.
     * @return predictedAddress Predicted address.
     */
    function predictDeterministicAddress(SmartVaultSpecification calldata specification, bytes32 salt)
        external
        view
        returns (address)
    {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(
                                abi.encodePacked(
                                    type(BeaconProxy).creationCode,
                                    abi.encode(address(this), _encodeInitializationCalldata(specification))
                                )
                            )
                        )
                    )
                )
            )
        );
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Validates smart vault specification.
     * @param specification Specifications for the new smart vault.
     */
    function _validateSpecification(SmartVaultSpecification calldata specification) private view {
        _assetGroupRegistry.validateAssetGroup(specification.assetGroupId);

        if (specification.strategies.length == 0) {
            revert SmartVaultRegistrationNoStrategies();
        }
        if (specification.strategies.length > STRATEGY_COUNT_CAP) {
            revert StrategyCapExceeded();
        }

        unchecked {
            bool fixedAllocations = uint16a16.unwrap(specification.strategyAllocation) > 0;
            uint256 fullAllocation;

            if (specification.strategies.length == 1 && !fixedAllocations) {
                revert SingleStrategyDynamicAllocation();
            }

            if (fixedAllocations) {
                if (specification.riskProvider != address(0)) {
                    revert StaticAllocationAndRiskProviderSet();
                }

                if (specification.riskTolerance != 0) {
                    revert StaticAllocationAndRiskToleranceSet();
                }

                if (specification.allocationProvider != address(0)) {
                    revert StaticAllocationAndAllocationProviderSet();
                }
            }

            for (uint256 i; i < specification.strategies.length; ++i) {
                if (fixedAllocations) {
                    if (specification.strategyAllocation.get(i) == 0) {
                        revert InvalidStrategyAllocationsLength();
                    }
                    fullAllocation += specification.strategyAllocation.get(i);
                }

                if (!_accessControl.hasRole(ROLE_STRATEGY, specification.strategies[i])) {
                    revert InvalidStrategy(specification.strategies[i]);
                }

                if (IStrategy(specification.strategies[i]).assetGroupId() != specification.assetGroupId) {
                    revert NotSameAssetGroup();
                }

                for (uint256 j = i + 1; j < specification.strategies.length; ++j) {
                    if (specification.strategies[i] == specification.strategies[j]) {
                        revert StrategiesNotUnique();
                    }
                }
            }

            if (fixedAllocations && fullAllocation != FULL_PERCENT) {
                revert InvalidStaticAllocation();
            }
        }

        if (specification.managementFeePct > MANAGEMENT_FEE_MAX) {
            revert ManagementFeeTooLarge(specification.managementFeePct);
        }
        if (specification.depositFeePct > DEPOSIT_FEE_MAX) {
            revert DepositFeeTooLarge(specification.depositFeePct);
        }
        if (specification.performanceFeePct > SV_PERFORMANCE_FEE_HIGH_MAX) {
            revert PerformanceFeeTooLarge(specification.performanceFeePct);
        }
    }

    /**
     * @notice Encodes calldata for smart vault initialization.
     * @param specification Specifications for the new smart vault.
     * @return initializationCalldata Enoded initialization calldata.
     */
    function _encodeInitializationCalldata(SmartVaultSpecification calldata specification)
        private
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSignature(
            "initialize(string,string,string,uint256)",
            specification.smartVaultName,
            specification.svtSymbol,
            specification.baseURI,
            specification.assetGroupId
        );
    }

    /**
     * @notice Integrates newly created smart vault into the Spool ecosystem.
     * @param smartVaultAddress Address of created smart vault.
     * @param specification Specifications for the new smart vault.
     */
    function _integrateSmartVault(address smartVaultAddress, SmartVaultSpecification calldata specification) private {
        _accessControl.grantSmartVaultOwnership(smartVaultAddress, msg.sender);
        _actionManager.setActions(smartVaultAddress, specification.actions, specification.actionRequestTypes);
        _guardManager.setGuards(smartVaultAddress, specification.guards, specification.guardRequestTypes);

        if (specification.allowRedeemFor) {
            _accessControl.grantRole(ROLE_SMART_VAULT_ALLOW_REDEEM, smartVaultAddress);
        }

        uint16a16 allocations = specification.strategyAllocation;

        // set allocation
        if (uint16a16.unwrap(allocations) == 0) {
            _riskManager.setRiskProvider(smartVaultAddress, specification.riskProvider);
            _riskManager.setRiskTolerance(smartVaultAddress, specification.riskTolerance);
            _riskManager.setAllocationProvider(smartVaultAddress, specification.allocationProvider);

            allocations = _riskManager.calculateAllocation(smartVaultAddress, specification.strategies);
        }

        _smartVaultRegistry.registerSmartVault(
            smartVaultAddress,
            SmartVaultRegistrationForm({
                assetGroupId: specification.assetGroupId,
                strategies: specification.strategies,
                strategyAllocation: allocations,
                managementFeePct: specification.managementFeePct,
                depositFeePct: specification.depositFeePct,
                performanceFeePct: specification.performanceFeePct
            })
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
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

import "@openzeppelin/token/ERC20/IERC20.sol";

/* ========== ERRORS ========== */

/**
 * @notice Used when invalid ID for asset group is provided.
 * @param assetGroupId Invalid ID for asset group.
 */
error InvalidAssetGroup(uint256 assetGroupId);

/**
 * @notice Used when no assets are provided for an asset group.
 */
error NoAssetsProvided();

/**
 * @notice Used when token is not allowed to be used as an asset.
 * @param token Address of the token that is not allowed.
 */
error TokenNotAllowed(address token);

/**
 * @notice Used when asset group already exists.
 * @param assetGroupId ID of the already existing asset group.
 */
error AssetGroupAlreadyExists(uint256 assetGroupId);

/**
 * @notice Used when given array is unsorted.
 */
error UnsortedArray();

/* ========== INTERFACES ========== */

interface IAssetGroupRegistry {
    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when token is allowed to be used as an asset.
     * @param token Address of newly allowed token.
     */
    event TokenAllowed(address indexed token);

    /**
     * @notice Emitted when asset group is registered.
     * @param assetGroupId ID of the newly registered asset group.
     */
    event AssetGroupRegistered(uint256 indexed assetGroupId);

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Checks if token is allowed to be used as an asset.
     * @param token Address of token to check.
     * @return isAllowed True if token is allowed, false otherwise.
     */
    function isTokenAllowed(address token) external view returns (bool isAllowed);

    /**
     * @notice Gets number of registered asset groups.
     * @return count Number of registered asset groups.
     */
    function numberOfAssetGroups() external view returns (uint256 count);

    /**
     * @notice Gets asset group by its ID.
     * @dev Requirements:
     * - must provide a valid ID for the asset group
     * @return assets Array of assets in the asset group.
     */
    function listAssetGroup(uint256 assetGroupId) external view returns (address[] memory assets);

    /**
     * @notice Gets asset group length.
     * @dev Requirements:
     * - must provide a valid ID for the asset group
     * @return length
     */
    function assetGroupLength(uint256 assetGroupId) external view returns (uint256 length);

    /**
     * @notice Validates that provided ID represents an asset group.
     * @dev Function reverts when ID does not represent an asset group.
     * @param assetGroupId ID to validate.
     */
    function validateAssetGroup(uint256 assetGroupId) external view;

    /**
     * @notice Checks if asset group composed of assets already exists.
     * Will revert if provided assets cannot form an asset group.
     * @param assets Assets composing the asset group.
     * @return Asset group ID if such asset group exists, 0 otherwise.
     */
    function checkAssetGroupExists(address[] calldata assets) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Allows a token to be used as an asset.
     * @dev Requirements:
     * - can only be called by the ROLE_SPOOL_ADMIN
     * @param token Address of token to be allowed.
     */
    function allowToken(address token) external;

    /**
     * @notice Allows tokens to be used as assets.
     * @dev Requirements:
     * - can only be called by the ROLE_SPOOL_ADMIN
     * @param tokens Addresses of tokens to be allowed.
     */
    function allowTokenBatch(address[] calldata tokens) external;

    /**
     * @notice Registers a new asset group.
     * @dev Requirements:
     * - must provide at least one asset
     * - all assets must be allowed
     * - assets must be sorted
     * - such asset group should not exist yet
     * - can only be called by the ROLE_SPOOL_ADMIN
     * @param assets Array of assets in the asset group.
     * @return id Sequential ID assigned to the asset group.
     */
    function registerAssetGroup(address[] calldata assets) external returns (uint256 id);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./ISmartVault.sol";
import "./RequestType.sol";

error GuardsAlreadyInitialized();
error GuardsNotInitialized();
error GuardError();

/**
 * @notice Used when a guard fails.
 * @param guardNum Sequential number of the guard that failed.
 */
error GuardFailed(uint256 guardNum);

error InvalidGuardParamType(uint256 paramType);

/**
 * @notice Too many guard definitions have been passed when creating a vault.
 */
error TooManyGuards();

/**
 * @notice The guard definition does not have all required inputs
 */
error IncompleteGuardDefinition();

/**
 * @custom:member VaultAddress Address of the smart vault.
 * @custom:member Executor In case of deposit, executor of deposit action; in case of withdrawal, executor of redeem action.
 * @custom:member Receiver Receiver of receipt NFT.
 * @custom:member Owner In case of deposit, owner of assets; in case of withdrawal, owner of vault shares.
 * @custom:member Assets Amounts of assets involved.
 * @custom:member Tokens Addresses of assets involved.
 * @custom:member AssetGroup Asset group of the smart vault.
 * @custom:member CustomValue Custom value.
 * @custom:member DynamicCustomValue Dynamic custom value.
 */
enum GuardParamType {
    VaultAddress,
    Executor,
    Receiver,
    Owner,
    Assets,
    Tokens,
    AssetGroup,
    CustomValue,
    DynamicCustomValue
}

/**
 * @custom:member methodSignature Signature of the method to invoke
 * @custom:member contractAddress Address of the contract to invoke
 * @custom:member operator The operator to use when comparing expectedValue to guard's function result.
 * @custom:member expectedValue Value to use when comparing with the guard function result.
 * - System only supports guards with return values that can be cast to uint256.
 * @custom:member methodParamTypes Types of parameters that the guard function is expecting.
 * @custom:member methodParamValues Parameter values that will be passed into the guard function call.
 * - This array should only include fixed/static values. Parameters that are resolved at runtime should be omitted.
 * - All values should be encoded using "abi.encode" before passing them to the GuardManager contract.
 * - We assume that all static types are encoded to 32 bytes. Fixed-size static arrays and structs with only static
 *      type members are not supported.
 * - If empty, system will assume the expected value is bool(true).
 */
struct GuardDefinition {
    string methodSignature;
    address contractAddress;
    bytes2 operator;
    uint256 expectedValue;
    GuardParamType[] methodParamTypes;
    bytes[] methodParamValues;
}

/**
 * @custom:member receiver Receiver of receipt NFT.
 * @custom:member executor In case of deposit, executor of deposit action; in case of withdrawal, executor of redeem action.
 * @custom:member owner In case of deposit, owner of assets; in case of withdrawal, owner of vault shares.
 * @custom:member requestType Request type for which the guard is run.
 * @custom:member assets Amounts of assets involved.
 * @custom:member tokens Addresses of tokens involved.
 */
struct RequestContext {
    address receiver;
    address executor;
    address owner;
    RequestType requestType;
    uint256[] assets;
    address[] tokens;
}

interface IGuardManager {
    /**
     * @notice Runs guards for a smart vault.
     * @dev Reverts if any guard fails.
     * The context.methodParamValues array should only include fixed/static values.
     * Parameters that are resolved at runtime should be omitted. All values should be encoded using "abi.encode" before
     * passing them to the GuardManager contract. We assume that all static types are encoded to 32 bytes. Fixed-size
     * static arrays and structs with only static type members are not supported.
     * @param smartVault Smart vault for which to run the guards.
     * @param context Context for running the guards.
     */
    function runGuards(address smartVault, RequestContext calldata context) external view;

    /**
     * @notice Gets guards for smart vault and request type.
     * @param smartVault Smart vault for which to get guards.
     * @param requestType Request type for which to get guards.
     * @return guards Guards for the smart vault and request type.
     */
    function readGuards(address smartVault, RequestType requestType)
        external
        view
        returns (GuardDefinition[] memory guards);

    /**
     * @notice Sets guards for the smart vault.
     * @dev
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_INTEGRATOR
     * - guards should not have been already set for the smart vault
     * @param smartVault Smart vault for which to set the guards.
     * @param guards Guards to set. Grouped by the request types.
     * @param requestTypes Request types for groups of guards.
     */
    function setGuards(address smartVault, GuardDefinition[][] calldata guards, RequestType[] calldata requestTypes)
        external;

    /**
     * @notice Emitted when guards are set for a smart vault.
     * @param smartVault Smart vault for which guards were set.
     * @param guards Guard definitions
     * @param requestTypes Guard triggers
     */
    event GuardsInitialized(address indexed smartVault, GuardDefinition[][] guards, RequestType[] requestTypes);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../libraries/uint16a16Lib.sol";

error InvalidRiskInputLength();
error RiskScoreValueOutOfBounds(uint8 value);
error RiskToleranceValueOutOfBounds(int8 value);
error CannotSetRiskScoreForGhostStrategy(uint8 riskScore);
error InvalidAllocationSum(uint256 allocationsSum);
error InvalidRiskScores(address riskProvider, address strategy);

interface IRiskManager {
    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Calculates allocation between strategies based on
     * - risk scores of strategies
     * - risk appetite
     * @param smartVault Smart vault address.
     * @param strategies Strategies.
     * @return allocation Calculated allocation.
     */
    function calculateAllocation(address smartVault, address[] calldata strategies)
        external
        view
        returns (uint16a16 allocation);

    /**
     * @notice Gets risk scores for strategies.
     * @param riskProvider Requested risk provider.
     * @param strategy Strategies.
     * @return riskScores Risk scores for strategies.
     */
    function getRiskScores(address riskProvider, address[] memory strategy)
        external
        view
        returns (uint8[] memory riskScores);

    /**
     * @notice Gets configured risk provider for a smart vault.
     * @param smartVault Smart vault.
     * @return riskProvider Risk provider for the smart vault.
     */
    function getRiskProvider(address smartVault) external view returns (address riskProvider);

    /**
     * @notice Gets configured allocation provider for a smart vault.
     * @param smartVault Smart vault.
     * @return allocationProvider Allocation provider for the smart vault.
     */
    function getAllocationProvider(address smartVault) external view returns (address allocationProvider);

    /**
     * @notice Gets configured risk tolerance for a smart vault.
     * @param smartVault Smart vault.
     * @return riskTolerance Risk tolerance for the smart vault.
     */
    function getRiskTolerance(address smartVault) external view returns (int8 riskTolerance);

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Sets risk provider for a smart vault.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_INTEGRATOR
     * - risk provider must have role ROLE_RISK_PROVIDER
     * @param smartVault Smart vault.
     * @param riskProvider_ Risk provider to set.
     */
    function setRiskProvider(address smartVault, address riskProvider_) external;

    /**
     * @notice Sets allocation provider for a smart vault.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_INTEGRATOR
     * - allocation provider must have role ROLE_ALLOCATION_PROVIDER
     * @param smartVault Smart vault.
     * @param allocationProvider Allocation provider to set.
     */
    function setAllocationProvider(address smartVault, address allocationProvider) external;

    /**
     * @notice Sets risk scores for strategies.
     * @dev Requirements:
     * - caller must have role ROLE_RISK_PROVIDER
     * @param riskScores Risk scores to set for strategies.
     * @param strategies Strategies for which to set risk scores.
     */
    function setRiskScores(uint8[] calldata riskScores, address[] calldata strategies) external;

    /**
     * @notice Sets risk tolerance for a smart vault.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_INTEGRATOR
     * - risk tolerance must be within valid bounds
     * @param smartVault Smart vault.
     * @param riskTolerance Risk tolerance to set.
     */
    function setRiskTolerance(address smartVault, int8 riskTolerance) external;

    /**
     * @notice Risk scores updated
     * @param riskProvider risk provider address
     * @param strategies strategy addresses
     * @param riskScores risk score values
     */
    event RiskScoresUpdated(address indexed riskProvider, address[] strategies, uint8[] riskScores);

    /**
     * @notice Smart vault risk provider set
     * @param smartVault Smart vault address
     * @param riskProvider New risk provider address
     */
    event RiskProviderSet(address indexed smartVault, address indexed riskProvider);

    /**
     * @notice Smart vault allocation provider set
     * @param smartVault Smart vault address
     * @param allocationProvider New allocation provider address
     */
    event AllocationProviderSet(address indexed smartVault, address indexed allocationProvider);

    /**
     * @notice Smart vault risk appetite
     * @param smartVault Smart vault address
     * @param riskTolerance risk appetite value
     */
    event RiskToleranceSet(address indexed smartVault, int8 riskTolerance);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "./Constants.sol";
import "./RequestType.sol";

/* ========== ERRORS ========== */

/**
 * @notice Used when the ID for deposit NFTs overflows.
 * @dev Should never happen.
 */
error DepositIdOverflow();

/**
 * @notice Used when the ID for withdrawal NFTs overflows.
 * @dev Should never happen.
 */
error WithdrawalIdOverflow();

/**
 * @notice Used when ID does not represent a deposit NFT.
 * @param depositNftId Invalid ID for deposit NFT.
 */
error InvalidDepositNftId(uint256 depositNftId);

/**
 * @notice Used when ID does not represent a withdrawal NFT.
 * @param withdrawalNftId Invalid ID for withdrawal NFT.
 */
error InvalidWithdrawalNftId(uint256 withdrawalNftId);

/**
 * @notice Used when balance of the NFT is invalid.
 * @param balance Actual balance of the NFT.
 */
error InvalidNftBalance(uint256 balance);

/**
 * @notice Used when someone wants to transfer invalid NFT shares amount.
 * @param transferAmount Amount of shares requested to be transferred.
 */
error InvalidNftTransferAmount(uint256 transferAmount);

/**
 * @notice Used when user tries to send tokens to himself.
 */
error SenderEqualsRecipient();

/* ========== STRUCTS ========== */

struct DepositMetadata {
    uint256[] assets;
    uint256 initiated;
    uint256 flushIndex;
}

/**
 * @notice Holds metadata detailing the withdrawal behind the NFT.
 * @custom:member vaultShares Vault shares withdrawn.
 * @custom:member flushIndex Flush index into which withdrawal is included.
 */
struct WithdrawalMetadata {
    uint256 vaultShares;
    uint256 flushIndex;
}

/**
 * @notice Holds all smart vault fee percentages.
 * @custom:member managementFeePct Management fee of the smart vault.
 * @custom:member depositFeePct Deposit fee of the smart vault.
 * @custom:member performanceFeePct Performance fee of the smart vault.
 */
struct SmartVaultFees {
    uint16 managementFeePct;
    uint16 depositFeePct;
    uint16 performanceFeePct;
}

/* ========== INTERFACES ========== */

interface ISmartVault is IERC20Upgradeable, IERC1155MetadataURIUpgradeable {
    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Fractional balance of a NFT (0 - NFT_MINTED_SHARES).
     * @param account Account to check the balance for.
     * @param id ID of the NFT to check.
     * @return fractionalBalance Fractional balance of account for the NFT.
     */
    function balanceOfFractional(address account, uint256 id) external view returns (uint256 fractionalBalance);

    /**
     * @notice Fractional balance of a NFTs (0 - NFT_MINTED_SHARES).
     * @param account Account to check the balance for.
     * @param ids IDs of the NFTs to check.
     * @return fractionalBalances Fractional balances of account for each requested NFT.
     */
    function balanceOfFractionalBatch(address account, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory fractionalBalances);
    /**
     * @notice Gets the asset group used by the smart vault.
     * @return id ID of the asset group.
     */
    function assetGroupId() external view returns (uint256 id);

    /**
     * @notice Gets the name of the smart vault.
     * @return name Name of the vault.
     */
    function vaultName() external view returns (string memory name);

    /**
     * @notice Gets metadata for NFTs.
     * @param nftIds IDs of NFTs.
     * @return metadata Metadata for each requested NFT.
     */
    function getMetadata(uint256[] calldata nftIds) external view returns (bytes[] memory metadata);

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Set a new base URI for ERC1155 metadata.
     * @param uri_ new base URI value
     */
    function setBaseURI(string memory uri_) external;

    /**
     * @notice Mints smart vault tokens for receiver.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param receiver REceiver of minted tokens.
     * @param vaultShares Amount of tokens to mint.
     */
    function mintVaultShares(address receiver, uint256 vaultShares) external;

    /**
     * @notice Burns smart vault tokens and releases strategy shares back to strategies.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param owner Address for which to burn the tokens.
     * @param vaultShares Amount of tokens to burn.
     * @param strategies Strategies for which to release the strategy shares.
     * @param shares Amounts of strategy shares to release.
     */
    function burnVaultShares(
        address owner,
        uint256 vaultShares,
        address[] calldata strategies,
        uint256[] calldata shares
    ) external;

    /**
     * @notice Mints a new withdrawal NFT.
     * @dev Supply of minted NFT is NFT_MINTED_SHARES (for partial burning).
     * Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param receiver Address that will receive the NFT.
     * @param metadata Metadata to store for minted NFT.
     * @return id ID of the minted NFT.
     */
    function mintWithdrawalNFT(address receiver, WithdrawalMetadata calldata metadata) external returns (uint256 id);

    /**
     * @notice Mints a new deposit NFT.
     * @dev Supply of minted NFT is NFT_MINTED_SHARES (for partial burning).
     * Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param receiver Address that will receive the NFT.
     * @param metadata Metadata to store for minted NFT.
     * @return id ID of the minted NFT.
     */
    function mintDepositNFT(address receiver, DepositMetadata calldata metadata) external returns (uint256 id);

    /**
     * @notice Burns NFTs and returns their metadata.
     * Allows for partial burning.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param owner Owner of NFTs to burn.
     * @param nftIds IDs of NFTs to burn.
     * @param nftAmounts NFT shares to burn (partial burn).
     * @return metadata Metadata for each burned NFT.
     */
    function burnNFTs(address owner, uint256[] calldata nftIds, uint256[] calldata nftAmounts)
        external
        returns (bytes[] memory metadata);

    /**
     * @notice Transfers smart vault tokens.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param from Spender and owner of tokens.
     * @param to Address to which tokens will be transferred.
     * @param amount Amount of tokens to transfer.
     * @return success True if transfer was successful.
     */
    function transferFromSpender(address from, address to, uint256 amount) external returns (bool success);

    /**
     * @notice Transfers unclaimed shares to claimer.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param claimer Address that claims the shares.
     * @param amount Amount of shares to transfer.
     */
    function claimShares(address claimer, uint256 amount) external;

    /// @notice Emitted when base URI is changed.
    event BaseURIChanged(string baseUri);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IDepositManager.sol";
import "./ISmartVault.sol";
import "./ISwapper.sol";
import "./IWithdrawalManager.sol";

/* ========== ERRORS ========== */

/**
 * @notice Used when user has insufficient balance for redeemal of shares.
 */
error InsufficientBalance(uint256 available, uint256 required);

/**
 * @notice Used when there is nothing to flush.
 */
error NothingToFlush();

/**
 * @notice Used when trying to register a smart vault that was already registered.
 */
error SmartVaultAlreadyRegistered();

/**
 * @notice Used when trying to perform an action for smart vault that was not registered yet.
 */
error SmartVaultNotRegisteredYet();

/**
 * @notice Used when user tries to configure a vault with too large management fee.
 */
error ManagementFeeTooLarge(uint256 mgmtFeePct);

/**
 * @notice Used when user tries to configure a vault with too large performance fee.
 */
error PerformanceFeeTooLarge(uint256 performanceFeePct);

/**
 * @notice Used when smart vault in reallocation has statically set allocation.
 */
error StaticAllocationSmartVault();

/**
 * @notice Used when user tries to configure a vault with too large deposit fee.
 */
error DepositFeeTooLarge(uint256 depositFeePct);

/**
 * @notice Used when user tries redeem on behalf of another user, but the vault does not support it
 */
error RedeemForNotAllowed();

/**
 * @notice Used when trying to flush a vault that still needs to be synced.
 */
error VaultNotSynced();

/**
 * @notice Used when trying to deposit into, redeem from, or flush a smart vault that has only ghost strategies.
 */
error GhostVault();

/**
 * @notice Used when reallocation is called with expired parameters.
 */
error ReallocationParametersExpired();

/* ========== STRUCTS ========== */

/**
 * @notice Struct holding all data for registration of smart vault.
 * @custom:member assetGroupId Underlying asset group of the smart vault.
 * @custom:member strategies Strategies used by the smart vault.
 * @custom:member strategyAllocation Optional. If empty array, values will be calculated on the spot.
 * @custom:member managementFeePct Management fee of the smart vault.
 * @custom:member depositFeePct Deposit fee of the smart vault.
 * @custom:member performanceFeePct Performance fee of the smart vault.
 */
struct SmartVaultRegistrationForm {
    uint256 assetGroupId;
    address[] strategies;
    uint16a16 strategyAllocation;
    uint16 managementFeePct;
    uint16 depositFeePct;
    uint16 performanceFeePct;
}

/**
 * @notice Parameters for reallocation.
 * @custom:member smartVaults Smart vaults to reallocate.
 * @custom:member strategies Set of strategies involved in the reallocation. Should not include ghost strategy, even if some smart vault uses it.
 * @custom:member swapInfo Information for swapping assets before depositing into the protocol.
 * @custom:member depositSlippages Slippages used to constrain depositing into the protocol.
 * @custom:member withdrawalSlippages Slippages used to contrain withdrawal from the protocol.
 * @custom:member exchangeRateSlippages Slippages used to constratrain exchange rates for asset tokens.
 * @custom:member validUntil Sets the maximum timestamp the user is willing to wait to start executing reallocation.
 */
struct ReallocateParamBag {
    address[] smartVaults;
    address[] strategies;
    SwapInfo[][] swapInfo;
    uint256[][] depositSlippages;
    uint256[][] withdrawalSlippages;
    uint256[2][] exchangeRateSlippages;
    uint256 validUntil;
}

struct FlushIndex {
    uint128 current;
    uint128 toSync;
}

/* ========== INTERFACES ========== */

interface ISmartVaultRegistry {
    /**
     * @notice Registers smart vault into the Spool protocol.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_INTEGRATOR
     * @param smartVault Smart vault to register.
     * @param registrationForm Form with information for registration.
     */
    function registerSmartVault(address smartVault, SmartVaultRegistrationForm calldata registrationForm) external;
}

interface ISmartVaultManager is ISmartVaultRegistry {
    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Gets do-hard-work indexes.
     * @param smartVault Smart vault.
     * @param flushIndex Flush index.
     * @return dhwIndexes Do-hard-work indexes for flush index of the smart vault.
     */
    function dhwIndexes(address smartVault, uint256 flushIndex) external view returns (uint16a16 dhwIndexes);

    /**
     * @notice Gets latest flush index for a smart vault.
     * @param smartVault Smart vault.
     * @return flushIndex Latest flush index for the smart vault.
     */
    function getLatestFlushIndex(address smartVault) external view returns (uint256 flushIndex);

    /**
     * @notice Gets strategy allocation for a smart vault.
     * @param smartVault Smart vault.
     * @return allocation Strategy allocation for the smart vault.
     */
    function allocations(address smartVault) external view returns (uint16a16 allocation);

    /**
     * @notice Gets strategies used by a smart vault.
     * @param smartVault Smart vault.
     * @return strategies Strategies for the smart vault.
     */
    function strategies(address smartVault) external view returns (address[] memory strategies);

    /**
     * @notice Gets asest group used by a smart vault.
     * @param smartVault Smart vault.
     * @return assetGroupId ID of the asset group used by the smart vault.
     */
    function assetGroupId(address smartVault) external view returns (uint256 assetGroupId);

    /**
     * @notice Gets required deposit ratio for a smart vault.
     * @param smartVault Smart vault.
     * @return ratio Required deposit ratio for the smart vault.
     */
    function depositRatio(address smartVault) external view returns (uint256[] memory ratio);

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Flushes deposits and withdrawal for the next do-hard-work.
     * @param smartVault Smart vault to flush.
     */
    function flushSmartVault(address smartVault) external;

    /**
     * @notice Reallocates smart vaults.
     * @dev Requirements:
     * - caller must have a ROLE_REALLOCATOR role
     * - smart vaults must be registered
     * - smart vaults must use same asset group
     * - strategies must represent a set of strategies used by smart vaults
     * @param reallocateParams Paramaters for reallocation.
     */
    function reallocate(ReallocateParamBag calldata reallocateParams) external;

    /**
     * @notice Removes strategy from vaults, and optionally removes it from the system as well.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * - the strategy has to be active (requires ROLE_STRATEGY)
     * @param strategy Strategy address to remove.
     * @param vaults Array of vaults from which to remove the strategy
     * @param disableStrategy Also disable the strategy across the system
     */
    function removeStrategyFromVaults(address strategy, address[] calldata vaults, bool disableStrategy) external;

    /**
     * @notice Syncs smart vault with strategies.
     * @param smartVault Smart vault to sync.
     * @param revertIfError If true, sync will revert if every flush index cannot be synced; if false it will sync all flush indexes it can.
     */
    function syncSmartVault(address smartVault, bool revertIfError) external;

    /**
     * @dev Calculate number of SVTs that haven't been synced yet after DHW runs
     * DHW has minted strategy shares, but vaults haven't claimed them yet.
     * Includes management fees (percentage of assets under management, distributed throughout a year) and deposit fees .
     * Invariants:
     * - There can't be more than once un-synced flush index per vault at any given time.
     * - Flush index can't be synced, if all DHWs haven't been completed yet.
     *
     * Can be used to retrieve the number of SSTs the vault would claim during sync.
     * @param smartVault SmartVault address
     * @return oldTotalSVTs Amount of SVTs before sync
     * @return mintedSVTs Amount of SVTs minted during sync
     * @return feeSVTs Amount of SVTs pertaining to fees
     * @return sstShares Amount of SSTs claimed per strategy
     */
    function simulateSync(address smartVault)
        external
        view
        returns (uint256 oldTotalSVTs, uint256 mintedSVTs, uint256 feeSVTs, uint256[] calldata sstShares);

    /**
     * @dev Simulate sync when burning dNFTs and return their svts value.
     *
     * @param smartVault SmartVault address
     * @param userAddress User address that owns dNFTs
     * @param nftIds Ids of dNFTs
     * @return svts Amount of svts user would get if he burns dNFTs
     */
    function simulateSyncWithBurn(address smartVault, address userAddress, uint256[] calldata nftIds)
        external
        view
        returns (uint256 svts);

    /**
     * @notice Instantly redeems smart vault shares for assets.
     * @param bag Parameters for fast redeemal.
     * @param withdrawalSlippages Slippages guarding redeemal.
     * @return withdrawnAssets Amount of assets withdrawn.
     */
    function redeemFast(RedeemBag calldata bag, uint256[][] calldata withdrawalSlippages)
        external
        returns (uint256[] memory withdrawnAssets);

    /**
     * @notice Simulates redeem fast of smart vault shares.
     * @dev Should only be run by address zero to simulate the redeemal and parse logs.
     * @param bag Parameters for fast redeemal.
     * @param withdrawalSlippages Slippages guarding redeemal.
     * @param redeemer Address of a user to simulate redeem for.
     * @return withdrawnAssets Amount of assets withdrawn.
     */
    function redeemFastView(RedeemBag calldata bag, uint256[][] calldata withdrawalSlippages, address redeemer)
        external
        returns (uint256[] memory withdrawnAssets);

    /**
     * @notice Claims withdrawal of assets by burning withdrawal NFT.
     * @dev Requirements:
     * - withdrawal NFT must be valid
     * @param smartVault Address of the smart vault that issued the withdrawal NFT.
     * @param nftIds ID of withdrawal NFT to burn.
     * @param nftAmounts amounts
     * @param receiver Receiver of claimed assets.
     * @return assetAmounts Amounts of assets claimed.
     * @return assetGroupId ID of the asset group.
     */
    function claimWithdrawal(
        address smartVault,
        uint256[] calldata nftIds,
        uint256[] calldata nftAmounts,
        address receiver
    ) external returns (uint256[] memory assetAmounts, uint256 assetGroupId);

    /**
     * @notice Claims smart vault tokens by burning the deposit NFT.
     * @dev Requirements:
     * - deposit NFT must be valid
     * - flush must be synced
     * @param smartVaultAddress Address of the smart vault that issued the deposit NFT.
     * @param nftIds ID of the deposit NFT to burn.
     * @param nftAmounts amounts
     * @return claimedAmount Amount of smart vault tokens claimed.
     */
    function claimSmartVaultTokens(address smartVaultAddress, uint256[] calldata nftIds, uint256[] calldata nftAmounts)
        external
        returns (uint256 claimedAmount);

    /**
     * @notice Initiates a withdrawal process and mints a withdrawal NFT. Once all DHWs are executed, user can
     * use the withdrawal NFT to claim the assets.
     * Optionally, caller can pass a list of deposit NFTs to unwrap.
     * @param bag smart vault address, amount of shares to redeem, nft ids and amounts to burn
     * @param receiver address that will receive the withdrawal NFT
     * @param doFlush optionally flush the smart vault
     * @return receipt ID of the receipt withdrawal NFT.
     */
    function redeem(RedeemBag calldata bag, address receiver, bool doFlush) external returns (uint256 receipt);

    /**
     * @notice Initiates a withdrawal process and mints a withdrawal NFT. Once all DHWs are executed, user can
     * use the withdrawal NFT to claim the assets.
     * Optionally, caller can pass a list of deposit NFTs to unwrap.
     * @param bag smart vault address, amount of shares to redeem, nft ids and amounts to burn
     * @param owner address that owns the shares to be redeemed and will receive the withdrawal NFT
     * @param doFlush optionally flush the smart vault
     * @return receipt ID of the receipt withdrawal NFT.
     */
    function redeemFor(RedeemBag calldata bag, address owner, bool doFlush) external returns (uint256 receipt);

    /**
     * @notice Initiated a deposit and mints a deposit NFT. Once all DHWs are executed, user can
     * unwrap the deposit NDF and claim his SVTs.
     * @param bag smartVault address, assets, NFT receiver address, referral address, doFlush
     * @return receipt ID of the receipt deposit NFT.
     */
    function deposit(DepositBag calldata bag) external returns (uint256 receipt);

    /**
     * @notice Recovers pending deposits from smart vault to emergency wallet.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * - all strategies of the smart vault need to be ghost strategies
     * @param smartVault Smart vault from which to recover pending deposits.
     */
    function recoverPendingDeposits(address smartVault) external;

    /* ========== EVENTS ========== */

    /**
     * @notice Smart vault has been flushed
     * @param smartVault Smart vault address
     * @param flushIndex Flush index
     */
    event SmartVaultFlushed(address indexed smartVault, uint256 flushIndex);

    /**
     * @notice Smart vault has been synced
     * @param smartVault Smart vault address
     * @param flushIndex Flush index
     */
    event SmartVaultSynced(address indexed smartVault, uint256 flushIndex);

    /**
     * @notice Smart vault has been registered
     * @param smartVault Smart vault address
     * @param registrationForm Smart vault configuration
     */
    event SmartVaultRegistered(address indexed smartVault, SmartVaultRegistrationForm registrationForm);

    /**
     * @notice Strategy was removed from the vault
     * @param strategy Strategy address
     * @param vault Vault to remove the strategy from
     */
    event StrategyRemovedFromVault(address indexed strategy, address indexed vault);

    /**
     * @notice Vault was reallocation executed
     * @param smartVault Smart vault address
     * @param newAllocations new vault strategy allocations
     */
    event SmartVaultReallocated(address indexed smartVault, uint16a16 newAllocations);
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

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {PlatformFees} from "./IStrategyRegistry.sol";
import "./ISwapper.sol";
import "./IUsdPriceFeedManager.sol";

/**
 * @notice Struct holding information how to swap the assets.
 * @custom:member slippage minumum output amount
 * @custom:member path swap path, first byte represents an action (e.g. Uniswap V2 custom swap), rest is swap specific path
 */
struct SwapData {
    uint256 slippage; // min amount out
    bytes path; // 1st byte is action, then path
}

/**
 * @notice Parameters for calling do hard work on strategy.
 * @custom:member swapInfo Information for swapping assets before depositing into the protocol.
 * @custom:member swapInfo Information for swapping rewards before depositing them back into the protocol.
 * @custom:member slippages Slippages used to constrain depositing and withdrawing from the protocol.
 * @custom:member assetGroup Asset group of the strategy.
 * @custom:member exchangeRates Exchange rates for assets.
 * @custom:member withdrawnShares Strategy shares withdrawn by smart vault.
 * @custom:member masterWallet Master wallet.
 * @custom:member priceFeedManager Price feed manager.
 * @custom:member baseYield Base yield value, manual input for specific strategies.
 * @custom:member platformFees Platform fees info.
 */
struct StrategyDhwParameterBag {
    SwapInfo[] swapInfo;
    SwapInfo[] compoundSwapInfo;
    uint256[] slippages;
    address[] assetGroup;
    uint256[] exchangeRates;
    uint256 withdrawnShares;
    address masterWallet;
    IUsdPriceFeedManager priceFeedManager;
    int256 baseYield;
    PlatformFees platformFees;
}

/**
 * @notice Information about results of the do hard work.
 * @custom:member sharesMinted Amount of strategy shares minted.
 * @custom:member assetsWithdrawn Amount of assets withdrawn.
 * @custom:member yieldPercentage Yield percentage from the previous DHW.
 * @custom:member valueAtDhw Value of the strategy at the end of DHW.
 * @custom:member totalSstsAtDhw Total SSTs at the end of DHW.
 */
struct DhwInfo {
    uint256 sharesMinted;
    uint256[] assetsWithdrawn;
    int256 yieldPercentage;
    uint256 valueAtDhw;
    uint256 totalSstsAtDhw;
}

/**
 * @notice Used when ghost strategy is called.
 */
error IsGhostStrategy();

/**
 * @notice Used when user is not allowed to redeem fast.
 * @param user User that tried to redeem fast.
 */
error NotFastRedeemer(address user);

/**
 * @notice Used when asset group ID is not correctly initialized.
 */
error InvalidAssetGroupIdInitialization();

interface IStrategy is IERC20Upgradeable {
    /* ========== EVENTS ========== */

    event Deposited(
        uint256 mintedShares, uint256 usdWorthDeposited, uint256[] assetsBeforeSwap, uint256[] assetsDeposited
    );

    event Withdrawn(uint256 withdrawnShares, uint256 usdWorthWithdrawn, uint256[] withdrawnAssets);

    event PlatformFeesCollected(address indexed strategy, uint256 sharesMinted);

    event Slippages(bool isDeposit, uint256 slippage, bytes data);

    event BeforeDepositCheckSlippages(uint256[] amounts);

    event BeforeRedeemalCheckSlippages(uint256 ssts);

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Gets strategy name.
     * @return name Name of the strategy.
     */
    function strategyName() external view returns (string memory name);

    /**
     * @notice Gets required ratio between underlying assets.
     * @return ratio Required asset ratio for the strategy.
     */
    function assetRatio() external view returns (uint256[] memory ratio);

    /**
     * @notice Gets asset group used by the strategy.
     * @return id ID of the asset group.
     */
    function assetGroupId() external view returns (uint256 id);

    /**
     * @notice Gets underlying assets for the strategy.
     * @return assets Addresses of the underlying assets.
     */
    function assets() external view returns (address[] memory assets);

    /**
     * @notice Gets underlying asset amounts for the strategy.
     * @return amounts Amounts of the underlying assets.
     */
    function getUnderlyingAssetAmounts() external view returns (uint256[] memory amounts);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Performs slippages check before depositing.
     * @param amounts Amounts to be deposited.
     * @param slippages Slippages to check against.
     */
    function beforeDepositCheck(uint256[] memory amounts, uint256[] calldata slippages) external;

    /**
     * @dev Performs slippages check before redeemal.
     * @param ssts Amount of strategy tokens to be redeemed.
     * @param slippages Slippages to check against.
     */
    function beforeRedeemalCheck(uint256 ssts, uint256[] calldata slippages) external;

    /**
     * @notice Does hard work:
     * - compounds rewards
     * - deposits into the protocol
     * - withdraws from the protocol
     * @dev Requirements:
     * - caller must have role ROLE_STRATEGY_REGISTRY
     * @param dhwParams Parameters for the do hard work.
     * @return info Information about do the performed hard work.
     */
    function doHardWork(StrategyDhwParameterBag calldata dhwParams) external returns (DhwInfo memory info);

    /**
     * @notice Claims strategy shares after do-hard-work.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault claiming shares.
     * @param amount Amount of strategy shares to claim.
     */
    function claimShares(address smartVault, uint256 amount) external;

    /**
     * @notice Releases shares back to strategy.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault releasing shares.
     * @param amount Amount of strategy shares to release.
     */
    function releaseShares(address smartVault, uint256 amount) external;

    /**
     * @notice Instantly redeems strategy shares for assets.
     * @dev Requirements:
     * - caller must have either role ROLE_SMART_VAULT_MANAGER or role ROLE_STRATEGY_REGISTRY
     * @param shares Amount of shares to redeem.
     * @param masterWallet Address of the master wallet.
     * @param assetGroup Asset group of the strategy.
     * @param slippages Slippages to guard redeeming.
     * @return assetsWithdrawn Amount of assets withdrawn.
     */
    function redeemFast(
        uint256 shares,
        address masterWallet,
        address[] calldata assetGroup,
        uint256[] calldata slippages
    ) external returns (uint256[] memory assetsWithdrawn);

    /**
     * @notice Instantly redeems strategy shares for assets.
     * @param shares Amount of shares to redeem.
     * @param redeemer Address of he redeemer, owner of SSTs.
     * @param assetGroup Asset group of the strategy.
     * @param slippages Slippages to guard redeeming.
     * @return assetsWithdrawn Amount of assets withdrawn.
     */
    function redeemShares(uint256 shares, address redeemer, address[] calldata assetGroup, uint256[] calldata slippages)
        external
        returns (uint256[] memory assetsWithdrawn);

    /**
     * @notice Instantly deposits into the protocol.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param assetGroup Asset group of the strategy.
     * @param exchangeRates Asset to USD exchange rates.
     * @param priceFeedManager Price feed manager contract.
     * @param slippages Slippages to guard depositing.
     * @param swapInfo Information for swapping assets before depositing into the protocol.
     * @return sstsMinted Amount of SSTs minted.
     */
    function depositFast(
        address[] calldata assetGroup,
        uint256[] calldata exchangeRates,
        IUsdPriceFeedManager priceFeedManager,
        uint256[] calldata slippages,
        SwapInfo[] calldata swapInfo
    ) external returns (uint256 sstsMinted);

    /**
     * @notice Instantly withdraws assets, bypassing shares mechanism.
     * Transfers withdrawn assets to the emergency withdrawal wallet.
     * @dev Requirements:
     * - caller must have role ROLE_STRATEGY_REGISTRY
     * @param slippages Slippages to guard redeeming.
     * @param recipient Recipient address
     */
    function emergencyWithdraw(uint256[] calldata slippages, address recipient) external;

    /**
     * @notice Gets USD worth of the strategy.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param exchangeRates Asset to USD exchange rates.
     * @param priceFeedManager Price feed manager contract.
     */
    function getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        external
        returns (uint256 usdWorth);

    /**
     * @notice Gets protocol rewards.
     * @dev Requirements:
     * - can only be called in view-execution mode.
     * @return tokens Addresses of reward tokens.
     * @return amounts Amount of reward tokens available.
     */
    function getProtocolRewards() external returns (address[] memory tokens, uint256[] memory amounts);
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

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/utils/Strings.sol";
import "@openzeppelin-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "./interfaces/IGuardManager.sol";
import "./interfaces/ISmartVault.sol";
import "./interfaces/CommonErrors.sol";
import "./interfaces/RequestType.sol";
import "./access/SpoolAccessControllable.sol";
import "./libraries/ArrayMapping.sol";

contract SmartVault is ERC20PermitUpgradeable, ERC1155Upgradeable, SpoolAccessControllable, ISmartVault {
    using SafeERC20 for IERC20;
    using ArrayMappingUint256 for mapping(uint256 => uint256);

    /* ========== CONSTANTS ========== */

    /// @notice Guard manager
    IGuardManager internal immutable _guardManager;

    /// @notice Asset group ID
    uint256 public assetGroupId;

    /// @notice Vault name
    string internal _vaultName;

    /* ========== STATE VARIABLES ========== */

    /// @notice Deposit metadata registry
    mapping(uint256 => DepositMetadata) private _depositMetadata;

    /// @notice Withdrawal metadata registry
    mapping(uint256 => WithdrawalMetadata) private _withdrawalMetadata;

    /// @notice Deposit NFT ID
    uint256 private _lastDepositId;

    /// @notice Withdrawal NFT ID
    uint256 private _lastWithdrawalId;

    /* ========== CONSTRUCTOR ========== */

    constructor(ISpoolAccessControl accessControl_, IGuardManager guardManager_)
        SpoolAccessControllable(accessControl_)
    {
        if (address(guardManager_) == address(0)) revert ConfigurationAddressZero();

        _guardManager = guardManager_;

        _disableInitializers();
    }

    function initialize(
        string calldata vaultName_,
        string calldata svtSymbol,
        string calldata baseURI_,
        uint256 assetGroupId_
    ) external initializer {
        if (bytes(vaultName_).length == 0) revert InvalidConfiguration();

        __ERC1155_init(baseURI_);
        __ERC20_init(vaultName_, svtSymbol);

        _vaultName = vaultName_;
        assetGroupId = assetGroupId_;

        _lastDepositId = 0;
        _lastWithdrawalId = MAXIMAL_DEPOSIT_ID;
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @dev Returns the URI for token type `id`.
     * Base functionality is used to hold the base URI string.
     * We override and append the token ID.
     */
    function uri(uint256 tokenId)
        public
        view
        override(ERC1155Upgradeable, IERC1155MetadataURIUpgradeable)
        returns (string memory)
    {
        return string(abi.encodePacked(super.uri(0), Strings.toString(tokenId), ".json"));
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     * Returns 1 if user has any balance, 0 otherwise.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        override(ERC1155Upgradeable, IERC1155Upgradeable)
        returns (uint256)
    {
        return super.balanceOf(account, id) >= 1 ? 1 : 0;
    }

    function balanceOfFractional(address account, uint256 id) public view returns (uint256) {
        return super.balanceOf(account, id);
    }

    /**
     * @notice Returns user's NFT balance
     * @dev 1 if user has any balance, 0 otherwise.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        override(ERC1155Upgradeable, IERC1155Upgradeable)
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function balanceOfFractionalBatch(address account, uint256[] calldata ids) public view returns (uint256[] memory) {
        uint256[] memory batchBalances = new uint256[](ids.length);

        for (uint256 i; i < ids.length; ++i) {
            batchBalances[i] = balanceOfFractional(account, ids[i]);
        }

        return batchBalances;
    }

    function vaultName() external view returns (string memory) {
        return _vaultName;
    }

    function getMetadata(uint256[] calldata nftIds) public view returns (bytes[] memory) {
        bytes[] memory metadata = new bytes[](nftIds.length);

        for (uint256 i; i < nftIds.length; ++i) {
            metadata[i] = nftIds[i] > MAXIMAL_DEPOSIT_ID
                ? abi.encode(_withdrawalMetadata[nftIds[i]])
                : abi.encode(_depositMetadata[nftIds[i]]);
        }

        return metadata;
    }

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Set a new base URI for ERC1155 metadata and emits an event.
     * @param uri_ new base URI value
     */
    function setBaseURI(string memory uri_) external onlyAdminOrVaultAdmin(address(this), msg.sender) {
        _setURI(uri_);
        emit BaseURIChanged(uri_);
    }

    function mintVaultShares(address receiver, uint256 vaultShares)
        external
        onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender)
    {
        _mint(receiver, vaultShares);
    }

    function burnVaultShares(
        address owner,
        uint256 vaultShares,
        address[] calldata strategies,
        uint256[] calldata shares
    ) external onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender) {
        // burn withdrawn vault shares
        _burn(owner, vaultShares);

        for (uint256 i; i < strategies.length; ++i) {
            if (shares[i] > 0) {
                IERC20(strategies[i]).safeTransfer(strategies[i], shares[i]);
            }
        }
    }

    function burnNFTs(address owner, uint256[] calldata nftIds, uint256[] calldata nftAmounts)
        external
        onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender)
        returns (bytes[] memory)
    {
        _burnBatch(owner, nftIds, nftAmounts);
        return getMetadata(nftIds);
    }

    function claimShares(address claimer, uint256 amount) external onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender) {
        _transfer(address(this), claimer, amount);
    }

    function mintDepositNFT(address receiver, DepositMetadata calldata metadata)
        external
        onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender)
        returns (uint256)
    {
        if (_lastDepositId >= MAXIMAL_DEPOSIT_ID) {
            revert DepositIdOverflow();
        }
        _lastDepositId++;
        _depositMetadata[_lastDepositId] = metadata;
        _mint(receiver, _lastDepositId, NFT_MINTED_SHARES, "");

        return _lastDepositId;
    }

    function mintWithdrawalNFT(address receiver, WithdrawalMetadata memory metadata)
        external
        onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender)
        returns (uint256 receipt)
    {
        if (_lastWithdrawalId >= MAXIMAL_WITHDRAWAL_ID) {
            revert WithdrawalIdOverflow();
        }
        _lastWithdrawalId++;
        _withdrawalMetadata[_lastWithdrawalId] = metadata;
        _mint(receiver, _lastWithdrawalId, NFT_MINTED_SHARES, "");

        return _lastWithdrawalId;
    }

    function transferFromSpender(address from, address to, uint256 amount)
        external
        onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender)
        returns (bool)
    {
        _transfer(from, to, amount);
        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
        _requireNotPaused();

        // mint / burn / redeem
        if (from == address(0) || to == address(0) || to == address(this)) return;
        if (from == to) revert SenderEqualsRecipient();

        uint256[] memory assets = new uint256[](1);
        assets[0] = amount;

        RequestContext memory context = RequestContext({
            receiver: to,
            executor: msg.sender,
            owner: from,
            requestType: RequestType.TransferSVTs,
            assets: assets,
            tokens: new address[](0)
        });
        _guardManager.runGuards(address(this), context);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal view override {
        _requireNotPaused();

        // skip transfer checks when minting and burning
        // they have their own checks made
        if (from == address(0) || to == address(0)) return;
        if (from == to) revert SenderEqualsRecipient();

        // check that only full NFT can be transferred
        for (uint256 i; i < ids.length; ++i) {
            if (amounts[i] != NFT_MINTED_SHARES) {
                revert InvalidNftTransferAmount(amounts[i]);
            }
        }

        // NOTE:
        // - here we are passing ids into the request context instead of amounts
        // - here we passing empty array as tokens
        RequestContext memory context = RequestContext({
            receiver: to,
            executor: operator,
            owner: from,
            requestType: RequestType.TransferNFT,
            assets: ids,
            tokens: new address[](0)
        });
        _guardManager.runGuards(address(this), context);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/proxy/beacon/UpgradeableBeacon.sol";
import "./interfaces/IAction.sol";
import "./interfaces/IAssetGroupRegistry.sol";
import "./interfaces/IGuardManager.sol";
import "./interfaces/IRiskManager.sol";
import "./interfaces/ISmartVault.sol";
import "./interfaces/ISmartVaultManager.sol";
import "./interfaces/ISpoolAccessControl.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/CommonErrors.sol";
import "./interfaces/Constants.sol";
import "./interfaces/RequestType.sol";
import "./access/Roles.sol";
import "./SmartVault.sol";

/* ========== ERRORS ========== */

/**
 * @notice Used when no strategy was provided during smart vault registration.
 */
error SmartVaultRegistrationNoStrategies();

/**
 * @notice Used when too many strategies were provided during smart vault registration.
 */
error StrategyCapExceeded();

/**
 * @notice Used when user has duplicated strategies when creating a new vault
 */
error StrategiesNotUnique();

/**
 * @notice Used when the number of allocation values is less than the number of strategies.
 */
error InvalidStrategyAllocationsLength();

/**
 * @notice Used when provided static allocation does not sum to FULL_PERCENT.
 */
error InvalidStaticAllocation();

/**
 * @notice Used when smart vault has set static allocation and risk provider.
 */
error StaticAllocationAndRiskProviderSet();

/**
 * @notice Used when smart vault has set static allocation and risk tolerance.
 */
error StaticAllocationAndRiskToleranceSet();

/**
 * @notice Used when smart vault has set static allocation and allocation provider.
 */
error StaticAllocationAndAllocationProviderSet();

/**
 * @notice Used when smart vault has only one strategy but does not set static allocation.
 */
error SingleStrategyDynamicAllocation();

/* ========== STRUCTS ========== */

/**
 * @notice Specification for smart vault deployment.
 * @custom:member smartVaultName Name of the smart vault.
 * @custom:member assetGroupId ID of the asset group.
 * @custom:member strategies Strategies used by the smart vault.
 * @custom:member strategyAllocation Optional. If empty array, values will be calculated on the spot.
 * @custom:member riskTolerance Risk appetite of the smart vault.
 * @custom:member riskProvider Risk provider used by the smart vault.
 * @custom:member allocationProvider Allocation provider used by the smart vault.
 * @custom:member actions Actions to register for the smart vault.
 * @custom:member actionRequestTypes Request types for actions.
 * @custom:member guards Guards to register for the smart vault.
 * @custom:member guardRequestTypes Request types for the smart vault.
 * @custom:member managementFeePCt Management fee percentage.
 * @custom:member depositFeePct Deposit fee percentage.
 * @custom:member allowRedeemFor Allow vault owner to initiate redeem on behalf of others.
 */
struct SmartVaultSpecification {
    string smartVaultName;
    string svtSymbol;
    string baseURI;
    uint256 assetGroupId;
    address[] strategies;
    uint16a16 strategyAllocation;
    int8 riskTolerance;
    address riskProvider;
    address allocationProvider;
    IAction[] actions;
    RequestType[] actionRequestTypes;
    GuardDefinition[][] guards;
    RequestType[] guardRequestTypes;
    uint16 managementFeePct;
    uint16 depositFeePct;
    uint16 performanceFeePct;
    bool allowRedeemFor;
}

/* ========== CONTRACTS ========== */

/**
 * @dev Requires roles:
 * - ROLE_SMART_VAULT_INTEGRATOR
 * - ADMIN_ROLE_SMART_VAULT_ALLOW_REDEEM
 */
contract SmartVaultFactory is UpgradeableBeacon {
    using uint16a16Lib for uint16a16;

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when a new smart vault is deployed.
     * @param smartVault Address of the newly deployed smart vault.
     * @param deployer Address of the deployer.
     */
    event SmartVaultDeployed(address indexed smartVault, address indexed deployer);

    /* ========== CONSTANTS ========== */

    /**
     * @notice Spool access control contract.
     */
    ISpoolAccessControl immutable _accessControl;

    /**
     * @notice Action manager contract.
     */
    IActionManager immutable _actionManager;

    /**
     * @notice Guard manager contract.
     */
    IGuardManager immutable _guardManager;

    /**
     * @notice Smart vault manager contract.
     */
    ISmartVaultRegistry immutable _smartVaultRegistry;

    /**
     * @notice Asset group registry contract.
     */
    IAssetGroupRegistry immutable _assetGroupRegistry;

    /**
     * @notice Risk manager contract.
     */
    IRiskManager immutable _riskManager;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address implementation,
        ISpoolAccessControl accessControl_,
        IActionManager actionManager_,
        IGuardManager guardManager_,
        ISmartVaultRegistry smartVaultRegistry_,
        IAssetGroupRegistry assetGroupRegistry_,
        IRiskManager riskManager_
    ) UpgradeableBeacon(implementation) {
        if (address(accessControl_) == address(0)) revert ConfigurationAddressZero();
        if (address(actionManager_) == address(0)) revert ConfigurationAddressZero();
        if (address(guardManager_) == address(0)) revert ConfigurationAddressZero();
        if (address(smartVaultRegistry_) == address(0)) revert ConfigurationAddressZero();
        if (address(assetGroupRegistry_) == address(0)) revert ConfigurationAddressZero();
        if (address(riskManager_) == address(0)) revert ConfigurationAddressZero();

        _accessControl = accessControl_;
        _actionManager = actionManager_;
        _guardManager = guardManager_;
        _smartVaultRegistry = smartVaultRegistry_;
        _assetGroupRegistry = assetGroupRegistry_;
        _riskManager = riskManager_;
    }

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Deploys a new smart vault into the Spool ecosystem.
     * @param specification Specifications for the new smart vault.
     * @return smartVault Deployed smart vault.
     */
    function deploySmartVault(SmartVaultSpecification calldata specification) external returns (ISmartVault) {
        _validateSpecification(specification);

        address smartVaultAddress = address(
            new BeaconProxy(
                address(this),
                _encodeInitializationCalldata(specification)
            )
        );

        _integrateSmartVault(smartVaultAddress, specification);

        emit SmartVaultDeployed(smartVaultAddress, msg.sender);

        return ISmartVault(smartVaultAddress);
    }

    /**
     * @notice Deploys a new smart vault to a deterministic address.
     * @param specification Specifications for the new smart vault.
     * @param salt Salt for address determination.
     * @return smartVault Deployed smart vault.
     */
    function deploySmartVaultDeterministically(SmartVaultSpecification calldata specification, bytes32 salt)
        external
        returns (ISmartVault)
    {
        _validateSpecification(specification);

        address smartVaultAddress = address(
            new BeaconProxy{salt: salt}(
                address(this),
                _encodeInitializationCalldata(specification)
            )
        );

        _integrateSmartVault(smartVaultAddress, specification);

        emit SmartVaultDeployed(smartVaultAddress, msg.sender);

        return ISmartVault(smartVaultAddress);
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Predicts deployment address deterministically deployed smart vault.
     * @param specification Specifications for the new smart vault.
     * @param salt Salt for address determination.
     * @return predictedAddress Predicted address.
     */
    function predictDeterministicAddress(SmartVaultSpecification calldata specification, bytes32 salt)
        external
        view
        returns (address)
    {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(
                                abi.encodePacked(
                                    type(BeaconProxy).creationCode,
                                    abi.encode(address(this), _encodeInitializationCalldata(specification))
                                )
                            )
                        )
                    )
                )
            )
        );
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Validates smart vault specification.
     * @param specification Specifications for the new smart vault.
     */
    function _validateSpecification(SmartVaultSpecification calldata specification) private view {
        _assetGroupRegistry.validateAssetGroup(specification.assetGroupId);

        if (specification.strategies.length == 0) {
            revert SmartVaultRegistrationNoStrategies();
        }
        if (specification.strategies.length > STRATEGY_COUNT_CAP) {
            revert StrategyCapExceeded();
        }

        unchecked {
            bool fixedAllocations = uint16a16.unwrap(specification.strategyAllocation) > 0;
            uint256 fullAllocation;

            if (specification.strategies.length == 1 && !fixedAllocations) {
                revert SingleStrategyDynamicAllocation();
            }

            if (fixedAllocations) {
                if (specification.riskProvider != address(0)) {
                    revert StaticAllocationAndRiskProviderSet();
                }

                if (specification.riskTolerance != 0) {
                    revert StaticAllocationAndRiskToleranceSet();
                }

                if (specification.allocationProvider != address(0)) {
                    revert StaticAllocationAndAllocationProviderSet();
                }
            }

            for (uint256 i; i < specification.strategies.length; ++i) {
                if (fixedAllocations) {
                    if (specification.strategyAllocation.get(i) == 0) {
                        revert InvalidStrategyAllocationsLength();
                    }
                    fullAllocation += specification.strategyAllocation.get(i);
                }

                if (!_accessControl.hasRole(ROLE_STRATEGY, specification.strategies[i])) {
                    revert InvalidStrategy(specification.strategies[i]);
                }

                if (IStrategy(specification.strategies[i]).assetGroupId() != specification.assetGroupId) {
                    revert NotSameAssetGroup();
                }

                for (uint256 j = i + 1; j < specification.strategies.length; ++j) {
                    if (specification.strategies[i] == specification.strategies[j]) {
                        revert StrategiesNotUnique();
                    }
                }
            }

            if (fixedAllocations && fullAllocation != FULL_PERCENT) {
                revert InvalidStaticAllocation();
            }
        }

        if (specification.managementFeePct > MANAGEMENT_FEE_MAX) {
            revert ManagementFeeTooLarge(specification.managementFeePct);
        }
        if (specification.depositFeePct > DEPOSIT_FEE_MAX) {
            revert DepositFeeTooLarge(specification.depositFeePct);
        }
        if (specification.performanceFeePct > SV_PERFORMANCE_FEE_MAX) {
            revert PerformanceFeeTooLarge(specification.performanceFeePct);
        }
    }

    /**
     * @notice Encodes calldata for smart vault initialization.
     * @param specification Specifications for the new smart vault.
     * @return initializationCalldata Enoded initialization calldata.
     */
    function _encodeInitializationCalldata(SmartVaultSpecification calldata specification)
        private
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSignature(
            "initialize(string,string,string,uint256)",
            specification.smartVaultName,
            specification.svtSymbol,
            specification.baseURI,
            specification.assetGroupId
        );
    }

    /**
     * @notice Integrates newly created smart vault into the Spool ecosystem.
     * @param smartVaultAddress Address of created smart vault.
     * @param specification Specifications for the new smart vault.
     */
    function _integrateSmartVault(address smartVaultAddress, SmartVaultSpecification calldata specification) private {
        _accessControl.grantSmartVaultOwnership(smartVaultAddress, msg.sender);
        _actionManager.setActions(smartVaultAddress, specification.actions, specification.actionRequestTypes);
        _guardManager.setGuards(smartVaultAddress, specification.guards, specification.guardRequestTypes);

        if (specification.allowRedeemFor) {
            _accessControl.grantRole(ROLE_SMART_VAULT_ALLOW_REDEEM, smartVaultAddress);
        }

        uint16a16 allocations = specification.strategyAllocation;

        // set allocation
        if (uint16a16.unwrap(allocations) == 0) {
            _riskManager.setRiskProvider(smartVaultAddress, specification.riskProvider);
            _riskManager.setRiskTolerance(smartVaultAddress, specification.riskTolerance);
            _riskManager.setAllocationProvider(smartVaultAddress, specification.allocationProvider);

            allocations = _riskManager.calculateAllocation(smartVaultAddress, specification.strategies);
        }

        _smartVaultRegistry.registerSmartVault(
            smartVaultAddress,
            SmartVaultRegistrationForm({
                assetGroupId: specification.assetGroupId,
                strategies: specification.strategies,
                strategyAllocation: allocations,
                managementFeePct: specification.managementFeePct,
                depositFeePct: specification.depositFeePct,
                performanceFeePct: specification.performanceFeePct
            })
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

type uint16a16 is uint256;

/**
 * @notice This library enables packing of sixteen uint16 elements into one uint256 word.
 */
library uint16a16Lib {
    /// @notice Number of bits per stored element.
    uint256 constant bits = 16;

    /// @notice Maximal number of elements stored.
    uint256 constant elements = 16;

    // must ensure that bits * elements <= 256

    /// @notice Range covered by stored element.
    uint256 constant range = 1 << bits;

    /// @notice Maximal value of stored element.
    uint256 constant max = range - 1;

    /**
     * @notice Gets element from packed array.
     * @param va Packed array.
     * @param index Index of element to get.
     * @return element Element of va stored in index index.
     */
    function get(uint16a16 va, uint256 index) internal pure returns (uint256) {
        require(index < elements);
        return (uint16a16.unwrap(va) >> (bits * index)) & max;
    }

    /**
     * @notice Sets element to packed array.
     * @param va Packed array.
     * @param index Index under which to store the element
     * @param ev Element to store.
     * @return va Packed array with stored element.
     */
    function set(uint16a16 va, uint256 index, uint256 ev) internal pure returns (uint16a16) {
        require(index < elements);
        require(ev < range);
        index *= bits;
        return uint16a16.wrap((uint16a16.unwrap(va) & ~(max << index)) | (ev << index));
    }

    /**
     * @notice Sets elements to packed array.
     * Elements are stored continuously from index 0 onwards.
     * @param va Packed array.
     * @param ev Elements to store.
     * @return va Packed array with stored elements.
     */
    function set(uint16a16 va, uint256[] memory ev) internal pure returns (uint16a16) {
        for (uint256 i; i < ev.length; ++i) {
            va = set(va, i, ev[i]);
        }

        return va;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./ISmartVault.sol";
import "../libraries/uint16a16Lib.sol";

/**
 * @notice Used when deposited assets are not the same length as underlying assets.
 */
error InvalidAssetLengths();

/**
 * @notice Used when lengths of NFT id and amount arrays when claiming NFTs don't match.
 */
error InvalidNftArrayLength();

/**
 * @notice Used when there are no pending deposits to recover.
 * E.g., they were already recovered or flushed.
 */
error NoDepositsToRecover();

/**
 * @notice Used when trying to recover pending deposits from a smart vault that has non-ghost strategies.
 */
error NotGhostVault();

/**
 * @notice Gathers input for depositing assets.
 * @custom:member smartVault Smart vault for which the deposit is made.
 * @custom:member assets Amounts of assets being deposited.
 * @custom:member receiver Receiver of the deposit NFT.
 * @custom:member referral Referral address.
 * @custom:member doFlush If true, the smart vault will be flushed after the deposit as part of same transaction.
 */
struct DepositBag {
    address smartVault;
    uint256[] assets;
    address receiver;
    address referral;
    bool doFlush;
}

/**
 * @notice Gathers extra input for depositing assets.
 * @custom:member depositor Address making the deposit.
 * @custom:member tokens Tokens of the smart vault.
 * @custom:member strategies Strategies of the smart vault.
 * @custom:member allocations Set allocation of funds between strategies.
 * @custom:member flushIndex Current flush index of the smart vault.
 */
struct DepositExtras {
    address depositor;
    address[] tokens;
    address[] strategies;
    uint16a16 allocations;
    uint256 flushIndex;
}

/**
 * @notice Gathers minted SVTs for a specific fee type.
 * @custom:member depositFees Minted SVTs for deposit fees.
 * @custom:member performanceFees Minted SVTs for performance fees.
 * @custom:member managementFees Minted SVTs for management fees.
 */
struct SmartVaultFeesCollected {
    uint256 depositFees;
    uint256 performanceFees;
    uint256 managementFees;
}

/**
 * @notice Gathers return values of syncing deposits.
 * @custom:member mintedSVTs Amount of SVTs minted.
 * @custom:member dhwTimestamp Timestamp of the last DHW synced.
 * @custom:member feeSVTs Amount of SVTs minted as fees.
 * @custom:member feesCollected Breakdown of amount of SVTs minted as fees.
 * @custom:member initialLockedSVTs Amount of initial locked SVTs.
 * @custom:member sstShares Amount of SSTs claimed for each strategy.
 */
struct DepositSyncResult {
    uint256 mintedSVTs;
    uint256 dhwTimestamp;
    uint256 feeSVTs;
    SmartVaultFeesCollected feesCollected;
    uint256 initialLockedSVTs;
    uint256[] sstShares;
}

/**
 * @custom:member smartVault Smart Vault address
 * @custom:member bag flush index, lastDhwSyncedTimestamp
 * @custom:member strategies strategy addresses
 * @custom:member assetGroup vault asset group token addresses
 * @custom:member dhwIndexes DHW Indexes for given flush index
 * @custom:member dhwIndexesOld DHW Indexes for previous flush index
 * @custom:member fees smart vault fee configuration
 * @return syncResult Result of the smart vault sync.
 */
struct SimulateDepositParams {
    address smartVault;
    // bag[0]: flushIndex,
    // bag[1]: lastDhwSyncedTimestamp,
    uint256[2] bag;
    address[] strategies;
    address[] assetGroup;
    uint16a16 dhwIndexes;
    uint16a16 dhwIndexesOld;
    SmartVaultFees fees;
}

interface IDepositManager {
    /**
     * @notice User redeemed deposit NFTs for SVTs
     * @param smartVault Smart vault address
     * @param claimer Claimer address
     * @param claimedVaultTokens Amount of SVTs claimed
     * @param nftIds NFTs to burn
     * @param nftAmounts NFT shares to burn
     */
    event SmartVaultTokensClaimed(
        address indexed smartVault,
        address indexed claimer,
        uint256 claimedVaultTokens,
        uint256[] nftIds,
        uint256[] nftAmounts
    );

    /**
     * @notice A deposit has been initiated
     * @param smartVault Smart vault address
     * @param receiver Beneficiary of the deposit
     * @param depositId Deposit NFT ID for this deposit
     * @param flushIndex Flush index the deposit was scheduled for
     * @param assets Amount of assets to deposit
     * @param depositor Address that initiated the deposit
     * @param referral Referral address
     */
    event DepositInitiated(
        address indexed smartVault,
        address indexed receiver,
        uint256 indexed depositId,
        uint256 flushIndex,
        uint256[] assets,
        address depositor,
        address referral
    );

    /**
     * @notice Pending deposits were recovered.
     * @param smartVault Smart vault address.
     * @param recoveredAssets Amount of assets recovered.
     */
    event PendingDepositsRecovered(address indexed smartVault, uint256[] recoveredAssets);

    /**
     * @notice Smart vault fees collected.
     * @param smartVault Smart vault address.
     * @param smartVaultFeesCollected Collected smart vault fee amounts.
     */
    event SmartVaultFeesMinted(address indexed smartVault, SmartVaultFeesCollected smartVaultFeesCollected);

    /**
     * @notice Simulate vault synchronization (i.e. DHW was completed, but vault wasn't synced yet)
     */
    function syncDepositsSimulate(SimulateDepositParams calldata parameters)
        external
        view
        returns (DepositSyncResult memory syncResult);

    /**
     * @notice Synchronize vault deposits for completed DHW runs
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart Vault address
     * @param bag flushIndex, lastDhwSyncedTimestamp
     * @param strategies vault strategy addresses
     * @param dhwIndexes dhw indexes for given and previous flushIndex
     * @param assetGroup vault asset group token addresses
     * @param fees smart vault fee configuration
     * @return syncResult Result of the smart vault sync.
     */
    function syncDeposits(
        address smartVault,
        uint256[2] calldata bag,
        // uint256 flushIndex,
        // uint256 lastDhwSyncedTimestamp
        address[] calldata strategies,
        uint16a16[2] calldata dhwIndexes,
        address[] calldata assetGroup,
        SmartVaultFees calldata fees
    ) external returns (DepositSyncResult memory syncResult);

    /**
     * @notice Adds deposits for the next flush cycle.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param bag Deposit parameters.
     * @param bag2 Extra parameters.
     * @return nftId ID of the deposit NFT.
     */
    function depositAssets(DepositBag calldata bag, DepositExtras calldata bag2) external returns (uint256 nftId);

    /**
     * @notice Mark deposits ready to be processed in the next DHW cycle
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart Vault address
     * @param flushIndex index to flush
     * @param strategies vault strategy addresses
     * @param allocations vault strategy allocations
     * @param tokens vault asset group token addresses
     * @return dhwIndexes DHW indexes in which the deposits will be included
     */
    function flushSmartVault(
        address smartVault,
        uint256 flushIndex,
        address[] calldata strategies,
        uint16a16 allocations,
        address[] calldata tokens
    ) external returns (uint16a16 dhwIndexes);

    /**
     * @notice Get the number of SVTs that are available, but haven't been claimed yet, for the given NFT
     * @param smartVaultAddress Smart Vault address
     * @param data NFT deposit NFT metadata
     * @param nftShares amount of NFT shares to burn for SVTs
     * @param mintedSVTs amount of SVTs minted for this flush
     * @param tokens vault asset group addresses
     */
    function getClaimedVaultTokensPreview(
        address smartVaultAddress,
        DepositMetadata memory data,
        uint256 nftShares,
        uint256 mintedSVTs,
        address[] calldata tokens
    ) external view returns (uint256);

    /**
     * @notice Fetch assets deposited in a given vault flush
     */
    function smartVaultDeposits(address smartVault, uint256 flushIdx, uint256 assetGroupLength)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Claim SVTs by burning deposit NFTs.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart Vault address
     * @param nftIds NFT ids to burn
     * @param nftAmounts NFT amounts to burn (support for partial burn)
     * @param tokens vault asset group token addresses
     * @param owner address owning NFTs
     * @param executor address executing the claim transaction
     * @param flushIndexToSync next flush index to sync for the smart vault
     * @return claimedTokens Amount of smart vault tokens claimed.
     */
    function claimSmartVaultTokens(
        address smartVault,
        uint256[] calldata nftIds,
        uint256[] calldata nftAmounts,
        address[] calldata tokens,
        address owner,
        address executor,
        uint256 flushIndexToSync
    ) external returns (uint256 claimedTokens);

    /**
     * @notice Recovers pending deposits from smart vault.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault from which to recover pending deposits.
     * @param flushIndex Flush index for which to recover pending deposits.
     * @param strategies Addresses of smart vault's strategies.
     * @param tokens Asset group token addresses.
     * @param emergencyWallet Address of emergency withdraw wallet.
     */
    function recoverPendingDeposits(
        address smartVault,
        uint256 flushIndex,
        address[] calldata strategies,
        address[] calldata tokens,
        address emergencyWallet
    ) external;

    /**
     * @notice Gets current required deposit ratio of a smart vault.
     * @param tokens Asset tokens of the smart vault.
     * @param allocations Allocation between strategies of the smart vault.
     * @param strategies Strategies of the smart vault.
     * @return ratio Required deposit ratio of the smart vault.
     */
    function getDepositRatio(address[] memory tokens, uint16a16 allocations, address[] memory strategies)
        external
        view
        returns (uint256[] memory ratio);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/* ========== STRUCTS ========== */

/**
 * @notice Information needed to make a swap of assets.
 * @custom:member swapTarget Contract executing the swap.
 * @custom:member token Token to be swapped.
 * @custom:member swapCallData Calldata describing the swap itself.
 */
struct SwapInfo {
    address swapTarget;
    address token;
    bytes swapCallData;
}

/* ========== ERRORS ========== */

/**
 * @notice Used when trying to do a swap via an exchange that is not allowed to execute a swap.
 * @param exchange Exchange used.
 */
error ExchangeNotAllowed(address exchange);

/**
 * @notice Used when trying to execute a swap but are not authorized.
 * @param caller Caller of the swap method.
 */
error NotSwapper(address caller);

/* ========== INTERFACES ========== */

interface ISwapper {
    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when the exchange allowlist is updated.
     * @param exchange Exchange that was updated.
     * @param isAllowed Whether the exchange is allowed to be used in a swap or not after the update.
     */
    event ExchangeAllowlistUpdated(address indexed exchange, bool isAllowed);

    event Swapped(
        address indexed receiver, address[] tokensIn, address[] tokensOut, uint256[] amountsIn, uint256[] amountsOut
    );

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Performs a swap of tokens with external contracts.
     * - deposit tokens into the swapper contract
     * - swapper will swap tokens based on swap info provided
     * - swapper will return unswapped tokens to the receiver
     * @param tokensIn Addresses of tokens available for the swap.
     * @param swapInfo Information needed to perform the swap.
     * @param tokensOut Addresses of tokens to swap to.
     * @param receiver Receiver of unswapped tokens.
     * @return amountsOut Amounts of `tokensOut` sent from the swapper to the receiver.
     */
    function swap(
        address[] calldata tokensIn,
        SwapInfo[] calldata swapInfo,
        address[] calldata tokensOut,
        address receiver
    ) external returns (uint256[] memory amountsOut);

    /**
     * @notice Updates list of exchanges that can be used in a swap.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SPOOL_ADMIN
     *   - exchanges and allowed arrays need to be of same length
     * @param exchanges Addresses of exchanges.
     * @param allowed Whether an exchange is allowed to be used in a swap.
     */
    function updateExchangeAllowlist(address[] calldata exchanges, bool[] calldata allowed) external;

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Checks if an exchange is allowed to be used in a swap.
     * @param exchange Exchange to check.
     * @return isAllowed True if the exchange is allowed to be used in a swap, false otherwise.
     */
    function isExchangeAllowed(address exchange) external view returns (bool isAllowed);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../libraries/uint16a16Lib.sol";

/**
 * @notice Used when trying to burn withdrawal NFT that was not synced yet.
 * @param id ID of the NFT.
 */
error WithdrawalNftNotSyncedYet(uint256 id);

/**
 * @notice Base information for redeemal.
 * @custom:member smartVault Smart vault from which to redeem.
 * @custom:member shares Amount of smart vault shares to redeem.
 * @custom:member nftIds IDs of deposit NFTs to burn before redeemal.
 * @custom:member nftAmounts Amounts of NFT shares to burn.
 */
struct RedeemBag {
    address smartVault;
    uint256 shares;
    uint256[] nftIds;
    uint256[] nftAmounts;
}

/**
 * @notice Extra information for fast redeemal.
 * @custom:member strategies Strategies of the smart vault.
 * @custom:member assetGroup Asset group of the smart vault.
 * @custom:member assetGroupId ID of the asset group of the smart vault.
 * @custom:member redeemer Address that initiated the redeemal.
 * @custom:member withdrawalSlippages Slippages used to guard redeemal.
 */
struct RedeemFastExtras {
    address[] strategies;
    address[] assetGroup;
    uint256 assetGroupId;
    address redeemer;
    uint256[][] withdrawalSlippages;
}

/**
 * @notice Extra information for redeemal.
 * @custom:member receiver Receiver of the withdraw NFT.
 * @custom:member owner Address that owns the shares being redeemed.
 * @custom:member executor Address that initiated the redeemal.
 * @custom:member flushIndex Current flush index of the smart vault.
 */
struct RedeemExtras {
    address receiver;
    address owner;
    address executor;
    uint256 flushIndex;
}

/**
 * @notice Information used to claim withdrawal.
 * @custom:member smartVault Smart vault from which to claim withdrawal.
 * @custom:member nftIds Withdrawal NFTs to burn while claiming withdrawal.
 * @custom:member nftAmounts Amounts of NFT shares to burn.
 * @custom:member receiver Receiver of withdrawn assets.
 * @custom:member executor Address that initiated the withdrawal claim.
 * @custom:member assetGroupId ID of the asset group of the smart vault.
 * @custom:member assetGroup Asset group of the smart vault.
 * @custom:member flushIndexToSync Next flush index to sync for the smart vault.
 */
struct WithdrawalClaimBag {
    address smartVault;
    uint256[] nftIds;
    uint256[] nftAmounts;
    address receiver;
    address executor;
    uint256 assetGroupId;
    address[] assetGroup;
    uint256 flushIndexToSync;
}

interface IWithdrawalManager {
    /**
     * @notice User redeemed withdrawal NFTs for underlying assets
     * @param smartVault Smart vault address
     * @param claimer Claimer address
     * @param nftIds NFTs to burn
     * @param nftAmounts NFT shares to burn
     * @param withdrawnAssets Amount of underlying assets withdrawn
     */
    event WithdrawalClaimed(
        address indexed smartVault,
        address indexed claimer,
        uint256 assetGroupId,
        uint256[] nftIds,
        uint256[] nftAmounts,
        uint256[] withdrawnAssets
    );

    /**
     * @notice A deposit has been initiated
     * @param smartVault Smart vault address
     * @param owner Owner of shares to be redeemed
     * @param redeemId Withdrawal NFT ID for this redeemal
     * @param flushIndex Flush index the redeem was scheduled for
     * @param shares Amount of vault shares to redeem
     * @param receiver Beneficiary that will be able to claim the underlying assets
     */
    event RedeemInitiated(
        address indexed smartVault,
        address indexed owner,
        uint256 indexed redeemId,
        uint256 flushIndex,
        uint256 shares,
        address receiver
    );

    /**
     * @notice A deposit has been initiated
     * @param smartVault Smart vault address
     * @param redeemer Redeem initiator and owner of shares
     * @param shares Amount of vault shares to redeem
     * @param nftIds NFTs to burn
     * @param nftAmounts NFT shares to burn
     * @param assetsWithdrawn Amount of underlying assets withdrawn
     */
    event FastRedeemInitiated(
        address indexed smartVault,
        address indexed redeemer,
        uint256 shares,
        uint256[] nftIds,
        uint256[] nftAmounts,
        uint256[] assetsWithdrawn
    );

    /**
     * @notice Flushes smart vaults deposits and withdrawals to the strategies.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault to flush.
     * @param flushIndex Current flush index of the smart vault.
     * @param strategies Strategies of the smart vault.
     * @return dhwIndexes current do-hard-work indexes of the strategies.
     */
    function flushSmartVault(address smartVault, uint256 flushIndex, address[] calldata strategies)
        external
        returns (uint16a16 dhwIndexes);

    /**
     * @notice Claims withdrawal.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SMART_VAULT_MANAGER
     * @param bag Parameters for claiming withdrawal.
     * @return withdrawnAssets Amount of assets withdrawn.
     * @return assetGroupId ID of the asset group.
     */
    function claimWithdrawal(WithdrawalClaimBag calldata bag)
        external
        returns (uint256[] memory withdrawnAssets, uint256 assetGroupId);

    /**
     * @notice Syncs withdrawals between strategies and smart vault after do-hard-works.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault to sync.
     * @param flushIndex Smart vault's flush index to sync.
     * @param strategies Strategies of the smart vault.
     * @param dhwIndexes_ Strategies' do-hard-work indexes to sync.
     */
    function syncWithdrawals(
        address smartVault,
        uint256 flushIndex,
        address[] calldata strategies,
        uint16a16 dhwIndexes_
    ) external;

    /**
     * @notice Redeems smart vault shares.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SMART_VAULT_MANAGER
     * @param bag Base information for redeemal.
     * @param bag2 Extra information for redeemal.
     * @return nftId ID of the withdrawal NFT.
     */
    function redeem(RedeemBag calldata bag, RedeemExtras calldata bag2) external returns (uint256 nftId);

    /**
     * @notice Instantly redeems smart vault shares.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SMART_VAULT_MANAGER
     * @param bag Base information for redeemal.
     * @param bag Extra information for fast redeemal.
     * @return assets Amount of assets withdrawn.
     */
    function redeemFast(RedeemBag calldata bag, RedeemFastExtras memory bag2)
        external
        returns (uint256[] memory assets);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./ISwapper.sol";
import {DhwInfo} from "./IStrategy.sol";
import "../libraries/uint16a16Lib.sol";

/* ========== ERRORS ========== */

/**
 * @notice Used when trying to register an already registered strategy.
 * @param address_ Address of already registered strategy.
 */
error StrategyAlreadyRegistered(address address_);

/**
 * @notice Used when DHW was not run yet for a strategy index.
 * @param strategy Address of the strategy.
 * @param strategyIndex Index of the strategy.
 */
error DhwNotRunYetForIndex(address strategy, uint256 strategyIndex);

/**
 * @notice Used when provided token list is invalid.
 */
error InvalidTokenList();

/**
 * @notice Used when ghost strategy is used.
 */
error GhostStrategyUsed();

/**
 * @notice Used when syncing vault that is already fully synced.
 */
error NothingToSync();

/**
 * @notice Used when system tries to configure a too large ecosystem fee.
 * @param ecosystemFeePct Requested ecosystem fee.
 */
error EcosystemFeeTooLarge(uint256 ecosystemFeePct);

/**
 * @notice Used when system tries to configure a too large treasury fee.
 * @param treasuryFeePct Requested treasury fee.
 */
error TreasuryFeeTooLarge(uint256 treasuryFeePct);

/**
 * @notice Used when user tries to re-add a strategy that was previously removed from the system.
 * @param strategy Strategy address
 */
error StrategyPreviouslyRemoved(address strategy);

/**
 * @notice Represents change of state for a strategy during a DHW.
 * @custom:member exchangeRates Exchange rates between assets and USD.
 * @custom:member assetsDeposited Amount of assets deposited into the strategy.
 * @custom:member sharesMinted Amount of strategy shares minted.
 * @custom:member totalSSTs Amount of strategy shares at the end of the DHW.
 * @custom:member totalStrategyValue Total strategy value at the end of the DHW.
 * @custom:member dhwYields DHW yield percentage from the previous DHW.
 */
struct StrategyAtIndex {
    uint256[] exchangeRates;
    uint256[] assetsDeposited;
    uint256 sharesMinted;
    uint256 totalSSTs;
    uint256 totalStrategyValue;
    int256 dhwYields;
}

/**
 * @notice Parameters for calling do hard work.
 * @custom:member strategies Strategies to do-hard-worked upon, grouped by their asset group.
 * @custom:member swapInfo Information for swapping assets before depositing into protocol. SwapInfo[] per each strategy.
 * @custom:member compoundSwapInfo Information for swapping rewards before depositing them back into the protocol. SwapInfo[] per each strategy.
 * @custom:member strategySlippages Slippages used to constrain depositing into and withdrawing from the protocol. uint256[] per strategy.
 * @custom:member baseYields Base yield percentage the strategy created in the DHW period (applicable only for some strategies).
 * @custom:member tokens List of all asset tokens involved in the do hard work.
 * @custom:member exchangeRateSlippages Slippages used to constrain exchange rates for asset tokens. uint256[2] for each token.
 * @custom:member validUntil Sets the maximum timestamp the user is willing to wait to start executing 'do hard work'.
 */
struct DoHardWorkParameterBag {
    address[][] strategies;
    SwapInfo[][][] swapInfo;
    SwapInfo[][][] compoundSwapInfo;
    uint256[][][] strategySlippages;
    int256[][] baseYields;
    address[] tokens;
    uint256[2][] exchangeRateSlippages;
    uint256 validUntil;
}

/**
 * @notice Parameters for calling redeem fast.
 * @custom:member strategies Addresses of strategies.
 * @custom:member strategyShares Amount of shares to redeem.
 * @custom:member assetGroup Asset group of the smart vault.
 * @custom:member slippages Slippages to guard withdrawal.
 */
struct RedeemFastParameterBag {
    address[] strategies;
    uint256[] strategyShares;
    address[] assetGroup;
    uint256[][] withdrawalSlippages;
}

/**
 * @notice Group of platform fees.
 * @custom:member ecosystemFeeReciever Receiver of the ecosystem fees.
 * @custom:member ecosystemFeePct Ecosystem fees. Expressed in FULL_PERCENT.
 * @custom:member treasuryFeeReciever Receiver of the treasury fees.
 * @custom:member treasuryFeePct Treasury fees. Expressed in FULL_PERCENT.
 */
struct PlatformFees {
    address ecosystemFeeReceiver;
    uint96 ecosystemFeePct;
    address treasuryFeeReceiver;
    uint96 treasuryFeePct;
}

/* ========== INTERFACES ========== */

interface IStrategyRegistry {
    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Returns address of emergency withdrawal wallet.
     * @return emergencyWithdrawalWallet Address of the emergency withdrawal wallet.
     */
    function emergencyWithdrawalWallet() external view returns (address emergencyWithdrawalWallet);

    /**
     * @notice Returns current do-hard-work indexes for strategies.
     * @param strategies Strategies.
     * @return dhwIndexes Current do-hard-work indexes for strategies.
     */
    function currentIndex(address[] calldata strategies) external view returns (uint256[] memory dhwIndexes);

    /**
     * @notice Returns current strategy APYs.
     * @param strategies Strategies.
     */
    function strategyAPYs(address[] calldata strategies) external view returns (int256[] memory apys);

    /**
     * @notice Returns assets deposited into a do-hard-work index for a strategy.
     * @param strategy Strategy.
     * @param dhwIndex Do-hard-work index.
     * @return assets Assets deposited into the do-hard-work index for the strategy.
     */
    function depositedAssets(address strategy, uint256 dhwIndex) external view returns (uint256[] memory assets);

    /**
     * @notice Returns shares redeemed in a do-hard-work index for a strategy.
     * @param strategy Strategy.
     * @param dhwIndex Do-hard-work index.
     * @return shares Shares redeemed in a do-hard-work index for the strategy.
     */
    function sharesRedeemed(address strategy, uint256 dhwIndex) external view returns (uint256 shares);

    /**
     * @notice Gets timestamps when do-hard-works were performed.
     * @param strategies Strategies.
     * @param dhwIndexes Do-hard-work indexes.
     * @return timestamps Timestamp for each pair of strategies and do-hard-work indexes.
     */
    function dhwTimestamps(address[] calldata strategies, uint16a16 dhwIndexes)
        external
        view
        returns (uint256[] memory timestamps);

    function getDhwYield(address[] calldata strategies, uint16a16 dhwIndexes)
        external
        view
        returns (int256[] memory yields);

    /**
     * @notice Returns state of strategies at do-hard-work indexes.
     * @param strategies Strategies.
     * @param dhwIndexes Do-hard-work indexes.
     * @return states State of each strategy at corresponding do-hard-work index.
     */
    function strategyAtIndexBatch(address[] calldata strategies, uint16a16 dhwIndexes, uint256 assetGroupLength)
        external
        view
        returns (StrategyAtIndex[] memory states);

    /**
     * @notice Gets required asset ratio for strategy at last DHW.
     * @param strategy Address of the strategy.
     * @return assetRatio Asset ratio.
     */
    function assetRatioAtLastDhw(address strategy) external view returns (uint256[] memory assetRatio);

    /**
     * @notice Gets set platform fees.
     * @return fees Set platform fees.
     */
    function platformFees() external view returns (PlatformFees memory fees);

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Registers a strategy into the system.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param strategy Address of strategy to register.
     * @param apy Apy of the strategy at the time of the registration.
     */
    function registerStrategy(address strategy, int256 apy) external;

    /**
     * @notice Removes strategy from the system.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param strategy Strategy to remove.
     */
    function removeStrategy(address strategy) external;

    /**
     * @notice Sets ecosystem fee.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param ecosystemFeePct Ecosystem fee to set. Expressed in terms of FULL_PERCENT.
     */
    function setEcosystemFee(uint96 ecosystemFeePct) external;

    /**
     * @notice Sets receiver of the ecosystem fees.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param ecosystemFeeReceiver Receiver to set.
     */
    function setEcosystemFeeReceiver(address ecosystemFeeReceiver) external;

    /**
     * @notice Sets treasury fee.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param treasuryFeePct Treasury fee to set. Expressed in terms of FULL_PERCENT.
     */
    function setTreasuryFee(uint96 treasuryFeePct) external;

    /**
     * @notice Sets treasury fee receiver.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param treasuryFeeReceiver Receiver to set.
     */
    function setTreasuryFeeReceiver(address treasuryFeeReceiver) external;

    /**
     * @notice Does hard work on multiple strategies.
     * @dev Requirements:
     * - caller must have role ROLE_DO_HARD_WORKER
     * @param dhwParams Parameters for do hard work.
     */
    function doHardWork(DoHardWorkParameterBag calldata dhwParams) external;

    /**
     * @notice Adds deposits to strategies to be processed at next do-hard-work.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param strategies Strategies to which to add deposit.
     * @param amounts Amounts of assets to add to each strategy.
     * @return strategyIndexes Current do-hard-work indexes for the strategies.
     */
    function addDeposits(address[] calldata strategies, uint256[][] calldata amounts)
        external
        returns (uint16a16 strategyIndexes);

    /**
     * @notice Adds withdrawals to strategies to be processed at next do-hard-work.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param strategies Strategies to which to add withdrawal.
     * @param strategyShares Amounts of strategy shares to add to each strategy.
     * @return strategyIndexes Current do-hard-work indexes for the strategies.
     */
    function addWithdrawals(address[] calldata strategies, uint256[] calldata strategyShares)
        external
        returns (uint16a16 strategyIndexes);

    /**
     * @notice Instantly redeems strategy shares for assets.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param redeemFastParams Parameters for fast redeem.
     * @return withdrawnAssets Amount of assets withdrawn.
     */
    function redeemFast(RedeemFastParameterBag calldata redeemFastParams)
        external
        returns (uint256[] memory withdrawnAssets);

    /**
     * @notice Claims withdrawals from the strategies.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * - DHWs must be run for withdrawal indexes.
     * @param strategies Addresses if strategies from which to claim withdrawal.
     * @param dhwIndexes Indexes of strategies when withdrawal was made.
     * @param strategyShares Amount of strategy shares that was withdrawn.
     * @return assetsWithdrawn Amount of assets withdrawn from strategies.
     */
    function claimWithdrawals(address[] calldata strategies, uint16a16 dhwIndexes, uint256[] calldata strategyShares)
        external
        returns (uint256[] memory assetsWithdrawn);

    /**
     * @notice Redeems strategy shares.
     * Used by recipients of platform fees.
     * @param strategies Strategies from which to redeem.
     * @param shares Amount of shares to redeem from each strategy.
     * @param withdrawalSlippages Slippages to guard redeemal process.
     */
    function redeemStrategyShares(
        address[] calldata strategies,
        uint256[] calldata shares,
        uint256[][] calldata withdrawalSlippages
    ) external;

    /**
     * @notice Strategy was registered
     * @param strategy Strategy address
     */
    event StrategyRegistered(address indexed strategy);

    /**
     * @notice Strategy was removed
     * @param strategy Strategy address
     */
    event StrategyRemoved(address indexed strategy);

    /**
     * @notice Strategy DHW was executed
     * @param strategy Strategy address
     * @param dhwIndex DHW index
     * @param dhwInfo DHW info
     */
    event StrategyDhw(address indexed strategy, uint256 dhwIndex, DhwInfo dhwInfo);

    /**
     * @notice Ecosystem fee configuration was changed
     * @param feePct Fee percentage value
     */
    event EcosystemFeeSet(uint256 feePct);

    /**
     * @notice Ecosystem fee receiver was changed
     * @param ecosystemFeeReceiver Receiver address
     */
    event EcosystemFeeReceiverSet(address indexed ecosystemFeeReceiver);

    /**
     * @notice Treasury fee configuration was changed
     * @param feePct Fee percentage value
     */
    event TreasuryFeeSet(uint256 feePct);

    /**
     * @notice Treasury fee receiver was changed
     * @param treasuryFeeReceiver Receiver address
     */
    event TreasuryFeeReceiverSet(address indexed treasuryFeeReceiver);

    /**
     * @notice Emergency withdrawal wallet changed
     * @param wallet Emergency withdrawal wallet address
     */
    event EmergencyWithdrawalWalletSet(address indexed wallet);

    /**
     * @notice Strategy shares have been redeemed
     * @param strategy Strategy address
     * @param owner Address that owns the shares
     * @param recipient Address that received the withdrawn funds
     * @param shares Amount of shares that were redeemed
     * @param assetsWithdrawn Amounts of withdrawn assets
     */
    event StrategySharesRedeemed(
        address indexed strategy,
        address indexed owner,
        address indexed recipient,
        uint256 shares,
        uint256[] assetsWithdrawn
    );

    /**
     * @notice Strategy shares were fast redeemed
     * @param strategy Strategy address
     * @param shares Amount of shares redeemed
     * @param assetsWithdrawn Amounts of withdrawn assets
     */
    event StrategySharesFastRedeemed(address indexed strategy, uint256 shares, uint256[] assetsWithdrawn);

    /**
     * @notice Strategy APY value was updated
     * @param strategy Strategy address
     * @param apy New APY value
     */
    event StrategyApyUpdated(address indexed strategy, int256 apy);
}

interface IEmergencyWithdrawal {
    /**
     * @notice Emitted when a strategy is emergency withdrawn from.
     * @param strategy Strategy that was emergency withdrawn from.
     */
    event StrategyEmergencyWithdrawn(address indexed strategy);

    /**
     * @notice Set a new address that will receive assets withdrawn if emergency withdrawal is executed.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param wallet Address to set as the emergency withdrawal wallet.
     */
    function setEmergencyWithdrawalWallet(address wallet) external;

    /**
     * @notice Instantly withdraws assets from a strategy, bypassing shares mechanism.
     * @dev Requirements:
     * - caller must have role ROLE_EMERGENCY_WITHDRAWAL_EXECUTOR
     * @param strategies Addresses of strategies.
     * @param withdrawalSlippages Slippages to guard withdrawal.
     * @param removeStrategies Whether to remove strategies from the system after withdrawal.
     */
    function emergencyWithdraw(
        address[] calldata strategies,
        uint256[][] calldata withdrawalSlippages,
        bool removeStrategies
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @dev Number of decimals used for USD values.
uint256 constant USD_DECIMALS = 18;

/**
 * @notice Emitted when asset is invalid.
 * @param asset Invalid asset.
 */
error InvalidAsset(address asset);

/**
 * @notice Emitted when price returned by price aggregator is negative or zero.
 * @param price Actual price returned by price aggregator.
 */
error NonPositivePrice(int256 price);

/**
 * @notice Emitted when pricing data returned by price aggregator is not from the current
 * round or the round hasn't finished.
 */
error StalePriceData();

interface IUsdPriceFeedManager {
    /**
     * @notice Gets number of decimals for an asset.
     * @param asset Address of the asset.
     * @return assetDecimals Number of decimals for the asset.
     */
    function assetDecimals(address asset) external view returns (uint256 assetDecimals);

    /**
     * @notice Gets number of decimals for USD.
     * @return usdDecimals Number of decimals for USD.
     */
    function usdDecimals() external view returns (uint256 usdDecimals);

    /**
     * @notice Calculates asset value in USD using current price.
     * @param asset Address of asset.
     * @param assetAmount Amount of asset in asset decimals.
     * @return usdValue Value in USD in USD decimals.
     */
    function assetToUsd(address asset, uint256 assetAmount) external view returns (uint256 usdValue);

    /**
     * @notice Calculates USD value in asset using current price.
     * @param asset Address of asset.
     * @param usdAmount Amount of USD in USD decimals.
     * @return assetValue Value in asset in asset decimals.
     */
    function usdToAsset(address asset, uint256 usdAmount) external view returns (uint256 assetValue);

    /**
     * @notice Calculates asset value in USD using provided price.
     * @param asset Address of asset.
     * @param assetAmount Amount of asset in asset decimals.
     * @param price Price of asset in USD.
     * @return usdValue Value in USD in USD decimals.
     */
    function assetToUsdCustomPrice(address asset, uint256 assetAmount, uint256 price)
        external
        view
        returns (uint256 usdValue);

    /**
     * @notice Calculates assets value in USD using provided prices.
     * @param assets Addresses of assets.
     * @param assetAmounts Amounts of assets in asset decimals.
     * @param prices Prices of asset in USD.
     * @return usdValue Value in USD in USD decimals.
     */
    function assetToUsdCustomPriceBulk(
        address[] calldata assets,
        uint256[] calldata assetAmounts,
        uint256[] calldata prices
    ) external view returns (uint256 usdValue);

    /**
     * @notice Calculates USD value in asset using provided price.
     * @param asset Address of asset.
     * @param usdAmount Amount of USD in USD decimals.
     * @param price Price of asset in USD.
     * @return assetValue Value in asset in asset decimals.
     */
    function usdToAssetCustomPrice(address asset, uint256 usdAmount, uint256 price)
        external
        view
        returns (uint256 assetValue);
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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/cryptography/EIP712Upgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 51
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
    }

    function __ERC20Permit_init_unchained(string memory) internal onlyInitializing {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
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

library ArrayMappingUint256 {
    /**
     * @notice Map mapping(uint256 => uint256)) values to an array.
     */
    function toArray(mapping(uint256 => uint256) storage _self, uint256 length)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory arrayOut = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            arrayOut[i] = _self[i];
        }
        return arrayOut;
    }

    /**
     * @notice Set array values to mapping slots.
     */
    function setValues(mapping(uint256 => uint256) storage _self, uint256[] calldata values) external {
        for (uint256 i; i < values.length; ++i) {
            _self[i] = values[i];
        }
    }
}

library ArrayMappingAddress {
    /**
     * @notice Map mapping(uint256 => address)) values to an array.
     */
    function toArray(mapping(uint256 => address) storage _self, uint256 length)
        external
        view
        returns (address[] memory)
    {
        address[] memory arrayOut = new address[](length);
        for (uint256 i; i < length; ++i) {
            arrayOut[i] = _self[i];
        }
        return arrayOut;
    }

    /**
     * @notice Set array values to mapping slots.
     */
    function setValues(mapping(uint256 => address) storage _self, address[] calldata values) external {
        for (uint256 i; i < values.length; ++i) {
            _self[i] = values[i];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
library SignedMath {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}