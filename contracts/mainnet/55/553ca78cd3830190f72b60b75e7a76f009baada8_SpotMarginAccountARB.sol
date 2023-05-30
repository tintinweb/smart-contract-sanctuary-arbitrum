// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import { SubAccount } from "./SubAccount.sol";
import { IERC20 } from "../../lib/openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SpotMarginAccountARB is SubAccount {

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Disable initializers.
     */
    constructor () {
        _disableInitializers();
    }

    /**
     * @notice Initialize the contract. Only called once.
     * @param ownerAddr owner.
     * @param operatorAddr operator.
     * @param feeCollectorAddr fee collector.
     * @param swapContractManagerAddr swap contract manager.
     * @param counterPartyRegistryAddr counter party registry.
     */
    function initialize (
        address ownerAddr,
        address operatorAddr,
        address feeCollectorAddr,
        address swapContractManagerAddr,
        address counterPartyRegistryAddr) external initializer {
        _initSubAccount(
            ownerAddr,
            operatorAddr,
            feeCollectorAddr,
            swapContractManagerAddr,
            counterPartyRegistryAddr
        );
    }

    /*///////////////////////////////////////////////////////////////
                        Modifiers
    //////////////////////////////////////////////////////////////*/


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner || msg.sender == operator, "not owner or operator");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Base Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the active loan contract address
     * @param loan The address of the loan to add.
     */
    function addLoanContract(address loan) external onlyOperator onlyIfInitialized
    {
        _addLoanContract(loan);
    }

    /**
     * @notice Remove a loan contract address
     * @param loan The address of the loan to add.
     */
    function removeLoanContract(address loan) external onlyOperator onlyIfInitialized
    {
        _removeLoanContract(loan);
    }

    /**
     * @notice Set the active strategy contract address
     * @param strategyContractAddress The address of the strategy contract.
     */
    function setActiveStrategy(address strategyContractAddress) external onlyOwnerOrOperator onlyIfInitialized
    {
        _setActiveStrategy(strategyContractAddress);
    }

    /**
     * @notice Close the subaccount.
     * @dev The subaccount cannot be reopened after calling this function.
     */
    function closeSubAccount() external onlyOperator onlyIfInitialized
    {
        _closeSubAccount();
    }

    /**
     * @notice Deploys a twap contract for the subaccount
     * @param traderAddr The address that executes orders through the twap contract.
     * @param depositorAddr The address that deposits into the twap contract.
     * @param sellingToken The token sold through the twap contract.
     * @param buyingToken The token bought through the twap contract.
     */
    function deployTwap(
        address traderAddr, 
        address depositorAddr, 
        IERC20 sellingToken, 
        IERC20 buyingToken) external onlyOperator onlyIfInitialized
    {
        _deployTwap(traderAddr, depositorAddr, sellingToken, buyingToken);
    }

    /**
     * @notice Update Price Limit for a twap order
     * @param priceLimit Price limit for twap order
     */
    function twapUpdatePriceLimit(uint256 priceLimit) external onlyOperator onlyIfInitialized
    {
        _twapUpdatePriceLimit(priceLimit);
    }

    /**
     * @notice Open a twap order
     * @param durationInMins The duration of the twap
     * @param targetQty The target quantity for the twap
     * @param chunkSize The chunk size for the twap
     * @param maxPriceLimit The max price limit for the twap
     */
    function twapOpenOrder(
        uint256 durationInMins, 
        uint256 targetQty, 
        uint256 chunkSize, 
        uint256 maxPriceLimit) external onlyOperator onlyIfInitialized 
    {
        _twapOpenOrder(durationInMins, targetQty, chunkSize, maxPriceLimit);
    }

    /**
     * @notice Deposit into twap contract
     * @param amount Amount of sell token to deposit into twap contract
     */
    function twapDeposit(IERC20 token, uint256 amount) external onlyOperator onlyIfInitialized
    {
        _twapDeposit(token, amount);
    }

    /**
     * @notice Cancel active twap order
     */
    function twapCancelOrder() external onlyOperator onlyIfInitialized
    {
        _twapCancelOrder();
    }

    /**
     * @notice Close active twap order
     * @dev This will transfer all tokens in twap contract back to subaccount. 
     */
    function twapCloseOrder() external onlyOperator onlyIfInitialized
    {
        _twapCloseOrder();
    }
    /**
     * @notice Deploy to the active strategy
     * @param token token to deposit.
     * @param amount amount of tokens to deposit.
     * @param minAmount minimum amount of tokens to receive.
     */
    function deployToStrategy(IERC20 token, uint256 amount, uint256 minAmount) external onlyOwnerOrOperator onlyIfInitialized
    {
        _deployToStrategy(token, amount, minAmount);
    }

    /**
     * @notice Withdraw from the active strategy
     * @param token token to withdraw.
     * @param amount amount of tokens to burn.
     * @param minAmount minimum amount of tokens to receive.
     */
    function withdrawFromStrategy(IERC20 token, uint256 amount, uint256 minAmount) external onlyOwnerOrOperator onlyIfInitialized
    {
        _withdrawFromStrategy(token, amount, minAmount);
    }

    /**
     * @notice Deposit only to active strategy
     * @param token token to deposit.
     * @param amount amount of tokens to deposit.
     */
    function depositToStrategy(IERC20 token, uint256 amount) external onlyOwnerOrOperator onlyIfInitialized
    {
        _depositToStrategy(token, amount);
    }

    /**
     * @notice Withdraw only from active strategy
     * @param token token to deposit.
     * @param amount amount of tokens to deposit.
     */
    function withdrawOnlyFromStrategy(IERC20 token, uint256 amount) external onlyOwnerOrOperator onlyIfInitialized
    {
        _withdrawOnlyFromStrategy(token, amount);
    }

    /**
     * @notice Deposit into the sub account. 
     * @param token token to deposit.
     * @param amount amount of tokens to deposit.
     */
    function deposit(IERC20 token, uint256 amount) external onlyOwner onlyIfInitialized
    { 
        _deposit(token, amount);
    }

    /**
     * @notice Withdraw from the sub account. 
     * @param token token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function withdraw(IERC20 token, uint256 amount) external onlyOwner onlyIfInitialized
    {
        _withdraw(token, amount);
    }

    /**
     * @notice Withdraw from the sub account to the owner address. 
     * @param token token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function withdrawToOwner(IERC20 token, uint256 amount) external onlyOperator onlyIfInitialized
    {
        _withdrawToOwner(token, amount);
    }

    /**
     * @notice Partially unwind a position. 
     * @param loan The address of the loan
     * @param token The token to swap
     * @param amount The amount to swap.
     * @param targetAmount The target amount to use when repaying debt.
     * @param swapCallData The callData to pass to the paraswap router. Generated offchain.
     */
    function partialUnwind(address loan, IERC20 token, uint256 amount, uint256 targetAmount, bytes memory swapCallData) external onlyOperator onlyIfInitialized
    {
        _partialUnwind(loan, token, amount, targetAmount, swapCallData);
    }

    /**
     * @notice Fully unwind a position. 
     * @param loan The address of the loan
     * @param token The token to swap
     * @param amount The amount to swap.
     * @param swapCallData The callData to pass to the paraswap router. Generated offchain.
     */
    function fullUnwind(address loan, IERC20 token, uint256 amount, bytes memory swapCallData) external onlyOperator onlyIfInitialized
    {
        _fullUnwind(loan, token, amount, swapCallData);
    }

    /**
     * @notice Swap rewards via the paraswap router.
     * @param token The token to swap.
     * @param amount The amount of tokens to swap. 
     * @param callData The callData to pass to the paraswap router. Generated offchain.
     */
    function swap(IERC20 token, uint256 amount, bytes memory callData) external payable onlyOperator onlyIfInitialized
    {
        //call internal swap
        _swap(token, amount, callData);
    }

    /**
     * @notice Accept the loan contract.
     * @param loan The address of the loan.
     */
    function acceptLoan(address loan) external onlyOperator onlyIfInitialized
    {
        _acceptLoan(loan);
    }

    /**
     * @notice Withdraw principal amount from the loan contract.
     * @param loan The address of the loan.
     */
    function withdrawLoanPrincipal(address loan) external onlyOperator onlyIfInitialized
    {
        _withdrawLoanPrincipal(loan);
    }

    /**
     * @notice Repay the principal amount for the loan.
     * @param loan The address of the loan.
     * @param amount Amount of principal to pay back.
     */
    function repayLoanPrincipal(address loan, uint256 amount) external onlyOperator onlyIfInitialized
    {
        _repayLoanPrincipal(loan, amount);
    }

    /**
     * @notice Repay accrued interest on the loan.
     * @param loan The address of the loan.
     */
    function repayLoanInterest(address loan) external onlyOperator onlyIfInitialized
    {
        _repayLoanInterest(loan);
    }

    /**
     * @notice Set subAccountState to Margin Call as a warning level.
     */
    function marginCall() external onlyOperator onlyIfInitialized
    {
        _marginCall();
    }

    /**
     * @notice Transfer a specified amount of margin between sub accounts.
     * @param token The token to transfer between accounts.
     * @param toSubAccount The account to transfer tokens to.
     * @param marginAmount The amount of margin to transfer between accounts.
     */
    function transferMargin(IERC20 token, address toSubAccount, uint256 marginAmount) external onlySwapContract onlyIfInitialized 
    {
        _transferMargin(token, toSubAccount, marginAmount);
    }

    /**
     * @notice Transfer a specified amount of tokens to the fractal fee collector.
     * @param token The token to transfer to the fee collector.
     * @param amount The amount to transfer to the fractal fee collector.
     */
    function transferOriginationFee(IERC20 token, uint256 amount) external onlySwapContractManager onlyIfInitialized
    {
        _transferOriginationFee(token, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import { IFractBaseStrategy } from "../interfaces/fractal/IFractBaseStrategy.sol";
import { IOpenTermLoan } from "../interfaces/fractal/IOpenTermLoan.sol";
import { ICounterPartyRegistry } from "../interfaces/fractal/ICounterPartyRegistry.sol";
import { IParaSwapAugustus } from "../interfaces/paraswap/IParaSwapAugustus.sol";
import { ITwapOrder } from "../interfaces/fractal/ITwapOrder.sol";
import { TwapOrder } from "./twap/TwapOrder.sol";
import { SafeERC20 } from "../../lib/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "../../lib/openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Initializable } from "../../lib/openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract SubAccount is Initializable {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/
    
    address constant internal PARASWAP = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    uint8 constant ACTIVE = 0;
    uint8 constant USER_FUNDED = 1;
    uint8 constant MARGIN_FUNDED = 2;
    uint8 constant MARGIN_CALL = 3;
    uint8 constant LIQUIDATED = 4;
    uint8 constant DEFAULTED = 5;
    uint8 constant CLOSED = 6;


    /*///////////////////////////////////////////////////////////////
                        State Variables
    //////////////////////////////////////////////////////////////*/

    uint8 public subAccountState;
    address public owner;
    address public operator;
    address public feeCollector;
    address public swapContractManager;
    address public counterPartyRegistry;
    address public activeStrategy;
    address public twap;

    address[] public loanAddresses;

    /*///////////////////////////////////////////////////////////////
                        Events
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice This event is fired when the subaccount receives a deposit.
     * @param account Specifies the depositor address.
     * @param amount Specifies the deposit amount.
     */
    event Deposit(address account, uint amount);

    /**
     * @notice This event is fired when the subaccount receives a withdrawal.
     * @param account Specifies the withdrawer address.
     * @param amount Specifies the withdrawal amount,
     */
    event Withdraw(address account, uint amount);

    /**
     * @notice This event is fired when the subaccount receives a withdrawal to owner.
     * @param token Specifies the token address.
     * @param amount Specifies the withdrawal amount,
     */
    event WithdrawToOwner(IERC20 token, uint amount);

    /**
     * @notice This event is fired when the subaccount adds a loan contract.
     * @param loan Address of the loan contract.
     */
    event AddLoan(address loan);

    /**
     * @notice This event is fired when the subaccount removes a loan contract.
     * @param loan Address of the loan contract.
     */
    event RemoveLoan(address loan);

    /**
     * @notice This event is fired when the subaccount is partially liquidated.
     * @param liquidator Address of liquidator.
     * @param state The state of the subaccount after liquidation.
     */
    event PartialLiquidation(address liquidator, uint8 state);

    /**
     * @notice This event is fired when the subaccount is fully liquidated.
     * @param liquidator Address of liquidator.
     * @param state The state of the subaccount after liquidation.
     */
    event FullLiquidation(address liquidator, uint8 state);

    /*///////////////////////////////////////////////////////////////
                        Modifiers
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Safety check for all possible versions of this contract.
     */
    modifier onlyIfInitialized {
        require(_getInitializedVersion() != type(uint8).max, "Contract was not initialized yet");
        _;
    }

    /**
     * @notice Only called by owner
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    /**
     * @notice Only called by controller
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Only Operator");
        _;
    }

    /**
     * @notice Only called by active swap contract
     */
    modifier onlySwapContract() {
        require(ICounterPartyRegistry(counterPartyRegistry).getSwapContract(msg.sender), 'Only Swap Contract');
        _;
    }

    /**
     * @notice Only called by swap contract manager
     */
    modifier onlySwapContractManager() {
        require(msg.sender == swapContractManager, 'Only Swap Contract Manager');
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Base Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the contract. Only called once.
     * @param ownerAddr owner.
     * @param operatorAddr operator.
     * @param feeCollectorAddr fee collector.
     * @param swapContractManagerAddr swap contract mananger.
     * @param counterPartyRegistryAddr counter party registry.
     */
    function _initSubAccount(
        address ownerAddr,
        address operatorAddr,
        address feeCollectorAddr,
        address swapContractManagerAddr,
        address counterPartyRegistryAddr) internal onlyInitializing 
    {
        owner = ownerAddr;
        operator = operatorAddr;
        feeCollector = feeCollectorAddr;
        swapContractManager = swapContractManagerAddr;
        counterPartyRegistry = counterPartyRegistryAddr;
    }

    /**
     * @notice Set the active loan contract address
     * @param loan The address of the loan to add.
     */
    function _addLoanContract(address loan) internal 
    {
        loanAddresses.push(loan);

        emit AddLoan(loan);
    }

    /**
     * @notice Remove a loan contract address
     * @param loan The address of the loan to remove.
     */
    function _removeLoanContract(address loan) internal 
    {
        //store new array
        address[] storage loanToRemove = loanAddresses;
        //cache length
        uint256 length = loanToRemove.length;
        for (uint256 i = 0; i < length;) {
            if (loan == loanToRemove[i]) {
                loanToRemove[i] = loanToRemove[length - 1];
                loanToRemove.pop();
                break;
            }

            unchecked { ++i; }
        }
        loanAddresses = loanToRemove;

        emit RemoveLoan(loan);
    }

    /**
     * @notice Set the active strategy contract address
     * @param strategyContractAddress The address of the strategy contract.
     */
    function _setActiveStrategy(address strategyContractAddress) internal 
    {
        activeStrategy = strategyContractAddress;
    }

    /**
     * @notice Close the subaccount.
     * @dev The subaccount cannot be reopened after calling this function.
     */
    function _closeSubAccount() internal
    {
        subAccountState = CLOSED; 
    }

    /**
     * @notice Deploys a twap contract for the subaccount
     * @param traderAddr The address that executes orders through the twap contract.
     * @param depositorAddr The address that deposits into the twap contract.
     * @param sellingToken The token sold through the twap contract.
     * @param buyingToken The token bought through the twap contract.
     */
    function _deployTwap(address traderAddr, address depositorAddr, IERC20 sellingToken, IERC20 buyingToken) internal 
    {
        TwapOrder instance = new TwapOrder();
        instance.initialize(traderAddr, depositorAddr, sellingToken, buyingToken);
        instance.transferOwnership(address(this));
        twap = address(instance);
    }

    /**
     * @notice Update Price Limit for a twap order
     * @param priceLimit Price limit for twap order
     */
    function _twapUpdatePriceLimit(uint256 priceLimit) internal
    {
        ITwapOrder(twap).updatePriceLimit(priceLimit); 
    }

    /**
     * @notice Open a twap order
     * @param durationInMins The duration of the twap
     * @param targetQty The target quantity for the twap
     * @param chunkSize The chunk size for the twap
     * @param maxPriceLimit The max price limit for the twap
     */
    function _twapOpenOrder(uint256 durationInMins, uint256 targetQty, uint256 chunkSize, uint256 maxPriceLimit) internal 
    {
        ITwapOrder(twap).openOrder(durationInMins, targetQty, chunkSize, maxPriceLimit);
    }

    /**
     * @notice Deposit into twap contract
     * @param amount Amount of sell token to deposit into twap contract
     */
    function _twapDeposit(IERC20 token, uint256 amount) internal 
    {
        token.safeApprove(twap, amount);
        ITwapOrder(twap).deposit(amount);
        token.safeApprove(twap, 0);
    }

    /**
     * @notice Cancel active twap order
     */
    function _twapCancelOrder() internal 
    {
        ITwapOrder(twap).cancelOrder();
    }

    /**
     * @notice Close active twap order
     * @dev This will transfer all tokens in twap contract back to subaccount. 
     */
    function _twapCloseOrder() internal
    {
        ITwapOrder(twap).closeOrder();
    }

    /**
     * @notice Deploy to the active strategy
     * @param token token to deposit.
     * @param amount amount of tokens to deposit.
     * @param minAmount minimum amount of tokens to receive.
     */
    function _deployToStrategy(IERC20 token, uint256 amount, uint256 minAmount) internal
    
    {
        //check state
        require(subAccountState == USER_FUNDED || subAccountState == MARGIN_FUNDED, 'not funded');
        //approve strategy as spender
        token.safeApprove(activeStrategy, amount);
        //transfer the amount to strategy
        IFractBaseStrategy(activeStrategy).deposit(token, amount);
        //enter position
        IFractBaseStrategy(activeStrategy).enterPosition(token, amount, minAmount);
        //set approval back to 0
        token.safeApprove(activeStrategy, 0);
    }

    /**
     * @notice Withdraw from the active strategy
     * @param token token to withdraw.
     * @param amount amount of tokens to withdraw.
     * @param minAmount minimum amount of tokens to receive.
     */
    function _withdrawFromStrategy(IERC20 token, uint256 amount, uint256 minAmount) internal
    {
        //check state
        require(subAccountState == USER_FUNDED || subAccountState == MARGIN_FUNDED, 'not funded');
        //exit position
        IFractBaseStrategy(activeStrategy).exitPosition(token, amount, minAmount);
        //call withdraw on active strategy
        IFractBaseStrategy(activeStrategy).withdraw(token, token.balanceOf(activeStrategy));
    }


    /**
     * @notice Deposit only to active strategy
     * @param token token to deposit.
     * @param amount amount of tokens to deposit.
     */
    function _depositToStrategy(IERC20 token, uint256 amount) internal
    
    {
        //check state
        require(subAccountState == USER_FUNDED || subAccountState == MARGIN_FUNDED, 'not funded');
        //approve strategy as spender
        token.safeApprove(activeStrategy, amount);
        //transfer the amount to strategy
        IFractBaseStrategy(activeStrategy).deposit(token, amount);
        //revoke approval
        token.safeApprove(activeStrategy, 0);
    }

    /**
     * @notice Withdraw only from active strategy
     * @param token token to deposit.
     * @param amount amount of tokens to deposit.
     */
    function _withdrawOnlyFromStrategy(IERC20 token, uint256 amount) internal
    {
        //check state
        require(subAccountState == USER_FUNDED || subAccountState == MARGIN_FUNDED, 'not funded');
        //call withdraw on active strategy
        IFractBaseStrategy(activeStrategy).withdraw(token, amount);
    }

    /**
     * @notice Deposit into the sub account. 
     * @param token token to deposit.
     * @param amount amount of tokens to deposit.
     */
    function _deposit(IERC20 token, uint256 amount) internal 
    {
        require(subAccountState == ACTIVE || subAccountState == USER_FUNDED || subAccountState == MARGIN_FUNDED || subAccountState == MARGIN_CALL, 'not active or funded');

        emit Deposit(msg.sender, amount);

        subAccountState = USER_FUNDED;

        _checkLoan(); 

        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Withdraw from the sub account. 
     * @param token token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function _withdraw(IERC20 token, uint256 amount) internal 
    {
        //check state
        require(subAccountState == USER_FUNDED || subAccountState == MARGIN_FUNDED, 'not funded');

        emit Withdraw(msg.sender, amount);

        token.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Withdraw from the sub account. 
     * @param token token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function _withdrawToOwner(IERC20 token, uint256 amount) internal 
    {

        emit WithdrawToOwner(token, amount);

        token.safeTransfer(owner, amount);
    }

    /**
     * @notice Swap rewards via the paraswap router.
     * @param token The token to swap.
     * @param amount The amount of tokens to swap. 
     * @param callData The callData to pass to the paraswap router. Generated offchain.
     */
    function _swap(IERC20 token, uint256 amount, bytes memory callData) internal 
    {
        //get TokenTransferProxy depending on chain.
        address tokenTransferProxy = IParaSwapAugustus(PARASWAP).getTokenTransferProxy();
        // allow TokenTransferProxy to spend token
        token.safeApprove(tokenTransferProxy, amount);
        //swap
        (bool success,) = PARASWAP.call(callData);
        //check swap
        require(success, "swap failed");
        //set approval back to 0
        token.safeApprove(tokenTransferProxy, 0);
    }


    /**
     * @notice Accept the loan contract.
     * @param loan The address of the loan.
     */
    function _acceptLoan(address loan) internal 
    {
        //check state
        require(subAccountState == USER_FUNDED || subAccountState == MARGIN_FUNDED, 'not funded');
        //get principal token
        address token = IOpenTermLoan(loan).principalToken();
        //approve loan contract as spender for white glove contract.
        IERC20(token).safeApprove(loan, type(uint256).max);
        //commit to loan
        IOpenTermLoan(loan).borrowerCommitment();
    }

    /**
     * @notice Withdraw principal amount from the loan contract.
     * @param loan The address of the loan.
     */
    function _withdrawLoanPrincipal(address loan) internal 
    {

        require(subAccountState == USER_FUNDED || subAccountState == MARGIN_FUNDED, 'not funded');

        subAccountState = MARGIN_FUNDED;

        IOpenTermLoan(loan).withdraw();
    }

    /**
     * @notice Repay the principal amount for the loan.
     * @param loan The address of the loan.
     * @param amount Amount of principal to pay back.
     */
    function _repayLoanPrincipal(address loan, uint256 amount) internal 
    {
        IOpenTermLoan(loan).repayPrincipal(amount);
    }

    /**
     * @notice Repay accrued interest on the loan.
     * @param loan The address of the loan.
     */
    function _repayLoanInterest(address loan) internal 
    {

        IOpenTermLoan(loan).repayInterests();
    }

    /**
     * @notice Set subAccountState to Margin Call as a warning level.
     */
    function _marginCall() internal 
    {
        //check state
        require(subAccountState == MARGIN_FUNDED, 'not funded');
        //set state
        subAccountState = MARGIN_CALL;
    }

    /**
     * @notice Partially unwind a position. 
     * @param loan The address of the loan to pay off.
     * @param token The token to swap
     * @param amount The amount to swap.
     * @param targetAmount The target amount to use when paying off interest and debt.
     * @param swapCallData The callData to pass to the paraswap router. Generated offchain.
     */
    function _partialUnwind(
        address loan,
        IERC20 token, 
        uint256 amount,
        uint256 targetAmount, 
        bytes memory swapCallData) internal 
    {
        //get principalDebt and interestOwed amount
        (,,,uint256 interestOwed,,,,,,) = IOpenTermLoan(loan).getDebt();
        //get principal token
        address principalToken = IOpenTermLoan(loan).principalToken();
        //repay amount
        uint256 repayAmount;
        //principle liquidation fee
        uint256 principleLiquidationFee = (targetAmount * 200) / 10000;
        //transfer
        IERC20(principalToken).safeTransfer(feeCollector, principleLiquidationFee);
        //check if interest owed
        if (interestOwed > 0) {
            //calculate fees
            uint256 interestLiquidationFee = (interestOwed * 200) / 10000;
            //transfer fees
            IERC20(principalToken).safeTransfer(feeCollector, interestLiquidationFee);  
            //repay
            repayAmount = targetAmount - interestOwed - principleLiquidationFee - interestLiquidationFee;
            //if no token passed == no collateral to swap
            if (address(token) == address(0)) {
                //pay interest
                _repayLoanInterest(loan);
                //use remaining balance to partially pay principal debt amount
                _repayLoanPrincipal(loan, repayAmount);
            } else 
            {
                //swap to principalToken
                _swap(token, amount, swapCallData);
                //pay interest
                _repayLoanInterest(loan);
                //use remaining balance to partially pay principal debt amount
                _repayLoanPrincipal(loan, repayAmount);
            }
        } else {
            //repay
            repayAmount = targetAmount - principleLiquidationFee;
            //if no token passed == no collateral to swap
            if (address(token) == address(0)) {
                //use remaining balance to partially pay principal debt amount
                _repayLoanPrincipal(loan, repayAmount);
            } else 
            {
                //swap to principalToken
                _swap(token, amount, swapCallData);
                //use remaining balance to partially pay principal debt amount
                _repayLoanPrincipal(loan, repayAmount);  
            }
        }

        emit PartialLiquidation(msg.sender, subAccountState);
    }

    /**
     * @notice Fully unwind a position. 
     * @param loan The address of the loan.
     * @param token The token to swap
     * @param amount The amount to swap.
     * @param swapCallData The callData to pass to the paraswap router. Generated offchain.
     */
    function _fullUnwind(
        address loan,
        IERC20 token, 
        uint256 amount,
        bytes memory swapCallData) internal
    {
        //get principalDebt and interestOwed amount
        (,,uint256 principalDebtAmount,uint256 interestOwed,,,,,,) = IOpenTermLoan(loan).getDebt();
        //get principal token
        address principalToken = IOpenTermLoan(loan).principalToken();
        //principle liquidation fee
        uint256 principleLiquidationFee = (principalDebtAmount * 200) / 10000;
        //transfer fee
        IERC20(principalToken).safeTransfer(feeCollector, principleLiquidationFee);
        //if interest is owed
        if (interestOwed > 0) {
            //calculate fees
            uint256 interestLiquidationFee = (interestOwed * 200) / 10000;
            //transfer fees
            IERC20(principalToken).safeTransfer(feeCollector, interestLiquidationFee);  
            //if nothing to swap
            if (address(token) == address(0)) {
                //pay interest
                _repayLoanInterest(loan);
                //use remaining balance to partially pay principal debt amount
                if (IERC20(principalToken).balanceOf(address(this)) >= principalDebtAmount) {
                    //repay loan
                    _repayLoanPrincipal(loan, principalDebtAmount);
                    //set state
                    subAccountState = LIQUIDATED;
                } else
                {
                    //repay whatever account can
                    _repayLoanPrincipal(loan, IERC20(principalToken).balanceOf(address(this)));
                    //set state
                    subAccountState = DEFAULTED;
                }
            } else 
            {
                //swap to principalToken
                _swap(token, amount, swapCallData);
                //pay interest
                _repayLoanInterest(loan);
                //use remaining balance to partially pay principal debt amount
                if (IERC20(principalToken).balanceOf(address(this)) >= principalDebtAmount) {
                    //repay loan
                    _repayLoanPrincipal(loan, principalDebtAmount);
                    //set state
                    subAccountState = LIQUIDATED;
                } else
                {
                    //repay whatever account can
                    _repayLoanPrincipal(loan, IERC20(principalToken).balanceOf(address(this)));
                    //set state
                    subAccountState = DEFAULTED;
                }
            }
        } else 
        {
            //if nothing to swap
            if (address(token) == address(0)) {
                //use remaining balance to partially pay principal debt amount
                if (IERC20(principalToken).balanceOf(address(this)) >= principalDebtAmount) {
                    //repay loan
                    _repayLoanPrincipal(loan, principalDebtAmount);
                    //set state
                    subAccountState = LIQUIDATED;
                } else
                {
                    //repay whatever account can
                    _repayLoanPrincipal(loan, IERC20(principalToken).balanceOf(address(this)));
                    //set state
                    subAccountState = DEFAULTED;
                }  
            } else 
            {
                //swap to principalToken
                _swap(token, amount, swapCallData);
                //use remaining balance to partially pay principal debt amount
                if (IERC20(principalToken).balanceOf(address(this)) >= principalDebtAmount) {
                    //repay loan
                    _repayLoanPrincipal(loan, principalDebtAmount);
                    //set state
                    subAccountState = LIQUIDATED;
                } else{
                    //repay whatever account can
                    _repayLoanPrincipal(loan, IERC20(principalToken).balanceOf(address(this)));
                    //set state
                    subAccountState = DEFAULTED;
                }
            }  
        }

        emit FullLiquidation(msg.sender, subAccountState);
    }

    /**
     * @notice Transfer a specified amount of margin between sub accounts.
     * @param token The token to transfer between accounts.
     * @param toSubAccount The account to transfer tokens to.
     * @param marginAmount The amount of margin to transfer between accounts.
     */
    function _transferMargin(IERC20 token, address toSubAccount, uint256 marginAmount) internal 
    {
        require(subAccountState == USER_FUNDED || subAccountState == MARGIN_FUNDED, 'not funded');
        //check that to and from sub accounts are valid.
        require(ICounterPartyRegistry(counterPartyRegistry).getCounterParty(toSubAccount), 'invalid counter party');
        //approve operator as spender of token for maxMarginTransferAmount
        token.safeApprove(toSubAccount, marginAmount);
        //transfer correct amounts based on calculation in the swap contract
        token.safeTransfer(toSubAccount, marginAmount);
        //set approval back to 0
        token.safeApprove(toSubAccount, 0);
    }

    /**
     * @notice Transfer a specified amount of tokens to the fractal fee collector.
     * @param token The token to transfer to the fee collector.
     * @param amount The amount to transfer to the fractal fee collector.
     */
    function _transferOriginationFee(IERC20 token, uint256 amount) internal 
    {
        token.safeApprove(feeCollector, amount);
        //transfer the amount to fee collector
        token.safeTransfer(feeCollector, amount);
        //set approval back to 0
        token.safeApprove(feeCollector, 0);
    }

    function _checkLoan() internal
    {
        if (loanAddresses.length > 0) {
            subAccountState = MARGIN_FUNDED;
        }
    }

    /**
     * @notice Withdraw eth locked in contract back to owner
     * @param amount amount of eth to send.
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        (bool success,) = payable(owner).call{value: amount}("");
        require(success, "withdraw failed");
    }

    function getLoans() external view returns (address[] memory) 
    {
        return loanAddresses;
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

import { IERC20 } from "../../../lib/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFractBaseStrategy {
    function enterPosition(IERC20 token, uint256 amount, uint256 minAmount) external;
    function exitPosition(IERC20 token, uint256 amount, uint256 minAmount) external;
    function claimRewards() external;
    function withdraw(IERC20, uint256) external;
    function deposit(IERC20, uint256) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IOpenTermLoan {
    function borrowerCommitment() external;
    function withdraw() external;
    function repayPrincipal(uint256) external;
    function repayInterests() external;
    function getDebt() external view returns 
    (
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
    function principalToken() external view returns(address);
    
}

// SPDX-License-Identifier: AGPL-3.0
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
    function getOrderMetrics() external view returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        address,
        uint8,
        bool
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IParaSwapAugustus} from "../../interfaces/paraswap/IParaSwapAugustus.sol";
import {ITwapQuery} from "./ITwapQuery.sol";
import { IERC20 } from "../../../lib/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CustomOwnable} from "./CustomOwnable.sol";
import {CustomInitializable} from "./CustomInitializable.sol";
import {ReentrancyGuard} from "../../lib/openzeppelin/security/ReentrancyGuard.sol";

contract TwapOrder is ITwapQuery, CustomOwnable, CustomInitializable, ReentrancyGuard {    
    address private constant AUGUSTUS_SWAPPER_ADDR = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    uint8 private constant STATE_ACTIVE = 1;
    uint8 private constant STATE_FINISHED = 2;
    uint8 private constant STATE_CANCELLED = 3;

    uint256 internal _startedOn;
    uint256 internal _deadline;
    uint256 internal _spent;
    uint256 internal _filled;
    uint256 internal _tradeSize;
    uint256 internal _priceLimit;
    uint256 internal _chunkSize;
    address public sellingTokenAddress;
    address public buyingTokenAddress;
    address public traderAddress;
    address public depositorAddress;

    uint8 internal _currentState;
    bool internal _orderAlive;

    event OnTraderChanged (address newAddr);
    event OnDepositorChanged (address newAddr);
    event OnCompletion ();
    event OnCancel ();
    event OnClose ();
    event OnOpen ();
    event OnSwap (address fromToken, uint256 fromAmount, address toToken, uint256 toAmount);


    constructor () {
        _owner = msg.sender;
    }

    modifier onlyTrader() {
        require(traderAddress == msg.sender, "Only trader");
        _;
    }

    modifier onlyDepositor() {
        require(depositorAddress == msg.sender, "Only depositor");
        _;
    }

    modifier ifCanCloseOrder () {
        require(_orderAlive, "Current order is not live");
        require(
            (_currentState == STATE_FINISHED || _currentState == STATE_CANCELLED) || 
            (_currentState == STATE_ACTIVE && block.timestamp > _deadline) // solhint-disable-line not-rely-on-time
        , "Cannot close order yet");
        _;
    }

    function initialize (address traderAddr, address depositorAddr, IERC20 sellingToken, IERC20 buyingToken) external onlyOwner ifNotInitialized {
        require(address(sellingToken) != address(buyingToken), "Invalid pair");

        traderAddress = traderAddr;
        depositorAddress = depositorAddr;
        sellingTokenAddress = address(sellingToken);
        buyingTokenAddress = address(buyingToken);

        _initializationCompleted();
    }

    function switchTrader (address traderAddr) external onlyOwner ifInitialized {
        require(traderAddr != address(0), "Invalid trader");
        require(traderAddr != traderAddress, "Trader already set");
        require(!_orderAlive, "Current order still alive");

        traderAddress = traderAddr;
        emit OnTraderChanged(traderAddr);
    }

    function switchDepositor (address depositorAddr) external onlyOwner ifInitialized {
        require(depositorAddr != address(0), "Invalid depositor");
        require(depositorAddr != depositorAddress, "Depositor already set");
        require(!_orderAlive, "Current order still alive");

        depositorAddress = depositorAddr;
        emit OnDepositorChanged(depositorAddr);
    }

    function updatePriceLimit (uint256 newPriceLimit) external onlyDepositor ifInitialized nonReentrant {
        require(newPriceLimit != _priceLimit, "Price limit already set");
        require(_currentState == STATE_ACTIVE, "Invalid state");
        require(_deadline > block.timestamp, "Deadline expired"); // solhint-disable-line not-rely-on-time

        _priceLimit = newPriceLimit;
    }

    function openOrder (uint256 durationInMins, uint256 targetQty, uint256 chunkSize, uint256 maxPriceLimit) external onlyDepositor ifInitialized {
        require(durationInMins >= 5, "Invalid duration");
        require(targetQty > 0, "Invalid trade size");
        require(chunkSize > 0, "Invalid chunk size");
        require(maxPriceLimit > 0, "Invalid price limit");
        require(!_orderAlive, "Current order still alive");

        _startedOn = block.timestamp; // solhint-disable-line not-rely-on-time
        _deadline = block.timestamp + (durationInMins * 1 minutes); // solhint-disable-line not-rely-on-time
        _tradeSize = targetQty;
        _chunkSize = chunkSize;
        _priceLimit = maxPriceLimit;
        _filled = 0;
        _spent = 0;
        _orderAlive = true;
        _currentState = STATE_ACTIVE;

        _approveProxy();
        emit OnOpen();
    }

    function deposit (uint256 depositAmount) external onlyDepositor ifInitialized {
        require(IERC20(sellingTokenAddress).transferFrom(msg.sender, address(this), depositAmount), "Deposit failed");
    }

    function swap (uint256 sellQty, uint256 buyQty, bytes memory payload) external nonReentrant onlyTrader ifInitialized {
        require(_currentState == STATE_ACTIVE, "Invalid state");
        require(_deadline > block.timestamp, "Deadline expired"); // solhint-disable-line not-rely-on-time
 
        IERC20 sellingToken = IERC20(sellingTokenAddress);
        uint256 sellingTokenBefore = sellingToken.balanceOf(address(this));
        require(sellingTokenBefore > 0, "Insufficient balance");

        IERC20 buyingToken = IERC20(buyingTokenAddress);
        uint256 buyingTokenBefore = buyingToken.balanceOf(address(this));

        // Swap
        (bool success,) = AUGUSTUS_SWAPPER_ADDR.call(payload); // solhint-disable-line avoid-low-level-calls
        require(success, "Swap failed");

        uint256 sellingTokenAfter = sellingToken.balanceOf(address(this));
        uint256 buyingTokenAfter = buyingToken.balanceOf(address(this));
        require(buyingTokenAfter > buyingTokenBefore, "Invalid swap: Buy");
        require(sellingTokenBefore > sellingTokenAfter, "Invalid swap: Sell");

        // The number of tokens received after running the swap
        uint256 tokensReceived = buyingTokenAfter - buyingTokenBefore;
        require(tokensReceived >= buyQty, "Invalid amount received");
        _filled += tokensReceived;

        // The number of tokens sold during this swap
        uint256 tokensSold = sellingTokenBefore - sellingTokenAfter;
        require(tokensSold <= sellQty, "Invalid amount spent");
        _spent += tokensSold;

        emit OnSwap(sellingTokenAddress, tokensSold, buyingTokenAddress, tokensReceived);

        if (buyingTokenAfter >= _tradeSize) {
            _currentState = STATE_FINISHED;
            emit OnCompletion();
        }
    }

    function cancelOrder () external nonReentrant onlyDepositor ifInitialized {
        require(_currentState == STATE_ACTIVE, "Invalid state");

        _currentState = STATE_CANCELLED;
        emit OnCancel();

        _closeOrder();
    }

    function closeOrder () external nonReentrant onlyDepositor ifInitialized {
        _closeOrder();
    }

    function _closeOrder () private ifCanCloseOrder {
        _orderAlive = false;

        IERC20 sellingToken = IERC20(sellingTokenAddress);
        IERC20 buyingToken = IERC20(buyingTokenAddress);
        uint256 sellingTokenBalance = sellingToken.balanceOf(address(this));
        uint256 buyingTokenBalance = buyingToken.balanceOf(address(this));

        if (sellingTokenBalance > 0) require(sellingToken.transfer(depositorAddress, sellingTokenBalance), "Transfer failed: sell");
        if (buyingTokenBalance > 0) require(buyingToken.transfer(depositorAddress, buyingTokenBalance), "Transfer failed: buy");
        _revokeProxy();

        emit OnClose();
    }

    function _approveProxy () private {
        IERC20 token = IERC20(sellingTokenAddress);
        address proxyAddr = IParaSwapAugustus(AUGUSTUS_SWAPPER_ADDR).getTokenTransferProxy();
        if (token.allowance(address(this), proxyAddr) != type(uint256).max) {
            require(token.approve(proxyAddr, type(uint256).max), "Token approval failed");
        }

        /*
        IERC20 token = IERC20(sellingTokenAddress);
        uint256 currentBalance = token.balanceOf(address(this));
        address proxyAddr = IParaSwapAugustus(AUGUSTUS_SWAPPER_ADDR).getTokenTransferProxy();
        if (token.allowance(address(this), proxyAddr) < currentBalance) {
            require(token.approve(proxyAddr, currentBalance), "Token approval failed");
        }
        */
    }

    function _revokeProxy () private {
        IERC20 token = IERC20(sellingTokenAddress);
        address proxyAddr = IParaSwapAugustus(AUGUSTUS_SWAPPER_ADDR).getTokenTransferProxy();
        if (token.allowance(address(this), proxyAddr) > 0) {
            require(token.approve(proxyAddr, 0), "Token approval failed");
        }
    }

    function getOrderMetrics () external view override returns (uint256 pStartedOn, uint256 pDeadline, uint256 pSpent, uint256 pFilled, uint256 pTradeSize, uint256 pChunkSize, uint256 pPriceLimit, address srcToken, address dstToken, uint8 pState, bool pAlive) {
        pDeadline = _deadline;
        pSpent = _spent;
        pFilled = _filled;
        pStartedOn = _startedOn;
        pTradeSize = _tradeSize;
        pChunkSize = _chunkSize;
        srcToken = sellingTokenAddress;
        dstToken = buyingTokenAddress;
        pState = _currentState;
        pAlive = _orderAlive;
        pPriceLimit = _priceLimit;
    }
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
pragma solidity 0.8.10;

interface ITwapQuery {
  function getOrderMetrics () external view returns (uint256 pStartedOn, uint256 pDeadline, uint256 pSpent, uint256 pFilled, uint256 pTradeSize, uint256 pChunkSize, uint256 pPriceLimit, address srcToken, address dstToken, uint8 pState, bool pAlive);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title Represents an ownable resource.
 */
contract CustomOwnable {
    // The current owner of this resource.
    address internal _owner;

    /**
     * @notice This event is triggered when the current owner transfers ownership of the contract.
     * @param previousOwner The previous owner
     * @param newOwner The new owner
     */
    event OnOwnershipTransferred (address previousOwner, address newOwner);

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) external virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        _transferOwnership(addr);
    }

    /**
     * @notice Gets the owner of this contract.
     * @return Returns the address of the owner.
     */
    function owner () external virtual view returns (address) {
        return _owner;
    }

    function _transferOwnership (address addr) internal virtual {
        address oldValue = _owner;
        _owner = addr;
        emit OnOwnershipTransferred(oldValue, _owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title Represents a resource that requires initialization.
 */
contract CustomInitializable {
    bool private _wasInitialized;

    /**
     * @notice Throws if the resource was not initialized yet.
     */
    modifier ifInitialized () {
        require(_wasInitialized, "Not initialized yet");
        _;
    }

    /**
     * @notice Throws if the resource was initialized already.
     */
    modifier ifNotInitialized () {
        require(!_wasInitialized, "Already initialized");
        _;
    }

    /**
     * @notice Marks the resource as initialized.
     */
    function _initializationCompleted () internal ifNotInitialized {
        _wasInitialized = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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