// SPDX-License-Identifier: UNLICENSED
/**                           
        /@#(@@@@@              
       @@      @@@             
        @@                      
        [email protected]@@#                  
        ##@@@@@@,              
      @@@      /@@@&            
    [email protected]@@         @@@@           
    @@@@  @@@@@  @@@@           
    @@@@  @   @  @@@/           
     @@@@       @@@             
       (@@@@#@@@      
    THE AORI PROTOCOL                           
 */
pragma solidity ^0.8.18;

import "./OpenZeppelin/Ownable.sol";
import "./Interfaces/IAoriSeats.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Orderbook.sol";

contract OrderbookFactory is Ownable {

    mapping(address => bool) isListedOrderbook;
    mapping(address => address) bookToOption;
    Orderbook[] public orderbookAdds;
    address public keeper;
    IAoriSeats public AORISEATSADD;
    
    constructor(IAoriSeats _AORISEATSADD) {
        AORISEATSADD = _AORISEATSADD;
    }

    event AoriOrderbookCreated(address orderbook, address option, address usdc);
    event OrderMade(address maker, uint256 price, uint256 size, bool isAsk);
    event OrderFilled(address taker, uint256 price, uint256 size, bool isAsk, bool hasEnded);

    /**
        Set the keeper of the Optiontroller.
        The keeper controls and deploys all new markets and orderbooks.
    */
    function setKeeper(address newKeeper) external onlyOwner returns(address) {
        keeper = newKeeper;
        return keeper;
    }
    
    function setAORISEATSADD(IAoriSeats newAORISEATSADD) external onlyOwner returns(IAoriSeats) {
        AORISEATSADD = newAORISEATSADD;
        return AORISEATSADD;
    }

    /**
        Deploys a new call option token at a designated strike and maturation block.
        Additionally deploys an orderbook to pair with the new ERC20 option token.
    */
    function createOrderbook(
            address OPTION_,
            address USDC
            ) public returns (Orderbook) {

        require(msg.sender == keeper);

        Orderbook orderbook =  new Orderbook(OPTION_, USDC, AORISEATSADD); 
        
        bookToOption[OPTION_] = address(orderbook);
        isListedOrderbook[address(orderbook)] = true;
        orderbookAdds.push(orderbook);

        emit AoriOrderbookCreated(address(orderbook), OPTION_, USDC);

        return (orderbook);
    }

    //Checks if an individual Orderbook is listed
    function checkIsListedOrderbook(address Orderbook_) public view returns(bool) {
        return isListedOrderbook[Orderbook_];
    }
    //Confirms for points that the Orderbook is a listed orderbook, THEN that the order is a listed order.
    function checkIsOrder(address Orderbook_, address order_) public view returns(bool) {
        require(checkIsListedOrderbook(Orderbook_), "Orderbook is not listed"); 
        require(Orderbook(Orderbook_).getIsBid(order_) == true || Orderbook(Orderbook_).getIsAsk(order_) == true, "Is not a confirmed order");

        return true;
    }
    
    function withdrawFees(IERC20 token, address to, uint256 amount) external onlyOwner returns(uint256) {
        IERC20(token).transfer(to, amount);
        return amount;
    }
    
    function getAllOrderbooks() external view returns(Orderbook[] memory) {
        return orderbookAdds;
    }
    
    function getBookByOption(address option) external view returns (address) {
        return bookToOption[option];
    }

    function eventEmit(address makerOrTaker, uint256 price, uint256 size, bool isAsk, bool isMake, bool hasEnded) external {
        require(isListedOrderbook[msg.sender]);
        if(isMake) {
            emit OrderMade(makerOrTaker, price, size, isAsk);
        } else {
            emit OrderFilled(makerOrTaker, price, size, isAsk, hasEnded);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "../Chainlink/AggregatorV3Interface.sol";
import "../OpenZeppelin/IERC721.sol";
import "../OpenZeppelin/IOwnable.sol";

interface IAoriSeats is IERC721, IOwnable {
    event FeeSetForSeat (uint256 seatId, address SeatOwner);
    event MaxSeatChange (uint256 NewMaxSeats);
    event MintFeeChange (uint256 NewMintFee);
    event TradingFeeChange (uint256 NewTradingFee);

    function mintSeat() external returns (uint256);

    /** 
        Combines two seats and adds their scores together
        Enabling the user to retain a higher portion of the fees collected from their seat
    */
    function combineSeats(uint256 seatIdOne, uint256 seatIdTwo) external returns(uint256);

    /**
        Mints the user a series of one score seats
     */
    function separateSeats(uint256 seatId) external;

    function marginFee() external returns (uint256);

    /** 
        Volume = total notional trading volume through the seat
        For data tracking purposes.
    */
    function addTakerVolume(uint256 volumeToAdd, uint256 seatId, address Orderbook_) external;

    /**
        Change the total number of seats
     */
    function setMaxSeats(uint256 newMaxSeats) external returns (uint256);
     /**
        Change the number of points for taking bids/asks and minting options
     */
    function setFeeMultiplier(uint256 newFeeMultiplier) external returns (uint256);
    

    /**
        Change the maximum number of seats that can be combined
        Currently if this number exceeds 12 the Orderbook will break
     */
    function setMaxSeatScore(uint256 newMaxScore) external returns(uint256);
    /** 
        Change the mintingfee in BPS
        For example a fee of 100 would be equivalent to a 1% fee (100 / 10_000)
    */
    function setMintFee(uint256 newMintFee) external returns (uint256);
    
    /** 
        Change the mintingfee in BPS
        For example a fee of 100 would be equivalent to a 1% fee (100 / 10_000)
    */
    function setMarginFee(uint256 newMarginFee) external returns (uint256);
    /** 
        Change the mintingfee in BPS
        For example a fee of 100 would be equivalent to a 1% fee (100 / 10_000)
    */
    function setTradingFee(uint256 newTradingFee) external returns (uint256);
    /**
        Set an individual seat URI
     */
    function setSeatIdURI(uint256 seatId, string memory _seatURI) external;

    /**
    VIEW FUNCTIONS
     */
    function getOptionMintingFee() external view returns (uint256);

    function getTradingFee() external view returns (uint256);
    
    function getMarginFee() external view returns (uint256);

    function confirmExists(uint256 seatId) external view returns (bool);

    function getPoints(address user) external view returns (uint256);

    function getSeatScore(uint256 seatId) external view returns (uint256);
    
    function getFeeMultiplier() external view returns (uint256);

    function getSeatVolume(uint256 seatId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
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

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);


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

    function decimals() external view returns (uint8);

}

// SPDX-License-Identifier: Unlicense
/**                           
        /@#(@@@@@              
       @@      @@@             
        @@                      
        [email protected]@@#                  
        ##@@@@@@,              
      @@@      /@@@&            
    [email protected]@@         @@@@           
    @@@@  @@@@@  @@@@           
    @@@@  @   @  @@@/           
     @@@@       @@@             
       (@@@@#@@@      
    THE AORI PROTOCOL                           
 */
pragma solidity ^0.8.18;

import "./Bid.sol";
import "./Ask.sol";
import "./Margin/Structs.sol";
import "./Interfaces/IOrder.sol";
import "./Interfaces/IOrderbookFactory.sol";

contract Orderbook {
    IAoriSeats public immutable AORISEATSADD;
    IERC20 public immutable OPTION;
    IERC20 public immutable USDC;
    IOrderbookFactory public factory;
    uint256 public cumVol;
    uint256 public cumFees;
    uint256 public immutable askMinTick = 1e4;
    uint256 public immutable bidMinTick = 1e16;
    mapping(address => bool) public isAsk;
    mapping(address => bool) public isBid;

    constructor(
        address _OPTION,
        address _USDC,
        IAoriSeats _AORISEATSADD
    ) {
        AORISEATSADD = _AORISEATSADD;
        OPTION = IERC20(_OPTION);
        USDC = IERC20(_USDC);
        factory = IOrderbookFactory(msg.sender);
    }

    // event AskCreated(address maker, address ask, uint256 USDCPerOPTION, uint256 OPTIONSize);
    // event Filled(address taker, uint256 USDCAmount, uint256 USDCPerOPTION, bool isAsk);
    // event BidCreated(address maker, address bid, uint256 OPTIONPerUSDC, uint256 USDCSize);
    /**
        Deploys an Ask.sol with the following parameters.    
     */
    function createAsk(uint256 _USDCPerOPTION, uint256 _OPTIONSize) public returns (Ask) {
        require(_USDCPerOPTION % askMinTick == 0, "Prices must match appropriate tick size");
        require(_OPTIONSize > 0, "No asks with size 0");
        Ask ask = new Ask(OPTION, USDC, AORISEATSADD, msg.sender, _USDCPerOPTION, AORISEATSADD.getTradingFee(), _OPTIONSize);
        OPTION.transferFrom(msg.sender, address(ask), _OPTIONSize);
        isAsk[address(ask)] = true;
        ask.fundContract();
        factory.eventEmit(msg.sender, _USDCPerOPTION, _OPTIONSize, true, true, false);
        return ask;
    }

    /**
        Deploys an Bid.sol with the following parameters.    
     */
    function createBid(uint256 _OPTIONPerUSDC, uint256 _USDCSize) public returns (Bid) {
        require(_OPTIONPerUSDC % bidMinTick == 0, "Prices must match appropriate tick size");
        require(_USDCSize > 0, "No bids with size 0");
        Bid bid = new Bid(USDC, OPTION, AORISEATSADD, msg.sender, _OPTIONPerUSDC, AORISEATSADD.getTradingFee(), _USDCSize);
        USDC.transferFrom(msg.sender, address(bid), _USDCSize);
        isBid[address(bid)] = true;
        bid.fundContract();
        factory.eventEmit(msg.sender, _OPTIONPerUSDC, _USDCSize, false, true, false);
        return bid;
    }

    function fillAsks(address receiver, uint256 _USDCPerOPTION, uint256 USDCsize, uint256 seatId, address[] memory asks) public returns(uint256) {
        USDC.transferFrom(msg.sender, address(this), USDCsize);
        cumVol += USDCsize;
        for (uint256 i; i < asks.length; i++) {
            require(isAsk[address(asks[i])], "Invalid ask");
            uint256 toFill = Structs.mulDiv(OPTION.balanceOf(address(asks[i])), Ask(asks[i]).USDCPerOPTION(), 10**OPTION.decimals());
            if(toFill > USDCsize) {
                USDC.approve(asks[i], USDCsize);
                Ask(asks[i]).fill(receiver, USDCsize, seatId);
                factory.eventEmit(receiver, _USDCPerOPTION, USDCsize, true, false, false);
                break;
            }
            USDC.approve(asks[i], toFill);
            Ask(asks[i]).fill(receiver, toFill, seatId);
            factory.eventEmit(receiver, _USDCPerOPTION, USDCsize, true, false, true);
            USDCsize -= toFill;
            if(USDC.allowance(address(this), asks[i]) > 0) {
                USDC.decreaseAllowance(receiver, USDC.allowance(address(this), asks[i]));
            }
        }
        return USDCsize;
    }

    function fillBids(address receiver, uint256 _OPTIONPerUSDC, uint256 OPTIONsize, uint256 seatId, address[] memory bids) public returns(uint256) {
        OPTION.transferFrom(msg.sender, address(this), OPTIONsize);
        for (uint256 i; i < bids.length; i++) {
            require(isBid[address(bids[i])], "Invalid bid");
            uint256 toFill = Structs.mulDiv(USDC.balanceOf(address(bids[i])), Bid(bids[i]).OPTIONPerUSDC(), 10**USDC.decimals());
            if(toFill > OPTIONsize) {
                OPTION.approve(bids[i], OPTIONsize);
                Bid(bids[i]).fill(receiver, OPTIONsize, seatId);
                factory.eventEmit(receiver, _OPTIONPerUSDC, OPTIONsize, false, false, false);
                break;
            }
            cumVol += OPTION.balanceOf(bids[i]);
            OPTION.approve(bids[i], toFill);
            Bid(bids[i]).fill(receiver, toFill, seatId);
            factory.eventEmit(receiver, _OPTIONPerUSDC, OPTIONsize, false, true, true);
            OPTIONsize -= toFill;
            if(OPTION.allowance(address(this), bids[i]) > 0) {
                OPTION.decreaseAllowance(receiver, OPTION.allowance(address(this), bids[i]));
            }
        }
        return OPTIONsize;
    }

    function cancelOrder(address order, bool _isAsk) public {
        IOrder(order).cancel();
    }

    function addCumFees(uint256 fees) external {
        require(isAsk[msg.sender] || isBid[msg.sender], "not a bid or ask calling");
        cumFees += fees;
    }

    function getIsAsk(address ask) external view returns (bool) {
        return isAsk[ask];
    }
    
    function getIsBid(address bid) external view returns (bool) {
        return isBid[bid];
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
 interface IOwnable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view  returns (address);
}

// SPDX-License-Identifier: Unlicense
/**                           
        /@#(@@@@@              
       @@      @@@             
        @@                      
        [email protected]@@#                  
        ##@@@@@@,              
      @@@      /@@@&            
    [email protected]@@         @@@@           
    @@@@  @@@@@  @@@@           
    @@@@  @   @  @@@/           
     @@@@       @@@             
       (@@@@#@@@      
    THE AORI PROTOCOL                           
 */
pragma solidity ^0.8.18;

import "./OpenZeppelin/IERC20.sol";
import "./Interfaces/IAoriSeats.sol";
import "./Interfaces/IOrderbook.sol";

contract Bid {
    address public immutable factory;
    address public immutable maker;
    uint256 public immutable OPTIONPerUSDC;
    uint256 public immutable USDCSize;
    uint256 public immutable fee; // in bps, default is 30 bps
    IAoriSeats public immutable AORISEATSADD;
    bool public hasEnded = false;
    bool public hasBeenFunded = false;
    IERC20 public USDC;
    IERC20 public OPTION;

    constructor(
        IERC20 _USDC,
        IERC20 _OPTION,
        IAoriSeats _AORISEATSADD,
        address _maker,
        uint256 _OPTIONPerUSDC,
        uint256 _fee,
        uint256 _USDCSize
    ) {
        factory = msg.sender;
        USDC = _USDC;
        OPTION = _OPTION;
        AORISEATSADD = _AORISEATSADD;
        maker = _maker;
        OPTIONPerUSDC = _OPTIONPerUSDC;
        fee = _fee;
        USDCSize = _USDCSize;
    }
    
    /**
        Fund the Ask with Aori option ERC20's
     */
    function fundContract() public {
        require(msg.sender == factory);
        //officially begin the countdown
        hasBeenFunded = true;
    }
    /**
        Partial or complete fill of the offer, with the requirement of trading through a seat
        regardless of whether the seat is owned or not.
        In the case of not owning the seat, a fee is charged in USDC.
    */
    function fill(address receiver, uint256 amountOfOPTION, uint256 seatId) public returns (uint256) {
        require(isFunded() && msg.sender == factory, "No bal/Not orderbook");
        require(!hasEnded, "Offer cancelled");
        require(OPTION.balanceOf(msg.sender) >= amountOfOPTION, "Not enough options");
        require(AORISEATSADD.confirmExists(seatId) && AORISEATSADD.ownerOf(seatId) != address(0x0), "Seat!=exist");
        uint256 OPTIONAfterFee = amountOfOPTION;
        uint256 USDCToReceive;
        address seatOwner = AORISEATSADD.ownerOf(seatId);
        OPTION.transferFrom(msg.sender, maker, OPTIONAfterFee);
        if(receiver == seatOwner) {
            USDCToReceive = mulDiv(OPTIONAfterFee, 10**6, OPTIONPerUSDC);
        } else {
            USDCToReceive = mulDiv(amountOfOPTION, 10**6, OPTIONPerUSDC);
            uint256 seatScoreFeeInBPS = mulDiv(fee, ((AORISEATSADD.getSeatScore(seatId) * 500) + 3500), 10000);
            uint256 feeToFactory = mulDiv(USDCToReceive, fee - seatScoreFeeInBPS, 10000);
            uint256 feeToSeat = mulDiv(USDCToReceive, seatScoreFeeInBPS, 10000);
            uint256 totalFees = feeToFactory + feeToSeat;
            USDC.transfer(IOwnable(factory).owner(), feeToFactory);
            USDC.transfer(seatOwner, feeToSeat);
            USDC.transfer(receiver, USDCToReceive - totalFees);
            IOrderbook(factory).addCumFees(totalFees);
        }
        if(USDC.balanceOf(address(this)) == 0) {
            hasEnded = true;
        }
        return USDCToReceive;
    }


    /**
        Cancel this order and refund all remaining tokens
    */
    function cancel() public  {
        require(msg.sender == factory);
        require(isFunded(), "no USDC balance");
        USDC.transfer(maker, USDC.balanceOf(address(this)));
        hasEnded = true;
    }

    //Check if the contract is funded still.
    function isFunded() public view returns (bool) {
        if (USDC.balanceOf(address(this)) > 0 && hasBeenFunded) {
            return true;
        } else {
            return false;
        }
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return (x * y) / z;
    }
}

// SPDX-License-Identifier: Unlicense
/**                           
        /@#(@@@@@              
       @@      @@@             
        @@                      
        [email protected]@@#                  
        ##@@@@@@,              
      @@@      /@@@&            
    [email protected]@@         @@@@           
    @@@@  @@@@@  @@@@           
    @@@@  @   @  @@@/           
     @@@@       @@@             
       (@@@@#@@@      
    THE AORI PROTOCOL                           
 */
pragma solidity ^0.8.18;

import "./OpenZeppelin/IERC20.sol";
import "./Interfaces/IAoriSeats.sol";
import "./Interfaces/IOrderbook.sol";

contract Ask {
    address public immutable factory;
    address public immutable maker;
    uint256 public immutable USDCPerOPTION;
    uint256 public immutable OPTIONSize;
    uint256 public immutable fee; // in bps, default is 10 bps
    IAoriSeats public immutable AORISEATSADD;
    bool public hasEnded = false;
    bool public hasBeenFunded = false;
    IERC20 public OPTION;
    IERC20 public USDC; 

    constructor(
        IERC20 _OPTION,
        IERC20 _USDC,
        IAoriSeats _AORISEATSADD,
        address _maker,
        uint256 _USDCPerOPTION,
        uint256 _fee,
        uint256 _OPTIONSize
    ) {
        factory = msg.sender;
        OPTION = _OPTION;
        USDC = _USDC;
        AORISEATSADD = _AORISEATSADD;
        maker = _maker;
        USDCPerOPTION = _USDCPerOPTION;
        fee = _fee;
        OPTIONSize = _OPTIONSize;
    }

    /**
        Fund the Ask with Aori option ERC20's
     */
    function fundContract() public {
        require(msg.sender == factory);
        hasBeenFunded = true;
        //officially begin the countdown
    }
    /**
        Partial or complete fill of the offer, with the requirement of trading through a seat
        regardless of whether the seat is owned or not.
        In the case of not owning the seat, a fee is charged in USDC.
     */
    function fill(address receiver, uint256 amountOfUSDC, uint256 seatId) public returns (uint256) {
        require(isFunded() && msg.sender == factory, "No bal/Not orderbook");
        require(!hasEnded, "offer has been previously been cancelled");
        require(USDC.balanceOf(msg.sender) >= amountOfUSDC, "Not enough USDC");
        require(AORISEATSADD.confirmExists(seatId) && AORISEATSADD.ownerOf(seatId) != address(0x0), "Seat does not exist");
        uint256 USDCAfterFee;
        uint256 OPTIONToReceive;
        address seatOwner = AORISEATSADD.ownerOf(seatId);
        if(receiver == seatOwner) {
            USDCAfterFee = amountOfUSDC;
            USDC.transferFrom(msg.sender, maker, USDCAfterFee);
            OPTIONToReceive = mulDiv(USDCAfterFee, (10**OPTION.decimals()), USDCPerOPTION);
        } else {
            uint256 seatScoreFeeInBPS = mulDiv(fee, ((AORISEATSADD.getSeatScore(seatId) * 500) + 3500), 10000);
            USDCAfterFee = (amountOfUSDC - (mulDiv(amountOfUSDC, fee - seatScoreFeeInBPS, 10000) + mulDiv(amountOfUSDC, seatScoreFeeInBPS, 10000)));
            OPTIONToReceive = mulDiv(USDCAfterFee, (10**OPTION.decimals()), USDCPerOPTION);
            USDC.transferFrom(msg.sender, IOwnable(address(factory)).owner(), mulDiv(amountOfUSDC, fee - seatScoreFeeInBPS, 10000));
            USDC.transferFrom(msg.sender, seatOwner, mulDiv(amountOfUSDC, seatScoreFeeInBPS, 10000));
            USDC.transferFrom(msg.sender, maker, USDCAfterFee);
            IOrderbook(factory).addCumFees(amountOfUSDC - USDCAfterFee);
        }
        OPTION.transfer(receiver, OPTIONToReceive);
        if(OPTION.balanceOf(address(this)) == 0) {
            hasEnded = true;
        }
        return OPTIONToReceive;
    }

    /**
        Cancel this order and refund all remaining tokens
    */
    function cancel() public  {
        require(msg.sender == factory);
        require(isFunded(), "no OPTION balance");
        OPTION.transfer(maker, OPTION.balanceOf(address(this)));
        hasEnded = true;
    }
    
    //Check if the contract is funded still.
    function isFunded() public view returns (bool) {
        if (OPTION.balanceOf(address(this)) > 0 && hasBeenFunded) {
            return true;
        } else {
            return false;
        }
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return (x * y) / z;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.18;
import "../OpenZeppelin/ERC20.sol";

library Structs {

    struct OpenPositionRequest {
        address account;
        uint256 collateral;
        address orderbook;
        address option;
        address assetToBorrow; //underlying for calls, usdc for puts
        bool isCall;
        uint256 amountOfUnderlying;
        uint256 seatId;
        uint256 endingTime;
        uint256 index;
    }
    
    struct Position {
        address account;
        bool isCall;
        address token;
        address option;
        uint256 strikeInUSDC;
        uint256 optionSize;
        uint256 collateral;
        uint256 entryMarginRate;
        uint256 lastAccrueTime;
        address orderbook;
        uint256 endingTime;
    }
    
    struct LensPosition {
        address account;
        bool isCall;
		bool isLong;
		bool isLevered;
        address option;
        string name;
        uint256 optionSize;
        uint256 collateral; //returns 0 if long || fully collateralized
        uint256 entryMarginRate; //current borrowRate, returns 0 if long || fully collateralized
        uint256 lastAccrueTime; //margin
        address orderbook;
    }
    
    struct Vars {
        uint256 optionsMinted;
        uint256 collateralVal;
        uint256 portfolioVal;
        uint256 collateralToLiquidator;
        uint256 profit;
        uint256 fairVal;
        bool isLiquidatable;
    }
    
    struct settleVars {
        uint256 tokenBalBefore;
        uint256 tokenDiff;
        uint256 optionsSold;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return (x * y) / z;
    }

    function getPositionKey(address _account, uint256 _optionSize, address _orderbook, bool _isCall, uint256 _lastAccrueTime, uint256 index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            _account,
            _optionSize,
            _orderbook,
            _isCall,
            _lastAccrueTime,
            index
        ));
    }
}

// SPDX-License-Identifier: Unlicense
/**                           
        /@#(@@@@@              
       @@      @@@             
        @@                      
        [email protected]@@#                  
        ##@@@@@@,              
      @@@      /@@@&            
    [email protected]@@         @@@@           
    @@@@  @@@@@  @@@@           
    @@@@  @   @  @@@/           
     @@@@       @@@             
       (@@@@#@@@      
    THE AORI PROTOCOL                           
 */
pragma solidity ^0.8.18;

import "../OpenZeppelin/IERC20.sol";
import "./IAoriSeats.sol";

interface IOrder {

    function fundContract() external;

    function fill(address receiver, uint256 amountOfUSDC, uint256 seatId) external returns (uint256);
 
    function cancel() external;
    
    function isFunded() external view returns (bool);

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) external pure returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED
/**                           
        /@#(@@@@@              
       @@      @@@             
        @@                      
        [email protected]@@#                  
        ##@@@@@@,              
      @@@      /@@@&            
    [email protected]@@         @@@@           
    @@@@  @@@@@  @@@@           
    @@@@  @   @  @@@/           
     @@@@       @@@             
       (@@@@#@@@      
    THE AORI PROTOCOL                           
 */
pragma solidity ^0.8.18;

import "../OpenZeppelin/Ownable.sol";
import "./IAoriSeats.sol";
import "../OpenZeppelin/IERC20.sol";
import "../Orderbook.sol";

interface IOrderbookFactory is IOwnable {

    event AoriOrderbookCreated(address orderbook, address option, address usdc);
    event OrderMade(address maker, uint256 price, uint256 size, bool isAsk);
    event OrderFilled(address taker, uint256 price, uint256 size, bool isAsk, bool hasEnded);

    function setKeeper(address newKeeper) external returns(address);
    
    function setAORISEATSADD(IAoriSeats newAORISEATSADD) external returns(IAoriSeats);
    
    function createOrderbook(address OPTION_, address USDC) external returns (Orderbook);

    function checkIsListedOrderbook(address Orderbook_) external view returns(bool);

    function checkIsOrder(address Orderbook_, address order_) external view returns(bool);
    
    function withdrawFees(IERC20 token, uint256 amount_) external returns(uint256);
    
    function getAllOrderbooks() external view returns(Orderbook[] memory);

    function eventEmit(address makerOrTaker, uint256 price, uint256 size, bool isAsk, bool isMake, bool hasEnded) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
/**                           
        /@#(@@@@@              
       @@      @@@             
        @@                      
        [email protected]@@#                  
        ##@@@@@@,              
      @@@      /@@@&            
    [email protected]@@         @@@@           
    @@@@  @@@@@  @@@@           
    @@@@  @   @  @@@/           
     @@@@       @@@             
       (@@@@#@@@      
    THE AORI PROTOCOL                           
 */
pragma solidity ^0.8.18;

import "./IOrder.sol";
// import "../Ask.sol";
// import "../Bid.sol";
import "../OpenZeppelin/IERC20.sol";

interface IOrderbook {

    event AskCreated(address ask, uint256 USDCPerOPTION, uint256 OPTIONSize);
    event Filled(address buyer, uint256 USDCAmount, uint256 USDCPerOPTION, bool isAsk);
    event BidCreated(address bid, uint256 OPTIONPerUSDC, uint256 USDCSize);

    // function createAsk(uint256 _USDCPerOPTION, uint256 _OPTIONSize) external returns (Ask);

    function OPTION() external view returns (IERC20);

    // function createBid(uint256 _OPTIONPerUSDC, uint256 _USDCSize) external returns (Bid);
    
    function fillAsks(address receiver, uint256 _USDCPerOPTION, uint256 USDCSize, uint256 seatId) external;
    
    function fillBids(address receiver, uint256 _OPTIONPerUSDC, uint256 OPTIONSize, uint256 seatId) external;

    function cancelOrder(address order, bool _isAsk) external;

    function getIsAsk(address ask) external view returns (bool);

    // function getAsks() external view returns (Ask[] memory);
    
    function getIsBid(address bid) external view returns (bool);
    
    function addCumFees(uint256 fees) external;

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) external pure returns (uint256);

    // function getBids() external view returns (Bid[] memory);
    
    // function getAsksAtPrice(uint256 _USDCPerOPTION) external view returns (Ask[] memory);

    // function getBidsAtPrice(uint256 _OPTIONPerUSDC) external view returns (Bid[] memory);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override(IERC20, IERC20Metadata) returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}