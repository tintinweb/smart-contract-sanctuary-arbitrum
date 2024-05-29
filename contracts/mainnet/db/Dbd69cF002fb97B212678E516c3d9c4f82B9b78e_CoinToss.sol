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
pragma solidity ^0.8.0;

interface IVRFV2PlusWrapper {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _numWords is the number of words to request.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit, uint32 _numWords) external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request in native with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _numWords is the number of words to request.
   */
  function calculateRequestPriceNative(uint32 _callbackGasLimit, uint32 _numWords) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _numWords is the number of words to request.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(
    uint32 _callbackGasLimit,
    uint32 _numWords,
    uint256 _requestGasPriceWei
  ) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request in native with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _numWords is the number of words to request.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPriceNative(
    uint32 _callbackGasLimit,
    uint32 _numWords,
    uint256 _requestGasPriceWei
  ) external view returns (uint256);

  /**
   * @notice Requests randomness from the VRF V2 wrapper, paying in native token.
   *
   * @param _callbackGasLimit is the gas limit for the request.
   * @param _requestConfirmations number of request confirmations to wait before serving a request.
   * @param _numWords is the number of words to request.
   */
  function requestRandomWordsInNative(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords,
    bytes calldata extraArgs
  ) external payable returns (uint256 requestId);

  function link() external view returns (address);
  function linkNativeFeed() external view returns (address);
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
  function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Game} from "./Game.sol";
import {IGameImplementation} from "./interfaces/IGameImplementation.sol";

interface ICoinToss is IGameImplementation {
    /// @notice Emitted after a bet is placed.
    /// @param id The bet ID.
    /// @param receiver Address of the receiver.
    /// @param token Address of the token.
    /// @param amount The bet amount.
    /// @param chargedVRFCost The Chainlink VRF cost paid by player.
    /// @param face The chosen coin face.
    /// @param affiliate Address of the affiliate.
    /// @param betCount How many bets at maximum must be placed.
    /// @param stopGain Profit limit indicating that bets must stop after surpassing it (before deduction of house edge).
    /// @param stopLoss Loss limit indicating that bets must stop after surpassing it (before deduction of house edge).
    event PlaceBet(
        uint256 id,
        address indexed receiver,
        address indexed token,
        uint256 amount,
        uint256 chargedVRFCost,
        bool face,
        address affiliate,
        uint32 betCount,
        uint256 stopGain,
        uint256 stopLoss
    );

    /// @notice Emitted after a bet is rolled.
    /// @param id The bet ID.
    /// @param receiver Address of the receiver.
    /// @param token Address of the token.
    /// @param amount The bet amount.
    /// @param face The chosen coin face.
    /// @param rolled The rolled coin faces.
    /// @param payout The payout amount.
    event Roll(
        uint256 indexed id,
        address indexed receiver,
        address indexed token,
        uint256 amount,
        bool face,
        bool[] rolled,
        uint256 payout
    );

    /// @notice Coin Toss bet information struct.
    /// @param face The chosen coin face.
    /// @param rolled The rolled coin faces.
    struct CoinTossBet {
        bool face;
        bool[] rolled;
    }

    /// @notice Creates multiple bets and stores the chosen coin face.
    /// @param face The chosen coin face.
    /// @param receiver Address of the receiver who will receive the payout.
    /// @param token Address of the token.
    /// @param tokenAmount The amount per bet.
    /// @param affiliate Address of the affiliate.
    /// @param multiBetData Data about multi bet.
    /// @return Bet ID.
    function wager(
        bool face,
        address receiver,
        address token,
        uint256 tokenAmount,
        address affiliate,
        Game.MultiBetData memory multiBetData
    ) external payable returns (uint256);

    function coinTossBets(
        uint256 id
    ) external view returns (CoinTossBet memory);
}

/// @title BetSwirl's Coin Toss game
/// @notice The game is played with a two-sided coin. The game's goal is to guess whether the lucky coin face will be Heads or Tails.
/// @author Romuald Hog (based on Yakitori's Coin Toss)
contract CoinToss is Game, ICoinToss {
    /// @notice Maps bets IDs to chosen and rolled coin faces.
    /// @dev Coin faces: true = Tails, false = Heads.
    mapping(uint256 => CoinTossBet) private _coinTossBets;

    /// @notice Initialize the game base contract.
    /// @param bankAddress The address of the bank.
    /// @param chainlinkCoordinatorAddress Address of the Chainlink VRF Coordinator.
    /// @param chainlinkWrapperAddress Address of the Chainlink VRF Wrapper.
    /// @param wrappedGasToken Address of the wrapped gas token.
    /// @param refundTime  Time to wait before to be refunded.
    constructor(
        address bankAddress,
        address chainlinkCoordinatorAddress,
        address chainlinkWrapperAddress,
        address wrappedGasToken,
        uint64 refundTime
    )
        Game(
            bankAddress,
            chainlinkCoordinatorAddress,
            chainlinkWrapperAddress,
            1,
            wrappedGasToken,
            refundTime
        )
    {}

    /// @notice Decode bytes into face bool.
    /// @param data Bytes to decode.
    /// @return face The decoded chosen face.
    function _decodeBytesToBool(
        bytes calldata data
    ) private pure returns (bool face) {
        (face) = abi.decode(data, (bool));
    }

    /// @notice Calculates the target payout amount.
    /// @param betAmount Bet amount.
    /// @return The target payout amount.
    function _getPayout(uint256 betAmount) private pure returns (uint256) {
        return betAmount * 2;
    }

    /// @notice Calculates the payout based on the randomWord.
    /// @param id Bet ID.
    /// @param betAmount Bet amount.
    /// @param randomWord Random word.
    /// @return rolled The rolled number (0 if heads & 1 if tails).
    /// @return rolledPayout The payout based on the rolled number & the betAmount.
    function _roll(
        uint256 id,
        uint256 betAmount,
        uint256 randomWord
    ) internal view override returns (uint256 rolled, uint256 rolledPayout) {
        bool face = _coinTossBets[id].face;
        rolled = randomWord % 2;
        if ((face && rolled == 1) || (!face && rolled == 0)) {
            rolledPayout = _getPayout(betAmount);
        }
    }

    /// @notice Creates multiple bets and stores the chosen coin face.
    /// @param face The chosen coin face.
    /// @param receiver Address of the receiver who will receive the payout.
    /// @param token Address of the token.
    /// @param tokenAmount The amount per bet.
    /// @param affiliate Address of the affiliate.
    /// @param multiBetData Data about multi bet.
    /// @return Bet ID.
    function wager(
        bool face,
        address receiver,
        address token,
        uint256 tokenAmount,
        address affiliate,
        MultiBetData memory multiBetData
    ) public payable whenNotPaused returns (uint256) {
        (Bet memory bet, uint256 chargedVRFCost) = _newBet(
            token,
            receiver,
            tokenAmount,
            _getPayout(BP_VALUE),
            affiliate,
            multiBetData
        );

        _coinTossBets[bet.id].face = face;

        emit PlaceBet(
            bet.id,
            bet.receiver,
            bet.token,
            bet.amount,
            chargedVRFCost,
            face,
            affiliate,
            multiBetData.betCount,
            multiBetData.stopGain,
            multiBetData.stopLoss
        );
        return bet.id;
    }

    /// @notice Creates mutliple bets and stores the chosen coin face.
    /// @param bet The chosen coin face.
    /// @param receiver Address of the receiver who will receive the payout.
    /// @param token Address of the token.
    /// @param tokenAmount The amount per bet.
    /// @param affiliate Address of the affiliate.
    /// @param multiBetData Data about multi bet.
    /// @return Bet ID.
    function wagerWithData(
        bytes calldata bet,
        address receiver,
        address token,
        uint256 tokenAmount,
        address affiliate,
        MultiBetData memory multiBetData
    ) external payable returns (uint256) {
        return
            wager(
                _decodeBytesToBool(bet),
                receiver,
                token,
                tokenAmount,
                affiliate,
                multiBetData
            );
    }

    /// @notice Resolves the bet using the Chainlink randomness.
    /// @param id The bet ID.
    /// @param randomWords Random words list. Contains only one for this game.
    // solhint-disable-next-line private-vars-leading-underscore
    function fulfillRandomWords(
        uint256 id,
        uint256[] calldata randomWords
    ) internal override {
        CoinTossBet storage coinTossBet = _coinTossBets[id];
        Bet storage bet = bets[id];
        bool[] memory rolledBetsBoolean;
        uint256 payout;
        // Single Bet
        if (bet.betCount == 1) {
            (uint256 rolled, uint256 rolledPayout) = _roll(
                id,
                bet.amount,
                randomWords[0]
            );
            rolledBetsBoolean = new bool[](1);
            rolledBetsBoolean[0] = rolled == 1;
            payout = _resolvePayout(bet, bet.amount, rolledPayout);
        }
        // Multi Bet
        else {
            (uint256 totalPayout, uint256[] memory rolled) = _resolveBets(
                id,
                randomWords[0]
            );
            payout = totalPayout;
            rolledBetsBoolean = new bool[](rolled.length);
            for (uint16 i; i < rolled.length; ) {
                rolledBetsBoolean[i] = rolled[i] == 1;
                unchecked {
                    ++i;
                }
            }
        }
        coinTossBet.rolled = rolledBetsBoolean;
        emit Roll(
            bet.id,
            bet.receiver,
            bet.token,
            bet.amount,
            coinTossBet.face,
            rolledBetsBoolean,
            payout
        );
    }

    function coinTossBets(
        uint256 id
    ) external view returns (CoinTossBet memory) {
        return _coinTossBets[id];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IBankGame} from "./interfaces/IBank.sol";
import {IGame, IVRFV2PlusWrapperCustom} from "./interfaces/IGame.sol";
import {IWrapped} from "../shared/interfaces/IWrapped.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @title Game base contract
/// @author Romuald Hog
/// @notice This should be parent contract of each games.
/// It defines all the games common functions and state variables.
/// @dev All rates are in basis point. Chainlink VRF v2.5 is used.
abstract contract Game is
    Pausable,
    VRFConsumerBaseV2Plus,
    ReentrancyGuard,
    IGame
{
    using SafeERC20 for IERC20;

    /// @notice Chainlink VRF configuration state.
    ChainlinkConfig private _chainlinkConfig;

    /// @notice Maps bets IDs to Bet information.
    mapping(uint256 => Bet) public bets;

    /// @notice Maps tokens addresses to token configuration.
    mapping(address => Token) public tokens;

    /// @notice Affiliate's house edge rates (token => affiliate => house edge).
    mapping(address => mapping(address => uint16)) public _affiliateHouseEdges;

    /// @notice The bank that manage to payout a won bet and collect a loss bet.
    IBankGame public immutable bank;

    /// @notice Set the wrapped token in case of transfer issue
    IWrapped public immutable wrapped;

    /// @notice Time to wait before to be refunded
    uint64 public immutable refundTime;

    uint256 internal constant BP_VALUE = 10_000;
    uint256 private constant MAX_HOUSE_EDGE = 1000;

    /// @notice Extra gas consumed in VRF callack that is used in addition to a single bet. This is independent of the betCount and token used.
    uint32 private constant EXTRA_MULTIBET_GAS = 5500;

    /// @notice Minimum extra VRF fees received in wager to refund the user. It is a little more than an ETH transfer.
    uint256 private constant MIN_VRF_EXTRA_FEE_REFUNDED = 22_000;

    /// @notice Initialize contract's state variables and VRF Consumer.
    /// @param bankAddress The address of the bank.
    /// @param chainlinkCoordinatorAddress Address of the Chainlink VRF Coordinator.
    /// @param chainlinkWrapperAddress Chainlink Wrapper used to estimate the VRF cost.
    /// @param numRandomWords How many random words is needed to resolve a game's bet.
    /// @param wrappedGasToken Address of the wrapped gas token.
    /// @param refundTime_  Time to wait before to be refunded.
    constructor(
        address bankAddress,
        address chainlinkCoordinatorAddress,
        address chainlinkWrapperAddress,
        uint16 numRandomWords,
        address wrappedGasToken,
        uint64 refundTime_
    ) VRFConsumerBaseV2Plus(chainlinkCoordinatorAddress) {
        if (
            chainlinkWrapperAddress == address(0) ||
            chainlinkCoordinatorAddress == address(0) ||
            bankAddress == address(0)
        ) {
            revert InvalidAddress();
        }
        require(
            numRandomWords != 0 && numRandomWords <= 500,
            "Wrong Chainlink NumRandomWords"
        );
        // 12h to 30d
        require(
            refundTime_ >= 43_200 && refundTime_ <= 2_592_000,
            "refundTime must be between 12 hours & 30 days"
        );

        bank = IBankGame(bankAddress);
        wrapped = IWrapped(wrappedGasToken);
        _chainlinkConfig.numRandomWords = numRandomWords;
        _chainlinkConfig.chainlinkWrapper = IVRFV2PlusWrapperCustom(
            chainlinkWrapperAddress
        );
        refundTime = refundTime_;
    }

    /// @notice Calculates the amount's fee based on the house edge.
    /// @param token Address of the token.
    /// @param amount From which the fee amount will be calculated.
    /// @param affiliate Address of the affiliate.
    /// @return The fee amount.
    function _getFees(
        address token,
        uint256 amount,
        address affiliate
    ) private view returns (uint256) {
        return (getAffiliateHouseEdge(affiliate, token) * amount) / BP_VALUE;
    }

    /// @notice Get the affiliate's house edge. If the affiliate has not their own house edge,
    /// then it takes the default house edge.
    /// @param affiliate Address of the affiliate.
    /// @param token Address of the token.
    /// @return The affiliate's house edge.
    function getAffiliateHouseEdge(
        address affiliate,
        address token
    ) public view returns (uint16) {
        uint16 affiliateHouseEdge = _affiliateHouseEdges[token][affiliate];
        return
            affiliateHouseEdge == 0
                ? tokens[token].houseEdge
                : affiliateHouseEdge;
    }

    /// @notice Creates a new bet and request randomness to Chainlink,
    /// transfer the ERC20 tokens to the contract or refund the bet amount overflow if the bet amount exceed the maxBetAmount.
    /// @param tokenAddress_ Address of the token (zero address if gas token).
    /// @param receiver Address of the receiver.
    /// @param tokenAmount The token amount bet.
    /// @param multiplier The bet amount leverage determines the user's profit amount. 10000 = 100% = no profit.
    /// @param affiliate Address of the affiliate.
    /// @return newbet A new Bet struct information.
    /// @dev msg.value must always contain the VRF cost.
    /// If the bet is made in gas token, then tokenAddress must be equal to zero address and msg.value must be equal to tokenAmount + VRF cost.
    /// The user is the address who receives the payout. Only msg.sender pays the bet amount and VRF fees.
    /// tokenAmount can now be lower than 10,000. In the worst case, the user's gains are rounded down, and the bank receives no fees.
    function _newBet(
        address tokenAddress_,
        address receiver,
        uint256 tokenAmount,
        uint256 multiplier,
        address affiliate,
        IGame.MultiBetData memory multiBetData
    )
        internal
        whenNotPaused
        nonReentrant
        returns (Bet memory newbet, uint256 chargedVRFCost)
    {
        if (affiliate == address(0)) revert InvalidAddress();
        uint16 betCount = multiBetData.betCount;
        if (betCount == 0) revert InvalidBetCount();
        if (tokenAmount == 0) revert UnderMinBetAmount(1);

        // Stack too deep fix
        address tokenAddress = tokenAddress_;

        bool isGasToken = address(0) == tokenAddress;

        Token storage token = tokens[tokenAddress];

        {
            (bool isAllowedToken, uint256 maxBetAmount) = bank
                .getBetRequirements(tokenAddress, multiplier);

            if (!isAllowedToken || token.houseEdge == 0) {
                revert ForbiddenToken();
            }

            if (tokenAmount > maxBetAmount) {
                if (isGasToken) {
                    Address.sendValue(
                        payable(msg.sender),
                        // excess gas token sent
                        (tokenAmount - maxBetAmount) * betCount
                    );
                }
                tokenAmount = maxBetAmount;
            }
        }

        chargedVRFCost = isGasToken
            ? msg.value - tokenAmount * betCount
            : msg.value;
        {
            // Charge sender for Chainlink VRF fee.
            uint256 chainlinkVRFCost = getChainlinkVRFCost(
                tokenAddress,
                betCount
            );
            if (chargedVRFCost < chainlinkVRFCost) {
                revert WrongGasValueToCoverFee();
            }
            uint256 extraVRFFees = chargedVRFCost - chainlinkVRFCost;
            // Refund if user sent too much VRF fee
            if (extraVRFFees > MIN_VRF_EXTRA_FEE_REFUNDED * tx.gasprice) {
                Address.sendValue(payable(msg.sender), extraVRFFees);
                chargedVRFCost -= extraVRFFees;
            }
            unchecked {
                token.VRFFees += chargedVRFCost;
            }
        }

        // Create bet
        uint256 id = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: _chainlinkConfig.keyHash,
                subId: token.vrfSubId,
                requestConfirmations: _chainlinkConfig.requestConfirmations,
                callbackGasLimit: _getCallbackGasLimit(tokenAddress, betCount),
                numWords: _chainlinkConfig.numRandomWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: _chainlinkConfig.nativePayment
                    })
                )
            })
        );

        newbet = Bet(
            false,
            receiver,
            tokenAddress,
            id,
            tokenAmount,
            uint32(block.timestamp),
            0,
            betCount,
            multiBetData.stopGain,
            multiBetData.stopLoss,
            affiliate
        );
        bets[id] = newbet;

        unchecked {
            ++token.pendingCount;
        }

        // Get the ERC20 tokens from the caller
        if (!isGasToken) {
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmount * betCount
            );
        }
    }

    function _roll(
        uint256 id,
        uint256 amount,
        uint256 randomWord
    ) internal view virtual returns (uint256, uint256);

    /// @notice Resolves multi bets taking into account the stopGain and stopLoss. It is a wrapped above _resolvePayout function.
    /// @param betId The bet id.
    /// @param randomSeed The VRF random seed. It derives a randomWord for each bet based on this randomSeed.
    /// @return payout The payout amount.
    /// @return rolledValues The rolled values in common format (uint256).
    /// @dev Should not revert as it resolves the bet with the randomness.
    function _resolveBets(
        uint256 betId,
        uint256 randomSeed
    ) internal returns (uint256 payout, uint256[] memory rolledValues) {
        Bet storage bet = bets[betId];

        uint256 cumulatedPayout;
        uint256 cumulatedBetAmount;
        uint16 betCount = bet.betCount;
        uint256 betAmount = bet.amount;
        rolledValues = new uint256[](betCount);

        uint256 stopGain = bet.stopGain;
        uint256 stopLoss = bet.stopLoss;
        uint16 rollCount = 0;
        do {
            cumulatedBetAmount += betAmount;

            // Compute random word here instead if in VRF Coordinator to avoid waste some gas if stopGain/stopLoss are triggered before the end
            (uint256 rolled, uint256 rolledPayout) = _roll(
                betId,
                betAmount,
                uint256(keccak256(abi.encode(randomSeed, rollCount)))
            );
            rolledValues[rollCount] = rolled;
            unchecked {
                ++rollCount;
            }

            cumulatedPayout += rolledPayout;
        } while (
            rollCount < betCount &&
                // Check if stopGain & stopLoss are triggered
                !((stopGain > 0 &&
                    cumulatedPayout >= stopGain + cumulatedBetAmount) ||
                    (stopLoss > 0 &&
                        cumulatedBetAmount >= stopLoss + cumulatedPayout))
        );

        // Shorten the array if needed (when stopGain/stopLoss has been triggered)
        if (rollCount < betCount) {
            assembly {
                mstore(rolledValues, rollCount)
            }
        }
        payout = _resolvePayout(bet, cumulatedBetAmount, cumulatedPayout);
    }

    /// @notice Resolves the bet based on the game child contract result.
    /// In case bet is won, the bet amount minus the house edge is transfered to user from the game contract, and the profit is transfered to the user from the Bank.
    /// In case bet is lost, the bet amount is transfered to the Bank from the game contract.
    /// @param bet The Bet struct information.
    /// @param totalBetAmount The total bet amount (betAmount * rolled betCount). If stopLoss or stopGain has been triggered,
    /// it means the value may be lower than the amount taken in wager tx.
    /// @param payout What should be sent to the user in case of a won bet. Payout = bet amount + profit amount.
    /// @return The payout amount.
    /// @dev Should not revert as it resolves the bet with the randomness.
    function _resolvePayout(
        Bet storage bet,
        uint256 totalBetAmount,
        uint256 payout
    ) internal returns (uint256) {
        if (bet.resolved == true || bet.id == 0) {
            revert NotPendingBet();
        }
        bet.resolved = true;

        address tokenAddress = bet.token;
        Token storage token = tokens[tokenAddress];
        unchecked {
            --token.pendingCount;
        }

        // We may refund amount if bets have been stopped via stopLoss or stopGain
        uint256 refundAmount = bet.amount * bet.betCount - totalBetAmount;
        bool isGasToken = tokenAddress == address(0);
        address affiliate = bet.affiliate;
        if (payout > totalBetAmount) {
            // The receiver has won more than his bet

            address receiver = bet.receiver;
            uint256 profit = payout - totalBetAmount;
            uint256 betAmountFee = _getFees(
                tokenAddress,
                totalBetAmount,
                affiliate
            );
            uint256 profitFee = _getFees(tokenAddress, profit, affiliate);
            uint256 fee = betAmountFee + profitFee;

            payout -= fee;

            uint256 betAmountPayout = totalBetAmount -
                betAmountFee +
                refundAmount;

            // Transfer the payout from the bank, the bet amount fee to the bank, and account fees.
            if (!isGasToken)
                IERC20(tokenAddress).safeTransfer(address(bank), betAmountFee);

            bank.payout{value: isGasToken ? betAmountFee : 0}(
                receiver,
                tokenAddress,
                profit - profitFee, // profitPayout
                fee,
                affiliate
            );
            // Transfer the bet amount payout to the player
            if (isGasToken) _safeNativeTransfer(receiver, betAmountPayout);
            else IERC20(tokenAddress).safeTransfer(receiver, betAmountPayout);
        } else if (payout > 0) {
            // The receiver has won something smaller than his bet
            uint256 fee = _getFees(tokenAddress, payout, affiliate);
            payout -= fee;
            uint256 bankCashIn = totalBetAmount - payout;
            uint256 betAmountPayout = payout + refundAmount;

            // Transfer the bet amount payout to the player
            if (isGasToken) _safeNativeTransfer(bet.receiver, betAmountPayout);
            else
                IERC20(tokenAddress).safeTransfer(
                    bet.receiver,
                    betAmountPayout
                );

            // Transfer the lost bet amount and fee to the bank
            if (!isGasToken && bankCashIn > 0) {
                IERC20(tokenAddress).safeTransfer(address(bank), bankCashIn);
            }
            bank.cashIn{value: isGasToken ? bankCashIn : 0}(
                tokenAddress,
                bankCashIn,
                fee,
                affiliate
            );
        } else {
            // The receiver did not win anything

            if (refundAmount > 0) {
                if (isGasToken) {
                    _safeNativeTransfer(bet.receiver, refundAmount);
                } else {
                    IERC20(tokenAddress).safeTransfer(
                        address(bet.receiver),
                        refundAmount
                    );
                }
            }
            if (!isGasToken) {
                IERC20(tokenAddress).safeTransfer(
                    address(bank),
                    totalBetAmount
                );
            }
            bank.cashIn{value: isGasToken ? totalBetAmount : 0}(
                tokenAddress,
                totalBetAmount,
                0,
                affiliate
            );
        }

        bet.payout = payout;
        return payout;
    }

    function _safeNativeTransfer(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");

        if (!success) {
            // Fallback to wrapped gas token in case of error
            wrapped.deposit{value: amount}();
            wrapped.transfer(recipient, amount);
        }
    }

    /// @notice Sets the game house edge rate for a specific token.
    /// @param token Address of the token.
    /// @param houseEdge House edge rate.
    function setHouseEdge(address token, uint16 houseEdge) external onlyOwner {
        if (hasPendingBets(token)) {
            revert TokenHasPendingBets();
        }
        if (houseEdge > MAX_HOUSE_EDGE) {
            revert HouseEdgeTooHigh();
        }
        tokens[token].houseEdge = houseEdge;
        emit SetHouseEdge(token, houseEdge);
    }

    /// @notice Sets the game affiliate's house edge rate for a specific token.
    /// @param token Address of the token.
    /// @param affiliateHouseEdge Affiliate's house edge rate.
    /// @dev The msg.sender of the tx is considered as to be the affiliate.
    function setAffiliateHouseEdge(
        address token,
        uint16 affiliateHouseEdge
    ) external {
        uint16 defaultHouseEdge = tokens[token].houseEdge;
        if (defaultHouseEdge == 0) {
            revert AccessDenied();
        }
        if (affiliateHouseEdge < defaultHouseEdge) {
            revert HouseEdgeTooLow();
        }
        if (affiliateHouseEdge > MAX_HOUSE_EDGE) {
            revert HouseEdgeTooHigh();
        }
        if (hasPendingBets(token)) {
            revert TokenHasPendingBets();
        }
        address affiliate = msg.sender;
        _affiliateHouseEdges[token][affiliate] = affiliateHouseEdge;
        emit SetAffiliateHouseEdge(token, affiliate, affiliateHouseEdge);
    }

    /// @notice Pauses the contract to disable new bets.
    function pause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /// @notice Sets the Chainlink VRF subscription ID for a specific token.
    /// @param token Address of the token.
    /// @param subId Subscription ID.
    function setVRFSubId(address token, uint256 subId) external onlyOwner {
        tokens[token].vrfSubId = subId;
        emit SetVRFSubId(token, subId);
    }

    /// @notice Sets the Chainlink VRF V2.5 configuration.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    /// @param chainlinkWrapper Chainlink Wrapper used to estimate the VRF cost.
    /// @param VRFCallbackGasExtraBet Callback gas to be added for each bet while multi betting.
    /// @param nativePayment Whether Betswirl pays VRF fees in gas token or in LINK token.
    function setChainlinkConfig(
        uint16 requestConfirmations,
        bytes32 keyHash,
        IVRFV2PlusWrapperCustom chainlinkWrapper,
        uint32 VRFCallbackGasExtraBet,
        bool nativePayment
    ) external onlyOwner {
        _chainlinkConfig.requestConfirmations = requestConfirmations;
        _chainlinkConfig.keyHash = keyHash;
        _chainlinkConfig.chainlinkWrapper = chainlinkWrapper;
        _chainlinkConfig.VRFCallbackGasExtraBet = VRFCallbackGasExtraBet;
        _chainlinkConfig.nativePayment = nativePayment;

        emit SetChainlinkConfig(
            requestConfirmations,
            keyHash,
            chainlinkWrapper,
            VRFCallbackGasExtraBet,
            nativePayment
        );
    }

    /// @notice Sets the Chainlink VRF V2.5 configuration.
    /// @param callbackGasBase How much gas is needed in the Chainlink VRF callback.
    function setVRFCallbackGasBase(
        address token,
        uint32 callbackGasBase
    ) external onlyOwner {
        tokens[token].VRFCallbackGasBase = callbackGasBase;
        emit SetVRFCallbackGasBase(token, callbackGasBase);
    }

    /// @notice Refunds the bet to the receiver if the Chainlink VRF callback failed.
    /// @param id The Bet ID.
    function refundBet(uint256 id) external {
        Bet storage bet = bets[id];
        if (bet.resolved == true || bet.id == 0) {
            revert NotPendingBet();
        } else if (block.timestamp < bet.timestamp + refundTime) {
            revert NotFulfilled();
        }

        Token storage token = tokens[bet.token];
        unchecked {
            token.pendingCount--;
        }

        bet.resolved = true;
        bet.payout = bet.amount * bet.betCount;
        if (bet.token == address(0)) {
            _safeNativeTransfer(payable(bet.receiver), bet.payout);
        } else {
            IERC20(bet.token).safeTransfer(bet.receiver, bet.payout);
        }

        emit BetRefunded(id, bet.receiver, bet.payout);
    }

    /// @notice Distributes the token's collected Chainlink fees.
    /// @param token Address of the token.
    function withdrawTokenVRFFees(address token) external {
        uint256 tokenChainlinkFees = tokens[token].VRFFees;
        if (tokenChainlinkFees != 0) {
            delete tokens[token].VRFFees;
            s_vrfCoordinator.fundSubscriptionWithNative{
                value: tokenChainlinkFees
            }(tokens[token].vrfSubId);
            emit DistributeTokenVRFFees(token, tokenChainlinkFees);
        }
    }

    /// @notice Allow the contract to receive gas token
    /// @dev Used to withdraw wrapped gas token
    receive() external payable {}

    /// @notice Returns the Chainlink VRF config.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    /// @param chainlinkCoordinator Reference to the VRFCoordinatorV2Plus deployed contract.
    /// @param chainlinkWrapper Reference to the VRFV2PlusWrapper deployed contract.
    /// @param VRFCallbackGasExtraBet Callback gas to be added for each bet while multi betting.
    function getChainlinkConfig()
        external
        view
        returns (
            uint16 requestConfirmations,
            bytes32 keyHash,
            IVRFCoordinatorV2Plus chainlinkCoordinator,
            IVRFV2PlusWrapperCustom chainlinkWrapper,
            uint32 VRFCallbackGasExtraBet,
            bool nativePayment
        )
    {
        return (
            _chainlinkConfig.requestConfirmations,
            _chainlinkConfig.keyHash,
            s_vrfCoordinator,
            _chainlinkConfig.chainlinkWrapper,
            _chainlinkConfig.VRFCallbackGasExtraBet,
            _chainlinkConfig.nativePayment
        );
    }

    /// @notice Returns whether the token has pending bets.
    /// @return Whether the token has pending bets.
    function hasPendingBets(address token) public view returns (bool) {
        return tokens[token].pendingCount != 0;
    }

    /// @notice Returns the amount of ETH that should be passed to the wager transaction.
    /// to cover Chainlink VRF fee.
    /// @param token Address of the token.
    /// @param betCount The number of bets to place.
    /// @return The bet resolution cost amount.
    /// @dev The user always pays VRF fees in gas token, whatever we pay in gas token or in LINK on our side.
    function getChainlinkVRFCost(
        address token,
        uint16 betCount
    ) public view returns (uint256) {
        IVRFV2PlusWrapperCustom chainlinkWrapper = _chainlinkConfig
            .chainlinkWrapper;
        (, , , , uint256 wrapperGasOverhead, , , , , , , ) = chainlinkWrapper
            .getConfig();
        uint256 gas = block.basefee == 0 ? tx.gasprice : block.basefee;
        return
            chainlinkWrapper.estimateRequestPriceNative(
                _getCallbackGasLimit(token, betCount),
                _chainlinkConfig.numRandomWords,
                gas
            ) - (gas * wrapperGasOverhead);
    }

    /// @notice Calculate the total callback gas limit based on the token + betCount.
    /// @param token Address of the token.
    /// @param betCount The number of bets to place.
    /// @return The total VRF callback gas limit.
    /// @dev The first bet is already included in the VRFCallbackGasBase.
    function _getCallbackGasLimit(
        address token,
        uint16 betCount
    ) private view returns (uint32) {
        return
            tokens[token].VRFCallbackGasBase +
            (
                betCount > 1
                    ? betCount *
                        _chainlinkConfig.VRFCallbackGasExtraBet +
                        EXTRA_MULTIBET_GAS
                    : 0
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

/// @notice Defines affiliate functionalities, essentially withdrawing house edge amount.
interface IBankAffiliate {
    /// @notice Emitted after the token's affiliate allocation is distributed.
    /// @param token Address of the token.
    /// @param affiliate Address of the affiliate.
    /// @param affiliateAmount The number of tokens sent to the affiliate.
    event HouseEdgeAffiliateDistribution(
        address indexed token,
        address affiliate,
        uint256 affiliateAmount
    );

    /// @notice Distributes the token's affiliate amount.
    /// @param tokenAddress Address of the token.
    /// @param affiliate Address of the affiliate.
    function withdrawAffiliateAmount(
        address tokenAddress,
        address affiliate
    ) external;
}

/// @notice Defines administrative functionalities.
interface IBankAdmin {
    /// @notice Emitted after the team wallet is set.
    /// @param teamWallet The team wallet address.
    event SetTeamWallet(address teamWallet);

    /// @notice Emitted after a token is added.
    /// @param token Address of the token.
    event AddToken(address token);

    /// @notice Emitted after the token's house edge allocations for bet payout is set.
    /// @param token Address of the token.
    /// @param bank Rate to be allocated to the bank, on bet payout.
    /// @param dividend Rate to be allocated as staking rewards, on bet payout.
    /// @param affiliate Rate to be allocated to the affiliate, on bet payout.
    /// @param treasury Rate to be allocated to the treasury, on bet payout.
    /// @param team Rate to be allocated to the team, on bet payout.
    event SetTokenHouseEdgeSplit(
        address indexed token,
        uint16 bank,
        uint16 dividend,
        uint16 affiliate,
        uint16 treasury,
        uint16 team
    );

    /// @notice Emitted after a token is allowed.
    /// @param token Address of the token.
    /// @param allowed Whether the token is allowed for betting.
    event SetAllowedToken(address indexed token, bool allowed);

    /// @notice Emitted after the token's treasury and team allocations are distributed.
    /// @param token Address of the token.
    /// @param treasuryAmount The number of tokens sent to the treasury.
    /// @param teamAmount The number of tokens sent to the team.
    event HouseEdgeDistribution(
        address indexed token,
        uint256 treasuryAmount,
        uint256 teamAmount
    );

    /// @notice Emitted after the token's dividend allocation is distributed.
    /// @param token Address of the token.
    /// @param amount The number of tokens sent to the Harvester.
    event HarvestDividend(address indexed token, uint256 amount);

    /// @notice Token's house edge allocations & splits struct.
    /// The games house edge is divided into several allocations and splits.
    /// The allocated amounts stays in the bank until authorized parties withdraw. They are subtracted from the balance.
    /// @param bank Rate to be allocated to the bank, on bet payout.
    /// @param dividend Rate to be allocated as staking rewards, on bet payout.
    /// @param affiliate Rate to be allocated to the affiliate, on bet payout.
    /// @param treasury Rate to be allocated to the treasury, on bet payout.
    /// @param team Rate to be allocated to the team, on bet payout.
    /// @param dividendAmount The number of tokens to be sent as staking rewards.
    /// @param affiliateAmount The total number of tokens to be sent to the affiliates.
    /// @param treasuryAmount The number of tokens to be sent to the treasury.
    /// @param teamAmount The number of tokens to be sent to the team.
    struct HouseEdgeSplitAndAllocation {
        uint16 bank;
        uint16 dividend;
        uint16 affiliate;
        uint16 treasury;
        uint16 team;
        uint256 dividendAmount;
        uint256 affiliateAmount;
        uint256 treasuryAmount;
        uint256 teamAmount;
    }
    /// @notice Token struct.
    /// List of tokens to bet on games.
    /// @param allowed Whether the token is allowed for bets.
    /// @param paused Whether the token is paused for bets.
    /// @param balanceRisk Defines the maximum bank payout, used to calculate the max bet amount.
    /// @param bankrollProvider Address of the bankroll manager to manage the token.
    /// @param pendingBankrollProvider Address of the elected new bankroll manager during transfer
    /// @param houseEdgeSplit House edge allocations.
    struct Token {
        bool allowed;
        bool paused;
        uint16 balanceRisk;
        address bankrollProvider;
        address pendingBankrollProvider;
        HouseEdgeSplitAndAllocation houseEdgeSplitAndAllocation;
    }

    /// @notice Token's metadata struct. It contains additional information from the ERC20 token.
    /// @dev Only used on the `getTokens` getter for the front-end.
    /// @param decimals Number of token's decimals.
    /// @param tokenAddress Contract address of the token.
    /// @param name Name of the token.
    /// @param symbol Symbol of the token.
    /// @param token Token data.
    struct TokenMetadata {
        uint8 decimals;
        address tokenAddress;
        string name;
        string symbol;
        Token token;
    }

    /// @notice Adds a new token that'll be visible for the games' betting.
    /// Token shouldn't exist yet.
    /// @param token Address of the token.
    function addToken(address token) external;

    /// @notice Changes the token's bet permission.
    /// @param token Address of the token.
    /// @param allowed Whether the token is enabled for bets.
    function setAllowedToken(address token, bool allowed) external;

    /// @notice Sets the token's house edge allocations for bet payout.
    /// @param token Address of the token.
    /// @param bank Rate to be allocated to the bank, on bet payout.
    /// @param dividend Rate to be allocated as staking rewards, on bet payout.
    /// @param affiliate Rate to be allocated to the affiliate, on bet payout.
    /// @param treasury Rate to be allocated to the treasury, on bet payout.
    /// @param team Rate to be allocated to the team, on bet payout.
    /// @dev `bank`, `dividend`, `treasury` and `team` rates sum must equals 10000.
    function setHouseEdgeSplit(
        address token,
        uint16 bank,
        uint16 dividend,
        uint16 affiliate,
        uint16 treasury,
        uint16 team
    ) external;

    /// @notice Harvests token dividends.
    /// @param tokenAddress Address of the token.
    function harvestDividend(address tokenAddress) external;

    /// @notice Harvests all tokens dividends.
    function harvestDividends() external;

    /// @notice Sets the new team wallet.
    /// @param _teamWallet The team wallet address.
    function setTeamWallet(address _teamWallet) external;

    /// @notice Distributes the token's treasury and team allocations amounts.
    /// @param tokenAddress Address of the token.
    function withdrawHouseEdgeAmount(address tokenAddress) external;

    /// @notice Calculates the max bet amount based on the token balance, the balance risk, and the game multiplier.
    /// @param token Address of the token.
    /// @param multiplier The bet amount leverage determines the user's profit amount. 10000 = 100% = no profit.
    /// @return Maximum bet amount for the token.
    /// @dev The multiplier should be at least 10000 in theory.
    function getMaxBetAmount(
        address token,
        uint256 multiplier
    ) external view returns (uint256);

    /// @notice Reverting error when trying to add an existing token.
    error TokenExists();

    /// @notice Reverting error when setting the house edge allocations, but the sum isn't 100%.
    /// @param splitSum Sum of the house edge allocations rates.
    error WrongHouseEdgeSplit(uint16 splitSum);

    /// @notice Reverting error when team wallet or treasury is the zero address.
    error InvalidAddress();
}

/// @notice Defines bankroll provider functionalities.
interface IBankBankrollProvider {
    /// @notice Emitted after the balance risk is set.
    /// @param balanceRisk Rate defining the balance risk.
    event SetBalanceRisk(address indexed token, uint16 balanceRisk);

    /// @notice Emitted after a token is paused.
    /// @param token Address of the token.
    /// @param paused Whether the token is paused for betting.
    event SetPausedToken(address indexed token, bool paused);

    /// @notice Emitted after a token deposit.
    /// @param token Address of the token.
    /// @param amount The number of token deposited.
    event Deposit(address indexed token, uint256 amount);

    /// @notice Emitted after a token withdrawal.
    /// @param token Address of the token.
    /// @param amount The number of token withdrawn.
    /// @param to who gets the funds.
    event Withdraw(address indexed token, uint256 amount, address indexed to);

    /// @notice emitted when starting a token's bankroll manager transfer
    event TokenBankrollProviderTransferStarted(
        address token,
        address newBankrollProvider
    );
    /// @notice emitted when accepting a token's bankroll manager transfer
    event TokenBankrollProviderTransferAccepted(
        address token,
        address newBankrollProvider
    );

    /// @notice Deposit funds in the bank to allow gamers to win more.
    /// ERC20 token allowance should be given prior to deposit.
    /// @param token Address of the token.
    /// @param amount Number of tokens.
    function deposit(address token, uint256 amount) external payable;

    /// @notice Withdraw funds from the bank. Token has to be paused and no pending bet resolution on games.
    /// @param token Address of the token.
    /// @param amount Number of tokens.
    function withdraw(address token, uint256 amount) external;

    /// @notice Sets the new token balance risk.
    /// @param token Address of the token.
    /// @param balanceRisk Risk rate.
    function setBalanceRisk(address token, uint16 balanceRisk) external;

    /// @notice Changes the token's paused status.
    /// @param token Address of the token.
    /// @param paused Whether the token is paused.
    function setPausedToken(address token, bool paused) external;

    /// @notice Gets the token's bankrollProvider.
    /// @param token Address of the token.
    /// @return Address of the bankrollProvider.
    function getBankrollProvider(address token) external view returns (address);

    /// @notice starts a token's bankroll manager transfer
    /// @param token address to tranfer
    /// @param to sets the new bankroll manager
    function startTokenBankrollProviderTransfer(
        address token,
        address to
    ) external;

    /// @notice accepts a token's bankrollProvider transfer
    /// @param token address to tranfer
    function acceptTokenBankrollProviderTransfer(address token) external;

    /// @notice Reverting error when param is not valid or not in range
    error InvalidParam();

    /// @notice Reverting error when sender isn't allowed.
    error AccessDenied();

    /// @notice Reverting error when withdrawing a non paused token.
    error TokenNotPaused();

    /// @notice Reverting error when token has pending bets on a game.
    error TokenHasPendingBets();
}

/// @notice Defines functionalities used by game contracts.
interface IBankGame {
    /// @notice Emitted after the token's house edge is allocated.
    /// @param token Address of the token.
    /// @param bank The number of tokens allocated to bank.
    /// @param dividend The number of tokens allocated as staking rewards.
    /// @param treasury The number of tokens allocated to the treasury.
    /// @param team The number of tokens allocated to the team.
    /// @param affiliate The number of tokens allocated to the affiliate.
    /// @param affiliateAddress The address of the affiliate.
    event AllocateHouseEdgeAmount(
        address indexed token,
        uint256 bank,
        uint256 dividend,
        uint256 treasury,
        uint256 team,
        uint256 affiliate,
        address affiliateAddress
    );

    /// @notice Emitted after the bet profit amount is sent to the user.
    /// @param token Address of the token.
    /// @param newBalance New token balance.
    /// @param profit Bet profit amount sent.
    event Payout(address indexed token, uint256 newBalance, uint256 profit);

    /// @notice Emitted after the bet amount is collected from the game smart contract.
    /// @param token Address of the token.
    /// @param newBalance New token balance.
    /// @param amount Bet amount collected.
    event CashIn(address indexed token, uint256 newBalance, uint256 amount);

    /// @notice Payouts a winning bet, and allocate the house edge fee.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param profit Number of tokens to be sent to the gamer.
    /// @param fees Bet amount and bet profit fees amount.
    /// @param affiliate Address of the affiliate
    function payout(
        address user,
        address token,
        uint256 profit,
        uint256 fees,
        address affiliate
    ) external payable;

    /// @notice Accounts a loss bet.
    /// @dev In case of an ERC20, the bet amount should be transfered prior to this tx.
    /// @dev In case of the gas token, the bet amount is sent along with this tx.
    /// @param tokenAddress Address of the token.
    /// @param amount Loss bet amount.
    /// @param fees Bet amount and bet profit fees amount.
    /// @param affiliate Address of the affiliate
    function cashIn(
        address tokenAddress,
        uint256 amount,
        uint256 fees,
        address affiliate
    ) external payable;

    /// @notice Calculates the max bet amount based on the token balance, the balance risk, and the game multiplier.
    /// @param tokenAddress Address of the token.
    /// @param multiplier The bet amount leverage determines the user's profit amount. 10000 = 100% = no profit.
    /// @notice Gets the token's min bet amount.
    /// @return isAllowedToken Whether the token is enabled for bets.
    /// @return maxBetAmount Maximum bet amount for the token.
    /// @dev The min bet amount should be at least 10000 cause of the `getMaxBetAmount` calculation.
    /// @dev The multiplier should be at least 10000 in theory.
    function getBetRequirements(
        address tokenAddress,
        uint256 multiplier
    ) external view returns (bool isAllowedToken, uint256 maxBetAmount);
}

/// @notice Aggregates all functionalities from IBankAdmin, IBankBankrollProvider, IBankGame, IBankAffiliate & IAccessControlEnumerable interfaces.
interface IBank is
    IBankAdmin,
    IBankBankrollProvider,
    IBankGame,
    IBankAffiliate,
    IAccessControlEnumerable
{
    /// @dev For the front-end
    function getTokens() external view returns (TokenMetadata[] memory);

    /// @notice Gets the token's balance.
    /// The token's house edge allocation amounts are subtracted from the balance.
    /// @param token Address of the token.
    /// @return The amount of token available for profits.
    function getBalance(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IVRFV2PlusWrapper} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFV2PlusWrapper.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {IVRFMigratableConsumerV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFMigratableConsumerV2Plus.sol";
import {IOwnable} from "@chainlink/contracts/src/v0.8/shared/interfaces/IOwnable.sol";

/// @notice Defines common functionalities used across IGameAdmin & IGameAffiliate interfaces.
interface IGameCommon {
    /// @notice Reverting error when token has pending bets.
    error TokenHasPendingBets();

    /// @notice Reverting error when house edge is too high
    error HouseEdgeTooHigh();
}

/// @notice Defines administrative functionalities.
interface IGameAdmin is IVRFMigratableConsumerV2Plus, IOwnable, IGameCommon {
    /// @notice Emitted after the house edge is set for a token.
    /// @param token Address of the token.
    /// @param houseEdge House edge rate.
    event SetHouseEdge(address indexed token, uint16 houseEdge);

    /// @notice Emitted after the Chainlink base callback gas is set for a token.
    /// @param token Address of the token.
    /// @param callbackGasBase New Chainlink VRF base callback gas.
    event SetVRFCallbackGasBase(address indexed token, uint32 callbackGasBase);

    /// @notice Emitted after the token's VRF subscription ID is set.
    /// @param token Address of the token.
    /// @param subId Subscription ID.
    event SetVRFSubId(address indexed token, uint256 subId);

    /// @notice Emitted after the Chainlink config is set.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    /// @param chainlinkWrapper  Chainlink Wrapper used to estimate the VRF cost.
    /// @param VRFCallbackGasExtraBet Callback gas to be added for each bet while multi betting.
    /// @param nativePayment Whether Betswirl pays VRF fees in gas token or in LINK token.
    event SetChainlinkConfig(
        uint16 requestConfirmations,
        bytes32 keyHash,
        IVRFV2PlusWrapperCustom chainlinkWrapper,
        uint32 VRFCallbackGasExtraBet,
        bool nativePayment
    );

    /// @notice Emitted after the token's VRF fees amount is transfered to the user.
    /// @param token Address of the token.
    /// @param amount Token amount refunded.
    event DistributeTokenVRFFees(address indexed token, uint256 amount);

    /// @notice Chainlink VRF configuration struct.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param numRandomWords How many random words is needed to resolve a game's bet.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    /// @param chainlinkWrapper Chainlink Wrapper used to estimate the VRF cost
    /// @param VRFCallbackGasExtraBet Callback gas to be added for each bet while multi betting.
    /// @param nativePayment Whether Betswirl pays VRF fees in gas token or in LINK token.
    struct ChainlinkConfig {
        uint16 requestConfirmations;
        uint16 numRandomWords;
        bytes32 keyHash;
        IVRFV2PlusWrapperCustom chainlinkWrapper;
        uint32 VRFCallbackGasExtraBet;
        bool nativePayment;
    }

    /// @notice Token struct.
    /// @param houseEdge House edge rate.
    /// @param pendingCount Number of pending bets.
    /// @param vrfSubId Chainlink VRF v2.5 subscription ID.
    /// @param VRFCallbackGasBase How much gas is needed in the Chainlink VRF callback.
    /// @param VRFFees Chainlink's VRF collected fees amount.
    struct Token {
        uint16 houseEdge;
        uint64 pendingCount;
        uint256 vrfSubId;
        uint32 VRFCallbackGasBase;
        uint256 VRFFees;
    }

    /// @notice Sets the game house edge rate for a specific token.
    /// @param token Address of the token.
    /// @param houseEdge House edge rate.
    function setHouseEdge(address token, uint16 houseEdge) external;

    /// @notice Pauses the contract to disable new bets.
    function pause() external;

    /// @notice Sets the Chainlink VRF subscription ID for a specific token.
    /// @param token Address of the token.
    /// @param subId Subscription ID.
    function setVRFSubId(address token, uint256 subId) external;

    /// @notice Sets the Chainlink VRF V2.5 configuration.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    /// @param chainlinkWrapper Chainlink Wrapper used to estimate the VRF cost.
    /// @param VRFCallbackGasExtraBet Callback gas to be added for each bet while multi betting.
    /// @param nativePayment Whether Betswirl pays VRF fees in gas token or in LINK token.
    function setChainlinkConfig(
        uint16 requestConfirmations,
        bytes32 keyHash,
        IVRFV2PlusWrapperCustom chainlinkWrapper,
        uint32 VRFCallbackGasExtraBet,
        bool nativePayment
    ) external;

    /// @notice Sets the Chainlink VRF V2.5 configuration.
    /// @param callbackGasBase How much gas is needed in the Chainlink VRF callback.
    function setVRFCallbackGasBase(
        address token,
        uint32 callbackGasBase
    ) external;

    /// @notice Distributes the token's collected Chainlink fees.
    /// @param token Address of the token.
    function withdrawTokenVRFFees(address token) external;

    /// @notice Returns the Chainlink VRF config.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    /// @param chainlinkCoordinator Reference to the VRFCoordinatorV2Plus deployed contract.
    /// @param chainlinkWrapper Reference to the VRFV2PlusWrapper deployed contract.
    /// @param VRFCallbackGasExtraBet Callback gas to be added for each bet while multi betting.
    function getChainlinkConfig()
        external
        view
        returns (
            uint16 requestConfirmations,
            bytes32 keyHash,
            IVRFCoordinatorV2Plus chainlinkCoordinator,
            IVRFV2PlusWrapperCustom chainlinkWrapper,
            uint32 VRFCallbackGasExtraBet,
            bool nativePayment
        );
}

/// @notice Defines affiliate functionalities, essentially setting house edge.
interface IGameAffiliate is IGameCommon {
    /// @notice Emitted after the affiliate's house edge is set for a token.
    /// @param token Address of the token.
    /// @param affiliate Address of the affiliate.
    /// @param houseEdge Affiliate's house edge rate.
    event SetAffiliateHouseEdge(
        address indexed token,
        address affiliate,
        uint16 houseEdge
    );

    /// @notice Sets the game affiliate's house edge rate for a specific token.
    /// @param token Address of the token.
    /// @param affiliateHouseEdge Affiliate's house edge rate.
    /// @dev The msg.sender of the tx is considered as to be the affiliate.
    function setAffiliateHouseEdge(
        address token,
        uint16 affiliateHouseEdge
    ) external;

    /// @notice Reverting error when sender isn't allowed.
    error AccessDenied();

    /// @notice Reverting error when house edge is too low
    error HouseEdgeTooLow();
}

/// @notice Defines functionalities used by the bank contract.
interface IGameBank {
    /// @notice Returns whether the token has pending bets.
    /// @return Whether the token has pending bets.
    function hasPendingBets(address token) external view returns (bool);
}

/// @notice Defines player functionalities, essentially wagering & refunding a bet.
interface IGamePlayer {
    /// @notice Multiple bets configuration struct.
    /// @param betCount How many bets at maximum must be placed.
    /// @param stopGain Profit limit indicating that bets must stop after surpassing it (before deduction of house edge).
    /// @param stopLoss Loss limit indicating that bets must stop after exceeding it (before deduction of house edge).
    struct MultiBetData {
        uint16 betCount;
        uint256 stopGain;
        uint256 stopLoss;
    }

    /// @notice Bet information struct.
    /// @param resolved Whether the bet has been resolved.
    /// @param receiver Address of the receiver.
    /// @param token Address of the token.
    /// @param id Bet ID generated by Chainlink VRF.
    /// @param amount The bet amount.
    /// @param timestamp of the bet used to refund in case Chainlink's callback fail.
    /// @param payout The payout amount.
    /// @param betCount How many bets at maximum must be placed.
    /// @param stopGain Profit limit indicating that bets must stop after surpassing it (before deduction of house edge).
    /// @param stopLoss Loss limit indicating that bets must stop after surpassing it (before deduction of house edge).
    /// @param affiliate Address of the affiliate.
    struct Bet {
        bool resolved;
        address receiver;
        address token;
        uint256 id;
        uint256 amount;
        uint32 timestamp;
        uint256 payout;
        uint16 betCount;
        uint256 stopGain;
        uint256 stopLoss;
        address affiliate;
    }

    /// @notice Emitted after the bet amount is transfered to the user.
    /// @param id The bet ID.
    /// @param user Address of the gamer.
    /// @param amount Token amount refunded.
    event BetRefunded(
        uint256 id,
        address user,
        uint256 amount
    );

    /// @notice Refunds the bet to the receiver if the Chainlink VRF callback failed.
    /// @param id The Bet ID.
    function refundBet(uint256 id) external;

    /// @notice Returns the amount of ETH that should be passed to the wager transaction.
    /// to cover Chainlink VRF fee.
    /// @param token Address of the token.
    /// @param betCount The number of bets to place.
    /// @return The bet resolution cost amount.
    /// @dev The user always pays VRF fees in gas token, whatever we pay in gas token or in LINK on our side.
    function getChainlinkVRFCost(
        address token,
        uint16 betCount
    ) external view returns (uint256);

    /// @notice Get the affiliate's house edge. If the affiliate has not their own house edge,
    /// then it takes the default house edge.
    /// @param affiliate Address of the affiliate.
    /// @param token Address of the token.
    /// @return The affiliate's house edge.
    function getAffiliateHouseEdge(
        address affiliate,
        address token
    ) external view returns (uint16);

    /// @notice Insufficient bet amount.
    /// @param minBetAmount Bet amount.
    error UnderMinBetAmount(uint256 minBetAmount);

    /// @notice Bet provided doesn't exist or was already resolved.
    error NotPendingBet();

    /// @notice Bet isn't resolved yet.
    error NotFulfilled();

    /// @notice Token is not allowed.
    error ForbiddenToken();

    /// @notice The msg.value is not enough to cover Chainlink's fee.
    error WrongGasValueToCoverFee();

    /// @notice Reverting error when provided address isn't valid.
    error InvalidAddress();

    /// @notice Reverting error when provided betCount isn't valid.
    error InvalidBetCount();
}

/// @notice Aggregates all functionalities from IGameAdmin, IGameBank, IGameAffiliate & IGamePlayer interfaces.
interface IGame is IGameAdmin, IGameBank, IGameAffiliate, IGamePlayer {

}

interface IVRFV2PlusWrapperCustom is IVRFV2PlusWrapper {
    function getConfig()
        external
        view
        returns (
            int256 fallbackWeiPerUnitLink,
            uint32 stalenessSeconds,
            uint32 fulfillmentFlatFeeNativePPM,
            uint32 fulfillmentFlatFeeLinkDiscountPPM,
            uint32 wrapperGasOverhead,
            uint32 coordinatorGasOverheadNative,
            uint32 coordinatorGasOverheadLink,
            uint16 coordinatorGasOverheadPerWord,
            uint8 wrapperNativePremiumPercentage,
            uint8 wrapperLinkPremiumPercentage,
            bytes32 keyHash,
            uint8 maxNumWords
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import {IGame} from "./IGame.sol";

/// @notice Defines common functionalities between all PVH implemention games.
interface IGameImplementation {
    function wagerWithData(
        bytes calldata bet,
        address receiver,
        address token,
        uint256 tokenAmount,
        address affiliate,
        IGame.MultiBetData memory multiBetData
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IWrapped {
    function deposit() external payable;

    function withdraw(uint wad) external;

    function transfer(address to, uint value) external returns (bool);
}