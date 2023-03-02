// SPDX-License-Identifier: MIT
import "../interfaces/StorageInterfaceV5.sol";
pragma solidity 0.8.10;

contract MTTPairInfos {
    // Addresses
    StorageInterfaceV5 immutable storageT;
    address public manager;

    // Constant parameters
    uint256 constant PRECISION = 1e10; // 10 decimals
    uint256 constant LIQ_THRESHOLD_P = 90; // -90% (of collateral)

    // Adjustable parameters
    uint256 public maxNegativePnlOnOpenP = 40 * PRECISION; // PRECISION (%)

    // Pair parameters
    struct PairParams {
        uint256 onePercentDepthAbove; // DAI
        uint256 onePercentDepthBelow; // DAI
        uint256 rolloverFeePerBlockP; // PRECISION (%)
        uint256 fundingFeePerBlockP; // PRECISION (%)
    }

    mapping(uint256 => PairParams) public pairParams;

    // Pair acc funding fees
    struct PairFundingFees {
        int256 accPerOiLong; // 1e18 (DAI)
        int256 accPerOiShort; // 1e18 (DAI)
        uint256 lastUpdateBlock;
    }

    mapping(uint256 => PairFundingFees) public pairFundingFees;

    // Pair acc rollover fees
    struct PairRolloverFees {
        uint256 accPerCollateral; // 1e18 (DAI)
        uint256 lastUpdateBlock;
    }

    mapping(uint256 => PairRolloverFees) public pairRolloverFees;

    // Trade initial acc fees
    struct TradeInitialAccFees {
        uint256 rollover; // 1e18 (DAI)
        int256 funding; // 1e18 (DAI)
        bool openedAfterUpdate;
    }

    mapping(address => mapping(uint256 => mapping(uint256 => TradeInitialAccFees)))
        public tradeInitialAccFees;

    // Events
    event ManagerUpdated(address value);
    event MaxNegativePnlOnOpenPUpdated(uint256 value);

    event PairParamsUpdated(uint256 pairIndex, PairParams value);
    event OnePercentDepthUpdated(
        uint256 pairIndex,
        uint256 valueAbove,
        uint256 valueBelow
    );
    event RolloverFeePerBlockPUpdated(uint256 pairIndex, uint256 value);
    event FundingFeePerBlockPUpdated(uint256 pairIndex, uint256 value);

    event TradeInitialAccFeesStored(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 rollover,
        int256 funding
    );

    event AccFundingFeesStored(
        uint256 pairIndex,
        int256 valueLong,
        int256 valueShort
    );
    event AccRolloverFeesStored(uint256 pairIndex, uint256 value);

    event FeesCharged(
        uint256 pairIndex,
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage,
        int256 percentProfit, // PRECISION (%)
        uint256 rolloverFees, // 1e18 (DAI)
        int256 fundingFees // 1e18 (DAI)
    );

    constructor(StorageInterfaceV5 _storageT) {
        storageT = _storageT;
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "MANAGER_ONLY");
        _;
    }
    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY");
        _;
    }

    // Set manager address
    function setManager(address _manager) external onlyGov {
        manager = _manager;

        emit ManagerUpdated(_manager);
    }

    // Set max negative PnL % on trade opening
    function setMaxNegativePnlOnOpenP(uint256 value) external onlyManager {
        maxNegativePnlOnOpenP = value;

        emit MaxNegativePnlOnOpenPUpdated(value);
    }

    // Set parameters for pair
    function setPairParams(uint256 pairIndex, PairParams memory value)
        public
        onlyManager
    {
        storeAccRolloverFees(pairIndex);
        storeAccFundingFees(pairIndex);

        pairParams[pairIndex] = value;

        emit PairParamsUpdated(pairIndex, value);
    }

    function setPairParamsArray(
        uint256[] memory indices,
        PairParams[] memory values
    ) external onlyManager {
        require(indices.length == values.length, "WRONG_LENGTH");

        for (uint256 i = 0; i < indices.length; i++) {
            setPairParams(indices[i], values[i]);
        }
    }

    // Set one percent depth for pair
    function setOnePercentDepth(
        uint256 pairIndex,
        uint256 valueAbove,
        uint256 valueBelow
    ) public onlyManager {
        PairParams storage p = pairParams[pairIndex];

        p.onePercentDepthAbove = valueAbove;
        p.onePercentDepthBelow = valueBelow;

        emit OnePercentDepthUpdated(pairIndex, valueAbove, valueBelow);
    }

    function setOnePercentDepthArray(
        uint256[] memory indices,
        uint256[] memory valuesAbove,
        uint256[] memory valuesBelow
    ) external onlyManager {
        require(
            indices.length == valuesAbove.length &&
                indices.length == valuesBelow.length,
            "WRONG_LENGTH"
        );

        for (uint256 i = 0; i < indices.length; i++) {
            setOnePercentDepth(indices[i], valuesAbove[i], valuesBelow[i]);
        }
    }

    // Set rollover fee for pair
    function setRolloverFeePerBlockP(uint256 pairIndex, uint256 value)
        public
        onlyManager
    {
        require(value <= 25000000, "TOO_HIGH"); // ≈ 100% per day

        storeAccRolloverFees(pairIndex);

        pairParams[pairIndex].rolloverFeePerBlockP = value;

        emit RolloverFeePerBlockPUpdated(pairIndex, value);
    }

    function setRolloverFeePerBlockPArray(
        uint256[] memory indices,
        uint256[] memory values
    ) external onlyManager {
        require(indices.length == values.length, "WRONG_LENGTH");

        for (uint256 i = 0; i < indices.length; i++) {
            setRolloverFeePerBlockP(indices[i], values[i]);
        }
    }

    // Set funding fee for pair
    function setFundingFeePerBlockP(uint256 pairIndex, uint256 value)
        public
        onlyManager
    {
        require(value <= 10000000, "TOO_HIGH"); // ≈ 40% per day

        storeAccFundingFees(pairIndex);

        pairParams[pairIndex].fundingFeePerBlockP = value;

        emit FundingFeePerBlockPUpdated(pairIndex, value);
    }

    function setFundingFeePerBlockPArray(
        uint256[] memory indices,
        uint256[] memory values
    ) external onlyManager {
        require(indices.length == values.length, "WRONG_LENGTH");

        for (uint256 i = 0; i < indices.length; i++) {
            setFundingFeePerBlockP(indices[i], values[i]);
        }
    }

    // Store trade details when opened (acc fee values)
    function storeTradeInitialAccFees(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long
    ) external onlyCallbacks {
        storeAccFundingFees(pairIndex);

        TradeInitialAccFees storage t = tradeInitialAccFees[trader][pairIndex][
            index
        ];

        t.rollover = getPendingAccRolloverFees(pairIndex);

        t.funding = long
            ? pairFundingFees[pairIndex].accPerOiLong
            : pairFundingFees[pairIndex].accPerOiShort;

        t.openedAfterUpdate = true;

        emit TradeInitialAccFeesStored(
            trader,
            pairIndex,
            index,
            t.rollover,
            t.funding
        );
    }

    // Acc rollover fees (store right before fee % update)
    function storeAccRolloverFees(uint256 pairIndex) private {
        PairRolloverFees storage r = pairRolloverFees[pairIndex];

        r.accPerCollateral = getPendingAccRolloverFees(pairIndex);
        r.lastUpdateBlock = block.number;

        emit AccRolloverFeesStored(pairIndex, r.accPerCollateral);
    }

    function getPendingAccRolloverFees(uint256 pairIndex)
        public
        view
        returns (uint256)
    {
        // 1e18 (DAI)
        PairRolloverFees storage r = pairRolloverFees[pairIndex];

        return
            r.accPerCollateral +
            ((block.number - r.lastUpdateBlock) *
                pairParams[pairIndex].rolloverFeePerBlockP *
                1e18) /
            PRECISION /
            100;
    }

    // Acc funding fees (store right before trades opened / closed and fee % update)
    function storeAccFundingFees(uint256 pairIndex) private {
        PairFundingFees storage f = pairFundingFees[pairIndex];

        (f.accPerOiLong, f.accPerOiShort) = getPendingAccFundingFees(pairIndex);
        f.lastUpdateBlock = block.number;

        emit AccFundingFeesStored(pairIndex, f.accPerOiLong, f.accPerOiShort);
    }

    function getPendingAccFundingFees(uint256 pairIndex)
        public
        view
        returns (int256 valueLong, int256 valueShort)
    {
        PairFundingFees storage f = pairFundingFees[pairIndex];

        valueLong = f.accPerOiLong;
        valueShort = f.accPerOiShort;

        int256 openInterestDaiLong = int256(
            storageT.openInterestDai(pairIndex, 0)
        );
        int256 openInterestDaiShort = int256(
            storageT.openInterestDai(pairIndex, 1)
        );

        int256 fundingFeesPaidByLongs = ((openInterestDaiLong -
            openInterestDaiShort) *
            int256(block.number - f.lastUpdateBlock) *
            int256(pairParams[pairIndex].fundingFeePerBlockP)) /
            int256(PRECISION) /
            100;

        if (openInterestDaiLong > 0) {
            valueLong += (fundingFeesPaidByLongs * 1e18) / openInterestDaiLong;
        }

        if (openInterestDaiShort > 0) {
            valueShort +=
                (fundingFeesPaidByLongs * 1e18 * (-1)) /
                openInterestDaiShort;
        }
    }

    // Dynamic price impact value on trade opening
    function getTradePriceImpact(
        uint256 openPrice, // PRECISION
        uint256 pairIndex,
        bool long,
        uint256 tradeOpenInterest // 1e18 (DAI)
    )
        external
        view
        returns (
            uint256 priceImpactP, // PRECISION (%)
            uint256 priceAfterImpact // PRECISION
        )
    {
        (priceImpactP, priceAfterImpact) = getTradePriceImpactPure(
            openPrice,
            long,
            storageT.openInterestDai(pairIndex, long ? 0 : 1),
            tradeOpenInterest,
            long
                ? pairParams[pairIndex].onePercentDepthAbove
                : pairParams[pairIndex].onePercentDepthBelow
        );
    }

    function getTradePriceImpactPure(
        uint256 openPrice, // PRECISION
        bool long,
        uint256 startOpenInterest, // 1e18 (DAI)
        uint256 tradeOpenInterest, // 1e18 (DAI)
        uint256 onePercentDepth
    )
        public
        view
        returns (
            uint256 priceImpactP, // PRECISION (%)
            uint256 priceAfterImpact // PRECISION
        )
    {
        if (onePercentDepth == 0) {
            return (0, openPrice);
        }

        priceImpactP =
            ((startOpenInterest + tradeOpenInterest / 2) * PRECISION) /
            1e18 /
            onePercentDepth;

        uint256 priceImpact = (priceImpactP * openPrice) / PRECISION / 100;

        priceAfterImpact = long
            ? openPrice + priceImpact
            : openPrice - priceImpact;
    }

    // Rollover fee value
    function getTradeRolloverFee(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 collateral // 1e18 (DAI)
    ) public view returns (uint256) {
        // 1e18 (DAI)
        TradeInitialAccFees memory t = tradeInitialAccFees[trader][pairIndex][
            index
        ];

        if (!t.openedAfterUpdate) {
            return 0;
        }

        return
            getTradeRolloverFeePure(
                t.rollover,
                getPendingAccRolloverFees(pairIndex),
                collateral
            );
    }

    function getTradeRolloverFeePure(
        uint256 accRolloverFeesPerCollateral,
        uint256 endAccRolloverFeesPerCollateral,
        uint256 collateral // 1e18 (DAI)
    ) public pure returns (uint256) {
        // 1e18 (DAI)
        return
            ((endAccRolloverFeesPerCollateral - accRolloverFeesPerCollateral) *
                collateral) / 1e18;
    }

    // Funding fee value
    function getTradeFundingFee(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage
    )
        public
        view
        returns (
            int256 // 1e18 (DAI) | Positive => Fee, Negative => Reward
        )
    {
        TradeInitialAccFees memory t = tradeInitialAccFees[trader][pairIndex][
            index
        ];

        if (!t.openedAfterUpdate) {
            return 0;
        }

        (int256 pendingLong, int256 pendingShort) = getPendingAccFundingFees(
            pairIndex
        );

        return
            getTradeFundingFeePure(
                t.funding,
                long ? pendingLong : pendingShort,
                collateral,
                leverage
            );
    }

    function getTradeFundingFeePure(
        int256 accFundingFeesPerOi,
        int256 endAccFundingFeesPerOi,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage
    )
        public
        pure
        returns (
            int256 // 1e18 (DAI) | Positive => Fee, Negative => Reward
        )
    {
        return
            ((endAccFundingFeesPerOi - accFundingFeesPerOi) *
                int256(collateral) *
                int256(leverage)) / 1e18;
    }

    // Liquidation price value after rollover and funding fees
    function getTradeLiquidationPrice(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 openPrice, // PRECISION
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage
    ) external view returns (uint256) {
        // PRECISION
        return
            getTradeLiquidationPricePure(
                openPrice,
                long,
                collateral,
                leverage,
                getTradeRolloverFee(trader, pairIndex, index, collateral),
                getTradeFundingFee(
                    trader,
                    pairIndex,
                    index,
                    long,
                    collateral,
                    leverage
                )
            );
    }

    function getTradeLiquidationPricePure(
        uint256 openPrice, // PRECISION
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage,
        uint256 rolloverFee, // 1e18 (DAI)
        int256 fundingFee // 1e18 (DAI)
    ) public pure returns (uint256) {
        // PRECISION
        int256 liqPriceDistance = (int256(openPrice) *
            (int256((collateral * LIQ_THRESHOLD_P) / 100) -
                int256(rolloverFee) -
                fundingFee)) /
            int256(collateral) /
            int256(leverage);

        int256 liqPrice = long
            ? int256(openPrice) - liqPriceDistance
            : int256(openPrice) + liqPriceDistance;

        return liqPrice > 0 ? uint256(liqPrice) : 0;
    }

    // Dai sent to trader after PnL and fees
    function getTradeValue(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage,
        int256 percentProfit, // PRECISION (%)
        uint256 closingFee // 1e18 (DAI)
    ) external onlyCallbacks returns (uint256 amount) {
        // 1e18 (DAI)
        storeAccFundingFees(pairIndex);

        uint256 r = getTradeRolloverFee(trader, pairIndex, index, collateral);
        int256 f = getTradeFundingFee(
            trader,
            pairIndex,
            index,
            long,
            collateral,
            leverage
        );

        amount = getTradeValuePure(collateral, percentProfit, r, f, closingFee);

        emit FeesCharged(
            pairIndex,
            long,
            collateral,
            leverage,
            percentProfit,
            r,
            f
        );
    }

    function getTradeValuePure(
        uint256 collateral, // 1e18 (DAI)
        int256 percentProfit, // PRECISION (%)
        uint256 rolloverFee, // 1e18 (DAI)
        int256 fundingFee, // 1e18 (DAI)
        uint256 closingFee // 1e18 (DAI)
    ) public pure returns (uint256) {
        // 1e18 (DAI)
        int256 value = int256(collateral) +
            (int256(collateral) * percentProfit) /
            int256(PRECISION) /
            100 -
            int256(rolloverFee) -
            fundingFee;

        if (
            value <= (int256(collateral) * int256(100 - LIQ_THRESHOLD_P)) / 100
        ) {
            return 0;
        }

        value -= int256(closingFee);

        return value > 0 ? uint256(value) : 0;
    }

    // Useful getters
    function getPairInfos(uint256[] memory indices)
        external
        view
        returns (
            PairParams[] memory,
            PairRolloverFees[] memory,
            PairFundingFees[] memory
        )
    {
        PairParams[] memory params = new PairParams[](indices.length);
        PairRolloverFees[] memory rolloverFees = new PairRolloverFees[](
            indices.length
        );
        PairFundingFees[] memory fundingFees = new PairFundingFees[](
            indices.length
        );

        for (uint256 i = 0; i < indices.length; i++) {
            uint256 index = indices[i];

            params[i] = pairParams[index];
            rolloverFees[i] = pairRolloverFees[index];
            fundingFees[i] = pairFundingFees[index];
        }

        return (params, rolloverFees, fundingFees);
    }

    function getOnePercentDepthAbove(uint256 pairIndex)
        external
        view
        returns (uint256)
    {
        return pairParams[pairIndex].onePercentDepthAbove;
    }

    function getOnePercentDepthBelow(uint256 pairIndex)
        external
        view
        returns (uint256)
    {
        return pairParams[pairIndex].onePercentDepthBelow;
    }

    function getRolloverFeePerBlockP(uint256 pairIndex)
        external
        view
        returns (uint256)
    {
        return pairParams[pairIndex].rolloverFeePerBlockP;
    }

    function getFundingFeePerBlockP(uint256 pairIndex)
        external
        view
        returns (uint256)
    {
        return pairParams[pairIndex].fundingFeePerBlockP;
    }

    function getAccRolloverFees(uint256 pairIndex)
        external
        view
        returns (uint256)
    {
        return pairRolloverFees[pairIndex].accPerCollateral;
    }

    function getAccRolloverFeesUpdateBlock(uint256 pairIndex)
        external
        view
        returns (uint256)
    {
        return pairRolloverFees[pairIndex].lastUpdateBlock;
    }

    function getAccFundingFeesLong(uint256 pairIndex)
        external
        view
        returns (int256)
    {
        return pairFundingFees[pairIndex].accPerOiLong;
    }

    function getAccFundingFeesShort(uint256 pairIndex)
        external
        view
        returns (int256)
    {
        return pairFundingFees[pairIndex].accPerOiShort;
    }

    function getAccFundingFeesUpdateBlock(uint256 pairIndex)
        external
        view
        returns (uint256)
    {
        return pairFundingFees[pairIndex].lastUpdateBlock;
    }

    function getTradeInitialAccRolloverFeesPerCollateral(
        address trader,
        uint256 pairIndex,
        uint256 index
    ) external view returns (uint256) {
        return tradeInitialAccFees[trader][pairIndex][index].rollover;
    }

    function getTradeInitialAccFundingFeesPerOi(
        address trader,
        uint256 pairIndex,
        uint256 index
    ) external view returns (int256) {
        return tradeInitialAccFees[trader][pairIndex][index].funding;
    }

    function getTradeOpenedAfterUpdate(
        address trader,
        uint256 pairIndex,
        uint256 index
    ) external view returns (bool) {
        return tradeInitialAccFees[trader][pairIndex][index].openedAfterUpdate;
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