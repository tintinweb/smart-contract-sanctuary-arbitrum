// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @title Minimal ERC20 interface for lighter
/// @notice Contains a subset of the full ERC20 interface that is used in lighter
interface IERC20Minimal {
    /// @notice Returns the balance of the account provided
    /// @param account The account to get the balance of
    /// @return balance The balance of the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers given amount of tokens from caller to the recipient
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return success Returns true for a successful transfer, false for unsuccessful
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Transfers given amount of tokens from the sender to the recipient
    /// @param sender The sender of the transfer
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return success Returns true for a successful transfer, false for unsuccessful
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /// @return decimals Returns the decimals of the token
    function decimals() external returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @title Factory Interface
/// @notice The Factory facilitates creation of order books
interface IFactory {
    struct OrderBookDetails {
        address orderBookAddress;
        uint8 orderBookId;
        address token0;
        address token1;
        uint128 sizeTick;
        uint128 priceMultiplier;
        uint128 priceDivider;
        uint64 minToken0BaseAmount;
        uint128 minToken1BaseAmount;
    }

    /// @notice Event emitted when a new order book is created
    /// @param orderBookAddress The address of the new order book
    /// @param orderBookId The id of the new order book
    /// @param token0 The base token of the new order book
    /// @param token1 The quote token of the new order book
    /// @param logSizeTick log10 of base token tick, size of the base token
    /// should be multiples of 10**logSizeTick for limit orders
    /// @param logPriceTick log10 of price tick, price of unit base token
    /// should be multiples of 10**logPriceTick for limit orders
    /// @param minToken0BaseAmount minimum token0Base amount for limit orders
    /// @param minToken1BaseAmount minimum token1Base amount (token0Base * priceBase) for limit orders
    event OrderBookCreated(
        address orderBookAddress,
        uint8 orderBookId,
        address token0,
        address token1,
        uint8 logSizeTick,
        uint8 logPriceTick,
        uint64 minToken0BaseAmount,
        uint128 minToken1BaseAmount
    );

    /// @notice Event emitted when the owner is changed
    /// @param owner Address of the new owner
    event OwnerChanged(address owner);

    /// @notice Creates a new orderBook
    /// @param token0 The contract address of the base token
    /// @param token1 The contract address of the quote token
    /// @param logSizeTick log10 of the base token size tick
    /// @param logPriceTick log10 of the price tick
    /// @param minToken0BaseAmount minimum token0Base amount for limit order
    /// @param minToken1BaseAmount minimum token1Base amount (token0Base * priceBase) for limit order
    /// @return orderBookAddress The address of the deployed order book
    function createOrderBook(
        address token0,
        address token1,
        uint8 logSizeTick,
        uint8 logPriceTick,
        uint64 minToken0BaseAmount,
        uint128 minToken1BaseAmount
    ) external returns (address);

    /// @notice Sets the owner of the factory
    /// @param newOwner The address of the new owner
    function setOwner(address newOwner) external;

    /// @notice Get the details of all order books
    /// @return orderBooksDetails OrderBookDetails[] array containing the details for all order books
    function getAllOrderBooksDetails() external view returns (OrderBookDetails[] memory);

    /// @notice Returns the address of the order book for a given token pair, or address 0 if it does not exist
    /// @param token0 The contract address the first token
    /// @param token1 The contract address the second token
    /// @return orderBookAddress The address of the order book
    function getOrderBookFromTokenPair(address token0, address token1) external view returns (address);

    /// @notice Returns the address of the order book for the given order book id
    /// @param orderBookId The id of the order book to lookup
    /// @return orderBookAddress The address of the order book
    function getOrderBookFromId(uint8 orderBookId) external view returns (address);

    /// @notice Returns the details of the order book for a given token pair
    /// @param token0 The first token of the order book
    /// @param token1 The second token of the order book
    /// @return orderBookDetails the details of the order book
    function getOrderBookDetailsFromTokenPair(
        address token0,
        address token1
    ) external view returns (OrderBookDetails memory);

    /// @notice Returns the details of the order book for a given order book id
    /// @param orderBookId The id of the order book to lookup
    /// @return orderBookDetails the details of the order book
    function getOrderBookDetailsFromId(uint8 orderBookId) external view returns (OrderBookDetails memory);

    /// @notice Returns the constant value of the order book capacity
    /// @return ORDERBOOK_ID_THRESHOLD capacity of order books
    function ORDERBOOK_ID_THRESHOLD() external view returns (uint256);

    /// @notice Returns the current owner of the factory
    /// @return owner The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the id of the next order book to create
    /// @return orderBookIdCounter id of the next order book
    function orderBookIdCounter() external view returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./external/IERC20Minimal.sol";

/// @title Callback for IOrderBook#swapExactSingle and IOrderBook#createOrder
/// @notice Any contract that calls IOrderBook#swapExactSingle and IOrderBook#createOrder must implement this interface with one exception
/// @dev If orderType is PerformanceLimitOrder, then no need to implement this interface
/// @dev PerformanceLimitOrder handles payments with pre-deposited funds by market-makers
interface ILighterV2TransferCallback {
    /// @notice Called by order book after transferring received assets from IOrderBook#swapExactInput or IOrderBook#swapExactOutput for payments
    /// @dev In the implementation order creator must pay the order book the assets for the order
    /// The caller of this method must be checked to be an order book deployed by the Factory
    /// @param callbackData Data passed through by the caller via the IOrderBook#swapExactSingle or IOrderBook#swapExactOutput call
    function lighterV2TransferCallback(
        uint256 debitTokenAmount,
        IERC20Minimal debitToken,
        bytes calldata callbackData
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "../libraries/LinkedList.sol";
import "./external/IERC20Minimal.sol";

/// @title Order Book Interface
/// @notice Order book implements spot trading endpoints and storage for two assets which conform to the IERC20Minimal specification.
interface IOrderBook {
    /// @notice Limit Order type.
    enum OrderType {
        LimitOrder, // Limit order
        PerformanceLimitOrder, // Limit order that uses claimable balances
        FoKOrder, // Fill or Kill limit order
        IoCOrder // Immediate or Cancel limit order
    }

    /// @notice Struct to use for storing limit orders
    struct LimitOrder {
        uint32 perfMode_creatorId; // lowest bit for perfMode, remaining 31 bits for creatorId
        uint32 prev; // id of the previous order in the list
        uint32 next; // id of the next order in the list
        uint32 ownerId; // id of the owner of the order
        uint64 amount0Base; // amount0Base of the order
        uint64 priceBase; // priceBase of the order
    }

    /// @notice Struct to use returning the paginated orders
    struct OrderQueryItem {
        bool isAsk; // true if the paginated orders are ask orders, false if bid orders
        uint32[] ids; // order ids of returned orders
        address[] owners; // owner addresses of returned orders
        uint256[] amount0s; // amount0s of returned orders (amount0Base * sizeTick)
        uint256[] prices; // prices of returned orders (priceBase * priceTick)
    }

    /// @notice Emitted when a limit order gets created
    /// @param owner The address of the order owner
    /// @param id The id of the order
    /// @param amount0Base The amount of token0 in the limit order in terms of number of sizeTicks
    /// @param priceBase The price of the token0 in terms of price ticks
    /// @param isAsk Whether the order is an ask order
    /// @param orderType type of the order
    event CreateOrder(
        address indexed owner,
        uint32 indexed id,
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        OrderType orderType
    );

    /// @notice Emitted when a limit order gets canceled
    /// @param id The id of the canceled order
    event CancelLimitOrder(uint32 indexed id);

    /// @notice Emitted when a taker initiates a swap (market order)
    /// @param sender The address that initiated the swap
    /// @param recipient The address that received the tokens from the swap
    /// @param isExactInput Whether the input amount is exact or output amount is exact
    /// @param isAsk Whether the order is an ask order
    /// @param swapAmount0 The amount of token0 that was swapped
    /// @param swapAmount1 The amount of token1 that was swapped
    event SwapExactAmount(
        address indexed sender,
        address indexed recipient,
        bool isExactInput,
        bool isAsk,
        uint256 swapAmount0,
        uint256 swapAmount1
    );

    /// @notice Emitted when a maker gets filled by a taker
    /// @param askId The id of the ask order
    /// @param bidId The id of the bid order
    /// @param askOwner The address of the ask order owner
    /// @param bidOwner The address of the bid order owner
    /// @param amount0 The amount of token0 that was swapped
    /// @param amount1 The amount of token1 that was swapped
    event Swap(
        uint32 indexed askId,
        uint32 indexed bidId,
        address askOwner,
        address bidOwner,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when flashLoan is called
    /// @param sender The address that initiated the flashLoan, and that received the callback
    /// @param recipient The address that received the tokens from flash loan
    /// @param amount0 The amount of token0 that was flash loaned
    /// @param amount1 The amount of token1 that was flash loaned
    event FlashLoan(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1);

    /// @notice Emitted when user claimable balance is increased due to deposit or order operations
    event ClaimableBalanceIncrease(address indexed owner, uint256 amountDelta, bool isToken0);

    /// @notice Emitted when user claimable balance is decreased due to withdraw or order operations
    event ClaimableBalanceDecrease(address indexed owner, uint256 amountDelta, bool isToken0);

    /// @notice Creates a limit order.
    /// @param amount0Base The amount of token0 in the limit order in terms of number of sizeTicks.
    /// amount0 is calculated by multiplying amount0Base by sizeTick.
    /// @param priceBase The price of the token0 in terms of price ticks.
    /// amount1 is calculated by multiplying priceBase by sizeTick and priceMultiplier and dividing by priceDivider.
    /// @param isAsk Whether the order is an ask order
    /// @param owner The address which will receive the funds and that can
    /// cancel this order. When called by a router, it'll be populated
    /// with msg.sender. Smart wallets should use msg.sender directly.
    /// @param hintId Hint on where to insert the order in the order book.
    /// Can be calculated with suggestHintId function, is not used for FoK and IoC orders.
    /// @param orderType type of the order, if FoK or IoC remaining order will not be added for future matches.
    /// @param callbackData data to be passed to callback
    /// @return id The id of the order
    function createOrder(
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        address owner,
        uint32 hintId,
        OrderType orderType,
        bytes memory callbackData
    ) external returns (uint32);

    /// @notice Cancels an outstanding limit order. Refunds the remaining tokens in the order to the owner
    /// @param id The id of the order to cancel
    /// @param owner The address of the order sender
    /// @return isCanceled Whether the order was successfully canceled or not
    function cancelLimitOrder(uint32 id, address owner) external returns (bool);

    /// @notice Swaps exact input or output amount of token0 or token1 for the other token
    /// @param isAsk Whether the order is an ask order, if true sender pays token0 and receives token1
    /// @param isExactInput Whether the input amount is exact or output amount is exact
    /// @param exactAmount exact token amount to swap (can be token0 or token1 based on isAsk and isExactInput)
    /// @param expectedAmount expected token amount to receive (can be token0 or token1 based on isAsk and isExactInput).
    /// if isExactInput is true, then expectedAmount is the minimum amount to receive.
    /// if isExactInput is false, then expectedAmount is the maximum amount to pay
    /// @param recipient The address which will receive the output
    /// @param callbackData data to be passed to callback
    function swapExactSingle(
        bool isAsk,
        bool isExactInput,
        uint256 exactAmount,
        uint256 expectedAmount,
        address recipient,
        bytes memory callbackData
    ) external returns (uint256, uint256);

    /// @notice Flash loans token0 and token1 to the recipient, sender receives the callback
    /// @param recipient The address which will receive the token0 and token1
    /// @param amount0 The amount of token0 to flash loan
    /// @param amount1 The amount of token1 to flash loan
    /// @param callbackData data to be passed to callback
    function flashLoan(address recipient, uint256 amount0, uint256 amount1, bytes calldata callbackData) external;

    /// @notice Deposits token0 or token1 from user to the order book and marks it as claimable
    /// to be used for performance limit orders for gas efficient limit order creations.
    /// @param amountToDeposit Amount to deposit
    /// @param isToken0 Whether the deposit is token0 or token1
    /// @param callbackData Byte data to send to callback
    function depositToken(uint256 amountToDeposit, bool isToken0, bytes memory callbackData) external;

    /// @notice Withdraws deposited or swapped token0 or token1 to the owner.
    /// @param amountToClaim Amount to withdraw
    /// @param isToken0 Whether the claimable token is token0 or token1
    function claimToken(uint256 amountToClaim, bool isToken0) external;

    /// @notice Finds the order id where the new order should be inserted to the right of
    /// Meant to be used off-chain to find the hintId for limit order creation functions
    /// @param priceBase basePrice derived from amount0Base and amount1Base
    /// @param isAsk Whether the new order is an ask order
    /// @return hintId The id of the order where the new order
    /// should be inserted to the right of
    function suggestHintId(uint64 priceBase, bool isAsk) external view returns (uint32);

    /// @notice Returns the amount of token0 and token1 to traded between two limit orders
    /// @param takerOrderAmount0Base The amount0Base of the taker order
    /// @param takerOrderPriceBase The priceBase of the taker order
    /// @param makerOrderAmount0Base The amount0Base of the maker order
    /// @param makerOrderPriceBase The priceBase of the maker order
    /// @param isTakerAsk True if taker order is an ask
    /// @return amount0BaseReturn The amount0Base to be traded
    /// @return amount1BaseReturn The amount1Base to be traded
    function getLimitOrderSwapAmounts(
        uint64 takerOrderAmount0Base,
        uint64 takerOrderPriceBase,
        uint64 makerOrderAmount0Base,
        uint64 makerOrderPriceBase,
        bool isTakerAsk
    ) external pure returns (uint64, uint128);

    /// @notice Returns the amount of token0 and token1 to traded between maker and swapper
    /// @param amount0 Exact token0 amount taker wants to trade
    /// @param isAsk True if swapper is an ask
    /// @param makerAmount0Base The amount0Base of the maker order
    /// @param makerPriceBase The priceBase of the maker order
    /// @return swapAmount0 The amount of token0 to be swapped
    /// @return swapAmount1 The amount of token1 to be swapped
    /// @return amount0BaseDelta Maker order baseAmount0 change
    /// @return fullTakerFill True if swapper can be fully filled by maker order
    function getSwapAmountsForToken0(
        uint256 amount0,
        bool isAsk,
        uint64 makerAmount0Base,
        uint64 makerPriceBase
    ) external view returns (uint256, uint256, uint64, bool);

    /// @notice Returns the amount of token0 and token1 to traded between maker and swapper
    /// @param amount1 Exact token1 amount taker wants to trade
    /// @param isAsk True if swapper is an ask
    /// @param makerAmount0Base The amount0Base of the maker order
    /// @param makerPriceBase The priceBase of the maker order
    /// @return swapAmount0 The amount of token0 to be swapped
    /// @return swapAmount1 The amount of token1 to be swapped
    /// @return amount0BaseDelta Maker order baseAmount0 change
    /// @return fullTakerFill True if swapper can be fully filled by maker order
    function getSwapAmountsForToken1(
        uint256 amount1,
        bool isAsk,
        uint64 makerAmount0Base,
        uint64 makerPriceBase
    ) external view returns (uint256, uint256, uint64, bool);

    /// @notice Returns price sorted limit orders with pagination
    /// @param startOrderId orderId from where the pagination should start (not inclusive)
    /// @dev caller can pass 0 to start from the top of the book
    /// @param isAsk Whether to return ask or bid orders
    /// @param limit Number number of orders to return in the page
    /// @return orderData The paginated order data
    function getPaginatedOrders(
        uint32 startOrderId,
        bool isAsk,
        uint32 limit
    ) external view returns (OrderQueryItem memory orderData);

    /// @notice Returns the limit order of the given index
    /// @param isAsk Whether the order is an ask order
    /// @param id The id of the order
    /// @return order The limit order
    function getLimitOrder(bool isAsk, uint32 id) external view returns (LimitOrder memory);

    /// @notice Returns whether an order is active or not
    /// @param id The id of the order
    /// @return isActive True if the order is active, false otherwise
    function isOrderActive(uint32 id) external view returns (bool);

    /// @notice Returns whether an order is an ask order or not, fails if order is not active
    /// @param id The id of the order
    /// @return isAsk True if the order is an ask order, false otherwise
    function isAskOrder(uint32 id) external view returns (bool);

    /// @notice Returns the constant for Log value of TickThreshold
    /// @return LOG10_TICK_THRESHOLD threshold for Log value of TickThreshold
    function LOG10_TICK_THRESHOLD() external view returns (uint8);

    /// @notice Returns the constant for threshold value of orderId
    /// @return ORDER_ID_THRESHOLD threshold for threshold value of orderId
    function ORDER_ID_THRESHOLD() external view returns (uint32);

    /// @notice Returns the constant for threshold value of creatorId
    /// @return CREATOR_ID_THRESHOLD threshold for threshold value of creatorId
    function CREATOR_ID_THRESHOLD() external view returns (uint32);

    /// @notice The token0 (base token)
    /// @return token0 The token0 (base token) contract
    function token0() external view returns (IERC20Minimal);

    /// @notice The token1 (quote token)
    /// @return token1 The token1 (quote token) contract
    function token1() external view returns (IERC20Minimal);

    /// @notice Id of the order book
    /// @return orderBookId The unique identifier of an order book
    function orderBookId() external view returns (uint8);

    /// @notice The sizeTick of the order book
    /// @return sizeTick The sizeTick of the order book
    function sizeTick() external view returns (uint128);

    /// @notice The priceTick of the order book
    /// @return priceTick The priceTick of the order book
    function priceTick() external view returns (uint128);

    /// @notice The priceMultiplier of the order book
    /// @return priceMultiplier The priceMultiplier of the order book
    function priceMultiplier() external view returns (uint128);

    /// @notice The priceDivider of the order book
    /// @return priceDivider The priceMultiplier of the order book
    function priceDivider() external view returns (uint128);

    /// @notice Returns the id of the next order Id to create
    /// @return orderIdCounter id of the next order
    function orderIdCounter() external view returns (uint32);

    /// @notice minToken0BaseAmount minimum token0Base amount for limit order
    /// @return minToken0BaseAmount minToken0BaseAmount of the order book
    function minToken0BaseAmount() external view returns (uint64);

    /// @notice minToken1BaseAmount minimum token1Base amount (token0Base * priceBase) for limit order
    /// @return minToken1BaseAmount minToken1BaseAmount of the order book
    function minToken1BaseAmount() external view returns (uint128);

    /// @notice Claimable token0 amount for given address
    /// @return claimableToken0Balance Claimable token0 amount for given address
    function claimableToken0Balance(address owner) external view returns (uint256);

    /// @notice Claimable token1 amount for given address
    /// @return claimableToken1Balance Claimable token1 amount for given address
    function claimableToken1Balance(address owner) external view returns (uint256);

    /// @notice id of an order-owner
    /// @return addressToOwnerId id of an order-owner
    function addressToOwnerId(address owner) external view returns (uint32);

    /// @notice address for given creatorId
    /// @return addressToCreatorId address for given creatorId
    function addressToCreatorId(address creatorAddress) external view returns (uint32);

    /// @notice id of a creatorAddress
    /// @return creatorIdToAddress id of a creatorAddress
    function creatorIdToAddress(uint32 creatorId) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @title Errors
/// @notice Library containing errors that Lighter V2 Core functions may revert with
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                      LIGHTER-V2-FACTORY
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when `msg.sender` is not the factory owner for setOwner or createOrderBook
    error LighterV2Factory_CallerNotOwner();

    /// @notice Thrown when zero address is passed when setting the owner
    error LighterV2Factory_OwnerCannotBeZero();

    /*//////////////////////////////////////////////////////////////////////////
                                      LIGHTER-V2-CREATE-ORDER-BOOK
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when token0 and token1 are identical or zero in order book creation
    error LighterV2CreateOrderBook_InvalidTokenPair();

    /// @notice Thrown when an order book already exists with given token0 and token1 in order book creation
    error LighterV2CreateOrderBook_OrderBookAlreadyExists();

    /// @notice Thrown when order book capacity is already reached in order book creation
    error LighterV2CreateOrderBook_OrderBookIdExceedsLimit();

    /// @notice Thrown when invalid combination of logSizeTick and logPriceTick is given in order book creation
    error LighterV2CreateOrderBook_InvalidTickCombination();

    /// @notice Thrown when invalid combination of minToken0BaseAmount and minToken1BaseAmount given in order book creation
    error LighterV2CreateOrderBook_InvalidMinAmount();

    /*//////////////////////////////////////////////////////////////////////////
                                  LIGHTER-V2-ORDER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when invalid hintId is given in limit order creation
    error LighterV2Order_InvalidHintId();

    /// @notice Thrown when given price is too small in order creation
    error LighterV2Order_PriceTooSmall();

    /// @notice Thrown when given price is too big in order creation
    error LighterV2Order_PriceTooBig();

    /// @notice Thrown when token0 or token1 amount is too small in limit order creation
    error LighterV2Order_AmountTooSmall();

    /// @notice Thrown when order capacity is already reached in order creation
    error LighterV2Order_OrderIdExceedsLimit();

    /// @notice Thrown when creator capacity is already reached in order creation
    error LighterV2Order_CreatorIdExceedsLimit();

    /// @notice Thrown when tokens sent callback is insufficient in order creation or swap
    error LighterV2Order_InsufficentCallbackTransfer();

    /// @notice Thrown when claimable balance is insufficient in order creation
    error LighterV2Order_InsufficientClaimableBalance();

    /// @notice Thrown when FillOrKill order is not fully filled
    error LighterV2Order_FoKNotFilled();

    /// @notice Thrown when contract balance decrease is larger than the transfered amount
    error LighterV2Base_ContractBalanceDoesNotMatchSentAmount();

    /// @notice Thrown when caller is not the order creator or owner in order cancelation
    error LighterV2Owner_CallerCannotCancel();

    /// @notice Thrown when caller tries to erase head or tail orders in order linked list
    error LighterV2Order_CannotEraseHeadOrTailOrders();

    /// @notice Thrown when caller tries to cancel an order that is not active
    error LighterV2Order_CannotCancelInactiveOrders();

    /// @notice Thrown when caller asks for order side for a inactive or non-existent order
    error LighterV2Order_OrderDoesNotExist();

    /// @notice Thrown when caller tries to query an order book page starting from an inactive order
    error LighterV2Order_CannotQueryFromInactiveOrder();

    /*//////////////////////////////////////////////////////////////////////////
                                  LIGHTER-SWAP
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when order book does not have enough liquidity to fill the swap
    error LighterV2Swap_NotEnoughLiquidity();

    /// @notice Thrown when swapper receives less than the minimum amount of tokens expected
    error LighterV2Swap_NotEnoughOutput();

    /// @notice Thrown when swapper needs to pay more than the maximum amount of tokens they are willing to pay
    error LighterV2Swap_TooMuchRequested();

    /*//////////////////////////////////////////////////////////////////////////
                                  LIGHTER-V2-VAULT
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when caller tries to withdraw more than their balance or withdraw zero
    error LighterV2Vault_InvalidClaimAmount();

    /// @notice Thrown when caller does not tranfer enough tokens to the vault when depositing
    error LighterV2Vault_InsufficentCallbackTransfer();
    /*//////////////////////////////////////////////////////////////////////////
                                  LIGHTER-V2-FLASH-LOAN
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when caller does not tranfer enough tokens to repay for the flash loan
    error LighterV2FlashLoan_InsufficentCallbackTransfer();

    /*//////////////////////////////////////////////////////////////////////////
                                  LIGHTER-V2-TOKEN-TRANSFER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when token transfer from order book fails
    error LighterV2TokenTransfer_Failed();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./Errors.sol";
import "../interfaces/IOrderBook.sol";

/// @title LinkedList
/// @notice Struct to use for storing sorted linked lists of ask and bid orders
struct LinkedList {
    mapping(uint32 => IOrderBook.LimitOrder) asks;
    mapping(uint32 => IOrderBook.LimitOrder) bids;
}

/// @title LinkedListLib
/// @notice Implements a sorted linked list of limit orders and provides necessary functions for order management
/// @dev Head is represented by order id 0, tail is represented by order id 1
library LinkedListLib {
    /// @notice Inserts an order into the respective linked list and keeps sorted order
    /// @param orderId id of the order to insert
    /// @param isAsk true if the order is an ask order, false if the order is a bid order
    /// @param hintId hint id of the order where the new order should be inserted to the right of
    function insert(LinkedList storage self, uint32 orderId, bool isAsk, uint32 hintId) internal {
        mapping(uint32 => IOrderBook.LimitOrder) storage orders = isAsk ? self.asks : self.bids;
        IOrderBook.LimitOrder storage order = orders[orderId];

        if (orders[hintId].next == 0) {
            revert Errors.LighterV2Order_InvalidHintId();
        }

        while (orders[hintId].ownerId == 0) {
            hintId = orders[hintId].next;
        }

        // After the search, hintId will be where the new order should be inserted to the right of
        IOrderBook.LimitOrder memory hintOrder = orders[hintId];
        while (hintId != 1) {
            IOrderBook.LimitOrder memory nextOrder = orders[hintOrder.next];
            if (isAsk ? (order.priceBase < nextOrder.priceBase) : (order.priceBase > nextOrder.priceBase)) break;
            hintId = hintOrder.next;
            hintOrder = nextOrder;
        }
        while (hintId != 0) {
            if (isAsk ? (order.priceBase >= hintOrder.priceBase) : (order.priceBase <= hintOrder.priceBase)) break;
            hintId = hintOrder.prev;
            hintOrder = orders[hintId];
        }

        order.prev = hintId;
        order.next = orders[hintId].next;
        orders[order.prev].next = orderId;
        orders[order.next].prev = orderId;
    }

    /// @notice Removes given order id from the respective linked list
    /// @dev Updates the respective linked list but does not delete the order, sets the ownerId to 0 instead
    /// @param orderId The order id to remove
    /// @param isAsk true if the order is an ask order, false if the order is a bid order
    function erase(LinkedList storage self, uint32 orderId, bool isAsk) internal {
        if (orderId <= 1) {
            revert Errors.LighterV2Order_CannotEraseHeadOrTailOrders();
        }

        mapping(uint32 => IOrderBook.LimitOrder) storage orders = isAsk ? self.asks : self.bids;

        if (orders[orderId].ownerId == 0) {
            revert Errors.LighterV2Order_CannotCancelInactiveOrders();
        }
        IOrderBook.LimitOrder storage order = orders[orderId];
        order.ownerId = 0;

        uint32 prev = order.prev;
        uint32 next = order.next;
        orders[prev].next = next;
        orders[next].prev = prev;
    }

    /// @notice Returns a struct that represents order page with given parameters
    /// @param startOrderId The order id to start the pagination from (not inclusive)
    /// @param isAsk true if the paginated orders are ask orders, false if bid orders
    /// @param limit The number of orders to return
    /// @param ownerIdToAddress Mapping from owner id to owner address
    /// @param sizeTick The size tick of the order book
    /// @param priceTick The price tick of the order book
    function getPaginatedOrders(
        LinkedList storage self,
        uint32 startOrderId,
        bool isAsk,
        uint32 limit,
        mapping(uint32 => address) storage ownerIdToAddress,
        uint128 sizeTick,
        uint128 priceTick
    ) public view returns (IOrderBook.OrderQueryItem memory paginatedOrders) {
        mapping(uint32 => IOrderBook.LimitOrder) storage orders = isAsk ? self.asks : self.bids;

        if (orders[startOrderId].ownerId == 0) {
            revert Errors.LighterV2Order_CannotQueryFromInactiveOrder();
        }
        uint32 i = 0;
        paginatedOrders.ids = new uint32[](limit);
        paginatedOrders.owners = new address[](limit);
        paginatedOrders.amount0s = new uint256[](limit);
        paginatedOrders.prices = new uint256[](limit);
        for (uint32 pointer = orders[startOrderId].next; pointer != 1 && i < limit; pointer = orders[pointer].next) {
            IOrderBook.LimitOrder memory order = orders[pointer];
            paginatedOrders.ids[i] = pointer;
            paginatedOrders.owners[i] = ownerIdToAddress[order.ownerId];
            paginatedOrders.amount0s[i] = uint256(order.amount0Base) * sizeTick;
            paginatedOrders.prices[i] = order.priceBase * priceTick;
            unchecked {
                ++i;
            }
        }
        paginatedOrders.isAsk = isAsk;
    }

    /// @notice Finds the order id where the order with given price should be inserted to the right of
    /// @param priceBase The priceBase to suggest the hintId for
    /// @return hintId The order id where the order with given price should be inserted to the right of
    function suggestHintId(LinkedList storage self, uint64 priceBase, bool isAsk) public view returns (uint32) {
        mapping(uint32 => IOrderBook.LimitOrder) storage orders = isAsk ? self.asks : self.bids;
        uint32 hintOrderId = 0;
        IOrderBook.LimitOrder memory hintOrder = orders[hintOrderId];
        while (hintOrderId != 1) {
            IOrderBook.LimitOrder memory nextOrder = orders[hintOrder.next];
            if (isAsk ? (priceBase < nextOrder.priceBase) : (priceBase > nextOrder.priceBase)) break;
            hintOrderId = hintOrder.next;
            hintOrder = nextOrder;
        }
        return hintOrderId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)
pragma solidity 0.8.18;

import "@elliottech/lighter-v2-core/contracts/interfaces/external/IERC20Minimal.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title SafeTransferLib
/// @author OpenZeppelin (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @notice Modified safe transfer library for Lighter V2 Periphery
library SafeTransferLib {
    using Address for address;

    /// @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
    /// non-reverting calls are assumed to be successful
    function safeTransfer(IERC20Minimal token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /// @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
    /// calling contract. If `token` returns no value, non-reverting calls are assumed to be successful
    function safeTransferFrom(IERC20Minimal token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /// @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
    /// on the return value: the return value is optional (but if data is returned, it must not be false)
    /// @param token The token targeted by the call
    /// @param data The call data (encoded using abi.encode or one of its variants)
    function _callOptionalReturn(IERC20Minimal token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@elliottech/lighter-v2-core/contracts/interfaces/IFactory.sol";
import "@elliottech/lighter-v2-core/contracts/interfaces/IOrderBook.sol";
import "@elliottech/lighter-v2-core/contracts/interfaces/ILighterV2TransferCallback.sol";
import "../libraries/SafeTransfer.sol";

/// @title SmartWallet
/// @notice A contract that acts as a smart wallet interacting with an order book contract.
contract SmartWallet is ILighterV2TransferCallback {
    using SafeTransferLib for IERC20Minimal;

    /// @notice address of the owner of smartWallet
    address public immutable owner;

    /// @notice factory instance used to query orderBooks by ID
    IFactory public immutable factory;

    /// @dev Modifier that restricts function execution to the contract owner.
    /// The caller must be the owner of the smart wallet.
    modifier onlyOwner() {
        require(msg.sender == owner, "caller must be owner");
        _;
    }

    /// @dev Constructor initializes the smart wallet with a factory contract.
    /// The owner of the smart wallet is set to the sender of the deployment transaction.
    /// @param _factory The address of the factory contract.
    constructor(IFactory _factory) {
        owner = msg.sender;
        factory = _factory;
    }

    /// @dev Callback function called by the `orderBook` contract after a successful transfer.
    /// This function is used to handle the transfer of `debitTokenAmount` of the `debitToken`.
    /// It ensures that only the `orderBook` contract can call this function.
    /// The transferred tokens are then sent back to the sender using the `safeTransfer` function.
    /// @param debitTokenAmount The amount of debit tokens to be transferred.
    /// @param debitToken The ERC20 token used for the transfer.
    /// @param data Additional data that can be provided to the function.
    function lighterV2TransferCallback(
        uint256 debitTokenAmount,
        IERC20Minimal debitToken,
        bytes memory data
    ) external override {
        uint8 orderBookId;
        // unpack data
        assembly {
            orderBookId := mload(add(data, 1))
        }

        address orderBookAddress = factory.getOrderBookFromId(orderBookId);

        require(msg.sender == address(orderBookAddress));

        debitToken.safeTransfer(msg.sender, debitTokenAmount);
    }

    /// @dev Creates multiple limit orders in the order book. Only the contract owner can call this function.
    /// The function processes each order provided in the arrays and creates corresponding limit orders in the order book.
    /// @param orderBookId The id of the order book which will be used.
    /// @param size The number of orders to create.
    /// @param amount0Base An array of amounts denominated in token0 to be used for each order.
    /// @param priceBase An array of prices denominated in token1 for each order.
    /// @param isAsk An array indicating whether each order is an "ask" order (true) or a "bid" order (false).
    /// @param hintId An array of hint IDs to guide order placement in the order book.
    /// @return orderId An array containing the order IDs of the created orders.
    function createLimitOrder(
        uint8 orderBookId,
        uint8 size,
        uint64[] memory amount0Base,
        uint64[] memory priceBase,
        bool[] memory isAsk,
        uint32[] memory hintId
    ) public onlyOwner returns (uint32[] memory orderId) {
        IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(orderBookId));
        orderId = new uint32[](size);
        bytes memory callbackData = abi.encodePacked(orderBookId);
        for (uint8 i; i < size; ) {
            orderId[i] = orderBook.createOrder(
                amount0Base[i],
                priceBase[i],
                isAsk[i],
                address(this),
                hintId[i],
                IOrderBook.OrderType.LimitOrder,
                callbackData
            );
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Creates multiple performance limit orders in the order book. Only the contract owner can call this function.
    /// The function processes each order provided in the arrays and creates corresponding performance limit orders in the order book.
    ///
    /// @param orderBookId The id of the order book which will be used.
    /// @param size The number of orders to create.
    /// @param amount0Base An array of amounts denominated in token0 to be used for each order.
    /// @param priceBase An array of prices denominated in token1 for each order.
    /// @param isAsk An array indicating whether each order is an "ask" order (true) or a "bid" order (false).
    /// @param hintId An array of hint IDs to guide order placement in the order book.
    /// @return orderId An array containing the order IDs of the created orders.
    function createPerformanceLimitOrder(
        uint8 orderBookId,
        uint8 size,
        uint64[] memory amount0Base,
        uint64[] memory priceBase,
        bool[] memory isAsk,
        uint32[] memory hintId
    ) public onlyOwner returns (uint32[] memory orderId) {
        IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(orderBookId));
        orderId = new uint32[](size);
        bytes memory callbackData = abi.encodePacked(orderBookId);
        for (uint8 i; i < size; ) {
            orderId[i] = orderBook.createOrder(
                amount0Base[i],
                priceBase[i],
                isAsk[i],
                address(this),
                hintId[i],
                IOrderBook.OrderType.PerformanceLimitOrder,
                callbackData
            );
            unchecked {
                ++i;
            }
        }
    }

    function createFoKOrder(
        uint8 orderBookId,
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk
    ) public onlyOwner returns (uint32) {
        IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(orderBookId));
        bytes memory callbackData = abi.encodePacked(orderBookId);

        return
            orderBook.createOrder(
                amount0Base,
                priceBase,
                isAsk,
                address(this),
                0,
                IOrderBook.OrderType.FoKOrder,
                callbackData
            );
    }

    function createIoCOrder(
        uint8 orderBookId,
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk
    ) public onlyOwner returns (uint32) {
        IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(orderBookId));
        bytes memory callbackData = abi.encodePacked(orderBookId);

        return
            orderBook.createOrder(
                amount0Base,
                priceBase,
                isAsk,
                address(this),
                0,
                IOrderBook.OrderType.IoCOrder,
                callbackData
            );
    }

    /// @dev Cancels multiple limit orders in the order book. Only the contract owner can call this function.
    /// The function processes each order ID provided in the array and attempts to cancel the corresponding limit orders.
    /// @param orderBookId The id of the order book which will be used.
    /// @param size The number of orders to cancel.
    /// @param orderId An array containing the order IDs to be canceled.
    /// @return isCanceled An array indicating whether each order was successfully canceled.
    function cancelLimitOrder(
        uint8 orderBookId,
        uint8 size,
        uint32[] memory orderId
    ) external onlyOwner returns (bool[] memory isCanceled) {
        IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(orderBookId));
        isCanceled = new bool[](size);
        for (uint256 i; i < size; ) {
            isCanceled[i] = orderBook.cancelLimitOrder(orderId[i], address(this));
            unchecked {
                ++i;
            }
        }
    }

    /// @notice user to swap exact input amount from the orderbook
    /// @param orderBookId The unique identifier of the order book
    /// @param isAsk Whether the order is an ask order
    /// @param exactInput exactInput (can be token0 or token1 based on isAsk)
    /// @param minOutput minimum output amount that is expected during swap (can be token0 or token1 based on isAsk)
    /// @param recipient the address of the recipient, this can be marketTaker or the recipient specified my marketTaker
    function swapExactInput(
        uint8 orderBookId,
        bool isAsk,
        uint256 exactInput,
        uint256 minOutput,
        address recipient
    ) external payable returns (uint256, uint256) {
        IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(orderBookId));
        bytes memory callbackData = abi.encodePacked(orderBookId);

        return orderBook.swapExactSingle(isAsk, true, exactInput, minOutput, recipient, callbackData);
    }

    /// @notice user to swap for exact output amount from the orderbook
    /// @dev for askOrder, user is expecting exact token1 amount
    /// for bidOrder, user is expecting exact token0 amount
    /// @param isAsk Whether the order is an ask order
    /// @param exactOutput exactOutput amount (can be token0 or token1 based on isAsk)
    /// @param maxInput maxInput amount that can be taken during swap (can be token0 or token1 based on isAsk)
    /// @param recipient the address of the recipient, this can be marketTaker or the recipient specified my marketTaker
    function swapExactOutput(
        uint8 orderBookId,
        bool isAsk,
        uint256 exactOutput,
        uint256 maxInput,
        address recipient
    ) external payable returns (uint256, uint256) {
        IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(orderBookId));
        bytes memory callbackData = abi.encodePacked(orderBookId);

        return orderBook.swapExactSingle(isAsk, false, exactOutput, maxInput, recipient, callbackData);
    }

    /// @notice deposit token0 amount to the orderBook
    /// @param orderBookId The id of the order book for depositTo
    /// @param amount The amount of token0 that user want to deposit to the orderbook
    function depositToken0(uint8 orderBookId, uint256 amount) external onlyOwner {
        IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(orderBookId));
        bytes memory callbackData = abi.encodePacked(orderBookId);
        orderBook.depositToken(amount, true, callbackData);
    }

    /// @notice deposit token1 amount to the orderBook
    /// @param orderBookId The id of the order book to depositTo
    /// @param amount The amount of token1 that user want to deposit to the orderbook
    function depositToken1(uint8 orderBookId, uint256 amount) external onlyOwner {
        IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(orderBookId));
        bytes memory callbackData = abi.encodePacked(orderBookId);
        orderBook.depositToken(amount, false, callbackData);
    }

    /// @notice claim token0 amount from the orderBook
    /// @param orderBookId The id of the order book to claim from
    /// @param amount The amount of token0 that user has deposited in the orderbook or can claim from the orderbook
    function claimToken0(uint8 orderBookId, uint256 amount) external onlyOwner {
        IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(orderBookId));
        orderBook.claimToken(amount, true);
    }

    /// @notice claim token1 amount from the orderBook
    /// @param orderBookId The id of the order book to claim from
    /// @param amount The amount of token1 that user has deposited in the orderbook or can claim from the orderbook
    function claimToken1(uint8 orderBookId, uint256 amount) external onlyOwner {
        IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(orderBookId));
        orderBook.claimToken(amount, false);
    }

    /// @notice claim entire claimable token0 and token1 amount from the orderBook
    /// @param orderBookId The id of the order book to claim from
    function claimAll(uint8 orderBookId) external onlyOwner {
        IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(orderBookId));

        uint256 claimable0 = orderBook.claimableToken0Balance(address(this));
        if (claimable0 > 0) {
            orderBook.claimToken(claimable0, true);
        }

        uint256 claimable1 = orderBook.claimableToken1Balance(address(this));
        if (claimable0 > 0) {
            orderBook.claimToken(claimable1, false);
        }
    }
}