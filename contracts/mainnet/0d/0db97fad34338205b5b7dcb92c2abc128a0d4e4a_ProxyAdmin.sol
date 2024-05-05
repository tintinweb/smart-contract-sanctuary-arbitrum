/**
 *Submitted for verification at Arbiscan.io on 2024-05-05
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.12;

/**
 * @title Defines the interface of a basic pricing oracle.
 * @dev All prices are expressed in USD, with 6 decimal positions.
 */
interface IBasicPriceOracle {
    function updateTokenPrice (address tokenAddr, uint256 valueInUSD) external;
    function bulkUpdate (address[] memory tokens, uint256[] memory prices) external;
    function getTokenPrice (address tokenAddr) external view returns (uint256);
}

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

interface ICategoryFees {
    function setContextFeeRate(uint256 feePercent, bytes32 categoryId, address specificAddr) external;
    
    function getContextFeeRate(bytes32 categoryId, address specificAddr) external view returns (uint256);
    function getContextFeeAmount(uint256 amount, bytes32 categoryId, address specificAddr) external view returns (uint256 feePercent, uint256 feeAmount);
}

interface ILenderHookV2 {
    function notifyLoanClosed() external;
    function notifyLoanMatured() external;
    function notifyPrincipalRepayment(uint256 effectiveLoanAmount, uint256 principalRepaid) external;
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

interface IERC20NonCompliant {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address addr) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
}

abstract contract BaseOwnable {
    address internal _owner;

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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * ////IMPORTANT: The same issues {IERC20-approve} has related to transaction
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

abstract contract BasePausableLiability {
    bool internal _depositsPaused;
    bool internal _withdrawalsPaused;

    event DepositsPaused();
    event DepositsResumed();
    event WithdrawalsPaused();
    event WithdrawalsResumed();

    // --------------------------------------------------------------------------
    // Modifiers
    // --------------------------------------------------------------------------
    modifier ifDepositsNotPaused() {
        require(!_depositsPaused, "Deposits paused");
        _;
    }

    modifier ifWithdrawalsNotPaused() {
        require(!_withdrawalsPaused, "Withdrawals paused");
        _;
    }

    // --------------------------------------------------------------------------
    // Implementation functions
    // --------------------------------------------------------------------------
    function _pauseDeposits() internal virtual {
        _depositsPaused = true;
        emit DepositsPaused();
    }

    function _resumeDeposits() internal virtual {
        require(_depositsPaused, "Deposits already active");
        _depositsPaused = false;
        emit DepositsResumed();
    }

    function _pauseWithdrawals() internal virtual {
        _withdrawalsPaused = true;
        emit WithdrawalsPaused();
    }

    function _resumeWithdrawals() internal virtual {
        require(_withdrawalsPaused, "Withdrawals already active");
        _withdrawalsPaused = false;
        emit WithdrawalsResumed();
    }
}

/**
 * @title Tokenizes a liability per EIP-20.
 * @dev The liability is upgradeable per EIP-1967. Reentrancy checks in place.
 */
abstract contract BaseUpgradeableERC20 is IERC20, Initializable, BaseReentrancyGuard {
    uint8 internal _decimals;
    string internal _symbol;
    string internal _name;

    // The total circulating supply of the token
    uint256 internal _totalSupply;

    // The maximum circulating supply of the token, if any. Set to zero if there is no max limit.
    uint256 internal _maxSupply;

    // The balance of each holder
    mapping(address => uint256) internal _balances;

    // The allowance of each spender, which is set by each owner
    mapping(address => mapping(address => uint256)) internal _allowances;

    /**
     * @notice This event is triggered when the maximum limit for minting tokens is updated.
     * @param prevValue The previous limit
     * @param newValue The new limit
     */
    event OnMaxSupplyChanged(uint256 prevValue, uint256 newValue);

    // --------------------------------------------------------------------------
    // Modifiers
    // --------------------------------------------------------------------------
    /**
     * @notice Indicates if this contract implementation was initialized at the proxy
     * @dev Throws if the contract was not initialized
     */
    modifier onlyIfInitialized() {
        require(_getInitializedVersion() != type(uint8).max, "Contract not initialized yet");
        _;
    }

    // --------------------------------------------------------------------------
    // ERC-20 interface implementation
    // --------------------------------------------------------------------------
    /**
     * @notice Transfers a given amount tokens to the address specified.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return Returns true in case of success.
     */
    function transfer(address to, uint256 value) external override onlyIfInitialized nonReentrant returns (bool) {
        return _executeErc20Transfer(msg.sender, to, value);
    }

    /**
     * @notice Transfer tokens from one address to another.
     * @dev Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     * @return Returns true in case of success.
     */
    function transferFrom(address from, address to, uint256 value) external override onlyIfInitialized nonReentrant returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= value, "Amount exceeds allowance");

        require (_executeErc20Transfer(from, to, value), "Failed to execute transferFrom");

        _approveSpender(from, msg.sender, currentAllowance - value);

        return true;
    }

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering.
     * One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0
     * and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return Returns true in case of success.
     */
    function approve(address spender, uint256 value) external override onlyIfInitialized nonReentrant returns (bool) {
        _approveSpender(msg.sender, spender, value);
        return true;
    }

    function getInitializedVersion() external view onlyIfInitialized returns (uint8) {
        return _getInitializedVersion();
    }

    /**
     * @notice Gets the total circulating supply of tokens
     * @return The total circulating supply of tokens
     */
    function totalSupply() external view override onlyIfInitialized returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Gets the balance of the address specified.
     * @param addr The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address addr) external view override onlyIfInitialized returns (uint256) {
        return _balances[addr];
    }

    /**
     * @notice Function to check the amount of tokens that an owner allowed to a spender.
     * @param ownerAddr address The address which owns the funds.
     * @param spenderAddr address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address ownerAddr, address spenderAddr) external view override onlyIfInitialized returns (uint256) {
        return _allowances[ownerAddr][spenderAddr];
    }

    /**
     * @notice Gets the symbol of the token.
     * @return Returns a string containing the token symbol.
     */
    function symbol() external view onlyIfInitialized returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Gets the descriptive name of the token.
     * @return Returns the name of the token.
     */
    function name() external view onlyIfInitialized returns (string memory) {
        return _name;
    }

    /**
     * @notice Gets the decimals of the token.
     * @return Returns the decimals precision of the token.
     */
    function decimals() external view onlyIfInitialized returns (uint8) {
        return _decimals;
    }

    function maxSupply() external view onlyIfInitialized returns (uint256) {
        return _maxSupply;
    }

    // --------------------------------------------------------------------------
    // Implementation functions
    // --------------------------------------------------------------------------
    function _executeErc20Transfer(address from, address to, uint256 value) internal virtual returns (bool) {
        // Checks
        require(to != address(0), "non-zero address required");
        require(from != address(0), "non-zero sender required");
        require(value > 0, "Amount cannot be zero");
        require(_balances[from] >= value, "Amount exceeds sender balance");

        // State changes
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;

        // Emit the event per ERC-20
        emit Transfer(from, to, value);

        return true;
    }

    function _approveSpender(address ownerAddr, address spender, uint256 value) internal virtual {
        require(spender != address(0), "non-zero spender required");
        require(ownerAddr != address(0), "non-zero owner required");

        // State changes
        _allowances[ownerAddr][spender] = value;

        // Emit the event
        emit Approval(ownerAddr, spender, value);
    }

    function _spendAllowance (address ownerAddr, address spenderAddr, uint256 amount) internal virtual {
        uint256 currentAllowance = _allowances[ownerAddr][spenderAddr];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approveSpender(ownerAddr, spenderAddr, currentAllowance - amount);
        }
    }

    function _mintErc20(address addr, uint256 amount) internal virtual {
        require(amount > 0, "Invalid amount");
        require(_canMint(amount), "Max supply limit reached");

        _totalSupply += amount;
        _balances[addr] += amount;

        emit Transfer(address(0), addr, amount);
    }

    function _burnErc20(address addr, uint256 amount) internal virtual {
        require(amount > 0, "Invalid amount");
        require(_balances[addr] >= amount, "Burn amount exceeds balance");

        _balances[addr] -= amount;
        _totalSupply -= amount;

        emit Transfer(addr, address(0), amount);
    }

    function _setMaxSupply(uint256 newValue) internal virtual {
        require(newValue > 0 && newValue > _totalSupply, "Invalid max supply");

        uint256 prevValue = _maxSupply;
        _maxSupply = newValue;

        emit OnMaxSupplyChanged(prevValue, newValue);
    }

    // Indicates if we can issue/mint the number of tokens specified.
    function _canMint(uint256 amount) internal view virtual returns (bool) {        
        return _maxSupply - _totalSupply >= amount;
    }
}

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

/**
 * @title Represents a liquidity pool. The pool works per ERC-4626 standard. The pool can be paused.
 */
abstract contract BaseUpgradeableERC4626 is IERC4626, BaseUpgradeableERC20, BasePausableLiability {
    using MathUpgradeable for uint256;

    IERC20 internal _underlyingAsset;
    uint256 internal _maxDepositAmount;
    uint256 internal _maxWithdrawalAmount;

    // Space reserved for future upgrades
    uint256[30 - 13] private __gap;

    // ---------------------------------------------------------------
    // Modifiers
    // ---------------------------------------------------------------
    modifier ifConfigured() {
        require(address(_underlyingAsset) != address(0), "Not configured");
        _;
    }

    modifier ifNotConfigured() {
        require(address(_underlyingAsset) == address(0), "Already configured");
        _;
    }

    // --------------------------------------------------------------------------
    // ERC-4626 interface implementation
    // --------------------------------------------------------------------------
    /**
     * @notice Deposits funds in the pool. Issues LP tokens in exchange for the deposit.
     * @dev Throws if the deposit limit is reached.
     * @param assets The deposit amount, expressed in underlying tokens. For example: USDC, DAI, etc.
     * @param receiver The address that will receive the LP tokens. It is usually the same as a the sender.
     * @return shares The number of LP tokens issued to the receiving address specified.
     */
    function deposit(
        uint256 assets, 
        address receiver
    ) external override onlyIfInitialized nonReentrant ifConfigured ifDepositsNotPaused returns (uint256 shares) {
        require(receiver != address(0) && receiver != address(this), "Invalid receiver");
        require(assets > 0, "Assets amount required");
        require(assets <= maxDeposit(receiver), "Deposit limit reached");

        shares = previewDeposit(assets);
        require(shares > 0, "Shares amount required");

        _deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Issues a specific amount of LP tokens to the receiver specified.
     * @dev Throws if the deposit limit is reached regardless of how many LP tokens you want to mint.
     * @param shares The amount of LP tokens to mint.
     * @param receiver The address of the receiver. It is usually the same as a the sender.
     * @return assets The amount of underlying assets per current ratio
     */
    function mint(
        uint256 shares, 
        address receiver
    ) external override onlyIfInitialized nonReentrant ifConfigured ifDepositsNotPaused returns (uint256 assets) {
        require(receiver != address(0) && receiver != address(this), "Invalid receiver");
        require(shares > 0, "Shares amount required");
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        assets = previewMint(shares);
        require(assets <= maxDeposit(receiver), "Deposit limit reached");

        _deposit(msg.sender, receiver, assets, shares);
    }

    function getIssuanceLimits() external view virtual returns (uint256, uint256) {
        return (_maxDepositAmount, _maxWithdrawalAmount);
    }

    function depositsPaused() external view virtual returns (bool) {
        return _depositsPaused;
    }

    function withdrawalsPaused() external view virtual returns (bool) {
        return _withdrawalsPaused;
    }

    /**
     * @notice Gets the underlying asset of the pool.
     * @return Returns the address of the asset.
     */
    function asset() external view override onlyIfInitialized returns (address) {
        return address(_underlyingAsset);
    }

    function totalAssets() external view virtual override onlyIfInitialized ifConfigured returns (uint256) {
        return _getTotalAssets();
    }

    function previewDeposit(uint256 assets) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    function previewMint(uint256 shares) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Up);
    }

    function previewWithdraw(uint256 assets) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Up);
    }

    function previewRedeem(uint256 shares) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    function convertToShares(uint256 assets) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    function convertToAssets(uint256 shares) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    function maxDeposit(address) public view virtual override onlyIfInitialized returns (uint256) {
        return _isVaultHealthy() ? _maxDepositAmount : 0;
    }

    function maxMint(address) public view virtual override onlyIfInitialized returns (uint256) {
        return _maxSupply;
    }

    function maxWithdraw(address holderAddr) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToAssets(_balances[holderAddr], MathUpgradeable.Rounding.Down);
    }

    function maxRedeem(address holderAddr) public view virtual override onlyIfInitialized returns (uint256) {
        return _balances[holderAddr];
    }

    // --------------------------------------------------------------------------
    // Implementation functions
    // --------------------------------------------------------------------------
    function _deposit(
        address callerAddr,
        address receiverAddr,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        uint256 expectedBalanceAfterTransfer = assets + _underlyingAsset.balanceOf(address(this));
        SafeERC20.safeTransferFrom(_underlyingAsset, callerAddr, address(this), assets);
        require(_underlyingAsset.balanceOf(address(this)) == expectedBalanceAfterTransfer, "Balance check failed");

        // Issue (mint) LP tokens to the receiver
        _mintErc20(receiverAddr, shares);

        // Log the ERC-4626 event
        emit Deposit(callerAddr, receiverAddr, assets, shares);
    }

    function _updateIssuanceLimits(
        uint256 newMaxDepositAmount, 
        uint256 newMaxWithdrawalAmount, 
        uint256 newMaxTokenSupply
    ) internal virtual {
        require(newMaxDepositAmount > 0, "Invalid deposit limit");
        require(newMaxWithdrawalAmount > 0, "Invalid withdrawal limit");
        
        _setMaxSupply(newMaxTokenSupply);

        _maxDepositAmount = newMaxDepositAmount;
        _maxWithdrawalAmount = newMaxWithdrawalAmount;
    }

    // --------------------------------------------------------------------------
    // Inner views
    // --------------------------------------------------------------------------
    function _getTotalAssets() internal view virtual returns (uint256) {
        return _underlyingAsset.balanceOf(address(this)); // _cachedBalance
    }

    function _isVaultHealthy() internal view virtual returns (bool) {
        return _totalSupply == 0 || _getTotalAssets() > 0;
    }

    // Internal conversion function (from assets to shares) to apply when the vault is empty.
    function _initialConvertToShares(uint256 assets, MathUpgradeable.Rounding) internal view virtual returns (uint256 shares) {
        return assets;
    }

    // Internal conversion function (from shares to assets) to apply when the vault is empty.
    function _initialConvertToAssets(uint256 shares, MathUpgradeable.Rounding) internal view virtual returns (uint256) {
        return shares;
    }

    // Internal conversion function (from assets to shares) with support for rounding direction.
    // Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. 
    // That corresponds to a case where any asset would represent an infinite amount of shares.
    function _convertToShares(uint256 assets, MathUpgradeable.Rounding rounding) internal view virtual returns (uint256) {
        return (assets == 0 || _totalSupply == 0) ? _initialConvertToShares(assets, rounding) : assets.mulDiv(_totalSupply, _getTotalAssets(), rounding);
    }

    // Internal conversion function (from shares to assets) with support for rounding direction.
    function _convertToAssets(uint256 shares, MathUpgradeable.Rounding rounding) internal view virtual returns (uint256) {
        return (_totalSupply == 0) ? _initialConvertToAssets(shares, rounding) : shares.mulDiv(_getTotalAssets(), _totalSupply, rounding);
    }
}

library DateUtils {
    // The number of seconds per day
    uint256 internal constant SECONDS_PER_DAY = 24 * 60 * 60;

    // The number of seconds per hour
    uint256 internal constant SECONDS_PER_HOUR = 60 * 60;

    // The number of seconds per minute
    uint256 internal constant SECONDS_PER_MINUTE = 60;

    // The offset from 01/01/1970
    int256 internal constant OFFSET19700101 = 2440588;

    function timestampToDate(uint256 ts) public pure returns (uint256 year, uint256 month, uint256 day) {
        (year, month, day) = _daysToDate(ts / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function timestampFromDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }

    /**
     * @notice Calculate year/month/day from the number of days since 1970/01/01 using the date conversion algorithm from http://aa.usno.navy.mil/faq/docs/JD_Formula.php and adding the offset 2440588 so that 1970/01/01 is day 0
     * @dev Taken from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
     * @param _days The year
     * @return year The year
     * @return month The month
     * @return day The day
     */
    function _daysToDate (uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        int256 __days = int256(_days);

        int256 x = __days + 68569 + OFFSET19700101;
        int256 n = 4 * x / 146097;
        x = x - (146097 * n + 3) / 4;
        int256 _year = 4000 * (x + 1) / 1461001;
        x = x - 1461 * _year / 4 + 31;
        int256 _month = 80 * x / 2447;
        int256 _day = x - 2447 * _month / 80;
        x = _month / 11;
        _month = _month + 2 - 12 * x;
        _year = 100 * (n - 49) + _year + x;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    /**
     * @notice Calculates the number of days from 1970/01/01 to year/month/day using the date conversion algorithm from http://aa.usno.navy.mil/faq/docs/JD_Formula.php and subtracting the offset 2440588 so that 1970/01/01 is day 0
     * @dev Taken from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
     * @param year The year
     * @param month The month
     * @param day The day
     * @return _days Returns the number of days
     */
    function _daysFromDate (uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970, "Error");
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint256(__days);
    }
}

/**
 * @title Represents a liquidity pool in which withdrawals are time-locked.
 */
abstract contract TimelockedERC4626 is BaseUpgradeableERC4626 {
    uint256 constant internal _TIMESTAMP_MANIPULATION_WINDOW = 5 minutes;

    struct RedeemSummary {
        uint256 shares;
        uint256 assets;
    }

    uint8 internal _liquidationHour;
    uint256 internal _lagDuration;

    mapping (bytes32 => RedeemSummary) internal _dailyRequirement;
    mapping (bytes32 => address[]) private _uniqueReceiversPerCluster;
    mapping (bytes32 => mapping(address => uint256)) internal _receiverAmounts;
    mapping (bytes32 => mapping(address => uint256)) internal _burnableAmounts;
    
    /**
     * @notice This event is triggered when a holder requests a withdrawal.
     * @param ownerAddr The address of the holder.
     * @param receiverAddr The address of the receiver.
     * @param shares The amount of shares (LP tokens) to burn.
     * @param assets The amount of underlying assets to transfer.
     * @param year The year component of the scheduled date.
     * @param month The month component of the scheduled date.
     * @param day The day component of the scheduled date.
     */
    event WithdrawalRequested (address ownerAddr, address receiverAddr, uint256 shares, uint256 assets, uint256 year, uint256 month, uint256 day);

    // ----------------------------------------
    // ERC-4626 endpoint overrides
    // ----------------------------------------
    function withdraw(
        uint256, 
        address, 
        address
    ) external override pure returns (uint256) {
        // Revert the call to ERC4626.withdraw(args) in order to stay compatible with the ERC-4626 standard.
        // Per ERC-4626 spec (https://eips.ethereum.org/EIPS/eip-4626):
        // - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).
        // - Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed. 
        //   Those methods should be performed separately.
        revert("Withdrawal request required");

        // We could enqueue a withdrawal request from this endpoint, but it wouldn't compatible with the ERC-4626 standard.
        // Likewise, we could process the funds for the receiver sppecified but -again- it wouldn't compatible with the ERC-4626 standard.
        // Hence the tx revert. Provided we revert in all cases, the function becomes pure.
    }

    function redeem(
        uint256, 
        address, 
        address
    ) external override pure returns (uint256) {
        // Revert the call to ERC4626.redeem(args) in order to stay compatible with the ERC-4626 standard.
        // Per ERC-4626 spec (https://eips.ethereum.org/EIPS/eip-4626):
        // - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).
        // - Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed. 
        //   Those methods should be performed separately.
        revert("Withdrawal request required");

        // We could enqueue a withdrawal request from this endpoint, but it wouldn't compatible with the ERC-4626 standard.
        // Likewise, we could process the funds for the receiver sppecified but -again- it wouldn't compatible with the ERC-4626 standard.
        // Hence the tx revert. Provided we revert in all cases, the function becomes pure.
    }

    // ----------------------------------------
    // Timelocked ERC-4626 features
    // ----------------------------------------
    /**
     * @notice Requests to redeem a given number of shares from the holder specified.
     * @dev The respective amount of assets will be made available in X hours from now, where "X" is the lag defined by the owner of the pool.
     * @param shares The number of shares to burn.
     * @param receiverAddr The address of the receiver.
     * @param holderAddr The address of the tokens holder.
     * @return Returns a tuple containing (assets, claimableEpoch)
     */
    function requestRedeem(
        uint256 shares, 
        address receiverAddr, 
        address holderAddr
    ) external onlyIfInitialized nonReentrant ifConfigured ifWithdrawalsNotPaused returns (uint256, uint256) {
        // The number of assets the receiver will get at the current price/ratio, per ERC-4626.
        uint256 assets = previewRedeem(shares);

        uint256 claimableEpoch = _registerRedeemRequest(shares, assets, holderAddr, receiverAddr, msg.sender);

        return (assets, claimableEpoch);
    }

    /**
     * @notice Allows any public address to process the scheduled withdrawal requests of the receiver specified.
     * @dev Throws if the receiving address is not the legitimate address you registered via "requestRedeem()"
     * @param year The year component of the claim. It can be a past date.
     * @param month The month component of the claim. It can be a past date.
     * @param day The day component of the claim. It can be a past date.
     * @param receiverIndex The index of the receiver, which can calculated off-chain.
     * @param receiverAddr The address of the legitimate receiver of the funds.
     * @return shares The effective number of shares (LP tokens) that were burnt from the liquidity pool.
     * @return assets The effective amount of underlying assets that were transfered to the receiver.
     */
    function claim(
        uint256 year, 
        uint256 month, 
        uint256 day,
        uint256 receiverIndex,
        address receiverAddr
    ) external onlyIfInitialized nonReentrant ifConfigured returns (uint256, uint256) {
        // This function is provided as a fallback.
        // If -for any reason- a third party does not process the scheduled withdrawals then the 
        // legitimate receiver can claim the respective funds on their own.
        // Thus as a legitimate receiver you can always claim your funds, even if the processing party fails to honor their promise.

        require(receiverAddr != address(0) && receiverAddr != address(this), "Invalid receiver");

        uint256 balanceBefore = IERC20(_underlyingAsset).balanceOf(address(this));
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));

        uint256 shares = _burnableAmounts[dailyCluster][receiverAddr];
        require(shares > 0, "No shares for receiver");

        uint256 assets = _receiverAmounts[dailyCluster][receiverAddr];
        require(assets > 0, "No assets for receiver");

        // Make sure withdrawals are processed at the expected epoch only.
        require(block.timestamp + _TIMESTAMP_MANIPULATION_WINDOW >= DateUtils.timestampFromDateTime(year, month, day, _liquidationHour, 0, 0), "Too early");

        // Make sure the pool has enough balance to cover withdrawals.
        require(balanceBefore >= assets, "Insufficient balance");

        // Internal state changes (trusted)
        _receiverAmounts[dailyCluster][receiverAddr] = 0;
        _burnableAmounts[dailyCluster][receiverAddr] = 0;
        _dailyRequirement[dailyCluster].shares -= shares;
        _dailyRequirement[dailyCluster].assets -= assets;

        _deleteReceiver(dailyCluster, receiverIndex, receiverAddr);

        _burnErc20(address(this), shares);

        SafeERC20.safeTransfer(_underlyingAsset, receiverAddr, assets);

        // Balance check, provided the external asset is untrusted
        require(IERC20(_underlyingAsset).balanceOf(address(this)) == balanceBefore - assets, "Balance check failed");

        return (shares, assets);
    }

    /**
     * @notice Processes all of the withdrawal requests scheduled for the date specified.
     * @dev Throws if the date is earlier than the liquidation/processing hour.
     * @param year The year component of the claim. It can be a past date.
     * @param month The month component of the claim. It can be a past date.
     * @param day The day component of the claim. It can be a past date.
     */
    function processAllClaimsByDate(
        uint256 year, 
        uint256 month, 
        uint256 day
    ) external onlyIfInitialized nonReentrant ifConfigured {
        uint256 balanceBefore = IERC20(_underlyingAsset).balanceOf(address(this));
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));
        uint256 totalLiabilityAmount = _dailyRequirement[dailyCluster].assets;

        // Make sure we have pending requests to process.
        require(totalLiabilityAmount > 0, "Nothing to process");

        // Make sure withdrawals are processed at the expected epoch only.
        require(block.timestamp + _TIMESTAMP_MANIPULATION_WINDOW >= DateUtils.timestampFromDateTime(year, month, day, _liquidationHour, 0, 0), "Too early");

        // Make sure the pool has enough balance to cover withdrawals.
        require(balanceBefore >= totalLiabilityAmount, "Insufficient balance");

        // This is the number of unique ERC20 transfers we will need to make in this transaction
        uint256 totalReceiversByDate = _uniqueReceiversPerCluster[dailyCluster].length;

        // Internal state changes (trusted)
        address[] memory receivers = new address[](totalReceiversByDate);
        uint256[] memory amounts = new uint256[](totalReceiversByDate);

        for (uint256 i; i < totalReceiversByDate; i++) {
            address receiverAddr = _uniqueReceiversPerCluster[dailyCluster][i];
            receivers[i] = receiverAddr;
            amounts[i] = _receiverAmounts[dailyCluster][receiverAddr];

            _receiverAmounts[dailyCluster][receiverAddr] = 0;
            _burnableAmounts[dailyCluster][receiverAddr] = 0;
        }

        _burnErc20(address(this), _dailyRequirement[dailyCluster].shares);

        delete _dailyRequirement[dailyCluster];
        delete _uniqueReceiversPerCluster[dailyCluster];

        // Untrusted external calls
        for (uint256 i; i < totalReceiversByDate; i++) {
            SafeERC20.safeTransfer(_underlyingAsset, receivers[i], amounts[i]);
        }

        // Balance check, provided the external asset is untrusted
        require(IERC20(_underlyingAsset).balanceOf(address(this)) == balanceBefore - totalLiabilityAmount, "Balance check failed");
    }

    // ----------------------------------------
    // Views
    // ----------------------------------------
    function getWithdrawalEpoch() external view onlyIfInitialized ifConfigured returns (
        uint256 year, 
        uint256 month, 
        uint256 day,
        uint256 claimableEpoch
    ) {
        (year, month, day) = DateUtils.timestampToDate(block.timestamp + _TIMESTAMP_MANIPULATION_WINDOW + _lagDuration);
        claimableEpoch = DateUtils.timestampFromDateTime(year, month, day, _liquidationHour, 0, 0);
    }

    /**
     * @notice Gets the funding requirement of the date specified.
     * @param year The year.
     * @param month The month.
     * @param day The day.
     * @return shares The number of shares (LP tokens) that will be burned on the date specified.
     * @return assets The amount of assets that will be transferred on the date specified.
     */
    function getRequirementByDate(
        uint256 year, 
        uint256 month, 
        uint256 day
    ) external view onlyIfInitialized returns (uint256 shares, uint256 assets) {
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));        
        shares = _dailyRequirement[dailyCluster].shares;
        assets = _dailyRequirement[dailyCluster].assets;
    }

    function getClaimableAmountByReceiver(
        uint256 year, 
        uint256 month, 
        uint256 day,
        address receiverAddr
    ) external view onlyIfInitialized returns (uint256) {
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));
        return _receiverAmounts[dailyCluster][receiverAddr];
    }

    function getBurnableAmountByReceiver(
        uint256 year, 
        uint256 month, 
        uint256 day,
        address receiverAddr
    ) external view onlyIfInitialized returns (uint256) {
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));

        return _burnableAmounts[dailyCluster][receiverAddr];
    }

    function getScheduledTransactionsByDate(
        uint256 year, 
        uint256 month, 
        uint256 day
    ) external view onlyIfInitialized returns (uint256 totalTransactions, uint256 executionEpoch) {
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));

        totalTransactions = _uniqueReceiversPerCluster[dailyCluster].length;
        executionEpoch = DateUtils.timestampFromDateTime(year, month, day, _liquidationHour, 0, 0);
    }

    function fromTimestampFromDate(uint256 ts) external pure returns (
        uint256 year, 
        uint256 month, 
        uint256 day
    ) {
        (year, month, day) = DateUtils.timestampToDate(ts);
    }

    function getReceiverIndex(
        uint256 year, 
        uint256 month, 
        uint256 day,
        address receiverAddr
    ) public view returns (uint256) {
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));

        for (uint256 i; i < _uniqueReceiversPerCluster[dailyCluster].length; i++) {
            if (_uniqueReceiversPerCluster[dailyCluster][i] == receiverAddr) return i;
        }

        return type(uint256).max;
    }

    // ----------------------------------------
    // Inner functions
    // ----------------------------------------
    function _registerRedeemRequest(
        uint256 shares, 
        uint256 assets,
        address holderAddr, 
        address receiverAddr,
        address callerAddr
    ) internal returns (uint256) {
        require(receiverAddr != address(0) && receiverAddr != address(this), "Invalid receiver");
        require(holderAddr != address(0) && holderAddr != address(this), "Invalid holder");
        require(shares > 0, "Shares amount required");
        require(assets > 0, "Assets amount required");
        require(_balances[holderAddr] >= shares, "Insufficient shares");
        require(assets <= maxWithdraw(holderAddr), "Withdrawal limit reached");

        // The time slot (cluster) of the lagged withdrawal
        (uint256 year, uint256 month, uint256 day) = DateUtils.timestampToDate(block.timestamp + _TIMESTAMP_MANIPULATION_WINDOW + _lagDuration);

        // The hash of the cluster
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));

        // The withdrawal will be processed at the following epoch
        uint256 claimableEpoch = DateUtils.timestampFromDateTime(year, month, day, _liquidationHour, 0, 0);

        // ERC20 allowance scenario
        if (callerAddr != holderAddr) _spendAllowance(holderAddr, callerAddr, shares);

        // Transfer the shares from the token holder to this contract.
        // We transfer the shares to the liquidity pool in order to avoid fluctuations on the token price.
        // Otherwise, burning shares at this point in time would affect the number of assets (liability) 
        // of future withdrawal requests because the token price would increase.
        _executeErc20Transfer(holderAddr, address(this), shares);

        // Global metrics
        _dailyRequirement[dailyCluster].assets += assets;
        _dailyRequirement[dailyCluster].shares += shares;

        // Unique receivers by date. We will transfer underlying tokens to this receiver shortly.
        if (_receiverAmounts[dailyCluster][receiverAddr] == 0) {
            _uniqueReceiversPerCluster[dailyCluster].push(receiverAddr);
        }

        // Track the amount of underlying assets we are required to transfer to the receiver address specified.
        _receiverAmounts[dailyCluster][receiverAddr] += assets;

        _burnableAmounts[dailyCluster][receiverAddr] += shares;

        emit WithdrawalRequested(holderAddr, receiverAddr, shares, assets, year, month, day);

        return claimableEpoch;
    }

    function _deleteReceiver(bytes32 dailyCluster, uint256 idx, address addr) private {
        require(idx < _uniqueReceiversPerCluster[dailyCluster].length, "Invalid receiver index");
        require(_uniqueReceiversPerCluster[dailyCluster][idx] == addr, "Address/index mismatch");

        uint256 totalReceiversByDate = _uniqueReceiversPerCluster[dailyCluster].length;
        address lastItem = _uniqueReceiversPerCluster[dailyCluster][totalReceiversByDate - 1];

        if (addr != lastItem) {
            _uniqueReceiversPerCluster[dailyCluster][totalReceiversByDate - 1] = _uniqueReceiversPerCluster[dailyCluster][idx];
            _uniqueReceiversPerCluster[dailyCluster][idx] = lastItem;
        }
        
        _uniqueReceiversPerCluster[dailyCluster].pop();
    }
}

/**
 * @title Represents an ownable liquidity pool. The pool is compliant with the ERC-4626 standard.
 */
abstract contract OwnableLiquidityPool is TimelockedERC4626, BaseOwnable {
    /**
     * @notice This event is triggered when the owner runs an emergency withdrawal.
     * @param withdrawalAmount The withdrawal amount.
     * @param tokenAddr The token address.
     * @param destinationAddr The destination address.
     */
    event OnEmergencyWithdraw (uint256 withdrawalAmount, address tokenAddr, address destinationAddr);

    /**
     * @notice Allows the owner of the pool to withdraw the full balance of the token specified.
     * @dev Throws if the caller is not the current owner of the pool. If the asset to withdraw is the underlying asset of the pool then this function pauses deposits and withdrawals automatically.
     * @param token The token to transfer.
     * @param destinationAddr The destination address of the ERC20 transfer.
     */
    function emergencyWithdraw(
        IERC20 token,
        address destinationAddr
    ) external virtual onlyIfInitialized nonReentrant ifConfigured onlyOwner {
        require(destinationAddr != address(0) && destinationAddr != address(this), "Invalid address");

        uint256 currentBalance = token.balanceOf(address(this));
        require(currentBalance > 0, "Insufficient balance");

        if (address(token) == address(_underlyingAsset)) {
            // Automatically pause deposits and withdrawals in order to prevent fluctuations on the price of the LP token
            _pauseDeposits();
            _pauseWithdrawals();
        }

        SafeERC20.safeTransfer(token, destinationAddr, currentBalance);

        emit OnEmergencyWithdraw(currentBalance, address(token), destinationAddr);
    }

    /**
     * @notice Gets the owner of the pool.
     * @return address The address who owns the pool.
     */
    function owner() external view onlyIfInitialized returns (address) {
        return _owner;
    }
}

/**
 * @title Represents an ERC-4626 compliant liquidity pool capable of lending funds on their own.
 * @dev This liquidity pool is ownable by definition.
 */
abstract contract AbstractLender is OwnableLiquidityPool {
    // ---------------------------------------------------------------
    // States of a loan
    // ---------------------------------------------------------------
    uint8 constant internal PREAPPROVED = 1;        // The loan was pre-approved by the lender
    uint8 constant internal FUNDING_REQUIRED = 2;   // The loan was accepted by the borrower. Waiting for the lender to fund the loan.
    uint8 constant internal FUNDED = 3;             // The loan was funded.
    uint8 constant internal ACTIVE = 4;             // The loan is active.
    uint8 constant internal CANCELLED = 5;          // The lender failed to fund the loan and the borrower claimed their collateral.
    uint8 constant internal MATURED = 6;            // The loan matured. It was liquidated by the lender.
    uint8 constant internal CLOSED = 7;             // The loan was closed normally.

    address internal _loansOperator;

    // Space reserved for future upgrades
    uint256[10] private __gap;

    // ---------------------------------------------------------------
    // Modifiers
    // ---------------------------------------------------------------
    modifier onlyLoansOperator() {
        require(msg.sender == _loansOperator, "Loans Operator only");
        _;
    }

    // ---------------------------------------------------------------
    // Implementation functions
    // ---------------------------------------------------------------
    /**
     * @notice Changes the oracle that calculates the token prices of the loan specified.
     * @param loanAddr The address of the loan.
     * @param newOracle The new oracle for token prices
     */
    function changeOracle(
        address loanAddr, 
        IBasicPriceOracle newOracle
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).changeOracle(newOracle);
    }

    /**
     * @notice As a lender, this pool proposes a new APR to the borrower of the loan address specified.
     * @param loanAddr The address of the loan.
     * @param newAprWithTwoDecimals The APR proposed by this pool, expressed with 2 decimal places.
     */
    function proposeNewApr(
        address loanAddr, 
        uint256 newAprWithTwoDecimals
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).proposeNewApr(newAprWithTwoDecimals);
    }

    /**
     * @notice Updates the late fees of the loan specified.
     * @param loanAddr The address of the loan.
     * @param lateInterestFeeWithTwoDecimals The late interest fee (percentage) with 2 decimal places.
     * @param latePrincipalFeeWithTwoDecimals The late principal fee (percentage) with 2 decimal places.
     */
    function changeLateFees(
        address loanAddr, 
        uint256 lateInterestFeeWithTwoDecimals, 
        uint256 latePrincipalFeeWithTwoDecimals
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).changeLateFees(lateInterestFeeWithTwoDecimals, latePrincipalFeeWithTwoDecimals);
    }

    /**
     * @notice Updates the maintenance collateral ratio
     * @param loanAddr The address of the loan.
     * @param maintenanceCollateralRatioWith2Decimals The maintenance collateral ratio, if applicable.
     */
    function changeMaintenanceCollateralRatio(
        address loanAddr, 
        uint256 maintenanceCollateralRatioWith2Decimals
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).changeMaintenanceCollateralRatio(maintenanceCollateralRatioWith2Decimals);
    }

    /**
     * @notice Allows the pool to capture a specific amount of collateral.
     * @param loanAddr The address of the loan.
     * @param amount The amount of collateral to seize.
     */
    function seizeCollateral(
        address loanAddr, 
        uint256 amount
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).seizeCollateral(amount);
    }

    /**
     * @notice Allows the pool to redeposit the collateral seized before.
     * @param loanAddr The address of the loan.
     * @param depositAmount The amount of collateral to return to the borrower.
     */
    function returnCollateral(
        address loanAddr, 
        uint256 depositAmount
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);

        address collateralTokenAddr = IOpenTermLoanV3(loanAddr).getCollateralToken();
        SafeERC20.safeApprove(IERC20(collateralTokenAddr), loanAddr, depositAmount);

        IOpenTermLoanV3(loanAddr).returnCollateral(depositAmount);

        SafeERC20.safeApprove(IERC20(collateralTokenAddr), loanAddr, 0);
    }

    /**
     * @notice Calls the loan specified.
     * @param loanAddr The address of the loan.
     * @param callbackPeriodInHours The callback period, measured in hours.
     * @param gracePeriodInHours The grace period, measured in hours.
     */
    function callLoan(
        address loanAddr, 
        uint256 callbackPeriodInHours, 
        uint256 gracePeriodInHours
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).callLoan(callbackPeriodInHours, gracePeriodInHours);
    }

    /**
     * @notice Liquidates the loan specified.
     * @param loanAddr The address of the loan.
     */
    function liquidate(address loanAddr) external onlyIfInitialized ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).liquidate();
    }

    /**
     * @notice The account authorized to manage loans.
     * @return address The address of the loans operator.
     */
    function getLoansOperator() external view onlyIfInitialized returns (address) {
        return _loansOperator;
    }

    // ---------------------------------------------------------------
    // Virtuals
    // ---------------------------------------------------------------
    function fundLoan(address loanAddr) external virtual;
    function _ensureValidLoan(address loanAddr) internal view virtual;
}

/**
 * @title Represents an ERC-4626 lender pool capable of processing hooks on-chain.
 * @dev This contract overrides ERC4626.totalAssets() in order to reflect the exposure to loans.
 */
abstract contract HookableLender is ILenderHookV2, AbstractLender {
    struct LoanDeploymentRecord {
        uint256 effectiveLoanAmount;
        uint256 activeDelta;
        bool isWhitelisted;
    }

    // ---------------------------------------------------------------
    // Storage layout
    // ---------------------------------------------------------------
    uint256 internal _globalLoansAmount;

    mapping (address => LoanDeploymentRecord) internal _deployedLoans;

    // Space reserved for future upgrades
    uint256[3] private __gap;

    // ---------------------------------------------------------------
    // Modifiers
    // ---------------------------------------------------------------
    modifier onlyKnownLoanContract() {
        require(_deployedLoans[msg.sender].isWhitelisted, "Unknown loan");
        _;
    }

    // ---------------------------------------------------------------
    // Hooks implementation
    // ---------------------------------------------------------------
    function notifyLoanMatured() external override onlyIfInitialized nonReentrant ifConfigured onlyKnownLoanContract {
        if (_deployedLoans[msg.sender].activeDelta > 0) _globalLoansAmount -= _deployedLoans[msg.sender].activeDelta;
        _deployedLoans[msg.sender].activeDelta = 0;
    }

    function notifyLoanClosed() external override onlyIfInitialized nonReentrant ifConfigured onlyKnownLoanContract {
        if (_deployedLoans[msg.sender].activeDelta > 0) _globalLoansAmount -= _deployedLoans[msg.sender].activeDelta;
        _deployedLoans[msg.sender].activeDelta = 0;
    }

    function notifyPrincipalRepayment(
        uint256 effectiveLoanAmount, 
        uint256 principalRepaid
    ) external override onlyIfInitialized nonReentrant ifConfigured onlyKnownLoanContract {
        uint256 newDelta = (principalRepaid < effectiveLoanAmount) ? effectiveLoanAmount - principalRepaid : 0;

        if (_deployedLoans[msg.sender].activeDelta > 0) _globalLoansAmount -= _deployedLoans[msg.sender].activeDelta;
        _deployedLoans[msg.sender].activeDelta = newDelta;
        if (newDelta > 0) _globalLoansAmount += newDelta;
    }

    function _ensureValidLoan(address loanAddr) internal view override {
        require(_deployedLoans[loanAddr].isWhitelisted, "Invalid loan contract");
    }

    function getGlobalLoansAmount() external virtual onlyIfInitialized returns (uint256) {
        return _globalLoansAmount;
    }

    // ---------------------------------------------------------------
    // ERC-4626 overrides
    // ---------------------------------------------------------------
    function _getTotalAssets() internal view virtual override returns (uint256) {
        // [Liquidity] + [the delta of all ACTIVE loans managed by this pool]
        return _globalLoansAmount + _underlyingAsset.balanceOf(address(this));
    }
}

/**
 * @title Represents a base lending pool.
 * @dev The pool is capable of deploying and funding loans on their own. It is also capable of receiving hooks on-chain.
 */
abstract contract BaseLendingPool is HookableLender {
    address internal _loansDeployerAddress;

    // Space reserved for future upgrades
    uint256[10] private __gap;

    /**
     * @notice Deploys a new loan on behalf of this pool.
     * @dev The pool acts as a lender. Throws if the caller is not an authorized sender, or if the pool was not configured.
     * @param fundingPeriodInDays The funding period of the loan, expressed in days.
     * @param newPaymentIntervalInSeconds The funding period of the loan, expressed in days.
     * @param loanAmountInPrincipalTokens The loan amount, expressed in principal currency (say USDC).
     * @param originationFeePercent2Decimals The origination fee of the loan. It is a percentage with 2 decimal places (1% = 100).
     * @param newAprWithTwoDecimals The APR of the loan. It is a percentage with 2 decimal places.
     * @param initialCollateralRatioWith2Decimals The initial collateral ratio of the loan. Zero if the loan is not secured. Greater than zero otherwise.
     * @param borrowerAddr The address of the borrower.
     * @param newCollateralToken The collateral token applicable to the loan, if any. Unsecured loans have no collateral (zero address)
     * @param newPrincipalToken The principal token of the loan.
     * @param feesManagerAddr The address authorized to define the fees collector and fees structure.
     * @param allowSeizeCollateral Indicates if the lender is allowed to seize the collateral deposited by the borrower.
     * @return Returns the address the loan deployed by the pool.
     */
    function deployNewLoan(
        uint256 fundingPeriodInDays,
        uint256 newPaymentIntervalInSeconds,
        uint256 loanAmountInPrincipalTokens, 
        uint256 originationFeePercent2Decimals,
        uint256 newAprWithTwoDecimals,
        uint256 initialCollateralRatioWith2Decimals,
        address borrowerAddr,
        address newCollateralToken,
        address newPrincipalToken,
        address feesManagerAddr,
        bool allowSeizeCollateral
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator returns (address) {
        address loanAddr = ILoansDeployer(_loansDeployerAddress).deployLoan(
            fundingPeriodInDays, 
            newPaymentIntervalInSeconds, 
            loanAmountInPrincipalTokens, 
            originationFeePercent2Decimals, 
            newAprWithTwoDecimals, 
            initialCollateralRatioWith2Decimals, 
            address(this), 
            borrowerAddr, 
            newCollateralToken, 
            newPrincipalToken, 
            feesManagerAddr, 
            allowSeizeCollateral
        );

        uint256 effectiveLoanAmount = IOpenTermLoanV3(loanAddr).getEffectiveLoanAmount();

        // This should never happen.
        require(!_deployedLoans[loanAddr].isWhitelisted, "Invalid deployment address");

        _deployedLoans[loanAddr] = LoanDeploymentRecord({
            effectiveLoanAmount: effectiveLoanAmount,
            activeDelta: 0,
            isWhitelisted: true
        });

        return loanAddr;
    }

    /**
     * @notice Funds the loan deployed at the address specified.
     * @dev Throws if the loan was not deployed by this pool.
     * @param loanAddr The address of the loan.
     */
    function fundLoan(address loanAddr) external override onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        // Trusted queries
        _ensureValidLoan(loanAddr);
        uint256 effectiveLoanAmount = _deployedLoans[loanAddr].effectiveLoanAmount;

        // Trusted changes
        _deployedLoans[loanAddr].activeDelta = effectiveLoanAmount; // The principal repaid at this point in time is zero
        _globalLoansAmount += effectiveLoanAmount; // which is "_deployedLoans[loanAddr].activeDelta"

        // Untrusted changes
        SafeERC20.safeApprove(_underlyingAsset, loanAddr, effectiveLoanAmount);
        IOpenTermLoanV3(loanAddr).fundLoan();
        SafeERC20.safeApprove(_underlyingAsset, loanAddr, uint256(0));

        // Late checks
        require(IOpenTermLoanV3(loanAddr).loanState() == ACTIVE, "Funding check failed");
        require(_underlyingAsset.allowance(address(this), loanAddr) == uint256(0), "Allowance check failed");
    }

    function setLoansDeployerAddress(address newLoansDeployerAddress) external onlyIfInitialized nonReentrant onlyOwner {
        _loansDeployerAddress = newLoansDeployerAddress;
    }

    function setLoansOperator(address newLoansOperator) external onlyIfInitialized nonReentrant onlyOwner {
        require(newLoansOperator != _owner, "Owner cannot be operator");
        _loansOperator = newLoansOperator;
    }

    function getLoansDeployerAddress() external view onlyIfInitialized returns (address) {
        return _loansDeployerAddress;
    }

    function getProcessingHour() external view onlyIfInitialized returns (uint8) {
        return _liquidationHour;
    }

    function getLagDuration() external view onlyIfInitialized returns (uint256) {
        return _lagDuration;
    }

    // --------------------------------------------------------------------------
    // Ownership override
    // --------------------------------------------------------------------------
    function _transferOwnership(address newOwner) internal virtual override {
        require(newOwner != address(0) && newOwner != address(this), "Invalid owner");
        require(newOwner != _owner, "Owner already set");
        require(newOwner != _loansOperator, "Owner cannot be operator");
        require(newOwner != _loansDeployerAddress, "Owner cannot be deployer");

        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * ////IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external payable ifAdmin returns (address admin_) {
        _requireZeroValue();
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external payable ifAdmin returns (address implementation_) {
        _requireZeroValue();
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external payable virtual ifAdmin {
        _requireZeroValue();
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external payable ifAdmin {
        _requireZeroValue();
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }

    /**
     * @dev To keep this contract fully transparent, all `ifAdmin` functions must be payable. This helper is here to
     * emulate some proxy functions being non-payable while still allowing value to pass through.
     */
    function _requireZeroValue() private {
        require(msg.value == 0);
    }
}

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

/**
 * @title Implements a basic price oracle.
 * @dev All prices are expressed in USD, with 6 decimal positions.
 */
contract PriceOracle is IBasicPriceOracle, BaseReentrancyGuard, BaseOwnable {
    // The price of each token, expressed in USD
    mapping (address => uint256) internal _tokenPrice;

    /**
     * @notice Constructor.
     * @param ownerAddr The address of the owner
     */
    constructor (address ownerAddr) {
        _owner = ownerAddr;
    }

    /**
     * @notice Updates the price of the token specified.
     * @dev Throws if the sender is not the owner of this contract.
     * @param tokenAddr The address of the token
     * @param newTokenPrice The new price of the token, expressed in USD with 6 decimal positions
     */
    function updateTokenPrice (address tokenAddr, uint256 newTokenPrice) external override onlyOwner {
        require(tokenAddr != address(0), "Token address required");
        require(newTokenPrice > 0, "Token price required");
        
        _tokenPrice[tokenAddr] = newTokenPrice;
    }

    /**
     * @notice Updates the price of multiple tokens.
     * @dev Throws if the sender is not the owner of this contract.
     * @param tokens The address of each token
     * @param prices The new price of each token, expressed in USD with 6 decimal positions
     */
    function bulkUpdate (address[] memory tokens, uint256[] memory prices) external override onlyOwner {
        require(tokens.length > 0 && tokens.length <= 30, "Too many tokens");
        require(tokens.length == prices.length, "Invalid array length");

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenAddr = tokens[i];
            uint256 newTokenPrice = prices[i];
            require(tokenAddr != address(0), "Token address required");
            require(newTokenPrice > 0, "Token price required");        
            _tokenPrice[tokenAddr] = newTokenPrice;
        }
    }

    /**
     * @notice Gets the price of the token specified.
     * @param tokenAddr The address of the token
     * @return Returns the token price
     */
    function getTokenPrice (address tokenAddr) external view override returns (uint256) {
        return _tokenPrice[tokenAddr];
    }
}

/**
 * @title This contract is responsible for managing context-based fees in a generic manner.
 */
contract CategoryFees is ICategoryFees, BaseReentrancyGuard, BaseOwnable {
    /// @notice The divisor for fees. Represents a percentage with 6 decimals places (2 + 6 decimals = 1e8)
    uint256 public constant FEES_DIVISOR = 1e8;

    // This is the mapping for fees, expressed as: Category > Specific Address > Fee
    mapping (bytes32 => mapping (address => uint256)) internal _categoryFees;

    /**
     * @notice Constructor.
     * @param ownerAddr The address of the owner
     */
    constructor (address ownerAddr) {
        _owner = ownerAddr;
    }

    /**
     * @notice Transfers ownership of the contract to a new account.
     */
    function transferOwnership(address newOwner) external nonReentrant onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @notice Sets the applicable to a given category. Optionally, you can specify a specific address for selective fees.
     * @param feePercent The fee, expressed as a percentage with 6 decimals places. It can be zero.
     * @param categoryId The ID of the category. It could be a hash, or a number, or a limited string. Required.
     * @param specificAddr The specific address within the category specified, if any. It can be the zero-address, meaning the fee applies to the whole category.
     */
    function setContextFeeRate(uint256 feePercent, bytes32 categoryId, address specificAddr) external override nonReentrant onlyOwner {
        require(categoryId != bytes32(0), "Category required");
        require(feePercent <= 99_000000, "Fee too high");

        _categoryFees[categoryId][specificAddr] = feePercent;
    }

    /**
     * @notice Gets the fee applicable to the context specified.
     * @param categoryId The ID of the category. It could be a hash, or a number, or a limited string.
     * @param specificAddr The specific address within the category specified, if any. It can be the zero-address, meaning the fee applies to the whole category.
     * @return Returns the rate for the category and address specified.
     */
    function getContextFeeRate(bytes32 categoryId, address specificAddr) external override view returns (uint256) {
        return _categoryFees[categoryId][specificAddr];
    }

    /**
     * @notice Gets the applicable fee amount for the context specified.
     * @param amount The payment amount.
     * @param categoryId The ID of the category. It could be a hash, or a number, or a limited string.
     * @param specificAddr The specific address within the category specified, if any. It can be the zero-address, meaning the fee applies to the whole category.
     * @return feePercent Returns the rate for the category and address specified.
     * @return feeAmount Returns the respective fee amount, for the category and address specified.
     */
    function getContextFeeAmount(uint256 amount, bytes32 categoryId, address specificAddr) external override view returns (uint256 feePercent, uint256 feeAmount) {
        feePercent = _categoryFees[categoryId][specificAddr];
        if ((specificAddr != address(0)) && (feePercent == 0)) feePercent = _categoryFees[categoryId][address(0)];
        
        feeAmount = (feePercent == 0) ? 0 : (feePercent * amount) / FEES_DIVISOR;
    }

    function owner() external view returns (address) {
        return _owner;
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

/**
 * @title Represents a lending pool in which all withdrawals are time-locked. The lending pool is fully compliant with the ERC-4626 standard.
 */
contract LendingPool is BaseLendingPool {
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Proxy initialization function.
     * @param newOwner The owner of the lending pool.
     * @param erc20Decimals The number of decimals of the LP token issued by this pool, per ERC20.
     * @param erc20Symbol The token symbol of this pool, per ERC20.
     * @param erc20Name The token name of this pool, per ERC20.
     */
    function initialize(
        address newOwner,
        uint8 erc20Decimals,
        string memory erc20Symbol,
        string memory erc20Name
    ) external initializer {
        _reentrancyStatus = _REENTRANCY_NOT_ENTERED;

        // ERC-20 settings
        _decimals = erc20Decimals;
        _symbol = erc20Symbol;
        _name = erc20Name;

        // Pause deposits and withdrawals until the pool gets configured by the authorized party.
        _depositsPaused = true;
        _withdrawalsPaused = true;

        _owner = newOwner;
    }

    /**
     * @notice Configures the lending pool.
     * @dev Throws if the caller is not the owner. Deposits and withdrawals are paused until the pool is configured.
     * @param newMaxDepositAmount The maximum deposit amount of assets (say USDC) investors are allowed to deposit in the pool.
     * @param newMaxWithdrawalAmount The maximum withdrawal amount of the pool, expressed in underlying assets (for example: USDC)
     * @param newMaxTokenSupply The maximum supply of LP tokens (liquidity pool tokens)
     * @param newUnderlyingAsset The underlying asset of the liquidity pool (for example: USDC).
     * @param newLoansOperator The address responsible for managing the loans of the pool.
     * @param newLoansDeployerAddress The address of the smart contract you will use for deploying loans on behalf of this pool.
     * @param newProcessingHour The hour (UTC) at which all withdrawal requests will be processed. The value ranges from [0..23]
     */
    function configurePool(
        uint256 newMaxDepositAmount, 
        uint256 newMaxWithdrawalAmount, 
        uint256 newMaxTokenSupply,
        address newUnderlyingAsset,
        address newLoansOperator,
        address newLoansDeployerAddress,
        uint8 newProcessingHour
    ) external onlyIfInitialized nonReentrant ifNotConfigured onlyOwner {
        require(newProcessingHour < 24, "Invalid processing hour"); // Min: 0, Max: 23  (eg: 13 = 1PM)

        _underlyingAsset = IERC20(newUnderlyingAsset);
        _updateIssuanceLimits(newMaxDepositAmount, newMaxWithdrawalAmount, newMaxTokenSupply);

        // Loan management actors
        _loansOperator = newLoansOperator;
        _loansDeployerAddress = newLoansDeployerAddress;

        // Timelock settings
        _lagDuration = 24 hours;
        _liquidationHour = newProcessingHour;

        // Resume deposits and withdrawals
        _depositsPaused = false;
        _withdrawalsPaused = false;
    }

    /**
     * @notice Transfers ownership of the contract to a new account.
     * @dev Throws if the caller is not the current owner. Additional constraints apply.
     * @param newOwner The new owner of this contract.
     */
    function transferOwnership(address newOwner) external onlyIfInitialized nonReentrant onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @notice Updates the processing hour of all withdrawal requests.
     * @dev Throws if the caller is not the owner of the pool. Throws if the pool was not configured.
     * @param newProcessingHour The new hour, which ranges between 0 and 23 (where 23 = 11PM)
     */
    function updateProcessingHour(uint8 newProcessingHour) external onlyIfInitialized nonReentrant ifConfigured onlyOwner {
        require(newProcessingHour < 24, "Invalid processing hour"); // Min: 0, Max: 23  (eg: 13 = 1PM, 14 = 2PM, 11 = 11AM)
        _liquidationHour = newProcessingHour;
    }

    /**
     * @notice Updates the issuance and redemption settings of the pool.
     * @dev Throws if the caller is not the owner of the pool. Throws if the pool was not configured.
     * @param newMaxDepositAmount The maximum deposit amount of assets (say USDC) investors are allowed to deposit in the pool.
     * @param newMaxWithdrawalAmount The maximum withdrawal amount of the pool, expressed in underlying assets (for example: USDC)
     * @param newMaxTokenSupply The maximum supply of LP tokens (liquidity pool tokens)
     */
    function updateIssuanceLimits(
        uint256 newMaxDepositAmount, 
        uint256 newMaxWithdrawalAmount, 
        uint256 newMaxTokenSupply
    ) external onlyIfInitialized nonReentrant ifConfigured onlyOwner {
        _updateIssuanceLimits(newMaxDepositAmount, newMaxWithdrawalAmount, newMaxTokenSupply);
    }

    /**
     * @notice Pauses deposits.
     * @dev The pool will stop accepting deposits if this tx goes through.
     */
    function pauseDeposits() external virtual onlyIfInitialized nonReentrant ifConfigured onlyOwner ifDepositsNotPaused {
        _pauseDeposits();
    }

    /**
     * @notice Resumes deposits.
     * @dev The pool will start accepting deposits again if this tx goes through.
     */
    function resumeDeposits() external virtual onlyIfInitialized nonReentrant ifConfigured onlyOwner {
        _resumeDeposits();
    }

    /**
     * @notice Pauses withdrawals.
     * @dev The pool will stop accepting withdrawal requests if this tx goes through.
     */
    function pauseWithdrawals() external virtual onlyIfInitialized nonReentrant ifConfigured onlyOwner ifWithdrawalsNotPaused {
        _pauseWithdrawals();
    }

    /**
     * @notice Resumes withdrawals.
     * @dev The pool will start accepting withdrawal requests again if this tx goes through.
     */
    function resumeWithdrawals() external virtual onlyIfInitialized nonReentrant ifConfigured onlyOwner {
        _resumeWithdrawals();
    }
}

/**
 * @title Represents a factory of transparent proxies.
 */
contract ProxyFactory is Ownable {
    /**
     * @notice This event is triggered when a new proxy is deployed.
     * @param adminAddress The address of the proxy admin.
     * @param proxyAddress The address of the transparent proxy.
     */
    event OnProxyDeployed (address adminAddress, address proxyAddress);

    /**
     * @notice Deploys a transparent proxy.
     * @dev This function can be called by the owner only.
     * @param adminSalt The salt of the Proxy Admin
     * @param proxySalt The salt of the Transparent Proxy
     * @param implementationAddr The implementation address
     * @param proxyOwnerAddr The owner of the Proxy Admin
     * @param initData The initialization data
     */
    function deploy (
        bytes32 adminSalt, 
        bytes32 proxySalt, 
        address implementationAddr, 
        address proxyOwnerAddr, 
        bytes memory initData
    ) external onlyOwner {
        // Basic check of input parameters
        require(adminSalt != bytes32(0), "Admin salt required");
        require(proxySalt != bytes32(0), "Proxy salt required");
        require(implementationAddr != address(0) && implementationAddr != address(this), "Invalid logic address");

        // Get the predictable address of both the proxy and the proxy admin
        (address adminContractAddr, address proxyContractAddr) = getDeploymentAddress(adminSalt, proxySalt, implementationAddr, initData);

        // Make sure the contract addresses above were not taken
        require(adminContractAddr.code.length == 0, "Admin address already taken");
        require(proxyContractAddr.code.length == 0, "Proxy address already taken");

        // Deploy the proxy admin
        ProxyAdmin adminInstance = (new ProxyAdmin){salt: adminSalt}();
        require(address(adminInstance) == adminContractAddr, "Admin deploy failed");

        // Deploy the transparent proxy
        TransparentUpgradeableProxy proxy = (new TransparentUpgradeableProxy){salt: proxySalt}(implementationAddr, address(adminInstance), initData);
        require(address(proxy) == proxyContractAddr, "Proxy deploy failed");

        // Transfer ownership of the Proxy Admin
        adminInstance.transferOwnership(proxyOwnerAddr);

        emit OnProxyDeployed(address(adminInstance), address(proxy));
    }

    /**
     * @notice Calculates the deployment address of the proxy specified.
     * @param adminSalt The salt of the Proxy Admin
     * @param proxySalt The salt of the Transparent Proxy
     * @param implementationAddr The implementation address
     * @param initData The initialization data
     * @return adminContractAddr The address of the proxy admin
     * @return proxyContractAddr The address of the transparent proxy
     */
    function getDeploymentAddress (bytes32 adminSalt, bytes32 proxySalt, address implementationAddr, bytes memory initData) public view returns (address adminContractAddr, address proxyContractAddr) {
        adminContractAddr = address(uint160(uint256(
                                keccak256(abi.encodePacked(bytes1(0xff), address(this), adminSalt, keccak256(type(ProxyAdmin).creationCode)))
                            )));

        proxyContractAddr = address(uint160(uint256(
                                keccak256(abi.encodePacked(bytes1(0xff), address(this), proxySalt, keccak256(
                                    abi.encodePacked(type(TransparentUpgradeableProxy).creationCode, abi.encode(implementationAddr, adminContractAddr, initData))
                                )))
                            )));
    }
}