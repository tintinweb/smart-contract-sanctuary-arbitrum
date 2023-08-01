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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IChainlinkOracle {
  function consult(address _token) external view returns (int256 price, uint8 decimals);
  function consultIn18Decimals(address _token) external view returns (uint256 price);
  function addTokenPriceFeed(address _token, address _feed) external;
  function addTokenMaxDelay(address _token, uint256 _maxDelay) external;
  function addTokenMaxDeviation(address _token, uint256 _maxDeviation) external;
  function emergencyPause() external;
  function emergencyResume() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICamelotFactory {
  function allPairsLength() external view returns (uint256);

  function allPairs(uint256 i) external view returns (address);

  function getPair(address token0, address token1) external view returns (address);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function setStableOwner() external view returns (address);

  function feeInfo() external view returns (uint256, address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICamelotPair {
  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function getReserves() external view returns(
    uint112 reserve0,
    uint112 reserve1,
    uint16 token0FeePercent,
    uint16 token1FeePercent
  );

  function totalSupply() external view returns (uint256);

  function stableSwap() external view returns (bool);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function factory() external view returns (address);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
      address from,
      address to,
      uint256 value
  ) external returns (bool);

  function kLast() external view returns (uint256);

  function precisionMultiplier0() external view returns (uint256);
  function precisionMultiplier1() external view returns (uint256);

  function FEE_DENOMINATOR() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICamelotRouter {
  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external;

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external;

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external;

  function getAmountsOut(
    uint amountIn,
    address[] calldata path
  ) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/swaps/camelot/ICamelotPair.sol";
import "../interfaces/swaps/camelot/ICamelotFactory.sol";
import "../interfaces/swaps/camelot/ICamelotRouter.sol";
import "../interfaces/oracles/IChainlinkOracle.sol";

contract CamelotOracle {
  /* ========== STATE VARIABLES ========== */

  // Camelot factory
  ICamelotFactory public immutable factory;
  // Camelot router
  ICamelotRouter public immutable router;
  // Chainlink oracle
  IChainlinkOracle public immutable chainlinkOracle;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param _factory Address of Camelot factory
    * @param _router Address of Camelot router
    * @param _chainlinkOracle Address of Chainlink oracle
  */
  constructor(ICamelotFactory _factory, ICamelotRouter _router, IChainlinkOracle _chainlinkOracle) {
    require(address(_factory) != address(0), "Invalid address");
    require(address(_router) != address(0), "Invalid address");
    require(address(_chainlinkOracle) != address(0), "Invalid address");

    factory = _factory;
    router = _router;
    chainlinkOracle = _chainlinkOracle;
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * Get the address of the Joe LP token for tokenA and tokenB
    * @param _tokenA Token A address
    * @param _tokenB Token B address
    * @return address Address of the Joe LP token
  */
  function lpToken(
    address _tokenA,
    address _tokenB
  ) public view returns (address) {
    return factory.getPair(_tokenA, _tokenB);
  }

  /**
    * Get token B amounts out with token A amounts in via swap liquidity pool
    * @param _amountIn Amount of token A in, expressed in token A's decimals
    * @param _tokenA Token A address
    * @param _tokenB Token B address
    * @param _pair LP token address
    * @return amountOut Amount of token B to be received, expressed in token B's decimals
  */
  function getAmountsOut(
    uint256 _amountIn,
    address _tokenA,
    address _tokenB,
    ICamelotPair _pair
  ) public view returns (uint256) {
    if (_amountIn == 0) return 0;
    require(address(_pair) != address(0), "invalid pool");
    require(
      _tokenA == _pair.token0() || _tokenA == _pair.token1(),
      "invalid token in pool"
    );
    require(
      _tokenB == _pair.token0() || _tokenB == _pair.token1(),
      "invalid token in pool"
    );

    address[] memory path = new address[](2);
    path[0] = _tokenA;
    path[1] = _tokenB;

    return router.getAmountsOut(_amountIn, path)[1];
  }

    /**
    * Helper function to calculate amountIn for swapExactTokensForTokens
    * @param _amountOut   Amt of token to receive in token decimals
    * @param _reserveIn   Reserve of token IN
    * @param _reserveOut  Reserve of token OUT
    * @param _fee         Fee paid on token IN
  */
  function getAmountsIn(
    uint256 _amountOut,
    uint256 _reserveIn,
    uint256 _reserveOut,
    uint256 _fee
  ) public pure returns (uint256) {
    require(_amountOut > 0, "Cannot swap 0");
    require(_reserveIn > 0 && _reserveOut > 0, "Invalid reserves");
    uint256 numerator = _reserveIn * _amountOut * 1000;
    uint256 denominator = (_reserveOut - _amountOut) * (1000 - (_fee / 100));
    return (numerator / denominator) + 1;
  }

  /**
    * Get token A and token B's respective reserves in an amount of LP token
    * @param _amount Amount of LP token, expressed in 1e18
    * @param _tokenA Token A address
    * @param _tokenB Token B address
    * @param _pair LP token address
    * @return (reserveA, reserveB) Reserve amount of Token A and B respectively, in 1e18
  */
  function getLpTokenReserves(
    uint256 _amount,
    address _tokenA,
    address _tokenB,
    ICamelotPair _pair
  ) public view returns (uint256, uint256) {
    require(address(_pair) != address(0), "invalid pool");
    require(
      _tokenA == _pair.token0() || _tokenA == _pair.token1(),
      "invalid token in pool"
    );
    require(
      _tokenB == _pair.token0() || _tokenB == _pair.token1(),
      "invalid token in pool"
    );

    uint256 reserveA;
    uint256 reserveB;

    (uint256 reserve0, uint256 reserve1, , ) = _pair.getReserves();

    uint256 totalSupply = _pair.totalSupply();

    if (_tokenA == _pair.token0() && _tokenB == _pair.token1()) {
      reserveA = reserve0;
      reserveB = reserve1;
    } else {
      reserveA = reserve1;
      reserveB = reserve0;
    }

    reserveA = _amount * SAFE_MULTIPLIER / totalSupply * reserveA / SAFE_MULTIPLIER;
    reserveB = _amount * SAFE_MULTIPLIER / totalSupply * reserveB / SAFE_MULTIPLIER;

    return (reserveA, reserveB);
  }

  /**
    * Get token A and token B's respective fees for an LP token
    * @param _tokenA Token A address
    * @param _tokenB Token B address
    * @param _pair LP token address
    * @return (feeA, feeB) Reserve amount of Token A and B respectively, in 1e18
  */
  function getLpTokenFees(
    address _tokenA,
    address _tokenB,
    ICamelotPair _pair
  ) public view returns (uint16, uint16) {
    require(address(_pair) != address(0), "invalid pool");
    require(
      _tokenA == _pair.token0() || _tokenA == _pair.token1(),
      "invalid token in pool"
    );
    require(
      _tokenB == _pair.token0() || _tokenB == _pair.token1(),
      "invalid token in pool"
    );

    (, , uint16 fee0, uint16 fee1) = _pair.getReserves();

    if (_tokenA == _pair.token0() && _tokenB == _pair.token1()) {
      return (fee0, fee1);
    } else {
      return (fee1, fee0);
    }
  }

  /**
    * Get LP token fair value
    * @param _pair LP token address
    * @return lpTokenValue Value of respective tokens; expressed in 1e8
  */
  function getLpTokenValue(
    ICamelotPair _pair,
    bool addProtocolFees
  ) public view returns (uint256) {
    uint256 totalSupply;
    if(addProtocolFees) {
      totalSupply = _pair.totalSupply() + getPendingProtocolFees(address(_pair));
    } else {
      totalSupply = _pair.totalSupply();
    }

    address _tokenA = _pair.token0();
    address _tokenB = _pair.token1();

    (uint256 totalReserveA, uint256 totalReserveB) = getLpTokenReserves(
      totalSupply,
      _tokenA,
      _tokenB,
      _pair
    );

    uint256 sqrtK = Math.sqrt((totalReserveA * totalReserveB)) * 2**112 / totalSupply;

    // convert prices from Chainlink consult which is in 1e18 to 2**112
    uint256 priceA = chainlinkOracle.consultIn18Decimals(_tokenA)
                     * 10**8 / SAFE_MULTIPLIER
                     * 2**112 / 10**(18 - IERC20Metadata(_tokenA).decimals());
    uint256 priceB = chainlinkOracle.consultIn18Decimals(_tokenB)
                     * 10**8 / SAFE_MULTIPLIER
                     * 2**112 / 10**(18 - IERC20Metadata(_tokenB).decimals());

    uint256 lpFairValue = sqrtK * 2
                          * Math.sqrt(priceA) / 2**56
                          * Math.sqrt(priceB) / 2**56; // in 1e12

    uint256 lpFairValueIn8 = lpFairValue
                              * 10**(36 - (IERC20Metadata(_tokenA).decimals() + IERC20Metadata(_tokenB).decimals())) / 2**112;

    return lpFairValueIn8;
  }

  /**
    * Get token A and token B's LP token amount from value
    * Used in keeper script to calculate how much LP tokens for given USD value
    * @param _value Value of LP token, expressed in 1e18
    * @param _pair LP token address
    * @return lpTokenAmount Amount of LP tokens; expressed in 1e18
  */
  function getLpTokenAmount(
    uint256 _value,
    ICamelotPair _pair
  ) public view returns (uint256) {
    uint256 lpTokenValue = getLpTokenValue(
      _pair,
      false
    );

    uint256 lpTokenAmount = _value / lpTokenValue;

    return lpTokenAmount;
  }

  /**
    * Replicate _mintFee function from CamelotPair contract to calculate pending LP
    * tokens that will be minted as protocol fees
    * @param _pair LP token address
    * @return pendingFees Amount of pending fees in LP tokens
  */
  function getPendingProtocolFees(address _pair) public view returns (uint256) {
    ICamelotPair _lpToken = ICamelotPair(_pair);
    if (_lpToken.stableSwap()) return 0;

    (uint256 ownerFeeShare, address feeTo) = ICamelotFactory(_lpToken.factory()).feeInfo();

    bool feeOn = feeTo != address(0);
    uint256 _kLast = _lpToken.kLast();

    if (feeOn) {
      if (_kLast != 0 ) {
        (uint256 reserve0, uint256 reserve1,,) = _lpToken.getReserves();
        uint256 rootK = Math.sqrt(_k(_pair, reserve0, reserve1));
        uint256 rootKLast = Math.sqrt(_kLast);
        if (rootK > rootKLast) {
          uint256 d = (_lpToken.FEE_DENOMINATOR() * 100 / ownerFeeShare) - 100;
          uint256 numerator = _lpToken.totalSupply() * (rootK - rootKLast) * 100;
          uint256 denominator = rootK * d + (rootKLast * 100);
          uint256 liquidity = numerator / denominator;
          return liquidity;
        }
      }
    }
    return 0;
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
    * Replicate _k function from CamelotPair to calculate rootK
    * @param _pair LP token address
    * @param _balance0 token0 reserve amount
    * @param _balance1 token1 reserve amount
    * @return rootK value of rootK
  */
  function _k(address _pair, uint256 _balance0, uint256 _balance1) internal view returns (uint256) {
    if (ICamelotPair(_pair).stableSwap()) {
      uint256 _x = _balance0 * (1e18) / ICamelotPair(_pair).precisionMultiplier0();
      uint256 _y = _balance1 * (1e18) / ICamelotPair(_pair).precisionMultiplier1();
      uint256 _a = (_x * (_y)) / 1e18;
      uint256 _b = (_x * (_x) / 1e18) + (_y * (_y) / 1e18);
      return  _a * (_b) / 1e18; // x3y+y3x >= k
    }
    return _balance0 * (_balance1);
  }
}