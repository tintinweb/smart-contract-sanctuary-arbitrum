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
import "./IAoriSeats.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Orderbook.sol";

contract OrderbookFactory is Ownable {

    mapping(address => bool) isListedOrderbook;
    Orderbook[] public orderbookAdds;
    address public keeper;
    IAoriSeats public AORISEATSADD;
    
    constructor(IAoriSeats _AORISEATSADD) {
        AORISEATSADD = _AORISEATSADD;
    }

    event AoriOrderbookCreated(
        address orderbook,
        address option,
        address usdc
    );

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
    
    function withdrawFees(IERC20 token, uint256 amount_) external onlyOwner returns(uint256) {
            IERC20(token).transfer(owner(), amount_);
            return amount_;
    }
    
    function getAllOrderbooks() external view returns(Orderbook[] memory) {
        return orderbookAdds;
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
import "./Chainlink/AggregatorV3Interface.sol";
import "./OpenZeppelin/IERC721.sol";
import "./OpenZeppelin/IOwnable.sol";

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

contract Orderbook {
    IAoriSeats public immutable AORISEATSADD;
    IERC20 public immutable OPTION;
    IERC20 public immutable USDC;
    uint256 public totalVolume;
    uint256 public immutable askMinTick = 1e4;
    uint256 public immutable bidMinTick = 1e16;
    Ask[] public asks;
    Bid[] public bids;

    mapping(address => bool) public isAsk;
    mapping(uint256 => Ask[]) public asksAtPrice;
    mapping(uint256 => uint256) public filledAskIndex;

    mapping(address => bool) public isBid;
    mapping(uint256 => Bid[]) public bidsAtPrice;
    mapping(uint256 => uint256) public filledBidIndex;

    constructor(
        address _OPTION,
        address _USDC,
        IAoriSeats _AORISEATSADD
    ) {
        AORISEATSADD = _AORISEATSADD;
        OPTION = IERC20(_OPTION);
        USDC = IERC20(_USDC);
    }

    event AskCreated(address ask, uint256 USDCPerOPTION, uint256 OPTIONSize);
    event Filled(address buyer, uint256 USDCAmount, uint256 USDCPerOPTION, bool isAsk);
    event BidCreated(address bid, uint256 OPTIONPerUSDC, uint256 USDCSize);
    /**
        Deploys an Ask.sol with the following parameters.    
     */
    function createAsk(uint256 _USDCPerOPTION, uint256 _OPTIONSize) public returns (Ask) {
        require(askMinTick % _USDCPerOPTION == askMinTick, "Prices must match appropriate tick size");
        Ask ask = new Ask(OPTION, USDC, AORISEATSADD, msg.sender, _USDCPerOPTION, AORISEATSADD.getTradingFee(), _OPTIONSize);
        asks.push(ask);
        //transfer before storing the results
        OPTION.transferFrom(msg.sender, address(ask), _OPTIONSize);
        //storage
        isAsk[address(ask)] = true;
        ask.fundContract();
        emit AskCreated(address(ask), _USDCPerOPTION, _OPTIONSize);
        return ask;
    }
    /**
        Deploys an Bid.sol with the following parameters.    
     */
    function createBid(uint256 _OPTIONPerUSDC, uint256 _USDCSize) public returns (Bid) {
        require(bidMinTick % _OPTIONPerUSDC == bidMinTick, "Prices must match appropriate tick size");
        Bid bid = new Bid(USDC, OPTION, AORISEATSADD, msg.sender, _OPTIONPerUSDC, AORISEATSADD.getTradingFee(), _USDCSize);
        bids.push(bid);
        //transfer before storing the results
        USDC.transferFrom(msg.sender, address(bid), _USDCSize);
        //storage
        isBid[address(bid)] = true;
        bidsAtPrice[_OPTIONPerUSDC].push(bid);
        bid.fundContract();
        emit BidCreated(address(bid), _OPTIONPerUSDC, _USDCSize);
        return bid;
    }
    
    function fillAsks(address receiver, uint256 _USDCPerOPTION, uint256 USDCSize, uint256 seatId) external{
        require(USDCSize > 0);
        USDC.transferFrom(msg.sender, address(this), USDCSize);
        uint256 amountToFill = USDCSize;
        uint256 bal = asks[filledAskIndex[_USDCPerOPTION]].totalUSDCWanted();
        if(bal == 0) {
            filledAskIndex[_USDCPerOPTION++];
        }
        for (uint256 i; i < asks.length - filledAskIndex[_USDCPerOPTION]; i++) {
            bal = asks[filledAskIndex[_USDCPerOPTION]].totalUSDCWanted();
            if(bal <= amountToFill) {
                amountToFill -= bal;
                USDC.approve(address(asks[filledAskIndex[_USDCPerOPTION]]), bal);
                asks[filledAskIndex[_USDCPerOPTION]].fill(receiver, bal, seatId);
                IERC20(address(USDC)).decreaseAllowance(address(asks[filledAskIndex[_USDCPerOPTION]]), USDC.allowance(address(this), address(asks[filledAskIndex[_USDCPerOPTION]])));
                filledAskIndex[_USDCPerOPTION]++;
            } else {
                USDC.approve(address(asks[filledAskIndex[_USDCPerOPTION]]), bal);
                asks[filledAskIndex[_USDCPerOPTION]].fill(receiver, amountToFill, seatId);
                amountToFill = 0;
                IERC20(address(USDC)).decreaseAllowance(address(asks[filledAskIndex[_USDCPerOPTION]]), USDC.allowance(address(this), address(asks[filledAskIndex[_USDCPerOPTION]])));
            }
            if(amountToFill == 0) {
                break;
            }
        }
        totalVolume += USDCSize;
        emit Filled(receiver, USDCSize, _USDCPerOPTION, true);
    }
    
    function fillBids(address receiver, uint256 _OPTIONPerUSDC, uint256 OPTIONSize, uint256 seatId) external{
        require(OPTIONSize > 0);
        OPTION.transferFrom(msg.sender, address(this), OPTIONSize);
        uint256 amountToFill = OPTIONSize;
        uint256 bal = bids[filledBidIndex[_OPTIONPerUSDC]].totalOPTIONWanted();
        uint256 usdcvolume;
        if(bal == 0) {
            filledBidIndex[_OPTIONPerUSDC++];
        }
        for (uint256 i; i < bids.length - filledBidIndex[_OPTIONPerUSDC]; i++) {
            bal = bids[filledBidIndex[_OPTIONPerUSDC]].totalOPTIONWanted();
            if(bal <= amountToFill) {
                amountToFill -= bal;
                OPTION.approve(address(bids[filledBidIndex[_OPTIONPerUSDC]]), bal);
                usdcvolume = bids[filledBidIndex[_OPTIONPerUSDC]].fill(receiver, bal, seatId);
                IERC20(address(OPTION)).decreaseAllowance(address(bids[filledBidIndex[_OPTIONPerUSDC]]), OPTION.allowance(address(this), address(bids[filledBidIndex[_OPTIONPerUSDC]])));
                filledBidIndex[_OPTIONPerUSDC]++;
            } else {
                OPTION.approve(address(bids[filledBidIndex[_OPTIONPerUSDC]]), bal);
                usdcvolume = bids[filledBidIndex[_OPTIONPerUSDC]].fill(receiver, amountToFill, seatId);
                amountToFill = 0;
                IERC20(address(OPTION)).decreaseAllowance(address(bids[filledBidIndex[_OPTIONPerUSDC]]), OPTION.allowance(address(this), address(bids[filledBidIndex[_OPTIONPerUSDC]])));
            }
            if(amountToFill == 0) {
                break;
            }
        }
        totalVolume += usdcvolume;
        emit Filled(receiver, usdcvolume, _OPTIONPerUSDC, false);
    }

    function cancelOrder(address order, bool _isAsk) public {
        if(_isAsk) {
            require(msg.sender == Ask(order).maker());
            Ask(order).cancel();
        } else {
            require(msg.sender == Bid(order).maker());
            Bid(order).cancel();
        }
    }

    function getIsAsk(address ask) external view returns (bool) {
        return isAsk[ask];
    }

    function getAsks() external view returns (Ask[] memory) {
        return asks;
    }
    
    function getIsBid(address bid) external view returns (bool) {
        return isBid[bid];
    }
    
    function getBids() external view returns (Bid[] memory) {
        return bids;
    }
    
    function getAsksAtPrice(uint256 _USDCPerOPTION) external view returns (Ask[] memory) {
        return asksAtPrice[_USDCPerOPTION];
    }

    function getBidsAtPrice(uint256 _OPTIONPerUSDC) external view returns (Bid[] memory) {
        return bidsAtPrice[_OPTIONPerUSDC];
    }
    
    function doTransferOut(IERC20 token, address receiver, uint256 amount) internal {
        token.transfer(receiver, amount);
        if(token.allowance(address(this), msg.sender) > 0) {
            token.decreaseAllowance(receiver, token.allowance(address(this), receiver));
        }
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
import "./IAoriSeats.sol";

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
        require(isFunded(), "no usdc balance");
        require(msg.sender == factory);
        require(!hasEnded, "offer has been previously been cancelled");
        require(OPTION.balanceOf(msg.sender) >= amountOfOPTION, "Not enough option tokens");
        require(AORISEATSADD.confirmExists(seatId) && AORISEATSADD.ownerOf(seatId) != address(0x0), "Seat does not exist");

        uint256 OPTIONAfterFee;
        uint256 USDCToReceive;

        if(receiver == AORISEATSADD.ownerOf(seatId)) {
            //Seat holders receive 0 fees for trading
            OPTIONAfterFee = amountOfOPTION;
            //Transfers
            OPTION.transferFrom(msg.sender, maker, OPTIONAfterFee);
            USDC.transfer(receiver, mulDiv(OPTIONAfterFee, 10**6, OPTIONPerUSDC));
        } else {
            //Deducts the fee from the options the taker will receive
            OPTIONAfterFee = amountOfOPTION;            
            USDCToReceive = mulDiv(amountOfOPTION, 10**6, OPTIONPerUSDC); //1eY = (1eX * 1eY) / 1eX
            //This means for Aori seat governance they should not allow more than 12 seats to be combined at once
            uint256 seatScoreFeeInBPS = mulDiv(fee, ((AORISEATSADD.getSeatScore(seatId) * 500) + 3500), 10000); //(10 * 4000) / 10000 (min)
            //Transfers from the msg.sender
            OPTION.transferFrom(msg.sender, maker, OPTIONAfterFee);
            //Fee transfers are all in USDC, so for Bids they're routed here
            //These are to the Factory, the Aori seatholder, then the buyer respectively.
            USDC.transfer(AORISEATSADD.owner(), mulDiv(USDCToReceive, fee - seatScoreFeeInBPS, 10000));
            USDC.transfer(AORISEATSADD.ownerOf(seatId), mulDiv(USDCToReceive, seatScoreFeeInBPS, 10000));
            USDC.transfer(receiver, USDCToReceive - (mulDiv(USDCToReceive, fee - seatScoreFeeInBPS, 10000) + mulDiv(USDCToReceive, seatScoreFeeInBPS, 10000)));
            //Tracking the volume in the NFT
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
        uint256 balance = USDC.balanceOf(address(this));
        
        USDC.transfer(maker, balance);
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
    
    function totalOPTIONWanted() public view returns (uint256) {
       if(USDC.balanceOf(address(this)) == 0) {
           return 0;
       }
    return (OPTIONPerUSDC * USDC.balanceOf(address(this))) / 10**6;
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
import "./IAoriSeats.sol";

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
    function fill(address receiver, uint256 amountOfUSDC, uint256 seatId) public {
        require(isFunded(), "no option balance");
        require(msg.sender == factory);
        require(!hasEnded, "offer has been previously been cancelled");
        require(USDC.balanceOf(msg.sender) >= amountOfUSDC, "Not enough USDC");
        require(AORISEATSADD.confirmExists(seatId) && AORISEATSADD.ownerOf(seatId) != address(0x0), "Seat does not exist");
        uint256 USDCAfterFee;
        uint256 OPTIONToReceive;

        if(receiver == IERC721(AORISEATSADD).ownerOf(seatId)) {
            //Seat holders receive 0 fees for trading
            USDCAfterFee = amountOfUSDC;
            //transfers To the msg.sender
            USDC.transferFrom(msg.sender, maker, USDCAfterFee);
            //transfer to the receiver
            OPTION.transfer(receiver, mulDiv(USDCAfterFee, 10**18, USDCPerOPTION));
        } else {
            //This means for Aori seat governance they should not allow more than 12 seats to be combined at once
            uint256 seatScoreFeeInBPS = mulDiv(fee, ((AORISEATSADD.getSeatScore(seatId) * 500) + 3500), 10000);
            //calculating the fee breakdown 
            //Calcualting the base tokens to transfer after fees
            USDCAfterFee = (amountOfUSDC - (mulDiv(amountOfUSDC, fee - seatScoreFeeInBPS, 10000) + mulDiv(amountOfUSDC, seatScoreFeeInBPS, 10000)));
            //And the amount of the quote currency the msg.sender will receive
            OPTIONToReceive = mulDiv(USDCAfterFee, 10**18, USDCPerOPTION); //(1e6 * 1e18) / 1e6 = 1e18
            //Transfers from the msg.sender
            USDC.transferFrom(msg.sender, IOwnable(address(AORISEATSADD)).owner(), mulDiv(amountOfUSDC, fee - seatScoreFeeInBPS, 10000));
            USDC.transferFrom(msg.sender, AORISEATSADD.ownerOf(seatId), mulDiv(amountOfUSDC, seatScoreFeeInBPS, 10000));
            USDC.transferFrom(msg.sender, maker, USDCAfterFee);
            //Transfers to the receiver
            OPTION.transfer(receiver, OPTIONToReceive);
            //Tracking the volume in the NFT
        }
        if(OPTION.balanceOf(address(this)) == 0) {
            hasEnded = true;
        }
    }
    /**
        Cancel this order and refund all remaining tokens
    */
    function cancel() public  {
        require(msg.sender == factory);
        require(isFunded(), "no OPTION balance");
        uint256 balance = OPTION.balanceOf(address(this));
        
        OPTION.transfer(maker, balance);
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

   function totalUSDCWanted() public view returns (uint256) {
       if(OPTION.balanceOf(address(this)) == 0) {
           return 0;
       }
    return (USDCPerOPTION * OPTION.balanceOf(address(this))) / 10**18;
    }
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