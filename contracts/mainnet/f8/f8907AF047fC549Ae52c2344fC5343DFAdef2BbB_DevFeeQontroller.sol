// SPDX-License-Identifier: NONE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFeeEmissionsQontroller.sol";
import "./libraries/CustomErrors.sol";

contract DevFeeQontroller is IFeeEmissionsQontroller {

  address public _OWNER;

  event ReceiveFees(address underlyingToken, uint feeLocal);

  event TransferOwnership(address oldOwner, address newOwner);
  
  constructor(address owner) {
    _OWNER = owner;
  }

  /** ADMIN FUNCTIONS **/

  // For receiving native token
  receive() external payable {}
  
  function transferOwnership(address newOwner) public {
    if (msg.sender != _OWNER) {
      revert CustomErrors.FEQ_Unauthorized();
    }
    emit TransferOwnership(_OWNER, newOwner);
    _OWNER = newOwner;
  }

  function withdraw() public {
    if (msg.sender != _OWNER) {
      revert CustomErrors.FEQ_Unauthorized();
    }
    payable(msg.sender).transfer(address(this).balance);
  }
  
  function withdraw(address tokenAddr) public {
    if (msg.sender != _OWNER) {
      revert CustomErrors.FEQ_Unauthorized();
    }
    uint balance = IERC20(tokenAddr).balanceOf(address(this));
    IERC20(tokenAddr).transfer(msg.sender, balance);
  }

  function approve(address tokenAddr, address spender) public {
    if (msg.sender != _OWNER) {
      revert CustomErrors.FEQ_Unauthorized();
    }
    IERC20 token = IERC20(tokenAddr);
    token.approve(spender, type(uint).max);
  }

  /** ACCESS CONTROLLED FUNCTIONS  **/

  function receiveFees(IERC20 underlyingToken, uint feeLocal) external {
    emit ReceiveFees(address(underlyingToken), feeLocal);
  }

  function veIncrease(address account, uint veIncreased) external {

  }

  function veReset(address account) external {

  }

  /** USER INTERFACE **/
  
  function claimEmissions() external {

  }

  function claimEmissions(address account) external {

  }

  /** VIEW FUNCTIONS **/
  
  function claimableEmissions() external pure returns (uint) {
    return 0;
  }

  function claimableEmissions(address account) external pure returns(uint) {
    account;
    return 0;
  }
  
  function expectedClaimableEmissions() external pure returns (uint) {
    return 0;
  }
  
  function expectedClaimableEmissions(address account) external pure returns (uint) {
    account;
    return 0;
  }

  function qAdmin() external pure returns(address) {
    return address(0);
  }

  function veToken() external pure returns (address) {
    return address(0);
  }
  
  function swapContract() external pure returns (address) {
    return address(0);
  }

  function WETH() external pure returns (IERC20) {
    return IERC20(address(0));
  }

  function emissionsRound() external pure returns (uint, uint, uint) {
    return (0,0,0);
  }
  
  function emissionsRound(uint round_) external pure returns (uint, uint, uint) {
    round_;
    return (0,0,0);
  }

  function timeTillRoundEnd() external pure returns (uint) {
    return 0;
  }

  function stakedVeAtRound(address account, uint round) external pure returns (uint) {
    account;
    round;
    return 0;
  }

  function roundInterval() external pure returns (uint) {
    return 0;
  }

  function currentRound() external pure returns (uint) {
    return 0;
  }

  function lastClaimedRound() external pure returns (uint) {
    return 0;
  }

  function lastClaimedRound(address account) external pure returns (uint) {
    account;
    return 0;
  }

  function lastClaimedVeBalance() external pure returns (uint) {
    return 0;
  }

  function lastClaimedVeBalance(address account) external pure returns (uint) {
    account;
    return 0;
  }
  
  function claimedEmissions() external pure returns (uint) {
    return 0;
  }
  
  function claimedEmissions(address account) external pure returns (uint) {
    account;
    return 0;
  }

  function totalFeesAccrued() external pure returns (uint) {
    return 0;
  }

  function totalFeesClaimed() external pure returns (uint) {
    return 0;
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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
  
  error QA_MinCollateralRatioNotGreaterThanInit();

  error QA_OverThreshold(uint actual, uint expected);

  error QA_UnderThreshold(uint actual, uint expected);

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

  error QPO_Already_Set();
  
  error QPO_DIA_Key_Not_Found();
}