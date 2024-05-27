// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.5.16;

import "./IAccessControlManagerV5.sol";

/**
 * @title AccessControlledV5
 * @author Venus
 * @notice This contract is helper between access control manager and actual contract. This contract further inherited by other contract (using solidity 0.5.16)
 * to integrate access controlled mechanism. It provides initialise methods and verifying access methods.
 */
contract AccessControlledV5 {
    /// @notice Access control manager contract
    IAccessControlManagerV5 private _accessControlManager;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    /// @notice Emitted when access control manager contract address is changed
    event NewAccessControlManager(address oldAccessControlManager, address newAccessControlManager);

    /**
     * @notice Returns the address of the access control manager contract
     */
    function accessControlManager() external view returns (IAccessControlManagerV5) {
        return _accessControlManager;
    }

    /**
     * @dev Internal function to set address of AccessControlManager
     * @param accessControlManager_ The new address of the AccessControlManager
     */
    function _setAccessControlManager(address accessControlManager_) internal {
        require(address(accessControlManager_) != address(0), "invalid acess control manager address");
        address oldAccessControlManager = address(_accessControlManager);
        _accessControlManager = IAccessControlManagerV5(accessControlManager_);
        emit NewAccessControlManager(oldAccessControlManager, accessControlManager_);
    }

    /**
     * @notice Reverts if the call is not allowed by AccessControlManager
     * @param signature Method signature
     */
    function _checkAccessAllowed(string memory signature) internal view {
        bool isAllowedToCall = _accessControlManager.isAllowedToCall(msg.sender, signature);

        if (!isAllowedToCall) {
            revert("Unauthorized");
        }
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./GovernorBravoInterfaces.sol";

/**
 * @title GovernorBravoDelegate
 * @notice Venus Governance latest on chain governance includes several new features including variable proposal routes and fine grained pause control.
 * Variable routes for proposals allows for governance paramaters such as voting threshold and timelocks to be customized based on the risk level and
 * impact of the proposal. Added granularity to the pause control mechanism allows governance to pause individual actions on specific markets,
 * which reduces impact on the protocol as a whole. This is particularly useful when applied to isolated pools.
 *
 * The goal of **Governance** is to increase governance efficiency, while mitigating and eliminating malicious or erroneous proposals.
 *
 * ## Details
 *
 * Governance has **3 main contracts**: **GovernanceBravoDelegate, XVSVault, XVS** token.
 *
 * - XVS token is the protocol token used for protocol users to cast their vote on submitted proposals.
 * - XVSVault is the main staking contract for XVS. Users first stake their XVS in the vault and receive voting power proportional to their staked
 * tokens that they can use to vote on proposals. Users also can choose to delegate their voting power to other users.
 *
 * # Governor Bravo
 *
 * `GovernanceBravoDelegate` is main Venus Governance contract. Users interact with it to:
 * - Submit new proposal
 * - Vote on a proposal
 * - Cancel a proposal
 * - Queue a proposal for execution with a timelock executor contract.
 * `GovernanceBravoDelegate` uses the XVSVault to get restrict certain actions based on a user's voting power. The governance rules it inforces are:
 * - A user's voting power must be greater than the `proposalThreshold` to submit a proposal
 * - If a user's voting power drops below certain amount, anyone can cancel the the proposal. The governance guardian and proposal creator can also
 * cancel a proposal at anytime before it is queued for execution.
 *
 * ## Venus Improvement Proposal
 *
 * Venus Governance allows for Venus Improvement Proposals (VIPs) to be categorized based on their impact and risk levels. This allows for optimizing proposals
 * execution to allow for things such as expediting interest rate changes and quickly updating risk parameters, while moving slower on other types of proposals
 * that can prevent a larger risk to the protocol and are not urgent. There are three different types of VIPs with different proposal paramters:
 *
 * - `NORMAL`
 * - `FASTTRACK`
 * - `CRITICAL`
 *
 * When initializing the `GovernorBravo` contract, the parameters for the three routes are set. The parameters are:
 *
 * - `votingDelay`: The delay in blocks between submitting a proposal and when voting begins
 * - `votingPeriod`: The number of blocks where voting will be open
 * - `proposalThreshold`: The number of votes required in order submit a proposal
 *
 * There is also a separate timelock executor contract for each route, which is used to dispatch the VIP for execution, giving even more control over the
 * flow of each type of VIP.
 *
 * ## Voting
 *
 * After a VIP is proposed, voting is opened after the `votingDelay` has passed. For example, if `votingDelay = 0`, then voting will begin in the next block
 * after the proposal has been submitted. After the delay, the proposal state is `ACTIVE` and users can cast their vote `for`, `against`, or `abstain`,
 * weighted by their total voting power (tokens + delegated voting power). Abstaining from a voting allows for a vote to be cast and optionally include a
 * comment, without the incrementing for or against vote count. The total voting power for the user is obtained by calling XVSVault's `getPriorVotes`.
 *
 * `GovernorBravoDelegate` also accepts [EIP-712](https://eips.ethereum.org/EIPS/eip-712) signatures for voting on proposals via the external function
 * `castVoteBySig`.
 *
 * ## Delegating
 *
 * A users voting power includes the amount of staked XVS the have staked as well as the votes delegate to them. Delegating is the process of a user loaning
 * their voting power to another, so that the latter has the combined voting power of both users. This is an important feature because it allows for a user
 * to let another user who they trust propose or vote in their place.
 *
 * The delegation of votes happens through the `XVSVault` contract by calling the `delegate` or `delegateBySig` functions. These same functions can revert
 * vote delegation by calling the same function with a value of `0`.
 */
contract GovernorBravoDelegate is GovernorBravoDelegateStorageV2, GovernorBravoEvents {
    /// @notice The name of this contract
    string public constant name = "Venus Governor Bravo";

    /// @notice The minimum setable proposal threshold
    uint public constant MIN_PROPOSAL_THRESHOLD = 150000e18; // 150,000 Xvs

    /// @notice The maximum setable proposal threshold
    uint public constant MAX_PROPOSAL_THRESHOLD = 300000e18; //300,000 Xvs

    /// @notice The minimum setable voting period
    uint public constant MIN_VOTING_PERIOD = 20 * 60 * 3; // About 3 hours, 3 secs per block

    /// @notice The max setable voting period
    uint public constant MAX_VOTING_PERIOD = 20 * 60 * 24 * 14; // About 2 weeks, 3 secs per block

    /// @notice The min setable voting delay
    uint public constant MIN_VOTING_DELAY = 1;

    /// @notice The max setable voting delay
    uint public constant MAX_VOTING_DELAY = 20 * 60 * 24 * 7; // About 1 week, 3 secs per block

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    uint public constant quorumVotes = 600000e18; // 600,000 = 2% of Xvs

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");

    /**
     * @notice Used to initialize the contract during delegator contructor
     * @param xvsVault_ The address of the XvsVault
     * @param proposalConfigs_ Governance configs for each governance route
     * @param timelocks Timelock addresses for each governance route
     */
    function initialize(
        address xvsVault_,
        ProposalConfig[] memory proposalConfigs_,
        TimelockInterface[] memory timelocks,
        address guardian_
    ) public {
        require(address(proposalTimelocks[0]) == address(0), "GovernorBravo::initialize: cannot initialize twice");
        require(msg.sender == admin, "GovernorBravo::initialize: admin only");
        require(xvsVault_ != address(0), "GovernorBravo::initialize: invalid xvs address");
        require(guardian_ != address(0), "GovernorBravo::initialize: invalid guardian");
        require(
            timelocks.length == uint8(ProposalType.CRITICAL) + 1,
            "GovernorBravo::initialize:number of timelocks should match number of governance routes"
        );
        require(
            proposalConfigs_.length == uint8(ProposalType.CRITICAL) + 1,
            "GovernorBravo::initialize:number of proposal configs should match number of governance routes"
        );

        xvsVault = XvsVaultInterface(xvsVault_);
        proposalMaxOperations = 10;
        guardian = guardian_;

        //Set parameters for each Governance Route
        uint256 arrLength = proposalConfigs_.length;
        for (uint256 i; i < arrLength; ++i) {
            require(
                proposalConfigs_[i].votingPeriod >= MIN_VOTING_PERIOD,
                "GovernorBravo::initialize: invalid min voting period"
            );
            require(
                proposalConfigs_[i].votingPeriod <= MAX_VOTING_PERIOD,
                "GovernorBravo::initialize: invalid max voting period"
            );
            require(
                proposalConfigs_[i].votingDelay >= MIN_VOTING_DELAY,
                "GovernorBravo::initialize: invalid min voting delay"
            );
            require(
                proposalConfigs_[i].votingDelay <= MAX_VOTING_DELAY,
                "GovernorBravo::initialize: invalid max voting delay"
            );
            require(
                proposalConfigs_[i].proposalThreshold >= MIN_PROPOSAL_THRESHOLD,
                "GovernorBravo::initialize: invalid min proposal threshold"
            );
            require(
                proposalConfigs_[i].proposalThreshold <= MAX_PROPOSAL_THRESHOLD,
                "GovernorBravo::initialize: invalid max proposal threshold"
            );
            require(address(timelocks[i]) != address(0), "GovernorBravo::initialize:invalid timelock address");

            proposalConfigs[i] = proposalConfigs_[i];
            proposalTimelocks[i] = timelocks[i];
        }
    }

    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold.
     * targets, values, signatures, and calldatas must be of equal length
     * @dev NOTE: Proposals with duplicate set of actions can not be queued for execution. If the proposals consists
     *  of duplicate actions, it's recommended to split those actions into separate proposals
     * @param targets Target addresses for proposal calls
     * @param values BNB values for proposal calls
     * @param signatures Function signatures for proposal calls
     * @param calldatas Calldatas for proposal calls
     * @param description String description of the proposal
     * @param proposalType the type of the proposal (e.g NORMAL, FASTTRACK, CRITICAL)
     * @return Proposal id of new proposal
     */
    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description,
        ProposalType proposalType
    ) public returns (uint) {
        // Reject proposals before initiating as Governor
        require(initialProposalId != 0, "GovernorBravo::propose: Governor Bravo not active");
        require(
            xvsVault.getPriorVotes(msg.sender, sub256(block.number, 1)) >=
                proposalConfigs[uint8(proposalType)].proposalThreshold,
            "GovernorBravo::propose: proposer votes below proposal threshold"
        );
        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "GovernorBravo::propose: proposal function information arity mismatch"
        );
        require(targets.length != 0, "GovernorBravo::propose: must provide actions");
        require(targets.length <= proposalMaxOperations, "GovernorBravo::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(
                proposersLatestProposalState != ProposalState.Active,
                "GovernorBravo::propose: one live proposal per proposer, found an already active proposal"
            );
            require(
                proposersLatestProposalState != ProposalState.Pending,
                "GovernorBravo::propose: one live proposal per proposer, found an already pending proposal"
            );
        }

        uint startBlock = add256(block.number, proposalConfigs[uint8(proposalType)].votingDelay);
        uint endBlock = add256(startBlock, proposalConfigs[uint8(proposalType)].votingPeriod);

        proposalCount++;
        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            eta: 0,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            startBlock: startBlock,
            endBlock: endBlock,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            canceled: false,
            executed: false,
            proposalType: uint8(proposalType)
        });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            startBlock,
            endBlock,
            description,
            uint8(proposalType)
        );
        return newProposal.id;
    }

    /**
     * @notice Queues a proposal of state succeeded
     * @param proposalId The id of the proposal to queue
     */
    function queue(uint proposalId) external {
        require(
            state(proposalId) == ProposalState.Succeeded,
            "GovernorBravo::queue: proposal can only be queued if it is succeeded"
        );
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, proposalTimelocks[uint8(proposal.proposalType)].delay());
        for (uint i; i < proposal.targets.length; ++i) {
            queueOrRevertInternal(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                eta,
                uint8(proposal.proposalType)
            );
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function queueOrRevertInternal(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta,
        uint8 proposalType
    ) internal {
        require(
            !proposalTimelocks[proposalType].queuedTransactions(
                keccak256(abi.encode(target, value, signature, data, eta))
            ),
            "GovernorBravo::queueOrRevertInternal: identical proposal action already queued at eta"
        );
        proposalTimelocks[proposalType].queueTransaction(target, value, signature, data, eta);
    }

    /**
     * @notice Executes a queued proposal if eta has passed
     * @param proposalId The id of the proposal to execute
     */
    function execute(uint proposalId) external {
        require(
            state(proposalId) == ProposalState.Queued,
            "GovernorBravo::execute: proposal can only be executed if it is queued"
        );
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i; i < proposal.targets.length; ++i) {
            proposalTimelocks[uint8(proposal.proposalType)].executeTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
     * @param proposalId The id of the proposal to cancel
     */
    function cancel(uint proposalId) external {
        require(state(proposalId) != ProposalState.Executed, "GovernorBravo::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == guardian ||
                msg.sender == proposal.proposer ||
                xvsVault.getPriorVotes(proposal.proposer, sub256(block.number, 1)) <
                proposalConfigs[proposal.proposalType].proposalThreshold,
            "GovernorBravo::cancel: proposer above threshold"
        );

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            proposalTimelocks[proposal.proposalType].cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Gets actions of a proposal
     * @param proposalId the id of the proposal
     * @return targets, values, signatures, and calldatas of the proposal actions
     */
    function getActions(
        uint proposalId
    )
        external
        view
        returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas)
    {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
     * @notice Gets the receipt for a voter on a given proposal
     * @param proposalId the id of proposal
     * @param voter The address of the voter
     * @return The voting receipt
     */
    function getReceipt(uint proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint proposalId) public view returns (ProposalState) {
        require(
            proposalCount >= proposalId && proposalId > initialProposalId,
            "GovernorBravo::state: invalid proposal id"
        );
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (
            block.timestamp >= add256(proposal.eta, proposalTimelocks[uint8(proposal.proposalType)].GRACE_PERIOD())
        ) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVote(uint proposalId, uint8 support) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), "");
    }

    /**
     * @notice Cast a vote for a proposal with a reason
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param reason The reason given for the vote by the voter
     */
    function castVoteWithReason(uint proposalId, uint8 support, string calldata reason) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), reason);
    }

    /**
     * @notice Cast a vote for a proposal by signature
     * @dev External function that accepts EIP-712 signatures for voting on proposals.
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param v recovery id of ECDSA signature
     * @param r part of the ECDSA sig output
     * @param s part of the ECDSA sig output
     */
    function castVoteBySig(uint proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainIdInternal(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GovernorBravo::castVoteBySig: invalid signature");
        emit VoteCast(signatory, proposalId, support, castVoteInternal(signatory, proposalId, support), "");
    }

    /**
     * @notice Internal function that caries out voting logic
     * @param voter The voter that is casting their vote
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @return The number of votes cast
     */
    function castVoteInternal(address voter, uint proposalId, uint8 support) internal returns (uint96) {
        require(state(proposalId) == ProposalState.Active, "GovernorBravo::castVoteInternal: voting is closed");
        require(support <= 2, "GovernorBravo::castVoteInternal: invalid vote type");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "GovernorBravo::castVoteInternal: voter already voted");
        uint96 votes = xvsVault.getPriorVotes(voter, proposal.startBlock);

        if (support == 0) {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        } else if (support == 1) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else if (support == 2) {
            proposal.abstainVotes = add256(proposal.abstainVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        return votes;
    }

    /**
     * @notice Sets the new governance guardian
     * @param newGuardian the address of the new guardian
     */
    function _setGuardian(address newGuardian) external {
        require(msg.sender == guardian || msg.sender == admin, "GovernorBravo::_setGuardian: admin or guardian only");
        require(newGuardian != address(0), "GovernorBravo::_setGuardian: cannot live without a guardian");
        address oldGuardian = guardian;
        guardian = newGuardian;

        emit NewGuardian(oldGuardian, newGuardian);
    }

    /**
     * @notice Initiate the GovernorBravo contract
     * @dev Admin only. Sets initial proposal id which initiates the contract, ensuring a continuous proposal id count
     * @param governorAlpha The address for the Governor to continue the proposal id count from
     */
    function _initiate(address governorAlpha) external {
        require(msg.sender == admin, "GovernorBravo::_initiate: admin only");
        require(initialProposalId == 0, "GovernorBravo::_initiate: can only initiate once");
        proposalCount = GovernorAlphaInterface(governorAlpha).proposalCount();
        initialProposalId = proposalCount;
        for (uint256 i; i < uint8(ProposalType.CRITICAL) + 1; ++i) {
            proposalTimelocks[i].acceptAdmin();
        }
    }

    /**
     * @notice Set max proposal operations
     * @dev Admin only.
     * @param proposalMaxOperations_ Max proposal operations
     */
    function _setProposalMaxOperations(uint proposalMaxOperations_) external {
        require(msg.sender == admin, "GovernorBravo::_setProposalMaxOperations: admin only");
        uint oldProposalMaxOperations = proposalMaxOperations;
        proposalMaxOperations = proposalMaxOperations_;

        emit ProposalMaxOperationsUpdated(oldProposalMaxOperations, proposalMaxOperations_);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(address newPendingAdmin) external {
        // Check caller = admin
        require(msg.sender == admin, "GovernorBravo:_setPendingAdmin: admin only");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "GovernorBravo:_acceptAdmin: pending admin only"
        );

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getChainIdInternal() internal pure returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

/**
 * @title GovernorBravoEvents
 * @author Venus
 * @notice Set of events emitted by the GovernorBravo contracts.
 */
contract GovernorBravoEvents {
    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint id,
        address proposer,
        address[] targets,
        uint[] values,
        string[] signatures,
        bytes[] calldatas,
        uint startBlock,
        uint endBlock,
        string description,
        uint8 proposalType
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param votes Number of votes which were cast by the voter
    /// @param reason The reason given for the vote by the voter
    event VoteCast(address indexed voter, uint proposalId, uint8 support, uint votes, string reason);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    /// @notice An event emitted when the voting delay is set
    event VotingDelaySet(uint oldVotingDelay, uint newVotingDelay);

    /// @notice An event emitted when the voting period is set
    event VotingPeriodSet(uint oldVotingPeriod, uint newVotingPeriod);

    /// @notice Emitted when implementation is changed
    event NewImplementation(address oldImplementation, address newImplementation);

    /// @notice Emitted when proposal threshold is set
    event ProposalThresholdSet(uint oldProposalThreshold, uint newProposalThreshold);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);

    /// @notice Emitted when the new guardian address is set
    event NewGuardian(address oldGuardian, address newGuardian);

    /// @notice Emitted when the maximum number of operations in one proposal is updated
    event ProposalMaxOperationsUpdated(uint oldMaxOperations, uint newMaxOperations);
}

/**
 * @title GovernorBravoDelegatorStorage
 * @author Venus
 * @notice Storage layout of the `GovernorBravoDelegator` contract
 */
contract GovernorBravoDelegatorStorage {
    /// @notice Administrator for this contract
    address public admin;

    /// @notice Pending administrator for this contract
    address public pendingAdmin;

    /// @notice Active brains of Governor
    address public implementation;
}

/**
 * @title GovernorBravoDelegateStorageV1
 * @dev For future upgrades, do not change GovernorBravoDelegateStorageV1. Create a new
 * contract which implements GovernorBravoDelegateStorageV1 and following the naming convention
 * GovernorBravoDelegateStorageVX.
 */
contract GovernorBravoDelegateStorageV1 is GovernorBravoDelegatorStorage {
    /// @notice DEPRECATED The delay before voting on a proposal may take place, once proposed, in blocks
    uint public votingDelay;

    /// @notice DEPRECATED The duration of voting on a proposal, in blocks
    uint public votingPeriod;

    /// @notice DEPRECATED The number of votes required in order for a voter to become a proposer
    uint public proposalThreshold;

    /// @notice Initial proposal id set at become
    uint public initialProposalId;

    /// @notice The total number of proposals
    uint public proposalCount;

    /// @notice The address of the Venus Protocol Timelock
    TimelockInterface public timelock;

    /// @notice The address of the Venus governance token
    XvsVaultInterface public xvsVault;

    /// @notice The official record of all proposals ever proposed
    mapping(uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint) public latestProposalIds;

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;
        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;
        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;
        /// @notice The ordered list of function signatures to be called
        string[] signatures;
        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint endBlock;
        /// @notice Current number of votes in favor of this proposal
        uint forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint abstainVotes;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;
        /// @notice The type of the proposal
        uint8 proposalType;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;
        /// @notice Whether or not the voter supports the proposal or abstains
        uint8 support;
        /// @notice The number of votes the voter had, which were cast
        uint96 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice The maximum number of actions that can be included in a proposal
    uint public proposalMaxOperations;

    /// @notice A privileged role that can cancel any proposal
    address public guardian;
}

/**
 * @title GovernorBravoDelegateStorageV2
 * @dev For future upgrades, do not change GovernorBravoDelegateStorageV1. Create a new
 * contract which implements GovernorBravoDelegateStorageV2 and following the naming convention
 * GovernorBravoDelegateStorageVX.
 */
contract GovernorBravoDelegateStorageV2 is GovernorBravoDelegateStorageV1 {
    enum ProposalType {
        NORMAL,
        FASTTRACK,
        CRITICAL
    }

    struct ProposalConfig {
        /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
        uint256 votingDelay;
        /// @notice The duration of voting on a proposal, in blocks
        uint256 votingPeriod;
        /// @notice The number of votes required in order for a voter to become a proposer
        uint256 proposalThreshold;
    }

    /// @notice mapping containing configuration for each proposal type
    mapping(uint => ProposalConfig) public proposalConfigs;

    /// @notice mapping containing Timelock addresses for each proposal type
    mapping(uint => TimelockInterface) public proposalTimelocks;
}

/**
 * @title TimelockInterface
 * @author Venus
 * @notice Interface implemented by the Timelock contract.
 */
interface TimelockInterface {
    function delay() external view returns (uint);

    function GRACE_PERIOD() external view returns (uint);

    function acceptAdmin() external;

    function queuedTransactions(bytes32 hash) external view returns (bool);

    function queueTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) external;

    function executeTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) external payable returns (bytes memory);
}

interface XvsVaultInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}

interface GovernorAlphaInterface {
    /// @notice The total number of proposals
    function proposalCount() external returns (uint);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.5.16;

/**
 * @title IAccessControlManagerV5
 * @author Venus
 * @notice Interface implemented by the `AccessControlManagerV5` contract.
 */
interface IAccessControlManagerV5 {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
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

    /**
     * @notice Gives a function call permission to one single account
     * @dev this function can be called only from Role Admin or DEFAULT_ADMIN_ROLE
     * 		May emit a {RoleGranted} event.
     * @param contractAddress address of contract for which call permissions will be granted
     * @param functionSig signature e.g. "functionName(uint,bool)"
     */
    function giveCallPermission(address contractAddress, string calldata functionSig, address accountToPermit) external;

    /**
     * @notice Revokes an account's permission to a particular function call
     * @dev this function can be called only from Role Admin or DEFAULT_ADMIN_ROLE
     * 		May emit a {RoleRevoked} event.
     * @param contractAddress address of contract for which call permissions will be revoked
     * @param functionSig signature e.g. "functionName(uint,bool)"
     */
    function revokeCallPermission(
        address contractAddress,
        string calldata functionSig,
        address accountToRevoke
    ) external;

    /**
     * @notice Verifies if the given account can call a praticular contract's function
     * @dev Since the contract is calling itself this function, we can get contracts address with msg.sender
     * @param account address (eoa or contract) for which call permissions will be checked
     * @param functionSig signature e.g. "functionName(uint,bool)"
     * @return false if the user account cannot call the particular contract function
     *
     */
    function isAllowedToCall(address account, string calldata functionSig) external view returns (bool);

    function hasPermission(
        address account,
        address contractAddress,
        string calldata functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.5.16;

contract TimeManagerV5 {
    /// @dev The approximate number of seconds per year
    uint256 public constant SECONDS_PER_YEAR = 31_536_000;

    /// @notice Number of blocks per year or seconds per year
    uint256 public blocksOrSecondsPerYear;

    /// @dev Sets true when block timestamp is used
    bool public isTimeBased;

    /// @dev Sets true when contract is initialized
    bool private isInitialized;

    /// @notice Deprecated slot for _getCurrentSlot function pointer
    bytes8 private __deprecatedSlot1;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;

    /**
     * @dev Function to simply retrieve block number or block timestamp
     * @return Current block number or block timestamp
     */
    function getBlockNumberOrTimestamp() public view returns (uint256) {
        return isTimeBased ? _getBlockTimestamp() : _getBlockNumber();
    }

    /**
     * @dev Initializes the contract to use either blocks or seconds
     * @param timeBased_ A boolean indicating whether the contract is based on time or block
     * If timeBased is true than blocksPerYear_ param is ignored as blocksOrSecondsPerYear is set to SECONDS_PER_YEAR
     * @param blocksPerYear_ The number of blocks per year
     */
    function _initializeTimeManager(bool timeBased_, uint256 blocksPerYear_) internal {
        if (isInitialized) revert("Already initialized TimeManager");

        if (!timeBased_ && blocksPerYear_ == 0) {
            revert("Invalid blocks per year");
        }
        if (timeBased_ && blocksPerYear_ != 0) {
            revert("Invalid time based configuration");
        }

        isTimeBased = timeBased_;
        blocksOrSecondsPerYear = timeBased_ ? SECONDS_PER_YEAR : blocksPerYear_;
        isInitialized = true;
    }

    /**
     * @dev Returns the current timestamp in seconds
     * @return The current timestamp
     */
    function _getBlockTimestamp() private view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Returns the current block number
     * @return The current block number
     */
    function _getBlockNumber() private view returns (uint256) {
        return block.number;
    }
}

pragma solidity ^0.5.16;

import "../Tokens/VTokens/VToken.sol";
import "../Oracle/PriceOracle.sol";
import "../Tokens/VAI/VAIControllerInterface.sol";
import { ComptrollerTypes } from "./ComptrollerStorage.sol";

contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata vTokens) external returns (uint[] memory);

    function exitMarket(address vToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address vToken, address minter, uint mintAmount) external returns (uint);

    function mintVerify(address vToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address vToken, address redeemer, uint redeemTokens) external returns (uint);

    function redeemVerify(address vToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address vToken, address borrower, uint borrowAmount) external returns (uint);

    function borrowVerify(address vToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address vToken,
        address payer,
        address borrower,
        uint repayAmount
    ) external returns (uint);

    function repayBorrowVerify(
        address vToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount
    ) external returns (uint);

    function liquidateBorrowVerify(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens
    ) external;

    function seizeAllowed(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external returns (uint);

    function seizeVerify(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external;

    function transferAllowed(address vToken, address src, address dst, uint transferTokens) external returns (uint);

    function transferVerify(address vToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address vTokenBorrowed,
        address vTokenCollateral,
        uint repayAmount
    ) external view returns (uint, uint);

    function setMintedVAIOf(address owner, uint amount) external returns (uint);

    function liquidateVAICalculateSeizeTokens(
        address vTokenCollateral,
        uint repayAmount
    ) external view returns (uint, uint);

    function getXVSAddress() public view returns (address);

    function markets(address) external view returns (bool, uint);

    function oracle() external view returns (PriceOracle);

    function getAccountLiquidity(address) external view returns (uint, uint, uint);

    function getAssetsIn(address) external view returns (VToken[] memory);

    function claimVenus(address) external;

    function venusAccrued(address) external view returns (uint);

    function venusSupplySpeeds(address) external view returns (uint);

    function venusBorrowSpeeds(address) external view returns (uint);

    function getAllMarkets() external view returns (VToken[] memory);

    function venusSupplierIndex(address, address) external view returns (uint);

    function venusInitialIndex() external view returns (uint224);

    function venusBorrowerIndex(address, address) external view returns (uint);

    function venusBorrowState(address) external view returns (uint224, uint32);

    function venusSupplyState(address) external view returns (uint224, uint32);

    function approvedDelegates(address borrower, address delegate) external view returns (bool);

    function vaiController() external view returns (VAIControllerInterface);

    function liquidationIncentiveMantissa() external view returns (uint);

    function protocolPaused() external view returns (bool);

    function actionPaused(address market, ComptrollerTypes.Action action) public view returns (bool);

    function mintedVAIs(address user) external view returns (uint);

    function vaiMintRate() external view returns (uint);
}

interface IVAIVault {
    function updatePendingRewards() external;
}

interface IComptroller {
    function liquidationIncentiveMantissa() external view returns (uint);

    /*** Treasury Data ***/
    function treasuryAddress() external view returns (address);

    function treasuryPercent() external view returns (uint);
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../Tokens/VTokens/VToken.sol";

interface ComptrollerLensInterface {
    function liquidateCalculateSeizeTokens(
        address comptroller,
        address vTokenBorrowed,
        address vTokenCollateral,
        uint actualRepayAmount
    ) external view returns (uint, uint);

    function liquidateVAICalculateSeizeTokens(
        address comptroller,
        address vTokenCollateral,
        uint actualRepayAmount
    ) external view returns (uint, uint);

    function getHypotheticalAccountLiquidity(
        address comptroller,
        address account,
        VToken vTokenModify,
        uint redeemTokens,
        uint borrowAmount
    ) external view returns (uint, uint, uint);
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.5.16;

import { VToken } from "../Tokens/VTokens/VToken.sol";
import { PriceOracle } from "../Oracle/PriceOracle.sol";
import { VAIControllerInterface } from "../Tokens/VAI/VAIControllerInterface.sol";
import { ComptrollerLensInterface } from "./ComptrollerLensInterface.sol";
import { IPrime } from "../Tokens/Prime/IPrime.sol";

interface ComptrollerTypes {
    enum Action {
        MINT,
        REDEEM,
        BORROW,
        REPAY,
        SEIZE,
        LIQUIDATE,
        TRANSFER,
        ENTER_MARKET,
        EXIT_MARKET
    }
}

contract UnitrollerAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active brains of Unitroller
     */
    address public comptrollerImplementation;

    /**
     * @notice Pending brains of Unitroller
     */
    address public pendingComptrollerImplementation;
}

contract ComptrollerV1Storage is ComptrollerTypes, UnitrollerAdminStorage {
    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint256 public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint256 public liquidationIncentiveMantissa;

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral)
     */
    uint256 public maxAssets;

    /**
     * @notice Per-account mapping of "assets you are in", capped by maxAssets
     */
    mapping(address => VToken[]) public accountAssets;

    struct Market {
        /// @notice Whether or not this market is listed
        bool isListed;
        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1, and stored as a mantissa.
         */
        uint256 collateralFactorMantissa;
        /// @notice Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;
        /// @notice Whether or not this market receives XVS
        bool isVenus;
    }

    /**
     * @notice Official mapping of vTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     */
    address public pauseGuardian;

    /// @notice Whether minting is paused (deprecated, superseded by actionPaused)
    bool private _mintGuardianPaused;
    /// @notice Whether borrowing is paused (deprecated, superseded by actionPaused)
    bool private _borrowGuardianPaused;
    /// @notice Whether borrowing is paused (deprecated, superseded by actionPaused)
    bool internal transferGuardianPaused;
    /// @notice Whether borrowing is paused (deprecated, superseded by actionPaused)
    bool internal seizeGuardianPaused;
    /// @notice Whether borrowing is paused (deprecated, superseded by actionPaused)
    mapping(address => bool) internal mintGuardianPaused;
    /// @notice Whether borrowing is paused (deprecated, superseded by actionPaused)
    mapping(address => bool) internal borrowGuardianPaused;

    struct VenusMarketState {
        /// @notice The market's last updated venusBorrowIndex or venusSupplyIndex
        uint224 index;
        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /// @notice A list of all markets
    VToken[] public allMarkets;

    /// @notice The rate at which the flywheel distributes XVS, per block
    uint256 internal venusRate;

    /// @notice The portion of venusRate that each market currently receives
    mapping(address => uint256) internal venusSpeeds;

    /// @notice The Venus market supply state for each market
    mapping(address => VenusMarketState) public venusSupplyState;

    /// @notice The Venus market borrow state for each market
    mapping(address => VenusMarketState) public venusBorrowState;

    /// @notice The Venus supply index for each market for each supplier as of the last time they accrued XVS
    mapping(address => mapping(address => uint256)) public venusSupplierIndex;

    /// @notice The Venus borrow index for each market for each borrower as of the last time they accrued XVS
    mapping(address => mapping(address => uint256)) public venusBorrowerIndex;

    /// @notice The XVS accrued but not yet transferred to each user
    mapping(address => uint256) public venusAccrued;

    /// @notice The Address of VAIController
    VAIControllerInterface public vaiController;

    /// @notice The minted VAI amount to each user
    mapping(address => uint256) public mintedVAIs;

    /// @notice VAI Mint Rate as a percentage
    uint256 public vaiMintRate;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     */
    bool public mintVAIGuardianPaused;
    bool public repayVAIGuardianPaused;

    /**
     * @notice Pause/Unpause whole protocol actions
     */
    bool public protocolPaused;

    /// @notice The rate at which the flywheel distributes XVS to VAI Minters, per block (deprecated)
    uint256 private venusVAIRate;
}

contract ComptrollerV2Storage is ComptrollerV1Storage {
    /// @notice The rate at which the flywheel distributes XVS to VAI Vault, per block
    uint256 public venusVAIVaultRate;

    // address of VAI Vault
    address public vaiVaultAddress;

    // start block of release to VAI Vault
    uint256 public releaseStartBlock;

    // minimum release amount to VAI Vault
    uint256 public minReleaseAmount;
}

contract ComptrollerV3Storage is ComptrollerV2Storage {
    /// @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    address public borrowCapGuardian;

    /// @notice Borrow caps enforced by borrowAllowed for each vToken address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint256) public borrowCaps;
}

contract ComptrollerV4Storage is ComptrollerV3Storage {
    /// @notice Treasury Guardian address
    address public treasuryGuardian;

    /// @notice Treasury address
    address public treasuryAddress;

    /// @notice Fee percent of accrued interest with decimal 18
    uint256 public treasuryPercent;
}

contract ComptrollerV5Storage is ComptrollerV4Storage {
    /// @notice The portion of XVS that each contributor receives per block (deprecated)
    mapping(address => uint256) private venusContributorSpeeds;

    /// @notice Last block at which a contributor's XVS rewards have been allocated (deprecated)
    mapping(address => uint256) private lastContributorBlock;
}

contract ComptrollerV6Storage is ComptrollerV5Storage {
    address public liquidatorContract;
}

contract ComptrollerV7Storage is ComptrollerV6Storage {
    ComptrollerLensInterface public comptrollerLens;
}

contract ComptrollerV8Storage is ComptrollerV7Storage {
    /// @notice Supply caps enforced by mintAllowed for each vToken address. Defaults to zero which corresponds to minting notAllowed
    mapping(address => uint256) public supplyCaps;
}

contract ComptrollerV9Storage is ComptrollerV8Storage {
    /// @notice AccessControlManager address
    address internal accessControl;

    /// @notice True if a certain action is paused on a certain market
    mapping(address => mapping(uint256 => bool)) internal _actionPaused;
}

contract ComptrollerV10Storage is ComptrollerV9Storage {
    /// @notice The rate at which venus is distributed to the corresponding borrow market (per block)
    mapping(address => uint256) public venusBorrowSpeeds;

    /// @notice The rate at which venus is distributed to the corresponding supply market (per block)
    mapping(address => uint256) public venusSupplySpeeds;
}

contract ComptrollerV11Storage is ComptrollerV10Storage {
    /// @notice Whether the delegate is allowed to borrow or redeem on behalf of the user
    //mapping(address user => mapping (address delegate => bool approved)) public approvedDelegates;
    mapping(address => mapping(address => bool)) public approvedDelegates;
}

contract ComptrollerV12Storage is ComptrollerV11Storage {
    /// @notice Whether forced liquidation is enabled for all users borrowing in a certain market
    mapping(address => bool) public isForcedLiquidationEnabled;
}

contract ComptrollerV13Storage is ComptrollerV12Storage {
    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in _facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in _facetAddresses array
    }

    mapping(bytes4 => FacetAddressAndPosition) internal _selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) internal _facetFunctionSelectors;
    // facet addresses
    address[] internal _facetAddresses;
}

contract ComptrollerV14Storage is ComptrollerV13Storage {
    /// @notice Prime token address
    IPrime public prime;
}

contract ComptrollerV15Storage is ComptrollerV14Storage {
    /// @notice Whether forced liquidation is enabled for the borrows of a user in a market
    mapping(address /* user */ => mapping(address /* market */ => bool)) public isForcedLiquidationEnabledForUser;
}

contract ComptrollerV16Storage is ComptrollerV15Storage {
    /// @notice The XVS token contract address
    address internal xvs;

    /// @notice The XVS vToken contract address
    address internal xvsVToken;
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { Unitroller, ComptrollerV16Storage } from "../Unitroller.sol";

/**
 * @title Diamond
 * @author Venus
 * @notice This contract contains functions related to facets
 */
contract Diamond is IDiamondCut, ComptrollerV16Storage {
    /// @notice Emitted when functions are added, replaced or removed to facets
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut);

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Call _acceptImplementation to accept the diamond proxy as new implementaion
     * @param unitroller Address of the unitroller
     */
    function _become(Unitroller unitroller) public {
        require(msg.sender == unitroller.admin(), "only unitroller admin can");
        require(unitroller._acceptImplementation() == 0, "not authorized");
    }

    /**
     * @notice To add function selectors to the facet's mapping
     * @dev Allows the contract admin to add function selectors
     * @param diamondCut_ IDiamondCut contains facets address, action and function selectors
     */
    function diamondCut(IDiamondCut.FacetCut[] memory diamondCut_) public {
        require(msg.sender == admin, "only unitroller admin can");
        libDiamondCut(diamondCut_);
    }

    /**
     * @notice Get all function selectors mapped to the facet address
     * @param facet Address of the facet
     * @return selectors Array of function selectors
     */
    function facetFunctionSelectors(address facet) external view returns (bytes4[] memory) {
        return _facetFunctionSelectors[facet].functionSelectors;
    }

    /**
     * @notice Get facet position in the _facetFunctionSelectors through facet address
     * @param facet Address of the facet
     * @return Position of the facet
     */
    function facetPosition(address facet) external view returns (uint256) {
        return _facetFunctionSelectors[facet].facetAddressPosition;
    }

    /**
     * @notice Get all facet addresses
     * @return facetAddresses Array of facet addresses
     */
    function facetAddresses() external view returns (address[] memory) {
        return _facetAddresses;
    }

    /**
     * @notice Get facet address and position through function selector
     * @param functionSelector function selector
     * @return FacetAddressAndPosition facet address and position
     */
    function facetAddress(
        bytes4 functionSelector
    ) external view returns (ComptrollerV16Storage.FacetAddressAndPosition memory) {
        return _selectorToFacetAndPosition[functionSelector];
    }

    /**
     * @notice Get all facets address and their function selector
     * @return facets_ Array of Facet
     */
    function facets() external view returns (Facet[] memory) {
        uint256 facetsLength = _facetAddresses.length;
        Facet[] memory facets_ = new Facet[](facetsLength);
        for (uint256 i; i < facetsLength; ++i) {
            address facet = _facetAddresses[i];
            facets_[i].facetAddress = facet;
            facets_[i].functionSelectors = _facetFunctionSelectors[facet].functionSelectors;
        }
        return facets_;
    }

    /**
     * @notice To add function selectors to the facets' mapping
     * @param diamondCut_ IDiamondCut contains facets address, action and function selectors
     */
    function libDiamondCut(IDiamondCut.FacetCut[] memory diamondCut_) internal {
        uint256 diamondCutLength = diamondCut_.length;
        for (uint256 facetIndex; facetIndex < diamondCutLength; ++facetIndex) {
            IDiamondCut.FacetCutAction action = diamondCut_[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(diamondCut_[facetIndex].facetAddress, diamondCut_[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(diamondCut_[facetIndex].facetAddress, diamondCut_[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(diamondCut_[facetIndex].facetAddress, diamondCut_[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(diamondCut_);
    }

    /**
     * @notice Add function selectors to the facet's address mapping
     * @param facetAddress Address of the facet
     * @param functionSelectors Array of function selectors need to add in the mapping
     */
    function addFunctions(address facetAddress, bytes4[] memory functionSelectors) internal {
        require(functionSelectors.length != 0, "LibDiamondCut: No selectors in facet to cut");
        require(facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(_facetFunctionSelectors[facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(facetAddress);
        }
        uint256 functionSelectorsLength = functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; ++selectorIndex) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = _selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(selector, selectorPosition, facetAddress);
            ++selectorPosition;
        }
    }

    /**
     * @notice Replace facet's address mapping for function selectors i.e selectors already associate to any other existing facet
     * @param facetAddress Address of the facet
     * @param functionSelectors Array of function selectors need to replace in the mapping
     */
    function replaceFunctions(address facetAddress, bytes4[] memory functionSelectors) internal {
        require(functionSelectors.length != 0, "LibDiamondCut: No selectors in facet to cut");
        require(facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(_facetFunctionSelectors[facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(facetAddress);
        }
        uint256 functionSelectorsLength = functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; ++selectorIndex) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = _selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            addFunction(selector, selectorPosition, facetAddress);
            ++selectorPosition;
        }
    }

    /**
     * @notice Remove function selectors to the facet's address mapping
     * @param facetAddress Address of the facet
     * @param functionSelectors Array of function selectors need to remove in the mapping
     */
    function removeFunctions(address facetAddress, bytes4[] memory functionSelectors) internal {
        uint256 functionSelectorsLength = functionSelectors.length;
        require(functionSelectorsLength != 0, "LibDiamondCut: No selectors in facet to cut");
        // if function does not exist then do nothing and revert
        require(facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; ++selectorIndex) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = _selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    /**
     * @notice Add new facet to the proxy
     * @param facetAddress Address of the facet
     */
    function addFacet(address facetAddress) internal {
        enforceHasContractCode(facetAddress, "Diamond: New facet has no code");
        _facetFunctionSelectors[facetAddress].facetAddressPosition = _facetAddresses.length;
        _facetAddresses.push(facetAddress);
    }

    /**
     * @notice Add function selector to the facet's address mapping
     * @param selector funciton selector need to be added
     * @param selectorPosition funciton selector position
     * @param facetAddress Address of the facet
     */
    function addFunction(bytes4 selector, uint96 selectorPosition, address facetAddress) internal {
        _selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
        _facetFunctionSelectors[facetAddress].functionSelectors.push(selector);
        _selectorToFacetAndPosition[selector].facetAddress = facetAddress;
    }

    /**
     * @notice Remove function selector to the facet's address mapping
     * @param facetAddress Address of the facet
     * @param selector function selectors need to remove in the mapping
     */
    function removeFunction(address facetAddress, bytes4 selector) internal {
        require(facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");

        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = _selectorToFacetAndPosition[selector].functionSelectorPosition;
        uint256 lastSelectorPosition = _facetFunctionSelectors[facetAddress].functionSelectors.length - 1;
        // if not the same then replace selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = _facetFunctionSelectors[facetAddress].functionSelectors[lastSelectorPosition];
            _facetFunctionSelectors[facetAddress].functionSelectors[selectorPosition] = lastSelector;
            _selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        _facetFunctionSelectors[facetAddress].functionSelectors.pop();
        delete _selectorToFacetAndPosition[selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = _facetAddresses.length - 1;
            uint256 facetAddressPosition = _facetFunctionSelectors[facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = _facetAddresses[lastFacetAddressPosition];
                _facetAddresses[facetAddressPosition] = lastFacetAddress;
                _facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            _facetAddresses.pop();
            delete _facetFunctionSelectors[facetAddress];
        }
    }

    /**
     * @dev Ensure that the given address has contract code deployed
     * @param _contract The address to check for contract code
     * @param _errorMessage The error message to display if the contract code is not deployed
     */
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize != 0, _errorMessage);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    function() external payable {
        address facet = _selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute public function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./facets/MarketFacet.sol";
import "./facets/PolicyFacet.sol";
import "./facets/RewardFacet.sol";
import "./facets/SetterFacet.sol";
import "./Diamond.sol";

/**
 * @title DiamondConsolidated
 * @author Venus
 * @notice This contract contains the functions defined in the different facets of the Diamond, plus the getters to the public variables.
 * This contract cannot be deployed, due to its size. Its main purpose is to allow the easy generation of an ABI and the typechain to interact with the
 * Unitroller contract in a simple way
 */
contract DiamondConsolidated is Diamond, MarketFacet, PolicyFacet, RewardFacet, SetterFacet {}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;

import { VToken, ComptrollerErrorReporter, ExponentialNoError } from "../../../Tokens/VTokens/VToken.sol";
import { IVAIVault } from "../../../Comptroller/ComptrollerInterface.sol";
import { ComptrollerV16Storage } from "../../../Comptroller/ComptrollerStorage.sol";
import { IAccessControlManagerV5 } from "@venusprotocol/governance-contracts/contracts/Governance/IAccessControlManagerV5.sol";

import { SafeBEP20, IBEP20 } from "../../../Utils/SafeBEP20.sol";

/**
 * @title FacetBase
 * @author Venus
 * @notice This facet contract contains functions related to access and checks
 */
contract FacetBase is ComptrollerV16Storage, ExponentialNoError, ComptrollerErrorReporter {
    using SafeBEP20 for IBEP20;

    /// @notice The initial Venus index for a market
    uint224 public constant venusInitialIndex = 1e36;
    // closeFactorMantissa must be strictly greater than this value
    uint256 internal constant closeFactorMinMantissa = 0.05e18; // 0.05
    // closeFactorMantissa must not exceed this value
    uint256 internal constant closeFactorMaxMantissa = 0.9e18; // 0.9
    // No collateralFactorMantissa may exceed this value
    uint256 internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    /// @notice Emitted when an account enters a market
    event MarketEntered(VToken indexed vToken, address indexed account);

    /// @notice Emitted when XVS is distributed to VAI Vault
    event DistributedVAIVaultVenus(uint256 amount);

    /// @notice Reverts if the protocol is paused
    function checkProtocolPauseState() internal view {
        require(!protocolPaused, "protocol is paused");
    }

    /// @notice Reverts if a certain action is paused on a market
    function checkActionPauseState(address market, Action action) internal view {
        require(!actionPaused(market, action), "action is paused");
    }

    /// @notice Reverts if the caller is not admin
    function ensureAdmin() internal view {
        require(msg.sender == admin, "only admin can");
    }

    /// @notice Checks the passed address is nonzero
    function ensureNonzeroAddress(address someone) internal pure {
        require(someone != address(0), "can't be zero address");
    }

    /// @notice Reverts if the market is not listed
    function ensureListed(Market storage market) internal view {
        require(market.isListed, "market not listed");
    }

    /// @notice Reverts if the caller is neither admin nor the passed address
    function ensureAdminOr(address privilegedAddress) internal view {
        require(msg.sender == admin || msg.sender == privilegedAddress, "access denied");
    }

    /// @notice Checks the caller is allowed to call the specified fuction
    function ensureAllowed(string memory functionSig) internal view {
        require(IAccessControlManagerV5(accessControl).isAllowedToCall(msg.sender, functionSig), "access denied");
    }

    /**
     * @notice Checks if a certain action is paused on a market
     * @param action Action id
     * @param market vToken address
     */
    function actionPaused(address market, Action action) public view returns (bool) {
        return _actionPaused[market][uint256(action)];
    }

    /**
     * @notice Get the latest block number
     */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
     * @notice Get the latest block number with the safe32 check
     */
    function getBlockNumberAsUint32() internal view returns (uint32) {
        return safe32(getBlockNumber(), "block # > 32 bits");
    }

    /**
     * @notice Transfer XVS to VAI Vault
     */
    function releaseToVault() internal {
        if (releaseStartBlock == 0 || getBlockNumber() < releaseStartBlock) {
            return;
        }

        IBEP20 xvs_ = IBEP20(xvs);

        uint256 xvsBalance = xvs_.balanceOf(address(this));
        if (xvsBalance == 0) {
            return;
        }

        uint256 actualAmount;
        uint256 deltaBlocks = sub_(getBlockNumber(), releaseStartBlock);
        // releaseAmount = venusVAIVaultRate * deltaBlocks
        uint256 releaseAmount_ = mul_(venusVAIVaultRate, deltaBlocks);

        if (xvsBalance >= releaseAmount_) {
            actualAmount = releaseAmount_;
        } else {
            actualAmount = xvsBalance;
        }

        if (actualAmount < minReleaseAmount) {
            return;
        }

        releaseStartBlock = getBlockNumber();

        xvs_.safeTransfer(vaiVaultAddress, actualAmount);
        emit DistributedVAIVaultVenus(actualAmount);

        IVAIVault(vaiVaultAddress).updatePendingRewards();
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param vTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral vToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        VToken vTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) internal view returns (Error, uint256, uint256) {
        (uint256 err, uint256 liquidity, uint256 shortfall) = comptrollerLens.getHypotheticalAccountLiquidity(
            address(this),
            account,
            vTokenModify,
            redeemTokens,
            borrowAmount
        );
        return (Error(err), liquidity, shortfall);
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param vToken The market to enter
     * @param borrower The address of the account to modify
     * @return Success indicator for whether the market was entered
     */
    function addToMarketInternal(VToken vToken, address borrower) internal returns (Error) {
        checkActionPauseState(address(vToken), Action.ENTER_MARKET);
        Market storage marketToJoin = markets[address(vToken)];
        ensureListed(marketToJoin);
        if (marketToJoin.accountMembership[borrower]) {
            // already joined
            return Error.NO_ERROR;
        }
        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(vToken);

        emit MarketEntered(vToken, borrower);

        return Error.NO_ERROR;
    }

    /**
     * @notice Checks for the user is allowed to redeem tokens
     * @param vToken Address of the market
     * @param redeemer Address of the user
     * @param redeemTokens Amount of tokens to redeem
     * @return Success indicator for redeem is allowed or not
     */
    function redeemAllowedInternal(
        address vToken,
        address redeemer,
        uint256 redeemTokens
    ) internal view returns (uint256) {
        ensureListed(markets[vToken]);
        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[vToken].accountMembership[redeemer]) {
            return uint256(Error.NO_ERROR);
        }
        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
            redeemer,
            VToken(vToken),
            redeemTokens,
            0
        );
        if (err != Error.NO_ERROR) {
            return uint256(err);
        }
        if (shortfall != 0) {
            return uint256(Error.INSUFFICIENT_LIQUIDITY);
        }
        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Returns the XVS address
     * @return The address of XVS token
     */
    function getXVSAddress() external view returns (address) {
        return xvs;
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;

import { IMarketFacet } from "../interfaces/IMarketFacet.sol";
import { FacetBase } from "./FacetBase.sol";
import { VToken } from "../../../Tokens/VTokens/VToken.sol";

/**
 * @title MarketFacet
 * @author Venus
 * @dev This facet contains all the methods related to the market's management in the pool
 * @notice This facet contract contains functions regarding markets
 */
contract MarketFacet is IMarketFacet, FacetBase {
    /// @notice Emitted when an admin supports a market
    event MarketListed(VToken indexed vToken);

    /// @notice Emitted when an account exits a market
    event MarketExited(VToken indexed vToken, address indexed account);

    /// @notice Emitted when the borrowing or redeeming delegate rights are updated for an account
    event DelegateUpdated(address indexed approver, address indexed delegate, bool approved);

    /// @notice Indicator that this is a Comptroller contract (for inspection)
    function isComptroller() public pure returns (bool) {
        return true;
    }

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (VToken[] memory) {
        return accountAssets[account];
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market
     * @return The list of market addresses
     */
    function getAllMarkets() external view returns (VToken[] memory) {
        return allMarkets;
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in vToken.liquidateBorrowFresh)
     * @param vTokenBorrowed The address of the borrowed vToken
     * @param vTokenCollateral The address of the collateral vToken
     * @param actualRepayAmount The amount of vTokenBorrowed underlying to convert into vTokenCollateral tokens
     * @return (errorCode, number of vTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokens(
        address vTokenBorrowed,
        address vTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256, uint256) {
        (uint256 err, uint256 seizeTokens) = comptrollerLens.liquidateCalculateSeizeTokens(
            address(this),
            vTokenBorrowed,
            vTokenCollateral,
            actualRepayAmount
        );
        return (err, seizeTokens);
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in vToken.liquidateBorrowFresh)
     * @param vTokenCollateral The address of the collateral vToken
     * @param actualRepayAmount The amount of vTokenBorrowed underlying to convert into vTokenCollateral tokens
     * @return (errorCode, number of vTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateVAICalculateSeizeTokens(
        address vTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256, uint256) {
        (uint256 err, uint256 seizeTokens) = comptrollerLens.liquidateVAICalculateSeizeTokens(
            address(this),
            vTokenCollateral,
            actualRepayAmount
        );
        return (err, seizeTokens);
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param vToken The vToken to check
     * @return True if the account is in the asset, otherwise false
     */
    function checkMembership(address account, VToken vToken) external view returns (bool) {
        return markets[address(vToken)].accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param vTokens The list of addresses of the vToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] calldata vTokens) external returns (uint256[] memory) {
        uint256 len = vTokens.length;

        uint256[] memory results = new uint256[](len);
        for (uint256 i; i < len; ++i) {
            results[i] = uint256(addToMarketInternal(VToken(vTokens[i]), msg.sender));
        }

        return results;
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow
     * @param vTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address vTokenAddress) external returns (uint256) {
        checkActionPauseState(vTokenAddress, Action.EXIT_MARKET);

        VToken vToken = VToken(vTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the vToken */
        (uint256 oErr, uint256 tokensHeld, uint256 amountOwed, ) = vToken.getAccountSnapshot(msg.sender);
        require(oErr == 0, "getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

        /* Fail if the sender is not permitted to redeem all of their tokens */
        uint256 allowed = redeemAllowedInternal(vTokenAddress, msg.sender, tokensHeld);
        if (allowed != 0) {
            return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
        }

        Market storage marketToExit = markets[address(vToken)];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint256(Error.NO_ERROR);
        }

        /* Set vToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete vToken from the account’s list of assets */
        // In order to delete vToken, copy last item in list to location of item to be removed, reduce length by 1
        VToken[] storage userAssetList = accountAssets[msg.sender];
        uint256 len = userAssetList.length;
        uint256 i;
        for (; i < len; ++i) {
            if (userAssetList[i] == vToken) {
                userAssetList[i] = userAssetList[len - 1];
                userAssetList.length--;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(i < len);

        emit MarketExited(vToken, msg.sender);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Add the market to the markets mapping and set it as listed
     * @dev Allows a privileged role to add and list markets to the Comptroller
     * @param vToken The address of the market (token) to list
     * @return uint256 0=success, otherwise a failure. (See enum Error for details)
     */
    function _supportMarket(VToken vToken) external returns (uint256) {
        ensureAllowed("_supportMarket(address)");

        if (markets[address(vToken)].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        vToken.isVToken(); // Sanity check to make sure its really a VToken

        // Note that isVenus is not in active use anymore
        Market storage newMarket = markets[address(vToken)];
        newMarket.isListed = true;
        newMarket.isVenus = false;
        newMarket.collateralFactorMantissa = 0;

        _addMarketInternal(vToken);
        _initializeMarket(address(vToken));

        emit MarketListed(vToken);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Grants or revokes the borrowing or redeeming delegate rights to / from an account
     *  If allowed, the delegate will be able to borrow funds on behalf of the sender
     *  Upon a delegated borrow, the delegate will receive the funds, and the borrower
     *  will see the debt on their account
     *  Upon a delegated redeem, the delegate will receive the redeemed amount and the approver
     *  will see a deduction in his vToken balance
     * @param delegate The address to update the rights for
     * @param approved Whether to grant (true) or revoke (false) the borrowing or redeeming rights
     */
    function updateDelegate(address delegate, bool approved) external {
        ensureNonzeroAddress(delegate);
        require(approvedDelegates[msg.sender][delegate] != approved, "Delegation status unchanged");

        _updateDelegate(msg.sender, delegate, approved);
    }

    function _updateDelegate(address approver, address delegate, bool approved) internal {
        approvedDelegates[approver][delegate] = approved;
        emit DelegateUpdated(approver, delegate, approved);
    }

    function _addMarketInternal(VToken vToken) internal {
        uint256 allMarketsLength = allMarkets.length;
        for (uint256 i; i < allMarketsLength; ++i) {
            require(allMarkets[i] != vToken, "already added");
        }
        allMarkets.push(vToken);
    }

    function _initializeMarket(address vToken) internal {
        uint32 blockNumber = getBlockNumberAsUint32();

        VenusMarketState storage supplyState = venusSupplyState[vToken];
        VenusMarketState storage borrowState = venusBorrowState[vToken];

        /*
         * Update market state indices
         */
        if (supplyState.index == 0) {
            // Initialize supply state index with default value
            supplyState.index = venusInitialIndex;
        }

        if (borrowState.index == 0) {
            // Initialize borrow state index with default value
            borrowState.index = venusInitialIndex;
        }

        /*
         * Update market state block numbers
         */
        supplyState.block = borrowState.block = blockNumber;
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;

import { VToken } from "../../../Tokens/VTokens/VToken.sol";
import { IPolicyFacet } from "../interfaces/IPolicyFacet.sol";

import { XVSRewardsHelper } from "./XVSRewardsHelper.sol";

/**
 * @title PolicyFacet
 * @author Venus
 * @dev This facet contains all the hooks used while transferring the assets
 * @notice This facet contract contains all the external pre-hook functions related to vToken
 */
contract PolicyFacet is IPolicyFacet, XVSRewardsHelper {
    /// @notice Emitted when a new borrow-side XVS speed is calculated for a market
    event VenusBorrowSpeedUpdated(VToken indexed vToken, uint256 newSpeed);

    /// @notice Emitted when a new supply-side XVS speed is calculated for a market
    event VenusSupplySpeedUpdated(VToken indexed vToken, uint256 newSpeed);

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param vToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(address vToken, address minter, uint256 mintAmount) external returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        checkProtocolPauseState();
        checkActionPauseState(vToken, Action.MINT);
        ensureListed(markets[vToken]);

        uint256 supplyCap = supplyCaps[vToken];
        require(supplyCap != 0, "market supply cap is 0");

        uint256 vTokenSupply = VToken(vToken).totalSupply();
        Exp memory exchangeRate = Exp({ mantissa: VToken(vToken).exchangeRateStored() });
        uint256 nextTotalSupply = mul_ScalarTruncateAddUInt(exchangeRate, vTokenSupply, mintAmount);
        require(nextTotalSupply <= supplyCap, "market supply cap reached");

        // Keep the flywheel moving
        updateVenusSupplyIndex(vToken);
        distributeSupplierVenus(vToken, minter);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates mint, accrues interest and updates score in prime. Reverts on rejection. May emit logs.
     * @param vToken Asset being minted
     * @param minter The address minting the tokens
     * @param actualMintAmount The amount of the underlying asset being minted
     * @param mintTokens The number of tokens being minted
     */
    // solhint-disable-next-line no-unused-vars
    function mintVerify(address vToken, address minter, uint256 actualMintAmount, uint256 mintTokens) external {
        if (address(prime) != address(0)) {
            prime.accrueInterestAndUpdateScore(minter, vToken);
        }
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param vToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of vTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(address vToken, address redeemer, uint256 redeemTokens) external returns (uint256) {
        checkProtocolPauseState();
        checkActionPauseState(vToken, Action.REDEEM);

        uint256 allowed = redeemAllowedInternal(vToken, redeemer, redeemTokens);
        if (allowed != uint256(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateVenusSupplyIndex(vToken);
        distributeSupplierVenus(vToken, redeemer);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates redeem, accrues interest and updates score in prime. Reverts on rejection. May emit logs.
     * @param vToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(address vToken, address redeemer, uint256 redeemAmount, uint256 redeemTokens) external {
        require(redeemTokens != 0 || redeemAmount == 0, "redeemTokens zero");
        if (address(prime) != address(0)) {
            prime.accrueInterestAndUpdateScore(redeemer, vToken);
        }
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param vToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(address vToken, address borrower, uint256 borrowAmount) external returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        checkProtocolPauseState();
        checkActionPauseState(vToken, Action.BORROW);

        ensureListed(markets[vToken]);

        if (!markets[vToken].accountMembership[borrower]) {
            // only vTokens may call borrowAllowed if borrower not in market
            require(msg.sender == vToken, "sender must be vToken");

            // attempt to add borrower to the market
            Error err = addToMarketInternal(VToken(vToken), borrower);
            if (err != Error.NO_ERROR) {
                return uint256(err);
            }
        }

        if (oracle.getUnderlyingPrice(VToken(vToken)) == 0) {
            return uint256(Error.PRICE_ERROR);
        }

        uint256 borrowCap = borrowCaps[vToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint256 nextTotalBorrows = add_(VToken(vToken).totalBorrows(), borrowAmount);
            require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }

        (Error err, , uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
            borrower,
            VToken(vToken),
            0,
            borrowAmount
        );
        if (err != Error.NO_ERROR) {
            return uint256(err);
        }
        if (shortfall != 0) {
            return uint256(Error.INSUFFICIENT_LIQUIDITY);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({ mantissa: VToken(vToken).borrowIndex() });
        updateVenusBorrowIndex(vToken, borrowIndex);
        distributeBorrowerVenus(vToken, borrower, borrowIndex);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates borrow, accrues interest and updates score in prime. Reverts on rejection. May emit logs.
     * @param vToken Asset whose underlying is being borrowed
     * @param borrower The address borrowing the underlying
     * @param borrowAmount The amount of the underlying asset requested to borrow
     */
    // solhint-disable-next-line no-unused-vars
    function borrowVerify(address vToken, address borrower, uint256 borrowAmount) external {
        if (address(prime) != address(0)) {
            prime.accrueInterestAndUpdateScore(borrower, vToken);
        }
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param vToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address vToken,
        address payer, // solhint-disable-line no-unused-vars
        address borrower,
        uint256 repayAmount // solhint-disable-line no-unused-vars
    ) external returns (uint256) {
        checkProtocolPauseState();
        checkActionPauseState(vToken, Action.REPAY);
        ensureListed(markets[vToken]);

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({ mantissa: VToken(vToken).borrowIndex() });
        updateVenusBorrowIndex(vToken, borrowIndex);
        distributeBorrowerVenus(vToken, borrower, borrowIndex);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates repayBorrow, accrues interest and updates score in prime. Reverts on rejection. May emit logs.
     * @param vToken Asset being repaid
     * @param payer The address repaying the borrow
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function repayBorrowVerify(
        address vToken,
        address payer, // solhint-disable-line no-unused-vars
        address borrower,
        uint256 actualRepayAmount, // solhint-disable-line no-unused-vars
        uint256 borrowerIndex // solhint-disable-line no-unused-vars
    ) external {
        if (address(prime) != address(0)) {
            prime.accrueInterestAndUpdateScore(borrower, vToken);
        }
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param vTokenBorrowed Asset which was borrowed by the borrower
     * @param vTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external view returns (uint256) {
        checkProtocolPauseState();

        // if we want to pause liquidating to vTokenCollateral, we should pause seizing
        checkActionPauseState(vTokenBorrowed, Action.LIQUIDATE);

        if (liquidatorContract != address(0) && liquidator != liquidatorContract) {
            return uint256(Error.UNAUTHORIZED);
        }

        ensureListed(markets[vTokenCollateral]);

        uint256 borrowBalance;
        if (address(vTokenBorrowed) != address(vaiController)) {
            ensureListed(markets[vTokenBorrowed]);
            borrowBalance = VToken(vTokenBorrowed).borrowBalanceStored(borrower);
        } else {
            borrowBalance = vaiController.getVAIRepayAmount(borrower);
        }

        if (isForcedLiquidationEnabled[vTokenBorrowed] || isForcedLiquidationEnabledForUser[borrower][vTokenBorrowed]) {
            if (repayAmount > borrowBalance) {
                return uint(Error.TOO_MUCH_REPAY);
            }
            return uint(Error.NO_ERROR);
        }

        /* The borrower must have shortfall in order to be liquidatable */
        (Error err, , uint256 shortfall) = getHypotheticalAccountLiquidityInternal(borrower, VToken(address(0)), 0, 0);
        if (err != Error.NO_ERROR) {
            return uint256(err);
        }
        if (shortfall == 0) {
            return uint256(Error.INSUFFICIENT_SHORTFALL);
        }

        // The liquidator may not repay more than what is allowed by the closeFactor
        //-- maxClose = multipy of closeFactorMantissa and borrowBalance
        if (repayAmount > mul_ScalarTruncate(Exp({ mantissa: closeFactorMantissa }), borrowBalance)) {
            return uint256(Error.TOO_MUCH_REPAY);
        }

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates liquidateBorrow, accrues interest and updates score in prime. Reverts on rejection. May emit logs.
     * @param vTokenBorrowed Asset which was borrowed by the borrower
     * @param vTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     * @param seizeTokens The amount of collateral token that will be seized
     */
    function liquidateBorrowVerify(
        address vTokenBorrowed,
        address vTokenCollateral, // solhint-disable-line no-unused-vars
        address liquidator,
        address borrower,
        uint256 actualRepayAmount, // solhint-disable-line no-unused-vars
        uint256 seizeTokens // solhint-disable-line no-unused-vars
    ) external {
        if (address(prime) != address(0)) {
            prime.accrueInterestAndUpdateScore(borrower, vTokenBorrowed);
            prime.accrueInterestAndUpdateScore(liquidator, vTokenBorrowed);
        }
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param vTokenCollateral Asset which was used as collateral and will be seized
     * @param vTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens // solhint-disable-line no-unused-vars
    ) external returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        checkProtocolPauseState();
        checkActionPauseState(vTokenCollateral, Action.SEIZE);

        Market storage market = markets[vTokenCollateral];

        // We've added VAIController as a borrowed token list check for seize
        ensureListed(market);

        if (!market.accountMembership[borrower]) {
            return uint256(Error.MARKET_NOT_COLLATERAL);
        }

        if (address(vTokenBorrowed) != address(vaiController)) {
            ensureListed(markets[vTokenBorrowed]);
        }

        if (VToken(vTokenCollateral).comptroller() != VToken(vTokenBorrowed).comptroller()) {
            return uint256(Error.COMPTROLLER_MISMATCH);
        }

        // Keep the flywheel moving
        updateVenusSupplyIndex(vTokenCollateral);
        distributeSupplierVenus(vTokenCollateral, borrower);
        distributeSupplierVenus(vTokenCollateral, liquidator);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates seize, accrues interest and updates score in prime. Reverts on rejection. May emit logs.
     * @param vTokenCollateral Asset which was used as collateral and will be seized
     * @param vTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeVerify(
        address vTokenCollateral,
        address vTokenBorrowed, // solhint-disable-line no-unused-vars
        address liquidator,
        address borrower,
        uint256 seizeTokens // solhint-disable-line no-unused-vars
    ) external {
        if (address(prime) != address(0)) {
            prime.accrueInterestAndUpdateScore(borrower, vTokenCollateral);
            prime.accrueInterestAndUpdateScore(liquidator, vTokenCollateral);
        }
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param vToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of vTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(
        address vToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        checkProtocolPauseState();
        checkActionPauseState(vToken, Action.TRANSFER);

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint256 allowed = redeemAllowedInternal(vToken, src, transferTokens);
        if (allowed != uint256(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateVenusSupplyIndex(vToken);
        distributeSupplierVenus(vToken, src);
        distributeSupplierVenus(vToken, dst);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates transfer, accrues interest and updates score in prime. Reverts on rejection. May emit logs.
     * @param vToken Asset being transferred
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of vTokens to transfer
     */
    // solhint-disable-next-line no-unused-vars
    function transferVerify(address vToken, address src, address dst, uint256 transferTokens) external {
        if (address(prime) != address(0)) {
            prime.accrueInterestAndUpdateScore(src, vToken);
            prime.accrueInterestAndUpdateScore(dst, vToken);
        }
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256) {
        (Error err, uint256 liquidity, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
            account,
            VToken(address(0)),
            0,
            0
        );

        return (uint256(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param vTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address vTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) external view returns (uint256, uint256, uint256) {
        (Error err, uint256 liquidity, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
            account,
            VToken(vTokenModify),
            redeemTokens,
            borrowAmount
        );
        return (uint256(err), liquidity, shortfall);
    }

    // setter functionality
    /**
     * @notice Set XVS speed for a single market
     * @dev Allows the contract admin to set XVS speed for a market
     * @param vTokens The market whose XVS speed to update
     * @param supplySpeeds New XVS speed for supply
     * @param borrowSpeeds New XVS speed for borrow
     */
    function _setVenusSpeeds(
        VToken[] calldata vTokens,
        uint256[] calldata supplySpeeds,
        uint256[] calldata borrowSpeeds
    ) external {
        ensureAdmin();

        uint256 numTokens = vTokens.length;
        require(numTokens == supplySpeeds.length && numTokens == borrowSpeeds.length, "invalid input");

        for (uint256 i; i < numTokens; ++i) {
            ensureNonzeroAddress(address(vTokens[i]));
            setVenusSpeedInternal(vTokens[i], supplySpeeds[i], borrowSpeeds[i]);
        }
    }

    function setVenusSpeedInternal(VToken vToken, uint256 supplySpeed, uint256 borrowSpeed) internal {
        ensureListed(markets[address(vToken)]);

        if (venusSupplySpeeds[address(vToken)] != supplySpeed) {
            // Supply speed updated so let's update supply state to ensure that
            //  1. XVS accrued properly for the old speed, and
            //  2. XVS accrued at the new speed starts after this block.

            updateVenusSupplyIndex(address(vToken));
            // Update speed and emit event
            venusSupplySpeeds[address(vToken)] = supplySpeed;
            emit VenusSupplySpeedUpdated(vToken, supplySpeed);
        }

        if (venusBorrowSpeeds[address(vToken)] != borrowSpeed) {
            // Borrow speed updated so let's update borrow state to ensure that
            //  1. XVS accrued properly for the old speed, and
            //  2. XVS accrued at the new speed starts after this block.
            Exp memory borrowIndex = Exp({ mantissa: vToken.borrowIndex() });
            updateVenusBorrowIndex(address(vToken), borrowIndex);

            // Update speed and emit event
            venusBorrowSpeeds[address(vToken)] = borrowSpeed;
            emit VenusBorrowSpeedUpdated(vToken, borrowSpeed);
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;

import { VToken } from "../../../Tokens/VTokens/VToken.sol";
import { IRewardFacet } from "../interfaces/IRewardFacet.sol";
import { XVSRewardsHelper } from "./XVSRewardsHelper.sol";
import { SafeBEP20, IBEP20 } from "../../../Utils/SafeBEP20.sol";
import { VBep20Interface } from "../../../Tokens/VTokens/VTokenInterfaces.sol";

/**
 * @title RewardFacet
 * @author Venus
 * @dev This facet contains all the methods related to the reward functionality
 * @notice This facet contract provides the external functions related to all claims and rewards of the protocol
 */
contract RewardFacet is IRewardFacet, XVSRewardsHelper {
    /// @notice Emitted when Venus is granted by admin
    event VenusGranted(address indexed recipient, uint256 amount);

    /// @notice Emitted when XVS are seized for the holder
    event VenusSeized(address indexed holder, uint256 amount);

    using SafeBEP20 for IBEP20;

    /**
     * @notice Claim all the xvs accrued by holder in all markets and VAI
     * @param holder The address to claim XVS for
     */
    function claimVenus(address holder) public {
        return claimVenus(holder, allMarkets);
    }

    /**
     * @notice Claim all the xvs accrued by holder in the specified markets
     * @param holder The address to claim XVS for
     * @param vTokens The list of markets to claim XVS in
     */
    function claimVenus(address holder, VToken[] memory vTokens) public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimVenus(holders, vTokens, true, true);
    }

    /**
     * @notice Claim all xvs accrued by the holders
     * @param holders The addresses to claim XVS for
     * @param vTokens The list of markets to claim XVS in
     * @param borrowers Whether or not to claim XVS earned by borrowing
     * @param suppliers Whether or not to claim XVS earned by supplying
     */
    function claimVenus(address[] memory holders, VToken[] memory vTokens, bool borrowers, bool suppliers) public {
        claimVenus(holders, vTokens, borrowers, suppliers, false);
    }

    /**
     * @notice Claim all the xvs accrued by holder in all markets, a shorthand for `claimVenus` with collateral set to `true`
     * @param holder The address to claim XVS for
     */
    function claimVenusAsCollateral(address holder) external {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimVenus(holders, allMarkets, true, true, true);
    }

    /**
     * @notice Transfer XVS to the user with user's shortfall considered
     * @dev Note: If there is not enough XVS, we do not perform the transfer all
     * @param user The address of the user to transfer XVS to
     * @param amount The amount of XVS to (possibly) transfer
     * @param shortfall The shortfall of the user
     * @param collateral Whether or not we will use user's venus reward as collateral to pay off the debt
     * @return The amount of XVS which was NOT transferred to the user
     */
    function grantXVSInternal(
        address user,
        uint256 amount,
        uint256 shortfall,
        bool collateral
    ) internal returns (uint256) {
        // If the user is blacklisted, they can't get XVS rewards
        require(
            user != 0xEF044206Db68E40520BfA82D45419d498b4bc7Bf &&
                user != 0x7589dD3355DAE848FDbF75044A3495351655cB1A &&
                user != 0x33df7a7F6D44307E1e5F3B15975b47515e5524c0 &&
                user != 0x24e77E5b74B30b026E9996e4bc3329c881e24968,
            "Blacklisted"
        );

        IBEP20 xvs_ = IBEP20(xvs);

        if (amount == 0 || amount > xvs_.balanceOf(address(this))) {
            return amount;
        }

        if (shortfall == 0) {
            xvs_.safeTransfer(user, amount);
            return 0;
        }
        // If user's bankrupt and doesn't use pending xvs as collateral, don't grant
        // anything, otherwise, we will transfer the pending xvs as collateral to
        // vXVS token and mint vXVS for the user
        //
        // If mintBehalf failed, don't grant any xvs
        require(collateral, "bankrupt");

        address xvsVToken_ = xvsVToken;

        xvs_.safeApprove(xvsVToken_, 0);
        xvs_.safeApprove(xvsVToken_, amount);
        require(VBep20Interface(xvsVToken_).mintBehalf(user, amount) == uint256(Error.NO_ERROR), "mint behalf error");

        // set venusAccrued[user] to 0
        return 0;
    }

    /*** Venus Distribution Admin ***/

    /**
     * @notice Transfer XVS to the recipient
     * @dev Allows the contract admin to transfer XVS to any recipient based on the recipient's shortfall
     *      Note: If there is not enough XVS, we do not perform the transfer all
     * @param recipient The address of the recipient to transfer XVS to
     * @param amount The amount of XVS to (possibly) transfer
     */
    function _grantXVS(address recipient, uint256 amount) external {
        ensureAdmin();
        uint256 amountLeft = grantXVSInternal(recipient, amount, 0, false);
        require(amountLeft == 0, "no xvs");
        emit VenusGranted(recipient, amount);
    }

    /**
     * @dev Seize XVS tokens from the specified holders and transfer to recipient
     * @notice Seize XVS rewards allocated to holders
     * @param holders Addresses of the XVS holders
     * @param recipient Address of the XVS token recipient
     * @return The total amount of XVS tokens seized and transferred to recipient
     */
    function seizeVenus(address[] calldata holders, address recipient) external returns (uint256) {
        ensureAllowed("seizeVenus(address[],address)");

        uint256 holdersLength = holders.length;
        uint256 totalHoldings;

        updateAndDistributeRewardsInternal(holders, allMarkets, true, true);
        for (uint256 j; j < holdersLength; ++j) {
            address holder = holders[j];
            uint256 userHolding = venusAccrued[holder];

            if (userHolding != 0) {
                totalHoldings += userHolding;
                delete venusAccrued[holder];
            }

            emit VenusSeized(holder, userHolding);
        }

        if (totalHoldings != 0) {
            IBEP20(xvs).safeTransfer(recipient, totalHoldings);
            emit VenusGranted(recipient, totalHoldings);
        }

        return totalHoldings;
    }

    /**
     * @notice Claim all xvs accrued by the holders
     * @param holders The addresses to claim XVS for
     * @param vTokens The list of markets to claim XVS in
     * @param borrowers Whether or not to claim XVS earned by borrowing
     * @param suppliers Whether or not to claim XVS earned by supplying
     * @param collateral Whether or not to use XVS earned as collateral, only takes effect when the holder has a shortfall
     */
    function claimVenus(
        address[] memory holders,
        VToken[] memory vTokens,
        bool borrowers,
        bool suppliers,
        bool collateral
    ) public {
        uint256 holdersLength = holders.length;

        updateAndDistributeRewardsInternal(holders, vTokens, borrowers, suppliers);
        for (uint256 j; j < holdersLength; ++j) {
            address holder = holders[j];

            // If there is a positive shortfall, the XVS reward is accrued,
            // but won't be granted to this holder
            (, , uint256 shortfall) = getHypotheticalAccountLiquidityInternal(holder, VToken(address(0)), 0, 0);

            uint256 value = venusAccrued[holder];
            delete venusAccrued[holder];

            uint256 returnAmount = grantXVSInternal(holder, value, shortfall, collateral);

            // returnAmount can only be positive if balance of xvsAddress is less than grant amount(venusAccrued[holder])
            if (returnAmount != 0) {
                venusAccrued[holder] = returnAmount;
            }
        }
    }

    /**
     * @notice Update and distribute tokens
     * @param holders The addresses to claim XVS for
     * @param vTokens The list of markets to claim XVS in
     * @param borrowers Whether or not to claim XVS earned by borrowing
     * @param suppliers Whether or not to claim XVS earned by supplying
     */
    function updateAndDistributeRewardsInternal(
        address[] memory holders,
        VToken[] memory vTokens,
        bool borrowers,
        bool suppliers
    ) internal {
        uint256 j;
        uint256 holdersLength = holders.length;
        uint256 vTokensLength = vTokens.length;

        for (uint256 i; i < vTokensLength; ++i) {
            VToken vToken = vTokens[i];
            ensureListed(markets[address(vToken)]);
            if (borrowers) {
                Exp memory borrowIndex = Exp({ mantissa: vToken.borrowIndex() });
                updateVenusBorrowIndex(address(vToken), borrowIndex);
                for (j = 0; j < holdersLength; ++j) {
                    distributeBorrowerVenus(address(vToken), holders[j], borrowIndex);
                }
            }

            if (suppliers) {
                updateVenusSupplyIndex(address(vToken));
                for (j = 0; j < holdersLength; ++j) {
                    distributeSupplierVenus(address(vToken), holders[j]);
                }
            }
        }
    }

    /**
     * @notice Returns the XVS vToken address
     * @return The address of XVS vToken
     */
    function getXVSVTokenAddress() external view returns (address) {
        return xvsVToken;
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;

import { VToken } from "../../../Tokens/VTokens/VToken.sol";
import { ISetterFacet } from "../interfaces/ISetterFacet.sol";
import { PriceOracle } from "../../../Oracle/PriceOracle.sol";
import { ComptrollerLensInterface } from "../../ComptrollerLensInterface.sol";
import { VAIControllerInterface } from "../../../Tokens/VAI/VAIControllerInterface.sol";
import { FacetBase } from "./FacetBase.sol";
import { IPrime } from "../../../Tokens/Prime/IPrime.sol";

/**
 * @title SetterFacet
 * @author Venus
 * @dev This facet contains all the setters for the states
 * @notice This facet contract contains all the configurational setter functions
 */
contract SetterFacet is ISetterFacet, FacetBase {
    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint256 oldCloseFactorMantissa, uint256 newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(
        VToken indexed vToken,
        uint256 oldCollateralFactorMantissa,
        uint256 newCollateralFactorMantissa
    );

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint256 oldLiquidationIncentiveMantissa, uint256 newLiquidationIncentiveMantissa);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when borrow cap for a vToken is changed
    event NewBorrowCap(VToken indexed vToken, uint256 newBorrowCap);

    /// @notice Emitted when VAIController is changed
    event NewVAIController(VAIControllerInterface oldVAIController, VAIControllerInterface newVAIController);

    /// @notice Emitted when VAI mint rate is changed by admin
    event NewVAIMintRate(uint256 oldVAIMintRate, uint256 newVAIMintRate);

    /// @notice Emitted when protocol state is changed by admin
    event ActionProtocolPaused(bool state);

    /// @notice Emitted when treasury guardian is changed
    event NewTreasuryGuardian(address oldTreasuryGuardian, address newTreasuryGuardian);

    /// @notice Emitted when treasury address is changed
    event NewTreasuryAddress(address oldTreasuryAddress, address newTreasuryAddress);

    /// @notice Emitted when treasury percent is changed
    event NewTreasuryPercent(uint256 oldTreasuryPercent, uint256 newTreasuryPercent);

    /// @notice Emitted when liquidator adress is changed
    event NewLiquidatorContract(address oldLiquidatorContract, address newLiquidatorContract);

    /// @notice Emitted when ComptrollerLens address is changed
    event NewComptrollerLens(address oldComptrollerLens, address newComptrollerLens);

    /// @notice Emitted when supply cap for a vToken is changed
    event NewSupplyCap(VToken indexed vToken, uint256 newSupplyCap);

    /// @notice Emitted when access control address is changed by admin
    event NewAccessControl(address oldAccessControlAddress, address newAccessControlAddress);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused on a market
    event ActionPausedMarket(VToken indexed vToken, Action indexed action, bool pauseState);

    /// @notice Emitted when VAI Vault info is changed
    event NewVAIVaultInfo(address indexed vault_, uint256 releaseStartBlock_, uint256 releaseInterval_);

    /// @notice Emitted when Venus VAI Vault rate is changed
    event NewVenusVAIVaultRate(uint256 oldVenusVAIVaultRate, uint256 newVenusVAIVaultRate);

    /// @notice Emitted when prime token contract address is changed
    event NewPrimeToken(IPrime oldPrimeToken, IPrime newPrimeToken);

    /// @notice Emitted when forced liquidation is enabled or disabled for all users in a market
    event IsForcedLiquidationEnabledUpdated(address indexed vToken, bool enable);

    /// @notice Emitted when forced liquidation is enabled or disabled for a user borrowing in a market
    event IsForcedLiquidationEnabledForUserUpdated(address indexed borrower, address indexed vToken, bool enable);

    /// @notice Emitted when XVS token address is changed
    event NewXVSToken(address indexed oldXVS, address indexed newXVS);

    /// @notice Emitted when XVS vToken address is changed
    event NewXVSVToken(address indexed oldXVSVToken, address indexed newXVSVToken);

    /**
     * @notice Compare two addresses to ensure they are different
     * @param oldAddress The original address to compare
     * @param newAddress The new address to compare
     */
    modifier compareAddress(address oldAddress, address newAddress) {
        require(oldAddress != newAddress, "old address is same as new address");
        _;
    }

    /**
     * @notice Compare two values to ensure they are different
     * @param oldValue The original value to compare
     * @param newValue The new value to compare
     */
    modifier compareValue(uint256 oldValue, uint256 newValue) {
        require(oldValue != newValue, "old value is same as new value");
        _;
    }

    /**
     * @notice Sets a new price oracle for the comptroller
     * @dev Allows the contract admin to set a new price oracle used by the Comptroller
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPriceOracle(
        PriceOracle newOracle
    ) external compareAddress(address(oracle), address(newOracle)) returns (uint256) {
        // Check caller is admin
        ensureAdmin();
        ensureNonzeroAddress(address(newOracle));

        // Track the old oracle for the comptroller
        PriceOracle oldOracle = oracle;

        // Set comptroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets the closeFactor used when liquidating borrows
     * @dev Allows the contract admin to set the closeFactor used to liquidate borrows
     * @param newCloseFactorMantissa New close factor, scaled by 1e18
     * @return uint256 0=success, otherwise will revert
     */
    function _setCloseFactor(
        uint256 newCloseFactorMantissa
    ) external compareValue(closeFactorMantissa, newCloseFactorMantissa) returns (uint256) {
        // Check caller is admin
        ensureAdmin();

        Exp memory newCloseFactorExp = Exp({ mantissa: newCloseFactorMantissa });

        //-- Check close factor <= 0.9
        Exp memory highLimit = Exp({ mantissa: closeFactorMaxMantissa });
        //-- Check close factor >= 0.05
        Exp memory lowLimit = Exp({ mantissa: closeFactorMinMantissa });

        if (lessThanExp(highLimit, newCloseFactorExp) || greaterThanExp(lowLimit, newCloseFactorExp)) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        uint256 oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, newCloseFactorMantissa);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets the address of the access control of this contract
     * @dev Allows the contract admin to set the address of access control of this contract
     * @param newAccessControlAddress New address for the access control
     * @return uint256 0=success, otherwise will revert
     */
    function _setAccessControl(
        address newAccessControlAddress
    ) external compareAddress(accessControl, newAccessControlAddress) returns (uint256) {
        // Check caller is admin
        ensureAdmin();
        ensureNonzeroAddress(newAccessControlAddress);

        address oldAccessControlAddress = accessControl;

        accessControl = newAccessControlAddress;
        emit NewAccessControl(oldAccessControlAddress, newAccessControlAddress);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets the collateralFactor for a market
     * @dev Allows a privileged role to set the collateralFactorMantissa
     * @param vToken The market to set the factor on
     * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
     * @return uint256 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setCollateralFactor(
        VToken vToken,
        uint256 newCollateralFactorMantissa
    )
        external
        compareValue(markets[address(vToken)].collateralFactorMantissa, newCollateralFactorMantissa)
        returns (uint256)
    {
        // Check caller is allowed by access control manager
        ensureAllowed("_setCollateralFactor(address,uint256)");
        ensureNonzeroAddress(address(vToken));

        // Verify market is listed
        Market storage market = markets[address(vToken)];
        ensureListed(market);

        Exp memory newCollateralFactorExp = Exp({ mantissa: newCollateralFactorMantissa });

        //-- Check collateral factor <= 0.9
        Exp memory highLimit = Exp({ mantissa: collateralFactorMaxMantissa });
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }

        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(vToken) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint256 oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(vToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets liquidationIncentive
     * @dev Allows a privileged role to set the liquidationIncentiveMantissa
     * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
     * @return uint256 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setLiquidationIncentive(
        uint256 newLiquidationIncentiveMantissa
    ) external compareValue(liquidationIncentiveMantissa, newLiquidationIncentiveMantissa) returns (uint256) {
        ensureAllowed("_setLiquidationIncentive(uint256)");

        require(newLiquidationIncentiveMantissa >= 1e18, "incentive < 1e18");

        // Save current value for use in log
        uint256 oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;
        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Update the address of the liquidator contract
     * @dev Allows the contract admin to update the address of liquidator contract
     * @param newLiquidatorContract_ The new address of the liquidator contract
     */
    function _setLiquidatorContract(
        address newLiquidatorContract_
    ) external compareAddress(liquidatorContract, newLiquidatorContract_) {
        // Check caller is admin
        ensureAdmin();
        ensureNonzeroAddress(newLiquidatorContract_);
        address oldLiquidatorContract = liquidatorContract;
        liquidatorContract = newLiquidatorContract_;
        emit NewLiquidatorContract(oldLiquidatorContract, newLiquidatorContract_);
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @dev Allows the contract admin to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint256 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(
        address newPauseGuardian
    ) external compareAddress(pauseGuardian, newPauseGuardian) returns (uint256) {
        ensureAdmin();
        ensureNonzeroAddress(newPauseGuardian);

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;
        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, newPauseGuardian);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Set the given borrow caps for the given vToken market Borrowing that brings total borrows to or above borrow cap will revert
     * @dev Allows a privileged role to set the borrowing cap for a vToken market. A borrow cap of 0 corresponds to unlimited borrowing
     * @param vTokens The addresses of the markets (tokens) to change the borrow caps for
     * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing
     */
    function _setMarketBorrowCaps(VToken[] calldata vTokens, uint256[] calldata newBorrowCaps) external {
        ensureAllowed("_setMarketBorrowCaps(address[],uint256[])");

        uint256 numMarkets = vTokens.length;
        uint256 numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, "invalid input");

        for (uint256 i; i < numMarkets; ++i) {
            borrowCaps[address(vTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(vTokens[i], newBorrowCaps[i]);
        }
    }

    /**
     * @notice Set the given supply caps for the given vToken market Supply that brings total Supply to or above supply cap will revert
     * @dev Allows a privileged role to set the supply cap for a vToken. A supply cap of 0 corresponds to Minting NotAllowed
     * @param vTokens The addresses of the markets (tokens) to change the supply caps for
     * @param newSupplyCaps The new supply cap values in underlying to be set. A value of 0 corresponds to Minting NotAllowed
     */
    function _setMarketSupplyCaps(VToken[] calldata vTokens, uint256[] calldata newSupplyCaps) external {
        ensureAllowed("_setMarketSupplyCaps(address[],uint256[])");

        uint256 numMarkets = vTokens.length;
        uint256 numSupplyCaps = newSupplyCaps.length;

        require(numMarkets != 0 && numMarkets == numSupplyCaps, "invalid input");

        for (uint256 i; i < numMarkets; ++i) {
            supplyCaps[address(vTokens[i])] = newSupplyCaps[i];
            emit NewSupplyCap(vTokens[i], newSupplyCaps[i]);
        }
    }

    /**
     * @notice Set whole protocol pause/unpause state
     * @dev Allows a privileged role to pause/unpause protocol
     * @param state The new state (true=paused, false=unpaused)
     * @return bool The updated state of the protocol
     */
    function _setProtocolPaused(bool state) external returns (bool) {
        ensureAllowed("_setProtocolPaused(bool)");

        protocolPaused = state;
        emit ActionProtocolPaused(state);
        return state;
    }

    /**
     * @notice Pause/unpause certain actions
     * @dev Allows a privileged role to pause/unpause the protocol action state
     * @param markets_ Markets to pause/unpause the actions on
     * @param actions_ List of action ids to pause/unpause
     * @param paused_ The new paused state (true=paused, false=unpaused)
     */
    function _setActionsPaused(address[] calldata markets_, Action[] calldata actions_, bool paused_) external {
        ensureAllowed("_setActionsPaused(address[],uint8[],bool)");

        uint256 numMarkets = markets_.length;
        uint256 numActions = actions_.length;
        for (uint256 marketIdx; marketIdx < numMarkets; ++marketIdx) {
            for (uint256 actionIdx; actionIdx < numActions; ++actionIdx) {
                setActionPausedInternal(markets_[marketIdx], actions_[actionIdx], paused_);
            }
        }
    }

    /**
     * @dev Pause/unpause an action on a market
     * @param market Market to pause/unpause the action on
     * @param action Action id to pause/unpause
     * @param paused The new paused state (true=paused, false=unpaused)
     */
    function setActionPausedInternal(address market, Action action, bool paused) internal {
        ensureListed(markets[market]);
        _actionPaused[market][uint256(action)] = paused;
        emit ActionPausedMarket(VToken(market), action, paused);
    }

    /**
     * @notice Sets a new VAI controller
     * @dev Admin function to set a new VAI controller
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setVAIController(
        VAIControllerInterface vaiController_
    ) external compareAddress(address(vaiController), address(vaiController_)) returns (uint256) {
        // Check caller is admin
        ensureAdmin();
        ensureNonzeroAddress(address(vaiController_));

        VAIControllerInterface oldVaiController = vaiController;
        vaiController = vaiController_;
        emit NewVAIController(oldVaiController, vaiController_);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Set the VAI mint rate
     * @param newVAIMintRate The new VAI mint rate to be set
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setVAIMintRate(
        uint256 newVAIMintRate
    ) external compareValue(vaiMintRate, newVAIMintRate) returns (uint256) {
        // Check caller is admin
        ensureAdmin();
        uint256 oldVAIMintRate = vaiMintRate;
        vaiMintRate = newVAIMintRate;
        emit NewVAIMintRate(oldVAIMintRate, newVAIMintRate);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Set the minted VAI amount of the `owner`
     * @param owner The address of the account to set
     * @param amount The amount of VAI to set to the account
     * @return The number of minted VAI by `owner`
     */
    function setMintedVAIOf(address owner, uint256 amount) external returns (uint256) {
        checkProtocolPauseState();

        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintVAIGuardianPaused && !repayVAIGuardianPaused, "VAI is paused");
        // Check caller is vaiController
        if (msg.sender != address(vaiController)) {
            return fail(Error.REJECTION, FailureInfo.SET_MINTED_VAI_REJECTION);
        }
        mintedVAIs[owner] = amount;
        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Set the treasury data.
     * @param newTreasuryGuardian The new address of the treasury guardian to be set
     * @param newTreasuryAddress The new address of the treasury to be set
     * @param newTreasuryPercent The new treasury percent to be set
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setTreasuryData(
        address newTreasuryGuardian,
        address newTreasuryAddress,
        uint256 newTreasuryPercent
    ) external returns (uint256) {
        // Check caller is admin
        ensureAdminOr(treasuryGuardian);

        require(newTreasuryPercent < 1e18, "percent >= 100%");
        ensureNonzeroAddress(newTreasuryGuardian);
        ensureNonzeroAddress(newTreasuryAddress);

        address oldTreasuryGuardian = treasuryGuardian;
        address oldTreasuryAddress = treasuryAddress;
        uint256 oldTreasuryPercent = treasuryPercent;

        treasuryGuardian = newTreasuryGuardian;
        treasuryAddress = newTreasuryAddress;
        treasuryPercent = newTreasuryPercent;

        emit NewTreasuryGuardian(oldTreasuryGuardian, newTreasuryGuardian);
        emit NewTreasuryAddress(oldTreasuryAddress, newTreasuryAddress);
        emit NewTreasuryPercent(oldTreasuryPercent, newTreasuryPercent);

        return uint256(Error.NO_ERROR);
    }

    /*** Venus Distribution ***/

    /**
     * @dev Set ComptrollerLens contract address
     * @param comptrollerLens_ The new ComptrollerLens contract address to be set
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setComptrollerLens(
        ComptrollerLensInterface comptrollerLens_
    ) external compareAddress(address(comptrollerLens), address(comptrollerLens_)) returns (uint256) {
        ensureAdmin();
        ensureNonzeroAddress(address(comptrollerLens_));
        address oldComptrollerLens = address(comptrollerLens);
        comptrollerLens = comptrollerLens_;
        emit NewComptrollerLens(oldComptrollerLens, address(comptrollerLens));

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Set the amount of XVS distributed per block to VAI Vault
     * @param venusVAIVaultRate_ The amount of XVS wei per block to distribute to VAI Vault
     */
    function _setVenusVAIVaultRate(
        uint256 venusVAIVaultRate_
    ) external compareValue(venusVAIVaultRate, venusVAIVaultRate_) {
        ensureAdmin();
        if (vaiVaultAddress != address(0)) {
            releaseToVault();
        }
        uint256 oldVenusVAIVaultRate = venusVAIVaultRate;
        venusVAIVaultRate = venusVAIVaultRate_;
        emit NewVenusVAIVaultRate(oldVenusVAIVaultRate, venusVAIVaultRate_);
    }

    /**
     * @notice Set the VAI Vault infos
     * @param vault_ The address of the VAI Vault
     * @param releaseStartBlock_ The start block of release to VAI Vault
     * @param minReleaseAmount_ The minimum release amount to VAI Vault
     */
    function _setVAIVaultInfo(
        address vault_,
        uint256 releaseStartBlock_,
        uint256 minReleaseAmount_
    ) external compareAddress(vaiVaultAddress, vault_) {
        ensureAdmin();
        ensureNonzeroAddress(vault_);
        if (vaiVaultAddress != address(0)) {
            releaseToVault();
        }

        vaiVaultAddress = vault_;
        releaseStartBlock = releaseStartBlock_;
        minReleaseAmount = minReleaseAmount_;
        emit NewVAIVaultInfo(vault_, releaseStartBlock_, minReleaseAmount_);
    }

    /**
     * @notice Sets the prime token contract for the comptroller
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPrimeToken(IPrime _prime) external returns (uint) {
        ensureAdmin();
        ensureNonzeroAddress(address(_prime));

        IPrime oldPrime = prime;
        prime = _prime;
        emit NewPrimeToken(oldPrime, _prime);

        return uint(Error.NO_ERROR);
    }

    /** @notice Enables forced liquidations for a market. If forced liquidation is enabled,
     * borrows in the market may be liquidated regardless of the account liquidity
     * @dev Allows a privileged role to set enable/disable forced liquidations
     * @param vTokenBorrowed Borrowed vToken
     * @param enable Whether to enable forced liquidations
     */
    function _setForcedLiquidation(address vTokenBorrowed, bool enable) external {
        ensureAllowed("_setForcedLiquidation(address,bool)");
        if (vTokenBorrowed != address(vaiController)) {
            ensureListed(markets[vTokenBorrowed]);
        }
        isForcedLiquidationEnabled[vTokenBorrowed] = enable;
        emit IsForcedLiquidationEnabledUpdated(vTokenBorrowed, enable);
    }

    /**
     * @notice Enables forced liquidations for user's borrows in a certain market. If forced
     * liquidation is enabled, user's borrows in the market may be liquidated regardless of
     * the account liquidity. Forced liquidation may be enabled for a user even if it is not
     * enabled for the entire market.
     * @param borrower The address of the borrower
     * @param vTokenBorrowed Borrowed vToken
     * @param enable Whether to enable forced liquidations
     */
    function _setForcedLiquidationForUser(address borrower, address vTokenBorrowed, bool enable) external {
        ensureAllowed("_setForcedLiquidationForUser(address,address,bool)");
        if (vTokenBorrowed != address(vaiController)) {
            ensureListed(markets[vTokenBorrowed]);
        }
        isForcedLiquidationEnabledForUser[borrower][vTokenBorrowed] = enable;
        emit IsForcedLiquidationEnabledForUserUpdated(borrower, vTokenBorrowed, enable);
    }

    /**
     * @notice Set the address of the XVS token
     * @param xvs_ The address of the XVS token
     */
    function _setXVSToken(address xvs_) external {
        ensureAdmin();
        ensureNonzeroAddress(xvs_);

        emit NewXVSToken(xvs, xvs_);
        xvs = xvs_;
    }

    /**
     * @notice Set the address of the XVS vToken
     * @param xvsVToken_ The address of the XVS vToken
     */
    function _setXVSVToken(address xvsVToken_) external {
        ensureAdmin();
        ensureNonzeroAddress(xvsVToken_);

        address underlying = VToken(xvsVToken_).underlying();
        require(underlying == xvs, "invalid xvs vtoken address");

        emit NewXVSVToken(xvsVToken, xvsVToken_);
        xvsVToken = xvsVToken_;
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;

import { VToken } from "../../../Tokens/VTokens/VToken.sol";
import { FacetBase } from "./FacetBase.sol";

/**
 * @title XVSRewardsHelper
 * @author Venus
 * @dev This contract contains internal functions used in RewardFacet and PolicyFacet
 * @notice This facet contract contains the shared functions used by the RewardFacet and PolicyFacet
 */
contract XVSRewardsHelper is FacetBase {
    /// @notice Emitted when XVS is distributed to a borrower
    event DistributedBorrowerVenus(
        VToken indexed vToken,
        address indexed borrower,
        uint256 venusDelta,
        uint256 venusBorrowIndex
    );

    /// @notice Emitted when XVS is distributed to a supplier
    event DistributedSupplierVenus(
        VToken indexed vToken,
        address indexed supplier,
        uint256 venusDelta,
        uint256 venusSupplyIndex
    );

    /**
     * @notice Accrue XVS to the market by updating the borrow index
     * @param vToken The market whose borrow index to update
     */
    function updateVenusBorrowIndex(address vToken, Exp memory marketBorrowIndex) internal {
        VenusMarketState storage borrowState = venusBorrowState[vToken];
        uint256 borrowSpeed = venusBorrowSpeeds[vToken];
        uint32 blockNumber = getBlockNumberAsUint32();
        uint256 deltaBlocks = sub_(blockNumber, borrowState.block);
        if (deltaBlocks != 0 && borrowSpeed != 0) {
            uint256 borrowAmount = div_(VToken(vToken).totalBorrows(), marketBorrowIndex);
            uint256 accruedVenus = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount != 0 ? fraction(accruedVenus, borrowAmount) : Double({ mantissa: 0 });
            borrowState.index = safe224(add_(Double({ mantissa: borrowState.index }), ratio).mantissa, "224");
            borrowState.block = blockNumber;
        } else if (deltaBlocks != 0) {
            borrowState.block = blockNumber;
        }
    }

    /**
     * @notice Accrue XVS to the market by updating the supply index
     * @param vToken The market whose supply index to update
     */
    function updateVenusSupplyIndex(address vToken) internal {
        VenusMarketState storage supplyState = venusSupplyState[vToken];
        uint256 supplySpeed = venusSupplySpeeds[vToken];
        uint32 blockNumber = getBlockNumberAsUint32();

        uint256 deltaBlocks = sub_(blockNumber, supplyState.block);
        if (deltaBlocks != 0 && supplySpeed != 0) {
            uint256 supplyTokens = VToken(vToken).totalSupply();
            uint256 accruedVenus = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens != 0 ? fraction(accruedVenus, supplyTokens) : Double({ mantissa: 0 });
            supplyState.index = safe224(add_(Double({ mantissa: supplyState.index }), ratio).mantissa, "224");
            supplyState.block = blockNumber;
        } else if (deltaBlocks != 0) {
            supplyState.block = blockNumber;
        }
    }

    /**
     * @notice Calculate XVS accrued by a supplier and possibly transfer it to them
     * @param vToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute XVS to
     */
    function distributeSupplierVenus(address vToken, address supplier) internal {
        if (address(vaiVaultAddress) != address(0)) {
            releaseToVault();
        }
        uint256 supplyIndex = venusSupplyState[vToken].index;
        uint256 supplierIndex = venusSupplierIndex[vToken][supplier];
        // Update supplier's index to the current index since we are distributing accrued XVS
        venusSupplierIndex[vToken][supplier] = supplyIndex;
        if (supplierIndex == 0 && supplyIndex >= venusInitialIndex) {
            // Covers the case where users supplied tokens before the market's supply state index was set.
            // Rewards the user with XVS accrued from the start of when supplier rewards were first
            // set for the market.
            supplierIndex = venusInitialIndex;
        }
        // Calculate change in the cumulative sum of the XVS per vToken accrued
        Double memory deltaIndex = Double({ mantissa: sub_(supplyIndex, supplierIndex) });
        // Multiply of supplierTokens and supplierDelta
        uint256 supplierDelta = mul_(VToken(vToken).balanceOf(supplier), deltaIndex);
        // Addition of supplierAccrued and supplierDelta
        venusAccrued[supplier] = add_(venusAccrued[supplier], supplierDelta);
        emit DistributedSupplierVenus(VToken(vToken), supplier, supplierDelta, supplyIndex);
    }

    /**
     * @notice Calculate XVS accrued by a borrower and possibly transfer it to them
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol
     * @param vToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute XVS to
     */
    function distributeBorrowerVenus(address vToken, address borrower, Exp memory marketBorrowIndex) internal {
        if (address(vaiVaultAddress) != address(0)) {
            releaseToVault();
        }
        uint256 borrowIndex = venusBorrowState[vToken].index;
        uint256 borrowerIndex = venusBorrowerIndex[vToken][borrower];
        // Update borrowers's index to the current index since we are distributing accrued XVS
        venusBorrowerIndex[vToken][borrower] = borrowIndex;
        if (borrowerIndex == 0 && borrowIndex >= venusInitialIndex) {
            // Covers the case where users borrowed tokens before the market's borrow state index was set.
            // Rewards the user with XVS accrued from the start of when borrower rewards were first
            // set for the market.
            borrowerIndex = venusInitialIndex;
        }
        // Calculate change in the cumulative sum of the XVS per borrowed unit accrued
        Double memory deltaIndex = Double({ mantissa: sub_(borrowIndex, borrowerIndex) });
        uint256 borrowerDelta = mul_(div_(VToken(vToken).borrowBalanceStored(borrower), marketBorrowIndex), deltaIndex);
        venusAccrued[borrower] = add_(venusAccrued[borrower], borrowerDelta);
        emit DistributedBorrowerVenus(VToken(vToken), borrower, borrowerDelta, borrowIndex);
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    function diamondCut(FacetCut[] calldata _diamondCut) external;
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;

import { VToken } from "../../../Tokens/VTokens/VToken.sol";

interface IMarketFacet {
    function isComptroller() external pure returns (bool);

    function liquidateCalculateSeizeTokens(
        address vTokenBorrowed,
        address vTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256, uint256);

    function liquidateVAICalculateSeizeTokens(
        address vTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256, uint256);

    function checkMembership(address account, VToken vToken) external view returns (bool);

    function enterMarkets(address[] calldata vTokens) external returns (uint256[] memory);

    function exitMarket(address vToken) external returns (uint256);

    function _supportMarket(VToken vToken) external returns (uint256);

    function getAssetsIn(address account) external view returns (VToken[] memory);

    function getAllMarkets() external view returns (VToken[] memory);

    function updateDelegate(address delegate, bool allowBorrows) external;
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;

import { VToken } from "../../../Tokens/VTokens/VToken.sol";

interface IPolicyFacet {
    function mintAllowed(address vToken, address minter, uint256 mintAmount) external returns (uint256);

    function mintVerify(address vToken, address minter, uint256 mintAmount, uint256 mintTokens) external;

    function redeemAllowed(address vToken, address redeemer, uint256 redeemTokens) external returns (uint256);

    function redeemVerify(address vToken, address redeemer, uint256 redeemAmount, uint256 redeemTokens) external;

    function borrowAllowed(address vToken, address borrower, uint256 borrowAmount) external returns (uint256);

    function borrowVerify(address vToken, address borrower, uint256 borrowAmount) external;

    function repayBorrowAllowed(
        address vToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address vToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external view returns (uint256);

    function liquidateBorrowVerify(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address vToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(address vToken, address src, address dst, uint256 transferTokens) external;

    function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);

    function getHypotheticalAccountLiquidity(
        address account,
        address vTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) external view returns (uint256, uint256, uint256);

    function _setVenusSpeeds(
        VToken[] calldata vTokens,
        uint256[] calldata supplySpeeds,
        uint256[] calldata borrowSpeeds
    ) external;
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;

import { VToken } from "../../../Tokens/VTokens/VToken.sol";
import { ComptrollerTypes } from "../../ComptrollerStorage.sol";

interface IRewardFacet {
    function claimVenus(address holder) external;

    function claimVenus(address holder, VToken[] calldata vTokens) external;

    function claimVenus(address[] calldata holders, VToken[] calldata vTokens, bool borrowers, bool suppliers) external;

    function claimVenusAsCollateral(address holder) external;

    function _grantXVS(address recipient, uint256 amount) external;

    function getXVSAddress() external view returns (address);

    function getXVSVTokenAddress() external view returns (address);

    function actionPaused(address market, ComptrollerTypes.Action action) external view returns (bool);

    function claimVenus(
        address[] calldata holders,
        VToken[] calldata vTokens,
        bool borrowers,
        bool suppliers,
        bool collateral
    ) external;
    function seizeVenus(address[] calldata holders, address recipient) external returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;

import { PriceOracle } from "../../../Oracle/PriceOracle.sol";
import { VToken } from "../../../Tokens/VTokens/VToken.sol";
import { ComptrollerTypes } from "../../ComptrollerStorage.sol";
import { VAIControllerInterface } from "../../../Tokens/VAI/VAIControllerInterface.sol";
import { ComptrollerLensInterface } from "../../../Comptroller/ComptrollerLensInterface.sol";
import { IPrime } from "../../../Tokens/Prime/IPrime.sol";

interface ISetterFacet {
    function _setPriceOracle(PriceOracle newOracle) external returns (uint256);

    function _setCloseFactor(uint256 newCloseFactorMantissa) external returns (uint256);

    function _setAccessControl(address newAccessControlAddress) external returns (uint256);

    function _setCollateralFactor(VToken vToken, uint256 newCollateralFactorMantissa) external returns (uint256);

    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external returns (uint256);

    function _setLiquidatorContract(address newLiquidatorContract_) external;

    function _setPauseGuardian(address newPauseGuardian) external returns (uint256);

    function _setMarketBorrowCaps(VToken[] calldata vTokens, uint256[] calldata newBorrowCaps) external;

    function _setMarketSupplyCaps(VToken[] calldata vTokens, uint256[] calldata newSupplyCaps) external;

    function _setProtocolPaused(bool state) external returns (bool);

    function _setActionsPaused(
        address[] calldata markets,
        ComptrollerTypes.Action[] calldata actions,
        bool paused
    ) external;

    function _setVAIController(VAIControllerInterface vaiController_) external returns (uint256);

    function _setVAIMintRate(uint256 newVAIMintRate) external returns (uint256);

    function setMintedVAIOf(address owner, uint256 amount) external returns (uint256);

    function _setTreasuryData(
        address newTreasuryGuardian,
        address newTreasuryAddress,
        uint256 newTreasuryPercent
    ) external returns (uint256);

    function _setComptrollerLens(ComptrollerLensInterface comptrollerLens_) external returns (uint256);

    function _setVenusVAIVaultRate(uint256 venusVAIVaultRate_) external;

    function _setVAIVaultInfo(address vault_, uint256 releaseStartBlock_, uint256 minReleaseAmount_) external;

    function _setForcedLiquidation(address vToken, bool enable) external;

    function _setPrimeToken(IPrime _prime) external returns (uint);

    function _setForcedLiquidationForUser(address borrower, address vTokenBorrowed, bool enable) external;

    function _setXVSToken(address xvs_) external;

    function _setXVSVToken(address xvsVToken_) external;
}

pragma solidity ^0.5.16;

import "./ComptrollerStorage.sol";
import "../Utils/ErrorReporter.sol";

/**
 * @title ComptrollerCore
 * @dev Storage for the comptroller is at this address, while execution is delegated to the `comptrollerImplementation`.
 * VTokens should reference this contract as their comptroller.
 */
contract Unitroller is UnitrollerAdminStorage, ComptrollerErrorReporter {
    /**
     * @notice Emitted when pendingComptrollerImplementation is changed
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingComptrollerImplementation is accepted, which means comptroller implementation is updated
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() public {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
        }

        address oldPendingImplementation = pendingComptrollerImplementation;

        pendingComptrollerImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accepts new implementation of comptroller. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptImplementation() public returns (uint) {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        if (msg.sender != pendingComptrollerImplementation || pendingComptrollerImplementation == address(0)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
        }

        // Save current values for inclusion in log
        address oldImplementation = comptrollerImplementation;
        address oldPendingImplementation = pendingComptrollerImplementation;

        comptrollerImplementation = pendingComptrollerImplementation;

        pendingComptrollerImplementation = address(0);

        emit NewImplementation(oldImplementation, comptrollerImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptAdmin() public returns (uint) {
        // Check caller is pendingAdmin
        if (msg.sender != pendingAdmin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = comptrollerImplementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize)
            }
            default {
                return(free_mem_ptr, returndatasize)
            }
        }
    }
}

pragma solidity ^0.5.16;

import "../Utils/IBEP20.sol";
import "../Utils/SafeBEP20.sol";
import "../Utils/Ownable.sol";

/**
 * @title VTreasury
 * @author Venus
 * @notice Protocol treasury that holds tokens owned by Venus
 */
contract VTreasury is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // WithdrawTreasuryBEP20 Event
    event WithdrawTreasuryBEP20(address tokenAddress, uint256 withdrawAmount, address withdrawAddress);

    // WithdrawTreasuryBNB Event
    event WithdrawTreasuryBNB(uint256 withdrawAmount, address withdrawAddress);

    /**
     * @notice To receive BNB
     */
    function() external payable {}

    /**
     * @notice Withdraw Treasury BEP20 Tokens, Only owner call it
     * @param tokenAddress The address of treasury token
     * @param withdrawAmount The withdraw amount to owner
     * @param withdrawAddress The withdraw address
     */
    function withdrawTreasuryBEP20(
        address tokenAddress,
        uint256 withdrawAmount,
        address withdrawAddress
    ) external onlyOwner {
        uint256 actualWithdrawAmount = withdrawAmount;
        // Get Treasury Token Balance
        uint256 treasuryBalance = IBEP20(tokenAddress).balanceOf(address(this));

        // Check Withdraw Amount
        if (withdrawAmount > treasuryBalance) {
            // Update actualWithdrawAmount
            actualWithdrawAmount = treasuryBalance;
        }

        // Transfer BEP20 Token to withdrawAddress
        IBEP20(tokenAddress).safeTransfer(withdrawAddress, actualWithdrawAmount);

        emit WithdrawTreasuryBEP20(tokenAddress, actualWithdrawAmount, withdrawAddress);
    }

    /**
     * @notice Withdraw Treasury BNB, Only owner call it
     * @param withdrawAmount The withdraw amount to owner
     * @param withdrawAddress The withdraw address
     */
    function withdrawTreasuryBNB(uint256 withdrawAmount, address payable withdrawAddress) external payable onlyOwner {
        uint256 actualWithdrawAmount = withdrawAmount;
        // Get Treasury BNB Balance
        uint256 bnbBalance = address(this).balance;

        // Check Withdraw Amount
        if (withdrawAmount > bnbBalance) {
            // Update actualWithdrawAmount
            actualWithdrawAmount = bnbBalance;
        }
        // Transfer BNB to withdrawAddress
        withdrawAddress.transfer(actualWithdrawAmount);

        emit WithdrawTreasuryBNB(actualWithdrawAmount, withdrawAddress);
    }
}

pragma solidity ^0.5.16;

/**
 * @title Venus's InterestRateModel Interface
 * @author Venus
 */
contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amnount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amnount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactorMantissa
    ) external view returns (uint);
}

pragma solidity ^0.5.16;

import "../Utils/SafeMath.sol";
import "./InterestRateModel.sol";

/**
 * @title Venus's JumpRateModel Contract
 * @author Venus
 */
contract JumpRateModel is InterestRateModel {
    using SafeMath for uint;

    event NewInterestParams(uint baseRatePerBlock, uint multiplierPerBlock, uint jumpMultiplierPerBlock, uint kink);

    /**
     * @notice The approximate number of blocks per year that is assumed by the interest rate model
     */
    uint public constant blocksPerYear = (60 * 60 * 24 * 365) / 3; // (assuming 3s blocks)

    /**
     * @notice The multiplier of utilization rate that gives the slope of the interest rate
     */
    uint public multiplierPerBlock;

    /**
     * @notice The base interest rate which is the y-intercept when utilization rate is 0
     */
    uint public baseRatePerBlock;

    /**
     * @notice The multiplierPerBlock after hitting a specified utilization point
     */
    uint public jumpMultiplierPerBlock;

    /**
     * @notice The utilization point at which the jump multiplier is applied
     */
    uint public kink;

    /**
     * @notice Construct an interest rate model
     * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
     * @param kink_ The utilization point at which the jump multiplier is applied
     */
    constructor(uint baseRatePerYear, uint multiplierPerYear, uint jumpMultiplierPerYear, uint kink_) public {
        baseRatePerBlock = baseRatePerYear.div(blocksPerYear);
        multiplierPerBlock = multiplierPerYear.div(blocksPerYear);
        jumpMultiplierPerBlock = jumpMultiplierPerYear.div(blocksPerYear);
        kink = kink_;

        emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink);
    }

    /**
     * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market (currently unused)
     * @return The utilization rate as a mantissa between [0, 1e18]
     */
    function utilizationRate(uint cash, uint borrows, uint reserves) public pure returns (uint) {
        // Utilization rate is 0 when there are no borrows
        if (borrows == 0) {
            return 0;
        }

        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
    }

    /**
     * @notice Calculates the current borrow rate per block, with the error code expected by the market
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getBorrowRate(uint cash, uint borrows, uint reserves) public view returns (uint) {
        uint util = utilizationRate(cash, borrows, reserves);

        if (util <= kink) {
            return util.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
        } else {
            uint normalRate = kink.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
            uint excessUtil = util.sub(kink);
            return excessUtil.mul(jumpMultiplierPerBlock).div(1e18).add(normalRate);
        }
    }

    /**
     * @notice Calculates the current supply rate per block
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @param reserveFactorMantissa The current reserve factor for the market
     * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactorMantissa
    ) public view returns (uint) {
        uint oneMinusReserveFactor = uint(1e18).sub(reserveFactorMantissa);
        uint borrowRate = getBorrowRate(cash, borrows, reserves);
        uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }
}

pragma solidity ^0.5.16;

import "../Utils/SafeMath.sol";
import "./InterestRateModel.sol";

/**
 * @title Venus's WhitePaperInterestRateModel Contract
 * @author Venus
 * @notice The parameterized model described in section 2.4 of the original Venus Protocol whitepaper
 */
contract WhitePaperInterestRateModel is InterestRateModel {
    using SafeMath for uint;

    event NewInterestParams(uint baseRatePerBlock, uint multiplierPerBlock);

    /**
     * @notice The approximate number of blocks per year that is assumed by the interest rate model
     */
    uint public constant blocksPerYear = (60 * 60 * 24 * 365) / 3; // (assuming 3s blocks)

    /**
     * @notice The multiplier of utilization rate that gives the slope of the interest rate
     */
    uint public multiplierPerBlock;

    /**
     * @notice The base interest rate which is the y-intercept when utilization rate is 0
     */
    uint public baseRatePerBlock;

    /**
     * @notice Construct an interest rate model
     * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     */
    constructor(uint baseRatePerYear, uint multiplierPerYear) public {
        baseRatePerBlock = baseRatePerYear.div(blocksPerYear);
        multiplierPerBlock = multiplierPerYear.div(blocksPerYear);

        emit NewInterestParams(baseRatePerBlock, multiplierPerBlock);
    }

    /**
     * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market (currently unused)
     * @return The utilization rate as a mantissa between [0, 1e18]
     */
    function utilizationRate(uint cash, uint borrows, uint reserves) public pure returns (uint) {
        // Utilization rate is 0 when there are no borrows
        if (borrows == 0) {
            return 0;
        }

        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
    }

    /**
     * @notice Calculates the current borrow rate per block, with the error code expected by the market
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getBorrowRate(uint cash, uint borrows, uint reserves) public view returns (uint) {
        uint ur = utilizationRate(cash, borrows, reserves);
        return ur.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
    }

    /**
     * @notice Calculates the current supply rate per block
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @param reserveFactorMantissa The current reserve factor for the market
     * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactorMantissa
    ) public view returns (uint) {
        uint oneMinusReserveFactor = uint(1e18).sub(reserveFactorMantissa);
        uint borrowRate = getBorrowRate(cash, borrows, reserves);
        uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../Tokens/VTokens/VBep20.sol";
import { VToken } from "../Tokens/VTokens/VToken.sol";
import { ExponentialNoError } from "../Utils/ExponentialNoError.sol";
import "../Tokens/EIP20Interface.sol";
import "../Oracle/PriceOracle.sol";
import "../Utils/ErrorReporter.sol";
import "../Comptroller/ComptrollerInterface.sol";
import "../Comptroller/ComptrollerLensInterface.sol";
import "../Tokens/VAI/VAIControllerInterface.sol";

/**
 * @title ComptrollerLens Contract
 * @author Venus
 * @notice The ComptrollerLens contract has functions to get the number of tokens that
 * can be seized through liquidation, hypothetical account liquidity and shortfall of an account.
 */
contract ComptrollerLens is ComptrollerLensInterface, ComptrollerErrorReporter, ExponentialNoError {
    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `vTokenBalance` is the number of vTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint vTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Computes the number of collateral tokens to be seized in a liquidation event
     * @param comptroller Address of comptroller
     * @param vTokenBorrowed Address of the borrowed vToken
     * @param vTokenCollateral Address of collateral for the borrow
     * @param actualRepayAmount Repayment amount i.e amount to be repaid of total borrowed amount
     * @return A tuple of error code, and tokens to seize
     */
    function liquidateCalculateSeizeTokens(
        address comptroller,
        address vTokenBorrowed,
        address vTokenCollateral,
        uint actualRepayAmount
    ) external view returns (uint, uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = ComptrollerInterface(comptroller).oracle().getUnderlyingPrice(
            VToken(vTokenBorrowed)
        );
        uint priceCollateralMantissa = ComptrollerInterface(comptroller).oracle().getUnderlyingPrice(
            VToken(vTokenCollateral)
        );
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint exchangeRateMantissa = VToken(vTokenCollateral).exchangeRateStored(); // Note: reverts on error
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;

        numerator = mul_(
            Exp({ mantissa: ComptrollerInterface(comptroller).liquidationIncentiveMantissa() }),
            Exp({ mantissa: priceBorrowedMantissa })
        );
        denominator = mul_(Exp({ mantissa: priceCollateralMantissa }), Exp({ mantissa: exchangeRateMantissa }));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);

        return (uint(Error.NO_ERROR), seizeTokens);
    }

    /**
     * @notice Computes the number of VAI tokens to be seized in a liquidation event
     * @param comptroller Address of comptroller
     * @param vTokenCollateral Address of collateral for vToken
     * @param actualRepayAmount Repayment amount i.e amount to be repaid of the total borrowed amount
     * @return A tuple of error code, and tokens to seize
     */
    function liquidateVAICalculateSeizeTokens(
        address comptroller,
        address vTokenCollateral,
        uint actualRepayAmount
    ) external view returns (uint, uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = 1e18; // Note: this is VAI
        uint priceCollateralMantissa = ComptrollerInterface(comptroller).oracle().getUnderlyingPrice(
            VToken(vTokenCollateral)
        );
        if (priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint exchangeRateMantissa = VToken(vTokenCollateral).exchangeRateStored(); // Note: reverts on error
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;

        numerator = mul_(
            Exp({ mantissa: ComptrollerInterface(comptroller).liquidationIncentiveMantissa() }),
            Exp({ mantissa: priceBorrowedMantissa })
        );
        denominator = mul_(Exp({ mantissa: priceCollateralMantissa }), Exp({ mantissa: exchangeRateMantissa }));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);

        return (uint(Error.NO_ERROR), seizeTokens);
    }

    /**
     * @notice Computes the hypothetical liquidity and shortfall of an account given a hypothetical borrow
     *      A snapshot of the account is taken and the total borrow amount of the account is calculated
     * @param comptroller Address of comptroller
     * @param account Address of the borrowed vToken
     * @param vTokenModify Address of collateral for vToken
     * @param redeemTokens Number of vTokens being redeemed
     * @param borrowAmount Amount borrowed
     * @return Returns a tuple of error code, liquidity, and shortfall
     */
    function getHypotheticalAccountLiquidity(
        address comptroller,
        address account,
        VToken vTokenModify,
        uint redeemTokens,
        uint borrowAmount
    ) external view returns (uint, uint, uint) {
        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;

        // For each asset the account is in
        VToken[] memory assets = ComptrollerInterface(comptroller).getAssetsIn(account);
        uint assetsCount = assets.length;
        for (uint i = 0; i < assetsCount; ++i) {
            VToken asset = assets[i];

            // Read the balances and exchange rate from the vToken
            (oErr, vars.vTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(
                account
            );
            if (oErr != 0) {
                // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (uint(Error.SNAPSHOT_ERROR), 0, 0);
            }
            (, uint collateralFactorMantissa) = ComptrollerInterface(comptroller).markets(address(asset));
            vars.collateralFactor = Exp({ mantissa: collateralFactorMantissa });
            vars.exchangeRate = Exp({ mantissa: vars.exchangeRateMantissa });

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = ComptrollerInterface(comptroller).oracle().getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (uint(Error.PRICE_ERROR), 0, 0);
            }
            vars.oraclePrice = Exp({ mantissa: vars.oraclePriceMantissa });

            // Pre-compute a conversion factor from tokens -> bnb (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * vTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.vTokenBalance, vars.sumCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
                vars.oraclePrice,
                vars.borrowBalance,
                vars.sumBorrowPlusEffects
            );

            // Calculate effects of interacting with vTokenModify
            if (asset == vTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
                    vars.tokensToDenom,
                    redeemTokens,
                    vars.sumBorrowPlusEffects
                );

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
                    vars.oraclePrice,
                    borrowAmount,
                    vars.sumBorrowPlusEffects
                );
            }
        }

        VAIControllerInterface vaiController = ComptrollerInterface(comptroller).vaiController();

        if (address(vaiController) != address(0)) {
            vars.sumBorrowPlusEffects = add_(vars.sumBorrowPlusEffects, vaiController.getVAIRepayAmount(account));
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (uint(Error.NO_ERROR), vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (uint(Error.NO_ERROR), 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { VToken } from "../Tokens/VTokens/VToken.sol";
import { ExponentialNoError } from "../Utils/ExponentialNoError.sol";
import "../Utils/SafeMath.sol";
import "../Comptroller/ComptrollerInterface.sol";
import "../Tokens/EIP20Interface.sol";
import "../Tokens/VTokens/VBep20.sol";

contract SnapshotLens is ExponentialNoError {
    using SafeMath for uint256;

    struct AccountSnapshot {
        address account;
        string assetName;
        address vTokenAddress;
        address underlyingAssetAddress;
        uint256 supply;
        uint256 supplyInUsd;
        uint256 collateral;
        uint256 borrows;
        uint256 borrowsInUsd;
        uint256 assetPrice;
        uint256 accruedInterest;
        uint vTokenDecimals;
        uint underlyingDecimals;
        uint exchangeRate;
        bool isACollateral;
    }

    /** Snapshot calculation **/
    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account snapshot.
     *  Note that `vTokenBalance` is the number of vTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountSnapshotLocalVars {
        uint collateral;
        uint vTokenBalance;
        uint borrowBalance;
        uint borrowsInUsd;
        uint balanceOfUnderlying;
        uint supplyInUsd;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
        bool isACollateral;
    }

    function getAccountSnapshot(
        address payable account,
        address comptrollerAddress
    ) public returns (AccountSnapshot[] memory) {
        // For each asset the account is in
        VToken[] memory assets = ComptrollerInterface(comptrollerAddress).getAllMarkets();
        AccountSnapshot[] memory accountSnapshots = new AccountSnapshot[](assets.length);
        for (uint256 i = 0; i < assets.length; ++i) {
            accountSnapshots[i] = getAccountSnapshot(account, comptrollerAddress, assets[i]);
        }
        return accountSnapshots;
    }

    function isACollateral(address account, address asset, address comptrollerAddress) public view returns (bool) {
        VToken[] memory assetsAsCollateral = ComptrollerInterface(comptrollerAddress).getAssetsIn(account);
        for (uint256 j = 0; j < assetsAsCollateral.length; ++j) {
            if (address(assetsAsCollateral[j]) == asset) {
                return true;
            }
        }

        return false;
    }

    function getAccountSnapshot(
        address payable account,
        address comptrollerAddress,
        VToken vToken
    ) public returns (AccountSnapshot memory) {
        AccountSnapshotLocalVars memory vars; // Holds all our calculation results
        uint oErr;

        // Read the balances and exchange rate from the vToken
        (oErr, vars.vTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = vToken.getAccountSnapshot(account);
        require(oErr == 0, "Snapshot Error");
        vars.exchangeRate = Exp({ mantissa: vars.exchangeRateMantissa });

        (, uint collateralFactorMantissa) = ComptrollerInterface(comptrollerAddress).markets(address(vToken));
        vars.collateralFactor = Exp({ mantissa: collateralFactorMantissa });

        // Get the normalized price of the asset
        vars.oraclePriceMantissa = ComptrollerInterface(comptrollerAddress).oracle().getUnderlyingPrice(vToken);
        vars.oraclePrice = Exp({ mantissa: vars.oraclePriceMantissa });

        // Pre-compute a conversion factor from tokens -> bnb (normalized price value)
        vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

        //Collateral = tokensToDenom * vTokenBalance
        vars.collateral = mul_ScalarTruncate(vars.tokensToDenom, vars.vTokenBalance);

        vars.balanceOfUnderlying = vToken.balanceOfUnderlying(account);
        vars.supplyInUsd = mul_ScalarTruncate(vars.oraclePrice, vars.balanceOfUnderlying);

        vars.borrowsInUsd = mul_ScalarTruncate(vars.oraclePrice, vars.borrowBalance);

        address underlyingAssetAddress;
        uint underlyingDecimals;

        if (compareStrings(vToken.symbol(), "vBNB")) {
            underlyingAssetAddress = address(0);
            underlyingDecimals = 18;
        } else {
            VBep20 vBep20 = VBep20(address(vToken));
            underlyingAssetAddress = vBep20.underlying();
            underlyingDecimals = EIP20Interface(vBep20.underlying()).decimals();
        }

        vars.isACollateral = isACollateral(account, address(vToken), comptrollerAddress);

        return
            AccountSnapshot({
                account: account,
                assetName: vToken.name(),
                vTokenAddress: address(vToken),
                underlyingAssetAddress: underlyingAssetAddress,
                supply: vars.balanceOfUnderlying,
                supplyInUsd: vars.supplyInUsd,
                collateral: vars.collateral,
                borrows: vars.borrowBalance,
                borrowsInUsd: vars.borrowsInUsd,
                assetPrice: vars.oraclePriceMantissa,
                accruedInterest: vToken.borrowIndex(),
                vTokenDecimals: vToken.decimals(),
                underlyingDecimals: underlyingDecimals,
                exchangeRate: vToken.exchangeRateCurrent(),
                isACollateral: vars.isACollateral
            });
    }

    // utilities
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../Tokens/VTokens/VBep20.sol";
import "../Tokens/VTokens/VToken.sol";
import "../Oracle/PriceOracle.sol";
import "../Tokens/EIP20Interface.sol";
import "../Tokens/XVS/XVS.sol";
import "../Comptroller/ComptrollerInterface.sol";
import "../Utils/SafeMath.sol";
import { ComptrollerTypes } from "../Comptroller/ComptrollerStorage.sol";

contract VenusLens is ExponentialNoError {
    using SafeMath for uint;

    /// @notice Blocks Per Day
    uint public constant BLOCKS_PER_DAY = 28800;

    /// @notice Total actions available on VToken
    uint public constant VTOKEN_ACTIONS = 8;

    struct VenusMarketState {
        uint224 index;
        uint32 block;
    }

    struct VTokenMetadata {
        address vToken;
        uint exchangeRateCurrent;
        uint supplyRatePerBlock;
        uint borrowRatePerBlock;
        uint reserveFactorMantissa;
        uint totalBorrows;
        uint totalReserves;
        uint totalSupply;
        uint totalCash;
        bool isListed;
        uint collateralFactorMantissa;
        address underlyingAssetAddress;
        uint vTokenDecimals;
        uint underlyingDecimals;
        uint venusSupplySpeed;
        uint venusBorrowSpeed;
        uint dailySupplyXvs;
        uint dailyBorrowXvs;
        uint pausedActions;
    }

    struct VTokenBalances {
        address vToken;
        uint balanceOf;
        uint borrowBalanceCurrent;
        uint balanceOfUnderlying;
        uint tokenBalance;
        uint tokenAllowance;
    }

    struct VTokenUnderlyingPrice {
        address vToken;
        uint underlyingPrice;
    }

    struct AccountLimits {
        VToken[] markets;
        uint liquidity;
        uint shortfall;
    }

    struct XVSBalanceMetadata {
        uint balance;
        uint votes;
        address delegate;
    }

    struct XVSBalanceMetadataExt {
        uint balance;
        uint votes;
        address delegate;
        uint allocated;
    }

    struct VenusVotes {
        uint blockNumber;
        uint votes;
    }

    struct ClaimVenusLocalVariables {
        uint totalRewards;
        uint224 borrowIndex;
        uint32 borrowBlock;
        uint224 supplyIndex;
        uint32 supplyBlock;
    }

    /**
     * @dev Struct for Pending Rewards for per market
     */
    struct PendingReward {
        address vTokenAddress;
        uint256 amount;
    }

    /**
     * @dev Struct for Reward of a single reward token.
     */
    struct RewardSummary {
        address distributorAddress;
        address rewardTokenAddress;
        uint256 totalRewards;
        PendingReward[] pendingRewards;
    }

    /**
     * @notice Query the metadata of a vToken by its address
     * @param vToken The address of the vToken to fetch VTokenMetadata
     * @return VTokenMetadata struct with vToken supply and borrow information.
     */
    function vTokenMetadata(VToken vToken) public returns (VTokenMetadata memory) {
        uint exchangeRateCurrent = vToken.exchangeRateCurrent();
        address comptrollerAddress = address(vToken.comptroller());
        ComptrollerInterface comptroller = ComptrollerInterface(comptrollerAddress);
        (bool isListed, uint collateralFactorMantissa) = comptroller.markets(address(vToken));
        address underlyingAssetAddress;
        uint underlyingDecimals;

        if (compareStrings(vToken.symbol(), "vBNB")) {
            underlyingAssetAddress = address(0);
            underlyingDecimals = 18;
        } else {
            VBep20 vBep20 = VBep20(address(vToken));
            underlyingAssetAddress = vBep20.underlying();
            underlyingDecimals = EIP20Interface(vBep20.underlying()).decimals();
        }

        uint venusSupplySpeedPerBlock = comptroller.venusSupplySpeeds(address(vToken));
        uint venusBorrowSpeedPerBlock = comptroller.venusBorrowSpeeds(address(vToken));

        uint256 pausedActions;

        for (uint8 i; i <= VTOKEN_ACTIONS; ++i) {
            uint256 paused = comptroller.actionPaused(address(vToken), ComptrollerTypes.Action(i)) ? 1 : 0;
            pausedActions |= paused << i;
        }

        return
            VTokenMetadata({
                vToken: address(vToken),
                exchangeRateCurrent: exchangeRateCurrent,
                supplyRatePerBlock: vToken.supplyRatePerBlock(),
                borrowRatePerBlock: vToken.borrowRatePerBlock(),
                reserveFactorMantissa: vToken.reserveFactorMantissa(),
                totalBorrows: vToken.totalBorrows(),
                totalReserves: vToken.totalReserves(),
                totalSupply: vToken.totalSupply(),
                totalCash: vToken.getCash(),
                isListed: isListed,
                collateralFactorMantissa: collateralFactorMantissa,
                underlyingAssetAddress: underlyingAssetAddress,
                vTokenDecimals: vToken.decimals(),
                underlyingDecimals: underlyingDecimals,
                venusSupplySpeed: venusSupplySpeedPerBlock,
                venusBorrowSpeed: venusBorrowSpeedPerBlock,
                dailySupplyXvs: venusSupplySpeedPerBlock.mul(BLOCKS_PER_DAY),
                dailyBorrowXvs: venusBorrowSpeedPerBlock.mul(BLOCKS_PER_DAY),
                pausedActions: pausedActions
            });
    }

    /**
     * @notice Get VTokenMetadata for an array of vToken addresses
     * @param vTokens Array of vToken addresses to fetch VTokenMetadata
     * @return Array of structs with vToken supply and borrow information.
     */
    function vTokenMetadataAll(VToken[] calldata vTokens) external returns (VTokenMetadata[] memory) {
        uint vTokenCount = vTokens.length;
        VTokenMetadata[] memory res = new VTokenMetadata[](vTokenCount);
        for (uint i = 0; i < vTokenCount; i++) {
            res[i] = vTokenMetadata(vTokens[i]);
        }
        return res;
    }

    /**
     * @notice Get amount of XVS distributed daily to an account
     * @param account Address of account to fetch the daily XVS distribution
     * @param comptrollerAddress Address of the comptroller proxy
     * @return Amount of XVS distributed daily to an account
     */
    function getDailyXVS(address payable account, address comptrollerAddress) external returns (uint) {
        ComptrollerInterface comptrollerInstance = ComptrollerInterface(comptrollerAddress);
        VToken[] memory vTokens = comptrollerInstance.getAllMarkets();
        uint dailyXvsPerAccount = 0;

        for (uint i = 0; i < vTokens.length; i++) {
            VToken vToken = vTokens[i];
            if (!compareStrings(vToken.symbol(), "vUST") && !compareStrings(vToken.symbol(), "vLUNA")) {
                VTokenMetadata memory metaDataItem = vTokenMetadata(vToken);

                //get balanceOfUnderlying and borrowBalanceCurrent from vTokenBalance
                VTokenBalances memory vTokenBalanceInfo = vTokenBalances(vToken, account);

                VTokenUnderlyingPrice memory underlyingPriceResponse = vTokenUnderlyingPrice(vToken);
                uint underlyingPrice = underlyingPriceResponse.underlyingPrice;
                Exp memory underlyingPriceMantissa = Exp({ mantissa: underlyingPrice });

                //get dailyXvsSupplyMarket
                uint dailyXvsSupplyMarket = 0;
                uint supplyInUsd = mul_ScalarTruncate(underlyingPriceMantissa, vTokenBalanceInfo.balanceOfUnderlying);
                uint marketTotalSupply = (metaDataItem.totalSupply.mul(metaDataItem.exchangeRateCurrent)).div(1e18);
                uint marketTotalSupplyInUsd = mul_ScalarTruncate(underlyingPriceMantissa, marketTotalSupply);

                if (marketTotalSupplyInUsd > 0) {
                    dailyXvsSupplyMarket = (metaDataItem.dailySupplyXvs.mul(supplyInUsd)).div(marketTotalSupplyInUsd);
                }

                //get dailyXvsBorrowMarket
                uint dailyXvsBorrowMarket = 0;
                uint borrowsInUsd = mul_ScalarTruncate(underlyingPriceMantissa, vTokenBalanceInfo.borrowBalanceCurrent);
                uint marketTotalBorrowsInUsd = mul_ScalarTruncate(underlyingPriceMantissa, metaDataItem.totalBorrows);

                if (marketTotalBorrowsInUsd > 0) {
                    dailyXvsBorrowMarket = (metaDataItem.dailyBorrowXvs.mul(borrowsInUsd)).div(marketTotalBorrowsInUsd);
                }

                dailyXvsPerAccount += dailyXvsSupplyMarket + dailyXvsBorrowMarket;
            }
        }

        return dailyXvsPerAccount;
    }

    /**
     * @notice Get the current vToken balance (outstanding borrows) for an account
     * @param vToken Address of the token to check the balance of
     * @param account Account address to fetch the balance of
     * @return VTokenBalances with token balance information
     */
    function vTokenBalances(VToken vToken, address payable account) public returns (VTokenBalances memory) {
        uint balanceOf = vToken.balanceOf(account);
        uint borrowBalanceCurrent = vToken.borrowBalanceCurrent(account);
        uint balanceOfUnderlying = vToken.balanceOfUnderlying(account);
        uint tokenBalance;
        uint tokenAllowance;

        if (compareStrings(vToken.symbol(), "vBNB")) {
            tokenBalance = account.balance;
            tokenAllowance = account.balance;
        } else {
            VBep20 vBep20 = VBep20(address(vToken));
            EIP20Interface underlying = EIP20Interface(vBep20.underlying());
            tokenBalance = underlying.balanceOf(account);
            tokenAllowance = underlying.allowance(account, address(vToken));
        }

        return
            VTokenBalances({
                vToken: address(vToken),
                balanceOf: balanceOf,
                borrowBalanceCurrent: borrowBalanceCurrent,
                balanceOfUnderlying: balanceOfUnderlying,
                tokenBalance: tokenBalance,
                tokenAllowance: tokenAllowance
            });
    }

    /**
     * @notice Get the current vToken balances (outstanding borrows) for all vTokens on an account
     * @param vTokens Addresses of the tokens to check the balance of
     * @param account Account address to fetch the balance of
     * @return VTokenBalances Array with token balance information
     */
    function vTokenBalancesAll(
        VToken[] calldata vTokens,
        address payable account
    ) external returns (VTokenBalances[] memory) {
        uint vTokenCount = vTokens.length;
        VTokenBalances[] memory res = new VTokenBalances[](vTokenCount);
        for (uint i = 0; i < vTokenCount; i++) {
            res[i] = vTokenBalances(vTokens[i], account);
        }
        return res;
    }

    /**
     * @notice Get the price for the underlying asset of a vToken
     * @param vToken address of the vToken
     * @return response struct with underlyingPrice info of vToken
     */
    function vTokenUnderlyingPrice(VToken vToken) public view returns (VTokenUnderlyingPrice memory) {
        ComptrollerInterface comptroller = ComptrollerInterface(address(vToken.comptroller()));
        PriceOracle priceOracle = comptroller.oracle();

        return
            VTokenUnderlyingPrice({ vToken: address(vToken), underlyingPrice: priceOracle.getUnderlyingPrice(vToken) });
    }

    /**
     * @notice Query the underlyingPrice of an array of vTokens
     * @param vTokens Array of vToken addresses
     * @return array of response structs with underlying price information of vTokens
     */
    function vTokenUnderlyingPriceAll(
        VToken[] calldata vTokens
    ) external view returns (VTokenUnderlyingPrice[] memory) {
        uint vTokenCount = vTokens.length;
        VTokenUnderlyingPrice[] memory res = new VTokenUnderlyingPrice[](vTokenCount);
        for (uint i = 0; i < vTokenCount; i++) {
            res[i] = vTokenUnderlyingPrice(vTokens[i]);
        }
        return res;
    }

    /**
     * @notice Query the account liquidity and shortfall of an account
     * @param comptroller Address of comptroller proxy
     * @param account Address of the account to query
     * @return Struct with markets user has entered, liquidity, and shortfall of the account
     */
    function getAccountLimits(
        ComptrollerInterface comptroller,
        address account
    ) public view returns (AccountLimits memory) {
        (uint errorCode, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(account);
        require(errorCode == 0, "account liquidity error");

        return AccountLimits({ markets: comptroller.getAssetsIn(account), liquidity: liquidity, shortfall: shortfall });
    }

    /**
     * @notice Query the XVSBalance info of an account
     * @param xvs XVS contract address
     * @param account Account address
     * @return Struct with XVS balance and voter details
     */
    function getXVSBalanceMetadata(XVS xvs, address account) external view returns (XVSBalanceMetadata memory) {
        return
            XVSBalanceMetadata({
                balance: xvs.balanceOf(account),
                votes: uint256(xvs.getCurrentVotes(account)),
                delegate: xvs.delegates(account)
            });
    }

    /**
     * @notice Query the XVSBalance extended info of an account
     * @param xvs XVS contract address
     * @param comptroller Comptroller proxy contract address
     * @param account Account address
     * @return Struct with XVS balance and voter details and XVS allocation
     */
    function getXVSBalanceMetadataExt(
        XVS xvs,
        ComptrollerInterface comptroller,
        address account
    ) external returns (XVSBalanceMetadataExt memory) {
        uint balance = xvs.balanceOf(account);
        comptroller.claimVenus(account);
        uint newBalance = xvs.balanceOf(account);
        uint accrued = comptroller.venusAccrued(account);
        uint total = add_(accrued, newBalance, "sum xvs total");
        uint allocated = sub_(total, balance, "sub allocated");

        return
            XVSBalanceMetadataExt({
                balance: balance,
                votes: uint256(xvs.getCurrentVotes(account)),
                delegate: xvs.delegates(account),
                allocated: allocated
            });
    }

    /**
     * @notice Query the voting power for an account at a specific list of block numbers
     * @param xvs XVS contract address
     * @param account Address of the account
     * @param blockNumbers Array of blocks to query
     * @return Array of VenusVotes structs with block number and vote count
     */
    function getVenusVotes(
        XVS xvs,
        address account,
        uint32[] calldata blockNumbers
    ) external view returns (VenusVotes[] memory) {
        VenusVotes[] memory res = new VenusVotes[](blockNumbers.length);
        for (uint i = 0; i < blockNumbers.length; i++) {
            res[i] = VenusVotes({
                blockNumber: uint256(blockNumbers[i]),
                votes: uint256(xvs.getPriorVotes(account, blockNumbers[i]))
            });
        }
        return res;
    }

    /**
     * @dev Queries the current supply to calculate rewards for an account
     * @param supplyState VenusMarketState struct
     * @param vToken Address of a vToken
     * @param comptroller Address of the comptroller proxy
     */
    function updateVenusSupplyIndex(
        VenusMarketState memory supplyState,
        address vToken,
        ComptrollerInterface comptroller
    ) internal view {
        uint supplySpeed = comptroller.venusSupplySpeeds(vToken);
        uint blockNumber = block.number;
        uint deltaBlocks = sub_(blockNumber, uint(supplyState.block));
        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint supplyTokens = VToken(vToken).totalSupply();
            uint venusAccrued = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(venusAccrued, supplyTokens) : Double({ mantissa: 0 });
            Double memory index = add_(Double({ mantissa: supplyState.index }), ratio);
            supplyState.index = safe224(index.mantissa, "new index overflows");
            supplyState.block = safe32(blockNumber, "block number overflows");
        } else if (deltaBlocks > 0) {
            supplyState.block = safe32(blockNumber, "block number overflows");
        }
    }

    /**
     * @dev Queries the current borrow to calculate rewards for an account
     * @param borrowState VenusMarketState struct
     * @param vToken Address of a vToken
     * @param comptroller Address of the comptroller proxy
     */
    function updateVenusBorrowIndex(
        VenusMarketState memory borrowState,
        address vToken,
        Exp memory marketBorrowIndex,
        ComptrollerInterface comptroller
    ) internal view {
        uint borrowSpeed = comptroller.venusBorrowSpeeds(vToken);
        uint blockNumber = block.number;
        uint deltaBlocks = sub_(blockNumber, uint(borrowState.block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            uint borrowAmount = div_(VToken(vToken).totalBorrows(), marketBorrowIndex);
            uint venusAccrued = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(venusAccrued, borrowAmount) : Double({ mantissa: 0 });
            Double memory index = add_(Double({ mantissa: borrowState.index }), ratio);
            borrowState.index = safe224(index.mantissa, "new index overflows");
            borrowState.block = safe32(blockNumber, "block number overflows");
        } else if (deltaBlocks > 0) {
            borrowState.block = safe32(blockNumber, "block number overflows");
        }
    }

    /**
     * @dev Calculate available rewards for an account's supply
     * @param supplyState VenusMarketState struct
     * @param vToken Address of a vToken
     * @param supplier Address of the account supplying
     * @param comptroller Address of the comptroller proxy
     * @return Undistributed earned XVS from supplies
     */
    function distributeSupplierVenus(
        VenusMarketState memory supplyState,
        address vToken,
        address supplier,
        ComptrollerInterface comptroller
    ) internal view returns (uint) {
        Double memory supplyIndex = Double({ mantissa: supplyState.index });
        Double memory supplierIndex = Double({ mantissa: comptroller.venusSupplierIndex(vToken, supplier) });
        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = comptroller.venusInitialIndex();
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint supplierTokens = VToken(vToken).balanceOf(supplier);
        uint supplierDelta = mul_(supplierTokens, deltaIndex);
        return supplierDelta;
    }

    /**
     * @dev Calculate available rewards for an account's borrows
     * @param borrowState VenusMarketState struct
     * @param vToken Address of a vToken
     * @param borrower Address of the account borrowing
     * @param marketBorrowIndex vToken Borrow index
     * @param comptroller Address of the comptroller proxy
     * @return Undistributed earned XVS from borrows
     */
    function distributeBorrowerVenus(
        VenusMarketState memory borrowState,
        address vToken,
        address borrower,
        Exp memory marketBorrowIndex,
        ComptrollerInterface comptroller
    ) internal view returns (uint) {
        Double memory borrowIndex = Double({ mantissa: borrowState.index });
        Double memory borrowerIndex = Double({ mantissa: comptroller.venusBorrowerIndex(vToken, borrower) });
        if (borrowerIndex.mantissa > 0) {
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            uint borrowerAmount = div_(VToken(vToken).borrowBalanceStored(borrower), marketBorrowIndex);
            uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
            return borrowerDelta;
        }
        return 0;
    }

    /**
     * @notice Calculate the total XVS tokens pending and accrued by a user account
     * @param holder Account to query pending XVS
     * @param comptroller Address of the comptroller
     * @return Reward object contraining the totalRewards and pending rewards for each market
     */
    function pendingRewards(
        address holder,
        ComptrollerInterface comptroller
    ) external view returns (RewardSummary memory) {
        VToken[] memory vTokens = comptroller.getAllMarkets();
        ClaimVenusLocalVariables memory vars;
        RewardSummary memory rewardSummary;
        rewardSummary.distributorAddress = address(comptroller);
        rewardSummary.rewardTokenAddress = comptroller.getXVSAddress();
        rewardSummary.totalRewards = comptroller.venusAccrued(holder);
        rewardSummary.pendingRewards = new PendingReward[](vTokens.length);
        for (uint i; i < vTokens.length; ++i) {
            (vars.borrowIndex, vars.borrowBlock) = comptroller.venusBorrowState(address(vTokens[i]));
            VenusMarketState memory borrowState = VenusMarketState({
                index: vars.borrowIndex,
                block: vars.borrowBlock
            });

            (vars.supplyIndex, vars.supplyBlock) = comptroller.venusSupplyState(address(vTokens[i]));
            VenusMarketState memory supplyState = VenusMarketState({
                index: vars.supplyIndex,
                block: vars.supplyBlock
            });

            Exp memory borrowIndex = Exp({ mantissa: vTokens[i].borrowIndex() });

            PendingReward memory marketReward;
            marketReward.vTokenAddress = address(vTokens[i]);

            updateVenusBorrowIndex(borrowState, address(vTokens[i]), borrowIndex, comptroller);
            uint256 borrowReward = distributeBorrowerVenus(
                borrowState,
                address(vTokens[i]),
                holder,
                borrowIndex,
                comptroller
            );

            updateVenusSupplyIndex(supplyState, address(vTokens[i]), comptroller);
            uint256 supplyReward = distributeSupplierVenus(supplyState, address(vTokens[i]), holder, comptroller);

            marketReward.amount = add_(borrowReward, supplyReward);
            rewardSummary.pendingRewards[i] = marketReward;
        }
        return rewardSummary;
    }

    // utilities
    /**
     * @notice Compares if two strings are equal
     * @param a First string to compare
     * @param b Second string to compare
     * @return Boolean depending on if the strings are equal
     */
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

pragma solidity ^0.5.16;

import "../Tokens/VTokens/VToken.sol";

contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
     * @notice Get the underlying price of a vToken asset
     * @param vToken The vToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(VToken vToken) external view returns (uint);
}

pragma solidity ^0.5.16;

import "../Utils/SafeMath.sol";

// Mock import
import { GovernorBravoDelegate } from "@venusprotocol/governance-contracts/contracts/Governance/GovernorBravoDelegate.sol";

interface BEP20Base {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);
}

contract BEP20 is BEP20Base {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract BEP20NS is BEP20Base {
    function transfer(address to, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;
}

/**
 * @title Standard BEP20 token
 * @dev Implementation of the basic standard token.
 *  See https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is BEP20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public {
        totalSupply = _initialAmount;
        balanceOf[msg.sender] = _initialAmount;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        allowance[src][msg.sender] = allowance[src][msg.sender].sub(amount, "Insufficient allowance");
        balanceOf[src] = balanceOf[src].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(src, dst, amount);
        return true;
    }

    function approve(address _spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }
}

/**
 * @title Non-Standard BEP20 token
 * @dev Version of BEP20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
contract NonStandardToken is BEP20NS {
    using SafeMath for uint256;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public {
        totalSupply = _initialAmount;
        balanceOf[msg.sender] = _initialAmount;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
    }

    function transfer(address dst, uint256 amount) external {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(msg.sender, dst, amount);
    }

    function transferFrom(address src, address dst, uint256 amount) external {
        allowance[src][msg.sender] = allowance[src][msg.sender].sub(amount, "Insufficient allowance");
        balanceOf[src] = balanceOf[src].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(src, dst, amount);
    }

    function approve(address _spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }
}

contract BEP20Harness is StandardToken {
    // To support testing, we can specify addresses for which transferFrom should fail and return false
    mapping(address => bool) public failTransferFromAddresses;

    // To support testing, we allow the contract to always fail `transfer`.
    mapping(address => bool) public failTransferToAddresses;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public StandardToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {}

    function harnessSetFailTransferFromAddress(address src, bool _fail) public {
        failTransferFromAddresses[src] = _fail;
    }

    function harnessSetFailTransferToAddress(address dst, bool _fail) public {
        failTransferToAddresses[dst] = _fail;
    }

    function harnessSetBalance(address _account, uint _amount) public {
        balanceOf[_account] = _amount;
    }

    function transfer(address dst, uint256 amount) external returns (bool success) {
        // Added for testing purposes
        if (failTransferToAddresses[dst]) {
            return false;
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amount) external returns (bool success) {
        // Added for testing purposes
        if (failTransferFromAddresses[src]) {
            return false;
        }
        allowance[src][msg.sender] = allowance[src][msg.sender].sub(amount, "Insufficient allowance");
        balanceOf[src] = balanceOf[src].sub(amount, "Insufficient balance");
        balanceOf[dst] = balanceOf[dst].add(amount, "Balance overflow");
        emit Transfer(src, dst, amount);
        return true;
    }
}

pragma solidity ^0.5.16;

import "./ComptrollerMock.sol";
import "../Oracle/PriceOracle.sol";
import "../Comptroller/Unitroller.sol";

contract ComptrollerHarness is ComptrollerMock {
    address internal xvsAddress;
    address internal vXVSAddress;
    uint public blockNumber;

    constructor() public ComptrollerMock() {}

    function setVenusSupplyState(address vToken, uint224 index, uint32 blockNumber_) public {
        venusSupplyState[vToken].index = index;
        venusSupplyState[vToken].block = blockNumber_;
    }

    function setVenusBorrowState(address vToken, uint224 index, uint32 blockNumber_) public {
        venusBorrowState[vToken].index = index;
        venusBorrowState[vToken].block = blockNumber_;
    }

    function setVenusAccrued(address user, uint userAccrued) public {
        venusAccrued[user] = userAccrued;
    }

    function setXVSAddress(address xvsAddress_) public {
        xvsAddress = xvsAddress_;
    }

    function setXVSVTokenAddress(address vXVSAddress_) public {
        vXVSAddress = vXVSAddress_;
    }

    /**
     * @notice Set the amount of XVS distributed per block
     * @param venusRate_ The amount of XVS wei per block to distribute
     */
    function harnessSetVenusRate(uint venusRate_) public {
        venusRate = venusRate_;
    }

    /**
     * @notice Recalculate and update XVS speeds for all XVS markets
     */
    function harnessRefreshVenusSpeeds() public {
        VToken[] memory allMarkets_ = allMarkets;

        for (uint i = 0; i < allMarkets_.length; i++) {
            VToken vToken = allMarkets_[i];
            Exp memory borrowIndex = Exp({ mantissa: vToken.borrowIndex() });
            updateVenusSupplyIndex(address(vToken));
            updateVenusBorrowIndex(address(vToken), borrowIndex);
        }

        Exp memory totalUtility = Exp({ mantissa: 0 });
        Exp[] memory utilities = new Exp[](allMarkets_.length);
        for (uint i = 0; i < allMarkets_.length; i++) {
            VToken vToken = allMarkets_[i];
            if (venusSpeeds[address(vToken)] > 0) {
                Exp memory assetPrice = Exp({ mantissa: oracle.getUnderlyingPrice(vToken) });
                Exp memory utility = mul_(assetPrice, vToken.totalBorrows());
                utilities[i] = utility;
                totalUtility = add_(totalUtility, utility);
            }
        }

        for (uint i = 0; i < allMarkets_.length; i++) {
            VToken vToken = allMarkets[i];
            uint newSpeed = totalUtility.mantissa > 0 ? mul_(venusRate, div_(utilities[i], totalUtility)) : 0;
            setVenusSpeedInternal(vToken, newSpeed, newSpeed);
        }
    }

    function setVenusBorrowerIndex(address vToken, address borrower, uint index) public {
        venusBorrowerIndex[vToken][borrower] = index;
    }

    function setVenusSupplierIndex(address vToken, address supplier, uint index) public {
        venusSupplierIndex[vToken][supplier] = index;
    }

    function harnessDistributeAllBorrowerVenus(
        address vToken,
        address borrower,
        uint marketBorrowIndexMantissa
    ) public {
        distributeBorrowerVenus(vToken, borrower, Exp({ mantissa: marketBorrowIndexMantissa }));
        venusAccrued[borrower] = grantXVSInternal(borrower, venusAccrued[borrower], 0, false);
    }

    function harnessDistributeAllSupplierVenus(address vToken, address supplier) public {
        distributeSupplierVenus(vToken, supplier);
        venusAccrued[supplier] = grantXVSInternal(supplier, venusAccrued[supplier], 0, false);
    }

    function harnessUpdateVenusBorrowIndex(address vToken, uint marketBorrowIndexMantissa) public {
        updateVenusBorrowIndex(vToken, Exp({ mantissa: marketBorrowIndexMantissa }));
    }

    function harnessUpdateVenusSupplyIndex(address vToken) public {
        updateVenusSupplyIndex(vToken);
    }

    function harnessDistributeBorrowerVenus(address vToken, address borrower, uint marketBorrowIndexMantissa) public {
        distributeBorrowerVenus(vToken, borrower, Exp({ mantissa: marketBorrowIndexMantissa }));
    }

    function harnessDistributeSupplierVenus(address vToken, address supplier) public {
        distributeSupplierVenus(vToken, supplier);
    }

    function harnessTransferVenus(address user, uint userAccrued, uint threshold) public returns (uint) {
        if (userAccrued > 0 && userAccrued >= threshold) {
            return grantXVSInternal(user, userAccrued, 0, false);
        }
        return userAccrued;
    }

    function harnessAddVenusMarkets(address[] memory vTokens) public {
        for (uint i = 0; i < vTokens.length; i++) {
            // temporarily set venusSpeed to 1 (will be fixed by `harnessRefreshVenusSpeeds`)
            setVenusSpeedInternal(VToken(vTokens[i]), 1, 1);
        }
    }

    function harnessSetMintedVAIs(address user, uint amount) public {
        mintedVAIs[user] = amount;
    }

    function harnessFastForward(uint blocks) public returns (uint) {
        blockNumber += blocks;
        return blockNumber;
    }

    function setBlockNumber(uint number) public {
        blockNumber = number;
    }

    function getBlockNumber() internal view returns (uint) {
        return blockNumber;
    }

    function getVenusMarkets() public view returns (address[] memory) {
        uint m = allMarkets.length;
        uint n = 0;
        for (uint i = 0; i < m; i++) {
            if (venusSpeeds[address(allMarkets[i])] > 0) {
                n++;
            }
        }

        address[] memory venusMarkets = new address[](n);
        uint k = 0;
        for (uint i = 0; i < m; i++) {
            if (venusSpeeds[address(allMarkets[i])] > 0) {
                venusMarkets[k++] = address(allMarkets[i]);
            }
        }
        return venusMarkets;
    }

    function harnessSetReleaseStartBlock(uint startBlock) external {
        releaseStartBlock = startBlock;
    }

    function harnessAddVtoken(address vToken) external {
        markets[vToken] = Market({ isListed: true, isVenus: false, collateralFactorMantissa: 0 });
    }
}

contract EchoTypesComptroller is UnitrollerAdminStorage {
    function stringy(string memory s) public pure returns (string memory) {
        return s;
    }

    function addresses(address a) public pure returns (address) {
        return a;
    }

    function booly(bool b) public pure returns (bool) {
        return b;
    }

    function listOInts(uint[] memory u) public pure returns (uint[] memory) {
        return u;
    }

    function reverty() public pure {
        require(false, "gotcha sucka");
    }

    function becomeBrains(address payable unitroller) public {
        Unitroller(unitroller)._acceptImplementation();
    }
}

pragma solidity ^0.5.16;

import "../Comptroller/Diamond/facets/MarketFacet.sol";
import "../Comptroller/Diamond/facets/PolicyFacet.sol";
import "../Comptroller/Diamond/facets/RewardFacet.sol";
import "../Comptroller/Diamond/facets/SetterFacet.sol";
import "../Comptroller/Unitroller.sol";

// This contract contains all methods of Comptroller implementation in different facets at one place for testing purpose
// This contract does not have diamond functionality(i.e delegate call to facets methods)
contract ComptrollerMock is MarketFacet, PolicyFacet, RewardFacet, SetterFacet {
    constructor() public {
        admin = msg.sender;
    }

    function _become(Unitroller unitroller) public {
        require(msg.sender == unitroller.admin(), "only unitroller admin can");
        require(unitroller._acceptImplementation() == 0, "not authorized");
    }

    function _setComptrollerLens(ComptrollerLensInterface comptrollerLens_) external returns (uint) {
        ensureAdmin();
        ensureNonzeroAddress(address(comptrollerLens_));
        address oldComptrollerLens = address(comptrollerLens);
        comptrollerLens = comptrollerLens_;
        emit NewComptrollerLens(oldComptrollerLens, address(comptrollerLens));

        return uint(Error.NO_ERROR);
    }
}

pragma solidity ^0.5.16;

import "./ComptrollerMock.sol";

contract ComptrollerScenario is ComptrollerMock {
    uint public blockNumber;
    address public xvsAddress;
    address public vaiAddress;

    constructor() public ComptrollerMock() {}

    function setXVSAddress(address xvsAddress_) public {
        xvsAddress = xvsAddress_;
    }

    // function getXVSAddress() public view returns (address) {
    //     return xvsAddress;
    // }

    function setVAIAddress(address vaiAddress_) public {
        vaiAddress = vaiAddress_;
    }

    function getVAIAddress() public view returns (address) {
        return vaiAddress;
    }

    function membershipLength(VToken vToken) public view returns (uint) {
        return accountAssets[address(vToken)].length;
    }

    function fastForward(uint blocks) public returns (uint) {
        blockNumber += blocks;

        return blockNumber;
    }

    function setBlockNumber(uint number) public {
        blockNumber = number;
    }

    function getBlockNumber() internal view returns (uint) {
        return blockNumber;
    }

    function getVenusMarkets() public view returns (address[] memory) {
        uint m = allMarkets.length;
        uint n = 0;
        for (uint i = 0; i < m; i++) {
            if (markets[address(allMarkets[i])].isVenus) {
                n++;
            }
        }

        address[] memory venusMarkets = new address[](n);
        uint k = 0;
        for (uint i = 0; i < m; i++) {
            if (markets[address(allMarkets[i])].isVenus) {
                venusMarkets[k++] = address(allMarkets[i]);
            }
        }
        return venusMarkets;
    }

    function unlist(VToken vToken) public {
        markets[address(vToken)].isListed = false;
    }

    /**
     * @notice Recalculate and update XVS speeds for all XVS markets
     */
    function refreshVenusSpeeds() public {
        VToken[] memory allMarkets_ = allMarkets;

        for (uint i = 0; i < allMarkets_.length; i++) {
            VToken vToken = allMarkets_[i];
            Exp memory borrowIndex = Exp({ mantissa: vToken.borrowIndex() });
            updateVenusSupplyIndex(address(vToken));
            updateVenusBorrowIndex(address(vToken), borrowIndex);
        }

        Exp memory totalUtility = Exp({ mantissa: 0 });
        Exp[] memory utilities = new Exp[](allMarkets_.length);
        for (uint i = 0; i < allMarkets_.length; i++) {
            VToken vToken = allMarkets_[i];
            if (venusSpeeds[address(vToken)] > 0) {
                Exp memory assetPrice = Exp({ mantissa: oracle.getUnderlyingPrice(vToken) });
                Exp memory utility = mul_(assetPrice, vToken.totalBorrows());
                utilities[i] = utility;
                totalUtility = add_(totalUtility, utility);
            }
        }

        for (uint i = 0; i < allMarkets_.length; i++) {
            VToken vToken = allMarkets[i];
            uint newSpeed = totalUtility.mantissa > 0 ? mul_(venusRate, div_(utilities[i], totalUtility)) : 0;
            setVenusSpeedInternal(vToken, newSpeed, newSpeed);
        }
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../Comptroller/Diamond/Diamond.sol";

contract DiamondHarness is Diamond {
    function getFacetAddress(bytes4 sig) public view returns (address) {
        address facet = _selectorToFacetAndPosition[sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        return facet;
    }
}

pragma solidity ^0.5.16;

import "./FaucetToken.sol";

/**
 * @title The Venus Evil Test Token
 * @author Venus
 * @notice A simple test token that fails certain operations
 */
contract EvilToken is FaucetToken {
    bool public fail;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public FaucetToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {
        fail = true;
    }

    function setFail(bool _fail) external {
        fail = _fail;
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        if (fail) {
            return false;
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        balanceOf[dst] = balanceOf[dst].add(amount);
        emit Transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        if (fail) {
            return false;
        }
        balanceOf[src] = balanceOf[src].sub(amount);
        balanceOf[dst] = balanceOf[dst].add(amount);
        allowance[src][msg.sender] = allowance[src][msg.sender].sub(amount);
        emit Transfer(src, dst, amount);
        return true;
    }
}

pragma solidity ^0.5.16;

import "../Tokens/VTokens/VTokenInterfaces.sol";

/**
 * @title Venus's VBep20Delegator Contract
 * @notice VTokens which wrap an EIP-20 underlying and delegate to an implementation
 * @author Venus
 */
contract EvilXDelegator is VTokenInterface, VBep20Interface, VDelegatorInterface {
    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ BEP-20 name of this token
     * @param symbol_ BEP-20 symbol of this token
     * @param decimals_ BEP-20 decimal precision of this token
     * @param admin_ Address of the administrator of this token
     * @param implementation_ The address of the implementation the contract delegates to
     * @param becomeImplementationData The encoded args for becomeImplementation
     */
    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_,
        address implementation_,
        bytes memory becomeImplementationData
    ) public {
        // Creator of the contract is admin during initialization
        admin = msg.sender;

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(
            implementation_,
            abi.encodeWithSignature(
                "initialize(address,address,address,uint256,string,string,uint8)",
                underlying_,
                comptroller_,
                interestRateModel_,
                initialExchangeRateMantissa_,
                name_,
                symbol_,
                decimals_
            )
        );

        // New implementations always get set via the settor (post-initialize)
        _setImplementation(implementation_, false, becomeImplementationData);

        // Set the proper admin now that initialization is done
        admin = admin_;
    }

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) public {
        require(msg.sender == admin, "VBep20Delegator::_setImplementation: Caller must be admin");

        if (allowResign) {
            delegateToImplementation(abi.encodeWithSignature("_resignImplementation()"));
        }

        address oldImplementation = implementation;
        implementation = implementation_;

        delegateToImplementation(abi.encodeWithSignature("_becomeImplementation(bytes)", becomeImplementationData));

        emit NewImplementation(oldImplementation, implementation);
    }

    /**
     * @notice Sender supplies assets into the market and receives vTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint256 mintAmount) external returns (uint256) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("mint(uint256)", mintAmount));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Sender supplies assets into the market and receiver receives vTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mintBehalf(address receiver, uint256 mintAmount) external returns (uint256) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("mintBehalf(address,uint256)", receiver, mintAmount)
        );
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Sender redeems vTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of vTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint256 redeemTokens) external returns (uint256) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("redeem(uint256)", redeemTokens));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Sender redeems vTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("redeemUnderlying(uint256)", redeemAmount)
        );
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function borrow(uint256 borrowAmount) external returns (uint256) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("borrow(uint256)", borrowAmount));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint256 repayAmount) external returns (uint256) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("repayBorrow(uint256)", repayAmount));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("repayBorrowBehalf(address,uint256)", borrower, repayAmount)
        );
        return abi.decode(data, (uint256));
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this vToken to be liquidated
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral
    ) external returns (uint256) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("liquidateBorrow(address,uint256,address)", borrower, repayAmount, vTokenCollateral)
        );
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("transfer(address,uint256)", dst, amount));
        return abi.decode(data, (bool));
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", src, dst, amount)
        );
        return abi.decode(data, (bool));
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("approve(address,uint256)", spender, amount)
        );
        return abi.decode(data, (bool));
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("allowance(address,address)", owner, spender)
        );
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("balanceOf(address)", owner));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("balanceOfUnderlying(address)", owner));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by comptroller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (possible error, token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account) external view returns (uint256, uint256, uint256, uint256) {
        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("getAccountSnapshot(address)", account)
        );
        return abi.decode(data, (uint256, uint256, uint256, uint256));
    }

    /**
     * @notice Returns the current per-block borrow interest rate for this vToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint256) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("borrowRatePerBlock()"));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Returns the current per-block supply interest rate for this vToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint256) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("supplyRatePerBlock()"));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external returns (uint256) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("totalBorrowsCurrent()"));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external returns (uint256) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("borrowBalanceCurrent(address)", account));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) public view returns (uint256) {
        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("borrowBalanceStored(address)", account)
        );
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() public returns (uint256) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("exchangeRateCurrent()"));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the VToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() public view returns (uint256) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("exchangeRateStored()"));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Get cash balance of this vToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint256) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("getCash()"));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Applies accrued interest to total borrows and reserves.
     * @dev This calculates interest accrued from the last checkpointed block
     *      up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() public returns (uint256) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("accrueInterest()"));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Will fail unless called by another vToken during the process of liquidation.
     *  Its absolutely critical to use msg.sender as the borrowed vToken and not a parameter.
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of vTokens to seize
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function seize(address liquidator, address borrower, uint256 seizeTokens) external returns (uint256) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("seize(address,address,uint256)", liquidator, borrower, seizeTokens)
        );
        return abi.decode(data, (uint256));
    }

    /*** Admin Functions ***/

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("_setPendingAdmin(address)", newPendingAdmin)
        );
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Sets a new comptroller for the market
     * @dev Admin function to set a new comptroller
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setComptroller(ComptrollerInterface newComptroller) public returns (uint256) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("_setComptroller(address)", newComptroller)
        );
        return abi.decode(data, (uint256));
    }

    /**
     * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
     * @dev Admin function to accrue interest and set a new reserve factor
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("_setReserveFactor(uint256)", newReserveFactorMantissa)
        );
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptAdmin() external returns (uint256) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_acceptAdmin()"));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Accrues interest and adds reserves by transferring from admin
     * @param addAmount Amount of reserves to add
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _addReserves(uint256 addAmount) external returns (uint256) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_addReserves(uint256)", addAmount));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Accrues interest and reduces reserves by transferring to admin
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReserves(uint256 reduceAmount) external returns (uint256) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_reduceReserves(uint256)", reduceAmount));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Accrues interest and updates the interest rate model using _setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint256) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("_setInterestRateModel(address)", newInterestRateModel)
        );
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }

    /**
     * @notice Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        return delegateTo(implementation, data);
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(
            abi.encodeWithSignature("delegateToImplementation(bytes)", data)
        );
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return abi.decode(returnData, (bytes));
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    function() external payable {
        require(msg.value == 0, "VBep20Delegator:fallback: cannot send value to fallback");

        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize)
            }
            default {
                return(free_mem_ptr, returndatasize)
            }
        }
    }
}

pragma solidity ^0.5.16;

import "../Tokens/VTokens/VBep20Immutable.sol";
import "../Tokens/VTokens/VBep20Delegator.sol";
import "../Tokens/VTokens/VBep20Delegate.sol";
import "./ComptrollerScenario.sol";
import "../Comptroller/ComptrollerInterface.sol";

contract VBep20Scenario is VBep20Immutable {
    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_
    )
        public
        VBep20Immutable(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_,
            admin_
        )
    {}

    function setTotalBorrows(uint totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function setTotalReserves(uint totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function getBlockNumber() internal view returns (uint) {
        ComptrollerScenario comptrollerScenario = ComptrollerScenario(address(comptroller));
        return comptrollerScenario.blockNumber();
    }
}

// doTransferOut method of this token supposed to be compromised and contians malicious code which
// can be used by attacker to compromise the protocol working.
contract EvilXToken is VBep20Delegate {
    event Log(string x, address y);
    event Log(string x, uint y);
    event LogLiquidity(uint liquidity);

    uint internal blockNumber = 100000;
    uint internal harnessExchangeRate;
    bool internal harnessExchangeRateStored;

    address public comptrollerAddress;

    mapping(address => bool) public failTransferToAddresses;

    function setComptrollerAddress(address _comptrollerAddress) external {
        comptrollerAddress = _comptrollerAddress;
    }

    function exchangeRateStoredInternal() internal view returns (MathError, uint) {
        if (harnessExchangeRateStored) {
            return (MathError.NO_ERROR, harnessExchangeRate);
        }
        return super.exchangeRateStoredInternal();
    }

    function doTransferOut(address payable to, uint amount) internal {
        require(failTransferToAddresses[to] == false, "TOKEN_TRANSFER_OUT_FAILED");
        super.doTransferOut(to, amount);

        // Checking the Liquidity of the user after the tranfer.
        // solhint-disable-next-line no-unused-vars
        (uint errorCode, uint liquidity, uint shortfall) = ComptrollerInterface(comptrollerAddress).getAccountLiquidity(
            msg.sender
        );
        emit LogLiquidity(liquidity);
        return;
    }

    function getBlockNumber() internal view returns (uint) {
        return blockNumber;
    }

    function getBorrowRateMaxMantissa() public pure returns (uint) {
        return borrowRateMaxMantissa;
    }

    function harnessSetBlockNumber(uint newBlockNumber) public {
        blockNumber = newBlockNumber;
    }

    function harnessFastForward(uint blocks) public {
        blockNumber += blocks;
    }

    function harnessSetBalance(address account, uint amount) external {
        accountTokens[account] = amount;
    }

    function harnessSetAccrualBlockNumber(uint _accrualblockNumber) public {
        accrualBlockNumber = _accrualblockNumber;
    }

    function harnessSetTotalSupply(uint totalSupply_) public {
        totalSupply = totalSupply_;
    }

    function harnessSetTotalBorrows(uint totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function harnessIncrementTotalBorrows(uint addtlBorrow_) public {
        totalBorrows = totalBorrows + addtlBorrow_;
    }

    function harnessSetTotalReserves(uint totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function harnessExchangeRateDetails(uint totalSupply_, uint totalBorrows_, uint totalReserves_) public {
        totalSupply = totalSupply_;
        totalBorrows = totalBorrows_;
        totalReserves = totalReserves_;
    }

    function harnessSetExchangeRate(uint exchangeRate) public {
        harnessExchangeRate = exchangeRate;
        harnessExchangeRateStored = true;
    }

    function harnessSetFailTransferToAddress(address _to, bool _fail) public {
        failTransferToAddresses[_to] = _fail;
    }

    function harnessMintFresh(address account, uint mintAmount) public returns (uint) {
        (uint err, ) = super.mintFresh(account, mintAmount);
        return err;
    }

    function harnessMintBehalfFresh(address payer, address receiver, uint mintAmount) public returns (uint) {
        (uint err, ) = super.mintBehalfFresh(payer, receiver, mintAmount);
        return err;
    }

    function harnessRedeemFresh(
        address payable account,
        uint vTokenAmount,
        uint underlyingAmount
    ) public returns (uint) {
        return super.redeemFresh(account, account, vTokenAmount, underlyingAmount);
    }

    function harnessAccountBorrows(address account) public view returns (uint principal, uint interestIndex) {
        BorrowSnapshot memory snapshot = accountBorrows[account];
        return (snapshot.principal, snapshot.interestIndex);
    }

    function harnessSetAccountBorrows(address account, uint principal, uint interestIndex) public {
        accountBorrows[account] = BorrowSnapshot({ principal: principal, interestIndex: interestIndex });
    }

    function harnessSetBorrowIndex(uint borrowIndex_) public {
        borrowIndex = borrowIndex_;
    }

    function harnessBorrowFresh(address payable account, uint borrowAmount) public returns (uint) {
        return borrowFresh(account, account, borrowAmount);
    }

    function harnessRepayBorrowFresh(address payer, address account, uint repayAmount) public returns (uint) {
        (uint err, ) = repayBorrowFresh(payer, account, repayAmount);
        return err;
    }

    function harnessLiquidateBorrowFresh(
        address liquidator,
        address borrower,
        uint repayAmount,
        VToken vTokenCollateral
    ) public returns (uint) {
        (uint err, ) = liquidateBorrowFresh(liquidator, borrower, repayAmount, vTokenCollateral);
        return err;
    }

    function harnessReduceReservesFresh(uint amount) public returns (uint) {
        return _reduceReservesFresh(amount);
    }

    function harnessSetReserveFactorFresh(uint newReserveFactorMantissa) public returns (uint) {
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    function harnessSetInterestRateModelFresh(InterestRateModel newInterestRateModel) public returns (uint) {
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    function harnessSetInterestRateModel(address newInterestRateModelAddress) public {
        interestRateModel = InterestRateModel(newInterestRateModelAddress);
    }

    function harnessCallBorrowAllowed(uint amount) public returns (uint) {
        return comptroller.borrowAllowed(address(this), msg.sender, amount);
    }
}

pragma solidity ^0.5.16;

import "../Tokens/EIP20NonStandardInterface.sol";

/**
 * @title Fauceteer
 * @author Venus
 * @notice First computer program to be part of The Giving Pledge
 */
contract Fauceteer {
    /**
     * @notice Drips some tokens to caller
     * @dev We send 0.01% of our tokens to the caller. Over time, the amount will tend toward and eventually reach zero.
     * @param token The token to drip. Note: if we have no balance in this token, function will revert.
     */
    function drip(EIP20NonStandardInterface token) public {
        uint tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "Fauceteer is empty");
        token.transfer(msg.sender, tokenBalance / 10000); // 0.01%

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard BEP-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant BEP-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant BEP-20, revert.
                revert(0, 0)
            }
        }

        require(success, "Transfer returned false.");
    }
}

pragma solidity ^0.5.16;

import "./BEP20.sol";

/**
 * @title The Venus Faucet Test Token
 * @author Venus
 * @notice A simple test token that lets anyone get more of it.
 */
contract FaucetToken is StandardToken {
    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public StandardToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {}

    function allocateTo(address _owner, uint256 value) public {
        balanceOf[_owner] += value;
        totalSupply += value;
        emit Transfer(address(this), _owner, value);
    }
}

/**
 * @title The Venus Faucet Test Token (non-standard)
 * @author Venus
 * @notice A simple test token that lets anyone get more of it.
 */
contract FaucetNonStandardToken is NonStandardToken {
    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public NonStandardToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {}

    function allocateTo(address _owner, uint256 value) public {
        balanceOf[_owner] += value;
        totalSupply += value;
        emit Transfer(address(this), _owner, value);
    }
}

/**
 * @title The Venus Faucet Re-Entrant Test Token
 * @author Venus
 * @notice A test token that is malicious and tries to re-enter callers
 */
contract FaucetTokenReEntrantHarness {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal totalSupply_;
    mapping(address => mapping(address => uint256)) internal allowance_;
    mapping(address => uint256) internal balanceOf_;

    bytes public reEntryCallData;
    string public reEntryFun;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        bytes memory _reEntryCallData,
        string memory _reEntryFun
    ) public {
        totalSupply_ = _initialAmount;
        balanceOf_[msg.sender] = _initialAmount;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
        reEntryCallData = _reEntryCallData;
        reEntryFun = _reEntryFun;
    }

    modifier reEnter(string memory funName) {
        string memory _reEntryFun = reEntryFun;
        if (compareStrings(_reEntryFun, funName)) {
            reEntryFun = ""; // Clear re-entry fun
            (bool success, bytes memory returndata) = msg.sender.call(reEntryCallData);
            assembly {
                if eq(success, 0) {
                    revert(add(returndata, 0x20), returndatasize())
                }
            }
        }

        _;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b)));
    }

    function allocateTo(address _owner, uint256 value) public {
        balanceOf_[_owner] += value;
        totalSupply_ += value;
        emit Transfer(address(this), _owner, value);
    }

    function totalSupply() public reEnter("totalSupply") returns (uint256) {
        return totalSupply_;
    }

    function allowance(address owner, address spender) public reEnter("allowance") returns (uint256 remaining) {
        return allowance_[owner][spender];
    }

    function approve(address spender, uint256 amount) public reEnter("approve") returns (bool success) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address owner) public reEnter("balanceOf") returns (uint256 balance) {
        return balanceOf_[owner];
    }

    function transfer(address dst, uint256 amount) public reEnter("transfer") returns (bool success) {
        _transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) public reEnter("transferFrom") returns (bool success) {
        _transfer(src, dst, amount);
        _approve(src, msg.sender, allowance_[src][msg.sender].sub(amount));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0), "sender should be valid address");
        require(owner != address(0), "owner should be valid address");
        allowance_[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address src, address dst, uint256 amount) internal {
        require(dst != address(0), "dst should be valid address");
        balanceOf_[src] = balanceOf_[src].sub(amount);
        balanceOf_[dst] = balanceOf_[dst].add(amount);
        emit Transfer(src, dst, amount);
    }
}

pragma solidity ^0.5.16;

import "./FaucetToken.sol";

/**
 * @title Fee Token
 * @author Venus
 * @notice A simple test token that charges fees on transfer. Used to mock USDT.
 */
contract FeeToken is FaucetToken {
    uint public basisPointFee;
    address public owner;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        uint _basisPointFee,
        address _owner
    ) public FaucetToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {
        basisPointFee = _basisPointFee;
        owner = _owner;
    }

    function transfer(address dst, uint amount) public returns (bool) {
        uint fee = amount.mul(basisPointFee).div(10000);
        uint net = amount.sub(fee);
        balanceOf[owner] = balanceOf[owner].add(fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        balanceOf[dst] = balanceOf[dst].add(net);
        emit Transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint amount) public returns (bool) {
        uint fee = amount.mul(basisPointFee).div(10000);
        uint net = amount.sub(fee);
        balanceOf[owner] = balanceOf[owner].add(fee);
        balanceOf[src] = balanceOf[src].sub(amount);
        balanceOf[dst] = balanceOf[dst].add(net);
        allowance[src][msg.sender] = allowance[src][msg.sender].sub(amount);
        emit Transfer(src, dst, amount);
        return true;
    }
}

pragma solidity ^0.5.16;

import "../Oracle/PriceOracle.sol";

contract FixedPriceOracle is PriceOracle {
    uint public price;

    constructor(uint _price) public {
        price = _price;
    }

    function getUnderlyingPrice(VToken vToken) public view returns (uint) {
        vToken;
        return price;
    }

    function assetPrices(address asset) public view returns (uint) {
        asset;
        return price;
    }
}

pragma solidity ^0.5.16;

import "../InterestRateModels/InterestRateModel.sol";

/**
 * @title An Interest Rate Model for tests that can be instructed to return a failure instead of doing a calculation
 * @author Venus
 */
contract InterestRateModelHarness is InterestRateModel {
    uint public constant opaqueBorrowFailureCode = 20;
    bool public failBorrowRate;
    uint public borrowRate;

    constructor(uint borrowRate_) public {
        borrowRate = borrowRate_;
    }

    function setFailBorrowRate(bool failBorrowRate_) public {
        failBorrowRate = failBorrowRate_;
    }

    function setBorrowRate(uint borrowRate_) public {
        borrowRate = borrowRate_;
    }

    function getBorrowRate(uint _cash, uint _borrows, uint _reserves) public view returns (uint) {
        _cash; // unused
        _borrows; // unused
        _reserves; // unused
        require(!failBorrowRate, "INTEREST_RATE_MODEL_ERROR");
        return borrowRate;
    }

    function getSupplyRate(
        uint _cash,
        uint _borrows,
        uint _reserves,
        uint _reserveFactor
    ) external view returns (uint) {
        _cash; // unused
        _borrows; // unused
        _reserves; // unused
        return borrowRate * (1 - _reserveFactor);
    }
}

pragma solidity ^0.5.16;

import "../Utils/SafeMath.sol";

contract DeflatingERC20 {
    using SafeMath for uint;

    string public constant name = "Deflating Test Token";
    string public constant symbol = "DTT";
    uint8 public constant decimals = 18;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor(uint _totalSupply) public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        _mint(msg.sender, _totalSupply);
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        uint burnAmount = value / 100;
        _burn(from, burnAmount);
        uint transferAmount = value.sub(burnAmount);
        balanceOf[from] = balanceOf[from].sub(transferAmount);
        balanceOf[to] = balanceOf[to].add(transferAmount);
        emit Transfer(from, to, transferAmount);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }
}

pragma solidity ^0.5.16;

import "../Tokens/VTokens/VToken.sol";

/**
 * @title Venus's vBNB Contract
 * @notice vToken which wraps BNB
 * @author Venus
 */
contract MockVBNB is VToken {
    /**
     * @notice Construct a new vBNB money market
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ BEP-20 name of this token
     * @param symbol_ BEP-20 symbol of this token
     * @param decimals_ BEP-20 decimal precision of this token
     * @param admin_ Address of the administrator of this token
     */
    constructor(
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_
    ) public {
        // Creator of the contract is admin during initialization
        admin = msg.sender;

        initialize(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

        // Set the proper admin now that initialization is done
        admin = admin_;
    }

    /**
     * @notice Send BNB to VBNB to mint
     */
    function() external payable {
        (uint err, ) = mintInternal(msg.value);
        requireNoError(err, "mint failed");
    }

    /*** User Interface ***/

    /**
     * @notice Sender supplies assets into the market and receives vTokens in exchange
     * @dev Reverts upon any failure
     */
    // @custom:event Emits Transfer event
    // @custom:event Emits Mint event
    function mint() external payable {
        (uint err, ) = mintInternal(msg.value);
        requireNoError(err, "mint failed");
    }

    /**
     * @notice Sender redeems vTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of vTokens to redeem into underlying
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Redeem event on success
    // @custom:event Emits Transfer event on success
    // @custom:event Emits RedeemFee when fee is charged by the treasury
    function redeem(uint redeemTokens) external returns (uint) {
        return redeemInternal(msg.sender, msg.sender, redeemTokens);
    }

    /**
     * @notice Sender redeems vTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Redeem event on success
    // @custom:event Emits Transfer event on success
    // @custom:event Emits RedeemFee when fee is charged by the treasury
    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        return redeemUnderlyingInternal(msg.sender, msg.sender, redeemAmount);
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Borrow event on success
    function borrow(uint borrowAmount) external returns (uint) {
        return borrowInternal(msg.sender, msg.sender, borrowAmount);
    }

    /**
     * @notice Sender repays their own borrow
     * @dev Reverts upon any failure
     */
    // @custom:event Emits RepayBorrow event on success
    function repayBorrow() external payable {
        (uint err, ) = repayBorrowInternal(msg.value);
        requireNoError(err, "repayBorrow failed");
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @dev Reverts upon any failure
     * @param borrower The account with the debt being payed off
     */
    // @custom:event Emits RepayBorrow event on success
    function repayBorrowBehalf(address borrower) external payable {
        (uint err, ) = repayBorrowBehalfInternal(borrower, msg.value);
        requireNoError(err, "repayBorrowBehalf failed");
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @dev Reverts upon any failure
     * @param borrower The borrower of this vToken to be liquidated
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     */
    // @custom:event Emit LiquidateBorrow event on success
    function liquidateBorrow(address borrower, VToken vTokenCollateral) external payable {
        (uint err, ) = liquidateBorrowInternal(borrower, msg.value, vTokenCollateral);
        requireNoError(err, "liquidateBorrow failed");
    }

    function setTotalReserves(uint totalReserves_) external payable {
        totalReserves = totalReserves_;
    }

    /*** Safe Token ***/

    /**
     * @notice Perform the actual transfer in, which is a no-op
     * @param from Address sending the BNB
     * @param amount Amount of BNB being sent
     * @return The actual amount of BNB transferred
     */
    function doTransferIn(address from, uint amount) internal returns (uint) {
        // Sanity checks
        require(msg.sender == from, "sender mismatch");
        require(msg.value == amount, "value mismatch");
        return amount;
    }

    function doTransferOut(address payable to, uint amount) internal {
        /* Send the BNB, with minimal gas and revert on failure */
        to.transfer(amount);
    }

    /**
     * @notice Gets balance of this contract in terms of BNB, before this message
     * @dev This excludes the value of the current message, if any
     * @return The quantity of BNB owned by this contract
     */
    function getCashPrior() internal view returns (uint) {
        (MathError err, uint startingBalance) = subUInt(address(this).balance, msg.value);
        require(err == MathError.NO_ERROR, "cash prior math error");
        return startingBalance;
    }

    function requireNoError(uint errCode, string memory message) internal pure {
        if (errCode == uint(Error.NO_ERROR)) {
            return;
        }

        bytes memory fullMessage = new bytes(bytes(message).length + 5);
        uint i;

        for (i = 0; i < bytes(message).length; i++) {
            fullMessage[i] = bytes(message)[i];
        }

        fullMessage[i + 0] = bytes1(uint8(32));
        fullMessage[i + 1] = bytes1(uint8(40));
        fullMessage[i + 2] = bytes1(uint8(48 + (errCode / 10)));
        fullMessage[i + 3] = bytes1(uint8(48 + (errCode % 10)));
        fullMessage[i + 4] = bytes1(uint8(41));

        require(errCode == uint(Error.NO_ERROR), string(fullMessage));
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    /**
     * @notice Reduces reserves by transferring to admin
     * @dev Requires fresh interest accrual
     * @param reduceAmount Amount of reduction to reserves
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function _reduceReservesFresh(uint reduceAmount) internal returns (uint) {
        // totalReserves - reduceAmount
        uint totalReservesNew;

        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.REDUCE_RESERVES_ADMIN_CHECK);
        }

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDUCE_RESERVES_FRESH_CHECK);
        }

        // Fail gracefully if protocol has insufficient underlying cash
        if (getCashPrior() < reduceAmount) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDUCE_RESERVES_CASH_NOT_AVAILABLE);
        }

        // Check reduceAmount ≤ reserves[n] (totalReserves)
        if (reduceAmount > totalReserves) {
            return fail(Error.BAD_INPUT, FailureInfo.REDUCE_RESERVES_VALIDATION);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        totalReservesNew = totalReserves - reduceAmount;

        // Store reserves[n+1] = reserves[n] - reduceAmount
        totalReserves = totalReservesNew;

        // // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        doTransferOut(admin, reduceAmount);

        emit ReservesReduced(admin, reduceAmount, totalReservesNew);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accrues interest and reduces reserves by transferring to admin
     * @param reduceAmount Amount of reduction to reserves
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits ReservesReduced event
    function _reduceReserves(uint reduceAmount) external nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
            return fail(Error(error), FailureInfo.REDUCE_RESERVES_ACCRUE_INTEREST_FAILED);
        }
        // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
        return _reduceReservesFresh(reduceAmount);
    }

    /**
     * @notice Applies accrued interest to total borrows and reserves
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    // @custom:event Emits AccrueInterest event
    function accrueInterest() public returns (uint) {
        /* Remember the initial block number */
        uint currentBlockNumber = getBlockNumber();
        uint accrualBlockNumberPrior = accrualBlockNumber;

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockNumberPrior == currentBlockNumber) {
            return uint(Error.NO_ERROR);
        }

        /* Read the previous values out of storage */
        uint cashPrior = getCashPrior();
        uint borrowsPrior = totalBorrows;
        uint reservesPrior = totalReserves;
        uint borrowIndexPrior = borrowIndex;

        /* Calculate the current borrow interest rate */
        uint borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
        require(borrowRateMantissa <= borrowRateMaxMantissa, "borrow rate is absurdly high");

        /* Calculate the number of blocks elapsed since the last accrual */
        (MathError mathErr, uint blockDelta) = subUInt(currentBlockNumber, accrualBlockNumberPrior);
        require(mathErr == MathError.NO_ERROR, "could not calculate block delta");

        /*
         * Calculate the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrowsNew = interestAccumulated + totalBorrows
         *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
         *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
         */

        Exp memory simpleInterestFactor;
        uint interestAccumulated;
        uint totalBorrowsNew;
        uint totalReservesNew;
        uint borrowIndexNew;

        (mathErr, simpleInterestFactor) = mulScalar(Exp({ mantissa: borrowRateMantissa }), blockDelta);
        if (mathErr != MathError.NO_ERROR) {
            return
                failOpaque(
                    Error.MATH_ERROR,
                    FailureInfo.ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
                    uint(mathErr)
                );
        }

        (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return
                failOpaque(
                    Error.MATH_ERROR,
                    FailureInfo.ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
                    uint(mathErr)
                );
        }

        (mathErr, totalBorrowsNew) = addUInt(interestAccumulated, borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return
                failOpaque(
                    Error.MATH_ERROR,
                    FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
                    uint(mathErr)
                );
        }

        (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(
            Exp({ mantissa: reserveFactorMantissa }),
            interestAccumulated,
            reservesPrior
        );
        if (mathErr != MathError.NO_ERROR) {
            return
                failOpaque(
                    Error.MATH_ERROR,
                    FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
                    uint(mathErr)
                );
        }

        (mathErr, borrowIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);
        if (mathErr != MathError.NO_ERROR) {
            return
                failOpaque(
                    Error.MATH_ERROR,
                    FailureInfo.ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
                    uint(mathErr)
                );
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        /* We emit an AccrueInterest event */
        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

        return uint(Error.NO_ERROR);
    }
}

pragma solidity ^0.5.16;

import "../Oracle/PriceOracle.sol";
import "../Tokens/VTokens/VBep20.sol";

contract SimplePriceOracle is PriceOracle {
    mapping(address => uint) internal prices;
    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

    function getUnderlyingPrice(VToken vToken) public view returns (uint) {
        if (compareStrings(vToken.symbol(), "vBNB")) {
            return 1e18;
        } else if (compareStrings(vToken.symbol(), "VAI")) {
            return prices[address(vToken)];
        } else {
            return prices[address(VBep20(address(vToken)).underlying())];
        }
    }

    function setUnderlyingPrice(VToken vToken, uint underlyingPriceMantissa) public {
        address asset = address(VBep20(address(vToken)).underlying());
        emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
        prices[asset] = underlyingPriceMantissa;
    }

    function setDirectPrice(address asset, uint price) public {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    // v1 price oracle interface for use as backing of proxy
    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

pragma solidity ^0.5.16;

import "../Tokens/VAI/VAIController.sol";

contract VAIControllerHarness is VAIController {
    uint public blockNumber;
    uint public blocksPerYear;

    constructor() public VAIController() {
        admin = msg.sender;
    }

    function setVenusVAIState(uint224 index, uint32 blockNumber_) public {
        venusVAIState.index = index;
        venusVAIState.block = blockNumber_;
    }

    function setVAIAddress(address vaiAddress_) public {
        vai = vaiAddress_;
    }

    function getVAIAddress() public view returns (address) {
        return vai;
    }

    function harnessRepayVAIFresh(address payer, address account, uint repayAmount) public returns (uint) {
        (uint err, ) = repayVAIFresh(payer, account, repayAmount);
        return err;
    }

    function harnessLiquidateVAIFresh(
        address liquidator,
        address borrower,
        uint repayAmount,
        VToken vTokenCollateral
    ) public returns (uint) {
        (uint err, ) = liquidateVAIFresh(liquidator, borrower, repayAmount, vTokenCollateral);
        return err;
    }

    function harnessFastForward(uint blocks) public returns (uint) {
        blockNumber += blocks;
        return blockNumber;
    }

    function harnessSetBlockNumber(uint newBlockNumber) public {
        blockNumber = newBlockNumber;
    }

    function setBlockNumber(uint number) public {
        blockNumber = number;
    }

    function setBlocksPerYear(uint number) public {
        blocksPerYear = number;
    }

    function getBlockNumber() internal view returns (uint) {
        return blockNumber;
    }

    function getBlocksPerYear() public view returns (uint) {
        return blocksPerYear;
    }
}

pragma solidity ^0.5.16;

import "../Tokens/VAI/VAI.sol";

contract VAIScenario is VAI {
    uint internal blockNumber = 100000;

    constructor(uint chainId) public VAI(chainId) {}

    function harnessFastForward(uint blocks) public {
        blockNumber += blocks;
    }

    function harnessSetTotalSupply(uint _totalSupply) public {
        totalSupply = _totalSupply;
    }

    function harnessIncrementTotalSupply(uint addtlSupply_) public {
        totalSupply = totalSupply + addtlSupply_;
    }

    function harnessSetBalanceOf(address account, uint _amount) public {
        balanceOf[account] = _amount;
    }

    function allocateTo(address _owner, uint256 value) public {
        balanceOf[_owner] += value;
        totalSupply += value;
        emit Transfer(address(this), _owner, value);
    }
}

pragma solidity ^0.5.16;

import "../Tokens/VTokens/VBep20Immutable.sol";
import "../Tokens/VTokens/VBep20Delegator.sol";
import "../Tokens/VTokens/VBep20Delegate.sol";
import "./ComptrollerScenario.sol";

contract VBep20Harness is VBep20Immutable {
    uint internal blockNumber = 100000;
    uint internal harnessExchangeRate;
    bool internal harnessExchangeRateStored;

    mapping(address => bool) public failTransferToAddresses;

    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_
    )
        public
        VBep20Immutable(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_,
            admin_
        )
    {}

    function doTransferOut(address payable to, uint amount) internal {
        require(failTransferToAddresses[to] == false, "TOKEN_TRANSFER_OUT_FAILED");
        return super.doTransferOut(to, amount);
    }

    function exchangeRateStoredInternal() internal view returns (MathError, uint) {
        if (harnessExchangeRateStored) {
            return (MathError.NO_ERROR, harnessExchangeRate);
        }
        return super.exchangeRateStoredInternal();
    }

    function getBlockNumber() internal view returns (uint) {
        return blockNumber;
    }

    function getBorrowRateMaxMantissa() public pure returns (uint) {
        return borrowRateMaxMantissa;
    }

    function harnessSetAccrualBlockNumber(uint _accrualblockNumber) public {
        accrualBlockNumber = _accrualblockNumber;
    }

    function harnessSetBlockNumber(uint newBlockNumber) public {
        blockNumber = newBlockNumber;
    }

    function harnessFastForward(uint blocks) public {
        blockNumber += blocks;
    }

    function harnessSetBalance(address account, uint amount) external {
        accountTokens[account] = amount;
    }

    function harnessSetTotalSupply(uint totalSupply_) public {
        totalSupply = totalSupply_;
    }

    function harnessSetTotalBorrows(uint totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function harnessSetTotalReserves(uint totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function harnessExchangeRateDetails(uint totalSupply_, uint totalBorrows_, uint totalReserves_) public {
        totalSupply = totalSupply_;
        totalBorrows = totalBorrows_;
        totalReserves = totalReserves_;
    }

    function harnessSetExchangeRate(uint exchangeRate) public {
        harnessExchangeRate = exchangeRate;
        harnessExchangeRateStored = true;
    }

    function harnessSetFailTransferToAddress(address _to, bool _fail) public {
        failTransferToAddresses[_to] = _fail;
    }

    function harnessMintFresh(address account, uint mintAmount) public returns (uint) {
        (uint err, ) = super.mintFresh(account, mintAmount);
        return err;
    }

    function harnessMintBehalfFresh(address payer, address receiver, uint mintAmount) public returns (uint) {
        (uint err, ) = super.mintBehalfFresh(payer, receiver, mintAmount);
        return err;
    }

    function harnessRedeemFresh(
        address payable account,
        uint vTokenAmount,
        uint underlyingAmount
    ) public returns (uint) {
        return super.redeemFresh(account, account, vTokenAmount, underlyingAmount);
    }

    function harnessAccountBorrows(address account) public view returns (uint principal, uint interestIndex) {
        BorrowSnapshot memory snapshot = accountBorrows[account];
        return (snapshot.principal, snapshot.interestIndex);
    }

    function harnessSetAccountBorrows(address account, uint principal, uint interestIndex) public {
        accountBorrows[account] = BorrowSnapshot({ principal: principal, interestIndex: interestIndex });
    }

    function harnessSetBorrowIndex(uint borrowIndex_) public {
        borrowIndex = borrowIndex_;
    }

    function harnessBorrowFresh(address payable account, uint borrowAmount) public returns (uint) {
        return borrowFresh(account, account, borrowAmount);
    }

    function harnessRepayBorrowFresh(address payer, address account, uint repayAmount) public returns (uint) {
        (uint err, ) = repayBorrowFresh(payer, account, repayAmount);
        return err;
    }

    function harnessLiquidateBorrowFresh(
        address liquidator,
        address borrower,
        uint repayAmount,
        VToken vTokenCollateral
    ) public returns (uint) {
        (uint err, ) = liquidateBorrowFresh(liquidator, borrower, repayAmount, vTokenCollateral);
        return err;
    }

    function harnessReduceReservesFresh(uint amount) public returns (uint) {
        return _reduceReservesFresh(amount);
    }

    function harnessSetReserveFactorFresh(uint newReserveFactorMantissa) public returns (uint) {
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    function harnessSetInterestRateModelFresh(InterestRateModel newInterestRateModel) public returns (uint) {
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    function harnessSetInterestRateModel(address newInterestRateModelAddress) public {
        interestRateModel = InterestRateModel(newInterestRateModelAddress);
    }

    function harnessCallBorrowAllowed(uint amount) public returns (uint) {
        return comptroller.borrowAllowed(address(this), msg.sender, amount);
    }
}

contract VBep20Scenario is VBep20Immutable {
    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_
    )
        public
        VBep20Immutable(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_,
            admin_
        )
    {}

    function setTotalBorrows(uint totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function setTotalReserves(uint totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function getBlockNumber() internal view returns (uint) {
        ComptrollerScenario comptrollerScenario = ComptrollerScenario(address(comptroller));
        return comptrollerScenario.blockNumber();
    }
}

contract VEvil is VBep20Scenario {
    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_
    )
        public
        VBep20Scenario(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_,
            admin_
        )
    {}

    function evilSeize(VToken treasure, address liquidator, address borrower, uint seizeTokens) public returns (uint) {
        return treasure.seize(liquidator, borrower, seizeTokens);
    }
}

contract VBep20DelegatorScenario is VBep20Delegator {
    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_,
        address implementation_,
        bytes memory becomeImplementationData
    )
        public
        VBep20Delegator(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_,
            admin_,
            implementation_,
            becomeImplementationData
        )
    {}

    function setTotalBorrows(uint totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function setTotalReserves(uint totalReserves_) public {
        totalReserves = totalReserves_;
    }
}

contract VBep20DelegateHarness is VBep20Delegate {
    event Log(string x, address y);
    event Log(string x, uint y);

    uint internal blockNumber = 100000;
    uint internal harnessExchangeRate;
    bool internal harnessExchangeRateStored;

    mapping(address => bool) public failTransferToAddresses;

    function exchangeRateStoredInternal() internal view returns (MathError, uint) {
        if (harnessExchangeRateStored) {
            return (MathError.NO_ERROR, harnessExchangeRate);
        }
        return super.exchangeRateStoredInternal();
    }

    function doTransferOut(address payable to, uint amount) internal {
        require(failTransferToAddresses[to] == false, "TOKEN_TRANSFER_OUT_FAILED");
        return super.doTransferOut(to, amount);
    }

    function getBlockNumber() internal view returns (uint) {
        return blockNumber;
    }

    function getBorrowRateMaxMantissa() public pure returns (uint) {
        return borrowRateMaxMantissa;
    }

    function harnessSetBlockNumber(uint newBlockNumber) public {
        blockNumber = newBlockNumber;
    }

    function harnessFastForward(uint blocks) public {
        blockNumber += blocks;
    }

    function harnessSetBalance(address account, uint amount) external {
        accountTokens[account] = amount;
    }

    function harnessSetAccrualBlockNumber(uint _accrualblockNumber) public {
        accrualBlockNumber = _accrualblockNumber;
    }

    function harnessSetTotalSupply(uint totalSupply_) public {
        totalSupply = totalSupply_;
    }

    function harnessSetTotalBorrows(uint totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function harnessIncrementTotalBorrows(uint addtlBorrow_) public {
        totalBorrows = totalBorrows + addtlBorrow_;
    }

    function harnessSetTotalReserves(uint totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function harnessExchangeRateDetails(uint totalSupply_, uint totalBorrows_, uint totalReserves_) public {
        totalSupply = totalSupply_;
        totalBorrows = totalBorrows_;
        totalReserves = totalReserves_;
    }

    function harnessSetExchangeRate(uint exchangeRate) public {
        harnessExchangeRate = exchangeRate;
        harnessExchangeRateStored = true;
    }

    function harnessSetFailTransferToAddress(address _to, bool _fail) public {
        failTransferToAddresses[_to] = _fail;
    }

    function harnessMintFresh(address account, uint mintAmount) public returns (uint) {
        (uint err, ) = super.mintFresh(account, mintAmount);
        return err;
    }

    function harnessMintBehalfFresh(address payer, address receiver, uint mintAmount) public returns (uint) {
        (uint err, ) = super.mintBehalfFresh(payer, receiver, mintAmount);
        return err;
    }

    function harnessRedeemFresh(
        address payable account,
        uint vTokenAmount,
        uint underlyingAmount
    ) public returns (uint) {
        return super.redeemFresh(account, account, vTokenAmount, underlyingAmount);
    }

    function harnessAccountBorrows(address account) public view returns (uint principal, uint interestIndex) {
        BorrowSnapshot memory snapshot = accountBorrows[account];
        return (snapshot.principal, snapshot.interestIndex);
    }

    function harnessSetAccountBorrows(address account, uint principal, uint interestIndex) public {
        accountBorrows[account] = BorrowSnapshot({ principal: principal, interestIndex: interestIndex });
    }

    function harnessSetBorrowIndex(uint borrowIndex_) public {
        borrowIndex = borrowIndex_;
    }

    function harnessBorrowFresh(address payable account, uint borrowAmount) public returns (uint) {
        return borrowFresh(account, account, borrowAmount);
    }

    function harnessRepayBorrowFresh(address payer, address account, uint repayAmount) public returns (uint) {
        (uint err, ) = repayBorrowFresh(payer, account, repayAmount);
        return err;
    }

    function harnessLiquidateBorrowFresh(
        address liquidator,
        address borrower,
        uint repayAmount,
        VToken vTokenCollateral
    ) public returns (uint) {
        (uint err, ) = liquidateBorrowFresh(liquidator, borrower, repayAmount, vTokenCollateral);
        return err;
    }

    function harnessReduceReservesFresh(uint amount) public returns (uint) {
        return _reduceReservesFresh(amount);
    }

    function harnessSetReserveFactorFresh(uint newReserveFactorMantissa) public returns (uint) {
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    function harnessSetInterestRateModelFresh(InterestRateModel newInterestRateModel) public returns (uint) {
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    function harnessSetInterestRateModel(address newInterestRateModelAddress) public {
        interestRateModel = InterestRateModel(newInterestRateModelAddress);
    }

    function harnessCallBorrowAllowed(uint amount) public returns (uint) {
        return comptroller.borrowAllowed(address(this), msg.sender, amount);
    }
}

contract VBep20DelegateScenario is VBep20Delegate {
    constructor() public {}

    function setTotalBorrows(uint totalBorrows_) public {
        totalBorrows = totalBorrows_;
    }

    function setTotalReserves(uint totalReserves_) public {
        totalReserves = totalReserves_;
    }

    function getBlockNumber() internal view returns (uint) {
        ComptrollerScenario comptrollerScenario = ComptrollerScenario(address(comptroller));
        return comptrollerScenario.blockNumber();
    }
}

contract VBep20DelegateScenarioExtra is VBep20DelegateScenario {
    function iHaveSpoken() public pure returns (string memory) {
        return "i have spoken";
    }

    function itIsTheWay() public {
        admin = address(1); // make a change to test effect
    }

    function babyYoda() public pure {
        revert("protect the baby");
    }
}

pragma solidity ^0.5.16;

import "../Tokens/VTokens/VToken.sol";

/**
 * @title Venus's VBep20 Contract
 * @notice VTokens which wrap an EIP-20 underlying
 * @author Venus
 */
contract VBep20MockDelegate is VToken, VBep20Interface {
    address public implementation;
    uint internal blockNumber = 100000;

    /**
     * @notice Initialize the new money market
     * @param underlying_ The address of the underlying asset
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ BEP-20 name of this token
     * @param symbol_ BEP-20 symbol of this token
     * @param decimals_ BEP-20 decimal precision of this token
     */
    function initialize(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public {
        // VToken initialize does the bulk of the work
        super.initialize(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

        // Set underlying and sanity check it
        underlying = underlying_;
        EIP20Interface(underlying).totalSupply();
    }

    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public {
        // Shh -- currently unused
        data;

        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _becomeImplementation");
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public {
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _resignImplementation");
    }

    function harnessFastForward(uint blocks) public {
        blockNumber += blocks;
    }

    /*** User Interface ***/

    /**
     * @notice Sender supplies assets into the market and receives vTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) external returns (uint) {
        (uint err, ) = mintInternal(mintAmount);
        return err;
    }

    /**
     * @notice Sender supplies assets into the market and receiver receives vTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param receiver the account which is receiving the vTokens
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mintBehalf(address receiver, uint mintAmount) external returns (uint) {
        (uint err, ) = mintBehalfInternal(receiver, mintAmount);
        return err;
    }

    /**
     * @notice Sender redeems vTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of vTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) external returns (uint) {
        return redeemInternal(msg.sender, msg.sender, redeemTokens);
    }

    /**
     * @notice Sender redeems vTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        return redeemUnderlyingInternal(msg.sender, msg.sender, redeemAmount);
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function borrow(uint borrowAmount) external returns (uint) {
        return borrowInternal(msg.sender, msg.sender, borrowAmount);
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint repayAmount) external returns (uint) {
        (uint err, ) = repayBorrowInternal(repayAmount);
        return err;
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint) {
        (uint err, ) = repayBorrowBehalfInternal(borrower, repayAmount);
        return err;
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this vToken to be liquidated
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function liquidateBorrow(
        address borrower,
        uint repayAmount,
        VTokenInterface vTokenCollateral
    ) external returns (uint) {
        (uint err, ) = liquidateBorrowInternal(borrower, repayAmount, vTokenCollateral);
        return err;
    }

    /**
     * @notice The sender adds to reserves.
     * @param addAmount The amount fo underlying token to add as reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _addReserves(uint addAmount) external returns (uint) {
        return _addReservesInternal(addAmount);
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() internal view returns (uint) {
        EIP20Interface token = EIP20Interface(underlying);
        return token.balanceOf(address(this));
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard BEP-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address from, uint amount) internal returns (uint) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
        uint balanceBefore = EIP20Interface(underlying).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard BEP-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant BEP-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant BEP-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint balanceAfter = EIP20Interface(underlying).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard BEP-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address payable to, uint amount) internal {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard BEP-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a complaint BEP-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant BEP-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}

pragma solidity ^0.5.16;

import "../../contracts/Tokens/VRT/VRTConverter.sol";

contract VRTConverterHarness is VRTConverter {
    constructor() public VRTConverter() {
        admin = msg.sender;
    }

    function balanceOfUser() public view returns (uint256, address) {
        uint256 vrtBalanceOfUser = vrt.balanceOf(msg.sender);
        return (vrtBalanceOfUser, msg.sender);
    }

    function setConversionRatio(uint256 _conversionRatio) public onlyAdmin {
        conversionRatio = _conversionRatio;
    }

    function setConversionTimeline(uint256 _conversionStartTime, uint256 _conversionPeriod) public onlyAdmin {
        conversionStartTime = _conversionStartTime;
        conversionPeriod = _conversionPeriod;
        conversionEndTime = conversionStartTime.add(conversionPeriod);
    }

    function getXVSRedeemedAmount(uint256 vrtAmount) public view returns (uint256) {
        return vrtAmount.mul(conversionRatio).mul(xvsDecimalsMultiplier).div(1e18).div(vrtDecimalsMultiplier);
    }
}

pragma solidity ^0.5.16;

import "../../contracts/VRTVault/VRTVault.sol";

contract VRTVaultHarness is VRTVault {
    uint public blockNumber;

    constructor() public VRTVault() {}

    function overrideInterestRatePerBlock(uint256 _interestRatePerBlock) public {
        interestRatePerBlock = _interestRatePerBlock;
    }

    function balanceOfUser() public view returns (uint256, address) {
        uint256 vrtBalanceOfUser = vrt.balanceOf(msg.sender);
        return (vrtBalanceOfUser, msg.sender);
    }

    function harnessFastForward(uint256 blocks) public returns (uint256) {
        blockNumber += blocks;
        return blockNumber;
    }

    function setBlockNumber(uint256 number) public {
        blockNumber = number;
    }

    function getBlockNumber() public view returns (uint256) {
        return blockNumber;
    }
}

pragma solidity ^0.5.16;

import "../Tokens/XVS/XVS.sol";

contract XVSScenario is XVS {
    constructor(address account) public XVS(account) {}

    function transferScenario(address[] calldata destinations, uint256 amount) external returns (bool) {
        for (uint i = 0; i < destinations.length; i++) {
            address dst = destinations[i];
            _transferTokens(msg.sender, dst, uint96(amount));
        }
        return true;
    }

    function transferFromScenario(address[] calldata froms, uint256 amount) external returns (bool) {
        for (uint i = 0; i < froms.length; i++) {
            address from = froms[i];
            _transferTokens(from, msg.sender, uint96(amount));
        }
        return true;
    }

    function generateCheckpoints(uint count, uint offset) external {
        for (uint i = 1 + offset; i <= count + offset; i++) {
            checkpoints[msg.sender][numCheckpoints[msg.sender]++] = Checkpoint(uint32(i), uint96(i));
        }
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../XVSVault/XVSVault.sol";

contract XVSVaultScenario is XVSVault {
    using SafeMath for uint256;

    constructor() public {
        admin = msg.sender;
    }

    function pushOldWithdrawalRequest(
        UserInfo storage _user,
        WithdrawalRequest[] storage _requests,
        uint _amount,
        uint _lockedUntil
    ) internal {
        uint i = _requests.length;
        _requests.push(WithdrawalRequest(0, 0, 0));
        // Keep it sorted so that the first to get unlocked request is always at the end
        for (; i > 0 && _requests[i - 1].lockedUntil <= _lockedUntil; --i) {
            _requests[i] = _requests[i - 1];
        }
        _requests[i] = WithdrawalRequest(_amount, uint128(_lockedUntil), 0);
        _user.pendingWithdrawals = _user.pendingWithdrawals.add(_amount);
    }

    function requestOldWithdrawal(address _rewardToken, uint256 _pid, uint256 _amount) external nonReentrant {
        _ensureValidPool(_rewardToken, _pid);
        require(_amount > 0, "requested amount cannot be zero");
        UserInfo storage user = userInfos[_rewardToken][_pid][msg.sender];
        require(user.amount >= user.pendingWithdrawals.add(_amount), "requested amount is invalid");

        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        WithdrawalRequest[] storage requests = withdrawalRequests[_rewardToken][_pid][msg.sender];
        uint lockedUntil = pool.lockPeriod.add(block.timestamp);

        pushOldWithdrawalRequest(user, requests, _amount, lockedUntil);

        // Update Delegate Amount
        if (_rewardToken == address(xvsAddress)) {
            _moveDelegates(delegates[msg.sender], address(0), uint96(_amount));
        }

        emit RequestedWithdrawal(msg.sender, _rewardToken, _pid, _amount);
    }

    function transferReward(address rewardToken, address user, uint256 amount) external {
        _transferReward(rewardToken, user, amount);
    }
}

pragma solidity ^0.5.16;

import "../../contracts/Tokens/XVS/XVSVesting.sol";

contract XVSVestingHarness is XVSVesting {
    address public constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    constructor() public XVSVesting() {
        admin = msg.sender;
    }

    uint public blockNumber;

    function recoverXVS(address recoveryAddress) public payable {
        uint256 xvsBalance = xvs.balanceOf(address(this));
        xvs.safeTransferFrom(address(this), recoveryAddress, xvsBalance);
    }

    function overWriteVRTConversionAddress() public {
        vrtConversionAddress = ZERO_ADDRESS;
    }

    function computeWithdrawableAmount(
        uint256 amount,
        uint256 vestingStartTime,
        uint256 withdrawnAmount
    ) public view returns (uint256 vestedAmount, uint256 toWithdraw) {
        (vestedAmount, toWithdraw) = super.calculateWithdrawableAmount(amount, vestingStartTime, withdrawnAmount);
        return (vestedAmount, toWithdraw);
    }

    function computeVestedAmount(
        uint256 vestingAmount,
        uint256 vestingStartTime,
        uint256 currentTime
    ) public view returns (uint256) {
        return super.calculateVestedAmount(vestingAmount, vestingStartTime, currentTime);
    }

    function getVestingCount(address beneficiary) public view returns (uint256) {
        return vestings[beneficiary].length;
    }

    function getVestedAmount(address recipient) public view nonZeroAddress(recipient) returns (uint256) {
        VestingRecord[] memory vestingsOfRecipient = vestings[recipient];
        uint256 vestingCount = vestingsOfRecipient.length;
        uint256 totalVestedAmount = 0;
        uint256 currentTime = getCurrentTime();

        for (uint i = 0; i < vestingCount; i++) {
            VestingRecord memory vesting = vestingsOfRecipient[i];
            uint256 vestedAmount = calculateVestedAmount(vesting.amount, vesting.startTime, currentTime);
            totalVestedAmount = totalVestedAmount.add(vestedAmount);
        }

        return totalVestedAmount;
    }
}

pragma solidity ^0.5.16;

/**
 * @title BEP 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return success whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return success whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return success whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity ^0.5.16;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of BEP20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {
    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance of the owner
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the BEP-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the BEP-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return success Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

/**
 * @title IPrime
 * @author Venus
 * @notice Interface for Prime Token
 */
interface IPrime {
    /**
     * @notice Executed by XVSVault whenever user's XVSVault balance changes
     * @param user the account address whose balance was updated
     */
    function xvsUpdated(address user) external;

    /**
     * @notice accrues interest and updates score for an user for a specific market
     * @param user the account address for which to accrue interest and update score
     * @param market the market for which to accrue interest and update score
     */
    function accrueInterestAndUpdateScore(address user, address market) external;

    /**
     * @notice Distributes income from market since last distribution
     * @param vToken the market for which to distribute the income
     */
    function accrueInterest(address vToken) external;

    /**
     * @notice Returns if user is a prime holder
     * @param isPrimeHolder returns if the user is a prime holder
     */
    function isUserPrimeHolder(address user) external view returns (bool isPrimeHolder);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.5.16;

contract LibNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed usr,
        bytes32 indexed arg1,
        bytes32 indexed arg2,
        bytes data
    ) anonymous;

    modifier note() {
        _;
        assembly {
            // log an 'anonymous' event with a constant 6 words of calldata
            // and four indexed topics: selector, caller, arg1 and arg2
            let mark := msize() // end of memory ensures zero
            mstore(0x40, add(mark, 288)) // update free memory pointer
            mstore(mark, 0x20) // bytes type data offset
            mstore(add(mark, 0x20), 224) // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224) // bytes payload
            log4(
                mark,
                288, // calldata
                shl(224, shr(224, calldataload(0))), // msg.sig
                caller(), // msg.sender
                calldataload(4), // arg1
                calldataload(36) // arg2
            )
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.5.16;

import "./lib.sol";

contract VAI is LibNote {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address guy) external note auth {
        wards[guy] = 1;
    }

    function deny(address guy) external note auth {
        wards[guy] = 0;
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "VAI/not-authorized");
        _;
    }

    // --- BEP20 Data ---
    string public constant name = "VAI Stablecoin";
    string public constant symbol = "VAI";
    string public constant version = "1";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);

    // --- Math ---
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "VAI math error");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "VAI math error");
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(uint256 chainId_) public {
        wards[msg.sender] = 1;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId_,
                address(this)
            )
        );
    }

    // --- Token ---
    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        require(balanceOf[src] >= wad, "VAI/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= wad, "VAI/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }

    function mint(address usr, uint256 wad) external auth {
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSupply = add(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }

    function burn(address usr, uint256 wad) external {
        require(balanceOf[usr] >= wad, "VAI/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != uint256(-1)) {
            require(allowance[usr][msg.sender] >= wad, "VAI/insufficient-allowance");
            allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], wad);
        }
        balanceOf[usr] = sub(balanceOf[usr], wad);
        totalSupply = sub(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }

    function approve(address usr, uint256 wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    // --- Alias ---
    function push(address usr, uint256 wad) external {
        transferFrom(msg.sender, usr, wad);
    }

    function pull(address usr, uint256 wad) external {
        transferFrom(usr, msg.sender, wad);
    }

    function move(address src, address dst, uint256 wad) external {
        transferFrom(src, dst, wad);
    }

    // --- Approve by signature ---
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, holder, spender, nonce, expiry, allowed))
            )
        );

        require(holder != address(0), "VAI/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "VAI/invalid-permit");
        require(expiry == 0 || now <= expiry, "VAI/permit-expired");
        require(nonce == nonces[holder]++, "VAI/invalid-nonce");
        uint256 wad = allowed ? uint256(-1) : 0;
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.5.16;

import { PriceOracle } from "../../Oracle/PriceOracle.sol";
import { VAIControllerErrorReporter } from "../../Utils/ErrorReporter.sol";
import { Exponential } from "../../Utils/Exponential.sol";
import { ComptrollerInterface } from "../../Comptroller/ComptrollerInterface.sol";
import { IAccessControlManagerV5 } from "@venusprotocol/governance-contracts/contracts/Governance/IAccessControlManagerV5.sol";
import { VToken, EIP20Interface } from "../VTokens/VToken.sol";
import { VAIUnitroller, VAIControllerStorageG4 } from "./VAIUnitroller.sol";
import { VAIControllerInterface } from "./VAIControllerInterface.sol";
import { VAI } from "./VAI.sol";
import { IPrime } from "../Prime/IPrime.sol";
import { VTokenInterface } from "../VTokens/VTokenInterfaces.sol";

/**
 * @title VAI Comptroller
 * @author Venus
 * @notice This is the implementation contract for the VAIUnitroller proxy
 */
contract VAIController is VAIControllerInterface, VAIControllerStorageG4, VAIControllerErrorReporter, Exponential {
    /// @notice Initial index used in interest computations
    uint256 public constant INITIAL_VAI_MINT_INDEX = 1e18;

    /// @notice Emitted when Comptroller is changed
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /// @notice Emitted when mint for prime holder is changed
    event MintOnlyForPrimeHolder(bool previousMintEnabledOnlyForPrimeHolder, bool newMintEnabledOnlyForPrimeHolder);

    /// @notice Emitted when Prime is changed
    event NewPrime(address oldPrime, address newPrime);

    /// @notice Event emitted when VAI is minted
    event MintVAI(address minter, uint256 mintVAIAmount);

    /// @notice Event emitted when VAI is repaid
    event RepayVAI(address payer, address borrower, uint256 repayVAIAmount);

    /// @notice Event emitted when a borrow is liquidated
    event LiquidateVAI(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address vTokenCollateral,
        uint256 seizeTokens
    );

    /// @notice Emitted when treasury guardian is changed
    event NewTreasuryGuardian(address oldTreasuryGuardian, address newTreasuryGuardian);

    /// @notice Emitted when treasury address is changed
    event NewTreasuryAddress(address oldTreasuryAddress, address newTreasuryAddress);

    /// @notice Emitted when treasury percent is changed
    event NewTreasuryPercent(uint256 oldTreasuryPercent, uint256 newTreasuryPercent);

    /// @notice Event emitted when VAIs are minted and fee are transferred
    event MintFee(address minter, uint256 feeAmount);

    /// @notice Emiitted when VAI base rate is changed
    event NewVAIBaseRate(uint256 oldBaseRateMantissa, uint256 newBaseRateMantissa);

    /// @notice Emiitted when VAI float rate is changed
    event NewVAIFloatRate(uint256 oldFloatRateMantissa, uint256 newFlatRateMantissa);

    /// @notice Emiitted when VAI receiver address is changed
    event NewVAIReceiver(address oldReceiver, address newReceiver);

    /// @notice Emiitted when VAI mint cap is changed
    event NewVAIMintCap(uint256 oldMintCap, uint256 newMintCap);

    /// @notice Emitted when access control address is changed by admin
    event NewAccessControl(address oldAccessControlAddress, address newAccessControlAddress);

    /// @notice Emitted when VAI token address is changed by admin
    event NewVaiToken(address oldVaiToken, address newVaiToken);

    function initialize() external onlyAdmin {
        require(vaiMintIndex == 0, "already initialized");

        vaiMintIndex = INITIAL_VAI_MINT_INDEX;
        accrualBlockNumber = getBlockNumber();
        mintCap = uint256(-1);

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
    }

    function _become(VAIUnitroller unitroller) external {
        require(msg.sender == unitroller.admin(), "only unitroller admin can change brains");
        require(unitroller._acceptImplementation() == 0, "change not authorized");
    }

    /**
     * @notice The mintVAI function mints and transfers VAI from the protocol to the user, and adds a borrow balance.
     * The amount minted must be less than the user's Account Liquidity and the mint vai limit.
     * @dev If the Comptroller address is not set, minting is a no-op and the function returns the success code.
     * @param mintVAIAmount The amount of the VAI to be minted.
     * @return 0 on success, otherwise an error code
     */
    // solhint-disable-next-line code-complexity
    function mintVAI(uint256 mintVAIAmount) external nonReentrant returns (uint256) {
        if (address(comptroller) == address(0)) {
            return uint256(Error.NO_ERROR);
        }

        _ensureNonzeroAmount(mintVAIAmount);
        _ensureNotPaused();
        accrueVAIInterest();

        uint256 err;
        address minter = msg.sender;
        address _vai = vai;
        uint256 vaiTotalSupply = EIP20Interface(_vai).totalSupply();

        uint256 vaiNewTotalSupply = add_(vaiTotalSupply, mintVAIAmount);
        require(vaiNewTotalSupply <= mintCap, "mint cap reached");

        uint256 accountMintableVAI;
        (err, accountMintableVAI) = getMintableVAI(minter);
        require(err == uint256(Error.NO_ERROR), "could not compute mintable amount");

        // check that user have sufficient mintableVAI balance
        require(mintVAIAmount <= accountMintableVAI, "minting more than allowed");

        // Calculate the minted balance based on interest index
        uint256 totalMintedVAI = comptroller.mintedVAIs(minter);

        if (totalMintedVAI > 0) {
            uint256 repayAmount = getVAIRepayAmount(minter);
            uint256 remainedAmount = sub_(repayAmount, totalMintedVAI);
            pastVAIInterest[minter] = add_(pastVAIInterest[minter], remainedAmount);
            totalMintedVAI = repayAmount;
        }

        uint256 accountMintVAINew = add_(totalMintedVAI, mintVAIAmount);
        err = comptroller.setMintedVAIOf(minter, accountMintVAINew);
        require(err == uint256(Error.NO_ERROR), "comptroller rejection");

        uint256 remainedAmount;
        if (treasuryPercent != 0) {
            uint256 feeAmount = div_(mul_(mintVAIAmount, treasuryPercent), 1e18);
            remainedAmount = sub_(mintVAIAmount, feeAmount);
            VAI(_vai).mint(treasuryAddress, feeAmount);

            emit MintFee(minter, feeAmount);
        } else {
            remainedAmount = mintVAIAmount;
        }

        VAI(_vai).mint(minter, remainedAmount);
        vaiMinterInterestIndex[minter] = vaiMintIndex;

        emit MintVAI(minter, remainedAmount);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice The repay function transfers VAI interest into the protocol and burns the rest,
     * reducing the borrower's borrow balance. Before repaying VAI, users must first approve
     * VAIController to access their VAI balance.
     * @dev If the Comptroller address is not set, repayment is a no-op and the function returns the success code.
     * @param amount The amount of VAI to be repaid.
     * @return Error code (0=success, otherwise a failure, see ErrorReporter.sol)
     * @return Actual repayment amount
     */
    function repayVAI(uint256 amount) external nonReentrant returns (uint256, uint256) {
        return _repayVAI(msg.sender, amount);
    }

    /**
     * @notice The repay on behalf function transfers VAI interest into the protocol and burns the rest,
     * reducing the borrower's borrow balance. Borrowed VAIs are repaid by another user (possibly the borrower).
     * Before repaying VAI, the payer must first approve VAIController to access their VAI balance.
     * @dev If the Comptroller address is not set, repayment is a no-op and the function returns the success code.
     * @param borrower The account to repay the debt for.
     * @param amount The amount of VAI to be repaid.
     * @return Error code (0=success, otherwise a failure, see ErrorReporter.sol)
     * @return Actual repayment amount
     */
    function repayVAIBehalf(address borrower, uint256 amount) external nonReentrant returns (uint256, uint256) {
        _ensureNonzeroAddress(borrower);
        return _repayVAI(borrower, amount);
    }

    /**
     * @dev Checks the parameters and the protocol state, accrues interest, and invokes repayVAIFresh.
     * @dev If the Comptroller address is not set, repayment is a no-op and the function returns the success code.
     * @param borrower The account to repay the debt for.
     * @param amount The amount of VAI to be repaid.
     * @return Error code (0=success, otherwise a failure, see ErrorReporter.sol)
     * @return Actual repayment amount
     */
    function _repayVAI(address borrower, uint256 amount) internal returns (uint256, uint256) {
        if (address(comptroller) == address(0)) {
            return (0, 0);
        }
        _ensureNonzeroAmount(amount);
        _ensureNotPaused();

        accrueVAIInterest();
        return repayVAIFresh(msg.sender, borrower, amount);
    }

    /**
     * @dev Repay VAI, expecting interest to be accrued
     * @dev Borrowed VAIs are repaid by another user (possibly the borrower).
     * @param payer the account paying off the VAI
     * @param borrower the account with the debt being payed off
     * @param repayAmount the amount of VAI being repaid
     * @return Error code (0=success, otherwise a failure, see ErrorReporter.sol)
     * @return Actual repayment amount
     */
    function repayVAIFresh(address payer, address borrower, uint256 repayAmount) internal returns (uint256, uint256) {
        (uint256 burn, uint256 partOfCurrentInterest, uint256 partOfPastInterest) = getVAICalculateRepayAmount(
            borrower,
            repayAmount
        );

        VAI _vai = VAI(vai);
        _vai.burn(payer, burn);
        bool success = _vai.transferFrom(payer, receiver, partOfCurrentInterest);
        require(success == true, "failed to transfer VAI fee");

        uint256 vaiBalanceBorrower = comptroller.mintedVAIs(borrower);

        uint256 accountVAINew = sub_(sub_(vaiBalanceBorrower, burn), partOfPastInterest);
        pastVAIInterest[borrower] = sub_(pastVAIInterest[borrower], partOfPastInterest);

        uint256 error = comptroller.setMintedVAIOf(borrower, accountVAINew);
        // We have to revert upon error since side-effects already happened at this point
        require(error == uint256(Error.NO_ERROR), "comptroller rejection");

        uint256 repaidAmount = add_(burn, partOfCurrentInterest);
        emit RepayVAI(payer, borrower, repaidAmount);

        return (uint256(Error.NO_ERROR), repaidAmount);
    }

    /**
     * @notice The sender liquidates the vai minters collateral. The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of vai to be liquidated
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return Error code (0=success, otherwise a failure, see ErrorReporter.sol)
     * @return Actual repayment amount
     */
    function liquidateVAI(
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral
    ) external nonReentrant returns (uint256, uint256) {
        _ensureNotPaused();

        uint256 error = vTokenCollateral.accrueInterest();
        if (error != uint256(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
            return (fail(Error(error), FailureInfo.VAI_LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED), 0);
        }

        // liquidateVAIFresh emits borrow-specific logs on errors, so we don't need to
        return liquidateVAIFresh(msg.sender, borrower, repayAmount, vTokenCollateral);
    }

    /**
     * @notice The liquidator liquidates the borrowers collateral by repay borrowers VAI.
     *  The collateral seized is transferred to the liquidator.
     * @dev If the Comptroller address is not set, liquidation is a no-op and the function returns the success code.
     * @param liquidator The address repaying the VAI and seizing collateral
     * @param borrower The borrower of this VAI to be liquidated
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the VAI to repay
     * @return Error code (0=success, otherwise a failure, see ErrorReporter.sol)
     * @return Actual repayment amount
     */
    function liquidateVAIFresh(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral
    ) internal returns (uint256, uint256) {
        if (address(comptroller) != address(0)) {
            accrueVAIInterest();

            /* Fail if liquidate not allowed */
            uint256 allowed = comptroller.liquidateBorrowAllowed(
                address(this),
                address(vTokenCollateral),
                liquidator,
                borrower,
                repayAmount
            );
            if (allowed != 0) {
                return (failOpaque(Error.REJECTION, FailureInfo.VAI_LIQUIDATE_COMPTROLLER_REJECTION, allowed), 0);
            }

            /* Verify vTokenCollateral market's block number equals current block number */
            //if (vTokenCollateral.accrualBlockNumber() != accrualBlockNumber) {
            if (vTokenCollateral.accrualBlockNumber() != getBlockNumber()) {
                return (fail(Error.REJECTION, FailureInfo.VAI_LIQUIDATE_COLLATERAL_FRESHNESS_CHECK), 0);
            }

            /* Fail if borrower = liquidator */
            if (borrower == liquidator) {
                return (fail(Error.REJECTION, FailureInfo.VAI_LIQUIDATE_LIQUIDATOR_IS_BORROWER), 0);
            }

            /* Fail if repayAmount = 0 */
            if (repayAmount == 0) {
                return (fail(Error.REJECTION, FailureInfo.VAI_LIQUIDATE_CLOSE_AMOUNT_IS_ZERO), 0);
            }

            /* Fail if repayAmount = -1 */
            if (repayAmount == uint256(-1)) {
                return (fail(Error.REJECTION, FailureInfo.VAI_LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX), 0);
            }

            /* Fail if repayVAI fails */
            (uint256 repayBorrowError, uint256 actualRepayAmount) = repayVAIFresh(liquidator, borrower, repayAmount);
            if (repayBorrowError != uint256(Error.NO_ERROR)) {
                return (fail(Error(repayBorrowError), FailureInfo.VAI_LIQUIDATE_REPAY_BORROW_FRESH_FAILED), 0);
            }

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            /* We calculate the number of collateral tokens that will be seized */
            (uint256 amountSeizeError, uint256 seizeTokens) = comptroller.liquidateVAICalculateSeizeTokens(
                address(vTokenCollateral),
                actualRepayAmount
            );
            require(
                amountSeizeError == uint256(Error.NO_ERROR),
                "VAI_LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED"
            );

            /* Revert if borrower collateral token balance < seizeTokens */
            require(vTokenCollateral.balanceOf(borrower) >= seizeTokens, "VAI_LIQUIDATE_SEIZE_TOO_MUCH");

            uint256 seizeError;
            seizeError = vTokenCollateral.seize(liquidator, borrower, seizeTokens);

            /* Revert if seize tokens fails (since we cannot be sure of side effects) */
            require(seizeError == uint256(Error.NO_ERROR), "token seizure failed");

            /* We emit a LiquidateBorrow event */
            emit LiquidateVAI(liquidator, borrower, actualRepayAmount, address(vTokenCollateral), seizeTokens);

            /* We call the defense hook */
            comptroller.liquidateBorrowVerify(
                address(this),
                address(vTokenCollateral),
                liquidator,
                borrower,
                actualRepayAmount,
                seizeTokens
            );

            return (uint256(Error.NO_ERROR), actualRepayAmount);
        }
    }

    /*** Admin Functions ***/

    /**
     * @notice Sets a new comptroller
     * @dev Admin function to set a new comptroller
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setComptroller(ComptrollerInterface comptroller_) external returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COMPTROLLER_OWNER_CHECK);
        }

        ComptrollerInterface oldComptroller = comptroller;
        comptroller = comptroller_;
        emit NewComptroller(oldComptroller, comptroller_);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Set the prime token contract address
     * @param prime_ The new address of the prime token contract
     */
    function setPrimeToken(address prime_) external onlyAdmin {
        emit NewPrime(prime, prime_);
        prime = prime_;
    }

    /**
     * @notice Set the VAI token contract address
     * @param vai_ The new address of the VAI token contract
     */
    function setVAIToken(address vai_) external onlyAdmin {
        emit NewVaiToken(vai, vai_);
        vai = vai_;
    }

    /**
     * @notice Toggle mint only for prime holder
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function toggleOnlyPrimeHolderMint() external returns (uint256) {
        _ensureAllowed("toggleOnlyPrimeHolderMint()");

        if (!mintEnabledOnlyForPrimeHolder && prime == address(0)) {
            return uint256(Error.REJECTION);
        }

        emit MintOnlyForPrimeHolder(mintEnabledOnlyForPrimeHolder, !mintEnabledOnlyForPrimeHolder);
        mintEnabledOnlyForPrimeHolder = !mintEnabledOnlyForPrimeHolder;

        return uint256(Error.NO_ERROR);
    }

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account total supply balance.
     *  Note that `vTokenBalance` is the number of vTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountAmountLocalVars {
        uint256 oErr;
        MathError mErr;
        uint256 sumSupply;
        uint256 marketSupply;
        uint256 sumBorrowPlusEffects;
        uint256 vTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRateMantissa;
        uint256 oraclePriceMantissa;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Function that returns the amount of VAI a user can mint based on their account liquidy and the VAI mint rate
     * If mintEnabledOnlyForPrimeHolder is true, only Prime holders are able to mint VAI
     * @param minter The account to check mintable VAI
     * @return Error code (0=success, otherwise a failure, see ErrorReporter.sol for details)
     * @return Mintable amount (with 18 decimals)
     */
    // solhint-disable-next-line code-complexity
    function getMintableVAI(address minter) public view returns (uint256, uint256) {
        if (mintEnabledOnlyForPrimeHolder && !IPrime(prime).isUserPrimeHolder(minter)) {
            return (uint256(Error.REJECTION), 0);
        }

        PriceOracle oracle = comptroller.oracle();
        VToken[] memory enteredMarkets = comptroller.getAssetsIn(minter);

        AccountAmountLocalVars memory vars; // Holds all our calculation results

        uint256 accountMintableVAI;
        uint256 i;

        /**
         * We use this formula to calculate mintable VAI amount.
         * totalSupplyAmount * VAIMintRate - (totalBorrowAmount + mintedVAIOf)
         */
        uint256 marketsCount = enteredMarkets.length;
        for (i = 0; i < marketsCount; i++) {
            (vars.oErr, vars.vTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = enteredMarkets[i]
                .getAccountSnapshot(minter);
            if (vars.oErr != 0) {
                // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (uint256(Error.SNAPSHOT_ERROR), 0);
            }
            vars.exchangeRate = Exp({ mantissa: vars.exchangeRateMantissa });

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(enteredMarkets[i]);
            if (vars.oraclePriceMantissa == 0) {
                return (uint256(Error.PRICE_ERROR), 0);
            }
            vars.oraclePrice = Exp({ mantissa: vars.oraclePriceMantissa });

            (vars.mErr, vars.tokensToDenom) = mulExp(vars.exchangeRate, vars.oraclePrice);
            if (vars.mErr != MathError.NO_ERROR) {
                return (uint256(Error.MATH_ERROR), 0);
            }

            // marketSupply = tokensToDenom * vTokenBalance
            (vars.mErr, vars.marketSupply) = mulScalarTruncate(vars.tokensToDenom, vars.vTokenBalance);
            if (vars.mErr != MathError.NO_ERROR) {
                return (uint256(Error.MATH_ERROR), 0);
            }

            (, uint256 collateralFactorMantissa) = comptroller.markets(address(enteredMarkets[i]));
            (vars.mErr, vars.marketSupply) = mulUInt(vars.marketSupply, collateralFactorMantissa);
            if (vars.mErr != MathError.NO_ERROR) {
                return (uint256(Error.MATH_ERROR), 0);
            }

            (vars.mErr, vars.marketSupply) = divUInt(vars.marketSupply, 1e18);
            if (vars.mErr != MathError.NO_ERROR) {
                return (uint256(Error.MATH_ERROR), 0);
            }

            (vars.mErr, vars.sumSupply) = addUInt(vars.sumSupply, vars.marketSupply);
            if (vars.mErr != MathError.NO_ERROR) {
                return (uint256(Error.MATH_ERROR), 0);
            }

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            (vars.mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(
                vars.oraclePrice,
                vars.borrowBalance,
                vars.sumBorrowPlusEffects
            );
            if (vars.mErr != MathError.NO_ERROR) {
                return (uint256(Error.MATH_ERROR), 0);
            }
        }

        uint256 totalMintedVAI = comptroller.mintedVAIs(minter);
        uint256 repayAmount = 0;

        if (totalMintedVAI > 0) {
            repayAmount = getVAIRepayAmount(minter);
        }

        (vars.mErr, vars.sumBorrowPlusEffects) = addUInt(vars.sumBorrowPlusEffects, repayAmount);
        if (vars.mErr != MathError.NO_ERROR) {
            return (uint256(Error.MATH_ERROR), 0);
        }

        (vars.mErr, accountMintableVAI) = mulUInt(vars.sumSupply, comptroller.vaiMintRate());
        require(vars.mErr == MathError.NO_ERROR, "VAI_MINT_AMOUNT_CALCULATION_FAILED");

        (vars.mErr, accountMintableVAI) = divUInt(accountMintableVAI, 10000);
        require(vars.mErr == MathError.NO_ERROR, "VAI_MINT_AMOUNT_CALCULATION_FAILED");

        (vars.mErr, accountMintableVAI) = subUInt(accountMintableVAI, vars.sumBorrowPlusEffects);
        if (vars.mErr != MathError.NO_ERROR) {
            return (uint256(Error.REJECTION), 0);
        }

        return (uint256(Error.NO_ERROR), accountMintableVAI);
    }

    /**
     * @notice Update treasury data
     * @param newTreasuryGuardian New Treasury Guardian address
     * @param newTreasuryAddress New Treasury Address
     * @param newTreasuryPercent New fee percentage for minting VAI that is sent to the treasury
     */
    function _setTreasuryData(
        address newTreasuryGuardian,
        address newTreasuryAddress,
        uint256 newTreasuryPercent
    ) external returns (uint256) {
        // Check caller is admin
        if (!(msg.sender == admin || msg.sender == treasuryGuardian)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_TREASURY_OWNER_CHECK);
        }

        require(newTreasuryPercent < 1e18, "treasury percent cap overflow");

        address oldTreasuryGuardian = treasuryGuardian;
        address oldTreasuryAddress = treasuryAddress;
        uint256 oldTreasuryPercent = treasuryPercent;

        treasuryGuardian = newTreasuryGuardian;
        treasuryAddress = newTreasuryAddress;
        treasuryPercent = newTreasuryPercent;

        emit NewTreasuryGuardian(oldTreasuryGuardian, newTreasuryGuardian);
        emit NewTreasuryAddress(oldTreasuryAddress, newTreasuryAddress);
        emit NewTreasuryPercent(oldTreasuryPercent, newTreasuryPercent);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Gets yearly VAI interest rate based on the VAI price
     * @return uint256 Yearly VAI interest rate
     */
    function getVAIRepayRate() public view returns (uint256) {
        PriceOracle oracle = comptroller.oracle();
        MathError mErr;

        if (baseRateMantissa > 0) {
            if (floatRateMantissa > 0) {
                uint256 oraclePrice = oracle.getUnderlyingPrice(VToken(getVAIAddress()));
                if (1e18 > oraclePrice) {
                    uint256 delta;
                    uint256 rate;

                    (mErr, delta) = subUInt(1e18, oraclePrice);
                    require(mErr == MathError.NO_ERROR, "VAI_REPAY_RATE_CALCULATION_FAILED");

                    (mErr, delta) = mulUInt(delta, floatRateMantissa);
                    require(mErr == MathError.NO_ERROR, "VAI_REPAY_RATE_CALCULATION_FAILED");

                    (mErr, delta) = divUInt(delta, 1e18);
                    require(mErr == MathError.NO_ERROR, "VAI_REPAY_RATE_CALCULATION_FAILED");

                    (mErr, rate) = addUInt(delta, baseRateMantissa);
                    require(mErr == MathError.NO_ERROR, "VAI_REPAY_RATE_CALCULATION_FAILED");

                    return rate;
                } else {
                    return baseRateMantissa;
                }
            } else {
                return baseRateMantissa;
            }
        } else {
            return 0;
        }
    }

    /**
     * @notice Get interest rate per block
     * @return uint256 Interest rate per bock
     */
    function getVAIRepayRatePerBlock() public view returns (uint256) {
        uint256 yearlyRate = getVAIRepayRate();

        MathError mErr;
        uint256 rate;

        (mErr, rate) = divUInt(yearlyRate, getBlocksPerYear());
        require(mErr == MathError.NO_ERROR, "VAI_REPAY_RATE_CALCULATION_FAILED");

        return rate;
    }

    /**
     * @notice Get the last updated interest index for a VAI Minter
     * @param minter Address of VAI minter
     * @return uint256 Returns the interest rate index for a minter
     */
    function getVAIMinterInterestIndex(address minter) public view returns (uint256) {
        uint256 storedIndex = vaiMinterInterestIndex[minter];
        // If the user minted VAI before the stability fee was introduced, accrue
        // starting from stability fee launch
        if (storedIndex == 0) {
            return INITIAL_VAI_MINT_INDEX;
        }
        return storedIndex;
    }

    /**
     * @notice Get the current total VAI a user needs to repay
     * @param account The address of the VAI borrower
     * @return (uint256) The total amount of VAI the user needs to repay
     */
    function getVAIRepayAmount(address account) public view returns (uint256) {
        MathError mErr;
        uint256 delta;

        uint256 amount = comptroller.mintedVAIs(account);
        uint256 interest = pastVAIInterest[account];
        uint256 totalMintedVAI;
        uint256 newInterest;

        (mErr, totalMintedVAI) = subUInt(amount, interest);
        require(mErr == MathError.NO_ERROR, "VAI_TOTAL_REPAY_AMOUNT_CALCULATION_FAILED");

        (mErr, delta) = subUInt(vaiMintIndex, getVAIMinterInterestIndex(account));
        require(mErr == MathError.NO_ERROR, "VAI_TOTAL_REPAY_AMOUNT_CALCULATION_FAILED");

        (mErr, newInterest) = mulUInt(delta, totalMintedVAI);
        require(mErr == MathError.NO_ERROR, "VAI_TOTAL_REPAY_AMOUNT_CALCULATION_FAILED");

        (mErr, newInterest) = divUInt(newInterest, 1e18);
        require(mErr == MathError.NO_ERROR, "VAI_TOTAL_REPAY_AMOUNT_CALCULATION_FAILED");

        (mErr, amount) = addUInt(amount, newInterest);
        require(mErr == MathError.NO_ERROR, "VAI_TOTAL_REPAY_AMOUNT_CALCULATION_FAILED");

        return amount;
    }

    /**
     * @notice Calculate how much VAI the user needs to repay
     * @param borrower The address of the VAI borrower
     * @param repayAmount The amount of VAI being returned
     * @return Amount of VAI to be burned
     * @return Amount of VAI the user needs to pay in current interest
     * @return Amount of VAI the user needs to pay in past interest
     */
    function getVAICalculateRepayAmount(
        address borrower,
        uint256 repayAmount
    ) public view returns (uint256, uint256, uint256) {
        MathError mErr;
        uint256 totalRepayAmount = getVAIRepayAmount(borrower);
        uint256 currentInterest;

        (mErr, currentInterest) = subUInt(totalRepayAmount, comptroller.mintedVAIs(borrower));
        require(mErr == MathError.NO_ERROR, "VAI_BURN_AMOUNT_CALCULATION_FAILED");

        (mErr, currentInterest) = addUInt(pastVAIInterest[borrower], currentInterest);
        require(mErr == MathError.NO_ERROR, "VAI_BURN_AMOUNT_CALCULATION_FAILED");

        uint256 burn;
        uint256 partOfCurrentInterest = currentInterest;
        uint256 partOfPastInterest = pastVAIInterest[borrower];

        if (repayAmount >= totalRepayAmount) {
            (mErr, burn) = subUInt(totalRepayAmount, currentInterest);
            require(mErr == MathError.NO_ERROR, "VAI_BURN_AMOUNT_CALCULATION_FAILED");
        } else {
            uint256 delta;

            (mErr, delta) = mulUInt(repayAmount, 1e18);
            require(mErr == MathError.NO_ERROR, "VAI_PART_CALCULATION_FAILED");

            (mErr, delta) = divUInt(delta, totalRepayAmount);
            require(mErr == MathError.NO_ERROR, "VAI_PART_CALCULATION_FAILED");

            uint256 totalMintedAmount;
            (mErr, totalMintedAmount) = subUInt(totalRepayAmount, currentInterest);
            require(mErr == MathError.NO_ERROR, "VAI_MINTED_AMOUNT_CALCULATION_FAILED");

            (mErr, burn) = mulUInt(totalMintedAmount, delta);
            require(mErr == MathError.NO_ERROR, "VAI_BURN_AMOUNT_CALCULATION_FAILED");

            (mErr, burn) = divUInt(burn, 1e18);
            require(mErr == MathError.NO_ERROR, "VAI_BURN_AMOUNT_CALCULATION_FAILED");

            (mErr, partOfCurrentInterest) = mulUInt(currentInterest, delta);
            require(mErr == MathError.NO_ERROR, "VAI_CURRENT_INTEREST_AMOUNT_CALCULATION_FAILED");

            (mErr, partOfCurrentInterest) = divUInt(partOfCurrentInterest, 1e18);
            require(mErr == MathError.NO_ERROR, "VAI_CURRENT_INTEREST_AMOUNT_CALCULATION_FAILED");

            (mErr, partOfPastInterest) = mulUInt(pastVAIInterest[borrower], delta);
            require(mErr == MathError.NO_ERROR, "VAI_PAST_INTEREST_CALCULATION_FAILED");

            (mErr, partOfPastInterest) = divUInt(partOfPastInterest, 1e18);
            require(mErr == MathError.NO_ERROR, "VAI_PAST_INTEREST_CALCULATION_FAILED");
        }

        return (burn, partOfCurrentInterest, partOfPastInterest);
    }

    /**
     * @notice Accrue interest on outstanding minted VAI
     */
    function accrueVAIInterest() public {
        MathError mErr;
        uint256 delta;

        (mErr, delta) = mulUInt(getVAIRepayRatePerBlock(), getBlockNumber() - accrualBlockNumber);
        require(mErr == MathError.NO_ERROR, "VAI_INTEREST_ACCRUE_FAILED");

        (mErr, delta) = addUInt(delta, vaiMintIndex);
        require(mErr == MathError.NO_ERROR, "VAI_INTEREST_ACCRUE_FAILED");

        vaiMintIndex = delta;
        accrualBlockNumber = getBlockNumber();
    }

    /**
     * @notice Sets the address of the access control of this contract
     * @dev Admin function to set the access control address
     * @param newAccessControlAddress New address for the access control
     */
    function setAccessControl(address newAccessControlAddress) external onlyAdmin {
        _ensureNonzeroAddress(newAccessControlAddress);

        address oldAccessControlAddress = accessControl;
        accessControl = newAccessControlAddress;
        emit NewAccessControl(oldAccessControlAddress, accessControl);
    }

    /**
     * @notice Set VAI borrow base rate
     * @param newBaseRateMantissa the base rate multiplied by 10**18
     */
    function setBaseRate(uint256 newBaseRateMantissa) external {
        _ensureAllowed("setBaseRate(uint256)");

        uint256 old = baseRateMantissa;
        baseRateMantissa = newBaseRateMantissa;
        emit NewVAIBaseRate(old, baseRateMantissa);
    }

    /**
     * @notice Set VAI borrow float rate
     * @param newFloatRateMantissa the VAI float rate multiplied by 10**18
     */
    function setFloatRate(uint256 newFloatRateMantissa) external {
        _ensureAllowed("setFloatRate(uint256)");

        uint256 old = floatRateMantissa;
        floatRateMantissa = newFloatRateMantissa;
        emit NewVAIFloatRate(old, floatRateMantissa);
    }

    /**
     * @notice Set VAI stability fee receiver address
     * @param newReceiver the address of the VAI fee receiver
     */
    function setReceiver(address newReceiver) external onlyAdmin {
        _ensureNonzeroAddress(newReceiver);

        address old = receiver;
        receiver = newReceiver;
        emit NewVAIReceiver(old, newReceiver);
    }

    /**
     * @notice Set VAI mint cap
     * @param _mintCap the amount of VAI that can be minted
     */
    function setMintCap(uint256 _mintCap) external {
        _ensureAllowed("setMintCap(uint256)");

        uint256 old = mintCap;
        mintCap = _mintCap;
        emit NewVAIMintCap(old, _mintCap);
    }

    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    function getBlocksPerYear() public view returns (uint256) {
        return 10512000; //(24 * 60 * 60 * 365) / 3;
    }

    /**
     * @notice Return the address of the VAI token
     * @return The address of VAI
     */
    function getVAIAddress() public view returns (address) {
        return vai;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can");
        _;
    }

    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    function _ensureAllowed(string memory functionSig) private view {
        require(IAccessControlManagerV5(accessControl).isAllowedToCall(msg.sender, functionSig), "access denied");
    }

    /// @dev Reverts if the protocol is paused
    function _ensureNotPaused() private view {
        require(!comptroller.protocolPaused(), "protocol is paused");
    }

    /// @dev Reverts if the passed address is zero
    function _ensureNonzeroAddress(address someone) private pure {
        require(someone != address(0), "can't be zero address");
    }

    /// @dev Reverts if the passed amount is zero
    function _ensureNonzeroAmount(uint256 amount) private pure {
        require(amount > 0, "amount can't be zero");
    }
}

pragma solidity ^0.5.16;

import { VTokenInterface } from "../VTokens/VTokenInterfaces.sol";

contract VAIControllerInterface {
    function mintVAI(uint256 mintVAIAmount) external returns (uint256);

    function repayVAI(uint256 amount) external returns (uint256, uint256);

    function repayVAIBehalf(address borrower, uint256 amount) external returns (uint256, uint256);

    function liquidateVAI(
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral
    ) external returns (uint256, uint256);

    function getMintableVAI(address minter) external view returns (uint256, uint256);

    function getVAIAddress() external view returns (address);

    function getVAIRepayAmount(address account) external view returns (uint256);
}

pragma solidity ^0.5.16;

import { ComptrollerInterface } from "../../Comptroller/ComptrollerInterface.sol";

contract VAIUnitrollerAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active brains of Unitroller
     */
    address public vaiControllerImplementation;

    /**
     * @notice Pending brains of Unitroller
     */
    address public pendingVAIControllerImplementation;
}

contract VAIControllerStorageG1 is VAIUnitrollerAdminStorage {
    ComptrollerInterface public comptroller;

    struct VenusVAIState {
        /// @notice The last updated venusVAIMintIndex
        uint224 index;
        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /// @notice The Venus VAI state
    VenusVAIState public venusVAIState;

    /// @notice The Venus VAI state initialized
    bool public isVenusVAIInitialized;

    /// @notice The Venus VAI minter index as of the last time they accrued XVS
    mapping(address => uint256) public venusVAIMinterIndex;
}

contract VAIControllerStorageG2 is VAIControllerStorageG1 {
    /// @notice Treasury Guardian address
    address public treasuryGuardian;

    /// @notice Treasury address
    address public treasuryAddress;

    /// @notice Fee percent of accrued interest with decimal 18
    uint256 public treasuryPercent;

    /// @notice Guard variable for re-entrancy checks
    bool internal _notEntered;

    /// @notice The base rate for stability fee
    uint256 public baseRateMantissa;

    /// @notice The float rate for stability fee
    uint256 public floatRateMantissa;

    /// @notice The address for VAI interest receiver
    address public receiver;

    /// @notice Accumulator of the total earned interest rate since the opening of the market. For example: 0.6 (60%)
    uint256 public vaiMintIndex;

    /// @notice Block number that interest was last accrued at
    uint256 internal accrualBlockNumber;

    /// @notice Global vaiMintIndex as of the most recent balance-changing action for user
    mapping(address => uint256) internal vaiMinterInterestIndex;

    /// @notice Tracks the amount of mintedVAI of a user that represents the accrued interest
    mapping(address => uint256) public pastVAIInterest;

    /// @notice VAI mint cap
    uint256 public mintCap;

    /// @notice Access control manager address
    address public accessControl;
}

contract VAIControllerStorageG3 is VAIControllerStorageG2 {
    /// @notice The address of the prime contract. It can be a ZERO address
    address public prime;

    /// @notice Tracks if minting is enabled only for prime token holders. Only used if prime is set
    bool public mintEnabledOnlyForPrimeHolder;
}

contract VAIControllerStorageG4 is VAIControllerStorageG3 {
    /// @notice The address of the VAI token
    address internal vai;
}

pragma solidity ^0.5.16;

import "../../Utils/ErrorReporter.sol";
import "./VAIControllerStorage.sol";

/**
 * @title VAI Unitroller
 * @author Venus
 * @notice This is the proxy contract for the VAIComptroller
 */
contract VAIUnitroller is VAIUnitrollerAdminStorage, VAIControllerErrorReporter {
    /**
     * @notice Emitted when pendingVAIControllerImplementation is changed
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingVAIControllerImplementation is accepted, which means comptroller implementation is updated
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() public {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public returns (uint256) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
        }

        address oldPendingImplementation = pendingVAIControllerImplementation;

        pendingVAIControllerImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingVAIControllerImplementation);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Accepts new implementation of comptroller. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptImplementation() public returns (uint256) {
        // Check caller is pendingImplementation
        if (msg.sender != pendingVAIControllerImplementation) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
        }

        // Save current values for inclusion in log
        address oldImplementation = vaiControllerImplementation;
        address oldPendingImplementation = pendingVAIControllerImplementation;

        vaiControllerImplementation = pendingVAIControllerImplementation;

        pendingVAIControllerImplementation = address(0);

        emit NewImplementation(oldImplementation, vaiControllerImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingVAIControllerImplementation);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint256) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptAdmin() public returns (uint256) {
        // Check caller is pendingAdmin
        if (msg.sender != pendingAdmin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = vaiControllerImplementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize)
            }
            default {
                return(free_mem_ptr, returndatasize)
            }
        }
    }
}

pragma solidity ^0.5.16;

import "../../Utils/Tokenlock.sol";

contract VRT is Tokenlock {
    /// @notice BEP-20 token name for this token
    string public constant name = "Venus Reward Token";

    /// @notice BEP-20 token symbol for this token
    string public constant symbol = "VRT";

    /// @notice BEP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public constant totalSupply = 30000000000e18; // 30 billion VRT

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping(address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard BEP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard BEP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new VRT token
     * @param account The initial account to grant all the tokens
     */
    constructor(address account) public {
        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external validLock returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "VRT::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external validLock returns (bool) {
        uint96 amount = safe96(rawAmount, "VRT::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint rawAmount) external validLock returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "VRT::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(
                spenderAllowance,
                amount,
                "VRT::transferFrom: transfer amount exceeds spender allowance"
            );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public validLock {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public validLock {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "VRT::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "VRT::delegateBySig: invalid nonce");
        require(now <= expiry, "VRT::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "VRT::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "VRT::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "VRT::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "VRT::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "VRT::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "VRT::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "VRT::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "VRT::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2 ** 32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2 ** 96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

pragma solidity ^0.5.16;

import "../../Utils/IBEP20.sol";
import "../../Utils/SafeBEP20.sol";
import "../XVS/IXVSVesting.sol";
import "./VRTConverterStorage.sol";
import "./VRTConverterProxy.sol";

/**
 * @title Venus's VRTConversion Contract
 * @author Venus
 */
contract VRTConverter is VRTConverterStorage {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /// @notice decimal precision for VRT
    uint256 public constant vrtDecimalsMultiplier = 1e18;

    /// @notice decimal precision for XVS
    uint256 public constant xvsDecimalsMultiplier = 1e18;

    /// @notice Emitted when an admin set conversion info
    event ConversionInfoSet(
        uint256 conversionRatio,
        uint256 conversionStartTime,
        uint256 conversionPeriod,
        uint256 conversionEndTime
    );

    /// @notice Emitted when token conversion is done
    event TokenConverted(
        address reedeemer,
        address vrtAddress,
        uint256 vrtAmount,
        address xvsAddress,
        uint256 xvsAmount
    );

    /// @notice Emitted when an admin withdraw converted token
    event TokenWithdraw(address token, address to, uint256 amount);

    /// @notice Emitted when XVSVestingAddress is set
    event XVSVestingSet(address xvsVestingAddress);

    constructor() public {}

    function initialize(
        address _vrtAddress,
        address _xvsAddress,
        uint256 _conversionRatio,
        uint256 _conversionStartTime,
        uint256 _conversionPeriod
    ) public {
        require(msg.sender == admin, "only admin may initialize the VRTConverter");
        require(initialized == false, "VRTConverter is already initialized");

        require(_vrtAddress != address(0), "vrtAddress cannot be Zero");
        vrt = IBEP20(_vrtAddress);

        require(_xvsAddress != address(0), "xvsAddress cannot be Zero");
        xvs = IBEP20(_xvsAddress);

        require(_conversionRatio > 0, "conversionRatio cannot be Zero");
        conversionRatio = _conversionRatio;

        require(_conversionStartTime >= block.timestamp, "conversionStartTime must be time in the future");
        require(_conversionPeriod > 0, "_conversionPeriod is invalid");

        conversionStartTime = _conversionStartTime;
        conversionPeriod = _conversionPeriod;
        conversionEndTime = conversionStartTime.add(conversionPeriod);
        emit ConversionInfoSet(conversionRatio, conversionStartTime, conversionPeriod, conversionEndTime);

        totalVrtConverted = 0;
        _notEntered = true;
        initialized = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    /**
     * @notice sets XVSVestingProxy Address
     * @dev Note: If XVSVestingProxy is not set, then Conversion is not allowed
     * @param _xvsVestingAddress The XVSVestingProxy Address
     */
    function setXVSVesting(address _xvsVestingAddress) public {
        require(msg.sender == admin, "only admin may initialize the Vault");
        require(_xvsVestingAddress != address(0), "xvsVestingAddress cannot be Zero");
        xvsVesting = IXVSVesting(_xvsVestingAddress);
        emit XVSVestingSet(_xvsVestingAddress);
    }

    modifier isInitialized() {
        require(initialized == true, "VRTConverter is not initialized");
        _;
    }

    function isConversionActive() public view returns (bool) {
        uint256 currentTime = block.timestamp;
        if (currentTime >= conversionStartTime && currentTime <= conversionEndTime) {
            return true;
        }
        return false;
    }

    modifier checkForActiveConversionPeriod() {
        uint256 currentTime = block.timestamp;
        require(currentTime >= conversionStartTime, "Conversion did not start yet");
        require(currentTime <= conversionEndTime, "Conversion Period Ended");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can");
        _;
    }

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "Address cannot be Zero");
        _;
    }

    /**
     * @notice Transfer VRT and redeem XVS
     * @dev Note: If there is not enough XVS, we do not perform the conversion.
     * @param vrtAmount The amount of VRT
     */
    function convert(uint256 vrtAmount) external isInitialized checkForActiveConversionPeriod nonReentrant {
        require(
            address(xvsVesting) != address(0) && address(xvsVesting) != DEAD_ADDRESS,
            "XVS-Vesting Address is not set"
        );
        require(vrtAmount > 0, "VRT amount must be non-zero");
        totalVrtConverted = totalVrtConverted.add(vrtAmount);

        uint256 redeemAmount = vrtAmount.mul(conversionRatio).mul(xvsDecimalsMultiplier).div(1e18).div(
            vrtDecimalsMultiplier
        );

        emit TokenConverted(msg.sender, address(vrt), vrtAmount, address(xvs), redeemAmount);
        vrt.safeTransferFrom(msg.sender, DEAD_ADDRESS, vrtAmount);
        xvsVesting.deposit(msg.sender, redeemAmount);
    }

    /*** Admin Functions ***/
    function _become(VRTConverterProxy vrtConverterProxy) public {
        require(msg.sender == vrtConverterProxy.admin(), "only proxy admin can change brains");
        vrtConverterProxy._acceptImplementation();
    }
}

pragma solidity ^0.5.16;

import "./VRTConverterStorage.sol";

contract VRTConverterProxy is VRTConverterAdminStorage {
    /**
     * @notice Emitted when pendingImplementation is changed
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingImplementation is accepted, which means VRTConverter implementation is updated
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor(
        address implementation_,
        address _vrtAddress,
        address _xvsAddress,
        uint256 _conversionRatio,
        uint256 _conversionStartTime,
        uint256 _conversionPeriod
    ) public nonZeroAddress(implementation_) nonZeroAddress(_vrtAddress) nonZeroAddress(_xvsAddress) {
        // Creator of the contract is admin during initialization
        admin = msg.sender;

        // New implementations always get set via the settor (post-initialize)
        _setImplementation(implementation_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(
            implementation_,
            abi.encodeWithSignature(
                "initialize(address,address,uint256,uint256,uint256)",
                _vrtAddress,
                _xvsAddress,
                _conversionRatio,
                _conversionStartTime,
                _conversionPeriod
            )
        );
    }

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "Address cannot be Zero");
        _;
    }

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function _setImplementation(address implementation_) public {
        require(msg.sender == admin, "VRTConverterProxy::_setImplementation: admin only");
        require(implementation_ != address(0), "VRTConverterProxy::_setImplementation: invalid implementation address");

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation);
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal nonZeroAddress(callee) returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(
        address newPendingImplementation
    ) public nonZeroAddress(newPendingImplementation) {
        require(msg.sender == admin, "Only admin can set Pending Implementation");

        address oldPendingImplementation = pendingImplementation;

        pendingImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);
    }

    /**
     * @notice Accepts new implementation of VRTConverter. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     * @dev return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptImplementation() public {
        // Check caller is pendingImplementation
        require(
            msg.sender == pendingImplementation,
            "only address marked as pendingImplementation can accept Implementation"
        );

        // Save current values for inclusion in log
        address oldImplementation = implementation;
        address oldPendingImplementation = pendingImplementation;

        implementation = pendingImplementation;

        pendingImplementation = address(0);

        emit NewImplementation(oldImplementation, implementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @dev return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPendingAdmin(address newPendingAdmin) public nonZeroAddress(newPendingAdmin) {
        // Check caller = admin
        require(msg.sender == admin, "only admin can set pending admin");
        require(newPendingAdmin != pendingAdmin, "New pendingAdmin can not be same as the previous one");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @dev return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptAdmin() public {
        // Check caller is pendingAdmin
        require(msg.sender == pendingAdmin, "only address marked as pendingAdmin can accept as Admin");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize)
            }
            default {
                return(free_mem_ptr, returndatasize)
            }
        }
    }
}

pragma solidity ^0.5.16;

import "../../Utils/SafeMath.sol";
import "../../Utils/IBEP20.sol";
import "../XVS/IXVSVesting.sol";

contract VRTConverterAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active brains of VRTConverter
     */
    address public implementation;

    /**
     * @notice Pending brains of VRTConverter
     */
    address public pendingImplementation;
}

contract VRTConverterStorage is VRTConverterAdminStorage {
    /// @notice Guard variable for re-entrancy checks
    bool public _notEntered;

    /// @notice indicator to check if the contract is initialized
    bool public initialized;

    /// @notice The VRT TOKEN!
    IBEP20 public vrt;

    /// @notice The XVS TOKEN!
    IBEP20 public xvs;

    /// @notice XVSVesting Contract reference
    IXVSVesting public xvsVesting;

    /// @notice Conversion ratio from VRT to XVS with decimal 18
    uint256 public conversionRatio;

    /// @notice total VRT converted to XVS
    uint256 public totalVrtConverted;

    /// @notice Conversion Start time in EpochSeconds
    uint256 public conversionStartTime;

    /// @notice ConversionPeriod in Seconds
    uint256 public conversionPeriod;

    /// @notice Conversion End time in EpochSeconds
    uint256 public conversionEndTime;
}

pragma solidity ^0.5.16;

import { VToken, VBep20Interface, ComptrollerInterface, InterestRateModel, VTokenInterface } from "./VToken.sol";
import { EIP20Interface } from "../EIP20Interface.sol";
import { EIP20NonStandardInterface } from "../EIP20NonStandardInterface.sol";

/**
 * @title Venus's VBep20 Contract
 * @notice vTokens which wrap an EIP-20 underlying
 * @author Venus
 */
contract VBep20 is VToken, VBep20Interface {
    /*** User Interface ***/

    /**
     * @notice Sender supplies assets into the market and receives vTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Transfer event
    // @custom:event Emits Mint event
    function mint(uint mintAmount) external returns (uint) {
        (uint err, ) = mintInternal(mintAmount);
        return err;
    }

    /**
     * @notice Sender supplies assets into the market and receiver receives vTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param receiver The account which is receiving the vTokens
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Transfer event
    // @custom:event Emits MintBehalf event
    function mintBehalf(address receiver, uint mintAmount) external returns (uint) {
        (uint err, ) = mintBehalfInternal(receiver, mintAmount);
        return err;
    }

    /**
     * @notice Sender redeems vTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of vTokens to redeem into underlying
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Redeem event on success
    // @custom:event Emits Transfer event on success
    // @custom:event Emits RedeemFee when fee is charged by the treasury
    function redeem(uint redeemTokens) external returns (uint) {
        return redeemInternal(msg.sender, msg.sender, redeemTokens);
    }

    /**
     * @notice Sender redeems assets on behalf of some other address. This function is only available
     *   for senders, explicitly marked as delegates of the supplier using `comptroller.updateDelegate`
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemer The user on behalf of whom to redeem
     * @param redeemTokens The number of vTokens to redeem into underlying
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Redeem event on success
    // @custom:event Emits Transfer event on success
    // @custom:event Emits RedeemFee when fee is charged by the treasury
    function redeemBehalf(address redeemer, uint redeemTokens) external returns (uint) {
        require(comptroller.approvedDelegates(redeemer, msg.sender), "not an approved delegate");

        return redeemInternal(redeemer, msg.sender, redeemTokens);
    }

    /**
     * @notice Sender redeems vTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Redeem event on success
    // @custom:event Emits Transfer event on success
    // @custom:event Emits RedeemFee when fee is charged by the treasury
    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        return redeemUnderlyingInternal(msg.sender, msg.sender, redeemAmount);
    }

    /**
     * @notice Sender redeems underlying assets on behalf of some other address. This function is only available
     *   for senders, explicitly marked as delegates of the supplier using `comptroller.updateDelegate`
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemer, on behalf of whom to redeem
     * @param redeemAmount The amount of underlying to receive from redeeming vTokens
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Redeem event on success
    // @custom:event Emits Transfer event on success
    // @custom:event Emits RedeemFee when fee is charged by the treasury
    function redeemUnderlyingBehalf(address redeemer, uint redeemAmount) external returns (uint) {
        require(comptroller.approvedDelegates(redeemer, msg.sender), "not an approved delegate");

        return redeemUnderlyingInternal(redeemer, msg.sender, redeemAmount);
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Borrow event on success
    function borrow(uint borrowAmount) external returns (uint) {
        return borrowInternal(msg.sender, msg.sender, borrowAmount);
    }

    /**
     * @notice Sender borrows assets on behalf of some other address. This function is only available
     *   for senders, explicitly marked as delegates of the borrower using `comptroller.updateDelegate`
     * @param borrower The borrower, on behalf of whom to borrow.
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Borrow event on success
    function borrowBehalf(address borrower, uint borrowAmount) external returns (uint) {
        require(comptroller.approvedDelegates(borrower, msg.sender), "not an approved delegate");
        return borrowInternal(borrower, msg.sender, borrowAmount);
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits RepayBorrow event on success
    function repayBorrow(uint repayAmount) external returns (uint) {
        (uint err, ) = repayBorrowInternal(repayAmount);
        return err;
    }

    /**
     * @notice Sender repays a borrow belonging to another borrowing account
     * @param borrower The account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits RepayBorrow event on success
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint) {
        (uint err, ) = repayBorrowBehalfInternal(borrower, repayAmount);
        return err;
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this vToken to be liquidated
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emit LiquidateBorrow event on success
    function liquidateBorrow(
        address borrower,
        uint repayAmount,
        VTokenInterface vTokenCollateral
    ) external returns (uint) {
        (uint err, ) = liquidateBorrowInternal(borrower, repayAmount, vTokenCollateral);
        return err;
    }

    /**
     * @notice The sender adds to reserves.
     * @param addAmount The amount of underlying tokens to add as reserves
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits ReservesAdded event
    function _addReserves(uint addAmount) external returns (uint) {
        return _addReservesInternal(addAmount);
    }

    /**
     * @notice Initialize the new money market
     * @param underlying_ The address of the underlying asset
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ BEP-20 name of this token
     * @param symbol_ BEP-20 symbol of this token
     * @param decimals_ BEP-20 decimal precision of this token
     */
    function initialize(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public {
        // VToken initialize does the bulk of the work
        super.initialize(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

        // Set underlying and sanity check it
        underlying = underlying_;
        EIP20Interface(underlying).totalSupply();
    }

    /*** Safe Token ***/

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard BEP-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address from, uint amount) internal returns (uint) {
        uint balanceBefore = EIP20Interface(underlying).balanceOf(address(this));
        EIP20NonStandardInterface(underlying).transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard BEP-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant BEP-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant BEP-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint balanceAfter = EIP20Interface(underlying).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard BEP-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address payable to, uint amount) internal {
        EIP20NonStandardInterface(underlying).transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard BEP-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant BEP-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant BEP-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() internal view returns (uint) {
        return EIP20Interface(underlying).balanceOf(address(this));
    }
}

pragma solidity ^0.5.16;

import { VBep20 } from "./VBep20.sol";
import { VDelegateInterface } from "./VTokenInterfaces.sol";

/**
 * @title Venus's VBep20Delegate Contract
 * @notice VTokens which wrap an EIP-20 underlying and are delegated to
 * @author Venus
 */
contract VBep20Delegate is VBep20, VDelegateInterface {
    /**
     * @notice Construct an empty delegate
     */
    constructor() public {}

    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public {
        // Shh -- currently unused
        data;

        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _becomeImplementation");
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public {
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _resignImplementation");
    }
}

pragma solidity ^0.5.16;

import "./VTokenInterfaces.sol";

/**
 * @title Venus's VBep20Delegator Contract
 * @notice vTokens which wrap an EIP-20 underlying and delegate to an implementation
 * @author Venus
 */
contract VBep20Delegator is VTokenInterface, VBep20Interface, VDelegatorInterface {
    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param comptroller_ The address of the comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ BEP-20 name of this token
     * @param symbol_ BEP-20 symbol of this token
     * @param decimals_ BEP-20 decimal precision of this token
     * @param admin_ Address of the administrator of this token
     * @param implementation_ The address of the implementation the contract delegates to
     * @param becomeImplementationData The encoded args for becomeImplementation
     */
    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_,
        address implementation_,
        bytes memory becomeImplementationData
    ) public {
        // Creator of the contract is admin during initialization
        admin = msg.sender;

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(
            implementation_,
            abi.encodeWithSignature(
                "initialize(address,address,address,uint256,string,string,uint8)",
                underlying_,
                comptroller_,
                interestRateModel_,
                initialExchangeRateMantissa_,
                name_,
                symbol_,
                decimals_
            )
        );

        // New implementations always get set via the settor (post-initialize)
        _setImplementation(implementation_, false, becomeImplementationData);

        // Set the proper admin now that initialization is done
        admin = admin_;
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    function() external payable {
        require(msg.value == 0, "VBep20Delegator:fallback: cannot send value to fallback");

        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize)
            }
            default {
                return(free_mem_ptr, returndatasize)
            }
        }
    }

    /**
     * @notice Sender supplies assets into the market and receives vTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function mint(uint mintAmount) external returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("mint(uint256)", mintAmount));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Sender supplies assets into the market and receiver receives vTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function mintBehalf(address receiver, uint mintAmount) external returns (uint) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("mintBehalf(address,uint256)", receiver, mintAmount)
        );
        return abi.decode(data, (uint));
    }

    /**
     * @notice Sender redeems vTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of vTokens to redeem into underlying asset
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function redeem(uint redeemTokens) external returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("redeem(uint256)", redeemTokens));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Sender redeems vTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("redeemUnderlying(uint256)", redeemAmount)
        );
        return abi.decode(data, (uint));
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function borrow(uint borrowAmount) external returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("borrow(uint256)", borrowAmount));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function repayBorrow(uint repayAmount) external returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("repayBorrow(uint256)", repayAmount));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Sender repays a borrow belonging to another borrower
     * @param borrower The account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("repayBorrowBehalf(address,uint256)", borrower, repayAmount)
        );
        return abi.decode(data, (uint));
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this vToken to be liquidated
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function liquidateBorrow(
        address borrower,
        uint repayAmount,
        VTokenInterface vTokenCollateral
    ) external returns (uint) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("liquidateBorrow(address,uint256,address)", borrower, repayAmount, vTokenCollateral)
        );
        return abi.decode(data, (uint));
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint amount) external returns (bool) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("transfer(address,uint256)", dst, amount));
        return abi.decode(data, (bool));
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", src, dst, amount)
        );
        return abi.decode(data, (bool));
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("approve(address,uint256)", spender, amount)
        );
        return abi.decode(data, (bool));
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("balanceOfUnderlying(address)", owner));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("totalBorrowsCurrent()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("borrowBalanceCurrent(address)", account));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Will fail unless called by another vToken during the process of liquidation.
     *  It's absolutely critical to use msg.sender as the borrowed vToken and not a parameter.
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of vTokens to seize
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("seize(address,address,uint256)", liquidator, borrower, seizeTokens)
        );
        return abi.decode(data, (uint));
    }

    /*** Admin Functions ***/

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("_setPendingAdmin(address)", newPendingAdmin)
        );
        return abi.decode(data, (uint));
    }

    /**
     * @notice Accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
     * @dev Admin function to accrue interest and set a new reserve factor
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("_setReserveFactor(uint256)", newReserveFactorMantissa)
        );
        return abi.decode(data, (uint));
    }

    /**
     * @notice Accepts transfer of admin rights. `msg.sender` must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function _acceptAdmin() external returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_acceptAdmin()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Accrues interest and adds reserves by transferring from admin
     * @param addAmount Amount of reserves to add
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function _addReserves(uint addAmount) external returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_addReserves(uint256)", addAmount));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Accrues interest and reduces reserves by transferring to admin
     * @param reduceAmount Amount of reduction to reserves
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function _reduceReserves(uint reduceAmount) external returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_reduceReserves(uint256)", reduceAmount));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Get cash balance of this vToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("getCash()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint) {
        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("allowance(address,address)", owner, spender)
        );
        return abi.decode(data, (uint));
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("balanceOf(address)", owner));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Get a snapshot of the account's balances and the cached exchange rate
     * @dev This is used by comptroller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (possible error, token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint) {
        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("getAccountSnapshot(address)", account)
        );
        return abi.decode(data, (uint, uint, uint, uint));
    }

    /**
     * @notice Returns the current per-block borrow interest rate for this vToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("borrowRatePerBlock()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Returns the current per-block supply interest rate for this vToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("supplyRatePerBlock()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    // @custom:access Only callable by admin
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) public {
        require(msg.sender == admin, "VBep20Delegator::_setImplementation: Caller must be admin");

        if (allowResign) {
            delegateToImplementation(abi.encodeWithSignature("_resignImplementation()"));
        }

        address oldImplementation = implementation;
        implementation = implementation_;

        delegateToImplementation(abi.encodeWithSignature("_becomeImplementation(bytes)", becomeImplementationData));

        emit NewImplementation(oldImplementation, implementation);
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() public returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("exchangeRateCurrent()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Applies accrued interest to total borrows and reserves.
     * @dev This calculates interest accrued from the last checkpointed block
     *      up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() public returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("accrueInterest()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Sets a new comptroller for the market
     * @dev Admin function to set a new comptroller
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function _setComptroller(ComptrollerInterface newComptroller) public returns (uint) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("_setComptroller(address)", newComptroller)
        );
        return abi.decode(data, (uint));
    }

    /**
     * @notice Accrues interest and updates the interest rate model using `_setInterestRateModelFresh`
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel The new interest rate model to use
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint) {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("_setInterestRateModel(address)", newInterestRateModel)
        );
        return abi.decode(data, (uint));
    }

    /**
     * @notice Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        return delegateTo(implementation, data);
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(
            abi.encodeWithSignature("delegateToImplementation(bytes)", data)
        );
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return abi.decode(returnData, (bytes));
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) public view returns (uint) {
        bytes memory data = delegateToViewImplementation(
            abi.encodeWithSignature("borrowBalanceStored(address)", account)
        );
        return abi.decode(data, (uint));
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the VToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() public view returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("exchangeRateStored()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }
}

pragma solidity ^0.5.16;

import "./VBep20.sol";

/**
 * @title Venus's VBep20Immutable Contract
 * @notice VTokens which wrap an EIP-20 underlying and are immutable
 * @author Venus
 */
contract VBep20Immutable is VBep20 {
    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param comptroller_ The address of the comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ BEP-20 name of this token
     * @param symbol_ BEP-20 symbol of this token
     * @param decimals_ BEP-20 decimal precision of this token
     * @param admin_ Address of the administrator of this token
     */
    constructor(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_
    ) public {
        // Creator of the contract is admin during initialization
        admin = msg.sender;

        // Initialize the market
        initialize(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_
        );

        // Set the proper admin now that initialization is done
        admin = admin_;
    }
}

pragma solidity ^0.5.16;

import "./VToken.sol";

/**
 * @title Venus's vBNB Contract
 * @notice vToken which wraps BNB
 * @author Venus
 */
contract VBNB is VToken {
    /**
     * @notice Construct a new vBNB money market
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ BEP-20 name of this token
     * @param symbol_ BEP-20 symbol of this token
     * @param decimals_ BEP-20 decimal precision of this token
     * @param admin_ Address of the administrator of this token
     */
    constructor(
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_
    ) public {
        // Creator of the contract is admin during initialization
        admin = msg.sender;

        initialize(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

        // Set the proper admin now that initialization is done
        admin = admin_;
    }

    /**
     * @notice Send BNB to VBNB to mint
     */
    function() external payable {
        (uint err, ) = mintInternal(msg.value);
        requireNoError(err, "mint failed");
    }

    /*** User Interface ***/

    /**
     * @notice Sender supplies assets into the market and receives vTokens in exchange
     * @dev Reverts upon any failure
     */
    // @custom:event Emits Transfer event
    // @custom:event Emits Mint event
    function mint() external payable {
        (uint err, ) = mintInternal(msg.value);
        requireNoError(err, "mint failed");
    }

    /**
     * @notice Sender redeems vTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of vTokens to redeem into underlying
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Redeem event on success
    // @custom:event Emits Transfer event on success
    // @custom:event Emits RedeemFee when fee is charged by the treasury
    function redeem(uint redeemTokens) external returns (uint) {
        return redeemInternal(msg.sender, msg.sender, redeemTokens);
    }

    /**
     * @notice Sender redeems vTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Redeem event on success
    // @custom:event Emits Transfer event on success
    // @custom:event Emits RedeemFee when fee is charged by the treasury
    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        return redeemUnderlyingInternal(msg.sender, msg.sender, redeemAmount);
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Borrow event on success
    function borrow(uint borrowAmount) external returns (uint) {
        return borrowInternal(msg.sender, msg.sender, borrowAmount);
    }

    /**
     * @notice Sender repays their own borrow
     * @dev Reverts upon any failure
     */
    // @custom:event Emits RepayBorrow event on success
    function repayBorrow() external payable {
        (uint err, ) = repayBorrowInternal(msg.value);
        requireNoError(err, "repayBorrow failed");
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @dev Reverts upon any failure
     * @param borrower The account with the debt being payed off
     */
    // @custom:event Emits RepayBorrow event on success
    function repayBorrowBehalf(address borrower) external payable {
        (uint err, ) = repayBorrowBehalfInternal(borrower, msg.value);
        requireNoError(err, "repayBorrowBehalf failed");
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @dev Reverts upon any failure
     * @param borrower The borrower of this vToken to be liquidated
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     */
    // @custom:event Emit LiquidateBorrow event on success
    function liquidateBorrow(address borrower, VToken vTokenCollateral) external payable {
        (uint err, ) = liquidateBorrowInternal(borrower, msg.value, vTokenCollateral);
        requireNoError(err, "liquidateBorrow failed");
    }

    /*** Safe Token ***/

    /**
     * @notice Perform the actual transfer in, which is a no-op
     * @param from Address sending the BNB
     * @param amount Amount of BNB being sent
     * @return The actual amount of BNB transferred
     */
    function doTransferIn(address from, uint amount) internal returns (uint) {
        // Sanity checks
        require(msg.sender == from, "sender mismatch");
        require(msg.value == amount, "value mismatch");
        return amount;
    }

    function doTransferOut(address payable to, uint amount) internal {
        /* Send the BNB, with minimal gas and revert on failure */
        to.transfer(amount);
    }

    /**
     * @notice Gets balance of this contract in terms of BNB, before this message
     * @dev This excludes the value of the current message, if any
     * @return The quantity of BNB owned by this contract
     */
    function getCashPrior() internal view returns (uint) {
        (MathError err, uint startingBalance) = subUInt(address(this).balance, msg.value);
        require(err == MathError.NO_ERROR, "cash prior math error");
        return startingBalance;
    }

    function requireNoError(uint errCode, string memory message) internal pure {
        if (errCode == uint(Error.NO_ERROR)) {
            return;
        }

        bytes memory fullMessage = new bytes(bytes(message).length + 5);
        uint i;

        for (i = 0; i < bytes(message).length; i++) {
            fullMessage[i] = bytes(message)[i];
        }

        fullMessage[i + 0] = bytes1(uint8(32));
        fullMessage[i + 1] = bytes1(uint8(40));
        fullMessage[i + 2] = bytes1(uint8(48 + (errCode / 10)));
        fullMessage[i + 3] = bytes1(uint8(48 + (errCode % 10)));
        fullMessage[i + 4] = bytes1(uint8(41));

        require(errCode == uint(Error.NO_ERROR), string(fullMessage));
    }
}

pragma solidity ^0.5.16;

import "../../Comptroller/ComptrollerInterface.sol";
import "../../Utils/ErrorReporter.sol";
import "../../Utils/Exponential.sol";
import "../../Tokens/EIP20Interface.sol";
import "../../Tokens/EIP20NonStandardInterface.sol";
import "../../InterestRateModels/InterestRateModel.sol";
import "./VTokenInterfaces.sol";
import { IAccessControlManagerV5 } from "@venusprotocol/governance-contracts/contracts/Governance/IAccessControlManagerV5.sol";

/**
 * @title Venus's vToken Contract
 * @notice Abstract base for vTokens
 * @author Venus
 */
contract VToken is VTokenInterface, Exponential, TokenErrorReporter {
    struct MintLocalVars {
        MathError mathErr;
        uint exchangeRateMantissa;
        uint mintTokens;
        uint totalSupplyNew;
        uint accountTokensNew;
        uint actualMintAmount;
    }

    struct RedeemLocalVars {
        MathError mathErr;
        uint exchangeRateMantissa;
        uint redeemTokens;
        uint redeemAmount;
        uint totalSupplyNew;
        uint accountTokensNew;
    }

    struct BorrowLocalVars {
        MathError mathErr;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
    }

    struct RepayBorrowLocalVars {
        Error err;
        MathError mathErr;
        uint repayAmount;
        uint borrowerIndex;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
        uint actualRepayAmount;
    }

    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    // @custom:event Emits Transfer event
    function transfer(address dst, uint256 amount) external nonReentrant returns (bool) {
        return transferTokens(msg.sender, msg.sender, dst, amount) == uint(Error.NO_ERROR);
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    // @custom:event Emits Transfer event
    function transferFrom(address src, address dst, uint256 amount) external nonReentrant returns (bool) {
        return transferTokens(msg.sender, src, dst, amount) == uint(Error.NO_ERROR);
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    // @custom:event Emits Approval event on successful approve
    function approve(address spender, uint256 amount) external returns (bool) {
        transferAllowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint) {
        Exp memory exchangeRate = Exp({ mantissa: exchangeRateCurrent() });
        (MathError mErr, uint balance) = mulScalarTruncate(exchangeRate, accountTokens[owner]);
        ensureNoMathError(mErr);
        return balance;
    }

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
        return totalBorrows;
    }

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
        return borrowBalanceStored(account);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Will fail unless called by another vToken during the process of liquidation.
     *  Its absolutely critical to use msg.sender as the borrowed vToken and not a parameter.
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of vTokens to seize
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits Transfer event
    function seize(address liquidator, address borrower, uint seizeTokens) external nonReentrant returns (uint) {
        return seizeInternal(msg.sender, liquidator, borrower, seizeTokens);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits NewPendingAdmin event with old and new admin addresses
    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint) {
        // Check caller = admin
        ensureAdmin(msg.sender);

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits NewAdmin event on successful acceptance
    // @custom:event Emits NewPendingAdmin event with null new pending admin
    function _acceptAdmin() external returns (uint) {
        // Check caller is pendingAdmin
        if (msg.sender != pendingAdmin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice accrues interest and sets a new reserve factor for the protocol using `_setReserveFactorFresh`
     * @dev Governor function to accrue interest and set a new reserve factor
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits NewReserveFactor event
    function _setReserveFactor(uint newReserveFactorMantissa_) external nonReentrant returns (uint) {
        ensureAllowed("_setReserveFactor(uint256)");
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reserve factor change failed.
            return fail(Error(error), FailureInfo.SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED);
        }
        // _setReserveFactorFresh emits reserve-factor-specific logs on errors, so we don't need to.
        return _setReserveFactorFresh(newReserveFactorMantissa_);
    }

    /**
     * @notice Sets the address of the access control manager of this contract
     * @dev Admin function to set the access control address
     * @param newAccessControlManagerAddress New address for the access control
     * @return uint 0=success, otherwise will revert
     */
    function setAccessControlManager(address newAccessControlManagerAddress) external returns (uint) {
        // Check caller is admin
        ensureAdmin(msg.sender);

        ensureNonZeroAddress(newAccessControlManagerAddress);

        emit NewAccessControlManager(accessControlManager, newAccessControlManagerAddress);
        accessControlManager = newAccessControlManagerAddress;

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accrues interest and reduces reserves by transferring to protocol share reserve
     * @param reduceAmount_ Amount of reduction to reserves
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits ReservesReduced event
    function _reduceReserves(uint reduceAmount_) external nonReentrant returns (uint) {
        ensureAllowed("_reduceReserves(uint256)");
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
            return fail(Error(error), FailureInfo.REDUCE_RESERVES_ACCRUE_INTEREST_FAILED);
        }

        // If reserves were reduced in accrueInterest
        if (reduceReservesBlockNumber == block.number) return (uint(Error.NO_ERROR));
        // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
        return _reduceReservesFresh(reduceAmount_);
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256) {
        return accountTokens[owner];
    }

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by comptroller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (possible error, token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint) {
        uint vTokenBalance = accountTokens[account];
        uint borrowBalance;
        uint exchangeRateMantissa;

        MathError mErr;

        (mErr, borrowBalance) = borrowBalanceStoredInternal(account);
        if (mErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0, 0, 0);
        }

        (mErr, exchangeRateMantissa) = exchangeRateStoredInternal();
        if (mErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0, 0, 0);
        }

        return (uint(Error.NO_ERROR), vTokenBalance, borrowBalance, exchangeRateMantissa);
    }

    /**
     * @notice Returns the current per-block supply interest rate for this vToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint) {
        return interestRateModel.getSupplyRate(getCashPrior(), totalBorrows, totalReserves, reserveFactorMantissa);
    }

    /**
     * @notice Returns the current per-block borrow interest rate for this vToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint) {
        return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
    }

    /**
     * @notice Get cash balance of this vToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint) {
        return getCashPrior();
    }

    /**
     * @notice Governance function to set new threshold of block difference after which funds will be sent to the protocol share reserve
     * @param newReduceReservesBlockDelta_ block difference value
     */
    function setReduceReservesBlockDelta(uint256 newReduceReservesBlockDelta_) external {
        require(newReduceReservesBlockDelta_ > 0, "Invalid Input");
        ensureAllowed("setReduceReservesBlockDelta(uint256)");
        emit NewReduceReservesBlockDelta(reduceReservesBlockDelta, newReduceReservesBlockDelta_);
        reduceReservesBlockDelta = newReduceReservesBlockDelta_;
    }

    /**
     * @notice Sets protocol share reserve contract address
     * @param protcolShareReserve_ The address of protocol share reserve contract
     */
    function setProtocolShareReserve(address payable protcolShareReserve_) external {
        // Check caller is admin
        ensureAdmin(msg.sender);
        ensureNonZeroAddress(protcolShareReserve_);
        emit NewProtocolShareReserve(protocolShareReserve, protcolShareReserve_);
        protocolShareReserve = protcolShareReserve_;
    }

    /**
     * @notice Initialize the money market
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ EIP-20 name of this token
     * @param symbol_ EIP-20 symbol of this token
     * @param decimals_ EIP-20 decimal precision of this token
     */
    function initialize(
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public {
        ensureAdmin(msg.sender);
        require(accrualBlockNumber == 0 && borrowIndex == 0, "market may only be initialized once");

        // Set initial exchange rate
        initialExchangeRateMantissa = initialExchangeRateMantissa_;
        require(initialExchangeRateMantissa > 0, "initial exchange rate must be greater than zero.");

        // Set the comptroller
        uint err = _setComptroller(comptroller_);
        require(err == uint(Error.NO_ERROR), "setting comptroller failed");

        // Initialize block number and borrow index (block number mocks depend on comptroller being set)
        accrualBlockNumber = block.number;
        borrowIndex = mantissaOne;

        // Set the interest rate model (depends on block number / borrow index)
        err = _setInterestRateModelFresh(interestRateModel_);
        require(err == uint(Error.NO_ERROR), "setting interest rate model failed");

        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() public nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
        return exchangeRateStored();
    }

    /**
     * @notice Applies accrued interest to total borrows and reserves
     * @dev This calculates interest accrued from the last checkpointed block
     * up to the current block and writes new checkpoint to storage and
     * reduce spread reserves to protocol share reserve
     * if currentBlock - reduceReservesBlockNumber >= blockDelta
     */
    // @custom:event Emits AccrueInterest event
    function accrueInterest() public returns (uint) {
        /* Remember the initial block number */
        uint currentBlockNumber = block.number;
        uint accrualBlockNumberPrior = accrualBlockNumber;

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockNumberPrior == currentBlockNumber) {
            return uint(Error.NO_ERROR);
        }

        /* Read the previous values out of storage */
        uint cashPrior = getCashPrior();
        uint borrowsPrior = totalBorrows;
        uint reservesPrior = totalReserves;
        uint borrowIndexPrior = borrowIndex;

        /* Calculate the current borrow interest rate */
        uint borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
        require(borrowRateMantissa <= borrowRateMaxMantissa, "borrow rate is absurdly high");

        /* Calculate the number of blocks elapsed since the last accrual */
        (MathError mathErr, uint blockDelta) = subUInt(currentBlockNumber, accrualBlockNumberPrior);
        ensureNoMathError(mathErr);

        /*
         * Calculate the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrowsNew = interestAccumulated + totalBorrows
         *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
         *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
         */

        Exp memory simpleInterestFactor;
        uint interestAccumulated;
        uint totalBorrowsNew;
        uint totalReservesNew;
        uint borrowIndexNew;

        (mathErr, simpleInterestFactor) = mulScalar(Exp({ mantissa: borrowRateMantissa }), blockDelta);
        if (mathErr != MathError.NO_ERROR) {
            return
                failOpaque(
                    Error.MATH_ERROR,
                    FailureInfo.ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
                    uint(mathErr)
                );
        }

        (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return
                failOpaque(
                    Error.MATH_ERROR,
                    FailureInfo.ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
                    uint(mathErr)
                );
        }

        (mathErr, totalBorrowsNew) = addUInt(interestAccumulated, borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return
                failOpaque(
                    Error.MATH_ERROR,
                    FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
                    uint(mathErr)
                );
        }

        (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(
            Exp({ mantissa: reserveFactorMantissa }),
            interestAccumulated,
            reservesPrior
        );
        if (mathErr != MathError.NO_ERROR) {
            return
                failOpaque(
                    Error.MATH_ERROR,
                    FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
                    uint(mathErr)
                );
        }

        (mathErr, borrowIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);
        if (mathErr != MathError.NO_ERROR) {
            return
                failOpaque(
                    Error.MATH_ERROR,
                    FailureInfo.ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
                    uint(mathErr)
                );
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        (mathErr, blockDelta) = subUInt(currentBlockNumber, reduceReservesBlockNumber);
        ensureNoMathError(mathErr);
        if (blockDelta >= reduceReservesBlockDelta) {
            reduceReservesBlockNumber = currentBlockNumber;
            if (cashPrior < totalReservesNew) {
                _reduceReservesFresh(cashPrior);
            } else {
                _reduceReservesFresh(totalReservesNew);
            }
        }

        /* We emit an AccrueInterest event */
        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sets a new comptroller for the market
     * @dev Admin function to set a new comptroller
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // @custom:event Emits NewComptroller event
    function _setComptroller(ComptrollerInterface newComptroller) public returns (uint) {
        // Check caller is admin
        ensureAdmin(msg.sender);

        ComptrollerInterface oldComptroller = comptroller;
        // Ensure invoke comptroller.isComptroller() returns true
        require(newComptroller.isComptroller(), "marker method returned false");

        // Set market's comptroller to newComptroller
        comptroller = newComptroller;

        // Emit NewComptroller(oldComptroller, newComptroller)
        emit NewComptroller(oldComptroller, newComptroller);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accrues interest and updates the interest rate model using _setInterestRateModelFresh
     * @dev Governance function to accrue interest and update the interest rate model
     * @param newInterestRateModel_ The new interest rate model to use
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function _setInterestRateModel(InterestRateModel newInterestRateModel_) public returns (uint) {
        ensureAllowed("_setInterestRateModel(address)");
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted change of interest rate model failed
            return fail(Error(error), FailureInfo.SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED);
        }
        // _setInterestRateModelFresh emits interest-rate-model-update-specific logs on errors, so we don't need to.
        return _setInterestRateModelFresh(newInterestRateModel_);
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the VToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() public view returns (uint) {
        (MathError err, uint result) = exchangeRateStoredInternal();
        ensureNoMathError(err);
        return result;
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) public view returns (uint) {
        (MathError err, uint result) = borrowBalanceStoredInternal(account);
        ensureNoMathError(err);
        return result;
    }

    /**
     * @notice Transfers `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferTokens(address spender, address src, address dst, uint tokens) internal returns (uint) {
        /* Fail if transfer not allowed */
        uint allowed = comptroller.transferAllowed(address(this), src, dst, tokens);
        if (allowed != 0) {
            return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.TRANSFER_COMPTROLLER_REJECTION, allowed);
        }

        /* Do not allow self-transfers */
        if (src == dst) {
            return fail(Error.BAD_INPUT, FailureInfo.TRANSFER_NOT_ALLOWED);
        }

        /* Get the allowance, infinite for the account owner */
        uint startingAllowance = 0;
        if (spender == src) {
            startingAllowance = uint(-1);
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        /* Do the calculations, checking for {under,over}flow */
        MathError mathErr;
        uint allowanceNew;
        uint srvTokensNew;
        uint dstTokensNew;

        (mathErr, allowanceNew) = subUInt(startingAllowance, tokens);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ALLOWED);
        }

        (mathErr, srvTokensNew) = subUInt(accountTokens[src], tokens);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ENOUGH);
        }

        (mathErr, dstTokensNew) = addUInt(accountTokens[dst], tokens);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_TOO_MUCH);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        accountTokens[src] = srvTokensNew;
        accountTokens[dst] = dstTokensNew;

        /* Eat some of the allowance (if necessary) */
        if (startingAllowance != uint(-1)) {
            transferAllowances[src][spender] = allowanceNew;
        }

        /* We emit a Transfer event */
        emit Transfer(src, dst, tokens);

        comptroller.transferVerify(address(this), src, dst, tokens);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sender supplies assets into the market and receives vTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
     */
    function mintInternal(uint mintAmount) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted mint failed
            return (fail(Error(error), FailureInfo.MINT_ACCRUE_INTEREST_FAILED), 0);
        }
        // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
        return mintFresh(msg.sender, mintAmount);
    }

    /**
     * @notice User supplies assets into the market and receives vTokens in exchange
     * @dev Assumes interest has already been accrued up to the current block
     * @param minter The address of the account which is supplying the assets
     * @param mintAmount The amount of the underlying asset to supply
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
     */
    function mintFresh(address minter, uint mintAmount) internal returns (uint, uint) {
        /* Fail if mint not allowed */
        uint allowed = comptroller.mintAllowed(address(this), minter, mintAmount);
        if (allowed != 0) {
            return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.MINT_COMPTROLLER_REJECTION, allowed), 0);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != block.number) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.MINT_FRESHNESS_CHECK), 0);
        }

        MintLocalVars memory vars;

        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.MINT_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr)), 0);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         *  We call `doTransferIn` for the minter and the mintAmount.
         *  Note: The vToken must handle variations between BEP-20 and BNB underlying.
         *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
         *  side-effects occurred. The function returns the amount actually transferred,
         *  in case of a fee. On success, the vToken holds an additional `actualMintAmount`
         *  of cash.
         */
        vars.actualMintAmount = doTransferIn(minter, mintAmount);

        /*
         * We get the current exchange rate and calculate the number of vTokens to be minted:
         *  mintTokens = actualMintAmount / exchangeRate
         */

        (vars.mathErr, vars.mintTokens) = divScalarByExpTruncate(
            vars.actualMintAmount,
            Exp({ mantissa: vars.exchangeRateMantissa })
        );
        ensureNoMathError(vars.mathErr);

        /*
         * We calculate the new total supply of vTokens and minter token balance, checking for overflow:
         *  totalSupplyNew = totalSupply + mintTokens
         *  accountTokensNew = accountTokens[minter] + mintTokens
         */
        (vars.mathErr, vars.totalSupplyNew) = addUInt(totalSupply, vars.mintTokens);
        ensureNoMathError(vars.mathErr);
        (vars.mathErr, vars.accountTokensNew) = addUInt(accountTokens[minter], vars.mintTokens);
        ensureNoMathError(vars.mathErr);

        /* We write previously calculated values into storage */
        totalSupply = vars.totalSupplyNew;
        accountTokens[minter] = vars.accountTokensNew;

        /* We emit a Mint event, and a Transfer event */
        emit Mint(minter, vars.actualMintAmount, vars.mintTokens, vars.accountTokensNew);
        emit Transfer(address(this), minter, vars.mintTokens);

        /* We call the defense and prime accrue interest hook */
        comptroller.mintVerify(address(this), minter, vars.actualMintAmount, vars.mintTokens);

        return (uint(Error.NO_ERROR), vars.actualMintAmount);
    }

    /**
     * @notice Sender supplies assets into the market and receiver receives vTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param receiver The address of the account which is receiving the vTokens
     * @param mintAmount The amount of the underlying asset to supply
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
     */
    function mintBehalfInternal(address receiver, uint mintAmount) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted mintBehalf failed
            return (fail(Error(error), FailureInfo.MINT_ACCRUE_INTEREST_FAILED), 0);
        }
        // mintBelahfFresh emits the actual Mint event if successful and logs on errors, so we don't need to
        return mintBehalfFresh(msg.sender, receiver, mintAmount);
    }

    /**
     * @notice Payer supplies assets into the market and receiver receives vTokens in exchange
     * @dev Assumes interest has already been accrued up to the current block
     * @param payer The address of the account which is paying the underlying token
     * @param receiver The address of the account which is receiving vToken
     * @param mintAmount The amount of the underlying asset to supply
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
     */
    function mintBehalfFresh(address payer, address receiver, uint mintAmount) internal returns (uint, uint) {
        ensureNonZeroAddress(receiver);
        /* Fail if mint not allowed */
        uint allowed = comptroller.mintAllowed(address(this), receiver, mintAmount);
        if (allowed != 0) {
            return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.MINT_COMPTROLLER_REJECTION, allowed), 0);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != block.number) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.MINT_FRESHNESS_CHECK), 0);
        }

        MintLocalVars memory vars;

        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.MINT_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr)), 0);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         *  We call `doTransferIn` for the payer and the mintAmount.
         *  Note: The vToken must handle variations between BEP-20 and BNB underlying.
         *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
         *  side-effects occurred. The function returns the amount actually transferred,
         *  in case of a fee. On success, the vToken holds an additional `actualMintAmount`
         *  of cash.
         */
        vars.actualMintAmount = doTransferIn(payer, mintAmount);

        /*
         * We get the current exchange rate and calculate the number of vTokens to be minted:
         *  mintTokens = actualMintAmount / exchangeRate
         */

        (vars.mathErr, vars.mintTokens) = divScalarByExpTruncate(
            vars.actualMintAmount,
            Exp({ mantissa: vars.exchangeRateMantissa })
        );
        ensureNoMathError(vars.mathErr);

        /*
         * We calculate the new total supply of vTokens and receiver token balance, checking for overflow:
         *  totalSupplyNew = totalSupply + mintTokens
         *  accountTokensNew = accountTokens[receiver] + mintTokens
         */
        (vars.mathErr, vars.totalSupplyNew) = addUInt(totalSupply, vars.mintTokens);
        ensureNoMathError(vars.mathErr);

        (vars.mathErr, vars.accountTokensNew) = addUInt(accountTokens[receiver], vars.mintTokens);
        ensureNoMathError(vars.mathErr);

        /* We write previously calculated values into storage */
        totalSupply = vars.totalSupplyNew;
        accountTokens[receiver] = vars.accountTokensNew;

        /* We emit a MintBehalf event, and a Transfer event */
        emit MintBehalf(payer, receiver, vars.actualMintAmount, vars.mintTokens, vars.accountTokensNew);
        emit Transfer(address(this), receiver, vars.mintTokens);

        /* We call the defense and prime accrue interest hook */
        comptroller.mintVerify(address(this), receiver, vars.actualMintAmount, vars.mintTokens);

        return (uint(Error.NO_ERROR), vars.actualMintAmount);
    }

    /**
     * @notice Redeemer redeems vTokens in exchange for the underlying assets, transferred to the receiver. Redeemer and receiver can be the same
     *   address, or different addresses if the receiver was previously approved by the redeemer as a valid delegate (see MarketFacet.updateDelegate)
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemer The address of the account which is redeeming the tokens
     * @param receiver The receiver of the tokens
     * @param redeemTokens The number of vTokens to redeem into underlying
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function redeemInternal(
        address redeemer,
        address payable receiver,
        uint redeemTokens
    ) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
            return fail(Error(error), FailureInfo.REDEEM_ACCRUE_INTEREST_FAILED);
        }
        // redeemFresh emits redeem-specific logs on errors, so we don't need to
        return redeemFresh(redeemer, receiver, redeemTokens, 0);
    }

    /**
     * @notice Sender redeems underlying assets on behalf of some other address. This function is only available
     *   for senders, explicitly marked as delegates of the supplier using `comptroller.updateDelegate`
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemer The address of the account which is redeeming the tokens
     * @param receiver The receiver of the tokens, if called by a delegate
     * @param redeemAmount The amount of underlying to receive from redeeming vTokens
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function redeemUnderlyingInternal(
        address redeemer,
        address payable receiver,
        uint redeemAmount
    ) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
            return fail(Error(error), FailureInfo.REDEEM_ACCRUE_INTEREST_FAILED);
        }
        // redeemFresh emits redeem-specific logs on errors, so we don't need to
        return redeemFresh(redeemer, receiver, 0, redeemAmount);
    }

    /**
     * @notice Redeemer redeems vTokens in exchange for the underlying assets, transferred to the receiver. Redeemer and receiver can be the same
     *   address, or different addresses if the receiver was previously approved by the redeemer as a valid delegate (see MarketFacet.updateDelegate)
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming the tokens
     * @param receiver The receiver of the tokens
     * @param redeemTokensIn The number of vTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmountIn The number of underlying tokens to receive from redeeming vTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    // solhint-disable-next-line code-complexity
    function redeemFresh(
        address redeemer,
        address payable receiver,
        uint redeemTokensIn,
        uint redeemAmountIn
    ) internal returns (uint) {
        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

        RedeemLocalVars memory vars;

        /* exchangeRate = invoke Exchange Rate Stored() */
        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
        ensureNoMathError(vars.mathErr);

        /* If redeemTokensIn > 0: */
        if (redeemTokensIn > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokensIn
             *  redeemAmount = redeemTokensIn x exchangeRateCurrent
             */
            vars.redeemTokens = redeemTokensIn;

            (vars.mathErr, vars.redeemAmount) = mulScalarTruncate(
                Exp({ mantissa: vars.exchangeRateMantissa }),
                redeemTokensIn
            );
            ensureNoMathError(vars.mathErr);
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmountIn / exchangeRate
             *  redeemAmount = redeemAmountIn
             */

            (vars.mathErr, vars.redeemTokens) = divScalarByExpTruncate(
                redeemAmountIn,
                Exp({ mantissa: vars.exchangeRateMantissa })
            );
            ensureNoMathError(vars.mathErr);

            vars.redeemAmount = redeemAmountIn;
        }

        /* Fail if redeem not allowed */
        uint allowed = comptroller.redeemAllowed(address(this), redeemer, vars.redeemTokens);
        if (allowed != 0) {
            revert("math error");
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != block.number) {
            revert("math error");
        }

        /*
         * We calculate the new total supply and redeemer balance, checking for underflow:
         *  totalSupplyNew = totalSupply - redeemTokens
         *  accountTokensNew = accountTokens[redeemer] - redeemTokens
         */
        (vars.mathErr, vars.totalSupplyNew) = subUInt(totalSupply, vars.redeemTokens);
        ensureNoMathError(vars.mathErr);

        (vars.mathErr, vars.accountTokensNew) = subUInt(accountTokens[redeemer], vars.redeemTokens);
        ensureNoMathError(vars.mathErr);

        /* Fail gracefully if protocol has insufficient cash */
        if (getCashPrior() < vars.redeemAmount) {
            revert("math error");
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write previously calculated values into storage */
        totalSupply = vars.totalSupplyNew;
        accountTokens[redeemer] = vars.accountTokensNew;

        /*
         * We invoke doTransferOut for the receiver and the redeemAmount.
         *  Note: The vToken must handle variations between BEP-20 and BNB underlying.
         *  On success, the vToken has redeemAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */

        uint feeAmount;
        uint remainedAmount;
        if (IComptroller(address(comptroller)).treasuryPercent() != 0) {
            (vars.mathErr, feeAmount) = mulUInt(
                vars.redeemAmount,
                IComptroller(address(comptroller)).treasuryPercent()
            );
            ensureNoMathError(vars.mathErr);

            (vars.mathErr, feeAmount) = divUInt(feeAmount, 1e18);
            ensureNoMathError(vars.mathErr);

            (vars.mathErr, remainedAmount) = subUInt(vars.redeemAmount, feeAmount);
            ensureNoMathError(vars.mathErr);

            doTransferOut(address(uint160(IComptroller(address(comptroller)).treasuryAddress())), feeAmount);

            emit RedeemFee(redeemer, feeAmount, vars.redeemTokens);
        } else {
            remainedAmount = vars.redeemAmount;
        }

        doTransferOut(receiver, remainedAmount);

        /* We emit a Transfer event, and a Redeem event */
        emit Transfer(redeemer, address(this), vars.redeemTokens);
        emit Redeem(redeemer, remainedAmount, vars.redeemTokens, vars.accountTokensNew);

        /* We call the defense and prime accrue interest hook */
        comptroller.redeemVerify(address(this), redeemer, vars.redeemAmount, vars.redeemTokens);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Receiver gets the borrow on behalf of the borrower address
     * @param borrower The borrower, on behalf of whom to borrow
     * @param receiver The account that would receive the funds (can be the same as the borrower)
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function borrowInternal(
        address borrower,
        address payable receiver,
        uint borrowAmount
    ) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return fail(Error(error), FailureInfo.BORROW_ACCRUE_INTEREST_FAILED);
        }
        // borrowFresh emits borrow-specific logs on errors, so we don't need to
        return borrowFresh(borrower, receiver, borrowAmount);
    }

    /**
     * @notice Receiver gets the borrow on behalf of the borrower address
     * @dev Before calling this function, ensure that the interest has been accrued
     * @param borrower The borrower, on behalf of whom to borrow
     * @param receiver The account that would receive the funds (can be the same as the borrower)
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint Returns 0 on success, otherwise revert (see ErrorReporter.sol for details).
     */
    function borrowFresh(address borrower, address payable receiver, uint borrowAmount) internal returns (uint) {
        /* Revert if borrow not allowed */
        uint allowed = comptroller.borrowAllowed(address(this), borrower, borrowAmount);
        if (allowed != 0) {
            revert("math error");
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != block.number) {
            revert("math error");
        }

        /* Revert if protocol has insufficient underlying cash */
        if (getCashPrior() < borrowAmount) {
            revert("math error");
        }

        BorrowLocalVars memory vars;

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowsNew = accountBorrows + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
        ensureNoMathError(vars.mathErr);

        (vars.mathErr, vars.accountBorrowsNew) = addUInt(vars.accountBorrows, borrowAmount);
        ensureNoMathError(vars.mathErr);

        (vars.mathErr, vars.totalBorrowsNew) = addUInt(totalBorrows, borrowAmount);
        ensureNoMathError(vars.mathErr);

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        accountBorrows[borrower].principal = vars.accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;

        /*
         * We invoke doTransferOut for the receiver and the borrowAmount.
         *  Note: The vToken must handle variations between BEP-20 and BNB underlying.
         *  On success, the vToken borrowAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        doTransferOut(receiver, borrowAmount);

        /* We emit a Borrow event */
        emit Borrow(borrower, borrowAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

        /* We call the defense and prime accrue interest hook */
        comptroller.borrowVerify(address(this), borrower, borrowAmount);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function repayBorrowInternal(uint repayAmount) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return (fail(Error(error), FailureInfo.REPAY_BORROW_ACCRUE_INTEREST_FAILED), 0);
        }
        // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        return repayBorrowFresh(msg.sender, msg.sender, repayAmount);
    }

    /**
     * @notice Sender repays a borrow belonging to another borrowing account
     * @param borrower The account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function repayBorrowBehalfInternal(address borrower, uint repayAmount) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return (fail(Error(error), FailureInfo.REPAY_BEHALF_ACCRUE_INTEREST_FAILED), 0);
        }
        // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        return repayBorrowFresh(msg.sender, borrower, repayAmount);
    }

    /**
     * @notice Borrows are repaid by another user (possibly the borrower).
     * @param payer The account paying off the borrow
     * @param borrower The account with the debt being payed off
     * @param repayAmount The amount of undelrying tokens being returned
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function repayBorrowFresh(address payer, address borrower, uint repayAmount) internal returns (uint, uint) {
        /* Fail if repayBorrow not allowed */
        uint allowed = comptroller.repayBorrowAllowed(address(this), payer, borrower, repayAmount);
        if (allowed != 0) {
            return (
                failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.REPAY_BORROW_COMPTROLLER_REJECTION, allowed),
                0
            );
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != block.number) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.REPAY_BORROW_FRESHNESS_CHECK), 0);
        }

        RepayBorrowLocalVars memory vars;

        /* We remember the original borrowerIndex for verification purposes */
        vars.borrowerIndex = accountBorrows[borrower].interestIndex;

        /* We fetch the amount the borrower owes, with accumulated interest */
        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (
                failOpaque(
                    Error.MATH_ERROR,
                    FailureInfo.REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
                    uint(vars.mathErr)
                ),
                0
            );
        }

        /* If repayAmount == -1, repayAmount = accountBorrows */
        if (repayAmount == uint(-1)) {
            vars.repayAmount = vars.accountBorrows;
        } else {
            vars.repayAmount = repayAmount;
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We call doTransferIn for the payer and the repayAmount
         *  Note: The vToken must handle variations between BEP-20 and BNB underlying.
         *  On success, the vToken holds an additional repayAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *   it returns the amount actually transferred, in case of a fee.
         */
        vars.actualRepayAmount = doTransferIn(payer, vars.repayAmount);

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        (vars.mathErr, vars.accountBorrowsNew) = subUInt(vars.accountBorrows, vars.actualRepayAmount);
        ensureNoMathError(vars.mathErr);

        (vars.mathErr, vars.totalBorrowsNew) = subUInt(totalBorrows, vars.actualRepayAmount);
        ensureNoMathError(vars.mathErr);

        /* We write the previously calculated values into storage */
        accountBorrows[borrower].principal = vars.accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;

        /* We emit a RepayBorrow event */
        emit RepayBorrow(payer, borrower, vars.actualRepayAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

        /* We call the defense and prime accrue interest hook */
        comptroller.repayBorrowVerify(address(this), payer, borrower, vars.actualRepayAmount, vars.borrowerIndex);

        return (uint(Error.NO_ERROR), vars.actualRepayAmount);
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this vToken to be liquidated
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function liquidateBorrowInternal(
        address borrower,
        uint repayAmount,
        VTokenInterface vTokenCollateral
    ) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
            return (fail(Error(error), FailureInfo.LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED), 0);
        }

        error = vTokenCollateral.accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
            return (fail(Error(error), FailureInfo.LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED), 0);
        }

        // liquidateBorrowFresh emits borrow-specific logs on errors, so we don't need to
        return liquidateBorrowFresh(msg.sender, borrower, repayAmount, vTokenCollateral);
    }

    /**
     * @notice The liquidator liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this vToken to be liquidated
     * @param liquidator The address repaying the borrow and seizing collateral
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    // solhint-disable-next-line code-complexity
    function liquidateBorrowFresh(
        address liquidator,
        address borrower,
        uint repayAmount,
        VTokenInterface vTokenCollateral
    ) internal returns (uint, uint) {
        /* Fail if liquidate not allowed */
        uint allowed = comptroller.liquidateBorrowAllowed(
            address(this),
            address(vTokenCollateral),
            liquidator,
            borrower,
            repayAmount
        );
        if (allowed != 0) {
            return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.LIQUIDATE_COMPTROLLER_REJECTION, allowed), 0);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != block.number) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.LIQUIDATE_FRESHNESS_CHECK), 0);
        }

        /* Verify vTokenCollateral market's block number equals current block number */
        if (vTokenCollateral.accrualBlockNumber() != block.number) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.LIQUIDATE_COLLATERAL_FRESHNESS_CHECK), 0);
        }

        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            return (fail(Error.INVALID_ACCOUNT_PAIR, FailureInfo.LIQUIDATE_LIQUIDATOR_IS_BORROWER), 0);
        }

        /* Fail if repayAmount = 0 */
        if (repayAmount == 0) {
            return (fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_ZERO), 0);
        }

        /* Fail if repayAmount = -1 */
        if (repayAmount == uint(-1)) {
            return (fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX), 0);
        }

        /* Fail if repayBorrow fails */
        (uint repayBorrowError, uint actualRepayAmount) = repayBorrowFresh(liquidator, borrower, repayAmount);
        if (repayBorrowError != uint(Error.NO_ERROR)) {
            return (fail(Error(repayBorrowError), FailureInfo.LIQUIDATE_REPAY_BORROW_FRESH_FAILED), 0);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We calculate the number of collateral tokens that will be seized */
        (uint amountSeizeError, uint seizeTokens) = comptroller.liquidateCalculateSeizeTokens(
            address(this),
            address(vTokenCollateral),
            actualRepayAmount
        );
        require(amountSeizeError == uint(Error.NO_ERROR), "LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED");

        /* Revert if borrower collateral token balance < seizeTokens */
        require(vTokenCollateral.balanceOf(borrower) >= seizeTokens, "LIQUIDATE_SEIZE_TOO_MUCH");

        // If this is also the collateral, run seizeInternal to avoid re-entrancy, otherwise make an external call
        uint seizeError;
        if (address(vTokenCollateral) == address(this)) {
            seizeError = seizeInternal(address(this), liquidator, borrower, seizeTokens);
        } else {
            seizeError = vTokenCollateral.seize(liquidator, borrower, seizeTokens);
        }

        /* Revert if seize tokens fails (since we cannot be sure of side effects) */
        require(seizeError == uint(Error.NO_ERROR), "token seizure failed");

        /* We emit a LiquidateBorrow event */
        emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(vTokenCollateral), seizeTokens);

        /* We call the defense and prime accrue interest hook */
        comptroller.liquidateBorrowVerify(
            address(this),
            address(vTokenCollateral),
            liquidator,
            borrower,
            actualRepayAmount,
            seizeTokens
        );

        return (uint(Error.NO_ERROR), actualRepayAmount);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another vToken.
     *  Its absolutely critical to use msg.sender as the seizer vToken and not a parameter.
     * @param seizerToken The contract seizing the collateral (i.e. borrowed vToken)
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of vTokens to seize
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function seizeInternal(
        address seizerToken,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) internal returns (uint) {
        /* Fail if seize not allowed */
        uint allowed = comptroller.seizeAllowed(address(this), seizerToken, liquidator, borrower, seizeTokens);
        if (allowed != 0) {
            return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.LIQUIDATE_SEIZE_COMPTROLLER_REJECTION, allowed);
        }

        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            return fail(Error.INVALID_ACCOUNT_PAIR, FailureInfo.LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER);
        }

        MathError mathErr;
        uint borrowerTokensNew;
        uint liquidatorTokensNew;

        /*
         * We calculate the new borrower and liquidator token balances, failing on underflow/overflow:
         *  borrowerTokensNew = accountTokens[borrower] - seizeTokens
         *  liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
         */
        (mathErr, borrowerTokensNew) = subUInt(accountTokens[borrower], seizeTokens);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED, uint(mathErr));
        }

        (mathErr, liquidatorTokensNew) = addUInt(accountTokens[liquidator], seizeTokens);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED, uint(mathErr));
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        accountTokens[borrower] = borrowerTokensNew;
        accountTokens[liquidator] = liquidatorTokensNew;

        /* Emit a Transfer event */
        emit Transfer(borrower, liquidator, seizeTokens);

        /* We call the defense and prime accrue interest hook */
        comptroller.seizeVerify(address(this), seizerToken, liquidator, borrower, seizeTokens);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sets a new reserve factor for the protocol (requires fresh interest accrual)
     * @dev Governance function to set a new reserve factor
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function _setReserveFactorFresh(uint newReserveFactorMantissa) internal returns (uint) {
        // Verify market's block number equals current block number
        if (accrualBlockNumber != block.number) {
            return fail(Error.MARKET_NOT_FRESH, FailureInfo.SET_RESERVE_FACTOR_FRESH_CHECK);
        }

        // Check newReserveFactor ≤ maxReserveFactor
        if (newReserveFactorMantissa > reserveFactorMaxMantissa) {
            return fail(Error.BAD_INPUT, FailureInfo.SET_RESERVE_FACTOR_BOUNDS_CHECK);
        }

        uint oldReserveFactorMantissa = reserveFactorMantissa;
        reserveFactorMantissa = newReserveFactorMantissa;

        emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accrues interest and adds reserves by transferring from `msg.sender`
     * @param addAmount Amount of addition to reserves
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function _addReservesInternal(uint addAmount) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
            return fail(Error(error), FailureInfo.ADD_RESERVES_ACCRUE_INTEREST_FAILED);
        }

        // _addReservesFresh emits reserve-addition-specific logs on errors, so we don't need to.
        (error, ) = _addReservesFresh(addAmount);
        return error;
    }

    /**
     * @notice Add reserves by transferring from caller
     * @dev Requires fresh interest accrual
     * @param addAmount Amount of addition to reserves
     * @return (uint, uint) An error code (0=success, otherwise a failure (see ErrorReporter.sol for details)) and the actual amount added, net token fees
     */
    function _addReservesFresh(uint addAmount) internal returns (uint, uint) {
        // totalReserves + actualAddAmount
        uint totalReservesNew;
        uint actualAddAmount;

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != block.number) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.ADD_RESERVES_FRESH_CHECK), actualAddAmount);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We call doTransferIn for the caller and the addAmount
         *  Note: The vToken must handle variations between BEP-20 and BNB underlying.
         *  On success, the vToken holds an additional addAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *  it returns the amount actually transferred, in case of a fee.
         */

        actualAddAmount = doTransferIn(msg.sender, addAmount);

        totalReservesNew = totalReserves + actualAddAmount;

        /* Revert on overflow */
        require(totalReservesNew >= totalReserves, "add reserves unexpected overflow");

        // Store reserves[n+1] = reserves[n] + actualAddAmount
        totalReserves = totalReservesNew;

        /* Emit NewReserves(admin, actualAddAmount, reserves[n+1]) */
        emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);

        /* Return (NO_ERROR, actualAddAmount) */
        return (uint(Error.NO_ERROR), actualAddAmount);
    }

    /**
     * @notice Reduces reserves by transferring to protocol share reserve contract
     * @dev Requires fresh interest accrual
     * @param reduceAmount Amount of reduction to reserves
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function _reduceReservesFresh(uint reduceAmount) internal returns (uint) {
        if (reduceAmount == 0) {
            return uint(Error.NO_ERROR);
        }

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != block.number) {
            return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDUCE_RESERVES_FRESH_CHECK);
        }

        // Fail gracefully if protocol has insufficient underlying cash
        if (getCashPrior() < reduceAmount) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDUCE_RESERVES_CASH_NOT_AVAILABLE);
        }

        // Check reduceAmount ≤ reserves[n] (totalReserves)
        if (reduceAmount > totalReserves) {
            return fail(Error.BAD_INPUT, FailureInfo.REDUCE_RESERVES_VALIDATION);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        // totalReserves - reduceAmount
        uint totalReservesNew = totalReserves - reduceAmount;

        // Store reserves[n+1] = reserves[n] - reduceAmount
        totalReserves = totalReservesNew;

        // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        doTransferOut(protocolShareReserve, reduceAmount);

        IProtocolShareReserveV5(protocolShareReserve).updateAssetsState(
            address(comptroller),
            underlying,
            IProtocolShareReserveV5.IncomeType.SPREAD
        );

        emit ReservesReduced(protocolShareReserve, reduceAmount, totalReservesNew);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice updates the interest rate model (requires fresh interest accrual)
     * @dev Governance function to update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @return uint Returns 0 on success, otherwise returns a failure code (see ErrorReporter.sol for details).
     */
    function _setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal returns (uint) {
        // Used to store old model for use in the event that is emitted on success
        InterestRateModel oldInterestRateModel;
        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != block.number) {
            return fail(Error.MARKET_NOT_FRESH, FailureInfo.SET_INTEREST_RATE_MODEL_FRESH_CHECK);
        }

        // Track the market's current interest rate model
        oldInterestRateModel = interestRateModel;

        // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
        require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

        // Set the interest rate model to newInterestRateModel
        interestRateModel = newInterestRateModel;

        // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel)
        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

        return uint(Error.NO_ERROR);
    }

    /*** Safe Token ***/

    /**
     * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
     *  This may revert due to insufficient balance or insufficient allowance.
     */
    function doTransferIn(address from, uint amount) internal returns (uint);

    /**
     * @dev Performs a transfer out, ideally returning an explanatory error code upon failure rather than reverting.
     *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
     *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
     */
    function doTransferOut(address payable to, uint amount) internal;

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return Tuple of error code and the calculated balance or 0 if error code is non-zero
     */
    function borrowBalanceStoredInternal(address account) internal view returns (MathError, uint) {
        /* Note: we do not assert that the market is up to date */
        MathError mathErr;
        uint principalTimesIndex;
        uint result;

        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) {
            return (MathError.NO_ERROR, 0);
        }

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        (mathErr, principalTimesIndex) = mulUInt(borrowSnapshot.principal, borrowIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        (mathErr, result) = divUInt(principalTimesIndex, borrowSnapshot.interestIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        return (MathError.NO_ERROR, result);
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the vToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Tuple of error code and calculated exchange rate scaled by 1e18
     */
    function exchangeRateStoredInternal() internal view returns (MathError, uint) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            /*
             * If there are no tokens minted:
             *  exchangeRate = initialExchangeRate
             */
            return (MathError.NO_ERROR, initialExchangeRateMantissa);
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
             */
            uint totalCash = getCashPrior();
            uint cashPlusBorrowsMinusReserves;
            Exp memory exchangeRate;
            MathError mathErr;

            (mathErr, cashPlusBorrowsMinusReserves) = addThenSubUInt(totalCash, totalBorrows, totalReserves);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            (mathErr, exchangeRate) = getExp(cashPlusBorrowsMinusReserves, _totalSupply);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            return (MathError.NO_ERROR, exchangeRate.mantissa);
        }
    }

    function ensureAllowed(string memory functionSig) private view {
        require(
            IAccessControlManagerV5(accessControlManager).isAllowedToCall(msg.sender, functionSig),
            "access denied"
        );
    }

    function ensureAdmin(address caller_) private view {
        require(caller_ == admin, "Unauthorized");
    }

    function ensureNoMathError(MathError mErr) private pure {
        require(mErr == MathError.NO_ERROR, "math error");
    }

    function ensureNonZeroAddress(address address_) private pure {
        require(address_ != address(0), "zero address");
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying owned by this contract
     */
    function getCashPrior() internal view returns (uint);
}

pragma solidity ^0.5.16;

import "../../Comptroller/ComptrollerInterface.sol";
import "../../InterestRateModels/InterestRateModel.sol";

interface IProtocolShareReserveV5 {
    enum IncomeType {
        SPREAD,
        LIQUIDATION
    }

    function updateAssetsState(address comptroller, address asset, IncomeType kind) external;
}

contract VTokenStorageBase {
    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @notice Maximum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-vToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @notice Initial exchange rate used when minting the first VTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @notice Official record of token balances for each account
     */
    mapping(address => uint) internal accountTokens;

    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping(address => mapping(address => uint)) internal transferAllowances;

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Underlying asset for this VToken
     */
    address public underlying;

    /**
     * @notice Implementation address for this contract
     */
    address public implementation;

    /**
     * @notice delta block after which reserves will be reduced
     */
    uint public reduceReservesBlockDelta;

    /**
     * @notice last block number at which reserves were reduced
     */
    uint public reduceReservesBlockNumber;

    /**
     * @notice address of protocol share reserve contract
     */
    address payable public protocolShareReserve;

    /**
     * @notice address of accessControlManager
     */

    address public accessControlManager;
}

contract VTokenStorage is VTokenStorageBase {
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

contract VTokenInterface is VTokenStorage {
    /**
     * @notice Indicator that this is a vToken contract (for inspection)
     */
    bool public constant isVToken = true;

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens, uint256 totalSupply);

    /**
     * @notice Event emitted when tokens are minted behalf by payer to receiver
     */
    event MintBehalf(address payer, address receiver, uint mintAmount, uint mintTokens, uint256 totalSupply);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens, uint256 totalSupply);

    /**
     * @notice Event emitted when tokens are redeemed and fee is transferred
     */
    event RedeemFee(address redeemer, uint feeAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint repayAmount,
        address vTokenCollateral,
        uint seizeTokens
    );

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin has been updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address protocolShareReserve, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Event emitted when block delta for reduce reserves get updated
     */
    event NewReduceReservesBlockDelta(uint256 oldReduceReservesBlockDelta, uint256 newReduceReservesBlockDelta);

    /**
     * @notice Event emitted when address of ProtocolShareReserve contract get updated
     */
    event NewProtocolShareReserve(address indexed oldProtocolShareReserve, address indexed newProtocolShareReserve);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);

    /// @notice Emitted when access control address is changed by admin
    event NewAccessControlManager(address oldAccessControlAddress, address newAccessControlAddress);

    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);

    function transferFrom(address src, address dst, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function balanceOfUnderlying(address owner) external returns (uint);

    function totalBorrowsCurrent() external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    /*** Admin Function ***/
    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);

    /*** Admin Function ***/
    function _acceptAdmin() external returns (uint);

    /*** Admin Function ***/
    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);

    /*** Admin Function ***/
    function _reduceReserves(uint reduceAmount) external returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    function borrowRatePerBlock() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function getCash() external view returns (uint);

    function exchangeRateCurrent() public returns (uint);

    function accrueInterest() public returns (uint);

    /*** Admin Function ***/
    function _setComptroller(ComptrollerInterface newComptroller) public returns (uint);

    /*** Admin Function ***/
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint);

    function borrowBalanceStored(address account) public view returns (uint);

    function exchangeRateStored() public view returns (uint);
}

contract VBep20Interface {
    /*** User Interface ***/

    function mint(uint mintAmount) external returns (uint);

    function mintBehalf(address receiver, uint mintAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow(uint repayAmount) external returns (uint);

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function liquidateBorrow(
        address borrower,
        uint repayAmount,
        VTokenInterface vTokenCollateral
    ) external returns (uint);

    /*** Admin Functions ***/

    function _addReserves(uint addAmount) external returns (uint);
}

contract VDelegatorInterface {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) public;
}

contract VDelegateInterface {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public;
}

pragma solidity ^0.5.16;

interface IXVSVesting {
    /// @param _recipient Address of the Vesting. recipient entitled to claim the vested funds
    /// @param _amount Total number of tokens Vested
    function deposit(address _recipient, uint256 _amount) external;
}

pragma solidity ^0.5.16;

import "../../Utils/Tokenlock.sol";

contract XVS is Tokenlock {
    /// @notice BEP-20 token name for this token
    string public constant name = "Venus";

    /// @notice BEP-20 token symbol for this token
    string public constant symbol = "XVS";

    /// @notice BEP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public constant totalSupply = 30000000e18; // 30 million XVS

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping(address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard BEP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard BEP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new XVS token
     * @param account The initial account to grant all the tokens
     */
    constructor(address account) public {
        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external validLock returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "XVS::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external validLock returns (bool) {
        uint96 amount = safe96(rawAmount, "XVS::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint rawAmount) external validLock returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "XVS::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(
                spenderAllowance,
                amount,
                "XVS::transferFrom: transfer amount exceeds spender allowance"
            );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public validLock {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public validLock {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "XVS::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "XVS::delegateBySig: invalid nonce");
        require(now <= expiry, "XVS::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "XVS::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "XVS::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "XVS::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "XVS::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "XVS::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "XVS::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "XVS::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "XVS::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2 ** 32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2 ** 96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

pragma solidity ^0.5.16;

import "../../Utils/IBEP20.sol";
import "../../Utils/SafeBEP20.sol";
import "./XVSVestingStorage.sol";
import "./XVSVestingProxy.sol";

/**
 * @title Venus's XVSVesting Contract
 * @author Venus
 */
contract XVSVesting is XVSVestingStorage {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /// @notice total vesting period for 1 year in seconds
    uint256 public constant TOTAL_VESTING_TIME = 365 * 24 * 60 * 60;

    /// @notice decimal precision for XVS
    uint256 public constant xvsDecimalsMultiplier = 1e18;

    /// @notice Emitted when XVSVested is claimed by recipient
    event VestedTokensClaimed(address recipient, uint256 amountClaimed);

    /// @notice Emitted when vrtConversionAddress is set
    event VRTConversionSet(address vrtConversionAddress);

    /// @notice Emitted when XVS is deposited for vesting
    event XVSVested(address indexed recipient, uint256 startTime, uint256 amount, uint256 withdrawnAmount);

    /// @notice Emitted when XVS is withdrawn by recipient
    event XVSWithdrawn(address recipient, uint256 amount);

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "Address cannot be Zero");
        _;
    }

    constructor() public {}

    /**
     * @notice initialize XVSVestingStorage
     * @param _xvsAddress The XVSToken address
     */
    function initialize(address _xvsAddress) public {
        require(msg.sender == admin, "only admin may initialize the XVSVesting");
        require(initialized == false, "XVSVesting is already initialized");
        require(_xvsAddress != address(0), "_xvsAddress cannot be Zero");
        xvs = IBEP20(_xvsAddress);

        _notEntered = true;
        initialized = true;
    }

    modifier isInitialized() {
        require(initialized == true, "XVSVesting is not initialized");
        _;
    }

    /**
     * @notice sets VRTConverter Address
     * @dev Note: If VRTConverter is not set, then Vesting is not allowed
     * @param _vrtConversionAddress The VRTConverterProxy Address
     */
    function setVRTConverter(address _vrtConversionAddress) public {
        require(msg.sender == admin, "only admin may initialize the Vault");
        require(_vrtConversionAddress != address(0), "vrtConversionAddress cannot be Zero");
        vrtConversionAddress = _vrtConversionAddress;
        emit VRTConversionSet(_vrtConversionAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can");
        _;
    }

    modifier onlyVrtConverter() {
        require(msg.sender == vrtConversionAddress, "only VRTConversion Address can call the function");
        _;
    }

    modifier vestingExistCheck(address recipient) {
        require(vestings[recipient].length > 0, "recipient doesnot have any vestingRecord");
        _;
    }

    /**
     * @notice Deposit XVS for Vesting
     * @param recipient The vesting recipient
     * @param depositAmount XVS amount for deposit
     */
    function deposit(
        address recipient,
        uint depositAmount
    ) external isInitialized onlyVrtConverter nonZeroAddress(recipient) {
        require(depositAmount > 0, "Deposit amount must be non-zero");

        VestingRecord[] storage vestingsOfRecipient = vestings[recipient];

        VestingRecord memory vesting = VestingRecord({
            recipient: recipient,
            startTime: getCurrentTime(),
            amount: depositAmount,
            withdrawnAmount: 0
        });

        vestingsOfRecipient.push(vesting);

        emit XVSVested(recipient, vesting.startTime, vesting.amount, vesting.withdrawnAmount);
    }

    /**
     * @notice Withdraw Vested XVS of recipient
     */
    function withdraw() external isInitialized vestingExistCheck(msg.sender) {
        address recipient = msg.sender;
        VestingRecord[] storage vestingsOfRecipient = vestings[recipient];
        uint256 vestingCount = vestingsOfRecipient.length;
        uint256 totalWithdrawableAmount = 0;

        for (uint i = 0; i < vestingCount; ++i) {
            VestingRecord storage vesting = vestingsOfRecipient[i];
            (, uint256 toWithdraw) = calculateWithdrawableAmount(
                vesting.amount,
                vesting.startTime,
                vesting.withdrawnAmount
            );
            if (toWithdraw > 0) {
                totalWithdrawableAmount = totalWithdrawableAmount.add(toWithdraw);
                vesting.withdrawnAmount = vesting.withdrawnAmount.add(toWithdraw);
            }
        }

        if (totalWithdrawableAmount > 0) {
            uint256 xvsBalance = xvs.balanceOf(address(this));
            require(xvsBalance >= totalWithdrawableAmount, "Insufficient XVS for withdrawal");
            emit XVSWithdrawn(recipient, totalWithdrawableAmount);
            xvs.safeTransfer(recipient, totalWithdrawableAmount);
        }
    }

    /**
     * @notice get Withdrawable XVS Amount
     * @param recipient The vesting recipient
     * @dev returns A tuple with totalWithdrawableAmount , totalVestedAmount and totalWithdrawnAmount
     */
    function getWithdrawableAmount(
        address recipient
    )
        public
        view
        isInitialized
        nonZeroAddress(recipient)
        vestingExistCheck(recipient)
        returns (uint256 totalWithdrawableAmount, uint256 totalVestedAmount, uint256 totalWithdrawnAmount)
    {
        VestingRecord[] storage vestingsOfRecipient = vestings[recipient];
        uint256 vestingCount = vestingsOfRecipient.length;

        for (uint i = 0; i < vestingCount; i++) {
            VestingRecord storage vesting = vestingsOfRecipient[i];
            (uint256 vestedAmount, uint256 toWithdraw) = calculateWithdrawableAmount(
                vesting.amount,
                vesting.startTime,
                vesting.withdrawnAmount
            );
            totalVestedAmount = totalVestedAmount.add(vestedAmount);
            totalWithdrawableAmount = totalWithdrawableAmount.add(toWithdraw);
            totalWithdrawnAmount = totalWithdrawnAmount.add(vesting.withdrawnAmount);
        }

        return (totalWithdrawableAmount, totalVestedAmount, totalWithdrawnAmount);
    }

    /**
     * @notice get Withdrawable XVS Amount
     * @param amount Amount deposited for vesting
     * @param vestingStartTime time in epochSeconds at the time of vestingDeposit
     * @param withdrawnAmount XVSAmount withdrawn from VestedAmount
     * @dev returns A tuple with vestedAmount and withdrawableAmount
     */
    function calculateWithdrawableAmount(
        uint256 amount,
        uint256 vestingStartTime,
        uint256 withdrawnAmount
    ) internal view returns (uint256, uint256) {
        uint256 vestedAmount = calculateVestedAmount(amount, vestingStartTime, getCurrentTime());
        uint toWithdraw = vestedAmount.sub(withdrawnAmount);
        return (vestedAmount, toWithdraw);
    }

    /**
     * @notice calculate total vested amount
     * @param vestingAmount Amount deposited for vesting
     * @param vestingStartTime time in epochSeconds at the time of vestingDeposit
     * @param currentTime currentTime in epochSeconds
     * @return Total XVS amount vested
     */
    function calculateVestedAmount(
        uint256 vestingAmount,
        uint256 vestingStartTime,
        uint256 currentTime
    ) internal view returns (uint256) {
        if (currentTime < vestingStartTime) {
            return 0;
        } else if (currentTime > vestingStartTime.add(TOTAL_VESTING_TIME)) {
            return vestingAmount;
        } else {
            return (vestingAmount.mul(currentTime.sub(vestingStartTime))).div(TOTAL_VESTING_TIME);
        }
    }

    /**
     * @notice current block timestamp
     * @return blocktimestamp
     */
    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    /*** Admin Functions ***/
    function _become(XVSVestingProxy xvsVestingProxy) public {
        require(msg.sender == xvsVestingProxy.admin(), "only proxy admin can change brains");
        xvsVestingProxy._acceptImplementation();
    }
}

pragma solidity ^0.5.16;

import "./XVSVestingStorage.sol";

contract XVSVestingProxy is XVSVestingAdminStorage {
    /**
     * @notice Emitted when pendingImplementation is changed
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingImplementation is accepted, which means XVSVesting implementation is updated
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor(
        address implementation_,
        address _xvsAddress
    ) public nonZeroAddress(implementation_) nonZeroAddress(_xvsAddress) {
        // Creator of the contract is admin during initialization
        admin = msg.sender;

        // New implementations always get set via the settor (post-initialize)
        _setImplementation(implementation_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation_, abi.encodeWithSignature("initialize(address)", _xvsAddress));
    }

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "Address cannot be Zero");
        _;
    }

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function _setImplementation(address implementation_) public {
        require(msg.sender == admin, "XVSVestingProxy::_setImplementation: admin only");
        require(implementation_ != address(0), "XVSVestingProxy::_setImplementation: invalid implementation address");

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation);
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal nonZeroAddress(callee) returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(
        address newPendingImplementation
    ) public nonZeroAddress(newPendingImplementation) {
        require(msg.sender == admin, "Only admin can set Pending Implementation");

        address oldPendingImplementation = pendingImplementation;

        pendingImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);
    }

    /**
     * @notice Accepts new implementation of VRT Vault. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     */
    function _acceptImplementation() public {
        // Check caller is pendingImplementation
        require(
            msg.sender == pendingImplementation,
            "only address marked as pendingImplementation can accept Implementation"
        );

        // Save current values for inclusion in log
        address oldImplementation = implementation;
        address oldPendingImplementation = pendingImplementation;

        implementation = pendingImplementation;

        pendingImplementation = address(0);

        emit NewImplementation(oldImplementation, implementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(address newPendingAdmin) public nonZeroAddress(newPendingAdmin) {
        // Check caller = admin
        require(msg.sender == admin, "only admin can set pending admin");
        require(newPendingAdmin != pendingAdmin, "New pendingAdmin can not be same as the previous one");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function _acceptAdmin() public {
        // Check caller is pendingAdmin
        require(msg.sender == pendingAdmin, "only address marked as pendingAdmin can accept as Admin");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize)
            }
            default {
                return(free_mem_ptr, returndatasize)
            }
        }
    }
}

pragma solidity ^0.5.16;

import "../../Utils/SafeMath.sol";
import "../../Utils/IBEP20.sol";

contract XVSVestingAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active brains of XVSVesting
     */
    address public implementation;

    /**
     * @notice Pending brains of XVSVesting
     */
    address public pendingImplementation;
}

contract XVSVestingStorage is XVSVestingAdminStorage {
    struct VestingRecord {
        address recipient;
        uint256 startTime;
        uint256 amount;
        uint256 withdrawnAmount;
    }

    /// @notice Guard variable for re-entrancy checks
    bool public _notEntered;

    /// @notice indicator to check if the contract is initialized
    bool public initialized;

    /// @notice The XVS TOKEN!
    IBEP20 public xvs;

    /// @notice VRTConversion Contract Address
    address public vrtConversionAddress;

    /// @notice mapping of VestingRecord(s) for user(s)
    mapping(address => VestingRecord[]) public vestings;
}

pragma solidity ^0.5.5;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        // solium-disable-next-line security/no-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.16;

/**
 * @title Careful Math
 * @author Venus
 * @notice Derived from OpenZeppelin's SafeMath library
 *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
contract CarefulMath {
    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
     * @dev Multiplies two numbers, returns an error on overflow.
     */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
     * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
     */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
     * @dev Adds two numbers, returns an error on overflow.
     */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
     * @dev add a and b and then subtract c
     */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

pragma solidity ^0.5.16;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin Contracts v4.3.2 (utils/cryptography/ECDSA.sol)

// SPDX-Copyright-Text: OpenZeppelin, 2021
// SPDX-Copyright-Text: Venus, 2021

pragma solidity ^0.5.16;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
contract ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }
}

pragma solidity ^0.5.16;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY,
        INSUFFICIENT_BALANCE_FOR_VAI,
        MARKET_NOT_COLLATERAL
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK,
        SET_VAI_MINT_RATE_CHECK,
        SET_VAICONTROLLER_OWNER_CHECK,
        SET_MINTED_VAI_REJECTION,
        SET_TREASURY_OWNER_CHECK
    }

    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint error, uint info, uint detail);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        COMPTROLLER_REJECTION,
        COMPTROLLER_CALCULATION_ERROR,
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        MARKET_NOT_LISTED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED,
        TOKEN_PRICE_ERROR
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_COMPTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_COMPTROLLER_REJECTION,
        LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_COMPTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_COMPTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_COMPTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COMPTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_COMPTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE,
        TOKEN_GET_UNDERLYING_PRICE_ERROR,
        REPAY_VAI_COMPTROLLER_REJECTION,
        REPAY_VAI_FRESHNESS_CHECK,
        VAI_MINT_EXCHANGE_CALCULATION_FAILED,
        SFT_MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED
    }

    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint error, uint info, uint detail);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract VAIControllerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED, // The sender is not authorized to perform this action.
        REJECTION, // The action would violate the comptroller, vaicontroller policy.
        SNAPSHOT_ERROR, // The comptroller could not get the account borrows and exchange rate from the market.
        PRICE_ERROR, // The comptroller could not obtain a required price of an asset.
        MATH_ERROR, // A math calculation error occurred.
        INSUFFICIENT_BALANCE_FOR_VAI // Caller does not have sufficient balance to mint VAI.
    }

    enum FailureInfo {
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_COMPTROLLER_OWNER_CHECK,
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        VAI_MINT_REJECTION,
        VAI_BURN_REJECTION,
        VAI_LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        VAI_LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        VAI_LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        VAI_LIQUIDATE_COMPTROLLER_REJECTION,
        VAI_LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        VAI_LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        VAI_LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        VAI_LIQUIDATE_FRESHNESS_CHECK,
        VAI_LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        VAI_LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        VAI_LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        VAI_LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        VAI_LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        VAI_LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        VAI_LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_FEE_CALCULATION_FAILED,
        SET_TREASURY_OWNER_CHECK
    }

    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint error, uint info, uint detail);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

pragma solidity ^0.5.16;

import "./CarefulMath.sol";
import "./ExponentialNoError.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Venus
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath, ExponentialNoError {
    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({ mantissa: 0 }));
        }

        return (MathError.NO_ERROR, Exp({ mantissa: rational }));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({ mantissa: result }));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({ mantissa: result }));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        return (MathError.NO_ERROR, Exp({ mantissa: scaledMantissa }));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) internal pure returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) internal pure returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        return (MathError.NO_ERROR, Exp({ mantissa: descaledMantissa }));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) internal pure returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) internal pure returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({ mantissa: 0 }));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({ mantissa: product }));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) internal pure returns (MathError, Exp memory) {
        return mulExp(Exp({ mantissa: a }), Exp({ mantissa: b }));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) internal pure returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }
}

pragma solidity ^0.5.16;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint internal constant expScale = 1e18;
    uint internal constant doubleScale = 1e36;
    uint internal constant halfExpScale = expScale / 2;
    uint internal constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) internal pure returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) internal pure returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) internal pure returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) internal pure returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) internal pure returns (uint224) {
        require(n < 2 ** 224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2 ** 32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({ mantissa: add_(a.mantissa, b.mantissa) });
    }

    function add_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({ mantissa: add_(a.mantissa, b.mantissa) });
    }

    function add_(uint a, uint b) internal pure returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({ mantissa: sub_(a.mantissa, b.mantissa) });
    }

    function sub_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({ mantissa: sub_(a.mantissa, b.mantissa) });
    }

    function sub_(uint a, uint b) internal pure returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({ mantissa: mul_(a.mantissa, b.mantissa) / expScale });
    }

    function mul_(Exp memory a, uint b) internal pure returns (Exp memory) {
        return Exp({ mantissa: mul_(a.mantissa, b) });
    }

    function mul_(uint a, Exp memory b) internal pure returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({ mantissa: mul_(a.mantissa, b.mantissa) / doubleScale });
    }

    function mul_(Double memory a, uint b) internal pure returns (Double memory) {
        return Double({ mantissa: mul_(a.mantissa, b) });
    }

    function mul_(uint a, Double memory b) internal pure returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) internal pure returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({ mantissa: div_(mul_(a.mantissa, expScale), b.mantissa) });
    }

    function div_(Exp memory a, uint b) internal pure returns (Exp memory) {
        return Exp({ mantissa: div_(a.mantissa, b) });
    }

    function div_(uint a, Exp memory b) internal pure returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({ mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa) });
    }

    function div_(Double memory a, uint b) internal pure returns (Double memory) {
        return Double({ mantissa: div_(a.mantissa, b) });
    }

    function div_(uint a, Double memory b) internal pure returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) internal pure returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) internal pure returns (Double memory) {
        return Double({ mantissa: div_(mul_(a, doubleScale), b) });
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {BEP20Detailed}.
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

pragma solidity ^0.5.16;

import "./Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.16;

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Should be owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}

pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for BEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.16;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2 ** 128, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2 ** 64, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2 ** 32, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2 ** 16, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2 ** 8, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2 ** 127 && value < 2 ** 127, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2 ** 63 && value < 2 ** 63, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2 ** 31 && value < 2 ** 31, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2 ** 15 && value < 2 ** 15, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2 ** 7 && value < 2 ** 7, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2 ** 255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

pragma solidity ^0.5.16;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(a, b, "SafeMath: addition overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.16;

import "./Owned.sol";

contract Tokenlock is Owned {
    /// @notice Indicates if token is locked
    uint8 internal isLocked = 0;

    event Freezed();
    event UnFreezed();

    modifier validLock() {
        require(isLocked == 0, "Token is locked");
        _;
    }

    function freeze() public onlyOwner {
        isLocked = 1;

        emit Freezed();
    }

    function unfreeze() public onlyOwner {
        isLocked = 0;

        emit UnFreezed();
    }
}

pragma solidity 0.5.16;

import "../Utils/SafeBEP20.sol";
import "../Utils/IBEP20.sol";
import "./VAIVaultStorage.sol";
import "./VAIVaultErrorReporter.sol";
import "@venusprotocol/governance-contracts/contracts/Governance/AccessControlledV5.sol";
import { VAIVaultProxy } from "./VAIVaultProxy.sol";

/**
 * @title VAI Vault
 * @author Venus
 * @notice The VAI Vault is configured for users to stake VAI And receive XVS as a reward.
 */
contract VAIVault is VAIVaultStorage, AccessControlledV5 {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /// @notice Event emitted when VAI deposit
    event Deposit(address indexed user, uint256 amount);

    /// @notice Event emitted when VAI withrawal
    event Withdraw(address indexed user, uint256 amount);

    /// @notice Event emitted when vault is paused
    event VaultPaused(address indexed admin);

    /// @notice Event emitted when vault is resumed after pause
    event VaultResumed(address indexed admin);

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can");
        _;
    }

    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    /**
     * @dev Prevents functions to execute when vault is paused.
     */
    modifier isActive() {
        require(!vaultPaused, "Vault is paused");
        _;
    }

    /**
     * @notice Pause vault
     */
    function pause() external {
        _checkAccessAllowed("pause()");
        require(!vaultPaused, "Vault is already paused");
        vaultPaused = true;
        emit VaultPaused(msg.sender);
    }

    /**
     * @notice Resume vault
     */
    function resume() external {
        _checkAccessAllowed("resume()");
        require(vaultPaused, "Vault is not paused");
        vaultPaused = false;
        emit VaultResumed(msg.sender);
    }

    /**
     * @notice Deposit VAI to VAIVault for XVS allocation
     * @param _amount The amount to deposit to vault
     */
    function deposit(uint256 _amount) external nonReentrant isActive {
        UserInfo storage user = userInfo[msg.sender];

        updateVault();

        // Transfer pending tokens to user
        updateAndPayOutPending(msg.sender);

        // Transfer in the amounts from user
        if (_amount > 0) {
            vai.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }

        user.rewardDebt = user.amount.mul(accXVSPerShare).div(1e18);
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Withdraw VAI from VAIVault
     * @param _amount The amount to withdraw from vault
     */
    function withdraw(uint256 _amount) external nonReentrant isActive {
        _withdraw(msg.sender, _amount);
    }

    /**
     * @notice Claim XVS from VAIVault
     */
    function claim() external nonReentrant isActive {
        _withdraw(msg.sender, 0);
    }

    /**
     * @notice Claim XVS from VAIVault
     * @param account The account for which to claim XVS
     */
    function claim(address account) external nonReentrant isActive {
        _withdraw(account, 0);
    }

    /**
     * @notice Low level withdraw function
     * @param account The account to withdraw from vault
     * @param _amount The amount to withdraw from vault
     */
    function _withdraw(address account, uint256 _amount) internal {
        UserInfo storage user = userInfo[account];
        require(user.amount >= _amount, "withdraw: not good");

        updateVault();
        updateAndPayOutPending(account); // Update balances of account this is not withdrawal but claiming XVS farmed

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            vai.safeTransfer(address(account), _amount);
        }
        user.rewardDebt = user.amount.mul(accXVSPerShare).div(1e18);

        emit Withdraw(account, _amount);
    }

    /**
     * @notice View function to see pending XVS on frontend
     * @param _user The user to see pending XVS
     * @return Amount of XVS the user can claim
     */
    function pendingXVS(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];

        return user.amount.mul(accXVSPerShare).div(1e18).sub(user.rewardDebt);
    }

    /**
     * @notice Update and pay out pending XVS to user
     * @param account The user to pay out
     */
    function updateAndPayOutPending(address account) internal {
        uint256 pending = pendingXVS(account);

        if (pending > 0) {
            safeXVSTransfer(account, pending);
        }
    }

    /**
     * @notice Safe XVS transfer function, just in case if rounding error causes pool to not have enough XVS
     * @param _to The address that XVS to be transfered
     * @param _amount The amount that XVS to be transfered
     */
    function safeXVSTransfer(address _to, uint256 _amount) internal {
        uint256 xvsBal = xvs.balanceOf(address(this));

        if (_amount > xvsBal) {
            xvs.transfer(_to, xvsBal);
            xvsBalance = xvs.balanceOf(address(this));
        } else {
            xvs.transfer(_to, _amount);
            xvsBalance = xvs.balanceOf(address(this));
        }
    }

    /**
     * @notice Function that updates pending rewards
     */
    function updatePendingRewards() public isActive {
        uint256 newRewards = xvs.balanceOf(address(this)).sub(xvsBalance);

        if (newRewards > 0) {
            xvsBalance = xvs.balanceOf(address(this)); // If there is no change the balance didn't change
            pendingRewards = pendingRewards.add(newRewards);
        }
    }

    /**
     * @notice Update reward variables to be up-to-date
     */
    function updateVault() internal {
        updatePendingRewards();

        uint256 vaiBalance = vai.balanceOf(address(this));
        if (vaiBalance == 0) {
            // avoids division by 0 errors
            return;
        }

        accXVSPerShare = accXVSPerShare.add(pendingRewards.mul(1e18).div(vaiBalance));
        pendingRewards = 0;
    }

    /*** Admin Functions ***/

    function _become(VAIVaultProxy vaiVaultProxy) external {
        require(msg.sender == vaiVaultProxy.admin(), "only proxy admin can change brains");
        require(vaiVaultProxy._acceptImplementation() == 0, "change not authorized");
    }

    function setVenusInfo(address _xvs, address _vai) external onlyAdmin {
        require(_xvs != address(0) && _vai != address(0), "addresses must not be zero");
        require(address(xvs) == address(0) && address(vai) == address(0), "addresses already set");
        xvs = IBEP20(_xvs);
        vai = IBEP20(_vai);

        _notEntered = true;
    }

    /**
     * @notice Sets the address of the access control of this contract
     * @dev Admin function to set the access control address
     * @param newAccessControlAddress New address for the access control
     */
    function setAccessControl(address newAccessControlAddress) external onlyAdmin {
        _setAccessControlManager(newAccessControlAddress);
    }
}

pragma solidity ^0.5.16;

contract VAIVaultErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK
    }

    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint error, uint info, uint detail);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

pragma solidity ^0.5.16;

import "./VAIVaultStorage.sol";
import "./VAIVaultErrorReporter.sol";

/**
 * @title VAI Vault Proxy
 * @author Venus
 * @notice Proxy contract for the VAI Vault
 */
contract VAIVaultProxy is VAIVaultAdminStorage, VAIVaultErrorReporter {
    /**
     * @notice Emitted when pendingVAIVaultImplementation is changed
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingVAIVaultImplementation is accepted, which means VAI Vault implementation is updated
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() public {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
        }

        address oldPendingImplementation = pendingVAIVaultImplementation;

        pendingVAIVaultImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingVAIVaultImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accepts new implementation of VAI Vault. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptImplementation() public returns (uint) {
        // Check caller is pendingImplementation
        if (msg.sender != pendingVAIVaultImplementation) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
        }

        // Save current values for inclusion in log
        address oldImplementation = vaiVaultImplementation;
        address oldPendingImplementation = pendingVAIVaultImplementation;

        vaiVaultImplementation = pendingVAIVaultImplementation;

        pendingVAIVaultImplementation = address(0);

        emit NewImplementation(oldImplementation, vaiVaultImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingVAIVaultImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptAdmin() public returns (uint) {
        // Check caller is pendingAdmin
        if (msg.sender != pendingAdmin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = vaiVaultImplementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize)
            }
            default {
                return(free_mem_ptr, returndatasize)
            }
        }
    }
}

pragma solidity ^0.5.16;
import "../Utils/SafeMath.sol";
import "../Utils/IBEP20.sol";

contract VAIVaultAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active brains of VAI Vault
     */
    address public vaiVaultImplementation;

    /**
     * @notice Pending brains of VAI Vault
     */
    address public pendingVAIVaultImplementation;
}

contract VAIVaultStorage is VAIVaultAdminStorage {
    /// @notice The XVS TOKEN!
    IBEP20 public xvs;

    /// @notice The VAI TOKEN!
    IBEP20 public vai;

    /// @notice Guard variable for re-entrancy checks
    bool internal _notEntered;

    /// @notice XVS balance of vault
    uint256 public xvsBalance;

    /// @notice Accumulated XVS per share
    uint256 public accXVSPerShare;

    //// pending rewards awaiting anyone to update
    uint256 public pendingRewards;

    /// @notice Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    // Info of each user that stakes tokens.
    mapping(address => UserInfo) public userInfo;

    /// @notice pause indicator for Vault
    bool public vaultPaused;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

pragma solidity 0.5.16;

import "../Utils/SafeBEP20.sol";
import "../Utils/IBEP20.sol";
import "./VRTVaultStorage.sol";
import "@venusprotocol/governance-contracts/contracts/Governance/AccessControlledV5.sol";

interface IVRTVaultProxy {
    function _acceptImplementation() external;

    function admin() external returns (address);
}

contract VRTVault is VRTVaultStorage, AccessControlledV5 {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /// @notice The upper bound for lastAccruingBlock. Close to year 3,000, considering 3 seconds per block. Used to avoid a value absurdly high
    uint256 public constant MAX_LAST_ACCRUING_BLOCK = 9999999999;

    /// @notice Event emitted when vault is paused
    event VaultPaused(address indexed admin);

    /// @notice Event emitted when vault is resumed after pause
    event VaultResumed(address indexed admin);

    /// @notice Event emitted on VRT deposit
    event Deposit(address indexed user, uint256 amount);

    /// @notice Event emitted when accruedInterest and VRT PrincipalAmount is withrawn
    event Withdraw(
        address indexed user,
        uint256 withdrawnAmount,
        uint256 totalPrincipalAmount,
        uint256 accruedInterest
    );

    /// @notice Event emitted when Admin withdraw BEP20 token from contract
    event WithdrawToken(address indexed tokenAddress, address indexed receiver, uint256 amount);

    /// @notice Event emitted when accruedInterest is claimed
    event Claim(address indexed user, uint256 interestAmount);

    /// @notice Event emitted when lastAccruingBlock state variable changes
    event LastAccruingBlockChanged(uint256 oldLastAccruingBlock, uint256 newLastAccruingBlock);

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin allowed");
        _;
    }

    function initialize(address _vrtAddress, uint256 _interestRatePerBlock) public {
        require(msg.sender == admin, "only admin may initialize the Vault");
        require(_vrtAddress != address(0), "vrtAddress cannot be Zero");
        require(interestRatePerBlock == 0, "Vault may only be initialized once");

        // Set initial exchange rate
        interestRatePerBlock = _interestRatePerBlock;
        require(interestRatePerBlock > 0, "interestRate Per Block must be greater than zero.");

        // Set the VRT
        vrt = IBEP20(_vrtAddress);
        _notEntered = true;
    }

    modifier isInitialized() {
        require(interestRatePerBlock > 0, "Vault is not initialized");
        _;
    }

    modifier isActive() {
        require(!vaultPaused, "Vault is paused");
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "Address cannot be Zero");
        _;
    }

    modifier userHasPosition(address userAddress) {
        UserInfo storage user = userInfo[userAddress];
        require(user.userAddress != address(0), "User does not have any position in the Vault.");
        _;
    }

    /**
     * @notice Pause vault
     */
    function pause() external {
        _checkAccessAllowed("pause()");
        require(!vaultPaused, "Vault is already paused");
        vaultPaused = true;
        emit VaultPaused(msg.sender);
    }

    /**
     * @notice Resume vault
     */
    function resume() external {
        _checkAccessAllowed("resume()");
        require(vaultPaused, "Vault is not paused");
        vaultPaused = false;
        emit VaultResumed(msg.sender);
    }

    /**
     * @notice Deposit VRT to VRTVault for a fixed-interest-rate
     * @param depositAmount The amount to deposit to vault
     */
    function deposit(uint256 depositAmount) external nonReentrant isInitialized isActive {
        require(depositAmount > 0, "Deposit amount must be non-zero");

        address userAddress = msg.sender;
        UserInfo storage user = userInfo[userAddress];

        if (user.userAddress == address(0)) {
            user.userAddress = userAddress;
            user.totalPrincipalAmount = depositAmount;
        } else {
            // accrue Interest and transfer to the user
            uint256 accruedInterest = computeAccruedInterest(user.totalPrincipalAmount, user.accrualStartBlockNumber);

            user.totalPrincipalAmount = user.totalPrincipalAmount.add(depositAmount);

            if (accruedInterest > 0) {
                uint256 vrtBalance = vrt.balanceOf(address(this));
                require(
                    vrtBalance >= accruedInterest,
                    "Failed to transfer accruedInterest, Insufficient VRT in Vault."
                );
                emit Claim(userAddress, accruedInterest);
                vrt.safeTransfer(user.userAddress, accruedInterest);
            }
        }

        uint256 currentBlock_ = getBlockNumber();
        if (lastAccruingBlock > currentBlock_) {
            user.accrualStartBlockNumber = currentBlock_;
        } else {
            user.accrualStartBlockNumber = lastAccruingBlock;
        }
        emit Deposit(userAddress, depositAmount);
        vrt.safeTransferFrom(userAddress, address(this), depositAmount);
    }

    /**
     * @notice get accruedInterest of the user's VRTDeposits in the Vault
     * @param userAddress Address of User in the the Vault
     * @return The interest accrued, in VRT
     */
    function getAccruedInterest(
        address userAddress
    ) public view nonZeroAddress(userAddress) isInitialized returns (uint256) {
        UserInfo storage user = userInfo[userAddress];
        if (user.accrualStartBlockNumber == 0) {
            return 0;
        }

        return computeAccruedInterest(user.totalPrincipalAmount, user.accrualStartBlockNumber);
    }

    /**
     * @notice get accruedInterest of the user's VRTDeposits in the Vault
     * @param totalPrincipalAmount of the User
     * @param accrualStartBlockNumber of the User
     * @return The interest accrued, in VRT
     */
    function computeAccruedInterest(
        uint256 totalPrincipalAmount,
        uint256 accrualStartBlockNumber
    ) internal view isInitialized returns (uint256) {
        uint256 blockNumber = getBlockNumber();
        uint256 _lastAccruingBlock = lastAccruingBlock;

        if (blockNumber > _lastAccruingBlock) {
            blockNumber = _lastAccruingBlock;
        }

        if (accrualStartBlockNumber == 0 || accrualStartBlockNumber >= blockNumber) {
            return 0;
        }

        // Number of blocks since deposit
        uint256 blockDelta = blockNumber.sub(accrualStartBlockNumber);
        uint256 accruedInterest = (totalPrincipalAmount.mul(interestRatePerBlock).mul(blockDelta)).div(1e18);
        return accruedInterest;
    }

    /**
     * @notice claim the accruedInterest of the user's VRTDeposits in the Vault
     */
    function claim() external nonReentrant isInitialized userHasPosition(msg.sender) isActive {
        _claim(msg.sender);
    }

    /**
     * @notice claim the accruedInterest of the user's VRTDeposits in the Vault
     * @param account The account for which to claim rewards
     */
    function claim(address account) external nonReentrant isInitialized userHasPosition(account) isActive {
        _claim(account);
    }

    /**
     * @notice Low level claim function
     * @param account The account for which to claim rewards
     */
    function _claim(address account) internal {
        uint256 accruedInterest = getAccruedInterest(account);
        if (accruedInterest > 0) {
            UserInfo storage user = userInfo[account];
            uint256 vrtBalance = vrt.balanceOf(address(this));
            require(vrtBalance >= accruedInterest, "Failed to transfer VRT, Insufficient VRT in Vault.");
            emit Claim(account, accruedInterest);
            uint256 currentBlock_ = getBlockNumber();
            if (lastAccruingBlock > currentBlock_) {
                user.accrualStartBlockNumber = currentBlock_;
            } else {
                user.accrualStartBlockNumber = lastAccruingBlock;
            }
            vrt.safeTransfer(user.userAddress, accruedInterest);
        }
    }

    /**
     * @notice withdraw accruedInterest and totalPrincipalAmount of the user's VRTDeposit in the Vault
     */
    function withdraw() external nonReentrant isInitialized userHasPosition(msg.sender) isActive {
        address userAddress = msg.sender;
        uint256 accruedInterest = getAccruedInterest(userAddress);

        UserInfo storage user = userInfo[userAddress];

        uint256 totalPrincipalAmount = user.totalPrincipalAmount;
        uint256 vrtForWithdrawal = accruedInterest.add(totalPrincipalAmount);
        user.totalPrincipalAmount = 0;
        user.accrualStartBlockNumber = getBlockNumber();

        uint256 vrtBalance = vrt.balanceOf(address(this));
        require(vrtBalance >= vrtForWithdrawal, "Failed to transfer VRT, Insufficient VRT in Vault.");

        emit Withdraw(userAddress, vrtForWithdrawal, totalPrincipalAmount, accruedInterest);
        vrt.safeTransfer(user.userAddress, vrtForWithdrawal);
    }

    /**
     * @notice withdraw BEP20 tokens from the contract to a recipient address.
     * @param tokenAddress address of the BEP20 token
     * @param receiver recipient of the BEP20 token
     * @param amount tokenAmount
     */
    function withdrawBep20(
        address tokenAddress,
        address receiver,
        uint256 amount
    ) external isInitialized nonZeroAddress(tokenAddress) nonZeroAddress(receiver) {
        _checkAccessAllowed("withdrawBep20(address,address,uint256)");
        require(amount > 0, "amount is invalid");
        IBEP20 token = IBEP20(tokenAddress);
        require(amount <= token.balanceOf(address(this)), "Insufficient amount in Vault");
        emit WithdrawToken(tokenAddress, receiver, amount);
        token.safeTransfer(receiver, amount);
    }

    function setLastAccruingBlock(uint256 _lastAccruingBlock) external {
        _checkAccessAllowed("setLastAccruingBlock(uint256)");
        require(_lastAccruingBlock < MAX_LAST_ACCRUING_BLOCK, "_lastAccruingBlock is absurdly high");

        uint256 oldLastAccruingBlock = lastAccruingBlock;
        uint256 currentBlock = getBlockNumber();
        if (oldLastAccruingBlock != 0) {
            require(currentBlock < oldLastAccruingBlock, "Cannot change at this point");
        }
        if (oldLastAccruingBlock == 0 || _lastAccruingBlock < oldLastAccruingBlock) {
            // Must be in future
            require(currentBlock < _lastAccruingBlock, "Invalid _lastAccruingBlock interest have been accumulated");
        }
        lastAccruingBlock = _lastAccruingBlock;
        emit LastAccruingBlockChanged(oldLastAccruingBlock, _lastAccruingBlock);
    }

    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    /*** Admin Functions ***/

    function _become(IVRTVaultProxy vrtVaultProxy) external {
        require(msg.sender == vrtVaultProxy.admin(), "only proxy admin can change brains");
        vrtVaultProxy._acceptImplementation();
    }

    /**
     * @notice Sets the address of the access control of this contract
     * @dev Admin function to set the access control address
     * @param newAccessControlAddress New address for the access control
     */
    function setAccessControl(address newAccessControlAddress) external onlyAdmin {
        _setAccessControlManager(newAccessControlAddress);
    }
}

pragma solidity ^0.5.16;

import "./VRTVaultStorage.sol";

contract VRTVaultProxy is VRTVaultAdminStorage {
    /**
     * @notice Emitted when pendingImplementation is changed
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingImplementation is accepted, which means VRT Vault implementation is updated
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor(address implementation_, address vrtAddress_, uint256 interestRatePerBlock_) public {
        // Creator of the contract is admin during initialization
        admin = msg.sender;

        // New implementations always get set via the settor (post-initialize)
        _setImplementation(implementation_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(
            implementation_,
            abi.encodeWithSignature("initialize(address,uint256)", vrtAddress_, interestRatePerBlock_)
        );
    }

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function _setImplementation(address implementation_) public {
        require(msg.sender == admin, "VRTVaultProxy::_setImplementation: admin only");
        require(implementation_ != address(0), "VRTVaultProxy::_setImplementation: invalid implementation address");

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation);
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public {
        require(msg.sender == admin, "Only admin can set Pending Implementation");

        address oldPendingImplementation = pendingImplementation;

        pendingImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);
    }

    /**
     * @notice Accepts new implementation of VRT Vault. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     */
    function _acceptImplementation() public {
        // Check caller is pendingImplementation
        require(
            msg.sender == pendingImplementation,
            "only address marked as pendingImplementation can accept Implementation"
        );

        // Save current values for inclusion in log
        address oldImplementation = implementation;
        address oldPendingImplementation = pendingImplementation;

        implementation = pendingImplementation;

        pendingImplementation = address(0);

        emit NewImplementation(oldImplementation, implementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(address newPendingAdmin) public {
        // Check caller = admin
        require(msg.sender == admin, "only admin can set pending admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @dev return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptAdmin() public {
        // Check caller is pendingAdmin
        require(msg.sender == pendingAdmin, "only address marked as pendingAdmin can accept as Admin");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize)
            }
            default {
                return(free_mem_ptr, returndatasize)
            }
        }
    }
}

pragma solidity ^0.5.16;
import "../Utils/SafeMath.sol";
import "../Utils/IBEP20.sol";

contract VRTVaultAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active brains of VRT Vault
     */
    address public implementation;

    /**
     * @notice Pending brains of VAI Vault
     */
    address public pendingImplementation;
}

contract VRTVaultStorage is VRTVaultAdminStorage {
    /// @notice Guard variable for re-entrancy checks
    bool public _notEntered;

    /// @notice pause indicator for Vault
    bool public vaultPaused;

    /// @notice The VRT TOKEN!
    IBEP20 public vrt;

    /// @notice interestRate for accrual - per Block
    uint256 public interestRatePerBlock;

    /// @notice Info of each user.
    struct UserInfo {
        address userAddress;
        uint256 accrualStartBlockNumber;
        uint256 totalPrincipalAmount;
        uint256 lastWithdrawnBlockNumber;
    }

    // Info of each user that stakes tokens.
    mapping(address => UserInfo) public userInfo;

    /// @notice block number after which no interest will be accrued
    uint256 public lastAccruingBlock;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

pragma solidity 0.5.16;
import "../Utils/SafeBEP20.sol";
import "../Utils/IBEP20.sol";

/**
 * @title XVS Store
 * @author Venus
 * @notice XVS Store responsible for distributing XVS rewards
 */
contract XVSStore {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /// @notice The Admin Address
    address public admin;

    /// @notice The pending admin address
    address public pendingAdmin;

    /// @notice The Owner Address
    address public owner;

    /// @notice The reward tokens
    mapping(address => bool) public rewardTokens;

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Event emitted when admin changed
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

    /// @notice Event emitted when owner changed
    event OwnerTransferred(address indexed oldOwner, address indexed newOwner);

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can");
        _;
    }

    /**
     * @notice Safely transfer rewards. Only active reward tokens can be sent using this function.
     * Only callable by owner
     * @dev Safe reward token transfer function, just in case if rounding error causes pool to not have enough tokens.
     * @param token Reward token to transfer
     * @param _to Destination address of the reward
     * @param _amount Amount to transfer
     */
    function safeRewardTransfer(address token, address _to, uint256 _amount) external onlyOwner {
        require(rewardTokens[token] == true, "only reward token can");

        if (address(token) != address(0)) {
            uint256 tokenBalance = IBEP20(token).balanceOf(address(this));
            if (_amount > tokenBalance) {
                IBEP20(token).safeTransfer(_to, tokenBalance);
            } else {
                IBEP20(token).safeTransfer(_to, _amount);
            }
        }
    }

    /**
     * @notice Allows the admin to propose a new admin
     * Only callable admin
     * @param _admin Propose an account as admin of the XVS store
     */
    function setPendingAdmin(address _admin) external onlyAdmin {
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = _admin;
        emit NewPendingAdmin(oldPendingAdmin, _admin);
    }

    /**
     * @notice Allows an account that is pending as admin to accept the role
     * nly calllable by the pending admin
     */
    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "only pending admin");
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        admin = pendingAdmin;
        pendingAdmin = address(0);

        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
        emit AdminTransferred(oldAdmin, admin);
    }

    /**
     * @notice Set the contract owner
     * @param _owner The address of the owner to set
     * Only callable admin
     */
    function setNewOwner(address _owner) external onlyAdmin {
        require(_owner != address(0), "new owner is the zero address");
        address oldOwner = owner;
        owner = _owner;
        emit OwnerTransferred(oldOwner, _owner);
    }

    /**
     * @notice Set or disable a reward token
     * @param _tokenAddress The address of a token to set as active or inactive
     * @param status Set whether a reward token is active or not
     */
    function setRewardToken(address _tokenAddress, bool status) external {
        require(msg.sender == admin || msg.sender == owner, "only admin or owner can");
        rewardTokens[_tokenAddress] = status;
    }

    /**
     * @notice Security function to allow the owner of the contract to withdraw from the contract
     * @param _tokenAddress Reward token address to withdraw
     * @param _amount Amount of token to withdraw
     */
    function emergencyRewardWithdraw(address _tokenAddress, uint256 _amount) external onlyOwner {
        IBEP20(_tokenAddress).safeTransfer(address(msg.sender), _amount);
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "../Utils/ECDSA.sol";
import "../Utils/SafeBEP20.sol";
import "../Utils/IBEP20.sol";
import "./XVSVaultStorage.sol";
import "../Tokens/Prime/IPrime.sol";
import "../Utils/SafeCast.sol";
import "@venusprotocol/governance-contracts/contracts/Governance/AccessControlledV5.sol";
import "@venusprotocol/solidity-utilities/contracts/TimeManagerV5.sol";

import { XVSStore } from "./XVSStore.sol";
import { XVSVaultProxy } from "./XVSVaultProxy.sol";

/**
 * @title XVS Vault
 * @author Venus
 * @notice The XVS Vault allows XVS holders to lock their XVS to recieve voting rights in Venus governance and are rewarded with XVS.
 */
contract XVSVault is XVSVaultStorage, ECDSA, AccessControlledV5, TimeManagerV5 {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using SafeBEP20 for IBEP20;

    /// @notice The upper bound for the lock period in a pool, 10 years
    uint256 public constant MAX_LOCK_PERIOD = 60 * 60 * 24 * 365 * 10;

    /// @notice Event emitted when deposit
    event Deposit(address indexed user, address indexed rewardToken, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when execute withrawal
    event ExecutedWithdrawal(address indexed user, address indexed rewardToken, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when request withrawal
    event RequestedWithdrawal(address indexed user, address indexed rewardToken, uint256 indexed pid, uint256 amount);

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChangedV2(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChangedV2(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice An event emitted when the reward store address is updated
    event StoreUpdated(address oldXvs, address oldStore, address newXvs, address newStore);

    /// @notice An event emitted when the withdrawal locking period is updated for a pool
    event WithdrawalLockingPeriodUpdated(address indexed rewardToken, uint indexed pid, uint oldPeriod, uint newPeriod);

    /// @notice An event emitted when the reward amount per block or second is modified for a pool
    event RewardAmountUpdated(address indexed rewardToken, uint oldReward, uint newReward);

    /// @notice An event emitted when a new pool is added
    event PoolAdded(
        address indexed rewardToken,
        uint indexed pid,
        address indexed token,
        uint allocPoints,
        uint rewardPerBlockOrSecond,
        uint lockPeriod
    );

    /// @notice An event emitted when a pool allocation points are updated
    event PoolUpdated(address indexed rewardToken, uint indexed pid, uint oldAllocPoints, uint newAllocPoints);

    /// @notice Event emitted when reward claimed
    event Claim(address indexed user, address indexed rewardToken, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when vault is paused
    event VaultPaused(address indexed admin);

    /// @notice Event emitted when vault is resumed after pause
    event VaultResumed(address indexed admin);

    /// @notice Event emitted when protocol logs a debt to a user due to insufficient funds for pending reward distribution
    event VaultDebtUpdated(
        address indexed rewardToken,
        address indexed userAddress,
        uint256 oldOwedAmount,
        uint256 newOwedAmount
    );

    /// @notice Emitted when prime token contract address is changed
    event NewPrimeToken(
        IPrime indexed oldPrimeToken,
        IPrime indexed newPrimeToken,
        address oldPrimeRewardToken,
        address newPrimeRewardToken,
        uint256 oldPrimePoolId,
        uint256 newPrimePoolId
    );

    /**
     * @notice XVSVault constructor
     */
    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can");
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    /**
     * @dev Prevents functions to execute when vault is paused.
     */
    modifier isActive() {
        require(!vaultPaused, "Vault is paused");
        _;
    }

    /**
     * @notice Pauses vault
     */
    function pause() external {
        _checkAccessAllowed("pause()");
        require(!vaultPaused, "Vault is already paused");
        vaultPaused = true;
        emit VaultPaused(msg.sender);
    }

    /**
     * @notice Resume vault
     */
    function resume() external {
        _checkAccessAllowed("resume()");
        require(vaultPaused, "Vault is not paused");
        vaultPaused = false;
        emit VaultResumed(msg.sender);
    }

    /**
     * @notice Returns the number of pools with the specified reward token
     * @param rewardToken Reward token address
     * @return Number of pools that distribute the specified token as a reward
     */
    function poolLength(address rewardToken) external view returns (uint256) {
        return poolInfos[rewardToken].length;
    }

    /**
     * @notice Returns the number of reward tokens created per block or second
     * @param _rewardToken Reward token address
     * @return Number of reward tokens created per block or second
     */
    function rewardTokenAmountsPerBlock(address _rewardToken) external view returns (uint256) {
        return rewardTokenAmountsPerBlockOrSecond[_rewardToken];
    }

    /**
     * @notice Add a new token pool
     * @dev This vault DOES NOT support deflationary tokens — it expects that
     *   the amount of transferred tokens would equal the actually deposited
     *   amount. In practice this means that this vault DOES NOT support USDT
     *   and similar tokens (that do not provide these guarantees).
     * @param _rewardToken Reward token address
     * @param _allocPoint Number of allocation points assigned to this pool
     * @param _token Staked token
     * @param _rewardPerBlockOrSecond Initial reward per block or second, in terms of _rewardToken
     * @param _lockPeriod A period between withdrawal request and a moment when it's executable
     */
    function add(
        address _rewardToken,
        uint256 _allocPoint,
        IBEP20 _token,
        uint256 _rewardPerBlockOrSecond,
        uint256 _lockPeriod
    ) external {
        _checkAccessAllowed("add(address,uint256,address,uint256,uint256)");
        _ensureNonzeroAddress(_rewardToken);
        _ensureNonzeroAddress(address(_token));
        require(address(xvsStore) != address(0), "Store contract address is empty");
        require(_allocPoint > 0, "Alloc points must not be zero");

        massUpdatePools(_rewardToken);

        PoolInfo[] storage poolInfo = poolInfos[_rewardToken];

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "Pool already added");
        }

        // We use balanceOf to get the supply amount, so shouldn't be possible to
        // configure pools with different reward token but the same staked token
        require(!isStakedToken[address(_token)], "Token exists in other pool");

        totalAllocPoints[_rewardToken] = totalAllocPoints[_rewardToken].add(_allocPoint);

        rewardTokenAmountsPerBlockOrSecond[_rewardToken] = _rewardPerBlockOrSecond;

        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardBlockOrSecond: getBlockNumberOrTimestamp(),
                accRewardPerShare: 0,
                lockPeriod: _lockPeriod
            })
        );
        isStakedToken[address(_token)] = true;

        XVSStore(xvsStore).setRewardToken(_rewardToken, true);

        emit PoolAdded(
            _rewardToken,
            poolInfo.length - 1,
            address(_token),
            _allocPoint,
            _rewardPerBlockOrSecond,
            _lockPeriod
        );
    }

    /**
     * @notice Update the given pool's reward allocation point
     * @param _rewardToken Reward token address
     * @param _pid Pool index
     * @param _allocPoint Number of allocation points assigned to this pool
     */
    function set(address _rewardToken, uint256 _pid, uint256 _allocPoint) external {
        _checkAccessAllowed("set(address,uint256,uint256)");
        _ensureValidPool(_rewardToken, _pid);

        massUpdatePools(_rewardToken);

        PoolInfo[] storage poolInfo = poolInfos[_rewardToken];
        uint256 newTotalAllocPoints = totalAllocPoints[_rewardToken].sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        require(newTotalAllocPoints > 0, "Alloc points per reward token must not be zero");

        uint256 oldAllocPoints = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        totalAllocPoints[_rewardToken] = newTotalAllocPoints;

        emit PoolUpdated(_rewardToken, _pid, oldAllocPoints, _allocPoint);
    }

    /**
     * @notice Update the given reward token's amount per block or second
     * @param _rewardToken Reward token address
     * @param _rewardAmount Number of allocation points assigned to this pool
     */
    function setRewardAmountPerBlockOrSecond(address _rewardToken, uint256 _rewardAmount) external {
        _checkAccessAllowed("setRewardAmountPerBlockOrSecond(address,uint256)");
        require(XVSStore(xvsStore).rewardTokens(_rewardToken), "Invalid reward token");
        massUpdatePools(_rewardToken);
        uint256 oldReward = rewardTokenAmountsPerBlockOrSecond[_rewardToken];
        rewardTokenAmountsPerBlockOrSecond[_rewardToken] = _rewardAmount;

        emit RewardAmountUpdated(_rewardToken, oldReward, _rewardAmount);
    }

    /**
     * @notice Update the lock period after which a requested withdrawal can be executed
     * @param _rewardToken Reward token address
     * @param _pid Pool index
     * @param _newPeriod New lock period
     */
    function setWithdrawalLockingPeriod(address _rewardToken, uint256 _pid, uint256 _newPeriod) external {
        _checkAccessAllowed("setWithdrawalLockingPeriod(address,uint256,uint256)");
        _ensureValidPool(_rewardToken, _pid);
        require(_newPeriod > 0 && _newPeriod < MAX_LOCK_PERIOD, "Invalid new locking period");
        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        uint256 oldPeriod = pool.lockPeriod;
        pool.lockPeriod = _newPeriod;

        emit WithdrawalLockingPeriodUpdated(_rewardToken, _pid, oldPeriod, _newPeriod);
    }

    /**
     * @notice Deposit XVSVault for XVS allocation
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     * @param _amount The amount to deposit to vault
     */
    function deposit(address _rewardToken, uint256 _pid, uint256 _amount) external nonReentrant isActive {
        _ensureValidPool(_rewardToken, _pid);
        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        UserInfo storage user = userInfos[_rewardToken][_pid][msg.sender];
        _updatePool(_rewardToken, _pid);
        require(pendingWithdrawalsBeforeUpgrade(_rewardToken, _pid, msg.sender) == 0, "execute pending withdrawal");

        if (user.amount > 0) {
            uint256 pending = _computeReward(user, pool);
            if (pending > 0) {
                _transferReward(_rewardToken, msg.sender, pending);
                emit Claim(msg.sender, _rewardToken, _pid, pending);
            }
        }
        pool.token.safeTransferFrom(msg.sender, address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = _cumulativeReward(user, pool);

        // Update Delegate Amount
        if (address(pool.token) == xvsAddress) {
            _moveDelegates(address(0), delegates[msg.sender], safe96(_amount, "XVSVault::deposit: votes overflow"));
        }

        if (primeRewardToken == _rewardToken && _pid == primePoolId) {
            primeToken.xvsUpdated(msg.sender);
        }

        emit Deposit(msg.sender, _rewardToken, _pid, _amount);
    }

    /**
     * @notice Claim rewards for pool
     * @param _account The account for which to claim rewards
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     */
    function claim(address _account, address _rewardToken, uint256 _pid) external nonReentrant isActive {
        _ensureValidPool(_rewardToken, _pid);
        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        UserInfo storage user = userInfos[_rewardToken][_pid][_account];
        _updatePool(_rewardToken, _pid);
        require(pendingWithdrawalsBeforeUpgrade(_rewardToken, _pid, _account) == 0, "execute pending withdrawal");

        if (user.amount > 0) {
            uint256 pending = _computeReward(user, pool);

            if (pending > 0) {
                user.rewardDebt = _cumulativeReward(user, pool);

                _transferReward(_rewardToken, _account, pending);
                emit Claim(_account, _rewardToken, _pid, pending);
            }
        }
    }

    /**
     * @notice Pushes withdrawal request to the requests array and updates
     *   the pending withdrawals amount. The requests are always sorted
     *   by unlock time (descending) so that the earliest to execute requests
     *   are always at the end of the array.
     * @param _user The user struct storage pointer
     * @param _requests The user's requests array storage pointer
     * @param _amount The amount being requested
     */
    function pushWithdrawalRequest(
        UserInfo storage _user,
        WithdrawalRequest[] storage _requests,
        uint _amount,
        uint _lockedUntil
    ) internal {
        uint i = _requests.length;
        _requests.push(WithdrawalRequest(0, 0, 1));
        // Keep it sorted so that the first to get unlocked request is always at the end
        for (; i > 0 && _requests[i - 1].lockedUntil <= _lockedUntil; --i) {
            _requests[i] = _requests[i - 1];
        }
        _requests[i] = WithdrawalRequest(_amount, _lockedUntil.toUint128(), 1);
        _user.pendingWithdrawals = _user.pendingWithdrawals.add(_amount);
    }

    /**
     * @notice Pops the requests with unlock time < now from the requests
     *   array and deducts the computed amount from the user's pending
     *   withdrawals counter. Assumes that the requests array is sorted
     *   by unclock time (descending).
     * @dev This function **removes** the eligible requests from the requests
     *   array. If this function is called, the withdrawal should actually
     *   happen (or the transaction should be reverted).
     * @param _user The user struct storage pointer
     * @param _requests The user's requests array storage pointer
     * @return beforeUpgradeWithdrawalAmount The amount eligible for withdrawal before upgrade (this amount should be
     *   sent to the user, otherwise the state would be inconsistent).
     * @return afterUpgradeWithdrawalAmount The amount eligible for withdrawal after upgrade (this amount should be
     *   sent to the user, otherwise the state would be inconsistent).
     */
    function popEligibleWithdrawalRequests(
        UserInfo storage _user,
        WithdrawalRequest[] storage _requests
    ) internal returns (uint beforeUpgradeWithdrawalAmount, uint afterUpgradeWithdrawalAmount) {
        // Since the requests are sorted by their unlock time, we can just
        // pop them from the array and stop at the first not-yet-eligible one
        for (uint i = _requests.length; i > 0 && isUnlocked(_requests[i - 1]); --i) {
            if (_requests[i - 1].afterUpgrade == 1) {
                afterUpgradeWithdrawalAmount = afterUpgradeWithdrawalAmount.add(_requests[i - 1].amount);
            } else {
                beforeUpgradeWithdrawalAmount = beforeUpgradeWithdrawalAmount.add(_requests[i - 1].amount);
            }

            _requests.pop();
        }
        _user.pendingWithdrawals = _user.pendingWithdrawals.sub(
            afterUpgradeWithdrawalAmount.add(beforeUpgradeWithdrawalAmount)
        );
        return (beforeUpgradeWithdrawalAmount, afterUpgradeWithdrawalAmount);
    }

    /**
     * @notice Checks if the request is eligible for withdrawal.
     * @param _request The request struct storage pointer
     * @return True if the request is eligible for withdrawal, false otherwise
     */
    function isUnlocked(WithdrawalRequest storage _request) private view returns (bool) {
        return _request.lockedUntil <= block.timestamp;
    }

    /**
     * @notice Execute withdrawal to XVSVault for XVS allocation
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     */
    function executeWithdrawal(address _rewardToken, uint256 _pid) external nonReentrant isActive {
        _ensureValidPool(_rewardToken, _pid);
        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        UserInfo storage user = userInfos[_rewardToken][_pid][msg.sender];
        WithdrawalRequest[] storage requests = withdrawalRequests[_rewardToken][_pid][msg.sender];

        uint256 beforeUpgradeWithdrawalAmount;
        uint256 afterUpgradeWithdrawalAmount;

        (beforeUpgradeWithdrawalAmount, afterUpgradeWithdrawalAmount) = popEligibleWithdrawalRequests(user, requests);
        require(beforeUpgradeWithdrawalAmount > 0 || afterUpgradeWithdrawalAmount > 0, "nothing to withdraw");

        // Having both old-style and new-style requests is not allowed and shouldn't be possible
        require(beforeUpgradeWithdrawalAmount == 0 || afterUpgradeWithdrawalAmount == 0, "inconsistent state");

        if (beforeUpgradeWithdrawalAmount > 0) {
            _updatePool(_rewardToken, _pid);
            uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            XVSStore(xvsStore).safeRewardTransfer(_rewardToken, msg.sender, pending);
            user.amount = user.amount.sub(beforeUpgradeWithdrawalAmount);
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
            pool.token.safeTransfer(address(msg.sender), beforeUpgradeWithdrawalAmount);
        } else {
            user.amount = user.amount.sub(afterUpgradeWithdrawalAmount);
            totalPendingWithdrawals[_rewardToken][_pid] = totalPendingWithdrawals[_rewardToken][_pid].sub(
                afterUpgradeWithdrawalAmount
            );
            pool.token.safeTransfer(address(msg.sender), afterUpgradeWithdrawalAmount);
        }

        emit ExecutedWithdrawal(
            msg.sender,
            _rewardToken,
            _pid,
            beforeUpgradeWithdrawalAmount.add(afterUpgradeWithdrawalAmount)
        );
    }

    /**
     * @notice Returns before and after upgrade pending withdrawal amount
     * @param _requests The user's requests array storage pointer
     * @return beforeUpgradeWithdrawalAmount The amount eligible for withdrawal before upgrade
     * @return afterUpgradeWithdrawalAmount The amount eligible for withdrawal after upgrade
     */
    function getRequestedWithdrawalAmount(
        WithdrawalRequest[] storage _requests
    ) internal view returns (uint beforeUpgradeWithdrawalAmount, uint afterUpgradeWithdrawalAmount) {
        for (uint i = _requests.length; i > 0; --i) {
            if (_requests[i - 1].afterUpgrade == 1) {
                afterUpgradeWithdrawalAmount = afterUpgradeWithdrawalAmount.add(_requests[i - 1].amount);
            } else {
                beforeUpgradeWithdrawalAmount = beforeUpgradeWithdrawalAmount.add(_requests[i - 1].amount);
            }
        }
        return (beforeUpgradeWithdrawalAmount, afterUpgradeWithdrawalAmount);
    }

    /**
     * @notice Request withdrawal to XVSVault for XVS allocation
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     * @param _amount The amount to withdraw from the vault
     */
    function requestWithdrawal(address _rewardToken, uint256 _pid, uint256 _amount) external nonReentrant isActive {
        _ensureValidPool(_rewardToken, _pid);
        require(_amount > 0, "requested amount cannot be zero");
        UserInfo storage user = userInfos[_rewardToken][_pid][msg.sender];
        require(user.amount >= user.pendingWithdrawals.add(_amount), "requested amount is invalid");

        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        WithdrawalRequest[] storage requests = withdrawalRequests[_rewardToken][_pid][msg.sender];

        uint beforeUpgradeWithdrawalAmount;

        (beforeUpgradeWithdrawalAmount, ) = getRequestedWithdrawalAmount(requests);
        require(beforeUpgradeWithdrawalAmount == 0, "execute pending withdrawal");

        _updatePool(_rewardToken, _pid);
        uint256 pending = _computeReward(user, pool);
        _transferReward(_rewardToken, msg.sender, pending);

        uint lockedUntil = pool.lockPeriod.add(block.timestamp);

        pushWithdrawalRequest(user, requests, _amount, lockedUntil);
        totalPendingWithdrawals[_rewardToken][_pid] = totalPendingWithdrawals[_rewardToken][_pid].add(_amount);
        user.rewardDebt = _cumulativeReward(user, pool);

        // Update Delegate Amount
        if (address(pool.token) == xvsAddress) {
            _moveDelegates(
                delegates[msg.sender],
                address(0),
                safe96(_amount, "XVSVault::requestWithdrawal: votes overflow")
            );
        }

        if (primeRewardToken == _rewardToken && _pid == primePoolId) {
            primeToken.xvsUpdated(msg.sender);
        }

        emit Claim(msg.sender, _rewardToken, _pid, pending);
        emit RequestedWithdrawal(msg.sender, _rewardToken, _pid, _amount);
    }

    /**
     * @notice Get unlocked withdrawal amount
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     * @param _user The User Address
     * @return withdrawalAmount Amount that the user can withdraw
     */
    function getEligibleWithdrawalAmount(
        address _rewardToken,
        uint256 _pid,
        address _user
    ) external view returns (uint withdrawalAmount) {
        _ensureValidPool(_rewardToken, _pid);
        WithdrawalRequest[] storage requests = withdrawalRequests[_rewardToken][_pid][_user];
        // Since the requests are sorted by their unlock time, we can take
        // the entries from the end of the array and stop at the first
        // not-yet-eligible one
        for (uint i = requests.length; i > 0 && isUnlocked(requests[i - 1]); --i) {
            withdrawalAmount = withdrawalAmount.add(requests[i - 1].amount);
        }
        return withdrawalAmount;
    }

    /**
     * @notice Get requested amount
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     * @param _user The User Address
     * @return Total amount of requested but not yet executed withdrawals (including both executable and locked ones)
     */
    function getRequestedAmount(address _rewardToken, uint256 _pid, address _user) external view returns (uint256) {
        _ensureValidPool(_rewardToken, _pid);
        UserInfo storage user = userInfos[_rewardToken][_pid][_user];
        return user.pendingWithdrawals;
    }

    /**
     * @notice Returns the array of withdrawal requests that have not been executed yet
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     * @param _user The User Address
     * @return An array of withdrawal requests
     */
    function getWithdrawalRequests(
        address _rewardToken,
        uint256 _pid,
        address _user
    ) external view returns (WithdrawalRequest[] memory) {
        _ensureValidPool(_rewardToken, _pid);
        return withdrawalRequests[_rewardToken][_pid][_user];
    }

    /**
     * @notice View function to see pending XVSs on frontend
     * @param _rewardToken Reward token address
     * @param _pid Pool index
     * @param _user User address
     * @return Reward the user is eligible for in this pool, in terms of _rewardToken
     */
    function pendingReward(address _rewardToken, uint256 _pid, address _user) external view returns (uint256) {
        _ensureValidPool(_rewardToken, _pid);
        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        UserInfo storage user = userInfos[_rewardToken][_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 supply = pool.token.balanceOf(address(this)).sub(totalPendingWithdrawals[_rewardToken][_pid]);
        uint256 curBlockNumberOrSecond = getBlockNumberOrTimestamp();
        uint256 rewardTokenPerBlockOrSecond = rewardTokenAmountsPerBlockOrSecond[_rewardToken];
        if (curBlockNumberOrSecond > pool.lastRewardBlockOrSecond && supply != 0) {
            uint256 multiplier = curBlockNumberOrSecond.sub(pool.lastRewardBlockOrSecond);
            uint256 reward = multiplier.mul(rewardTokenPerBlockOrSecond).mul(pool.allocPoint).div(
                totalAllocPoints[_rewardToken]
            );
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(supply));
        }
        WithdrawalRequest[] storage requests = withdrawalRequests[_rewardToken][_pid][_user];
        (, uint256 afterUpgradeWithdrawalAmount) = getRequestedWithdrawalAmount(requests);
        return user.amount.sub(afterUpgradeWithdrawalAmount).mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools(address _rewardToken) internal {
        uint256 length = poolInfos[_rewardToken].length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(_rewardToken, pid);
        }
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date
     * @param _rewardToken Reward token address
     * @param _pid Pool index
     */
    function updatePool(address _rewardToken, uint256 _pid) external isActive {
        _ensureValidPool(_rewardToken, _pid);
        _updatePool(_rewardToken, _pid);
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(address _rewardToken, uint256 _pid) internal {
        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        if (getBlockNumberOrTimestamp() <= pool.lastRewardBlockOrSecond) {
            return;
        }
        uint256 supply = pool.token.balanceOf(address(this));
        supply = supply.sub(totalPendingWithdrawals[_rewardToken][_pid]);
        if (supply == 0) {
            pool.lastRewardBlockOrSecond = getBlockNumberOrTimestamp();
            return;
        }
        uint256 curBlockNumberOrSecond = getBlockNumberOrTimestamp();
        uint256 multiplier = curBlockNumberOrSecond.sub(pool.lastRewardBlockOrSecond);
        uint256 reward = multiplier.mul(rewardTokenAmountsPerBlockOrSecond[_rewardToken]).mul(pool.allocPoint).div(
            totalAllocPoints[_rewardToken]
        );
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(supply));
        pool.lastRewardBlockOrSecond = getBlockNumberOrTimestamp();
    }

    function _ensureValidPool(address rewardToken, uint256 pid) internal view {
        require(pid < poolInfos[rewardToken].length, "vault: pool exists?");
    }

    /**
     * @notice Get user info with reward token address and pid
     * @param _rewardToken Reward token address
     * @param _pid Pool index
     * @param _user User address
     * @return amount Deposited amount
     * @return rewardDebt Reward debt (technical value used to track past payouts)
     * @return pendingWithdrawals Requested but not yet executed withdrawals
     */
    function getUserInfo(
        address _rewardToken,
        uint256 _pid,
        address _user
    ) external view returns (uint256 amount, uint256 rewardDebt, uint256 pendingWithdrawals) {
        _ensureValidPool(_rewardToken, _pid);
        UserInfo storage user = userInfos[_rewardToken][_pid][_user];
        amount = user.amount;
        rewardDebt = user.rewardDebt;
        pendingWithdrawals = user.pendingWithdrawals;
    }

    /**
     * @notice Gets the total pending withdrawal amount of a user before upgrade
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     * @param _user The address of the user
     * @return beforeUpgradeWithdrawalAmount Total pending withdrawal amount in requests made before the vault upgrade
     */
    function pendingWithdrawalsBeforeUpgrade(
        address _rewardToken,
        uint256 _pid,
        address _user
    ) public view returns (uint256 beforeUpgradeWithdrawalAmount) {
        WithdrawalRequest[] storage requests = withdrawalRequests[_rewardToken][_pid][_user];
        (beforeUpgradeWithdrawalAmount, ) = getRequestedWithdrawalAmount(requests);
        return beforeUpgradeWithdrawalAmount;
    }

    /**
     * @notice Get the XVS stake balance of an account (excluding the pending withdrawals)
     * @param account The address of the account to check
     * @return The balance that user staked
     */
    function getStakeAmount(address account) internal view returns (uint96) {
        require(xvsAddress != address(0), "XVSVault::getStakeAmount: xvs address is not set");

        PoolInfo[] storage poolInfo = poolInfos[xvsAddress];

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (address(poolInfo[pid].token) == address(xvsAddress)) {
                UserInfo storage user = userInfos[xvsAddress][pid][account];
                return safe96(user.amount.sub(user.pendingWithdrawals), "XVSVault::getStakeAmount: votes overflow");
            }
        }
        return uint96(0);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external isActive {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external isActive {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("XVSVault")), getChainId(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ECDSA.recover(digest, v, r, s);
        require(nonce == nonces[signatory]++, "XVSVault::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "XVSVault::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = getStakeAmount(delegator);
        delegates[delegator] = delegatee;

        emit DelegateChangedV2(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "XVSVault::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "XVSVault::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
        uint32 blockNumberOrSecond = safe32(
            getBlockNumberOrTimestamp(),
            "XVSVault::_writeCheckpoint: block number or second exceeds 32 bits"
        );

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlockOrSecond == blockNumberOrSecond) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumberOrSecond, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChangedV2(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2 ** 32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2 ** 96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    /**
     * @notice Determine the xvs stake balance for an account
     * @param account The address of the account to check
     * @param blockNumberOrSecond The block number or second to get the vote balance at
     * @return The balance that user staked
     */
    function getPriorVotes(address account, uint256 blockNumberOrSecond) external view returns (uint96) {
        require(blockNumberOrSecond < getBlockNumberOrTimestamp(), "XVSVault::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlockOrSecond <= blockNumberOrSecond) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlockOrSecond > blockNumberOrSecond) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlockOrSecond == blockNumberOrSecond) {
                return cp.votes;
            } else if (cp.fromBlockOrSecond < blockNumberOrSecond) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    /*** Admin Functions ***/

    function _become(XVSVaultProxy xvsVaultProxy) external {
        require(msg.sender == xvsVaultProxy.admin(), "only proxy admin can change brains");
        require(xvsVaultProxy._acceptImplementation() == 0, "change not authorized");
    }

    function setXvsStore(address _xvs, address _xvsStore) external onlyAdmin {
        _ensureNonzeroAddress(_xvs);
        _ensureNonzeroAddress(_xvsStore);

        address oldXvsContract = xvsAddress;
        address oldStore = xvsStore;
        require(oldXvsContract == address(0), "already initialized");

        xvsAddress = _xvs;
        xvsStore = _xvsStore;

        _notEntered = true;

        emit StoreUpdated(oldXvsContract, oldStore, _xvs, _xvsStore);
    }

    /**
     * @notice Sets the address of the prime token contract
     * @param _primeToken address of the prime token contract
     * @param _primeRewardToken address of reward token
     * @param _primePoolId pool id for reward
     */
    function setPrimeToken(IPrime _primeToken, address _primeRewardToken, uint256 _primePoolId) external onlyAdmin {
        require(address(_primeToken) != address(0), "prime token cannot be zero address");
        require(_primeRewardToken != address(0), "reward cannot be zero address");

        _ensureValidPool(_primeRewardToken, _primePoolId);

        emit NewPrimeToken(primeToken, _primeToken, primeRewardToken, _primeRewardToken, primePoolId, _primePoolId);

        primeToken = _primeToken;
        primeRewardToken = _primeRewardToken;
        primePoolId = _primePoolId;
    }

    /**
     * @dev Initializes the contract to use either blocks or seconds
     * @param timeBased_ A boolean indicating whether the contract is based on time or block
     * If timeBased is true than blocksPerYear_ param is ignored as blocksOrSecondsPerYear is set to SECONDS_PER_YEAR
     * @param blocksPerYear_ The number of blocks per year
     */
    function initializeTimeManager(bool timeBased_, uint256 blocksPerYear_) external onlyAdmin {
        _initializeTimeManager(timeBased_, blocksPerYear_);
    }

    /**
     * @notice Sets the address of the access control of this contract
     * @dev Admin function to set the access control address
     * @param newAccessControlAddress New address for the access control
     */
    function setAccessControl(address newAccessControlAddress) external onlyAdmin {
        _setAccessControlManager(newAccessControlAddress);
    }

    /**
     * @dev Reverts if the provided address is a zero address
     * @param address_ Address to check
     */
    function _ensureNonzeroAddress(address address_) internal pure {
        require(address_ != address(0), "zero address not allowed");
    }

    /**
     * @dev Transfers the reward to the user, taking into account the rewards store
     *   balance and the previous debt. If there are not enough rewards in the store,
     *   transfers the available funds and records the debt amount in pendingRewardTransfers.
     * @param rewardToken Reward token address
     * @param userAddress User address
     * @param amount Reward amount, in reward tokens
     */
    function _transferReward(address rewardToken, address userAddress, uint256 amount) internal {
        address xvsStore_ = xvsStore;
        uint256 storeBalance = IBEP20(rewardToken).balanceOf(xvsStore_);
        uint256 debtDueToFailedTransfers = pendingRewardTransfers[rewardToken][userAddress];
        uint256 fullAmount = amount.add(debtDueToFailedTransfers);

        if (fullAmount <= storeBalance) {
            if (debtDueToFailedTransfers != 0) {
                pendingRewardTransfers[rewardToken][userAddress] = 0;
                emit VaultDebtUpdated(rewardToken, userAddress, debtDueToFailedTransfers, 0);
            }
            XVSStore(xvsStore_).safeRewardTransfer(rewardToken, userAddress, fullAmount);
            return;
        }
        // Overflow isn't possible due to the check above
        uint256 newOwedAmount = fullAmount - storeBalance;
        pendingRewardTransfers[rewardToken][userAddress] = newOwedAmount;
        emit VaultDebtUpdated(rewardToken, userAddress, debtDueToFailedTransfers, newOwedAmount);
        XVSStore(xvsStore_).safeRewardTransfer(rewardToken, userAddress, storeBalance);
    }

    /**
     * @dev Computes cumulative reward for all user's shares
     * @param user UserInfo storage struct
     * @param pool PoolInfo storage struct
     */
    function _cumulativeReward(UserInfo storage user, PoolInfo storage pool) internal view returns (uint256) {
        return user.amount.sub(user.pendingWithdrawals).mul(pool.accRewardPerShare).div(1e12);
    }

    /**
     * @dev Computes the reward for all user's shares
     * @param user UserInfo storage struct
     * @param pool PoolInfo storage struct
     */
    function _computeReward(UserInfo storage user, PoolInfo storage pool) internal view returns (uint256) {
        return _cumulativeReward(user, pool).sub(user.rewardDebt);
    }
}

pragma solidity ^0.5.16;

contract XVSVaultErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK
    }

    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint error, uint info, uint detail);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

pragma solidity ^0.5.16;

import "./XVSVaultStorage.sol";
import "./XVSVaultErrorReporter.sol";

/**
 * @title XVS Vault Proxy
 * @author Venus
 * @notice XVS Vault Proxy contract
 */
contract XVSVaultProxy is XVSVaultAdminStorage, XVSVaultErrorReporter {
    /**
     * @notice Emitted when pendingXVSVaultImplementation is changed
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingXVSVaultImplementation is accepted, which means XVS Vault implementation is updated
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() public {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
        }

        address oldPendingImplementation = pendingXVSVaultImplementation;

        pendingXVSVaultImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingXVSVaultImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accepts new implementation of XVS Vault. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptImplementation() public returns (uint) {
        // Check caller is pendingImplementation
        if (msg.sender != pendingXVSVaultImplementation) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
        }

        // Save current values for inclusion in log
        address oldImplementation = implementation;
        address oldPendingImplementation = pendingXVSVaultImplementation;

        implementation = pendingXVSVaultImplementation;

        pendingXVSVaultImplementation = address(0);

        emit NewImplementation(oldImplementation, implementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingXVSVaultImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptAdmin() public returns (uint) {
        // Check caller is pendingAdmin
        if (msg.sender != pendingAdmin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize)
            }
            default {
                return(free_mem_ptr, returndatasize)
            }
        }
    }
}

pragma solidity ^0.5.16;

import "../Utils/SafeMath.sol";
import "../Utils/IBEP20.sol";
import "../Tokens/Prime/IPrime.sol";

contract XVSVaultAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active brains of XVS Vault
     */
    address public implementation;

    /**
     * @notice Pending brains of XVS Vault
     */
    address public pendingXVSVaultImplementation;
}

contract XVSVaultStorageV1 is XVSVaultAdminStorage {
    /// @notice Guard variable for re-entrancy checks
    bool internal _notEntered;

    /// @notice The reward token store
    address public xvsStore;

    /// @notice The xvs token address
    address public xvsAddress;

    // Reward tokens created per block or second indentified by reward token address.
    mapping(address => uint256) public rewardTokenAmountsPerBlockOrSecond;

    /// @notice Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingWithdrawals;
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 token; // Address of token contract to stake.
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardBlockOrSecond; // Last block number or second that reward tokens distribution occurs.
        uint256 accRewardPerShare; // Accumulated per share, times 1e12. See below.
        uint256 lockPeriod; // Min time between withdrawal request and its execution.
    }

    // Infomation about a withdrawal request
    struct WithdrawalRequest {
        uint256 amount;
        uint128 lockedUntil;
        uint128 afterUpgrade;
    }

    // Info of each user that stakes tokens.
    mapping(address => mapping(uint256 => mapping(address => UserInfo))) internal userInfos;

    // Info of each pool.
    mapping(address => PoolInfo[]) public poolInfos;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    mapping(address => uint256) public totalAllocPoints;

    // Info of requested but not yet executed withdrawals
    mapping(address => mapping(uint256 => mapping(address => WithdrawalRequest[]))) internal withdrawalRequests;

    /// @notice DEPRECATED A record of each accounts delegate (before the voting power fix)
    mapping(address => address) private __oldDelegatesSlot;

    /// @notice A checkpoint for marking number of votes from a given block or second
    struct Checkpoint {
        uint32 fromBlockOrSecond;
        uint96 votes;
    }

    /// @notice DEPRECATED A record of votes checkpoints for each account, by index (before the voting power fix)
    mapping(address => mapping(uint32 => Checkpoint)) private __oldCheckpointsSlot;

    /// @notice DEPRECATED The number of checkpoints for each account (before the voting power fix)
    mapping(address => uint32) private __oldNumCheckpointsSlot;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint) public nonces;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
}

contract XVSVaultStorage is XVSVaultStorageV1 {
    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice Tracks pending withdrawals for all users for a particular reward token and pool id
    mapping(address => mapping(uint256 => uint256)) public totalPendingWithdrawals;

    /// @notice pause indicator for Vault
    bool public vaultPaused;

    /// @notice if the token is added to any of the pools
    mapping(address => bool) public isStakedToken;

    /// @notice Amount we owe to users because of failed transfer attempts
    mapping(address => mapping(address => uint256)) public pendingRewardTransfers;

    /// @notice Prime token contract address
    IPrime public primeToken;

    /// @notice Reward token for which prime token is issued for staking
    address public primeRewardToken;

    /// @notice Pool ID for which prime token is issued for staking
    uint256 public primePoolId;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}