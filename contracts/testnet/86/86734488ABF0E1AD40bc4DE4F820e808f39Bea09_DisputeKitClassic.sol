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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./IArbitrator.sol";

/**
 * @title IArbitrable
 * Arbitrable interface. Note that this interface follows the ERC-792 standard.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator interface that implements the new arbitration standard.
 * Unlike the ERC-792 this standard doesn't have anything related to appeals, so each arbitrator can implement an appeal system that suits it the most.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrable The arbitrable receiving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrable indexed _arbitrable, uint256 indexed _disputeID, uint256 _ruling);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must pay at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Required cost of arbitration.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@unknownunknown1, @jaybuidl]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8;

import "./IArbitrator.sol";

/**
 *  @title IDisputeKit
 *  An abstraction of the Dispute Kits intended for interfacing with KlerosCore.
 *  It does not intend to abstract the interactions with the user (such as voting or appeal funding) to allow for implementation-specific parameters.
 */
interface IDisputeKit {
    // ************************************ //
    // *             Events               * //
    // ************************************ //

    /**
     * @dev Emitted when casting a vote to provide the justification of juror's choice.
     * @param _coreDisputeID ID of the dispute in the core contract.
     * @param _juror Address of the juror.
     * @param _choice The choice juror voted for.
     * @param _justification Justification of the choice.
     */
    event Justification(
        uint256 indexed _coreDisputeID,
        address indexed _juror,
        uint256 indexed _choice,
        string _justification
    );

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /** @dev Creates a local dispute and maps it to the dispute ID in the Core contract.
     *  Note: Access restricted to Kleros Core only.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
     *  @param _numberOfChoices Number of choices of the dispute
     *  @param _extraData Additional info about the dispute, for possible use in future dispute kits.
     */
    function createDispute(
        uint256 _coreDisputeID,
        uint256 _numberOfChoices,
        bytes calldata _extraData,
        uint256 _nbVotes
    ) external;

    /** @dev Passes the phase.
     */
    function passPhase() external;

    /** @dev Draws the juror from the sortition tree. The drawn address is picked up by Kleros Core.
     *  Note: Access restricted to Kleros Core only.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
     *  @return drawnAddress The drawn address.
     */
    function draw(uint256 _coreDisputeID) external returns (address drawnAddress);

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /** @dev Gets the current ruling of a specified dispute.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
     *  @return ruling The current ruling.
     *  @return tied Whether it's a tie or not.
     *  @return overridden Whether the ruling was overridden by appeal funding or not.
     */
    function currentRuling(uint256 _coreDisputeID) external view returns (uint256 ruling, bool tied, bool overridden);

    /** @dev Gets the degree of coherence of a particular voter. This function is called by Kleros Core in order to determine the amount of the reward.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
     *  @param _coreRoundID The ID of the round in Kleros Core, not in the Dispute Kit.
     *  @param _voteID The ID of the vote.
     *  @return The degree of coherence in basis points.
     */
    function getDegreeOfCoherence(
        uint256 _coreDisputeID,
        uint256 _coreRoundID,
        uint256 _voteID
    ) external view returns (uint256);

    /** @dev Gets the number of jurors who are eligible to a reward in this round.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
     *  @param _coreRoundID The ID of the round in Kleros Core, not in the Dispute Kit.
     *  @return The number of coherent jurors.
     */
    function getCoherentCount(uint256 _coreDisputeID, uint256 _coreRoundID) external view returns (uint256);

    /** @dev Returns true if all of the jurors have cast their commits for the last round.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
     *  @return Whether all of the jurors have cast their commits for the last round.
     */
    function areCommitsAllCast(uint256 _coreDisputeID) external view returns (bool);

    /** @dev Returns true if all of the jurors have cast their votes for the last round.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
     *  @return Whether all of the jurors have cast their votes for the last round.
     */
    function areVotesAllCast(uint256 _coreDisputeID) external view returns (bool);

    /** @dev Returns true if the specified voter was active in this round.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
     *  @param _coreRoundID The ID of the round in Kleros Core, not in the Dispute Kit.
     *  @param _voteID The ID of the voter.
     *  @return Whether the voter was active or not.
     */
    function isVoteActive(uint256 _coreDisputeID, uint256 _coreRoundID, uint256 _voteID) external view returns (bool);

    function getRoundInfo(
        uint256 _coreDisputeID,
        uint256 _coreRoundID,
        uint256 _choice
    )
        external
        view
        returns (
            uint256 winningChoice,
            bool tied,
            uint256 totalVoted,
            uint256 totalCommited,
            uint256 nbVoters,
            uint256 choiceCount
        );

    function getVoteInfo(
        uint256 _coreDisputeID,
        uint256 _coreRoundID,
        uint256 _voteID
    ) external view returns (address account, bytes32 commit, uint256 choice, bool voted);

    /** @dev Returns the number of disputes without jurors in the dispute kit.
     *  @return The number of disputes without jurors in the dispute kit.
     */
    function disputesWithoutJurors() external view returns (uint256);

    /** @dev Returns true if the dispute kit is ready to Resolve, regardless of the number of disputes without jurors.
     *  @return Whether the dispute kit is ready to resolve, regardless of the number of disputes without jurors.
     */
    function isResolving() external view returns (bool);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@unknownunknown1, @jaybuidl]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IArbitrator.sol";
import "./IDisputeKit.sol";
import {SortitionSumTreeFactoryV2} from "../libraries/SortitionSumTreeFactoryV2.sol";

/**
 *  @title KlerosCore
 *  Core arbitrator contract for Kleros v2.
 *  Note that this contract trusts the token and the dispute kit contracts.
 */
contract KlerosCore is IArbitrator {
    using SortitionSumTreeFactoryV2 for SortitionSumTreeFactoryV2.SortitionSumTrees; // Use library functions for sortition sum trees.

    // ************************************* //
    // *         Enums / Structs           * //
    // ************************************* //

    enum Phase {
        staking, // Stake can be updated during this phase.
        freezing // Phase during which the dispute kits can undergo the drawing process. Staking is not allowed during this phase.
    }

    enum Period {
        evidence, // Evidence can be submitted. This is also when drawing has to take place.
        commit, // Jurors commit a hashed vote. This is skipped for courts without hidden votes.
        vote, // Jurors reveal/cast their vote depending on whether the court has hidden votes or not.
        appeal, // The dispute can be appealed.
        execution // Tokens are redistributed and the ruling is executed.
    }

    struct Court {
        uint96 parent; // The parent court.
        bool hiddenVotes; // Whether to use commit and reveal or not.
        uint256[] children; // List of child courts.
        uint256 minStake; // Minimum tokens needed to stake in the court.
        uint256 alpha; // Basis point of tokens that are lost when incoherent.
        uint256 feeForJuror; // Arbitration fee paid per juror.
        uint256 jurorsForCourtJump; // The appeal after the one that reaches this number of jurors will go to the parent court if any.
        uint256[4] timesPerPeriod; // The time allotted to each dispute period in the form `timesPerPeriod[period]`.
        mapping(uint256 => bool) supportedDisputeKits; // True if DK with this ID is supported by the court.
    }

    struct Dispute {
        uint96 courtID; // The ID of the court the dispute is in.
        IArbitrable arbitrated; // The arbitrable contract.
        Period period; // The current period of the dispute.
        bool ruled; // True if the ruling has been executed, false otherwise.
        uint256 lastPeriodChange; // The last time the period was changed.
        Round[] rounds;
    }

    struct Round {
        uint256 disputeKitID; // Index of the dispute kit in the array.
        uint256 tokensAtStakePerJuror; // The amount of tokens at stake for each juror in this round.
        uint256 totalFeesForJurors; // The total juror fees paid in this round.
        uint256 nbVotes; // The total number of votes the dispute can possibly have in the current round. Former votes[_round].length.
        uint256 repartitions; // A counter of reward repartitions made in this round.
        uint256 penalties; // The amount of tokens collected from penalties in this round.
        address[] drawnJurors; // Addresses of the jurors that were drawn in this round.
    }

    struct Juror {
        uint96[] courtIDs; // The IDs of courts where the juror's stake path ends. A stake path is a path from the general court to a court the juror directly staked in using `_setStake`.
        mapping(uint96 => uint256) stakedTokens; // The number of tokens the juror has staked in the court in the form `stakedTokens[courtID]`.
        mapping(uint96 => uint256) lockedTokens; // The number of tokens the juror has locked in the court in the form `lockedTokens[courtID]`.
    }

    struct DisputeKitNode {
        uint256 parent; // Index of the parent dispute kit. If it's 0 then this DK is a root.
        uint256[] children; // List of child dispute kits.
        IDisputeKit disputeKit; // The dispute kit implementation.
        bool needsFreezing; // The dispute kit needs freezing.
        uint256 depthLevel; // How far this DK is from the root. 0 for root DK.
    }

    struct DelayedStake {
        address account; // The address of the juror.
        uint96 courtID; // The ID of the court.
        uint256 stake; // The new stake.
        uint256 penalty; // Penalty value, in case the stake was set during execution.
    }

    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    uint96 public constant FORKING_COURT = 0; // Index of the forking court.
    uint96 public constant GENERAL_COURT = 1; // Index of the default (general) court.
    uint256 public constant NULL_DISPUTE_KIT = 0; // Null pattern to indicate a top-level DK which has no parent.
    uint256 public constant DISPUTE_KIT_CLASSIC = 1; // Index of the default DK. 0 index is skipped.
    uint256 public constant MAX_STAKE_PATHS = 4; // The maximum number of stake paths a juror can have.
    uint256 public constant MIN_JURORS = 3; // The global default minimum number of jurors in a dispute.
    uint256 public constant ALPHA_DIVISOR = 1e4; // The number to divide `Court.alpha` by.
    uint256 public constant NON_PAYABLE_AMOUNT = (2 ** 256 - 2) / 2; // An amount higher than the supply of ETH.
    uint256 public constant SEARCH_ITERATIONS = 10; // Number of iterations to search for suitable parent court before jumping to the top court.

    address public governor; // The governor of the contract.
    IERC20 public pinakion; // The Pinakion token contract.
    // TODO: interactions with jurorProsecutionModule.
    address public jurorProsecutionModule; // The module for juror's prosecution.
    Phase public phase; // The current phase.
    uint256 public minStakingTime; // The time after which the phase can be switched to Freezing if there are open disputes.
    uint256 public maxFreezingTime; // The time after which the phase can be switched back to Staking.
    uint256 public lastPhaseChange; // The last time the phase was changed.
    uint256 public freezeBlock; // Number of the block when Core was frozen.
    Court[] public courts; // The courts.
    DisputeKitNode[] public disputeKitNodes; // The list of DisputeKitNode, indexed by DisputeKitID.
    uint256[] public disputesKitIDsThatNeedFreezing; // The disputeKitIDs that need switching to Freezing phase.
    Dispute[] public disputes; // The disputes.
    mapping(address => Juror) internal jurors; // The jurors.
    SortitionSumTreeFactoryV2.SortitionSumTrees internal sortitionSumTrees; // The sortition sum trees.
    mapping(uint256 => DelayedStake) public delayedStakes; // Stores the stakes that were changed during Freezing phase, to update them when the phase is switched to Staking.

    uint256 public delayedStakeWriteIndex; // The index of the last `delayedStake` item that was written to the array. 0 index is skipped.
    uint256 public delayedStakeReadIndex = 1; // The index of the next `delayedStake` item that should be processed. Starts at 1 because 0 index is skipped.

    // ************************************* //
    // *              Events               * //
    // ************************************* //

    event NewPhase(Phase _phase);
    event NewPeriod(uint256 indexed _disputeID, Period _period);
    event StakeSet(address indexed _address, uint256 _courtID, uint256 _amount, uint256 _newTotalStake);
    event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);
    event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);
    event Draw(address indexed _address, uint256 indexed _disputeID, uint256 _roundID, uint256 _voteID);
    event CourtCreated(
        uint256 indexed _courtID,
        uint96 indexed _parent,
        bool _hiddenVotes,
        uint256 _minStake,
        uint256 _alpha,
        uint256 _feeForJuror,
        uint256 _jurorsForCourtJump,
        uint256[4] _timesPerPeriod,
        uint256 _sortitionSumTreeK,
        uint256[] _supportedDisputeKits
    );
    event CourtModified(uint96 indexed _courtID, string _param);
    event DisputeKitCreated(
        uint256 indexed _disputeKitID,
        IDisputeKit indexed _disputeKitAddress,
        uint256 indexed _parent
    );
    event DisputeKitEnabled(uint96 indexed _courtID, uint256 indexed _disputeKitID, bool indexed _enable);
    event CourtJump(
        uint256 indexed _disputeID,
        uint256 indexed _roundID,
        uint96 indexed _fromCourtID,
        uint96 _toCourtID
    );
    event DisputeKitJump(
        uint256 indexed _disputeID,
        uint256 indexed _roundID,
        uint256 indexed _fromDisputeKitID,
        uint256 _toDisputeKitID
    );
    event TokenAndETHShift(
        address indexed _account,
        uint256 indexed _disputeID,
        int256 _tokenAmount,
        int256 _ethAmount
    );

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    modifier onlyByGovernor() {
        require(governor == msg.sender, "Governor only");
        _;
    }

    /** @dev Constructor.
     *  @param _governor The governor's address.
     *  @param _pinakion The address of the token contract.
     *  @param _jurorProsecutionModule The address of the juror prosecution module.
     *  @param _disputeKit The address of the default dispute kit.
     *  @param _phaseTimeouts minStakingTime and maxFreezingTime respectively
     *  @param _hiddenVotes The `hiddenVotes` property value of the general court.
     *  @param _courtParameters Numeric parameters of General court (minStake, alpha, feeForJuror and jurorsForCourtJump respectively).
     *  @param _timesPerPeriod The `timesPerPeriod` property value of the general court.
     *  @param _sortitionSumTreeK The number of children per node of the general court's sortition sum tree.
     */
    constructor(
        address _governor,
        IERC20 _pinakion,
        address _jurorProsecutionModule,
        IDisputeKit _disputeKit,
        uint256[2] memory _phaseTimeouts,
        bool _hiddenVotes,
        uint256[4] memory _courtParameters,
        uint256[4] memory _timesPerPeriod,
        uint256 _sortitionSumTreeK
    ) {
        governor = _governor;
        pinakion = _pinakion;
        jurorProsecutionModule = _jurorProsecutionModule;
        minStakingTime = _phaseTimeouts[0];
        maxFreezingTime = _phaseTimeouts[1];
        lastPhaseChange = block.timestamp;

        // NULL_DISPUTE_KIT: an empty element at index 0 to indicate when a node has no parent.
        disputeKitNodes.push();

        // DISPUTE_KIT_CLASSIC
        disputeKitNodes.push(
            DisputeKitNode({
                parent: NULL_DISPUTE_KIT,
                children: new uint256[](0),
                disputeKit: _disputeKit,
                needsFreezing: false,
                depthLevel: 0
            })
        );
        emit DisputeKitCreated(DISPUTE_KIT_CLASSIC, _disputeKit, NULL_DISPUTE_KIT);

        // FORKING_COURT
        // TODO: Fill the properties for the Forking court, emit CourtCreated.
        courts.push();
        sortitionSumTrees.createTree(bytes32(uint256(FORKING_COURT)), _sortitionSumTreeK);

        // GENERAL_COURT
        Court storage court = courts.push();
        court.parent = FORKING_COURT;
        court.children = new uint256[](0);
        court.hiddenVotes = _hiddenVotes;
        court.minStake = _courtParameters[0];
        court.alpha = _courtParameters[1];
        court.feeForJuror = _courtParameters[2];
        court.jurorsForCourtJump = _courtParameters[3];
        court.timesPerPeriod = _timesPerPeriod;
        sortitionSumTrees.createTree(bytes32(uint256(GENERAL_COURT)), _sortitionSumTreeK);
        emit CourtCreated(
            1,
            court.parent,
            _hiddenVotes,
            _courtParameters[0],
            _courtParameters[1],
            _courtParameters[2],
            _courtParameters[3],
            _timesPerPeriod,
            _sortitionSumTreeK,
            new uint256[](0)
        );
        enableDisputeKit(GENERAL_COURT, DISPUTE_KIT_CLASSIC, true);
    }

    // ************************ //
    // *      Governance      * //
    // ************************ //

    /** @dev Allows the governor to call anything on behalf of the contract.
     *  @param _destination The destination of the call.
     *  @param _amount The value sent with the call.
     *  @param _data The data sent with the call.
     */
    function executeGovernorProposal(
        address _destination,
        uint256 _amount,
        bytes memory _data
    ) external onlyByGovernor {
        (bool success, ) = _destination.call{value: _amount}(_data);
        require(success, "Unsuccessful call");
    }

    /** @dev Changes the `governor` storage variable.
     *  @param _governor The new value for the `governor` storage variable.
     */
    function changeGovernor(address payable _governor) external onlyByGovernor {
        governor = _governor;
    }

    /** @dev Changes the `pinakion` storage variable.
     *  @param _pinakion The new value for the `pinakion` storage variable.
     */
    function changePinakion(IERC20 _pinakion) external onlyByGovernor {
        pinakion = _pinakion;
    }

    /** @dev Changes the `jurorProsecutionModule` storage variable.
     *  @param _jurorProsecutionModule The new value for the `jurorProsecutionModule` storage variable.
     */
    function changeJurorProsecutionModule(address _jurorProsecutionModule) external onlyByGovernor {
        jurorProsecutionModule = _jurorProsecutionModule;
    }

    /** @dev Changes the `minStakingTime` storage variable.
     *  @param _minStakingTime The new value for the `minStakingTime` storage variable.
     */
    function changeMinStakingTime(uint256 _minStakingTime) external onlyByGovernor {
        minStakingTime = _minStakingTime;
    }

    /** @dev Changes the `maxFreezingTime` storage variable.
     *  @param _maxFreezingTime The new value for the `maxFreezingTime` storage variable.
     */
    function changeMaxFreezingTime(uint256 _maxFreezingTime) external onlyByGovernor {
        maxFreezingTime = _maxFreezingTime;
    }

    /** @dev Add a new supported dispute kit module to the court.
     *  @param _disputeKitAddress The address of the dispute kit contract.
     *  @param _parent The ID of the parent dispute kit. It is left empty when root DK is created.
     *  Note that the root DK must be supported by the general court.
     */
    function addNewDisputeKit(IDisputeKit _disputeKitAddress, uint256 _parent) external onlyByGovernor {
        uint256 disputeKitID = disputeKitNodes.length;
        require(_parent < disputeKitID, "!Parent");
        uint256 depthLevel;
        if (_parent != NULL_DISPUTE_KIT) {
            depthLevel = disputeKitNodes[_parent].depthLevel + 1;
            // It should be always possible to reach the root from the leaf with the defined number of search iterations.
            require(depthLevel < SEARCH_ITERATIONS, "Depth level max");
        }
        disputeKitNodes.push(
            DisputeKitNode({
                parent: _parent,
                children: new uint256[](0),
                disputeKit: _disputeKitAddress,
                needsFreezing: false,
                depthLevel: depthLevel
            })
        );
        disputeKitNodes[_parent].children.push(disputeKitID);
        emit DisputeKitCreated(disputeKitID, _disputeKitAddress, _parent);
        if (_parent == NULL_DISPUTE_KIT) {
            // A new dispute kit tree root should always be supported by the General court.
            enableDisputeKit(GENERAL_COURT, disputeKitID, true);
        }
    }

    /** @dev Creates a court under a specified parent court.
     *  @param _parent The `parent` property value of the court.
     *  @param _hiddenVotes The `hiddenVotes` property value of the court.
     *  @param _minStake The `minStake` property value of the court.
     *  @param _alpha The `alpha` property value of the court.
     *  @param _feeForJuror The `feeForJuror` property value of the court.
     *  @param _jurorsForCourtJump The `jurorsForCourtJump` property value of the court.
     *  @param _timesPerPeriod The `timesPerPeriod` property value of the court.
     *  @param _sortitionSumTreeK The number of children per node of the court's sortition sum tree.
     *  @param _supportedDisputeKits Indexes of dispute kits that this court will support.
     */
    function createCourt(
        uint96 _parent,
        bool _hiddenVotes,
        uint256 _minStake,
        uint256 _alpha,
        uint256 _feeForJuror,
        uint256 _jurorsForCourtJump,
        uint256[4] memory _timesPerPeriod,
        uint256 _sortitionSumTreeK,
        uint256[] memory _supportedDisputeKits
    ) external onlyByGovernor {
        require(courts[_parent].minStake <= _minStake, "MinStake lower than parent court");
        require(_supportedDisputeKits.length > 0, "!Supported DK");
        require(_parent != FORKING_COURT, "Invalid: Forking court as parent");

        uint256 courtID = courts.length;
        Court storage court = courts.push();

        for (uint256 i = 0; i < _supportedDisputeKits.length; i++) {
            require(
                _supportedDisputeKits[i] > 0 && _supportedDisputeKits[i] < disputeKitNodes.length,
                "Wrong DK index"
            );
            court.supportedDisputeKits[_supportedDisputeKits[i]] = true;
        }

        court.parent = _parent;
        court.children = new uint256[](0);
        court.hiddenVotes = _hiddenVotes;
        court.minStake = _minStake;
        court.alpha = _alpha;
        court.feeForJuror = _feeForJuror;
        court.jurorsForCourtJump = _jurorsForCourtJump;
        court.timesPerPeriod = _timesPerPeriod;

        sortitionSumTrees.createTree(bytes32(courtID), _sortitionSumTreeK);
        // Update the parent.
        courts[_parent].children.push(courtID);
        emit CourtCreated(
            courtID,
            _parent,
            _hiddenVotes,
            _minStake,
            _alpha,
            _feeForJuror,
            _jurorsForCourtJump,
            _timesPerPeriod,
            _sortitionSumTreeK,
            _supportedDisputeKits
        );
    }

    /** @dev Changes the `minStake` property value of a specified court. Don't set to a value lower than its parent's `minStake` property value.
     *  @param _courtID The ID of the court.
     *  @param _minStake The new value for the `minStake` property value.
     */
    function changeCourtMinStake(uint96 _courtID, uint256 _minStake) external onlyByGovernor {
        require(
            _courtID == GENERAL_COURT || courts[courts[_courtID].parent].minStake <= _minStake,
            "MinStake lower than parent court"
        );
        for (uint256 i = 0; i < courts[_courtID].children.length; i++) {
            require(courts[courts[_courtID].children[i]].minStake >= _minStake, "MinStake lower than parent court");
        }

        courts[_courtID].minStake = _minStake;
        emit CourtModified(_courtID, "minStake");
    }

    /** @dev Changes the `alpha` property value of a specified court.
     *  @param _courtID The ID of the court.
     *  @param _alpha The new value for the `alpha` property value.
     */
    function changeCourtAlpha(uint96 _courtID, uint256 _alpha) external onlyByGovernor {
        courts[_courtID].alpha = _alpha;
        emit CourtModified(_courtID, "alpha");
    }

    /** @dev Changes the `feeForJuror` property value of a specified court.
     *  @param _courtID The ID of the court.
     *  @param _feeForJuror The new value for the `feeForJuror` property value.
     */
    function changeCourtJurorFee(uint96 _courtID, uint256 _feeForJuror) external onlyByGovernor {
        courts[_courtID].feeForJuror = _feeForJuror;
        emit CourtModified(_courtID, "feeForJuror");
    }

    /** @dev Changes the `jurorsForCourtJump` property value of a specified court.
     *  @param _courtID The ID of the court.
     *  @param _jurorsForCourtJump The new value for the `jurorsForCourtJump` property value.
     */
    function changeCourtJurorsForJump(uint96 _courtID, uint256 _jurorsForCourtJump) external onlyByGovernor {
        courts[_courtID].jurorsForCourtJump = _jurorsForCourtJump;
        emit CourtModified(_courtID, "jurorsForCourtJump");
    }

    /** @dev Changes the `hiddenVotes` property value of a specified court.
     *  @param _courtID The ID of the court.
     *  @param _hiddenVotes The new value for the `hiddenVotes` property value.
     */
    function changeCourtHiddenVotes(uint96 _courtID, bool _hiddenVotes) external onlyByGovernor {
        courts[_courtID].hiddenVotes = _hiddenVotes;
        emit CourtModified(_courtID, "hiddenVotes");
    }

    /** @dev Changes the `timesPerPeriod` property value of a specified court.
     *  @param _courtID The ID of the court.
     *  @param _timesPerPeriod The new value for the `timesPerPeriod` property value.
     */
    function changeCourtTimesPerPeriod(uint96 _courtID, uint256[4] memory _timesPerPeriod) external onlyByGovernor {
        courts[_courtID].timesPerPeriod = _timesPerPeriod;
        emit CourtModified(_courtID, "timesPerPeriod");
    }

    /** @dev Adds/removes court's support for specified dispute kits.
     *  @param _courtID The ID of the court.
     *  @param _disputeKitIDs The IDs of dispute kits which support should be added/removed.
     *  @param _enable Whether add or remove the dispute kits from the court.
     */
    function enableDisputeKits(uint96 _courtID, uint256[] memory _disputeKitIDs, bool _enable) external onlyByGovernor {
        Court storage court = courts[_courtID];
        for (uint256 i = 0; i < _disputeKitIDs.length; i++) {
            if (_enable) {
                require(_disputeKitIDs[i] > 0 && _disputeKitIDs[i] < disputeKitNodes.length, "Wrong DK index");
                enableDisputeKit(_courtID, _disputeKitIDs[i], true);
            } else {
                require(
                    !(_courtID == GENERAL_COURT && disputeKitNodes[_disputeKitIDs[i]].parent == NULL_DISPUTE_KIT),
                    "Can't disable Root DK in General"
                );
                enableDisputeKit(_courtID, _disputeKitIDs[i], false);
            }
        }
    }

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /** @dev Sets the caller's stake in a court.
     *  @param _courtID The ID of the court.
     *  @param _stake The new stake.
     */
    function setStake(uint96 _courtID, uint256 _stake) external {
        require(setStakeForAccount(msg.sender, _courtID, _stake, 0), "Staking failed");
    }

    /** @dev Executes the next delayed stakes.
     *  @param _iterations The number of delayed stakes to execute.
     */
    function executeDelayedStakes(uint256 _iterations) external {
        require(phase == Phase.staking, "!Staking phase.");

        uint256 actualIterations = (delayedStakeReadIndex + _iterations) - 1 > delayedStakeWriteIndex
            ? (delayedStakeWriteIndex - delayedStakeReadIndex) + 1
            : _iterations;
        uint256 newDelayedStakeReadIndex = delayedStakeReadIndex + actualIterations;

        for (uint256 i = delayedStakeReadIndex; i < newDelayedStakeReadIndex; i++) {
            DelayedStake storage delayedStake = delayedStakes[i];
            setStakeForAccount(delayedStake.account, delayedStake.courtID, delayedStake.stake, delayedStake.penalty);
            delete delayedStakes[i];
        }
        delayedStakeReadIndex = newDelayedStakeReadIndex;
    }

    /** @dev Creates a dispute. Must be called by the arbitrable contract.
     *  @param _numberOfChoices Number of choices for the jurors to choose from.
     *  @param _extraData Additional info about the dispute. We use it to pass the ID of the dispute's court (first 32 bytes),
     *  the minimum number of jurors required (next 32 bytes) and the ID of the specific dispute kit (last 32 bytes).
     *  @return disputeID The ID of the created dispute.
     */
    function createDispute(
        uint256 _numberOfChoices,
        bytes memory _extraData
    ) external payable override returns (uint256 disputeID) {
        require(msg.value >= arbitrationCost(_extraData), "ETH too low for arbitration cost");

        (uint96 courtID, , uint256 disputeKitID) = extraDataToCourtIDMinJurorsDisputeKit(_extraData);
        require(courts[courtID].supportedDisputeKits[disputeKitID], "DK unsupported by court");

        disputeID = disputes.length;
        Dispute storage dispute = disputes.push();
        dispute.courtID = courtID;
        dispute.arbitrated = IArbitrable(msg.sender);
        dispute.lastPeriodChange = block.timestamp;

        IDisputeKit disputeKit = disputeKitNodes[disputeKitID].disputeKit;
        Court storage court = courts[dispute.courtID];
        Round storage round = dispute.rounds.push();
        round.nbVotes = msg.value / court.feeForJuror;
        round.disputeKitID = disputeKitID;
        round.tokensAtStakePerJuror = (court.minStake * court.alpha) / ALPHA_DIVISOR;
        round.totalFeesForJurors = msg.value;

        if (!disputeKitNodes[disputeKitID].needsFreezing) {
            // Ensures uniqueness in the disputesKitIDsThatNeedFreezing array.
            disputeKitNodes[disputeKitID].needsFreezing = true;
            disputesKitIDsThatNeedFreezing.push(disputeKitID);
        }

        disputeKit.createDispute(disputeID, _numberOfChoices, _extraData, round.nbVotes);
        emit DisputeCreation(disputeID, IArbitrable(msg.sender));
    }

    /** @dev Switches the phases between Staking and Freezing, also signal the switch to the dispute kits.
     */
    function passPhase() external {
        if (phase == Phase.staking) {
            require(block.timestamp - lastPhaseChange >= minStakingTime, "MinStakingTime not passed");
            require(disputesKitIDsThatNeedFreezing.length > 0, "No DK needs freezing");
            phase = Phase.freezing;
            freezeBlock = block.number;
        } else {
            // phase == Phase.freezing
            bool timeout = this.freezingPhaseTimeout();
            for (int256 i = int256(disputesKitIDsThatNeedFreezing.length) - 1; i >= 0; --i) {
                uint256 disputeKitID = disputesKitIDsThatNeedFreezing[uint256(i)];
                IDisputeKit disputeKit = disputeKitNodes[disputesKitIDsThatNeedFreezing[uint256(i)]].disputeKit;
                if (timeout && !disputeKit.isResolving()) {
                    // Force the dispute kit to be ready for Staking phase.
                    disputeKit.passPhase(); // Should not be called if already in Resolving phase, because it reverts.
                    require(disputeKit.isResolving(), "Some DK not in Resolving phase");
                } else {
                    // Check if the dispute kit is ready for Staking phase.
                    require(disputeKit.isResolving(), "Some DK not in Resolving phase");
                    if (disputeKit.disputesWithoutJurors() == 0) {
                        // The dispute kit had time to finish drawing jurors for all its disputes.
                        disputeKitNodes[disputeKitID].needsFreezing = false;
                        if (i < int256(disputesKitIDsThatNeedFreezing.length) - 1) {
                            // This is not the last element so copy the last element to the current one, then pop.
                            disputesKitIDsThatNeedFreezing[uint256(i)] = disputesKitIDsThatNeedFreezing[
                                disputesKitIDsThatNeedFreezing.length - 1
                            ];
                        }
                        disputesKitIDsThatNeedFreezing.pop();
                    }
                }
            }
            phase = Phase.staking;
        }
        // Should not be reached if the phase is unchanged.
        lastPhaseChange = block.timestamp;
        emit NewPhase(phase);
    }

    /** @dev Passes the period of a specified dispute.
     *  @param _disputeID The ID of the dispute.
     */
    function passPeriod(uint256 _disputeID) external {
        Dispute storage dispute = disputes[_disputeID];
        Court storage court = courts[dispute.courtID];

        uint256 currentRound = dispute.rounds.length - 1;
        Round storage round = dispute.rounds[currentRound];
        if (dispute.period == Period.evidence) {
            require(
                currentRound > 0 ||
                    block.timestamp - dispute.lastPeriodChange >= court.timesPerPeriod[uint256(dispute.period)],
                "Evidence not passed && !Appeal"
            );
            require(round.drawnJurors.length == round.nbVotes, "Dispute still drawing");
            dispute.period = court.hiddenVotes ? Period.commit : Period.vote;
        } else if (dispute.period == Period.commit) {
            require(
                block.timestamp - dispute.lastPeriodChange >= court.timesPerPeriod[uint256(dispute.period)] ||
                    disputeKitNodes[round.disputeKitID].disputeKit.areCommitsAllCast(_disputeID),
                "Commit period not passed"
            );
            dispute.period = Period.vote;
        } else if (dispute.period == Period.vote) {
            require(
                block.timestamp - dispute.lastPeriodChange >= court.timesPerPeriod[uint256(dispute.period)] ||
                    disputeKitNodes[round.disputeKitID].disputeKit.areVotesAllCast(_disputeID),
                "Vote period not passed"
            );
            dispute.period = Period.appeal;
            emit AppealPossible(_disputeID, dispute.arbitrated);
        } else if (dispute.period == Period.appeal) {
            require(
                block.timestamp - dispute.lastPeriodChange >= court.timesPerPeriod[uint256(dispute.period)],
                "Appeal period not passed"
            );
            dispute.period = Period.execution;
        } else if (dispute.period == Period.execution) {
            revert("Dispute period is final");
        }

        dispute.lastPeriodChange = block.timestamp;
        emit NewPeriod(_disputeID, dispute.period);
    }

    /** @dev Draws jurors for the dispute. Can be called in parts.
     *  @param _disputeID The ID of the dispute.
     *  @param _iterations The number of iterations to run.
     */
    function draw(uint256 _disputeID, uint256 _iterations) external {
        require(phase == Phase.freezing, "Wrong phase");

        Dispute storage dispute = disputes[_disputeID];
        uint256 currentRound = dispute.rounds.length - 1;
        Round storage round = dispute.rounds[currentRound];
        require(dispute.period == Period.evidence, "!Evidence period");

        IDisputeKit disputeKit = disputeKitNodes[round.disputeKitID].disputeKit;
        uint256 startIndex = round.drawnJurors.length;
        uint256 endIndex = startIndex + _iterations <= round.nbVotes ? startIndex + _iterations : round.nbVotes;

        for (uint256 i = startIndex; i < endIndex; i++) {
            address drawnAddress = disputeKit.draw(_disputeID);
            if (drawnAddress != address(0)) {
                // In case no one has staked at the court yet.
                jurors[drawnAddress].lockedTokens[dispute.courtID] += round.tokensAtStakePerJuror;
                emit Draw(drawnAddress, _disputeID, currentRound, round.drawnJurors.length);
                round.drawnJurors.push(drawnAddress);
            }
        }
    }

    /** @dev Appeals the ruling of a specified dispute.
     *  Note: Access restricted to the Dispute Kit for this `disputeID`.
     *  @param _disputeID The ID of the dispute.
     *  @param _numberOfChoices Number of choices for the dispute. Can be required during court jump.
     *  @param _extraData Extradata for the dispute. Can be required during court jump.
     */
    function appeal(uint256 _disputeID, uint256 _numberOfChoices, bytes memory _extraData) external payable {
        require(msg.value >= appealCost(_disputeID), "ETH too low for appeal cost");

        Dispute storage dispute = disputes[_disputeID];
        require(dispute.period == Period.appeal, "Dispute not appealable");

        Round storage round = dispute.rounds[dispute.rounds.length - 1];
        require(msg.sender == address(disputeKitNodes[round.disputeKitID].disputeKit), "Dispute Kit only");

        uint96 newCourtID = dispute.courtID;
        uint256 newDisputeKitID = round.disputeKitID;

        // Warning: the extra round must be created before calling disputeKit.createDispute()
        Round storage extraRound = dispute.rounds.push();

        if (round.nbVotes >= courts[newCourtID].jurorsForCourtJump) {
            // Jump to parent court.
            newCourtID = courts[newCourtID].parent;

            for (uint256 i = 0; i < SEARCH_ITERATIONS; i++) {
                if (courts[newCourtID].supportedDisputeKits[newDisputeKitID]) {
                    break;
                } else if (disputeKitNodes[newDisputeKitID].parent != NULL_DISPUTE_KIT) {
                    newDisputeKitID = disputeKitNodes[newDisputeKitID].parent;
                } else {
                    // DK's parent has 0 index, that means we reached the root DK (0 depth level).
                    // Jump to the next parent court if the current court doesn't support any DK from this tree.
                    // Note that we don't reset newDisputeKitID in this case as, a precaution.
                    newCourtID = courts[newCourtID].parent;
                }
            }
            // We didn't find a court that is compatible with DK from this tree, so we jump directly to the top court.
            // Note that this can only happen when disputeKitID is at its root, and each root DK is supported by the top court by default.
            if (!courts[newCourtID].supportedDisputeKits[newDisputeKitID]) {
                newCourtID = GENERAL_COURT;
            }

            if (newCourtID != dispute.courtID) {
                emit CourtJump(_disputeID, dispute.rounds.length - 1, dispute.courtID, newCourtID);
            }
        }

        dispute.courtID = newCourtID;
        dispute.period = Period.evidence;
        dispute.lastPeriodChange = block.timestamp;

        Court storage court = courts[newCourtID];
        extraRound.nbVotes = msg.value / court.feeForJuror; // As many votes that can be afforded by the provided funds.
        extraRound.tokensAtStakePerJuror = (court.minStake * court.alpha) / ALPHA_DIVISOR;
        extraRound.totalFeesForJurors = msg.value;
        extraRound.disputeKitID = newDisputeKitID;

        if (!disputeKitNodes[newDisputeKitID].needsFreezing) {
            // Ensures uniqueness in the disputesKitIDsThatNeedFreezing array.
            disputeKitNodes[newDisputeKitID].needsFreezing = true;
            disputesKitIDsThatNeedFreezing.push(newDisputeKitID);
        }

        // Dispute kit was changed, so create a dispute in the new DK contract.
        if (extraRound.disputeKitID != round.disputeKitID) {
            emit DisputeKitJump(_disputeID, dispute.rounds.length - 1, round.disputeKitID, extraRound.disputeKitID);
            disputeKitNodes[extraRound.disputeKitID].disputeKit.createDispute(
                _disputeID,
                _numberOfChoices,
                _extraData,
                extraRound.nbVotes
            );
        }

        emit AppealDecision(_disputeID, dispute.arbitrated);
        emit NewPeriod(_disputeID, Period.evidence);
    }

    /** @dev Distribute tokens and ETH for the specific round of the dispute. Can be called in parts.
     *  @param _disputeID The ID of the dispute.
     *  @param _round The appeal round.
     *  @param _iterations The number of iterations to run.
     */
    function execute(uint256 _disputeID, uint256 _round, uint256 _iterations) external {
        Dispute storage dispute = disputes[_disputeID];
        require(dispute.period == Period.execution, "!Execution period");

        Round storage round = dispute.rounds[_round];
        IDisputeKit disputeKit = disputeKitNodes[round.disputeKitID].disputeKit;

        uint256 end = round.repartitions + _iterations;
        uint256 penaltiesInRoundCache = round.penalties; // For saving gas.
        uint256 numberOfVotesInRound = round.drawnJurors.length;
        uint256 coherentCount = disputeKit.getCoherentCount(_disputeID, _round); // Total number of jurors that are eligible to a reward in this round.

        address account; // Address of the juror.
        uint256 degreeOfCoherence; // [0, 1] value that determines how coherent the juror was in this round, in basis points.

        if (coherentCount == 0) {
            // We loop over the votes once as there are no rewards because it is not a tie and no one in this round is coherent with the final outcome.
            if (end > numberOfVotesInRound) end = numberOfVotesInRound;
        } else {
            // We loop over the votes twice, first to collect penalties, and second to distribute them as rewards along with arbitration fees.
            if (end > numberOfVotesInRound * 2) end = numberOfVotesInRound * 2;
        }

        for (uint256 i = round.repartitions; i < end; i++) {
            if (i < numberOfVotesInRound) {
                // Penalty.
                degreeOfCoherence = disputeKit.getDegreeOfCoherence(_disputeID, _round, i);

                // Make sure the degree doesn't exceed 1, though it should be ensured by the dispute kit.
                if (degreeOfCoherence > ALPHA_DIVISOR) {
                    degreeOfCoherence = ALPHA_DIVISOR;
                }

                // Fully coherent jurors won't be penalized.
                uint256 penalty = (round.tokensAtStakePerJuror * (ALPHA_DIVISOR - degreeOfCoherence)) / ALPHA_DIVISOR;
                penaltiesInRoundCache += penalty;

                account = round.drawnJurors[i];
                jurors[account].lockedTokens[dispute.courtID] -= penalty; // Release this part of locked tokens.

                // Can only update the stake if it is able to cover the minStake and penalty, otherwise unstake from the court.
                if (jurors[account].stakedTokens[dispute.courtID] >= courts[dispute.courtID].minStake + penalty) {
                    uint256 newStake = jurors[account].stakedTokens[dispute.courtID] - penalty;
                    setStakeForAccount(account, dispute.courtID, newStake, penalty);
                } else if (jurors[account].stakedTokens[dispute.courtID] != 0) {
                    setStakeForAccount(account, dispute.courtID, 0, penalty);
                }

                // Unstake the juror if he lost due to inactivity.
                if (!disputeKit.isVoteActive(_disputeID, _round, i)) {
                    uint96[] memory courtIDs = getJurorCourtIDs(account);
                    for (uint256 j = 0; j < courtIDs.length; j++) {
                        setStakeForAccount(account, courtIDs[j], 0, 0);
                    }
                }
                emit TokenAndETHShift(account, _disputeID, -int256(penalty), 0);

                if (i == numberOfVotesInRound - 1) {
                    if (coherentCount == 0) {
                        // No one was coherent. Send the rewards to governor.
                        payable(governor).send(round.totalFeesForJurors);
                        safeTransfer(governor, penaltiesInRoundCache);
                    }
                }
            } else {
                // Reward.
                degreeOfCoherence = disputeKit.getDegreeOfCoherence(_disputeID, _round, i % numberOfVotesInRound);

                // Make sure the degree doesn't exceed 1, though it should be ensured by the dispute kit.
                if (degreeOfCoherence > ALPHA_DIVISOR) {
                    degreeOfCoherence = ALPHA_DIVISOR;
                }

                account = round.drawnJurors[i % numberOfVotesInRound];

                // Release the rest of the tokens of the juror for this round.
                jurors[account].lockedTokens[dispute.courtID] -=
                    (round.tokensAtStakePerJuror * degreeOfCoherence) /
                    ALPHA_DIVISOR;

                // Give back the locked tokens in case the juror fully unstaked earlier.
                if (jurors[account].stakedTokens[dispute.courtID] == 0) {
                    uint256 tokenLocked = (round.tokensAtStakePerJuror * degreeOfCoherence) / ALPHA_DIVISOR;
                    safeTransfer(account, tokenLocked);
                }

                uint256 tokenReward = ((penaltiesInRoundCache / coherentCount) * degreeOfCoherence) / ALPHA_DIVISOR;
                uint256 ethReward = ((round.totalFeesForJurors / coherentCount) * degreeOfCoherence) / ALPHA_DIVISOR;
                safeTransfer(account, tokenReward);
                payable(account).send(ethReward);
                emit TokenAndETHShift(account, _disputeID, int256(tokenReward), int256(ethReward));
            }
        }

        if (round.penalties != penaltiesInRoundCache) {
            round.penalties = penaltiesInRoundCache;
        }
        round.repartitions = end;
    }

    /** @dev Executes a specified dispute's ruling. UNTRUSTED.
     *  @param _disputeID The ID of the dispute.
     */
    function executeRuling(uint256 _disputeID) external {
        Dispute storage dispute = disputes[_disputeID];
        require(dispute.period == Period.execution, "!Execution period");
        require(!dispute.ruled, "Ruling already executed");

        (uint256 winningChoice, , ) = currentRuling(_disputeID);
        dispute.ruled = true;
        emit Ruling(dispute.arbitrated, _disputeID, winningChoice);
        dispute.arbitrated.rule(_disputeID, winningChoice);
    }

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /** @dev Gets the cost of arbitration in a specified court.
     *  @param _extraData Additional info about the dispute. We use it to pass the ID of the court to create the dispute in (first 32 bytes)
     *  and the minimum number of jurors required (next 32 bytes).
     *  @return cost The arbitration cost.
     */
    function arbitrationCost(bytes memory _extraData) public view override returns (uint256 cost) {
        (uint96 courtID, uint256 minJurors, ) = extraDataToCourtIDMinJurorsDisputeKit(_extraData);
        cost = courts[courtID].feeForJuror * minJurors;
    }

    /** @dev Gets the cost of appealing a specified dispute.
     *  @param _disputeID The ID of the dispute.
     *  @return cost The appeal cost.
     */
    function appealCost(uint256 _disputeID) public view returns (uint256 cost) {
        Dispute storage dispute = disputes[_disputeID];
        Round storage round = dispute.rounds[dispute.rounds.length - 1];
        Court storage court = courts[dispute.courtID];
        if (round.nbVotes >= court.jurorsForCourtJump) {
            // Jump to parent court.
            if (dispute.courtID == GENERAL_COURT) {
                // TODO: Handle the forking when appealed in General court.
                cost = NON_PAYABLE_AMOUNT; // Get the cost of the parent court.
            } else {
                cost = courts[court.parent].feeForJuror * ((round.nbVotes * 2) + 1);
            }
        } else {
            // Stay in current court.
            cost = court.feeForJuror * ((round.nbVotes * 2) + 1);
        }
    }

    /** @dev Gets the start and the end of a specified dispute's current appeal period.
     *  @param _disputeID The ID of the dispute.
     *  @return start The start of the appeal period.
     *  @return end The end of the appeal period.
     */
    function appealPeriod(uint256 _disputeID) public view returns (uint256 start, uint256 end) {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.period == Period.appeal) {
            start = dispute.lastPeriodChange;
            end = dispute.lastPeriodChange + courts[dispute.courtID].timesPerPeriod[uint256(Period.appeal)];
        } else {
            start = 0;
            end = 0;
        }
    }

    /** @dev Gets the current ruling of a specified dispute.
     *  @param _disputeID The ID of the dispute.
     *  @return ruling The current ruling.
     *  @return tied Whether it's a tie or not.
     *  @return overridden Whether the ruling was overridden by appeal funding or not.
     */
    function currentRuling(uint256 _disputeID) public view returns (uint256 ruling, bool tied, bool overridden) {
        Dispute storage dispute = disputes[_disputeID];
        Round storage round = dispute.rounds[dispute.rounds.length - 1];
        IDisputeKit disputeKit = disputeKitNodes[round.disputeKitID].disputeKit;
        (ruling, tied, overridden) = disputeKit.currentRuling(_disputeID);
    }

    function getRoundInfo(
        uint256 _disputeID,
        uint256 _round
    )
        external
        view
        returns (
            uint256 tokensAtStakePerJuror,
            uint256 totalFeesForJurors,
            uint256 repartitions,
            uint256 penalties,
            address[] memory drawnJurors,
            uint256 disputeKitID
        )
    {
        Round storage round = disputes[_disputeID].rounds[_round];
        return (
            round.tokensAtStakePerJuror,
            round.totalFeesForJurors,
            round.repartitions,
            round.penalties,
            round.drawnJurors,
            round.disputeKitID
        );
    }

    function getNumberOfRounds(uint256 _disputeID) external view returns (uint256) {
        return disputes[_disputeID].rounds.length;
    }

    function getJurorBalance(address _juror, uint96 _courtID) external view returns (uint256 staked, uint256 locked) {
        staked = jurors[_juror].stakedTokens[_courtID];
        locked = jurors[_juror].lockedTokens[_courtID];
    }

    function isSupported(uint96 _courtID, uint256 _disputeKitID) external view returns (bool) {
        return courts[_courtID].supportedDisputeKits[_disputeKitID];
    }

    /** @dev Gets non-primitive properties of a specified dispute kit node.
     *  @param _disputeKitID The ID of the dispute kit.
     *  @return children Indexes of children of this DK.
     */
    function getDisputeKitChildren(uint256 _disputeKitID) external view returns (uint256[] memory) {
        return disputeKitNodes[_disputeKitID].children;
    }

    /** @dev Gets the timesPerPeriod array for a given court.
     *  @param _courtID The ID of the court to get the times from.
     *  @return timesPerPeriod The timesPerPeriod array for the given court.
     */
    function getTimesPerPeriod(uint96 _courtID) external view returns (uint256[4] memory timesPerPeriod) {
        Court storage court = courts[_courtID];
        timesPerPeriod = court.timesPerPeriod;
    }

    // ************************************* //
    // *   Public Views for Dispute Kits   * //
    // ************************************* //

    function getSortitionSumTreeNode(bytes32 _key, uint256 _index) external view returns (uint256) {
        return sortitionSumTrees.sortitionSumTrees[_key].nodes[_index];
    }

    function getSortitionSumTree(
        bytes32 _key,
        uint256 _nodeIndex
    ) public view returns (uint256 K, uint256 length, bytes32 ID) {
        SortitionSumTreeFactoryV2.SortitionSumTree storage tree = sortitionSumTrees.sortitionSumTrees[_key];
        K = tree.K;
        length = tree.nodes.length;
        ID = tree.nodeIndexesToIDs[_nodeIndex];
    }

    function getNumberOfVotes(uint256 _disputeID) external view returns (uint256) {
        Dispute storage dispute = disputes[_disputeID];
        return dispute.rounds[dispute.rounds.length - 1].nbVotes;
    }

    function freezingPhaseTimeout() external view returns (bool) {
        return phase == Phase.freezing && block.timestamp - lastPhaseChange >= maxFreezingTime;
    }

    /** @dev Returns true if the dispute kit will be switched to a parent DK.
     *  @param _disputeID The ID of the dispute.
     *  @return Whether DK will be switched or not.
     */
    function isDisputeKitJumping(uint256 _disputeID) external view returns (bool) {
        Dispute storage dispute = disputes[_disputeID];
        Round storage round = dispute.rounds[dispute.rounds.length - 1];
        Court storage court = courts[dispute.courtID];

        if (round.nbVotes < court.jurorsForCourtJump) {
            return false;
        }

        // Jump if the parent court doesn't support the current DK.
        return !courts[court.parent].supportedDisputeKits[round.disputeKitID];
    }

    function getDisputesKitIDsThatNeedFreezing() external view returns (uint256[] memory) {
        return disputesKitIDsThatNeedFreezing;
    }

    function getJurorCourtIDs(address _juror) public view returns (uint96[] memory) {
        return jurors[_juror].courtIDs;
    }

    // ************************************* //
    // *            Internal               * //
    // ************************************* //

    function enableDisputeKit(uint96 _courtID, uint256 _disputeKitID, bool _enable) internal {
        courts[_courtID].supportedDisputeKits[_disputeKitID] = _enable;
        emit DisputeKitEnabled(_courtID, _disputeKitID, _enable);
    }

    /** @dev Sets the specified juror's stake in a court.
     *  `O(n + p * log_k(j))` where
     *  `n` is the number of courts the juror has staked in,
     *  `p` is the depth of the court tree,
     *  `k` is the minimum number of children per node of one of these courts' sortition sum tree,
     *  and `j` is the maximum number of jurors that ever staked in one of these courts simultaneously.
     *  @param _account The address of the juror.
     *  @param _courtID The ID of the court.
     *  @param _stake The new stake.
     *  @param _penalty Penalized amount won't be transferred back to juror when the stake is lowered.
     *  @return succeeded True if the call succeeded, false otherwise.
     */
    function setStakeForAccount(
        address _account,
        uint96 _courtID,
        uint256 _stake,
        uint256 _penalty
    ) internal returns (bool succeeded) {
        if (_courtID == FORKING_COURT || _courtID > courts.length) return false;

        Juror storage juror = jurors[_account];
        bytes32 stakePathID = accountAndCourtIDToStakePathID(_account, _courtID);
        uint256 currentStake = sortitionSumTrees.stakeOf(bytes32(uint256(_courtID)), stakePathID);

        if (_stake != 0) {
            // Check against locked tokens in case the min stake was lowered.
            if (_stake < courts[_courtID].minStake || _stake < juror.lockedTokens[_courtID]) return false;
            if (currentStake == 0 && juror.courtIDs.length >= MAX_STAKE_PATHS) return false;
        }

        // Delayed action logic.
        if (phase != Phase.staking) {
            delayedStakes[++delayedStakeWriteIndex] = DelayedStake({
                account: _account,
                courtID: _courtID,
                stake: _stake,
                penalty: _penalty
            });
            return true;
        }

        uint256 transferredAmount;
        if (_stake >= currentStake) {
            transferredAmount = _stake - currentStake;
            if (transferredAmount > 0) {
                if (safeTransferFrom(_account, address(this), transferredAmount)) {
                    if (currentStake == 0) {
                        juror.courtIDs.push(_courtID);
                    }
                } else {
                    return false;
                }
            }
        } else if (_stake == 0) {
            // Keep locked tokens in the contract and release them after dispute is executed.
            transferredAmount = currentStake - juror.lockedTokens[_courtID] - _penalty;
            if (transferredAmount > 0) {
                if (safeTransfer(_account, transferredAmount)) {
                    for (uint256 i = 0; i < juror.courtIDs.length; i++) {
                        if (juror.courtIDs[i] == _courtID) {
                            juror.courtIDs[i] = juror.courtIDs[juror.courtIDs.length - 1];
                            juror.courtIDs.pop();
                            break;
                        }
                    }
                } else {
                    return false;
                }
            }
        } else {
            transferredAmount = currentStake - _stake - _penalty;
            if (transferredAmount > 0) {
                if (!safeTransfer(_account, transferredAmount)) {
                    return false;
                }
            }
        }

        // Update juror's records.
        uint256 newTotalStake = juror.stakedTokens[_courtID] - currentStake + _stake;
        juror.stakedTokens[_courtID] = newTotalStake;

        // Update court parents.
        bool finished = false;
        uint256 currentCourtID = _courtID;
        while (!finished) {
            sortitionSumTrees.set(bytes32(currentCourtID), _stake, stakePathID);
            if (currentCourtID == GENERAL_COURT) finished = true;
            else currentCourtID = courts[currentCourtID].parent;
        }

        emit StakeSet(_account, _courtID, _stake, newTotalStake);

        return true;
    }

    /** @dev Gets a court ID, the minimum number of jurors and an ID of a dispute kit from a specified extra data bytes array.
     *  Note that if extradata contains an incorrect value then this value will be switched to default.
     *  @param _extraData The extra data bytes array. The first 32 bytes are the court ID, the next are the minimum number of jurors and the last are the dispute kit ID.
     *  @return courtID The court ID.
     *  @return minJurors The minimum number of jurors required.
     *  @return disputeKitID The ID of the dispute kit.
     */
    function extraDataToCourtIDMinJurorsDisputeKit(
        bytes memory _extraData
    ) internal view returns (uint96 courtID, uint256 minJurors, uint256 disputeKitID) {
        // Note that if the extradata doesn't contain 32 bytes for the dispute kit ID it'll return the default 0 index.
        if (_extraData.length >= 64) {
            assembly {
                // solium-disable-line security/no-inline-assembly
                courtID := mload(add(_extraData, 0x20))
                minJurors := mload(add(_extraData, 0x40))
                disputeKitID := mload(add(_extraData, 0x60))
            }
            if (courtID == FORKING_COURT || courtID >= courts.length) {
                courtID = GENERAL_COURT;
            }
            if (minJurors == 0) {
                minJurors = MIN_JURORS;
            }
            if (disputeKitID == NULL_DISPUTE_KIT || disputeKitID >= disputeKitNodes.length) {
                disputeKitID = DISPUTE_KIT_CLASSIC; // 0 index is not used.
            }
        } else {
            courtID = GENERAL_COURT;
            minJurors = MIN_JURORS;
            disputeKitID = DISPUTE_KIT_CLASSIC;
        }
    }

    /** @dev Packs an account and a court ID into a stake path ID.
     *  @param _account The address of the juror to pack.
     *  @param _courtID The court ID to pack.
     *  @return stakePathID The stake path ID.
     */
    function accountAndCourtIDToStakePathID(
        address _account,
        uint96 _courtID
    ) internal pure returns (bytes32 stakePathID) {
        assembly {
            // solium-disable-line security/no-inline-assembly
            let ptr := mload(0x40)
            for {
                let i := 0x00
            } lt(i, 0x14) {
                i := add(i, 0x01)
            } {
                mstore8(add(ptr, i), byte(add(0x0c, i), _account))
            }
            for {
                let i := 0x14
            } lt(i, 0x20) {
                i := add(i, 0x01)
            } {
                mstore8(add(ptr, i), byte(i, _courtID))
            }
            stakePathID := mload(ptr)
        }
    }

    /** @dev Calls transfer() without reverting.
     *  @param _to Recepient address.
     *  @param _value Amount transferred.
     *  @return Whether transfer succeeded or not.
     */
    function safeTransfer(address _to, uint256 _value) internal returns (bool) {
        (bool success, bytes memory data) = address(pinakion).call(
            abi.encodeWithSelector(IERC20.transfer.selector, _to, _value)
        );
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    /** @dev Calls transferFrom() without reverting.
     *  @param _from Sender address.
     *  @param _to Recepient address.
     *  @param _value Amount transferred.
     *  @return Whether transfer succeeded or not.
     */
    function safeTransferFrom(address _from, address _to, uint256 _value) internal returns (bool) {
        (bool success, bytes memory data) = address(pinakion).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value)
        );
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@unknownunknown1, @jaybuidl]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8;

import "../IDisputeKit.sol";
import "../KlerosCore.sol";

/**
 *  @title BaseDisputeKit
 *  Provides common basic behaviours to the Dispute Kit implementations.
 */
abstract contract BaseDisputeKit is IDisputeKit {
    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    address public governor; // The governor of the contract.
    KlerosCore public core; // The Kleros Core arbitrator

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    modifier onlyByGovernor() {
        require(governor == msg.sender, "Access not allowed: Governor only.");
        _;
    }

    modifier onlyByCore() {
        require(address(core) == msg.sender, "Access not allowed: KlerosCore only.");
        _;
    }

    /** @dev Constructor.
     *  @param _governor The governor's address.
     *  @param _core The KlerosCore arbitrator.
     */
    constructor(address _governor, KlerosCore _core) {
        governor = _governor;
        core = _core;
    }

    // ************************ //
    // *      Governance      * //
    // ************************ //

    /** @dev Allows the governor to call anything on behalf of the contract.
     *  @param _destination The destination of the call.
     *  @param _amount The value sent with the call.
     *  @param _data The data sent with the call.
     */
    function executeGovernorProposal(
        address _destination,
        uint256 _amount,
        bytes memory _data
    ) external onlyByGovernor {
        (bool success, ) = _destination.call{value: _amount}(_data);
        require(success, "Unsuccessful call");
    }

    /** @dev Checks that the chosen address satisfies certain conditions for being drawn.
     *  @param _coreDisputeID ID of the dispute in the core contract.
     *  @param _juror Chosen address.
     *  @return Whether the address can be drawn or not.
     */
    function postDrawCheck(uint256 _coreDisputeID, address _juror) internal virtual returns (bool);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@unknownunknown1, @jaybuidl]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8;

import "./BaseDisputeKit.sol";
import "../../rng/RNG.sol";
import "../../evidence/IEvidence.sol";

/**
 *  @title DisputeKitClassic
 *  Dispute kit implementation of the Kleros v1 features including:
 *  - a drawing system: proportional to staked PNK,
 *  - a vote aggreation system: plurality,
 *  - an incentive system: equal split between coherent votes,
 *  - an appeal system: fund 2 choices only, vote on any choice.
 */
contract DisputeKitClassic is BaseDisputeKit, IEvidence {
    // ************************************* //
    // *             Structs               * //
    // ************************************* //

    enum Phase {
        resolving, // No disputes that need drawing.
        generating, // Waiting for a random number. Pass as soon as it is ready.
        drawing // Jurors can be drawn.
    }

    struct Dispute {
        Round[] rounds; // Rounds of the dispute. 0 is the default round, and [1, ..n] are the appeal rounds.
        uint256 numberOfChoices; // The number of choices jurors have when voting. This does not include choice `0` which is reserved for "refuse to arbitrate".
        bool jumped; // True if dispute jumped to a parent dispute kit and won't be handled by this DK anymore.
        mapping(uint256 => uint256) coreRoundIDToLocal; // Maps id of the round in the core contract to the index of the round of related local dispute.
        bytes extraData; // Extradata for the dispute.
    }

    struct Round {
        Vote[] votes; // Former votes[_appeal][].
        uint256 winningChoice; // The choice with the most votes. Note that in the case of a tie, it is the choice that reached the tied number of votes first.
        mapping(uint256 => uint256) counts; // The sum of votes for each choice in the form `counts[choice]`.
        bool tied; // True if there is a tie, false otherwise.
        uint256 totalVoted; // Former uint[_appeal] votesInEachRound.
        uint256 totalCommitted; // Former commitsInRound.
        mapping(uint256 => uint256) paidFees; // Tracks the fees paid for each choice in this round.
        mapping(uint256 => bool) hasPaid; // True if this choice was fully funded, false otherwise.
        mapping(address => mapping(uint256 => uint256)) contributions; // Maps contributors to their contributions for each choice.
        uint256 feeRewards; // Sum of reimbursable appeal fees available to the parties that made contributions to the ruling that ultimately wins a dispute.
        uint256[] fundedChoices; // Stores the choices that are fully funded.
        uint256 nbVotes; // Maximal number of votes this dispute can get.
    }

    struct Vote {
        address account; // The address of the juror.
        bytes32 commit; // The commit of the juror. For courts with hidden votes.
        uint256 choice; // The choice of the juror.
        bool voted; // True if the vote has been cast.
    }

    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    uint256 public constant WINNER_STAKE_MULTIPLIER = 10000; // Multiplier of the appeal cost that the winner has to pay as fee stake for a round in basis points. Default is 1x of appeal fee.
    uint256 public constant LOSER_STAKE_MULTIPLIER = 20000; // Multiplier of the appeal cost that the loser has to pay as fee stake for a round in basis points. Default is 2x of appeal fee.
    uint256 public constant LOSER_APPEAL_PERIOD_MULTIPLIER = 5000; // Multiplier of the appeal period for the choice that wasn't voted for in the previous round, in basis points. Default is 1/2 of original appeal period.
    uint256 public constant ONE_BASIS_POINT = 10000; // One basis point, for scaling.

    RNG public rng; // The random number generator
    uint256 public rngRequestedBlock; // The block number requested to the random number.
    uint256 public rngLookahead; // Minimum block distance between requesting and obtaining a random number.
    uint256 public randomNumber; // The current random number.
    Phase public phase; // Current phase of this dispute kit.
    uint256 public disputesWithoutJurors; // The number of disputes that have not finished drawing jurors.
    Dispute[] public disputes; // Array of the locally created disputes.
    mapping(uint256 => uint256) public coreDisputeIDToLocal; // Maps the dispute ID in Kleros Core to the local dispute ID.

    // ************************************* //
    // *              Events               * //
    // ************************************* //

    event DisputeCreation(uint256 indexed _coreDisputeID, uint256 _numberOfChoices, bytes _extraData);

    event CommitCast(uint256 indexed _coreDisputeID, uint256[] _voteIDs, bytes32 _commit);

    event Contribution(
        uint256 indexed _coreDisputeID,
        uint256 indexed _coreRoundID,
        uint256 _choice,
        address indexed _contributor,
        uint256 _amount
    );

    event Withdrawal(
        uint256 indexed _coreDisputeID,
        uint256 indexed _coreRoundID,
        uint256 _choice,
        address indexed _contributor,
        uint256 _amount
    );

    event ChoiceFunded(uint256 indexed _coreDisputeID, uint256 indexed _coreRoundID, uint256 indexed _choice);
    event NewPhaseDisputeKit(Phase _phase);

    // ************************************* //
    // *              Modifiers            * //
    // ************************************* //

    modifier notJumped(uint256 _coreDisputeID) {
        require(!disputes[coreDisputeIDToLocal[_coreDisputeID]].jumped, "Dispute jumped to a parent DK!");
        _;
    }

    /** @dev Constructor.
     *  @param _governor The governor's address.
     *  @param _core The KlerosCore arbitrator.
     *  @param _rng The random number generator.
     *  @param _rngLookahead Lookahead value for rng.
     */
    constructor(address _governor, KlerosCore _core, RNG _rng, uint256 _rngLookahead) BaseDisputeKit(_governor, _core) {
        rng = _rng;
        rngLookahead = _rngLookahead;
    }

    // ************************ //
    // *      Governance      * //
    // ************************ //

    /** @dev Changes the `governor` storage variable.
     *  @param _governor The new value for the `governor` storage variable.
     */
    function changeGovernor(address payable _governor) external onlyByGovernor {
        governor = _governor;
    }

    /** @dev Changes the `core` storage variable.
     *  @param _core The new value for the `core` storage variable.
     */
    function changeCore(address _core) external onlyByGovernor {
        core = KlerosCore(_core);
    }

    /** @dev Changes the `_rng` storage variable.
     *  @param _rng The new value for the `RNGenerator` storage variable.
     *  @param _rngLookahead The new value for the `rngLookahead` storage variable.
     */
    function changeRandomNumberGenerator(RNG _rng, uint256 _rngLookahead) external onlyByGovernor {
        rng = _rng;
        rngLookahead = _rngLookahead;
        if (phase == Phase.generating) {
            rngRequestedBlock = block.number + rngLookahead;
            rng.requestRandomness(rngRequestedBlock);
        }
    }

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /** @dev Creates a local dispute and maps it to the dispute ID in the Core contract.
     *  Note: Access restricted to Kleros Core only.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core.
     *  @param _numberOfChoices Number of choices of the dispute
     *  @param _extraData Additional info about the dispute, for possible use in future dispute kits.
     *  @param _nbVotes Number of votes for this dispute.
     */
    function createDispute(
        uint256 _coreDisputeID,
        uint256 _numberOfChoices,
        bytes calldata _extraData,
        uint256 _nbVotes
    ) external override onlyByCore {
        uint256 localDisputeID = disputes.length;
        Dispute storage dispute = disputes.push();
        dispute.numberOfChoices = _numberOfChoices;
        dispute.extraData = _extraData;

        // New round in the Core should be created before the dispute creation in DK.
        dispute.coreRoundIDToLocal[core.getNumberOfRounds(_coreDisputeID) - 1] = dispute.rounds.length;

        Round storage round = dispute.rounds.push();
        round.nbVotes = _nbVotes;
        round.tied = true;

        coreDisputeIDToLocal[_coreDisputeID] = localDisputeID;
        disputesWithoutJurors++;
        emit DisputeCreation(_coreDisputeID, _numberOfChoices, _extraData);
    }

    /** @dev Passes the phase.
     */
    function passPhase() external override {
        if (core.phase() == KlerosCore.Phase.staking || core.freezingPhaseTimeout()) {
            require(phase != Phase.resolving, "Already in Resolving phase");
            phase = Phase.resolving; // Safety net.
        } else if (core.phase() == KlerosCore.Phase.freezing) {
            if (phase == Phase.resolving) {
                require(disputesWithoutJurors > 0, "All the disputes have jurors");
                rngRequestedBlock = core.freezeBlock() + rngLookahead;
                rng.requestRandomness(rngRequestedBlock);
                phase = Phase.generating;
            } else if (phase == Phase.generating) {
                randomNumber = rng.receiveRandomness(rngRequestedBlock);
                require(randomNumber != 0, "Random number is not ready yet");
                phase = Phase.drawing;
            } else if (phase == Phase.drawing) {
                require(disputesWithoutJurors == 0, "Not ready for Resolving phase");
                phase = Phase.resolving;
            }
        }
        // Should not be reached if the phase is unchanged.
        emit NewPhaseDisputeKit(phase);
    }

    /** @dev Draws the juror from the sortition tree. The drawn address is picked up by Kleros Core.
     *  Note: Access restricted to Kleros Core only.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core.
     *  @return drawnAddress The drawn address.
     */
    function draw(
        uint256 _coreDisputeID
    ) external override onlyByCore notJumped(_coreDisputeID) returns (address drawnAddress) {
        require(phase == Phase.drawing, "Should be in drawing phase");

        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        Round storage round = dispute.rounds[dispute.rounds.length - 1];

        (uint96 courtID, , , , ) = core.disputes(_coreDisputeID);
        bytes32 key = bytes32(uint256(courtID)); // Get the ID of the tree.

        (uint256 K, uint256 nodesLength, ) = core.getSortitionSumTree(key, 0);
        uint256 treeIndex = 0;
        uint256 currentDrawnNumber = uint256(
            keccak256(abi.encodePacked(randomNumber, _coreDisputeID, round.votes.length))
        );
        currentDrawnNumber %= core.getSortitionSumTreeNode(key, 0);

        // TODO: Handle the situation when no one has staked yet.

        // While it still has children
        while ((K * treeIndex) + 1 < nodesLength) {
            for (uint256 i = 1; i <= K; i++) {
                // Loop over children.
                uint256 nodeIndex = (K * treeIndex) + i;
                uint256 nodeValue = core.getSortitionSumTreeNode(key, nodeIndex);

                if (currentDrawnNumber >= nodeValue) {
                    // Go to the next child.
                    currentDrawnNumber -= nodeValue;
                } else {
                    // Pick this child.
                    treeIndex = nodeIndex;
                    break;
                }
            }
        }

        (, , bytes32 ID) = core.getSortitionSumTree(key, treeIndex);
        drawnAddress = stakePathIDToAccount(ID);

        if (postDrawCheck(_coreDisputeID, drawnAddress)) {
            round.votes.push(Vote({account: drawnAddress, commit: bytes32(0), choice: 0, voted: false}));
            if (round.votes.length == round.nbVotes) {
                disputesWithoutJurors--;
            }
        } else {
            drawnAddress = address(0);
        }
    }

    /** @dev Sets the caller's commit for the specified votes. It can be called multiple times during the
     *  commit period, each call overrides the commits of the previous one.
     *  `O(n)` where
     *  `n` is the number of votes.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core.
     *  @param _voteIDs The IDs of the votes.
     *  @param _commit The commit. Note that justification string is a part of the commit.
     */
    function castCommit(
        uint256 _coreDisputeID,
        uint256[] calldata _voteIDs,
        bytes32 _commit
    ) external notJumped(_coreDisputeID) {
        (, , KlerosCore.Period period, , ) = core.disputes(_coreDisputeID);
        require(period == KlerosCore.Period.commit, "The dispute should be in Commit period.");
        require(_commit != bytes32(0), "Empty commit.");

        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        Round storage round = dispute.rounds[dispute.rounds.length - 1];
        for (uint256 i = 0; i < _voteIDs.length; i++) {
            require(round.votes[_voteIDs[i]].account == msg.sender, "The caller has to own the vote.");
            round.votes[_voteIDs[i]].commit = _commit;
        }
        round.totalCommitted += _voteIDs.length;
        emit CommitCast(_coreDisputeID, _voteIDs, _commit);
    }

    /** @dev Sets the caller's choices for the specified votes.
     *  `O(n)` where
     *  `n` is the number of votes.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core.
     *  @param _voteIDs The IDs of the votes.
     *  @param _choice The choice.
     *  @param _salt The salt for the commit if the votes were hidden.
     *  @param _justification Justification of the choice.
     */
    function castVote(
        uint256 _coreDisputeID,
        uint256[] calldata _voteIDs,
        uint256 _choice,
        uint256 _salt,
        string memory _justification
    ) external notJumped(_coreDisputeID) {
        (, , KlerosCore.Period period, , ) = core.disputes(_coreDisputeID);
        require(period == KlerosCore.Period.vote, "The dispute should be in Vote period.");
        require(_voteIDs.length > 0, "No voteID provided");

        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        require(_choice <= dispute.numberOfChoices, "Choice out of bounds");

        Round storage round = dispute.rounds[dispute.rounds.length - 1];
        (uint96 courtID, , , , ) = core.disputes(_coreDisputeID);
        (, bool hiddenVotes, , , , ) = core.courts(courtID);

        //  Save the votes.
        for (uint256 i = 0; i < _voteIDs.length; i++) {
            require(round.votes[_voteIDs[i]].account == msg.sender, "The caller has to own the vote.");
            require(
                !hiddenVotes ||
                    round.votes[_voteIDs[i]].commit == keccak256(abi.encodePacked(_choice, _justification, _salt)),
                "The commit must match the choice in courts with hidden votes."
            );
            require(!round.votes[_voteIDs[i]].voted, "Vote already cast.");
            round.votes[_voteIDs[i]].choice = _choice;
            round.votes[_voteIDs[i]].voted = true;
        }

        round.totalVoted += _voteIDs.length;

        round.counts[_choice] += _voteIDs.length;
        if (_choice == round.winningChoice) {
            if (round.tied) round.tied = false;
        } else {
            // Voted for another choice.
            if (round.counts[_choice] == round.counts[round.winningChoice]) {
                // Tie.
                if (!round.tied) round.tied = true;
            } else if (round.counts[_choice] > round.counts[round.winningChoice]) {
                // New winner.
                round.winningChoice = _choice;
                round.tied = false;
            }
        }
        emit Justification(_coreDisputeID, msg.sender, _choice, _justification);
    }

    /** @dev Manages contributions, and appeals a dispute if at least two choices are fully funded.
     *  Note that the surplus deposit will be reimbursed.
     *  @param _coreDisputeID Index of the dispute in Kleros Core.
     *  @param _choice A choice that receives funding.
     */
    function fundAppeal(uint256 _coreDisputeID, uint256 _choice) external payable notJumped(_coreDisputeID) {
        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        require(_choice <= dispute.numberOfChoices, "There is no such ruling to fund.");

        (uint256 appealPeriodStart, uint256 appealPeriodEnd) = core.appealPeriod(_coreDisputeID);
        require(block.timestamp >= appealPeriodStart && block.timestamp < appealPeriodEnd, "Appeal period is over.");

        uint256 multiplier;
        (uint256 ruling, , ) = this.currentRuling(_coreDisputeID);
        if (ruling == _choice) {
            multiplier = WINNER_STAKE_MULTIPLIER;
        } else {
            require(
                block.timestamp - appealPeriodStart <
                    ((appealPeriodEnd - appealPeriodStart) * LOSER_APPEAL_PERIOD_MULTIPLIER) / ONE_BASIS_POINT,
                "Appeal period is over for loser"
            );
            multiplier = LOSER_STAKE_MULTIPLIER;
        }

        Round storage round = dispute.rounds[dispute.rounds.length - 1];
        uint256 coreRoundID = core.getNumberOfRounds(_coreDisputeID) - 1;

        require(!round.hasPaid[_choice], "Appeal fee is already paid.");
        uint256 appealCost = core.appealCost(_coreDisputeID);
        uint256 totalCost = appealCost + (appealCost * multiplier) / ONE_BASIS_POINT;

        // Take up to the amount necessary to fund the current round at the current costs.
        uint256 contribution;
        if (totalCost > round.paidFees[_choice]) {
            contribution = totalCost - round.paidFees[_choice] > msg.value // Overflows and underflows will be managed on the compiler level.
                ? msg.value
                : totalCost - round.paidFees[_choice];
            emit Contribution(_coreDisputeID, coreRoundID, _choice, msg.sender, contribution);
        }

        round.contributions[msg.sender][_choice] += contribution;
        round.paidFees[_choice] += contribution;
        if (round.paidFees[_choice] >= totalCost) {
            round.feeRewards += round.paidFees[_choice];
            round.fundedChoices.push(_choice);
            round.hasPaid[_choice] = true;
            emit ChoiceFunded(_coreDisputeID, coreRoundID, _choice);
        }

        if (round.fundedChoices.length > 1) {
            // At least two sides are fully funded.
            round.feeRewards = round.feeRewards - appealCost;

            if (core.isDisputeKitJumping(_coreDisputeID)) {
                // Don't create a new round in case of a jump, and remove local dispute from the flow.
                dispute.jumped = true;
            } else {
                // Don't subtract 1 from length since both round arrays haven't been updated yet.
                dispute.coreRoundIDToLocal[coreRoundID + 1] = dispute.rounds.length;

                Round storage newRound = dispute.rounds.push();
                newRound.nbVotes = core.getNumberOfVotes(_coreDisputeID);
                newRound.tied = true;
                disputesWithoutJurors++;
            }
            core.appeal{value: appealCost}(_coreDisputeID, dispute.numberOfChoices, dispute.extraData);
        }

        if (msg.value > contribution) payable(msg.sender).send(msg.value - contribution);
    }

    /** @dev Allows those contributors who attempted to fund an appeal round to withdraw any reimbursable fees or rewards after the dispute gets resolved.
     *  @param _coreDisputeID Index of the dispute in Kleros Core contract.
     *  @param _beneficiary The address whose rewards to withdraw.
     *  @param _coreRoundID The round in the Kleros Core contract the caller wants to withdraw from.
     *  @param _choice The ruling option that the caller wants to withdraw from.
     *  @return amount The withdrawn amount.
     */
    function withdrawFeesAndRewards(
        uint256 _coreDisputeID,
        address payable _beneficiary,
        uint256 _coreRoundID,
        uint256 _choice
    ) external returns (uint256 amount) {
        (, , , bool isRuled, ) = core.disputes(_coreDisputeID);
        require(isRuled, "Dispute should be resolved.");

        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        Round storage round = dispute.rounds[dispute.coreRoundIDToLocal[_coreRoundID]];
        (uint256 finalRuling, , ) = core.currentRuling(_coreDisputeID);

        if (!round.hasPaid[_choice]) {
            // Allow to reimburse if funding was unsuccessful for this ruling option.
            amount = round.contributions[_beneficiary][_choice];
        } else {
            // Funding was successful for this ruling option.
            if (_choice == finalRuling) {
                // This ruling option is the ultimate winner.
                amount = round.paidFees[_choice] > 0
                    ? (round.contributions[_beneficiary][_choice] * round.feeRewards) / round.paidFees[_choice]
                    : 0;
            } else if (!round.hasPaid[finalRuling]) {
                // The ultimate winner was not funded in this round. In this case funded ruling option(s) are reimbursed.
                amount =
                    (round.contributions[_beneficiary][_choice] * round.feeRewards) /
                    (round.paidFees[round.fundedChoices[0]] + round.paidFees[round.fundedChoices[1]]);
            }
        }
        round.contributions[_beneficiary][_choice] = 0;

        if (amount != 0) {
            _beneficiary.send(amount); // Deliberate use of send to prevent reverting fallback. It's the user's responsibility to accept ETH.
            emit Withdrawal(_coreDisputeID, _coreRoundID, _choice, _beneficiary, amount);
        }
    }

    /** @dev Submits evidence.
     *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to. It's the submitter responsability to submit the right evidence group ID.
     *  @param _evidence IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'.
     */
    function submitEvidence(uint256 _evidenceGroupID, string calldata _evidence) external {
        emit Evidence(_evidenceGroupID, msg.sender, _evidence);
    }

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    function getFundedChoices(uint256 _coreDisputeID) public view returns (uint256[] memory fundedChoices) {
        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        Round storage lastRound = dispute.rounds[dispute.rounds.length - 1];
        return lastRound.fundedChoices;
    }

    /** @dev Gets the current ruling of a specified dispute.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core.
     *  @return ruling The current ruling.
     *  @return tied Whether it's a tie or not.
     *  @return overridden Whether the ruling was overridden by appeal funding or not.
     */
    function currentRuling(
        uint256 _coreDisputeID
    ) external view override returns (uint256 ruling, bool tied, bool overridden) {
        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        Round storage round = dispute.rounds[dispute.rounds.length - 1];
        tied = round.tied;
        ruling = tied ? 0 : round.winningChoice;
        (, , KlerosCore.Period period, , ) = core.disputes(_coreDisputeID);
        // Override the final ruling if only one side funded the appeals.
        if (period == KlerosCore.Period.execution) {
            uint256[] memory fundedChoices = getFundedChoices(_coreDisputeID);
            if (fundedChoices.length == 1) {
                ruling = fundedChoices[0];
                tied = false;
                overridden = true;
            }
        }
    }

    /** @dev Gets the degree of coherence of a particular voter. This function is called by Kleros Core in order to determine the amount of the reward.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
     *  @param _coreRoundID The ID of the round in Kleros Core, not in the Dispute Kit.
     *  @param _voteID The ID of the vote.
     *  @return The degree of coherence in basis points.
     */
    function getDegreeOfCoherence(
        uint256 _coreDisputeID,
        uint256 _coreRoundID,
        uint256 _voteID
    ) external view override returns (uint256) {
        // In this contract this degree can be either 0 or 1, but in other dispute kits this value can be something in between.
        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        Vote storage vote = dispute.rounds[dispute.coreRoundIDToLocal[_coreRoundID]].votes[_voteID];
        (uint256 winningChoice, bool tied, ) = core.currentRuling(_coreDisputeID);

        if (vote.voted && (vote.choice == winningChoice || tied)) {
            return ONE_BASIS_POINT;
        } else {
            return 0;
        }
    }

    /** @dev Gets the number of jurors who are eligible to a reward in this round.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
     *  @param _coreRoundID The ID of the round in Kleros Core, not in the Dispute Kit.
     *  @return The number of coherent jurors.
     */
    function getCoherentCount(uint256 _coreDisputeID, uint256 _coreRoundID) external view override returns (uint256) {
        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        Round storage currentRound = dispute.rounds[dispute.coreRoundIDToLocal[_coreRoundID]];
        (uint256 winningChoice, bool tied, ) = core.currentRuling(_coreDisputeID);

        if (currentRound.totalVoted == 0 || (!tied && currentRound.counts[winningChoice] == 0)) {
            return 0;
        } else if (tied) {
            return currentRound.totalVoted;
        } else {
            return currentRound.counts[winningChoice];
        }
    }

    /** @dev Returns true if all of the jurors have cast their commits for the last round.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core.
     *  @return Whether all of the jurors have cast their commits for the last round.
     */
    function areCommitsAllCast(uint256 _coreDisputeID) external view override returns (bool) {
        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        Round storage round = dispute.rounds[dispute.rounds.length - 1];
        return round.totalCommitted == round.votes.length;
    }

    /** @dev Returns true if all of the jurors have cast their votes for the last round.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core.
     *  @return Whether all of the jurors have cast their votes for the last round.
     */
    function areVotesAllCast(uint256 _coreDisputeID) external view override returns (bool) {
        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        Round storage round = dispute.rounds[dispute.rounds.length - 1];
        return round.totalVoted == round.votes.length;
    }

    /** @dev Returns true if the specified voter was active in this round.
     *  @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
     *  @param _coreRoundID The ID of the round in Kleros Core, not in the Dispute Kit.
     *  @param _voteID The ID of the voter.
     *  @return Whether the voter was active or not.
     */
    function isVoteActive(
        uint256 _coreDisputeID,
        uint256 _coreRoundID,
        uint256 _voteID
    ) external view override returns (bool) {
        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        Vote storage vote = dispute.rounds[dispute.coreRoundIDToLocal[_coreRoundID]].votes[_voteID];
        return vote.voted;
    }

    function getRoundInfo(
        uint256 _coreDisputeID,
        uint256 _coreRoundID,
        uint256 _choice
    )
        external
        view
        override
        returns (
            uint256 winningChoice,
            bool tied,
            uint256 totalVoted,
            uint256 totalCommited,
            uint256 nbVoters,
            uint256 choiceCount
        )
    {
        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        Round storage round = dispute.rounds[dispute.coreRoundIDToLocal[_coreRoundID]];
        return (
            round.winningChoice,
            round.tied,
            round.totalVoted,
            round.totalCommitted,
            round.votes.length,
            round.counts[_choice]
        );
    }

    function getVoteInfo(
        uint256 _coreDisputeID,
        uint256 _coreRoundID,
        uint256 _voteID
    ) external view override returns (address account, bytes32 commit, uint256 choice, bool voted) {
        Dispute storage dispute = disputes[coreDisputeIDToLocal[_coreDisputeID]];
        Vote storage vote = dispute.rounds[dispute.coreRoundIDToLocal[_coreRoundID]].votes[_voteID];
        return (vote.account, vote.commit, vote.choice, vote.voted);
    }

    function isResolving() external view override returns (bool) {
        return phase == Phase.resolving;
    }

    // ************************************* //
    // *            Internal               * //
    // ************************************* //

    /** @dev Checks that the chosen address satisfies certain conditions for being drawn.
     *  @param _coreDisputeID ID of the dispute in the core contract.
     *  @param _juror Chosen address.
     *  @return Whether the address can be drawn or not.
     */
    function postDrawCheck(uint256 _coreDisputeID, address _juror) internal view override returns (bool) {
        (uint96 courtID, , , , ) = core.disputes(_coreDisputeID);
        (uint256 lockedAmountPerJuror, , , , , ) = core.getRoundInfo(
            _coreDisputeID,
            core.getNumberOfRounds(_coreDisputeID) - 1
        );
        (uint256 stakedTokens, uint256 lockedTokens) = core.getJurorBalance(_juror, courtID);
        (, , uint256 minStake, , , ) = core.courts(courtID);
        return stakedTokens >= lockedTokens + lockedAmountPerJuror && stakedTokens >= minStake;
    }

    /** @dev Retrieves a juror's address from the stake path ID.
     *  @param _stakePathID The stake path ID to unpack.
     *  @return account The account.
     */
    function stakePathIDToAccount(bytes32 _stakePathID) internal pure returns (address account) {
        assembly {
            // solium-disable-line security/no-inline-assembly
            let ptr := mload(0x40)
            for {
                let i := 0x00
            } lt(i, 0x14) {
                i := add(i, 0x01)
            } {
                mstore8(add(add(ptr, 0x0c), i), byte(i, _stakePathID))
            }
            account := mload(ptr)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../arbitration/IArbitrator.sol";

/** @title IEvidence
 */
interface IEvidence {
    /**
     * @dev To be raised when evidence is submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     * @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     * @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     * @param _evidence IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
     */
    event Evidence(uint256 indexed _evidenceGroupID, address indexed _party, string _evidence);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@epiqueras, @unknownunknown1]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8;

/**
 *  @title SortitionSumTreeFactoryV2
 *  @dev A factory of trees that keeps track of staked values for sortition. This is the updated version for 0.8 compiler.
 */
library SortitionSumTreeFactoryV2 {
    /* Structs */

    struct SortitionSumTree {
        uint256 K; // The maximum number of childs per node.
        // We use this to keep track of vacant positions in the tree after removing a leaf. This is for keeping the tree as balanced as possible without spending gas on moving nodes around.
        uint256[] stack;
        uint256[] nodes;
        // Two-way mapping of IDs to node indexes. Note that node index 0 is reserved for the root node, and means the ID does not have a node.
        mapping(bytes32 => uint256) IDsToNodeIndexes;
        mapping(uint256 => bytes32) nodeIndexesToIDs;
    }

    /* Storage */

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

    /* Public */

    /**
     *  @dev Create a sortition sum tree at the specified key.
     *  @param _key The key of the new tree.
     *  @param _K The number of children each node in the tree should have.
     */
    function createTree(SortitionSumTrees storage self, bytes32 _key, uint256 _K) external {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(tree.K == 0, "Tree already exists.");
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.nodes.push(0);
    }

    /**
     *  @dev Set a value of a tree.
     *  @param _key The key of the tree.
     *  @param _value The new value.
     *  @param _ID The ID of the value.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function set(SortitionSumTrees storage self, bytes32 _key, uint256 _value, bytes32 _ID) external {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint256 treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) {
            // No existing node.
            if (_value != 0) {
                // Non zero value.
                // Append.
                // Add node.
                if (tree.stack.length == 0) {
                    // No vacant spots.
                    // Get the index and append the value.
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                    // Potentially append a new node and make the parent a sum node.
                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) {
                        // Is first child.
                        uint256 parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint256 newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else {
                    // Some vacant spot.
                    // Pop the stack and append the value.
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.pop();
                    tree.nodes[treeIndex] = _value;
                }

                // Add label.
                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else {
            // Existing node.
            if (_value == 0) {
                // Zero value.
                // Remove.
                // Remember value and set to 0.
                uint256 value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                // Push to stack.
                tree.stack.push(treeIndex);

                // Clear label.
                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) {
                // New, non zero value.
                // Set.
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint256 plusOrMinusValue = plusOrMinus
                    ? _value - tree.nodes[treeIndex]
                    : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

    /* Public Views */

    /**
     *  @dev Query the leaves of a tree. Note that if `startIndex == 0`, the tree is empty and the root node will be returned.
     *  @param _key The key of the tree to get the leaves from.
     *  @param _cursor The pagination cursor.
     *  @param _count The number of items to return.
     *  @return startIndex The index at which leaves start.
     *  @return values The values of the returned leaves.
     *  @return hasMore Whether there are more for pagination.
     *  `O(n)` where
     *  `n` is the maximum number of nodes ever appended.
     */
    function queryLeafs(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint256 _cursor,
        uint256 _count
    ) external view returns (uint256 startIndex, uint256[] memory values, bool hasMore) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        // Find the start index.
        for (uint256 i = 0; i < tree.nodes.length; i++) {
            if ((tree.K * i) + 1 >= tree.nodes.length) {
                startIndex = i;
                break;
            }
        }

        // Get the values.
        uint256 loopStartIndex = startIndex + _cursor;
        values = new uint256[](
            loopStartIndex + _count > tree.nodes.length ? tree.nodes.length - loopStartIndex : _count
        );
        uint256 valuesIndex = 0;
        for (uint256 j = loopStartIndex; j < tree.nodes.length; j++) {
            if (valuesIndex < _count) {
                values[valuesIndex] = tree.nodes[j];
                valuesIndex++;
            } else {
                hasMore = true;
                break;
            }
        }
    }

    /** @dev Gets a specified ID's associated value.
     *  @param _key The key of the tree.
     *  @param _ID The ID of the value.
     *  @return value The associated value.
     */
    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) external view returns (uint256 value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint256 treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

    /* Private */

    /**
     *  @dev Update all the parents of a node.
     *  @param _key The key of the tree to update.
     *  @param _treeIndex The index of the node to start from.
     *  @param _plusOrMinus Whether to add (true) or substract (false).
     *  @param _value The value to add or substract.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function updateParents(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint256 _treeIndex,
        bool _plusOrMinus,
        uint256 _value
    ) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint256 parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus
                ? tree.nodes[parentIndex] + _value
                : tree.nodes[parentIndex] - _value;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface RNG {
    /**
     * @dev Request a random number.
     * @param _block Block linked to the request.
     */
    function requestRandomness(uint256 _block) external;

    /**
     * @dev Receive the random number.
     * @param _block Block the random number is linked to.
     * @return randomNumber Random Number. If the number is not ready or has not been required 0 instead.
     */
    function receiveRandomness(uint256 _block) external returns (uint256 randomNumber);
}