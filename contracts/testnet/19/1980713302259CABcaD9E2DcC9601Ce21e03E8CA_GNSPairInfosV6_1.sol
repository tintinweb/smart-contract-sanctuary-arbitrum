// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface NftInterfaceV5{
    function balanceOf(address) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function tokenOfOwnerByIndex(address, uint) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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
pragma solidity ^0.8.7;

interface StorageInterfaceV5{
    enum LimitOrder { TP, SL, LIQ, OPEN }
    struct Trader{
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal;  // 1e18
    }
    struct Trade{
        address trader; //交易员，这个没有必要吧？
        uint pairIndex; //交易对索引，这样不大好吧？交易对如果做修改添加？//由于存在股票等标的，所以只能这样。那就不能修改索引了；
        uint index; //第几笔交易？
        uint initialPosToken;       // 1e18 //初始化仓位的标的？
        uint positionSizeDai;       // 1e18 //保证金DAI数量；//名字有误
        uint openPrice;             // PRECISION    //开仓价格；
        bool buy;   //开空，还是开多？
        uint leverage;  //杠杆倍数；
        uint tp;                    // PRECISION    //toke profit; 盈利平仓价格；
        uint sl;                    // PRECISION    //stop loss; 止亏价格；
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
    function priceAggregator() external view returns(AggregatorInterfaceV6);    //返回特定类型的合约实例地址；
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
    function pairsStorage() external view returns(PairsStorageInterfaceV6); //返回特定类型的合约实例地址；
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
pragma solidity ^0.8.7;

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
pragma solidity ^0.8.7;

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
pragma solidity ^0.8.7;

interface VaultInterfaceV5{
	function sendDaiToTrader(address, uint) external;
	function receiveDaiFromTrader(address, uint, uint) external;
	function currentBalanceDai() external view returns(uint);
	function distributeRewardDai(uint) external;
}

// SPDX-License-Identifier: MIT
import '../interfaces/StorageInterfaceV5.sol';
pragma solidity 0.8.14;

contract GNSPairInfosV6_1 {

    // Addresses
    StorageInterfaceV5 immutable storageT;
    address public manager;

    // Constant parameters
    uint constant PRECISION = 1e10;     // 10 decimals
    uint constant LIQ_THRESHOLD_P = 90; // -90% (of collateral) 觸發強平

    // Adjustable parameters
    uint public maxNegativePnlOnOpenP = 40 * PRECISION; // PRECISION (%)

    // Pair parameters
    struct PairParams{
        uint onePercentDepthAbove; // DAI   //导致往上1%滑点的资金量；
        uint onePercentDepthBelow; // DAI   //导致往下1%滑点的资金量；DAI为单位；
        uint rolloverFeePerBlockP; // PRECISION (%) //隔夜费；
        uint fundingFeePerBlockP;  // PRECISION (%) //每个区块的资金费率；
    }

    mapping(uint => PairParams) public pairParams;  //每个币种的基础点差计算、隔夜费、资金费率等；

    // Pair acc funding fees
    struct PairFundingFees{
        int accPerOiLong;  // 1e18 (DAI) 累计多头资金费率；
        int accPerOiShort; // 1e18 (DAI) 累计空投资金费率；
        uint lastUpdateBlock;   //更新到哪个区块了；
    }

    mapping(uint => PairFundingFees) public pairFundingFees;   //标的 -》 累计资金费率；

    // Pair acc rollover fees
    struct PairRolloverFees{
        uint accPerCollateral; // 1e18 (DAI)
        uint lastUpdateBlock;
    }

    mapping(uint => PairRolloverFees) public pairRolloverFees;

    // Trade initial acc fees
    struct TradeInitialAccFees{
        uint rollover; // 1e18 (DAI)
        int funding;   // 1e18 (DAI)
        bool openedAfterUpdate;
    }

    mapping(
        address => mapping(
            uint => mapping(
                uint => TradeInitialAccFees
            )
        )
    ) public tradeInitialAccFees;

    // Events
    event ManagerUpdated(address value);
    event MaxNegativePnlOnOpenPUpdated(uint value);

    event PairParamsUpdated(uint pairIndex, PairParams value);
    event OnePercentDepthUpdated(uint pairIndex, uint valueAbove, uint valueBelow);
    event RolloverFeePerBlockPUpdated(uint pairIndex, uint value);
    event FundingFeePerBlockPUpdated(uint pairIndex, uint value);

    event TradeInitialAccFeesStored(
        address trader,
        uint pairIndex,
        uint index,
        uint rollover,
        int funding
    );

    event AccFundingFeesStored(uint pairIndex, int valueLong, int valueShort);
    event AccRolloverFeesStored(uint pairIndex, uint value);

    event FeesCharged(
        uint pairIndex,
        bool long,
        uint collateral,   // 1e18 (DAI)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint rolloverFees, // 1e18 (DAI)
        int fundingFees    // 1e18 (DAI)
    );

    constructor(StorageInterfaceV5 _storageT){
        storageT = _storageT;
    }

    // Modifiers
    modifier onlyGov(){
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyManager(){
        require(msg.sender == manager, "MANAGER_ONLY");
        _;
    }
    modifier onlyCallbacks(){
        require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY");
        _;
    }

    // Set manager address
    function setManager(address _manager) external onlyGov{
        manager = _manager;

        emit ManagerUpdated(_manager);
    }

    // Set max negative PnL % on trade opening
    function setMaxNegativePnlOnOpenP(uint value) external onlyManager{
        maxNegativePnlOnOpenP = value;

        emit MaxNegativePnlOnOpenPUpdated(value);
    }

    // Set parameters for pair
    function setPairParams(uint pairIndex, PairParams memory value) public onlyManager{
        storeAccRolloverFees(pairIndex);
        storeAccFundingFees(pairIndex);

        pairParams[pairIndex] = value;

        emit PairParamsUpdated(pairIndex, value);
    }
    function setPairParamsArray(
        uint[] memory indices,
        PairParams[] memory values
    ) external onlyManager{
        require(indices.length == values.length, "WRONG_LENGTH");

        for(uint i = 0; i < indices.length; i++){
            setPairParams(indices[i], values[i]);
        }
    }

    // Set one percent depth for pair
    function setOnePercentDepth(
        uint pairIndex,
        uint valueAbove,
        uint valueBelow
    ) public onlyManager{
        PairParams storage p = pairParams[pairIndex];

        p.onePercentDepthAbove = valueAbove;
        p.onePercentDepthBelow = valueBelow;

        emit OnePercentDepthUpdated(pairIndex, valueAbove, valueBelow);
    }
    function setOnePercentDepthArray(
        uint[] memory indices,
        uint[] memory valuesAbove,
        uint[] memory valuesBelow
    ) external onlyManager{
        require(indices.length == valuesAbove.length
            && indices.length == valuesBelow.length, "WRONG_LENGTH");

        for(uint i = 0; i < indices.length; i++){
            setOnePercentDepth(indices[i], valuesAbove[i], valuesBelow[i]);
        }
    }

    // Set rollover fee for pair    //每个区块需要收取的隔夜费，每个币种都不一样；//这个为何跟币种有关系，应该是跟size有关系才对吧？
    function setRolloverFeePerBlockP(uint pairIndex, uint value) public onlyManager{
        require(value <= 25000000, "TOO_HIGH"); // ≈ 100% per day

        storeAccRolloverFees(pairIndex);

        pairParams[pairIndex].rolloverFeePerBlockP = value;

        emit RolloverFeePerBlockPUpdated(pairIndex, value);
    }
    function setRolloverFeePerBlockPArray(
        uint[] memory indices,
        uint[] memory values
    ) external onlyManager{
        require(indices.length == values.length, "WRONG_LENGTH");

        for(uint i = 0; i < indices.length; i++){
            setRolloverFeePerBlockP(indices[i], values[i]);
        }
    }

    //每个区块的资金费率是设置出来的
    // Set funding fee for pair
    function setFundingFeePerBlockP(uint pairIndex, uint value) public onlyManager{
        require(value <= 10000000, "TOO_HIGH"); // ≈ 40% per day

        storeAccFundingFees(pairIndex); //先更新累计资金费率；
        pairParams[pairIndex].fundingFeePerBlockP = value; //然后再更新每个区块的资金费率参数；
        emit FundingFeePerBlockPUpdated(pairIndex, value);
    }

    //批量设置资金费率（每个区块）//内部会 先 更新对用币种的累计资金费率；
    function setFundingFeePerBlockPArray(
        uint[] memory indices,
        uint[] memory values
    ) external onlyManager{
        require(indices.length == values.length, "WRONG_LENGTH");

        for(uint i = 0; i < indices.length; i++){
            setFundingFeePerBlockP(indices[i], values[i]);
        }
    }

    // Store trade details when opened (acc fee values)
    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external onlyCallbacks{
        storeAccFundingFees(pairIndex);

        TradeInitialAccFees storage t = tradeInitialAccFees[trader][pairIndex][index];

        t.rollover = getPendingAccRolloverFees(pairIndex);

        t.funding = long ?
            pairFundingFees[pairIndex].accPerOiLong :
            pairFundingFees[pairIndex].accPerOiShort;

        t.openedAfterUpdate = true;

        emit TradeInitialAccFeesStored(trader, pairIndex, index, t.rollover, t.funding);
    }

    // Acc rollover fees (store right before fee % update)
    function storeAccRolloverFees(uint pairIndex) private{
        PairRolloverFees storage r = pairRolloverFees[pairIndex];

        r.accPerCollateral = getPendingAccRolloverFees(pairIndex);
        r.lastUpdateBlock = block.number;

        emit AccRolloverFeesStored(pairIndex, r.accPerCollateral);
    }
    function getPendingAccRolloverFees(
        uint pairIndex
    ) public view returns(uint){ // 1e18 (DAI)
        PairRolloverFees storage r = pairRolloverFees[pairIndex];

        return r.accPerCollateral +
            (block.number - r.lastUpdateBlock)
            * pairParams[pairIndex].rolloverFeePerBlockP
            * 1e18 / PRECISION / 100;
    }

    //更新累计资金费率；
    // Acc funding fees (store right before trades opened / closed and fee % update)
    function storeAccFundingFees(uint pairIndex) private{
        PairFundingFees storage f = pairFundingFees[pairIndex];

        (f.accPerOiLong, f.accPerOiShort) = getPendingAccFundingFees(pairIndex); //更新并获取最新的累计资金费率；
        f.lastUpdateBlock = block.number;

        emit AccFundingFeesStored(pairIndex, f.accPerOiLong, f.accPerOiShort);
    }

    //更新到截止目前最新区块的累计资金费率（特定标的）；
    function getPendingAccFundingFees(uint pairIndex) public view returns(
        int valueLong,
        int valueShort
    ){
        //获取原始全局对象；
        PairFundingFees storage f = pairFundingFees[pairIndex];  //会更新原对象
        valueLong = f.accPerOiLong;
        valueShort = f.accPerOiShort;

        int openInterestDaiLong = int(storageT.openInterestDai(pairIndex, 0)); //多头总头寸
        int openInterestDaiShort = int(storageT.openInterestDai(pairIndex, 1)); //口头总头寸；

        //多：累計的資金費率 += (多仓总头寸 - 空仓总头寸) * 過了幾塊(blocks elapsed) * 资金费率（每个区块）/多仓总头寸
        //空：累計的資金費率 += (空仓总头寸- 多仓总头寸) * 過了幾塊(blocks elapsed) * 资金费率（每个区块）/ 空仓总头寸
        int fundingFeesPaidByLongs = (openInterestDaiLong - openInterestDaiShort)   //净头寸
            * int(block.number - f.lastUpdateBlock)  //区块数量；
            * int(pairParams[pairIndex].fundingFeePerBlockP)    //每个区块的资金费率；
            / int(PRECISION) / 100;

        if(openInterestDaiLong > 0){
            valueLong += fundingFeesPaidByLongs * 1e18
                / openInterestDaiLong;
        }

        if(openInterestDaiShort > 0){
            valueShort += fundingFeesPaidByLongs * 1e18 * (-1)
                / openInterestDaiShort;
        }
    }

    //获取交易价格
    // Dynamic price impact value on trade opening
    function getTradePriceImpact(
        uint openPrice,        // PRECISION
        uint pairIndex,
        bool long,
        uint tradeOpenInterest // 1e18 (DAI)
    ) external view returns(
        uint priceImpactP,     // PRECISION (%)
        uint priceAfterImpact  // PRECISION
    ){
        (priceImpactP, priceAfterImpact) = getTradePriceImpactPure(
            openPrice,  //0也代表精度？
            long,
            storageT.openInterestDai(pairIndex, long ? 0 : 1),  //得到利润？
            tradeOpenInterest,  //size?
            long ?
                pairParams[pairIndex].onePercentDepthAbove :
                pairParams[pairIndex].onePercentDepthBelow
        );
    }
    //获取价格滑点以及调整后的价格；
    function getTradePriceImpactPure(
        uint openPrice,         // PRECISION
        bool long,
        uint startOpenInterest, // 1e18 (DAI)
        uint tradeOpenInterest, // 1e18 (DAI)
        uint onePercentDepth
    ) public pure returns(
        uint priceImpactP,      // PRECISION (%)
        uint priceAfterImpact   // PRECISION
    ){
        if(onePercentDepth == 0){
            return (0, openPrice);  //如果1点深度为0，直接返回0？
        }

        priceImpactP = (startOpenInterest + tradeOpenInterest / 2)
            * PRECISION / 1e18 / onePercentDepth;   //计算价格滑点；

        uint priceImpact = priceImpactP * openPrice / PRECISION / 100;

        priceAfterImpact = long ? openPrice + priceImpact : openPrice - priceImpact;    //调整后的价格；
    }

    // Rollover fee value
    function getTradeRolloverFee(
        address trader,
        uint pairIndex,
        uint index,
        uint collateral // 1e18 (DAI)
    ) public view returns(uint){ // 1e18 (DAI)
        TradeInitialAccFees memory t = tradeInitialAccFees[trader][pairIndex][index];

        if(!t.openedAfterUpdate){
            return 0;
        }

        return getTradeRolloverFeePure(
            t.rollover,
            getPendingAccRolloverFees(pairIndex),
            collateral
        );
    }
    function getTradeRolloverFeePure(
        uint accRolloverFeesPerCollateral,
        uint endAccRolloverFeesPerCollateral,
        uint collateral // 1e18 (DAI)
    ) public pure returns(uint){ // 1e18 (DAI)
        return (endAccRolloverFeesPerCollateral - accRolloverFeesPerCollateral)
            * collateral / 1e18;
    }

    // Funding fee value
    function getTradeFundingFee(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage
    ) public view returns(
        int // 1e18 (DAI) | Positive => Fee, Negative => Reward
    ){
        TradeInitialAccFees memory t = tradeInitialAccFees[trader][pairIndex][index];

        if(!t.openedAfterUpdate){
            return 0;
        }

        (int pendingLong, int pendingShort) = getPendingAccFundingFees(pairIndex);

        return getTradeFundingFeePure(
            t.funding,
            long ? pendingLong : pendingShort,
            collateral,
            leverage
        );
    }
    function getTradeFundingFeePure(
        int accFundingFeesPerOi,
        int endAccFundingFeesPerOi,
        uint collateral, // 1e18 (DAI)
        uint leverage
    ) public pure returns(
        int // 1e18 (DAI) | Positive => Fee, Negative => Reward
    ){
        return (endAccFundingFeesPerOi - accFundingFeesPerOi)
            * int(collateral) * int(leverage) / 1e18;
    }

    // Liquidation price value after rollover and funding fees
    function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice,  // PRECISION
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage
    ) external view returns(uint){ // PRECISION
        return getTradeLiquidationPricePure(
            openPrice,
            long,
            collateral,
            leverage,
            getTradeRolloverFee(trader, pairIndex, index, collateral),
            getTradeFundingFee(trader, pairIndex, index, long, collateral, leverage)
        );
    }

    //计算某个仓位的清算价格
    function getTradeLiquidationPricePure(
        uint openPrice,   // PRECISION
        bool long,
        uint collateral,  // 1e18 (DAI)
        uint leverage,
        uint rolloverFee, // 1e18 (DAI)
        int fundingFee    // 1e18 (DAI)
    ) public pure returns(uint){ // PRECISION
        int liqPriceDistance = int(openPrice) * (
                int(collateral * LIQ_THRESHOLD_P / 100)
                - int(rolloverFee) - fundingFee
            ) / int(collateral) / int(leverage);

        int liqPrice = long ?
            int(openPrice) - liqPriceDistance :
            int(openPrice) + liqPriceDistance;

        return liqPrice > 0 ? uint(liqPrice) : 0;
    }

    // Dai sent to trader after PnL and fees
    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral,   // 1e18 (DAI)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee    // 1e18 (DAI)
    ) external onlyCallbacks returns(uint amount){ // 1e18 (DAI)
        storeAccFundingFees(pairIndex);

        uint r = getTradeRolloverFee(trader, pairIndex, index, collateral);
        int f = getTradeFundingFee(trader, pairIndex, index, long, collateral, leverage);

        amount = getTradeValuePure(collateral, percentProfit, r, f, closingFee);

        emit FeesCharged(pairIndex, long, collateral, leverage, percentProfit, r, f);
    }
    function getTradeValuePure(
        uint collateral,   // 1e18 (DAI)
        int percentProfit, // PRECISION (%)
        uint rolloverFee,  // 1e18 (DAI)
        int fundingFee,    // 1e18 (DAI)
        uint closingFee    // 1e18 (DAI)
    ) public pure returns(uint){ // 1e18 (DAI)
        int value = int(collateral)
            + int(collateral) * percentProfit / int(PRECISION) / 100
            - int(rolloverFee) - fundingFee;

        if(value <= int(collateral) * int(100 - LIQ_THRESHOLD_P) / 100){
            return 0;
        }

        value -= int(closingFee);

        return value > 0 ? uint(value) : 0;
    }

    // Useful getters
    function getPairInfos(uint[] memory indices) external view returns(
        PairParams[] memory,
        PairRolloverFees[] memory,
        PairFundingFees[] memory
    ){
        PairParams[] memory params = new PairParams[](indices.length);
        PairRolloverFees[] memory rolloverFees = new PairRolloverFees[](indices.length);
        PairFundingFees[] memory fundingFees = new PairFundingFees[](indices.length);

        for(uint i = 0; i < indices.length; i++){
            uint index = indices[i];

            params[i] = pairParams[index];
            rolloverFees[i] = pairRolloverFees[index];
            fundingFees[i] = pairFundingFees[index];
        }

        return (params, rolloverFees, fundingFees);
    }
    function getOnePercentDepthAbove(uint pairIndex) external view returns(uint){
        return pairParams[pairIndex].onePercentDepthAbove;
    }
    function getOnePercentDepthBelow(uint pairIndex) external view returns(uint){
        return pairParams[pairIndex].onePercentDepthBelow;
    }
    function getRolloverFeePerBlockP(uint pairIndex) external view returns(uint){
        return pairParams[pairIndex].rolloverFeePerBlockP;
    }
    function getFundingFeePerBlockP(uint pairIndex) external view returns(uint){
        return pairParams[pairIndex].fundingFeePerBlockP;
    }
    function getAccRolloverFees(uint pairIndex) external view returns(uint){
        return pairRolloverFees[pairIndex].accPerCollateral;
    }
    function getAccRolloverFeesUpdateBlock(uint pairIndex) external view returns(uint){
        return pairRolloverFees[pairIndex].lastUpdateBlock;
    }
    function getAccFundingFeesLong(uint pairIndex) external view returns(int){
        return pairFundingFees[pairIndex].accPerOiLong;
    }
    function getAccFundingFeesShort(uint pairIndex) external view returns(int){
        return pairFundingFees[pairIndex].accPerOiShort;
    }
    function getAccFundingFeesUpdateBlock(uint pairIndex) external view returns(uint){
        return pairFundingFees[pairIndex].lastUpdateBlock;
    }
    function getTradeInitialAccRolloverFeesPerCollateral(
        address trader,
        uint pairIndex,
        uint index
    ) external view returns(uint){
        return tradeInitialAccFees[trader][pairIndex][index].rollover;
    }
    function getTradeInitialAccFundingFeesPerOi(
        address trader,
        uint pairIndex,
        uint index
    ) external view returns(int){
        return tradeInitialAccFees[trader][pairIndex][index].funding;
    }
    function getTradeOpenedAfterUpdate(
        address trader,
        uint pairIndex,
        uint index
    ) external view returns(bool){
        return tradeInitialAccFees[trader][pairIndex][index].openedAfterUpdate;
    }
}