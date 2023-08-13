// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

enum OrderType {
    Market,
    Limit,
    StopMarket,
    StopLimit
}

enum OrderExecType {
    OpenPosition,
    IncreasePosition,
    DecreasePosition,
    ClosePosition
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./enums.sol";

struct OrderRequest {
    address trader;
    bool isLong;
    bool isIncrease;
    OrderType orderType;
    uint256 marketId;
    uint256 sizeAbs;
    uint256 marginAbs;
    uint256 limitPrice; // empty for market orders
}

struct OpenPosition {
    address trader;
    bool isLong;
    int256 unrealizedPnl; // current unrealized PnL => FIXME: this value should be update in real-time (off-chain or front-end)
    uint256 currentPositionRecordId;
    uint256 marketId;
    // uint256 leverage;
    uint256 size; // Token Counts
    uint256 margin; // Token Counts
    uint256 avgOpenPrice; // TODO: check - should be coupled w/ positions link logic
    uint256 lastUpdatedTime; // Currently not used for any validation
    int256 avgEntryFundingIndex;
}

struct OrderRecord {
    OrderType orderType;
    bool isLong;
    bool isIncrease;
    uint256 positionRecordId;
    uint256 marketId;
    uint256 sizeAbs;
    uint256 marginAbs;
    uint256 executionPrice;
    uint256 timestamp;
}

// decrease, close position에서 호출 필요
struct PositionRecord {
    bool isClosed;
    int256 cumulativeRealizedPnl; // cumulative realized PnL => this value to be closingPnl for closed positions
    uint256 cumulativeClosedSize;
    uint256 marketId;
    uint256 maxSize; // max open interest
    uint256 avgOpenPrice;
    uint256 avgClosePrice; // updated for decreasing/closing the position
    uint256 openTimestamp;
    uint256 closeTimestamp; // only for closed positions
}

struct GlobalPositionState {
    uint256 totalSize;
    uint256 totalMargin;
    uint256 avgPrice;
}

// TODO: check - base asset, quote asset size decimals for submitting an order
struct MarketInfo {
    uint256 marketId;
    uint256 priceTickSize; // in USD, 10^8
    uint256 baseAssetId; // synthetic
    uint256 quoteAssetId; // synthetic
    uint256 longReserveAssetId; // real liquidity
    uint256 shortReserveAssetId; // real liquidity
    uint256 marginAssetId;
    int256 fundingRateMultiplier;
    address marketMakerToken;
}
struct TokenData {
    uint256 decimals;
    uint256 sizeToPriceBufferDeltaMultiplier;
    address tokenAddress;
    // string symbol;
    // string name;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../common/structs.sol";

contract Market {
    mapping(uint256 => MarketInfo) public markets; // marketId => MarketInfo
    uint256 public globalMarketIdCounter = 0; // TODO: choose when to update - before / after the market is created

    function getMarketInfo(
        uint256 _marketId
    ) external view returns (MarketInfo memory) {
        return markets[_marketId];
    }

    function getMarketIdCounter() external view returns (uint256) {
        return globalMarketIdCounter;
    }

    function getPriceTickSize(
        uint256 _marketId
    ) external view returns (uint256) {
        MarketInfo memory marketInfo = markets[_marketId];
        require(
            marketInfo.priceTickSize != 0,
            "MarketVault: priceTickSize not set"
        );
        return marketInfo.priceTickSize;
    }

    function setPriceTickSize(
        uint256 _marketId,
        uint256 _tickSizeInUsd
    ) public {
        // TODO: only owner
        // TODO: event - shows the previous tick size
        MarketInfo storage marketInfo = markets[_marketId];
        marketInfo.priceTickSize = _tickSizeInUsd;
    }
}