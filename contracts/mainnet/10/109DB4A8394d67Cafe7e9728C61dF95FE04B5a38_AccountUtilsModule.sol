// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

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
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
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
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
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
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.20;

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
        InvalidSignatureS
    }

    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
     * return address(0) without also returning an error description. Errors are documented using an enum (error type)
     * and a bytes32 providing additional information about the error.
     *
     * If no error is returned, then the address can be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError, bytes32) {
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
            return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError, bytes32) {
        unchecked {
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError, bytes32) {
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
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
     */
    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/MessageHashUtils.sol)

pragma solidity ^0.8.20;

import {Strings} from "../Strings.sol";

/**
 * @dev Signature message hash utilities for producing digests to be consumed by {ECDSA} recovery or signing.
 *
 * The library provides methods for generating a hash of a message that conforms to the
 * https://eips.ethereum.org/EIPS/eip-191[EIP 191] and https://eips.ethereum.org/EIPS/eip-712[EIP 712]
 * specifications.
 */
library MessageHashUtils {
    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing a bytes32 `messageHash` with
     * `"\x19Ethereum Signed Message:\n32"` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * NOTE: The `messageHash` parameter is intended to be the result of hashing a raw message with
     * keccak256, although any bytes32 value can be safely used because the final digest will
     * be re-hashed.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 32 is the bytes-length of messageHash
            mstore(0x1c, messageHash) // 0x1c (28) is the length of the prefix
            digest := keccak256(0x00, 0x3c) // 0x3c is the length of the prefix (0x1c) + messageHash (0x20)
        }
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing an arbitrary `message` with
     * `"\x19Ethereum Signed Message:\n" + len(message)` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes memory message) internal pure returns (bytes32) {
        return
            keccak256(bytes.concat("\x19Ethereum Signed Message:\n", bytes(Strings.toString(message.length)), message));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x00` (data with intended validator).
     *
     * The digest is calculated by prefixing an arbitrary `data` with `"\x19\x00"` and the intended
     * `validator` address. Then hashing the result.
     *
     * See {ECDSA-recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"19_00", validator, data));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-712 typed data (EIP-191 version `0x01`).
     *
     * The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
     * `\x19\x01` and hashing the result. It corresponds to the hash signed by the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of EIP-712.
     *
     * See {ECDSA-recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

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
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
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
            set._positions[value] = set._values.length;
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
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Initializable module
 */
library Initializable {
    // ------- Storage -------
    struct InitializableStorageData {
        bool initialized;
    }

    error AlreadyInitialized();
    error NotInitialized();

    /**
     * @dev Returns the account stored at the specified account id.
     */
    function getStorage() internal pure returns (InitializableStorageData storage data) {
        bytes32 slot = keccak256(abi.encode("io.infinex.InitializableStorage"));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data.slot := slot
        }
    }

    // ------- Implementation -------
    function initialize() internal {
        InitializableStorageData storage data = getStorage();

        // Note: We don't use onlyUninitialized here to save gas by preventing a double call to load().
        if (data.initialized) revert AlreadyInitialized();

        data.initialized = true;
    }

    modifier onlyInitialized() {
        if (!getStorage().initialized) revert NotInitialized();
        _;
    }

    modifier onlyUninitialized() {
        if (getStorage().initialized) revert AlreadyInitialized();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IAccountUtilsModule } from "src/interfaces/accounts/IAccountUtilsModule.sol";
import { IInfinexProtocolConfigBeacon } from "src/interfaces/beacons/IInfinexProtocolConfigBeacon.sol";

import { SecurityModifiers } from "../utils/SecurityModifiers.sol";

import { ERC2771Context } from "src/forwarder/ERC2771Context.sol";
import { Account } from "../storage/Account.sol";
import { Bridge } from "../storage/Bridge.sol";
import { SecurityKeys } from "../storage/SecurityKeys.sol";
import { AccountConstants } from "../utils/AccountConstants.sol";

import { Error } from "src/libraries/Error.sol";

//       c=<
//        |
//        |   ////\    1@2
//    @@  |  /___\**   @@@2			@@@@@@@@@@@@@@@@@@@@@@
//   @@@  |  |~L~ |*   @@@@@@		@@@  @@@@@        @@@@    @@@ @@@@    @@@  @@@@@@@@ @@@@ @@@@    @@@ @@@@@@@@@ @@@@   @@@@
//  @@@@@ |   \=_/8    @@@@1@@		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@   @@@ @@@@@@@@@ @@@@ @@@@@  @@@@ @@@@@@@@@  @@@@ @@@@
// @@@@@@| _ /| |\__ @@@@@@@@2		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@ @@@ @@@@      @@@@ @@@@@@ @@@@ @@@         @@@@@@@
// 1@@@@@@|\  \___/)   @@1@@@@@2	~~~  ~~~~~  @@@@  ~~@@    ~~~ ~~~~~~~~~~~ ~~~~      ~~~~ ~~~~~~~~~~~ ~@@          @@@@@
// 2@@@@@ |  \ \ / |     @@@@@@2	@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@@@@@ @@@@@@@@@ @@@@ @@@@@@@@@@@ @@@@@@@@@    @@@@@
// 2@@@@  |_  >   <|__    @@1@12	@@@  @@@@@  @@@@  @@@@    @@@ @@@@ @@@@@@ @@@@      @@@@ @@@@ @@@@@@ @@@         @@@@@@@
// @@@@  / _|  / \/    \   @@1@		@@@   @@@   @@@@  @@@@    @@@ @@@@  @@@@@ @@@@      @@@@ @@@@  @@@@@ @@@@@@@@@  @@@@ @@@@
//  @@ /  |^\/   |      |   @@1		@@@         @@@@  @@@@    @@@ @@@@    @@@ @@@@      @@@@ @@@    @@@@ @@@@@@@@@ @@@@   @@@@
//   /     / ---- \ \\\=    @@		@@@@@@@@@@@@@@@@@@@@@@
//   \___/ --------  ~~    @@@
//     @@  | |   | |  --   @@
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

contract AccountUtilsModule is IAccountUtilsModule, SecurityModifiers {
    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the Infinex Protocol Config
     * @return The Infinex Protocol Config Beacon
     */
    function infinexProtocolConfigBeacon() external view returns (address) {
        return address(Account._infinexProtocolConfig());
    }

    /**
     * @notice Check if the provided operation key is valid
     * @param _operationKey The operation key to check
     * @return A boolean indicating if the key is valid
     */
    function isValidOperationKey(address _operationKey) external view returns (bool) {
        return SecurityKeys._isValidOperationKey(_operationKey);
    }

    /**
     * @notice Check if the provided sudo key is valid
     * @param _sudoKey The sudo key to check
     * @return A boolean indicating if the sudo key is valid
     */
    function isValidSudoKey(address _sudoKey) external view returns (bool) {
        return SecurityKeys._isValidSudoKey(_sudoKey);
    }

    /**
     * @notice Check if the provided recovery key is valid
     * @param _recoveryKey The recovery key to check
     * @return A boolean indicating if the recovery key is valid
     */
    function isValidRecoveryKey(address _recoveryKey) external view returns (bool) {
        return SecurityKeys._isValidRecoveryKey(_recoveryKey);
    }

    /**
     * @notice Retrieves the Circle Bridge parameters.
     * @return The address of the circleBridge.
     * @return The address of the circleMinter.
     * @return The default circle bridge destination domain
     */
    function getCircleBridgeParams() external view returns (address, address, uint32) {
        Bridge.Data storage bridgeData = Bridge.getStorage();
        return (bridgeData.circleBridge, bridgeData.circleMinter, bridgeData.defaultDestinationCCTPDomain);
    }

    /**
     * @notice Retrieves the Wormhole Circle Bridge parameters.
     * @return The address of the wormholeCircleBridge.
     */
    function getWormholeCircleBridge() external view returns (address) {
        Bridge.Data storage bridgeData = Bridge.getStorage();
        return bridgeData.wormholeCircleBridge;
    }

    /**
     * @notice Retrieves the Wormhole Circle Bridge parameters.
     * @return The address of the wormholeCircleBridge.
     * @return The address of the wormholeCircleBridge and the defaultDestinationWormholeChainId
     */
    function getWormholeCircleBridgeParams() external view returns (address, uint16) {
        Bridge.Data storage bridgeData = Bridge.getStorage();
        return (bridgeData.wormholeCircleBridge, bridgeData.defaultDestinationWormholeChainId);
    }

    /**
     * @notice Retrieves the USDC address.
     * @return The address of USDC.
     */
    function getUSDCAddress() external view returns (address) {
        Bridge.Data storage bridgeData = Bridge.getStorage();
        return bridgeData.USDC;
    }

    /**
     * @notice Retrieves the maximum withdrawal fee.
     * @return The maximum withdrawal fee.
     */
    function getMaxWithdrawalFee() external view returns (uint256) {
        return AccountConstants.MAX_WITHDRAWAL_FEE;
    }

    /*///////////////////////////////////////////////////////////////
                                MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Upgrade to a new beacon implementation and updates any new parameters along with it
     * @param _newInfinexProtocolConfigBeacon The address of the new beacon
     * @dev requires the sender to be the sudo key
     * @dev Requires passing the new beacon address which matches the latest to ensure that the upgrade both
     * is as the user intended, and is to the latest beacon implementation. Prevents the user from opting in to a
     * specific version and upgrading to a later version that may have been deployed between the opt-in and the upgrade
     */
    function upgradeProtocolBeaconParameters(address _newInfinexProtocolConfigBeacon) external requiresSudoKeySender {
        if (_newInfinexProtocolConfigBeacon == address(0)) revert Error.NullAddress();
        Account.Data storage accountData = Account.getStorage();
        IInfinexProtocolConfigBeacon protocolConfigBeacon = Account._infinexProtocolConfig();
        address latestInfinexProtocolConfigBeacon = protocolConfigBeacon.getLatestInfinexProtocolConfigBeacon();

        if (latestInfinexProtocolConfigBeacon == address(protocolConfigBeacon)) {
            revert Error.SameAddress();
        }
        if (latestInfinexProtocolConfigBeacon != _newInfinexProtocolConfigBeacon) {
            revert Error.ImplementationMismatch(_newInfinexProtocolConfigBeacon, latestInfinexProtocolConfigBeacon);
        }

        address beaconForwarder = protocolConfigBeacon.TRUSTED_FORWARDER();
        if (ERC2771Context.isTrustedForwarder(beaconForwarder)) {
            ERC2771Context._removeTrustedForwarder(beaconForwarder);
            ERC2771Context._addTrustedForwarder(IInfinexProtocolConfigBeacon(latestInfinexProtocolConfigBeacon).TRUSTED_FORWARDER());
        }

        emit AccountInfinexProtocolBeaconImplementationUpgraded(latestInfinexProtocolConfigBeacon);
        accountData.infinexProtocolConfigBeacon = latestInfinexProtocolConfigBeacon;
    }

    /**
     * @notice Updates the parameters for the Circle Bridge to the latest from the Infinex Protocol Config Beacon.
     * Update is opt in to prevent malicious automatic updates.
     * @dev requires the sender to be the sudo key
     */
    function updateCircleBridgeParams() external requiresSudoKeySender {
        Bridge.Data storage bridgeData = Bridge.getStorage();

        IInfinexProtocolConfigBeacon protocolConfigBeacon = Account._infinexProtocolConfig();
        (address circleBridge, address circleMinter, uint32 defaultDestinationCCTPDomain) =
            protocolConfigBeacon.getCircleBridgeParams();

        emit AccountCircleBridgeParamsUpgraded(circleBridge, circleMinter, defaultDestinationCCTPDomain);

        bridgeData.circleBridge = circleBridge;
        bridgeData.circleMinter = circleMinter;
        bridgeData.defaultDestinationCCTPDomain = defaultDestinationCCTPDomain;
    }

    /**
     * @notice Updates the parameters for the Wormhole Circle Bridge to the latest from the Infinex Protocol Config Beacon.
     * Update is opt in to prevent malicious automatic updates.
     * @dev requires the sender to be the sudo key
     */
    function updateWormholeCircleBridge() external requiresSudoKeySender {
        Bridge.Data storage bridgeData = Bridge.getStorage();

        IInfinexProtocolConfigBeacon protocolConfigBeacon = Account._infinexProtocolConfig();
        (address wormholeCircleBridge, uint16 defaultDestinationWormholeChainId) = protocolConfigBeacon.getWormholeCircleBridgeParams();

        emit AccountWormholeCircleBridgeParamsUpgraded(wormholeCircleBridge, defaultDestinationWormholeChainId);

        bridgeData.wormholeCircleBridge = wormholeCircleBridge;
        bridgeData.defaultDestinationWormholeChainId = defaultDestinationWormholeChainId;
    }

    /**
     * @notice Updates the USDC address from the Infinex Protocol Config Beacon.
     * Update is opt in to prevent malicious automatic updates.
     * @dev requires the sender to be the sudo key
     */
    function updateUSDCAddress() external requiresSudoKeySender {
        Bridge.Data storage bridgeData = Bridge.getStorage();

        IInfinexProtocolConfigBeacon protocolConfigBeacon = Account._infinexProtocolConfig();
        address USDC = protocolConfigBeacon.USDC();

        emit AccountUSDCAddressUpgraded(USDC);

        bridgeData.USDC = USDC;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IInfinexProtocolConfigBeacon } from "src/interfaces/beacons/IInfinexProtocolConfigBeacon.sol";

/**
 * @title Account storage struct
 */
library Account {
    struct Data {
        address infinexProtocolConfigBeacon; // Address of the Infinex Protocol Config Beacon
        uint256 referralTokenId; // ID of the referral token
    }

    /**
     * @dev Returns the account stored at the specified account id.
     */
    function getStorage() internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("io.infinex.AccountStorage"));
        assembly {
            data.slot := s
        }
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the Infinex Protocol Config
     * @return The Infinex Protocol Config Beacon
     */
    function _infinexProtocolConfig() internal view returns (IInfinexProtocolConfigBeacon) {
        Data storage data = getStorage();
        return IInfinexProtocolConfigBeacon(data.infinexProtocolConfigBeacon);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Bridging related storage struct and functions
 */
library Bridge {
    struct Data {
        // Parameters for interacting with USDC and the Circle Bridge
        address circleBridge;
        address circleMinter;
        address USDC;
        address wormholeCircleBridge;
        uint32 defaultDestinationCCTPDomain;
        uint16 defaultDestinationWormholeChainId;
    }

    /**
     * @dev Returns the account stored at the specified account id.
     */
    function getStorage() internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("io.infinex.Bridge"));
        assembly {
            data.slot := s
        }
    }

    /**
     * @dev Returns the address of the USDC token.
     */
    function _USDC() internal view returns (address) {
        return getStorage().USDC;
    }

    /**
     * @dev Returns the address of the Circle Bridge contract.
     */
    // slither-disable-next-line dead-code
    function _circleBridge() internal view returns (address) {
        return getStorage().circleBridge;
    }

    /**
     * @dev Returns the address of the Circle Minter contract.
     * The minter contract stores the maximum amount of tokens that can be minted or burned.
     * The contract is responsible for minting and burning tokens as part of a bridging transaction.
     */
    // slither-disable-next-line dead-code
    function _circleMinter() internal view returns (address) {
        return getStorage().circleMinter;
    }

    /**
     * @dev Returns the address of the Wormhole Circle Bridge contract.
     */
    function _wormholeCircleBridge() internal view returns (address) {
        return getStorage().wormholeCircleBridge;
    }

    /**
     * @dev Returns the CCTP domain of the default destination chain.
     */
    // slither-disable-next-line dead-code
    function _defaultDestinationCCTPDomain() internal view returns (uint32) {
        return getStorage().defaultDestinationCCTPDomain;
    }

    /**
     * @dev Returns the Wormhole chain id of the default destination chain.
     */
    // slither-disable-next-line dead-code
    function _defaultDestinationWormholeChainId() internal view returns (uint16) {
        return getStorage().defaultDestinationWormholeChainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

library EIP712 {
    bytes32 private constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @custom:storage-location erc7201:openzeppelin.storage.EIP712
    struct EIP712Storage {
        /// @custom:oz-renamed-from _HASHED_NAME
        bytes32 _hashedName;
        /// @custom:oz-renamed-from _HASHED_VERSION
        bytes32 _hashedVersion;
        string _name;
        string _version;
    }

    function _getEIP712Storage() private pure returns (EIP712Storage storage data) {
        bytes32 s = keccak256(abi.encode("io.infinex.EIP712"));
        assembly {
            data.slot := s
        }
    }

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal {
        EIP712Storage storage $ = _getEIP712Storage();
        $._name = name;
        $._version = version;

        // Reset prior values in storage if upgrading
        $._hashedName = 0;
        $._hashedVersion = 0;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator();
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash(), block.chainid, address(this)));
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
        return MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {IERC-5267}.
     */
    function eip712Domain()
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
        EIP712Storage storage $ = _getEIP712Storage();
        // If the hashed name and version in storage are non-zero, the contract hasn't been properly initialized
        // and the EIP712 domain is not reliable, as it will be missing name and version.
        // solhint-disable-next-line gas-custom-errors
        require($._hashedName == 0 && $._hashedVersion == 0, "EIP712: Uninitialized");

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
     * @dev The name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Name() internal view returns (string memory) {
        EIP712Storage storage $ = _getEIP712Storage();
        return $._name;
    }

    /**
     * @dev The version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Version() internal view returns (string memory) {
        EIP712Storage storage $ = _getEIP712Storage();
        return $._version;
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: In previous versions this function was virtual. In this version you should override `_EIP712Name` instead.
     */
    function _EIP712NameHash() internal view returns (bytes32) {
        EIP712Storage storage $ = _getEIP712Storage();
        string memory name = _EIP712Name();
        if (bytes(name).length > 0) {
            return keccak256(bytes(name));
        } else {
            // If the name is empty, the contract may have been upgraded without initializing the new storage.
            // We return the name hash in storage if non-zero, otherwise we assume the name is empty by design.
            bytes32 hashedName = $._hashedName;
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
     * NOTE: In previous versions this function was virtual. In this version you should override `_EIP712Version` instead.
     */
    function _EIP712VersionHash() internal view returns (bytes32) {
        EIP712Storage storage $ = _getEIP712Storage();
        string memory version = _EIP712Version();
        if (bytes(version).length > 0) {
            return keccak256(bytes(version));
        } else {
            // If the version is empty, the contract may have been upgraded without initializing the new storage.
            // We return the version hash in storage if non-zero, otherwise we assume the version is empty by design.
            bytes32 hashedVersion = $._hashedVersion;
            if (hashedVersion != 0) {
                return hashedVersion;
            } else {
                return keccak256("");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { Error } from "src/libraries/Error.sol";

/**
 * @title Security keys storage and functions
 */
library SecurityKeys {
    using MessageHashUtils for bytes32;

    // slither-disable-next-line constable-states,unused-state
    bytes32 internal constant _SIGNATURE_REQUEST_TYPEHASH = keccak256(
        "Request(address _address,address _address2,uint256 _uint256,bytes32 _nonce,uint32 _uint32,bool _bool,bytes4 _selector)"
    );

    struct Data {
        mapping(bytes32 => bool) nonces; // Mapping of nonces
        mapping(address => bool) operationKeys;
        mapping(address => bool) recoveryKeys;
        mapping(address => bool) sudoKeys;
        uint16 sudoKeysCounter;
    }

    /*///////////////////////////////////////////////////////////////
                    			EVENTS / ERRORS
    ///////////////////////////////////////////////////////////////*/

    event NonceConsumed(bytes32 nonce);
    event OperationKeyStatusSet(address operationKey, bool isValid);
    event RecoveryKeyStatusSet(address recoveryKey, bool isValid);
    event SudoKeyStatusSet(address sudoKey, bool isValid);

    /**
     * @dev Returns the account stored at the specified account id.
     */
    function getStorage() internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("io.infinex.SecurityKeys"));
        assembly {
            data.slot := s
        }
    }

    /*///////////////////////////////////////////////////////////////
                                    VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if the provided operation key is valid
     * @param _operationKey The operation key to check
     * @return A boolean indicating if the operation key is valid
     */
    function _isValidOperationKey(address _operationKey) internal view returns (bool) {
        Data storage data = getStorage();
        return data.operationKeys[_operationKey];
    }

    /**
     * @notice Check if the provided recovery key is valid
     * @param _recoveryKey The recovery key to check
     * @return A boolean indicating if the recovery key is valid
     */
    function _isValidRecoveryKey(address _recoveryKey) internal view returns (bool) {
        Data storage data = getStorage();
        return data.recoveryKeys[_recoveryKey];
    }

    /**
     * @notice Check if the provided sudo key is valid
     * @param _sudoKey The sudo key to check
     * @return A boolean indicating if the sudo key is valid
     */
    function _isValidSudoKey(address _sudoKey) internal view returns (bool) {
        Data storage data = getStorage();
        return data.sudoKeys[_sudoKey];
    }

    /**
     * @notice Check if the provided nonce is valid
     * @param _nonce The nonce to check
     * @return A boolean indicating if the nonce is valid
     */
    function _isValidNonce(bytes32 _nonce) internal view returns (bool) {
        Data storage data = getStorage();
        return !data.nonces[_nonce];
    }

    /*///////////////////////////////////////////////////////////////
                                MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Set an operation key for the account
     * @param _operationKey The operation key address to be set
     * @param _isValid Whether the key is to be set as valid or invalid
     */
    function _setOperationKeyStatus(address _operationKey, bool _isValid) internal {
        Data storage data = getStorage();
        if (_operationKey == address(0)) revert Error.NullAddress();
        if (data.operationKeys[_operationKey]) {
            if (_isValid) revert Error.KeyAlreadyValid();
        } else {
            if (!_isValid) revert Error.KeyAlreadyInvalid();
        }
        emit OperationKeyStatusSet(_operationKey, _isValid);
        data.operationKeys[_operationKey] = _isValid;
    }

    /**
     * @notice Set a new recovery key for the account
     * @param _recoveryKey The recovery key address to be set
     * @param _isValid Whether the key is to be set as valid or invalid
     */
    function _setRecoveryKeyStatus(address _recoveryKey, bool _isValid) internal {
        Data storage data = getStorage();
        if (_recoveryKey == address(0)) revert Error.NullAddress();
        if (data.recoveryKeys[_recoveryKey]) {
            if (_isValid) revert Error.KeyAlreadyValid();
        } else {
            if (!_isValid) revert Error.KeyAlreadyInvalid();
        }
        emit RecoveryKeyStatusSet(_recoveryKey, _isValid);
        data.recoveryKeys[_recoveryKey] = _isValid;
    }

    /**
     * @notice Set a sudo key for the account
     * @param _sudoKey The sudo key address to be set
     * @param _isValid Whether the key is to be set as valid or invalid
     */
    function _setSudoKeyStatus(address _sudoKey, bool _isValid) internal {
        Data storage data = getStorage();
        if (_sudoKey == address(0)) revert Error.NullAddress();
        if (data.sudoKeys[_sudoKey]) {
            if (_isValid) revert Error.KeyAlreadyValid();
            if (data.sudoKeysCounter == 1) revert Error.CannotRemoveLastKey();
            --data.sudoKeysCounter;
        } else {
            if (!_isValid) revert Error.KeyAlreadyInvalid();
            ++data.sudoKeysCounter;
        }
        emit SudoKeyStatusSet(_sudoKey, _isValid);
        data.sudoKeys[_sudoKey] = _isValid;
    }

    /**
     * @notice Consumes a nonce, marking it as used
     * @param _nonce The nonce to consume
     * @dev Reverts if nonce has already been consumed.
     */
    function _consumeNonce(bytes32 _nonce) internal returns (bool) {
        Data storage data = getStorage();
        if (data.nonces[_nonce]) revert Error.InvalidNonce(_nonce);
        emit NonceConsumed(_nonce);
        data.nonces[_nonce] = true;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library AccountConstants {
    uint256 public constant MAX_WITHDRAWAL_FEE = 50;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract RequestTypes {
    struct Request {
        address _address;
        address _address2;
        uint256 _uint256;
        bytes32 _nonce;
        uint32 _uint32;
        bool _bool;
        bytes4 _selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { RequestTypes } from "./RequestTypes.sol";

import { ERC2771Context } from "src/forwarder/ERC2771Context.sol";
import { Account } from "../storage/Account.sol";
import { EIP712 } from "../storage/EIP712.sol";
import { SecurityKeys } from "../storage/SecurityKeys.sol";

import { Error } from "src/libraries/Error.sol";

contract SecurityModifiers {
    using MessageHashUtils for bytes32;

    /*///////////////////////////////////////////////////////////////
                    			EVENTS / ERRORS
    ///////////////////////////////////////////////////////////////*/

    event PayloadProcessed(RequestTypes.Request request, bytes signature);

    /*///////////////////////////////////////////////////////////////
                            SECURITY CHECK MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Modifier to check if the request requires an sudo key.
     * @param _request The request data.
     * @param _signature The sudo key signature to process the transaction.
     */
    modifier requiresSudoKey(RequestTypes.Request calldata _request, bytes calldata _signature) {
        if (_request._selector != msg.sig) {
            revert Error.InvalidRequest();
        }
        bytes32 messageHash = EIP712._hashTypedDataV4(keccak256(abi.encode(SecurityKeys._SIGNATURE_REQUEST_TYPEHASH, _request)));

        address sudoKey = ECDSA.recover(messageHash, _signature);
        if (!SecurityKeys._isValidSudoKey(sudoKey)) {
            revert Error.InvalidKeySignature(sudoKey);
        }

        SecurityKeys._consumeNonce(_request._nonce);
        emit PayloadProcessed(_request, _signature);

        _;
    }

    /**
     * @notice Modifier to check if the sender is an sudo key.
     */
    modifier requiresSudoKeySender() {
        if (!SecurityKeys._isValidSudoKey(ERC2771Context._msgSender())) {
            revert Error.InvalidKeySignature(ERC2771Context._msgSender());
        }

        _;
    }

    /**
     * @notice Modifier to check if the sender is a sudo or operation key.
     * If not, it reverts with an error message.
     */
    modifier requiresAuthorizedOperationsParty() {
        address sender = ERC2771Context._msgSender();
        if (!SecurityKeys._isValidSudoKey(sender) && !SecurityKeys._isValidOperationKey(sender)) {
            revert Error.InvalidKeySignature(sender);
        }
        _;
    }

    /**
     * @notice Modifier to check if the sender is an sudo key, a recovery key or a trusted recovery keeper.
     * If not, it reverts with an error message.
     */
    modifier requiresAuthorizedRecoveryParty() {
        address sender = ERC2771Context._msgSender();
        if (
            !SecurityKeys._isValidSudoKey(sender) && !SecurityKeys._isValidRecoveryKey(sender)
                && !Account._infinexProtocolConfig().isTrustedRecoveryKeeper(sender)
        ) {
            revert Error.InvalidKeySignature(sender);
        }
        _;
    }

    /**
     * @notice Modifier to check if the sender is a trusted keeper for recovery.
     * If not, reverts with an error message.
     */
    modifier requiresTrustedRecoveryKeeper() {
        if (!Account._infinexProtocolConfig().isTrustedRecoveryKeeper(ERC2771Context._msgSender())) {
            revert Error.InvalidKeySignature(ERC2771Context._msgSender());
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// Originally sourced from OpenZeppelin Contracts (last updated v4.9.3) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.21;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Initializable } from "../Initializable.sol";

import { Error } from "src/libraries/Error.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
library ERC2771Context {
    event TrustedForwarderAdded(address forwarder);
    event TrustedForwarderRemoved(address forwarder);

    struct Data {
        EnumerableSet.AddressSet trustedForwarders;
    }

    function getStorage() internal pure returns (Data storage data) {
        bytes32 slot = keccak256(abi.encode("io.infinex.ERC2771Context"));
        assembly {
            data.slot := slot
        }
    }

    function initialize(address initialTrustedForwarder) internal {
        Initializable.initialize();

        EnumerableSet.add(getStorage().trustedForwarders, initialTrustedForwarder);
    }

    function isTrustedForwarder(address forwarder) internal view returns (bool) {
        return EnumerableSet.contains(getStorage().trustedForwarders, forwarder);
    }

    function trustedForwarder() internal view returns (address[] memory) {
        return EnumerableSet.values(getStorage().trustedForwarders);
    }

    function _addTrustedForwarder(address forwarder) internal returns (bool) {
        if (EnumerableSet.add(getStorage().trustedForwarders, forwarder)) {
            emit TrustedForwarderAdded(forwarder);
            return true;
        } else {
            revert Error.AlreadyExists();
        }
    }

    function _removeTrustedForwarder(address forwarder) internal returns (bool) {
        if (EnumerableSet.remove(getStorage().trustedForwarders, forwarder)) {
            emit TrustedForwarderRemoved(forwarder);
            return true;
        } else {
            revert Error.DoesNotExist();
        }
    }

    function _msgSender() internal view returns (address) {
        uint256 calldataLength = msg.data.length;
        uint256 contextSuffixLength = _contextSuffixLength();
        if (isTrustedForwarder(msg.sender) && calldataLength >= contextSuffixLength) {
            return address(bytes20(msg.data[calldataLength - contextSuffixLength:]));
        } else {
            return msg.sender;
        }
    }

    // slither-disable-start dead-code
    function _msgData() internal view returns (bytes calldata) {
        uint256 calldataLength = msg.data.length;
        uint256 contextSuffixLength = _contextSuffixLength();
        if (isTrustedForwarder(msg.sender) && calldataLength >= contextSuffixLength) {
            return msg.data[:calldataLength - contextSuffixLength];
        } else {
            return msg.data;
        }
    }

    /**
     * @dev ERC-2771 specifies the context as being a single address (20 bytes).
     */
    function _contextSuffixLength() internal pure returns (uint256) {
        return 20;
    }
    // slither-disable-end dead-code
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IAccountUtilsModule {
    event AccountInfinexProtocolBeaconImplementationUpgraded(address infinexProtocolConfigBeacon);

    event AccountSynthetixInformationBeaconUpgraded(address synthetixInformationBeacon);

    event AccountCircleBridgeParamsUpgraded(address circleBridge, address circleMinter, uint32 defaultDestinationCCTPDomain);

    event AccountWormholeCircleBridgeParamsUpgraded(address wormholeCircleBridge, uint16 defaultDestinationWormholeChainId);

    event AccountUSDCAddressUpgraded(address USDC);

    /*///////////////////////////////////////////////////////////////
                                    VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the Infinex Protocol Config
     * @return The Infinex Protocol Config Beacon
     */
    function infinexProtocolConfigBeacon() external view returns (address);

    /**
     * @notice Check if the provided operation key is valid
     * @param _operationKey The operation key to check
     * @return A boolean indicating if the key is valid
     */
    function isValidOperationKey(address _operationKey) external view returns (bool);

    /**
     * @notice Check if the provided sudo key is valid
     * @param _sudoKey The sudo key to check
     * @return A boolean indicating if the sudo key is valid
     */
    function isValidSudoKey(address _sudoKey) external view returns (bool);

    /**
     * @notice Check if the provided recovery key is valid
     * @param _recoveryKey The recovery key to check
     * @return A boolean indicating if the recovery key is valid
     */
    function isValidRecoveryKey(address _recoveryKey) external view returns (bool);

    /**
     * @notice Retrieves the Circle Bridge parameters.
     * @return The address of the circleBridge
     * @return The address of the minter.
     * @return The default circle bridge destination domain.
     */
    function getCircleBridgeParams() external view returns (address, address, uint32);

    /**
     * @notice Retrieves the wormhole circle bridge
     * @return The wormhole circle bridge address.
     */
    function getWormholeCircleBridge() external view returns (address);

    /**
     * @notice Retrieves the Wormhole Circle Bridge parameters.
     * @return The address of the wormholeCircleBridge
     * @return The address of the wormholeCircleBridge and the default defaultDestinationWormholeChainId
     */
    function getWormholeCircleBridgeParams() external view returns (address, uint16);

    /**
     * @notice Retrieves the USDC address.
     * @return The address of USDC
     */
    function getUSDCAddress() external view returns (address);

    /**
     * @notice Retrieves the maximum withdrawal fee.
     * @return The maximum withdrawal fee.
     */
    function getMaxWithdrawalFee() external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                                MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Upgrade to a new beacon implementation and updates any new parameters along with it
     * @param _newInfinexProtocolConfigBeacon The address of the new beacon
     * @dev requires the sender to be the sudo key
     * @dev Requires passing the new beacon address which matches the latest to ensure that the upgrade both
     * is as the user intended, and is to the latest beacon implementation. Prevents the user from opting in to a
     * specific version and upgrading to a later version that may have been deployed between the opt-in and the upgrade
     */
    function upgradeProtocolBeaconParameters(address _newInfinexProtocolConfigBeacon) external;

    /**
     * @notice Updates the parameters for the Circle Bridge to the latest from the Infinex Protocol Config Beacon.
     * Update is opt in to prevent malicious automatic updates.
     * @dev requires the sender to be the sudo key
     */
    function updateCircleBridgeParams() external;

    /**
     * @notice Updates the parameters for the Wormhole Circle Bridge to the latest from the Infinex Protocol Config Beacon.
     * Update is opt in to prevent malicious automatic updates.
     * @dev requires the sender to be the sudo key
     */
    function updateWormholeCircleBridge() external;

    /**
     * @notice Updates the USDC address from the Infinex Protocol Config Beacon.
     * Update is opt in to prevent malicious automatic updates.
     * @dev requires the sender to be the sudo key
     */
    function updateUSDCAddress() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IInfinexProtocolConfigBeacon
 * @notice Interface for the Infinex Protocol Config Beacon contract.
 */
interface IInfinexProtocolConfigBeacon {
    /*///////////////////////////////////////////////////////////////
    	 										STRUCTS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Struct containing the constructor arguments for the InfinexProtocolConfigBeacon contract
     * @param trustedForwarder Address of the trusted forwarder contract
     * @param latestAccountImplementation Address of the latest account implementation contract
     * @param initialProxyImplementation Address of the initial proxy implementation contract
     * @param revenuePool Address of the revenue pool contract
     * @param USDC Address of the USDC token contract
     * @param minimumUSDCBridgeAmount Minimum amount of USDC required to bridge
     * @param circleBridge Address of the Circle bridge contract
     * @param circleMinter Address of the Circle minter contract, used for checking the maximum bridge amount
     * @param wormholeCircleBridge Address of the Wormhole Circle bridge contract
     * @param defaultDestinationCCTPDomain the CCTP domain of the default destination chain.
     * @param defaultDestinationWormholeChainId the Wormhole chain id of the default destination chain.
     * @param solanaWalletSeed The salt used to generate the Solana account (fixed seed "wallet")
     * @param solanaFixedPDASeed The salt used to generate the PDA (Program Derived Address)
     * @param solanaWalletProgramAddress The Solana Wallet Program Address
     * @param solanaTokenMintAddress The Solana token mint address
     * @param solanaTokenProgramAddress The Solana token program address
     * @param solanaAssociatedTokenProgramAddress The Solana ATA program address
     */
    struct InfinexBeaconConstructorArgs {
        address trustedForwarder;
        address latestAccountImplementation;
        address initialProxyImplementation;
        address revenuePool;
        address USDC;
        uint256 minimumUSDCBridgeAmount;
        address circleBridge;
        address circleMinter;
        address wormholeCircleBridge;
        uint32 defaultDestinationCCTPDomain;
        uint16 defaultDestinationWormholeChainId;
        uint16[] supportedWormholeChainIds;
        uint32 solanaCCTPDestinationDomain;
        bytes solanaWalletSeed;
        bytes solanaFixedPDASeed;
        bytes32 solanaWalletProgramAddress;
        bytes32 solanaTokenMintAddress;
        bytes32 solanaTokenProgramAddress;
        bytes32 solanaAssociatedTokenProgramAddress;
    }

    /**
     * @notice Struct containing both Circle and Wormhole bridge configuration
     * @param minimumUSDCBridgeAmount Minimum amount of USDC required to bridge
     * @param circleBridge Address of the Circle bridge contract
     * @param circleMinter Address of the Circle minter contract, used for checking the maximum bridge amount
     * @param wormholeCircleBridge Address of the Wormhole Circle bridge contract
     * @param defaultDestinationCCTPDomain the CCTP domain of the default destination chain.
     * @param defaultDestinationWormholeChainId the Wormhole chain id of the default destination chain.
     * @dev Chain id is the official chain id for evm chains and documented one for non evm chains.
     */
    struct BridgeConfiguration {
        uint256 minimumUSDCBridgeAmount;
        address circleBridge;
        address circleMinter;
        address wormholeCircleBridge;
        uint32 defaultDestinationCCTPDomain;
        uint16 defaultDestinationWormholeChainId;
    }

    /**
     * @notice The addresses for implementations referenced by the beacon
     * @param initialProxyImplementation The initial proxy implementation address used for account creation to ensure identical cross chain addresses
     * @param latestAccountImplementation The latest account implementation address, used for account upgrades and new accounts
     * @param latestInfinexProtocolConfigBeacon The latest Infinex Protocol config beacon address, used for pointing account updates to the latest beacon
     */
    struct ImplementationAddresses {
        address initialProxyImplementation;
        address latestAccountImplementation;
        address latestInfinexProtocolConfigBeacon;
    }

    /**
     * @notice Struct containing the Solana configuration needed to verify addresses
     * @param walletSeed The salt used to generate the Solana account (fixed seed "wallet")
     * @param fixedPDASeed The salt used to generate the PDA (Program Derived Address)
     * @param walletProgramAddress The Solana Wallet Program Address
     * @param tokenMintAddress The Solana token mint address
     * @param tokenProgramAddress The Solana token address
     * @param associatedTokenProgramAddress The Solana ATA program address
     */
    struct SolanaConfiguration {
        bytes walletSeed;
        bytes fixedPDASeed;
        bytes32 walletProgramAddress;
        bytes32 tokenMintAddress;
        bytes32 tokenProgramAddress;
        bytes32 associatedTokenProgramAddress;
    }

    /*///////////////////////////////////////////////////////////////
    	 										EVENTS
    ///////////////////////////////////////////////////////////////*/

    event LatestAccountImplementationSet(address latestAccountImplementation);
    event InitialProxyImplementationSet(address initialProxyImplementation);
    event RevenuePoolSet(address revenuePool);
    event USDCAddressSet(address USDC);
    event CircleBridgeParamsSet(address circleBridge, address circleMinter, uint32 defaultDestinationCCTPDomain);
    event WormholeCircleBridgeParamsSet(address wormholeCircleBridge, uint16 defaultDestinationWormholeChainId);
    event LatestInfinexProtocolConfigBeaconSet(address latestInfinexProtocolConfigBeacon);
    event WithdrawalFeeUSDCSet(uint256 withdrawalFee);
    event FundsRecoveryStatusSet(bool status);
    event MinimumUSDCBridgeAmountSet(uint256 amount);
    event WormholeDestinationDomainSet(uint256 indexed chainId, uint16 destinationDomain);
    event CircleDestinationDomainSet(uint256 indexed chainId, uint32 destinationDomain);
    event TrustedRecoveryKeeperSet(address indexed trustedRecoveryKeeper, bool isTrusted);
    event SupportedWormholeChainIdSet(uint16 wormholeChainId, bool status);
    event SolanaCCTPDestinationDomainSet(uint32 solanaCCTPDestinationDomain);

    /*///////////////////////////////////////////////////////////////
    	 									VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the timestamp the beacon was deployed
     * @return The timestamp the beacon was deployed
     */
    function CREATED_AT() external view returns (uint256);

    /**
     * @notice Gets the trusted forwarder address
     * @return The address of the trusted forwarder
     */
    function TRUSTED_FORWARDER() external view returns (address);

    /**
     * @notice A platform wide feature flag to enable or disable funds recovery, false by default
     * @return True if funds recovery is active
     */
    function fundsRecoveryActive() external view returns (bool);

    /**
     * @notice Gets the revenue pool address
     * @return The address of the revenue pool
     */
    function revenuePool() external view returns (address);

    /**
     * @notice Gets the USDC amount to charge as withdrawal fee
     * @return The withdrawal fee in USDC's decimals
     */
    function withdrawalFeeUSDC() external view returns (uint256);

    /**
     * @notice Retrieves the USDC address.
     * @return The address of the USDC token
     */
    function USDC() external view returns (address);

    /*///////////////////////////////////////////////////////////////
    	 								VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieves supported wormhole chain ids.
     * @param _wormholeChainId the chain id to check
     * @return bool if the chain is supported or not.
     */
    function isSupportedWormholeChainId(uint16 _wormholeChainId) external view returns (bool);

    /**
     * @notice Retrieves the minimum USDC amount that can be bridged.
     * @return The minimum USDC bridge amount.
     */
    function getMinimumUSDCBridgeAmount() external view returns (uint256);

    /**
     * @notice Retrieves the Circle Bridge parameters.
     * @return circleBridge The address of the Circle Bridge contract.
     * @return circleMinter The address of the TokenMinter contract.
     * @return defaultDestinationCCTPDomain The CCTP domain of the default destination chain.
     */
    function getCircleBridgeParams()
        external
        view
        returns (address circleBridge, address circleMinter, uint32 defaultDestinationCCTPDomain);

    /**
     * @notice Retrieves the Circle Bridge address.
     * @return The address of the Circle Bridge contract.
     */
    function getCircleBridge() external view returns (address);

    /**
     * @notice Retrieves the Circle TokenMinter address.
     * @return The address of the Circle TokenMinter contract.
     */
    function getCircleMinter() external view returns (address);

    /**
     * @notice Retrieves the CCTP domain of the destination chain.
     * @return The CCTP domain of the default destination chain.
     */
    function getDefaultDestinationCCTPDomain() external view returns (uint32);

    /**
     * @notice Retrieves the parameters required for Wormhole bridging.
     * @return The address of the Wormhole Circle Bridge contract.
     * @return The default wormhole destination domain for the circle bridge contract.
     */
    function getWormholeCircleBridgeParams() external view returns (address, uint16);

    /**
     * @notice Retrieves the Wormhole Circle Bridge address.
     * @return The address of the Wormhole Circle Bridge contract.
     */
    function getWormholeCircleBridge() external view returns (address);

    /**
     * @notice Retrieves the Wormhole chain id for Base, or Ethereum Mainnet if deployed on Base.
     * @return The Wormhole chain id of the default destination chain.
     */
    function getDefaultDestinationWormholeChainId() external view returns (uint16);

    /**
     * @notice Retrieves the circle CCTP destination domain for solana.
     * @return The CCTP destination domain for solana.
     */
    function getSolanaCCTPDestinationDomain() external view returns (uint32);

    /**
     * @notice Gets the latest account implementation address.
     * @return The address of the latest account implementation.
     */
    function getLatestAccountImplementation() external view returns (address);

    /**
     * @notice Gets the initial proxy implementation address.
     * @return The address of the initial proxy implementation.
     */
    function getInitialProxyImplementation() external view returns (address);

    /**
     * @notice The latest Infinex Protocol config beacon address, used for pointing account updates to the latest beacon.
     * @return The address of the latest Infinex Protocol config beacon.
     */
    function getLatestInfinexProtocolConfigBeacon() external view returns (address);

    /**
     * @notice Checks if an address is a trusted recovery keeper.
     * @param _address The address to check.
     * @return True if the address is a trusted recovery keeper, false otherwise.
     */
    function isTrustedRecoveryKeeper(address _address) external view returns (bool);

    /**
     * @notice Returns the Solana configuration
     * @param walletSeed The salt used to generate the Solana account (fixed seed "wallet")
     * @param fixedPDASeed The salt used to generate the PDA (Program Derived Address)
     * @param walletProgramAddress The Solana Wallet Program Address
     * @param tokenMintAddress The Solana token mint address
     * @param tokenProgramAddress The Solana token program address
     * @param associatedTokenProgramAddress The Solana ATA program address
     */
    function getSolanaConfiguration()
        external
        view
        returns (
            bytes memory walletSeed,
            bytes memory fixedPDASeed,
            bytes32 walletProgramAddress,
            bytes32 tokenMintAddress,
            bytes32 tokenProgramAddress,
            bytes32 associatedTokenProgramAddress
        );

    /*///////////////////////////////////////////////////////////////
    	 							MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets or unsets a supported wormhole chain id.
     * @param _wormholeChainId the wormhole chain id to add or remove.
     * @param _status the status of the chain id.
     */
    function setSupportedWormholeChainId(uint16 _wormholeChainId, bool _status) external;

    /**
     * @notice Sets the solana CCTP destination domain
     * @param _solanaCCTPDestinationDomain the destination domain for circles CCTP USDC bridge.
     */
    function setSolanaCCTPDestinationDomain(uint32 _solanaCCTPDestinationDomain) external;

    /**
     * @notice Sets or unsets an address as a trusted recovery keeper.
     * @param _address The address to set or unset.
     * @param _isTrusted Boolean indicating whether to set or unset the address as a trusted recovery keeper.
     */
    function setTrustedRecoveryKeeper(address _address, bool _isTrusted) external;

    /**
     * @notice Sets the funds recovery flag to active.
     * @dev Initially only the owner can call this. After 90 days, it can be activated by anyone.
     */
    function setFundsRecoveryActive() external;

    /**
     * @notice Sets the revenue pool address.
     * @param _revenuePool The revenue pool address.
     */
    function setRevenuePool(address _revenuePool) external;

    /**
     * @notice Sets the USDC amount to charge as withdrawal fee.
     * @param _withdrawalFeeUSDC The withdrawal fee in USDC's decimals.
     */
    function setWithdrawalFeeUSDC(uint256 _withdrawalFeeUSDC) external;

    /**
     * @notice Sets the address of the USDC token contract.
     * @param _USDC The address of the USDC token contract.
     * @dev Only the contract owner can call this function.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setUSDCAddress(address _USDC) external;

    /**
     * @notice Sets the minimum USDC amount that can be bridged, in 6 decimals.
     * @param _amount The minimum USDC bridge amount.
     */
    function setMinimumUSDCBridgeAmount(uint256 _amount) external;

    /**
     * @notice Sets the parameters for Circle bridging.
     * @param _circleBridge The address of the Circle Bridge contract.
     * @param _circleMinter The address of the Circle TokenMinter contract.
     * @param _defaultDestinationCCTPDomain The CCTP domain of the default destination chain.
     * @dev Circle Destination Domain can be 0 - Ethereum.
     */
    function setCircleBridgeParams(address _circleBridge, address _circleMinter, uint32 _defaultDestinationCCTPDomain) external;

    /**
     * @notice Sets the parameters for Wormhole bridging.
     * @param _wormholeCircleBridge The address of the Wormhole Circle Bridge contract.
     * @param _defaultDestinationWormholeChainId The wormhole domain of the default destination chain.
     */
    function setWormholeCircleBridgeParams(address _wormholeCircleBridge, uint16 _defaultDestinationWormholeChainId) external;

    /**
     * @notice Sets the initial proxy implementation address.
     * @param _initialProxyImplementation The initial proxy implementation address.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setInitialProxyImplementation(address _initialProxyImplementation) external;

    /**
     * @notice Sets the latest account implementation address.
     * @param _latestAccountImplementation The latest account implementation address.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setLatestAccountImplementation(address _latestAccountImplementation) external;

    /**
     * @notice Sets the latest Infinex Protocol Config Beacon.
     * @param _latestInfinexProtocolConfigBeacon The address of the Infinex Protocol Config Beacon.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setLatestInfinexProtocolConfigBeacon(address _latestInfinexProtocolConfigBeacon) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library Error {
    /*///////////////////////////////////////////////////////////////
                                            GENERIC
    ///////////////////////////////////////////////////////////////*/

    error AlreadyExists();

    error DoesNotExist();

    error Unauthorized();

    error InvalidLength();

    error NotOwner();

    error InvalidWormholeChainId();

    /*///////////////////////////////////////////////////////////////
                                            ADDRESS
    ///////////////////////////////////////////////////////////////*/

    error ImplementationMismatch(address implementation, address latestImplementation);

    error InvalidWithdrawalAddress(address to);

    error NullAddress();

    error SameAddress();

    error InvalidSolanaAddress();

    error AddressAlreadySet();

    /*///////////////////////////////////////////////////////////////
                                    AMOUNT / BALANCE
    ///////////////////////////////////////////////////////////////*/

    error InsufficientBalance();

    error InsufficientWithdrawalAmount(uint256 amount);

    error InsufficientBalanceForFee(uint256 balance, uint256 fee);

    error InvalidNonce(bytes32 nonce);

    error ZeroValue();

    error AmountDeltaZeroValue();

    error DecimalsMoreThan18(uint256 decimals);

    error InsufficientBridgeAmount();

    error BridgeMaxAmountExceeded();

    /*///////////////////////////////////////////////////////////////
                                            ACCOUNT
    ///////////////////////////////////////////////////////////////*/

    error CreateAccountDisabled();

    error InvalidKeysForSalt();

    error PredictAddressDisabled();

    error FundsRecoveryActivationDeadlinePending();

    /*///////////////////////////////////////////////////////////////
                                        KEY MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    error InvalidRequest();

    error InvalidKeySignature(address from);

    error KeyAlreadyInvalid();

    error KeyAlreadyValid();

    error KeyNotFound();

    error CannotRemoveLastKey();

    /*///////////////////////////////////////////////////////////////
                                     GAS FEE REBATE
    ///////////////////////////////////////////////////////////////*/

    error InvalidDeductGasFunction(bytes4 sig);

    /*///////////////////////////////////////////////////////////////
                                FEATURE FLAGS
    ///////////////////////////////////////////////////////////////*/

    error FundsRecoveryNotActive();
}