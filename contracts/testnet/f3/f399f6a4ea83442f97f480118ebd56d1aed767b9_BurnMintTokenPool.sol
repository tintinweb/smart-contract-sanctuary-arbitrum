// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IBurnMintERC20} from "../../shared/token/ERC20/IBurnMintERC20.sol";

import {TokenPool} from "./TokenPool.sol";

/// @notice This pool mints and burns a 3rd-party token.
/// @dev Pool whitelisting mode is set in the constructor and cannot be modified later.
/// It either accepts any address as originalSender, or only accepts whitelisted originalSender.
/// The only way to change whitelisting mode is to deploy a new pool.
/// If that is expected, please make sure the token's burner/minter roles are adjustable.
contract BurnMintTokenPool is TokenPool {
  constructor(
    IBurnMintERC20 token,
    address[] memory allowlist,
    address armProxy
  ) TokenPool(token, allowlist, armProxy) {}

  /// @notice Burn the token in the pool
  /// @dev Burn is not rate limited at per-pool level. Burn does not contribute to honey pot risk.
  /// Benefits of rate limiting here does not justify the extra gas cost.
  /// @param amount Amount to burn
  function lockOrBurn(
    address originalSender,
    bytes calldata,
    uint256 amount,
    uint64,
    bytes calldata
  ) external override onlyOnRamp checkAllowList(originalSender) whenHealthy returns (bytes memory) {
    _consumeOnRampRateLimit(amount);
    IBurnMintERC20(address(i_token)).burn(amount);
    emit Burned(msg.sender, amount);
    return "";
  }

  /// @notice Mint tokens from the pool to the recipient
  /// @param receiver Recipient address
  /// @param amount Amount to mint
  function releaseOrMint(
    bytes memory,
    address receiver,
    uint256 amount,
    uint64,
    bytes memory
  ) external virtual override whenHealthy onlyOffRamp {
    _consumeOffRampRateLimit(amount);
    IBurnMintERC20(address(i_token)).mint(receiver, amount);
    emit Minted(msg.sender, receiver, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../../../vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";

interface IBurnMintERC20 is IERC20 {
  /// @notice Mints new tokens for a given address.
  /// @param account The address to mint the new tokens to.
  /// @param amount The number of tokens to be minted.
  /// @dev this function increases the total supply.
  function mint(address account, uint256 amount) external;

  /// @notice Burns tokens from the sender.
  /// @param amount The number of tokens to be burned.
  /// @dev this function decreases the total supply.
  function burn(uint256 amount) external;

  /// @notice Burns tokens from a given address..
  /// @param account The address to burn tokens from.
  /// @param amount The number of tokens to be burned.
  /// @dev this function decreases the total supply.
  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IPool} from "../interfaces/pools/IPool.sol";
import {IARM} from "../interfaces/IARM.sol";

import {OwnerIsCreator} from "../../shared/access/OwnerIsCreator.sol";
import {RateLimiter} from "../libraries/RateLimiter.sol";

import {Pausable} from "../../vendor/Pausable.sol";
import {IERC20} from "../../vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {IERC165} from "../../vendor/openzeppelin-solidity/v4.8.0/utils/introspection/IERC165.sol";
import {EnumerableSet} from "../../vendor/openzeppelin-solidity/v4.8.0/utils/structs/EnumerableSet.sol";

/// @notice Base abstract class with common functions for all token pools.
abstract contract TokenPool is IPool, OwnerIsCreator, IERC165 {
  using EnumerableSet for EnumerableSet.AddressSet;
  using RateLimiter for RateLimiter.TokenBucket;

  error PermissionsError();
  error ZeroAddressNotAllowed();
  error SenderNotAllowed(address sender);
  error AllowListNotEnabled();
  error NonExistentRamp(address ramp);
  error BadARMSignal();
  error RampAlreadyExists(address ramp);

  event Locked(address indexed sender, uint256 amount);
  event Burned(address indexed sender, uint256 amount);
  event Released(address indexed sender, address indexed recipient, uint256 amount);
  event Minted(address indexed sender, address indexed recipient, uint256 amount);
  event OnRampAdded(address onRamp, RateLimiter.Config rateLimiterConfig);
  event OnRampConfigured(address onRamp, RateLimiter.Config rateLimiterConfig);
  event OnRampRemoved(address onRamp);
  event OffRampAdded(address offRamp, RateLimiter.Config rateLimiterConfig);
  event OffRampConfigured(address offRamp, RateLimiter.Config rateLimiterConfig);
  event OffRampRemoved(address offRamp);
  event AllowListAdd(address sender);
  event AllowListRemove(address sender);

  struct RampUpdate {
    address ramp;
    bool allowed;
    RateLimiter.Config rateLimiterConfig;
  }

  // The immutable token that belongs to this pool.
  IERC20 internal immutable i_token;
  address internal immutable i_armProxy;
  // The immutable flag that indicates if the pool is access-controlled.
  bool internal immutable i_allowlistEnabled;
  // A set of addresses allowed to trigger lockOrBurn as original senders.
  EnumerableSet.AddressSet internal s_allowList;

  // A set of allowed onRamps. We want the whitelist to be enumerable to
  // be able to quickly determine (without parsing logs) who can access the pool.
  EnumerableSet.AddressSet internal s_onRamps;
  mapping(address => RateLimiter.TokenBucket) internal s_onRampRateLimits;
  // A set of allowed offRamps.
  EnumerableSet.AddressSet internal s_offRamps;
  mapping(address => RateLimiter.TokenBucket) internal s_offRampRateLimits;

  constructor(IERC20 token, address[] memory allowlist, address armProxy) {
    if (address(token) == address(0)) revert ZeroAddressNotAllowed();
    i_token = token;
    i_armProxy = armProxy;

    // Pool can be set as permissioned or permissionless at deployment time only.
    i_allowlistEnabled = allowlist.length > 0;
    if (i_allowlistEnabled) {
      _applyAllowListUpdates(new address[](0), allowlist);
    }
  }

  /// @notice Get ARM proxy address
  /// @return armProxy Address of arm proxy
  function getArmProxy() public view returns (address armProxy) {
    return i_armProxy;
  }

  /// @inheritdoc IPool
  function getToken() public view override returns (IERC20 token) {
    return i_token;
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    return interfaceId == type(IPool).interfaceId || interfaceId == type(IERC165).interfaceId;
  }

  // ================================================================
  // |                      Ramp permissions                        |
  // ================================================================

  /// @notice Checks whether something is a permissioned onRamp on this contract.
  /// @return true if the given address is a permissioned onRamp.
  function isOnRamp(address onRamp) public view returns (bool) {
    return s_onRamps.contains(onRamp);
  }

  /// @notice Checks whether something is a permissioned offRamp on this contract.
  /// @return true if the given address is a permissioned offRamp.
  function isOffRamp(address offRamp) public view returns (bool) {
    return s_offRamps.contains(offRamp);
  }

  /// @notice Get onRamp whitelist
  /// @return list of onramps.
  function getOnRamps() public view returns (address[] memory) {
    return s_onRamps.values();
  }

  /// @notice Get offRamp whitelist
  /// @return list of offramps
  function getOffRamps() public view returns (address[] memory) {
    return s_offRamps.values();
  }

  /// @notice Sets permissions for all on and offRamps.
  /// @dev Only callable by the owner
  /// @param onRamps A list of onRamps and their new permission status/rate limits
  /// @param offRamps A list of offRamps and their new permission status/rate limits
  function applyRampUpdates(RampUpdate[] calldata onRamps, RampUpdate[] calldata offRamps) external virtual onlyOwner {
    _applyRampUpdates(onRamps, offRamps);
  }

  function _applyRampUpdates(RampUpdate[] calldata onRamps, RampUpdate[] calldata offRamps) internal onlyOwner {
    for (uint256 i = 0; i < onRamps.length; ++i) {
      RampUpdate memory update = onRamps[i];
      if (update.allowed) {
        if (s_onRamps.add(update.ramp)) {
          s_onRampRateLimits[update.ramp] = RateLimiter.TokenBucket({
            rate: update.rateLimiterConfig.rate,
            capacity: update.rateLimiterConfig.capacity,
            tokens: update.rateLimiterConfig.capacity,
            lastUpdated: uint32(block.timestamp),
            isEnabled: update.rateLimiterConfig.isEnabled
          });
          emit OnRampAdded(update.ramp, update.rateLimiterConfig);
        } else {
          revert RampAlreadyExists(update.ramp);
        }
      } else {
        if (s_onRamps.remove(update.ramp)) {
          delete s_onRampRateLimits[update.ramp];
          emit OnRampRemoved(update.ramp);
        } else {
          // Cannot remove a non-existent onRamp.
          revert NonExistentRamp(update.ramp);
        }
      }
    }

    for (uint256 i = 0; i < offRamps.length; ++i) {
      RampUpdate memory update = offRamps[i];
      if (update.allowed) {
        if (s_offRamps.add(update.ramp)) {
          s_offRampRateLimits[update.ramp] = RateLimiter.TokenBucket({
            rate: update.rateLimiterConfig.rate,
            capacity: update.rateLimiterConfig.capacity,
            tokens: update.rateLimiterConfig.capacity,
            lastUpdated: uint32(block.timestamp),
            isEnabled: update.rateLimiterConfig.isEnabled
          });
          emit OffRampAdded(update.ramp, update.rateLimiterConfig);
        } else {
          revert RampAlreadyExists(update.ramp);
        }
      } else {
        if (s_offRamps.remove(update.ramp)) {
          delete s_offRampRateLimits[update.ramp];
          emit OffRampRemoved(update.ramp);
        } else {
          // Cannot remove a non-existent offRamp.
          revert NonExistentRamp(update.ramp);
        }
      }
    }
  }

  // ================================================================
  // |                        Rate limiting                         |
  // ================================================================

  /// @notice Consumes outbound rate limiting capacity in this pool
  function _consumeOnRampRateLimit(uint256 amount) internal {
    s_onRampRateLimits[msg.sender]._consume(amount, address(i_token));
  }

  /// @notice Consumes inbound rate limiting capacity in this pool
  function _consumeOffRampRateLimit(uint256 amount) internal {
    s_offRampRateLimits[msg.sender]._consume(amount, address(i_token));
  }

  /// @notice Gets the token bucket with its values for the block it was requested at.
  /// @return The token bucket.
  function currentOnRampRateLimiterState(address onRamp) external view returns (RateLimiter.TokenBucket memory) {
    return s_onRampRateLimits[onRamp]._currentTokenBucketState();
  }

  /// @notice Gets the token bucket with its values for the block it was requested at.
  /// @return The token bucket.
  function currentOffRampRateLimiterState(address offRamp) external view returns (RateLimiter.TokenBucket memory) {
    return s_offRampRateLimits[offRamp]._currentTokenBucketState();
  }

  /// @notice Sets the onramp rate limited config.
  /// @param config The new rate limiter config.
  function setOnRampRateLimiterConfig(address onRamp, RateLimiter.Config memory config) external onlyOwner {
    if (!isOnRamp(onRamp)) revert NonExistentRamp(onRamp);
    s_onRampRateLimits[onRamp]._setTokenBucketConfig(config);
    emit OnRampConfigured(onRamp, config);
  }

  /// @notice Sets the offramp rate limited config.
  /// @param config The new rate limiter config.
  function setOffRampRateLimiterConfig(address offRamp, RateLimiter.Config memory config) external onlyOwner {
    if (!isOffRamp(offRamp)) revert NonExistentRamp(offRamp);
    s_offRampRateLimits[offRamp]._setTokenBucketConfig(config);
    emit OffRampConfigured(offRamp, config);
  }

  // ================================================================
  // |                           Access                             |
  // ================================================================

  /// @notice Checks whether the msg.sender is a permissioned onRamp on this contract
  /// @dev Reverts with a PermissionsError if check fails
  modifier onlyOnRamp() {
    if (!isOnRamp(msg.sender)) revert PermissionsError();
    _;
  }

  /// @notice Checks whether the msg.sender is a permissioned offRamp on this contract
  /// @dev Reverts with a PermissionsError if check fails
  modifier onlyOffRamp() {
    if (!isOffRamp(msg.sender)) revert PermissionsError();
    _;
  }

  // ================================================================
  // |                          Allowlist                           |
  // ================================================================

  modifier checkAllowList(address sender) {
    if (i_allowlistEnabled && !s_allowList.contains(sender)) revert SenderNotAllowed(sender);
    _;
  }

  /// @notice Gets whether the allowList functionality is enabled.
  /// @return true is enabled, false if not.
  function getAllowListEnabled() external view returns (bool) {
    return i_allowlistEnabled;
  }

  /// @notice Gets the allowed addresses.
  /// @return The allowed addresses.
  function getAllowList() external view returns (address[] memory) {
    return s_allowList.values();
  }

  /// @notice Apply updates to the allow list.
  /// @param removes The addresses to be removed.
  /// @param adds The addresses to be added.
  /// @dev allowListing will be removed before public launch
  function applyAllowListUpdates(address[] calldata removes, address[] calldata adds) external onlyOwner {
    _applyAllowListUpdates(removes, adds);
  }

  /// @notice Internal version of applyAllowListUpdates to allow for reuse in the constructor.
  function _applyAllowListUpdates(address[] memory removes, address[] memory adds) internal {
    if (!i_allowlistEnabled) revert AllowListNotEnabled();

    for (uint256 i = 0; i < removes.length; ++i) {
      address toRemove = removes[i];
      if (s_allowList.remove(toRemove)) {
        emit AllowListRemove(toRemove);
      }
    }
    for (uint256 i = 0; i < adds.length; ++i) {
      address toAdd = adds[i];
      if (toAdd == address(0)) {
        continue;
      }
      if (s_allowList.add(toAdd)) {
        emit AllowListAdd(toAdd);
      }
    }
  }

  /// @notice Ensure that the ARM has not emitted a bad signal, and that the latest heartbeat is not stale.
  modifier whenHealthy() {
    if (IARM(i_armProxy).isCursed()) revert BadARMSignal();
    _;
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
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "../../../vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";

// Shared public interface for multiple pool types.
// Each pool type handles a different child token model (lock/unlock, mint/burn.)
interface IPool {
  /// @notice Lock tokens into the pool or burn the tokens.
  /// @param originalSender Original sender of the tokens.
  /// @param receiver Receiver of the tokens on destination chain.
  /// @param amount Amount to lock or burn.
  /// @param destChainSelector Destination chain Id.
  /// @param extraArgs Additional data passed in by sender for lockOrBurn processing
  /// in custom pools on source chain.
  /// @return retData Optional field that contains bytes. Unused for now but already
  /// implemented to allow future upgrades while preserving the interface.
  function lockOrBurn(
    address originalSender,
    bytes calldata receiver,
    uint256 amount,
    uint64 destChainSelector,
    bytes calldata extraArgs
  ) external returns (bytes memory);

  /// @notice Releases or mints tokens to the receiver address.
  /// @param originalSender Original sender of the tokens.
  /// @param receiver Receiver of the tokens.
  /// @param amount Amount to release or mint.
  /// @param sourceChainSelector Source chain Id.
  /// @param extraData Additional data supplied offchain for releaseOrMint processing in
  /// custom pools on dest chain. This could be an attestation that was retrieved through a
  /// third party API.
  /// @dev offchainData can come from any untrusted source.
  function releaseOrMint(
    bytes memory originalSender,
    address receiver,
    uint256 amount,
    uint64 sourceChainSelector,
    bytes memory extraData
  ) external;

  /// @notice Gets the IERC20 token that this pool can lock or burn.
  /// @return token The IERC20 token representation.
  function getToken() external view returns (IERC20 token);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @notice This interface contains the only ARM-related functions that might be used on-chain by other CCIP contracts.
interface IARM {
  /// @notice A Merkle root tagged with the address of the commit store contract it is destined for.
  struct TaggedRoot {
    address commitStore;
    bytes32 root;
  }

  /// @notice Callers MUST NOT cache the return value as a blessed tagged root could become unblessed.
  function isBlessed(TaggedRoot calldata taggedRoot) external view returns (bool);

  /// @notice When the ARM is "cursed", CCIP pauses until the curse is lifted.
  function isCursed() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ConfirmedOwner} from "../../ConfirmedOwner.sol";

/// @title The OwnerIsCreator contract
/// @notice A contract with helpers for basic contract ownership.
contract OwnerIsCreator is ConfirmedOwner {
  constructor() ConfirmedOwner(msg.sender) {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @notice Implements Token Bucket rate limiting.
/// @dev uint128 is safe for rate limiter state.
/// For USD value rate limiting, it can adequately store USD value in 18 decimals.
/// For ERC20 token amount rate limiting, all tokens that will be listed will have at most
/// a supply of uint128.max tokens, and it will therefore not overflow the bucket.
/// In exceptional scenarios where tokens consumed may be larger than uint128,
/// e.g. compromised issuer, an enabled RateLimiter will check and revert.
library RateLimiter {
  error BucketOverfilled();
  error OnlyCallableByAdminOrOwner();
  error TokenMaxCapacityExceeded(uint256 capacity, uint256 requested, address tokenAddress);
  error TokenRateLimitReached(uint256 minWaitInSeconds, uint256 available, address tokenAddress);
  error AggregateValueMaxCapacityExceeded(uint256 capacity, uint256 requested);
  error AggregateValueRateLimitReached(uint256 minWaitInSeconds, uint256 available);

  event TokensConsumed(uint256 tokens);
  event ConfigChanged(Config config);

  struct TokenBucket {
    uint128 tokens; // ------┐ Current number of tokens that are in the bucket.
    uint32 lastUpdated; //   | Timestamp in seconds of the last token refill, good for 100+ years.
    bool isEnabled; // ------┘ Indication whether the rate limiting is enabled or not
    uint128 capacity; // ----┐ Maximum number of tokens that can be in the bucket.
    uint128 rate; // --------┘ Number of tokens per second that the bucket is refilled.
  }

  struct Config {
    bool isEnabled; // Indication whether the rate limiting should be enabled
    uint128 capacity; // ----┐ Specifies the capacity of the rate limiter
    uint128 rate; //  -------┘ Specifies the rate of the rate limiter
  }

  /// @notice _consume removes the given tokens from the pool, lowering the
  /// rate tokens allowed to be consumed for subsequent calls.
  /// @param requestTokens The total tokens to be consumed from the bucket.
  /// @param tokenAddress The token to consume capacity for, use 0x0 to indicate aggregate value capacity.
  /// @dev Reverts when requestTokens exceeds bucket capacity or available tokens in the bucket
  /// @dev emits removal of requestTokens if requestTokens is > 0
  function _consume(TokenBucket storage s_bucket, uint256 requestTokens, address tokenAddress) internal {
    // If there is no value to remove or rate limiting is turned off, skip this step to reduce gas usage
    if (!s_bucket.isEnabled || requestTokens == 0) {
      return;
    }

    uint256 tokens = s_bucket.tokens;
    uint256 capacity = s_bucket.capacity;
    uint256 timeDiff = block.timestamp - s_bucket.lastUpdated;

    if (timeDiff != 0) {
      if (tokens > capacity) revert BucketOverfilled();

      // Refill tokens when arriving at a new block time
      tokens = _calculateRefill(capacity, tokens, timeDiff, s_bucket.rate);

      s_bucket.lastUpdated = uint32(block.timestamp);
    }

    if (capacity < requestTokens) {
      // Token address 0 indicates consuming aggregate value rate limit capacity.
      if (tokenAddress == address(0)) revert AggregateValueMaxCapacityExceeded(capacity, requestTokens);
      revert TokenMaxCapacityExceeded(capacity, requestTokens, tokenAddress);
    }
    if (tokens < requestTokens) {
      uint256 rate = s_bucket.rate;
      // Wait required until the bucket is refilled enough to accept this value, round up to next higher second
      // Consume is not guaranteed to succeed after wait time passes if there is competing traffic.
      // This acts as a lower bound of wait time.
      uint256 minWaitInSeconds = ((requestTokens - tokens) + (rate - 1)) / rate;

      if (tokenAddress == address(0)) revert AggregateValueRateLimitReached(minWaitInSeconds, tokens);
      revert TokenRateLimitReached(minWaitInSeconds, tokens, tokenAddress);
    }
    tokens -= requestTokens;

    // Downcast is safe here, as tokens is not larger than capacity
    s_bucket.tokens = uint128(tokens);
    emit TokensConsumed(requestTokens);
  }

  /// @notice Gets the token bucket with its values for the block it was requested at.
  /// @return The token bucket.
  function _currentTokenBucketState(TokenBucket memory bucket) internal view returns (TokenBucket memory) {
    // We update the bucket to reflect the status at the exact time of the
    // call. This means we might need to refill a part of the bucket based
    // on the time that has passed since the last update.
    bucket.tokens = uint128(
      _calculateRefill(bucket.capacity, bucket.tokens, block.timestamp - bucket.lastUpdated, bucket.rate)
    );
    bucket.lastUpdated = uint32(block.timestamp);
    return bucket;
  }

  /// @notice Sets the rate limited config.
  /// @param s_bucket The token bucket
  /// @param config The new config
  function _setTokenBucketConfig(TokenBucket storage s_bucket, Config memory config) internal {
    // First update the bucket to make sure the proper rate is used for all the time
    // up until the config change.
    uint256 timeDiff = block.timestamp - s_bucket.lastUpdated;
    if (timeDiff != 0) {
      s_bucket.tokens = uint128(_calculateRefill(s_bucket.capacity, s_bucket.tokens, timeDiff, s_bucket.rate));

      s_bucket.lastUpdated = uint32(block.timestamp);
    }

    s_bucket.tokens = uint128(_min(config.capacity, s_bucket.tokens));
    s_bucket.isEnabled = config.isEnabled;
    s_bucket.capacity = config.capacity;
    s_bucket.rate = config.rate;

    emit ConfigChanged(config);
  }

  /// @notice Calculate refilled tokens
  /// @param capacity bucket capacity
  /// @param tokens current bucket tokens
  /// @param timeDiff block time difference since last refill
  /// @param rate bucket refill rate
  /// @return the value of tokens after refill
  function _calculateRefill(
    uint256 capacity,
    uint256 tokens,
    uint256 timeDiff,
    uint256 rate
  ) private pure returns (uint256) {
    return _min(capacity, tokens + timeDiff * rate);
  }

  /// @notice Return the smallest of two integers
  /// @param a first int
  /// @param b second int
  /// @return smallest
  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
  // To implement this library for multiple types with as little code
  // repetition as possible, we write it in terms of a generic Set type with
  // bytes32 values.
  // The Set implementation uses private functions, and user-facing
  // implementations (such as AddressSet) are just wrappers around the
  // underlying Set.
  // This means that we can only create new EnumerableSets for types that fit
  // in bytes32.

  struct Set {
    // Storage of set values
    bytes32[] _values;
    // Position of the value in the `values` array, plus 1 because index 0
    // means a value is not in the set.
    mapping(bytes32 => uint256) _indexes;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      // The value is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel value
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function _remove(Set storage set, bytes32 value) private returns (bool) {
    // We read and store the value's index to prevent multiple reads from the same storage slot
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      // Equivalent to contains(set, value)
      // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      if (lastIndex != toDeleteIndex) {
        bytes32 lastValue = set._values[lastIndex];

        // Move the last value to the index where the value to delete is
        set._values[toDeleteIndex] = lastValue;
        // Update the index for the moved value
        set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
      }

      // Delete the slot where the moved value was stored
      set._values.pop();

      // Delete the index for the deleted slot
      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function _contains(Set storage set, bytes32 value) private view returns (bool) {
    return set._indexes[value] != 0;
  }

  /**
   * @dev Returns the number of values on the set. O(1).
   */
  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    return set._values[index];
  }

  /**
   * @dev Return the entire set in an array
   *
   * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
   * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
   * this function has an unbounded cost, and using it as part of a state-changing function may render the function
   * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
   */
  function _values(Set storage set) private view returns (bytes32[] memory) {
    return set._values;
  }

  // Bytes32Set

  struct Bytes32Set {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _remove(set._inner, value);
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
    return _contains(set._inner, value);
  }

  /**
   * @dev Returns the number of values in the set. O(1).
   */
  function length(Bytes32Set storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
    return _at(set._inner, index);
  }

  /**
   * @dev Return the entire set in an array
   *
   * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
   * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
   * this function has an unbounded cost, and using it as part of a state-changing function may render the function
   * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
   */
  function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
    bytes32[] memory store = _values(set._inner);
    bytes32[] memory result;

    /// @solidity memory-safe-assembly
    assembly {
      result := store
    }

    return result;
  }

  // AddressSet

  struct AddressSet {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(AddressSet storage set, address value) internal returns (bool) {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(AddressSet storage set, address value) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns the number of values in the set. O(1).
   */
  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(AddressSet storage set, uint256 index) internal view returns (address) {
    return address(uint160(uint256(_at(set._inner, index))));
  }

  /**
   * @dev Return the entire set in an array
   *
   * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
   * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
   * this function has an unbounded cost, and using it as part of a state-changing function may render the function
   * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
   */
  function values(AddressSet storage set) internal view returns (address[] memory) {
    bytes32[] memory store = _values(set._inner);
    address[] memory result;

    /// @solidity memory-safe-assembly
    assembly {
      result := store
    }

    return result;
  }

  // UintSet

  struct UintSet {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(UintSet storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(UintSet storage set, uint256 value) internal view returns (bool) {
    return _contains(set._inner, bytes32(value));
  }

  /**
   * @dev Returns the number of values in the set. O(1).
   */
  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(UintSet storage set, uint256 index) internal view returns (uint256) {
    return uint256(_at(set._inner, index));
  }

  /**
   * @dev Return the entire set in an array
   *
   * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
   * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
   * this function has an unbounded cost, and using it as part of a state-changing function may render the function
   * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
   */
  function values(UintSet storage set) internal view returns (uint256[] memory) {
    bytes32[] memory store = _values(set._inner);
    uint256[] memory result;

    /// @solidity memory-safe-assembly
    assembly {
      result := store
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}