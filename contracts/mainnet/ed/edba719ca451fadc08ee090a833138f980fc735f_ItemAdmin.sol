/**
 *Submitted for verification at Arbiscan on 2023-01-10
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

// File: Squires/ItemAdmin.sol


pragma solidity ^0.8.17;


interface IITEM {
    function mint(address to, uint typeChoice) external;
}

contract ItemAdmin is Ownable {

    address public POTIONS = 0x6F2aA70c70625E45424652aEd968E3971020F205;
    address public TRINKETS = 0x9f0cc315caE0826005b94462B5400849b3d39d91;
    address public RINGS  = 0x37865Fe8A9c839F330f35104EeD08d4E8136c339;

    mapping(address => bool) public admin;

    bool private active = true;
    

    constructor() {
        
    }

    function setAdmin(address _addy, bool _state) public onlyOwner {
        admin[_addy] = _state;
    }

    function setActive(bool _state) public onlyOwner {
        active = _state;
    }

    function mintPotions(uint256 id, uint256 amount) public {
        require(admin[msg.sender], "Not admin");
        require(active, "Not active");

        for(uint i = 0; i < amount; i++)
            IITEM(POTIONS).mint(msg.sender, id);
    }

    function mintTrinkets(uint256 id, uint256 amount) public {
        require(admin[msg.sender], "Not admin");
        require(active, "Not active");

        for(uint i = 0; i < amount; i++)
            IITEM(TRINKETS).mint(msg.sender, id);
    }

    function mintRings(uint256 id, uint256 amount) public {
        require(admin[msg.sender], "Not admin");
        require(active, "Not active");

        for(uint i = 0; i < amount; i++)
            IITEM(RINGS).mint(msg.sender, id);
    }

    

}