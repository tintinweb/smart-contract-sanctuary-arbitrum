// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.22 ^0.8.0 ^0.8.20;

// lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// lib/cozy-safety-module-rewards-manager/src/lib/RewardsManagerStates.sol

enum RewardsManagerState {
  ACTIVE,
  PAUSED
}

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

// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC-20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[ERC-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC-20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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

// lib/openzeppelin-contracts/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// src/interfaces/IMetadataRegistry.sol

interface IMetadataRegistry {
  struct Metadata {
    string name;
    string description;
    string logoURI;
    string extraData;
  }

  /// @notice Update metadata for a SafetyModule. This function can be called by the CozyRouter.
  /// @param safetyModule_ The address of the SafetyModule.
  /// @param metadata_ The new metadata for the SafetyModule.
  /// @param caller_ The address of the CozyRouter caller.
  function updateSafetyModuleMetadata(address safetyModule_, Metadata calldata metadata_, address caller_) external;
}

// src/interfaces/IStETH.sol

interface IStETH {
  function allowance(address owner_, address spender_) external view returns (uint256);
  function approve(address spender_, uint256 amount_) external returns (bool);
  function balanceOf(address account_) external view returns (uint256);
  function getSharesByPooledEth(uint256 ethAmount_) external view returns (uint256);
  function getPooledEthByShares(uint256 sharesAmount_) external view returns (uint256);
  function getTotalPooledEther() external returns (uint256);
  function getTotalShares() external returns (uint256);
  function transfer(address recipient_, uint256 amount_) external returns (bool);
  function transferFrom(address sender_, address recipient_, uint256 amount_) external returns (bool);
  function submit(address referral_) external payable returns (uint256);
}

// src/interfaces/IWeth.sol

/**
 * @dev Interface for WETH9.
 */
interface IWeth {
  /// @notice Returns the remaining number of tokens that `spender_` will be allowed to spend on behalf of `holder_`.
  function allowance(address holder, address spender) external view returns (uint256 remainingAllowance_);

  /// @notice Sets `amount_` as the allowance of `spender_` over the caller's tokens.
  function approve(address spender, uint256 amount) external returns (bool success_);

  /// @notice Returns the amount of tokens owned by `account_`.
  function balanceOf(address account_) external view returns (uint256 balance_);

  /// @notice Returns the decimal places of the token.
  function decimals() external view returns (uint8);

  /// @notice Deposit ETH and receive WETH.
  function deposit() external payable;

  /// @notice Returns the name of the token.
  function name() external view returns (string memory);

  /// @notice Returns the symbol of the token.
  function symbol() external view returns (string memory);

  /// @notice Returns the amount of tokens in existence.
  function totalSupply() external view returns (uint256 supply_);

  /// @notice Moves `amount_` tokens from the caller's account to `to_`.
  function transfer(address to_, uint256 amount_) external returns (bool success_);

  /// @notice Moves `amount_` tokens from `from_` to `to_` using the allowance mechanism. `amount_` is then deducted
  /// from the caller's allowance.
  function transferFrom(address from_, address to_, uint256 amount_) external returns (bool success_);

  /// @notice Burn WETH to withdraw ETH.
  function withdraw(uint256 amount_) external;
}

// src/interfaces/IWstETH.sol

interface IWstETH {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function unwrap(uint256 wstETHAmount) external returns (uint256);
  function wrap(uint256 stETHAmount) external returns (uint256);
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

// lib/cozy-safety-module-models/src/interfaces/IDripModelConstantFactory.sol

interface IDripModelConstantFactory {
  /// @notice Deploys a DripModelConstant contract and emits a DeployedDripModelConstant event that
  /// indicates what the params from the deployment are. This address is then cached inside the
  /// isDeployed mapping.
  /// @return model_ which has an address that is deterministic with the input amountPerSecond_.
  function deployModel(address owner_, uint256 amountPerSecond_, bytes32 baseSalt_)
    external
    returns (IDripModel model_);

  /// @notice Given a `caller_`, `owner_`, `amountPerSecond_`, and `baseSalt_`, return the address of the
  /// DripModelConstant deployed from the `DripModelConstantFactory`.
  function computeAddress(address caller_, address owner_, uint256 amountPerSecond_, bytes32 baseSalt_)
    external
    view
    returns (address);
}

// lib/cozy-safety-module-rewards-manager/src/lib/structs/Rewards.sol

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

// src/interfaces/IConnector.sol

interface IConnector {
  /// @notice Calculates the minimum amount of base assets needed to get back at least `assets_` amount of the wrapped
  /// tokens.
  function convertToBaseAssetsNeeded(uint256 assets_) external view returns (uint256);

  /// @notice Calculates the amount of wrapped tokens needed for `assets_` amount of the base asset.
  function convertToWrappedAssets(uint256 assets_) external view returns (uint256);

  /// @notice Wraps the base asset and mints wrapped tokens to the `receiver_` address.
  function wrapBaseAsset(address recipient_, uint256 amount_) external returns (uint256);

  /// @notice Unwraps the wrapped tokens and sends base assets to the `receiver_` address.
  function unwrapWrappedAsset(address recipient_, uint256 amount_) external returns (uint256);

  /// @notice Returns the base asset address.
  function baseAsset() external view returns (IERC20);

  /// @notice Returns the amount of wrapped tokens owned by `account_`.
  function balanceOf(address account_) external view returns (uint256);
}

// src/interfaces/ITrigger.sol

/**
 * @dev The minimal functions a trigger must implement to work with SafetyModules.
 */
interface ITrigger {
  /// @notice The current trigger state.
  function state() external returns (TriggerState);
}

// lib/cozy-safety-module-rewards-manager/src/lib/structs/Configs.sol

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

struct AssetPool_0 {
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

// lib/cozy-safety-module-rewards-manager/src/lib/structs/Pools.sol

struct AssetPool_1 {
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

// lib/cozy-safety-module-shared/src/lib/SafeERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 * @dev This is a forked version which uses our IERC20 interfaces instead of the OpenZeppelin's ERC20. The formatting
 * is kept consistent with the original so its easier to compare.
 */
library SafeERC20 {
  using Address for address;

  /**
   * @dev An operation with an ERC20 token failed.
   */
  error SafeERC20FailedOperation(address token);

  /**
   * @dev Indicates a failed `decreaseAllowance` request.
   */
  error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

  /**
   * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
   * non-reverting calls are assumed to be successful.
   */
  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
  }

  /**
   * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
   * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
   */
  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
  }

  /**
   * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
   * non-reverting calls are assumed to be successful.
   */
  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 oldAllowance = token.allowance(address(this), spender);
    forceApprove(token, spender, oldAllowance + value);
  }

  /**
   * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
   * value, non-reverting calls are assumed to be successful.
   */
  function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
    unchecked {
      uint256 currentAllowance = token.allowance(address(this), spender);
      if (currentAllowance < requestedDecrease) {
        revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
      }
      forceApprove(token, spender, currentAllowance - requestedDecrease);
    }
  }

  /**
   * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
   * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
   * to be set to zero before setting it to a non-zero value, such as USDT.
   */
  function forceApprove(IERC20 token, address spender, uint256 value) internal {
    bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

    if (!_callOptionalReturnBool(token, approvalCall)) {
      _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
      _callOptionalReturn(token, approvalCall);
    }
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

    bytes memory returndata = address(token).functionCall(data);
    if (returndata.length != 0 && !abi.decode(returndata, (bool))) revert SafeERC20FailedOperation(address(token));
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   *
   * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
   */
  function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
    // and not revert is the subcall reverts.

    (bool success, bytes memory returndata) = address(token).call(data);
    return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
  }
}

// src/interfaces/IOwnableTriggerFactory.sol

interface IOwnableTriggerFactory {
  function deployTrigger(address _owner, TriggerMetadata memory _metadata, bytes32 _salt)
    external
    returns (ITrigger _trigger);

  function computeTriggerAddress(address _owner, bytes32 _salt) external view returns (address _address);
}

// src/interfaces/IUMATriggerFactory.sol

/**
 * @notice This is a utility contract to make it easy to deploy UMATriggers for
 * the Cozy Safety Module protocol.
 * @dev Be sure to approve the trigger to spend the rewardAmount before calling
 * `deployTrigger`, otherwise the latter will revert. Funds need to be available
 * to the created trigger within its constructor so that it can submit its query
 * to the UMA oracle.
 */
interface IUMATriggerFactory {
  /// @dev Emitted when the factory deploys a trigger.
  /// @param trigger The address at which the trigger was deployed.
  /// @param triggerConfigId See the function of the same name in this contract.
  /// @param oracle The address of the UMA Optimistic Oracle.
  /// @param query The query that the trigger submitted to the UMA Optimistic Oracle.
  /// @param rewardToken The token used to pay the reward to users that successfully propose answers to the query.
  /// @param rewardAmount The amount of rewardToken that will be paid as a reward to anyone who successfully proposes an
  /// answer to the query.
  /// @param refundRecipient Default address that will recieve any leftover rewards at UMA query settlement time.
  /// @param bondAmount The amount of `rewardToken` that must be staked by a user wanting to propose or dispute an
  /// answer to the query.
  /// @param proposalDisputeWindow The window of time in seconds within which a proposed answer may be disputed.
  /// @param name The human-readble name of the trigger.
  /// @param category The category of the trigger.
  /// @param description A human-readable description of the trigger.
  /// @param logoURI The URI of a logo image to represent the trigger.
  /// For other attributes, see the docs for the params of `deployTrigger` in
  /// this contract.
  event TriggerDeployed(
    address trigger,
    bytes32 indexed triggerConfigId,
    address indexed oracle,
    string query,
    address indexed rewardToken,
    uint256 rewardAmount,
    address refundRecipient,
    uint256 bondAmount,
    uint256 proposalDisputeWindow,
    string name,
    string category,
    string description,
    string logoURI
  );

  /// @notice Maps triggerConfigIds to whether an UMATrigger has been created with the related config.
  function exists(bytes32) external view returns (bool);

  /// @notice Call this function to deploy an UMATrigger.
  /// @param _query The query that the trigger will send to the UMA Optimistic
  /// Oracle for evaluation.
  /// @param _rewardToken The token used to pay the reward to users that propose
  /// answers to the query.
  /// @param _rewardAmount The amount of rewardToken that will be paid as a
  /// reward to anyone who proposes an answer to the query.
  /// @param _refundRecipient Default address that will recieve any leftover
  /// rewards at UMA query settlement time.
  /// @param _bondAmount The amount of `rewardToken` that must be staked by a
  /// user wanting to propose or dispute an answer to the query. See UMA's price
  /// dispute workflow for more information. It's recommended that the bond
  /// amount be a significant value to deter addresses from proposing malicious,
  /// false, or otherwise self-interested answers to the query.
  /// @param _proposalDisputeWindow The window of time in seconds within which a
  /// proposed answer may be disputed. See UMA's "customLiveness" setting for
  /// more information. It's recommended that the dispute window be fairly long
  /// (12-24 hours), given the difficulty of assessing expected queries (e.g.
  /// "Was protocol ABCD hacked") and the amount of funds potentially at stake.
  /// @param _metadata See TriggerMetadata for more info.
  function deployTrigger(
    string memory _query,
    IERC20 _rewardToken,
    uint256 _rewardAmount,
    address _refundRecipient,
    uint256 _bondAmount,
    uint256 _proposalDisputeWindow,
    TriggerMetadata memory _metadata
  ) external returns (ITrigger _trigger);

  /// @notice Call this function to determine the address at which a trigger
  /// with the supplied configuration would be deployed. See `deployTrigger` for
  /// more information on parameters and their meaning.
  function computeTriggerAddress(
    string memory _query,
    IERC20 _rewardToken,
    uint256 _rewardAmount,
    address _refundRecipient,
    uint256 _bondAmount,
    uint256 _proposalDisputeWindow
  ) external view returns (address _address);

  /// @notice Call this function to find triggers with the specified
  /// configurations that can be used for safety modules. See
  /// `deployTrigger` for more information on parameters and their meaning.
  function findAvailableTrigger(
    string memory _query,
    IERC20 _rewardToken,
    uint256 _rewardAmount,
    address _refundRecipient,
    uint256 _bondAmount,
    uint256 _proposalDisputeWindow
  ) external view returns (address);

  /// @notice Call this function to determine the identifier of the supplied
  /// trigger configuration. This identifier is used both to track if there is an
  /// UMATrigger deployed with this configuration (see `exists`) and is
  /// emitted as a part of the TriggerDeployed event when triggers are deployed.
  /// @dev This function takes the rewardAmount as an input despite it not being
  /// an argument of the UMATrigger constructor nor it being held in storage by
  /// the trigger. This is done because the rewardAmount is something that
  /// deployers could reasonably differ on. Deployer A might deploy a trigger
  /// that is identical to what Deployer B wants in every way except the amount
  /// of rewardToken that is being offered, and it would still be reasonable for
  /// Deployer B to not want to re-use A's trigger for their own Safety Module.
  function triggerConfigId(
    string memory _query,
    IERC20 _rewardToken,
    uint256 _rewardAmount,
    address _refundRecipient,
    uint256 _bondAmount,
    uint256 _proposalDisputeWindow
  ) external view returns (bytes32);
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

// lib/cozy-safety-module-rewards-manager/src/interfaces/ICozyManager.sol

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

// lib/cozy-safety-module-rewards-manager/src/interfaces/IRewardsManager.sol

interface IRewardsManager {
  function allowedRewardPools() external view returns (uint16);

  function allowedStakePools() external view returns (uint16);

  function assetPools(IERC20 asset_) external view returns (AssetPool_1 memory);

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

// lib/cozy-safety-module-rewards-manager/src/interfaces/IRewardsManagerFactory.sol

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
  function assetPools(IERC20 asset_) external view returns (AssetPool_0 memory assetPool_);

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

// src/interfaces/IChainlinkTriggerFactory.sol

/**
 * @notice Deploys Chainlink triggers that ensure two oracles stay within the given price
 * tolerance. It also supports creating a fixed price oracle to use as the truth oracle, useful
 * for e.g. ensuring stablecoins maintain their peg.
 */
interface IChainlinkTriggerFactory {
  /// @notice Call this function to determine the address at which a trigger
  /// with the supplied configuration would be deployed.
  /// @param truthOracle_ The address of the desired truthOracle for the trigger.
  /// @param trackingOracle_ The address of the desired trackingOracle for the trigger.
  /// @param priceTolerance_ The priceTolerance that the deployed trigger would
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param truthFrequencyTolerance_ The frequency tolerance that the deployed trigger would
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param trackingFrequencyTolerance_ The frequency tolerance that the deployed trigger would
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  /// @param triggerCount_ The zero-indexed ordinal of the trigger with respect to its
  /// configuration, e.g. if this were to be the fifth trigger deployed with
  /// these configs, then _triggerCount should be 4.
  function computeTriggerAddress(
    AggregatorV3Interface truthOracle_,
    AggregatorV3Interface trackingOracle_,
    uint256 priceTolerance_,
    uint256 truthFrequencyTolerance_,
    uint256 trackingFrequencyTolerance_,
    uint256 triggerCount_
  ) external view returns (address address_);

  /// @notice Call this function to compute the address that a
  /// FixedPriceAggregator contract would be deployed to with the provided args.
  /// @param _price The fixed price, in the decimals indicated, returned by the deployed oracle.
  /// @param _decimals The number of decimals of the fixed price.
  function computeFixedPriceAggregatorAddress(int256 _price, uint8 _decimals) external view returns (address);

  /// @notice Call this function to deploy a ChainlinkTrigger.
  /// @param truthOracle_ The address of the desired truthOracle for the trigger.
  /// @param trackingOracle_ The address of the desired trackingOracle for the trigger.
  /// @param priceTolerance_ The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param truthFrequencyTolerance_ The frequency tolerance that the deployed trigger will
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param trackingFrequencyTolerance_ The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  /// @param metadata_ See TriggerMetadata for more info.
  function deployTrigger(
    AggregatorV3Interface truthOracle_,
    AggregatorV3Interface trackingOracle_,
    uint256 priceTolerance_,
    uint256 truthFrequencyTolerance_,
    uint256 trackingFrequencyTolerance_,
    TriggerMetadata memory metadata_
  ) external returns (ITrigger trigger_);

  /// @notice Call this function to deploy a ChainlinkTrigger with a
  /// FixedPriceAggregator as its truthOracle. This is useful if you were
  /// building a market in which you wanted to track whether or not a stablecoin
  /// asset had become depegged.
  /// @param _price The fixed price, or peg, with which to compare the trackingOracle price.
  /// @param _decimals The number of decimals of the fixed price. This should
  /// match the number of decimals used by the desired _trackingOracle.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _frequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  function deployTrigger(
    int256 _price,
    uint8 _decimals,
    AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _frequencyTolerance,
    TriggerMetadata memory _metadata
  ) external returns (ITrigger _trigger);

  /// @notice Call this function to determine the identifier of the supplied trigger
  /// configuration. This identifier is used both to track the number of
  /// triggers deployed with this configuration (see `triggerCount`) and is
  /// emitted at the time triggers with that configuration are deployed.
  /// @param truthOracle_ The address of the desired truthOracle for the trigger.
  /// @param trackingOracle_ The address of the desired trackingOracle for the trigger.
  /// @param priceTolerance_ The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param truthFrequencyTolerance_ The frequency tolerance that the deployed trigger will
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param trackingFrequencyTolerance_ The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  function triggerConfigId(
    AggregatorV3Interface truthOracle_,
    AggregatorV3Interface trackingOracle_,
    uint256 priceTolerance_,
    uint256 truthFrequencyTolerance_,
    uint256 trackingFrequencyTolerance_
  ) external view returns (bytes32);

  /// @notice Maps the triggerConfigId to the number of triggers created with those configs.
  function triggerCount(bytes32) external view returns (uint256);
}

// src/lib/structs/TriggerFactories.sol

struct TriggerFactories {
  IChainlinkTriggerFactory chainlinkTriggerFactory;
  IOwnableTriggerFactory ownableTriggerFactory;
  IUMATriggerFactory umaTriggerFactory;
}

// src/lib/router/CozyRouterCommon.sol

contract CozyRouterCommon {
  /// @notice The Cozy Safety Module Manager address.
  ICozySafetyModuleManager public immutable safetyModuleCozyManager;

  /// @dev Thrown when an invalid address is passed as a parameter.
  error InvalidAddress();

  constructor(ICozySafetyModuleManager safetyModuleCozyManager_) {
    safetyModuleCozyManager = safetyModuleCozyManager_;
  }

  /// @notice Given a `caller_` and `baseSalt_`, return the salt used to compute the address of a deployed contract
  /// using a deployment helper function on this `CozyRouter`.
  /// @param caller_ The caller of the deployment helper function on this `CozyRouter`.
  /// @param baseSalt_ Used to compute the deployment salt.
  function computeSalt(address caller_, bytes32 baseSalt_) public pure returns (bytes32) {
    // To avoid front-running of factory deploys using a salt, msg.sender is used to compute the deploy salt.
    return keccak256(abi.encodePacked(baseSalt_, caller_));
  }

  /// @dev Revert if the address is the zero address.
  function _assertAddressNotZero(address address_) internal pure {
    if (address_ == address(0)) revert InvalidAddress();
  }
}

// src/lib/router/RewardsManagerDeploymentHelpers.sol

abstract contract RewardsManagerDeploymentHelpers is CozyRouterCommon {
  /// @notice The Cozy Rewards Manager Cozy Manager address.
  ICozyManager public immutable rewardsManagerCozyManager;

  constructor(ICozyManager rewardsManagerCozyManager_) {
    rewardsManagerCozyManager = rewardsManagerCozyManager_;
  }

  /// @notice Deploys a new Rewards Manager.
  function deployRewardsManager(
    address owner_,
    address pauser_,
    StakePoolConfig[] calldata stakePoolConfigs_,
    RewardPoolConfig[] calldata rewardPoolConfigs_,
    bytes32 salt_
  ) external payable returns (IRewardsManager rewardsManager_) {
    rewardsManager_ = rewardsManagerCozyManager.createRewardsManager(
      owner_, pauser_, stakePoolConfigs_, rewardPoolConfigs_, computeSalt(msg.sender, salt_)
    );
  }
}

// src/lib/router/DripModelDeploymentHelpers.sol

abstract contract DripModelDeploymentHelpers is CozyRouterCommon {
  /// @notice The DripModelConstantFactory address.
  IDripModelConstantFactory public immutable dripModelConstantFactory;

  constructor(IDripModelConstantFactory dripModelConstantFactory_) {
    dripModelConstantFactory = dripModelConstantFactory_;
  }

  /// @notice Deploys a new DripModelConstant.
  function deployDripModelConstant(address owner_, uint256 amountPerSecond_, bytes32 baseSalt_)
    external
    payable
    returns (IDripModel dripModel_)
  {
    dripModel_ = dripModelConstantFactory.deployModel(owner_, amountPerSecond_, computeSalt(msg.sender, baseSalt_));
  }
}

// src/lib/router/SafetyModuleDeploymentHelpers.sol

abstract contract SafetyModuleDeploymentHelpers is CozyRouterCommon {
  /// @notice Deploys a new Cozy Safety Module.
  function deploySafetyModule(
    address owner_,
    address pauser_,
    UpdateConfigsCalldataParams calldata configs_,
    bytes32 salt_
  ) external payable returns (ISafetyModule safetyModule_) {
    safetyModule_ =
      safetyModuleCozyManager.createSafetyModule(owner_, pauser_, configs_, computeSalt(msg.sender, salt_));
  }

  /// @notice Update metadata for a safety module.
  /// @dev `msg.sender` must be the owner of the safety module.
  /// @param metadataRegistry_ The address of the metadata registry.
  /// @param safetyModule_ The address of the safety module.
  /// @param metadata_ The new metadata for the safety module.
  function updateSafetyModuleMetadata(
    IMetadataRegistry metadataRegistry_,
    address safetyModule_,
    IMetadataRegistry.Metadata calldata metadata_
  ) external payable {
    metadataRegistry_.updateSafetyModuleMetadata(safetyModule_, metadata_, msg.sender);
  }
}

// src/lib/router/TokenHelpers.sol

abstract contract TokenHelpers is CozyRouterCommon {
  using Address for address;
  using SafeERC20 for IERC20;

  /// @dev Thrown when the router's balance is too low to perform the requested action.
  error InsufficientBalance();

  /// @dev Thrown when a token or ETH transfer failed.
  error TransferFailed();

  /// @notice Approves the router to spend `value_` of the specified `token_`. tokens on behalf of the caller. The
  /// permit transaction must be submitted by the `deadline_`.
  /// @dev More info on permit: https://eips.ethereum.org/EIPS/eip-2612
  function permitRouter(IERC20 token_, uint256 value_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_)
    external
    payable
  {
    // For ERC-2612 permits, use the approval amount as the `value_`. For DAI permits, `value_` should be the
    // nonce as all DAI permits are for `type(uint256).max` by default.
    IERC20(token_).permit(msg.sender, address(this), value_, deadline_, v_, r_, s_);
  }

  /// @notice Transfers the full balance of the router's holdings of `token_` to `recipient_`, as long as the contract
  /// holds at least `amountMin_` tokens.
  function sweepToken(IERC20 token_, address recipient_, uint256 amountMin_) external payable returns (uint256 amount_) {
    _assertAddressNotZero(recipient_);
    amount_ = token_.balanceOf(address(this));
    if (amount_ < amountMin_) revert InsufficientBalance();
    if (amount_ > 0) token_.safeTransfer(recipient_, amount_);
  }

  /// @notice Transfers `amount_` of the router's holdings of `token_` to `recipient_`.
  function transferTokens(IERC20 token_, address recipient_, uint256 amount_) external payable {
    _assertAddressNotZero(recipient_);
    token_.safeTransfer(recipient_, amount_);
  }
}

// src/lib/router/SafetyModuleActions.sol

abstract contract SafetyModuleActions is CozyRouterCommon {
  using SafeERC20 for IERC20;

  // ---------------------------------
  // -------- Deposit / Stake --------
  // ---------------------------------

  /// @notice Deposits assets into a `safetyModule_` reserve pool. Mints `depositReceiptTokenAmount_` to `receiver_` by
  /// depositing exactly `reserveAssetAmount_` of the reserve pool's underlying tokens into the `safetyModule_`. The
  /// specified amount of assets are transferred from the caller to the Safety Module.
  /// @dev This will revert if the router is not approved for at least `reserveAssetAmount_` of the reserve pool's
  /// underlying asset.
  function depositReserveAssets(
    ISafetyModule safetyModule_,
    uint8 reservePoolId_,
    uint256 reserveAssetAmount_,
    address receiver_
  ) public payable returns (uint256 depositReceiptTokenAmount_) {
    IERC20 asset_ = safetyModule_.reservePools(reservePoolId_).asset;
    asset_.safeTransferFrom(msg.sender, address(safetyModule_), reserveAssetAmount_);

    depositReceiptTokenAmount_ =
      depositReserveAssetsWithoutTransfer(safetyModule_, reservePoolId_, reserveAssetAmount_, receiver_);
  }

  /// @notice Deposits assets into a `rewardsManager_` reward pool. Mints `depositReceiptTokenAmount_` to `receiver_`
  /// by depositing exactly `rewardAssetAmount_` of the reward pool's underlying tokens into the `rewardsManager_`.
  /// The specified amount of assets are transferred from the caller to the `rewardsManager_`.
  /// @dev This will revert if the router is not approved for at least `rewardAssetAmount_` of the reward pool's
  /// underlying asset.
  function depositRewardAssets(
    IRewardsManager rewardsManager_,
    uint16 rewardPoolId_,
    uint256 rewardAssetAmount_,
    address receiver_
  ) external payable returns (uint256 depositReceiptTokenAmount_) {
    IERC20 asset_ = rewardsManager_.rewardPools(rewardPoolId_).asset;
    asset_.safeTransferFrom(msg.sender, address(rewardsManager_), rewardAssetAmount_);

    depositReceiptTokenAmount_ =
      depositRewardAssetsWithoutTransfer(rewardsManager_, rewardPoolId_, rewardAssetAmount_, receiver_);
  }

  /// @notice Executes a deposit into `safetyModule_` in the reserve pool corresponding to `reservePoolId_`, sending
  /// the resulting deposit tokens to `receiver_`. This method does not transfer the assets to the Safety Module which
  /// are necessary for the deposit, thus the caller should ensure that a transfer to the Safety Module with the
  /// needed amount of assets (`reserveAssetAmount_`) of the reserve pool's underlying asset (viewable with
  /// `safetyModule.reservePools(reservePoolId_)`) is transferred to the Safety Module before calling this method.
  /// In general, prefer using `CozyRouter.depositReserveAssets` to deposit into a Safety Module reserve pool, this
  /// method is here to facilitate MultiCall transactions.
  function depositReserveAssetsWithoutTransfer(
    ISafetyModule safetyModule_,
    uint8 reservePoolId_,
    uint256 reserveAssetAmount_,
    address receiver_
  ) public payable returns (uint256 depositReceiptTokenAmount_) {
    _assertAddressNotZero(receiver_);
    depositReceiptTokenAmount_ =
      safetyModule_.depositReserveAssetsWithoutTransfer(reservePoolId_, reserveAssetAmount_, receiver_);
  }

  /// @notice Executes a deposit into `rewardsManager_` in the reward pool corresponding to `rewardPoolId_`,
  /// sending the resulting deposit tokens to `receiver_`. This method does not transfer the assets to the Rewards
  /// Manager which are necessary for the deposit, thus the caller should ensure that a transfer to the Rewards Manager
  /// with the needed amount of assets (`rewardAssetAmount_`) of the reward pool's underlying asset (viewable with
  /// `rewardsManager.rewardPools(rewardPoolId_)`) is transferred to the Rewards Manager before calling this
  /// method. In general, prefer using `CozyRouter.depositRewardAssets` to deposit into a Rewards Manager reward pool,
  /// this method is here to facilitate MultiCall transactions.
  function depositRewardAssetsWithoutTransfer(
    IRewardsManager rewardsManager_,
    uint16 rewardPoolId_,
    uint256 rewardAssetAmount_,
    address receiver_
  ) public payable returns (uint256 depositReceiptTokenAmount_) {
    _assertAddressNotZero(receiver_);
    depositReceiptTokenAmount_ =
      rewardsManager_.depositRewardAssetsWithoutTransfer(rewardPoolId_, rewardAssetAmount_, receiver_);
  }

  /// @notice Deposits assets into a `safetyModule_` reserve pool and stakes the resulting deposit tokens into a
  /// `rewardsManager_` stake pool.
  /// @dev This method is a convenience method that combines `depositReserveAssets` and `stakeWithoutTransfer`.
  /// @dev This will revert if the router is not approved for at least `reserveAssetAmount_` of the reserve pool's
  /// underlying asset.
  function depositReserveAssetsAndStake(
    ISafetyModule safetyModule_,
    IRewardsManager rewardsManager_,
    uint8 reservePoolId_,
    uint16 stakePoolId_,
    uint256 reserveAssetAmount_,
    address receiver_
  ) external payable returns (uint256 receiptTokenAmount_) {
    // The stake receipt token amount received from staking is 1:1 with the amount of Safety Module receipt tokens
    // received from depositing into reserves.
    receiptTokenAmount_ =
      depositReserveAssets(safetyModule_, reservePoolId_, reserveAssetAmount_, address(rewardsManager_));
    stakeWithoutTransfer(rewardsManager_, stakePoolId_, receiptTokenAmount_, receiver_);
  }

  /// @notice Deposits assets into a `safetyModule_` reserve pool and stakes the resulting deposit tokens into a
  /// `rewardsManager_` stake pool.
  /// @dev This method is a convenience method that combines `depositReserveAssetsWithoutTransfer` and
  /// `stakeWithoutTransfer`. Useful in cases where the SM asset is wrapped + transferred to the SM beforehand via
  /// aggregate call, e.g. with CozyRouter.wrapNativeToken.
  function depositReserveAssetsWithoutTransferAndStake(
    ISafetyModule safetyModule_,
    IRewardsManager rewardsManager_,
    uint8 reservePoolId_,
    uint16 stakePoolId_,
    uint256 reserveAssetAmount_,
    address receiver_
  ) external payable returns (uint256 receiptTokenAmount_) {
    // The stake receipt token amount received from staking is 1:1 with the amount of Safety Module receipt tokens
    // received from depositing into reserves.
    receiptTokenAmount_ =
      depositReserveAssetsWithoutTransfer(safetyModule_, reservePoolId_, reserveAssetAmount_, address(rewardsManager_));
    stakeWithoutTransfer(rewardsManager_, stakePoolId_, receiptTokenAmount_, receiver_);
  }

  /// @notice Deposits assets into a `safetyModule_` reserve pool via a connector and stakes the resulting deposit
  /// tokens into a `rewardsManager_` stake pool.
  /// @dev This method is a convenience method that combines `wrapBaseAssetViaConnectorAndDepositReserveAssets` and
  /// `stakeWithoutTransfer`.
  /// @dev This will revert if the router is not approved for at least `baseAssetAmount_` of the base asset.
  function depositReserveAssetsViaConnectorAndStake(
    IConnector connector_,
    ISafetyModule safetyModule_,
    IRewardsManager rewardsManager_,
    uint8 reservePoolId_,
    uint16 stakePoolId_,
    uint256 baseAssetAmount_,
    address receiver_
  ) external payable returns (uint256 receiptTokenAmount_) {
    // The stake receipt token amount received from staking is 1:1 with the amount of Safety Module receipt tokens
    // received from depositing into reserves.
    receiptTokenAmount_ = wrapBaseAssetViaConnectorAndDepositReserveAssets(
      connector_, safetyModule_, reservePoolId_, baseAssetAmount_, address(rewardsManager_)
    );
    stakeWithoutTransfer(rewardsManager_, stakePoolId_, receiptTokenAmount_, receiver_);
  }

  /// @notice Stakes assets into the `rewardsManager_`. Mints `stakeTokenAmount_` to `receiver_` by staking exactly
  /// `stakeAssetAmount_` of the stake pool's underlying tokens into the `rewardsManager_`. The specified amount of
  /// assets are transferred from the caller to the `rewardsManager_`.
  /// @dev This will revert if the router is not approved for at least `stakeAssetAmount_` of the stake pool's
  /// underlying asset.
  /// @dev The amount of stake receipt tokens received are 1:1 with `stakeAssetAmount_`.
  function stake(IRewardsManager rewardsManager_, uint16 stakePoolId_, uint256 stakeAssetAmount_, address receiver_)
    external
    payable
  {
    _assertAddressNotZero(receiver_);
    IERC20 asset_ = rewardsManager_.stakePools(stakePoolId_).asset;
    asset_.safeTransferFrom(msg.sender, address(rewardsManager_), stakeAssetAmount_);

    stakeWithoutTransfer(rewardsManager_, stakePoolId_, stakeAssetAmount_, receiver_);
  }

  /// @notice Executes a stake against `rewardsManager_` in the stake pool corresponding to `stakePoolId_`, sending
  /// the resulting stake tokens to `receiver_`. This method does not transfer the assets to the Rewards Manager which
  /// are necessary for the stake, thus the caller should ensure that a transfer to the Rewards Manager with the
  /// needed amount of assets (`stakeAssetAmount_`) of the stake pool's underlying asset (viewable with
  /// `rewardsManager.stakePools(stakePoolId_)`) is transferred to the Rewards Manager before calling this method.
  /// In general, prefer using `CozyRouter.stake` to stake into a Rewards Manager, this method is here to facilitate
  /// MultiCall transactions.
  /// @dev The amount of stake receipt tokens received are 1:1 with `stakeAssetAmount_`.
  function stakeWithoutTransfer(
    IRewardsManager rewardsManager_,
    uint16 stakePoolId_,
    uint256 stakeAssetAmount_,
    address receiver_
  ) public payable {
    _assertAddressNotZero(receiver_);
    rewardsManager_.stakeWithoutTransfer(stakePoolId_, stakeAssetAmount_, receiver_);
  }

  /// @notice Calls the connector to wrap the base asset, send the wrapped assets to `safetyModule_`, and then
  /// `depositReserveAssetsWithoutTransfer`.
  /// @dev This will revert if the router is not approved for at least `baseAssetAmount_` of the base asset.
  function wrapBaseAssetViaConnectorAndDepositReserveAssets(
    IConnector connector_,
    ISafetyModule safetyModule_,
    uint8 reservePoolId_,
    uint256 baseAssetAmount_,
    address receiver_
  ) public payable returns (uint256 depositReceiptTokenAmount_) {
    uint256 depositAssetAmount_ = _wrapBaseAssetViaConnector(connector_, address(safetyModule_), baseAssetAmount_);
    depositReceiptTokenAmount_ =
      depositReserveAssetsWithoutTransfer(safetyModule_, reservePoolId_, depositAssetAmount_, receiver_);
  }

  /// @notice Calls the connector to wrap the base asset, send the wrapped assets to `rewardsManager_`, and then
  /// `depositRewardAssetsWithoutTransfer`.
  /// @dev This will revert if the router is not approved for at least `baseAssetAmount_` of the base asset.
  function wrapBaseAssetViaConnectorAndDepositRewardAssets(
    IConnector connector_,
    IRewardsManager rewardsManager_,
    uint8 reservePoolId_,
    uint256 baseAssetAmount_,
    address receiver_
  ) external payable returns (uint256 depositReceiptTokenAmount_) {
    uint256 depositAssetAmount_ = _wrapBaseAssetViaConnector(connector_, address(rewardsManager_), baseAssetAmount_);
    depositReceiptTokenAmount_ =
      depositRewardAssetsWithoutTransfer(rewardsManager_, reservePoolId_, depositAssetAmount_, receiver_);
  }

  // --------------------------------------
  // -------- Withdrawal / Unstake --------
  // --------------------------------------

  /// @notice Removes assets from a `safetyModule_` reserve pool. Burns `depositReceiptTokenAmount_` from caller and
  /// sends exactly `reserveAssetAmount_` of the reserve pool's underlying tokens to the `receiver_`. If the safety
  /// module is PAUSED, withdrawal can be completed immediately, otherwise this queues a redemption which can be
  /// completed once sufficient delay has elapsed.
  function withdrawReservePoolAssets(
    ISafetyModule safetyModule_,
    uint8 reservePoolId_,
    uint256 reserveAssetAmount_,
    address receiver_
  ) external payable returns (uint64 redemptionId_, uint256 depositReceiptTokenAmount_) {
    _assertAddressNotZero(receiver_);
    depositReceiptTokenAmount_ = safetyModule_.convertToReceiptTokenAmount(reservePoolId_, reserveAssetAmount_);
    // Caller must first approve the CozyRouter to spend the deposit tokens.
    (redemptionId_,) = safetyModule_.redeem(reservePoolId_, depositReceiptTokenAmount_, receiver_, msg.sender);
  }

  /// @notice Removes assets from a `safetyModule_` reserve pool. Burns `depositReceiptTokenAmount_` from caller and
  /// sends exactly `reserveAssetAmount_` of the reserve pool's underlying tokens to the `receiver_`. If the safety
  /// module is PAUSED, withdrawal can be completed immediately, otherwise this queues a redemption which can be
  /// completed once sufficient delay has elapsed.
  function redeemReservePoolDepositReceiptTokens(
    ISafetyModule safetyModule_,
    uint8 reservePoolId_,
    uint256 depositReceiptTokenAmount_,
    address receiver_
  ) external payable returns (uint64 redemptionId_, uint256 assetsReceived_) {
    _assertAddressNotZero(receiver_);
    // Caller must first approve the CozyRouter to spend the deposit tokens.
    (redemptionId_, assetsReceived_) =
      safetyModule_.redeem(reservePoolId_, depositReceiptTokenAmount_, receiver_, msg.sender);
  }

  /// @notice Removes assets from a `rewardsManager_` reward pool. Burns `depositReceiptTokenAmount_` from caller and
  /// sends exactly `rewardAssetAmount_` of the reward pool's underlying tokens to the `receiver_`. Withdrawal of
  /// undripped assets from reward pools can be completed instantly.
  function withdrawRewardPoolAssets(
    IRewardsManager rewardsManager_,
    uint8 rewardPoolId_,
    uint256 rewardAssetAmount_,
    address receiver_
  ) external payable returns (uint256 depositReceiptTokenAmount_) {
    _assertAddressNotZero(receiver_);
    depositReceiptTokenAmount_ =
      rewardsManager_.convertRewardAssetToReceiptTokenAmount(rewardPoolId_, rewardAssetAmount_);
    // Caller must first approve the CozyRouter to spend the deposit receipt tokens.
    rewardsManager_.redeemUndrippedRewards(rewardPoolId_, depositReceiptTokenAmount_, receiver_, msg.sender);
  }

  // @notice Removes assets from a `rewardsManager_` reward pool. Burns `depositReceiptTokenAmount_` from caller and
  /// sends exactly `rewardAssetAmount_` of the reward pool's underlying tokens to the `receiver_`. Withdrawal of
  /// undripped assets from reward pools can be completed instantly.
  function redeemRewardPoolDepositReceiptTokens(
    IRewardsManager rewardsManager_,
    uint16 rewardPoolId_,
    uint256 depositReceiptTokenAmount_,
    address receiver_
  ) external payable returns (uint256 assetsReceived_) {
    _assertAddressNotZero(receiver_);
    // Caller must first approve the CozyRouter to spend the deposit receipt tokens.
    assetsReceived_ =
      rewardsManager_.redeemUndrippedRewards(rewardPoolId_, depositReceiptTokenAmount_, receiver_, msg.sender);
  }

  /// @notice Unstakes exactly `stakeReceiptTokenAmount` from a `rewardsManager_` stake pool. Burns
  /// `stakeReceiptTokenAmount` from caller and sends the same amount of the stake pool's underlying
  /// tokens to the `receiver_`. This also claims any outstanding rewards that the user is entitled to for the stake
  /// pool.
  /// @dev Caller must first approve the CozyRouter to spend the stake tokens.
  /// @dev The amount of underlying assets received are 1:1 with `stakeReceiptTokenAmount_`.
  function unstake(
    IRewardsManager rewardsManager_,
    uint16 stakePoolId_,
    uint256 stakeReceiptTokenAmount,
    address receiver_
  ) public payable {
    _assertAddressNotZero(receiver_);
    // Exchange rate between rewards manager stake tokens and safety module deposit receipt tokens is 1:1.
    rewardsManager_.unstake(stakePoolId_, stakeReceiptTokenAmount, receiver_, msg.sender);
  }

  /// @notice Burns `rewardsManager_` stake tokens for `stakePoolId_` stake pool from caller and sends exactly
  /// `reserveAssetAmount_` of `safetyModule_` `reservePoolId_` reserve pool's underlying tokens to the `receiver_`,
  /// and reverts if less than `minAssetsReceived_` of the reserve pool asset would be received.
  /// If the safety module is PAUSED, unstake can be completed immediately, otherwise this
  /// queues a redemption which can be completed once sufficient delay has elapsed. This also claims any outstanding
  /// rewards that the user is entitled to.
  /// @dev Caller must first approve the CozyRouter to spend the rewards manager stake tokens.
  function unstakeReserveAssetsAndWithdraw(
    ISafetyModule safetyModule_,
    IRewardsManager rewardsManager_,
    uint8 reservePoolId_,
    uint16 stakePoolId_,
    uint256 reserveAssetAmount_,
    address receiver_
  ) external payable returns (uint64 redemptionId_, uint256 stakeReceiptTokenAmount_) {
    _assertAddressNotZero(receiver_);
    // Exchange rate between rewards manager stake tokens and safety module deposit receipt tokens is 1:1.
    stakeReceiptTokenAmount_ = safetyModule_.convertToReceiptTokenAmount(reservePoolId_, reserveAssetAmount_);

    // The stake receipt tokens are transferred to this router because RewardsManager.claimRewards must be called by
    // the owner of the stake receipt tokens.
    _transferStakeTokensAndClaimRewards(rewardsManager_, stakePoolId_, stakeReceiptTokenAmount_, receiver_);

    rewardsManager_.unstake(stakePoolId_, stakeReceiptTokenAmount_, address(this), address(this));
    (redemptionId_,) = safetyModule_.redeem(reservePoolId_, stakeReceiptTokenAmount_, receiver_, address(this));
  }

  /// @notice Unstakes exactly `stakeReceiptTokenAmount_` of stake receipt tokens from a
  /// `rewardsManager_` stake pool. Burns `rewardsManager` stake tokens for `stakePoolId_`, `safetyModule_`
  /// deposit receipt tokens for `reservePoolId_`, and redeems exactly `reserveAssetAmount_` of the `safetyModule_`
  /// reserve pool's underlying tokens to the `receiver_`. If the safety module is PAUSED, withdrawal/redemption
  /// can be completed immediately, otherwise this queues  a redemption which can be completed once sufficient delay
  /// has elapsed. This also claims any outstanding rewards that the user is entitled to for the stake pool.
  /// @dev Caller must first approve the CozyRouter to spend the rewards manager stake tokens.
  function unstakeStakeReceiptTokensAndRedeem(
    ISafetyModule safetyModule_,
    IRewardsManager rewardsManager_,
    uint8 reservePoolId_,
    uint16 stakePoolId_,
    uint256 stakeReceiptTokenAmount_,
    address receiver_
  ) external payable returns (uint64 redemptionId_, uint256 reserveAssetAmount_) {
    _assertAddressNotZero(receiver_);

    // The stake receipt tokens are transferred to this router because RewardsManager.claimRewards must be called by
    // the owner of the stake receipt tokens.
    _transferStakeTokensAndClaimRewards(rewardsManager_, stakePoolId_, stakeReceiptTokenAmount_, receiver_);

    rewardsManager_.unstake(stakePoolId_, stakeReceiptTokenAmount_, address(this), address(this));

    // // Exchange rate between rewards manager stake tokens and safety module deposit receipt tokens is 1:1.
    (redemptionId_, reserveAssetAmount_) =
      safetyModule_.redeem(reservePoolId_, stakeReceiptTokenAmount_, receiver_, address(this));
  }

  /// @notice Completes the redemption corresponding to `id_` in `safetyModule_`.
  function completeWithdraw(ISafetyModule safetyModule_, uint64 id_) external payable {
    safetyModule_.completeRedemption(id_);
  }

  /// @notice Completes the redemption corresponding to `id_` in `safetyModule_`.
  function completeRedemption(ISafetyModule safetyModule_, uint64 id_) external payable {
    safetyModule_.completeRedemption(id_);
  }

  /// @notice Calls the connector to unwrap the wrapped assets and transfer base assets back to `receiver_`.
  /// @dev This assumes that all assets that need to be withdrawn are sitting in the connector. It expects the
  /// integrator has called `CozyRouter.withdraw/redeem/unstake` with `receiver_ == address(connector_)`.
  /// @dev This function should be `aggregate` called with `completeWithdraw/Redeem/Unstake`, or
  /// `withdraw/redeem/unstake`. It can be called with withdraw/redeem/unstake in the case that instant
  /// withdrawals can occur due to the safety module being PAUSED.
  function unwrapWrappedAssetViaConnectorForWithdraw(IConnector connector_, address receiver_) external payable {
    uint256 assets_ = connector_.balanceOf(address(connector_));
    if (assets_ > 0) connector_.unwrapWrappedAsset(receiver_, assets_);
  }

  /// @notice Calls the connector to unwrap the wrapped assets and transfer base assets back to `receiver_`.
  /// @dev This assumes that `assets_` amount of the wrapped assets are sitting in the connector. So, it expects
  /// the integrator has called a safety module operation such as withdraw with `receiver_ ==
  /// address(connector_)`.
  function unwrapWrappedAssetViaConnector(IConnector connector_, uint256 assets_, address receiver_) external payable {
    if (assets_ > 0) connector_.unwrapWrappedAsset(receiver_, assets_);
  }

  // ----------------------------------
  // -------- Internal helpers --------
  // ----------------------------------

  function _wrapBaseAssetViaConnector(IConnector connector_, address receiver_, uint256 baseAssetAmount_)
    internal
    returns (uint256 depositAssetAmount_)
  {
    connector_.baseAsset().safeTransferFrom(msg.sender, address(connector_), baseAssetAmount_);
    depositAssetAmount_ = connector_.wrapBaseAsset(receiver_, baseAssetAmount_);
  }

  /// @dev Caller must first approve the CozyRouter to spend the stake tokens.
  function _transferStakeTokensAndClaimRewards(
    IRewardsManager rewardsManager_,
    uint16 stakePoolId_,
    uint256 stakeReceiptTokenAmount_,
    address receiver_
  ) internal {
    IERC20(rewardsManager_.stakePools(stakePoolId_).stkReceiptToken).safeTransferFrom(
      msg.sender, address(this), stakeReceiptTokenAmount_
    );
    rewardsManager_.claimRewards(stakePoolId_, receiver_);
  }
}

// src/lib/router/WethTokenHelpers.sol

abstract contract WethTokenHelpers is TokenHelpers {
  using Address for address;
  using SafeERC20 for IERC20;

  /// @notice The address that conforms to the IWETH9 interface.
  IWeth public immutable wrappedNativeToken;

  constructor(IWeth weth_) {
    _assertAddressNotZero(address(weth_));
    wrappedNativeToken = weth_;
  }

  /// @notice Wraps all native tokens held by this contact into the wrapped native token and sends them to the
  /// `receiver_`.
  /// @dev This function should be `aggregate` called with deposit or stake without transfer functions.
  function wrapNativeToken(address receiver_) external payable {
    uint256 amount_ = address(this).balance;
    wrappedNativeToken.deposit{value: amount_}();
    IERC20(address(wrappedNativeToken)).safeTransfer(receiver_, amount_);
  }

  /// @notice Wraps the specified `amount_` of native tokens from this contact into wrapped native tokens and sends them
  /// to the `receiver_`.
  /// @dev This function should be `aggregate` called with deposit or stake without transfer functions.
  function wrapNativeToken(address receiver_, uint256 amount_) external payable {
    // Using msg.value in a multicall is dangerous, so we avoid it.
    if (address(this).balance < amount_) revert InsufficientBalance();
    wrappedNativeToken.deposit{value: amount_}();
    IERC20(address(wrappedNativeToken)).safeTransfer(receiver_, amount_);
  }

  /// @notice Unwraps all wrapped native tokens held by this contact and sends native tokens to the `recipient_`.
  /// @dev Reentrancy is possible here, but this router is stateless and therefore a reentrant call is not harmful.
  /// @dev This function should be `aggregate` called with `completeRedeem/completeWithdraw/completeUnstake`. This
  /// should also be called with withdraw/redeem/unstake functions in the case that instant withdrawals/redemptions
  /// can occur due to the safety module being PAUSED.
  function unwrapNativeToken(address recipient_) external payable {
    _assertAddressNotZero(recipient_);
    uint256 amount_ = wrappedNativeToken.balanceOf(address(this));
    wrappedNativeToken.withdraw(amount_);
    // Enables reentrancy, but this is a stateless router so it's ok.
    Address.sendValue(payable(recipient_), amount_);
  }

  /// @notice Unwraps the specified `amount_` of wrapped native tokens held by this contact and sends native tokens to
  /// the `recipient_`.
  /// @dev Reentrancy is possible here, but this router is stateless and therefore a reentrant call is not harmful.
  /// @dev This function should be `aggregate` called with `completeRedeem/completeWithdraw/completeUnstake`. This
  /// should also be called with withdraw/redeem/unstake functions in the case that instant withdrawals/redemptions
  /// can occur due to the safety module being PAUSED.
  function unwrapNativeToken(address recipient_, uint256 amount_) external payable {
    _assertAddressNotZero(recipient_);
    if (wrappedNativeToken.balanceOf(address(this)) < amount_) revert InsufficientBalance();
    wrappedNativeToken.withdraw(amount_);
    // Enables reentrancy, but this is a stateless router so it's ok.
    Address.sendValue(payable(recipient_), amount_);
  }
}

// src/lib/router/StEthTokenHelpers.sol

abstract contract StEthTokenHelpers is TokenHelpers {
  using Address for address;
  using SafeERC20 for IERC20;

  /// @notice Staked ETH address.
  IStETH public immutable stEth;

  /// @notice Wrapped staked ETH address.
  IWstETH public immutable wstEth;

  constructor(IStETH stEth_, IWstETH wstEth_) {
    // The addresses for stEth and wstEth can be 0 in our current deployment setup
    stEth = stEth_;
    wstEth = wstEth_;

    if (address(stEth) != address(0)) IERC20(address(stEth)).safeIncreaseAllowance(address(wstEth), type(uint256).max);
  }

  /// @notice Wraps caller's entire balance of stETH as wstETH and transfers to `receiver_`.
  /// Requires pre-approval of the router to transfer the caller's stETH.
  /// @dev This function should be `aggregate` called with deposit or stake without transfer functions.
  function wrapStEth(address receiver_) external {
    wrapStEth(receiver_, stEth.balanceOf(msg.sender));
  }

  /// @notice Wraps `amount_` of stETH as wstETH and transfers to `receiver_`.
  /// Requires pre-approval of the router to transfer the caller's stETH.
  /// @dev This function should be `aggregate` called with deposit or stake without transfer functions.
  function wrapStEth(address receiver_, uint256 amount_) public {
    IERC20(address(stEth)).safeTransferFrom(msg.sender, address(this), amount_);
    uint256 wstEthAmount_ = wstEth.wrap(stEth.balanceOf(address(this)));
    IERC20(address(wstEth)).safeTransfer(receiver_, wstEthAmount_);
  }

  /// @notice Unwraps router's balance of wstETH into stETH and transfers to `recipient_`.
  /// @dev This function should be `aggregate` called with `completeRedeem/completeWithdraw/completeUnstake`. This
  /// should also be called with withdraw/redeem/unstake functions in the case that instant withdrawals/redemptions
  /// can occur due to the safety module being PAUSED.
  function unwrapStEth(address recipient_) external {
    _assertAddressNotZero(recipient_);
    uint256 stEthAmount_ = wstEth.unwrap(wstEth.balanceOf(address(this)));
    IERC20(address(stEth)).safeTransfer(recipient_, stEthAmount_);
  }
}

// src/lib/router/TriggerDeploymentHelpers.sol

abstract contract TriggerDeploymentHelpers is CozyRouterCommon {
  using SafeERC20 for IERC20;

  IChainlinkTriggerFactory public immutable chainlinkTriggerFactory;

  IOwnableTriggerFactory public immutable ownableTriggerFactory;

  IUMATriggerFactory public immutable umaTriggerFactory;

  constructor(TriggerFactories memory triggerFactories_) {
    chainlinkTriggerFactory = triggerFactories_.chainlinkTriggerFactory;
    ownableTriggerFactory = triggerFactories_.ownableTriggerFactory;
    umaTriggerFactory = triggerFactories_.umaTriggerFactory;
  }

  /// @notice Deploys a new ChainlinkTrigger.
  /// @param truthOracle_ The address of the desired truthOracle for the trigger.
  /// @param trackingOracle_ The address of the desired trackingOracle for the trigger.
  /// @param priceTolerance_ The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param truthFrequencyTolerance_ The frequency tolerance that the deployed trigger will
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param trackingFrequencyTolerance_ The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  /// @param metadata_ See TriggerMetadata for more info.
  function deployChainlinkTrigger(
    AggregatorV3Interface truthOracle_,
    AggregatorV3Interface trackingOracle_,
    uint256 priceTolerance_,
    uint256 truthFrequencyTolerance_,
    uint256 trackingFrequencyTolerance_,
    TriggerMetadata memory metadata_
  ) external payable returns (ITrigger trigger_) {
    trigger_ = chainlinkTriggerFactory.deployTrigger(
      truthOracle_, trackingOracle_, priceTolerance_, truthFrequencyTolerance_, trackingFrequencyTolerance_, metadata_
    );
  }

  /// @notice Deploys a new ChainlinkTrigger with a FixedPriceAggregator as its truthOracle. This is useful if you were
  /// configurating a safety module in which you wanted to track whether or not a stablecoin asset had become depegged.
  /// @param price_ The fixed price, or peg, with which to compare the trackingOracle price.
  /// @param decimals_ The number of decimals of the fixed price. This should
  /// match the number of decimals used by the desired _trackingOracle.
  /// @param trackingOracle_ The address of the desired trackingOracle for the trigger.
  /// @param priceTolerance_ The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param frequencyTolerance_ The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  /// @param metadata_ See TriggerMetadata for more info.
  function deployChainlinkFixedPriceTrigger(
    int256 price_,
    uint8 decimals_,
    AggregatorV3Interface trackingOracle_,
    uint256 priceTolerance_,
    uint256 frequencyTolerance_,
    TriggerMetadata memory metadata_
  ) external payable returns (ITrigger trigger_) {
    trigger_ = chainlinkTriggerFactory.deployTrigger(
      price_, decimals_, trackingOracle_, priceTolerance_, frequencyTolerance_, metadata_
    );
  }

  /// @notice Deploys a new OwnableTrigger.
  /// @param owner_ The owner of the trigger.
  /// @param metadata_ See TriggerMetadata for more info.
  /// @param salt_ The salt used to derive the trigger's address.
  function deployOwnableTrigger(address owner_, TriggerMetadata memory metadata_, bytes32 salt_)
    external
    payable
    returns (ITrigger trigger_)
  {
    trigger_ = ownableTriggerFactory.deployTrigger(owner_, metadata_, computeSalt(msg.sender, salt_));
  }

  /// @notice Deploys a new UMATrigger.
  /// @dev Be sure to approve the CozyRouter to spend the `rewardAmount_` before calling
  /// `deployUMATrigger`, otherwise the latter will revert. Funds need to be available
  /// to the created trigger within its constructor so that it can submit its query
  /// to the UMA oracle.
  /// @param query_ The query that the trigger will send to the UMA Optimistic
  /// Oracle for evaluation.
  /// @param rewardToken_ The token used to pay the reward to users that propose
  /// answers to the query. The reward token must be approved by UMA governance.
  /// Approved tokens can be found with the UMA AddressWhitelist contract on each
  /// chain supported by UMA.
  /// @param rewardAmount_ The amount of rewardToken that will be paid as a
  /// reward to anyone who proposes an answer to the query.
  /// @param refundRecipient_ Default address that will recieve any leftover
  /// rewards at UMA query settlement time.
  /// @param bondAmount_ The amount of `rewardToken` that must be staked by a
  /// user wanting to propose or dispute an answer to the query. See UMA's price
  /// dispute workflow for more information. It's recommended that the bond
  /// amount be a significant value to deter addresses from proposing malicious,
  /// false, or otherwise self-interested answers to the query.
  /// @param proposalDisputeWindow_ The window of time in seconds within which a
  /// proposed answer may be disputed. See UMA's "customLiveness" setting for
  /// more information. It's recommended that the dispute window be fairly long
  /// (12-24 hours), given the difficulty of assessing expected queries (e.g.
  /// "Was protocol ABCD hacked") and the amount of funds potentially at stake.
  /// @param metadata_ See TriggerMetadata for more info.
  function deployUMATrigger(
    string memory query_,
    IERC20 rewardToken_,
    uint256 rewardAmount_,
    address refundRecipient_,
    uint256 bondAmount_,
    uint256 proposalDisputeWindow_,
    TriggerMetadata memory metadata_
  ) external payable returns (ITrigger trigger_) {
    // UMATriggerFactory.deployTrigger uses safeTransferFrom to transfer rewardToken_ from caller.
    // In the context of deployTrigger below, msg.sender is this CozyRouter, so the funds must first be transferred
    // here.
    rewardToken_.safeTransferFrom(msg.sender, address(this), rewardAmount_);
    rewardToken_.approve(address(umaTriggerFactory), rewardAmount_);
    trigger_ = umaTriggerFactory.deployTrigger(
      query_, rewardToken_, rewardAmount_, refundRecipient_, bondAmount_, proposalDisputeWindow_, metadata_
    );
  }
}

// src/CozyRouter.sol

contract CozyRouter is
  CozyRouterCommon,
  SafetyModuleDeploymentHelpers,
  RewardsManagerDeploymentHelpers,
  DripModelDeploymentHelpers,
  SafetyModuleActions,
  StEthTokenHelpers,
  WethTokenHelpers,
  TriggerDeploymentHelpers
{
  /// @dev Thrown when a call in `aggregate` fails, contains the index of the call and the data it returned.
  error CallFailed(uint256 index, bytes returnData);

  constructor(
    ICozySafetyModuleManager safetyModuleCozyManager_,
    ICozyManager rewardsManagerCozyManager_,
    IWeth weth_,
    IStETH stEth_,
    IWstETH wstEth_,
    TriggerFactories memory triggerFactories_,
    IDripModelConstantFactory dripModelConstantFactory_
  )
    CozyRouterCommon(safetyModuleCozyManager_)
    StEthTokenHelpers(stEth_, wstEth_)
    WethTokenHelpers(weth_)
    DripModelDeploymentHelpers(dripModelConstantFactory_)
    RewardsManagerDeploymentHelpers(rewardsManagerCozyManager_)
    TriggerDeploymentHelpers(triggerFactories_)
  {}

  receive() external payable {}

  // ---------------------------
  // -------- Multicall --------
  // ---------------------------

  /// @notice Enables batching of multiple router calls into a single transaction.
  /// @dev All methods in this contract must be payable to support sending ETH with a batch call.
  /// @param calls_ Array of ABI encoded calls to be performed.
  function aggregate(bytes[] calldata calls_) external payable returns (bytes[] memory returnData_) {
    returnData_ = new bytes[](calls_.length);

    for (uint256 i = 0; i < calls_.length; i++) {
      (bool success_, bytes memory response_) = address(this).delegatecall(calls_[i]);
      if (!success_) revert CallFailed(i, response_);
      returnData_[i] = response_;
    }
  }
}