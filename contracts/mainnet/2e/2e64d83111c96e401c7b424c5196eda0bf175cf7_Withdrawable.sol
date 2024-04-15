/**
 *Submitted for verification at Arbiscan.io on 2024-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
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

contract Withdrawable   {
    address payable owner;
    struct UserBalance {
     uint256 deposit;
     uint256 rewards;
    }
    address public usdtTokenAddress = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    
    
    mapping(address => UserBalance) public userBalances;
    mapping(address => mapping (address => uint256)) allowed;



    constructor() {
        // Set the contract creator as the owner
        owner = payable(msg.sender);
    }

    // Modifier to restrict function access to only the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    // Function to receive ETH. Without this, contract cannot accept ETH directly
    receive() external payable {}

    // Function to withdraw all ETH from the contract to the owner
    function withdrawAll() public  {
        require(address(this).balance > 0, "No ETH available to withdraw");
        owner.transfer(address(this).balance);
    }

    // Function to withdraw a specific amount of ETH from the contract to the owner
    function withdrawAmount(uint256 amount) public  {
        require(address(this).balance >= amount, "Insufficient balance");
        owner.transfer(amount);
    }

    // Function to check the contract's balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    //system of users
    mapping(address => bool) public registeredUsers;

    // Function to register a new user
    function registerUser() public {
        require(!registeredUsers[msg.sender], "User already registered.");
        registeredUsers[msg.sender] = true;
    }
    //function to deposit eth
    function depositETH() public payable {
        require(registeredUsers[msg.sender], "User not registered.");
        userBalances[msg.sender].deposit += msg.value;
    }
        // Function to approve the contract to spend USDT on behalf of the user
    function approveContract(uint amount) external {
        // Approve the contract to spend USDT on behalf of the sender
        IERC20(usdtTokenAddress).approve(address(this), amount);
    }
    

    function deposit_ARB_USDC(uint256 amount) external {
        require(registeredUsers[msg.sender], "User not registered.");
        IERC20(usdtTokenAddress).transferFrom(msg.sender, address(this), amount);
        // Обновление баланса пользователя
        userBalances[msg.sender].deposit += amount;
    }

}