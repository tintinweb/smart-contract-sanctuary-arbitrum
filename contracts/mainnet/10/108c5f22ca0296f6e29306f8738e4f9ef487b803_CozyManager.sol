// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {Governable} from "cozy-safety-module-shared/lib/Governable.sol";
import {ICozyManager} from "./interfaces/ICozyManager.sol";
import {IRewardsManager} from "./interfaces/IRewardsManager.sol";
import {IRewardsManagerFactory} from "./interfaces/IRewardsManagerFactory.sol";
import {RewardPoolConfig, StakePoolConfig} from "./lib/structs/Configs.sol";

contract CozyManager is Governable, ICozyManager {
  /// @notice Cozy protocol RewardsManagerFactory.
  IRewardsManagerFactory public immutable rewardsManagerFactory;

  /// @param owner_ The Cozy protocol owner.
  /// @param pauser_ The Cozy protocol pauser.
  /// @param rewardsManagerFactory_ The Cozy protocol RewardsManagerFactory.
  constructor(address owner_, address pauser_, IRewardsManagerFactory rewardsManagerFactory_) {
    _assertAddressNotZero(owner_);
    _assertAddressNotZero(address(rewardsManagerFactory_));
    __initGovernable(owner_, pauser_);

    rewardsManagerFactory = rewardsManagerFactory_;
  }

  // -------------------------------------------------
  // -------- Batched Rewards Manager Actions --------
  // -------------------------------------------------

  /// @notice Batch pauses rewardsManagers_. The manager's pauser or owner can perform this action.
  /// @param rewardsManagers_ The array of rewards managers to pause.
  function pause(IRewardsManager[] calldata rewardsManagers_) external {
    if (msg.sender != pauser && msg.sender != owner) revert Unauthorized();
    for (uint256 i = 0; i < rewardsManagers_.length; i++) {
      rewardsManagers_[i].pause();
    }
  }

  /// @notice Batch unpauses rewardsManagers_. The manager's owner can perform this action.
  /// @param rewardsManagers_ The array of rewards managers to unpause.
  function unpause(IRewardsManager[] calldata rewardsManagers_) external onlyOwner {
    for (uint256 i = 0; i < rewardsManagers_.length; i++) {
      rewardsManagers_[i].unpause();
    }
  }

  // ----------------------------------------
  // -------- Permissionless Actions --------
  // ----------------------------------------

  /// @notice Deploys a new Rewards Manager with the provided parameters.
  /// @param owner_ The owner of the rewards manager.
  /// @param pauser_ The pauser of the rewards manager.
  /// @param stakePoolConfigs_ The array of stake pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param rewardPoolConfigs_  The array of reward pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param salt_ Used to compute the resulting address of the rewards manager along with `msg.sender`.
  /// @return rewardsManager_ The newly created rewards manager.
  function createRewardsManager(
    address owner_,
    address pauser_,
    StakePoolConfig[] calldata stakePoolConfigs_,
    RewardPoolConfig[] calldata rewardPoolConfigs_,
    bytes32 salt_
  ) external returns (IRewardsManager rewardsManager_) {
    _assertAddressNotZero(owner_);
    _assertAddressNotZero(pauser_);

    bytes32 deploySalt_ = _computeDeploySalt(msg.sender, salt_);

    rewardsManager_ =
      rewardsManagerFactory.deployRewardsManager(owner_, pauser_, stakePoolConfigs_, rewardPoolConfigs_, deploySalt_);
  }

  /// @notice Given a `caller_` and `salt_`, compute and return the address of the RewardsManager deployed with
  /// `createRewardsManager`.
  /// @param caller_ The caller of the `createRewardsManager` function.
  /// @param salt_ Used to compute the resulting address of the rewards manager along with `caller_`.
  function computeRewardsManagerAddress(address caller_, bytes32 salt_) external view returns (address) {
    bytes32 deploySalt_ = _computeDeploySalt(caller_, salt_);
    return rewardsManagerFactory.computeAddress(deploySalt_);
  }

  /// @notice Given a `caller_` and `salt_`, return the salt used to compute the RewardsManager address deployed from
  /// the `rewardsManagerFactory`.
  /// @param caller_ The caller of the `createRewardsManager` function.
  /// @param salt_ Used to compute the resulting address of the rewards manager along with `caller_`.
  function _computeDeploySalt(address caller_, bytes32 salt_) internal pure returns (bytes32) {
    // To avoid front-running of RewardsManager deploys, msg.sender is used for the deploy salt.
    return keccak256(abi.encodePacked(salt_, caller_));
  }
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

import {IGovernable} from "cozy-safety-module-shared/interfaces/IGovernable.sol";
import {IRewardsManager} from "./IRewardsManager.sol";
import {IRewardsManagerFactory} from "./IRewardsManagerFactory.sol";
import {RewardPoolConfig, StakePoolConfig} from "../lib/structs/Configs.sol";

interface ICozyManager is IGovernable {
  /// @notice Cozy protocol RewardsManagerFactory.
  function rewardsManagerFactory() external view returns (IRewardsManagerFactory rewardsManagerFactory_);

  /// @notice Batch pauses rewardsManagers_. The manager's pauser or owner can perform this action.
  /// @param rewardsManagers_ The array of rewards managers to pause.
  function pause(IRewardsManager[] calldata rewardsManagers_) external;

  /// @notice Batch unpauses rewardsManagers_. The manager's owner can perform this action.
  /// @param rewardsManagers_ The array of rewards managers to unpause.
  function unpause(IRewardsManager[] calldata rewardsManagers_) external;

  /// @notice Deploys a new Rewards Manager with the provided parameters.
  /// @param owner_ The owner of the rewards manager.
  /// @param pauser_ The pauser of the rewards manager.
  /// @param stakePoolConfigs_ The array of stake pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param rewardPoolConfigs_  The array of reward pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param salt_ Used to compute the resulting address of the rewards manager.
  /// @return rewardsManager_ The newly created rewards manager.
  function createRewardsManager(
    address owner_,
    address pauser_,
    StakePoolConfig[] calldata stakePoolConfigs_,
    RewardPoolConfig[] calldata rewardPoolConfigs_,
    bytes32 salt_
  ) external returns (IRewardsManager rewardsManager_);

  /// @notice Given a `caller_` and `salt_`, compute and return the address of the RewardsManager deployed with
  /// `createRewardsManager`.
  /// @param caller_ The caller of the `createRewardsManager` function.
  /// @param salt_ Used to compute the resulting address of the rewards manager along with `caller_`.
  function computeRewardsManagerAddress(address caller_, bytes32 salt_) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IDripModel} from "cozy-safety-module-shared/interfaces/IDripModel.sol";
import {IERC20} from "cozy-safety-module-shared/interfaces/IERC20.sol";
import {IReceiptToken} from "cozy-safety-module-shared/interfaces/IReceiptToken.sol";
import {IReceiptTokenFactory} from "cozy-safety-module-shared/interfaces/IReceiptTokenFactory.sol";
import {StakePool, RewardPool, AssetPool} from "../lib/structs/Pools.sol";
import {ClaimableRewardsData, PreviewClaimableRewards, UserRewardsData} from "../lib/structs/Rewards.sol";
import {RewardsManagerState} from "../lib/RewardsManagerStates.sol";
import {ClaimableRewardsData, PreviewClaimableRewards} from "../lib/structs/Rewards.sol";
import {RewardPoolConfig, StakePoolConfig} from "../lib/structs/Configs.sol";
import {ICozyManager} from "./ICozyManager.sol";

interface IRewardsManager {
  function allowedRewardPools() external view returns (uint16);

  function allowedStakePools() external view returns (uint16);

  function assetPools(IERC20 asset_) external view returns (AssetPool memory);

  function claimableRewards(uint16 stakePoolId_, uint16 rewardPoolId_)
    external
    view
    returns (ClaimableRewardsData memory);

  function claimRewards(uint16 stakePoolId_, address receiver_) external;

  function convertRewardAssetToReceiptTokenAmount(uint16 rewardPoolId_, uint256 rewardAssetAmount_)
    external
    view
    returns (uint256 depositReceiptTokenAmount_);

  function cozyManager() external returns (ICozyManager);

  function depositRewardAssets(uint16 rewardPoolId_, uint256 rewardAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_);

  function depositRewardAssetsWithoutTransfer(uint16 rewardPoolId_, uint256 rewardAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_);

  function dripRewardPool(uint16 rewardPoolId_) external;

  function dripRewards() external;

  function getClaimableRewards() external view returns (ClaimableRewardsData[][] memory);

  function getClaimableRewards(uint16 stakePoolId_) external view returns (ClaimableRewardsData[] memory);

  function getRewardPools() external view returns (RewardPool[] memory);

  function getStakePools() external view returns (StakePool[] memory);

  function getUserRewards(uint16 stakePoolId_, address user) external view returns (UserRewardsData[] memory);

  function initialize(
    address owner_,
    address pauser_,
    StakePoolConfig[] calldata stakePoolConfigs_,
    RewardPoolConfig[] calldata rewardPoolConfigs_
  ) external;

  function owner() external view returns (address);

  function pause() external;

  function pauser() external view returns (address);

  function previewClaimableRewards(uint16[] calldata stakePoolIds_, address owner_)
    external
    view
    returns (PreviewClaimableRewards[] memory);

  function previewUndrippedRewardsRedemption(uint16 rewardPoolId_, uint256 depositReceiptTokenAmount_)
    external
    view
    returns (uint256 rewardAssetAmount_);

  function redeemUndrippedRewards(
    uint16 rewardPoolId_,
    uint256 depositReceiptTokenAmount_,
    address receiver_,
    address owner_
  ) external returns (uint256 rewardAssetAmount_);

  function receiptTokenFactory() external view returns (address);

  function rewardPools(uint256 id_) external view returns (RewardPool memory);

  function rewardsManagerState() external view returns (RewardsManagerState);

  function stake(uint16 stakePoolId_, uint256 assetAmount_, address receiver_) external;

  function stakePools(uint256 id_) external view returns (StakePool memory);

  function stakeWithoutTransfer(uint16 stakePoolId_, uint256 assetAmount_, address receiver_) external;

  function unpause() external;

  function updateConfigs(StakePoolConfig[] calldata stakePoolConfigs_, RewardPoolConfig[] calldata rewardPoolConfigs_)
    external;

  function unstake(uint16 stakePoolId_, uint256 stkReceiptTokenAmount_, address receiver_, address owner_) external;

  function updateUserRewardsForStkReceiptTokenTransfer(address from_, address to_) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IRewardsManager} from "./IRewardsManager.sol";
import {RewardPoolConfig, StakePoolConfig} from "../lib/structs/Configs.sol";

interface IRewardsManagerFactory {
  /// @dev Emitted when a new Rewards Manager is deployed.
  /// @param rewardsManager The deployed rewards manager.
  event RewardsManagerDeployed(IRewardsManager rewardsManager);

  /// @notice Address of the Rewards Manager logic contract used to deploy new reward managers.
  function rewardsManagerLogic() external view returns (IRewardsManager);

  /// @notice Creates a new Rewards Manager contract with the specified configuration.
  /// @param owner_ The owner of the rewards manager.
  /// @param pauser_ The pauser of the rewards manager.
  /// @param stakePoolConfigs_ The configuration for the stake pools. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param rewardPoolConfigs_ The configuration for the reward pools. These configs must obey requirements described
  /// in `Configurator.updateConfigs`.
  /// @param baseSalt_ Used to compute the resulting address of the rewards manager.
  /// @return rewardsManager_ The deployed rewards manager.
  function deployRewardsManager(
    address owner_,
    address pauser_,
    StakePoolConfig[] calldata stakePoolConfigs_,
    RewardPoolConfig[] calldata rewardPoolConfigs_,
    bytes32 baseSalt_
  ) external returns (IRewardsManager rewardsManager_);

  /// @notice Given the `baseSalt_` compute and return the address that Rewards Manager will be deployed to.
  /// @dev Rewards Manager addresses are uniquely determined by their salt because the deployer is always the factory,
  /// and the use of minimal proxies means they all have identical bytecode and therefore an identical bytecode hash.
  /// @dev The `baseSalt_` is the user-provided salt, not the final salt after hashing with the chain ID.
  /// @param baseSalt_ The user-provided salt.
  /// @return The resulting address of the rewards manager.
  function computeAddress(bytes32 baseSalt_) external view returns (address);

  /// @notice Given the `baseSalt_`, return the salt that will be used for deployment.
  /// @param baseSalt_ The user-provided salt.
  /// @return The resulting salt that will be used for deployment.
  function salt(bytes32 baseSalt_) external view returns (bytes32);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {IDripModel} from "cozy-safety-module-shared/interfaces/IDripModel.sol";
import {IERC20} from "cozy-safety-module-shared/interfaces/IERC20.sol";

struct RewardPoolConfig {
  // The underlying asset of the reward pool.
  IERC20 asset;
  // The drip model for the reward pool.
  IDripModel dripModel;
}

struct StakePoolConfig {
  // The underlying asset of the stake pool.
  IERC20 asset;
  // The rewards weight of the stake pool.
  uint16 rewardsWeight;
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

import {IDripModel} from "cozy-safety-module-shared/interfaces/IDripModel.sol";
import {IERC20} from "cozy-safety-module-shared/interfaces/IERC20.sol";
import {IReceiptToken} from "cozy-safety-module-shared/interfaces/IReceiptToken.sol";

struct AssetPool {
  // The total balance of assets held by a rewards manager. This should be equivalent to asset.balanceOf(address(this)),
  // discounting any assets directly sent to the rewards manager via direct transfer.
  uint256 amount;
}

struct StakePool {
  // The balance of the underlying asset held by the stake pool.
  uint256 amount;
  // The underlying asset of the stake pool.
  IERC20 asset;
  // The receipt token for the stake pool.
  IReceiptToken stkReceiptToken;
  // The weighting of each stake pool's claim to all reward pools in terms of a ZOC. Must sum to ZOC. e.g.
  // stakePoolA.rewardsWeight = 10%, means stake pool A is eligible for up to 10% of rewards dripped from all reward
  // pools.
  uint16 rewardsWeight;
}

struct RewardPool {
  // The amount of undripped rewards held by the reward pool.
  uint256 undrippedRewards;
  // The cumulative amount of rewards dripped since the last config update. This value is reset to 0 on each config
  // update.
  uint256 cumulativeDrippedRewards;
  // The last time undripped rewards were dripped from the reward pool.
  uint128 lastDripTime;
  // The underlying asset of the reward pool.
  IERC20 asset;
  // The drip model for the reward pool.
  IDripModel dripModel;
  // The receipt token for the reward pool.
  IReceiptToken depositReceiptToken;
}

struct IdLookup {
  // The index of the item in an array.
  uint16 index;
  // Whether the item exists.
  bool exists;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {IERC20} from "cozy-safety-module-shared/interfaces/IERC20.sol";

// Used to track the rewards a user is entitled to for a given (stake pool, reward pool) pair.
struct UserRewardsData {
  // The total amount of rewards accrued by the user.
  uint256 accruedRewards;
  // The index snapshot the relevant claimable rewards data, when the user's accrued rewards were updated. The index
  // snapshot must update each time the user's accrued rewards are updated.
  uint256 indexSnapshot;
}

struct ClaimRewardsArgs {
  // The ID of the stake pool.
  uint16 stakePoolId;
  // The address that will receive the rewards.
  address receiver;
  // The address that owns the stkReceiptTokens.
  address owner;
}

// Used to track the total rewards all users are entitled to for a given (stake pool, reward pool) pair.
struct ClaimableRewardsData {
  // The cumulative amount of rewards that are claimable. This value is reset to 0 on each config update.
  uint256 cumulativeClaimableRewards;
  // The index snapshot the relevant claimable rewards data, when the cumulative claimed rewards were updated. The index
  // snapshot must update each time the cumulative claimed rewards are updated.
  uint256 indexSnapshot;
}

// Used as a return type for the `previewClaimableRewards` function.
struct PreviewClaimableRewards {
  // The ID of the stake pool.
  uint16 stakePoolId;
  // An array of preview claimable rewards data with one entry for each reward pool.
  PreviewClaimableRewardsData[] claimableRewardsData;
}

struct PreviewClaimableRewardsData {
  // The ID of the reward pool.
  uint16 rewardPoolId;
  // The amount of claimable rewards.
  uint256 amount;
  // The reward asset.
  IERC20 asset;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

enum RewardsManagerState {
  ACTIVE,
  PAUSED
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external view returns (address);
}