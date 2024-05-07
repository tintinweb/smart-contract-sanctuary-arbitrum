/**
 *Submitted for verification at Arbiscan.io on 2024-05-06
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.12;




interface ILoansDeployer {
    function deployLoan(
        uint256 fundingPeriodInDays,
        uint256 newPaymentIntervalInSeconds,
        uint256 loanAmountInPrincipalTokens, 
        uint256 originationFeePercent2Decimals,
        uint256 newAprWithTwoDecimals,
        uint256 initialCollateralRatioWith2Decimals,
        address lenderAddr, 
        address borrowerAddr,
        address newCollateralToken,
        address newPrincipalToken,
        address feesManagerAddr,
        bool allowSeizeCollateral
    ) external returns (address);
}







interface IERC20NonCompliant {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address addr) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
}







/**
 * @title Defines the interface of a basic pricing oracle.
 * @dev All prices are expressed in USD, with 6 decimal positions.
 */
interface IBasicPriceOracle {
    function updateTokenPrice (address tokenAddr, uint256 valueInUSD) external;
    function bulkUpdate (address[] memory tokens, uint256[] memory prices) external;
    function getTokenPrice (address tokenAddr) external view returns (uint256);
}


interface IOpenTermLoanV3 {
    // State changing functions
    function fundLoan() external;
    function callLoan(uint256 callbackPeriodInHours, uint256 gracePeriodInHours) external;
    function liquidate() external;
    function setFeesOracle(address newFeesOracle) external;
    function changeOracle(IBasicPriceOracle newOracle) external;
    function setFeesCollector(address newFeesCollector) external;
    function proposeNewApr(uint256 newAprWithTwoDecimals) external;
    function acceptApr() external;
    function changeLateFees(uint256 lateInterestFeeWithTwoDecimals, uint256 latePrincipalFeeWithTwoDecimals) external;
    function seizeCollateral(uint256 amount) external;
    function returnCollateral(uint256 depositAmount) external;
    function repay(uint256 paymentAmount) external;
    function changeMaintenanceCollateralRatio(uint256 maintenanceCollateralRatioWith2Decimals) external;

    // Views
    function loanState() external view returns (uint8);
    function getEffectiveLoanAmount() external view returns (uint256);
    function getDebtBoundaries() external view returns (uint256 minPayment, uint256 maxPayment, uint256 netDebtAmount);
    function lender() external view returns (address);
    function interestsRepaid() external view returns (uint256);
    function principalRepaid() external view returns (uint256);
    function getCollateralToken() external view returns (address);
}




interface ILenderHookV2 {
    function notifyLoanClosed() external;
    function notifyLoanMatured() external;
    function notifyPrincipalRepayment(uint256 effectiveLoanAmount, uint256 principalRepaid) external;
}




interface ICategoryFees {
    function setContextFeeRate(uint256 feePercent, bytes32 categoryId, address specificAddr) external;
    
    function getContextFeeRate(bytes32 categoryId, address specificAddr) external view returns (uint256);
    function getContextFeeAmount(uint256 amount, bytes32 categoryId, address specificAddr) external view returns (uint256 feePercent, uint256 feeAmount);
}




/**
 * @notice This library provides stateless, general purpose functions.
 */
library ContractUtils {
    // The code hash of any EOA
    bytes32 constant internal EOA_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    /**
     * @notice Indicates if the address specified represents a smart contract.
     * @dev Notice that this method returns TRUE if the address is a contract under construction
     * @param addr The address to evaluate
     * @return Returns true if the address represents a smart contract
     */
    function isContract (address addr) internal view returns (bool) {
        bytes32 eoaHash = EOA_HASH;

        bytes32 codeHash;

        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(addr) }

        return (codeHash != eoaHash && codeHash != 0x0);
    }

    /**
     * @notice Gets the code hash of the address specified
     * @param addr The address to evaluate
     * @return Returns a hash
     */
    function getCodeHash (address addr) internal view returns (bytes32) {
        bytes32 codeHash;

        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(addr) }

        return codeHash;
    }
}


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}


/**
 * @title Represents an open-term loan.
 */
contract OpenTermLoanV3 is IOpenTermLoanV3, ReentrancyGuard {
    // ---------------------------------------------------------------
    // States of a loan
    // ---------------------------------------------------------------
    uint8 constant private PREAPPROVED = 1;        // The loan was pre-approved by the lender
    uint8 constant private FUNDING_REQUIRED = 2;   // The loan was accepted by the borrower. Waiting for the lender to fund the loan.
    uint8 constant private FUNDED = 3;             // The loan was funded.
    uint8 constant private ACTIVE = 4;             // The loan is active.
    uint8 constant private CANCELLED = 5;          // The lender failed to fund the loan and the borrower claimed their collateral.
    uint8 constant private MATURED = 6;            // The loan matured. It was liquidated by the lender.
    uint8 constant private CLOSED = 7;             // The loan was closed normally.

    // ---------------------------------------------------------------
    // Fee constants
    // ---------------------------------------------------------------
    bytes32 constant public REPAY_INTERESTS_CATEGORY = bytes32(keccak256("LOAN.REPAY.INTERESTS"));
    bytes32 constant public LIQUIDATE_LOAN_COLLATERAL_CATEGORY = bytes32(keccak256("LOAN.LIQUIDATION.COLLATERAL"));

    // ---------------------------------------------------------------
    // Other constants
    // ---------------------------------------------------------------
    // The zero address
    address constant private ZERO_ADDRESS = address(0);

    // The minimum payment interval, expressed in seconds
    uint256 constant private MIN_PAYMENT_INTERVAL = 2 hours;

    // The minimum callback period when calling a loan
    uint256 constant private MIN_CALLBACK_PERIOD = uint256(24);

    // The minimum grace period when calling a loan
    uint256 constant private MIN_GRACE_PERIOD = uint256(12);


    // ---------------------------------------------------------------
    // State layout
    // ---------------------------------------------------------------
    /**
     * @notice The late interests fee, as a percentage with 2 decimal places.
     */
    uint256 public lateInterestFee = uint256(30000);

    /**
     * @notice The late principal fee, as a percentage with 2 decimal places.
     */
    uint256 public latePrincipalFee = uint256(40000);

    /**
     * @notice The callback deadline of the loan. It is non-zero as soon as the loan gets called.
     * @dev It becomes a non-zero value as soon as the loan gets called.
     */
    uint256 public callbackDeadline;

    /**
     * @notice The date in which the loan was funded by the lender.
     * @dev It becomes a non-zero value as soon as the loan gets funded by the lender. It is zero otherwise.
     */
    uint256 public fundedOn;

    /**
     * @notice The amount of interests repaid so far.
     * @dev It gets updated when the borrower repays interests.
     */
    uint256 public override interestsRepaid;

    /**
     * @notice The amount of principal repaid so far.
     * @dev It gets updated when the borrower repays principal.
     */
    uint256 public override principalRepaid;

    /**
     * @notice The deadline for funding the loan.
     * @dev The lender is required to fund the principal before this exact point in time.
     */
    uint256 public fundingDeadline;

    // The maintenance collateral ratio, with 2 decimal places. It is zero for unsecured debt.
    uint256 private _maintenanceCollateralRatio;

    /**
     * @notice The APR of the loan, with 2 decimal places.
     * @dev If the APR is 6% then the value reads 600, which is 6.00%
     */
    uint256 public variableApr;

    /**
     * @notice The new APR proposed by the lender, expressed with 2 decimal places.
     */
    uint256 public proposedApr;

    /**
     * @notice The date (unix epoch) in which the variable APR was updated by the lender.
     */
    uint256 public aprUpdatedOn;

    /**
     * @notice The amount of collateral seized by the lender.
     */
    uint256 public collateralAmountSeized;

    /**
     * @notice The total amount of fees collected on interest repayments so far.
     */
    uint256 public totalInterestPaymentFees;

    // The current state of the loan
    uint8 internal _loanState;

    /**
     * @notice The oracle for calculating token prices.
     */
    address public priceOracle;

    /**
     * @notice The oracle used for calculating fees.
     */
    address public feesOracle;

    /**
     * @notice The address of the fees collector.
     */
    address public feesCollector;

    // ---------------------------------------------------------------
    // Immutable state
    // ---------------------------------------------------------------
    /**
     * @notice The manager of this loan.
     */
    address public immutable manager;

    /**
     * @notice The payment interval, expressed in seconds.
     * @dev For example, 1 day = 86400
     */
    uint256 public immutable paymentIntervalInSeconds;

    /**
     * @notice The funding period, expressed in seconds.
     */
    uint256 public immutable fundingPeriod;

    /**
     * @notice The loan amount, expressed in principal tokens.
     */
    uint256 public immutable loanAmountInPrincipalTokens;

    // The effective loan amount
    uint256 private immutable _effectiveLoanAmount;

    // The initial collateral ratio, with 2 decimal places. It is zero for unsecured debt.
    uint256 private immutable _initialCollateralRatio;

    /**
     * @notice The address of the borrower per terms and conditions agreed between parties.
     */
    address public immutable borrower;

    /**
     * @notice The address of the lender per terms and conditions agreed between parties.
     */
    address public immutable override lender;

    /**
     * @notice The address of the principal token.
     */
    address public immutable principalToken;

    /**
     * @notice The address of the collateral token, if any.
     * @dev The collateral token is the zero address for unsecured loans.
     */
    address public immutable collateralToken;

    /**
     * @notice Indicates if the lender is allowed to seize the collateral of the borrower
     */
    bool public immutable canSeizeCollateral;


    // ---------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------
    /**
     * @notice This event is triggered when the borrower accepts a loan.
     */
    event OnBorrowerCommitment();

    /**
     * @notice This event is triggered when the lender funds the loan.
     * @param amount The funding amount deposited in this loan
     */
    event OnLoanFunded(uint256 amount);

    /**
     * @notice This event is triggered when the borrower claims their collateral.
     * @param collateralClaimed The amount of collateral claimed by the borrower
     */
    event OnCollateralClaimed(uint256 collateralClaimed);

    /**
     * @notice This event is triggered when the price oracle changes.
     * @param prevAddress The address of the previous oracle
     * @param newAddress The address of the new oracle
     */
    event OnPriceOracleChanged(address prevAddress, address newAddress);

    /**
     * @notice This event is triggered when the maintenance collateralization ratio is updated
     * @param prevValue The previous maintenance ratio
     * @param newValue The new maintenance ratio
     */
    event OnCollateralRatioChanged(uint256 prevValue, uint256 newValue);

    /**
     * @notice This event is triggered when the late fees are updated
     * @param prevLateInterestFee The previous late fee for interests
     * @param newLateInterestFee The new late fee for interests
     * @param prevLatePrincipalFee The previous late fee for principal
     * @param newLatePrincipalFee The new late fee for principal
     */
    event OnLateFeesChanged(uint256 prevLateInterestFee, uint256 newLateInterestFee, uint256 prevLatePrincipalFee, uint256 newLatePrincipalFee);

    /**
     * @notice This event is triggered when the borrower withdraws principal tokens from the contract
     * @param numberOfTokens The amount of principal tokens withdrawn by the borrower
     */
    event OnBorrowerWithdrawal (uint256 numberOfTokens);

    /**
     * @notice This event is triggered when the lender calls the loan.
     * @param callbackPeriodInHours The callback period, measured in hours.
     * @param gracePeriodInHours The grace period, measured in hours.
     */
    event OnLoanCalled (uint256 callbackPeriodInHours, uint256 gracePeriodInHours);

    /**
     * @notice This event is triggered when the borrower repays interests
     * @param paymentAmountTokens The amount repaid by the borrower
     */
    event OnInterestsRepayment (uint256 paymentAmountTokens);

    /**
     * @notice This event is triggered when the borrower repays capital (principal)
     * @param paymentAmountTokens The amount repaid by the borrower
     */
    event OnPrincipalRepayment (uint256 paymentAmountTokens);

    /**
     * @notice This event is triggered when the loan gets closed.
     */
    event OnLoanClosed();

    /**
     * @notice This event is triggered when the loan is matured.
     */
    event OnLoanMatured();

    /**
     * @notice This event is triggered when the lender proposes a new APR.
     */
    event OnNewAprProposed (uint256 oldApr, uint256 newApr);

    /**
     * @notice This event is triggered when the borrower accepts the new APR proposed by the lender.
     */
    event OnAprAcceptedByBorrower (uint256 oldApr, uint256 newApr);

    /**
     * @notice This event is triggered if/when the lender seizes the collateral deposited by the borrower.
     */
    event OnCollateralCaptured(uint256 amount);

    /**
     * @notice This event is triggered if/when the lender re-deposits the collateral submitted by the borrower.
     */
    event OnCollateralRedeposited(uint256 depositAmount);

    /**
     * @notice This event is triggered whenever this contract transfers fees to the collector.
     */
    event OnFeeProcessed(uint256 feePercent, uint256 feeAmount, address from, address to);


    // ---------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------
    constructor (
        uint256 fundingPeriodInDays,
        uint256 newPaymentIntervalInSeconds,
        uint256 newLoanAmountInPrincipalTokens, 
        uint256 originationFeePercent2Decimals,
        uint256 newAprWithTwoDecimals,
        uint256 initialCollateralRatioWith2Decimals,
        address lenderAddr, 
        address borrowerAddr,
        address newCollateralToken,
        address newPrincipalToken,
        address feesManagerAddr,
        bool allowSeizeCollateral
    ) {
        // Checks
        require(lenderAddr != ZERO_ADDRESS, "Lender required");
        require(borrowerAddr != ZERO_ADDRESS, "Borrower required");
        require(feesManagerAddr != ZERO_ADDRESS, "Fees manager required");

        require(borrowerAddr != lenderAddr, "Invalid borrower");
        require(feesManagerAddr != lenderAddr && feesManagerAddr != borrowerAddr, "Invalid fees manager");

        require(fundingPeriodInDays > 0, "Invalid funding period");

        // The minimum loan amount is 365 * 1e4 = 3650000 = 3.650000 USDC
        require(newLoanAmountInPrincipalTokens > 365 * 1e4, "Invalid loan amount");

        // The minimum APR is 1 (APR: 0.01%)
        require(newAprWithTwoDecimals > 0, "Invalid APR");

        // The minimum payment interval is 3 hours
        require(newPaymentIntervalInSeconds >= MIN_PAYMENT_INTERVAL, "Payment interval too short");

        // The maximum origination fee is 90% of the loan amount
        require(originationFeePercent2Decimals <= 9000, "Origination fee too high");

        // Check the collateralization ratio
        if (newCollateralToken == ZERO_ADDRESS) {
            // Unsecured loan
            require(initialCollateralRatioWith2Decimals == 0, "Invalid initial collateral");
        } else {
            // Secured loan
            require(initialCollateralRatioWith2Decimals > 0 && initialCollateralRatioWith2Decimals <= 12000, "Invalid initial collateral");
        }

        // State changes (immutable)
        lender = lenderAddr;
        borrower = borrowerAddr;
        manager = feesManagerAddr;

        principalToken = newPrincipalToken;
        collateralToken = newCollateralToken;
        canSeizeCollateral = allowSeizeCollateral;

        fundingPeriod = fundingPeriodInDays * 1 days;
        variableApr = newAprWithTwoDecimals;
        paymentIntervalInSeconds = newPaymentIntervalInSeconds;

        loanAmountInPrincipalTokens = newLoanAmountInPrincipalTokens;
        _initialCollateralRatio = initialCollateralRatioWith2Decimals;
        _effectiveLoanAmount = newLoanAmountInPrincipalTokens - (newLoanAmountInPrincipalTokens * originationFeePercent2Decimals / 1e4);

        // State changes (volatile)
        _maintenanceCollateralRatio = initialCollateralRatioWith2Decimals;
        _loanState = PREAPPROVED;
        aprUpdatedOn = block.timestamp;
    }

    // ---------------------------------------------------------------
    // Modifiers
    // ---------------------------------------------------------------
    /**
     * @notice Throws if the caller is not the expected borrower.
     */
    modifier onlyBorrower() {
        require(msg.sender == borrower, "Only borrower");
        _;
    }

    /**
     * @notice Throws if the caller is not the expected lender.
     */
    modifier onlyLender() {
        require(msg.sender == lender, "Only lender");
        _;
    }

    /**
     * @notice Throws if the caller is not the expected manager.
     */
    modifier onlyManager() {
        require(msg.sender == manager, "Only manager");
        _;
    }

    /**
     * @notice Throws if the loan is not active.
     */
    modifier onlyIfActive() {
        require(_loanState == ACTIVE, "Loan is not active");
        _;
    }

    /**
     * @notice Throws if the loan is not active or funded.
     */
    modifier onlyIfActiveOrFunded() {
        require(_loanState == ACTIVE || _loanState == FUNDED, "Loan is not active");
        _;
    }

    /**
     * @notice Throws if the lender is not allowed to seize the collateral deposited by the borrower.
     */
    modifier onlyIfCanSeizeCollateral() {
        require(canSeizeCollateral, "Cannot seize borrower's collateral");
        _;
    }

    /**
     * @notice Throws if the fees collector and/or oracle is not set.
     */
    modifier ifFeesInitialized() {
        require(feesOracle != ZERO_ADDRESS, "Fees oracle not set");
        require(feesCollector != ZERO_ADDRESS, "Fees collector not set");
        require(priceOracle != ZERO_ADDRESS, "Price oracle not set");
        _;
    }

    // ---------------------------------------------------------------
    // Functions
    // ---------------------------------------------------------------
    /**
     * @notice Sets the address of the fees collector.
     * @param newFeesCollector The new address of the fees collector.
     */
    function setFeesCollector(address newFeesCollector) external override nonReentrant onlyManager {
        require(newFeesCollector != ZERO_ADDRESS, "Fees collector required");
        feesCollector = newFeesCollector;
    }

    /**
     * @notice Sets the address of the oracle responsible for calculating fees.
     * @param newFeesOracle The address of the oracle responsible for calculating fees.
     */
    function setFeesOracle(address newFeesOracle) external override nonReentrant onlyManager {
        require(newFeesOracle != ZERO_ADDRESS, "Fees oracle required");
        feesOracle = newFeesOracle;
    }

    /**
     * @notice As a lender, you propose a new APR to the borrower.
     * @dev The lender is allowed to propose any new APR at their sole discretion.
     * @param newAprWithTwoDecimals The APR proposed by the lender, expressed with 2 decimal places.
     */
    function proposeNewApr(uint256 newAprWithTwoDecimals) external override nonReentrant onlyLender onlyIfActive {
        require(newAprWithTwoDecimals > 0, "Invalid APR");
        require(newAprWithTwoDecimals != variableApr, "APR already set");

        // The lender cannot propose a new APR if the loan was called.
        require(callbackDeadline == 0, "Loan was called");

        proposedApr = newAprWithTwoDecimals;

        emit OnNewAprProposed(variableApr, newAprWithTwoDecimals);
    }

    /**
     * @notice As a borrower, you are accepting the new APR proposed by the lender.
     */
    function acceptApr() external override nonReentrant onlyBorrower onlyIfActive {
        require(proposedApr > 0, "No new APR was proposed yet");
        require(callbackDeadline == 0, "Loan was called");

        uint256 oldApr = variableApr;        
        variableApr = proposedApr;
        proposedApr = 0;
        aprUpdatedOn = block.timestamp;

        emit OnAprAcceptedByBorrower(oldApr, variableApr);
    }

    /**
     * @notice Updates the late fees
     * @dev Only the lender is allowed to call this function. As a lender, you cannot change the fees if the loan was called.
     * @param lateInterestFeeWithTwoDecimals The late interest fee (percentage) with 2 decimal places.
     * @param latePrincipalFeeWithTwoDecimals The late principal fee (percentage) with 2 decimal places.
     */
    function changeLateFees(uint256 lateInterestFeeWithTwoDecimals, uint256 latePrincipalFeeWithTwoDecimals) external override nonReentrant onlyLender {
        require(lateInterestFeeWithTwoDecimals > 0 && latePrincipalFeeWithTwoDecimals > 0, "Late fee required");
        require(callbackDeadline == 0, "Loan was called");

        emit OnLateFeesChanged(lateInterestFee, lateInterestFeeWithTwoDecimals, latePrincipalFee, latePrincipalFeeWithTwoDecimals);

        lateInterestFee = lateInterestFeeWithTwoDecimals;
        latePrincipalFee = latePrincipalFeeWithTwoDecimals;
    }

    /**
     * @notice Changes the oracle that calculates token prices.
     * @dev Only the lender is allowed to call this function
     * @param newOracle The new oracle for token prices
     */
    function changeOracle(IBasicPriceOracle newOracle) external override nonReentrant onlyLender {
        address prevAddr = priceOracle;
        require(prevAddr != address(newOracle), "Oracle already set");

        if (isSecured()) {
            // The lender cannot change the price oracle if the loan was called.
            // Otherwise the lender could force a liquidation of the loan 
            // by changing the maintenance collateral in order to game the borrower.
            require(callbackDeadline == 0, "Loan was called");
        }

        priceOracle = address(newOracle);
        emit OnPriceOracleChanged(prevAddr, priceOracle);
    }

    /**
     * @notice Updates the maintenance collateral ratio
     * @dev Only the lender is allowed to call this function. As a lender, you cannot change the maintenance collateralization ratio if the loan was called.
     * @param maintenanceCollateralRatioWith2Decimals The maintenance collateral ratio, if applicable.
     */
    function changeMaintenanceCollateralRatio(uint256 maintenanceCollateralRatioWith2Decimals) external override nonReentrant onlyLender {
        // The maintenance ratio cannot be altered if the loan is unsecured
        require(isSecured(), "This loan is unsecured");

        // The maintenance ratio cannot be greater than the initial ratio
        require(maintenanceCollateralRatioWith2Decimals > 0, "Maintenance ratio required");
        require(maintenanceCollateralRatioWith2Decimals <= _initialCollateralRatio, "Maintenance ratio too high");
        require(_maintenanceCollateralRatio != maintenanceCollateralRatioWith2Decimals, "Value already set");

        // The lender cannot change the maintenance ratio if the loan was called.
        // Otherwise the lender could force a liquidation of the loan 
        // by changing the maintenance collateral in order to game the borrower.
        require(callbackDeadline == 0, "Loan was called");

        emit OnCollateralRatioChanged(_maintenanceCollateralRatio, maintenanceCollateralRatioWith2Decimals);
        
        _maintenanceCollateralRatio = maintenanceCollateralRatioWith2Decimals;
    }

    /**
     * @notice Allows the borrower to accept the loan offered by the lender.
     * @dev Only the borrower is allowed to call this function. The deposit amount is zero for unsecured loans.
     */
    function borrowerCommitment() external nonReentrant ifFeesInitialized onlyBorrower {
        // Checks
        require(_loanState == PREAPPROVED, "Invalid loan state");

        // Update the state of the loan
        _loanState = FUNDING_REQUIRED;

        // Set the deadline for funding the principal
        fundingDeadline = block.timestamp + fundingPeriod; // solhint-disable-line not-rely-on-time

        if (isSecured()) {
            // This is the amount of collateral the borrower is required to deposit, in tokens.
            uint256 expectedDepositAmount = getInitialCollateralAmount();

            // Deposit the collateral
            _depositToken(IERC20NonCompliant(collateralToken), msg.sender, expectedDepositAmount);
        }

        // Emit the respective event
        emit OnBorrowerCommitment();
    }

    /**
     * @notice Funds this loan with the respective amount of principal, per loan specs.
     * @dev Only the lender is allowed to call this function. The loan must be funded within the time window specified. Otherwise, the borrower is allowed to claim their collateral.
     */
    function fundLoan() external override nonReentrant onlyLender {
        require(_loanState == FUNDING_REQUIRED, "Invalid loan state");

        uint256 ts = block.timestamp; // solhint-disable-line not-rely-on-time
        require(ts <= fundingDeadline, "Funding period elapsed");

        // State changes
        fundedOn = ts;
        fundingDeadline = 0;
        _loanState = ACTIVE;

        // Fund the loan with the expected amount of principal tokens
        _depositToken(IERC20NonCompliant(principalToken), msg.sender, _effectiveLoanAmount);

        emit OnLoanFunded(_effectiveLoanAmount);

        // Send principal tokens to the borrower
        _transferPrincipalTokens(_effectiveLoanAmount, borrower);

        // Emit the event
        emit OnBorrowerWithdrawal(_effectiveLoanAmount);
    }

    /**
     * @notice Claims the collateral deposited by the borrower
     * @dev Only the borrower is allowed to call this function
     */
    function claimCollateral() external nonReentrant onlyBorrower {
        require(isSecured(), "This loan is unsecured");
        require(_loanState == FUNDING_REQUIRED, "Invalid loan state");
        require(block.timestamp > fundingDeadline, "Funding period not elapsed"); // solhint-disable-line not-rely-on-time

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        uint256 currentBalance = collateralTokenInterface.balanceOf(address(this));

        _loanState = CANCELLED;

        collateralTokenInterface.transfer(borrower, currentBalance);
        require(collateralTokenInterface.balanceOf(address(this)) == 0, "Collateral transfer failed");

        emit OnCollateralClaimed(currentBalance);
    }

    /**
     * @notice Allows the lender to capture a specific amount of collateral deposited by the borrower.
     * @param amount The amount of collateral to seize.
     */
    function seizeCollateral(uint256 amount) external override nonReentrant onlyLender onlyIfActive onlyIfCanSeizeCollateral {
        // The lender cannot seize the collateral if the loan was called
        require(callbackDeadline == 0, "Loan was called");

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        uint256 currentBalance = collateralTokenInterface.balanceOf(address(this));
        require(currentBalance > 0, "No collateral available");
        require(amount <= currentBalance, "Amount greater than balance");

        uint256 expectedBalance = currentBalance - amount;

        collateralAmountSeized += amount;

        // Transfer the collateral to the lender
        collateralTokenInterface.transfer(lender, amount);
        require(collateralTokenInterface.balanceOf(address(this)) == expectedBalance, "Collateral transfer failed");

        emit OnCollateralCaptured(amount);
    }

    /**
     * @notice Allows the lender to redeposit the previously seized collateral.
     * @param depositAmount The amount of collateral to return to the borrower.
     */
    function returnCollateral(uint256 depositAmount) external override nonReentrant onlyLender onlyIfActive onlyIfCanSeizeCollateral {
        require(depositAmount > 0, "Deposit amount required");
        require(depositAmount <= collateralAmountSeized, "Amount greater than captured funds");

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        uint256 currentBalance = collateralTokenInterface.balanceOf(address(this));
        uint256 expectedBalance = currentBalance + depositAmount;

        collateralAmountSeized -= depositAmount;

        collateralTokenInterface.transferFrom(msg.sender, address(this), depositAmount);
        require(collateralTokenInterface.balanceOf(address(this)) == expectedBalance, "Collateral deposit failed");

        emit OnCollateralRedeposited(depositAmount);
    }

    /**
     * @notice Repays the loan in a single transaction.
     * @dev Repays both interest and capital, where applicable. Applicability depends on the current context.
     * @param paymentAmount The payment amount, expressed in principal tokens.
     */
    function repay(uint256 paymentAmount) external override nonReentrant onlyBorrower onlyIfActive {
        require(paymentAmount > 0, "Payment amount required");

        // Enforce the maintenance collateral ratio, if applicable
        _enforceMaintenanceRatio();

        // If the loan was called then force the borrower to repay the full debt, including any late fees.
        if (callbackDeadline > 0) {
            _repayPrincipal(paymentAmount);
            return;
        }

        // At this point, the loan was not called.
        // Thus the borrower can repay both interests and capital, if applicable.
        // Get the current debt
        (, , , uint256 interestOwed, , , , , uint256 minPaymentAmount, ) = getDebt();

        // If the borrower repaid the interests already then the minimum payment amount is zero.
        // As a result, the borrower can repay the principal only.
        if (minPaymentAmount == 0) {
            // No interests owed. Repay the principal only.
            _repayPrincipal(paymentAmount);
            return;
        }

        // At this point, the borrower owes both: interests and principal.
        // Thus the minimum payment amount is the one defined for interests.
        require(paymentAmount >= minPaymentAmount, "Min Payment amount required");

        // Repay interests first.
        _repayInterests(minPaymentAmount, interestOwed, minPaymentAmount);

        // The payment amount we can consume in this tx
        uint256 pendingAmount = paymentAmount - minPaymentAmount;
        if (pendingAmount == 0) return;

        // At this point, the borrower repaid their interest.
        // The only option available is repay the principal.
        _repayPrincipal(pendingAmount);
    }

    /**
     * @notice Repays the interests portion of the loan.
     */
    function repayInterests() external nonReentrant onlyBorrower onlyIfActive {
        // Make sure the loan hasn't been called
        require(callbackDeadline == 0, "Loan was called");

        // Enforce the maintenance collateral ratio, if applicable
        _enforceMaintenanceRatio();

        // Get the current debt
        (, , , uint256 interestOwed, , , , , uint256 minPaymentAmount, ) = getDebt();

        _repayInterests(minPaymentAmount, interestOwed, minPaymentAmount);
    }

    /**
     * @notice Repays the principal portion of the loan.
     * @param paymentAmountInTokens The payment amount, expressed in principal tokens.
     */
    function repayPrincipal(uint256 paymentAmountInTokens) external nonReentrant onlyBorrower onlyIfActive {
        // Checks
        require(paymentAmountInTokens > 0, "Payment amount required");

        // Enforce the maintenance collateral ratio, if applicable
        _enforceMaintenanceRatio();

        _repayPrincipal(paymentAmountInTokens);
    }

    /**
     * @notice Calls the loan.
     * @dev Only the lender is allowed to call this function
     * @param callbackPeriodInHours The callback period, measured in hours.
     * @param gracePeriodInHours The grace period, measured in hours.
     */
    function callLoan(uint256 callbackPeriodInHours, uint256 gracePeriodInHours) external virtual override nonReentrant onlyLender onlyIfActiveOrFunded {
        require(callbackPeriodInHours >= MIN_CALLBACK_PERIOD, "Invalid Callback period");
        require(gracePeriodInHours >= MIN_GRACE_PERIOD, "Invalid Grace period");
        require(callbackDeadline == 0, "Loan was called already");
        require(collateralAmountSeized == 0, "Return the collateral first");

        callbackDeadline = block.timestamp + ((callbackPeriodInHours + gracePeriodInHours) * 1 hours); // solhint-disable-line not-rely-on-time

        emit OnLoanCalled(callbackPeriodInHours, gracePeriodInHours);
    }

    /**
     * @notice Liquidates the loan.
     * @dev Only the lender is allowed to call this function
     */
    function liquidate() external virtual override nonReentrant onlyLender onlyIfActiveOrFunded {
        // Checks
        require(callbackDeadline > 0, "Loan was not called yet");
        require(block.timestamp > callbackDeadline, "Callback period not elapsed"); // solhint-disable-line not-rely-on-time

        // State changes
        _loanState = MATURED;

        // Transfer the collateral to the lender
        if (isSecured()) {
            IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
            uint256 collateralBalanceInTokens = collateralTokenInterface.balanceOf(address(this));

            if (collateralBalanceInTokens > 0) {
                // Apply fees and transfer the collateral
                _applyFeesAndTransferTo(collateralTokenInterface, collateralBalanceInTokens, lender, LIQUIDATE_LOAN_COLLATERAL_CATEGORY, address(this));
                require(collateralTokenInterface.balanceOf(address(this)) == 0, "Collateral transfer failed");
            }
        }

        // This contract never holds principal tokens.
        // IF -for any reason- this contract holds principal tokens then transfer the funds to the fees collector.
        // Otherwise those funds would be unrecoverable.
        IERC20NonCompliant principalTokenInterface = IERC20NonCompliant(principalToken);
        uint256 principalBalanceInTokens = principalTokenInterface.balanceOf(address(this));

        if (principalBalanceInTokens > 0) {
            // Transfer any principal tokens to the fees collector. Fees are not applicable in this case.
            _transferPrincipalTokens(principalBalanceInTokens, feesCollector);
            require(principalTokenInterface.balanceOf(address(this)) == 0, "Principal transfer failed");
        }

        // Notify others that this loan matured.
        emit OnLoanMatured();
        if (ContractUtils.isContract(lender)) ILenderHookV2(lender).notifyLoanMatured();
    }

    // Repays a specific amount of interests
    function _repayInterests(uint256 paymentAmount, uint256 interestOwed, uint256 minPaymentAmount) private {
        // Checks
        require(paymentAmount > 0, "Payment amount required");
        require(interestOwed > 0, "No interests owed");
        require(paymentAmount >= minPaymentAmount, "Min payment amount required");
        //require(paymentAmount <= interestOwed, "Invalid interests amount");

        // State changes
        interestsRepaid += paymentAmount;

        // Transfer funds from the borrower to this contract
        _depositToken(IERC20NonCompliant(principalToken), msg.sender, paymentAmount);

        // Apply fees and transfer the payment amount to the lender
        _applyFeesAndTransferTo(IERC20NonCompliant(principalToken), paymentAmount, lender, REPAY_INTERESTS_CATEGORY, address(this));

        emit OnInterestsRepayment(paymentAmount);
    }

    // Repays a specific amount of capital
    function _repayPrincipal(uint256 paymentAmountInTokens) private {
        // Get the current debt
        (, , uint256 principalDebtAmount, uint256 interestOwed, , , , , , uint256 maxPaymentAmount) = getDebt();

        if (callbackDeadline > 0) {
            // If the loan was called then the borrower is required to repay the net debt amount
            require(paymentAmountInTokens == maxPaymentAmount, "Full payment expected");
        } else {
            require(interestOwed == 0, "Must repay interests first");
        }

        // If the loan was not called then the borrower can repay any principal amount of their preference 
        // as long as it does not exceed the net debt
        require(paymentAmountInTokens <= maxPaymentAmount, "Amount exceeds net debt");

        // Make sure the deposit succeeds
        _depositToken(IERC20NonCompliant(principalToken), msg.sender, paymentAmountInTokens);

        // Update the amount of principal (capital) that was repaid so far
        uint256 delta = (paymentAmountInTokens <= principalDebtAmount) ? paymentAmountInTokens : principalDebtAmount;
        principalRepaid += delta;

        // Log the event
        emit OnPrincipalRepayment(paymentAmountInTokens);

        // Forward the payment to the lender
        _transferPrincipalTokens(paymentAmountInTokens, lender);

        if (ContractUtils.isContract(lender)) ILenderHookV2(lender).notifyPrincipalRepayment(_effectiveLoanAmount, principalRepaid);

        // Close the loan, if applicable
        if (loanAmountInPrincipalTokens - principalRepaid == 0) _closeLoan();
    }

    function _applyFeesAndTransferTo(IERC20NonCompliant token, uint256 amount, address destinationAddr, bytes32 categoryId, address specificAddr) private {
        // Get the applicable fee
        (uint256 feePercent, uint256 feeAmount) = ICategoryFees(feesOracle).getContextFeeAmount(amount, categoryId, specificAddr);

        require(amount > feeAmount, "Insufficient amount");

        if (feeAmount > 0) {
            if (categoryId == REPAY_INTERESTS_CATEGORY) totalInterestPaymentFees += feeAmount;

            // Transfer the fees to the collector
            token.transfer(feesCollector, feeAmount);
            emit OnFeeProcessed(feePercent, feeAmount, address(this), feesCollector);
        }

        // Transfer the funds to the recipient specified
        token.transfer(destinationAddr, amount - feeAmount);
    }

    // Closes the loan
    function _closeLoan() private {
        // Update the state of the loan
        _loanState = CLOSED;

        // Send the collateral back to the borrower, if applicable.
        if (isSecured()) {
            IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
            uint256 collateralBalanceInTokens = collateralTokenInterface.balanceOf(address(this));
            collateralTokenInterface.transfer(borrower, collateralBalanceInTokens);
            require(collateralTokenInterface.balanceOf(address(this)) == 0, "Collateral transfer failed");
        }

        emit OnLoanClosed();

        // If the lender is a smart contract then let the lender know that the loan was just closed.
        if (ContractUtils.isContract(lender)) ILenderHookV2(lender).notifyLoanClosed();
    }

    // Deposits a specific amount of tokens into this smart contract
    function _depositToken(IERC20NonCompliant tokenInterface, address senderAddr, uint256 depositAmount) private {
        require(depositAmount > 0, "Deposit amount required");

        // Check balance and allowance
        require(tokenInterface.allowance(senderAddr, address(this)) >= depositAmount, "Insufficient allowance");
        require(tokenInterface.balanceOf(senderAddr) >= depositAmount, "Insufficient funds");

        // Calculate the expected outcome, per check-effects-interaction pattern
        uint256 balanceBeforeTransfer = tokenInterface.balanceOf(address(this));
        uint256 expectedBalanceAfterTransfer = balanceBeforeTransfer + depositAmount;

        // Let the borrower deposit the predefined collateral through a partially-compliant ERC20
        tokenInterface.transferFrom(senderAddr, address(this), depositAmount);

        // Check the new balance
        uint256 actualBalanceAfterTransfer = tokenInterface.balanceOf(address(this));
        require(actualBalanceAfterTransfer == expectedBalanceAfterTransfer, "Deposit failed");
    }

    // Transfers principal tokens to the recipient specified
    function _transferPrincipalTokens(uint256 amountInPrincipalTokens, address recipientAddr) private {
        // Check the balance of the contract
        IERC20NonCompliant principalTokenInterface = IERC20NonCompliant(principalToken);
        uint256 currentBalanceAtContract = principalTokenInterface.balanceOf(address(this));
        require(currentBalanceAtContract > 0 && currentBalanceAtContract >= amountInPrincipalTokens, "Insufficient balance");

        // Transfer the funds
        uint256 currentBalanceAtRecipient = principalTokenInterface.balanceOf(recipientAddr);
        uint256 newBalanceAtRecipient = currentBalanceAtRecipient + amountInPrincipalTokens;
        uint256 newBalanceAtContract = currentBalanceAtContract - amountInPrincipalTokens;

        principalTokenInterface.transfer(recipientAddr, amountInPrincipalTokens);

        require(principalTokenInterface.balanceOf(address(this)) == newBalanceAtContract, "Balance check failed");
        require(principalTokenInterface.balanceOf(recipientAddr) == newBalanceAtRecipient, "Transfer check failed");
    }

    // ---------------------------------------------------------------
    // Views
    // ---------------------------------------------------------------
    function getCollateralToken() external view override returns (address) {
        return collateralToken;
    }

    /**
     * @notice Gets the number of collateral tokens required to represent the amount of principal specified.
     * @param principalPrice The price of the principal token
     * @param principalQty The number of principal tokens
     * @param collateralPrice The price of the collateral token
     * @param collateralDecimals The decimal positions of the collateral token
     * @return Returns the number of collateral tokens
     */
    function fromTokenToToken(uint256 principalPrice, uint256 principalQty, uint256 collateralPrice, uint256 collateralDecimals) public pure returns (uint256) {
        return ((principalPrice * principalQty) / collateralPrice) * (10 ** (collateralDecimals - 6));
    }

    /**
     * @notice Gets the minimum interest amount.
     * @return The minimum interest amount
     */
    function getMinInterestAmount() public view returns (uint256) {
        return (loanAmountInPrincipalTokens - principalRepaid) * variableApr * paymentIntervalInSeconds / 365 days / 1e4;
    }

    /**
     * @notice Gets the date of the next payment.
     * @dev This is provided for informational purposes only. The date is zero if the loan is not active.
     * @return The unix epoch that represents the next payment date.
     */
    function getNextPaymentDate() public view returns (uint256) {
        if (_loanState != ACTIVE) return 0;

        uint256 diffSeconds = block.timestamp - fundedOn; // solhint-disable-line not-rely-on-time
        uint256 currentBillingCycle = (diffSeconds < paymentIntervalInSeconds) ? 1 : ((diffSeconds % paymentIntervalInSeconds == 0) ? diffSeconds / paymentIntervalInSeconds : (diffSeconds / paymentIntervalInSeconds) + 1);

        // The date of the next payment, for informational purposes only (and for the sake of transparency)
        return fundedOn + currentBillingCycle * paymentIntervalInSeconds;
    }

    /**
     * @notice Gets the current debt.
     * @return interestDebtAmount The interest owed by the borrower at this point in time.
     * @return grossDebtAmount The gross debt amount
     * @return principalDebtAmount The amount of principal owed by the borrower at this point in time.
     * @return interestOwed The amount of interest owed by the borrower
     * @return applicableLateFee The late fee(s) applied at the current point in time.
     * @return netDebtAmount The net debt amount, which includes any late fees
     * @return daysSinceFunding The number of days that elapsed since the loan was funded.
     * @return currentBillingCycle The current billing cycle (aka: payment interval).
     * @return minPaymentAmount The minimum payment amount to submit in order to repay your debt, at any point in time, including late fees.
     * @return maxPaymentAmount The maximum amount to repay in order to close the loan.
     */
    function getDebt() public view returns (
        uint256 interestDebtAmount, 
        uint256 grossDebtAmount, 
        uint256 principalDebtAmount, 
        uint256 interestOwed, 
        uint256 applicableLateFee, 
        uint256 netDebtAmount, 
        uint256 daysSinceFunding, 
        uint256 currentBillingCycle,
        uint256 minPaymentAmount,
        uint256 maxPaymentAmount
    ) {
        // If the loan hasn't been funded or it was closed then the current debt is zero
        if (fundedOn == 0 || _loanState == CLOSED || _loanState == MATURED) return (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

        uint256 ts = block.timestamp; // solhint-disable-line not-rely-on-time
        uint256 diffSeconds = ts - aprUpdatedOn;
        currentBillingCycle = (diffSeconds < paymentIntervalInSeconds) ? 1 : ((diffSeconds % paymentIntervalInSeconds == 0) ? diffSeconds / paymentIntervalInSeconds : (diffSeconds / paymentIntervalInSeconds) + 1);
        daysSinceFunding = (diffSeconds < 86400) ? 1 : ((diffSeconds % 86400 == 0) ? diffSeconds / 86400 : (diffSeconds / 86400) + 1);
        principalDebtAmount = loanAmountInPrincipalTokens - principalRepaid;
        interestDebtAmount = loanAmountInPrincipalTokens * variableApr * daysSinceFunding / 365 / 1e4;
        require(interestDebtAmount > 0, "Interest debt cannot be zero");

        if (principalDebtAmount > 0) {
            grossDebtAmount = principalDebtAmount + interestDebtAmount;

            // Notice that the minimum interest amount could become zero due to rounding, if the principal debt is too small (say one cent)
            uint256 minInterestAmount = principalDebtAmount * variableApr * paymentIntervalInSeconds / 365 days / 1e4;

            uint256 x = currentBillingCycle * minInterestAmount;
            interestOwed = (x > interestsRepaid) ? x - interestsRepaid : uint256(0);

            // Calculate the late fee, depending on the current context
            if ((callbackDeadline > 0) && (ts > callbackDeadline)) {
                // The loan was called and the deadline elapsed (callback period + grace period)
                applicableLateFee = grossDebtAmount * latePrincipalFee / 365 / 1e4;
            } else {
                // The loan might have been called. In any case, you are still within the grace period so the principal fee does not apply
                uint256 delta = (interestOwed > minInterestAmount) ? interestOwed - minInterestAmount : uint256(0);
                applicableLateFee = delta * lateInterestFee / 365 / 1e4;
            }

            uint256 n = grossDebtAmount + applicableLateFee;
            netDebtAmount = (n > interestsRepaid) ? n - interestsRepaid : uint256(0);

            // Calculate the min/max payment amount, depending on the context
            if (callbackDeadline == 0) {
                // The loan was not called yet
                maxPaymentAmount = principalDebtAmount + applicableLateFee;
                minPaymentAmount = interestOwed + applicableLateFee;
            } else {
                // The loan was called
                maxPaymentAmount = principalDebtAmount + applicableLateFee + interestOwed;
                minPaymentAmount = maxPaymentAmount;
            }
        }
    }

    /**
     * @notice Gets the upcoming payment amount to be transferred to the lender (after fees)
     * @dev The upcoming payment after fees is zero if the loan was called.
     * @param paymentAmount The future payment amount of the borrower
     * @return upcomingPaymentAmountAfterFees The upcoming payment amount (after fees) to be transferred to the lender.
     * @return upcomingNetDebtAfterFees The interests repaid to the lender so far (after fees), including the new payment specified.
     */
    function getUpcomingAmountAfterFees(uint256 paymentAmount) external view returns (uint256 upcomingPaymentAmountAfterFees, uint256 upcomingNetDebtAfterFees) {
        // The borrower's debt at this point in time
        (, , , uint256 interestOwed, , , , , uint256 minPaymentAmount, ) = getDebt();

        if ((minPaymentAmount > 0) && (interestOwed > 0)) {
            // The loan was not called.
            require(paymentAmount >= minPaymentAmount, "Insufficient payment amount");

            uint256 applicableAmount = (paymentAmount >= interestOwed) ? interestOwed : paymentAmount;

            // The fee to collect at this point in time
            (, uint256 feeAmount) = ICategoryFees(feesOracle).getContextFeeAmount(applicableAmount, REPAY_INTERESTS_CATEGORY, address(this));

            upcomingPaymentAmountAfterFees = (applicableAmount >= feeAmount) ? applicableAmount - feeAmount : 0;
        } else {
            // Either the loan was called or the borrower repaid all the interests. 
            // At this point, the only pending debt is the principal (capital). 
            // We don't charge any fees on repayments of the principal, thus the upcoming payment amount is zero.
            upcomingPaymentAmountAfterFees = 0;
        }

        upcomingNetDebtAfterFees = (interestsRepaid - totalInterestPaymentFees) + upcomingPaymentAmountAfterFees;
    }

    /**
     * @notice Gets the boundaries of this loan.
     * @return minPayment The minimum payment amount of the loan, at this point in time.
     * @return maxPayment The payment amount required to repay the full debt and close the loan.
     * @return netDebt The net debt amount of the loan.
     */
    function getDebtBoundaries() public view override returns (uint256 minPayment, uint256 maxPayment, uint256 netDebt) {
        (, , , , , uint256 netDebtAmount, , , uint256 minPaymentAmount, uint256 maxPaymentAmount) = getDebt();
        minPayment = minPaymentAmount;
        maxPayment = maxPaymentAmount;
        netDebt = netDebtAmount;
    }

    /**
     * @notice Indicates whether the loan is secured or not.
     * @return Returns true if the loan represents secured debt.
     */
    function isSecured() public view returns (bool) {
        return collateralToken != ZERO_ADDRESS;
    }

    /**
     * @notice Gets the amount of initial collateral that needs to be deposited in this contract.
     * @return The amount of initial collateral to deposit.
     */
    function getInitialCollateralAmount() public view returns (uint256) {
        return _getCollateralAmount(_initialCollateralRatio);
    }

    /**
     * @notice Gets the amount of maintenance collateral that needs to be deposited in this contract.
     * @return The amount of maintenance collateral to deposit.
     */
    function getMaintenanceCollateralAmount() public view returns (uint256) {
        uint256 a = _getCollateralAmount(_maintenanceCollateralRatio);
        return (collateralAmountSeized <= a) ? a - collateralAmountSeized : 0;
    }

    /**
     * @notice Gets the current state of the loan.
     * @return The state of the loan
     */
    function loanState() external view override returns (uint8) {
        return _loanState;
    }

    /**
     * @notice Gets the effective amount of the loan.
     * @return The effective amount of the loan
     */
    function getEffectiveLoanAmount() external view override returns (uint256) {
        return _effectiveLoanAmount;
    }

    // Enforces the maintenance collateral ratio
    function _enforceMaintenanceRatio() private view {
        if (!isSecured()) return;

        // This is the amount of collateral tokens the borrower is required to maintain.
        uint256 expectedCollatAmount = getMaintenanceCollateralAmount();

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        require(collateralTokenInterface.balanceOf(address(this)) >= expectedCollatAmount, "Insufficient maintenance ratio");
    }

    function _getCollateralAmount(uint256 collatRatio) private view returns (uint256) {
        if (!isSecured()) return 0;

        uint256 principalPrice = IBasicPriceOracle(priceOracle).getTokenPrice(principalToken);
        require(principalPrice > 0, "Invalid price for principal");

        uint256 collateralPrice = IBasicPriceOracle(priceOracle).getTokenPrice(collateralToken);
        require(collateralPrice > 0, "Invalid price for collateral");

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        uint256 collateralDecimals = uint256(collateralTokenInterface.decimals());
        require(collateralDecimals >= 6, "Invalid collateral token");

        uint256 collateralInPrincipalTokens = loanAmountInPrincipalTokens * collatRatio / 1e4;
        return fromTokenToToken(principalPrice, collateralInPrincipalTokens, collateralPrice, collateralDecimals);
    }
}







/**
 * @notice Defines the interface for whitelisting addresses.
 */
interface IAddressWhitelist {
    /**
     * @notice Whitelists the address specified.
     * @param addr The address to enable
     */
    function enableAddress (address addr) external;

    /**
     * @notice Disables the address specified.
     * @param addr The address to disable
     */
    function disableAddress (address addr) external;

    /**
     * @notice Indicates if the address is whitelisted or not.
     * @param addr The address to disable
     * @return Returns 1 if the address is whitelisted
     */
    function isWhitelistedAddress (address addr) external view returns (bool);

    /**
     * This event is triggered when a new address is whitelisted.
     * @param addr The address that was whitelisted
     */
    event OnAddressEnabled(address addr);

    /**
     * This event is triggered when an address is disabled.
     * @param addr The address that was disabled
     */
    event OnAddressDisabled(address addr);
}



// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)




// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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


/**
 * @title Contract for whitelisting addresses
 */
contract AddressWhitelist is IAddressWhitelist, ReentrancyGuard, Ownable {
    mapping (address => bool) internal _whitelistedAddresses;

    /**
     * @notice Whitelists the address specified.
     * @param addr The address to enable
     */
    function enableAddress (address addr) external override nonReentrant onlyOwner {
        require(!_whitelistedAddresses[addr], "Already enabled");
        _whitelistedAddresses[addr] = true;
        emit OnAddressEnabled(addr);
    }

    /**
     * @notice Disables the address specified.
     * @param addr The address to disable
     */
    function disableAddress (address addr) external override nonReentrant onlyOwner {
        require(_whitelistedAddresses[addr], "Already disabled");
        _whitelistedAddresses[addr] = false;
        emit OnAddressDisabled(addr);
    }

    /**
     * @notice Indicates if the address is whitelisted or not.
     * @param addr The address to disable
     * @return Returns true if the address is whitelisted
     */
    function isWhitelistedAddress (address addr) external view override returns (bool) {
        return _whitelistedAddresses[addr];
    }
}


contract LoansDeployer is ILoansDeployer, AddressWhitelist {
    /**
     * @notice Deploys a new loan.
     * @dev This function can be called by the owner only.
     * @param newFundingPeriodInDays The funding period, in days.
     * @param newPaymentIntervalInSeconds The payment interval, in seconds.
     * @param loanAmountInPrincipalTokens The loan amount, in principal currency.
     * @param originationFeePercent2Decimals The origination fee. It is a percentage with 2 decimal places.
     * @param newAprWithTwoDecimals The APR. It is a percentage with 2 decimal places.
     * @param initialCollateralRatioWith2Decimals The initial collateral ratio, if any.
     * @param lenderAddr The address of the lender.
     * @param borrowerAddr The address of the borrower.
     * @param newCollateralToken The collateral token, if any.
     * @param newPrincipalToken The principal token.
     * @param feesManagerAddr The address authorized to define the fees collector and fees structure.
     * @param allowSeizeCollateral Indicates if the lender is allowed to seize the collateral deposited by the borrower.
     */
    function deployLoan(
        uint256 newFundingPeriodInDays,
        uint256 newPaymentIntervalInSeconds,
        uint256 loanAmountInPrincipalTokens, 
        uint256 originationFeePercent2Decimals,
        uint256 newAprWithTwoDecimals,
        uint256 initialCollateralRatioWith2Decimals,
        address lenderAddr, 
        address borrowerAddr,
        address newCollateralToken,
        address newPrincipalToken,
        address feesManagerAddr,
        bool allowSeizeCollateral
    ) external override nonReentrant returns (address) {
        require(_whitelistedAddresses[msg.sender], "Sender not whitelisted");

        // Deploy a new loan
        OpenTermLoanV3 instance = new OpenTermLoanV3(
                                                newFundingPeriodInDays,
                                                newPaymentIntervalInSeconds,
                                                loanAmountInPrincipalTokens, 
                                                originationFeePercent2Decimals,
                                                newAprWithTwoDecimals,
                                                initialCollateralRatioWith2Decimals,
                                                lenderAddr, 
                                                borrowerAddr,
                                                newCollateralToken,
                                                newPrincipalToken,
                                                feesManagerAddr,
                                                allowSeizeCollateral
                                                );

        return address(instance);
    }
}