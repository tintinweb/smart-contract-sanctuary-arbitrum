// SPDX-License-Identifier: MIT
import './interfaces/StorageInterfaceV5.sol';
pragma solidity 0.8.11;

contract GNSTradingCallbacksV6{

    // Contracts (constant)
    StorageInterfaceV5 constant storageT = StorageInterfaceV5(0xaee4d11a16B2bc65EDD6416Fb626EB404a6D65BD);

    // Params (constant)
    uint constant PRECISION = 1e10;     // 10 decimals

    uint constant LIQ_THRESHOLD_P = 90; // -90% PNL
    uint constant MAX_SL_P = 75;        // -75% PNL
    uint constant MAX_GAIN_P = 900;     // 900% PnL (10x)

    // Params (adjustable)
    uint public vaultFeeP = 10;         // %

    // State
    bool public isPaused;               // Prevent opening new trades
    bool public isDone;                 // Prevent any interaction with the contract

    // Custom data types
    struct AggregatorAnswer{ uint orderId; uint price; uint spreadP; }
    struct Values{ uint price; int profitP; uint tokenPriceDai; uint posToken; uint posDai; uint nftReward; }

    // Events
    event MarketExecuted(
        uint orderId,
        StorageInterfaceV5.Trade t,
        bool open,
        uint price,
        uint positionSizeDai,
        int percentProfit
    );
    event LimitExecuted(
        uint orderId,
        uint limitIndex,
        StorageInterfaceV5.Trade t,
        address nftHolder,
        StorageInterfaceV5.LimitOrder orderType,
        uint price,
        uint positionSizeDai,
        int percentProfit
    );

    event MarketOpenCanceled(uint orderId, address trader, uint pairIndex);
    event MarketCloseCanceled(uint orderId, address trader, uint pairIndex, uint index);

    event SlUpdated(uint orderId, address trader, uint pairIndex, uint index, uint newSl);
    event SlCanceled(uint orderId, address trader, uint pairIndex, uint index);

    event AddressUpdated(string name, address a);
    event NumberUpdated(string name, uint value);
    
    event Pause(bool paused);
    event Done(bool done);

    constructor() { }

    // Modifiers
    modifier onlyGov(){ require(msg.sender == storageT.gov(), "GOV_ONLY"); _; }
    modifier onlyPriceAggregator(){ require(msg.sender == address(storageT.priceAggregator()), "AGGREGATOR_ONLY"); _; }
    modifier notDone(){ require(!isDone, "DONE"); _; }

    // Manage params
    function setVaultFeeP(uint _vaultFeeP) external onlyGov{
        require(_vaultFeeP <= 50, "ABOVE_50");
        vaultFeeP = _vaultFeeP;
        emit NumberUpdated("vaultFeeP", _vaultFeeP);
    }

    // Manage state
    function pause() external onlyGov{ isPaused = !isPaused; emit Pause(isPaused); }
    function done() external onlyGov{ isDone = !isDone; emit Done(isDone); }

    // Callbacks
    function openTradeMarketCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone{

        StorageInterfaceV5.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(a.orderId);
        if(o.block == 0){ return; }
        
        StorageInterfaceV5.Trade memory t = o.trade;
        t.openPrice = marketExecutionPrice(a.price, a.spreadP, o.spreadReductionP, t.buy);

        uint maxSlippage = o.wantedPrice * o.slippageP / 100 / PRECISION;

        if(isPaused || a.price == 0
        || (t.buy ? t.openPrice > o.wantedPrice + maxSlippage : t.openPrice < o.wantedPrice - maxSlippage)
        || (t.tp > 0 && (t.buy ? t.openPrice >= t.tp : t.openPrice <= t.tp))
        || (t.sl > 0 && (t.buy ? t.openPrice <= t.sl : t.openPrice >= t.sl))
        || !withinExposureLimits(t.pairIndex, t.buy, t.positionSizeDai, t.leverage)){

            storageT.transferDai(
                address(storageT), 
                t.trader, 
                t.positionSizeDai - storageT.handleDevGovFees(
                    t.pairIndex, 
                    t.positionSizeDai * t.leverage, 
                    true, 
                    true
                )
            );

            emit MarketOpenCanceled(a.orderId, t.trader, t.pairIndex);

        }else{
            (StorageInterfaceV5.Trade memory finalTrade, uint tokenPriceDai) = registerTrade(t, 1500, 0);

            emit MarketExecuted(
                a.orderId,
                finalTrade,
                true,
                finalTrade.openPrice,
                finalTrade.initialPosToken * tokenPriceDai / PRECISION,
                0
            );
        }

        storageT.unregisterPendingMarketOrder(a.orderId, true);
    }
    function closeTradeMarketCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone{
        
        StorageInterfaceV5.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(a.orderId);
        if(o.block == 0){ return; }

        StorageInterfaceV5.Trade memory t = storageT.openTrades(o.trade.trader, o.trade.pairIndex, o.trade.index);

        if(t.leverage > 0){

            StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(t.trader, t.pairIndex, t.index);
            AggregatorInterfaceV6 aggregator = storageT.priceAggregator();
            
            uint tokenPriceDai = aggregator.tokenPriceDai();
            uint levPosToken = t.initialPosToken * i.tokenPriceDai * t.leverage / tokenPriceDai;

            if(a.price == 0){
               
                uint feeToken = storageT.handleDevGovFees(t.pairIndex, levPosToken, false, true);

                if(t.initialPosToken > feeToken){
                    t.initialPosToken -= feeToken;
                    storageT.updateTrade(t);
                }else{
                    unregisterTrade(t, -100, 0, i.openInterestDai/t.leverage, 0, 0, 0);
                }

                emit MarketCloseCanceled(a.orderId, t.trader, t.pairIndex, t.index);

            }else{
                Values memory v;
                v.profitP = currentPercentProfit(t.openPrice, a.price, t.buy, t.leverage);
                v.posDai = t.initialPosToken * i.tokenPriceDai / PRECISION;

                unregisterTrade(
                    t,
                    v.profitP,
                    v.posDai,
                    i.openInterestDai/t.leverage,
                    0,
                    levPosToken * aggregator.pairsStorage().pairCloseFeeP(t.pairIndex) / 100 / PRECISION,
                    tokenPriceDai
                );

                emit MarketExecuted(a.orderId, t, false, a.price, v.posDai, v.profitP);
            }
        }

        storageT.unregisterPendingMarketOrder(a.orderId, false);
    }
    function executeNftOpenOrderCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone{

        StorageInterfaceV5.PendingNftOrder memory n = storageT.reqID_pendingNftOrder(a.orderId);
        NftRewardsInterfaceV6 nftIncentives = storageT.priceAggregator().nftRewards();

        if(!isPaused && a.price != 0
        && storageT.hasOpenLimitOrder(n.trader, n.pairIndex, n.index)
        && block.number >= storageT.nftLastSuccess(n.nftId) + storageT.nftSuccessTimelock()){

            StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(n.trader, n.pairIndex, n.index);
            NftRewardsInterfaceV6.OpenLimitOrderType t = nftIncentives.openLimitOrderTypes(n.trader, n.pairIndex, n.index);

            a.price = marketExecutionPrice(a.price, a.spreadP, o.spreadReductionP, o.buy);

            if((t == NftRewardsInterfaceV6.OpenLimitOrderType.LEGACY ? (a.price >= o.minPrice && a.price <= o.maxPrice) :
                t == NftRewardsInterfaceV6.OpenLimitOrderType.REVERSAL ? (o.buy ? a.price <= o.maxPrice : a.price >= o.minPrice) :
                (o.buy ? a.price >= o.minPrice : a.price <= o.maxPrice))
            && withinExposureLimits(o.pairIndex, o.buy, o.positionSize, o.leverage)){

                (StorageInterfaceV5.Trade memory finalTrade, uint tokenPriceDai) = registerTrade(
                    StorageInterfaceV5.Trade(
                        o.trader,
                        o.pairIndex,
                        0, 0,
                        o.positionSize,
                        t == NftRewardsInterfaceV6.OpenLimitOrderType.REVERSAL ? o.buy ? o.maxPrice : o.minPrice : a.price,
                        o.buy,
                        o.leverage,
                        o.tp,
                        o.sl
                    ), 
                    n.nftId,
                    n.index
                );

                storageT.unregisterOpenLimitOrder(o.trader, o.pairIndex, o.index);

                emit LimitExecuted(
                    a.orderId,
                    n.index,
                    finalTrade,
                    n.nftHolder,
                    StorageInterfaceV5.LimitOrder.OPEN,
                    finalTrade.openPrice,
                    finalTrade.initialPosToken * tokenPriceDai / PRECISION,
                    0
                );
            }
        }

        nftIncentives.unregisterTrigger(NftRewardsInterfaceV6.TriggeredLimitId(n.trader, n.pairIndex, n.index, n.orderType));
        storageT.unregisterPendingNftOrder(a.orderId);
    }
    function executeNftCloseOrderCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone{
        
        StorageInterfaceV5.PendingNftOrder memory o = storageT.reqID_pendingNftOrder(a.orderId);
        StorageInterfaceV5.Trade memory t = storageT.openTrades(o.trader, o.pairIndex, o.index);

        AggregatorInterfaceV6 aggregator = storageT.priceAggregator();
        NftRewardsInterfaceV6 nftIncentives = aggregator.nftRewards();

        if(a.price != 0
        && t.leverage > 0 && block.number >= storageT.nftLastSuccess(o.nftId) + storageT.nftSuccessTimelock()){

            StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(t.trader, t.pairIndex, t.index);
            PairsStorageInterfaceV6 pairsStored = aggregator.pairsStorage();
            Values memory v;

            v.price = pairsStored.guaranteedSlEnabled(t.pairIndex) ?
                        o.orderType == StorageInterfaceV5.LimitOrder.TP ? t.tp : 
                        o.orderType == StorageInterfaceV5.LimitOrder.SL ? t.sl : a.price : a.price;

            v.profitP = currentPercentProfit(t.openPrice, v.price, t.buy, t.leverage);

            v.tokenPriceDai = aggregator.tokenPriceDai();
            v.posToken = t.initialPosToken * i.tokenPriceDai / v.tokenPriceDai;
            v.posDai = t.initialPosToken * i.tokenPriceDai / PRECISION;

            v.nftReward = 
                (o.orderType == StorageInterfaceV5.LimitOrder.TP && t.tp > 0 && (t.buy ? a.price >= t.tp : a.price <= t.tp))
             || (o.orderType == StorageInterfaceV5.LimitOrder.SL && t.sl > 0 && (t.buy ? a.price <= t.sl : a.price >= t.sl)) ? 
                    v.posToken * t.leverage * pairsStored.pairNftLimitOrderFeeP(t.pairIndex) / 100 / PRECISION : 
                o.orderType == StorageInterfaceV5.LimitOrder.LIQ && v.profitP <= int(LIQ_THRESHOLD_P*PRECISION) * (-1) ? 
                    v.posToken / 20 : 0;

            if(v.nftReward > 0){

                unregisterTrade(
                    t,
                    v.profitP,
                    v.posDai,
                    i.openInterestDai/t.leverage,
                    v.nftReward,
                    o.orderType == StorageInterfaceV5.LimitOrder.LIQ ? 
                        v.nftReward :
                        v.posToken * t.leverage * pairsStored.pairCloseFeeP(t.pairIndex) / 100 / PRECISION,
                    v.tokenPriceDai
                );

                nftIncentives.distributeNftReward(
                    NftRewardsInterfaceV6.TriggeredLimitId(o.trader, o.pairIndex, o.index, o.orderType),
                    v.nftReward
                );

                storageT.increaseNftRewards(o.nftId, v.nftReward);

                emit LimitExecuted(a.orderId, o.index, t, o.nftHolder, o.orderType, v.price, v.posDai, v.profitP);
            }
        }

        nftIncentives.unregisterTrigger(NftRewardsInterfaceV6.TriggeredLimitId(o.trader, o.pairIndex, o.index, o.orderType));
        storageT.unregisterPendingNftOrder(a.orderId);
    }
    function updateSlCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone{
        
        AggregatorInterfaceV6 aggregator = storageT.priceAggregator();
        AggregatorInterfaceV6.PendingSl memory o = aggregator.pendingSlOrders(a.orderId);
        
        StorageInterfaceV5.Trade memory t = storageT.openTrades(o.trader, o.pairIndex, o.index);

        if(a.price != 0 && t.leverage > 0 
        && t.buy == o.buy && t.openPrice == o.openPrice
        && (t.buy ? o.newSl <= a.price : o.newSl >= a.price)){

            storageT.updateSl(o.trader, o.pairIndex, o.index, o.newSl);
            emit SlUpdated(a.orderId, o.trader, o.pairIndex, o.index, o.newSl);
            
        }else{
            emit SlCanceled(a.orderId, o.trader, o.pairIndex, o.index);
        }

        aggregator.unregisterPendingSlOrder(a.orderId);
    }

    // Shared code between market & limit callbacks
    function registerTrade(
        StorageInterfaceV5.Trade memory _trade, 
        uint _nftId, 
        uint _limitIndex
    ) private returns(StorageInterfaceV5.Trade memory, uint){

        AggregatorInterfaceV6 aggregator = storageT.priceAggregator();
        PairsStorageInterfaceV6 pairsStored = aggregator.pairsStorage();

        _trade.positionSizeDai -= storageT.handleDevGovFees(_trade.pairIndex, _trade.positionSizeDai * _trade.leverage, true, true);

        storageT.vault().receiveDaiFromTrader(_trade.trader, _trade.positionSizeDai, 0);

        uint tokenPriceDai = aggregator.tokenPriceDai();
        _trade.initialPosToken = _trade.positionSizeDai * PRECISION / tokenPriceDai;
        _trade.positionSizeDai = 0;

        {
            uint rTokens = _trade.initialPosToken * _trade.leverage * pairsStored.pairReferralFeeP(_trade.pairIndex) / 100 / PRECISION;
            address referral = storageT.getReferral(_trade.trader);

            if(referral != address(0)){ 
                rTokens /= 2;
                storageT.handleTokens(referral, rTokens, true);
                storageT.increaseReferralRewards(referral, rTokens);
            }

            _trade.initialPosToken -= rTokens;
        }

        if(_nftId < 1500){
            uint nTokens = _trade.initialPosToken * _trade.leverage * pairsStored.pairNftLimitOrderFeeP(_trade.pairIndex) / 100 / PRECISION;
            _trade.initialPosToken -= nTokens;
            
            aggregator.nftRewards().distributeNftReward(
                NftRewardsInterfaceV6.TriggeredLimitId(
                    _trade.trader, _trade.pairIndex, _limitIndex, StorageInterfaceV5.LimitOrder.OPEN
                ), nTokens
            );

            storageT.increaseNftRewards(_nftId, nTokens);
        }

        _trade.index = storageT.firstEmptyTradeIndex(_trade.trader, _trade.pairIndex);
        _trade.tp = correctTp(_trade.openPrice, _trade.leverage, _trade.tp, _trade.buy);
        _trade.sl = correctSl(_trade.openPrice, _trade.leverage, _trade.sl, _trade.buy);

        pairsStored.updateGroupCollateral(_trade.pairIndex, _trade.initialPosToken * tokenPriceDai / PRECISION, _trade.buy, true);

        storageT.storeTrade(
            _trade,
            StorageInterfaceV5.TradeInfo(
                0, 
                tokenPriceDai, 
                _trade.initialPosToken * _trade.leverage * tokenPriceDai / PRECISION,
                0,
                0,
                false
            )
        );

        return (_trade, tokenPriceDai);
    }
    function unregisterTrade(
        StorageInterfaceV5.Trade memory _trade,
        int _percentProfit,             // PRECISION
        uint _currentDaiPos,            // 1e18
        uint _initialDaiPos,            // 1e18
        uint _amountNftToken,           // 1e18
        uint _lpFeeToken,               // 1e18
        uint _tokenPriceDai             // PRECISION
    ) private{

        VaultInterfaceV5 vault = storageT.vault();

        storageT.distributeLpRewards(_lpFeeToken * (100 - vaultFeeP) / 100);
        vault.distributeRewardDai(_lpFeeToken * vaultFeeP * _tokenPriceDai / 100 / PRECISION);

        if(_percentProfit > int(LIQ_THRESHOLD_P * PRECISION) * (-1)){
            vault.sendDaiToTrader(
                _trade.trader, 
                uint(
                    int(_currentDaiPos) + 
                    _percentProfit * int(_currentDaiPos) / 100 / int(PRECISION) - 
                    int((_lpFeeToken + _amountNftToken) * _tokenPriceDai / PRECISION))
                );
        }
        
        storageT.priceAggregator().pairsStorage().updateGroupCollateral(_trade.pairIndex, _initialDaiPos, _trade.buy, false);
        storageT.unregisterTrade(_trade.trader, _trade.pairIndex, _trade.index);
    }

    // Utils
    function withinExposureLimits(uint _pairIndex, bool _buy, uint _positionSizeDai, uint _leverage) private view returns(bool){
        PairsStorageInterfaceV6 pairsStored = storageT.priceAggregator().pairsStorage();
        return storageT.openInterestDai(_pairIndex, _buy ? 0 : 1) + _positionSizeDai * _leverage <= storageT.openInterestDai(_pairIndex, 2)
            && pairsStored.groupCollateral(_pairIndex, _buy) + _positionSizeDai <= pairsStored.groupMaxCollateral(_pairIndex);
    }
    function currentPercentProfit(uint openPrice, uint currentPrice, bool buy, uint leverage) private pure returns(int p){
        int diff = buy ? (int(currentPrice) - int(openPrice)) : (int(openPrice) - int(currentPrice));
        int minPnlP = int(PRECISION) * (-100);
        int maxPnlP = int(MAX_GAIN_P) * int(PRECISION);
        
        p = diff * 100 * int(PRECISION) * int(leverage) / int(openPrice);
        p = p < minPnlP ? minPnlP : p > maxPnlP ? maxPnlP : p;
    }
    function correctTp(uint openPrice, uint leverage, uint tp, bool buy) private pure returns(uint){
        if(tp == 0 || currentPercentProfit(openPrice, tp, buy, leverage) == int(MAX_GAIN_P) * int(PRECISION)){
            uint tpDiff = openPrice * MAX_GAIN_P / leverage / 100;
            return buy ? openPrice + tpDiff : tpDiff <= openPrice ? openPrice - tpDiff : 0;
        }
        return tp;
    }
    function correctSl(uint openPrice, uint leverage, uint sl, bool buy) private pure returns(uint){
        if(sl > 0 && currentPercentProfit(openPrice, sl, buy, leverage) < int(MAX_SL_P) * int(PRECISION) * (-1)){
            uint slDiff = openPrice * MAX_SL_P / leverage / 100;
            return buy ? openPrice - slDiff : openPrice + slDiff;
        }
        return sl;
    }
    function marketExecutionPrice(uint _price, uint _spreadP, uint _spreadReductionP, bool _long) private pure returns (uint){
        uint priceDiff = _price * (_spreadP - _spreadP * _spreadReductionP / 100) / 100 / PRECISION;
        return _long ? _price + priceDiff : _price - priceDiff;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface NftInterfaceV5{
    function balanceOf(address) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function tokenOfOwnerByIndex(address, uint) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface PairsStorageInterfaceV6{
    enum FeedCalculation { DEFAULT, INVERT, COMBINE }    // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed{ address feed1; address feed2; FeedCalculation feedCalculation; uint maxDeviationP; } // PRECISION (%)
    function incrementCurrentOrderId() external returns(uint);
    function updateGroupCollateral(uint, uint, bool, bool) external;
    function pairJob(uint) external returns(string memory, string memory, bytes32, uint);
    function pairFeed(uint) external view returns(Feed memory);
    function pairSpreadP(uint) external view returns(uint);
    function pairMinLeverage(uint) external view returns(uint);
    function pairMaxLeverage(uint) external view returns(uint);
    function groupMaxCollateral(uint) external view returns(uint);
    function groupCollateral(uint, bool) external view returns(uint);
    function guaranteedSlEnabled(uint) external view returns(bool);
    function pairOpenFeeP(uint) external view returns(uint);
    function pairCloseFeeP(uint) external view returns(uint);
    function pairOracleFeeP(uint) external view returns(uint);
    function pairNftLimitOrderFeeP(uint) external view returns(uint);
    function pairReferralFeeP(uint) external view returns(uint);
    function pairMinLevPosDai(uint) external view returns(uint);
}

// SPDX-License-Identifier: MIT
import './UniswapRouterInterfaceV5.sol';
import './TokenInterfaceV5.sol';
import './NftInterfaceV5.sol';
import './VaultInterfaceV5.sol';
import './PairsStorageInterfaceV6.sol';
pragma solidity 0.8.11;

interface StorageInterfaceV5{
    enum LimitOrder { TP, SL, LIQ, OPEN }
    struct Trader{
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal;  // 1e18
    }
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken;       // 1e18
        uint positionSizeDai;       // 1e18
        uint openPrice;             // PRECISION
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
    }
    struct TradeInfo{
        uint tokenId;
        uint tokenPriceDai;         // PRECISION
        uint openInterestDai;       // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder{
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize;          // 1e18 (DAI or GFARM2)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION (%)
        uint sl;                    // PRECISION (%)
        uint minPrice;              // PRECISION
        uint maxPrice;              // PRECISION
        uint block;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingMarketOrder{
        Trade trade;
        uint block;
        uint wantedPrice;           // PRECISION
        uint slippageP;             // PRECISION (%)
        uint spreadReductionP;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingNftOrder{
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }
    function PRECISION() external pure returns(uint);
    function gov() external view returns(address);
    function dev() external view returns(address);
    function dai() external view returns(TokenInterfaceV5);
    function token() external view returns(TokenInterfaceV5);
    function linkErc677() external view returns(TokenInterfaceV5);
    function tokenDaiRouter() external view returns(UniswapRouterInterfaceV5);
    function priceAggregator() external view returns(AggregatorInterfaceV6);
    function vault() external view returns(VaultInterfaceV5);
    function trading() external view returns(address);
    function callbacks() external view returns(address);
    function handleTokens(address,uint,bool) external;
    function transferDai(address, address, uint) external;
    function transferLinkToAggregator(address, uint, uint) external;
    function unregisterTrade(address, uint, uint) external;
    function unregisterPendingMarketOrder(uint, bool) external;
    function unregisterOpenLimitOrder(address, uint, uint) external;
    function hasOpenLimitOrder(address, uint, uint) external view returns(bool);
    function storePendingMarketOrder(PendingMarketOrder memory, uint, bool) external;
    function storeReferral(address, address) external;
    function openTrades(address, uint, uint) external view returns(Trade memory);
    function openTradesInfo(address, uint, uint) external view returns(TradeInfo memory);
    function updateSl(address, uint, uint, uint) external;
    function updateTp(address, uint, uint, uint) external;
    function getOpenLimitOrder(address, uint, uint) external view returns(OpenLimitOrder memory);
    function spreadReductionsP(uint) external view returns(uint);
    function positionSizeTokenDynamic(uint,uint) external view returns(uint);
    function maxSlP() external view returns(uint);
    function storeOpenLimitOrder(OpenLimitOrder memory) external;
    function reqID_pendingMarketOrder(uint) external view returns(PendingMarketOrder memory);
    function storePendingNftOrder(PendingNftOrder memory, uint) external;
    function updateOpenLimitOrder(OpenLimitOrder calldata) external;
    function firstEmptyTradeIndex(address, uint) external view returns(uint);
    function firstEmptyOpenLimitIndex(address, uint) external view returns(uint);
    function increaseNftRewards(uint, uint) external;
    function nftSuccessTimelock() external view returns(uint);
    function currentPercentProfit(uint,uint,bool,uint) external view returns(int);
    function reqID_pendingNftOrder(uint) external view returns(PendingNftOrder memory);
    function setNftLastSuccess(uint) external;
    function updateTrade(Trade memory) external;
    function nftLastSuccess(uint) external view returns(uint);
    function unregisterPendingNftOrder(uint) external;
    function handleDevGovFees(uint, uint, bool, bool) external returns(uint);
    function distributeLpRewards(uint) external;
    function getReferral(address) external view returns(address);
    function increaseReferralRewards(address, uint) external;
    function storeTrade(Trade memory, TradeInfo memory) external;
    function setLeverageUnlocked(address, uint) external;
    function getLeverageUnlocked(address) external view returns(uint);
    function openLimitOrdersCount(address, uint) external view returns(uint);
    function maxOpenLimitOrdersPerPair() external view returns(uint);
    function openTradesCount(address, uint) external view returns(uint);
    function pendingMarketOpenCount(address, uint) external view returns(uint);
    function pendingMarketCloseCount(address, uint) external view returns(uint);
    function maxTradesPerPair() external view returns(uint);
    function maxTradesPerBlock() external view returns(uint);
    function tradesPerBlock(uint) external view returns(uint);
    function pendingOrderIdsCount(address) external view returns(uint);
    function maxPendingMarketOrders() external view returns(uint);
    function maxGainP() external view returns(uint);
    function defaultLeverageUnlocked() external view returns(uint);
    function openInterestDai(uint, uint) external view returns(uint);
    function getPendingOrderIds(address) external view returns(uint[] memory);
    function traders(address) external view returns(Trader memory);
    function nfts(uint) external view returns(NftInterfaceV5);
}

interface AggregatorInterfaceV6{
    enum OrderType { MARKET_OPEN, MARKET_CLOSE, LIMIT_OPEN, LIMIT_CLOSE, UPDATE_SL }
    function pairsStorage() external view returns(PairsStorageInterfaceV6);
    function nftRewards() external view returns(NftRewardsInterfaceV6);
    function getPrice(uint,OrderType,uint) external returns(uint);
    function tokenPriceDai() external view returns(uint);
    function linkFee(uint,uint) external view returns(uint);
    function tokenDaiReservesLp() external view returns(uint, uint);
    function pendingSlOrders(uint) external view returns(PendingSl memory);
    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;
    function unregisterPendingSlOrder(uint orderId) external;
    struct PendingSl{address trader; uint pairIndex; uint index; uint openPrice; bool buy; uint newSl; }
}

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
pragma solidity 0.8.11;

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
pragma solidity 0.8.11;

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
pragma solidity 0.8.11;

interface VaultInterfaceV5{
	function sendDaiToTrader(address, uint) external;
	function receiveDaiFromTrader(address, uint, uint) external;
	function currentBalanceDai() external view returns(uint);
	function distributeRewardDai(uint) external;
}