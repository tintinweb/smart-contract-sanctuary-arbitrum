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
pragma solidity 0.8.18;

import "@elliottech/lighter-v2-core/contracts/interfaces/external/IERC20Minimal.sol";

/// @title Interface for WETH9 on Arbitrum
/// @notice token functions to facilitate the wrap and unwrap functions during deposit and withdrawal of WETH token
interface IWETH9 is IERC20Minimal {
    /// @notice Withdraw wrapped ether to get ether to a recipient address
    /// @param recipient address to send unwrapped ether
    /// @param amount amount of WETH to be unwrapped during withdrawal
    function withdrawTo(address recipient, uint256 amount) external;

    /// @notice wrap the ether and transfer to a recipient address
    /// @param recipient address to send wrapped ether
    function depositTo(address recipient) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@elliottech/lighter-v2-core/contracts/interfaces/IOrderBook.sol";
import "./ISwapMultiRequest.sol";

/// @title Router Interface
/// @notice A router contract to get OrderBook Details
interface IRouter is ISwapMultiRequest {
    /// @notice Creates multiple limit orders in the given order book
    /// @param orderBookId The unique identifier of the order book
    /// @param size The number of limit orders to create. Size of each array given should be equal to `size`
    /// @param amount0Base The amount of token0 for each limit order in terms of number of sizeTicks.
    /// The exact amount of token0 for each order will be amount0Base[i] * sizeTick
    /// @param priceBase The price of the token0 for each limit order.
    /// Exact price for unit token0 is calculated as priceBase[i] * priceTick
    /// @param isAsk Whether each order is an ask order
    /// @param hintId Where to insert each order in the given order book. Meant to be calculated
    /// off-chain using the suggestHintId function
    /// @return orderId The id of the each created order
    function createLimitOrderBatch(
        uint8 orderBookId,
        uint8 size,
        uint64[] memory amount0Base,
        uint64[] memory priceBase,
        bool[] memory isAsk,
        uint32[] memory hintId
    ) external returns (uint32[] memory orderId);

    /// @notice Creates a limit order in the given order book
    /// @param orderBookId The unique identifier of the order book
    /// @param amount0Base The amount of token0 in terms of number of sizeTicks.
    /// The exact amount of token0 for each order will be amount0Base * sizeTick
    /// @param priceBase The price of the token0. Exact price for unit token0 is calculated as priceBase[i] * priceTick
    /// @param isAsk Whether the order is an ask order
    /// @param hintId Where to insert the order in the given order book, meant to be calculated
    /// off-chain using the suggestHintId function
    /// @return orderId The id of the created order
    function createLimitOrder(
        uint8 orderBookId,
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        uint32 hintId
    ) external returns (uint32 orderId);

    /// @notice Creates a fill or kill order in the given order book
    /// @param orderBookId The unique identifier of the order book
    /// @param amount0Base The amount of token0 in terms of number of sizeTicks.
    /// The exact amount of token0 for each order will be amount0Base * sizeTick
    /// @param priceBase The price of the token0. Exact price for unit token0 is calculated as priceBase[i] * priceTick
    /// @param isAsk Whether the order is an ask order
    /// @return orderId The id of the created order
    function createFoKOrder(
        uint8 orderBookId,
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk
    ) external returns (uint32 orderId);

    /// @notice Creates an immediate or cancel order in the given order book
    /// @param orderBookId The unique identifier of the order book
    /// @param amount0Base The amount of token0 in terms of number of sizeTicks.
    /// The exact amount of token0 for each order will be amount0Base * sizeTick
    /// @param priceBase The price of the token0. Exact price for unit token0 is calculated as priceBase[i] * priceTick
    /// @param isAsk Whether the order is an ask order
    /// @return orderId The id of the created order
    function createIoCOrder(
        uint8 orderBookId,
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk
    ) external returns (uint32 orderId);

    /// @notice Cancels and creates multiple limit orders in the given order book with given parameters
    /// @param orderBookId The unique identifier of the order book
    /// @param size The number of limit orders to update. Size of each array given should be equal to `size`
    /// @param orderId Id of the each order to update
    /// @param newAmount0Base The amount of token0 for each updated limit order in terms of number of sizeTicks.
    /// The exact amount of token0 for each order will be newAmount0Base[i] * sizeTick
    /// @param newPriceBase The new price of the token0 for each limit order.
    /// Exact price for unit token0 is calculated as newPriceBase[i] * priceTick
    /// @param hintId Where to insert each updated order in the given order book. Meant to be calculated
    /// off-chain using the suggestHintId function
    /// @return newOrderId The new id of the each updated order
    function updateLimitOrderBatch(
        uint8 orderBookId,
        uint8 size,
        uint32[] memory orderId,
        uint64[] memory newAmount0Base,
        uint64[] memory newPriceBase,
        uint32[] memory hintId
    ) external returns (uint32[] memory newOrderId);

    /// @notice Cancels a limit order in the given order book and creates a new one with given parameters
    /// @param orderBookId The unique identifier of the order book
    /// @param orderId The id of the order to update
    /// @param newAmount0Base The amount of token0 for updated limit order in terms of number of sizeTicks.
    /// The exact amount of token0 will be newAmount0Base * sizeTick
    /// @param newPriceBase The new price of the token0 for updated limit order.
    /// Exact price for unit token0 is calculated as newPriceBase * priceTick
    /// @param hintId Where to insert the updated order in the given order book. Meant to
    /// be calculated off-chain using the suggestHintId function
    /// @return newOrderId The new id of the updated order
    function updateLimitOrder(
        uint8 orderBookId,
        uint32 orderId,
        uint64 newAmount0Base,
        uint64 newPriceBase,
        uint32 hintId
    ) external returns (uint32 newOrderId);

    /// @notice Cancels multiple limit orders in the given order book
    /// @dev Including an inactive order in the batch cancelation does not
    /// revert the entire transaction, function returns false for that order
    /// @param orderBookId The unique identifier of the order book
    /// @param size The number of limit orders to cancel. Size of each array given should be equal to `size`
    /// @param orderId The id for each limit order to cancel
    /// @return isCanceled List of booleans indicating whether each order was successfully canceled
    function cancelLimitOrderBatch(
        uint8 orderBookId,
        uint8 size,
        uint32[] memory orderId
    ) external returns (bool[] memory isCanceled);

    /// @notice Cancels a limit order in the given order book
    /// @param orderBookId The unique identifier of the order book
    /// @param orderId The id of the order to cancel
    /// @return isCanceled A boolean indicating whether the order was successfully canceled
    function cancelLimitOrder(uint8 orderBookId, uint32 orderId) external returns (bool);

    /// @notice Performs swap in the given order book
    /// @param orderBookId The unique identifier of the order book
    /// @param isAsk Whether the order is an ask order
    /// @param exactInput exactInput to pay for the swap (can be token0 or token1 based on isAsk)
    /// @param minOutput Minimum output amount expected to recieve from swap (can be token0 or token1 based on isAsk)
    /// @param recipient The address of the recipient of the output
    /// @param unwrap Boolean indicator wheter to unwrap the wrapped native token output or not
    /// @dev Unwrap is only applicable if native wrapped token is the output token
    /// @return swappedInput The amount of input taker paid for the swap
    /// @return swappedOutput The amount of output taker received from the swap
    function swapExactInputSingle(
        uint8 orderBookId,
        bool isAsk,
        uint256 exactInput,
        uint256 minOutput,
        address recipient,
        bool unwrap
    ) external payable returns (uint256 swappedInput, uint256 swappedOutput);

    /// @notice Performs swap in the given order book
    /// @param isAsk Whether the order is an ask order
    /// @param exactOutput exactOutput to receive from the swap (can be token0 or token1 based on isAsk)
    /// @param maxInput Maximum input that the taker is willing to pay for the swap (can be token0 or token1 based on isAsk)
    /// @param recipient The address of the recipient of the output
    /// @param unwrap Boolean indicator wheter to unwrap the wrapped native token output or not
    /// @dev Unwrap is only applicable if native wrapped token is the output token
    /// @return swappedInput The amount of input taker paid for the swap
    /// @return swappedOutput The amount of output taker received from the swap
    function swapExactOutputSingle(
        uint8 orderBookId,
        bool isAsk,
        uint256 exactOutput,
        uint256 maxInput,
        address recipient,
        bool unwrap
    ) external payable returns (uint256 swappedInput, uint256 swappedOutput);

    /// @notice Performs a multi path exact input swap
    /// @param multiPathExactInputRequest The input request containing swap details
    /// @return swappedInput The amount of input taker paid for the swap
    /// @return swappedOutput The amount of output taker received from the swap
    function swapExactInputMulti(
        MultiPathExactInputRequest memory multiPathExactInputRequest
    ) external payable returns (uint256 swappedInput, uint256 swappedOutput);

    /// @notice Performs a multi path exact output swap
    /// @param multiPathExactOutputRequest The input request containing swap details
    /// @return swappedInput The amount of input taker paid for the swap
    /// @return swappedOutput The amount of output taker received from the swap
    function swapExactOutputMulti(
        MultiPathExactOutputRequest memory multiPathExactOutputRequest
    ) external payable returns (uint256 swappedInput, uint256 swappedOutput);

    /// @notice Returns the paginated order details of ask or bid orders in the given order book
    /// @param orderBookId The unique identifier of the order book
    /// @param startOrderId orderId from where the pagination should start (not inclusive)
    /// @dev caller can pass 0 to start from the top of the book
    /// @param isAsk Whether to return ask or bid orders
    /// @param limit Number number of orders to return in the page
    /// @return orderData The paginated order data
    function getPaginatedOrders(
        uint8 orderBookId,
        uint32 startOrderId,
        bool isAsk,
        uint32 limit
    ) external view returns (IOrderBook.OrderQueryItem memory orderData);

    /// @notice Returns the ask and bid order details in the given order book
    /// @param orderBookId The unique identifier of the order book
    /// @param limit Number number of orders to return from the top of the book on each side
    /// @return askOrders The list of ask order details
    /// @return bidOrders The list of bid order details
    function getLimitOrders(
        uint8 orderBookId,
        uint32 limit
    ) external view returns (IOrderBook.OrderQueryItem memory askOrders, IOrderBook.OrderQueryItem memory bidOrders);

    /// @notice Returns the order id to the right of where the new order should be inserted.
    /// Meant to be used off-chain to calculate the hintId for order operations
    /// @param orderBookId The unique identifier of the order book
    /// @param priceBase The price of the token0 for each limit order.
    /// Exact price for unit token0 is calculated as priceBase * priceTick
    /// @param isAsk Whether the order is an ask order
    /// @return hintId The id of the order to the right of where the new order should be inserted
    function suggestHintId(uint8 orderBookId, uint64 priceBase, bool isAsk) external view returns (uint32);

    /// @notice Returns quote for exact input single swap
    /// @param orderBookId The unique identifier of the order book
    /// @param isAsk Whether the order is an ask order
    /// @param exactInput amount of token to get quote for (token0 or token1 based on isAsk)
    /// @return quotedInput the amount of token required for swap
    /// @return quotedOutput the amount of token to be received by the user
    function getQuoteForExactInput(
        uint8 orderBookId,
        bool isAsk,
        uint256 exactInput
    ) external view returns (uint256 quotedInput, uint256 quotedOutput);

    /// @notice Returns quote for exact output single swap
    /// @param orderBookId The unique identifier of the order book
    /// @param isAsk Whether the order is an ask order
    /// @param exactOutput amount of token to get quote for (token0 or token1 based on isAsk)
    /// @return quotedInput the amount of token required for swap
    /// @return quotedOutput the amount of token to be received by the user
    function getQuoteForExactOutput(
        uint8 orderBookId,
        bool isAsk,
        uint256 exactOutput
    ) external view returns (uint256 quotedInput, uint256 quotedOutput);

    /// @notice Returns quote for exact input swap multi path swap
    /// @param swapRequests array of swap requests defining the multi path swap sequence
    /// @param exactInput amount of token to get quote for (token0 or token1 based on isAsk)
    /// @return quotedInput the initial amount of token required for swap
    /// @return quotedOutput the final amount of token to be received by the user
    function getQuoteForExactInputMulti(
        ISwapMultiRequest.SwapRequest[] memory swapRequests,
        uint256 exactInput
    ) external view returns (uint256 quotedInput, uint256 quotedOutput);

    /// @notice Returns quote for exact output multi path swap
    /// @param swapRequests array of swap requests defining the multi path swap sequence
    /// @param exactOutput amount of token to get quote for (token0 or token1 based on isAsk)
    /// @return quotedInput the initial amount of token required for swap
    /// @return quotedOutput the final amount of token to be received by the user
    function getQuoteForExactOutputMulti(
        ISwapMultiRequest.SwapRequest[] memory swapRequests,
        uint256 exactOutput
    ) external view returns (uint256 quotedInput, uint256 quotedOutput);

    /// @notice Validates a multi path swap request
    /// @param swapRequests array of swap requests defining the multi path swap sequence
    function validateMultiPathSwap(SwapRequest[] memory swapRequests) external view;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @title SwapMultiRequest Interface
/// @notice Interface for multi path swap requests
interface ISwapMultiRequest {
    /// @notice Structure to represent a swap request.
    struct SwapRequest {
        bool isAsk; // Whether the order is an ask order
        uint8 orderBookId; // The unique identifier of the order book associated with the swap request
    }

    /// @notice Structure to represent a multi-path swapExactInput request.
    struct MultiPathExactInputRequest {
        SwapRequest[] swapRequests; // Array of swap requests defining the sequence of swaps to be executed
        uint256 exactInput; // exactInput to pay for the first swap in the sequence
        uint256 minOutput; // Minimum output amount expected to recieve from last swap in the sequence
        address recipient; // The address of the recipient of the output
        bool unwrap; // Boolean indicator wheter to unwrap the wrapped native token output or not
    }

    /// @notice Structure to represent a multi-path swapExactOutput request.
    struct MultiPathExactOutputRequest {
        SwapRequest[] swapRequests; // Array of swap requests defining the multi-path swap sequence
        uint256 exactOutput; // exactOutput to receive from the last swap in the sequence
        uint256 maxInput; // Maximum input that the taker is willing to pay for the first swap in the sequence
        address recipient; // The address of the recipient of the output
        bool unwrap; // Boolean indicator wheter to unwrap the wrapped native token output or not
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @title PeripheryErrors
/// @notice Library containing errors that Lighter V2 Periphery functions may revert with
library PeripheryErrors {
    /*//////////////////////////////////////////////////////////////////////////
                                      LIGHTER-V2-ROUTER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when there is not enough WETH to unwrap in the router contract
    error LighterV2Router_InsufficientWETH9();

    /// @notice Thrown when router tries to fetch an order book with invalid id
    error LighterV2Router_InvalidOrderBookId();

    /// @notice Thrown when router receives eth with no calldata provided
    error LighterV2Router_ReceiveNotSupported();

    /// @notice Thrown when input required for multi path exact output swap is too big
    error LighterV2Router_SwapExactOutputMultiTooMuchRequested();

    /// @notice Thrown when amount of native token provided is not enough to wrap and use as input for the swap
    error LighterV2Router_NotEnoughNative();

    /// @notice Thrown when router callback function is called from an address that is not a registered valid order book
    error LighterV2Router_TransferCallbackCallerIsNotOrderBook();

    /*//////////////////////////////////////////////////////////////////////////
                                      LIGHTER-V2-PARSE-CALLDATA
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice Thrown when parseLength exceeds 32-Bytes
    error LighterV2ParseCallData_ByteSizeLimit32();

    /// @notice Thrown when parse range exceeds the messageData byte length
    error LighterV2ParseCallData_CannotReadPastEndOfCallData();

    /// @notice Thrown when mantissa representation values are invalid
    error LighterV2ParseCallData_InvalidMantissa();

    /*//////////////////////////////////////////////////////////////////////////
                                  LIGHTER-V2-QUOTER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when there is not enough available liquidity in the order book to get quote from
    error LighterV2Quoter_NotEnoughLiquidity();

    /// @notice Thrown when path given for multi path swap is invalid
    error LighterV2Quoter_InvalidSwapExactMultiRequestCombination();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@elliottech/lighter-v2-core/contracts/interfaces/IOrderBook.sol";
import "@elliottech/lighter-v2-core/contracts/interfaces/IFactory.sol";
import "./PeripheryErrors.sol";
import "../interfaces/ISwapMultiRequest.sol";

/// @title Quoter provides quoting functionality for swaps
library QuoterLib {
    /// @notice Structure to hold local variables for internal functions
    struct LocalVars {
        uint32 index; // Index of the orders in OrderBook
        uint256 filledAmount0; // Total filledAmount of token0 in the swap
        uint256 filledAmount1; // Total filledAmount of token1 in the swap
        uint256 amount; // Remaining amount for swapExact function
        uint256 exactInput; // exactInput amount used for swapExactInput
        uint256 exactOutput; // exactOutput amount used for swapExactOutput
        uint256 swapAmount0; // Swapped amount for token0 during a single match
        uint256 swapAmount1; // Swapped amount for token1 during a single match
        bool fullTakerFill; // Boolean indicator to mark if taker swap is fully filled
    }

    /// @notice Returns quote for exact input single swap
    /// @param factory Contract used for getting IOrderBook from orderBookId
    /// @param orderBookId Id of the orderBook
    /// @param isAsk Whether the order is an ask order
    /// @param exactInput Amount of token to get quote for (token0 or token1 based on isAsk)
    /// @return quotedInput The amount of token required for swap
    /// @return quotedOutput The amount of token to be received by the user
    function getQuoteForExactInput(
        IFactory factory,
        uint8 orderBookId,
        bool isAsk,
        uint256 exactInput
    ) internal view returns (uint256 quotedInput, uint256 quotedOutput) {
        return getQuote(factory, orderBookId, isAsk, exactInput, true);
    }

    /// @notice Returns quote for exact output single swap
    /// @param factory Contract used for getting IOrderBook from orderBookId
    /// @param orderBookId Id of the orderBook
    /// @param isAsk Whether the order is an ask order
    /// @param exactOutput Amount of token to get quote for (token0 or token1 based on isAsk)
    /// @return quotedInput The amount of token required for swap
    /// @return quotedOutput The amount of token to be received by the user
    function getQuoteForExactOutput(
        IFactory factory,
        uint8 orderBookId,
        bool isAsk,
        uint256 exactOutput
    ) internal view returns (uint256 quotedInput, uint256 quotedOutput) {
        return getQuote(factory, orderBookId, isAsk, exactOutput, false);
    }

    /// @notice Returns quote for exact input swap with multiple hops (multi path)
    /// @param factory Contract used for getting IOrderBook from orderBookId
    /// @param swapRequests Array of swap requests defining the multi path swap sequence
    /// @param exactInput Amount of token to get quote for (token0 or token1 based on isAsk)
    /// @return quotedInput The initial amount of token required for swap
    /// @return quotedOutput The final amount of token to be received by the user
    function getQuoteForExactInputMulti(
        IFactory factory,
        ISwapMultiRequest.SwapRequest[] memory swapRequests,
        uint256 exactInput
    ) internal view returns (uint256 quotedInput, uint256 quotedOutput) {
        LocalVars memory localVars;
        uint256 requestLength = swapRequests.length;
        uint256 index = 0;

        while (true) {
            (localVars.exactInput, localVars.exactOutput) = getQuoteForExactInput(
                factory,
                swapRequests[index].orderBookId,
                swapRequests[index].isAsk,
                exactInput
            );

            // First order book in the swapRequest path is used to set quotedInput
            if (index == 0) {
                quotedInput = localVars.exactInput;
            }

            if (index + 1 < requestLength) {
                // exactInput for next request to process should be the exactOutput of the current swap
                exactInput = localVars.exactOutput;
                unchecked {
                    ++index;
                }
            } else {
                // Last order book in the swapRequest path is used to set quotedOutput
                quotedOutput = localVars.exactOutput;
                break;
            }
        }

        return (quotedInput, quotedOutput);
    }

    /// @notice Returns quote for exact output swap with multiple hops (multi path)
    /// @param factory Contract used for getting IOrderBook from orderBookId
    /// @param swapRequests Array of swap requests defining the multi path swap sequence
    /// @param exactOutput Amount of token to get quote for (token0 or token1 based on isAsk)
    /// @return quotedInput The initial amount of token required for swap
    /// @return quotedOutput The final amount of token to be received by the user
    function getQuoteForExactOutputMulti(
        IFactory factory,
        ISwapMultiRequest.SwapRequest[] memory swapRequests,
        uint256 exactOutput
    ) internal view returns (uint256 quotedInput, uint256 quotedOutput) {
        LocalVars memory localVars;
        uint256 requestLength = swapRequests.length;
        uint256 index = requestLength - 1;

        // To be able to calculate quotedInput for given exact output, iterate over the swapRequests in reverse order
        while (true) {
            (localVars.exactInput, localVars.exactOutput) = getQuoteForExactOutput(
                factory,
                swapRequests[index].orderBookId,
                swapRequests[index].isAsk,
                exactOutput
            );

            // Last order book in the swapRequest path is used to set quotedOutput
            if (index + 1 == requestLength) {
                quotedOutput = localVars.exactOutput;
            }

            if (index > 0) {
                // exactOutput for next request to process (previous one in the list due to reversed order) should be the exactInput of the current swap
                exactOutput = localVars.exactInput;
                unchecked {
                    index--;
                }
            } else {
                // First order book in the swapRequest path is used to set quotedInput
                quotedInput = localVars.exactInput;
                break;
            }
        }

        return (quotedInput, quotedOutput);
    }

    /// @notice Calculates and returns swap quotes for the given order book and amount
    /// @dev Executes order book swap matching as in the given order book contract but does not change the state
    /// and returns quotedInput and quotedOutput
    /// @param factory Contract used for getting IOrderBook from orderBookId
    /// @param orderBookId Id of the orderBook
    /// @param isAsk Whether the order is an ask order
    /// @param amount Exact amount to get quote for (token0 or token1 based on isAsk and isExactInput)
    /// @param isExactInput Boolean indicator to mark if the amount is exactInput or exactOutput
    /// @return quotedInput Exact amount of input token to be provided
    /// @return quotedOutput Exact amount of output token to be received
    function getQuote(
        IFactory factory,
        uint8 orderBookId,
        bool isAsk,
        uint256 amount,
        bool isExactInput
    ) internal view returns (uint256, uint256) {
        IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(orderBookId));

        LocalVars memory localVars;
        localVars.amount = amount;

        localVars.index = orderBook.getLimitOrder(!isAsk, 0).next;
        localVars.fullTakerFill = amount == 0;

        while (localVars.index != 1 && !localVars.fullTakerFill) {
            IOrderBook.LimitOrder memory bestMatch = isAsk
                ? orderBook.getLimitOrder(false, localVars.index)
                : orderBook.getLimitOrder(true, localVars.index);

            (localVars.swapAmount0, localVars.swapAmount1, , localVars.fullTakerFill) = (isAsk == isExactInput)
                ? orderBook.getSwapAmountsForToken0(localVars.amount, isAsk, bestMatch.amount0Base, bestMatch.priceBase)
                : orderBook.getSwapAmountsForToken1(
                    localVars.amount,
                    isAsk,
                    bestMatch.amount0Base,
                    bestMatch.priceBase
                );

            if (localVars.swapAmount0 == 0 || localVars.swapAmount1 == 0) break;

            localVars.filledAmount0 += localVars.swapAmount0;
            localVars.filledAmount1 += localVars.swapAmount1;

            if (localVars.fullTakerFill) {
                break;
            }

            localVars.amount = (isAsk == isExactInput)
                ? localVars.amount - localVars.swapAmount0
                : localVars.amount - localVars.swapAmount1;
            localVars.index = bestMatch.next;
        }

        if (!localVars.fullTakerFill) {
            revert PeripheryErrors.LighterV2Quoter_NotEnoughLiquidity();
        }

        if (isAsk) {
            return (localVars.filledAmount0, localVars.filledAmount1);
        } else {
            return (localVars.filledAmount1, localVars.filledAmount0);
        }
    }

    /// @notice Validates a multi path swap request
    /// @param factory Contract used for getting IOrderBook from orderBookId
    /// @param swapRequests Array of swap requests defining the multi path swap sequence
    function validateMultiPathSwap(
        IFactory factory,
        ISwapMultiRequest.SwapRequest[] memory swapRequests
    ) internal view {
        address lastOutput;

        for (uint256 index = 0; index < swapRequests.length; ) {
            ISwapMultiRequest.SwapRequest memory swapRequest = swapRequests[index];

            // Gets the order book associated with the current swap request in the path
            IOrderBook orderBook = IOrderBook(factory.getOrderBookFromId(swapRequest.orderBookId));

            if (address(orderBook) == address(0)) {
                revert PeripheryErrors.LighterV2Quoter_InvalidSwapExactMultiRequestCombination();
            }

            address currentInput;
            address currentOutput;

            (currentInput, currentOutput) = (swapRequest.isAsk)
                ? (address(orderBook.token0()), address(orderBook.token1()))
                : (address(orderBook.token1()), address(orderBook.token0()));

            // Checks if input token of the current swap request matches with the output token of the previous swap request
            if (index != 0 && lastOutput != currentInput) {
                revert PeripheryErrors.LighterV2Quoter_InvalidSwapExactMultiRequestCombination();
            }
            lastOutput = currentOutput;

            unchecked {
                ++index;
            }
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

import "@elliottech/lighter-v2-core/contracts/interfaces/IOrderBook.sol";
import "@elliottech/lighter-v2-core/contracts/interfaces/ILighterV2TransferCallback.sol";
import "@elliottech/lighter-v2-core/contracts/interfaces/IFactory.sol";
import "./libraries/PeripheryErrors.sol";
import "./libraries/SafeTransfer.sol";
import "./libraries/Quoter.sol";
import "./interfaces/external/IWETH9.sol";
import "./interfaces/IRouter.sol";

/// @title Router
/// @notice Router for interacting with order books to perform order operations, swaps and views
contract Router is IRouter, ILighterV2TransferCallback {
    using SafeTransferLib for IERC20Minimal;
    using QuoterLib for IFactory;

    /// @notice The address of the factory contract that manages order book deployments
    IFactory public immutable factory;

    /// @notice The address of the Wrapped Ether (WETH) contract
    IWETH9 public immutable weth9;

    /// @notice Struct to hold local variables for internal functions logic
    struct LocalVars {
        uint256 swapAmount0; // Amount of token0 to swap
        uint256 swapAmount1; // Amount of token1 to swap
        uint256 swappedInput; // Amount of input token swapped
        uint256 swappedOutput; // Amount of output token swapped
        uint256 exactInput; // Amount of the exact-input-token used in the swap
        address sender; // Address of the payer of the swap
        address recipient; // Address of the recipient
    }

    /// @dev Constructor to initialize the Router with factory and WETH contract addresses
    /// @param _factoryAddress The address of the factory contract.
    /// @param _wethAddress The address of the Wrapped Ether (WETH) contract
    constructor(address _factoryAddress, address _wethAddress) {
        factory = IFactory(_factoryAddress);
        weth9 = IWETH9(_wethAddress);
    }

    receive() external payable {
        revert PeripheryErrors.LighterV2Router_ReceiveNotSupported();
    }

    /// @inheritdoc IRouter
    function createLimitOrderBatch(
        uint8 orderBookId,
        uint8 size,
        uint64[] memory amount0Base,
        uint64[] memory priceBase,
        bool[] memory isAsk,
        uint32[] memory hintId
    ) external override returns (uint32[] memory orderId) {
        IOrderBook orderBook = _getOrderBookFromId(orderBookId);
        orderId = new uint32[](size);
        bytes memory callbackData = abi.encodePacked(orderBookId, msg.sender);
        for (uint8 i; i < size; ) {
            orderId[i] = orderBook.createOrder(
                amount0Base[i],
                priceBase[i],
                isAsk[i],
                msg.sender,
                hintId[i],
                IOrderBook.OrderType.LimitOrder,
                callbackData
            );
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IRouter
    function createLimitOrder(
        uint8 orderBookId,
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        uint32 hintId
    ) public override returns (uint32 orderId) {
        orderId = _getOrderBookFromId(orderBookId).createOrder(
            amount0Base,
            priceBase,
            isAsk,
            msg.sender,
            hintId,
            IOrderBook.OrderType.LimitOrder,
            abi.encodePacked(orderBookId, msg.sender)
        );
    }

    /// @inheritdoc IRouter
    function createFoKOrder(
        uint8 orderBookId,
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk
    ) public override returns (uint32 orderId) {
        orderId = _getOrderBookFromId(orderBookId).createOrder(
            amount0Base,
            priceBase,
            isAsk,
            msg.sender,
            0,
            IOrderBook.OrderType.FoKOrder,
            abi.encodePacked(orderBookId, msg.sender)
        );
    }

    /// @inheritdoc IRouter
    function createIoCOrder(
        uint8 orderBookId,
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk
    ) public override returns (uint32 orderId) {
        orderId = _getOrderBookFromId(orderBookId).createOrder(
            amount0Base,
            priceBase,
            isAsk,
            msg.sender,
            0,
            IOrderBook.OrderType.IoCOrder,
            abi.encodePacked(orderBookId, msg.sender)
        );
    }

    /// @inheritdoc IRouter
    function updateLimitOrderBatch(
        uint8 orderBookId,
        uint8 size,
        uint32[] memory orderId,
        uint64[] memory newAmount0Base,
        uint64[] memory newPriceBase,
        uint32[] memory hintId
    ) external override returns (uint32[] memory newOrderId) {
        newOrderId = new uint32[](size);
        IOrderBook orderBook = _getOrderBookFromId(orderBookId);
        bool isCanceled;
        bool isAsk;
        bytes memory callbackData = abi.encodePacked(orderBookId, msg.sender);
        for (uint256 i; i < size; ) {
            if (!orderBook.isOrderActive(orderId[i])) {
                newOrderId[i] = 0;
                unchecked {
                    ++i;
                }
                continue;
            }
            isAsk = orderBook.isAskOrder(orderId[i]);
            isCanceled = orderBook.cancelLimitOrder(orderId[i], msg.sender);

            // Should not happen since function checks if the order is active above
            if (!isCanceled) {
                newOrderId[i] = 0;
            } else {
                newOrderId[i] = orderBook.createOrder(
                    newAmount0Base[i],
                    newPriceBase[i],
                    isAsk,
                    msg.sender,
                    hintId[i],
                    IOrderBook.OrderType.LimitOrder,
                    callbackData
                );
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IRouter
    function updateLimitOrder(
        uint8 orderBookId,
        uint32 orderId,
        uint64 newAmount0Base,
        uint64 newPriceBase,
        uint32 hintId
    ) public override returns (uint32 newOrderId) {
        IOrderBook orderBook = _getOrderBookFromId(orderBookId);
        if (!orderBook.isOrderActive(orderId)) {
            newOrderId = 0;
        } else {
            bool isAsk = orderBook.isAskOrder(orderId);
            if (orderBook.cancelLimitOrder(orderId, msg.sender)) {
                newOrderId = orderBook.createOrder(
                    newAmount0Base,
                    newPriceBase,
                    isAsk,
                    msg.sender,
                    hintId,
                    IOrderBook.OrderType.LimitOrder,
                    abi.encodePacked(orderBookId, msg.sender)
                );
            } else {
                // Should not happen since function checks if the order is active above
                newOrderId = 0;
            }
        }
    }

    /// @inheritdoc IRouter
    function cancelLimitOrderBatch(
        uint8 orderBookId,
        uint8 size,
        uint32[] memory orderId
    ) external override returns (bool[] memory isCanceled) {
        IOrderBook orderBook = _getOrderBookFromId(orderBookId);
        isCanceled = new bool[](size);
        for (uint256 i; i < size; ) {
            isCanceled[i] = orderBook.cancelLimitOrder(orderId[i], msg.sender);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IRouter
    function cancelLimitOrder(uint8 orderBookId, uint32 orderId) public override returns (bool) {
        return _getOrderBookFromId(orderBookId).cancelLimitOrder(orderId, msg.sender);
    }

    /// @inheritdoc IRouter
    function swapExactInputSingle(
        uint8 orderBookId,
        bool isAsk,
        uint256 exactInput,
        uint256 minOutput,
        address recipient,
        bool unwrap
    ) public payable override returns (uint256 swappedInput, uint256 swappedOutput) {
        uint256 swapAmount0;
        uint256 swapAmount1;
        IOrderBook orderBook = _getOrderBookFromId(orderBookId);

        if (msg.value > 0 && msg.value < exactInput) {
            revert PeripheryErrors.LighterV2Router_NotEnoughNative();
        }

        bytes memory callbackData = abi.encodePacked(orderBookId, msg.sender);

        (swapAmount0, swapAmount1) = orderBook.swapExactSingle(
            isAsk,
            true,
            exactInput,
            minOutput,
            (unwrap) ? address(this) : recipient,
            callbackData
        );

        if (isAsk) {
            (swappedInput, swappedOutput) = (swapAmount0, swapAmount1);
        } else {
            (swappedInput, swappedOutput) = (swapAmount1, swapAmount0);
        }

        if (msg.value > 0) {
            _handleNativeRefund();
        }

        if (unwrap) {
            _unwrapWETH9AndTransfer(recipient, swappedOutput);
        }
    }

    /// @inheritdoc IRouter
    function swapExactOutputSingle(
        uint8 orderBookId,
        bool isAsk,
        uint256 exactOutput,
        uint256 maxInput,
        address recipient,
        bool unwrap
    ) public payable returns (uint256 swappedInput, uint256 swappedOutput) {
        uint256 swapAmount0;
        uint256 swapAmount1;
        IOrderBook orderBook = _getOrderBookFromId(orderBookId);

        if (msg.value > 0 && msg.value < maxInput) {
            revert PeripheryErrors.LighterV2Router_NotEnoughNative();
        }

        bytes memory callbackData = abi.encodePacked(orderBookId, msg.sender);

        (swapAmount0, swapAmount1) = orderBook.swapExactSingle(
            isAsk,
            false,
            exactOutput,
            maxInput,
            (unwrap) ? address(this) : recipient,
            callbackData
        );

        if (isAsk) {
            (swappedInput, swappedOutput) = (swapAmount0, swapAmount1);
        } else {
            (swappedInput, swappedOutput) = (swapAmount1, swapAmount0);
        }

        if (msg.value > 0) {
            _handleNativeRefund();
        }

        if (unwrap) {
            _unwrapWETH9AndTransfer(recipient, swappedOutput);
        }
    }

    /// @inheritdoc IRouter
    function swapExactInputMulti(
        MultiPathExactInputRequest memory multiPathExactInputRequest
    ) public payable returns (uint256 swappedInput, uint256 swappedOutput) {
        // In the case of a single order book, forward call to swapExactInputSingle
        if (multiPathExactInputRequest.swapRequests.length == 1) {
            return
                swapExactInputSingle(
                    multiPathExactInputRequest.swapRequests[0].orderBookId,
                    multiPathExactInputRequest.swapRequests[0].isAsk,
                    multiPathExactInputRequest.exactInput,
                    multiPathExactInputRequest.minOutput,
                    multiPathExactInputRequest.recipient,
                    multiPathExactInputRequest.unwrap
                );
        }
        factory.validateMultiPathSwap(multiPathExactInputRequest.swapRequests);
        return _executeSwapExactInputMulti(multiPathExactInputRequest);
    }

    /// @inheritdoc IRouter
    function swapExactOutputMulti(
        MultiPathExactOutputRequest memory multiPathExactOutputRequest
    ) public payable returns (uint256 swappedInput, uint256 swappedOutput) {
        // In the case of a single order book, forward call to swapExactOutputSingle
        if (multiPathExactOutputRequest.swapRequests.length == 1) {
            return
                swapExactOutputSingle(
                    multiPathExactOutputRequest.swapRequests[0].orderBookId,
                    multiPathExactOutputRequest.swapRequests[0].isAsk,
                    multiPathExactOutputRequest.exactOutput,
                    multiPathExactOutputRequest.maxInput,
                    multiPathExactOutputRequest.recipient,
                    multiPathExactOutputRequest.unwrap
                );
        }
        factory.validateMultiPathSwap(multiPathExactOutputRequest.swapRequests);

        (uint256 quotedInput, uint256 quotedOutput) = factory.getQuoteForExactOutputMulti(
            multiPathExactOutputRequest.swapRequests,
            multiPathExactOutputRequest.exactOutput
        );

        // Verify that the quotedInput is smaller than or equal to user provided maxInput
        if (quotedInput > multiPathExactOutputRequest.maxInput) {
            revert PeripheryErrors.LighterV2Router_SwapExactOutputMultiTooMuchRequested();
        }

        return
            _executeSwapExactInputMulti(
                MultiPathExactInputRequest({
                    swapRequests: multiPathExactOutputRequest.swapRequests,
                    exactInput: quotedInput,
                    minOutput: quotedOutput,
                    recipient: multiPathExactOutputRequest.recipient,
                    unwrap: multiPathExactOutputRequest.unwrap
                })
            );
    }

    /// @inheritdoc ILighterV2TransferCallback
    function lighterV2TransferCallback(
        uint256 debitTokenAmount,
        IERC20Minimal debitToken,
        bytes memory _data
    ) external override {
        uint8 orderBookId;
        address payer;

        // Unpack data
        assembly {
            orderBookId := mload(add(_data, 1))
            payer := mload(add(_data, 21))
        }

        // Check if sender is a valid order book
        IOrderBook orderBook = _getOrderBookFromId(orderBookId);
        if (msg.sender != address(orderBook)) {
            revert PeripheryErrors.LighterV2Router_TransferCallbackCallerIsNotOrderBook();
        }

        if (address(debitToken) == address(weth9) && address(this).balance >= debitTokenAmount) {
            // Pay with WETH9
            IWETH9(weth9).depositTo{value: debitTokenAmount}(msg.sender);
        } else if (payer == address(this)) {
            // Pay with tokens already in the contract (for the exact input multi path case)
            debitToken.safeTransfer(msg.sender, debitTokenAmount);
        } else {
            // Pull payment
            debitToken.safeTransferFrom(payer, msg.sender, debitTokenAmount);
        }
    }

    /// @notice This function is called when no other router function is called
    /// @dev The data should be passed in msg.data
    /// Fallback function is to be used for calldata optimization.
    /// The first byte of msg.data should be the function selector:
    /// 1 = createLimitOrder
    /// 2 = updateLimitOrder
    /// 3 = cancelLimitOrder
    /// 4 + 0 = createIoCOrder -- isAsk=false
    ///   + 1 = createIoCOrder -- isAsk=true
    /// 6 + 0 = createFoKOrder -- isAsk=false
    ///   + 1 = createFoKOrder -- isAsk=true
    /// 8 + 0 = swapExactInputSingle -- unwrap=false, recipientIsMsgSender=false
    ///   + 1 = swapExactInputSingle -- unwrap=true, recipientIsMsgSender=false
    ///   + 2 = swapExactInputSingle -- unwrap=false, recipientIsMsgSender=true
    ///   + 3 = swapExactInputSingle -- unwrap=true, recipientIsMsgSender=true
    /// 12 + 0 = swapExactOutputSingle -- unwrap=false, recipientIsMsgSender=false
    ///    + 1 = swapExactOutputSingle -- unwrap=true, recipientIsMsgSender=false
    ///    + 2 = swapExactOutputSingle -- unwrap=false, recipientIsMsgSender=true
    ///    + 3 = swapExactOutputSingle -- unwrap=true, recipientIsMsgSender=true
    /// 16 + 0 = swapExactInputMulti -- unwrap=false, recipientIsMsgSender=false
    ///    + 1 = swapExactInputMulti -- unwrap=true, recipientIsMsgSender=false
    ///    + 2 = swapExactInputMulti -- unwrap=false, recipientIsMsgSender=true
    ///    + 3 = swapExactInputMulti -- unwrap=true, recipientIsMsgSender=true
    /// 20 + 0 = swapExactOutputMulti -- unwrap=false, recipientIsMsgSender=false
    ///    + 1 = swapExactOutputMulti -- unwrap=true, recipientIsMsgSender=false
    ///    + 2 = swapExactOutputMulti -- unwrap=false, recipientIsMsgSender=true
    ///    + 3 = swapExactOutputMulti -- unwrap=true, recipientIsMsgSender=true
    /// The next byte should be the id of the order book
    /// Remaining bytes should be order or swap details
    fallback() external payable {
        uint256 _func;
        uint256 dataLength = msg.data.length;

        uint256 currentByte = 1;
        _func = _parseCallData(0, dataLength, 1);

        uint256 value;
        uint8 parsed;

        // Group order-related operations together
        if (_func < 8) {
            uint8 orderBookId = uint8(_parseCallData(1, dataLength, 1));
            IOrderBook orderBook = _getOrderBookFromId(orderBookId);
            currentByte = 2;

            uint64 amount0Base;
            uint64 priceBase;
            uint32 hintId;
            uint256 isAsk;
            uint32 orderId;

            // Create limit order
            if (_func == 1) {
                // Parse all isAsk bits, at once, in a compressed form
                (isAsk, parsed) = _parseSizePaddedNumberFromCallData(currentByte, dataLength);
                currentByte += parsed;

                bytes memory callbackData = abi.encodePacked(orderBookId, msg.sender);

                while (currentByte < dataLength) {
                    (value, parsed) = _parseSizePaddedNumberFromCallData(currentByte, dataLength);
                    amount0Base = uint64(value);
                    currentByte += parsed;

                    (value, parsed) = _parseSizePaddedNumberFromCallData(currentByte, dataLength);
                    priceBase = uint64(value);
                    currentByte += parsed;

                    (value, parsed) = _parseSizePaddedNumberFromCallData(currentByte, dataLength);
                    hintId = uint32(value);
                    currentByte += parsed;

                    if (currentByte > dataLength) {
                        revert PeripheryErrors.LighterV2ParseCallData_CannotReadPastEndOfCallData();
                    }

                    orderBook.createOrder(
                        amount0Base,
                        priceBase,
                        isAsk & 1 > 0,
                        msg.sender,
                        hintId,
                        IOrderBook.OrderType.LimitOrder,
                        callbackData
                    );

                    // Consume 1 isAsk bit
                    isAsk >>= 1;
                }
            }

            // Update limit order
            if (_func == 2) {
                while (currentByte < dataLength) {
                    (value, parsed) = _parseSizePaddedNumberFromCallData(currentByte, dataLength);
                    orderId = uint32(value);
                    currentByte += parsed;

                    (value, parsed) = _parseSizePaddedNumberFromCallData(currentByte, dataLength);
                    amount0Base = uint64(value);
                    currentByte += parsed;

                    (value, parsed) = _parseSizePaddedNumberFromCallData(currentByte, dataLength);
                    priceBase = uint64(value);
                    currentByte += parsed;

                    (value, parsed) = _parseSizePaddedNumberFromCallData(currentByte, dataLength);
                    hintId = uint32(value);
                    currentByte += parsed;

                    if (currentByte > dataLength) {
                        revert PeripheryErrors.LighterV2ParseCallData_CannotReadPastEndOfCallData();
                    }

                    updateLimitOrder(orderBookId, orderId, amount0Base, priceBase, hintId);
                }
            }

            // Cancel limit order
            if (_func == 3) {
                while (currentByte < dataLength) {
                    (value, parsed) = _parseSizePaddedNumberFromCallData(currentByte, dataLength);
                    orderId = uint32(value);
                    currentByte += parsed;

                    if (currentByte > dataLength) {
                        revert PeripheryErrors.LighterV2ParseCallData_CannotReadPastEndOfCallData();
                    }

                    orderBook.cancelLimitOrder(orderId, msg.sender);
                }
            }

            // Create IoC order
            if (_func == 4 || _func == 5) {
                bool isAskByte = (_func == 5);

                (value, parsed) = _parseSizePaddedNumberFromCallData(currentByte, dataLength);
                amount0Base = uint64(value);
                currentByte += parsed;

                (value, parsed) = _parseSizePaddedNumberFromCallData(currentByte, dataLength);
                priceBase = uint64(value);
                currentByte += parsed;

                if (currentByte > dataLength) {
                    revert PeripheryErrors.LighterV2ParseCallData_CannotReadPastEndOfCallData();
                }

                createIoCOrder(orderBookId, amount0Base, priceBase, isAskByte);

                return;
            }

            // Create FoK order
            if (_func == 6 || _func == 7) {
                bool isAskByte = (_func == 7);

                (value, parsed) = _parseSizePaddedNumberFromCallData(currentByte, dataLength);
                amount0Base = uint64(value);
                currentByte += parsed;

                (value, parsed) = _parseSizePaddedNumberFromCallData(currentByte, dataLength);
                priceBase = uint64(value);
                currentByte += parsed;

                if (currentByte > dataLength) {
                    revert PeripheryErrors.LighterV2ParseCallData_CannotReadPastEndOfCallData();
                }

                createFoKOrder(orderBookId, amount0Base, priceBase, isAskByte);

                return;
            }
        }

        /// swapExactInputSingle with mantissa representation
        if (_func >= 8 && _func < 8 + 4) {
            // Parse compressed isAsk & orderBookId
            (bool isAsk, uint8 orderBookId) = _parseCompressedOBFromCallData(1, dataLength);
            currentByte = 2;

            uint256 exactInput;
            uint256 minOutput;

            (exactInput, parsed) = _parseNumberMantissaFromCallData(currentByte, dataLength);
            currentByte += parsed;

            (minOutput, parsed) = _parseNumberMantissaFromCallData(currentByte, dataLength);
            currentByte += parsed;

            uint8 recipientIsMsgSender = uint8((_func - 8) & 2);
            address recipient = (recipientIsMsgSender > 0)
                ? msg.sender
                : address(uint160(_parseCallData(currentByte, dataLength, 20)));
            if (recipientIsMsgSender == 0) currentByte += 20;
            bool unwrap = ((_func - 8) & 1) > 0;

            swapExactInputSingle(orderBookId, isAsk, exactInput, minOutput, recipient, unwrap);
            return;
        }

        /// swapExactOutputSingle with mantissa representation
        if (_func >= 12 && _func < 12 + 4) {
            // Parse compressed isAsk & orderBookId
            (bool isAsk, uint8 orderBookId) = _parseCompressedOBFromCallData(1, dataLength);
            currentByte = 2;

            uint256 exactOutput;
            uint256 maxInput;

            (exactOutput, parsed) = _parseNumberMantissaFromCallData(currentByte, dataLength);
            currentByte += parsed;

            (maxInput, parsed) = _parseNumberMantissaFromCallData(currentByte, dataLength);
            currentByte += parsed;

            uint8 recipientIsMsgSender = uint8((_func - 12) & 2);
            address recipient = (recipientIsMsgSender > 0)
                ? msg.sender
                : address(uint160(_parseCallData(currentByte, dataLength, 20)));
            if (recipientIsMsgSender == 0) currentByte += 20;
            bool unwrap = ((_func - 12) & 1) > 0;

            swapExactOutputSingle(orderBookId, isAsk, exactOutput, maxInput, recipient, unwrap);
            return;
        }

        /// swapExactInputMulti with mantissa representation
        if (_func >= 16 && _func < 16 + 4) {
            currentByte = 1;

            MultiPathExactInputRequest memory request;

            (request.exactInput, parsed) = _parseNumberMantissaFromCallData(currentByte, dataLength);
            currentByte += parsed;

            (request.minOutput, parsed) = _parseNumberMantissaFromCallData(currentByte, dataLength);
            currentByte += parsed;

            uint8 recipientIsMsgSender = uint8((_func - 16) & 2);
            if (recipientIsMsgSender > 0) {
                request.recipient = msg.sender;
            } else {
                request.recipient = address(uint160(_parseCallData(currentByte, dataLength, 20)));
                currentByte += 20;
            }
            request.unwrap = ((_func - 16) & 1) > 0;

            // Remaining callData is request.swapRequests
            uint256 remaining = dataLength - currentByte;
            request.swapRequests = new SwapRequest[](remaining);
            for (uint256 index = 0; index < remaining; ) {
                (
                    request.swapRequests[index].isAsk,
                    request.swapRequests[index].orderBookId
                ) = _parseCompressedOBFromCallData(currentByte, dataLength);
                currentByte += 1;
                unchecked {
                    ++index;
                }
            }

            swapExactInputMulti(request);
            return;
        }

        /// swapExactOutputMulti with mantissa representation
        if (_func >= 20 && _func < 20 + 4) {
            currentByte = 1;

            MultiPathExactOutputRequest memory request;

            (request.exactOutput, parsed) = _parseNumberMantissaFromCallData(currentByte, dataLength);
            currentByte += parsed;

            (request.maxInput, parsed) = _parseNumberMantissaFromCallData(currentByte, dataLength);
            currentByte += parsed;

            uint8 recipientIsMsgSender = uint8((_func - 20) & 2);
            if (recipientIsMsgSender > 0) {
                request.recipient = msg.sender;
            } else {
                request.recipient = address(uint160(_parseCallData(currentByte, dataLength, 20)));
                currentByte += 20;
            }
            request.unwrap = ((_func - 20) & 1) > 0;

            // remaining CallData is request.swapRequests
            uint256 remaining = dataLength - currentByte;
            request.swapRequests = new SwapRequest[](remaining);
            for (uint256 index = 0; index < remaining; ) {
                (
                    request.swapRequests[index].isAsk,
                    request.swapRequests[index].orderBookId
                ) = _parseCompressedOBFromCallData(currentByte, dataLength);
                currentByte += 1;
                unchecked {
                    ++index;
                }
            }

            swapExactOutputMulti(request);
            return;
        }
    }

    /// @dev Execute the MultiPathExactInputRequest after it has been validated.
    /// This exists as a separate function because it's also called by swapExactOutputMulti
    function _executeSwapExactInputMulti(
        MultiPathExactInputRequest memory multiPathExactInputRequest
    ) internal returns (uint256 swappedInput, uint256 swappedOutput) {
        if (msg.value > 0 && msg.value < multiPathExactInputRequest.exactInput) {
            revert PeripheryErrors.LighterV2Router_NotEnoughNative();
        }

        LocalVars memory localVars;
        localVars.exactInput = multiPathExactInputRequest.exactInput;
        uint256 requestsLength = multiPathExactInputRequest.swapRequests.length;

        for (uint index; index < requestsLength; ) {
            SwapRequest memory swapRequest = multiPathExactInputRequest.swapRequests[index];
            IOrderBook orderBook = _getOrderBookFromId(swapRequest.orderBookId);

            // If this is not the last request or if unwrap is set to true then the recipient will be the router.
            // Otherwise the recipient will be the recipient provided by the multi-swap initiator
            localVars.recipient = (requestsLength != index + 1)
                ? address(this)
                : ((multiPathExactInputRequest.unwrap) ? address(this) : multiPathExactInputRequest.recipient);

            // If this is the first request, sender will pay, for the rest of the requests, router will pay
            localVars.sender = (index == 0) ? msg.sender : address(this);

            (localVars.swapAmount0, localVars.swapAmount1) = orderBook.swapExactSingle(
                swapRequest.isAsk,
                true,
                localVars.exactInput,
                (index + 1 == requestsLength) ? multiPathExactInputRequest.minOutput : 0,
                localVars.recipient,
                abi.encodePacked(swapRequest.orderBookId, localVars.sender)
            );

            // If router is the sender and swapped input amount is less than the token amount in the router, refund the difference
            if (localVars.sender == address(this)) {
                uint256 refundAmount = swapRequest.isAsk
                    ? localVars.exactInput - localVars.swapAmount0
                    : localVars.exactInput - localVars.swapAmount1;

                // Send refund tokens from router to recipient of request
                if (refundAmount > 0) {
                    IERC20Minimal refundToken = swapRequest.isAsk ? orderBook.token0() : orderBook.token1();
                    refundToken.safeTransfer(multiPathExactInputRequest.recipient, refundAmount);
                }
            }

            if (index == 0) {
                localVars.swappedInput = swapRequest.isAsk ? localVars.swapAmount0 : localVars.swapAmount1;
            }
            localVars.exactInput = swapRequest.isAsk ? localVars.swapAmount1 : localVars.swapAmount0;

            unchecked {
                ++index;
            }
        }

        localVars.swappedOutput = localVars.exactInput;

        if (msg.value > 0) {
            _handleNativeRefund();
        }

        if (multiPathExactInputRequest.unwrap) {
            _unwrapWETH9AndTransfer(multiPathExactInputRequest.recipient, localVars.swappedOutput);
        }

        return (localVars.swappedInput, localVars.swappedOutput);
    }

    /// @dev Transfer all ETH to caller
    /// Does not care about the swap results since Router contract should not store any funds
    /// before or after transactions
    function _handleNativeRefund() internal {
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    /// @dev Unwrap the WETH9 tokens and transfer the native to recipient
    /// @param recipient Address of recipient
    /// @param amount Amount of WETH9 to be unwrapped to native
    function _unwrapWETH9AndTransfer(address recipient, uint256 amount) internal {
        uint256 balanceWETH9 = weth9.balanceOf(address(this));
        if (balanceWETH9 < amount) {
            revert PeripheryErrors.LighterV2Router_InsufficientWETH9();
        }
        if (amount > 0) {
            weth9.withdrawTo(recipient, amount);
        }
    }

    /// @dev Get the uint value from msg.data starting from a specific byte
    /// @param startByte Index of startByte of calldata
    /// @param msgDataLength Length of the data bytes in msg
    /// @param length The number of bytes to read
    /// @return val Parsed uint256 value from calldata
    function _parseCallData(uint256 startByte, uint256 msgDataLength, uint256 length) internal pure returns (uint256) {
        uint256 val;

        if (length > 32) {
            revert PeripheryErrors.LighterV2ParseCallData_ByteSizeLimit32();
        }

        if (length + startByte > msgDataLength) {
            revert PeripheryErrors.LighterV2ParseCallData_CannotReadPastEndOfCallData();
        }

        assembly {
            val := calldataload(startByte)
        }

        val = val >> (256 - length * 8);

        return val;
    }

    /// @dev Parse a number using the exponent and mantissa values from msg.data, starting from the given startByte
    /// The data for mantissa and exponent has the following format:
    /// 2 bits for type, 6 bits for exponent and 3, 5 or 7 bytes for mantissa part of the value depending on the type
    /// @param startByte Index of startByte of calldata
    /// @param msgDataLength Length of the data bytes in msg
    /// @return value Parsed uint256 number
    /// @return parsedBytes The number of bytes read to parse `value`
    function _parseNumberMantissaFromCallData(
        uint256 startByte,
        uint256 msgDataLength
    ) internal pure returns (uint256 value, uint8 parsedBytes) {
        if (startByte >= msgDataLength) {
            revert PeripheryErrors.LighterV2ParseCallData_CannotReadPastEndOfCallData();
        }
        uint256 val;
        assembly {
            val := calldataload(startByte)
        }

        uint8 mantissaType = uint8(val >> (256 - 2));
        uint256 exponent = (val >> (256 - 8)) - (mantissaType << 6);

        if (mantissaType > 2 || exponent > 60) {
            revert PeripheryErrors.LighterV2ParseCallData_InvalidMantissa();
        }

        // For mantissaType = 0, needs to read 3 bytes
        // For mantissaType = 1, needs to read 5 bytes
        // For mantissaType = 2, needs to read 7 bytes
        if (startByte + 3 + 2 * mantissaType >= msgDataLength) {
            revert PeripheryErrors.LighterV2ParseCallData_CannotReadPastEndOfCallData();
        }

        val = (val << 8); // Get rid of the type and exponent

        // For mantissaType = 0, needs to read most significant 24 bits (3 bytes), val >> 232
        // For mantissaType = 1, needs to read most significant 40 bits (5 bytes), val >> 216
        // For mantissaType = 2, needs to read most significant 56 bits (7 bytes), val >> 200
        // Largest exponent can be 60 and maximum value van be is 2^56-1,
        // since 10^60 * (2^56-1) < 2^256, always fits into uint256
        value = (val >> (232 - (mantissaType << 4))) * (10 ** exponent);
        // Number of bytes read is 1 (for type and exponent) + (3 + 2 * type) (for mantissa) = 4 + 2 * type
        parsedBytes = (mantissaType << 1) + 4;
    }

    /// @dev Parse the compressed data which contain isAsk and orderBookId from a single byte
    /// @param startByte Index of startByte of calldata
    /// @param msgDataLength Length of the data bytes in msg
    function _parseCompressedOBFromCallData(
        uint256 startByte,
        uint256 msgDataLength
    ) internal pure returns (bool isAsk, uint8 orderBookId) {
        if (startByte >= msgDataLength) {
            revert PeripheryErrors.LighterV2ParseCallData_CannotReadPastEndOfCallData();
        }

        uint256 val;
        assembly {
            val := calldataload(startByte)
        }

        val = val >> (256 - 8);
        isAsk = ((val) & (1 << 7)) > 0;
        orderBookId = uint8(val) & ((1 << 7) - 1);
    }

    /// @notice Parse for number at specific startByte of calldata
    /// @dev First 3 bits are used to indicate the number of extraBytes, maximum number that
    /// can be represented is 61 bits (remaining 5 bits of extraBytes + 7 bytes)
    /// @param startByte Index of startByte of calldata
    /// @param msgDataLength Length of the data bytes in msg
    /// @return value Parsed number, taking into consideration extraBytes
    /// @return parsedBytes Number of bytes read
    function _parseSizePaddedNumberFromCallData(
        uint256 startByte,
        uint256 msgDataLength
    ) internal pure returns (uint256 value, uint8 parsedBytes) {
        if (startByte >= msgDataLength) {
            revert PeripheryErrors.LighterV2ParseCallData_CannotReadPastEndOfCallData();
        }
        uint256 val;
        assembly {
            val := calldataload(startByte)
        }

        // Split bits which are part of padding
        uint256 extraBytes = (val & ((7) << 253));

        // Remove padding from number
        val ^= extraBytes;

        // Get actual extraBytes number
        extraBytes >>= 253;

        if (startByte + extraBytes >= msgDataLength) {
            revert PeripheryErrors.LighterV2ParseCallData_CannotReadPastEndOfCallData();
        }

        // Parse number, taking into consideration extraBytes
        value = (val) >> (248 - (extraBytes << 3));

        parsedBytes = uint8(++extraBytes);
    }

    /// @inheritdoc IRouter
    function getPaginatedOrders(
        uint8 orderBookId,
        uint32 startOrderId,
        bool isAsk,
        uint32 limit
    ) external view override returns (IOrderBook.OrderQueryItem memory orderData) {
        return _getOrderBookFromId(orderBookId).getPaginatedOrders(startOrderId, isAsk, limit);
    }

    /// @inheritdoc IRouter
    function getLimitOrders(
        uint8 orderBookId,
        uint32 limit
    )
        external
        view
        override
        returns (IOrderBook.OrderQueryItem memory askOrders, IOrderBook.OrderQueryItem memory bidOrders)
    {
        IOrderBook orderBook = _getOrderBookFromId(orderBookId);
        return (orderBook.getPaginatedOrders(0, true, limit), orderBook.getPaginatedOrders(0, false, limit));
    }

    /// @inheritdoc IRouter
    function suggestHintId(uint8 orderBookId, uint64 priceBase, bool isAsk) external view override returns (uint32) {
        return _getOrderBookFromId(orderBookId).suggestHintId(priceBase, isAsk);
    }

    /// @inheritdoc IRouter
    function getQuoteForExactInput(
        uint8 orderBookId,
        bool isAsk,
        uint256 amount
    ) external view override returns (uint256 quotedInput, uint256 quotedOutput) {
        return factory.getQuoteForExactInput(orderBookId, isAsk, amount);
    }

    /// @inheritdoc IRouter
    function getQuoteForExactOutput(
        uint8 orderBookId,
        bool isAsk,
        uint256 amount
    ) external view override returns (uint256 quotedInput, uint256 quotedOutput) {
        return factory.getQuoteForExactOutput(orderBookId, isAsk, amount);
    }

    /// @inheritdoc IRouter
    function getQuoteForExactInputMulti(
        ISwapMultiRequest.SwapRequest[] memory swapRequests,
        uint256 exactInput
    ) external view override returns (uint256 quotedInput, uint256 quotedOutput) {
        // validateMultiPathSwap throws in case of error
        factory.validateMultiPathSwap(swapRequests);

        return factory.getQuoteForExactInputMulti(swapRequests, exactInput);
    }

    /// @inheritdoc IRouter
    function getQuoteForExactOutputMulti(
        ISwapMultiRequest.SwapRequest[] memory swapRequests,
        uint256 exactOutput
    ) external view override returns (uint256 quotedInput, uint256 quotedOutput) {
        // validateMultiPathSwap throws in case of error
        factory.validateMultiPathSwap(swapRequests);

        return factory.getQuoteForExactOutputMulti(swapRequests, exactOutput);
    }

    /// @inheritdoc IRouter
    function validateMultiPathSwap(SwapRequest[] memory swapRequests) external view override {
        factory.validateMultiPathSwap(swapRequests);
    }

    /// @dev Returns IOrderBook for given order book id using factory
    function _getOrderBookFromId(uint8 orderBookId) internal view returns (IOrderBook) {
        address orderBookAddress = factory.getOrderBookFromId(orderBookId);
        if (orderBookAddress == address(0)) {
            revert PeripheryErrors.LighterV2Router_InvalidOrderBookId();
        }
        return IOrderBook(orderBookAddress);
    }
}