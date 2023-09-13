// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PayloadsControllerUtils} from '../payloads/PayloadsControllerUtils.sol';
import {IPayloadsController} from '../payloads/interfaces/IPayloadsController.sol';
import {IPayloadsControllerCore} from '../payloads/interfaces/IPayloadsControllerCore.sol';
import {IPayloadsControllerDataHelper} from './interfaces/IPayloadsControllerDataHelper.sol';

/**
 * @title PayloadsControllerDataHelper
 * @author BGD Labs
 * @notice this contract contains the logic to get the payloads and to retreive the executor configs.
 */
contract PayloadsControllerDataHelper is IPayloadsControllerDataHelper {
  /// @inheritdoc IPayloadsControllerDataHelper
  function getPayloadsData(
    IPayloadsController payloadsController,
    uint40[] calldata payloadsIds
  ) external view returns (Payload[] memory) {
    Payload[] memory payloads = new Payload[](payloadsIds.length);
    IPayloadsController.Payload memory payload;

    for (uint256 i = 0; i < payloadsIds.length; i++) {
      payload = payloadsController.getPayloadById(payloadsIds[i]);
      payloads[i] = Payload({id: payloadsIds[i], data: payload});
    }

    return payloads;
  }

  /// @inheritdoc IPayloadsControllerDataHelper
  function getExecutorConfigs(
    IPayloadsController payloadsController,
    PayloadsControllerUtils.AccessControl[] calldata accessLevels
  ) external view returns (ExecutorConfig[] memory) {
    ExecutorConfig[] memory executorConfigs = new ExecutorConfig[](
      accessLevels.length
    );
    IPayloadsControllerCore.ExecutorConfig memory executorConfig;

    for (uint256 i = 0; i < accessLevels.length; i++) {
      executorConfig = payloadsController.getExecutorSettingsByAccessControl(
        accessLevels[i]
      );
      executorConfigs[i] = ExecutorConfig({
        accessLevel: accessLevels[i],
        config: executorConfig
      });
    }

    return executorConfigs;
  }
}

// SPDX-License-Identifier: MIT
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

import {IBaseReceiverPortal} from 'aave-crosschain-infra/contracts/interfaces/IBaseReceiverPortal.sol';
import {IPayloadsControllerCore} from './IPayloadsControllerCore.sol';
import {PayloadsControllerUtils} from '../PayloadsControllerUtils.sol';

/**
 * @title IPayloadsController
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the PayloadsController contract
 */
interface IPayloadsController is IBaseReceiverPortal, IPayloadsControllerCore {
  /**
   * @notice get contract address from where the messages come
   * @return address of the message registry
   */
  function CROSS_CHAIN_CONTROLLER() external view returns (address);

  /**
   * @notice get chain id of the message originator network
   * @return chain id of the originator network
   */
  function ORIGIN_CHAIN_ID() external view returns (uint256);

  /**
   * @notice get address of the message sender in originator network
   * @return address of the originator contract
   */
  function MESSAGE_ORIGINATOR() external view returns (address);

  /**
   * @notice method to decode a message from from governance chain
   * @param message encoded message with message type
   * @return payloadId, accessLevel, proposalVoteActivationTimestamp from the decoded message
   */
  function decodeMessage(
    bytes memory message
  )
    external
    pure
    returns (uint40, PayloadsControllerUtils.AccessControl, uint40);
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

import {PayloadsControllerUtils} from '../../payloads/PayloadsControllerUtils.sol';
import {IPayloadsController} from '../../payloads/interfaces/IPayloadsController.sol';
import {IPayloadsControllerCore} from '../../payloads/interfaces/IPayloadsControllerCore.sol';

/**
 * @title IPayloadsControllerDataHelper
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the PayloadsControllerDataHelper contract
 */
interface IPayloadsControllerDataHelper {
  /**
   * @notice Object storing the payload data along with its id
   * @param id identifier of the payload
   * @param payloadData payload body
   */
  struct Payload {
    uint256 id;
    IPayloadsController.Payload data;
  }

  /**
   * @notice Object storing the config of the executor
   * @param accessLevel access level
   * @param config executor config
   */
  struct ExecutorConfig {
    PayloadsControllerUtils.AccessControl accessLevel;
    IPayloadsControllerCore.ExecutorConfig config;
  }

  /**
   * @notice method to get proposals list
   * @param payloadsController instance of the payloads controller
   * @param payloadsIds list of the ids of payloads to get
   * @return list of the payloads
   */
  function getPayloadsData(
    IPayloadsController payloadsController,
    uint40[] calldata payloadsIds
  ) external view returns (Payload[] memory);

  /**
   * @notice method to get executor configs for certain accessLevels
   * @param payloadsController instance of the payloads controller
   * @param accessLevels list of the accessLevels for which configs should be returned
   * @return list of the executor configs
   */
  function getExecutorConfigs(
    IPayloadsController payloadsController,
    PayloadsControllerUtils.AccessControl[] calldata accessLevels
  ) external view returns (ExecutorConfig[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IBaseReceiverPortal
 * @author BGD Labs
 * @notice interface defining the method that needs to be implemented by all receiving portals, as its the one that
           will be called when a received message gets confirmed
 */
interface IBaseReceiverPortal {
  /**
   * @notice method called by CrossChainController when a message has been confirmed
   * @param originSender address of the sender of the bridged message
   * @param originChainId id of the chain where the message originated
   * @param message bytes bridged containing the desired information
   */
  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory message
  ) external;
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