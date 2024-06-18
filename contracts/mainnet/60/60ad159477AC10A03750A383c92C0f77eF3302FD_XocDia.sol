// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function _preventExecution() internal view {
    // solhint-disable-next-line avoid-tx-origin
    if (tx.origin != address(0) && tx.origin != address(0x1111111111111111111111111111111111111111)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    _preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AutomationBase} from "./AutomationBase.sol";
import {AutomationCompatibleInterface} from "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ConfirmedOwnerWithProposal} from "./ConfirmedOwnerWithProposal.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from "../interfaces/IOwnable.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    // solhint-disable-next-line gas-custom-errors
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /// @notice Allows an owner to begin transferring ownership to a new address.
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /// @notice Allows an ownership transfer to be completed by the recipient.
  function acceptOwnership() external override {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /// @notice Get the current owner
  function owner() public view override returns (address) {
    return s_owner;
  }

  /// @notice validate, transfer ownership, and emit relevant events
  function _transferOwnership(address to) private {
    // solhint-disable-next-line gas-custom-errors
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /// @notice validate access
  function _validateOwnership() internal view {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /// @notice Reverts if called by anyone other than the contract owner.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFV2PlusClient} from "../libraries/VRFV2PlusClient.sol";
import {IVRFSubscriptionV2Plus} from "./IVRFSubscriptionV2Plus.sol";

// Interface that enables consumers of VRFCoordinatorV2Plus to be future-proof for upgrades
// This interface is supported by subsequent versions of VRFCoordinatorV2Plus
interface IVRFCoordinatorV2Plus is IVRFSubscriptionV2Plus {
  /**
   * @notice Request a set of random words.
   * @param req - a struct containing following fields for randomness request:
   * keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * requestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * extraArgs - abi-encoded extra args
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256 requestId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice The IVRFMigratableConsumerV2Plus interface defines the
/// @notice method required to be implemented by all V2Plus consumers.
/// @dev This interface is designed to be used in VRFConsumerBaseV2Plus.
interface IVRFMigratableConsumerV2Plus {
  event CoordinatorSet(address vrfCoordinator);

  /// @notice Sets the VRF Coordinator address
  /// @notice This method should only be callable by the coordinator or contract owner
  function setCoordinator(address vrfCoordinator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice The IVRFSubscriptionV2Plus interface defines the subscription
/// @notice related methods implemented by the V2Plus coordinator.
interface IVRFSubscriptionV2Plus {
  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint256 subId, address to) external;

  /**
   * @notice Accept subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint256 subId) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint256 subId, address newOwner) external;

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription with LINK, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   * @dev Note to fund the subscription with Native, use fundSubscriptionWithNative. Be sure
   * @dev  to send Native with the call, for example:
   * @dev COORDINATOR.fundSubscriptionWithNative{value: amount}(subId);
   */
  function createSubscription() external returns (uint256 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return nativeBalance - native balance of the subscription in wei.
   * @return reqCount - Requests count of subscription.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint256 subId
  )
    external
    view
    returns (uint96 balance, uint96 nativeBalance, uint64 reqCount, address owner, address[] memory consumers);

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint256 subId) external view returns (bool);

  /**
   * @notice Paginate through all active VRF subscriptions.
   * @param startIndex index of the subscription to start from
   * @param maxCount maximum number of subscriptions to return, 0 to return all
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * @dev should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   */
  function getActiveSubscriptionIds(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  /**
   * @notice Fund a subscription with native.
   * @param subId - ID of the subscription
   * @notice This method expects msg.value to be greater than or equal to 0.
   */
  function fundSubscriptionWithNative(uint256 subId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// End consumer library.
library VRFV2PlusClient {
  // extraArgs will evolve to support new features
  bytes4 public constant EXTRA_ARGS_V1_TAG = bytes4(keccak256("VRF ExtraArgsV1"));
  struct ExtraArgsV1 {
    bool nativePayment;
  }

  struct RandomWordsRequest {
    bytes32 keyHash;
    uint256 subId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    uint32 numWords;
    bytes extraArgs;
  }

  function _argsToBytes(ExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IVRFCoordinatorV2Plus} from "./interfaces/IVRFCoordinatorV2Plus.sol";
import {IVRFMigratableConsumerV2Plus} from "./interfaces/IVRFMigratableConsumerV2Plus.sol";
import {ConfirmedOwner} from "../../shared/access/ConfirmedOwner.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinatorV2Plus.
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBaseV2Plus, and can
 * @dev initialize VRFConsumerBaseV2Plus's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumerV2Plus is VRFConsumerBaseV2Plus {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _subOwner)
 * @dev       VRFConsumerBaseV2Plus(_vrfCoordinator, _subOwner) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create a subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords, extraArgs),
 * @dev see (IVRFCoordinatorV2Plus for a description of the arguments).
 *
 * @dev Once the VRFCoordinatorV2Plus has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBaseV2Plus.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2Plus is IVRFMigratableConsumerV2Plus, ConfirmedOwner {
  error OnlyCoordinatorCanFulfill(address have, address want);
  error OnlyOwnerOrCoordinator(address have, address owner, address coordinator);
  error ZeroAddress();

  // s_vrfCoordinator should be used by consumers to make requests to vrfCoordinator
  // so that coordinator reference is updated after migration
  IVRFCoordinatorV2Plus public s_vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) ConfirmedOwner(msg.sender) {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2Plus expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != address(s_vrfCoordinator)) {
      revert OnlyCoordinatorCanFulfill(msg.sender, address(s_vrfCoordinator));
    }
    fulfillRandomWords(requestId, randomWords);
  }

  /**
   * @inheritdoc IVRFMigratableConsumerV2Plus
   */
  function setCoordinator(address _vrfCoordinator) external override onlyOwnerOrCoordinator {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);

    emit CoordinatorSet(_vrfCoordinator);
  }

  modifier onlyOwnerOrCoordinator() {
    if (msg.sender != owner() && msg.sender != address(s_vrfCoordinator)) {
      revert OnlyOwnerOrCoordinator(msg.sender, owner(), address(s_vrfCoordinator));
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

/*
UYTIN.IO - Terms of Service

All games are run entirely by smart contracts on the blockchain network and outcomes are determined by Chainlink VRF. Players can directly participate in betting with the blockchain system through blockchain explorers such as polygonscan.com, arbiscan.io, or users can connect directly to nodes of the blockchain network to participate in betting with their personal electronic wallets. Therefore, we cannot require KYC, manage IP addresses, or any personal information of the players.
Players store cryptocurrencies in their personal crypto wallets and are fully responsible for the security of their electronic wallets, as well as for signing transactions on blockchain networks.
List of restricted countries: Users from the following countries and territories are not allowed to participate in our games due to legal restrictions. Please note that this list may be updated depending on the legal situation of each country: The United States and its territories, United Kingdom, Canada, Australia, New Zealand European countries: Albania, Andorra, Armenia, Austria, Azerbaijan, Belarus, Belgium, Bosnia and Herzegovina, Bulgaria, Croatia, Cyprus, Czechia, Denmark, Estonia, Finland, France, Germany, Georgia, Greece, Hungary, Iceland, Ireland, Italy, Latvia, Liechtenstein, Lithuania, Luxembourg, Malta, Moldova, Monaco, Montenegro, Netherlands, North Macedonia, Norway, Poland, Portugal, Romania, Russia, San Marino, Serbia, Slovakia, Slovenia, Spain, Sweden, Switzerland, Turkey, Ukraine Other countries: Barbados, Burkina Faso, Cambodia, Cayman Islands, Gibraltar, Haiti, Jordan, Mali, Morocco, Myanmar, Russia, Nicaragua, Pakistan, Panama, Philippines, Senegal, Trinidad & Tobago, Uganda, United Arab Emirates, Vanuatu, Yemen, Zimbabwe, India, Hong Kong, Syria, Turkey, China, Saudi Arabia, Iraq, Iran, Kuwait, Libya, Sudan, Singapore, South Sudan, Bahamas, Ethiopia, Ghana, Sri Lanka, Cameroon, Comoros, Côte d'Ivoire, Cook Islands, Cape Verde, Djibouti, Eritrea, Somalia, Sao Tome and Principe, Uzbekistan, Virgin Islands, Tanzania, Ukraine, Vatican City State, Venezuela, Serbia, North Korea, South Korea, Greenland, Lebanon, Maldives, Niger, Suriname, Togo, Tonga, Tuvalu, Uruguay, Papua New Guinea, Paraguay, Samoa, Solomon Islands, Belize, Brunei Darussalam, Eswatini, Guyana, Kiribati, Lesotho, Liberia, Colombia
Note: 
We (UYTIN.IO) only provide smart contracts on blockchain networks; 
1. players are responsible for the laws of their country of residence and nationality. 
2. All players residing in or nationals of countries that prohibit online gambling or cryptocurrencies are not allowed to participate. 
3. All players residing in countries that require KYC for buying, selling, exchanging, or transferring cryptocurrencies are not allowed to participate in our games. 
4. Players must be of the minimum age required by local gambling laws to participate in online gambling. 
Please carefully check the information before participating in our games. In case players from countries where gambling or unauthorized use of cryptocurrencies is prohibited use our services, they will be fully responsible for the local laws of their place of residence.
We do not take responsibility for any misuse of our source code to build other gambling systems. You are solely responsible for your actions as well as security and legal issues.
*/

// import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

interface IBankRoll {
    function getTokenList() external view returns (address[] memory);

    function getIsValidWager(address gameAddress, address tokenAddress)
        external
        view
        returns (bool);

    function getMinWager(address tokenAddress) external view returns (uint256);

    function poolLiquidityOf(address tokenAddress)
        external
        view
        returns (uint256);

    function getRef(address playerAddress)
        external
        view
        returns (address refferalAddress);

    function receiveWager(
        address playerAddress,
        uint256 wagers,
        address tokenAddress,
        uint256 wagersAfterTax,
        uint256 reward,
        uint256 payout
    ) external;
}

contract MultiPlayer is VRFConsumerBaseV2Plus {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public houseEdge;
    mapping(address => mapping(address => uint256)) balance;
    uint256 public accepted;

    IBankRoll public Bankroll;
    IVRFCoordinatorV2Plus COORDINATOR;

    uint256 s_subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    uint16 refundConfirmations;
    bool public payingWithNative;

    constructor(
        uint256 _subscriptionId,
        address _coordinator,
        bytes32 _keyhash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint16 _refundConfirmations
    ) VRFConsumerBaseV2Plus(_coordinator) {
        COORDINATOR = IVRFCoordinatorV2Plus(_coordinator);
        s_subscriptionId = _subscriptionId;
        keyHash = _keyhash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        refundConfirmations = _refundConfirmations;
        accepted = 1122448;
    }

    error NotApprovedBankroll();

    function getBalance (address tokenAddress, address playerAddress) external view returns (uint256) {
        return balance[tokenAddress][playerAddress];
    }

    function setAccepted (uint256 _value) external onlyOwner {
        // _value from 1% => 5% bankroll pool
        require (_value >= 1000000 && _value <= 5000000, "value is not valid");
        accepted = _value;
    }

    function setNativePayment(bool value) external onlyOwner {
        payingWithNative = value;
    }

    // Assumes the subscription is funded sufficiently.
    function _requestRandomWords(uint32 numWords)
        internal
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        // To enable payment in native tokens, set nativePayment to true.
        requestId = COORDINATOR.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: payingWithNative
                    })
                )
            })
        );
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        handleResult(requestId, randomWords);
    }

    function handleResult(uint256 _requestId, uint256[] memory _randomWords)
        internal
        virtual
    {
        // Override source code to handle result on each games.
    }

    // This function used to transfer out token to House/Bankroll or Winner
    function _transferTo(
        address receiveAddress,
        uint256 wagers,
        address tokenAddress
    ) internal {
        IERC20(tokenAddress).safeTransfer(receiveAddress, wagers);
    }

    function depositToGame(address tokenAddress, uint256 amount) external  {
        if (!Bankroll.getIsValidWager(address(this), tokenAddress)) {
            revert NotApprovedBankroll();
        }
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        balance[tokenAddress][msg.sender] += amount;
    }

    function withdrawAll(address tokenAddress) external  {
        require(
            balance[tokenAddress][msg.sender] > 0,
            "Insufficient balance to withdraw"
        );
        uint256 amount = balance[tokenAddress][msg.sender];
        balance[tokenAddress][msg.sender] = 0;
        _transferTo(
            msg.sender,
            amount,
            tokenAddress
        );
        
    }

    function transferHouseEdge(address receiveAddress)
        external
        onlyOwner
    {
        address[] memory list = Bankroll.getTokenList();
        uint256 length = list.length;

        for (uint256 i; i < length; i++) {
            if (houseEdge[list[i]] != 0) {
                uint256 value = houseEdge[list[i]];
                houseEdge[list[i]] = 0;

                _transferTo(receiveAddress, value, list[i]);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import "./MultiPlayer.sol";

contract XocDia is MultiPlayer, AutomationCompatibleInterface {
    // address public s_forwarderAddress;

    event RoundisOpenNow_EVENT();
    event XocDia_Play_EVENT(
        address playerAddress,
        uint256 wager,
        address tokenAddress,
        bool isOdd
    );
    event XocDia_Round_INFO_Event(
        uint256 id,
        uint256 le,
        uint256 chan,
        uint256 coutdown,
        uint256 lePlayers,
        uint256 chanPlayers
    );
    event XocDia_Take_Balance_EVENT(
        uint256 le,
        uint256 chan,
        uint256 bankrollAccepted
    );
    event XocDia_VRF_Request_EVENT(
        uint8 quan1,
        uint8 quan2,
        uint8 quan3,
        uint8 quan4
    );

    constructor(
        uint256 _subscriptionId,
        address _coordinator,
        bytes32 _keyhash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint16 _refundConfirmations,
        address _bankroll
    )
        MultiPlayer(
            _subscriptionId,
            _coordinator,
            _keyhash,
            _callbackGasLimit,
            _requestConfirmations,
            _refundConfirmations
        )
    {
        Bankroll = IBankRoll(_bankroll);
        lastId = 1;
    }

    uint256 lastId;

    struct Round {
        address tokenAddress;
        uint256 startTime;
        uint8 status;
        uint256 le;
        uint256 chan;
        uint256 bankrollAccepted;
        uint256 requestId;
        uint64 blockNumber;
    }

    struct XocDiaGame {
        uint256 le;
        uint256 chan;
        address tokenAddress;
    }

    struct Result {
        uint8 quan1;
        uint8 quan2;
        uint8 quan3;
        uint8 quan4;
    }

    mapping(uint256 => Round) Rounds;
    mapping(address => XocDiaGame) XocDiaGames;
    mapping(uint256 => Result) Results;
    address[] le;
    address[] chan;

    function XocDia_GetState(address player)
        external
        view
        returns (XocDiaGame memory)
    {
        return (XocDiaGames[player]);
    }

    function getRound(uint256 id)
        external
        view
        returns (Round memory, uint256 time)
    {
        return (Rounds[id], block.timestamp);
    }

    function getTurn()
        external
        view
        returns (
            Round memory,
            uint256 id,
            uint256 time,
            uint256 lePlayers,
            uint256 chanPlayers
        )
    {
        return (
            Rounds[lastId],
            lastId,
            block.timestamp,
            le.length,
            chan.length
        );
    }

    function getResult(uint256 id) external view returns (Result memory) {
        return Results[id];
    }

    function XocDia_Play(
        uint256 wager,
        address tokenAddress,
        bool isOdd
    ) external {
        address msgSender = msg.sender;
        require(
            wager <= balance[tokenAddress][msgSender],
            "Insufficient balance to play"
        );
        require(
            wager >= Bankroll.getMinWager(tokenAddress),
            "Betting is not in range"
        );
        require(
            Rounds[lastId].status < 2,
            "ROUND GAME is closed, waitting for new round"
        );

        if (Rounds[lastId].status == 1) {
            require(
                (block.timestamp - Rounds[lastId].startTime) < 1 minutes,
                "ROUND GAME is closed, waitting for new round"
            );
        }
        if (Rounds[lastId].status == 0) {
            Rounds[lastId].status = 1;
            Rounds[lastId].startTime = block.timestamp;
        }
        
        balance[tokenAddress][msgSender] -= wager;
        Rounds[lastId].tokenAddress = tokenAddress;

        XocDiaGame storage game = XocDiaGames[msgSender];
        game.tokenAddress = tokenAddress;
        if (isOdd) {
            game.le += wager;
            Rounds[lastId].le += wager;
        } else {
            game.chan += wager;
            Rounds[lastId].chan += wager;
        }
        if (!isPlayerListed(isOdd, msgSender)) {
            if (isOdd) le.push(msgSender);
            else chan.push(msgSender);
        }
        if (isOdd)
            emit XocDia_Play_EVENT(msgSender, game.le, tokenAddress, isOdd);
        else emit XocDia_Play_EVENT(msgSender, game.chan, tokenAddress, isOdd);

        emit XocDia_Round_INFO_Event(
            lastId,
            Rounds[lastId].le,
            Rounds[lastId].chan,
            60 - (block.timestamp - Rounds[lastId].startTime),
            le.length,
            chan.length
        );
    }

    function _XocDia_TakeBalance() internal {
        Rounds[lastId].status = 2;
        uint256 poolLiquidity = Bankroll.poolLiquidityOf(
            Rounds[lastId].tokenAddress
        );
        uint256 bankrollAccepted = (poolLiquidity * accepted) / 100000000;

        if (Rounds[lastId].le > Rounds[lastId].chan) {
            if (Rounds[lastId].chan + bankrollAccepted >= Rounds[lastId].le) {
                Rounds[lastId].bankrollAccepted =
                    Rounds[lastId].le -
                    Rounds[lastId].chan;
            } else {
                Rounds[lastId].bankrollAccepted = bankrollAccepted;
                uint256 temple = Rounds[lastId].chan + bankrollAccepted;
                uint256 length = le.length;
                for (uint256 i = 0; i < length; i++) {
                    address _playerAddress = le[i];
                    uint256 tempPlayerBet = (XocDiaGames[_playerAddress].le *
                        temple) / Rounds[lastId].le;
                    balance[Rounds[lastId].tokenAddress][
                        _playerAddress
                    ] += (XocDiaGames[_playerAddress].le - tempPlayerBet);
                    XocDiaGames[_playerAddress].le = tempPlayerBet;
                }
                Rounds[lastId].le = temple;
            }
        } else {
            if (Rounds[lastId].le + bankrollAccepted > Rounds[lastId].chan) {
                Rounds[lastId].bankrollAccepted =
                    Rounds[lastId].chan -
                    Rounds[lastId].le;
            } else {
                Rounds[lastId].bankrollAccepted = bankrollAccepted;
                uint256 tempchan = Rounds[lastId].le + bankrollAccepted;
                uint256 length = chan.length;
                for (uint256 i = 0; i < length; i++) {
                    address _playerAddress = chan[i];
                    uint256 tempPlayerBet = (XocDiaGames[_playerAddress].chan *
                        tempchan) / Rounds[lastId].chan;
                    balance[Rounds[lastId].tokenAddress][
                        _playerAddress
                    ] += (XocDiaGames[_playerAddress].chan - tempPlayerBet);
                    XocDiaGames[_playerAddress].chan = tempPlayerBet;
                }
                Rounds[lastId].chan = tempchan;
            }
        }
        Rounds[lastId].blockNumber = uint64(block.number);
        Rounds[lastId].requestId = _requestRandomWords(4);
        emit XocDia_Take_Balance_EVENT(
            Rounds[lastId].le,
            Rounds[lastId].chan,
            Rounds[lastId].bankrollAccepted
        );
    }

    function _XocDia_Refund() internal {
        Rounds[lastId].status = 5; // Refunding
        uint256 lengthchan = chan.length;
        for (uint256 i = 0; i < lengthchan; i++) {
            address _playerAddress = chan[i];
            balance[XocDiaGames[_playerAddress].tokenAddress][
                _playerAddress
            ] += XocDiaGames[_playerAddress].chan;
            XocDiaGames[_playerAddress].chan = 0;
        }
        uint256 lengthle = le.length;
        for (uint256 j = 0; j < lengthle; j++) {
            address _playerAddress = le[j];
            balance[XocDiaGames[_playerAddress].tokenAddress][
                _playerAddress
            ] += XocDiaGames[_playerAddress].le;
            XocDiaGames[_playerAddress].le = 0;
        }

        delete chan;
        delete le;
        lastId++;
    }

    function handleResult(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // CHECK VALID DATA AREA
        require(
            Rounds[lastId].status == 2,
            "ROUND GAME is not waiting for Chainlink VRF"
        );
        require(
            Rounds[lastId].requestId == requestId,
            "Chainlink VRF is not valid"
        );

        uint8 quan1 = uint8(randomWords[0] % 2);
        uint8 quan2 = uint8(randomWords[1] % 2);
        uint8 quan3 = uint8(randomWords[2] % 2);
        uint8 quan4 = uint8(randomWords[3] % 2);

        Results[lastId] = Result(quan1, quan2, quan3, quan4);

        Rounds[lastId].status = 3;
        emit XocDia_VRF_Request_EVENT(quan1, quan2, quan3, quan4);
    }

    function openBowl() internal {
        Rounds[lastId].status = 4; // Paid for winners.
        Round memory _round = Rounds[lastId];
        address tokenAddress = _round.tokenAddress;
        uint256 payout;
        houseEdge[tokenAddress] +=
            (_round.le + _round.chan + _round.bankrollAccepted) /
            100;

        if (_openBowl(Results[lastId])) {
            uint256 lengthle = le.length;
            for (uint256 j = 0; j < lengthle; j++) {
                address _playerAddress = le[j];
                balance[tokenAddress][_playerAddress] +=
                    (XocDiaGames[_playerAddress].le * 198) /
                    100;
                // Send reward to Refferal.
                address refferal = Bankroll.getRef(_playerAddress);
                if (refferal != address(0)) {
                    balance[tokenAddress][refferal] +=
                        XocDiaGames[_playerAddress].le /
                        1000;
                    houseEdge[tokenAddress] -= XocDiaGames[_playerAddress].le /
                        1000;
                }
                XocDiaGames[_playerAddress].le = 0;
            }
            uint256 lengthchan = chan.length;
            for (uint256 i = 0; i < lengthchan; i++) {
                address _playerAddress = chan[i];
                // Send reward to Refferal.
                address refferal = Bankroll.getRef(_playerAddress);
                if (refferal != address(0)) {
                    balance[tokenAddress][refferal] +=
                        XocDiaGames[_playerAddress].chan /
                        1000;
                    houseEdge[tokenAddress] -= XocDiaGames[_playerAddress].chan /
                        1000;
                }
                XocDiaGames[_playerAddress].chan = 0;
            }
            if (_round.le > _round.chan)
                payout = (_round.bankrollAccepted * 198) / 100;
        } else {
            uint256 lengthchan = chan.length;
            for (uint256 i = 0; i < lengthchan; i++) {
                address _playerAddress = chan[i];
                balance[tokenAddress][_playerAddress] +=
                    (XocDiaGames[_playerAddress].chan * 198) /
                    100;
                // Send reward to Refferal.
                address refferal = Bankroll.getRef(_playerAddress);
                if (refferal != address(0)) {
                    balance[tokenAddress][refferal] +=
                        XocDiaGames[_playerAddress].chan /
                        1000;
                    houseEdge[tokenAddress] -= XocDiaGames[_playerAddress].chan /
                        1000;
                }
                XocDiaGames[_playerAddress].chan = 0;
            }
            uint256 lengthle = le.length;
            for (uint256 j = 0; j < lengthle; j++) {
                address _playerAddress = le[j];
                // Send reward to Refferal.
                address refferal = Bankroll.getRef(_playerAddress);
                if (refferal != address(0)) {
                    balance[tokenAddress][refferal] +=
                        XocDiaGames[_playerAddress].le /
                        1000;
                    houseEdge[tokenAddress] -= XocDiaGames[_playerAddress].le /
                        1000;
                }
                XocDiaGames[_playerAddress].le = 0;
            }
            if (_round.le < _round.chan)
                payout = (_round.bankrollAccepted * 198) / 100;
        }
        if (_round.bankrollAccepted != 0) {
            _transferToBankroll(
                _round.bankrollAccepted,
                _round.tokenAddress,
                payout
            );
        }
        delete chan;
        delete le;
        lastId++; // Start new round.
        emit RoundisOpenNow_EVENT();
    }

    function _openBowl(Result memory mobat) private pure returns (bool) {
        uint8 kqua = mobat.quan1 + mobat.quan2 + mobat.quan3 + mobat.quan4;
        if ((kqua % 2) == 1) return true;
        else return false;
    }

    // Help function: check player is in list le, chan or not.
    function isPlayerListed(bool _isOdd, address playerAddress)
        private
        view
        returns (bool)
    {
        address[] storage players;
        if (_isOdd) players = le;
        else players = chan;
        uint256 length = players.length;
        for (uint256 i = 0; i < length; i++) {
            if (players[i] == playerAddress) {
                return true;
            }
        }
        return false;
    }

    function _transferToBankroll(
        uint256 bankrollAccepted,
        address tokenAddress,
        uint256 payout
    ) private {
        uint256 tax = (bankrollAccepted * 2) / 100;
        uint256 wagersAfterTax = bankrollAccepted - tax;
        _transferTo(address(Bankroll), wagersAfterTax, tokenAddress);
        Bankroll.receiveWager(
            address(this),
            bankrollAccepted,
            tokenAddress,
            wagersAfterTax,
            0,
            payout
        );
    }

    // ================================================================
    // |                    AUTOMATION COMPATIBLE                     |
    // ================================================================
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        // Take_Balance();
        if (
            Rounds[lastId].status == 1 &&
            (block.timestamp - Rounds[lastId].startTime) > 1 minutes
        ) upkeepNeeded = true;
        // Refund ();
        if (
            Rounds[lastId].status == 2 &&
            Rounds[lastId].blockNumber + refundConfirmations <= block.number
        ) upkeepNeeded = true;
        // openBowl ();
        if (Rounds[lastId].status == 3) upkeepNeeded = true;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        // Remove security automation to prevent exceeds 24576 bytes (a limit introduced in Spurious Dragon)
        // Security smartcontract by if condition, dont need to security by forwarderAddress
        // require(
        //     msg.sender == s_forwarderAddress || msg.sender == owner(),
        //     "This address does not have permission to call performUpkeep"
        // );
        if (
            Rounds[lastId].status == 1 &&
            (block.timestamp - Rounds[lastId].startTime) > 1 minutes
        ) _XocDia_TakeBalance();
        if (
            Rounds[lastId].status == 2 &&
            Rounds[lastId].blockNumber + refundConfirmations <= block.number
        ) _XocDia_Refund();
        if (Rounds[lastId].status == 3) openBowl();
    }

    // function setForwarderAddress(address forwarderAddress) external onlyOwner {
    //     s_forwarderAddress = forwarderAddress;
    // }
}