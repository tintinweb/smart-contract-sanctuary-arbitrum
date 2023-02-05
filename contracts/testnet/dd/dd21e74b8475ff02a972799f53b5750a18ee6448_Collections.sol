/**
 *Submitted for verification at Arbiscan on 2023-02-04
*/

// File: https://github.com/morality-network/ratings/Contracts/Models/Models.sol


pragma solidity >=0.7.0 <0.9.0;

library Models{

    struct SiteOwner{
        string Site;
        address Owner;
        bool Exists;
    }
	
	struct SiteOwnerRequest{
        string Site;
        address Owner;
        bool Exists;
        bool Confirmed;
    }

    struct Rating {
       address User;
       string Site;
       uint256 Field1;
       uint256 Field2;
       uint256 Field3;
       uint256 Field4;
       uint256 Field5;
    }

    struct AggregateRating {
       uint256 Field1Total;
       uint256 Field2Total;
       uint256 Field3Total;
       uint256 Field4Total;
       uint256 Field5Total;
       uint256 Count;
    }

    struct Index {
        uint256 Position;
        bool Exists;
    }

    struct RatingDto{
       uint256 Field1;
       uint256 Field2;
       uint256 Field3;
       uint256 Field4;
       uint256 Field5;
    }
}
// File: https://github.com/morality-network/ratings/Contracts/Interfaces/ISiteOwners.sol


pragma solidity >=0.7.0 <0.9.0;


// Contract to confirm a site ownership from
interface ISiteOwners{
    
    /**
    * Get the owner for a site if exists
    */
    function getSiteOwner(string memory site) external view returns(Models.SiteOwner memory siteOwner);
}
// File: https://github.com/morality-network/ratings/Contracts/Interfaces/ISiteRatings.sol


pragma solidity >=0.7.0 <0.9.0;

// Contract to confirm user/site rating counts for payouts
interface ISiteRatings{

    // Get total sites ratings 
    function getTotalSiteRatings(string memory site) external view returns(uint256 total);

    // Get a total user ratings 
    function getTotalUserRatings(address userAddress) external view returns(uint256 total);
}
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/RateCollections.sol


pragma solidity =0.8.7.0;





/**
 * @title Ratings
 * @dev Persists and manages ratings across the internet
 */

contract Collections is Ownable {
    // Supporting contract definitions
    ISiteRatings private _ratings;
    ISiteOwners private _siteOwners;
    IERC20 private _token;

    // Record of whats been paid out
    mapping(address => uint256) private _userPayouts;
    mapping(string => uint256) private _sitePayouts;
    mapping(address => uint256) private _payoutTimes;

    // Multiplier for fee
    uint256 private _multiplier = 1000000000; // 1 Gwei default
    uint256 private _maxPayoutPerPeriod = 100;
    uint256 private _minimumPayoutPeriod = 1 days;

    // The contract events
    event UserPayout(address indexed user, uint256 indexed payoutAmount, uint256 indexed multiplier, uint256 time);
    event SitePayout(address indexed user, string indexed site, uint256 indexed payoutAmount, uint256 multiplier, uint256 time);
    event MultiplierUpdatedEvent(uint256 indexed newMultiplier, uint256 time);

    constructor (address ratingsContractAddress, address siteOwnersContractAddress, address payoutTokenAddress){
        _ratings = ISiteRatings(ratingsContractAddress);
        _siteOwners = ISiteOwners(siteOwnersContractAddress);
        _token = IERC20(payoutTokenAddress);
    }

    //
    function lootUser() external{
        // Validate that user is out of cool down
        require(_validatePayoutTime(msg.sender), "Please wait for cooldown period to finish");

        // Add to payout time
        _payoutTimes[msg.sender] = getTimestamp();

        // Get the total ratings count for a user
        uint256 userRatingCount = _ratings.getTotalUserRatings(msg.sender);

        // Get the users paid out value
        uint256 paidOutValue = _userPayouts[msg.sender];
 
        // See if the user has already paid out
        require(paidOutValue <= userRatingCount, "Nothing to payout");

        // Find the amount to credit user
        uint256 payoutValue = userRatingCount - paidOutValue;

        // Add value to the user payouts
        _userPayouts[msg.sender] = _userPayouts[msg.sender] + payoutValue;

        // Send the value to the user
        uint256 realizedPayoutValue = payoutValue * _multiplier;
        _token.transfer(address(this), realizedPayoutValue);

        // Emit event
        emit UserPayout(msg.sender, realizedPayoutValue, _multiplier, getTimestamp());
    }

    function lootSite(string memory site) external{
        // Validate that user is out of cool down
        require(_validatePayoutTime(msg.sender), "Please wait for cooldown period to finish");

        // Check caller is owner
        Models.SiteOwner memory owner = _siteOwners.getSiteOwner(site);
        require(owner.Owner == msg.sender, "Only owner can loot site");

        // Get the total ratings count for a site
        uint256 siteRatingCount = _ratings.getTotalSiteRatings(site);

        // Get the sites paid out value
        uint256 paidOutValue = _sitePayouts[site];
    
        // See if the ite has already paid out
        require(paidOutValue >= siteRatingCount, "Nothing to payout");

        // Find the amount to credit site
        uint256 payoutValue = getWhatsOwedToSite(site);

        // Add value to the user payouts
        _sitePayouts[site] = siteRatingCount;

        // Send the value to the user
        uint256 realizedPayoutValue = payoutValue * _multiplier;
        _token.transfer(address(this), realizedPayoutValue);

        // Add to payout time
        _payoutTimes[msg.sender] = getTimestamp();

        // Emit event
        emit SitePayout(msg.sender, site, realizedPayoutValue, _multiplier, getTimestamp());
    } 

    function getWhatsOwedToUser(address owner) public view returns(uint256){
         // Get the total ratings count for a user
        uint256 userRatingCount = _ratings.getTotalUserRatings(owner);

        // Get the users paid out value
        uint256 paidOutValue = _userPayouts[msg.sender];

        // Find the amount to credit user
        return userRatingCount - paidOutValue;
    }

    function getWhatsOwedToSite(string memory site) public view returns(uint256){
        // Get the total ratings count for a site 
        uint256 siteRatingCount = _ratings.getTotalSiteRatings(site);

        // Get the sites paid out value
        uint256 paidOutValue = _sitePayouts[site];

        // Find the amount to credit site
        return siteRatingCount - paidOutValue;
    }

    function getSitesLootedTotal(string memory site) public view returns(uint256){
        return _sitePayouts[site] * _multiplier;
    }

    function getUsersLootedTotal(address user) public view returns(uint256){
        return _userPayouts[user] * _multiplier;
    }

    /**
    * Get the multiplier
    */
    function getMultiplier() public view returns(uint256 multiplier){
        return _multiplier;
    }

    /**
    * Set the multiplier. Only owner can set
    */
    function setMultiplier(uint256 newMultiplier) public onlyOwner{
         // Update the multiplier
         _multiplier = newMultiplier;

         // Fire update event
         emit MultiplierUpdatedEvent(newMultiplier, getTimestamp());
    }

    // Recover tokens to the owner
    function recoverTokens(IERC20 token, uint256 amount) public onlyOwner {
        // Ensure there is a balance in this contract for the token specified
        require(token.balanceOf(address(this)) >= amount, "Not enough of token in contract, reduce the amount");

        // Transfer the tokens from the contract to the owner
        token.transfer(owner(), amount);
    }

    // Check if cool down has finished
    function _validatePayoutTime(address user) public view returns(bool){
        // Get the last time a user was paid out
        uint256 lastPayoutTime = _payoutTimes[user];

        // Check the period has been exceeded
        if((lastPayoutTime + _minimumPayoutPeriod) > getTimestamp())
            return false;
        
        // If the period has exceeded cooldown, it has finished
        return true;
    }

    function getTimestamp() public view returns(uint256){
        return block.timestamp;
    }
}