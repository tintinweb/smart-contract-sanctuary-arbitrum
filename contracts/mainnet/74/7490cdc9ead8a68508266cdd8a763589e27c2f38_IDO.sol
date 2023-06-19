/**
 *Submitted for verification at Arbiscan on 2023-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

  
 
// Import ERC20 interface
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

/**
 * @title IDO contract
 * @dev This contract enables users to participate in an IDO for an ERC20 token and also receive referral bonuses.
 */
contract IDO {
    // Address of the ERC20 token being sold
    address public tokenAddress;

    // Price of token in ETH
    uint256 public tokenPrice;

    // Total supply of tokens available for sale
    uint256 public totalTokenSupply;

    // Number of tokens sold so far
    uint256 public tokensSold;

    // Is Open
    bool public isOpen;
    
    // Address of the owner of the contract (IDO creator)
    address public owner;

    // Map of addresses and their corresponding referral address
    mapping(address => address) referrals;

    // Referral bonus percentage (10%)
    uint256 public REFERRAL_BONUS = 10;

    // Event triggered when a user purchases tokens
    event TokenPurchase(address indexed purchaser, uint256 amount);

    // Event triggered when a user refers another user
    event Referral(address indexed referrer, address indexed referee);

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    /**
     * Constructor
     * @param _tokenAddress Address of the ERC20 token being sold
     * @param _tokenPrice Price of token in ETH  1000000000
     * @param _totalTokenSupply Total supply of tokens available for sale  300000000000000000000000000000
     */

    constructor(address _tokenAddress, uint256 _tokenPrice, uint256 _totalTokenSupply) {
        tokenAddress = _tokenAddress;
        tokenPrice = _tokenPrice;
        totalTokenSupply = _totalTokenSupply;
        owner = msg.sender;
    }

    function setTokenPrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
    }

    function setTotalTokenSupply(uint256 _newTotalTokenSupply) public onlyOwner {
        totalTokenSupply = _newTotalTokenSupply;
    }

    function open() public onlyOwner {
        isOpen = true; 
    }

    function close() public onlyOwner {
        isOpen = false;
    }



    /**
     * Function for users to purchase tokens
     * @param _tokenAmount Amount of tokens to purchase
     * @param _referrer Referral address (optional)
     */
    function buyTokens(uint256 _tokenAmount, address _referrer) public payable {
        // Ensure there are still tokens available for sale
        require(tokensSold + _tokenAmount <= totalTokenSupply, "Not enough tokens available");

        require(isOpen == true,"ido don't start");
        
        // Calculate the total cost in ETH
        uint256 totalCost = _tokenAmount * tokenPrice / 10 ** 18;

        // Ensure the user has sent enough ETH with their transaction
        require(msg.value >= totalCost, "Insufficient ETH sent");

        // Transfer the tokens to the buyer
        IERC20(tokenAddress).transfer(msg.sender, _tokenAmount);

        // Update the number of tokens sold
        tokensSold += _tokenAmount;

        // Trigger the TokenPurchase event
        emit TokenPurchase(msg.sender, _tokenAmount);

        // If a referral address was provided and is valid
        if (_referrer != address(0) && _referrer != msg.sender) {
            // Store the referral relationship
            referrals[msg.sender] = _referrer;

            // Calculate the referral bonus amount
            uint256 referralBonus = (totalCost * REFERRAL_BONUS) / 100;

            // Send the referral bonus to the referrer
            payable(_referrer).transfer(referralBonus);

            // Trigger the Referral event
            emit Referral(_referrer, msg.sender);
        }
    }

    /**
     * Function for users to check their referral status
     * @param _user Address of the user
     * @return The address of the user's referrer (if any)
     */
    function getReferralStatus(address _user) public view returns (address) {
        return referrals[_user];
    }

    /**
     * Function for the owner to withdraw any remaining unsold tokens
     */
    function withdrawUnsoldTokens() public {
        // Ensure only the contract owner can call this function
        require(msg.sender == owner, "Only the contract owner can call this function");

        // Calculate the number of unsold tokens
        uint256 unsoldTokens = totalTokenSupply - tokensSold;

        // Transfer the unsold tokens to the owner
        IERC20(tokenAddress).transfer(owner, unsoldTokens);
    }

    /**
     * Function for the owner to withdraw any remaining unsold tokens
     */
    function withdraw() public {
        require(msg.sender == owner, "Only the contract owner can call this function");
        payable(msg.sender).transfer(address(this).balance);
    }
    
}