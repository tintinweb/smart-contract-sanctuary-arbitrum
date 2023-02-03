//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IOptionMarket {
  enum TradeDirection {
    OPEN,
    CLOSE,
    LIQUIDATE
  }
  enum OptionType {
    LONG_CALL,
    LONG_PUT,
    SHORT_CALL_BASE,
    SHORT_CALL_QUOTE,
    SHORT_PUT_QUOTE
  }
  enum NonZeroValues {
    BASE_IV,
    SKEW,
    STRIKE_PRICE,
    ITERATIONS,
    STRIKE_ID
  }

  struct TradeParameters {
    bool isBuy;
    bool isForceClose;
    TradeDirection tradeDirection;
    OptionType optionType;
    uint amount;
    uint expiry;
    uint strikePrice;
    uint spotPrice;
    ILiquidityPool.Liquidity liquidity;
  }
  struct Strike {
    uint id;
    uint strikePrice;
    uint skew;
    uint longCall;
    uint shortCallBase;
    uint shortCallQuote;
    uint longPut;
    uint shortPut;
    uint boardId;
  }
  struct OptionBoard {
    uint id;
    uint expiry;
    uint iv;
    bool frozen;
    uint[] strikeIds;
  }
  struct TradeInputParameters {
    uint strikeId;
    uint positionId;
    uint iterations;
    OptionType optionType;
    uint amount;
    uint setCollateralTo;
    uint minTotalCost;
    uint maxTotalCost;
    address referrer;
  }
  struct Result {
    uint positionId;
    uint totalCost;
    uint totalFee;
  }

  function getStrike(uint strikeId) external view returns (Strike memory);

  function getOptionBoard(uint boardId) external view returns (OptionBoard memory);

  function getSettlementParameters(
    uint strikeId
  ) external view returns (uint strikePrice, uint priceAtExpiry, uint strikeToBaseReturned, uint longScaleFactor);

  function boardToPriceAtExpiry(uint256) external view returns (uint256);

  error ExpectedNonZeroValue(address thrower, NonZeroValues valueType);
  error InvalidBoardId(address thrower, uint boardId);
  error InvalidExpiryTimestamp(address thrower, uint currentTime, uint expiry, uint maxBoardExpiry);
  error BoardNotFrozen(address thrower, uint boardId);
  error BoardAlreadySettled(address thrower, uint boardId);
  error BoardNotExpired(address thrower, uint boardId);
  error InvalidStrikeId(address thrower, uint strikeId);
  error StrikeSkewLengthMismatch(address thrower, uint strikesLength, uint skewsLength);
  error TotalCostOutsideOfSpecifiedBounds(address thrower, uint totalCost, uint minCost, uint maxCost);
  error BoardIsFrozen(address thrower, uint boardId);
  error BoardExpired(address thrower, uint boardId, uint boardExpiry, uint currentTime);
}

interface IGMXAdapter {
  enum PriceType {
    MIN_PRICE, // minimise the spot based on logic in adapter - can revert
    MAX_PRICE, // maximise the spot based on logic in adapter
    REFERENCE,
    FORCE_MIN, // minimise the spot based on logic in adapter - shouldn't revert unless feeds are compromised
    FORCE_MAX
  }

  function getSpotPriceForMarket(IOptionMarket optionMarket, PriceType pricing) external view returns (uint spotPrice);

  function rateAndCarry(IOptionMarket optionMarket) external view returns (int rateDecimal);
}

interface ILiquidityPool {
  struct Liquidity {
    uint freeLiquidity;
    uint burnableLiquidity;
    uint usedCollatLiquidity;
    uint pendingDeltaLiquidity;
    uint usedDeltaLiquidity;
    uint NAV;
    uint longScaleFactor;
  }

  function getLiquidity() external view returns (Liquidity memory);
}

interface IOptionMarketPricer {
  struct VegaUtilFeeComponents {
    int preTradeAmmNetStdVega;
    int postTradeAmmNetStdVega;
    uint vegaUtil;
    uint volTraded;
    uint NAV;
    uint vegaUtilFee;
  }

  struct VarianceFeeComponents {
    uint varianceFeeCoefficient;
    uint vega;
    uint vegaCoefficient;
    uint skew;
    uint skewCoefficient;
    uint ivVariance;
    uint ivVarianceCoefficient;
    uint varianceFee;
  }

  struct TradeResult {
    uint amount;
    uint premium;
    uint optionPriceFee;
    uint spotPriceFee;
    VegaUtilFeeComponents vegaUtilFee;
    VarianceFeeComponents varianceFee;
    uint totalFee;
    uint totalCost;
    uint volTraded;
    uint newBaseIv;
    uint newSkew;
  }

  struct VolComponents {
    uint vol;
    uint baseIv;
    uint skew;
  }

  struct PricingParameters {
    uint optionPriceFeeCoefficient;
    uint optionPriceFee1xPoint;
    uint optionPriceFee2xPoint;
    uint spotPriceFeeCoefficient;
    uint spotPriceFee1xPoint;
    uint spotPriceFee2xPoint;
    uint vegaFeeCoefficient;
    uint standardSize;
    uint skewAdjustmentFactor;
  }

  function getTimeWeightedFee(
    uint expiry,
    uint pointA,
    uint pointB,
    uint coefficient
  ) external view returns (uint timeWeightedFee);

  function getPricingParams() external view returns (PricingParameters memory pricingParameters);

  function ivImpactForTrade(
    IOptionMarket.TradeParameters memory trade,
    uint boardBaseIv,
    uint strikeSkew
  ) external view returns (uint newBaseIv, uint newSkew);

  function getVegaUtilFee(
    IOptionMarket.TradeParameters memory trade,
    IOptionGreekCache.TradePricing memory pricing
  ) external view returns (VegaUtilFeeComponents memory vegaUtilFeeComponents);

  function getVarianceFee(
    IOptionMarket.TradeParameters memory trade,
    IOptionGreekCache.TradePricing memory pricing,
    uint skew
  ) external view returns (VarianceFeeComponents memory varianceFeeComponents);
}

interface IOptionGreekCache {
  struct TradePricing {
    uint optionPrice;
    int preTradeAmmNetStdVega;
    int postTradeAmmNetStdVega;
    int callDelta;
    uint volTraded;
    uint ivVariance;
    uint vega;
  }
  struct GreekCacheParameters {
    uint maxStrikesPerBoard;
    uint acceptableSpotPricePercentMove;
    uint staleUpdateDuration;
    uint varianceIvGWAVPeriod;
    uint varianceSkewGWAVPeriod;
    uint optionValueIvGWAVPeriod;
    uint optionValueSkewGWAVPeriod;
    uint gwavSkewFloor;
    uint gwavSkewCap;
  }
  struct NetGreeks {
    int netDelta;
    int netStdVega;
    int netOptionValue;
  }
  struct StrikeGreeks {
    int callDelta;
    int putDelta;
    uint stdVega;
    uint callPrice;
    uint putPrice;
  }

  struct OptionBoardCache {
    uint id;
    uint[] strikes;
    uint expiry;
    uint iv;
    NetGreeks netGreeks;
    uint updatedAt;
    uint updatedAtPrice;
    uint maxSkewVariance;
    uint ivVariance;
  }
  struct StrikeCache {
    uint id;
    uint boardId;
    uint strikePrice;
    uint skew;
    StrikeGreeks greeks;
    int callExposure; // long - short
    int putExposure; // long - short
    uint skewVariance; // (GWAVSkew - skew)
  }
  struct GlobalCache {
    uint minUpdatedAt;
    uint minUpdatedAtPrice;
    uint maxUpdatedAtPrice;
    uint maxSkewVariance;
    uint maxIvVariance;
    NetGreeks netGreeks;
  }
  struct BoardGreeksView {
    NetGreeks boardGreeks;
    uint ivGWAV;
    StrikeGreeks[] strikeGreeks;
    uint[] skewGWAVs;
  }

  function getStrikeCache(uint strikeId) external view returns (StrikeCache memory);

  function getSkewGWAV(uint strikeId, uint secondsAgo) external view returns (uint skewGWAV);

  function getOptionBoardCache(uint boardId) external view returns (OptionBoardCache memory);

  function getGreekCacheParams() external view returns (GreekCacheParameters memory);

  function getGlobalCache() external view returns (GlobalCache memory);

  function getBoardGreeksView(uint boardId) external view returns (BoardGreeksView memory);
}

interface ILyraRegister {
  struct OptionMarketAddresses {
    ILiquidityPool liquidityPool;
    address liquidityToken;
    IOptionGreekCache greekCache;
    IOptionMarket optionMarket;
    IOptionMarketPricer optionMarketPricer;
    address optionToken;
    address poolHedger;
    address shortCollateral;
    address gwavOracle;
    address quoteAsset;
    address baseAsset;
  }

  function getMarketAddresses(IOptionMarket optionMarket) external view returns (OptionMarketAddresses memory);

  function getGlobalAddress(bytes32 contractName) external view returns (address globalContract);
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

// Libraries
import "../synthetix/SignedDecimalMath.sol";
import "../synthetix/DecimalMath.sol";
import "./FixedPointMathLib.sol";
import "./Math.sol";

/**
 * @title BlackScholes
 * @author Lyra
 * @dev Contract to compute the black scholes price of options. Where the unit is unspecified, it should be treated as a
 * PRECISE_DECIMAL, which has 1e27 units of precision. The default decimal matches the ethereum standard of 1e18 units
 * of precision.
 */
library BlackScholes {
  using DecimalMath for uint;
  using SignedDecimalMath for int;

  struct PricesDeltaStdVega {
    uint callPrice;
    uint putPrice;
    int callDelta;
    int putDelta;
    uint vega;
    uint stdVega;
  }

  /**
   * @param timeToExpirySec Number of seconds to the expiry of the option
   * @param volatilityDecimal Implied volatility over the period til expiry as a percentage
   * @param spotDecimal The current price of the base asset
   * @param strikePriceDecimal The strikePrice price of the option
   * @param rateDecimal The percentage risk free rate + carry cost
   */
  struct BlackScholesInputs {
    uint timeToExpirySec;
    uint volatilityDecimal;
    uint spotDecimal;
    uint strikePriceDecimal;
    int rateDecimal;
  }

  uint private constant SECONDS_PER_YEAR = 31536000;
  /// @dev Internally this library uses 27 decimals of precision
  uint private constant PRECISE_UNIT = 1e27;
  uint private constant SQRT_TWOPI = 2506628274631000502415765285;
  /// @dev Value to use to avoid any division by 0 or values near 0
  uint private constant MIN_T_ANNUALISED = PRECISE_UNIT / SECONDS_PER_YEAR; // 1 second
  uint private constant MIN_VOLATILITY = PRECISE_UNIT / 10000; // 0.001%
  uint private constant VEGA_STANDARDISATION_MIN_DAYS = 7 days;
  /// @dev Magic numbers for normal CDF
  uint private constant SPLIT = 7071067811865470000000000000;
  uint private constant N0 = 220206867912376000000000000000;
  uint private constant N1 = 221213596169931000000000000000;
  uint private constant N2 = 112079291497871000000000000000;
  uint private constant N3 = 33912866078383000000000000000;
  uint private constant N4 = 6373962203531650000000000000;
  uint private constant N5 = 700383064443688000000000000;
  uint private constant N6 = 35262496599891100000000000;
  uint private constant M0 = 440413735824752000000000000000;
  uint private constant M1 = 793826512519948000000000000000;
  uint private constant M2 = 637333633378831000000000000000;
  uint private constant M3 = 296564248779674000000000000000;
  uint private constant M4 = 86780732202946100000000000000;
  uint private constant M5 = 16064177579207000000000000000;
  uint private constant M6 = 1755667163182640000000000000;
  uint private constant M7 = 88388347648318400000000000;

  /////////////////////////////////////
  // Option Pricing public functions //
  /////////////////////////////////////

  /**
   * @dev Returns call and put prices for options with given parameters.
   */
  function optionPrices(BlackScholesInputs memory bsInput) public pure returns (uint call, uint put) {
    uint tAnnualised = _annualise(bsInput.timeToExpirySec);
    uint spotPrecise = bsInput.spotDecimal.decimalToPreciseDecimal();
    uint strikePricePrecise = bsInput.strikePriceDecimal.decimalToPreciseDecimal();
    int ratePrecise = bsInput.rateDecimal.decimalToPreciseDecimal();
    (int d1, int d2) = _d1d2(
      tAnnualised,
      bsInput.volatilityDecimal.decimalToPreciseDecimal(),
      spotPrecise,
      strikePricePrecise,
      ratePrecise
    );
    (call, put) = _optionPrices(tAnnualised, spotPrecise, strikePricePrecise, ratePrecise, d1, d2);
    return (call.preciseDecimalToDecimal(), put.preciseDecimalToDecimal());
  }

  /**
   * @dev Returns call/put prices and delta/stdVega for options with given parameters.
   */
  function pricesDeltaStdVega(BlackScholesInputs memory bsInput) public pure returns (PricesDeltaStdVega memory) {
    uint tAnnualised = _annualise(bsInput.timeToExpirySec);
    uint spotPrecise = bsInput.spotDecimal.decimalToPreciseDecimal();

    (int d1, int d2) = _d1d2(
      tAnnualised,
      bsInput.volatilityDecimal.decimalToPreciseDecimal(),
      spotPrecise,
      bsInput.strikePriceDecimal.decimalToPreciseDecimal(),
      bsInput.rateDecimal.decimalToPreciseDecimal()
    );
    (uint callPrice, uint putPrice) = _optionPrices(
      tAnnualised,
      spotPrecise,
      bsInput.strikePriceDecimal.decimalToPreciseDecimal(),
      bsInput.rateDecimal.decimalToPreciseDecimal(),
      d1,
      d2
    );
    (uint vegaPrecise, uint stdVegaPrecise) = _standardVega(d1, spotPrecise, bsInput.timeToExpirySec);
    (int callDelta, int putDelta) = _delta(d1);

    return
      PricesDeltaStdVega(
        callPrice.preciseDecimalToDecimal(),
        putPrice.preciseDecimalToDecimal(),
        callDelta.preciseDecimalToDecimal(),
        putDelta.preciseDecimalToDecimal(),
        vegaPrecise.preciseDecimalToDecimal(),
        stdVegaPrecise.preciseDecimalToDecimal()
      );
  }

  /**
   * @dev Returns call delta given parameters.
   */

  function delta(BlackScholesInputs memory bsInput) public pure returns (int callDeltaDecimal, int putDeltaDecimal) {
    uint tAnnualised = _annualise(bsInput.timeToExpirySec);
    uint spotPrecise = bsInput.spotDecimal.decimalToPreciseDecimal();

    (int d1, ) = _d1d2(
      tAnnualised,
      bsInput.volatilityDecimal.decimalToPreciseDecimal(),
      spotPrecise,
      bsInput.strikePriceDecimal.decimalToPreciseDecimal(),
      bsInput.rateDecimal.decimalToPreciseDecimal()
    );

    (int callDelta, int putDelta) = _delta(d1);
    return (callDelta.preciseDecimalToDecimal(), putDelta.preciseDecimalToDecimal());
  }

  /**
   * @dev Returns non-normalized vega given parameters. Quoted in cents.
   */
  function vega(BlackScholesInputs memory bsInput) public pure returns (uint vegaDecimal) {
    uint tAnnualised = _annualise(bsInput.timeToExpirySec);
    uint spotPrecise = bsInput.spotDecimal.decimalToPreciseDecimal();

    (int d1, ) = _d1d2(
      tAnnualised,
      bsInput.volatilityDecimal.decimalToPreciseDecimal(),
      spotPrecise,
      bsInput.strikePriceDecimal.decimalToPreciseDecimal(),
      bsInput.rateDecimal.decimalToPreciseDecimal()
    );
    return _vega(tAnnualised, spotPrecise, d1).preciseDecimalToDecimal();
  }

  //////////////////////
  // Computing Greeks //
  //////////////////////

  /**
   * @dev Returns internal coefficients of the Black-Scholes call price formula, d1 and d2.
   * @param tAnnualised Number of years to expiry
   * @param volatility Implied volatility over the period til expiry as a percentage
   * @param spot The current price of the base asset
   * @param strikePrice The strikePrice price of the option
   * @param rate The percentage risk free rate + carry cost
   */
  function _d1d2(
    uint tAnnualised,
    uint volatility,
    uint spot,
    uint strikePrice,
    int rate
  ) internal pure returns (int d1, int d2) {
    // Set minimum values for tAnnualised and volatility to not break computation in extreme scenarios
    // These values will result in option prices reflecting only the difference in stock/strikePrice, which is expected.
    // This should be caught before calling this function, however the function shouldn't break if the values are 0.
    tAnnualised = tAnnualised < MIN_T_ANNUALISED ? MIN_T_ANNUALISED : tAnnualised;
    volatility = volatility < MIN_VOLATILITY ? MIN_VOLATILITY : volatility;

    int vtSqrt = int(volatility.multiplyDecimalRoundPrecise(_sqrtPrecise(tAnnualised)));
    int log = FixedPointMathLib.lnPrecise(int(spot.divideDecimalRoundPrecise(strikePrice)));
    int v2t = (int(volatility.multiplyDecimalRoundPrecise(volatility) / 2) + rate).multiplyDecimalRoundPrecise(
      int(tAnnualised)
    );
    d1 = (log + v2t).divideDecimalRoundPrecise(vtSqrt);
    d2 = d1 - vtSqrt;
  }

  /**
   * @dev Internal coefficients of the Black-Scholes call price formula.
   * @param tAnnualised Number of years to expiry
   * @param spot The current price of the base asset
   * @param strikePrice The strikePrice price of the option
   * @param rate The percentage risk free rate + carry cost
   * @param d1 Internal coefficient of Black-Scholes
   * @param d2 Internal coefficient of Black-Scholes
   */
  function _optionPrices(
    uint tAnnualised,
    uint spot,
    uint strikePrice,
    int rate,
    int d1,
    int d2
  ) internal pure returns (uint call, uint put) {
    uint strikePricePV = strikePrice.multiplyDecimalRoundPrecise(
      FixedPointMathLib.expPrecise(int(-rate.multiplyDecimalRoundPrecise(int(tAnnualised))))
    );
    uint spotNd1 = spot.multiplyDecimalRoundPrecise(_stdNormalCDF(d1));
    uint strikePriceNd2 = strikePricePV.multiplyDecimalRoundPrecise(_stdNormalCDF(d2));

    // We clamp to zero if the minuend is less than the subtrahend
    // In some scenarios it may be better to compute put price instead and derive call from it depending on which way
    // around is more precise.
    call = strikePriceNd2 <= spotNd1 ? spotNd1 - strikePriceNd2 : 0;
    put = call + strikePricePV;
    put = spot <= put ? put - spot : 0;
  }

  /*
   * Greeks
   */

  /**
   * @dev Returns the option's delta value
   * @param d1 Internal coefficient of Black-Scholes
   */
  function _delta(int d1) internal pure returns (int callDelta, int putDelta) {
    callDelta = int(_stdNormalCDF(d1));
    putDelta = callDelta - int(PRECISE_UNIT);
  }

  /**
   * @dev Returns the option's vega value based on d1. Quoted in cents.
   *
   * @param d1 Internal coefficient of Black-Scholes
   * @param tAnnualised Number of years to expiry
   * @param spot The current price of the base asset
   */
  function _vega(uint tAnnualised, uint spot, int d1) internal pure returns (uint) {
    return _sqrtPrecise(tAnnualised).multiplyDecimalRoundPrecise(_stdNormal(d1).multiplyDecimalRoundPrecise(spot));
  }

  /**
   * @dev Returns the option's vega value with expiry modified to be at least VEGA_STANDARDISATION_MIN_DAYS
   * @param d1 Internal coefficient of Black-Scholes
   * @param spot The current price of the base asset
   * @param timeToExpirySec Number of seconds to expiry
   */
  function _standardVega(int d1, uint spot, uint timeToExpirySec) internal pure returns (uint, uint) {
    uint tAnnualised = _annualise(timeToExpirySec);
    uint normalisationFactor = _getVegaNormalisationFactorPrecise(timeToExpirySec);
    uint vegaPrecise = _vega(tAnnualised, spot, d1);
    return (vegaPrecise, vegaPrecise.multiplyDecimalRoundPrecise(normalisationFactor));
  }

  function _getVegaNormalisationFactorPrecise(uint timeToExpirySec) internal pure returns (uint) {
    timeToExpirySec = timeToExpirySec < VEGA_STANDARDISATION_MIN_DAYS ? VEGA_STANDARDISATION_MIN_DAYS : timeToExpirySec;
    uint daysToExpiry = timeToExpirySec / 1 days;
    uint thirty = 30 * PRECISE_UNIT;
    return _sqrtPrecise(thirty / daysToExpiry) / 100;
  }

  /////////////////////
  // Math Operations //
  /////////////////////

  /// @notice Calculates the square root of x, rounding down (borrowed from https://github.com/paulrberg/prb-math)
  /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
  /// @param x The uint256 number for which to calculate the square root.
  /// @return result The result as an uint256.
  function _sqrt(uint x) internal pure returns (uint result) {
    if (x == 0) {
      return 0;
    }

    // Calculate the square root of the perfect square of a power of two that is the closest to x.
    uint xAux = uint(x);
    result = 1;
    if (xAux >= 0x100000000000000000000000000000000) {
      xAux >>= 128;
      result <<= 64;
    }
    if (xAux >= 0x10000000000000000) {
      xAux >>= 64;
      result <<= 32;
    }
    if (xAux >= 0x100000000) {
      xAux >>= 32;
      result <<= 16;
    }
    if (xAux >= 0x10000) {
      xAux >>= 16;
      result <<= 8;
    }
    if (xAux >= 0x100) {
      xAux >>= 8;
      result <<= 4;
    }
    if (xAux >= 0x10) {
      xAux >>= 4;
      result <<= 2;
    }
    if (xAux >= 0x8) {
      result <<= 1;
    }

    // The operations can never overflow because the result is max 2^127 when it enters this block.
    unchecked {
      result = (result + x / result) >> 1;
      result = (result + x / result) >> 1;
      result = (result + x / result) >> 1;
      result = (result + x / result) >> 1;
      result = (result + x / result) >> 1;
      result = (result + x / result) >> 1;
      result = (result + x / result) >> 1; // Seven iterations should be enough
      uint roundedDownResult = x / result;
      return result >= roundedDownResult ? roundedDownResult : result;
    }
  }

  /**
   * @dev Returns the square root of the value using Newton's method.
   */
  function _sqrtPrecise(uint x) internal pure returns (uint) {
    // Add in an extra unit factor for the square root to gobble;
    // otherwise, sqrt(x * UNIT) = sqrt(x) * sqrt(UNIT)
    return _sqrt(x * PRECISE_UNIT);
  }

  /**
   * @dev The standard normal distribution of the value.
   */
  function _stdNormal(int x) internal pure returns (uint) {
    return
      FixedPointMathLib.expPrecise(int(-x.multiplyDecimalRoundPrecise(x / 2))).divideDecimalRoundPrecise(SQRT_TWOPI);
  }

  /**
   * @dev The standard normal cumulative distribution of the value.
   * borrowed from a C++ implementation https://stackoverflow.com/a/23119456
   */
  function _stdNormalCDF(int x) public pure returns (uint) {
    uint z = Math.abs(x);
    int c = 0;

    if (z <= 37 * PRECISE_UNIT) {
      uint e = FixedPointMathLib.expPrecise(-int(z.multiplyDecimalRoundPrecise(z / 2)));
      if (z < SPLIT) {
        c = int(
          (_stdNormalCDFNumerator(z).divideDecimalRoundPrecise(_stdNormalCDFDenom(z)).multiplyDecimalRoundPrecise(e))
        );
      } else {
        uint f = (z +
          PRECISE_UNIT.divideDecimalRoundPrecise(
            z +
              (2 * PRECISE_UNIT).divideDecimalRoundPrecise(
                z +
                  (3 * PRECISE_UNIT).divideDecimalRoundPrecise(
                    z + (4 * PRECISE_UNIT).divideDecimalRoundPrecise(z + ((PRECISE_UNIT * 13) / 20))
                  )
              )
          ));
        c = int(e.divideDecimalRoundPrecise(f.multiplyDecimalRoundPrecise(SQRT_TWOPI)));
      }
    }
    return uint((x <= 0 ? c : (int(PRECISE_UNIT) - c)));
  }

  /**
   * @dev Helper for _stdNormalCDF
   */
  function _stdNormalCDFNumerator(uint z) internal pure returns (uint) {
    uint numeratorInner = ((((((N6 * z) / PRECISE_UNIT + N5) * z) / PRECISE_UNIT + N4) * z) / PRECISE_UNIT + N3);
    return (((((numeratorInner * z) / PRECISE_UNIT + N2) * z) / PRECISE_UNIT + N1) * z) / PRECISE_UNIT + N0;
  }

  /**
   * @dev Helper for _stdNormalCDF
   */
  function _stdNormalCDFDenom(uint z) internal pure returns (uint) {
    uint denominatorInner = ((((((M7 * z) / PRECISE_UNIT + M6) * z) / PRECISE_UNIT + M5) * z) / PRECISE_UNIT + M4);
    return
      (((((((denominatorInner * z) / PRECISE_UNIT + M3) * z) / PRECISE_UNIT + M2) * z) / PRECISE_UNIT + M1) * z) /
      PRECISE_UNIT +
      M0;
  }

  /**
   * @dev Converts an integer number of seconds to a fractional number of years.
   */
  function _annualise(uint secs) internal pure returns (uint yearFraction) {
    return secs.divideDecimalRoundPrecise(SECONDS_PER_YEAR);
  }
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

// Slightly modified version of:
// - https://github.com/recmo/experiment-solexp/blob/605738f3ed72d6c67a414e992be58262fbc9bb80/src/FixedPointMathLib.sol
library FixedPointMathLib {
  /// @dev Computes ln(x) for a 1e27 fixed point. Loses 9 last significant digits of precision.
  function lnPrecise(int x) internal pure returns (int r) {
    return ln(x / 1e9) * 1e9;
  }

  /// @dev Computes e ^ x for a 1e27 fixed point. Loses 9 last significant digits of precision.
  function expPrecise(int x) internal pure returns (uint r) {
    return exp(x / 1e9) * 1e9;
  }

  // Computes ln(x) in 1e18 fixed point.
  // Reverts if x is negative or zero.
  // Consumes 670 gas.
  function ln(int x) internal pure returns (int r) {
    unchecked {
      if (x < 1) {
        if (x < 0) revert LnNegativeUndefined();
        revert Overflow();
      }

      // We want to convert x from 10**18 fixed point to 2**96 fixed point.
      // We do this by multiplying by 2**96 / 10**18.
      // But since ln(x * C) = ln(x) + ln(C), we can simply do nothing here
      // and add ln(2**96 / 10**18) at the end.

      // Reduce range of x to (1, 2) * 2**96
      // ln(2^k * x) = k * ln(2) + ln(x)
      // Note: inlining ilog2 saves 8 gas.
      int k = int(ilog2(uint(x))) - 96;
      x <<= uint(159 - k);
      x = int(uint(x) >> 159);

      // Evaluate using a (8, 8)-term rational approximation
      // p is made monic, we will multiply by a scale factor later
      int p = x + 3273285459638523848632254066296;
      p = ((p * x) >> 96) + 24828157081833163892658089445524;
      p = ((p * x) >> 96) + 43456485725739037958740375743393;
      p = ((p * x) >> 96) - 11111509109440967052023855526967;
      p = ((p * x) >> 96) - 45023709667254063763336534515857;
      p = ((p * x) >> 96) - 14706773417378608786704636184526;
      p = p * x - (795164235651350426258249787498 << 96);
      //emit log_named_int("p", p);
      // We leave p in 2**192 basis so we don't need to scale it back up for the division.
      // q is monic by convention
      int q = x + 5573035233440673466300451813936;
      q = ((q * x) >> 96) + 71694874799317883764090561454958;
      q = ((q * x) >> 96) + 283447036172924575727196451306956;
      q = ((q * x) >> 96) + 401686690394027663651624208769553;
      q = ((q * x) >> 96) + 204048457590392012362485061816622;
      q = ((q * x) >> 96) + 31853899698501571402653359427138;
      q = ((q * x) >> 96) + 909429971244387300277376558375;
      assembly {
        // Div in assembly because solidity adds a zero check despite the `unchecked`.
        // The q polynomial is known not to have zeros in the domain. (All roots are complex)
        // No scaling required because p is already 2**96 too large.
        r := sdiv(p, q)
      }
      // r is in the range (0, 0.125) * 2**96

      // Finalization, we need to
      // * multiply by the scale factor s = 5.549…
      // * add ln(2**96 / 10**18)
      // * add k * ln(2)
      // * multiply by 10**18 / 2**96 = 5**18 >> 78
      // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
      r *= 1677202110996718588342820967067443963516166;
      // add ln(2) * k * 5e18 * 2**192
      r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
      // add ln(2**96 / 10**18) * 5e18 * 2**192
      r += 600920179829731861736702779321621459595472258049074101567377883020018308;
      // base conversion: mul 2**18 / 2**192
      r >>= 174;
    }
  }

  // Integer log2
  // @returns floor(log2(x)) if x is nonzero, otherwise 0. This is the same
  //          as the location of the highest set bit.
  // Consumes 232 gas. This could have been an 3 gas EVM opcode though.
  function ilog2(uint x) internal pure returns (uint r) {
    assembly {
      r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
      r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
      r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
      r := or(r, shl(4, lt(0xffff, shr(r, x))))
      r := or(r, shl(3, lt(0xff, shr(r, x))))
      r := or(r, shl(2, lt(0xf, shr(r, x))))
      r := or(r, shl(1, lt(0x3, shr(r, x))))
      r := or(r, lt(0x1, shr(r, x)))
    }
  }

  // Computes e^x in 1e18 fixed point.
  function exp(int x) internal pure returns (uint r) {
    unchecked {
      // Input x is in fixed point format, with scale factor 1/1e18.

      // When the result is < 0.5 we return zero. This happens when
      // x <= floor(log(0.5e18) * 1e18) ~ -42e18
      if (x <= -42139678854452767551) {
        return 0;
      }

      // When the result is > (2**255 - 1) / 1e18 we can not represent it
      // as an int256. This happens when x >= floor(log((2**255 -1) / 1e18) * 1e18) ~ 135.
      if (x >= 135305999368893231589) revert ExpOverflow();

      // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
      // for more intermediate precision and a binary basis. This base conversion
      // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
      x = (x << 78) / 5 ** 18;

      // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers of two
      // such that exp(x) = exp(x') * 2**k, where k is an integer.
      // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
      int k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
      x = x - k * 54916777467707473351141471128;
      // k is in the range [-61, 195].

      // Evaluate using a (6, 7)-term rational approximation
      // p is made monic, we will multiply by a scale factor later
      int p = x + 2772001395605857295435445496992;
      p = ((p * x) >> 96) + 44335888930127919016834873520032;
      p = ((p * x) >> 96) + 398888492587501845352592340339721;
      p = ((p * x) >> 96) + 1993839819670624470859228494792842;
      p = p * x + (4385272521454847904632057985693276 << 96);
      // We leave p in 2**192 basis so we don't need to scale it back up for the division.
      // Evaluate using using Knuth's scheme from p. 491.
      int z = x + 750530180792738023273180420736;
      z = ((z * x) >> 96) + 32788456221302202726307501949080;
      int w = x - 2218138959503481824038194425854;
      w = ((w * z) >> 96) + 892943633302991980437332862907700;
      int q = z + w - 78174809823045304726920794422040;
      q = ((q * w) >> 96) + 4203224763890128580604056984195872;
      assembly {
        // Div in assembly because solidity adds a zero check despite the `unchecked`.
        // The q polynomial is known not to have zeros in the domain. (All roots are complex)
        // No scaling required because p is already 2**96 too large.
        r := sdiv(p, q)
      }
      // r should be in the range (0.09, 0.25) * 2**96.

      // We now need to multiply r by
      //  * the scale factor s = ~6.031367120...,
      //  * the 2**k factor from the range reduction, and
      //  * the 1e18 / 2**96 factor for base converison.
      // We do all of this at once, with an intermediate result in 2**213 basis
      // so the final right shift is always by a positive amount.
      r = (uint(r) * 3822833074963236453042738258902158003155416615667) >> uint(195 - k);
    }
  }

  error Overflow();
  error ExpOverflow();
  error LnNegativeUndefined();
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

/**
 * @title Math
 * @author Lyra
 * @dev Library to unify logic for common shared functions
 */
library Math {
  /// @dev Return the minimum value between the two inputs
  function min(uint x, uint y) internal pure returns (uint) {
    return (x < y) ? x : y;
  }

  /// @dev Return the maximum value between the two inputs
  function max(uint x, uint y) internal pure returns (uint) {
    return (x > y) ? x : y;
  }

  /// @dev Compute the absolute value of `val`.
  function abs(int val) internal pure returns (uint) {
    return uint(val < 0 ? -val : val);
  }

  /// @dev Takes ceiling of a to m precision
  /// @param m represents 1eX where X is the number of trailing 0's
  function ceil(uint a, uint m) internal pure returns (uint) {
    return ((a + m - 1) / m) * m;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "openzeppelin-contracts-4.4.1/utils/math/SafeCast.sol";
import "./synthetix/DecimalMath.sol";
import "./libraries/BlackScholes.sol";
import "./interfaces/ILyra.sol";

contract LyraQuoter {
  using DecimalMath for uint256;

  ILyraRegister internal register; // 0x6c87e4364Fd44B0D425ADfD0328e56b89b201329
  IGMXAdapter internal gmxAdapter; // 0x7D135662818d3540bd6f23294bFDB6946c52C9AB

  struct QuoteParameters {
    IOptionMarket optionMarket;
    IOptionGreekCache greekCache;
    IOptionMarketPricer optionPricer;
    IOptionMarket.Strike strike;
    IOptionMarket.OptionBoard board;
    uint256 timeToExpiryAnnualized;
    uint256 iterations;
    uint256 timeToExpiry;
    IOptionGreekCache.GlobalCache globalCache;
    IOptionGreekCache.GreekCacheParameters greekCacheParameters;
    IOptionMarket.TradeParameters trade;
    IOptionGreekCache.BoardGreeksView boardGreek;
  }

  struct FeeParameters {
    uint256 volTraded;
    uint256 optionPrice;
    int256 preTradeAmmNetStdVega;
    int256 postTradeAmmNetStdVega;
    uint256 ivVariance;
    uint256 newSkew;
  }

  constructor(address _lyraRegister) {
    register = ILyraRegister(_lyraRegister);
    gmxAdapter = IGMXAdapter(register.getGlobalAddress(bytes32("GMX_ADAPTER")));
  }

  function _getTimeToExpiryAnnualized(
    IOptionMarket.OptionBoard memory board
  ) internal view returns (uint256 timeToExpiryAnnualized) {
    uint256 timeToExpiry = max(0, board.expiry - block.timestamp);
    timeToExpiryAnnualized = timeToExpiry / (60 * 60 * 24 * 365);
  }

  function _isLong(IOptionMarket.OptionType optionType) internal pure returns (bool) {
    return (optionType == IOptionMarket.OptionType.LONG_CALL || optionType == IOptionMarket.OptionType.LONG_PUT);
  }

  function _checkStrike(
    IOptionMarket optionMarket,
    uint256 strikeId,
    uint256 iterations
  ) internal view returns (IOptionMarket.Strike memory strike) {
    if (strikeId == 0) {
      revert IOptionMarket.ExpectedNonZeroValue(address(this), IOptionMarket.NonZeroValues.STRIKE_ID);
    }
    if (iterations == 0) {
      revert IOptionMarket.ExpectedNonZeroValue(address(this), IOptionMarket.NonZeroValues.ITERATIONS);
    }

    strike = optionMarket.getStrike(strikeId);
    if (strike.id != strikeId) {
      revert IOptionMarket.InvalidStrikeId(address(this), strikeId);
    }
  }

  function _checkBoard(
    IOptionMarket optionMarket,
    IOptionMarket.Strike memory strike
  ) internal view returns (IOptionMarket.OptionBoard memory board) {
    board = optionMarket.getOptionBoard(strike.boardId);
    uint256 boardToPriceAtExpiry = optionMarket.boardToPriceAtExpiry(board.id);
    if (boardToPriceAtExpiry != 0) {
      revert IOptionMarket.BoardAlreadySettled(address(this), board.id);
    }
    if (board.frozen) {
      revert IOptionMarket.BoardIsFrozen(address(this), board.id);
    }
    if (block.timestamp >= board.expiry) {
      revert IOptionMarket.BoardExpired(address(this), board.id, board.expiry, block.timestamp);
    }
  }

  function _getPricing(
    IOptionMarket.TradeDirection tradeDirection,
    IOptionMarket.OptionType optionType,
    bool isForceClose
  ) internal pure returns (IGMXAdapter.PriceType pricing) {
    if (tradeDirection == IOptionMarket.TradeDirection.LIQUIDATE) {
      pricing = IGMXAdapter.PriceType.REFERENCE;
    } else if (
      optionType == IOptionMarket.OptionType.LONG_CALL || optionType == IOptionMarket.OptionType.SHORT_PUT_QUOTE
    ) {
      pricing = tradeDirection == IOptionMarket.TradeDirection.OPEN
        ? IGMXAdapter.PriceType.MAX_PRICE
        : (isForceClose ? IGMXAdapter.PriceType.FORCE_MIN : IGMXAdapter.PriceType.MIN_PRICE);
    } else {
      pricing = tradeDirection == IOptionMarket.TradeDirection.OPEN
        ? IGMXAdapter.PriceType.MIN_PRICE
        : (isForceClose ? IGMXAdapter.PriceType.FORCE_MAX : IGMXAdapter.PriceType.MAX_PRICE);
    }
  }

  function _composeQuote(
    IOptionMarket optionMarket,
    uint256 strikeId,
    uint256 iterations,
    IOptionMarket.OptionType optionType,
    uint256 amount,
    IOptionMarket.TradeDirection tradeDirection,
    bool isForceClose
  ) internal view returns (QuoteParameters memory quoteParameters) {
    IOptionMarket.Strike memory strike = _checkStrike(optionMarket, strikeId, iterations);

    IOptionMarket.OptionBoard memory board = _checkBoard(optionMarket, strike);
    IGMXAdapter.PriceType pricing = _getPricing(tradeDirection, optionType, isForceClose);

    IOptionMarket.TradeParameters memory trade = IOptionMarket.TradeParameters({
      isBuy: (tradeDirection == IOptionMarket.TradeDirection.OPEN) ? _isLong(optionType) : !_isLong(optionType),
      isForceClose: isForceClose,
      tradeDirection: tradeDirection,
      optionType: optionType,
      amount: amount / iterations,
      expiry: board.expiry,
      strikePrice: strike.strikePrice,
      liquidity: register.getMarketAddresses(optionMarket).liquidityPool.getLiquidity(),
      spotPrice: gmxAdapter.getSpotPriceForMarket(optionMarket, pricing)
    });
    ILyraRegister.OptionMarketAddresses memory marketAddresses = register.getMarketAddresses(optionMarket);
    quoteParameters = QuoteParameters({
      optionMarket: optionMarket,
      greekCache: marketAddresses.greekCache,
      optionPricer: marketAddresses.optionMarketPricer,
      strike: strike,
      board: board,
      timeToExpiryAnnualized: _getTimeToExpiryAnnualized(board),
      timeToExpiry: max(0, board.expiry - block.timestamp),
      iterations: iterations,
      globalCache: marketAddresses.greekCache.getGlobalCache(),
      greekCacheParameters: marketAddresses.greekCache.getGreekCacheParams(),
      trade: trade,
      boardGreek: marketAddresses.greekCache.getBoardGreeksView(board.id)
    });
  }

  function _getOptionPrice(QuoteParameters memory params, uint256 volTraded) internal view returns (uint256) {
    (uint256 call, uint256 put) = BlackScholes.optionPrices(
      BlackScholes.BlackScholesInputs({
        timeToExpirySec: params.timeToExpiry,
        volatilityDecimal: volTraded,
        spotDecimal: params.trade.spotPrice,
        strikePriceDecimal: params.strike.strikePrice,
        rateDecimal: gmxAdapter.rateAndCarry(params.optionMarket)
      })
    );

    return
      (params.trade.optionType == IOptionMarket.OptionType.LONG_PUT ||
        params.trade.optionType == IOptionMarket.OptionType.SHORT_PUT_QUOTE)
        ? put
        : call;
  }

  function _getOptionPriceFee(
    IOptionMarketPricer pricer,
    IOptionMarket.OptionBoard memory board,
    uint256 pricePerOption,
    uint256 size
  ) internal view returns (uint256) {
    IOptionMarketPricer.PricingParameters memory pricingParams = pricer.getPricingParams();

    uint256 timeWeightedOptionPriceFee = pricer.getTimeWeightedFee(
      board.expiry,
      pricingParams.optionPriceFee1xPoint,
      pricingParams.optionPriceFee2xPoint,
      pricingParams.optionPriceFeeCoefficient
    );

    return timeWeightedOptionPriceFee.multiplyDecimal(size).multiplyDecimal(pricePerOption);
  }

  function _getSpotPriceFee(
    IOptionMarketPricer pricer,
    IOptionMarket.OptionBoard memory board,
    uint256 size,
    uint256 spotPrice
  ) internal view returns (uint256) {
    IOptionMarketPricer.PricingParameters memory pricingParams = pricer.getPricingParams();

    uint256 timeWeightedSpotPriceFee = pricer.getTimeWeightedFee(
      board.expiry,
      pricingParams.spotPriceFee1xPoint,
      pricingParams.spotPriceFee2xPoint,
      pricingParams.spotPriceFeeCoefficient
    );

    return timeWeightedSpotPriceFee.multiplyDecimal(size).multiplyDecimal(spotPrice);
  }

  function _getOtherFees(
    QuoteParameters memory quoterParams,
    FeeParameters memory params
  ) internal view returns (uint256 vegaFee, uint256 varianceFee) {
    uint256 vegaDecimal = BlackScholes.vega(
      BlackScholes.BlackScholesInputs({
        timeToExpirySec: quoterParams.timeToExpiry,
        volatilityDecimal: params.volTraded,
        spotDecimal: quoterParams.trade.spotPrice,
        strikePriceDecimal: quoterParams.strike.strikePrice,
        rateDecimal: gmxAdapter.rateAndCarry(quoterParams.optionMarket)
      })
    );

    IOptionGreekCache.TradePricing memory pricing = IOptionGreekCache.TradePricing({
      optionPrice: params.optionPrice,
      preTradeAmmNetStdVega: params.preTradeAmmNetStdVega,
      postTradeAmmNetStdVega: params.postTradeAmmNetStdVega,
      callDelta: 0, //Not used on below functions
      volTraded: params.volTraded,
      ivVariance: params.ivVariance,
      vega: vegaDecimal
    });
    IOptionMarketPricer.VegaUtilFeeComponents memory vegaUtilFeeComps = quoterParams.optionPricer.getVegaUtilFee(
      quoterParams.trade,
      pricing
    );
    IOptionMarketPricer.VarianceFeeComponents memory varianceFeeComps = quoterParams.optionPricer.getVarianceFee(
      quoterParams.trade,
      pricing,
      params.newSkew
    );

    vegaFee = vegaUtilFeeComps.vegaUtilFee;
    varianceFee = varianceFeeComps.varianceFee;
  }

  function _getTotalFee(
    FeeParameters memory feeParams,
    QuoteParameters memory quoteParams
  ) internal view returns (uint256 fees) {
    uint256 optionPriceFee = _getOptionPriceFee(
      quoteParams.optionPricer,
      quoteParams.board,
      feeParams.optionPrice,
      quoteParams.trade.amount
    );
    uint256 spotPriceFee = _getSpotPriceFee(
      quoteParams.optionPricer,
      quoteParams.board,
      quoteParams.trade.amount,
      quoteParams.trade.spotPrice
    );

    (uint256 vegaFee, uint256 varianceFee) = _getOtherFees(quoteParams, feeParams);

    fees = optionPriceFee + spotPriceFee + vegaFee + varianceFee;
  }

  function _quoteIteration(
    uint256 baseIv,
    uint256 skew,
    QuoteParameters memory params,
    int256 preTradeAmmNetStdVega
  )
    internal
    view
    returns (uint256 newBaseIv, uint256 newSkew, int256 postTradeAmmNetStdVega, uint256 fees, uint256 premium)
  {
    (newBaseIv, newSkew) = params.optionPricer.ivImpactForTrade(params.trade, baseIv, skew);
    uint256 volTraded = newBaseIv.multiplyDecimal(newSkew);

    uint256 optionPrice = _getOptionPrice(params, volTraded);
    uint256 ivVariance = abs(int256(params.boardGreek.ivGWAV) - int256(newBaseIv));

    int256 netStdVegaDiff = (params.globalCache.netGreeks.netStdVega *
      int256(params.trade.amount) *
      (params.trade.isBuy ? int256(1) : int256(-1))) / 10e18;
    postTradeAmmNetStdVega = preTradeAmmNetStdVega + netStdVegaDiff;
    FeeParameters memory feeParams = FeeParameters({
      volTraded: volTraded,
      optionPrice: optionPrice,
      preTradeAmmNetStdVega: preTradeAmmNetStdVega,
      postTradeAmmNetStdVega: postTradeAmmNetStdVega,
      ivVariance: ivVariance,
      newSkew: newSkew
    });
    fees = _getTotalFee(feeParams, params);
    uint256 base = optionPrice.multiplyDecimal(params.trade.amount);

    premium = params.trade.isBuy ? (base + fees) : (fees < base ? (base - fees) : 0);
  }

  function quote(
    IOptionMarket _optionMarket,
    uint256 strikeId,
    uint256 iterations,
    IOptionMarket.OptionType optionType,
    uint256 amount
  ) public view returns (uint256 totalPremium, uint256 totalFee) {
    QuoteParameters memory params = _composeQuote(
      _optionMarket,
      strikeId,
      iterations,
      optionType,
      amount,
      IOptionMarket.TradeDirection.OPEN,
      false
    );
    int256 preTradeAmmNetStdVega = params.globalCache.netGreeks.netStdVega * (-1);

    uint256 baseIv = params.board.iv;
    uint256 skew = params.strike.skew;

    for (uint256 i = 0; i < params.iterations; i++) {
      (
        uint256 newBaseIv,
        uint256 newSkew,
        int256 postTradeAmmNetStdVega,
        uint256 fee,
        uint256 premium
      ) = _quoteIteration(baseIv, skew, params, preTradeAmmNetStdVega);

      baseIv = newBaseIv;
      skew = newSkew;
      preTradeAmmNetStdVega = postTradeAmmNetStdVega;

      totalPremium = totalPremium + premium;
      totalFee = totalFee + fee;
    }
  }

  function fullQuotes(
    IOptionMarket _optionMarket,
    uint256 strikeId,
    uint256 iterations,
    uint256 amount
  ) external view returns (uint256[] memory, uint256[] memory) {
    uint256[] memory totalPremiums = new uint256[](5);
    uint256[] memory totalFees = new uint256[](5);

    (totalPremiums[0], totalFees[0]) = quote(
      _optionMarket,
      strikeId,
      iterations,
      IOptionMarket.OptionType.LONG_CALL,
      amount
    );
    (totalPremiums[1], totalFees[1]) = quote(
      _optionMarket,
      strikeId,
      iterations,
      IOptionMarket.OptionType.LONG_PUT,
      amount
    );
    (totalPremiums[2], totalFees[2]) = quote(
      _optionMarket,
      strikeId,
      iterations,
      IOptionMarket.OptionType.SHORT_CALL_BASE,
      amount
    );
    (totalPremiums[3], totalFees[3]) = quote(
      _optionMarket,
      strikeId,
      iterations,
      IOptionMarket.OptionType.SHORT_CALL_QUOTE,
      amount
    );
    (totalPremiums[4], totalFees[4]) = quote(
      _optionMarket,
      strikeId,
      iterations,
      IOptionMarket.OptionType.SHORT_PUT_QUOTE,
      amount
    );

    return (totalPremiums, totalFees);
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function abs(int val) internal pure returns (uint) {
    return uint(val < 0 ? -val : val);
  }
}

//SPDX-License-Identifier: MIT
//
//Copyright (c) 2019 Synthetix
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

pragma solidity 0.8.16;

/**
 * @title DecimalMath
 * @author Lyra
 * @dev Modified synthetix SafeDecimalMath to include internal arithmetic underflow/overflow.
 * @dev https://docs.synthetix.io/contracts/source/libraries/SafeDecimalMath/
 */

library DecimalMath {
  /* Number of decimal places in the representations. */
  uint8 public constant decimals = 18;
  uint8 public constant highPrecisionDecimals = 27;

  /* The number representing 1.0. */
  uint public constant UNIT = 10 ** uint(decimals);

  /* The number representing 1.0 for higher fidelity numbers. */
  uint public constant PRECISE_UNIT = 10 ** uint(highPrecisionDecimals);
  uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10 ** uint(highPrecisionDecimals - decimals);

  /**
   * @return Provides an interface to UNIT.
   */
  function unit() external pure returns (uint) {
    return UNIT;
  }

  /**
   * @return Provides an interface to PRECISE_UNIT.
   */
  function preciseUnit() external pure returns (uint) {
    return PRECISE_UNIT;
  }

  /**
   * @return The result of multiplying x and y, interpreting the operands as fixed-point
   * decimals.
   *
   * @dev A unit factor is divided out after the product of x and y is evaluated,
   * so that product must be less than 2**256. As this is an integer division,
   * the internal division always rounds down. This helps save on gas. Rounding
   * is more expensive on gas.
   */
  function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
    /* Divide by UNIT to remove the extra factor introduced by the product. */
    return (x * y) / UNIT;
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of the specified precision unit.
   *
   * @dev The operands should be in the form of a the specified unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function _multiplyDecimalRound(uint x, uint y, uint precisionUnit) private pure returns (uint) {
    /* Divide by UNIT to remove the extra factor introduced by the product. */
    uint quotientTimesTen = (x * y) / (precisionUnit / 10);

    if (quotientTimesTen % 10 >= 5) {
      quotientTimesTen += 10;
    }

    return quotientTimesTen / 10;
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a precise unit.
   *
   * @dev The operands should be in the precise unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
    return _multiplyDecimalRound(x, y, PRECISE_UNIT);
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a standard unit.
   *
   * @dev The operands should be in the standard unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
    return _multiplyDecimalRound(x, y, UNIT);
  }

  /**
   * @return The result of safely dividing x and y. The return value is a high
   * precision decimal.
   *
   * @dev y is divided after the product of x and the standard precision unit
   * is evaluated, so the product of x and UNIT must be less than 2**256. As
   * this is an integer division, the result is always rounded down.
   * This helps save on gas. Rounding is more expensive on gas.
   */
  function divideDecimal(uint x, uint y) internal pure returns (uint) {
    /* Reintroduce the UNIT factor that will be divided out by y. */
    return (x * UNIT) / y;
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * decimal in the precision unit specified in the parameter.
   *
   * @dev y is divided after the product of x and the specified precision unit
   * is evaluated, so the product of x and the specified precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function _divideDecimalRound(uint x, uint y, uint precisionUnit) private pure returns (uint) {
    uint resultTimesTen = (x * (precisionUnit * 10)) / y;

    if (resultTimesTen % 10 >= 5) {
      resultTimesTen += 10;
    }

    return resultTimesTen / 10;
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * standard precision decimal.
   *
   * @dev y is divided after the product of x and the standard precision unit
   * is evaluated, so the product of x and the standard precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
    return _divideDecimalRound(x, y, UNIT);
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * high precision decimal.
   *
   * @dev y is divided after the product of x and the high precision unit
   * is evaluated, so the product of x and the high precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
    return _divideDecimalRound(x, y, PRECISE_UNIT);
  }

  /**
   * @dev Convert a standard decimal representation to a high precision one.
   */
  function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
    return i * UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR;
  }

  /**
   * @dev Convert a high precision decimal to a standard decimal representation.
   */
  function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
    uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

    if (quotientTimesTen % 10 >= 5) {
      quotientTimesTen += 10;
    }

    return quotientTimesTen / 10;
  }
}

//SPDX-License-Identifier: MIT
//
//Copyright (c) 2019 Synthetix
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

pragma solidity 0.8.16;

/**
 * @title SignedDecimalMath
 * @author Lyra
 * @dev Modified synthetix SafeSignedDecimalMath to include internal arithmetic underflow/overflow.
 * @dev https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
 */
library SignedDecimalMath {
  /* Number of decimal places in the representations. */
  uint8 public constant decimals = 18;
  uint8 public constant highPrecisionDecimals = 27;

  /* The number representing 1.0. */
  int public constant UNIT = int(10 ** uint(decimals));

  /* The number representing 1.0 for higher fidelity numbers. */
  int public constant PRECISE_UNIT = int(10 ** uint(highPrecisionDecimals));
  int private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = int(10 ** uint(highPrecisionDecimals - decimals));

  /**
   * @return Provides an interface to UNIT.
   */
  function unit() external pure returns (int) {
    return UNIT;
  }

  /**
   * @return Provides an interface to PRECISE_UNIT.
   */
  function preciseUnit() external pure returns (int) {
    return PRECISE_UNIT;
  }

  /**
   * @dev Rounds an input with an extra zero of precision, returning the result without the extra zero.
   * Half increments round away from zero; positive numbers at a half increment are rounded up,
   * while negative such numbers are rounded down. This behaviour is designed to be consistent with the
   * unsigned version of this library (SafeDecimalMath).
   */
  function _roundDividingByTen(int valueTimesTen) private pure returns (int) {
    int increment;
    if (valueTimesTen % 10 >= 5) {
      increment = 10;
    } else if (valueTimesTen % 10 <= -5) {
      increment = -10;
    }
    return (valueTimesTen + increment) / 10;
  }

  /**
   * @return The result of multiplying x and y, interpreting the operands as fixed-point
   * decimals.
   *
   * @dev A unit factor is divided out after the product of x and y is evaluated,
   * so that product must be less than 2**256. As this is an integer division,
   * the internal division always rounds down. This helps save on gas. Rounding
   * is more expensive on gas.
   */
  function multiplyDecimal(int x, int y) internal pure returns (int) {
    /* Divide by UNIT to remove the extra factor introduced by the product. */
    return (x * y) / UNIT;
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of the specified precision unit.
   *
   * @dev The operands should be in the form of a the specified unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function _multiplyDecimalRound(int x, int y, int precisionUnit) private pure returns (int) {
    /* Divide by UNIT to remove the extra factor introduced by the product. */
    int quotientTimesTen = (x * y) / (precisionUnit / 10);
    return _roundDividingByTen(quotientTimesTen);
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a precise unit.
   *
   * @dev The operands should be in the precise unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function multiplyDecimalRoundPrecise(int x, int y) internal pure returns (int) {
    return _multiplyDecimalRound(x, y, PRECISE_UNIT);
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a standard unit.
   *
   * @dev The operands should be in the standard unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function multiplyDecimalRound(int x, int y) internal pure returns (int) {
    return _multiplyDecimalRound(x, y, UNIT);
  }

  /**
   * @return The result of safely dividing x and y. The return value is a high
   * precision decimal.
   *
   * @dev y is divided after the product of x and the standard precision unit
   * is evaluated, so the product of x and UNIT must be less than 2**256. As
   * this is an integer division, the result is always rounded down.
   * This helps save on gas. Rounding is more expensive on gas.
   */
  function divideDecimal(int x, int y) internal pure returns (int) {
    /* Reintroduce the UNIT factor that will be divided out by y. */
    return (x * UNIT) / y;
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * decimal in the precision unit specified in the parameter.
   *
   * @dev y is divided after the product of x and the specified precision unit
   * is evaluated, so the product of x and the specified precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function _divideDecimalRound(int x, int y, int precisionUnit) private pure returns (int) {
    int resultTimesTen = (x * (precisionUnit * 10)) / y;
    return _roundDividingByTen(resultTimesTen);
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * standard precision decimal.
   *
   * @dev y is divided after the product of x and the standard precision unit
   * is evaluated, so the product of x and the standard precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function divideDecimalRound(int x, int y) internal pure returns (int) {
    return _divideDecimalRound(x, y, UNIT);
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * high precision decimal.
   *
   * @dev y is divided after the product of x and the high precision unit
   * is evaluated, so the product of x and the high precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function divideDecimalRoundPrecise(int x, int y) internal pure returns (int) {
    return _divideDecimalRound(x, y, PRECISE_UNIT);
  }

  /**
   * @dev Convert a standard decimal representation to a high precision one.
   */
  function decimalToPreciseDecimal(int i) internal pure returns (int) {
    return i * UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR;
  }

  /**
   * @dev Convert a high precision decimal to a standard decimal representation.
   */
  function preciseDecimalToDecimal(int i) internal pure returns (int) {
    int quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);
    return _roundDividingByTen(quotientTimesTen);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}