// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {IDripModel} from "cozy-safety-module-shared/interfaces/IDripModel.sol";
import {IERC20} from "cozy-safety-module-shared/interfaces/IERC20.sol";
import {Governable} from "cozy-safety-module-shared/lib/Governable.sol";
import {ICozySafetyModuleManager} from "./interfaces/ICozySafetyModuleManager.sol";
import {ISafetyModule} from "./interfaces/ISafetyModule.sol";
import {ISafetyModuleFactory} from "./interfaces/ISafetyModuleFactory.sol";
import {UpdateConfigsCalldataParams, ReservePoolConfig} from "./lib/structs/Configs.sol";
import {Delays} from "./lib/structs/Delays.sol";
import {ConfiguratorLib} from "./lib/ConfiguratorLib.sol";

contract CozySafetyModuleManager is Governable, ICozySafetyModuleManager {
  struct DripModelLookup {
    IDripModel dripModel;
    bool exists;
  }

  /// @notice The max number of reserve pools allowed per SafetyModule.
  uint8 public immutable allowedReservePools;

  /// @notice Cozy Safety Module protocol SafetyModuleFactory.
  ISafetyModuleFactory public immutable safetyModuleFactory;

  /// @notice The default fee drip model used for SafetyModules.
  IDripModel public feeDripModel;

  /// @notice Override fee drip models for specific SafetyModules.
  mapping(ISafetyModule => DripModelLookup) public overrideFeeDripModels;

  /// @notice For the specified SafetyModule, returns whether it's a valid Cozy Safety Module.
  mapping(ISafetyModule => bool) public isSafetyModule;

  /// @dev Thrown when an SafetyModule's configuration does not meet all requirements.
  error InvalidConfiguration();

  /// @param owner_ The Cozy Safety Module protocol owner.
  /// @param pauser_ The Cozy Safety Module protocol pauser.
  /// @param safetyModuleFactory_ The Cozy Safety Module protocol SafetyModuleFactory.
  /// @param feeDripModel_ The default fee drip model used for SafetyModules.
  /// @param allowedReservePools_ The max number of reserve pools allowed per SafetyModule.
  constructor(
    address owner_,
    address pauser_,
    ISafetyModuleFactory safetyModuleFactory_,
    IDripModel feeDripModel_,
    uint8 allowedReservePools_
  ) {
    _assertAddressNotZero(owner_);
    _assertAddressNotZero(address(safetyModuleFactory_));
    _assertAddressNotZero(address(feeDripModel_));
    __initGovernable(owner_, pauser_);

    safetyModuleFactory = safetyModuleFactory_;
    allowedReservePools = allowedReservePools_;

    _updateFeeDripModel(feeDripModel_);
  }

  // ------------------------------------
  // -------- Cozy Owner Actions --------
  // ------------------------------------

  /// @notice Update the default fee drip model used for SafetyModules.
  /// @param feeDripModel_ The new default fee drip model.
  function updateFeeDripModel(IDripModel feeDripModel_) external onlyOwner {
    _updateFeeDripModel(feeDripModel_);
  }

  /// @notice Update the fee drip model for the specified SafetyModule.
  /// @param safetyModule_ The SafetyModule to update the fee drip model for.
  /// @param feeDripModel_ The new fee drip model for the SafetyModule.
  function updateOverrideFeeDripModel(ISafetyModule safetyModule_, IDripModel feeDripModel_) external onlyOwner {
    overrideFeeDripModels[safetyModule_] = DripModelLookup({exists: true, dripModel: feeDripModel_});
    emit OverrideFeeDripModelUpdated(safetyModule_, feeDripModel_);
  }

  /// @notice Reset the override fee drip model for the specified SafetyModule back to the default.
  /// @param safetyModule_ The SafetyModule to update the fee drip model for.
  function resetOverrideFeeDripModel(ISafetyModule safetyModule_) external onlyOwner {
    delete overrideFeeDripModels[safetyModule_];
    emit OverrideFeeDripModelUpdated(safetyModule_, feeDripModel);
  }

  // -----------------------------------------------
  // -------- Batched Safety Module Actions --------
  // -----------------------------------------------

  /// @notice For all specified `safetyModules_`, transfers accrued fees to the owner address.
  function claimFees(ISafetyModule[] calldata safetyModules_) external {
    address owner_ = owner;
    for (uint256 i = 0; i < safetyModules_.length; i++) {
      safetyModules_[i].claimFees(owner_, getFeeDripModel(safetyModules_[i]));
      emit ClaimedSafetyModuleFees(safetyModules_[i]);
    }
  }

  /// @notice Batch pauses `safetyModules_`. The CozySafetyModuleManager's pauser or owner can perform this action.
  function pause(ISafetyModule[] calldata safetyModules_) external {
    if (msg.sender != pauser && msg.sender != owner) revert Unauthorized();
    for (uint256 i = 0; i < safetyModules_.length; i++) {
      safetyModules_[i].pause();
    }
  }

  /// @notice Batch unpauses `safetyModules_`. The CozySafetyModuleManager's owner can perform this action.
  function unpause(ISafetyModule[] calldata safetyModules_) external onlyOwner {
    for (uint256 i = 0; i < safetyModules_.length; i++) {
      safetyModules_[i].unpause();
    }
  }

  // ----------------------------------------
  // -------- Permissionless Actions --------
  // ----------------------------------------

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
  ) external returns (ISafetyModule safetyModule_) {
    _assertAddressNotZero(owner_);
    _assertAddressNotZero(pauser_);

    if (!ConfiguratorLib.isValidConfiguration(configs_.reservePoolConfigs, configs_.delaysConfig, allowedReservePools))
    {
      revert InvalidConfiguration();
    }

    bytes32 deploySalt_ = _computeDeploySalt(msg.sender, salt_);

    ISafetyModuleFactory safetyModuleFactory_ = safetyModuleFactory;
    isSafetyModule[ISafetyModule(safetyModuleFactory_.computeAddress(deploySalt_))] = true;
    safetyModule_ = safetyModuleFactory_.deploySafetyModule(owner_, pauser_, configs_, deploySalt_);
  }

  /// @notice Given a `caller_` and `salt_`, compute and return the address of the SafetyModule deployed with
  /// `createSafetyModule`.
  /// @param caller_ The caller of the `createSafetyModule` function.
  /// @param salt_ Used to compute the resulting address of the SafetyModule along with `caller_`.
  function computeSafetyModuleAddress(address caller_, bytes32 salt_) external view returns (address) {
    bytes32 deploySalt_ = _computeDeploySalt(caller_, salt_);
    return safetyModuleFactory.computeAddress(deploySalt_);
  }

  /// @notice For the specified SafetyModule, returns the drip model used for fee accrual.
  function getFeeDripModel(ISafetyModule safetyModule_) public view returns (IDripModel) {
    DripModelLookup memory overrideFeeDripModel_ = overrideFeeDripModels[safetyModule_];
    if (overrideFeeDripModel_.exists) return overrideFeeDripModel_.dripModel;
    else return feeDripModel;
  }

  // ----------------------------------
  // -------- Internal Helpers --------
  // ----------------------------------

  /// @dev Executes the fee drip model update.
  function _updateFeeDripModel(IDripModel feeDripModel_) internal {
    feeDripModel = feeDripModel_;
    emit FeeDripModelUpdated(feeDripModel_);
  }

  /// @notice Given a `caller_` and `salt_`, return the salt used to compute the SafetyModule address deployed from
  /// the `safetyModuleFactory`.
  /// @param caller_ The caller of the `createSafetyModule` function.
  /// @param salt_ Used to compute the resulting address of the SafetyModule along with `caller_`.
  function _computeDeploySalt(address caller_, bytes32 salt_) internal pure returns (bytes32) {
    // To avoid front-running of SafetyModule deploys, msg.sender is used for the deploy salt.
    return keccak256(abi.encodePacked(salt_, caller_));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IDripModel {
  /// @notice Returns the drip factor, given the `lastDripTime_` and `initialAmount_`.
  function dripFactor(uint256 lastDripTime_, uint256 initialAmount_) external view returns (uint256 dripFactor_);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {IGovernable} from "../interfaces/IGovernable.sol";
import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module providing owner and pauser functionality, intended to be used through inheritance.
 * @dev No modifiers are provided to avoid the chance of dead code, as the child contract may
 * have more complex authentication requirements than just a modifier from this contract.
 */
abstract contract Governable is Ownable, IGovernable {
  /// @notice Contract pauser.
  address public pauser;

  /// @dev Emitted when the pauser address is updated.
  event PauserUpdated(address indexed newPauser_);

  /// @dev Initializer, replaces constructor for minimal proxies. Must be kept internal and it's up
  /// to the caller to make sure this can only be called once.
  /// @param owner_ The contract owner.
  /// @param pauser_ The contract pauser.
  function __initGovernable(address owner_, address pauser_) internal {
    __initOwnable(owner_);
    pauser = pauser_;
    emit PauserUpdated(pauser_);
  }

  /// @notice Update pauser to `_newPauser`.
  /// @param _newPauser The new pauser.
  function _updatePauser(address _newPauser) internal {
    if (msg.sender != owner && msg.sender != pauser) revert Unauthorized();
    emit PauserUpdated(_newPauser);
    pauser = _newPauser;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IDripModel} from "cozy-safety-module-shared/interfaces/IDripModel.sol";
import {IOwnable} from "cozy-safety-module-shared/interfaces/IOwnable.sol";
import {ICozySafetyModuleManagerEvents} from "./ICozySafetyModuleManagerEvents.sol";
import {ISafetyModule} from "./ISafetyModule.sol";
import {UpdateConfigsCalldataParams} from "../lib/structs/Configs.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IDripModel} from "cozy-safety-module-shared/interfaces/IDripModel.sol";
import {IERC20} from "cozy-safety-module-shared/interfaces/IERC20.sol";
import {IReceiptToken} from "cozy-safety-module-shared/interfaces/IReceiptToken.sol";
import {IReceiptTokenFactory} from "cozy-safety-module-shared/interfaces/IReceiptTokenFactory.sol";
import {SafetyModuleState} from "../lib/SafetyModuleStates.sol";
import {AssetPool} from "../lib/structs/Pools.sol";
import {UpdateConfigsCalldataParams, ConfigUpdateMetadata} from "../lib/structs/Configs.sol";
import {ReservePool} from "../lib/structs/Pools.sol";
import {RedemptionPreview} from "../lib/structs/Redemptions.sol";
import {Slash} from "../lib/structs/Slash.sol";
import {Trigger} from "../lib/structs/Trigger.sol";
import {Delays} from "../lib/structs/Delays.sol";
import {ICozySafetyModuleManager} from "./ICozySafetyModuleManager.sol";
import {ITrigger} from "./ITrigger.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "cozy-safety-module-shared/interfaces/IERC20.sol";
import {ICozySafetyModuleManager} from "./ICozySafetyModuleManager.sol";
import {ISafetyModule} from "./ISafetyModule.sol";
import {UpdateConfigsCalldataParams, ReservePoolConfig} from "../lib/structs/Configs.sol";
import {Delays} from "../lib/structs/Delays.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {IERC20} from "cozy-safety-module-shared/interfaces/IERC20.sol";
import {Delays} from "./Delays.sol";
import {TriggerConfig} from "./Trigger.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

/// @notice Delays for the SafetyModule.
struct Delays {
  // Duration between when SafetyModule updates are queued and when they can be executed.
  uint64 configUpdateDelay;
  // Defines how long the owner has to execute a configuration change, once it can be executed.
  uint64 configUpdateGracePeriod;
  // Delay for two-step withdraw process (for deposited reserve assets).
  uint64 withdrawDelay;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {ICommonErrors} from "cozy-safety-module-shared/interfaces/ICommonErrors.sol";
import {IERC20} from "cozy-safety-module-shared/interfaces/IERC20.sol";
import {IReceiptToken} from "cozy-safety-module-shared/interfaces/IReceiptToken.sol";
import {IReceiptTokenFactory} from "cozy-safety-module-shared/interfaces/IReceiptTokenFactory.sol";
import {MathConstants} from "cozy-safety-module-shared/lib/MathConstants.sol";
import {SafetyModuleState, TriggerState} from "./SafetyModuleStates.sol";
import {IConfiguratorErrors} from "../interfaces/IConfiguratorErrors.sol";
import {IConfiguratorEvents} from "../interfaces/IConfiguratorEvents.sol";
import {ITrigger} from "../interfaces/ITrigger.sol";
import {ICozySafetyModuleManager} from "../interfaces/ICozySafetyModuleManager.sol";
import {ReservePool} from "./structs/Pools.sol";
import {Delays} from "./structs/Delays.sol";
import {ConfigUpdateMetadata, ReservePoolConfig, UpdateConfigsCalldataParams} from "./structs/Configs.sol";
import {TriggerConfig, Trigger} from "./structs/Trigger.sol";

library ConfiguratorLib {
  error InvalidTimestamp();

  /// @notice Signal an update to the SafetyModule configs. Existing queued updates are overwritten.
  /// @param lastConfigUpdate_ Metadata about the most recently queued configuration update.
  /// @param safetyModuleState_ The state of the SafetyModule.
  /// @param reservePools_ The array of existing reserve pools.
  /// @param triggerData_ The mapping of trigger to trigger data.
  /// @param delays_ The existing delays config.
  /// @param configUpdates_ The new configs. Includes:
  /// - reservePoolConfigs: The array of new reserve pool configs, sorted by associated ID. The array may also
  /// include config for new reserve pools.
  /// - triggerConfigUpdates: The array of trigger config updates. It only needs to include config for updates to
  /// existing triggers or new triggers.
  /// - delaysConfig: The new delays config.
  /// @param manager_ The Cozy Safety Module protocol Manager.
  function updateConfigs(
    ConfigUpdateMetadata storage lastConfigUpdate_,
    SafetyModuleState safetyModuleState_,
    ReservePool[] storage reservePools_,
    mapping(ITrigger => Trigger) storage triggerData_,
    Delays storage delays_,
    UpdateConfigsCalldataParams calldata configUpdates_,
    ICozySafetyModuleManager manager_
  ) internal {
    if (safetyModuleState_ == SafetyModuleState.TRIGGERED) revert ICommonErrors.InvalidState();
    if (!isValidUpdate(reservePools_, triggerData_, configUpdates_, manager_)) {
      revert IConfiguratorErrors.InvalidConfiguration();
    }

    // Hash stored to ensure only queued updates can be applied.
    lastConfigUpdate_.queuedConfigUpdateHash = keccak256(
      abi.encode(configUpdates_.reservePoolConfigs, configUpdates_.triggerConfigUpdates, configUpdates_.delaysConfig)
    );

    uint64 configUpdateTime_ = uint64(block.timestamp) + delays_.configUpdateDelay;
    uint64 configUpdateDeadline_ = configUpdateTime_ + delays_.configUpdateGracePeriod;
    emit IConfiguratorEvents.ConfigUpdatesQueued(
      configUpdates_.reservePoolConfigs,
      configUpdates_.triggerConfigUpdates,
      configUpdates_.delaysConfig,
      configUpdateTime_,
      configUpdateDeadline_
    );

    lastConfigUpdate_.configUpdateTime = configUpdateTime_;
    lastConfigUpdate_.configUpdateDeadline = configUpdateDeadline_;
  }

  /// @notice Execute queued updates to SafetyModule configs.
  /// @dev If the SafetyModule becomes triggered before the queued update is applied, the queued update is cancelled
  /// and can be requeued by the owner when the SafetyModule returns to the active or paused states.
  /// @param lastConfigUpdate_ Metadata about the most recently queued configuration update.
  /// @param safetyModuleState_ The state of the SafetyModule.
  /// @param reservePools_ The array of existing reserve pools.
  /// @param triggerData_ The mapping of trigger to trigger data.
  /// @param delays_ The existing delays config.
  /// @param receiptTokenFactory_ The ReceiptToken factory.
  /// @param configUpdates_ The new configs. Includes:
  /// - reservePoolConfigs: The array of new reserve pool configs, sorted by associated ID. The array may also
  /// include config for new reserve pools.
  /// - triggerConfigUpdates: The array of trigger config updates. It only needs to include config for updates to
  /// existing triggers or new triggers.
  /// - delaysConfig: The new delays config.
  function finalizeUpdateConfigs(
    ConfigUpdateMetadata storage lastConfigUpdate_,
    SafetyModuleState safetyModuleState_,
    ReservePool[] storage reservePools_,
    mapping(ITrigger => Trigger) storage triggerData_,
    Delays storage delays_,
    IReceiptTokenFactory receiptTokenFactory_,
    UpdateConfigsCalldataParams calldata configUpdates_
  ) internal {
    if (safetyModuleState_ == SafetyModuleState.TRIGGERED) revert ICommonErrors.InvalidState();
    if (block.timestamp < lastConfigUpdate_.configUpdateTime) revert InvalidTimestamp();
    if (block.timestamp > lastConfigUpdate_.configUpdateDeadline) revert InvalidTimestamp();

    // Ensure the queued config update hash matches the provided config updates.
    if (
      keccak256(
        abi.encode(configUpdates_.reservePoolConfigs, configUpdates_.triggerConfigUpdates, configUpdates_.delaysConfig)
      ) != lastConfigUpdate_.queuedConfigUpdateHash
    ) revert IConfiguratorErrors.InvalidConfiguration();

    // Reset the config update hash.
    lastConfigUpdate_.queuedConfigUpdateHash = 0;
    applyConfigUpdates(reservePools_, triggerData_, delays_, receiptTokenFactory_, configUpdates_);
  }

  /// @notice Returns true if the provided configs are valid for the SafetyModule, false otherwise.
  /// @param reservePools_ The array of existing reserve pools.
  /// @param triggerData_ The mapping of trigger to trigger data.
  /// @param configUpdates_ The new configs.
  /// @param manager_ The Cozy Safety Module protocol Manager.
  function isValidUpdate(
    ReservePool[] storage reservePools_,
    mapping(ITrigger => Trigger) storage triggerData_,
    UpdateConfigsCalldataParams calldata configUpdates_,
    ICozySafetyModuleManager manager_
  ) internal view returns (bool) {
    // Generic validation of the configuration parameters.
    if (
      !isValidConfiguration(
        configUpdates_.reservePoolConfigs, configUpdates_.delaysConfig, manager_.allowedReservePools()
      )
    ) return false;

    // Validate number of reserve pools. It is only possible to add new pools, not remove existing ones.
    uint256 numExistingReservePools_ = reservePools_.length;
    if (configUpdates_.reservePoolConfigs.length < numExistingReservePools_) return false;

    // Validate existing reserve pools.
    for (uint8 i = 0; i < numExistingReservePools_; i++) {
      // Existing reserve pools cannot have their asset updated.
      if (reservePools_[i].asset != configUpdates_.reservePoolConfigs[i].asset) return false;
    }

    // Validate trigger config.
    for (uint16 i = 0; i < configUpdates_.triggerConfigUpdates.length; i++) {
      // Triggers that have successfully called trigger() on the safety module cannot be updated.
      if (triggerData_[configUpdates_.triggerConfigUpdates[i].trigger].triggered) return false;
    }

    return true;
  }

  /// @notice Returns true if the provided configs are generically valid, false otherwise.
  /// @dev Does not include SafetyModule-specific checks, e.g. checks based on existing reserve pools.
  function isValidConfiguration(
    ReservePoolConfig[] calldata reservePoolConfigs_,
    Delays calldata delaysConfig_,
    uint8 maxReservePools_
  ) internal pure returns (bool) {
    // Validate number of reserve pools.
    if (reservePoolConfigs_.length > maxReservePools_) return false;

    // Validate delays.
    if (delaysConfig_.configUpdateDelay <= delaysConfig_.withdrawDelay) return false;

    // Validate max slash percentages.
    for (uint8 i = 0; i < reservePoolConfigs_.length; i++) {
      if (reservePoolConfigs_[i].maxSlashPercentage > MathConstants.ZOC) return false;
    }

    return true;
  }

  /// @notice Apply queued updates to SafetyModule config.
  /// @param reservePools_ The array of existing reserve pools.
  /// @param triggerData_ The mapping of trigger to trigger data.
  /// @param delays_ The existing delays config.
  /// @param receiptTokenFactory_ The ReceiptToken factory.
  /// @param configUpdates_ The new configs.
  function applyConfigUpdates(
    ReservePool[] storage reservePools_,
    mapping(ITrigger => Trigger) storage triggerData_,
    Delays storage delays_,
    IReceiptTokenFactory receiptTokenFactory_,
    UpdateConfigsCalldataParams calldata configUpdates_
  ) public {
    // Update existing reserve pool maxSlashPercentages. Reserve pool assets cannot be updated.
    uint8 numExistingReservePools_ = uint8(reservePools_.length);
    for (uint8 i = 0; i < numExistingReservePools_; i++) {
      reservePools_[i].maxSlashPercentage = configUpdates_.reservePoolConfigs[i].maxSlashPercentage;
    }

    // Initialize new reserve pools.
    for (uint8 i = numExistingReservePools_; i < configUpdates_.reservePoolConfigs.length; i++) {
      initializeReservePool(reservePools_, receiptTokenFactory_, configUpdates_.reservePoolConfigs[i], i);
    }

    // Update trigger configs.
    for (uint256 i = 0; i < configUpdates_.triggerConfigUpdates.length; i++) {
      // Triggers that have successfully called trigger() on the Safety cannot be updated.
      // The trigger must also not be in a triggered state.
      if (
        triggerData_[configUpdates_.triggerConfigUpdates[i].trigger].triggered
          || configUpdates_.triggerConfigUpdates[i].trigger.state() == TriggerState.TRIGGERED
      ) revert IConfiguratorErrors.InvalidConfiguration();
      triggerData_[configUpdates_.triggerConfigUpdates[i].trigger] = Trigger({
        exists: configUpdates_.triggerConfigUpdates[i].exists,
        payoutHandler: configUpdates_.triggerConfigUpdates[i].payoutHandler,
        triggered: false
      });
    }

    // Update delays.
    delays_.configUpdateDelay = configUpdates_.delaysConfig.configUpdateDelay;
    delays_.configUpdateGracePeriod = configUpdates_.delaysConfig.configUpdateGracePeriod;
    delays_.withdrawDelay = configUpdates_.delaysConfig.withdrawDelay;

    emit IConfiguratorEvents.ConfigUpdatesFinalized(
      configUpdates_.reservePoolConfigs, configUpdates_.triggerConfigUpdates, configUpdates_.delaysConfig
    );
  }

  /// @notice Initializes a new reserve pool when it is added to the SafetyModule.
  /// @param reservePools_ The array of existing reserve pools.
  /// @param receiptTokenFactory_ The ReceiptToken factory.
  /// @param reservePoolConfig_ The new reserve pool config.
  /// @param reservePoolId_ The ID of the new reserve pool.
  function initializeReservePool(
    ReservePool[] storage reservePools_,
    IReceiptTokenFactory receiptTokenFactory_,
    ReservePoolConfig calldata reservePoolConfig_,
    uint8 reservePoolId_
  ) internal {
    IReceiptToken reserveDepositReceiptToken_ = receiptTokenFactory_.deployReceiptToken(
      reservePoolId_, IReceiptTokenFactory.PoolType.RESERVE, reservePoolConfig_.asset.decimals()
    );

    reservePools_.push(
      ReservePool({
        asset: reservePoolConfig_.asset,
        depositReceiptToken: reserveDepositReceiptToken_,
        depositAmount: 0,
        pendingWithdrawalsAmount: 0,
        feeAmount: 0,
        maxSlashPercentage: reservePoolConfig_.maxSlashPercentage,
        lastFeesDripTime: uint128(block.timestamp)
      })
    );

    emit IConfiguratorEvents.ReservePoolCreated(reservePoolId_, reservePoolConfig_.asset, reserveDepositReceiptToken_);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IOwnable} from "./IOwnable.sol";

interface IGovernable is IOwnable {
  function pauser() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {IOwnable} from "../interfaces/IOwnable.sol";

/**
 * @dev Contract module providing owner functionality, intended to be used through inheritance.
 */
abstract contract Ownable is IOwnable {
  /// @notice Contract owner.
  address public owner;

  /// @notice The pending new owner.
  address public pendingOwner;

  /// @dev Emitted when the owner address is updated.
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /// @dev Emitted when the first step of the two step ownership transfer is executed.
  event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

  /// @dev Thrown when the caller is not authorized to perform the action.
  error Unauthorized();

  /// @dev Thrown when an invalid address is passed as a parameter.
  error InvalidAddress();

  /// @dev Initializer, replaces constructor for minimal proxies. Must be kept internal and it's up
  /// to the caller to make sure this can only be called once.
  /// @param owner_ The contract owner.
  function __initOwnable(address owner_) internal {
    emit OwnershipTransferred(owner, owner_);
    owner = owner_;
  }

  /// @notice Callable by the pending owner to transfer ownership to them.
  /// @dev Updates the owner in storage to newOwner_ and resets the pending owner.
  function acceptOwnership() external {
    if (msg.sender != pendingOwner) revert Unauthorized();
    delete pendingOwner;
    address oldOwner_ = owner;
    owner = msg.sender;
    emit OwnershipTransferred(oldOwner_, msg.sender);
  }

  /// @notice Starts the ownership transfer of the contract to a new account.
  /// Replaces the pending transfer if there is one.
  /// @param newOwner_ The new owner of the contract.
  function transferOwnership(address newOwner_) external onlyOwner {
    _assertAddressNotZero(newOwner_);
    pendingOwner = newOwner_;
    emit OwnershipTransferStarted(owner, newOwner_);
  }

  /// @dev Revert if the address is the zero address.
  function _assertAddressNotZero(address address_) internal pure {
    if (address_ == address(0)) revert InvalidAddress();
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized();
    _;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IDripModel} from "cozy-safety-module-shared/interfaces/IDripModel.sol";
import {ISafetyModule} from "./ISafetyModule.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IReceiptToken} from "./IReceiptToken.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {IERC20} from "cozy-safety-module-shared/interfaces/IERC20.sol";
import {IReceiptToken} from "cozy-safety-module-shared/interfaces/IReceiptToken.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {IReceiptToken} from "cozy-safety-module-shared/interfaces/IReceiptToken.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

struct Slash {
  // ID of the reserve pool.
  uint8 reservePoolId;
  // Asset amount that will be slashed from the reserve pool.
  uint256 amount;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {ITrigger} from "../../interfaces/ITrigger.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TriggerState} from "../lib/SafetyModuleStates.sol";

/**
 * @dev The minimal functions a trigger must implement to work with SafetyModules.
 */
interface ITrigger {
  /// @notice The current trigger state.
  function state() external returns (TriggerState);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ICommonErrors {
  /// @dev Thrown if the current state does not allow the requested action to be performed.
  error InvalidState();

  /// @dev Thrown when a requested state transition is not allowed.
  error InvalidStateTransition();

  /// @dev Thrown if the request action is not allowed because zero units would be transferred, burned, minted, etc.
  error RoundsToZero();

  /// @dev Thrown if the request action is not allowed because the requested amount is zero.
  error AmountIsZero();

  /// @dev Thrown when a drip model returns an invalid drip factor.
  error InvalidDripFactor();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

library MathConstants {
  uint256 constant ZOC = 1e4;
  uint256 constant ZOC2 = 1e8;
  uint256 constant WAD = 1e18;
  uint256 constant WAD_ZOC2 = 1e26;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IConfiguratorErrors {
  /// @dev Thrown when an update's configuration does not meet all requirements.
  error InvalidConfiguration();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "cozy-safety-module-shared/interfaces/IERC20.sol";
import {IReceiptToken} from "cozy-safety-module-shared/interfaces/IReceiptToken.sol";
import {ReservePoolConfig} from "../lib/structs/Configs.sol";
import {Delays} from "../lib/structs/Delays.sol";
import {TriggerConfig} from "../lib/structs/Trigger.sol";

interface IConfiguratorEvents {
  /// @dev Emitted when a SafetyModule owner queues a new configuration.
  event ConfigUpdatesQueued(
    ReservePoolConfig[] reservePoolConfigs,
    TriggerConfig[] triggerConfigUpdates,
    Delays delaysConfig,
    uint256 updateTime,
    uint256 updateDeadline
  );

  /// @dev Emitted when a SafetyModule's queued configuration updates are applied.
  event ConfigUpdatesFinalized(
    ReservePoolConfig[] reservePoolConfigs, TriggerConfig[] triggerConfigUpdates, Delays delaysConfig
  );

  /// @notice Emitted when a reserve pool is created.
  event ReservePoolCreated(uint16 indexed reservePoolId, IERC20 reserveAsset, IReceiptToken depositReceiptToken);
}