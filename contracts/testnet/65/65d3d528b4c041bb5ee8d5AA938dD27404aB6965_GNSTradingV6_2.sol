// File: contracts\interfaces\UniswapRouterInterfaceV5.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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

// File: contracts\interfaces\TokenInterfaceV5.sol

pragma solidity 0.8.15;

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

// File: contracts\interfaces\NftInterfaceV5.sol

pragma solidity 0.8.15;

interface NftInterfaceV5{
    function balanceOf(address) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function tokenOfOwnerByIndex(address, uint) external view returns(uint);
}

// File: contracts\interfaces\VaultInterfaceV5.sol

pragma solidity 0.8.15;

interface VaultInterfaceV5{
	function sendDaiToTrader(address, uint) external;
	function receiveDaiFromTrader(address, uint, uint) external;
	function currentBalanceDai() external view returns(uint);
	function distributeRewardDai(uint) external;
}

// File: contracts\interfaces\PairsStorageInterfaceV6.sol

pragma solidity 0.8.15;

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

// File: contracts\interfaces\StorageInterfaceV5.sol

pragma solidity 0.8.15;

interface StorageInterfaceV5{
    enum LimitOrder { TP, SL, LIQ, OPEN }   //触发tp, sl, liq, 限价委托开仓执行；
    struct Trader{
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal;  // 1e18
    }
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken;       // 1e18 //初始仓位代币数量？为何目前是0？
        uint positionSizeDai;       // 1e18 //保证金数量；这个命名有误；
        uint openPrice;             // PRECISION    //签名之前开仓界面显示的，用户期望的开仓价格；
        bool buy;   //开空还是开多；
        uint leverage;  //杠杆倍数；
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
    }

    struct TradeInfo {
        uint tokenId;   //标的？
        uint tokenPriceDai;         // PRECISION    //标的价格usd?
        uint openInterestDai;       // 1e18
        uint tpLastUpdated; //？
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
    function priceAggregator() external view returns(AggregatorInterfaceV6_2);
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

interface AggregatorInterfaceV6_2{
    enum OrderType { MARKET_OPEN, MARKET_CLOSE, LIMIT_OPEN, LIMIT_CLOSE, UPDATE_SL }
    function pairsStorage() external view returns(PairsStorageInterfaceV6);
    function getPrice(uint,OrderType,uint) external returns(uint);
    function tokenPriceDai() external returns(uint);
    function linkFee(uint,uint) external view returns(uint);
    function tokenDaiReservesLp() external view returns(uint, uint);
    function pendingSlOrders(uint) external view returns(PendingSl memory);
    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;
    function unregisterPendingSlOrder(uint orderId) external;
    struct PendingSl{address trader; uint pairIndex; uint index; uint openPrice; bool buy; uint newSl; }
}

interface NftRewardsInterfaceV6{
    struct TriggeredLimitId{ address trader; uint pairIndex; uint index; StorageInterfaceV5.LimitOrder order; }
    enum OpenLimitOrderType{LEGACY, REVERSAL, MOMENTUM}   //遗产、逆转、势头；//0就是市价委托，其它是限价委托
    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;
    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;
    function unregisterTrigger(TriggeredLimitId calldata) external;
    function distributeNftReward(TriggeredLimitId calldata, uint) external;
    function openLimitOrderTypes(address, uint, uint) external view returns(OpenLimitOrderType);
    function setOpenLimitOrderType(address, uint, uint, OpenLimitOrderType) external;
    function triggered(TriggeredLimitId calldata) external view returns(bool);
    function timedOut(TriggeredLimitId calldata) external view returns(bool);
}

// File: contracts\interfaces\GNSPairInfosInterfaceV6.sol

pragma solidity 0.8.15;

interface GNSPairInfosInterfaceV6{
    function maxNegativePnlOnOpenP() external view returns(uint); // PRECISION (%)

    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external;

    function getTradePriceImpact(
        uint openPrice,   // PRECISION
        uint pairIndex,
        bool long,
        uint openInterest // 1e18 (DAI)
    ) external view returns(
        uint priceImpactP,      // PRECISION (%)
        uint priceAfterImpact   // PRECISION
    );

   function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice,  // PRECISION
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage
    ) external view returns(uint); // PRECISION

    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral,   // 1e18 (DAI)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee    // 1e18 (DAI)
    ) external returns(uint); // 1e18 (DAI)
}

// File: contracts\interfaces\GNSReferralsInterfaceV6_2.sol

pragma solidity 0.8.15;

interface GNSReferralsInterfaceV6_2{
    function registerPotentialReferrer(address trader, address referral) external;
   	function distributePotentialReward(
        address trader,
        uint volumeDai,
        uint pairOpenFeeP,
        uint tokenPriceDai
    ) external returns(uint);
    function getPercentOfOpenFeeP(address trader) external view returns(uint);
    function getTraderReferrer(address trader) external view returns(address referrer);
}

// File: contracts\Delegatable.sol

pragma solidity 0.8.15;

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

// File: contracts\GNSTradingV6_2.sol

pragma solidity 0.8.15;

contract GNSTradingV6_2 is Delegatable {

    // Contracts (constant)
    StorageInterfaceV5 public immutable storageT;
    NftRewardsInterfaceV6 public immutable nftRewards;
    GNSPairInfosInterfaceV6 public immutable pairInfos;
    GNSReferralsInterfaceV6_2 public immutable referrals;

    // Params (constant)
    uint constant PRECISION = 1e10;
    uint constant MAX_SL_P = 75;  // -75% PNL

    // Params (adjustable)
    uint public maxPosDai;            // 1e18 (eg. 75000 * 1e18)    //目前为10w;
    uint public limitOrdersTimelock;  // block (eg. 30)
    uint public marketOrdersTimeout;  // block (eg. 30)

    // State
    bool public isPaused;  // Prevent opening new trades
    bool public isDone;    // Prevent any interaction with the contract

    // Events
    event Done(bool done);
    event Paused(bool paused);

    event NumberUpdated(string name, uint value);

    event MarketOrderInitiated(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        bool open
    );

    event OpenLimitPlaced(
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );
    event OpenLimitUpdated(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newPrice,
        uint newTp,
        uint newSl
    );
    event OpenLimitCanceled(
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );

    event TpUpdated(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newTp
    );
    event SlUpdated(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newSl
    );
    event SlUpdateInitiated(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newSl
    );

    event NftOrderInitiated(
        uint orderId,
        address indexed nftHolder,
        address indexed trader,
        uint indexed pairIndex
    );
    event NftOrderSameBlock(
        address indexed nftHolder,
        address indexed trader,
        uint indexed pairIndex
    );

    event ChainlinkCallbackTimeout(
        uint indexed orderId,
        StorageInterfaceV5.PendingMarketOrder order
    );
    event CouldNotCloseTrade(
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );

    constructor(
        StorageInterfaceV5 _storageT,
        NftRewardsInterfaceV6 _nftRewards,
        GNSPairInfosInterfaceV6 _pairInfos,
        GNSReferralsInterfaceV6_2 _referrals,
        uint _maxPosDai,
        uint _limitOrdersTimelock,
        uint _marketOrdersTimeout
    ) {
        require(address(_storageT) != address(0)
            && address(_nftRewards) != address(0)
            && address(_pairInfos) != address(0)
            && address(_referrals) != address(0)
            && _maxPosDai > 0
            && _limitOrdersTimelock > 0
            && _marketOrdersTimeout > 0, "WRONG_PARAMS");

        storageT = _storageT;
        nftRewards = _nftRewards;
        pairInfos = _pairInfos;
        referrals = _referrals;

        maxPosDai = _maxPosDai;
        limitOrdersTimelock = _limitOrdersTimelock;
        marketOrdersTimeout = _marketOrdersTimeout;
    }

    // Modifiers
    modifier onlyGov(){
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier notContract(){
        require(tx.origin == msg.sender);
        _;
    }
    modifier notDone(){
        require(!isDone, "DONE");
        _;
    }

    // Manage params
    function setMaxPosDai(uint value) external onlyGov{
        require(value > 0, "VALUE_0");
        maxPosDai = value;
        
        emit NumberUpdated("maxPosDai", value);
    }
    function setLimitOrdersTimelock(uint value) external onlyGov{
        require(value > 0, "VALUE_0");
        limitOrdersTimelock = value;
        
        emit NumberUpdated("limitOrdersTimelock", value);
    }
    function setMarketOrdersTimeout(uint value) external onlyGov{
        require(value > 0, "VALUE_0");
        marketOrdersTimeout = value;
        
        emit NumberUpdated("marketOrdersTimeout", value);
    }

    // Manage state
    function pause() external onlyGov{
        isPaused = !isPaused;

        emit Paused(isPaused);
    }
    function done() external onlyGov{
        isDone = !isDone;

        emit Done(isDone);
    }

    //委托开仓入口：
    // Open new trade (MARKET/LIMIT)
    //tp, sl就是告知系统，在这个价格就给我平仓；
    //输入的t.index这个暂时用不到，所以都是0；估计是为了方便，省却重新定义数据结构；
    //t.initialPosToken 这个也不知道干嘛的；没用到；
    function openTrade(
        StorageInterfaceV5.Trade memory t,  //v5的trade参数
        NftRewardsInterfaceV6.OpenLimitOrderType orderType, // LEGACY => market；0就是市价委托，其它就是限价委托；
        uint spreadReductionId, //nft持有者可以享有费用折扣；0就代表没有使用；
        uint slippageP, // for market orders only   //市价下单允许的最大滑点；
        address referrer    //介绍人地址；
    ) external notContract notDone{
        require(!isPaused, "PAUSED");
        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();    //聚合类对象；
        PairsStorageInterfaceV6 pairsStored = aggregator.pairsStorage();    //获取交易对类对象；

        address sender = _msgSender();

        require(storageT.openTradesCount(sender, t.pairIndex)
            + storageT.pendingMarketOpenCount(sender, t.pairIndex)
            + storageT.openLimitOrdersCount(sender, t.pairIndex)
            < storageT.maxTradesPerPair(), 
            "MAX_TRADES_PER_PAIR"); //限制每个用户的每个交易对只允许有三个；

        require(storageT.pendingOrderIdsCount(sender)
            < storageT.maxPendingMarketOrders(), //限制每个用户的pedding交易数量；
            "MAX_PENDING_ORDERS");

        require(t.positionSizeDai <= maxPosDai, "ABOVE_MAX_POS");        //限制了10w dai;
        require(t.positionSizeDai * t.leverage >= pairsStored.pairMinLevPosDai(t.pairIndex), "BELOW_MIN_POS"); //判断size是否小于要求的最低size；

        require(t.leverage > 0 && t.leverage >= pairsStored.pairMinLeverage(t.pairIndex) 
            && t.leverage <= pairsStored.pairMaxLeverage(t.pairIndex), 
            "LEVERAGE_INCORRECT");

        require(spreadReductionId == 0
            || storageT.nfts(spreadReductionId - 1).balanceOf(sender) > 0,
            "NO_CORRESPONDING_NFT_SPREAD_REDUCTION");

        require(t.tp == 0 || (t.buy ?   //百分百的tp的计算只跟杠杆倍数、当前价格有关；
                t.tp > t.openPrice :
                t.tp < t.openPrice), "WRONG_TP");

        require(t.sl == 0 || (t.buy ?    //百分百的sl的计算只跟杠杆倍数、当前价格有关；
                t.sl < t.openPrice :
                t.sl > t.openPrice), "WRONG_SL");

        //判断价格滑点是否过大；
        (uint priceImpactP,) = pairInfos.getTradePriceImpact(
            0,
            t.pairIndex,
            t.buy,
            t.positionSizeDai * t.leverage
        );
        require(priceImpactP * t.leverage
            <= pairInfos.maxNegativePnlOnOpenP(), "PRICE_IMPACT_TOO_HIGH"); //由size影响的最高价格滑点不能超过，目前是40%；

        //1. 将用户的保证金DAI转入金库；
        storageT.transferDai(sender, address(storageT), t.positionSizeDai);

        //2. 委托订单写入数据库；//如果是市价单，就给预言机节点发送喂价请求；
        if (orderType != NftRewardsInterfaceV6.OpenLimitOrderType.LEGACY) { //限价单；//限价单为何不需要请求预言机？？
            //通过sender, pairindex得到新的订单索引；
            uint index = storageT.firstEmptyOpenLimitIndex(sender, t.pairIndex);

            //1.写入一个新的限价单委托到数据库；
            storageT.storeOpenLimitOrder(
                StorageInterfaceV5.OpenLimitOrder(
                    sender,
                    t.pairIndex,
                    index, //key(用户,pair)下的订单索引；    //输入的参数有什么用呢？应该是读取合约拿到的，但是不输入这个参数也没关系吧？//这里最终使用的还是计算出来的，所以，这个输入参数是没有必要的；
                    t.positionSizeDai,
                    spreadReductionId > 0 ?
                        storageT.spreadReductionsP(spreadReductionId - 1) :
                        0,  //nft持有者，可以获取费用折扣
                    t.buy,
                    t.leverage,
                    t.tp,
                    t.sl,
                    t.openPrice, //用户期望的开仓价格
                    t.openPrice,
                    block.number, //请求开仓的区块高度；
                    0
                )
            );

            //2.奖励相关？为何限价单才有奖励？
            nftRewards.setOpenLimitOrderType(sender, t.pairIndex, index, orderType);

            emit OpenLimitPlaced(
                sender,
                t.pairIndex,
                index
            );

        } else {//其它的就是市价订单；
            //1.请求预言机节点喂价并执行回调；
            uint orderId = aggregator.getPrice(
                t.pairIndex, 
                AggregatorInterfaceV6_2.OrderType.MARKET_OPEN, //委托单类型；这个为何要单独搞个类型？
                t.positionSizeDai * t.leverage  //size
            );

            //2.存储到数据库，并记录预言机请求id与数据库记录的关系；
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
                    slippageP,  //这个滑点只要大于0就行了？
                    spreadReductionId > 0 ?
                        storageT.spreadReductionsP(spreadReductionId - 1) :
                        0,  //nft持有者，可以获取费用折扣
                    0
                ), orderId, true
            );

            emit MarketOrderInitiated(
                orderId,
                sender,
                t.pairIndex,
                true
            );
        }

        referrals.registerPotentialReferrer(sender, referrer);  //记录推荐关系；
    }

    //委托市价平仓；
    // Close trade (MARKET)
    function closeTradeMarket(
        uint pairIndex,
        uint index
    ) external notContract notDone{

        address sender = _msgSender();

        //1. 通过三元组得到对应的仓位；
        StorageInterfaceV5.Trade memory t = storageT.openTrades(
            sender, pairIndex, index
        );

        //通过三元组得到对应的仓位信息；
        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(
            sender, pairIndex, index
        );

        require(storageT.pendingOrderIdsCount(sender)
            < storageT.maxPendingMarketOrders(), "MAX_PENDING_ORDERS");

        require(!i.beingMarketClosed, "ALREADY_BEING_CLOSED");
        require(t.leverage > 0, "NO_TRADE");

        //2. 调用预言机聚合器的接口，请求喂价；
        uint orderId = storageT.priceAggregator().getPrice(
            pairIndex,
            AggregatorInterfaceV6_2.OrderType.MARKET_CLOSE, //关仓价格；
            t.initialPosToken * i.tokenPriceDai * t.leverage / PRECISION    //貌似是计算总体仓位；
        );

        //3. 存储信息；
        storageT.storePendingMarketOrder(
            StorageInterfaceV5.PendingMarketOrder(
                StorageInterfaceV5.Trade(
                    sender, pairIndex, index, 0, 0, 0, false, 0, 0, 0
                ),
                0, 0, 0, 0, 0
            ), orderId, false
        );

        emit MarketOrderInitiated(
            orderId,
            sender,
            pairIndex,
            false
        );
    }

    // Manage limit order (OPEN)
    function updateOpenLimitOrder(
        uint pairIndex, 
        uint index, 
        uint price,  // PRECISION
        uint tp,
        uint sl
    ) external notContract notDone{

        address sender = _msgSender();

        require(storageT.hasOpenLimitOrder(sender, pairIndex, index),
            "NO_LIMIT");

        StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(
            sender, pairIndex, index
        );

        require(block.number - o.block >= limitOrdersTimelock, "LIMIT_TIMELOCK");

        require(tp == 0 || (o.buy ?
            tp > price :
            tp < price), "WRONG_TP");

        require(sl == 0 || (o.buy ?
            sl < price :
            sl > price), "WRONG_SL");

        o.minPrice = price;
        o.maxPrice = price;

        o.tp = tp;
        o.sl = sl;

        storageT.updateOpenLimitOrder(o);

        emit OpenLimitUpdated(
            sender,
            pairIndex,
            index,
            price,
            tp,
            sl
        );
    }

    function cancelOpenLimitOrder(
        uint pairIndex,
        uint index
    ) external notContract notDone{

        address sender = _msgSender();

        require(storageT.hasOpenLimitOrder(sender, pairIndex, index),
            "NO_LIMIT");

        StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(
            sender, pairIndex, index
        );

        require(block.number - o.block >= limitOrdersTimelock, "LIMIT_TIMELOCK");

        storageT.unregisterOpenLimitOrder(sender, pairIndex, index);
        storageT.transferDai(address(storageT), sender, o.positionSize);

        emit OpenLimitCanceled(
            sender,
            pairIndex,
            index
        );
    }

    // Manage limit order (TP/SL)
    function updateTp(
        uint pairIndex,
        uint index,
        uint newTp
    ) external notContract notDone{

        address sender = _msgSender();

        StorageInterfaceV5.Trade memory t = storageT.openTrades(
            sender, pairIndex, index
        );

        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(
            sender, pairIndex, index
        );

        require(t.leverage > 0, "NO_TRADE");
        require(block.number - i.tpLastUpdated >= limitOrdersTimelock,
            "LIMIT_TIMELOCK");

        storageT.updateTp(sender, pairIndex, index, newTp);

        emit TpUpdated(
            sender,
            pairIndex,
            index,
            newTp
        );
    }

    function updateSl(
        uint pairIndex,
        uint index,
        uint newSl
    ) external notContract notDone{

        address sender = _msgSender();

        StorageInterfaceV5.Trade memory t = storageT.openTrades(
            sender, pairIndex, index
        );

        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(
            sender, pairIndex, index
        );

        require(t.leverage > 0, "NO_TRADE");

        uint maxSlDist = t.openPrice * MAX_SL_P / 100 / t.leverage;

        require(newSl == 0 || (t.buy ? 
            newSl >= t.openPrice - maxSlDist :
            newSl <= t.openPrice + maxSlDist), "SL_TOO_BIG");
        
        require(block.number - i.slLastUpdated >= limitOrdersTimelock,
            "LIMIT_TIMELOCK");

        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();

        if(newSl == 0
        || !aggregator.pairsStorage().guaranteedSlEnabled(pairIndex)){

            storageT.updateSl(sender, pairIndex, index, newSl);

            emit SlUpdated(
                sender,
                pairIndex,
                index,
                newSl
            );

        }else{
            uint orderId = aggregator.getPrice(
                pairIndex,
                AggregatorInterfaceV6_2.OrderType.UPDATE_SL, 
                t.initialPosToken * i.tokenPriceDai * t.leverage / PRECISION
            );

            aggregator.storePendingSlOrder(
                orderId, 
                AggregatorInterfaceV6_2.PendingSl(
                    sender, pairIndex, index, t.openPrice, t.buy, newSl
                )
            );
            
            emit SlUpdateInitiated(
                orderId,
                sender,
                pairIndex,
                index,
                newSl
            );
        }
    }

    //触发限价订单执行？
    // Execute limit order
    function executeNftOrder(
        StorageInterfaceV5.LimitOrder orderType, 
        address trader, 
        uint pairIndex, 
        uint index,
        uint nftId, 
        uint nftType
    ) external notContract notDone{
        //基础校验
        address sender = _msgSender();
        require(nftType >= 1 && nftType <= 5, "WRONG_NFT_TYPE"); //只要支持NFT即可；
        require(storageT.nfts(nftType - 1).ownerOf(nftId) == sender, "NO_NFT");
        require(block.number >=
            storageT.nftLastSuccess(nftId) + storageT.nftSuccessTimelock(),
            "SUCCESS_TIMELOCK");

        //1. 场景校验；
        StorageInterfaceV5.Trade memory t;
        if(orderType == StorageInterfaceV5.LimitOrder.OPEN){
            require(storageT.hasOpenLimitOrder(trader, pairIndex, index),
                "NO_LIMIT");//限价开仓委托必须存在
        }else{
            t = storageT.openTrades(trader, pairIndex, index);  //其它的，必定仓位已经存在；

            require(t.leverage > 0, "NO_TRADE");

            if(orderType == StorageInterfaceV5.LimitOrder.LIQ){ //强平；
                uint liqPrice = getTradeLiquidationPrice(t);  //计算清算价格；
                
                require(t.sl == 0 || (t.buy ?
                    liqPrice > t.sl :   //由于资金费用的结算导致sl低于liqPrice?   //正常应该sl先触发，如果sl没有触发， 就说明liqPrice一定要高于sl;
                    liqPrice < t.sl), "HAS_SL");
            }else{  //tp or sl
                require(orderType != StorageInterfaceV5.LimitOrder.SL || t.sl > 0,
                    "NO_SL");
                require(orderType != StorageInterfaceV5.LimitOrder.TP || t.tp > 0,
                    "NO_TP");
            }
        }

        NftRewardsInterfaceV6.TriggeredLimitId memory triggeredLimitId =
            NftRewardsInterfaceV6.TriggeredLimitId(trader, pairIndex, index, orderType);  //构建触发index;

        //判断是否需要执行；
        if(!nftRewards.triggered(triggeredLimitId) || nftRewards.timedOut(triggeredLimitId)){ //没有触发，或者触发已经执行超时？
            
            uint leveragedPosDai;

            if(orderType == StorageInterfaceV5.LimitOrder.OPEN){    //限价开仓委托
                StorageInterfaceV5.OpenLimitOrder memory l = storageT.getOpenLimitOrder(
                    trader, pairIndex, index
                );

                leveragedPosDai = l.positionSize * l.leverage;

                (uint priceImpactP, ) = pairInfos.getTradePriceImpact(
                    0,
                    l.pairIndex,
                    l.buy,
                    leveragedPosDai
                );
                
                require(priceImpactP * l.leverage <= pairInfos.maxNegativePnlOnOpenP(),
                    "PRICE_IMPACT_TOO_HIGH");

            }else{  //强平、sl, tp;
                leveragedPosDai = t.initialPosToken * storageT.openTradesInfo(
                    trader, pairIndex, index
                ).tokenPriceDai * t.leverage / PRECISION;  //获取size?
            }

            storageT.transferLinkToAggregator(sender, pairIndex, leveragedPosDai); //转移link

            uint orderId = storageT.priceAggregator().getPrice( //发送喂价并执行的请求;  这个里面为何没有具体的订单index? 只有币种信息，难道是会在一次喂价里面执行这个币种的所有仓位委托？
                pairIndex, 
                orderType == StorageInterfaceV5.LimitOrder.OPEN ? 
                    AggregatorInterfaceV6_2.OrderType.LIMIT_OPEN : 
                    AggregatorInterfaceV6_2.OrderType.LIMIT_CLOSE,  //为何类型只有限价单？没有强平，sl,tp; //强平、sl, tp估计都属于限价单平仓的范畴；
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
                ), orderId
            );  //存储触发订单；

            nftRewards.storeFirstToTrigger(triggeredLimitId, sender); //存储触发index;
            
            emit NftOrderInitiated(
                orderId,
                sender,
                trader,
                pairIndex
            );

        }else{
            nftRewards.storeTriggerSameBlock(triggeredLimitId, sender); //在同一个区块里面触发多次
            
            emit NftOrderSameBlock(
                sender,
                trader,
                pairIndex
            );
        }
    }
    // Avoid stack too deep error in executeNftOrder
    function getTradeLiquidationPrice(
        StorageInterfaceV5.Trade memory t
    ) private view returns(uint){
        return pairInfos.getTradeLiquidationPrice(
            t.trader,
            t.pairIndex,
            t.index,
            t.openPrice,
            t.buy,
            t.initialPosToken * storageT.openTradesInfo(
                t.trader, t.pairIndex, t.index
            ).tokenPriceDai / PRECISION,
            t.leverage
        );
    }

    // Market timeout
    function openTradeMarketTimeout(uint _order) external notContract notDone{
        address sender = _msgSender();

        StorageInterfaceV5.PendingMarketOrder memory o =
            storageT.reqID_pendingMarketOrder(_order);

        StorageInterfaceV5.Trade memory t = o.trade;

        require(o.block > 0
            && block.number >= o.block + marketOrdersTimeout, "WAIT_TIMEOUT");

        require(t.trader == sender, "NOT_YOUR_ORDER");
        require(t.leverage > 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, true);
        storageT.transferDai(address(storageT), sender, t.positionSizeDai);

        emit ChainlinkCallbackTimeout(
            _order,
            o
        );
    }
    
    function closeTradeMarketTimeout(uint _order) external notContract notDone{
        address sender = _msgSender();

        StorageInterfaceV5.PendingMarketOrder memory o =
            storageT.reqID_pendingMarketOrder(_order);

        StorageInterfaceV5.Trade memory t = o.trade;

        require(o.block > 0
            && block.number >= o.block + marketOrdersTimeout, "WAIT_TIMEOUT");

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

        if(!success){
            emit CouldNotCloseTrade(
                sender,
                t.pairIndex,
                t.index
            );
        }

        emit ChainlinkCallbackTimeout(
            _order,
            o
        );
    }
}