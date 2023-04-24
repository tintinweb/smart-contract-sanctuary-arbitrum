/**
 *Submitted for verification at Arbiscan on 2023-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

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

contract EsGMXEscrow {
    address public constant buyer = 0x55eA69f1af8be494c91c3d7d5655865E3Bc215A0;
    address public constant seller = 0xe0CFDd05393C473cbe26EF366893eaCeDAf29964;
    uint256 public constant gmxAmount = 204 * 10**18;
    uint256 public constant esGmxAmount = 453 * 10**18;
    address public constant gmxToken = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;
    address public constant esGmxToken = 0xf42Ae1D54fd613C9bb14810b0588FaAa09a426cA;

    enum State {AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, REFUNDED}
    State public currentState;

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer allowed");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller allowed");
        _;
    }

    modifier inState(State expectedState) {
        require(currentState == expectedState, "Invalid state");
        _;
    }

    constructor() {
        currentState = State.AWAITING_PAYMENT;
    }

    function depositPayment() external onlyBuyer inState(State.AWAITING_PAYMENT) {
        require(IERC20(gmxToken).transferFrom(buyer, address(this), gmxAmount), "Payment transfer failed");
        currentState = State.AWAITING_DELIVERY;
    }

    function completeTransaction() external onlySeller inState(State.AWAITING_DELIVERY) {
        uint256 buyerEsGmxBalance = IERC20(esGmxToken).balanceOf(buyer);
        require(buyerEsGmxBalance >= esGmxAmount, "Buyer does not have required esGMX balance");
        bool b = IERC20(gmxToken).transfer(seller, gmxAmount);
        require(b, "Payment transfer to seller failed");
        currentState = State.COMPLETE;
    }

    function refundBuyer() external onlyBuyer inState(State.AWAITING_DELIVERY) {
        bool b = IERC20(gmxToken).transfer(buyer, gmxAmount);
        require(b, "Refund transfer failed");
        currentState = State.REFUNDED;
    }
}