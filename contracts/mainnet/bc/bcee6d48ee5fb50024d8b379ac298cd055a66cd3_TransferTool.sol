/**
 *Submitted for verification at Arbiscan on 2023-06-13
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


pragma solidity ^0.8.17;



contract TransferTool {


    address public owner;

    constructor ()  payable{//添加payable,支持在创建合约的时候，value往合约里面传eth

        owner = msg.sender;

    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }


    //批量转账

    function transferEthsAvg(address[] memory _tos) payable public returns (bool) {//添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户

        require(_tos.length > 0);

        uint256 vv = msg.value/_tos.length;

        for(uint32 i=0;i<_tos.length;i++){

            payable(_tos[i]).transfer(vv);

        }

        return true;

    }




    function checkBalance() public view returns (uint) {

        return address(this).balance;

    }

    function withdraw(address _token_address) public isOwner returns (uint256 balance) {
        if(_token_address == address(0)){
            balance  = address(this).balance;
            payable(owner).transfer(balance);
        }else{
            balance = IERC20(_token_address).balanceOf(address(this));
            bool success = IERC20(_token_address).transfer(owner,balance);
            require(success, "transferTokensAvg failed");
        }
        

    }

    fallback () payable external {//添加payable,用于直接往合约地址转eth,如使用metaMask往合约转账

    }

    receive () payable external {//添加payable,用于直接往合约地址转eth,如使用metaMask往合约转账

    }

    function destroy() isOwner public {

        require(msg.sender == owner);

        selfdestruct(payable(owner));

    }


    function transferTokensAvg(address _token_address,address[] memory _tos,uint _v)public returns (bool){

        require(_tos.length > 0);

        uint256 vv = _v/_tos.length;

        for(uint i=0;i<_tos.length;i++){

            bool success = IERC20(_token_address).transferFrom(msg.sender,_tos[i],vv);
            require(success, "transferTokensAvg failed");

        }

        return true;

    }



}