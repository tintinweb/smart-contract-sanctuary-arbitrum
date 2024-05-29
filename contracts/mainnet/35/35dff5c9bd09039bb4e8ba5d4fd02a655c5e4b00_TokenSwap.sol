/**
 *Submitted for verification at Arbiscan.io on 2024-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ISWAP {
    function enscript(uint256 value,address to)external;
    function swapToTicket(uint256 value) external ;
    function ticketToThis(uint256 value) external ;
    function swapFromTicket(uint256 value) external ;

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    function withdrawTo(address account, uint256 amount) external;

    function depositTo(address to) external payable;
    function withdraw(uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function ticketToThis(address src,address dst,uint256 amount) external; 
    }

contract TokenSwap {
    ISWAP public oldToken;
    ISWAP public ticketToken;
    ISWAP public newToken;
    ISWAP public thirdToken;
    address public multiNetPool;
    uint256 constant etherThreshold = 30 ether;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(
    ) {
        oldToken = ISWAP(0xB961cC81d18A41dd8bbFD40c39262D78FB6f9641);
        ticketToken = ISWAP(0xfFC3b4f7807092e1Aa8CE0966d11DbFdb3d2D014);
        newToken = ISWAP(0x205976c72802e7C7607ACC3b9D86E4151E93aa82);
        thirdToken = ISWAP(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    }

    function swapOldToNew(uint256 amount) external {
        require(oldToken.transferFrom(msg.sender, address(this), amount), "Transfer of old token failed");
        
        if ((etherThreshold > amount ) && (address(oldToken).balance > amount)){
            oldToken.approve(address(oldToken),amount);
            oldToken.withdraw(amount);
            (bool success, ) = address(newToken).call{value: amount}("");
            newToken.transfer(msg.sender, amount);
            require(success, "Deposit to third token failed"); 
        } else { 
            ticketToken.enscript(amount,address(this));
            ticketToken.approve(address(newToken), amount);
            newToken.ticketToThis(address(this),msg.sender, amount);
        }

    }



    receive() external payable {}
}