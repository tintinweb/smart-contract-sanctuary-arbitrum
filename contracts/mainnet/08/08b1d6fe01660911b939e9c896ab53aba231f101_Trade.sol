// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./interfaces/IChainlink.sol";
import "./interfaces/IStore.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ITrade.sol";

contract Trade is ITrade {
    uint256 public constant UNIT = 10 ** 18;
    uint256 public constant BPS_DIVIDER = 10000;

    // Contracts
    address public gov;
    IChainlink public chainlink;
    IPool public pool;
    IStore public store;

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == gov, "!governance");
        _;
    }

    constructor(address _gov) {
        gov = _gov;
    }

    // Gov methods
    function updateGov(address _gov) external onlyGov {
        require(_gov != address(0), "!address");

        address oldGov = gov;
        gov = _gov;

        emit GovernanceUpdated(oldGov, _gov);
    }

    function link(address _chainlink, address _pool, address _store) external onlyGov {
        chainlink = IChainlink(_chainlink);
        pool = IPool(_pool);
        store = IStore(_store);
    }

    // Deposit / Withdraw logic

    function deposit(uint256 amount) external {
        require(amount > 0, "!amount");
        store.transferIn(msg.sender, amount);
        store.incrementBalance(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }

    function depositThroughUniswap(address tokenIn, uint256 amountIn, uint256 amountOutMin, uint24 poolFee)
        external
        payable
    {
        require(poolFee > 0, "!poolFee");
        require(msg.value != 0 || amountIn > 0 && tokenIn != address(0), "!input");

        address user = msg.sender;

        // executes swap, tokens will be deposited in the store contract
        uint256 amountOut = store.swapExactInputSingle{value: msg.value}(user, amountIn, amountOutMin, tokenIn, poolFee);

        store.incrementBalance(msg.sender, amountOut);

        emit Deposit(msg.sender, amountOut);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "!amount");
        address user = msg.sender;
        store.decrementBalance(user, amount);

        // check equity
        int256 upl = getUpl(user);
        uint256 balance = store.getBalance(user); // balance after decrement
        int256 equity = int256(balance) + upl;
        uint256 lockedMargin = store.getLockedMargin(user);

        require(int256(lockedMargin) <= equity, "!equity");

        store.transferOut(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    // Order logic
    function submitOrder(IStore.Order memory params, uint256 tpPrice, uint256 slPrice) external {
        address user = msg.sender;

        IStore.Market memory market = store.getMarket(params.market);
        require(market.maxLeverage > 0, "!market");

        if (params.isReduceOnly) {
            params.margin = 0;
        } else {
            params.margin = params.size / market.maxLeverage;

            // check equity
            int256 upl = getUpl(user);
            uint256 balance = store.getBalance(user);
            int256 equity = int256(balance) + upl;

            uint256 lockedMargin = store.getLockedMargin(user);
            require(int256(lockedMargin) <= equity, "!equity");

            // if margin exceeds freeMargin, set it to max freeMargin available
            if (int256(lockedMargin + params.margin) > equity) {
                params.margin = uint256(equity - int256(lockedMargin));
                // adjust size so leverage stays the same
                params.size = market.maxLeverage * params.margin;
            }

            require(params.margin > 0 && int256(lockedMargin + params.margin) <= equity, "!margin");
            store.lockMargin(user, params.margin);
        }

        // size should be above market.minSize
        require(market.minSize <= params.size, "!min-size");

        // fee
        uint256 fee = market.fee * params.size / BPS_DIVIDER;
        store.decrementBalance(user, fee);

        // Get chainlink price
        uint256 chainlinkPrice = chainlink.getPrice(market.feed);
        require(chainlinkPrice > 0, "!chainlink");

        // Check chainlink price vs order price for trigger orders
        if (
            params.orderType == 1 && params.isLong && chainlinkPrice <= params.price
                || params.orderType == 1 && !params.isLong && chainlinkPrice >= params.price
                || params.orderType == 2 && params.isLong && chainlinkPrice >= params.price
                || params.orderType == 2 && !params.isLong && chainlinkPrice <= params.price
        ) {
            revert("!orderType");
        }

        // Assign current chainlink price to market orders
        if (params.orderType == 0) {
            params.price = chainlinkPrice;
        }

        // Save order to store
        params.user = user;
        params.fee = uint192(fee);
        params.timestamp = uint64(block.timestamp);

        uint256 orderId = store.addOrder(params);

        emit OrderCreated(
            orderId,
            params.user,
            params.market,
            params.isLong,
            params.margin,
            params.size,
            params.price,
            params.fee,
            params.orderType,
            params.isReduceOnly
            );

        if (tpPrice > 0) {
            IStore.Order memory tpOrder = IStore.Order({
                orderId: 0,
                user: user,
                market: params.market,
                price: tpPrice,
                isLong: !params.isLong,
                isReduceOnly: true,
                orderType: 1,
                margin: 0,
                size: params.size,
                fee: params.fee,
                timestamp: uint64(block.timestamp)
            });
            store.decrementBalance(user, fee);
            uint256 tpOrderId = store.addOrder(tpOrder);
            emit OrderCreated(
                tpOrderId,
                tpOrder.user,
                tpOrder.market,
                tpOrder.isLong,
                tpOrder.margin,
                tpOrder.size,
                tpOrder.price,
                tpOrder.fee,
                tpOrder.orderType,
                tpOrder.isReduceOnly
                );
        }

        if (slPrice > 0) {
            IStore.Order memory slOrder = IStore.Order({
                orderId: 0,
                user: user,
                market: params.market,
                price: slPrice,
                isLong: !params.isLong,
                isReduceOnly: true,
                orderType: 2,
                margin: 0,
                size: params.size,
                fee: params.fee,
                timestamp: uint64(block.timestamp)
            });
            store.decrementBalance(user, fee);
            uint256 slOrderId = store.addOrder(slOrder);
            emit OrderCreated(
                slOrderId,
                slOrder.user,
                slOrder.market,
                slOrder.isLong,
                slOrder.margin,
                slOrder.size,
                slOrder.price,
                slOrder.fee,
                slOrder.orderType,
                slOrder.isReduceOnly
                );
        }
    }

    function updateOrder(uint256 orderId, uint256 price) external {
        IStore.Order memory order = store.getOrder(orderId);
        require(order.user == msg.sender, "!user");
        require(order.size > 0, "!order");
        require(order.orderType != 0, "!market-order");

        IStore.Market memory market = store.getMarket(order.market);
        uint256 chainlinkPrice = chainlink.getPrice(market.feed);
        require(chainlinkPrice > 0, "!chainlink");

        if (
            order.orderType == 1 && order.isLong && chainlinkPrice <= price
                || order.orderType == 1 && !order.isLong && chainlinkPrice >= price
                || order.orderType == 2 && order.isLong && chainlinkPrice >= price
                || order.orderType == 2 && !order.isLong && chainlinkPrice <= price
        ) {
            if (order.orderType == 1) order.orderType = 2;
            else order.orderType = 1;
        }

        order.price = price;
        store.updateOrder(order);
    }

    function cancelOrders(uint256[] calldata orderIds) external {
        for (uint256 i = 0; i < orderIds.length; i++) {
            cancelOrder(orderIds[i]);
        }
    }

    function cancelOrder(uint256 orderId) public {
        IStore.Order memory order = store.getOrder(orderId);
        require(order.user == msg.sender, "!user");
        require(order.size > 0, "!order");
        _cancelOrder(orderId);
    }

    function _cancelOrder(uint256 orderId) internal {
        IStore.Order memory order = store.getOrder(orderId);

        if (!order.isReduceOnly) {
            store.unlockMargin(order.user, order.margin);
        }

        store.removeOrder(orderId);
        store.incrementBalance(order.user, order.fee);

        emit OrderCancelled(orderId, order.user);
    }

    function executeOrders() external {
        uint256[] memory orderIds = getExecutableOrderIds();
        for (uint256 i = 0; i < orderIds.length; i++) {
            uint256 orderId = orderIds[i];
            IStore.Order memory order = store.getOrder(orderId);
            if (order.size == 0 || order.price == 0) continue;
            IStore.Market memory market = store.getMarket(order.market);
            uint256 chainlinkPrice = chainlink.getPrice(market.feed);
            if (chainlinkPrice == 0) continue;
            _executeOrder(order, chainlinkPrice, msg.sender);
        }
    }

    function getExecutableOrderIds() public view returns (uint256[] memory orderIdsToExecute) {
        IStore.Order[] memory orders = store.getOrders();
        uint256[] memory _orderIds = new uint256[](orders.length);
        uint256 j;
        for (uint256 i = 0; i < orders.length; i++) {
            IStore.Order memory order = orders[i];
            IStore.Market memory market = store.getMarket(order.market);

            uint256 chainlinkPrice = chainlink.getPrice(market.feed);
            if (chainlinkPrice == 0) continue;

            // Can this order be executed?
            if (
                order.orderType == 0 || order.orderType == 1 && order.isLong && chainlinkPrice <= order.price
                    || order.orderType == 1 && !order.isLong && chainlinkPrice >= order.price
                    || order.orderType == 2 && order.isLong && chainlinkPrice >= order.price
                    || order.orderType == 2 && !order.isLong && chainlinkPrice <= order.price
            ) {
                // Check settlement time has passed, or chainlinkPrice is different for market order
                if (
                    order.orderType == 0 && chainlinkPrice != order.price
                        || block.timestamp - order.timestamp > market.minSettlementTime
                ) {
                    _orderIds[j] = order.orderId;
                    ++j;
                }
            }
        }

        // Return trimmed result containing only executable order ids
        orderIdsToExecute = new uint256[](j);
        for (uint256 i = 0; i < j; i++) {
            orderIdsToExecute[i] = _orderIds[i];
        }

        return orderIdsToExecute;
    }

    function _executeOrder(IStore.Order memory order, uint256 price, address keeper) internal {
        // Check for existing position
        IStore.Position memory position = store.getPosition(order.user, order.market);

        bool doAdd = !order.isReduceOnly && (position.size == 0 || order.isLong == position.isLong);
        bool doReduce = position.size > 0 && order.isLong != position.isLong;

        if (doAdd) {
            _increasePosition(order, price, keeper);
        } else if (doReduce) {
            _decreasePosition(order, price, keeper);
        } else {
            _cancelOrder(order.orderId);
        }
    }

    // Position logic
    function _increasePosition(IStore.Order memory order, uint256 price, address keeper) internal {
        IStore.Position memory position = store.getPosition(order.user, order.market);

        store.incrementOI(order.market, order.size, order.isLong);

        _updateFundingTracker(order.market);

        uint256 averagePrice = (position.size * position.price + order.size * price) / (position.size + order.size);

        if (position.size == 0) {
            position.user = order.user;
            position.market = order.market;
            position.timestamp = uint64(block.timestamp);
            position.isLong = order.isLong;
            position.fundingTracker = store.getFundingTracker(order.market);
        }

        position.size += order.size;
        position.margin += order.margin;
        position.price = averagePrice;

        store.addOrUpdatePosition(position);

        if (order.orderId > 0) {
            store.removeOrder(order.orderId);
        }

        // Credit fees
        uint256 fee = order.fee;
        uint256 keeperFee = fee * store.keeperFeeShare() / BPS_DIVIDER;
        fee -= keeperFee;
        pool.creditFee(order.user, order.market, fee, false);
        store.incrementBalance(keeper, keeperFee);

        emit PositionIncreased(
            order.orderId,
            order.user,
            order.market,
            order.isLong,
            order.size,
            order.margin,
            price,
            position.margin,
            position.size,
            position.price,
            position.fundingTracker,
            fee,
            keeperFee
            );
    }

    function _decreasePosition(IStore.Order memory order, uint256 price, address keeper) internal {
        IStore.Position memory position = store.getPosition(order.user, order.market);
        IStore.Market memory market = store.getMarket(order.market);

        uint256 executedOrderSize = position.size > order.size ? order.size : position.size;
        uint256 remainingOrderSize = order.size - executedOrderSize;

        if (order.isReduceOnly) {
            // order.margin = 0
            // A fee (order.fee) corresponding to order.size was taken from balance on submit. Only fee corresponding to executedOrderSize should be charged, rest should be returned, if any
            store.incrementBalance(order.user, order.fee * remainingOrderSize / order.size);
        }

        // Funding update
        store.decrementOI(order.market, order.size, position.isLong);
        _updateFundingTracker(order.market);

        // P/L

        (int256 pnl, int256 fundingFee) =
            _getPnL(order.market, position.isLong, price, position.price, executedOrderSize, position.fundingTracker);

        uint256 marginToFree = executedOrderSize / market.maxLeverage;

        position.size -= executedOrderSize;
        position.margin -= marginToFree;
        position.fundingTracker = store.getFundingTracker(order.market);

        if (pnl < 0) {
            uint256 absPnl = uint256(-1 * pnl);
            // credit trader loss to pool
            pool.creditTraderLoss(order.user, order.market, absPnl);
        } else {
            pool.debitTraderProfit(order.user, order.market, uint256(pnl));
        }

        store.unlockMargin(order.user, marginToFree);

        if (position.size == 0) {
            store.removePosition(order.user, order.market);
        } else {
            store.addOrUpdatePosition(position);
        }

        store.removeOrder(order.orderId);

        // Open position in opposite direction if size remains
        if (!order.isReduceOnly && remainingOrderSize > 0) {
            IStore.Order memory nextOrder = IStore.Order({
                orderId: 0,
                user: order.user,
                market: order.market,
                margin: remainingOrderSize / market.maxLeverage,
                size: remainingOrderSize,
                price: 0,
                isLong: order.isLong,
                orderType: 0,
                fee: uint192(order.fee * remainingOrderSize / order.size),
                isReduceOnly: false,
                timestamp: uint64(block.timestamp)
            });

            _increasePosition(nextOrder, price, keeper);
        }

        // Credit fees
        uint256 fee = order.fee;
        uint256 keeperFee = fee * store.keeperFeeShare() / BPS_DIVIDER;
        fee -= keeperFee;
        pool.creditFee(order.user, order.market, fee, false);
        store.incrementBalance(keeper, keeperFee);

        emit PositionDecreased(
            order.orderId,
            order.user,
            order.market,
            order.isLong,
            executedOrderSize,
            marginToFree,
            price,
            position.margin,
            position.size,
            position.price,
            position.fundingTracker,
            fee,
            keeperFee,
            pnl,
            fundingFee
            );
    }

    function closePositionWithoutProfit(string memory _market) external {
        address user = msg.sender;

        IStore.Position memory position = store.getPosition(user, _market);
        require(position.size > 0, "!position");

        IStore.Market memory market = store.getMarket(_market);

        store.decrementOI(_market, position.size, position.isLong);

        _updateFundingTracker(_market);

        uint256 chainlinkPrice = chainlink.getPrice(market.feed);
        require(chainlinkPrice > 0, "!price");

        // P/L

        (int256 pnl,) =
            _getPnL(_market, position.isLong, chainlinkPrice, position.price, position.size, position.fundingTracker);

        // Only profitable positions can be closed this way
        require(pnl >= 0, "pnl < 0");

        store.unlockMargin(user, position.margin);
        store.removePosition(user, _market);

        // Credit fees
        uint256 fee = position.size * market.fee / BPS_DIVIDER;
        pool.creditFee(user, _market, fee, false);

        emit PositionDecreased(
            0,
            user,
            _market,
            !position.isLong,
            position.size,
            position.margin,
            chainlinkPrice,
            position.margin,
            position.size,
            position.price,
            position.fundingTracker,
            fee,
            0,
            0,
            0
            );
    }

    function liquidateUsers() external {
        address[] memory usersToLiquidate = getLiquidatableUsers();
        uint256 userLength = usersToLiquidate.length;
        uint256 liquidatorFees;

        for (uint256 i = 0; i < userLength; i++) {
            uint256 userFees;

            address user = usersToLiquidate[i];
            IStore.Position[] memory positions = store.getUserPositions(user);
            uint256 posLength = positions.length;

            for (uint256 j = 0; j < posLength; j++) {
                IStore.Position memory position = positions[j];
                IStore.Market memory market = store.getMarket(position.market);

                uint256 fee = position.size * market.fee / BPS_DIVIDER;
                uint256 liquidatorFee = fee * store.keeperFeeShare() / BPS_DIVIDER;
                fee -= liquidatorFee;
                liquidatorFees += liquidatorFee;
                userFees += fee + liquidatorFee;

                store.decrementOI(position.market, position.size, position.isLong);
                _updateFundingTracker(position.market);
                store.removePosition(user, position.market);

                uint256 chainlinkPrice = chainlink.getPrice(market.feed);

                // Credit fees
                pool.creditFee(user, position.market, fee, true);

                emit PositionLiquidated(
                    user,
                    position.market,
                    position.isLong,
                    position.size,
                    position.margin,
                    chainlinkPrice,
                    fee,
                    liquidatorFee
                    );
            }

            // Credit full user balance minus fees
            pool.creditTraderLoss(user, "all", store.getBalance(user) - userFees);
            // set margin and user balance to zero
            store.unlockMargin(user, store.getLockedMargin(user));
            store.decrementBalance(user, store.getBalance(user));
        }

        // credit liquidator fees
        store.incrementBalance(msg.sender, liquidatorFees);
    }

    function getLiquidatableUsers() public view returns (address[] memory usersToLiquidate) {
        uint256 length = store.getUsersWithLockedMarginLength();
        address[] memory _users = new address[](length);
        uint256 j;
        for (uint256 i = 0; i < length; i++) {
            address user = store.getUserWithLockedMargin(i);
            int256 equity = int256(store.getBalance(user)) + getUpl(user);
            uint256 lockedMargin = store.getLockedMargin(user);
            uint256 marginLevel;
            if (equity <= 0) {
                marginLevel = 0;
            } else {
                marginLevel = BPS_DIVIDER * uint256(equity) / lockedMargin;
            }
            if (marginLevel < store.minimumMarginLevel()) {
                _users[j] = user;
                ++j;
            }
        }
        // Return trimmed result containing only users to be liquidated
        usersToLiquidate = new address[](j);
        for (uint256 i = 0; i < j; i++) {
            usersToLiquidate[i] = _users[i];
        }
        return usersToLiquidate;
    }

    function getUserPositionsWithUpls(address user)
        external
        view
        returns (IStore.Position[] memory _positions, int256[] memory _upls)
    {
        _positions = store.getUserPositions(user);
        uint256 length = _positions.length;
        _upls = new int256[](length);
        for (uint256 i = 0; i < length; i++) {
            IStore.Position memory position = _positions[i];

            IStore.Market memory market = store.getMarket(position.market);

            uint256 chainlinkPrice = chainlink.getPrice(market.feed);
            if (chainlinkPrice == 0) continue;

            (int256 pnl,) = _getPnL(
                position.market, position.isLong, chainlinkPrice, position.price, position.size, position.fundingTracker
            );

            _upls[i] = pnl;
        }

        return (_positions, _upls);
    }

    function _getPnL(
        string memory market,
        bool isLong,
        uint256 price,
        uint256 positionPrice,
        uint256 size,
        int256 fundingTracker
    ) internal view returns (int256 pnl, int256 fundingFee) {
        if (price == 0 || positionPrice == 0 || size == 0) return (0, 0);

        if (isLong) {
            pnl = int256(size) * (int256(price) - int256(positionPrice)) / int256(positionPrice);
        } else {
            pnl = int256(size) * (int256(positionPrice) - int256(price)) / int256(positionPrice);
        }

        int256 currentFundingTracker = store.getFundingTracker(market);
        fundingFee = int256(size) * (currentFundingTracker - fundingTracker) / (int256(BPS_DIVIDER) * int256(UNIT)); // funding tracker is in UNIT * bps

        if (isLong) {
            pnl -= fundingFee; // positive = longs pay, negative = longs receive
        } else {
            pnl += fundingFee; // positive = shorts receive, negative = shorts pay
        }

        return (pnl, fundingFee);
    }

    function getUpl(address user) public view returns (int256 upl) {
        IStore.Position[] memory positions = store.getUserPositions(user);
        for (uint256 j = 0; j < positions.length; j++) {
            IStore.Position memory position = positions[j];
            IStore.Market memory market = store.getMarket(position.market);

            uint256 chainlinkPrice = chainlink.getPrice(market.feed);
            if (chainlinkPrice == 0) continue;

            (int256 pnl,) = _getPnL(
                position.market, position.isLong, chainlinkPrice, position.price, position.size, position.fundingTracker
            );

            upl += pnl;
        }

        return upl;
    }

    // Funding
    function getAccruedFunding(string memory market, uint256 intervals) public view returns (int256) {
        if (intervals == 0) {
            intervals = (block.timestamp - store.getFundingLastUpdated(market)) / store.FUNDING_INTERVAL();
        }

        if (intervals == 0) return 0;

        uint256 OILong = store.getOILong(market);
        uint256 OIShort = store.getOIShort(market);

        if (OIShort == 0 && OILong == 0) return 0;

        uint256 OIDiff = OIShort > OILong ? OIShort - OILong : OILong - OIShort;
        uint256 yearlyFundingFactor = store.getFundingFactor(market); // in bps
        // intervals = hours since FUNDING_INTERVAL = 1 hour
        uint256 accruedFunding = UNIT * yearlyFundingFactor * OIDiff * intervals / (24 * 365 * (OILong + OIShort)); // in UNIT * bps

        if (OILong > OIShort) {
            // Longs pay shorts. Increase funding tracker.
            return int256(accruedFunding);
        } else {
            // Shorts pay longs. Decrease funding tracker.
            return -1 * int256(accruedFunding);
        }
    }

    function _updateFundingTracker(string memory market) internal {
        uint256 lastUpdated = store.getFundingLastUpdated(market);
        uint256 _now = block.timestamp;

        if (lastUpdated == 0) {
            store.setFundingLastUpdated(market, _now);
            return;
        }

        if (lastUpdated + store.FUNDING_INTERVAL() > _now) return;

        int256 fundingIncrement = getAccruedFunding(market, 0); // in UNIT * bps

        if (fundingIncrement == 0) return;

        store.updateFundingTracker(market, fundingIncrement);
        store.setFundingLastUpdated(market, _now);

        emit FundingUpdated(market, store.getFundingTracker(market), fundingIncrement);
    }

    // Views

    function getMarketsWithPrices() external view returns (IStore.Market[] memory _markets, uint256[] memory _prices) {
        string[] memory marketList = store.getMarketList();
        uint256 length = marketList.length;
        _markets = new IStore.Market[](length);
        _prices = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            IStore.Market memory market = store.getMarket(marketList[i]);
            uint256 chainlinkPrice = chainlink.getPrice(market.feed);
            _markets[i] = market;
            _prices[i] = chainlinkPrice;
        }

        return (_markets, _prices);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IChainlink {
    function getPrice(address feed) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IPool {
    event AddLiquidity(address indexed user, uint256 amount, uint256 clpAmount, uint256 poolBalance);
    event FeePaid(address indexed user, string market, uint256 fee, uint256 poolFee, bool isLiquidation);
    event GovernanceUpdated(address indexed oldGov, address indexed newGov);
    event PoolPayIn(
        address indexed user,
        string market,
        uint256 amount,
        uint256 bufferToPoolAmount,
        uint256 poolBalance,
        uint256 bufferBalance
    );
    event PoolPayOut(address indexed user, string market, uint256 amount, uint256 poolBalance, uint256 bufferBalance);
    event RemoveLiquidity(
        address indexed user, uint256 amount, uint256 feeAmount, uint256 clpAmount, uint256 poolBalance
    );

    function addLiquidity(uint256 amount) external;

    function addLiquidityThroughUniswap(address tokenIn, uint256 amountIn, uint256 amountOutMin, uint24 poolFee)
        external
        payable;

    function creditFee(address user, string memory market, uint256 fee, bool isLiquidation) external;

    function creditTraderLoss(address user, string memory market, uint256 amount) external;

    function debitTraderProfit(address user, string memory market, uint256 amount) external;

    function removeLiquidity(uint256 amount) external;

    function updateGov(address _gov) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IStore {
    // Events
    event GovernanceUpdated(address indexed oldGov, address indexed newGov);

    // Structs
    struct Market {
        string symbol;
        address feed;
        uint16 minSettlementTime; // overflows at ~18hrs
        uint16 maxLeverage; // overflows at 65535
        uint32 fee; // in bps, overflows at 4.3 billion
        uint32 fundingFactor; // Yearly funding rate if OI is completely skewed to one side. In bps.
        uint256 maxOI;
        uint256 minSize;
    }

    struct Order {
        bool isLong;
        bool isReduceOnly;
        uint8 orderType; // 0 = market, 1 = limit, 2 = stop
        uint72 orderId; // overflows at 4.7 * 10**21
        address user;
        string market;
        uint64 timestamp;
        uint192 fee;
        uint256 price;
        uint256 margin;
        uint256 size;
    }

    struct Position {
        bool isLong;
        uint64 timestamp;
        address user;
        string market;
        int256 fundingTracker;
        uint256 price;
        uint256 margin;
        uint256 size;
    }

    function BPS_DIVIDER() external view returns (uint256);

    function FUNDING_INTERVAL() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function MAX_KEEPER_FEE_SHARE() external view returns (uint256);

    function MAX_POOL_WITHDRAWAL_FEE() external view returns (uint256);

    function addOrUpdatePosition(Position memory position) external;

    function addOrder(Order memory order) external returns (uint256);

    function bufferBalance() external view returns (uint256);

    function bufferPayoutPeriod() external view returns (uint256);

    function burnCLP(address user, uint256 amount) external;

    function clp() external view returns (address);

    function currency() external view returns (address);

    function decrementBalance(address user, uint256 amount) external;

    function decrementBufferBalance(uint256 amount) external;

    function decrementOI(string memory market, uint256 size, bool isLong) external;

    function decrementPoolBalance(uint256 amount) external;

    function getBalance(address user) external view returns (uint256);

    function getCLPSupply() external view returns (uint256);

    function getEstimatedOutputTokens(uint256 amountIn, address tokenIn, uint24 poolFee)
        external
        returns (uint256 amountOut);

    function getFundingFactor(string memory market) external view returns (uint256);

    function getFundingLastUpdated(string memory market) external view returns (uint256);

    function getFundingTracker(string memory market) external view returns (int256);

    function getLockedMargin(address user) external view returns (uint256);

    function getMarket(string memory market) external view returns (Market memory _market);

    function getMarketList() external view returns (string[] memory);

    function getOILong(string memory market) external view returns (uint256);

    function getOIShort(string memory market) external view returns (uint256);

    function getOrder(uint256 id) external view returns (Order memory _order);

    function getOrders() external view returns (Order[] memory _orders);

    function getPosition(address user, string memory market) external view returns (Position memory position);

    function getUserOrders(address user) external view returns (Order[] memory _orders);

    function getUserPoolBalance(address user) external view returns (uint256);

    function getUserPositions(address user) external view returns (Position[] memory _positions);

    function getUserWithLockedMargin(uint256 i) external view returns (address);

    function getUsersWithLockedMarginLength() external view returns (uint256);

    function gov() external view returns (address);

    function incrementBalance(address user, uint256 amount) external;

    function incrementBufferBalance(uint256 amount) external;

    function incrementOI(string memory market, uint256 size, bool isLong) external;

    function incrementPoolBalance(uint256 amount) external;

    function keeperFeeShare() external view returns (uint256);

    function link(address _trade, address _pool, address _currency, address _clp) external;

    function linkUniswap(address _swapRouter, address _quoter, address _weth) external;

    function lockMargin(address user, uint256 amount) external;

    function marketList(uint256) external view returns (string memory);

    function minimumMarginLevel() external view returns (uint256);

    function mintCLP(address user, uint256 amount) external;

    function pool() external view returns (address);

    function poolBalance() external view returns (uint256);

    function poolFeeShare() external view returns (uint256);

    function poolLastPaid() external view returns (uint256);

    function poolWithdrawalFee() external view returns (uint256);

    function quoter() external view returns (address);

    function removeOrder(uint256 _orderId) external;

    function removePosition(address user, string memory market) external;

    function setBufferPayoutPeriod(uint256 amount) external;

    function setFundingLastUpdated(string memory market, uint256 timestamp) external;

    function setKeeperFeeShare(uint256 amount) external;

    function setMarket(string memory market, Market memory marketInfo) external;

    function setMinimumMarginLevel(uint256 amount) external;

    function setPoolFeeShare(uint256 amount) external;

    function setPoolLastPaid(uint256 timestamp) external;

    function setPoolWithdrawalFee(uint256 amount) external;

    function swapExactInputSingle(address user, uint256 amountIn, uint256 amountOutMin, address tokenIn, uint24 poolFee)
        external
        payable
        returns (uint256 amountOut);

    function swapRouter() external view returns (address);

    function trade() external view returns (address);

    function transferIn(address user, uint256 amount) external;

    function transferOut(address user, uint256 amount) external;

    function unlockMargin(address user, uint256 amount) external;

    function updateFundingTracker(string memory market, int256 fundingIncrement) external;

    function updateGov(address _gov) external;

    function updateOrder(Order memory order) external;

    function weth() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./IStore.sol";

interface ITrade {
    event Deposit(address indexed user, uint256 amount);
    event FundingUpdated(string market, int256 fundingTracker, int256 fundingIncrement);
    event GovernanceUpdated(address indexed oldGov, address indexed newGov);
    event OrderCancelled(uint256 indexed orderId, address indexed user);
    event OrderCreated(
        uint256 indexed orderId,
        address indexed user,
        string market,
        bool isLong,
        uint256 margin,
        uint256 size,
        uint256 price,
        uint256 fee,
        uint8 orderType,
        bool isReduceOnly
    );
    event PositionDecreased(
        uint256 indexed orderId,
        address indexed user,
        string market,
        bool isLong,
        uint256 size,
        uint256 margin,
        uint256 price,
        uint256 positionMargin,
        uint256 positionSize,
        uint256 positionPrice,
        int256 fundingTracker,
        uint256 fee,
        uint256 keeperFee,
        int256 pnl,
        int256 fundingFee
    );
    event PositionIncreased(
        uint256 indexed orderId,
        address indexed user,
        string market,
        bool isLong,
        uint256 size,
        uint256 margin,
        uint256 price,
        uint256 positionMargin,
        uint256 positionSize,
        uint256 positionPrice,
        int256 fundingTracker,
        uint256 fee,
        uint256 keeperFee
    );
    event PositionLiquidated(
        address indexed user,
        string market,
        bool isLong,
        uint256 size,
        uint256 margin,
        uint256 price,
        uint256 fee,
        uint256 liquidatorFee
    );
    event Withdraw(address indexed user, uint256 amount);

    function BPS_DIVIDER() external view returns (uint256);

    function UNIT() external view returns (uint256);

    function cancelOrder(uint256 orderId) external;

    function cancelOrders(uint256[] memory orderIds) external;

    function closePositionWithoutProfit(string memory _market) external;

    function deposit(uint256 amount) external;

    function depositThroughUniswap(address tokenIn, uint256 amountIn, uint256 amountOutMin, uint24 poolFee)
        external
        payable;

    function executeOrders() external;

    function getAccruedFunding(string memory market, uint256 intervals) external view returns (int256);

    function getExecutableOrderIds() external view returns (uint256[] memory orderIdsToExecute);

    function getLiquidatableUsers() external view returns (address[] memory usersToLiquidate);

    function getMarketsWithPrices() external view returns (IStore.Market[] memory _markets, uint256[] memory _prices);

    function getUpl(address user) external view returns (int256 upl);

    function getUserPositionsWithUpls(address user)
        external
        view
        returns (IStore.Position[] memory _positions, int256[] memory _upls);

    function gov() external view returns (address);

    function link(address _chainlink, address _pool, address _store) external;

    function liquidateUsers() external;

    function submitOrder(IStore.Order memory params, uint256 tpPrice, uint256 slPrice) external;

    function updateGov(address _gov) external;

    function updateOrder(uint256 orderId, uint256 price) external;

    function withdraw(uint256 amount) external;
}