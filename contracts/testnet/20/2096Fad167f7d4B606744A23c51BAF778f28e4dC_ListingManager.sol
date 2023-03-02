// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title MemoryBinarySearch
 * @author Lyra
 * @notice Binary search utilities for memory arrays.
 * Close copy of OZ/Arrays.sol storage binary search.
 */

library MemoryBinarySearch {
  /**
   * @dev Searches a sorted `array` and returns the first index that contains
   * a value greater or equal to `element`. If no such index exists (i.e. all
   * values in the array are strictly less than `element`), the array length is
   * returned. Time complexity O(log n).
   *
   * `array` is expected to be sorted in ascending order, and to contain no
   * repeated elements.
   */
  function findUpperBound(uint[] memory array, uint element) internal pure returns (uint) {
    if (array.length == 0) {
      return 0;
    }

    uint low = 0;
    uint high = array.length;

    while (low < high) {
      uint mid = (low + high) / 2;

      // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
      // because `(low + high) / 2` rounds down.
      if (array[mid] > element) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
    if (low > 0 && array[low - 1] == element) {
      return low - 1;
    } else {
      return low;
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title UnorderedMemoryArray
 * @author Lyra
 * @notice util functions for in-memory unordered array operations
 */

library UnorderedMemoryArray {
  /**
   * @dev Add unique element to existing "array" if and increase max index
   * array memory will be updated in place
   * @param array array of number
   * @param newElement number to check
   * @param arrayLen previously recorded array length with non-zero value
   * @return newArrayLen new length of array
   * @return index index of the added element
   */
  function addUniqueToArray(uint[] memory array, uint newElement, uint arrayLen)
    internal
    pure
    returns (uint newArrayLen, uint index)
  {
    int foundIndex = findInArray(array, newElement, arrayLen);
    if (foundIndex == -1) {
      array[arrayLen] = newElement;
      unchecked {
        return (arrayLen + 1, arrayLen);
      }
    }
    return (arrayLen, uint(foundIndex));
  }

  /**
   * @dev Add unique element to existing "array" if and increase max index
   * array memory will be updated in place
   * @param array array of address
   * @param newElement address to check
   * @param arrayLen previously recorded array length with non-zero value
   * @return newArrayLen new length of array
   */
  function addUniqueToArray(address[] memory array, address newElement, uint arrayLen)
    internal
    pure
    returns (uint newArrayLen)
  {
    if (findInArray(array, newElement, arrayLen) == -1) {
      unchecked {
        array[arrayLen++] = newElement;
      }
    }
    return arrayLen;
  }

  /**
   * @dev return if a number exists in an array of numbers
   * @param array array of number
   * @param toFind  numbers to find
   * @return index index of the found element. -1 if not found
   */
  function findInArray(uint[] memory array, uint toFind, uint arrayLen) internal pure returns (int index) {
    unchecked {
      for (uint i; i < arrayLen; ++i) {
        if (array[i] == 0) {
          return -1;
        }
        if (array[i] == toFind) {
          return int(i);
        }
      }
      return -1;
    }
  }

  /**
   * @dev return if an address exists in an array of address
   * @param array array of address
   * @param toFind  address to find
   * @return index index of the found element. -1 if not found
   */
  function findInArray(address[] memory array, address toFind, uint arrayLen) internal pure returns (int index) {
    unchecked {
      for (uint i; i < arrayLen; ++i) {
        if (array[i] == address(0)) {
          return -1;
        }
        if (array[i] == toFind) {
          return int(i);
        }
      }
      return -1;
    }
  }

  /**
   * @dev shorten a memory array length in place
   */
  function trimArray(uint[] memory array, uint finalLength) internal pure {
    assembly {
      mstore(array, finalLength)
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library FixedPointMathLib {
  /// @dev Magic numbers for normal CDF
  uint private constant N0 = 4062099735652764000328;
  uint private constant N1 = 4080670594171652639712;
  uint private constant N2 = 2067498006223917203771;
  uint private constant N3 = 625581961353917287603;
  uint private constant N4 = 117578849504046139487;
  uint private constant N5 = 12919787143353136591;
  uint private constant N6 = 650478250178244362;
  uint private constant M0 = 8124199471305528000657;
  uint private constant M1 = 14643514515380871948050;
  uint private constant M2 = 11756730424506726822413;
  uint private constant M3 = 5470644798650576484341;
  uint private constant M4 = 1600821957476871612085;
  uint private constant M5 = 296331772558254578451;
  uint private constant M6 = 32386342837845824709;
  uint private constant M7 = 1630477228166597028;
  uint private constant SQRT_TWOPI_BASE2 = 46239130270042206915;

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
        if (x < 0) {
          revert LnNegativeUndefined();
        }
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
  // consumes 500 gas
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
      if (x >= 135305999368893231589) {
        revert ExpOverflow();
      }

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

  /// @notice Calculates the square root of x, rounding down (borrowed from https://ethereum.stackexchange.com/a/97540)
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
    if (xAux >= 0x4) {
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
   * @dev Returns the square root of a value using Newton's method.
   */
  function sqrt(uint x) internal pure returns (uint) {
    // Add in an extra unit factor for the square root to gobble;
    // otherwise, sqrt(x * UNIT) = sqrt(x) * sqrt(UNIT)
    return _sqrt(x * 1e18);
  }

  /**
   * @dev Compute the absolute value of `val`.
   *
   * @param val The number to absolute value.
   */
  function abs(int val) internal pure returns (uint) {
    return uint(val < 0 ? -val : val);
  }

  /**
   * @dev The standard normal distribution of the value.
   */
  function stdNormal(int x) internal pure returns (uint) {
    int y = ((x >> 1) * x) / 1e18;
    return (exp(-y) * 1e18) / 2506628274631000502;
  }

  /**
   * @dev The standard normal cumulative distribution of the value.
   * borrowed from a C++ implementation https://stackoverflow.com/a/23119456
   * original paper: http://www.codeplanet.eu/files/download/accuratecumnorm.pdf
   * consumes 1800 gas
   */
  function stdNormalCDF(int x) internal pure returns (uint) {
    unchecked {
      uint z = abs(x);
      uint c;
      if (z > 37 * 1e18) {
        return (x <= 0) ? c : uint(1e18 - int(c));
      } else {
        // z^2 cannot overflow in this "else" block
        uint e = exp(-int(((z >> 1) * z) / 1e18));

        // convert to binary base with factor 1e18 / 2**64 = 5**18 / 2**46.
        // z cant overflow with z < 37 * 1e18 range we're in
        // e cant overflow since its at most 1.0 (at z=0)

        z = (z << 46) / 5 ** 18;
        e = (e << 46) / 5 ** 18;

        if (z < 130438178253327725388) // 7071067811865470000 in decimal (7.07)
        {
          // Hart's algorithm for x \in (-7.07, 7.07)
          uint n;
          uint d;

          n = ((N6 * z) >> 64) + N5;
          n = ((n * z) >> 64) + N4;
          n = ((n * z) >> 64) + N3;
          n = ((n * z) >> 64) + N2;
          n = ((n * z) >> 64) + N1;
          n = ((n * z) >> 64) + N0;

          d = ((M7 * z) >> 64) + M6;
          d = ((d * z) >> 64) + M5;
          d = ((d * z) >> 64) + M4;
          d = ((d * z) >> 64) + M3;
          d = ((d * z) >> 64) + M2;
          d = ((d * z) >> 64) + M1;
          d = ((d * z) >> 64) + M0;

          c = (n * e);
          assembly {
            // Div in assembly because solidity adds a zero check despite the `unchecked`
            // denominator d is a polynomial with non-negative z and, all magic numbers are positive
            // no need to scale since c = (n * e) is already 2^64 times larger
            c := div(c, d)
          }
        } else {
          // continued fracton approximation for abs(x) \in (7.07, 37)
          uint f;
          f = 11990383647911208550; // 13/20 ratio in base 2^64
          // TODO can probaby use assembly here for division
          f = (4 << 128) / (z + f);
          f = (3 << 128) / (z + f);
          f = (2 << 128) / (z + f);
          f = (1 << 128) / (z + f);
          f += z;
          f = (f * SQRT_TWOPI_BASE2) >> 64;
          e = (e << 64);
          assembly {
            // Div in assembly because solidity adds a zero check despite the `unchecked`
            // denominator f is a finite continued fraction that attains min value of 0.4978 at z=37.0
            // so it cannot underflow into 0
            // no need to scale since e is made 2^64 times larger on the line above
            c := div(e, f)
          }
        }
      }

      c = (c * (5 ** 18)) >> 46;
      c = (x <= 0) ? c : uint(1e18 - int(c));
      return c;
    }
  }

  error Overflow();
  error ExpOverflow();
  error LnNegativeUndefined();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./StorageSlot.sol";
import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    using StorageSlot for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

import "../../lib/openzeppelin-contracts/contracts/utils/Arrays.sol";
import "../../lib/lyra-utils/src/arrays/UnorderedMemoryArray.sol";

/**
 * @title Automated Expiry Generator
 * @author Lyra
 * @notice This Library automatically generates expiry times for various boards
 * The intent being to automate the way that boards and strikes are listed
 * Whilst ensuring that the expiries make sense are in reasonable timeframes
 */
library ExpiryGenerator {
  /// @dev time difference between 0 UTC and the friday 8am
  uint constant MOD_OFFSET = 115200;

  /**
   * @notice Calculate the upcoming weekly and monthly expiries and insert into an array.
   * @param monthlyExpiries Ordered list of monthly expiries
   * @param nWeeklies Number of weekly options to generate
   * @param nMonthlies Number of monthly options to generate
   * @param timestamp Reference timestamp for generating expiries from that date onwards
   * @return expiries The valid expiries for the given parameters
   */
  function getExpiries(uint nWeeklies, uint nMonthlies, uint timestamp, uint[] storage monthlyExpiries)
    internal
    view
    returns (uint[] memory expiries)
  {
    return _expiriesGenerator(nWeeklies, nMonthlies, timestamp, monthlyExpiries);
  }

  function _expiriesGenerator(uint nWeeklies, uint nMonthlies, uint timestamp, uint[] storage monthlyExpiries)
    internal
    view
    returns (uint[] memory expiries)
  {
    expiries = new uint[](nWeeklies + nMonthlies);
    uint weeklyExpiry = getNextFriday(timestamp);

    uint insertIndex = 0;
    for (; insertIndex < nWeeklies; ++insertIndex) {
      expiries[insertIndex] = weeklyExpiry;
      weeklyExpiry += 7 days;
    }

    // TODO: consider if we want to start from last weekly seen and get _next_ 3 monthlies
    uint monthlyIndex = Arrays.findUpperBound(monthlyExpiries, timestamp);

    // if there is more than 1 monthly add to expiries array
    for (uint i = 0; i < nMonthlies; i++) {
      uint monthlyStamp = monthlyExpiries[monthlyIndex + i];
      if (UnorderedMemoryArray.findInArray(expiries, monthlyStamp, nWeeklies) != -1) {
        // if the weekly expiry is already in the monthlies array
        // then we need to add the next friday
        continue;
      }
      expiries[insertIndex] = monthlyStamp;
      ++insertIndex;
    }

    UnorderedMemoryArray.trimArray(expiries, insertIndex);

    return expiries;
  }

  /////////////
  // Helpers //
  /////////////

  /**
   * @notice This function finds the first friday expiry (8pm UTC) relative to the current timestamp
   * @dev Friday's array has to be sorted in ascending order
   * @param timestamp The current timestamp
   * @return Timestamp the timestamp of the closest friday to the current timestamp,
   */
  function getNextFriday(uint timestamp) internal pure returns (uint) {
    // by subtracting the offset you make the friday 8am the reference point - so when you mod, you'll round to the nearest friday
    return timestamp - ((timestamp - MOD_OFFSET) % 7 days) + 7 days;
  }
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

// Libraries
import "../../lib/openzeppelin-contracts/contracts/utils/Arrays.sol";
import "../../lib/lyra-utils/src/arrays/UnorderedMemoryArray.sol";
import "../../lib/lyra-utils/src/decimals/DecimalMath.sol";
import "../../lib/lyra-utils/src/decimals/SignedDecimalMath.sol";
import "../../lib/lyra-utils/src/math/FixedPointMathLib.sol";

/**
 * @title Automated strike price generator
 * @author Lyra
 * @notice The library automatically generates strike prices for various expiries as spot fluctuates.
 * The intent is to automate away the decision making on which strikes to list,
 * while generating boards with strike price that span a reasonable delta range.
 */
library StrikePriceGenerator {
  using DecimalMath for uint;
  using SignedDecimalMath for int;
  using FixedPointMathLib for int;
  using UnorderedMemoryArray for uint[];

  /**
   * @notice Generates an array of new strikes around spot following the schema of this library.
   * @param tTarget The annualized time-to-expiry of the new surface to generate.
   * @param spot Current chainlink spot price.
   * @param maxScaledMoneyness Caller must pre-compute maxScaledMoneyness from governance parameters.
   * Typically one param would be a static MAX_D1, e.g. MAX_D1 = 1.2, which would
   * be mapped out of the desired delta range. Since delta=N(d1), if we want to bound
   * the delta to say (10, 90) range, we can simply bound d1 to be in (-1.2, 1.2) range.
   * Second param would be some approx volatility baseline, e.g. MONEYNESS_SCALER.
   * This param can be maintained by governance or taken to be some baseIv GVAW.
   * It since d1 = ln(K/S) / (sigma * sqrt(T)), some proxy for sigma is needed to
   * solve for K from d1.
   * Together, maxScaledMoneyness = MAX_D1 * MONEYNESS_SCALER is expected to be passed here.
   * @param maxNumStrikes A cap on how many strikes can be in a single board.
   * @param liveStrikes Array of strikes that already exist in the board, will avoid generating them.
   * @return newStrikes The additional strikes that must be added to the board.
   * @return numAdded Total number of added strikes as `newStrikes` may contain blank entries.
   */
  function getNewStrikes(
    uint tTarget,
    uint spot,
    uint maxScaledMoneyness,
    uint maxNumStrikes,
    uint[] memory liveStrikes,
    uint[] storage pivots
  ) internal view returns (uint[] memory newStrikes, uint numAdded) {
    // find step size and the nearest pivot
    uint nearestPivot = getLeftNearestPivot(pivots, spot);
    uint step = getStep(nearestPivot, tTarget);

    // find the ATM strike and see if it already exists
    (uint atmStrike) = getATMStrike(spot, nearestPivot, step);

    // find remaining strike (excluding atm)
    int remainNumStrikes = int(maxNumStrikes) - int(liveStrikes.length);
    if (remainNumStrikes <= 0) {
      // if == 0, then still need to add ATM
      return (newStrikes, 0);
    }

    // find strike range
    (uint minStrike, uint maxStrike) = getStrikeRange(tTarget, spot, maxScaledMoneyness);

    // starting from ATM strike, go left and right in steps
    return _createNewStrikes(liveStrikes, remainNumStrikes, atmStrike, step, minStrike, maxStrike);
  }

  /////////////
  // Helpers //
  /////////////

  /**
   * @notice Finds the left nearest pivot using binary search
   * @param pivots Storage array of available pivots
   * @param spot Spot price
   * @return nearestPivot left nearest pivot
   */
  function getLeftNearestPivot(uint[] storage pivots, uint spot) internal view returns (uint nearestPivot) {
    uint maxPivot = pivots[pivots.length - 1];
    if (spot >= maxPivot) {
      revert SpotPriceAboveMaxStrike(maxPivot);
    }

    if (spot == 0) {
      revert SpotPriceIsZero();
    }

    // use OZ upperBound library to get leftNearest
    uint rightIndex = Arrays.findUpperBound(pivots, spot);
    if (rightIndex == 0) {
      return pivots[0];
    } else if (pivots[rightIndex] == spot) {
      return pivots[rightIndex];
    } else {
      return pivots[rightIndex - 1];
    }
  }

  /**
   * @notice Finds the ATM strike by stepping up from the pivot
   * @param spot Spot price
   * @param pivot Pivot strike that is nearest to the spot price
   * @param step Step size
   * @return atmStrike The first strike satisfying strike <= spot < (strike + step)
   */
  function getATMStrike(uint spot, uint pivot, uint step) internal pure returns (uint atmStrike) {
    atmStrike = pivot;
    while (true) {
      uint nextStrike = atmStrike + step;

      if (spot < nextStrike) {
        uint distanceLeft = spot - atmStrike;
        uint distanceRight = nextStrike - spot;
        return (distanceRight < distanceLeft) ? nextStrike : atmStrike;
      }
      atmStrike += step;
    }
  }

  function getStrikeRange(uint tTarget, uint spot, uint maxScaledMoneyness)
    internal
    pure
    returns (uint minStrike, uint maxStrike)
  {
    uint strikeRange = int(maxScaledMoneyness.multiplyDecimal(Math.sqrt(tTarget * DecimalMath.UNIT))).exp();
    return (spot.divideDecimal(strikeRange), spot.multiplyDecimal(strikeRange));
  }

  /**
   * @notice Returns the strike step corresponding to the pivot bucket and the time-to-expiry.
   * @dev Since vol is approx ~ sqrt(T), it makes sense to double the step size
   * every time tAnnualized is roughly quadripled
   * @param p The pivot strike.
   * @param tAnnualized Years to expiry, 18 decimals.
   * @return step The strike step size at this pivot and tAnnualized.
   */
  function getStep(uint p, uint tAnnualized) internal pure returns (uint step) {
    unchecked {
      uint div;
      if (tAnnualized * (365 days) <= (1 weeks * 1e18)) {
        div = 40; // 2.5%
      } else if (tAnnualized * (365 days) <= (4 weeks * 1e18)) {
        div = 20; // 5%
      } else if (tAnnualized * (365 days) <= (12 weeks * 1e18)) {
        div = 10; // 10%
      } else {
        div = 5; // 20%
      }

      if (p <= div) {
        revert PivotLessThanOrEqualToStepDiv(p, div);
      }
      return p / div;
    }
  }

  /**
   * @notice Constructs a new array of strikes given all required parameters.
   * Begins by adding a strike to the left of the ATM, then to the right.
   * Alternates until remaining strikes runs out or exceeds the range.
   * @param liveStrikes Existing strikes.
   * @param remainNumStrikes Num of strikes that can be added.
   * @param atmStrike Strike price of ATM.
   * @param step Step size for each new strike.
   * @param minStrike Min allowed strike based on moneyness (delta).
   * @param maxStrike Max allowed strike based on moneyness (delta).
   * @return newStrikes Additional strikes to add.
   * @return numAdded Total number of added strikes as `newStrikes` may contain blank entries.
   */
  function _createNewStrikes(
    uint[] memory liveStrikes,
    int remainNumStrikes,
    uint atmStrike,
    uint step,
    uint minStrike,
    uint maxStrike
  ) internal pure returns (uint[] memory newStrikes, uint numAdded) {
    // add ATM strike first
    numAdded = (liveStrikes.findInArray(atmStrike, liveStrikes.length) == -1) ? 1 : 0;
    newStrikes = new uint[](uint(remainNumStrikes));
    if (numAdded == 1) {
      newStrikes[0] = atmStrike;
      remainNumStrikes--;
    }

    uint nextStrike;
    uint lastStrike;
    uint stepFromAtm;
    uint i = 0;
    while (remainNumStrikes > 0) {
      stepFromAtm = (1 + (i / 2)) * step;
      lastStrike = nextStrike;
      if (i % 2 == 0) {
        // prioritize left strike
        nextStrike = (atmStrike > stepFromAtm) ? atmStrike - stepFromAtm : 0;
      } else {
        nextStrike = atmStrike + stepFromAtm;
      }

      if (
        liveStrikes.findInArray(nextStrike, liveStrikes.length) == -1 && (nextStrike > minStrike)
          && (nextStrike < maxStrike)
      ) {
        newStrikes[numAdded++] = nextStrike;
        remainNumStrikes--;
      } else if ((lastStrike < minStrike) && (nextStrike > maxStrike)) {
        return (newStrikes, numAdded);
      }

      i++;
    }
  }

  ////////////
  // Errors //
  ////////////
  error SpotPriceAboveMaxStrike(uint maxPivot);
  error SpotPriceIsZero();
  error PivotLessThanOrEqualToStepDiv(uint pivot, uint div);
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

import "../../lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "../../lib/lyra-utils/src/decimals/DecimalMath.sol";
import "../../lib/lyra-utils/src/decimals/SignedDecimalMath.sol";

import "../../lib/lyra-utils/src/math/FixedPointMathLib.sol";
import "../../lib/lyra-utils/src/arrays/MemoryBinarySearch.sol";

/**
 * @title Automated vol generator
 * @author Lyra
 * @notice The library automatically generates baseIv and skews for
 * various input strikes. It uses other boards or existing strikes
 * to best approximate an initial baseIv or skew for each new strike.
 */
library VolGenerator {
  using DecimalMath for uint;
  using SignedDecimalMath for int;
  using FixedPointMathLib for int;
  using SafeCast for int;
  using MemoryBinarySearch for uint[];

  struct Board {
    // annualized time to expiry: 1 day == 1 / 365 in 18 decimal points
    uint tAnnualized;
    // base volatility of all the strikes in this board
    uint baseIv;
    // all strikes ordered in ascending order
    uint[] orderedStrikePrices;
    // all skews corresponding the order of strike prices
    uint[] orderedSkews;
  }

  ////////////////
  // End to End //
  ////////////////

  /**
   * @notice Returns the skew for a given strike
   * when the new board has both an adjacent short and long dated boards.
   * E.g. for a new strike: 3mo time to expiry, and liveBoards: [1d, 1mo, 6mo]
   * The returned new strike volatility = baseIv * newSkew
   * @param newStrike the strike price for which to find the skew
   * @param tTarget annualized time to expiry
   * @param baseIv base volatility for the given strike
   * @param shortDatedBoard Board details of the board with a shorter time to expiry.
   * @param longDatedBoard Board details of the board with a longer time to expiry.
   * @return newSkew Estimated skew of the new strike
   */
  function getSkewForNewBoard(
    uint newStrike,
    uint tTarget,
    uint baseIv,
    Board memory shortDatedBoard,
    Board memory longDatedBoard
  ) internal pure returns (uint newSkew) {
    // get matching skews of adjacent boards
    uint shortDatedSkew = getSkewForLiveBoard(newStrike, shortDatedBoard);

    uint longDatedSkew = getSkewForLiveBoard(newStrike, longDatedBoard);

    // interpolate skews
    return _interpolateSkewAcrossBoards(
      shortDatedSkew,
      longDatedSkew,
      shortDatedBoard.baseIv,
      longDatedBoard.baseIv,
      shortDatedBoard.tAnnualized,
      longDatedBoard.tAnnualized,
      tTarget,
      baseIv
    );
  }

  /**
   * @notice Returns the skew for a given strike
   * when the new board does not have adjacent boards on both sides.
   * E.g. for a new strike: 3mo time to expiry, but liveBoards: [1d, 1w, 1mo]
   * The returned new strike volatility = baseIv * newSkew.
   * @param newStrike the strike price for which to find the skew
   * @param tTarget annualized time to expiry
   * @param baseIv base volatility for the given strike
   * @param edgeBoard Board details of the board with a shorter or longer time to expiry
   * @return newSkew Estimated skew of the new strike
   */
  function getSkewForNewBoard(uint newStrike, uint tTarget, uint baseIv, uint spot, Board memory edgeBoard)
    internal
    pure
    returns (uint newSkew)
  {
    return _extrapolateSkewAcrossBoards(
      newStrike,
      edgeBoard.orderedStrikePrices,
      edgeBoard.orderedSkews,
      edgeBoard.tAnnualized,
      edgeBoard.baseIv,
      tTarget,
      baseIv,
      spot
    );
  }

  /**
   * @notice Returns the skew for a given strike that lies within an existing board.
   * The returned new strike volatility = baseIv * newSkew.
   * @param newStrike the strike price for which to find the skew
   * @param liveBoard Board details of the live board
   * @return newSkew Estimated skew of the new strike
   */
  function getSkewForLiveBoard(uint newStrike, Board memory liveBoard) internal pure returns (uint newSkew) {
    uint[] memory strikePrices = liveBoard.orderedStrikePrices;
    uint[] memory skews = liveBoard.orderedSkews;

    uint numLiveStrikes = strikePrices.length;
    if (numLiveStrikes == 0) {
      revert VG_NoStrikes();
    }

    // early return if found exact match
    uint idx = strikePrices.findUpperBound(newStrike);
    if (idx != numLiveStrikes && strikePrices[idx] == newStrike) {
      return skews[idx];
    }

    // determine whether to interpolate or extrapolate
    if (idx == 0) {
      return skews[0];
    } else if (idx == numLiveStrikes) {
      return skews[numLiveStrikes - 1];
    } else {
      return _interpolateSkewWithinBoard(
        newStrike, strikePrices[idx - 1], strikePrices[idx], skews[idx - 1], skews[idx], liveBoard.baseIv
      );
    }
  }

  ///////////////////
  // Across Boards //
  ///////////////////

  /**
   * @notice Interpolates skew for a new baord using exact strikes from longer/shorted dated boards.
   * @param leftSkew Skew from same strike but shorter dated board.
   * @param rightSkew Skew from same strike but longer dated board.
   * @param leftBaseIv BaseIv of the shorter dated board.
   * @param rightBaseIv BaseIv of the longer dated board.
   * @param leftT Annualized time to expiry of the shorter dated board.
   * @param rightT Annualized time to expiry of the longer dated board.
   * @param tTarget Annualied time to expiry of the targer strike
   * @param baseIv BaseIv of the board with the new strike
   * @return newSkew New strike's skew.
   */
  function _interpolateSkewAcrossBoards(
    uint leftSkew,
    uint rightSkew,
    uint leftBaseIv,
    uint rightBaseIv,
    uint leftT,
    uint rightT,
    uint tTarget,
    uint baseIv
  ) internal pure returns (uint newSkew) {
    if (!(leftT < tTarget && tTarget < rightT)) {
      revert VG_ImproperExpiryOrderDuringInterpolation(leftT, tTarget, rightT);
    }

    uint ratio = (rightT - tTarget).divideDecimal(rightT - leftT);

    // convert to variance
    uint leftVariance = getVariance(leftBaseIv, leftSkew).multiplyDecimal(leftT);
    uint rightVariance = getVariance(rightBaseIv, rightSkew).multiplyDecimal(rightT);

    // interpolate
    uint vol = sqrtWeightedAvg(ratio, leftVariance, rightVariance, tTarget);
    return vol.divideDecimal(baseIv);
  }

  /**
   * @notice Extrapolates skew for a strike on a new board.
   * Assumes: sigma(z(T1), T1) == sigma(z(T2), T2)
   * i.e. "2mo 80-delta option" has same vol as "3mo 80-delta option".
   * @param newStrike The "live" volatility slice in the form of ExpiryData.
   * @param orderedEdgeBoardStrikes Ordered list of strikes of the live board closest to the new board.
   * @param orderedEdgeBoardSkews Skews of the live board in the same order as the strikes.
   * @param edgeBoardT The index of expiryArray's edge, i.e. 0 or expiryArray.length - 1.
   * @param edgeBoardBaseIv Base volatility of the live board.
   * @param tTarget The annualized time-to-expiry of the new surface user wants to generate.
   * @param baseIv Value for ATM skew to anchor towards, e.g. 1e18 will ensure ATM skew is set to 1.0.
   * @param spot Current chainlink spot price.
   * @return newSkew Array of skews for each strike in strikeTargets.
   */
  function _extrapolateSkewAcrossBoards(
    uint newStrike,
    uint[] memory orderedEdgeBoardStrikes,
    uint[] memory orderedEdgeBoardSkews,
    uint edgeBoardT,
    uint edgeBoardBaseIv,
    uint tTarget,
    uint baseIv,
    uint spot
  ) internal pure returns (uint newSkew) {
    // map newStrike to a strike on the edge board with the same moneyness
    int moneyness = strikeToMoneyness(newStrike, spot, tTarget);
    uint strikeOnEdgeBoard = moneynessToStrike(moneyness, spot, edgeBoardT);

    // get skew on the existing board
    uint skewWithEdgeBaseIv = getSkewForLiveBoard(
      strikeOnEdgeBoard,
      Board({
        orderedStrikePrices: orderedEdgeBoardStrikes,
        orderedSkews: orderedEdgeBoardSkews,
        baseIv: edgeBoardBaseIv,
        tAnnualized: edgeBoardT
      })
    );

    // convert skew to new board given a different baseIv
    return skewWithEdgeBaseIv.multiplyDecimal(edgeBoardBaseIv).divideDecimal(baseIv);
  }

  //////////////////
  // Within Board //
  //////////////////

  /**
   * @notice Interpolates skew for a new strike when given adjacent strikes.
   * @param newStrike The strike for which skew will be interpolated.
   * @param leftStrike Must be less than midStrike.
   * @param rightStrike Must be greater than midStrike.
   * @param leftSkew The skew of leftStrike.
   * @param rightSkew The skew of rightStrike
   * @param baseIv The base volatility of the board
   * @return newSkew New strike's skew.
   */
  function _interpolateSkewWithinBoard(
    uint newStrike,
    uint leftStrike,
    uint rightStrike,
    uint leftSkew,
    uint rightSkew,
    uint baseIv
  ) internal pure returns (uint newSkew) {
    // ensure mid strike is actually in the middle
    if (!(leftStrike < newStrike && newStrike < rightStrike)) {
      revert VG_ImproperStrikeOrderDuringInterpolation(leftStrike, newStrike, rightStrike);
    }

    // get left and right variances
    uint varianceLeft = getVariance(baseIv, leftSkew);
    uint varianceRight = getVariance(baseIv, rightSkew);

    // convert strikes into ln space
    int lnMStrike = int(newStrike).ln();
    int lnLStrike = int(leftStrike).ln();
    int lnRStrike = int(rightStrike).ln();

    // interpolate
    uint ratio = SafeCast.toUint256((lnRStrike - lnMStrike).divideDecimal(lnRStrike - lnLStrike));

    uint vol = sqrtWeightedAvg(ratio, varianceLeft, varianceRight, 1e18);
    return vol.divideDecimal(baseIv);
  }

  /////////////
  // Helpers //
  /////////////

  /**
   * @notice Converts a $ strike to standard moneyness.
   * @dev By "standard" moneyness we mean moneyness := ln(K/S) / sqrt(T).
   * This value allows us to avoid delta calculations.
   * Delta maps one-to-one to Black-Scholes d1, and this is a "simple" version of d1.
   * So instead of using / computing / inverting delta, we can just find moneyness
   * That maps to desired delta values, and use it instead.
   * @param strike dollar strike, 18 decimals
   * @param spot dollar Chainlink spot, 18 decimals
   * @param tAnnualized annualized time-to-expiry, 18 decimals
   */
  function strikeToMoneyness(uint strike, uint spot, uint tAnnualized) internal pure returns (int moneyness) {
    unchecked {
      moneyness = int(strike.divideDecimal(spot)).ln().divideDecimal(int(Math.sqrt(tAnnualized * DecimalMath.UNIT)));
    }
  }

  /**
   * @notice Converts standard moneyness back to a $ strike.
   * Inverse of `strikeToMoneyness()`.
   * @param moneyness moneyness as defined in _strikeToMoneyness()
   * @param spot dollar Chainlink spot, 18 decimals
   * @param tAnnualized annualized time-to-expiry, 18 decimals
   */
  function moneynessToStrike(int moneyness, uint spot, uint tAnnualized) internal pure returns (uint strike) {
    unchecked {
      strike = moneyness.multiplyDecimal(int(Math.sqrt(tAnnualized * DecimalMath.UNIT))).exp().multiplyDecimal(spot);
    }
  }

  /**
   * @notice Calculates variance given the baseIv and skew.
   * @param baseIv The base volatility of the board.
   * @param skew The volatility skew of the given strike.
   * @return variance Variance of the given strike.
   */
  function getVariance(uint baseIv, uint skew) internal pure returns (uint variance) {
    // todo: good candidate for a standalone Lyra-util library
    variance = baseIv.multiplyDecimal(skew);
    return variance.multiplyDecimal(variance);
  }

  function sqrtWeightedAvg(uint leftVal, uint leftWeight, uint rightWeight, uint denominator)
    internal
    pure
    returns (uint)
  {
    uint weightedAvg = leftVal.multiplyDecimal(leftWeight) + (DecimalMath.UNIT - leftVal).multiplyDecimal(rightWeight);

    return Math.sqrt(weightedAvg.divideDecimal(denominator) * DecimalMath.UNIT);
  }

  ////////////
  // Errors //
  ////////////

  error VG_ImproperStrikeOrderDuringInterpolation(uint leftStrike, uint midStrike, uint rightStrike);
  error VG_ImproperStrikeOrderDuringExtrapolation(uint insideStrike, uint edgeStrike, uint newStrike);
  error VG_ImproperExpiryOrderDuringInterpolation(uint leftT, uint tTarget, uint rightT);

  error VG_NoStrikes();
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

// Interfaces
import "./lyra-interfaces/IBaseExchangeAdapter.sol";
import "./lyra-interfaces/ILiquidityPool.sol";
import "./lyra-interfaces/IOptionGreekCache.sol";
import "./lyra-interfaces/IOptionMarket.sol";
import "./lyra-interfaces/IOptionMarketGovernanceWrapper.sol";

// Libraries
import "../lib/lyra-utils/src/decimals/DecimalMath.sol";
import "./lib/VolGenerator.sol";
import "./lib/StrikePriceGenerator.sol";
import "./lib/ExpiryGenerator.sol";

// Inherited
import "./ListingManagerLibrarySettings.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";

contract ListingManager is ListingManagerLibrarySettings, Ownable2Step {
  using DecimalMath for uint;

  /////////////////////
  // Storage structs //
  /////////////////////
  struct QueuedBoard {
    uint queuedTime;
    uint baseIv;
    uint expiry;
    StrikeToAdd[] strikesToAdd;
  }

  struct QueuedStrikes {
    uint boardId;
    uint queuedTime;
    StrikeToAdd[] strikesToAdd;
  }

  struct StrikeToAdd {
    uint strikePrice;
    uint skew;
  }

  ///////////////
  // In-memory //
  ///////////////
  struct BoardDetails {
    uint expiry;
    uint baseIv;
    StrikeDetails[] strikes;
  }

  struct StrikeDetails {
    uint strikePrice;
    uint skew;
  }

  ///////////////
  // Variables //
  ///////////////
  IBaseExchangeAdapter immutable exchangeAdapter;
  ILiquidityPool immutable liquidityPool;
  IOptionGreekCache immutable optionGreekCache;
  IOptionMarket immutable optionMarket;
  IOptionMarketGovernanceWrapper immutable governanceWrapper;

  address riskCouncil;

  /// @notice How long a board must be queued before it can be publicly executed
  uint public boardQueueTime = 1 days;
  /// @notice How long new strikes must be queued before they can be publicly executed
  uint public strikeQueueTime = 1 days;
  /// @notice How long a queued item can exist after queueTime before being considered stale and removed
  uint public queueStaleTime = 1 days;
  /// @notice Limit strikes generated to be within this moneyness bound
  uint public maxScaledMoneyness = 1.2 ether;

  // boardId => strikes
  mapping(uint => QueuedStrikes) queuedStrikes;

  // expiry => board;
  mapping(uint => QueuedBoard) queuedBoards;

  constructor(
    IBaseExchangeAdapter _exchangeAdapter,
    ILiquidityPool _liquidityPool,
    IOptionGreekCache _optionGreekCache,
    IOptionMarket _optionMarket,
    IOptionMarketGovernanceWrapper _governanceWrapper
  ) Ownable2Step() {
    exchangeAdapter = _exchangeAdapter;
    liquidityPool = _liquidityPool;
    optionGreekCache = _optionGreekCache;
    optionMarket = _optionMarket;
    governanceWrapper = _governanceWrapper;
  }

  ///////////
  // Admin //
  ///////////
  function setRiskCouncil(address _riskCouncil) external onlyOwner {
    riskCouncil = _riskCouncil;
    emit LM_RiskCouncilSet(_riskCouncil);
  }

  function setQueueParams(uint _boardQueueTime, uint _strikeQueueTime, uint _queueStaleTime) external onlyOwner {
    boardQueueTime = _boardQueueTime;
    strikeQueueTime = _strikeQueueTime;
    queueStaleTime = _queueStaleTime;
    emit LM_QueueParamsSet(_boardQueueTime, _strikeQueueTime, _queueStaleTime);
  }

  function setMaxScaledMoneyness(uint _maxScaledMoneyness) external onlyOwner {
    maxScaledMoneyness = _maxScaledMoneyness;
    emit LM_MaxScaledMoneynessSet(maxScaledMoneyness);
  }

  /////////////////////
  // onlyRiskCouncil //
  /////////////////////

  /// @notice Forcefully remove the QueuedStrikes for given boardId
  function vetoStrikeUpdate(uint boardId) external onlyRiskCouncil {
    emit LM_StrikeUpdateVetoed(boardId, queuedStrikes[boardId]);
    delete queuedStrikes[boardId];
  }

  /// @notice Forcefully remove the QueuedBoard for given expiry
  function vetoQueuedBoard(uint expiry) external onlyRiskCouncil {
    emit LM_BoardVetoed(expiry, queuedBoards[expiry]);
    delete queuedBoards[expiry];
  }

  /// @notice Bypass the delay for adding strikes to a board, execute immediately
  function fastForwardStrikeUpdate(uint boardId, uint executionLimit) external onlyRiskCouncil {
    _executeQueuedStrikes(boardId, executionLimit);
  }

  /// @notice Bypass the delay for adding a new board, execute immediately
  function fastForwardQueuedBoard(uint expiry) external onlyRiskCouncil {
    _executeQueuedBoard(expiry);
  }

  ////////////////////////////
  // Execute queued strikes //
  ////////////////////////////

  function executeQueuedStrikes(uint boardId, uint executionLimit) public {
    if (isCBActive()) {
      emit LM_CBClearQueuedStrikes(msg.sender, boardId);
      delete queuedStrikes[boardId];
      return;
    }

    if (queuedStrikes[boardId].queuedTime + queueStaleTime + strikeQueueTime < block.timestamp) {
      emit LM_QueuedStrikesStale(
        msg.sender, boardId, queuedStrikes[boardId].queuedTime + queueStaleTime + strikeQueueTime, block.timestamp
        );

      delete queuedStrikes[boardId];
      return;
    }

    if (queuedStrikes[boardId].queuedTime + strikeQueueTime > block.timestamp) {
      revert LM_TooEarlyToExecuteStrike(boardId, queuedStrikes[boardId].queuedTime, block.timestamp);
    }
    _executeQueuedStrikes(boardId, executionLimit);
  }

  function _executeQueuedStrikes(uint boardId, uint executionLimit) internal {
    uint strikesLength = queuedStrikes[boardId].strikesToAdd.length;
    uint numToExecute = strikesLength > executionLimit ? executionLimit : strikesLength;

    for (uint i = strikesLength; i > strikesLength - numToExecute; --i) {
      governanceWrapper.addStrikeToBoard(
        boardId, queuedStrikes[boardId].strikesToAdd[i - 1].strikePrice, queuedStrikes[boardId].strikesToAdd[i - 1].skew
      );
      emit LM_QueuedStrikeExecuted(msg.sender, boardId, queuedStrikes[boardId].strikesToAdd[i - 1]);
      queuedStrikes[boardId].strikesToAdd.pop();
    }

    if (queuedStrikes[boardId].strikesToAdd.length == 0) {
      emit LM_QueuedStrikesAllExecuted(msg.sender, boardId);
      delete queuedStrikes[boardId];
    }
  }

  //////////////////////////
  // Execute queued board //
  //////////////////////////

  function executeQueuedBoard(uint expiry) public {
    if (isCBActive()) {
      emit LM_CBClearQueuedBoard(msg.sender, expiry);
      delete queuedBoards[expiry];
      return;
    }

    QueuedBoard memory queuedBoard = queuedBoards[expiry];
    if (queuedBoard.expiry == 0) {
      revert LM_BoardNotQueued(expiry);
    }

    // if it is stale (staleQueueTime), delete the entry
    if (queuedBoard.queuedTime + boardQueueTime + queueStaleTime < block.timestamp) {
      emit LM_QueuedBoardStale(
        msg.sender, expiry, queuedBoard.queuedTime + boardQueueTime + queueStaleTime, block.timestamp
        );
      delete queuedBoards[expiry];
      return;
    }

    // execute the queued board if the required time has passed
    if (queuedBoard.queuedTime + boardQueueTime > block.timestamp) {
      revert LM_TooEarlyToExecuteBoard(expiry, queuedBoard.queuedTime, block.timestamp);
    }

    _executeQueuedBoard(expiry);
  }

  function _executeQueuedBoard(uint expiry) internal {
    QueuedBoard memory queuedBoard = queuedBoards[expiry];
    uint[] memory strikes = new uint[](queuedBoard.strikesToAdd.length);
    uint[] memory skews = new uint[](queuedBoard.strikesToAdd.length);

    for (uint i; i < queuedBoard.strikesToAdd.length; i++) {
      strikes[i] = queuedBoard.strikesToAdd[i].strikePrice;
      skews[i] = queuedBoard.strikesToAdd[i].skew;
    }

    uint boardId = governanceWrapper.createOptionBoard(queuedBoard.expiry, queuedBoard.baseIv, strikes, skews, false);

    emit LM_QueuedBoardExecuted(msg.sender, boardId, queuedBoard);
    delete queuedBoards[expiry];
  }

  ///////////////////////
  // Queue new strikes //
  ///////////////////////

  // given no strikes queued for the board currently (and also check things like CBs in the liquidity pool)
  // for the given board, see if any strikes can be added based on the schema
  // if so; request the skews from the libraries
  // and then add to queue
  function findAndQueueStrikesForBoard(uint boardId) external {
    if (isCBActive()) {
      revert LM_CBActive(block.timestamp);
    }

    if (queuedStrikes[boardId].boardId != 0) {
      revert LM_strikesAlreadyQueued(boardId);
    }

    BoardDetails memory boardDetails = getBoardDetails(boardId);

    if (boardDetails.expiry < block.timestamp + NEW_STRIKE_MIN_EXPIRY) {
      revert LM_TooCloseToExpiry(boardDetails.expiry, boardId);
    }

    _queueNewStrikes(boardId, boardDetails);
  }

  function _queueNewStrikes(uint boardId, BoardDetails memory boardDetails) internal {
    uint spotPrice = _getSpotPrice();

    VolGenerator.Board memory board = _toVolGeneratorBoard(boardDetails);

    (uint[] memory newStrikes, uint numNewStrikes) = StrikePriceGenerator.getNewStrikes(
      _secToAnnualized(boardDetails.expiry - block.timestamp),
      spotPrice,
      maxScaledMoneyness,
      MAX_NUM_STRIKES,
      board.orderedStrikePrices,
      PIVOTS
    );

    if (numNewStrikes == 0) {
      revert LM_NoNewStrikesGenerated(boardId);
    }

    queuedStrikes[boardId].queuedTime = block.timestamp;
    queuedStrikes[boardId].boardId = boardId;

    for (uint i = 0; i < numNewStrikes; i++) {
      queuedStrikes[boardId].strikesToAdd.push(
        StrikeToAdd({strikePrice: newStrikes[i], skew: VolGenerator.getSkewForLiveBoard(newStrikes[i], board)})
      );
    }
  }

  /////////////////////
  // Queue new Board //
  /////////////////////

  function queueNewBoard(uint newExpiry) external {
    if (isCBActive()) {
      revert LM_CBActive(block.timestamp);
    }

    _validateNewBoardExpiry(newExpiry);

    if (queuedBoards[newExpiry].expiry != 0) {
      revert LM_BoardAlreadyQueued(newExpiry);
    }

    _queueNewBoard(newExpiry);
  }

  function _validateNewBoardExpiry(uint expiry) internal view {
    if (expiry < block.timestamp + NEW_BOARD_MIN_EXPIRY) {
      revert LM_ExpiryTooShort(expiry, NEW_BOARD_MIN_EXPIRY);
    }

    uint[] memory validExpiries = getValidExpiries();
    for (uint i = 0; i < validExpiries.length; ++i) {
      if (validExpiries[i] == expiry) {
        // matches a valid expiry. If the expiry already exists, it will be caught in _fetchSurroundingBoards()
        return;
      }
    }
    revert LM_ExpiryDoesntMatchFormat(expiry);
  }

  /// @dev Internal queueBoard function, assumes the expiry is valid (but does not know if the expiry is already used)
  function _queueNewBoard(uint newExpiry) internal {
    (uint baseIv, StrikeToAdd[] memory strikesToAdd) = _getNewBoardData(newExpiry);
    queuedBoards[newExpiry].queuedTime = block.timestamp;
    queuedBoards[newExpiry].expiry = newExpiry;
    queuedBoards[newExpiry].baseIv = baseIv;
    for (uint i = 0; i < strikesToAdd.length; i++) {
      queuedBoards[newExpiry].strikesToAdd.push(strikesToAdd[i]);
    }
  }

  function _getNewBoardData(uint expiry) internal view returns (uint baseIv, StrikeToAdd[] memory strikesToAdd) {
    uint spotPrice = _getSpotPrice();

    (uint[] memory newStrikes, uint numNewStrikes) = StrikePriceGenerator.getNewStrikes(
      _secToAnnualized(expiry - block.timestamp), spotPrice, maxScaledMoneyness, MAX_NUM_STRIKES, new uint[](0), PIVOTS
    );

    BoardDetails[] memory boardDetails = getAllBoardDetails();

    (VolGenerator.Board memory shortDated, VolGenerator.Board memory longDated) =
      _fetchSurroundingBoards(boardDetails, expiry);

    if (shortDated.orderedSkews.length == 0) {
      return _extrapolateBoard(spotPrice, expiry, newStrikes, numNewStrikes, longDated);
    } else if (longDated.orderedSkews.length == 0) {
      return _extrapolateBoard(spotPrice, expiry, newStrikes, numNewStrikes, shortDated);
    } else {
      // assume theres at least one board - _fetchSurroundingBoards will revert if there are no live boards.
      return _interpolateBoard(spotPrice, expiry, newStrikes, numNewStrikes, shortDated, longDated);
    }
  }

  /// @notice Gets the closest board on both sides of the given expiry, converting them to the format required for the vol generator
  function _fetchSurroundingBoards(BoardDetails[] memory boardDetails, uint expiry)
    internal
    view
    returns (VolGenerator.Board memory shortDated, VolGenerator.Board memory longDated)
  {
    if (boardDetails.length == 0) {
      revert LM_NoBoards();
    }

    uint shortIndex = type(uint).max;
    uint longIndex = type(uint).max;
    for (uint i = 0; i < boardDetails.length; i++) {
      BoardDetails memory current = boardDetails[i];
      if (current.expiry < expiry) {
        // If the board's expiry is less than the expiry we want to add - it is a shortDated board
        if (shortIndex == type(uint).max || boardDetails[shortIndex].expiry < current.expiry) {
          // If the current board is closer, update to the current board
          shortIndex = i;
        }
      } else if (current.expiry > expiry) {
        // If the board's expiry is larger than the expiry we want to add - it is a longDated board
        if (longIndex == type(uint).max || boardDetails[longIndex].expiry > current.expiry) {
          longIndex = i;
        }
      } else {
        revert LM_ExpiryExists(expiry);
      }
    }

    // At this point, one of short/long is guaranteed to be set - as the boardDetails length is > 0
    // and the expiry being used already causes reverts
    if (longIndex != type(uint).max) {
      longDated = _toVolGeneratorBoard(boardDetails[longIndex]);
    }

    if (shortIndex != type(uint).max) {
      shortDated = _toVolGeneratorBoard(boardDetails[shortIndex]);
    }
    return (shortDated, longDated);
  }

  /// @notice Get the baseIv and skews for
  function _interpolateBoard(
    uint spotPrice,
    uint expiry,
    uint[] memory newStrikes,
    uint numNewStrikes,
    VolGenerator.Board memory shortDated,
    VolGenerator.Board memory longDated
  ) internal view returns (uint baseIv, StrikeToAdd[] memory strikesToAdd) {
    uint tteAnnualised = _secToAnnualized(expiry - block.timestamp);

    // Note: we treat the default ATM skew as 1.0, by passing in baseIv as 1, we can determine what the "skew" should be
    // if baseIv is 1. Then we flip the equation to get the baseIv for a skew of 1.0.
    baseIv = VolGenerator.getSkewForNewBoard(spotPrice, tteAnnualised, DecimalMath.UNIT, shortDated, longDated);

    strikesToAdd = new StrikeToAdd[](numNewStrikes);
    for (uint i = 0; i < numNewStrikes; ++i) {
      strikesToAdd[i] = StrikeToAdd({
        strikePrice: newStrikes[i],
        skew: VolGenerator.getSkewForNewBoard(newStrikes[i], tteAnnualised, baseIv, shortDated, longDated)
      });
    }
  }

  function _extrapolateBoard(
    uint spotPrice,
    uint expiry,
    uint[] memory newStrikes,
    uint numNewStrikes,
    VolGenerator.Board memory edgeBoard
  ) internal view returns (uint baseIv, StrikeToAdd[] memory strikesToAdd) {
    uint tteAnnualised = _secToAnnualized(expiry - block.timestamp);

    // Note: we treat the default ATM skew as 1.0, by passing in baseIv as 1, we can determine what the "skew" should be
    // if baseIv is 1. Then we flip the equation to get the baseIv for a skew of 1.0.
    baseIv = VolGenerator.getSkewForNewBoard(spotPrice, tteAnnualised, DecimalMath.UNIT, spotPrice, edgeBoard);

    strikesToAdd = new StrikeToAdd[](numNewStrikes);

    for (uint i = 0; i < numNewStrikes; ++i) {
      strikesToAdd[i] = StrikeToAdd({
        strikePrice: newStrikes[i],
        skew: VolGenerator.getSkewForNewBoard(newStrikes[i], tteAnnualised, baseIv, spotPrice, edgeBoard)
      });
    }
  }

  ///////////
  // Utils //
  ///////////

  function _toVolGeneratorBoard(BoardDetails memory details) internal view returns (VolGenerator.Board memory) {
    uint numStrikes = details.strikes.length;

    _quickSortStrikes(details.strikes, 0, int(numStrikes - 1));

    uint[] memory orderedStrikePrices = new uint[](numStrikes);
    uint[] memory orderedSkews = new uint[](numStrikes);

    for (uint i = 0; i < numStrikes; i++) {
      orderedStrikePrices[i] = details.strikes[i].strikePrice;
      orderedSkews[i] = details.strikes[i].skew;
    }

    return VolGenerator.Board({
      // This will revert for expired boards
      tAnnualized: _secToAnnualized(details.expiry - block.timestamp),
      baseIv: details.baseIv,
      orderedStrikePrices: orderedStrikePrices,
      orderedSkews: orderedSkews
    });
  }

  ///////////////////////////
  // Lyra Protocol getters //
  ///////////////////////////

  function getAllBoardDetails() public view returns (BoardDetails[] memory boardDetails) {
    uint[] memory liveBoards = optionMarket.getLiveBoards();
    boardDetails = new BoardDetails[](liveBoards.length);
    for (uint i = 0; i < liveBoards.length; ++i) {
      boardDetails[i] = getBoardDetails(liveBoards[i]);
    }
    return boardDetails;
  }

  function getBoardDetails(uint boardId) public view returns (BoardDetails memory boardDetails) {
    (IOptionMarket.OptionBoard memory board, IOptionMarket.Strike[] memory strikes,,,) =
      optionMarket.getBoardAndStrikeDetails(boardId);

    IOptionGreekCache.BoardGreeksView memory boardGreeks = optionGreekCache.getBoardGreeksView(boardId);

    StrikeDetails[] memory strikeDetails = new StrikeDetails[](strikes.length);
    for (uint i = 0; i < strikes.length; ++i) {
      strikeDetails[i] = StrikeDetails({strikePrice: strikes[i].strikePrice, skew: boardGreeks.skewGWAVs[i]});
    }
    return BoardDetails({expiry: board.expiry, baseIv: boardGreeks.ivGWAV, strikes: strikeDetails});
  }

  function _getSpotPrice() internal view returns (uint spotPrice) {
    return exchangeAdapter.getSpotPriceForMarket(address(optionMarket), IBaseExchangeAdapter.PriceType.REFERENCE);
  }

  function isCBActive() internal view returns (bool) {
    return liquidityPool.CBTimestamp() > block.timestamp;
  }

  ///////////
  // Views //
  ///////////

  function getQueuedBoard(uint expiry) external view returns (QueuedBoard memory) {
    return queuedBoards[expiry];
  }

  function getQueuedStrikes(uint boardId) external view returns (QueuedStrikes memory) {
    return queuedStrikes[boardId];
  }

  function getValidExpiries() public view returns (uint[] memory validExpiries) {
    return ExpiryGenerator.getExpiries(NUM_WEEKLIES, NUM_MONTHLIES, block.timestamp, LAST_FRIDAYS);
  }

  //////////
  // Misc //
  //////////

  function _secToAnnualized(uint sec) public pure returns (uint) {
    return (sec * DecimalMath.UNIT) / uint(365 days);
  }

  function _quickSortStrikes(StrikeDetails[] memory arr, int left, int right) internal pure {
    int i = left;
    int j = right;
    if (i == j) {
      return;
    }
    uint pivot = arr[uint(left + (right - left) / 2)].strikePrice;
    while (i <= j) {
      while (arr[uint(i)].strikePrice < pivot) {
        i++;
      }
      while (pivot < arr[uint(j)].strikePrice) {
        j--;
      }
      if (i <= j) {
        (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
        i++;
        j--;
      }
    }
    if (left < j) {
      _quickSortStrikes(arr, left, j);
    }
    if (i < right) {
      _quickSortStrikes(arr, i, right);
    }
  }

  ///////////
  // Views //
  ///////////

  function viewBoardToBeQueued(uint newExpiry) external view returns (uint baseIv, StrikeToAdd[] memory strikesToAdd) {
    _validateNewBoardExpiry(newExpiry);
    return _getNewBoardData(newExpiry);
  }

  function viewStrikesToBeQueued(uint boardId) external view returns (StrikeToAdd[] memory strikesToAdd) {
    BoardDetails memory boardDetails = getBoardDetails(boardId);
    VolGenerator.Board memory board = _toVolGeneratorBoard(boardDetails);

    (uint[] memory newStrikes, uint numNewStrikes) = StrikePriceGenerator.getNewStrikes(
      _secToAnnualized(boardDetails.expiry - block.timestamp),
      _getSpotPrice(),
      maxScaledMoneyness,
      MAX_NUM_STRIKES,
      board.orderedStrikePrices,
      PIVOTS
    );

    strikesToAdd = new StrikeToAdd[](newStrikes.length);

    for (uint i = 0; i < numNewStrikes; i++) {
      strikesToAdd[i] =
        StrikeToAdd({strikePrice: newStrikes[i], skew: VolGenerator.getSkewForLiveBoard(newStrikes[i], board)});
    }
  }

  ///////////////
  // Modifiers //
  ///////////////
  modifier onlyRiskCouncil() {
    if (msg.sender != riskCouncil) {
      revert LM_OnlyRiskCouncil(msg.sender);
    }
    _;
  }

  /////////////
  // Events ///
  /////////////

  event LM_RiskCouncilSet(address indexed riskCouncil);
  event LM_QueueParamsSet(uint boardQueuedTime, uint strikesQueuedTime, uint staleTime);
  event LM_MaxScaledMoneynessSet(uint maxScaledMoneyness);
  event LM_StrikeUpdateVetoed(uint indexed boardId, QueuedStrikes exectuedStrike);
  event LM_BoardVetoed(uint indexed expiry, QueuedBoard queuedBoards);
  event LM_QueuedStrikeExecuted(address indexed caller, uint indexed boardId, StrikeToAdd strikeAdded);
  event LM_QueuedStrikesAllExecuted(address indexed caller, uint indexed boardId);
  event LM_QueuedBoardExecuted(address indexed caller, uint indexed expiry, QueuedBoard board);

  event LM_QueuedStrikesStale(address indexed caller, uint indexed boardId, uint staleTimestamp, uint blockTime);
  event LM_CBClearQueuedStrikes(address indexed caller, uint indexed boardId);

  event LM_QueuedBoardStale(address indexed caller, uint indexed expiry, uint staleTimestamp, uint blockTime);
  event LM_CBClearQueuedBoard(address indexed caller, uint indexed expiry);

  ////////////
  // Errors //
  ////////////

  error LM_ExpiryExists(uint expiry);

  error LM_BoardNotQueued(uint expiry);

  error LM_OnlyRiskCouncil(address sender);

  error LM_TooEarlyToExecuteStrike(uint boardId, uint queuedTime, uint blockTime);

  error LM_BoardStale(uint expiry, uint staleTime, uint blockTime);

  error LM_TooEarlyToExecuteBoard(uint expiry, uint queuedTime, uint blockTime);

  error LM_CBActive(uint blockTime);

  error LM_TooCloseToExpiry(uint expiry, uint boardId);

  error LM_BoardAlreadyQueued(uint expiry);

  error LM_ExpiryDoesntMatchFormat(uint expiry);

  error LM_ExpiryTooShort(uint expiry, uint minExpiry);

  error LM_NoBoards();

  error LM_NoNewStrikesGenerated(uint boardId);

  error LM_strikesAlreadyQueued(uint boardId);
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

abstract contract ListingManagerLibrarySettings {
  uint constant NEW_BOARD_MIN_EXPIRY = 7 days;
  uint constant NEW_STRIKE_MIN_EXPIRY = 2 days;
  uint constant NUM_WEEKLIES = 3;
  uint constant NUM_MONTHLIES = 3;
  uint constant MAX_NUM_STRIKES = 25;

  uint[] PIVOTS = [
    1e6,
    2e6,
    5e6,
    1e7,
    2e7,
    5e7,
    1e8,
    2e8,
    5e8,
    1e9,
    2e9,
    5e9,
    1e10,
    2e10,
    5e10,
    1e11,
    2e11,
    5e11,
    1e12,
    2e12,
    5e12,
    1e13,
    2e13,
    5e13,
    1e14,
    2e14,
    5e14,
    1e15,
    2e15,
    5e15,
    1e16,
    2e16,
    5e16,
    1e17,
    2e17,
    5e17,
    1e18,
    2e18,
    5e18,
    1e19,
    2e19,
    5e19,
    1e20,
    2e20,
    5e20,
    1e21,
    2e21,
    5e21,
    1e22,
    2e22,
    5e22,
    1e23,
    2e23,
    5e23,
    1e24,
    2e24,
    5e24,
    1e25,
    2e25,
    5e25,
    1e26,
    2e26,
    5e26,
    1e27,
    2e27,
    5e27,
    1e28,
    2e28,
    5e28,
    1e29,
    2e29,
    5e29,
    1e30,
    2e30,
    5e30,
    1e31,
    2e31,
    5e31,
    1e32,
    2e32,
    5e32,
    1e33,
    2e33,
    5e33,
    1e34,
    2e34,
    5e34,
    1e35,
    2e35,
    5e35,
    1e36,
    2e36,
    5e36,
    1e37,
    2e37,
    5e37,
    1e38,
    2e38,
    5e38,
    1e39,
    2e39,
    5e39,
    1e40,
    2e40,
    5e40,
    1e41,
    2e41,
    5e41,
    1e42,
    2e42,
    5e42,
    1e43,
    2e43,
    5e43,
    1e44,
    2e44,
    5e44,
    1e45,
    2e45,
    5e45,
    1e46,
    2e46,
    5e46,
    1e47,
    2e47,
    5e47,
    1e48,
    2e48,
    5e48,
    1e49,
    2e49,
    5e49
  ];

  uint[] LAST_FRIDAYS = [
    1674806400,
    1677225600,
    1680249600,
    1682668800,
    1685088000,
    1688112000,
    1690531200,
    1692950400,
    1695974400,
    1698393600,
    1700812800,
    1703836800,
    1706256000,
    1708675200,
    1711699200,
    1714118400,
    1717142400,
    1719561600,
    1721980800,
    1725004800,
    1727424000,
    1729843200,
    1732867200,
    1735286400,
    1738310400,
    1740729600,
    1743148800,
    1745568000,
    1748592000,
    1751011200,
    1753430400,
    1756454400,
    1758873600,
    1761897600,
    1764316800,
    1766736000,
    1769760000,
    1772179200,
    1774598400,
    1777017600,
    1780041600,
    1782460800,
    1785484800,
    1787904000,
    1790323200,
    1793347200,
    1795766400,
    1798185600,
    1801209600,
    1803628800,
    1806048000,
    1809072000,
    1811491200,
    1813910400,
    1816934400,
    1819353600,
    1821772800,
    1824796800,
    1827216000,
    1830240000,
    1832659200,
    1835078400,
    1838102400,
    1840521600,
    1842940800,
    1845964800,
    1848384000,
    1850803200,
    1853827200,
    1856246400,
    1858665600,
    1861689600,
    1864108800,
    1866528000,
    1869552000,
    1871971200,
    1874390400,
    1877414400,
    1879833600,
    1882857600,
    1885276800,
    1887696000,
    1890720000,
    1893139200,
    1895558400,
    1897977600,
    1901001600,
    1903420800,
    1906444800,
    1908864000,
    1911283200,
    1914307200,
    1916726400,
    1919145600,
    1922169600,
    1924588800,
    1927612800,
    1930032000,
    1932451200,
    1934870400,
    1937894400,
    1940313600,
    1942732800,
    1945756800,
    1948176000,
    1951200000,
    1953619200,
    1956038400,
    1959062400,
    1961481600,
    1963900800,
    1966924800,
    1969344000,
    1971763200,
    1974787200,
    1977206400,
    1979625600,
    1982649600,
    1985068800,
    1988092800,
    1990512000,
    1992931200,
    1995350400,
    1998374400,
    2000793600,
    2003212800,
    2006236800,
    2008656000,
    2011680000,
    2014099200,
    2016518400,
    2019542400,
    2021961600,
    2024380800,
    2027404800,
    2029824000,
    2032243200,
    2035267200,
    2037686400,
    2040105600,
    2043129600,
    2045548800,
    2047968000,
    2050992000,
    2053411200,
    2055830400,
    2058854400,
    2061273600,
    2063692800,
    2066716800,
    2069136000,
    2072160000,
    2074579200,
    2076998400,
    2080022400,
    2082441600,
    2084860800,
    2087884800,
    2090304000,
    2092723200,
    2095747200,
    2098166400,
    2100585600,
    2103609600,
    2106028800,
    2109052800,
    2111472000,
    2113891200,
    2116915200,
    2119334400,
    2121753600,
    2124172800,
    2127196800,
    2129616000,
    2132640000,
    2135059200,
    2137478400,
    2140502400,
    2142921600,
    2145340800,
    2148364800,
    2150784000,
    2153203200,
    2156227200,
    2158646400,
    2161065600,
    2164089600,
    2166508800,
    2168928000,
    2171952000,
    2174371200,
    2177395200,
    2179814400,
    2182233600,
    2184652800,
    2187676800,
    2190096000,
    2192515200,
    2195539200,
    2197958400,
    2200982400,
    2203401600,
    2205820800,
    2208844800,
    2211264000,
    2213683200,
    2216707200,
    2219126400,
    2221545600,
    2224569600,
    2226988800,
    2230012800,
    2232432000,
    2234851200,
    2237875200,
    2240294400,
    2242713600,
    2245132800,
    2248156800,
    2250576000,
    2253600000,
    2256019200,
    2258438400,
    2261462400,
    2263881600,
    2266300800,
    2269324800,
    2271744000,
    2274768000,
    2277187200,
    2279606400,
    2282025600,
    2285049600,
    2287468800,
    2289888000,
    2292912000,
    2295331200,
    2298355200,
    2300774400,
    2303193600,
    2306217600,
    2308636800,
    2311056000,
    2313475200,
    2316499200,
    2318918400,
    2321942400,
    2324361600,
    2326780800,
    2329804800,
    2332224000,
    2334643200,
    2337667200,
    2340086400,
    2342505600,
    2345529600
  ];
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

interface IBaseExchangeAdapter {
  enum PriceType {
    MIN_PRICE, // minimise the spot based on logic in adapter - can revert
    MAX_PRICE, // maximise the spot based on logic in adapter
    REFERENCE,
    FORCE_MIN, // minimise the spot based on logic in adapter - shouldn't revert unless feeds are compromised
    FORCE_MAX
  }

  function getSpotPriceForMarket(address, PriceType) external view returns (uint spot);
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

interface ILiquidityPool {
  function CBTimestamp() external view returns (uint);
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

// For full documentation refer to @lyrafinance/protocol/contracts/interfaces/IOptionGreekCache.sol";
interface IOptionGreekCache {
  struct GreekCacheParameters {
    // Cap the number of strikes per board to avoid hitting gasLimit constraints
    uint maxStrikesPerBoard;
    // How much spot price can move since last update before deposits/withdrawals are blocked
    uint acceptableSpotPricePercentMove;
    // How much time has passed since last update before deposits/withdrawals are blocked
    uint staleUpdateDuration;
    // Length of the GWAV for the baseline volatility used to fire the vol circuit breaker
    uint varianceIvGWAVPeriod;
    // Length of the GWAV for the skew ratios used to fire the vol circuit breaker
    uint varianceSkewGWAVPeriod;
    // Length of the GWAV for the baseline used to determine the NAV of the pool
    uint optionValueIvGWAVPeriod;
    // Length of the GWAV for the skews used to determine the NAV of the pool
    uint optionValueSkewGWAVPeriod;
    // Minimum skew that will be fed into the GWAV calculation
    // Prevents near 0 values being used to heavily manipulate the GWAV
    uint gwavSkewFloor;
    // Maximum skew that will be fed into the GWAV calculation
    uint gwavSkewCap;
  }

  struct ForceCloseParameters {
    // Length of the GWAV for the baseline vol used in ForceClose() and liquidations
    uint ivGWAVPeriod;
    // Length of the GWAV for the skew ratio used in ForceClose() and liquidations
    uint skewGWAVPeriod;
    // When a user buys back an option using ForceClose() we increase the GWAV vol to penalise the trader
    uint shortVolShock;
    // Increase the penalty when within the trading cutoff
    uint shortPostCutoffVolShock;
    // When a user sells back an option to the AMM using ForceClose(), we decrease the GWAV to penalise the seller
    uint longVolShock;
    // Increase the penalty when within the trading cutoff
    uint longPostCutoffVolShock;
    // Same justification as shortPostCutoffVolShock
    uint liquidateVolShock;
    // Increase the penalty when within the trading cutoff
    uint liquidatePostCutoffVolShock;
    // Minimum price the AMM will sell back an option at for force closes (as a % of current spot)
    uint shortSpotMin;
    // Minimum price the AMM will sell back an option at for liquidations (as a % of current spot)
    uint liquidateSpotMin;
  }

  struct MinCollateralParameters {
    // Minimum collateral that must be posted for a short to be opened (denominated in quote)
    uint minStaticQuoteCollateral;
    // Minimum collateral that must be posted for a short to be opened (denominated in base)
    uint minStaticBaseCollateral;
    /* Shock Vol:
     * Vol used to compute the minimum collateral requirements for short positions.
     * This value is derived from the following chart, created by using the 4 values listed below.
     *
     *     vol
     *      |
     * volA |____
     *      |    \
     * volB |     \___
     *      |___________ time to expiry
     *         A   B
     */
    uint shockVolA;
    uint shockVolPointA;
    uint shockVolB;
    uint shockVolPointB;
    // Static percentage shock to the current spot price for calls
    uint callSpotPriceShock;
    // Static percentage shock to the current spot price for puts
    uint putSpotPriceShock;
  }

  ///////////////////
  // Cache storage //
  ///////////////////
  struct GlobalCache {
    uint minUpdatedAt;
    uint minUpdatedAtPrice;
    uint maxUpdatedAtPrice;
    uint maxSkewVariance;
    uint maxIvVariance;
    NetGreeks netGreeks;
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

  // These are based on GWAVed iv
  struct StrikeGreeks {
    int callDelta;
    int putDelta;
    uint stdVega;
    uint callPrice;
    uint putPrice;
  }

  // These are based on GWAVed iv
  struct NetGreeks {
    int netDelta;
    int netStdVega;
    int netOptionValue;
  }

  ///////////////
  // In-memory //
  ///////////////
  struct TradePricing {
    uint optionPrice;
    int preTradeAmmNetStdVega;
    int postTradeAmmNetStdVega;
    int callDelta;
    uint volTraded;
    uint ivVariance;
    uint vega;
  }

  struct BoardGreeksView {
    NetGreeks boardGreeks;
    uint ivGWAV;
    StrikeGreeks[] strikeGreeks;
    uint[] skewGWAVs;
  }

  /////////////////////////////
  // External View functions //
  /////////////////////////////

  function getBoardGreeksView(uint boardId) external view returns (BoardGreeksView memory);

  function getOptionBoardCache(uint boardId) external view returns (OptionBoardCache memory);
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

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

  /// @notice For returning more specific errors
  enum NonZeroValues {
    BASE_IV,
    SKEW,
    STRIKE_PRICE,
    ITERATIONS,
    STRIKE_ID
  }

  ///////////////////
  // Internal Data //
  ///////////////////

  struct Strike {
    // strike listing identifier
    uint id;
    // strike price
    uint strikePrice;
    // volatility component specific to the strike listing (boardIv * skew = vol of strike)
    uint skew;
    // total user long call exposure
    uint longCall;
    // total user short call (base collateral) exposure
    uint shortCallBase;
    // total user short call (quote collateral) exposure
    uint shortCallQuote;
    // total user long put exposure
    uint longPut;
    // total user short put (quote collateral) exposure
    uint shortPut;
    // id of board to which strike belongs
    uint boardId;
  }

  struct OptionBoard {
    // board identifier
    uint id;
    // expiry of all strikes belonging to board
    uint expiry;
    // volatility component specific to board (boardIv * skew = vol of strike)
    uint iv;
    // admin settable flag blocking all trading on this board
    bool frozen;
    // list of all strikes belonging to this board
    uint[] strikeIds;
  }

  ///////////////
  // In-memory //
  ///////////////

  struct OptionMarketParameters {
    // max allowable expiry of added boards
    uint maxBoardExpiry;
    // security module address
    address securityModule;
    // fee portion reserved for Lyra DAO
    uint feePortionReserved;
    // expected fee charged to LPs, used for pricing short_call_base settlement
    uint staticBaseSettlementFee;
  }

  struct TradeInputParameters {
    // id of strike
    uint strikeId;
    // OptionToken ERC721 id for position (set to 0 for new positions)
    uint positionId;
    // number of sub-orders to break order into (reduces slippage)
    uint iterations;
    // type of option to trade
    OptionType optionType;
    // number of contracts to trade
    uint amount;
    // final amount of collateral to leave in OptionToken position
    uint setCollateralTo;
    // revert trade if totalCost is below this value
    uint minTotalCost;
    // revert trade if totalCost is above this value
    uint maxTotalCost;
  }

  struct TradeEventData {
    uint expiry;
    uint strikePrice;
    OptionType optionType;
    TradeDirection tradeDirection;
    uint amount;
    uint setCollateralTo;
    bool isForceClose;
    uint spotPrice;
    uint reservedFee;
    uint totalCost;
  }

  struct LiquidationEventData {
    address rewardBeneficiary;
    address caller;
    uint returnCollateral; // quote || base
    uint lpPremiums; // quote || base
    uint lpFee; // quote || base
    uint liquidatorFee; // quote || base
    uint smFee; // quote || base
    uint insolventAmount; // quote
  }

  struct Result {
    uint positionId;
    uint totalCost;
    uint totalFee;
  }

  /**
   * @notice Returns board and strike details given a boardId
   *
   * @return board
   * @return boardStrikes
   * @return strikeToBaseReturnedRatios For each strike, the ratio of full base collateral to return to the trader
   * @return priceAtExpiry
   * @return longScaleFactor The amount to scale payouts for long options
   */
  function getBoardAndStrikeDetails(uint boardId)
    external
    view
    returns (OptionBoard memory, Strike[] memory, uint[] memory, uint, uint);

  function getLiveBoards() external view returns (uint[] memory);
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

import "./IOptionMarket.sol";

interface IOptionMarketGovernanceWrapper {
  function createOptionBoard(uint expiry, uint baseIV, uint[] memory strikePrices, uint[] memory skews, bool frozen)
    external
    returns (uint boardId);

  function addStrikeToBoard(uint boardId, uint strikePrice, uint skew) external;
}