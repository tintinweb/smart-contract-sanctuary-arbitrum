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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
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
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
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
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { Decimal } from "../libraries/LibDecimal.sol";
import { ConstantsStorage } from "./ConstantsStorage.sol";
import { IConstantsEvents } from "./IConstantsEvents.sol";

library ConstantsInternal {
    using ConstantsStorage for ConstantsStorage.Layout;
    using Decimal for Decimal.D256;

    uint256 private constant PERCENT_BASE = 1e18;
    uint256 private constant PRECISION = 1e18;

    /* ========== VIEWS ========== */

    function getPrecision() internal pure returns (uint256) {
        return PRECISION;
    }

    function getPercentBase() internal pure returns (uint256) {
        return PERCENT_BASE;
    }

    function getCollateral() internal view returns (address) {
        return ConstantsStorage.layout().collateral;
    }

    function getLiquidationFee() internal view returns (Decimal.D256 memory) {
        return Decimal.ratio(ConstantsStorage.layout().liquidationFee, PERCENT_BASE);
    }

    function getProtocolLiquidationShare() internal view returns (Decimal.D256 memory) {
        return Decimal.ratio(ConstantsStorage.layout().protocolLiquidationShare, PERCENT_BASE);
    }

    function getCVA() internal view returns (Decimal.D256 memory) {
        return Decimal.ratio(ConstantsStorage.layout().cva, PERCENT_BASE);
    }

    function getRequestTimeout() internal view returns (uint256) {
        return ConstantsStorage.layout().requestTimeout;
    }

    function getMaxOpenPositionsCross() internal view returns (uint256) {
        return ConstantsStorage.layout().maxOpenPositionsCross;
    }

    /* ========== SETTERS ========== */

    function setCollateral(address collateral) internal {
        ConstantsStorage.layout().collateral = collateral;
    }

    function setLiquidationFee(uint256 liquidationFee) internal {
        ConstantsStorage.layout().liquidationFee = liquidationFee;
    }

    function setProtocolLiquidationShare(uint256 protocolLiquidationShare) internal {
        ConstantsStorage.layout().protocolLiquidationShare = protocolLiquidationShare;
    }

    function setCVA(uint256 cva) internal {
        ConstantsStorage.layout().cva = cva;
    }

    function setRequestTimeout(uint256 requestTimeout) internal {
        ConstantsStorage.layout().requestTimeout = requestTimeout;
    }

    function setMaxOpenPositionsCross(uint256 maxOpenPositionsCross) internal {
        ConstantsStorage.layout().maxOpenPositionsCross = maxOpenPositionsCross;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library ConstantsStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("diamond.standard.constants.storage");

    struct Layout {
        address collateral;
        uint256 liquidationFee;
        uint256 protocolLiquidationShare;
        uint256 cva;
        uint256 requestTimeout;
        uint256 maxOpenPositionsCross;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IConstantsEvents {
    event SetCollateral(address oldAddress, address newAddress);
    event SetLiquidationFee(uint256 oldFee, uint256 newFee);
    event SetProtocolLiquidationShare(uint256 oldShare, uint256 newShare);
    event SetCVA(uint256 oldCVA, uint256 newCVA);
    event SetRequestTimeout(uint256 oldTimeout, uint256 newTimeout);
    event SetMaxOpenPositionsCross(uint256 oldMax, uint256 newMax);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10 ** 18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero() internal pure returns (D256 memory) {
        return D256({ value: 0 });
    }

    function one() internal pure returns (D256 memory) {
        return D256({ value: BASE });
    }

    function from(uint256 a) internal pure returns (D256 memory) {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(uint256 a, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(D256 memory self, uint256 b, string memory reason) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.mul(b) });
    }

    function div(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.div(b) });
    }

    function pow(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        if (b == 0) {
            return one();
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; ++i) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(D256 memory self, D256 memory b, string memory reason) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(uint256 target, uint256 numerator, uint256 denominator) private pure returns (uint256) {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(D256 memory a, D256 memory b) private pure returns (uint256) {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

enum MarketType {
    FOREX,
    METALS,
    ENERGIES,
    INDICES,
    STOCKS,
    COMMODITIES,
    BONDS,
    ETFS,
    CRYPTO
}

enum Side {
    BUY,
    SELL
}

enum HedgerMode {
    SINGLE,
    HYBRID,
    AUTO
}

enum OrderType {
    LIMIT,
    MARKET
}

enum PositionType {
    ISOLATED,
    CROSS
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { Decimal } from "../libraries/LibDecimal.sol";
import { ConstantsInternal } from "../constants/ConstantsInternal.sol";
import { MarketsStorage, Market } from "./MarketsStorage.sol";
import { MasterStorage } from "../master-agreement/MasterStorage.sol";

library MarketsInternal {
    using MarketsStorage for MarketsStorage.Layout;
    using MasterStorage for MasterStorage.Layout;
    using Decimal for Decimal.D256;

    /* ========== VIEWS ========== */

    function getMarkets() internal view returns (Market[] memory markets) {
        return getMarketsInRange(1, MarketsStorage.layout().marketList.length);
    }

    function getMarketById(uint256 marketId) internal view returns (Market memory market) {
        return MarketsStorage.layout().marketMap[marketId];
    }

    function getMarketsByIds(uint256[] memory marketIds) internal view returns (Market[] memory markets) {
        markets = new Market[](marketIds.length);
        for (uint256 i = 0; i < marketIds.length; i++) {
            markets[i] = MarketsStorage.layout().marketMap[marketIds[i]];
        }
    }

    function getMarketsInRange(uint256 start, uint256 end) internal view returns (Market[] memory markets) {
        uint256 length = end - start + 1;
        markets = new Market[](length);

        for (uint256 i = 0; i < length; i++) {
            markets[i] = MarketsStorage.layout().marketMap[start + i];
        }
    }

    function getMarketsLength() internal view returns (uint256 length) {
        return MarketsStorage.layout().marketList.length;
    }

    function getMarketFromPositionId(uint256 positionId) internal view returns (Market memory market) {
        uint256 marketId = MasterStorage.layout().allPositionsMap[positionId].marketId;
        market = MarketsStorage.layout().marketMap[marketId];
    }

    function getMarketsFromPositionIds(uint256[] calldata positionIds) internal view returns (Market[] memory markets) {
        markets = new Market[](positionIds.length);
        for (uint256 i = 0; i < positionIds.length; i++) {
            uint256 marketId = MasterStorage.layout().allPositionsMap[positionIds[i]].marketId;
            markets[i] = MarketsStorage.layout().marketMap[marketId];
        }
    }

    function getMarketProtocolFee(uint256 marketId) internal view returns (Decimal.D256 memory) {
        uint256 fee = MarketsStorage.layout().marketMap[marketId].protocolFee;
        return Decimal.ratio(fee, ConstantsInternal.getPercentBase());
    }

    function isValidMarketId(uint256 marketId) internal pure returns (bool) {
        return marketId > 0;
    }

    function isActiveMarket(uint256 marketId) internal view returns (bool) {
        return MarketsStorage.layout().marketMap[marketId].active;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { MarketType } from "../libraries/LibEnums.sol";

struct Market {
    uint256 marketId;
    string identifier;
    MarketType marketType;
    bool active;
    string baseCurrency;
    string quoteCurrency;
    string symbol;
    bytes32 muonPriceFeedId;
    bytes32 fundingRateId;
    uint256 protocolFee;
}

library MarketsStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("diamond.standard.markets.storage");

    struct Layout {
        mapping(uint256 => Market) marketMap;
        Market[] marketList;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { Side } from "../libraries/LibEnums.sol";
import { Decimal } from "../libraries/LibDecimal.sol";
import { PositionPrice } from "../oracle/OracleStorage.sol";
import { ConstantsInternal } from "../constants/ConstantsInternal.sol";
import { MarketsInternal } from "../markets/MarketsInternal.sol";
import { MasterStorage, Position } from "./MasterStorage.sol";

library MasterCalculators {
    using Decimal for Decimal.D256;
    using MasterStorage for MasterStorage.Layout;

    /**
     * @notice Returns the UPnL for a specific position.
     * @dev This is a naive function, inputs can not be trusted. Use cautiously.
     */
    function calculateUPnLIsolated(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice
    ) internal view returns (int256 uPnLA, int256 uPnLB) {
        MasterStorage.Layout storage s = MasterStorage.layout();
        Position memory position = s.allPositionsMap[positionId];

        (uPnLA, uPnLB) = _calculateUPnLIsolated(
            position.side,
            position.currentBalanceUnits,
            position.initialNotionalUsd,
            bidPrice,
            askPrice
        );
    }

    /**
     * @notice Returns the UPnL of a party across all his open positions.
     * @dev This is a naive function, inputs can NOT be trusted. Use cautiously.
     *      Use Muon to verify inputs to prevent expensive computational costs.
     * @dev positionPrices can have an incorrect length.
     * @dev positionPrices can have an arbitrary order.
     * @dev positionPrices can contain forged duplicates.
     */
    function calculateUPnLCross(
        PositionPrice[] memory positionPrices,
        address party
    ) internal view returns (int256 uPnLCross) {
        return _calculateUPnLCross(positionPrices, party);
    }

    function calculateProtocolFeeAmount(uint256 marketId, uint256 notionalUsd) internal view returns (uint256) {
        return Decimal.from(notionalUsd).mul(MarketsInternal.getMarketProtocolFee(marketId)).asUint256();
    }

    function calculateLiquidationFeeAmount(uint256 notionalUsd) internal view returns (uint256) {
        return Decimal.from(notionalUsd).mul(ConstantsInternal.getLiquidationFee()).asUint256();
    }

    function calculateCVAAmount(uint256 notionalSize) internal view returns (uint256) {
        return Decimal.from(notionalSize).mul(ConstantsInternal.getCVA()).asUint256();
    }

    function calculateCrossMarginHealth(
        address party,
        int256 uPnLCross
    ) internal view returns (Decimal.D256 memory ratio) {
        MasterStorage.Layout storage s = MasterStorage.layout();

        uint256 lockedMargin = s.crossLockedMargin[party];
        uint256 openPositions = s.openPositionsCrossLength[party];

        if (lockedMargin == 0 && openPositions == 0) {
            return Decimal.ratio(1, 1);
        } else if (lockedMargin == 0) {
            return Decimal.zero();
        }

        if (uPnLCross >= 0) {
            return Decimal.ratio(lockedMargin + uint256(uPnLCross), lockedMargin);
        }

        uint256 pnl = uint256(-uPnLCross);
        if (pnl >= lockedMargin) {
            return Decimal.zero();
        }

        ratio = Decimal.ratio(lockedMargin - pnl, lockedMargin);
    }

    /* ========== PRIVATE ========== */

    /**
     * @notice Returns the UPnL for a specific position.
     * @dev This is a naive function, inputs can not be trusted. Use cautiously.
     */
    function _calculateUPnLIsolated(
        Side side,
        uint256 currentBalanceUnits,
        uint256 initialNotionalUsd,
        uint256 bidPrice,
        uint256 askPrice
    ) private pure returns (int256 uPnLA, int256 uPnLB) {
        if (currentBalanceUnits == 0) return (0, 0);

        uint256 precision = ConstantsInternal.getPrecision();
        if (side == Side.BUY) {
            require(bidPrice != 0, "Oracle bidPrice is invalid");
            int256 notionalIsolatedA = int256((currentBalanceUnits * bidPrice) / precision);
            uPnLA = notionalIsolatedA - int256(initialNotionalUsd);
        } else {
            require(askPrice != 0, "Oracle askPrice is invalid");
            int256 notionalIsolatedA = int256((currentBalanceUnits * askPrice) / precision);
            uPnLA = int256(initialNotionalUsd) - notionalIsolatedA;
        }

        return (uPnLA, -uPnLA);
    }

    /**
     * @notice Returns the UPnL of a party across all his open positions.
     * @dev This is a naive function, inputs can NOT be trusted. Use cautiously.
     * @dev positionPrices can have an incorrect length.
     * @dev positionPrices can have an arbitrary order.
     * @dev positionPrices can contain forged duplicates.
     */
    function _calculateUPnLCross(
        PositionPrice[] memory positionPrices,
        address party
    ) private view returns (int256 uPnLCrossA) {
        MasterStorage.Layout storage s = MasterStorage.layout();

        for (uint256 i = 0; i < positionPrices.length; i++) {
            uint256 positionId = positionPrices[i].positionId;
            uint256 bidPrice = positionPrices[i].bidPrice;
            uint256 askPrice = positionPrices[i].askPrice;

            Position memory position = s.allPositionsMap[positionId];
            require(position.partyA == party, "PositionId mismatch");

            (int256 _uPnLIsolatedA, ) = _calculateUPnLIsolated(
                position.side,
                position.currentBalanceUnits,
                position.initialNotionalUsd,
                bidPrice,
                askPrice
            );

            uPnLCrossA += _uPnLIsolatedA;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { PositionType, OrderType, HedgerMode, Side } from "../libraries/LibEnums.sol";

enum RequestForQuoteState {
    NEW,
    CANCELED,
    ACCEPTED
}

enum PositionState {
    OPEN,
    MARKET_CLOSE_REQUESTED,
    LIMIT_CLOSE_REQUESTED,
    LIMIT_CLOSE_ACTIVE,
    CLOSED,
    LIQUIDATED
    // TODO: add cancel limit close
}

struct RequestForQuote {
    uint256 creationTimestamp;
    uint256 mutableTimestamp;
    uint256 rfqId;
    RequestForQuoteState state;
    PositionType positionType;
    OrderType orderType;
    address partyA;
    address partyB;
    HedgerMode hedgerMode;
    uint256 marketId;
    Side side;
    uint256 notionalUsd;
    uint256 lockedMarginA;
    uint256 protocolFee;
    uint256 liquidationFee;
    uint256 cva;
    uint256 minExpectedUnits;
    uint256 maxExpectedUnits;
    address affiliate;
}

struct Position {
    uint256 creationTimestamp;
    uint256 mutableTimestamp;
    uint256 positionId;
    bytes16 uuid;
    PositionState state;
    PositionType positionType;
    uint256 marketId;
    address partyA;
    address partyB;
    Side side;
    uint256 lockedMarginA;
    uint256 lockedMarginB;
    uint256 protocolFeePaid;
    uint256 liquidationFee;
    uint256 cva;
    uint256 currentBalanceUnits;
    uint256 initialNotionalUsd;
    address affiliate;
}

library MasterStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("diamond.standard.master.agreement.storage");

    struct Layout {
        // Balances
        mapping(address => uint256) accountBalances;
        mapping(address => uint256) marginBalances;
        mapping(address => uint256) crossLockedMargin;
        mapping(address => uint256) crossLockedMarginReserved; // TODO: rename this to lockedMarginReserved
        // RequestForQuotes
        mapping(uint256 => RequestForQuote) requestForQuotesMap;
        uint256 requestForQuotesLength;
        mapping(address => uint256) crossRequestForQuotesLength;
        // Positions
        mapping(uint256 => Position) allPositionsMap;
        uint256 allPositionsLength;
        mapping(address => uint256) openPositionsIsolatedLength; // DEPRECATED
        mapping(address => uint256) openPositionsCrossLength;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { Side, PositionType } from "../../libraries/LibEnums.sol";
import { PositionPrice } from "../../oracle/OracleInternal.sol";
import { MasterStorage, Position, PositionState } from "../MasterStorage.sol";
import { MasterCalculators } from "../MasterCalculators.sol";
import { ICloseEvents } from "./ICloseEvents.sol";

abstract contract CloseBase is ICloseEvents {
    using MasterStorage for MasterStorage.Layout;

    function _onClosePosition(uint256 positionId, PositionPrice memory positionPrice) internal {
        MasterStorage.Layout storage s = MasterStorage.layout();
        Position storage position = s.allPositionsMap[positionId];

        uint256 price = position.side == Side.BUY ? positionPrice.bidPrice : positionPrice.askPrice;

        // Calculate the PnL of PartyA
        (int256 uPnLA, ) = MasterCalculators.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Distribute the PnL accordingly
        if (position.positionType == PositionType.ISOLATED) {
            _distributePnLIsolated(position.positionId, uPnLA);
        } else {
            _distributePnLCross(position.positionId, uPnLA);
        }

        // Return parties their reserved liquidation fees
        s.marginBalances[position.partyA] += (position.liquidationFee + position.cva);
        s.marginBalances[position.partyB] += (position.liquidationFee + position.cva);

        // Emit event prior to updating the balance state
        emit ClosePosition(positionId, position.partyA, position.partyB, position.currentBalanceUnits, price);

        // Update Position
        position.state = PositionState.CLOSED;
        position.currentBalanceUnits = 0;
        position.mutableTimestamp = block.timestamp;

        // Update mappings
        if (position.positionType == PositionType.CROSS) {
            s.openPositionsCrossLength[position.partyA]--;
        }
    }

    function _updatePositionState(Position storage position, PositionState state) internal {
        position.state = state;
        position.mutableTimestamp = block.timestamp;
    }

    function _distributePnLIsolated(uint256 positionId, int256 uPnLA) private {
        MasterStorage.Layout storage s = MasterStorage.layout();
        Position memory position = s.allPositionsMap[positionId];
        require(position.positionType == PositionType.ISOLATED, "Invalid position type");

        /**
         * Winning party receives the PNL.
         * Losing party pays for the PNL using isolated margin.
         */

        if (uPnLA >= 0) {
            uint256 amount = uint256(uPnLA);
            if (amount >= position.lockedMarginB) {
                // Technically this represents a liquidation.
                s.marginBalances[position.partyA] += (position.lockedMarginA + position.lockedMarginB);
            } else {
                s.marginBalances[position.partyA] += (position.lockedMarginA + amount);
                s.marginBalances[position.partyB] += (position.lockedMarginB - amount);
            }
        } else {
            uint256 amount = uint256(-uPnLA);
            if (amount >= position.lockedMarginA) {
                // Technically this represents a liquidation.
                s.marginBalances[position.partyB] += (position.lockedMarginA + position.lockedMarginB);
            } else {
                s.marginBalances[position.partyB] += (position.lockedMarginB + amount);
                s.marginBalances[position.partyA] += (position.lockedMarginA - amount);
            }
        }
    }

    function _distributePnLCross(uint256 positionId, int256 uPnLA) private {
        MasterStorage.Layout storage s = MasterStorage.layout();
        Position memory position = s.allPositionsMap[positionId];
        require(position.positionType == PositionType.CROSS, "Invalid position type");

        /**
         * Winning party receives the PNL.
         * Losing party pays for the PNL using his globally lockedMargin (Cross).
         */
        address partyA = position.partyA;
        address partyB = position.partyB;

        if (uPnLA >= 0) {
            /**
             * PartyA will NOT receive his lockedMargin back,
             * he'll have to withdraw it manually. This has to do with the
             * risk of liquidation + the fact that his initially lockedMargin
             * could be greater than what he currently has locked.
             */
            uint256 amount = uint256(uPnLA);
            if (amount >= position.lockedMarginB) {
                // Technically this represents a liquidation.
                s.marginBalances[position.partyA] += position.lockedMarginB;
                // We don't have to reset the lockedMargin of PartyB because he's Isolated.
            } else {
                s.marginBalances[position.partyA] += amount;
                s.marginBalances[position.partyB] += (position.lockedMarginB - amount);
            }
        } else {
            uint256 amount = uint256(-uPnLA);
            // PartyB is Isolated by nature.
            if (amount >= s.crossLockedMargin[partyA]) {
                // Technically this represents a liquidation.
                s.marginBalances[partyB] += (s.crossLockedMargin[partyA] + position.lockedMarginB);
                s.crossLockedMargin[partyA] = 0;
            } else {
                s.marginBalances[partyB] += (position.lockedMarginB + amount);
                s.crossLockedMargin[partyA] -= amount;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { OrderType } from "../../libraries/LibEnums.sol";
import { OracleInternal } from "../../oracle/OracleInternal.sol";
import { MasterStorage, Position, PositionState } from "../MasterStorage.sol";
import { CloseBase } from "./CloseBase.sol";

contract ClosePosition is CloseBase {
    using MasterStorage for MasterStorage.Layout;

    function closePosition(uint256 positionId, uint256 avgPriceUsd) external {
        Position memory position = MasterStorage.layout().allPositionsMap[positionId];

        if (position.state == PositionState.MARKET_CLOSE_REQUESTED) {
            _closeMarket(position, avgPriceUsd);
        } else {
            revert("Other modes not implemented yet");
        }
    }

    function _closeMarket(Position memory position, uint256 avgPriceUsd) private {
        require(position.partyB == msg.sender, "Invalid party");
        _onClosePosition(
            position.positionId,
            OracleInternal.createPositionPrice(position.positionId, avgPriceUsd, avgPriceUsd)
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface ICloseEvents {
    event RequestClosePosition(uint256 indexed positionId, address partyA, address partyB);
    event CancelClosePosition(uint256 indexed positionId, address partyA, address partyB);
    event ClosePosition(
        uint256 indexed positionId,
        address partyA,
        address partyB,
        uint256 amountUnits,
        uint256 avgPriceUsd
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { OracleStorage, PublicKey, SchnorrSign, PositionPrice } from "./OracleStorage.sol";
import { SchnorrSECP256K1Verifier } from "./SchnorrSECP256K1Verifier.sol";

library OracleInternal {
    using OracleStorage for OracleStorage.Layout;
    using ECDSA for bytes32;

    /* ========== VIEWS ========== */

    function getMuonAppId() internal view returns (uint256) {
        return OracleStorage.layout().muonAppId;
    }

    function getMuonAppCID() internal view returns (bytes memory) {
        return OracleStorage.layout().muonAppCID;
    }

    function getMuonPublicKey() internal view returns (PublicKey memory) {
        return OracleStorage.layout().muonPublicKey;
    }

    function getMuonGatewaySigner() internal view returns (address) {
        return OracleStorage.layout().muonGatewaySigner;
    }

    function getSignatureExpiryPeriod() internal view returns (uint256) {
        return OracleStorage.layout().signatureExpiryPeriod;
    }

    function verifyTSSOrThrow(string calldata data, bytes calldata reqId, SchnorrSign calldata sign) internal view {
        (uint256 muonAppId, bytes memory muonAppCID, PublicKey memory muonPublicKey, ) = _getMuonConstants();

        bytes32 hash = keccak256(abi.encodePacked(muonAppId, reqId, muonAppCID, data));
        bool verified = _verifySignature(uint256(hash), sign, muonPublicKey);
        require(verified, "TSS not verified");
    }

    // To get the gatewaySignature, gwSign=true should be passed to the MuonApp.
    function verifyTSSAndGatewayOrThrow(
        bytes32 hash,
        SchnorrSign calldata sign,
        bytes calldata gatewaySignature
    ) internal view {
        (, , PublicKey memory muonPublicKey, address muonGatewaySigner) = _getMuonConstants();

        bool verified = _verifySignature(uint256(hash), sign, muonPublicKey);
        require(verified, "TSS not verified");

        hash = hash.toEthSignedMessageHash();
        address gatewaySigner = hash.recover(gatewaySignature);
        require(gatewaySigner == muonGatewaySigner, "Invalid gateway signer");
    }

    function verifyPositionPriceOrThrow(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice,
        uint256 timestamp,
        bytes calldata reqId,
        SchnorrSign calldata sign,
        bytes calldata gatewaySignature
    ) internal view {
        (uint256 muonAppId, bytes memory muonAppCID, , ) = _getMuonConstants();
        require(timestamp + getSignatureExpiryPeriod() >= block.timestamp, "Signature expired");

        bytes32 hash = keccak256(
            abi.encodePacked(muonAppId, reqId, muonAppCID, positionId, bidPrice, askPrice, timestamp)
        );
        verifyTSSAndGatewayOrThrow(hash, sign, gatewaySignature);
    }

    function verifyPositionPricesOrThrow(
        uint256[] memory positionIds,
        uint256[] memory bidPrices,
        uint256[] memory askPrices,
        uint256 timestamp,
        bytes calldata reqId,
        SchnorrSign calldata sign,
        bytes calldata gatewaySignature
    ) internal view {
        (uint256 muonAppId, bytes memory muonAppCID, , ) = _getMuonConstants();
        require(timestamp + getSignatureExpiryPeriod() >= block.timestamp, "Signature expired");

        bytes32 hash = keccak256(
            abi.encodePacked(muonAppId, reqId, muonAppCID, positionIds, bidPrices, askPrices, timestamp)
        );
        verifyTSSAndGatewayOrThrow(hash, sign, gatewaySignature);
    }

    function createPositionPrice(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice
    ) internal pure returns (PositionPrice memory positionPrice) {
        return PositionPrice(positionId, bidPrice, askPrice);
    }

    function createPositionPrices(
        uint256[] memory positionIds,
        uint256[] memory bidPrices,
        uint256[] memory askPrices
    ) internal pure returns (PositionPrice[] memory positionPrices) {
        require(
            positionIds.length == bidPrices.length && positionIds.length == askPrices.length,
            "Invalid position prices"
        );

        positionPrices = new PositionPrice[](positionIds.length);
        for (uint256 i = 0; i < positionIds.length; i++) {
            positionPrices[i] = PositionPrice(positionIds[i], bidPrices[i], askPrices[i]);
        }
    }

    /* ========== SETTERS ========== */

    function setMuonAppId(uint256 muonAppId) internal {
        OracleStorage.layout().muonAppId = muonAppId;
    }

    function setMuonAppCID(bytes calldata muonAppCID) internal {
        OracleStorage.layout().muonAppCID = muonAppCID;
    }

    function setMuonPublicKey(PublicKey memory muonPublicKey) internal {
        OracleStorage.layout().muonPublicKey = muonPublicKey;
    }

    function setMuonGatewaySigner(address muonGatewaySigner) internal {
        OracleStorage.layout().muonGatewaySigner = muonGatewaySigner;
    }

    function setSignatureExpiryPeriod(uint256 signatureExpiryPeriod) internal {
        OracleStorage.layout().signatureExpiryPeriod = signatureExpiryPeriod;
    }

    /* ========== PRIVATE ========== */

    function _getMuonConstants()
        private
        view
        returns (uint256 muonAppId, bytes memory muonAppCID, PublicKey memory muonPublicKey, address muonGatewaySigner)
    {
        return (getMuonAppId(), getMuonAppCID(), getMuonPublicKey(), getMuonGatewaySigner());
    }

    function _verifySignature(
        uint256 hash,
        SchnorrSign memory signature,
        PublicKey memory pubKey
    ) private pure returns (bool) {
        return
            SchnorrSECP256K1Verifier.verifySignature(
                pubKey.x,
                pubKey.parity,
                signature.signature,
                hash,
                signature.nonce
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

struct PublicKey {
    uint256 x;
    uint8 parity;
}

struct PositionPrice {
    uint256 positionId;
    uint256 bidPrice;
    uint256 askPrice;
}

library OracleStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("diamond.standard.oracle.storage");

    struct Layout {
        uint256 muonAppId;
        bytes muonAppCID;
        PublicKey muonPublicKey;
        address muonGatewaySigner;
        uint256 signatureExpiryPeriod;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-version
pragma solidity  >=0.7.0 <0.9.0;

library SchnorrSECP256K1Verifier {
  // See https://en.bitcoin.it/wiki/Secp256k1 for this constant.
  uint256 constant public Q = // Group order of secp256k1
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
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
    address nonceTimesGeneratorAddress) internal pure returns (bool) {
    require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
    // Avoid signature malleability from multiple representations for ℤ/Qℤ elts
    require(signature < Q, "signature must be reduced modulo Q");

    // Forbid trivial inputs, to avoid ecrecover edge cases. The main thing to
    // avoid is something which causes ecrecover to return 0x0: then trivial
    // signatures could be constructed with the nonceTimesGeneratorAddress input
    // set to 0x0.
    //
    require(nonceTimesGeneratorAddress != address(0) && signingPubKeyX > 0 &&
      signature > 0 && msgHash > 0, "no zero inputs allowed");

    uint256 msgChallenge = // "e"
      uint256(keccak256(abi.encodePacked(nonceTimesGeneratorAddress, msgHash)));

    // Verify msgChallenge * signingPubKey + signature * generator ==
    //        nonce * generator
    //
    // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
    // The point corresponding to the address returned by
    // ecrecover(-s*r,v,r,e*r) is (r⁻¹ mod Q)*(e*r*R-(-s)*r*g)=e*R+s*g, where R
    // is the (v,r) point. See https://crypto.stackexchange.com/a/18106
    //
    address recoveredAddress = ecrecover(
      bytes32(Q - mulmod(signingPubKeyX, signature, Q)),
      // https://ethereum.github.io/yellowpaper/paper.pdf p. 24, "The
      // value 27 represents an even y value and 28 represents an odd
      // y value."
      (pubKeyYParity == 0) ? 27 : 28,
      bytes32(signingPubKeyX),
      bytes32(mulmod(msgChallenge, signingPubKeyX, Q)));
    return nonceTimesGeneratorAddress == recoveredAddress;
  }

  function validatePubKey (uint256 signingPubKeyX) internal pure {
    require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
  }
}