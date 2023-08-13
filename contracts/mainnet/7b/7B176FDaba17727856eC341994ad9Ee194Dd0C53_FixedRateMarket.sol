// SPDX-License-Identifier: NONE
pragma solidity >=0.8.9 <=0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IFeeEmissionsQontroller.sol";
import "./interfaces/IFixedRateMarket.sol";
import "./interfaces/ILiquidityEmissionsQontroller.sol";
import "./interfaces/IQollateralManager.sol";
import "./interfaces/IQPriceOracle.sol";
import "./interfaces/ITradingEmissionsQontroller.sol";
import "./interfaces/IQAdmin.sol";
import "./interfaces/IQuoteManager.sol";
import "./interfaces/IQToken.sol";
import "./libraries/CustomErrors.sol";
import "./libraries/Interest.sol";
import "./libraries/LinkedList.sol";
import "./libraries/QTypes.sol";
import "./libraries/Utils.sol";

contract FixedRateMarket is Initializable, IFixedRateMarket {

  using SafeERC20 for IERC20;
  using LinkedList for LinkedList.OrderbookSide;

  /// @notice Reserve storage gap so introduction of new parent class later on can be done via upgrade
  uint256[150] __gap;
  
  /// @notice Borrow side enum
  uint8 private constant _SIDE_BORROW = 0;

  /// @notice Lend side enum
  uint8 private constant _SIDE_LEND = 1;

  /// @notice Internal representation on null pointer for linked lists
  uint64 private constant _NULL_POINTER = 0;

  /// @notice Token dust size - effectively treat it as zero
  uint private constant _DUST = 100;
  
  /// @notice Contract storing all global Qoda parameters
  IQAdmin private _qAdmin;

  /// @notice Address of the ERC20 token which the loan will be denominated
  IERC20 private _underlying;
  
  /// @notice UNIX timestamp (in seconds) when the market matures
  uint private _maturity;

  /// @notice Storage for all borrows by a user
  /// account => principalPlusInterest
  mapping(address => uint) private _accountBorrows;

  /// @notice (Deprecated) Storage for qTokens redeemed so far by a user
  /// account => qTokensRedeemed
  mapping(address => uint) private _tokensRedeemed;

  /// @notice (Deprecated) Tokens redeemed across all users so far
  uint private _tokensRedeemedTotal;

  /// @notice Total protocol fee accrued in this market so far, in local currency
  uint private _totalAccruedFees;

  /// @notice For calculation of prorated protocol fee
  uint private constant ONE_YEAR_IN_SECONDS = 365 * 24 * 60 * 60;
  
  /// @notice Contract managing quotes
  IQuoteManager private _quoteManager;
  
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;
  
  /// @notice Same as _status in `@openzeppelin/contracts/security/ReentrancyGuard.sol`
  /// Reconstruct here instead of inheritance is to avoid storage slot sequence problem 
  /// during contract upgrade, as well as saving contract size with use of custom error
  uint256 private _status;
  
  /// @notice Name of this contract
  string private _name;
  
  /// @notice Symbol representing this contract
  string private _symbol;
  
  /// @notice Contract managing qTokens
  IQToken private _qToken;
  
  constructor() {
    _disableInitializers();
  }

  /// @notice Constructor for upgradeable contracts
  /// @param qAdminAddr_ Address of the `QAdmin` contract
  /// @param underlyingAddr_ Address of the underlying loan token denomination
  /// @param maturity_ UNIX timestamp (in seconds) when the market matures
  /// @param name_ Name of the market's ERC20 token
  /// @param symbol_ Symbol of the market's ERC20 token
  function initialize(
                      address qAdminAddr_,
                      address underlyingAddr_,
                      uint maturity_,
                      string memory name_,
                      string memory symbol_
                      ) public initializer {
    _name = name_;
    _symbol = symbol_;
    _qAdmin = IQAdmin(qAdminAddr_);
    _underlying = IERC20(underlyingAddr_);
    _maturity = maturity_;
  }
  
  /// @notice Needed for native token operation when withdrawing from WETH
  receive() external payable {
    // If it is not from WETH, refund it back to sender
    if (msg.sender != _qAdmin.WETH()) {
      Utils.refundExcessiveETH(0);
    }
  }
  
  modifier onlyAdmin() {
    if (!_qAdmin.hasRole(_qAdmin.ADMIN_ROLE(), msg.sender)) {
      revert CustomErrors.FRM_OnlyAdmin();
    }
    _;
  }
  
  modifier onlyQToken() {
    if (address(_qToken) != msg.sender) {
      revert CustomErrors.FRM_OnlyQToken();
    }
    _;
  }
  
  modifier onlyQuoteManager() {
    if (address(_quoteManager) != msg.sender) {
      revert CustomErrors.FRM_OnlyQuoteManager();
    }
    _;
  }

  /// @notice Modifier which checks that contract and specified operation is not paused
  modifier whenNotPaused(uint operationId) {
    if (_qAdmin.isPaused(address(this), operationId)) {
      revert CustomErrors.FRM_OperationPaused(operationId);
    }
    _;
  }
  
  /// @notice Logic copied from `@openzeppelin/contracts/security/ReentrancyGuard.sol`
  /// Reconstruct here instead of inheritance is to avoid storage slot sequence problem during
  /// contract upgrade
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    if (_status == _ENTERED) {
      revert CustomErrors.FRM_ReentrancyDetected();
    }

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  
  /** ADMIN FUNCTIONS **/
  
  // Temporal function to fix existing markets
  function _setName(string calldata name_) external onlyAdmin {
    _name = name_;
  }
  
  // Temporal function to fix existing markets
  function _setSymbol(string calldata symbol_) external onlyAdmin {
    _symbol = symbol_;
  }
  
  /// @notice Call upon initialization after deploying `QuoteManager` contract
  /// @param quoteManagerAddress Address of `QuoteManager` deployment
  function _setQuoteManager(address quoteManagerAddress) external onlyAdmin {
    // Initialize the value
    _quoteManager = IQuoteManager(quoteManagerAddress);

    // Emit the event
    emit SetQuoteManager(quoteManagerAddress);
  }
  
  /// @notice Call upon initialization after deploying `QToken` contract
  /// @param qTokenAddress Address of `QToken` deployment
  function _setQToken(address qTokenAddress) external onlyAdmin {
    // Initialize the value
    _qToken = IQToken(qTokenAddress);

    // Emit the event
    emit SetQToken(qTokenAddress);
  }
  
  /// @notice Function to be used by qToken contract to transfer native or underlying token to recipient
  /// Transfer operation is centralized in FixedRateMarket so token held does not need to be transferred
  /// to/from qToken contract.
  /// @param receiver Account of the receiver
  /// @param amount Size of the fund to be transferred from sender to receiver
  /// @param isSendingETH Indicate if sender is sending fund with ETH
  /// @param isReceivingETH Indicate if receiver is receiving fund with ETH
  function _transferTokenOrETH(
                               address receiver,
                               uint amount,
                               bool isSendingETH,
                               bool isReceivingETH
                               ) external onlyQToken {
    Utils.transferTokenOrETH(address(this), receiver, amount, _underlying, _qAdmin.WETH(), isSendingETH, isReceivingETH);
  }
  
  /// @notice Borrower will make repayments to the smart contract, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @param to Address of the receiver
  /// @param amount Amount to repay
  /// @return uint Remaining account borrow amount
  function _repayBorrowInQToken(address to, uint amount) external onlyQToken nonReentrant whenNotPaused(303) returns(uint) {
    return _repayBorrow(to, amount, false, true);
  }
  
  function _updateLiquidityEmissionsOnRedeem(uint8 side, uint64 id) external onlyQToken {
    return _updateLiquidityEmissions(side, id);
  }
  
  /// @notice Call upon quote creation
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of the `Quote`
  function _onCreateQuote(uint8 side, uint64 id) external onlyQuoteManager {
    _updateLiquidityEmissions(side, id);
  }
  
  /// @notice Call upon quote fill
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of the `Quote`
  function _onFillQuote(uint8 side, uint64 id) external onlyQuoteManager {
    _updateLiquidityEmissions(side, id);
  }
  
  /// @notice Call upon quote cancellation
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of the `Quote`
  function _onCancelQuote(uint8 side, uint64 id) external onlyQuoteManager {
    _updateLiquidityEmissions(side, id);
  }
  
  /** USER INTERFACE **/

  /// @notice Creates a new  `Quote` and adds it to the `OrderbookSide` linked list by side
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param APR In decimal form scaled by 1e4 (ex. 1052 = 10.52%)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  function createQuote(uint8 side, uint8 quoteType, uint64 APR, uint cashflow) external {
    _quoteManager.createQuote(side, msg.sender, quoteType, APR, cashflow);
  }
  
  /// @notice Analogue of market order to borrow against current lend `Quote`s.
  /// Only fills at most up to `amountPV`, any unfilled amount is discarded.
  /// @param amountPV The maximum amount to borrow
  /// @param maxAPR Only accept `Quote`s up to specified APR. You may think of
  /// this as a maximum slippage tolerance variable
  function borrow(uint amountPV, uint64 maxAPR) external nonReentrant whenNotPaused(301) {
    _execMarketOrder(_SIDE_LEND, msg.sender, amountPV, maxAPR, false);
  }
  
  /// @notice Analogue of market order to borrow against current lend `Quote`s.
  /// Only fills at most up to `amountPV`, any unfilled amount is discarded.
  /// ETH will be sent to borrower
  /// @param amountPV The maximum amount to borrow
  /// @param maxAPR Only accept `Quote`s up to specified APR. You may think of
  /// this as a maximum slippage tolerance variable
  function borrowETH(uint amountPV, uint64 maxAPR) external nonReentrant whenNotPaused(301) {
    if (address(_underlying) != _qAdmin.WETH()) {
      revert CustomErrors.FRM_EthOperationNotPermitted();
    }
    _execMarketOrder(_SIDE_LEND, msg.sender, amountPV, maxAPR, true);
  }

  /// @notice Analogue of market order to lend against current borrow `Quote`s.
  /// Only fills at most up to `amountPV`, any unfilled amount is discarded.
  /// @param amountPV The maximum amount to lend
  /// @param minAPR Only accept `Quote`s up to specified APR. You may think of
  /// this as a maximum slippage tolerance variable
  function lend(uint amountPV, uint64 minAPR) external nonReentrant whenNotPaused(302) {
    _execMarketOrder(_SIDE_BORROW, msg.sender, amountPV, minAPR, false);
  }
  
  /// @notice Analogue of market order to lend against current borrow `Quote`s.
  /// Only fills at most up to `msg.value`, any unfilled amount is discarded.
  /// Excessive amount will be sent back to lender
  /// Note that protocol fee should also be included as ETH sent in the function call
  /// @param minAPR Only accept `Quote`s up to specified APR. You may think of
  /// this as a maximum slippage tolerance variable
  function lendETH(uint64 minAPR) external payable nonReentrant whenNotPaused(302) {
    if (address(_underlying) != _qAdmin.WETH()) {
      revert CustomErrors.FRM_EthOperationNotPermitted();
    }
    
    // Deduce corresponding amountPV if protocol fee is not included 
    uint amountPV = hypotheticalMaxLendPV(msg.value);
    
    uint executedPV = _execMarketOrder(_SIDE_BORROW, msg.sender, amountPV, minAPR, true);

    Utils.refundExcessiveETH(executedPV + proratedProtocolFee(executedPV));
  }

  /// @notice Borrower will make repayments to the smart contract, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @param amount Amount to repay
  /// @return uint Remaining account borrow amount
  function repayBorrow(uint amount) external nonReentrant whenNotPaused(303) returns(uint) {
    return _repayBorrow(msg.sender, amount, false, false);
  }
  
  /// @notice Borrower will make repayments to the smart contract using ETH, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @return uint Remaining account borrow amount
  function repayBorrowWithETH() external payable nonReentrant whenNotPaused(303) returns(uint) {
    if (address(_underlying) != _qAdmin.WETH()) {
      revert CustomErrors.FRM_EthOperationNotPermitted();
    }
    uint balanceBefore = _accountBorrows[msg.sender];
    uint balanceAfter = _repayBorrow(msg.sender, msg.value, true, false);
    Utils.refundExcessiveETH(balanceBefore - balanceAfter);
    return balanceAfter;
  }
  
  /// @notice Cancel `Quote` by id. Note this is a O(1) operation
  /// since `OrderbookSide` uses hashmaps under the hood. However, it is
  /// O(n) against the array of `Quote` ids by account so we should ensure
  /// that array should not grow too large in practice.
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of the `Quote`
  function cancelQuote(uint8 side, uint64 id) external {
    _quoteManager.cancelQuote(true, side, msg.sender, id);
  }
  
  /// @notice If an account is in danger of being underwater (i.e. collateralRatio < 1.0)
  /// or has not repaid past maturity plus `_repaymentGracePeriod`, any user may
  /// liquidate that account by paying back the loan on behalf of the account. In return,
  /// the liquidator receives collateral belonging to the account equal in value to
  /// the repayment amount in USD plus the liquidation incentive amount as a bonus.
  /// @param borrower Address of account to liquidate
  /// @param amount Amount to repay on behalf of account in the currency of the loan
  /// @param collateralToken Liquidator's choice of which currency to be paid in
  function liquidateBorrow(address borrower, uint amount, IERC20 collateralToken) external nonReentrant whenNotPaused(305) {
    _liquidateBorrow(borrower, amount, collateralToken, false);
  }
  
  
  /** VIEW FUNCTIONS **/
  
  /// @notice Get the name of this contract
  /// @return address contract name
  function name() external view returns(string memory) {
    return _name;
  }
  
  /// @notice Get the symbol representing this contract
  /// @return address contract symbol
  function symbol() external view returns(string memory) {
    return _symbol;
  }

  /// @notice Get the address of the `QAdmin`
  /// @return address
  function qAdmin() external view returns(address) {
    return address(_qAdmin);
  }
  
  /// @notice Get the address of the `QollateralManager`
  /// @return address
  function qollateralManager() external view returns(address){
    return _qAdmin.qollateralManager();
  }
  
  /// @notice Get the address of the `QuoteManager`
  /// @return address
  function quoteManager() external view returns(address){
    return address(_quoteManager);
  }
  
  /// @notice Get the address of the `QToken`
  /// @return address
  function qToken() external view returns(address) {
    return address(_qToken);
  }

  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return IERC20
  function underlyingToken() external view returns(IERC20) {
    return _underlying;
  }
  
  /// @notice Get the UNIX timestamp (in seconds) when the market matures
  /// @return uint
  function maturity() external view returns(uint){
    return _maturity;
  }

  /// @notice Get the minimum quote size for this market
  /// @return uint Minimum quote size, in PV terms, local currency
  function minQuoteSize() external view returns(uint) {
    return _qAdmin.minQuoteSize(address(this));
  }

  /// @notice Get the total balance of borrows by user
  /// @param account Account to query
  /// @return uint Borrows
  function accountBorrows(address account) external view returns(uint){
    return _accountBorrows[account];
  }

  /// @notice Get the linked list pointer top of book for `Quote` by side
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return uint64 id of top of book `Quote` 
  function getQuoteHeadId(uint8 side) external view returns(uint64) {
    return _quoteManager.getQuoteHeadId(side);
  }

  /// @notice Get the top of book for `Quote` by side
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return QTypes.Quote head `Quote`
  function getQuoteHead(uint8 side) external view returns(QTypes.Quote memory) {
    return _quoteManager.getQuoteHead(side);
  }
  
  /// @notice Get the `Quote` for the given `side` and `id`
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of `Quote`
  /// @return QTypes.Quote `Quote` associated with the id
  function getQuote(uint8 side, uint64 id) external view returns(QTypes.Quote memory) {
    return _quoteManager.getQuote(side, id);
  }

  /// @notice Get all live `Quote` id's by `account` and `side`
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param account Account to query
  /// @return uint[] Unsorted array of borrow `Quote` id's
  function getAccountQuotes(uint8 side, address account) external view returns(uint64[] memory) {
    return _quoteManager.getAccountQuotes(side, account);
  }

  /// @notice Get the number of active `Quote`s by `side` in the orderbook
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return uint Number of `Quote`s
  function getNumQuotes(uint8 side) external view returns(uint) {
    return _quoteManager.getNumQuotes(side);
  }
    
  /// @notice Gets the `protocolFee` associated with this market
  /// @return uint annualized protocol fee, scaled by 1e4
  function protocolFee() public view returns(uint) {
    // If fee emissions qontroller is not defined, no protocol fee will be charged
    if (address(_qAdmin.feeEmissionsQontroller()) == address(0)) {
      return 0;
    }
    return _qAdmin.protocolFee(address(this));
  }

  /// @notice Gets the `protocolFee` associated with this market, prorated by time till maturity 
  /// @param amount loan amount
  /// @return uint prorated protocol fee in local currency
  function proratedProtocolFee(uint amount) public view returns(uint) {
    return proratedProtocolFee(amount, block.timestamp);
  }

  /// @notice Gets the `protocolFee` associated with this market, prorated by time till maturity 
  /// @param amount loan amount
  /// @param timestamp UNIX timestamp in seconds
  /// @return uint prorated protocol fee in local currency
  function proratedProtocolFee(uint amount, uint timestamp) public view returns(uint) {
    if (timestamp >= _maturity) {
      revert CustomErrors.FRM_MarketExpired();
    }
    return amount * protocolFee() * (_maturity - timestamp) / _qAdmin.MANTISSA_BPS() / ONE_YEAR_IN_SECONDS;
  }
  
  /// @notice Get total protocol fee accrued in this market so far, in local currency
  /// @return uint accrued fee
  function totalAccruedFees() external view returns(uint) {
    return _totalAccruedFees;
  }

  /// @notice Get the PV of a cashflow amount based on the `quoteType`
  /// @param quoteType 0 for PV, 1 for FV
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param sTime PV start time
  /// @param eTime FV end time
  /// @param amount Value to be PV'ed
  /// @return uint PV of the `amount`
  function getPV(
                 uint8 quoteType,
                 uint64 APR,
                 uint amount,
                 uint sTime,
                 uint eTime
                 ) public view returns(uint) {
    return _quoteManager.getPV(quoteType, APR, amount, sTime, eTime);
  }

  /// @notice Get the FV of a cashflow amount based on the `quoteType`
  /// @param quoteType 0 for PV, 1 for FV
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param sTime PV start time
  /// @param eTime FV end time
  /// @param amount Value to be FV'ed
  /// @return uint FV of the `amount`
  function getFV(
                 uint8 quoteType,
                 uint64 APR,
                 uint amount,
                 uint sTime,
                 uint eTime
                 ) public view returns(uint) {
    return _quoteManager.getFV(quoteType, APR, amount, sTime, eTime);    
  }
  
  /// @notice Get maximum value user can lend with given amount when protocol fee is factored in.
  /// Mantissa is added to reduce precision error during calculation
  /// @param amount Lending amount with protocol fee factored in
  /// @return uint Maximum value user can lend with protocol fee considered
  function hypotheticalMaxLendPV(uint amount) public view returns (uint) {
    // Round up denominator if it is not fully divisible
    uint num = amount * 1e18;
    uint denom = 1e18 + proratedProtocolFee(1e18);
    return num / (denom + Math.min(num % denom, 1)); 
  }
  
  
  /** INTERNAL FUNCTIONS **/

  /// @notice Called under the hood by external `borrow` and `lend` functions.
  /// This function loops through the opposite `OrderbookSide`, executing loans
  /// until either the full amount is filled, the `OrderbookSide` is empty, or
  /// no more `Quote`s exist that satisfy the `limitAPR` set by the market order.
  /// @param quoteSide 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param account Address of the `Acceptor`
  /// @param amountPV Amount that the `Acceptor` wants to execute, as PV
  /// @param limitAPR Only accept `Quote`s up to specified APR. You may think of
  /// this as a maximum slippage tolerance variable
  /// @param isPaidInETH Is amount being paid in ETH
  /// @return uint Total amount executed in PV terms
  function _execMarketOrder(
                            uint8 quoteSide,
                            address account,
                            uint amountPV,
                            uint64 limitAPR,
                            bool isPaidInETH
                            ) internal returns (uint) {

    // Store the initial requested `Acceptor` size - must be positive
    if (amountPV <= 0) {
      revert CustomErrors.FRM_AmountZero();
    }
    uint amountRemaining = amountPV;

    // Start `Quote`s from head
    QTypes.Quote memory currQuote = _quoteManager.getQuoteHead(quoteSide);

    uint totalExecutedPV = 0;
    uint totalExecutedFV = 0;
    
    while(amountRemaining > 0) {
      
      if((quoteSide == _SIDE_LEND && limitAPR < currQuote.APR) ||
         (quoteSide == _SIDE_BORROW && limitAPR > currQuote.APR)) {
        
        // Stop loop condition: `limitAPR` works as a limit price.
        // Since `Quote`s are ordered by APR, if the current `Quote` is past
        // the limit, we know all remaining `Quote`s will not satisfy the
        // `Acceptor`s conditions
        break;

      } else if(currQuote.id == _NULL_POINTER) {

        // Stop loop condition: No more `Quote`s remaining
        break;

      } else if(account == currQuote.quoter) {

        // Cannot execute `Quote` against self - just ignore it
        // Move to the next `Quote` in line
        currQuote = _quoteManager.getQuote(quoteSide, currQuote.next);

      } else if(!_quoteManager.isQuoteValid(quoteSide, currQuote)) {

        // Store the pointer to the next best `Quote`
        uint64 next = currQuote.next;

        // Clean up invalid `Quote`s. If the current `Quote` is not valid, it
        // will be cancelled automatically without notice to the creator of
        // the `Quote`
        _quoteManager.cancelQuote(false, quoteSide, currQuote.quoter, currQuote.id);

        // Move to the next `Quote` in line
        currQuote = _quoteManager.getQuote(quoteSide, next);        

      } else {

        // `Quote` is valid. Preprocess and then execute the loan
        (uint execAmountPV, uint execAmountFV) = _preprocessLoan(quoteSide, currQuote.id, account, amountRemaining, isPaidInETH);
        totalExecutedPV += execAmountPV;
        totalExecutedFV += execAmountFV;
        
        // Just in case of potential rounding errors, floor the new `amountRemaining` at zero
        if(amountRemaining > execAmountPV) {
          amountRemaining = amountRemaining - execAmountPV;
        } else {
          amountRemaining = 0;
        }

        // Move to the next `Quote` in line
        currQuote = _quoteManager.getQuote(quoteSide, currQuote.next);
      }      
    }
    if (totalExecutedPV > 0) {
      emit ExecMarketOrder(quoteSide, account, totalExecutedPV, totalExecutedFV);
    }
    return totalExecutedPV;
  }

  /// @notice Intermediary function that handles order/quote sides, PV/FV
  /// and actual executed amount calculations, and updates `Quote` fill status
  /// @param quoteSide 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param quoteId Id of the `Quote`
  /// @param acceptor Address of the `Acceptor`
  /// @param acceptorAmountPV Amount that the `Acceptor` wants to execute, as PV
  /// @param isPaidInETH Is amount being paid in ETH
  /// @return uint execAmountPV uint execAmountFV
  function _preprocessLoan(
                           uint8 quoteSide,
                           uint64 quoteId,
                           address acceptor,
                           uint acceptorAmountPV,
                           bool isPaidInETH
                           ) internal returns(uint,uint){

    // Get immutable instance of `Quote`
    QTypes.Quote memory quote = _quoteManager.getQuote(quoteSide, quoteId);
    
    uint execAmountPV;
    uint execAmountFV;
    if(quote.quoteType == 0){ // Quote is in PV terms

      // Executing Amount must be the smaller of the `Quoter` and `Acceptor` size
      execAmountPV = Math.min(acceptorAmountPV, quote.cashflow - quote.filled);

      // Get the equivalent executed amount in PV terms
      execAmountFV = Interest.PVToFV(
                                     quote.APR,
                                     execAmountPV,
                                     block.timestamp,
                                     _maturity,
                                     _qAdmin.MANTISSA_BPS()
                                     );

      // Update the filled amount for the `Quote`
      quote.filled += execAmountPV;
      _quoteManager.fillQuote(quoteSide, quoteId, execAmountPV);
      
    }else { // Quote is in FV terms
      
      // Get the equivalent FV amount of Acceptor's original amount
      uint acceptorAmountFV = Interest.PVToFV(
                                              quote.APR,
                                              acceptorAmountPV,
                                              block.timestamp,
                                              _maturity,
                                              _qAdmin.MANTISSA_BPS()
                                              );      

      // Executing Amount must be the smaller of the `Quoter` and `Acceptor` size
      execAmountFV = Math.min(acceptorAmountFV, quote.cashflow - quote.filled);

      // Get the equivalent executed amount in PV terms
      execAmountPV = Interest.FVToPV(
                                     quote.APR,
                                     execAmountFV,
                                     block.timestamp,
                                     _maturity,
                                     _qAdmin.MANTISSA_BPS()
                                     );

      // Update the filled amount for the `Quote`
      quote.filled += execAmountFV;
      _quoteManager.fillQuote(quoteSide, quoteId, execAmountFV);
      
    }

    address quoter = quote.quoter;
    uint64 apr = quote.APR;
    if (quote.cashflow - quote.filled < _DUST) {
      // If `Quote` is fully filled (minus dust), remove it from the `OrderbookSide`
      _quoteManager.cancelQuote(false, quoteSide, quote.quoter, quote.id);
    }
    
    // Create the loan, taking care to differentiate whether the `Quoter` is the
    // lender and `Acceptor` is the borrower, or vice versa
    if (quoteSide == _SIDE_BORROW) {
      return _createFixedRateLoan(quoteSide, quoter, acceptor, execAmountPV, execAmountFV, proratedProtocolFee(execAmountPV), apr, isPaidInETH);
    } 
    if (quoteSide == _SIDE_LEND) {
      return _createFixedRateLoan(quoteSide, acceptor, quoter, execAmountPV, execAmountFV, proratedProtocolFee(execAmountPV), apr, isPaidInETH);
    } 
    revert CustomErrors.FRM_InvalidSide();
  }

  /// @notice Mint the future `qToken`s to the lender, add `amountFV` to the
  /// borrower's debts, transfer `amountPV` from lender to borrower, and accrue
  /// `protocolFee`s to the `FeeEmissionsQontroller`
  /// @param quoteSide 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param borrower Account of the borrower
  /// @param lender Account of the lender
  /// @param amountPV Size of the initial loan paid by lender
  /// @param amountFV Final amount that must be paid by borrower
  /// @param protocolFee_ Protocol fee to be paid by both lender and borrower in the transaction
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param isPaidInETH Is amount being paid in ETH
  /// @return uint execAmountPV uint execAmountFV
  function _createFixedRateLoan(
                                uint8 quoteSide,
                                address borrower,
                                address lender,
                                uint amountPV,
                                uint amountFV,
                                uint protocolFee_,
                                uint64 APR,
                                bool isPaidInETH
                                ) internal returns(uint, uint){

    // Loan amount must be strictly positive
    if (amountPV <= 0) {
      revert CustomErrors.FRM_AmountZero();
    }

    // Interest rate needs to be positive
    if (amountPV >= amountFV) {
      revert CustomErrors.FRM_InvalidAPR();
    }

    // AmountPV should be able to cover protocolFee cost
    if (amountPV <= protocolFee_) {
      revert CustomErrors.FRM_AmountLessThanProtocolFee();
    }

    // Cannot execute loan against self
    if (lender == borrower) {
      revert CustomErrors.FRM_InvalidCounterparty();
    }

    // Cannot create a loan past its maturity time
    if (block.timestamp >= _maturity) {
      revert CustomErrors.FRM_InvalidMaturity();
    }

    // If contract is to act on behalf of lender, assume upstream has handled related fund transfer to the contract.
    // So no fund availability check is needed here.
    if (quoteSide != _SIDE_BORROW || !isPaidInETH) {
      // Check lender has approved contract spend
      if (_underlying.allowance(lender, address(this)) < amountPV + protocolFee_) {
        revert CustomErrors.FRM_InsufficientAllowance();
      }
  
      // Check lender has enough balance
      if (_underlying.balanceOf(lender) < amountPV + protocolFee_) {
        revert CustomErrors.FRM_InsufficientBalance();
      }
    }

    // Check if borrowing amount is above max borrow and update market participated  
    _checkRatioAndAddParticipatedMarket(borrower, lender, amountFV);
    
    // The borrow amount of the borrower increases by the full `amountFV`
    _accountBorrows[borrower] += amountFV;
    
    // Net off borrow amount with any balance of qTokens the borrower may have
    _repayBorrow(borrower, _qToken.balanceOf(borrower), false, true);

    // Transfer `amountPV` from lender to borrower, and protocolFee from both
    // lender and borrower to `FeeEmissionsQontroller`.
    // Note that lender will pay `protocolFee_` from their account balance,
    // while borrower will pay `protocolFee_` from their borrowed amount. So
    // total amount involved in transfer = amountPV + protocolFee_
    // Also note that if it is WETH market and borrower intends to receive ETH,
    // contract will receive on behalf and do token unwrapping outside this function
    IFeeEmissionsQontroller feq = IFeeEmissionsQontroller(_qAdmin.feeEmissionsQontroller());
    bool lenderInitiate = quoteSide == _SIDE_BORROW;
    if (address(feq) == address(0)) {
      Utils.transferTokenOrETH(lender, borrower, amountPV, _underlying, _qAdmin.WETH(), isPaidInETH && lenderInitiate, isPaidInETH && !lenderInitiate);
    } else {
      // No token unwrapping is need for FeeEmissionsQontroller as target recipient
      Utils.transferTokenOrETH(lender, address(feq), protocolFee_ * 2, _underlying, _qAdmin.WETH(), isPaidInETH && lenderInitiate, false);
      Utils.transferTokenOrETH(lender, borrower, amountPV - protocolFee_, _underlying, _qAdmin.WETH(), isPaidInETH && lenderInitiate, isPaidInETH && !lenderInitiate);

      _totalAccruedFees += protocolFee_ * 2;
      feq.receiveFees(_underlying, protocolFee_ * 2);
    }

    // Lender receives `amountFV` amount in qTokens
    // Put this last to protect against reentracy
    _qToken.mint(lender, amountFV);
    
    // Net off the minted amount with any borrow amounts the lender may have
    _repayBorrow(lender, _qToken.balanceOf(lender), false, true);

    // Finally, report trading volumes for trading rewards
    _updateTradingRewards(borrower, lender, amountPV);

    // Emit the matched borrower and lender and fixed rate loan terms
    emit FixedRateLoan(quoteSide, borrower, lender, amountPV, amountFV, protocolFee_, APR);

    return (amountPV, amountFV);
  }
  
  /// @notice Check if borrowing amount is breaching maximum allow amount borrow,
  /// which is determined by initCollateralRatio and creditLimit.
  /// Note `_initCollateralRatio` is a larger value than `_minCollateralRatio`. 
  /// This protects users from taking loans at the minimum threshold, 
  /// putting them at risk of instant liquidation.
  /// @param borrower Account of the borrower
  /// @param lender Account of the lender
  /// @param amountFV Final amount that must be paid by borrower
  function _checkRatioAndAddParticipatedMarket(address borrower, address lender, uint amountFV) internal {
    IQollateralManager qm = IQollateralManager(_qAdmin.qollateralManager());
    IFixedRateMarket currentMarket = IFixedRateMarket(address(this));
    uint maxBorrowFV = qm.hypotheticalMaxBorrowFV(borrower, currentMarket);
    if (amountFV > maxBorrowFV) {
      revert CustomErrors.FRM_MaxBorrowExceeded();
    }

    // Record that the lender/borrow have participated in this market
    if(!qm.accountMarkets(lender, currentMarket)){
      qm._addAccountMarket(lender, currentMarket);
    }
    if(!qm.accountMarkets(borrower, currentMarket)){
      qm._addAccountMarket(borrower, currentMarket);
    }
  }
  
  /// @notice Borrower will make repayments to the smart contract, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @param amount Amount to repay
  /// @param isPaidInETH Is amount being paid in ETH
  /// @param isPaidInQTokens Is amount being paid with qTokens
  /// @return uint Remaining account borrow amount
  function _repayBorrow(address account, uint amount, bool isPaidInETH, bool isPaidInQTokens) internal returns(uint){

    // Don't allow users to pay more than necessary
    amount = Math.min(amount, _accountBorrows[account]);
    
    if (isPaidInQTokens) {
      if(amount == 0) {      
        // Short-circuit: If user has no qTokens, no need to do anything
        return _accountBorrows[account];
      }
      
      // Burn the qTokens from the account and subtract the amount for the user's borrows
      _qToken.burn(account, amount);
    } else {
      // Repayment amount must be positive
      if (amount <= 0) {
        revert CustomErrors.FRM_AmountZero();
      }
      
      // Transfer amount from borrower to contract for escrow until maturity
      uint balanceBefore = _underlying.balanceOf(address(this));
      Utils.transferTokenOrETH(account, address(this), amount, _underlying, _qAdmin.WETH(), isPaidInETH, false);
      amount = _underlying.balanceOf(address(this)) - balanceBefore;
    }

    // Deduct from the account's total debts
    // Guaranteed not to underflow due to the flooring on amount above
    _accountBorrows[account] -= amount;
    
    // Emit the event
    emit RepayBorrow(account, amount, isPaidInQTokens);

    return _accountBorrows[account];
  }
  
  /// @notice If an account is in danger of being underwater (i.e. collateralRatio < 1.0)
  /// or has not repaid past maturity plus `_repaymentGracePeriod`, any user may
  /// liquidate that account by paying back the loan on behalf of the account. In return,
  /// the liquidator receives collateral belonging to the account equal in value to
  /// the repayment amount in USD plus the liquidation incentive amount as a bonus.
  /// @param borrower Address of account to liquidate
  /// @param amount Amount to repay on behalf of account in the currency of the loan
  /// @param collateralToken Liquidator's choice of which currency to be paid in
  /// @param isPaidInETH Is amount being paid in ETH
  /// @return uint Amount transferred for liquidation
  function _liquidateBorrow(address borrower, uint amount, IERC20 collateralToken, bool isPaidInETH) internal returns(uint) {

    IQollateralManager qm = IQollateralManager(_qAdmin.qollateralManager());
    uint repaymentGracePeriod = _qAdmin.repaymentGracePeriod();

    // Ensure borrower is either underwater or past payment due date.
    // These are the necessary conditions before borrower can be liquidated.
    if (qm.collateralRatio(borrower) >= _qAdmin.minCollateralRatio(borrower) &&
        block.timestamp <= _maturity + repaymentGracePeriod) {
      revert CustomErrors.FRM_NotLiquidatable();
    }
    
    // For borrowers that are underwater, liquidator can only repay up
    // to a percentage of the full loan balance determined by the `closeFactor`
    uint closeFactor = qm.closeFactor();
    
    // For borrowers that are past due date, ignore the close factor - liquidator
    // can liquidate the entire sum
    if(block.timestamp > _maturity){
      closeFactor = _qAdmin.MANTISSA_FACTORS();
    }

    // Liquidator cannot repay more than the percentage of the full loan balance
    // determined by `closeFactor`
    uint maxRepayment = _accountBorrows[borrower] * closeFactor / _qAdmin.MANTISSA_FACTORS();
    amount = Math.min(amount, maxRepayment);

    // Amount must be positive
    if (amount <= 0) {
      revert CustomErrors.FRM_AmountZero();
    }

    // Get USD value of amount paid
    uint amountUSD = qm.localToUSD(_underlying, amount);

    // Get USD value of amount plus liquidity incentive
    uint rewardUSD = amountUSD * _qAdmin.liquidationIncentive() / _qAdmin.MANTISSA_FACTORS();

    // Get the local amount of collateral to reward liquidator
    uint rewardLocal = qm.USDToLocal(collateralToken, rewardUSD);

    // Ensure the borrower has enough collateral balance to pay the liquidator
    if (rewardLocal > qm.collateralBalance(borrower, collateralToken)) {
      revert CustomErrors.FRM_NotEnoughCollateral();
    }

    // Liquidator repays the loan on behalf of borrower
    Utils.transferTokenOrETH(msg.sender, address(this), amount, _underlying, _qAdmin.WETH(), isPaidInETH, false);

    // Credit the borrower's account
    _accountBorrows[borrower] -= amount;

    // Emit the event
    emit LiquidateBorrow(borrower, msg.sender, amount, address(collateralToken), rewardLocal);

    // Transfer the collateral balance from borrower to the liquidator
    qm._transferCollateral(collateralToken, borrower, msg.sender, rewardLocal);
    
    // Return amount transferred for liquidation
    return amount;
  }
  
  /// @notice Tracks the amount traded, its associated protocol fees, normalize
  /// to USD, and reports the data to `TradingEmissionsQontroller` which handles
  /// disbursing token rewards for trading volumes
  /// @param borrower Address of the borrower
  /// @param lender Address of the lender
  /// @param amountPV Amount traded (in local currency, in PV terms)
  function _updateTradingRewards(address borrower, address lender, uint amountPV) internal {
    // Instantiate interfaces
    ITradingEmissionsQontroller teq = ITradingEmissionsQontroller(_qAdmin.tradingEmissionsQontroller());
    
    if (address(teq) != address(0)) {
      
      IQPriceOracle oracle = IQPriceOracle(_qAdmin.qPriceOracle());

      // Get the associated protocol fees generated by the amount
      uint feeLocal = proratedProtocolFee(amountPV);
    
      // Convert the fee to USD
      uint feeUSD = oracle.localToUSD(_underlying, feeLocal);
        
      // report volumes to `TradingEmissionsQontroller`
      teq.updateRewards(borrower, lender, feeUSD);
    }
  }
  
  function _updateLiquidityEmissions(uint8 side, uint64 id) internal {
    address liquidityEmissionsAddress = _qAdmin.liquidityEmissionsQontroller();
    if (liquidityEmissionsAddress != address(0)) {
      ILiquidityEmissionsQontroller qontroller = ILiquidityEmissionsQontroller(liquidityEmissionsAddress);
      uint lastDistributeTime = qontroller.lastDistributeTime(address(this), side);
      if (lastDistributeTime > 0 && lastDistributeTime < _maturity) {
        qontroller.updateRewards(this, side, id);
      }
    }
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeeEmissionsQontroller {

  /// @notice Emitted when user claims emissions
  event ClaimEmissions(address indexed account, uint amount);

  /// @notice Emitted when fee is accrued in a round
  event FeesAccrued(uint indexed round, address token, uint amount, uint amountInRound);

  /// @notice Emitted when we move to a new round
  event NewFeeEmissionsRound(uint indexed currentPeriod, uint startTime, uint endTime);

  /** ACCESS CONTROLLED FUNCTIONS **/

  function receiveFees(IERC20 underlyingToken, uint feeLocal) external;

  function veIncrease(address account, uint veIncreased) external;

  function veReset(address account) external;

  /** USER INTERFACE **/

  function claimEmissions() external;

  function claimEmissions(address account) external;


  /** VIEW FUNCTIONS **/
  
  function claimableEmissions() external view returns (uint);
  
  function claimableEmissions(address account) external view returns (uint);
  
  function expectedClaimableEmissions() external view returns (uint);
  
  function expectedClaimableEmissions(address account) external view returns (uint);

  function qAdmin() external view returns (address);

  function veToken() external view returns (address);

  function swapContract() external view returns (address);

  function WETH() external view returns (IERC20);

  function emissionsRound() external view returns (uint, uint, uint);
  
  function emissionsRound(uint round_) external view returns (uint, uint, uint);

  function timeTillRoundEnd() external view returns (uint);

  function stakedVeAtRound(address account, uint round) external view returns (uint);

  function roundInterval() external view returns (uint);

  function currentRound() external view returns (uint);

  function lastClaimedRound() external view returns (uint);

  function lastClaimedRound(address account) external view returns (uint);

  function lastClaimedVeBalance() external view returns (uint);

  function lastClaimedVeBalance(address account) external view returns (uint);
  
  function claimedEmissions() external view returns (uint);
    
  function claimedEmissions(address account) external view returns (uint);

  function totalFeesAccrued() external view returns (uint);

  function totalFeesClaimed() external view returns (uint);

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/QTypes.sol";

interface IFixedRateMarket {
  
  /// @notice Emitted when market order is created and loan can be created with one or more quotes
  event ExecMarketOrder(
                        uint8 indexed quoteSide,
                        address indexed account,
                        uint totalExecutedPV,
                        uint totalExecutedFV
                        );
  
  /// @notice Emitted when a borrower repays borrow.
  /// Boolean flag `withQTokens`= true if repaid via qTokens, false otherwise.
  event RepayBorrow(address indexed borrower, uint amount, bool withQTokens);
  
  /// @notice Emitted when a borrower is liquidated
  event LiquidateBorrow(
                        address indexed borrower,
                        address indexed liquidator,
                        uint amount,
                        address collateralTokenAddr,
                        uint reward
                        );
  
  /// @notice Emitted when a borrower and lender are matched for a fixed rate loan
  event FixedRateLoan(
                      uint8 indexed quoteSide,
                      address indexed borrower,
                      address indexed lender,
                      uint amountPV,
                      uint amountFV,
                      uint feeIncurred,
                      uint64 APR
                      );
    
  /// @notice Emitted when setting `_quoteManager`
  event SetQuoteManager(address quoteManagerAddress);
  
  /// @notice Emitted when setting `_qToken`
  event SetQToken(address qTokenAddress);

  /** ADMIN FUNCTIONS **/
  
  /// @notice Call upon initialization after deploying `QuoteManager` contract
  /// @param quoteManagerAddress Address of `QuoteManager` deployment
  function _setQuoteManager(address quoteManagerAddress) external;
    
  /// @notice Call upon initialization after deploying `QToken` contract
  /// @param qTokenAddress Address of `QToken` deployment
  function _setQToken(address qTokenAddress) external;
  
  /// @notice Function to be used by qToken contract to transfer native or underlying token to recipient
  /// Transfer operation is centralized in FixedRateMarket so token held does not need to be transferred
  /// to/from qToken contract.
  /// @param receiver Account of the receiver
  /// @param amount Size of the fund to be transferred from sender to receiver
  /// @param isSendingETH Indicate if sender is sending fund with ETH
  /// @param isReceivingETH Indicate if receiver is receiving fund with ETH
  function _transferTokenOrETH(
                               address receiver,
                               uint amount,
                               bool isSendingETH,
                               bool isReceivingETH
                               ) external;
  
  /// @notice Borrower will make repayments to the smart contract, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @param to Address of the receiver
  /// @param amount Amount to repay
  /// @return uint Remaining account borrow amount
  function _repayBorrowInQToken(address to, uint amount) external returns(uint);
  
  function _updateLiquidityEmissionsOnRedeem(uint8 side, uint64 id) external;
  
  /// @notice Call upon quote creation
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of the `Quote`
  function _onCreateQuote(uint8 side, uint64 id) external;
    
  /// @notice Call upon quote fill
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of the `Quote`
  function _onFillQuote(uint8 side, uint64 id) external;
    
  /// @notice Call upon quote cancellation
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of the `Quote`
  function _onCancelQuote(uint8 side, uint64 id) external;
  
  /** USER INTERFACE **/
  
  /// @notice Creates a new  `Quote` and adds it to the `OrderbookSide` linked list by side
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param APR In decimal form scaled by 1e4 (ex. 1052 = 10.52%)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  function createQuote(uint8 side, uint8 quoteType, uint64 APR, uint cashflow) external;
  
  /// @notice Analogue of market order to borrow against current lend `Quote`s.
  /// Only fills at most up to `amountPV`, any unfilled amount is discarded.
  /// @param amountPV The maximum amount to borrow
  /// @param maxAPR Only accept `Quote`s up to specified APR. You may think of
  /// this as a maximum slippage tolerance variable
  function borrow(uint amountPV, uint64 maxAPR) external;
    
  /// @notice Analogue of market order to borrow against current lend `Quote`s.
  /// Only fills at most up to `amountPV`, any unfilled amount is discarded.
  /// ETH will be sent to borrower
  /// @param amountPV The maximum amount to borrow
  /// @param maxAPR Only accept `Quote`s up to specified APR. You may think of
  /// this as a maximum slippage tolerance variable
  function borrowETH(uint amountPV, uint64 maxAPR) external;

  /// @notice Analogue of market order to lend against current borrow `Quote`s.
  /// Only fills at most up to `amountPV`, any unfilled amount is discarded.
  /// @param amountPV The maximum amount to lend
  /// @param minAPR Only accept `Quote`s up to specified APR. You may think of
  /// this as a maximum slippage tolerance variable
  function lend(uint amountPV, uint64 minAPR) external;
    
  /// @notice Analogue of market order to lend against current borrow `Quote`s.
  /// Only fills at most up to `msg.value`, any unfilled amount is discarded.
  /// Excessive amount will be sent back to lender
  /// Note that protocol fee should also be included as ETH sent in the function call
  /// @param minAPR Only accept `Quote`s up to specified APR. You may think of
  /// this as a maximum slippage tolerance variable
  function lendETH(uint64 minAPR) external payable;

  /// @notice Borrower will make repayments to the smart contract, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @param amount Amount to repay
  /// @return uint Remaining account borrow amount
  function repayBorrow(uint amount) external returns(uint);
  
  /// @notice Borrower will make repayments to the smart contract using ETH, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @return uint Remaining account borrow amount
  function repayBorrowWithETH() external payable returns(uint);
  
  /// @notice Cancel `Quote` by id. Note this is a O(1) operation
  /// since `OrderbookSide` uses hashmaps under the hood. However, it is
  /// O(n) against the array of `Quote` ids by account so we should ensure
  /// that array should not grow too large in practice.
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of the `Quote`
  function cancelQuote(uint8 side, uint64 id) external;

  /// @notice If an account is in danger of being underwater (i.e. collateralRatio < 1.0)
  /// or has not repaid past maturity plus `_repaymentGracePeriod`, any user may
  /// liquidate that account by paying back the loan on behalf of the account. In return,
  /// the liquidator receives collateral belonging to the account equal in value to
  /// the repayment amount in USD plus the liquidation incentive amount as a bonus.
  /// @param borrower Address of account to liquidate
  /// @param amount Amount to repay on behalf of account in the currency of the loan
  /// @param collateralToken Liquidator's choice of which currency to be paid in
  function liquidateBorrow(address borrower, uint amount, IERC20 collateralToken) external;
    
  /** VIEW FUNCTIONS **/
  
  /// @notice Get the name of this contract
  /// @return address contract name
  function name() external view returns(string memory);
  
  /// @notice Get the symbol representing this contract
  /// @return address contract symbol
  function symbol() external view returns(string memory);

  /// @notice Get the address of the `QAdmin`
  /// @return address
  function qAdmin() external view returns(address);
  
  /// @notice Get the address of the `QollateralManager`
  /// @return address
  function qollateralManager() external view returns(address);
    
  /// @notice Get the address of the `QuoteManager`
  /// @return address
  function quoteManager() external view returns(address);
  
  /// @notice Get the address of the `QToken`
  /// @return address
  function qToken() external view returns(address);

  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return IERC20
  function underlyingToken() external view returns(IERC20);

  /// @notice Get the UNIX timestamp (in seconds) when the market matures
  /// @return uint
  function maturity() external view returns(uint);

  /// @notice Get the minimum quote size for this market
  /// @return uint Minimum quote size, in PV terms, local currency
  function minQuoteSize() external view returns(uint);

  /// @notice Get the total balance of borrows by user
  /// @param account Account to query
  /// @return uint Borrows
  function accountBorrows(address account) external view returns(uint);

  /// @notice Get the linked list pointer top of book for `Quote` by side
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return uint64 id of top of book `Quote` 
  function getQuoteHeadId(uint8 side) external view returns(uint64);

  /// @notice Get the top of book for `Quote` by side
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return QTypes.Quote head `Quote`
  function getQuoteHead(uint8 side) external view returns(QTypes.Quote memory);
  
  /// @notice Get the `Quote` for the given `side` and `id`
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of `Quote`
  /// @return QTypes.Quote `Quote` associated with the id
  function getQuote(uint8 side, uint64 id) external view returns(QTypes.Quote memory);

  /// @notice Get all live `Quote` id's by `account` and `side`
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param account Account to query
  /// @return uint[] Unsorted array of borrow `Quote` id's
  function getAccountQuotes(uint8 side, address account) external view returns(uint64[] memory);

  /// @notice Get the number of active `Quote`s by `side` in the orderbook
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return uint Number of `Quote`s
  function getNumQuotes(uint8 side) external view returns(uint);
    
  /// @notice Gets the `protocolFee` associated with this market
  /// @return uint annualized protocol fee, scaled by 1e4
  function protocolFee() external view returns(uint);

  /// @notice Gets the `protocolFee` associated with this market, prorated by time till maturity 
  /// @param amount loan amount
  /// @return uint prorated protocol fee in local currency
  function proratedProtocolFee(uint amount) external view returns(uint);
  
  /// @notice Gets the `protocolFee` associated with this market, prorated by time till maturity 
  /// @param amount loan amount
  /// @param timestamp UNIX timestamp in seconds
  /// @return uint prorated protocol fee in local currency
  function proratedProtocolFee(uint amount, uint timestamp) external view returns(uint);

  /// @notice Get total protocol fee accrued in this market so far, in local currency
  /// @return uint accrued fee
  function totalAccruedFees() external view returns(uint);

  /// @notice Get the PV of a cashflow amount based on the `quoteType`
  /// @param quoteType 0 for PV, 1 for FV
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param sTime PV start time
  /// @param eTime FV end time
  /// @param amount Value to be PV'ed
  /// @return uint PV of the `amount`
  function getPV(
                 uint8 quoteType,
                 uint64 APR,
                 uint amount,
                 uint sTime,
                 uint eTime
                 ) external view returns(uint);

  /// @notice Get the FV of a cashflow amount based on the `quoteType`
  /// @param quoteType 0 for PV, 1 for FV
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param sTime PV start time
  /// @param eTime FV end time
  /// @param amount Value to be FV'ed
  /// @return uint FV of the `amount`
  function getFV(
                 uint8 quoteType,
                 uint64 APR,
                 uint amount,
                 uint sTime,
                 uint eTime
                 ) external view returns(uint);

  /// @notice Get maximum value user can lend with given amount when protocol fee is factored in.
  /// Mantissa is added to reduce precision error during calculation
  /// @param amount Lending amount with protocol fee factored in
  /// @return uint Maximum value user can lend with protocol fee considered
  function hypotheticalMaxLendPV(uint amount) external view returns (uint);
  
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

import "./IFixedRateMarket.sol";
import "../libraries/QTypes.sol";

interface ILiquidityEmissionsQontroller {
  /** EVENTS **/
  
  /// @notice Emitted when user claims emissions
  event ClaimEmissions(address indexed account, uint emission);
  
  /** ACCESS CONTROLLED FUNCTIONS **/
  
  /// @notice Distribute cumulated reward to the top-of-book
  /// Function will be invoked whenever quotes within a market is updated, which happens when:
  /// - New quote is created
  /// - Existing quote gets filled
  /// - Existing quote gets cancelled
  /// - Market expiry is reached
  /// @param market `FixedRateMarket` contract where quote update happens
  /// @param side Order book side for reward to be distributed. 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param currQuoteId Id of the newly created quote
  function updateRewards(IFixedRateMarket market, uint8 side, uint64 currQuoteId) external;
  
  /// @notice Function to set number of token to distribute per second for given market
  /// @param market `FixedRateMarket` contract
  /// @param rewardPerSec_ Number of token to distribute per second, scaled to decimal of the token
  function _setRewardPerSec(address market, uint rewardPerSec_) external;
  
  /// @notice Function to set all detail related for given market, can only be invoked once.
  /// Note that reward token should be approved on sender side before this function is invoked.
  /// @param market `FixedRateMarket` contract
  /// @param rewardTokenAddress Address of reward token to distribute
  /// @param rewardPerSec_ Number of token to distribute per second, scaled to decimal of the token
  /// @param allocation Maximum reward given market can distribute to user, scaled to decimal of the token
  function _setMarketInfo(address market, address rewardTokenAddress, uint rewardPerSec_, uint allocation) external;
  
  /// @notice Function to start reward distribution for given market, can only be invoked once.
  /// @param startSec start time in second for reward distribution, 0 for current time
  function _startDistribution(address market, uint startSec) external;
  
  /// @notice Withdraw the specified amount if possible.
  /// @param rewardTokenAddress Address of reward token to withdraw
  /// @param amount the amount to withdraw
  function _withdraw(address rewardTokenAddress, uint amount) external;
  
  /** USER INTERFACE **/
  
  /// @notice Distribute cumulated reward to the top-of-book for specified market and side
  /// Unless forcing reward emission in given market is needed (e.g. user is top-of-book but there 
  /// is no market activity), user can simply rely on market contract to manage reward distribution
  /// @param market `FixedRateMarket` contract where quote update happens
  /// @param side Order book side for reward to be distributed. 0 for borrow `Quote`, 1 for lend `Quote`
  function updateRewards(IFixedRateMarket market, uint8 side) external;
  
  /// @notice Mint unclaimed rewards to user and reset their claimable emissions
  function claimEmissions() external;
  
  /// @notice Mint unclaimed rewards to specified account and reset their claimable emissions
  /// @param account Address of the user
  function claimEmissions(address account) external;
  
  /// @notice Do top-of-book calculation for given market before transferring unclaimed reward to specified account and resetting
  /// @param account Address of the user
  /// @param market `FixedRateMarket` contract where quote update happens
  function claimEmissionsWithRewardUpdate(address account, IFixedRateMarket market) external;
  
  /** VIEW FUNCTIONS **/
    
  /// @notice Check if given account is top-of-book of specified side of the market
  /// Note that function assumes quotes in each market is ordered by best APR first, 
  /// followed by quote creation sequence in case of ties
  /// @param market `FixedRateMarket` contract for top-of-book check
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param account Address of the user
  /// @return bool true if account is currently top-of-book of specified side of the market
  function isTopOfBook(IFixedRateMarket market, uint8 side, address account) external view returns(bool);
  
  /// @notice Check if given account is top-of-book of specified side of the market,
  /// starting with given quote id
  /// Note that function assumes quotes in each market is ordered by best APR first, 
  /// followed by quote creation sequence in case of ties
  /// @param market `FixedRateMarket` contract for top-of-book check
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param account Address of the user
  /// @param startQuoteId Quote id to start top-of-book check
  /// @return bool true if account is currently top-of-book of specified side of the market
  function isTopOfBook(IFixedRateMarket market, uint8 side, address account, uint64 startQuoteId) external view returns(bool);
  
  /// @notice Get top-of-book quote of specified side of the market
  /// @param market `FixedRateMarket` contract for top-of-book check
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return QTypes.Quote top-of-book quote for specified side of the market
  function getQuoteEligibleForReward(IFixedRateMarket market, uint8 side) external view returns (QTypes.Quote memory);
  
  /// @notice Get top-of-book quote of specified side of the market,
  /// starting with given quote id
  /// @param market `FixedRateMarket` contract for top-of-book check
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return QTypes.Quote top-of-book quote for specified side of the market
  function getQuoteEligibleForReward(IFixedRateMarket market, uint8 side, uint64 startQuoteId) external view returns (QTypes.Quote memory);
  
  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address);

  /// @notice Get the address of the reward token to distribute
  /// @param marketAddress `FixedRateMarket` contract address
  /// @return address Address of the reward token to distribute
  function rewardToken(address marketAddress) external view returns(address);
  
  /// @notice Get reward pending to claim for specified account
  /// @param account Account to query
  /// @param rewardTokenAddress Address of reward token to distribute
  /// @return uint reward pending to claim for specified account, scaled to decimal of the token
  function pendingReward(address account, address rewardTokenAddress) external view returns(uint);
  
  /// @notice Get amount per second to grant top-of-book quoter with given market
  /// @param marketAddress `FixedRateMarket` contract address
  /// @return Reward per second, scaled to decimal of the token
  function rewardPerSec(address marketAddress) external view returns(uint);
  
  /// @notice Get last reward distribution time for given market and side
  /// @param marketAddress `FixedRateMarket` contract address
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return Last reward distribution time, measured in second
  function lastDistributeTime(address marketAddress, uint8 side) external view returns(uint);
  
  /// @notice Get total allocated token balance for given market
  /// @param marketAddress `FixedRateMarket` contract address
  /// @return Total allocated token balance for given market, scaled to decimal of the token
  function totalAllocation(address marketAddress) external view returns(uint);
  
  /// @notice Get remaining allocated token balance for given market
  /// @param marketAddress `FixedRateMarket` contract address
  /// @return Remaining allocated token balance for given market, scaled to decimal of the token
  function remainingAllocation(address marketAddress) external view returns(uint);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFixedRateMarket.sol";

interface IQollateralManager {

  /// @notice Emitted when an account deposits collateral into the contract
  event DepositCollateral(address indexed account, address tokenAddress, uint amount);

  /// @notice Emitted when an account withdraws collateral from the contract
  event WithdrawCollateral(address indexed account, address tokenAddress, uint amount);
  
  /// @notice Emitted when an account first interacts with the `Market`
  event AddAccountMarket(address indexed account, address indexed market);

  /// @notice Emitted when collateral is transferred from one account to another
  event TransferCollateral(address indexed tokenAddress, address indexed from, address indexed to, uint amount);
  
  /// @notice Constructor for upgradeable contracts
  /// @param qAdminAddress_ Address of the `QAdmin` contract
  /// @param qPriceOracleAddress_ Address of the `QPriceOracle` contract
  function initialize(address qAdminAddress_, address qPriceOracleAddress_) external;

  /** ADMIN/RESTRICTED FUNCTIONS **/

  /// @notice Record when an account has either borrowed or lent into a
  /// `FixedRateMarket`. This is necessary because we need to iterate
  /// across all markets that an account has borrowed/lent to to calculate their
  /// `borrowValue`. Only the `FixedRateMarket` contract itself may call
  /// this function
  /// @param account User account
  /// @param market Address of the `FixedRateMarket` market
  function _addAccountMarket(address account, IFixedRateMarket market) external;

  /// @notice Transfer collateral balances from one account to another. Only
  /// `FixedRateMarket` contracts can call this restricted function. This is used
  /// for when a liquidator liquidates an account.
  /// @param token ERC20 token
  /// @param from Sender address
  /// @param to Recipient address
  /// @param amount Amount to transfer
  function _transferCollateral(IERC20 token, address from, address to, uint amount) external;
  
  /** USER INTERFACE **/
  
  /// @notice Users call this to deposit collateral to fund their borrows
  /// @param token ERC20 token
  /// @param amount Amount to deposit (in local ccy)
  /// @return uint New collateral balance
  function depositCollateral(IERC20 token, uint amount) external returns(uint);

  /// @notice Users call this to deposit collateral to fund their borrows, where their
  /// collateral is automatically wrapped into MTokens for convenience so users can
  /// automatically earn interest on their collateral.
  /// @param underlying Underlying ERC20 token
  /// @param amount Amount to deposit (in underlying local currency)
  /// @return uint New collateral balance (in MToken balance)
  function depositCollateralWithMTokenWrap(IERC20 underlying, uint amount) external returns(uint);
  
  /// @notice Users call this to deposit collateral to fund their borrows, where their
  /// collateral is automatically wrapped from ETH to WETH.
  /// @return uint New collateral balance (in WETH balance)
  function depositCollateralWithETH() external payable returns(uint);
  
  /// @notice Users call this to deposit collateral to fund their borrows, where their
  /// collateral is automatically wrapped from ETH into MTokens for convenience so users can
  /// automatically earn interest on their collateral.
  /// @return uint New collateral balance (in MToken balance)
  function depositCollateralWithMTokenWrapWithETH() external payable returns(uint);
  
  /// @notice Users call this to withdraw collateral
  /// @param token ERC20 token
  /// @param amount Amount to withdraw (in local ccy)
  /// @return uint New collateral balance
  function withdrawCollateral(IERC20 token, uint amount) external returns(uint);

  /// @notice Users call this to withdraw mToken collateral, where their
  /// collateral is automatically unwrapped into underlying tokens for
  /// convenience.
  /// @param mTokenAddress Yield-bearing token address
  /// @param amount Amount to withdraw (in mToken local currency)
  /// @return uint New collateral balance (in MToken balance)
  function withdrawCollateralWithMTokenUnwrap(
                                              address mTokenAddress,
                                              uint amount
                                              ) external returns(uint);
    
  /// @notice Users call this to withdraw ETH collateral, where their
  /// collateral is automatically unwrapped from WETH for convenience.
  /// @param amount Amount to withdraw (in WETH local currency)
  /// @return uint New collateral balance (in WETH balance)
  function withdrawCollateralWithETH(uint amount) external returns(uint);
  
  /// @notice Users call this to withdraw mToken collateral, where their
  /// collateral is automatically unwrapped into ETH for convenience.
  /// @param amount Amount to withdraw (in WETH local currency)
  /// @return uint New collateral balance (in MToken balance)
  function withdrawCollateralWithMTokenWrapWithETH(uint amount) external returns(uint);
  
  /** VIEW FUNCTIONS **/

  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address);

  /// @notice Get the address of the `QPriceOracle` contract
  /// @return address Address of `QPriceOracle` contract
  function qPriceOracle() external view returns(address);

  /// @notice Get all enabled `Asset`s
  /// @return address[] iterable list of enabled `Asset`s
  function allAssets() external view returns(address[] memory);
  
  /// @notice Gets the `CollateralFactor` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint Collateral Factor, scaled by 1e8
  function collateralFactor(IERC20 token) external view returns(uint);

  /// @notice Gets the `MarketFactor` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint Market Factor, scaled by 1e8
  function marketFactor(IERC20 token) external view returns(uint);
  
  /// @notice Return what the collateral ratio for an account would be
  /// with a hypothetical collateral withdraw/deposit and/or token borrow/lend.
  /// The collateral ratio is calculated as:
  /// (`virtualCollateralValue` / `virtualBorrowValue`)
  /// If the returned value falls below 1e8, the account can be liquidated
  /// @param account User account
  /// @param hypotheticalToken Currency of hypothetical withdraw / deposit
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param depositAmount Amount of hypothetical deposit in local currency
  /// @param hypotheticalMarket Market of hypothetical borrow
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @param lendAmount Amount of hypothetical lend in local ccy
  /// @return uint Hypothetical collateral ratio
  function hypotheticalCollateralRatio(
                                       address account,
                                       IERC20 hypotheticalToken,
                                       uint withdrawAmount,
                                       uint depositAmount,
                                       IFixedRateMarket hypotheticalMarket,
                                       uint borrowAmount,
                                       uint lendAmount
                                       ) external view returns(uint);

  /// @notice Return the current collateral ratio for an account.
  /// The collateral ratio is calculated as:
  /// (`virtualCollateralValue` / `virtualBorrowValue`)
  /// If the returned value falls below 1e8, the account can be liquidated
  /// @param account User account
  /// @return uint Collateral ratio
  function collateralRatio(address account) external view returns(uint);
  
  /// @notice Get the `collateralFactor` weighted value (in USD) of all the
  /// collateral deposited for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD, scaled to 1e18
  function virtualCollateralValue(address account) external view returns(uint);
  
  /// @notice Get the `collateralFactor` weighted value (in USD) for the tokens
  /// deposited for an account
  /// @param account Account to query
  /// @param token ERC20 token
  /// @return uint Value of token collateral of account in USD, scaled to 1e18
  function virtualCollateralValueByToken(
                                         address account,
                                         IERC20 token
                                         ) external view returns(uint);

  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function virtualBorrowValue(address account) external view returns(uint);
  
  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param market `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function virtualBorrowValueByMarket(
                                      address account,
                                      IFixedRateMarket market
                                      ) external view returns(uint);

  /// @notice Return what the weighted total borrow value for an account would be with a hypothetical borrow  
  /// @param account Account to query
  /// @param hypotheticalMarket Market of hypothetical borrow / lend
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @param lendAmount Amount of hypothetical lend in local ccy
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function hypotheticalVirtualBorrowValue(
                                          address account,
                                          IFixedRateMarket hypotheticalMarket,
                                          uint borrowAmount,
                                          uint lendAmount
                                          ) external view returns(uint);
  
  /// @notice Get the unweighted value (in USD) of all the collateral deposited
  /// for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD, scaled to 1e18
  function realCollateralValue(address account) external view returns(uint);
  
  /// @notice Get the unweighted value (in USD) of the tokens deposited
  /// for an account
  /// @param account Account to query
  /// @param token ERC20 token
  /// @return uint Value of token collateral of account in USD, scaled to 1e18
  function realCollateralValueByToken(
                                      address account,
                                      IERC20 token
                                      ) external view returns(uint);
  
  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function realBorrowValue(address account) external view returns(uint);

  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param market `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function realBorrowValueByMarket(
                                   address account,
                                   IFixedRateMarket market
                                   ) external view returns(uint);
  
  /// @notice Get an account's maximum available borrow amount in a specific FixedRateMarket.
  /// For example, what is the maximum amount of GLMRJUL22 that an account can borrow
  /// while ensuring their account health continues to be acceptable?
  /// Note: This function will return 0 if market to borrow is disabled
  /// Note: This function will return creditLimit() if maximum amount allowed for one market exceeds creditLimit()
  /// Note: User can only borrow up to `initCollateralRatio` for their own protection against instant liquidations
  /// @param account User account
  /// @param borrowMarket Address of the `FixedRateMarket` market to borrow
  /// @return uint Maximum available amount user can borrow (in FV) without breaching `initCollateralRatio`
  function hypotheticalMaxBorrowFV(address account, IFixedRateMarket borrowMarket) external view returns(uint);

  /// @notice Get the minimum collateral ratio. Scaled by 1e8.
  /// @return uint Minimum collateral ratio
  function minCollateralRatio() external view returns(uint);
  
  /// @notice Get the minimum collateral ratio for a user account. Scaled by 1e8.
  /// @param account User account 
  /// @return uint Minimum collateral ratio
  function minCollateralRatio(address account) external view returns(uint);
  
  /// @notice Get the initial collateral ratio. Scaled by 1e8
  /// @return uint Initial collateral ratio
  function initCollateralRatio() external view returns(uint);
  
  /// @notice Get the initial collateral ratio for a user account. Scaled by 1e8
  /// @param account User account 
  /// @return uint Initial collateral ratio
  function initCollateralRatio(address account) external view returns(uint);
  
  /// @notice Get the close factor. Scaled by 1e8
  /// @return uint Close factor
  function closeFactor() external view returns(uint);

  /// @notice Get the liquidation incentive. Scaled by 1e8
  /// @return uint Liquidation incentive
  function liquidationIncentive() external view returns(uint);
  
  /// @notice Use this for quick lookups of collateral balances by asset
  /// @param account User account
  /// @param token ERC20 token
  /// @return uint Balance in local
  function collateralBalance(address account, IERC20 token) external view returns(uint);

  /// @notice Get iterable list of collateral addresses which an account has nonzero balance.
  /// @param account User account
  /// @return address[] Iterable list of ERC20 token addresses
  function iterableCollateralAddresses(address account) external view returns(IERC20[] memory);

  /// @notice Quick lookup of whether an account has a particular collateral
  /// @param account User account
  /// @param token ERC20 token addresses
  /// @return bool True if account has collateralized with given ERC20 token, false otherwise
  function accountCollateral(address account, IERC20 token) external view returns(bool);

  /// @notice Get iterable list of all Markets which an account has participated
  /// @param account User account
  /// @return address[] Iterable list of `FixedRateLoanMarket` contract addresses
  function iterableAccountMarkets(address account) external view returns(IFixedRateMarket[] memory);
                                                                         
  /// @notice Quick lookup of whether an account has participated in a Market
  /// @param account User account
  /// @param market`FixedRateLoanMarket` contract
  /// @return bool True if participated, false otherwise
  function accountMarkets(address account, IFixedRateMarket market) external view returns(bool);
                                                                       
  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param token ERC20 token
  /// @param amountLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD, scaled to 1e18
  function localToUSD(IERC20 token, uint amountLocal) external view returns(uint);

  /// @notice Converts any value in USD into its value in local using oracle feed price
  /// @param token ERC20 token
  /// @param valueUSD Amount in USD
  /// @return uint Amount denominated in terms of the ERC20 token
  function USDToLocal(IERC20 token, uint valueUSD) external view returns(uint);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IQPriceOracle {

  /// @notice Emitted when setting the DIA Oracle address
  event SetDIAOracle(address DIAOracle);

  /// @notice Emitted when setting grace period for IERC20 token
  event SetGracePeriod(address tokenAddress, uint oldValue, uint newValue);

  function _setDIAOracle(address DIAOracleAddr) external;

  function _setGracePeriod(address tokenAddress, uint gracePeriodNew) external;
  
  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param token ERC20 token
  /// @param amountLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD
  function localToUSD(IERC20 token, uint amountLocal) external view returns(uint);

  /// @notice Converts any value in USD into its value in local using oracle feed price
  /// @param token ERC20 token
  /// @param valueUSD Amount in USD
  /// @return uint Amount denominated in terms of the ERC20 token
  function USDToLocal(IERC20 token, uint valueUSD) external view returns(uint);

  /// @notice Convenience function for getting price feed from various oracles.
  /// Returned prices should ALWAYS be normalized to eight decimal places.
  /// @param underlyingToken Address of the underlying token
  /// @param oracleFeed Address of the oracle feed
  /// @return answer uint256, decimals uint8
  function priceFeed(
                     IERC20 underlyingToken,
                     address oracleFeed
                     ) external view returns(uint256, uint8);
  
  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address);

  /// @notice Get grace period for specified IERC20 token
  /// @return uint Grace period for specified IERC20 token, measured in seconds
  function gracePeriod(address tokenAddress) external view returns(uint);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

interface ITradingEmissionsQontroller {

  /** ACCESS CONTROLLED FUNCTIONS **/
  
  /// @notice Use the fees generated (in USD) as basis to calculate how much
  /// token reward to disburse for trading volumes. Only `FixedRateMarket`
  /// contracts may call this function.
  /// @param borrower Address of the borrower
  /// @param lender Address of the lender
  /// @param feeUSD Fees generated (in USD, scaled to 1e18)
  function updateRewards(address borrower, address lender, uint feeUSD) external;

  
  /** USER INTERFACE **/

  /// @notice Mint the unclaimed rewards to user and reset their claimable emissions
  function claimEmissions() external;

  
  /** VIEW FUNCTIONS **/

  /// @notice Checks the amount of unclaimed trading rewards that the user can claim
  /// @param account Address of the user
  /// @return uint Amount of QODA token rewards the user may claim
  function claimableEmissions(address account) external view returns(uint);

  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address);

  /// @notice Get the address of the ERC20 token to distribute
  /// @return address Address of the ERC20 token to distribute
  function underlying() external view returns(address);

  function numPhases() external view returns(uint);

  function currentPhase() external view returns(uint);

  function totalAllocation() external view returns(uint);

  function emissionsPhase(uint phase) external view returns(uint, uint, uint);
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/QTypes.sol";

interface IQAdmin is IAccessControlUpgradeable {

  /// @notice Emitted when a new FixedRateMarket is deployed
  event CreateFixedRateMarket(address indexed marketAddress, address indexed tokenAddress, uint maturity);
  
  /// @notice Emitted when existing FixedRateMarket is removed
  event RemoveFixedRateMarket(address indexed marketAddress, address indexed tokenAddress, uint maturity);
  
  /// @notice Emitted when a new `Asset` is added
  event AddAsset(
                 address indexed tokenAddress,
                 bool isYieldBearing,
                 address oracleFeed,
                 uint collateralFactor,
                 uint marketFactor);
  
  /// @notice Emitted when existing `Asset` is removed
  event RemoveAsset(address indexed tokenAddress);
  
  /// @notice Emitted when setting `_weth`
  event SetWETH(address wethAddress);

  /// @notice Emitted when setting `_qollateralManager`
  event SetQollateralManager(address qollateralManagerAddress);

  /// @notice Emitted when setting `_stakingEmissionsQontroller`
  event SetStakingEmissionsQontroller(address stakingEmissionsQontrollerAddress);

  /// @notice Emitted when setting `_tradingEmissionsQontroller`
  event SetTradingEmissionsQontroller(address tradingEmissionsQontrollerAddress);

  /// @notice Emitted when setting `_feeEmissionsQontroller`
  event SetFeeEmissionsQontroller(address feeEmissionsQontrollerAddress);
  
  /// @notice Emitted when setting `_liquidityEmissionsQontroller`
  event SetLiquidityEmissionsQontroller(address liquidityEmissionsQontrollerAddress);

  /// @notice Emitted when setting `_veQoda`
  event SetVeQoda(address veQodaAddress);
  
  /// @notice Emitted when setting `_qodaLens`
  event SetQodaLens(address qodaLensAddress);
  
  /// @notice Emitted when setting `collateralFactor`
  event SetCollateralFactor(address indexed tokenAddress, uint oldValue, uint newValue);

  /// @notice Emitted when setting `marketFactor`
  event SetMarketFactor(address indexed tokenAddress, uint oldValue, uint newValue);

  /// @notice Emitted when setting `minQuoteSize`
  event SetMinQuoteSize(address indexed tokenAddress, uint oldValue, uint newValue);
  
  /// @notice Emitted when `_minCollateralRatioDefault` and `_initCollateralRatioDefault` get updated
  event SetCollateralRatio(uint oldMinValue, uint oldInitValue, uint newMinValue, uint newInitValue);
  
  /// @notice Emitted when `CreditFacility` gets updated
  event SetCreditFacility(address account, bool oldEnabled, uint oldMinValue, uint oldInitValue, uint oldCreditValue, bool newEnabled, uint newMinValue, uint newInitValue, uint newCreditValue);
  
  /// @notice Emitted when `_closeFactor` gets updated
  event SetCloseFactor(uint oldValue, uint newValue);

  /// @notice Emitted when `_repaymentGracePeriod` gets updated
  event SetRepaymentGracePeriod(uint oldValue, uint newValue);
  
  /// @notice Emitted when `_maturityGracePeriod` gets updated
  event SetMaturityGracePeriod(uint oldValue, uint newValue);
  
  /// @notice Emitted when `_liquidationIncentive` gets updated
  event SetLiquidationIncentive(uint oldValue, uint newValue);

  /// @notice Emitted when `_protocolFee` gets updated
  event SetProtocolFee(uint oldValue, uint newValue);
  
  /// @notice Emitted when pause state of all `FixedRateMarket` contract is changed
  event SetMarketPaused(bool paused);
  
  /// @notice Emitted when pause state of a particular contract is changed
  event SetContractPaused(address contractAddr, bool paused);
  
  /// @notice Emitted when pause state of a particular operation is changed
  event SetOperationPaused(uint operationId, bool paused);
  
  /** ADMIN FUNCTIONS **/

  /// @notice Call upon initialization after deploying `QAdmin` contract
  /// @param wethAddress Address of `WETH` contract of the network 
  function _setWETH(address wethAddress) external;
  
  /// @notice Call upon initialization after deploying `QollateralManager` contract
  /// @param qollateralManagerAddress Address of `QollateralManager` deployment
  function _setQollateralManager(address qollateralManagerAddress) external;

  /// @notice Call upon initialization after deploying `StakingEmissionsQontroller` contract
  /// @param stakingEmissionsQontrollerAddress Address of `StakingEmissionsQontroller` deployment
  function _setStakingEmissionsQontroller(address stakingEmissionsQontrollerAddress) external;

  /// @notice Call upon initialization after deploying `TradingEmissionsQontroller` contract
  /// @param tradingEmissionsQontrollerAddress Address of `TradingEmissionsQontroller` deployment
  function _setTradingEmissionsQontroller(address tradingEmissionsQontrollerAddress) external;

  /// @notice Call upon initialization after deploying `FeeEmissionsQontroller` contract
  /// @param feeEmissionsQontrollerAddress Address of `FeeEmissionsQontroller` deployment
  function _setFeeEmissionsQontroller(address feeEmissionsQontrollerAddress) external;
  
  /// @notice Call upon initialization after deploying `LiquidityEmissionsQontroller` contract
  /// @param liquidityEmissionsQontrollerAddress Address of `LiquidityEmissionsQontroller` deployment
  function _setLiquidityEmissionsQontroller(address liquidityEmissionsQontrollerAddress) external;

  /// @notice Call upon initialization after deploying `veQoda` contract
  /// @param veQodaAddress Address of `veQoda` deployment
  function _setVeQoda(address veQodaAddress) external;
  
  /// @notice Call upon initialization after deploying `QodaLens` contract
  /// @param qodaLensAddress Address of `QodaLens` deployment
  function _setQodaLens(address qodaLensAddress) external;
  
  /// @notice Set credit facility for specified account
  /// @param account_ account for credit facility adjustment
  /// @param enabled_ If credit facility should be enabled
  /// @param minCollateralRatio_ New minimum collateral ratio value
  /// @param initCollateralRatio_ New initial collateral ratio value
  /// @param creditLimit_ new credit limit in USD, scaled by 1e18
  function _setCreditFacility(address account_, bool enabled_, uint minCollateralRatio_, uint initCollateralRatio_, uint creditLimit_) external;
  
  /// @notice Admin function for adding new Assets. An Asset must be added before it
  /// can be used as collateral or borrowed. Note: We can create functionality for
  /// allowing borrows of a token but not using it as collateral by setting
  /// `collateralFactor` to zero.
  /// @param tokenAddress ERC20 token corresponding to the Asset
  /// @param isYieldBearing True if token bears interest (eg aToken, cToken, mToken, etc)
  /// @param underlying Address of the underlying token
  /// @param oracleFeed Chainlink price feed address
  /// @param collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @param marketFactor 0.0 to 1.0 (scaled to 1e8) for premium on risky borrows
  function _addAsset(
                     address tokenAddress,
                     bool isYieldBearing,
                     address underlying,
                     address oracleFeed,
                     uint collateralFactor,
                     uint marketFactor
                     ) external;
  
  /// @notice Admin function for removing an asset
  /// @param token ERC20 token corresponding to the Asset
  function _removeAsset(IERC20 token) external;

  /// @notice Adds a new `FixedRateMarket` contract into the internal mapping of
  /// whitelisted market addresses
  /// @param marketAddress New `FixedRateMarket` contract address
  /// @param protocolFee_ Corresponding protocol fee in basis points
  /// @param minQuoteSize_ Size in PV terms, local currency
  function _addFixedRateMarket(
                               address marketAddress,
                               uint protocolFee_,
                               uint minQuoteSize_
                               ) external;
  
  /// @notice Update the `collateralFactor` for a given `Asset`
  /// @param token ERC20 token corresponding to the Asset
  /// @param collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setCollateralFactor(IERC20 token, uint collateralFactor) external;

  /// @notice Update the `marketFactor` for a given `Asset`
  /// @param token Address of the token corresponding to the Asset
  /// @param marketFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setMarketFactor(IERC20 token, uint marketFactor) external;

  /// @notice Set the minimum quote size for a particular `FixedRateMarket`
  /// @param marketAddress Address of the `FixedRateMarket` contract
  /// @param minQuoteSize_ Size in PV terms, local currency
  function _setMinQuoteSize(address marketAddress, uint minQuoteSize_) external;
  
  /// @notice Set the global minimum and initial collateral ratio
  /// @param minCollateralRatio_ New global minimum collateral ratio value
  /// @param initCollateralRatio_ New global initial collateral ratio value
  function _setCollateralRatio(uint minCollateralRatio_, uint initCollateralRatio_) external;
  
  /// @notice Set the global close factor
  /// @param closeFactor_ New close factor value
  function _setCloseFactor(uint closeFactor_) external;

  /// @notice Set the global repayment grace period
  /// @param repaymentGracePeriod_ New repayment grace period
  function _setRepaymentGracePeriod(uint repaymentGracePeriod_) external;

  /// @notice Set the global maturity grace period
  /// @param maturityGracePeriod_ New maturity grace period
  function _setMaturityGracePeriod(uint maturityGracePeriod_) external;
  
  /// @notice Set the global liquidation incetive
  /// @param liquidationIncentive_ New liquidation incentive value
  function _setLiquidationIncentive(uint liquidationIncentive_) external;

  /// @notice Set the global annualized protocol fees for each market in basis points
  /// @param marketAddress Address of the `FixedRateMarket` contract
  /// @param protocolFee_ New protocol fee value (scaled to 1e4)
  function _setProtocolFee(address marketAddress, uint protocolFee_) external;
  
  /// @notice Set the global threshold in USD for protocol fee transfer
  /// @param thresholdUSD_ New threshold USD value (scaled by 1e6)
  function _setThresholdUSD(uint thresholdUSD_) external;
  
  /// @notice Pause/unpause all markets for admin
  /// @param paused Boolean to indicate if all markets should be paused
  function _setMarketsPaused(bool paused) external;
  
  /// @notice Pause/unpause specified list of contracts for admin
  /// @param contractsAddr List of contract addresses to pause/unpause
  /// @param paused Boolean to indicate if specified contract should be paused
  function _setContractPaused(address[] memory contractsAddr, bool paused) external;
  
  /// @notice Pause/unpause specified contract for admin
  /// @param contractAddr Address of contract to pause/unpause
  /// @param paused Boolean to indicate if specified contract should be paused
  function _setContractPaused(address contractAddr, bool paused) external;
  
  /// @notice Pause/unpause specified list of operations for admin
  /// @param operationIds List of ids for operation to pause/unpause
  /// @param paused Boolean to indicate if specified operation should be paused
  function _setOperationPaused(uint[] memory operationIds, bool paused) external;
  
  /// @notice Pause/unpause specified operation for admin
  /// @param operationId Id for operation to pause/unpause
  /// @param paused Boolean to indicate if specified operation should be paused
  function _setOperationPaused(uint operationId, bool paused) external;
  
  /** VIEW FUNCTIONS **/

  function ADMIN_ROLE() external view returns(bytes32);

  function MARKET_ROLE() external view returns(bytes32);

  function MINTER_ROLE() external view returns(bytes32);

  function VETOKEN_ROLE() external view returns(bytes32);
  
  /// @notice Get the address of the `WETH` contract
  function WETH() external view returns(address);
  
  /// @notice Get the address of the `QollateralManager` contract
  function qollateralManager() external view returns(address);

  /// @notice Get the address of the `QPriceOracle` contract
  function qPriceOracle() external view returns(address);

  /// @notice Get the address of the `StakingEmissionsQontroller` contract
  function stakingEmissionsQontroller() external view returns(address);

  /// @notice Get the address of the `TradingEmissionsQontroller` contract
  function tradingEmissionsQontroller() external view returns(address);

  /// @notice Get the address of the `FeeEmissionsQontroller` contract
  function feeEmissionsQontroller() external view returns(address);
  
  /// @notice Get the address of the `LiquidityEmissionsQontroller` contract
  function liquidityEmissionsQontroller() external view returns(address);

  /// @notice Get the address of the `veQoda` contract
  function veQoda() external view returns(address);
  
  /// @notice Get the address of the `QodaLens` contract
  function qodaLens() external view returns(address);

  /// @notice Get the credit limit with associated address, scaled by 1e18
  function creditLimit(address account_) external view returns(uint);
  
  /// @notice Gets the `Asset` mapped to the address of a ERC20 token
  /// @param token ERC20 token
  /// @return QTypes.Asset Associated `Asset`
  function assets(IERC20 token) external view returns(QTypes.Asset memory);

  /// @notice Get all enabled `Asset`s
  /// @return address[] iterable list of enabled `Asset`s
  function allAssets() external view returns(address[] memory);

  /// @notice Gets the `oracleFeed` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return address Address of the oracle feed
  function oracleFeed(IERC20 token) external view returns(address);
  
  /// @notice Gets the `CollateralFactor` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint Collateral Factor, scaled by 1e8
  function collateralFactor(IERC20 token) external view returns(uint);

  /// @notice Gets the `MarketFactor` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint Market Factor, scaled by 1e8
  function marketFactor(IERC20 token) external view returns(uint);

  /// @notice Gets the `maturities` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint[] array of UNIX timestamps (in seconds) of the maturity dates
  function maturities(IERC20 token) external view returns(uint[] memory);
  
  /// @notice Get the MToken market corresponding to any underlying ERC20
  /// tokenAddress => mTokenAddress
  function underlyingToMToken(IERC20 token) external view returns(address);
  
  /// @notice Gets the address of the `FixedRateMarket` contract
  /// @param token ERC20 token
  /// @param maturity UNIX timestamp of the maturity date
  /// @return address Address of `FixedRateMarket` contract
  function fixedRateMarkets(IERC20 token, uint maturity) external view returns(address);

  /// @notice Check whether an address is a valid FixedRateMarket address.
  /// Can be used for checks for inter-contract admin/restricted function call.
  /// @param marketAddress Address of the `FixedRateMarket` contract
  /// @return bool True if valid false otherwise
  function isMarketEnabled(address marketAddress) external view returns(bool);

  function minQuoteSize(address marketAddress) external view returns(uint);
  
  function minCollateralRatio() external view returns(uint);
  
  function minCollateralRatio(address account) external view returns(uint);
  
  function initCollateralRatio() external view returns(uint);
  
  function initCollateralRatio(address account) external view returns(uint);
  
  function closeFactor() external view returns(uint);

  function repaymentGracePeriod() external view returns(uint);
  
  function maturityGracePeriod() external view returns(uint);
  
  function liquidationIncentive() external view returns(uint);

  /// @notice Annualized protocol fee in basis points, scaled by 1e4
  function protocolFee(address marketAddress) external view returns(uint);

  /// @notice threshold in USD where protocol fee from each market will be transferred into `FeeEmissionsQontroller`
  /// once this amount is reached, scaled by 1e6
  function thresholdUSD() external view returns(uint);
  
  /// @notice Boolean to indicate if all markets are paused
  function marketsPaused() external view returns(bool);
  
  /// @notice Boolean to indicate if specified contract address is paused
  function contractPaused(address contractAddr) external view returns(bool);
  
  /// @notice Boolean to indicate if specified operation is paused
  function operationPaused(uint operationId) external view returns(bool);
  
  /// @notice Check if given combination of contract address and operation should be allowed
  function isPaused(address contractAddr, uint operationId) external view returns(bool);
  
  /// @notice 2**256 - 1
  function UINT_MAX() external pure returns(uint);
  
  /// @notice Generic mantissa corresponding to ETH decimals
  function MANTISSA_DEFAULT() external pure returns(uint);

  /// @notice Mantissa for USD
  function MANTISSA_USD() external pure returns(uint);
  
  /// @notice Mantissa for collateral ratio
  function MANTISSA_COLLATERAL_RATIO() external pure returns(uint);

  /// @notice `assetFactor` and `marketFactor` have up to 8 decimal places precision
  function MANTISSA_FACTORS() external pure returns(uint);

  /// @notice Basis points have 4 decimal place precision
  function MANTISSA_BPS() external pure returns(uint);

  /// @notice Staked Qoda has 6 decimal place precision
  function MANTISSA_STAKING() external pure returns(uint);
  
  /// @notice `collateralFactor` cannot be above 1.0
  function MAX_COLLATERAL_FACTOR() external pure returns(uint);

  /// @notice `marketFactor` cannot be above 1.0
  function MAX_MARKET_FACTOR() external pure returns(uint);

  /// @notice version number of this contract, will be bumped upon contractual change
  function VERSION_NUMBER() external pure returns(string memory);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

import "../libraries/QTypes.sol";

interface IQuoteManager {
  
  /// @notice Emitted when an account creates a new `Quote`
  event CreateQuote(
                    uint8 indexed side,
                    address indexed quoter,
                    uint64 id,
                    uint8 quoteType,
                    uint64 APR,
                    uint cashflow
                    );
  
  /// @notice Emitted when a `Quote` is filled and/or cancelled
  event RemoveQuote(
                    address indexed quoter,
                    bool isUserCanceled,
                    uint8 side,
                    uint64 id,
                    uint8 quoteType,
                    uint64 APR,
                    uint cashflow,
                    uint filled
                    );
  
  /** USER INTERFACE **/
    
  /// @notice Creates a new  `Quote` and adds it to the `OrderbookSide` linked list by side
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param quoter Account of the Quoter
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param APR In decimal form scaled by 1e4 (ex. 1052 = 10.52%)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  function createQuote(uint8 side, address quoter, uint8 quoteType, uint64 APR, uint cashflow) external;
    
  /// @notice Cancel `Quote` by id. Note this is a O(1) operation
  /// since `OrderbookSide` uses hashmaps under the hood. However, it is
  /// O(n) against the array of `Quote` ids by account so we should ensure
  /// that array should not grow too large in practice.
  /// @param isUserCanceled True if user actively canceled `Quote`, false otherwise
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param quoter Address of the `Quoter`
  /// @param id Id of the `Quote`
  function cancelQuote(bool isUserCanceled, uint8 side, address quoter, uint64 id) external;
    
  /// @notice Fill existing `Quote` by side and id
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of the `Quote`
  /// @param amount Amount to be filled
  function fillQuote(uint8 side, uint64 id, uint amount) external;
    
  /** VIEW FUNCTIONS **/
  
  /// @notice Get the address of the `QAdmin`
  /// @return address
  function qAdmin() external view returns(address);
  
  /// @notice Get the address of the `FixedRateMarket`
  /// @return address
  function fixedRateMarket() external view returns(address);
    
  /// @notice Get the minimum quote size for this market
  /// @return uint Minimum quote size, in PV terms, local currency
  function minQuoteSize() external view returns(uint);
    
  /// @notice Get the linked list pointer top of book for `Quote` by side
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return uint64 id of top of book `Quote` 
  function getQuoteHeadId(uint8 side) external view returns(uint64);

  /// @notice Get the top of book for `Quote` by side
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return QTypes.Quote head `Quote`
  function getQuoteHead(uint8 side) external view returns(QTypes.Quote memory);
  
  /// @notice Get the `Quote` for the given `side` and `id`
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of `Quote`
  /// @return QTypes.Quote `Quote` associated with the id
  function getQuote(uint8 side, uint64 id) external view returns(QTypes.Quote memory);

  /// @notice Get all live `Quote` id's by `account` and `side`
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param account Account to query
  /// @return uint[] Unsorted array of borrow `Quote` id's
  function getAccountQuotes(uint8 side, address account) external view returns(uint64[] memory);

  /// @notice Get the number of active `Quote`s by `side` in the orderbook
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return uint Number of `Quote`s
  function getNumQuotes(uint8 side) external view returns(uint);
  
  /// @notice Checks whether a `Quote` is still valid. Importantly, for lenders,
  /// we need to check if the `Quoter` currently has enough balance to perform
  /// a lend, since the `Quoter` can always remove balance/allowance immediately
  /// after creating the `Quote`. Likewise, for borrowers, we need to check if
  /// the `Quoter` has enough collateral to perform a borrow, since the `Quoter`
  /// can always remove collateral immediately after creating the `Quote`.
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param quote `Quote` to check for validity
  /// @return bool True if valid false otherwise
  function isQuoteValid(uint8 side, QTypes.Quote memory quote) external view returns(bool);
  
  /// @notice Get the PV of a cashflow amount based on the `quoteType`
  /// @param quoteType 0 for PV, 1 for FV
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param sTime PV start time
  /// @param eTime FV end time
  /// @param amount Value to be PV'ed
  /// @return uint PV of the `amount`
  function getPV(
                 uint8 quoteType,
                 uint64 APR,
                 uint amount,
                 uint sTime,
                 uint eTime
                 ) external view returns(uint);

  /// @notice Get the FV of a cashflow amount based on the `quoteType`
  /// @param quoteType 0 for PV, 1 for FV
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param sTime PV start time
  /// @param eTime FV end time
  /// @param amount Value to be FV'ed
  /// @return uint FV of the `amount`
  function getFV(
                 uint8 quoteType,
                 uint64 APR,
                 uint amount,
                 uint sTime,
                 uint eTime
                 ) external view returns(uint);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IQToken is IERC20Upgradeable, IERC20MetadataUpgradeable {
  
  /// @notice Emitted when an account redeems their qTokens
  event RedeemQTokens(address indexed account, uint amount);
  
  /** USER INTERFACE **/
  
  /// @notice This function allows net lenders to redeem qTokens for the
  /// underlying token. Redemptions may only be permitted after loan maturity
  /// plus `_maturityGracePeriod`. The public interface redeems specified amount
  /// of qToken from existing balance.
  /// @param amount Amount of qTokens to redeem
  /// @return uint Amount of qTokens redeemed
  function redeemQTokensByRatio(uint amount) external returns(uint);
  
  /// @notice This function allows net lenders to redeem qTokens for the
  /// underlying token. Redemptions may only be permitted after loan maturity
  /// plus `_maturityGracePeriod`. The public interface redeems the entire qToken
  /// balance.
  /// @return uint Amount of qTokens redeemed
  function redeemAllQTokensByRatio() external returns(uint);
  
  /// @notice This function allows net lenders to redeem qTokens for ETH.
  /// Redemptions may only be permitted after loan maturity plus 
  /// `_maturityGracePeriod`. The public interface redeems specified amount
  /// of qToken from existing balance.
  /// @param amount Amount of qTokens to redeem
  /// @return uint Amount of qTokens redeemed
  function redeemQTokensByRatioWithETH(uint amount) external returns(uint);
  
  /// @notice This function allows net lenders to redeem qTokens for ETH.
  /// Redemptions may only be permitted after loan maturity plus
  /// `_maturityGracePeriod`. The public interface redeems the entire qToken
  /// balance.
  /// @return uint Amount of qTokens redeemed
  function redeemAllQTokensByRatioWithETH() external returns(uint);
  
  /** VIEW FUNCTIONS **/
  
  /// @notice Get the address of the `QAdmin`
  /// @return address
  function qAdmin() external view returns(address);
  
  /// @notice Gets the address of the `FixedRateMarket` contract
  /// @return address Address of `FixedRateMarket` contract
  function fixedRateMarket() external view returns(address);
  
  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return IERC20
  function underlyingToken() external view returns(IERC20);
  
  /// @notice Get amount of qTokens user can redeem based on current loan repayment ratio
  /// @return uint amount of qTokens user can redeem
  function redeemableQTokens() external view returns(uint);
  
  /// @notice Gets the current `redemptionRatio` where owned qTokens can be redeemed up to
  /// @return uint redemption ratio, capped and scaled by 1e18
  function redemptionRatio() external view returns(uint);
  
  /// @notice Tokens redeemed from message sender so far
  /// @return uint Token redeemed by message sender
  function tokensRedeemed() external view returns(uint);
  
  /// @notice Tokens redeemed from given account so far
  /// @param account Account to query
  /// @return uint Token redeemed by given account
  function tokensRedeemed(address account) external view returns(uint);
  
  /// @notice Tokens redeemed across all users so far
  function tokensRedeemedTotal() external view returns(uint);
  
  /** ERC20 Implementation **/
  
  /// @notice Creates `amount` tokens and assigns them to `account`, increasing the total supply.
  /// @param account Account to receive qToken
  /// @param amount Amount of qToken to mint
  function mint(address account, uint256 amount) external;
  
  /// @notice Destroys `amount` tokens from `account`, reducing the total supply
  /// @param account Account to receive qToken
  /// @param amount Amount of qToken to mint
  function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

library CustomErrors {
  
  error QA_OnlyAdmin();
  
  error QM_OnlyAdmin();
  
  error FRM_OnlyAdmin();
  
  error SEQ_OnlyAdmin();
  
  error LEQ_OnlyAdmin();
  
  error SOS_OnlyAdmin();
  
  error STS_OnlyAdmin();
  
  error TV_OnlyAdmin();

  error QPO_OnlyAdmin();

  error FEQ_OnlyMarket();
  
  error QA_OnlyMarket();
  
  error QM_OnlyMarket();
  
  error QUM_OnlyMarket();
  
  error QTK_OnlyMarket();
  
  error TEQ_OnlyMarket();
  
  error LEQ_OnlyMarket();
  
  error SOS_OnlyMarket();
  
  error STS_OnlyMarket();
  
  error SS_OnlyMarket();
  
  error QE_OnlyMinter();
  
  error FEQ_OnlyVeToken();
  
  error QA_OnlyVeToken();
  
  error SEQ_OnlyVeToken();
  
  error FRM_OnlyQToken();

  error FRM_OnlyQuoteManager();
  
  error QA_AssetExist();

  error QA_AssetNotExist();

  error QA_AssetNotEnabled();

  error QA_AssetNotSupported();
  
  error QM_AssetNotSupported();
  
  error QPO_AssetNotSupported();

  error QA_MarketExist();
  
  error QA_MarketNotExist();

  error QA_InvalidCollateralFactor();

  error QA_InvalidMarketFactor();

  error QA_InvalidAddress();

  error QA_MinCollateralRatioNotLessThan1();

  error QA_MinCollateralRatioNotGreaterThanInit();

  error QA_OverThreshold(uint actual, uint expected);

  error QA_UnderThreshold(uint actual, uint expected);
  
  error QA_FailToRedeemMTokens();
  
  error QA_FailToMintMTokens();

  error QM_OperationPaused(uint operationId);
  
  error FRM_OperationPaused(uint operationId);
  
  error QUM_OperationPaused(uint operationId);
  
  error QTK_OperationPaused(uint operationId);
  
  error SEQ_OperationPaused(uint operationId);
  
  error TEQ_OperationPaused(uint operationId);
  
  error LEQ_OperationPaused(uint operationId);
  
  error FEQ_OperationPaused(uint operationId);
  
  error VQ_OperationPaused(uint operationId);
  
  error FRM_ReentrancyDetected();
  
  error QTK_ReentrancyDetected();
  
  error QM_ReentrancyDetected();
  
  error FRM_AmountZero();
  
  error SEQ_AmountZero();
  
  error QM_ZeroTransferAmount();
  
  error QM_ZeroDepositAmount();
  
  error SEQ_ZeroDepositAmount();
  
  error QM_ZeroWithdrawAmount();
  
  error QTK_ZeroRedeemAmount();
  
  error TEQ_ZeroRewardAmount();
  
  error VQ_ZeroStakeAmount();
  
  error VQ_ZeroUnstakeAmount();
  
  error FRM_InsufficientAllowance();
  
  error QUM_InsufficientAllowance();
  
  error FRM_InsufficientBalance();
  
  error QUM_InsufficientBalance();
  
  error VQ_InsufficientBalance();
  
  error TT_InsufficientBalance();
  
  error QM_InsufficientCollateralBalance();
  
  error TT_InsufficientEth();
  
  error QM_WithdrawMoreThanCollateral();
  
  error QM_MTokenUnsupported();
  
  error QTK_CannotRedeemEarly();
  
  error FRM_NotLiquidatable();
  
  error QM_NotEnoughCollateral();
  
  error FRM_NotEnoughCollateral();
  
  error QTK_BorrowsMoreThanLends();
  
  error FRM_AmountLessThanProtocolFee();
  
  error FRM_MarketExpired();
  
  error FRM_InvalidSide();
  
  error QUM_InvalidSide();
  
  error QL_InvalidSide();
  
  error QUM_InvalidQuoteType();
  
  error QL_InvalidQuoteType();
  
  error FRM_InvalidAPR();
  
  error FRM_InvalidCounterparty();
  
  error FRM_InvalidMaturity();
  
  error QM_InvalidWithdrawal(uint actual, uint expected);
  
  error QUM_InvalidFillAmount();
  
  error QUM_InvalidCashflowSize();
  
  error INT_InvalidTimeInterval();
  
  error QTK_AmountExceedsRedeemable();
  
  error QTK_AmountExceedsBorrows();
  
  error FRM_MaxBorrowExceeded();
  
  error QUM_MaxBorrowExceeded();
  
  error QL_MaxBorrowExceeded();
  
  error QUM_QuoteNotFound();
  
  error QUM_QuoteSizeTooSmall();
  
  error QPO_ExchangeRateOutOfBound();
  
  error SEQ_LengthMismatch();
  
  error TEQ_LengthMismatch();
  
  error SEQ_InvokeMoreThanOnce();
  
  error LEQ_InvokeMoreThanOnce();
  
  error VQ_TransferDisabled();
  
  error QM_UnsuccessfulEthTransfer();
  
  error FRM_UnsuccessfulEthTransfer();
  
  error MT_UnsuccessfulEthTransfer();
  
  error TT_UnsuccessfulEthTransfer();
  
  error UTL_UnsuccessfulEthTransfer();
  
  error FRM_EthOperationNotPermitted();
  
  error QTK_EthOperationNotPermitted();
  
  error LEQ_ContractInitializationProblem();
  
  error FEQ_ContractInitializationProblem();
  
  error FEQ_Unauthorized();
  
  error QUM_Unauthorized();
  
  error QUM_NotQuoteOwner();

  error QPO_Already_Set();
  
  error QPO_DIA_Key_Not_Found();

  error QPO_DIA_Price_Invalid();

  error QPO_DIA_Price_Stale();
  
  error QPO_Price_Stale();
  
  error QPO_Price_Invalid();
  
  error LL_Quote_Not_Exist();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

import "./CustomErrors.sol";

library Interest {

  function PVToFV(
                  uint64 APR,
                  uint PV,
                  uint sTime,
                  uint eTime,
                  uint mantissaAPR
                  ) internal pure returns(uint){

    if (sTime >= eTime) {
      revert CustomErrors.INT_InvalidTimeInterval();
    }

    // Seconds per 365-day year (60 * 60 * 24 * 365)
    uint year = 31536000;
    
    // elapsed time from now to maturity
    uint elapsed = eTime - sTime;

    uint interest = PV * APR * elapsed / mantissaAPR / year;

    return PV + interest;    
  }

  function FVToPV(
                  uint64 APR,
                  uint FV,
                  uint sTime,
                  uint eTime,
                  uint mantissaAPR
                  ) internal pure returns(uint){

    if (sTime >= eTime) {
      revert CustomErrors.INT_InvalidTimeInterval();
    }

    // Seconds per 365-day year (60 * 60 * 24 * 365)
    uint year = 31536000;
    
    // elapsed time from now to maturity
    uint elapsed = eTime - sTime;

    uint num = FV * mantissaAPR * year;
    uint denom = mantissaAPR * year + APR * elapsed;

    return num / denom;
    
  }  
}

//SPDX-License-Identifier: NONE
pragma solidity >=0.8.9 <=0.8.19;

import "./QTypes.sol";
import "./CustomErrors.sol";

library LinkedList {

  struct OrderbookSide {
    uint64 head;
    uint64 tail;
    uint64 idCounter;
    uint64 length;
    mapping(uint64 => QTypes.Quote) quotes;
  }

    
  /// @notice Get the `Quote` with id `id`
  function get(OrderbookSide storage self, uint64 id) internal view returns(QTypes.Quote memory){
    QTypes.Quote memory quote = self.quotes[id];
    return quote;
  }
    
  /// @notice Insert a new `Quote` as the new head of the linked list
  /// @return uint64 Id of the new `Quote`
  function addHead(
                   OrderbookSide storage self,
                   address quoter,
                   uint8 quoteType,
                   uint64 APR,
                   uint cashflow                    
                   ) internal returns(uint64){

    // Create a new unlinked object representing the new head
    QTypes.Quote memory newQuote = createQuote(self, quoter, quoteType, APR, cashflow);

    // Link `newQuote` before the current head
    link(self, newQuote.id, self.head);

    // Set the head pointer to `newQuote`
    setHeadId(self, newQuote.id);

    if(self.tail == 0) {
      // `OrderbookSide` is currently empty, so set tail = head
      setTailId(self, newQuote.id);
    }

    return newQuote.id;
  }

  /// @notice Insert a new `Quote` as the tail of the linked list
  /// @return uint64 Id of the new `Quote`
  function addTail(
                   OrderbookSide storage self,
                   address quoter,
                   uint8 quoteType,
                   uint64 APR,
                   uint cashflow
                   ) internal returns(uint64) {
    
    if (self.head == 0) {

      // `OrderbookSide` is currently empty, so set head = tail
      return addHead(self, quoter, quoteType, APR, cashflow);

    } else {

      // Create a new unlinked object representing the new tail
      QTypes.Quote memory newQuote = createQuote(self, quoter, quoteType, APR, cashflow);

      // Link `newQuote` after the current tail
      link(self, self.tail, newQuote.id);

      // Set the tail pointer to `newQuote`
      setTailId(self, newQuote.id);

      return newQuote.id;
    }    
  }


  /// @notice Remove the `Quote` with id `id` from the linked list
  function remove(OrderbookSide storage self, uint64 id) internal {
    if (self.quotes[id].id != id) {
      revert CustomErrors.LL_Quote_Not_Exist();
    }
    
    QTypes.Quote memory quoteToRemove = self.quotes[id];

    if(self.head == id && self.tail == id) {
      // `OrderbookSide` only has one element. Reset both head and tail pointers
      setHeadId(self, 0);
      setTailId(self, 0);
    } else if (self.head == id) {
      // `quoteToRemove` is the current head, so set the next item in the linked list to be head
      setHeadId(self, quoteToRemove.next);
      self.quotes[quoteToRemove.next].prev = 0;
    } else if (self.tail == id) {
      // `quoteToRemove` is the current tail, so set the prev item in the linked list to be tail
      setTailId(self, quoteToRemove.prev);
      self.quotes[quoteToRemove.prev].next = 0;
    } else {
      // Link the `Quote`s before and after `quoteToRemove` together
      link(self, quoteToRemove.prev, quoteToRemove.next);
    }

    // Ready to delete `quoteToRemove`
    delete self.quotes[quoteToRemove.id];

    // Decrement the length of the `OrderbookSide`
    self.length--;
  }
  
  /// @notice Insert a new `Quote` after the `Quote` with id `prev`
  /// @return uint64 Id of the new `Quote`
  function insertAfter(
                       OrderbookSide storage self,
                       uint64 prev,
                       address quoter,
                       uint8 quoteType,
                       uint64 APR,
                       uint cashflow
                       ) internal returns(uint64){
    
    if(prev == self.tail) {     

      // Prev element is the tail, make this `Quote` the new tail
      return addTail(self, quoter, quoteType, APR, cashflow);
            
    } else {

      // Create a new unlinked object representing the new `Quote`
      QTypes.Quote memory newQuote = createQuote(self, quoter, quoteType, APR, cashflow);

      // Get the `Quote`s before and after `newQuote`
      QTypes.Quote memory prevQuote = self.quotes[prev];      
      QTypes.Quote memory nextQuote = self.quotes[prevQuote.next];

      // Insert the new `Quote` between `prevQuote` and `nextQuote`
      link(self, newQuote.id, nextQuote.id);
      link(self, prevQuote.id, newQuote.id);

      return newQuote.id;
    }    
  }

  /// @notice Insert a new `Quote` before the `Quote` with id `next`
  /// @return uint64 Id of the new `Quote`
  function insertBefore(
                        OrderbookSide storage self,
                        uint64 next,
                        address quoter,
                        uint8 quoteType,
                        uint64 APR,
                        uint cashflow
                        ) internal returns(uint64){

    if(next == self.head) {

      // Next element is the head, make this `Quote` the new head
      return addHead(self, quoter, quoteType, APR, cashflow);
      
    } else {

      // inserting before `next` is equivalent to inserting after `next.prev`
      return insertAfter(self, self.quotes[next].prev, quoter, quoteType, APR, cashflow);
      
    }
    
  }
                        
  /// @notice Update the pointer to head of the linked list
  function setHeadId(OrderbookSide storage self, uint64 head) internal {
    self.head = head;
  }

  /// @notice Update the pointer to tail of the linked list
  function setTailId(OrderbookSide storage self, uint64 tail) internal {
    self.tail = tail;
  }
  
  /// @notice Create a new unlinked `Quote`
  function createQuote(
                       OrderbookSide storage self,
                       address quoter,
                       uint8 quoteType,
                       uint64 APR,
                       uint cashflow
                       ) internal returns(QTypes.Quote memory) {

    // Increment the counter for new id's.
    // Note this means non-empty linked lists start with id = 1
    self.idCounter = self.idCounter + 1;    
    
    // Create a new unlinked `Quote` with the latest `idCounter`
    QTypes.Quote memory newQuote = QTypes.Quote(self.idCounter, 0, 0, quoter, quoteType, APR, cashflow, 0);
    
    // Add the `Quote` to the internal mapping of `Quote`s
    self.quotes[newQuote.id] = newQuote;
    
    // Increment the length of the `OrderbookSide`
    self.length++;
    
    return newQuote;
  }

  /// @notice Link two `Quote`s together
  function link(
                OrderbookSide storage self,
                uint64 prev,
                uint64 next
                ) internal {
    
    self.quotes[prev].next = next;
    self.quotes[next].prev = prev;
    
  }
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

library QTypes {

  /// @notice Contains all the details of an Asset. Assets  must be defined
  /// before they can be used as collateral.
  /// @member isEnabled True if an asset is defined, false otherwise
  /// @member isYieldBearing True if token bears interest (eg aToken, cToken, mToken, etc)
  /// @member underlying Address of the underlying token
  /// @member oracleFeed Address of the corresponding chainlink oracle feed
  /// @member collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @member marketFactor 0.0 1.0 for premium on risky borrows
  /// @member maturities Iterable storage for all enabled maturities
  struct Asset {
    bool isEnabled;
    bool isYieldBearing;
    address underlying;
    address oracleFeed;
    uint collateralFactor;
    uint marketFactor;
    uint[] maturities;
  }
  
  /// @notice Contains all the fields of a created Quote
  /// @param id ID of the quote
  /// @param next Next quote in the list
  /// @param prev Previous quote in the list
  /// @param quoter Account of the Quoter
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param filled Amount quote has got filled partially 
  struct Quote {
    uint64 id;
    uint64 next;
    uint64 prev;
    address quoter;
    uint8 quoteType;
    uint64 APR;
    uint cashflow;
    uint filled;
  }
  
  /// @notice Contains all the configurations customizable to an address
  /// @member enabled If config for an address is enabled. When enabled is false, credit limit is infinite even if value is 0
  /// @member minCollateralRatio If collateral ratio falls below `_minCollateralRatio`, it is subject to liquidation. Scaled by 1e8
  /// @member initCollateralRatio When initially taking a loan, collateral ratio must be higher than this. `initCollateralRatio` should always be higher than `minCollateralRatio`. Scaled by 1e8
  /// @member creditLimit Allowed limit in virtual USD for each address to do uncollateralized borrow, scaled by 1e18
  struct CreditFacility {
    bool enabled;
    uint minCollateralRatio;
    uint initCollateralRatio;
    uint creditLimit;
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/CustomErrors.sol";

library Utils {
  
  using SafeERC20 for IERC20;
  
  function roundUpDiv(uint dividend, uint divider) internal pure returns(uint) {
    uint adjustment = dividend % divider > 0? 1: 0;
    return dividend / divider + adjustment;
  }
  
  /// @notice Transfer fund from sender to receiver, with handling of ETH wrapping and unwrapping
  /// if needed. Note that this function will not perform balance check and it should be done
  /// in the caller.
  /// @param sender Account of the sender
  /// @param receiver Account of the receiver
  /// @param amount Size of the fund to be transferred from sender to receiver
  /// @param isSendingETH Indicate if sender is sending fund with ETH
  /// @param isReceivingETH Indicate if receiver is receiving fund with ETH
  function transferTokenOrETH(
                              address sender,
                              address receiver,
                              uint amount,
                              IERC20 underlying,
                              address wethAddress,
                              bool isSendingETH,
                              bool isReceivingETH
                              ) internal {
    address sender_ = sender;
    address receiver_ = receiver;
    
    // If it is ETH transfer, contract will send/receive on behalf
    // and do needed token wrapping/unwrapping
    if (isSendingETH) {
      sender_ = address(this);
    }
    if (isReceivingETH) {
      receiver_ = address(this);
    }
    
    // If sender uses ETH for transfer, token wrapping is needed
    if (isSendingETH) {
      IWETH weth = IWETH(wethAddress);
      weth.deposit{ value: amount }();
    }
    
    // Transfer `amount` from sender to receiver
    if (sender_ == address(this)) {
      underlying.safeTransfer(receiver_, amount);
    } else {
      underlying.safeTransferFrom(sender_, receiver_, amount);
    }
    
    // For receiver getting ETH in transfer, token unwrapping is needed
    if (isReceivingETH) {
      IWETH weth = IWETH(wethAddress);
      weth.withdraw(amount);
      (bool success,) = receiver.call{value: amount}("");
      if (!success) {
        revert CustomErrors.UTL_UnsuccessfulEthTransfer();
      }
    }
  }

  /// @notice Obtain balance for an account for either token balance or native balance
  /// @param account Account to fetch
  /// @param isETH true to fetch native balance, false to fetch ERC20 balance
  /// @param underlying ERC20 token to fetch balance
  /// @return balance of an account
  function getBalance(address account, bool isETH, IERC20 underlying) internal view returns (uint) {
    return isETH? account.balance: underlying.balanceOf(account);
  }

  /// @notice If user sends more ETH than is actually being executed, the excessive amount should
  /// be refunded to the user
  /// @param amountConsumed amount used in this transaction
  function refundExcessiveETH(uint amountConsumed) internal {
    if (amountConsumed < msg.value) {
      (bool success,) = msg.sender.call{value: msg.value - amountConsumed}("");
      if (!success) {
        revert CustomErrors.UTL_UnsuccessfulEthTransfer();
      }
    }
  }
  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

//SPDX-License-Identifier: NONE
pragma solidity >=0.8.9 <=0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}