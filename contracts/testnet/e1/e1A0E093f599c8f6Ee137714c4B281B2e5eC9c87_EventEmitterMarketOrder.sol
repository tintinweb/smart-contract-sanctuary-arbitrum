/**
 *Submitted for verification at Arbiscan.io on 2023-11-09
*/

library TypeLibrary {
    enum Side {
        NULL,
        LONG,
        SHORT
    }

    enum OrderType {
        NULL,
        MARKET,
        LIMIT,
        STOP_MARKET
    }

    enum OrderState {
        NULL,
        REQUESTED,
        PENDING,
        CANCELLED,
        FULFILLED
    }

    struct Position {
        uint256 instId;
        TypeLibrary.Side posSide;
        uint256 posSize; // scaling factor: SIZE_SCALING_FACTOR
        uint256 avgPx; // scaling factor: 10^base_token_decimals
        int256 fundingAcc;
    }

    // MARKET: MarketOrderRequest => Trading => execuete order
    // LIMIT: PendingOrderRequest => Trading => createOpenPendingOrder => execuete order

    struct MarketOrder {
        Order order;
    }

    struct PendingOrder {
        Order order;
        uint256 pendingOrdId;
        uint256 triggerPrice;
        uint256 timestamp;
    }

    struct Order {
        OrderType ordType;
        OrderState ordState;
        address portfolio;
        uint256 instId;
        Side ordSide;
        uint256 ordSize;
        uint256 fulfillPrice;
        uint256 stopPrice;
    }

    uint256 public constant SIZE_SCALING_FACTOR = 10 ** 4;
    uint256 public constant RATIO_SCALING_FACTOR = 10 ** 4;
    uint256 public constant VALUE_SCALING_FACTOR = 10 ** 8; // USD vaule
}


contract EventEmitterMarketOrder {
    event RequestPrice(uint256 indexed _requestType, bytes data);

    function trigger(uint256 _requestType) external {
        if (_requestType == 1) {
            TypeLibrary.MarketOrder memory marketOrder = TypeLibrary
                .MarketOrder(
                    TypeLibrary.Order(
                        TypeLibrary.OrderType.MARKET,
                        TypeLibrary.OrderState.REQUESTED,
                        address(this),
                        1,
                        TypeLibrary.Side.LONG,
                        10,
                        123,
                        456
                    )
                );
            emit RequestPrice(1, abi.encode(marketOrder));
        } else if (_requestType == 2) {
            TypeLibrary.PendingOrder memory pendingOrder = TypeLibrary
                .PendingOrder(
                    TypeLibrary.Order(
                        TypeLibrary.OrderType.MARKET,
                        TypeLibrary.OrderState.REQUESTED,
                        address(this),
                        1,
                        TypeLibrary.Side.LONG,
                        10,
                        123,
                        456
                    ),
                    1,
                    123,
                    16000
                );
            emit RequestPrice(2, abi.encode(pendingOrder));
        }
    }
}