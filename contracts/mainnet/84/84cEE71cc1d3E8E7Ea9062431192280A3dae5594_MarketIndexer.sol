// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IMarketDescriptor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Configurable Interface
/// @notice This interface defines the functions for manage USD stablecoins and market configurations
interface IConfigurable {
    struct MarketConfig {
        MarketBaseConfig baseConfig;
        MarketFeeRateConfig feeRateConfig;
        MarketPriceConfig priceConfig;
    }

    struct MarketBaseConfig {
        // ==================== LP Position Configuration ====================
        /// @notice The minimum entry margin required for per LP position, for example, 10_000_000 means the minimum
        /// entry margin is 10 USD
        uint64 minMarginPerLiquidityPosition;
        /// @notice The maximum leverage for per LP position, for example, 100 means the maximum leverage is 100 times
        uint32 maxLeveragePerLiquidityPosition;
        /// @notice The liquidation fee rate for per LP position,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 liquidationFeeRatePerLiquidityPosition;
        // ==================== Trader Position Configuration ==================
        /// @notice The minimum entry margin required for per trader position, for example, 10_000_000 means
        /// the minimum entry margin is 10 USD
        uint64 minMarginPerPosition;
        /// @notice The maximum leverage for per trader position, for example, 100 means the maximum leverage
        /// is 100 times
        uint32 maxLeveragePerPosition;
        /// @notice The liquidation fee rate for per trader position,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 liquidationFeeRatePerPosition;
        /// @notice The maximum available liquidity used to calculate the maximum size
        /// of the trader's position
        uint128 maxPositionLiquidity;
        /// @notice The maximum value of all positions relative to `maxPositionLiquidity`,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        /// @dev The maximum position value rate is used to calculate the maximum size of
        /// the trader's position, the formula is
        /// `maxSize = maxPositionValueRate * min(liquidity, maxPositionLiquidity) / maxIndexPrice`
        uint32 maxPositionValueRate;
        /// @notice The maximum size of per position relative to `maxSize`,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        /// @dev The maximum size per position rate is used to calculate the maximum size of
        /// the trader's position, the formula is
        /// `maxSizePerPosition = maxSizeRatePerPosition
        ///                       * maxPositionValueRate * min(liquidity, maxPositionLiquidity) / maxIndexPrice`
        uint32 maxSizeRatePerPosition;
        // ==================== Other Configuration ==========================
        /// @notice The liquidation execution fee for LP and trader positions
        uint64 liquidationExecutionFee;
    }

    struct MarketFeeRateConfig {
        /// @notice The protocol funding fee rate as a percentage of funding fee,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 protocolFundingFeeRate;
        /// @notice A coefficient used to adjust how funding fees are paid to the market,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 fundingCoeff;
        /// @notice A coefficient used to adjust how funding fees are distributed between long and short positions,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 protocolFundingCoeff;
        /// @notice The interest rate used to calculate the funding rate,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 interestRate;
        /// @notice The funding buffer, denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 fundingBuffer;
        /// @notice The liquidity funding fee rate, denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 liquidityFundingFeeRate;
        /// @notice The maximum funding rate, denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 maxFundingRate;
    }

    struct VertexConfig {
        /// @notice The balance rate of the vertex, denominated in a bip (i.e. 1e-8)
        uint32 balanceRate;
        /// @notice The premium rate of the vertex, denominated in a bip (i.e. 1e-8)
        uint32 premiumRate;
    }

    struct MarketPriceConfig {
        /// @notice The maximum available liquidity used to calculate the premium rate
        /// when trader increase or decrease positions
        uint128 maxPriceImpactLiquidity;
        /// @notice The index used to store the net position of the liquidation
        uint8 liquidationVertexIndex;
        /// @notice The dynamic depth mode used to determine the formula for calculating the trade price
        uint8 dynamicDepthMode;
        /// @notice The dynamic depth level used to calculate the trade price,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 dynamicDepthLevel;
        VertexConfig[10] vertices;
    }

    /// @notice Emitted when a USD stablecoin is enabled
    /// @param usd The ERC20 token representing the USD stablecoin used in markets
    event USDEnabled(IERC20 indexed usd);

    /// @notice Emitted when a market is enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param baseCfg The new market base configuration
    /// @param feeRateCfg The new market fee rate configuration
    /// @param priceCfg The new market price configuration
    event MarketConfigEnabled(
        IMarketDescriptor indexed market,
        MarketBaseConfig baseCfg,
        MarketFeeRateConfig feeRateCfg,
        MarketPriceConfig priceCfg
    );

    /// @notice Emitted when a market configuration is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market base configuration
    event MarketBaseConfigChanged(IMarketDescriptor indexed market, MarketBaseConfig newCfg);

    /// @notice Emitted when a market fee rate configuration is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market fee rate configuration
    event MarketFeeRateConfigChanged(IMarketDescriptor indexed market, MarketFeeRateConfig newCfg);

    /// @notice Emitted when a market price configuration is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market price configuration
    event MarketPriceConfigChanged(IMarketDescriptor indexed market, MarketPriceConfig newCfg);

    /// @notice Market is not enabled
    error MarketNotEnabled(IMarketDescriptor market);
    /// @notice Market is already enabled
    error MarketAlreadyEnabled(IMarketDescriptor market);
    /// @notice Invalid maximum leverage for LP positions
    error InvalidMaxLeveragePerLiquidityPosition(uint32 maxLeveragePerLiquidityPosition);
    /// @notice Invalid liquidation fee rate for LP positions
    error InvalidLiquidationFeeRatePerLiquidityPosition(uint32 invalidLiquidationFeeRatePerLiquidityPosition);
    /// @notice Invalid maximum leverage for trader positions
    error InvalidMaxLeveragePerPosition(uint32 maxLeveragePerPosition);
    /// @notice Invalid liquidation fee rate for trader positions
    error InvalidLiquidationFeeRatePerPosition(uint32 liquidationFeeRatePerPosition);
    /// @notice Invalid maximum position value
    error InvalidMaxPositionLiquidity(uint128 maxPositionLiquidity);
    /// @notice Invalid maximum position value rate
    error InvalidMaxPositionValueRate(uint32 maxPositionValueRate);
    /// @notice Invalid maximum size per rate for per psoition
    error InvalidMaxSizeRatePerPosition(uint32 maxSizeRatePerPosition);
    /// @notice Invalid protocol funding fee rate
    error InvalidProtocolFundingFeeRate(uint32 protocolFundingFeeRate);
    /// @notice Invalid funding coefficient
    error InvalidFundingCoeff(uint32 fundingCoeff);
    /// @notice Invalid protocol funding coefficient
    error InvalidProtocolFundingCoeff(uint32 protocolFundingCoeff);
    /// @notice Invalid interest rate
    error InvalidInterestRate(uint32 interestRate);
    /// @notice Invalid funding buffer
    error InvalidFundingBuffer(uint32 fundingBuffer);
    /// @notice Invalid liquidity funding fee rate
    error InvalidLiquidityFundingFeeRate(uint32 liquidityFundingFeeRate);
    /// @notice Invalid maximum funding rate
    error InvalidMaxFundingRate(uint32 maxFundingRate);
    /// @notice Invalid maximum price impact liquidity
    error InvalidMaxPriceImpactLiquidity(uint128 maxPriceImpactLiquidity);
    /// @notice Invalid vertices length
    /// @dev The length of vertices must be equal to the `VERTEX_NUM`
    error InvalidVerticesLength(uint256 length, uint256 requiredLength);
    /// @notice Invalid liquidation vertex index
    /// @dev The liquidation vertex index must be less than the length of vertices
    error InvalidLiquidationVertexIndex(uint8 liquidationVertexIndex);
    /// @notice Invalid vertex
    /// @param index The index of the vertex
    error InvalidVertex(uint8 index);
    /// @notice Invalid dynamic depth level
    error InvalidDynamicDepthLevel(uint32 dynamicDepthLevel);

    /// @notice Get the USD stablecoin used in markets
    /// @return The ERC20 token representing the USD stablecoin used in markets
    function USD() external view returns (IERC20);

    /// @notice Checks if a market is enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @return True if the market is enabled, false otherwise
    function isEnabledMarket(IMarketDescriptor market) external view returns (bool);

    /// @notice Get market configuration
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function marketBaseConfigs(IMarketDescriptor market) external view returns (MarketBaseConfig memory);

    /// @notice Get market fee rate configuration
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function marketFeeRateConfigs(IMarketDescriptor market) external view returns (MarketFeeRateConfig memory);

    /// @notice Get market price configuration
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function marketPriceConfigs(IMarketDescriptor market) external view returns (MarketPriceConfig memory);

    /// @notice Get market price vertex configuration
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param index The index of the vertex
    function marketPriceVertexConfigs(
        IMarketDescriptor market,
        uint8 index
    ) external view returns (VertexConfig memory);

    /// @notice Enable a market
    /// @dev The call will fail if caller is not the governor or the market is already enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param cfg The market configuration
    function enableMarket(IMarketDescriptor market, MarketConfig calldata cfg) external;

    /// @notice Update a market configuration
    /// @dev The call will fail if caller is not the governor or the market is not enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market base configuration
    function updateMarketBaseConfig(IMarketDescriptor market, MarketBaseConfig calldata newCfg) external;

    /// @notice Update a market fee rate configuration
    /// @dev The call will fail if caller is not the governor or the market is not enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market fee rate configuration
    function updateMarketFeeRateConfig(IMarketDescriptor market, MarketFeeRateConfig calldata newCfg) external;

    /// @notice Update a market price configuration
    /// @dev The call will fail if caller is not the governor or the market is not enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market price configuration
    function updateMarketPriceConfig(IMarketDescriptor market, MarketPriceConfig calldata newCfg) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IMarketDescriptor {
    /// @notice Error thrown when the symbol is already initialized
    error SymbolAlreadyInitialized();

    /// @notice Get the name of the market
    function name() external view returns (string memory);

    /// @notice Get the symbol of the market
    function symbol() external view returns (string memory);

    /// @notice Get the size decimals of the market
    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Side} from "../../types/Side.sol";

interface IMarketErrors {
    /// @notice Liquidity is not enough to open a liquidity position
    error InvalidLiquidityToOpen();
    /// @notice Invalid caller
    error InvalidCaller(address requiredCaller);
    /// @notice Insufficient size to decrease
    error InsufficientSizeToDecrease(uint128 size, uint128 requiredSize);
    /// @notice Insufficient margin
    error InsufficientMargin();
    /// @notice Position not found
    error PositionNotFound(address requiredAccount, Side requiredSide);
    /// @notice Size exceeds max size per position
    error SizeExceedsMaxSizePerPosition(uint128 requiredSize, uint128 maxSizePerPosition);
    /// @notice Size exceeds max size
    error SizeExceedsMaxSize(uint128 requiredSize, uint128 maxSize);
    /// @notice Liquidity position not found
    error LiquidityPositionNotFound(address requiredAccount);
    /// @notice Insufficient liquidity to decrease
    error InsufficientLiquidityToDecrease(uint256 liquidity, uint128 requiredLiquidity);
    /// @notice Last liquidity position cannot be closed
    error LastLiquidityPositionCannotBeClosed();
    /// @notice Caller is not the liquidator
    error CallerNotLiquidator();
    /// @notice Insufficient balance
    error InsufficientBalance(uint256 balance, uint256 requiredAmount);
    /// @notice Leverage is too high
    error LeverageTooHigh(uint256 margin, uint128 liquidity, uint32 maxLeverage);
    /// @notice Insufficient global liquidity
    error InsufficientGlobalLiquidity();
    /// @notice Risk rate is too high
    error RiskRateTooHigh(int256 margin, uint256 maintenanceMargin);
    /// @notice Risk rate is too low
    error RiskRateTooLow(int256 margin, uint256 maintenanceMargin);
    /// @notice Position margin rate is too low
    error MarginRateTooLow(int256 margin, int256 unrealizedPnL, uint256 maintenanceMargin);
    /// @notice Position margin rate is too high
    error MarginRateTooHigh(int256 margin, int256 unrealizedPnL, uint256 maintenanceMargin);
    /// @notice Emitted when premium rate overflows, should stop calculation
    error MaxPremiumRateExceeded();
    /// @notice Emitted when size delta is zero
    error ZeroSizeDelta();
    /// @notice The liquidation fund is experiencing losses
    error LiquidationFundLoss();
    /// @notice Insufficient liquidation fund
    error InsufficientLiquidationFund(uint128 requiredRiskBufferFund);
    /// @notice Emitted when trade price is invalid
    error InvalidTradePrice(int256 tradePriceX96TimesSizeTotal);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IMarketDescriptor.sol";
import {Side} from "../../types/Side.sol";

/// @notice Interface for managing liquidity positions
/// @dev The market liquidity position is the core component of the protocol, which stores the information of
/// all LP's positions.
interface IMarketLiquidityPosition {
    struct GlobalLiquidityPosition {
        /// @notice The size of the net position held by all LPs
        uint128 netSize;
        /// @notice The size of the net position held by all LPs in the liquidation buffer
        uint128 liquidationBufferNetSize;
        /// @notice The Previous Settlement Point Price, as a Q64.96
        uint160 previousSPPriceX96;
        /// @notice The side of the position (Long or Short)
        Side side;
        /// @notice The total liquidity of all LPs
        uint128 liquidity;
        /// @notice The accumulated unrealized Profit and Loss (PnL) growth per liquidity unit, as a Q192.64.
        /// The value is updated when the following actions are performed:
        ///     1. Settlement Point is reached
        ///     2. Funding fee is added
        ///     3. Liquidation loss is added
        int256 unrealizedPnLGrowthX64;
        uint256[50] __gap;
    }

    struct LiquidityPosition {
        /// @notice The margin of the position
        uint128 margin;
        /// @notice The liquidity (value) of the position
        uint128 liquidity;
        /// @notice The snapshot of `GlobalLiquidityPosition.realizedProfitGrowthX64`
        /// at the time of the position was opened.
        int256 entryUnrealizedPnLGrowthX64;
        uint256[50] __gap;
    }

    /// @notice Emitted when the global liquidity position net position changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param sideAfter The adjusted side of the net position
    /// @param netSizeAfter The adjusted net position size
    /// @param liquidationBufferNetSizeAfter The adjusted net position size in the liquidation buffer
    event GlobalLiquidityPositionNetPositionChanged(
        IMarketDescriptor indexed market,
        Side sideAfter,
        uint128 netSizeAfter,
        uint128 liquidationBufferNetSizeAfter
    );

    /// @notice Emitted when the position margin/liquidity (value) is increased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param marginDelta The increased margin
    /// @param marginAfter The adjusted margin
    /// @param liquidityAfter The adjusted liquidity
    /// @param realizedPnLDelta The realized PnL of the position
    event LiquidityPositionIncreased(
        IMarketDescriptor indexed market,
        address indexed account,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 liquidityAfter,
        int256 realizedPnLDelta
    );

    /// @notice Emitted when the position margin/liquidity (value) is decreased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param marginDelta The decreased margin
    /// @param marginAfter The adjusted margin
    /// @param liquidityAfter The adjusted liquidity
    /// @param realizedPnLDelta The realized PnL of the position
    /// @param receiver The address that receives the margin
    event LiquidityPositionDecreased(
        IMarketDescriptor indexed market,
        address indexed account,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 liquidityAfter,
        int256 realizedPnLDelta,
        address receiver
    );

    /// @notice Emitted when a position is liquidated
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidator The address that executes the liquidation of the position
    /// @param liquidationLoss The loss of the liquidated position.
    /// If it is a negative number, it means that the remaining LP bears this part of the loss,
    /// otherwise it means that the `Liquidation Fund` gets this part of the liquidation fee.
    /// @param unrealizedPnLGrowthAfterX64 The adjusted `GlobalLiquidityPosition.unrealizedPnLGrowthX64`, as a Q192.64
    /// @param feeReceiver The address that receives the liquidation execution fee
    event LiquidityPositionLiquidated(
        IMarketDescriptor indexed market,
        address indexed account,
        address indexed liquidator,
        int256 liquidationLoss,
        int256 unrealizedPnLGrowthAfterX64,
        address feeReceiver
    );

    /// @notice Emitted when the previous Settlement Point Price is initialized
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param previousSPPriceX96 The adjusted `GlobalLiquidityPosition.previousSPPriceX96`, as a Q64.96
    event PreviousSPPriceInitialized(IMarketDescriptor indexed market, uint160 previousSPPriceX96);

    /// @notice Emitted when the Settlement Point is reached
    /// @dev Settlement Point is triggered by the following 6 actions:
    ///     1. increaseLiquidityPosition
    ///     2. decreaseLiquidityPosition
    ///     3. liquidateLiquidityPosition
    ///     4. increasePosition
    ///     5. decreasePosition
    ///     6. liquidatePosition
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param unrealizedPnLGrowthAfterX64 The adjusted `GlobalLiquidityPosition.unrealizedPnLGrowthX64`, as a Q192.64
    /// @param previousSPPriceAfterX96 The adjusted `GlobalLiquidityPosition.previousSPPriceX96`, as a Q64.96
    event SettlementPointReached(
        IMarketDescriptor indexed market,
        int256 unrealizedPnLGrowthAfterX64,
        uint160 previousSPPriceAfterX96
    );

    /// @notice Emitted when the global liquidity position is increased by funding fee
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param unrealizedPnLGrowthAfterX64 The adjusted `GlobalLiquidityPosition.unrealizedPnLGrowthX64`, as a Q192.64
    event GlobalLiquidityPositionPnLGrowthIncreasedByFundingFee(
        IMarketDescriptor indexed market,
        int256 unrealizedPnLGrowthAfterX64
    );

    /// @notice Get the global liquidity position of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function globalLiquidityPositions(IMarketDescriptor market) external view returns (GlobalLiquidityPosition memory);

    /// @notice Get the information of a liquidity position
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    function liquidityPositions(
        IMarketDescriptor market,
        address account
    ) external view returns (LiquidityPosition memory);

    /// @notice Increase the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param marginDelta The increase in margin, which can be 0
    /// @param liquidityDelta The increase in liquidity, which can be 0
    /// @return marginAfter The margin after increasing the position
    function increaseLiquidityPosition(
        IMarketDescriptor market,
        address account,
        uint128 marginDelta,
        uint128 liquidityDelta
    ) external returns (uint128 marginAfter);

    /// @notice Decrease the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param marginDelta The decrease in margin, which can be 0
    /// @param liquidityDelta The decrease in liquidity, which can be 0
    /// @param receiver The address to receive the margin at the time of closing
    /// @return marginAfter The margin after decreasing the position
    function decreaseLiquidityPosition(
        IMarketDescriptor market,
        address account,
        uint128 marginDelta,
        uint128 liquidityDelta,
        address receiver
    ) external returns (uint128 marginAfter);

    /// @notice Liquidate a liquidity position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param feeReceiver The address to receive the liquidation execution fee
    function liquidateLiquidityPosition(IMarketDescriptor market, address account, address feeReceiver) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IConfigurable.sol";
import "./IMarketErrors.sol";
import "./IMarketPosition.sol";
import "./IMarketLiquidityPosition.sol";
import "../../oracle/interfaces/IPriceFeed.sol";

interface IMarketManager is IMarketErrors, IMarketPosition, IMarketLiquidityPosition, IConfigurable {
    struct PriceVertex {
        /// @notice The available size when the price curve moves to this vertex
        uint128 size;
        /// @notice The premium rate when the price curve moves to this vertex, as a Q32.96
        uint128 premiumRateX96;
    }

    struct PriceState {
        /// @notice The premium rate during the last position adjustment by the trader, as a Q32.96
        uint128 premiumRateX96;
        /// @notice The index used to track the pending update of the price vertex
        uint8 pendingVertexIndex;
        /// @notice The index used to track the current used price vertex
        uint8 currentVertexIndex;
        /// @notice The basis index price, as a Q64.96
        uint160 basisIndexPriceX96;
        /// @notice The price vertices used to determine the price curve
        PriceVertex[10] priceVertices;
        /// @notice The net sizes of the liquidation buffer
        uint128[10] liquidationBufferNetSizes;
        uint256[50] __gap;
    }

    struct GlobalLiquidationFund {
        /// @notice The liquidation fund, primarily used to compensate for the difference between the
        /// liquidation price and the index price when a trader's position is liquidated. It consists of
        /// the following parts:
        ///     1. Increased by the liquidation fee when the trader's is liquidated
        ///     2. Increased by the liquidation fee when the LP's position is liquidated
        ///     3. Increased by the liquidity added to the liquidation fund
        ///     4. Decreased by the liquidity removed from the liquidation fund
        ///     5. Decreased by the funding fee compensated when the trader's position is liquidated
        ///     6. Decreased by the loss compensated when the LP's position is liquidated
        ///     7. Decreased by the difference between the liquidation price and the index price when
        ///      the trader's position is liquidated
        ///     8. Decreased by the governance when the liquidation fund is pofitable
        int256 liquidationFund;
        /// @notice The total liquidity of the liquidation fund
        uint256 liquidity;
        uint256[50] __gap;
    }

    struct State {
        /// @notice The value is used to track the price curve
        PriceState priceState;
        /// @notice The value is used to track the USD balance of the market
        uint128 usdBalance;
        /// @notice The value is used to track the remaining protocol fee of the market
        uint128 protocolFee;
        /// @notice Mapping of referral token to referral fee
        mapping(uint256 referralToken => uint256 feeAmount) referralFees;
        // ==================== Liquidity Position Stats ====================
        /// @notice The value is used to track the global liquidity position
        GlobalLiquidityPosition globalLiquidityPosition;
        /// @notice Mapping of account to liquidity position
        mapping(address account => LiquidityPosition) liquidityPositions;
        // ==================== Position Stats ==============================
        /// @notice The value is used to track the global position
        GlobalPosition globalPosition;
        /// @notice Mapping of account to position
        mapping(address account => mapping(Side => Position)) positions;
        // ==================== Liquidation Fund Position Stats =============
        /// @notice The value is used to track the global liquidation fund
        GlobalLiquidationFund globalLiquidationFund;
        /// @notice Mapping of account to liquidation fund position
        mapping(address account => uint256 liquidity) liquidationFundPositions;
        uint256[50] __gap;
    }

    /// @notice Emitted when the price vertex is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param index The index of the price vertex
    /// @param sizeAfter The available size when the price curve moves to this vertex
    /// @param premiumRateAfterX96 The premium rate when the price curve moves to this vertex, as a Q32.96
    event PriceVertexChanged(
        IMarketDescriptor indexed market,
        uint8 index,
        uint128 sizeAfter,
        uint128 premiumRateAfterX96
    );

    /// @notice Emitted when the protocol fee is increased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param amount The increased protocol fee
    event ProtocolFeeIncreased(IMarketDescriptor indexed market, uint128 amount);

    /// @notice Emitted when the protocol fee is collected
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param amount The collected protocol fee
    event ProtocolFeeCollected(IMarketDescriptor indexed market, uint128 amount);

    /// @notice Emitted when the price feed is changed
    /// @param priceFeedBefore The address of the price feed before changed
    /// @param priceFeedAfter The address of the price feed after changed
    event PriceFeedChanged(IPriceFeed indexed priceFeedBefore, IPriceFeed indexed priceFeedAfter);

    /// @notice Emitted when the premium rate is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param premiumRateAfterX96 The premium rate after changed, as a Q32.96
    event PremiumRateChanged(IMarketDescriptor indexed market, uint128 premiumRateAfterX96);

    /// @notice Emitted when liquidation buffer net size is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param index The index of the liquidation buffer net size
    /// @param netSizeAfter The net size of the liquidation buffer after changed
    event LiquidationBufferNetSizeChanged(IMarketDescriptor indexed market, uint8 index, uint128 netSizeAfter);

    /// @notice Emitted when the basis index price is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param basisIndexPriceAfterX96 The basis index price after changed, as a Q64.96
    event BasisIndexPriceChanged(IMarketDescriptor indexed market, uint160 basisIndexPriceAfterX96);

    /// @notice Emitted when the liquidation fund is used by `Gov`
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param receiver The address that receives the liquidation fund
    /// @param liquidationFundDelta The amount of liquidation fund used
    event GlobalLiquidationFundGovUsed(
        IMarketDescriptor indexed market,
        address indexed receiver,
        uint128 liquidationFundDelta
    );

    /// @notice Emitted when the liquidity of the liquidation fund is increased by liquidation
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param liquidationFee The amount of the liquidation fee that is added to the liquidation fund.
    /// It consists of following parts:
    ///     1. The liquidation fee paid by the position
    ///     2. The funding fee compensated when liquidating, covered by the liquidation fund (if any)
    ///     3. The difference between the liquidation price and the trade price when liquidating,
    ///     covered by the liquidation fund (if any)
    /// @param liquidationFundAfter The amount of the liquidation fund after the increase
    event GlobalLiquidationFundIncreasedByLiquidation(
        IMarketDescriptor indexed market,
        int256 liquidationFee,
        int256 liquidationFundAfter
    );

    /// @notice Emitted when the liquidity of the liquidation fund is increased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidityAfter The total liquidity of the position after the increase
    event LiquidationFundPositionIncreased(
        IMarketDescriptor indexed market,
        address indexed account,
        uint256 liquidityAfter
    );

    /// @notice Emitted when the liquidity of the liquidation fund is decreased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidityAfter The total liquidity of the position after the decrease
    /// @param receiver The address that receives the liquidity when it is decreased
    event LiquidationFundPositionDecreased(
        IMarketDescriptor indexed market,
        address indexed account,
        uint256 liquidityAfter,
        address receiver
    );

    /// @notice Change the price feed
    /// @param priceFeed The address of the new price feed
    function setPriceFeed(IPriceFeed priceFeed) external;

    /// @notice Get the price state of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function priceStates(IMarketDescriptor market) external view returns (PriceState memory);

    /// @notice Get the USD balance of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function usdBalances(IMarketDescriptor market) external view returns (uint256);

    /// @notice Get the protocol fee of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function protocolFees(IMarketDescriptor market) external view returns (uint128);

    /// @notice Change the price vertex of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param startExclusive The start index of the price vertex to be changed, exclusive
    /// @param endInclusive The end index of the price vertex to be changed, inclusive
    function changePriceVertex(IMarketDescriptor market, uint8 startExclusive, uint8 endInclusive) external;

    /// @notice Settle the funding fee of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function settleFundingFee(IMarketDescriptor market) external;

    /// @notice Collect the protocol fee of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function collectProtocolFee(IMarketDescriptor market) external;

    /// @notice Get the global liquidation fund of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function globalLiquidationFunds(IMarketDescriptor market) external view returns (GlobalLiquidationFund memory);

    /// @notice Get the liquidity of the liquidation fund
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    function liquidationFundPositions(
        IMarketDescriptor market,
        address account
    ) external view returns (uint256 liquidity);

    /// @notice `Gov` uses the liquidation fund
    /// @dev The call will fail if the caller is not the `Gov` or the liquidation fund is insufficient
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param receiver The address to receive the liquidation fund
    /// @param liquidationFundDelta The amount of liquidation fund to be used
    function govUseLiquidationFund(IMarketDescriptor market, address receiver, uint128 liquidationFundDelta) external;

    /// @notice Increase the liquidity of a liquidation fund position
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidityDelta The increase in liquidity
    function increaseLiquidationFundPosition(
        IMarketDescriptor market,
        address account,
        uint128 liquidityDelta
    ) external;

    /// @notice Decrease the liquidity of a liquidation fund position
    /// @dev The call will fail if the position liquidity is insufficient or the liquidation fund is losing
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidityDelta The decrease in liquidity
    /// @param receiver The address to receive the liquidity when it is decreased
    function decreaseLiquidationFundPosition(
        IMarketDescriptor market,
        address account,
        uint128 liquidityDelta,
        address receiver
    ) external;

    /// @notice Get the market price of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param side The side of the position adjustment, 1 for opening long or closing short positions,
    /// 2 for opening short or closing long positions
    /// @return marketPriceX96 The market price, as a Q64.96
    function marketPriceX96s(IMarketDescriptor market, Side side) external view returns (uint160 marketPriceX96);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IMarketDescriptor.sol";
import {Side} from "../../types/Side.sol";

/// @notice Interface for managing market positions.
/// @dev The market position is the core component of the protocol, which stores the information of
/// all trader's positions and the funding rate.
interface IMarketPosition {
    struct GlobalPosition {
        /// @notice The sum of long position sizes
        uint128 longSize;
        /// @notice The sum of short position sizes
        uint128 shortSize;
        /// @notice The maximum available size of all positions
        uint128 maxSize;
        /// @notice The maximum available size of per position
        uint128 maxSizePerPosition;
        /// @notice The funding rate growth per unit of long position sizes, as a Q96.96
        int192 longFundingRateGrowthX96;
        /// @notice The funding rate growth per unit of short position sizes, as a Q96.96
        int192 shortFundingRateGrowthX96;
        /// @notice The last time the funding fee is settled
        uint64 lastFundingFeeSettleTime;
        uint256[50] __gap;
    }

    struct Position {
        /// @notice The margin of the position
        uint128 margin;
        /// @notice The size of the position
        uint128 size;
        /// @notice The entry price of the position, as a Q64.96
        uint160 entryPriceX96;
        /// @notice The snapshot of the funding rate growth at the time the position was opened.
        /// For long positions it is `GlobalPosition.longFundingRateGrowthX96`,
        /// and for short positions it is `GlobalPosition.shortFundingRateGrowthX96`
        int192 entryFundingRateGrowthX96;
        uint256[50] __gap;
    }
    /// @notice Emitted when the funding fee is settled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param longFundingRateGrowthAfterX96 The adjusted `GlobalPosition.longFundingRateGrowthX96`, as a Q96.96
    /// @param shortFundingRateGrowthAfterX96 The adjusted `GlobalPosition.shortFundingRateGrowthX96`, as a Q96.96
    event FundingFeeSettled(
        IMarketDescriptor indexed market,
        int192 longFundingRateGrowthAfterX96,
        int192 shortFundingRateGrowthAfterX96
    );

    /// @notice Emitted when the max available size is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param maxSizeAfter The adjusted `maxSize`
    /// @param maxSizePerPositionAfter The adjusted `maxSizePerPosition`
    event GlobalPositionSizeChanged(
        IMarketDescriptor indexed market,
        uint128 maxSizeAfter,
        uint128 maxSizePerPositionAfter
    );

    /// @notice Emitted when the position margin/liquidity (value) is increased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The increased margin
    /// @param marginAfter The adjusted margin
    /// @param sizeAfter The adjusted position size
    /// @param tradePriceX96 The trade price at which the position is adjusted.
    /// If only adding margin, it returns 0, as a Q64.96
    /// @param entryPriceAfterX96 The adjusted entry price of the position, as a Q64.96
    /// @param fundingFee The funding fee, a positive value means the position receives funding fee,
    /// while a negative value means the position positive pays funding fee
    event PositionIncreased(
        IMarketDescriptor indexed market,
        address indexed account,
        Side side,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 sizeAfter,
        uint160 tradePriceX96,
        uint160 entryPriceAfterX96,
        int256 fundingFee
    );

    /// @notice Emitted when the position margin/liquidity (value) is decreased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The decreased margin
    /// @param marginAfter The adjusted margin
    /// @param sizeAfter The adjusted position size
    /// @param tradePriceX96 The trade price at which the position is adjusted.
    /// If only reducing margin, it returns 0, as a Q64.96
    /// @param realizedPnLDelta The realized PnL
    /// @param fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee
    /// @param receiver The address that receives the margin
    event PositionDecreased(
        IMarketDescriptor indexed market,
        address indexed account,
        Side side,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 sizeAfter,
        uint160 tradePriceX96,
        int256 realizedPnLDelta,
        int256 fundingFee,
        address receiver
    );

    /// @notice Emitted when a position is liquidated
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param liquidator The address that executes the liquidation of the position
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param indexPriceX96 The index price when liquidating the position, as a Q64.96
    /// @param tradePriceX96 The trade price at which the position is liquidated, as a Q64.96
    /// @param liquidationPriceX96 The liquidation price of the position, as a Q64.96
    /// @param fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee. If it's negative,
    /// it represents the actual funding fee paid during liquidation
    /// @param liquidationFee The liquidation fee paid by the position
    /// @param liquidationExecutionFee The liquidation execution fee paid by the position
    /// @param feeReceiver The address that receives the liquidation execution fee
    event PositionLiquidated(
        IMarketDescriptor indexed market,
        address indexed liquidator,
        address indexed account,
        Side side,
        uint160 indexPriceX96,
        uint160 tradePriceX96,
        uint160 liquidationPriceX96,
        int256 fundingFee,
        uint128 liquidationFee,
        uint64 liquidationExecutionFee,
        address feeReceiver
    );

    /// @notice Get the global position of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function globalPositions(IMarketDescriptor market) external view returns (GlobalPosition memory);

    /// @notice Get the information of a position
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    function positions(IMarketDescriptor market, address account, Side side) external view returns (Position memory);

    /// @notice Increase the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The increase in margin, which can be 0
    /// @param sizeDelta The increase in size, which can be 0
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only adding margin, it returns 0, as a Q64.96
    function increasePosition(
        IMarketDescriptor market,
        address account,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta
    ) external returns (uint160 tradePriceX96);

    /// @notice Decrease the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The decrease in margin, which can be 0
    /// @param sizeDelta The decrease in size, which can be 0
    /// @param receiver The address to receive the margin
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only reducing margin, it returns 0, as a Q64.96
    function decreasePosition(
        IMarketDescriptor market,
        address account,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta,
        address receiver
    ) external returns (uint160 tradePriceX96);

    /// @notice Liquidate a position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param feeReceiver The address that receives the liquidation execution fee
    function liquidatePosition(IMarketDescriptor market, address account, Side side, address feeReceiver) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.23;

import "./interfaces/IMarketManager.sol";

/// @notice The contract is used for assigning market indexes.
/// Using an index instead of an address can effectively reduce the gas cost of the transaction.
contract MarketIndexer {
    /// @notice The address of the market manager
    IMarketManager public immutable marketManager;
    /// @notice The current index of the market assigned
    uint24 public marketIndex;
    /// @notice Mapping of markets to their indexes
    mapping(IMarketDescriptor market => uint24 index) public marketIndexes;
    /// @notice Mapping of indexes to their markets
    mapping(uint24 index => IMarketDescriptor market) public indexMarkets;

    /// @notice Emitted when a index is assigned to a market
    /// @param market The address of the market
    /// @param index The index assigned to the market
    event MarketIndexAssigned(IMarketDescriptor indexed market, uint24 indexed index);

    /// @notice Error thrown when the market index is already assigned
    error MarketIndexAlreadyAssigned(IMarketDescriptor market);
    /// @notice Error thrown when the market is invalid
    error InvalidMarket(IMarketDescriptor market);

    /// @notice Construct the market indexer contract
    constructor(IMarketManager _marketManager) {
        marketManager = _marketManager;
    }

    /// @notice Assign a market index to a market
    function assignMarketIndex(IMarketDescriptor _market) external returns (uint24 index) {
        if (marketIndexes[_market] != 0) revert MarketIndexAlreadyAssigned(_market);
        if (!marketManager.isEnabledMarket(_market)) revert InvalidMarket(_market);

        index = ++marketIndex;
        marketIndexes[_market] = index;
        indexMarkets[index] = _market;

        emit MarketIndexAssigned(_market, index);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IChainLinkAggregator {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IChainLinkAggregator.sol";
import "../../core/interfaces/IMarketDescriptor.sol";

interface IPriceFeed {
    struct MarketConfig {
        /// @notice ChainLink contract address for corresponding market
        IChainLinkAggregator refPriceFeed;
        /// @notice Expected update interval of chain link price feed
        uint32 refHeartbeatDuration;
        /// @notice Maximum cumulative change ratio difference between prices and ChainLink price
        /// within a period of time.
        uint64 maxCumulativeDeltaDiff;
    }

    struct PriceDataItem {
        uint32 prevRound;
        uint160 prevRefPriceX96;
        uint64 cumulativeRefPriceDelta;
        uint160 prevPriceX96;
        uint64 cumulativePriceDelta;
    }

    struct PricePack {
        /// @notice The timestamp when updater uploads the price
        uint64 updateTimestamp;
        /// @notice Calculated maximum price, as a Q64.96
        uint160 maxPriceX96;
        /// @notice Calculated minimum price, as a Q64.96
        uint160 minPriceX96;
        /// @notice The block timestamp when price is committed
        uint64 updateBlockTimestamp;
    }

    struct MarketPrice {
        IMarketDescriptor market;
        uint160 priceX96;
    }

    /// @notice Emitted when market price updated
    /// @param market Market address
    /// @param priceX96 The price passed in by updater, as a Q64.96
    /// @param maxPriceX96 Calculated maximum price, as a Q64.96
    /// @param minPriceX96 Calculated minimum price, as a Q64.96
    event PriceUpdated(IMarketDescriptor indexed market, uint160 priceX96, uint160 minPriceX96, uint160 maxPriceX96);

    /// @notice Emitted when maxCumulativeDeltaDiff exceeded
    /// @param market Market address
    /// @param priceX96 The price passed in by updater, as a Q64.96
    /// @param refPriceX96 The price provided by ChainLink, as a Q64.96
    /// @param cumulativeDelta The cumulative value of the price change ratio
    /// @param cumulativeRefDelta The cumulative value of the ChainLink price change ratio
    event MaxCumulativeDeltaDiffExceeded(
        IMarketDescriptor indexed market,
        uint160 priceX96,
        uint160 refPriceX96,
        uint64 cumulativeDelta,
        uint64 cumulativeRefDelta
    );

    /// @notice Price not be initialized
    error NotInitialized();

    /// @notice Reference price feed not set
    error ReferencePriceFeedNotSet();

    /// @notice Invalid reference price
    /// @param referencePrice Reference price
    error InvalidReferencePrice(int256 referencePrice);

    /// @notice Reference price timeout
    /// @param elapsed The time elapsed since the last price update.
    error ReferencePriceTimeout(uint256 elapsed);

    /// @notice Stable market price timeout
    /// @param elapsed The time elapsed since the last price update.
    error StableMarketPriceTimeout(uint256 elapsed);

    /// @notice Invalid stable market price
    /// @param stableMarketPrice Stable market price
    error InvalidStableMarketPrice(int256 stableMarketPrice);

    /// @notice Invalid update timestamp
    /// @param timestamp Update timestamp
    error InvalidUpdateTimestamp(uint64 timestamp);
    /// @notice L2 sequencer is down
    error SequencerDown();
    /// @notice Grace period is not over
    /// @param sequencerUptime Sequencer uptime
    error GracePeriodNotOver(uint256 sequencerUptime);

    struct Slot {
        // Maximum deviation ratio between price and ChainLink price.
        uint32 maxDeviationRatio;
        // Period for calculating cumulative deviation ratio.
        uint32 cumulativeRoundDuration;
        // The number of additional rounds for ChainLink prices to participate in price update calculation.
        uint32 refPriceExtraSample;
        // The timeout for price update transactions.
        uint32 updateTxTimeout;
    }

    /// @notice Get the address of stable market price feed
    /// @return priceFeed The address of stable market price feed
    function stableMarketPriceFeed() external view returns (IChainLinkAggregator priceFeed);

    /// @notice Get the expected update interval of stable market price
    /// @return duration The expected update interval of stable market price
    function stableMarketPriceFeedHeartBeatDuration() external view returns (uint32 duration);

    /// @notice The 0th storage slot in the price feed stores many values, which helps reduce gas
    /// costs when interacting with the price feed.
    function slot() external view returns (Slot memory);

    /// @notice Get market configuration for updating price
    /// @param market The market address to query the configuration
    /// @return marketConfig The packed market config data
    function marketConfig(IMarketDescriptor market) external view returns (MarketConfig memory marketConfig);

    /// @notice `ReferencePriceFeedNotSet` will be ignored when `ignoreReferencePriceFeedError` is true
    function ignoreReferencePriceFeedError() external view returns (bool);

    /// @notice Get latest price data for corresponding market.
    /// @param market The market address to query the price data
    /// @return packedData The packed price data
    function latestPrice(IMarketDescriptor market) external view returns (PricePack memory packedData);

    /// @notice Update prices
    /// @dev Updater calls this method to update prices for multiple markets. The contract calculation requires
    /// higher precision prices, so the passed-in prices need to be adjusted.
    ///
    /// ## Example
    ///
    /// The price of ETH is $2000, and ETH has 18 decimals, so the price of one unit of ETH is $`2000 / (10 ^ 18)`.
    ///
    /// The price of USD is $1, and USD has 6 decimals, so the price of one unit of USD is $`1 / (10 ^ 6)`.
    ///
    /// Then the price of ETH/USD pair is 2000 / (10 ^ 18) * (10 ^ 6)
    ///
    /// Finally convert the price to Q64.96, ETH/USD priceX96 = 2000 / (10 ^ 18) * (10 ^ 6) * (2 ^ 96)
    /// @param marketPrices Array of market addresses and prices to update for
    /// @param timestamp The timestamp of price update
    function setPriceX96s(MarketPrice[] calldata marketPrices, uint64 timestamp) external;

    /// @notice calculate min and max price if passed a specific price value
    /// @param marketPrices Array of market addresses and prices to update for
    function calculatePriceX96s(
        MarketPrice[] calldata marketPrices
    ) external view returns (uint160[] memory minPriceX96s, uint160[] memory maxPriceX96s);

    /// @notice Get minimum market price
    /// @param market The market address to query the price
    /// @return priceX96 Minimum market price
    function getMinPriceX96(IMarketDescriptor market) external view returns (uint160 priceX96);

    /// @notice Get maximum market price
    /// @param market The market address to query the price
    /// @return priceX96 Maximum market price
    function getMaxPriceX96(IMarketDescriptor market) external view returns (uint160 priceX96);

    /// @notice Set updater status active or not
    /// @param account Updater address
    /// @param active Status of updater permission to set
    function setUpdater(address account, bool active) external;

    /// @notice Check if is updater
    /// @param account The address to query the status
    /// @return active Status of updater
    function isUpdater(address account) external returns (bool active);

    /// @notice Set ChainLink contract address for corresponding market.
    /// @param market The market address to set
    /// @param priceFeed ChainLink contract address
    function setRefPriceFeed(IMarketDescriptor market, IChainLinkAggregator priceFeed) external;

    /// @notice Set SequencerUptimeFeed contract address.
    /// @param sequencerUptimeFeed SequencerUptimeFeed contract address
    function setSequencerUptimeFeed(IChainLinkAggregator sequencerUptimeFeed) external;

    /// @notice Get SequencerUptimeFeed contract address.
    /// @return sequencerUptimeFeed SequencerUptimeFeed contract address
    function sequencerUptimeFeed() external returns (IChainLinkAggregator sequencerUptimeFeed);

    /// @notice Set the expected update interval for the ChainLink oracle price of the corresponding market.
    /// If ChainLink does not update the price within this period, it is considered that ChainLink has broken down.
    /// @param market The market address to set
    /// @param duration Expected update interval
    function setRefHeartbeatDuration(IMarketDescriptor market, uint32 duration) external;

    /// @notice Set maximum deviation ratio between price and ChainLink price.
    /// If exceeded, the updated price will refer to ChainLink price.
    /// @param maxDeviationRatio Maximum deviation ratio
    function setMaxDeviationRatio(uint32 maxDeviationRatio) external;

    /// @notice Set period for calculating cumulative deviation ratio.
    /// @param cumulativeRoundDuration Period in seconds to set.
    function setCumulativeRoundDuration(uint32 cumulativeRoundDuration) external;

    /// @notice Set the maximum acceptable cumulative change ratio difference between prices and ChainLink prices
    /// within a period of time. If exceeded, the updated price will refer to ChainLink price.
    /// @param market The market address to set
    /// @param maxCumulativeDeltaDiff Maximum cumulative change ratio difference
    function setMaxCumulativeDeltaDiffs(IMarketDescriptor market, uint64 maxCumulativeDeltaDiff) external;

    /// @notice Set number of additional rounds for ChainLink prices to participate in price update calculation.
    /// @param refPriceExtraSample The number of additional sampling rounds.
    function setRefPriceExtraSample(uint32 refPriceExtraSample) external;

    /// @notice Set the timeout for price update transactions.
    /// @param updateTxTimeout The timeout for price update transactions
    function setUpdateTxTimeout(uint32 updateTxTimeout) external;

    /// @notice Set ChainLink contract address and heart beat duration config for stable market.
    /// @param stableMarketPriceFeed The stable market address to set
    /// @param stableMarketPriceFeedHeartBeatDuration The expected update interval of stable market price
    function setStableMarketPriceFeed(
        IChainLinkAggregator stableMarketPriceFeed,
        uint32 stableMarketPriceFeedHeartBeatDuration
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

Side constant LONG = Side.wrap(1);
Side constant SHORT = Side.wrap(2);

type Side is uint8;

error InvalidSide(Side side);

using {requireValid, isLong, isShort, flip, eq as ==} for Side global;

function requireValid(Side self) pure {
    if (!isLong(self) && !isShort(self)) revert InvalidSide(self);
}

function isLong(Side self) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(LONG);
}

function isShort(Side self) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(SHORT);
}

function eq(Side self, Side other) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(other);
}

function flip(Side self) pure returns (Side) {
    return isLong(self) ? SHORT : LONG;
}