// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {IExecutorBase} from 'governance-crosschain-bridges/contracts/interfaces/IExecutorBase.sol';
import {IL2RobotKeeper, AutomationCompatibleInterface} from '../interfaces/IL2RobotKeeper.sol';
import {IAaveCLRobotOperator} from '../interfaces/IAaveCLRobotOperator.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';

/**
 * @title L2RobotKeeper
 * @author BGD Labs
 * @dev Aave chainlink keeper-compatible contract for proposal actionsSet automation on layer 2:
 * - checks if the proposal actionsSet state could be moved to executed
 * - moves the proposal actionsSet to executed if all the conditions are met
 */
contract L2RobotKeeper is Ownable, IL2RobotKeeper {
  /// @inheritdoc IL2RobotKeeper
  address public immutable BRIDGE_EXECUTOR;

  /// @inheritdoc IL2RobotKeeper
  uint256 public constant MAX_ACTIONS = 25;

  /// @inheritdoc IL2RobotKeeper
  uint256 public constant MAX_SKIP = 20;

  mapping(uint256 => bool) internal _disabledActionsSets;

  error NoActionCanBePerformed();

  /**
   * @param bridgeExecutor address of the bridge executor contract.
   */
  constructor(address bridgeExecutor) {
    BRIDGE_EXECUTOR = bridgeExecutor;
  }

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev run off-chain, checks if proposal actionsSet should be moved to executed state.
   */
  function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
    uint256[] memory actionsSetIdsToPerformExecute = new uint256[](MAX_ACTIONS);

    uint256 index = IExecutorBase(BRIDGE_EXECUTOR).getActionsSetCount();
    uint256 skipCount = 0;
    uint256 actionsCount = 0;

    // loops from the last/latest actionsSetId until MAX_SKIP iterations. resets skipCount and checks more MAX_SKIP number
    // of actionsSet if they could be executed. we only check actionsSet until MAX_SKIP iterations from the last/latest actionsSet
    // or actionsSets where any action could be performed, and actionsSets before that will not be checked by the keeper.
    while (index != 0 && skipCount <= MAX_SKIP && actionsCount <= MAX_ACTIONS) {
      uint256 actionsSetId = index - 1;

      if (!isDisabled(actionsSetId)) {
        if (_canActionSetBeExecuted(actionsSetId)) {
          skipCount = 0;
          actionsSetIdsToPerformExecute[actionsCount] = actionsSetId;
          actionsCount++;
        } else {
          // it is in final state: executed/expired/cancelled
          skipCount++;
        }
      }

      index--;
    }

    if (actionsCount > 0) {
      // we do not know the length in advance, so we init arrays with the maxNumberOfActions
      // and then squeeze the array using mstore
      assembly {
        mstore(actionsSetIdsToPerformExecute, actionsCount)
      }
      bytes memory performData = abi.encode(actionsSetIdsToPerformExecute);
      return (true, performData);
    }

    return (false, '');
  }

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev if actionsSet could be executed - performs execute action on the bridge executor contract.
   * @param performData actionsSet ids to execute.
   */
  function performUpkeep(bytes calldata performData) external override {
    uint256[] memory actionsSetIds = abi.decode(performData, (uint256[]));
    bool isActionPerformed;

    // executes action on actionSetIds in order from first to last
    for (uint i = actionsSetIds.length; i > 0; i--) {
      uint256 actionsSetId = actionsSetIds[i - 1];

      if (_canActionSetBeExecuted(actionsSetId)) {
        try IExecutorBase(BRIDGE_EXECUTOR).execute(actionsSetId) {
          isActionPerformed = true;
          emit ActionSucceeded(actionsSetId, ProposalAction.PerformExecute);
        } catch Error(string memory reason) {
          emit ActionFailed(actionsSetId, ProposalAction.PerformExecute, reason);
        }
      }
    }

    if (!isActionPerformed) revert NoActionCanBePerformed();
  }

  /// @inheritdoc IL2RobotKeeper
  function toggleDisableAutomationById(
    uint256 actionsSetId
  ) external onlyOwner {
    _disabledActionsSets[actionsSetId] = !_disabledActionsSets[actionsSetId];
  }

  /// @inheritdoc IL2RobotKeeper
  function isDisabled(uint256 actionsSetId) public view returns (bool) {
    return _disabledActionsSets[actionsSetId];
  }

  /**
   * @notice method to check if the actionsSet could be executed.
   * @param actionsSetId the actionsSetId to check if it can be executed.
   * @return true if the actionsSet could be executed, false otherwise.
   */
  function _canActionSetBeExecuted(uint256 actionsSetId) internal view returns (bool) {
    IExecutorBase.ActionsSet memory actionsSet = IExecutorBase(BRIDGE_EXECUTOR).getActionsSetById(
      actionsSetId
    );
    IExecutorBase.ActionsSetState actionsSetState = IExecutorBase(BRIDGE_EXECUTOR).getCurrentState(
      actionsSetId
    );

    if (
      actionsSetState == IExecutorBase.ActionsSetState.Queued &&
      block.timestamp >= actionsSet.executionTime
    ) {
      return true;
    }
    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

interface IGovernanceStrategy {
  /**
   * @dev Returns the Proposition Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Proposition Power
   * @return Power number
   **/
  function getPropositionPowerAt(address user, uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Proposition Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalPropositionSupplyAt(uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Voting Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalVotingSupplyAt(uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the Vote Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Vote Power
   * @return Vote number
   **/
  function getVotingPowerAt(address user, uint256 blockNumber) external view returns (uint256);
}

interface IExecutorWithTimelock {
  /**
   * @dev emitted when a new pending admin is set
   * @param newPendingAdmin address of the new pending admin
   **/
  event NewPendingAdmin(address newPendingAdmin);

  /**
   * @dev emitted when a new admin is set
   * @param newAdmin address of the new admin
   **/
  event NewAdmin(address newAdmin);

  /**
   * @dev emitted when a new delay (between queueing and execution) is set
   * @param delay new delay
   **/
  event NewDelay(uint256 delay);

  /**
   * @dev emitted when a new (trans)action is Queued.
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  event QueuedAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall
  );

  /**
   * @dev emitted when an action is Cancelled
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  event CancelledAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall
  );

  /**
   * @dev emitted when an action is Cancelled
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @param resultData the actual callData used on the target
   **/
  event ExecutedAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall,
    bytes resultData
  );

  /**
   * @dev Getter of the current admin address (should be governance)
   * @return The address of the current admin
   **/
  function getAdmin() external view returns (address);

  /**
   * @dev Getter of the current pending admin address
   * @return The address of the pending admin
   **/
  function getPendingAdmin() external view returns (address);

  /**
   * @dev Getter of the delay between queuing and execution
   * @return The delay in seconds
   **/
  function getDelay() external view returns (uint256);

  /**
   * @dev Returns whether an action (via actionHash) is queued
   * @param actionHash hash of the action to be checked
   * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @return true if underlying action of actionHash is queued
   **/
  function isActionQueued(bytes32 actionHash) external view returns (bool);

  /**
   * @dev Checks whether a proposal is over its grace period
   * @param governance Governance contract
   * @param proposalId Id of the proposal against which to test
   * @return true of proposal is over grace period
   **/
  function isProposalOverGracePeriod(
    IAaveGovernanceV2 governance,
    uint256 proposalId
  ) external view returns (bool);

  /**
   * @dev Getter of grace period constant
   * @return grace period in seconds
   **/
  function GRACE_PERIOD() external view returns (uint256);

  /**
   * @dev Getter of minimum delay constant
   * @return minimum delay in seconds
   **/
  function MINIMUM_DELAY() external view returns (uint256);

  /**
   * @dev Getter of maximum delay constant
   * @return maximum delay in seconds
   **/
  function MAXIMUM_DELAY() external view returns (uint256);

  /**
   * @dev Function, called by Governance, that queue a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external returns (bytes32);

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external payable returns (bytes memory);

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external returns (bytes32);
}

interface IAaveGovernanceV2 {
  enum ProposalState {
    Pending,
    Canceled,
    Active,
    Failed,
    Succeeded,
    Queued,
    Expired,
    Executed
  }

  struct Vote {
    bool support;
    uint248 votingPower;
  }

  struct Proposal {
    uint256 id;
    address creator;
    IExecutorWithTimelock executor;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 startBlock;
    uint256 endBlock;
    uint256 executionTime;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
    bool canceled;
    address strategy;
    bytes32 ipfsHash;
    mapping(address => Vote) votes;
  }

  struct ProposalWithoutVotes {
    uint256 id;
    address creator;
    IExecutorWithTimelock executor;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 startBlock;
    uint256 endBlock;
    uint256 executionTime;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
    bool canceled;
    address strategy;
    bytes32 ipfsHash;
  }

  /**
   * @dev emitted when a new proposal is created
   * @param id Id of the proposal
   * @param creator address of the creator
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param targets list of contracts called by proposal's associated transactions
   * @param values list of value in wei for each propoposal's associated transaction
   * @param signatures list of function signatures (can be empty) to be used when created the callData
   * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
   * @param withDelegatecalls boolean, true = transaction delegatecalls the taget, else calls the target
   * @param startBlock block number when vote starts
   * @param endBlock block number when vote ends
   * @param strategy address of the governanceStrategy contract
   * @param ipfsHash IPFS hash of the proposal
   **/
  event ProposalCreated(
    uint256 id,
    address indexed creator,
    IExecutorWithTimelock indexed executor,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    bool[] withDelegatecalls,
    uint256 startBlock,
    uint256 endBlock,
    address strategy,
    bytes32 ipfsHash
  );

  /**
   * @dev emitted when a proposal is canceled
   * @param id Id of the proposal
   **/
  event ProposalCanceled(uint256 id);

  /**
   * @dev emitted when a proposal is queued
   * @param id Id of the proposal
   * @param executionTime time when proposal underlying transactions can be executed
   * @param initiatorQueueing address of the initiator of the queuing transaction
   **/
  event ProposalQueued(uint256 id, uint256 executionTime, address indexed initiatorQueueing);
  /**
   * @dev emitted when a proposal is executed
   * @param id Id of the proposal
   * @param initiatorExecution address of the initiator of the execution transaction
   **/
  event ProposalExecuted(uint256 id, address indexed initiatorExecution);
  /**
   * @dev emitted when a vote is registered
   * @param id Id of the proposal
   * @param voter address of the voter
   * @param support boolean, true = vote for, false = vote against
   * @param votingPower Power of the voter/vote
   **/
  event VoteEmitted(uint256 id, address indexed voter, bool support, uint256 votingPower);

  event GovernanceStrategyChanged(address indexed newStrategy, address indexed initiatorChange);

  event VotingDelayChanged(uint256 newVotingDelay, address indexed initiatorChange);

  event ExecutorAuthorized(address executor);

  event ExecutorUnauthorized(address executor);

  /**
   * @dev Creates a Proposal (needs Proposition Power of creator > Threshold)
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param targets list of contracts called by proposal's associated transactions
   * @param values list of value in wei for each propoposal's associated transaction
   * @param signatures list of function signatures (can be empty) to be used when created the callData
   * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
   * @param withDelegatecalls if true, transaction delegatecalls the taget, else calls the target
   * @param ipfsHash IPFS hash of the proposal
   **/
  function create(
    IExecutorWithTimelock executor,
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls,
    bytes32 ipfsHash
  ) external returns (uint256);

  /**
   * @dev Cancels a Proposal,
   * either at anytime by guardian
   * or when proposal is Pending/Active and threshold no longer reached
   * @param proposalId id of the proposal
   **/
  function cancel(uint256 proposalId) external;

  /**
   * @dev Queue the proposal (If Proposal Succeeded)
   * @param proposalId id of the proposal to queue
   **/
  function queue(uint256 proposalId) external;

  /**
   * @dev Execute the proposal (If Proposal Queued)
   * @param proposalId id of the proposal to execute
   **/
  function execute(uint256 proposalId) external payable;

  /**
   * @dev Function allowing msg.sender to vote for/against a proposal
   * @param proposalId id of the proposal
   * @param support boolean, true = vote for, false = vote against
   **/
  function submitVote(uint256 proposalId, bool support) external;

  /**
   * @dev Function to register the vote of user that has voted offchain via signature
   * @param proposalId id of the proposal
   * @param support boolean, true = vote for, false = vote against
   * @param v v part of the voter signature
   * @param r r part of the voter signature
   * @param s s part of the voter signature
   **/
  function submitVoteBySignature(
    uint256 proposalId,
    bool support,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Set new GovernanceStrategy
   * Note: owner should be a timelocked executor, so needs to make a proposal
   * @param governanceStrategy new Address of the GovernanceStrategy contract
   **/
  function setGovernanceStrategy(address governanceStrategy) external;

  /**
   * @dev Set new Voting Delay (delay before a newly created proposal can be voted on)
   * Note: owner should be a timelocked executor, so needs to make a proposal
   * @param votingDelay new voting delay in seconds
   **/
  function setVotingDelay(uint256 votingDelay) external;

  /**
   * @dev Add new addresses to the list of authorized executors
   * @param executors list of new addresses to be authorized executors
   **/
  function authorizeExecutors(address[] memory executors) external;

  /**
   * @dev Remove addresses to the list of authorized executors
   * @param executors list of addresses to be removed as authorized executors
   **/
  function unauthorizeExecutors(address[] memory executors) external;

  /**
   * @dev Let the guardian abdicate from its priviledged rights
   **/
  function __abdicate() external;

  /**
   * @dev Getter of the current GovernanceStrategy address
   * @return The address of the current GovernanceStrategy contracts
   **/
  function getGovernanceStrategy() external view returns (address);

  /**
   * @dev Getter of the current Voting Delay (delay before a created proposal can be voted on)
   * Different from the voting duration
   * @return The voting delay in seconds
   **/
  function getVotingDelay() external view returns (uint256);

  /**
   * @dev Returns whether an address is an authorized executor
   * @param executor address to evaluate as authorized executor
   * @return true if authorized
   **/
  function isExecutorAuthorized(address executor) external view returns (bool);

  /**
   * @dev Getter the address of the guardian, that can mainly cancel proposals
   * @return The address of the guardian
   **/
  function getGuardian() external view returns (address);

  /**
   * @dev Getter of the proposal count (the current number of proposals ever created)
   * @return the proposal count
   **/
  function getProposalsCount() external view returns (uint256);

  /**
   * @dev Getter of a proposal by id
   * @param proposalId id of the proposal to get
   * @return the proposal as ProposalWithoutVotes memory object
   **/
  function getProposalById(uint256 proposalId) external view returns (ProposalWithoutVotes memory);

  /**
   * @dev Getter of the Vote of a voter about a proposal
   * Note: Vote is a struct: ({bool support, uint248 votingPower})
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @return The associated Vote memory object
   **/
  function getVoteOnProposal(uint256 proposalId, address voter) external view returns (Vote memory);

  /**
   * @dev Get the current state of a proposal
   * @param proposalId id of the proposal
   * @return The current state if the proposal
   **/
  function getProposalState(uint256 proposalId) external view returns (ProposalState);
}

library AaveGovernanceV2 {
  IAaveGovernanceV2 internal constant GOV =
    IAaveGovernanceV2(0xEC568fffba86c094cf06b22134B23074DFE2252c);

  IGovernanceStrategy public constant GOV_STRATEGY =
    IGovernanceStrategy(0xb7e383ef9B1E9189Fc0F71fb30af8aa14377429e);

  address public constant SHORT_EXECUTOR = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

  address public constant LONG_EXECUTOR = 0x79426A1c24B2978D90d7A5070a46C65B07bC4299;

  address public constant ARC_TIMELOCK = 0xAce1d11d836cb3F51Ef658FD4D353fFb3c301218;

  // https://github.com/aave/governance-crosschain-bridges
  address internal constant POLYGON_BRIDGE_EXECUTOR = 0xdc9A35B16DB4e126cFeDC41322b3a36454B1F772;

  address internal constant OPTIMISM_BRIDGE_EXECUTOR = 0x7d9103572bE58FfE99dc390E8246f02dcAe6f611;

  address internal constant ARBITRUM_BRIDGE_EXECUTOR = 0x7d9103572bE58FfE99dc390E8246f02dcAe6f611;

  address internal constant METIS_BRIDGE_EXECUTOR = 0x8EC77963068474a45016938Deb95E603Ca82a029;

  // https://github.com/bgd-labs/aave-v3-crosschain-listing-template/tree/master/src/contracts
  address internal constant CROSSCHAIN_FORWARDER_POLYGON =
    0x158a6bC04F0828318821baE797f50B0A1299d45b;

  address internal constant CROSSCHAIN_FORWARDER_OPTIMISM =
    0x5f5C02875a8e9B5A26fbd09040ABCfDeb2AA6711;

  address internal constant CROSSCHAIN_FORWARDER_ARBITRUM =
    0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3;

  address internal constant CROSSCHAIN_FORWARDER_METIS = 0x2fE52eF191F0BE1D98459BdaD2F1d3160336C08f;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AutomationCompatibleInterface} from 'chainlink-brownie-contracts/interfaces/AutomationCompatibleInterface.sol';

/**
 * @title IL2RobotKeeper
 * @author BGD Labs
 * @notice Defines the interface for the contract to automate actions on aave governance v2 bridge executors.
 */
interface IL2RobotKeeper is AutomationCompatibleInterface {
  /**
   * @dev Emitted when performUpkeep is called and no actions are executed.
   * @param id actionsSetId of failed action.
   * @param action action performed on the actionsSet which faled.
   * @param reason reason of the failed action.
   */
  event ActionFailed(uint256 indexed id, ProposalAction indexed action, string reason);

  /**
   * @dev Emitted when performUpkeep is called and actions are executed.
   * @param id actionsSetId id of successful action.
   * @param action successful action performed on the actionsSetId.
   */
  event ActionSucceeded(uint256 indexed id, ProposalAction indexed action);

  /**
   * @notice Actions that can be performed by the robot on the bridge executor.
   * @param PerformExecute: performs execute action on the bridge executor.
   */
  enum ProposalAction {
    PerformExecute
  }

  /**
   * @notice holds action to be performed for a given actionsSetId.
   * @param id actionsSetId for which action needs to be performed.
   * @param action action to be perfomed for the actionsSetId.
   */
  struct ActionWithId {
    uint256 id;
    ProposalAction action;
  }

  /**
   * @notice method called by owner / robot guardian to disable/enabled automation on a specific actionsSetId.
   * @param actionsSetId id for which we need to disable/enable automation.
   */
  function toggleDisableAutomationById(uint256 actionsSetId) external;

  /**
   * @notice method to check if automation for the actionsSetId is disabled/enabled.
   * @param actionsSetId id to check if automation is disabled or not.
   * @return bool if automation for actionsSetId is disabled or not.
   */
  function isDisabled(uint256 actionsSetId) external view returns (bool);

  /**
   * @notice method to get the address of the aave bridge executor contract.
   * @return bridge executor contract address.
   */
  function BRIDGE_EXECUTOR() external returns (address);

  /**
   * @notice method to get the maximum number of actions that can be performed by the keeper in one performUpkeep.
   * @return max number of actions.
   */
  function MAX_ACTIONS() external returns (uint256);

  /**
   * @notice method to get maximum number of actionsSet to check before the latest actionsSet, if an action could be performed upon.
   * @return max number of skips.
   */
  function MAX_SKIP() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IAaveCLRobotOperator
 * @author BGD Labs
 * @notice Defines the interface for the robot operator contract to perform admin actions on the automation keepers.
 **/
interface IAaveCLRobotOperator {
  /**
   * @dev Emitted when a keeper is registered using the operator contract.
   * @param id id of the keeper registered.
   * @param upkeep address of the keeper contract.
   * @param amount amount of link the keeper has been registered with.
   */
  event KeeperRegistered(uint256 indexed id, address indexed upkeep, uint96 indexed amount);

  /**
   * @dev Emitted when a keeper is cancelled using the operator contract.
   * @param id id of the keeper cancelled.
   * @param upkeep address of the keeper contract.
   */
  event KeeperCancelled(uint256 indexed id, address indexed upkeep);

  /**
   * @dev Emitted when a keeper is already cancelled, and link is being withdrawn using the operator contract.
   * @param id id of the keeper to withdraw link from.
   * @param upkeep address of the keeper contract.
   * @param to address where link needs to be withdrawn to.
   */
  event LinkWithdrawn(uint256 indexed id, address indexed upkeep, address indexed to);

  /**
   * @dev Emitted when a keeper is refilled using the operator contract.
   * @param id id of the keeper which has been refilled.
   * @param from address which refilled the keeper.
   * @param amount amount of link which has been refilled for the keeper.
   */
  event KeeperRefilled(uint256 indexed id, address indexed from, uint96 indexed amount);

  /**
   * @dev Emitted when the link withdraw address has been changed of the keeper.
   * @param newWithdrawAddress address of the new withdraw address where link will be withdrawn to.
   */
  event WithdrawAddressSet(address indexed newWithdrawAddress);

  /**
   * @dev Emitted when gas limit is configured using the operator contract.
   * @param id id of the keeper which gas limit has been configured.
   * @param upkeep address of the keeper contract.
   * @param gasLimit max gas limit which has been configured for the keeper.
   */
  event GasLimitSet(uint256 indexed id, address indexed upkeep, uint32 indexed gasLimit);

  /**
   * @notice holds the keeper info registered via the operator.
   * @param upkeep address of the keeper contract registered.
   * @param name name of the registered keeper.
   */
  struct KeeperInfo {
    address upkeep;
    string name;
  }

  /**
   * @notice method called by owner to register the automation robot keeper.
   * @param name - name of keeper.
   * @param upkeepContract - upkeepContract of the keeper.
   * @param gasLimit - max gasLimit which the chainlink automation node can execute for the automation.
   * @param amountToFund - amount of link to fund the keeper with.
   * @return chainlink id for the registered keeper.
   **/
  function register(
    string memory name,
    address upkeepContract,
    uint32 gasLimit,
    uint96 amountToFund
  ) external returns (uint256);

  /**
   * @notice method called to refill the keeper.
   * @param id - id of the chainlink registered keeper to refill.
   * @param amount - amount of LINK to refill the keeper with.
   **/
  function refillKeeper(uint256 id, uint96 amount) external;

  /**
   * @notice method called by the owner to cancel the automation robot keeper.
   * @param id - id of the chainlink registered keeper to cancel.
   **/
  function cancel(uint256 id) external;

  /**
   * @notice method called permissionlessly to withdraw link of automation robot keeper to the withdraw address.
   *         this method should only be called after the automation robot keeper is cancelled.
   * @param id - id of the chainlink registered keeper to withdraw funds of.
   **/
  function withdrawLink(uint256 id) external;

  /**
   * @notice method called by owner / robot guardian to set the max gasLimit of upkeep robot keeper.
   * @param id - id of the chainlink registered keeper to set the gasLimit.
   * @param gasLimit max gasLimit which the chainlink automation node can execute.
   **/
  function setGasLimit(uint256 id, uint32 gasLimit) external;

  /**
   * @notice method called by owner to set the withdraw address when withdrawing excess link from the automation robot keeeper.
   * @param withdrawAddress withdraw address to withdaw link to.
   **/
  function setWithdrawAddress(address withdrawAddress) external;

  /**
   * @notice method to get the withdraw address for the robot operator contract.
   * @return withdraw address to send excess link to.
   **/
  function getWithdrawAddress() external view returns (address);

  /**
   * @notice method to get the keeper information registered via the operator.
   * @param id - id of the chainlink registered keeper.
   * @return Struct containing the following information about the keeper:
   *         - uint256 chainlink id of the registered keeper.
   *         - string name of the registered keeper.
   *         - address chainlink registry of the registered keeper.
   **/
  function getKeeperInfo(uint256 id) external view returns (KeeperInfo memory);

  /**
   * @notice method to get the address of ERC-677 link token.
   * @return link token address.
   */
  function LINK_TOKEN() external returns (address);

  /**
   * @notice method to get the address of chainlink keeper registry contract.
   * @return keeper registry address.
   */
  function KEEPER_REGISTRY() external returns (address);

  /**
   * @notice method to get the address of chainlink keeper registrar contract.
   * @return keeper registrar address.
   */
  function KEEPER_REGISTRAR() external returns (address);
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