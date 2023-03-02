// File: contracts\interfaces\UniswapRouterInterfaceV5.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
import "../interfaces/UniswapRouterInterfaceV5.sol";
import "../interfaces/TokenInterfaceV5.sol";
import "../interfaces/NftInterfaceV5.sol";
import "../interfaces/VaultInterfaceV5.sol";
import "../interfaces/PairsStorageInterfaceV6.sol";
import "../interfaces/StorageInterfaceV5.sol";
import "../interfaces/MMTPairInfosInterfaceV6.sol";
import "../interfaces/MMTReferralsInterfaceV6_2.sol";
import "../interfaces/NftRewardsInterfaceV6.sol";
import "../interfaces/IWhitelist.sol";
import "../helpers/Delegatable.sol";

contract MTTTrading is Delegatable {
    // Contracts (constant)
    StorageInterfaceV5 public immutable storageT;
    NftRewardsInterfaceV6 public immutable nftRewards;
    MMTPairInfosInterfaceV6 public immutable pairInfos;
    MMTReferralsInterfaceV6_2 public immutable referrals;
    IWhitelist public whitelist;

    // Params (constant)
    uint256 constant PRECISION = 1e10;
    uint256 constant MAX_SL_P = 75; // -75% PNL

    // Params (adjustable)
    uint256 public maxPosDai; // 1e18 (eg. 75000 * 1e18)
    uint256 public limitOrdersTimelock; // block (eg. 30)
    uint256 public marketOrdersTimeout; // block (eg. 30)

    // State
    bool public isPaused; // Prevent opening new trades
    bool public isDone; // Prevent any interaction with the contract

    // Events
    event Done(bool done);
    event Paused(bool paused);

    event NumberUpdated(string name, uint256 value);

    event MarketOrderInitiated(
        uint256 indexed orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        bool open
    );

    event OpenLimitPlaced(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index
    );
    event OpenLimitUpdated(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint256 newPrice,
        uint256 newTp,
        uint256 newSl
    );
    event OpenLimitCanceled(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index
    );

    event TpUpdated(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint256 newTp
    );
    event SlUpdated(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint256 newSl
    );
    event SlUpdateInitiated(
        uint256 indexed orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint256 newSl
    );

    event NftOrderInitiated(
        uint256 orderId,
        address indexed nftHolder,
        address indexed trader,
        uint256 indexed pairIndex
    );
    event NftOrderSameBlock(
        address indexed nftHolder,
        address indexed trader,
        uint256 indexed pairIndex
    );

    event ChainlinkCallbackTimeout(
        uint256 indexed orderId,
        StorageInterfaceV5.PendingMarketOrder order
    );
    event CouldNotCloseTrade(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index
    );

    constructor(
        StorageInterfaceV5 _storageT,
        NftRewardsInterfaceV6 _nftRewards,
        MMTPairInfosInterfaceV6 _pairInfos,
        MMTReferralsInterfaceV6_2 _referrals,
        uint256 _maxPosDai,
        uint256 _limitOrdersTimelock,
        uint256 _marketOrdersTimeout
    ) {
        require(
            address(_storageT) != address(0) &&
                address(_nftRewards) != address(0) &&
                address(_pairInfos) != address(0) &&
                address(_referrals) != address(0) &&
                _maxPosDai > 0 &&
                _limitOrdersTimelock > 0 &&
                _marketOrdersTimeout > 0,
            "WRONG_PARAMS"
        );

        storageT = _storageT;
        nftRewards = _nftRewards;
        pairInfos = _pairInfos;
        referrals = _referrals;

        maxPosDai = _maxPosDai;
        limitOrdersTimelock = _limitOrdersTimelock;
        marketOrdersTimeout = _marketOrdersTimeout;
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier notContract() {
        require(tx.origin == msg.sender);
        _;
    }
    modifier notDone() {
        require(!isDone, "DONE");
        _;
    }

    modifier checkWhitelist() {
        require(
            address(whitelist) == address(0) ||
                whitelist.isWhitelists(msg.sender),
            "NOT_IN_WHITELIST"
        );
        _;
    }

    // Manage params
    function setMaxPosDai(uint256 value) external onlyGov {
        require(value > 0, "VALUE_0");
        maxPosDai = value;

        emit NumberUpdated("maxPosDai", value);
    }

    function setLimitOrdersTimelock(uint256 value) external onlyGov {
        require(value > 0, "VALUE_0");
        limitOrdersTimelock = value;

        emit NumberUpdated("limitOrdersTimelock", value);
    }

    function setMarketOrdersTimeout(uint256 value) external onlyGov {
        require(value > 0, "VALUE_0");
        marketOrdersTimeout = value;

        emit NumberUpdated("marketOrdersTimeout", value);
    }

    function setWhitelistContract(IWhitelist whitelistContract)
        external
        onlyGov
    {
        whitelist = whitelistContract;
    }

    // Manage state
    function pause() external onlyGov {
        isPaused = !isPaused;

        emit Paused(isPaused);
    }

    function done() external onlyGov {
        isDone = !isDone;

        emit Done(isDone);
    }

    // Open new trade (MARKET/LIMIT)
    function openTrade(
        StorageInterfaceV5.Trade memory t,
        NftRewardsInterfaceV6.OpenLimitOrderType orderType, // LEGACY => market
        uint256 spreadReductionId,
        uint256 slippageP, // for market orders only
        address referrer
    ) external notContract notDone checkWhitelist {
        require(!isPaused, "PAUSED");

        AggregatorInterfaceV6 aggregator = storageT.priceAggregator();
        PairsStorageInterfaceV6 pairsStored = aggregator.pairsStorage();

        address sender = _msgSender();

        require(
            storageT.openTradesCount(sender, t.pairIndex) +
                storageT.pendingMarketOpenCount(sender, t.pairIndex) +
                storageT.openLimitOrdersCount(sender, t.pairIndex) <
                storageT.maxTradesPerPair(),
            "MAX_TRADES_PER_PAIR"
        );

        require(
            storageT.pendingOrderIdsCount(sender) <
                storageT.maxPendingMarketOrders(),
            "MAX_PENDING_ORDERS"
        );

        require(t.positionSizeDai <= maxPosDai, "ABOVE_MAX_POS");
        require(
            t.positionSizeDai * t.leverage >=
                pairsStored.pairMinLevPosDai(t.pairIndex),
            "BELOW_MIN_POS"
        );

        require(
            t.leverage > 0 &&
                t.leverage >= pairsStored.pairMinLeverage(t.pairIndex) &&
                t.leverage <= pairsStored.pairMaxLeverage(t.pairIndex),
            "LEVERAGE_INCORRECT"
        );

        require(
            spreadReductionId == 0 ||
                storageT.nfts(spreadReductionId - 1).balanceOf(sender) > 0,
            "NO_CORRESPONDING_NFT_SPREAD_REDUCTION"
        );

        require(
            t.tp == 0 || (t.buy ? t.tp > t.openPrice : t.tp < t.openPrice),
            "WRONG_TP"
        );

        require(
            t.sl == 0 || (t.buy ? t.sl < t.openPrice : t.sl > t.openPrice),
            "WRONG_SL"
        );

        (uint256 priceImpactP, ) = pairInfos.getTradePriceImpact(
            0,
            t.pairIndex,
            t.buy,
            t.positionSizeDai * t.leverage
        );

        require(
            priceImpactP * t.leverage <= pairInfos.maxNegativePnlOnOpenP(),
            "PRICE_IMPACT_TOO_HIGH"
        );

        storageT.transferDai(sender, address(storageT), t.positionSizeDai);

        //thangtest
        //referrals.registerPotentialReferrer(sender, referrer);

        if (orderType != NftRewardsInterfaceV6.OpenLimitOrderType.LEGACY) {
            uint256 index = storageT.firstEmptyOpenLimitIndex(
                sender,
                t.pairIndex
            );

            storageT.storeOpenLimitOrder(
                StorageInterfaceV5.OpenLimitOrder(
                    sender,
                    t.pairIndex,
                    index,
                    t.positionSizeDai,
                    spreadReductionId > 0
                        ? storageT.spreadReductionsP(spreadReductionId - 1)
                        : 0,
                    t.buy,
                    t.leverage,
                    t.tp,
                    t.sl,
                    t.openPrice,
                    t.openPrice,
                    block.number,
                    0
                )
            );

            nftRewards.setOpenLimitOrderType(
                sender,
                t.pairIndex,
                index,
                orderType
            );

            emit OpenLimitPlaced(sender, t.pairIndex, index);
        } else {
            uint256 orderId = aggregator.getPrice(
                t.pairIndex,
                AggregatorInterfaceV6.OrderType.MARKET_OPEN,
                t.positionSizeDai * t.leverage
            );

            storageT.storePendingMarketOrder(
                StorageInterfaceV5.PendingMarketOrder(
                    StorageInterfaceV5.Trade(
                        sender,
                        t.pairIndex,
                        0,
                        0,
                        t.positionSizeDai,
                        0,
                        t.buy,
                        t.leverage,
                        t.tp,
                        t.sl
                    ),
                    0,
                    t.openPrice,
                    slippageP,
                    spreadReductionId > 0
                        ? storageT.spreadReductionsP(spreadReductionId - 1)
                        : 0,
                    0
                ),
                orderId,
                true
            );

            aggregator.emptyNodeFulFill(
                t.pairIndex,
                orderId,
                AggregatorInterfaceV6.OrderType.MARKET_OPEN
            );

            emit MarketOrderInitiated(orderId, sender, t.pairIndex, true);
        }

        //thangtest move up function
        referrals.registerPotentialReferrer(sender, referrer);
    }

    // Close trade (MARKET)
    function closeTradeMarket(uint256 pairIndex, uint256 index)
        external
        notContract
        notDone
    {
        address sender = _msgSender();

        StorageInterfaceV5.Trade memory t = storageT.openTrades(
            sender,
            pairIndex,
            index
        );

        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(
            sender,
            pairIndex,
            index
        );

        require(
            storageT.pendingOrderIdsCount(sender) <
                storageT.maxPendingMarketOrders(),
            "MAX_PENDING_ORDERS"
        );

        require(!i.beingMarketClosed, "ALREADY_BEING_CLOSED");
        require(t.leverage > 0, "NO_TRADE");

        uint256 orderId = storageT.priceAggregator().getPrice(
            pairIndex,
            AggregatorInterfaceV6.OrderType.MARKET_CLOSE,
            (t.initialPosToken * i.tokenPriceDai * t.leverage) / PRECISION
        );

        storageT.storePendingMarketOrder(
            StorageInterfaceV5.PendingMarketOrder(
                StorageInterfaceV5.Trade(
                    sender,
                    pairIndex,
                    index,
                    0,
                    0,
                    0,
                    false,
                    0,
                    0,
                    0
                ),
                0,
                0,
                0,
                0,
                0
            ),
            orderId,
            false
        );

        storageT.priceAggregator().emptyNodeFulFill(
            pairIndex,
            orderId,
            AggregatorInterfaceV6.OrderType.MARKET_CLOSE
        );

        emit MarketOrderInitiated(orderId, sender, pairIndex, false);
    }

    // Manage limit order (OPEN)
    function updateOpenLimitOrder(
        uint256 pairIndex,
        uint256 index,
        uint256 price, // PRECISION
        uint256 tp,
        uint256 sl
    ) external notContract notDone {
        address sender = _msgSender();

        require(
            storageT.hasOpenLimitOrder(sender, pairIndex, index),
            "NO_LIMIT"
        );

        StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(
            sender,
            pairIndex,
            index
        );

        require(
            block.number - o.block >= limitOrdersTimelock,
            "LIMIT_TIMELOCK"
        );

        require(tp == 0 || (o.buy ? tp > price : tp < price), "WRONG_TP");

        require(sl == 0 || (o.buy ? sl < price : sl > price), "WRONG_SL");

        o.minPrice = price;
        o.maxPrice = price;

        o.tp = tp;
        o.sl = sl;

        storageT.updateOpenLimitOrder(o);

        emit OpenLimitUpdated(sender, pairIndex, index, price, tp, sl);
    }

    function cancelOpenLimitOrder(uint256 pairIndex, uint256 index)
        external
        notContract
        notDone
    {
        address sender = _msgSender();

        require(
            storageT.hasOpenLimitOrder(sender, pairIndex, index),
            "NO_LIMIT"
        );

        StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(
            sender,
            pairIndex,
            index
        );

        require(
            block.number - o.block >= limitOrdersTimelock,
            "LIMIT_TIMELOCK"
        );

        storageT.unregisterOpenLimitOrder(sender, pairIndex, index);
        storageT.transferDai(address(storageT), sender, o.positionSize);

        emit OpenLimitCanceled(sender, pairIndex, index);
    }

    // Manage limit order (TP/SL)
    function updateTp(
        uint256 pairIndex,
        uint256 index,
        uint256 newTp
    ) external notContract notDone {
        address sender = _msgSender();

        StorageInterfaceV5.Trade memory t = storageT.openTrades(
            sender,
            pairIndex,
            index
        );

        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(
            sender,
            pairIndex,
            index
        );

        require(t.leverage > 0, "NO_TRADE");
        require(
            block.number - i.tpLastUpdated >= limitOrdersTimelock,
            "LIMIT_TIMELOCK"
        );

        storageT.updateTp(sender, pairIndex, index, newTp);

        emit TpUpdated(sender, pairIndex, index, newTp);
    }

    function updateSl(
        uint256 pairIndex,
        uint256 index,
        uint256 newSl
    ) external notContract notDone {
        address sender = _msgSender();

        StorageInterfaceV5.Trade memory t = storageT.openTrades(
            sender,
            pairIndex,
            index
        );

        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(
            sender,
            pairIndex,
            index
        );

        require(t.leverage > 0, "NO_TRADE");

        uint256 maxSlDist = (t.openPrice * MAX_SL_P) / 100 / t.leverage;

        require(
            newSl == 0 ||
                (
                    t.buy
                        ? newSl >= t.openPrice - maxSlDist
                        : newSl <= t.openPrice + maxSlDist
                ),
            "SL_TOO_BIG"
        );

        require(
            block.number - i.slLastUpdated >= limitOrdersTimelock,
            "LIMIT_TIMELOCK"
        );

        AggregatorInterfaceV6 aggregator = storageT.priceAggregator();

        if (
            newSl == 0 ||
            !aggregator.pairsStorage().guaranteedSlEnabled(pairIndex)
        ) {
            storageT.updateSl(sender, pairIndex, index, newSl);

            emit SlUpdated(sender, pairIndex, index, newSl);
        } else {
            uint256 orderId = aggregator.getPrice(
                pairIndex,
                AggregatorInterfaceV6.OrderType.UPDATE_SL,
                (t.initialPosToken * i.tokenPriceDai * t.leverage) / PRECISION
            );

            aggregator.storePendingSlOrder(
                orderId,
                AggregatorInterfaceV6.PendingSl(
                    sender,
                    pairIndex,
                    index,
                    t.openPrice,
                    t.buy,
                    newSl
                )
            );
            aggregator.emptyNodeFulFill(
                pairIndex,
                orderId,
                AggregatorInterfaceV6.OrderType.UPDATE_SL
            );

            emit SlUpdateInitiated(orderId, sender, pairIndex, index, newSl);
        }
    }

    // Execute Order B yGPT3-Bot
    function executeOrderByGPT3Bot(
        StorageInterfaceV5.LimitOrder orderType,
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 nftId,
        uint256 nftType
    ) external notContract notDone checkWhitelist {
        address sender = _msgSender();

        require(nftType >= 1 && nftType <= 5, "WRONG_NFT_TYPE");
        require(storageT.nfts(nftType - 1).ownerOf(nftId) == sender, "NO_NFT");

        require(
            block.number >=
                storageT.nftLastSuccess(nftId) + storageT.nftSuccessTimelock(),
            "SUCCESS_TIMELOCK"
        );

        StorageInterfaceV5.Trade memory t;

        if (orderType == StorageInterfaceV5.LimitOrder.OPEN) {
            require(
                storageT.hasOpenLimitOrder(trader, pairIndex, index),
                "NO_LIMIT"
            );
        } else {
            t = storageT.openTrades(trader, pairIndex, index);

            require(t.leverage > 0, "NO_TRADE");

            if (orderType == StorageInterfaceV5.LimitOrder.LIQ) {
                uint256 liqPrice = getTradeLiquidationPrice(t);

                require(
                    t.sl == 0 || (t.buy ? liqPrice > t.sl : liqPrice < t.sl),
                    "HAS_SL"
                );
            } else {
                require(
                    orderType != StorageInterfaceV5.LimitOrder.SL || t.sl > 0,
                    "NO_SL"
                );
                require(
                    orderType != StorageInterfaceV5.LimitOrder.TP || t.tp > 0,
                    "NO_TP"
                );
            }
        }

        NftRewardsInterfaceV6.TriggeredLimitId
            memory triggeredLimitId = NftRewardsInterfaceV6.TriggeredLimitId(
                trader,
                pairIndex,
                index,
                orderType
            );

        if (
            !nftRewards.triggered(triggeredLimitId) ||
            nftRewards.timedOut(triggeredLimitId)
        ) {
            uint256 leveragedPosDai;

            if (orderType == StorageInterfaceV5.LimitOrder.OPEN) {
                StorageInterfaceV5.OpenLimitOrder memory l = storageT
                    .getOpenLimitOrder(trader, pairIndex, index);

                leveragedPosDai = l.positionSize * l.leverage;

                (uint256 priceImpactP, ) = pairInfos.getTradePriceImpact(
                    0,
                    l.pairIndex,
                    l.buy,
                    leveragedPosDai
                );

                require(
                    priceImpactP * l.leverage <=
                        pairInfos.maxNegativePnlOnOpenP(),
                    "PRICE_IMPACT_TOO_HIGH"
                );
            } else {
                leveragedPosDai =
                    (t.initialPosToken *
                        storageT
                            .openTradesInfo(trader, pairIndex, index)
                            .tokenPriceDai *
                        t.leverage) /
                    PRECISION;
            }

            storageT.transferLinkToAggregator(
                sender,
                pairIndex,
                leveragedPosDai
            );

            uint256 orderId = storageT.priceAggregator().getPrice(
                pairIndex,
                orderType == StorageInterfaceV5.LimitOrder.OPEN
                    ? AggregatorInterfaceV6.OrderType.LIMIT_OPEN
                    : AggregatorInterfaceV6.OrderType.LIMIT_CLOSE,
                leveragedPosDai
            );

            storageT.storePendingNftOrder(
                StorageInterfaceV5.PendingNftOrder(
                    sender,
                    nftId,
                    trader,
                    pairIndex,
                    index,
                    orderType
                ),
                orderId
            );

            storageT.priceAggregator().emptyNodeFulFill(
                pairIndex,
                orderId,
                orderType == StorageInterfaceV5.LimitOrder.OPEN
                    ? AggregatorInterfaceV6.OrderType.LIMIT_OPEN
                    : AggregatorInterfaceV6.OrderType.LIMIT_CLOSE
            );

            nftRewards.storeFirstToTrigger(triggeredLimitId, sender);

            emit NftOrderInitiated(orderId, sender, trader, pairIndex);
        } else {
            nftRewards.storeTriggerSameBlock(triggeredLimitId, sender);

            emit NftOrderSameBlock(sender, trader, pairIndex);
        }
    }

    // Avoid stack too deep error in executeOrderByGPT3Bot
    function getTradeLiquidationPrice(StorageInterfaceV5.Trade memory t)
        private
        view
        returns (uint256)
    {
        return
            pairInfos.getTradeLiquidationPrice(
                t.trader,
                t.pairIndex,
                t.index,
                t.openPrice,
                t.buy,
                (t.initialPosToken *
                    storageT
                        .openTradesInfo(t.trader, t.pairIndex, t.index)
                        .tokenPriceDai) / PRECISION,
                t.leverage
            );
    }

    // Market timeout
    function openTradeMarketTimeout(uint256 _order)
        external
        notContract
        notDone
    {
        address sender = _msgSender();

        StorageInterfaceV5.PendingMarketOrder memory o = storageT
            .reqID_pendingMarketOrder(_order);

        StorageInterfaceV5.Trade memory t = o.trade;

        require(
            o.block > 0 && block.number >= o.block + marketOrdersTimeout,
            "WAIT_TIMEOUT"
        );

        require(t.trader == sender, "NOT_YOUR_ORDER");
        require(t.leverage > 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, true);
        storageT.transferDai(address(storageT), sender, t.positionSizeDai);

        emit ChainlinkCallbackTimeout(_order, o);
    }

    function closeTradeMarketTimeout(uint256 _order)
        external
        notContract
        notDone
    {
        address sender = _msgSender();

        StorageInterfaceV5.PendingMarketOrder memory o = storageT
            .reqID_pendingMarketOrder(_order);

        StorageInterfaceV5.Trade memory t = o.trade;

        require(
            o.block > 0 && block.number >= o.block + marketOrdersTimeout,
            "WAIT_TIMEOUT"
        );

        require(t.trader == sender, "NOT_YOUR_ORDER");
        require(t.leverage == 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, false);

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSignature(
                "closeTradeMarket(uint256,uint256)",
                t.pairIndex,
                t.index
            )
        );

        if (!success) {
            emit CouldNotCloseTrade(sender, t.pairIndex, t.index);
        }

        emit ChainlinkCallbackTimeout(_order, o);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

abstract contract Delegatable {
    mapping (address => address) public delegations;
    address private senderOverride;

    function setDelegate(address delegate) external {
        require(tx.origin == msg.sender, "NO_CONTRACT");

        delegations[msg.sender] = delegate;
    }

    function removeDelegate() external {
        delegations[msg.sender] = address(0);
    }

    function delegatedAction(address trader, bytes calldata call_data) external returns (bytes memory) {
        require(delegations[trader] == msg.sender, "DELEGATE_NOT_APPROVED");

        senderOverride = trader;
        (bool success, bytes memory result) = address(this).delegatecall(call_data);
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577 (return the original revert reason)
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        senderOverride = address(0);

        return result;
    }


    function _msgSender() public view returns (address) {
        if (senderOverride == address(0)) {
            return msg.sender;
        } else {
            return senderOverride;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "./NftRewardsInterfaceV6.sol";
import "./PairsStorageInterfaceV6.sol";

interface AggregatorInterfaceV6 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL
    }

    function pairsStorage() external view returns (PairsStorageInterfaceV6);

    function nftRewards() external view returns (NftRewardsInterfaceV6);

    function getPrice(
        uint256,
        OrderType,
        uint256
    ) external returns (uint256);

    function tokenPriceDai() external view returns (uint256);

    function linkFee(uint256, uint256) external view returns (uint256);

    function tokenDaiReservesLp() external view returns (uint256, uint256);

    function pendingSlOrders(uint256) external view returns (PendingSl memory);

    function storePendingSlOrder(uint256 orderId, PendingSl calldata p)
        external;

    function unregisterPendingSlOrder(uint256 orderId) external;

    function emptyNodeFulFill(
        uint256,
        uint256,
        OrderType
    ) external;

    struct PendingSl {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 openPrice;
        bool buy;
        uint256 newSl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IWhitelist {
    function isWhitelists(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface MMTPairInfosInterfaceV6 {
    function maxNegativePnlOnOpenP() external view returns (uint256); // PRECISION (%)

    function storeTradeInitialAccFees(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long
    ) external;

    function getTradePriceImpact(
        uint256 openPrice, // PRECISION
        uint256 pairIndex,
        bool long,
        uint256 openInterest // 1e18 (DAI)
    )
        external
        view
        returns (
            uint256 priceImpactP, // PRECISION (%)
            uint256 priceAfterImpact // PRECISION
        );

    function getTradeLiquidationPrice(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 openPrice, // PRECISION
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage
    ) external view returns (uint256); // PRECISION

    function getTradeValue(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage,
        int256 percentProfit, // PRECISION (%)
        uint256 closingFee // 1e18 (DAI)
    ) external returns (uint256); // 1e18 (DAI)
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface MMTReferralsInterfaceV6_2 {
    function registerPotentialReferrer(address trader, address referral)
        external;

    function distributePotentialReward(
        address trader,
        uint256 volumeDai,
        uint256 pairOpenFeeP,
        uint256 tokenPriceDai
    ) external returns (uint256);

    function getPercentOfOpenFeeP(address trader)
        external
        view
        returns (uint256);

    function getTraderReferrer(address trader)
        external
        view
        returns (address referrer);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface NftInterfaceV5{
    function balanceOf(address) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function tokenOfOwnerByIndex(address, uint) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import './StorageInterfaceV5.sol';

interface NftRewardsInterfaceV6{
    struct TriggeredLimitId{ address trader; uint pairIndex; uint index; StorageInterfaceV5.LimitOrder order; }
    enum OpenLimitOrderType{ LEGACY, REVERSAL, MOMENTUM }
    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;
    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;
    function unregisterTrigger(TriggeredLimitId calldata) external;
    function distributeNftReward(TriggeredLimitId calldata, uint) external;
    function openLimitOrderTypes(address, uint, uint) external view returns(OpenLimitOrderType);
    function setOpenLimitOrderType(address, uint, uint, OpenLimitOrderType) external;
    function triggered(TriggeredLimitId calldata) external view returns(bool);
    function timedOut(TriggeredLimitId calldata) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface PairsStorageInterfaceV6 {
    //thangtest only testnet UNDEFINED
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE,
        UNDEFINED
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint256 maxDeviationP;
    } // PRECISION (%)

    function incrementCurrentOrderId() external returns (uint256);

    function updateGroupCollateral(
        uint256,
        uint256,
        bool,
        bool
    ) external;

    function pairJob(uint256)
        external
        returns (
            string memory,
            string memory,
            bytes32,
            uint256
        );

    function pairFeed(uint256) external view returns (Feed memory);

    function pairSpreadP(uint256) external view returns (uint256);

    function pairMinLeverage(uint256) external view returns (uint256);

    function pairMaxLeverage(uint256) external view returns (uint256);

    function groupMaxCollateral(uint256) external view returns (uint256);

    function groupCollateral(uint256, bool) external view returns (uint256);

    function guaranteedSlEnabled(uint256) external view returns (bool);

    function pairOpenFeeP(uint256) external view returns (uint256);

    function pairCloseFeeP(uint256) external view returns (uint256);

    function pairOracleFeeP(uint256) external view returns (uint256);

    function pairNftLimitOrderFeeP(uint256) external view returns (uint256);

    function pairReferralFeeP(uint256) external view returns (uint256);

    function pairMinLevPosDai(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./UniswapRouterInterfaceV5.sol";
import "./TokenInterfaceV5.sol";
import "./NftInterfaceV5.sol";
import "./VaultInterfaceV5.sol";
import "./PairsStorageInterfaceV6.sol";
import "./AggregatorInterfaceV6.sol";

interface StorageInterfaceV5 {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trader {
        uint256 leverageUnlocked;
        address referral;
        uint256 referralRewardsTotal; // 1e18
    }
    struct Trade {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 initialPosToken; // 1e18
        uint256 positionSizeDai; // 1e18
        uint256 openPrice; // PRECISION
        bool buy;
        uint256 leverage;
        uint256 tp; // PRECISION
        uint256 sl; // PRECISION
    }
    struct TradeInfo {
        uint256 tokenId;
        uint256 tokenPriceDai; // PRECISION
        uint256 openInterestDai; // 1e18
        uint256 tpLastUpdated;
        uint256 slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 positionSize; // 1e18 (DAI or GFARM2)
        uint256 spreadReductionP;
        bool buy;
        uint256 leverage;
        uint256 tp; // PRECISION (%)
        uint256 sl; // PRECISION (%)
        uint256 minPrice; // PRECISION
        uint256 maxPrice; // PRECISION
        uint256 block;
        uint256 tokenId; // index in supportedTokens
    }
    struct PendingMarketOrder {
        Trade trade;
        uint256 block;
        uint256 wantedPrice; // PRECISION
        uint256 slippageP; // PRECISION (%)
        uint256 spreadReductionP;
        uint256 tokenId; // index in supportedTokens
    }
    struct PendingNftOrder {
        address nftHolder;
        uint256 nftId;
        address trader;
        uint256 pairIndex;
        uint256 index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint256);

    function gov() external view returns (address);

    function dev() external view returns (address);

    function dai() external view returns (TokenInterfaceV5);

    function token() external view returns (TokenInterfaceV5);

    function linkErc677() external view returns (TokenInterfaceV5);

    function tokenDaiRouter() external view returns (UniswapRouterInterfaceV5);

    function priceAggregator() external view returns (AggregatorInterfaceV6);

    function vault() external view returns (VaultInterfaceV5);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(
        address,
        uint256,
        bool
    ) external;

    function transferDai(
        address,
        address,
        uint256
    ) external;

    function transferLinkToAggregator(
        address,
        uint256,
        uint256
    ) external;

    function unregisterTrade(
        address,
        uint256,
        uint256
    ) external;

    function unregisterPendingMarketOrder(uint256, bool) external;

    function unregisterOpenLimitOrder(
        address,
        uint256,
        uint256
    ) external;

    function hasOpenLimitOrder(
        address,
        uint256,
        uint256
    ) external view returns (bool);

    function storePendingMarketOrder(
        PendingMarketOrder memory,
        uint256,
        bool
    ) external;

    function storeReferral(address, address) external;

    function openTrades(
        address,
        uint256,
        uint256
    ) external view returns (Trade memory);

    function openTradesInfo(
        address,
        uint256,
        uint256
    ) external view returns (TradeInfo memory);

    function updateSl(
        address,
        uint256,
        uint256,
        uint256
    ) external;

    function updateTp(
        address,
        uint256,
        uint256,
        uint256
    ) external;

    function getOpenLimitOrder(
        address,
        uint256,
        uint256
    ) external view returns (OpenLimitOrder memory);

    function spreadReductionsP(uint256) external view returns (uint256);

    function positionSizeTokenDynamic(uint256, uint256)
        external
        view
        returns (uint256);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(uint256)
        external
        view
        returns (PendingMarketOrder memory);

    function storePendingNftOrder(PendingNftOrder memory, uint256) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint256)
        external
        view
        returns (uint256);

    function firstEmptyOpenLimitIndex(address, uint256)
        external
        view
        returns (uint256);

    function increaseNftRewards(uint256, uint256) external;

    function nftSuccessTimelock() external view returns (uint256);

    function currentPercentProfit(
        uint256,
        uint256,
        bool,
        uint256
    ) external view returns (int256);

    function reqID_pendingNftOrder(uint256)
        external
        view
        returns (PendingNftOrder memory);

    function setNftLastSuccess(uint256) external;

    function updateTrade(Trade memory) external;

    function nftLastSuccess(uint256) external view returns (uint256);

    function unregisterPendingNftOrder(uint256) external;

    function handleDevGovFees(
        uint256,
        uint256,
        bool,
        bool
    ) external returns (uint256);

    function distributeLpRewards(uint256) external;

    function getReferral(address) external view returns (address);

    function increaseReferralRewards(address, uint256) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function setLeverageUnlocked(address, uint256) external;

    function getLeverageUnlocked(address) external view returns (uint256);

    function openLimitOrdersCount(address, uint256)
        external
        view
        returns (uint256);

    function maxOpenLimitOrdersPerPair() external view returns (uint256);

    function openTradesCount(address, uint256) external view returns (uint256);

    function pendingMarketOpenCount(address, uint256)
        external
        view
        returns (uint256);

    function pendingMarketCloseCount(address, uint256)
        external
        view
        returns (uint256);

    function maxTradesPerPair() external view returns (uint256);

    function tradesPerBlock(uint256) external view returns (uint256);

    function pendingOrderIdsCount(address) external view returns (uint256);

    function maxPendingMarketOrders() external view returns (uint256);

    function openInterestDai(uint256, uint256) external view returns (uint256);

    function getPendingOrderIds(address)
        external
        view
        returns (uint256[] memory);

    function traders(address) external view returns (Trader memory);

    function nfts(uint256) external view returns (NftInterfaceV5);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface TokenInterfaceV5{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface UniswapRouterInterfaceV5{
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface VaultInterfaceV5{
	function sendDaiToTrader(address, uint) external;
	function receiveDaiFromTrader(address, uint, uint) external;
	function currentBalanceDai() external view returns(uint);
	function distributeRewardDai(uint) external;
	function distributeReward(uint assets) external;
	function sendAssets(uint assets, address receiver) external;
	function receiveAssets(uint assets, address user) external;
}