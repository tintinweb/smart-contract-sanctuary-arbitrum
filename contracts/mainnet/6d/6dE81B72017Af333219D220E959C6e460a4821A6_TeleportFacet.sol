// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import {ITeleport} from "../interfaces/ITeleport.sol";
import {IProvider} from "../interfaces/IProvider.sol";
import {IProviderSelector} from "../interfaces/IProviderSelector.sol";
import {ITeleportDApp} from "../interfaces/ITeleportDApp.sol";
import {LibTeleport} from "../libraries/LibTeleport.sol";
import {LibGovernance, ECDSA, Counters} from "../libraries/LibGovernance.sol";
import {LibFeeCalculator} from "../libraries/LibFeeCalculator.sol";
import {Governable} from "../Governable.sol";
import {ICommonErrors, ITeleportFacetErrors} from "../interfaces/IDiamondErrors.sol";

contract TeleportFacet is ITeleport, Governable, ITeleportFacetErrors {
    using Counters for Counters.Counter;
    address private immutable _SELF = address(this);

    // Modifier to restrict access to functions only to valid providers
    modifier onlyValidProvider() {
        if (!IProviderSelector(LibTeleport.teleportStorage().providerSelector).isValidProvider(msg.sender))
            revert OnlyValidProviderCalls();
        _;
    }

    /**
     * @notice sets the state for the TeleportFacet
     * @dev This method is never attached on the diamond
     */
    function state(bytes memory data_) external {
        if (address(this) == _SELF) {
            revert ICommonErrors.NoDirectCall();
        }

        LibTeleport.Storage storage ts = LibTeleport.teleportStorage();
        (ts.chainId, ts.providerSelector) = abi.decode(data_, (uint8, address));
    }

    /*********************************** PUBLIC INTERFACE *********************************/

    /**
     * @notice Selects a provider to bridge the message to the target chain
     * @param targetChainId_ The chainID where the message should be delivered to
     * @param transmissionReceiver_ The address of the contract in the target chain to receive the transmission
     * @param dAppId_ ID for the dApp that the message belongs to
     * @param payload_ The dApp-specific message data
     */
    function transmit(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_
    ) external payable override {
        _transmitWithArgs(targetChainId_, transmissionReceiver_, dAppId_, payload_, bytes(""));
    }

    /**
     * @notice Selects a provider to bridge the message to the target chain
     * @param targetChainId_ The chainID where the message should be delivered to
     * @param transmissionReceiver_ The address of the contract in the target chain to receive the transmission
     * @param dAppId_ ID for the dApp that the message belongs to
     * @param payload_ The dApp-specific message data
     * @param extraOptionalArgs_ Extra optional arguments to be passed to the provider. This allow for specific provider configurations. Send bytes('') if not needed
     */
    function transmitWithArgs(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external payable override {
        _transmitWithArgs(targetChainId_, transmissionReceiver_, dAppId_, payload_, extraOptionalArgs_);
    }

    /**
     * @notice Selects a provider to bridge the message to the target chain
     * @param targetChainId_ The chainID where the message should be delivered to
     * @param transmissionReceiver_ The address of the contract in the target chain to receive the transmission
     * @param dAppId_ ID for the dApp that the message belongs to
     * @param payload_ The dApp-specific message data
     * @param providerAddress_ The provider to be used for the transmission
     * @param extraOptionalArgs_ Extra arguments to be passed to the provider. This allow for specific provider configurations
     * */
    function transmitWithProvider(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        address providerAddress_,
        bytes calldata extraOptionalArgs_
    ) external payable {
        // Check if the provider exists
        if (providerAddress_ == address(0)) revert ProviderCannotBeZeroAddress();

        // Validate that the given provider is a valid one according to the provider selector
        if (!IProviderSelector(LibTeleport.teleportStorage().providerSelector).isValidProvider(providerAddress_))
            revert InvalidProvider();

        _transmitWithProvider(
            targetChainId_,
            transmissionReceiver_,
            dAppId_,
            payload_,
            providerAddress_,
            extraOptionalArgs_
        );
    }

    /**
     * @dev Returns the teleport fee charged by the teleport contract.
     * @return The teleport fee amount in wei.
     */
    function teleportFee() external view override returns (uint256) {
        return LibFeeCalculator.feeCalculatorStorage().serviceFee;
    }

    /**
     * @dev Returns the provider fee charged by the provider contract.
     * @param targetChainId_ The chainID where the message should be delivered to
     * @param transmissionReceiver_ The address of the contract in the target chain to receive the transmission
     * @param dAppId_ ID for the dApp that the message belongs to
     * @param payload_ The dApp-specific message data
     * @param extraOptionalArgs_ Extra optional arguments to be passed to the provider. This allow for specific provider configurations. Send bytes('') if not needed
     * @return The provider fee amount in wei.
     */
    function providerFee(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view override returns (uint256) {
        // Get the correct provider from provider selector
        address providerAddress_ = IProviderSelector(LibTeleport.teleportStorage().providerSelector).getProvider(
            targetChainId_,
            transmissionReceiver_,
            dAppId_,
            payload_
        );

        if (providerAddress_ == address(0)) revert TransmissionNotSupportedByAnyProvider();

        return
            _providerFee(
                providerAddress_,
                targetChainId_,
                transmissionReceiver_,
                dAppId_,
                payload_,
                extraOptionalArgs_
            );
    }

    /**
     * @dev Returns the provider fee charged by the provider contract.
     * @param providerAddress_ The provider to be used for the transmission
     * @param targetChainId_ The chainID where the message should be delivered to
     * @param transmissionReceiver_ The address of the contract in the target chain to receive the transmission
     * @param dAppId_ ID for the dApp that the message belongs to
     * @param payload_ The dApp-specific message data
     * @param extraOptionalArgs_ Extra optional arguments to be passed to the provider. This allow for specific provider configurations. Send bytes('') if not needed
     * @return The provider fee amount in wei.
     */
    function providerFee(
        address providerAddress_,
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view override returns (uint256) {
        if (providerAddress_ == address(0)) revert ProviderCannotBeZeroAddress();

        return
            _providerFee(
                providerAddress_,
                targetChainId_,
                transmissionReceiver_,
                dAppId_,
                payload_,
                extraOptionalArgs_
            );
    }

    /**
     * @dev Returns the service fee charged by the teleport and the provider contracts.
     * @param targetChainId_ The chainID where the message should be delivered to
     * @param transmissionReceiver_ The address of the contract in the target chain to receive the transmission
     * @param dAppId_ ID for the dApp that the message belongs to
     * @param payload_ The dApp-specific message data
     * @param extraOptionalArgs_ Extra optional arguments to be passed to the provider. This allow for specific provider configurations. Send bytes('') if not needed
     * @return The service fee amount in wei.
     */
    function serviceFee(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view override returns (uint256) {
        // Get the correct provider from provider selector
        address providerAddress_ = IProviderSelector(LibTeleport.teleportStorage().providerSelector).getProvider(
            targetChainId_,
            transmissionReceiver_,
            dAppId_,
            payload_
        );

        if (providerAddress_ == address(0)) revert TransmissionNotSupportedByAnyProvider();

        return
            LibFeeCalculator.feeCalculatorStorage().serviceFee +
            _providerFee(
                providerAddress_,
                targetChainId_,
                transmissionReceiver_,
                dAppId_,
                payload_,
                extraOptionalArgs_
            );
    }

    /**
     * @dev Returns the service fee charged by the teleport and the provider contracts.
     * @param providerAddress_ The provider to be used for the transmission
     * @param targetChainId_ The chainID where the message should be delivered to
     * @param transmissionReceiver_ The address of the contract in the target chain to receive the transmission
     * @param dAppId_ ID for the dApp that the message belongs to
     * @param payload_ The dApp-specific message data
     * @param extraOptionalArgs_ Extra optional arguments to be passed to the provider. This allow for specific provider configurations. Send bytes('') if not needed
     * @return The service fee amount in wei.
     */
    function serviceFee(
        address providerAddress_,
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view override returns (uint256) {
        // Get the correct provider from provider selector
        if (providerAddress_ == address(0)) revert ProviderCannotBeZeroAddress();

        return
            LibFeeCalculator.feeCalculatorStorage().serviceFee +
            _providerFee(
                providerAddress_,
                targetChainId_,
                transmissionReceiver_,
                dAppId_,
                payload_,
                extraOptionalArgs_
            );
    }

    /**
     * @dev Delivers a message using the provided provider. This might not be supported by all providers.
     * @param providerAddress The address of the provider contract.
     * @param args The arguments to be passed to the provider contract.
     */
    function deliver(address providerAddress, bytes calldata args) external override {
        // Check if the provider exists
        if (providerAddress == address(0)) revert ProviderCannotBeZeroAddress();

        // Validate that the given provider is a valid one according to the provider selector
        if (!IProviderSelector(LibTeleport.teleportStorage().providerSelector).isValidProvider(providerAddress))
            revert InvalidProvider();

        // Call deliver method on provider
        IProvider(providerAddress).manualClaim(args);
    }

    /**
     * @dev Function called when a provider receives a transmission from another chain's teleport.
     * @param args The DappTransmissionReceive struct containing the transmission data.
     */
    function onProviderReceive(DappTransmissionReceive calldata args) external override onlyValidProvider {
        bytes memory sourceChainTeleportSender = LibTeleport.teleportStorage().teleportAddressByChainId[
            args.sourceChainId
        ];

        if (sourceChainTeleportSender.length == 0) revert SourceChainNotSupported();

        // check the sender is the teleport contract of the source chain
        if (keccak256(sourceChainTeleportSender) != keccak256(args.teleportSender)) revert InvalidTeleportSender();

        ITeleportDApp(args.dappTransmissionReceiver).onTeleportMessage(
            args.sourceChainId,
            args.dappTransmissionSender,
            args.dAppId,
            args.payload
        );
    }

    /*********************************** GOVERNANCE SECTION *********************************/

    function configProviderSelector(
        bytes calldata configData,
        bytes[] calldata signatures_
    ) external override onlyConsensusNonce(computeConfigProviderSelector(configData), signatures_) {
        IProviderSelector(LibTeleport.teleportStorage().providerSelector).config(configData);
    }

    /// @notice Computes the bytes32 ethereum signed message hash of the call to config the provider selector message
    function computeConfigProviderSelector(bytes calldata configData) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encode(
                        LibTeleport.teleportStorage().chainId,
                        "computeConfigProviderSelector",
                        configData,
                        LibGovernance.governanceStorage().administrativeNonce.current()
                    )
                )
            );
    }

    function configProvider(
        bytes calldata configData,
        address providerAddress,
        bytes[] calldata signatures_
    ) external override onlyConsensusNonce(computeConfigProvider(configData, providerAddress), signatures_) {
        // Check if the provider exists
        if (providerAddress == address(0)) revert ProviderCannotBeZeroAddress();

        // Validate that the given provider is a valid one according to the provider selector
        if (!IProviderSelector(LibTeleport.teleportStorage().providerSelector).isValidProvider(providerAddress))
            revert InvalidProvider();

        IProvider(providerAddress).config(configData);
    }

    /// @notice Computes the bytes32 ethereum signed message hash of the call to the config a provider message
    function computeConfigProvider(bytes calldata configData, address providerAddress) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encode(
                        LibTeleport.teleportStorage().chainId,
                        "computeConfigProvider",
                        configData,
                        providerAddress,
                        LibGovernance.governanceStorage().administrativeNonce.current()
                    )
                )
            );
    }

    /*********************************** PRIVATE SECTION *********************************/

    /**
     * @notice internal function to transmit the message to the target chain using the given provider
     * @param targetChainId_ The chainID where the message should be delivered to
     * @param dappTransmissionReceiver_ The address of the contract in the target chain to receive the transmission
     * @param dAppId_ ID for the dApp that the message belongs to
     * @param payload_ The dApp-specific message data
     * @param providerAddress_ The provider to be used for the transmission
     * @param extraOptionalArgs_ Extra arguments to be passed to the provider. This allow for specific provider configurations
     * */
    function _transmitWithProvider(
        uint8 targetChainId_,
        bytes calldata dappTransmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        address providerAddress_,
        bytes memory extraOptionalArgs_
    ) private {
        uint256 remainingValue = LibFeeCalculator.accrueReward(msg.value);

        emit TransmissionFees(msg.value - remainingValue);

        bytes memory targetChainTeleportReceiver = LibTeleport.teleportStorage().teleportAddressByChainId[
            targetChainId_
        ];

        if (targetChainTeleportReceiver.length == 0) revert TargetChainNotSupported();

        // Call the provider to transmit the message
        IProvider(providerAddress_).sendMsg{value: remainingValue}(
            targetChainId_,
            targetChainTeleportReceiver,
            IProvider.DappTransmissionInfo(_addressToBytes(msg.sender), dappTransmissionReceiver_, dAppId_, payload_),
            extraOptionalArgs_
        );
    }

    /**
     * @param targetChainId_ The chainID where the message should be delivered to
     * @param transmissionReceiver_ The address of the contract in the target chain to receive the transmission
     * @param dAppId_ ID for the dApp that the message belongs to
     * @param payload_ The dApp-specific message data
     * @param extraOptionalArgs_ Extra optional arguments to be passed to the provider. This allow for specific provider configurations. Send bytes('') if not needed
     */
    function _transmitWithArgs(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes memory extraOptionalArgs_
    ) private {
        // Get the correct provider from provider selector
        address provider = IProviderSelector(LibTeleport.teleportStorage().providerSelector).getProvider(
            targetChainId_,
            transmissionReceiver_,
            dAppId_,
            payload_
        );

        if (provider == address(0)) revert TransmissionNotSupportedByAnyProvider();

        //Call the transmitWithProvider with the gotten providerId to transmit the message
        _transmitWithProvider(targetChainId_, transmissionReceiver_, dAppId_, payload_, provider, extraOptionalArgs_);
    }

    /**
     * @dev Returns the provider fee charged by the provider contract.
     * @param providerAddress_ The provider to be used for the transmission
     * @param targetChainId_ The chainID where the message should be delivered to
     * @param transmissionReceiver_ The address of the contract in the target chain to receive the transmission
     * @param dAppId_ ID for the dApp that the message belongs to
     * @param payload_ The dApp-specific message data
     * @param extraOptionalArgs_ Extra optional arguments to be passed to the provider. This allow for specific provider configurations. Send bytes('') if not needed
     * @return The provider fee amount in wei.
     */
    function _providerFee(
        address providerAddress_,
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) internal view returns (uint256) {
        bytes memory targetChainTeleportReceiver = LibTeleport.teleportStorage().teleportAddressByChainId[
            targetChainId_
        ];

        if (targetChainTeleportReceiver.length == 0) revert TargetChainNotSupported();

        return
            IProvider(providerAddress_).fee(
                targetChainId_,
                targetChainTeleportReceiver,
                IProvider.DappTransmissionInfo(_addressToBytes(msg.sender), transmissionReceiver_, dAppId_, payload_),
                extraOptionalArgs_
            );
    }

    /*********************************** UTILS *********************************/

    /**
     *  @param addr value of type address
     *  @return addr value converted to type bytes
     */
    function _addressToBytes(address addr) internal pure returns (bytes memory) {
        return abi.encodePacked(addr);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import {LibGovernance, Counters, ECDSA} from "./libraries/LibGovernance.sol";
import {IGovernanceFacetErrors} from "./interfaces/IDiamondErrors.sol";

/**
 * @notice Provides modifiers for securing methods behind a governance vote
 */
abstract contract Governable {
    using Counters for Counters.Counter;
    using LibGovernance for LibGovernance.Storage;

    /**
     * @notice Verifies the message hash against the signatures. Requires a majority.
     * @param _ethHash hash to verify
     * @param _signatures governance hash signatures
     */
    function onlyConsensus(LibGovernance.Storage storage gs, bytes32 _ethHash, bytes[] memory _signatures) internal view {
        uint256 members = gs.membersCount();
        if (_signatures.length > members || _signatures.length <= (members / 2)) {
            revert IGovernanceFacetErrors.InvalidNumberOfSignatures();
        }

        address lastSigner;
        for (uint256 i = 0; i < _signatures.length; ) {
            address signer = ECDSA.recover(_ethHash, _signatures[i]);

            if (!gs.isMember(signer)) {
                revert IGovernanceFacetErrors.InvalidSigner();
            }
            if (signer <= lastSigner) {
                revert IGovernanceFacetErrors.WrongSignersOrder();
            }
            lastSigner = signer;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Verifies the message hash against the signatures. Requires a majority. Burns a nonce.
     * @param _ethHash hash to verify
     * @param _signatures governance hash signatures
     */
    modifier onlyConsensusNonce(bytes32 _ethHash, bytes[] calldata _signatures) {
        LibGovernance.Storage storage gs = LibGovernance.governanceStorage();
        onlyConsensus(gs, _ethHash, _signatures);
        gs.administrativeNonce.increment();
        _;
    }

    /**
     * @notice Verifies the message hash against the signatures. Requires a majority. Burns the hash.
     * @param _ethHash hash to verify
     * @param _signatures governance hash signatures
     */
    modifier onlyConsensusHash(bytes32 _ethHash, bytes[] memory _signatures) {
        LibGovernance.Storage storage gs = LibGovernance.governanceStorage();

        if (gs.hashesUsed[_ethHash]) {
            revert IGovernanceFacetErrors.HashAlreadyUsed();
        }
        gs.hashesUsed[_ethHash] = true;
        onlyConsensus(gs, _ethHash, _signatures);
        _;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface ICommonErrors {
    error NoDirectCall();

    error TransferFailed(string message);

    error AccountIsAddressZero();

    error NoValueAllowed();
}

interface IDiamondLoupeFacetErrors {
    error ExceededMaxFacets();
}

interface ILibDiamondErrors {
    // "Diamond: Function does not exist"
    error FunctionDoesNotExist();

    // LibDiamondCut: No selectors in facet to cut
    error NoSelectorsInFacetToCut();

    // LibDiamondCut: Can't add function that already exists
    error FunctionAlreadyExists();

    // LibDiamondCut: Can't replace immutable function
    error CantReplaceImmutableFn();

    // LibDiamondCut: Can't replace function with same function
    error CantReplaceWithSameFn();

    // LibDiamondCut: Can't replace function that doesn't exist
    error CantReplaceNonexistentFn();

    // LibDiamondCut: Remove facet address must be address(0)
    error RemoveFacetAddressMustBeZero();

    // LibDiamondCut: Can't remove function that doesn't exist
    error CantRemoveNonexistentFn();

    // LibDiamondCut: Can't remove immutable function
    error CantRemoveImmutableFn();

    // LibDiamondCut: Incorrect FacetCutAction
    error IncorrectFacetCutAction();

    // LibDiamondCut: _init is address(0) but_calldata is not empty
    error InitIsAddress0AndCalldataNotEmpty();

    // LibDiamondCut: _calldata is empty but _init is not address(0)
    error CalldataIsEmpty();

    // LibDiamondCut: _init function reverted
    error InitFunctionReverted();

    // either "LibDiamondCut: Add facet has no code" or "LibDiamondCut: Replace facet has no code" or "LibDiamondCut: _init address has no code"
    error ContractHasNoCode(string checkCase);

    error LibDiamond__InitIsNotFacet();
}

interface ITeleportFacetErrors {
    /**
     * @dev Used to make sure the function is only called by the teleport contract.
     */
    error OnlyValidProviderCalls();

    /**
     * @dev Used when there's not provider that supports the specified transmission.
     */
    error TransmissionNotSupportedByAnyProvider();

    /**
     * @dev Used when the provided provider address is the zero address.
     */
    error ProviderCannotBeZeroAddress();

    /**
     * @dev Used when the provided provider address is not supported by the provider selector.
     */
    error InvalidProvider();

    /**
     * @dev Thrown when a message is received from an unknown source chain.
     */
    error SourceChainNotSupported();

    /**
     * @dev Thrown when a message is received from an invalid teleport sender.
     */
    error InvalidTeleportSender();

    /**
     * @dev Thrown when a message is being send to an unknown target chain.
     */
    error TargetChainNotSupported();

    // LibTeleport: INVALID_CHAIN_ID
    error InvalidChainId();

    // LibTeleport: INVALID_SENDER_ADDRESS
    error InvalidSenderAddress();

    // LibTeleport: DUPLICATE_CHAIN_ID
    error DuplicateChainId();
}

interface IFeeCalculatorFacetErrors {
    // FeeCalculator: nothing to claim
    error NothingToClaim();

    // FeeCalculator: insufficient fee amount
    error InsufficientFeeAmount();
}

interface IGovernanceFacetErrors {
    // Governance: msg.sender is not a member
    error NotAValidMember();

    // Governance: member list empty
    error MemberListEmpty();

    // Governance: Account already added
    error AccountAlreadyAdded();

    // Governance: Would become memberless
    error WouldBecomeMemberless();

    // Governance: Invalid number of signatures
    error InvalidNumberOfSignatures();

    // Governance: invalid signer
    error InvalidSigner();

    // Governance: signers must be in ascending order and uniques
    error WrongSignersOrder();

    // Governance: message hash already used
    error HashAlreadyUsed();
}

// solhint-disable no-empty-blocks
interface IDiamondErrors is
    ICommonErrors,
    IDiamondLoupeFacetErrors,
    ILibDiamondErrors,
    ITeleportFacetErrors,
    IFeeCalculatorFacetErrors,
    IGovernanceFacetErrors
{
    // We just combine all the interfaces into one to simplify the import from the ITeleportDiamond and generate the ABI
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface IProvider {
    /**
     * @dev Used to make sure the function is only called by the teleport contract.
     */
    error OnlyTeleportCalls();

    /// @notice emitted when transmitting a payload
    event Transmission(
        bytes transmissionSender,
        uint8 targetChainId,
        bytes transmissionReceiver,
        bytes32 dAppId,
        bytes payload
    );
    /// @notice emitted when delivering a payload
    event Delivery(bytes32 transmissionId);

    struct DappTransmissionInfo {
        bytes dappTransmissionSender;
        bytes dappTransmissionReceiver;
        bytes32 dAppId;
        bytes dappPayload;
    }

    function supportedChains(uint256 index) external view returns (uint8);

    function supportedChainsCount() external view returns (uint256);

    /// @return The currently set service fee
    function fee(
        uint8 targetChainId,
        bytes calldata transmissionTeleportReceiver,
        DappTransmissionInfo calldata dappTranmissionInfo,
        bytes calldata extraOptionalArgs
    ) external view returns (uint256);

    function sendMsg(
        uint8 targetChainId,
        bytes calldata transmissionTeleportReceiver,
        DappTransmissionInfo calldata dappTranmissionInfo,
        bytes calldata extraOptionalArgs
    ) external payable;

    function manualClaim(bytes calldata args) external;

    function config(bytes calldata configData) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface IProviderSelector {
    /**
     * @dev Used to make sure the function is only called by the teleport contract.
     */
    error OnlyTeleportCalls();

    function isValidProvider(address provider) external returns (bool);

    function getProvider(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_
    ) external view returns (address);

    function config(bytes calldata configData) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

/**
 * @title ITeleport
 * @dev Interface for the Teleport contract, which allows for cross-chain communication and messages transfer using different providers.
 */
interface ITeleport {
    /**
     * @notice Emitted when collecting fees
     * @param serviceFee The amount of service fee collected
     */
    event TransmissionFees(uint256 serviceFee);

    /**
     * @dev Transmits a message to the specified target chain ID. The message will be delivered using the most suitable provider.
     * @param targetChainId The ID of the target chain
     * @param transmissionReceiver The address of the receiver on the target chain
     * @param dAppId The ID of the dApp on the target chain
     * @param payload The message payload
     */
    function transmit(
        uint8 targetChainId,
        bytes calldata transmissionReceiver,
        bytes32 dAppId,
        bytes calldata payload
    ) external payable;

    /**
     * @notice Selects a provider to bridge the message to the target chain
     * @param targetChainId_ The chainID where the message should be delivered to
     * @param transmissionReceiver_ The address of the contract in the target chain to receive the transmission
     * @param dAppId_ ID for the dApp that the message belongs to
     * @param payload_ The dApp-specific message data
     * @param extraOptionalArgs_ Extra optional arguments to be passed to the provider. This allow for specific provider configurations. Send bytes('') if not needed
     */
    function transmitWithArgs(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external payable;

    /**
     * @dev Transmits a message to the specified target chain ID. The message will be delivered using the specified provider.
     * @param targetChainId The ID of the target chain
     * @param transmissionReceiver The address of the receiver on the target chain
     * @param dAppId The ID of the dApp on the target chain
     * @param payload The message payload
     * @param providerAddress The address of the provider to use
     */
    function transmitWithProvider(
        uint8 targetChainId,
        bytes calldata transmissionReceiver,
        bytes32 dAppId,
        bytes calldata payload,
        address providerAddress,
        bytes memory extraOptionalArgs_
    ) external payable;

    /**
     * @dev Delivers a message to this chain.
     * @param args The message arguments, which depend on the provider. See the provider's documentation for more information.
     */
    function deliver(address providerAddress, bytes calldata args) external;

    /**
     * @dev Returns the currently set teleport fee.
     * @return The teleport fee amount
     */
    function teleportFee() external view returns (uint256);

    /**
     * @dev Returns the fee for the automatic selected provider.
     * @return The provider fee amount
     */
    function providerFee(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view returns (uint256);

    /**
     * @dev Returns the fee for the stated provider.
     * @return The provider fee amount
     */
    function providerFee(
        address providerAddress_,
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view returns (uint256);

    /**
     * @dev Returns the currently set service fee.
     * @return The service fee amount
     */
    function serviceFee(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view returns (uint256);

    /**
     * @dev Returns the currently set service fee.
     * @return The service fee amount
     */
    function serviceFee(
        address providerAddress_,
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view returns (uint256);

    struct DappTransmissionReceive {
        bytes teleportSender;
        uint8 sourceChainId;
        bytes dappTransmissionSender;
        address dappTransmissionReceiver;
        bytes32 dAppId;
        bytes payload;
    }

    /**
     * @dev Notifies the teleport that the provider has received a new message. Teleport should invoke the related dapps.
     * @param args The arguments of the message.
     */
    function onProviderReceive(DappTransmissionReceive calldata args) external;

    function configProviderSelector(bytes calldata configData, bytes[] calldata signatures_) external;

    function configProvider(bytes calldata configData, address providerAddress, bytes[] calldata signatures_) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface ITeleportDApp {
    /**
     * @notice Called by a Teleport contract to deliver a verified payload to a dApp
     * @param _sourceChainId The chainID where the transmission originated
     * @param _transmissionSender The address that invoked `transmit()` on the source chain
     * @param _dAppId an identifier for the dApp
     * @param _payload a dApp-specific byte array with the message data
     */
    function onTeleportMessage(
        uint8 _sourceChainId,
        bytes calldata _transmissionSender,
        bytes32 _dAppId,
        bytes calldata _payload
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface IUtility {
    event TeleportSenderSet(TeleportSender[] senders_);
    event ProviderSelectorSet(address providerSelector_);

    struct Subroutine {
        address contractAddress;
        bytes callParams;
    }

    /**
     * @dev Struct with the information of the teleport sender of a specific chain with the defined MPCId chainId.
     */
    struct TeleportSender {
        // The MPCId of the sender teleport
        uint8 chainId;
        // The actual teleport sender address
        bytes senderAddress;
    }

    /// @return The internal Teleport chain Id
    function chainId() external view returns (uint8);

    /**
     * @dev Returns the address of the provider selector.
     */
    function providerSelector() external view returns (address);

    /**
     * @dev Returns the teleport sender address for a given chainId.
     * @param _chainId The chainId of the teleport sender.
     * @return The teleport sender address.
     */
    function getTeleportSender(uint8 _chainId) external view returns (bytes memory);

    /**
     * @dev Sets the teleport senders that are allowed to send messaged from another chains.
     * @param senders_ An array of `TeleportSender` structs representing the teleport senders.
     * @param signatures_ An array of bytes representing the governance signatures that allow this change.
     */
    function setTeleportSenders(TeleportSender[] calldata senders_, bytes[] calldata signatures_) external;

    /**
     * @dev Sets the provider selector.
     * @param providerSelector_ The address of the provider selector contract.
     * @param signatures_ The array of governance members signatures that allow the change.
     */
    function setProviderSelector(address providerSelector_, bytes[] calldata signatures_) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import {LibGovernance} from "./LibGovernance.sol";
import {IFeeCalculatorFacetErrors} from "../interfaces/IDiamondErrors.sol";

library LibFeeCalculator {
    bytes32 private constant STORAGE_POSITION = keccak256("fee.calculator.storage");
    using LibGovernance for LibGovernance.Storage;

    struct Storage {
        // The current service fee
        uint256 serviceFee;
        // Total fees accrued since contract deployment
        uint256 feesAccrued;
        // Total fees accrued up to the last point a member claimed rewards
        uint256 previousAccrued;
        // Accumulates rewards on a per-member basis
        uint256 accumulator;
        // Total rewards claimed per member
        mapping(address => uint256) claimedRewardsPerAccount;
    }

    function feeCalculatorStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice addNewMember Sets the initial claimed rewards for new members
     * @param account_ The address of the new member
     */
    function addNewMember(address account_) internal {
        LibFeeCalculator.Storage storage fcs = feeCalculatorStorage();

        uint256 diff = fcs.feesAccrued - fcs.previousAccrued;
        if (diff > 0) {
            fcs.accumulator += diff / LibGovernance.governanceStorage().membersCount();
            fcs.previousAccrued = fcs.feesAccrued;
        }

        fcs.claimedRewardsPerAccount[account_] = fcs.accumulator;
    }

    /**
     * @notice claimReward Make calculations based on fee distribution and returns the claimable amount
     * @param claimer_ The address of the claimer
     */
    function claimReward(address claimer_) internal returns (uint256) {
        LibFeeCalculator.Storage storage fcs = feeCalculatorStorage();

        uint256 diff = fcs.feesAccrued - fcs.previousAccrued;
        if (diff > 0) {
            uint256 gain = diff / LibGovernance.governanceStorage().membersCount();
            fcs.previousAccrued = fcs.feesAccrued;
            fcs.accumulator += gain;
        }

        uint256 claimableAmount = fcs.accumulator - fcs.claimedRewardsPerAccount[claimer_];

        fcs.claimedRewardsPerAccount[claimer_] = fcs.accumulator;

        return claimableAmount;
    }

    /**
     * @notice Accrue reward to be later distributed to members
     */
    function accrueReward(uint256 amount_) internal returns (uint256) {
        LibFeeCalculator.Storage storage fcs = feeCalculatorStorage();

        if (amount_ < fcs.serviceFee) {
            revert IFeeCalculatorFacetErrors.InsufficientFeeAmount();
        }
        fcs.feesAccrued += fcs.serviceFee;

        return amount_ - fcs.serviceFee;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
// solhint-disable-next-line no-unused-import
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // We will use this from consumers of this library
import {IGovernanceFacetErrors} from "../interfaces/IDiamondErrors.sol";

library LibGovernance {
    using EnumerableSet for EnumerableSet.AddressSet;
    bytes32 private constant STORAGE_POSITION = keccak256("diamond.standard.governance.storage");

    struct Storage {
        // nonce used for making administrative changes
        Counters.Counter administrativeNonce;
        // the set of active validators
        EnumerableSet.AddressSet membersSet;
        // governance message hashes we've executed
        mapping(bytes32 => bool) hashesUsed;
    }

    function governanceStorage() internal pure returns (Storage storage gs) {
        bytes32 position = STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            gs.slot := position
        }
    }

    /// @notice Adds/removes a validator from the member set
    function updateMember(Storage storage gs, address account_, bool status_) internal {
        if (status_) {
            if (!gs.membersSet.add(account_)) {
                revert IGovernanceFacetErrors.AccountAlreadyAdded();
            }
        } else if (!status_) {
            if (gs.membersSet.length() <= 1) {
                revert IGovernanceFacetErrors.WouldBecomeMemberless();
            }
            if (!gs.membersSet.remove(account_)) {
                revert IGovernanceFacetErrors.NotAValidMember();
            }
        }
    }

    /// @notice Returns true/false depending on whether a given address is member or not
    function isMember(Storage storage gs, address member_) internal view returns (bool) {
        return gs.membersSet.contains(member_);
    }

    /// @notice Returns the count of the members
    function membersCount(Storage storage gs) internal view returns (uint256) {
        return gs.membersSet.length();
    }

    /// @notice Returns the address of a member at a given index
    function memberAt(Storage storage gs, uint256 index_) internal view returns (address) {
        return gs.membersSet.at(index_);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import {IUtility} from "../interfaces/IUtility.sol";
import {ICommonErrors, ITeleportFacetErrors} from "../interfaces/IDiamondErrors.sol";

library LibTeleport {
    bytes32 private constant STORAGE_POSITION = keccak256("message.teleport.storage");

    struct Storage {
        /// The Id of the current chain
        uint8 chainId;
        address providerSelector;
        // Who is allowed to send us teleport messages by MPCId
        mapping(uint8 => bytes) teleportAddressByChainId;
        uint8[] supportedChainIds;
    }

    /// @notice Returns the Teleport Storage object at the correct slot
    function teleportStorage() internal pure returns (Storage storage mts) {
        bytes32 position = STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mts.slot := position
        }
    }

    /// @notice Sets the teleports' addresses on all supported chains
    function updateTeleportSenders(IUtility.TeleportSender[] calldata senders_) internal {
        LibTeleport.Storage storage ts = teleportStorage();
        // reset teleportAddressByChainId
        for (uint256 i = 0; i < ts.supportedChainIds.length; ) {
            delete ts.teleportAddressByChainId[ts.supportedChainIds[i]];
            unchecked {
                ++i;
            }
        }
        // reset supportedChainIds
        delete ts.supportedChainIds;
        for (uint256 i = 0; i < senders_.length; ) {
            if (senders_[i].chainId == 0) {
                revert ITeleportFacetErrors.InvalidChainId();
            }
            if (senders_[i].senderAddress.length != 20) {
                revert ITeleportFacetErrors.InvalidSenderAddress();
            }
            if (keccak256(abi.encodePacked(senders_[i].senderAddress)) == keccak256(abi.encodePacked(address(0)))) {
                revert ICommonErrors.AccountIsAddressZero();
            }
            if (keccak256(ts.teleportAddressByChainId[senders_[i].chainId]) != keccak256(bytes(""))) {
                revert ITeleportFacetErrors.DuplicateChainId();
            }
            ts.teleportAddressByChainId[senders_[i].chainId] = senders_[i].senderAddress;
            ts.supportedChainIds.push(senders_[i].chainId);
            unchecked {
                ++i;
            }
        }
    }
}