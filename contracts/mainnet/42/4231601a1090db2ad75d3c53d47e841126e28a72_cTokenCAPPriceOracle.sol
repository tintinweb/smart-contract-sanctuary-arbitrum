/**
 *Submitted for verification at Arbiscan on 2023-05-20
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface cToken {
    function underlying() external view returns (address);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface UniswapV3Pool{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function observe(uint32[] calldata secondsAgos) external view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

interface ChainLinkOracle{
    function latestAnswer() external view returns (int256);
}

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address cToken) virtual external view returns (uint);
}

contract cTokenCAPPriceOracle is PriceOracle {
    address constant CAP_WETH_UNISWAP_ADDRESS = address(0x3Be3EBc2C4c0e65d444D6254aE9b1486F0d801EE);
    uint256 internal constant CHAINLINK_ETH_PRICE_SCALE = 8;
    address constant ETH_CHAINLINK_ORACLE = address(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
    
    // All prices are either mantissa with 18 decimals or 0 if stale price. 0 reverts on main contract
    function getUnderlyingPrice(address cTokenAddress) override external view returns (uint256) {
        cTokenAddress; // Not used here
        uint256 price = getUniswapTwapPrice(CAP_WETH_UNISWAP_ADDRESS, 86400); // Get the average ETH price over last day
        price = getUSDPriceFromETH(price);
        return price;
    }

    function getUSDPriceFromETH(uint256 ethPrice) internal view returns (uint256) {
        return ethPrice * uint256(ChainLinkOracle(ETH_CHAINLINK_ORACLE).latestAnswer()) / (10 ** CHAINLINK_ETH_PRICE_SCALE);
    }

    // This function returns the token0 price
    function getUniswapTwapPrice(address uniswapPoolAddress, uint32 secRange) internal view returns (uint256) {
        UniswapV3Pool pool = UniswapV3Pool(uniswapPoolAddress);
        uint32[] memory timePeriods = new uint32[](2);
        timePeriods[0] = secRange;
        timePeriods[1] = 0;
        (int56[] memory ticks, ) = pool.observe(timePeriods);
        int56 ticksDelta = ticks[1] - ticks[0];
        if(ticksDelta == 0) { return 0; } // Cannot determine price right now
        int24 arithmeticMeanTick = int24(ticksDelta / int32(secRange));
        // Always round to negative infinity
        if (ticksDelta < 0 && (ticksDelta % int32(secRange) != 0)) { arithmeticMeanTick--; }
        // Calculate the price (formula 1.0001 * ticksDelta * token0 decimals / token1 decimals) of token0 compared to token1
        uint256 price = 0;
        uint256 mantissa = 1.0001 ether;
        if(arithmeticMeanTick >= 0){
            uint24 exponent = uint24(arithmeticMeanTick);
            price = wpow(mantissa, exponent);
        }else{
            uint24 exponent = uint24(arithmeticMeanTick * -1);
            price = wpow(mantissa, exponent);
            price = 1e18 * 1e18 / price; // Inverted price
        }
        uint8 token0Decimals = IERC20(pool.token0()).decimals();
        uint8 token1Decimals = IERC20(pool.token1()).decimals();
        price = price * (10**token0Decimals) / (10**token1Decimals); // Normalize price
        return price;
    }

    // Math stuff
    // Use decimal math to do power equation with 18 decimals of precision
    // Borrowed from DS-Math
    uint constant WAD = 10 ** 18;

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function wpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : WAD;

        for (n /= 2; n != 0; n /= 2) {
            x = wmul(x, x);

            if (n % 2 != 0) {
                z = wmul(z, x);
            }
        }
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
    
}