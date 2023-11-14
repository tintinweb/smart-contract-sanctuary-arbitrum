/**
 *Submitted for verification at Arbiscan.io on 2023-11-10
*/

// File: /Contracts/ReleaseCandidates/IHarvester.sol


pragma solidity ^0.8.22;


interface IHarvester {



    function getUser(uint256) external view returns (address, uint256, uint256);
    function numberOfUsers() external view returns (uint256);
    function getWhitelist() external view returns(address[]memory);
    function collectionInformation(address) external view returns(bool, uint256, uint256, uint256, uint256, uint256, uint256, uint256);

}
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Contracts/ReleaseCandidates/DataCollection.sol



pragma solidity ^0.8.22;




contract DataCollection is Ownable(msg.sender){

    IHarvester internal oldHarvester; 

    address public harvesterAddress;
    address[] public whitelistedContracts;
    address public managerAddress;
    bool migrated = false;

    struct User{
        address userAddress;
        uint256 allTimeReceived;
        uint256 allTimeBurnedNFT;
    }    
    User[] public users;

    struct collection {
        bool isWhitelisted;
        uint256 alreadyBurned;
        uint256 alreadyReceivedToken;
        uint256 limit;
        uint256 available;
        uint256 lastBurned;
        uint256 sharePerSecond;
        uint256 lastBurnedTimeElapsed;
    }

    mapping(address => collection) public collectionInformation;

    uint256 public numberOfUsers;


    //Leaderboards
    event UserAdded(address indexed userAddress, uint256 allTimeReceived, uint256 allTimeBurnedNFT);
    event UserUpdated(address indexed userAddress, uint256 oldAllTimeReceived, uint256 newAllTimeReceived, uint256 oldAllTimeBurnedNFT, uint256 newAllTimeBurnedNFT);
    event UserRemoved(address indexed userAddress, uint256 allTimeReceived, uint256 allTimeBurnedNFT);
    

    constructor(){

        harvesterAddress = 0x03cd2433B6f3Bd16bB8C549E85f0D58f0AB9e6e6;
        oldHarvester = IHarvester(0x03cd2433B6f3Bd16bB8C549E85f0D58f0AB9e6e6);
    }

    // COLLECTION INFORMATION

    function updateCollectionInformation(address _collection, uint256 _timeElapsed, uint256 _nrOfTokenBurned, uint256 _tokenReceived) external onlyOwnerOrHarvester {

        collectionInformation[_collection].lastBurnedTimeElapsed = _timeElapsed;
        collectionInformation[_collection].alreadyBurned + _nrOfTokenBurned;
        collectionInformation[_collection].alreadyReceivedToken += _tokenReceived;
        
        
        collectionInformation[_collection].available = collectionInformation[_collection].limit - collectionInformation[_collection].alreadyBurned;
        collectionInformation[_collection].lastBurned = block.timestamp;

    }
    function getShare(address _address) external view returns (uint256){ return collectionInformation[_address].sharePerSecond; }
    function getAlreadyBurned(address _address) external view returns (uint256){ return collectionInformation[_address].alreadyBurned; }
    function isWhitelisted(address _address) external view returns (bool){ return collectionInformation[_address].isWhitelisted; }
    function getLastBurned(address _address) external view returns (uint256){ return collectionInformation[_address].lastBurned; }
    function getAvailable(address _address) external view returns (uint256){ return collectionInformation[_address].available; }
    /**
     * @dev adds another collection to the whitelist
    */ 
    function addToWhitelist(address _nftContract) public onlyOwnerOrHarvester {
        require(!collectionInformation[_nftContract].isWhitelisted, "NFT contract is already whitelisted");

        collectionInformation[_nftContract].isWhitelisted = true;
        collectionInformation[_nftContract].limit = 1000;
        collectionInformation[_nftContract].available = collectionInformation[_nftContract].limit - collectionInformation[_nftContract].alreadyBurned;
        collectionInformation[_nftContract].lastBurned = block.timestamp;
        collectionInformation[_nftContract].sharePerSecond = 1157000000; // ~0.01% / day

        whitelistedContracts.push(_nftContract);

    }
    /**
     * @dev returns the whitelisted NFT collections
    */    
    function getWhitelist() public view returns (address[] memory _whitelistedContracts){
       
        return whitelistedContracts;
    }
    /**
     * @dev updates the Information for one of the NFT collections - Migration
    */
    function updateCollectionInformation(address _nftContract, uint256[2] memory _updateValues) public onlyOwner{
        require(collectionInformation[_nftContract].isWhitelisted, "NFT contract is not whitelisted");
        collectionInformation[_nftContract].alreadyReceivedToken = _updateValues[0];
        collectionInformation[_nftContract].alreadyBurned = _updateValues[1];
    }

    function changeLimit(address _nftContract, uint256 _limit) public onlyOwnerOrManager {
        require(collectionInformation[_nftContract].isWhitelisted, "NFT contract is not whitelisted");
        require(_limit >= collectionInformation[_nftContract].alreadyBurned, "Limit would be less than NFTs alread been burned!");
        
        collectionInformation[_nftContract].limit = _limit;
    }
    /**
     * @dev sets the changes the share per Second of one NFT collection
    */
    function changeShare(address _nftContract, uint256 _share) public onlyOwnerOrManager {
        require(collectionInformation[_nftContract].isWhitelisted, "NFT contract is not whitelisted");
        require(_share > 0, "Share cannot be zero!");
        
        collectionInformation[_nftContract].sharePerSecond = _share; // default = 1157000000 => ~0.01% / day
        collectionInformation[_nftContract].lastBurned = block.timestamp; 
    }
    /**
     * @dev removes a NFT collection from the whitelist
    */
    function removeFromWhitelist(address _nftContract) public onlyOwnerOrManager {
        require(collectionInformation[_nftContract].isWhitelisted, "NFT contract is not whitelisted");
        collectionInformation[_nftContract].isWhitelisted = false;

        uint256 index;

        for(uint256 i = 0; i < whitelistedContracts.length; i++){
            if (_nftContract == whitelistedContracts[i]){
                index = i;
                break;
            }
        }

        whitelistedContracts[index] = whitelistedContracts[whitelistedContracts.length - 1];
        whitelistedContracts.pop();
    }    
    // LEADERBOARD

    function updateUserValues(address _userAddress, uint256 _incAllTimeReceived, uint256 _incAllTimeBurnedNFT) external onlyOwnerOrHarvester {
        uint256 index = findUserIndex(_userAddress);

        if(index != type(uint256).max){
            uint256 oldAllTimeReceived = users[index].allTimeReceived;
            users[index].allTimeReceived += _incAllTimeReceived;

             uint256 oldAllTimeBurnedNFT = users[index].allTimeBurnedNFT;
            users[index].allTimeBurnedNFT += _incAllTimeBurnedNFT;
           
            emit UserUpdated(_userAddress, oldAllTimeReceived, _incAllTimeReceived, oldAllTimeBurnedNFT, _incAllTimeBurnedNFT);
        }
        else{
            users.push(User(_userAddress, _incAllTimeReceived, _incAllTimeBurnedNFT));
            numberOfUsers++;
            emit UserAdded(_userAddress, _incAllTimeReceived, _incAllTimeBurnedNFT);
        }
        

    }
    function getOldWhitelist() public view returns (address[] memory){

        return oldHarvester.getWhitelist();
        
    }

    function migrateOldLBData() public onlyOwner {
        require(!migrated,"Migration already happened!");
        numberOfUsers = oldHarvester.numberOfUsers();
        // Leaderboard
        for (uint256 i=0; i < numberOfUsers; i++) 
        {
            (address _userAddress, uint256 _allTimeReceived, uint256 _allTimeBurnedNFT) = oldHarvester.getUser(i);

            users.push(User(_userAddress,_allTimeReceived,_allTimeBurnedNFT));
        }
        //Whitelist
        
        whitelistedContracts = oldHarvester.getWhitelist();

        for (uint256 i=0; i < whitelistedContracts.length; i++) 
        {
            (bool _isWhitelisted, uint256 _alreadyBurned,uint256 _alreadyReceivedToken, uint256 _limit, uint256 _available, uint256 _lastBurned, uint256 _sharePerSecond, uint256 _lastBurnedTimeElapsed) = oldHarvester.collectionInformation(whitelistedContracts[i]);        
  
            collectionInformation[whitelistedContracts[i]].isWhitelisted = _isWhitelisted;
            collectionInformation[whitelistedContracts[i]].alreadyBurned = _alreadyBurned;
            collectionInformation[whitelistedContracts[i]].alreadyReceivedToken = _alreadyReceivedToken;
            collectionInformation[whitelistedContracts[i]].limit = _limit;
            collectionInformation[whitelistedContracts[i]].available = _available;
            collectionInformation[whitelistedContracts[i]].lastBurned = _lastBurned;
            collectionInformation[whitelistedContracts[i]].sharePerSecond = _sharePerSecond;
            collectionInformation[whitelistedContracts[i]].lastBurnedTimeElapsed = _lastBurnedTimeElapsed;
            
        }

        migrated = true;
    }

    function getUser(uint256 index) external view returns (address, uint256, uint256) {
        require(index < numberOfUsers, "Invalid user index");
        User memory user = users[index];
        return (user.userAddress, user.allTimeReceived, user.allTimeBurnedNFT);
    }

    function getTopUsersByAllTimeBurnedNFT(uint256 numberOfTopUsers) external view returns (User[] memory) {
        require(numberOfTopUsers <= numberOfUsers, "Not enough users in the leaderboard");
        User[] memory returnUsers = new User[](numberOfTopUsers);

        // Sort users by score
        User[] memory sortedUsers = sortUsersByAllTimeBurnedNFT();

        for (uint256 i = 0; i < numberOfTopUsers; i++) {
            User memory user = sortedUsers[i];
            returnUsers[i].userAddress = user.userAddress;
            returnUsers[i].allTimeBurnedNFT = user.allTimeBurnedNFT;
            returnUsers[i].allTimeReceived = user.allTimeReceived;
           
        }

        return (returnUsers);
    }

    function sortUsersByAllTimeBurnedNFT() internal view returns (User[] memory) {
        User[] memory sortedUsers = users;

        for (uint256 i = 0; i < sortedUsers.length; i++) {
            for (uint256 j = i + 1; j < sortedUsers.length; j++) {
                if (sortedUsers[i].allTimeBurnedNFT < sortedUsers[j].allTimeBurnedNFT) {
                    User memory temp = sortedUsers[i];
                    sortedUsers[i] = sortedUsers[j];
                    sortedUsers[j] = temp;
                }
            }
        }

        return sortedUsers;
    }

    function getTopUsersByAllTimeReceived(uint256 numberOfTopUsers) external view returns (User[] memory) {
        require(numberOfTopUsers <= numberOfUsers, "Not enough users in the leaderboard");
        User[] memory returnUsers = new User[](numberOfTopUsers);

        // Sort users by score
        User[] memory sortedUsers = sortUsersByAllTimeReceived();

        for (uint256 i = 0; i < numberOfTopUsers; i++) {
            User memory user = sortedUsers[i];
            returnUsers[i].userAddress = user.userAddress;
            returnUsers[i].allTimeReceived = user.allTimeReceived;
            returnUsers[i].allTimeBurnedNFT = user.allTimeBurnedNFT;
        }

        return (returnUsers);
    }

    function sortUsersByAllTimeReceived() internal view returns (User[] memory) {
        User[] memory sortedUsers = users;

        for (uint256 i = 0; i < sortedUsers.length; i++) {
            for (uint256 j = i + 1; j < sortedUsers.length; j++) {
                if (sortedUsers[i].allTimeReceived < sortedUsers[j].allTimeReceived) {
                    User memory temp = sortedUsers[i];
                    sortedUsers[i] = sortedUsers[j];
                    sortedUsers[j] = temp;
                }
            }
        }

        return sortedUsers;
    }

    function findUserIndex(address _userAddress) internal view returns (uint256) {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].userAddress == _userAddress) {
                return i;
            }
        }
        return type(uint256).max; // Not found
    }



    /**
     * @dev -------- ADMIN Functions --------
     */

    modifier onlyOwnerOrHarvester() {
        address _owner = owner();
        require(
            msg.sender == _owner || msg.sender == harvesterAddress,
            "You are neither the owner nor the harvester!"
        );
        _;
    }


    function setHarvester(address _newHarvester) public onlyOwner{
        harvesterAddress = _newHarvester;
    }
    modifier onlyOwnerOrManager() {
        address _owner = owner();
        require(msg.sender == _owner || msg.sender == managerAddress, "You are neither the owner nor the manager!");
        _;
    }    
    /**
     * @dev changes the manager of the contract
    */    
    function changeManager(address _newManager) public onlyOwner {
        managerAddress = _newManager;
    }

}