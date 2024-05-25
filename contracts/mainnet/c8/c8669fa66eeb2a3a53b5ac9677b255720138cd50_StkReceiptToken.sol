// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {ReceiptToken} from "cozy-safety-module-shared/ReceiptToken.sol";
import {IRewardsManager} from "./interfaces/IRewardsManager.sol";

contract StkReceiptToken is ReceiptToken {
  constructor() ReceiptToken() {}

  /// @dev Updates the user's rewards before transferring the stkReceiptTokens by calling into the rewards manager.
  function transfer(address to_, uint256 amount_) public override returns (bool) {
    IRewardsManager(module).updateUserRewardsForStkReceiptTokenTransfer(msg.sender, to_);
    return super.transfer(to_, amount_);
  }

  /// @dev Updates the user's rewards before transferring the stkReceiptTokens by calling into the rewards manager.
  function transferFrom(address from_, address to_, uint256 amount_) public override returns (bool) {
    IRewardsManager(module).updateUserRewardsForStkReceiptTokenTransfer(from_, to_);
    return super.transferFrom(from_, to_, amount_);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {ERC20} from "./lib/ERC20.sol";

contract ReceiptToken is ERC20 {
  /// @notice Address of this token's safety/rewards module.
  address public module;

  /// @dev Thrown if the minimal proxy contract is already initialized.
  error Initialized();

  /// @dev Thrown when an address is invalid.
  error InvalidAddress();

  /// @dev Thrown when the caller is not authorized to perform the action.
  error Unauthorized();

  /// @notice Replaces the constructor for minimal proxies.
  /// @param module_ The safety/rewards module for this ReceiptToken.
  /// @param name_ The name of the token.
  /// @param symbol_ The symbol of the token.
  /// @param decimals_ The decimal places of the token.
  function initialize(address module_, string memory name_, string memory symbol_, uint8 decimals_) external {
    if (module != address(0)) revert Initialized();
    __initERC20(name_, symbol_, decimals_);
    module = module_;
  }

  /// @notice Mints `amount_` of tokens to `to_`.
  function mint(address to_, uint256 amount_) external onlyModule {
    _mint(to_, amount_);
  }

  /// @notice Burns `amount_` of tokens from `from_`.
  function burn(address caller_, address owner_, uint256 amount_) external onlyModule {
    if (caller_ != owner_) {
      uint256 allowed_ = allowance[owner_][caller_]; // Saves gas for limited approvals.
      if (allowed_ != type(uint256).max) _setAllowance(owner_, caller_, allowed_ - amount_);
    }
    _burn(owner_, amount_);
  }

  /// @notice Sets the allowance such that the `_spender` can spend `_amount` of `_owner`s tokens.
  function _setAllowance(address _owner, address _spender, uint256 _amount) internal {
    allowance[_owner][_spender] = _amount;
  }

  // -------- Modifiers --------

  /// @dev Checks that msg.sender is the module address.
  modifier onlyModule() {
    if (msg.sender != address(module)) revert Unauthorized();
    _;
  }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./PackedStringLib.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/v7/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
/// @dev Modified from Solmate to use an initializer for use as a minimal proxy, and packed strings for name and symbol.
/// The formatting is kept consistent with the original so its easier to compare.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The encoded name of the token.
    bytes32 internal packedName;

    /// @notice The encoded symbol of the token.
    bytes32 internal packedSymbol;

    uint8 public decimals;

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

    /// @dev Domain separator at the time of minimal proxy initialization. This may change if a fork occurs.
    bytes32 internal initialDomainSeparator;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
      INITIAL_CHAIN_ID = block.chainid;
    }

    /// @dev Initializer, replaces constructor for minimal proxies. Must be kept internal and it's up
    /// to the caller to make sure this can only be called once. _name and _symbol must be less than 32 bytes
    /// since they are packed into bytes32 storage variables.
    /// @param _name The name of the token.
    /// @param _symbol The symbol of the token.
    /// @param _decimals The decimal places of the token.
    function __initERC20(string memory _name, string memory _symbol, uint8 _decimals) internal {
      packedName = PackedStringLib.packString(_name);
      packedSymbol = PackedStringLib.packString(_symbol);
      decimals = _decimals;

      // initialDomainSeparator is set in the initializer so the computed domain separator uses the proxy contract
      // address instead of the logic contract address.
      initialDomainSeparator = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               String Getters
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the name of the token.
    function name() public view returns (string memory) {
      return PackedStringLib.unpackString(packedName);
    }

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory) {
      return PackedStringLib.unpackString(packedSymbol);
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

    /// @notice Returns the domain separator.
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
      return block.chainid == INITIAL_CHAIN_ID ? initialDomainSeparator : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name())),
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for encoding/decoding strings shorter than 32 bytes as one word.
/// @notice Solidity has built-in functionality for storing strings shorter than 32 bytes in
/// a single word, but it must determine at runtime whether to treat each string as one word
/// or several. This introduces a significant amount of bytecode and runtime complexity to
/// any contract storing strings.
/// @notice When it is known in advance that a string will never be longer than 31 bytes,
/// telling the compiler to always treat strings as such can greatly reduce extraneous runtime
/// code that would have never been executed.
/// @notice https://docs.soliditylang.org/en/v0.8.17/types.html#bytes-and-string-as-arrays
/// @author Solmate (https://github.com/transmissions11/solmate/blob/bf9e7d0c790273a16fc815f486dd5f37e46a7204/src/utils/PackedStringLib.sol)
library PackedStringLib {
    error UnpackableString();

    /// @dev Pack a 0-31 byte string into a bytes32.
    /// @dev Will revert if string exceeds 31 bytes.
    function packString(string memory unpackedString) internal pure returns (bytes32 packedString) {
        uint256 length = bytes(unpackedString).length;
        // Verify string length and body will fit into one word
        if (length > 31) {
            revert UnpackableString();
        }
        assembly {
            // -------------------------------------------------------------------------//
            // Layout in memory of input string (less than 32 bytes)                    //
            // Note that "position" is relative to the pointer, not absolute            //
            // -------------------------------------------------------------------------//
            // Bytes   | Value             | Description                                //
            // -------------------------------------------------------------------------//
            // 0:31     | 0                 | Empty left-padding for string length      //
            //          |                   | Not included in output                    //
            // 31:32    | length            | Single-byte length between 0 and 31       //
            // 32:63    | body / unknown    | Right-padded string body if length > 0    //
            //          |                   | Unknown if length is zero                 //
            // 63:64    | 0 / unknown       | Empty right-padding byte for string if    //
            //          |                   | length > 0; otherwise, unknown data       //
            //          |                   | This byte is never included in the output //
            // -------------------------------------------------------------------------//

            // Read one word starting at the last byte of the length, so that the first
            // byte of the packed string will be its length (left-padded) and the
            // following 31 bytes will contain the string's body (right-padded).
            packedString := mul(
                mload(add(unpackedString, 31)),
                // If length is zero, the word after length will not be allocated for
                // the body and may contain dirty bits. We multiply the packed value by
                // length > 0 to ensure the body is null if the length is zero.
                iszero(iszero(length))
            )
        }
    }

    /// @dev Memory-safe string unpacking - updates the free memory pointer to
    /// allocate space for the string. Useful for strings which are used within
    /// the contract and not simply returned in metadata queries.
    /// @notice Does not check `packedString` has valid encoding, assumes it was created
    /// by `packString`.
    /// Note that supplying an input not generated by this library can result in severe memory
    /// corruption. The returned string can have an apparent length of up to 255 bytes and
    /// overflow into adjacent memory regions if it is not encoded correctly.
    function unpackString(bytes32 packedString) internal pure returns (string memory unpackedString) {
        assembly {
            // Set pointer for `unpackedString` to free memory pointer.
            unpackedString := mload(0x40)
            // Clear full buffer - it may contain dirty (unallocated) data.
            // Normally this would not matter for the trailing zeroes of the body,
            // but developers may assume that strings are padded to full words so
            // we maintain that practice here.
            mstore(unpackedString, 0)
            mstore(add(unpackedString, 0x20), 0)
            // Increase free memory pointer by 64 bytes to allocate space for
            // the string's length and body - prevents Solidity's memory
            // management from overwriting it.
            mstore(0x40, add(unpackedString, 0x40))
            // Write the packed string to memory starting at the last byte of the
            // length buffer. This places the single-byte length at the end of the
            // length word and the 0-31 byte body at the start of the body word.
            mstore(add(unpackedString, 0x1f), packedString)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IOwnable} from "./IOwnable.sol";

interface IGovernable is IOwnable {
  function pauser() external view returns (address);
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
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external view returns (address);
}