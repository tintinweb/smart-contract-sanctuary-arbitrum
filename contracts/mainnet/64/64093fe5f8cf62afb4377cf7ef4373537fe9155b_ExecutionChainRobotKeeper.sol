// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IPayloadsControllerCore} from 'aave-governance-v3/src/contracts/payloads/interfaces/IPayloadsControllerCore.sol';
import {IExecutionChainRobotKeeper, AutomationCompatibleInterface} from '../interfaces/IExecutionChainRobotKeeper.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';

/**
 * @title ExecutionChainRobotKeeper
 * @author BGD Labs
 * @notice Contract to perform automation on payloads controller
 * @dev Aave chainlink automation-keeper-compatible contract to:
 *      - check if the payload could be executed
 *      - executes the payload if all the conditions are met.
 */
contract ExecutionChainRobotKeeper is Ownable, IExecutionChainRobotKeeper {
  /// @inheritdoc IExecutionChainRobotKeeper
  address public immutable PAYLOADS_CONTROLLER;

  mapping(uint256 => bool) internal _disabledProposals;

  /// @inheritdoc IExecutionChainRobotKeeper
  uint256 public constant MAX_SHUFFLE_SIZE = 5;

  /**
   * @inheritdoc IExecutionChainRobotKeeper
   * @dev maximum number of payloads to check before the latest payload, if they could be executed.
   *      from the last payload we check 20 more payloads to be very sure that no proposal is being unchecked.
   */
  uint256 public constant MAX_SKIP = 20;

  error NoActionCanBePerformed();

  /**
   * @param payloadsController address of the payloads controller contract.
   */
  constructor(address payloadsController) {
    PAYLOADS_CONTROLLER = payloadsController;
  }

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev run off-chain, checks if payload should be executed
   */
  function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
    uint40[] memory payloadIdsToExecute = new uint40[](MAX_SHUFFLE_SIZE);
    uint256 actionsCount;

    uint40 index = IPayloadsControllerCore(PAYLOADS_CONTROLLER).getPayloadsCount();
    uint256 skipCount;

    // loops from the last/latest payloadId until MAX_SKIP iterations. resets skipCount and checks more MAX_SKIP number
    // of payloads if they could be executed. we only check payloads until MAX_SKIP iterations from the last/latest payload
    // or payloads where any action could be performed, and payloads before that will not be checked by the keeper.
    while (index != 0 && skipCount <= MAX_SKIP && actionsCount < MAX_SHUFFLE_SIZE) {
      uint40 payloadId = index - 1;
      if (!isDisabled(payloadId)) {
        if (_canPayloadBeExecuted(payloadId)) {
          payloadIdsToExecute[actionsCount] = payloadId;
          actionsCount++;
          skipCount = 0;
        } else {
          skipCount++;
        }
      }
      index--;
    }

    if (actionsCount > 0) {
      // we shuffle the payloadsIds list to execute so that one payload failing does not block the other actions of the keeper.
      payloadIdsToExecute = _squeezeAndShuffleActions(payloadIdsToExecute, actionsCount);
      // squash and pick the first element from the shuffled array to perform execute.
      // we only perform one execute action due to gas limit limitation in one performUpkeep.
      assembly {
        mstore(payloadIdsToExecute, 1)
      }
      return (true, abi.encode(payloadIdsToExecute));
    }

    return (false, '');
  }

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev executes executePayload action on payload controller.
   * @param performData array of proposal ids to execute.
   */
  function performUpkeep(bytes calldata performData) external override {
    uint40[] memory payloadIdsToExecute = abi.decode(performData, (uint40[]));
    bool isActionPerformed;

    // executes action on payloadIds in order from first to last
    for (uint256 i = payloadIdsToExecute.length; i > 0; i--) {
      uint40 payloadId = payloadIdsToExecute[i - 1];

      if (_canPayloadBeExecuted(payloadId)) {
        IPayloadsControllerCore(PAYLOADS_CONTROLLER).executePayload(payloadId);
        isActionPerformed = true;
        emit ActionSucceeded(payloadId);
      }
    }

    if (!isActionPerformed) revert NoActionCanBePerformed();
  }

  /// @inheritdoc IExecutionChainRobotKeeper
  function isDisabled(uint40 id) public view returns (bool) {
    return _disabledProposals[id];
  }

  /// @inheritdoc IExecutionChainRobotKeeper
  function toggleDisableAutomationById(uint256 id) external onlyOwner {
    _disabledProposals[id] = !_disabledProposals[id];
  }

  /**
   * @notice method to check if the payload could be executed.
   * @param payloadId the id of the payload to check if it can be executed.
   * @return true if the payload could be executed, false otherwise.
   */
  function _canPayloadBeExecuted(uint40 payloadId) internal view returns (bool) {
    IPayloadsControllerCore.Payload memory payload = IPayloadsControllerCore(PAYLOADS_CONTROLLER)
      .getPayloadById(payloadId);

    return
      payload.state == IPayloadsControllerCore.PayloadState.Queued &&
      block.timestamp > payload.queuedAt + payload.delay;
  }

  /**
   * @notice method to squeeze the payloadIds array to the right size and shuffle them.
   * @param payloadIds the list of payloadIds to squeeze and shuffle.
   * @param actionsCount the total count of actions - used to squeeze the array to the right size.
   * @return actions array squeezed and shuffled.
   */
  function _squeezeAndShuffleActions(
    uint40[] memory payloadIds,
    uint256 actionsCount
  ) internal view returns (uint40[] memory) {
    // we do not know the length in advance, so we init arrays with MAX_SHUFFLE_SIZE
    // and then squeeze the array using mstore
    assembly {
      mstore(payloadIds, actionsCount)
    }

    // shuffle actions
    for (uint256 i = 0; i < payloadIds.length; i++) {
      uint256 randomNumber = uint256(
        keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
      );
      uint256 n = i + (randomNumber % (payloadIds.length - i));
      uint40 temp = payloadIds[n];
      payloadIds[n] = payloadIds[i];
      payloadIds[i] = temp;
    }

    return payloadIds;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRescuable} from 'solidity-utils/contracts/utils/interfaces/IRescuable.sol';
import {PayloadsControllerUtils} from '../PayloadsControllerUtils.sol';

/**
 * @title IPayloadsControllerCore
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the IPayloadsControllerCore contract
 */
interface IPayloadsControllerCore is IRescuable {
  /**
   * @notice Enum indicating the possible payload states
   * @dev PayloadState enum defines the state machine of a payload, so the order on which the state is
          defined is important. Check logic correctness if new states are added / removed
   */
  enum PayloadState {
    None, // state 0 left as empty
    Created,
    Queued,
    Executed,
    Cancelled,
    Expired
  }

  /**
   * @notice holds configuration of the executor
   * @param executor address of the executor
   * @param delay time in seconds between queuing and execution
   */
  struct ExecutorConfig {
    address executor;
    uint40 delay;
  }

  /**
   * @notice Object containing the information necessary to set a new executor
   * @param accessLevel level of access that the executor will be assigned to
   * @param executorConfig object containing the configurations for the accessLevel specified
   */
  struct UpdateExecutorInput {
    PayloadsControllerUtils.AccessControl accessLevel;
    ExecutorConfig executorConfig;
  }

  /**
   * @notice Object containing the information necessary to define a payload action
   * @param target address of the contract that needs to be executed
   * @param withDelegateCall boolean indicating if execution needs to be delegated
   * @param accessLevel access level of the executor needed for the execution
   * @param value value amount that needs to be sent to the executeTransaction method
   * @param signature method signature that will be executed
   * @param callData data needed for the execution of the signature
   */
  struct ExecutionAction {
    address target;
    bool withDelegateCall;
    PayloadsControllerUtils.AccessControl accessLevel;
    uint256 value;
    string signature;
    bytes callData;
  }

  /**
   * @notice Object containing a payload information
   * @param creator address of the createPayload method caller
   * @param maximumAccessLevelRequired min level needed to be able to execute all actions
   * @param state indicates the current state of the payload
   * @param createdAt time indicating when payload has been created. In seconds // max is: 1.099511628×10¹² (ie 34'865 years)
   * @param queuedAt time indicating when payload has been queued. In seconds  // max is: 1.099511628×10¹² (ie 34'865 years)
   * @param executedAt time indicating when a payload has been executed. In seconds  // max is: 1.099511628×10¹² (ie 34'865 years)
   * @param cancelledAt time indicating when the payload has been cancelled. In seconds
   * @param expirationTime time indicating when the Payload will expire
   * @param delay time in seconds that a payload must remain queued before execution
   * @param gracePeriod time in seconds that a payload has to be executed
   * @param actions array of actions to be executed
   */
  struct Payload {
    address creator;
    PayloadsControllerUtils.AccessControl maximumAccessLevelRequired;
    PayloadState state;
    uint40 createdAt;
    uint40 queuedAt;
    uint40 executedAt;
    uint40 cancelledAt;
    uint40 expirationTime;
    uint40 delay;
    uint40 gracePeriod;
    ExecutionAction[] actions;
  }

  /**
   * @notice Event emitted when an executor has been set for a determined access level
   * @param accessLevel level of access that the executor will be set to
   * @param executor address that will be set for the determined access level
   * @param delay time in seconds between queuing and execution
   */
  event ExecutorSet(
    PayloadsControllerUtils.AccessControl indexed accessLevel,
    address indexed executor,
    uint40 delay
  );

  /**
   * @notice Event emitted when a payload has been created
   * @param payloadId id of the payload created
   * @param creator address pertaining to the caller of the method createPayload
   * @param actions array of the actions conforming the payload
   * @param maximumAccessLevelRequired maximum level of the access control
   */
  event PayloadCreated(
    uint40 indexed payloadId,
    address indexed creator,
    ExecutionAction[] actions,
    PayloadsControllerUtils.AccessControl indexed maximumAccessLevelRequired
  );

  /**
   * @notice emitted when a cross chain message gets received
   * @param originSender address that sent the message on the origin chain
   * @param originChainId id of the chain where the message originated
   * @param delivered flag indicating if message has been delivered
   * @param message bytes containing the necessary information to queue the bridged payload id
   * @param reason bytes with the revert information
   */
  event PayloadExecutionMessageReceived(
    address indexed originSender,
    uint256 indexed originChainId,
    bool indexed delivered,
    bytes message,
    bytes reason
  );

  /**
   * @notice Event emitted when a payload has been executed
   * @param payloadId id of the payload being enqueued
   */
  event PayloadExecuted(uint40 payloadId);

  /**
   * @notice Event emitted when a payload has been queued
   * @param payloadId id of the payload being enqueued
   */
  event PayloadQueued(uint40 payloadId);

  /**
   * @notice Event emitted when cancelling a payload
   * @param payloadId id of the cancelled payload
   */
  event PayloadCancelled(uint40 payloadId);

  /**
   * @notice method to initialize the contract with starter params. Only callable by proxy
   * @param owner address of the owner of the contract. with permissions to call certain methods
   * @param guardian address of the guardian. With permissions to call certain methods
   * @param executors array of executor configurations
   */
  function initialize(
    address owner,
    address guardian,
    UpdateExecutorInput[] calldata executors
  ) external;

  /**
   * @notice get the expiration delay of a payload
   * @return expiration delay in seconds
   */
  function EXPIRATION_DELAY() external view returns (uint40);

  /**
   * @notice get the maximum time in seconds that a proposal must spend being queued
   * @return max delay in seconds
   */
  function MAX_EXECUTION_DELAY() external view returns (uint40);

  /**
   * @notice get the minimum time in seconds that a proposal must spend being queued
   * @return min delay in seconds
   */
  function MIN_EXECUTION_DELAY() external view returns (uint40);

  /**
   * @notice time in seconds where the proposal can be executed (from executionTime) before it expires
   * @return grace period in seconds
   */
  function GRACE_PERIOD() external view returns (uint40);

  /**
   * @notice get a previously created payload object
   * @param payloadId id of the payload to retrieve
   * @return payload information
   */
  function getPayloadById(
    uint40 payloadId
  ) external view returns (Payload memory);

  /**
   * @notice get the current state of a payload
   * @param payloadId id of the payload to retrieve the state from
   * @return payload state
   */
  function getPayloadState(
    uint40 payloadId
  ) external view returns (PayloadState);

  /**
   * @notice get the total count of payloads created
   * @return number of payloads
   */
  function getPayloadsCount() external view returns (uint40);

  /**
   * @notice method that will create a Payload object for every action sent
   * @param actions array of actions which this proposal payload will contain
   * @return id of the created payload
   */
  function createPayload(
    ExecutionAction[] calldata actions
  ) external returns (uint40);

  /**
   * @notice method to execute a payload
   * @param payloadId id of the payload that needs to be executed
   */
  function executePayload(uint40 payloadId) external payable;

  /**
   * @notice method to cancel a payload
   * @param payloadId id of the payload that needs to be canceled
   */
  function cancelPayload(uint40 payloadId) external;

  /**
   * @notice method to add executors and its configuration
   * @param executors array of UpdateExecutorInput objects
   */
  function updateExecutors(UpdateExecutorInput[] calldata executors) external;

  /**
   * @notice method to get the executor configuration assigned to the specified level
   * @param accessControl level of which we want to get the executor configuration from
   * @return executor configuration
   */
  function getExecutorSettingsByAccessControl(
    PayloadsControllerUtils.AccessControl accessControl
  ) external view returns (ExecutorConfig memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AutomationCompatibleInterface} from 'chainlink/src/v0.8/interfaces/automation/AutomationCompatibleInterface.sol';

/**
 * @title IExecutionChainRobotKeeper
 * @author BGD Labs
 * @notice Defines the interface for the contract to automate actions for the payloads controller on execution chain.
 **/
interface IExecutionChainRobotKeeper is AutomationCompatibleInterface {
  /**
   * @notice Emitted when performUpkeep is called and an action is executed.
   * @param id payload id of successful action.
   */
  event ActionSucceeded(uint256 indexed id);

  /**
   * @notice method to check if a payloadId is disabled.
   * @param id - payloadId to check if disabled.
   * @return bool if payload is disabled or not.
   **/
  function isDisabled(uint40 id) external view returns (bool);

  /**
   * @notice method called by owner to disable/enabled automation on a specific payloadId.
   * @param payloadId payloadId for which we need to disable/enable automation.
   */
  function toggleDisableAutomationById(uint256 payloadId) external;

  /**
   * @notice method to get the address of the payloads controller contract.
   * @return payloads controller contract address.
   */
  function PAYLOADS_CONTROLLER() external view returns (address);

  /**
   * @notice method to get the maximum size of payloadIds list from which we shuffle from to select a single payload to execute.
   * @return max shuffle size.
   */
  function MAX_SHUFFLE_SIZE() external view returns (uint256);

  /**
   * @notice method to get maximum number of payloads to check before the latest proposal, if an action could be performed upon.
   * @return max number of skips.
   */
  function MAX_SKIP() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

pragma solidity ^0.8.0;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _transferOwnership(_msgSender());
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if the sender is not the owner.
   */
  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/**
 * @title IRescuable
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the Rescuable contract
 */
interface IRescuable {
  /**
   * @notice emitted when erc20 tokens get rescued
   * @param caller address that triggers the rescue
   * @param token address of the rescued token
   * @param to address that will receive the rescued tokens
   * @param amount quantity of tokens rescued
   */
  event ERC20Rescued(
    address indexed caller,
    address indexed token,
    address indexed to,
    uint256 amount
  );

  /**
   * @notice emitted when native tokens get rescued
   * @param caller address that triggers the rescue
   * @param to address that will receive the rescued tokens
   * @param amount quantity of tokens rescued
   */
  event NativeTokensRescued(address indexed caller, address indexed to, uint256 amount);

  /**
   * @notice method called to rescue tokens sent erroneously to the contract. Only callable by owner
   * @param erc20Token address of the token to rescue
   * @param to address to send the tokens
   * @param amount of tokens to rescue
   */
  function emergencyTokenTransfer(address erc20Token, address to, uint256 amount) external;

  /**
   * @notice method called to rescue ether sent erroneously to the contract. Only callable by owner
   * @param to address to send the eth
   * @param amount of eth to rescue
   */
  function emergencyEtherTransfer(address to, uint256 amount) external;

  /**
   * @notice method that defines the address that is allowed to rescue tokens
   * @return the allowed address
   */
  function whoCanRescue() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library PayloadsControllerUtils {
  /// @notice enum with supported access levels
  enum AccessControl {
    Level_null, // to not use 0
    Level_1, // LEVEL_1 - short executor before, listing assets, changes of assets params, updates of the protocol etc
    Level_2 // LEVEL_2 - long executor before, payloads controller updates
  }

  /**
   * @notice Object containing the necessary payload information.
   * @param chain
   * @param accessLevel
   * @param payloadsController
   * @param payloadId
   */
  struct Payload {
    uint256 chain;
    AccessControl accessLevel;
    address payloadsController; // address which holds the logic to execute after success proposal voting
    uint40 payloadId; // number of the payload placed to payloadsController, max is: ~10¹²
  }
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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