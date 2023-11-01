// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Definition here allows both the lib and inheriting contracts to use BigNumber directly.
struct BigNumber { 
    bytes val;
    bool neg;
    uint bitlen;
}

/**
 * @notice BigNumbers library for Solidity.
 */
library BigNumbers {
    
    /// @notice the value for number 0 of a BigNumber instance.
    bytes constant ZERO = hex"0000000000000000000000000000000000000000000000000000000000000000";
    /// @notice the value for number 1 of a BigNumber instance.
    bytes constant  ONE = hex"0000000000000000000000000000000000000000000000000000000000000001";
    /// @notice the value for number 2 of a BigNumber instance.
    bytes constant  TWO = hex"0000000000000000000000000000000000000000000000000000000000000002";

    // ***************** BEGIN EXPOSED MANAGEMENT FUNCTIONS ******************
    /** @notice verify a BN instance
     *  @dev checks if the BN is in the correct format. operations should only be carried out on
     *       verified BNs, so it is necessary to call this if your function takes an arbitrary BN
     *       as input.
     *
     *  @param bn BigNumber instance
     */
    function verify(
        BigNumber memory bn
    ) internal pure {
        uint msword; 
        bytes memory val = bn.val;
        assembly {msword := mload(add(val,0x20))} //get msword of result
        if(msword==0) require(isZero(bn));
        else require((bn.val.length % 32 == 0) && (msword>>((bn.bitlen%256)-1)==1));
    }

    /** @notice initialize a BN instance
     *  @dev wrapper function for _init. initializes from bytes value.
     *       Allows passing bitLength of value. This is NOT verified in the internal function. Only use where bitlen is
     *       explicitly known; otherwise use the other init function.
     *
     *  @param val BN value. may be of any size.
     *  @param neg neg whether the BN is +/-
     *  @param bitlen bit length of output.
     *  @return BigNumber instance
     */
    function init(
        bytes memory val, 
        bool neg, 
        uint bitlen
    ) internal view returns(BigNumber memory){
        return _init(val, neg, bitlen);
    }
    
    /** @notice initialize a BN instance
     *  @dev wrapper function for _init. initializes from bytes value.
     *
     *  @param val BN value. may be of any size.
     *  @param neg neg whether the BN is +/-
     *  @return BigNumber instance
     */
    function init(
        bytes memory val, 
        bool neg
    ) internal view returns(BigNumber memory){
        return _init(val, neg, 0);
    }

    /** @notice initialize a BN instance
     *  @dev wrapper function for _init. initializes from uint value (converts to bytes); 
     *       tf. resulting BN is in the range -2^256-1 ... 2^256-1.
     *
     *  @param val uint value.
     *  @param neg neg whether the BN is +/-
     *  @return BigNumber instance
     */
    function init(
        uint val, 
        bool neg
    ) internal view returns(BigNumber memory){
        return _init(abi.encodePacked(val), neg, 0);
    }
    // ***************** END EXPOSED MANAGEMENT FUNCTIONS ******************




    // ***************** BEGIN EXPOSED CORE CALCULATION FUNCTIONS ******************
    /** @notice BigNumber addition: a + b.
      * @dev add: Initially prepare BigNumbers for addition operation; internally calls actual addition/subtraction,
      *           depending on inputs.
      *           In order to do correct addition or subtraction we have to handle the sign.
      *           This function discovers the sign of the result based on the inputs, and calls the correct operation.
      *
      * @param a first BN
      * @param b second BN
      * @return r result  - addition of a and b.
      */
    function add(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(BigNumber memory r) {
        if(a.bitlen==0 && b.bitlen==0) return zero();
        if(a.bitlen==0) return b;
        if(b.bitlen==0) return a;
        bytes memory val;
        uint bitlen;
        int compare = cmp(a,b,false);

        if(a.neg || b.neg){
            if(a.neg && b.neg){
                if(compare>=0) (val, bitlen) = _add(a.val,b.val,a.bitlen);
                else (val, bitlen) = _add(b.val,a.val,b.bitlen);
                r.neg = true;
            }
            else {
                if(compare==1){
                    (val, bitlen) = _sub(a.val,b.val);
                    r.neg = a.neg;
                }
                else if(compare==-1){
                    (val, bitlen) = _sub(b.val,a.val);
                    r.neg = !a.neg;
                }
                else return zero();//one pos and one neg, and same value.
            }
        }
        else{
            if(compare>=0){ // a>=b
                (val, bitlen) = _add(a.val,b.val,a.bitlen);
            }
            else {
                (val, bitlen) = _add(b.val,a.val,b.bitlen);
            }
            r.neg = false;
        }

        r.val = val;
        r.bitlen = (bitlen);
    }

    /** @notice BigNumber subtraction: a - b.
      * @dev sub: Initially prepare BigNumbers for subtraction operation; internally calls actual addition/subtraction,
                  depending on inputs.
      *           In order to do correct addition or subtraction we have to handle the sign.
      *           This function discovers the sign of the result based on the inputs, and calls the correct operation.
      *
      * @param a first BN
      * @param b second BN
      * @return r result - subtraction of a and b.
      */  
    function sub(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(BigNumber memory r) {
        if(a.bitlen==0 && b.bitlen==0) return zero();
        bytes memory val;
        int compare;
        uint bitlen;
        compare = cmp(a,b,false);
        if(a.neg || b.neg) {
            if(a.neg && b.neg){           
                if(compare == 1) { 
                    (val,bitlen) = _sub(a.val,b.val); 
                    r.neg = true;
                }
                else if(compare == -1) { 

                    (val,bitlen) = _sub(b.val,a.val); 
                    r.neg = false;
                }
                else return zero();
            }
            else {
                if(compare >= 0) (val,bitlen) = _add(a.val,b.val,a.bitlen);
                else (val,bitlen) = _add(b.val,a.val,b.bitlen);
                
                r.neg = (a.neg) ? true : false;
            }
        }
        else {
            if(compare == 1) {
                (val,bitlen) = _sub(a.val,b.val);
                r.neg = false;
             }
            else if(compare == -1) { 
                (val,bitlen) = _sub(b.val,a.val);
                r.neg = true;
            }
            else return zero(); 
        }
        
        r.val = val;
        r.bitlen = (bitlen);
    }

    /** @notice BigNumber multiplication: a * b.
      * @dev mul: takes two BigNumbers and multiplys them. Order is irrelevant.
      *              multiplication achieved using modexp precompile:
      *                 (a * b) = ((a + b)**2 - (a - b)**2) / 4
      *
      * @param a first BN
      * @param b second BN
      * @return r result - multiplication of a and b.
      */
    function mul(
        BigNumber memory a, 
        BigNumber memory b
    ) internal view returns(BigNumber memory r){
            
        BigNumber memory lhs = add(a,b);
        BigNumber memory fst = modexp(lhs, two(), _powModulus(lhs, 2)); // (a+b)^2
        
        // no need to do subtraction part of the equation if a == b; if so, it has no effect on final result.
        if(!eq(a,b)) {
            BigNumber memory rhs = sub(a,b);
            BigNumber memory snd = modexp(rhs, two(), _powModulus(rhs, 2)); // (a-b)^2
            r = _shr(sub(fst, snd) , 2); // (a * b) = (((a + b)**2 - (a - b)**2) / 4
        }
        else {
            r = _shr(fst, 2); // a==b ? (((a + b)**2 / 4
        }
    }

    /** @notice BigNumber division verification: a * b.
      * @dev div: takes three BigNumbers (a,b and result), and verifies that a/b == result.
      * Performing BigNumber division on-chain is a significantly expensive operation. As a result, 
      * we expose the ability to verify the result of a division operation, which is a constant time operation. 
      *              (a/b = result) == (a = b * result)
      *              Integer division only; therefore:
      *                verify ((b*result) + (a % (b*result))) == a.
      *              eg. 17/7 == 2:
      *                verify  (7*2) + (17 % (7*2)) == 17.
      * The function returns a bool on successful verification. The require statements will ensure that false can never
      *  be returned, however inheriting contracts may also want to put this function inside a require statement.
      *  
      * @param a first BigNumber
      * @param b second BigNumber
      * @param r result BigNumber
      * @return bool whether or not the operation was verified
      */
    function divVerify(
        BigNumber memory a, 
        BigNumber memory b, 
        BigNumber memory r
    ) internal view returns(bool) {

        // first do zero check.
        // if a<b (always zero) and r==zero (input check), return true.
        if(cmp(a, b, false) == -1){
            require(cmp(zero(), r, false)==0);
            return true;
        }

        // Following zero check:
        //if both negative: result positive
        //if one negative: result negative
        //if neither negative: result positive
        bool positiveResult = ( a.neg && b.neg ) || (!a.neg && !b.neg);
        require(positiveResult ? !r.neg : r.neg);
        
        // require denominator to not be zero.
        require(!(cmp(b,zero(),true)==0));
        
        // division result check assumes inputs are positive.
        // we have already checked for result sign so this is safe.
        bool[3] memory negs = [a.neg, b.neg, r.neg];
        a.neg = false;
        b.neg = false;
        r.neg = false;

        // do multiplication (b * r)
        BigNumber memory fst = mul(b,r);
        // check if we already have 'a' (ie. no remainder after division). if so, no mod necessary, and return true.
        if(cmp(fst,a,true)==0) return true;
        //a mod (b*r)
        BigNumber memory snd = modexp(a,one(),fst); 
        // ((b*r) + a % (b*r)) == a
        require(cmp(add(fst,snd),a,true)==0); 

        a.neg = negs[0];
        b.neg = negs[1];
        r.neg = negs[2];

        return true;
    }

    /** @notice BigNumber exponentiation: a ^ b.
      * @dev pow: takes a BigNumber and a uint (a,e), and calculates a^e.
      * modexp precompile is used to achieve a^e; for this is work, we need to work out the minimum modulus value 
      * such that the modulus passed to modexp is not used. the result of a^e can never be more than size bitlen(a) * e.
      * 
      * @param a BigNumber
      * @param e exponent
      * @return r result BigNumber
      */
    function pow(
        BigNumber memory a, 
        uint e
    ) internal view returns(BigNumber memory){
        return modexp(a, init(e, false), _powModulus(a, e));
    }

    /** @notice BigNumber modulus: a % n.
      * @dev mod: takes a BigNumber and modulus BigNumber (a,n), and calculates a % n.
      * modexp precompile is used to achieve a % n; an exponent of value '1' is passed.
      * @param a BigNumber
      * @param n modulus BigNumber
      * @return r result BigNumber
      */
    function mod(
        BigNumber memory a, 
        BigNumber memory n
    ) internal view returns(BigNumber memory){
      return modexp(a,one(),n);
    }

    /** @notice BigNumber modular exponentiation: a^e mod n.
      * @dev modexp: takes base, exponent, and modulus, internally computes base^exponent % modulus using the precompile at address 0x5, and creates new BigNumber.
      *              this function is overloaded: it assumes the exponent is positive. if not, the other method is used, whereby the inverse of the base is also passed.
      *
      * @param a base BigNumber
      * @param e exponent BigNumber
      * @param n modulus BigNumber
      * @return result BigNumber
      */    
    function modexp(
        BigNumber memory a, 
        BigNumber memory e, 
        BigNumber memory n
    ) internal view returns(BigNumber memory) {
        //if exponent is negative, other method with this same name should be used.
        //if modulus is negative or zero, we cannot perform the operation.
        require(  e.neg==false
                && n.neg==false
                && !isZero(n.val));

        bytes memory _result = _modexp(a.val,e.val,n.val);
        //get bitlen of result (TODO: optimise. we know bitlen is in the same byte as the modulus bitlen byte)
        uint bitlen = bitLength(_result);
        
        // if result is 0, immediately return.
        if(bitlen == 0) return zero();
        // if base is negative AND exponent is odd, base^exp is negative, and tf. result is negative;
        // in that case we make the result positive by adding the modulus.
        if(a.neg && isOdd(e)) return add(BigNumber(_result, true, bitlen), n);
        // in any other case we return the positive result.
        return BigNumber(_result, false, bitlen);
    }

    /** @notice BigNumber modular exponentiation with negative base: inv(a)==a_inv && a_inv^e mod n.
    /** @dev modexp: takes base, base inverse, exponent, and modulus, asserts inverse(base)==base inverse, 
      *              internally computes base_inverse^exponent % modulus and creates new BigNumber.
      *              this function is overloaded: it assumes the exponent is negative. 
      *              if not, the other method is used, where the inverse of the base is not passed.
      *
      * @param a base BigNumber
      * @param ai base inverse BigNumber
      * @param e exponent BigNumber
      * @param a modulus
      * @return BigNumber memory result.
      */ 
    function modexp(
        BigNumber memory a, 
        BigNumber memory ai, 
        BigNumber memory e, 
        BigNumber memory n) 
    internal view returns(BigNumber memory) {
        // base^-exp = (base^-1)^exp
        require(!a.neg && e.neg);

        //if modulus is negative or zero, we cannot perform the operation.
        require(!n.neg && !isZero(n.val));

        //base_inverse == inverse(base, modulus)
        require(modinvVerify(a, n, ai)); 
            
        bytes memory _result = _modexp(ai.val,e.val,n.val);
        //get bitlen of result (TODO: optimise. we know bitlen is in the same byte as the modulus bitlen byte)
        uint bitlen = bitLength(_result);

        // if result is 0, immediately return.
        if(bitlen == 0) return zero();
        // if base_inverse is negative AND exponent is odd, base_inverse^exp is negative, and tf. result is negative;
        // in that case we make the result positive by adding the modulus.
        if(ai.neg && isOdd(e)) return add(BigNumber(_result, true, bitlen), n);
        // in any other case we return the positive result.
        return BigNumber(_result, false, bitlen);
    }
 
    /** @notice modular multiplication: (a*b) % n.
      * @dev modmul: Takes BigNumbers for a, b, and modulus, and computes (a*b) % modulus
      *              We call mul for the two input values, before calling modexp, passing exponent as 1.
      *              Sign is taken care of in sub-functions.
      *
      * @param a BigNumber
      * @param b BigNumber
      * @param n Modulus BigNumber
      * @return result BigNumber
      */
    function modmul(
        BigNumber memory a, 
        BigNumber memory b, 
        BigNumber memory n) internal view returns(BigNumber memory) {       
        return mod(mul(a,b), n);       
    }

    /** @notice modular inverse verification: Verifies that (a*r) % n == 1.
      * @dev modinvVerify: Takes BigNumbers for base, modulus, and result, verifies (base*result)%modulus==1, and returns result.
      *              Similar to division, it's far cheaper to verify an inverse operation on-chain than it is to calculate it, so we allow the user to pass their own result.
      *
      * @param a base BigNumber
      * @param n modulus BigNumber
      * @param r result BigNumber
      * @return boolean result
      */
    function modinvVerify(
        BigNumber memory a, 
        BigNumber memory n, 
        BigNumber memory r
    ) internal view returns(bool) {
        require(!a.neg && !n.neg); //assert positivity of inputs.
        /*
         * the following proves:
         * - user result passed is correct for values base and modulus
         * - modular inverse exists for values base and modulus.
         * otherwise it fails.
         */        
        require(cmp(modmul(a, r, n),one(),true)==0);
        
        return true;
    }
    // ***************** END EXPOSED CORE CALCULATION FUNCTIONS ******************




    // ***************** START EXPOSED HELPER FUNCTIONS ******************
    /** @notice BigNumber odd number check
      * @dev isOdd: returns 1 if BigNumber value is an odd number and 0 otherwise.
      *              
      * @param a BigNumber
      * @return r Boolean result
      */  
    function isOdd(
        BigNumber memory a
    ) internal pure returns(bool r){
        assembly{
            let a_ptr := add(mload(a), mload(mload(a))) // go to least significant word
            r := mod(mload(a_ptr),2)                      // mod it with 2 (returns 0 or 1) 
        }
    }

    /** @notice BigNumber comparison
      * @dev cmp: Compares BigNumbers a and b. 'signed' parameter indiciates whether to consider the sign of the inputs.
      *           'trigger' is used to decide this - 
      *              if both negative, invert the result; 
      *              if both positive (or signed==false), trigger has no effect;
      *              if differing signs, we return immediately based on input.
      *           returns -1 on a<b, 0 on a==b, 1 on a>b.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @param signed whether to consider sign of inputs
      * @return int result
      */
    function cmp(
        BigNumber memory a, 
        BigNumber memory b, 
        bool signed
    ) internal pure returns(int){
        int trigger = 1;
        if(signed){
            if(a.neg && b.neg) trigger = -1;
            else if(a.neg==false && b.neg==true) return 1;
            else if(a.neg==true && b.neg==false) return -1;
        }

        if(a.bitlen>b.bitlen) return    trigger;   // 1*trigger
        if(b.bitlen>a.bitlen) return -1*trigger;

        uint a_ptr;
        uint b_ptr;
        uint a_word;
        uint b_word;

        uint len = a.val.length; //bitlen is same so no need to check length.

        assembly{
            a_ptr := add(mload(a),0x20) 
            b_ptr := add(mload(b),0x20)
        }

        for(uint i=0; i<len;i+=32){
            assembly{
                a_word := mload(add(a_ptr,i))
                b_word := mload(add(b_ptr,i))
            }

            if(a_word>b_word) return    trigger; // 1*trigger
            if(b_word>a_word) return -1*trigger; 

        }

        return 0; //same value.
    }

    /** @notice BigNumber equality
      * @dev eq: returns true if a==b. sign always considered.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
    function eq(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==0) ? true : false;
    }

    /** @notice BigNumber greater than
      * @dev eq: returns true if a>b. sign always considered.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
    function gt(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==1) ? true : false;
    }

    /** @notice BigNumber greater than or equal to
      * @dev eq: returns true if a>=b. sign always considered.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
    function gte(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==1 || result==0) ? true : false;
    }

    /** @notice BigNumber less than
      * @dev eq: returns true if a<b. sign always considered.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
    function lt(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==-1) ? true : false;
    }

    /** @notice BigNumber less than or equal o
      * @dev eq: returns true if a<=b. sign always considered.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
    function lte(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==-1 || result==0) ? true : false;
    }

    /** @notice right shift BigNumber value
      * @dev shr: right shift BigNumber a by 'bits' bits.
             copies input value to new memory location before shift and calls _shr function after. 
      * @param a BigNumber value to shift
      * @param bits amount of bits to shift by
      * @return result BigNumber
      */
    function shr(
        BigNumber memory a, 
        uint bits
    ) internal view returns(BigNumber memory){
        require(!a.neg);
        return _shr(a, bits);
    }

    /** @notice right shift BigNumber memory 'dividend' by 'bits' bits.
      * @dev _shr: Shifts input value in-place, ie. does not create new memory. shr function does this.
      * right shift does not necessarily have to copy into a new memory location. where the user wishes the modify
      * the existing value they have in place, they can use this.  
      * @param bn value to shift
      * @param bits amount of bits to shift by
      * @return r result
      */
    function _shr(BigNumber memory bn, uint bits) internal view returns(BigNumber memory){
        uint length;
        assembly { length := mload(mload(bn)) }

        // if bits is >= the bitlength of the value the result is always 0
        if(bits >= bn.bitlen) return BigNumber(ZERO,false,0); 
        
        // set bitlen initially as we will be potentially modifying 'bits'
        bn.bitlen = bn.bitlen-(bits);

        // handle shifts greater than 256:
        // if bits is greater than 256 we can simply remove any trailing words, by altering the BN length. 
        // we also update 'bits' so that it is now in the range 0..256.
        assembly {
            if or(gt(bits, 0x100), eq(bits, 0x100)) {
                length := sub(length, mul(div(bits, 0x100), 0x20))
                mstore(mload(bn), length)
                bits := mod(bits, 0x100)
            }

            // if bits is multiple of 8 (byte size), we can simply use identity precompile for cheap memcopy.
            // otherwise we shift each word, starting at the least signifcant word, one-by-one using the mask technique.
            // TODO it is possible to do this without the last two operations, see SHL identity copy.
            let bn_val_ptr := mload(bn)
            switch eq(mod(bits, 8), 0)
              case 1 {  
                  let bytes_shift := div(bits, 8)
                  let in          := mload(bn)
                  let inlength    := mload(in)
                  let insize      := add(inlength, 0x20)
                  let out         := add(in,     bytes_shift)
                  let outsize     := sub(insize, bytes_shift)
                  let success     := staticcall(450, 0x4, in, insize, out, insize)
                  mstore8(add(out, 0x1f), 0) // maintain our BN layout following identity call:
                  mstore(in, inlength)         // set current length byte to 0, and reset old length.
              }
              default {
                  let mask
                  let lsw
                  let mask_shift := sub(0x100, bits)
                  let lsw_ptr := add(bn_val_ptr, length)   
                  for { let i := length } eq(eq(i,0),0) { i := sub(i, 0x20) } { // for(int i=max_length; i!=0; i-=32)
                      switch eq(i,0x20)                                         // if i==32:
                          case 1 { mask := 0 }                                  //    - handles lsword: no mask needed.
                          default { mask := mload(sub(lsw_ptr,0x20)) }          //    - else get mask (previous word)
                      lsw := shr(bits, mload(lsw_ptr))                          // right shift current by bits
                      mask := shl(mask_shift, mask)                             // left shift next significant word by mask_shift
                      mstore(lsw_ptr, or(lsw,mask))                             // store OR'd mask and shifted bits in-place
                      lsw_ptr := sub(lsw_ptr, 0x20)                             // point to next bits.
                  }
              }

            // The following removes the leading word containing all zeroes in the result should it exist, 
            // as well as updating lengths and pointers as necessary.
            let msw_ptr := add(bn_val_ptr,0x20)
            switch eq(mload(msw_ptr), 0) 
                case 1 {
                   mstore(msw_ptr, sub(mload(bn_val_ptr), 0x20)) // store new length in new position
                   mstore(bn, msw_ptr)                           // update pointer from bn
                }
                default {}
        }
    

        return bn;
    }

    /** @notice left shift BigNumber value
      * @dev shr: left shift BigNumber a by 'bits' bits.
                  ensures the value is not negative before calling the private function.
      * @param a BigNumber value to shift
      * @param bits amount of bits to shift by
      * @return result BigNumber
      */
    function shl(
        BigNumber memory a, 
        uint bits
    ) internal view returns(BigNumber memory){
        require(!a.neg);
        return _shl(a, bits);
    }

    /** @notice sha3 hash a BigNumber.
      * @dev hash: takes a BigNumber and performs sha3 hash on it.
      *            we hash each BigNumber WITHOUT it's first word - first word is a pointer to the start of the bytes value,
      *            and so is different for each struct.
      *             
      * @param a BigNumber
      * @return h bytes32 hash.
      */
    function hash(
        BigNumber memory a
    ) internal pure returns(bytes32 h) {
        //amount of words to hash = all words of the value and three extra words: neg, bitlen & value length.     
        assembly {
            h := keccak256( add(a,0x20), add (mload(mload(a)), 0x60 ) ) 
        }
    }

    /** @notice BigNumber full zero check
      * @dev isZero: checks if the BigNumber is in the default zero format for BNs (ie. the result from zero()).
      *             
      * @param a BigNumber
      * @return boolean result.
      */
    function isZero(
        BigNumber memory a
    ) internal pure returns(bool) {
        return isZero(a.val) && a.val.length==0x20 && !a.neg && a.bitlen == 0;
    }


    /** @notice bytes zero check
      * @dev isZero: checks if input bytes value resolves to zero.
      *             
      * @param a bytes value
      * @return boolean result.
      */
    function isZero(
        bytes memory a
    ) internal pure returns(bool) {
        uint msword;
        uint msword_ptr;
        assembly {
            msword_ptr := add(a,0x20)
        }
        for(uint i=0; i<a.length; i+=32) {
            assembly { msword := mload(msword_ptr) } // get msword of input
            if(msword > 0) return false;
            assembly { msword_ptr := add(msword_ptr, 0x20) }
        }
        return true;

    }

    /** @notice BigNumber value bit length
      * @dev bitLength: returns BigNumber value bit length- ie. log2 (most significant bit of value)
      *             
      * @param a BigNumber
      * @return uint bit length result.
      */
    function bitLength(
        BigNumber memory a
    ) internal pure returns(uint){
        return bitLength(a.val);
    }

    /** @notice bytes bit length
      * @dev bitLength: returns bytes bit length- ie. log2 (most significant bit of value)
      *             
      * @param a bytes value
      * @return r uint bit length result.
      */
    function bitLength(
        bytes memory a
    ) internal pure returns(uint r){
        if(isZero(a)) return 0;
        uint msword; 
        assembly {
            msword := mload(add(a,0x20))               // get msword of input
        }
        r = bitLength(msword);                         // get bitlen of msword, add to size of remaining words.
        assembly {                                           
            r := add(r, mul(sub(mload(a), 0x20) , 8))  // res += (val.length-32)*8;  
        }
    }

    /** @notice uint bit length
        @dev bitLength: get the bit length of a uint input - ie. log2 (most significant bit of 256 bit value (one EVM word))
      *                       credit: Tjaden Hess @ ethereum.stackexchange             
      * @param a uint value
      * @return r uint bit length result.
      */
    function bitLength(
        uint a
    ) internal pure returns (uint r){
        assembly {
            switch eq(a, 0)
            case 1 {
                r := 0
            }
            default {
                let arg := a
                a := sub(a,1)
                a := or(a, div(a, 0x02))
                a := or(a, div(a, 0x04))
                a := or(a, div(a, 0x10))
                a := or(a, div(a, 0x100))
                a := or(a, div(a, 0x10000))
                a := or(a, div(a, 0x100000000))
                a := or(a, div(a, 0x10000000000000000))
                a := or(a, div(a, 0x100000000000000000000000000000000))
                a := add(a, 1)
                let m := mload(0x40)
                mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
                mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
                mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
                mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
                mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
                mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
                mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
                mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
                mstore(0x40, add(m, 0x100))
                let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
                let shift := 0x100000000000000000000000000000000000000000000000000000000000000
                let _a := div(mul(a, magic), shift)
                r := div(mload(add(m,sub(255,_a))), shift)
                r := add(r, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
                // where a is a power of two, result needs to be incremented. we use the power of two trick here: if(arg & arg-1 == 0) ++r;
                if eq(and(arg, sub(arg, 1)), 0) {
                    r := add(r, 1) 
                }
            }
        }
    }

    /** @notice BigNumber zero value
        @dev zero: returns zero encoded as a BigNumber
      * @return zero encoded as BigNumber
      */
    function zero(
    ) internal pure returns(BigNumber memory) {
        return BigNumber(ZERO, false, 0);
    }

    /** @notice BigNumber one value
        @dev one: returns one encoded as a BigNumber
      * @return one encoded as BigNumber
      */
    function one(
    ) internal pure returns(BigNumber memory) {
        return BigNumber(ONE, false, 1);
    }

    /** @notice BigNumber two value
        @dev two: returns two encoded as a BigNumber
      * @return two encoded as BigNumber
      */
    function two(
    ) internal pure returns(BigNumber memory) {
        return BigNumber(TWO, false, 2);
    }
    // ***************** END EXPOSED HELPER FUNCTIONS ******************





    // ***************** START PRIVATE MANAGEMENT FUNCTIONS ******************
    /** @notice Create a new BigNumber.
        @dev init: overloading allows caller to obtionally pass bitlen where it is known - as it is cheaper to do off-chain and verify on-chain. 
      *            we assert input is in data structure as defined above, and that bitlen, if passed, is correct.
      *            'copy' parameter indicates whether or not to copy the contents of val to a new location in memory (for example where you pass 
      *            the contents of another variable's value in)
      * @param val bytes - bignum value.
      * @param neg bool - sign of value
      * @param bitlen uint - bit length of value
      * @return r BigNumber initialized value.
      */
    function _init(
        bytes memory val, 
        bool neg, 
        uint bitlen
    ) private view returns(BigNumber memory r){ 
        // use identity at location 0x4 for cheap memcpy.
        // grab contents of val, load starting from memory end, update memory end pointer.
        assembly {
            let data := add(val, 0x20)
            let length := mload(val)
            let out
            let freemem := msize()
            switch eq(mod(length, 0x20), 0)                       // if(val.length % 32 == 0)
                case 1 {
                    out     := add(freemem, 0x20)                 // freememory location + length word
                    mstore(freemem, length)                       // set new length 
                }
                default { 
                    let offset  := sub(0x20, mod(length, 0x20))   // offset: 32 - (length % 32)
                    out     := add(add(freemem, offset), 0x20)    // freememory location + offset + length word
                    mstore(freemem, add(length, offset))          // set new length 
                }
            pop(staticcall(450, 0x4, data, length, out, length))  // copy into 'out' memory location
            mstore(0x40, add(freemem, add(mload(freemem), 0x20))) // update the free memory pointer
            
            // handle leading zero words. assume freemem is pointer to bytes value
            let bn_length := mload(freemem)
            for { } eq ( eq(bn_length, 0x20), 0) { } {            // for(; length!=32; length-=32)
             switch eq(mload(add(freemem, 0x20)),0)               // if(msword==0):
                    case 1 { freemem := add(freemem, 0x20) }      //     update length pointer
                    default { break }                             // else: loop termination. non-zero word found
                bn_length := sub(bn_length,0x20)                          
            } 
            mstore(freemem, bn_length)                             

            mstore(r, freemem)                                    // store new bytes value in r
            mstore(add(r, 0x20), neg)                             // store neg value in r
        }

        r.bitlen = bitlen == 0 ? bitLength(r.val) : bitlen;
    }
    // ***************** END PRIVATE MANAGEMENT FUNCTIONS ******************





    // ***************** START PRIVATE CORE CALCULATION FUNCTIONS ******************
    /** @notice takes two BigNumber memory values and the bitlen of the max value, and adds them.
      * @dev _add: This function is private and only callable from add: therefore the values may be of different sizes,
      *            in any order of size, and of different signs (handled in add).
      *            As values may be of different sizes, inputs are considered starting from the least significant 
      *            words, working back. 
      *            The function calculates the new bitlen (basically if bitlens are the same for max and min, 
      *            max_bitlen++) and returns a new BigNumber memory value.
      *
      * @param max bytes -  biggest value  (determined from add)
      * @param min bytes -  smallest value (determined from add)
      * @param max_bitlen uint - bit length of max value.
      * @return bytes result - max + min.
      * @return uint - bit length of result.
      */
    function _add(
        bytes memory max, 
        bytes memory min, 
        uint max_bitlen
    ) private pure returns (bytes memory, uint) {
        bytes memory result;
        assembly {

            let result_start := msize()                                       // Get the highest available block of memory
            let carry := 0
            let uint_max := sub(0,1)

            let max_ptr := add(max, mload(max))
            let min_ptr := add(min, mload(min))                               // point to last word of each byte array.

            let result_ptr := add(add(result_start,0x20), mload(max))         // set result_ptr end.

            for { let i := mload(max) } eq(eq(i,0),0) { i := sub(i, 0x20) } { // for(int i=max_length; i!=0; i-=32)
                let max_val := mload(max_ptr)                                 // get next word for 'max'
                switch gt(i,sub(mload(max),mload(min)))                       // if(i>(max_length-min_length)). while 
                                                                              // 'min' words are still available.
                    case 1{ 
                        let min_val := mload(min_ptr)                         //      get next word for 'min'
                        mstore(result_ptr, add(add(max_val,min_val),carry))   //      result_word = max_word+min_word+carry
                        switch gt(max_val, sub(uint_max,sub(min_val,carry)))  //      this switch block finds whether or
                                                                              //      not to set the carry bit for the
                                                                              //      next iteration.
                            case 1  { carry := 1 }
                            default {
                                switch and(eq(max_val,uint_max),or(gt(carry,0), gt(min_val,0)))
                                case 1 { carry := 1 }
                                default{ carry := 0 }
                            }
                            
                        min_ptr := sub(min_ptr,0x20)                       //       point to next 'min' word
                    }
                    default{                                               // else: remainder after 'min' words are complete.
                        mstore(result_ptr, add(max_val,carry))             //       result_word = max_word+carry
                        
                        switch and( eq(uint_max,max_val), eq(carry,1) )    //       this switch block finds whether or 
                                                                           //       not to set the carry bit for the 
                                                                           //       next iteration.
                            case 1  { carry := 1 }
                            default { carry := 0 }
                    }
                result_ptr := sub(result_ptr,0x20)                         // point to next 'result' word
                max_ptr := sub(max_ptr,0x20)                               // point to next 'max' word
            }

            switch eq(carry,0) 
                case 1{ result_start := add(result_start,0x20) }           // if carry is 0, increment result_start, ie.
                                                                           // length word for result is now one word 
                                                                           // position ahead.
                default { mstore(result_ptr, 1) }                          // else if carry is 1, store 1; overflow has
                                                                           // occured, so length word remains in the 
                                                                           // same position.

            result := result_start                                         // point 'result' bytes value to the correct
                                                                           // address in memory.
            mstore(result,add(mload(max),mul(0x20,carry)))                 // store length of result. we are finished 
                                                                           // with the byte array.
            
            mstore(0x40, add(result,add(mload(result),0x20)))              // Update freemem pointer to point to new 
                                                                           // end of memory.

            // we now calculate the result's bit length.
            // with addition, if we assume that some a is at least equal to some b, then the resulting bit length will
            // be a's bit length or (a's bit length)+1, depending on carry bit.this is cheaper than calling bitLength.
            let msword := mload(add(result,0x20))                             // get most significant word of result
            // if(msword==1 || msword>>(max_bitlen % 256)==1):
            if or( eq(msword, 1), eq(shr(mod(max_bitlen,256),msword),1) ) {
                    max_bitlen := add(max_bitlen, 1)                          // if msword's bit length is 1 greater 
                                                                              // than max_bitlen, OR overflow occured,
                                                                              // new bitlen is max_bitlen+1.
                }
        }
        

        return (result, max_bitlen);
    }

    /** @notice takes two BigNumber memory values and subtracts them.
      * @dev _sub: This function is private and only callable from add: therefore the values may be of different sizes, 
      *            in any order of size, and of different signs (handled in add).
      *            As values may be of different sizes, inputs are considered starting from the least significant words,
      *            working back. 
      *            The function calculates the new bitlen (basically if bitlens are the same for max and min, 
      *            max_bitlen++) and returns a new BigNumber memory value.
      *
      * @param max bytes -  biggest value  (determined from add)
      * @param min bytes -  smallest value (determined from add)
      * @return bytes result - max + min.
      * @return uint - bit length of result.
      */
    function _sub(
        bytes memory max, 
        bytes memory min
    ) internal pure returns (bytes memory, uint) {
        bytes memory result;
        uint carry = 0;
        uint uint_max = type(uint256).max;
        assembly {
                
            let result_start := msize()                                     // Get the highest available block of 
                                                                            // memory
        
            let max_len := mload(max)
            let min_len := mload(min)                                       // load lengths of inputs
            
            let len_diff := sub(max_len,min_len)                            // get differences in lengths.
            
            let max_ptr := add(max, max_len)
            let min_ptr := add(min, min_len)                                // go to end of arrays
            let result_ptr := add(result_start, max_len)                    // point to least significant result 
                                                                            // word.
            let memory_end := add(result_ptr,0x20)                          // save memory_end to update free memory
                                                                            // pointer at the end.
            
            for { let i := max_len } eq(eq(i,0),0) { i := sub(i, 0x20) } {  // for(int i=max_length; i!=0; i-=32)
                let max_val := mload(max_ptr)                               // get next word for 'max'
                switch gt(i,len_diff)                                       // if(i>(max_length-min_length)). while
                                                                            // 'min' words are still available.
                    case 1{ 
                        let min_val := mload(min_ptr)                       //  get next word for 'min'
        
                        mstore(result_ptr, sub(sub(max_val,min_val),carry)) //  result_word = (max_word-min_word)-carry
                    
                        switch or(lt(max_val, add(min_val,carry)), 
                               and(eq(min_val,uint_max), eq(carry,1)))      //  this switch block finds whether or 
                                                                            //  not to set the carry bit for the next iteration.
                            case 1  { carry := 1 }
                            default { carry := 0 }
                            
                        min_ptr := sub(min_ptr,0x20)                        //  point to next 'result' word
                    }
                    default {                                               // else: remainder after 'min' words are complete.

                        mstore(result_ptr, sub(max_val,carry))              //      result_word = max_word-carry
                    
                        switch and( eq(max_val,0), eq(carry,1) )            //      this switch block finds whether or 
                                                                            //      not to set the carry bit for the 
                                                                            //      next iteration.
                            case 1  { carry := 1 }
                            default { carry := 0 }

                    }
                result_ptr := sub(result_ptr,0x20)                          // point to next 'result' word
                max_ptr    := sub(max_ptr,0x20)                             // point to next 'max' word
            }      

            //the following code removes any leading words containing all zeroes in the result.
            result_ptr := add(result_ptr,0x20)                                                 

            // for(result_ptr+=32;; result==0; result_ptr+=32)
            for { }   eq(mload(result_ptr), 0) { result_ptr := add(result_ptr,0x20) } { 
               result_start := add(result_start, 0x20)                      // push up the start pointer for the result
               max_len := sub(max_len,0x20)                                 // subtract a word (32 bytes) from the 
                                                                            // result length.
            } 

            result := result_start                                          // point 'result' bytes value to 
                                                                            // the correct address in memory
            
            mstore(result,max_len)                                          // store length of result. we 
                                                                            // are finished with the byte array.
            
            mstore(0x40, memory_end)                                        // Update freemem pointer.
        }

        uint new_bitlen = bitLength(result);                                // calculate the result's 
                                                                            // bit length.
        
        return (result, new_bitlen);
    }

    /** @notice gets the modulus value necessary for calculating exponetiation.
      * @dev _powModulus: we must pass the minimum modulus value which would return JUST the a^b part of the calculation
      *       in modexp. the rationale here is:
      *       if 'a' has n bits, then a^e has at most n*e bits.
      *       using this modulus in exponetiation will result in simply a^e.
      *       therefore the value may be many words long.
      *       This is done by:
      *         - storing total modulus byte length
      *         - storing first word of modulus with correct bit set
      *         - updating the free memory pointer to come after total length.
      *
      * @param a BigNumber base
      * @param e uint exponent
      * @return BigNumber modulus result
      */
    function _powModulus(
        BigNumber memory a, 
        uint e
    ) private pure returns(BigNumber memory){
        bytes memory _modulus = ZERO;
        uint mod_index;

        assembly {
            mod_index := mul(mload(add(a, 0x40)), e)               // a.bitlen * e is the max bitlength of result
            let first_word_modulus := shl(mod(mod_index, 256), 1)  // set bit in first modulus word.
            mstore(_modulus, mul(add(div(mod_index,256),1),0x20))  // store length of modulus
            mstore(add(_modulus,0x20), first_word_modulus)         // set first modulus word
            mstore(0x40, add(_modulus, add(mload(_modulus),0x20))) // update freemem pointer to be modulus index
                                                                   // + length
        }

        //create modulus BigNumber memory for modexp function
        return BigNumber(_modulus, false, mod_index); 
    }

    /** @notice Modular Exponentiation: Takes bytes values for base, exp, mod and calls precompile for (base^exp)%^mod
      * @dev modexp: Wrapper for built-in modexp (contract 0x5) as described here: 
      *              https://github.com/ethereum/EIPs/pull/198
      *
      * @param _b bytes base
      * @param _e bytes base_inverse 
      * @param _m bytes exponent
      * @param r bytes result.
      */
    function _modexp(
        bytes memory _b, 
        bytes memory _e, 
        bytes memory _m
    ) private view returns(bytes memory r) {
        assembly {
            
            let bl := mload(_b)
            let el := mload(_e)
            let ml := mload(_m)
            
            
            let freemem := mload(0x40) // Free memory pointer is always stored at 0x40
            
            
            mstore(freemem, bl)         // arg[0] = base.length @ +0
            
            mstore(add(freemem,32), el) // arg[1] = exp.length @ +32
            
            mstore(add(freemem,64), ml) // arg[2] = mod.length @ +64
            
            // arg[3] = base.bits @ + 96
            // Use identity built-in (contract 0x4) as a cheap memcpy
            let success := staticcall(450, 0x4, add(_b,32), bl, add(freemem,96), bl)
            
            // arg[4] = exp.bits @ +96+base.length
            let size := add(96, bl)
            success := staticcall(450, 0x4, add(_e,32), el, add(freemem,size), el)
            
            // arg[5] = mod.bits @ +96+base.length+exp.length
            size := add(size,el)
            success := staticcall(450, 0x4, add(_m,32), ml, add(freemem,size), ml)
            
            switch success case 0 { invalid() } //fail where we haven't enough gas to make the call

            // Total size of input = 96+base.length+exp.length+mod.length
            size := add(size,ml)
            // Invoke contract 0x5, put return value right after mod.length, @ +96
            success := staticcall(sub(gas(), 1350), 0x5, freemem, size, add(freemem, 0x60), ml)

            switch success case 0 { invalid() } //fail where we haven't enough gas to make the call

            let length := ml
            let msword_ptr := add(freemem, 0x60)

            ///the following code removes any leading words containing all zeroes in the result.
            for { } eq ( eq(length, 0x20), 0) { } {                   // for(; length!=32; length-=32)
                switch eq(mload(msword_ptr),0)                        // if(msword==0):
                    case 1 { msword_ptr := add(msword_ptr, 0x20) }    //     update length pointer
                    default { break }                                 // else: loop termination. non-zero word found
                length := sub(length,0x20)                          
            } 
            r := sub(msword_ptr,0x20)
            mstore(r, length)
            
            // point to the location of the return value (length, bits)
            //assuming mod length is multiple of 32, return value is already in the right format.
            mstore(0x40, add(add(96, freemem),ml)) //deallocate freemem pointer
        }        
    }
    // ***************** END PRIVATE CORE CALCULATION FUNCTIONS ******************





    // ***************** START PRIVATE HELPER FUNCTIONS ******************
    /** @notice left shift BigNumber memory 'dividend' by 'value' bits.
      * @param bn value to shift
      * @param bits amount of bits to shift by
      * @return r result
      */
    function _shl(
        BigNumber memory bn, 
        uint bits
    ) private view returns(BigNumber memory r) {
        if(bits==0 || bn.bitlen==0) return bn;
        
        // we start by creating an empty bytes array of the size of the output, based on 'bits'.
        // for that we must get the amount of extra words needed for the output.
        uint length = bn.val.length;
        // position of bitlen in most significnat word
        uint bit_position = ((bn.bitlen-1) % 256) + 1;
        // total extra words. we check if the bits remainder will add one more word.
        uint extra_words = (bits / 256) + ( (bits % 256) >= (256 - bit_position) ? 1 : 0);
        // length of output
        uint total_length = length + (extra_words * 0x20);

        r.bitlen = bn.bitlen+(bits);
        r.neg = bn.neg;
        bits %= 256;

        
        bytes memory bn_shift;
        uint bn_shift_ptr;
        // the following efficiently creates an empty byte array of size 'total_length'
        assembly {
            let freemem_ptr := mload(0x40)                // get pointer to free memory
            mstore(freemem_ptr, total_length)             // store bytes length
            let mem_end := add(freemem_ptr, total_length) // end of memory
            mstore(mem_end, 0)                            // store 0 at memory end
            bn_shift := freemem_ptr                       // set pointer to bytes
            bn_shift_ptr := add(bn_shift, 0x20)           // get bn_shift pointer
            mstore(0x40, add(mem_end, 0x20))              // update freemem pointer
        }

        // use identity for cheap copy if bits is multiple of 8.
        if(bits % 8 == 0) {
            // calculate the position of the first byte in the result.
            uint bytes_pos = ((256-(((bn.bitlen-1)+bits) % 256))-1) / 8;
            uint insize = (bn.bitlen / 8) + ((bn.bitlen % 8 != 0) ? 1 : 0);
            assembly {
              let in          := add(add(mload(bn), 0x20), div(sub(256, bit_position), 8))
              let out         := add(bn_shift_ptr, bytes_pos)
              let success     := staticcall(450, 0x4, in, insize, out, length)
            }
            r.val = bn_shift;
            return r;
        }


        uint mask;
        uint mask_shift = 0x100-bits;
        uint msw;
        uint msw_ptr;

       assembly {
           msw_ptr := add(mload(bn), 0x20)   
       }
        
       // handle first word before loop if the shift adds any extra words.
       // the loop would handle it if the bit shift doesn't wrap into the next word, 
       // so we check only for that condition.
       if((bit_position+bits) > 256){
           assembly {
              msw := mload(msw_ptr)
              mstore(bn_shift_ptr, shr(mask_shift, msw))
              bn_shift_ptr := add(bn_shift_ptr, 0x20)
           }
       }
        
       // as a result of creating the empty array we just have to operate on the words in the original bn.
       for(uint i=bn.val.length; i!=0; i-=0x20){                  // for each word:
           assembly {
               msw := mload(msw_ptr)                              // get most significant word
               switch eq(i,0x20)                                  // if i==32:
                   case 1 { mask := 0 }                           // handles msword: no mask needed.
                   default { mask := mload(add(msw_ptr,0x20)) }   // else get mask (next word)
               msw := shl(bits, msw)                              // left shift current msw by 'bits'
               mask := shr(mask_shift, mask)                      // right shift next significant word by mask_shift
               mstore(bn_shift_ptr, or(msw,mask))                 // store OR'd mask and shifted bits in-place
               msw_ptr := add(msw_ptr, 0x20)
               bn_shift_ptr := add(bn_shift_ptr, 0x20)
           }
       }

       r.val = bn_shift;
    }
    // ***************** END PRIVATE HELPER FUNCTIONS ******************
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./BigNumbers.sol";

// errors
error CTAThresholdOutOfBoundaries(
    uint256 revealThreshold,
    uint256 minRevealThreshold,
    uint256 maxRevealThreshold
);
error CTAInconsistentTLPIterations(uint256 timeLockPuzzleIterations);
error CTATimeToRevealOutOfBoundaries(
    uint256 timeToAllowReveal,
    uint256 minTimeToReveal,
    uint256 maxTimeToReveal
);
error CTAInvalidVerificators(
    uint256 verificatorsBytesLength,
    uint256 revealThreshold
);
error CTAInvalidGenerator();
error CTAInvalidShare();
error CTACannotMintExistentLeaderboard();
error CTACanOnlyJoinLeaderboardThatIsNotRevealed();
error CTACanOnlyJoinLeaderboardThatIsNotReadyToReveal();
error CTACanOnlyRevealLeaderboardThatIsNotRevealed();
error CTACannotRevealLeaderboardThatIsNotReadyToReveal();
error CTACannotRevealNonexistentLeaderboard();
error CTAOnlyHuntersCanReveal();
error CTATooSoonToRevealLeaderboard();
error CTASecretIsNotConsistentWithHash();
error CTAEncryptionKeyIsNotConsistentWithTLP();
error ERC721MetadataURIQueryForNonexistentToken();
error CTACannotJoinOrRevealNonexistentLeaderboard();
error CTAHunterAlreadyListed();
error CTANonexistentLeaderboard(uint256 tokenId);
error CTAPageRankNotConverged();

struct Leaderboard {
    bytes32 hash;
    uint256 secret;
    uint32 revealThreshold;
    uint64 mintTimestamp;
    uint64 timeToAllowReveal;
    Share[] shares;
    bytes generator;
    bytes blindingGenerator;
    bytes[] verificators;
    bytes timeLockedKey;
    bytes timeLockPuzzleModulus;
    bytes timeLockPuzzleBase;
    uint256 timeLockPuzzleIterations;
    bytes encryptedSecretCiphertext;
    bytes encryptedSecretIv;
}
struct GetLeaderboardQueryResult {
    Leaderboard leaderboard;
    bool revealed;
}

struct Share {
    address hunter;
    bytes index;
    bytes evaluation;
    uint256 timeWhenJoined;
}

struct JoinData {
    bytes32 secretHash;
    bytes indexBytes;
    bytes shareBytes;
    bytes blindingShareBytes;
}

struct MintData {
    JoinData joinData;
    bytes generatorBytes;
    bytes blindingGeneratorBytes;
    bytes[] verificatorsBytes;
    uint32 revealThreshold;
    uint256 timeToAllowReveal;
    bytes timeLockedKeyBytes;
    bytes timeLockPuzzleModulusBytes;
    bytes timeLockPuzzleBaseBytes;
    uint256 timeLockPuzzleIterations;
    bytes ciphertextBytes;
    bytes ivBytes;
}

struct RevealData {
    JoinData joinData;
    bytes[] interpolationInverses;
}

struct HunterLeaderboardIds {
    uint256[] tokenIds;
    uint256 publicSupply;
    uint256 privateSupply;
}

library Utils {
    using BigNumbers for *;
    using Utils for Leaderboard;

    // safe prime in RFC3526 https://datatracker.ietf.org/doc/rfc3526/
    bytes public constant COEFF_PRIME_BYTES =
        hex"FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7EDEE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3DC2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F83655D23DCA3AD961C62F356208552BB9ED529077096966D670C354E4ABC9804F1746C08CA18217C32905E462E36CE3BE39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF6955817183995497CEA956AE515D2261898FA051015728E5A8AACAA68FFFFFFFFFFFFFFFF";

    /**
     * @notice CTA leaderboard fetching common functinoality
     * @dev gets a leaderboard making sure it is valid for the given parameters
     * @param joinData Data including secretHash, indexBytes, shareBytes & blindingShareBytes
     * @param tokenIdToLeaderboardMap Token ID to leaderboard mapping\
     * @param hashToLeaderboardTokenIdMap Hash to token ID mapping
     */
    function checkAndGetExistentLeaderboard(
        JoinData memory joinData,
        mapping(uint256 => Leaderboard) storage tokenIdToLeaderboardMap,
        mapping(bytes32 => uint256) storage hashToLeaderboardTokenIdMap
    ) external view returns (Leaderboard storage) {
        Leaderboard storage _leaderboard = tokenIdToLeaderboardMap[
            hashToLeaderboardTokenIdMap[joinData.secretHash]
        ];
        bool leaderboardExists = _leaderboard.shares.length >= 1;

        if (!leaderboardExists) {
            revert CTACannotJoinOrRevealNonexistentLeaderboard();
        }

        bool isHunter = verifyIfHunterIsOnLeaderboard(_leaderboard);

        if (isHunter) {
            revert CTAHunterAlreadyListed();
        }

        bool validShare = vsssVerifyShare(
            joinData,
            _leaderboard.generator,
            _leaderboard.blindingGenerator,
            _leaderboard.verificators
        );

        if (!validShare) {
            revert CTAInvalidShare();
        }

        return _leaderboard;
    }

    function verifyIfHunterIsOnLeaderboard(
        Leaderboard storage leaderboard_
    ) public view returns (bool isHunter) {
        //checking if the hunter is already listed on the leaderboard
        for (uint256 i = 0; i < leaderboard_.shares.length; i++) {
            if (leaderboard_.shares[i].hunter == msg.sender) {
                isHunter = true;
                break;
            }
        }

        return isHunter;
    }

    /**
     * @notice VSSS verification
     * @dev verifies a share in a VSSS scheme using the verificators
     * @param joinData Data including indexBytes, shareBytes and blindingShareBytes
     * @param generatorBytes bytes memory
     * @param blindingGeneratorBytes bytes memory
     * @param verificatorsBytes bytes[] memory
     * @return bool
     */
    function vsssVerifyShare(
        JoinData memory joinData,
        bytes memory generatorBytes,
        bytes memory blindingGeneratorBytes,
        bytes[] memory verificatorsBytes
    ) public view returns (bool) {
        BigNumber memory coeffPrime = BigNumbers.init(COEFF_PRIME_BYTES, false);

        // shr is inplace
        BigNumber memory exponentPrime = BigNumbers
            .init(COEFF_PRIME_BYTES, false)
            .shr(1);

        BigNumber memory index = BigNumbers.init(joinData.indexBytes, false);
        BigNumber memory evaluation = BigNumbers.init(
            joinData.shareBytes,
            false
        );
        BigNumber memory blindingEvaluation = BigNumbers.init(
            joinData.blindingShareBytes,
            false
        );
        BigNumber memory addressNum = BigNumbers.init(
            uint160(msg.sender),
            false
        );
        BigNumber memory verificatorGenerator = BigNumbers.init(
            generatorBytes,
            false
        );

        BigNumber memory blindingGenerator = BigNumbers.init(
            blindingGeneratorBytes,
            false
        );

        BigNumber[] memory verificators = new BigNumber[](
            verificatorsBytes.length
        );

        for (uint256 i = 0; i < verificators.length; i++) {
            verificators[i] = BigNumbers.init(verificatorsBytes[i], false);
        }

        if (!index.eq(addressNum.mod(coeffPrime))) {
            return false;
        } else {
            BigNumber memory verification = calculateVerification(
                verificators,
                index,
                coeffPrime,
                exponentPrime
            );
            return
                verification.eq(
                    verificatorGenerator.modexp(evaluation, coeffPrime).modmul(
                        blindingGenerator.modexp(
                            blindingEvaluation,
                            coeffPrime
                        ),
                        coeffPrime
                    )
                );
        }
    }

    /**
     * @notice VSSS verification calculation
     * @dev calculates the verification from the verificators
     * @param verificators BigNumber[] memory
     * @param index BigNumber memory
     * @param coeffPrime BigNumber memory
     * @param exponentPrime BigNumber memory
     * @return BigNumber memory
     */
    function calculateVerification(
        BigNumber[] memory verificators,
        BigNumber memory index,
        BigNumber memory coeffPrime,
        BigNumber memory exponentPrime
    ) public view returns (BigNumber memory) {
        BigNumber memory verification = BigNumbers.one();
        BigNumber memory indexPower = BigNumbers.one();
        for (uint256 i = 0; i < verificators.length; i++) {
            verification = verification.modmul(
                verificators[i].modexp(indexPower, coeffPrime),
                coeffPrime
            );
            indexPower = indexPower.modmul(index, exponentPrime);
        }
        return verification;
    }

    /**
     * @notice VSSS secret integrity validation
     * @dev uses verificator to verify integrity of secret
     * @param secret uint256 memory
     * @param blindingSecretBytes bytes memory
     * @param firstVerificatorBytes bytes memory
     * @param generatorBytes bytes memory
     * @param blindingGeneratorBytes bytes memory
     * @return bool
     */
    function vsssValidateSecretIntegrity(
        uint256 secret,
        bytes memory blindingSecretBytes,
        bytes memory firstVerificatorBytes,
        bytes memory generatorBytes,
        bytes memory blindingGeneratorBytes
    ) external view returns (bool) {
        BigNumber memory secretBN = BigNumbers.init(secret, false);
        BigNumber memory blindingSecret = BigNumbers.init(
            blindingSecretBytes,
            false
        );
        BigNumber memory firstVerificator = BigNumbers.init(
            firstVerificatorBytes,
            false
        );
        BigNumber memory generator = BigNumbers.init(generatorBytes, false);
        BigNumber memory blindingGenerator = BigNumbers.init(
            blindingGeneratorBytes,
            false
        );
        BigNumber memory coeffPrime = BigNumbers.init(COEFF_PRIME_BYTES, false);

        return
            firstVerificator.eq(
                generator.modexp(secretBN, coeffPrime).modmul(
                    blindingGenerator.modexp(blindingSecret, coeffPrime),
                    coeffPrime
                )
            );
    }

    /**
     * @notice VSSS generator verification
     * @dev verifies if the generator in a VSSS has the expected order
     * @param generatorBytes bytes memory
     * @return bool
     */
    function vsssVerifyGeneratorOrder(
        bytes memory generatorBytes
    ) external view returns (bool) {
        BigNumber memory coeffPrime = BigNumbers.init(COEFF_PRIME_BYTES, false);

        // shr is inplace
        BigNumber memory exponentPrime = BigNumbers
            .init(COEFF_PRIME_BYTES, false)
            .shr(1);

        BigNumber memory generator = BigNumbers.init(generatorBytes, false);

        if (
            generator.mod(coeffPrime).eq(BigNumbers.one()) ||
            generator.mod(coeffPrime).eq(coeffPrime.sub(BigNumbers.one()))
        ) {
            return false;
        } else {
            return
                generator.modexp(exponentPrime, coeffPrime).eq(
                    BigNumbers.one()
                );
        }
    }

    /**
     * @notice VSSS interpolation
     * @dev interpolates secret from shares
     * @param shares Share[] memory
     * @param interpolationInversesBytes bytes[] memory
     * @return BigNumber memory
     */
    function vsssInterpolate(
        Share[] memory shares,
        bytes[] memory interpolationInversesBytes
    ) external view returns (uint256) {
        BigNumber[] memory indexes = new BigNumber[](shares.length);
        BigNumber[] memory evaluations = new BigNumber[](shares.length);

        BigNumber memory coeffPrime = BigNumbers.init(COEFF_PRIME_BYTES, false);

        BigNumber[] memory interpolationInverses = new BigNumber[](
            interpolationInversesBytes.length
        );

        for (uint256 i = 0; i < shares.length; i++) {
            indexes[i] = BigNumbers.init(shares[i].index, false);
        }

        for (uint256 i = 0; i < shares.length; i++) {
            evaluations[i] = BigNumbers.init(shares[i].evaluation, false);
        }

        for (uint256 i = 0; i < interpolationInversesBytes.length; i++) {
            interpolationInverses[i] = BigNumbers.init(
                interpolationInversesBytes[i],
                false
            );
        }
        BigNumber memory secret = BigNumbers.zero();

        for (uint256 i = 0; i < indexes.length; i++) {
            BigNumber memory numerator = BigNumbers.one();
            BigNumber memory denominator = BigNumbers.one();
            for (uint256 j = 0; j < indexes.length; j++) {
                if (j != i) {
                    numerator = numerator.modmul(
                        BigNumbers.zero().sub(indexes[j]),
                        coeffPrime
                    );
                    denominator = denominator.modmul(
                        indexes[i].sub(indexes[j]),
                        coeffPrime
                    );
                }
            }
            assert(
                denominator.modinvVerify(coeffPrime, interpolationInverses[i])
            );
            secret = secret
                .add(
                    numerator
                        .modmul(interpolationInverses[i], coeffPrime)
                        .modmul(evaluations[i], coeffPrime)
                )
                .mod(coeffPrime);
        }

        return uint256(bytes32(secret.val));
    }

    /**
     * @notice TLP key integrity validation
     * @dev uses modulus factorization to verify TLP instance
     * @param keyBytes bytes memory
     * @param pBytes bytes memory
     * @param qBytes bytes memory
     * @param timeLockedKeyBytes bytes memory
     * @param timeLockPuzzleBaseBytes bytes memory
     * @param timeLockPuzzleModulusBytes bytes memory
     * @param timeLockPuzzleIterations uint256
     * @return bool
     */
    function tlpValidateKeyIntegrity(
        bytes memory keyBytes,
        bytes memory pBytes,
        bytes memory qBytes,
        bytes memory timeLockedKeyBytes,
        bytes memory timeLockPuzzleBaseBytes,
        bytes memory timeLockPuzzleModulusBytes,
        uint256 timeLockPuzzleIterations
    ) external view returns (bool) {
        BigNumber memory key = BigNumbers.init(keyBytes, false);
        BigNumber memory p = BigNumbers.init(pBytes, false);
        BigNumber memory q = BigNumbers.init(qBytes, false);
        BigNumber memory timeLockedKey = BigNumbers.init(
            timeLockedKeyBytes,
            false
        );
        BigNumber memory timeLockPuzzleBase = BigNumbers.init(
            timeLockPuzzleBaseBytes,
            false
        );
        BigNumber memory timeLockPuzzleModulus = BigNumbers.init(
            timeLockPuzzleModulusBytes,
            false
        );
        BigNumber memory timeLockPuzzleIterationsBN = BigNumbers.init(
            timeLockPuzzleIterations,
            false
        );

        // check if factorization is correct
        if (!timeLockPuzzleModulus.eq(p.mul(q))) {
            return false;
        }

        BigNumber memory phi = p.sub(BigNumbers.one()).mul(
            q.sub(BigNumbers.one())
        );

        BigNumber memory reducedExponent = BigNumbers.two().modexp(
            timeLockPuzzleIterationsBN,
            phi
        );

        // check if TLP is consistent
        return
            timeLockedKey.eq(
                timeLockPuzzleBase
                    .modexp(reducedExponent, timeLockPuzzleModulus)
                    .add(key)
            );
    }

    /* solhint-disable quotes */
    function buildMain(
        string memory id,
        bool revealed
    ) public pure returns (string memory) {
        string memory textColor = revealed ? "#5EFE34" : "white";
        string memory rectColor = revealed ? "#1E4D13" : "black";

        return
            string.concat(
                '<g><rect fill="',
                rectColor,
                '" x="0" y="0" width="350" height="350"></rect>',
                '<text font-family="Arial, Helvetica, sans-serif" y="45%" x="50%" dominant-baseline="middle" text-anchor="middle" font-size="200%" font-weight="bold" fill="',
                textColor,
                '">CTA</text>',
                '<text font-family="Arial, Helvetica, sans-serif" y="55%" x="50%" dominant-baseline="middle" text-anchor="middle" font-size="200%" font-weight="bold" fill="',
                textColor,
                '">#',
                id,
                "</text>",
                "</g>"
            );
    }

    /*
     * @notice CTA build SVG function
     * @dev building the CTA svg image from the hash
     * @param uint256 tokenId
     * @return base64 encoded svg
     */
    function buildSVG(
        uint256 tokenId,
        bool revealed
    ) public pure returns (string memory) {
        string
            memory SVG_HEADER = '<svg xmlns="http://www.w3.org/2000/svg" height="350" width="350">';
        string memory SVG_FOOTER = "</svg>";

        string memory id = Strings.toString(tokenId);
        return
            Base64.encode(
                bytes(
                    string.concat(
                        SVG_HEADER,
                        buildMain(id, revealed),
                        SVG_FOOTER
                    )
                )
            );
    }

    /* solhint-enable quotes */

    /**
     * @notice converting the hash to a string of the 10 first chars
     * @dev convertion from bytes32 to array bytes(5) then abi.encodePacked donsen't work :/ i did it manually
     * @param bytes32_ bytes32
     * @return string memory
     */
    function hashPart(bytes32 bytes32_) internal pure returns (string memory) {
        bytes memory converted = abi.encodePacked("");
        string[16] memory _base = [
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "a",
            "b",
            "c",
            "d",
            "e",
            "f"
        ];
        for (uint256 i = 0; i < 5; i++) {
            converted = abi.encodePacked(
                converted,
                _base[uint8(bytes32_[i]) / _base.length]
            );
            converted = abi.encodePacked(
                converted,
                _base[uint8(bytes32_[i]) % _base.length]
            );
        }
        converted = abi.encodePacked("0x", converted);
        return string(converted);
    }

    /// @notice See {Cta-tokenURI}
    function tokenURI(
        uint256 tokenId,
        mapping(uint256 => Leaderboard) storage tokenIdToLeaderboardMap
    ) external view returns (string memory) {
        //creating the svg image and encoding in base64
        Leaderboard storage _leaderboard = tokenIdToLeaderboardMap[tokenId];
        string memory encodedSVG = buildSVG(tokenId, _leaderboard.isRevealed());
        bytes32 hash = tokenIdToLeaderboardMap[tokenId].hash;
        string memory attributes = "";
        string memory hunterAddress = "";
        string memory comma = "";
        string memory _hashPart = hashPart(hash);

        /* solhint-disable quotes */
        if (_leaderboard.shares.length >= 1) {
            for (uint256 i = 0; i < _leaderboard.shares.length; i++) {
                //add hunter address to attributes
                hunterAddress = Strings.toHexString(
                    uint160(_leaderboard.shares[i].hunter),
                    20
                );
                attributes = string.concat(
                    attributes,
                    comma,
                    '{"trait_type": "',
                    Strings.toString(i),
                    '","value": "',
                    hunterAddress,
                    '"}'
                );
                comma = ",";
            }
        }

        string memory baseJson = string.concat(
            '{"name": "Capture The Alpha","description": "CTA is the first on-chain competition between alpha hunters","tokenId":"',
            Strings.toString(tokenId),
            '", "attributes" : [',
            attributes,
            ', {"trait_type": "isPrivate", "value":',
            !tokenIdToLeaderboardMap[tokenId].isRevealed() ? "true" : "false",
            '}, {"trait_type": "hash", "value": "',
            _hashPart,
            '" }],"image" : "data:image/svg+xml;base64,',
            encodedSVG,
            '"}'
        );
        /* solhint-enable quotes */

        //next step encoding for the tokenURI
        string memory jsonHeaderURI = "data:application/json;base64,";
        string memory encodedJson = string.concat(
            jsonHeaderURI,
            Base64.encode(bytes(baseJson))
        );

        //the result must be a string and not bytes data
        return encodedJson;
    }

    function isRevealed(
        Leaderboard storage leaderboard
    ) internal view returns (bool) {
        return leaderboard.secret != 0;
    }

    function getAdjacencyMatrix(
        uint256 size,
        uint256 supply,
        mapping(uint256 => Leaderboard) storage tokenIdToLeaderboardMap,
        address[] storage allHunters
    ) public view returns (int256[][] memory, uint256) {
        int256[][] memory matrix = new int256[][](size);
        for (uint256 i = 0; i < size; i++) {
            matrix[i] = new int256[](size);
        }

        uint256 publicSupply = 0;
        for (uint256 i = 1; i <= supply; i++) {
            Leaderboard storage _leaderboard = tokenIdToLeaderboardMap[i];

            // We only consider public leaderboards
            if (!_leaderboard.isRevealed()) {
                continue;
            }

            publicSupply += 1;
            address firstAddress = _leaderboard.shares[0].hunter;
            uint256 startIndex = 1;
            uint256 indexIn = getHunterIndex(
                firstAddress,
                startIndex,
                allHunters
            );
            for (uint256 j = 1; j < _leaderboard.shares.length; j++) {
                uint256 indexOut = getHunterIndex(
                    _leaderboard.shares[j].hunter,
                    startIndex,
                    allHunters
                );
                matrix[indexIn][indexOut] = matrix[indexIn][indexOut] + 1;
            }
        }

        return (matrix, publicSupply);
    }

    function getHunterIndex(
        address hunter,
        uint256 startIndex,
        address[] storage allHunters
    ) public view returns (uint256) {
        uint256 defaultIndex = 0;
        for (uint256 j = startIndex; j < allHunters.length; j++) {
            if (allHunters[j] == hunter) {
                return j;
            }
        }
        return defaultIndex;
    }
}