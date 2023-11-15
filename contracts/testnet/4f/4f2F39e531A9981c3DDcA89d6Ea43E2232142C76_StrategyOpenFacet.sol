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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

error TooFewSignLens();
error DuplicateSigner();
error InvalidStrategy();
error InvalidSignature();
error InvalidSignerNum();
error InvalidMarkPrice();
error RepeatedSignerAddress();
error InvalidPortfolioMargin();
error InvalidObservationsTimestamp(uint256 observationsTimestamp, uint256 latestTransmissionTimestamp);
error InvalidAddress(address thrower, address inputAddress);
error InvalidPosition();

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {LibVault} from "../libraries/LibVault.sol";
import {LibAgent} from "../libraries/LibAgent.sol";
import {LibEIP712} from "../libraries/LibEIP712.sol";
import {Constants} from "../../utils/Constants.sol";
import {InvalidStrategy} from "../errors/GenericErrors.sol";
import {IStrategyOpen} from "../interfaces/IStrategyOpen.sol";
import {ReentrancyGuard} from "../security/ReentrancyGuard.sol";
import {StrategyTypes} from "../libraries/StrategyTypes.sol";
import {LibMarketPricer} from "../libraries/LibMarketPricer.sol";
import {LibPositionCore} from "../libraries/LibPositionCore.sol";
import {LibStrategyOpen} from "../libraries/LibStrategyOpen.sol";
import {LibStrategyConfig} from "../libraries/LibStrategyConfig.sol";
import {LibAccessControlEnumerable} from "../libraries/LibAccessControlEnumerable.sol";

/**
 * @title DEDERI Strategy Open
 * @author dederi
 * @notice This contract is strategy Open 涵盖创建策略，创建合并.
 */
contract StrategyOpenFacet is IStrategyOpen, ReentrancyGuard {
    using LibStrategyOpen for LibStrategyOpen.Layout;
    using LibStrategyConfig for LibStrategyConfig.Layout;

    /**
     * @notice StrategyCreationRequested
     * @param makerRequestHash 做市商 request Hash
     * @param makerStrategy 做市商的策略请求结构体
     * @param takerRequestHash 用户的 request Hash
     * @param takerStrategy 用户的策略请求结构体
     */
    event StrategyCreationRequested(
        bytes32 makerRequestHash,
        bytes32 takerRequestHash,
        StrategyTypes.StrategyRequest makerStrategy,
        StrategyTypes.StrategyRequest takerStrategy
    );

    /**
     * @notice StrategyCreationExecuted
     * @param makerRequestHash 做市商 request Hash
     * @param takerRequestHash 用户的 request Hash
     * @param makerStrategyId 做市商的策略id
     * @param takerStrategyId 用户的策略id
     * @param makerMergeId 做市商的策略合并id
     * @param takerMergeId 用户的策略合并id
     */
    event StrategyCreationExecuted(
        bytes32 makerRequestHash,
        bytes32 takerRequestHash,
        uint256 makerStrategyId,
        uint256 takerStrategyId,
        uint256 makerMergeId,
        uint256 takerMergeId
    );

    function createStrategy(
        address receiver,
        bytes memory signature,
        StrategyTypes.StrategyRequest memory makerStrategy,
        StrategyTypes.StrategyRequest memory takerStrategy
    ) external {
        if (makerStrategy.timestamp < block.timestamp) {
            revert StrategyExpired();
        }
        LibStrategyConfig._checkSamePosition(makerStrategy);
        LibStrategyConfig._checkSamePosition(takerStrategy);
        bool isSame = LibStrategyConfig._validateStrategy(makerStrategy, takerStrategy);
        if (!isSame) {
            revert InvalidStrategy();
        }

        LibEIP712._checkSignatureExists(makerStrategy.admin, signature);
        LibEIP712._verify(receiver, signature, makerStrategy);

        address makerAddr = LibAgent._getAdminAndUpdate(receiver);
        address takerAddr = LibAgent._getAdminAndUpdate(msg.sender);
        makerStrategy.admin = makerAddr;
        takerStrategy.admin = takerAddr;

        bytes32 makerRequestHash = LibStrategyConfig._getRequestHashAndUpdateNonce(makerAddr);
        bytes32 takerRequestHash = LibStrategyConfig._getRequestHashAndUpdateNonce(takerAddr);

        LibStrategyConfig._updateUserRequestStrategy(makerRequestHash, makerStrategy);
        LibStrategyConfig._updateUserRequestStrategy(takerRequestHash, takerStrategy);

        emit StrategyCreationRequested(makerRequestHash, takerRequestHash, makerStrategy, takerStrategy);
    }

    function executeCreateStrategy(bytes32 makerRequestHash, bytes32 takerRequestHash) external nonReentrant {
        LibAccessControlEnumerable.checkRole(Constants.KEEPER_ROLE);
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        StrategyTypes.StrategyRequest memory makerStrategy = l.userRequestStrategy[makerRequestHash];
        StrategyTypes.StrategyRequest memory takerStrategy = l.userRequestStrategy[takerRequestHash];

        // TODO 总的抵押品 权利金 + 抵押品
        //以 USDC 加入到 collateral 中
        LibMarketPricer._checkCollateralSufficiency(makerStrategy.collaterals, makerRequestHash, true);
        LibMarketPricer._checkCollateralSufficiency(takerStrategy.collaterals, takerRequestHash, true);

        // 权利金支付方可用余额减少，不可用余额增加（权利金支付，都只改变可用余额）
        LibVault._transferPremium(makerStrategy, makerStrategy.admin, takerStrategy.admin);
        //将保证金从用户账户划转到策略账户
        //
        LibVault._marginDecrease(makerStrategy.admin, makerStrategy.collaterals);
        LibVault._marginDecrease(takerStrategy.admin, takerStrategy.collaterals);
        //TODO 需要在 nft 判断是不是是加腿还是创建？
        // 权利金加到抵押品部分放到 nft 去做
        // 将最终权利金支付方和接收方包括数量返回传到 nft

        uint256 makerStrategyId = LibPositionCore._handleCreateStrategy(makerStrategy, makerStrategy.admin);
        uint256 takerStrategyId = LibPositionCore._handleCreateStrategy(takerStrategy, takerStrategy.admin);

        delete l.userRequestStrategy[makerRequestHash];
        delete l.userRequestStrategy[takerRequestHash];

        // 2个用户的 开仓+合并 发生策略id
        emit StrategyCreationExecuted(
            makerRequestHash,
            takerRequestHash,
            makerStrategyId,
            takerStrategyId,
            makerStrategy.mergeId,
            takerStrategy.mergeId
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import {IUniswapV3SwapCallback} from "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

/**
 * @dev Interface for chainlink price feeds used by Dederi
 */
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function getRoundData(
        uint80 _roundId
    ) external view returns (uint80 roundId, int answer, uint startedAt, uint updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int answer, uint startedAt, uint updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

interface IDiamondCut {
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Add=0, Replace=1, Remove=2
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Add/replace/remove any number of functions and optionally execute
     * a function with delegatecall
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     * _calldata is executed with delegatecall on _init
     **/
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "../libraries/StrategyTypes.sol";

interface IStrategyOpen {
    error StrategyExpired();

    function createStrategy(
        address receiver,
        bytes memory signature,
        StrategyTypes.StrategyRequest memory makerStrategy,
        StrategyTypes.StrategyRequest memory takerStrategy
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibAccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.AccessControlEnumerable");

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
        mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
        mapping(bytes4 => bool) supportedInterfaces;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function checkRole(bytes32 role) internal view {
        checkRole(role, msg.sender);
    }

    function checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function hasRole(bytes32 role, address account) internal view returns (bool) {
        LibAccessControlEnumerable.Layout storage l = LibAccessControlEnumerable.layout();
        return l.roles[role].members[account];
    }

    function grantRole(bytes32 role, address account) internal {
        LibAccessControlEnumerable.Layout storage l = LibAccessControlEnumerable.layout();
        if (!hasRole(role, account)) {
            l.roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
            l.roleMembers[role].add(account);
        }
    }

    function revokeRole(bytes32 role, address account) internal {
        LibAccessControlEnumerable.Layout storage l = LibAccessControlEnumerable.layout();
        if (hasRole(role, account)) {
            l.roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
            l.roleMembers[role].remove(account);
        }
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        LibAccessControlEnumerable.Layout storage l = LibAccessControlEnumerable.layout();
        bytes32 previousAdminRole = l.roles[role].adminRole;
        l.roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

library LibAgent {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.Agent");

    struct Layout {
        /// @notice /* agent */ /* admin */
        mapping(address => address) pendingAgentToAdmin;
        /// @notice Associates agents with their corresponding admins /* agent */ /* admin */
        mapping(address => address) agentToAdmin;
        /// @notice Keeps a record of whether an agent has ever acted as an admin.
        mapping(address => bool) adminHistory;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice If the address of the admin is the zero address,
    /// it signifies that this address serves as the admin address, and its status should be recorded.
    function _getAdminAndUpdate(address _account) internal returns (address) {
        LibAgent.Layout storage l = LibAgent.layout();
        address admin = l.agentToAdmin[_account];
        if (admin == address(0)) {
            _updateAdminHistory(l, _account);
            return _account;
        } else {
            return admin;
        }
    }

    /// @notice Update the address status.
    function _updateAdminHistory(LibAgent.Layout storage l, address _account) internal {
        if (!l.adminHistory[_account]) {
            l.adminHistory[_account] = true;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "./StrategyTypes.sol";
import {LibStrategyConfig} from "./LibStrategyConfig.sol";
import {LibPositionCore} from "./LibPositionCore.sol";

library LibCollateral {
    using LibPositionCore for LibPositionCore.Layout;
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.Collateral");

    error InvalidCollateral(address collateralToken, uint256 collateralAmount);
    error CollateralDuplicates(address token);

    struct Layout {
        /// @notice 支持的抵押品
        mapping(address => bool) isReserveToken;
        /**
         * @notice Official mapping of cTokens -> Market metadata
         * @dev Used e.g. to determine if a market is supported
         */
        mapping(address => StrategyTypes.Market) markets;
        /// @notice 所有市场的标的资产地址
        address[] allMarkets;
        /// @notice 减少保证金请求中需要的参数
        mapping(bytes32 => StrategyTypes.DecreaseStrategyCollateralRequest) userDSCRequest;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice 此函数用于检查抵押品数组中是否存在重复的抵押品，如果有重复，将触发错误。
    function _checkCollateralDuplicates(StrategyTypes.CollateralInfo[] memory collaterals) internal view {
        uint256 collateralsLen = collaterals.length;
        for (uint256 i; i < collateralsLen; ) {
            // 验证抵押品数量是否大于0，验证抵押品token是否支持
            LibStrategyConfig._ensureSupportCollateral(collaterals[i].collateralToken);
            if (collaterals[i].collateralAmount == 0) {
                revert InvalidCollateral(collaterals[i].collateralToken, collaterals[i].collateralAmount);
            }
            for (uint256 j = i + 1; j < collateralsLen; ) {
                if (collaterals[i].collateralToken == collaterals[j].collateralToken) {
                    revert CollateralDuplicates(collaterals[i].collateralToken);
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice 将内存抵押品数据push到storage中
     * @param collateralsStorage 存储中空的抵押品数组
     * @param collateralsMemory 内存中有数据的抵押品数组
     */
    function _collateralsMemoryToStorage(
        StrategyTypes.CollateralInfo[] storage collateralsStorage,
        StrategyTypes.CollateralInfo[] memory collateralsMemory
    ) internal {
        uint256 collLen = collateralsMemory.length;
        for (uint256 i; i < collLen; ) {
            StrategyTypes.CollateralInfo memory collInfo = collateralsMemory[i];
            collateralsStorage.push(collInfo);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice 增加抵押品
     * @param tokenId 当前策略Id
     * @param newCollaterals 待增加的抵押品信息
     */
    function _increaseStrategyCollateral(
        uint256 tokenId,
        StrategyTypes.CollateralInfo[] memory newCollaterals
    ) internal {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        StrategyTypes.StrategyData storage originalStrategy = l.strategies[tokenId];
        // 先遍历待变化抵押品，再遍历原始抵押品
        _collateralsAdd(newCollaterals, originalStrategy.collaterals);
    }

    /**
     * @notice 减少抵押品
     * @param tokenId 当前策略Id
     * @param newCollaterals 待减少的抵押品信息
     */
    function _decreaseStrategyCollateral(
        uint256 tokenId,
        StrategyTypes.CollateralInfo[] memory newCollaterals
    ) internal returns (StrategyTypes.CollateralInfo[] memory) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        // 获取策略抵押品
        uint256 newCollateralLen = newCollaterals.length;
        newCollateralLen;
        StrategyTypes.StrategyData storage originalStrategy = l.strategies[tokenId];
        uint256 originalCollateralLen = originalStrategy.collaterals.length;
        originalCollateralLen;
        // 先遍历待添加的（待减少抵押品），再遍历原始待push的（原始抵押品）
        _collateralsSub(newCollaterals, originalStrategy.collaterals);
        return originalStrategy.collaterals;
    }

    /// @notice 把抵押品数组A 从抵押品数组B中减除
    /// @dev 注意2个抵押品数组里面不能有重复的；即2个抵押品是正确的，并且抵押品数组A包含在数组B中
    function _collateralsSub(
        StrategyTypes.CollateralInfo[] memory collArrayA,
        StrategyTypes.CollateralInfo[] storage collArrayB
    ) internal {
        uint256 collALen = collArrayA.length;
        uint256 collBLen = collArrayB.length;
        for (uint256 i; i < collALen; ) {
            StrategyTypes.CollateralInfo memory collAInfo = collArrayA[i];
            bool found;
            for (uint256 j; j < collBLen; ) {
                StrategyTypes.CollateralInfo memory collBInfo = collArrayB[j];
                if (collAInfo.collateralToken == collBInfo.collateralToken) {
                    // 记录抵押品
                    collArrayB[i].collateralAmount -= collAInfo.collateralAmount;
                    found = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            if (!found) {
                revert InvalidCollateral(collAInfo.collateralToken, collAInfo.collateralAmount);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice 把抵押品数组A 添加到抵押品数组B中
    /// @dev 注意2个抵押品数组里面不能有重复的；即2个抵押品是正确的
    function _collateralsAdd(
        StrategyTypes.CollateralInfo[] memory collArrayA,
        StrategyTypes.CollateralInfo[] storage collArrayB
    ) internal {
        uint256 collALen = collArrayA.length;
        for (uint256 i; i < collALen; ) {
            StrategyTypes.CollateralInfo memory collAInfo = collArrayA[i];
            bool found;
            for (uint256 j; j < collArrayB.length; ) {
                StrategyTypes.CollateralInfo memory collBInfo = collArrayB[j];
                if (collAInfo.collateralToken == collBInfo.collateralToken) {
                    // 记录抵押品
                    collArrayB[i].collateralAmount += collAInfo.collateralAmount;
                    found = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            if (!found) {
                collArrayB.push(collAInfo);
            }
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "../interfaces/IDiamondCut.sol";

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // Used in ReentrancyGuard
        uint256 status;
        bool paused;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            bytes4[] memory _functionSelectors = _diamondCut[facetIndex].functionSelectors;
            require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
            unchecked {
                facetIndex++;
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
            unchecked {
                selectorIndex++;
            }
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
            unchecked {
                selectorIndex++;
            }
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
            unchecked {
                selectorIndex++;
            }
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Constants} from "../../utils/Constants.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {StrategyTypes} from "./StrategyTypes.sol";

/**
 * @title EIP712
 * @author dederi
 * @notice 提取来自OZ.
 */
library LibEIP712 {
    error InvalidSignature();
    error SignatureAlreadyUsed(address user);

    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.EIP712");
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    using ECDSA for bytes32;

    struct Layout {
        /// @custom:oz-renamed-from _HASHED_NAME
        bytes32 _hashedName;
        /// @custom:oz-renamed-from _HASHED_VERSION
        bytes32 _hashedVersion;
        string _name;
        string _version;
        mapping(address => mapping(bytes32 => bool)) usedSignatureHash;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function _init(string memory name, string memory version) internal {
        LibEIP712.Layout storage l = LibEIP712.layout();
        l._name = name;
        l._version = version;

        // Reset prior values in storage if upgrading
        l._hashedName = 0;
        l._hashedVersion = 0;
    }

    /// @notice Reverts if the signature is used
    function _checkSignatureExists(address user, bytes memory signature) internal {
        LibEIP712.Layout storage l = LibEIP712.layout();
        bytes32 userSigHash = keccak256(signature);
        if (l.usedSignatureHash[user][userSigHash]) {
            revert SignatureAlreadyUsed(user);
        }
        // // Mark the signature as used
        l.usedSignatureHash[user][userSigHash] = true;
    }

    function _hashStrategy(StrategyTypes.StrategyRequest memory strategy) internal view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(Constants.STRATEGY_REQUEST_TYPE_HASH, strategy));
        return _hashTypedDataV4(structHash);
    }

    function _recoverSigner(bytes32 messageHash, bytes memory signature) internal pure returns (address) {
        return messageHash.recover(signature);
    }

    function _verify(
        address receiver,
        bytes memory signature,
        StrategyTypes.StrategyRequest memory strategy
    ) internal view {
        bytes32 messageHash = _hashStrategy(strategy);
        address signer = _recoverSigner(messageHash, signature);
        if (signer != receiver) {
            revert InvalidSignature();
        }
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function _eip712Domain()
        internal
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        // If the hashed name and version in storage are non-zero, the contract hasn't been properly initialized
        // and the EIP712 domain is not reliable, as it will be missing name and version.
        require(LibEIP712.layout()._hashedName == 0 && LibEIP712.layout()._hashedVersion == 0, "EIP712: Uninitialized");

        return (
            hex"0f", // 01111
            _EIP712Name(),
            _EIP712Version(),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator();
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash(), block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Name() internal view returns (string memory) {
        return LibEIP712.layout()._name;
    }

    /**
     * @dev The version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Version() internal view returns (string memory) {
        return LibEIP712.layout()._version;
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: In previous versions this function was . In this version you should override `_EIP712Name` instead.
     */
    function _EIP712NameHash() internal view returns (bytes32) {
        string memory name = _EIP712Name();
        if (bytes(name).length > 0) {
            return keccak256(bytes(name));
        } else {
            // If the name is empty, the contract may have been upgraded without initializing the new storage.
            // We return the name hash in storage if non-zero, otherwise we assume the name is empty by design.
            bytes32 hashedName = LibEIP712.layout()._hashedName;
            if (hashedName != 0) {
                return hashedName;
            } else {
                return keccak256("");
            }
        }
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: In previous versions this function was . In this version you should override `_EIP712Version` instead.
     */
    function _EIP712VersionHash() internal view returns (bytes32) {
        string memory version = _EIP712Version();
        if (bytes(version).length > 0) {
            return keccak256(bytes(version));
        } else {
            // If the version is empty, the contract may have been upgraded without initializing the new storage.
            // We return the version hash in storage if non-zero, otherwise we assume the version is empty by design.
            bytes32 hashedVersion = LibEIP712.layout()._hashedVersion;
            if (hashedVersion != 0) {
                return hashedVersion;
            } else {
                return keccak256("");
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {InvalidPortfolioMargin} from "../errors/GenericErrors.sol";
import {LibTWAPOracle} from "../libraries/LibTWAPOracle.sol";
import "../interfaces/IAggregatorV3.sol";
import "./StrategyTypes.sol";

library LibMarginOracle {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.MarginOracle");

    struct Signer {
        bool active;
        // Index of oracle in s_signersList
        uint8 index;
    }

    struct Layout {
        uint256 signerNum;
        mapping(bytes32 => StrategyTypes.MarginItemWithHash) portfolioMarginInfoByHash;
        mapping(address /* signer address */ => Signer) s_signers;
        // s_signersList contains the signing address of each oracle
        address[] s_signersList;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function _getPortfolioMarginInfoByHash(bytes32 requestHash) internal view returns (uint256, uint256) {
        LibMarginOracle.Layout storage l = LibMarginOracle.layout();
        StrategyTypes.MarginItemWithHash memory strategyItem = l.portfolioMarginInfoByHash[requestHash];
        if (strategyItem.updateAt != block.timestamp) {
            revert InvalidPortfolioMargin();
        }
        return (strategyItem.im, strategyItem.mm);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "./StrategyTypes.sol";
import {LibMarginOracle} from "../libraries/LibMarginOracle.sol";
import {LibSpotPriceOracle} from "../libraries/LibSpotPriceOracle.sol";

library LibMarketPricer {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.MarketPricer");

    uint256 public constant EXP_SCALE = 1e18;
    error InsufficientCollateral(uint256 correct, uint256 incorrect);
    struct Layout {
        uint256 abc;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /////////////
    // Getters //
    /////////////

    /// @notice 获取系统预估IM
    function _getEstimatedIM(bytes32 requestHash) internal view returns (uint256) {
        (uint256 im, ) = LibMarginOracle._getPortfolioMarginInfoByHash(requestHash);
        // EstimatedIM=max(115\%系统预估IM,400USDC)
        return max((115 * im) / 100, 400e18);
    }

    /**
     * @notice 检查抵押品是否足够，不正确revert
     * @param collaterals 用于查询maker的地址和相关保证金
     * @param requestHash 用于查询taker的地址和相关保证金
     * @param isIM 是否比较初始保证金
     */
    function _checkCollateralSufficiency(
        StrategyTypes.CollateralInfo[] memory collaterals,
        bytes32 requestHash,
        bool isIM
    ) internal view {
        uint256 usdcValue = _calculateUserCollateralValue(collaterals);
        // 这里后面要改成通用的
        (uint256 im, uint256 mm) = LibMarginOracle._getPortfolioMarginInfoByHash(requestHash);

        if (isIM) {
            if (usdcValue < im) {
                revert InsufficientCollateral(im, usdcValue);
            }
        } else {
            if (usdcValue < mm) {
                revert InsufficientCollateral(mm, usdcValue);
            }
        }
    }

    function _calculateUserCollateralValue(
        StrategyTypes.CollateralInfo[] memory collaterals
    ) internal view returns (uint256 tokenToUsdc) {
        uint256 collateralLen = collaterals.length;
        for (uint256 i = 0; i < collateralLen; ) {
            tokenToUsdc +=
                (LibSpotPriceOracle._getUnderlyingPrice(collaterals[i].collateralToken) *
                    collaterals[i].collateralAmount) /
                EXP_SCALE;

            unchecked {
                ++i;
            }
        }
        return tokenToUsdc;
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "./StrategyTypes.sol";
import {LibStrategyConfig} from "./LibStrategyConfig.sol";
import {LibCollateral} from "./LibCollateral.sol";
import {IStrategyNFT} from "../../interfaces/IStrategyNFT.sol";

library LibPositionCore {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.PositionCore");
    uint256 private constant LEG_LIMIT = 10;

    error OutOfLegLimit(uint256 num);
    error InvalidCollateral(address collateralToken, uint256 collateralAmount);
    // Splitting
    error SplittingUnapprovedStrategy(address thrower, address caller, uint256 strategyId);
    // Merging
    error MergingUnapprovedStrategy(address thrower, address caller, uint256 strategyId);
    error StrategyIsNotActive(uint256 strategyId);

    struct Layout {
        uint256 currentPositionId;
        IStrategyNFT strategyNFT;
        mapping(uint256 => StrategyTypes.StrategyData) strategies;
        mapping(uint256 => StrategyTypes.PositionData) positions;
        mapping(uint256 => StrategyTypes.Option) optionPositions;
        mapping(uint256 => StrategyTypes.Future) futurePositions;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @dev Returns an Strategy struct of a given strategyId
    function _getStrategy(uint256 strategyId) internal view returns (StrategyTypes.StrategyData memory) {
        return LibPositionCore.layout().strategies[strategyId];
    }

    /// @dev Returns an Strategy struct of a given strategyId
    function _getStrategyWithOwner(
        uint256 strategyId
    ) internal view returns (StrategyTypes.StrategyDataWithOwner memory) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        StrategyTypes.StrategyData memory strategy = l.strategies[strategyId];

        return
            StrategyTypes.StrategyDataWithOwner({
                strategyId: strategy.strategyId,
                positionIds: strategy.positionIds,
                collaterals: strategy.collaterals,
                realisedPnl: strategy.realisedPnl,
                isActive: strategy.isActive,
                owner: l.strategyNFT.ownerOf(strategyId) // if owner = zero addr , not notify invalid owner
            });
    }

    /// @dev 获取接下来的仓位ID
    function _getCurrentPositionId() internal returns (uint256) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        l.currentPositionId++;
        return l.currentPositionId;
    }

    /// @dev 从某个storage数组中移除某个key
    function _removePositionId(uint256[] storage ids, uint256 id) internal {
        uint256 idLen = ids.length;
        for (uint256 i; i < idLen; ) {
            if (ids[i] == id) {
                ids[i] = ids[idLen - 1];
                // Remove last element from array
                ids.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Mint 内部函数
     * @param to 接收方
     * @param newTokenId 是否指定tokenId，当参数为0表示不指定，反之指定
     */
    function _mintInternal(address to, uint256 newTokenId) internal returns (uint256) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        return l.strategyNFT.mintWithId(to, newTokenId);
    }

    /// @notice 调用StrategyNFT
    function _burn(uint256 tokenId) internal {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        l.strategyNFT.burn(tokenId);
    }

    /// @notice 创建nft 仓位数据
    function _handleCreateStrategy(
        StrategyTypes.StrategyRequest memory _strategy,
        address receipt
    ) internal returns (uint256 strategyId) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        // mint nft
        uint256 tokenId = _mintInternal(receipt, 0);
        // 创建策略
        l.strategies[tokenId].strategyId = tokenId;
        l.strategies[tokenId].timestamp = _strategy.timestamp;
        l.strategies[tokenId].isActive = true;

        // 抵押品
        uint256 collateralLen = _strategy.collaterals.length;
        for (uint256 i; i < collateralLen; ) {
            StrategyTypes.CollateralInfo memory collateral_ = _strategy.collaterals[i];
            l.strategies[tokenId].collaterals.push(collateral_);
            unchecked {
                ++i;
            }
        }

        // 创建option
        uint256 optionLen = _strategy.option.length;
        for (uint256 i; i < optionLen; ) {
            uint256 newPositionId = _getCurrentPositionId();
            // note: positionIds push
            l.strategies[tokenId].positionIds.push(newPositionId);

            l.positions[newPositionId].positionId = newPositionId;
            l.positions[newPositionId].assetType = StrategyTypes.AssetType.OPTION;

            StrategyTypes.Option memory option_ = _strategy.option[i];
            l.optionPositions[newPositionId].positionId = newPositionId;
            l.optionPositions[newPositionId].underlying = option_.underlying;
            l.optionPositions[newPositionId].strikePrice = option_.strikePrice;
            l.optionPositions[newPositionId].premium = option_.premium;
            l.optionPositions[newPositionId].expiryTime = option_.expiryTime;
            l.optionPositions[newPositionId].size = option_.size;
            l.optionPositions[newPositionId].optionType = option_.optionType;

            unchecked {
                ++i;
            }
        }
        // 创建future
        uint256 futureLen = _strategy.future.length;
        for (uint256 i; i < futureLen; ) {
            uint256 newPositionId = _getCurrentPositionId();
            // note: positionIds push
            l.strategies[tokenId].positionIds.push(newPositionId);

            l.positions[newPositionId].positionId = newPositionId;
            l.positions[newPositionId].assetType = StrategyTypes.AssetType.FUTURE;

            StrategyTypes.Future memory future_ = _strategy.future[i];
            l.futurePositions[newPositionId].positionId = newPositionId;
            l.futurePositions[newPositionId].underlying = future_.underlying;
            l.futurePositions[newPositionId].entryPrice = future_.entryPrice;
            l.futurePositions[newPositionId].expiryTime = future_.expiryTime;
            l.futurePositions[newPositionId].size = future_.size;
            l.futurePositions[newPositionId].isLong = future_.isLong;

            unchecked {
                ++i;
            }
        }
        return tokenId;
    }

    function _handleSplitStrategy(
        StrategyTypes.SpiltStrategyRequest memory requestParam
    ) internal returns (uint256 tokenIdA, uint256 tokenIdB) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        StrategyTypes.StrategyData storage originalStrategy = l.strategies[requestParam.strategyId];
        // 先判断owner是否正确
        if (msg.sender != l.strategyNFT.ownerOf(originalStrategy.strategyId)) {
            revert SplittingUnapprovedStrategy(address(this), msg.sender, originalStrategy.strategyId);
        }

        // 验证是否为激活状态
        if (!originalStrategy.isActive) {
            revert StrategyIsNotActive(originalStrategy.strategyId);
        }

        // A 用之前的保证金 B 用可用余额 不够的从账户中划转

        //

        // 设置原来的状态为false，并且burn 原来的
        originalStrategy.isActive = false;
        _burn(requestParam.strategyId);

        // mint 新的 A 和 B 并返回
        address owner = l.strategyNFT.ownerOf(originalStrategy.strategyId);
        tokenIdA = _mintInternal(owner, 0);
        tokenIdB = _mintInternal(owner, 0);

        StrategyTypes.StrategyData storage strategyA;
        strategyA = l.strategies[tokenIdA];
        strategyA.strategyId = tokenIdA;
        strategyA.timestamp = block.timestamp;
        // strategyA.realisedPnl;
        strategyA.isActive = true;

        uint256 originalLen = originalStrategy.positionIds.length;
        uint256 newlySpiltLen = requestParam.positionIds.length;
        newlySpiltLen;
        // 构造A的仓位id列表
        for (uint256 i; i < originalLen; ) {
            uint256 originalPositionId = originalStrategy.positionIds[i];
            for (uint256 j; j < originalLen; ) {
                uint256 newlyPositionId = requestParam.positionIds[i];
                if (originalPositionId != newlyPositionId) {
                    strategyA.positionIds.push(originalPositionId);
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        uint256 originalCollLen = originalStrategy.collaterals.length;
        uint256 topUpLen = requestParam.originalCollateralsToTopUp.length;
        for (uint256 i; i < originalCollLen; ) {
            StrategyTypes.CollateralInfo memory collInfo = originalStrategy.collaterals[originalCollLen];
            for (uint256 j; j < topUpLen; ) {
                StrategyTypes.CollateralInfo memory topUpCollInfo = requestParam.originalCollateralsToTopUp[topUpLen];
                if (collInfo.collateralToken == topUpCollInfo.collateralToken) {
                    strategyA.collaterals.push(
                        StrategyTypes.CollateralInfo({
                            collateralToken: collInfo.collateralToken,
                            collateralAmount: collInfo.collateralAmount + topUpCollInfo.collateralAmount
                        })
                    );
                }

                if (j + 1 == topUpLen) {
                    strategyA.collaterals.push(
                        StrategyTypes.CollateralInfo({
                            collateralToken: topUpCollInfo.collateralToken,
                            collateralAmount: topUpCollInfo.collateralAmount
                        })
                    );
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        StrategyTypes.StrategyData storage strategyB;
        strategyB = l.strategies[tokenIdB];
        strategyB.strategyId = tokenIdB;
        strategyB.timestamp = block.timestamp;
        // strategyB.realisedPnl;
        strategyB.isActive = true;
        strategyB.positionIds = requestParam.positionIds;
        // 构造b的抵押品
        uint256 newlySpiltCollLen = requestParam.newlySplitCollaterals.length;
        for (uint256 i; i < newlySpiltCollLen; ) {
            StrategyTypes.CollateralInfo memory collInfo = requestParam.newlySplitCollaterals[newlySpiltCollLen];
            strategyB.collaterals.push(collInfo);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev 查看2个期权是否为相反方向，相反则为true，反之为false
    function _isOppositeDirection(
        StrategyTypes.Option memory firstOption,
        StrategyTypes.Option memory nextOption
    ) internal pure returns (bool) {
        if (
            (firstOption.optionType == StrategyTypes.OptionType.LONG_CALL &&
                nextOption.optionType == StrategyTypes.OptionType.SHORT_CALL) ||
            (firstOption.optionType == StrategyTypes.OptionType.SHORT_CALL &&
                nextOption.optionType == StrategyTypes.OptionType.LONG_CALL) ||
            (firstOption.optionType == StrategyTypes.OptionType.LONG_PUT &&
                nextOption.optionType == StrategyTypes.OptionType.SHORT_PUT) ||
            (firstOption.optionType == StrategyTypes.OptionType.SHORT_PUT &&
                nextOption.optionType == StrategyTypes.OptionType.LONG_PUT)
        ) {
            return true;
        }
        return false;
    }

    /// @notice 合并相同方向的期权
    function _mergeOptionsOfSameDirection(
        StrategyTypes.Option memory firstOption,
        StrategyTypes.Option memory nextOption
    ) internal returns (uint256) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        uint256 positionId = _getCurrentPositionId();
        StrategyTypes.PositionData storage newPosition = l.positions[positionId];
        newPosition.positionId = positionId;
        newPosition.isActive = true;
        newPosition.assetType = StrategyTypes.AssetType.OPTION;

        // 构建optionData
        StrategyTypes.Option storage newOption = l.optionPositions[positionId];
        newOption.positionId = positionId;
        newOption.underlying = firstOption.underlying;
        newOption.expiryTime = firstOption.expiryTime;
        newOption.premium = firstOption.premium + nextOption.premium;
        newOption.strikePrice = firstOption.strikePrice;
        newOption.size = firstOption.size + nextOption.size;
        newOption.optionType = firstOption.optionType;
        return positionId;
    }

    /// @dev 合并相反方向的期权
    function _mergeOptionsOfOppositeDirection(
        StrategyTypes.Option memory firstOption,
        StrategyTypes.Option memory nextOption
    ) internal returns (uint256) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        uint256 positionId = _getCurrentPositionId();
        StrategyTypes.PositionData storage newPosition = l.positions[positionId];
        newPosition.positionId = positionId;
        newPosition.isActive = true;
        newPosition.assetType = StrategyTypes.AssetType.OPTION;

        // 构建optionData
        StrategyTypes.Option storage newOption = l.optionPositions[positionId];
        newOption.positionId = positionId;
        newOption.underlying = firstOption.underlying;
        newOption.expiryTime = firstOption.expiryTime;
        newOption.premium = firstOption.premium + nextOption.premium;
        newOption.strikePrice = firstOption.strikePrice;
        // 保留size差值
        newOption.size = firstOption.size > nextOption.size
            ? firstOption.size - nextOption.size
            : nextOption.size - firstOption.size;
        // 采取size大的作为新方向
        newOption.optionType = firstOption.size > nextOption.size ? firstOption.optionType : nextOption.optionType;
        return positionId;
    }

    /// @dev 合并相同方向的期货
    function _mergeFuturesOfSameDirection(
        StrategyTypes.Future memory firstFuture,
        StrategyTypes.Future memory nextFuture
    ) internal returns (uint256) {
        uint256 positionId = _getCurrentPositionId();

        firstFuture;
        nextFuture;
        return positionId;
    }

    /// @dev 合并相反方向的期货
    function _mergeFuturesOfOppositeDirection(
        StrategyTypes.Future memory firstFuture,
        StrategyTypes.Future memory nextFuture
    ) internal returns (uint256) {
        uint256 positionId = _getCurrentPositionId();

        firstFuture;
        nextFuture;
        return positionId;
    }

    /**
     * @notice 加腿+合并
     * @dev 只有StrategyManager可以调用
     * @param requestParam 请求参数
     * @return bool 如果可以完全抵消，返回真；反之返回假。
     */
    function _handleCreateAndMerge(StrategyTypes.Strategy memory requestParam) internal returns (bool) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        // 验证要合并策略的owner和状态(manager去做)
        // 验证新加的腿是否有重复的(manager去做)
        StrategyTypes.StrategyData storage originalStrategy = l.strategies[requestParam.mergeId];
        // 比较option
        uint256 newOptionsLen = requestParam.option.length;
        uint256 newFuturesLen = requestParam.future.length;
        for (uint256 i; i < newOptionsLen; ) {
            for (uint256 j; j < originalStrategy.positionIds.length; ) {
                StrategyTypes.Option memory firstOption = requestParam.option[i];
                StrategyTypes.Option memory nextOption = l.optionPositions[originalStrategy.positionIds[j]];
                // 验证期权到期日和行权价
                if (
                    firstOption.expiryTime == nextOption.expiryTime && firstOption.strikePrice == nextOption.strikePrice
                ) {
                    if (firstOption.optionType == nextOption.optionType) {
                        // 如果是相同期权类型 相加
                        // 构建positionData
                        uint256 positionId = _mergeOptionsOfSameDirection(firstOption, nextOption);

                        originalStrategy.positionIds.push(positionId);
                        // 移除旧的，添加新的
                        _removePositionId(originalStrategy.positionIds, nextOption.positionId);
                        originalStrategy.positionIds.push(positionId);
                        break;
                    } else {
                        if (_isOppositeDirection(firstOption, nextOption)) {
                            // 如果是相反方向，size相同则可以抵消
                            if (firstOption.size == nextOption.size) {
                                _removePositionId(originalStrategy.positionIds, nextOption.positionId);
                            } else {
                                // 当期权在不同方向也无法抵消，判断期权类型该是那个方向
                                // 构建positionData
                                uint256 positionId = _mergeOptionsOfOppositeDirection(firstOption, nextOption);

                                // 移除旧的，添加新的
                                _removePositionId(originalStrategy.positionIds, nextOption.positionId);
                                originalStrategy.positionIds.push(positionId);
                            }
                        }
                    }
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        // 比较future
        for (uint256 i; i < newFuturesLen; ) {
            for (uint256 j; j < originalStrategy.positionIds.length; ) {
                StrategyTypes.Future memory firstFuture = requestParam.future[i];
                StrategyTypes.Future memory nextFuture = l.futurePositions[originalStrategy.positionIds[j]];
                // 验证期权到期日和行权价
                if (firstFuture.isLong == nextFuture.isLong) {
                    // 如果是相同期货方向 相加
                    uint256 positionId = _mergeFuturesOfSameDirection(firstFuture, nextFuture);

                    // 移除旧的，添加新的
                    _removePositionId(originalStrategy.positionIds, nextFuture.positionId);
                    originalStrategy.positionIds.push(positionId);
                    break;
                } else {
                    uint256 positionId = _mergeFuturesOfOppositeDirection(firstFuture, nextFuture);

                    // 移除旧的，添加新的
                    _removePositionId(originalStrategy.positionIds, nextFuture.positionId);
                    originalStrategy.positionIds.push(positionId);
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        // 添加抵押品
        LibCollateral._collateralsAdd(requestParam.collaterals, originalStrategy.collaterals);
        // 校验腿数量
        uint256 mergeLen = originalStrategy.positionIds.length;
        if (mergeLen == 0) {
            return true;
        } else {
            if (mergeLen > LEG_LIMIT) {
                revert OutOfLegLimit(mergeLen);
            }
        }
        return false;
    }

    /**
     * @notice 合并策略
     * @dev Only ACTIVE strategies can be owned by users, so status does not need to be checked.
     * @param requestParam 请求参数
     * @return bool 如果可以完全抵消，返回真；反之返回假。
     * @return uint256 如果为0，说明策略完全抵消。
     */
    function _handleMergeStrategies(
        StrategyTypes.MergeStrategyRequest memory requestParam
    ) internal returns (bool, uint256) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        // 注意：合并前提是用户创建策略时候内部的腿策略没有要合并的，这样合并逻辑可以减少逻辑节省gas
        // 第一个
        StrategyTypes.StrategyData storage firstStrategy = l.strategies[requestParam.firstStrategyId];
        // 第二个
        StrategyTypes.StrategyData storage nextStrategy = l.strategies[requestParam.secondStrategyId];

        // 遍历策略下的仓位
        uint256 firstStrategyPositionsLen = firstStrategy.positionIds.length;
        uint256 nextStrategyPositionsLen = nextStrategy.positionIds.length;
        // 完全抵消是否就不需要mint
        uint256 currentTokenId = l.strategyNFT.currentTokenId();
        uint256 mergeStrategyId = currentTokenId++;
        // 构造新的合并策略storage
        StrategyTypes.StrategyData storage mergeStrategy = l.strategies[mergeStrategyId];

        // 先把合并的总仓位id放在数组中 这个逻辑和下面标注A合并了-》标注C

        for (uint256 j; j < nextStrategyPositionsLen; ) {
            StrategyTypes.PositionData memory nextStrategyPosition = l.positions[nextStrategy.positionIds[j]];
            if (!nextStrategyPosition.isActive) {
                break;
            } else {
                mergeStrategy.positionIds.push(nextStrategy.positionIds[j]);
            }
        }

        for (uint256 i; i < firstStrategyPositionsLen; ) {
            StrategyTypes.PositionData storage firstStrategyPosition = l.positions[firstStrategy.positionIds[i]];
            // 标注A
            if (!firstStrategyPosition.isActive) {
                break;
            } else {
                // 标注C
                mergeStrategy.positionIds.push(firstStrategy.positionIds[i]);
            }
            for (uint256 j; j < nextStrategyPositionsLen; ) {
                // 如果是已标记为可以合并的再次循环就跳过
                StrategyTypes.PositionData storage nextStrategyPosition = l.positions[nextStrategy.positionIds[j]];
                if (!nextStrategyPosition.isActive) {
                    break;
                }
                if (firstStrategyPosition.assetType == nextStrategyPosition.assetType) {
                    // 处理期权
                    if (firstStrategyPosition.assetType == StrategyTypes.AssetType.OPTION) {
                        StrategyTypes.Option memory firstOption = l.optionPositions[firstStrategy.positionIds[i]];
                        StrategyTypes.Option memory nextOption = l.optionPositions[nextStrategy.positionIds[j]];
                        // 验证期权到期日和行权价
                        if (
                            firstOption.expiryTime == nextOption.expiryTime &&
                            firstOption.strikePrice == nextOption.strikePrice
                        ) {
                            // 验证期权类型
                            if (firstOption.optionType == nextOption.optionType) {
                                // 如果是相同期权类型 相加
                                // 构建positionData
                                uint256 positionId = _mergeOptionsOfSameDirection(firstOption, nextOption);

                                mergeStrategy.positionIds.push(positionId);
                                // 移除旧的，添加新的
                                _removePositionId(mergeStrategy.positionIds, firstOption.positionId);
                                _removePositionId(mergeStrategy.positionIds, nextOption.positionId);
                                mergeStrategy.positionIds.push(positionId);
                                break;
                            } else {
                                if (_isOppositeDirection(firstOption, nextOption)) {
                                    // 如果是相反方向，size相同则可以抵消
                                    if (firstOption.size == nextOption.size) {
                                        // 相互抵消，移除腿id
                                        _removePositionId(mergeStrategy.positionIds, firstOption.positionId);
                                        _removePositionId(mergeStrategy.positionIds, nextOption.positionId);
                                    } else {
                                        // 当期权在不同方向也无法抵消，判断期权类型该是那个方向
                                        // 构建positionData
                                        uint256 positionId = _mergeOptionsOfOppositeDirection(firstOption, nextOption);

                                        // 移除旧的，添加新的
                                        _removePositionId(mergeStrategy.positionIds, firstOption.positionId);
                                        _removePositionId(mergeStrategy.positionIds, nextOption.positionId);
                                        mergeStrategy.positionIds.push(positionId);
                                    }
                                    // 在此括号下的策略可以合并，不过他是相反方向，因此可以使用break
                                    break;
                                }
                            }
                        }
                    } else {
                        // 处理期货
                        // 验证是否为多头还是空头以及到期日
                        StrategyTypes.Future storage firstFuture = l.futurePositions[firstStrategy.positionIds[i]];
                        StrategyTypes.Future storage nextFuture = l.futurePositions[nextStrategy.positionIds[j]];
                        if (firstFuture.expiryTime == nextFuture.expiryTime) {
                            // 验证期货 假如是相同方向
                            if (firstFuture.isLong == firstFuture.isLong) {
                                // 如果仓位方向相同
                                uint256 positionId = _mergeFuturesOfSameDirection(firstFuture, nextFuture);
                                _removePositionId(mergeStrategy.positionIds, firstFuture.positionId);
                                _removePositionId(mergeStrategy.positionIds, nextFuture.positionId);
                                mergeStrategy.positionIds.push(positionId);
                                break;
                            } else {
                                // 如果仓位方向相反
                                uint256 positionId = _mergeFuturesOfOppositeDirection(firstFuture, nextFuture);
                                _removePositionId(mergeStrategy.positionIds, firstFuture.positionId);
                                _removePositionId(mergeStrategy.positionIds, nextFuture.positionId);
                                mergeStrategy.positionIds.push(positionId);
                            }
                        }
                    }
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        // 处理完之后将这2个策略设置为未激活，然后burn掉2个nft
        firstStrategy.isActive = false;
        nextStrategy.isActive = false;
        _burn(firstStrategy.strategyId);
        _burn(nextStrategy.strategyId);

        // 如果合并后的策略是可以完全抵消：我就删除此结构体storage
        // currentTokenId--(不做)
        // 删除strategies
        uint256 mergeLen = mergeStrategy.positionIds.length;
        if (mergeLen == 0) {
            delete l.strategies[mergeStrategyId];
            return (true, 0);
        } else {
            // 验证腿数量
            if (mergeLen > LEG_LIMIT) {
                revert OutOfLegLimit(mergeLen);
            } else {
                // 更新合并策略storage剩余部分
                mergeStrategy.strategyId = mergeStrategyId;
                mergeStrategy.isActive = true;
                //mergeStrategy.realisedPnl；
                //mergeStrategy.timestamp;

                uint256 firstCollLen = firstStrategy.collaterals.length;
                for (uint256 i; i < firstCollLen; ) {
                    StrategyTypes.CollateralInfo memory collInfo = firstStrategy.collaterals[i];
                    mergeStrategy.collaterals.push(collInfo);
                    unchecked {
                        ++i;
                    }
                }
                LibCollateral._collateralsAdd(nextStrategy.collaterals, mergeStrategy.collaterals);
                LibCollateral._collateralsAdd(requestParam.newCollaterals, mergeStrategy.collaterals);

                // 如果不完全抵消
                // 我需要把nft mint 出来，需要传token id; 我要把2个策略的抵押品部分和新加进来的抵押品部分合并
                _mintInternal(requestParam.admin, mergeStrategyId);
            }
        }
        return (false, mergeStrategyId);
    }

    function _handleIncreasePositions(uint256 tokenId, StrategyTypes.Strategy memory strategy) internal {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        StrategyTypes.StrategyData storage originalStrategy = l.strategies[tokenId];
        if (!originalStrategy.isActive) {
            revert StrategyIsNotActive(originalStrategy.strategyId);
        }
        for (uint256 i = 0; i < strategy.option.length; ) {
            uint256 newPositionId = _getCurrentPositionId();
            // note: positionIds push
            originalStrategy.positionIds.push(newPositionId);

            StrategyTypes.PositionData storage position;
            position = l.positions[newPositionId];
            position.positionId = newPositionId;
            position.assetType = StrategyTypes.AssetType.OPTION;

            StrategyTypes.Option memory option_ = strategy.option[i];
            StrategyTypes.Option storage option;
            option = l.optionPositions[newPositionId];
            option.positionId = newPositionId;
            option.underlying = option_.underlying;
            option.strikePrice = option_.strikePrice;
            option.premium = option_.premium;
            option.expiryTime = option_.expiryTime;
            option.size = option_.size;
            option.optionType = option_.optionType;

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {InvalidAddress} from "../errors/GenericErrors.sol";
import {LibTWAPOracle} from "../libraries/LibTWAPOracle.sol";
import "../interfaces/IAggregatorV3.sol";

library LibSpotPriceOracle {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.SpotPriceOracle");

    /// @notice A common scaling factor to maintain precision
    uint256 public constant EXP_SCALE = 1e18;

    /// @notice Set this as asset address for ETH. This is the underlying address for vBNB
    address public constant NATIVE_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct TokenFeedConfig {
        /// @notice Underlying token address, which can't be a null address
        /// @notice Used to check if a token is supported
        /// @notice 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for Native
        address asset;
        /// @notice Chainlink feed address
        address feed;
        /// @notice Price expiration period of this asset
        uint256 maxStalePeriod;
    }

    struct PriceDataItem {
        uint256 price; // USDC-rate, multiplied by 1e18.
        uint256 observationsTimestamp; // when were observations made offchain
        uint256 transmissionTimestamp; // when was report received onchain
    }

    struct Layout {
        /// @notice The highest ratio of the new price to the anchor price that will still trigger the price to be updated
        uint256 upperBoundAnchorRatio;
        /// @notice The lowest ratio of the new price to the anchor price that will still trigger the price to be updated
        uint256 lowerBoundAnchorRatio;
        address usdcTokenAddr;
        /// @notice Token config by assets
        mapping(address => TokenFeedConfig) tokenFeedConfigs;
        /// @notice Manually set an override price, useful under extenuating conditions such as price feed failure
        mapping(address => PriceDataItem) priceData;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    error SpotOracle__PriceExpired();
    error InvalidAnswer(address asset, int256 answer, uint256 updatedAt, uint256 blockTimestamp);
    error InvalidObservationsTimestamp(uint256 observationsTimestamp, uint256 latestTransmissionTimestamp);
    error PriceOutOfRange(uint256 reportPrice, uint256 anchorPrice);

    ///////////////
    // Modifiers //
    ///////////////

    modifier notNullAddress(address someone) {
        if (someone == address(0)) revert InvalidAddress(address(this), someone);
        _;
    }

    /////////////
    // Getters //
    /////////////

    /**
     * @notice Get the underlying price of a listed underlying token asset 获取实时的价格，如果不是当前区块直接revert
     * @param asset Address of the asset
     * @return price Price in USDC, with 18 decimals of precision
     */
    function _getUnderlyingPrice(address asset) internal view returns (uint256) {
        LibSpotPriceOracle.Layout storage l = LibSpotPriceOracle.layout();
        if (asset == l.usdcTokenAddr) {
            return 1e18;
        }
        PriceDataItem memory priceData = l.priceData[asset];

        if (priceData.transmissionTimestamp != block.timestamp) {
            revert SpotOracle__PriceExpired();
        }
        return priceData.price;
    }

    /**
     * @notice Get the spot price of a listed underlying token asset 获取chainlink的价格，以USDC计价
     * @param asset Address of the asset
     * @return price Price in USDC, with 18 decimals of precision
     */
    function _getChainlinkPriceInUsdc(address asset) internal view returns (uint256) {
        LibSpotPriceOracle.Layout storage l = LibSpotPriceOracle.layout();
        if (asset == l.usdcTokenAddr) {
            return 1e18;
        }
        uint256 assetUsdPrice = _getChainlinkPrice(asset);
        uint256 usdcUsdPrice = _getChainlinkPrice(asset);
        uint256 assetUsdcPrice = (assetUsdPrice * 1e18) / usdcUsdPrice;

        return assetUsdcPrice;
    }

    /**
     * @notice Get the Chainlink price for an asset, revert if token config doesn't exist
     * @dev The precision of the price feed is used to ensure the returned price has 18 decimals of precision
     * @param asset Address of the asset
     * @return price Price in USD, with 18 decimals of precision
     */
    function _getChainlinkPrice(
        address asset
    ) internal view notNullAddress(LibSpotPriceOracle.layout().tokenFeedConfigs[asset].asset) returns (uint256) {
        LibSpotPriceOracle.Layout storage l = LibSpotPriceOracle.layout();
        TokenFeedConfig memory tokenConfig = l.tokenFeedConfigs[asset];
        AggregatorV3Interface feed = AggregatorV3Interface(tokenConfig.feed);

        // note: maxStalePeriod cannot be 0
        uint256 maxStalePeriod = tokenConfig.maxStalePeriod;

        (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();
        if (answer <= 0 || block.timestamp - updatedAt > maxStalePeriod) {
            revert InvalidAnswer(asset, answer, updatedAt, block.timestamp);
        }

        // Chainlink USD-denominated feeds store answers at 8 decimals, mostly
        uint256 decimalDelta = 18 - feed.decimals();

        return uint256(answer) * (10 ** decimalDelta);
    }

    /**
     * @notice This is called by the reporter whenever a new price is posted on-chain
     * @param reporterPrice the price from the reporter
     * @param anchorPrice the price from the other contract
     * @return valid bool
     */
    function _isWithinAnchor(uint256 reporterPrice, uint256 anchorPrice) internal view returns (bool) {
        LibSpotPriceOracle.Layout storage l = LibSpotPriceOracle.layout();
        if (reporterPrice > 0 && anchorPrice > 0) {
            uint256 minAnswer = (anchorPrice * l.lowerBoundAnchorRatio) / EXP_SCALE;
            uint256 maxAnswer = (anchorPrice * l.upperBoundAnchorRatio) / EXP_SCALE;
            return minAnswer <= reporterPrice && reporterPrice <= maxAnswer;
        }
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {InvalidStrategy} from "../errors/GenericErrors.sol";
import {StrategyTypes} from "./StrategyTypes.sol";

library LibStrategyConfig {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.StrategyConfig");

    error MarketNotListed();
    error OnlyReserveToken(address token);
    error OnlyStrategyOwner();
    error PositionIdDuplicates(uint256 id);
    error StrategyIsNotActive(uint256 strategyId);
    // signature
    error InvalidSignature();
    error SignatureAlreadyUsed(address user);

    struct Layout {
        /// @notice 支持的抵押品
        mapping(address => bool) isReserveToken;
        /**
         * @notice Official mapping of cTokens -> Market metadata
         * @dev Used e.g. to determine if a market is supported
         */
        mapping(address => StrategyTypes.Market) markets;
        /// @notice 所有市场的标的资产地址
        address[] allMarkets;
        address vault;
        /// @notice 用户对应的admin nonce，用于生成某个admin唯一的requestHash
        mapping(address => uint256) userNonce;
        mapping(address => mapping(bytes32 => bool)) usedSignatureHash;
        /// @notice 开仓，开仓加腿合并，平仓等请求中需要的参数
        mapping(bytes32 => StrategyTypes.StrategyRequest) userRequestStrategy;
        // @notice 提前平仓请求中需要的参数
        mapping(bytes32 => StrategyTypes.SellStrategyRequest) userSellRequest;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Reverts if the signature is used
    function _checkSignatureExists(address user, bytes memory signature) internal {
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        bytes32 userSigHash = keccak256(signature);
        if (l.usedSignatureHash[user][userSigHash]) {
            revert SignatureAlreadyUsed(user);
        }
        // // Mark the signature as used
        l.usedSignatureHash[user][userSigHash] = true;
    }

    /// @notice Reverts if the caller is not support collateral
    function _ensureSupportCollateral(address _token) internal view {
        if (!LibStrategyConfig._isReserveToken(_token)) {
            revert OnlyReserveToken(_token);
        }
    }

    /// @notice Reverts if the market is not listed
    function _ensureListed(StrategyTypes.Market storage market) internal view {
        if (!market.isListed) {
            revert MarketNotListed();
        }
    }

    /// @notice 是否为支持的抵押品
    function _isReserveToken(address token) internal view returns (bool) {
        return LibStrategyConfig.layout().isReserveToken[token];
    }

    /// @notice Reverts if the caller is not admin or strategy is not active
    function _ensureAdminAndActive(StrategyTypes.StrategyDataWithOwner memory strategy, address _admin) internal pure {
        if (_admin != strategy.owner) {
            revert OnlyStrategyOwner();
        }
        if (!strategy.isActive) {
            revert StrategyIsNotActive(strategy.strategyId);
        }
    }

    /**
     * @notice 先获取requestHash，然后更新nonce
     * @param user 用户地址
     * @return requestHash 返回requestHash
     */
    function _getRequestHashAndUpdateNonce(address user) internal returns (bytes32 requestHash) {
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        requestHash = keccak256(abi.encode(user, l.userNonce[user]));
        l.userNonce[user] += 1;
    }

    function _checkSamePosition(StrategyTypes.StrategyRequest memory strategy) internal pure {
        uint256 optionLen = strategy.option.length;
        uint256 futureLen = strategy.option.length;
        for (uint256 i = 0; i < optionLen; ) {
            for (uint256 j = i + 1; j < optionLen; ) {
                bool isSame = _checkOptionPosition(
                    strategy.option[i],
                    strategy.option[j],
                    strategy.option[i].underlying
                );
                if (!isSame) {
                    revert InvalidStrategy();
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < futureLen; ) {
            for (uint256 j = i + 1; j < futureLen; ) {
                bool isSame = _checkFuturePosition(
                    strategy.future[i],
                    strategy.future[j],
                    strategy.future[i].underlying
                );
                if (!isSame) {
                    revert InvalidStrategy();
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function _validateStrategy(
        StrategyTypes.StrategyRequest memory makerStrategy,
        StrategyTypes.StrategyRequest memory takerStrategy
    ) internal pure returns (bool) {
        uint256 makerOptionLen = makerStrategy.option.length;
        uint256 makerFutureLen = makerStrategy.future.length;
        uint256 takerOptionLen = takerStrategy.option.length;
        uint256 takerFutureLen = takerStrategy.future.length;
        uint256 makerLen = makerOptionLen + makerFutureLen;
        uint256 takerLen = takerOptionLen + takerFutureLen;
        uint256 legLimit;

        if (makerLen != takerLen || takerLen > legLimit) {
            return false;
        }
        address underlying;
        if (makerOptionLen > 0) {
            underlying = makerStrategy.option[0].underlying;
        } else {
            underlying = makerStrategy.future[0].underlying;
        }

        for (uint256 i = 0; i < makerOptionLen; ) {
            bool isSame = _checkOptionPosition(makerStrategy.option[i], takerStrategy.option[i], underlying);
            if (!isSame) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _checkFuturePosition(
        StrategyTypes.Future memory future1,
        StrategyTypes.Future memory future2,
        address underlying
    ) internal pure returns (bool) {
        if (future1.underlying != underlying) {
            return false;
        }
        if (future2.underlying != underlying) {
            return false;
        }
        bytes32 future1Hash = keccak256(
            abi.encode(future1.entryPrice, future1.expiryTime, future1.size, future1.isLong)
        );
        bytes32 future2Hash = keccak256(
            abi.encode(future2.entryPrice, future2.expiryTime, future2.size, future2.isLong)
        );
        if (future1Hash == future2Hash) {
            return false;
        }
        if (future1.isLong == !future2.isLong) {
            return false;
        }
        // TODO 验证每条腿开仓的时间是不是我们限定的时间点
        return true;
    }

    function _checkOptionPosition(
        StrategyTypes.Option memory option1,
        StrategyTypes.Option memory option2,
        address underlying
    ) internal pure returns (bool) {
        if (option1.underlying != underlying) {
            return false;
        }
        if (option2.underlying != underlying) {
            return false;
        }
        bytes32 option1Hash = keccak256(
            abi.encode(option1.strikePrice, option1.premium, option1.size, option1.expiryTime)
        );
        bytes32 option2Hash = keccak256(
            abi.encode(option2.strikePrice, option2.premium, option2.size, option2.expiryTime)
        );
        if (option1Hash == option2Hash) {
            return false;
        }
        if (option1.optionType == StrategyTypes.OptionType.LONG_CALL) {
            if (option2.optionType != StrategyTypes.OptionType.SHORT_CALL) {
                return false;
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.SHORT_CALL) {
            if (option2.optionType != StrategyTypes.OptionType.LONG_CALL) {
                return false;
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.LONG_PUT) {
            if (option2.optionType != StrategyTypes.OptionType.SHORT_PUT) {
                return false;
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.SHORT_PUT) {
            if (option2.optionType != StrategyTypes.OptionType.LONG_PUT) {
                return false;
            }
        }
        // TODO 验证每条腿开仓的时间是不是我们限定的时间点
        return true;
    }

    /// @notice 此函数用于检查腿 ID 数组中是否存在重复的腿 ID，如果有重复，将触发错误。
    function _checkPositionIdDuplicates(uint256[] memory ids) internal pure {
        uint256 idsLen = ids.length;
        for (uint256 i; i < idsLen; ) {
            for (uint256 j = i + 1; j < idsLen; ) {
                if (ids[i] == ids[j]) {
                    revert PositionIdDuplicates(ids[i]);
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice 设置开仓时的userRequst 参数
    function _updateUserRequestStrategy(bytes32 requestId, StrategyTypes.StrategyRequest memory _strategy) internal {
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        l.userRequestStrategy[requestId].timestamp = _strategy.timestamp;
        l.userRequestStrategy[requestId].mergeId = _strategy.mergeId;
        // 抵押品
        uint256 collateralLen = _strategy.collaterals.length;
        for (uint256 i; i < collateralLen; ) {
            StrategyTypes.CollateralInfo memory collateral_ = _strategy.collaterals[i];
            l.userRequestStrategy[requestId].collaterals.push(collateral_);
            unchecked {
                ++i;
            }
        }

        uint256 optionLen = _strategy.option.length;
        for (uint256 i; i < optionLen; ) {
            StrategyTypes.Option memory option_ = _strategy.option[i];
            l.userRequestStrategy[requestId].option.push(option_);

            unchecked {
                ++i;
            }
        }

        uint256 futureLen = _strategy.future.length;
        for (uint256 i; i < futureLen; ) {
            StrategyTypes.Future memory future_ = _strategy.future[i];
            l.userRequestStrategy[requestId].future.push(future_);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice 设置开仓时的userRequst 参数
    function _updateUserSellRequestStrategy(
        bytes32 requestId,
        StrategyTypes.SellStrategyRequest memory _strategy
    ) internal {
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        l.userSellRequest[requestId].strategyId = _strategy.strategyId;
        l.userSellRequest[requestId].price = _strategy.price;
        l.userSellRequest[requestId].receiver = _strategy.receiver;
        l.userSellRequest[requestId].admin = _strategy.admin;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "./StrategyTypes.sol";
import {LibStrategyConfig} from "./LibStrategyConfig.sol";

library LibStrategyOpen {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.StrategyOpen");

    error InvalidCollateral();
    error CollateralDuplicates(address token);

    struct Layout {
        /// @notice 支持的抵押品
        mapping(address => bool) isReserveToken;
        /**
         * @notice Official mapping of cTokens -> Market metadata
         * @dev Used e.g. to determine if a market is supported
         */
        mapping(address => StrategyTypes.Market) markets;
        /// @notice 所有市场的标的资产地址
        address[] allMarkets;
        /// @notice 减少保证金请求中需要的参数
        mapping(bytes32 => StrategyTypes.DecreaseStrategyCollateralRequest) userDSCRequest;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice 此函数用于检查抵押品数组中是否存在重复的抵押品，如果有重复，将触发错误。
    function _checkCollateralDuplicates(StrategyTypes.CollateralInfo[] memory collaterals) internal view {
        uint256 collateralsLen = collaterals.length;
        for (uint256 i; i < collateralsLen; ) {
            // 验证抵押品数量是否大于0，验证抵押品token是否支持
            LibStrategyConfig._ensureSupportCollateral(collaterals[i].collateralToken);
            if (collaterals[i].collateralAmount == 0) {
                revert InvalidCollateral();
            }
            for (uint256 j = i + 1; j < collateralsLen; ) {
                if (collaterals[i].collateralToken == collaterals[j].collateralToken) {
                    revert CollateralDuplicates(collaterals[i].collateralToken);
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice 将内存抵押品数据push到storage中
     * @param collateralsStorage 存储中空的抵押品数组
     * @param collateralsMemory 内存中有数据的抵押品数组
     */
    function _collateralsMemoryToStorage(
        StrategyTypes.CollateralInfo[] storage collateralsStorage,
        StrategyTypes.CollateralInfo[] memory collateralsMemory
    ) internal {
        uint256 collLen = collateralsMemory.length;
        for (uint256 i; i < collLen; ) {
            StrategyTypes.CollateralInfo memory collInfo = collateralsMemory[i];
            collateralsStorage.push(collInfo);
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {InvalidAddress} from "../errors/GenericErrors.sol";
import {FixedPoint96, FullMath, TickMath, IUniswapV3Pool} from "../libraries/UniswapLib.sol";

library LibTWAPOracle {
    /// @dev Describe how to interpret the fixedPrice in the TokenConfig.
    enum PriceSource {
        FIXED_ETH, /// implies the fixedPrice is a constant multiple of the ETH price (which varies)
        FIXED_USD /// implies the fixedPrice is a constant multiple of the USD price (which is 1)
    }

    /// @dev Describe how the USD price should be determined for an asset.
    ///  There should be 1 TokenTWAPConfig object for each supported asset, passed in the constructor.
    struct TokenTWAPConfig {
        // The address of the underlying market token.
        address underlying;
        // Where price is coming from.  Refer to README for more information
        PriceSource priceSource;
        // The number of smallest units of measurement in a single whole unit.
        uint256 baseDecimals;
        // The number of smallest units of measurement in a single whole unit.
        uint256 quoteDecimals;
        // The address of the pool being used as the anchor for this market.
        address uniswapMarket;
        // True if the pair on Uniswap is defined as ETH / X
        bool isUniswapReversed;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.TWAPOracle");

    /// @notice The number of wei in 1 ETH
    uint256 public constant ETH_BASE_UNIT = 1e18;

    /// @notice A common scaling factor to maintain precision
    uint256 public constant EXP_SCALE = 1e18;

    error TWAPOracle__AlreadyInitialized();
    error TWAPOracle__TickNotInRange();
    error TWAPOracle__TimeWeightedAverageTickExceedsLimit();

    struct Layout {
        address wrappedNative;
        /// @notice The time interval to search for TWAPs when calling the Uniswap V3 observe function
        uint32 anchorPeriod;
        /// @notice Token config by assets
        mapping(address => TokenTWAPConfig) tokenTWAPConfigs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function initialize(uint32 _anchorPeriod, address _wrappedNative) internal {
        LibTWAPOracle.Layout storage l = LibTWAPOracle.layout();
        if (l.wrappedNative != address(0) && l.anchorPeriod != 0) {
            revert TWAPOracle__AlreadyInitialized();
        }
        l.anchorPeriod = _anchorPeriod;
        l.wrappedNative = _wrappedNative;
    }

    function _getTWAPPrice(address asset) internal view returns (uint256) {
        LibTWAPOracle.Layout storage l = LibTWAPOracle.layout();
        TokenTWAPConfig memory config = l.tokenTWAPConfigs[asset];
        uint256 anchorPrice = _calculateAnchorPriceFromEthPrice(config);
        return anchorPrice;
    }

    /**
     * @notice Calculate the anchor price by fetching price data from the TWAP
     * @param config TokenTWAPConfig
     * @return anchorPrice uint
     */
    function _calculateAnchorPriceFromEthPrice(
        TokenTWAPConfig memory config
    ) internal view returns (uint256 anchorPrice) {
        if (config.priceSource == PriceSource.FIXED_ETH) {
            // btc-eth eth-usdc -> btc-usdc
            uint256 ethPrice = _fetchEthPrice();
            anchorPrice = _fetchAnchorPrice(config, ethPrice);
        } else {
            // eth-usdc
            anchorPrice = _fetchAnchorPrice(config, ETH_BASE_UNIT);
        }
    }

    /**
     * @dev Fetches the current eth/usd price from Uniswap, with 18 decimals of precision.
     *  Conversion factor is 1e18 for eth/usdc market, since we decode Uniswap price statically with 18 decimals.
     */
    function _fetchEthPrice() internal view returns (uint256) {
        LibTWAPOracle.Layout storage l = LibTWAPOracle.layout();
        return _fetchAnchorPrice(l.tokenTWAPConfigs[l.wrappedNative], ETH_BASE_UNIT);
    }

    /**
     * @dev Fetches the current token/usd price from Uniswap, with 18 decimals of precision.
     * @param conversionFactor 1e18 if seeking the ETH price, and a 18 decimal ETH-USDC price in the case of other assets
     */

    function _fetchAnchorPrice(
        TokenTWAPConfig memory config,
        uint256 conversionFactor
    ) internal view returns (uint256) {
        if (config.underlying == address(0) || config.uniswapMarket == address(0)) {
            revert InvalidAddress(address(this), address(0));
        }
        // `getUniswapTwap(config)`
        //      -> TWAP between the baseUnits of Uniswap pair (scaled to 1e18)
        uint256 twap = _getUniswapTwap(config);

        // `unscaledPriceMantissa * 10^config.baseDecimals / 10^config.quoteDecimals / EXP_SCALE`
        //      -> price of 1 token relative to baseUnit of the other token (scaled to 1)
        uint256 unscaledPriceMantissa = twap * conversionFactor;

        // Adjust twap price decimals
        uint256 anchorPrice = (unscaledPriceMantissa * (10 ** config.baseDecimals)) /
            (10 ** config.quoteDecimals) /
            EXP_SCALE;

        return anchorPrice;
    }

    /**
     * @dev Fetches the latest TWATP from the UniV3 pool oracle, over the last anchor period.
     *      Note that the TWATP (time-weighted average tick-price) is not equivalent to the TWAP,
     *      as ticks are logarithmic. The TWATP returned by this function will usually
     *      be lower than the TWAP.
     */
    function _getUniswapTwap(TokenTWAPConfig memory config) internal view returns (uint256) {
        LibTWAPOracle.Layout storage l = LibTWAPOracle.layout();
        uint32 anchorPeriod_ = l.anchorPeriod;
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = anchorPeriod_;
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(config.uniswapMarket).observe(secondsAgos);

        int56 anchorPeriod__ = int56(uint56(anchorPeriod_));
        int56 timeWeightedAverageTickS56 = (tickCumulatives[1] - tickCumulatives[0]) / anchorPeriod__;
        //        require(
        //            timeWeightedAverageTickS56 >= TickMath.MIN_TICK && timeWeightedAverageTickS56 <= TickMath.MAX_TICK,
        //            "TWAP not in range"
        //        );
        if (timeWeightedAverageTickS56 < TickMath.MIN_TICK || timeWeightedAverageTickS56 > TickMath.MAX_TICK) {
            revert TWAPOracle__TickNotInRange();
        }
        // require(timeWeightedAverageTickS56 < type(int24).max, "timeWeightedAverageTick > max");
        if (timeWeightedAverageTickS56 >= type(int24).max) {
            revert TWAPOracle__TimeWeightedAverageTickExceedsLimit();
        }
        int24 timeWeightedAverageTick = int24(timeWeightedAverageTickS56);
        if (config.isUniswapReversed) {
            // If the reverse price is desired, inverse the tick
            // price = 1.0001^{tick}
            // (price)^{-1} = (1.0001^{tick})^{-1}
            // \frac{1}{price} = 1.0001^{-tick}
            timeWeightedAverageTick = -timeWeightedAverageTick;
        }
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(timeWeightedAverageTick);
        // Squaring the result also squares the Q96 scalar (2**96),
        // so after this mulDiv, the resulting TWAP is still in Q96 fixed precision.
        uint256 twapX96 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);

        // Scale up to a common precision (EXP_SCALE), then down-scale from Q96.
        return FullMath.mulDiv(EXP_SCALE, twapX96, FixedPoint96.Q96);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {ISwapRouter} from "../interfaces/external/ISwapRouter.sol";
import {StrategyTypes} from "./StrategyTypes.sol";

library LibVault {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.Vault");

    struct UserBalance {
        /// @notice dederi 总账户余额
        uint256 balance;
        /// @notice 需要链下调用更改 positiveUnSettledBalance，若为 0 则没有锁住的资产，提现时加判断，需要通过 pnl 来获取这个值
        uint256 positiveUnSettledBalance;
    }

    uint256 public constant timeTemplate = 1698134400;

    struct Layout {
        mapping(bytes32 => UserBalance) userBalance;
        address weth;
        address usdcToken;
        ISwapRouter swapRouter;
    }

    error Vault__AlreadyInitialized();
    error BalanceNotEnough();

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function initialize(address weth, address usdcToken) internal {
        LibVault.Layout storage l = LibVault.layout();
        if (l.weth != address(0) && l.usdcToken != address(0)) {
            revert Vault__AlreadyInitialized();
        }
        l.weth = weth;
        l.usdcToken = usdcToken;
    }

    /// @notice 将可用余额划转到策略账户中
    function _marginDecrease(address user, StrategyTypes.CollateralInfo[] memory collateral) internal {
        LibVault.Layout storage l = LibVault.layout();
        uint256 tokenLen = collateral.length;
        for (uint256 i; i < tokenLen; ) {
            bytes32 id = keccak256(abi.encodePacked(user, collateral[i].collateralToken));
            l.userBalance[id].balance -= collateral[i].collateralAmount;

            unchecked {
                ++i;
            }
        }
    }

    /// @notice 将抵押品划转到账户可用余额中
    function _marginIncrease(address user, StrategyTypes.CollateralInfo[] memory collateral) internal {
        LibVault.Layout storage l = LibVault.layout();
        uint256 tokenLen = collateral.length;
        for (uint256 i = 0; i < tokenLen; ) {
            bytes32 id = keccak256(abi.encodePacked(user, collateral[i].collateralToken));
            l.userBalance[id].balance += collateral[i].collateralAmount;

            unchecked {
                ++i;
            }
        }
    }

    function _balanceUpdate(address taker, address maker, address token, int256 amount) internal {
        LibVault.Layout storage l = LibVault.layout();
        bytes32 takerId = keccak256(abi.encodePacked(taker, token));
        bytes32 makerId = keccak256(abi.encodePacked(maker, token));
        int256 takerBalance = int256(l.userBalance[takerId].balance);
        int256 makerBalance = int256(l.userBalance[makerId].balance);
        if (amount > 0) {
            takerBalance += amount;
            makerBalance -= amount;
        } else {
            makerBalance += amount;
            takerBalance -= amount;
        }
        if (makerBalance > 0 && takerBalance > 0) {
            l.userBalance[takerId].balance = uint256(takerBalance);
            l.userBalance[makerId].balance = uint256(makerBalance);
        } else {
            revert BalanceNotEnough();
        }
    }

    // function _balanceDecrease(address receiver, address token, int256 amount) internal {
    //     LibVault.Layout storage l = LibVault.layout();
    //     bytes32 id = keccak256(abi.encodePacked(receiver, token));
    //     l.userBalance[id].balance -= amount;
    // }

    function _lockBalanceUpdate(address receiver, address token, uint256 amount) internal {
        LibVault.Layout storage l = LibVault.layout();
        bytes32 id = keccak256(abi.encodePacked(receiver, token));
        l.userBalance[id].positiveUnSettledBalance += amount;
    }

    /// TODO longAmount shortAmount ，user，receipt 命名更改
    function _transferPremium(StrategyTypes.StrategyRequest memory strategy, address taker, address maker) internal {
        LibVault.Layout storage l = LibVault.layout();
        int256 amount;
        uint256 optionLen = strategy.option.length;
        for (uint256 i; i < optionLen; ) {
            // if (
            //     strategy.option[i].optionType == StrategyTypes.OptionType.SHORT_CALL ||
            //     strategy.option[i].optionType == StrategyTypes.OptionType.SHORT_PUT
            // ) {
            //     longAmount += strategy.option[i].premium;
            // } else {
            //     shortAmount += strategy.option[i].premium;
            // }
            //收到权利金为正，支付权利金为负
            amount += strategy.option[i].premium;
            unchecked {
                ++i;
            }
        }
        _balanceUpdate(taker, maker, l.usdcToken, amount);

        // TODO 将权利金转移到策略账户
        // 权利金支付部分直接减少可用余额，不改变已使用余额
        // if (longAmount > shortAmount) {
        //     int256 amount = longAmount - shortAmount;
        //     _balanceUpdate(user, l.usdcToken, amount);
        //     _balanceIncrease(receipt, l.usdcToken, amount);
        // }
        // if (shortAmount > longAmount) {
        //     int256 amount = shortAmount - longAmount;
        //     _balanceDecrease(receipt, l.usdcToken, amount);
        //     _balanceIncrease(user, l.usdcToken, amount);
        // }
    }

    // 1、临界值问题
    // 2、timeIndex 是都需要+ 1
    function getTime() internal view returns (uint256) {
        uint256 timeIndex = (block.timestamp - timeTemplate) / 86400 + 1;
        uint256 nextExpireTime = timeIndex * 86400 + timeTemplate;
        return nextExpireTime;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

library StrategyTypes {
    enum AssetType {
        OPTION,
        FUTURE
    }

    enum OptionType {
        LONG_CALL,
        LONG_PUT,
        SHORT_CALL,
        SHORT_PUT
    }

    ///////////////////
    // Internal Data //
    ///////////////////

    struct Option {
        uint256 positionId;
        // underlying asset address
        address underlying;
        // option strike price (with 18 decimals)
        uint256 strikePrice;
        int256 premium;
        // option expiry timestamp
        uint256 expiryTime;
        // order size
        uint256 size;
        // option type
        OptionType optionType;
        bool isActive;
    }

    struct Future {
        uint256 positionId;
        // underlying asset address
        address underlying;
        // (with 18 decimals)
        uint256 entryPrice;
        // future expiry timestamp
        uint256 expiryTime;
        // order size
        uint256 size;
        bool isLong;
        bool isActive;
    }

    struct CollateralInfo {
        address collateralToken;
        uint256 collateralAmount;
    }

    struct PositionData {
        uint256 positionId;
        AssetType assetType;
        bool isActive;
    }

    struct StrategyData {
        uint256 strategyId;
        uint256 timestamp;
        uint256[] positionIds;
        CollateralInfo[] collaterals;
        int256 realisedPnl;
        bool isActive;
    }

    struct StrategyDataWithOwner {
        uint256 strategyId;
        uint256[] positionIds;
        CollateralInfo[] collaterals;
        int256 realisedPnl;
        bool isActive;
        address owner;
    }

    struct Strategy {
        address admin;
        uint256 timestamp;
        int256 realizedPnl;
        // 合并的id：如果为0，表示不合并；有值进行验证并合并
        uint256 mergeId;
        bool isActive;
        CollateralInfo[] collaterals;
        Option[] option;
        Future[] future;
    }

    struct CreateAndMergeStrategyRequest {
        uint256 strategyId;
    }

    struct DecreaseStrategyCollateralRequest {
        address admin;
        uint256 strategyId;
        CollateralInfo[] collaterals;
    }

    struct MergeStrategyRequest {
        address admin;
        uint256 firstStrategyId;
        uint256 secondStrategyId;
        CollateralInfo[] newCollaterals;
    }

    struct SpiltStrategyRequest {
        address admin;
        uint256 strategyId;
        uint256[] positionIds;
        CollateralInfo[] originalCollateralsToTopUp;
        CollateralInfo[] newlySplitCollaterals;
    }

    struct LiquidateStrategyRequest {
        uint256 strategyId;
        address admin;
    }

    struct StrategyRequest {
        address admin;
        uint256 timestamp;
        uint256 mergeId;
        CollateralInfo[] collaterals;
        Option[] option;
        Future[] future;
    }

    struct SellStrategyRequest {
        uint256 strategyId;
        uint256[] positionIds;
        int256 price;
        address receiver;
        address admin;
    }

    struct Market {
        // Whether or not this market is listed
        bool isListed;
        // 保证金缩水率
        uint256 marginScale;
        // 合约乘数
        // 上限
        // 下限
    }

    ///////////////////
    // Margin Oracle //
    ///////////////////

    struct MarginItemWithId {
        uint256 strategyId;
        uint256 im;
        uint256 mm;
        uint256 updateAt;
    }

    struct MarginItemWithHash {
        bytes32 requestHash;
        uint256 im;
        uint256 mm;
        uint256 updateAt;
    }

    ///////////////////
    //   Mark Price  //
    ///////////////////

    struct MarkPriceItemWithId {
        uint256 positionId;
        uint256 price;
        uint256 updateAt;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

// From: https://github.com/Uniswap/uniswap-v3-core

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }
}

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(uint24(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }
}

interface IUniswapV3Pool {
    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(
        uint32[] calldata secondsAgos
    ) external view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    modifier nonReentrant() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.status != _ENTERED, "ReentrancyGuard: reentrant call");
        ds.status = _ENTERED;
        _;
        ds.status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.19;

import "../diamond/libraries/StrategyTypes.sol";

interface IInStrategyNFT {
    /**
     * @notice Mint nft to recipient.
     * @param to The recipient address.
     */
    function mint(address to) external returns (uint256);

    function mintWithId(address to, uint256 tokenId) external returns (uint256);

    function burn(uint256 tokenId) external;

    function currentTokenId() external returns (uint256);
}

interface IStrategyNFT is IInStrategyNFT {
    //////////
    // View //
    //////////

    function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

type Price8 is uint64;
type Qty10 is uint80;
type Usd18 is uint96;

library Constants {
    /*-------------------------------- Role --------------------------------*/
    // 0x0000000000000000000000000000000000000000000000000000000000000000
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    // 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // 0xfc425f2263d0df187444b70e47283d622c70181c5baebb1306a01edba1ce184c
    bytes32 internal constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    // 0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab
    bytes32 internal constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    // 0xa47af3fd2c1c79eb1dca3988e5817b1cc324b3345b8992b0bc7c0ff492863c88
    // bytes32 internal constant MARK_SIGNER_ROLE = keccak256("MARK_SIGNER_ROLE");
    // 0xb5f6c0f8c55ae10f5b95eff27f33679ba36b6c38c8459d642ed21a2d895bda6f
    bytes32 internal constant MARGIN_SIGNER_ROLE = keccak256("MARGIN_SIGNER_ROLE");
    // 0x8227712ef8ad39d0f26f06731ef0df8665eb7ada7f41b1ee089adf3c238862a2
    bytes32 internal constant MONITOR_ROLE = keccak256("MONITOR_ROLE");

    bytes32 internal constant STRATEGY_REQUEST_TYPE_HASH =
        keccak256(
            "Strategy("
            "address admin,"
            "uint256 timestamp,"
            "uint256[] mergeId,"
            "CollateralInfo[] collaterals,"
            "Option[] option,"
            "Future[] future"
            ")"
        );

    /*-------------------------------- Decimals --------------------------------*/
    uint8 public constant PRICE_DECIMALS = 8;
    uint8 public constant QTY_DECIMALS = 10;
    uint8 public constant USD_DECIMALS = 18;

    uint16 public constant BASIS_POINTS_DIVISOR = 1e4;
    uint16 public constant MAX_LEVERAGE = 1e3;
    int256 public constant FUNDING_FEE_RATE_DIVISOR = 1e18;
    uint16 public constant MAX_DAO_SHARE_P = 2000;
    uint16 public constant MAX_COMMISSION_P = 8000;
    uint8 public constant FEED_DELAY_BLOCK = 100;
    uint8 public constant MAX_REQUESTS_PER_PAIR_IN_BLOCK = 100;
    uint256 public constant TIME_LOCK_DELAY = 2 hours;
    uint256 public constant TIME_LOCK_GRACE_PERIOD = 12 hours;
}