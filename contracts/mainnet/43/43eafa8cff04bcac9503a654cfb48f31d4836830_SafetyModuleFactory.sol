// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.22 ^0.8.0 ^0.8.20;

// lib/cozy-safety-module-shared/src/interfaces/IDripModel.sol

interface IDripModel {
  /// @notice Returns the drip factor, given the `lastDripTime_` and `initialAmount_`.
  function dripFactor(uint256 lastDripTime_, uint256 initialAmount_) external view returns (uint256 dripFactor_);
}

// lib/cozy-safety-module-shared/src/interfaces/IERC20.sol

/**
 * @dev Interface for ERC20 tokens.
 */
interface IERC20 {
  /// @dev Emitted when the allowance of a `spender_` for an `owner_` is updated, where `amount_` is the new allowance.
  event Approval(address indexed owner_, address indexed spender_, uint256 value_);
  /// @dev Emitted when `amount_` tokens are moved from `from_` to `to_`.
  event Transfer(address indexed from_, address indexed to_, uint256 value_);

  /// @notice Returns the remaining number of tokens that `spender_` will be allowed to spend on behalf of `holder_`.
  function allowance(address owner_, address spender_) external view returns (uint256);

  /// @notice Sets `amount_` as the allowance of `spender_` over the caller's tokens.
  function approve(address spender_, uint256 amount_) external returns (bool);

  /// @notice Returns the amount of tokens owned by `account_`.
  function balanceOf(address account_) external view returns (uint256);

  /// @notice Returns the decimal places of the token.
  function decimals() external view returns (uint8);

  /// @notice Sets `value_` as the allowance of `spender_` over `owner_`s tokens, given a signed approval from the
  /// owner.
  function permit(address owner_, address spender_, uint256 value_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_)
    external;

  /// @notice Returns the name of the token.
  function name() external view returns (string memory);

  /// @notice Returns the nonce of `owner_`.
  function nonces(address owner_) external view returns (uint256);

  /// @notice Returns the symbol of the token.
  function symbol() external view returns (string memory);

  /// @notice Returns the amount of tokens in existence.
  function totalSupply() external view returns (uint256);

  /// @notice Moves `amount_` tokens from the caller's account to `to_`.
  function transfer(address to_, uint256 amount_) external returns (bool);

  /// @notice Moves `amount_` tokens from `from_` to `to_` using the allowance mechanism. `amount`_ is then deducted
  /// from the caller's allowance.
  function transferFrom(address from_, address to_, uint256 amount_) external returns (bool);
}

// lib/cozy-safety-module-shared/src/interfaces/IOwnable.sol

interface IOwnable {
  function owner() external view returns (address);
}

// lib/openzeppelin-contracts/contracts/proxy/Clones.sol

// OpenZeppelin Contracts (last updated v5.0.0) (proxy/Clones.sol)

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[ERC-1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 */
library Clones {
    /**
     * @dev A clone instance deployment failed.
     */
    error ERC1167FailedCreateClone();

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// src/lib/SafetyModuleStates.sol

enum SafetyModuleState {
  ACTIVE,
  TRIGGERED,
  PAUSED
}

enum TriggerState {
  ACTIVE,
  TRIGGERED,
  FROZEN
}

// src/lib/structs/Delays.sol

/// @notice Delays for the SafetyModule.
struct Delays {
  // Duration between when SafetyModule updates are queued and when they can be executed.
  uint64 configUpdateDelay;
  // Defines how long the owner has to execute a configuration change, once it can be executed.
  uint64 configUpdateGracePeriod;
  // Delay for two-step withdraw process (for deposited reserve assets).
  uint64 withdrawDelay;
}

// src/lib/structs/Slash.sol

struct Slash {
  // ID of the reserve pool.
  uint8 reservePoolId;
  // Asset amount that will be slashed from the reserve pool.
  uint256 amount;
}

// lib/cozy-safety-module-shared/src/interfaces/IReceiptToken.sol

interface IReceiptToken is IERC20 {
  /// @notice Burns `amount_` of tokens from `from`_.
  function burn(address caller_, address from_, uint256 amount_) external;

  /// @notice Replaces the constructor for minimal proxies.
  /// @param module_ The safety/rewards module for this ReceiptToken.
  /// @param name_ The name of the token.
  /// @param symbol_ The symbol of the token.
  /// @param decimals_ The decimal places of the token.
  function initialize(address module_, string memory name_, string memory symbol_, uint8 decimals_) external;

  /// @notice Mints `amount_` of tokens to `to_`.
  function mint(address to_, uint256 amount_) external;

  /// @notice Address of this token's safety/rewards module.
  function module() external view returns (address);
}

// src/interfaces/ITrigger.sol

/**
 * @dev The minimal functions a trigger must implement to work with SafetyModules.
 */
interface ITrigger {
  /// @notice The current trigger state.
  function state() external returns (TriggerState);
}

// lib/cozy-safety-module-shared/src/interfaces/IReceiptTokenFactory.sol

interface IReceiptTokenFactory {
  enum PoolType {
    RESERVE,
    STAKE,
    REWARD
  }

  /// @dev Emitted when a new ReceiptToken is deployed.
  event ReceiptTokenDeployed(
    IReceiptToken receiptToken,
    address indexed module,
    uint16 indexed poolId,
    PoolType indexed poolType,
    uint8 decimals_
  );

  /// @notice Given a `module_`, its `poolId_`, and `poolType_`, compute and return the address of its
  /// ReceiptToken.
  function computeAddress(address module_, uint16 poolId_, PoolType poolType_) external view returns (address);

  /// @notice Creates a new ReceiptToken contract with the given number of `decimals_`. The ReceiptToken's
  /// safety / rewards module is identified by the caller address. The pool id of the ReceiptToken in the module and
  /// its `PoolType` is used to generate a unique salt for deploy.
  function deployReceiptToken(uint16 poolId_, PoolType poolType_, uint8 decimals_)
    external
    returns (IReceiptToken receiptToken_);
}

// src/lib/structs/Pools.sol

struct AssetPool {
  // The total balance of assets held by a SafetyModule, should be equivalent to
  // token.balanceOf(address(this)), discounting any assets directly sent
  // to the SafetyModule via direct transfer.
  uint256 amount;
}

struct ReservePool {
  // The internally accounted total amount of assets held by the reserve pool. This amount includes
  // pendingWithdrawalsAmount.
  uint256 depositAmount;
  // The amount of assets that are currently queued for withdrawal from the reserve pool.
  uint256 pendingWithdrawalsAmount;
  // The amount of fees that have accumulated in the reserve pool since the last fee claim.
  uint256 feeAmount;
  // The max percentage of the reserve pool deposit amount that can be slashed in a SINGLE slash as a ZOC.
  // If multiple slashes occur, they compound, and the final deposit amount can be less than (1 - maxSlashPercentage)%
  // following all the slashes.
  uint256 maxSlashPercentage;
  // The underlying asset of the reserve pool.
  IERC20 asset;
  // The receipt token that represents reserve pool deposits.
  IReceiptToken depositReceiptToken;
  // The timestamp of the last time fees were dripped to the reserve pool.
  uint128 lastFeesDripTime;
}

// src/lib/structs/Redemptions.sol

struct Redemption {
  uint8 reservePoolId; // ID of the reserve pool.
  uint216 receiptTokenAmount; // Deposit receipt token amount burned to queue the redemption.
  IReceiptToken receiptToken; // The receipt token being redeemed.
  uint128 assetAmount; // Asset amount that will be paid out upon completion of the redemption.
  address owner; // Owner of the deposit tokens.
  address receiver; // Receiver of reserve assets.
  uint40 queueTime; // Timestamp at which the redemption was requested.
  uint40 delay; // SafetyModule redemption delay at the time of request.
  uint32 queuedAccISFsLength; // Length of pendingRedemptionAccISFs at queue time.
  uint256 queuedAccISF; // Last pendingRedemptionAccISFs value at queue time.
}

struct RedemptionPreview {
  uint40 delayRemaining; // SafetyModule redemption delay remaining.
  uint216 receiptTokenAmount; // Deposit receipt token amount burned to queue the redemption.
  IReceiptToken receiptToken; // The receipt token being redeemed.
  uint128 reserveAssetAmount; // Asset amount that will be paid out upon completion of the redemption.
  address owner; // Owner of the deposit receipt tokens.
  address receiver; // Receiver of the assets.
}

// src/lib/structs/Trigger.sol

struct Trigger {
  // Whether the trigger exists.
  bool exists;
  // The payout handler that is authorized to slash assets when the trigger is triggered.
  address payoutHandler;
  // Whether the trigger has triggered the SafetyModule. A trigger cannot trigger the SafetyModule more than once.
  bool triggered;
}

struct TriggerConfig {
  // The trigger that is being configured.
  ITrigger trigger;
  // The address that is authorized to slash assets when the trigger is triggered.
  address payoutHandler;
  // Whether the trigger is used by the SafetyModule.
  bool exists;
}

struct TriggerMetadata {
  // The name that should be used for SafetyModules that use the trigger.
  string name;
  // A human-readable description of the trigger.
  string description;
  // The URI of a logo image to represent the trigger.
  string logoURI;
  // Any extra data that should be included in the trigger's metadata.
  string extraData;
}

// src/lib/structs/Configs.sol

/// @notice Configuration for a reserve pool.
struct ReservePoolConfig {
  // The maximum percentage of the reserve pool assets that can be slashed in a single transaction, represented as a
  // ZOC. If multiple slashes occur, they compound, and the final reserve pool amount can be less than
  // (1 - maxSlashPercentage)% following all the slashes.
  uint256 maxSlashPercentage;
  // The underlying asset of the reserve pool.
  IERC20 asset;
}

/// @notice Metadata for a configuration update.
struct ConfigUpdateMetadata {
  // A hash representing queued `ReservePoolConfig[]`, TriggerConfig[], and `Delays` updates. This hash is
  // used to prove that the params used when applying config updates are identical to the queued updates.
  // This strategy is used instead of storing non-hashed `ReservePoolConfig[]`, `TriggerConfig[] and
  // `Delays` for gas optimization and to avoid dynamic array manipulation. This hash is set to bytes32(0) when there is
  // no config update queued.
  bytes32 queuedConfigUpdateHash;
  // Earliest timestamp at which finalizeUpdateConfigs can be called to apply config updates queued by updateConfigs.
  uint64 configUpdateTime;
  // The latest timestamp after configUpdateTime at which finalizeUpdateConfigs can be called to apply config
  // updates queued by updateConfigs. After this timestamp, the queued config updates expire and can no longer be
  // applied.
  uint64 configUpdateDeadline;
}

/// @notice Parameters for configuration updates.
struct UpdateConfigsCalldataParams {
  // The new reserve pool configs.
  ReservePoolConfig[] reservePoolConfigs;
  // The new trigger configs.
  TriggerConfig[] triggerConfigUpdates;
  // The new delays config.
  Delays delaysConfig;
}

// src/interfaces/ICozySafetyModuleManagerEvents.sol

/**
 * @dev Data types and events for the Manager.
 */
interface ICozySafetyModuleManagerEvents {
  /// @dev Emitted when accrued Cozy fees are swept from a SafetyModule to the Cozy Safety Module protocol owner.
  event ClaimedSafetyModuleFees(ISafetyModule indexed safetyModule_);

  /// @dev Emitted when the default fee drip model is updated by the Cozy Safety Module protocol owner.
  event FeeDripModelUpdated(IDripModel indexed feeDripModel_);

  /// @dev Emitted when an override fee drip model is updated by the Cozy Safety Module protocol owner.
  event OverrideFeeDripModelUpdated(ISafetyModule indexed safetyModule_, IDripModel indexed feeDripModel_);
}


// src/interfaces/ICozySafetyModuleManager.sol

interface ICozySafetyModuleManager is IOwnable, ICozySafetyModuleManagerEvents {
  /// @notice Deploys a new SafetyModule with the provided parameters.
  /// @param owner_ The owner of the SafetyModule.
  /// @param pauser_ The pauser of the SafetyModule.
  /// @param configs_ The configuration for the SafetyModule.
  /// @param salt_ Used to compute the resulting address of the SafetyModule.
  function createSafetyModule(
    address owner_,
    address pauser_,
    UpdateConfigsCalldataParams calldata configs_,
    bytes32 salt_
  ) external returns (ISafetyModule safetyModule_);

  /// @notice For the specified SafetyModule, returns whether it's a valid Cozy Safety Module.
  function isSafetyModule(ISafetyModule safetyModule_) external view returns (bool);

  /// @notice For the specified SafetyModule, returns the drip model used for fee accrual.
  function getFeeDripModel(ISafetyModule safetyModule_) external view returns (IDripModel);

  /// @notice Number of reserve pools allowed per SafetyModule.
  function allowedReservePools() external view returns (uint8);
}

// src/interfaces/ISafetyModule.sol

interface ISafetyModule {
  /// @notice The asset pools configured for this SafetyModule.
  /// @dev Used for doing aggregate accounting of reserve assets.
  function assetPools(IERC20 asset_) external view returns (AssetPool memory assetPool_);

  /// @notice Claims any accrued fees to the CozySafetyModuleManager owner.
  /// @dev Validation is handled in the CozySafetyModuleManager, which is the only account authorized to call this
  /// method.
  /// @param owner_ The address to transfer the fees to.
  /// @param dripModel_ The drip model to use for calculating fee drip.
  function claimFees(address owner_, IDripModel dripModel_) external;

  /// @notice Completes the redemption request for the specified redemption ID.
  /// @param redemptionId_ The ID of the redemption to complete.
  function completeRedemption(uint64 redemptionId_) external returns (uint256 assetAmount_);

  /// @notice Returns the receipt token amount for a given amount of reserve assets after taking into account
  /// any pending fee drip.
  /// @param reservePoolId_ The ID of the reserve pool to convert the reserve asset amount for.
  /// @param reserveAssetAmount_ The amount of reserve assets to convert to deposit receipt tokens.
  function convertToReceiptTokenAmount(uint8 reservePoolId_, uint256 reserveAssetAmount_)
    external
    view
    returns (uint256 depositReceiptTokenAmount_);

  /// @notice Returns the reserve asset amount for a given amount of deposit receipt tokens after taking into account
  /// any
  /// pending fee drip.
  /// @param reservePoolId_ The ID of the reserve pool to convert the deposit receipt token amount for.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to convert to reserve assets.
  function convertToReserveAssetAmount(uint8 reservePoolId_, uint256 depositReceiptTokenAmount_)
    external
    view
    returns (uint256 reserveAssetAmount_);

  /// @notice Address of the Cozy Safety Module protocol manager contract.
  function cozySafetyModuleManager() external view returns (ICozySafetyModuleManager);

  /// @notice Config, withdrawal and unstake delays.
  function delays() external view returns (Delays memory delays_);

  /// @notice Deposits reserve assets into the SafetyModule and mints deposit receipt tokens.
  /// @dev Expects `msg.sender` to have approved this SafetyModule for `reserveAssetAmount_` of
  /// `reservePools[reservePoolId_].asset` so it can `transferFrom` the assets to this SafetyModule.
  /// @param reservePoolId_ The ID of the reserve pool to deposit assets into.
  /// @param reserveAssetAmount_ The amount of reserve assets to deposit.
  /// @param receiver_ The address to receive the deposit receipt tokens.
  function depositReserveAssets(uint8 reservePoolId_, uint256 reserveAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_);

  /// @notice Deposits reserve assets into the SafetyModule and mints deposit receipt tokens.
  /// @dev Expects depositer to transfer assets to the SafetyModule beforehand.
  /// @param reservePoolId_ The ID of the reserve pool to deposit assets into.
  /// @param reserveAssetAmount_ The amount of reserve assets to deposit.
  /// @param receiver_ The address to receive the deposit receipt tokens.
  function depositReserveAssetsWithoutTransfer(uint8 reservePoolId_, uint256 reserveAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_);

  /// @notice Updates the fee amounts for each reserve pool by applying a drip factor on the deposit amounts.
  function dripFees() external;

  /// @notice Drips fees from a specific reserve pool.
  /// @param reservePoolId_ The ID of the reserve pool to drip fees from.
  function dripFeesFromReservePool(uint8 reservePoolId_) external;

  /// @notice Execute queued updates to the safety module configs.
  /// @param configUpdates_ The new configs. Includes:
  /// - reservePoolConfigs: The array of new reserve pool configs, sorted by associated ID. The array may also
  /// include config for new reserve pools.
  /// - triggerConfigUpdates: The array of trigger config updates. It only needs to include config for updates to
  /// existing triggers or new triggers.
  /// - delaysConfig: The new delays config.
  function finalizeUpdateConfigs(UpdateConfigsCalldataParams calldata configUpdates_) external;

  /// @notice Returns the maximum amount of assets that can be slashed from the specified reserve pool.
  /// @param reservePoolId_ The ID of the reserve pool to get the maximum slashable amount for.
  function getMaxSlashableReservePoolAmount(uint8 reservePoolId_)
    external
    view
    returns (uint256 slashableReservePoolAmount_);

  /// @notice Initializes the SafetyModule with the specified parameters.
  /// @dev Replaces the constructor for minimal proxies.
  /// @param owner_ The SafetyModule owner.
  /// @param pauser_ The SafetyModule pauser.
  /// @param configs_ The SafetyModule configuration parameters. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  function initialize(address owner_, address pauser_, UpdateConfigsCalldataParams calldata configs_) external;

  /// @notice Metadata about the most recently queued configuration update.
  function lastConfigUpdate() external view returns (ConfigUpdateMetadata memory);

  /// @notice The number of slashes that must occur before the SafetyModule can be active.
  /// @dev This value is incremented when a trigger occurs, and decremented when a slash from a trigger assigned payout
  /// handler occurs. When this value is non-zero, the SafetyModule is triggered (or paused).
  function numPendingSlashes() external returns (uint16);

  /// @notice Returns the address of the SafetyModule owner.
  function owner() external view returns (address);

  /// @notice Pauses the SafetyModule if it's a valid state transition.
  /// @dev Only the owner or pauser can call this function.
  function pause() external;

  /// @notice Address of the SafetyModule pauser.
  function pauser() external view returns (address);

  /// @notice Maps payout handlers to the number of slashes they are currently entitled to.
  /// @dev The number of slashes that a payout handler is entitled to is increased each time a trigger triggers this
  /// SafetyModule, if the payout handler is assigned to the trigger. The number of slashes is decreased each time a
  /// slash from the trigger assigned payout handler occurs.
  function payoutHandlerNumPendingSlashes(address payoutHandler_) external returns (uint256);

  /// @notice Allows an on-chain or off-chain user to simulate the effects of their queued redemption (i.e. view the
  /// number of reserve assets received) at the current block, given current on-chain conditions.
  /// @param redemptionId_ The ID of the redemption to preview.
  function previewQueuedRedemption(uint64 redemptionId_)
    external
    view
    returns (RedemptionPreview memory redemptionPreview_);

  /// @notice Allows an on-chain or off-chain user to simulate the effects of their redemption (i.e. view the number
  /// of reserve assets received) at the current block, given current on-chain conditions.
  /// @param reservePoolId_ The ID of the reserve pool to redeem from.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to redeem.
  function previewRedemption(uint8 reservePoolId_, uint256 depositReceiptTokenAmount_)
    external
    view
    returns (uint256 reserveAssetAmount_);

  /// @notice Address of the Cozy Safety Module protocol ReceiptTokenFactory.
  function receiptTokenFactory() external view returns (IReceiptTokenFactory);

  /// @notice Queues a redemption by burning `depositReceiptTokenAmount_` of `reservePoolId_` reserve pool deposit
  /// tokens.
  /// When the redemption is completed, `reserveAssetAmount_` of `reservePoolId_` reserve pool assets will be sent
  /// to `receiver_` if the reserve pool's assets are not slashed. If the SafetyModule is paused, the redemption
  /// will be completed instantly.
  /// @dev Assumes that user has approved the SafetyModule to spend its deposit tokens.
  /// @param reservePoolId_ The ID of the reserve pool to redeem from.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to redeem.
  /// @param receiver_ The address to receive the reserve assets.
  /// @param owner_ The address that owns the deposit receipt tokens.
  function redeem(uint8 reservePoolId_, uint256 depositReceiptTokenAmount_, address receiver_, address owner_)
    external
    returns (uint64 redemptionId_, uint256 reserveAssetAmount_);

  /// @notice Accounting and metadata for reserve pools configured for this SafetyModule.
  /// @dev Reserve pool index in this array is its ID
  function reservePools(uint256 id_) external view returns (ReservePool memory reservePool_);

  /// @notice The state of this SafetyModule.
  function safetyModuleState() external view returns (SafetyModuleState);

  /// @notice Slashes the reserve pools, sends the assets to the receiver, and returns the safety module to the ACTIVE
  /// state if there are no payout handlers that still need to slash assets. Note: Payout handlers can call this
  /// function once for each triggered trigger that has it assigned as its payout handler.
  /// @param slashes_ The slashes to execute.
  /// @param receiver_ The address to receive the slashed assets.
  function slash(Slash[] memory slashes_, address receiver_) external;

  /// @notice Triggers the SafetyModule by referencing one of the triggers configured for this SafetyModule.
  /// @param trigger_ The trigger to reference when triggering the SafetyModule.
  function trigger(ITrigger trigger_) external;

  /// @notice Returns trigger related data.
  /// @param trigger_ The trigger to get data for.
  function triggerData(ITrigger trigger_) external view returns (Trigger memory);

  /// @notice Unpauses the SafetyModule.
  function unpause() external;

  /// @notice Signal an update to the safety module configs. Existing queued updates are overwritten.
  /// @param configUpdates_ The new configs. Includes:
  /// - reservePoolConfigs: The array of new reserve pool configs, sorted by associated ID. The array may also
  /// include config for new reserve pools.
  /// - triggerConfigUpdates: The array of trigger config updates. It only needs to include config for updates to
  /// existing triggers or new triggers.
  /// - delaysConfig: The new delays config.
  function updateConfigs(UpdateConfigsCalldataParams calldata configUpdates_) external;
}

// src/interfaces/ISafetyModuleFactory.sol

interface ISafetyModuleFactory {
  /// @dev Emitted when a new Safety Module is deployed.
  event SafetyModuleDeployed(ISafetyModule safetyModule);

  /// @notice Given the `baseSalt_` compute and return the address that SafetyModule will be deployed to.
  /// @dev SafetyModule addresses are uniquely determined by their salt because the deployer is always the factory,
  /// and the use of minimal proxies means they all have identical bytecode and therefore an identical bytecode hash.
  /// @dev The `baseSalt_` is the user-provided salt, not the final salt after hashing with the chain ID.
  /// @param baseSalt_ The user-provided salt.
  function computeAddress(bytes32 baseSalt_) external view returns (address);

  /// @notice Address of the Cozy Safety Module protocol manager contract.
  function cozySafetyModuleManager() external view returns (ICozySafetyModuleManager);

  /// @notice Deploys a new SafetyModule contract with the specified configuration.
  /// @param owner_ The owner of the SafetyModule.
  /// @param pauser_ The pauser of the SafetyModule.
  /// @param configs_ The configuration for the SafetyModule.
  /// @param baseSalt_ Used to compute the resulting address of the SafetyModule.
  function deploySafetyModule(
    address owner_,
    address pauser_,
    UpdateConfigsCalldataParams calldata configs_,
    bytes32 baseSalt_
  ) external returns (ISafetyModule safetyModule_);

  /// @notice Address of the SafetyModule logic contract used to deploy new SafetyModule minimal proxies.
  function safetyModuleLogic() external view returns (ISafetyModule);

  /// @notice Given the `baseSalt_`, return the salt that will be used for deployment.
  /// @param baseSalt_ The user-provided salt.
  function salt(bytes32 baseSalt_) external view returns (bytes32);
}

// src/SafetyModuleFactory.sol

/**
 * @notice Deploys new SafetyModules.
 */
contract SafetyModuleFactory is ISafetyModuleFactory {
  using Clones for address;

  /// @notice Address of the Cozy Safety Module protocol manager contract.
  ICozySafetyModuleManager public immutable cozySafetyModuleManager;

  /// @notice Address of the SafetyModule logic contract used to deploy new SafetyModule minimal proxies.
  ISafetyModule public immutable safetyModuleLogic;

  /// @dev Thrown when the caller is not authorized to perform the action.
  error Unauthorized();

  /// @dev Thrown if an address parameter is invalid.
  error InvalidAddress();

  /// @param cozySafetyModuleManager_ Cozy Safety Module protocol manager contract.
  /// @param safetyModuleLogic_ Logic contract for deploying new SafetyModules.
  constructor(ICozySafetyModuleManager cozySafetyModuleManager_, ISafetyModule safetyModuleLogic_) {
    _assertAddressNotZero(address(cozySafetyModuleManager_));
    _assertAddressNotZero(address(safetyModuleLogic_));
    cozySafetyModuleManager = cozySafetyModuleManager_;
    safetyModuleLogic = safetyModuleLogic_;
  }

  /// @notice Deploys a new SafetyModule contract with the specified configuration.
  /// @param owner_ The owner of the SafetyModule.
  /// @param pauser_ The pauser of the SafetyModule.
  /// @param configs_ The configuration for the SafetyModule.
  /// @param baseSalt_ Used to compute the resulting address of the SafetyModule.
  function deploySafetyModule(
    address owner_,
    address pauser_,
    UpdateConfigsCalldataParams calldata configs_,
    bytes32 baseSalt_
  ) public returns (ISafetyModule safetyModule_) {
    // It'd be harmless to let anyone deploy SafetyModules, but to make it more clear where the proper entry
    // point for SafetyModule creation is, we restrict this to being called by the CozySafetyModuleManager.
    if (msg.sender != address(cozySafetyModuleManager)) revert Unauthorized();

    // SafetyModules deployed by this factory are minimal proxies.
    safetyModule_ = ISafetyModule(address(safetyModuleLogic).cloneDeterministic(salt(baseSalt_)));
    emit SafetyModuleDeployed(safetyModule_);
    safetyModule_.initialize(owner_, pauser_, configs_);
  }

  /// @notice Given the `baseSalt_` compute and return the address that SafetyModule will be deployed to.
  /// @dev SafetyModule addresses are uniquely determined by their salt because the deployer is always the factory,
  /// and the use of minimal proxies means they all have identical bytecode and therefore an identical bytecode hash.
  /// @dev The `baseSalt_` is the user-provided salt, not the final salt after hashing with the chain ID.
  /// @param baseSalt_ The user-provided salt.
  function computeAddress(bytes32 baseSalt_) external view returns (address) {
    return Clones.predictDeterministicAddress(address(safetyModuleLogic), salt(baseSalt_), address(this));
  }

  /// @notice Given the `baseSalt_`, return the salt that will be used for deployment.
  /// @param baseSalt_ The user-provided salt.
  function salt(bytes32 baseSalt_) public view returns (bytes32) {
    // We take the user-provided salt and concatenate it with the chain ID before hashing. This is
    // required because CREATE2 with a user provided salt or CREATE both make it easy for an
    // attacker to create a malicious Safety Module on one chain and pass it off as a reputable Safety Module from
    // another chain since the two have the same address.
    return keccak256(abi.encode(baseSalt_, block.chainid));
  }

  /// @notice Revert if the address is the zero address.
  /// @param address_ The address to check.
  function _assertAddressNotZero(address address_) internal pure {
    if (address_ == address(0)) revert InvalidAddress();
  }
}