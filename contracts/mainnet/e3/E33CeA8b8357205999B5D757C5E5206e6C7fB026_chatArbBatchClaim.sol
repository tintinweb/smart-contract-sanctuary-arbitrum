/**
 *Submitted for verification at Arbiscan on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

interface IMessage {
    function sendMessageETH(string calldata _content) external payable;
}

 contract  MeaasgeItem {

     function send(address messageAddress,address ercAddress,address adr,string calldata content) public  payable {
         IMessage(messageAddress).sendMessageETH{value:msg.value}(content);
         IERC20(ercAddress).transfer(adr,IERC20(ercAddress).balanceOf(address(this)));
     }
    function destroy(address  adr) public
{ 
  selfdestruct(payable(adr)); 
} 

}

contract chatArbBatchClaim {

    uint public  idoEtherAmount = 0.0005 ether;
    address public messageAddress = 0x4ae71875395079425eAfb804b925E5d9F315C238;
    address public chatarbAddress = 0xb13bF254044db6831a079d5446c4836a381d3Ba8;



    function batchClaim (uint amount,string calldata content) public payable{
        require(msg.value == idoEtherAmount*amount,"Insufficient quantity");
        for(uint a;a < amount;a++){
            MeaasgeItem sendC = new MeaasgeItem();
            sendC.send{value:idoEtherAmount}(messageAddress,chatarbAddress,address(this),content);
            sendC.destroy(address(this));
        }
         IERC20(chatarbAddress).transfer(msg.sender,IERC20(chatarbAddress).balanceOf(address(this)));
    }

}