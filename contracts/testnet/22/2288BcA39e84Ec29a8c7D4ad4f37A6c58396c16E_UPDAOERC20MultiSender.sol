/**
 *Submitted for verification at Arbiscan.io on 2023-10-31
*/

/**
 *Submitted for verification at Arbiscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** 
 __    __  _______   _______    ______    ______  
/  |  /  |/       \ /       \  /      \  /      \ 
$$ |  $$ |$$$$$$$  |$$$$$$$  |/$$$$$$  |/$$$$$$  |
$$ |  $$ |$$ |__$$ |$$ |  $$ |$$ |__$$ |$$ |  $$ |
$$ |  $$ |$$    $$/ $$ |  $$ |$$    $$ |$$ |  $$ |
$$ |  $$ |$$$$$$$/  $$ |  $$ |$$$$$$$$ |$$ |  $$ |
$$ \__$$ |$$ |      $$ |__$$ |$$ |  $$ |$$ \__$$ |
$$    $$/ $$ |      $$    $$/ $$ |  $$ |$$    $$/ 
 $$$$$$/  $$/       $$$$$$$/  $$/   $$/  $$$$$$/ 

https://weupdao.io/
*/


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

// File: contracts/updao/UPDAOERC20MultiSender.sol


pragma solidity ^0.8.18;

/** 
 __    __  _______   _______    ______    ______  
/  |  /  |/       \ /       \  /      \  /      \ 
$$ |  $$ |$$$$$$$  |$$$$$$$  |/$$$$$$  |/$$$$$$  |
$$ |  $$ |$$ |__$$ |$$ |  $$ |$$ |__$$ |$$ |  $$ |
$$ |  $$ |$$    $$/ $$ |  $$ |$$    $$ |$$ |  $$ |
$$ |  $$ |$$$$$$$/  $$ |  $$ |$$$$$$$$ |$$ |  $$ |
$$ \__$$ |$$ |      $$ |__$$ |$$ |  $$ |$$ \__$$ |
$$    $$/ $$ |      $$    $$/ $$ |  $$ |$$    $$/ 
 $$$$$$/  $$/       $$$$$$$/  $$/   $$/  $$$$$$/ 

https://weupdao.io/
*/



contract UPDAOERC20MultiSender  {

    string public toolName;

    /// @notice Addresses of super operators
    mapping(address => bool) public superOperators;

    /// Events
    /// @notice Emitted after super operator is updated
    event AuthorizedOperator(address indexed operator, address indexed holder);

    /// @notice Emitted after super operator is updated
    event RevokedOperator(address indexed operator, address indexed holder);

    /// @notice Requires sender to be contract super operator
    modifier isSuperOperator() {
        // Ensure sender is super operator
        require(superOperators[msg.sender], "Not super operator");
        _;
    }
    
    /// @notice 
    constructor() {
        toolName = "UPDAOERC20MultiSender";
        superOperators[msg.sender] = true;
    }
   

    function allowance(address _token) view public returns (uint){
        IERC20 token = IERC20(_token);
        return token.allowance(msg.sender,address(this));
    }


    function batch_transfer(address _token, address[] memory to, uint256 amount) public {
        IERC20 token = IERC20(_token);
        for (uint256 i = 0; i < to.length; i++) {
            token.transferFrom(msg.sender, to[i], amount);
        }
    }

    function batch_transfer_diffent_amount(address _token, address[] memory to, uint[] memory amount) public {
        IERC20 token = IERC20(_token);
        require(to.length == amount.length, "address.len must equal amount.len ");
        for (uint256 i = 0; i < to.length; i++) {
            token.transferFrom(msg.sender, to[i], amount[i]);
        }
    }

    /// @notice Able to receive ETH
    receive() external payable {}

    /**
     * Allow withdraw of ETH tokens from the contract
     */
    function withdrawETH(address recipient) public isSuperOperator {
        uint256 balance = address(this).balance;
        require(balance > 0, "balance is zero");
        payable(recipient).transfer(balance);
    }

     /// @notice Allows super operator to update super operator
    function authorizeOperator(address _operator) external isSuperOperator {
        superOperators[_operator] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

    /// @notice Allows super operator to update super operator
    function revokeOperator(address _operator) external isSuperOperator {
        superOperators[_operator] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

}