/**
 *Submitted for verification at Arbiscan.io on 2024-05-20
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
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

// File: contracts/LotteryS.sol



pragma solidity >=0.8.2 <0.9.0;


interface IERC20{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title LotteryS
 * @dev Every week lottery. 50% of pool is burned, rest is sent to the winner
 */

 contract LotteryS is Ownable {
     IERC20 public S;

     uint256 public POOL_BURN_AMOUNT = 50; // % pool is burned, rest is sent to the winner
     bool public Active = false; // is game active right now?
     uint256 public ticketPrice; // price of ticket to buy tickets
     uint256 public numberOfTickets; // number of tickets to buy

     address[] private players;
     
     constructor(address addresS) Ownable(msg.sender) {
        S = IERC20(addresS);
     }


    function Start(uint256 _ticketPrice, uint256 _numberOfTickets) public onlyOwner{
        Active = true;
        ticketPrice = _ticketPrice;
        numberOfTickets = _numberOfTickets;
    }

    function Stop() public onlyOwner{
        Active = false;
    }

    function PickWinner() public onlyOwner{
        require(!Active, "Game is active");

        uint index = random() % players.length;
        uint amount = (players.length * ticketPrice) / (100 / POOL_BURN_AMOUNT);
        S.transfer(players[index], amount);
        players = new address[](0);
        S.transfer(0x000000000000000000000000000000000000dEaD, amount);
    }

    function SetBurn(uint amount) public onlyOwner{
        POOL_BURN_AMOUNT = amount;
    }

    function BuyTicket(uint256 _numberOfTickets) public payable{
        require(Active, 'Game not active');
        require(numberOfTickets >= _numberOfTickets, 'You are not allowed to buy more tickets than expected');
        require(S.balanceOf(msg.sender) > _numberOfTickets * ticketPrice, 'Not enough S');
        require(S.allowance(msg.sender, address(this)) > _numberOfTickets, 'Not enough S in allowance');
            
        S.approve(msg.sender, _numberOfTickets * ticketPrice);
        S.transferFrom(msg.sender, address(this), _numberOfTickets * ticketPrice);

        for(uint8 i=0; i < _numberOfTickets; i++)
        {
            players.push(msg.sender);
        }
    }

    function getPlayers() public view returns (address[] memory){
        return players;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.prevrandao,block.timestamp,players.length)));
    }
    
 }