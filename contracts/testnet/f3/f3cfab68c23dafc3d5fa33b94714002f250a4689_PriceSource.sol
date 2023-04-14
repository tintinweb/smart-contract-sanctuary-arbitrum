// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {AggregatorV3Interface} from "chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {PriceLib, UFixed128} from "./libraries/PriceLib.sol";
import {PriceSourceLib} from "./libraries/PriceSourceLib.sol";
import {SubIndexLib} from "./libraries/SubIndexLib.sol";

import {IPriceSource} from "./interfaces/IPriceSource.sol";

/// @title PriceSourceErrors interface
/// @notice Contains PriceSource's errors
interface IPriceSourceErrors {
    /// @dev Reverts if price is stale
    error PriceSourceStale();
    /// @dev Reverts if price hasn't been updated more than max allowed interval
    error PriceSourceInterval();
    /// @dev Reverts if there are no aggregators for corresponded asset
    error PriceSourceAggregators();
}

/// @title PriceSource abstract contract
/// @notice Contains logic to retrieve price of asset using Chainlink's aggregators
contract PriceSource is IPriceSource, IPriceSourceErrors {
    using FixedPointMathLib for uint256;
    using PriceLib for uint256;

    /// @dev 10 ** decimals of USDC
    uint32 private constant BASE_FACTOR = 1e6;

    /// @dev Maximal allowed time interval between price updates
    uint32 private constant MAX_INTERVAL = 1 days;

    /// @inheritdoc IPriceSource
    function encode(uint8 decimals, address[] memory aggregators) external view override returns (bytes memory) {
        PriceSourceLib.Source memory priceSource;
        priceSource.aggregatorDecimals = new uint8[](aggregators.length);
        priceSource.aggregators = new address[](aggregators.length);
        for (uint256 i; i < aggregators.length; ++i) {
            priceSource.aggregators[i] = aggregators[i];
            priceSource.aggregatorDecimals[i] = AggregatorV3Interface(aggregators[i]).decimals();
        }
        priceSource.decimals = decimals;

        return abi.encode(priceSource);
    }

    /// @inheritdoc IPriceSource
    function prices(SubIndexDetails[] calldata details) external view override returns (UFixed128[][] memory result) {
        uint256 length = details.length;
        result = new UFixed128[][](length);
        for (uint256 i; i < length;) {
            address[] memory assets_ = details[i].assets;
            uint256 assetsLength = assets_.length;

            uint256 chainId = details[i].chainId;

            result[i] = new UFixed128[](assetsLength);

            for (uint256 j; j < assetsLength;) {
                result[i][j] =
                    _price(abi.decode(PriceSourceLib.priceSourceOf(assets_[j], chainId), (PriceSourceLib.Source)));
                unchecked {
                    j = j + 1;
                }
            }

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IPriceSource
    function price(address asset, uint256 chainId) external view override returns (UFixed128 result) {
        return _price(abi.decode(PriceSourceLib.priceSourceOf(asset, chainId), (PriceSourceLib.Source)));
    }

    /// @inheritdoc IPriceSource
    function decode(bytes memory data) external pure override returns (PriceSourceLib.Source memory) {
        return abi.decode(data, (PriceSourceLib.Source));
    }

    /// @dev Calculates price based on given source information
    ///
    /// @param source Source to fetch price from
    ///
    /// @return Price of asset
    function _price(PriceSourceLib.Source memory source) internal view returns (UFixed128) {
        uint256 aggregatorsCount = source.aggregators.length;

        if (aggregatorsCount == 0) {
            revert PriceSourceAggregators();
        }

        uint256 price_ = PriceLib.Q128.mulDivUp(
            10 ** source.aggregatorDecimals[0], _getChainlinkPrice(source.aggregators[0])
        ) * 10 ** source.decimals / BASE_FACTOR;

        if (aggregatorsCount != 1) {
            for (uint256 i = 1; i < aggregatorsCount;) {
                price_ = price_.mulDivUp(10 ** source.aggregatorDecimals[i], _getChainlinkPrice(source.aggregators[i]));

                unchecked {
                    i = i + 1;
                }
            }
        }

        return UFixed128.wrap(price_);
    }

    /// @dev Validates and returns the latest asset's price from Chainlink's aggregator
    ///
    /// @param aggregator AggregatorV3Interface contract instance
    ///
    /// @return Price of asset
    function _getChainlinkPrice(address aggregator) private view returns (uint256) {
        (uint80 roundID, int256 price_,, uint256 updatedAt, uint80 answeredInRound) =
            AggregatorV3Interface(aggregator).latestRoundData();
        if (updatedAt == 0 || price_ < 1 || answeredInRound < roundID) {
            revert PriceSourceStale();
        }

        if (block.timestamp - updatedAt > MAX_INTERVAL) {
            revert PriceSourceInterval();
        }

        return uint256(price_);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {AggregatorV3Interface} from "chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {SubIndexLib} from "../libraries/SubIndexLib.sol";
import {UFixed128} from "../libraries/PriceLib.sol";
import {PriceSourceLib} from "../libraries/PriceSourceLib.sol";

/// @title PriceSource interface
/// @notice Returns prices of Index's constituents, encodes and decodes `Source`
interface IPriceSource {
    struct SubIndexDetails {
        uint256 chainId;
        address[] assets;
    }

    /// @notice Creates and encodes `Source`
    ///
    /// @param decimals Decimals of underlying asset
    /// @param aggregators List of aggregators
    ///
    /// @return Encoded `Source`
    function encode(uint8 decimals, address[] calldata aggregators) external view returns (bytes memory);

    /// @notice Returns price of given constituent
    ///
    /// @param asset Asset address
    /// @param chainId Chain id
    ///
    /// @return result Price of given constituent
    function price(address asset, uint256 chainId) external view returns (UFixed128 result);

    /// @notice Returns prices for constituents of given chains
    ///
    /// @param details Details of SubIndex
    ///
    /// @return result Prices for constituents of given chains
    function prices(SubIndexDetails[] calldata details) external view returns (UFixed128[][] memory result);

    /// @notice Decodes `bytes`
    ///
    /// @param data Bytes of `Source`
    ///
    /// @return Price `Source`
    function decode(bytes memory data) external pure returns (PriceSourceLib.Source memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

type UFixed128 is uint256;

library PriceLib {
    using FixedPointMathLib for uint256;

    /// @dev 2**128
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    function convertToAssets(uint256 base, UFixed128 price) internal pure returns (uint256) {
        return base.mulDivDown(UFixed128.unwrap(price), Q128);
    }

    function convertToBase(uint256 assets, UFixed128 price) internal pure returns (uint256) {
        return assets.mulDivDown(Q128, UFixed128.unwrap(price));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

/// @dev Reverts if `Source` for asset is not found
error PriceSourceLibInvalid(address, uint256);

library PriceSourceLib {
    /// @notice PriceSource info
    ///
    /// @param aggregators Array of aggregator's details
    /// @param decimals Decimals of underlying asset
    /// @param aggregatorDecimals Array of aggregator decimals
    struct Source {
        uint8 decimals;
        address[] aggregators;
        uint8[] aggregatorDecimals;
    }

    /**
     * @dev Encoded price source for WETH:
     *  decimals: 18
     *  aggregators: [0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419]
     */
    bytes private constant WETH =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000005f4ec3df9cbd43714fe2740f5e3616155c5b841900000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for UNI:
     *  decimals: 18
     *  aggregators: [0x553303d460ee0afb37edff9be42922d8ff63220e]
     */
    bytes private constant UNI =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000553303d460ee0afb37edff9be42922d8ff63220e00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for SXP:
     *  decimals: 18
     *  aggregators: [0xFb0CfD6c19e25DB4a08D8a204a387cEa48Cc138f]
     */
    bytes private constant SXP =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000fb0cfd6c19e25db4a08d8a204a387cea48cc138f00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for AAVE:
     *  decimals: 18
     *  aggregators: [0x547a514d5e3769680Ce22B2361c10Ea13619e8a9]
     */
    bytes private constant AAVE =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000547a514d5e3769680ce22b2361c10ea13619e8a900000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for MKR:
     *  decimals: 18
     *  aggregators: [0xec1D1B3b0443256cc3860e24a46F108e699484Aa]
     */
    bytes private constant MKR =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000ec1d1b3b0443256cc3860e24a46f108e699484aa00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for LDO:
     *  decimals: 18
     *  aggregators: [0x4e844125952D32AcdF339BE976c98E22F6F318dB, 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419]
     */
    bytes private constant LDO =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000020000000000000000000000004e844125952d32acdf339be976c98e22f6f318db0000000000000000000000005f4ec3df9cbd43714fe2740f5e3616155c5b8419000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for INCH:
     *  decimals: 18
     *  aggregators: [0xc929ad75B72593967DE83E7F7Cda0493458261D9]
     */
    bytes private constant INCH =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c929ad75b72593967de83e7f7cda0493458261d900000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for AMP:
     *  decimals: 18
     *  aggregators: [0xD9BdD9f5ffa7d89c846A5E3231a093AE4b3469D2]
     */
    bytes private constant AMP =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000d9bdd9f5ffa7d89c846a5e3231a093ae4b3469d200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for COMP:
     *  decimals: 18
     *  aggregators: [0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5]
     */
    bytes private constant COMP =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000dbd020caef83efd542f4de03e3cf0c28a4428bd500000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for YFI:
     *  decimals: 18
     *  aggregators: [0xA027702dbb89fbd58938e4324ac03B58d812b0E1]
     */
    bytes private constant YFI =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000a027702dbb89fbd58938e4324ac03b58d812b0e100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for SUSHI:
     *  decimals: 18
     *  aggregators: [0xCc70F09A6CC17553b2E31954cD36E4A2d89501f7]
     */
    bytes private constant SUSHI =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000cc70f09a6cc17553b2e31954cd36e4a2d89501f700000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for BAL:
     *  decimals: 18
     *  aggregators: [0xdF2917806E30300537aEB49A7663062F4d1F2b5F]
     */
    bytes private constant BAL =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000df2917806e30300537aeb49a7663062f4d1f2b5f00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for SNX:
     *  decimals: 18
     *  aggregators: [0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699]
     */
    bytes private constant SNX =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000dc3ea94cd0ac27d9a86c180091e7f78c683d369900000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for CRV:
     *  decimals: 18
     *  aggregators: [0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f]
     */
    bytes private constant CRV =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000cd627aa160a6fa45eb793d19ef54f5062f20f33f00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for CVX:
     *  decimals: 18
     *  aggregators: [0xd962fC30A72A84cE50161031391756Bf2876Af5D]
     */
    bytes private constant CVX =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000d962fc30a72a84ce50161031391756bf2876af5d00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for LRC:
     *  decimals: 18
     *  aggregators: [0x160AC928A16C93eD4895C2De6f81ECcE9a7eB7b4, 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419]
     */
    bytes private constant LRC =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000160ac928a16c93ed4895c2de6f81ecce9a7eb7b40000000000000000000000005f4ec3df9cbd43714fe2740f5e3616155c5b8419000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for FXS:
     *  decimals: 18
     *  aggregators: [0x6Ebc52C8C1089be9eB3945C4350B68B8E4C2233f]
     */
    bytes private constant FXS =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000006ebc52c8c1089be9eb3945c4350b68b8e4c2233f00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for LINK:
     *  decimals: 18
     *  aggregators: [0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c]
     */
    bytes private constant LINK =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000002c1d072e956affc0d435cb7ac38ef18d24d9127c00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for DAI:
     *  decimals: 18
     *  aggregators: [0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9]
     */
    bytes private constant DAI =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000aed0c38402a5d19df6e4c03f4e2dced6e29c1ee900000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for BNB:
     *  decimals: 18
     *  aggregators: [0x14e613AC84a31f709eadbdF89C6CC390fDc9540A]
     */
    bytes private constant BNB =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000014e613ac84a31f709eadbdf89c6cc390fdc9540a00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for MATIC:
     *  decimals: 18
     *  aggregators: [0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676]
     */
    bytes private constant MATIC =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000007bac85a8a13a4bcd8abb3eb7d6b4d632c5a5767600000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for ZRX:
     *  decimals: 18
     *  aggregators: [0x2Da4983a622a8498bb1a21FaE9D8F6C664939962]
     */
    bytes private constant ZRX =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000002da4983a622a8498bb1a21fae9d8f6c66493996200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000012";

    /**
     * @dev Encoded price source for BAT:
     *  decimals: 18
     *  aggregators: [0x0d16d4528239e9ee52fa531af613AcdB23D88c94]
     */
    bytes private constant BAT =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000d16d4528239e9ee52fa531af613acdb23d88c9400000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000012";

    /**
     * @dev Encoded price source for MANA:
     *  decimals: 18
     *  aggregators: [0x82A44D92D6c329826dc557c5E1Be6ebeC5D5FeB9, 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419]
     */
    bytes private constant MANA =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000200000000000000000000000082a44d92d6c329826dc557c5e1be6ebec5d5feb90000000000000000000000005f4ec3df9cbd43714fe2740f5e3616155c5b8419000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000008";

    /**
     * @dev Encoded price source for DASH:
     *  decimals: 18
     *  aggregators: [0xFb0cADFEa136E9E343cfb55B863a6Df8348ab912]
     */
    bytes private constant DASH =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000fb0cadfea136e9e343cfb55b863a6df8348ab91200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    bytes private constant WETH_ARB_GOERLI =
        hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000062cae0fa2da220f43a51f86db2edb36dca9a5a0800000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";

    /// @dev Returns encoded `Source` for given constiturnt info
    ///
    /// @param asset Address of underlying asset
    /// @param chainId ChainIf of underlying asset's network
    ///
    /// @return Encoded `Source`
    function priceSourceOf(address asset, uint256 chainId) internal pure returns (bytes memory) {
        if (chainId == 1) {
            if (asset == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) return WETH;
            else if (asset == 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984) return UNI;
            else if (asset == 0x8CE9137d39326AD0cD6491fb5CC0CbA0e089b6A9) return SXP;
            else if (asset == 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9) return AAVE;
            else if (asset == 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2) return MKR;
            else if (asset == 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32) return LDO;
            else if (asset == 0x111111111117dC0aa78b770fA6A738034120C302) return INCH;
            else if (asset == 0xfF20817765cB7f73d4bde2e66e067E58D11095C2) return AMP;
            else if (asset == 0xc00e94Cb662C3520282E6f5717214004A7f26888) return COMP;
            else if (asset == 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e) return YFI;
            else if (asset == 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2) return SUSHI;
            else if (asset == 0xba100000625a3754423978a60c9317c58a424e3D) return BAL;
            else if (asset == 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F) return SNX;
            else if (asset == 0xD533a949740bb3306d119CC777fa900bA034cd52) return CRV;
            else if (asset == 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B) return CVX;
            else if (asset == 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD) return LRC;
            else if (asset == 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0) return FXS;
            else if (asset == 0x514910771AF9Ca656af840dff83E8264EcF986CA) return LINK;
            else if (asset == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return DAI;
            else if (asset == 0xE41d2489571d322189246DaFA5ebDe1F4699F498) return ZRX;
            else if (asset == 0x0D8775F648430679A709E98d2b0Cb6250d2887EF) return BAT;
            else if (asset == 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942) return MANA;
        } else if (chainId == 56) {
            if (asset == 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c) return BNB;
            else if (asset == 0x023B5F2e3779171380383b4CA8aA751ACfBbeF4c) return DASH;
        } else if (chainId == 137) {
            if (asset == 0x0000000000000000000000000000000000001010) return MATIC;
        }
        // return WETH;
        return WETH_ARB_GOERLI;
        // revert PriceSourceLibInvalid(asset, chainId);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

library SubIndexLib {
    struct SubIndex {
        // TODO: make it uint128 ?
        uint256 id;
        uint256 chainId;
        address[] assets;
        uint256[] balances;
    }

    // TODO: increase precision
    uint32 internal constant TOTAL_SUPPLY = type(uint32).max;
}