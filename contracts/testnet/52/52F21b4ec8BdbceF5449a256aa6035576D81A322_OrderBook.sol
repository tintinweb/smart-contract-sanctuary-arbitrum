// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IERC20.sol";
import "IOrderBook.sol";

//security avoid reentrancy attacks
//todo add and test events
//todo manage erc-1155 tokens

contract OrderBook is IOrderBook {
    struct Order {
        address maker;
        uint256 pricePerUnit;
        uint256 startingAmount;
        uint256 amount;
        Type orderType;
        Status status;
        uint256 timestampOpen;
        uint256 timestampClose;
    }

    struct OrderParams {
        uint256 price;
        uint256 amount;
        Type orderType;
        address token;
    }

    struct Match {
        uint256 amount;
        uint256 price;
        uint256 timestamp;
    }

    uint256 private constant _MAX_UINT = type(uint256).max;

    uint256 private _id;
    address public bookToken;
    address public priceToken;
    uint256 public marketPrice;
    // todo add commission

    mapping(uint256 => Order) public orderID_order;
    mapping(uint256 => Match[]) public orderID_matches;
    mapping(address => uint256[]) public user_ordersId;
    mapping(uint256 => uint256[]) public price_openAsks; // asks ordered by time
    mapping(uint256 => uint256[]) public price_openBids; // bids ordered by time
    // stack of all open asks ordered by pricePerUnit asc, [length-1] is the best
    uint256[] public openAsksStack;
    // stack of all open bids ordered by pricePerUnit desc, [length-1] is the best
    uint256[] public openBidsStack;

    constructor(address _bookToken, address _priceToken) {
        _id = 1;
        bookToken = _bookToken;
        priceToken = _priceToken;
        marketPrice = 0;
    }

    function marketBuy(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than zero");
        require(openAsksStack.length > 0, "No open asks");

        _marketOrder(_amount, Type.MarketBuy, price_openAsks, openAsksStack);
    }

    function marketSell(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than zero");
        require(openBidsStack.length > 0, "No open bids");

        _marketOrder(_amount, Type.MarketSell, price_openBids, openBidsStack);
    }

    function _marketOrder(
        uint256 _amount,
        Type _orderType,
        mapping(uint256 => uint256[]) storage openOrders,
        uint256[] storage openOrdersStack
    ) internal {
        uint256 maxPrice = _orderType == Type.MarketBuy ? _MAX_UINT : 0;

        orderID_order[_id] = Order(
            msg.sender,
            maxPrice,
            _amount,
            _amount,
            _orderType,
            Status.Open,
            block.timestamp,
            0
        );

        Order storage newOrder = orderID_order[_id];
        user_ordersId[msg.sender].push(_id);

        uint256 bestPrice = _orderType == Type.MarketBuy
            ? bestAskPrice()
            : bestBidPrice();

        uint256 i = 0;
        while (
            newOrder.status != Status.Filled &&
            ((_orderType == Type.MarketBuy && bestPrice < maxPrice) ||
                (_orderType == Type.MarketSell && bestPrice > maxPrice))
        ) {
            uint256 bestOrderId = openOrders[bestPrice][i];
            Order storage bestOrder = orderID_order[bestOrderId];
            newOrder.pricePerUnit = bestPrice;

            if (_orderType == Type.MarketBuy) _matchOrders(_id, bestOrderId);
            else _matchOrders(bestOrderId, _id);

            if (bestOrder.status == Status.Filled) i++;

            if (openOrders[bestPrice].length == i) {
                openOrders[bestPrice] = new uint[](0);
                openOrdersStack.pop();
                bestPrice = _orderType == Type.MarketBuy
                    ? bestAskPrice()
                    : bestBidPrice();
                i = 0;
            }
        }

        _skip(openOrders[bestPrice], i);

        uint256 totalAmount = 0;
        uint256 totalValue = 0;
        for (uint256 k = 0; k < orderID_matches[_id].length; k++) {
            Match memory thisMatch = orderID_matches[_id][k];
            totalValue += thisMatch.price * thisMatch.amount;
            totalAmount += thisMatch.amount;
        }

        newOrder.pricePerUnit = totalAmount == 0 ? 0 : totalValue / totalAmount;

        _id++;

        if (newOrder.status == Status.Open) {
            uint256 remainder = newOrder.amount;
            _fillOrder(newOrder, _id - 1);
            newOrder.amount = remainder;

            if (_orderType == Type.MarketBuy) {
                OrderParams memory orderParams = OrderParams(
                    marketPrice,
                    remainder,
                    Type.Bid,
                    priceToken
                );
                _addLimitOrder(
                    orderParams,
                    price_openBids,
                    price_openAsks,
                    openBidsStack,
                    openAsksStack
                );
            } else {
                OrderParams memory orderParams = OrderParams(
                    marketPrice,
                    remainder,
                    Type.Ask,
                    bookToken
                );
                _addLimitOrder(
                    orderParams,
                    price_openAsks,
                    price_openBids,
                    openAsksStack,
                    openBidsStack
                );
            }
        }
    }

    function addBid(uint256 _price, uint256 _amount) external {
        require(_price > 0, "Price must be greater than zero");
        require(_amount > 0, "Amount must be greater than zero");
        require(
            _price <= bestAskPrice(),
            "Price must be less or equal than best ask price"
        );

        OrderParams memory orderParams = OrderParams(
            _price,
            _amount,
            Type.Bid,
            priceToken
        );

        _addLimitOrder(
            orderParams,
            price_openBids,
            price_openAsks,
            openBidsStack,
            openAsksStack
        );
    }

    function addAsk(uint256 _price, uint256 _amount) external {
        require(_price > 0, "Price must be greater than zero");
        require(_amount > 0, "Amount must be greater than zero");
        require(
            _price >= bestBidPrice(),
            "Price must be greater or equal than best bid price"
        );

        OrderParams memory orderParams = OrderParams(
            _price,
            _amount,
            Type.Ask,
            bookToken
        );

        _addLimitOrder(
            orderParams,
            price_openAsks,
            price_openBids,
            openAsksStack,
            openBidsStack
        );
    }

    function _addLimitOrder(
        OrderParams memory orderParams,
        mapping(uint256 => uint256[]) storage openOrders,
        mapping(uint256 => uint256[]) storage antagonistOpenOrders,
        uint256[] storage openOrdersStack,
        uint256[] storage antagonistOpenOrdersStack
    ) internal {
        orderID_order[_id] = Order(
            msg.sender,
            orderParams.price,
            orderParams.amount,
            orderParams.amount,
            orderParams.orderType,
            Status.Open,
            block.timestamp,
            0
        );

        Order storage newOrder = orderID_order[_id];
        user_ordersId[msg.sender].push(_id);

        uint256 transferAmount = orderParams.orderType == Type.Bid
            ? (orderParams.amount * orderParams.price) / 1e18
            : orderParams.amount;
        IERC20(orderParams.token).transferFrom(
            msg.sender,
            address(this),
            transferAmount
        );

        uint256 i = 0;
        while (
            newOrder.status == Status.Open &&
            i < antagonistOpenOrders[orderParams.price].length
        ) {
            uint256 bestOrderID = antagonistOpenOrders[orderParams.price][i];

            if (orderParams.orderType == Type.Bid)
                _matchOrders(_id, bestOrderID);
            else _matchOrders(bestOrderID, _id);
            i++;
        }

        if (newOrder.status == Status.Open) {
            openOrders[orderParams.price].push(_id);
            _insertOrderInStack(
                orderParams.price,
                orderParams.orderType,
                openOrders[orderParams.price],
                openOrdersStack
            );
        }

        _id++;

        if (i == 0) return;
        Order storage secondBestOrder = orderID_order[
            antagonistOpenOrders[orderParams.price][i - 1]
        ];
        antagonistOpenOrders[orderParams.price] = secondBestOrder.status ==
            Status.Filled
            ? _skip(antagonistOpenOrders[orderParams.price], i)
            : _skip(antagonistOpenOrders[orderParams.price], i - 1);

        if (antagonistOpenOrders[orderParams.price].length == 0)
            antagonistOpenOrdersStack.pop();
    }

    function _insertOrderInStack(
        uint256 _price,
        Type _orderType,
        uint256[] storage openOrders,
        uint256[] storage orderStack
    ) private {
        if (openOrders.length == 1) {
            uint256 j = orderStack.length;
            orderStack.push(_price);
            while (
                j > 0 &&
                ((_orderType == Type.Bid && orderStack[j - 1] > _price) ||
                    (_orderType == Type.Ask && orderStack[j - 1] < _price))
            ) {
                orderStack[j] = orderStack[j - 1];
                j--;
            }
            orderStack[j] = _price;
        }
    }

    function _matchOrders(uint256 bidId, uint256 askId) internal {
        uint256 matchedBookTokens = 0;
        Order storage bid = orderID_order[bidId];
        Order storage ask = orderID_order[askId];

        if (bid.amount == ask.amount) {
            matchedBookTokens = bid.amount;
            _fillOrder(bid, bidId);
            _fillOrder(ask, askId);
        } else if (bid.amount > ask.amount) {
            matchedBookTokens = ask.amount;
            _partialFillOrder(bid, ask.amount, bidId);
            _fillOrder(ask, askId);
        } else {
            matchedBookTokens = bid.amount;
            _partialFillOrder(ask, bid.amount, askId);
            _fillOrder(bid, bidId);
        }

        if (bid.orderType == Type.MarketBuy) {
            IERC20(bookToken).transfer(bid.maker, matchedBookTokens);
            IERC20(priceToken).transferFrom(
                bid.maker,
                ask.maker,
                (matchedBookTokens * ask.pricePerUnit) / 1e18
            );
        } else if (ask.orderType == Type.MarketSell) {
            IERC20(bookToken).transferFrom(
                ask.maker,
                bid.maker,
                matchedBookTokens
            );
            IERC20(priceToken).transfer(
                ask.maker,
                (matchedBookTokens * bid.pricePerUnit) / 1e18
            );
        } else {
            IERC20(bookToken).transfer(bid.maker, matchedBookTokens);
            IERC20(priceToken).transfer(
                ask.maker,
                (matchedBookTokens * ask.pricePerUnit) / 1e18
            );
        }
        marketPrice = ask.pricePerUnit;
    }

    function _fillOrder(Order storage order, uint256 orderId) internal {
        orderID_matches[orderId].push(
            Match(order.amount, order.pricePerUnit, block.timestamp)
        );
        order.amount = 0;
        order.status = Status.Filled;
        order.timestampClose = block.timestamp;
    }

    function _partialFillOrder(
        Order storage order,
        uint256 amount,
        uint256 orderId
    ) internal {
        orderID_matches[orderId].push(
            Match(amount, order.pricePerUnit, block.timestamp)
        );
        order.amount -= amount;
    }

    function bestBidPrice() public view returns (uint256) {
        if (openBidsStack.length == 0) return 0;
        return openBidsStack[openBidsStack.length - 1];
    }

    function _getBidPrice(uint256 index) internal view returns (uint256) {
        if (openBidsStack.length == index) return 0;
        return openBidsStack[openBidsStack.length - (1 + index)];
    }

    function bestAskPrice() public view returns (uint256) {
        if (openAsksStack.length == 0) return _MAX_UINT;
        return openAsksStack[openAsksStack.length - 1];
    }

    function _getAskPrice(uint256 index) internal view returns (uint256) {
        if (openAsksStack.length == index) return _MAX_UINT;
        return openAsksStack[openAsksStack.length - (1 + index)];
    }

    function getLiquidityDepthByPrice(
        uint256 price
    ) public view returns (uint256) {
        uint256 liquidityDepth = 0;

        uint256[] storage openOrders = price_openBids[price].length > 0
            ? price_openBids[price]
            : price_openAsks[price];

        for (uint256 i = 0; i < openOrders.length; i++) {
            uint256 orderId = openOrders[i];
            Order storage order = orderID_order[orderId];
            liquidityDepth += order.amount;
        }

        return liquidityDepth;
    }

    function getMarketOrderAveragePrice(
        uint256 amount,
        Type orderType
    ) external view returns (uint256) {
        require(amount > 0, "Amount must be greater than zero");
        require(
            (orderType == Type.MarketBuy && openAsksStack.length > 0) ||
                (orderType == Type.MarketSell && openBidsStack.length > 0),
            "No open orders"
        );

        uint256 totalAmount = 0;
        uint256 totalValue = 0;
        uint256 i = 0;
        uint256 bestPrice = orderType == Type.MarketBuy
            ? bestAskPrice()
            : bestBidPrice();

        while (
            totalAmount < amount &&
            ((orderType == Type.MarketBuy && bestPrice < _MAX_UINT) ||
                (orderType == Type.MarketSell && bestPrice > 0))
        ) {
            uint256 bestPriceDepth = getLiquidityDepthByPrice(bestPrice);
            totalAmount += bestPriceDepth;
            totalValue += bestPriceDepth * bestPrice;

            i++;
            bestPrice = orderType == Type.MarketBuy
                ? _getAskPrice(i)
                : _getBidPrice(i);
        }

        if (amount >= totalAmount) return totalValue / totalAmount;

        bestPrice = orderType == Type.MarketBuy
            ? _getAskPrice(i - 1)
            : _getBidPrice(i - 1);

        uint256 remainder = totalAmount - amount;
        totalAmount -= remainder;
        totalValue -= remainder * bestPrice;

        return totalValue / totalAmount;
    }

    function cancelOrder(uint256 orderID) external {
        require(orderID_order[orderID].maker != address(0), "Order not found");
        require(msg.sender == orderID_order[orderID].maker, "Not order maker");
        require(orderID_order[orderID].status == Status.Open, "Order not open");

        Order storage order = orderID_order[orderID];
        order.status = Status.Cancelled;
        order.timestampClose = block.timestamp;

        if (order.orderType == Type.Bid) {
            uint256[] storage openBids = price_openBids[order.pricePerUnit];
            for (uint256 i = 0; i < openBids.length; i++) {
                if (openBids[i] == orderID) {
                    _deleteItem(i, openBids);
                    break;
                }
            }
            if (openBids.length == 0) {
                for (uint256 i = 0; i < openBidsStack.length; i++) {
                    if (openBidsStack[i] == order.pricePerUnit) {
                        _deleteItem(i, openBidsStack);
                        break;
                    }
                }
            }

            IERC20(priceToken).transfer(
                order.maker,
                (order.amount * order.pricePerUnit) / 1e18
            );
        } else {
            uint256[] storage openAsks = price_openAsks[order.pricePerUnit];
            for (uint256 i = 0; i < openAsks.length; i++) {
                if (openAsks[i] == orderID) {
                    _deleteItem(i, openAsks);
                    break;
                }
            }
            if (openAsks.length == 0) {
                for (uint256 i = 0; i < openAsksStack.length; i++) {
                    if (openAsksStack[i] == order.pricePerUnit) {
                        _deleteItem(i, openAsksStack);
                        break;
                    }
                }
            }

            IERC20(bookToken).transfer(order.maker, order.amount);
        }
    }

    function _skip(
        uint256[] memory array,
        uint256 n
    ) private pure returns (uint256[] memory) {
        require(
            n <= array.length,
            "Cannot skip more elements than the array length"
        );
        if (n == 0) return array;

        uint[] memory result = new uint[](array.length - n);
        for (uint i = n; i < array.length; i++) {
            result[i - n] = array[i];
        }
        return result;
    }

    function _deleteItem(uint256 index, uint256[] storage array) internal {
        require(index < array.length, "Index out of bounds");
        for (uint256 i = index; i < array.length - 1; i++) {
            array[i] = array[i + 1];
        }
        array.pop();
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOrderBook {
    enum Type {
        Bid,
        Ask,
        MarketBuy,
        MarketSell
    }

    enum Status {
        Open,
        Filled,
        Cancelled
    }

    function addBid(uint256 price, uint256 amount) external;

    function addAsk(uint256 price, uint256 amount) external;

    function marketBuy(uint256 amount) external;

    function marketSell(uint256 amount) external;

    function cancelOrder(uint256 orderID) external;

    function bestBidPrice() external view returns (uint256);

    function bestAskPrice() external view returns (uint256);

    function getLiquidityDepthByPrice(
        uint256 price
    ) external view returns (uint256);

    function getMarketOrderAveragePrice(
        uint256 amount,
        Type orderType
    ) external view returns (uint256);
}