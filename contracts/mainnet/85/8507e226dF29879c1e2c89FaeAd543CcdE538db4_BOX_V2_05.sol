/**
 *Submitted for verification at Arbiscan on 2022-10-28
*/

//
//████████╗░░░███╗░░░███╗███████╗░░░░██╗██████╗░░█████╗░██████╗░████████╗██╗░░░██╗██╗░░██╗░█████╗░████████╗
//╚══██╔══╝░░░████╗░████║██╔════╝░░░██╔╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝╚██╗░██╔╝██║░░██║██╔══██╗╚══██╔══╝
//░░░██║░░░░░░██╔████╔██║█████╗░░░░██╔╝░██████╔╝███████║██████╔╝░░░██║░░░░╚████╔╝░███████║███████║░░░██║░░░
//░░░██║░░░░░░██║╚██╔╝██║██╔══╝░░░██╔╝░░██╔═══╝░██╔══██║██╔══██╗░░░██║░░░░░╚██╔╝░░██╔══██║██╔══██║░░░██║░░░
//░░░██║░░░██╗██║░╚═╝░██║███████╗██╔╝░░░██║░░░░░██║░░██║██║░░██║░░░██║░░░░░░██║░░░██║░░██║██║░░██║░░░██║░░░
//░░░╚═╝░░░╚═╝╚═╝░░░░░╚═╝╚══════╝╚═╝░░░░╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░

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

// File: contracts/1_Storage.sol


pragma solidity ^0.8.7;


interface IRandomizer {
    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement) external;
    function incrementCommitId() external;
    function addRandomForCommit(uint256 _seed) external;
    function requestRandomNumber() external returns(uint256);
    function revealRandomNumber(uint256 _requestId) external view returns(uint256);
    function isRandomReady(uint256 _requestId) external view returns(bool);
}

contract BOX_V2_05 is Ownable{
    mapping(address => uint256) public userId;
    mapping(address => uint256) public betsize;
    mapping(address => uint256) public multiplier;
    IRandomizer public randomizer;
    uint public float = 0;
    uint public tax = 2;
    uint public fraction = 5;

	receive() external payable{
	}

    function _bet(uint256 _multiplier) public payable{
        require(_multiplier >= 1);
        require(_multiplier <= 100);
        require(_multiplier * msg.value < address(this).balance / fraction);
        require(_multiplier * msg.value + float < address(this).balance);
        require(betsize[msg.sender] == 0);
        multiplier[msg.sender] = _multiplier;
        payable(address(this)).transfer(msg.value);
        userId[msg.sender] = randomizer.requestRandomNumber();
        betsize[msg.sender] = msg.value * multiplier[msg.sender];
        float += betsize[msg.sender];
    }

    function _reveal() public{
        require(userId[msg.sender] != 0, "User has no unrevealed numbers.");
        require(randomizer.isRandomReady(userId[msg.sender]), "Random number not ready, try again.");
        uint256 secretnum;
        uint256 rand = randomizer.revealRandomNumber(userId[msg.sender]);
        secretnum = uint256(keccak256(abi.encode(rand))) % 100; 
        if(secretnum < (100 / multiplier[msg.sender])){
            payable(msg.sender).transfer(betsize[msg.sender] * (100 - tax) / 100 );
            float -= betsize[msg.sender];
            delete betsize[msg.sender];
            delete multiplier[msg.sender];
        }
        else{
            float -= betsize[msg.sender];
            delete betsize[msg.sender];
            delete multiplier[msg.sender];
        }
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function reset_float() public onlyOwner {
        float = 0;
    }

    function set_tax(uint256 _tax) public onlyOwner {
        tax = _tax;
    }

    function set_fraction(uint256 _fraction) public onlyOwner {
        fraction = _fraction;
    }

    constructor(address _randomizer){
        randomizer = IRandomizer(_randomizer);
    }
}