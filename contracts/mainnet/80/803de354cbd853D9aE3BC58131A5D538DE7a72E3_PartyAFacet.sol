// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../storages/QuoteStorage.sol";

interface IPartyAEvents {
    event SendQuote(
        address partyA,
        uint256 quoteId,
        address[] partyBsWhiteList,
        uint256 symbolId,
        PositionType positionType,
        OrderType orderType,
        uint256 price,
        uint256 marketPrice,
        uint256 quantity,
        uint256 cva,
        uint256 lf,
        uint256 partyAmm,
        uint256 partyBmm,
        uint256 tradingFee,
        uint256 deadline
    );

    event ExpireQuote(QuoteStatus quoteStatus, uint256 quoteId);
    event RequestToCancelQuote(
        address partyA,
        address partyB,
        QuoteStatus quoteStatus,
        uint256 quoteId
    );

    event RequestToClosePosition(
        address partyA,
        address partyB,
        uint256 quoteId,
        uint256 closePrice,
        uint256 quantityToClose,
        OrderType orderType,
        uint256 deadline,
        QuoteStatus quoteStatus
    );

    event RequestToCancelCloseRequest(
        address partyA,
        address partyB,
        uint256 quoteId,
        QuoteStatus quoteStatus
    );

    event ForceCancelQuote(uint256 quoteId, QuoteStatus quoteStatus);

    event ForceCancelCloseRequest(uint256 quoteId, QuoteStatus quoteStatus);

    event ForceClosePosition(
        uint256 quoteId,
        address partyA,
        address partyB,
        uint256 filledAmount,
        uint256 closedPrice,
        QuoteStatus quoteStatus
    );
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "./PartyAFacetImpl.sol";
import "../../utils/Accessibility.sol";
import "../../utils/Pausable.sol";
import "./IPartyAEvents.sol";

contract PartyAFacet is Accessibility, Pausable, IPartyAEvents {
    function sendQuote(
        address[] memory partyBsWhiteList,
        uint256 symbolId,
        PositionType positionType,
        OrderType orderType,
        uint256 price,
        uint256 quantity,
        uint256 cva,
        uint256 lf,
        uint256 partyAmm,
        uint256 partyBmm,
        uint256 maxFundingRate,
        uint256 deadline,
        SingleUpnlAndPriceSig memory upnlSig
    ) external whenNotPartyAActionsPaused notLiquidatedPartyA(msg.sender) notSuspended(msg.sender) {
        uint256 quoteId = PartyAFacetImpl.sendQuote(
            partyBsWhiteList,
            symbolId,
            positionType,
            orderType,
            price,
            quantity,
            cva,
            lf,
            partyAmm,
            partyBmm,
            maxFundingRate,
            deadline,
            upnlSig
        );
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        emit SendQuote(
            msg.sender,
            quoteId,
            partyBsWhiteList,
            symbolId,
            positionType,
            orderType,
            price,
            upnlSig.price,
            quantity,
            quote.lockedValues.cva,
            quote.lockedValues.lf,
            quote.lockedValues.partyAmm,
            quote.lockedValues.partyBmm,
            quote.tradingFee,
            deadline
        );
    }

    function expireQuote(uint256[] memory expiredQuoteIds) external whenNotPartyAActionsPaused {
        QuoteStatus result;
        for (uint8 i; i < expiredQuoteIds.length; i++) {
            result = LibQuote.expireQuote(expiredQuoteIds[i]);
            emit ExpireQuote(result, expiredQuoteIds[i]);
        }
    }

    function requestToCancelQuote(uint256 quoteId)
        external
        whenNotPartyAActionsPaused
        onlyPartyAOfQuote(quoteId)
        notLiquidated(quoteId)
    {
        QuoteStatus result = PartyAFacetImpl.requestToCancelQuote(quoteId);
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        if (result == QuoteStatus.EXPIRED) {
            emit ExpireQuote(result, quoteId);
        } else if (result == QuoteStatus.CANCELED || result == QuoteStatus.CANCEL_PENDING) {
            emit RequestToCancelQuote(quote.partyA, quote.partyB, result, quoteId);
        }
    }

    function requestToClosePosition(
        uint256 quoteId,
        uint256 closePrice,
        uint256 quantityToClose,
        OrderType orderType,
        uint256 deadline
    ) external whenNotPartyAActionsPaused onlyPartyAOfQuote(quoteId) notLiquidated(quoteId) {
        PartyAFacetImpl.requestToClosePosition(
            quoteId,
            closePrice,
            quantityToClose,
            orderType,
            deadline
        );
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        emit RequestToClosePosition(
            quote.partyA,
            quote.partyB,
            quoteId,
            closePrice,
            quantityToClose,
            orderType,
            deadline,
            QuoteStatus.CLOSE_PENDING
        );
    }

    function requestToCancelCloseRequest(uint256 quoteId)
        external
        whenNotPartyAActionsPaused
        onlyPartyAOfQuote(quoteId)
        notLiquidated(quoteId)
    {
        QuoteStatus result = PartyAFacetImpl.requestToCancelCloseRequest(quoteId);
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        if (result == QuoteStatus.OPENED) {
            emit ExpireQuote(QuoteStatus.OPENED, quoteId);
        } else if (result == QuoteStatus.CANCEL_CLOSE_PENDING) {
            emit RequestToCancelCloseRequest(
                quote.partyA,
                quote.partyB,
                quoteId,
                QuoteStatus.CANCEL_CLOSE_PENDING
            );
        }
    }

    function forceCancelQuote(uint256 quoteId)
        external
        notLiquidated(quoteId)
        whenNotPartyAActionsPaused
    {
        PartyAFacetImpl.forceCancelQuote(quoteId);
        emit ForceCancelQuote(quoteId, QuoteStatus.CANCELED);
    }

    function forceCancelCloseRequest(uint256 quoteId)
        external
        notLiquidated(quoteId)
        whenNotPartyAActionsPaused
    {
        PartyAFacetImpl.forceCancelCloseRequest(quoteId);
        emit ForceCancelCloseRequest(quoteId, QuoteStatus.OPENED);
    }

    function forceClosePosition(uint256 quoteId, PairUpnlAndPriceSig memory upnlSig)
        external
        notLiquidated(quoteId)
        whenNotPartyAActionsPaused
    {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        uint256 filledAmount = quote.quantityToClose;
        uint256 requestedClosePrice = quote.requestedClosePrice;
        PartyAFacetImpl.forceClosePosition(quoteId, upnlSig);
        emit ForceClosePosition(
            quoteId,
            quote.partyA,
            quote.partyB,
            filledAmount,
            requestedClosePrice,
            quote.quoteStatus
        );
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../libraries/LibLockedValues.sol";
import "../../libraries/LibMuon.sol";
import "../../libraries/LibAccount.sol";
import "../../libraries/LibSolvency.sol";
import "../../libraries/LibQuote.sol";
import "../../storages/MAStorage.sol";
import "../../storages/QuoteStorage.sol";
import "../../storages/MuonStorage.sol";
import "../../storages/AccountStorage.sol";
import "../../storages/SymbolStorage.sol";

library PartyAFacetImpl {
    using LockedValuesOps for LockedValues;

    function sendQuote(
        address[] memory partyBsWhiteList,
        uint256 symbolId,
        PositionType positionType,
        OrderType orderType,
        uint256 price,
        uint256 quantity,
        uint256 cva,
        uint256 lf,
        uint256 partyAmm,
        uint256 partyBmm,
        uint256 maxFundingRate,
        uint256 deadline,
        SingleUpnlAndPriceSig memory upnlSig
    ) internal returns (uint256 currentId) {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        MAStorage.Layout storage maLayout = MAStorage.layout();
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();

        require(
            quoteLayout.partyAPendingQuotes[msg.sender].length < maLayout.pendingQuotesValidLength,
            "PartyAFacet: Number of pending quotes out of range"
        );
        require(symbolLayout.symbols[symbolId].isValid, "PartyAFacet: Symbol is not valid");
        require(deadline >= block.timestamp, "PartyAFacet: Low deadline");

        LockedValues memory lockedValues = LockedValues(cva, lf, partyAmm, partyBmm);
        uint256 tradingPrice = orderType == OrderType.LIMIT ? price : upnlSig.price;
        require(
            lockedValues.lf >=
                (symbolLayout.symbols[symbolId].minAcceptablePortionLF * lockedValues.totalForPartyA()) /
                    1e18,
            "PartyAFacet: LF is not enough"
        );

        require(
            lockedValues.totalForPartyA() >= symbolLayout.symbols[symbolId].minAcceptableQuoteValue,
            "PartyAFacet: Quote value is low"
        );
        for (uint8 i = 0; i < partyBsWhiteList.length; i++) {
            require(
                partyBsWhiteList[i] != msg.sender,
                "PartyAFacet: Sender isn't allowed in partyBWhiteList"
            );
        }

        LibMuon.verifyPartyAUpnlAndPrice(upnlSig, msg.sender, symbolId);

        int256 availableBalance = LibAccount.partyAAvailableForQuote(upnlSig.upnl, msg.sender);
        require(availableBalance > 0, "PartyAFacet: Available balance is lower than zero");
        require(
            uint256(availableBalance) >=
                lockedValues.totalForPartyA() +
                    ((quantity * tradingPrice * symbolLayout.symbols[symbolId].tradingFee) / 1e36),
            "PartyAFacet: insufficient available balance"
        );

        // lock funds the in middle of way
        accountLayout.pendingLockedBalances[msg.sender].add(lockedValues);
        currentId = ++quoteLayout.lastId;

        // create quote.
        Quote memory quote = Quote({
            id: currentId,
            partyBsWhiteList: partyBsWhiteList,
            symbolId: symbolId,
            positionType: positionType,
            orderType: orderType,
            openedPrice: 0,
            initialOpenedPrice: 0,
            requestedOpenPrice: price,
            marketPrice: upnlSig.price,
            quantity: quantity,
            closedAmount: 0,
            lockedValues: lockedValues,
            initialLockedValues: lockedValues,
            maxFundingRate: maxFundingRate,
            partyA: msg.sender,
            partyB: address(0),
            quoteStatus: QuoteStatus.PENDING,
            avgClosedPrice: 0,
            requestedClosePrice: 0,
            parentId: 0,
            createTimestamp: block.timestamp,
            statusModifyTimestamp: block.timestamp,
            quantityToClose: 0,
            lastFundingPaymentTimestamp: 0,
            deadline: deadline,
            tradingFee: symbolLayout.symbols[symbolId].tradingFee
        });
        quoteLayout.quoteIdsOf[msg.sender].push(currentId);
        quoteLayout.partyAPendingQuotes[msg.sender].push(currentId);
        quoteLayout.quotes[currentId] = quote;
        
        accountLayout.allocatedBalances[msg.sender] -= LibQuote.getTradingFee(currentId);
    }

    function requestToCancelQuote(uint256 quoteId) internal returns (QuoteStatus result) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        require(
            quote.quoteStatus == QuoteStatus.PENDING || quote.quoteStatus == QuoteStatus.LOCKED,
            "PartyAFacet: Invalid state"
        );

        if (block.timestamp > quote.deadline) {
            result = LibQuote.expireQuote(quoteId);
        } else if (quote.quoteStatus == QuoteStatus.PENDING) {
            quote.quoteStatus = QuoteStatus.CANCELED;
            accountLayout.allocatedBalances[quote.partyA] += LibQuote.getTradingFee(quote.id);
            accountLayout.pendingLockedBalances[quote.partyA].subQuote(quote);
            LibQuote.removeFromPartyAPendingQuotes(quote);
            result = QuoteStatus.CANCELED;
        } else {
            // Quote is locked
            quote.quoteStatus = QuoteStatus.CANCEL_PENDING;
            result = QuoteStatus.CANCEL_PENDING;
        }
        quote.statusModifyTimestamp = block.timestamp;
    }

    function requestToClosePosition(
        uint256 quoteId,
        uint256 closePrice,
        uint256 quantityToClose,
        OrderType orderType,
        uint256 deadline
    ) internal {
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        require(quote.quoteStatus == QuoteStatus.OPENED, "PartyAFacet: Invalid state");
        require(deadline >= block.timestamp, "PartyAFacet: Low deadline");
        require(
            LibQuote.quoteOpenAmount(quote) >= quantityToClose,
            "PartyAFacet: Invalid quantityToClose"
        );

        // check that remaining position is not too small
        if (LibQuote.quoteOpenAmount(quote) > quantityToClose) {
            require(
                ((LibQuote.quoteOpenAmount(quote) - quantityToClose) * quote.lockedValues.totalForPartyA()) /
                    LibQuote.quoteOpenAmount(quote) >=
                    symbolLayout.symbols[quote.symbolId].minAcceptableQuoteValue,
                "PartyAFacet: Remaining quote value is low"
            );
        }

        quote.statusModifyTimestamp = block.timestamp;
        quote.quoteStatus = QuoteStatus.CLOSE_PENDING;
        quote.requestedClosePrice = closePrice;
        quote.quantityToClose = quantityToClose;
        quote.orderType = orderType;
        quote.deadline = deadline;
    }

    function requestToCancelCloseRequest(uint256 quoteId) internal returns (QuoteStatus) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        require(quote.quoteStatus == QuoteStatus.CLOSE_PENDING, "PartyAFacet: Invalid state");
        if (block.timestamp > quote.deadline) {
            LibQuote.expireQuote(quoteId);
            return QuoteStatus.OPENED;
        } else {
            quote.statusModifyTimestamp = block.timestamp;
            quote.quoteStatus = QuoteStatus.CANCEL_CLOSE_PENDING;
            return QuoteStatus.CANCEL_CLOSE_PENDING;
        }
    }

    function forceCancelQuote(uint256 quoteId) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        MAStorage.Layout storage maLayout = MAStorage.layout();
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        require(quote.quoteStatus == QuoteStatus.CANCEL_PENDING, "PartyAFacet: Invalid state");
        require(
            block.timestamp > quote.statusModifyTimestamp + maLayout.forceCancelCooldown,
            "PartyAFacet: Cooldown not reached"
        );
        quote.statusModifyTimestamp = block.timestamp;
        quote.quoteStatus = QuoteStatus.CANCELED;
        accountLayout.pendingLockedBalances[quote.partyA].subQuote(quote);
        accountLayout.partyBPendingLockedBalances[quote.partyB][quote.partyA].subQuote(quote);

        // send trading Fee back to partyA
        accountLayout.allocatedBalances[quote.partyA] += LibQuote.getTradingFee(quote.id);

        LibQuote.removeFromPendingQuotes(quote);
    }

    function forceCancelCloseRequest(uint256 quoteId) internal {
        MAStorage.Layout storage maLayout = MAStorage.layout();
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        require(
            quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING,
            "PartyAFacet: Invalid state"
        );
        require(
            block.timestamp > quote.statusModifyTimestamp + maLayout.forceCancelCloseCooldown,
            "PartyAFacet: Cooldown not reached"
        );

        quote.statusModifyTimestamp = block.timestamp;
        quote.quoteStatus = QuoteStatus.OPENED;
        quote.requestedClosePrice = 0;
        quote.quantityToClose = 0;
    }

    function forceClosePosition(uint256 quoteId, PairUpnlAndPriceSig memory upnlSig) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        MAStorage.Layout storage maLayout = MAStorage.layout();
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        uint256 filledAmount = quote.quantityToClose;
        require(quote.quoteStatus == QuoteStatus.CLOSE_PENDING, "PartyAFacet: Invalid state");
        require(
            block.timestamp > quote.statusModifyTimestamp + maLayout.forceCloseCooldown,
            "PartyAFacet: Cooldown not reached"
        );
        require(block.timestamp <= quote.deadline, "PartyBFacet: Quote is expired");
        require(
            quote.orderType == OrderType.LIMIT,
            "PartyBFacet: Quote's order type should be LIMIT"
        );
        if (quote.positionType == PositionType.LONG) {
            require(
                upnlSig.price >=
                    quote.requestedClosePrice +
                        (quote.requestedClosePrice * maLayout.forceCloseGapRatio) /
                        1e18,
                "PartyAFacet: Requested close price not reached"
            );
        } else {
            require(
                upnlSig.price <=
                    quote.requestedClosePrice -
                        (quote.requestedClosePrice * maLayout.forceCloseGapRatio) /
                        1e18,
                "PartyAFacet: Requested close price not reached"
            );
        }

        LibMuon.verifyPairUpnlAndPrice(upnlSig, quote.partyB, quote.partyA, quote.symbolId);
        LibSolvency.isSolventAfterClosePosition(
            quoteId,
            filledAmount,
            upnlSig.price,
            upnlSig
        );
        accountLayout.partyANonces[quote.partyA] += 1;
        accountLayout.partyBNonces[quote.partyB][quote.partyA] += 1;
        LibQuote.closeQuote(quote, filledAmount, upnlSig.price);
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/GlobalAppStorage.sol";

library LibAccessibility {
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant MUON_SETTER_ROLE = keccak256("MUON_SETTER_ROLE");
    bytes32 public constant SYMBOL_MANAGER_ROLE = keccak256("SYMBOL_MANAGER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 public constant PARTY_B_MANAGER_ROLE = keccak256("PARTY_B_MANAGER_ROLE");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    bytes32 public constant SUSPENDER_ROLE = keccak256("SUSPENDER_ROLE");
    bytes32 public constant DISPUTE_ROLE = keccak256("DISPUTE_ROLE");

    function hasRole(address user, bytes32 role) internal view returns (bool) {
        GlobalAppStorage.Layout storage layout = GlobalAppStorage.layout();
        return layout.hasRole[user][role];
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "./LibLockedValues.sol";
import "../storages/AccountStorage.sol";

library LibAccount {
    using LockedValuesOps for LockedValues;

    function partyATotalLockedBalances(address partyA) internal view returns (uint256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        return
            accountLayout.pendingLockedBalances[partyA].totalForPartyA() +
            accountLayout.lockedBalances[partyA].totalForPartyA();
    }

    function partyBTotalLockedBalances(
        address partyB,
        address partyA
    ) internal view returns (uint256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        return
            accountLayout.partyBPendingLockedBalances[partyB][partyA].totalForPartyB() +
            accountLayout.partyBLockedBalances[partyB][partyA].totalForPartyB();
    }

    function partyAAvailableForQuote(int256 upnl, address partyA) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 available;
        if (upnl >= 0) {
            available =
                int256(accountLayout.allocatedBalances[partyA]) +
                upnl -
                int256(
                    (accountLayout.lockedBalances[partyA].totalForPartyA() +
                        accountLayout.pendingLockedBalances[partyA].totalForPartyA())
                );
        } else {
            int256 mm = int256(accountLayout.lockedBalances[partyA].partyAmm);
            int256 considering_mm = -upnl > mm ? -upnl : mm;
            available =
                int256(accountLayout.allocatedBalances[partyA]) -
                int256(
                    (accountLayout.lockedBalances[partyA].cva +
                        accountLayout.lockedBalances[partyA].lf +
                        accountLayout.pendingLockedBalances[partyA].totalForPartyA())
                ) -
                considering_mm;
        }
        return available;
    }

    function partyAAvailableBalance(int256 upnl, address partyA) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 available;
        if (upnl >= 0) {
            available =
                int256(accountLayout.allocatedBalances[partyA]) +
                upnl -
                int256(accountLayout.lockedBalances[partyA].totalForPartyA());
        } else {
            int256 mm = int256(accountLayout.lockedBalances[partyA].partyAmm);
            int256 considering_mm = -upnl > mm ? -upnl : mm;
            available =
                int256(accountLayout.allocatedBalances[partyA]) -
                int256(
                    accountLayout.lockedBalances[partyA].cva +
                        accountLayout.lockedBalances[partyA].lf
                ) -
                considering_mm;
        }
        return available;
    }

    function partyAAvailableBalanceForLiquidation(
        int256 upnl,
        address partyA
    ) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 freeBalance = int256(accountLayout.allocatedBalances[partyA]) -
            int256(accountLayout.lockedBalances[partyA].cva + accountLayout.lockedBalances[partyA].lf);
        return freeBalance + upnl;
    }

    function partyBAvailableForQuote(
        int256 upnl,
        address partyB,
        address partyA
    ) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 available;
        if (upnl >= 0) {
            available =
                int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) +
                upnl -
                int256(
                    (accountLayout.partyBLockedBalances[partyB][partyA].totalForPartyB() +
                        accountLayout.partyBPendingLockedBalances[partyB][partyA].totalForPartyB())
                );
        } else {
            int256 mm = int256(accountLayout.partyBLockedBalances[partyB][partyA].partyBmm);
            int256 considering_mm = -upnl > mm ? -upnl : mm;
            available =
                int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) -
                int256(
                    (accountLayout.partyBLockedBalances[partyB][partyA].cva +
                        accountLayout.partyBLockedBalances[partyB][partyA].lf +
                        accountLayout.partyBPendingLockedBalances[partyB][partyA].totalForPartyB())
                ) -
                considering_mm;
        }
        return available;
    }

    function partyBAvailableBalance(
        int256 upnl,
        address partyB,
        address partyA
    ) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 available;
        if (upnl >= 0) {
            available =
                int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) +
                upnl -
                int256(accountLayout.partyBLockedBalances[partyB][partyA].totalForPartyB());
        } else {
            int256 mm = int256(accountLayout.partyBLockedBalances[partyB][partyA].partyBmm);
            int256 considering_mm = -upnl > mm ? -upnl : mm;
            available =
                int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) -
                int256(
                    accountLayout.partyBLockedBalances[partyB][partyA].cva +
                        accountLayout.partyBLockedBalances[partyB][partyA].lf
                ) -
                considering_mm;
        }
        return available;
    }

    function partyBAvailableBalanceForLiquidation(
        int256 upnl,
        address partyB,
        address partyA
    ) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 a = int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) -
            int256(accountLayout.partyBLockedBalances[partyB][partyA].cva +
                accountLayout.partyBLockedBalances[partyB][partyA].lf);
        return a + upnl;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../storages/QuoteStorage.sol";

struct LockedValues {
    uint256 cva;
    uint256 lf;
    uint256 partyAmm;
    uint256 partyBmm;
}

library LockedValuesOps {
    using SafeMath for uint256;

    function add(LockedValues storage self, LockedValues memory a)
        internal
        returns (LockedValues storage)
    {
        self.cva = self.cva.add(a.cva);
        self.partyAmm = self.partyAmm.add(a.partyAmm);
        self.partyBmm = self.partyBmm.add(a.partyBmm);
        self.lf = self.lf.add(a.lf);
        return self;
    }

    function addQuote(LockedValues storage self, Quote storage quote)
        internal
        returns (LockedValues storage)
    {
        return add(self, quote.lockedValues);
    }

    function sub(LockedValues storage self, LockedValues memory a)
        internal
        returns (LockedValues storage)
    {
        self.cva = self.cva.sub(a.cva);
        self.partyAmm = self.partyAmm.sub(a.partyAmm);
        self.partyBmm = self.partyBmm.sub(a.partyBmm);
        self.lf = self.lf.sub(a.lf);
        return self;
    }

    function subQuote(LockedValues storage self, Quote storage quote)
        internal
        returns (LockedValues storage)
    {
        return sub(self, quote.lockedValues);
    }

    function makeZero(LockedValues storage self) internal returns (LockedValues storage) {
        self.cva = 0;
        self.partyAmm = 0;
        self.partyBmm = 0;
        self.lf = 0;
        return self;
    }

    function totalForPartyA(LockedValues memory self) internal pure returns (uint256) {
        return self.cva + self.partyAmm + self.lf;
    }

    function totalForPartyB(LockedValues memory self) internal pure returns (uint256) {
        return self.cva + self.partyBmm + self.lf;
    }

    function mul(LockedValues storage self, uint256 a) internal returns (LockedValues storage) {
        self.cva = self.cva.mul(a);
        self.partyAmm = self.partyAmm.mul(a);
        self.partyBmm = self.partyBmm.mul(a);
        self.lf = self.lf.mul(a);
        return self;
    }

    function mulMem(LockedValues memory self, uint256 a)
        internal
        pure
        returns (LockedValues memory)
    {
        LockedValues memory lockedValues = LockedValues(
            self.cva.mul(a),
            self.lf.mul(a),
            self.partyAmm.mul(a),
            self.partyBmm.mul(a)
        );
        return lockedValues;
    }

    function div(LockedValues storage self, uint256 a) internal returns (LockedValues storage) {
        self.cva = self.cva.div(a);
        self.partyAmm = self.partyAmm.div(a);
        self.partyBmm = self.partyBmm.div(a);
        self.lf = self.lf.div(a);
        return self;
    }

    function divMem(LockedValues memory self, uint256 a)
        internal
        pure
        returns (LockedValues memory)
    {
        LockedValues memory lockedValues = LockedValues(
            self.cva.div(a),
            self.lf.div(a),
            self.partyAmm.div(a),
            self.partyBmm.div(a)
        );
        return lockedValues;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../libraries/LibMuonV04ClientBase.sol";
import "../storages/MuonStorage.sol";
import "../storages/AccountStorage.sol";

library LibMuon {
    using ECDSA for bytes32;

    function getChainId() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    // CONTEXT for commented out lines
    // We're utilizing muon signatures for asset pricing and user uPNLs calculations. 
    // Even though these signatures are necessary for full testing of the system, particularly when invoking various methods.
    // The process of creating automated functional signature for tests has proven to be either impractical or excessively time-consuming. therefore, we've established commenting out the necessary code as a workaround specifically for testing.
    // Essentially, during testing, we temporarily disable the code sections responsible for validating these signatures. The sections I'm referring to are located within the LibMuon file. Specifically, the body of the 'verifyTSSAndGateway' method is a prime candidate for temporary disablement. In addition, several 'require' statements within other functions of this file, which examine the signatures' expiration status, also need to be temporarily disabled.
    // However, it is crucial to note that these lines should not be disabled in the production deployed version. 
    // We emphasize this because they are only disabled for testing purposes.

    function verifyTSSAndGateway(
        bytes32 hash,
        SchnorrSign memory sign,
        bytes memory gatewaySignature
    ) internal view {
        // == SignatureCheck( ==
        bool verified = LibMuonV04ClientBase.muonVerify(
            uint256(hash),
            sign,
            MuonStorage.layout().muonPublicKey
        );
        require(verified, "LibMuon: TSS not verified");

        hash = hash.toEthSignedMessageHash();
        address gatewaySignatureSigner = hash.recover(gatewaySignature);

        require(
            gatewaySignatureSigner == MuonStorage.layout().validGateway,
            "LibMuon: Gateway is not valid"
        );
        // == ) ==
    }

    function verifyLiquidationSig(LiquidationSig memory liquidationSig, address partyA) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        require(liquidationSig.prices.length == liquidationSig.symbolIds.length, "LibMuon: Invalid length");
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                liquidationSig.reqId,
                liquidationSig.liquidationId,
                address(this),
                "verifyLiquidationSig",
                partyA,
                AccountStorage.layout().partyANonces[partyA],
                liquidationSig.upnl,
                liquidationSig.totalUnrealizedLoss,
                liquidationSig.symbolIds,
                liquidationSig.prices,
                liquidationSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, liquidationSig.sigs, liquidationSig.gatewaySignature);
    }

    function verifyQuotePrices(QuotePriceSig memory priceSig) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        require(priceSig.prices.length == priceSig.quoteIds.length, "LibMuon: Invalid length");
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                priceSig.reqId,
                address(this),
                priceSig.quoteIds,
                priceSig.prices,
                priceSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, priceSig.sigs, priceSig.gatewaySignature);
    }

    function verifyPartyAUpnl(SingleUpnlSig memory upnlSig, address partyA) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyA,
                AccountStorage.layout().partyANonces[partyA],
                upnlSig.upnl,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }

    function verifyPartyAUpnlAndPrice(
        SingleUpnlAndPriceSig memory upnlSig,
        address partyA,
        uint256 symbolId
    ) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyA,
                AccountStorage.layout().partyANonces[partyA],
                upnlSig.upnl,
                symbolId,
                upnlSig.price,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }

    function verifyPartyBUpnl(
        SingleUpnlSig memory upnlSig,
        address partyB,
        address partyA
    ) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyB,
                partyA,
                AccountStorage.layout().partyBNonces[partyB][partyA],
                upnlSig.upnl,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }

    function verifyPairUpnlAndPrice(
        PairUpnlAndPriceSig memory upnlSig,
        address partyB,
        address partyA,
        uint256 symbolId
    ) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyB,
                partyA,
                AccountStorage.layout().partyBNonces[partyB][partyA],
                AccountStorage.layout().partyANonces[partyA],
                upnlSig.upnlPartyB,
                upnlSig.upnlPartyA,
                symbolId,
                upnlSig.price,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }

    function verifyPairUpnl(
        PairUpnlSig memory upnlSig,
        address partyB,
        address partyA
    ) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyB,
                partyA,
                AccountStorage.layout().partyBNonces[partyB][partyA],
                AccountStorage.layout().partyANonces[partyA],
                upnlSig.upnlPartyB,
                upnlSig.upnlPartyA,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "../storages/MuonStorage.sol";

library LibMuonV04ClientBase {
    // See https://en.bitcoin.it/wiki/Secp256k1 for this constant.
    uint256 constant public Q = // Group order of secp256k1
    // solium-disable-next-line indentation
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    // solium-disable-next-line zeppelin/no-arithmetic-operations
    uint256 constant public HALF_Q = (Q >> 1) + 1;

    /** **************************************************************************
@notice verifySignature returns true iff passed a valid Schnorr signature.

      @dev See https://en.wikipedia.org/wiki/Schnorr_signature for reference.

      @dev In what follows, let d be your secret key, PK be your public key,
      PKx be the x ordinate of your public key, and PKyp be the parity bit for
      the y ordinate (i.e., 0 if PKy is even, 1 if odd.)
      **************************************************************************
      @dev TO CREATE A VALID SIGNATURE FOR THIS METHOD

      @dev First PKx must be less than HALF_Q. Then follow these instructions
           (see evm/test/schnorr_test.js, for an example of carrying them out):
      @dev 1. Hash the target message to a uint256, called msgHash here, using
              keccak256

      @dev 2. Pick k uniformly and cryptographically securely randomly from
              {0,...,Q-1}. It is critical that k remains confidential, as your
              private key can be reconstructed from k and the signature.

      @dev 3. Compute k*g in the secp256k1 group, where g is the group
              generator. (This is the same as computing the public key from the
              secret key k. But it's OK if k*g's x ordinate is greater than
              HALF_Q.)

      @dev 4. Compute the ethereum address for k*g. This is the lower 160 bits
              of the keccak hash of the concatenated affine coordinates of k*g,
              as 32-byte big-endians. (For instance, you could pass k to
              ethereumjs-utils's privateToAddress to compute this, though that
              should be strictly a development convenience, not for handling
              live secrets, unless you've locked your javascript environment
              down very carefully.) Call this address
              nonceTimesGeneratorAddress.

      @dev 5. Compute e=uint256(keccak256(PKx as a 32-byte big-endian
                                        ‖ PKyp as a single byte
                                        ‖ msgHash
                                        ‖ nonceTimesGeneratorAddress))
              This value e is called "msgChallenge" in verifySignature's source
              code below. Here "‖" means concatenation of the listed byte
              arrays.

      @dev 6. Let x be your secret key. Compute s = (k - d * e) % Q. Add Q to
              it, if it's negative. This is your signature. (d is your secret
              key.)
      **************************************************************************
      @dev TO VERIFY A SIGNATURE

      @dev Given a signature (s, e) of msgHash, constructed as above, compute
      S=e*PK+s*generator in the secp256k1 group law, and then the ethereum
      address of S, as described in step 4. Call that
      nonceTimesGeneratorAddress. Then call the verifySignature method as:

      @dev    verifySignature(PKx, PKyp, s, msgHash,
                              nonceTimesGeneratorAddress)
      **************************************************************************
      @dev This signging scheme deviates slightly from the classical Schnorr
      signature, in that the address of k*g is used in place of k*g itself,
      both when calculating e and when verifying sum S as described in the
      verification paragraph above. This reduces the difficulty of
      brute-forcing a signature by trying random secp256k1 points in place of
      k*g in the signature verification process from 256 bits to 160 bits.
      However, the difficulty of cracking the public key using "baby-step,
      giant-step" is only 128 bits, so this weakening constitutes no compromise
      in the security of the signatures or the key.

      @dev The constraint signingPubKeyX < HALF_Q comes from Eq. (281), p. 24
      of Yellow Paper version 78d7b9a. ecrecover only accepts "s" inputs less
      than HALF_Q, to protect against a signature- malleability vulnerability in
      ECDSA. Schnorr does not have this vulnerability, but we must account for
      ecrecover's defense anyway. And since we are abusing ecrecover by putting
      signingPubKeyX in ecrecover's "s" argument the constraint applies to
      signingPubKeyX, even though it represents a value in the base field, and
      has no natural relationship to the order of the curve's cyclic group.
      **************************************************************************
      @param signingPubKeyX is the x ordinate of the public key. This must be
             less than HALF_Q.
      @param pubKeyYParity is 0 if the y ordinate of the public key is even, 1
             if it's odd.
      @param signature is the actual signature, described as s in the above
             instructions.
      @param msgHash is a 256-bit hash of the message being signed.
      @param nonceTimesGeneratorAddress is the ethereum address of k*g in the
             above instructions
      **************************************************************************
      @return True if passed a valid signature, false otherwise. */
    function verifySignature(
        uint256 signingPubKeyX,
        uint8 pubKeyYParity,
        uint256 signature,
        uint256 msgHash,
        address nonceTimesGeneratorAddress) public pure returns (bool) {
        require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
        // Avoid signature malleability from multiple representations for ℤ/Qℤ elts
        require(signature < Q, "signature must be reduced modulo Q");

        // Forbid trivial inputs, to avoid ecrecover edge cases. The main thing to
        // avoid is something which causes ecrecover to return 0x0: then trivial
        // signatures could be constructed with the nonceTimesGeneratorAddress input
        // set to 0x0.
        //
        // solium-disable-next-line indentation
        require(nonceTimesGeneratorAddress != address(0) && signingPubKeyX > 0 &&
        signature > 0 && msgHash > 0, "no zero inputs allowed");

        // solium-disable-next-line indentation
        uint256 msgChallenge = // "e"
        // solium-disable-next-line indentation
                            uint256(keccak256(abi.encodePacked(signingPubKeyX, pubKeyYParity,
                msgHash, nonceTimesGeneratorAddress))
            );

        // Verify msgChallenge * signingPubKey + signature * generator ==
        //        nonce * generator
        //
        // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
        // The point corresponding to the address returned by
        // ecrecover(-s*r,v,r,e*r) is (r⁻¹ mod Q)*(e*r*R-(-s)*r*g)=e*R+s*g, where R
        // is the (v,r) point. See https://crypto.stackexchange.com/a/18106
        //
        // solium-disable-next-line indentation
        address recoveredAddress = ecrecover(
        // solium-disable-next-line zeppelin/no-arithmetic-operations
            bytes32(Q - mulmod(signingPubKeyX, signature, Q)),
            // https://ethereum.github.io/yellowpaper/paper.pdf p. 24, "The
            // value 27 represents an even y value and 28 represents an odd
            // y value."
            (pubKeyYParity == 0) ? 27 : 28,
            bytes32(signingPubKeyX),
            bytes32(mulmod(msgChallenge, signingPubKeyX, Q)));
        return nonceTimesGeneratorAddress == recoveredAddress;
    }

    function validatePubKey(uint256 signingPubKeyX) public pure {
        require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
    }

    function muonVerify(
        uint256 hash,
        SchnorrSign memory signature,
        PublicKey memory pubKey
    ) internal pure returns (bool) {
        if (!verifySignature(pubKey.x, pubKey.parity,
            signature.signature,
            hash, signature.nonce)) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "./LibLockedValues.sol";
import "../storages/QuoteStorage.sol";
import "../storages/AccountStorage.sol";
import "../storages/GlobalAppStorage.sol";
import "../storages/SymbolStorage.sol";
import "../storages/MAStorage.sol";

library LibQuote {
    using LockedValuesOps for LockedValues;

    function quoteOpenAmount(Quote storage quote) internal view returns (uint256) {
        return quote.quantity - quote.closedAmount;
    }

    function getIndexOfItem(
        uint256[] storage array_,
        uint256 item
    ) internal view returns (uint256) {
        for (uint256 index = 0; index < array_.length; index++) {
            if (array_[index] == item) return index;
        }
        return type(uint256).max;
    }

    function removeFromArray(uint256[] storage array_, uint256 item) internal {
        uint256 index = getIndexOfItem(array_, item);
        require(index != type(uint256).max, "LibQuote: Item not Found");
        array_[index] = array_[array_.length - 1];
        array_.pop();
    }

    function removeFromPartyAPendingQuotes(Quote storage quote) internal {
        removeFromArray(QuoteStorage.layout().partyAPendingQuotes[quote.partyA], quote.id);
    }

    function removeFromPartyBPendingQuotes(Quote storage quote) internal {
        removeFromArray(
            QuoteStorage.layout().partyBPendingQuotes[quote.partyB][quote.partyA],
            quote.id
        );
    }

    function removeFromPendingQuotes(Quote storage quote) internal {
        removeFromPartyAPendingQuotes(quote);
        removeFromPartyBPendingQuotes(quote);
    }

    function addToOpenPositions(uint256 quoteId) internal {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        Quote storage quote = quoteLayout.quotes[quoteId];

        quoteLayout.partyAOpenPositions[quote.partyA].push(quote.id);
        quoteLayout.partyBOpenPositions[quote.partyB][quote.partyA].push(quote.id);

        quoteLayout.partyAPositionsIndex[quote.id] = quoteLayout.partyAPositionsCount[quote.partyA];
        quoteLayout.partyBPositionsIndex[quote.id] = quoteLayout.partyBPositionsCount[quote.partyB][
                        quote.partyA
            ];

        quoteLayout.partyAPositionsCount[quote.partyA] += 1;
        quoteLayout.partyBPositionsCount[quote.partyB][quote.partyA] += 1;
    }

    function removeFromOpenPositions(uint256 quoteId) internal {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        Quote storage quote = quoteLayout.quotes[quoteId];
        uint256 indexOfPartyAPosition = quoteLayout.partyAPositionsIndex[quote.id];
        uint256 indexOfPartyBPosition = quoteLayout.partyBPositionsIndex[quote.id];
        uint256 lastOpenPositionIndex = quoteLayout.partyAPositionsCount[quote.partyA] - 1;
        quoteLayout.partyAOpenPositions[quote.partyA][indexOfPartyAPosition] = quoteLayout
            .partyAOpenPositions[quote.partyA][lastOpenPositionIndex];
        quoteLayout.partyAPositionsIndex[
        quoteLayout.partyAOpenPositions[quote.partyA][lastOpenPositionIndex]
        ] = indexOfPartyAPosition;
        quoteLayout.partyAOpenPositions[quote.partyA].pop();

        lastOpenPositionIndex = quoteLayout.partyBPositionsCount[quote.partyB][quote.partyA] - 1;
        quoteLayout.partyBOpenPositions[quote.partyB][quote.partyA][
        indexOfPartyBPosition
        ] = quoteLayout.partyBOpenPositions[quote.partyB][quote.partyA][lastOpenPositionIndex];
        quoteLayout.partyBPositionsIndex[
        quoteLayout.partyBOpenPositions[quote.partyB][quote.partyA][lastOpenPositionIndex]
        ] = indexOfPartyBPosition;
        quoteLayout.partyBOpenPositions[quote.partyB][quote.partyA].pop();

        quoteLayout.partyAPositionsIndex[quote.id] = 0;
        quoteLayout.partyBPositionsIndex[quote.id] = 0;
    }

    function getValueOfQuoteForPartyA(
        uint256 currentPrice,
        uint256 filledAmount,
        Quote storage quote
    ) internal view returns (bool hasMadeProfit, uint256 pnl) {
        if (currentPrice > quote.openedPrice) {
            if (quote.positionType == PositionType.LONG) {
                hasMadeProfit = true;
            } else {
                hasMadeProfit = false;
            }
            pnl = ((currentPrice - quote.openedPrice) * filledAmount) / 1e18;
        } else {
            if (quote.positionType == PositionType.LONG) {
                hasMadeProfit = false;
            } else {
                hasMadeProfit = true;
            }
            pnl = ((quote.openedPrice - currentPrice) * filledAmount) / 1e18;
        }
    }

    function getTradingFee(uint256 quoteId) internal view returns (uint256 fee) {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        Quote storage quote = quoteLayout.quotes[quoteId];
        if (quote.orderType == OrderType.LIMIT) {
            fee =
                (LibQuote.quoteOpenAmount(quote) * quote.requestedOpenPrice * quote.tradingFee) /
                1e36;
        } else {
            fee = (LibQuote.quoteOpenAmount(quote) * quote.marketPrice * quote.tradingFee) / 1e36;
        }
    }

    function closeQuote(Quote storage quote, uint256 filledAmount, uint256 closedPrice) internal {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();

        require(quote.lockedValues.cva == 0 || quote.lockedValues.cva * filledAmount / LibQuote.quoteOpenAmount(quote) > 0, "LibQuote: Low filled amount");
        require(quote.lockedValues.partyAmm == 0 || quote.lockedValues.partyAmm * filledAmount / LibQuote.quoteOpenAmount(quote) > 0, "LibQuote: Low filled amount");
        require(quote.lockedValues.partyBmm == 0 || quote.lockedValues.partyBmm * filledAmount / LibQuote.quoteOpenAmount(quote) > 0, "LibQuote: Low filled amount");
        require(quote.lockedValues.lf * filledAmount / LibQuote.quoteOpenAmount(quote) > 0, "LibQuote: Low filled amount");
        LockedValues memory lockedValues = LockedValues(
            quote.lockedValues.cva -
            ((quote.lockedValues.cva * filledAmount) / (LibQuote.quoteOpenAmount(quote))),
            quote.lockedValues.lf -
            ((quote.lockedValues.lf * filledAmount) / (LibQuote.quoteOpenAmount(quote))),
            quote.lockedValues.partyAmm -
            ((quote.lockedValues.partyAmm * filledAmount) / (LibQuote.quoteOpenAmount(quote))),
            quote.lockedValues.partyBmm -
            ((quote.lockedValues.partyBmm * filledAmount) / (LibQuote.quoteOpenAmount(quote)))
        );
        accountLayout.lockedBalances[quote.partyA].subQuote(quote).add(lockedValues);
        accountLayout.partyBLockedBalances[quote.partyB][quote.partyA].subQuote(quote).add(
            lockedValues
        );
        quote.lockedValues = lockedValues;

        if (LibQuote.quoteOpenAmount(quote) == quote.quantityToClose) {
            require(
                quote.lockedValues.totalForPartyA() == 0 ||
                    quote.lockedValues.totalForPartyA() >=
                    symbolLayout.symbols[quote.symbolId].minAcceptableQuoteValue,
                "LibQuote: Remaining quote value is low"
            );
        }

        (bool hasMadeProfit, uint256 pnl) = LibQuote.getValueOfQuoteForPartyA(
            closedPrice,
            filledAmount,
            quote
        );
        if (hasMadeProfit) {
            accountLayout.allocatedBalances[quote.partyA] += pnl;
            accountLayout.partyBAllocatedBalances[quote.partyB][quote.partyA] -= pnl;
        } else {
            accountLayout.allocatedBalances[quote.partyA] -= pnl;
            accountLayout.partyBAllocatedBalances[quote.partyB][quote.partyA] += pnl;
        }

        quote.avgClosedPrice =
            (quote.avgClosedPrice * quote.closedAmount + filledAmount * closedPrice) /
            (quote.closedAmount + filledAmount);

        quote.closedAmount += filledAmount;
        quote.quantityToClose -= filledAmount;

        if (quote.closedAmount == quote.quantity) {
            quote.statusModifyTimestamp = block.timestamp;
            quote.quoteStatus = QuoteStatus.CLOSED;
            quote.requestedClosePrice = 0;
            removeFromOpenPositions(quote.id);
            quoteLayout.partyAPositionsCount[quote.partyA] -= 1;
            quoteLayout.partyBPositionsCount[quote.partyB][quote.partyA] -= 1;
        } else if (
            quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING || quote.quantityToClose == 0
        ) {
            quote.quoteStatus = QuoteStatus.OPENED;
            quote.statusModifyTimestamp = block.timestamp;
            quote.requestedClosePrice = 0;
            quote.quantityToClose = 0; // for CANCEL_CLOSE_PENDING status
        }
    }

    function expireQuote(uint256 quoteId) internal returns (QuoteStatus result) {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();

        Quote storage quote = quoteLayout.quotes[quoteId];
        require(block.timestamp > quote.deadline, "LibQuote: Quote isn't expired");
        require(
            quote.quoteStatus == QuoteStatus.PENDING ||
            quote.quoteStatus == QuoteStatus.CANCEL_PENDING ||
            quote.quoteStatus == QuoteStatus.LOCKED ||
            quote.quoteStatus == QuoteStatus.CLOSE_PENDING ||
            quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING,
            "LibQuote: Invalid state"
        );
        require(
            !MAStorage.layout().liquidationStatus[quote.partyA],
            "LibQuote: PartyA isn't solvent"
        );
        require(
            !MAStorage.layout().partyBLiquidationStatus[quote.partyB][quote.partyA],
            "LibQuote: PartyB isn't solvent"
        );
        if (
            quote.quoteStatus == QuoteStatus.PENDING ||
            quote.quoteStatus == QuoteStatus.LOCKED ||
            quote.quoteStatus == QuoteStatus.CANCEL_PENDING
        ) {
            quote.statusModifyTimestamp = block.timestamp;
            accountLayout.pendingLockedBalances[quote.partyA].subQuote(quote);
            // send trading Fee back to partyA
            accountLayout.allocatedBalances[quote.partyA] += LibQuote.getTradingFee(quote.id);
            removeFromPartyAPendingQuotes(quote);
            if (
                quote.quoteStatus == QuoteStatus.LOCKED ||
                quote.quoteStatus == QuoteStatus.CANCEL_PENDING
            ) {
                accountLayout.partyBPendingLockedBalances[quote.partyB][quote.partyA].subQuote(
                    quote
                );
                removeFromPartyBPendingQuotes(quote);
            }
            quote.quoteStatus = QuoteStatus.EXPIRED;
            result = QuoteStatus.EXPIRED;
        } else if (
            quote.quoteStatus == QuoteStatus.CLOSE_PENDING ||
            quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING
        ) {
            quote.statusModifyTimestamp = block.timestamp;
            quote.requestedClosePrice = 0;
            quote.quantityToClose = 0;
            quote.quoteStatus = QuoteStatus.OPENED;
            result = QuoteStatus.OPENED;
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/MuonStorage.sol";
import "../storages/QuoteStorage.sol";
import "./LibAccount.sol";
import "./LibQuote.sol";

library LibSolvency {
    using LockedValuesOps for LockedValues;

    function isSolventAfterOpenPosition(
        uint256 quoteId,
        uint256 filledAmount,
        PairUpnlAndPriceSig memory upnlSig
    ) internal view returns (bool) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        int256 partyBAvailableBalance = LibAccount.partyBAvailableBalanceForLiquidation(
            upnlSig.upnlPartyB,
            quote.partyB,
            quote.partyA
        );
        int256 partyAAvailableBalance = LibAccount.partyAAvailableBalanceForLiquidation(
            upnlSig.upnlPartyA,
            quote.partyA
        );

        if (quote.positionType == PositionType.LONG) {
            if (quote.openedPrice >= upnlSig.price) {
                uint256 diff = (filledAmount * (quote.openedPrice - upnlSig.price)) / 1e18;
                require(
                    partyAAvailableBalance - int256(diff) >= 0,
                    "LibSolvency: PartyA will be liquidatable"
                );
                require(
                    partyBAvailableBalance + int256(diff) >= 0,
                    "LibSolvency: PartyB will be liquidatable"
                );
            } else {
                uint256 diff = (filledAmount * (upnlSig.price - quote.openedPrice)) / 1e18;
                require(
                    partyBAvailableBalance - int256(diff) >= 0,
                    "LibSolvency: PartyB will be liquidatable"
                );
                require(
                    partyAAvailableBalance + int256(diff) >= 0,
                    "LibSolvency: PartyA will be liquidatable"
                );
            }
        } else if (quote.positionType == PositionType.SHORT) {
            if (quote.openedPrice >= upnlSig.price) {
                uint256 diff = (filledAmount * (quote.openedPrice - upnlSig.price)) / 1e18;
                require(
                    partyBAvailableBalance - int256(diff) >= 0,
                    "LibSolvency: PartyB will be liquidatable"
                );
                require(
                    partyAAvailableBalance + int256(diff) >= 0,
                    "LibSolvency: PartyA will be liquidatable"
                );
            } else {
                uint256 diff = (filledAmount * (upnlSig.price - quote.openedPrice)) / 1e18;
                require(
                    partyAAvailableBalance - int256(diff) >= 0,
                    "LibSolvency: PartyA will be liquidatable"
                );
                require(
                    partyBAvailableBalance + int256(diff) >= 0,
                    "LibSolvency: PartyB will be liquidatable"
                );
            }
        }

        return true;
    }

    function isSolventAfterClosePosition(
        uint256 quoteId,
        uint256 filledAmount,
        uint256 closedPrice,
        PairUpnlAndPriceSig memory upnlSig
    ) internal view returns (bool) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        uint256 unlockedAmount = (filledAmount * (quote.lockedValues.cva + quote.lockedValues.lf)) /
            LibQuote.quoteOpenAmount(quote);

        int256 partyBAvailableBalance = LibAccount.partyBAvailableBalanceForLiquidation(
            upnlSig.upnlPartyB,
            quote.partyB,
            quote.partyA
        ) + int256(unlockedAmount);

        int256 partyAAvailableBalance = LibAccount.partyAAvailableBalanceForLiquidation(
            upnlSig.upnlPartyA,
            quote.partyA
        ) + int256(unlockedAmount);

        if (quote.positionType == PositionType.LONG) {
            if (closedPrice >= upnlSig.price) {
                uint256 diff = (filledAmount * (closedPrice - upnlSig.price)) / 1e18;
                partyBAvailableBalance -= int256(diff);
                partyAAvailableBalance += int256(diff);
            } else {
                uint256 diff = (filledAmount * (upnlSig.price - closedPrice)) / 1e18;
                partyBAvailableBalance += int256(diff);
                partyAAvailableBalance -= int256(diff);
            }
        } else if (quote.positionType == PositionType.SHORT) {
            if (closedPrice <= upnlSig.price) {
                uint256 diff = (filledAmount * (upnlSig.price - closedPrice)) / 1e18;
                partyBAvailableBalance -= int256(diff);
                partyAAvailableBalance += int256(diff);
            } else {
                uint256 diff = (filledAmount * (closedPrice - upnlSig.price)) / 1e18;
                partyBAvailableBalance += int256(diff);
                partyAAvailableBalance -= int256(diff);
            }
        }
        require(
            partyBAvailableBalance >= 0 && partyAAvailableBalance >= 0,
            "LibSolvency: Available balance is lower than zero"
        );
        return true;
    }

    function isSolventAfterRequestToClosePosition(
        uint256 quoteId,
        uint256 closePrice,
        uint256 quantityToClose,
        SingleUpnlAndPriceSig memory upnlSig
    ) internal view returns (bool) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        uint256 unlockedAmount = (quantityToClose *
            (quote.lockedValues.cva + quote.lockedValues.lf)) / LibQuote.quoteOpenAmount(quote);

        int256 availableBalance = LibAccount.partyAAvailableBalanceForLiquidation(
            upnlSig.upnl,
            msg.sender
        ) + int256(unlockedAmount);

        require(availableBalance >= 0, "LibSolvency: Available balance is lower than zero");
        if (quote.positionType == PositionType.LONG && closePrice <= upnlSig.price) {
            require(
                uint256(availableBalance) >=
                    ((quantityToClose * (upnlSig.price - closePrice)) / 1e18),
                "LibSolvency: partyA will be liquidatable"
            );
        } else if (quote.positionType == PositionType.SHORT && closePrice >= upnlSig.price) {
            require(
                uint256(availableBalance) >=
                    ((quantityToClose * (closePrice - upnlSig.price)) / 1e18),
                "LibSolvency: partyA will be liquidatable"
            );
        }
        return true;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

enum LiquidationType {
    NONE,
    NORMAL,
    LATE,
    OVERDUE
}

struct SettlementState {
    int256 actualAmount; 
    int256 expectedAmount; 
    uint256 cva;
    bool pending;
}

struct LiquidationDetail {
    bytes liquidationId;
    LiquidationType liquidationType;
    int256 upnl;
    int256 totalUnrealizedLoss;
    uint256 deficit;
    uint256 liquidationFee;
    uint256 timestamp;
    uint256 involvedPartyBCounts;
    int256 partyAAccumulatedUpnl;
    bool disputed;
}

struct Price {
    uint256 price;
    uint256 timestamp;
}

library AccountStorage {
    bytes32 internal constant ACCOUNT_STORAGE_SLOT = keccak256("diamond.standard.storage.account");

    struct Layout {
        // Users deposited amounts
        mapping(address => uint256) balances;
        mapping(address => uint256) allocatedBalances;
        // position value will become pending locked before openPosition and will be locked after that
        mapping(address => LockedValues) pendingLockedBalances;
        mapping(address => LockedValues) lockedBalances;
        mapping(address => mapping(address => uint256)) partyBAllocatedBalances;
        mapping(address => mapping(address => LockedValues)) partyBPendingLockedBalances;
        mapping(address => mapping(address => LockedValues)) partyBLockedBalances;
        mapping(address => uint256) withdrawCooldown;
        mapping(address => uint256) partyANonces;
        mapping(address => mapping(address => uint256)) partyBNonces;
        mapping(address => bool) suspendedAddresses;
        mapping(address => LiquidationDetail) liquidationDetails;
        mapping(address => mapping(uint256 => Price)) symbolsPrices;
        mapping(address => address[]) liquidators;
        mapping(address => uint256) partyAReimbursement;
        // partyA => partyB => SettlementState
        mapping(address => mapping(address => SettlementState)) settlementStates;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = ACCOUNT_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

library GlobalAppStorage {
    bytes32 internal constant GLOBAL_APP_STORAGE_SLOT =
        keccak256("diamond.standard.storage.global");

    struct Layout {
        address collateral;
        address feeCollector;
        bool globalPaused;
        bool liquidationPaused;
        bool accountingPaused;
        bool partyBActionsPaused;
        bool partyAActionsPaused;
        bool emergencyMode;
        uint256 balanceLimitPerUser;
        mapping(address => bool) partyBEmergencyStatus;
        mapping(address => mapping(bytes32 => bool)) hasRole;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = GLOBAL_APP_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

library MAStorage {
    bytes32 internal constant MA_STORAGE_SLOT =
        keccak256("diamond.standard.storage.masteragreement");

    struct Layout {
        uint256 deallocateCooldown;
        uint256 forceCancelCooldown;
        uint256 forceCancelCloseCooldown;
        uint256 forceCloseCooldown;
        uint256 liquidationTimeout;
        uint256 liquidatorShare; // in 18 decimals
        uint256 pendingQuotesValidLength;
        uint256 forceCloseGapRatio;
        mapping(address => bool) partyBStatus;
        mapping(address => bool) liquidationStatus;
        mapping(address => mapping(address => bool)) partyBLiquidationStatus;
        mapping(address => mapping(address => uint256)) partyBLiquidationTimestamp;
        mapping(address => mapping(address => uint256)) partyBPositionLiquidatorsShare;
        address[] partyBList;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = MA_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

struct PublicKey {
    uint256 x;
    uint8 parity;
}

struct SingleUpnlSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnl;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct SingleUpnlAndPriceSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnl;
    uint256 price;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct PairUpnlSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnlPartyA;
    int256 upnlPartyB;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct PairUpnlAndPriceSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnlPartyA;
    int256 upnlPartyB;
    uint256 price;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct LiquidationSig {
    bytes reqId;
    uint256 timestamp;
    bytes liquidationId;
    int256 upnl;
    int256 totalUnrealizedLoss; 
    uint256[] symbolIds;
    uint256[] prices;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct QuotePriceSig {
    bytes reqId;
    uint256 timestamp;
    uint256[] quoteIds;
    uint256[] prices;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

library MuonStorage {
    bytes32 internal constant MUON_STORAGE_SLOT = keccak256("diamond.standard.storage.muon");

    struct Layout {
        uint256 upnlValidTime;
        uint256 priceValidTime;
        uint256 priceQuantityValidTime;
        uint256 muonAppId;
        PublicKey muonPublicKey;
        address validGateway;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = MUON_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

enum PositionType {
    LONG,
    SHORT
}

enum OrderType {
    LIMIT,
    MARKET
}

enum QuoteStatus {
    PENDING, //0
    LOCKED, //1
    CANCEL_PENDING, //2
    CANCELED, //3
    OPENED, //4
    CLOSE_PENDING, //5
    CANCEL_CLOSE_PENDING, //6
    CLOSED, //7
    LIQUIDATED, //8
    EXPIRED //9
}

struct Quote {
    uint256 id;
    address[] partyBsWhiteList;
    uint256 symbolId;
    PositionType positionType;
    OrderType orderType;
    // Price of quote which PartyB opened in 18 decimals
    uint256 openedPrice;
    uint256 initialOpenedPrice;
    // Price of quote which PartyA requested in 18 decimals
    uint256 requestedOpenPrice;
    uint256 marketPrice;
    // Quantity of quote which PartyA requested in 18 decimals
    uint256 quantity;
    // Quantity of quote which PartyB has closed until now in 18 decimals
    uint256 closedAmount;
    LockedValues initialLockedValues;
    LockedValues lockedValues;
    uint256 maxFundingRate;
    address partyA;
    address partyB;
    QuoteStatus quoteStatus;
    uint256 avgClosedPrice;
    uint256 requestedClosePrice;
    uint256 quantityToClose;
    // handle partially open position
    uint256 parentId;
    uint256 createTimestamp;
    uint256 statusModifyTimestamp;
    uint256 lastFundingPaymentTimestamp;
    uint256 deadline;
    uint256 tradingFee;
}

library QuoteStorage {
    bytes32 internal constant QUOTE_STORAGE_SLOT = keccak256("diamond.standard.storage.quote");

    struct Layout {
        mapping(address => uint256[]) quoteIdsOf;
        mapping(uint256 => Quote) quotes;
        mapping(address => uint256) partyAPositionsCount;
        mapping(address => mapping(address => uint256)) partyBPositionsCount;
        mapping(address => uint256[]) partyAPendingQuotes;
        mapping(address => mapping(address => uint256[])) partyBPendingQuotes;
        mapping(address => uint256[]) partyAOpenPositions;
        mapping(uint256 => uint256) partyAPositionsIndex;
        mapping(address => mapping(address => uint256[])) partyBOpenPositions;
        mapping(uint256 => uint256) partyBPositionsIndex;
        uint256 lastId;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = QUOTE_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

struct Symbol {
    uint256 symbolId;
    string name;
    bool isValid;
    uint256 minAcceptableQuoteValue;
    uint256 minAcceptablePortionLF;
    uint256 tradingFee;
    uint256 maxLeverage;
    uint256 fundingRateEpochDuration;
    uint256 fundingRateWindowTime;
}

library SymbolStorage {
    bytes32 internal constant SYMBOL_STORAGE_SLOT = keccak256("diamond.standard.storage.symbol");

    struct Layout {
        mapping(uint256 => Symbol) symbols;
        uint256 lastId;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SYMBOL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/MAStorage.sol";
import "../storages/AccountStorage.sol";
import "../storages/QuoteStorage.sol";
import "../libraries/LibAccessibility.sol";

abstract contract Accessibility {
    modifier onlyPartyB() {
        require(MAStorage.layout().partyBStatus[msg.sender], "Accessibility: Should be partyB");
        _;
    }

    modifier notPartyB() {
        require(!MAStorage.layout().partyBStatus[msg.sender], "Accessibility: Shouldn't be partyB");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(LibAccessibility.hasRole(msg.sender, role), "Accessibility: Must has role");
        _;
    }

    modifier notLiquidatedPartyA(address partyA) {
        require(
            !MAStorage.layout().liquidationStatus[partyA],
            "Accessibility: PartyA isn't solvent"
        );
        _;
    }

    modifier notLiquidatedPartyB(address partyB, address partyA) {
        require(
            !MAStorage.layout().partyBLiquidationStatus[partyB][partyA],
            "Accessibility: PartyB isn't solvent"
        );
        _;
    }

    modifier notLiquidated(uint256 quoteId) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(
            !MAStorage.layout().liquidationStatus[quote.partyA],
            "Accessibility: PartyA isn't solvent"
        );
        require(
            !MAStorage.layout().partyBLiquidationStatus[quote.partyB][quote.partyA],
            "Accessibility: PartyB isn't solvent"
        );
        require(
            quote.quoteStatus != QuoteStatus.LIQUIDATED && quote.quoteStatus != QuoteStatus.CLOSED,
            "Accessibility: Invalid state"
        );
        _;
    }

    modifier onlyPartyAOfQuote(uint256 quoteId) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(quote.partyA == msg.sender, "Accessibility: Should be partyA of quote");
        _;
    }

    modifier onlyPartyBOfQuote(uint256 quoteId) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(quote.partyB == msg.sender, "Accessibility: Should be partyB of quote");
        _;
    }

    modifier notSuspended(address user) {
        require(
            !AccountStorage.layout().suspendedAddresses[user],
            "Accessibility: Sender is Suspended"
        );
        _;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/GlobalAppStorage.sol";

abstract contract Pausable {
    modifier whenNotGlobalPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        _;
    }

    modifier whenNotLiquidationPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        require(!GlobalAppStorage.layout().liquidationPaused, "Pausable: Liquidation paused");
        _;
    }

    modifier whenNotAccountingPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        require(!GlobalAppStorage.layout().accountingPaused, "Pausable: Accounting paused");
        _;
    }

    modifier whenNotPartyAActionsPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        require(!GlobalAppStorage.layout().partyAActionsPaused, "Pausable: PartyA actions paused");
        _;
    }

    modifier whenNotPartyBActionsPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        require(!GlobalAppStorage.layout().partyBActionsPaused, "Pausable: PartyB actions paused");
        _;
    }

    modifier whenEmergencyMode(address partyB) {
        require(
            GlobalAppStorage.layout().emergencyMode ||
                GlobalAppStorage.layout().partyBEmergencyStatus[partyB],
            "Pausable: It isn't emergency mode"
        );
        _;
    }
}