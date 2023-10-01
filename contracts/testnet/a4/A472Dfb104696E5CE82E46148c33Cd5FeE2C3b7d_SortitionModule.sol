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

/// @custom:authors: [@unknownunknown1, @jaybuidl]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

import {IArbitrableV2, IArbitratorV2} from "./interfaces/IArbitratorV2.sol";
import "./interfaces/IDisputeKit.sol";
import "./interfaces/ISortitionModule.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/Constants.sol";
import "../proxy/UUPSProxiable.sol";
import "../proxy/Initializable.sol";

/// @title KlerosCore
/// Core arbitrator contract for Kleros v2.
/// Note that this contract trusts the PNK token, the dispute kit and the sortition module contracts.
contract KlerosCore is IArbitratorV2, UUPSProxiable, Initializable {
    using SafeERC20 for IERC20;

    // ************************************* //
    // *         Enums / Structs           * //
    // ************************************* //

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
        uint256 minStake; // Minimum PNKs needed to stake in the court.
        uint256 alpha; // Basis point of PNKs that are lost when incoherent.
        uint256 feeForJuror; // Arbitration fee paid per juror.
        uint256 jurorsForCourtJump; // The appeal after the one that reaches this number of jurors will go to the parent court if any.
        uint256[4] timesPerPeriod; // The time allotted to each dispute period in the form `timesPerPeriod[period]`.
        mapping(uint256 => bool) supportedDisputeKits; // True if DK with this ID is supported by the court.
        bool disabled; // True if the court is disabled. Unused for now, will be implemented later.
    }

    struct Dispute {
        uint96 courtID; // The ID of the court the dispute is in.
        IArbitrableV2 arbitrated; // The arbitrable contract.
        Period period; // The current period of the dispute.
        bool ruled; // True if the ruling has been executed, false otherwise.
        uint256 lastPeriodChange; // The last time the period was changed.
        Round[] rounds;
    }

    struct Round {
        uint256 disputeKitID; // Index of the dispute kit in the array.
        uint256 pnkAtStakePerJuror; // The amount of PNKs at stake for each juror in this round.
        uint256 totalFeesForJurors; // The total juror fees paid in this round.
        uint256 nbVotes; // The total number of votes the dispute can possibly have in the current round. Former votes[_round].length.
        uint256 repartitions; // A counter of reward repartitions made in this round.
        uint256 pnkPenalties; // The amount of PNKs collected from penalties in this round.
        address[] drawnJurors; // Addresses of the jurors that were drawn in this round.
        uint256 sumFeeRewardPaid; // Total sum of arbitration fees paid to coherent jurors as a reward in this round.
        uint256 sumPnkRewardPaid; // Total sum of PNK paid to coherent jurors as a reward in this round.
        IERC20 feeToken; // The token used for paying fees in this round.
        uint256 drawIterations; // The number of iterations passed drawing the jurors for this round.
    }

    struct Juror {
        uint96[] courtIDs; // The IDs of courts where the juror's stake path ends. A stake path is a path from the general court to a court the juror directly staked in using `_setStake`.
        uint256 stakedPnk; // The juror's total amount of tokens staked in subcourts. Reflects actual pnk balance.
        uint256 lockedPnk; // The juror's total amount of tokens locked in disputes. Can reflect actual pnk balance when stakedPnk are fully withdrawn.
        mapping(uint96 => uint256) stakedPnkByCourt; // The amount of PNKs the juror has staked in the court in the form `stakedPnkByCourt[courtID]`.
    }

    struct DisputeKitNode {
        uint256 parent; // Index of the parent dispute kit. If it's 0 then this DK is a root.
        uint256[] children; // List of child dispute kits.
        IDisputeKit disputeKit; // The dispute kit implementation.
        uint256 depthLevel; // How far this DK is from the root. 0 for root DK.
        bool disabled; // True if the dispute kit is disabled and can't be used. This parameter is added preemptively to avoid storage changes in the future.
    }

    // Workaround "stack too deep" errors
    struct ExecuteParams {
        uint256 disputeID; // The ID of the dispute to execute.
        uint256 round; // The round to execute.
        uint256 coherentCount; // The number of coherent votes in the round.
        uint256 numberOfVotesInRound; // The number of votes in the round.
        uint256 pnkPenaltiesInRound; // The amount of PNKs collected from penalties in the round.
        uint256 repartition; // The index of the repartition to execute.
    }

    struct CurrencyRate {
        bool feePaymentAccepted;
        uint64 rateInEth;
        uint8 rateDecimals;
    }

    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    uint256 private constant ALPHA_DIVISOR = 1e4; // The number to divide `Court.alpha` by.
    uint256 private constant NON_PAYABLE_AMOUNT = (2 ** 256 - 2) / 2; // An amount higher than the supply of ETH.
    uint256 private constant SEARCH_ITERATIONS = 10; // Number of iterations to search for suitable parent court before jumping to the top court.
    IERC20 private constant NATIVE_CURRENCY = IERC20(address(0)); // The native currency, such as ETH on Arbitrum, Optimism and Ethereum L1.

    address public governor; // The governor of the contract.
    IERC20 public pinakion; // The Pinakion token contract.
    address public jurorProsecutionModule; // The module for juror's prosecution.
    ISortitionModule public sortitionModule; // Sortition module for drawing.
    Court[] public courts; // The courts.
    DisputeKitNode[] public disputeKitNodes; // The list of DisputeKitNode, indexed by DisputeKitID.
    Dispute[] public disputes; // The disputes.
    mapping(address => Juror) internal jurors; // The jurors.
    mapping(IERC20 => CurrencyRate) public currencyRates; // The price of each token in ETH.

    // ************************************* //
    // *              Events               * //
    // ************************************* //

    event StakeSet(address indexed _address, uint256 _courtID, uint256 _amount);
    event StakeDelayed(address indexed _address, uint256 _courtID, uint256 _amount);
    event NewPeriod(uint256 indexed _disputeID, Period _period);
    event AppealPossible(uint256 indexed _disputeID, IArbitrableV2 indexed _arbitrable);
    event AppealDecision(uint256 indexed _disputeID, IArbitrableV2 indexed _arbitrable);
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
        uint256[] _supportedDisputeKits
    );
    event CourtModified(
        uint96 indexed _courtID,
        bool _hiddenVotes,
        uint256 _minStake,
        uint256 _alpha,
        uint256 _feeForJuror,
        uint256 _jurorsForCourtJump,
        uint256[4] _timesPerPeriod
    );
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
        uint256 indexed _roundID,
        uint256 _degreeOfCoherency,
        int256 _pnkAmount,
        int256 _feeAmount,
        IERC20 _feeToken
    );
    event LeftoverRewardSent(
        uint256 indexed _disputeID,
        uint256 indexed _roundID,
        uint256 _pnkAmount,
        uint256 _feeAmount,
        IERC20 _feeToken
    );

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    modifier onlyByGovernor() {
        if (governor != msg.sender) revert GovernorOnly();
        _;
    }

    // ************************************* //
    // *            Constructor            * //
    // ************************************* //

    /// @dev Constructor, initializing the implementation to reduce attack surface.
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializer (constructor equivalent for upgradable contracts).
    /// @param _governor The governor's address.
    /// @param _pinakion The address of the token contract.
    /// @param _jurorProsecutionModule The address of the juror prosecution module.
    /// @param _disputeKit The address of the default dispute kit.
    /// @param _hiddenVotes The `hiddenVotes` property value of the general court.
    /// @param _courtParameters Numeric parameters of General court (minStake, alpha, feeForJuror and jurorsForCourtJump respectively).
    /// @param _timesPerPeriod The `timesPerPeriod` property value of the general court.
    /// @param _sortitionExtraData The extra data for sortition module.
    /// @param _sortitionModuleAddress The sortition module responsible for sortition of the jurors.
    function initialize(
        address _governor,
        IERC20 _pinakion,
        address _jurorProsecutionModule,
        IDisputeKit _disputeKit,
        bool _hiddenVotes,
        uint256[4] memory _courtParameters,
        uint256[4] memory _timesPerPeriod,
        bytes memory _sortitionExtraData,
        ISortitionModule _sortitionModuleAddress
    ) external initializer {
        governor = _governor;
        pinakion = _pinakion;
        jurorProsecutionModule = _jurorProsecutionModule;
        sortitionModule = _sortitionModuleAddress;

        // NULL_DISPUTE_KIT: an empty element at index 0 to indicate when a node has no parent.
        disputeKitNodes.push();

        // DISPUTE_KIT_CLASSIC
        disputeKitNodes.push(
            DisputeKitNode({
                parent: Constants.NULL_DISPUTE_KIT,
                children: new uint256[](0),
                disputeKit: _disputeKit,
                depthLevel: 0,
                disabled: false
            })
        );
        emit DisputeKitCreated(Constants.DISPUTE_KIT_CLASSIC, _disputeKit, Constants.NULL_DISPUTE_KIT);

        // FORKING_COURT
        // TODO: Fill the properties for the Forking court, emit CourtCreated.
        courts.push();
        sortitionModule.createTree(bytes32(uint256(Constants.FORKING_COURT)), _sortitionExtraData);

        // GENERAL_COURT
        Court storage court = courts.push();
        court.parent = Constants.FORKING_COURT;
        court.children = new uint256[](0);
        court.hiddenVotes = _hiddenVotes;
        court.minStake = _courtParameters[0];
        court.alpha = _courtParameters[1];
        court.feeForJuror = _courtParameters[2];
        court.jurorsForCourtJump = _courtParameters[3];
        court.timesPerPeriod = _timesPerPeriod;

        sortitionModule.createTree(bytes32(uint256(Constants.GENERAL_COURT)), _sortitionExtraData);

        emit CourtCreated(
            1,
            court.parent,
            _hiddenVotes,
            _courtParameters[0],
            _courtParameters[1],
            _courtParameters[2],
            _courtParameters[3],
            _timesPerPeriod,
            new uint256[](0)
        );
        _enableDisputeKit(Constants.GENERAL_COURT, Constants.DISPUTE_KIT_CLASSIC, true);
    }

    // ************************************* //
    // *             Governance            * //
    // ************************************* //

    /* @dev Access Control to perform implementation upgrades (UUPS Proxiable)
     * @dev Only the governor can perform upgrades (`onlyByGovernor`)
     */
    function _authorizeUpgrade(address) internal view override onlyByGovernor {
        // NOP
    }

    /// @dev Allows the governor to call anything on behalf of the contract.
    /// @param _destination The destination of the call.
    /// @param _amount The value sent with the call.
    /// @param _data The data sent with the call.
    function executeGovernorProposal(
        address _destination,
        uint256 _amount,
        bytes memory _data
    ) external onlyByGovernor {
        (bool success, ) = _destination.call{value: _amount}(_data);
        if (!success) revert UnsuccessfulCall();
    }

    /// @dev Changes the `governor` storage variable.
    /// @param _governor The new value for the `governor` storage variable.
    function changeGovernor(address payable _governor) external onlyByGovernor {
        governor = _governor;
    }

    /// @dev Changes the `pinakion` storage variable.
    /// @param _pinakion The new value for the `pinakion` storage variable.
    function changePinakion(IERC20 _pinakion) external onlyByGovernor {
        pinakion = _pinakion;
    }

    /// @dev Changes the `jurorProsecutionModule` storage variable.
    /// @param _jurorProsecutionModule The new value for the `jurorProsecutionModule` storage variable.
    function changeJurorProsecutionModule(address _jurorProsecutionModule) external onlyByGovernor {
        jurorProsecutionModule = _jurorProsecutionModule;
    }

    /// @dev Changes the `_sortitionModule` storage variable.
    /// Note that the new module should be initialized for all courts.
    /// @param _sortitionModule The new value for the `sortitionModule` storage variable.
    function changeSortitionModule(ISortitionModule _sortitionModule) external onlyByGovernor {
        sortitionModule = _sortitionModule;
    }

    /// @dev Add a new supported dispute kit module to the court.
    /// @param _disputeKitAddress The address of the dispute kit contract.
    /// @param _parent The ID of the parent dispute kit. It is left empty when root DK is created.
    /// Note that the root DK must be supported by the general court.
    function addNewDisputeKit(IDisputeKit _disputeKitAddress, uint256 _parent) external onlyByGovernor {
        uint256 disputeKitID = disputeKitNodes.length;
        if (_parent >= disputeKitID) revert InvalidDisputKitParent();
        uint256 depthLevel;
        if (_parent != Constants.NULL_DISPUTE_KIT) {
            depthLevel = disputeKitNodes[_parent].depthLevel + 1;
            // It should be always possible to reach the root from the leaf with the defined number of search iterations.
            if (depthLevel >= SEARCH_ITERATIONS) revert DepthLevelMax();
        }
        disputeKitNodes.push(
            DisputeKitNode({
                parent: _parent,
                children: new uint256[](0),
                disputeKit: _disputeKitAddress,
                depthLevel: depthLevel,
                disabled: false
            })
        );

        disputeKitNodes[_parent].children.push(disputeKitID);
        emit DisputeKitCreated(disputeKitID, _disputeKitAddress, _parent);
        if (_parent == Constants.NULL_DISPUTE_KIT) {
            // A new dispute kit tree root should always be supported by the General court.
            _enableDisputeKit(Constants.GENERAL_COURT, disputeKitID, true);
        }
    }

    /// @dev Creates a court under a specified parent court.
    /// @param _parent The `parent` property value of the court.
    /// @param _hiddenVotes The `hiddenVotes` property value of the court.
    /// @param _minStake The `minStake` property value of the court.
    /// @param _alpha The `alpha` property value of the court.
    /// @param _feeForJuror The `feeForJuror` property value of the court.
    /// @param _jurorsForCourtJump The `jurorsForCourtJump` property value of the court.
    /// @param _timesPerPeriod The `timesPerPeriod` property value of the court.
    /// @param _sortitionExtraData Extra data for sortition module.
    /// @param _supportedDisputeKits Indexes of dispute kits that this court will support.
    function createCourt(
        uint96 _parent,
        bool _hiddenVotes,
        uint256 _minStake,
        uint256 _alpha,
        uint256 _feeForJuror,
        uint256 _jurorsForCourtJump,
        uint256[4] memory _timesPerPeriod,
        bytes memory _sortitionExtraData,
        uint256[] memory _supportedDisputeKits
    ) external onlyByGovernor {
        if (courts[_parent].minStake > _minStake) revert MinStakeLowerThanParentCourt();
        if (_supportedDisputeKits.length == 0) revert UnsupportedDisputeKit();
        if (_parent == Constants.FORKING_COURT) revert InvalidForkingCourtAsParent();

        uint256 courtID = courts.length;
        Court storage court = courts.push();

        for (uint256 i = 0; i < _supportedDisputeKits.length; i++) {
            if (_supportedDisputeKits[i] == 0 || _supportedDisputeKits[i] >= disputeKitNodes.length) {
                revert WrongDisputeKitIndex();
            }
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

        sortitionModule.createTree(bytes32(courtID), _sortitionExtraData);

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
            _supportedDisputeKits
        );
    }

    function changeCourtParameters(
        uint96 _courtID,
        bool _hiddenVotes,
        uint256 _minStake,
        uint256 _alpha,
        uint256 _feeForJuror,
        uint256 _jurorsForCourtJump,
        uint256[4] memory _timesPerPeriod
    ) external onlyByGovernor {
        Court storage court = courts[_courtID];
        if (_courtID != Constants.GENERAL_COURT && courts[court.parent].minStake > _minStake) {
            revert MinStakeLowerThanParentCourt();
        }
        for (uint256 i = 0; i < court.children.length; i++) {
            if (courts[court.children[i]].minStake < _minStake) {
                revert MinStakeLowerThanParentCourt();
            }
        }
        court.minStake = _minStake;
        court.hiddenVotes = _hiddenVotes;
        court.alpha = _alpha;
        court.feeForJuror = _feeForJuror;
        court.jurorsForCourtJump = _jurorsForCourtJump;
        court.timesPerPeriod = _timesPerPeriod;
        emit CourtModified(
            _courtID,
            _hiddenVotes,
            _minStake,
            _alpha,
            _feeForJuror,
            _jurorsForCourtJump,
            _timesPerPeriod
        );
    }

    /// @dev Adds/removes court's support for specified dispute kits.
    /// @param _courtID The ID of the court.
    /// @param _disputeKitIDs The IDs of dispute kits which support should be added/removed.
    /// @param _enable Whether add or remove the dispute kits from the court.
    function enableDisputeKits(uint96 _courtID, uint256[] memory _disputeKitIDs, bool _enable) external onlyByGovernor {
        for (uint256 i = 0; i < _disputeKitIDs.length; i++) {
            if (_enable) {
                if (_disputeKitIDs[i] == 0 || _disputeKitIDs[i] >= disputeKitNodes.length) {
                    revert WrongDisputeKitIndex();
                }
                _enableDisputeKit(_courtID, _disputeKitIDs[i], true);
            } else {
                if (
                    _courtID == Constants.GENERAL_COURT &&
                    disputeKitNodes[_disputeKitIDs[i]].parent == Constants.NULL_DISPUTE_KIT
                ) {
                    revert CannotDisableRootDKInGeneral();
                }
                _enableDisputeKit(_courtID, _disputeKitIDs[i], false);
            }
        }
    }

    /// @dev Changes the supported fee tokens.
    /// @param _feeToken The fee token.
    /// @param _accepted Whether the token is supported or not as a method of fee payment.
    function changeAcceptedFeeTokens(IERC20 _feeToken, bool _accepted) external onlyByGovernor {
        currencyRates[_feeToken].feePaymentAccepted = _accepted;
        emit AcceptedFeeToken(_feeToken, _accepted);
    }

    /// @dev Changes the currency rate of a fee token.
    /// @param _feeToken The fee token.
    /// @param _rateInEth The new rate of the fee token in ETH.
    /// @param _rateDecimals The new decimals of the fee token rate.
    function changeCurrencyRates(IERC20 _feeToken, uint64 _rateInEth, uint8 _rateDecimals) external onlyByGovernor {
        currencyRates[_feeToken].rateInEth = _rateInEth;
        currencyRates[_feeToken].rateDecimals = _rateDecimals;
        emit NewCurrencyRate(_feeToken, _rateInEth, _rateDecimals);
    }

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /// @dev Sets the caller's stake in a court.
    /// @param _courtID The ID of the court.
    /// @param _newStake The new stake.
    function setStake(uint96 _courtID, uint256 _newStake) external {
        if (!_setStakeForAccount(msg.sender, _courtID, _newStake)) revert StakingFailed();
    }

    function setStakeBySortitionModule(address _account, uint96 _courtID, uint256 _newStake) external {
        if (msg.sender != address(sortitionModule)) revert WrongCaller();
        _setStakeForAccount(_account, _courtID, _newStake);
    }

    /// @inheritdoc IArbitratorV2
    function createDispute(
        uint256 _numberOfChoices,
        bytes memory _extraData
    ) external payable override returns (uint256 disputeID) {
        if (msg.value < arbitrationCost(_extraData)) revert ArbitrationFeesNotEnough();

        return _createDispute(_numberOfChoices, _extraData, NATIVE_CURRENCY, msg.value);
    }

    /// @inheritdoc IArbitratorV2
    function createDispute(
        uint256 _numberOfChoices,
        bytes calldata _extraData,
        IERC20 _feeToken,
        uint256 _feeAmount
    ) external override returns (uint256 disputeID) {
        if (!currencyRates[_feeToken].feePaymentAccepted) revert TokenNotAccepted();
        if (_feeAmount < arbitrationCost(_extraData, _feeToken)) revert ArbitrationFeesNotEnough();

        if (!_feeToken.safeTransferFrom(msg.sender, address(this), _feeAmount)) revert TransferFailed();
        return _createDispute(_numberOfChoices, _extraData, _feeToken, _feeAmount);
    }

    function _createDispute(
        uint256 _numberOfChoices,
        bytes memory _extraData,
        IERC20 _feeToken,
        uint256 _feeAmount
    ) internal returns (uint256 disputeID) {
        (uint96 courtID, , uint256 disputeKitID) = _extraDataToCourtIDMinJurorsDisputeKit(_extraData);
        if (!courts[courtID].supportedDisputeKits[disputeKitID]) revert DisputeKitNotSupportedByCourt();

        disputeID = disputes.length;
        Dispute storage dispute = disputes.push();
        dispute.courtID = courtID;
        dispute.arbitrated = IArbitrableV2(msg.sender);
        dispute.lastPeriodChange = block.timestamp;

        IDisputeKit disputeKit = disputeKitNodes[disputeKitID].disputeKit;
        Court storage court = courts[dispute.courtID];
        Round storage round = dispute.rounds.push();

        // Obtain the feeForJuror in the same currency as the _feeAmount
        uint256 feeForJuror = (_feeToken == NATIVE_CURRENCY)
            ? court.feeForJuror
            : convertEthToTokenAmount(_feeToken, court.feeForJuror);
        round.nbVotes = _feeAmount / feeForJuror;
        round.disputeKitID = disputeKitID;
        round.pnkAtStakePerJuror = (court.minStake * court.alpha) / ALPHA_DIVISOR;
        round.totalFeesForJurors = _feeAmount;
        round.feeToken = IERC20(_feeToken);

        sortitionModule.createDisputeHook(disputeID, 0); // Default round ID.

        disputeKit.createDispute(disputeID, _numberOfChoices, _extraData, round.nbVotes);
        emit DisputeCreation(disputeID, IArbitrableV2(msg.sender));
    }

    /// @dev Passes the period of a specified dispute.
    /// @param _disputeID The ID of the dispute.
    function passPeriod(uint256 _disputeID) external {
        Dispute storage dispute = disputes[_disputeID];
        Court storage court = courts[dispute.courtID];

        uint256 currentRound = dispute.rounds.length - 1;
        Round storage round = dispute.rounds[currentRound];
        if (dispute.period == Period.evidence) {
            if (
                currentRound == 0 &&
                block.timestamp - dispute.lastPeriodChange < court.timesPerPeriod[uint256(dispute.period)]
            ) {
                revert EvidenceNotPassedAndNotAppeal();
            }
            if (round.drawnJurors.length != round.nbVotes) revert DisputeStillDrawing();
            dispute.period = court.hiddenVotes ? Period.commit : Period.vote;
        } else if (dispute.period == Period.commit) {
            if (
                block.timestamp - dispute.lastPeriodChange < court.timesPerPeriod[uint256(dispute.period)] &&
                !disputeKitNodes[round.disputeKitID].disputeKit.areCommitsAllCast(_disputeID)
            ) {
                revert CommitPeriodNotPassed();
            }
            dispute.period = Period.vote;
        } else if (dispute.period == Period.vote) {
            if (
                block.timestamp - dispute.lastPeriodChange < court.timesPerPeriod[uint256(dispute.period)] &&
                !disputeKitNodes[round.disputeKitID].disputeKit.areVotesAllCast(_disputeID)
            ) {
                revert VotePeriodNotPassed();
            }
            dispute.period = Period.appeal;
            emit AppealPossible(_disputeID, dispute.arbitrated);
        } else if (dispute.period == Period.appeal) {
            if (block.timestamp - dispute.lastPeriodChange < court.timesPerPeriod[uint256(dispute.period)]) {
                revert AppealPeriodNotPassed();
            }
            dispute.period = Period.execution;
        } else if (dispute.period == Period.execution) {
            revert DisputePeriodIsFinal();
        }

        dispute.lastPeriodChange = block.timestamp;
        emit NewPeriod(_disputeID, dispute.period);
    }

    /// @dev Draws jurors for the dispute. Can be called in parts.
    /// @param _disputeID The ID of the dispute.
    /// @param _iterations The number of iterations to run.
    function draw(uint256 _disputeID, uint256 _iterations) external {
        Dispute storage dispute = disputes[_disputeID];
        uint256 currentRound = dispute.rounds.length - 1;
        Round storage round = dispute.rounds[currentRound];
        if (dispute.period != Period.evidence) revert NotEvidencePeriod();

        IDisputeKit disputeKit = disputeKitNodes[round.disputeKitID].disputeKit;

        uint256 startIndex = round.drawIterations; // for gas: less storage reads
        uint256 i;
        while (i < _iterations && round.drawnJurors.length < round.nbVotes) {
            address drawnAddress = disputeKit.draw(_disputeID, startIndex + i++);
            if (drawnAddress == address(0)) {
                continue;
            }
            jurors[drawnAddress].lockedPnk += round.pnkAtStakePerJuror;
            emit Draw(drawnAddress, _disputeID, currentRound, round.drawnJurors.length);
            round.drawnJurors.push(drawnAddress);
            if (round.drawnJurors.length == round.nbVotes) {
                sortitionModule.postDrawHook(_disputeID, currentRound);
            }
        }
        round.drawIterations += i;
    }

    /// @dev Appeals the ruling of a specified dispute.
    /// Note: Access restricted to the Dispute Kit for this `disputeID`.
    /// @param _disputeID The ID of the dispute.
    /// @param _numberOfChoices Number of choices for the dispute. Can be required during court jump.
    /// @param _extraData Extradata for the dispute. Can be required during court jump.
    function appeal(uint256 _disputeID, uint256 _numberOfChoices, bytes memory _extraData) external payable {
        if (msg.value < appealCost(_disputeID)) revert AppealFeesNotEnough();

        Dispute storage dispute = disputes[_disputeID];
        if (dispute.period != Period.appeal) revert DisputeNotAppealable();

        Round storage round = dispute.rounds[dispute.rounds.length - 1];
        if (msg.sender != address(disputeKitNodes[round.disputeKitID].disputeKit)) revert DisputeKitOnly();

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
                } else if (disputeKitNodes[newDisputeKitID].parent != Constants.NULL_DISPUTE_KIT) {
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
                newCourtID = Constants.GENERAL_COURT;
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
        extraRound.pnkAtStakePerJuror = (court.minStake * court.alpha) / ALPHA_DIVISOR;
        extraRound.totalFeesForJurors = msg.value;
        extraRound.disputeKitID = newDisputeKitID;

        sortitionModule.createDisputeHook(_disputeID, dispute.rounds.length - 1);

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

    /// @dev Distribute the PNKs at stake and the dispute fees for the specific round of the dispute. Can be called in parts.
    /// @param _disputeID The ID of the dispute.
    /// @param _round The appeal round.
    /// @param _iterations The number of iterations to run.
    function execute(uint256 _disputeID, uint256 _round, uint256 _iterations) external {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.period != Period.execution) revert NotExecutionPeriod();

        Round storage round = dispute.rounds[_round];
        IDisputeKit disputeKit = disputeKitNodes[round.disputeKitID].disputeKit;

        uint256 start = round.repartitions;
        uint256 end = round.repartitions + _iterations;

        uint256 pnkPenaltiesInRoundCache = round.pnkPenalties; // For saving gas.
        uint256 numberOfVotesInRound = round.drawnJurors.length;
        uint256 coherentCount = disputeKit.getCoherentCount(_disputeID, _round); // Total number of jurors that are eligible to a reward in this round.

        if (coherentCount == 0) {
            // We loop over the votes once as there are no rewards because it is not a tie and no one in this round is coherent with the final outcome.
            if (end > numberOfVotesInRound) end = numberOfVotesInRound;
        } else {
            // We loop over the votes twice, first to collect the PNK penalties, and second to distribute them as rewards along with arbitration fees.
            if (end > numberOfVotesInRound * 2) end = numberOfVotesInRound * 2;
        }
        round.repartitions = end;

        for (uint256 i = start; i < end; i++) {
            if (i < numberOfVotesInRound) {
                pnkPenaltiesInRoundCache = _executePenalties(
                    ExecuteParams(_disputeID, _round, coherentCount, numberOfVotesInRound, pnkPenaltiesInRoundCache, i)
                );
            } else {
                _executeRewards(
                    ExecuteParams(_disputeID, _round, coherentCount, numberOfVotesInRound, pnkPenaltiesInRoundCache, i)
                );
            }
        }
        if (round.pnkPenalties != pnkPenaltiesInRoundCache) {
            round.pnkPenalties = pnkPenaltiesInRoundCache; // Reentrancy risk: breaks Check-Effect-Interact
        }
    }

    /// @dev Distribute the PNKs at stake and the dispute fees for the specific round of the dispute, penalties only.
    /// @param _params The parameters for the execution, see `ExecuteParams`.
    /// @return pnkPenaltiesInRoundCache The updated penalties in round cache.
    function _executePenalties(ExecuteParams memory _params) internal returns (uint256) {
        Dispute storage dispute = disputes[_params.disputeID];
        Round storage round = dispute.rounds[_params.round];
        IDisputeKit disputeKit = disputeKitNodes[round.disputeKitID].disputeKit;

        // [0, 1] value that determines how coherent the juror was in this round, in basis points.
        uint256 degreeOfCoherence = disputeKit.getDegreeOfCoherence(
            _params.disputeID,
            _params.round,
            _params.repartition
        );
        if (degreeOfCoherence > ALPHA_DIVISOR) {
            // Make sure the degree doesn't exceed 1, though it should be ensured by the dispute kit.
            degreeOfCoherence = ALPHA_DIVISOR;
        }

        // Fully coherent jurors won't be penalized.
        uint256 penalty = (round.pnkAtStakePerJuror * (ALPHA_DIVISOR - degreeOfCoherence)) / ALPHA_DIVISOR;
        _params.pnkPenaltiesInRound += penalty;

        // Unlock the PNKs affected by the penalty
        address account = round.drawnJurors[_params.repartition];
        jurors[account].lockedPnk -= penalty;

        // Apply the penalty to the staked PNKs.
        // Note that lockedPnk will always cover penalty while stakedPnk can become lower after manual unstaking.
        if (jurors[account].stakedPnk >= penalty) {
            jurors[account].stakedPnk -= penalty;
        } else {
            jurors[account].stakedPnk = 0;
        }
        emit TokenAndETHShift(
            account,
            _params.disputeID,
            _params.round,
            degreeOfCoherence,
            -int256(penalty),
            0,
            round.feeToken
        );

        if (!disputeKit.isVoteActive(_params.disputeID, _params.round, _params.repartition)) {
            // The juror is inactive, unstake them.
            sortitionModule.setJurorInactive(account);
        }
        if (_params.repartition == _params.numberOfVotesInRound - 1 && _params.coherentCount == 0) {
            // No one was coherent, send the rewards to the governor.
            if (round.feeToken == NATIVE_CURRENCY) {
                // The dispute fees were paid in ETH
                payable(governor).send(round.totalFeesForJurors);
            } else {
                // The dispute fees were paid in ERC20
                round.feeToken.safeTransfer(governor, round.totalFeesForJurors);
            }
            pinakion.safeTransfer(governor, _params.pnkPenaltiesInRound);
            emit LeftoverRewardSent(
                _params.disputeID,
                _params.round,
                _params.pnkPenaltiesInRound,
                round.totalFeesForJurors,
                round.feeToken
            );
        }
        return _params.pnkPenaltiesInRound;
    }

    /// @dev Distribute the PNKs at stake and the dispute fees for the specific round of the dispute, rewards only.
    /// @param _params The parameters for the execution, see `ExecuteParams`.
    function _executeRewards(ExecuteParams memory _params) internal {
        Dispute storage dispute = disputes[_params.disputeID];
        Round storage round = dispute.rounds[_params.round];
        IDisputeKit disputeKit = disputeKitNodes[round.disputeKitID].disputeKit;

        // [0, 1] value that determines how coherent the juror was in this round, in basis points.
        uint256 degreeOfCoherence = disputeKit.getDegreeOfCoherence(
            _params.disputeID,
            _params.round,
            _params.repartition % _params.numberOfVotesInRound
        );

        // Make sure the degree doesn't exceed 1, though it should be ensured by the dispute kit.
        if (degreeOfCoherence > ALPHA_DIVISOR) {
            degreeOfCoherence = ALPHA_DIVISOR;
        }

        address account = round.drawnJurors[_params.repartition % _params.numberOfVotesInRound];
        uint256 pnkLocked = (round.pnkAtStakePerJuror * degreeOfCoherence) / ALPHA_DIVISOR;

        // Release the rest of the PNKs of the juror for this round.
        jurors[account].lockedPnk -= pnkLocked;

        // Give back the locked PNKs in case the juror fully unstaked earlier.
        if (jurors[account].stakedPnk == 0) {
            pinakion.safeTransfer(account, pnkLocked);
        }

        // Transfer the rewards
        uint256 pnkReward = ((_params.pnkPenaltiesInRound / _params.coherentCount) * degreeOfCoherence) / ALPHA_DIVISOR;
        round.sumPnkRewardPaid += pnkReward;
        uint256 feeReward = ((round.totalFeesForJurors / _params.coherentCount) * degreeOfCoherence) / ALPHA_DIVISOR;
        round.sumFeeRewardPaid += feeReward;
        pinakion.safeTransfer(account, pnkReward);
        if (round.feeToken == NATIVE_CURRENCY) {
            // The dispute fees were paid in ETH
            payable(account).send(feeReward);
        } else {
            // The dispute fees were paid in ERC20
            round.feeToken.safeTransfer(account, feeReward);
        }
        emit TokenAndETHShift(
            account,
            _params.disputeID,
            _params.round,
            degreeOfCoherence,
            int256(pnkReward),
            int256(feeReward),
            round.feeToken
        );

        // Transfer any residual rewards to the governor. It may happen due to partial coherence of the jurors.
        if (_params.repartition == _params.numberOfVotesInRound * 2 - 1) {
            uint256 leftoverPnkReward = _params.pnkPenaltiesInRound - round.sumPnkRewardPaid;
            uint256 leftoverFeeReward = round.totalFeesForJurors - round.sumFeeRewardPaid;
            if (leftoverPnkReward != 0 || leftoverFeeReward != 0) {
                if (leftoverPnkReward != 0) {
                    pinakion.safeTransfer(governor, leftoverPnkReward);
                }
                if (leftoverFeeReward != 0) {
                    if (round.feeToken == NATIVE_CURRENCY) {
                        // The dispute fees were paid in ETH
                        payable(governor).send(leftoverFeeReward);
                    } else {
                        // The dispute fees were paid in ERC20
                        round.feeToken.safeTransfer(governor, leftoverFeeReward);
                    }
                }
                emit LeftoverRewardSent(
                    _params.disputeID,
                    _params.round,
                    leftoverPnkReward,
                    leftoverFeeReward,
                    round.feeToken
                );
            }
        }
    }

    /// @dev Executes a specified dispute's ruling.
    /// @param _disputeID The ID of the dispute.
    function executeRuling(uint256 _disputeID) external {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.period != Period.execution) revert NotExecutionPeriod();
        if (dispute.ruled) revert RulingAlreadyExecuted();

        (uint256 winningChoice, , ) = currentRuling(_disputeID);
        dispute.ruled = true;
        emit Ruling(dispute.arbitrated, _disputeID, winningChoice);
        dispute.arbitrated.rule(_disputeID, winningChoice);
    }

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /// @dev Compute the cost of arbitration denominated in ETH.
    ///      It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
    /// @param _extraData Additional info about the dispute. We use it to pass the ID of the dispute's court (first 32 bytes), the minimum number of jurors required (next 32 bytes) and the ID of the specific dispute kit (last 32 bytes).
    /// @return cost The arbitration cost in ETH.
    function arbitrationCost(bytes memory _extraData) public view override returns (uint256 cost) {
        (uint96 courtID, uint256 minJurors, ) = _extraDataToCourtIDMinJurorsDisputeKit(_extraData);
        cost = courts[courtID].feeForJuror * minJurors;
    }

    /// @dev Compute the cost of arbitration denominated in `_feeToken`.
    ///      It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
    /// @param _extraData Additional info about the dispute. We use it to pass the ID of the dispute's court (first 32 bytes), the minimum number of jurors required (next 32 bytes) and the ID of the specific dispute kit (last 32 bytes).
    /// @param _feeToken The ERC20 token used to pay fees.
    /// @return cost The arbitration cost in `_feeToken`.
    function arbitrationCost(bytes calldata _extraData, IERC20 _feeToken) public view override returns (uint256 cost) {
        cost = convertEthToTokenAmount(_feeToken, arbitrationCost(_extraData));
    }

    /// @dev Gets the cost of appealing a specified dispute.
    /// @param _disputeID The ID of the dispute.
    /// @return cost The appeal cost.
    function appealCost(uint256 _disputeID) public view returns (uint256 cost) {
        Dispute storage dispute = disputes[_disputeID];
        Round storage round = dispute.rounds[dispute.rounds.length - 1];
        Court storage court = courts[dispute.courtID];
        if (round.nbVotes >= court.jurorsForCourtJump) {
            // Jump to parent court.
            if (dispute.courtID == Constants.GENERAL_COURT) {
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

    /// @dev Gets the start and the end of a specified dispute's current appeal period.
    /// @param _disputeID The ID of the dispute.
    /// @return start The start of the appeal period.
    /// @return end The end of the appeal period.
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

    /// @dev Gets the current ruling of a specified dispute.
    /// @param _disputeID The ID of the dispute.
    /// @return ruling The current ruling.
    /// @return tied Whether it's a tie or not.
    /// @return overridden Whether the ruling was overridden by appeal funding or not.
    function currentRuling(uint256 _disputeID) public view returns (uint256 ruling, bool tied, bool overridden) {
        Dispute storage dispute = disputes[_disputeID];
        Round storage round = dispute.rounds[dispute.rounds.length - 1];
        IDisputeKit disputeKit = disputeKitNodes[round.disputeKitID].disputeKit;
        (ruling, tied, overridden) = disputeKit.currentRuling(_disputeID);
    }

    function getRoundInfo(uint256 _disputeID, uint256 _round) external view returns (Round memory) {
        return disputes[_disputeID].rounds[_round];
    }

    function getNumberOfRounds(uint256 _disputeID) external view returns (uint256) {
        return disputes[_disputeID].rounds.length;
    }

    function getJurorBalance(
        address _juror,
        uint96 _courtID
    ) external view returns (uint256 totalStaked, uint256 totalLocked, uint256 stakedInCourt, uint256 nbCourts) {
        Juror storage juror = jurors[_juror];
        totalStaked = juror.stakedPnk;
        totalLocked = juror.lockedPnk;
        stakedInCourt = juror.stakedPnkByCourt[_courtID];
        nbCourts = juror.courtIDs.length;
    }

    function isSupported(uint96 _courtID, uint256 _disputeKitID) external view returns (bool) {
        return courts[_courtID].supportedDisputeKits[_disputeKitID];
    }

    /// @dev Gets non-primitive properties of a specified dispute kit node.
    /// @param _disputeKitID The ID of the dispute kit.
    /// @return children Indexes of children of this DK.
    function getDisputeKitChildren(uint256 _disputeKitID) external view returns (uint256[] memory) {
        return disputeKitNodes[_disputeKitID].children;
    }

    /// @dev Gets the timesPerPeriod array for a given court.
    /// @param _courtID The ID of the court to get the times from.
    /// @return timesPerPeriod The timesPerPeriod array for the given court.
    function getTimesPerPeriod(uint96 _courtID) external view returns (uint256[4] memory timesPerPeriod) {
        timesPerPeriod = courts[_courtID].timesPerPeriod;
    }

    // ************************************* //
    // *   Public Views for Dispute Kits   * //
    // ************************************* //

    /// @dev Gets the number of votes permitted for the specified dispute in the latest round.
    /// @param _disputeID The ID of the dispute.
    function getNumberOfVotes(uint256 _disputeID) external view returns (uint256) {
        Dispute storage dispute = disputes[_disputeID];
        return dispute.rounds[dispute.rounds.length - 1].nbVotes;
    }

    /// @dev Returns true if the dispute kit will be switched to a parent DK.
    /// @param _disputeID The ID of the dispute.
    /// @return Whether DK will be switched or not.
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

    function getDisputeKitNodesLength() external view returns (uint256) {
        return disputeKitNodes.length;
    }

    /// @dev Gets the dispute kit for a specific `_disputeKitID`.
    /// @param _disputeKitID The ID of the dispute kit.
    function getDisputeKit(uint256 _disputeKitID) external view returns (IDisputeKit) {
        return disputeKitNodes[_disputeKitID].disputeKit;
    }

    /// @dev Gets the court identifiers where a specific `_juror` has staked.
    /// @param _juror The address of the juror.
    function getJurorCourtIDs(address _juror) public view returns (uint96[] memory) {
        return jurors[_juror].courtIDs;
    }

    function convertEthToTokenAmount(IERC20 _toToken, uint256 _amountInEth) public view returns (uint256) {
        return (_amountInEth * 10 ** currencyRates[_toToken].rateDecimals) / currencyRates[_toToken].rateInEth;
    }

    // ************************************* //
    // *            Internal               * //
    // ************************************* //

    /// @dev Toggles the dispute kit support for a given court.
    /// @param _courtID The ID of the court to toggle the support for.
    /// @param _disputeKitID The ID of the dispute kit to toggle the support for.
    /// @param _enable Whether to enable or disable the support.
    function _enableDisputeKit(uint96 _courtID, uint256 _disputeKitID, bool _enable) internal {
        courts[_courtID].supportedDisputeKits[_disputeKitID] = _enable;
        emit DisputeKitEnabled(_courtID, _disputeKitID, _enable);
    }

    /// @dev Sets the specified juror's stake in a court.
    /// `O(n + p * log_k(j))` where
    /// `n` is the number of courts the juror has staked in,
    /// `p` is the depth of the court tree,
    /// `k` is the minimum number of children per node of one of these courts' sortition sum tree,
    /// and `j` is the maximum number of jurors that ever staked in one of these courts simultaneously.
    /// @param _account The address of the juror.
    /// @param _courtID The ID of the court.
    /// @param _newStake The new stake.
    /// @return succeeded True if the call succeeded, false otherwise.
    function _setStakeForAccount(
        address _account,
        uint96 _courtID,
        uint256 _newStake
    ) internal returns (bool succeeded) {
        if (_courtID == Constants.FORKING_COURT || _courtID > courts.length) return false;

        Juror storage juror = jurors[_account];
        uint256 currentStake = juror.stakedPnkByCourt[_courtID];

        if (_newStake != 0) {
            if (_newStake < courts[_courtID].minStake) return false;
        } else if (currentStake == 0) {
            return false;
        }

        ISortitionModule.preStakeHookResult result = sortitionModule.preStakeHook(_account, _courtID, _newStake);
        if (result == ISortitionModule.preStakeHookResult.failed) {
            return false;
        } else if (result == ISortitionModule.preStakeHookResult.delayed) {
            emit StakeDelayed(_account, _courtID, _newStake);
            return true;
        }

        uint256 transferredAmount;
        if (_newStake >= currentStake) {
            // Stake increase
            // When stakedPnk becomes lower than lockedPnk count the locked tokens in when transferring tokens from juror.
            // (E.g. stakedPnk = 0, lockedPnk = 150) which can happen if the juror unstaked fully while having some tokens locked.
            uint256 previouslyLocked = (juror.lockedPnk >= juror.stakedPnk) ? juror.lockedPnk - juror.stakedPnk : 0; // underflow guard
            transferredAmount = (_newStake >= currentStake + previouslyLocked) // underflow guard
                ? _newStake - currentStake - previouslyLocked
                : 0;
            if (transferredAmount > 0) {
                if (!pinakion.safeTransferFrom(_account, address(this), transferredAmount)) {
                    return false;
                }
            }
            if (currentStake == 0) {
                juror.courtIDs.push(_courtID);
            }
        } else {
            // Stake decrease: make sure locked tokens always stay in the contract. They can only be released during Execution.
            if (juror.stakedPnk >= currentStake - _newStake + juror.lockedPnk) {
                // We have enough pnk staked to afford withdrawal while keeping locked tokens.
                transferredAmount = currentStake - _newStake;
            } else if (juror.stakedPnk >= juror.lockedPnk) {
                // Can't afford withdrawing the current stake fully. Take whatever is available while keeping locked tokens.
                transferredAmount = juror.stakedPnk - juror.lockedPnk;
            }
            if (transferredAmount > 0) {
                if (!pinakion.safeTransfer(_account, transferredAmount)) {
                    return false;
                }
            }
            if (_newStake == 0) {
                for (uint256 i = juror.courtIDs.length; i > 0; i--) {
                    if (juror.courtIDs[i - 1] == _courtID) {
                        juror.courtIDs[i - 1] = juror.courtIDs[juror.courtIDs.length - 1];
                        juror.courtIDs.pop();
                        break;
                    }
                }
            }
        }

        // Note that stakedPnk can become async with currentStake (e.g. after penalty).
        juror.stakedPnk = (juror.stakedPnk >= currentStake) ? juror.stakedPnk - currentStake + _newStake : _newStake;
        juror.stakedPnkByCourt[_courtID] = _newStake;

        sortitionModule.setStake(_account, _courtID, _newStake);
        emit StakeSet(_account, _courtID, _newStake);
        return true;
    }

    /// @dev Gets a court ID, the minimum number of jurors and an ID of a dispute kit from a specified extra data bytes array.
    /// Note that if extradata contains an incorrect value then this value will be switched to default.
    /// @param _extraData The extra data bytes array. The first 32 bytes are the court ID, the next are the minimum number of jurors and the last are the dispute kit ID.
    /// @return courtID The court ID.
    /// @return minJurors The minimum number of jurors required.
    /// @return disputeKitID The ID of the dispute kit.
    function _extraDataToCourtIDMinJurorsDisputeKit(
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
            if (courtID == Constants.FORKING_COURT || courtID >= courts.length) {
                courtID = Constants.GENERAL_COURT;
            }
            if (minJurors == 0) {
                minJurors = Constants.DEFAULT_NB_OF_JURORS;
            }
            if (disputeKitID == Constants.NULL_DISPUTE_KIT || disputeKitID >= disputeKitNodes.length) {
                disputeKitID = Constants.DISPUTE_KIT_CLASSIC; // 0 index is not used.
            }
        } else {
            courtID = Constants.GENERAL_COURT;
            minJurors = Constants.DEFAULT_NB_OF_JURORS;
            disputeKitID = Constants.DISPUTE_KIT_CLASSIC;
        }
    }

    // ************************************* //
    // *              Errors               * //
    // ************************************* //

    error GovernorOnly();
    error UnsuccessfulCall();
    error InvalidDisputKitParent();
    error DepthLevelMax();
    error MinStakeLowerThanParentCourt();
    error UnsupportedDisputeKit();
    error InvalidForkingCourtAsParent();
    error WrongDisputeKitIndex();
    error CannotDisableRootDKInGeneral();
    error ArraysLengthMismatch();
    error StakingFailed();
    error WrongCaller();
    error ArbitrationFeesNotEnough();
    error DisputeKitNotSupportedByCourt();
    error TokenNotAccepted();
    error EvidenceNotPassedAndNotAppeal();
    error DisputeStillDrawing();
    error CommitPeriodNotPassed();
    error VotePeriodNotPassed();
    error AppealPeriodNotPassed();
    error NotEvidencePeriod();
    error AppealFeesNotEnough();
    error DisputeNotAppealable();
    error DisputeKitOnly();
    error NotExecutionPeriod();
    error RulingAlreadyExecuted();
    error DisputePeriodIsFinal();
    error TransferFailed();
}

// SPDX-License-Identifier: MIT

/**
 *  @custom:authors: [@epiqueras, @unknownunknown1, @shotaronowhere]
 *  @custom:reviewers: []
 *  @custom:auditors: []
 *  @custom:bounties: []
 *  @custom:deployments: []
 */

pragma solidity 0.8.18;

import "./KlerosCore.sol";
import "./interfaces/ISortitionModule.sol";
import "./interfaces/IDisputeKit.sol";
import "../rng/RNG.sol";
import "../proxy/UUPSProxiable.sol";
import "../proxy/Initializable.sol";
import "../libraries/Constants.sol";

/// @title SortitionModule
/// @dev A factory of trees that keeps track of staked values for sortition.
contract SortitionModule is ISortitionModule, UUPSProxiable, Initializable {
    // ************************************* //
    // *         Enums / Structs           * //
    // ************************************* //

    struct SortitionSumTree {
        uint256 K; // The maximum number of children per node.
        // We use this to keep track of vacant positions in the tree after removing a leaf. This is for keeping the tree as balanced as possible without spending gas on moving nodes around.
        uint256[] stack;
        uint256[] nodes;
        // Two-way mapping of IDs to node indexes. Note that node index 0 is reserved for the root node, and means the ID does not have a node.
        mapping(bytes32 => uint256) IDsToNodeIndexes;
        mapping(uint256 => bytes32) nodeIndexesToIDs;
    }

    struct DelayedStake {
        address account; // The address of the juror.
        uint96 courtID; // The ID of the court.
        uint256 stake; // The new stake.
    }

    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    uint256 public constant MAX_STAKE_PATHS = 4; // The maximum number of stake paths a juror can have.
    uint256 public constant DEFAULT_K = 6; // Default number of children per node.

    address public governor; // The governor of the contract.
    KlerosCore public core; // The core arbitrator contract.
    Phase public phase; // The current phase.
    uint256 public minStakingTime; // The time after which the phase can be switched to Drawing if there are open disputes.
    uint256 public maxDrawingTime; // The time after which the phase can be switched back to Staking.
    uint256 public lastPhaseChange; // The last time the phase was changed.
    uint256 public randomNumberRequestBlock; // Number of the block when RNG request was made.
    uint256 public disputesWithoutJurors; // The number of disputes that have not finished drawing jurors.
    RNG public rng; // The random number generator.
    uint256 public randomNumber; // Random number returned by RNG.
    uint256 public rngLookahead; // Minimal block distance between requesting and obtaining a random number.
    uint256 public delayedStakeWriteIndex; // The index of the last `delayedStake` item that was written to the array. 0 index is skipped.
    uint256 public delayedStakeReadIndex; // The index of the next `delayedStake` item that should be processed. Starts at 1 because 0 index is skipped.
    mapping(bytes32 => SortitionSumTree) sortitionSumTrees; // The mapping trees by keys.
    mapping(uint256 => DelayedStake) public delayedStakes; // Stores the stakes that were changed during Drawing phase, to update them when the phase is switched to Staking.

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    modifier onlyByGovernor() {
        require(address(governor) == msg.sender, "Access not allowed: Governor only.");
        _;
    }

    modifier onlyByCore() {
        require(address(core) == msg.sender, "Access not allowed: KlerosCore only.");
        _;
    }

    // ************************************* //
    // *            Constructor            * //
    // ************************************* //

    /// @dev Constructor, initializing the implementation to reduce attack surface.
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializer (constructor equivalent for upgradable contracts).
    /// @param _core The KlerosCore.
    /// @param _minStakingTime Minimal time to stake
    /// @param _maxDrawingTime Time after which the drawing phase can be switched
    /// @param _rng The random number generator.
    /// @param _rngLookahead Lookahead value for rng.
    function initialize(
        address _governor,
        KlerosCore _core,
        uint256 _minStakingTime,
        uint256 _maxDrawingTime,
        RNG _rng,
        uint256 _rngLookahead
    ) external reinitializer(1) {
        governor = _governor;
        core = _core;
        minStakingTime = _minStakingTime;
        maxDrawingTime = _maxDrawingTime;
        lastPhaseChange = block.timestamp;
        rng = _rng;
        rngLookahead = _rngLookahead;
        delayedStakeReadIndex = 1;
    }

    // ************************************* //
    // *             Governance            * //
    // ************************************* //

    /**
     * @dev Access Control to perform implementation upgrades (UUPS Proxiable)
     * @dev Only the governor can perform upgrades (`onlyByGovernor`)
     */
    function _authorizeUpgrade(address) internal view override onlyByGovernor {
        // NOP
    }

    /// @dev Changes the `minStakingTime` storage variable.
    /// @param _minStakingTime The new value for the `minStakingTime` storage variable.
    function changeMinStakingTime(uint256 _minStakingTime) external onlyByGovernor {
        minStakingTime = _minStakingTime;
    }

    /// @dev Changes the `maxDrawingTime` storage variable.
    /// @param _maxDrawingTime The new value for the `maxDrawingTime` storage variable.
    function changeMaxDrawingTime(uint256 _maxDrawingTime) external onlyByGovernor {
        maxDrawingTime = _maxDrawingTime;
    }

    /// @dev Changes the `_rng` and `_rngLookahead` storage variables.
    /// @param _rng The new value for the `RNGenerator` storage variable.
    /// @param _rngLookahead The new value for the `rngLookahead` storage variable.
    function changeRandomNumberGenerator(RNG _rng, uint256 _rngLookahead) external onlyByGovernor {
        rng = _rng;
        rngLookahead = _rngLookahead;
        if (phase == Phase.generating) {
            rng.requestRandomness(block.number + rngLookahead);
            randomNumberRequestBlock = block.number;
        }
    }

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    function passPhase() external {
        if (phase == Phase.staking) {
            require(
                block.timestamp - lastPhaseChange >= minStakingTime,
                "The minimum staking time has not passed yet."
            );
            require(disputesWithoutJurors > 0, "There are no disputes that need jurors.");
            rng.requestRandomness(block.number + rngLookahead);
            randomNumberRequestBlock = block.number;
            phase = Phase.generating;
        } else if (phase == Phase.generating) {
            randomNumber = rng.receiveRandomness(randomNumberRequestBlock + rngLookahead);
            require(randomNumber != 0, "Random number is not ready yet");
            phase = Phase.drawing;
        } else if (phase == Phase.drawing) {
            require(
                disputesWithoutJurors == 0 || block.timestamp - lastPhaseChange >= maxDrawingTime,
                "There are still disputes without jurors and the maximum drawing time has not passed yet."
            );
            phase = Phase.staking;
        }

        lastPhaseChange = block.timestamp;
        emit NewPhase(phase);
    }

    /// @dev Create a sortition sum tree at the specified key.
    /// @param _key The key of the new tree.
    /// @param _extraData Extra data that contains the number of children each node in the tree should have.
    function createTree(bytes32 _key, bytes memory _extraData) external override onlyByCore {
        SortitionSumTree storage tree = sortitionSumTrees[_key];
        uint256 K = _extraDataToTreeK(_extraData);
        require(tree.K == 0, "Tree already exists.");
        require(K > 1, "K must be greater than one.");
        tree.K = K;
        tree.nodes.push(0);
    }

    /// @dev Executes the next delayed stakes.
    /// @param _iterations The number of delayed stakes to execute.
    function executeDelayedStakes(uint256 _iterations) external {
        require(phase == Phase.staking, "Should be in Staking phase.");

        uint256 actualIterations = (delayedStakeReadIndex + _iterations) - 1 > delayedStakeWriteIndex
            ? (delayedStakeWriteIndex - delayedStakeReadIndex) + 1
            : _iterations;
        uint256 newDelayedStakeReadIndex = delayedStakeReadIndex + actualIterations;

        for (uint256 i = delayedStakeReadIndex; i < newDelayedStakeReadIndex; i++) {
            DelayedStake storage delayedStake = delayedStakes[i];
            core.setStakeBySortitionModule(delayedStake.account, delayedStake.courtID, delayedStake.stake);
            delete delayedStakes[i];
        }
        delayedStakeReadIndex = newDelayedStakeReadIndex;
    }

    function preStakeHook(
        address _account,
        uint96 _courtID,
        uint256 _stake
    ) external override onlyByCore returns (preStakeHookResult) {
        (, , uint256 currentStake, uint256 nbCourts) = core.getJurorBalance(_account, _courtID);
        if (currentStake == 0 && nbCourts >= MAX_STAKE_PATHS) {
            // Prevent staking beyond MAX_STAKE_PATHS but unstaking is always allowed.
            return preStakeHookResult.failed;
        } else {
            if (phase != Phase.staking) {
                delayedStakes[++delayedStakeWriteIndex] = DelayedStake({
                    account: _account,
                    courtID: _courtID,
                    stake: _stake
                });
                return preStakeHookResult.delayed;
            }
        }
        return preStakeHookResult.ok;
    }

    function createDisputeHook(uint256 /*_disputeID*/, uint256 /*_roundID*/) external override onlyByCore {
        disputesWithoutJurors++;
    }

    function postDrawHook(uint256 /*_disputeID*/, uint256 /*_roundID*/) external override onlyByCore {
        disputesWithoutJurors--;
    }

    /// @dev Saves the random number to use it in sortition. Not used by this contract because the storing of the number is inlined in passPhase().
    /// @param _randomNumber Random number returned by RNG contract.
    function notifyRandomNumber(uint256 _randomNumber) public override {}

    /// @dev Sets the value for a particular court and its parent courts.
    /// @param _courtID ID of the court.
    /// @param _value The new value.
    /// @param _account Address of the juror.
    /// `O(log_k(n))` where
    /// `k` is the maximum number of children per node in the tree,
    ///  and `n` is the maximum number of nodes ever appended.
    function setStake(address _account, uint96 _courtID, uint256 _value) external override onlyByCore {
        bytes32 stakePathID = _accountAndCourtIDToStakePathID(_account, _courtID);
        bool finished = false;
        uint96 currenCourtID = _courtID;
        while (!finished) {
            // Tokens are also implicitly staked in parent courts through sortition module to increase the chance of being drawn.
            _set(bytes32(uint256(currenCourtID)), _value, stakePathID);
            if (currenCourtID == Constants.GENERAL_COURT) {
                finished = true;
            } else {
                (currenCourtID, , , , , , ) = core.courts(currenCourtID);
            }
        }
    }

    /// @dev Unstakes the inactive juror from all courts.
    /// `O(n * (p * log_k(j)) )` where
    /// `n` is the number of courts the juror has staked in,
    /// `p` is the depth of the court tree,
    /// `k` is the minimum number of children per node of one of these courts' sortition sum tree,
    /// and `j` is the maximum number of jurors that ever staked in one of these courts simultaneously.
    /// @param _account The juror to unstake.
    function setJurorInactive(address _account) external override onlyByCore {
        uint96[] memory courtIDs = core.getJurorCourtIDs(_account);
        for (uint256 j = courtIDs.length; j > 0; j--) {
            core.setStakeBySortitionModule(_account, courtIDs[j - 1], 0);
        }
    }

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /// @dev Draw an ID from a tree using a number.
    /// Note that this function reverts if the sum of all values in the tree is 0.
    /// @param _key The key of the tree.
    /// @param _coreDisputeID Index of the dispute in Kleros Core.
    /// @param _nonce Nonce to hash with random number.
    /// @return drawnAddress The drawn address.
    /// `O(k * log_k(n))` where
    /// `k` is the maximum number of children per node in the tree,
    ///  and `n` is the maximum number of nodes ever appended.
    function draw(
        bytes32 _key,
        uint256 _coreDisputeID,
        uint256 _nonce
    ) public view override returns (address drawnAddress) {
        require(phase == Phase.drawing, "Wrong phase.");
        SortitionSumTree storage tree = sortitionSumTrees[_key];

        if (tree.nodes[0] == 0) {
            return address(0); // No jurors staked.
        }

        uint256 currentDrawnNumber = uint256(keccak256(abi.encodePacked(randomNumber, _coreDisputeID, _nonce))) %
            tree.nodes[0];

        // While it still has children
        uint256 treeIndex = 0;
        while ((tree.K * treeIndex) + 1 < tree.nodes.length) {
            for (uint256 i = 1; i <= tree.K; i++) {
                // Loop over children.
                uint256 nodeIndex = (tree.K * treeIndex) + i;
                uint256 nodeValue = tree.nodes[nodeIndex];

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
        drawnAddress = _stakePathIDToAccount(tree.nodeIndexesToIDs[treeIndex]);
    }

    // ************************************* //
    // *            Internal               * //
    // ************************************* //

    /// @dev Update all the parents of a node.
    /// @param _key The key of the tree to update.
    /// @param _treeIndex The index of the node to start from.
    /// @param _plusOrMinus Whether to add (true) or substract (false).
    /// @param _value The value to add or substract.
    /// `O(log_k(n))` where
    /// `k` is the maximum number of children per node in the tree,
    ///  and `n` is the maximum number of nodes ever appended.
    function _updateParents(bytes32 _key, uint256 _treeIndex, bool _plusOrMinus, uint256 _value) private {
        SortitionSumTree storage tree = sortitionSumTrees[_key];

        uint256 parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus
                ? tree.nodes[parentIndex] + _value
                : tree.nodes[parentIndex] - _value;
        }
    }

    /// @dev Retrieves a juror's address from the stake path ID.
    /// @param _stakePathID The stake path ID to unpack.
    /// @return account The account.
    function _stakePathIDToAccount(bytes32 _stakePathID) internal pure returns (address account) {
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

    function _extraDataToTreeK(bytes memory _extraData) internal pure returns (uint256 K) {
        if (_extraData.length >= 32) {
            assembly {
                // solium-disable-line security/no-inline-assembly
                K := mload(add(_extraData, 0x20))
            }
        } else {
            K = DEFAULT_K;
        }
    }

    /// @dev Set a value in a tree.
    /// @param _key The key of the tree.
    /// @param _value The new value.
    /// @param _ID The ID of the value.
    /// `O(log_k(n))` where
    /// `k` is the maximum number of children per node in the tree,
    ///  and `n` is the maximum number of nodes ever appended.
    function _set(bytes32 _key, uint256 _value, bytes32 _ID) internal {
        SortitionSumTree storage tree = sortitionSumTrees[_key];
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

                _updateParents(_key, treeIndex, true, _value);
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

                _updateParents(_key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) {
                // New, non zero value.
                // Set.
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint256 plusOrMinusValue = plusOrMinus
                    ? _value - tree.nodes[treeIndex]
                    : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                _updateParents(_key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

    /// @dev Packs an account and a court ID into a stake path ID.
    /// @param _account The address of the juror to pack.
    /// @param _courtID The court ID to pack.
    /// @return stakePathID The stake path ID.
    function _accountAndCourtIDToStakePathID(
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IArbitratorV2.sol";

/// @title IArbitrableV2
/// @notice Arbitrable interface.
/// When developing arbitrable contracts, we need to:
/// - Define the action taken when a ruling is received by the contract.
/// - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
interface IArbitrableV2 {
    /// @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
    /// @param _arbitrator The arbitrator of the contract.
    /// @param _arbitrableDisputeID The identifier of the dispute in the Arbitrable contract.
    /// @param _externalDisputeID An identifier created outside Kleros by the protocol requesting arbitration.
    /// @param _templateId The identifier of the dispute template. Should not be used with _templateUri.
    /// @param _templateUri The URI to the dispute template. For example on IPFS: starting with '/ipfs/'. Should not be used with _templateId.
    event DisputeRequest(
        IArbitratorV2 indexed _arbitrator,
        uint256 indexed _arbitrableDisputeID,
        uint256 _externalDisputeID,
        uint256 _templateId,
        string _templateUri
    );

    /// @dev To be raised when a ruling is given.
    /// @param _arbitrator The arbitrator giving the ruling.
    /// @param _disputeID The identifier of the dispute in the Arbitrator contract.
    /// @param _ruling The ruling which was given.
    event Ruling(IArbitratorV2 indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /// @dev Give a ruling for a dispute.
    ///      Must be called by the arbitrator.
    ///      The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
    /// @param _disputeID The identifier of the dispute in the Arbitrator contract.
    /// @param _ruling Ruling given by the arbitrator.
    /// Note that 0 is reserved for "Not able/wanting to make a decision".
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IArbitrableV2.sol";

/// @title Arbitrator
/// Arbitrator interface that implements the new arbitration standard.
/// Unlike the ERC-792 this standard is not concerned with appeals, so each arbitrator can implement an appeal system that suits it the most.
/// When developing arbitrator contracts we need to:
/// - Define the functions for dispute creation (createDispute). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
/// - Define the functions for cost display (arbitrationCost).
/// - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
interface IArbitratorV2 {
    /// @dev To be emitted when a dispute is created.
    /// @param _disputeID The identifier of the dispute in the Arbitrator contract.
    /// @param _arbitrable The contract which created the dispute.
    event DisputeCreation(uint256 indexed _disputeID, IArbitrableV2 indexed _arbitrable);

    /// @dev To be raised when a ruling is given.
    /// @param _arbitrable The arbitrable receiving the ruling.
    /// @param _disputeID The identifier of the dispute in the Arbitrator contract.
    /// @param _ruling The ruling which was given.
    event Ruling(IArbitrableV2 indexed _arbitrable, uint256 indexed _disputeID, uint256 _ruling);

    /// @dev To be emitted when an ERC20 token is added or removed as a method to pay fees.
    /// @param _token The ERC20 token.
    /// @param _accepted Whether the token is accepted or not.
    event AcceptedFeeToken(IERC20 indexed _token, bool indexed _accepted);

    /// @dev To be emitted when the fee for a particular ERC20 token is updated.
    /// @param _feeToken The ERC20 token.
    /// @param _rateInEth The new rate of the fee token in ETH.
    /// @param _rateDecimals The new decimals of the fee token rate.
    event NewCurrencyRate(IERC20 indexed _feeToken, uint64 _rateInEth, uint8 _rateDecimals);

    /// @dev Create a dispute and pay for the fees in the native currency, typically ETH.
    ///      Must be called by the arbitrable contract.
    ///      Must pay at least arbitrationCost(_extraData).
    /// @param _numberOfChoices The number of choices the arbitrator can choose from in this dispute.
    /// @param _extraData Additional info about the dispute. We use it to pass the ID of the dispute's court (first 32 bytes), the minimum number of jurors required (next 32 bytes) and the ID of the specific dispute kit (last 32 bytes).
    /// @return disputeID The identifier of the dispute created.
    function createDispute(
        uint256 _numberOfChoices,
        bytes calldata _extraData
    ) external payable returns (uint256 disputeID);

    /// @dev Create a dispute and pay for the fees in a supported ERC20 token.
    ///      Must be called by the arbitrable contract.
    ///      Must pay at least arbitrationCost(_extraData).
    /// @param _numberOfChoices The number of choices the arbitrator can choose from in this dispute.
    /// @param _extraData Additional info about the dispute. We use it to pass the ID of the dispute's court (first 32 bytes), the minimum number of jurors required (next 32 bytes) and the ID of the specific dispute kit (last 32 bytes).
    /// @param _feeToken The ERC20 token used to pay fees.
    /// @param _feeAmount Amount of the ERC20 token used to pay fees.
    /// @return disputeID The identifier of the dispute created.
    function createDispute(
        uint256 _numberOfChoices,
        bytes calldata _extraData,
        IERC20 _feeToken,
        uint256 _feeAmount
    ) external returns (uint256 disputeID);

    /// @dev Compute the cost of arbitration denominated in the native currency, typically ETH.
    ///      It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
    /// @param _extraData Additional info about the dispute. We use it to pass the ID of the dispute's court (first 32 bytes), the minimum number of jurors required (next 32 bytes) and the ID of the specific dispute kit (last 32 bytes).
    /// @return cost The arbitration cost in ETH.
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);

    /// @dev Compute the cost of arbitration denominated in `_feeToken`.
    ///      It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
    /// @param _extraData Additional info about the dispute. We use it to pass the ID of the dispute's court (first 32 bytes), the minimum number of jurors required (next 32 bytes) and the ID of the specific dispute kit (last 32 bytes).
    /// @param _feeToken The ERC20 token used to pay fees.
    /// @return cost The arbitration cost in `_feeToken`.
    function arbitrationCost(bytes calldata _extraData, IERC20 _feeToken) external view returns (uint256 cost);

    /// @dev Gets the current ruling of a specified dispute.
    /// @param _disputeID The ID of the dispute.
    /// @return ruling The current ruling.
    /// @return tied Whether it's a tie or not.
    /// @return overridden Whether the ruling was overridden by appeal funding or not.
    function currentRuling(uint256 _disputeID) external view returns (uint256 ruling, bool tied, bool overridden);
}

// SPDX-License-Identifier: MIT

/// @custom:authors: [@unknownunknown1, @jaybuidl]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

import "./IArbitratorV2.sol";

/// @title IDisputeKit
/// An abstraction of the Dispute Kits intended for interfacing with KlerosCore.
/// It does not intend to abstract the interactions with the user (such as voting or appeal funding) to allow for implementation-specific parameters.
interface IDisputeKit {
    // ************************************ //
    // *             Events               * //
    // ************************************ //

    /// @dev Emitted when casting a vote to provide the justification of juror's choice.
    /// @param _coreDisputeID The identifier of the dispute in the Arbitrator contract.
    /// @param _juror Address of the juror.
    /// @param _voteIDs The identifiers of the votes in the dispute.
    /// @param _choice The choice juror voted for.
    /// @param _justification Justification of the choice.
    event VoteCast(
        uint256 indexed _coreDisputeID,
        address indexed _juror,
        uint256[] _voteIDs,
        uint256 indexed _choice,
        string _justification
    );

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /// @dev Creates a local dispute and maps it to the dispute ID in the Core contract.
    /// Note: Access restricted to Kleros Core only.
    /// @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
    /// @param _numberOfChoices Number of choices of the dispute
    /// @param _extraData Additional info about the dispute, for possible use in future dispute kits.
    function createDispute(
        uint256 _coreDisputeID,
        uint256 _numberOfChoices,
        bytes calldata _extraData,
        uint256 _nbVotes
    ) external;

    /// @dev Draws the juror from the sortition tree. The drawn address is picked up by Kleros Core.
    /// Note: Access restricted to Kleros Core only.
    /// @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
    /// @param _nonce Nonce.
    /// @return drawnAddress The drawn address.
    function draw(uint256 _coreDisputeID, uint256 _nonce) external returns (address drawnAddress);

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /// @dev Gets the current ruling of a specified dispute.
    /// @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
    /// @return ruling The current ruling.
    /// @return tied Whether it's a tie or not.
    /// @return overridden Whether the ruling was overridden by appeal funding or not.
    function currentRuling(uint256 _coreDisputeID) external view returns (uint256 ruling, bool tied, bool overridden);

    /// @dev Gets the degree of coherence of a particular voter. This function is called by Kleros Core in order to determine the amount of the reward.
    /// @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
    /// @param _coreRoundID The ID of the round in Kleros Core, not in the Dispute Kit.
    /// @param _voteID The ID of the vote.
    /// @return The degree of coherence in basis points.
    function getDegreeOfCoherence(
        uint256 _coreDisputeID,
        uint256 _coreRoundID,
        uint256 _voteID
    ) external view returns (uint256);

    /// @dev Gets the number of jurors who are eligible to a reward in this round.
    /// @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
    /// @param _coreRoundID The ID of the round in Kleros Core, not in the Dispute Kit.
    /// @return The number of coherent jurors.
    function getCoherentCount(uint256 _coreDisputeID, uint256 _coreRoundID) external view returns (uint256);

    /// @dev Returns true if all of the jurors have cast their commits for the last round.
    /// @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
    /// @return Whether all of the jurors have cast their commits for the last round.
    function areCommitsAllCast(uint256 _coreDisputeID) external view returns (bool);

    /// @dev Returns true if all of the jurors have cast their votes for the last round.
    /// @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
    /// @return Whether all of the jurors have cast their votes for the last round.
    function areVotesAllCast(uint256 _coreDisputeID) external view returns (bool);

    /// @dev Returns true if the specified voter was active in this round.
    /// @param _coreDisputeID The ID of the dispute in Kleros Core, not in the Dispute Kit.
    /// @param _coreRoundID The ID of the round in Kleros Core, not in the Dispute Kit.
    /// @param _voteID The ID of the voter.
    /// @return Whether the voter was active or not.
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ISortitionModule {
    enum Phase {
        staking, // Stake sum trees can be updated. Pass after `minStakingTime` passes and there is at least one dispute without jurors.
        generating, // Waiting for a random number. Pass as soon as it is ready.
        drawing // Jurors can be drawn. Pass after all disputes have jurors or `maxDrawingTime` passes.
    }

    enum preStakeHookResult {
        ok,
        delayed,
        failed
    }

    event NewPhase(Phase _phase);

    function createTree(bytes32 _key, bytes memory _extraData) external;

    function setStake(address _account, uint96 _courtID, uint256 _value) external;

    function setJurorInactive(address _account) external;

    function notifyRandomNumber(uint256 _drawnNumber) external;

    function draw(bytes32 _court, uint256 _coreDisputeID, uint256 _nonce) external view returns (address);

    function preStakeHook(address _account, uint96 _courtID, uint256 _stake) external returns (preStakeHookResult);

    function createDisputeHook(uint256 _disputeID, uint256 _roundID) external;

    function postDrawHook(uint256 _disputeID, uint256 _roundID) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/// @title Constants
library Constants {
    // Courts
    uint96 public constant FORKING_COURT = 0; // Index of the forking court.
    uint96 public constant GENERAL_COURT = 1; // Index of the default (general) court.

    // Dispute Kits
    uint256 public constant NULL_DISPUTE_KIT = 0; // Null pattern to indicate a top-level DK which has no parent.
    uint256 public constant DISPUTE_KIT_CLASSIC = 1; // Index of the default DK. 0 index is skipped.

    // Defaults
    uint256 public constant DEFAULT_NB_OF_JURORS = 3; // The default number of jurors in a dispute.
}

// SPDX-License-Identifier: MIT
// Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a7a94c77463acea95d979aae1580fb0ddc3b6a1e/contracts/token/ERC20/utils/SafeERC20.sol

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SafeERC20
/// @dev Wrappers around ERC20 operations that throw on failure (when the token
/// contract returns false). Tokens that return no value (and instead revert or
/// throw on failure) are also supported, non-reverting calls are assumed to be
/// successful.
/// To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
/// which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
library SafeERC20 {
    /// @dev Increases the allowance granted to `spender` by the caller.
    /// @param _token Token to transfer.
    /// @param _spender The address which will spend the funds.
    /// @param _addedValue The amount of tokens to increase the allowance by.
    function increaseAllowance(IERC20 _token, address _spender, uint256 _addedValue) internal returns (bool) {
        _token.approve(_spender, _token.allowance(address(this), _spender) + _addedValue);
        return true;
    }

    /// @dev Calls transfer() without reverting.
    /// @param _token Token to transfer.
    /// @param _to Recepient address.
    /// @param _value Amount transferred.
    /// @return Whether transfer succeeded or not.
    function safeTransfer(IERC20 _token, address _to, uint256 _value) internal returns (bool) {
        (bool success, bytes memory data) = address(_token).call(abi.encodeCall(IERC20.transfer, (_to, _value)));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    /// @dev Calls transferFrom() without reverting.
    /// @param _token Token to transfer.
    /// @param _from Sender address.
    /// @param _to Recepient address.
    /// @param _value Amount transferred.
    /// @return Whether transfer succeeded or not.
    function safeTransferFrom(IERC20 _token, address _from, address _to, uint256 _value) internal returns (bool) {
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeCall(IERC20.transferFrom, (_from, _to, _value))
        );
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol) <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/Initializable.sol>

pragma solidity 0.8.18;

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
 * possible by providing the encoded function call as the `_data` argument to the proxy constructor
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

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1))
    bytes32 private constant _INITIALIZABLE_STORAGE =
        0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a0e;

    /**
     * @dev The contract is already initialized.
     */
    error AlreadyInitialized();

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
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;
        if (!(isTopLevelCall && initialized < 1) && !(address(this).code.length == 0 && initialized == 1)) {
            revert AlreadyInitialized();
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
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert AlreadyInitialized();
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
            revert AlreadyInitialized();
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
            $.slot := _INITIALIZABLE_STORAGE
        }
    }
}

//SPDX-License-Identifier: MIT
// Adapted from <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol>

/**
 *  @authors: [@malatrax]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */
pragma solidity 0.8.18;

/**
 * @title UUPS Proxiable
 * @author Simon Malatrait <[email protected]>
 * @dev This contract implements an upgradeability mechanism designed for UUPS proxies.
 * The functions included here can perform an upgrade of an UUPS Proxy, when this contract is set as the implementation behind such a proxy.
 *
 * IMPORTANT: A UUPS proxy requires its upgradeability functions to be in the implementation as opposed to the transparent proxy.
 * This means that if the proxy is upgraded to an implementation that does not support this interface, it will no longer be upgradeable.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSProxiable` with a custom implementation of upgrades.
 *
 * The `_authorizeUpgrade` function must be overridden to include access restriction to the upgrade mechanism.
 */
abstract contract UUPSProxiable {
    // ************************************* //
    // *             Event                 * //
    // ************************************* //

    /**
     * Emitted when the `implementation` has been successfully upgraded.
     * @param newImplementation Address of the new implementation the proxy is now forwarding calls to.
     */
    event Upgraded(address indexed newImplementation);

    // ************************************* //
    // *             Error                 * //
    // ************************************* //

    /**
     * @dev The call is from an unauthorized context.
     */
    error UUPSUnauthorizedCallContext();

    /**
     * @dev The storage `slot` is unsupported as a UUID.
     */
    error UUPSUnsupportedProxiableUUID(bytes32 slot);

    /// The `implementation` is not UUPS-compliant
    error InvalidImplementation(address implementation);

    /// Failed Delegated call
    error FailedDelegateCall();

    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     * NOTE: bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
     */
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage variable of the proxiable contract address.
     * It is used to check whether or not the current call is from the proxy.
     */
    address private immutable __self = address(this);

    // ************************************* //
    // *             Governance            * //
    // ************************************* //

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract.
     * @dev Called by {upgradeToAndCall}.
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /**
     * @dev Upgrade mechanism including access control and UUPS-compliance.
     * @param newImplementation Address of the new implementation contract.
     * @param data Data used in a delegate call to `newImplementation` if non-empty. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     *
     * @dev Reverts if the execution is not performed via delegatecall or the execution
     * context is not of a proxy with an ERC1967-compliant implementation pointing to self.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual {
        _authorizeUpgrade(newImplementation);

        /* Check that the execution is being performed through a delegatecall call and that the execution context is
        a proxy contract with an implementation (as defined in ERC1967) pointing to self. */
        if (address(this) == __self || _getImplementation() != __self) {
            revert UUPSUnauthorizedCallContext();
        }

        try UUPSProxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != IMPLEMENTATION_SLOT) {
                revert UUPSUnsupportedProxiableUUID(slot);
            }
            // Store the new implementation address to the implementation storage slot.
            assembly {
                sstore(IMPLEMENTATION_SLOT, newImplementation)
            }
            emit Upgraded(newImplementation);

            if (data.length != 0) {
                // The return data is not checked (checking, in case of success, that the newImplementation code is non-empty if the return data is empty) because the authorized callee is trusted.
                (bool success, ) = newImplementation.delegatecall(data);
                if (!success) {
                    revert FailedDelegateCall();
                }
            }
        } catch {
            revert InvalidImplementation(newImplementation);
        }
    }

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /**
     * @dev Implementation of the ERC1822 `proxiableUUID` function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the if statement.
     */
    function proxiableUUID() external view virtual returns (bytes32) {
        if (address(this) != __self) {
            // Must not be called through delegatecall
            revert UUPSUnauthorizedCallContext();
        }
        return IMPLEMENTATION_SLOT;
    }

    // ************************************* //
    // *           Internal Views          * //
    // ************************************* //

    function _getImplementation() internal view returns (address implementation) {
        assembly {
            implementation := sload(IMPLEMENTATION_SLOT)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface RNG {
    /// @dev Request a random number.
    /// @param _block Block linked to the request.
    function requestRandomness(uint256 _block) external;

    /// @dev Receive the random number.
    /// @param _block Block the random number is linked to.
    /// @return randomNumber Random Number. If the number is not ready or has not been required 0 instead.
    function receiveRandomness(uint256 _block) external returns (uint256 randomNumber);
}