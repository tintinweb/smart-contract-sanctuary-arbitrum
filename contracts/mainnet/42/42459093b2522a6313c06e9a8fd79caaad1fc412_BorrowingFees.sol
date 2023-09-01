// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IBorrowingFees.sol";
import "../interfaces/ITradingStorage.sol";
import "../interfaces/IPairInfos.sol";
import "../libraries/ChainUtils.sol";


contract BorrowingFees is IBorrowingFees {
   
    uint256 constant P_1 = 1e10;
    uint256 constant P_2 = 1e40;

    ITradingStorage public storageT;
    IPairInfos public pairInfos;

    mapping(uint16 => Group) public groups;
    mapping(uint256 => Pair) public pairs;
    mapping(address => mapping(uint256 => mapping(uint256 => InitialAccFees))) public initialAccFees;

    error BorrowingFeesWrongParameters();
    error BorrowingFeesInvalidManagerAddress(address account);
    error BorrowingFeesInvalidCallbacksContract(address account);
    error BorrowingFeesOverflow();
    error BorrowingFeesBlockOrder();

    modifier onlyManager(){
        if (msg.sender != pairInfos.manager()) {
            revert BorrowingFeesInvalidManagerAddress(msg.sender);
        }
        _;
    }
    modifier onlyCallbacks(){
        if (msg.sender != storageT.callbacks()) {
            revert BorrowingFeesInvalidCallbacksContract(msg.sender);
        }
        _;
    }

    constructor(ITradingStorage _storageT, IPairInfos _pairInfos) {
        if (address(_storageT) == address(0) || address(_pairInfos) == address(0)) revert BorrowingFeesWrongParameters();

        storageT = _storageT;
        pairInfos = _pairInfos;
    }

    function setPairParams(uint256 pairIndex, PairParams calldata value) external onlyManager {
        _setPairParams(pairIndex, value);
    }

    function setPairParamsArray(uint256[] calldata indices, PairParams[] calldata values) external onlyManager {
        uint256 len = indices.length;
        if (len != values.length) revert BorrowingFeesWrongParameters();

        for (uint256 i; i < len; ) {
            _setPairParams(indices[i], values[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setGroupParams(uint16 groupIndex, GroupParams calldata value) external onlyManager {
        _setGroupParams(groupIndex, value);
    }

    function setGroupParamsArray(uint16[] calldata indices, GroupParams[] calldata values) external onlyManager {
        uint256 len = indices.length;
        if (len != values.length) revert BorrowingFeesWrongParameters();

        for (uint256 i; i < len; ) {
            _setGroupParams(indices[i], values[i]);
            unchecked {
                ++i;
            }
        }
    }

    function handleTradeAction(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 positionSizeStable,
        bool open,
        bool long
    ) external override onlyCallbacks {
        uint16 groupIndex = getPairGroupIndex(pairIndex);
        uint256 currentBlock = ChainUtils.getBlockNumber();

        (uint64 pairAccFeeLong, uint64 pairAccFeeShort) = _setPairPendingAccFees(pairIndex, currentBlock);
        (uint64 groupAccFeeLong, uint64 groupAccFeeShort) = _setGroupPendingAccFees(groupIndex, currentBlock);

        _setGroupOi(groupIndex, long, open, positionSizeStable);

        if (open) {
            InitialAccFees memory initialFees = InitialAccFees(
                long ? pairAccFeeLong : pairAccFeeShort,
                long ? groupAccFeeLong : groupAccFeeShort,
                ChainUtils.getUint48BlockNumber(currentBlock),
                0 // placeholder
            );

            initialAccFees[trader][pairIndex][index] = initialFees;

            emit TradeInitialAccFeesStored(trader, pairIndex, index, initialFees.accPairFee, initialFees.accGroupFee);
        }

        emit TradeActionHandled(trader, pairIndex, index, open, long, positionSizeStable);
    }

    function getTradeLiquidationPrice(LiqPriceInput calldata input) external view returns (uint256) {
        return
            pairInfos.getTradeLiquidationPricePure(
                input.openPrice,
                input.long,
                input.collateral,
                input.leverage,
                pairInfos.getTradeRolloverFee(input.trader, input.pairIndex, input.index, input.collateral) +
                    getTradeBorrowingFee(
                        BorrowingFeeInput(
                            input.trader,
                            input.pairIndex,
                            input.index,
                            input.long,
                            input.collateral,
                            input.leverage
                        )
                    ),
                pairInfos.getTradeFundingFee(
                    input.trader,
                    input.pairIndex,
                    input.index,
                    input.long,
                    input.collateral,
                    input.leverage
                )
            );
    }

    function withinMaxGroupOi(
        uint256 pairIndex,
        bool long,
        uint256 positionSizeStable 
    ) external view returns (bool) {
        Group memory g = groups[getPairGroupIndex(pairIndex)];
        return (g.maxOi == 0) || ((long ? g.oiLong : g.oiShort) + (positionSizeStable * P_1) / 1e18 <= g.maxOi);
    }

    function getGroup(uint16 groupIndex) external view returns (Group memory) {
        return groups[groupIndex];
    }

    function getPair(uint256 pairIndex) external view returns (Pair memory) {
        return pairs[pairIndex];
    }

    function getAllPairs() external view returns (Pair[] memory) {
        uint256 len = storageT.priceAggregator().pairsStorage().pairsCount();
        Pair[] memory p = new Pair[](len);

        for (uint256 i; i < len; ) {
            p[i] = pairs[i];
            unchecked {
                ++i;
            }
        }

        return p;
    }

    function getGroups(uint16[] calldata indices) external view returns (Group[] memory) {
        Group[] memory g = new Group[](indices.length);
        uint256 len = indices.length;

        for (uint256 i; i < len; ) {
            g[i] = groups[indices[i]];
            unchecked {
                ++i;
            }
        }

        return g;
    }

    function getTradeInitialAccFees(
        address trader,
        uint256 pairIndex,
        uint256 index
    )
        external
        view
        returns (InitialAccFees memory borrowingFees, IPairInfos.TradeInitialAccFees memory otherFees)
    {
        borrowingFees = initialAccFees[trader][pairIndex][index];
        otherFees = pairInfos.tradeInitialAccFees(trader, pairIndex, index);
    }

    function getPairGroupAccFeesDeltas(
        uint256 i,
        PairGroup[] memory pairGroups,
        InitialAccFees memory initialFees,
        uint256 pairIndex,
        bool long,
        uint256 currentBlock
    ) public view returns (uint64 deltaGroup, uint64 deltaPair, bool beforeTradeOpen) {
        PairGroup memory group = pairGroups[i];

        beforeTradeOpen = group.block < initialFees.block;

        if (i == pairGroups.length - 1) {
            // Last active group
            deltaGroup = getGroupPendingAccFee(group.groupIndex, currentBlock, long);
            deltaPair = getPairPendingAccFee(pairIndex, currentBlock, long);
        } else {
            // Previous groups
            PairGroup memory nextGroup = pairGroups[i + 1];

            // If it's not the first group to be before the trade was opened then fee is 0
            if (beforeTradeOpen && nextGroup.block <= initialFees.block) {
                return (0, 0, beforeTradeOpen);
            }

            deltaGroup = long ? nextGroup.prevGroupAccFeeLong : nextGroup.prevGroupAccFeeShort;
            deltaPair = long ? nextGroup.pairAccFeeLong : nextGroup.pairAccFeeShort;
        }

        if (beforeTradeOpen) {
            deltaGroup -= initialFees.accGroupFee;
            deltaPair -= initialFees.accPairFee;
        } else {
            deltaGroup -= (long ? group.initialAccFeeLong : group.initialAccFeeShort);
            deltaPair -= (long ? group.pairAccFeeLong : group.pairAccFeeShort);
        }
    }

    function getPairPendingAccFees(
        uint256 pairIndex,
        uint256 currentBlock
    ) public view returns (uint64 accFeeLong, uint64 accFeeShort, int256 pairAccFeeDelta) {
        uint256 workPoolMarketCap = getPairWeightedWorkPoolMarketCapSinceLastUpdate(pairIndex, currentBlock);
        Pair memory pair = pairs[pairIndex];

        (uint256 pairOiLong, uint256 pairOiShort) = getPairOpenInterestStable(pairIndex);

        (accFeeLong, accFeeShort, pairAccFeeDelta) = getPendingAccFees(
            pair.accFeeLong,
            pair.accFeeShort,
            pairOiLong,
            pairOiShort,
            pair.feePerBlock,
            currentBlock,
            pair.accLastUpdatedBlock,
            workPoolMarketCap
        );
    }

    function getPairPendingAccFee(uint256 pairIndex, uint256 currentBlock, bool long) public view returns (uint64 accFee) {
        (uint64 accFeeLong, uint64 accFeeShort, ) = getPairPendingAccFees(pairIndex, currentBlock);
        return long ? accFeeLong : accFeeShort;
    }

    function getGroupPendingAccFees(
        uint16 groupIndex,
        uint256 currentBlock
    ) public view returns (uint64 accFeeLong, uint64 accFeeShort, int256 groupAccFeeDelta) {
        uint workPoolMarketCap = getGroupWeightedWorkPoolMarketCapSinceLastUpdate(groupIndex, currentBlock);
        Group memory group = groups[groupIndex];

        (accFeeLong, accFeeShort, groupAccFeeDelta) = getPendingAccFees(
            group.accFeeLong,
            group.accFeeShort,
            (uint256(group.oiLong) * 1e18) / P_1,
            (uint256(group.oiShort) * 1e18) / P_1,
            group.feePerBlock,
            currentBlock,
            group.accLastUpdatedBlock,
            workPoolMarketCap
        );
    }

    function getGroupPendingAccFee(
        uint16 groupIndex,
        uint256 currentBlock,
        bool long
    ) public view returns (uint64 accFee) {
        (uint64 accFeeLong, uint64 accFeeShort, ) = getGroupPendingAccFees(groupIndex, currentBlock);
        return long ? accFeeLong : accFeeShort;
    }

    function getTradeBorrowingFee(BorrowingFeeInput memory input) public view returns (uint256 fee) {
        InitialAccFees memory initialFees = initialAccFees[input.trader][input.pairIndex][input.index];
        PairGroup[] memory pairGroups = pairs[input.pairIndex].groups;

        uint256 currentBlock = ChainUtils.getBlockNumber();

        PairGroup memory firstPairGroup;
        if (pairGroups.length > 0) {
            firstPairGroup = pairGroups[0];
        }

        // If pair has had no group after trade was opened, initialize with pair borrowing fee
        if (pairGroups.length == 0 || firstPairGroup.block > initialFees.block) {
            fee = ((
                pairGroups.length == 0
                    ? getPairPendingAccFee(input.pairIndex, currentBlock, input.long)
                    : (input.long ? firstPairGroup.pairAccFeeLong : firstPairGroup.pairAccFeeShort)
            ) - initialFees.accPairFee);
        }

        // Sum of max(pair fee, group fee) for all groups the pair was in while trade was open
        for (uint256 i = pairGroups.length; i > 0; ) {
            (uint64 deltaGroup, uint64 deltaPair, bool beforeTradeOpen) = getPairGroupAccFeesDeltas(
                i - 1,
                pairGroups,
                initialFees,
                input.pairIndex,
                input.long,
                currentBlock
            );

            fee += (deltaGroup > deltaPair ? deltaGroup : deltaPair);

            // Exit loop at first group before trade was open
            if (beforeTradeOpen) break;
            unchecked {
                --i;
            }
        }

        fee = (input.collateral * input.leverage * fee) / P_1 / 100;
    }

    function getPairOpenInterestStable(uint256 pairIndex) public view returns (uint256, uint256) {
        return (storageT.openInterestStable(pairIndex, 0), storageT.openInterestStable(pairIndex, 1));
    }

    function getPairGroupIndex(uint256 pairIndex) public view returns (uint16 groupIndex) {
        PairGroup[] memory pairGroups = pairs[pairIndex].groups;
        return pairGroups.length == 0 ? 0 : pairGroups[pairGroups.length - 1].groupIndex;
    }

    function getPendingAccBlockWeightedMarketCap(uint256 currentBlock) public view returns (uint256) {
        return IWorkPool(storageT.workPool()).getPendingAccBlockWeightedMarketCap(currentBlock);
    }

    function getGroupWeightedWorkPoolMarketCapSinceLastUpdate(
        uint16 groupIndex,
        uint256 currentBlock
    ) public view returns (uint256) {
        Group memory g = groups[groupIndex];
        return
            getWeightedWorkPoolMarketCap(
                getPendingAccBlockWeightedMarketCap(currentBlock),
                g.lastAccBlockWeightedMarketCap,
                currentBlock - g.accLastUpdatedBlock
            );
    }

    function getPairWeightedWorkPoolMarketCapSinceLastUpdate(
        uint256 pairIndex,
        uint256 currentBlock
    ) public view returns (uint256) {
        Pair memory p = pairs[pairIndex];
        return
            getWeightedWorkPoolMarketCap(
                getPendingAccBlockWeightedMarketCap(currentBlock),
                p.lastAccBlockWeightedMarketCap,
                currentBlock - p.accLastUpdatedBlock
            );
    }

    function getPendingAccFees(
        uint64 accFeeLong, 
        uint64 accFeeShort, 
        uint256 oiLong, 
        uint256 oiShort, 
        uint32 feePerBlock, 
        uint256 currentBlock,
        uint256 accLastUpdatedBlock,
        uint256 workPoolMarketCap 
    ) public pure returns (uint64 newAccFeeLong, uint64 newAccFeeShort, int256 delta) {
        if (currentBlock < accLastUpdatedBlock) revert BorrowingFeesBlockOrder();

        delta =
            ((int256(oiLong) - int256(oiShort)) * int256(uint256(feePerBlock)) * int256(currentBlock - accLastUpdatedBlock)) /
            int256(workPoolMarketCap); 

        uint256 deltaUint;

        if (delta < 0) {
            deltaUint = uint256(delta * (-1));
            newAccFeeLong = accFeeLong;
            newAccFeeShort = accFeeShort + uint64(deltaUint);
        } else {
            deltaUint = uint256(delta);
            newAccFeeLong = accFeeLong + uint64(deltaUint);
            newAccFeeShort = accFeeShort;
        }

        if (deltaUint > type(uint64).max) revert BorrowingFeesOverflow();
    }

    function getWeightedWorkPoolMarketCap(
        uint256 accBlockWeightedMarketCap,
        uint256 lastAccBlockWeightedMarketCap,
        uint256 blockDelta
    ) public pure returns (uint256) {
        // return 1 in case blockDelta is 0 since acc borrowing fees delta will be 0 anyway, and 0 / 1 = 0
        return blockDelta > 0 ? (blockDelta * P_2) / (accBlockWeightedMarketCap - lastAccBlockWeightedMarketCap) : 1; 
    }

    function _setPairParams(uint256 pairIndex, PairParams calldata value) private {
        Pair storage p = pairs[pairIndex];

        uint16 prevGroupIndex = getPairGroupIndex(pairIndex);
        uint256 currentBlock = ChainUtils.getBlockNumber();

        _setPairPendingAccFees(pairIndex, currentBlock);

        if (value.groupIndex != prevGroupIndex) {
            _setGroupPendingAccFees(prevGroupIndex, currentBlock);
            _setGroupPendingAccFees(value.groupIndex, currentBlock);

            (uint256 oiLong, uint256 oiShort) = getPairOpenInterestStable(pairIndex);

            // Only remove OI from old group if old group is not 0
            _setGroupOi(prevGroupIndex, true, false, oiLong);
            _setGroupOi(prevGroupIndex, false, false, oiShort);

            // Add OI to new group if it's not group 0 (even if old group is 0)
            // So when we assign a pair to a group, it takes into account its OI
            // And group 0 OI will always be 0 but it doesn't matter since it's not used
            _setGroupOi(value.groupIndex, true, true, oiLong);
            _setGroupOi(value.groupIndex, false, true, oiShort);

            Group memory newGroup = groups[value.groupIndex];
            Group memory prevGroup = groups[prevGroupIndex];

            p.groups.push(
                PairGroup(
                    value.groupIndex,
                    ChainUtils.getUint48BlockNumber(currentBlock),
                    newGroup.accFeeLong,
                    newGroup.accFeeShort,
                    prevGroup.accFeeLong,
                    prevGroup.accFeeShort,
                    p.accFeeLong,
                    p.accFeeShort,
                    0 // placeholder
                )
            );

            emit PairGroupUpdated(pairIndex, prevGroupIndex, value.groupIndex);
        }

        p.feePerBlock = value.feePerBlock;

        emit PairParamsUpdated(pairIndex, value.groupIndex, value.feePerBlock);
    }

    function _setGroupParams(uint16 groupIndex, GroupParams calldata value) private {
        if (groupIndex == 0) revert BorrowingFeesWrongParameters();

        _setGroupPendingAccFees(groupIndex, ChainUtils.getBlockNumber());
        groups[groupIndex].feePerBlock = value.feePerBlock;
        groups[groupIndex].maxOi = value.maxOi;

        emit GroupUpdated(groupIndex, value.feePerBlock, value.maxOi);
    }

    function _setGroupOi(
        uint16 groupIndex,
        bool long,
        bool increase,
        uint256 amount 
    ) private {
        Group storage group = groups[groupIndex];
        uint112 amountFinal;

        if (groupIndex > 0) {
            amount = (amount * P_1) / 1e18; 
            if (amount > type(uint112).max) revert BorrowingFeesOverflow();

            amountFinal = uint112(amount);

            if (long) {
                group.oiLong = increase
                    ? group.oiLong + amountFinal
                    : group.oiLong - (group.oiLong > amountFinal ? amountFinal : group.oiLong);
            } else {
                group.oiShort = increase
                    ? group.oiShort + amountFinal
                    : group.oiShort - (group.oiShort > amountFinal ? amountFinal : group.oiShort);
            }
        }

        emit GroupOiUpdated(groupIndex, long, increase, amountFinal, group.oiLong, group.oiShort);
    }

    function _setPairPendingAccFees(
        uint256 pairIndex,
        uint256 currentBlock
    ) private returns (uint64 accFeeLong, uint64 accFeeShort) {
        int256 delta;
        (accFeeLong, accFeeShort, delta) = getPairPendingAccFees(pairIndex, currentBlock);

        Pair storage pair = pairs[pairIndex];

        (pair.accFeeLong, pair.accFeeShort) = (accFeeLong, accFeeShort);
        pair.accLastUpdatedBlock = ChainUtils.getUint48BlockNumber(currentBlock);
        pair.lastAccBlockWeightedMarketCap = getPendingAccBlockWeightedMarketCap(currentBlock);

        emit PairAccFeesUpdated(
            pairIndex,
            currentBlock,
            pair.accFeeLong,
            pair.accFeeShort,
            pair.lastAccBlockWeightedMarketCap
        );
    }

    function _setGroupPendingAccFees(
        uint16 groupIndex,
        uint256 currentBlock
    ) private returns (uint64 accFeeLong, uint64 accFeeShort) {
        int256 delta;
        (accFeeLong, accFeeShort, delta) = getGroupPendingAccFees(groupIndex, currentBlock);

        Group storage group = groups[groupIndex];

        (group.accFeeLong, group.accFeeShort) = (accFeeLong, accFeeShort);
        group.accLastUpdatedBlock = ChainUtils.getUint48BlockNumber(currentBlock);
        group.lastAccBlockWeightedMarketCap = getPendingAccBlockWeightedMarketCap(currentBlock);

        emit GroupAccFeesUpdated(
            groupIndex,
            currentBlock,
            group.accFeeLong,
            group.accFeeShort,
            group.lastAccBlockWeightedMarketCap
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IArbSys.sol";


library ChainUtils {

    error ChainUtilsOverflow();

    uint256 public constant ARBITRUM_MAINNET = 42161;
    uint256 public constant ARBITRUM_GOERLI = 421613;
    IArbSys public constant ARB_SYS = IArbSys(address(100));

    function getBlockNumber() internal view returns (uint256) {
        if (block.chainid == ARBITRUM_MAINNET || block.chainid == ARBITRUM_GOERLI) {
            return ARB_SYS.arbBlockNumber();
        }

        return block.number;
    }

    function getUint48BlockNumber(uint256 blockNumber) internal pure returns (uint48) {
        if (blockNumber > type(uint48).max) revert ChainUtilsOverflow();
        return uint48(blockNumber);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPairInfos {
    
    struct TradeInitialAccFees {
        uint256 rollover;  
        int256 funding;  
        bool openedAfterUpdate;
    }

    function tradeInitialAccFees(address, uint256, uint256) external view returns (TradeInitialAccFees memory);

    function maxNegativePnlOnOpenP() external view returns (uint256); 

    function storeTradeInitialAccFees(address trader, uint256 pairIndex, uint256 index, bool long) external;

    function getTradePriceImpact(
        uint256 openPrice, 
        uint256 pairIndex,
        bool long,
        uint256 openInterest 
    )
        external
        view
        returns (
            uint256 priceImpactP, 
            uint256 priceAfterImpact 
        );

    function getTradeRolloverFee(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 collateral 
    ) external view returns (uint256);

    function getTradeFundingFee(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral, 
        uint256 leverage
    )
        external
        view
        returns (
            int256  // Positive => Fee, Negative => Reward
        );

    function getTradeLiquidationPricePure(
        uint256 openPrice, 
        bool long,
        uint256 collateral, 
        uint256 leverage,
        uint256 rolloverFee, 
        int256 fundingFee 
    ) external pure returns (uint256);

    function getTradeLiquidationPrice(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 openPrice, 
        bool long,
        uint256 collateral, 
        uint256 leverage
    ) external view returns (uint256); 

    function getTradeValue(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral,  
        uint256 leverage,
        int256 percentProfit, 
        uint256 closingFee  
    ) external returns (uint256);  

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./TokenInterface.sol";
import "./IWorkPool.sol";
import "./IPairsStorage.sol";
import "./IChainlinkFeed.sol";


interface ITradingStorage {

    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }

    struct Trade {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 positionSizeStable;
        uint256 openPrice;
        bool buy;
        uint256 leverage;
        uint256 tp;
        uint256 sl; 
    }

    struct TradeInfo {
        uint256 tokenId;
        uint256 openInterestStable; 
        uint256 tpLastUpdated;
        uint256 slLastUpdated;
        bool beingMarketClosed;
    }

    struct OpenLimitOrder {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 positionSize;
        bool buy;
        uint256 leverage;
        uint256 tp;
        uint256 sl; 
        uint256 minPrice; 
        uint256 maxPrice; 
        uint256 block;
        uint256 tokenId; // index in supportedTokens
    }

    struct PendingMarketOrder {
        Trade trade;
        uint256 block;
        uint256 wantedPrice; 
        uint256 slippageP;
        uint256 tokenId; // index in supportedTokens
    }

    struct PendingBotOrder {
        address trader;
        uint256 pairIndex;
        uint256 index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint256);

    function gov() external view returns (address);

    function dev() external view returns (address);

    function ref() external view returns (address);

    function devFeesStable() external view returns (uint256);

    function govFeesStable() external view returns (uint256);

    function refFeesStable() external view returns (uint256);

    function stable() external view returns (TokenInterface);

    function token() external view returns (TokenInterface);

    function orderTokenManagement() external view returns (IOrderExecutionTokenManagement);

    function linkErc677() external view returns (TokenInterface);

    function priceAggregator() external view returns (IAggregator01);

    function workPool() external view returns (IWorkPool);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint256, bool) external;

    function transferStable(address, address, uint256) external;

    function transferLinkToAggregator(address, uint256, uint256) external;

    function unregisterTrade(address, uint256, uint256) external;

    function unregisterPendingMarketOrder(uint256, bool) external;

    function unregisterOpenLimitOrder(address, uint256, uint256) external;

    function hasOpenLimitOrder(address, uint256, uint256) external view returns (bool);

    function storePendingMarketOrder(PendingMarketOrder memory, uint256, bool) external;

    function openTrades(address, uint256, uint256) external view returns (Trade memory);

    function openTradesInfo(address, uint256, uint256) external view returns (TradeInfo memory);

    function updateSl(address, uint256, uint256, uint256) external;

    function updateTp(address, uint256, uint256, uint256) external;

    function getOpenLimitOrder(address, uint256, uint256) external view returns (OpenLimitOrder memory);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(uint256) external view returns (PendingMarketOrder memory);

    function storePendingBotOrder(PendingBotOrder memory, uint256) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint256) external view returns (uint256);

    function firstEmptyOpenLimitIndex(address, uint256) external view returns (uint256);

    function reqID_pendingBotOrder(uint256) external view returns (PendingBotOrder memory);

    function updateTrade(Trade memory) external;

    function unregisterPendingBotOrder(uint256) external;

    function handleDevGovRefFees(uint256, uint256, bool, bool) external returns (uint256);

    function storeTrade(Trade memory, TradeInfo memory) external;

    function openLimitOrdersCount(address, uint256) external view returns (uint256);

    function openTradesCount(address, uint256) external view returns (uint256);

    function pendingMarketOpenCount(address, uint256) external view returns (uint256);

    function pendingMarketCloseCount(address, uint256) external view returns (uint256);

    function maxTradesPerPair() external view returns (uint256);

    function pendingOrderIdsCount(address) external view returns (uint256);

    function maxPendingMarketOrders() external view returns (uint256);

    function openInterestStable(uint256, uint256) external view returns (uint256);

    function getPendingOrderIds(address) external view returns (uint256[] memory);

    function pairTradersArray(uint256) external view returns(address[] memory);

    function setWorkPool(address) external;

}


interface IAggregator01 {

    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL
    }

    struct PendingSl {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 openPrice;
        bool buy;
        uint256 newSl;
    }

    function pairsStorage() external view returns (IPairsStorage);

    function getPrice(uint256, OrderType, uint256) external returns (uint256);

    function tokenPriceStable() external returns (uint256);

    function linkFee() external view returns (uint256);

    function openFeeP(uint256) external view returns (uint256);

    function pendingSlOrders(uint256) external view returns (PendingSl memory);

    function storePendingSlOrder(uint256 orderId, PendingSl calldata p) external;

    function unregisterPendingSlOrder(uint256 orderId) external;
}


interface IAggregator02 is IAggregator01 {
    function linkPriceFeed() external view returns (IChainlinkFeed);
}


interface IOrderExecutionTokenManagement {

    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function setOpenLimitOrderType(address, uint256, uint256, OpenLimitOrderType) external;

    function openLimitOrderTypes(address, uint256, uint256) external view returns (OpenLimitOrderType);
    
    function addAggregatorFund() external returns (uint256);
}


interface ITradingCallbacks01 {

    enum TradeType {
        MARKET,
        LIMIT
    }

    struct SimplifiedTradeId {
        address trader;
        uint256 pairIndex;
        uint256 index;
        TradeType tradeType;
    }
    
    struct LastUpdated {
        uint32 tp;
        uint32 sl;
        uint32 limit;
        uint32 created;
    }

    function tradeLastUpdated(address, uint256, uint256, TradeType) external view returns (LastUpdated memory);

    function setTradeLastUpdated(SimplifiedTradeId calldata, LastUpdated memory) external;

    function canExecuteTimeout() external view returns (uint256);

    function pairMaxLeverage(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBorrowingFees {

    struct PairGroup {
        uint16 groupIndex;
        uint48 block;
        uint64 initialAccFeeLong; 
        uint64 initialAccFeeShort; 
        uint64 prevGroupAccFeeLong; 
        uint64 prevGroupAccFeeShort; 
        uint64 pairAccFeeLong; 
        uint64 pairAccFeeShort; 
        uint64 _placeholder; // might be useful later
    }
    struct Pair {
        PairGroup[] groups;
        uint32 feePerBlock; 
        uint64 accFeeLong; 
        uint64 accFeeShort; 
        uint48 accLastUpdatedBlock;
        uint48 _placeholder; // might be useful later
        uint256 lastAccBlockWeightedMarketCap; // 1e40
    }
    struct Group {
        uint112 oiLong; 
        uint112 oiShort; 
        uint32 feePerBlock; 
        uint64 accFeeLong; 
        uint64 accFeeShort; 
        uint48 accLastUpdatedBlock;
        uint80 maxOi; 
        uint256 lastAccBlockWeightedMarketCap; 
    }
    struct InitialAccFees {
        uint64 accPairFee; 
        uint64 accGroupFee; 
        uint48 block;
        uint80 _placeholder; // might be useful later
    }
    struct PairParams {
        uint16 groupIndex;
        uint32 feePerBlock; 
    }
    struct GroupParams {
        uint32 feePerBlock; 
        uint80 maxOi; 
    }
    struct BorrowingFeeInput {
        address trader;
        uint256 pairIndex;
        uint256 index;
        bool long;
        uint256 collateral; 
        uint256 leverage;
    }
    struct LiqPriceInput {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 openPrice; 
        bool long;
        uint256 collateral; 
        uint256 leverage;
    }

    event PairParamsUpdated(uint indexed pairIndex, uint16 indexed groupIndex, uint32 feePerBlock);
    event PairGroupUpdated(uint indexed pairIndex, uint16 indexed prevGroupIndex, uint16 indexed newGroupIndex);
    event GroupUpdated(uint16 indexed groupIndex, uint32 feePerBlock, uint80 maxOi);
    event TradeInitialAccFeesStored(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint64 initialPairAccFee,
        uint64 initialGroupAccFee
    );
    event TradeActionHandled(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        bool open,
        bool long,
        uint256 positionSizeStable 
    );
    event PairAccFeesUpdated(
        uint256 indexed pairIndex,
        uint256 currentBlock,
        uint64 accFeeLong,
        uint64 accFeeShort,
        uint256 accBlockWeightedMarketCap
    );
    event GroupAccFeesUpdated(
        uint16 indexed groupIndex,
        uint256 currentBlock,
        uint64 accFeeLong,
        uint64 accFeeShort,
        uint256 accBlockWeightedMarketCap
    );
    event GroupOiUpdated(
        uint16 indexed groupIndex,
        bool indexed long,
        bool indexed increase,
        uint112 amount,
        uint112 oiLong,
        uint112 oiShort
    );

    function getTradeLiquidationPrice(LiqPriceInput calldata) external view returns (uint256); 

    function getTradeBorrowingFee(BorrowingFeeInput memory) external view returns (uint256); 

    function handleTradeAction(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 positionSizeStable, // (collateral * leverage)
        bool open,
        bool long
    ) external;

    function withinMaxGroupOi(uint256 pairIndex, bool long, uint256 positionSizeStable) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

/**
 * @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface IArbSys {
    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external pure returns (uint256);

    function arbChainID() external view returns (uint256);

    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns (uint256);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(address account) external view returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param dest destination address
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address dest) external pure returns (address);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external view returns (uint256);

    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IChainlinkFeed{
    function latestRoundData() external view returns (uint80,int256,uint256,uint256,uint80);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPairsStorage {

    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint256 maxDeviationP;
    } 

    function incrementCurrentOrderId() external returns (uint256);

    function updateGroupCollateral(uint256, uint256, bool, bool) external;

    function pairJob(uint256) external returns (string memory, string memory, bytes32, uint256);

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

    function pairExecuteLimitOrderFeeP(uint256) external view returns (uint256);

    function pairReferralFeeP(uint256) external view returns (uint256);

    function pairMinLevPosStable(uint256) external view returns (uint256);

    function pairsCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";

interface IWorkPool {
    
    function mainPool() external view returns (address);

    function mainPoolOwner() external view returns (address);

    function currentEpochStart() external view returns (uint256);

    function currentEpochPositiveOpenPnl() external view returns (uint256);

    function updateAccPnlPerTokenUsed(uint256 prevPositiveOpenPnl, uint256 newPositiveOpenPnl) external returns (uint256);

    function sendAssets(uint256 assets, address receiver) external;

    function receiveAssets(uint256 assets, address user) external;

    function distributeReward(uint256 assets) external;

    function currentBalanceStable() external view returns (uint256);

    function tvl() external view returns (uint256);

    function marketCap() external view returns (uint256);

    function getPendingAccBlockWeightedMarketCap(uint256 currentBlock) external view returns (uint256);

    function shareToAssetsPrice() external view returns (uint256);

    function deposit(uint256 assets, address receiver) external returns (uint256);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);

    function refill(uint256 assets) external; 

    function deplete(uint256 assets) external;

    function withdrawEpochsTimelock() external view returns (uint256);

    function collateralizationP() external view returns (uint256); 

    function currentEpoch() external view returns (uint256);

    function accPnlPerTokenUsed() external view returns (int256);

    function accPnlPerToken() external view returns (int256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface TokenInterface{
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}