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

// File: contracts/UserRatings.sol


pragma solidity =0.8.7.0;


// Contract to confirm user/subject user rating counts for payouts
interface IRatings{

    // Get total subject user ratings 
    function getTotalSubjectUsersRatings(address subjectUser) external view returns(uint256 total);

    // Get a total user ratings 
    function getTotalUsersRatedsRatings(address userAddress) external view returns(uint256 total);
}

/**
* @title Ratings
* @dev Persists and manages ratings across the internet
*/

contract UserRatings is Ownable, IRatings{

    struct Rating {
       address UserRated;
       address SubjectUser;
       uint256 Field1;
       uint256 Field2;
       uint256 Field3;
       uint256 Field4;
       uint256 Field5;
       uint256 DateRated;
    }

    struct AggregateRating {
       address SubjectUser;
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

    struct RatingBound{
        uint256 Min;
        uint256 Max;
    }

    struct RatingDefinition{
       RatingBound Field1Bound;
       RatingBound Field2Bound;
       RatingBound Field3Bound;
       RatingBound Field4Bound;
       RatingBound Field5Bound;
    }

    // All subject users total ratings (aggregate of individual ratings)
    AggregateRating[] private _allAggregateRatings;

    // Subject users total ratings
    mapping(address => Index) private _subjectUserAggregates;

    // All user/subject users ratings
    Rating[] private _allRatings;

    // Subject users individual rating indexes
    mapping(address => uint256[]) private _subjectUserRatingIndexes;
    mapping(address => uint256) private _subjectUserRatingCounts;

    // Users individual rating indexes
    mapping(address => uint256[]) private _userRatingIndexes;
    mapping(address => uint256) private _userRatingCounts;

    // Index mapping for user subject/users individual ratings
    mapping(address => mapping(address => Index)) private _userSubjectUserRatingsIndex;

    // The max page limit
    uint256 private _pageLimit = 50;

    // Rating settings
    RatingDefinition _definition = RatingDefinition(
        RatingBound(0,5),
        RatingBound(0,5),
        RatingBound(0,5),
        RatingBound(0,5),
        RatingBound(0,5)
    );

    // Events
    event AddedRating(address indexed subjectUser, address indexed userRating, uint256 rating1, uint256 rating2, uint256 rating3, uint256 rating4, uint256 rating5, uint256 time);
    event EditedRating(address indexed subjectUser, address indexed userRating, uint256 newRating1, uint256 newRating2, uint256 newRating3, uint256 newRating4, uint256 newRating5, uint256 time);
    event PageLimitUpdatedEvent(uint256 indexed newPageLimit, uint256 time);
    event RatingDefinitionUpdatedEvent(address indexed user, uint256 time);

    // Add a new or replace and existing rating
    function addRating(address subjectUser, RatingDto memory rating) external {
        // Validate bounds
        validateBounds(rating);

        // We check if there is already an index for this subjectUser/user
        Index memory userSubjectUserRatingIndex = _userSubjectUserRatingsIndex[msg.sender][subjectUser];

        // Map to correct model
        Rating memory mappedRating = _mapRatingDto(subjectUser, rating);

        // If it already exists then edit the existing
        if(userSubjectUserRatingIndex.Exists == true) 
            _editRating(subjectUser, mappedRating);

        // Otherwise add a new rating for site/user
        else _createRating(subjectUser, mappedRating);          
    }

    // Gets an aggregate rating for a subject user
    function getAggregateRating(address subjectUser) public view returns(AggregateRating memory aggregateRating){
        Index memory index = _subjectUserAggregates[subjectUser];
        
        if(!index.Exists)
            return aggregateRating;

        aggregateRating = _allAggregateRatings[index.Position];
    }

    // Gets a single rating for a user-subject user
	function getRating(address userRated, address subjectUser) public view returns(Rating memory rating){
		// Get the index of the user/site rating
        Index memory userIndex = _userSubjectUserRatingsIndex[userRated][subjectUser];
		
		require(userIndex.Exists, "No user-subject user rating exists");

        // Get the users existing rating for the site
        rating = _allRatings[userIndex.Position];

        return rating;
	}

    // Gets paged aggregate ratings for a site
    function getAggregateRatings(uint256 pageNumber, uint256 perPage) public view returns(AggregateRating[] memory aggregateRatings){
        // Validate page limit
        require(perPage <= _pageLimit, "Page limit exceeded");

        // Get the total amount remaining
        uint256 totalRatings = _allAggregateRatings.length;

        // Get the index to start from
        uint256 startingIndex = pageNumber * perPage;

        // The number of ratings that will be returned (to set array)
        uint256 remaining = totalRatings - startingIndex;
        uint256 pageSize = ((startingIndex+1)>totalRatings) ? 0 : (remaining < perPage) ? remaining : perPage;

        // Create the page
        AggregateRating[] memory pageOfRatings = new AggregateRating[](pageSize);

        // Add each item to the page
        uint256 pageItemIndex = 0;
        for(uint256 i = startingIndex;i < (startingIndex + pageSize);i++){
           
           // Get the rating 
           AggregateRating memory rating = _allAggregateRatings[i];

           // Add to page
           pageOfRatings[pageItemIndex] = rating;

           // Increment page item index
           pageItemIndex++;
        }

        return pageOfRatings;
    }

    // Get a page of users ratings 
    function getUsersRatedsRatings(address userAddress, uint256 pageNumber, uint256 perPage) public view returns(Rating[] memory ratings){
        // Validate page limit
        require(perPage <= _pageLimit, "Page limit exceeded");

        // Get the total amount remaining
        uint256 totalRatings = _userRatingCounts[userAddress];

        // Get the index to start from
        uint256 startingIndex = pageNumber * perPage;

        // The number of ratings that will be returned (to set array)
        uint256 remaining = totalRatings - startingIndex;
        uint256 pageSize = ((startingIndex+1)>totalRatings) ? 0 : (remaining < perPage) ? remaining : perPage;

        // Create the page
        Rating[] memory pageOfRatings = new Rating[](pageSize);

        // Add each item to the page
        uint256 pageItemIndex = 0;
        for(uint256 i = startingIndex;i < (startingIndex + pageSize);i++){
           // Get the rating index
           uint256 index = _userRatingIndexes[userAddress][i];

           // Get the rating 
           Rating memory rating = _allRatings[index];

           // Add to page
           pageOfRatings[pageItemIndex] = rating;

           // Increment page item index
           pageItemIndex++;
        }

        return pageOfRatings;
    }

    // Get a page of a subject user ratings - pageNumber starts from 0
    function getSubjectUserRatings(address subjectUser, uint256 pageNumber, uint256 perPage) public view returns(Rating[] memory ratings){
        // Validate page limit
        require(perPage <= _pageLimit, "Page limit exceeded");

        // Get the total amount remaining
        uint256 totalRatings = _subjectUserRatingCounts[subjectUser];

        // Get the index to start from
        uint256 startingIndex = pageNumber * perPage;

        // The number of ratings that will be returned (to set array)
        uint256 remaining = totalRatings - startingIndex;
        uint256 pageSize = ((startingIndex+1)>totalRatings) ? 0 : (remaining < perPage) ? remaining : perPage;

        // Create the page
        Rating[] memory pageOfRatings = new Rating[](pageSize);

        // Add each item to the page
        uint256 pageItemIndex = 0;
        for(uint256 i = startingIndex;i < (startingIndex + pageSize);i++){
           // Get the rating index
           uint256 index = _subjectUserRatingIndexes[subjectUser][i];

           // Get the rating
           Rating memory rating = _allRatings[index];

           // Add to page
           pageOfRatings[pageItemIndex] = rating;

           // Increment page item index
           pageItemIndex++;
        }

        return pageOfRatings;
    }

    // Get a page ratings - pageNumber starts from 0
    function getRatings(uint256 pageNumber, uint256 perPage) public view returns(Rating[] memory ratings){
        // Validate page limit
        require(perPage <= _pageLimit, "Page limit exceeded");

        // Get the total amount remaining
        uint256 totalRatings = getTotalRatings();

        // Get the index to start from
        uint256 startingIndex = pageNumber * perPage;

        // The number of ratings that will be returned (to set array)
        uint256 remaining = totalRatings - startingIndex;
        uint256 pageSize = ((startingIndex+1)>totalRatings) ? 0 : (remaining < perPage) ? remaining : perPage;

        // Create the page
        Rating[] memory pageOfRatings = new Rating[](pageSize);

        // Add each item to the page
        uint256 pageItemIndex = 0;
        for(uint256 i = startingIndex;i < (startingIndex + pageSize);i++){
           // Get the rating
           Rating memory rating = _allRatings[i];

           // Add to page
           pageOfRatings[pageItemIndex] = rating;

           // Increment page item index
           pageItemIndex++;
        }

        return pageOfRatings;
    }

    // Get total subject user ratings 
    function getTotalSubjectUsersRatings(address subjectUser) external override view returns(uint256 total){
        return _subjectUserRatingCounts[subjectUser];
    }

    // Get a total user ratings 
    function getTotalUsersRatedsRatings(address userAddress) external override view returns(uint256 total){
        return _userRatingCounts[userAddress];
    }

    // Get total ratings made
    function getTotalRatings() public view returns(uint256 total){
        return _allRatings.length;
    }

    // Get total aggregate ratings made
    function getTotalAggregateRatings() public view returns(uint256 total){
        return _allAggregateRatings.length;
    }

    /**
    * Get the page limit
    */
    function getPageLimit() public view returns(uint256 pageLimit){
        return _pageLimit;
    }

    /**
    * Validate rating field bounds
    */
    function validateBounds(RatingDto memory rating) public view returns(bool){
        require(rating.Field1 >= _definition.Field1Bound.Min, 'Field 1 is not within bounds (less than expected)');
        require(rating.Field1 <= _definition.Field1Bound.Max, 'Field 1 is not within bounds (more than expected');

        require(rating.Field2 >= _definition.Field2Bound.Min, 'Field 2 is not within bounds (less than expected)');
        require(rating.Field2 <= _definition.Field2Bound.Max, 'Field 2 is not within bounds (more than expected');

        require(rating.Field3 >= _definition.Field3Bound.Min, 'Field 3 is not within bounds (less than expected)');
        require(rating.Field3 <= _definition.Field3Bound.Max, 'Field 3 is not within bounds (more than expected');

        require(rating.Field4 >= _definition.Field4Bound.Min, 'Field 4 is not within bounds (less than expected)');
        require(rating.Field4 <= _definition.Field4Bound.Max, 'Field 4 is not within bounds (more than expected');

        require(rating.Field5 >= _definition.Field5Bound.Min, 'Field 5 is not within bounds (less than expected)');
        require(rating.Field5 <= _definition.Field5Bound.Max, 'Field 5 is not within bounds (more than expected)');

        return true;
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

    /**
    * Set the rating min/max values. Only owner can set
    */
    function setRatingDefinition(RatingDefinition memory definition) public onlyOwner{
        // Update the definition
        _definition = definition;

         // Fire update event
        emit RatingDefinitionUpdatedEvent(msg.sender, getTimestamp());
    }

    /**
    * Get the rating min/max values. Only owner can set
    */
    function getRatingDefinition() public view returns(RatingDefinition memory){
        return _definition;
    }

    // Helpers

    // Create a new rating for a subject user/user
    function _createRating(address subjectUser, Rating memory rating) private {
        // Update the total rating for the subject user
        _updateSiteAggregate(subjectUser, rating);

        // Save the rating
        _allRatings.push(rating);

       // Add to site rating indexes
       uint256[] storage siteRatingIndexes = _subjectUserRatingIndexes[subjectUser];
       siteRatingIndexes.push(_allRatings.length-1);

       // Update the length of the ratings
       _subjectUserRatingCounts[subjectUser] = siteRatingIndexes.length;

       // Add to user rating indexes
       uint256[] storage userRatings = _userRatingIndexes[msg.sender];
       userRatings.push(_allRatings.length-1);

       // Update the length of the ratings
       _userRatingCounts[msg.sender] = userRatings.length;

       // Add index
       Index memory userSubjectUserIndex = Index(_allRatings.length-1, true);
       _userSubjectUserRatingsIndex[msg.sender][subjectUser] = userSubjectUserIndex;

       // Fire event
       emit AddedRating(subjectUser, msg.sender, rating.Field1, rating.Field2, rating.Field3, rating.Field4, rating.Field5, getTimestamp());
    }

    // Create a new rating for a subject user/user
    function _editRating(address subjectUser, Rating memory rating) private {
        // Get the index of the user/subject user rating
        Index memory userIndex = _userSubjectUserRatingsIndex[msg.sender][subjectUser];

        // Get the users existing rating for the site
        uint256 oldRatingIndex = _userRatingIndexes[msg.sender][userIndex.Position];
        Rating storage oldRating = _allRatings[oldRatingIndex];

        // Remove old value
        _removeSiteAggregate(subjectUser, oldRating);

        // Update the total rating for the site
        _updateSiteAggregate(subjectUser, rating);

       // Update user rating
       oldRating.Field1 = rating.Field1;
       oldRating.Field2 = rating.Field2;
       oldRating.Field3 = rating.Field3;
       oldRating.Field4 = rating.Field4;
       oldRating.Field5 = rating.Field5;
       oldRating.DateRated = getTimestamp();

       // Fire event
       emit EditedRating(subjectUser, msg.sender, rating.Field1, rating.Field2, rating.Field3, rating.Field4, 
            rating.Field5, getTimestamp());
    }

    // Update the total ratings for a subject user
    function _updateSiteAggregate(address subjectUser, Rating memory rating) private{
        // Get index
        Index memory existingIndex = _subjectUserAggregates[subjectUser];

        // Update if exists already
        if(existingIndex.Exists){
            // Get the aggregate to update
            AggregateRating storage aggregateRating = _allAggregateRatings[existingIndex.Position];

            // Update the aggregate with extra info
            aggregateRating.SubjectUser = subjectUser;
            aggregateRating.Field1Total += rating.Field1;
            aggregateRating.Field2Total += rating.Field2;
            aggregateRating.Field3Total += rating.Field3;
            aggregateRating.Field4Total += rating.Field4;
            aggregateRating.Field5Total += rating.Field5;

            // Up the answer count
            aggregateRating.Count += 1;
        }
        else{
            // Create the aggregate
            AggregateRating memory aggregateRating = AggregateRating(
                subjectUser, rating.Field1, rating.Field2, rating.Field3, rating.Field4, rating.Field5, 1);

            // Add to all
            _allAggregateRatings.push(aggregateRating);

            // Add to indexes
            Index memory index = Index(_allAggregateRatings.length-1, true);
            _subjectUserAggregates[subjectUser] = index;
        }
    }

    // Update the total ratings for a site
    function _removeSiteAggregate(address subjectUser, Rating memory oldRating) private{
        // Get index
        Index memory index = _subjectUserAggregates[subjectUser];
        require(index.Exists, "Index doesn't exist");

        // Get the aggregate to update
        AggregateRating storage aggregateRating = _allAggregateRatings[index.Position];

        aggregateRating.Field1Total -= oldRating.Field1;
        aggregateRating.Field2Total -= oldRating.Field2;
        aggregateRating.Field3Total -= oldRating.Field3;
        aggregateRating.Field4Total -= oldRating.Field4;
        aggregateRating.Field5Total -= oldRating.Field5;

        aggregateRating.Count -= 1;
    }

    // Map CreateRating to Rating
    function _mapRatingDto(address subjectUser, RatingDto memory createRating) private view returns(Rating memory rating){
         return Rating(
            msg.sender,
            subjectUser,
            createRating.Field1,
            createRating.Field2,
            createRating.Field3,
            createRating.Field4,
            createRating.Field5,
            getTimestamp()
         );
    }
    
    function getTimestamp() public view returns(uint256){
        return block.timestamp;
    }
}