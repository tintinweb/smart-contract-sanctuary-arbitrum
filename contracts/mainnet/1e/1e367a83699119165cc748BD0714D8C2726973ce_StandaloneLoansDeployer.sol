// SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.12;







struct LoanDeploymentParams {
    uint256 fundingPeriodInSeconds;
    uint256 newPaymentIntervalInSeconds;
    uint256 newLoanAmountInPrincipalTokens; 
    uint256 originationFeePercent2Decimals;
    uint256 newAprWithTwoDecimals;
    uint256 initialCollateralRatioWith2Decimals;
    uint256 maintenanceCollateralRatioWith2Decimals;
    uint256 lateInterestFee;
    uint256 latePrincipalFee;
    uint256 expiryInfo;
    string loanTypeInfo;
    address lenderAddr;
    address borrowerAddr;
    address newCollateralToken;
    address newPrincipalToken;
    address feesManagerAddr;
    address priceOracleAddress;
    address feesCollectorAddress;
    address categoryFeesAdress;
    bool allowSeizeCollateral;
}


interface IPermissionlessLoansDeployer {
    /**
     * @notice Triggers when a new loan is deployed.
     * @param loanAddr The address of the newly deployed loan.
     * @param lenderAddr The lender.
     * @param borrowerAddr The borrower.
     */
    event PermissionlessLoanDeployed(address indexed loanAddr, address indexed lenderAddr, address indexed borrowerAddr);

    function deployLoan(LoanDeploymentParams calldata loanParams) external returns (address);
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




interface IERC20NonCompliant {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address addr) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
}




interface ICategoryFees {
    function setContextFeeRate(uint256 feePercent, bytes32 categoryId, address specificAddr) external;
    
    function getContextFeeRate(bytes32 categoryId, address specificAddr) external view returns (uint256);
    function getContextFeeAmount(uint256 amount, bytes32 categoryId, address specificAddr) external view returns (uint256 feePercent, uint256 feeAmount);
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




interface ILenderHookV2 {
    function notifyLoanClosed() external;
    function notifyLoanMatured() external;
    function notifyPrincipalRepayment(uint256 effectiveLoanAmount, uint256 principalRepaid) external;
}






interface IPeerToPeerOpenTermLoan {
    // Functions available to the lender only
    function fundLoan() external;
    function callLoan(uint256 callbackPeriodInSeconds, uint256 gracePeriodInSeconds) external;
    function liquidate() external;
    function proposeNewApr(uint256 newAprWithTwoDecimals) external;
    function changeOracle(address newOracle) external;
    function changeLateFees(uint256 lateInterestFeeWithTwoDecimals, uint256 latePrincipalFeeWithTwoDecimals) external;
    function changeMaintenanceCollateralRatio(uint256 maintenanceCollateralRatioWith2Decimals) external;
    function seizeCollateral(uint256 amount) external;
    function returnCollateral(uint256 depositAmount) external;

    // Functions available to the borrower only
    function acceptApr() external;
    function borrowerCommitment() external;
    function claimCollateral() external;
    function repay(uint256 paymentAmount) external;
    function repayInterests() external;
    function repayPrincipal(uint256 paymentAmount) external;

    // The minimum views of a loan
    function lender() external view returns (address);
    function borrower() external view returns (address);
    function principalToken() external view returns (address);
    function collateralToken() external view returns (address);
    function loanState() external view returns (uint8);
    function currentApr() external view returns (uint256);
    function effectiveLoanAmount() external view returns (uint256);
    function getCollateralRequirements() external view returns (uint256 initialCollateralAmount, uint256 maintenanceCollateralAmount);


    function getDebt() external view returns (
        uint256 currentBillingCycle,
        uint256 cyclesSinceLastAprUpdate,
        uint256 interestOwed,
        uint256 applicableLateFee,
        uint256 minPaymentAmount,
        uint256 maxPaymentAmount
    );
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
abstract contract InitializableOpenTermLoan is IPeerToPeerOpenTermLoan, ReentrancyGuard {
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
    uint256 constant private MIN_PAYMENT_INTERVAL = uint256(3600);

    // The minimum period when calling a loan, expressed in seconds
    uint256 constant private MIN_CALLBACK_PERIOD = uint256(3600);

    // The minimum grace period when calling a loan, expressed in seconds
    uint256 constant private MIN_GRACE_PERIOD = uint256(1800);

    uint256 constant private _SECONDS_PER_YEAR_DIV100 = uint256(315360); // 315360 = (60 * 60 * 24 * 365) / 100


    // ---------------------------------------------------------------
    // Storage layout (tighly packed)
    // ---------------------------------------------------------------
    /// @notice The loan amount, expressed in principal tokens.
    uint256 public loanAmountInPrincipalTokens;

    /// @notice The effective loan amount
    uint256 public override effectiveLoanAmount;

    /// @notice The current APR of the loan, with 2 decimal places.
    uint256 public override currentApr;

    /// @notice The payment interval, expressed in seconds. For example, 1 day = 86400
    uint256 public paymentIntervalInSeconds;

    /// @notice The date in which the loan was funded by the lender. It is zero until the loan gets funded.
    uint256 public fundedOn;

    /// @notice The new APR proposed by the lender, expressed with 2 decimal places.
    uint256 public proposedApr;

    /// @notice The date (unix epoch) in which the variable APR was updated by the lender.
    uint256 public aprUpdatedOn;

    /// @notice The funding period of the loan, expressed in seconds.
    uint256 public fundingPeriod;

    /// @notice The deadline for funding the loan. The lender is required to fund the principal before this exact point in time.
    uint256 public fundingDeadline;

    /// @notice The callback deadline of the loan. It becomes greater than zero as soon as the loan gets called.
    uint256 public callbackDeadline;

    /// @notice The initial collateral ratio, with 2 decimal places. It is zero for unsecured debt.
    uint256 public initialCollateralRatio;

    /// @notice The maintenance collateral ratio, with 2 decimal places. It is zero for unsecured loans.
    uint256 public maintenanceCollateralRatio;

    /// @notice The late interests fee, as a percentage with 2 decimal places.
    uint256 public lateInterestFee;

    /// @notice The late principal fee, as a percentage with 2 decimal places.
    uint256 public latePrincipalFee;

    /// @notice The principal amount of the loan.
    uint256 public principalAmount;

    /// @notice The minimum interest amount of the loan.
    uint256 public minInterestAmount;

    /// @notice The total interest repaid since the loan was deployed.
    uint256 public totalInterestRepaid;

    /// @notice The interest repaid since the APR was updated. This value resets to zero when the APR changes.
    uint256 public cycleInterestsRepaid;

    /// @notice The amount of principal repaid so far. It gets updated when the borrower repays any principal.
    uint256 public principalRepaid;

    /// @notice The total amount of fees collected on interest repayments so far.
    uint256 public totalInterestPaymentFees;

    /// @notice The amount of collateral seized by the lender.
    uint256 public collateralAmountSeized;

    /// @notice The informational expiry date of the loan. This is provided for informational purposes only. It has no effect on how the loan works.
    uint256 public expiryInfo;

    /// @notice An informational type classifier for the loan. This is provided for informational purposes only. It has no effect on how the loan works.
    string public loanTypeInfo;

    /// @notice The address that deployed this loan.
    address public deployedBy;

    /// @notice The address of the lender per terms and conditions agreed between parties.
    address public override lender;

    /// @notice The address of the borrower per terms and conditions agreed between parties.
    address public override borrower;

    /// @notice The address of the principal token.
    address public override principalToken;

    /// @notice The address of the collateral token, if any. The collateral token is the zero address for unsecured loans.
    address public override collateralToken;

    /// @notice The address of the fees collector.
    address public feesCollector;

    /// @notice The oracle for calculating token prices.
    address public priceOracle;

    /// @notice The oracle used for calculating fees.
    address public feesOracle;

    /// @notice The manager of this loan.
    address public manager;

    /// @notice The current state of the loan
    uint8 public loanState;

    /// @notice Indicates if the lender is allowed to seize the collateral of the borrower
    bool public canSeizeCollateral;

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
        require(loanState == ACTIVE, "Loan is not active");
        _;
    }

    /**
     * @notice Throws if the loan is not active or funded.
     */
    modifier onlyIfActiveOrFunded() {
        require(loanState == ACTIVE || loanState == FUNDED, "Loan is not active");
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

    function _initLoan(LoanDeploymentParams memory params) internal {
        // Checks
        require(params.lenderAddr != ZERO_ADDRESS, "Lender required");
        require(params.borrowerAddr != ZERO_ADDRESS, "Borrower required");
        require(params.feesManagerAddr != ZERO_ADDRESS, "Fees manager required");

        require(params.borrowerAddr != params.lenderAddr, "Invalid borrower");
        require(params.feesManagerAddr != params.lenderAddr && params.feesManagerAddr != params.borrowerAddr, "Invalid fees manager");

        require(params.fundingPeriodInSeconds >= 3600, "Funding period too short");

        // The minimum loan amount is 365 * 1e4 = 3650000 = 3.650000 USDC
        require(params.newLoanAmountInPrincipalTokens > 365 * 1e4, "Invalid loan amount");

        // The minimum APR is 1 (APR: 0.01%)
        require(params.newAprWithTwoDecimals > 0, "Invalid APR");

        // The minimum payment interval is 3 hours
        require(params.newPaymentIntervalInSeconds >= MIN_PAYMENT_INTERVAL, "Payment interval too short");

        // The maximum origination fee is 90% of the loan amount
        require(params.originationFeePercent2Decimals <= 9000, "Origination fee too high");

        // Check the collateralization ratio
        if (params.newCollateralToken == ZERO_ADDRESS) {
            // Unsecured loan
            require(params.initialCollateralRatioWith2Decimals == 0, "Invalid initial collateral");
        } else {
            // Secured loan
            require(params.initialCollateralRatioWith2Decimals > 0 && params.initialCollateralRatioWith2Decimals <= 12000, "Invalid initial collateral");
        }

        require(lender == ZERO_ADDRESS, "Already initialized");

        // State changes
        lender = params.lenderAddr;
        borrower = params.borrowerAddr;
        manager = params.feesManagerAddr;

        principalToken = params.newPrincipalToken;
        collateralToken = params.newCollateralToken;
        canSeizeCollateral = params.allowSeizeCollateral;

        fundingPeriod = params.fundingPeriodInSeconds;
        currentApr = params.newAprWithTwoDecimals;
        paymentIntervalInSeconds = params.newPaymentIntervalInSeconds;
        initialCollateralRatio = params.initialCollateralRatioWith2Decimals;
        maintenanceCollateralRatio = params.maintenanceCollateralRatioWith2Decimals;

        feesCollector = params.feesCollectorAddress;
        feesOracle = params.categoryFeesAdress;
        priceOracle = params.priceOracleAddress;

        effectiveLoanAmount = params.newLoanAmountInPrincipalTokens - (params.newLoanAmountInPrincipalTokens * params.originationFeePercent2Decimals / 1e4);
        loanAmountInPrincipalTokens = params.newLoanAmountInPrincipalTokens;
        principalAmount = params.newLoanAmountInPrincipalTokens;

        minInterestAmount = principalAmount * currentApr * paymentIntervalInSeconds / _SECONDS_PER_YEAR_DIV100 / 1e6;
        loanState = PREAPPROVED;

        lateInterestFee = params.lateInterestFee;
        latePrincipalFee = params.latePrincipalFee;
        expiryInfo = params.expiryInfo;
        loanTypeInfo = params.loanTypeInfo;
    }

    // ---------------------------------------------------------------
    // Functions
    // ---------------------------------------------------------------
    /**
     * @notice Allows the borrower to accept the loan offered by the lender.
     * @dev Only the borrower is allowed to call this function. The deposit amount is zero for unsecured loans.
     */
    function borrowerCommitment() external override nonReentrant ifFeesInitialized onlyBorrower {
        // Checks
        require(loanState == PREAPPROVED, "Invalid loan state");

        // Update the state of the loan
        loanState = FUNDING_REQUIRED;

        // Set the deadline for funding the principal
        fundingDeadline = block.timestamp + fundingPeriod; // solhint-disable-line not-rely-on-time

        if (collateralToken != ZERO_ADDRESS) {
            // This is the amount of collateral the borrower is required to deposit, in tokens.
            uint256 expectedDepositAmount = _getCollateralAmount(initialCollateralRatio);

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
        require(loanState == FUNDING_REQUIRED, "Invalid loan state");

        uint256 ts = block.timestamp; // solhint-disable-line not-rely-on-time
        require(ts <= fundingDeadline, "Funding period elapsed");

        // State changes
        fundedOn = ts;
        aprUpdatedOn = ts;
        fundingDeadline = 0;
        loanState = ACTIVE;

        // Fund the loan with the expected amount of principal tokens
        _depositToken(IERC20NonCompliant(principalToken), msg.sender, effectiveLoanAmount);

        emit OnLoanFunded(effectiveLoanAmount);

        // Send principal tokens to the borrower
        _transferPrincipalTokens(effectiveLoanAmount, borrower);

        // Emit the event
        emit OnBorrowerWithdrawal(effectiveLoanAmount);
    }

    /**
     * @notice As a lender, you propose a new APR to the borrower.
     * @dev The lender is allowed to propose any new APR at their sole discretion.
     * @param newAprWithTwoDecimals The APR proposed by the lender, expressed with 2 decimal places.
     */
    function proposeNewApr(uint256 newAprWithTwoDecimals) external override nonReentrant onlyLender onlyIfActive {
        require(newAprWithTwoDecimals > 0, "Invalid APR");
        require(newAprWithTwoDecimals != currentApr, "APR already set");

        // The lender cannot propose a new APR if the loan was called.
        require(callbackDeadline == 0, "Loan was called");

        proposedApr = newAprWithTwoDecimals;

        emit OnNewAprProposed(currentApr, newAprWithTwoDecimals);
    }

    /**
     * @notice As a borrower, you are accepting the new APR proposed by the lender.
     */
    function acceptApr() external override nonReentrant onlyBorrower onlyIfActive {
        require(proposedApr > 0, "No new APR was proposed yet");
        require(callbackDeadline == 0, "Loan was called");

        (uint256 interestOwed, ) = _calculateInterestOwed();
        (uint256 applicableLateFee, , ) = _getMinMaxAmount(interestOwed);

        uint256 oldApr = currentApr;        
        currentApr = proposedApr;
        proposedApr = 0;
        aprUpdatedOn = block.timestamp;

        principalAmount = principalAmount + (interestOwed + applicableLateFee);
        cycleInterestsRepaid = 0;
        minInterestAmount = principalAmount * currentApr * paymentIntervalInSeconds / _SECONDS_PER_YEAR_DIV100 / 1e6;

        emit OnAprAcceptedByBorrower(oldApr, currentApr);
    }

    /**
     * @notice Calls the loan.
     * @dev Only the lender is allowed to call this function
     * @param callbackPeriodInSeconds The callback period, measured in seconds.
     * @param gracePeriodInSeconds The grace period, measured in seconds.
     */
    function callLoan(
        uint256 callbackPeriodInSeconds, 
        uint256 gracePeriodInSeconds
    ) external override nonReentrant onlyLender onlyIfActiveOrFunded {
        require(callbackPeriodInSeconds >= MIN_CALLBACK_PERIOD, "Invalid Callback period");
        require(gracePeriodInSeconds >= MIN_GRACE_PERIOD, "Invalid Grace period");
        require(callbackDeadline == 0, "Loan was called already");
        require(collateralAmountSeized == 0, "Return the collateral first");

        callbackDeadline = block.timestamp + (callbackPeriodInSeconds + gracePeriodInSeconds); // solhint-disable-line not-rely-on-time

        emit OnLoanCalled(callbackPeriodInSeconds, gracePeriodInSeconds);
    }

    /**
     * @notice Liquidates the loan.
     * @dev Only the lender is allowed to call this function
     */
    function liquidate() external override nonReentrant onlyLender onlyIfActiveOrFunded {
        // Checks
        require(callbackDeadline > 0, "Loan was not called yet");
        require(block.timestamp > callbackDeadline, "Callback period not elapsed"); // solhint-disable-line not-rely-on-time

        // State changes
        loanState = MATURED;

        // Transfer the collateral to the lender
        if (collateralToken != ZERO_ADDRESS) {
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

    /**
     * @notice Repays the interests portion of the loan.
     */
    function repayInterests() external override nonReentrant onlyBorrower onlyIfActive {
        // Make sure the loan hasn't been called
        require(callbackDeadline == 0, "Loan was called");

        // Enforce the maintenance collateral ratio, if applicable
        _enforceMaintenanceRatio();

        // Get the current debt
        (uint256 interestOwed, ) = _calculateInterestOwed();
        (uint256 applicableLateFee, uint256 minPaymentAmount, ) = _getMinMaxAmount(interestOwed);

        _repayInterests(interestOwed, applicableLateFee, minPaymentAmount);
    }

    /**
     * @notice Repays the principal portion of the loan.
     * @param paymentAmountInTokens The payment amount, expressed in principal tokens.
     */
    function repayPrincipal(uint256 paymentAmountInTokens) external override nonReentrant onlyBorrower onlyIfActive {
        // Checks
        require(paymentAmountInTokens > 0, "Payment amount required");

        // Enforce the maintenance collateral ratio, if applicable
        _enforceMaintenanceRatio();

        _repayPrincipal(paymentAmountInTokens);
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
        (uint256 interestOwed, ) = _calculateInterestOwed();
        (uint256 applicableLateFee, uint256 minPaymentAmount, ) = _getMinMaxAmount(interestOwed);

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
        _repayInterests(interestOwed, applicableLateFee, minPaymentAmount);

        // The payment amount we can consume in this tx
        uint256 pendingAmount = paymentAmount - minPaymentAmount;
        if (pendingAmount == 0) return;

        // At this point, the borrower repaid their interest.
        // The only option available is repay the principal.
        _repayPrincipal(pendingAmount);
    }

    /**
     * @notice Claims the collateral deposited by the borrower
     * @dev Only the borrower is allowed to call this function
     */
    function claimCollateral() external override nonReentrant onlyBorrower {
        require(collateralToken != ZERO_ADDRESS, "This loan is unsecured");
        require(loanState == FUNDING_REQUIRED, "Invalid loan state");
        require(block.timestamp > fundingDeadline, "Funding period not elapsed"); // solhint-disable-line not-rely-on-time

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        uint256 currentBalance = collateralTokenInterface.balanceOf(address(this));

        loanState = CANCELLED;

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

    // ---------------------------------------------------------------
    // Maintenance functions
    // ---------------------------------------------------------------
    /**
     * @notice Sets the address of the fees collector.
     * @param newFeesCollector The new address of the fees collector.
     */
    function setFeesCollector(address newFeesCollector) external nonReentrant onlyManager {
        require(newFeesCollector != ZERO_ADDRESS, "Fees collector required");
        feesCollector = newFeesCollector;
    }

    /**
     * @notice Sets the address of the oracle responsible for calculating fees.
     * @param newFeesOracle The address of the oracle responsible for calculating fees.
     */
    function setFeesOracle(address newFeesOracle) external nonReentrant onlyManager {
        require(newFeesOracle != ZERO_ADDRESS, "Fees oracle required");
        feesOracle = newFeesOracle;
    }

    /**
     * @notice Updates the late fees. The fee can be zero.
     * @dev Only the lender is allowed to call this function. As a lender, you cannot change the fees if the loan was called.
     * @param lateInterestFeeWithTwoDecimals The late interest fee (percentage) with 2 decimal places.
     * @param latePrincipalFeeWithTwoDecimals The late principal fee (percentage) with 2 decimal places.
     */
    function changeLateFees(
        uint256 lateInterestFeeWithTwoDecimals, 
        uint256 latePrincipalFeeWithTwoDecimals
    ) external override nonReentrant onlyLender {
        require(callbackDeadline == 0, "Loan was called");

        emit OnLateFeesChanged(lateInterestFee, lateInterestFeeWithTwoDecimals, latePrincipalFee, latePrincipalFeeWithTwoDecimals);

        lateInterestFee = lateInterestFeeWithTwoDecimals;
        latePrincipalFee = latePrincipalFeeWithTwoDecimals;
    }

    /**
     * @notice Changes the oracle that calculates token prices.
     * @dev Only the lender is allowed to call this function
     * @param newOracleAddr The new oracle for token prices
     */
    function changeOracle(address newOracleAddr) external override nonReentrant onlyLender {
        address prevAddr = priceOracle;
        require(prevAddr != newOracleAddr, "Oracle already set");

        IBasicPriceOracle newOracle = IBasicPriceOracle(newOracleAddr);

        if (collateralToken != ZERO_ADDRESS) {
            // The lender cannot change the price oracle if the loan was called.
            // Otherwise the lender could force a liquidation of the loan 
            // by changing the maintenance collateral in order to game the borrower.
            require(callbackDeadline == 0, "Loan was called");
        }

        require(address(newOracle) != address(0), "Invalid Oracle");

        priceOracle = address(newOracle);
        emit OnPriceOracleChanged(prevAddr, priceOracle);
    }

    /**
     * @notice Updates the maintenance collateral ratio
     * @dev Only the lender is allowed to call this function. As a lender, you cannot change the maintenance collateralization ratio if the loan was called.
     * @param newRatioWith2Decimals The maintenance collateral ratio, if applicable.
     */
    function changeMaintenanceCollateralRatio(uint256 newRatioWith2Decimals) external override nonReentrant onlyLender {
        // The maintenance ratio cannot be altered if the loan is unsecured
        require(collateralToken != ZERO_ADDRESS, "This loan is unsecured");

        // The maintenance ratio cannot be greater than the initial ratio
        require(newRatioWith2Decimals > 0, "Maintenance ratio required");
        require(newRatioWith2Decimals <= initialCollateralRatio, "Maintenance ratio too high");
        require(maintenanceCollateralRatio != newRatioWith2Decimals, "Value already set");

        // The lender cannot change the maintenance ratio if the loan was called.
        // Otherwise the lender could force a liquidation of the loan 
        // by changing the maintenance collateral in order to game the borrower.
        require(callbackDeadline == 0, "Loan was called");

        emit OnCollateralRatioChanged(maintenanceCollateralRatio, newRatioWith2Decimals);
        
        maintenanceCollateralRatio = newRatioWith2Decimals;
    }

    function updateInfo(uint256 newExpiryInfo, string calldata newLoanTypeInfo) external nonReentrant onlyLender {
        expiryInfo = newExpiryInfo;
        loanTypeInfo = newLoanTypeInfo;
    }

    // ---------------------------------------------------------------
    // Internal and private functions
    // ---------------------------------------------------------------
    // Repays a specific amount of interests
    function _repayInterests(
        uint256 interestOwed, 
        uint256 applicableLateFee, 
        uint256 paymentAmount
    ) private {
        require(paymentAmount > 0, "Payment amount required");
        require(interestOwed > 0, "No interests owed");

        uint256 minPaymentAmount = interestOwed + applicableLateFee;
        require(paymentAmount >= minPaymentAmount, "Min payment amount required");
        require(paymentAmount <= interestOwed + applicableLateFee, "Max amount exceeded");

        // Late fees are not included in the interest repaid.
        uint256 interestDelta = paymentAmount - applicableLateFee;
        cycleInterestsRepaid += interestDelta;
        totalInterestRepaid += interestDelta;

        // Transfer principal (payment) from the borrower to this contract
        _depositToken(IERC20NonCompliant(principalToken), msg.sender, paymentAmount);

        // Apply fees and transfer the payment amount to the lender
        _applyFeesAndTransferTo(IERC20NonCompliant(principalToken), paymentAmount, lender, REPAY_INTERESTS_CATEGORY, address(this));

        emit OnInterestsRepayment(paymentAmount);
    }
    
    // Repays a specific amount of capital
    function _repayPrincipal(uint256 paymentAmountInTokens) private {
        (uint256 interestOwed, ) = _calculateInterestOwed();
        (, , uint256 maxPaymentAmount) = _getMinMaxAmount(interestOwed);

        if (callbackDeadline > 0) {
            // If the loan was called then the borrower is required to repay the net debt amount
            require(paymentAmountInTokens == maxPaymentAmount, "Full payment expected");
        } else {
            require(interestOwed == 0, "Must repay interests first");
        }

        // If the loan was not called then the borrower can repay any principal amount of their preference 
        // as long as it does not exceed the net debt
        require(paymentAmountInTokens <= maxPaymentAmount, "Amount exceeds net debt");

        // Update the amount of principal (capital) that was repaid so far
        uint256 delta = (paymentAmountInTokens > principalAmount) ? principalAmount : paymentAmountInTokens;
        principalRepaid += delta;
        principalAmount -= delta;
        minInterestAmount = principalAmount * currentApr * paymentIntervalInSeconds / _SECONDS_PER_YEAR_DIV100 / 1e6;

        // Make sure the deposit succeeds
        _depositToken(IERC20NonCompliant(principalToken), msg.sender, paymentAmountInTokens);

        // Log the event
        emit OnPrincipalRepayment(paymentAmountInTokens);

        // Forward the payment to the lender
        _transferPrincipalTokens(paymentAmountInTokens, lender);

        if (ContractUtils.isContract(lender)) ILenderHookV2(lender).notifyPrincipalRepayment(effectiveLoanAmount, principalRepaid);

        // Close the loan, if applicable
        if (principalAmount == 0) _closeLoan();
    }

    // Closes the loan
    function _closeLoan() private {
        // Update the state of the loan
        loanState = CLOSED;

        // Send the collateral back to the borrower, if applicable.
        if (collateralToken != ZERO_ADDRESS) {
            IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
            uint256 collateralBalanceInTokens = collateralTokenInterface.balanceOf(address(this));
            collateralTokenInterface.transfer(borrower, collateralBalanceInTokens);
            require(collateralTokenInterface.balanceOf(address(this)) == 0, "Collateral transfer failed");
        }

        emit OnLoanClosed();

        // If the lender is a smart contract then let the lender know that the loan was just closed.
        if (ContractUtils.isContract(lender)) ILenderHookV2(lender).notifyLoanClosed();
    }

    function _applyFeesAndTransferTo(
        IERC20NonCompliant token, 
        uint256 amount, 
        address destinationAddr, 
        bytes32 categoryId, 
        address specificAddr
    ) private {
        // Get the applicable fee
        (uint256 feePercent, uint256 feeAmount) = ICategoryFees(feesOracle).getContextFeeAmount(amount, categoryId, specificAddr);

        require(amount > feeAmount, "Fees: Insufficient amount");

        if (feeAmount > 0) {
            if (categoryId == REPAY_INTERESTS_CATEGORY) totalInterestPaymentFees += feeAmount;

            // Transfer the fees to the collector
            token.transfer(feesCollector, feeAmount);
            emit OnFeeProcessed(feePercent, feeAmount, address(this), feesCollector);
        }

        // Transfer the funds to the recipient specified
        token.transfer(destinationAddr, amount - feeAmount);
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

    // ---------------------------------------------------------------
    // Views
    // ---------------------------------------------------------------
    /**
     * @notice Gets the number of collateral tokens required to represent the amount of principal specified.
     * @param principalPrice The price of the principal token
     * @param principalQty The number of principal tokens
     * @param collateralPrice The price of the collateral token
     * @param collateralDecimals The decimal positions of the collateral token
     * @return Returns the number of collateral tokens
     */
    function fromTokenToToken(
        uint256 principalPrice, 
        uint256 principalQty, 
        uint256 collateralPrice, 
        uint256 collateralDecimals
    ) external pure returns (uint256) {
        return _fromTokenToToken(principalPrice, principalQty, collateralPrice, collateralDecimals);
    }
    
    /**
     * @notice Gets the current debt.
     * @return currentBillingCycle The current billing cycle.
     * @return cyclesSinceLastAprUpdate The number of intervals that elapsed since the APR was updated.
     * @return interestOwed The interest owed.
     * @return applicableLateFee The applicable late fees, if any.
     * @return minPaymentAmount The minimum payment amount.
     * @return maxPaymentAmount The maximum payment amount.
     */
    function getDebt() external override view returns (
        uint256 currentBillingCycle,
        uint256 cyclesSinceLastAprUpdate,
        uint256 interestOwed,
        uint256 applicableLateFee,
        uint256 minPaymentAmount,
        uint256 maxPaymentAmount
    ) {
        if (loanState == ACTIVE) {
            uint256 ts = block.timestamp; // solhint-disable-line not-rely-on-time

            // The number of payment intervals that elapsed since the loan was funded
            uint256 diffSeconds = ts - fundedOn;
            currentBillingCycle = (diffSeconds < paymentIntervalInSeconds) ? 1 : ((diffSeconds % paymentIntervalInSeconds == 0) ? diffSeconds / paymentIntervalInSeconds : (diffSeconds / paymentIntervalInSeconds) + 1);

            (interestOwed, cyclesSinceLastAprUpdate) = _calculateInterestOwed();
            (applicableLateFee, minPaymentAmount, maxPaymentAmount) = _getMinMaxAmount(interestOwed);
        }
    }

    /**
     * @notice Gets the date of the next payment.
     * @dev This is provided for informational purposes only. The date is zero if the loan is not active.
     * @return The unix epoch that represents the next payment date.
     */
    function getNextPaymentDate() external view returns (uint256) {
        if (loanState != ACTIVE) return 0;

        uint256 diffSeconds = block.timestamp - fundedOn; // solhint-disable-line not-rely-on-time
        uint256 currentBillingCycle = (diffSeconds < paymentIntervalInSeconds) ? 1 : ((diffSeconds % paymentIntervalInSeconds == 0) ? diffSeconds / paymentIntervalInSeconds : (diffSeconds / paymentIntervalInSeconds) + 1);

        // The date of the next payment, for informational purposes only (and for the sake of transparency)
        return fundedOn + currentBillingCycle * paymentIntervalInSeconds;
    }

    /**
     * @notice Gets the upcoming payment amount to be transferred to the lender (after fees)
     * @dev The upcoming payment after fees is zero if the loan was called.
     * @param paymentAmount The future payment amount of the borrower
     * @return upcomingPaymentAmountAfterFees The upcoming payment amount (after fees) to be transferred to the lender.
     * @return upcomingNetDebtAfterFees The interests repaid to the lender so far (after fees), including the new payment specified.
     */
    function getUpcomingAmountAfterFees(uint256 paymentAmount) external view returns (
        uint256 upcomingPaymentAmountAfterFees, 
        uint256 upcomingNetDebtAfterFees
    ) {
        // The borrower's debt at this point in time
        (uint256 interestOwed, ) = _calculateInterestOwed();
        (, uint256 minPaymentAmount, ) = _getMinMaxAmount(interestOwed);

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

        upcomingNetDebtAfterFees = (totalInterestRepaid - totalInterestPaymentFees) + upcomingPaymentAmountAfterFees;
    }

    /**
     * @notice Gets the collateral requirements of a loan. Returns zero if the loan is unsecured.
     * @return initialCollateralAmount The initial collateral amount.
     * @return maintenanceCollateralAmount The maintenance collateral amount.
     */
    function getCollateralRequirements() external view override returns (
        uint256 initialCollateralAmount,
        uint256 maintenanceCollateralAmount
    ) {
        if (collateralToken != ZERO_ADDRESS) {
            initialCollateralAmount = _getCollateralAmount(initialCollateralRatio);
            maintenanceCollateralAmount = _getMaintenanceCollateralAmount();
        }
    }

    function _fromTokenToToken(
        uint256 principalPrice, 
        uint256 principalQty, 
        uint256 collateralPrice, 
        uint256 collateralDecimals
    ) internal pure returns (uint256) {
        return ((principalPrice * principalQty) / collateralPrice) * (10 ** (collateralDecimals - 6));
    }

    function _getMaintenanceCollateralAmount() internal view returns (uint256) {
        uint256 a = _getCollateralAmount(maintenanceCollateralRatio);
        return (collateralAmountSeized <= a) ? a - collateralAmountSeized : 0;
    }

    function _getCollateralAmount(uint256 collatRatio) internal view returns (uint256) {
        if (collateralToken == ZERO_ADDRESS) return 0;

        uint256 principalPrice = IBasicPriceOracle(priceOracle).getTokenPrice(principalToken);
        require(principalPrice > 0, "Invalid price for principal");

        uint256 collateralPrice = IBasicPriceOracle(priceOracle).getTokenPrice(collateralToken);
        require(collateralPrice > 0, "Invalid price for collateral");

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        uint256 collateralDecimals = uint256(collateralTokenInterface.decimals());
        require(collateralDecimals >= 6, "Invalid collateral token");

        uint256 collateralInPrincipalTokens = loanAmountInPrincipalTokens * collatRatio / 1e4;

        return _fromTokenToToken(principalPrice, collateralInPrincipalTokens, collateralPrice, collateralDecimals);
    }

    // Enforces the maintenance collateral ratio
    function _enforceMaintenanceRatio() internal view {
        if (collateralToken == ZERO_ADDRESS) return;

        // This is the amount of collateral tokens the borrower is required to maintain.
        uint256 expectedCollatAmount = _getMaintenanceCollateralAmount();

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        require(collateralTokenInterface.balanceOf(address(this)) >= expectedCollatAmount, "Insufficient maintenance ratio");
    }

    function _calculateInterestOwed() internal view returns (uint256, uint256) {
        uint256 ts = block.timestamp; // solhint-disable-line not-rely-on-time

        //uint256 diffSeconds = ts - fundedOn;
        // The number of payment intervals that elapsed since the loan was funded
        //uint256 currentBillingCycle = (diffSeconds < paymentIntervalInSeconds) ? 1 : ((diffSeconds % paymentIntervalInSeconds == 0) ? diffSeconds / paymentIntervalInSeconds : (diffSeconds / paymentIntervalInSeconds) + 1);

        // The number of billing cycles that elapsed since the APR was updated
        uint256 diffSeconds = ts - aprUpdatedOn;
        uint256 cyclesSinceLastAprUpdate = (diffSeconds < paymentIntervalInSeconds) ? 1 : ((diffSeconds % paymentIntervalInSeconds == 0) ? diffSeconds / paymentIntervalInSeconds : (diffSeconds / paymentIntervalInSeconds) + 1);

        //uint256 newMinInterestAmount = principalAmount * currentApr * paymentIntervalInSeconds / _SECONDS_PER_YEAR / uint256(100);

        // The interest owed since the APR was changed. It does not include any payment.
        uint256 grossInterestOwedAtDate = principalAmount * currentApr * (paymentIntervalInSeconds * cyclesSinceLastAprUpdate) / _SECONDS_PER_YEAR_DIV100 / 1e6;

        // The interest owed. The interest repaid gets reset to zero when the APR changes.
        uint256 w = (grossInterestOwedAtDate > cycleInterestsRepaid) ? grossInterestOwedAtDate - cycleInterestsRepaid : 0;
        return (w, cyclesSinceLastAprUpdate);
    }

    function _getMinMaxAmount(uint256 interestOwed) internal view returns (
        uint256 applicableLateFee, 
        uint256 minPaymentAmount, 
        uint256 maxPaymentAmount
    ) {
        uint256 ts = block.timestamp; // solhint-disable-line not-rely-on-time

        uint256 grossDebtAmount = principalAmount + interestOwed;

        // Calculate the late fee, depending on the current context
        if ((callbackDeadline > 0) && (ts > callbackDeadline)) {
            // The loan was called and the deadline elapsed (callback period + grace period)
            applicableLateFee = grossDebtAmount * latePrincipalFee / 365 / 1e4;
        } else {
            // The loan might have been called. In any case, you are still within the grace period so the principal fee does not apply
            uint256 delta = (interestOwed > minInterestAmount) ? interestOwed - minInterestAmount : uint256(0);
            applicableLateFee = delta * lateInterestFee / 365 / 1e4;
        }

        // Calculate the min/max payment amount, depending on the context
        if (callbackDeadline == 0) {
            // The loan was not called yet
            maxPaymentAmount = principalAmount + applicableLateFee;
            minPaymentAmount = interestOwed + applicableLateFee;
        } else {
            // The loan was called
            maxPaymentAmount = principalAmount + applicableLateFee + interestOwed;
            minPaymentAmount = maxPaymentAmount;
        }
    }
}


/**
 * @title Represents an open-term loan.
 */
contract StandaloneOpenTermLoan is InitializableOpenTermLoan {
    constructor(LoanDeploymentParams memory params) {
        deployedBy = msg.sender;
        _initLoan(params);
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
     * @notice Whitelists the addresses specified.
     * @param arr The addresses to enable
     */
    function enableAddresses (address[] calldata arr) external;

    /**
     * @notice Disables the address specified.
     * @param addr The address to disable
     */
    function disableAddress (address addr) external;

    /**
     * @notice Disables the addresses specified.
     * @param arr The addresses to disable
     */
    function disableAddresses (address[] calldata arr) external;

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




abstract contract BaseReentrancyGuard {
    uint256 internal constant _REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant _REENTRANCY_ENTERED = 2;

    uint256 internal _reentrancyStatus;

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
        require(_reentrancyStatus != _REENTRANCY_ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = _REENTRANCY_ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = _REENTRANCY_NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _reentrancyStatus == _REENTRANCY_ENTERED;
    }
}




abstract contract BaseOwnable {
    address internal _owner;

    /**
     * @notice Triggers when contract ownership changes.
     * @param previousOwner The previous owner of the contract.
     * @param newOwner The new owner of the contract.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
 * @title Standalone contract for whitelisting addresses.
 */
contract AddressWhitelist is IAddressWhitelist, BaseOwnable, BaseReentrancyGuard {
    mapping (address => bool) internal _whitelistedAddresses;

    constructor() {
        _owner = msg.sender;
    }

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
     * @notice Whitelists the addresses specified.
     * @param arr The addresses to enable
     */
    function enableAddresses (address[] calldata arr) external override nonReentrant onlyOwner {
        require(arr.length > 0, "Addresses required");

        for (uint256 i; i < arr.length; i++) {
            require(arr[i] != address(0), "Invalid address");
            require(!_whitelistedAddresses[arr[i]], "Already enabled");
            _whitelistedAddresses[arr[i]] = true;
            emit OnAddressEnabled(arr[i]);
        }
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
     * @notice Disables the addresses specified.
     * @param arr The addresses to disable
     */
    function disableAddresses (address[] calldata arr) external override nonReentrant onlyOwner {
        for (uint256 i; i < arr.length; i++) {
            require(_whitelistedAddresses[arr[i]], "Already disabled");
            _whitelistedAddresses[arr[i]] = false;
            emit OnAddressDisabled(arr[i]);
        }
    }

    /**
     * @notice Transfers ownership of the contract to a new account.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external nonReentrant onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @notice Indicates if the address is whitelisted or not.
     * @param addr The address to evaluate.
     * @return Returns true if the address is whitelisted.
     */
    function isWhitelistedAddress (address addr) external view override returns (bool) {
        return _whitelistedAddresses[addr];
    }

    /**
     * @notice Gets the owner of the contract.
     * @return The address who owns the contract.
     */
    function owner() external view returns (address) {
        return _owner;
    }
}


/**
 * @title Deployer for Standalone OpenTerm loans.
 */
contract StandaloneLoansDeployer is IPermissionlessLoansDeployer, AddressWhitelist {
    /**
     * @notice Deploys a new loan with the parameters specified.
     * @param loanParams The parameters of the loan.
     * @return address The address of the newly deployed loan.
     */
    function deployLoan(LoanDeploymentParams calldata loanParams) external override nonReentrant returns (address) {
        require(_whitelistedAddresses[msg.sender], "Sender not whitelisted");

        // Deploy a new loan
        return address(new StandaloneOpenTermLoan(loanParams));
    }
}