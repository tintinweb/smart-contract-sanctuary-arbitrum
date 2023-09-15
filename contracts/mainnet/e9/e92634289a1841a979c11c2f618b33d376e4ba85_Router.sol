// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {TypeAndVersionInterface} from "../interfaces/TypeAndVersionInterface.sol";
import {IRouterClient} from "./interfaces/IRouterClient.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {IEVM2AnyOnRamp} from "./interfaces/IEVM2AnyOnRamp.sol";
import {IARM} from "./interfaces/IARM.sol";
import {IWrappedNative} from "./interfaces/IWrappedNative.sol";
import {IAny2EVMMessageReceiver} from "./interfaces/IAny2EVMMessageReceiver.sol";

import {Client} from "./libraries/Client.sol";
import {OwnerIsCreator} from "./../shared/access/OwnerIsCreator.sol";

import {EnumerableMap} from "../vendor/openzeppelin-solidity/v4.8.0/contracts/utils/structs/EnumerableMap.sol";
import {SafeERC20} from "../vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";

/// @title Router
/// @notice This is the entry point for the end user wishing to send data across chains.
/// @dev This contract is used as a router for both on-ramps and off-ramps
contract Router is IRouter, IRouterClient, TypeAndVersionInterface, OwnerIsCreator {
  using SafeERC20 for IERC20;
  using EnumerableMap for EnumerableMap.AddressToUintMap;

  error FailedToSendValue();
  error InvalidRecipientAddress(address to);
  error OffRampMismatch();
  error BadARMSignal();

  event OnRampSet(uint64 indexed destChainSelector, address onRamp);
  event OffRampAdded(uint64 indexed sourceChainSelector, address offRamp);
  event OffRampRemoved(uint64 indexed sourceChainSelector, address offRamp);
  event MessageExecuted(bytes32 messageId, uint64 sourceChainSelector, address offRamp, bytes32 calldataHash);

  struct OnRamp {
    uint64 destChainSelector;
    address onRamp;
  }

  struct OffRamp {
    uint64 sourceChainSelector;
    address offRamp;
  }

  // solhint-disable-next-line chainlink-solidity/all-caps-constant-storage-variables
  string public constant override typeAndVersion = "Router 1.0.0";
  // We limit return data to a selector plus 4 words. This is to avoid
  // malicious contracts from returning large amounts of data and causing
  // repeated out-of-gas scenarios.
  uint16 public constant MAX_RET_BYTES = 4 + 4 * 32;
  // STATIC CONFIG
  // Address of arm proxy contract.
  address private immutable i_armProxy;

  // DYNAMIC CONFIG
  address private s_wrappedNative;
  // destChainSelector => onRamp address
  // Only ever one onRamp enabled at a time for a given destChainSelector.
  mapping(uint256 destChainSelector => address onRamp) private s_onRamps;
  // Mapping of offRamps to source chain ids
  // Can be multiple offRamps enabled at a time for a given sourceChainSelector,
  // for example during an no downtime upgrade while v1 messages are being flushed.
  EnumerableMap.AddressToUintMap private s_offRamps;

  constructor(address wrappedNative, address armProxy) {
    // Zero address indicates unsupported auto-wrapping, therefore, unsupported
    // native fee token payments.
    s_wrappedNative = wrappedNative;
    i_armProxy = armProxy;
  }

  // ================================================================
  // |                       Message sending                        |
  // ================================================================

  /// @inheritdoc IRouterClient
  function getFee(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory message
  ) external view returns (uint256 fee) {
    if (message.feeToken == address(0)) {
      // For empty feeToken return native quote.
      message.feeToken = address(s_wrappedNative);
    }
    address onRamp = s_onRamps[destinationChainSelector];
    if (onRamp == address(0)) revert UnsupportedDestinationChain(destinationChainSelector);
    return IEVM2AnyOnRamp(onRamp).getFee(message);
  }

  /// @inheritdoc IRouterClient
  function getSupportedTokens(uint64 chainSelector) external view returns (address[] memory) {
    if (!isChainSupported(chainSelector)) {
      return new address[](0);
    }
    return IEVM2AnyOnRamp(s_onRamps[uint256(chainSelector)]).getSupportedTokens();
  }

  /// @inheritdoc IRouterClient
  function isChainSupported(uint64 chainSelector) public view returns (bool) {
    return s_onRamps[chainSelector] != address(0);
  }

  /// @inheritdoc IRouterClient
  function ccipSend(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory message
  ) external payable whenHealthy returns (bytes32) {
    address onRamp = s_onRamps[destinationChainSelector];
    if (onRamp == address(0)) revert UnsupportedDestinationChain(destinationChainSelector);
    uint256 feeTokenAmount;
    // address(0) signals payment in true native
    if (message.feeToken == address(0)) {
      // for fee calculation we check the wrapped native price as we wrap
      // as part of the native fee coin payment.
      message.feeToken = s_wrappedNative;
      // We rely on getFee to validate that the feeToken is whitelisted.
      feeTokenAmount = IEVM2AnyOnRamp(onRamp).getFee(message);
      // Ensure sufficient native.
      if (msg.value < feeTokenAmount) revert InsufficientFeeTokenAmount();
      // Wrap and send native payment.
      // Note we take the whole msg.value regardless if its larger.
      feeTokenAmount = msg.value;
      IWrappedNative(message.feeToken).deposit{value: feeTokenAmount}();
      IERC20(message.feeToken).safeTransfer(onRamp, feeTokenAmount);
    } else {
      if (msg.value > 0) revert InvalidMsgValue();
      // We rely on getFee to validate that the feeToken is whitelisted.
      feeTokenAmount = IEVM2AnyOnRamp(onRamp).getFee(message);
      IERC20(message.feeToken).safeTransferFrom(msg.sender, onRamp, feeTokenAmount);
    }

    // Transfer the tokens to the token pools.
    for (uint256 i = 0; i < message.tokenAmounts.length; ++i) {
      IERC20 token = IERC20(message.tokenAmounts[i].token);
      // We rely on getPoolBySourceToken to validate that the token is whitelisted.
      token.safeTransferFrom(
        msg.sender,
        address(IEVM2AnyOnRamp(onRamp).getPoolBySourceToken(token)),
        message.tokenAmounts[i].amount
      );
    }

    return IEVM2AnyOnRamp(onRamp).forwardFromRouter(message, feeTokenAmount, msg.sender);
  }

  // ================================================================
  // |                      Message execution                       |
  // ================================================================

  /// @inheritdoc IRouter
  /// @dev Handles the edge case where we want to pass a specific amount of gas,
  /// @dev but EIP-150 sends all but 1/64 of the remaining gas instead so the user gets
  /// @dev less gas than they paid for. The other 2 parts of EIP-150 do not apply since
  /// @dev a) we hard code value=0 and b) we ensure code already exists.
  /// @dev If we revert instead, then that will never happen.
  /// @dev Separately we capture the return data up to a maximum size to avoid return bombs,
  /// @dev borrowed from https://github.com/nomad-xyz/ExcessivelySafeCall/blob/main/src/ExcessivelySafeCall.sol.
  function routeMessage(
    Client.Any2EVMMessage calldata message,
    uint16 gasForCallExactCheck,
    uint256 gasLimit,
    address receiver
  )
    external
    override
    onlyOffRamp(message.sourceChainSelector)
    whenHealthy
    returns (bool success, bytes memory retData)
  {
    // We encode here instead of the offRamps to constrain specifically what functions
    // can be called from the router.
    bytes memory data = abi.encodeWithSelector(IAny2EVMMessageReceiver.ccipReceive.selector, message);
    // allocate retData memory ahead of time
    retData = new bytes(MAX_RET_BYTES);

    // solhint-disable-next-line no-inline-assembly
    assembly {
      // solidity calls check that a contract actually exists at the destination, so we do the same
      // Note we do this check prior to measuring gas so gasForCallExactCheck (our "cushion")
      // doesn't need to account for it.
      if iszero(extcodesize(receiver)) {
        revert(0, 0)
      }

      let g := gas()
      // Compute g -= gasForCallExactCheck and check for underflow
      // The gas actually passed to the callee is _min(gasAmount, 63//64*gas available).
      // We want to ensure that we revert if gasAmount >  63//64*gas available
      // as we do not want to provide them with less, however that check itself costs
      // gas. gasForCallExactCheck ensures we have at least enough gas to be able
      // to revert if gasAmount >  63//64*gas available.
      if lt(g, gasForCallExactCheck) {
        revert(0, 0)
      }
      g := sub(g, gasForCallExactCheck)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasLimit)) {
        revert(0, 0)
      }
      // call and return whether we succeeded. ignore return data
      // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
      success := call(gasLimit, receiver, 0, add(data, 0x20), mload(data), 0, 0)

      // limit our copy to MAX_RET_BYTES bytes
      let toCopy := returndatasize()
      if gt(toCopy, MAX_RET_BYTES) {
        toCopy := MAX_RET_BYTES
      }
      // Store the length of the copied bytes
      mstore(retData, toCopy)
      // copy the bytes from retData[0:_toCopy]
      returndatacopy(add(retData, 0x20), 0, toCopy)
    }
    emit MessageExecuted(message.messageId, message.sourceChainSelector, msg.sender, keccak256(data));
    return (success, retData);
  }

  // ================================================================
  // |                           Config                             |
  // ================================================================

  /// @notice Gets the wrapped representation of the native fee coin.
  /// @return The address of the ERC20 wrapped native.
  function getWrappedNative() external view returns (address) {
    return s_wrappedNative;
  }

  /// @notice Sets a new wrapped native token.
  /// @param wrappedNative The address of the new wrapped native ERC20 token.
  function setWrappedNative(address wrappedNative) external onlyOwner {
    s_wrappedNative = wrappedNative;
  }

  /// @notice Gets the arm address
  /// @return The address of the ARM proxy contract.
  function getArmProxy() external view returns (address) {
    return i_armProxy;
  }

  /// @notice Return the configured onramp for specific a destination chain.
  /// @param destChainSelector The destination chain Id to get the onRamp for.
  /// @return The address of the onRamp.
  function getOnRamp(uint64 destChainSelector) external view returns (address) {
    return s_onRamps[destChainSelector];
  }

  /// @notice Return a full list of configured offRamps.
  function getOffRamps() external view returns (OffRamp[] memory) {
    OffRamp[] memory offRamps = new OffRamp[](s_offRamps.length());
    for (uint256 i = 0; i < offRamps.length; ++i) {
      (address offRamp, uint256 sourceChainSelector) = s_offRamps.at(i);
      offRamps[i] = OffRamp({sourceChainSelector: uint64(sourceChainSelector), offRamp: offRamp});
    }
    return offRamps;
  }

  /// @notice Returns true if the given address is a permissioned offRamp
  /// and sourceChainSelector if so.
  function isOffRamp(address offRamp) external view returns (bool, uint64) {
    (bool exists, uint256 sourceChainSelector) = s_offRamps.tryGet(offRamp);
    return (exists, uint64(sourceChainSelector));
  }

  /// @notice applyRampUpdates applies a set of ramp changes which provides
  /// the ability to add new chains and upgrade ramps.
  function applyRampUpdates(
    OnRamp[] calldata onRampUpdates,
    OffRamp[] calldata offRampRemoves,
    OffRamp[] calldata offRampAdds
  ) external onlyOwner {
    // Apply egress updates.
    // We permit zero address as way to disable egress.
    for (uint256 i = 0; i < onRampUpdates.length; ++i) {
      OnRamp memory onRampUpdate = onRampUpdates[i];
      s_onRamps[onRampUpdate.destChainSelector] = onRampUpdate.onRamp;
      emit OnRampSet(onRampUpdate.destChainSelector, onRampUpdate.onRamp);
    }
    // Apply ingress updates.
    // We permit an empty list as a way to disable ingress.
    for (uint256 i = 0; i < offRampRemoves.length; ++i) {
      uint64 rampSelector = offRampRemoves[i].sourceChainSelector;
      address rampAddress = offRampRemoves[i].offRamp;

      if (s_offRamps.get(rampAddress) != uint256(rampSelector)) revert OffRampMismatch();

      if (s_offRamps.remove(rampAddress)) {
        emit OffRampRemoved(rampSelector, rampAddress);
      }
    }
    for (uint256 i = 0; i < offRampAdds.length; ++i) {
      uint64 rampSelector = offRampAdds[i].sourceChainSelector;
      address rampAddress = offRampAdds[i].offRamp;

      if (s_offRamps.set(rampAddress, rampSelector)) {
        emit OffRampAdded(rampSelector, rampAddress);
      }
    }
  }

  /// @notice Provides the ability for the owner to recover any tokens accidentally
  /// sent to this contract.
  /// @dev Must be onlyOwner to avoid malicious token contract calls.
  /// @param tokenAddress ERC20-token to recover
  /// @param to Destination address to send the tokens to.
  function recoverTokens(address tokenAddress, address to, uint256 amount) external onlyOwner {
    if (to == address(0)) revert InvalidRecipientAddress(to);

    if (tokenAddress == address(0)) {
      (bool success, ) = to.call{value: amount}("");
      if (!success) revert FailedToSendValue();
      return;
    }
    IERC20(tokenAddress).safeTransfer(to, amount);
  }

  // ================================================================
  // |                           Access                             |
  // ================================================================

  /// @notice only lets permissioned offRamps execute
  /// @dev We additionally restrict offRamps to specific source chains for defense in depth.
  modifier onlyOffRamp(uint64 expectedSourceChainSelector) {
    (bool exists, uint256 sourceChainSelector) = s_offRamps.tryGet(msg.sender);
    if (!exists || expectedSourceChainSelector != uint64(sourceChainSelector)) revert OnlyOffRamp();
    _;
  }

  /// @notice Ensure that the ARM has not emitted a bad signal, and that the latest heartbeat is not stale.
  modifier whenHealthy() {
    if (IARM(i_armProxy).isCursed()) revert BadARMSignal();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

interface IRouterClient {
  error UnsupportedDestinationChain(uint64 destChainSelector);
  error InsufficientFeeTokenAmount();
  error InvalidMsgValue();

  /// @notice Checks if the given chain ID is supported for sending/receiving.
  /// @param chainSelector The chain to check.
  /// @return supported is true if it is supported, false if not.
  function isChainSupported(uint64 chainSelector) external view returns (bool supported);

  /// @notice Gets a list of all supported tokens which can be sent or received
  /// to/from a given chain id.
  /// @param chainSelector The chainSelector.
  /// @return tokens The addresses of all tokens that are supported.
  function getSupportedTokens(uint64 chainSelector) external view returns (address[] memory tokens);

  /// @param destinationChainSelector The destination chainSelector
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return fee returns execution fee for the message
  /// delivery to destination chain, denominated in the feeToken specified in the message.
  /// @dev Reverts with appropriate reason upon invalid message.
  function getFee(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory message
  ) external view returns (uint256 fee);

  /// @notice Request a message to be sent to the destination chain
  /// @param destinationChainSelector The destination chain ID
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return messageId The message ID
  /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
  /// the overpayment with no refund.
  /// @dev Reverts with appropriate reason upon invalid message.
  function ccipSend(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage calldata message
  ) external payable returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

interface IRouter {
  error OnlyOffRamp();

  /// @notice Route the message to its intended receiver contract.
  /// @param message Client.Any2EVMMessage struct.
  /// @param gasForCallExactCheck of params for exec
  /// @param gasLimit set of params for exec
  /// @param receiver set of params for exec
  /// @dev if the receiver is a contracts that signals support for CCIP execution through EIP-165.
  /// the contract is called. If not, only tokens are transferred.
  /// @return success A boolean value indicating whether the ccip message was received without errors.
  /// @return retBytes A bytes array containing return data form CCIP receiver.
  function routeMessage(
    Client.Any2EVMMessage calldata message,
    uint16 gasForCallExactCheck,
    uint256 gasLimit,
    address receiver
  ) external returns (bool success, bytes memory retBytes);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPool} from "./pools/IPool.sol";

import {Client} from "../libraries/Client.sol";
import {Internal} from "../libraries/Internal.sol";

import {IERC20} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";

interface IEVM2AnyOnRamp {
  /// @notice Get the fee for a given ccip message
  /// @param message The message to calculate the cost for
  /// @return fee The calculated fee
  function getFee(Client.EVM2AnyMessage calldata message) external view returns (uint256 fee);

  /// @notice Get the pool for a specific token
  /// @param sourceToken The source chain token to get the pool for
  /// @return pool Token pool
  function getPoolBySourceToken(IERC20 sourceToken) external view returns (IPool);

  /// @notice Gets a list of all supported source chain tokens.
  /// @return tokens The addresses of all tokens that this onRamp supports for sending.
  function getSupportedTokens() external view returns (address[] memory tokens);

  /// @notice Gets the next sequence number to be used in the onRamp
  /// @return the next sequence number to be used
  function getExpectedNextSequenceNumber() external view returns (uint64);

  /// @notice Get the next nonce for a given sender
  /// @param sender The sender to get the nonce for
  /// @return nonce The next nonce for the sender
  function getSenderNonce(address sender) external view returns (uint64 nonce);

  /// @notice Adds and removed token pools.
  /// @param removes The tokens and pools to be removed
  /// @param adds The tokens and pools to be added.
  function applyPoolUpdates(Internal.PoolUpdate[] memory removes, Internal.PoolUpdate[] memory adds) external;

  /// @notice Send a message to the remote chain
  /// @dev only callable by the Router
  /// @dev approve() must have already been called on the token using the this ramp address as the spender.
  /// @dev if the contract is paused, this function will revert.
  /// @param message Message struct to send
  /// @param originalSender The original initiator of the CCIP request
  function forwardFromRouter(
    Client.EVM2AnyMessage memory message,
    uint256 feeTokenAmount,
    address originalSender
  ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
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

import {IERC20} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";

interface IWrappedNative is IERC20 {
  function deposit() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

/// @notice Application contracts that intend to receive messages from
/// the router should implement this interface.
interface IAny2EVMMessageReceiver {
  /// @notice Called by the Router to deliver a message.
  /// If this reverts, any token transfers also revert. The message
  /// will move to a FAILED state and become available for manual execution.
  /// @param message CCIP Message
  /// @dev Note ensure you check the msg.sender is the OffRampRouter
  function ccipReceive(Client.Any2EVMMessage calldata message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// End consumer library.
library Client {
  struct EVMTokenAmount {
    address token; // token address on the local chain.
    uint256 amount; // Amount of tokens.
  }

  struct Any2EVMMessage {
    bytes32 messageId; // MessageId corresponding to ccipSend on source.
    uint64 sourceChainSelector; // Source chain selector.
    bytes sender; // abi.decode(sender) if coming from an EVM chain.
    bytes data; // payload sent in original message.
    EVMTokenAmount[] destTokenAmounts; // Tokens and their amounts in their destination chain representation.
  }

  // If extraArgs is empty bytes, the default is 200k gas limit.
  struct EVM2AnyMessage {
    bytes receiver; // abi.encode(receiver address) for dest EVM chains
    bytes data; // Data payload
    EVMTokenAmount[] tokenAmounts; // Token transfers
    address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
  }

  // bytes4(keccak256("CCIP EVMExtraArgsV1"));
  bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
  struct EVMExtraArgsV1 {
    uint256 gasLimit;
  }

  function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ConfirmedOwner} from "./ConfirmedOwner.sol";

/// @title The OwnerIsCreator contract
/// @notice A contract with helpers for basic contract ownership.
contract OwnerIsCreator is ConfirmedOwner {
  constructor() ConfirmedOwner(msg.sender) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
  using EnumerableSet for EnumerableSet.Bytes32Set;

  // To implement this library for multiple types with as little code
  // repetition as possible, we write it in terms of a generic Map type with
  // bytes32 keys and values.
  // The Map implementation uses private functions, and user-facing
  // implementations (such as Uint256ToAddressMap) are just wrappers around
  // the underlying Map.
  // This means that we can only create new EnumerableMaps for types that fit
  // in bytes32.

  struct Bytes32ToBytes32Map {
    // Storage of keys
    EnumerableSet.Bytes32Set _keys;
    mapping(bytes32 => bytes32) _values;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
   * key. O(1).
   *
   * Returns true if the key was added to the map, that is if it was not
   * already present.
   */
  function set(
    Bytes32ToBytes32Map storage map,
    bytes32 key,
    bytes32 value
  ) internal returns (bool) {
    map._values[key] = value;
    return map._keys.add(key);
  }

  /**
   * @dev Removes a key-value pair from a map. O(1).
   *
   * Returns true if the key was removed from the map, that is if it was present.
   */
  function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
    delete map._values[key];
    return map._keys.remove(key);
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
   */
  function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
    return map._keys.contains(key);
  }

  /**
   * @dev Returns the number of key-value pairs in the map. O(1).
   */
  function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
    return map._keys.length();
  }

  /**
   * @dev Returns the key-value pair stored at position `index` in the map. O(1).
   *
   * Note that there are no guarantees on the ordering of entries inside the
   * array, and it may change when more entries are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
    bytes32 key = map._keys.at(index);
    return (key, map._values[key]);
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
   * Does not revert if `key` is not in the map.
   */
  function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
    bytes32 value = map._values[key];
    if (value == bytes32(0)) {
      return (contains(map, key), bytes32(0));
    } else {
      return (true, value);
    }
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
   *
   * Requirements:
   *
   * - `key` must be in the map.
   */
  function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
    bytes32 value = map._values[key];
    require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
    return value;
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryGet}.
   */
  function get(
    Bytes32ToBytes32Map storage map,
    bytes32 key,
    string memory errorMessage
  ) internal view returns (bytes32) {
    bytes32 value = map._values[key];
    require(value != 0 || contains(map, key), errorMessage);
    return value;
  }

  // UintToUintMap

  struct UintToUintMap {
    Bytes32ToBytes32Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
   * key. O(1).
   *
   * Returns true if the key was added to the map, that is if it was not
   * already present.
   */
  function set(
    UintToUintMap storage map,
    uint256 key,
    uint256 value
  ) internal returns (bool) {
    return set(map._inner, bytes32(key), bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the key was removed from the map, that is if it was present.
   */
  function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
    return remove(map._inner, bytes32(key));
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
   */
  function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
    return contains(map._inner, bytes32(key));
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
   */
  function length(UintToUintMap storage map) internal view returns (uint256) {
    return length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    return (uint256(key), uint256(value));
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
   * Does not revert if `key` is not in the map.
   */
  function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
    (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
    return (success, uint256(value));
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
   *
   * Requirements:
   *
   * - `key` must be in the map.
   */
  function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
    return uint256(get(map._inner, bytes32(key)));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryGet}.
   */
  function get(
    UintToUintMap storage map,
    uint256 key,
    string memory errorMessage
  ) internal view returns (uint256) {
    return uint256(get(map._inner, bytes32(key), errorMessage));
  }

  // UintToAddressMap

  struct UintToAddressMap {
    Bytes32ToBytes32Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
   * key. O(1).
   *
   * Returns true if the key was added to the map, that is if it was not
   * already present.
   */
  function set(
    UintToAddressMap storage map,
    uint256 key,
    address value
  ) internal returns (bool) {
    return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the key was removed from the map, that is if it was present.
   */
  function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
    return remove(map._inner, bytes32(key));
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
   */
  function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
    return contains(map._inner, bytes32(key));
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
   */
  function length(UintToAddressMap storage map) internal view returns (uint256) {
    return length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    return (uint256(key), address(uint160(uint256(value))));
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
   * Does not revert if `key` is not in the map.
   */
  function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
    (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
    return (success, address(uint160(uint256(value))));
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
   *
   * Requirements:
   *
   * - `key` must be in the map.
   */
  function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
    return address(uint160(uint256(get(map._inner, bytes32(key)))));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryGet}.
   */
  function get(
    UintToAddressMap storage map,
    uint256 key,
    string memory errorMessage
  ) internal view returns (address) {
    return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
  }

  // AddressToUintMap

  struct AddressToUintMap {
    Bytes32ToBytes32Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
   * key. O(1).
   *
   * Returns true if the key was added to the map, that is if it was not
   * already present.
   */
  function set(
    AddressToUintMap storage map,
    address key,
    uint256 value
  ) internal returns (bool) {
    return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the key was removed from the map, that is if it was present.
   */
  function remove(AddressToUintMap storage map, address key) internal returns (bool) {
    return remove(map._inner, bytes32(uint256(uint160(key))));
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
   */
  function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
    return contains(map._inner, bytes32(uint256(uint160(key))));
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
   */
  function length(AddressToUintMap storage map) internal view returns (uint256) {
    return length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    return (address(uint160(uint256(key))), uint256(value));
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
   * Does not revert if `key` is not in the map.
   */
  function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
    (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
    return (success, uint256(value));
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
   *
   * Requirements:
   *
   * - `key` must be in the map.
   */
  function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
    return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryGet}.
   */
  function get(
    AddressToUintMap storage map,
    address key,
    string memory errorMessage
  ) internal view returns (uint256) {
    return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
  }

  // Bytes32ToUintMap

  struct Bytes32ToUintMap {
    Bytes32ToBytes32Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
   * key. O(1).
   *
   * Returns true if the key was added to the map, that is if it was not
   * already present.
   */
  function set(
    Bytes32ToUintMap storage map,
    bytes32 key,
    uint256 value
  ) internal returns (bool) {
    return set(map._inner, key, bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the key was removed from the map, that is if it was present.
   */
  function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
    return remove(map._inner, key);
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
   */
  function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
    return contains(map._inner, key);
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
   */
  function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
    return length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    return (key, uint256(value));
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
   * Does not revert if `key` is not in the map.
   */
  function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
    (bool success, bytes32 value) = tryGet(map._inner, key);
    return (success, uint256(value));
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
   *
   * Requirements:
   *
   * - `key` must be in the map.
   */
  function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
    return uint256(get(map._inner, key));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryGet}.
   */
  function get(
    Bytes32ToUintMap storage map,
    bytes32 key,
    string memory errorMessage
  ) internal view returns (uint256) {
    return uint256(get(map._inner, key, errorMessage));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
pragma solidity ^0.8.0;

import {IERC20} from "../../../vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "./Client.sol";
import {MerkleMultiProof} from "../libraries/MerkleMultiProof.sol";

// Library for CCIP internal definitions common to multiple contracts.
library Internal {
  struct PriceUpdates {
    TokenPriceUpdate[] tokenPriceUpdates;
    uint64 destChainSelector; // ──╮ Destination chain selector
    uint224 usdPerUnitGas; // ─────╯ 1e18 USD per smallest unit (e.g. wei) of destination chain gas
  }

  struct TokenPriceUpdate {
    address sourceToken; // Source token
    uint224 usdPerToken; // 1e18 USD per smallest unit of token
  }

  struct TimestampedPackedUint224 {
    uint224 value; // ───────╮ Value in uint224, packed.
    uint32 timestamp; // ────╯ Timestamp of the most recent price update.
  }

  /// @dev Gas price is stored in 112-bit unsigned int. uint224 can pack 2 prices.
  /// When packing L1 and L2 gas prices, L1 gas price is left-shifted to the higher-order bits.
  /// Using uint8, which is strictly lower than 1st shift operand, to avoid shift operand type warning.
  uint8 public constant GAS_PRICE_BITS = 112;

  struct PoolUpdate {
    address token; // The IERC20 token address
    address pool; // The token pool address
  }

  struct ExecutionReport {
    EVM2EVMMessage[] messages;
    // Contains a bytes array for each message, each inner bytes array contains bytes per transferred token
    bytes[][] offchainTokenData;
    bytes32[] proofs;
    uint256 proofFlagBits;
  }

  // @notice The cross chain message that gets committed to EVM chains
  struct EVM2EVMMessage {
    uint64 sourceChainSelector; // ─────────╮ the chain selector of the source chain, note: not chainId
    address sender; // ─────────────────────╯ sender address on the source chain
    address receiver; // ───────────────────╮ receiver address on the destination chain
    uint64 sequenceNumber; // ──────────────╯ sequence number, not unique across lanes
    uint256 gasLimit; //                      user supplied maximum gas amount available for dest chain execution
    bool strict; // ────────────────────────╮ DEPRECATED
    uint64 nonce; //                        │ nonce for this lane for this sender, not unique across senders/lanes
    address feeToken; // ───────────────────╯ fee token
    uint256 feeTokenAmount; //                fee token amount
    bytes data; //                            arbitrary data payload supplied by the message sender
    Client.EVMTokenAmount[] tokenAmounts; //  array of tokens and amounts to transfer
    bytes[] sourceTokenData; //               array of token pool return values, one per token
    bytes32 messageId; //                     a hash of the message data
  }

  /// @dev EVM2EVMMessage struct has 13 fields, including 3 variable arrays.
  /// Each variable array takes 1 more slot to store its length.
  /// When abi encoded, excluding array contents,
  /// EVM2EVMMessage takes up a fixed number of 16 lots, 32 bytes each.
  /// For structs that contain arrays, 1 more slot is added to the front, reaching a total of 17.
  uint256 public constant MESSAGE_FIXED_BYTES = 32 * 17;

  /// @dev Each token transfer adds 1 EVMTokenAmount and 1 bytes.
  /// When abiEncoded, each EVMTokenAmount takes 2 slots, each bytes takes 2 slots.
  uint256 public constant MESSAGE_BYTES_PER_TOKEN = 32 * 4;

  function _toAny2EVMMessage(
    EVM2EVMMessage memory original,
    Client.EVMTokenAmount[] memory destTokenAmounts
  ) internal pure returns (Client.Any2EVMMessage memory message) {
    message = Client.Any2EVMMessage({
      messageId: original.messageId,
      sourceChainSelector: original.sourceChainSelector,
      sender: abi.encode(original.sender),
      data: original.data,
      destTokenAmounts: destTokenAmounts
    });
  }

  bytes32 internal constant EVM_2_EVM_MESSAGE_HASH = keccak256("EVM2EVMMessageEvent");

  function _hash(EVM2EVMMessage memory original, bytes32 metadataHash) internal pure returns (bytes32) {
    /// @dev Fields split into 2 abi.encode calls due to number of parameters triggering stack too deep.
    /// If a dynamic type, e.g. an array is to be added, make sure it is placed in the last abi.encode call.
    return
      keccak256(
        bytes.concat(
          abi.encode(
            MerkleMultiProof.LEAF_DOMAIN_SEPARATOR,
            metadataHash,
            original.sequenceNumber,
            original.nonce,
            original.sender,
            original.receiver,
            keccak256(original.data),
            keccak256(abi.encode(original.tokenAmounts)),
            keccak256(abi.encode(original.sourceTokenData)),
            original.gasLimit,
            original.strict
          ),
          abi.encode(original.feeToken, original.feeTokenAmount)
        )
      );
  }

  /// @notice Enum listing the possible message execution states within
  /// the offRamp contract.
  /// UNTOUCHED never executed
  /// IN_PROGRESS currently being executed, used a replay protection
  /// SUCCESS successfully executed. End state
  /// FAILURE unsuccessfully executed, manual execution is now enabled.
  enum MessageExecutionState {
    UNTOUCHED,
    IN_PROGRESS,
    SUCCESS,
    FAILURE
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
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library MerkleMultiProof {
  /// @notice Leaf domain separator, should be used as the first 32 bytes of a leaf's preimage.
  bytes32 internal constant LEAF_DOMAIN_SEPARATOR = 0x0000000000000000000000000000000000000000000000000000000000000000;
  /// @notice Internal domain separator, should be used as the first 32 bytes of an internal node's preiimage.
  bytes32 internal constant INTERNAL_DOMAIN_SEPARATOR =
    0x0000000000000000000000000000000000000000000000000000000000000001;

  uint256 internal constant MAX_NUM_HASHES = 256;

  error InvalidProof();
  error LeavesCannotBeEmpty();

  /// @notice Computes the root based on provided pre-hashed leaf nodes in
  /// leaves, internal nodes in proofs, and using proofFlagBits' i-th bit to
  /// determine if an element of proofs or one of the previously computed leafs
  /// or internal nodes will be used for the i-th hash.
  /// @param leaves Should be pre-hashed and the first 32 bytes of a leaf's
  /// preimage should match LEAF_DOMAIN_SEPARATOR.
  /// @param proofs The hashes to be used instead of a leaf hash when the proofFlagBits
  ///  indicates a proof should be used.
  /// @param proofFlagBits A single uint256 of which each bit indicates whether a leaf or
  ///  a proof needs to be used in a hash operation.
  /// @dev the maximum number of hash operations it set to 256. Any input that would require
  ///  more than 256 hashes to get to a root will revert.
  /// @dev For given input `leaves` = [a,b,c] `proofs` = [D] and `proofFlagBits` = 5
  ///     totalHashes = 3 + 1 - 1 = 3
  ///  ** round 1 **
  ///    proofFlagBits = (5 >> 0) & 1 = true
  ///    hashes[0] = hashPair(a, b)
  ///    (leafPos, hashPos, proofPos) = (2, 0, 0);
  ///
  ///  ** round 2 **
  ///    proofFlagBits = (5 >> 1) & 1 = false
  ///    hashes[1] = hashPair(D, c)
  ///    (leafPos, hashPos, proofPos) = (3, 0, 1);
  ///
  ///  ** round 3 **
  ///    proofFlagBits = (5 >> 2) & 1 = true
  ///    hashes[2] = hashPair(hashes[0], hashes[1])
  ///    (leafPos, hashPos, proofPos) = (3, 2, 1);
  ///
  ///    i = 3 and no longer < totalHashes. The algorithm is done
  ///    return hashes[totalHashes - 1] = hashes[2]; the last hash we computed.
  // We mark this function as internal to force it to be inlined in contracts
  // that use it, but semantically it is public.
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function merkleRoot(
    bytes32[] memory leaves,
    bytes32[] memory proofs,
    uint256 proofFlagBits
  ) internal pure returns (bytes32) {
    unchecked {
      uint256 leavesLen = leaves.length;
      uint256 proofsLen = proofs.length;
      if (leavesLen == 0) revert LeavesCannotBeEmpty();
      if (!(leavesLen <= MAX_NUM_HASHES + 1 && proofsLen <= MAX_NUM_HASHES + 1)) revert InvalidProof();
      uint256 totalHashes = leavesLen + proofsLen - 1;
      if (!(totalHashes <= MAX_NUM_HASHES)) revert InvalidProof();
      if (totalHashes == 0) {
        return leaves[0];
      }
      bytes32[] memory hashes = new bytes32[](totalHashes);
      (uint256 leafPos, uint256 hashPos, uint256 proofPos) = (0, 0, 0);

      for (uint256 i = 0; i < totalHashes; ++i) {
        // Checks if the bit flag signals the use of a supplied proof or a leaf/previous hash.
        bytes32 a;
        if (proofFlagBits & (1 << i) == (1 << i)) {
          // Use a leaf or a previously computed hash.
          if (leafPos < leavesLen) {
            a = leaves[leafPos++];
          } else {
            a = hashes[hashPos++];
          }
        } else {
          // Use a supplied proof.
          a = proofs[proofPos++];
        }

        // The second part of the hashed pair is never a proof as hashing two proofs would result in a
        // hash that can already be computed offchain.
        bytes32 b;
        if (leafPos < leavesLen) {
          b = leaves[leafPos++];
        } else {
          b = hashes[hashPos++];
        }

        if (!(hashPos <= i)) revert InvalidProof();

        hashes[i] = _hashPair(a, b);
      }
      if (!(hashPos == totalHashes - 1 && leafPos == leavesLen && proofPos == proofsLen)) revert InvalidProof();
      // Return the last hash.
      return hashes[totalHashes - 1];
    }
  }

  /// @notice Hashes two bytes32 objects in their given order, prepended by the
  /// INTERNAL_DOMAIN_SEPARATOR.
  function _hashInternalNode(bytes32 left, bytes32 right) private pure returns (bytes32 hash) {
    return keccak256(abi.encode(INTERNAL_DOMAIN_SEPARATOR, left, right));
  }

  /// @notice Hashes two bytes32 objects. The order is taken into account,
  /// using the lower value first.
  function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
    return a < b ? _hashInternalNode(a, b) : _hashInternalNode(b, a);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IOwnable.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is IOwnable {
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

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}