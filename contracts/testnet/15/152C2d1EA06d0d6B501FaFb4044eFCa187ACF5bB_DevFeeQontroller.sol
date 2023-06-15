// SPDX-License-Identifier: NONE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFeeEmissionsQontroller.sol";

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
    require(msg.sender == _OWNER, "not authorized");
    emit TransferOwnership(_OWNER, newOwner);
    _OWNER = newOwner;
  }

  function withdraw() public {
    require(msg.sender == _OWNER, "not authorized");
    payable(msg.sender).transfer(address(this).balance);
  }
  
  function withdraw(address tokenAddr) public {
    require(msg.sender == _OWNER, "not authorized");
    uint balance = IERC20(tokenAddr).balanceOf(address(this));
    IERC20(tokenAddr).transfer(msg.sender, balance);
  }

  function approve(address tokenAddr, address spender) public {
    require(msg.sender == _OWNER, "not authorized");
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