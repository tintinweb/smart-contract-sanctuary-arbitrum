// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/*

8888888b.  8888888b.   .d8888b.       888       888          888 888          888    
888   Y88b 888   Y88b d88P  Y88b      888   o   888          888 888          888    
888    888 888    888 Y88b.           888  d8b  888          888 888          888    
888   d88P 888   d88P  "Y888b.        888 d888b 888  8888b.  888 888  .d88b.  888888 
8888888P"  8888888P"      "Y88b.      888d88888b888     "88b 888 888 d8P  Y8b 888    
888 T88b   888 T88b         "888      88888P Y88888 .d888888 888 888 88888888 888    
888  T88b  888  T88b  Y88b  d88P      8888P   Y8888 888  888 888 888 Y8b.     Y88b.  
888   T88b 888   T88b  "Y8888P"       888P     Y888 "Y888888 888 888  "Y8888   "Y888 

*/

import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/security/ReentrancyGuard.sol";
import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";

contract RRSWalletV2 is Ownable, ReentrancyGuard {
        
    mapping(address=>uint256) public tokenPrice; // price of $1 USD per token
    mapping(address=>bool) public isTokenActive;

    bool public isSalesActive;
    
    mapping(address=>bool) public whitelistAddress;
    
    mapping(uint256=>uint256) public itemPrices; // USD price per 1 item package
    mapping(uint256=>bool) public itemActive; // Item active status per item id

    event BuyItem(address indexed walletAddress, uint256 indexed itemId, address tokenAddress, uint256 amount);
    event AirdropBatchPayment(address indexed walletAddress, uint256 indexed amount, address indexed tokenAddress);
    event AirdropBatchPaymentETH(address indexed walletAddress, uint256 indexed amount);

    constructor(){
        isSalesActive = true;
    }

    modifier onlyWhiteList() {
        require(whitelistAddress[msg.sender], "Account Sender is Not whitelisted");
        _;
    }

    receive() external payable {
    }

    /// @dev buy item with token
    /// @param _itemId item id
    /// @param _tokenAddress deposit token address
    function buyItem(
        uint256 _itemId,
        address _tokenAddress
    ) external nonReentrant{
        require(isSalesActive, "Not Activated");
        require(isTokenActive[_tokenAddress], "Not support");

        require(itemActive[_itemId], "Item is not active");
        uint256 amount = itemPrices[_itemId]*tokenPrice[_tokenAddress];
        require(IERC20(_tokenAddress).balanceOf(msg.sender) >= amount, "Insufficient funds");

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);

        emit BuyItem(msg.sender, _itemId, _tokenAddress, amount);
    }

    /// @dev buy item with token
    /// @param _itemIds item ids
    /// @param _tokenAddress deposit token address
    function buyItems(
        uint256[] calldata _itemIds,
        address _tokenAddress
    ) external nonReentrant{
        require(isSalesActive, "Not Activated");
        require(isTokenActive[_tokenAddress], "Not Supported");

        for(uint256 i = 0; i < _itemIds.length; i++ ){
            require(itemActive[_itemIds[i]], "Item is not active");
            uint256 amount = itemPrices[_itemIds[i]]*tokenPrice[_tokenAddress];
            require(IERC20(_tokenAddress).balanceOf(msg.sender) >= amount, "Insufficient funds");
            
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);

            emit BuyItem(msg.sender, _itemIds[i], _tokenAddress, amount);
        }
    }

    /// @dev airdrop payments
    /// @param _walletAddresses array wallet address
    /// @param _amounts array amount 
    /// @param _tokenAddress token address
    function airdropBatchPayment(
        address[] calldata _walletAddresses,
        uint256[] calldata _amounts,
        address _tokenAddress
    ) external onlyOwner nonReentrant{
        require( (_walletAddresses.length == _amounts.length), "Length wrong");

        for( uint256 i = 0; i < _walletAddresses.length; i++ ){
            address walletAddress = _walletAddresses[i];
            uint256 amount = _amounts[i];

            require(IERC20(_tokenAddress).balanceOf(address(this)) >= amount, "Insufficient funds");
           
            IERC20(_tokenAddress).transfer(walletAddress, amount);

            emit AirdropBatchPayment(walletAddress, amount, _tokenAddress);
        }
    }

    /// @dev airdrop payment
    /// @param _walletAddresses to wallet address
    /// @param _amounts token amount
    function airdropBatchPaymentETH(
        address[] calldata _walletAddresses,
        uint256[] calldata _amounts
    ) external onlyOwner nonReentrant{
        require( _walletAddresses.length == _amounts.length, "Length wrong");

        for( uint256 i = 0; i < _walletAddresses.length; i++ ){
            address walletAddress = _walletAddresses[i];
            uint256 amount = _amounts[i];

            require(address(this).balance >= amount, "Insufficient funds");

            (bool sent, ) = walletAddress.call{value: amount}("");
            require(sent, "Failed to send Ether");

            emit AirdropBatchPaymentETH(walletAddress, amount);
        }
    }

    /// @dev set prices of each item by id
    /// @param _itemId item id
    /// @param _itemPrice price per item    
    function setItemPrice(
        uint256 _itemId,
        uint256 _itemPrice
    ) external onlyOwner nonReentrant{
        itemPrices[_itemId] = _itemPrice;
        itemActive[_itemId] = true;
    }

    /// @dev set prices of each item by id
    /// @param _itemIds list item ids
    /// @param _itemPrices list of USD price per item    
    function setItemPrices(
        uint256[] calldata _itemIds,
        uint256[] calldata _itemPrices
    ) external onlyOwner nonReentrant{
        require((_itemIds.length == _itemPrices.length), "Length wrong");

        for(uint256 i = 0; i < _itemIds.length; i++ ){
            itemPrices[_itemIds[i]] = _itemPrices[i];
            itemActive[_itemIds[i]] = true;
        }
    }

    /// @dev change active status of items
    /// @param _itemIds list item ids
    /// @param _status list of active status for items  
    function changeItemsActive(
        uint256[] calldata _itemIds,
        bool[] calldata _status
    ) external onlyOwner nonReentrant{
        require((_itemIds.length == _status.length), "Length wrong");

        for(uint256 i = 0; i < _itemIds.length; i++ ){
            itemActive[_itemIds[i]] = _status[i];
        }
    }

    /// @dev set price of token (intended to match to $1 USD)
    /// @param _tokenAddresses token address
    /// @param _price token price
    function setTokenPrice(
        address[] calldata _tokenAddresses,
        uint256[] calldata _price
    ) external onlyWhiteList{
        require( _tokenAddresses.length == _price.length, "Length wrong");

        for( uint256 i = 0; i < _tokenAddresses.length; i++ ){
            tokenPrice[_tokenAddresses[i]] = _price[i];
        }        
    }

    /// @dev set active tokens
    /// @param _tokenAddresses to token address 
    /// @param _active active type
    function setTokenActive(
        address[] calldata _tokenAddresses,
        bool _active
    ) external onlyOwner{
        for( uint256 i = 0; i < _tokenAddresses.length; i++ ){
            isTokenActive[_tokenAddresses[i]] = _active;
        }
    }

    /// @dev set sales active 
    /// @param _active active type
    function setSalesActive(
        bool _active
    ) public onlyOwner {
        isSalesActive = _active;
    }

    /// @dev add Whitelist address
    /// @param _toAddAddresses wallet address
    function addToWhitelist(
        address[] calldata _toAddAddresses
    ) external onlyOwner{
        for (uint i = 0; i < _toAddAddresses.length; i++) {
            whitelistAddress[_toAddAddresses[i]] = true;
        }
    }

    /// @dev remove Whitelist address
    /// @param _toRemoveAddresses wallet address
    function removeFromWhitelist(
        address[] calldata _toRemoveAddresses
    ) external onlyOwner{
        for (uint i = 0; i < _toRemoveAddresses.length; i++) {
            delete whitelistAddress[_toRemoveAddresses[i]];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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