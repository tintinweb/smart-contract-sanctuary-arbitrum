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
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
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

// src/lib/RewardsManagerStates.sol

enum RewardsManagerState {
  ACTIVE,
  PAUSED
}

// lib/cozy-safety-module-shared/src/interfaces/IGovernable.sol

interface IGovernable is IOwnable {
  function pauser() external view returns (address);
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

// src/lib/structs/Rewards.sol

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

// src/lib/structs/Configs.sol

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

// src/lib/structs/Pools.sol

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

// src/interfaces/ICozyManager.sol

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

// src/interfaces/IRewardsManager.sol

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

// src/interfaces/IRewardsManagerFactory.sol

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

// src/RewardsManagerFactory.sol

contract RewardsManagerFactory is IRewardsManagerFactory {
  using Clones for address;

  /// @notice Address of the Cozy protocol manager.
  ICozyManager public immutable cozyManager;

  /// @notice Address of the Rewards Manager logic contract used to deploy new Rewards Managers.
  IRewardsManager public immutable rewardsManagerLogic;

  /// @notice Thrown when the caller is not authorized to perform the action.
  error Unauthorized();

  /// @notice Thrown if an address parameter is invalid.
  error InvalidAddress();

  /// @param cozyManager_ The Cozy protocol manager.
  /// @param rewardsManagerLogic_ Logic contract for deploying new Rewards Managers.
  constructor(ICozyManager cozyManager_, IRewardsManager rewardsManagerLogic_) {
    _assertAddressNotZero(address(cozyManager_));
    _assertAddressNotZero(address(rewardsManagerLogic_));
    cozyManager = cozyManager_;
    rewardsManagerLogic = rewardsManagerLogic_;
  }

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
  ) public returns (IRewardsManager rewardsManager_) {
    // It'd be harmless to let anyone deploy rewards managers, but to make it more clear where the proper entry
    // point for safety module creation is, we restrict this to being called by the cozy manager.
    if (msg.sender != address(cozyManager)) revert Unauthorized();

    rewardsManager_ = IRewardsManager(address(rewardsManagerLogic).cloneDeterministic(salt(baseSalt_)));
    emit RewardsManagerDeployed(rewardsManager_);
    rewardsManager_.initialize(owner_, pauser_, stakePoolConfigs_, rewardPoolConfigs_);
  }

  /// @notice Given the `baseSalt_` compute and return the address that Rewards Manager will be deployed to.
  /// @dev Rewards Manager addresses are uniquely determined by their salt because the deployer is always the factory,
  /// and the use of minimal proxies means they all have identical bytecode and therefore an identical bytecode hash.
  /// @dev The `baseSalt_` is the user-provided salt, not the final salt after hashing with the chain ID.
  /// @param baseSalt_ The user-provided salt.
  /// @return The resulting address of the rewards manager.
  function computeAddress(bytes32 baseSalt_) external view returns (address) {
    return Clones.predictDeterministicAddress(address(rewardsManagerLogic), salt(baseSalt_), address(this));
  }

  /// @notice Given the `baseSalt_`, return the salt that will be used for deployment.
  /// @param baseSalt_ The user-provided salt.
  /// @return The resulting salt that will be used for deployment.
  function salt(bytes32 baseSalt_) public view returns (bytes32) {
    // We take the user-provided salt and concatenate it with the chain ID before hashing. This is
    // required because CREATE2 with a user provided salt or CREATE both make it easy for an
    // attacker to create a malicious Rewards Manager on one chain and pass it off as a reputable Rewards Manager from
    // another chain since the two have the same address.
    return keccak256(abi.encode(baseSalt_, block.chainid));
  }

  /// @dev Revert if the address is the zero address.
  function _assertAddressNotZero(address address_) internal pure {
    if (address_ == address(0)) revert InvalidAddress();
  }
}