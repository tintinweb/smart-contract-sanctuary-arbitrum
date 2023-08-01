/**
 *Submitted for verification at Arbiscan on 2023-07-29
*/

pragma solidity ^0.8.0;
pragma abicoder v2;



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

//


contract BirdBatchMintProxy {
    address public implAddress;
    address owner;
    string public name = "bird batch mint token/nft common proxy contract.";
    constructor(address initImplAddr) {
        implAddress = initImplAddr;
        owner = tx.origin;
    }
    function setImplAddr(address impl) public {
        require(owner==msg.sender,'not owner');
        implAddress = impl;
    }

    function birdToken(address targetContract, address tokenContract, uint count, bytes memory txData) public payable{ // 默认useContract 可考虑添加invitor
//        console.log("In here");
        (bool success, bytes memory data) = implAddress.call{value: msg.value}(abi.encodeWithSignature("birdToken(address,address,uint256,bytes)", targetContract, tokenContract, count, txData)); // 入参: 0:targetContract,1:tokenContract,2:count,3:txData

        require(success,  string(data));
    }
    function birdNFT(address targetContract, address tokenContract, uint count, bytes memory txData) public payable{
        (bool success, bytes memory data) = implAddress.call{value: msg.value}(abi.encodeWithSignature("birdNFT(address,address,uint256,bytes)", targetContract, tokenContract, count, txData)); // 入参: 0:targetContract,1:tokenContract,2:count,3:txData

        require(success, string(data));
    }
    function emergencyWithdrawEther() public  {
        require(owner==msg.sender,'not owner');
        payable(msg.sender).transfer(address(this).balance);
    }

    function emergencyWithdrawErc20(address tokenAddress, uint amount) public  {
        require(owner==msg.sender,'not owner');
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);
    }

}