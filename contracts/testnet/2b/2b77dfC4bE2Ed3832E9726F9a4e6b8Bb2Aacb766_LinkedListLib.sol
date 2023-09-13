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
    error LighterV2Order_FillOrKillOrder_NotFilled();

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

/// @title LinkedList
/// @notice Struct to use for storing sorted linked lists of ask and bid orders
struct LinkedList {
    mapping(uint32 => LimitOrder) asks;
    mapping(uint32 => LimitOrder) bids;
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
        mapping(uint32 => LimitOrder) storage orders = isAsk ? self.asks : self.bids;
        LimitOrder storage order = orders[orderId];

        if (orders[hintId].next == 0) {
            revert Errors.LighterV2Order_InvalidHintId();
        }

        while (orders[hintId].ownerId == 0) {
            hintId = orders[hintId].next;
        }

        // After the search, hintId will be where the new order should be inserted to the right of
        LimitOrder memory hintOrder = orders[hintId];
        while (hintId != 1) {
            LimitOrder memory nextOrder = orders[hintOrder.next];
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

        mapping(uint32 => LimitOrder) storage orders = isAsk ? self.asks : self.bids;

        if (orders[orderId].ownerId == 0) {
            revert Errors.LighterV2Order_CannotCancelInactiveOrders();
        }
        LimitOrder storage order = orders[orderId];
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
    ) public view returns (OrderQueryItem memory paginatedOrders) {
        mapping(uint32 => LimitOrder) storage orders = isAsk ? self.asks : self.bids;

        if (orders[startOrderId].ownerId == 0) {
            revert Errors.LighterV2Order_CannotQueryFromInactiveOrder();
        }
        uint32 i = 0;
        paginatedOrders.ids = new uint32[](limit);
        paginatedOrders.owners = new address[](limit);
        paginatedOrders.amount0s = new uint256[](limit);
        paginatedOrders.prices = new uint256[](limit);
        for (uint32 pointer = orders[startOrderId].next; pointer != 1 && i < limit; pointer = orders[pointer].next) {
            LimitOrder memory order = orders[pointer];
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

    /// @notice Find the order id to the right of where an order with given priceBase should be inserted.
    /// @param priceBase The priceBase to suggest the hintId for
    function suggestHintId(LinkedList storage self, uint64 priceBase, bool isAsk) public view returns (uint32) {
        mapping(uint32 => LimitOrder) storage orders = isAsk ? self.asks : self.bids;
        // left of where the new order should be inserted.
        uint32 hintOrderId = 0;
        LimitOrder memory hintOrder = orders[hintOrderId];
        while (hintOrderId != 1) {
            LimitOrder memory nextOrder = orders[hintOrder.next];
            if (isAsk ? (priceBase < nextOrder.priceBase) : (priceBase > nextOrder.priceBase)) break;
            hintOrderId = hintOrder.next;
            hintOrder = nextOrder;
        }
        return hintOrderId;
    }
}