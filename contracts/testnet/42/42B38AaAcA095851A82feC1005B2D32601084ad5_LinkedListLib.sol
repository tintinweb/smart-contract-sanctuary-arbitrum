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