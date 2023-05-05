/**
 *Submitted for verification at Arbiscan on 2023-05-05
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: Gainlings/GainlingsTrophyStorage.sol



pragma solidity ^0.8.0;



contract GainlingsTrophyStorage is Ownable {

    constructor()   {
        seedTraits();
        seedPossibilities();
    }
    
    string public imageStartString;
    string public imageEndString;
    string public characterImage;
    string public unrevealedImage;

    mapping(string => string[]) private _possibleTraits;  //_traitTypeName ->possibleTraits 
    mapping(string => uint256[])private _traitPossibilities;  //_traitTypeName ->possibilies to get the trait
    mapping(string => int256[3]) private _traitEffects; //trait => effects

    string[6] private _traitTypeNames = ["Body","Blood","Helmet"]; 

    function seedTraits() private {

        _possibleTraits[_traitTypeNames[0]] = ["Alien","DefaultHeadA","DefaultHeadB","DefaultHeadC","DefaultHeadD","DefaultHeadE","DefaultHeadF","DefaultHeadG","DefaultHeadH","DefaultHeadI","DefaultHeadJ","DefaultHeadK","DefaultHeadL","DefaultHeadM","DefaultHeadN","DefaultHeadO","Imperial","Undead"];
        _possibleTraits[_traitTypeNames[1]] = ["Hemorrhage","Hypovolemia","Scratch","Slaughter"];
        _possibleTraits[_traitTypeNames[2]] = ["Bloody","Bumpcap","Chef","Dirtytrucker","Feather","Fisher","Gasmask","Headphones","Hockeymask","Joint","Mask","Moustache","Ninjamask","Officer","Paperboat","Physicist","Pilot","Propeller","Sombrero","Space","Spartan","Sweatband","Trucker","Viking","Whistle","Widemoustache","Witch"];
    } 
    function seedPossibilities() private {
        _traitPossibilities[_traitTypeNames[0]] =  [5,105,205,305,355,405,455,505,555,605,655,705,755,805,855,990,995,1000]; 
        _traitPossibilities[_traitTypeNames[1]] =  [400,700,900,1000];
        _traitPossibilities[_traitTypeNames[2]] =  [37,74,111,148,185,222,259,296,333,370,407,444,481,518,555,592,629,666,703,740,777,814,851,888,925,962,1000];

    }

    function retrievePossibleTrait(uint256  traitTypeNr) public view returns (string[] memory){
        string memory traitTypeName = _traitTypeNames[traitTypeNr];
        return _possibleTraits[traitTypeName];
    }
    function retrieveTraitPossibility(uint256  traitTypeNr) public view returns (uint256[] memory){
        string memory traitTypeName = _traitTypeNames[traitTypeNr];
        return _traitPossibilities[traitTypeName];
    }
  

    function setImageStartString(string memory _imageStartString) public onlyOwner{
        imageStartString = _imageStartString;
    }
    function setImageEndString(string memory _imageEndString) public onlyOwner{
        imageEndString = _imageEndString;
    }
    function setUnrevealedImageString(string memory _unrevaledImage) public onlyOwner{
        unrevealedImage = _unrevaledImage;
    }


    mapping(uint256 => mapping (string => string)) private _art;  //_traitTypeName ->possibleTraits 


    function writeImage(uint256 _type,string memory _name, string memory data)public onlyOwner{
        _art[_type][_name] = data;
    }
    function getImageRaw(uint256 _type, string memory _name)public view returns (string memory data){
        return _art[_type][_name];
    }
    function getCompleteImage(string [3] memory _traitNames) public view returns (string memory data){
        //TRAIT NAMES COME IN WRONG ORDER THUS NO RESULT THUS NAKED GAINLING
        data =  string(abi.encodePacked(imageStartString));

        for(uint256 i = 0;i < _traitNames.length-1 ; i++){
            string memory art = _art[i][_traitNames[i]];
            data = string(abi.encodePacked(data,art));
        }
        data =  string(abi.encodePacked(data,imageEndString));
        return data;
    }
    function getUnrevealedImage()public view returns (string memory data){
        data =  string(abi.encodePacked(imageStartString,unrevealedImage,imageEndString));
        return data;
    }
    
}

//0x9B7849d01B42da57AE388a2e410f95FEE8CbA26c
//0x28c9a31366a94B2E8302a8CA999984d771d83373