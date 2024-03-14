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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

/// @custom:authors: [@unknownunknown1, @jaybuidl]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

import {IArbitrableV2, IArbitratorV2} from "./interfaces/IArbitratorV2.sol";
import {IDisputeKit} from "./interfaces/IDisputeKit.sol";
import {ISortitionModule} from "./interfaces/ISortitionModule.sol";
import {SafeERC20, IERC20} from "../libraries/SafeERC20.sol";
import "../libraries/Constants.sol";

/// @title KlerosCoreBase
/// Core arbitrator contract for Kleros v2.
/// Note that this contract trusts the PNK token, the dispute kit and the sortition module contracts.
abstract contract KlerosCoreBase is IArbitratorV2 {
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
        mapping(uint256 => bool) supportedDisputeKits; // True if DK with this ID is supported by the court. Note that each court must support classic dispute kit.
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

    // Workaround "stack too deep" errors
    struct ExecuteParams {
        uint256 disputeID; // The ID of the dispute to execute.
        uint256 round; // The round to execute.
        uint256 coherentCount; // The number of coherent votes in the round.
        uint256 numberOfVotesInRound; // The number of votes in the round.
        uint256 feePerJurorInRound; // The fee per juror in the round.
        uint256 pnkAtStakePerJurorInRound; // The amount of PNKs at stake for each juror in the round.
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

    address public governor; // The governor of the contract.
    address public guardian; // The guardian able to pause asset withdrawals.
    IERC20 public pinakion; // The Pinakion token contract.
    address public jurorProsecutionModule; // The module for juror's prosecution.
    ISortitionModule public sortitionModule; // Sortition module for drawing.
    Court[] public courts; // The courts.
    IDisputeKit[] public disputeKits; // Array of dispute kits.
    Dispute[] public disputes; // The disputes.
    mapping(IERC20 => CurrencyRate) public currencyRates; // The price of each token in ETH.
    bool public paused; // Whether asset withdrawals are paused.

    // ************************************* //
    // *              Events               * //
    // ************************************* //

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
    event DisputeKitCreated(uint256 indexed _disputeKitID, IDisputeKit indexed _disputeKitAddress);
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
    event Paused();
    event Unpaused();

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    modifier onlyByGovernor() {
        if (governor != msg.sender) revert GovernorOnly();
        _;
    }

    modifier onlyByGuardianOrGovernor() {
        if (guardian != msg.sender && governor != msg.sender) revert GuardianOrGovernorOnly();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert WhenPausedOnly();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert WhenNotPausedOnly();
        _;
    }

    // ************************************* //
    // *            Constructor            * //
    // ************************************* //

    function _initialize(
        address _governor,
        address _guardian,
        IERC20 _pinakion,
        address _jurorProsecutionModule,
        IDisputeKit _disputeKit,
        bool _hiddenVotes,
        uint256[4] memory _courtParameters,
        uint256[4] memory _timesPerPeriod,
        bytes memory _sortitionExtraData,
        ISortitionModule _sortitionModuleAddress
    ) internal {
        governor = _governor;
        guardian = _guardian;
        pinakion = _pinakion;
        jurorProsecutionModule = _jurorProsecutionModule;
        sortitionModule = _sortitionModuleAddress;

        // NULL_DISPUTE_KIT: an empty element at index 0 to indicate when a dispute kit is not supported.
        disputeKits.push();

        // DISPUTE_KIT_CLASSIC
        disputeKits.push(_disputeKit);

        emit DisputeKitCreated(DISPUTE_KIT_CLASSIC, _disputeKit);

        // FORKING_COURT
        // TODO: Fill the properties for the Forking court, emit CourtCreated.
        courts.push();
        sortitionModule.createTree(bytes32(uint256(FORKING_COURT)), _sortitionExtraData);

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

        sortitionModule.createTree(bytes32(uint256(GENERAL_COURT)), _sortitionExtraData);

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
        _enableDisputeKit(GENERAL_COURT, DISPUTE_KIT_CLASSIC, true);
    }

    // ************************************* //
    // *             Governance            * //
    // ************************************* //

    /// @dev Pause staking and reward execution. Can only be done by guardian or governor.
    function pause() external onlyByGuardianOrGovernor whenNotPaused {
        paused = true;
        emit Paused();
    }

    /// @dev Unpause staking and reward execution. Can only be done by governor.
    function unpause() external onlyByGovernor whenPaused {
        paused = false;
        emit Unpaused();
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

    /// @dev Changes the `guardian` storage variable.
    /// @param _guardian The new value for the `guardian` storage variable.
    function changeGuardian(address _guardian) external onlyByGovernor {
        guardian = _guardian;
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
    function addNewDisputeKit(IDisputeKit _disputeKitAddress) external onlyByGovernor {
        uint256 disputeKitID = disputeKits.length;
        disputeKits.push(_disputeKitAddress);
        emit DisputeKitCreated(disputeKitID, _disputeKitAddress);
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
        if (_parent == FORKING_COURT) revert InvalidForkingCourtAsParent();

        uint256 courtID = courts.length;
        Court storage court = courts.push();

        for (uint256 i = 0; i < _supportedDisputeKits.length; i++) {
            if (_supportedDisputeKits[i] == 0 || _supportedDisputeKits[i] >= disputeKits.length) {
                revert WrongDisputeKitIndex();
            }
            court.supportedDisputeKits[_supportedDisputeKits[i]] = true;
        }
        // Check that Classic DK support was added.
        if (!court.supportedDisputeKits[DISPUTE_KIT_CLASSIC]) revert MustSupportDisputeKitClassic();

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
        if (_courtID != GENERAL_COURT && courts[court.parent].minStake > _minStake) {
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
                if (_disputeKitIDs[i] == 0 || _disputeKitIDs[i] >= disputeKits.length) {
                    revert WrongDisputeKitIndex();
                }
                _enableDisputeKit(_courtID, _disputeKitIDs[i], true);
            } else {
                // Classic dispute kit must be supported by all courts.
                if (_disputeKitIDs[i] == DISPUTE_KIT_CLASSIC) {
                    revert CannotDisableClassicDK();
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
    /// Note that the existing delayed stake will be nullified as non-relevant.
    function setStake(uint96 _courtID, uint256 _newStake) external virtual whenNotPaused {
        _setStake(msg.sender, _courtID, _newStake, false, OnError.Revert);
    }

    /// @dev Sets the stake of a specified account in a court, typically to apply a delayed stake or unstake inactive jurors.
    /// @param _account The account whose stake is being set.
    /// @param _courtID The ID of the court.
    /// @param _newStake The new stake.
    /// @param _alreadyTransferred Whether the PNKs have already been transferred to the contract.
    function setStakeBySortitionModule(
        address _account,
        uint96 _courtID,
        uint256 _newStake,
        bool _alreadyTransferred
    ) external {
        if (msg.sender != address(sortitionModule)) revert SortitionModuleOnly();
        _setStake(_account, _courtID, _newStake, _alreadyTransferred, OnError.Return);
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
    ) internal virtual returns (uint256 disputeID) {
        (uint96 courtID, , uint256 disputeKitID) = _extraDataToCourtIDMinJurorsDisputeKit(_extraData);
        if (!courts[courtID].supportedDisputeKits[disputeKitID]) revert DisputeKitNotSupportedByCourt();

        disputeID = disputes.length;
        Dispute storage dispute = disputes.push();
        dispute.courtID = courtID;
        dispute.arbitrated = IArbitrableV2(msg.sender);
        dispute.lastPeriodChange = block.timestamp;

        IDisputeKit disputeKit = disputeKits[disputeKitID];
        Court storage court = courts[courtID];
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
                !disputeKits[round.disputeKitID].areCommitsAllCast(_disputeID)
            ) {
                revert CommitPeriodNotPassed();
            }
            dispute.period = Period.vote;
        } else if (dispute.period == Period.vote) {
            if (
                block.timestamp - dispute.lastPeriodChange < court.timesPerPeriod[uint256(dispute.period)] &&
                !disputeKits[round.disputeKitID].areVotesAllCast(_disputeID)
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

        IDisputeKit disputeKit = disputeKits[round.disputeKitID];

        uint256 startIndex = round.drawIterations; // for gas: less storage reads
        uint256 i;
        while (i < _iterations && round.drawnJurors.length < round.nbVotes) {
            address drawnAddress = disputeKit.draw(_disputeID, startIndex + i++);
            if (drawnAddress == address(0)) {
                continue;
            }
            sortitionModule.lockStake(drawnAddress, round.pnkAtStakePerJuror);
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
        if (msg.sender != address(disputeKits[round.disputeKitID])) revert DisputeKitOnly();

        uint96 newCourtID = dispute.courtID;
        uint256 newDisputeKitID = round.disputeKitID;

        // Warning: the extra round must be created before calling disputeKit.createDispute()
        Round storage extraRound = dispute.rounds.push();

        if (round.nbVotes >= courts[newCourtID].jurorsForCourtJump) {
            // Jump to parent court.
            newCourtID = courts[newCourtID].parent;

            if (!courts[newCourtID].supportedDisputeKits[newDisputeKitID]) {
                // Switch to classic dispute kit if parent court doesn't support the current one.
                newDisputeKitID = DISPUTE_KIT_CLASSIC;
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
            disputeKits[extraRound.disputeKitID].createDispute(
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
    /// Note: Reward distributions are forbidden during pause.
    /// @param _disputeID The ID of the dispute.
    /// @param _round The appeal round.
    /// @param _iterations The number of iterations to run.
    function execute(uint256 _disputeID, uint256 _round, uint256 _iterations) external whenNotPaused {
        Round storage round;
        {
            Dispute storage dispute = disputes[_disputeID];
            if (dispute.period != Period.execution) revert NotExecutionPeriod();

            round = dispute.rounds[_round];
        } // stack too deep workaround

        uint256 start = round.repartitions;
        uint256 end = round.repartitions + _iterations;

        uint256 pnkPenaltiesInRound = round.pnkPenalties; // Keep in memory to save gas.
        uint256 numberOfVotesInRound = round.drawnJurors.length;
        uint256 feePerJurorInRound = round.totalFeesForJurors / numberOfVotesInRound;
        uint256 pnkAtStakePerJurorInRound = round.pnkAtStakePerJuror;
        uint256 coherentCount;
        {
            IDisputeKit disputeKit = disputeKits[round.disputeKitID];
            coherentCount = disputeKit.getCoherentCount(_disputeID, _round); // Total number of jurors that are eligible to a reward in this round.
        } // stack too deep workaround

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
                pnkPenaltiesInRound = _executePenalties(
                    ExecuteParams({
                        disputeID: _disputeID,
                        round: _round,
                        coherentCount: coherentCount,
                        numberOfVotesInRound: numberOfVotesInRound,
                        feePerJurorInRound: feePerJurorInRound,
                        pnkAtStakePerJurorInRound: pnkAtStakePerJurorInRound,
                        pnkPenaltiesInRound: pnkPenaltiesInRound,
                        repartition: i
                    })
                );
            } else {
                _executeRewards(
                    ExecuteParams({
                        disputeID: _disputeID,
                        round: _round,
                        coherentCount: coherentCount,
                        numberOfVotesInRound: numberOfVotesInRound,
                        feePerJurorInRound: feePerJurorInRound,
                        pnkAtStakePerJurorInRound: pnkAtStakePerJurorInRound,
                        pnkPenaltiesInRound: pnkPenaltiesInRound,
                        repartition: i
                    })
                );
            }
        }
        if (round.pnkPenalties != pnkPenaltiesInRound) {
            round.pnkPenalties = pnkPenaltiesInRound; // Reentrancy risk: breaks Check-Effect-Interact
        }
    }

    /// @dev Distribute the PNKs at stake and the dispute fees for the specific round of the dispute, penalties only.
    /// @param _params The parameters for the execution, see `ExecuteParams`.
    /// @return pnkPenaltiesInRoundCache The updated penalties in round cache.
    function _executePenalties(ExecuteParams memory _params) internal returns (uint256) {
        Dispute storage dispute = disputes[_params.disputeID];
        Round storage round = dispute.rounds[_params.round];
        IDisputeKit disputeKit = disputeKits[round.disputeKitID];

        // [0, 1] value that determines how coherent the juror was in this round, in basis points.
        uint256 degreeOfCoherence = disputeKit.getDegreeOfCoherence(
            _params.disputeID,
            _params.round,
            _params.repartition,
            _params.feePerJurorInRound,
            _params.pnkAtStakePerJurorInRound
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
        sortitionModule.unlockStake(account, penalty);

        // Apply the penalty to the staked PNKs.
        sortitionModule.penalizeStake(account, penalty);
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
        IDisputeKit disputeKit = disputeKits[round.disputeKitID];

        // [0, 1] value that determines how coherent the juror was in this round, in basis points.
        uint256 degreeOfCoherence = disputeKit.getDegreeOfCoherence(
            _params.disputeID,
            _params.round,
            _params.repartition % _params.numberOfVotesInRound,
            _params.feePerJurorInRound,
            _params.pnkAtStakePerJurorInRound
        );

        // Make sure the degree doesn't exceed 1, though it should be ensured by the dispute kit.
        if (degreeOfCoherence > ALPHA_DIVISOR) {
            degreeOfCoherence = ALPHA_DIVISOR;
        }

        address account = round.drawnJurors[_params.repartition % _params.numberOfVotesInRound];
        uint256 pnkLocked = (round.pnkAtStakePerJuror * degreeOfCoherence) / ALPHA_DIVISOR;

        // Release the rest of the PNKs of the juror for this round.
        sortitionModule.unlockStake(account, pnkLocked);

        // Give back the locked PNKs in case the juror fully unstaked earlier.
        if (!sortitionModule.isJurorStaked(account)) {
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
        IDisputeKit disputeKit = disputeKits[round.disputeKitID];
        (ruling, tied, overridden) = disputeKit.currentRuling(_disputeID);
    }

    function getRoundInfo(uint256 _disputeID, uint256 _round) external view returns (Round memory) {
        return disputes[_disputeID].rounds[_round];
    }

    function getNumberOfRounds(uint256 _disputeID) external view returns (uint256) {
        return disputes[_disputeID].rounds.length;
    }

    function isSupported(uint96 _courtID, uint256 _disputeKitID) external view returns (bool) {
        return courts[_courtID].supportedDisputeKits[_disputeKitID];
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

    function getDisputeKitsLength() external view returns (uint256) {
        return disputeKits.length;
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
    /// @param _enable Whether to enable or disable the support. Note that classic dispute kit should always be enabled.
    function _enableDisputeKit(uint96 _courtID, uint256 _disputeKitID, bool _enable) internal {
        courts[_courtID].supportedDisputeKits[_disputeKitID] = _enable;
        emit DisputeKitEnabled(_courtID, _disputeKitID, _enable);
    }

    /// @dev If called only once then set _onError to Revert, otherwise set it to Return
    /// @param _account The account to set the stake for.
    /// @param _courtID The ID of the court to set the stake for.
    /// @param _newStake The new stake.
    /// @param _alreadyTransferred Whether the PNKs were already transferred to/from the staking contract.
    /// @param _onError Whether to revert or return false on error.
    /// @return Whether the stake was successfully set or not.
    function _setStake(
        address _account,
        uint96 _courtID,
        uint256 _newStake,
        bool _alreadyTransferred,
        OnError _onError
    ) internal returns (bool) {
        if (_courtID == FORKING_COURT || _courtID > courts.length) {
            _stakingFailed(_onError, StakingResult.CannotStakeInThisCourt); // Staking directly into the forking court is not allowed.
            return false;
        }
        if (_newStake != 0 && _newStake < courts[_courtID].minStake) {
            _stakingFailed(_onError, StakingResult.CannotStakeLessThanMinStake); // Staking less than the minimum stake is not allowed.
            return false;
        }
        (uint256 pnkDeposit, uint256 pnkWithdrawal, StakingResult stakingResult) = sortitionModule.setStake(
            _account,
            _courtID,
            _newStake,
            _alreadyTransferred
        );
        if (stakingResult != StakingResult.Successful) {
            _stakingFailed(_onError, stakingResult);
            return false;
        }
        if (pnkDeposit > 0) {
            if (!pinakion.safeTransferFrom(_account, address(this), pnkDeposit)) {
                _stakingFailed(_onError, StakingResult.StakingTransferFailed);
                return false;
            }
        }
        if (pnkWithdrawal > 0) {
            if (!pinakion.safeTransfer(_account, pnkWithdrawal)) {
                _stakingFailed(_onError, StakingResult.UnstakingTransferFailed);
                return false;
            }
        }
        return true;
    }

    /// @dev It may revert depending on the _onError parameter.
    function _stakingFailed(OnError _onError, StakingResult _result) internal pure virtual {
        if (_onError == OnError.Return) return;
        if (_result == StakingResult.StakingTransferFailed) revert StakingTransferFailed();
        if (_result == StakingResult.UnstakingTransferFailed) revert UnstakingTransferFailed();
        if (_result == StakingResult.CannotStakeInMoreCourts) revert StakingInTooManyCourts();
        if (_result == StakingResult.CannotStakeInThisCourt) revert StakingNotPossibeInThisCourt();
        if (_result == StakingResult.CannotStakeLessThanMinStake) revert StakingLessThanCourtMinStake();
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
            if (courtID == FORKING_COURT || courtID >= courts.length) {
                courtID = GENERAL_COURT;
            }
            if (minJurors == 0) {
                minJurors = DEFAULT_NB_OF_JURORS;
            }
            if (disputeKitID == NULL_DISPUTE_KIT || disputeKitID >= disputeKits.length) {
                disputeKitID = DISPUTE_KIT_CLASSIC; // 0 index is not used.
            }
        } else {
            courtID = GENERAL_COURT;
            minJurors = DEFAULT_NB_OF_JURORS;
            disputeKitID = DISPUTE_KIT_CLASSIC;
        }
    }

    // ************************************* //
    // *              Errors               * //
    // ************************************* //

    error GovernorOnly();
    error GuardianOrGovernorOnly();
    error DisputeKitOnly();
    error SortitionModuleOnly();
    error UnsuccessfulCall();
    error InvalidDisputKitParent();
    error DepthLevelMax();
    error MinStakeLowerThanParentCourt();
    error UnsupportedDisputeKit();
    error InvalidForkingCourtAsParent();
    error WrongDisputeKitIndex();
    error CannotDisableClassicDK();
    error ArraysLengthMismatch();
    error StakingInTooManyCourts();
    error StakingNotPossibeInThisCourt();
    error StakingLessThanCourtMinStake();
    error StakingTransferFailed();
    error UnstakingTransferFailed();
    error ArbitrationFeesNotEnough();
    error DisputeKitNotSupportedByCourt();
    error MustSupportDisputeKitClassic();
    error TokenNotAccepted();
    error EvidenceNotPassedAndNotAppeal();
    error DisputeStillDrawing();
    error CommitPeriodNotPassed();
    error VotePeriodNotPassed();
    error AppealPeriodNotPassed();
    error NotEvidencePeriod();
    error AppealFeesNotEnough();
    error DisputeNotAppealable();
    error NotExecutionPeriod();
    error RulingAlreadyExecuted();
    error DisputePeriodIsFinal();
    error TransferFailed();
    error WhenNotPausedOnly();
    error WhenPausedOnly();
}

// SPDX-License-Identifier: MIT

/// @custom:authors: [@unknownunknown1, @jaybuidl]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

import "./KlerosCoreBase.sol";
import {UUPSProxiable} from "../proxy/UUPSProxiable.sol";
import {Initializable} from "../proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title KlerosCoreNeo
/// Core arbitrator contract for Kleros v2.
/// Note that this contract trusts the PNK token, the dispute kit and the sortition module contracts.
contract KlerosCoreNeo is KlerosCoreBase, UUPSProxiable, Initializable {
    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    mapping(address => bool) public arbitrableWhitelist; // Arbitrable whitelist.
    IERC721 public jurorNft; // Eligible jurors NFT.

    // ************************************* //
    // *            Constructor            * //
    // ************************************* //

    /// @dev Constructor, initializing the implementation to reduce attack surface.
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializer (constructor equivalent for upgradable contracts).
    /// @param _governor The governor's address.
    /// @param _guardian The guardian's address.
    /// @param _pinakion The address of the token contract.
    /// @param _jurorProsecutionModule The address of the juror prosecution module.
    /// @param _disputeKit The address of the default dispute kit.
    /// @param _hiddenVotes The `hiddenVotes` property value of the general court.
    /// @param _courtParameters Numeric parameters of General court (minStake, alpha, feeForJuror and jurorsForCourtJump respectively).
    /// @param _timesPerPeriod The `timesPerPeriod` property value of the general court.
    /// @param _sortitionExtraData The extra data for sortition module.
    /// @param _sortitionModuleAddress The sortition module responsible for sortition of the jurors.
    /// @param _jurorNft NFT contract to vet the jurors.
    function initialize(
        address _governor,
        address _guardian,
        IERC20 _pinakion,
        address _jurorProsecutionModule,
        IDisputeKit _disputeKit,
        bool _hiddenVotes,
        uint256[4] memory _courtParameters,
        uint256[4] memory _timesPerPeriod,
        bytes memory _sortitionExtraData,
        ISortitionModule _sortitionModuleAddress,
        IERC721 _jurorNft
    ) external reinitializer(2) {
        super._initialize(
            _governor,
            _guardian,
            _pinakion,
            _jurorProsecutionModule,
            _disputeKit,
            _hiddenVotes,
            _courtParameters,
            _timesPerPeriod,
            _sortitionExtraData,
            _sortitionModuleAddress
        );
        jurorNft = _jurorNft;
    }

    // ************************************* //
    // *             Governance            * //
    // ************************************* //

    /// @dev Access Control to perform implementation upgrades (UUPS Proxiable)
    ///      Only the governor can perform upgrades (`onlyByGovernor`)
    function _authorizeUpgrade(address) internal view override onlyByGovernor {
        // NOP
    }

    /// @dev Changes the `jurorNft` storage variable.
    /// @param _jurorNft The new value for the `jurorNft` storage variable.
    function changeJurorNft(IERC721 _jurorNft) external onlyByGovernor {
        jurorNft = _jurorNft;
    }

    /// @dev Adds or removes an arbitrable from whitelist.
    /// @param _arbitrable Arbitrable address.
    /// @param _allowed Whether add or remove permission.
    function changeArbitrableWhitelist(address _arbitrable, bool _allowed) external onlyByGovernor {
        arbitrableWhitelist[_arbitrable] = _allowed;
    }

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /// @dev Sets the caller's stake in a court.
    /// Note: Staking and unstaking is forbidden during pause.
    /// @param _courtID The ID of the court.
    /// @param _newStake The new stake.
    /// Note that the existing delayed stake will be nullified as non-relevant.
    function setStake(uint96 _courtID, uint256 _newStake) external override whenNotPaused {
        if (jurorNft.balanceOf(msg.sender) == 0) revert NotEligibleForStaking();
        super._setStake(msg.sender, _courtID, _newStake, false, OnError.Revert);
    }

    // ************************************* //
    // *            Internal               * //
    // ************************************* //

    function _createDispute(
        uint256 _numberOfChoices,
        bytes memory _extraData,
        IERC20 _feeToken,
        uint256 _feeAmount
    ) internal override returns (uint256 disputeID) {
        if (!arbitrableWhitelist[msg.sender]) revert ArbitrableNotWhitelisted();
        return super._createDispute(_numberOfChoices, _extraData, _feeToken, _feeAmount);
    }

    function _stakingFailed(OnError _onError, StakingResult _result) internal pure override {
        super._stakingFailed(_onError, _result);
        if (_result == StakingResult.CannotStakeMoreThanMaxStakePerJuror) revert StakingMoreThanMaxStakePerJuror();
        if (_result == StakingResult.CannotStakeMoreThanMaxTotalStaked) revert StakingMoreThanMaxTotalStaked();
    }

    // ************************************* //
    // *              Errors               * //
    // ************************************* //

    error NotEligibleForStaking();
    error StakingMoreThanMaxStakePerJuror();
    error StakingMoreThanMaxTotalStaked();
    error ArbitrableNotWhitelisted();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IArbitratorV2.sol";

/// @title IArbitrableV2
/// @notice Arbitrable interface.
/// @dev When developing arbitrable contracts, we need to:
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
    /// @param _feePerJuror The fee per juror.
    /// @param _pnkAtStakePerJuror The PNK at stake per juror.
    /// @return The degree of coherence in basis points.
    function getDegreeOfCoherence(
        uint256 _coreDisputeID,
        uint256 _coreRoundID,
        uint256 _voteID,
        uint256 _feePerJuror,
        uint256 _pnkAtStakePerJuror
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

import "../../libraries/Constants.sol";

interface ISortitionModule {
    enum Phase {
        staking, // Stake sum trees can be updated. Pass after `minStakingTime` passes and there is at least one dispute without jurors.
        generating, // Waiting for a random number. Pass as soon as it is ready.
        drawing // Jurors can be drawn. Pass after all disputes have jurors or `maxDrawingTime` passes.
    }

    event NewPhase(Phase _phase);

    function createTree(bytes32 _key, bytes memory _extraData) external;

    function setStake(
        address _account,
        uint96 _courtID,
        uint256 _newStake,
        bool _alreadyTransferred
    ) external returns (uint256 pnkDeposit, uint256 pnkWithdrawal, StakingResult stakingResult);

    function setJurorInactive(address _account) external;

    function lockStake(address _account, uint256 _relativeAmount) external;

    function unlockStake(address _account, uint256 _relativeAmount) external;

    function penalizeStake(address _account, uint256 _relativeAmount) external;

    function notifyRandomNumber(uint256 _drawnNumber) external;

    function draw(bytes32 _court, uint256 _coreDisputeID, uint256 _nonce) external view returns (address);

    function getJurorBalance(
        address _juror,
        uint96 _courtID
    ) external view returns (uint256 totalStaked, uint256 totalLocked, uint256 stakedInCourt, uint256 nbCourts);

    function getJurorCourtIDs(address _juror) external view returns (uint96[] memory);

    function isJurorStaked(address _juror) external view returns (bool);

    function createDisputeHook(uint256 _disputeID, uint256 _roundID) external;

    function postDrawHook(uint256 _disputeID, uint256 _roundID) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Courts
uint96 constant FORKING_COURT = 0; // Index of the forking court.
uint96 constant GENERAL_COURT = 1; // Index of the default (general) court.

// Dispute Kits
uint256 constant NULL_DISPUTE_KIT = 0; // Null pattern to indicate a top-level DK which has no parent.
uint256 constant DISPUTE_KIT_CLASSIC = 1; // Index of the default DK. 0 index is skipped.

// Sortition Module
uint256 constant MAX_STAKE_PATHS = 4; // The maximum number of stake paths a juror can have.
uint256 constant DEFAULT_K = 6; // Default number of children per node.

// Defaults
uint256 constant DEFAULT_NB_OF_JURORS = 3; // The default number of jurors in a dispute.
IERC20 constant NATIVE_CURRENCY = IERC20(address(0)); // The native currency, such as ETH on Arbitrum, Optimism and Ethereum L1.

enum OnError {
    Revert,
    Return
}

enum StakingResult {
    Successful,
    StakingTransferFailed,
    UnstakingTransferFailed,
    CannotStakeInMoreCourts,
    CannotStakeInThisCourt,
    CannotStakeLessThanMinStake,
    CannotStakeMoreThanMaxStakePerJuror,
    CannotStakeMoreThanMaxTotalStaked
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol) <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/proxy/utils/Initializable.sol>

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
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
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
// Adapted from <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/proxy/utils/UUPSUpgradeable.sol>

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