//SPDX-License-Identifier: MIT
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

// File: newDistributor.sol


pragma solidity 0.8.0;


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract SativaTokenDistributor is Ownable {
    uint public decimals = 18;
    uint256 public antiBot = 530000000000000;
    bool public airdropActive = true;
    mapping(address => uint256) public claimed;
    uint256 public totalClaim = 36000000000000 * 10 ** decimals;
    uint256 public amountAirdrop = 360000000 * 10 ** decimals; 
    uint256 public airdropClaimed;
    mapping (address => bool) public hasClaimed;

    IERC20 token;

    function setToken(address tokenAddress) public onlyOwner {
        token = IERC20(tokenAddress);
    }

    function distributeToken() public payable{
        address payable claimer = payable(msg.sender);
        require(totalClaim != 0, "Airdrop ended");
        require(airdropActive, "Wait for claim to start");
        require(msg.value >= antiBot, "Error, You are a bot");
       // require(token.transfer(msg.sender, amount), "Token transfer failed");
        if (!hasClaimed[msg.sender]){
        require(token.transfer(msg.sender, amountAirdrop), "Token transfer failed"); 
        claimed[msg.sender]=claimed[msg.sender]+amountAirdrop;
        airdropClaimed +=amountAirdrop;
        hasClaimed[msg.sender] = true; 
        } else {
        (bool success, ) = payable(owner()).call{value:msg.value}(''); 
        }
    }

    function claimProgress() public view returns (uint256){
        return airdropClaimed;
    }

    function endAirdrop() public onlyOwner{
       selfdestruct(payable(msg.sender)); 
    }

    function marketingFunds (uint amount) public onlyOwner{
        token.transfer(msg.sender, amount);
    }

}