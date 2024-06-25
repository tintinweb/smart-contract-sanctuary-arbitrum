// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./interfaces/IOptimistic.sol";
import "./interfaces/IWrapped.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

//import "./lzApp/NonblockingLzApp.sol";

contract SimpleTradeContract is Ownable, TradeInterface {

    mapping(uint => mapping (address => mapping( address => Pair ))) public book;
    uint32                    public srcLzc;
    uint                      private constant BASIS_POINTS=10000;
    uint16                    private constant SEND = 1;

    //Constructor
    constructor() {
    }

    event OrderPlaced(address indexed sender, address srcAsset, address dstAsset, uint32 dstLzc, uint32 orderIndex, uint96 amount, uint96 dstOutput, uint16 bondFee, bool isMaker);
    event MatchCreated(address indexed bonder, address srcAsset, address dstAsset, uint32 dstLzc, uint32 srcIndex, uint32 dstIndex, uint96 srcQuantity, uint96 dstQuantity);
    event MatchExecuted(address indexed bonder, address srcAsset, address dstAsset, uint32 dstLzc, uint32 srcIndex, uint32 dstIndex, uint96 srcQuantity, uint96 dstQuantity, bool isWrapped);
    event MatchConfirmed(address indexed bonder, address srcAsset, address dstAsset, uint32 dstLzc, uint32 srcIndex, uint32 dstIndex, uint16 bondFee);
    event ChallengeRaised(address indexed challenger, address srcAsset, address dstAsset, uint32 dstLzc, uint32 srcIndex, address bonder, uint32 dstIndex);
    event OrderCancelled(address indexed sender,  address srcAsset, address dstAsset, uint32 dstLzc, uint32 orderIndex);
    event MatchUnwound(address indexed bonder, address srcAsset, address dstAsset, uint32 dstLzc, uint32 srcIndex, uint32 dstIndex);

    //PlaceTrade Functions
    function placeOrder(
        OrderDirection memory direction,
        OrderFunding memory funding,
        OrderExpiration memory expiration,
        bool isMaker
    ) public {

        //check
        require((expiration.challengeOffset + expiration.challengeWindow) < 1e5 , "!maxWindow"); 

        //action
        Order[] storage orders=book[direction.dstLzc][direction.dstAsset][direction.srcAsset].orders;

        Order memory newOrder = Order({
            sender: msg.sender,
            funding: funding,
            expiration: expiration,
            settled: uint96(0),
            isMaker: isMaker
        });

        uint32 orderIndex=uint32(orders.length);
        orders.push(newOrder);

        //event 
        emit OrderPlaced(
            msg.sender,
            direction.srcAsset,
            direction.dstAsset,
            direction.dstLzc,
            orderIndex,
            funding.amount,
            funding.dstOutput,
            funding.bondFee,
            isMaker
        );
        
        //an intent...no funds are pulled
    }

    //Read Functions
    function getOrders(address srcAsset, address dstAsset, uint dstLzc) public view returns (Order[] memory orders) {
        orders=book[dstLzc][dstAsset][srcAsset].orders;
    }

    function getOrder(address srcAsset, address dstAsset, uint dstLzc, uint index) public view returns (Order memory _order) {
        _order=book[dstLzc][dstAsset][srcAsset].orders[index];
    } 

    function getReceipt(address srcAsset, address dstAsset, uint dstLzc, uint srcIndex, uint dstIndex) public view returns (Receipt memory _receipt) {
        _receipt=book[dstLzc][dstAsset][srcAsset].receipts[srcIndex][dstIndex];
    } 

    function getMatch(address srcAsset, address dstAsset, uint dstLzc, uint index) public view returns (Match memory _match) {
        _match=book[dstLzc][dstAsset][srcAsset].matches[index];
    } 

    //Core Functions
    function createMatch(
        OrderDirection memory direction,
        uint32 srcIndex,
        uint32 dstIndex,
        address Counterparty,
        uint96 srcQuantity,
        uint96 dstQuantity
    ) public {

        Pair storage selected_pair=book[direction.dstLzc][direction.dstAsset][direction.srcAsset];
        Order storage order = selected_pair.orders[srcIndex];

        //checks
        require(order.settled == 0, "Order has already been settled.");
        require(Counterparty != address(0), "Bad idea bud");
        require(order.funding.amount == srcQuantity, "Partial fills are not allowed. Source quantity must match the order amount.");
        require(order.expiration.timestamp >= block.timestamp, "Order has expired. Check timestamp");
        require(!order.isMaker, "The createMatch method is reserved for taker orders. Makers should use the executeMatch method.");

        transferFrom(order.funding.bondAsset, msg.sender, order.funding.bondAmount); //bonder
        transferFrom(direction.srcAsset, order.sender, srcQuantity); //taker

        //action
        Match memory TakerMatch = Match({
          dstIndex: dstIndex,
          srcQuantity: srcQuantity,
          dstQuantity: dstQuantity,
          receiver: Counterparty,
          bonder: msg.sender,
          blockNumber: uint96(block.number),
          finalized: false,
          challenged: false
        });

        selected_pair.matches[srcIndex]=TakerMatch; //onlyBonder

        //state change
        order.settled+=srcQuantity;
        require(selected_pair.orders[srcIndex].settled == selected_pair.orders[srcIndex].funding.amount, "Sanity check T3"); //test case remove in prod


        //event
        emit MatchCreated(msg.sender, direction.srcAsset, direction.dstAsset, direction.dstLzc, srcIndex, dstIndex, srcQuantity, dstQuantity);

    }

    function executeMatch(
        OrderDirection memory direction,
        uint32 srcIndex,
        uint32 dstIndex,
        address Counterparty,
        uint96 srcQuantity,
        uint96 dstQuantity,
        bool isUnwrap
    ) public {

        Pair storage selected_pair=book[direction.dstLzc][direction.dstAsset][direction.srcAsset];
        Order storage order= selected_pair.orders[srcIndex];

        //checks
        require(order.sender == msg.sender, "Only the maker wallet can call this method"); //onlyMaker
        require(order.funding.amount>order.settled, "Maker order is closed");
        require((order.funding.amount-order.settled)>=srcQuantity, "Maker order too small to cover this match");
        require(srcQuantity > 0, "Zero valued match");
        require(Counterparty != address(0), "Bad idea bud");
        require(order.expiration.timestamp >= block.timestamp, "Maker order has expired. Check timestamp");
        require(order.isMaker, "The executeMatch method is reserved for maker orders. Bonders should use the createMatch method.");

        //actions (pull maker and pay taker)
        transferFrom(direction.srcAsset, order.sender, srcQuantity); //pull maker funds
        
        //pay taker funds -- isUnwrap true is used to deliver user native gas tokens 
        if (isUnwrap) {
            //Unwrap the token and transfer srcQuantity of the native gas token to the user
            IWrapped(direction.srcAsset).withdraw(srcQuantity);

            //send the gas token
            (bool sent,) = Counterparty.call{value: srcQuantity}("");
            require(sent, "Failed to unwrap and send native asset");
        }

        else {
            transferTo(direction.srcAsset, Counterparty, srcQuantity); //pay counterparty
        }

        Receipt memory MakerReceipt = Receipt({
          payoutQuantity: srcQuantity,
          receiver: Counterparty
        });

        selected_pair.receipts[srcIndex][dstIndex]=MakerReceipt; // add the receipt
        
        //state change
        order.settled+=srcQuantity;
        require(selected_pair.orders[srcIndex].settled <= selected_pair.orders[srcIndex].funding.amount, "Sanity check T4"); //test case remove in prod

        //event
        emit MatchExecuted(msg.sender, direction.srcAsset, direction.dstAsset, direction.dstLzc, srcIndex, dstIndex, srcQuantity, dstQuantity, isUnwrap);

    }

    function confirmMatch(
        OrderDirection memory direction,
        uint32 srcIndex
    ) public {

        Pair storage selected_pair=book[direction.dstLzc][direction.dstAsset][direction.srcAsset];
        Order storage _order= selected_pair.orders[srcIndex];
        Match storage _match=selected_pair.matches[srcIndex];

        //check
        uint validBlock = _match.blockNumber+_order.expiration.challengeOffset+_order.expiration.challengeWindow;
        
        require(!_match.finalized && !_match.challenged, "!Match is closed");
        require(msg.sender==_match.bonder || msg.sender==_match.receiver, "!OnlyMakerOrBonder");
        require(block.number > validBlock, "Must wait before confirming match");
        
        //math
        uint order_amount = _order.funding.amount;
        uint16 fee = _order.funding.bondFee;
        uint maker_payout=applyFee(order_amount, fee);
        uint bonder_fee_payout=bondFee(order_amount, fee);

        require(_match.srcQuantity == _order.funding.amount, "Sanity Check T1"); //Test case remove in prod
        require((bonder_fee_payout+maker_payout)==order_amount, "Sanity Check T2"); //Test case remove in prod
        require(_order.settled==order_amount, "Sanity Check T5"); //Test case remove in prod

        //state
        _match.finalized=true; 

        //transfer
        address bonder =_match.bonder;

        transferTo(direction.srcAsset, _match.receiver, maker_payout); //pay counterparty
        transferTo(direction.srcAsset, bonder, bonder_fee_payout); //pay bonder fee
        transferTo(_order.funding.bondAsset, bonder, _order.funding.bondAmount); //give back bonder his bond

        //event
        emit MatchConfirmed(bonder, direction.srcAsset, direction.dstAsset, direction.dstLzc, srcIndex, _match.dstIndex, fee);
    }

    function cancelOrder(
        OrderDirection memory direction,
        uint32 orderIndex
    ) public {
        Order storage order= book[direction.dstLzc][direction.dstAsset][direction.srcAsset].orders[orderIndex];
        address sender=order.sender;
        //check
        require(msg.sender==sender, "!onlySender");
        require(order.settled < order.funding.amount, "!alreadyMatched");

        //action
        order.funding.amount = 0;

        //event
        emit OrderCancelled(sender, direction.srcAsset, direction.dstAsset, direction.dstLzc, orderIndex);
    }

    function unwindMatch(
        OrderDirection memory direction,
        uint32 srcIndex
    ) public {
        Pair storage selected_pair=book[direction.dstLzc][direction.dstAsset][direction.srcAsset];
        Order storage _order= selected_pair.orders[srcIndex];
        Match storage _match=selected_pair.matches[srcIndex];

        //check
        require(msg.sender == _match.receiver, "!onlyMaker");
        require(!_match.finalized && !_match.challenged, "!Match is closed");

        //updates
        _order.funding.amount = 0;
        _match.finalized = true;

        //transfer
        transferTo(_order.funding.bondAsset, _match.bonder, _order.funding.bondAmount); //give back bonder his bond
        transferTo(direction.srcAsset, _order.sender, _order.funding.amount); //refund user

        //emit
        emit MatchUnwound(_match.bonder, direction.srcAsset, direction.dstAsset, direction.dstLzc, srcIndex, _match.dstIndex);

    }



    //LayerZero Functions
    event MessageSent(bytes message, uint32 dstEid);      // @notice Emitted when a challenge is sent on source chain to dest chain (src -> dst).
    event ReturnMessageSent(string message, uint32 dstEid);     // @notice Emitted when a challenge is judges on the dest chain (src -> dst).
    event MessageReceived(string message, uint32 senderEid, bytes32 sender);     // @notice Emitted when a message is received from another chain.

    //Challenge Pattern: A->B->A

    function decodeMessage(bytes calldata encodedMessage) public pure returns (Payload memory message, uint16 msgType, uint256 extraOptionsStart, uint256 extraOptionsLength) {
        uint256 extraOptionsStart = 256;  // Starting offset after _message, _msgType, and extraOptionsLength
        Payload memory _message;
        uint16 _msgType;

        // Decode the first part of the message
        (_message, _msgType, extraOptionsLength) = abi.decode(encodedMessage, (Payload, uint16, uint256));

        // // Slice out _extraReturnOptions
        // bytes memory _extraReturnOptions = abi.decode(encodedMessage[extraOptionsStart:extraOptionsStart + extraOptionsLength], (bytes));
        
        return (_message, _msgType, extraOptionsStart, extraOptionsLength);
    }
    
    /**
     * @notice Sends a message to a specified destination chain.
     * @param direction._dstEid Destination endpoint ID for the message.
     * @param _extraSendOptions Options for sending the message, such as gas settings.
     * @param _extraReturnOptions Additional options for the return message.
     */
    function challengeMatch(
        OrderDirection memory direction,
        uint32 srcIndex,
        bytes calldata _extraSendOptions, // gas settings for A -> B
        bytes calldata _extraReturnOptions // gas settings for B -> A
    ) external payable {
    }


    
    //Transfer Functions
    function transferFrom(address tkn, address from, uint amount) internal {
        SafeERC20.safeTransferFrom(IERC20(tkn), from, address(this),  amount);
    }

    function transferTo(address tkn, address to, uint amount) internal {
        SafeERC20.safeTransfer(IERC20(tkn), to, amount);
    }

    //Fee Functions
    function bondFee(uint number, uint _fee) public pure returns (uint) {
        return (_fee*number)/BASIS_POINTS;
    }
    function applyFee(uint number, uint _fee) public pure returns (uint) {
        return number-((_fee*number)/BASIS_POINTS);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TradeInterface {
    //PART 1: FUNCTIONS

    /**
     * @dev Submits a new order.
     * @param direction The direction parameters of the order (source asset, destination asset, and destination chain ID).
     * @param funding The funding parameters of the order (amount, minimum output, bond fee, bond asset, and bond amount).
     * @param expiration The expiration parameters of the order (timestamp, challenge offset, and challenge window).
     * @param isMaker Indicates if the order maker is placing the order.
     */
    function placeOrder(
        OrderDirection memory direction,
        OrderFunding memory funding,
        OrderExpiration memory expiration,
        bool isMaker
    ) external;


    /**
     * @dev Creates a new match between orders.
     * @param direction The direction parameters of the source order (source asset, destination asset, and destination chain ID).
     * @param srcIndex The index of the source order.
     * @param dstIndex The index of the destination order.
     * @param Counterparty The wallet on the destination chain. This must be the same address as dest_order.sender
     * @param srcQuantity The quantity of srcAsset in the match.
     * @param dstQuantity The quantity of dstAsset in the match.
     */
    function createMatch(
        OrderDirection memory direction,
        uint32 srcIndex,
        uint32 dstIndex,
        address Counterparty,
        uint96 srcQuantity,
        uint96 dstQuantity
    ) external;

    /**
     * @dev Executes an existing match.
     * @param direction The direction parameters of the source order (source asset, destination asset, and destination chain ID).
     * @param srcIndex The index of the source order.
     * @param dstIndex The index of the destination order.
     * @param srcQuantity The quantity of srcAsset in the match.
     * @param dstQuantity The quantity of dstAsset in the match.
     */
    function executeMatch(
        OrderDirection memory direction,
        uint32 srcIndex,
        uint32 dstIndex,
        address Counterparty,
        uint96 srcQuantity,
        uint96 dstQuantity,
        bool isUnwrap
    ) external;

    /**
     * @dev Confirms a match.
     * @param srcIndex The index of the source order.
     */
    function confirmMatch(
        OrderDirection memory direction,
        uint32 srcIndex
    ) external;

    /**
     * @dev Cancels an order.
     * @param direction The direction parameters of the source order (source asset, destination asset, and destination chain ID).
     * @param orderIndex The index of the order.
     */
    function cancelOrder(
        OrderDirection memory direction,
        uint32 orderIndex
    ) external;

    /**
     * @dev Challenges an existing match.
     * @param direction The direction parameters of the source order (source asset, destination asset, and destination chain ID).
     * @param srcIndex The nonce of the match.
     */
    function unwindMatch(
        OrderDirection memory direction,
        uint32 srcIndex
    ) external;


    /**
     * @dev Challenges an existing match.
     * @param direction The direction parameters of the source order (source asset, destination asset, and destination chain ID).
     * @param srcIndex The nonce of the match.
     */
    function challengeMatch(
        OrderDirection memory direction,
        uint32 srcIndex,
        bytes calldata _extraSendOptions, // gas settings for A -> B
        bytes calldata _extraReturnOptions // gas settings for B -> A
    ) external payable;


    // PART 2: STRUCTS
    
    
    /**
     * @dev Struct representing an order.
     * @param sender The address of the order creator.
     * @param direction The direction parameters of the order.
     * @param funding The funding parameters of the order.
     * @param expiration The expiration parameters of the order.
     * @param isMaker Indicates if the order maker is placing the order.
     */
    struct Order {
        address sender;
        OrderFunding funding;
        OrderExpiration expiration;
        uint96 settled;
        bool isMaker;
    }
    /**
     * @dev Struct for direction parameters of an order.
     * @param srcAsset The source asset being offered.
     * @param dstAsset The destination asset desired.
     * @param dstLzc The chain ID of the destination chain.
     */
    struct OrderDirection {
        address srcAsset;
        address dstAsset;
        uint32 dstLzc;
    }

    /**
     * @dev Struct for funding parameters of an order.
     * @param amount The quantity of srcAsset being offered.
     * @param dstOutput The minimum quantity of dstAsset to be received.
     * @param bondFee The basis points percentage which will go to the bonder.
     * @param bondAsset The asset used for the bond.
     * @param bondAmount The amount of the bond asset.
     */
    struct OrderFunding {
        uint96 amount;
        uint96 dstOutput;
        uint16 bondFee;
        address bondAsset; 
        uint96 bondAmount;
    }

    /**
     * @dev Struct for expiration parameters of an order.
     * @param timestamp The timestamp when the order was created.
     * @param challengeOffset The offset for the challenge window start.
     * @param challengeWindow The duration of the challenge window in seconds.
     */
    struct OrderExpiration {
        uint32 timestamp;
        uint16 challengeOffset; 
        uint16 challengeWindow;
    }


    /**
    * @dev Represents a match between orders in the trading system.
    * @param dstIndex Index of the destination order.
    * @param srcQuantity Quantity of srcAsset in the match.
    * @param dstQuantity Quantity of dstAsset in the match.
    * @param receiver Address to receive the destination asset.
    * @param bonder Address of the bonder.
    * @param blockNumber Block number when the match was created.
    * @param finalized Whether the match has been executed.
    * @param challenged Whether the match is locked.
    */
    struct Match {
        uint32 dstIndex;              // Index of the destination order
        // Pricing
        uint96 srcQuantity;           // Quantity of srcAsset in the match
        uint96 dstQuantity;           // Quantity of dstAsset in the match
        // Counterparty
        address receiver;             // Address to receive the destination asset
        address bonder;               // Address of the bonder
        // Security
        uint96 blockNumber;           // Block number when the match was created
        bool finalized;               // Whether the match has been finalized
        bool challenged;              // Whether the match is locked.
    }

    /**
    * @dev Represents a recipet
    * @param payoutQuantity how much got paid
    * @param receiver to whom it was paid
    */
    struct Receipt {
        uint96 payoutQuantity;           // Quantity of srcAsset in the match
        address receiver;             // Address of who got the funds
    }

    struct Pair {
        address             src;
        address             dst;
        uint16              lzc;
        Order[] orders;
        mapping(uint => Match) matches; //indexed by taker order id
        mapping(uint => mapping(uint => Receipt)) receipts; // indexed by maker order id and corresponding contra-taker order id
    }

    struct Payload {
        address sender;
        uint32 srcLzc;
        address srcToken;
        address dstToken;
        uint32 srcIndex;
        uint32 dstIndex;
        address taker;
        uint minAmount;
        uint status; //0 means undecided, 1 means challenge is true and succeeded, 2 means challenge failed
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWrapped {
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}