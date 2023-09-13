// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Library for errors
/// @author Timeswap Labs
/// @dev Common error messages
library Error {
  /// @dev Reverts when input is zero.
  error ZeroInput();

  /// @dev Reverts when output is zero.
  error ZeroOutput();

  /// @dev Reverts when a value cannot be zero.
  error CannotBeZero();

  /// @dev Reverts when a pool already have liquidity.
  /// @param liquidity The liquidity amount that already existed in the pool.
  error AlreadyHaveLiquidity(uint160 liquidity);

  /// @dev Reverts when a pool requires liquidity.
  error RequireLiquidity();

  /// @dev Reverts when a given address is the zero address.
  error ZeroAddress();

  /// @dev Reverts when the maturity given is not withing uint96.
  /// @param maturity The maturity being inquired.
  error IncorrectMaturity(uint256 maturity);

  /// @dev Reverts when an option of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error InactiveOption(uint256 strike, uint256 maturity);

  /// @dev Reverts when a pool of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error InactivePool(uint256 strike, uint256 maturity);

  /// @dev Reverts when a liquidity token is inactive.
  error InactiveLiquidityTokenChoice();

  /// @dev Reverts when the square root interest rate is zero.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error ZeroSqrtInterestRate(uint256 strike, uint256 maturity);

  /// @dev Reverts when the maturity is already matured.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  error AlreadyMatured(uint256 maturity, uint96 blockTimestamp);

  /// @dev Reverts when the maturity is still active.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  error StillActive(uint256 maturity, uint96 blockTimestamp);

  /// @dev Token amount not received.
  /// @param minuend The amount being subtracted.
  /// @param subtrahend The amount subtracting.
  error NotEnoughReceived(uint256 minuend, uint256 subtrahend);

  /// @dev The deadline of a transaction has been reached.
  /// @param deadline The deadline set.
  error DeadlineReached(uint256 deadline);

  /// @dev Reverts when input is zero.
  function zeroInput() internal pure {
    revert ZeroInput();
  }

  /// @dev Reverts when output is zero.
  function zeroOutput() internal pure {
    revert ZeroOutput();
  }

  /// @dev Reverts when a value cannot be zero.
  function cannotBeZero() internal pure {
    revert CannotBeZero();
  }

  /// @dev Reverts when a pool already have liquidity.
  /// @param liquidity The liquidity amount that already existed in the pool.
  function alreadyHaveLiquidity(uint160 liquidity) internal pure {
    revert AlreadyHaveLiquidity(liquidity);
  }

  /// @dev Reverts when a pool requires liquidity.
  function requireLiquidity() internal pure {
    revert RequireLiquidity();
  }

  /// @dev Reverts when a given address is the zero address.
  function zeroAddress() internal pure {
    revert ZeroAddress();
  }

  /// @dev Reverts when the maturity given is not withing uint96.
  /// @param maturity The maturity being inquired.
  function incorrectMaturity(uint256 maturity) internal pure {
    revert IncorrectMaturity(maturity);
  }

  /// @dev Reverts when the maturity is already matured.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  function alreadyMatured(uint256 maturity, uint96 blockTimestamp) internal pure {
    revert AlreadyMatured(maturity, blockTimestamp);
  }

  /// @dev Reverts when the maturity is still active.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  function stillActive(uint256 maturity, uint96 blockTimestamp) internal pure {
    revert StillActive(maturity, blockTimestamp);
  }

  /// @dev The deadline of a transaction has been reached.
  /// @param deadline The deadline set.
  function deadlineReached(uint256 deadline) internal pure {
    revert DeadlineReached(deadline);
  }

  /// @dev Reverts when an option of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  function inactiveOptionChoice(uint256 strike, uint256 maturity) internal pure {
    revert InactiveOption(strike, maturity);
  }

  /// @dev Reverts when a pool of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  function inactivePoolChoice(uint256 strike, uint256 maturity) internal pure {
    revert InactivePool(strike, maturity);
  }

  /// @dev Reverts when the square root interest rate is zero.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  function zeroSqrtInterestRate(uint256 strike, uint256 maturity) internal pure {
    revert ZeroSqrtInterestRate(strike, maturity);
  }

  /// @dev Reverts when a liquidity token is inactive.
  function inactiveLiquidityTokenChoice() internal pure {
    revert InactiveLiquidityTokenChoice();
  }

  /// @dev Reverts when token amount not received.
  /// @param balance The balance amount being subtracted.
  /// @param balanceTarget The amount target.
  function checkEnough(uint256 balance, uint256 balanceTarget) internal pure {
    if (balance < balanceTarget) revert NotEnoughReceived(balance, balanceTarget);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Math} from "./Math.sol";

/// @title Library for math utils for uint512
/// @author Timeswap Labs
library FullMath {
  using Math for uint256;

  /// @dev Reverts when modulo by zero.
  error ModuloByZero();

  /// @dev Reverts when add512 overflows over uint512.
  /// @param addendA0 The least significant part of first addend.
  /// @param addendA1 The most significant part of first addend.
  /// @param addendB0 The least significant part of second addend.
  /// @param addendB1 The most significant part of second addend.
  error AddOverflow(uint256 addendA0, uint256 addendA1, uint256 addendB0, uint256 addendB1);

  /// @dev Reverts when sub512 underflows.
  /// @param minuend0 The least significant part of minuend.
  /// @param minuend1 The most significant part of minuend.
  /// @param subtrahend0 The least significant part of subtrahend.
  /// @param subtrahend1 The most significant part of subtrahend.
  error SubUnderflow(uint256 minuend0, uint256 minuend1, uint256 subtrahend0, uint256 subtrahend1);

  /// @dev Reverts when div512To256 overflows over uint256.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  error DivOverflow(uint256 dividend0, uint256 dividend1, uint256 divisor);

  /// @dev Reverts when mulDiv overflows over uint256.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @param divisor The divisor.
  error MulDivOverflow(uint256 multiplicand, uint256 multiplier, uint256 divisor);

  /// @dev Calculates the sum of two uint512 numbers.
  /// @notice Reverts on overflow over uint512.
  /// @param addendA0 The least significant part of addendA.
  /// @param addendA1 The most significant part of addendA.
  /// @param addendB0 The least significant part of addendB.
  /// @param addendB1 The most significant part of addendB.
  /// @return sum0 The least significant part of sum.
  /// @return sum1 The most significant part of sum.
  function add512(
    uint256 addendA0,
    uint256 addendA1,
    uint256 addendB0,
    uint256 addendB1
  ) internal pure returns (uint256 sum0, uint256 sum1) {
    uint256 carry;
    assembly {
      sum0 := add(addendA0, addendB0)
      carry := lt(sum0, addendA0)
      sum1 := add(add(addendA1, addendB1), carry)
    }

    if (carry == 0 ? addendA1 > sum1 : (sum1 == 0 || addendA1 > sum1 - 1))
      revert AddOverflow(addendA0, addendA1, addendB0, addendB1);
  }

  /// @dev Calculates the difference of two uint512 numbers.
  /// @notice Reverts on underflow.
  /// @param minuend0 The least significant part of minuend.
  /// @param minuend1 The most significant part of minuend.
  /// @param subtrahend0 The least significant part of subtrahend.
  /// @param subtrahend1 The most significant part of subtrahend.
  /// @return difference0 The least significant part of difference.
  /// @return difference1 The most significant part of difference.
  function sub512(
    uint256 minuend0,
    uint256 minuend1,
    uint256 subtrahend0,
    uint256 subtrahend1
  ) internal pure returns (uint256 difference0, uint256 difference1) {
    assembly {
      difference0 := sub(minuend0, subtrahend0)
      difference1 := sub(sub(minuend1, subtrahend1), lt(minuend0, subtrahend0))
    }

    if (subtrahend1 > minuend1 || (subtrahend1 == minuend1 && subtrahend0 > minuend0))
      revert SubUnderflow(minuend0, minuend1, subtrahend0, subtrahend1);
  }

  /// @dev Calculate the product of two uint256 numbers that may result to uint512 product.
  /// @notice Can never overflow.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @return product0 The least significant part of product.
  /// @return product1 The most significant part of product.
  function mul512(uint256 multiplicand, uint256 multiplier) internal pure returns (uint256 product0, uint256 product1) {
    assembly {
      let mm := mulmod(multiplicand, multiplier, not(0))
      product0 := mul(multiplicand, multiplier)
      product1 := sub(sub(mm, product0), lt(mm, product0))
    }
  }

  /// @dev Divide 2 to 256 power by the divisor.
  /// @dev Rounds down the result.
  /// @notice Reverts when divide by zero.
  /// @param divisor The divisor.
  /// @return quotient The quotient.
  function div256(uint256 divisor) private pure returns (uint256 quotient) {
    if (divisor == 0) revert Math.DivideByZero();
    assembly {
      quotient := add(div(sub(0, divisor), divisor), 1)
    }
  }

  /// @dev Compute 2 to 256 power modulo the given value.
  /// @notice Reverts when modulo by zero.
  /// @param value The given value.
  /// @return result The result.
  function mod256(uint256 value) private pure returns (uint256 result) {
    if (value == 0) revert ModuloByZero();
    assembly {
      result := mod(sub(0, value), value)
    }
  }

  /// @dev Divide a uint512 number by uint256 number to return a uint512 number.
  /// @dev Rounds down the result.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param quotient0 The least significant part of quotient.
  /// @param quotient1 The most significant part of quotient.
  function div512(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor
  ) private pure returns (uint256 quotient0, uint256 quotient1) {
    if (dividend1 == 0) quotient0 = dividend0.div(divisor, false);
    else {
      uint256 q = div256(divisor);
      uint256 r = mod256(divisor);
      while (dividend1 != 0) {
        (uint256 t0, uint256 t1) = mul512(dividend1, q);
        (quotient0, quotient1) = add512(quotient0, quotient1, t0, t1);
        (t0, t1) = mul512(dividend1, r);
        (dividend0, dividend1) = add512(t0, t1, dividend0, 0);
      }
      (quotient0, quotient1) = add512(quotient0, quotient1, dividend0.div(divisor, false), 0);
    }
  }

  /// @dev Divide a uint512 number by a uint256 number.
  /// @dev Reverts when result is greater than uint256.
  /// @notice Skips div512 if dividend1 is zero.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @param quotient The quotient.
  function div512To256(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 quotient) {
    uint256 quotient1;
    (quotient, quotient1) = div512(dividend0, dividend1, divisor);

    if (quotient1 != 0) revert DivOverflow(dividend0, dividend1, divisor);

    if (roundUp) {
      (uint256 productA0, uint256 productA1) = mul512(quotient, divisor);
      if (dividend1 > productA1 || dividend0 > productA0) quotient++;
    }
  }

  /// @dev Divide a uint512 number by a uint256 number.
  /// @notice Skips div512 if dividend1 is zero.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @param quotient0 The least significant part of quotient.
  /// @param quotient1 The most significant part of quotient.
  function div512(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 quotient0, uint256 quotient1) {
    (quotient0, quotient1) = div512(dividend0, dividend1, divisor);

    if (roundUp) {
      (uint256 productA0, uint256 productA1) = mul512(quotient0, divisor);
      productA1 += (quotient1 * divisor);
      if (dividend1 > productA1 || dividend0 > productA0) {
        if (quotient0 == type(uint256).max) {
          quotient0 = 0;
          quotient1++;
        } else quotient0++;
      }
    }
  }

  /// @dev Multiply two uint256 number then divide it by a uint256 number.
  /// @notice Skips mulDiv if product of multiplicand and multiplier is uint256 number.
  /// @dev Reverts when result is greater than uint256.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The result.
  function mulDiv(
    uint256 multiplicand,
    uint256 multiplier,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 result) {
    (uint256 product0, uint256 product1) = mul512(multiplicand, multiplier);

    // Handle non-overflow cases, 256 by 256 division
    if (product1 == 0) return result = product0.div(divisor, roundUp);

    // Make sure the result is less than 2**256.
    // Also prevents divisor == 0
    if (divisor <= product1) revert MulDivOverflow(multiplicand, multiplier, divisor);

    unchecked {
      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [product1 product0]
      // Compute remainder using mulmod
      uint256 remainder;
      assembly {
        remainder := mulmod(multiplicand, multiplier, divisor)
      }
      // Subtract 256 bit number from 512 bit number
      assembly {
        product1 := sub(product1, gt(remainder, product0))
        product0 := sub(product0, remainder)
      }

      // Factor powers of two out of divisor
      // Compute largest power of two divisor of divisor.
      // Always >= 1.
      uint256 twos;
      twos = (0 - divisor) & divisor;
      // Divide denominator by power of two
      assembly {
        divisor := div(divisor, twos)
      }

      // Divide [product1 product0] by the factors of two
      assembly {
        product0 := div(product0, twos)
      }
      // Shift in bits from product1 into product0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      product0 |= product1 * twos;

      // Invert divisor mod 2**256
      // Now that divisor is an odd number, it has an inverse
      // modulo 2**256 such that divisor * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, divisor * inv = 1 mod 2**4
      uint256 inv;
      inv = (3 * divisor) ^ 2;

      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - divisor * inv; // inverse mod 2**8
      inv *= 2 - divisor * inv; // inverse mod 2**16
      inv *= 2 - divisor * inv; // inverse mod 2**32
      inv *= 2 - divisor * inv; // inverse mod 2**64
      inv *= 2 - divisor * inv; // inverse mod 2**128
      inv *= 2 - divisor * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of divisor. This will give us the
      // correct result modulo 2**256. Since the preconditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and product1
      // is no longer required.
      result = product0 * inv;
    }

    if (roundUp && mulmod(multiplicand, multiplier, divisor) != 0) result++;
  }

  /// @dev Get the square root of a uint512 number.
  /// @param value0 The least significant of the number.
  /// @param value1 The most significant of the number.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The result.
  function sqrt512(uint256 value0, uint256 value1, bool roundUp) internal pure returns (uint256 result) {
    if (value1 == 0) result = value0.sqrt(roundUp);
    else {
      uint256 estimate = sqrt512Estimate(value0, value1, type(uint256).max);
      result = type(uint256).max;
      while (estimate < result) {
        result = estimate;
        estimate = sqrt512Estimate(value0, value1, estimate);
      }

      if (roundUp) {
        (uint256 product0, uint256 product1) = mul512(result, result);
        if (value1 > product1 || value0 > product0) result++;
      }
    }
  }

  /// @dev An iterative process of getting sqrt512 following Newtonian method.
  /// @param value0 The least significant of the number.
  /// @param value1 The most significant of the number.
  /// @param currentEstimate The current estimate of the iteration.
  /// @param estimate The new estimate of the iteration.
  function sqrt512Estimate(
    uint256 value0,
    uint256 value1,
    uint256 currentEstimate
  ) private pure returns (uint256 estimate) {
    uint256 r0 = div512To256(value0, value1, currentEstimate, false);
    uint256 r1;
    (r0, r1) = add512(r0, 0, currentEstimate, 0);
    estimate = div512To256(r0, r1, 2, false);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Library for math related utils
/// @author Timeswap Labs
library Math {
  /// @dev Reverts when divide by zero.
  error DivideByZero();
  error Overflow();

  /// @dev Add two uint256.
  /// @notice May overflow.
  /// @param addend1 The first addend.
  /// @param addend2 The second addend.
  /// @return sum The sum.
  function unsafeAdd(uint256 addend1, uint256 addend2) internal pure returns (uint256 sum) {
    unchecked {
      sum = addend1 + addend2;
    }
  }

  /// @dev Subtract two uint256.
  /// @notice May underflow.
  /// @param minuend The minuend.
  /// @param subtrahend The subtrahend.
  /// @return difference The difference.
  function unsafeSub(uint256 minuend, uint256 subtrahend) internal pure returns (uint256 difference) {
    unchecked {
      difference = minuend - subtrahend;
    }
  }

  /// @dev Multiply two uint256.
  /// @notice May overflow.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @return product The product.
  function unsafeMul(uint256 multiplicand, uint256 multiplier) internal pure returns (uint256 product) {
    unchecked {
      product = multiplicand * multiplier;
    }
  }

  /// @dev Divide two uint256.
  /// @notice Reverts when divide by zero.
  /// @param dividend The dividend.
  /// @param divisor The divisor.
  //// @param roundUp Round up the result when true. Round down if false.
  /// @return quotient The quotient.
  function div(uint256 dividend, uint256 divisor, bool roundUp) internal pure returns (uint256 quotient) {
    quotient = dividend / divisor;

    if (roundUp && dividend % divisor != 0) quotient++;
  }

  /// @dev Shift right a uint256 number.
  /// @param dividend The dividend.
  /// @param divisorBit The divisor in bits.
  /// @param roundUp True if ceiling the result. False if floor the result.
  /// @return quotient The quotient.
  function shr(uint256 dividend, uint8 divisorBit, bool roundUp) internal pure returns (uint256 quotient) {
    quotient = dividend >> divisorBit;

    if (roundUp && dividend % (1 << divisorBit) != 0) quotient++;
  }

  /// @dev Gets the square root of a value.
  /// @param value The value being square rooted.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The resulting value of the square root.
  function sqrt(uint256 value, bool roundUp) internal pure returns (uint256 result) {
    if (value == type(uint256).max) return result = type(uint128).max;
    if (value == 0) return 0;
    unchecked {
      uint256 estimate = (value + 1) >> 1;
      result = value;
      while (estimate < result) {
        result = estimate;
        estimate = (value / estimate + estimate) >> 1;
      }
    }

    if (roundUp && result * result < value) result++;
  }

  /// @dev Gets the min of two uint256 number.
  /// @param value1 The first value to be compared.
  /// @param value2 The second value to be compared.
  /// @return result The min result.
  function min(uint256 value1, uint256 value2) internal pure returns (uint256 result) {
    return value1 < value2 ? value1 : value2;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Libary for ownership
/// @author Timeswap Labs
library Ownership {
  /// @dev Reverts when the caller is not the owner.
  /// @param caller The caller of the function that is not the owner.
  /// @param owner The actual owner.
  error NotTheOwner(address caller, address owner);

  /// @dev reverts when the caller is already the owner.
  /// @param owner The owner.
  error AlreadyTheOwner(address owner);

  /// @dev revert when the caller is not the pending owner.
  /// @param caller The caller of the function that is not the pending owner.
  /// @param pendingOwner The actual pending owner.
  error NotThePendingOwner(address caller, address pendingOwner);

  /// @dev checks if the caller is the owner.
  /// @notice Reverts when the msg.sender is not the owner.
  /// @param owner The owner address.
  function checkIfOwner(address owner) internal view {
    if (msg.sender != owner) revert NotTheOwner(msg.sender, owner);
  }

  /// @dev checks if the caller is already the owner.
  /// @notice Reverts when the chosen pending owner is already the owner.
  /// @param chosenPendingOwner The chosen pending owner.
  /// @param owner The current actual owner.
  function checkIfAlreadyOwner(address chosenPendingOwner, address owner) internal pure {
    if (chosenPendingOwner == owner) revert AlreadyTheOwner(owner);
  }

  /// @dev checks if the caller is the pending owner.
  /// @notice Reverts when the caller is not the pending owner.
  /// @param caller The address of the caller.
  /// @param pendingOwner The current pending owner.
  function checkIfPendingOwner(address caller, address pendingOwner) internal pure {
    if (caller != pendingOwner) revert NotThePendingOwner(caller, pendingOwner);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Library for safecasting
/// @author Timeswap Labs
library SafeCast {
  /// @dev Reverts when overflows over uint16.
  error Uint16Overflow();

  /// @dev Reverts when overflows over uint96.
  error Uint96Overflow();

  /// @dev Reverts when overflows over uint160.
  error Uint160Overflow();

  /// @dev Safely cast a uint256 number to uint16.
  /// @dev Reverts when number is greater than uint16.
  /// @param value The uint256 number to be safecasted.
  /// @param result The uint16 result.
  function toUint16(uint256 value) internal pure returns (uint16 result) {
    if (value > type(uint16).max) revert Uint16Overflow();
    result = uint16(value);
  }

  /// @dev Safely cast a uint256 number to uint96.
  /// @dev Reverts when number is greater than uint96.
  /// @param value The uint256 number to be safecasted.
  /// @param result The uint96 result.
  function toUint96(uint256 value) internal pure returns (uint96 result) {
    if (value > type(uint96).max) revert Uint96Overflow();
    result = uint96(value);
  }

  /// @dev Safely cast a uint256 number to uint160.
  /// @dev Reverts when number is greater than uint160.
  /// @param value The uint256 number to be safecasted.
  /// @param result The uint160 result.
  function toUint160(uint256 value) internal pure returns (uint160 result) {
    if (value > type(uint160).max) revert Uint160Overflow();
    result = uint160(value);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {FullMath} from "./FullMath.sol";

/// @title library for converting strike prices.
/// @dev When strike is greater than uint128, the base token is denominated as token0 (which is the smaller address token).
/// @dev When strike is uint128, the base token is denominated as token1 (which is the larger address).
library StrikeConversion {
  /// @dev When zeroToOne, converts a number in multiple of strike.
  /// @dev When oneToZero, converts a number in multiple of 1 / strike.
  /// @param amount The amount to be converted.
  /// @param strike The strike multiple conversion.
  /// @param zeroToOne ZeroToOne if it is true. OneToZero if it is false.
  /// @param roundUp Round up the result when true. Round down if false.
  function convert(uint256 amount, uint256 strike, bool zeroToOne, bool roundUp) internal pure returns (uint256) {
    return
      zeroToOne
        ? FullMath.mulDiv(amount, strike, uint256(1) << 128, roundUp)
        : FullMath.mulDiv(amount, uint256(1) << 128, strike, roundUp);
  }

  /// @dev When toOne, converts a base denomination to token1 denomination.
  /// @dev When toZero, converts a base denomination to token0 denomination.
  /// @param amount The amount ot be converted. Token0 amount when zeroToOne. Token1 amount when oneToZero.
  /// @param strike The strike multiple conversion.
  /// @param toOne ToOne if it is true, ToZero if it is false.
  /// @param roundUp Round up the result when true. Round down if false.
  function turn(uint256 amount, uint256 strike, bool toOne, bool roundUp) internal pure returns (uint256) {
    return
      strike > type(uint128).max
        ? (toOne ? convert(amount, strike, true, roundUp) : amount)
        : (toOne ? amount : convert(amount, strike, false, roundUp));
  }

  /// @dev Combine and add token0Amount and token1Amount into base token amount.
  /// @param amount0 The token0 amount to be combined.
  /// @param amount1 The token1 amount to be combined.
  /// @param strike The strike multiple conversion.
  /// @param roundUp Round up the result when true. Round down if false.
  function combine(uint256 amount0, uint256 amount1, uint256 strike, bool roundUp) internal pure returns (uint256) {
    return
      strike > type(uint128).max
        ? amount0 + convert(amount1, strike, false, roundUp)
        : amount1 + convert(amount0, strike, true, roundUp);
  }

  /// @dev When zeroToOne, given a larger base amount, and token0 amount, get the difference token1 amount.
  /// @dev When oneToZero, given a larger base amount, and toekn1 amount, get the difference token0 amount.
  /// @param base The larger base amount.
  /// @param amount The token0 amount when zeroToOne, the token1 amount when oneToZero.
  /// @param strike The strike multiple conversion.
  /// @param zeroToOne ZeroToOne if it is true. OneToZero if it is false.
  /// @param roundUp Round up the result when true. Round down if false.
  function dif(
    uint256 base,
    uint256 amount,
    uint256 strike,
    bool zeroToOne,
    bool roundUp
  ) internal pure returns (uint256) {
    return
      strike > type(uint128).max
        ? (zeroToOne ? convert(base - amount, strike, true, roundUp) : base - convert(amount, strike, false, !roundUp))
        : (zeroToOne ? base - convert(amount, strike, true, !roundUp) : convert(base - amount, strike, false, roundUp));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The three type of native token positions.
/// @dev Long0 is denominated as the underlying Token0.
/// @dev Long1 is denominated as the underlying Token1.
/// @dev When strike greater than uint128 then Short is denominated as Token0 (the base token denomination).
/// @dev When strike is uint128 then Short is denominated as Token1 (the base token denomination).
enum TimeswapV2OptionPosition {
  Long0,
  Long1,
  Short
}

/// @title library for position utils
/// @author Timeswap Labs
/// @dev Helper functions for the TimeswapOptionPosition enum.
library PositionLibrary {
  /// @dev Reverts when the given type of position is invalid.
  error InvalidPosition();

  /// @dev Checks that the position input is correct.
  /// @param position The position input.
  function check(TimeswapV2OptionPosition position) internal pure {
    if (uint256(position) >= 3) revert InvalidPosition();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The different input for the mint transaction.
enum TimeswapV2OptionMint {
  GivenTokensAndLongs,
  GivenShorts
}

/// @dev The different input for the burn transaction.
enum TimeswapV2OptionBurn {
  GivenTokensAndLongs,
  GivenShorts
}

/// @dev The different input for the swap transaction.
enum TimeswapV2OptionSwap {
  GivenToken0AndLong0,
  GivenToken1AndLong1
}

/// @dev The different input for the collect transaction.
enum TimeswapV2OptionCollect {
  GivenShort,
  GivenToken0,
  GivenToken1
}

/// @title library for transaction checks
/// @author Timeswap Labs
/// @dev Helper functions for the all enums in this module.
library TransactionLibrary {
  /// @dev Reverts when the given type of transaction is invalid.
  error InvalidTransaction();

  /// @dev checks that the given input is correct.
  /// @param transaction the mint transaction input.
  function check(TimeswapV2OptionMint transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the burn transaction input.
  function check(TimeswapV2OptionBurn transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the swap transaction input.
  function check(TimeswapV2OptionSwap transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the collect transaction input.
  function check(TimeswapV2OptionCollect transaction) internal pure {
    if (uint256(transaction) >= 3) revert InvalidTransaction();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionPosition} from "../enums/Position.sol";
import {TimeswapV2OptionMintParam, TimeswapV2OptionBurnParam, TimeswapV2OptionSwapParam, TimeswapV2OptionCollectParam} from "../structs/Param.sol";
import {StrikeAndMaturity} from "../structs/StrikeAndMaturity.sol";

/// @title An interface for a contract that deploys Timeswap V2 Option pair contracts
/// @notice A Timeswap V2 Option pair facilitates option mechanics between any two assets that strictly conform
/// to the ERC20 specification.
interface ITimeswapV2Option {
  /* ===== EVENT ===== */

  /// @dev Emits when a position is transferred.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param from The address of the caller of the transferPosition function.
  /// @param to The address of the recipient of the position.
  /// @param position The type of position transferred. More information in the Position module.
  /// @param amount The amount of balance transferred.
  event TransferPosition(
    uint256 indexed strike,
    uint256 indexed maturity,
    address from,
    address to,
    TimeswapV2OptionPosition position,
    uint256 amount
  );

  /// @dev Emits when a mint transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param long0To The address of the recipient of long token0 position.
  /// @param long1To The address of the recipient of long token1 position.
  /// @param shortTo The address of the recipient of short position.
  /// @param token0AndLong0Amount The amount of token0 deposited and long0 minted.
  /// @param token1AndLong1Amount The amount of token1 deposited and long1 minted.
  /// @param shortAmount The amount of short minted.
  event Mint(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when a burn transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param token0To The address of the recipient of token0.
  /// @param token1To The address of the recipient of token1.
  /// @param token0AndLong0Amount The amount of token0 withdrawn and long0 burnt.
  /// @param token1AndLong1Amount The amount of token1 withdrawn and long1 burnt.
  /// @param shortAmount The amount of short burnt.
  event Burn(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address token0To,
    address token1To,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when a swap transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param tokenTo The address of the recipient of token0 or token1.
  /// @param longTo The address of the recipient of long token0 or long token1.
  /// @param isLong0toLong1 The direction of the swap. More information in the Transaction module.
  /// @param token0AndLong0Amount If the direction is from long0 to long1, the amount of token0 withdrawn and long0 burnt.
  /// If the direction is from long1 to long0, the amount of token0 deposited and long0 minted.
  /// @param token1AndLong1Amount If the direction is from long0 to long1, the amount of token1 deposited and long1 minted.
  /// If the direction is from long1 to long0, the amount of token1 withdrawn and long1 burnt.
  event Swap(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address tokenTo,
    address longTo,
    bool isLong0toLong1,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount
  );

  /// @dev Emits when a collect transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param token0To The address of the recipient of token0.
  /// @param token1To The address of the recipient of token1.
  /// @param long0AndToken0Amount The amount of token0 withdrawn.
  /// @param long1AndToken1Amount The amount of token1 withdrawn.
  /// @param shortAmount The amount of short burnt.
  event Collect(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address token0To,
    address token1To,
    uint256 long0AndToken0Amount,
    uint256 long1AndToken1Amount,
    uint256 shortAmount
  );

  /* ===== VIEW ===== */

  /// @dev Returns the factory address that deployed this contract.
  function optionFactory() external view returns (address);

  /// @dev Returns the first ERC20 token address of the pair.
  function token0() external view returns (address);

  /// @dev Returns the second ERC20 token address of the pair.
  function token1() external view returns (address);

  /// @dev Get the strike and maturity of the option in the option enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (StrikeAndMaturity memory);

  /// @dev Number of options being interacted.
  function numberOfOptions() external view returns (uint256);

  /// @dev Returns the total position of the option.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param position The type of position inquired. More information in the Position module.
  /// @return balance The total position.
  function totalPosition(
    uint256 strike,
    uint256 maturity,
    TimeswapV2OptionPosition position
  ) external view returns (uint256 balance);

  /// @dev Returns the position of an owner of the option.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param owner The address of the owner of the position.
  /// @param position The type of position inquired. More information in the Position module.
  /// @return balance The user position.
  function positionOf(
    uint256 strike,
    uint256 maturity,
    address owner,
    TimeswapV2OptionPosition position
  ) external view returns (uint256 balance);

  /* ===== UPDATE ===== */

  /// @dev Transfer position to another address.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param to The address of the recipient of the position.
  /// @param position The type of position transferred. More information in the Position module.
  /// @param amount The amount of balance transferred.
  function transferPosition(
    uint256 strike,
    uint256 maturity,
    address to,
    TimeswapV2OptionPosition position,
    uint256 amount
  ) external;

  /// @dev Mint position.
  /// Mint long token0 position when token0 is deposited.
  /// Mint long token1 position when token1 is deposited.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the mint function.
  /// @return token0AndLong0Amount The amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount The amount of token1 deposited and long1 minted.
  /// @return shortAmount The amount of short minted.
  /// @return data The additional data return.
  function mint(
    TimeswapV2OptionMintParam calldata param
  )
    external
    returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data);

  /// @dev Burn short position.
  /// Withdraw token0, when long token0 is burnt.
  /// Withdraw token1, when long token1 is burnt.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the burn function.
  /// @return token0AndLong0Amount The amount of token0 withdrawn and long0 burnt.
  /// @return token1AndLong1Amount The amount of token1 withdrawn and long1 burnt.
  /// @return shortAmount The amount of short burnt.
  function burn(
    TimeswapV2OptionBurnParam calldata param
  )
    external
    returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data);

  /// @dev If the direction is from long token0 to long token1, burn long token0 and mint equivalent long token1,
  /// also deposit token1 and withdraw token0.
  /// If the direction is from long token1 to long token0, burn long token1 and mint equivalent long token0,
  /// also deposit token0 and withdraw token1.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the swap function.
  /// @return token0AndLong0Amount If direction is Long0ToLong1, the amount of token0 withdrawn and long0 burnt.
  /// If direction is Long1ToLong0, the amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount If direction is Long0ToLong1, the amount of token1 deposited and long1 minted.
  /// If direction is Long1ToLong0, the amount of token1 withdrawn and long1 burnt.
  /// @return data The additional data return.
  function swap(
    TimeswapV2OptionSwapParam calldata param
  ) external returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, bytes memory data);

  /// @dev Burn short position, withdraw token0 and token1.
  /// @dev Can only be called after the maturity of the pool.
  /// @param param The parameters for the collect function.
  /// @return token0Amount The amount of token0 withdrawn.
  /// @return token1Amount The amount of token1 withdrawn.
  /// @return shortAmount The amount of short burnt.
  function collect(
    TimeswapV2OptionCollectParam calldata param
  ) external returns (uint256 token0Amount, uint256 token1Amount, uint256 shortAmount, bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title The interface for the contract that deploys Timeswap V2 Option pair contracts
/// @notice The Timeswap V2 Option Factory facilitates creation of Timeswap V2 Options pair.
interface ITimeswapV2OptionFactory {
  /* ===== EVENT ===== */

  /// @dev Emits when a new Timeswap V2 Option contract is created.
  /// @param caller The address of the caller of create function.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the Timeswap V2 Option contract created.
  event Create(address indexed caller, address indexed token0, address indexed token1, address optionPair);

  /* ===== VIEW ===== */

  /// @dev Returns the address of a Timeswap V2 Option.
  /// @dev Returns a zero address if the Timeswap V2 Option does not exist.
  /// @notice The token0 address must be smaller than token1 address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @return optionPair The address of the Timeswap V2 Option contract or a zero address.
  function get(address token0, address token1) external view returns (address optionPair);

  /// @dev Get the address of the option pair in the option pair enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (address optionPair);

  /// @dev The number of option pairs deployed.
  function numberOfPairs() external view returns (uint256);

  /* ===== UPDATE ===== */

  /// @dev Creates a Timeswap V2 Option based on pair parameters.
  /// @dev Cannot create a duplicate Timeswap V2 Option with the same pair parameters.
  /// @notice The token0 address must be smaller than token1 address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the Timeswap V2 Option contract created.
  function create(address token0, address token1) external returns (address optionPair);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title library for optionPair utils
/// @author Timeswap Labs
library OptionPairLibrary {
  /// @dev Reverts when option address is zero.
  error ZeroOptionAddress();

  /// @dev Reverts when the pair has incorrect format.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  error InvalidOptionPair(address token0, address token1);

  /// @dev Reverts when the Timeswap V2 Option already exist.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the existed Pair contract.
  error OptionPairAlreadyExisted(address token0, address token1, address optionPair);

  /// @dev Checks if option address is not zero.
  /// @param optionPair The option pair address being inquired.
  function checkNotZeroAddress(address optionPair) internal pure {
    if (optionPair == address(0)) revert ZeroOptionAddress();
  }

  /// @dev Check if the pair tokens is in correct format.
  /// @notice Reverts if token0 is greater than or equal token1.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  function checkCorrectFormat(address token0, address token1) internal pure {
    if (token0 >= token1) revert InvalidOptionPair(token0, token1);
  }

  /// @dev Check if the pair already existed.
  /// @notice Reverts if the pair is not a zero address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the existed Pair contract.
  function checkDoesNotExist(address token0, address token1, address optionPair) internal pure {
    if (optionPair != address(0)) revert OptionPairAlreadyExisted(token0, token1, optionPair);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {TimeswapV2OptionMint, TimeswapV2OptionBurn, TimeswapV2OptionSwap, TimeswapV2OptionCollect, TransactionLibrary} from "../enums/Transaction.sol";

/// @dev The parameter to call the mint function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param shortTo The recipient of short positions.
/// @param transaction The type of mint transaction, more information in Transaction module.
/// @param amount0 If transaction is givenTokensAndLongs, the amount of token0 deposited, and amount of long0 position minted.
/// If transaction is givenShorts, the amount of short minted, where the equivalent strike converted amount is long0 positions.
/// @param amount1 If transaction is givenTokensAndLongs, the amount of token1 deposited, and amount of long1 position minted.
/// If transaction is givenShorts, the amount of short minted, where the equivalent strike converted amount is long1 positions.
/// @param data The data to be sent to the function, which will go to the mint callback.
struct TimeswapV2OptionMintParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  TimeswapV2OptionMint transaction;
  uint256 amount0;
  uint256 amount1;
  bytes data;
}

/// @dev The parameter to call the burn function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param token0To The recipient of token0 withdrawn.
/// @param token1To The recipient of token1 withdrawn.
/// @param transaction The type of burn transaction, more information in Transaction module.
/// @param amount0 If transaction is givenTokensAndLongs, the amount of token0 withdrawn, and amount of long0 position burnt.
/// If transaction is givenShorts, the amount of short burnt, where the equivalent strike converted amount is long0 positions.
/// @param amount1 If transaction is givenTokensAndLongs, the amount of token1 withdrawn, and amount of long1 position burnt.
/// If transaction is givenShorts, the amount of short burnt, where the equivalent strike converted amount is long1 positions.
/// @param data The data to be sent to the function, which will go to the burn callback.
/// @notice If data length is zero, skips the callback.
struct TimeswapV2OptionBurnParam {
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  TimeswapV2OptionBurn transaction;
  uint256 amount0;
  uint256 amount1;
  bytes data;
}

/// @dev The parameter to call the swap function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param tokenTo The recipient of token0 when isLong0ToLong1 or token1 when isLong1ToLong0.
/// @param longTo The recipient of long1 positions when isLong0ToLong1 or long0 when isLong1ToLong0.
/// @param isLong0ToLong1 Transform long0 positions to long1 positions when true. Transform long1 positions to long0 positions when false.
/// @param transaction The type of swap transaction, more information in Transaction module.
/// @param amount If isLong0ToLong1 and transaction is GivenToken0AndLong0, this is the amount of token0 withdrawn, and the amount of long0 position burnt.
/// If isLong1ToLong0 and transaction is GivenToken0AndLong0, this is the amount of token0 to be deposited, and the amount of long0 position minted.
/// If isLong0ToLong1 and transaction is GivenToken1AndLong1, this is the amount of token1 to be deposited, and the amount of long1 position minted.
/// If isLong1ToLong0 and transaction is GivenToken1AndLong1, this is the amount of token1 withdrawn, and the amount of long1 position burnt.
/// @param data The data to be sent to the function, which will go to the swap callback.
struct TimeswapV2OptionSwapParam {
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0ToLong1;
  TimeswapV2OptionSwap transaction;
  uint256 amount;
  bytes data;
}

/// @dev The parameter to call the collect function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param token0To The recipient of token0 withdrawn.
/// @param token1To The recipient of token1 withdrawn.
/// @param transaction The type of collect transaction, more information in Transaction module.
/// @param amount If transaction is GivenShort, the amount of short position burnt.
/// If transaction is GivenToken0, the amount of token0 withdrawn.
/// If transaction is GivenToken1, the amount of token1 withdrawn.
/// @param data The data to be sent to the function, which will go to the collect callback.
/// @notice If data length is zero, skips the callback.
struct TimeswapV2OptionCollectParam {
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  TimeswapV2OptionCollect transaction;
  uint256 amount;
  bytes data;
}

library ParamLibrary {
  /// @dev Sanity checks
  /// @param param the parameter for mint transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionMintParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.shortTo == address(0)) Error.zeroAddress();
    if (param.long0To == address(0)) Error.zeroAddress();
    if (param.long1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount0 == 0 && param.amount1 == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for burn transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionBurnParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.token0To == address(0)) Error.zeroAddress();
    if (param.token1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount0 == 0 && param.amount1 == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for swap transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionSwapParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.tokenTo == address(0)) Error.zeroAddress();
    if (param.longTo == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for collect transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionCollectParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity >= blockTimestamp) Error.stillActive(param.maturity, blockTimestamp);
    if (param.token0To == address(0)) Error.zeroAddress();
    if (param.token1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount == 0) Error.zeroInput();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev A data with strike and maturity data.
/// @param strike The strike.
/// @param maturity The maturity.
struct StrikeAndMaturity {
  uint256 strike;
  uint256 maturity;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";
import {Ownership} from "@timeswap-labs/v2-library/contracts/Ownership.sol";

import {IOwnableTwoSteps} from "../interfaces/IOwnableTwoSteps.sol";

/// @dev contract for ownable implementation with a safety two step owner transfership.
contract OwnableTwoSteps is IOwnableTwoSteps {
  using Ownership for address;

  /// @dev The current owner of the contract.
  address public override owner;
  /// @dev The pending owner of the contract. Is zero when none is pending.
  address public override pendingOwner;

  constructor(address chosenOwner) {
    owner = chosenOwner;
  }

  /// @inheritdoc IOwnableTwoSteps
  function setPendingOwner(address chosenPendingOwner) external override {
    Ownership.checkIfOwner(owner);

    if (chosenPendingOwner == address(0)) Error.zeroAddress();
    chosenPendingOwner.checkIfAlreadyOwner(owner);

    pendingOwner = chosenPendingOwner;

    emit SetOwner(pendingOwner);
  }

  /// @inheritdoc IOwnableTwoSteps
  function acceptOwner() external override {
    msg.sender.checkIfPendingOwner(pendingOwner);

    owner = msg.sender;
    delete pendingOwner;

    emit AcceptOwner(msg.sender);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The different kind of mint transactions.
enum TimeswapV2PoolMint {
  GivenLiquidity,
  GivenLong,
  GivenShort,
  GivenLarger
}

/// @dev The different kind of burn transactions.
enum TimeswapV2PoolBurn {
  GivenLiquidity,
  GivenLong,
  GivenShort,
  GivenSmaller
}

/// @dev The different kind of deleverage transactions.
enum TimeswapV2PoolDeleverage {
  GivenDeltaSqrtInterestRate,
  GivenLong,
  GivenShort,
  GivenSum
}

/// @dev The different kind of leverage transactions.
enum TimeswapV2PoolLeverage {
  GivenDeltaSqrtInterestRate,
  GivenLong,
  GivenShort,
  GivenSum
}

/// @dev The different kind of rebalance transactions.
enum TimeswapV2PoolRebalance {
  GivenLong0,
  GivenLong1
}

library TransactionLibrary {
  /// @dev Reverts when the given type of transaction is invalid.
  error InvalidTransaction();

  /// @dev Function to revert with the error InvalidTransaction.
  function invalidTransaction() internal pure {
    revert InvalidTransaction();
  }

  /// @dev Sanity checks for the mint parameters.
  function check(TimeswapV2PoolMint transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the burn parameters.
  function check(TimeswapV2PoolBurn transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the deleverage parameters.
  function check(TimeswapV2PoolDeleverage transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the leverage parameters.
  function check(TimeswapV2PoolLeverage transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the rebalance parameters.
  function check(TimeswapV2PoolRebalance transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PoolBurnChoiceCallbackParam, TimeswapV2PoolBurnCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the burn function.
interface ITimeswapV2PoolBurnCallback {
  /// @dev Returns the amount of long0 position and long1 positions chosen to be withdrawn.
  /// @notice The StrikeConversion.combine of long0 position and long1 position must be less than or equal to long amount.
  /// @return long0Amount Amount of long0 position to be withdrawn.
  /// @return long1Amount Amount of long1 position to be withdrawn.
  /// @return data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolBurnChoiceCallback(
    TimeswapV2PoolBurnChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);

  /// @dev Require enough liquidity position by the msg.sender.
  /// @return data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolBurnCallback(
    TimeswapV2PoolBurnCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PoolDeleverageChoiceCallbackParam, TimeswapV2PoolDeleverageCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the deleverage function.
interface ITimeswapV2PoolDeleverageCallback {
  /// @dev Returns the amount of long0 position and long1 positions chosen to be deposited to the pool.
  /// @notice The StrikeConversion.combine of long0 position and long1 position must be greater than or equal to long amount.
  /// @dev The short positions will already be minted to the recipient.
  /// @return long0Amount Amount of long0 position to be deposited.
  /// @return long1Amount Amount of long1 position to be deposited.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolDeleverageChoiceCallback(
    TimeswapV2PoolDeleverageChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);

  /// @dev Require the transfer of long0 position and long1 position into the pool.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolDeleverageCallback(
    TimeswapV2PoolDeleverageCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PoolLeverageChoiceCallbackParam, TimeswapV2PoolLeverageCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the leverage function.
interface ITimeswapV2PoolLeverageCallback {
  /// @dev Returns the amount of long0 position and long1 positions chosen to be withdrawn.
  /// @notice The StrikeConversion.combine of long0 position and long1 position must be less than or equal to long amount.
  /// @dev The long0 positions and long1 positions will already be minted to the recipients.
  /// @return long0Amount Amount of long0 position to be withdrawn.
  /// @return long1Amount Amount of long1 position to be withdrawn.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolLeverageChoiceCallback(
    TimeswapV2PoolLeverageChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);

  /// @dev Require the transfer of short position into the pool.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolLeverageCallback(
    TimeswapV2PoolLeverageCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PoolMintChoiceCallbackParam, TimeswapV2PoolMintCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the mint function.
interface ITimeswapV2PoolMintCallback {
  /// @dev Returns the amount of long0 position and long1 positions chosen to be deposited to the pool.
  /// @notice The StrikeConversion.combine of long0 position and long1 position must be greater than or equal to long amount.
  /// @dev The liquidity positions will already be minted to the recipient.
  /// @return long0Amount Amount of long0 position to be deposited.
  /// @return long1Amount Amount of long1 position to be deposited.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolMintChoiceCallback(
    TimeswapV2PoolMintChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);

  /// @dev Require the transfer of long0 position, long1 position, and short position into the pool.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolMintCallback(
    TimeswapV2PoolMintCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PoolRebalanceCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the rebalance function.
interface ITimeswapV2PoolRebalanceCallback {
  /// @dev When Long0ToLong1, require the transfer of long0 position into the pool.
  /// @dev When Long1ToLong0, require the transfer of long1 position into the pool.
  /// @dev The long0 positions or long1 positions will already be minted to the recipient.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolRebalanceCallback(
    TimeswapV2PoolRebalanceCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

interface IOwnableTwoSteps {
  /// @dev Emits when the pending owner is chosen.
  /// @param pendingOwner The new pending owner.
  event SetOwner(address pendingOwner);

  /// @dev Emits when the pending owner accepted and become the new owner.
  /// @param owner The new owner.
  event AcceptOwner(address owner);

  /// @dev The address of the current owner.
  /// @return address
  function owner() external view returns (address);

  /// @dev The address of the current pending owner.
  /// @notice The address can be zero which signifies no pending owner.
  /// @return address
  function pendingOwner() external view returns (address);

  /// @dev The owner sets the new pending owner.
  /// @notice Can only be called by the owner.
  /// @param chosenPendingOwner The newly chosen pending owner.
  function setPendingOwner(address chosenPendingOwner) external;

  /// @dev The pending owner accepts being the new owner.
  /// @notice Can only be called by the pending owner.
  function acceptOwner() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {StrikeAndMaturity} from "@timeswap-labs/v2-option/contracts/structs/StrikeAndMaturity.sol";

import {TimeswapV2PoolCollectProtocolFeesParam, TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam, TimeswapV2PoolMintParam, TimeswapV2PoolBurnParam, TimeswapV2PoolDeleverageParam, TimeswapV2PoolLeverageParam, TimeswapV2PoolRebalanceParam} from "../structs/Param.sol";

/// @title An interface for Timeswap V2 Pool contract.
interface ITimeswapV2Pool {
  /// @dev Emits when liquidity position is transferred.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param from The sender of liquidity position.
  /// @param to The receipeint of liquidity position.
  /// @param liquidityAmount The amount of liquidity position transferred.
  event TransferLiquidity(
    uint256 indexed strike,
    uint256 indexed maturity,
    address from,
    address to,
    uint160 liquidityAmount
  );

  /// @dev Emits when protocol fees are withdrawn by the factory contract owner.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the collectProtocolFees function.
  /// @param long0To The recipient of long0 position fees.
  /// @param long1To The recipient of long1 position fees.
  /// @param shortTo The recipient of short position fees.
  /// @param long0Amount The amount of long0 position fees withdrawn.
  /// @param long1Amount The amount of long1 position fees withdrawn.
  /// @param shortAmount The amount of short position fees withdrawn.
  event CollectProtocolFees(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when transaction fees are withdrawn by a liquidity provider.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the collectTransactionFees function.
  /// @param long0FeesTo The recipient of long0 position fees.
  /// @param long1FeesTo The recipient of long1 position fees.
  /// @param shortFeesTo The recipient of short position fees.
  /// @param shortReturnedTo The recipient of short position returned.
  /// @param long0Fees The amount of long0 position fees withdrawn.
  /// @param long1Fees The amount of long1 position fees withdrawn.
  /// @param shortFees The amount of short position fees withdrawn.
  /// @param shortReturned The amount of short position returned withdrawn.
  event CollectTransactionFeesAndShortReturned(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0FeesTo,
    address long1FeesTo,
    address shortFeesTo,
    address shortReturnedTo,
    uint256 long0Fees,
    uint256 long1Fees,
    uint256 shortFees,
    uint256 shortReturned
  );

  /// @dev Emits when the mint transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the mint function.
  /// @param to The recipient of liquidity positions.
  /// @param liquidityAmount The amount of liquidity positions minted.
  /// @param long0Amount The amount of long0 positions deposited.
  /// @param long1Amount The amount of long1 positions deposited.
  /// @param shortAmount The amount of short positions deposited.
  event Mint(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address to,
    uint160 liquidityAmount,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when the burn transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the burn function.
  /// @param long0To The recipient of long0 positions.
  /// @param long1To The recipient of long1 positions.
  /// @param shortTo The recipient of short positions.
  /// @param liquidityAmount The amount of liquidity positions burnt.
  /// @param long0Amount The amount of long0 positions withdrawn.
  /// @param long1Amount The amount of long1 positions withdrawn.
  /// @param shortAmount The amount of short positions withdrawn.
  event Burn(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint160 liquidityAmount,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when deleverage transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the deleverage function.
  /// @param to The recipient of short positions.
  /// @param long0Amount The amount of long0 positions deposited.
  /// @param long1Amount The amount of long1 positions deposited.
  /// @param shortAmount The amount of short positions withdrawn.
  event Deleverage(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address to,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when leverage transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the leverage function.
  /// @param long0To The recipient of long0 positions.
  /// @param long1To The recipient of long1 positions.
  /// @param long0Amount The amount of long0 positions withdrawn.
  /// @param long1Amount The amount of long1 positions withdrawn.
  /// @param shortAmount The amount of short positions deposited.
  event Leverage(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when rebalance transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the rebalance function.
  /// @param to If isLong0ToLong1 then recipient of long0 positions, ekse recipient of long1 positions.
  /// @param isLong0ToLong1 Long0ToLong1 if true. Long1ToLong0 if false.
  /// @param long0Amount If isLong0ToLong1, amount of long0 positions deposited.
  /// If isLong1ToLong0, amount of long0 positions withdrawn.
  /// @param long1Amount If isLong0ToLong1, amount of long1 positions withdrawn.
  /// If isLong1ToLong0, amount of long1 positions deposited.
  event Rebalance(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address to,
    bool isLong0ToLong1,
    uint256 long0Amount,
    uint256 long1Amount
  );

  error Quote();

  /* ===== VIEW ===== */

  /// @dev Returns the factory address that deployed this contract.
  function poolFactory() external view returns (address);

  /// @dev Returns the Timeswap V2 Option of the pair.
  function optionPair() external view returns (address);

  /// @dev Returns the transaction fee earned by the liquidity providers.
  function transactionFee() external view returns (uint256);

  /// @dev Returns the protocol fee earned by the protocol.
  function protocolFee() external view returns (uint256);

  /// @dev Get the strike and maturity of the pool in the pool enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (StrikeAndMaturity memory);

  /// @dev Get the number of pools being interacted.
  function numberOfPools() external view returns (uint256);

  /// @dev Returns the total amount of liquidity in the pool.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return liquidityAmount The liquidity amount of the pool.
  function totalLiquidity(uint256 strike, uint256 maturity) external view returns (uint160 liquidityAmount);

  /// @dev Returns the square root of the interest rate of the pool.
  /// @dev the square root of interest rate is z/(x+y) where z is the short amount, x+y is the long0 amount, and y is the long1 amount.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return rate The square root of the interest rate of the pool.
  function sqrtInterestRate(uint256 strike, uint256 maturity) external view returns (uint160 rate);

  /// @dev Returns the amount of liquidity owned by the given address.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param owner The address to query the liquidity of.
  /// @return liquidityAmount The amount of liquidity owned by the given address.
  function liquidityOf(uint256 strike, uint256 maturity, address owner) external view returns (uint160 liquidityAmount);

  /// @dev It calculates the global fee and global short returned growth, which is fee increased per unit of liquidity token.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0FeeGrowth The global fee increased per unit of liquidity token for long0.
  /// @return long1FeeGrowth The global fee increased per unit of liquidity token for long1.
  /// @return shortFeeGrowth The global fee increased per unit of liquidity token for short.
  /// @return shortReturnedGrowth The global returned increased per unit of liquidity token for short.
  function feesEarnedAndShortReturnedGrowth(
    uint256 strike,
    uint256 maturity
  )
    external
    view
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth);

  /// @dev It calculates the global fee and global short returned growth, which is fee increased per unit of liquidity token.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param durationForward The duration of time moved forward.
  /// @return long0FeeGrowth The global fee increased per unit of liquidity token for long0.
  /// @return long1FeeGrowth The global fee increased per unit of liquidity token for long1.
  /// @return shortFeeGrowth The global fee increased per unit of liquidity token for short.
  /// @return shortReturnedGrowth The global returned increased per unit of liquidity token for short.
  function feesEarnedAndShortReturnedGrowth(
    uint256 strike,
    uint256 maturity,
    uint96 durationForward
  )
    external
    view
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth);

  /// @dev It calculates the fee earned and global short returned growth, which is short returned per unit of liquidity token.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param owner The address to query the fees earned of.
  /// @return long0Fees The amount of long0 fees owned by the given address.
  /// @return long1Fees The amount of long1 fees owned by the given address.
  /// @return shortFees The amount of short fees owned by the given address.
  /// @return shortReturned The amount of short returned owned by the given address.
  function feesEarnedAndShortReturnedOf(
    uint256 strike,
    uint256 maturity,
    address owner
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned);

  /// @dev It calculates the fee earned and global short returned growth, which is short returned per unit of liquidity token.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param owner The address to query the fees earned of.
  /// @param durationForward The duration of time moved forward.
  /// @return long0Fees The amount of long0 fees owned by the given address.
  /// @return long1Fees The amount of long1 fees owned by the given address.
  /// @return shortFees The amount of short fees owned by the given address.
  /// @return shortReturned The amount of short returned owned by the given address.
  function feesEarnedAndShortReturnedOf(
    uint256 strike,
    uint256 maturity,
    address owner,
    uint96 durationForward
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned);

  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0ProtocolFees The amount of long0 protocol fees owned by the owner of the factory contract.
  /// @return long1ProtocolFees The amount of long1 protocol fees owned by the owner of the factory contract.
  /// @return shortProtocolFees The amount of short protocol fees owned by the owner of the factory contract.
  function protocolFeesEarned(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 long0ProtocolFees, uint256 long1ProtocolFees, uint256 shortProtocolFees);

  /// @dev Returns the amount of long0 and long1 in the pool.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0Amount The amount of long0 in the pool.
  /// @return long1Amount The amount of long1 in the pool.
  function totalLongBalance(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 long0Amount, uint256 long1Amount);

  /// @dev Returns the amount of long0 and long1 adjusted for the protocol and transaction fee.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0Amount The amount of long0 in the pool, adjusted for the protocol and transaction fee.
  /// @return long1Amount The amount of long1 in the pool, adjusted for the protocol and transaction fee.
  function totalLongBalanceAdjustFees(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 long0Amount, uint256 long1Amount);

  /// @dev Returns the amount of sum of long0 and long1 converted to base denomination in the pool.
  /// @dev Returns the amount of short positions in the pool.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return longAmount The amount of sum of long0 and long1 converted to base denomination in the pool.
  /// @return shortAmount The amount of short in the pool.
  function totalPositions(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 longAmount, uint256 shortAmount);

  /* ===== UPDATE ===== */

  /// @dev Transfer liquidity positions to another address.
  /// @notice Does not transfer the transaction fees earned by the sender.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param to The recipient of the liquidity positions.
  /// @param liquidityAmount The amount of liquidity positions transferred
  function transferLiquidity(uint256 strike, uint256 maturity, address to, uint160 liquidityAmount) external;

  /// @dev initializes the pool with the given parameters.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param rate The square root of the interest rate of the pool.
  function initialize(uint256 strike, uint256 maturity, uint160 rate) external;

  /// @dev Collects the protocol fees of the pool.
  /// @dev only protocol owner can call this function.
  /// @dev if the owner enters an amount which is greater than the fee amount they have earned, withdraw only the amount they have.
  /// @param param The parameters of the collectProtocolFees.
  /// @return long0Amount The amount of long0 collected.
  /// @return long1Amount The amount of long1 collected.
  /// @return shortAmount The amount of short collected.
  function collectProtocolFees(
    TimeswapV2PoolCollectProtocolFeesParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount);

  /// @dev Collects the transaction fees of the pool.
  /// @dev only liquidity provider can call this function.
  /// @dev if the owner enters an amount which is greater than the fee amount they have earned, withdraw only the amount they have.
  /// @param param The parameters of the collectTransactionFee.
  /// @return long0Fees The amount of long0 fees collected.
  /// @return long1Fees The amount of long1 fees collected.
  /// @return shortFees The amount of short fees collected.
  /// @return shortReturned The amount of short returned collected.
  function collectTransactionFeesAndShortReturned(
    TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam calldata param
  ) external returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned);

  /// @dev deposit Short and Long tokens and mints Liquidity
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the mint function
  /// @return liquidityAmount The amount of liquidity minted.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function mint(
    TimeswapV2PoolMintParam calldata param
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Short and Long tokens and mints Liquidity
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the mint function.
  /// @param durationForward The duration of time moved forward.
  /// @return liquidityAmount The amount of liquidity minted.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function mint(
    TimeswapV2PoolMintParam calldata param,
    uint96 durationForward
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev burn Liquidity and receive Short and Long tokens
  /// @dev can be only called before the maturity.
  /// @dev after the maturity of the pool, the long0 and long1 tokens are zero. And the short tokens are added into the transaction fees.
  /// @dev if the user wants to burn the liquidity after the maturity, they should call the collectTransactionFee function.
  /// @param param it is a struct that contains the parameters of the burn function
  /// @return liquidityAmount The amount of liquidity burned.
  /// @return long0Amount The amount of long0 withdrawn.
  /// @return long1Amount The amount of long1 withdrawn.
  /// @return shortAmount The amount of short withdrawn.
  /// @return data the data used for the callbacks.
  function burn(
    TimeswapV2PoolBurnParam calldata param
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev burn Liquidity and receive Short and Long tokens
  /// @dev can be only called before the maturity.
  /// @dev after the maturity of the pool, the long0 and long1 tokens are zero. And the short tokens are added into the transaction fees.
  /// @dev if the user wants to burn the liquidity after the maturity, they should call the collectTransactionFee function.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the burn function.
  /// @param durationForward The duration of time moved forward.
  /// @return liquidityAmount The amount of liquidity burned.
  /// @return long0Amount The amount of long0 withdrawn.
  /// @return long1Amount The amount of long1 withdrawn.
  /// @return shortAmount The amount of short withdrawn.
  /// @return data the data used for the callbacks.
  function burn(
    TimeswapV2PoolBurnParam calldata param,
    uint96 durationForward
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Long tokens and receive Short tokens
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the deleverage function
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short received.
  /// @return data the data used for the callbacks.
  function deleverage(
    TimeswapV2PoolDeleverageParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Long tokens and receive Short tokens
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the deleverage function.
  /// @param durationForward The duration of time moved forward.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short received.
  /// @return data the data used for the callbacks.
  function deleverage(
    TimeswapV2PoolDeleverageParam calldata param,
    uint96 durationForward
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Short tokens and receive Long tokens
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the leverage function.
  /// @return long0Amount The amount of long0 received.
  /// @return long1Amount The amount of long1 received.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function leverage(
    TimeswapV2PoolLeverageParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Short tokens and receive Long tokens
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the leverage function.
  /// @param durationForward The duration of time moved forward.
  /// @return long0Amount The amount of long0 received.
  /// @return long1Amount The amount of long1 received.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function leverage(
    TimeswapV2PoolLeverageParam calldata param,
    uint96 durationForward
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev Deposit Long0 to receive Long1 or deposit Long1 to receive Long0.
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the rebalance function
  /// @return long0Amount The amount of long0 received/deposited.
  /// @return long1Amount The amount of long1 deposited/received.
  /// @return data the data used for the callbacks.
  function rebalance(
    TimeswapV2PoolRebalanceParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title An interface for a contract that is capable of deploying Timeswap V2 Pool
/// @notice A contract that constructs a pair must implement this to pass arguments to the pair.
/// @dev This is used to avoid having constructor arguments in the pair contract, which results in the init code hash
/// of the pair being constant allowing the CREATE2 address of the pair to be cheaply computed on-chain.
interface ITimeswapV2PoolDeployer {
  /* ===== VIEW ===== */

  /// @notice Get the parameters to be used in constructing the pair, set transiently during pair creation.
  /// @dev Called by the pair constructor to fetch the parameters of the pair.
  /// @return poolFactory The poolFactory address.
  /// @param optionPair The Timeswap V2 OptionPair address.
  /// @param transactionFee The transaction fee earned by the liquidity providers.
  /// @param protocolFee The protocol fee earned by the DAO.
  function parameter()
    external
    view
    returns (address poolFactory, address optionPair, uint256 transactionFee, uint256 protocolFee);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IOwnableTwoSteps} from "./IOwnableTwoSteps.sol";

/// @title The interface for the contract that deploys Timeswap V2 Pool pair contracts
/// @notice The Timeswap V2 Pool Factory facilitates creation of Timeswap V2 Pool pair.
interface ITimeswapV2PoolFactory is IOwnableTwoSteps {
  /* ===== EVENT ===== */

  /// @dev Emits when a new Timeswap V2 Pool contract is created.
  /// @param caller The address of the caller of create function.
  /// @param option The address of the option contract used by the pool.
  /// @param poolPair The address of the Timeswap V2 Pool contract created.
  event Create(address indexed caller, address indexed option, address indexed poolPair);

  /* ===== VIEW ===== */

  /// @dev Returns the address of the Timeswap V2 Option factory contract utilized by Timeswap V2 Pool factory contract.
  function optionFactory() external view returns (address);

  /// @dev Returns the fixed transaction fee used by all created Timeswap V2 Pool contract.
  function transactionFee() external view returns (uint256);

  /// @dev Returns the fixed protocol fee used by all created Timeswap V2 Pool contract.
  function protocolFee() external view returns (uint256);

  /// @dev Returns the address of a Timeswap V2 Pool.
  /// @dev Returns a zero address if the Timeswap V2 Pool does not exist.
  /// @param option The address of the option contract used by the pool.
  /// @return poolPair The address of the Timeswap V2 Pool contract or a zero address.
  function get(address option) external view returns (address poolPair);

  /// @dev Returns the address of a Timeswap V2 Pool.
  /// @dev Returns a zero address if the Timeswap V2 Pool does not exist.
  /// @param token0 The address of the smaller sized address of ERC20.
  /// @param token1 The address of the larger sized address of ERC20.
  /// @return poolPair The address of the Timeswap V2 Pool contract or a zero address.
  function get(address token0, address token1) external view returns (address poolPair);

  function getByIndex(uint256 id) external view returns (address optionPair);

  function numberOfPairs() external view returns (uint256);

  /* ===== UPDATE ===== */

  /// @dev Creates a Timeswap V2 Pool based on option parameter.
  /// @dev Cannot create a duplicate Timeswap V2 Pool with the same option parameter.
  /// @param token0 The address of the smaller sized address of ERC20.
  /// @param token1 The address of the larger sized address of ERC20.
  /// @param poolPair The address of the Timeswap V2 Pool contract created.
  function create(address token0, address token1) external returns (address poolPair);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";
import {FullMath} from "@timeswap-labs/v2-library/contracts/FullMath.sol";

import {SafeCast} from "@timeswap-labs/v2-library/contracts/SafeCast.sol";

import {FeeCalculation} from "./FeeCalculation.sol";

/// @title Constant Product Library that returns the Constant Product given certain parameters
library ConstantProduct {
  using Math for uint256;
  using SafeCast for uint256;

  /// @dev Reverts when calculation overflows or underflows.
  error CalculationOverload();

  /// @dev Reverts when there is not enough time value liqudity to receive when lending.
  error NotEnoughLiquidityToLend();

  /// @dev Reverts when there is not enough principal liquidity to borrow from.
  error NotEnoughLiquidityToBorrow();

  /// @dev Returns the Long position given liquidity.
  /// @param liquidity The liquidity given.
  /// @param rate The pool's squared root Interest Rate.
  /// @param roundUp Rounds up the result when true. Rounds down the result when false.
  function getLong(uint160 liquidity, uint160 rate, bool roundUp) internal pure returns (uint256) {
    return (uint256(liquidity) << 96).div(rate, roundUp);
  }

  /// @dev Returns the Short position given liquidity.
  /// @param liquidity The liquidity given.
  /// @param rate The pool's squared root Interest Rate.
  /// @param duration The time duration in seconds.
  /// @param roundUp Rounds up the result when true. Rounds down the result when false.
  function getShort(uint160 liquidity, uint160 rate, uint96 duration, bool roundUp) internal pure returns (uint256) {
    return FullMath.mulDiv(uint256(liquidity).unsafeMul(duration), uint256(rate), uint256(1) << 192, roundUp);
  }

  /// @dev Calculate the amount of long positions in base denomination and short positions from change of liquidity.
  /// @param rate The pool's squared root Interest Rate.
  /// @param deltaLiquidity The change in liquidity amount.
  /// @param duration The time duration in seconds.
  /// @param isAdd Increase liquidity amount if true. Decrease liquidity amount if false.
  /// @return longAmount The amount of long positions in base denomination to deposit when increasing liquidity.
  /// The amount of long positions in base denomination to withdraw when decreasing liquidity.
  /// @return shortAmount The amount of short positions to deposit when increasing liquidity.
  /// The amount of short positions to withdraw when decreasing liquidity.
  function calculateGivenLiquidityDelta(
    uint160 rate,
    uint160 deltaLiquidity,
    uint96 duration,
    bool isAdd
  ) internal pure returns (uint256 longAmount, uint256 shortAmount) {
    longAmount = getLong(deltaLiquidity, rate, isAdd);

    shortAmount = getShort(deltaLiquidity, rate, duration, isAdd);
  }

  /// @dev Calculate the amount of liquidity positions and amount of short positions from given long positions in base denomination.
  /// @param rate The pool's squared root Interest Rate.
  /// @param longAmount The amount of long positions.
  /// @param duration The time duration in seconds.
  /// @param isAdd Deposit long amount in base denomination if true. Withdraw long amount in base denomination if false.
  /// @return liquidityAmount The amount of liquidity positions minted when depositing long positions.
  /// The amount of liquidity positions burnt when withdrawing long positions.
  /// @return shortAmount The amount of short positions to deposit when depositing long positions.
  /// The amount of short positions to withdraw when withdrawing long positions.
  function calculateGivenLiquidityLong(
    uint160 rate,
    uint256 longAmount,
    uint96 duration,
    bool isAdd
  ) internal pure returns (uint160 liquidityAmount, uint256 shortAmount) {
    liquidityAmount = getLiquidityGivenLong(rate, longAmount, !isAdd);

    shortAmount = getShort(liquidityAmount, rate, duration, isAdd);
  }

  /// @dev Calculate the amount of liquidity positions and amount of long positions in base denomination from given short positions.
  /// @param rate The pool's squared root Interest Rate.
  /// @param shortAmount The amount of short positions.
  /// @param duration The time duration in seconds.
  /// @param isAdd Deposit short amount if true. Withdraw short amount if false.
  /// @return liquidityAmount The amount of liquidity positions minted when depositing short positions.
  /// The amount of liquidity positions burnt when withdrawing short positions.
  /// @return longAmount The amount of long positions in base denomination to deposit when depositing short positions.
  /// The amount of long positions in base denomination to withdraw when withdrawing short positions.
  function calculateGivenLiquidityShort(
    uint160 rate,
    uint256 shortAmount,
    uint96 duration,
    bool isAdd
  ) internal pure returns (uint160 liquidityAmount, uint256 longAmount) {
    liquidityAmount = getLiquidityGivenShort(rate, shortAmount, duration, !isAdd);

    longAmount = getLong(liquidityAmount, rate, isAdd);
  }

  /// @dev Calculate the amount of liquidity positions and amount of long positions in base denomination or short position whichever is larger or smaller.
  /// @param rate The pool's squared root Interest Rate.
  /// @param amount The amount of long positions in base denomination or short positions whichever is larger.
  /// @param duration The time duration in seconds.
  /// @param isAdd Deposit short amount if true. Withdraw short amount if false.
  /// @return liquidityAmount The amount of liquidity positions minted when depositing short positions.
  /// The amount of liquidity positions burnt when withdrawing short positions.
  /// @return longAmount The amount of long positions in base denomination to deposit when depositing short positions.
  /// The amount of long positions in base denomination to withdraw when withdrawing short positions.
  /// @return shortAmount The amount of short positions to deposit when depositing long positions.
  /// The amount of short positions to withdraw when withdrawing long positions.
  function calculateGivenLiquidityLargerOrSmaller(
    uint160 rate,
    uint256 amount,
    uint96 duration,
    bool isAdd
  ) internal pure returns (uint160 liquidityAmount, uint256 longAmount, uint256 shortAmount) {
    liquidityAmount = getLiquidityGivenLong(rate, amount, !isAdd);

    shortAmount = getShort(liquidityAmount, rate, duration, isAdd);

    if (isAdd ? amount >= shortAmount : amount <= shortAmount) longAmount = amount;
    else {
      liquidityAmount = getLiquidityGivenShort(rate, amount, duration, !isAdd);

      longAmount = getLong(liquidityAmount, rate, isAdd);

      shortAmount = amount;

      if (isAdd ? amount < longAmount : amount > longAmount) longAmount = amount;
    }
  }

  /// @dev Update the new square root interest rate given change in square root change.
  /// @param liquidity The amount of liquidity of the pool.
  /// @param rate The pool's squared root Interest Rate.
  /// @param deltaRate The change in the squared root Interest Rate.
  /// @param duration The time duration in seconds.
  /// @param transactionFee The fee that will be adjusted in the transaction.
  /// @param isAdd Increase square root interest rate if true. Decrease square root interest rate if false.
  /// @return newRate The new squared root Interest Rate.
  /// @return longAmount The amount of long positions in base denomination to withdraw when increasing square root interest rate.
  /// The amount of long positions in base denomination to deposit when decreasing square root interest rate.
  /// @return shortAmount The amount of short positions to deposit when increasing square root interest rate.
  /// The amount of short positions to withdraw when decreasing square root interest rate.
  /// @return fees The amount of long positions fee in base denominations when increasing square root interest rate.
  /// The amount of short positions fee when decreasing square root interest rate.
  function updateGivenSqrtInterestRateDelta(
    uint160 liquidity,
    uint160 rate,
    uint160 deltaRate,
    uint96 duration,
    uint256 transactionFee,
    bool isAdd
  ) internal pure returns (uint160 newRate, uint256 longAmount, uint256 shortAmount, uint256 fees) {
    newRate = isAdd ? rate + deltaRate : rate - deltaRate;

    longAmount = getLongFromSqrtInterestRate(liquidity, rate, deltaRate, newRate, !isAdd);

    shortAmount = getShortFromSqrtInterestRate(liquidity, deltaRate, duration, isAdd);

    fees = FeeCalculation.getFeesRemoval(isAdd ? longAmount : shortAmount, transactionFee);
    if (isAdd) longAmount -= fees;
    else shortAmount -= fees;
  }

  /// @dev Update the new square root interest rate given change in long positions in base denomination.
  /// @param liquidity The amount of liquidity of the pool.
  /// @param rate The pool's squared root Interest Rate.
  /// @param longAmount The amount of long positions.
  /// @param duration The time duration in seconds.
  /// @param transactionFee The fee that will be adjusted in the transaction.
  /// @return newRate The new squared root Interest Rate.
  /// @return shortAmount The amount of short positions to withdraw when depositing long positions in base denomination.
  /// The amount of short positions to deposit when withdrawing long positions in base denomination.
  /// @return fees The amount of short positions fee when depositing long positions in base denomination.
  /// The amount of long positions fee in base denominations fee when withdrawing long positions in base denomination.
  function updateGivenLong(
    uint160 liquidity,
    uint160 rate,
    uint256 longAmount,
    uint96 duration,
    uint256 transactionFee,
    bool isAdd
  ) internal pure returns (uint160 newRate, uint256 shortAmount, uint256 fees) {
    if (!isAdd) fees = FeeCalculation.getFeesAdditional(longAmount, transactionFee);

    newRate = getNewSqrtInterestRateGivenLong(liquidity, rate, longAmount + fees, isAdd);

    shortAmount = getShortFromSqrtInterestRate(liquidity, isAdd ? rate - newRate : newRate - rate, duration, !isAdd);

    if (isAdd) {
      fees = FeeCalculation.getFeesRemoval(shortAmount, transactionFee);
      shortAmount -= fees;
    }
  }

  /// @dev Update the new square root interest rate given change in short positions.
  /// @param liquidity The amount of liquidity of the pool.
  /// @param rate The pool's squared root Interest Rate.
  /// @param shortAmount The amount of short positions.
  /// @param duration The time duration in seconds.
  /// @param transactionFee The fee that will be adjusted in the transaction.
  /// @return newRate The new squared root Interest Rate.
  /// @return longAmount The amount of long positions in base denomination to withdraw when depositing short positions.
  /// The amount of long positions in base denomination to deposit when withdrawing short positions.
  /// @return fees The amount of long positions fee in base denominations when depositing short positions.
  /// The amount of short positions fee when withdrawing short positions.
  function updateGivenShort(
    uint160 liquidity,
    uint160 rate,
    uint256 shortAmount,
    uint96 duration,
    uint256 transactionFee,
    bool isAdd
  ) internal pure returns (uint160 newRate, uint256 longAmount, uint256 fees) {
    if (!isAdd) fees = FeeCalculation.getFeesAdditional(shortAmount, transactionFee);

    uint160 deltaRate;
    (newRate, deltaRate) = getNewSqrtInterestRateGivenShort(liquidity, rate, shortAmount + fees, duration, isAdd);

    longAmount = getLongFromSqrtInterestRate(liquidity, rate, deltaRate, newRate, !isAdd);

    if (isAdd) {
      fees = FeeCalculation.getFeesRemoval(longAmount, transactionFee);
      longAmount -= fees;
    }
  }

  /// @dev Update the new square root interest rate given sum of long positions in base denomination change and short position change.
  /// @param liquidity The amount of liquidity of the pool.
  /// @param rate The pool's squared root Interest Rate.
  /// @param sumAmount The sum amount of long positions in base denomination change and short position change.
  /// @param duration The time duration in seconds.
  /// @param transactionFee The fee that will be adjusted in the transaction.
  /// @param isAdd Increase square root interest rate if true. Decrease square root interest rate if false.
  /// @return newRate The new squared root Interest Rate.
  /// @return longAmount The amount of long positions in base denomination to withdraw when increasing square root interest rate.
  /// The amount of long positions in base denomination to deposit when decreasing square root interest rate.
  /// @return shortAmount The amount of short positions to deposit when increasing square root interest rate.
  /// The amount of short positions to withdraw when decreasing square root interest rate.
  /// @return fees The amount of long positions fee in base denominations when increasing square root interest rate.
  /// The amount of short positions fee when decreasing square root interest rate.
  function updateGivenSumLong(
    uint160 liquidity,
    uint160 rate,
    uint256 sumAmount,
    uint96 duration,
    uint256 transactionFee,
    bool isAdd
  ) internal pure returns (uint160 newRate, uint256 longAmount, uint256 shortAmount, uint256 fees) {
    uint256 amount = getShortOrLongFromGivenSum(liquidity, rate, sumAmount, duration, transactionFee, isAdd);

    if (isAdd) (newRate, ) = getNewSqrtInterestRateGivenShort(liquidity, rate, amount, duration, false);
    else newRate = getNewSqrtInterestRateGivenLong(liquidity, rate, amount, false);

    fees = FeeCalculation.getFeesRemoval(amount, transactionFee);
    amount -= fees;

    if (isAdd) {
      shortAmount = amount;
      longAmount = sumAmount - shortAmount;
    } else {
      longAmount = amount;
      shortAmount = sumAmount - longAmount;
    }
  }

  /// @dev Returns liquidity for a given long.
  /// @param rate The pool's squared root Interest Rate.
  /// @param longAmount The amount of long in base denomination change..
  /// @param roundUp Round up the result when true. Round down the result when false.
  function getLiquidityGivenLong(uint160 rate, uint256 longAmount, bool roundUp) private pure returns (uint160) {
    return FullMath.mulDiv(uint256(rate), longAmount, uint256(1) << 96, roundUp).toUint160();
  }

  /// @dev Returns liquidity for a given short.
  /// @param rate The pool's squared root Interest Rate.
  /// @param shortAmount The amount of short change.
  /// @param duration The time duration in seconds.
  /// @param roundUp Round up the result when true. Round down the result when false.
  function getLiquidityGivenShort(
    uint160 rate,
    uint256 shortAmount,
    uint96 duration,
    bool roundUp
  ) private pure returns (uint160) {
    return FullMath.mulDiv(shortAmount, uint256(1) << 192, uint256(rate).unsafeMul(duration), roundUp).toUint160();
  }

  /// @dev Returns the new squared root interest rate given long positions in base denomination change.
  /// @param liquidity The liquidity of the pool.
  /// @param rate The pool's squared root Interest Rate.
  /// @param longAmount The amount long positions in base denomination change.
  /// @param isAdd Long positions increase when true. Long positions decrease when false.
  function getNewSqrtInterestRateGivenLong(
    uint160 liquidity,
    uint160 rate,
    uint256 longAmount,
    bool isAdd
  ) private pure returns (uint160) {
    uint256 numerator;
    unchecked {
      numerator = uint256(liquidity) << 96;
    }

    uint256 product = longAmount.unsafeMul(rate);

    if (isAdd) {
      if (product.div(longAmount, false) == rate) {
        uint256 denominator = numerator.unsafeAdd(product);
        if (denominator >= numerator) {
          return FullMath.mulDiv(numerator, rate, denominator, true).toUint160();
        }
      }

      uint256 denominator2 = numerator.div(rate, false);

      denominator2 += longAmount;
      return numerator.div(denominator2, true).toUint160();
    } else {
      if (product.div(longAmount, false) != rate || product >= numerator) revert NotEnoughLiquidityToBorrow();

      uint256 denominator = numerator.unsafeSub(product);
      return (FullMath.mulDiv(numerator, rate, denominator, true)).toUint160();
    }
  }

  /// @dev Returns the new squared root interest rate given short position change.
  /// @param liquidity The liquidity of the pool.
  /// @param rate The pool's squared root Interest Rate.
  /// @param shortAmount The amount short positions change.
  /// @param duration The time duration in seconds.
  /// @param isAdd Short positions increase when true. Short positions decrease when false.
  /// @return newRate The updated squared interest rate
  /// @return deltaRate The difference between the new and old squared interest rate
  function getNewSqrtInterestRateGivenShort(
    uint160 liquidity,
    uint160 rate,
    uint256 shortAmount,
    uint96 duration,
    bool isAdd
  ) private pure returns (uint160 newRate, uint160 deltaRate) {
    uint256 denominator = uint256(liquidity).unsafeMul(duration);

    deltaRate = FullMath.mulDiv(shortAmount, uint256(1) << 192, denominator, !isAdd).toUint160();

    if (isAdd) newRate = rate + deltaRate;
    else if (rate > deltaRate) newRate = rate - deltaRate;
    else revert NotEnoughLiquidityToLend();
  }

  /// @dev Returns the long positions for a given interest rate.
  /// @param liquidity The liquidity of the pool.
  /// @param rate The pool's squared root Interest Rate.
  /// @param deltaRate The pool's delta rate in square root interest rate.
  /// @param newRate The new interest rate of the pool
  /// @param roundUp Increases in square root interest rate when true. Decrease in square root interest rate when false.
  function getLongFromSqrtInterestRate(
    uint160 liquidity,
    uint160 rate,
    uint160 deltaRate,
    uint160 newRate,
    bool roundUp
  ) private pure returns (uint256) {
    uint256 numerator;
    unchecked {
      numerator = uint256(liquidity) << 96;
    }
    return
      roundUp
        ? FullMath.mulDiv(numerator, deltaRate, uint256(rate), true).div(newRate, true)
        : FullMath.mulDiv(numerator, deltaRate, uint256(newRate), false).div(rate, false);
  }

  /// @dev Returns the short positions for a given interest rate.
  /// @param liquidity The liquidity of the pool.
  /// @param deltaRate The pool's delta rate in square root interest rate.
  /// @param duration The time duration in seconds.
  /// @param roundUp Increases in square root interest rate when true. Decrease in square root interest rate when false.
  function getShortFromSqrtInterestRate(
    uint160 liquidity,
    uint160 deltaRate,
    uint96 duration,
    bool roundUp
  ) private pure returns (uint256) {
    uint256 numerator = uint256(liquidity).unsafeMul(duration);
    return FullMath.mulDiv(uint256(numerator), uint256(deltaRate), uint256(1) << 192, roundUp);
  }

  /// @dev Get the short amount or long amount for given sum type transactions.
  /// @param liquidity The liquidity of the pool.
  /// @param rate The pool's squared root Interest Rate.
  /// @param sumAmount The given sum amount.
  /// @param duration The duration of the pool.
  /// @param transactionFee The transaction fee of the pool.
  /// @param isShort True if to calculate for short amount.
  /// False if to calculate for long amount.
  /// @return amount The short amount or long amount calculated.
  function getShortOrLongFromGivenSum(
    uint160 liquidity,
    uint160 rate,
    uint256 sumAmount,
    uint96 duration,
    uint256 transactionFee,
    bool isShort
  ) private pure returns (uint256 amount) {
    uint256 negativeB = calculateNegativeB(liquidity, rate, sumAmount, duration, transactionFee, isShort);

    uint256 sqrtDiscriminant = calculateSqrtDiscriminant(
      liquidity,
      rate,
      sumAmount,
      duration,
      transactionFee,
      negativeB,
      isShort
    );

    amount = (negativeB - sqrtDiscriminant).shr(1, false);
  }

  /// @dev Calculate the negativeB.
  /// @param liquidity The liquidity of the pool.
  /// @param rate The pool's squared root Interest Rate.
  /// @param sumAmount The given sum amount.
  /// @param duration The duration of the pool.
  /// @param transactionFee The transaction fee of the pool.
  /// @param isShort True if to calculate for short amount.
  /// False if to calculate for long amount.
  /// @return negativeB The negative B calculated.
  function calculateNegativeB(
    uint160 liquidity,
    uint160 rate,
    uint256 sumAmount,
    uint96 duration,
    uint256 transactionFee,
    bool isShort
  ) private pure returns (uint256 negativeB) {
    uint256 adjustment = (uint256(1) << 16).unsafeSub(transactionFee);

    uint256 negativeB0 = isShort ? getShort(liquidity, rate, duration, false) : getLong(liquidity, rate, false);
    uint256 negativeB1 = isShort
      ? FullMath.mulDiv(liquidity, uint256(1) << 112, uint256(rate).unsafeMul(adjustment), false)
      : FullMath.mulDiv(uint256(liquidity).unsafeMul(duration), rate, (uint256(1) << 176).unsafeMul(adjustment), false);
    uint256 negativeB2 = FullMath.mulDiv(sumAmount, uint256(1) << 16, adjustment, false);

    negativeB = negativeB0 + negativeB1 + negativeB2;
  }

  /// Dev Calculate the square root discriminant.
  /// @param liquidity The liquidity of the pool.
  /// @param rate The pool's squared root Interest Rate.
  /// @param sumAmount The given sum amount.
  /// @param duration The duration of the pool.
  /// @param transactionFee The transaction fee of the pool.
  /// @param negativeB The negative B calculated.
  /// @param isShort True if to calculate for short amount.
  /// False if to calculate for long amount.
  /// @return sqrtDiscriminant The square root disriminant calculated.
  function calculateSqrtDiscriminant(
    uint160 liquidity,
    uint160 rate,
    uint256 sumAmount,
    uint96 duration,
    uint256 transactionFee,
    uint256 negativeB,
    bool isShort
  ) private pure returns (uint256 sqrtDiscriminant) {
    uint256 denominator = isShort
      ? (uint256(1) << 174).unsafeMul((uint256(1) << 16).unsafeSub(transactionFee))
      : uint256(rate).unsafeMul((uint256(1) << 16).unsafeSub(transactionFee));

    (uint256 a0, uint256 a1) = isShort
      ? FullMath.mul512(uint256(liquidity).unsafeMul(duration), rate)
      : FullMath.mul512(liquidity, uint256(1) << 114);

    (uint256 a00, uint256 a01) = FullMath.mul512(a0, sumAmount);
    (uint256 a10, uint256 a11) = FullMath.mul512(a1, sumAmount);

    if (a11 == 0 && a01.unsafeAdd(a10) >= a01) {
      a0 = a00;
      a1 = a01.unsafeAdd(a10);
      (a0, a1) = FullMath.div512(a0, a1, denominator, false);
    } else {
      (a0, a1) = FullMath.div512(a0, a1, denominator, false);

      (a00, a01) = FullMath.mul512(a0, sumAmount);
      (a10, a11) = FullMath.mul512(a1, sumAmount);

      if (a11 != 0 || a01.unsafeAdd(a10) < a01) revert CalculationOverload();
      a0 = a00;
      a1 = a01.unsafeAdd(a10);
    }

    (uint256 b0, uint256 b1) = FullMath.mul512(negativeB, negativeB);

    (b0, b1) = FullMath.sub512(b0, b1, a0, a1);

    sqrtDiscriminant = FullMath.sqrt512(b0, b1, true);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {StrikeConversion} from "@timeswap-labs/v2-library/contracts/StrikeConversion.sol";
import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";

import {FeeCalculation} from "./FeeCalculation.sol";
import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

/// @title Constant Sum Library that returns the Constant Sum given certain parameters
library ConstantSum {
  using Math for uint256;

  /// @dev Calculate long amount out.
  /// @param strike The strike of the pool.
  /// @param longAmountIn The long amount to be deposited.
  /// @param transactionFee The fee that will be adjusted in the transaction.
  /// @param isLong0ToLong1 Deposit long0 positions when true. Deposit long1 positions when false.
  function calculateGivenLongIn(
    uint256 strike,
    uint256 longAmountIn,
    uint256 transactionFee,
    bool isLong0ToLong1
  ) internal pure returns (uint256 longAmountOut, uint256 longFees) {
    longAmountOut = StrikeConversion.convert(longAmountIn, strike, isLong0ToLong1, false);
    longFees = FeeCalculation.getFeesRemoval(longAmountOut, transactionFee);
    longAmountOut = longAmountOut.unsafeSub(longFees);
  }

  /// @dev Calculate long amount in.
  /// @param strike The strike of the pool.
  /// @param longAmountOut The long amount to be withdrawn.
  /// @param transactionFee The fee that will be adjusted in the transaction.
  /// @param isLong0ToLong1 Deposit long0 positions when true. Deposit long1 positions when false.
  function calculateGivenLongOut(
    uint256 strike,
    uint256 longAmountOut,
    uint256 transactionFee,
    bool isLong0ToLong1
  ) internal pure returns (uint256 longAmountIn, uint256 longFees) {
    longFees = FeeCalculation.getFeesAdditional(longAmountOut, transactionFee);
    longAmountIn = StrikeConversion.convert(longAmountOut + longFees, strike, !isLong0ToLong1, true);
  }

  /// @dev Calculate long amount in without adjusting for fees.
  /// @param strike The strike of the pool.
  /// @param longAmountOut The long amount to be withdrawn.
  /// @param isLong0ToLong1 Deposit long0 positions when true. Deposit long1 positions when false.
  function calculateGivenLongOutAlreadyAdjustFees(
    uint256 strike,
    uint256 longAmountOut,
    bool isLong0ToLong1
  ) internal pure returns (uint256 longAmountIn) {
    longAmountIn = StrikeConversion.convert(longAmountOut, strike, !isLong0ToLong1, true);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title A library for The Timeswap V2 Option contract Duration type
library DurationLibrary {
  error DurationOverflow(uint256 duration);

  /// @dev initialize the duration type
  /// @dev Reverts when the duration is too large.
  /// @param duration The duration in seconds which is needed to be converted to the Duration type.
  function init(uint256 duration) internal pure returns (uint96) {
    if (duration > type(uint96).max) revert DurationOverflow(duration);
    return uint96(duration);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";
import {SafeCast} from "@timeswap-labs/v2-library/contracts/SafeCast.sol";

import {DurationLibrary} from "./Duration.sol";

/// @title calculation of duration
library DurationCalculation {
  using Math for uint256;
  using SafeCast for uint256;

  /// @dev gives the duration between the current block timestamp and the last timestamp
  /// @param lastTimestamp The last timestamp
  /// @param blockTimestamp The current block timestamp
  /// @return duration The duration between the current block timestamp and the last timestamp
  function unsafeDurationFromLastTimestampToNow(
    uint96 lastTimestamp,
    uint96 blockTimestamp
  ) internal pure returns (uint96 duration) {
    duration = uint256(blockTimestamp).unsafeSub(lastTimestamp).toUint96();
  }

  /// @dev gives the duration between the maturity and the current block timestamp
  /// @param maturity The maturity of the pool
  /// @param blockTimestamp The current block timestamp
  /// @return duration The duration between the maturity and the current block timestamp
  function unsafeDurationFromNowToMaturity(
    uint256 maturity,
    uint96 blockTimestamp
  ) internal pure returns (uint96 duration) {
    duration = maturity.unsafeSub(uint256(blockTimestamp)).toUint96();
  }

  /// @dev gives the duration between the maturity and the last timestamp
  /// @param lastTimestamp The last timestamp
  /// @param maturity The maturity of the pool
  /// @return duration The duration between the maturity and the last timestamp
  function unsafeDurationFromLastTimestampToMaturity(
    uint96 lastTimestamp,
    uint256 maturity
  ) internal pure returns (uint96 duration) {
    duration = maturity.unsafeSub(lastTimestamp).toUint96();
  }

  /// @dev gives the duration between the maturity and the minimum of the last timestamp and the current block timestamp
  /// @param lastTimestamp The last timestamp
  /// @param maturity The maturity of the pool
  /// @param blockTimestamp The current block timestamp
  /// @return duration The duration between the maturity and the minimum of the last timestamp and the current block timestamp
  function unsafeDurationFromLastTimestampToNowOrMaturity(
    uint96 lastTimestamp,
    uint256 maturity,
    uint96 blockTimestamp
  ) internal pure returns (uint96 duration) {
    duration = maturity.min(blockTimestamp).unsafeSub(lastTimestamp).toUint96();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {FeeCalculation} from "./FeeCalculation.sol";
import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";

/// @title library for calculating duration weight
/// @author Timeswap Labs
library DurationWeight {
  using Math for uint256;

  /// @dev update the short returned growth given the short returned growth and the short token amount.
  /// @param liquidity The liquidity of the pool.
  /// @param shortReturnedGrowth The current amount of short returned growth.
  /// @param shortAmount The amount of short withdrawn.
  /// @param newShortReturnedGrowth The newly updated short returned growth.
  function update(
    uint160 liquidity,
    uint256 shortReturnedGrowth,
    uint256 shortAmount
  ) internal pure returns (uint256 newShortReturnedGrowth) {
    newShortReturnedGrowth = shortReturnedGrowth.unsafeAdd(FeeCalculation.getFeeGrowth(shortAmount, liquidity));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";
import {FullMath} from "@timeswap-labs/v2-library/contracts/FullMath.sol";

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

///@title library for fees related calculations
library FeeCalculation {
  using Math for uint256;

  event ReceiveTransactionFees(TimeswapV2OptionPosition position, uint256 fees);

  /// @dev Reverts when fee overflow.
  error FeeOverflow();

  /// @dev reverts to overflow fee.
  function feeOverflow() private pure {
    revert FeeOverflow();
  }

  /// @dev Updates the new fee growth and protocol fee given the current fee growth and protocol fee.
  /// @param position The position to be updated.
  /// @param liquidity The current liquidity in the pool.
  /// @param feeGrowth The current feeGrowth in the pool.
  /// @param protocolFees The current protocolFees in the pool.
  /// @param fees The fees to be earned.
  /// @param protocolFee The protocol fee rate.
  /// @return newFeeGrowth The newly updated fee growth.
  /// @return newProtocolFees The newly updated protocol fees.
  function update(
    TimeswapV2OptionPosition position,
    uint160 liquidity,
    uint256 feeGrowth,
    uint256 protocolFees,
    uint256 fees,
    uint256 protocolFee
  ) internal returns (uint256 newFeeGrowth, uint256 newProtocolFees) {
    uint256 protocolFeesToAdd = getFeesRemoval(fees, protocolFee);
    uint256 transactionFees = fees.unsafeSub(protocolFeesToAdd);

    newFeeGrowth = feeGrowth.unsafeAdd(getFeeGrowth(transactionFees, liquidity));

    newProtocolFees = protocolFees + protocolFeesToAdd;

    emit ReceiveTransactionFees(position, transactionFees);
  }

  /// @dev get the fee given the last fee growth and the global fee growth
  /// @notice returns zero if the last fee growth is equal to the global fee growth
  /// @param liquidity The current liquidity in the pool.
  /// @param lastFeeGrowth The previous global fee growth when owner enters.
  /// @param globalFeeGrowth The current global fee growth.
  function getFees(uint160 liquidity, uint256 lastFeeGrowth, uint256 globalFeeGrowth) internal pure returns (uint256) {
    return
      globalFeeGrowth != lastFeeGrowth
        ? FullMath.mulDiv(liquidity, globalFeeGrowth.unsafeSub(lastFeeGrowth), uint256(1) << 128, false)
        : 0;
  }

  /// @dev Adds the fees to the amount.
  /// @param amount The original amount.
  /// @param fee The transaction fee rate.
  function addFees(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return FullMath.mulDiv(amount, (uint256(1) << 16), (uint256(1) << 16).unsafeSub(fee), true);
  }

  /// @dev Removes the fees from the amount.
  /// @param amount The original amount.
  /// @param fee The transaction fee rate.
  function removeFees(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return FullMath.mulDiv(amount, (uint256(1) << 16).unsafeSub(fee), uint256(1) << 16, false);
  }

  /// @dev Get the fees from an amount with fees.
  /// @param amount The amount with fees.
  /// @param fee The transaction fee rate.
  function getFeesRemoval(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return FullMath.mulDiv(amount, fee, uint256(1) << 16, true);
  }

  /// @dev Get the fees from an amount.
  /// @param amount The amount with fees.
  /// @param fee The transaction fee rate.
  function getFeesAdditional(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return FullMath.mulDiv(amount, fee, (uint256(1) << 16).unsafeSub(fee), true);
  }

  /// @dev Get the fee growth.
  /// @param feeAmount The fee amount.
  /// @param liquidity The current liquidity in the pool.
  function getFeeGrowth(uint256 feeAmount, uint160 liquidity) internal pure returns (uint256) {
    return FullMath.mulDiv(feeAmount, uint256(1) << 128, liquidity, false);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title library for renentrancy protection
/// @author Timeswap Labs
library ReentrancyGuard {
  /// @dev Reverts when their is a reentrancy to a single option.
  error NoReentrantCall();

  /// @dev Reverts when the option, pool, or token id is not interacted yet.
  error NotInteracted();

  /// @dev The initial state which must be change to NOT_ENTERED when first interacting.
  uint96 internal constant NOT_INTERACTED = 0;

  /// @dev The initial and ending state of balanceTarget in the Option struct.
  uint96 internal constant NOT_ENTERED = 1;

  /// @dev The state where the contract is currently being interacted with.
  uint96 internal constant ENTERED = 2;

  /// @dev Check if there is a reentrancy in an option.
  /// @notice Reverts when balanceTarget is not zero.
  /// @param reentrancyGuard The balance being inquired.
  function check(uint96 reentrancyGuard) internal pure {
    if (reentrancyGuard == NOT_INTERACTED) revert NotInteracted();
    if (reentrancyGuard == ENTERED) revert NoReentrantCall();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract.
contract NoDelegateCall {
  /* ===== ERROR ===== */

  /// @dev Reverts when called using delegatecall.
  error CannotBeDelegateCalled();

  /* ===== MODEL ===== */

  /// @dev The original address of this contract.
  address private immutable original;

  /* ===== INIT ===== */

  constructor() {
    // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
    // In other words, this variable won't change when it's checked at runtime.
    original = address(this);
  }

  /* ===== MODIFIER ===== */

  /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
  /// and the use of immutable means the address bytes are copied in every place the modifier is used.
  function checkNotDelegateCall() private view {
    if (address(this) != original) revert CannotBeDelegateCalled();
  }

  /// @notice Prevents delegatecall into the modified method
  modifier noDelegateCall() {
    checkNotDelegateCall();
    _;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The parameters for the add fees callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Fees The amount of long0 position required by the pool from msg.sender.
/// @param long1Fees The amount of long1 position required by the pool from msg.sender.
/// @param shortFees The amount of short position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolAddFeesCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  bytes data;
}

/// @dev The parameters for the mint choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param longAmount The amount of long position in base denomination required by the pool from msg.sender.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param liquidityAmount The amount of liquidity position minted.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolMintChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 longAmount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the mint callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position required by the pool from msg.sender.
/// @param long1Amount The amount of long1 position required by the pool from msg.sender.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param liquidityAmount The amount of liquidity position minted.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolMintCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the burn choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Balance The amount of long0 position that can be withdrawn from the pool.
/// @param long1Balance The amount of long1 position that can be withdrawn from the pool.
/// @param longAmount The amount of long position in base denomination that will be withdrawn.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param liquidityAmount The amount of liquidity position burnt.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolBurnChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Balance;
  uint256 long1Balance;
  uint256 longAmount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the burn callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position that will be withdrawn.
/// @param long1Amount The amount of long1 position that will be withdrawn.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param liquidityAmount The amount of liquidity position burnt.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolBurnCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the deleverage choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position required by the pool from msg.sender.
/// @param long1Amount The amount of long1 position required by the pool from msg.sender.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolDeleverageChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 longAmount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the deleverage callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param longAmount The amount of long position in base denomination required by the pool from msg.sender.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolDeleverageCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the leverage choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Balance The amount of long0 position that can be withdrawn from the pool.
/// @param long1Balance The amount of long1 position that can be withdrawn from the pool.
/// @param longAmount The amount of long position in base denomination that will be withdrawn.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolLeverageChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Balance;
  uint256 long1Balance;
  uint256 longAmount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the leverage choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position that can be withdrawn.
/// @param long1Amount The amount of long1 position that can be withdrawn.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolLeverageCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the rebalance callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param isLong0ToLong1 Long0ToLong1 when true. Long1ToLong0 when false.
/// @param long0Amount When Long0ToLong1, the amount of long0 position required by the pool from msg.sender.
/// When Long1ToLong0, the amount of long0 position that can be withdrawn.
/// @param long1Amount When Long0ToLong1, the amount of long1 position that can be withdrawn.
/// When Long1ToLong0, the amount of long1 position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolRebalanceCallbackParam {
  uint256 strike;
  uint256 maturity;
  bool isLong0ToLong1;
  uint256 long0Amount;
  uint256 long1Amount;
  bytes data;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";

import {FeeCalculation} from "../libraries/FeeCalculation.sol";

/// @param liquidity The amount of liquidity owned.
/// @param long0FeeGrowth The long0 position fee growth stored when the user entered the positions.
/// @param long1FeeGrowth The long1 position fee growth stored when the user entered the positions.
/// @param shortFeeGrowth The short position fee growth stored when the user entered the positions.
/// @param long0Fees The stored amount of long0 position fees owned.
/// @param long1Fees The stored amount of long1 position fees owned.
/// @param shortFees The stored amount of short position fees owned.
struct LiquidityPosition {
  uint160 liquidity;
  uint256 long0FeeGrowth;
  uint256 long1FeeGrowth;
  uint256 shortFeeGrowth;
  uint256 shortReturnedGrowth;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  uint256 shortReturned;
}

/// @title library for liquidity position utils
/// @author Timeswap Labs
library LiquidityPositionLibrary {
  using Math for uint256;

  /// @dev Get the total fees earned and short returned by the owner.
  /// @param liquidityPosition The liquidity position of the owner.
  /// @param long0FeeGrowth The current global long0 position fee growth to be compared.
  /// @param long1FeeGrowth The current global long1 position fee growth to be compared.
  /// @param shortFeeGrowth The current global short position fee growth to be compared.
  /// @param shortReturnedGrowth The current glocal short position returned growth to be compared
  /// @return long0Fees The long0 fees owned.
  /// @return long1Fees The long1 fees owned.
  /// @return shortFees The short fees owned.
  /// @return shortReturned The short returned owned.
  function feesEarnedAndShortReturnedOf(
    LiquidityPosition memory liquidityPosition,
    uint256 long0FeeGrowth,
    uint256 long1FeeGrowth,
    uint256 shortFeeGrowth,
    uint256 shortReturnedGrowth
  ) internal pure returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned) {
    uint160 liquidity = liquidityPosition.liquidity;

    long0Fees = liquidityPosition.long0Fees.unsafeAdd(
      FeeCalculation.getFees(liquidity, liquidityPosition.long0FeeGrowth, long0FeeGrowth)
    );
    long1Fees = liquidityPosition.long1Fees.unsafeAdd(
      FeeCalculation.getFees(liquidity, liquidityPosition.long1FeeGrowth, long1FeeGrowth)
    );
    shortFees = liquidityPosition.shortFees.unsafeAdd(
      FeeCalculation.getFees(liquidity, liquidityPosition.shortFeeGrowth, shortFeeGrowth)
    );
    shortReturned = liquidityPosition.shortReturned.unsafeAdd(
      FeeCalculation.getFees(liquidityPosition.liquidity, liquidityPosition.shortReturnedGrowth, shortReturnedGrowth)
    );
  }

  /// @dev Update the liquidity position after collectTransactionFees, mint and/or burn functions.
  /// @param liquidityPosition The liquidity position of the owner.
  /// @param long0FeeGrowth The current global long0 position fee growth to be compared.
  /// @param long1FeeGrowth The current global long1 position fee growth to be compared.
  /// @param shortFeeGrowth The current global short position fee growth to be compared.
  /// @param shortReturnedGrowth The current global short position returned growth to be compared.
  function update(
    LiquidityPosition storage liquidityPosition,
    uint256 long0FeeGrowth,
    uint256 long1FeeGrowth,
    uint256 shortFeeGrowth,
    uint256 shortReturnedGrowth
  ) internal {
    uint160 liquidity = liquidityPosition.liquidity;

    if (liquidity != 0) {
      liquidityPosition.long0Fees += FeeCalculation.getFees(
        liquidity,
        liquidityPosition.long0FeeGrowth,
        long0FeeGrowth
      );
      liquidityPosition.long1Fees += FeeCalculation.getFees(
        liquidity,
        liquidityPosition.long1FeeGrowth,
        long1FeeGrowth
      );
      liquidityPosition.shortFees += FeeCalculation.getFees(
        liquidity,
        liquidityPosition.shortFeeGrowth,
        shortFeeGrowth
      );
      liquidityPosition.shortReturned += FeeCalculation.getFees(
        liquidity,
        liquidityPosition.shortReturnedGrowth,
        shortReturnedGrowth
      );
    }

    liquidityPosition.long0FeeGrowth = long0FeeGrowth;
    liquidityPosition.long1FeeGrowth = long1FeeGrowth;
    liquidityPosition.shortFeeGrowth = shortFeeGrowth;
    liquidityPosition.shortReturnedGrowth = shortReturnedGrowth;
  }

  /// @dev updates the liquidity position by the given amount
  /// @param liquidityPosition the position that is to be updated
  /// @param liquidityAmount the amount that is to be incremented in the position
  function mint(LiquidityPosition storage liquidityPosition, uint160 liquidityAmount) internal {
    liquidityPosition.liquidity += liquidityAmount;
  }

  /// @dev updates the liquidity position by the given amount
  /// @param liquidityPosition the position that is to be updated
  /// @param liquidityAmount the amount that is to be decremented in the position
  function burn(LiquidityPosition storage liquidityPosition, uint160 liquidityAmount) internal {
    liquidityPosition.liquidity -= liquidityAmount;
  }

  /// @dev function to collect the transaction fees accrued for a given liquidity position
  /// @param liquidityPosition the liquidity position that whose fees is collected
  /// @param long0FeesRequested the long0 fees requested
  /// @param long1FeesRequested the long1 fees requested
  /// @param shortFeesRequested the short fees requested
  /// @param shortReturnedRequested the short returned requested
  /// @return long0Fees the long0 fees collected
  /// @return long1Fees the long1 fees collected
  /// @return shortFees the short fees collected
  /// @return shortReturned the short returned collected
  function collectTransactionFeesAndShortReturned(
    LiquidityPosition storage liquidityPosition,
    uint256 long0FeesRequested,
    uint256 long1FeesRequested,
    uint256 shortFeesRequested,
    uint256 shortReturnedRequested
  ) internal returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned) {
    if (long0FeesRequested >= liquidityPosition.long0Fees) {
      long0Fees = liquidityPosition.long0Fees;
      liquidityPosition.long0Fees = 0;
    } else {
      long0Fees = long0FeesRequested;
      liquidityPosition.long0Fees = liquidityPosition.long0Fees.unsafeSub(long0FeesRequested);
    }

    if (long1FeesRequested >= liquidityPosition.long1Fees) {
      long1Fees = liquidityPosition.long1Fees;
      liquidityPosition.long1Fees = 0;
    } else {
      long1Fees = long1FeesRequested;
      liquidityPosition.long1Fees = liquidityPosition.long1Fees.unsafeSub(long1FeesRequested);
    }

    if (shortFeesRequested >= liquidityPosition.shortFees) {
      shortFees = liquidityPosition.shortFees;
      liquidityPosition.shortFees = 0;
    } else {
      shortFees = shortFeesRequested;
      liquidityPosition.shortFees = liquidityPosition.shortFees.unsafeSub(shortFeesRequested);
    }

    if (shortReturnedRequested >= liquidityPosition.shortReturned) {
      shortReturned = liquidityPosition.shortReturned;
      liquidityPosition.shortReturned = 0;
    } else {
      shortReturned = shortReturnedRequested;
      liquidityPosition.shortReturned = liquidityPosition.shortReturned.unsafeSub(shortReturnedRequested);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {TimeswapV2PoolMint, TimeswapV2PoolBurn, TimeswapV2PoolDeleverage, TimeswapV2PoolLeverage, TimeswapV2PoolRebalance, TransactionLibrary} from "../enums/Transaction.sol";

/// @dev The parameter for collectProtocolFees functions.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param shortTo The recipient of short positions.
/// @param long0Requested The maximum amount of long0 positions wanted.
/// @param long1Requested The maximum amount of long1 positions wanted.
/// @param shortRequested The maximum amount of short positions wanted.
struct TimeswapV2PoolCollectProtocolFeesParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  uint256 long0Requested;
  uint256 long1Requested;
  uint256 shortRequested;
}

/// @dev The parameter for collectTransactionFeesAndShortReturned functions.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0FeesTo The recipient of long0 fees.
/// @param long1FeesTo The recipient of long1 fees.
/// @param shortFeesTo The recipient of short fees.
/// @param shortReturnedTo The recipient of short returned.
/// @param long0FeesRequested The maximum amount of long0 fees wanted.
/// @param long1FeesRequested The maximum amount of long1 fees wanted.
/// @param shortFeesRequested The maximum amount of short fees wanted.
/// @param shortReturnedRequested The maximum amount of short returned wanted.
struct TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam {
  uint256 strike;
  uint256 maturity;
  address long0FeesTo;
  address long1FeesTo;
  address shortFeesTo;
  address shortReturnedTo;
  uint256 long0FeesRequested;
  uint256 long1FeesRequested;
  uint256 shortFeesRequested;
  uint256 shortReturnedRequested;
}

/// @dev The parameter for mint function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param to The recipient of liquidity positions.
/// @param transaction The type of mint transaction, more information in Transaction module.
/// @param delta If transaction is GivenLiquidity, the amount of liquidity minted. Note that this value must be uint160.
/// If transaction is GivenLong, the amount of long position in base denomination to be deposited.
/// If transaction is GivenShort, the amount of short position to be deposited.
/// @param data The data to be sent to the function, which will go to the mint choice callback.
struct TimeswapV2PoolMintParam {
  uint256 strike;
  uint256 maturity;
  address to;
  TimeswapV2PoolMint transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for burn function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param shortTo The recipient of short positions.
/// @param transaction The type of burn transaction, more information in Transaction module.
/// @param delta If transaction is GivenLiquidity, the amount of liquidity burnt. Note that this value must be uint160.
/// If transaction is GivenLong, the amount of long position in base denomination to be withdrawn.
/// If transaction is GivenShort, the amount of short position to be withdrawn.
/// @param data The data to be sent to the function, which will go to the burn choice callback.
struct TimeswapV2PoolBurnParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  TimeswapV2PoolBurn transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for deleverage function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param to The recipient of short positions.
/// @param transaction The type of deleverage transaction, more information in Transaction module.
/// @param delta If transaction is GivenDeltaSqrtInterestRate, the decrease in square root interest rate.
/// If transaction is GivenLong, the amount of long position in base denomination to be deposited.
/// If transaction is GivenShort, the amount of short position to be withdrawn.
/// If transaction is  GivenSum, the sum amount of long position in base denomination to be deposited, and short position to be withdrawn.
/// @param data The data to be sent to the function, which will go to the deleverage choice callback.
struct TimeswapV2PoolDeleverageParam {
  uint256 strike;
  uint256 maturity;
  address to;
  TimeswapV2PoolDeleverage transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for leverage function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param transaction The type of leverage transaction, more information in Transaction module.
/// @param delta If transaction is GivenDeltaSqrtInterestRate, the increase in square root interest rate.
/// If transaction is GivenLong, the amount of long position in base denomination to be withdrawn.
/// If transaction is GivenShort, the amount of short position to be deposited.
/// If transaction is  GivenSum, the sum amount of long position in base denomination to be withdrawn, and short position to be deposited.
/// @param data The data to be sent to the function, which will go to the leverage choice callback.
struct TimeswapV2PoolLeverageParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  TimeswapV2PoolLeverage transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for rebalance function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param to When Long0ToLong1, the recipient of long1 positions.
/// When Long1ToLong0, the recipient of long0 positions.
/// @param isLong0ToLong1 Long0ToLong1 when true. Long1ToLong0 when false.
/// @param transaction The type of rebalance transaction, more information in Transaction module.
/// @param delta If transaction is GivenLong0 and Long0ToLong1, the amount of long0 positions to be deposited.
/// If transaction is GivenLong0 and Long1ToLong0, the amount of long1 positions to be withdrawn.
/// If transaction is GivenLong1 and Long0ToLong1, the amount of long1 positions to be withdrawn.
/// If transaction is GivenLong1 and Long1ToLong0, the amount of long1 positions to be deposited.
/// @param data The data to be sent to the function, which will go to the rebalance callback.
struct TimeswapV2PoolRebalanceParam {
  uint256 strike;
  uint256 maturity;
  address to;
  bool isLong0ToLong1;
  TimeswapV2PoolRebalance transaction;
  uint256 delta;
  bytes data;
}

library ParamLibrary {
  /// @dev Sanity checks
  /// @param param the parameter for collectProtocolFees transaction.
  function check(TimeswapV2PoolCollectProtocolFeesParam memory param) internal pure {
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if ((param.long0Requested == 0 && param.long1Requested == 0 && param.shortRequested == 0) || param.strike == 0)
      Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for collectTransactionFeesAndShortReturned transaction.
  function check(TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam memory param) internal pure {
    if (
      param.long0FeesTo == address(0) ||
      param.long1FeesTo == address(0) ||
      param.shortFeesTo == address(0) ||
      param.shortReturnedTo == address(0)
    ) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (
      (param.long0FeesRequested == 0 &&
        param.long1FeesRequested == 0 &&
        param.shortFeesRequested == 0 &&
        param.shortReturnedRequested == 0) || param.strike == 0
    ) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for mint transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolMintParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.to == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for burn transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolBurnParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();

    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for deleverage transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolDeleverageParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.to == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for leverage transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolLeverageParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.long0To == address(0) || param.long1To == address(0)) Error.zeroAddress();

    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for rebalance transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolRebalanceParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.to == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {SafeCast} from "@timeswap-labs/v2-library/contracts/SafeCast.sol";
import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";
import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";

import {ITimeswapV2Option} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2Option.sol";

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {StrikeConversion} from "@timeswap-labs/v2-library/contracts/StrikeConversion.sol";

import {DurationCalculation} from "../libraries/DurationCalculation.sol";
import {DurationWeight} from "../libraries/DurationWeight.sol";
import {ConstantProduct} from "../libraries/ConstantProduct.sol";
import {ConstantSum} from "../libraries/ConstantSum.sol";
import {FeeCalculation} from "../libraries/FeeCalculation.sol";

import {ITimeswapV2PoolMintCallback} from "../interfaces/callbacks/ITimeswapV2PoolMintCallback.sol";
import {ITimeswapV2PoolBurnCallback} from "../interfaces/callbacks/ITimeswapV2PoolBurnCallback.sol";
import {ITimeswapV2PoolDeleverageCallback} from "../interfaces/callbacks/ITimeswapV2PoolDeleverageCallback.sol";
import {ITimeswapV2PoolLeverageCallback} from "../interfaces/callbacks/ITimeswapV2PoolLeverageCallback.sol";

import {LiquidityPosition, LiquidityPositionLibrary} from "./LiquidityPosition.sol";

import {TimeswapV2PoolMint, TimeswapV2PoolBurn, TimeswapV2PoolDeleverage, TimeswapV2PoolLeverage, TimeswapV2PoolRebalance, TransactionLibrary} from "../enums/Transaction.sol";

import {TimeswapV2PoolCollectProtocolFeesParam, TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam, TimeswapV2PoolMintParam, TimeswapV2PoolBurnParam, TimeswapV2PoolDeleverageParam, TimeswapV2PoolLeverageParam, TimeswapV2PoolRebalanceParam} from "./Param.sol";
import {TimeswapV2PoolMintChoiceCallbackParam, TimeswapV2PoolBurnChoiceCallbackParam, TimeswapV2PoolDeleverageChoiceCallbackParam, TimeswapV2PoolLeverageChoiceCallbackParam} from "./CallbackParam.sol";

/// @param liquidity The current total liquidity of the pool. Follows UQ 112.48
/// @param lastTimestamp The last block timestamp the pool was interacted with.
/// @param sqrtInterestRate The current square root interest rate of the pool. Follows UQ16.144.
/// @param long0Balance The current amount of long0 positions in the pool.
/// @param long1Balance The current amount of long1 positions in the pool.
/// @param long0FeeGrowth The global long0 position fee growth the last time the pool was interacted with.
/// @param long1FeeGrowth The global long1 position fee growth the last time the pool was interacted with.
/// @param shortFeeGrowth The global short position fee growth the last time the pool was interacted with.
/// @param long0ProtocolFees The amount of long0 position protocol fees earned.
/// @param long1ProtocolFees The amount of long1 position protocol fees earned.
/// @param shortProtocolFees The amount of short position protocol fees earned.
/// @param liquidityPositions The mapping of liquidity positions owned by liquidity providers.
struct Pool {
  uint160 liquidity;
  uint96 lastTimestamp;
  uint160 sqrtInterestRate;
  uint256 long0Balance;
  uint256 long1Balance;
  uint256 long0FeeGrowth;
  uint256 long1FeeGrowth;
  uint256 shortFeeGrowth;
  uint256 shortReturnedGrowth;
  uint256 long0ProtocolFees;
  uint256 long1ProtocolFees;
  uint256 shortProtocolFees;
  mapping(address => LiquidityPosition) liquidityPositions;
}

/// @title library for pool core
/// @author Timeswap Labs
library PoolLibrary {
  using LiquidityPositionLibrary for LiquidityPosition;
  using Math for uint256;
  using SafeCast for uint256;

  /// @dev It calculates the global fee growth, which is fee increased per unit of liquidity token.
  /// @param pool The state of the pool.
  /// @return long0FeeGrowth The global fee increased per unit of liquidity token for long0.
  /// @return long1FeeGrowth The global fee increased per unit of liquidity token for long1.
  /// @return shortFeeGrowth The global fee increased per unit of liquidity token for short.
  /// @return shortReturnedGrowth The global short returned increased per unit of liquidity token for short returned.
  function feesEarnedAndShortReturnedGrowth(
    Pool storage pool,
    uint256 maturity,
    uint96 blockTimestamp
  )
    external
    view
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth)
  {
    long0FeeGrowth = pool.long0FeeGrowth;
    long1FeeGrowth = pool.long1FeeGrowth;
    shortFeeGrowth = pool.shortFeeGrowth;
    shortReturnedGrowth = pool.shortReturnedGrowth;

    if (pool.liquidity != 0) {
      if (maturity > blockTimestamp) {
        (, shortReturnedGrowth) = updateDurationWeight(
          pool.liquidity,
          pool.sqrtInterestRate,
          pool.shortReturnedGrowth,
          DurationCalculation.unsafeDurationFromLastTimestampToNow(pool.lastTimestamp, blockTimestamp),
          blockTimestamp
        );
      } else if (pool.lastTimestamp < maturity) {
        (, shortReturnedGrowth) = updateDurationWeight(
          pool.liquidity,
          pool.sqrtInterestRate,
          pool.shortReturnedGrowth,
          DurationCalculation.unsafeDurationFromLastTimestampToMaturity(pool.lastTimestamp, maturity),
          blockTimestamp
        );
      }
    }
  }

  /// @param pool The state of the pool.
  /// @param owner The address to query the fees earned of.
  /// @return long0Fees The amount of long0 fees owned by the given address.
  /// @return long1Fees The amount of long1 fees owned by the given address.
  /// @return shortFees The amount of short fees owned by the given address.
  /// @return shortReturned The amount of short returned owned by the given address.
  function feesEarnedAndShortReturnedOf(
    Pool storage pool,
    uint256 maturity,
    address owner,
    uint96 blockTimestamp
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned) {
    uint256 shortReturnedGrowth = pool.shortReturnedGrowth;
    if (pool.liquidity != 0) {
      if (maturity > blockTimestamp) {
        (, shortReturnedGrowth) = updateDurationWeight(
          pool.liquidity,
          pool.sqrtInterestRate,
          pool.shortReturnedGrowth,
          DurationCalculation.unsafeDurationFromLastTimestampToNow(pool.lastTimestamp, blockTimestamp),
          blockTimestamp
        );
      } else if (pool.lastTimestamp < maturity) {
        (, shortReturnedGrowth) = updateDurationWeight(
          pool.liquidity,
          pool.sqrtInterestRate,
          pool.shortReturnedGrowth,
          DurationCalculation.unsafeDurationFromLastTimestampToMaturity(pool.lastTimestamp, maturity),
          blockTimestamp
        );
      }
    }

    return
      pool.liquidityPositions[owner].feesEarnedAndShortReturnedOf(
        pool.long0FeeGrowth,
        pool.long1FeeGrowth,
        pool.shortFeeGrowth,
        shortReturnedGrowth
      );
  }

  /// @param pool The state of the pool.
  /// @return long0ProtocolFees The amount of long0 protocol fees owned by the owner of the factory contract.
  /// @return long1ProtocolFees The amount of long1 protocol fees owned by the owner of the factory contract.
  /// @return shortProtocolFees The amount of short protocol fees owned by the owner of the factory contract.
  function protocolFeesEarned(
    Pool storage pool
  ) external view returns (uint256 long0ProtocolFees, uint256 long1ProtocolFees, uint256 shortProtocolFees) {
    return (pool.long0ProtocolFees, pool.long1ProtocolFees, pool.shortProtocolFees);
  }

  /// @dev Returns the amount of long0 and long1 adjusted for the protocol and transaction fee.
  /// @param pool The state of the pool.
  /// @return long0Amount The amount of long0 in the pool, adjusted for the protocol and transaction fee.
  /// @return long1Amount The amount of long1 in the pool, adjusted for the protocol and transaction fee.
  function totalLongBalanceAdjustFees(
    Pool storage pool,
    uint256 transactionFee
  ) external view returns (uint256 long0Amount, uint256 long1Amount) {
    long0Amount = FeeCalculation.removeFees(pool.long0Balance, transactionFee);
    long1Amount = FeeCalculation.removeFees(pool.long1Balance, transactionFee);
  }

  /// @dev Returns the amount of sum of long0 and long1 converted to base denomination in the pool.
  /// @dev Returns the amount of short positions in the pool.
  /// @param pool The state of the pool.
  /// @return longAmount The amount of sum of long0 and long1 converted to base denomination in the pool.
  /// @return shortAmount The amount of short in the pool.
  function totalPositions(
    Pool storage pool,
    uint256 maturity,
    uint96 blockTimestamp
  ) external view returns (uint256 longAmount, uint256 shortAmount) {
    longAmount = ConstantProduct.getLong(pool.liquidity, pool.sqrtInterestRate, false);
    shortAmount = maturity > blockTimestamp
      ? ConstantProduct.getShort(
        pool.liquidity,
        pool.sqrtInterestRate,
        DurationCalculation.unsafeDurationFromNowToMaturity(maturity, blockTimestamp),
        false
      )
      : 0;
  }

  /// @dev Move short positions to short fee growth due to duration of the pool decreasing as time moves forward.
  /// @param liquidity The liquidity in the pool.
  /// @param rate The square root interest rate in the pool.
  /// @param shortReturnedGrowth The previous short returned growth from last transaction in the pool.
  /// @param duration The duration time of the pool.
  /// @param blockTimestamp The block timestamp.
  /// @return newLastTimestamp The new current last timestamp.
  /// @return newShortReturnedGrowth The newly updated short fee growth.
  function updateDurationWeight(
    uint160 liquidity,
    uint160 rate,
    uint256 shortReturnedGrowth,
    uint96 duration,
    uint96 blockTimestamp
  ) private pure returns (uint96 newLastTimestamp, uint256 newShortReturnedGrowth) {
    newLastTimestamp = blockTimestamp;
    newShortReturnedGrowth = DurationWeight.update(
      liquidity,
      shortReturnedGrowth,
      ConstantProduct.getShort(liquidity, rate, duration, false)
    );
  }

  /// @dev Move short positions to short fee growth due to duration of the pool decreasing as time moves forward when pool is before maturity.
  /// @param pool The state of the pool.
  /// @param blockTimestamp The block timestamp.
  function updateDurationWeightBeforeMaturity(Pool storage pool, uint96 blockTimestamp) private {
    if (pool.lastTimestamp < blockTimestamp)
      (pool.lastTimestamp, pool.shortReturnedGrowth) = updateDurationWeight(
        pool.liquidity,
        pool.sqrtInterestRate,
        pool.shortReturnedGrowth,
        DurationCalculation.unsafeDurationFromLastTimestampToNow(pool.lastTimestamp, blockTimestamp),
        blockTimestamp
      );
  }

  /// @dev Move short positions to short fee growth due to duration of the pool decreasing as time moves forward when pool is after maturity.
  /// @param pool The state of the pool.
  /// @param maturity The maturity of the pool
  /// @param blockTimestamp The block timestamp.
  function updateDurationWeightAfterMaturity(Pool storage pool, uint256 maturity, uint96 blockTimestamp) private {
    (pool.lastTimestamp, pool.shortReturnedGrowth) = updateDurationWeight(
      pool.liquidity,
      pool.sqrtInterestRate,
      pool.shortReturnedGrowth,
      DurationCalculation.unsafeDurationFromLastTimestampToMaturity(pool.lastTimestamp, maturity),
      blockTimestamp
    );
  }

  /// @dev Transfer liquidity positions to another address.
  /// @notice Does not transfer the transaction fees earned by the sender.
  /// @param pool The state of the pool.
  /// @param to The recipient of the liquidity positions.
  /// @param liquidityAmount The amount of liquidity positions transferred.
  /// @param blockTimestamp The current block timestamp.
  function transferLiquidity(
    Pool storage pool,
    uint256 maturity,
    address to,
    uint160 liquidityAmount,
    uint96 blockTimestamp
  ) external {
    // Update the state of the pool first for the short fee growth.
    if (pool.liquidity != 0) {
      if (maturity > blockTimestamp) updateDurationWeightBeforeMaturity(pool, blockTimestamp);
      else if (pool.lastTimestamp < maturity) updateDurationWeightAfterMaturity(pool, maturity, blockTimestamp);
    }

    // Update the fee growth and fees of msg.sender.
    LiquidityPosition storage liquidityPosition = pool.liquidityPositions[msg.sender];

    liquidityPosition.update(pool.long0FeeGrowth, pool.long1FeeGrowth, pool.shortFeeGrowth, pool.shortReturnedGrowth);
    liquidityPosition.burn(liquidityAmount);

    // Update the fee growth and fees of recipient.
    LiquidityPosition storage newLiquidityPosition = pool.liquidityPositions[to];

    newLiquidityPosition.update(
      pool.long0FeeGrowth,
      pool.long1FeeGrowth,
      pool.shortFeeGrowth,
      pool.shortReturnedGrowth
    );
    newLiquidityPosition.mint(liquidityAmount);
  }

  /// @dev initializes the pool with the given parameters.
  /// @param pool The state of the pool.
  /// @param rate The square root of the interest rate of the pool.
  function initialize(Pool storage pool, uint160 rate) external {
    if (pool.liquidity != 0) Error.alreadyHaveLiquidity(pool.liquidity);
    pool.sqrtInterestRate = rate;
  }

  /// @dev Collects the protocol fees of the pool.
  /// @dev only protocol owner can call this function.
  /// @dev if the owner enters an amount which is greater than the fee amount they have earned, withdraw only the amount they have.
  /// @param pool The state of the pool.
  /// @param long0Requested The maximum amount of long0 positions wanted.
  /// @param long1Requested The maximum amount of long1 positions wanted.
  /// @param shortRequested The maximum amount of short positions wanted.
  /// @return long0Amount The amount of long0 collected.
  /// @return long1Amount The amount of long1 collected.
  /// @return shortAmount The amount of short collected.
  function collectProtocolFees(
    Pool storage pool,
    uint256 long0Requested,
    uint256 long1Requested,
    uint256 shortRequested
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount) {
    if (long0Requested >= pool.long0ProtocolFees) {
      long0Amount = pool.long0ProtocolFees;
      pool.long0ProtocolFees = 0;
    } else {
      long0Amount = long0Requested;
      pool.long0ProtocolFees = pool.long0ProtocolFees.unsafeSub(long0Requested);
    }

    if (long1Requested >= pool.long1ProtocolFees) {
      long1Amount = pool.long1ProtocolFees;
      pool.long1ProtocolFees = 0;
    } else {
      long1Amount = long1Requested;
      pool.long1ProtocolFees = pool.long1ProtocolFees.unsafeSub(long1Requested);
    }

    if (shortRequested >= pool.shortProtocolFees) {
      shortAmount = pool.shortProtocolFees;
      pool.shortProtocolFees = 0;
    } else {
      shortAmount = shortRequested;
      pool.shortProtocolFees = pool.shortProtocolFees.unsafeSub(shortRequested);
    }
  }

  /// @dev Collects the transaction fees and short returned of the pool.
  /// @dev only liquidity provider can call this function.
  /// @dev if the owner enters an amount which is greater than the fee amount they have earned, withdraw only the amount they have.
  /// @param pool The state of the pool.
  /// @param maturity The maturity of the pool.
  /// @param long0FeesRequested The maximum amount of long0 fees wanted.
  /// @param long1FeesRequested The maximum amount of long1 fees wanted.
  /// @param shortFeesRequested The maximum amount of short fees wanted.
  /// @param shortReturnedRequested The maximum amount of short returned wanted.
  /// @param blockTimestamp The current blockTimestamp
  /// @return long0Fees The amount of long0 fees collected.
  /// @return long1Fees The amount of long1 fees collected.
  /// @return shortFees The amount of short fees collected.
  /// @return shortReturned The amount of short returned collected.
  function collectTransactionFeesAndShortReturned(
    Pool storage pool,
    uint256 maturity,
    uint256 long0FeesRequested,
    uint256 long1FeesRequested,
    uint256 shortFeesRequested,
    uint256 shortReturnedRequested,
    uint96 blockTimestamp
  ) external returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned) {
    // Update the state of the pool first for the short fee growth.
    if (pool.liquidity != 0) {
      if (maturity > blockTimestamp) updateDurationWeightBeforeMaturity(pool, blockTimestamp);
      else if (pool.lastTimestamp < maturity) updateDurationWeightAfterMaturity(pool, maturity, blockTimestamp);
    }

    LiquidityPosition storage liquidityPosition = pool.liquidityPositions[msg.sender];

    if (pool.liquidity != 0)
      liquidityPosition.update(pool.long0FeeGrowth, pool.long1FeeGrowth, pool.shortFeeGrowth, pool.shortReturnedGrowth);

    (long0Fees, long1Fees, shortFees, shortReturned) = liquidityPosition.collectTransactionFeesAndShortReturned(
      long0FeesRequested,
      long1FeesRequested,
      shortFeesRequested,
      shortReturnedRequested
    );
  }

  /// @dev deposit Short and Long tokens and mints Liquidity
  /// @dev can be only called before the maturity.
  /// @param pool The state of the pool.
  /// @param param it is a struct that contains the parameters of the mint function.
  /// @param blockTimestamp The current block timestamp.
  /// @return liquidityAmount The amount of liquidity minted.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function mint(
    Pool storage pool,
    TimeswapV2PoolMintParam memory param,
    uint96 blockTimestamp
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data)
  {
    // Update the state of the pool first for the short fee growth.
    if (pool.liquidity == 0) pool.lastTimestamp = blockTimestamp;
    else updateDurationWeightBeforeMaturity(pool, blockTimestamp);
    // Update the fee growth and fees of caller.
    LiquidityPosition storage liquidityPosition = pool.liquidityPositions[param.to];

    liquidityPosition.update(pool.long0FeeGrowth, pool.long1FeeGrowth, pool.shortFeeGrowth, pool.shortReturnedGrowth);

    uint256 longAmount;
    if (param.transaction == TimeswapV2PoolMint.GivenLiquidity) {
      (longAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityDelta(
        pool.sqrtInterestRate,
        liquidityAmount = param.delta.toUint160(),
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        true
      );

      if (longAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolMint.GivenLong) {
      (liquidityAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityLong(
        pool.sqrtInterestRate,
        longAmount = param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        true
      );

      if (liquidityAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolMint.GivenShort) {
      (liquidityAmount, longAmount) = ConstantProduct.calculateGivenLiquidityShort(
        pool.sqrtInterestRate,
        shortAmount = param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        true
      );

      if (liquidityAmount == 0) Error.zeroOutput();
      if (longAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolMint.GivenLarger) {
      (liquidityAmount, longAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityLargerOrSmaller(
        pool.sqrtInterestRate,
        param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        true
      );

      if (liquidityAmount == 0) Error.zeroOutput();
      if (longAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    }

    // Ask the msg.sender how much long0 position and long1 position wanted.
    (long0Amount, long1Amount, data) = ITimeswapV2PoolMintCallback(msg.sender).timeswapV2PoolMintChoiceCallback(
      TimeswapV2PoolMintChoiceCallbackParam({
        strike: param.strike,
        maturity: param.maturity,
        longAmount: longAmount,
        shortAmount: shortAmount,
        liquidityAmount: liquidityAmount,
        data: param.data
      })
    );
    Error.checkEnough(StrikeConversion.combine(long0Amount, long1Amount, param.strike, false), longAmount);

    if (long0Amount != 0) pool.long0Balance += long0Amount;
    if (long1Amount != 0) pool.long1Balance += long1Amount;

    liquidityPosition.mint(liquidityAmount);
    pool.liquidity += liquidityAmount;
  }

  /// @dev burn Liquidity and receive Short and Long tokens
  /// @dev can be only called before the maturity.
  /// @dev after the maturity of the pool, the long0 and long1 tokens are zero. And the short tokens are added into the transaction fees.
  /// @dev if the user wants to burn the liquidity after the maturity, they should call the collectTransactionFee function.
  /// @param pool The state of the pool.
  /// @param param it is a struct that contains the parameters of the burn function.
  /// @param blockTimestamp The current block timestamp.
  /// @return liquidityAmount The amount of liquidity burned.
  /// @return long0Amount The amount of long0 withdrawn.
  /// @return long1Amount The amount of long1 withdrawn.
  /// @return shortAmount The amount of short withdrawn.
  /// @return data the data used for the callbacks.
  function burn(
    Pool storage pool,
    TimeswapV2PoolBurnParam memory param,
    uint96 blockTimestamp
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data)
  {
    if (pool.liquidity == 0) Error.requireLiquidity();

    // Update the state of the pool first for the short fee growth.
    updateDurationWeightBeforeMaturity(pool, blockTimestamp);

    LiquidityPosition storage liquidityPosition = pool.liquidityPositions[msg.sender];

    liquidityPosition.update(pool.long0FeeGrowth, pool.long1FeeGrowth, pool.shortFeeGrowth, pool.shortReturnedGrowth);

    uint256 longAmount;
    if (param.transaction == TimeswapV2PoolBurn.GivenLiquidity) {
      (longAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityDelta(
        pool.sqrtInterestRate,
        liquidityAmount = param.delta.toUint160(),
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        false
      );

      if (longAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolBurn.GivenLong) {
      (liquidityAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityLong(
        pool.sqrtInterestRate,
        longAmount = param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        false
      );

      if (liquidityAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolBurn.GivenShort) {
      (liquidityAmount, longAmount) = ConstantProduct.calculateGivenLiquidityShort(
        pool.sqrtInterestRate,
        shortAmount = param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        false
      );

      if (liquidityAmount == 0) Error.zeroOutput();
      if (longAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolBurn.GivenSmaller) {
      (liquidityAmount, longAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityLargerOrSmaller(
        pool.sqrtInterestRate,
        param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        false
      );

      if (liquidityAmount == 0) Error.zeroOutput();
      if (longAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    }

    (long0Amount, long1Amount, data) = ITimeswapV2PoolBurnCallback(msg.sender).timeswapV2PoolBurnChoiceCallback(
      TimeswapV2PoolBurnChoiceCallbackParam({
        strike: param.strike,
        maturity: param.maturity,
        long0Balance: pool.long0Balance,
        long1Balance: pool.long1Balance,
        longAmount: longAmount,
        shortAmount: shortAmount,
        liquidityAmount: liquidityAmount,
        data: param.data
      })
    );

    Error.checkEnough(longAmount, StrikeConversion.combine(long0Amount, long1Amount, param.strike, true));

    if (long0Amount != 0) pool.long0Balance -= long0Amount;
    if (long1Amount != 0) pool.long1Balance -= long1Amount;

    pool.liquidity -= liquidityAmount;
  }

  /// @dev deposit Long tokens and receive Short tokens
  /// @dev can be only called before the maturity.
  /// @param pool The state of the pool.
  /// @param param it is a struct that contains the parameters of the deleverage function
  /// @param transactionFee The transaction fee rate.
  /// @param protocolFee The protocol fee rate.
  /// @param blockTimestamp The current block timestamp.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short received.
  /// @return data the data used for the callbacks.
  function deleverage(
    Pool storage pool,
    TimeswapV2PoolDeleverageParam memory param,
    uint256 transactionFee,
    uint256 protocolFee,
    uint96 blockTimestamp
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data) {
    if (pool.liquidity == 0) Error.requireLiquidity();
    // Update the state of the pool first for the short fee growth.
    updateDurationWeightBeforeMaturity(pool, blockTimestamp);

    uint256 longAmount;
    uint256 shortFees;
    if (param.transaction == TimeswapV2PoolDeleverage.GivenDeltaSqrtInterestRate) {
      (pool.sqrtInterestRate, longAmount, shortAmount, shortFees) = ConstantProduct.updateGivenSqrtInterestRateDelta(
        pool.liquidity,
        pool.sqrtInterestRate,
        param.delta.toUint160(),
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        transactionFee,
        false
      );

      if (longAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolDeleverage.GivenLong) {
      (pool.sqrtInterestRate, shortAmount, shortFees) = ConstantProduct.updateGivenLong(
        pool.liquidity,
        pool.sqrtInterestRate,
        longAmount = param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        transactionFee,
        true
      );

      if (shortAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolDeleverage.GivenShort) {
      (pool.sqrtInterestRate, longAmount, shortFees) = ConstantProduct.updateGivenShort(
        pool.liquidity,
        pool.sqrtInterestRate,
        shortAmount = param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        transactionFee,
        false
      );

      if (longAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolDeleverage.GivenSum) {
      (pool.sqrtInterestRate, longAmount, shortAmount, shortFees) = ConstantProduct.updateGivenSumLong(
        pool.liquidity,
        pool.sqrtInterestRate,
        param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        transactionFee,
        true
      );

      if (longAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    }

    (pool.shortFeeGrowth, pool.shortProtocolFees) = FeeCalculation.update(
      TimeswapV2OptionPosition.Short,
      pool.liquidity,
      pool.shortFeeGrowth,
      pool.shortProtocolFees,
      shortFees,
      protocolFee
    );

    (long0Amount, long1Amount, data) = ITimeswapV2PoolDeleverageCallback(msg.sender)
      .timeswapV2PoolDeleverageChoiceCallback(
        TimeswapV2PoolDeleverageChoiceCallbackParam({
          strike: param.strike,
          maturity: param.maturity,
          longAmount: longAmount,
          shortAmount: shortAmount,
          data: param.data
        })
      );
    Error.checkEnough(StrikeConversion.combine(long0Amount, long1Amount, param.strike, false), longAmount);

    if (long0Amount != 0) pool.long0Balance += long0Amount;
    if (long1Amount != 0) pool.long1Balance += long1Amount;
  }

  /// @dev deposit Short tokens and receive Long tokens
  /// @dev can be only called before the maturity.
  /// @param pool The state of the pool.
  /// @param param it is a struct that contains the parameters of the leverage function.
  /// @param transactionFee The transaction fee rate.
  /// @param protocolFee The protocol fee rate.
  /// @param blockTimestamp The current block timestamp.
  /// @return long0Amount The amount of long0 received.
  /// @return long1Amount The amount of long1 received.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function leverage(
    Pool storage pool,
    TimeswapV2PoolLeverageParam memory param,
    uint256 transactionFee,
    uint256 protocolFee,
    uint96 blockTimestamp
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data) {
    if (pool.liquidity == 0) Error.requireLiquidity();

    // Update the state of the pool first for the short fee growth.
    updateDurationWeightBeforeMaturity(pool, blockTimestamp);

    uint256 long0BalanceAdjustFees = FeeCalculation.removeFees(pool.long0Balance, transactionFee);
    uint256 long1BalanceAdjustFees = FeeCalculation.removeFees(pool.long1Balance, transactionFee);
    {
      uint256 longAmount;
      if (param.transaction == TimeswapV2PoolLeverage.GivenDeltaSqrtInterestRate) {
        (pool.sqrtInterestRate, longAmount, shortAmount, ) = ConstantProduct.updateGivenSqrtInterestRateDelta(
          pool.liquidity,
          pool.sqrtInterestRate,
          param.delta.toUint160(),
          DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
          transactionFee,
          true
        );

        if (longAmount == 0) Error.zeroOutput();
        if (shortAmount == 0) Error.zeroOutput();
      } else if (param.transaction == TimeswapV2PoolLeverage.GivenLong) {
        (pool.sqrtInterestRate, shortAmount, ) = ConstantProduct.updateGivenLong(
          pool.liquidity,
          pool.sqrtInterestRate,
          longAmount = param.delta,
          DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
          transactionFee,
          false
        );

        if (shortAmount == 0) Error.zeroOutput();
      } else if (param.transaction == TimeswapV2PoolLeverage.GivenShort) {
        (pool.sqrtInterestRate, longAmount, ) = ConstantProduct.updateGivenShort(
          pool.liquidity,
          pool.sqrtInterestRate,
          shortAmount = param.delta,
          DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
          transactionFee,
          true
        );

        if (longAmount == 0) Error.zeroOutput();
      } else if (param.transaction == TimeswapV2PoolLeverage.GivenSum) {
        (pool.sqrtInterestRate, longAmount, shortAmount, ) = ConstantProduct.updateGivenSumLong(
          pool.liquidity,
          pool.sqrtInterestRate,
          param.delta,
          DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
          transactionFee,
          false
        );
        if (longAmount == 0) Error.zeroOutput();
        if (shortAmount == 0) Error.zeroOutput();
      }

      (long0Amount, long1Amount, data) = ITimeswapV2PoolLeverageCallback(msg.sender)
        .timeswapV2PoolLeverageChoiceCallback(
          TimeswapV2PoolLeverageChoiceCallbackParam({
            strike: param.strike,
            maturity: param.maturity,
            long0Balance: long0BalanceAdjustFees,
            long1Balance: long1BalanceAdjustFees,
            longAmount: longAmount,
            shortAmount: shortAmount,
            data: param.data
          })
        );
      Error.checkEnough(longAmount, StrikeConversion.combine(long0Amount, long1Amount, param.strike, true));
    }

    if (long0Amount != 0) {
      uint256 long0Fees;
      if (long0Amount == long0BalanceAdjustFees) {
        long0Fees = pool.long0Balance.unsafeSub(long0Amount);
        pool.long0Balance = 0;
      } else {
        long0Fees = FeeCalculation.getFeesAdditional(long0Amount, transactionFee);
        pool.long0Balance -= (long0Amount + long0Fees);
      }

      (pool.long0FeeGrowth, pool.long0ProtocolFees) = FeeCalculation.update(
        TimeswapV2OptionPosition.Long0,
        pool.liquidity,
        pool.long0FeeGrowth,
        pool.long0ProtocolFees,
        long0Fees,
        protocolFee
      );
    }

    if (long1Amount != 0) {
      uint256 long1Fees;
      if (long1Amount == long1BalanceAdjustFees) {
        long1Fees = pool.long1Balance.unsafeSub(long1Amount);
        pool.long1Balance = 0;
      } else {
        long1Fees = FeeCalculation.getFeesAdditional(long1Amount, transactionFee);

        pool.long1Balance -= (long1Amount + long1Fees);
      }

      (pool.long1FeeGrowth, pool.long1ProtocolFees) = FeeCalculation.update(
        TimeswapV2OptionPosition.Long1,
        pool.liquidity,
        pool.long1FeeGrowth,
        pool.long1ProtocolFees,
        long1Fees,
        protocolFee
      );
    }
  }

  /// @dev Deposit Long0 to receive Long1 or deposit Long1 to receive Long0.
  /// @dev can be only called before the maturity.
  /// @param pool The state of the pool.
  /// @param param it is a struct that contains the parameters of the rebalance function.
  /// @param transactionFee The transaction fee rate.
  /// @param protocolFee The protocol fee rate.
  /// @return long0Amount The amount of long0 received/deposited.
  /// @return long1Amount The amount of long1 deposited/received.
  function rebalance(
    Pool storage pool,
    TimeswapV2PoolRebalanceParam memory param,
    uint256 transactionFee,
    uint256 protocolFee
  ) external returns (uint256 long0Amount, uint256 long1Amount) {
    if (pool.liquidity == 0) Error.requireLiquidity();

    // No need to update short returned growth.

    uint256 longFees;
    if (param.isLong0ToLong1) {
      if (param.transaction == TimeswapV2PoolRebalance.GivenLong0) {
        (long1Amount, longFees) = ConstantSum.calculateGivenLongIn(
          param.strike,
          long0Amount = param.delta,
          transactionFee,
          true
        );

        if (long1Amount == 0) Error.zeroOutput();

        pool.long1Balance -= (long1Amount + longFees);
      } else if (param.transaction == TimeswapV2PoolRebalance.GivenLong1) {
        uint256 long1AmountAdjustFees = FeeCalculation.removeFees(pool.long1Balance, transactionFee);

        if ((long1Amount = param.delta) == long1AmountAdjustFees) {
          long0Amount = ConstantSum.calculateGivenLongOutAlreadyAdjustFees(param.strike, pool.long1Balance, true);

          longFees = pool.long1Balance.unsafeSub(long1Amount);
          pool.long1Balance = 0;
        } else {
          (long0Amount, longFees) = ConstantSum.calculateGivenLongOut(param.strike, long1Amount, transactionFee, true);

          pool.long1Balance -= (long1Amount + longFees);
        }

        if (long0Amount == 0) Error.zeroOutput();
      }

      pool.long0Balance += long0Amount;

      (pool.long1FeeGrowth, pool.long1ProtocolFees) = FeeCalculation.update(
        TimeswapV2OptionPosition.Long1,
        pool.liquidity,
        pool.long1FeeGrowth,
        pool.long1ProtocolFees,
        longFees,
        protocolFee
      );
    } else {
      if (param.transaction == TimeswapV2PoolRebalance.GivenLong0) {
        uint256 long0AmountAdjustFees = FeeCalculation.removeFees(pool.long0Balance, transactionFee);

        if ((long0Amount = param.delta) == long0AmountAdjustFees) {
          long1Amount = ConstantSum.calculateGivenLongOutAlreadyAdjustFees(param.strike, pool.long0Balance, false);

          longFees = pool.long0Balance.unsafeSub(long0Amount);
          pool.long0Balance = 0;
        } else {
          (long1Amount, longFees) = ConstantSum.calculateGivenLongOut(param.strike, long0Amount, transactionFee, false);

          pool.long0Balance -= (long0Amount + longFees);
        }

        if (long1Amount == 0) Error.zeroOutput();
      } else if (param.transaction == TimeswapV2PoolRebalance.GivenLong1) {
        (long0Amount, longFees) = ConstantSum.calculateGivenLongIn(
          param.strike,
          long1Amount = param.delta,
          transactionFee,
          false
        );

        if (long0Amount == 0) Error.zeroOutput();

        pool.long0Balance -= (long0Amount + longFees);
      }

      pool.long1Balance += long1Amount;

      (pool.long0FeeGrowth, pool.long0ProtocolFees) = FeeCalculation.update(
        TimeswapV2OptionPosition.Long0,
        pool.liquidity,
        pool.long0FeeGrowth,
        pool.long0ProtocolFees,
        longFees,
        protocolFee
      );
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Ownership} from "@timeswap-labs/v2-library/contracts/Ownership.sol";

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {ITimeswapV2Option} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2Option.sol";

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {StrikeAndMaturity} from "@timeswap-labs/v2-option/contracts/structs/StrikeAndMaturity.sol";

import {NoDelegateCall} from "./NoDelegateCall.sol";

import {ITimeswapV2Pool} from "./interfaces/ITimeswapV2Pool.sol";
import {ITimeswapV2PoolFactory} from "./interfaces/ITimeswapV2PoolFactory.sol";
import {ITimeswapV2PoolDeployer} from "./interfaces/ITimeswapV2PoolDeployer.sol";

import {ITimeswapV2PoolMintCallback} from "./interfaces/callbacks/ITimeswapV2PoolMintCallback.sol";
import {ITimeswapV2PoolBurnCallback} from "./interfaces/callbacks/ITimeswapV2PoolBurnCallback.sol";
import {ITimeswapV2PoolDeleverageCallback} from "./interfaces/callbacks/ITimeswapV2PoolDeleverageCallback.sol";
import {ITimeswapV2PoolLeverageCallback} from "./interfaces/callbacks/ITimeswapV2PoolLeverageCallback.sol";
import {ITimeswapV2PoolRebalanceCallback} from "./interfaces/callbacks/ITimeswapV2PoolRebalanceCallback.sol";

import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";

import {LiquidityPosition, LiquidityPositionLibrary} from "./structs/LiquidityPosition.sol";

import {Pool, PoolLibrary} from "./structs/Pool.sol";
import {TimeswapV2PoolCollectProtocolFeesParam, TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam, TimeswapV2PoolMintParam, TimeswapV2PoolBurnParam, TimeswapV2PoolDeleverageParam, TimeswapV2PoolLeverageParam, TimeswapV2PoolRebalanceParam, ParamLibrary} from "./structs/Param.sol";
import {TimeswapV2PoolMintChoiceCallbackParam, TimeswapV2PoolMintCallbackParam, TimeswapV2PoolBurnChoiceCallbackParam, TimeswapV2PoolBurnCallbackParam, TimeswapV2PoolDeleverageChoiceCallbackParam, TimeswapV2PoolDeleverageCallbackParam, TimeswapV2PoolLeverageCallbackParam, TimeswapV2PoolLeverageChoiceCallbackParam, TimeswapV2PoolRebalanceCallbackParam} from "./structs/CallbackParam.sol";

import {TimeswapV2PoolMint, TimeswapV2PoolBurn, TimeswapV2PoolDeleverage, TimeswapV2PoolLeverage, TimeswapV2PoolRebalance, TransactionLibrary} from "./enums/Transaction.sol";

/// @title Contract for TimeswapV2Pool
/// @author Timeswap Labs
contract TimeswapV2Pool is ITimeswapV2Pool, NoDelegateCall {
  using PoolLibrary for Pool;
  using Ownership for address;
  using LiquidityPositionLibrary for LiquidityPosition;

  /* ===== MODEL ===== */

  /// @inheritdoc ITimeswapV2Pool
  address public immutable override poolFactory;
  /// @inheritdoc ITimeswapV2Pool
  address public immutable override optionPair;
  /// @inheritdoc ITimeswapV2Pool
  uint256 public immutable override transactionFee;
  /// @inheritdoc ITimeswapV2Pool
  uint256 public immutable override protocolFee;

  mapping(uint256 => mapping(uint256 => uint96)) private reentrancyGuards;
  mapping(uint256 => mapping(uint256 => Pool)) private pools;

  StrikeAndMaturity[] private listOfPools;

  function addPoolEnumerationIfNecessary(uint256 strike, uint256 maturity) private {
    if (reentrancyGuards[strike][maturity] == ReentrancyGuard.NOT_INTERACTED) {
      reentrancyGuards[strike][maturity] = ReentrancyGuard.NOT_ENTERED;
      listOfPools.push(StrikeAndMaturity({strike: strike, maturity: maturity}));
    }
  }

  /* ===== MODIFIER ===== */
  /// @dev function to raise the reentrancy guard
  /// @param strike the strike amount
  /// @param maturity the maturity timestamp
  function raiseGuard(uint256 strike, uint256 maturity) private {
    ReentrancyGuard.check(reentrancyGuards[strike][maturity]);
    reentrancyGuards[strike][maturity] = ReentrancyGuard.ENTERED;
  }

  /// @dev function to lower the reentrancy guard
  /// @param strike the strike amount
  /// @param maturity the maturity timestamp
  function lowerGuard(uint256 strike, uint256 maturity) private {
    reentrancyGuards[strike][maturity] = ReentrancyGuard.NOT_ENTERED;
  }

  /* ===== INIT ===== */
  /// @dev constructor for the contract
  constructor() NoDelegateCall() {
    (poolFactory, optionPair, transactionFee, protocolFee) = ITimeswapV2PoolDeployer(msg.sender).parameter();
  }

  // Can be overidden for testing purposes.
  /// @dev for advancing the duration
  /// @param durationForward the durationForward seconds
  function blockTimestamp(uint96 durationForward) internal view virtual returns (uint96) {
    return uint96(block.timestamp + durationForward); // truncation is desired
  }

  function hasLiquidity(uint256 strike, uint256 maturity) private view {
    if (pools[strike][maturity].liquidity == 0) Error.requireLiquidity();
  }

  /* ===== VIEW ===== */

  /// @inheritdoc ITimeswapV2Pool
  function getByIndex(uint256 id) external view override returns (StrikeAndMaturity memory) {
    return listOfPools[id];
  }

  /// @inheritdoc ITimeswapV2Pool
  function numberOfPools() external view override returns (uint256) {
    return listOfPools.length;
  }

  /// @inheritdoc ITimeswapV2Pool
  function totalLiquidity(uint256 strike, uint256 maturity) external view override returns (uint160) {
    return pools[strike][maturity].liquidity;
  }

  /// @inheritdoc ITimeswapV2Pool
  function sqrtInterestRate(uint256 strike, uint256 maturity) external view override returns (uint160) {
    return pools[strike][maturity].sqrtInterestRate;
  }

  /// @inheritdoc ITimeswapV2Pool
  function liquidityOf(uint256 strike, uint256 maturity, address owner) external view override returns (uint160) {
    return pools[strike][maturity].liquidityPositions[owner].liquidity;
  }

  /// @inheritdoc ITimeswapV2Pool
  function feesEarnedAndShortReturnedGrowth(
    uint256 strike,
    uint256 maturity
  )
    external
    view
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth)
  {
    return pools[strike][maturity].feesEarnedAndShortReturnedGrowth(maturity, blockTimestamp(0));
  }

  /// @inheritdoc ITimeswapV2Pool
  function feesEarnedAndShortReturnedGrowth(
    uint256 strike,
    uint256 maturity,
    uint96 durationForward
  )
    external
    view
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth)
  {
    return pools[strike][maturity].feesEarnedAndShortReturnedGrowth(maturity, blockTimestamp(durationForward));
  }

  /// @inheritdoc ITimeswapV2Pool
  function feesEarnedAndShortReturnedOf(
    uint256 strike,
    uint256 maturity,
    address owner
  ) external view override returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned) {
    return pools[strike][maturity].feesEarnedAndShortReturnedOf(maturity, owner, blockTimestamp(0));
  }

  /// @inheritdoc ITimeswapV2Pool
  function feesEarnedAndShortReturnedOf(
    uint256 strike,
    uint256 maturity,
    address owner,
    uint96 durationForward
  ) external view override returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned) {
    return pools[strike][maturity].feesEarnedAndShortReturnedOf(maturity, owner, blockTimestamp(durationForward));
  }

  /// @inheritdoc ITimeswapV2Pool
  function protocolFeesEarned(
    uint256 strike,
    uint256 maturity
  ) external view override returns (uint256 long0ProtocolFees, uint256 long1ProtocolFees, uint256 shortProtocolFees) {
    return pools[strike][maturity].protocolFeesEarned();
  }

  /// @inheritdoc ITimeswapV2Pool
  function totalLongBalance(
    uint256 strike,
    uint256 maturity
  ) external view override returns (uint256 long0Amount, uint256 long1Amount) {
    Pool storage pool = pools[strike][maturity];
    long0Amount = pool.long0Balance;
    long1Amount = pool.long1Balance;
  }

  /// @inheritdoc ITimeswapV2Pool
  function totalLongBalanceAdjustFees(
    uint256 strike,
    uint256 maturity
  ) external view override returns (uint256 long0Amount, uint256 long1Amount) {
    (long0Amount, long1Amount) = pools[strike][maturity].totalLongBalanceAdjustFees(transactionFee);
  }

  /// @inheritdoc ITimeswapV2Pool
  function totalPositions(
    uint256 strike,
    uint256 maturity
  ) external view override returns (uint256 longAmount, uint256 shortAmount) {
    (longAmount, shortAmount) = pools[strike][maturity].totalPositions(maturity, blockTimestamp(0));
  }

  /* ===== UPDATE ===== */

  /// @inheritdoc ITimeswapV2Pool
  function transferLiquidity(uint256 strike, uint256 maturity, address to, uint160 liquidityAmount) external override {
    hasLiquidity(strike, maturity);

    if (blockTimestamp(0) > maturity) Error.alreadyMatured(maturity, blockTimestamp(0));
    if (to == address(0)) Error.zeroAddress();
    if (liquidityAmount == 0) Error.zeroInput();

    pools[strike][maturity].transferLiquidity(maturity, to, liquidityAmount, blockTimestamp(0));

    emit TransferLiquidity(strike, maturity, msg.sender, to, liquidityAmount);
  }

  /// @inheritdoc ITimeswapV2Pool
  function initialize(uint256 strike, uint256 maturity, uint160 rate) external override noDelegateCall {
    if (strike == 0) Error.cannotBeZero();
    if (maturity < blockTimestamp(0)) Error.alreadyMatured(maturity, blockTimestamp(0));
    if (rate == 0) Error.cannotBeZero();
    addPoolEnumerationIfNecessary(strike, maturity);

    pools[strike][maturity].initialize(rate);
  }

  /// @inheritdoc ITimeswapV2Pool
  function collectProtocolFees(
    TimeswapV2PoolCollectProtocolFeesParam calldata param
  ) external override noDelegateCall returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount) {
    ParamLibrary.check(param);
    raiseGuard(param.strike, param.maturity);

    // Can only be called by the TimeswapV2Pool factory owner.
    ITimeswapV2PoolFactory(poolFactory).owner().checkIfOwner();

    // Calculate the main logic of protocol fee.
    (long0Amount, long1Amount, shortAmount) = pools[param.strike][param.maturity].collectProtocolFees(
      param.long0Requested,
      param.long1Requested,
      param.shortRequested
    );

    collect(
      param.strike,
      param.maturity,
      param.long0To,
      param.long1To,
      param.shortTo,
      long0Amount,
      long1Amount,
      shortAmount
    );

    lowerGuard(param.strike, param.maturity);

    emit CollectProtocolFees(
      param.strike,
      param.maturity,
      msg.sender,
      param.long0To,
      param.long1To,
      param.shortTo,
      long0Amount,
      long1Amount,
      shortAmount
    );
  }

  /// @inheritdoc ITimeswapV2Pool
  function collectTransactionFeesAndShortReturned(
    TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam calldata param
  )
    external
    override
    noDelegateCall
    returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned)
  {
    ParamLibrary.check(param);
    raiseGuard(param.strike, param.maturity);

    // Calculate the main logic of transaction fee.
    (long0Fees, long1Fees, shortFees, shortReturned) = pools[param.strike][param.maturity]
      .collectTransactionFeesAndShortReturned(
        param.maturity,
        param.long0FeesRequested,
        param.long1FeesRequested,
        param.shortFeesRequested,
        param.shortReturnedRequested,
        blockTimestamp(0)
      );

    collect(
      param.strike,
      param.maturity,
      param.long0FeesTo,
      param.long1FeesTo,
      param.shortFeesTo,
      long0Fees,
      long1Fees,
      shortFees
    );

    if (shortReturned != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        param.strike,
        param.maturity,
        param.shortReturnedTo,
        TimeswapV2OptionPosition.Short,
        shortReturned
      );

    lowerGuard(param.strike, param.maturity);

    emit CollectTransactionFeesAndShortReturned(
      param.strike,
      param.maturity,
      msg.sender,
      param.long0FeesTo,
      param.long1FeesTo,
      param.shortFeesTo,
      param.shortReturnedTo,
      long0Fees,
      long1Fees,
      shortFees,
      shortReturned
    );
  }

  /// @dev Transfer long0 positions, long1 positions, and/or short positions to the recipients.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param long0To The recipient of long0 positions.
  /// @param long1To The recipient of long1 positions.
  /// @param shortTo The recipient of short positions.
  /// @param long0Amount The amount of long0 positions wanted.
  /// @param long1Amount The amount of long1 positions wanted.
  /// @param shortAmount The amount of short positions wanted.
  function collect(
    uint256 strike,
    uint256 maturity,
    address long0To,
    address long1To,
    address shortTo,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  ) private {
    if (long0Amount != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        strike,
        maturity,
        long0To,
        TimeswapV2OptionPosition.Long0,
        long0Amount
      );

    if (long1Amount != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        strike,
        maturity,
        long1To,
        TimeswapV2OptionPosition.Long1,
        long1Amount
      );

    if (shortAmount != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        strike,
        maturity,
        shortTo,
        TimeswapV2OptionPosition.Short,
        shortAmount
      );
  }

  /// @inheritdoc ITimeswapV2Pool
  function mint(
    TimeswapV2PoolMintParam calldata param
  )
    external
    override
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data)
  {
    return mint(param, false, 0);
  }

  /// @inheritdoc ITimeswapV2Pool
  function mint(
    TimeswapV2PoolMintParam calldata param,
    uint96 durationForward
  )
    external
    override
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data)
  {
    return mint(param, true, durationForward);
  }

  /// @dev deposit Short and Long tokens and mints Liquidity
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the mint function.
  /// @param durationForward The duration of time moved forward.
  /// @param isQuote Whether used for quoting purposes
  /// @return liquidityAmount The amount of liquidity minted.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function mint(
    TimeswapV2PoolMintParam calldata param,
    bool isQuote,
    uint96 durationForward
  )
    private
    noDelegateCall
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data)
  {
    ParamLibrary.check(param, blockTimestamp(durationForward));
    raiseGuard(param.strike, param.maturity);

    // Calculate the main logic of mint function.
    (liquidityAmount, long0Amount, long1Amount, shortAmount, data) = pools[param.strike][param.maturity].mint(
      param,
      blockTimestamp(durationForward)
    );

    // Calculate the amount of long0 position, long1 position, and short position required by the pool.

    // long0Amount chosen could be zero. Skip the calculation for gas efficiency.
    uint256 long0BalanceTarget;
    if (long0Amount != 0)
      long0BalanceTarget =
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Long0
        ) +
        long0Amount;

    // long1Amount chosen could be zero. Skip the calculation for gas efficiency.
    uint256 long1BalanceTarget;
    if (long1Amount != 0)
      long1BalanceTarget =
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Long1
        ) +
        long1Amount;

    // shortAmount cannot be zero.
    uint256 shortBalanceTarget = ITimeswapV2Option(optionPair).positionOf(
      param.strike,
      param.maturity,
      address(this),
      TimeswapV2OptionPosition.Short
    ) + shortAmount;

    // Ask the msg.sender to transfer the positions into this address.
    data = ITimeswapV2PoolMintCallback(msg.sender).timeswapV2PoolMintCallback(
      TimeswapV2PoolMintCallbackParam({
        strike: param.strike,
        maturity: param.maturity,
        long0Amount: long0Amount,
        long1Amount: long1Amount,
        shortAmount: shortAmount,
        liquidityAmount: liquidityAmount,
        data: data
      })
    );

    if (isQuote) revert Quote();

    // Check when the position balance targets are reached.

    if (long0Amount != 0)
      Error.checkEnough(
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Long0
        ),
        long0BalanceTarget
      );

    if (long1Amount != 0)
      Error.checkEnough(
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Long1
        ),
        long1BalanceTarget
      );

    Error.checkEnough(
      ITimeswapV2Option(optionPair).positionOf(
        param.strike,
        param.maturity,
        address(this),
        TimeswapV2OptionPosition.Short
      ),
      shortBalanceTarget
    );

    lowerGuard(param.strike, param.maturity);

    emit Mint(
      param.strike,
      param.maturity,
      msg.sender,
      param.to,
      liquidityAmount,
      long0Amount,
      long1Amount,
      shortAmount
    );
  }

  /// @inheritdoc ITimeswapV2Pool
  function burn(
    TimeswapV2PoolBurnParam calldata param
  )
    external
    override
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data)
  {
    return burn(param, false, 0);
  }

  /// @inheritdoc ITimeswapV2Pool
  function burn(
    TimeswapV2PoolBurnParam calldata param,
    uint96 durationForward
  )
    external
    override
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data)
  {
    return burn(param, true, durationForward);
  }

  /// @dev burn Liquidity and receive Short and Long tokens
  /// @dev can be only called before the maturity.
  /// @dev after the maturity of the pool, the long0 and long1 tokens are zero. And the short tokens are added into the transaction fees.
  /// @dev if the user wants to burn the liquidity after the maturity, they should call the collectTransactionFee function.
  /// @param param it is a struct that contains the parameters of the burn function
  /// @param durationForward The duration of time moved forward.
  /// @param isQuote Whether is used for quoting purposes.
  /// @return liquidityAmount The amount of liquidity burned.
  /// @return long0Amount The amount of long0 withdrawn.
  /// @return long1Amount The amount of long1 withdrawn.
  /// @return shortAmount The amount of short withdrawn.
  /// @return data the data used for the callbacks.
  function burn(
    TimeswapV2PoolBurnParam calldata param,
    bool isQuote,
    uint96 durationForward
  )
    private
    noDelegateCall
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data)
  {
    hasLiquidity(param.strike, param.maturity);

    ParamLibrary.check(param, blockTimestamp(durationForward));
    raiseGuard(param.strike, param.maturity);

    Pool storage pool = pools[param.strike][param.maturity];

    // Calculate the main logic of burn function.
    (liquidityAmount, long0Amount, long1Amount, shortAmount, data) = pool.burn(param, blockTimestamp(durationForward));

    // Transfer the positions to the recipients.

    // Long0 amount can be zero.
    if (long0Amount != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        param.strike,
        param.maturity,
        param.long0To,
        TimeswapV2OptionPosition.Long0,
        long0Amount
      );

    // Long1 amount can be zero.
    if (long1Amount != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        param.strike,
        param.maturity,
        param.long1To,
        TimeswapV2OptionPosition.Long1,
        long1Amount
      );

    // Short amount cannot be zero.
    ITimeswapV2Option(optionPair).transferPosition(
      param.strike,
      param.maturity,
      param.shortTo,
      TimeswapV2OptionPosition.Short,
      shortAmount
    );

    data = ITimeswapV2PoolBurnCallback(msg.sender).timeswapV2PoolBurnCallback(
      TimeswapV2PoolBurnCallbackParam({
        strike: param.strike,
        maturity: param.maturity,
        long0Amount: long0Amount,
        long1Amount: long1Amount,
        shortAmount: shortAmount,
        liquidityAmount: liquidityAmount,
        data: data
      })
    );

    if (isQuote) revert Quote();

    pool.liquidityPositions[msg.sender].burn(liquidityAmount);

    lowerGuard(param.strike, param.maturity);

    emit Burn(
      param.strike,
      param.maturity,
      msg.sender,
      param.long0To,
      param.long1To,
      param.shortTo,
      liquidityAmount,
      long0Amount,
      long1Amount,
      shortAmount
    );
  }

  /// @inheritdoc ITimeswapV2Pool
  function deleverage(
    TimeswapV2PoolDeleverageParam calldata param
  ) external override returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data) {
    return deleverage(param, false, 0);
  }

  /// @inheritdoc ITimeswapV2Pool
  function deleverage(
    TimeswapV2PoolDeleverageParam calldata param,
    uint96 durationForward
  ) external override returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data) {
    return deleverage(param, true, durationForward);
  }

  /// @dev deposit Long tokens and receive Short tokens
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the deleverage function.
  /// @param durationForward The duration of time moved forward.
  /// @param isQuote Whether is used for quoting purposes.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short received.
  /// @return data the data used for the callbacks.
  function deleverage(
    TimeswapV2PoolDeleverageParam calldata param,
    bool isQuote,
    uint96 durationForward
  ) private noDelegateCall returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data) {
    hasLiquidity(param.strike, param.maturity);
    ParamLibrary.check(param, blockTimestamp(durationForward));
    raiseGuard(param.strike, param.maturity);

    // Calculate the main logic of deleverage function.
    (long0Amount, long1Amount, shortAmount, data) = pools[param.strike][param.maturity].deleverage(
      param,
      transactionFee,
      protocolFee,
      blockTimestamp(durationForward)
    );

    // Calculate the amount of long0 position and long1 position required by the pool.

    // long0Amount chosen could be zero. Skip the calculation for gas efficiency.
    uint256 long0BalanceTarget;
    if (long0Amount != 0)
      long0BalanceTarget =
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Long0
        ) +
        long0Amount;

    // long1Amount chosen could be zero. Skip the calculation for gas efficiency.
    uint256 long1BalanceTarget;
    if (long1Amount != 0)
      long1BalanceTarget =
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Long1
        ) +
        long1Amount;

    // Transfer short positions to the recipient.
    ITimeswapV2Option(optionPair).transferPosition(
      param.strike,
      param.maturity,
      param.to,
      TimeswapV2OptionPosition.Short,
      shortAmount
    );

    // Ask the msg.sender to transfer the positions into this address.
    data = ITimeswapV2PoolDeleverageCallback(msg.sender).timeswapV2PoolDeleverageCallback(
      TimeswapV2PoolDeleverageCallbackParam({
        strike: param.strike,
        maturity: param.maturity,
        long0Amount: long0Amount,
        long1Amount: long1Amount,
        shortAmount: shortAmount,
        data: data
      })
    );

    if (isQuote) revert Quote();

    // Check when the position balance targets are reached.

    if (long0Amount != 0)
      Error.checkEnough(
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Long0
        ),
        long0BalanceTarget
      );

    if (long1Amount != 0)
      Error.checkEnough(
        ITimeswapV2Option(optionPair).positionOf(
          param.strike,
          param.maturity,
          address(this),
          TimeswapV2OptionPosition.Long1
        ),
        long1BalanceTarget
      );

    lowerGuard(param.strike, param.maturity);

    emit Deleverage(param.strike, param.maturity, msg.sender, param.to, long0Amount, long1Amount, shortAmount);
  }

  /// @inheritdoc ITimeswapV2Pool
  function leverage(
    TimeswapV2PoolLeverageParam calldata param
  ) external override returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data) {
    return leverage(param, false, 0);
  }

  /// @inheritdoc ITimeswapV2Pool
  function leverage(
    TimeswapV2PoolLeverageParam calldata param,
    uint96 durationForward
  ) external override returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data) {
    return leverage(param, true, durationForward);
  }

  /// @dev deposit Short tokens and receive Long tokens
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the leverage function.
  /// @param durationForward The duration of time moved forward.
  /// @param isQuote Whether is used for quoting purposes.
  /// @return long0Amount The amount of long0 received.
  /// @return long1Amount The amount of long1 received.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function leverage(
    TimeswapV2PoolLeverageParam calldata param,
    bool isQuote,
    uint96 durationForward
  ) private noDelegateCall returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data) {
    hasLiquidity(param.strike, param.maturity);
    ParamLibrary.check(param, blockTimestamp(durationForward));
    raiseGuard(param.strike, param.maturity);

    // Calculate the main logic of leverage function.
    (long0Amount, long1Amount, shortAmount, data) = pools[param.strike][param.maturity].leverage(
      param,
      transactionFee,
      protocolFee,
      blockTimestamp(durationForward)
    );

    // Calculate the amount of short position required by the pool.

    uint256 balanceTarget = ITimeswapV2Option(optionPair).positionOf(
      param.strike,
      param.maturity,
      address(this),
      TimeswapV2OptionPosition.Short
    ) + shortAmount;

    // Transfer the positions to the recipients.

    if (long0Amount != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        param.strike,
        param.maturity,
        param.long0To,
        TimeswapV2OptionPosition.Long0,
        long0Amount
      );

    if (long1Amount != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        param.strike,
        param.maturity,
        param.long1To,
        TimeswapV2OptionPosition.Long1,
        long1Amount
      );

    // Ask the msg.sender to transfer the positions into this address.
    data = ITimeswapV2PoolLeverageCallback(msg.sender).timeswapV2PoolLeverageCallback(
      TimeswapV2PoolLeverageCallbackParam({
        strike: param.strike,
        maturity: param.maturity,
        long0Amount: long0Amount,
        long1Amount: long1Amount,
        shortAmount: shortAmount,
        data: data
      })
    );

    if (isQuote) revert Quote();

    // Check when the position balance targets are reached.

    Error.checkEnough(
      ITimeswapV2Option(optionPair).positionOf(
        param.strike,
        param.maturity,
        address(this),
        TimeswapV2OptionPosition.Short
      ),
      balanceTarget
    );

    lowerGuard(param.strike, param.maturity);

    emit Leverage(
      param.strike,
      param.maturity,
      msg.sender,
      param.long0To,
      param.long1To,
      long0Amount,
      long1Amount,
      shortAmount
    );
  }

  /// @inheritdoc ITimeswapV2Pool
  function rebalance(
    TimeswapV2PoolRebalanceParam calldata param
  ) external override noDelegateCall returns (uint256 long0Amount, uint256 long1Amount, bytes memory data) {
    hasLiquidity(param.strike, param.maturity);
    ParamLibrary.check(param, blockTimestamp(0));
    raiseGuard(param.strike, param.maturity);

    // Calculate the main logic of rebalance function.
    (long0Amount, long1Amount) = pools[param.strike][param.maturity].rebalance(param, transactionFee, protocolFee);

    // Calculate the amount of long position required by the pool.

    uint256 balanceTarget = ITimeswapV2Option(optionPair).positionOf(
      param.strike,
      param.maturity,
      address(this),
      param.isLong0ToLong1 ? TimeswapV2OptionPosition.Long0 : TimeswapV2OptionPosition.Long1
    ) + (param.isLong0ToLong1 ? long0Amount : long1Amount);

    // Transfer the positions to the recipients.

    ITimeswapV2Option(optionPair).transferPosition(
      param.strike,
      param.maturity,
      param.to,
      param.isLong0ToLong1 ? TimeswapV2OptionPosition.Long1 : TimeswapV2OptionPosition.Long0,
      param.isLong0ToLong1 ? long1Amount : long0Amount
    );

    // Ask the msg.sender to transfer the positions into this address.
    data = ITimeswapV2PoolRebalanceCallback(msg.sender).timeswapV2PoolRebalanceCallback(
      TimeswapV2PoolRebalanceCallbackParam({
        strike: param.strike,
        maturity: param.maturity,
        isLong0ToLong1: param.isLong0ToLong1,
        long0Amount: long0Amount,
        long1Amount: long1Amount,
        data: param.data
      })
    );

    // Check when the position balance targets are reached.

    Error.checkEnough(
      ITimeswapV2Option(optionPair).positionOf(
        param.strike,
        param.maturity,
        address(this),
        param.isLong0ToLong1 ? TimeswapV2OptionPosition.Long0 : TimeswapV2OptionPosition.Long1
      ),
      balanceTarget
    );

    lowerGuard(param.strike, param.maturity);

    emit Rebalance(param.strike, param.maturity, msg.sender, param.to, param.isLong0ToLong1, long0Amount, long1Amount);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2Pool} from "./TimeswapV2Pool.sol";

import {ITimeswapV2PoolDeployer} from "./interfaces/ITimeswapV2PoolDeployer.sol";

/// @title Capable of deploying Timeswap V2 Pool
/// @author Timeswap Labs
contract TimeswapV2PoolDeployer is ITimeswapV2PoolDeployer {
  struct Parameter {
    address poolFactory;
    address optionPair;
    uint256 transactionFee;
    uint256 protocolFee;
  }

  /* ===== MODEL ===== */

  /// @inheritdoc ITimeswapV2PoolDeployer
  Parameter public override parameter;

  /* ===== UPDATE ===== */
  /// @dev deploy the pool contract
  /// @param poolFactory address of the pool factory
  /// @param optionPair address of the option pair contract
  /// @param transactionFee transaction fee to be used in the pool contract
  /// @param protocolFee protocol fee to be used in the pool contract
  function deploy(
    address poolFactory,
    address optionPair,
    uint256 transactionFee,
    uint256 protocolFee
  ) internal returns (address poolPair) {
    parameter = Parameter({
      poolFactory: poolFactory,
      optionPair: optionPair,
      transactionFee: transactionFee,
      protocolFee: protocolFee
    });

    poolPair = address(new TimeswapV2Pool{salt: keccak256(abi.encode(optionPair))}());

    delete parameter;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Ownership} from "@timeswap-labs/v2-library/contracts/Ownership.sol";

import {ITimeswapV2OptionFactory} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2OptionFactory.sol";

import {OptionPairLibrary} from "@timeswap-labs/v2-option/contracts/libraries/OptionPair.sol";

import {ITimeswapV2PoolFactory} from "./interfaces/ITimeswapV2PoolFactory.sol";

import {TimeswapV2PoolDeployer} from "./TimeswapV2PoolDeployer.sol";

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {OwnableTwoSteps} from "./base/OwnableTwoSteps.sol";

/// @title Factory contract for TimeswapV2Pool
/// @author Timeswap Labs
contract TimeswapV2PoolFactory is ITimeswapV2PoolFactory, TimeswapV2PoolDeployer, OwnableTwoSteps {
  using OptionPairLibrary for address;
  using Ownership for address;

  /// @dev Revert when fee initialization is chosen to be larger than uint16.
  /// @param fee The chosen fee.
  error IncorrectFeeInitialization(uint256 fee);

  /* ===== MODEL ===== */

  /// @inheritdoc ITimeswapV2PoolFactory
  address public immutable override optionFactory;
  /// @inheritdoc ITimeswapV2PoolFactory
  uint256 public immutable override transactionFee;
  /// @inheritdoc ITimeswapV2PoolFactory
  uint256 public immutable override protocolFee;

  mapping(address => address) private pairs;

  address[] public override getByIndex;

  /* ===== INIT ===== */

  constructor(
    address chosenOwner,
    address chosenOptionFactory,
    uint256 chosenTransactionFee,
    uint256 chosenProtocolFee
  ) OwnableTwoSteps(chosenOwner) {
    if (chosenTransactionFee > type(uint16).max) revert IncorrectFeeInitialization(chosenTransactionFee);
    if (chosenProtocolFee > type(uint16).max) revert IncorrectFeeInitialization(chosenProtocolFee);

    optionFactory = chosenOptionFactory;
    transactionFee = chosenTransactionFee;
    protocolFee = chosenProtocolFee;
  }

  /* ===== VIEW ===== */

  /// @inheritdoc ITimeswapV2PoolFactory
  function get(address optionPair) external view override returns (address pair) {
    pair = pairs[optionPair];
  }

  /// @inheritdoc ITimeswapV2PoolFactory
  function get(address token0, address token1) external view override returns (address pair) {
    address optionPair = ITimeswapV2OptionFactory(optionFactory).get(token0, token1);
    pair = pairs[optionPair];
  }

  function numberOfPairs() external view override returns (uint256) {
    return getByIndex.length;
  }

  /* ===== UPDATE ===== */

  /// @inheritdoc ITimeswapV2PoolFactory
  function create(address token0, address token1) external override returns (address pair) {
    address optionPair = ITimeswapV2OptionFactory(optionFactory).get(token0, token1);
    if (optionPair == address(0)) Error.zeroAddress();

    pair = pairs[optionPair];
    if (pair != address(0)) Error.zeroAddress();

    pair = deploy(address(this), optionPair, transactionFee, protocolFee);

    pairs[optionPair] = pair;
    getByIndex.push(pair);

    emit Create(msg.sender, optionPair, pair);
  }
}