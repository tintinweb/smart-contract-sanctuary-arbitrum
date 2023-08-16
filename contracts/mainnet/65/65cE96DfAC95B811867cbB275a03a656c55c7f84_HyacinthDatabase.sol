// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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

pragma solidity 0.8.14;

import "./interface/IProofOfDeveloper.sol";
import "./interface/IProofOfAuditor.sol";
import "./interface/IDeveloperWallet.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

/// @title   Hyacinth Database
/// @notice  Contract that keeps track of pending and completed audits
/// @author  Hyacinth
contract HyacinthDatabase {
    /// EVENTS ///

    /// @notice          Emitted after audit has been created
    /// @param auditId   Audit id
    /// @param previous  Audit id of previous audit
    /// @param developer Address of developer
    /// @param contracts Address of conrtacts being audited (Off chain audit if empty)
    event AuditCreated(
        uint256 indexed auditId,
        uint256 indexed previous,
        address indexed developer,
        address[] contracts
    );

    /// @notice           Emitted after pod has been minted
    /// @param developer  Address of developer
    /// @param id         Id of POD minted
    event PODMinted(address indexed developer, uint256 id);

    /// @notice           Emitted after audit result has been submitted
    /// @param auditor    Address of auditor
    /// @param developer  Developer of contracts
    /// @param auditId    Id of audit
    /// @param result     Result of audit
    event ResultSubmitted(address indexed auditor, address indexed developer, uint256 indexed auditId, STATUS result);

    /// @notice           Emitted after audit result has been submitted
    /// @param auditId    Id of audit
    /// @param auditor    Address of auditor
    /// @param developer  Developer of `auditId`
    /// @param positive   Bool if positive feedback
    event AuditFeedBackGiven(
        uint256 indexed auditId,
        address indexed auditor,
        address indexed developer,
        bool positive
    );

    /// @notice           Emitted after bounty has been refunded
    /// @param developer  Address of developer being refunded
    /// @param auditId    Id of audit being refunded
    event BountyRefunded(address indexed developer, uint256 indexed auditId);

    /// @notice         Emitted after auditor request has been sent
    /// @param auditor  Address of auditor requesting
    /// @param auditId  Audit id of audit request
    event AuditorRequest(address indexed auditor, uint256 indexed auditId);

    /// @notice           Emitted after auditor has been accepted
    /// @param developer  Address of developer of audit
    /// @param auditor    Address of auditor accepted
    /// @param auditId    Audit id auditor has been accepted for
    event AuditorAccepted(address indexed developer, address indexed auditor, uint256 indexed auditId);

    /// @notice                 Emitted after collaboration has been created
    /// @param auditId          Audit id collaborator is being added to
    /// @param collaborator     Address of collaborator
    /// @param percentOfBounty  Percent of bounty given to collaborator
    event CollaborationCreated(uint256 indexed auditId, address collaborator, uint256 percentOfBounty);

    /// @notice        Emitted after max number of audits for auditor set
    /// @param oldMax  Old max audits for auditor
    /// @param newMax  New max audits for auditor
    event MaxAuditsSet(uint256 oldMax, uint256 newMax);

    /// @notice           Emitted after time to roll over is updated
    /// @param oldPeriod  Old roll over period
    /// @param newPeriod  New roll over period
    event TimeToRollOverSet(uint256 oldPeriod, uint256 newPeriod);

    /// @notice         Emitted after auditor has been added
    /// @param auditor  Address of auditor being added
    event AuditorAdded(address auditor);

    /// @notice         Emitted after auditor has been removed
    /// @param auditor  Address of auditor being removed
    event AuditorRemoved(address auditor);

    /// @notice               Emitted after ownership has been transfered
    /// @param previousOwner  Address of previous owner
    /// @param newOwner       Address of new owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// ERRORS ///

    /// @notice Error for if invalid level
    error InvalidLevel();
    /// @notice Error for if auditor has already been assigned
    error AuditorAssigned();
    /// @notice Error for if audit has not been failed
    error AuditNotFailed();
    /// @notice Error for if audit has been rolled over
    error AuditRolledOver();
    /// @notice Error for if refund condition not met
    error CanNotRefund();
    /// @notice Error for if the address is not the owner
    error NotOwner();
    /// @notice Error for if not approved auditor
    error NotApprovedAuditor();
    /// @notice Error for if not requested auditor
    error NotRequestedAuditor();
    /// @notice Error for only auditor
    error OnlyAuditor();
    /// @notice Error for only developer
    error OnlyDeveloper();
    /// @notice Error for if contract is not being audited
    error NotBeingAudited();
    /// @notice Error for if audit has not been passed
    error NotPassed();
    /// @notice Error for if feedback has already been given
    error FeedbackGiven();
    /// @notice Error for if contract is already in system
    error AlreadyInSystem();
    /// @notice Error for invalid audit result
    error InvalidResult();
    /// @notice Error for if address is not a contact
    error NotAContract();
    /// @notice Error for if collaboration has already been created
    error CollaborationAlreadyCreated();
    /// @notice Error for if trying to give away more of bounty than available
    error MoreThanCanGiveAway();
    /// @notice Error for if address already owns POD NFT
    error AlreadyOwnPOD();
    /// @notice Error for if submitting audit and does not own POD NFT
    error DoesNotOwnPODNFT();
    /// @notice Error for if auditor has max amount of audits
    error MaxAuditsInProgress();
    /// @notice Error for if roll over period is still active
    error RollOverStillActive();
    /// @notice Error for if invalid previous
    error InvalidPrevious();

    /// STRUCTS ///

    enum STATUS {
        NOTAUDITED,
        PENDING,
        PASSED,
        FAILED,
        REFUNDED
    }

    /// @notice           Details of contract
    /// @param contracts  Address of contract developer
    /// @param audited    Bool if has been add to audit
    /// @param auditId    Audit id
    struct Contract {
        address developer;
        bool audited;
        uint256 auditId;
    }

    /// @notice                  Details of audited contracts
    /// @param contracts         Contracts being audited
    /// @param auditor           Address of auditor
    /// @param developer         Address of developer
    /// @param status            Status of audit
    /// @param auditDescription  Description of audit results
    /// @param deadline          Deadline auditor has to complete audit
    /// @param feedback          Bool if feedback has been given to auditor
    struct Audit {
        address[] contracts;
        address auditor;
        address developer;
        STATUS status;
        string auditDescription;
        uint256 deadline;
        bool feedback;
    }

    /// @notice                  Details of auditor
    /// @param auditsInProgress  Number of audits in progress
    /// @param positiveFeedback  Number of positive feedback for auditor
    /// @param negativeFeedbac   Number of negative feedback for auditor
    /// @param mintedLevel       Minted level for auditor
    struct Auditor {
        uint256 auditsInProgress;
        uint256 positiveFeedback;
        uint256 negativeFeedback;
        uint256 mintedLevel;
    }

    /// STATE VARIABLES ///

    /// @notice Fee percent for Hyacinth
    uint256 public constant HYACINTH_FEE = 25;
    /// @notice Fee amount to mint POD NFT
    uint256 public constant POD_MINT_FEE = 100000000;
    /// @notice 30 days to complete audit or can refund
    uint256 public constant AUDIT_DEADLINE = 30 days;
    /// @notice Max number of audits an auditor can pick up at one time
    uint256 public maxAuditsForAuditor;
    /// @notice Amount of time dev has to roll over audit until auditor can claim bounty
    uint256 public timeToRollOver;
    /// @notice Amount of audits in system
    uint256 public auditId;

    /// @notice Address of owner
    address public owner;

    /// @notice Address of previous POD
    address public immutable previousPOD;
    /// @notice Address of hyacinth wallet
    address public immutable hyacinthWallet;
    /// @notice Address of USDC
    address public immutable USDC;
    /// @notice Address of proof of developer NFT
    IProofOfDeveloper public immutable proofOfDeveloper;
    /// @notice Address of proof of auditor NFT
    IProofOfAuditor public immutable proofOfAuditor;

    /// @notice Amount of audits completed at each level for auditor
    mapping(address => uint256[4]) internal _levelsCompleted;

    /// @notice Contract details for contract address
    mapping(address => Contract) public contracts;
    /// @notice Audit details of address
    mapping(uint256 => Audit) public audits;
    /// @notice Auditor details of auditor
    mapping(address => Auditor) public auditors;
    /// @notice Bool if address is an approved auditor
    mapping(address => bool) public approvedAuditor;
    /// @notice Percent of bounty given to collaborators
    mapping(uint256 => uint256) public percentGivenForCollab;
    /// @notice Time rollover of bounty is active till
    mapping(uint256 => uint256) public timeRollOverActive;
    /// @notice Developer wallet contract of developer
    mapping(address => address) public developerWalletContract;
    /// @notice Address failed audit rolled over to
    mapping(uint256 => uint256) public rolledOverAudit;
    /// @notice Array of collaborators for audit id
    mapping(uint256 => address[]) public collaborators;
    /// @notice Array of fees collaborators receive
    mapping(uint256 => uint256[]) public collaboratorsPercentOfBounty;
    /// @notice Bounty percent for collaberation of an audit id of a collaborator
    mapping(uint256 => mapping(address => uint256)) public collaborationPercent;
    /// @notice Bool if address requested to be auditor of audit id
    mapping(uint256 => mapping(address => bool)) public requestToBeAuditor;

    /// CONSTRUCTOR ///

    /// @param hyacinthWallet_  Address of hyacinth wallet
    /// @param owner_           Address of owner
    /// @param pod_             Address of proof of developer NFT
    /// @param poa_             Address of proof of auditor NFT
    /// @param usdc_            Address of USDC
    /// @param previousPOD_     Address of previous proof of developer
    constructor(
        address hyacinthWallet_,
        address owner_,
        address pod_,
        address poa_,
        address usdc_,
        address previousPOD_
    ) {
        hyacinthWallet = hyacinthWallet_;
        owner = owner_;
        proofOfDeveloper = IProofOfDeveloper(pod_);
        proofOfAuditor = IProofOfAuditor(poa_);
        USDC = usdc_;
        previousPOD = previousPOD_;
    }

    /// AUDIT FUNCTION ///

    /// @notice               Function that creates audit
    /// @param beingAudited_  Array of addresses to have be audited (If 0 - Off chain audit)
    /// @param previous_      Previous audit id if rolling over
    /// @param bountyAmount_  Starting bounty amount
    /// @return auditId_      Id of audit created
    function createAudit(
        address[] calldata beingAudited_,
        uint256 previous_,
        uint256 bountyAmount_
    ) external returns (uint256 auditId_) {
        if (proofOfDeveloper.balanceOf(msg.sender) == 0) revert DoesNotOwnPODNFT();

        ++auditId;
        auditId_ = auditId;

        if (beingAudited_.length > 0) {
            for (uint i; i < beingAudited_.length; ++i) {
                Contract memory contract_ = contracts[beingAudited_[i]];
                if (contract_.audited) revert AlreadyInSystem();
                if (contract_.developer != msg.sender) revert OnlyDeveloper();
                contracts[beingAudited_[i]].audited = true;
                contracts[beingAudited_[i]].auditId = auditId_;
            }

            if (
                previous_ != 0 &&
                (timeRollOverActive[previous_] <= block.timestamp || audits[previous_].developer != msg.sender)
            ) revert InvalidPrevious();

            if (previous_ != 0) {
                audits[auditId_].auditor = audits[previous_].auditor;
                audits[auditId_].deadline = block.timestamp + AUDIT_DEADLINE;
                collaborators[auditId_] = collaborators[previous_];
                collaboratorsPercentOfBounty[auditId_] = collaboratorsPercentOfBounty[previous_];
                percentGivenForCollab[auditId_] = percentGivenForCollab[previous_];
                rolledOverAudit[previous_] = auditId_;
                IDeveloperWallet(developerWalletContract[msg.sender]).rollOverBounty(previous_, auditId_);
            }

            audits[auditId_].contracts = beingAudited_;
        }

        audits[auditId_].developer = msg.sender;
        audits[auditId_].status = STATUS.PENDING;

        if (bountyAmount_ > 0) {
            address devWallet_ = developerWalletContract[msg.sender];
            IERC20(USDC).transferFrom(msg.sender, devWallet_, bountyAmount_);
            IDeveloperWallet(devWallet_).addToBounty(auditId_, bountyAmount_, false, USDC);
        }

        emit AuditCreated(auditId_, previous_, msg.sender, beingAudited_);
    }

    /// @notice  Called upon contract being deployed to be audited
    function beingAudited() external {
        if (proofOfDeveloper.balanceOf(tx.origin) == 0) revert DoesNotOwnPODNFT();
        if (msg.sender == tx.origin) revert NotAContract();
        Contract memory contract_ = contracts[msg.sender];
        if (contract_.developer != address(0)) revert AlreadyInSystem();
        contracts[msg.sender].developer = tx.origin;
    }

    /// DEVELOPER FUNCTION ///

    /// @notice                   Function that allow address to mint POD NFT
    /// @return id_               POD id minted
    /// @return developerWallet_  Address of developer wallet contract
    function mintPOD() external returns (uint256 id_, address developerWallet_) {
        if (previousPOD == address(0) || IERC721(previousPOD).balanceOf(msg.sender) == 0)
            IERC20(USDC).transferFrom(msg.sender, hyacinthWallet, POD_MINT_FEE);
        if (proofOfDeveloper.balanceOf(msg.sender) > 0) revert AlreadyOwnPOD();
        else (id_, developerWallet_) = proofOfDeveloper.mint(msg.sender);
        developerWalletContract[msg.sender] = developerWallet_;

        emit PODMinted(msg.sender, id_);
    }

    /// @notice           Function that allows developer to give feedback to auditor
    /// @param auditId_   Audit id feedback given for
    /// @param positive_  Bool if positive or negative feedback
    function giveAuditorFeedback(uint256 auditId_, bool positive_) external {
        Audit memory audit_ = audits[auditId_];

        if (audit_.status != STATUS.PASSED) revert NotPassed();
        if (audit_.developer != msg.sender) revert OnlyDeveloper();
        if (audit_.feedback) revert FeedbackGiven();

        audits[auditId_].feedback = true;

        if (positive_) ++auditors[audit_.auditor].positiveFeedback;
        else ++auditors[audit_.auditor].negativeFeedback;

        emit AuditFeedBackGiven(auditId_, audit_.auditor, audit_.developer, positive_);
    }

    /// @notice           Function that allows developer to get a refund for bounty if no auditor or past deadline
    /// @param auditId_   Audit id to get refund for
    function refundBounty(uint256 auditId_) external {
        Audit memory audit_ = audits[auditId_];
        if (audit_.developer != msg.sender) revert OnlyDeveloper();
        if ((audit_.auditor != address(0) && audit_.deadline > block.timestamp) || audit_.status != STATUS.PENDING)
            revert CanNotRefund();

        audits[auditId_].status = STATUS.REFUNDED;

        address devWallet_ = developerWalletContract[msg.sender];
        IDeveloperWallet(devWallet_).refundBounty(auditId_);

        emit BountyRefunded(msg.sender, auditId_);
    }

    /// @notice          Function that allows developer to accept propose auditor
    /// @param auditId_  Audit Id of audit developer is accepting `auditor_` for
    /// @param auditor_  Address being accepted as auditor for `auditId_`
    function acceptAuditor(uint256 auditId_, address auditor_) external {
        if (audits[auditId_].developer != msg.sender) revert OnlyDeveloper();
        if (audits[auditId_].auditor != address(0)) revert AuditorAssigned();
        if (maxAuditsForAuditor <= auditors[auditor_].auditsInProgress) revert MaxAuditsInProgress();
        if (!requestToBeAuditor[auditId_][auditor_]) revert NotRequestedAuditor();

        ++auditors[auditor_].auditsInProgress;
        audits[auditId_].auditor = auditor_;
        audits[auditId_].deadline = block.timestamp + AUDIT_DEADLINE;

        emit AuditorAccepted(msg.sender, auditor_, auditId_);
    }

    /// AUDITOR FUNCTION ///

    /// @notice          Function that allows approved auditor to request to audit
    /// @param auditId_  Audit id auditor is requesting to audit
    function requestToAudit(uint256 auditId_) external {
        if (audits[auditId_].status != STATUS.PENDING) revert NotBeingAudited();
        if (audits[auditId_].auditor != address(0)) revert AuditorAssigned();
        if (!approvedAuditor[msg.sender]) revert NotApprovedAuditor();
        if (maxAuditsForAuditor <= auditors[msg.sender].auditsInProgress) revert MaxAuditsInProgress();

        requestToBeAuditor[auditId_][msg.sender] = true;

        emit AuditorRequest(msg.sender, auditId_);
    }

    /// @notice              Auditor submits the `result_` of `auditId_`
    /// @param auditId_      Audit Id of audit having `result_` submitted
    /// @param result_       Result of the audit
    /// @param description_  Desecription of the audit
    function submitResult(uint256 auditId_, STATUS result_, string memory description_) external {
        Audit memory audit_ = audits[auditId_];
        if (audit_.status != STATUS.PENDING) revert NotBeingAudited();
        if (audit_.auditor != msg.sender) revert OnlyAuditor();
        if (result_ != STATUS.PASSED && result_ != STATUS.FAILED) revert InvalidResult();
        audit_.status = result_;
        audit_.auditDescription = description_;
        audits[auditId_] = audit_;

        if (result_ == STATUS.PASSED) {
            uint256 level_ = _payBounty(auditId_, developerWalletContract[audit_.developer]);
            ++_levelsCompleted[audit_.auditor][level_];
        } else {
            timeRollOverActive[auditId_] = block.timestamp + timeToRollOver;
        }

        emit ResultSubmitted(audit_.auditor, audit_.developer, auditId_, result_);
    }

    /// @notice          Function that pays out bounty if roll over has expired
    /// @param auditId_  Audit id to pay out bounty for
    function rollOverExpired(uint256 auditId_) external {
        Audit memory audit_ = audits[auditId_];
        if (audit_.status != STATUS.FAILED) revert AuditNotFailed();
        if (audit_.auditor != msg.sender) revert OnlyAuditor();
        if (timeRollOverActive[auditId_] > block.timestamp) revert RollOverStillActive();
        if (rolledOverAudit[auditId_] != 0) revert AuditRolledOver();

        _payBounty(auditId_, developerWalletContract[audit_.developer]);
    }

    /// @notice                  Function that allows an auditor to propose a collaboration
    /// @param auditId_          Audit id
    /// @param collaborator_     Address of collaborator
    /// @param percentOfBounty_  Percent of bounty `collaborator_` will receive
    function createCollaboration(uint256 auditId_, address collaborator_, uint256 percentOfBounty_) external {
        Audit memory audit_ = audits[auditId_];
        if (audit_.status != STATUS.PENDING) revert NotBeingAudited();
        if (audit_.auditor != msg.sender) revert OnlyAuditor();
        if (!approvedAuditor[collaborator_]) revert NotApprovedAuditor();
        if (percentGivenForCollab[auditId_] + percentOfBounty_ > 100) revert MoreThanCanGiveAway();

        uint256 collaborationPercent_ = collaborationPercent[auditId_][collaborator_];
        if (collaborationPercent_ > 0) revert CollaborationAlreadyCreated();

        collaborationPercent[auditId_][collaborator_] = percentOfBounty_;

        percentGivenForCollab[auditId_] += percentOfBounty_;
        collaborators[auditId_].push(collaborator_);
        collaboratorsPercentOfBounty[auditId_].push(percentOfBounty_);

        emit CollaborationCreated(auditId_, collaborator_, percentOfBounty_);
    }

    /// OWNER FUNCTION ///

    /// @notice           Transfer ownership of contract
    /// @param newOwner_  Address of the new owner
    function transferOwnership(address newOwner_) external {
        if (msg.sender != owner) revert NotOwner();
        address oldOwner_ = owner;
        owner = newOwner_;

        emit OwnershipTransferred(oldOwner_, newOwner_);
    }

    /// @notice                 Set roll over time for failed audit
    /// @param timeToRollOver_  New roll over time for failed audit
    function setTimeToRollOver(uint256 timeToRollOver_) external {
        if (msg.sender != owner) revert NotOwner();
        uint256 oldPeriod_ = timeToRollOver;
        timeToRollOver = timeToRollOver_;

        emit TimeToRollOverSet(oldPeriod_, timeToRollOver_);
    }

    /// @notice            Set max number of audits
    /// @param maxAudits_  New max number of audits for auditor
    function setMaxAuditsForAuditor(uint256 maxAudits_) external {
        if (msg.sender != owner) revert NotOwner();
        uint256 oldMax_ = maxAuditsForAuditor;
        maxAuditsForAuditor = maxAudits_;

        emit MaxAuditsSet(oldMax_, maxAudits_);
    }

    /// @notice           Add auditor
    /// @param auditor_   Address to add as auditor
    /// @param baseLevel_  Base level to give `auditor_`
    /// @return id_       Id of POA for `auditor_`
    function addAuditor(address auditor_, uint256 baseLevel_) external returns (uint256 id_) {
        if (msg.sender != owner) revert NotOwner();
        if (baseLevel_ > 3) revert InvalidLevel();

        if (proofOfAuditor.balanceOf(auditor_) == 0) {
            id_ = proofOfAuditor.mint(auditor_);
        } else id_ = proofOfAuditor.idHeld(auditor_);

        auditors[auditor_].mintedLevel = baseLevel_;
        approvedAuditor[auditor_] = true;

        emit AuditorAdded(auditor_);
    }

    /// @notice          Remove auditor
    /// @param auditor_  Address to remove as auditor
    function removeAuditor(address auditor_) external {
        if (msg.sender != owner) revert NotOwner();
        approvedAuditor[auditor_] = false;

        emit AuditorRemoved(auditor_);
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice                  Internal function that pays out bounty
    /// @param auditId_          Bounty Id to pay bounty out for
    /// @param developerWallet_  Developer wallet contract
    function _payBounty(uint256 auditId_, address developerWallet_) internal returns (uint256 level_) {
        address[] memory collaborators_ = collaborators[auditId_];
        uint256[] memory percentsOfBounty_ = collaboratorsPercentOfBounty[auditId_];

        level_ = IDeveloperWallet(developerWallet_).payOutBounty(auditId_, collaborators_, percentsOfBounty_);

        --auditors[msg.sender].auditsInProgress;
    }

    /// EXTERNAL VIEW FUNCTIONS ///

    /// @notice                   Returns amount of audits completed at each level for `auditorAdderss_`
    /// @param auditorAddress_    Address of auditor
    /// @return levelsCompleted_  Array of levels of audits completed for `auditorAddress_`
    function levelsCompleted(address auditorAddress_) external view returns (uint256[4] memory levelsCompleted_) {
        return (_levelsCompleted[auditorAddress_]);
    }

    /// @notice                   Returns audit status for `contractAddress_`
    /// @param contractAddress_   Contract address to check audit status for
    /// @return status_           Audit status of `contractAddress_`
    function auditStatus(address contractAddress_) external view returns (STATUS status_) {
        Contract memory contract_ = contracts[contractAddress_];
        if (contract_.audited) status_ = audits[contract_.auditId].status;
    }
}

pragma solidity ^0.8.0;

interface IDeveloperWallet {
    function payOutBounty(
        uint256 auditId_,
        address[] calldata collaborators_,
        uint256[] calldata percentsOfBounty_
    ) external returns (uint256 level_);

    function rollOverBounty(uint256 previous_, uint256 new_) external;

    function refundBounty(uint256 auditId_) external;

    function currentBountyLevel(uint256 auditId_) external view returns (uint256 level_, uint256 bounty_);

    function addToBounty(uint256 auditId_, uint256 amount_, bool transfer_, address token_) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IProofOfAuditor is IERC721 {
    function mint(address auditor_) external returns (uint256 id_);

    function idHeld(address auditor_) external view returns (uint256 id_);

    function level(uint256 tokenId_) external view returns (uint256 level_);
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IProofOfDeveloper is IERC721 {
    function mint(address developer_) external returns (uint256 id_, address developerWallet_);

    function idHeld(address developer_) external view returns (uint256 id_);
}