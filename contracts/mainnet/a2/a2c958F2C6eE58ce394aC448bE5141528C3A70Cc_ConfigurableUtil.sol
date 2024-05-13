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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Constants.sol";
import "../core/interfaces/IConfigurable.sol";

library ConfigurableUtil {
    function enableMarket(
        mapping(IMarketDescriptor => IConfigurable.MarketConfig) storage _self,
        IMarketDescriptor _market,
        IConfigurable.MarketConfig calldata _cfg
    ) public {
        if (_self[_market].baseConfig.maxLeveragePerLiquidityPosition > 0)
            revert IConfigurable.MarketAlreadyEnabled(_market);

        _validateBaseConfig(_cfg.baseConfig);
        _validateFeeRateConfig(_cfg.feeRateConfig);
        _validatePriceConfig(_cfg.priceConfig);

        _self[_market] = _cfg;

        emit IConfigurable.MarketConfigEnabled(_market, _cfg.baseConfig, _cfg.feeRateConfig, _cfg.priceConfig);
    }

    function updateMarketBaseConfig(
        mapping(IMarketDescriptor => IConfigurable.MarketConfig) storage _self,
        IMarketDescriptor _market,
        IConfigurable.MarketBaseConfig calldata _newCfg
    ) public {
        IConfigurable.MarketConfig storage marketCfg = _self[_market];
        if (marketCfg.baseConfig.maxLeveragePerLiquidityPosition == 0) revert IConfigurable.MarketNotEnabled(_market);

        _validateBaseConfig(_newCfg);

        marketCfg.baseConfig = _newCfg;

        emit IConfigurable.MarketBaseConfigChanged(_market, _newCfg);
    }

    function updateMarketFeeRateConfig(
        mapping(IMarketDescriptor => IConfigurable.MarketConfig) storage _self,
        IMarketDescriptor _market,
        IConfigurable.MarketFeeRateConfig calldata _newCfg
    ) public {
        IConfigurable.MarketConfig storage marketCfg = _self[_market];
        if (marketCfg.baseConfig.maxLeveragePerLiquidityPosition == 0) revert IConfigurable.MarketNotEnabled(_market);

        _validateFeeRateConfig(_newCfg);

        marketCfg.feeRateConfig = _newCfg;

        emit IConfigurable.MarketFeeRateConfigChanged(_market, _newCfg);
    }

    function updateMarketPriceConfig(
        mapping(IMarketDescriptor => IConfigurable.MarketConfig) storage _self,
        IMarketDescriptor _market,
        IConfigurable.MarketPriceConfig calldata _newCfg
    ) public {
        IConfigurable.MarketConfig storage marketCfg = _self[_market];
        if (marketCfg.baseConfig.maxLeveragePerLiquidityPosition == 0) revert IConfigurable.MarketNotEnabled(_market);

        _validatePriceConfig(_newCfg);

        marketCfg.priceConfig = _newCfg;

        emit IConfigurable.MarketPriceConfigChanged(_market, _newCfg);
    }

    function _validateBaseConfig(IConfigurable.MarketBaseConfig calldata _newCfg) private pure {
        if (_newCfg.maxLeveragePerLiquidityPosition == 0)
            revert IConfigurable.InvalidMaxLeveragePerLiquidityPosition(_newCfg.maxLeveragePerLiquidityPosition);

        if (_newCfg.liquidationFeeRatePerLiquidityPosition > Constants.BASIS_POINTS_DIVISOR)
            revert IConfigurable.InvalidLiquidationFeeRatePerLiquidityPosition(
                _newCfg.liquidationFeeRatePerLiquidityPosition
            );

        if (_newCfg.maxLeveragePerPosition == 0)
            revert IConfigurable.InvalidMaxLeveragePerPosition(_newCfg.maxLeveragePerPosition);

        if (_newCfg.liquidationFeeRatePerPosition > Constants.BASIS_POINTS_DIVISOR)
            revert IConfigurable.InvalidLiquidationFeeRatePerPosition(_newCfg.liquidationFeeRatePerPosition);

        if (_newCfg.maxPositionLiquidity == 0)
            revert IConfigurable.InvalidMaxPositionLiquidity(_newCfg.maxPositionLiquidity);

        if (_newCfg.maxPositionValueRate == 0)
            revert IConfigurable.InvalidMaxPositionValueRate(_newCfg.maxPositionValueRate);

        if (_newCfg.maxSizeRatePerPosition > Constants.BASIS_POINTS_DIVISOR)
            revert IConfigurable.InvalidMaxSizeRatePerPosition(_newCfg.maxSizeRatePerPosition);
    }

    function _validateFeeRateConfig(IConfigurable.MarketFeeRateConfig calldata _newCfg) private pure {
        if (_newCfg.protocolFundingFeeRate > Constants.BASIS_POINTS_DIVISOR)
            revert IConfigurable.InvalidProtocolFundingFeeRate(_newCfg.protocolFundingFeeRate);

        if (_newCfg.fundingCoeff > Constants.BASIS_POINTS_DIVISOR * 10)
            revert IConfigurable.InvalidFundingCoeff(_newCfg.fundingCoeff);

        if (_newCfg.protocolFundingCoeff > Constants.BASIS_POINTS_DIVISOR)
            revert IConfigurable.InvalidProtocolFundingCoeff(_newCfg.protocolFundingCoeff);

        if (_newCfg.interestRate > Constants.BASIS_POINTS_DIVISOR)
            revert IConfigurable.InvalidInterestRate(_newCfg.interestRate);

        if (_newCfg.fundingBuffer > Constants.BASIS_POINTS_DIVISOR)
            revert IConfigurable.InvalidFundingBuffer(_newCfg.fundingBuffer);

        if (_newCfg.liquidityFundingFeeRate > Constants.BASIS_POINTS_DIVISOR)
            revert IConfigurable.InvalidLiquidityFundingFeeRate(_newCfg.liquidityFundingFeeRate);

        if (_newCfg.maxFundingRate > Constants.BASIS_POINTS_DIVISOR)
            revert IConfigurable.InvalidMaxFundingRate(_newCfg.maxFundingRate);
    }

    function _validatePriceConfig(IConfigurable.MarketPriceConfig calldata _newCfg) private pure {
        if (_newCfg.maxPriceImpactLiquidity == 0)
            revert IConfigurable.InvalidMaxPriceImpactLiquidity(_newCfg.maxPriceImpactLiquidity);

        if (_newCfg.vertices.length != Constants.VERTEX_NUM)
            revert IConfigurable.InvalidVerticesLength(_newCfg.vertices.length, Constants.VERTEX_NUM);

        if (_newCfg.liquidationVertexIndex >= Constants.LATEST_VERTEX)
            revert IConfigurable.InvalidLiquidationVertexIndex(_newCfg.liquidationVertexIndex);

        if (_newCfg.dynamicDepthLevel > Constants.BASIS_POINTS_DIVISOR)
            revert IConfigurable.InvalidDynamicDepthLevel(_newCfg.dynamicDepthLevel);

        unchecked {
            // first vertex must be (0, 0)
            if (_newCfg.vertices[0].balanceRate != 0 || _newCfg.vertices[0].premiumRate != 0)
                revert IConfigurable.InvalidVertex(0);

            for (uint8 i = 2; i < Constants.VERTEX_NUM; ++i) {
                if (
                    _newCfg.vertices[i - 1].balanceRate > _newCfg.vertices[i].balanceRate ||
                    _newCfg.vertices[i - 1].premiumRate > _newCfg.vertices[i].premiumRate
                ) revert IConfigurable.InvalidVertex(i);
            }
            if (
                _newCfg.vertices[Constants.LATEST_VERTEX].balanceRate > Constants.BASIS_POINTS_DIVISOR ||
                _newCfg.vertices[Constants.LATEST_VERTEX].premiumRate > Constants.BASIS_POINTS_DIVISOR
            ) revert IConfigurable.InvalidVertex(Constants.LATEST_VERTEX);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Constants {
    uint32 internal constant BASIS_POINTS_DIVISOR = 100_000_000;

    uint8 internal constant VERTEX_NUM = 10;
    uint8 internal constant LATEST_VERTEX = VERTEX_NUM - 1;

    uint32 internal constant FUNDING_RATE_SETTLE_CONFIG_INTERVAL = 8 hours;

    uint256 internal constant Q64 = 1 << 64;
    uint256 internal constant Q96 = 1 << 96;
    uint256 internal constant Q152 = 1 << 152;
}