/**
 *Submitted for verification at Arbiscan on 2022-05-13
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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

// File: contracts/01_Prism_Project.sol


pragma solidity 0.8.1;




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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

contract PrismProjects is Ownable {
  
 using Strings for uint256;

  /**
  @dev global
 */
  address public prismTokenContract;
  uint256 public nextProjectId = 1;
  uint256 public nextCollectionId = 1;
  string public collectionBaseURI;
  string public projectBaseURI;
  enum AssetType { MASTER, TRAIT, OTHER}
  
  /**
  @dev mappings
 */
  
  //Project mappings
  mapping (uint256 => Project) public projects;
  mapping (address => uint256[]) private addressToProjectIds;
  mapping (uint256 => uint256[]) private projectIdToCollectionIds;  
  
  //Collection mappings
  mapping(uint256 => Collection) public collections;
  mapping(address => uint256[]) private addressToCollectionIds;
  


  /**
  @dev constructor
 */

  constructor(
  ){
  }

  /**
  @dev structs
 */
  
  struct Project {
    uint256 id;
    string name;
    address chef;
    string[] traitTypes;
  }

  struct Collection {
    string name;
    uint256 id;
    uint256 projectId;
    uint256 royalties; // in 1000th e.g. 1000 for 10%
    address manager; // gets royalties 
    uint256 invocations;
    uint256 maxInvocations;
    AssetType assetType;
    bool paused;
  }

  /**
  @dev modifiers
 */

  modifier onlyChef(uint256 _projectId) {
      require(projects[_projectId].chef == _msgSender() || _msgSender() == owner() , "Must own token");
    _;
  }

  modifier onlyOpenCollection(uint256 _id, uint256 _amount) {
    require(collections[_id].invocations + _amount <= collections[_id].maxInvocations, "Must not exceed max invocations");
    require(!collections[_id].paused || _msgSender() == collections[_id].manager || _msgSender() == owner() , "Purchases must not paused");
    _;
  }


  /**
  @dev helpers 
 */

  function addBaseURI(string memory _projectURI, string memory _collectionURI)
    public
    onlyOwner
  {
    projectBaseURI = _projectURI;
    collectionBaseURI = _collectionURI;
  }

  /**
  @dev project functions
 */

  function createProject(
      string memory _name,
      address _chef,
      string[] memory _traitTypes
    ) public 
    {
      Project memory project;
      project.id = nextProjectId;
      project.name = _name;
      project.chef = _chef;
      project.traitTypes = _traitTypes;
      projects[nextProjectId] = project;
      emit ProjectCreated(nextProjectId, _name, _chef, _traitTypes);
      addressToProjectIds[_msgSender()].push(nextProjectId);
      nextProjectId++;  
    }

  function editProject( uint256 _id, string memory _name, address _chef, string[] memory _traitTypes) 
  public
  onlyChef(_id)
  {
    require(address(0) != projects[_id].chef, "Project must exist");
    projects[_id].name = _name;
    projects[_id].chef = _chef;
    projects[_id].traitTypes = _traitTypes;

  }


  // if traitType is empty it is master or standard assetType and therefore needs to turn true
  // if traitType is not empty it needs to be part of the string specified in projects

  function checkTraitType(uint256 _id, string calldata _traitType)
  external
  view 
  returns(bool)
  {
    bytes32 traitType_ = keccak256(abi.encodePacked(_traitType));
    bytes memory _typeString = bytes(_traitType);
    string[] memory allTypes = projects[_id].traitTypes;

    if (_typeString.length == 0){
      return true;} 
    else {
      for (uint256 i= 0; i < allTypes.length; i++) {
        bytes32 _typ = keccak256(abi.encodePacked(allTypes[i]));
        if(_typ == traitType_){
          return true;
        }
      }   
    }
    return false;
  }




  /**
  @dev view functions
 */

  function projectURI(uint256 _projectId)
  public
  view
  returns (string memory)
  {
    return string(abi.encodePacked(
      projectBaseURI, Strings.toString(_projectId)));
  }

  function chefToProjects(address _chef)
  public
  view
  returns (uint256[] memory)
  { 
  return addressToProjectIds[_chef];
  }

  function viewProjectChef(uint256 _id)
  external
  view
  returns (address)
  { 
  return projects[_id].chef;
  }

  function viewProjectTraitTypes(uint256 _projectId)
  external
  view
  returns (string[] memory)
  { 
  return projects[_projectId].traitTypes;
  }


  /**
  @dev collection functions
 */

  function createCollection(
    string memory _name,
    uint256 _maxInvocations,
    uint256 _projectId,
    address _manager,
    AssetType _assetType,
    uint256 _royalties // needs to be in 1000: 5% = 500

  ) 
  public 
  onlyChef(_projectId)
  {
    Collection memory collection;
    collection.name = _name;
    collection.maxInvocations = _maxInvocations;
    collection.manager = _manager;
    collection.assetType = _assetType;
    collection.projectId = _projectId;
    collection.royalties = (_royalties * 100) ;
    collection.paused = true;
    collection.id = nextCollectionId;
    collections[nextCollectionId] = collection;
    projectIdToCollectionIds[_projectId].push(nextCollectionId); 
    addressToCollectionIds[_manager].push(nextCollectionId);
    
    emit CollectionCreated(_name, nextCollectionId, _projectId, _royalties, _manager, _maxInvocations, _assetType, true);
    nextCollectionId++;
  }

  function editCollection(
    uint256 _id,
    uint256 _projectId,
    string memory _name,
    uint256 _maxInvocations,
    address _manager,
    uint256 _royalties,
    AssetType _assetType,
    bool _paused
  
    )
    public
    onlyChef(collections[_id].projectId)
    {
    collections[_id].name = _name;
    collections[_id].projectId = _projectId;
    collections[_id].maxInvocations = _maxInvocations;
    collections[_id].manager = _manager;
    collections[_id].royalties = (_royalties * 100);
    collections[_id].assetType = _assetType;
    collections[_id].paused = _paused;
  }

  function pauseCollection(uint256 _id) public onlyChef(collections[_id].projectId) {
    collections[_id].paused = !collections[_id].paused;
  }

  function addInvocation(uint256 _id, uint256 _amount) external {
    require(msg.sender == prismTokenContract, "Must be prism token contract" );
    collections[_id].invocations += _amount;
  }


  function viewProjectId(uint256 _id) external view returns(uint256 projectId){
    return collections[_id].projectId;
  }

  function viewMaxInvocations(uint256 _id) external view returns(uint256 maxInvocations){
    return collections[_id].maxInvocations;
  }

  function viewInvocations(uint256 _id) external view returns(uint256 invocations){
    return collections[_id].invocations;
  }

  function viewManager(uint256 _id) external view returns(address manager){
    return collections[_id].manager;
  }

  function viewRoyalties(uint256 _id) external view returns(uint256 royalties){
    return collections[_id].royalties;
  }

  function viewPausedStatus (uint256 _id) external view returns(bool paused){
    return collections[_id].paused;
  }

  function collectionURI(uint256 _id) 
  public 
  view
  returns (string memory)
  {
  return string(abi.encodePacked(
    collectionBaseURI, Strings.toString(_id)));
  }

  function collectionsOfProject(uint256 _projectId)
  public
  view
  returns (uint256[] memory)
  { 
  return projectIdToCollectionIds[_projectId];
  }

  function collectionsOfManager(address _manager)
  public
  view
  returns (uint256[] memory)
  { 
  return addressToCollectionIds[_manager];
  }

  function setPrismTokenContract(address _prismTokenContract) public onlyOwner(){
    prismTokenContract = _prismTokenContract;
  }

  /**
  @dev events
 */

  event ProjectCreated(
    uint256 indexed _id,
    string _name,
    address _chef,
    string[] traitTypes
  );

  event CollectionCreated(
    string _name,
    uint256 indexed _id,
    uint256 indexed _projectId,
    uint256 royalties,
     address manager,
    uint256 _maxInvocation,
    AssetType assetType,
    bool paused
  );



}