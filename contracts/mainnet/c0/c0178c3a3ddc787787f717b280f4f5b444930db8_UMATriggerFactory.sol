// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {SafeTransferLib} from "./lib/SafeTransferLib.sol";
import {UMATrigger} from "./UMATrigger.sol";
import {TriggerMetadata} from "./structs/Triggers.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IUMATriggerFactory} from "./interfaces/IUMATriggerFactory.sol";
import {OptimisticOracleV2Interface} from "./interfaces/OptimisticOracleV2Interface.sol";

/**
 * @notice This is a utility contract to make it easy to deploy UMATriggers for
 * the Cozy Safety Module protocol.
 * @dev Be sure to approve the trigger to spend the rewardAmount before calling
 * `deployTrigger`, otherwise the latter will revert. Funds need to be available
 * to the created trigger within its constructor so that it can submit its query
 * to the UMA oracle.
 */
contract UMATriggerFactory {
  using SafeTransferLib for IERC20;

  /// @notice The UMA Optimistic Oracle.
  OptimisticOracleV2Interface public immutable oracle;

  /// @notice Maps the triggerConfigId to whether a trigger has been deployed with that config.
  mapping(bytes32 => bool) public exists;

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
  /// @param description A human-readable description of the trigger.
  /// @param logoURI The URI of a logo image to represent the trigger.
  /// For other attributes, see the docs for the params of `deployTrigger` in
  /// this contract.
  /// @param extraData Extra metadata for the trigger.
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
    string description,
    string logoURI,
    string extraData
  );

  /// @dev Thrown when the trigger address computed by the factory does not match deployed address.
  error TriggerAddressMismatch();

  /// @dev Thrown when the trigger has already been deployed with the given config.
  error AlreadyDeployed();

  constructor(OptimisticOracleV2Interface _oracle) {
    oracle = _oracle;
  }

  struct DeployTriggerVars {
    bytes32 configId;
    bytes32 salt;
    address triggerAddress;
    UMATrigger trigger;
  }

  /// @notice Call this function to deploy a UMATrigger.
  /// @param _query The query that the trigger will send to the UMA Optimistic
  /// Oracle for evaluation.
  /// @param _rewardToken The token used to pay the reward to users that propose
  /// answers to the query. The reward token must be approved by UMA governance.
  /// Approved tokens can be found with the UMA AddressWhitelist contract on each
  /// chain supported by UMA.
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
  ) external returns (UMATrigger) {
    // We need to do this because of stack-too-deep errors; there are too many
    // inputs/internal-vars to this function otherwise.
    DeployTriggerVars memory _vars;

    _vars.configId =
      triggerConfigId(_query, _rewardToken, _rewardAmount, _refundRecipient, _bondAmount, _proposalDisputeWindow);
    if (exists[_vars.configId]) revert AlreadyDeployed();

    exists[_vars.configId] = true;
    _vars.salt = _getSalt(_vars.configId, _rewardAmount);

    _vars.triggerAddress =
      computeTriggerAddress(_query, _rewardToken, _rewardAmount, _refundRecipient, _bondAmount, _proposalDisputeWindow);

    _rewardToken.safeTransferFrom(msg.sender, _vars.triggerAddress, _rewardAmount);

    _vars.trigger = new UMATrigger{salt: _vars.salt}(
      oracle, _query, _rewardToken, _refundRecipient, _bondAmount, _proposalDisputeWindow
    );

    if (address(_vars.trigger) != _vars.triggerAddress) revert TriggerAddressMismatch();

    emit TriggerDeployed(
      address(_vars.trigger),
      _vars.configId,
      address(oracle),
      _query,
      address(_rewardToken),
      _rewardAmount,
      _refundRecipient,
      _bondAmount,
      _proposalDisputeWindow,
      _metadata.name,
      _metadata.description,
      _metadata.logoURI,
      _metadata.extraData
    );

    return _vars.trigger;
  }

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
  ) public view returns (address _address) {
    bytes memory _triggerConstructorArgs =
      abi.encode(oracle, _query, _rewardToken, _refundRecipient, _bondAmount, _proposalDisputeWindow);

    // https://eips.ethereum.org/EIPS/eip-1014
    bytes32 _bytecodeHash = keccak256(bytes.concat(type(UMATrigger).creationCode, _triggerConstructorArgs));

    bytes32 _salt = _getSalt(
      triggerConfigId(_query, _rewardToken, _rewardAmount, _refundRecipient, _bondAmount, _proposalDisputeWindow),
      _rewardAmount
    );
    bytes32 _data = keccak256(bytes.concat(bytes1(0xff), bytes20(address(this)), _salt, _bytecodeHash));
    _address = address(uint160(uint256(_data)));
  }

  /// @notice Call this function to find triggers with the specified
  /// configurations that can be used for safety modules. See `deployTrigger` for more information on parameters
  /// and their meaning.
  function findAvailableTrigger(
    string memory _query,
    IERC20 _rewardToken,
    uint256 _rewardAmount,
    address _refundRecipient,
    uint256 _bondAmount,
    uint256 _proposalDisputeWindow
  ) public view returns (address) {
    bytes32 _configId =
      triggerConfigId(_query, _rewardToken, _rewardAmount, _refundRecipient, _bondAmount, _proposalDisputeWindow);
    return exists[_configId]
      ? computeTriggerAddress(_query, _rewardToken, _rewardAmount, _refundRecipient, _bondAmount, _proposalDisputeWindow)
      : address(0); // If none is found, return zero address.
  }

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
  ) public view returns (bytes32) {
    bytes memory _triggerConfigData =
      abi.encode(oracle, _query, _rewardToken, _rewardAmount, _refundRecipient, _bondAmount, _proposalDisputeWindow);
    return keccak256(_triggerConfigData);
  }

  function _getSalt(bytes32 _triggerConfigId, uint256 _rewardAmount) private pure returns (bytes32) {
    // We use the reward amount in the salt so that triggers that are the same
    // except for their reward amount will still be deployed to different
    // addresses and can be differentiated. A trigger deployment with the same
    // _rewardAmount and _triggerCount should be the same across chains.
    return keccak256(bytes.concat(_triggerConfigId, bytes32(_rewardAmount)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// A named import is used to avoid identifier naming conflicts between IERC20 imports. solc throws a DeclarationError
// if an interface with the same name is imported twice in a file using different paths, even if they have the
// same implementation. For example, if a file in the cozy-v2-interfaces submodule that is imported in this project
// imports an IERC20 interface with "import src/interfaces/IERC20.sol;", but in this project we import the same
// interface with "import cozy-v2-interfaces/interfaces/IERC20.sol;", a DeclarationError will be thrown.
import { IERC20 } from "../interfaces/IERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/v7/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
/// @dev Note that this version of solmate's SafeTransferLib uses our own IERC20 interface instead of solmate's ERC20. Cozy's ERC20 was modified
/// from solmate to use an initializer to support usage as a minimal proxy.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append the "from" argument.
            mstore(36, to) // Append the "to" argument.
            mstore(68, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {BaseTrigger} from "./abstract/BaseTrigger.sol";
import {OptimisticOracleV2Interface} from "./interfaces/OptimisticOracleV2Interface.sol";
import {SafeTransferLib} from "./lib/SafeTransferLib.sol";
import {TriggerState} from "./structs/StateEnums.sol";
import {IERC20} from "./interfaces/IERC20.sol";

/**
 * @notice This is an automated trigger contract which will move into a
 * TRIGGERED state in the event that the UMA Optimistic Oracle answers "YES" to
 * a provided query, e.g. "Was protocol ABCD hacked on or after block 42". More
 * information about UMA oracles and the lifecycle of queries can be found here:
 * https://docs.umaproject.org/.
 * @dev The high-level lifecycle of a UMA request is as follows:
 * - someone asks a question of the oracle and provides a reward for someone
 * to answer it
 * - users of the UMA prediction market view the question (usually here:
 * https://oracle.umaproject.org/)
 * - someone proposes an answer to the question in hopes of claiming the
 * reward`
 * - users of UMA see the proposed answer and have a chance to dispute it
 * - there is a finite period of time within which to dispute the answer
 * - if the answer is not disputed during this period, the oracle finalizes
 * the answer and the proposer gets the reward
 * - if the answer is disputed, the question is sent to the DVM (Data
 * Verification Mechanism) in which UMA token holders vote on who is right
 * There are four essential players in the above process:
 * 1. Requester: the account that is asking the oracle a question.
 * 2. Proposer: the account that submits an answer to the question.
 * 3. Disputer: the account (if any) that disagrees with the proposed answer.
 * 4. The DVM: a DAO that is the final arbiter of disputed proposals.
 * This trigger plays the first role in this lifecycle. It submits a request for
 * an answer to a yes-or-no question (the query) to the Optimistic Oracle.
 * Questions need to be phrased in such a way that if a "Yes" answer is given
 * to them, then this contract will go into a TRIGGERED state. For
 * example, if you wanted to create a safety module for protecting Compound
 * users, you might deploy a UMATrigger with a query like "Was Compound hacked
 * after block X?" If the oracle responds with a "Yes" answer, this contract
 * would move into the TRIGGERED state and safety modules  with this trigger
 * registered could transition to the TRIGGERED state and potentially payout
 * Compound users.
 * But what if Compound hasn't been hacked? Can't someone just respond "No" to
 * the trigger's query? Wouldn't that be the right answer and wouldn't it mean
 * the end of the query lifecycle? Yes. For this exact reason, we have enabled
 * callbacks (see the `priceProposed` function) which will revert in the event
 * that someone attempts to propose a negative answer to the question. We want
 * the queries to remain open indefinitely until there is a positive answer,
 * i.e. "Yes, there was a hack". **This should be communicated in the query text.**
 * In the event that a YES answer to a query is disputed and the DVM sides
 * with the disputer (i.e. a NO answer), we immediately re-submit the query to
 * the DVM through another callback (see `priceSettled`). In this way, our query
 * will always be open with the oracle. If/when the event that we are concerned
 * with happens the trigger will immediately be notified.
 */
contract UMATrigger is BaseTrigger {
  using SafeTransferLib for IERC20;

  /// @notice The type of query that will be submitted to the oracle.
  bytes32 public constant queryIdentifier = bytes32("YES_OR_NO_QUERY");

  /// @notice The UMA Optimistic Oracle.
  OptimisticOracleV2Interface public immutable oracle;

  /// @notice The identifier used to lookup the UMA Optimistic Oracle with the finder.
  bytes32 internal constant ORACLE_LOOKUP_IDENTIFIER = bytes32("OptimisticOracleV2");

  /// @notice The query that is sent to the UMA Optimistic Oracle for evaluation.
  /// It should be phrased so that only a positive answer is appropriate, e.g.
  /// "Was protocol ABCD hacked on or after block number 42". Negative answers
  /// are disallowed so that queries can remain open in UMA until the events we
  /// care about happen, if ever.
  string public query;

  /// @notice The token used to pay the reward to users that propose answers to the query.
  IERC20 public immutable rewardToken;

  /// @notice The amount of `rewardToken` that must be staked by a user wanting
  /// to propose or dispute an answer to the query. See UMA's price dispute
  /// workflow for more information. It's recommended that the bond amount be a
  /// significant value to deter addresses from proposing malicious, false, or
  /// otherwise self-interested answers to the query.
  uint256 public immutable bondAmount;

  /// @notice The window of time in seconds within which a proposed answer may
  /// be disputed. See UMA's "customLiveness" setting for more information. It's
  /// recommended that the dispute window be fairly long (12-24 hours), given
  /// the difficulty of assessing expected queries (e.g. "Was protocol ABCD
  /// hacked") and the amount of funds potentially at stake. Additionally,
  /// proposalDisputeWindow < min(unstakeDelay, withdrawalDelay) is recommended
  /// to avoid safety modules stakers / depositors front-running safety modules
  /// becoming triggered.
  uint256 public immutable proposalDisputeWindow;

  /// @notice The most recent timestamp that the query was submitted to the UMA oracle.
  uint256 public requestTimestamp;

  /// @notice Default address that will receive any leftover rewards.
  address public refundRecipient;

  /// @dev Thrown when a negative answer is proposed to the submitted query.
  error InvalidProposal();

  /// @dev Thrown when the trigger attempts to settle an unsettleable UMA request.
  error Unsettleable();

  /// @dev Emitted when an answer proposed to the submitted query is disputed
  /// and a request is sent to the DVM for dispute resolution by UMA tokenholders
  /// via voting.
  event ProposalDisputed();

  /// @dev Emitted when the query is resubmitted after a dispute resolution results
  /// in the proposed answer being rejected (so, the market returns to the active
  /// state).
  event QueryResubmitted();

  /// @dev Thrown when the caller is not authorized to perform the action.
  error Unauthorized();

  /// @dev UMA expects answers to be denominated as wads. So, e.g., a p3 answer
  /// of 0.5 would be represented as 0.5e18.
  int256 internal constant AFFIRMATIVE_ANSWER = 1e18;

  /// @param _oracle The UMA Optimistic Oracle.
  /// @param _query The query that the trigger will send to the UMA Optimistic
  /// Oracle for evaluation.
  /// @param _rewardToken The token used to pay the reward to users that propose
  /// answers to the query. The reward token must be approved by UMA governance.
  /// Approved tokens can be found with the UMA AddressWhitelist contract on each
  /// chain supported by UMA.
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
  constructor(
    OptimisticOracleV2Interface _oracle,
    string memory _query,
    IERC20 _rewardToken,
    address _refundRecipient,
    uint256 _bondAmount,
    uint256 _proposalDisputeWindow
  ) BaseTrigger() {
    oracle = _oracle;
    query = _query;
    rewardToken = _rewardToken;
    refundRecipient = _refundRecipient;
    bondAmount = _bondAmount;
    proposalDisputeWindow = _proposalDisputeWindow;

    _submitRequestToOracle();
  }

  /// @notice Submits the trigger query to the UMA Optimistic Oracle for evaluation.
  function _submitRequestToOracle() internal {
    uint256 _rewardAmount = rewardToken.balanceOf(address(this));
    rewardToken.approve(address(oracle), _rewardAmount);
    requestTimestamp = block.timestamp;

    // The UMA function for submitting a query to the oracle is `requestPrice`
    // even though not all queries are price queries. Another name for this
    // function might have been `requestAnswer`.
    oracle.requestPrice(queryIdentifier, requestTimestamp, bytes(query), rewardToken, _rewardAmount);

    // Set this as an event-based query so that no one can propose the "too
    // soon" answer and so that we automatically get the reward back if there
    // is a dispute. This allows us to re-query the oracle for ~free.
    oracle.setEventBased(queryIdentifier, requestTimestamp, bytes(query));

    // Set the amount of rewardTokens that have to be staked in order to answer
    // the query or dispute an answer to the query.
    oracle.setBond(queryIdentifier, requestTimestamp, bytes(query), bondAmount);

    // Set the proposal dispute window -- i.e. how long people have to challenge
    // and answer to the query.
    oracle.setCustomLiveness(queryIdentifier, requestTimestamp, bytes(query), proposalDisputeWindow);

    // We want to be notified by the UMA oracle when answers and proposed and
    // when answers are confirmed/settled.
    oracle.setCallbacks(
      queryIdentifier,
      requestTimestamp,
      bytes(query),
      true, // Enable the answer-proposed callback.
      true, // Enable the answer-disputed callback.
      true // Enable the answer-settled callback.
    );
  }

  /// @notice UMA callback for proposals. This function is called by the UMA
  /// oracle when a new answer is proposed for the query. Its only purpose is to
  /// prevent people from proposing negative answers and prematurely closing our
  /// queries. For example, if our query were something like "Has Compound been
  /// hacked since block X?" the correct answer could easily be "No" right now.
  /// But we we don't care if the answer is "No". The trigger only cares when
  /// hacks *actually happen*. So we revert when people try to submit negative
  /// answers, as negative answers that are undisputed would resolve our query
  /// and we'd have to pay a new reward to resubmit.
  /// @param _identifier price identifier being requested.
  /// @param _timestamp timestamp of the original query request.
  /// @param _ancillaryData ancillary data of the original query request.
  function priceProposed(bytes32 _identifier, uint256 _timestamp, bytes memory _ancillaryData) external {
    // Besides confirming that the caller is the UMA oracle, we also confirm
    // that the args passed in match the args used to submit our latest query to
    // UMA. This is done as an extra safeguard that we are responding to an
    // event related to the specific query we care about. It is possible, for
    // example, for multiple queries to be submitted to the oracle that differ
    // only with respect to timestamp. So we want to make sure we know which
    // query the answer is for.
    if (
      msg.sender != address(oracle) || _timestamp != requestTimestamp
        || keccak256(_ancillaryData) != keccak256(bytes(query)) || _identifier != queryIdentifier
    ) revert Unauthorized();

    OptimisticOracleV2Interface.Request memory _umaRequest;
    _umaRequest = oracle.getRequest(address(this), _identifier, _timestamp, _ancillaryData);

    // Revert if the answer was anything other than "YES". We don't want to be told
    // that a hack/exploit has *not* happened yet, or it cannot be determined, etc.
    if (_umaRequest.proposedPrice != AFFIRMATIVE_ANSWER) revert InvalidProposal();

    // Freeze the trigger so it cannot be added to a safety module, since there's now a real
    // possibility that we are going to trigger.
    _updateTriggerState(TriggerState.FROZEN);
  }

  /// @notice UMA callback for settlement. This code is run when the protocol
  /// has confirmed an answer to the query.
  /// @dev This callback is kept intentionally lean, as we don't want to risk
  /// reverting and blocking settlement.
  /// @param _identifier price identifier being requested.
  /// @param _timestamp timestamp of the original query request.
  /// @param _ancillaryData ancillary data of the original query request.
  /// @param _answer the oracle's answer to the query.
  function priceSettled(bytes32 _identifier, uint256 _timestamp, bytes memory _ancillaryData, int256 _answer) external {
    // See `priceProposed` for why we authorize callers in this way.
    if (
      msg.sender != address(oracle) || _timestamp != requestTimestamp
        || keccak256(_ancillaryData) != keccak256(bytes(query)) || _identifier != queryIdentifier
    ) revert Unauthorized();

    if (_answer == AFFIRMATIVE_ANSWER) {
      uint256 _rewardBalance = rewardToken.balanceOf(address(this));
      if (_rewardBalance > 0) rewardToken.safeTransfer(refundRecipient, _rewardBalance);
      _updateTriggerState(TriggerState.TRIGGERED);
    } else {
      // If the answer was not affirmative, i.e. "Yes, the protocol was hacked",
      // the trigger should return to the ACTIVE state. And we need to resubmit
      // our query so that we are informed if the event we care about happens in
      // the future.
      _updateTriggerState(TriggerState.ACTIVE);
      _submitRequestToOracle();
      emit QueryResubmitted();
    }
  }

  /// @notice UMA callback for disputes. This code is run when the answer
  /// proposed to the query is disputed.
  /// @param _identifier price identifier being requested.
  /// @param _timestamp timestamp of the original query request.
  /// @param _ancillaryData ancillary data of the original query request.
  function priceDisputed(bytes32 _identifier, uint256 _timestamp, bytes memory _ancillaryData, uint256 /* _refund */ )
    external
  {
    // See `priceProposed` for why we authorize callers in this way.
    if (
      msg.sender != address(oracle) || _timestamp != requestTimestamp
        || keccak256(_ancillaryData) != keccak256(bytes(query)) || _identifier != queryIdentifier
    ) revert Unauthorized();

    emit ProposalDisputed();
  }

  /// @notice This function attempts to confirm and finalize (i.e. "settle") the
  /// answer to the query with the UMA oracle. It reverts with Unsettleable if
  /// it cannot settle the query, but does NOT revert if the oracle has already
  /// settled the query on its own. If the oracle's answer is an
  /// AFFIRMATIVE_ANSWER, this function will toggle the trigger.
  function runProgrammaticCheck() external returns (TriggerState) {
    // Rather than revert when triggered, we simply return the state and exit.
    // Both behaviors are acceptable, but returning is friendlier to the caller
    // as they don't need to handle a revert and can simply parse the
    // transaction's logs to know if the call resulted in a state change.
    if (state == TriggerState.TRIGGERED) return state;

    bool _oracleHasPrice = oracle.hasPrice(address(this), queryIdentifier, requestTimestamp, bytes(query));

    if (!_oracleHasPrice) revert Unsettleable();

    OptimisticOracleV2Interface.Request memory _umaRequest =
      oracle.getRequest(address(this), queryIdentifier, requestTimestamp, bytes(query));
    if (!_umaRequest.settled) {
      // Give the reward balance to the caller to make up for gas costs and
      // incentivize keeping safety modules in line with trigger state.
      refundRecipient = msg.sender;

      // `settle` will cause the oracle to call the trigger's `priceSettled` function.
      oracle.settle(address(this), queryIdentifier, requestTimestamp, bytes(query));
    }

    // If the request settled as a result of this call, trigger.state will have
    // been updated in the priceSettled callback.
    return state;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

struct TriggerMetadata {
  // The name that should be used for safety modules that use the trigger.
  string name;
  // A human-readable description of the trigger.
  string description;
  // The URI of a logo image to represent the trigger.
  string logoURI;
  // Extra metadata for the trigger.
  string extraData;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @dev Interface for ERC20 tokens.
 */
interface IERC20 {
  /// @dev Emitted when the allowance of a `spender` for an `owner` is updated, where `amount` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 value);
  /// @dev Emitted when `amount` tokens are moved from `from` to `to`.
  event Transfer(address indexed from, address indexed to, uint256 value);

  /// @notice Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `holder`.
  function allowance(address owner, address spender) external view returns (uint256);
  /// @notice Sets `_amount` as the allowance of `_spender` over the caller's tokens.
  function approve(address spender, uint256 amount) external returns (bool);
  /// @notice Returns the amount of tokens owned by `account`.
  function balanceOf(address account) external view returns (uint256);
  /// @notice Returns the decimal places of the token.
  function decimals() external view returns (uint8);
  /// @notice Sets `_value` as the allowance of `_spender` over `_owner`s tokens, given a signed approval from the
  /// owner.
  function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
    external;
  /// @notice Returns the name of the token.
  function name() external view returns (string memory);
  /// @notice Returns the symbol of the token.
  function symbol() external view returns (string memory);
  /// @notice Returns the amount of tokens in existence.
  function totalSupply() external view returns (uint256);
  /// @notice Moves `_amount` tokens from the caller's account to `_to`.
  function transfer(address to, uint256 amount) external returns (bool);
  /// @notice Moves `_amount` tokens from `_from` to `_to` using the allowance mechanism. `_amount` is then deducted
  /// from the caller's allowance.
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";
import {IUMATrigger} from "./IUMATrigger.sol";
import {TriggerMetadata} from "../structs/Triggers.sol";

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
  ) external returns (IUMATrigger _trigger);

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// A named import is used to avoid identifier naming conflicts between IERC20 imports. solc throws a DeclarationError
// if an interface with the same name is imported twice in a file using different paths, even if they have the
// same implementation. For example, if a file in the cozy-v2-interfaces submodule that is imported in this project
// imports an IERC20 interface with "import src/interfaces/IERC20.sol;", but in this project we import the same
// interface with "import cozy-v2-interfaces/interfaces/IERC20.sol;", a DeclarationError will be thrown.
import { IERC20 } from "./IERC20.sol";

abstract contract OptimisticOracleV2Interface {
    struct RequestSettings {
        bool eventBased; // True if the request is set to be event-based.
        bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
        bool callbackOnPriceProposed; // True if callbackOnPriceProposed callback is required.
        bool callbackOnPriceDisputed; // True if callbackOnPriceDisputed callback is required.
        bool callbackOnPriceSettled; // True if callbackOnPriceSettled callback is required.
        uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
        uint256 customLiveness; // Custom liveness value set by the requester.
    }

    // Struct representing a price request.
    struct Request {
        address proposer; // Address of the proposer.
        address disputer; // Address of the disputer.
        IERC20 currency; // ERC20 token used to pay rewards and fees.
        bool settled; // True if the request is settled.
        RequestSettings requestSettings; // Custom settings associated with a request.
        int256 proposedPrice; // Price that the proposer submitted.
        int256 resolvedPrice; // Price resolved once the request is settled.
        uint256 expirationTime; // Time at which the request auto-settles without a dispute.
        uint256 reward; // Amount of the currency to pay to the proposer on settlement.
        uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
    }

    /**
     * @notice Requests a new price.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data representing additional args being passed with the price request.
     * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
     * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
     *               which could make sense if the contract requests and proposes the value in the same call or
     *               provides its own reward system.
     * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
     * This can be changed with a subsequent call to setBond().
     */
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Set the proposal bond associated with a price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param bond custom bond amount to set.
     * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
     * changed again with a subsequent call to setBond().
     */
    function setBond(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 bond
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Sets a custom liveness value for the request. Liveness is the amount of time a proposal must wait before
     * being auto-resolved.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param customLiveness new custom liveness.
     */
    function setCustomLiveness(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 customLiveness
    ) external virtual;

    /**
     * @notice Sets the request to be an "event-based" request.
     * @dev Calling this method has a few impacts on the request:
     *
     * 1. The timestamp at which the request is evaluated is the time of the proposal, not the timestamp associated
     *    with the request.
     *
     * 2. The proposer cannot propose the "too early" value (TOO_EARLY_RESPONSE). This is to ensure that a proposer who
     *    prematurely proposes a response loses their bond.
     *
     * 3. RefundoOnDispute is automatically set, meaning disputes trigger the reward to be automatically refunded to
     *    the requesting contract.
     *
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function setEventBased(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual;

    /**
     * @notice Sets which callbacks should be enabled for the request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param callbackOnPriceProposed whether to enable the callback onPriceProposed.
     * @param callbackOnPriceDisputed whether to enable the callback onPriceDisputed.
     * @param callbackOnPriceSettled whether to enable the callback onPriceSettled.
     */
    function setCallbacks(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        bool callbackOnPriceProposed,
        bool callbackOnPriceDisputed,
        bool callbackOnPriceSettled
    ) external virtual;

    /**
     * @notice Proposes a price value for an existing price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Disputes a price value for an existing price request with an active proposal.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was valid (the proposal was incorrect).
     */
    function disputePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
     * the returned bonds as well as additional rewards.
     */
    function settle(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (uint256 payout);

    /**
     * @notice Gets the current data structure containing all information about a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the Request data structure.
     */
    function getRequest(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (Request memory);

    /**
     * @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return true if price has resolved or settled, false otherwise.
     */
    function hasPrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {ITrigger} from "../interfaces/ITrigger.sol";
import {TriggerState} from "../structs/StateEnums.sol";

/**
 * @dev Core trigger interface and implementation. All triggers should inherit from this to ensure they conform
 * to the required trigger interface.
 */
abstract contract BaseTrigger is ITrigger {
  /// @notice Current trigger state.
  TriggerState public state;

  /// @dev Thrown when a state update results in an invalid state transition.
  error InvalidStateTransition();

  /// @dev Child contracts should use this function to handle Trigger state transitions.
  function _updateTriggerState(TriggerState _newState) internal returns (TriggerState) {
    if (!_isValidTriggerStateTransition(state, _newState)) revert InvalidStateTransition();
    state = _newState;
    emit TriggerStateUpdated(_newState);
    return _newState;
  }

  /// @dev Reimplement this function if different state transitions are needed.
  function _isValidTriggerStateTransition(TriggerState _oldState, TriggerState _newState)
    internal
    virtual
    returns (bool)
  {
    // | From / To | ACTIVE      | FROZEN      | PAUSED   | TRIGGERED |
    // | --------- | ----------- | ----------- | -------- | --------- |
    // | ACTIVE    | -           | true        | false    | true      |
    // | FROZEN    | true        | -           | false    | true      |
    // | PAUSED    | false       | false       | -        | false     | <-- PAUSED is a safety module-level state
    // | TRIGGERED | false       | false       | false    | -         | <-- TRIGGERED is a terminal state

    if (_oldState == TriggerState.TRIGGERED) return false;
    // If oldState == newState, return true since the safety module will convert that into a no-op.
    if (_oldState == _newState) return true;
    if (_oldState == TriggerState.ACTIVE && _newState == TriggerState.FROZEN) return true;
    if (_oldState == TriggerState.FROZEN && _newState == TriggerState.ACTIVE) return true;
    if (_oldState == TriggerState.ACTIVE && _newState == TriggerState.TRIGGERED) return true;
    if (_oldState == TriggerState.FROZEN && _newState == TriggerState.TRIGGERED) return true;
    return false;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

enum TriggerState {
  ACTIVE,
  TRIGGERED,
  FROZEN
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TriggerState} from "../structs/StateEnums.sol";

/**
 * @notice This is an automated trigger contract which will move into a
 * TRIGGERED state in the event that the UMA Optimistic Oracle answers "YES" to
 * a provided query, e.g. "Was protocol ABCD hacked on or after block 42". More
 * information about UMA oracles and the lifecycle of queries can be found here:
 * https://docs.umaproject.org/.
 * @dev The high-level lifecycle of a UMA request is as follows:
 * - someone asks a question of the oracle and provides a reward for someone
 * to answer it
 * - users of the UMA prediction market view the question (usually here:
 * https://oracle.umaproject.org/)
 * - someone proposes an answer to the question in hopes of claiming the
 * reward`
 * - users of UMA see the proposed answer and have a chance to dispute it
 * - there is a finite period of time within which to dispute the answer
 * - if the answer is not disputed during this period, the oracle finalizes
 * the answer and the proposer gets the reward
 * - if the answer is disputed, the question is sent to the DVM (Data
 * Verification Mechanism) in which UMA token holders vote on who is right
 * There are four essential players in the above process:
 * 1. Requester: the account that is asking the oracle a question.
 * 2. Proposer: the account that submits an answer to the question.
 * 3. Disputer: the account (if any) that disagrees with the proposed answer.
 * 4. The DVM: a DAO that is the final arbiter of disputed proposals.
 * This trigger plays the first role in this lifecycle. It submits a request for
 * an answer to a yes-or-no question (the query) to the Optimistic Oracle.
 * Questions need to be phrased in such a way that if a "Yes" answer is given
 * to them, then this contract will go into a TRIGGERED state. For
 * example, if you wanted to create a safety module for protecting Compound
 * users, you might deploy a UMATrigger with a query like "Was Compound hacked
 * after block X?" If the oracle responds with a "Yes" answer, this contract
 * would move into the TRIGGERED state and safety modules  with this trigger
 * registered could transition to the TRIGGERED state and potentially payout
 * Compound users.
 * But what if Compound hasn't been hacked? Can't someone just respond "No" to
 * the trigger's query? Wouldn't that be the right answer and wouldn't it mean
 * the end of the query lifecycle? Yes. For this exact reason, we have enabled
 * callbacks (see the `priceProposed` function) which will revert in the event
 * that someone attempts to propose a negative answer to the question. We want
 * the queries to remain open indefinitely until there is a positive answer,
 * i.e. "Yes, there was a hack". **This should be communicated in the query text.**
 * In the event that a YES answer to a query is disputed and the DVM sides
 * with the disputer (i.e. a NO answer), we immediately re-submit the query to
 * the DVM through another callback (see `priceSettled`). In this way, our query
 * will always be open with the oracle. If/when the event that we are concerned
 * with happens the trigger will immediately be notified.
 */
interface IUMATrigger {
  /// @dev Emitted when a trigger's state is updated.
  event TriggerStateUpdated(TriggerState indexed state);

  /// @notice The current trigger state.
  function state() external returns (TriggerState);

  /// @notice The type of query that will be submitted to the oracle.
  function queryIdentifier() external view returns (bytes32);

  /// @notice The UMA contract used to lookup the UMA Optimistic Oracle.
  function oracleFinder() external view returns (address);

  /// @notice The query that is sent to the UMA Optimistic Oracle for evaluation.
  /// It should be phrased so that only a positive answer is appropriate, e.g.
  /// "Was protocol ABCD hacked on or after block number 42". Negative answers
  /// are disallowed so that queries can remain open in UMA until the events we
  /// care about happen, if ever.
  function query() external view returns (string memory);

  /// @notice The token used to pay the reward to users that propose answers to the query.
  function rewardToken() external view returns (address);

  /// @notice The amount of `rewardToken` that must be staked by a user wanting
  /// to propose or dispute an answer to the query. See UMA's price dispute
  /// workflow for more information. It's recommended that the bond amount be a
  /// significant value to deter addresses from proposing malicious, false, or
  /// otherwise self-interested answers to the query.
  function bondAmount() external view returns (uint256);

  /// @notice The window of time in seconds within which a proposed answer may
  /// be disputed. See UMA's "customLiveness" setting for more information. It's
  /// recommended that the dispute window be fairly long (12-24 hours), given
  /// the difficulty of assessing expected queries (e.g. "Was protocol ABCD
  /// hacked") and the amount of funds potentially at stake.
  function proposalDisputeWindow() external view returns (uint256);

  /// @notice The most recent timestamp that the query was submitted to the UMA oracle.
  function requestTimestamp() external view returns (uint256);

  /// @notice UMA callback for proposals. This function is called by the UMA
  /// oracle when a new answer is proposed for the query. Its only purpose is to
  /// prevent people from proposing negative answers and prematurely closing our
  /// queries. For example, if our query were something like "Has Compound been
  /// hacked since block X?" the correct answer could easily be "No" right now.
  /// But we we don't care if the answer is "No". The trigger only cares when
  /// hacks *actually happen*. So we revert when people try to submit negative
  /// answers, as negative answers that are undisputed would resolve our query
  /// and we'd have to pay a new reward to resubmit.
  /// @param _identifier price identifier being requested.
  /// @param _timestamp timestamp of the original query request.
  /// @param _ancillaryData ancillary data of the original query request.
  function priceProposed(bytes32 _identifier, uint256 _timestamp, bytes memory _ancillaryData) external;

  /// @notice UMA callback for settlement. This code is run when the protocol
  /// has confirmed an answer to the query.
  /// @dev This callback is kept intentionally lean, as we don't want to risk
  /// reverting and blocking settlement.
  /// @param _identifier price identifier being requested.
  /// @param _timestamp timestamp of the original query request.
  /// @param _ancillaryData ancillary data of the original query request.
  /// @param _answer the oracle's answer to the query.
  function priceSettled(bytes32 _identifier, uint256 _timestamp, bytes memory _ancillaryData, int256 _answer) external;

  /// @notice Toggles the trigger if the UMA oracle has confirmed a positive
  /// answer to the query.
  function runProgrammaticCheck() external returns (uint8);

  /// @notice The UMA Optimistic Oracle queried by this trigger.
  function getOracle() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TriggerState} from "../structs/StateEnums.sol";

/**
 * @dev The minimal functions a trigger must implement to work with the Cozy Safety Module protocol.
 */
interface ITrigger {
  /// @dev Emitted when a trigger's state is updated.
  event TriggerStateUpdated(TriggerState indexed state);

  /// @notice The current trigger state.
  function state() external returns (TriggerState);
}