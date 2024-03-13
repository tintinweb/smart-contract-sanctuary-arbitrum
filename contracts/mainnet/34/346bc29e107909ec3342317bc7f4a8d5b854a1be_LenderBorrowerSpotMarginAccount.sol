// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    LenderBorrowerSubAccount,
    IERC20,
    SafeERC20,
    IOpenTermLoanV2
} from "../base/LenderBorrowerSubAccount.sol";

contract LenderBorrowerSpotMarginAccount is LenderBorrowerSubAccount {
    using SafeERC20 for IERC20;
    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Disable initializers.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the contract. Only called once.
     * @param _borrowerAddr borrower.
     * @param _lenderAddr lender.
     * @param _operatorAddr operator.
     * @param _executorAddr executor.
     * @param _feeCollectorAddr fee collector.
     * @param _swapContractManagerAddr swap contract mananger.
     * @param _counterPartyRegistryAddr counter party registry.
     * @param _tokenRegistryAddr token registry.
     * @param _oracleRegistryAddr oracle registry.
     * @param _loanManagerAddr sub account loan manager.
     */
    function initialize(
        address _borrowerAddr,
        address _lenderAddr,
        address _operatorAddr,
        address _executorAddr,
        address _feeCollectorAddr,
        address _swapContractManagerAddr,
        address _counterPartyRegistryAddr,
        address _tokenRegistryAddr,
        address _oracleRegistryAddr,
        address _loanManagerAddr
    ) external initializer {
        _initSubAccount(
            _borrowerAddr,
            _lenderAddr,
            _operatorAddr,
            _executorAddr,
            _feeCollectorAddr,
            _swapContractManagerAddr,
            _counterPartyRegistryAddr,
            _tokenRegistryAddr,
            _oracleRegistryAddr,
            _loanManagerAddr
        );
    }

    /*///////////////////////////////////////////////////////////////
                        Modifiers
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Safety check for all possible versions of this contract.
     */
    modifier onlyIfInitialized() {
        require(_getInitializedVersion() != type(uint8).max, "not initialized");
        _;
    }

    /**
     * @notice Only called by borrower
     */
    modifier onlyBorrower() {
        require(borrower == msg.sender, "not borrower");
        _;
    }

    /**
     * @notice Only called by lender
     */
    modifier onlyLender() {
        require(lender == msg.sender, "not lender");
        _;
    }

    /**
     * @notice Only called by operator
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "not operator");
        _;
    }

    /**
     * @notice Only called by executor
     */
    modifier onlyExecutor() {
        require(executor == msg.sender, "not executor");
        _;
    }

    /**
     * @notice Only called by executor or operator
     */
    modifier onlyExecutorOrOperator() {
        require(executor == msg.sender || operator == msg.sender, "not executor or operator");
        _;
    }

    /**
     * @notice Only called by borrower or executor
     */
    modifier onlyBorrowerOrExecutor() {
        require(msg.sender == borrower || msg.sender == executor, "not borrower or executor");
        _;
    }

    /**
     * @notice Only called by borrower or executor
     */
    modifier onlyLenderOrExecutor() {
        require(msg.sender == lender || msg.sender == executor, "not lender or executor");
        _;
    }

    /**
     * @notice Only called by loan manager or executor
     */
    modifier onlyLoanManagerOrExecutor() {
        require(
            msg.sender == loanManager || msg.sender == executor,
            "not loan manager or executor"
        );
        _;
    }

    /**
     * @notice Only called by borrower or executor or operator
     */
    modifier onlyBorrowerOrExecutorOrOperator() {
        require(
            msg.sender == borrower || msg.sender == executor || msg.sender == operator,
            "not borrower, executor, or operator"
        );
        _;
    }

    /**
     * @notice Only called by swap contract manager
     */
    modifier onlySwapContractManager() {
        require(msg.sender == swapContractManager, "only swap contract manager");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Setters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set loan manager
     */
    function addLoanContract(address loan) external onlyIfInitialized onlyLoanManagerOrExecutor {
        _addLoanContract(loan);
    }

    /**
     * @notice Remove a loan contract address
     * @param loan The address of the loan to add.
     */
    function removeLoanContract(address loan) external onlyIfInitialized onlyExecutor {
        _removeLoanContract(loan);
    }

    /**
     * @notice Set the active strategy contract address
     * @param strategyContractAddress The address of the strategy contract.
     */
    function setActiveStrategy(address strategyContractAddress) external onlyIfInitialized onlyExecutor {
        activeStrategy = strategyContractAddress;

        emit SetActiveStrategy(activeStrategy);
    }

    /**
     * @notice Set loan manager
     */
    function setFeesOracle(address feeOracleAddr) external onlyIfInitialized onlyExecutor {
        feesOracle = feeOracleAddr;
    }

    /**
     * @notice Enable withdrawals from the subaccount.
     */
    function setWithdrawals(bool status) external onlyIfInitialized onlyExecutor {
        require(status != withdrawalEnabled, "already set");
        withdrawalEnabled = status;
    }

    /*///////////////////////////////////////////////////////////////
                            Strategy Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit only to active strategy
     * @param token token to deposit.
     * @param amount amount of tokens to deposit.
     */
    function depositToStrategy(IERC20 token, uint256 amount)
        external
        onlyIfInitialized
        nonReentrant
        onlyBorrowerOrExecutor
    {
        _depositToStrategy(token, amount);
    }

    /**
     * @notice Withdraw only from active strategy
     * @param token token to deposit.
     * @param amount amount of tokens to deposit.
     */
    function withdrawOnlyFromStrategy(IERC20 token, uint256 amount)
        external
        onlyIfInitialized
        nonReentrant
        onlyBorrowerOrExecutor
    {
        _withdrawFromStrategy(token, amount);
    }

    /*///////////////////////////////////////////////////////////////
                            Base Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit into the sub account.
     * @param token token to deposit.
     * @param amount amount of tokens to deposit.
     */
    function deposit(IERC20 token, uint256 amount) external onlyIfInitialized nonReentrant onlyBorrower {
        subAccountState = FUNDED;

        uint256 depositAmount = _calculateAmount(address(token), amount);

        _postAmount(address(token), amount, true);

        totalDeposits += depositAmount;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(address(token), amount, totalDeposits, subAccountState);
    }

    /**
     * @notice Withdraw from the sub account.
     * @param token token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function withdraw(IERC20 token, uint256 amount) external onlyIfInitialized nonReentrant onlyBorrower {

        (uint256 totalPrincipalDebt, uint256 totalInterestOwed) = getTotalDebt();

        if (!withdrawalEnabled) {
            require(totalPrincipalDebt + totalInterestOwed == 0, "outstanding debt");
        }

        uint256 withdrawalAmount = _calculateAmount(address(token), amount);

        _postAmount(address(token), amount, false);

        totalWithdrawals += withdrawalAmount;

        token.safeTransfer(msg.sender, amount);

        emit Withdraw(address(token), amount, totalWithdrawals);
    }

    /**
     * @notice Withdraw from the sub account to the lender address.
     * @param token token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function withdrawToLender(IERC20 token, uint256 amount) external onlyIfInitialized nonReentrant onlyExecutor {

        token.safeTransfer(lender, amount);

        emit WithdrawToLender(address(token), amount);
    }

    /**
     * @notice Swap rewards via the paraswap router.
     * @param srcToken The token to swap.
     * @param destToken The token to receive.
     * @param srcAmount The amount of tokens to swap.
     * @param minDestAmountOut The minimum amount of tokens out we expect to receive.
     * @param callData The callData to pass to the paraswap router. Generated offchain.
     */
    function swap(IERC20 srcToken, IERC20 destToken, uint256 srcAmount, uint256 minDestAmountOut, bytes memory callData)
        external
        payable
        onlyIfInitialized
        onlyBorrowerOrExecutorOrOperator
    {
        _swap(srcToken, destToken, srcAmount, minDestAmountOut, callData);
    }

    /*///////////////////////////////////////////////////////////////
                            Borrower Loan Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Loans V2 Hook.
     */
    function notifyLoanClosed() external {}

    /**
     * @notice Loans V2 Hook.
     */
    function notifyLoanMatured() external {}

    /**
     * @notice Change Loan APR.
     * @param loan The address of the loan.
     * @param newApr The new APR.
     */
    function changeLoanApr(address loan, uint256 newApr) external onlyLenderOrExecutor {
        IOpenTermLoanV2(loan).proposeNewApr(newApr);
    }

    /**
     * @notice Change late fees.
     */
    function changeLateFees(address loan, uint256 interestFee, uint256 principalFees) external onlyLenderOrExecutor {
        IOpenTermLoanV2(loan).changeLateFees(interestFee, principalFees);
    }

    /**
     * @notice Accept Loan APR.
     * @param loan The address of the loan.
     */
    function acceptLoanApr(address loan) external onlyBorrowerOrExecutor {
        IOpenTermLoanV2(loan).acceptApr();
    }

    /**
     * @notice Accept the loan contract.
     * @param loan The address of the loan.
     */
    function acceptLoan(address loan) external onlyIfInitialized onlyBorrowerOrExecutor {
        _acceptLoan(loan);
    }

    /**
     * @notice Repay the principal amount for the loan.
     * @param loan The address of the loan.
     * @param amount Amount of principal to pay back.
     */
    function repayLoanPrincipal(address loan, uint256 amount)
        external
        onlyIfInitialized
        onlyBorrowerOrExecutorOrOperator
    {
        _repayLoanPrincipal(loan, amount);
    }

    /**
     * @notice Repay accrued interest on the loan.
     * @param loan The address of the loan.
     */
    function repayLoanInterest(address loan) external onlyIfInitialized onlyBorrowerOrExecutorOrOperator {
        _repayLoanInterest(loan);
    }

    /*///////////////////////////////////////////////////////////////
                            Lender Loan Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Fund a loan.
     * @param loan The address of the loan.
     */
    function fundLoan(address loan) external onlyIfInitialized onlyLenderOrExecutor {
        _fundLoan(loan);
    }

    /**
     * @notice Set subAccountState to Margin Call as a warning level.
     */
    function marginCall() external onlyIfInitialized nonReentrant onlyOperator {

        subAccountState = MARGIN_CALL;

        emit SubAccountStateChange(subAccountState);
    }

    /*///////////////////////////////////////////////////////////////
                            OTC Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfer a specified amount of margin between sub accounts.
     * @param token The token to transfer between accounts.
     * @param toSubAccount The account to transfer tokens to.
     * @param marginAmount The amount of margin to transfer between accounts.
     */
    function transferMargin(IERC20 token, address toSubAccount, uint256 marginAmount)
        external
        onlyIfInitialized
        onlySwapContract
    {
        _transferMargin(token, toSubAccount, marginAmount);
    }

    /*///////////////////////////////////////////////////////////////
                        ETH Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Depost ETH into the contract
     */
    function depositETH() external payable onlyIfInitialized nonReentrant onlyBorrower {
        uint256 depositAmount = _calculateAmount(NATIVE_ASSET, msg.value);

        totalDeposits += depositAmount;

        emit DepositETH(msg.value, totalDeposits);
    }

    /**
     * @notice Withdraw eth locked in contract back to owner
     * @param amount amount of eth to send.
     */
    function withdrawETH(uint256 amount) external onlyIfInitialized nonReentrant onlyBorrower {
        uint256 withdrawalAmount = _calculateAmount(NATIVE_ASSET, amount);

        totalWithdrawals += withdrawalAmount;

        (bool success,) = msg.sender.call{value: amount}(new bytes(0));
        require(success, "withdraw failed");

        emit WithdrawETH(amount, totalWithdrawals);
    }

    /**
     * @notice Withdraw from the sub account to the lender address.
     * @param amount amount of ETH to withdraw.
     */
    function withdrawETHToLender(uint256 amount) external onlyIfInitialized nonReentrant onlyExecutor {

        (bool success,) = payable(lender).call{value: amount}(new bytes(0));
        require(success, "withdraw failed");

        emit WithdrawETHToLender(amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IFractBaseStrategy} from "../../interfaces/fractal/IFractBaseStrategy.sol";
import {IOpenTermLoan} from "../../interfaces/fractal/IOpenTermLoan.sol";
import {IOpenTermLoanV2} from "../../interfaces/fractal/IOpenTermLoanV2.sol";
import {ICounterPartyRegistry} from "../../interfaces/fractal/ICounterPartyRegistry.sol";
import {ITokenRegistry} from "../../interfaces/fractal/ITokenRegistry.sol";
import {IOracleRegistry} from "../../interfaces/fractal/IOracleRegistry.sol";
import {IParaSwapAugustus} from "../../interfaces/paraswap/IParaSwapAugustus.sol";
import {ITwapOrder} from "../../interfaces/fractal/ITwapOrder.sol";
import {SafeERC20} from "../../../lib/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../../../lib/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILenderHook} from "../../interfaces/fractal/ILenderHook.sol";
import {Initializable} from "../../../lib/openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../../../lib/openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../../lib/openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../lib/fractal/oracles/OracleMath.sol";
import "../../lib/fractal/subaccounts/SubAccount.sol";
import "../../fees/FeesAwareMini.sol";

abstract contract LenderBorrowerSubAccount is Initializable, ReentrancyGuard, FeesAwareMini, ILenderHook {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/

    uint8 constant ACTIVE = 0;
    uint8 constant FUNDED = 1;
    uint8 constant MARGIN_CALL = 3;

    address constant PARASWAP = address(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57);

    /*///////////////////////////////////////////////////////////////
                        State Variables
    //////////////////////////////////////////////////////////////*/

    /// Subaccount State
    uint8 internal subAccountState;
    /// Withdrawal Status
    bool internal withdrawalEnabled;
    /// Borrower address.
    address public borrower;
    /// @dev Lender address, can be same as borrower to grant both sets of permissions.
    address public lender;
    /// Operator address.
    address public operator;
    /// Executor address.
    address public executor;
    /// Fee collector address.
    address public feeCollector;
    /// Swap contract manager address.
    address public swapContractManager;
    /// Counter Party Registry address.
    address public counterPartyRegistry;
    /// Active strategy address.
    address public activeStrategy;
    /// Token registry address.
    address public tokenRegistry;
    /// Oracle registry address.
    address public oracleRegistry;
    /// Loan manager address.
    address public loanManager;
    /// Fees oracle address.
    address feesOracle;
    /// Loan addresses.
    address[] internal loanAddresses;
    /// Total Deposits in USD.
    uint256 internal totalDeposits;
    /// Total Withdrawals in USD.
    uint256 internal totalWithdrawals;
    /// Posted Margin in native token units.
    mapping(address => SubAccount.Posted) internal postedMargin;
    /// Posted Deposits in native token units.
    mapping(address => SubAccount.PositionParams[]) internal postedDeposits;
    /// Posted Withdrawals in native token units.
    mapping(address => SubAccount.PositionParams[]) internal postedWithdrawals;
    /// Fees collected in native token units.
    mapping(address => SubAccount.PositionParams[]) internal feesCollected;

    /*///////////////////////////////////////////////////////////////
                        Events
    //////////////////////////////////////////////////////////////*/

    event SubAccountStateChange(uint8 newSubAccountState);
    event SetActiveStrategy(address newActiveStrategy);
    event WithdrawalsEnabled(bool status);
    event Deposit(address token, uint256 amount, uint256 totalDeposits, uint8 newSubAccountState);
    event DepositETH(uint256 amount, uint256 totalDeposits);
    event Withdraw(address token, uint256 amount, uint256 totalWithdrawals);
    event WithdrawETH(uint256 amount, uint256 totalWithdrawals);
    event WithdrawToLender(address token, uint256 amount);
    event WithdrawETHToLender(uint256 amount);
    event AddLoan(address loan);
    event RemoveLoan(address loan);
    event TransferMargin(address token, address toSubAccount, address fromSubAccount);
    event Received(address sender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                            Initialize
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the contract. Only called once.
     * @param _borrowerAddr borrower.
     * @param _lenderAddr lender.
     * @param _operatorAddr operator.
     * @param _executorAddr executor.
     * @param _feeCollectorAddr fee collector.
     * @param _swapContractManagerAddr swap contract mananger.
     * @param _counterPartyRegistryAddr counter party registry.
     * @param _tokenRegistryAddr token registry.
     * @param _oracleRegistryAddr oracle registry.
     * @param _loanManagerAddr Loan manager.
     */
    function _initSubAccount(
        address _borrowerAddr,
        address _lenderAddr,
        address _operatorAddr,
        address _executorAddr,
        address _feeCollectorAddr,
        address _swapContractManagerAddr,
        address _counterPartyRegistryAddr,
        address _tokenRegistryAddr,
        address _oracleRegistryAddr,
        address _loanManagerAddr
    ) internal onlyInitializing {
        borrower = _borrowerAddr;
        lender = _lenderAddr;
        operator = _operatorAddr;
        executor = _executorAddr;
        feeCollector = _feeCollectorAddr;
        swapContractManager = _swapContractManagerAddr;
        counterPartyRegistry = _counterPartyRegistryAddr;
        tokenRegistry = _tokenRegistryAddr;
        oracleRegistry = _oracleRegistryAddr;
        loanManager = _loanManagerAddr;
    }

    /*///////////////////////////////////////////////////////////////
                        Modifiers
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Only called by active swap contract
     */
    modifier onlySwapContract() {
        require(ICounterPartyRegistry(counterPartyRegistry).getSwapContract(msg.sender), "only swap contract");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        Receive
    //////////////////////////////////////////////////////////////*/

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /*///////////////////////////////////////////////////////////////
                            Setters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the active loan contract address
     * @param loan The address of the loan to add.
     */
    function _addLoanContract(address loan) internal {
        loanAddresses.push(loan);

        emit AddLoan(loan);
    }

    /**
     * @notice Remove a loan contract address
     */
    function _removeLoanContract(address loan) internal {
        address[] memory loanToRemove = SubAccount.removeLoan(loan, loanAddresses);

        loanAddresses = loanToRemove;

        emit RemoveLoan(loan);
    }

    /*///////////////////////////////////////////////////////////////
                            Strategy Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit only to active strategy.
     */
    function _depositToStrategy(IERC20 token, uint256 amount) internal {
        if (address(token) == NATIVE_ASSET) {
            IFractBaseStrategy(activeStrategy).depositETH{value: amount}();
        } else {
            token.safeApprove(activeStrategy, amount);
            IFractBaseStrategy(activeStrategy).deposit(token, amount);
            token.safeApprove(activeStrategy, 0);
        }
    }

    /**
     * @notice Withdraw only from active strategy.
     */
    function _withdrawFromStrategy(IERC20 token, uint256 amount) internal {
        if (address(token) == NATIVE_ASSET) {
            IFractBaseStrategy(activeStrategy).withdrawETH(amount);
        } else {
            IFractBaseStrategy(activeStrategy).withdraw(token, amount);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Base Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Convert amount to USD via chainlink oracle.
     * @param token token to get price of.
     * @param amount amount of token.
     */
    function _calculateAmount(address token, uint256 amount) internal view returns (uint256) {
        address oracle = IOracleRegistry(oracleRegistry).getSupportedOracle(token);

        uint8 decimals = (token == NATIVE_ASSET) ? 18 : IERC20Metadata(token).decimals();

        return OracleMath.processV1(oracle, 0, decimals, amount);
    }

    /**
     * @notice Post a deposit or withdrawal
     * @param token token to get price of.
     * @param amount amount of token.
     * @param isDeposit is the post for a deposit.
     */
    function _postAmount(address token, uint256 amount, bool isDeposit) internal {
        if (isDeposit) {
            postedDeposits[token].push(_logPosition(token, amount));
        } else {
            postedWithdrawals[token].push(_logPosition(token, amount));
        }
    }

    /**
     * @notice Log a deposit or withdrawal into the SubAccount contract.
     * @param token token to deposit or withdrawal.
     * @param amount amount of tokens to deposit or withdraw.
     */
    function _logPosition(address token, uint256 amount) internal view returns (SubAccount.PositionParams memory positionParams) {
        address oracle = IOracleRegistry(oracleRegistry).getSupportedOracle(token);

        uint8 decimals = (token == NATIVE_ASSET) ? 18 : IERC20Metadata(token).decimals();

        positionParams.amount = amount;
        positionParams.time = block.timestamp;
        positionParams.price = OracleMath.getPriceV1(oracle, decimals);

        return positionParams;
    }

    /**
     * @notice Swap rewards via the paraswap router.
     * @param srcToken The token to swap.
     * @param destToken The token to receive.
     * @param srcAmount The amount of tokens to swap.
     * @param minDestAmountOut The minimum amount of tokens out we expect to receive.
     * @param callData The callData to pass to the paraswap router. Generated offchain.
     */
    function _swap(
        IERC20 srcToken,
        IERC20 destToken,
        uint256 srcAmount,
        uint256 minDestAmountOut,
        bytes memory callData
    ) internal {
        require(ITokenRegistry(tokenRegistry).getSupportedToken(address(srcToken)), "invalid source token");
        require(ITokenRegistry(tokenRegistry).getSupportedToken(address(destToken)), "invalid destination token");
        // require(minDestAmountOut > 0, "balance check");

        address tokenTransferProxy = IParaSwapAugustus(PARASWAP).getTokenTransferProxy();

        uint256 destTokenBalanceBefore;
        if (address(destToken) != NATIVE_ASSET) {
            destTokenBalanceBefore = destToken.balanceOf(address(this));
        } else {
            destTokenBalanceBefore = address(this).balance;
        }

        if (address(srcToken) == NATIVE_ASSET) {
            (bool success,) = PARASWAP.call{value: srcAmount}(callData);
            require(success, "swap failed");
        } else {
            srcToken.safeApprove(tokenTransferProxy, srcAmount);
            (bool success,) = PARASWAP.call(callData);
            require(success, "swap failed");
            srcToken.safeApprove(tokenTransferProxy, 0);
        }

        uint256 destTokenBalanceAfter;
        if (address(destToken) != NATIVE_ASSET) {
            destTokenBalanceAfter = destToken.balanceOf(address(this));
        } else {
            destTokenBalanceAfter = address(this).balance;
        }

        require(destTokenBalanceAfter - destTokenBalanceBefore >= minDestAmountOut, "slippage check");

        // Apply the default fees applicable to Paraswap.
        // Transfer any applicable fees to the fees collector. Leave any remaining funds in this contract.
        _applyFeesOnly(
            feesOracle,
            feeCollector,
            address(destToken),
            destTokenBalanceAfter - destTokenBalanceBefore,
            bytes32(keccak256("SUBACCOUNT.SWAP"))
        );
    }

    /*///////////////////////////////////////////////////////////////
                            Borrower Loan Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Accept the loan contract.
     * @param loan The address of the loan.
     */
    function _acceptLoan(address loan) internal {
        address token = IOpenTermLoan(loan).principalToken();

        IERC20(token).safeApprove(loan, type(uint256).max);

        IOpenTermLoan(loan).borrowerCommitment();
    }

    /**
     * @notice Repay the principal amount for the loan.
     * @param loan The address of the loan.
     * @param amount Amount of principal to pay back.
     */
    function _repayLoanPrincipal(address loan, uint256 amount) internal {
        IOpenTermLoan(loan).repayPrincipal(amount);
    }

    /**
     * @notice Repay accrued interest on the loan.
     * @param loan The address of the loan.
     */
    function _repayLoanInterest(address loan) internal {
        IOpenTermLoan(loan).repayInterests();
    }

    /*///////////////////////////////////////////////////////////////
                            Lender Loan Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Fund the loan contract.
     * @param loan The address of the loan.
     */
    function _fundLoan(address loan) internal {
        address principalToken = IOpenTermLoan(loan).principalToken();

        IERC20(principalToken).safeApprove(loan, type(uint256).max);

        IOpenTermLoan(loan).fundLoan();

        IERC20(principalToken).safeApprove(loan, 0);
    }

    /*///////////////////////////////////////////////////////////////
                            OTC Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfer a specified amount of margin between sub accounts.
     * @param token The token to transfer between accounts.
     * @param toSubAccount The account to transfer tokens to.
     * @param marginAmount The amount of margin to transfer between accounts.
     */
    function _transferMargin(IERC20 token, address toSubAccount, uint256 marginAmount) internal {
        require(ICounterPartyRegistry(counterPartyRegistry).getCounterParty(toSubAccount), "invalid counter party");

        postedMargin[address(token)].onchainPosted += int256(marginAmount);

        token.safeApprove(toSubAccount, marginAmount);

        token.safeTransfer(toSubAccount, marginAmount);

        token.safeApprove(toSubAccount, 0);

        emit TransferMargin(address(token), toSubAccount, address(this));
    }

    /*///////////////////////////////////////////////////////////////
                        ETH Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit ETH only to active strategy
     * @param amount amount of ETH to deposit.
     */
    function _depositETHToStrategy(uint256 amount) internal {
        IFractBaseStrategy(activeStrategy).depositETH{value: amount}();
    }

    /**
     * @notice Withdraw ETH only from active strategy
     * @param amount amount of ETH to withdraw.
     */
    function _withdrawETHOnlyFromStrategy(uint256 amount) internal {
        IFractBaseStrategy(activeStrategy).withdrawETH(amount);
    }

    /*///////////////////////////////////////////////////////////////
                        Getters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get posted margin for a given token.
     */
    function getFeesCollected(address token) external view returns (SubAccount.PositionParams[] memory) {
        return feesCollected[token];
    }

    /**
     * @notice Get posted margin for a given token.
     */
    function getPostedMargin(address token) external view returns (SubAccount.Posted memory) {
        return postedMargin[token];
    }

    /**
     * @notice Get array of token deployments.
     * @param token token address.
     * @dev pass NATIVE_ASSET to return ETH deployments.
     */
    function getTokenDeployedAmounts(address token) external view returns (SubAccount.PositionParams[] memory) {
        return postedDeposits[token];
    }

    /**
     * @notice Get array of token withdrawals.
     * @param token token address.
     * @dev pass NATIVE_ASSET to return ETH withdrawals.
     */
    function getTokenWithdrawalAmounts(address token) external view returns (SubAccount.PositionParams[] memory) {
        return postedWithdrawals[token];
    }

    /**
     * @notice Get all loans for subaccount.
     */
    function getSubAccountState() public view returns (uint8) {
        return subAccountState;
    }

    function getWithdrawalEnabled() public view returns (bool) {
        return withdrawalEnabled;
    }

    /**
     * @notice Get all loans for subaccount.
     */
    function getLoans() public view returns (address[] memory) {
        return loanAddresses;
    }

    /**
     * @notice Get total deposits and withdrawals in usd.
     */
    function getTotalDepositsAndWithdrawals() external view returns (uint256, uint256) {
        return (totalDeposits, totalWithdrawals);
    }

    /**
     * @notice Get total debt across all loans for subaccount.
     */
    function getTotalDebt() public view returns (uint256 totalInterestOwed, uint256 totalPrincipalDebtOwed) {
        address borrowerAddr;
        address principalToken;
        address[] memory loans = getLoans();
        uint256 length = loans.length;
        uint256 interestOwed;
        uint256 principalDebtAmount;

        for (uint256 i = 0; i < length;) {
            borrowerAddr = IOpenTermLoan(loans[i]).borrower();
            if (borrowerAddr == address(this)) {
                (,, principalDebtAmount, interestOwed,,,,,,) = IOpenTermLoan(loans[i]).getDebt();
                principalToken = IOpenTermLoan(loans[i]).principalToken();
                totalInterestOwed += _calculateAmount(principalToken, interestOwed);
                totalPrincipalDebtOwed += _calculateAmount(principalToken, principalDebtAmount);
            }

            unchecked {
                i++;
            }
        }

        return (totalInterestOwed, totalPrincipalDebtOwed);
    }

    /**
     * @notice Get net interest owed and paid to lender across all loans for subaccount.
     */
    function getTotalCredit()
        public
        view
        returns (uint256 netInterestOwed, uint256 totalPrincipalDebtOwed, uint256 netInterestRepaid)
    {
        address lenderAddr;
        address principalToken;
        uint256 length = loanAddresses.length;
        uint256 interestOwed;
        uint256 interestRepaid;
        uint256 interestAfterFees;
        uint256 interestPaymentFees;
        uint256 principalDebtAmount;

        for (uint256 i = 0; i < length;) {
            lenderAddr = IOpenTermLoanV2(loanAddresses[i]).lender();
            if (lenderAddr == address(this)) {
                (,, principalDebtAmount, interestOwed,,,,,,) = IOpenTermLoanV2(loanAddresses[i]).getDebt();
                principalToken = IOpenTermLoanV2(loanAddresses[i]).principalToken();
                interestRepaid = IOpenTermLoanV2(loanAddresses[i]).interestsRepaid();
                (interestAfterFees,) = IOpenTermLoanV2(loanAddresses[i]).getUpcomingAmountAfterFees(interestOwed); 
                interestPaymentFees = IOpenTermLoanV2(loanAddresses[i]).totalInterestPaymentFees();

                netInterestOwed += _calculateAmount(principalToken, interestAfterFees);
                netInterestRepaid += _calculateAmount(principalToken, interestRepaid - interestPaymentFees);
                totalPrincipalDebtOwed += _calculateAmount(principalToken, principalDebtAmount);
            }

            unchecked {
                i++;
            }
        }

        return (netInterestOwed, totalPrincipalDebtOwed, netInterestRepaid);
    }

    /**
     * @notice Get total interest repaid across all loans for subaccount.
     */
    function getTotalInterestRepaid() external view returns (uint256 totalInterestRepaid) {
        address principalToken;
        address[] memory loans = getLoans();
        uint256 length = loans.length;
        uint256 interestRepaid;

        for (uint256 i = 0; i < length;) {
            address borrowerAddr = IOpenTermLoan(loans[i]).borrower();
            if (borrowerAddr == address(this)) {
                interestRepaid = IOpenTermLoan(loans[i]).interestsRepaid();
                principalToken = IOpenTermLoan(loans[i]).principalToken();

                totalInterestRepaid += _calculateAmount(principalToken, interestRepaid);
            }

            unchecked {
                i++;
            }
        }

        return totalInterestRepaid;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../lib/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFractBaseStrategy {
    function enterPosition(IERC20 token, uint256 amount, uint256 minAmount) external;
    function exitPosition(IERC20 token, uint256 amount, uint256 minAmount) external;
    function claimRewards() external;
    function withdraw(IERC20, uint256) external;
    function deposit(IERC20, uint256) external;
    function depositETH() external payable;
    function withdrawETH(uint256) external payable;
    function setOperator(address) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IOpenTermLoan {
    function borrowerCommitment() external;
    function withdraw() external;
    function repayPrincipal(uint256) external;
    function repayInterests() external;
    function getDebt()
        external
        view
        returns (
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
        );
    function principalToken() external view returns (address);
    function fundLoan() external;
    function claimPrincipal() external;
    function interestsRepaid() external view returns (uint256);
    function loanState() external view returns (uint8);
    function borrower() external view returns (address);
    function changeLateFees(uint256, uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

interface IOpenTermLoanV2 {
    function fundLoan() external;
    function callLoan(uint256 callbackPeriodInHours, uint256 gracePeriodInHours) external;
    function liquidate() external;

    function loanState() external view returns (uint8);
    function getEffectiveLoanAmount() external view returns (uint256);
    function getDebtBoundaries()
        external
        view
        returns (uint256 minPayment, uint256 maxPayment, uint256 netDebtAmount);
    function lender() external view returns (address);
    function interestsRepaid() external view returns (uint256);
    function principalRepaid() external view returns (uint256);
    function borrowerCommitment() external;
    function repayPrincipal(uint256) external;
    function repayInterests() external;
    function getDebt()
        external
        view
        returns (
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
        );
    function principalToken() external view returns (address);
    function borrower() external view returns (address);
    function getUpcomingAmountAfterFees(uint256 amount) external view returns (uint256, uint256);
    function proposeNewApr(uint256 newApr) external;
    function acceptApr() external;
    function variableApr() external view returns (uint256);
    function changeLateFees(uint256, uint256) external;
    function totalInterestPaymentFees() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

interface ICounterPartyRegistry {
    function getCounterParty(address) external view returns (bool);
    function getSwapContract(address) external view returns (bool);
    function getSwapContractManager(address) external view returns (bool);
    function getMaxMarginTransferAmount(address) external view returns (uint256);
    function setMaxMarginTransferAmount(address, uint256) external;
    function addSwapContract(address) external;
    function addCounterParty(address) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface ITokenRegistry {
    function getSupportedToken(address) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "../../lib/fractal/oracles/OracleStructs.sol";

interface IOracleRegistry {
    function getSupportedOracle(address) external view returns (address);
    function getSupportedToken(address) external view returns (OracleStructs.Token memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IParaSwapAugustus {
    function getTokenTransferProxy() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

interface ITwapOrder {
    function updatePriceLimit(uint256) external;
    function openOrder(uint256, uint256, uint256, uint256) external;
    function deposit(uint256) external;
    function swap(uint256, uint256, bytes memory) external;
    function cancelOrder() external;
    function closeOrder() external;
    function getOrderMetrics()
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, address, uint8, bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

interface ILenderHook {
    function notifyLoanClosed() external;
    function notifyLoanMatured() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IAggregatorV3Interface} from "../../../interfaces/chainlink/IAggregatorV3Interface.sol";
import {AggregatorInterface} from "../../../interfaces/chainlink/AggregatorInterface.sol";
import {IERC20} from "../../../../lib/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFastPriceFeedReader} from "../../../interfaces/pyth/IFastPriceFeedReader.sol";
import "./OracleStructs.sol";

library OracleMath {
    address constant NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 constant WAD = uint256(10 ** 18);
    uint256 constant PYTH_PRECISION = uint256(10 ** 30);

    function process(OracleStructs.Token memory params, uint256 tokenAmount) internal view returns (uint256 usdValue) {
        uint256 finalPrice = getPrice(params);

        // Adjust usdValue to have 18 decimal places
        usdValue = (tokenAmount * finalPrice * 10 ** (18 - params.decimals)) / (10 ** params.decimals);

        return usdValue;
    }

    function getPrice(OracleStructs.Token memory params) internal view returns (uint256 finalPrice) {
        if (uint8(params.tokenType) == 0) {
            finalPrice = _getPriceOneToken(params.oracle, params.decimals);
        } else if (uint8(params.tokenType) == 1) {
            finalPrice = _getLpTokenPrice(
                params.token, params.pool, params.underlyingTokens, params.underlyingOracles, params.underlyingDecimals
            );
        } else if (uint8(params.tokenType) == 2) {
            finalPrice = _getLpTokenPrice(
                params.token, params.pool, params.underlyingTokens, params.underlyingOracles, params.underlyingDecimals
            );
        } else if (uint8(params.tokenType) == 3) {
            finalPrice = _getSparkTokenPrice(params.oracle, params.decimals);
        } else if (uint8(params.tokenType) == 4) {
            finalPrice = _getPythPrice(params.oracle, params.pool, params.token, params.decimals);
        }
    }

    function processV1(address oracle, uint256, uint8 tokenDecimals, uint256 tokenAmount)
        internal
        view
        returns (uint256 usdValue)
    {
        IAggregatorV3Interface chainlink = IAggregatorV3Interface(oracle);
        (, int256 price,,,) = chainlink.latestRoundData();
        uint256 oracleDecimals = chainlink.decimals();

        uint256 finalPrice;

        if (oracleDecimals > tokenDecimals) {
            finalPrice = uint256(price) / 10 ** (oracleDecimals - tokenDecimals);
        } else if (oracleDecimals < tokenDecimals) {
            finalPrice = uint256(price) * 10 ** (tokenDecimals - oracleDecimals);
        } else {
            finalPrice = uint256(price);
        }

        // Adjust usdValue to have 18 decimal places
        usdValue = (tokenAmount * finalPrice * 10 ** (18 - tokenDecimals)) / (10 ** tokenDecimals);

        return usdValue;
    }

    function getPriceV1(address oracle, uint256 tokenDecimals) internal view returns (uint256 finalPrice) {
        IAggregatorV3Interface chainlink = IAggregatorV3Interface(oracle);
        (, int256 price,,,) = chainlink.latestRoundData();
        uint256 oracleDecimals = chainlink.decimals();

        if (oracleDecimals > tokenDecimals) {
            finalPrice = uint256(price) / 10 ** (oracleDecimals - tokenDecimals);
        } else if (oracleDecimals < tokenDecimals) {
            finalPrice = uint256(price) * 10 ** (tokenDecimals - oracleDecimals);
        } else {
            finalPrice = uint256(price);
        }
    }

    function _getPriceOneToken(address oracle, uint256 tokenDecimals) private view returns (uint256 finalPrice) {
        IAggregatorV3Interface chainlink = IAggregatorV3Interface(oracle);
        (, int256 price,,,) = chainlink.latestRoundData();
        uint256 oracleDecimals = chainlink.decimals();

        if (oracleDecimals > tokenDecimals) {
            finalPrice = uint256(price) / 10 ** (oracleDecimals - tokenDecimals);
        } else if (oracleDecimals < tokenDecimals) {
            finalPrice = uint256(price) * 10 ** (tokenDecimals - oracleDecimals);
        } else {
            finalPrice = uint256(price);
        }
    }

    function _getLpTokenPrice(
        address token,
        address pool,
        address[] memory underlyingTokens,
        address[] memory underlyingOracles,
        uint256[] memory underlyingDecimals
    ) private view returns (uint256 lpTokenPrice) {
        //get total supply
        uint256 totalSupply = IERC20(token).totalSupply();
        uint256 tokenBalance;
        uint256 tokenPrice;
        uint256 totalValue;

        //balance of target
        address target = pool != address(0) ? pool : token;

        require(
            underlyingDecimals.length == underlyingTokens.length
                && underlyingDecimals.length == underlyingOracles.length,
            "invalid arrays"
        );

        uint256 length = underlyingDecimals.length;

        for (uint256 i = 0; i < length; i++) {
            tokenBalance =
                underlyingTokens[i] == NATIVE_ASSET ? target.balance : (IERC20(underlyingTokens[i])).balanceOf(target);
            tokenPrice = _getPriceOneToken(underlyingOracles[i], underlyingDecimals[i]);

            tokenBalance = _scale(tokenBalance, underlyingDecimals[i]);
            tokenPrice = _scale(tokenPrice, underlyingDecimals[i]);

            totalValue += tokenBalance * tokenPrice;
        }

        lpTokenPrice = totalValue / totalSupply;

        return lpTokenPrice;
    }

    function _scale(uint256 amount, uint256 decimals) private pure returns (uint256 scaledAmount) {
        scaledAmount = decimals < 18 ? amount * (10 ** (18 - decimals)) : amount;

        return scaledAmount;
    }

    function _getSparkTokenPrice(address oracle, uint256 tokenDecimals) private view returns (uint256 finalPrice) {
        AggregatorInterface sparkOracle = AggregatorInterface(oracle);
        int256 price = sparkOracle.latestAnswer();
        uint256 oracleDecimals = 8;

        if (oracleDecimals > tokenDecimals) {
            finalPrice = uint256(price) / 10 ** (oracleDecimals - tokenDecimals);
        } else if (oracleDecimals < tokenDecimals) {
            finalPrice = uint256(price) * 10 ** (tokenDecimals - oracleDecimals);
        } else {
            finalPrice = uint256(price);
        }
    }

    function _getPythPrice(address oracle, address pool, address token, uint256 tokenDecimals)
        private
        view
        returns (uint256 finalPrice)
    {
        address[] memory tokens = new address[](1);

        tokens[0] = token;

        uint256[] memory prices = IFastPriceFeedReader(oracle).getPrices(pool, tokens);

        finalPrice = (prices[0] * (10 ** tokenDecimals)) / PYTH_PRECISION;

        return finalPrice;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

library SubAccount {
    /**
     * @notice Loans
     */
    struct OTC {
        address exchangeAccount;
        address otcRouter;
    }

    /**
     * @notice Loans
     */
    struct Fees {
        address feeCollector;
        address feesOracle;
    }

    /**
     * @notice Loans
     */
    struct Loans {
        address[] loanAddresses;
        address loanManager;
    }

    /**
     * @notice Posted Collateral
     */
    struct Posted {
        int256 onchainPosted;
        int256 exchangePosted;
    }

    /**
     * @notice Receiver and Payer.
     */
    struct CounterParties {
        address borrower;
        address lender;
    }

    /**
     * @notice Registry Addresses.
     */
    struct Registries {
        address strategyRegistry;
        address otcRegistry;
        address counterPartyRegistry;
        address tokenRegistry;
        address oracleRegistry;
    }

    /**
     * @notice Registry Addresses.
     */
    struct PositionParams {
        uint256 amount;
        uint256 price;
        uint256 time;
    }

    function removeLoan(address loan, address[] memory loans) internal pure returns (address[] memory) {
        uint256 length = loans.length;
        address[] memory newLoans = new address[](length - 1);
        uint256 j = 0;

        for (uint256 i = 0; i < length; i++) {
            if (loans[i] != loan) {
                newLoans[j++] = loans[i];
            }
        }
        return newLoans;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./ICategoryFees.sol";
import {IERC20} from "../../lib/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../../lib/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title This contract is responsible for handling fees.
 */
abstract contract FeesAwareMini {
    using SafeERC20 for IERC20;

    /**
     * @notice The address of the native asset.
     */
    address public constant NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice This event is triggered whenever this contract transfers fees to the collector.
     */
    event OnFeeProcessed(uint256 feePercent, uint256 feeAmount, address from, address to, address tokenAddr);

    function _applyFeesOnly(
        address feesOracle,
        address feeCollector,
        address tokenAddr,
        uint256 contextAmount,
        bytes32 categoryId
    ) internal virtual returns (uint256 remainingAmount) {
        require(contextAmount > 0, "Context amount required");
        require(categoryId != bytes32(0), "Category required");
        require(feesOracle != address(0) && feesOracle != address(this), "Invalid fees oracle");
        require(feeCollector != address(0) && feeCollector != address(this), "Invalid fees collector");

        // Get the applicable fee
        (uint256 feePercent, uint256 feeAmount) =
            ICategoryFees(feesOracle).getContextFeeAmount(contextAmount, categoryId, address(this));

        if (feeAmount > 0) {
            // Transfer the fees to the collector
            if (tokenAddr == NATIVE_ASSET) {
                payable(feeCollector).transfer(feeAmount);
            } else {
                IERC20(tokenAddr).safeTransfer(feeCollector, feeAmount);
            }

            emit OnFeeProcessed(feePercent, feeAmount, address(this), feeCollector, tokenAddr);
        }

        remainingAmount = (contextAmount > feeAmount) ? contextAmount - feeAmount : 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

library OracleStructs {
    enum TokenType {
        GENERIC,
        CURVE_LP,
        UNISWAP_V2_LP,
        SPARK,
        PYTH
    }

    struct Token {
        TokenType tokenType;
        uint256 decimals;
        address token;
        address oracle;
        address pool;
        uint256[] underlyingDecimals;
        address[] underlyingTokens;
        address[] underlyingOracles;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
pragma solidity ^0.8.0;

interface IAggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
// Chainlink Contracts v0.8
pragma solidity ^0.8.0;

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IFastPriceFeedReader {
    function getPrices(address _fastPriceFeed, address[] memory _tokens) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

interface ICategoryFees {
    function setContextFeeRate(uint256 feePercent, bytes32 categoryId, address specificAddr) external;

    function getContextFeeRate(bytes32 categoryId, address specificAddr) external view returns (uint256);
    function getContextFeeAmount(uint256 amount, bytes32 categoryId, address specificAddr)
        external
        view
        returns (uint256 feePercent, uint256 feeAmount);
}