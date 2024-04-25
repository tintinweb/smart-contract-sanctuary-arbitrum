/**
 *Submitted for verification at Arbiscan.io on 2024-04-25
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: USDT.sol


pragma solidity ^0.8.25;


contract USDTMonthly{
    address public owner;
    uint256 public withdrawTimes = 0;
    uint256 public lastWithdrawTimestamp = 0;
    uint256 public constant WITHDRAW_MAX_TIMES = 18;
    uint256 public constant WITHDRAW_ONE_MONTH = 2592000;                 // 1 month
    uint256 public constant WITHDRAW_ALL_TIMESTAMP = 1893427200;          // 2030-01-01

    constructor() payable {
        owner = msg.sender;  
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Only the owner can call this function");
        _;
    }

    receive() external payable {}

    function getBlockInfo() public view returns(uint256 block_number,uint256 block_timestamp) {
        return (block.number,block.timestamp);
    }  

    function ETHWithdrawal() external onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");   
    }     

    event ERC20Withdraw(uint256 withdrawTimes,uint256 withdrawAmount,uint256 timestamp);

    function ERC20WithdrawMonthly(address tokenContract) external onlyOwner returns (bool) { 
        require(block.timestamp - lastWithdrawTimestamp >= WITHDRAW_ONE_MONTH,"Can only withdraw once per month");
        require(IERC20(tokenContract).balanceOf(address(this)) > 0,"Insufficient balance on the contract");
          
        uint256 amountToSend = IERC20(tokenContract).balanceOf(address(this)) / (WITHDRAW_MAX_TIMES - withdrawTimes);
        bool transferSuccess = IERC20(tokenContract).transfer(owner, amountToSend);

        if (transferSuccess) {
            withdrawTimes++;   
            lastWithdrawTimestamp = block.timestamp;   
            emit ERC20Withdraw(withdrawTimes,amountToSend,block.timestamp);       
        }

        return transferSuccess;        
    } 

    function ERC20WithdrawAllbyTimestamp(address tokenContract) external onlyOwner returns (bool) { 
        require(block.timestamp >= WITHDRAW_ALL_TIMESTAMP,"Withdraw time not reached");
        require(IERC20(tokenContract).balanceOf(address(this)) > 0,"Insufficient balance on the contract");

        return IERC20(tokenContract).transfer(owner, IERC20(tokenContract).balanceOf(address(this))); 
    }                    
}