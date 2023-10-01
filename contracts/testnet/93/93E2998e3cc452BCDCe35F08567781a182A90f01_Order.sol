/**
 *Submitted for verification at Arbiscan.io on 2023-09-28
*/

pragma solidity ^0.8.0;

contract Order{

    uint256 public orderId = 1;

    struct OrderInfo{
        uint256 orderId;
        uint256 margin;
        int8 direction;
        uint256 triggerPrice;
        address market;
        bool orderStatus; 
        uint256 tradePrice;                                  //false or true
    }

    mapping(uint256 => OrderInfo) public orders;

    constructor(){

    }

    event CreateOrder(uint256 indexed id, int8 indexed direction, uint256 indexed triggerPrice, uint256 margin,  address market);

    function createOrder(uint256 margin, int8 direction, uint256 triggerPrice, address market)external {
        OrderInfo storage orderInfo = orders[orderId];
        orderInfo.margin = margin;
        orderInfo.direction = direction;
        orderInfo.triggerPrice = triggerPrice;
        orderInfo.market = market;
        orderInfo.orderId = orderId;
        orderId++;

        emit CreateOrder(orderInfo.orderId, orderInfo.direction, orderInfo.triggerPrice, orderInfo.margin, orderInfo.market);
    }

    function executeOrder(uint256 id, uint256 price)external{
        require(price > 0,"E0");

        OrderInfo storage orderInfo = orders[id];
        orderInfo.orderStatus = true;
        orderInfo.tradePrice = price;
    }
}