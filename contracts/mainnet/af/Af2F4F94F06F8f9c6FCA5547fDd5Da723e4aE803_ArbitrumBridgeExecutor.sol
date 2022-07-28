// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {AddressAliasHelper} from '../dependencies/arbitrum/AddressAliasHelper.sol';
import {L2BridgeExecutor} from './L2BridgeExecutor.sol';

/**
 * @title ArbitrumBridgeExecutor
 * @author Aave
 * @notice Implementation of the Arbitrum Bridge Executor, able to receive cross-chain transactions from Ethereum
 * @dev Queuing an ActionsSet into this Executor can only be done by the L2 Address Alias of the L1 EthereumGovernanceExecutor
 */
contract ArbitrumBridgeExecutor is L2BridgeExecutor {
  /// @inheritdoc L2BridgeExecutor
  modifier onlyEthereumGovernanceExecutor() override {
    if (AddressAliasHelper.undoL1ToL2Alias(msg.sender) != _ethereumGovernanceExecutor)
      revert UnauthorizedEthereumExecutor();
    _;
  }

  /**
   * @dev Constructor
   *
   * @param ethereumGovernanceExecutor The address of the EthereumGovernanceExecutor
   * @param delay The delay before which an actions set can be executed
   * @param gracePeriod The time period after a delay during which an actions set can be executed
   * @param minimumDelay The minimum bound a delay can be set to
   * @param maximumDelay The maximum bound a delay can be set to
   * @param guardian The address of the guardian, which can cancel queued proposals (can be zero)
   */
  constructor(
    address ethereumGovernanceExecutor,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    address guardian
  )
    L2BridgeExecutor(
      ethereumGovernanceExecutor,
      delay,
      gracePeriod,
      minimumDelay,
      maximumDelay,
      guardian
    )
  {
    // Intentionally left blank
  }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IL2BridgeExecutor} from '../interfaces/IL2BridgeExecutor.sol';
import {BridgeExecutorBase} from './BridgeExecutorBase.sol';

/**
 * @title L2BridgeExecutor
 * @author Aave
 * @notice Abstract contract that implements bridge executor functionality for L2
 * @dev It does not implement the `onlyEthereumGovernanceExecutor` modifier. This should instead be done in the inheriting
 * contract with proper configuration and adjustments depending on the L2
 */
abstract contract L2BridgeExecutor is BridgeExecutorBase, IL2BridgeExecutor {
  // Address of the Ethereum Governance Executor, which should be able to queue actions sets
  address internal _ethereumGovernanceExecutor;

  /**
   * @dev Only the Ethereum Governance Executor should be able to call functions marked by this modifier.
   **/
  modifier onlyEthereumGovernanceExecutor() virtual;

  /**
   * @dev Constructor
   *
   * @param ethereumGovernanceExecutor The address of the EthereumGovernanceExecutor
   * @param delay The delay before which an actions set can be executed
   * @param gracePeriod The time period after a delay during which an actions set can be executed
   * @param minimumDelay The minimum bound a delay can be set to
   * @param maximumDelay The maximum bound a delay can be set to
   * @param guardian The address of the guardian, which can cancel queued proposals (can be zero)
   */
  constructor(
    address ethereumGovernanceExecutor,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    address guardian
  ) BridgeExecutorBase(delay, gracePeriod, minimumDelay, maximumDelay, guardian) {
    _ethereumGovernanceExecutor = ethereumGovernanceExecutor;
  }

  /// @inheritdoc IL2BridgeExecutor
  function queue(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls
  ) external onlyEthereumGovernanceExecutor {
    _queue(targets, values, signatures, calldatas, withDelegatecalls);
  }

  /// @inheritdoc IL2BridgeExecutor
  function updateEthereumGovernanceExecutor(address ethereumGovernanceExecutor) external onlyThis {
    emit EthereumGovernanceExecutorUpdate(_ethereumGovernanceExecutor, ethereumGovernanceExecutor);
    _ethereumGovernanceExecutor = ethereumGovernanceExecutor;
  }

  /// @inheritdoc IL2BridgeExecutor
  function getEthereumGovernanceExecutor() external view returns (address) {
    return _ethereumGovernanceExecutor;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IL2BridgeExecutorBase
 * @author Aave
 * @notice Defines the basic interface for the L2BridgeExecutor abstract contract
 */
interface IL2BridgeExecutor {
  error UnauthorizedEthereumExecutor();

  /**
   * @dev Emitted when the Ethereum Governance Executor is updated
   * @param oldEthereumGovernanceExecutor The address of the old EthereumGovernanceExecutor
   * @param newEthereumGovernanceExecutor The address of the new EthereumGovernanceExecutor
   **/
  event EthereumGovernanceExecutorUpdate(
    address oldEthereumGovernanceExecutor,
    address newEthereumGovernanceExecutor
  );

  /**
   * @notice Queue an ActionsSet
   * @dev If a signature is empty, calldata is used for the execution, calldata is appended to signature otherwise
   * @param targets Array of targets to be called by the actions set
   * @param values Array of values to pass in each call by the actions set
   * @param signatures Array of function signatures to encode in each call by the actions (can be empty)
   * @param calldatas Array of calldata to pass in each call by the actions set
   * @param withDelegatecalls Array of whether to delegatecall for each call of the actions set
   **/
  function queue(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls
  ) external;

  /**
   * @notice Update the address of the Ethereum Governance Executor
   * @param ethereumGovernanceExecutor The address of the new EthereumGovernanceExecutor
   **/
  function updateEthereumGovernanceExecutor(address ethereumGovernanceExecutor) external;

  /**
   * @notice Returns the address of the Ethereum Governance Executor
   * @return The address of the EthereumGovernanceExecutor
   **/
  function getEthereumGovernanceExecutor() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IExecutorBase} from '../interfaces/IExecutorBase.sol';

/**
 * @title BridgeExecutorBase
 * @author Aave
 * @notice Abstract contract that implements basic executor functionality
 * @dev It does not implement an external `queue` function. This should instead be done in the inheriting
 * contract with proper access control
 */
abstract contract BridgeExecutorBase is IExecutorBase {
  // Minimum allowed grace period, which reduces the risk of having an actions set expire due to network congestion
  uint256 constant MINIMUM_GRACE_PERIOD = 10 minutes;

  // Time between queuing and execution
  uint256 private _delay;
  // Time after the execution time during which the actions set can be executed
  uint256 private _gracePeriod;
  // Minimum allowed delay
  uint256 private _minimumDelay;
  // Maximum allowed delay
  uint256 private _maximumDelay;
  // Address with the ability of canceling actions sets
  address private _guardian;

  // Number of actions sets
  uint256 private _actionsSetCounter;
  // Map of registered actions sets (id => ActionsSet)
  mapping(uint256 => ActionsSet) private _actionsSets;
  // Map of queued actions (actionHash => isQueued)
  mapping(bytes32 => bool) private _queuedActions;

  /**
   * @dev Only guardian can call functions marked by this modifier.
   **/
  modifier onlyGuardian() {
    if (msg.sender != _guardian) revert NotGuardian();
    _;
  }

  /**
   * @dev Only this contract can call functions marked by this modifier.
   **/
  modifier onlyThis() {
    if (msg.sender != address(this)) revert OnlyCallableByThis();
    _;
  }

  /**
   * @dev Constructor
   *
   * @param delay The delay before which an actions set can be executed
   * @param gracePeriod The time period after a delay during which an actions set can be executed
   * @param minimumDelay The minimum bound a delay can be set to
   * @param maximumDelay The maximum bound a delay can be set to
   * @param guardian The address of the guardian, which can cancel queued proposals (can be zero)
   */
  constructor(
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    address guardian
  ) {
    if (
      gracePeriod < MINIMUM_GRACE_PERIOD ||
      minimumDelay >= maximumDelay ||
      delay < minimumDelay ||
      delay > maximumDelay
    ) revert InvalidInitParams();

    _updateDelay(delay);
    _updateGracePeriod(gracePeriod);
    _updateMinimumDelay(minimumDelay);
    _updateMaximumDelay(maximumDelay);
    _updateGuardian(guardian);
  }

  /// @inheritdoc IExecutorBase
  function execute(uint256 actionsSetId) external payable override {
    if (getCurrentState(actionsSetId) != ActionsSetState.Queued) revert OnlyQueuedActions();

    ActionsSet storage actionsSet = _actionsSets[actionsSetId];
    if (block.timestamp < actionsSet.executionTime) revert TimelockNotFinished();

    actionsSet.executed = true;
    uint256 actionCount = actionsSet.targets.length;

    bytes[] memory returnedData = new bytes[](actionCount);
    for (uint256 i = 0; i < actionCount; ) {
      returnedData[i] = _executeTransaction(
        actionsSet.targets[i],
        actionsSet.values[i],
        actionsSet.signatures[i],
        actionsSet.calldatas[i],
        actionsSet.executionTime,
        actionsSet.withDelegatecalls[i]
      );
      unchecked {
        ++i;
      }
    }

    emit ActionsSetExecuted(actionsSetId, msg.sender, returnedData);
  }

  /// @inheritdoc IExecutorBase
  function cancel(uint256 actionsSetId) external override onlyGuardian {
    if (getCurrentState(actionsSetId) != ActionsSetState.Queued) revert OnlyQueuedActions();

    ActionsSet storage actionsSet = _actionsSets[actionsSetId];
    actionsSet.canceled = true;

    uint256 targetsLength = actionsSet.targets.length;
    for (uint256 i = 0; i < targetsLength; ) {
      _cancelTransaction(
        actionsSet.targets[i],
        actionsSet.values[i],
        actionsSet.signatures[i],
        actionsSet.calldatas[i],
        actionsSet.executionTime,
        actionsSet.withDelegatecalls[i]
      );
      unchecked {
        ++i;
      }
    }

    emit ActionsSetCanceled(actionsSetId);
  }

  /// @inheritdoc IExecutorBase
  function updateGuardian(address guardian) external override onlyThis {
    _updateGuardian(guardian);
  }

  /// @inheritdoc IExecutorBase
  function updateDelay(uint256 delay) external override onlyThis {
    _validateDelay(delay);
    _updateDelay(delay);
  }

  /// @inheritdoc IExecutorBase
  function updateGracePeriod(uint256 gracePeriod) external override onlyThis {
    if (gracePeriod < MINIMUM_GRACE_PERIOD) revert GracePeriodTooShort();
    _updateGracePeriod(gracePeriod);
  }

  /// @inheritdoc IExecutorBase
  function updateMinimumDelay(uint256 minimumDelay) external override onlyThis {
    if (minimumDelay >= _maximumDelay) revert MinimumDelayTooLong();
    _updateMinimumDelay(minimumDelay);
    _validateDelay(_delay);
  }

  /// @inheritdoc IExecutorBase
  function updateMaximumDelay(uint256 maximumDelay) external override onlyThis {
    if (maximumDelay <= _minimumDelay) revert MaximumDelayTooShort();
    _updateMaximumDelay(maximumDelay);
    _validateDelay(_delay);
  }

  /// @inheritdoc IExecutorBase
  function executeDelegateCall(address target, bytes calldata data)
    external
    payable
    override
    onlyThis
    returns (bool, bytes memory)
  {
    bool success;
    bytes memory resultData;
    // solium-disable-next-line security/no-call-value
    (success, resultData) = target.delegatecall(data);
    return (success, resultData);
  }

  /// @inheritdoc IExecutorBase
  function receiveFunds() external payable override {}

  /// @inheritdoc IExecutorBase
  function getDelay() external view override returns (uint256) {
    return _delay;
  }

  /// @inheritdoc IExecutorBase
  function getGracePeriod() external view override returns (uint256) {
    return _gracePeriod;
  }

  /// @inheritdoc IExecutorBase
  function getMinimumDelay() external view override returns (uint256) {
    return _minimumDelay;
  }

  /// @inheritdoc IExecutorBase
  function getMaximumDelay() external view override returns (uint256) {
    return _maximumDelay;
  }

  /// @inheritdoc IExecutorBase
  function getGuardian() external view override returns (address) {
    return _guardian;
  }

  /// @inheritdoc IExecutorBase
  function getActionsSetCount() external view override returns (uint256) {
    return _actionsSetCounter;
  }

  /// @inheritdoc IExecutorBase
  function getActionsSetById(uint256 actionsSetId)
    external
    view
    override
    returns (ActionsSet memory)
  {
    return _actionsSets[actionsSetId];
  }

  /// @inheritdoc IExecutorBase
  function getCurrentState(uint256 actionsSetId) public view override returns (ActionsSetState) {
    if (_actionsSetCounter <= actionsSetId) revert InvalidActionsSetId();
    ActionsSet storage actionsSet = _actionsSets[actionsSetId];
    if (actionsSet.canceled) {
      return ActionsSetState.Canceled;
    } else if (actionsSet.executed) {
      return ActionsSetState.Executed;
    } else if (block.timestamp > actionsSet.executionTime + _gracePeriod) {
      return ActionsSetState.Expired;
    } else {
      return ActionsSetState.Queued;
    }
  }

  /// @inheritdoc IExecutorBase
  function isActionQueued(bytes32 actionHash) public view override returns (bool) {
    return _queuedActions[actionHash];
  }

  function _updateGuardian(address guardian) internal {
    emit GuardianUpdate(_guardian, guardian);
    _guardian = guardian;
  }

  function _updateDelay(uint256 delay) internal {
    emit DelayUpdate(_delay, delay);
    _delay = delay;
  }

  function _updateGracePeriod(uint256 gracePeriod) internal {
    emit GracePeriodUpdate(_gracePeriod, gracePeriod);
    _gracePeriod = gracePeriod;
  }

  function _updateMinimumDelay(uint256 minimumDelay) internal {
    emit MinimumDelayUpdate(_minimumDelay, minimumDelay);
    _minimumDelay = minimumDelay;
  }

  function _updateMaximumDelay(uint256 maximumDelay) internal {
    emit MaximumDelayUpdate(_maximumDelay, maximumDelay);
    _maximumDelay = maximumDelay;
  }

  /**
   * @notice Queue an ActionsSet
   * @dev If a signature is empty, calldata is used for the execution, calldata is appended to signature otherwise
   * @param targets Array of targets to be called by the actions set
   * @param values Array of values to pass in each call by the actions set
   * @param signatures Array of function signatures to encode in each call (can be empty)
   * @param calldatas Array of calldata to pass in each call (can be empty)
   * @param withDelegatecalls Array of whether to delegatecall for each call
   **/
  function _queue(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls
  ) internal {
    if (targets.length == 0) revert EmptyTargets();
    uint256 targetsLength = targets.length;
    if (
      targetsLength != values.length ||
      targetsLength != signatures.length ||
      targetsLength != calldatas.length ||
      targetsLength != withDelegatecalls.length
    ) revert InconsistentParamsLength();

    uint256 actionsSetId = _actionsSetCounter;
    uint256 executionTime = block.timestamp + _delay;
    unchecked {
      ++_actionsSetCounter;
    }

    for (uint256 i = 0; i < targetsLength; ) {
      bytes32 actionHash = keccak256(
        abi.encode(
          targets[i],
          values[i],
          signatures[i],
          calldatas[i],
          executionTime,
          withDelegatecalls[i]
        )
      );
      if (isActionQueued(actionHash)) revert DuplicateAction();
      _queuedActions[actionHash] = true;
      unchecked {
        ++i;
      }
    }

    ActionsSet storage actionsSet = _actionsSets[actionsSetId];
    actionsSet.targets = targets;
    actionsSet.values = values;
    actionsSet.signatures = signatures;
    actionsSet.calldatas = calldatas;
    actionsSet.withDelegatecalls = withDelegatecalls;
    actionsSet.executionTime = executionTime;

    emit ActionsSetQueued(
      actionsSetId,
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls,
      executionTime
    );
  }

  function _executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) internal returns (bytes memory) {
    if (address(this).balance < value) revert InsufficientBalance();

    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedActions[actionHash] = false;

    bytes memory callData;
    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    bool success;
    bytes memory resultData;
    if (withDelegatecall) {
      (success, resultData) = this.executeDelegateCall{value: value}(target, callData);
    } else {
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.call{value: value}(callData);
    }
    return _verifyCallResult(success, resultData);
  }

  function _cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) internal {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedActions[actionHash] = false;
  }

  function _validateDelay(uint256 delay) internal view {
    if (delay < _minimumDelay) revert DelayShorterThanMin();
    if (delay > _maximumDelay) revert DelayLongerThanMax();
  }

  function _verifyCallResult(bool success, bytes memory returnData)
    private
    pure
    returns (bytes memory)
  {
    if (success) {
      return returnData;
    } else {
      // Look for revert reason and bubble it up if present
      if (returnData.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returnData)
          revert(add(32, returnData), returndata_size)
        }
      } else {
        revert FailedActionExecution();
      }
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IExecutorBase
 * @author Aave
 * @notice Defines the basic interface for the ExecutorBase abstract contract
 */
interface IExecutorBase {
  error InvalidInitParams();
  error NotGuardian();
  error OnlyCallableByThis();
  error MinimumDelayTooLong();
  error MaximumDelayTooShort();
  error GracePeriodTooShort();
  error DelayShorterThanMin();
  error DelayLongerThanMax();
  error OnlyQueuedActions();
  error TimelockNotFinished();
  error InvalidActionsSetId();
  error EmptyTargets();
  error InconsistentParamsLength();
  error DuplicateAction();
  error InsufficientBalance();
  error FailedActionExecution();

  /**
   * @notice This enum contains all possible actions set states
   */
  enum ActionsSetState {
    Queued,
    Executed,
    Canceled,
    Expired
  }

  /**
   * @notice This struct contains the data needed to execute a specified set of actions
   * @param targets Array of targets to call
   * @param values Array of values to pass in each call
   * @param signatures Array of function signatures to encode in each call (can be empty)
   * @param calldatas Array of calldatas to pass in each call, appended to the signature at the same array index if not empty
   * @param withDelegateCalls Array of whether to delegatecall for each call
   * @param executionTime Timestamp starting from which the actions set can be executed
   * @param executed True if the actions set has been executed, false otherwise
   * @param canceled True if the actions set has been canceled, false otherwise
   */
  struct ActionsSet {
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 executionTime;
    bool executed;
    bool canceled;
  }

  /**
   * @dev Emitted when an ActionsSet is queued
   * @param id Id of the ActionsSet
   * @param targets Array of targets to be called by the actions set
   * @param values Array of values to pass in each call by the actions set
   * @param signatures Array of function signatures to encode in each call by the actions set
   * @param calldatas Array of calldata to pass in each call by the actions set
   * @param withDelegatecalls Array of whether to delegatecall for each call of the actions set
   * @param executionTime The timestamp at which this actions set can be executed
   **/
  event ActionsSetQueued(
    uint256 indexed id,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    bool[] withDelegatecalls,
    uint256 executionTime
  );

  /**
   * @dev Emitted when an ActionsSet is successfully executed
   * @param id Id of the ActionsSet
   * @param initiatorExecution The address that triggered the ActionsSet execution
   * @param returnedData The returned data from the ActionsSet execution
   **/
  event ActionsSetExecuted(
    uint256 indexed id,
    address indexed initiatorExecution,
    bytes[] returnedData
  );

  /**
   * @dev Emitted when an ActionsSet is cancelled by the guardian
   * @param id Id of the ActionsSet
   **/
  event ActionsSetCanceled(uint256 indexed id);

  /**
   * @dev Emitted when a new guardian is set
   * @param oldGuardian The address of the old guardian
   * @param newGuardian The address of the new guardian
   **/
  event GuardianUpdate(address oldGuardian, address newGuardian);

  /**
   * @dev Emitted when the delay (between queueing and execution) is updated
   * @param oldDelay The value of the old delay
   * @param newDelay The value of the new delay
   **/
  event DelayUpdate(uint256 oldDelay, uint256 newDelay);

  /**
   * @dev Emitted when the grace period (between executionTime and expiration) is updated
   * @param oldGracePeriod The value of the old grace period
   * @param newGracePeriod The value of the new grace period
   **/
  event GracePeriodUpdate(uint256 oldGracePeriod, uint256 newGracePeriod);

  /**
   * @dev Emitted when the minimum delay (lower bound of delay) is updated
   * @param oldMinimumDelay The value of the old minimum delay
   * @param newMinimumDelay The value of the new minimum delay
   **/
  event MinimumDelayUpdate(uint256 oldMinimumDelay, uint256 newMinimumDelay);

  /**
   * @dev Emitted when the maximum delay (upper bound of delay)is updated
   * @param oldMaximumDelay The value of the old maximum delay
   * @param newMaximumDelay The value of the new maximum delay
   **/
  event MaximumDelayUpdate(uint256 oldMaximumDelay, uint256 newMaximumDelay);

  /**
   * @notice Execute the ActionsSet
   * @param actionsSetId The id of the ActionsSet to execute
   **/
  function execute(uint256 actionsSetId) external payable;

  /**
   * @notice Cancel the ActionsSet
   * @param actionsSetId The id of the ActionsSet to cancel
   **/
  function cancel(uint256 actionsSetId) external;

  /**
   * @notice Update guardian
   * @param guardian The address of the new guardian
   **/
  function updateGuardian(address guardian) external;

  /**
   * @notice Update the delay, time between queueing and execution of ActionsSet
   * @dev It does not affect to actions set that are already queued
   * @param delay The value of the delay (in seconds)
   **/
  function updateDelay(uint256 delay) external;

  /**
   * @notice Update the grace period, the period after the execution time during which an actions set can be executed
   * @param gracePeriod The value of the grace period (in seconds)
   **/
  function updateGracePeriod(uint256 gracePeriod) external;

  /**
   * @notice Update the minimum allowed delay
   * @param minimumDelay The value of the minimum delay (in seconds)
   **/
  function updateMinimumDelay(uint256 minimumDelay) external;

  /**
   * @notice Update the maximum allowed delay
   * @param maximumDelay The maximum delay (in seconds)
   **/
  function updateMaximumDelay(uint256 maximumDelay) external;

  /**
   * @notice Allows to delegatecall a given target with an specific amount of value
   * @dev This function is external so it allows to specify a defined msg.value for the delegate call, reducing
   * the risk that a delegatecall gets executed with more value than intended
   * @return True if the delegate call was successful, false otherwise
   * @return The bytes returned by the delegate call
   **/
  function executeDelegateCall(address target, bytes calldata data)
    external
    payable
    returns (bool, bytes memory);

  /**
   * @notice Allows to receive funds into the executor
   * @dev Useful for actionsSet that needs funds to gets executed
   */
  function receiveFunds() external payable;

  /**
   * @notice Returns the delay (between queuing and execution)
   * @return The value of the delay (in seconds)
   **/
  function getDelay() external view returns (uint256);

  /**
   * @notice Returns the grace period
   * @return The value of the grace period (in seconds)
   **/
  function getGracePeriod() external view returns (uint256);

  /**
   * @notice Returns the minimum delay
   * @return The value of the minimum delay (in seconds)
   **/
  function getMinimumDelay() external view returns (uint256);

  /**
   * @notice Returns the maximum delay
   * @return The value of the maximum delay (in seconds)
   **/
  function getMaximumDelay() external view returns (uint256);

  /**
   * @notice Returns the address of the guardian
   * @return The address of the guardian
   **/
  function getGuardian() external view returns (address);

  /**
   * @notice Returns the total number of actions sets of the executor
   * @return The number of actions sets
   **/
  function getActionsSetCount() external view returns (uint256);

  /**
   * @notice Returns the data of an actions set
   * @param actionsSetId The id of the ActionsSet
   * @return The data of the ActionsSet
   **/
  function getActionsSetById(uint256 actionsSetId) external view returns (ActionsSet memory);

  /**
   * @notice Returns the current state of an actions set
   * @param actionsSetId The id of the ActionsSet
   * @return The current state of theI ActionsSet
   **/
  function getCurrentState(uint256 actionsSetId) external view returns (ActionsSetState);

  /**
   * @notice Returns whether an actions set (by actionHash) is queued
   * @dev actionHash = keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @param actionHash hash of the action to be checked
   * @return True if the underlying action of actionHash is queued, false otherwise
   **/
  function isActionQueued(bytes32 actionHash) external view returns (bool);
}