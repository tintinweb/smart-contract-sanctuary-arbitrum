// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Initializable} from "@openzeppelin/proxy/utils/Initializable.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

import {ILlamaCore} from "src/interfaces/ILlamaCore.sol";
import {ILlamaStrategy} from "src/interfaces/ILlamaStrategy.sol";
import {ILlamaTokenAdapter} from "src/token-voting/interfaces/ILlamaTokenAdapter.sol";
import {ActionState, VoteType} from "src/lib/Enums.sol";
import {Action, ActionInfo, CasterConfig} from "src/lib/Structs.sol";
import {LlamaUtils} from "src/lib/LlamaUtils.sol";
import {PeriodPctCheckpoints} from "src/lib/PeriodPctCheckpoints.sol";
import {QuorumCheckpoints} from "src/lib/QuorumCheckpoints.sol";

/// @title LlamaTokenGovernor
/// @author Llama ([email protected])
/// @notice This contract lets holders of a given governance token create actions if they have a
/// sufficient token balance and collectively cast an approval or disapproval on created actions.
/// @dev This contract is deployed by `LlamaTokenVotingFactory`. Anyone can deploy this contract using the factory, but
/// it must hold a Policy from the specified `LlamaCore` instance to actually be able to create and cast on an action.
contract LlamaTokenGovernor is Initializable {
  using PeriodPctCheckpoints for PeriodPctCheckpoints.History;
  using QuorumCheckpoints for QuorumCheckpoints.History;
  // =========================
  // ======== Structs ========
  // =========================

  /// @dev Cast counts and submission data.
  struct CastData {
    uint128 votesFor; // Number of votes casted for this action.
    uint128 votesAbstain; // Number of abstentions casted for this action.
    uint128 votesAgainst; // Number of votes casted against this action.
    uint128 vetoesFor; // Number of vetoes casted for this action.
    uint128 vetoesAbstain; // Number of abstentions casted for this action.
    uint128 vetoesAgainst; // Number of disapprovals casted against this action.
    mapping(address tokenholder => bool) castVote; // True if tokenholder casted a vote, false otherwise.
    mapping(address tokenholder => bool) castVeto; // True if tokenholder casted a veto, false otherwise.
  }

  // ======================================
  // ======== Errors and Modifiers ========
  // ======================================

  /// @dev Thrown when a user tries to submit (dis)approval but the casting period has not ended.
  error CastingPeriodNotOver();

  /// @dev Thrown when a user tries to cast a vote or veto but the casting period has ended.
  error CastingPeriodOver();

  /// @dev Thrown when a user tries to cast a vote or veto but the delay period has not ended.
  error DelayPeriodNotOver();

  /// @dev Token holders can only cast once.
  error DuplicateCast();

  /// @dev Thrown when a user tries to cast a vote or veto but the against surpasses for.
  error ForDoesNotSurpassAgainst(uint256 castsFor, uint256 castsAgainst);

  /// @dev Thrown when a user tries to create an action but does not have enough tokens.
  error InsufficientBalance(uint256 balance);

  /// @dev Thrown when a user tries to submit a disapproval but there are not enough for vetoes.
  error InsufficientVetoes(uint256 vetoes, uint256 threshold);

  /// @dev Thrown when a user tries to submit an approval but there are not enough for votes.
  error InsufficientVotes(uint256 votes, uint256 threshold);

  /// @dev The action is not in the expected state.
  /// @param current The current state of the action.
  error InvalidActionState(ActionState current);

  /// @dev Thrown when an invalid `creationThreshold` is passed to the constructor.
  error InvalidCreationThreshold();

  /// @dev The indices would result in `Panic: Index Out of Bounds`.
  /// @dev Thrown when the `end` index is greater than array length or when the `start` index is greater than the `end`
  /// index.
  error InvalidIndices();

  /// @dev Thrown when an invalid `llamaCore` address is passed to the constructor.
  error InvalidLlamaCoreAddress();

  /// @dev Thrown when an invalid `delayPeriodPct` and `castingPeriodPct` are set.
  error InvalidPeriodPcts(uint16 delayPeriodPct, uint16 castingPeriodPct);

  /// @dev This token caster contract does not have the defined role at action creation time.
  error InvalidPolicyholder();

  /// @dev The recovered signer does not match the expected tokenholder.
  error InvalidSignature();

  /// @dev Thrown when an invalid `support` value is used when casting.
  error InvalidSupport(uint8 support);

  /// @dev Thrown when a `token` with an invalid totaly supply is passed to the constructor.
  error InvalidTotalSupply();

  /// @dev Thrown when an invalid `vetoQuorumPct` is passed to the constructor.
  error InvalidVetoQuorumPct(uint16 vetoQuorumPct);

  /// @dev Thrown when an invalid `voteQuorumPct` is passed to the constructor.
  error InvalidVoteQuorumPct(uint16 voteQuorumPct);

  /// @dev Thrown when a user tries to cancel an action but they are not the action creator.
  error OnlyActionCreator();

  /// @dev Thrown when an address other than the `LlamaExecutor` tries to call a function.
  error OnlyLlamaExecutor();

  /// @dev Thrown when a user tries to submit (dis)approval but the submission period has ended.
  error SubmissionPeriodOver();

  /// @dev Checks that the caller is the Llama Executor and reverts if not.
  modifier onlyLlama() {
    if (msg.sender != address(llamaCore.executor())) revert OnlyLlamaExecutor();
    _;
  }

  // ========================
  // ======== Events ========
  // ========================

  /// @dev Emitted when an action is canceled.
  event ActionCanceled(uint256 id, address indexed creator);

  /// @dev Emitted when an action is created.
  event ActionCreated(uint256 id, address indexed creator);

  /// @dev Emitted when the default number of tokens required to create an action is changed.
  event ActionThresholdSet(uint256 newThreshold);

  /// @dev Emitted when a cast approval is submitted to the `LlamaCore` contract.
  event ApprovalSubmitted(
    uint256 id,
    address indexed caller,
    uint8 indexed role,
    uint256 weightFor,
    uint256 weightAgainst,
    uint256 weightAbstain
  );

  /// @dev Emitted when a cast disapproval is submitted to the `LlamaCore` contract.
  event DisapprovalSubmitted(
    uint256 id,
    address indexed caller,
    uint8 indexed role,
    uint256 weightFor,
    uint256 weightAgainst,
    uint256 weightAbstain
  );

  /// @dev Emitted when the delay and casting period percentages are set.
  event PeriodPctSet(uint16 delayPeriodPct, uint16 castingPeriodPct);

  /// @dev Emitted when the voting quorum and/or vetoing quorum is set.
  event QuorumPctSet(uint16 voteQuorumPct, uint16 vetoQuorumPct);

  /// @dev Emitted when a veto is cast.
  event VetoCast(uint256 id, address indexed tokenholder, uint8 indexed support, uint256 weight, string reason);

  /// @dev Emitted when a vote is cast.
  event VoteCast(uint256 id, address indexed tokenholder, uint8 indexed support, uint256 weight, string reason);

  // =================================================
  // ======== Constants and Storage Variables ========
  // =================================================

  /// @dev EIP-712 base typehash.
  bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

  /// @dev EIP-712 createAction typehash.
  bytes32 internal constant CREATE_ACTION_TYPEHASH = keccak256(
    "CreateAction(address tokenHolder,uint8 role,address strategy,address target,uint256 value,bytes data,string description,uint256 nonce)"
  );

  /// @dev EIP-712 cancelAction typehash.
  bytes32 internal constant CANCEL_ACTION_TYPEHASH = keccak256(
    "CancelAction(address tokenHolder,ActionInfo actionInfo,uint256 nonce)ActionInfo(uint256 id,address creator,uint8 creatorRole,address strategy,address target,uint256 value,bytes data)"
  );

  /// @notice EIP-712 castVote typehash.
  bytes32 internal constant CAST_VOTE_TYPEHASH = keccak256(
    "CastVote(address tokenHolder,uint8 role,ActionInfo actionInfo,uint8 support,string reason,uint256 nonce)ActionInfo(uint256 id,address creator,uint8 creatorRole,address strategy,address target,uint256 value,bytes data)"
  );

  /// @notice EIP-712 castVeto typehash.
  bytes32 internal constant CAST_VETO_TYPEHASH = keccak256(
    "CastVeto(address tokenHolder,uint8 role,ActionInfo actionInfo,uint8 support,string reason,uint256 nonce)ActionInfo(uint256 id,address creator,uint8 creatorRole,address strategy,address target,uint256 value,bytes data)"
  );

  /// @dev EIP-712 actionInfo typehash.
  bytes32 internal constant ACTION_INFO_TYPEHASH = keccak256(
    "ActionInfo(uint256 id,address creator,uint8 creatorRole,address strategy,address target,uint256 value,bytes data)"
  );

  /// @dev Equivalent to 100%, but in basis points.
  uint256 internal constant ONE_HUNDRED_IN_BPS = 10_000;

  /// @notice The core contract for this Llama instance.
  ILlamaCore public llamaCore;

  /// @notice The contract that manages the timepoints for this token voting module.
  ILlamaTokenAdapter public tokenAdapter;

  /// @notice The number of tokens required to create an action.
  uint256 public creationThreshold;

  /// @dev The quorum checkpoints for this token voting module.
  QuorumCheckpoints.History internal quorumCheckpoints;

  /// @dev The period pct checkpoints for this token voting module.
  PeriodPctCheckpoints.History internal periodPctsCheckpoint;

  /// @notice The address of the tokenholder that created the action.
  mapping(uint256 => address) public actionCreators;

  /// @notice Mapping from action ID to the status of existing casts.
  mapping(uint256 actionId => CastData) public casts;

  /// @notice Mapping of tokenholders to function selectors to current nonces for EIP-712 signatures.
  /// @dev This is used to prevent replay attacks by incrementing the nonce for each operation (`castVote`,
  /// `createAction`, `cancelAction`, and `castVeto`) signed by the tokenholders.
  mapping(address tokenholders => mapping(bytes4 selector => uint256 currentNonce)) public nonces;

  // ================================
  // ======== Initialization ========
  // ================================

  /// @dev This contract is deployed as a minimal proxy from the factory's `deploy` function. The
  /// `_disableInitializers` locks the implementation (logic) contract, preventing any future initialization of it.
  constructor() {
    _disableInitializers();
  }

  /// @notice Initializes a new `LlamaTokenGovernor clone.
  /// @dev This function is called by the `deploy` function in the `LlamaTokenVotingFactory` contract.
  /// The `initializer` modifier ensures that this function can be invoked at most once.
  /// @param _llamaCore The `LlamaCore` contract for this Llama instance.
  /// @param _tokenAdapter The token adapter that manages the clock, timepoints, past votes and past supply for this
  /// token voting module.
  /// @param _creationThreshold The default number of tokens required to create an action. This must
  /// be in the same decimals as the token. For example, if the token has 18 decimals and you want a
  /// creation threshold of 1000 tokens, pass in 1000e18.
  /// @param casterConfig Contains the quorum and period pct values to initialize the contract with.
  function initialize(
    ILlamaCore _llamaCore,
    ILlamaTokenAdapter _tokenAdapter,
    uint256 _creationThreshold,
    CasterConfig memory casterConfig
  ) external initializer {
    // This call has two purposes:
    // 1. To check that _llamaCore is not the zero address (otherwise it would revert).
    // 2. By duck testing the actionsCount method we can be confident that `_llamaCore` is a `LlamaCore`contract.
    _llamaCore.actionsCount();

    llamaCore = _llamaCore;
    tokenAdapter = _tokenAdapter;
    _setActionThreshold(_creationThreshold);
    _setQuorumPct(casterConfig.voteQuorumPct, casterConfig.vetoQuorumPct);
    _setPeriodPct(casterConfig.delayPeriodPct, casterConfig.castingPeriodPct);
  }

  // ===========================================
  // ======== External and Public Logic ========
  // ===========================================

  // -------- Action Creation Lifecycle Management --------

  /// @notice Creates an action.
  /// @dev Use `""` for `description` if there is no description.
  /// @param role The role that will be used to determine the permission ID of the Token Governor.
  /// @param strategy The strategy contract that will determine how the action is executed.
  /// @param target The contract called when the action is executed.
  /// @param value The value in wei to be sent when the action is executed.
  /// @param data Data to be called on the target when the action is executed.
  /// @param description A human readable description of the action and the changes it will enact.
  /// @return actionId Action ID of the newly created action.
  function createAction(
    uint8 role,
    ILlamaStrategy strategy,
    address target,
    uint256 value,
    bytes calldata data,
    string calldata description
  ) external returns (uint256 actionId) {
    return _createAction(msg.sender, role, strategy, target, value, data, description);
  }

  /// @notice Creates an action via an off-chain signature. The creator needs to have sufficient token balance that is
  /// greater than or equal to the creation threshold.
  /// @dev Use `""` for `description` if there is no description.
  /// @param tokenHolder The tokenHolder that signed the message.
  /// @param role The role that will be used to determine the permission ID of the Token Governor.
  /// @param strategy The strategy contract that will determine how the action is executed.
  /// @param target The contract called when the action is executed.
  /// @param value The value in wei to be sent when the action is executed.
  /// @param data Data to be called on the target when the action is executed.
  /// @param description A human readable description of the action and the changes it will enact.
  /// @param v ECDSA signature component: Parity of the `y` coordinate of point `R`
  /// @param r ECDSA signature component: x-coordinate of `R`
  /// @param s ECDSA signature component: `s` value of the signature
  /// @return actionId Action ID of the newly created action.
  function createActionBySig(
    address tokenHolder,
    uint8 role,
    ILlamaStrategy strategy,
    address target,
    uint256 value,
    bytes calldata data,
    string memory description,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 actionId) {
    bytes32 digest = _getCreateActionTypedDataHash(tokenHolder, role, strategy, target, value, data, description);
    address signer = ecrecover(digest, v, r, s);
    if (signer == address(0) || signer != tokenHolder) revert InvalidSignature();
    actionId = _createAction(signer, role, strategy, target, value, data, description);
  }

  /// @notice Cancels an action.
  /// @param actionInfo The action to cancel.
  /// @dev Relies on the validation checks in `LlamaCore.cancelAction()`.
  function cancelAction(ActionInfo calldata actionInfo) external {
    _cancelAction(msg.sender, actionInfo);
  }

  /// @notice Cancels an action by its `actionInfo` struct via an off-chain signature.
  /// @dev Rules for cancelation are defined by the strategy.
  /// @param policyholder The policyholder that signed the message.
  /// @param actionInfo Data required to create an action.
  /// @param v ECDSA signature component: Parity of the `y` coordinate of point `R`
  /// @param r ECDSA signature component: x-coordinate of `R`
  /// @param s ECDSA signature component: `s` value of the signature
  function cancelActionBySig(address policyholder, ActionInfo calldata actionInfo, uint8 v, bytes32 r, bytes32 s)
    external
  {
    bytes32 digest = _getCancelActionTypedDataHash(policyholder, actionInfo);
    address signer = ecrecover(digest, v, r, s);
    if (signer == address(0) || signer != policyholder) revert InvalidSignature();
    _cancelAction(signer, actionInfo);
  }

  // -------- Action Casting Lifecycle Management --------

  /// @notice How tokenholders add their support of the approval of an action with a reason.
  /// @dev Use `""` for `reason` if there is no reason.
  /// @param role This needs to be a role that the token governor can use to successfully cast an approval on the
  /// action, but it does not need to be the role that will be used by `submitApproval`. This allows `castVote` to check
  /// that the token governor can successfully cast an approval for the action provided, without calculating which role
  /// will be used on every `castVote` call.
  /// @param actionInfo Data required to create an action.
  /// @param support The tokenholder's support of the approval of the action.
  ///   0 = Against
  ///   1 = For
  ///   2 = Abstain
  /// @param reason The reason given for the approval by the tokenholder.
  /// @return The weight of the cast.
  function castVote(uint8 role, ActionInfo calldata actionInfo, uint8 support, string calldata reason)
    external
    returns (uint128)
  {
    return _castVote(msg.sender, role, actionInfo, support, reason);
  }

  /// @notice How tokenholders add their support of the approval of an action with a reason via an off-chain
  /// signature.
  /// @dev Use `""` for `reason` if there is no reason.
  /// @param caster The tokenholder that signed the message.
  /// @param role This needs to be a role that the token governor can use to successfully cast an approval on the
  /// action, but it does not need to be the role that will be used by `submitApproval`. This allows `castVote` to check
  /// that the token governor can successfully cast an approval for the action provided, without calculating which role
  /// will be used on every `castVote` call.
  /// @param actionInfo Data required to create an action.
  /// @param support The tokenholder's support of the approval of the action.
  ///   0 = Against
  ///   1 = For
  ///   2 = Abstain
  /// @param reason The reason given for the approval by the tokenholder.
  /// @param v ECDSA signature component: Parity of the `y` coordinate of point `R`
  /// @param r ECDSA signature component: x-coordinate of `R`
  /// @param s ECDSA signature component: `s` value of the signature
  /// @return The weight of the cast.
  function castVoteBySig(
    address caster,
    uint8 role,
    ActionInfo calldata actionInfo,
    uint8 support,
    string calldata reason,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint128) {
    bytes32 digest = _getCastVoteTypedDataHash(caster, role, actionInfo, support, reason);
    address signer = ecrecover(digest, v, r, s);
    if (signer == address(0) || signer != caster) revert InvalidSignature();
    return _castVote(signer, role, actionInfo, support, reason);
  }

  /// @notice How tokenholders add their support of the disapproval of an action with a reason.
  /// @dev Use `""` for `reason` if there is no reason.
  /// @param role This needs to be a role that the token governor can use to successfully cast a disapproval on the
  /// action, but it does not need to be the role that will be used by `submitDisapproval`. This allows `castVeto` to
  /// check that the token governor can successfully cast a disapproval for the action provided, without calculating
  /// which role will be used on every `castVeto` call.
  /// @param actionInfo Data required to create an action.
  /// @param support The tokenholder's support of the approval of the action.
  ///   0 = Against
  ///   1 = For
  ///   2 = Abstain
  /// @param reason The reason given for the approval by the tokenholder.
  /// @return The weight of the cast.
  function castVeto(uint8 role, ActionInfo calldata actionInfo, uint8 support, string calldata reason)
    external
    returns (uint128)
  {
    return _castVeto(msg.sender, role, actionInfo, support, reason);
  }

  /// @notice How tokenholders add their support of the disapproval of an action with a reason via an off-chain
  /// signature.
  /// @dev Use `""` for `reason` if there is no reason.
  /// @param caster The tokenholder that signed the message.
  /// @param role This needs to be a role that the token governor can use to successfully cast a disapproval on the
  /// action, but it does not need to be the role that will be used by `submitDisapproval`. This allows `castVeto` to
  /// check that the token governor can successfully cast a disapproval for the action provided, without calculating
  /// which role will be used on every `castVeto` call.
  /// @param actionInfo Data required to create an action.
  /// @param support The tokenholder's support of the approval of the action.
  ///   0 = Against
  ///   1 = For
  ///   2 = Abstain
  /// @param reason The reason given for the approval by the tokenholder.
  /// @param v ECDSA signature component: Parity of the `y` coordinate of point `R`
  /// @param r ECDSA signature component: x-coordinate of `R`
  /// @param s ECDSA signature component: `s` value of the signature
  /// @return The weight of the cast.
  function castVetoBySig(
    address caster,
    uint8 role,
    ActionInfo calldata actionInfo,
    uint8 support,
    string calldata reason,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint128) {
    bytes32 digest = _getCastVetoTypedDataHash(caster, role, actionInfo, support, reason);
    address signer = ecrecover(digest, v, r, s);
    if (signer == address(0) || signer != caster) revert InvalidSignature();
    return _castVeto(signer, role, actionInfo, support, reason);
  }

  /// @notice Submits a cast approval to the `LlamaCore` contract.
  /// @param actionInfo Data required to create an action.
  /// @dev This function can be called by anyone.
  function submitApproval(ActionInfo calldata actionInfo) external {
    Action memory action = llamaCore.getAction(actionInfo.id);
    uint256 checkpointTime = action.creationTime - 1;

    // Reverts if clock or CLOCK_MODE() has changed
    tokenAdapter.checkIfInconsistentClock();

    uint256 delayPeriodEndTime;
    uint256 castingPeriodEndTime;
    // Scoping to prevent stack too deep errors.
    {
      // Checks to ensure it's the submission period.
      (uint16 delayPeriodPct, uint16 castingPeriodPct) =
        periodPctsCheckpoint.getAtProbablyRecentTimestamp(checkpointTime);
      uint256 approvalPeriod = actionInfo.strategy.approvalPeriod();
      unchecked {
        delayPeriodEndTime = action.creationTime + ((approvalPeriod * delayPeriodPct) / ONE_HUNDRED_IN_BPS);
        castingPeriodEndTime = delayPeriodEndTime + ((approvalPeriod * castingPeriodPct) / ONE_HUNDRED_IN_BPS);
      }
      if (block.timestamp <= castingPeriodEndTime) revert CastingPeriodNotOver();
      // submissionPeriod is implicitly calculated as (approvalPeriod - delayPeriod - castingPeriod).
      // Llama approval period is inclusive of approval end time.
      if (block.timestamp > action.creationTime + approvalPeriod) revert SubmissionPeriodOver();
    }

    CastData storage castData = casts[actionInfo.id];

    uint256 totalSupply = tokenAdapter.getPastTotalSupply(tokenAdapter.timestampToTimepoint(delayPeriodEndTime));
    uint128 votesFor = castData.votesFor;
    uint128 votesAgainst = castData.votesAgainst;
    uint128 votesAbstain = castData.votesAbstain;
    (uint16 voteQuorumPct,) = quorumCheckpoints.getAtProbablyRecentTimestamp(checkpointTime);
    uint256 threshold = FixedPointMathLib.mulDivUp(totalSupply, voteQuorumPct, ONE_HUNDRED_IN_BPS);
    if (votesFor < threshold) revert InsufficientVotes(votesFor, threshold);
    if (votesFor <= votesAgainst) revert ForDoesNotSurpassAgainst(votesFor, votesAgainst);

    uint8 governorRole = _determineGovernorRole(actionInfo.strategy, true);
    llamaCore.castApproval(governorRole, actionInfo, "");
    emit ApprovalSubmitted(actionInfo.id, msg.sender, governorRole, votesFor, votesAgainst, votesAbstain);
  }

  /// @notice Submits a cast disapproval to the `LlamaCore` contract.
  /// @param actionInfo Data required to create an action.
  /// @dev This function can be called by anyone.
  function submitDisapproval(ActionInfo calldata actionInfo) external {
    Action memory action = llamaCore.getAction(actionInfo.id);
    uint256 checkpointTime = action.creationTime - 1;

    // Reverts if clock or CLOCK_MODE() has changed
    tokenAdapter.checkIfInconsistentClock();

    uint256 delayPeriodEndTime;
    uint256 castingPeriodEndTime;
    // Scoping to prevent stack too deep errors.
    {
      // Checks to ensure it's the submission period.
      (uint16 delayPeriodPct, uint16 castingPeriodPct) =
        periodPctsCheckpoint.getAtProbablyRecentTimestamp(checkpointTime);
      uint256 queuingPeriod = actionInfo.strategy.queuingPeriod();
      unchecked {
        delayPeriodEndTime =
          (action.minExecutionTime - queuingPeriod) + ((queuingPeriod * delayPeriodPct) / ONE_HUNDRED_IN_BPS);
        castingPeriodEndTime = delayPeriodEndTime + ((queuingPeriod * castingPeriodPct) / ONE_HUNDRED_IN_BPS);
      }
      // submissionPeriod is implicitly calculated as (queuingPeriod - delayPeriod - castingPeriod).
      if (block.timestamp <= castingPeriodEndTime) revert CastingPeriodNotOver();
      // Llama disapproval period is exclusive of min execution time.
      if (block.timestamp >= action.minExecutionTime) revert SubmissionPeriodOver();
    }

    CastData storage castData = casts[actionInfo.id];

    uint256 totalSupply = tokenAdapter.getPastTotalSupply(tokenAdapter.timestampToTimepoint(delayPeriodEndTime));
    uint128 vetoesFor = castData.vetoesFor;
    uint128 vetoesAgainst = castData.vetoesAgainst;
    uint128 vetoesAbstain = castData.vetoesAbstain;
    (, uint16 vetoQuorumPct) = quorumCheckpoints.getAtProbablyRecentTimestamp(checkpointTime);
    uint256 threshold = FixedPointMathLib.mulDivUp(totalSupply, vetoQuorumPct, ONE_HUNDRED_IN_BPS);
    if (vetoesFor < threshold) revert InsufficientVetoes(vetoesFor, threshold);
    if (vetoesFor <= vetoesAgainst) revert ForDoesNotSurpassAgainst(vetoesFor, vetoesAgainst);

    uint8 governorRole = _determineGovernorRole(actionInfo.strategy, false);
    llamaCore.castDisapproval(governorRole, actionInfo, "");
    emit DisapprovalSubmitted(actionInfo.id, msg.sender, governorRole, vetoesFor, vetoesAgainst, vetoesAbstain);
  }

  // -------- Instance Management --------

  /// @notice Sets the default number of tokens required to create an action.
  /// @param _creationThreshold The number of tokens required to create an action.
  /// @dev This must be in the same decimals as the token.
  function setActionThreshold(uint256 _creationThreshold) external onlyLlama {
    _setActionThreshold(_creationThreshold);
  }

  /// @notice Sets the vote quorum and veto quorum for submitting a (dis)approval to `LlamaCore`.
  /// @param _voteQuorumPct The minimum % of total supply that must be casted as `For` votes.
  /// @param _vetoQuorumPct The minimum % of total supply that must be casted as `For` vetoes.
  function setQuorumPct(uint16 _voteQuorumPct, uint16 _vetoQuorumPct) external onlyLlama {
    _setQuorumPct(_voteQuorumPct, _vetoQuorumPct);
  }

  /// @notice Sets the delay period and casting period.
  /// @dev The submission period is implicitly equal to `ONE_HUNDRED_IN_BPS - delayPeriodPct - castingPeriodPct`
  /// @param _delayPeriodPct The % of the total approval or queuing period used as a delay.
  /// @param _castingPeriodPct The % of the total approval or queuing period used to cast votes or vetoes.
  function setPeriodPct(uint16 _delayPeriodPct, uint16 _castingPeriodPct) external onlyLlama {
    _setPeriodPct(_delayPeriodPct, _castingPeriodPct);
  }

  // -------- User Nonce Management --------

  /// @notice Increments the caller's nonce for the given `selector`. This is useful for revoking
  /// signatures that have not been used yet.
  /// @param selector The function selector to increment the nonce for.
  function incrementNonce(bytes4 selector) external {
    // Safety: Can never overflow a uint256 by incrementing.
    nonces[msg.sender][selector] = LlamaUtils.uncheckedIncrement(nonces[msg.sender][selector]);
  }

  // -------- Getters --------

  /// @notice Returns if a token holder has cast (vote or veto) yet for a given action.
  /// @param actionId ID of the action.
  /// @param tokenholder The tokenholder to check.
  /// @param isVote `true` if checking for a vote, `false` if checking for a veto.
  function hasTokenHolderCast(uint256 actionId, address tokenholder, bool isVote) external view returns (bool) {
    if (isVote) return casts[actionId].castVote[tokenholder];
    else return casts[actionId].castVeto[tokenholder];
  }

  /// @notice Returns the current voting quorum and vetoing quorum.
  /// @return The current voting quorum and vetoing quorum.
  function getQuorum() external view returns (uint16, uint16) {
    return quorumCheckpoints.latest();
  }

  /// @notice Returns the voting quorum and vetoing quorum at a given timestamp.
  /// @param timestamp The timestamp to get the quorums at.
  /// @return The voting quorum and vetoing quorum at a given timestamp.
  function getPastQuorum(uint256 timestamp) external view returns (uint16, uint16) {
    return quorumCheckpoints.getAtProbablyRecentTimestamp(timestamp);
  }

  /// @notice Returns all quorum checkpoints.
  /// @return All quorum checkpoints.
  function getQuorumCheckpoints() external view returns (QuorumCheckpoints.History memory) {
    return quorumCheckpoints;
  }

  /// @notice Returns the quorum checkpoints array from a given set of indices.
  /// @param start Start index of the checkpoints to get from their checkpoint history array. This index is inclusive.
  /// @param end End index of the checkpoints to get from their checkpoint history array. This index is exclusive.
  /// @return The quorum checkpoints array from a given set of indices.
  function getQuorumCheckpoints(uint256 start, uint256 end) external view returns (QuorumCheckpoints.History memory) {
    if (start > end) revert InvalidIndices();
    uint256 checkpointsLength = quorumCheckpoints._checkpoints.length;
    if (end > checkpointsLength) revert InvalidIndices();

    uint256 sliceLength = end - start;
    QuorumCheckpoints.Checkpoint[] memory checkpoints = new QuorumCheckpoints.Checkpoint[](sliceLength);
    for (uint256 i = start; i < end; i = LlamaUtils.uncheckedIncrement(i)) {
      checkpoints[i - start] = quorumCheckpoints._checkpoints[i];
    }
    return QuorumCheckpoints.History(checkpoints);
  }

  /// @notice Returns the current delay and casting period percentages.
  /// @return The current delay and casting period percentages.
  function getPeriodPcts() external view returns (uint16, uint16) {
    return periodPctsCheckpoint.latest();
  }

  /// @notice Returns the delay and casting period percentages at a given timestamp.
  /// @param timestamp The timestamp to get the period percentages at.
  /// @return The delay and casting period percentages at a given timestamp.
  function getPastPeriodPcts(uint256 timestamp) external view returns (uint16, uint16) {
    return periodPctsCheckpoint.getAtProbablyRecentTimestamp(timestamp);
  }

  /// @notice Returns all period pct checkpoints.
  /// @return All period pct checkpoints.
  function getPeriodPctCheckpoints() external view returns (PeriodPctCheckpoints.History memory) {
    return periodPctsCheckpoint;
  }

  /// @notice Returns the period pct checkpoints array from a given set of indices.
  /// @param start Start index of the checkpoints to get from their checkpoint history array. This index is inclusive.
  /// @param end End index of the checkpoints to get from their checkpoint history array. This index is exclusive.
  /// @return The period pct checkpoints array from a given set of indices.
  function getPeriodPctCheckpoints(uint256 start, uint256 end)
    external
    view
    returns (PeriodPctCheckpoints.History memory)
  {
    if (start > end) revert InvalidIndices();
    uint256 checkpointsLength = periodPctsCheckpoint._checkpoints.length;
    if (end > checkpointsLength) revert InvalidIndices();

    uint256 sliceLength = end - start;
    PeriodPctCheckpoints.Checkpoint[] memory checkpoints = new PeriodPctCheckpoints.Checkpoint[](sliceLength);
    for (uint256 i = start; i < end; i = LlamaUtils.uncheckedIncrement(i)) {
      checkpoints[i - start] = periodPctsCheckpoint._checkpoints[i];
    }
    return PeriodPctCheckpoints.History(checkpoints);
  }

  // ================================
  // ======== Internal Logic ========
  // ================================

  // -------- Action Creation Internal Functions --------

  /// @dev Creates an action. The creator needs to have sufficient token balance.
  function _createAction(
    address tokenHolder,
    uint8 role,
    ILlamaStrategy strategy,
    address target,
    uint256 value,
    bytes calldata data,
    string memory description
  ) internal returns (uint256 actionId) {
    // Reverts if clock or CLOCK_MODE() has changed
    tokenAdapter.checkIfInconsistentClock();

    uint256 balance = tokenAdapter.getPastVotes(tokenHolder, tokenAdapter.clock() - 1);
    if (balance < creationThreshold) revert InsufficientBalance(balance);

    actionId = llamaCore.createAction(role, strategy, target, value, data, description);
    actionCreators[actionId] = tokenHolder;
    emit ActionCreated(actionId, tokenHolder);
  }

  /// @dev Cancels an action by its `actionInfo` struct. Only the action creator can cancel.
  function _cancelAction(address creator, ActionInfo calldata actionInfo) internal {
    if (creator != actionCreators[actionInfo.id]) revert OnlyActionCreator();
    llamaCore.cancelAction(actionInfo);
    emit ActionCanceled(actionInfo.id, creator);
  }

  // -------- Action Casting Internal Functions --------

  /// @dev How token holders add their support of the approval of an action with a reason.
  function _castVote(address caster, uint8 role, ActionInfo calldata actionInfo, uint8 support, string calldata reason)
    internal
    returns (uint128)
  {
    Action memory action = llamaCore.getAction(actionInfo.id);
    uint256 checkpointTime = action.creationTime - 1;

    CastData storage castData = casts[actionInfo.id];

    actionInfo.strategy.checkIfApprovalEnabled(actionInfo, address(this), role); // Reverts if not allowed.
    if (castData.castVote[caster]) revert DuplicateCast();
    _preCastAssertions(actionInfo, role, support, ActionState.Active, checkpointTime);

    uint256 delayPeriodEndTime;
    uint256 castingPeriodEndTime;
    // Scoping to prevent stack too deep errors.
    {
      // Checks to ensure it's the casting period.
      (uint16 delayPeriodPct, uint16 castingPeriodPct) =
        periodPctsCheckpoint.getAtProbablyRecentTimestamp(checkpointTime);
      uint256 approvalPeriod = actionInfo.strategy.approvalPeriod();
      unchecked {
        delayPeriodEndTime = action.creationTime + ((approvalPeriod * delayPeriodPct) / ONE_HUNDRED_IN_BPS);
        castingPeriodEndTime = delayPeriodEndTime + ((approvalPeriod * castingPeriodPct) / ONE_HUNDRED_IN_BPS);
      }
      if (block.timestamp <= delayPeriodEndTime) revert DelayPeriodNotOver();
      if (block.timestamp > castingPeriodEndTime) revert CastingPeriodOver();
    }

    uint128 weight =
      LlamaUtils.toUint128(tokenAdapter.getPastVotes(caster, tokenAdapter.timestampToTimepoint(delayPeriodEndTime)));

    if (support == uint8(VoteType.Against)) castData.votesAgainst = _newCastCount(castData.votesAgainst, weight);
    else if (support == uint8(VoteType.For)) castData.votesFor = _newCastCount(castData.votesFor, weight);
    else if (support == uint8(VoteType.Abstain)) castData.votesAbstain = _newCastCount(castData.votesAbstain, weight);
    castData.castVote[caster] = true;

    emit VoteCast(actionInfo.id, caster, support, weight, reason);
    return weight;
  }

  /// @dev How token holders add their support of the disapproval of an action with a reason.
  function _castVeto(address caster, uint8 role, ActionInfo calldata actionInfo, uint8 support, string calldata reason)
    internal
    returns (uint128)
  {
    Action memory action = llamaCore.getAction(actionInfo.id);
    uint256 checkpointTime = action.creationTime - 1;

    CastData storage castData = casts[actionInfo.id];

    actionInfo.strategy.checkIfDisapprovalEnabled(actionInfo, address(this), role); // Reverts if not allowed.
    if (castData.castVeto[caster]) revert DuplicateCast();
    _preCastAssertions(actionInfo, role, support, ActionState.Queued, checkpointTime);

    uint256 delayPeriodEndTime;
    uint256 castingPeriodEndTime;
    // Scoping to prevent stack too deep errors.
    {
      // Checks to ensure it's the casting period.
      (uint16 delayPeriodPct, uint16 castingPeriodPct) =
        periodPctsCheckpoint.getAtProbablyRecentTimestamp(checkpointTime);
      uint256 queuingPeriod = actionInfo.strategy.queuingPeriod();
      unchecked {
        delayPeriodEndTime =
          (action.minExecutionTime - queuingPeriod) + ((queuingPeriod * delayPeriodPct) / ONE_HUNDRED_IN_BPS);
        castingPeriodEndTime = delayPeriodEndTime + ((queuingPeriod * castingPeriodPct) / ONE_HUNDRED_IN_BPS);
      }
      if (block.timestamp <= delayPeriodEndTime) revert DelayPeriodNotOver();
      if (block.timestamp > castingPeriodEndTime) revert CastingPeriodOver();
    }

    uint128 weight =
      LlamaUtils.toUint128(tokenAdapter.getPastVotes(caster, tokenAdapter.timestampToTimepoint(delayPeriodEndTime)));

    if (support == uint8(VoteType.Against)) castData.vetoesAgainst = _newCastCount(castData.vetoesAgainst, weight);
    else if (support == uint8(VoteType.For)) castData.vetoesFor = _newCastCount(castData.vetoesFor, weight);
    else if (support == uint8(VoteType.Abstain)) castData.vetoesAbstain = _newCastCount(castData.vetoesAbstain, weight);
    castData.castVeto[caster] = true;

    emit VetoCast(actionInfo.id, caster, support, weight, reason);
    return weight;
  }

  /// @dev The only `support` values allowed to be passed into this method are Against (0), For (1) or Abstain (2).
  function _preCastAssertions(
    ActionInfo calldata actionInfo,
    uint8 role,
    uint8 support,
    ActionState expectedState,
    uint256 checkpointTime
  ) internal view {
    if (support > uint8(VoteType.Abstain)) revert InvalidSupport(support);

    ActionState currentState = ActionState(llamaCore.getActionState(actionInfo));
    if (currentState != expectedState) revert InvalidActionState(currentState);

    bool hasRole = llamaCore.policy().hasRole(address(this), role, checkpointTime);
    if (!hasRole) revert InvalidPolicyholder();

    // Reverts if clock or CLOCK_MODE() has changed
    tokenAdapter.checkIfInconsistentClock();
  }

  /// @dev Returns the new total count of votes or vetoes in Against (0), For (1) or Abstain (2).
  function _newCastCount(uint128 currentCount, uint128 weight) internal pure returns (uint128) {
    if (uint256(currentCount) + weight >= type(uint128).max) return type(uint128).max;
    return currentCount + weight;
  }

  /// @dev Returns the role that the Token Governor should use when casting an approval or disapproval to `LlamaCore`.
  function _determineGovernorRole(ILlamaStrategy strategy, bool isApproval) internal view returns (uint8) {
    uint8 maxInitializedRole = llamaCore.policy().numRoles();
    // We start from i = 1 here because a value of zero is reserved for the "all holders" role.
    // The "All holders" role cannot be used as a force approval or disapproval role in relative or absolute strategies.
    // Similarly, use we `<=` to make sure we check the last role.
    for (uint256 i = 1; i <= maxInitializedRole; i = LlamaUtils.uncheckedIncrement(i)) {
      if (isApproval ? strategy.forceApprovalRole(uint8(i)) : strategy.forceDisapprovalRole(uint8(i))) return uint8(i);
    }
    return isApproval ? strategy.approvalRole() : strategy.disapprovalRole();
  }

  // -------- Instance Management Internal Functions --------

  /// @dev Sets the default number of tokens required to create an action.
  function _setActionThreshold(uint256 _creationThreshold) internal {
    uint256 totalSupply = tokenAdapter.getPastTotalSupply(tokenAdapter.clock() - 1);
    if (totalSupply == 0) revert InvalidTotalSupply();
    if (_creationThreshold > totalSupply) revert InvalidCreationThreshold();
    creationThreshold = _creationThreshold;
    emit ActionThresholdSet(_creationThreshold);
  }

  /// @dev Sets the voting quorum and vetoing quorum.
  function _setQuorumPct(uint16 _voteQuorumPct, uint16 _vetoQuorumPct) internal {
    if (_voteQuorumPct > ONE_HUNDRED_IN_BPS || _voteQuorumPct == 0) revert InvalidVoteQuorumPct(_voteQuorumPct);
    if (_vetoQuorumPct > ONE_HUNDRED_IN_BPS || _vetoQuorumPct == 0) revert InvalidVetoQuorumPct(_vetoQuorumPct);
    quorumCheckpoints.push(_voteQuorumPct, _vetoQuorumPct);
    emit QuorumPctSet(_voteQuorumPct, _vetoQuorumPct);
  }

  /// @dev Sets the delay and casting period percentages. The submission period is implicitly equal to
  /// `ONE_HUNDRED_IN_BPS - _delayPeriodPct - _castingPeriodPct`
  function _setPeriodPct(uint16 _delayPeriodPct, uint16 _castingPeriodPct) internal {
    if (_delayPeriodPct + _castingPeriodPct >= ONE_HUNDRED_IN_BPS) {
      revert InvalidPeriodPcts(_delayPeriodPct, _castingPeriodPct);
    }
    periodPctsCheckpoint.push(_delayPeriodPct, _castingPeriodPct);
    emit PeriodPctSet(_delayPeriodPct, _castingPeriodPct);
  }

  // -------- User Nonce Management Internal Functions --------

  /// @dev Returns the current nonce for a given tokenHolder and selector, and increments it. Used to prevent
  /// replay attacks.
  function _useNonce(address tokenHolder, bytes4 selector) internal returns (uint256 nonce) {
    nonce = nonces[tokenHolder][selector];
    nonces[tokenHolder][selector] = LlamaUtils.uncheckedIncrement(nonce);
  }

  // -------- EIP-712 Getters --------

  /// @dev Returns the EIP-712 domain separator.
  function _getDomainHash() internal view returns (bytes32) {
    return keccak256(
      abi.encode(
        EIP712_DOMAIN_TYPEHASH, keccak256(bytes(llamaCore.name())), keccak256(bytes("1")), block.chainid, address(this)
      )
    );
  }

  /// @dev Returns the hash of the ABI-encoded EIP-712 message for the `CreateAction` domain, which can be used to
  /// recover the signer.
  function _getCreateActionTypedDataHash(
    address tokenHolder,
    uint8 role,
    ILlamaStrategy strategy,
    address target,
    uint256 value,
    bytes calldata data,
    string memory description
  ) internal returns (bytes32) {
    // Calculating and storing nonce in memory and using that below, instead of calculating in place to prevent stack
    // too deep error.
    uint256 nonce = _useNonce(tokenHolder, msg.sig);

    bytes32 createActionHash = keccak256(
      abi.encode(
        CREATE_ACTION_TYPEHASH,
        tokenHolder,
        role,
        address(strategy),
        target,
        value,
        keccak256(data),
        keccak256(bytes(description)),
        nonce
      )
    );

    return keccak256(abi.encodePacked("\x19\x01", _getDomainHash(), createActionHash));
  }

  /// @dev Returns the hash of the ABI-encoded EIP-712 message for the `CancelAction` domain, which can be used to
  /// recover the signer.
  function _getCancelActionTypedDataHash(address tokenHolder, ActionInfo calldata actionInfo)
    internal
    returns (bytes32)
  {
    bytes32 cancelActionHash = keccak256(
      abi.encode(CANCEL_ACTION_TYPEHASH, tokenHolder, _getActionInfoHash(actionInfo), _useNonce(tokenHolder, msg.sig))
    );

    return keccak256(abi.encodePacked("\x19\x01", _getDomainHash(), cancelActionHash));
  }

  /// @dev Returns the hash of the ABI-encoded EIP-712 message for the `CastApproval` domain, which can be used to
  /// recover the signer.
  function _getCastVoteTypedDataHash(
    address tokenholder,
    uint8 role,
    ActionInfo calldata actionInfo,
    uint8 support,
    string calldata reason
  ) internal returns (bytes32) {
    bytes32 castVoteHash = keccak256(
      abi.encode(
        CAST_VOTE_TYPEHASH,
        tokenholder,
        role,
        _getActionInfoHash(actionInfo),
        support,
        keccak256(bytes(reason)),
        _useNonce(tokenholder, msg.sig)
      )
    );

    return keccak256(abi.encodePacked("\x19\x01", _getDomainHash(), castVoteHash));
  }

  /// @dev Returns the hash of the ABI-encoded EIP-712 message for the `CastDisapproval` domain, which can be used to
  /// recover the signer.
  function _getCastVetoTypedDataHash(
    address tokenholder,
    uint8 role,
    ActionInfo calldata actionInfo,
    uint8 support,
    string calldata reason
  ) internal returns (bytes32) {
    bytes32 castVetoHash = keccak256(
      abi.encode(
        CAST_VETO_TYPEHASH,
        tokenholder,
        role,
        _getActionInfoHash(actionInfo),
        support,
        keccak256(bytes(reason)),
        _useNonce(tokenholder, msg.sig)
      )
    );

    return keccak256(abi.encodePacked("\x19\x01", _getDomainHash(), castVetoHash));
  }

  /// @dev Returns the hash of `actionInfo`.
  function _getActionInfoHash(ActionInfo calldata actionInfo) internal pure returns (bytes32) {
    return keccak256(
      abi.encode(
        ACTION_INFO_TYPEHASH,
        actionInfo.id,
        actionInfo.creator,
        actionInfo.creatorRole,
        address(actionInfo.strategy),
        actionInfo.target,
        actionInfo.value,
        keccak256(actionInfo.data)
      )
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
// TODO This interface was generated from `cast interface`, so some types are not as strong as they
// could be. For example, the existing `ILlamaStrategy` were all `address` until they were manually
// changed. So there are probably other types that need to be updated also.
pragma solidity ^0.8.23;

import {ILlamaPolicy} from "src/interfaces/ILlamaPolicy.sol";
import {ILlamaStrategy} from "src/interfaces/ILlamaStrategy.sol";
import {ActionState} from "src/lib/Enums.sol";
import {
  Action,
  ActionInfo,
  LlamaInstanceConfig,
  LlamaPolicyConfig,
  PermissionData,
  RoleHolderData,
  RolePermissionData
} from "src/lib/Structs.sol";

/// @title LlamaCore Interface
/// @author Llama ([email protected])
/// @notice This is the interface for LlamaCore.
interface ILlamaCore {
  error InvalidSignature();

  error PolicyholderDoesNotHavePermission();

  /// @dev The action is not in the expected state.
  /// @param current The current state of the action.
  error InvalidActionState(ActionState current);

  function actionGuard(address target, bytes4 selector) external view returns (address guard);

  function actionsCount() external view returns (uint256);

  function approvals(uint256 actionId, address policyholder) external view returns (bool hasApproved);

  function authorizedAccountLogics(address accountLogic) external view returns (bool isAuthorized);

  function authorizedScripts(address script) external view returns (bool isAuthorized);

  function authorizedStrategyLogics(ILlamaStrategy strategyLogic) external view returns (bool isAuthorized);

  function cancelAction(ActionInfo memory actionInfo) external;

  function cancelActionBySig(address policyholder, ActionInfo memory actionInfo, uint8 v, bytes32 r, bytes32 s)
    external;

  function castApproval(uint8 role, ActionInfo memory actionInfo, string memory reason) external returns (uint96);

  function castApprovalBySig(
    address policyholder,
    uint8 role,
    ActionInfo memory actionInfo,
    string memory reason,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint96);

  function castDisapproval(uint8 role, ActionInfo memory actionInfo, string memory reason) external returns (uint96);

  function castDisapprovalBySig(
    address policyholder,
    uint8 role,
    ActionInfo memory actionInfo,
    string memory reason,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint96);

  function createAccounts(address llamaAccountLogic, bytes[] memory accountConfigs) external;

  function createAction(
    uint8 role,
    ILlamaStrategy strategy,
    address target,
    uint256 value,
    bytes memory data,
    string memory description
  ) external returns (uint256 actionId);

  function createActionBySig(
    address policyholder,
    uint8 role,
    ILlamaStrategy strategy,
    address target,
    uint256 value,
    bytes memory data,
    string memory description,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 actionId);

  function createStrategies(address llamaStrategyLogic, bytes[] memory strategyConfigs) external;

  function disapprovals(uint256 actionId, address policyholder) external view returns (bool hasDisapproved);

  function executeAction(ActionInfo memory actionInfo) external payable;

  function executor() external view returns (address);

  function getAction(uint256 actionId) external view returns (Action memory);

  function getActionState(ActionInfo memory actionInfo) external view returns (uint8);

  function incrementNonce(bytes4 selector) external;

  function initialize(LlamaInstanceConfig memory config, address policyLogic, address policyMetadataLogic) external;

  function name() external view returns (string memory);

  function nonces(address policyholder, bytes4 selector) external view returns (uint256 currentNonce);

  function policy() external view returns (ILlamaPolicy);

  function queueAction(ActionInfo memory actionInfo) external;

  function setAccountLogicAuthorization(address accountLogic, bool authorized) external;

  function setGuard(address target, bytes4 selector, address guard) external;

  function setScriptAuthorization(address script, bool authorized) external;

  function setStrategyAuthorization(ILlamaStrategy strategy, bool authorized) external;

  function setStrategyLogicAuthorization(ILlamaStrategy strategyLogic, bool authorized) external;

  function strategies(ILlamaStrategy strategy) external view returns (bool deployed, bool authorized);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ActionInfo} from "src/lib/Structs.sol";
import {ILlamaCore} from "src/interfaces/ILlamaCore.sol";
import {ILlamaPolicy} from "src/interfaces/ILlamaPolicy.sol";

/// @title Llama Strategy Interface
/// @author Llama ([email protected])
/// @notice This is the interface for Llama strategies which determine the rules of an action's process.
/// @dev The interface is sorted by the stage of the action's lifecycle in which the method's are used.
interface ILlamaStrategy {
  // -------- For Inspection --------
  // These are not strictly required by the core, but are useful for inspecting a strategy contract.

  /// @notice Returns the address of the Llama core that this strategy is registered to.
  function llamaCore() external view returns (ILlamaCore);

  /// @notice Returns the name of the Llama policy that this strategy is registered to.
  function policy() external view returns (ILlamaPolicy);

  // -------- Required for Strategies used with LlamaTokenGovernor --------

  /// @notice Returns the approval period of the strategy in seconds.
  function approvalPeriod() external view returns (uint64);

  /// @notice Returns the queuing period of the strategy in seconds.
  function queuingPeriod() external view returns (uint64);

  /// @notice The role that can approve an action.
  function approvalRole() external view returns (uint8);

  /// @notice The role that can disapprove an action.
  function disapprovalRole() external view returns (uint8);

  /// @notice Returns true if an action can force an action to be approved and false otherwise.
  function forceApprovalRole(uint8 role) external view returns (bool isForceApproval);

  /// @notice Returns true if an action can force an action to be disapproved and false otherwise.
  function forceDisapprovalRole(uint8 role) external view returns (bool isForceDisapproval);

  // -------- At Strategy Creation --------

  /// @notice Initializes a new clone of the strategy.
  /// @dev This function is called by the `_deployStrategies` function in the `LlamaCore` contract. The `initializer`
  /// modifier ensures that this function can be invoked at most once.
  /// @param config The strategy configuration, encoded as bytes to support differing constructor arguments in
  /// different strategies.
  /// @return This return statement must be hardcoded to `true` to ensure that initializing an EOA
  /// (like the zero address) will revert.
  function initialize(bytes memory config) external returns (bool);

  // -------- At Action Creation --------

  /// @notice Reverts if action creation is not allowed.
  /// @param actionInfo Data required to create an action.
  function validateActionCreation(ActionInfo calldata actionInfo) external view;

  // -------- When Casting Approval --------

  /// @notice Reverts if approvals are not allowed with this strategy for the given policyholder when approving with
  /// role.
  /// @param actionInfo Data required to create an action.
  /// @param policyholder Address of the policyholder.
  /// @param role The role of the policyholder being used to cast approval.
  function checkIfApprovalEnabled(ActionInfo calldata actionInfo, address policyholder, uint8 role) external view;

  /// @notice Get the quantity of an approval of a policyholder at a specific timestamp.
  /// @param policyholder Address of the policyholder.
  /// @param role The role to check quantity for.
  /// @param timestamp The timestamp at which to get the approval quantity.
  /// @return The quantity of the policyholder's approval.
  function getApprovalQuantityAt(address policyholder, uint8 role, uint256 timestamp) external view returns (uint96);

  // -------- When Casting Disapproval --------

  /// @notice Reverts if disapprovals are not allowed with this strategy for the given policyholder when disapproving
  /// with role.
  /// @param actionInfo Data required to create an action.
  /// @param policyholder Address of the policyholder.
  /// @param role The role of the policyholder being used to cast disapproval.
  function checkIfDisapprovalEnabled(ActionInfo calldata actionInfo, address policyholder, uint8 role) external view;

  /// @notice Get the quantity of a disapproval of a policyholder at a specific timestamp.
  /// @param policyholder Address of the policyholder.
  /// @param role The role to check quantity for.
  /// @param timestamp The timestamp at which to get the disapproval quantity.
  /// @return The quantity of the policyholder's disapproval.
  function getDisapprovalQuantityAt(address policyholder, uint8 role, uint256 timestamp) external view returns (uint96);

  // -------- When Queueing --------

  /// @notice Returns the earliest timestamp, in seconds, at which an action can be executed.
  /// @param actionInfo Data required to create an action.
  /// @return The earliest timestamp at which an action can be executed.
  function minExecutionTime(ActionInfo calldata actionInfo) external view returns (uint64);

  // -------- When Canceling --------

  /// @notice Reverts if the action cannot be canceled.
  /// @param actionInfo Data required to create an action.
  /// @param caller Policyholder initiating the cancelation.
  function validateActionCancelation(ActionInfo calldata actionInfo, address caller) external view;

  // -------- When Determining Action State --------
  // These are used during casting of approvals and disapprovals, when queueing, and when executing.

  /// @notice Get whether an action is currently active.
  /// @param actionInfo Data required to create an action.
  /// @return Boolean value that is `true` if the action is currently active, `false` otherwise.
  function isActionActive(ActionInfo calldata actionInfo) external view returns (bool);

  /// @notice Get whether an action has passed the approval process.
  /// @param actionInfo Data required to create an action.
  /// @return Boolean value that is `true` if the action has passed the approval process.
  function isActionApproved(ActionInfo calldata actionInfo) external view returns (bool);

  /// @notice Get whether an action has been vetoed during the disapproval process.
  /// @param actionInfo Data required to create an action.
  /// @return Boolean value that is `true` if the action has been vetoed during the disapproval process.
  function isActionDisapproved(ActionInfo calldata actionInfo) external view returns (bool);

  /// @notice Returns `true` if the action is expired, `false` otherwise.
  /// @param actionInfo Data required to create an action.
  /// @return Boolean value that is `true` if the action is expired.
  function isActionExpired(ActionInfo calldata actionInfo) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title ILlamaTokenAdapter
/// @author Llama ([email protected])
/// @notice This contract provides an interface for voting token adapters.
interface ILlamaTokenAdapter {
  /// @notice Initializes a new clone of the token adapter.
  /// @dev This function is called by the `deploy` function in the `LlamaTokenVotingFactory` contract. The `initializer`
  /// modifier ensures that this function can be invoked at most once.
  /// @param config The token adapter configuration, encoded as bytes to support differing constructor arguments in
  /// different token adapters.
  /// @return This return statement must be hardcoded to `true` to ensure that initializing an EOA
  /// (like the zero address) will revert.
  function initialize(bytes memory config) external returns (bool);

  /// @notice Returns the token voting module's voting token address.
  /// @return token The voting token.
  function token() external view returns (address token);

  /// @notice Returns the current timepoint according to the token's clock.
  /// @return timepoint the current timepoint
  function clock() external view returns (uint48 timepoint);

  /// @notice Reverts if the token's CLOCK_MODE changes from what's in the adapter or if the clock() function doesn't
  function checkIfInconsistentClock() external view;

  /// @notice Converts a timestamp to timepoint units.
  /// @param timestamp The timestamp to convert.
  /// @return timepoint the current timepoint
  function timestampToTimepoint(uint256 timestamp) external view returns (uint48 timepoint);

  /// @notice Get the voting balance of a token holder at a specified past timepoint.
  /// @param account The token holder's address.
  /// @param timepoint The timepoint at which to get the voting balance.
  /// @return The number of votes the account had at timepoint.
  function getPastVotes(address account, uint48 timepoint) external view returns (uint256);

  /// @notice Get the total supply of a token at a specified past timepoint.
  /// @param timepoint The timepoint at which to get the total supply.
  /// @return The total supply of the token at timepoint.
  function getPastTotalSupply(uint48 timepoint) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @dev Possible states of an action during its lifecycle.
enum ActionState {
  Active, // Action created and approval period begins.
  Canceled, // Action canceled by creator.
  Failed, // Action approval failed.
  Approved, // Action approval succeeded and ready to be queued.
  Queued, // Action queued for queueing duration and disapproval period begins.
  Expired, // block.timestamp is greater than Action's executionTime + expirationDelay.
  Executed // Action has executed successfully.

}

/// @dev Possible states of a user cast vote.
enum VoteType {
  Against,
  For,
  Abstain
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ILlamaAccount} from "src/interfaces/ILlamaAccount.sol";
import {ILlamaCore} from "src/interfaces/ILlamaCore.sol";
import {ILlamaActionGuard} from "src/interfaces/ILlamaActionGuard.sol";
import {ILlamaStrategy} from "src/interfaces/ILlamaStrategy.sol";
import {ILlamaTokenAdapter} from "src/token-voting/interfaces/ILlamaTokenAdapter.sol";
import {RoleDescription} from "src/lib/UDVTs.sol";

/// @dev Data required to create an action.
struct ActionInfo {
  uint256 id; // ID of the action.
  address creator; // Address that created the action.
  uint8 creatorRole; // The role that created the action.
  ILlamaStrategy strategy; // Strategy used to govern the action.
  address target; // Contract being called by an action.
  uint256 value; // Value in wei to be sent when the action is executed.
  bytes data; // Data to be called on the target when the action is executed.
}

/// @dev Data that represents an action.
struct Action {
  // Instead of storing all data required to execute an action in storage, we only save the hash to
  // make action creation cheaper. The hash is computed by taking the keccak256 hash of the concatenation of each
  // field in the `ActionInfo` struct.
  bytes32 infoHash;
  bool executed; // Has action executed.
  bool canceled; // Is action canceled.
  bool isScript; // Is the action's target a script.
  ILlamaActionGuard guard; // The action's guard. This is the address(0) if no guard is set on the action's target and
    // selector pair.
  uint64 creationTime; // The timestamp when action was created (used for policy snapshots).
  uint64 minExecutionTime; // Only set when an action is queued. The timestamp when action execution can begin.
  uint96 totalApprovals; // The total quantity of policyholder approvals.
  uint96 totalDisapprovals; // The total quantity of policyholder disapprovals.
}

/// @dev Data that represents a permission.
struct PermissionData {
  address target; // Contract being called by an action.
  bytes4 selector; // Selector of the function being called by an action.
  ILlamaStrategy strategy; // Strategy used to govern the action.
}

/// @dev Data required to assign/revoke a role to/from a policyholder.
struct RoleHolderData {
  uint8 role; // ID of the role to set (uint8 ensures onchain enumerability when burning policies).
  address policyholder; // Policyholder to assign the role to.
  uint96 quantity; // Quantity of the role to assign to the policyholder, i.e. their (dis)approval quantity.
  uint64 expiration; // When the role expires.
}

/// @dev Data required to assign/revoke a permission to/from a role.
struct RolePermissionData {
  uint8 role; // ID of the role to set (uint8 ensures onchain enumerability when burning policies).
  PermissionData permissionData; // The `(target, selector, strategy)` tuple that will be keccak256 hashed to
    // generate the permission ID to assign or unassign to the role
  bool hasPermission; // Whether to assign the permission or remove the permission.
}

/// @dev Configuration of a new Llama instance.
struct LlamaInstanceConfig {
  string name; // The name of the Llama instance.
  ILlamaStrategy strategyLogic; // The initial strategy implementation (logic) contract.
  ILlamaAccount accountLogic; // The initial account implementation (logic) contract.
  bytes[] initialStrategies; // Array of initial strategy configurations.
  bytes[] initialAccounts; // Array of initial account configurations.
  LlamaPolicyConfig policyConfig; // Configuration of the instance's policy.
}

/// @dev Configuration of a new Llama policy.
struct LlamaPolicyConfig {
  RoleDescription[] roleDescriptions; // The initial role descriptions.
  RoleHolderData[] roleHolders; // The `role`, `policyholder`, `quantity` and `expiration` of the initial role holders.
  RolePermissionData[] rolePermissions; // The `role`, `permissionData`, and  the `hasPermission` boolean.
  string color; // The primary color of the SVG representation of the instance's policy (e.g. #00FF00).
  string logo; // The SVG string representing the logo for the deployed Llama instance's NFT.
}

/// @dev Configuration of a new Llama token voting module.
struct LlamaTokenVotingConfig {
  ILlamaCore llamaCore; // The address of the Llama core.
  ILlamaTokenAdapter tokenAdapterLogic; // The logic contract of the token adapter.
  bytes adapterConfig; // The configuration of the token adapter.
  uint256 nonce; // The nonce to be used in the salt of the deterministic deployment.
  uint256 creationThreshold; // The number of tokens required to create an action.
  CasterConfig casterConfig; // The quorum and period data for the `LlamaTokenGovernor`.
}

/// @dev Quorum and period data for token voting caster contracts.
struct CasterConfig {
  uint16 voteQuorumPct; // The minimum % of total supply that must be casted as `For` votes.
  uint16 vetoQuorumPct; // The minimum % of total supply that must be casted as `For` vetoes.
  uint16 delayPeriodPct; // The % of the total approval or queuing period used as a delay.
  uint16 castingPeriodPct; // The % of the total approval or queuing period used to cast votes or vetoes
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {PermissionData} from "src/lib/Structs.sol";

/// @dev Shared helper methods for Llama's contracts.
library LlamaUtils {
  /// @dev Thrown when a value cannot be safely casted to a smaller type.
  error UnsafeCast(uint256 n);

  /// @dev Reverts if `n` does not fit in a `uint16`.
  function toUint16(uint256 n) internal pure returns (uint16) {
    if (n > type(uint16).max) revert UnsafeCast(n);
    return uint16(n);
  }

  /// @dev Reverts if `n` does not fit in a `uint48`.
  function toUint48(uint256 n) internal pure returns (uint48) {
    if (n > type(uint48).max) revert UnsafeCast(n);
    return uint48(n);
  }

  /// @dev Reverts if `n` does not fit in a `uint64`.
  function toUint64(uint256 n) internal pure returns (uint64) {
    if (n > type(uint64).max) revert UnsafeCast(n);
    return uint64(n);
  }

  /// @dev Reverts if `n` does not fit in a `uint96`.
  function toUint96(uint256 n) internal pure returns (uint96) {
    if (n > type(uint96).max) revert UnsafeCast(n);
    return uint96(n);
  }

  /// @dev Reverts if `n` does not fit in a `uint128`.
  function toUint128(uint256 n) internal pure returns (uint128) {
    if (n > type(uint128).max) revert UnsafeCast(n);
    return uint128(n);
  }

  /// @dev Increments a `uint256` without checking for overflow.
  function uncheckedIncrement(uint256 i) internal pure returns (uint256) {
    unchecked {
      return i + 1;
    }
  }

  /// @dev Hashes a permission to return the corresponding permission ID.
  function computePermissionId(PermissionData memory permission) internal pure returns (bytes32) {
    return keccak256(abi.encode(permission));
  }
}

// SPDX-License-Identifier: MIT
// forgefmt: disable-start
pragma solidity ^0.8.0;

import {LlamaUtils} from "src/lib/LlamaUtils.sol";

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block timestamp.
 *
 * To create a history of checkpoints define a variable type `PeriodPctCheckpoints.History` in your contract, and store a new
 * checkpoint for the current transaction timestamp using the {push} function.
 *
 * @dev This was created by modifying then running the OpenZeppelin `Checkpoints.js` script, which generated a version
 * of this library that uses a 64 bit `timestamp` and 96 bit `quantity` field in the `Checkpoint` struct. The struct
 * was then modified to use uint48 timestamps and add two uint16 period fields. For simplicity, safe cast and math methods were inlined from
 * the OpenZeppelin versions at the same commit. We disable forge-fmt for this file to simplify diffing against the
 * original OpenZeppelin version: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/d00acef4059807535af0bd0dd0ddf619747a044b/contracts/utils/Checkpoints.sol
 */
library PeriodPctCheckpoints {
    struct History {
        Checkpoint[] _checkpoints;
    }

    struct Checkpoint {
        uint48 timestamp;
        uint16 delayPeriodPct;
        uint16 castingPeriodPct;
    }

    /**
     * @dev Returns the periods at a given block timestamp. If a checkpoint is not available at that time, the closest
     * one before it is returned, or zero otherwise. Similar to {upperLookup} but optimized for the case when the
     * searched checkpoint is probably "recent", defined as being among the last sqrt(N) checkpoints where N is the
     * timestamp of checkpoints.
     */
    function getAtProbablyRecentTimestamp(History storage self, uint256 timestamp) internal view returns (uint16, uint16) {
        require(timestamp < block.timestamp, "PeriodPctCheckpoints: timestamp is not in the past");
        uint48 _timestamp = LlamaUtils.toUint48(timestamp);

        uint256 len = self._checkpoints.length;

        uint256 low = 0;
        uint256 high = len;

        if (len > 5) {
            uint256 mid = len - sqrt(len);
            if (_timestamp < _unsafeAccess(self._checkpoints, mid).timestamp) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        uint256 pos = _upperBinaryLookup(self._checkpoints, _timestamp, low, high);

        if (pos == 0) return (0, 0);
        Checkpoint memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
        return (ckpt.delayPeriodPct, ckpt.castingPeriodPct);
    }

    /**
     * @dev Pushes a `delayPeriodPct` and `castingPeriodPct` onto a History so that it is stored as the checkpoint for the current
     * `timestamp`.
     *
     * For simplicity, this method does not return anything, since the return values are not needed by Llama.
     */
    function push(History storage self, uint16 delayPeriodPct, uint16 castingPeriodPct) internal {
        _insert(self._checkpoints, LlamaUtils.toUint48(block.timestamp), LlamaUtils.toUint16(delayPeriodPct), LlamaUtils.toUint16(castingPeriodPct));
    }

    /**
     * @dev Returns the periods in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint16, uint16) {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) return (0, 0);
        Checkpoint memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
        return (ckpt.delayPeriodPct, ckpt.castingPeriodPct);
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the timestamp and
     * periods in the most recent checkpoint.
     */
    function latestCheckpoint(History storage self)
        internal
        view
        returns (
            bool exists,
            uint48 timestamp,
            uint16 delayPeriodPct,
            uint16 castingPeriodPct
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0, 0);
        } else {
            Checkpoint memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt.timestamp, ckpt.delayPeriodPct, ckpt.castingPeriodPct);
        }
    }

    /**
     * @dev Returns the number of checkpoints.
     */
    function length(History storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`timestamp`, `delayPeriodPct`, and `castingPeriodPct`) group into an ordered list of checkpoints, either by inserting a new
     * checkpoint, or by updating the last one.
     */
    function _insert(
        Checkpoint[] storage self,
        uint48 timestamp,
        uint16 delayPeriodPct,
        uint16 castingPeriodPct
    ) private {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints timestamps must be increasing.
            require(last.timestamp <= timestamp, "Period Pct Checkpoint: invalid timestamp");

            // Update or push new checkpoint
            if (last.timestamp == timestamp) {
                Checkpoint storage ckpt = _unsafeAccess(self, pos - 1);
                ckpt.delayPeriodPct = delayPeriodPct;
                ckpt.castingPeriodPct = castingPeriodPct;
            } else {
                self.push(Checkpoint({timestamp: timestamp, delayPeriodPct: delayPeriodPct, castingPeriodPct: castingPeriodPct}));
            }
        } else {
            self.push(Checkpoint({timestamp: timestamp, delayPeriodPct: delayPeriodPct, castingPeriodPct: castingPeriodPct}));
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose timestamp is greater than the search timestamp, or `high`
     * if there is none. `low` and `high` define a section where to do the search, with inclusive `low` and exclusive
     * `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint[] storage self,
        uint48 timestamp,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = average(low, high);
            if (_unsafeAccess(self, mid).timestamp > timestamp) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose timestamp is greater or equal than the search timestamp, or
     * `high` if there is none. `low` and `high` define a section where to do the search, with inclusive `low` and
     * exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint[] storage self,
        uint48 timestamp,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = average(low, high);
            if (_unsafeAccess(self, mid).timestamp < timestamp) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    function _unsafeAccess(Checkpoint[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) private pure returns (uint256) {
        return (a & b) + (a ^ b) / 2; // (a + b) / 2 can overflow.
    }

    /**
     * @dev This was copied from Solmate v7 https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/utils/FixedPointMathLib.sol
     * @notice The math utils in solmate v7 were reviewed/audited by spearbit as part of the art gobblers audit, and are more efficient than the v6 versions.
     */
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }
}

// SPDX-License-Identifier: MIT
// forgefmt: disable-start
pragma solidity ^0.8.0;

import {LlamaUtils} from "src/lib/LlamaUtils.sol";

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block timestamp.
 *
 * To create a history of checkpoints define a variable type `QuorumCheckpoints.History` in your contract, and store a new
 * checkpoint for the current transaction timestamp using the {push} function.
 *
 * @dev This was created by modifying then running the OpenZeppelin `Checkpoints.js` script, which generated a version
 * of this library that uses a 64 bit `timestamp` and 96 bit `quantity` field in the `Checkpoint` struct. The struct
 * was then modified to work with the below `Checkpoint` struct. For simplicity, safe cast and math methods were inlined from
 * the OpenZeppelin versions at the same commit. We disable forge-fmt for this file to simplify diffing against the
 * original OpenZeppelin version: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/d00acef4059807535af0bd0dd0ddf619747a044b/contracts/utils/Checkpoints.sol
 */
library QuorumCheckpoints {
    struct History {
        Checkpoint[] _checkpoints;
    }

    struct Checkpoint {
        uint48 timestamp;
        uint16 voteQuorumPct;
        uint16 vetoQuorumPct;
    }

    /**
     * @dev Returns the quorums at a given block timestamp. If a checkpoint is not available at that time, the closest
     * one before it is returned, or zero otherwise. Similar to {upperLookup} but optimized for the case when the
     * searched checkpoint is probably "recent", defined as being among the last sqrt(N) checkpoints where N is the
     * timestamp of checkpoints.
     */
    function getAtProbablyRecentTimestamp(History storage self, uint256 timestamp) internal view returns (uint16, uint16) {
        require(timestamp < block.timestamp, "QuorumCheckpoints: timestamp is not in the past");
        uint48 _timestamp = LlamaUtils.toUint48(timestamp);

        uint256 len = self._checkpoints.length;

        uint256 low = 0;
        uint256 high = len;

        if (len > 5) {
            uint256 mid = len - sqrt(len);
            if (_timestamp < _unsafeAccess(self._checkpoints, mid).timestamp) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        uint256 pos = _upperBinaryLookup(self._checkpoints, _timestamp, low, high);

        if (pos == 0) return (0, 0);
        Checkpoint memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
        return (ckpt.voteQuorumPct, ckpt.vetoQuorumPct);
    }

    /**
     * @dev Pushes a `voteQuorumPct` and `vetoQuorumPct` onto a History so that it is stored as the checkpoint for the current
     * `timestamp`.
     *
     * For simplicity, this method does not return anything, since the return values are not needed by Llama.
     */
    function push(History storage self, uint256 voteQuorumPct, uint256 vetoQuorumPct) internal {
        _insert(self._checkpoints, LlamaUtils.toUint48(block.timestamp), LlamaUtils.toUint16(voteQuorumPct), LlamaUtils.toUint16(vetoQuorumPct));
    }

    /**
     * @dev Returns the quorums in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint16, uint16) {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) return (0, 0);
        Checkpoint memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
        return (ckpt.voteQuorumPct, ckpt.vetoQuorumPct);
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the timestamp and
     * quorums in the most recent checkpoint.
     */
    function latestCheckpoint(History storage self)
        internal
        view
        returns (
            bool exists,
            uint48 timestamp,
            uint16 voteQuorumPct,
            uint16 vetoQuorumPct
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0, 0);
        } else {
            Checkpoint memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt.timestamp, ckpt.voteQuorumPct, ckpt.vetoQuorumPct);
        }
    }

    /**
     * @dev Returns the number of checkpoints.
     */
    function length(History storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`timestamp`, `voteQuorumPct`, `vetoQuorumPct`) pair into an ordered list of checkpoints, either by inserting a new
     * checkpoint, or by updating the last one.
     */
    function _insert(
        Checkpoint[] storage self,
        uint48 timestamp,
        uint16 voteQuorumPct,
        uint16 vetoQuorumPct
    ) private {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints timestamps must be increasing.
            require(last.timestamp <= timestamp, "Quorum Checkpoint: invalid timestamp");

            // Update or push new checkpoint
            if (last.timestamp == timestamp) {
                Checkpoint storage ckpt = _unsafeAccess(self, pos - 1);
                ckpt.voteQuorumPct = voteQuorumPct;
                ckpt.vetoQuorumPct = vetoQuorumPct;
            } else {
                self.push(Checkpoint({timestamp: timestamp, voteQuorumPct: voteQuorumPct, vetoQuorumPct: vetoQuorumPct}));
            }
        } else {
            self.push(Checkpoint({timestamp: timestamp, voteQuorumPct: voteQuorumPct, vetoQuorumPct: vetoQuorumPct}));
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose timestamp is greater than the search timestamp, or `high`
     * if there is none. `low` and `high` define a section where to do the search, with inclusive `low` and exclusive
     * `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint[] storage self,
        uint48 timestamp,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = average(low, high);
            if (_unsafeAccess(self, mid).timestamp > timestamp) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose timestamp is greater or equal than the search timestamp, or
     * `high` if there is none. `low` and `high` define a section where to do the search, with inclusive `low` and
     * exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint[] storage self,
        uint48 timestamp,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = average(low, high);
            if (_unsafeAccess(self, mid).timestamp < timestamp) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    function _unsafeAccess(Checkpoint[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) private pure returns (uint256) {
        return (a & b) + (a ^ b) / 2; // (a + b) / 2 can overflow.
    }

    /**
     * @dev This was copied from Solmate v7 https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/utils/FixedPointMathLib.sol
     * @notice The math utils in solmate v7 were reviewed/audited by spearbit as part of the art gobblers audit, and are more efficient than the v6 versions.
     */
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }
}

// SPDX-License-Identifier: MIT
// TODO This interface was generated from `cast interface`, so some types are not as strong as they
// could be.
pragma solidity ^0.8.23;

import {RoleDescription} from "../lib/UDVTs.sol";

/// @title LlamaPolicy Interface
/// @author Llama ([email protected])
/// @notice This is the interface for LlamaPolicy.
interface ILlamaPolicy {
  event Approval(address indexed owner, address indexed spender, uint256 indexed id);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  event ExpiredRoleRevoked(address indexed caller, address indexed policyholder, uint8 indexed role);
  event Initialized(uint8 version);
  event PolicyMetadataSet(address policyMetadata, address indexed policyMetadataLogic, bytes initializationData);
  event RoleAssigned(address indexed policyholder, uint8 indexed role, uint64 expiration, uint96 quantity);
  event RoleInitialized(uint8 indexed role, bytes32 description);
  event RolePermissionAssigned(
    uint8 indexed role, bytes32 indexed permissionId, PermissionData permissionData, bool hasPermission
  );
  event Transfer(address indexed from, address indexed to, uint256 indexed id);

  struct LlamaPolicyConfig {
    RoleDescription[] roleDescriptions;
    RoleHolderData[] roleHolders;
    RolePermissionData[] rolePermissions;
    string color;
    string logo;
  }

  struct PermissionData {
    address target;
    bytes4 selector;
    address strategy;
  }

  struct Checkpoint {
    uint64 timestamp;
    uint64 expiration;
    uint96 quantity;
  }

  struct History {
    Checkpoint[] _checkpoints;
  }

  struct RoleHolderData {
    uint8 role;
    address policyholder;
    uint96 quantity;
    uint64 expiration;
  }

  struct RolePermissionData {
    uint8 role;
    PermissionData permissionData;
    bool hasPermission;
  }

  function approve(address, uint256) external pure;
  function balanceOf(address owner) external view returns (uint256);
  function canCreateAction(uint8 role, bytes32 permissionId) external view returns (bool hasPermission);
  function contractURI() external view returns (string memory);
  function getApproved(uint256) external view returns (address);
  function getPastQuantity(address policyholder, uint8 role, uint256 timestamp) external view returns (uint96);
  function getPastRoleSupplyAsNumberOfHolders(uint8 role, uint256 timestamp)
    external
    view
    returns (uint96 numberOfHolders);
  function getPastRoleSupplyAsQuantitySum(uint8 role, uint256 timestamp) external view returns (uint96 totalQuantity);
  function getQuantity(address policyholder, uint8 role) external view returns (uint96);
  function getRoleSupplyAsNumberOfHolders(uint8 role) external view returns (uint96 numberOfHolders);
  function getRoleSupplyAsQuantitySum(uint8 role) external view returns (uint96 totalQuantity);
  function hasPermissionId(address policyholder, uint8 role, bytes32 permissionId) external view returns (bool);
  function hasRole(address policyholder, uint8 role) external view returns (bool);
  function hasRole(address policyholder, uint8 role, uint256 timestamp) external view returns (bool);
  function initialize(
    string memory _name,
    LlamaPolicyConfig memory config,
    address policyMetadataLogic,
    address executor,
    PermissionData memory bootstrapPermissionData
  ) external;
  function initializeRole(RoleDescription description) external;
  function isApprovedForAll(address, address) external view returns (bool);
  function isRoleExpired(address policyholder, uint8 role) external view returns (bool);
  function llamaExecutor() external view returns (address);
  function llamaPolicyMetadata() external view returns (address);
  function name() external view returns (string memory);
  function numRoles() external view returns (uint8);
  function ownerOf(uint256 id) external view returns (address owner);
  function revokeExpiredRole(uint8 role, address policyholder) external;
  function revokePolicy(address policyholder) external;
  function roleBalanceCheckpoints(address policyholder, uint8 role, uint256 start, uint256 end)
    external
    view
    returns (History memory);
  function roleBalanceCheckpoints(address policyholder, uint8 role) external view returns (History memory);
  function roleBalanceCheckpointsLength(address policyholder, uint8 role) external view returns (uint256);
  function roleExpiration(address policyholder, uint8 role) external view returns (uint64);
  function roleSupplyCheckpoints(uint8 role, uint256 start, uint256 end) external view returns (History memory);
  function roleSupplyCheckpoints(uint8 role) external view returns (History memory);
  function roleSupplyCheckpointsLength(uint8 role) external view returns (uint256);
  function safeTransferFrom(address, address, uint256) external pure;
  function safeTransferFrom(address, address, uint256, bytes memory) external pure;
  function setAndInitializePolicyMetadata(address llamaPolicyMetadataLogic, bytes memory config) external;
  function setApprovalForAll(address, bool) external pure;
  function setRoleHolder(uint8 role, address policyholder, uint96 quantity, uint64 expiration) external;
  function setRolePermission(uint8 role, PermissionData memory permissionData, bool hasPermission) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function transferFrom(address, address, uint256) external pure;
  function updateRoleDescription(uint8 role, RoleDescription description) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title Llama Account Logic Interface
/// @author Llama ([email protected])
/// @notice This is the interface for Llama accounts which can be used to hold assets for a Llama instance.
interface ILlamaAccount {
  // -------- For Inspection --------

  /// @notice Returns the address of the Llama instance's executor.
  function llamaExecutor() external view returns (address);

  // -------- At Account Creation --------

  /// @notice Initializes a new clone of the account.
  /// @dev This function is called by the `_deployAccounts` function in the `LlamaCore` contract. The `initializer`
  /// modifier ensures that this function can be invoked at most once.
  /// @param config The account configuration, encoded as bytes to support differing constructor arguments in
  /// different account logic contracts.
  /// @return This return statement must be hardcoded to `true` to ensure that initializing an EOA
  /// (like the zero address) will revert.
  function initialize(bytes memory config) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ActionInfo} from "src/lib/Structs.sol";

/// @title Llama Action Guard Interface
/// @author Llama ([email protected])
/// @notice Executes checks on action creation and execution to verify that the action is allowed.
/// @dev Methods are not `view` because (1) an action guard may write to it's own storage, and (2)
/// Having `view` methods that can revert isn't great UX. Allowing guards to write to their own
/// storage is useful to persist state between calls to the various guard methods. For example, a
/// guard may:
///   - Store the USD price of a token during action creation in `validateActionCreation`.
///   - Verify the price has not changed by more than a given amount during `validatePreActionExecution`
///     and save off the current USD value of an account.
///   - Verify the USD value of an account has not decreased by more than a certain amount during
///     execution, i.e. between `validatePreActionExecution` and `validatePostActionExecution`.
interface ILlamaActionGuard {
  /// @notice Reverts if action creation is not allowed.
  /// @param actionInfo Data required to create an action.
  function validateActionCreation(ActionInfo calldata actionInfo) external;

  /// @notice Called immediately before action execution, and reverts if the action is not allowed
  /// to be executed.
  /// @param actionInfo Data required to create an action.
  function validatePreActionExecution(ActionInfo calldata actionInfo) external;

  /// @notice Called immediately after action execution, and reverts if the just-executed
  /// action should not have been allowed to execute.
  /// @param actionInfo Data required to create an action.
  function validatePostActionExecution(ActionInfo calldata actionInfo) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// @dev We use this UDVT for stronger typing of the Role Description.
type RoleDescription is bytes32;