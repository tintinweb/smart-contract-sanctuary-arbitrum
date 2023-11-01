// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "../IUtilityToken.sol";
import "../feerouter/IFeeRouter.sol";

interface IConfig {
    struct StableCoinEnabled {
        bool buyEnabled;
        bool sellEnabled;
        bool exists;
        address gauge;
        bool isMetaGauge;
    }

    function vammBuyFees(uint256 totalPrice) external view returns (uint256);

    function vammSellFees(uint256 totalPrice) external view returns (uint256);

    function getVAMMStableCoin(
        address stableCoin
    ) external view returns (StableCoinEnabled memory);

    function getStableCoins() external view returns (address[] memory);

    function getMaxOnceExchangeAmount() external view returns (uint256);

    function getFeeRouter() external view returns (IFeeRouter);

    function getUtilityToken() external view returns (IUtilityToken);

    function getPRToken() external view returns (IUtilityToken);

    function getGovToken() external view returns (IUtilityToken);

    function getStableCoinToken() external view returns (IUtilityToken);

    function getUtilityStakeAddress() external view returns (address);

    function getLiquidityStakeAddress() external view returns (address);

    function getVAMMAddress() external view returns (address);

    function getMinterAddress() external view returns (address);

    function getCurveStableCoin2CRVPoolAddress()
        external
        view
        returns (address);

    function checkIsOperator(address _operator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IFeeRouter {
    function colletFees() external;

    function getDAOVault() external view returns (address);

    function getGewardVault() external view returns (address);

    function getPercentForGeward() external view returns (uint256);

    function getTokens() external view returns (address[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IPriceField {
    event UpdateFloorPrice(uint256 newFloorPrice);

    function setFloorPrice(uint256 floorPrice_) external;

    function increaseSupplyWithNoPriceImpact(uint256 amount) external;

    function exerciseAmount() external view returns (uint256);

    function slope() external view returns (uint256);

    function slope0() external view returns (uint256);

    function floorPrice() external view returns (uint256);

    function x1(uint256 targetFloorPrice) external view returns (uint256);

    function x1() external view returns (uint256);

    function x2() external view returns (uint256);

    function c() external view returns (uint256);

    function c1() external view returns (uint256);

    function b2() external view returns (uint256);

    function k() external view returns (uint256);

    function finalPrice1(uint256 x, bool round) external view returns (uint256);

    function finalPrice2(uint256 x, bool round) external view returns (uint256);

    function getPrice1(
        uint256 xs,
        uint256 xe,
        bool round
    ) external view returns (uint256);

    function getPrice2(
        uint256 xs,
        uint256 xe,
        bool round
    ) external view returns (uint256);

    function getUseFPBuyPrice(
        uint256 amount
    ) external view returns (uint256 toLiquidityPrice, uint256 fees);

    function getBuyPrice(
        uint256 amount
    ) external view returns (uint256 toLiquidityPrice, uint256 fees);

    function getSellPrice(
        uint256 xe,
        uint256 amount
    ) external view returns (uint256 toUserPrice, uint256 fees);

    function getSellPrice(
        uint256 amount
    ) external view returns (uint256 toUserPrice, uint256 fees);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUtilityToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./config/IConfig.sol";
import "./IPriceField.sol";

contract PriceField is IPriceField {
    uint128 public constant PRICE_PRECISION = 1e18;

    uint128 public constant PRECENT_DENOMINATOR = 10000000000;

    IConfig private _config;

    // main slope
    // 10 decimals
    uint256 private _slope;

    //
    uint256 private _exerciseAmount;

    // current floor price
    uint256 private _floorPrice;

    constructor(IConfig config_, uint256 slope_, uint256 floorPrice_) {
        _config = config_;
        _slope = slope_;
        _exerciseAmount = 0;

        _setFloorPrice(floorPrice_);
    }

    modifier onlyVamm() {
        require(
            msg.sender == address(_config.getVAMMAddress()),
            "PriceField: caller is not the vamm"
        );
        _;
    }

    function _setFloorPrice(uint256 floorPrice_) internal {
        require(floorPrice_ >= PRICE_PRECISION / 2, "floor price too low");
        require(floorPrice_ > _floorPrice, "floor price too low");
        uint256 x3 = _config.getUtilityToken().totalSupply();
        if (x3 > c()) {
            uint256 maxFloorPrice = (Math.mulDiv(
                x3 - c(),
                _slope,
                PRECENT_DENOMINATOR,
                Math.Rounding.Zero
            ) + PRICE_PRECISION) / 2;
            _floorPrice = Math.min(floorPrice_, maxFloorPrice);
        } else if (_floorPrice == 0) {
            _floorPrice = floorPrice_;
        } else if (x3 > x1(floorPrice_) + _exerciseAmount) {
            _floorPrice = floorPrice_;
        } else if (x3 == 0) {
            _floorPrice = floorPrice_;
        }
        emit UpdateFloorPrice(_floorPrice);
    }

    function setFloorPrice(uint256 floorPrice_) external onlyVamm {
        _setFloorPrice(floorPrice_);
    }

    function increaseSupplyWithNoPriceImpact(uint256 amount) external onlyVamm {
        _exerciseAmount += amount;
    }

    function exerciseAmount() external view returns (uint256) {
        return _exerciseAmount;
    }

    function slope() external view returns (uint256) {
        return _slope;
    }

    function slope0() external view returns (uint256) {
        uint256 a = _floorPrice;
        uint256 b = _finalPrice1(x2() + _exerciseAmount, false);
        uint256 h = x2() - x1();
        return Math.mulDiv(b - a, PRECENT_DENOMINATOR, h);
    }

    function floorPrice() external view returns (uint256) {
        return _floorPrice;
    }

    function x1(uint256 targetFloorPrice) public view returns (uint256) {
        // (2fp - 1)/m
        return
            Math.mulDiv(
                (targetFloorPrice * 2 - PRICE_PRECISION),
                PRECENT_DENOMINATOR,
                _slope,
                Math.Rounding.Zero
            );
    }

    function x1() public view returns (uint256) {
        // (2fp - 1)/m
        return
            Math.mulDiv(
                (_floorPrice * 2 - PRICE_PRECISION),
                PRECENT_DENOMINATOR,
                _slope,
                Math.Rounding.Zero
            );
    }

    function x2() public view returns (uint256) {
        // x2 = x1+2/m
        return x1() + c();
    }

    function c() public view returns (uint256) {
        // 2/m
        return
            Math.mulDiv(
                2 * PRICE_PRECISION,
                PRECENT_DENOMINATOR,
                _slope,
                Math.Rounding.Zero
            );
    }

    function c1() public view returns (uint256) {
        // x1 + 1/m
        return
            x1() +
            Math.mulDiv(
                PRICE_PRECISION,
                PRECENT_DENOMINATOR,
                _slope,
                Math.Rounding.Zero
            );
    }

    function b2() public view returns (uint256) {
        // m*x2
        return Math.mulDiv(x2(), _slope, PRECENT_DENOMINATOR, Math.Rounding.Up);
    }

    function k() public view returns (uint256) {
        // b2-fp
        return b2() - _floorPrice;
    }

    function finalPrice1(
        uint256 x,
        bool round
    ) external view returns (uint256) {
        return _finalPrice1(x, round);
    }

    function finalPrice2(
        uint256 x,
        bool round
    ) external view returns (uint256) {
        return _finalPrice2(x, round);
    }

    function _finalPrice1(
        uint256 x,
        bool round
    ) internal view returns (uint256) {
        require(x >= x1() + _exerciseAmount, "x too low");
        require(x <= x2() + _exerciseAmount, "x too high");
        if (x < c1() + _exerciseAmount) {
            return
                Math.mulDiv(
                    PRICE_PRECISION -
                        Math.mulDiv(
                            c1() + _exerciseAmount - x,
                            _slope,
                            PRECENT_DENOMINATOR,
                            round ? Math.Rounding.Up : Math.Rounding.Zero
                        ),
                    k(),
                    2 * PRICE_PRECISION
                ) + _floorPrice;
        }
        // ((x-c1-s) * m + 1) * k / 2 + fp
        return
            Math.mulDiv(
                Math.mulDiv(
                    x - c1() - _exerciseAmount,
                    _slope,
                    PRECENT_DENOMINATOR,
                    round ? Math.Rounding.Up : Math.Rounding.Zero
                ) + PRICE_PRECISION,
                k(),
                2 * PRICE_PRECISION
            ) + _floorPrice;
    }

    function _finalPrice2(
        uint256 x,
        bool round
    ) internal view returns (uint256) {
        require(x >= x2() + _exerciseAmount, "x too low");
        // (x-s) * m
        return
            Math.mulDiv(
                x - _exerciseAmount,
                _slope,
                PRECENT_DENOMINATOR,
                round ? Math.Rounding.Up : Math.Rounding.Zero
            );
    }

    function getPrice1(
        uint256 xs,
        uint256 xe,
        bool round
    ) external view returns (uint256) {
        return _getPrice1(xs, xe, round);
    }

    function getPrice2(
        uint256 xs,
        uint256 xe,
        bool round
    ) external view returns (uint256) {
        return _getPrice2(xs, xe, round);
    }

    // Calculate the total price of the price1 based on two points
    function _getPrice1(
        uint256 xs,
        uint256 xe,
        bool round
    ) internal view returns (uint256) {
        require(xs <= xe, "xs > xe");
        uint256 p1xs = xs;
        uint256 p1xe = xe;

        if (xs > x2() + _exerciseAmount) {
            return 0;
        }

        if (xe < x1() + _exerciseAmount) {
            return 0;
        }

        if (xs < x1() + _exerciseAmount) {
            p1xs = x1() + _exerciseAmount;
        }

        if (xe > x2() + _exerciseAmount) {
            p1xe = x2() + _exerciseAmount - 1;
        }

        uint256 a = _finalPrice1(p1xs, round);
        uint256 b = _finalPrice1(p1xe, round);

        return
            Math.mulDiv(
                a + b,
                p1xe - p1xs,
                2 * PRICE_PRECISION,
                round ? Math.Rounding.Up : Math.Rounding.Zero
            );
    }

    // Calculate the total price of the price2 based on two points
    function _getPrice2(
        uint256 xs,
        uint256 xe,
        bool round
    ) internal view returns (uint256) {
        require(xs <= xe, "xs > xe");

        if (xe < x2() + _exerciseAmount) {
            return 0;
        }
        
        uint256 p2xs = xs;
        uint256 p2xe = xe;

        if (xs < x2() + _exerciseAmount) {
            p2xs = x2() + _exerciseAmount;
        }

        uint256 a = _finalPrice2(p2xs, round);
        uint256 b = _finalPrice2(p2xe, round);

        return
            Math.mulDiv(
                a + b,
                p2xe - p2xs,
                2 * PRICE_PRECISION,
                round ? Math.Rounding.Up : Math.Rounding.Zero
            );
    }

    // Calculate the total price of the floor price based on two points
    function _getPrice0(
        uint256 xs,
        uint256 xe,
        bool round
    ) internal view returns (uint256) {
        require(xs <= xe, "xs > xe");
        uint256 fpAmount = 0;
        if (xs < x1() + _exerciseAmount) {
            fpAmount = x1() + _exerciseAmount - xs;
        }
        if (xe < x1() + _exerciseAmount) {
            fpAmount = xe - xs;
        }

        return
            Math.mulDiv(
                fpAmount,
                _floorPrice,
                PRICE_PRECISION,
                round ? Math.Rounding.Up : Math.Rounding.Zero
            );
    }

    function getUseFPBuyPrice(
        uint256 amount
    ) public view returns (uint256 toLiquidityPrice, uint256 fees) {
        toLiquidityPrice = Math.mulDiv(
            _floorPrice,
            amount,
            PRICE_PRECISION,
            Math.Rounding.Up
        );
        fees = _config.vammBuyFees(toLiquidityPrice);
    }

    function getBuyPrice(
        uint256 amount
    ) external view returns (uint256 toLiquidityPrice, uint256 fees) {
        uint256 xs = _config.getUtilityToken().totalSupply() + 1;
        uint256 xe = xs + amount;
        uint256 price1 = _getPrice1(xs, xe, true);
        uint256 price2 = _getPrice2(xs, xe, true);
        uint256 price0 = _getPrice0(xs, xe, true);
        toLiquidityPrice = price1 + price2 + price0;
        fees = _config.vammBuyFees(toLiquidityPrice);
    }

    function getSellPrice(
        uint256 xe,
        uint256 amount
    ) external view returns (uint256 toUserPrice, uint256 fees) {
        uint256 xs = xe - amount;
        uint256 price1 = _getPrice1(xs, xe, false);
        uint256 price2 = _getPrice2(xs, xe, false);
        uint256 price0 = _getPrice0(xs, xe, false);
        uint256 totalPrice = price1 + price2 + price0;
        fees = _config.vammSellFees(totalPrice);
        toUserPrice = totalPrice - fees;
    }

    function getSellPrice(
        uint256 amount
    ) external view returns (uint256 toUserPrice, uint256 fees) {
        uint256 xe = _config.getUtilityToken().totalSupply();
        if (xe == 0) {
            return (0, 0);
        }
        uint256 xs = xe - amount;
        uint256 price1 = _getPrice1(xs, xe, false);
        uint256 price2 = _getPrice2(xs, xe, false);
        uint256 price0 = _getPrice0(xs, xe, false);
        uint256 totalPrice = price1 + price2 + price0;
        fees = _config.vammSellFees(totalPrice);
        toUserPrice = totalPrice - fees;
    }
}