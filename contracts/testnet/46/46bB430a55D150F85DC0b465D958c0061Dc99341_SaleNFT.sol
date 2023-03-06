/**
 *Submitted for verification at Arbiscan on 2023-03-05
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/saleNFT.sol


pragma solidity ^0.8.0;




interface IRosnPassCore {
    function mint(address _owner) external returns (uint256) ;
}

contract SaleNFT is Ownable, ReentrancyGuard {
    
    event BuyPhaseWhileList(address indexed purchaser, uint256 amount, uint256 tokenId);
    event BuyPhasePublic(address indexed purchaser, uint256 amount, uint256 tokenId);

    address public nftRosnPass;
    address public usdc;
    address public admin;
    uint256 public maxNFTPhaseWL= 1500;
    uint256 public countNFTPhaseWL;
    uint256 public nftPrice = 100000000000000000000;
    uint128 public startTimeWL;
    uint128 public endTimeWL;
    bool public isTimePublicSale;
    mapping(address => bool) public whilelist;
    mapping(address=>bool) public buyer;
    mapping(address => uint256) public checkNonce;

    /**
     * @param _nftRosnPass  NFT Roseon Pass Address
     * @param _admin  Address sign message
     */
    constructor(address _nftRosnPass, address _admin, address _usdc) {
        require(address(_nftRosnPass) != address(0), "zeroAddr");
        require(address(_admin) != address(0), "zeroAddr");
        require(address(_usdc) != address(0), "zeroAddr");
        usdc = _usdc;
        admin = _admin;
        nftRosnPass = _nftRosnPass;
    }

    /**
     * @notice Buy NFT during the sale phase whitelist
     */
    function buyPhaseWhileList(uint256 _amount) external nonReentrant returns (uint256) {
        require(block.timestamp > startTimeWL && startTimeWL > 0, "Not Started");
        require(block.timestamp < endTimeWL, "Sale Over");
        require(countNFTPhaseWL < maxNFTPhaseWL, "Sale Out");
        require(_amount == nftPrice, "Price NFT 100 USDC");
        require(!buyer[msg.sender], "Not Buy More Than 1 NFT");
        require(IERC20(usdc).transferFrom(msg.sender, address(this), _amount), "TransferFrom Fail");

        buyer[msg.sender] = true;
        countNFTPhaseWL++;
        uint256 tokenId = IRosnPassCore(nftRosnPass).mint(msg.sender); 
        emit BuyPhaseWhileList(msg.sender, _amount, tokenId);
        return tokenId;
    }


    /**
     * @notice Buy NFT during the sale phase public
     */
    function buyPhasePublic(address _addr, uint256 _amountUsdc, uint256 _amountRosn, 
                            uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) external nonReentrant returns (uint256) {
                                
        require(msg.sender == _addr, "Invalid address");
        require(isTimePublicSale, "Not Started");
        require(_amountUsdc == nftPrice, "Price NFT 100 USDC");
        require(!buyer[msg.sender], "Not Buy More Than 1 NFT");
        require(_nonce > checkNonce[msg.sender], "Invalid nonce");
        require(verify(msg.sender, _amountRosn, _nonce, _v, _r, _s) == admin, "Invalid signature");
        require(IERC20(usdc).transferFrom(msg.sender, address(this), _amountUsdc), "TransferFrom Fail");
        checkNonce[msg.sender] = _nonce;
        buyer[msg.sender] = true;
        uint256 tokenId = IRosnPassCore(nftRosnPass).mint(msg.sender); 
        emit BuyPhasePublic(msg.sender, _amountUsdc, tokenId);
        return tokenId;

    }

    /**
     * @notice veryfy sign message
     */
    function verify(address _addr, uint256 _amount, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) private pure returns (address) {
        return ecrecover(getEthSignedMessageHash(keccak256(abi.encode(_addr, _amount,_nonce))), _v, _r, _s);
    }

    // FUNCTION internal
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /**
     * @notice update address sign message
     * @param  _admin address sign message
     */
    function setAdminAddress(address _admin) external onlyOwner {
        admin = _admin;
    }

    /**
     * @notice update price NFT Roseon Pass 
     */
    function setPriceNft(uint256  _nftPrice) external onlyOwner {
        nftPrice = _nftPrice;
    }

    /**
     * @notice set start sale phase whitelist
     */
    function setTimePhaseWhiteList(uint128 _startTime, uint128  _endTime) external onlyOwner {
        startTimeWL = _startTime;
        endTimeWL = _endTime;
    }

    /**
     * @notice set start sale phase public
     */
    function enableTimePhasePublic(bool _enable) external onlyOwner {
       isTimePublicSale = _enable;
    }

    /**
     * @notice add address to buy NFT during the sale phase whitelist
     */
    function addAddressWhiteList(address[] calldata _address) external onlyOwner {
        for(uint256 i=0; i< _address.length ; i++) {
            whilelist[_address[i]] = true;
        }
    }

    /**
     * @notice Get balance usdc in contract
     */
    function getBalance() public view returns(uint256) {
        return IERC20(usdc).balanceOf(address(this));
    }
    
    /**
     * @notice withdrawn usdc to owner
     */
    function withdrawBalance(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

   
    function getTime() public view returns(uint256) {
        return block.timestamp;
    }

}