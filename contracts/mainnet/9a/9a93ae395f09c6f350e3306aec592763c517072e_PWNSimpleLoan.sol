// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { MultiToken, IMultiTokenCategoryRegistry } from "MultiToken/MultiToken.sol";

import { Math } from "openzeppelin/utils/math/Math.sol";
import { SafeCast } from "openzeppelin/utils/math/SafeCast.sol";

import { PWNConfig } from "pwn/config/PWNConfig.sol";
import { PWNHub } from "pwn/hub/PWNHub.sol";
import { PWNHubTags } from "pwn/hub/PWNHubTags.sol";
import { IERC5646 } from "pwn/interfaces/IERC5646.sol";
import { IPoolAdapter } from "pwn/interfaces/IPoolAdapter.sol";
import { IPWNLoanMetadataProvider } from "pwn/interfaces/IPWNLoanMetadataProvider.sol";
import { PWNFeeCalculator } from "pwn/loan/lib/PWNFeeCalculator.sol";
import { PWNSignatureChecker } from "pwn/loan/lib/PWNSignatureChecker.sol";
import { PWNSimpleLoanProposal } from "pwn/loan/terms/simple/proposal/PWNSimpleLoanProposal.sol";
import { PWNLOAN } from "pwn/loan/token/PWNLOAN.sol";
import { Permit, InvalidPermitOwner, InvalidPermitAsset } from "pwn/loan/vault/Permit.sol";
import { PWNVault } from "pwn/loan/vault/PWNVault.sol";
import { PWNRevokedNonce } from "pwn/nonce/PWNRevokedNonce.sol";
import { Expired, AddressMissingHubTag } from "pwn/PWNErrors.sol";


/**
 * @title PWN Simple Loan
 * @notice Contract managing a simple loan in PWN protocol.
 * @dev Acts as a vault for every loan created by this contract.
 */
contract PWNSimpleLoan is PWNVault, IERC5646, IPWNLoanMetadataProvider {
    using MultiToken for address;

    string public constant VERSION = "1.2";

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    uint32 public constant MIN_LOAN_DURATION = 10 minutes;
    uint40 public constant MAX_ACCRUING_INTEREST_APR = 16e6; // 160,000 APR (with 2 decimals)

    uint256 public constant ACCRUING_INTEREST_APR_DECIMALS = 1e2;
    uint256 public constant MINUTES_IN_YEAR = 525_600; // Note: Assuming 365 days in a year
    uint256 public constant ACCRUING_INTEREST_APR_DENOMINATOR = ACCRUING_INTEREST_APR_DECIMALS * MINUTES_IN_YEAR * 100;

    uint256 public constant MAX_EXTENSION_DURATION = 90 days;
    uint256 public constant MIN_EXTENSION_DURATION = 1 days;

    bytes32 public constant EXTENSION_PROPOSAL_TYPEHASH = keccak256(
        "ExtensionProposal(uint256 loanId,address compensationAddress,uint256 compensationAmount,uint40 duration,uint40 expiration,address proposer,uint256 nonceSpace,uint256 nonce)"
    );

    bytes32 public immutable DOMAIN_SEPARATOR = keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("PWNSimpleLoan"),
        keccak256(abi.encodePacked(VERSION)),
        block.chainid,
        address(this)
    ));

    PWNHub public immutable hub;
    PWNLOAN public immutable loanToken;
    PWNConfig public immutable config;
    PWNRevokedNonce public immutable revokedNonce;
    IMultiTokenCategoryRegistry public immutable categoryRegistry;

    /**
     * @notice Struct defining a simple loan terms.
     * @dev This struct is created by proposal contracts and never stored.
     * @param lender Address of a lender.
     * @param borrower Address of a borrower.
     * @param duration Loan duration in seconds.
     * @param collateral Asset used as a loan collateral. For a definition see { MultiToken dependency lib }.
     * @param credit Asset used as a loan credit. For a definition see { MultiToken dependency lib }.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens. It is the minimum amount of interest which has to be paid by a borrower.
     * @param accruingInterestAPR Accruing interest APR with 2 decimals.
     * @param lenderSpecHash Hash of a lender specification.
     * @param borrowerSpecHash Hash of a borrower specification.
     */
    struct Terms {
        address lender;
        address borrower;
        uint32 duration;
        MultiToken.Asset collateral;
        MultiToken.Asset credit;
        uint256 fixedInterestAmount;
        uint24 accruingInterestAPR;
        bytes32 lenderSpecHash;
        bytes32 borrowerSpecHash;
    }

    /**
     * @notice Loan proposal specification during loan creation.
     * @param proposalContract Address of a loan proposal contract.
     * @param proposalData Encoded proposal data that is passed to the loan proposal contract.
     * @param proposalInclusionProof Inclusion proof of the proposal in the proposal contract.
     * @param signature Signature of the proposal.
     */
    struct ProposalSpec {
        address proposalContract;
        bytes proposalData;
        bytes32[] proposalInclusionProof;
        bytes signature;
    }

    /**
     * @notice Lender specification during loan creation.
     * @param sourceOfFunds Address of a source of funds. This can be the lenders address, if the loan is funded directly,
     *                      or a pool address from with the funds are withdrawn on the lenders behalf.
     */
    struct LenderSpec {
        address sourceOfFunds;
    }

    /**
     * @notice Caller specification during loan creation.
     * @param refinancingLoanId Id of a loan to be refinanced. 0 if creating a new loan.
     * @param revokeNonce Flag if the callers nonce should be revoked.
     * @param nonce Callers nonce to be revoked. Nonce is revoked from the current nonce space.
     * @param permitData Callers permit data for a loans credit asset.
     */
    struct CallerSpec {
        uint256 refinancingLoanId;
        bool revokeNonce;
        uint256 nonce;
        bytes permitData;
    }

    /**
     * @notice Struct defining a simple loan.
     * @param status 0 == none/dead || 2 == running/accepted offer/accepted request || 3 == paid back || 4 == expired.
     * @param creditAddress Address of an asset used as a loan credit.
     * @param originalSourceOfFunds Address of a source of funds that was used to fund the loan.
     * @param startTimestamp Unix timestamp (in seconds) of a start date.
     * @param defaultTimestamp Unix timestamp (in seconds) of a default date.
     * @param borrower Address of a borrower.
     * @param originalLender Address of a lender that funded the loan.
     * @param accruingInterestAPR Accruing interest APR with 2 decimals.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens.
     *                            It is the minimum amount of interest which has to be paid by a borrower.
     *                            This property is reused to store the final interest amount if the loan is repaid and waiting to be claimed.
     * @param principalAmount Principal amount in credit asset tokens.
     * @param collateral Asset used as a loan collateral. For a definition see { MultiToken dependency lib }.
     */
    struct LOAN {
        uint8 status;
        address creditAddress;
        address originalSourceOfFunds;
        uint40 startTimestamp;
        uint40 defaultTimestamp;
        address borrower;
        address originalLender;
        uint24 accruingInterestAPR;
        uint256 fixedInterestAmount;
        uint256 principalAmount;
        MultiToken.Asset collateral;
    }

    /**
     * Mapping of all LOAN data by loan id.
     */
    mapping (uint256 => LOAN) private LOANs;

    /**
     * @notice Struct defining a loan extension proposal that can be signed by a borrower or a lender.
     * @param loanId Id of a loan to be extended.
     * @param compensationAddress Address of a compensation asset.
     * @param compensationAmount Amount of a compensation asset that a borrower has to pay to a lender.
     * @param duration Duration of the extension in seconds.
     * @param expiration Unix timestamp (in seconds) of an expiration date.
     * @param proposer Address of a proposer that signed the extension proposal.
     * @param nonceSpace Nonce space of the extension proposal nonce.
     * @param nonce Nonce of the extension proposal.
     */
    struct ExtensionProposal {
        uint256 loanId;
        address compensationAddress;
        uint256 compensationAmount;
        uint40 duration;
        uint40 expiration;
        address proposer;
        uint256 nonceSpace;
        uint256 nonce;
    }

    /**
     * Mapping of extension proposals made via on-chain transaction by extension hash.
     */
    mapping (bytes32 => bool) public extensionProposalsMade;


    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Emitted when a new loan in created.
     */
    event LOANCreated(uint256 indexed loanId, bytes32 indexed proposalHash, address indexed proposalContract, uint256 refinancingLoanId, Terms terms, LenderSpec lenderSpec, bytes extra);

    /**
     * @notice Emitted when a loan is paid back.
     */
    event LOANPaidBack(uint256 indexed loanId);

    /**
     * @notice Emitted when a repaid or defaulted loan is claimed.
     */
    event LOANClaimed(uint256 indexed loanId, bool indexed defaulted);

    /**
     * @notice Emitted when a LOAN token holder extends a loan.
     */
    event LOANExtended(uint256 indexed loanId, uint40 originalDefaultTimestamp, uint40 extendedDefaultTimestamp);

    /**
     * @notice Emitted when a loan extension proposal is made.
     */
    event ExtensionProposalMade(bytes32 indexed extensionHash, address indexed proposer,  ExtensionProposal proposal);


    /*----------------------------------------------------------*|
    |*  # ERRORS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Thrown when managed loan is running.
     */
    error LoanNotRunning();

    /**
     * @notice Thrown when manged loan is still running.
     */
    error LoanRunning();

    /**
     * @notice Thrown when managed loan is repaid.
     */
    error LoanRepaid();

    /**
     * @notice Thrown when managed loan is defaulted.
     */
    error LoanDefaulted(uint40);

    /**
     * @notice Thrown when loan doesn't exist.
     */
    error NonExistingLoan();

    /**
     * @notice Thrown when caller is not a LOAN token holder.
     */
    error CallerNotLOANTokenHolder();

    /**
     * @notice Thrown when refinancing loan terms have different borrower than the original loan.
     */
    error RefinanceBorrowerMismatch(address currentBorrower, address newBorrower);

    /**
     * @notice Thrown when refinancing loan terms have different credit asset than the original loan.
     */
    error RefinanceCreditMismatch();

    /**
     * @notice Thrown when refinancing loan terms have different collateral asset than the original loan.
     */
    error RefinanceCollateralMismatch();

    /**
     * @notice Thrown when hash of provided lender spec doesn't match the one in loan terms.
     */
    error InvalidLenderSpecHash(bytes32 current, bytes32 expected);

    /**
     * @notice Thrown when loan duration is below the minimum.
     */
    error InvalidDuration(uint256 current, uint256 limit);

    /**
     * @notice Thrown when accruing interest APR is above the maximum.
     */
    error InterestAPROutOfBounds(uint256 current, uint256 limit);

    /**
     * @notice Thrown when caller is not a vault.
     */
    error CallerNotVault();

    /**
     * @notice Thrown when pool based source of funds doesn't have a registered adapter.
     */
    error InvalidSourceOfFunds(address sourceOfFunds);

    /**
     * @notice Thrown when caller is not a loan borrower or lender.
     */
    error InvalidExtensionCaller();

    /**
     * @notice Thrown when signer is not a loan extension proposer.
     */
    error InvalidExtensionSigner(address allowed, address current);

    /**
     * @notice Thrown when loan extension duration is out of bounds.
     */
    error InvalidExtensionDuration(uint256 duration, uint256 limit);

    /**
     * @notice Thrown when MultiToken.Asset is invalid.
     * @dev Could be because of invalid category, address, id or amount.
     */
    error InvalidMultiTokenAsset(uint8 category, address addr, uint256 id, uint256 amount);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(
        address _hub,
        address _loanToken,
        address _config,
        address _revokedNonce,
        address _categoryRegistry
    ) {
        hub = PWNHub(_hub);
        loanToken = PWNLOAN(_loanToken);
        config = PWNConfig(_config);
        revokedNonce = PWNRevokedNonce(_revokedNonce);
        categoryRegistry = IMultiTokenCategoryRegistry(_categoryRegistry);
    }


    /*----------------------------------------------------------*|
    |*  # LENDER SPEC                                           *|
    |*----------------------------------------------------------*/

    /**
     * @notice Get hash of a lender specification.
     * @param lenderSpec Lender specification struct.
     * @return Hash of a lender specification.
     */
    function getLenderSpecHash(LenderSpec calldata lenderSpec) public pure returns (bytes32) {
        return keccak256(abi.encode(lenderSpec));
    }


    /*----------------------------------------------------------*|
    |*  # CREATE LOAN                                           *|
    |*----------------------------------------------------------*/

    /**
     * @notice Create a new loan.
     * @dev The function assumes a prior token approval to a contract address or signed permits.
     * @param proposalSpec Proposal specification struct.
     * @param lenderSpec Lender specification struct.
     * @param callerSpec Caller specification struct.
     * @param extra Auxiliary data that are emitted in the loan creation event. They are not used in the contract logic.
     * @return loanId Id of the created LOAN token.
     */
    function createLOAN(
        ProposalSpec calldata proposalSpec,
        LenderSpec calldata lenderSpec,
        CallerSpec calldata callerSpec,
        bytes calldata extra
    ) external returns (uint256 loanId) {
        // Check provided proposal contract
        if (!hub.hasTag(proposalSpec.proposalContract, PWNHubTags.LOAN_PROPOSAL)) {
            revert AddressMissingHubTag({ addr: proposalSpec.proposalContract, tag: PWNHubTags.LOAN_PROPOSAL });
        }

        // Revoke nonce if needed
        if (callerSpec.revokeNonce) {
            revokedNonce.revokeNonce(msg.sender, callerSpec.nonce);
        }

        // If refinancing a loan, check that the loan can be repaid
        if (callerSpec.refinancingLoanId != 0) {
            LOAN storage loan = LOANs[callerSpec.refinancingLoanId];
            _checkLoanCanBeRepaid(loan.status, loan.defaultTimestamp);
        }

        // Accept proposal and get loan terms
        (bytes32 proposalHash, Terms memory loanTerms) = PWNSimpleLoanProposal(proposalSpec.proposalContract)
            .acceptProposal({
                acceptor: msg.sender,
                refinancingLoanId: callerSpec.refinancingLoanId,
                proposalData: proposalSpec.proposalData,
                proposalInclusionProof: proposalSpec.proposalInclusionProof,
                signature: proposalSpec.signature
            });

        // Check that provided lender spec is correct
        if (msg.sender != loanTerms.lender && loanTerms.lenderSpecHash != getLenderSpecHash(lenderSpec)) {
            revert InvalidLenderSpecHash({ current: loanTerms.lenderSpecHash, expected: getLenderSpecHash(lenderSpec) });
        }

        // Check minimum loan duration
        if (loanTerms.duration < MIN_LOAN_DURATION) {
            revert InvalidDuration({ current: loanTerms.duration, limit: MIN_LOAN_DURATION });
        }

        // Check maximum accruing interest APR
        if (loanTerms.accruingInterestAPR > MAX_ACCRUING_INTEREST_APR) {
            revert InterestAPROutOfBounds({ current: loanTerms.accruingInterestAPR, limit: MAX_ACCRUING_INTEREST_APR });
        }

        if (callerSpec.refinancingLoanId == 0) {
            // Check loan credit and collateral validity
            _checkValidAsset(loanTerms.credit);
            _checkValidAsset(loanTerms.collateral);
        } else {
            // Check refinance loan terms
            _checkRefinanceLoanTerms(callerSpec.refinancingLoanId, loanTerms);
        }

        // Create a new loan
        loanId = _createLoan({
            loanTerms: loanTerms,
            lenderSpec: lenderSpec
        });

        emit LOANCreated({
            loanId: loanId,
            proposalHash: proposalHash,
            proposalContract: proposalSpec.proposalContract,
            refinancingLoanId: callerSpec.refinancingLoanId,
            terms: loanTerms,
            lenderSpec: lenderSpec,
            extra: extra
        });

        // Execute permit for the caller
        if (callerSpec.permitData.length > 0) {
            Permit memory permit = abi.decode(callerSpec.permitData, (Permit));
            _checkPermit(msg.sender, loanTerms.credit.assetAddress, permit);
            _tryPermit(permit);
        }

        // Settle the loan
        if (callerSpec.refinancingLoanId == 0) {
            // Transfer collateral to Vault and credit to borrower
            _settleNewLoan(loanTerms, lenderSpec);
        } else {
            // Update loan to repaid state
            _updateRepaidLoan(callerSpec.refinancingLoanId);

            // Repay the original loan and transfer the surplus to the borrower if any
            _settleLoanRefinance({
                refinancingLoanId: callerSpec.refinancingLoanId,
                loanTerms: loanTerms,
                lenderSpec: lenderSpec
            });
        }
    }

    /**
     * @notice Check that permit data have correct owner and asset.
     * @param caller Caller address.
     * @param creditAddress Address of a credit to be used.
     * @param permit Permit to be checked.
     */
    function _checkPermit(address caller, address creditAddress, Permit memory permit) private pure {
        if (permit.asset != address(0)) {
            if (permit.owner != caller) {
                revert InvalidPermitOwner({ current: permit.owner, expected: caller });
            }
            if (permit.asset != creditAddress) {
                revert InvalidPermitAsset({ current: permit.asset, expected: creditAddress });
            }
        }
    }

    /**
     * @notice Check if the loan terms are valid for refinancing.
     * @dev The function will revert if the loan terms are not valid for refinancing.
     * @param loanId Original loan id.
     * @param loanTerms Refinancing loan terms struct.
     */
    function _checkRefinanceLoanTerms(uint256 loanId, Terms memory loanTerms) private view {
        LOAN storage loan = LOANs[loanId];

        // Check that the credit asset is the same as in the original loan
        // Note: Address check is enough because the asset has always ERC20 category and zero id.
        // Amount can be different, but nonzero.
        if (
            loan.creditAddress != loanTerms.credit.assetAddress ||
            loanTerms.credit.amount == 0
        ) revert RefinanceCreditMismatch();

        // Check that the collateral is identical to the original one
        if (
            loan.collateral.category != loanTerms.collateral.category ||
            loan.collateral.assetAddress != loanTerms.collateral.assetAddress ||
            loan.collateral.id != loanTerms.collateral.id ||
            loan.collateral.amount != loanTerms.collateral.amount
        ) revert RefinanceCollateralMismatch();

        // Check that the borrower is the same as in the original loan
        if (loan.borrower != loanTerms.borrower) {
            revert RefinanceBorrowerMismatch({
                currentBorrower: loan.borrower,
                newBorrower: loanTerms.borrower
            });
        }
    }

    /**
     * @notice Mint LOAN token and store loan data under loan id.
     * @param loanTerms Loan terms struct.
     * @param lenderSpec Lender specification struct.
     */
    function _createLoan(
        Terms memory loanTerms,
        LenderSpec calldata lenderSpec
    ) private returns (uint256 loanId) {
        // Mint LOAN token for lender
        loanId = loanToken.mint(loanTerms.lender);

        // Store loan data under loan id
        LOAN storage loan = LOANs[loanId];
        loan.status = 2;
        loan.creditAddress = loanTerms.credit.assetAddress;
        loan.originalSourceOfFunds = lenderSpec.sourceOfFunds;
        loan.startTimestamp = uint40(block.timestamp);
        loan.defaultTimestamp = uint40(block.timestamp) + loanTerms.duration;
        loan.borrower = loanTerms.borrower;
        loan.originalLender = loanTerms.lender;
        loan.accruingInterestAPR = loanTerms.accruingInterestAPR;
        loan.fixedInterestAmount = loanTerms.fixedInterestAmount;
        loan.principalAmount = loanTerms.credit.amount;
        loan.collateral = loanTerms.collateral;
    }

    /**
     * @notice Transfer collateral to Vault and credit to borrower.
     * @dev The function assumes a prior token approval to a contract address or signed permits.
     * @param loanTerms Loan terms struct.
     */
    function _settleNewLoan(
        Terms memory loanTerms,
        LenderSpec calldata lenderSpec
    ) private {
        // Transfer collateral to Vault
        _pull(loanTerms.collateral, loanTerms.borrower);

        // Lender is not the source of funds
        if (lenderSpec.sourceOfFunds != loanTerms.lender) {
            // Withdraw credit asset to the lender first
            _withdrawCreditFromPool(loanTerms.credit, loanTerms, lenderSpec);
        }

        // Calculate fee amount and new loan amount
        (uint256 feeAmount, uint256 newLoanAmount)
            = PWNFeeCalculator.calculateFeeAmount(config.fee(), loanTerms.credit.amount);

        // Note: `creditHelper` must not be used before updating the amount.
        MultiToken.Asset memory creditHelper = loanTerms.credit;

        // Collect fees
        if (feeAmount > 0) {
            creditHelper.amount = feeAmount;
            _pushFrom(creditHelper, loanTerms.lender, config.feeCollector());
        }

        // Transfer credit to borrower
        creditHelper.amount = newLoanAmount;
        _pushFrom(creditHelper, loanTerms.lender, loanTerms.borrower);
    }

    /**
     * @notice Settle the refinanced loan. If the new lender is the same as the current LOAN owner,
     *         the function will transfer only the surplus to the borrower, if any.
     *         If the new loan amount is not enough to cover the original loan, the borrower needs to contribute.
     *         The function assumes a prior token approval to a contract address or signed permits.
     * @param refinancingLoanId Id of a loan to be refinanced.
     * @param loanTerms Loan terms struct.
     * @param lenderSpec Lender specification struct.
     */
    function _settleLoanRefinance(
        uint256 refinancingLoanId,
        Terms memory loanTerms,
        LenderSpec calldata lenderSpec
    ) private {
        LOAN storage loan = LOANs[refinancingLoanId];
        address loanOwner = loanToken.ownerOf(refinancingLoanId);
        uint256 repaymentAmount = loanRepaymentAmount(refinancingLoanId);

        // Calculate fee amount and new loan amount
        (uint256 feeAmount, uint256 newLoanAmount)
            = PWNFeeCalculator.calculateFeeAmount(config.fee(), loanTerms.credit.amount);

        uint256 common = Math.min(repaymentAmount, newLoanAmount);
        uint256 surplus = newLoanAmount > repaymentAmount ? newLoanAmount - repaymentAmount : 0;
        uint256 shortage = surplus > 0 ? 0 : repaymentAmount - newLoanAmount;

        // Note: New lender will always transfer common loan amount to the Vault, except when:
        // - the new lender is the current loan owner but not the original lender
        // - the new lender is the current loan owner, is the original lender, and the new and original source of funds are equal

        bool shouldTransferCommon =
            loanTerms.lender != loanOwner ||
            (loan.originalLender == loanOwner && loan.originalSourceOfFunds != lenderSpec.sourceOfFunds);

        // Note: `creditHelper` must not be used before updating the amount.
        MultiToken.Asset memory creditHelper = loanTerms.credit;

        // Lender is not the source of funds
        if (lenderSpec.sourceOfFunds != loanTerms.lender) {
            // Withdraw credit asset to the lender first
            creditHelper.amount = feeAmount + (shouldTransferCommon ? common : 0) + surplus;
            _withdrawCreditFromPool(creditHelper, loanTerms, lenderSpec);
        }

        // Collect fees
        if (feeAmount > 0) {
            creditHelper.amount = feeAmount;
            _pushFrom(creditHelper, loanTerms.lender, config.feeCollector());
        }

        // Transfer common amount to the Vault if necessary
        if (shouldTransferCommon) {
            creditHelper.amount = common;
            _pull(creditHelper, loanTerms.lender);
        }

        // Handle the surplus or the shortage
        if (surplus > 0) {
            // New loan covers the whole original loan, transfer surplus to the borrower
            creditHelper.amount = surplus;
            _pushFrom(creditHelper, loanTerms.lender, loanTerms.borrower);
        } else if (shortage > 0) {
            // New loan covers only part of the original loan, borrower needs to contribute
            creditHelper.amount = shortage;
            _pull(creditHelper, loanTerms.borrower);
        }

        // Try to repay directly
        try this.tryClaimRepaidLOAN({
            loanId: refinancingLoanId,
            creditAmount: (shouldTransferCommon ? common : 0) + shortage,
            loanOwner: loanOwner
        }) {} catch {
            // Note: Safe transfer or supply to a pool can fail. In that case the LOAN token stays in repaid state and
            // waits for the LOAN token owner to claim the repaid credit. Otherwise lender would be able to prevent
            // anybody from repaying the loan.
        }
    }

    /**
     * @notice Withdraw a credit asset from a pool to the Vault.
     * @dev The function will revert if pool doesn't have registered pool adapter.
     * @param credit Asset to be pulled from the pool.
     * @param loanTerms Loan terms struct.
     * @param lenderSpec Lender specification struct.
     */
    function _withdrawCreditFromPool(
        MultiToken.Asset memory credit,
        Terms memory loanTerms,
        LenderSpec calldata lenderSpec
    ) private {
        IPoolAdapter poolAdapter = config.getPoolAdapter(lenderSpec.sourceOfFunds);
        if (address(poolAdapter) == address(0)) {
            revert InvalidSourceOfFunds({ sourceOfFunds: lenderSpec.sourceOfFunds });
        }

        if (credit.amount > 0) {
            _withdrawFromPool(credit, poolAdapter, lenderSpec.sourceOfFunds, loanTerms.lender);
        }
    }


    /*----------------------------------------------------------*|
    |*  # REPAY LOAN                                            *|
    |*----------------------------------------------------------*/

    /**
     * @notice Repay running loan.
     * @dev Any address can repay a running loan, but a collateral will be transferred to a borrower address associated with the loan.
     *      If the LOAN token holder is the same as the original lender, the repayment credit asset will be
     *      transferred to the LOAN token holder directly. Otherwise it will transfer the repayment credit asset to
     *      a vault, waiting on a LOAN token holder to claim it. The function assumes a prior token approval to a contract address
     *      or a signed permit.
     * @param loanId Id of a loan that is being repaid.
     * @param permitData Callers credit permit data.
     */
    function repayLOAN(
        uint256 loanId,
        bytes calldata permitData
    ) external {
        LOAN storage loan = LOANs[loanId];

        _checkLoanCanBeRepaid(loan.status, loan.defaultTimestamp);

        // Update loan to repaid state
        _updateRepaidLoan(loanId);

        // Execute permit for the caller
        if (permitData.length > 0) {
            Permit memory permit = abi.decode(permitData, (Permit));
            _checkPermit(msg.sender, loan.creditAddress, permit);
            _tryPermit(permit);
        }

        // Transfer the repaid credit to the Vault
        uint256 repaymentAmount = loanRepaymentAmount(loanId);
        _pull(loan.creditAddress.ERC20(repaymentAmount), msg.sender);

        // Transfer collateral back to borrower
        _push(loan.collateral, loan.borrower);

        // Try to repay directly
        try this.tryClaimRepaidLOAN(loanId, repaymentAmount, loanToken.ownerOf(loanId)) {} catch {
            // Note: Safe transfer or supply to a pool can fail. In that case leave the LOAN token in repaid state and
            // wait for the LOAN token owner to claim the repaid credit. Otherwise lender would be able to prevent
            // borrower from repaying the loan.
        }
    }

    /**
     * @notice Check if the loan can be repaid.
     * @dev The function will revert if the loan cannot be repaid.
     * @param status Loan status.
     * @param defaultTimestamp Loan default timestamp.
     */
    function _checkLoanCanBeRepaid(uint8 status, uint40 defaultTimestamp) private view {
        // Check that loan exists and is not from a different loan contract
        if (status == 0)
            revert NonExistingLoan();
        // Check that loan is running
        if (status != 2)
            revert LoanNotRunning();
        // Check that loan is not defaulted
        if (defaultTimestamp <= block.timestamp)
            revert LoanDefaulted(defaultTimestamp);
    }

    /**
     * @notice Update loan to repaid state.
     * @param loanId Id of a loan that is being repaid.
     */
    function _updateRepaidLoan(uint256 loanId) private {
        LOAN storage loan = LOANs[loanId];

        // Move loan to repaid state and wait for the loan owner to claim the repaid credit
        loan.status = 3;

        // Update accrued interest amount
        loan.fixedInterestAmount = _loanAccruedInterest(loan);
        loan.accruingInterestAPR = 0;

        // Note: Reusing `fixedInterestAmount` to store accrued interest at the time of repayment
        // to have the value at the time of claim and stop accruing new interest.

        emit LOANPaidBack({ loanId: loanId });
    }


    /*----------------------------------------------------------*|
    |*  # LOAN REPAYMENT AMOUNT                                 *|
    |*----------------------------------------------------------*/

    /**
     * @notice Calculate the loan repayment amount with fixed and accrued interest.
     * @param loanId Id of a loan.
     * @return Repayment amount.
     */
    function loanRepaymentAmount(uint256 loanId) public view returns (uint256) {
        LOAN storage loan = LOANs[loanId];

        // Check non-existent loan
        if (loan.status == 0) return 0;

        // Return loan principal with accrued interest
        return loan.principalAmount + _loanAccruedInterest(loan);
    }

    /**
     * @notice Calculate the loan accrued interest.
     * @param loan Loan data struct.
     * @return Accrued interest amount.
     */
    function _loanAccruedInterest(LOAN storage loan) private view returns (uint256) {
        if (loan.accruingInterestAPR == 0)
            return loan.fixedInterestAmount;

        uint256 accruingMinutes = (block.timestamp - loan.startTimestamp) / 1 minutes;
        uint256 accruedInterest = Math.mulDiv(
            loan.principalAmount, uint256(loan.accruingInterestAPR) * accruingMinutes, ACCRUING_INTEREST_APR_DENOMINATOR
        );
        return loan.fixedInterestAmount + accruedInterest;
    }


    /*----------------------------------------------------------*|
    |*  # CLAIM LOAN                                            *|
    |*----------------------------------------------------------*/

    /**
     * @notice Claim a repaid or defaulted loan.
     * @dev Only a LOAN token holder can claim a repaid or defaulted loan.
     *      Claim will transfer the repaid credit or collateral to a LOAN token holder address and burn the LOAN token.
     * @param loanId Id of a loan that is being claimed.
     */
    function claimLOAN(uint256 loanId) external {
        LOAN storage loan = LOANs[loanId];

        // Check that caller is LOAN token holder
        if (loanToken.ownerOf(loanId) != msg.sender)
            revert CallerNotLOANTokenHolder();

        if (loan.status == 0)
            // Loan is not existing or from a different loan contract
            revert NonExistingLoan();
        else if (loan.status == 3)
            // Loan has been paid back
            _settleLoanClaim({ loanId: loanId, loanOwner: msg.sender, defaulted: false });
        else if (loan.status == 2 && loan.defaultTimestamp <= block.timestamp)
            // Loan is running but expired
            _settleLoanClaim({ loanId: loanId, loanOwner: msg.sender, defaulted: true });
        else
            // Loan is in wrong state
            revert LoanRunning();
    }

    /**
     * @notice Try to claim a repaid loan for the loan owner.
     * @dev The function is called by the vault to repay a loan directly to the original lender or its source of funds
     *      if the loan owner is the original lender. If the transfer fails, the LOAN token will remain in repaid state
     *      and the LOAN token owner will be able to claim the repaid credit. Otherwise lender would be able to prevent
     *      borrower from repaying the loan.
     * @param loanId Id of a loan that is being claimed.
     * @param creditAmount Amount of a credit to be claimed.
     * @param loanOwner Address of the LOAN token holder.
     */
    function tryClaimRepaidLOAN(uint256 loanId, uint256 creditAmount, address loanOwner) external {
        if (msg.sender != address(this))
            revert CallerNotVault();

        LOAN storage loan = LOANs[loanId];

        if (loan.status != 3)
            return;

        // If current loan owner is not original lender, the loan cannot be repaid directly, return without revert.
        if (loan.originalLender != loanOwner)
            return;

        // Note: The loan owner is the original lender at this point.

        address destinationOfFunds = loan.originalSourceOfFunds;
        MultiToken.Asset memory repaymentCredit = loan.creditAddress.ERC20(creditAmount);

        // Delete loan data & burn LOAN token before calling safe transfer
        _deleteLoan(loanId);

        emit LOANClaimed({ loanId: loanId, defaulted: false });

        // End here if the credit amount is zero
        if (creditAmount == 0)
            return;

        // Note: Zero credit amount can happen when the loan is refinanced by the original lender.

        // Repay the original lender
        if (destinationOfFunds == loanOwner) {
            _push(repaymentCredit, loanOwner);
        } else {
            IPoolAdapter poolAdapter = config.getPoolAdapter(destinationOfFunds);
            // Check that pool has registered adapter
            if (address(poolAdapter) == address(0)) {

                // Note: Adapter can be unregistered during the loan lifetime, so the pool might not have an adapter.
                // In that case, the loan owner will be able to claim the repaid credit.

                revert InvalidSourceOfFunds({ sourceOfFunds: destinationOfFunds });
            }

            // Supply the repaid credit to the original pool
            _supplyToPool(repaymentCredit, poolAdapter, destinationOfFunds, loanOwner);
        }

        // Note: If the transfer fails, the LOAN token will remain in repaid state and the LOAN token owner
        // will be able to claim the repaid credit. Otherwise lender would be able to prevent borrower from
        // repaying the loan.
    }

    /**
     * @notice Settle the loan claim.
     * @param loanId Id of a loan that is being claimed.
     * @param loanOwner Address of the LOAN token holder.
     * @param defaulted If the loan is defaulted.
     */
    function _settleLoanClaim(uint256 loanId, address loanOwner, bool defaulted) private {
        LOAN storage loan = LOANs[loanId];

        // Store in memory before deleting the loan
        MultiToken.Asset memory asset = defaulted
            ? loan.collateral
            : loan.creditAddress.ERC20(loanRepaymentAmount(loanId));

        // Delete loan data & burn LOAN token before calling safe transfer
        _deleteLoan(loanId);

        emit LOANClaimed({ loanId: loanId, defaulted: defaulted });

        // Transfer asset to current LOAN token owner
        _push(asset, loanOwner);
    }

    /**
     * @notice Delete loan data and burn LOAN token.
     * @param loanId Id of a loan that is being deleted.
     */
    function _deleteLoan(uint256 loanId) private {
        loanToken.burn(loanId);
        delete LOANs[loanId];
    }


    /*----------------------------------------------------------*|
    |*  # EXTEND LOAN                                           *|
    |*----------------------------------------------------------*/

    /**
     * @notice Make an on-chain extension proposal.
     * @param extension Extension proposal struct.
     */
    function makeExtensionProposal(ExtensionProposal calldata extension) external {
        // Check that caller is a proposer
        if (msg.sender != extension.proposer)
            revert InvalidExtensionSigner({ allowed: extension.proposer, current: msg.sender });

        // Mark extension proposal as made
        bytes32 extensionHash = getExtensionHash(extension);
        extensionProposalsMade[extensionHash] = true;

        emit ExtensionProposalMade(extensionHash, extension.proposer, extension);
    }

    /**
     * @notice Extend loans default date with signed extension proposal signed by borrower or LOAN token owner.
     * @dev The function assumes a prior token approval to a contract address or a signed permit.
     * @param extension Extension proposal struct.
     * @param signature Signature of the extension proposal.
     * @param permitData Callers credit permit data.
     */
    function extendLOAN(
        ExtensionProposal calldata extension,
        bytes calldata signature,
        bytes calldata permitData
    ) external {
        LOAN storage loan = LOANs[extension.loanId];

        // Check that loan is in the right state
        if (loan.status == 0)
            revert NonExistingLoan();
        if (loan.status == 3) // cannot extend repaid loan
            revert LoanRepaid();

        // Check extension validity
        bytes32 extensionHash = getExtensionHash(extension);
        if (!extensionProposalsMade[extensionHash])
            if (!PWNSignatureChecker.isValidSignatureNow(extension.proposer, extensionHash, signature))
                revert PWNSignatureChecker.InvalidSignature({ signer: extension.proposer, digest: extensionHash });

        // Check extension expiration
        if (block.timestamp >= extension.expiration)
            revert Expired({ current: block.timestamp, expiration: extension.expiration });

        // Check extension nonce
        if (!revokedNonce.isNonceUsable(extension.proposer, extension.nonceSpace, extension.nonce))
            revert PWNRevokedNonce.NonceNotUsable({
                addr: extension.proposer,
                nonceSpace: extension.nonceSpace,
                nonce: extension.nonce
            });

        // Check caller and signer
        address loanOwner = loanToken.ownerOf(extension.loanId);
        if (msg.sender == loanOwner) {
            if (extension.proposer != loan.borrower) {
                // If caller is loan owner, proposer must be borrower
                revert InvalidExtensionSigner({
                    allowed: loan.borrower,
                    current: extension.proposer
                });
            }
        } else if (msg.sender == loan.borrower) {
            if (extension.proposer != loanOwner) {
                // If caller is borrower, proposer must be loan owner
                revert InvalidExtensionSigner({
                    allowed: loanOwner,
                    current: extension.proposer
                });
            }
        } else {
            // Caller must be loan owner or borrower
            revert InvalidExtensionCaller();
        }

        // Check duration range
        if (extension.duration < MIN_EXTENSION_DURATION)
            revert InvalidExtensionDuration({
                duration: extension.duration,
                limit: MIN_EXTENSION_DURATION
            });
        if (extension.duration > MAX_EXTENSION_DURATION)
            revert InvalidExtensionDuration({
                duration: extension.duration,
                limit: MAX_EXTENSION_DURATION
            });

        // Revoke extension proposal nonce
        revokedNonce.revokeNonce(extension.proposer, extension.nonceSpace, extension.nonce);

        // Update loan
        uint40 originalDefaultTimestamp = loan.defaultTimestamp;
        loan.defaultTimestamp = originalDefaultTimestamp + extension.duration;

        // Emit event
        emit LOANExtended({
            loanId: extension.loanId,
            originalDefaultTimestamp: originalDefaultTimestamp,
            extendedDefaultTimestamp: loan.defaultTimestamp
        });

        // Skip compensation transfer if it's not set
        if (extension.compensationAddress != address(0) && extension.compensationAmount > 0) {
            MultiToken.Asset memory compensation = extension.compensationAddress.ERC20(extension.compensationAmount);

            // Check compensation asset validity
            _checkValidAsset(compensation);

            // Transfer compensation to the loan owner
            if (permitData.length > 0) {
                Permit memory permit = abi.decode(permitData, (Permit));
                _checkPermit(msg.sender, extension.compensationAddress, permit);
                _tryPermit(permit);
            }
            _pushFrom(compensation, loan.borrower, loanOwner);
        }
    }

    /**
     * @notice Get the hash of the extension struct.
     * @param extension Extension proposal struct.
     * @return Hash of the extension struct.
     */
    function getExtensionHash(ExtensionProposal calldata extension) public view returns (bytes32) {
        return keccak256(abi.encodePacked(
            hex"1901",
            DOMAIN_SEPARATOR,
            keccak256(abi.encodePacked(
                EXTENSION_PROPOSAL_TYPEHASH,
                abi.encode(extension)
            ))
        ));
    }


    /*----------------------------------------------------------*|
    |*  # GET LOAN                                              *|
    |*----------------------------------------------------------*/

    /**
     * @notice Return a LOAN data struct associated with a loan id.
     * @param loanId Id of a loan in question.
     * @return status LOAN status.
     * @return startTimestamp Unix timestamp (in seconds) of a loan creation date.
     * @return defaultTimestamp Unix timestamp (in seconds) of a loan default date.
     * @return borrower Address of a loan borrower.
     * @return originalLender Address of a loan original lender.
     * @return loanOwner Address of a LOAN token holder.
     * @return accruingInterestAPR Accruing interest APR with 2 decimal places.
     * @return fixedInterestAmount Fixed interest amount in credit asset tokens.
     * @return credit Asset used as a loan credit. For a definition see { MultiToken dependency lib }.
     * @return collateral Asset used as a loan collateral. For a definition see { MultiToken dependency lib }.
     * @return originalSourceOfFunds Address of a source of funds for the loan. Original lender address, if the loan was funded directly, or a pool address from witch credit funds were withdrawn / borrowred.
     * @return repaymentAmount Loan repayment amount in credit asset tokens.
     */
    function getLOAN(uint256 loanId) external view returns (
        uint8 status,
        uint40 startTimestamp,
        uint40 defaultTimestamp,
        address borrower,
        address originalLender,
        address loanOwner,
        uint24 accruingInterestAPR,
        uint256 fixedInterestAmount,
        MultiToken.Asset memory credit,
        MultiToken.Asset memory collateral,
        address originalSourceOfFunds,
        uint256 repaymentAmount
    ) {
        LOAN storage loan = LOANs[loanId];

        status = _getLOANStatus(loanId);
        startTimestamp = loan.startTimestamp;
        defaultTimestamp = loan.defaultTimestamp;
        borrower = loan.borrower;
        originalLender = loan.originalLender;
        loanOwner = loan.status != 0 ? loanToken.ownerOf(loanId) : address(0);
        accruingInterestAPR = loan.accruingInterestAPR;
        fixedInterestAmount = loan.fixedInterestAmount;
        credit = loan.creditAddress.ERC20(loan.principalAmount);
        collateral = loan.collateral;
        originalSourceOfFunds = loan.originalSourceOfFunds;
        repaymentAmount = loanRepaymentAmount(loanId);
    }

    /**
     * @notice Return a LOAN status associated with a loan id.
     * @param loanId Id of a loan in question.
     * @return status LOAN status.
     */
    function _getLOANStatus(uint256 loanId) private view returns (uint8) {
        LOAN storage loan = LOANs[loanId];
        return (loan.status == 2 && loan.defaultTimestamp <= block.timestamp) ? 4 : loan.status;
    }


    /*----------------------------------------------------------*|
    |*  # MultiToken                                            *|
    |*----------------------------------------------------------*/

    /**
     * @notice Check if the asset is valid with the MultiToken dependency lib and the category registry.
     * @dev See MultiToken.isValid for more details.
     * @param asset Asset to be checked.
     * @return True if the asset is valid.
     */
    function isValidAsset(MultiToken.Asset memory asset) public view returns (bool) {
        return MultiToken.isValid(asset, categoryRegistry);
    }

    /**
     * @notice Check if the asset is valid with the MultiToken lib and the category registry.
     * @dev The function will revert if the asset is not valid.
     * @param asset Asset to be checked.
     */
    function _checkValidAsset(MultiToken.Asset memory asset) private view {
        if (!isValidAsset(asset)) {
            revert InvalidMultiTokenAsset({
                category: uint8(asset.category),
                addr: asset.assetAddress,
                id: asset.id,
                amount: asset.amount
            });
        }
    }


    /*----------------------------------------------------------*|
    |*  # IPWNLoanMetadataProvider                              *|
    |*----------------------------------------------------------*/

    /**
     * @inheritdoc IPWNLoanMetadataProvider
     */
    function loanMetadataUri() override external view returns (string memory) {
        return config.loanMetadataUri(address(this));
    }


    /*----------------------------------------------------------*|
    |*  # ERC5646                                               *|
    |*----------------------------------------------------------*/

    /**
     * @inheritdoc IERC5646
     */
    function getStateFingerprint(uint256 tokenId) external view virtual override returns (bytes32) {
        LOAN storage loan = LOANs[tokenId];

        if (loan.status == 0)
            return bytes32(0);

        // The only mutable state properties are:
        // - status: updated for expired loans based on block.timestamp
        // - defaultTimestamp: updated when the loan is extended
        // - fixedInterestAmount: updated when the loan is repaid and waiting to be claimed
        // - accruingInterestAPR: updated when the loan is repaid and waiting to be claimed
        // Others don't have to be part of the state fingerprint as it does not act as a token identification.
        return keccak256(abi.encode(
            _getLOANStatus(tokenId),
            loan.defaultTimestamp,
            loan.fixedInterestAmount,
            loan.accruingInterestAPR
        ));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "openzeppelin/interfaces/IERC20.sol";
import { IERC721 } from "openzeppelin/interfaces/IERC721.sol";
import { IERC1155 } from "openzeppelin/interfaces/IERC1155.sol";
import { IERC20Permit } from "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import { SafeERC20 } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { ERC165Checker } from "openzeppelin/utils/introspection/ERC165Checker.sol";

import { ICryptoKitties } from "multitoken/interfaces/ICryptoKitties.sol";
import { IMultiTokenCategoryRegistry } from "multitoken/interfaces/IMultiTokenCategoryRegistry.sol";


/**
 * @title MultiToken library
 * @dev Library for handling various token standards (ERC20, ERC721, ERC1155, CryptoKitties) in a single contract.
 */
library MultiToken {
    using ERC165Checker for address;
    using SafeERC20 for IERC20;

    bytes4 public constant ERC20_INTERFACE_ID = 0x36372b07;
    bytes4 public constant ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 public constant ERC1155_INTERFACE_ID = 0xd9b67a26;
    bytes4 public constant CRYPTO_KITTIES_INTERFACE_ID = 0x9a20483d;

    /**
    * @notice A reserved value for a category not registered.
    */
    uint8 public constant CATEGORY_NOT_REGISTERED = type(uint8).max;

    /**
     * @title Category
     * @dev Enum representation Asset category.
     */
    enum Category {
        ERC20,
        ERC721,
        ERC1155,
        CryptoKitties
    }

    /**
     * @title Asset
     * @param category Corresponding asset category.
     * @param assetAddress Address of the token contract defining the asset.
     * @param id TokenID of an NFT or 0.
     * @param amount Amount of fungible tokens or 0 -> 1.
     */
    struct Asset {
        Category category;
        address assetAddress;
        uint256 id;
        uint256 amount;
    }

    /**
     * @notice Thrown when unsupported category is used.
     * @param categoryValue Value of the unsupported category.
     */
    error UnsupportedCategory(uint8 categoryValue);

    /*----------------------------------------------------------*|
    |*  # FACTORY FUNCTIONS                                     *|
    |*----------------------------------------------------------*/

    /**
     * @notice Factory function for creating an ERC20 asset.
     * @param assetAddress Address of the token contract defining the asset.
     * @param amount Amount of fungible tokens.
     * @return Asset struct representing the ERC20 asset.
     */
    function ERC20(address assetAddress, uint256 amount) internal pure returns (Asset memory) {
        return Asset(Category.ERC20, assetAddress, 0, amount);
    }

    /**
     * @notice Factory function for creating an ERC721 asset.
     * @param assetAddress Address of the token contract defining the asset.
     * @param id Token id of an NFT.
     * @return Asset struct representing the ERC721 asset.
     */
    function ERC721(address assetAddress, uint256 id) internal pure returns (Asset memory) {
        return Asset(Category.ERC721, assetAddress, id, 0);
    }

    /**
     * @notice Factory function for creating an ERC1155 asset.
     * @param assetAddress Address of the token contract defining the asset.
     * @param id Token id of an SFT.
     * @param amount Amount of semifungible tokens.
     * @return Asset struct representing the ERC1155 asset.
     */
    function ERC1155(address assetAddress, uint256 id, uint256 amount) internal pure returns (Asset memory) {
        return Asset(Category.ERC1155, assetAddress, id, amount);
    }

    /**
     * @notice Factory function for creating an ERC1155 NFT asset.
     * @param assetAddress Address of the token contract defining the asset.
     * @param id Token id of an NFT.
     * @return Asset struct representing the ERC1155 NFT asset.
     */
    function ERC1155(address assetAddress, uint256 id) internal pure returns (Asset memory) {
        return Asset(Category.ERC1155, assetAddress, id, 0);
    }

    /**
     * @notice Factory function for creating a CryptoKitties asset.
     * @param assetAddress Address of the token contract defining the asset.
     * @param id Token id of a CryptoKitty.
     * @return Asset struct representing the CryptoKitties asset.
     */
    function CryptoKitties(address assetAddress, uint256 id) internal pure returns (Asset memory) {
        return Asset(Category.CryptoKitties, assetAddress, id, 0);
    }


    /*----------------------------------------------------------*|
    |*  # TRANSFER ASSET                                        *|
    |*----------------------------------------------------------*/

    /**
     * @notice Wrapping function for `transferFrom` calls on various token interfaces.
     * @dev If `source` is `address(this)`, function `transfer` is called instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function transferAssetFrom(Asset memory asset, address source, address dest) internal {
        _transferAssetFrom(asset, source, dest, false);
    }

    /**
     * @notice Wrapping function for `safeTransferFrom` calls on various token interfaces.
     * @dev If `source` is `address(this)`, function `transfer` is called instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function safeTransferAssetFrom(Asset memory asset, address source, address dest) internal {
        _transferAssetFrom(asset, source, dest, true);
    }

    function _transferAssetFrom(Asset memory asset, address source, address dest, bool isSafe) private {
        if (asset.category == Category.ERC20) {
            if (source == address(this))
                IERC20(asset.assetAddress).safeTransfer(dest, asset.amount);
            else
                IERC20(asset.assetAddress).safeTransferFrom(source, dest, asset.amount);

        } else if (asset.category == Category.ERC721) {
            if (!isSafe)
                IERC721(asset.assetAddress).transferFrom(source, dest, asset.id);
            else
                IERC721(asset.assetAddress).safeTransferFrom(source, dest, asset.id, "");

        } else if (asset.category == Category.ERC1155) {
            IERC1155(asset.assetAddress).safeTransferFrom(source, dest, asset.id, asset.amount == 0 ? 1 : asset.amount, "");

        } else if (asset.category == Category.CryptoKitties) {
            if (source == address(this))
                ICryptoKitties(asset.assetAddress).transfer(dest, asset.id);
            else
                ICryptoKitties(asset.assetAddress).transferFrom(source, dest, asset.id);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }

    /**
     * @notice Get amount of asset that would be transferred.
     * @dev NFTs (ERC721, CryptoKitties & ERC1155 with amount 0) with return 1.
     *      Fungible tokens will return its amount (ERC20 with 0 amount is valid).
     *      In combination with `balanceOf` can be used to check successful asset transfer.
     * @param asset Struct defining all necessary context of a token.
     * @return Number of tokens that would be transferred of the asset.
     */
    function getTransferAmount(Asset memory asset) internal pure returns (uint256) {
        if (asset.category == Category.ERC20)
            return asset.amount;
        else if (asset.category == Category.ERC1155 && asset.amount > 0)
            return asset.amount;
        else // Return 1 for ERC721, CryptoKitties and ERC1155 used as NFTs (amount = 0)
            return 1;
    }


    /*----------------------------------------------------------*|
    |*  # TRANSFER ASSET CALLDATA                               *|
    |*----------------------------------------------------------*/

    /**
     * @notice Wrapping function for `transferFrom` calladata on various token interfaces.
     * @dev If `fromSender` is true, function `transfer` is returned instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function transferAssetFromCalldata(Asset memory asset, address source, address dest, bool fromSender) pure internal returns (bytes memory) {
        return _transferAssetFromCalldata(asset, source, dest, fromSender, false);
    }

    /**
     * @notice Wrapping function for `safeTransferFrom` calladata on various token interfaces.
     * @dev If `fromSender` is true, function `transfer` is returned instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function safeTransferAssetFromCalldata(Asset memory asset, address source, address dest, bool fromSender) pure internal returns (bytes memory) {
        return _transferAssetFromCalldata(asset, source, dest, fromSender, true);
    }

    function _transferAssetFromCalldata(Asset memory asset, address source, address dest, bool fromSender, bool isSafe) pure private returns (bytes memory) {
        if (asset.category == Category.ERC20) {
            if (fromSender) {
                return abi.encodeWithSignature(
                    "transfer(address,uint256)", dest, asset.amount
                );
            } else {
                return abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)", source, dest, asset.amount
                );
            }
        } else if (asset.category == Category.ERC721) {
            if (!isSafe) {
                return abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)", source, dest, asset.id
                );
            } else {
                return abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,bytes)", source, dest, asset.id, ""
                );
            }

        } else if (asset.category == Category.ERC1155) {
            return abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)", source, dest, asset.id, asset.amount == 0 ? 1 : asset.amount, ""
            );

        } else if (asset.category == Category.CryptoKitties) {
            if (fromSender) {
                return abi.encodeWithSignature(
                    "transfer(address,uint256)", dest, asset.id
                );
            } else {
                return abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)", source, dest, asset.id
                );
            }

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # PERMIT                                                *|
    |*----------------------------------------------------------*/

    /**
     * @notice Wrapping function for granting approval via permit signature.
     * @param asset Struct defining all necessary context of a token.
     * @param owner Account/address that signed the permit.
     * @param spender Account/address that would be granted approval to `asset`.
     * @param permitData Data about permit deadline (uint256) and permit signature (64/65 bytes).
     *                   Deadline and signature should be pack encoded together.
     *                   Signature can be standard (65 bytes) or compact (64 bytes) defined in EIP-2098.
     */
    function permit(Asset memory asset, address owner, address spender, bytes memory permitData) internal {
        if (asset.category == Category.ERC20) {

            // Parse deadline and permit signature parameters
            uint256 deadline;
            bytes32 r;
            bytes32 s;
            uint8 v;

            // Parsing signature parameters used from OpenZeppelins ECDSA library
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/83277ff916ac4f58fec072b8f28a252c1245c2f1/contracts/utils/cryptography/ECDSA.sol

            // Deadline (32 bytes) + standard signature data (65 bytes) -> 97 bytes
            if (permitData.length == 97) {
                assembly {
                    deadline := mload(add(permitData, 0x20))
                    r := mload(add(permitData, 0x40))
                    s := mload(add(permitData, 0x60))
                    v := byte(0, mload(add(permitData, 0x80)))
                }
            }
            // Deadline (32 bytes) + compact signature data (64 bytes) -> 96 bytes
            else if (permitData.length == 96) {
                bytes32 vs;

                assembly {
                    deadline := mload(add(permitData, 0x20))
                    r := mload(add(permitData, 0x40))
                    vs := mload(add(permitData, 0x60))
                }

                s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                v = uint8((uint256(vs) >> 255) + 27);
            } else {
                revert("MultiToken::Permit: Invalid permit length");
            }

            // Call permit with parsed parameters
            IERC20Permit(asset.assetAddress).permit(owner, spender, asset.amount, deadline, v, r, s);

        } else {
            // Currently supporting only ERC20 signed approvals via ERC2612
            revert("MultiToken::Permit: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # BALANCE OF                                            *|
    |*----------------------------------------------------------*/

    /**
     * @notice Wrapping function for checking balances on various token interfaces.
     * @param asset Struct defining all necessary context of a token.
     * @param target Target address to be checked.
     */
    function balanceOf(Asset memory asset, address target) internal view returns (uint256) {
        if (asset.category == Category.ERC20) {
            return IERC20(asset.assetAddress).balanceOf(target);

        } else if (asset.category == Category.ERC721) {
            return IERC721(asset.assetAddress).ownerOf(asset.id) == target ? 1 : 0;

        } else if (asset.category == Category.ERC1155) {
            return IERC1155(asset.assetAddress).balanceOf(target, asset.id);

        } else if (asset.category == Category.CryptoKitties) {
            return ICryptoKitties(asset.assetAddress).ownerOf(asset.id) == target ? 1 : 0;

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # APPROVE ASSET                                         *|
    |*----------------------------------------------------------*/

    /**
     * @notice Wrapping function for `approve` calls on various token interfaces.
     * @dev By using `safeApprove` for ERC20, caller can set allowance to 0 or from 0.
     *      Cannot set non-zero value if allowance is also non-zero.
     * @param asset Struct defining all necessary context of a token.
     * @param target Account/address that would be granted approval to `asset`.
     */
    function approveAsset(Asset memory asset, address target) internal {
        if (asset.category == Category.ERC20) {
            IERC20(asset.assetAddress).safeApprove(target, asset.amount);

        } else if (asset.category == Category.ERC721) {
            IERC721(asset.assetAddress).approve(target, asset.id);

        } else if (asset.category == Category.ERC1155) {
            IERC1155(asset.assetAddress).setApprovalForAll(target, true);

        } else if (asset.category == Category.CryptoKitties) {
            ICryptoKitties(asset.assetAddress).approve(target, asset.id);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # ASSET CHECKS                                          *|
    |*----------------------------------------------------------*/

    /**
     * @notice Checks that provided asset is contract, has correct format and stated category via MultiTokenCategoryRegistry and ERC165 checks.
     * @dev Fungible tokens (ERC20) have to have id = 0.
     *      NFT (ERC721, CryptoKitties) tokens have to have amount = 0.
     *      Correct asset category is determined via ERC165.
     *      The check assumes, that asset contract implements only one token standard at a time.
     * @param registry Category registry contract.
     * @param asset Asset that is examined.
     * @return True if asset has correct format and category.
     */
    function isValid(Asset memory asset, IMultiTokenCategoryRegistry registry) internal view returns (bool) {
        return _checkCategory(asset, registry) && _checkFormat(asset);
    }

    /**
     * @notice Checks that provided asset is contract, has correct format and stated category via ERC165 checks.
     * @dev Fungible tokens (ERC20) have to have id = 0.
     *      NFT (ERC721, CryptoKitties) tokens have to have amount = 0.
     *      Correct asset category is determined via ERC165.
     *      The check assumes, that asset contract implements only one token standard at a time.
     * @param asset Asset that is examined.
     * @return True if asset has correct format and category.
     */
    function isValid(Asset memory asset) internal view returns (bool) {
        return _checkCategoryViaERC165(asset) && _checkFormat(asset);
    }

    /**
     * @notice Checks that provided asset is contract and stated category is correct via MultiTokenCategoryRegistry and ERC165 checks.
     * @dev Will fallback to ERC165 checks if asset is not registered in the category registry.
     *      The check assumes, that asset contract implements only one token standard at a time.
     * @param registry Category registry contract.
     * @param asset Asset that is examined.
     * @return True if assets stated category is correct.
     */
    function _checkCategory(Asset memory asset, IMultiTokenCategoryRegistry registry) internal view returns (bool) {
        // Check if asset is registered in the category registry
        uint8 categoryValue = registry.registeredCategoryValue(asset.assetAddress);
        if (categoryValue != CATEGORY_NOT_REGISTERED)
            return uint8(asset.category) == categoryValue;

        return _checkCategoryViaERC165(asset);
    }

    /**
     * @notice Checks that provided asset is contract and stated category is correct via ERC165 checks.
     * @dev The check assumes, that asset contract implements only one token standard at a time.
     * @param asset Asset that is examined.
     * @return True if assets stated category is correct.
     */
    function _checkCategoryViaERC165(Asset memory asset) internal view returns (bool) {
        if (asset.category == Category.ERC20) {
            // ERC20 has optional ERC165 implementation
            if (asset.assetAddress.supportsERC165()) {
                // If contract implements ERC165 and returns true for ERC20 intefrace id, consider it a correct category
                if (asset.assetAddress.supportsERC165InterfaceUnchecked(ERC20_INTERFACE_ID))
                    return true;

                // If contract implements ERC165, it has to return false for ERC721, ERC1155, and CryptoKitties interface ids
                return
                    !asset.assetAddress.supportsERC165InterfaceUnchecked(ERC721_INTERFACE_ID) &&
                    !asset.assetAddress.supportsERC165InterfaceUnchecked(ERC1155_INTERFACE_ID) &&
                    !asset.assetAddress.supportsERC165InterfaceUnchecked(CRYPTO_KITTIES_INTERFACE_ID);

            } else {
                // In case token doesn't implement ERC165, its safe to assume that provided category is correct,
                // because any other category has to implement ERC165.

                // Check that asset address is contract
                // Note: Asset address will return code length 0, if this code is called from the constructor.
                return asset.assetAddress.code.length > 0;
            }

        } else if (asset.category == Category.ERC721) {
            // Check ERC721 via ERC165
            return asset.assetAddress.supportsInterface(ERC721_INTERFACE_ID);

        } else if (asset.category == Category.ERC1155) {
            // Check ERC1155 via ERC165
            return asset.assetAddress.supportsInterface(ERC1155_INTERFACE_ID);

        } else if (asset.category == Category.CryptoKitties) {
            // Check CryptoKitties via ERC165
            return asset.assetAddress.supportsInterface(CRYPTO_KITTIES_INTERFACE_ID);

        } else {
            revert UnsupportedCategory(uint8(asset.category));
        }
    }

    /**
     * @notice Checks that provided asset has correct format.
     * @dev Fungible tokens (ERC20) have to have id = 0.
     *      NFT (ERC721, CryptoKitties) tokens have to have amount = 0.
     *      Correct asset category is determined via ERC165.
     * @param asset Asset that is examined.
     * @return True asset struct has correct format.
     */
    function _checkFormat(Asset memory asset) internal pure returns (bool) {
        if (asset.category == Category.ERC20) {
            // Id must be 0 for ERC20
            if (asset.id != 0) return false;

        } else if (asset.category == Category.ERC721) {
            // Amount must be 0 for ERC721
            if (asset.amount != 0) return false;

        } else if (asset.category == Category.ERC1155) {
            // No format check for ERC1155

        } else if (asset.category == Category.CryptoKitties) {
            // Amount must be 0 for CryptoKitties
            if (asset.amount != 0) return false;

        } else {
            revert UnsupportedCategory(uint8(asset.category));
        }

        return true;
    }

    /**
     * @notice Compare two assets, ignoring their amounts.
     * @param asset First asset to examine.
     * @param otherAsset Second asset to examine.
     * @return True if both structs represents the same asset.
     */
    function isSameAs(Asset memory asset, Asset memory otherAsset) internal pure returns (bool) {
        return
            asset.category == otherAsset.category &&
            asset.assetAddress == otherAsset.assetAddress &&
            asset.id == otherAsset.id;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { Ownable2Step } from "openzeppelin/access/Ownable2Step.sol";
import { Initializable } from "openzeppelin/proxy/utils/Initializable.sol";

import { IPoolAdapter } from "pwn/interfaces/IPoolAdapter.sol";
import { IStateFingerpringComputer } from "pwn/interfaces/IStateFingerpringComputer.sol";


/**
 * @title PWN Config
 * @notice Contract holding configurable values of PWN protocol.
 * @dev Is intended to be used as a proxy via `TransparentUpgradeableProxy`.
 */
contract PWNConfig is Ownable2Step, Initializable {

    string internal constant VERSION = "1.2";

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    uint16 public constant MAX_FEE = 1000; // 10%

    /**
     * @notice Protocol fee value in basis points.
     * @dev Value of 100 is 1% fee.
     */
    uint16 public fee;

    /**
     * @notice Address that collects protocol fees.
     */
    address public feeCollector;

    /**
     * @notice Mapping of a loan contract address to LOAN token metadata uri.
     * @dev LOAN token minted by a loan contract will return metadata uri stored in this mapping.
     *      If there is no metadata uri for a loan contract, default metadata uri will be used stored under address(0).
     */
    mapping (address => string) private _loanMetadataUri;

    /**
     * @notice Mapping holding registered state fingerprint computer to an asset.
     */
    mapping (address => address) private _sfComputerRegistry;

    /**
     * @notice Mapping holding registered pool adapter to a pool address.
     */
    mapping (address => address) private _poolAdapterRegistry;


    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Emitted when new fee value is set.
     */
    event FeeUpdated(uint16 oldFee, uint16 newFee);

    /**
     * @notice Emitted when new fee collector address is set.
     */
    event FeeCollectorUpdated(address oldFeeCollector, address newFeeCollector);

    /**
     * @notice Emitted when new LOAN token metadata uri is set.
     */
    event LOANMetadataUriUpdated(address indexed loanContract, string newUri);

    /**
     * @notice Emitted when new default LOAN token metadata uri is set.
     */
    event DefaultLOANMetadataUriUpdated(string newUri);


    /*----------------------------------------------------------*|
    |*  # ERRORS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Thrown when registering a computer which does not support the asset it is registered for.
     */
    error InvalidComputerContract(address computer, address asset);

    /**
     * @notice Thrown when trying to set a fee value higher than `MAX_FEE`.
     */
    error InvalidFeeValue(uint256 fee, uint256 limit);

    /**
     * @notice Thrown when trying to set a fee collector to zero address.
     */
    error ZeroFeeCollector();

    /**
     * @notice Thrown when trying to set a LOAN token metadata uri for zero address loan contract.
     */
    error ZeroLoanContract();


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor() Ownable2Step() {
        // PWNConfig is used as a proxy. Use initializer to setup initial properties.
        _disableInitializers();
        _transferOwnership(address(0));
    }

    function initialize(address _owner, uint16 _fee, address _feeCollector) external initializer {
        require(_owner != address(0), "Owner is zero address");
        _transferOwnership(_owner);
        _setFeeCollector(_feeCollector);
        _setFee(_fee);
    }


    /*----------------------------------------------------------*|
    |*  # FEE MANAGEMENT                                        *|
    |*----------------------------------------------------------*/

    /**
     * @notice Set new protocol fee value.
     * @param _fee New fee value in basis points. Value of 100 is 1% fee.
     */
    function setFee(uint16 _fee) external onlyOwner {
        _setFee(_fee);
    }

    /**
     * @notice Internal implementation of setting new protocol fee value.
     * @param _fee New fee value in basis points. Value of 100 is 1% fee.
     */
    function _setFee(uint16 _fee) private {
        if (_fee > MAX_FEE)
            revert InvalidFeeValue({ fee: _fee, limit: MAX_FEE });

        uint16 oldFee = fee;
        fee = _fee;
        emit FeeUpdated(oldFee, _fee);
    }

    /**
     * @notice Set new fee collector address.
     * @param _feeCollector New fee collector address.
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        _setFeeCollector(_feeCollector);
    }

    /**
     * @notice Internal implementation of setting new fee collector address.
     * @param _feeCollector New fee collector address.
     */
    function _setFeeCollector(address _feeCollector) private {
        if (_feeCollector == address(0))
            revert ZeroFeeCollector();

        address oldFeeCollector = feeCollector;
        feeCollector = _feeCollector;
        emit FeeCollectorUpdated(oldFeeCollector, _feeCollector);
    }


    /*----------------------------------------------------------*|
    |*  # LOAN METADATA                                         *|
    |*----------------------------------------------------------*/

    /**
     * @notice Set a LOAN token metadata uri for a specific loan contract.
     * @param loanContract Address of a loan contract.
     * @param metadataUri New value of LOAN token metadata uri for given `loanContract`.
     */
    function setLOANMetadataUri(address loanContract, string memory metadataUri) external onlyOwner {
        if (loanContract == address(0))
            // address(0) is used as a default metadata uri. Use `setDefaultLOANMetadataUri` to set default metadata uri.
            revert ZeroLoanContract();

        _loanMetadataUri[loanContract] = metadataUri;
        emit LOANMetadataUriUpdated(loanContract, metadataUri);
    }

    /**
     * @notice Set a default LOAN token metadata uri.
     * @param metadataUri New value of default LOAN token metadata uri.
     */
    function setDefaultLOANMetadataUri(string memory metadataUri) external onlyOwner {
        _loanMetadataUri[address(0)] = metadataUri;
        emit DefaultLOANMetadataUriUpdated(metadataUri);
    }

    /**
     * @notice Return a LOAN token metadata uri base on a loan contract that minted the token.
     * @param loanContract Address of a loan contract.
     * @return uri Metadata uri for given loan contract.
     */
    function loanMetadataUri(address loanContract) external view returns (string memory uri) {
        uri = _loanMetadataUri[loanContract];
        // If there is no metadata uri for a loan contract, use default metadata uri.
        if (bytes(uri).length == 0)
            uri = _loanMetadataUri[address(0)];
    }


    /*----------------------------------------------------------*|
    |*  # STATE FINGERPRINT COMPUTER                            *|
    |*----------------------------------------------------------*/

    /**
     * @notice Returns the state fingerprint computer for a given asset.
     * @param asset The asset for which the computer is requested.
     * @return The computer for the given asset.
     */
    function getStateFingerprintComputer(address asset) external view returns (IStateFingerpringComputer) {
        return IStateFingerpringComputer(_sfComputerRegistry[asset]);
    }

    /**
     * @notice Registers a state fingerprint computer for a given asset.
     * @param asset The asset for which the computer is registered.
     * @param computer The computer to be registered. Use address(0) to remove a computer.
     */
    function registerStateFingerprintComputer(address asset, address computer) external onlyOwner {
        if (computer != address(0))
            if (!IStateFingerpringComputer(computer).supportsToken(asset))
                revert InvalidComputerContract({ computer: computer, asset: asset });

        _sfComputerRegistry[asset] = computer;
    }


    /*----------------------------------------------------------*|
    |*  # POOL ADAPTER                                          *|
    |*----------------------------------------------------------*/

    /**
     * @notice Returns the pool adapter for a given pool.
     * @param pool The pool for which the adapter is requested.
     * @return The adapter for the given pool.
     */
    function getPoolAdapter(address pool) external view returns (IPoolAdapter) {
        return IPoolAdapter(_poolAdapterRegistry[pool]);
    }

    /**
     * @notice Registers a pool adapter for a given pool.
     * @param pool The pool for which the adapter is registered.
     * @param adapter The adapter to be registered.
     */
    function registerPoolAdapter(address pool, address adapter) external onlyOwner {
        _poolAdapterRegistry[pool] = adapter;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { Ownable2Step } from "openzeppelin/access/Ownable2Step.sol";


/**
 * @title PWN Hub
 * @notice Connects PWN contracts together into protocol via tags.
 */
contract PWNHub is Ownable2Step {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * @dev Mapping of address tags. (contract address => tag => is tagged)
     */
    mapping (address => mapping (bytes32 => bool)) private tags;


    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Emitted when tag is set for an address.
     */
    event TagSet(address indexed _address, bytes32 indexed tag, bool hasTag);


    /*----------------------------------------------------------*|
    |*  # ERRORS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Thrown when `PWNHub.setTags` inputs lengths are not equal.
     */
    error InvalidInputData();


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor() Ownable2Step() {

    }


    /*----------------------------------------------------------*|
    |*  # TAG MANAGEMENT                                        *|
    |*----------------------------------------------------------*/

    /**
     * @notice Set tag to an address.
     * @dev Tag can be added or removed via this functions. Only callable by contract owner.
     * @param _address Address to which a tag is set.
     * @param tag Tag that is set to an `_address`.
     * @param _hasTag Bool value if tag is added or removed.
     */
    function setTag(address _address, bytes32 tag, bool _hasTag) public onlyOwner {
        tags[_address][tag] = _hasTag;
        emit TagSet(_address, tag, _hasTag);
    }

    /**
     * @notice Set list of tags to an address.
     * @dev Tags can be added or removed via this functions. Only callable by contract owner.
     * @param _addresses List of addresses to which tags are set.
     * @param _tags List of tags that are set to an `_address`.
     * @param _hasTag Bool value if tags are added or removed.
     */
    function setTags(address[] memory _addresses, bytes32[] memory _tags, bool _hasTag) external onlyOwner {
        if (_addresses.length != _tags.length)
            revert InvalidInputData();

        uint256 length = _tags.length;
        for (uint256 i; i < length;) {
            setTag(_addresses[i], _tags[i], _hasTag);
            unchecked { ++i; }
        }
    }


    /*----------------------------------------------------------*|
    |*  # TAG GETTER                                            *|
    |*----------------------------------------------------------*/

    /**
     * @dev Return if an address is associated with a tag.
     * @param _address Address that is examined for a `tag`.
     * @param tag Tag that should an `_address` be associated with.
     * @return True if given address has a tag.
     */
    function hasTag(address _address, bytes32 tag) external view returns (bool) {
        return tags[_address][tag];
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

library PWNHubTags {

    string internal constant VERSION = "1.2";

    /// @dev Address can mint LOAN tokens and create LOANs via loan factory contracts.
    bytes32 internal constant ACTIVE_LOAN = keccak256("PWN_ACTIVE_LOAN");
    /// @dev Address can call loan contracts to create and/or refinance a loan.
    bytes32 internal constant LOAN_PROPOSAL = keccak256("PWN_LOAN_PROPOSAL");
    /// @dev Address can revoke nonces on other addresses behalf.
    bytes32 internal constant NONCE_MANAGER = keccak256("PWN_NONCE_MANAGER");

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title IERC5646
 * @notice Interface of the ERC5646 standard, as defined in the https://eips.ethereum.org/EIPS/eip-5646.
 */
interface IERC5646 {

    /**
     * @notice Function to return current token state fingerprint.
     * @param tokenId Id of a token state in question.
     * @return Current token state fingerprint.
     */
    function getStateFingerprint(uint256 tokenId) external view returns (bytes32);

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title IPoolAdapter
 * @notice Interface for pool adapters used to withdraw and supply assets to the pool.
 */
interface IPoolAdapter {

    /**
     * @notice Withdraw an asset from the pool on behalf of the owner.
     * @dev Withdrawn asset remains in the owner. Caller must have the ACTIVE_LOAN tag in the hub.
     * @param pool The address of the pool from which the asset is withdrawn.
     * @param owner The address of the owner from whom the asset is withdrawn.
     * @param asset The address of the asset to withdraw.
     * @param amount The amount of the asset to withdraw.
     */
    function withdraw(address pool, address owner, address asset, uint256 amount) external;

    /**
     * @notice Supply an asset to the pool on behalf of the owner.
     * @dev Need to transfer the asset to the adapter before calling this function.
     * @param pool The address of the pool to which the asset is supplied.
     * @param owner The address of the owner on whose behalf the asset is supplied.
     * @param asset The address of the asset to supply.
     * @param amount The amount of the asset to supply.
     */
    function supply(address pool, address owner, address asset, uint256 amount) external;

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title IPWNLoanMetadataProvider
 * @notice Interface for a provider of a LOAN token metadata.
 * @dev Loan contracts should implement this interface.
 */
interface IPWNLoanMetadataProvider {

    /**
     * @notice Get a loan metadata uri for a LOAN token minted by this contract.
     * @return LOAN token metadata uri.
     */
    function loanMetadataUri() external view returns (string memory);

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { Math } from "openzeppelin/utils/math/Math.sol";


/**
 * @title PWN Fee Calculator
 * @notice Library that calculates fee amount for given loan amount.
 */
library PWNFeeCalculator {

    string internal constant VERSION = "1.1";

    /**
     * @notice Compute fee amount.
     * @param fee Fee value in basis points. Value of 100 is 1% fee.
     * @param loanAmount Amount of an asset used as a loan credit.
     * @return feeAmount Amount of a loan asset that represents a protocol fee.
     * @return newLoanAmount New amount of a loan credit asset, after deducting protocol fee.
     */
    function calculateFeeAmount(uint16 fee, uint256 loanAmount) internal pure returns (uint256 feeAmount, uint256 newLoanAmount) {
        if (fee == 0)
            return (0, loanAmount);

        feeAmount = Math.mulDiv(loanAmount, fee, 1e4);
        newLoanAmount = loanAmount - feeAmount;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { ECDSA } from "openzeppelin/utils/cryptography/ECDSA.sol";
import { IERC1271 } from "openzeppelin/interfaces/IERC1271.sol";


/**
 * @title PWN Signature Checker
 * @notice Library to check if a given signature is valid for EOAs or contract accounts.
 * @dev This library is a modification of an Open-Zeppelin `SignatureChecker` library extended by a support for EIP-2098 compact signatures.
 */
library PWNSignatureChecker {

    string internal constant VERSION = "1.0";

    /**
     * @dev Thrown when signature length is not 64 nor 65 bytes.
     */
    error InvalidSignatureLength(uint256 length);

    /**
     * @dev Thrown when signature is invalid.
     */
    error InvalidSignature(address signer, bytes32 digest);

    /**
     * @dev Function will try to recover a signer of a given signature and check if is the same as given signer address.
     *      For a contract account signer address, function will check signature validity by calling `isValidSignature` function defined by EIP-1271.
     * @param signer Address that should be a `hash` signer or a signature validator, in case of a contract account.
     * @param hash Hash of a signed message that should validated.
     * @param signature Signature of a signed `hash`. Could be empty for a contract account signature validation.
     *                  Signature can be standard (65 bytes) or compact (64 bytes) defined by EIP-2098.
     * @return True if a signature is valid.
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        // Check that signature is valid for contract account
        if (signer.code.length > 0) {
            (bool success, bytes memory result) = signer.staticcall(
                abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
            );
            return
                success &&
                result.length == 32 &&
                abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector);
        }
        // Check that signature is valid for EOA
        else {
            bytes32 r;
            bytes32 s;
            uint8 v;

            // Standard signature data (65 bytes)
            if (signature.length == 65) {
                assembly {
                    r := mload(add(signature, 0x20))
                    s := mload(add(signature, 0x40))
                    v := byte(0, mload(add(signature, 0x60)))
                }
            }
            // Compact signature data (64 bytes) - see EIP-2098
            else if (signature.length == 64) {
                bytes32 vs;

                assembly {
                    r := mload(add(signature, 0x20))
                    vs := mload(add(signature, 0x40))
                }

                s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                v = uint8((uint256(vs) >> 255) + 27);
            } else {
                revert InvalidSignatureLength({ length: signature.length });
            }

            return signer == ECDSA.recover(hash, v, r, s);
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { MerkleProof } from "openzeppelin/utils/cryptography/MerkleProof.sol";
import { ERC165Checker } from "openzeppelin/utils/introspection/ERC165Checker.sol";

import { PWNConfig, IStateFingerpringComputer } from "pwn/config/PWNConfig.sol";
import { PWNHub } from "pwn/hub/PWNHub.sol";
import { PWNHubTags } from "pwn/hub/PWNHubTags.sol";
import { IERC5646 } from "pwn/interfaces/IERC5646.sol";
import { PWNSignatureChecker } from "pwn/loan/lib/PWNSignatureChecker.sol";
import { PWNSimpleLoan } from "pwn/loan/terms/simple/loan/PWNSimpleLoan.sol";
import { PWNRevokedNonce } from "pwn/nonce/PWNRevokedNonce.sol";
import { Expired, AddressMissingHubTag } from "pwn/PWNErrors.sol";

/**
 * @title PWN Simple Loan Proposal Base Contract
 * @notice Base contract of loan proposals that builds a simple loan terms.
 */
abstract contract PWNSimpleLoanProposal {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable MULTIPROPOSAL_DOMAIN_SEPARATOR;

    PWNHub public immutable hub;
    PWNRevokedNonce public immutable revokedNonce;
    PWNConfig public immutable config;

    bytes32 public constant MULTIPROPOSAL_TYPEHASH = keccak256("Multiproposal(bytes32 multiproposalMerkleRoot)");

    struct Multiproposal {
        bytes32 multiproposalMerkleRoot;
    }

    struct ProposalBase {
        address collateralAddress;
        uint256 collateralId;
        bool checkCollateralStateFingerprint;
        bytes32 collateralStateFingerprint;
        uint256 creditAmount;
        uint256 availableCreditLimit;
        uint40 expiration;
        address allowedAcceptor;
        address proposer;
        bool isOffer;
        uint256 refinancingLoanId;
        uint256 nonceSpace;
        uint256 nonce;
        address loanContract;
    }

    /**
     * @dev Mapping of proposals made via on-chain transactions.
     *      Could be used by contract wallets instead of EIP-1271.
     *      (proposal hash => is made)
     */
    mapping (bytes32 => bool) public proposalsMade;

    /**
     * @dev Mapping of credit used by a proposal with defined available credit limit.
     *      (proposal hash => credit used)
     */
    mapping (bytes32 => uint256) public creditUsed;


    /*----------------------------------------------------------*|
    |*  # ERRORS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Thrown when a caller is missing a required hub tag.
     */
    error CallerNotLoanContract(address caller, address loanContract);

    /**
     * @notice Thrown when a state fingerprint computer is not registered.
     */
    error MissingStateFingerprintComputer();

    /**
     * @notice Thrown when a proposed collateral state fingerprint doesn't match the current state.
     */
    error InvalidCollateralStateFingerprint(bytes32 current, bytes32 proposed);

    /**
     * @notice Thrown when a caller is not a stated proposer.
     */
    error CallerIsNotStatedProposer(address addr);

    /**
     * @notice Thrown when proposal acceptor and proposer are the same.
     */
    error AcceptorIsProposer(address addr);

    /**
     * @notice Thrown when provided refinance loan id cannot be used.
     */
    error InvalidRefinancingLoanId(uint256 refinancingLoanId);

    /**
     * @notice Thrown when a proposal would exceed the available credit limit.
     */
    error AvailableCreditLimitExceeded(uint256 used, uint256 limit);

    /**
     * @notice Thrown when caller is not allowed to accept a proposal.
     */
    error CallerNotAllowedAcceptor(address current, address allowed);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(
        address _hub,
        address _revokedNonce,
        address _config,
        string memory name,
        string memory version
    ) {
        hub = PWNHub(_hub);
        revokedNonce = PWNRevokedNonce(_revokedNonce);
        config = PWNConfig(_config);

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(abi.encodePacked(name)),
            keccak256(abi.encodePacked(version)),
            block.chainid,
            address(this)
        ));

        MULTIPROPOSAL_DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name)"),
            keccak256("PWNMultiproposal")
        ));
    }


    /*----------------------------------------------------------*|
    |*  # EXTERNALS                                             *|
    |*----------------------------------------------------------*/

    /**
     * @notice Get a multiproposal hash according to EIP-712.
     * @param multiproposal Multiproposal struct.
     * @return Multiproposal hash.
     */
    function getMultiproposalHash(Multiproposal memory multiproposal) public view returns (bytes32) {
        return keccak256(abi.encodePacked(
            hex"1901", MULTIPROPOSAL_DOMAIN_SEPARATOR, keccak256(abi.encodePacked(
                MULTIPROPOSAL_TYPEHASH, abi.encode(multiproposal)
            ))
        ));
    }

    /**
     * @notice Helper function for revoking a proposal nonce on behalf of a caller.
     * @param nonceSpace Nonce space of a proposal nonce to be revoked.
     * @param nonce Proposal nonce to be revoked.
     */
    function revokeNonce(uint256 nonceSpace, uint256 nonce) external {
        revokedNonce.revokeNonce(msg.sender, nonceSpace, nonce);
    }

    /**
     * @notice Accept a proposal and create new loan terms.
     * @dev Function can be called only by a loan contract with appropriate PWN Hub tag.
     * @param acceptor Address of a proposal acceptor.
     * @param refinancingLoanId Id of a loan to be refinanced. 0 if creating a new loan.
     * @param proposalData Encoded proposal data with signature.
     * @param proposalInclusionProof Multiproposal inclusion proof. Empty if single proposal.
     * @return proposalHash Proposal hash.
     * @return loanTerms Loan terms.
     */
    function acceptProposal(
        address acceptor,
        uint256 refinancingLoanId,
        bytes calldata proposalData,
        bytes32[] calldata proposalInclusionProof,
        bytes calldata signature
    ) virtual external returns (bytes32 proposalHash, PWNSimpleLoan.Terms memory loanTerms);


    /*----------------------------------------------------------*|
    |*  # INTERNALS                                             *|
    |*----------------------------------------------------------*/

    /**
     * @notice Get a proposal hash according to EIP-712.
     * @param encodedProposal Encoded proposal struct.
     * @return Struct hash.
     */
    function _getProposalHash(
        bytes32 proposalTypehash,
        bytes memory encodedProposal
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            hex"1901", DOMAIN_SEPARATOR, keccak256(abi.encodePacked(
                proposalTypehash, encodedProposal
            ))
        ));
    }

    /**
     * @notice Make an on-chain proposal.
     * @dev Function will mark a proposal hash as proposed.
     * @param proposalHash Proposal hash.
     * @param proposer Address of a proposal proposer.
     */
    function _makeProposal(bytes32 proposalHash, address proposer) internal {
        if (msg.sender != proposer) {
            revert CallerIsNotStatedProposer({ addr: proposer });
        }

        proposalsMade[proposalHash] = true;
    }

    /**
     * @notice Try to accept proposal base.
     * @param acceptor Address of a proposal acceptor.
     * @param refinancingLoanId Refinancing loan ID.
     * @param proposalHash Proposal hash.
     * @param proposalInclusionProof Multiproposal inclusion proof. Empty if single proposal.
     * @param signature Signature of a proposal.
     * @param proposal Proposal base struct.
     */
    function _acceptProposal(
        address acceptor,
        uint256 refinancingLoanId,
        bytes32 proposalHash,
        bytes32[] calldata proposalInclusionProof,
        bytes calldata signature,
        ProposalBase memory proposal
    ) internal {
        // Check loan contract
        if (msg.sender != proposal.loanContract) {
            revert CallerNotLoanContract({ caller: msg.sender, loanContract: proposal.loanContract });
        }
        if (!hub.hasTag(proposal.loanContract, PWNHubTags.ACTIVE_LOAN)) {
            revert AddressMissingHubTag({ addr: proposal.loanContract, tag: PWNHubTags.ACTIVE_LOAN });
        }

        // Check proposal signature or that it was made on-chain
        if (proposalInclusionProof.length == 0) {
            // Single proposal signature
            if (!proposalsMade[proposalHash]) {
                if (!PWNSignatureChecker.isValidSignatureNow(proposal.proposer, proposalHash, signature)) {
                    revert PWNSignatureChecker.InvalidSignature({ signer: proposal.proposer, digest: proposalHash });
                }
            }
        } else {
            // Multiproposal signature
            bytes32 multiproposalHash = getMultiproposalHash(
                Multiproposal({
                    multiproposalMerkleRoot: MerkleProof.processProofCalldata({
                        proof: proposalInclusionProof,
                        leaf: proposalHash
                    })
                })
            );
            if (!PWNSignatureChecker.isValidSignatureNow(proposal.proposer, multiproposalHash, signature)) {
                revert PWNSignatureChecker.InvalidSignature({ signer: proposal.proposer, digest: multiproposalHash });
            }
        }

        // Check proposer is not acceptor
        if (proposal.proposer == acceptor) {
            revert AcceptorIsProposer({ addr: acceptor});
        }

        // Check refinancing proposal
        if (refinancingLoanId == 0) {
            if (proposal.refinancingLoanId != 0) {
                revert InvalidRefinancingLoanId({ refinancingLoanId: proposal.refinancingLoanId });
            }
        } else {
            if (refinancingLoanId != proposal.refinancingLoanId) {
                if (proposal.refinancingLoanId != 0 || !proposal.isOffer) {
                    revert InvalidRefinancingLoanId({ refinancingLoanId: proposal.refinancingLoanId });
                }
            }
        }

        // Check proposal is not expired
        if (block.timestamp >= proposal.expiration) {
            revert Expired({ current: block.timestamp, expiration: proposal.expiration });
        }

        // Check proposal is not revoked
        if (!revokedNonce.isNonceUsable(proposal.proposer, proposal.nonceSpace, proposal.nonce)) {
            revert PWNRevokedNonce.NonceNotUsable({
                addr: proposal.proposer,
                nonceSpace: proposal.nonceSpace,
                nonce: proposal.nonce
            });
        }

        // Check propsal is accepted by an allowed address
        if (proposal.allowedAcceptor != address(0) && acceptor != proposal.allowedAcceptor) {
            revert CallerNotAllowedAcceptor({ current: acceptor, allowed: proposal.allowedAcceptor });
        }

        if (proposal.availableCreditLimit == 0) {
            // Revoke nonce if credit limit is 0, proposal can be accepted only once
            revokedNonce.revokeNonce(proposal.proposer, proposal.nonceSpace, proposal.nonce);
        } else if (creditUsed[proposalHash] + proposal.creditAmount <= proposal.availableCreditLimit) {
            // Increase used credit if credit limit is not exceeded
            creditUsed[proposalHash] += proposal.creditAmount;
        } else {
            // Revert if credit limit is exceeded
            revert AvailableCreditLimitExceeded({
                used: creditUsed[proposalHash] + proposal.creditAmount,
                limit: proposal.availableCreditLimit
            });
        }

        // Check collateral state fingerprint if needed
        if (proposal.checkCollateralStateFingerprint) {
            bytes32 currentFingerprint;
            IStateFingerpringComputer computer = config.getStateFingerprintComputer(proposal.collateralAddress);
            if (address(computer) != address(0)) {
                // Asset has registered computer
                currentFingerprint = computer.computeStateFingerprint({
                    token: proposal.collateralAddress, tokenId: proposal.collateralId
                });
            } else if (ERC165Checker.supportsInterface(proposal.collateralAddress, type(IERC5646).interfaceId)) {
                // Asset implements ERC5646
                currentFingerprint = IERC5646(proposal.collateralAddress).getStateFingerprint(proposal.collateralId);
            } else {
                // Asset is not implementing ERC5646 and no computer is registered
                revert MissingStateFingerprintComputer();
            }

            if (proposal.collateralStateFingerprint != currentFingerprint) {
                // Fingerprint mismatch
                revert InvalidCollateralStateFingerprint({
                    current: currentFingerprint,
                    proposed: proposal.collateralStateFingerprint
                });
            }
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { ERC721 } from "openzeppelin/token/ERC721/ERC721.sol";

import { PWNHub } from "pwn/hub/PWNHub.sol";
import { PWNHubTags } from "pwn/hub/PWNHubTags.sol";
import { IERC5646 } from "pwn/interfaces/IERC5646.sol";
import { IPWNLoanMetadataProvider } from "pwn/interfaces/IPWNLoanMetadataProvider.sol";


/**
 * @title PWN LOAN token
 * @notice A LOAN token representing a loan in PWN protocol.
 * @dev Token doesn't hold any loan logic, just an address of a loan contract that minted the LOAN token.
 *      PWN LOAN token is shared between all loan contracts.
 */
contract PWNLOAN is ERC721, IERC5646 {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    PWNHub public immutable hub;

    /**
     * @dev Last used LOAN id. First LOAN id is 1. This value is incremental.
     */
    uint256 public lastLoanId;

    /**
     * @dev Mapping of a LOAN id to a loan contract that minted the LOAN token.
     */
    mapping (uint256 => address) public loanContract;


    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Emitted when a new LOAN token is minted.
     */
    event LOANMinted(uint256 indexed loanId, address indexed loanContract, address indexed owner);

    /**
     * @notice Emitted when a LOAN token is burned.
     */
    event LOANBurned(uint256 indexed loanId);


    /*----------------------------------------------------------*|
    |*  # ERRORS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Thrown when `PWNLOAN.burn` caller is not a loan contract that minted the LOAN token.
     */
    error InvalidLoanContractCaller();

    /**
     * @notice Thrown when caller is missing a PWN Hub tag.
     */
    error CallerMissingHubTag(bytes32 tag);


    /*----------------------------------------------------------*|
    |*  # MODIFIERS                                             *|
    |*----------------------------------------------------------*/

    modifier onlyActiveLoan() {
        if (!hub.hasTag(msg.sender, PWNHubTags.ACTIVE_LOAN))
            revert CallerMissingHubTag({ tag: PWNHubTags.ACTIVE_LOAN });
        _;
    }


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address _hub) ERC721("PWN LOAN", "LOAN") {
        hub = PWNHub(_hub);
    }


    /*----------------------------------------------------------*|
    |*  # TOKEN LIFECYCLE                                       *|
    |*----------------------------------------------------------*/

    /**
     * @notice Mint a new LOAN token.
     * @dev Only an address with associated `ACTIVE_LOAN` tag in PWN Hub can call this function.
     * @param owner Address of a LOAN token receiver.
     * @return loanId Id of a newly minted LOAN token.
     */
    function mint(address owner) external onlyActiveLoan returns (uint256 loanId) {
        loanId = ++lastLoanId;
        loanContract[loanId] = msg.sender;
        _mint(owner, loanId);
        emit LOANMinted(loanId, msg.sender, owner);
    }

    /**
     * @notice Burn a LOAN token.
     * @dev Any address that is associated with given loan id can call this function.
     *      It is enabled to let deprecated loan contracts repay and claim existing loans.
     * @param loanId Id of a LOAN token to be burned.
     */
    function burn(uint256 loanId) external {
        if (loanContract[loanId] != msg.sender)
            revert InvalidLoanContractCaller();

        delete loanContract[loanId];
        _burn(loanId);
        emit LOANBurned(loanId);
    }


    /*----------------------------------------------------------*|
    |*  # METADATA                                              *|
    |*----------------------------------------------------------*/

    /**
     * @notice Return a LOAN token metadata uri base on a loan contract that minted the token.
     * @param tokenId Id of a LOAN token.
     * @return Metadata uri for given token id (loan id).
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return IPWNLoanMetadataProvider(loanContract[tokenId]).loanMetadataUri();
    }


    /*----------------------------------------------------------*|
    |*  # ERC5646                                               *|
    |*----------------------------------------------------------*/

    /**
     * @dev See {IERC5646-getStateFingerprint}.
     */
    function getStateFingerprint(uint256 tokenId) external view virtual override returns (bytes32) {
        address _loanContract = loanContract[tokenId];

        if (_loanContract == address(0))
            return bytes32(0);

        return IERC5646(_loanContract).getStateFingerprint(tokenId);
    }


    /*----------------------------------------------------------*|
    |*  # ERC165                                                *|
    |*----------------------------------------------------------*/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC5646).interfaceId;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

/**
 * @notice Struct to hold the permit data.
 * @param asset The address of the ERC20 token.
 * @param owner The owner of the tokens.
 * @param amount The amount of tokens.
 * @param deadline The deadline for the permit.
 * @param v The v value of the signature.
 * @param r The r value of the signature.
 * @param s The s value of the signature.
 */
struct Permit {
    address asset;
    address owner;
    uint256 amount;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @notice Thrown when the permit owner is not matching.
 */
error InvalidPermitOwner(address current, address expected);

/**
 * @notice Thrown when the permit asset is not matching.
 */
error InvalidPermitAsset(address current, address expected);

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { MultiToken } from "MultiToken/MultiToken.sol";

import { IERC20Permit } from "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import { IERC721Receiver } from "openzeppelin/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver, IERC165 } from "openzeppelin/token/ERC1155/IERC1155Receiver.sol";

import { IPoolAdapter } from "pwn/interfaces/IPoolAdapter.sol";
import { Permit } from "pwn/loan/vault/Permit.sol";


/**
 * @title PWN Vault
 * @notice Base contract for transferring and managing collateral and loan assets in PWN protocol.
 * @dev Loan contracts inherits PWN Vault to act as a Vault for its loan type.
 */
abstract contract PWNVault is IERC721Receiver, IERC1155Receiver {
    using MultiToken for MultiToken.Asset;

    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Emitted when asset transfer happens from an `origin` address to a vault.
     */
    event VaultPull(MultiToken.Asset asset, address indexed origin);

    /**
     * @notice Emitted when asset transfer happens from a vault to a `beneficiary` address.
     */
    event VaultPush(MultiToken.Asset asset, address indexed beneficiary);

    /**
     * @notice Emitted when asset transfer happens from an `origin` address to a `beneficiary` address.
     */
    event VaultPushFrom(MultiToken.Asset asset, address indexed origin, address indexed beneficiary);

    /**
     * @notice Emitted when asset is withdrawn from a pool to an `owner` address.
     */
    event PoolWithdraw(MultiToken.Asset asset, address indexed poolAdapter, address indexed pool, address indexed owner);

    /**
     * @notice Emitted when asset is supplied to a pool from a vault.
     */
    event PoolSupply(MultiToken.Asset asset, address indexed poolAdapter, address indexed pool, address indexed owner);


    /*----------------------------------------------------------*|
    |*  # ERRORS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Thrown when the Vault receives an asset that is not transferred by the Vault itself.
     */
    error UnsupportedTransferFunction();

    /**
     * @notice Thrown when an asset transfer is incomplete.
     */
    error IncompleteTransfer();


    /*----------------------------------------------------------*|
    |*  # TRANSFER FUNCTIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Function pulling an asset into a vault.
     * @dev The function assumes a prior token approval to a vault address.
     * @param asset An asset construct - for a definition see { MultiToken dependency lib }.
     * @param origin Borrower address that is transferring collateral to Vault or repaying a loan.
     */
    function _pull(MultiToken.Asset memory asset, address origin) internal {
        uint256 originalBalance = asset.balanceOf(address(this));

        asset.transferAssetFrom(origin, address(this));
        _checkTransfer(asset, originalBalance, address(this), true);

        emit VaultPull(asset, origin);
    }

    /**
     * @notice Function pushing an asset from a vault to a recipient.
     * @dev This is used for claiming a paid back loan or a defaulted collateral, or returning collateral to a borrower.
     * @param asset An asset construct - for a definition see { MultiToken dependency lib }.
     * @param beneficiary An address of a recipient of an asset.
     */
    function _push(MultiToken.Asset memory asset, address beneficiary) internal {
        uint256 originalBalance = asset.balanceOf(beneficiary);

        asset.safeTransferAssetFrom(address(this), beneficiary);
        _checkTransfer(asset, originalBalance, beneficiary, true);

        emit VaultPush(asset, beneficiary);
    }

    /**
     * @notice Function pushing an asset from an origin address to a beneficiary address.
     * @dev The function assumes a prior token approval to a vault address.
     * @param asset An asset construct - for a definition see { MultiToken dependency lib }.
     * @param origin An address of a lender who is providing a loan asset.
     * @param beneficiary An address of the recipient of an asset.
     */
    function _pushFrom(MultiToken.Asset memory asset, address origin, address beneficiary) internal {
        uint256 originalBalance = asset.balanceOf(beneficiary);

        asset.safeTransferAssetFrom(origin, beneficiary);
        _checkTransfer(asset, originalBalance, beneficiary, true);

        emit VaultPushFrom(asset, origin, beneficiary);
    }

    /**
     * @notice Function withdrawing an asset from a Compound pool to the owner.
     * @dev The function assumes a prior check for a valid pool address.
     * @param asset An asset construct - for a definition see { MultiToken dependency lib }.
     * @param poolAdapter An address of a pool adapter.
     * @param pool An address of a pool.
     * @param owner An address on which behalf the assets are withdrawn.
     */
    function _withdrawFromPool(MultiToken.Asset memory asset, IPoolAdapter poolAdapter, address pool, address owner) internal {
        uint256 originalBalance = asset.balanceOf(owner);

        poolAdapter.withdraw(pool, owner, asset.assetAddress, asset.amount);
        _checkTransfer(asset, originalBalance, owner, true);

        emit PoolWithdraw(asset, address(poolAdapter), pool, owner);
    }

    /**
     * @notice Function supplying an asset to a pool from a vault via a pool adapter.
     * @dev The function assumes a prior check for a valid pool address.
     *      Assuming pool will revert supply transaction if it fails.
     * @param asset An asset construct - for a definition see { MultiToken dependency lib }.
     * @param poolAdapter An address of a pool adapter.
     * @param pool An address of a pool.
     * @param owner An address on which behalf the asset is supplied.
     */
    function _supplyToPool(MultiToken.Asset memory asset, IPoolAdapter poolAdapter, address pool, address owner) internal {
        uint256 originalBalance = asset.balanceOf(address(this));

        asset.transferAssetFrom(address(this), address(poolAdapter));
        poolAdapter.supply(pool, owner, asset.assetAddress, asset.amount);
        _checkTransfer(asset, originalBalance, address(this), false);

        // Note: Assuming pool will revert supply transaction if it fails.

        emit PoolSupply(asset, address(poolAdapter), pool, owner);
    }

    function _checkTransfer(
        MultiToken.Asset memory asset,
        uint256 originalBalance,
        address checkedAddress,
        bool checkIncreasingBalance
    ) private view {
        uint256 expectedBalance = checkIncreasingBalance
            ? originalBalance + asset.getTransferAmount()
            : originalBalance - asset.getTransferAmount();

        if (expectedBalance != asset.balanceOf(checkedAddress)) {
            revert IncompleteTransfer();
        }
    }


    /*----------------------------------------------------------*|
    |*  # PERMIT                                                *|
    |*----------------------------------------------------------*/

    /**
     * @notice Try to execute a permit for an ERC20 token.
     * @dev If the permit execution fails, the function will not revert.
     * @param permit The permit data.
     */
    function _tryPermit(Permit memory permit) internal {
        if (permit.asset != address(0)) {
            try IERC20Permit(permit.asset).permit({
                owner: permit.owner,
                spender: address(this),
                value: permit.amount,
                deadline: permit.deadline,
                v: permit.v,
                r: permit.r,
                s: permit.s
            }) {} catch {
                // Note: Permit execution can be frontrun, so we don't revert on failure.
            }
        }
    }


    /*----------------------------------------------------------*|
    |*  # ERC721/1155 RECEIVED HOOKS                            *|
    |*----------------------------------------------------------*/

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * @return `IERC721Receiver.onERC721Received.selector` if transfer is allowed
     */
    function onERC721Received(
        address operator,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) override external view returns (bytes4) {
        if (operator != address(this))
            revert UnsupportedTransferFunction();

        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     * To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address /*from*/,
        uint256 /*id*/,
        uint256 /*value*/,
        bytes calldata /*data*/
    ) override external view returns (bytes4) {
        if (operator != address(this))
            revert UnsupportedTransferFunction();

        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated. To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address /*operator*/,
        address /*from*/,
        uint256[] calldata /*ids*/,
        uint256[] calldata /*values*/,
        bytes calldata /*data*/
    ) override external pure returns (bytes4) {
        revert UnsupportedTransferFunction();
    }


    /*----------------------------------------------------------*|
    |*  # SUPPORTED INTERFACES                                  *|
    |*----------------------------------------------------------*/

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external pure virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { PWNHub } from "pwn/hub/PWNHub.sol";
import { PWNHubTags } from "pwn/hub/PWNHubTags.sol";
import { AddressMissingHubTag } from "pwn/PWNErrors.sol";


/**
 * @title PWN Revoked Nonce
 * @notice Contract holding revoked nonces.
 */
contract PWNRevokedNonce {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * @notice Access tag that needs to be assigned to a caller in PWN Hub
     *         to call functions that revoke nonces on behalf of an owner.
     */
    bytes32 public immutable accessTag;

    /**
     * @notice PWN Hub contract.
     * @dev Addresses revoking nonces on behalf of an owner need to have an access tag in PWN Hub.
     */
    PWNHub public immutable hub;

    /**
     * @notice Mapping of revoked nonces by an address. Every address has its own nonce space.
     *         (owner => nonce space => nonce => is revoked)
     */
    mapping (address => mapping (uint256 => mapping (uint256 => bool))) private _revokedNonce;

    /**
     * @notice Mapping of current nonce space for an address.
     */
    mapping (address => uint256) private _nonceSpace;


    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Emitted when a nonce is revoked.
     */
    event NonceRevoked(address indexed owner, uint256 indexed nonceSpace, uint256 indexed nonce);

    /**
     * @notice Emitted when a nonce is revoked.
     */
    event NonceSpaceRevoked(address indexed owner, uint256 indexed nonceSpace);


    /*----------------------------------------------------------*|
    |*  # ERRORS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Thrown when trying to revoke a nonce that is already revoked.
     */
    error NonceAlreadyRevoked(address addr, uint256 nonceSpace, uint256 nonce);

    /**
     * @notice Thrown when nonce is currently not usable.
     * @dev Maybe nonce is revoked or not in the current nonce space.
     */
    error NonceNotUsable(address addr, uint256 nonceSpace, uint256 nonce);


    /*----------------------------------------------------------*|
    |*  # MODIFIERS                                             *|
    |*----------------------------------------------------------*/

    modifier onlyWithHubTag() {
        if (!hub.hasTag(msg.sender, accessTag))
            revert AddressMissingHubTag({ addr: msg.sender, tag: accessTag });
        _;
    }


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address _hub, bytes32 _accessTag) {
        accessTag = _accessTag;
        hub = PWNHub(_hub);
    }


    /*----------------------------------------------------------*|
    |*  # NONCE                                                 *|
    |*----------------------------------------------------------*/

    /**
     * @notice Revoke callers nonce in the current nonce space.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(uint256 nonce) external {
        _revokeNonce(msg.sender, _nonceSpace[msg.sender], nonce);
    }

    /**
     * @notice Revoke multiple caller nonces in the current nonce space.
     * @param nonces List of nonces to be revoked.
     */
    function revokeNonces(uint256[] calldata nonces) external {
        for (uint256 i; i < nonces.length; ++i) {
            _revokeNonce(msg.sender, _nonceSpace[msg.sender], nonces[i]);
        }
    }

    /**
     * @notice Revoke caller nonce in a nonce space.
     * @param nonceSpace Nonce space where a nonce will be revoked.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(uint256 nonceSpace, uint256 nonce) external {
        _revokeNonce(msg.sender, nonceSpace, nonce);
    }

    /**
     * @notice Revoke a nonce in the current nonce space on behalf of an owner.
     * @dev Only an address with associated access tag in PWN Hub can call this function.
     * @param owner Owner address of a revoking nonce.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(address owner, uint256 nonce) external onlyWithHubTag {
        _revokeNonce(owner, _nonceSpace[owner], nonce);
    }

    /**
     * @notice Revoke a nonce in a nonce space on behalf of an owner.
     * @dev Only an address with associated access tag in PWN Hub can call this function.
     * @param owner Owner address of a revoking nonce.
     * @param nonceSpace Nonce space where a nonce will be revoked.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(address owner, uint256 nonceSpace, uint256 nonce) external onlyWithHubTag {
        _revokeNonce(owner, nonceSpace, nonce);
    }

    /**
     * @notice Internal function to revoke a nonce in a nonce space.
     */
    function _revokeNonce(address owner, uint256 nonceSpace, uint256 nonce) private {
        if (_revokedNonce[owner][nonceSpace][nonce]) {
            revert NonceAlreadyRevoked({ addr: owner, nonceSpace: nonceSpace, nonce: nonce });
        }
        _revokedNonce[owner][nonceSpace][nonce] = true;
        emit NonceRevoked(owner, nonceSpace, nonce);
    }

    /**
     * @notice Return true if owners nonce is revoked in the given nonce space.
     * @dev Do not use this function to check if nonce is usable.
     *      Use `isNonceUsable` instead, which checks nonce space as well.
     * @param owner Address of a nonce owner.
     * @param nonceSpace Value of a nonce space.
     * @param nonce Value of a nonce.
     * @return True if nonce is revoked.
     */
    function isNonceRevoked(address owner, uint256 nonceSpace, uint256 nonce) external view returns (bool) {
        return _revokedNonce[owner][nonceSpace][nonce];
    }

    /**
     * @notice Return true if owners nonce is usable. Nonce is usable if it is not revoked and in the current nonce space.
     * @param owner Address of a nonce owner.
     * @param nonceSpace Value of a nonce space.
     * @param nonce Value of a nonce.
     * @return True if nonce is usable.
     */
    function isNonceUsable(address owner, uint256 nonceSpace, uint256 nonce) external view returns (bool) {
        if (_nonceSpace[owner] != nonceSpace)
            return false;

        return !_revokedNonce[owner][nonceSpace][nonce];
    }


    /*----------------------------------------------------------*|
    |*  # NONCE SPACE                                           *|
    |*----------------------------------------------------------*/

    /**
     * @notice Revoke all nonces in the current nonce space and increment nonce space.
     * @dev Caller is used as a nonce owner.
     * @return New nonce space.
     */
    function revokeNonceSpace() external returns (uint256) {
        emit NonceSpaceRevoked(msg.sender, _nonceSpace[msg.sender]);
        return ++_nonceSpace[msg.sender];
    }

    /**
     * @notice Return current nonce space for an address.
     * @param owner Address of a nonce owner.
     * @return Current nonce space.
     */
    function currentNonceSpace(address owner) external view returns (uint256) {
        return _nonceSpace[owner];
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;


/**
 * @notice Thrown when an address is missing a PWN Hub tag.
 */
error AddressMissingHubTag(address addr, bytes32 tag);

/**
 * @notice Thrown when a proposal is expired.
 */
error Expired(uint256 current, uint256 expiration);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CryptoKitties Interface
 * @dev CryptoKitties Interface ID is 0x9a20483d.
 */
interface ICryptoKitties {
    // Required methods
    function totalSupply() external view returns (uint256 total);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Optional
    function name() external view returns (string memory name);
    function symbol() external view returns (string memory symbol);
    function tokensOfOwner(address _owner) external view returns (uint256[] memory tokenIds);
    function tokenMetadata(uint256 _tokenId, string memory _preferredTransport) external view returns (string memory infoUrl);

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    // Is not part of the interface id
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @title MultiToken Category Registry Interface
* @notice Interface for the MultiToken Category Registry.
* @dev Category Registry Interface ID is 0xc37a4a01.
*/
interface IMultiTokenCategoryRegistry {

    /**
    * @notice Emitted when a category is registered for an asset address.
    * @param assetAddress Address of an asset to which category is registered.
    * @param category A raw value of a MultiToken Category registered for an asset.
    */
    event CategoryRegistered(address indexed assetAddress, uint8 indexed category);

    /**
    * @notice Emitted when a category is unregistered for an asset address.
    * @param assetAddress Address of an asset to which category is unregistered.
    */
    event CategoryUnregistered(address indexed assetAddress);

    /**
     * @notice Register a MultiToken Category value to an asset address.
     * @param assetAddress Address of an asset to which category is registered.
     * @param category A raw value of a MultiToken Category to register for an asset.
     */
    function registerCategoryValue(address assetAddress, uint8 category) external;

    /**
     * @notice Clear the stored category for the asset address.
     * @param assetAddress Address of an asset to which category is unregistered.
     */
    function unregisterCategoryValue(address assetAddress) external;

    /**
     * @notice Getter for a registered category value of a given asset address.
     * @param assetAddress Address of an asset to which category is requested.
     * @return Raw category value registered for the asset address.
     */
    function registeredCategoryValue(address assetAddress) external view returns (uint8);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
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
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title IStateFingerpringComputer
 * @notice State Fingerprint Computer Interface.
 * @dev Contract can compute state fingerprint of several tokens as long as they share the same state structure.
 */
interface IStateFingerpringComputer {

    /**
     * @notice Compute current token state fingerprint for a given token.
     * @param token Address of a token contract.
     * @param tokenId Token id to compute state fingerprint for.
     * @return Current token state fingerprint.
     */
    function computeStateFingerprint(address token, uint256 tokenId) external view returns (bytes32);

    /**
     * @notice Check if the computer supports a given token address.
     * @param token Address of a token contract.
     * @return True if the computer supports the token address, false otherwise.
     */
    function supportsToken(address token) external view returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
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
        }
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
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
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
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
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

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}