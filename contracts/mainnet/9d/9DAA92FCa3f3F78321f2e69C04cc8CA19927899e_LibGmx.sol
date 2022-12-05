// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../interfaces/IGmxOrderBook.sol";
import "../../../interfaces/IGmxPositionRouter.sol";
import "../../../interfaces/IGmxVault.sol";
import "../../../interfaces/IWETH.sol";

import "../Type.sol";

library LibGmx {
    using SafeERC20 for IERC20;

    enum OrderCategory {
        NONE,
        OPEN,
        CLOSE,
        LIQUIDATE
    }

    enum OrderReceiver {
        PR_INC,
        PR_DEC,
        OB_INC,
        OB_DEC
    }

    struct OrderHistory {
        OrderCategory category; // 4
        OrderReceiver receiver; // 4
        uint64 index; // 64
        uint96 borrow; // 96
        uint88 timestamp; // 80
    }

    function getOraclePrice(
        ProjectConfigs storage projectConfigs,
        address token,
        bool useMaxPrice
    ) internal view returns (uint256 price) {
        // open long = max
        // open short = min
        // close long = min
        // close short = max
        price = useMaxPrice //isOpen == isLong
            ? IGmxVault(projectConfigs.vault).getMaxPrice(token)
            : IGmxVault(projectConfigs.vault).getMinPrice(token);
        require(price != 0, "ZeroOraclePrice");
    }

    function swap(
        ProjectConfigs memory projectConfigs,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minOut
    ) internal returns (uint256 amountOut) {
        IERC20(tokenIn).safeTransfer(projectConfigs.vault, amountIn);
        amountOut = IGmxVault(projectConfigs.vault).swap(tokenIn, tokenOut, address(this));
        require(amountOut >= minOut, "AmountOutNotReached");
    }

    function getOrderIndex(ProjectConfigs memory projectConfigs, OrderReceiver receiver)
        internal
        view
        returns (uint256 index)
    {
        if (receiver == OrderReceiver.PR_INC) {
            index = IGmxPositionRouter(projectConfigs.positionRouter).increasePositionsIndex(address(this));
        } else if (receiver == OrderReceiver.PR_DEC) {
            index = IGmxPositionRouter(projectConfigs.positionRouter).decreasePositionsIndex(address(this));
        } else if (receiver == OrderReceiver.OB_INC) {
            index = IGmxOrderBook(projectConfigs.orderBook).increaseOrdersIndex(address(this)) - 1;
        } else if (receiver == OrderReceiver.OB_DEC) {
            index = IGmxOrderBook(projectConfigs.orderBook).decreaseOrdersIndex(address(this)) - 1;
        }
    }

    function getOrder(ProjectConfigs memory projectConfigs, bytes32 key)
        internal
        view
        returns (bool isFilled, OrderHistory memory history)
    {
        history = decodeOrderHistoryKey(key);
        if (history.receiver == OrderReceiver.PR_INC) {
            IGmxPositionRouter.IncreasePositionRequest memory request = IGmxPositionRouter(
                projectConfigs.positionRouter
            ).increasePositionRequests(encodeOrderKey(address(this), history.index));
            isFilled = request.account == address(0);
        } else if (history.receiver == OrderReceiver.PR_DEC) {
            IGmxPositionRouter.DecreasePositionRequest memory request = IGmxPositionRouter(
                projectConfigs.positionRouter
            ).decreasePositionRequests(encodeOrderKey(address(this), history.index));
            isFilled = request.account == address(0);
        } else if (history.receiver == OrderReceiver.OB_INC) {
            (address collateralToken, , , , , , , , ) = IGmxOrderBook(projectConfigs.orderBook).getIncreaseOrder(
                address(this),
                history.index
            );
            isFilled = collateralToken == address(0);
        } else if (history.receiver == OrderReceiver.OB_DEC) {
            (address collateralToken, , , , , , , ) = IGmxOrderBook(projectConfigs.orderBook).getDecreaseOrder(
                address(this),
                history.index
            );
            isFilled = collateralToken == address(0);
        } else {
            revert();
        }
    }

    function cancelOrderFromPositionRouter(address positionRouter, bytes32 key) internal returns (bool success) {
        OrderHistory memory history = decodeOrderHistoryKey(key);
        success = false;
        if (history.receiver == OrderReceiver.PR_INC) {
            try
                IGmxPositionRouter(positionRouter).cancelIncreasePosition(
                    encodeOrderKey(address(this), history.index),
                    payable(address(this))
                )
            returns (bool _success) {
                success = _success;
            } catch {}
        } else if (history.receiver == OrderReceiver.PR_DEC) {
            try
                IGmxPositionRouter(positionRouter).cancelDecreasePosition(
                    encodeOrderKey(address(this), history.index),
                    payable(address(this))
                )
            returns (bool _success) {
                success = _success;
            } catch {}
        }
    }

    function cancelOrderFromOrderBook(address orderBook, bytes32 key) internal returns (bool success) {
        OrderHistory memory history = decodeOrderHistoryKey(key);
        success = false;
        if (history.receiver == OrderReceiver.OB_INC) {
            try IGmxOrderBook(orderBook).cancelIncreaseOrder(history.index) {
                success = true;
            } catch {}
        } else if (history.receiver == OrderReceiver.OB_DEC) {
            try IGmxOrderBook(orderBook).cancelDecreaseOrder(history.index) {
                success = true;
            } catch {}
        }
    }

    function cancelOrder(ProjectConfigs memory projectConfigs, bytes32 key) public returns (bool success) {
        OrderHistory memory history = decodeOrderHistoryKey(key);
        success = false;
        if (history.receiver == OrderReceiver.PR_INC) {
            try
                IGmxPositionRouter(projectConfigs.positionRouter).cancelIncreasePosition(
                    encodeOrderKey(address(this), history.index),
                    payable(address(this))
                )
            returns (bool _success) {
                success = _success;
            } catch {}
        } else if (history.receiver == OrderReceiver.PR_DEC) {
            try
                IGmxPositionRouter(projectConfigs.positionRouter).cancelDecreasePosition(
                    encodeOrderKey(address(this), history.index),
                    payable(address(this))
                )
            returns (bool _success) {
                success = _success;
            } catch {}
        } else if (history.receiver == OrderReceiver.OB_INC) {
            try IGmxOrderBook(projectConfigs.orderBook).cancelIncreaseOrder(history.index) {
                success = true;
            } catch {}
        } else if (history.receiver == OrderReceiver.OB_DEC) {
            try IGmxOrderBook(projectConfigs.orderBook).cancelDecreaseOrder(history.index) {
                success = true;
            } catch {}
        } else {
            revert();
        }
    }

    function getPnl(
        ProjectConfigs memory projectConfigs,
        address indexToken,
        uint256 size,
        uint256 averagePriceUsd,
        bool isLong,
        uint256 priceUsd,
        uint256 lastIncreasedTime
    ) public view returns (bool, uint256) {
        require(priceUsd > 0, "");
        uint256 priceDelta = averagePriceUsd > priceUsd ? averagePriceUsd - priceUsd : priceUsd - averagePriceUsd;
        uint256 delta = (size * priceDelta) / averagePriceUsd;
        bool hasProfit;
        if (isLong) {
            hasProfit = priceUsd > averagePriceUsd;
        } else {
            hasProfit = averagePriceUsd > priceUsd;
        }
        uint256 minProfitTime = IGmxVault(projectConfigs.vault).minProfitTime();
        uint256 minProfitBasisPoints = IGmxVault(projectConfigs.vault).minProfitBasisPoints(indexToken);
        uint256 minBps = block.timestamp > lastIncreasedTime + minProfitTime ? 0 : minProfitBasisPoints;
        if (hasProfit && delta * 10000 <= size * minBps) {
            delta = 0;
        }
        return (hasProfit, delta);
    }

    function encodeOrderKey(address account, uint256 index) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, index));
    }

    function decodeOrderHistoryKey(bytes32 key) internal pure returns (OrderHistory memory history) {
        //            252          248                184          88           0
        // +------------+------------+------------------+-----------+-----------+
        // | category 4 | receiver 4 | gmxOrderIndex 64 | borrow 96 |  time 88  |
        // +------------+------------+------------------+-----------+-----------+
        history.category = OrderCategory(uint8(bytes1(key)) >> 4);
        history.receiver = OrderReceiver(uint8(bytes1(key)) & 0x0f);
        history.index = uint64(bytes8(key << 8));
        history.borrow = uint96(uint256(key >> 88));
        history.timestamp = uint88(uint256(key));
    }

    function encodeOrderHistoryKey(
        OrderCategory category,
        OrderReceiver receiver,
        uint256 index,
        uint256 borrow,
        uint256 timestamp
    ) internal pure returns (bytes32 data) {
        //            252          248                184          88           0
        // +------------+------------+------------------+-----------+-----------+
        // | category 4 | receiver 4 | gmxOrderIndex 64 | borrow 96 |  time 88  |
        // +------------+------------+------------------+-----------+-----------+
        require(index < type(uint64).max, "GmxOrderIndexOverflow");
        require(borrow < type(uint96).max, "BorrowOverflow");
        require(timestamp < type(uint88).max, "FeeOverflow");
        data =
            bytes32(uint256(category) << 252) | // 256 - 4
            bytes32(uint256(receiver) << 248) | // 256 - 4 - 4
            bytes32(uint256(index) << 184) | // 256 - 4 - 4 - 64
            bytes32(uint256(borrow) << 88) | // 256 - 4 - 4 - 64 - 96
            bytes32(uint256(timestamp));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGmxOrderBook {
    event CreateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event CancelIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 sizeDelta,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );
    event CreateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event CancelDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );

    function minExecutionFee() external view returns (uint256);

    function getIncreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function increaseOrdersIndex(address account) external view returns (uint256);

    function decreaseOrdersIndex(address account) external view returns (uint256);

    function cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external;

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function cancelIncreaseOrder(uint256 _orderIndex) external;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function cancelDecreaseOrder(uint256 _orderIndex) external;

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function executeDecreaseOrder(
        address,
        uint256,
        address payable
    ) external;

    function executeIncreaseOrder(
        address,
        uint256,
        address payable
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGmxPositionRouter {
    struct IncreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
    }

    struct DecreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
    }

    function setPositionKeeper(address _account, bool _isActive) external;

    function increasePositionRequests(bytes32) external view returns (IncreasePositionRequest memory);

    function decreasePositionRequests(bytes32) external view returns (DecreasePositionRequest memory);

    function minExecutionFee() external view returns (uint256);

    function increasePositionsIndex(address account) external view returns (uint256);

    function decreasePositionsIndex(address account) external view returns (uint256);

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function cancelIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool); // callback

    function cancelDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool); // callback

    function executeIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function executeDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGmxVault {
    struct Position {
        uint256 sizeUsd;
        uint256 collateralUsd;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnlUsd;
        uint256 lastIncreasedTime;
    }

    event BuyUSDG(address account, address token, uint256 tokenAmount, uint256 usdgAmount, uint256 feeBasisPoints);
    event SellUSDG(address account, address token, uint256 usdgAmount, uint256 tokenAmount, uint256 feeBasisPoints);
    event Swap(
        address account,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 amountOutAfterFees,
        uint256 feeBasisPoints
    );

    event IncreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event DecreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event LiquidatePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 size,
        uint256 collateral,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl
    );

    event UpdateFundingRate(address token, uint256 fundingRate);
    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta);

    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event CollectMarginFees(address token, uint256 feeUsd, uint256 feeTokens);

    event DirectPoolDeposit(address token, uint256 amount);
    event IncreasePoolAmount(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event IncreaseUsdgAmount(address token, uint256 amount);
    event DecreaseUsdgAmount(address token, uint256 amount);
    event IncreaseReservedAmount(address token, uint256 amount);
    event DecreaseReservedAmount(address token, uint256 amount);
    event IncreaseGuaranteedUsd(address token, uint256 amount);
    event DecreaseGuaranteedUsd(address token, uint256 amount);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        uint256 _lastIncreasedTime
    ) external view returns (uint256);

    function positions(bytes32 key) external view returns (Position memory);

    /**
     * [0] size,
     * [1] collateral,
     * [2] averagePrice,
     * [3] entryFundingRate,
     * [4] reserveAmount,
     * [5] realisedPnl,
     * [6] realisedPnl >= 0,
     * [7] lastIncreasedTime
     */
    function getPosition(
        address account,
        address collateralToken,
        address indexToken,
        bool isLong
    )
        external
        view
        returns (
            uint256 size,
            uint256 collateral,
            uint256 averagePrice,
            uint256 entryFundingRate,
            uint256 reserveAmount,
            uint256 realisedPnl,
            bool hasRealisedPnl,
            uint256 lastIncreasedTime
        );

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function usdgAmounts(address) external view returns (uint256);

    function tokenWeights(address) external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function priceFeed() external view returns (address);

    function poolAmounts(address token) external view returns (uint256);

    function bufferAmounts(address token) external view returns (uint256);

    function reservedAmounts(address token) external view returns (uint256);

    function getRedemptionAmount(address token, uint256 usdgAmount) external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function minProfitBasisPoints(address token) external view returns (uint256);

    function maxUsdgAmounts(address token) external view returns (uint256);

    function globalShortSizes(address token) external view returns (uint256);

    function maxGlobalShortSizes(address token) external view returns (uint256);

    function guaranteedUsd(address token) external view returns (uint256);

    function stableTokens(address token) external view returns (bool);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(address token) external view returns (uint256);

    function getNextFundingRate(address token) external view returns (uint256);

    function getEntryFundingRate(
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function gov() external view returns (address);

    function setLiquidator(address, bool) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

enum ProjectConfigIds {
    VAULT,
    POSITION_ROUTER,
    ORDER_BOOK,
    ROUTER,
    REFERRAL_CODE,
    MARKET_ORDER_TIMEOUT_SECONDS,
    LIMIT_ORDER_TIMEOUT_SECONDS,
    FUNDING_ASSET_ID,
    END
}

enum TokenConfigIds {
    BOOST_FEE_RATE,
    INITIAL_MARGIN_RATE,
    MAINTENANCE_MARGIN_RATE,
    LIQUIDATION_FEE_RATE,
    REFERRENCE_ORACLE,
    REFERRENCE_ORACLE_DEVIATION,
    END
}

struct ProjectConfigs {
    address vault;
    address positionRouter;
    address orderBook;
    address router;
    bytes32 referralCode;
    // ========================
    uint32 marketOrderTimeoutSeconds;
    uint32 limitOrderTimeoutSeconds;
    uint8 fundingAssetId;
    bytes32[19] reserved;
}

struct TokenConfigs {
    address referrenceOracle;
    // --------------------------
    uint32 referenceDeviation;
    uint32 boostFeeRate;
    uint32 initialMarginRate;
    uint32 maintenanceMarginRate;
    uint32 liquidationFeeRate;
    // --------------------------
    bytes32[20] reserved;
}

struct AccountState {
    address account;
    uint256 cumulativeDebt;
    uint256 cumulativeFee;
    uint256 debtEntryFunding;
    address collateralToken;
    // --------------------------
    address indexToken; // 160
    uint8 deprecated0; // 8
    bool isLong; // 8
    uint8 collateralDecimals;
    // reserve 80
    // --------------------------
    uint256 liquidationFee;
    bool isLiquidating;
    bytes32[18] reserved;
}

struct OpenPositionContext {
    // parameters
    uint256 amountIn;
    uint256 sizeUsd;
    uint256 priceUsd;
    bool isMarket;
    // calculated
    uint256 fee;
    uint256 borrow;
    uint256 amountOut;
    uint256 gmxOrderIndex;
    uint256 executionFee;
}

struct ClosePositionContext {
    uint256 collateralUsd;
    uint256 sizeUsd;
    uint256 priceUsd;
    bool isMarket;
    uint256 gmxOrderIndex;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}