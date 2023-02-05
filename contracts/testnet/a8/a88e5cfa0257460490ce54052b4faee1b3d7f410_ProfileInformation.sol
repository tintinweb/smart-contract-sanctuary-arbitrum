/**
 *Submitted for verification at Arbiscan on 2023-02-04
*/

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

// File: contracts/ProfileInformation.sol


pragma solidity =0.8.7.0;


contract ProfileInformation is Ownable{

    struct AccountDetails{
        string ProfilePictureUrl;
        string FirstName;
        string LastName;
        string Alias;
        string Country;
        uint256 LastUpdated;
    }

    struct AccountDetailsDto{
        string ProfilePictureUrl;
        string FirstName;
        string LastName;
        string Alias;
        string Country;
    }

    struct Index{
        bool Exists;
        uint256 Position;
    }

    // Indexes of profile information 2 their index in the collection
    mapping(address => Index) private _accountDetailIndexes;

    // All the account details
    AccountDetails[] _accountDetails;

    // The max page limit
    uint256 private _pageLimit = 50;

    // Events
    event AccountDetailsAdded(address indexed user,string ProfilePictureUrl, string FirstName, string LastName, string indexed Alias, string Country, uint256 indexed time);
    event AccountDetailsEdited(address indexed user, string ProfilePictureUrl, string FirstName, string LastName, string indexed Alias, string Country, uint256 indexed time);
    event PageLimitUpdatedEvent(uint256 indexed newPageLimit, uint256 time);

    // Update the callers account details
    function updateAccountDetails(AccountDetailsDto memory details) public{
        // Try to get the users items index
        Index memory existingIndex =  _accountDetailIndexes[msg.sender];
        
        // If the index doesn't exist then we add
        if(!existingIndex.Exists)
        {
            // Add and add to new indexs
            _accountDetails.push(_mapAccountDetailsDto(details));
            _accountDetailIndexes[msg.sender] = Index(true, _accountDetails.length - 1);

            // Fire event
            emit AccountDetailsAdded(msg.sender, details.ProfilePictureUrl, details.FirstName, details.LastName, details.Alias, details.Country, getTimestamp());
        }
        // If the index already exists then we update
        else 
        {
            // Update value at index
            _accountDetails[existingIndex.Position] = _mapAccountDetailsDto(details);

            // Fire event
            emit AccountDetailsEdited(msg.sender, details.ProfilePictureUrl, details.FirstName, details.LastName, details.Alias, details.Country, getTimestamp());
        }
    }

    /**
    * Set the page limit. Only owner can set
    */
    function setPageLimit(uint256 newPageLimit) public onlyOwner{
         // Update the extension
         _pageLimit = newPageLimit;

         // Fire update event
         emit PageLimitUpdatedEvent(newPageLimit, getTimestamp());
    }

    function getAccountDetail(address user) public view returns(AccountDetails memory){
         // Try to get the users items index
        Index memory existingIndex =  _accountDetailIndexes[user];
        
        // Check exists
        require(existingIndex.Exists, 'Account details dont exist for specified user');

        // Return the account details
        return _accountDetails[existingIndex.Position];
    }

     function getUsersAccountDetail(address[] memory users) public view returns(AccountDetails[] memory){
         // Validate page limit
        require(users.length <= _pageLimit, "Page limit exceeded");

        // Create the page
        AccountDetails[] memory page = new AccountDetails[](users.length);

        for(uint256 i = 0;i<users.length;i++)
        {
            // Get the user
            address user = users[i];

            // Try to get the users items index
            Index memory existingIndex =  _accountDetailIndexes[user];
        
            // Check exists
            require(existingIndex.Exists, 'Account details dont exist for specified user');

            // Get the item at index
            AccountDetails memory accountDetail =_accountDetails[existingIndex.Position];

            // Add to page
            page[i] = accountDetail;
        }

        // Return the page of account details
        return page;
    }

    /**
    * Get the page limit
    */
    function getPageLimit() public view returns(uint256 pageLimit){
        return _pageLimit;
    }

    // Get total users account details created
    function getTotalUsersAccountDetails() public view returns(uint256 total){
        return _accountDetails.length;
    }

    function getAccountDetails(uint256 pageNumber, uint256 perPage) public view returns(AccountDetails[] memory accountDetails){
        // Validate page limit
        require(perPage <= _pageLimit, "Page limit exceeded");

        // Get the total amount remaining
        uint256 totalAccountDetails = getTotalUsersAccountDetails();

        // Get the index to start from
        uint256 startingIndex = pageNumber * perPage;

        // The number of account details that will be returned (to set array)
        uint256 remaining = totalAccountDetails - startingIndex;
        uint256 pageSize = ((startingIndex+1)>totalAccountDetails) ? 0 : (remaining < perPage) ? remaining : perPage;

        // Create the page
        AccountDetails[] memory pageOfRatings = new AccountDetails[](pageSize);

        // Add each item to the page
        uint256 pageItemIndex = 0;
        for(uint256 i = startingIndex;i < (startingIndex + pageSize);i++){
           // Get the account detail
           AccountDetails memory rating = _accountDetails[i];

           // Add to page
           pageOfRatings[pageItemIndex] = rating;

           // Increment page item index
           pageItemIndex++;
        }

        return pageOfRatings;
    }

    function _mapAccountDetailsDto(AccountDetailsDto memory accountDetailDto) private view returns(AccountDetails memory){
          return AccountDetails(
             accountDetailDto.ProfilePictureUrl,
             accountDetailDto.FirstName,
             accountDetailDto.LastName,
             accountDetailDto.Alias,
             accountDetailDto.Country,
             getTimestamp()
          );
    }

    function getTimestamp() public view returns(uint256){
        return block.timestamp;
    }
}