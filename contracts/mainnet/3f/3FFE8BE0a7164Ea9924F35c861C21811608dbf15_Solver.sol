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
pragma solidity ^0.8.17;

interface IEIP712 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IEIP712} from "./IEIP712.sol";

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer is IEIP712 {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(
        address indexed owner,
        uint256 word,
        uint256 mask
    );

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(ERC20 token, address from, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(ERC20 token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(ERC20 token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// ----------------------------------------------------------- BASE SOCKET ORDER ----------------------------------------------------------- //

/**
 * @notice BasicInfo is basic information needed in the socket invariant to post an order.
 * @notice This is the very basic info needed in every order.
 * @param sender - address of the order creator.
 * @param inputToken - address of the token on source.
 * @param inputAmount - amount of the input token the user wants to sell.
 * @param deadline - timestamp till the order is valid.
 * @param nonce - unique number that cannot be repeated.
 */
struct BasicInfo {
    address sender;
    address inputToken;
    uint256 inputAmount;
    uint256 deadline; // till when is the order valid.
    uint256 nonce;
}

/**
 * @notice SocketOrder is the order against which the user is signing to interact with socket protocol.
 * @notice This order will be exposed to all the solvers in socket protocol.
 * @param info - Basic Info Struct from the order above.
 * @param receiver - address where the funds will be sent when fulfilled or the contract where the payload given will be executed.
 * @param outputToken - address of the token to be fulfilled with on the destination.
 * @param minOutputAmount - the absolute minimum amount of output token the user wants to buy.
 * @param fromChainId -  source chain id where the order is made.
 * @param toChainId -  destChainId where the order will be fulfilled.
 */
struct SocketOrder {
    BasicInfo info;
    address receiver;
    address outputToken;
    uint256 minOutputAmount;
    uint256 fromChainId;
    uint256 toChainId;
}

// ----------------------------------------------------------- RFQ ORDERS ----------------------------------------------------------- //

/**
 * @notice RFQ Order is the order being filled by a whitelisted RFQ Solver.
 * @param order - The base socket order against which the user signed.
 * @param promisedAmount - amount promised by the solver on the destination.
 * @param userSignature - signature of the user against the socket order.
 */
struct RFQOrder {
    SocketOrder order;
    uint256 promisedAmount;
    bytes userSignature;
}

/**
 * @notice Batch RFQ Order is the batch of rfq orders being submitted by an rfq solver.
 * @param settlementReceiver - address that will receive the user funds on the source side when order is settled.
 * @param orders - RFQ orders in the batch.
 * @param socketSignature - batch order signed by Socket so that the auction winner can only submit the orders won in auction.
 */
struct BatchRFQOrder {
    address settlementReceiver;
    RFQOrder[] orders;
    bytes socketSignature;
}

/**
 * @notice Fulfill RFQ Order is the order being fulfilled on the destiantion by any solver.
 * @param order - order submitted by the user on the source side.
 * @param amount - amount to fulfill the user order on the destination.
 */
struct FulfillRFQOrder {
    SocketOrder order;
    uint256 amount;
}

/**
 * @notice Batch Gateway Orders is the batch of gateway orders being submitted by the gateway solver.
 * @param info - Gateway orders in the batch.
 * @param settlementReceiver - address that will receive funds when an order is settled.
 * @param promisedAmount - amount promised by the solver.
 */
struct ExtractedRFQOrder {
    BasicInfo info;
    address settlementReceiver;
    uint256 promisedAmount;
    uint256 fulfillDeadline;
}

// ----------------------------------------------------------- GATEWAY ORDERS ----------------------------------------------------------- //

/**
 * @notice Gateway Order is the order being filled by a whitelisted Gateway Solver.
 * @notice This order will be routed through the socket gateway using an external bridge.
 * @param order - The base socket order against which the user signed.
 * @param gatewayValue - value to be sent to socket gateway if needed.
 * @param gatewayPayload - calldata supposed to be sent to to socket gateway for bridging.
 * @param userSignature - signature of the user against the socket order.
 */
struct GatewayOrder {
    SocketOrder order;
    uint256 gatewayValue;
    bytes gatewayPayload;
    bytes userSignature;
}

/**
 * @notice Batch Gateway Orders is the batch of gateway orders being submitted by the gateway solver.
 * @param orders - Gateway orders in the batch.
 * @param socketSignature - batch order signed by Socket so that the auction winner can only submit the orders won in auction.
 */
struct BatchGatewayOrder {
    GatewayOrder[] orders;
    bytes socketSignature;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error BatchAuthenticationFailed();
error OrderDeadlineNotMet();
error DuplicateOrderHash();
error MinOutputAmountNotMet();
error OnlyOwner();
error OnlyNominee();
error OrderAlreadyFulfilled();
error FulfillDeadlineNotMet();
error InvalidSenderForTheOrder();
error NonSocketMessageInbound();
error ExtractedOrderAlreadyUnlocked();
error WrongOutoutToken();
error PromisedAmountNotMet();
error FulfillmentChainInvalid();
error SocketGatewayExecutionFailed();
error SolverNotWhitelisted();
error InvalidGatewayInboundCaller();
error InvalidSolver();
error InvalidGatewaySolver();
error InvalidRFQSolver();
error OrderAlreadyPrefilled();
error InboundOrderNotFound();
error OrderAlreadyCompleted();
error OrderNotClaimable();
error NotGatewayExtractor();
error InvalidOrder();

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {IPlug} from "../interfaces/IPlug.sol";
import {ISocket} from "../interfaces/ISocket.sol";
import {Ownable} from "../utils/Ownable.sol";
import {BatchGatewayOrder, FulfillRFQOrder, BatchRFQOrder, GatewayOrder, RFQOrder, SocketOrder, BasicInfo, ExtractedRFQOrder} from "../common/SocketStructs.sol";
import {ISocketWhitelist} from "../interfaces/ISocketWhitelist.sol";
import {Permit2Lib} from "../lib/Permit2Lib.sol";
import {SocketOrderLib} from "../lib/SocketOrderLib.sol";
import {GatewayOrderLib} from "../lib/GatewayOrderLib.sol";
import {RFQOrderLib} from "../lib/RFQOrderLib.sol";
import {BatchAuthenticationFailed, InvalidOrder, FulfillmentChainInvalid, SocketGatewayExecutionFailed, InvalidGatewaySolver, InvalidRFQSolver, OrderDeadlineNotMet, InvalidSenderForTheOrder, DuplicateOrderHash, PromisedAmountNotMet, WrongOutoutToken, MinOutputAmountNotMet, OrderAlreadyFulfilled, FulfillDeadlineNotMet, NonSocketMessageInbound, ExtractedOrderAlreadyUnlocked} from "../errors/Errors.sol";
import {ISignatureTransfer} from "lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {RescueFundsLib} from "../lib/RescueFundsLib.sol";
import {BasicInfoLib} from "../lib/BasicInfoLib.sol";

/**
 * @title Socket Extractor
 * @notice Routes user order either through RFQ or Socket Gateway.
 * @dev User will sign against a Socket Order and whitelisted Solvers will execute bridging orders for users.
 * @dev Each solver is whitelisted by socket protocol. Every batch executed will be signed by the socket protocol.
 * @author reddyismav.
 */
contract SocketExtractor is IPlug, Ownable {
    using SafeTransferLib for ERC20;
    using SocketOrderLib for SocketOrder;
    using GatewayOrderLib for BatchGatewayOrder;
    using GatewayOrderLib for GatewayOrder;
    using RFQOrderLib for RFQOrder;
    using RFQOrderLib for BatchRFQOrder;
    using BasicInfoLib for BasicInfo;

    // -------------------------------------------------- ADDRESSES THAT NEED TO BE SET -------------------------------------------------- //

    /// @notice Permit2 Contract Address.
    ISignatureTransfer public immutable PERMIT2;

    /// @notice Sokcet Whitelist Contract Address
    ISocketWhitelist public immutable SOCKET_WHITELIST;

    /// @notice Socket DL address.
    address public immutable SOCKET;

    /// @notice Socket Gateway address.
    address public immutable SOCKET_GATEWAY;

    // -------------------------------------------------- RFQ EVENTS -------------------------------------------------- //

    /// @notice event to be emitted when funds are extracted from the user for an order.
    event RFQOrderExtracted(
        bytes32 orderHash,
        address sender,
        address inputToken,
        uint256 inputAmount,
        address receiver,
        address outputToken,
        uint256 minOutputAmount,
        uint256 toChainId
    );

    /// @notice event to be emitted when order is fulfilled by a solver.
    event RFQOrderFulfilled(
        bytes32 orderHash,
        address receiver,
        address outputToken,
        uint256 fromChainId,
        uint256 fulfilledAmount
    );

    /// @notice event to be emitted when user funds are unlocked and sent to the solver.
    event RFQOrderUnlocked(
        bytes32 orderHash,
        address inputToken,
        uint256 inputAmount,
        address settlementReceiver,
        uint256 promisedAmount,
        uint256 fulfilledAmount
    );

    /// @notice event to be emitted when the user withdraws funds against his order.
    event RFQOrderWithdrawn(
        bytes32 orderHash,
        address sender,
        address inputToken,
        uint256 inputAmount
    );

    // -------------------------------------------------- Gateway EVENTS -------------------------------------------------- //

    /// @notice event to be emitted when funds are extracted from the user for an order.
    event GatewayOrderExecuted(
        bytes32 orderHash,
        address sender,
        address inputToken,
        uint256 inputAmount,
        address receiver,
        address outputToken,
        uint256 minOutputAmount,
        uint256 toChainId
    );

    // -------------------------------------------------- CONSTRUCTOR -------------------------------------------------- //

    /**
     * @notice Constructor.
     * @param _socket address that can call inbound function on this contract.
     * @param _permit2Address address of the permit 2 contract.
     * @param _socketWhitelist address of the permit 2 contract.
     */
    constructor(
        address _socket,
        address _permit2Address,
        address _socketWhitelist,
        address _socketGateway,
        address _owner
    ) Ownable(_owner) {
        SOCKET = _socket;
        SOCKET_GATEWAY = _socketGateway;
        PERMIT2 = ISignatureTransfer(_permit2Address);
        SOCKET_WHITELIST = ISocketWhitelist(_socketWhitelist);
    }

    // -------------------------------------------------- MAPPINGS -------------------------------------------------- //

    /// @notice store details of all escrows stored on this extractor
    mapping(bytes32 => ExtractedRFQOrder) public extractedRfqOrders;

    /// @notice store if the order is created previously or not.
    mapping(bytes32 => bool) public disaptchedOrders;

    /// @notice store if the order is fulfilled previously or not.
    mapping(bytes32 => uint256) public fulfilledOrderAmountMap;

    // -------------------------------------------------- GATEWAY FUNCTION -------------------------------------------------- //

    /**
     * @dev this function is gated by socket signature.
     * @notice The winning solver will submit the batch signed by socket protocol for fulfillment.
     * @notice The batch must only contain Socket Gateway orders.
     * @notice Each order will have a permit2 signature signed by the user allowing this contract to pull funds.
     * @notice Order hash is generated and will be used as the unique identifier to map to an order.
     * @notice This order will be routed through an external bridge.
     * @param batchGateway the batch of gateway orders
     */
    function batchExtractAndBridge(
        BatchGatewayOrder calldata batchGateway
    ) external payable {
        // Check if the batch is valid.
        _isValidGatewayBatch(batchGateway);

        unchecked {
            for (uint i = 0; i < batchGateway.orders.length; i++) {
                // Return order hash if the order is valid.
                bytes32 orderHash = _isValidGatewayOrder(
                    batchGateway.orders[i]
                );

                // Transfer Funds from user using Permit2 Signature.
                _transferFundsForGateway(batchGateway.orders[i], orderHash);

                // Call Socket Gateway
                _callSocketGateway(
                    batchGateway.orders[i].gatewayValue,
                    batchGateway.orders[i].gatewayPayload,
                    batchGateway.orders[i].order.info.inputToken,
                    batchGateway.orders[i].order.info.inputAmount
                );

                // Mark the Gateway Order as dispatched.
                _markGatewayOrder(orderHash);

                // Emit the order hash for the event.
                emit GatewayOrderExecuted(
                    orderHash,
                    batchGateway.orders[i].order.info.sender,
                    batchGateway.orders[i].order.info.inputToken,
                    batchGateway.orders[i].order.info.inputAmount,
                    batchGateway.orders[i].order.receiver,
                    batchGateway.orders[i].order.outputToken,
                    batchGateway.orders[i].order.minOutputAmount,
                    batchGateway.orders[i].order.toChainId
                );
            }
        }
    }

    // -------------------------------------------------- RFQ FUNCTIONS -------------------------------------------------- //

    /**
     * @dev this function is gated by socket signature.
     * @notice The winning solver will submit the batch signed by socket protocol for fulfillment.
     * @notice The batch must only contain RFQ orders.
     * @notice Each order will have a permit2 signature signed by the user allowing this contract to pull funds.
     * @notice Order hash is generated and will be used as the unique identifier to unlock user funds after solver fills the order.
     * @notice User can unlock funds after the fulfillment deadline if the order is still unfulfilled.
     * @param batchRfq the batch of orders getting submitted for fulfillment.
     */
    function batchExtractRFQ(BatchRFQOrder calldata batchRfq) external payable {
        // Check if the batch is valid.
        _isValidRFQBatch(batchRfq);

        // Unchecked loop on batch iterating rfq orders.
        unchecked {
            for (uint i = 0; i < batchRfq.orders.length; i++) {
                // Return order hash if the order is valid.
                bytes32 orderHash = _isValidRFQOrder(batchRfq.orders[i]);

                // Transfer Funds from user using Permit2 Signature.
                _transferFundsForRFQ(batchRfq.orders[i], orderHash);

                // Save the RFQ Order against the hash.
                _saveRFQOrder(
                    batchRfq.orders[i],
                    orderHash,
                    batchRfq.settlementReceiver
                );

                // Emit the order hash for the event.
                emit RFQOrderExtracted(
                    orderHash,
                    batchRfq.orders[i].order.info.sender,
                    batchRfq.orders[i].order.info.inputToken,
                    batchRfq.orders[i].order.info.inputAmount,
                    batchRfq.orders[i].order.receiver,
                    batchRfq.orders[i].order.outputToken,
                    batchRfq.orders[i].order.minOutputAmount,
                    batchRfq.orders[i].order.toChainId
                );
            }
        }
    }

    /**
     * @dev this function will be called by the solver to fulfill RFQ Orders pulled on the source side.
     * @notice Each order will have amount that will be disbursed to the receiver.
     * @notice Order hash is generated and will be used as the unique identifier to unlock user funds on the source chain.
     * @notice If the order fulfillment is wrong then the solver will lose money as the user funds will not be unlocked on the other side.
     * @notice User can unlock funds after the fulfillment deadline if the order is still unfulfilled on the source side if the message does not reach before fulfillment deadline.
     * @notice Solver when pulling funds on the source side gives a settlement receiver, this receiver will get the funds when order is settled on the source side.
     * @param fulfillOrders array of orders to be fulfilled.
     */
    function fulfillBatchRFQ(
        FulfillRFQOrder[] calldata fulfillOrders
    ) external payable {
        // Unchecked loop on fulfill orders array
        unchecked {
            for (uint i = 0; i < fulfillOrders.length; i++) {
                // Check if the toChainId in the order matches the block chainId.
                if (block.chainid != fulfillOrders[i].order.toChainId)
                    revert FulfillmentChainInvalid();

                // Create the order hash from the order info
                bytes32 orderHash = fulfillOrders[i].order.hash();

                // Check if the order is already fulfilled.
                if (fulfilledOrderAmountMap[orderHash] > 0)
                    revert OrderAlreadyFulfilled();

                // Get the solver promised amount for the user from the solver
                // The solver promised amount should be equal or more than the promised amount on the source side.
                ERC20(fulfillOrders[i].order.outputToken).safeTransferFrom(
                    msg.sender,
                    fulfillOrders[i].order.receiver,
                    fulfillOrders[i].amount
                );

                // Save fulfilled order
                fulfilledOrderAmountMap[orderHash] = fulfillOrders[i].amount;

                // emit event
                emit RFQOrderFulfilled(
                    orderHash,
                    fulfillOrders[i].order.receiver,
                    fulfillOrders[i].order.outputToken,
                    fulfillOrders[i].order.fromChainId,
                    fulfillOrders[i].amount
                );
            }
        }
    }

    /**
     * @dev this function can be called by anyone to send message back to source chain.
     * @notice Each order hash will have an amount against it.
     * @notice Array of order hashes and array of amounts will be sent back to the source chain and will be settled against.
     * @param orderHashes array of order hashes that were fulfilled on destination domain.
     * @param msgValue value being send to DL as fees.
     * @param destGasLimit gas limit to be used on the destination where message has to be executed.
     * @param srcChainId chainId of the destination where the message has to be executed.
     */
    function settleRFQOrders(
        bytes32[] calldata orderHashes,
        uint256 msgValue,
        uint256 destGasLimit,
        uint256 srcChainId
    ) external payable {
        uint256 length = orderHashes.length;
        uint256[] memory fulfillAmounts = new uint256[](length);

        unchecked {
            for (uint i = 0; i < length; i++) {
                // Get amount fulfilled for the order.
                uint256 amount = fulfilledOrderAmountMap[orderHashes[i]];

                // Check if the amount is greater than 0.
                if (amount > 0) {
                    fulfillAmounts[i] = amount;
                } else {
                    revert InvalidOrder();
                }
            }
        }

        _outbound(
            uint32(srcChainId),
            destGasLimit,
            msgValue,
            bytes32(0),
            bytes32(0),
            abi.encode(orderHashes, fulfillAmounts)
        );
    }

    /**
     * @notice User can withdraw funds if the fulfillment deadline has passed for an extracted rfq order.
     * @param orderHash order hash of the order to withdraw funds.
     */
    function withdrawRFQFunds(bytes32 orderHash) external payable {
        // Get the order against the order hash.
        ExtractedRFQOrder memory rfqOrder = extractedRfqOrders[orderHash];

        // Check if the fulfillDeadline has passed.
        if (block.timestamp < rfqOrder.fulfillDeadline)
            revert FulfillDeadlineNotMet();

        // Transfer funds to the user(sender in the order)
        ERC20(rfqOrder.info.inputToken).safeTransfer(
            rfqOrder.info.sender,
            rfqOrder.info.inputAmount
        );

        // Remove the orderHash from the extractedOrders list after releasing funds to the solver.
        delete extractedRfqOrders[orderHash];
        delete disaptchedOrders[orderHash];

        // Emit event when the user withdraws funds against the order.
        emit RFQOrderWithdrawn(
            orderHash,
            rfqOrder.info.sender,
            rfqOrder.info.inputToken,
            rfqOrder.info.inputAmount
        );
    }

    // -------------------------------------------------- GATEWAY RELATED INTERNAL FUNCTIONS -------------------------------------------------- //

    /**
     * @dev checks the validity of the gateway batch being submitted.
     * @notice Reverts if the msg sender is not a whitelisted solver.
     * @notice Reverts if the socket signature is not authenticated.
     * @param batchGateway batch of gateway orders.
     */
    function _isValidGatewayBatch(
        BatchGatewayOrder calldata batchGateway
    ) internal view {
        // Check if socket protocol has signed against this order.
        if (
            !SOCKET_WHITELIST.isSocketApproved(
                batchGateway.hashBatch(),
                batchGateway.socketSignature
            )
        ) revert BatchAuthenticationFailed();

        if (!SOCKET_WHITELIST.isGatewaySolver(msg.sender))
            revert InvalidGatewaySolver();
    }

    /**
     * @dev checks the validity of the gateway order.
     * @notice Reverts if any of the checks below are not met.
     * @notice Returns the order hash
     * @param gatewayOrder gateway order.
     */
    function _isValidGatewayOrder(
        GatewayOrder calldata gatewayOrder
    ) internal view returns (bytes32 orderHash) {
        // Check if the order deadline is met.
        if (block.timestamp >= gatewayOrder.order.info.deadline)
            revert OrderDeadlineNotMet();

        // Create the order hash, order hash will be recreated on the fulfillment function.
        // This hash is solely responsible for unlocking user funds for the solver.
        orderHash = gatewayOrder.order.hash();

        // Check is someone is trying to submit the same order again.
        if (disaptchedOrders[orderHash]) revert DuplicateOrderHash();
    }

    /**
     * @dev transfer funds from the user to the contract using Permit 2.
     * @param gatewayOrder gateway order.
     * @param orderHash hash of the order signed by the user.
     */
    function _transferFundsForGateway(
        GatewayOrder calldata gatewayOrder,
        bytes32 orderHash
    ) internal {
        // Permit2 Transfer From User to this contract.
        PERMIT2.permitWitnessTransferFrom(
            Permit2Lib.toPermit(gatewayOrder.order.info),
            Permit2Lib.transferDetails(gatewayOrder.order.info, address(this)),
            gatewayOrder.order.info.sender,
            orderHash,
            SocketOrderLib.PERMIT2_ORDER_TYPE,
            gatewayOrder.userSignature
        );
    }

    /**
     * @dev function that calls gateway to bridge funds.
     * @param msgValue value to send to socket gateway.
     * @param payload calldata to send to socket gateway.
     * @param token token address that is being bridged. (used in approval)
     * @param amount amount to bridge. (used in approval)
     */
    function _callSocketGateway(
        uint256 msgValue,
        bytes calldata payload,
        address token,
        uint256 amount
    ) internal {
        // Approve Gateway For Using funds from the gateway extractor
        ERC20(token).approve(SOCKET_GATEWAY, amount);

        // Call Socket Gateway to bridge funds.
        (bool success, ) = SOCKET_GATEWAY.call{value: msgValue}(payload);

        // Revert if any of the socket gateway execution fails.
        if (!success) revert SocketGatewayExecutionFailed();
    }

    /**
     * @dev mark the order hash as dispatched.
     * @param orderHash hash of the order signed by the user.
     */
    function _markGatewayOrder(bytes32 orderHash) internal {
        // Store the Order Extracted to mark it as active.
        disaptchedOrders[orderHash] = true;
    }

    // -------------------------------------------------- RFQ RELATED INTERNAL FUNCTIONS -------------------------------------------------- //

    /**
     * @dev checks the validity of the batch being submitted.
     * @notice Reverts if the msg sender is not a whitelisted solver.
     * @notice Reverts if the socket signature is not authenticated.
     * @param batchRfq batch of rfq orders.
     */
    function _isValidRFQBatch(BatchRFQOrder calldata batchRfq) internal view {
        // Check if socket protocol has signed against this order.
        if (
            !SOCKET_WHITELIST.isSocketApproved(
                batchRfq.hashBatch(),
                batchRfq.socketSignature
            )
        ) revert BatchAuthenticationFailed();

        if (!SOCKET_WHITELIST.isRFQSolver(msg.sender))
            revert InvalidRFQSolver();
    }

    /**
     * @dev checks the validity of the rfq order.
     * @notice Reverts if any of the checks below are not met.
     * @notice Returns the order hash
     * @param rfqOrder rfq order.
     */
    function _isValidRFQOrder(
        RFQOrder calldata rfqOrder
    ) internal view returns (bytes32 orderHash) {
        // Check if the order deadline is met.
        if (block.timestamp >= rfqOrder.order.info.deadline)
            revert OrderDeadlineNotMet();

        // Check if the solver promised amount is less than the output amount and revert.
        if (rfqOrder.promisedAmount < rfqOrder.order.minOutputAmount)
            revert MinOutputAmountNotMet();

        // Create the order hash, order hash will be recreated on the fulfillment function.
        // This hash is solely responsible for unlocking user funds for the solver.
        orderHash = rfqOrder.order.hash();

        // Check is someone is trying to submit the same order again.
        if (disaptchedOrders[orderHash]) revert DuplicateOrderHash();
    }

    /**
     * @dev transfer funds from the user to the contract using Permit 2.
     * @param rfqOrder rfq order.
     * @param orderHash hash of the order signed by the user.
     */
    function _transferFundsForRFQ(
        RFQOrder calldata rfqOrder,
        bytes32 orderHash
    ) internal {
        // Permit2 Transfer From User to this contract.
        PERMIT2.permitWitnessTransferFrom(
            Permit2Lib.toPermit(rfqOrder.order.info),
            Permit2Lib.transferDetails(rfqOrder.order.info, address(this)),
            rfqOrder.order.info.sender,
            orderHash,
            SocketOrderLib.PERMIT2_ORDER_TYPE,
            rfqOrder.userSignature
        );
    }

    /**
     * @dev saved the rfq order in rfq order mapping.
     * @param rfqOrder rfq order.
     * @param orderHash hash of the order signed by the user.
     * @param settlementReceiver address that will receive funds when an order is settled.
     */
    function _saveRFQOrder(
        RFQOrder calldata rfqOrder,
        bytes32 orderHash,
        address settlementReceiver
    ) internal {
        // Store the Order Extracted against the order hash.
        extractedRfqOrders[orderHash] = ExtractedRFQOrder(
            rfqOrder.order.info,
            settlementReceiver,
            rfqOrder.promisedAmount,
            block.timestamp + 86400 // 24 hours fulfill deadline. Temporary fulfill deadline.
        );
        // Store the Order Extracted to mark it as active.
        disaptchedOrders[orderHash] = true;
    }

    /**
     * @dev saved the rfq order in rfq order mapping.
     * @param orderHash hash of the order signed by the user.
     * @param fulfilledAmount amount fulfilled on the destination.
     */
    function _settleOrder(bytes32 orderHash, uint256 fulfilledAmount) internal {
        // Check if the order hash is already unlocked.
        if (extractedRfqOrders[orderHash].promisedAmount == 0)
            revert ExtractedOrderAlreadyUnlocked();

        // Get the Extracted Order from storage.
        ExtractedRFQOrder memory rfqOrder = extractedRfqOrders[orderHash];

        // Check if the solver fulfilledAmount is not less than what was promised.
        if (fulfilledAmount < rfqOrder.promisedAmount)
            revert PromisedAmountNotMet();

        // Check if the order is under fulfillDeadline
        if (block.timestamp > rfqOrder.fulfillDeadline)
            revert FulfillDeadlineNotMet();

        // Release User funds to the solver against that order.
        ERC20(rfqOrder.info.inputToken).safeTransfer(
            rfqOrder.settlementReceiver,
            rfqOrder.info.inputAmount
        );

        // Remove the orderHash from the extractedOrders list after releasing funds to the solver.
        delete disaptchedOrders[orderHash];
        delete extractedRfqOrders[orderHash];

        // Emit event when socket protocol releases extracted user funds to the solver.
        emit RFQOrderUnlocked(
            orderHash,
            rfqOrder.info.inputToken,
            rfqOrder.info.inputAmount,
            rfqOrder.settlementReceiver,
            rfqOrder.promisedAmount,
            fulfilledAmount
        );
    }

    // --------------------------------------------------  -------------------------------------------------- //

    // -------------------------------------------------- SOCKET DATA LAYER FUNCTIONS -------------------------------------------------- //

    function _connect(
        uint32 remoteChainSlug_,
        address remotePlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard
    ) external onlyOwner {
        ISocket(SOCKET).connect(
            remoteChainSlug_,
            remotePlug_,
            inboundSwitchboard_,
            outboundSwitchboard
        );
    }

    /**
     * @notice Function to send the message through socket data layer to the destination chain.
     * @param targetChain_ the destination chain slug to send the message to.
     * @param minMsgGasLimit_ gasLimit to use to execute the message on the destination chain.
     * @param msgValue socket data layer fees to send a message.
     * @param executionParams_ execution params.
     * @param transmissionParams_ transmission params.
     * @param payload_ payload is the encoded message that the inbound will receive.
     */
    function _outbound(
        uint32 targetChain_,
        uint256 minMsgGasLimit_,
        uint256 msgValue,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        bytes memory payload_
    ) internal {
        ISocket(SOCKET).outbound{value: msgValue}(
            targetChain_,
            minMsgGasLimit_,
            executionParams_,
            transmissionParams_,
            payload_
        );
    }

    /**
     * @notice Message received from socket DL to unlock user funds.
     * @notice Message has to be received before an orders fulfillment deadline. Solver will not unlock user funds after this deadline.
     * @param payload_ payload to be executed.
     */
    function inbound(uint32, bytes calldata payload_) external payable {
        // Check if the message is coming from the socket configured address.
        if (msg.sender != SOCKET) revert NonSocketMessageInbound();

        // Decode the payload sent after fulfillment from the other side.
        (bytes32[] memory orderHashes, uint256[] memory fulfilledAmounts) = abi
            .decode(payload_, (bytes32[], uint256[]));

        unchecked {
            for (uint i = 0; i < orderHashes.length; i++) {
                _settleOrder(orderHashes[i], fulfilledAmounts[i]);
            }
        }
    }

    // --------------------------------------------------  -------------------------------------------------- //

    // -------------------------------------------------- ADMIN FUNCTION -------------------------------------------------- //

    /**
     * @notice Rescues funds from the contract if they are locked by mistake.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address where rescued tokens need to be sent.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }

    // Gateway Batch Hash
    function getGatewayBatchHash(
        BatchGatewayOrder memory batchGateway
    ) external pure returns (bytes32 batchHash) {
        batchHash = batchGateway.hashBatch();
        return batchHash;
    }

    // RFQ Batch Hash.
    function getRFQBatchHash(
        BatchRFQOrder memory batchRfq
    ) external pure returns (bytes32 batchHash) {
        batchHash = batchRfq.hashBatch();
        return batchHash;
    }

    // Hash an RFQ order.
    function getRFQOrderHash(
        RFQOrder memory rfqOrder
    ) external pure returns (bytes32 rfqOrderHash) {
        rfqOrderHash = rfqOrder.hash();
    }

    // Hash a gateway order.
    function getGatewayOrderHash(
        GatewayOrder memory gatewayOrder
    ) external pure returns (bytes32 gatewayOrderHash) {
        gatewayOrderHash = gatewayOrder.hash();
    }

    // Get Socket Order Hash
    function getSocketOrderHash(
        SocketOrder memory order
    ) external pure returns (bytes32 orderHash) {
        orderHash = order.hash();
    }

    // Get Basic Info Hash
    function getBasicInfoHash(
        BasicInfo memory info
    ) external pure returns (bytes32 infoHash) {
        infoHash = info.hash();
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @title IPlug
 * @notice Interface for a plug contract that executes the message received from a source chain.
 */
interface IPlug {
    /**
     * @dev this should be only executable by socket
     * @notice executes the message received from source chain
     * @notice It is expected to have original sender checks in the destination plugs using payload
     * @param srcChainSlug_ chain slug of source
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(
        uint32 srcChainSlug_,
        bytes calldata payload_
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @title ISocket
 * @notice An interface for a cross-chain communication contract
 * @dev This interface provides methods for transmitting and executing messages between chains,
 * connecting a plug to a remote chain and setting up switchboards for the message transmission
 * This interface also emits events for important operations such as message transmission, execution status,
 * and plug connection
 */
interface ISocket {
    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with capacitor
     * @param remoteChainSlug_ the remote chain slug
     * @param minMsgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint32 remoteChainSlug_,
        uint256 minMsgGasLimit_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        bytes calldata payload_
    ) external payable returns (bytes32 msgId);

    /**
     * @notice sets the config specific to the plug
     * @param siblingChainSlug_ the sibling chain slug
     * @param siblingPlug_ address of plug present at sibling chain to call inbound
     * @param inboundSwitchboard_ the address of switchboard to use for receiving messages
     * @param outboundSwitchboard_ the address of switchboard to use for sending messages
     */
    function connect(
        uint32 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external;

    event PlugConnected(
        address plug,
        uint32 siblingChainSlug,
        address siblingPlug,
        address inboundSwitchboard,
        address outboundSwitchboard,
        address capacitor,
        address decapacitor
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {BatchGatewayOrder, FulfillRFQOrder, BatchRFQOrder} from "../common/SocketStructs.sol";

/**
 * @title ISocketMarketplace
 * @notice Interface for Socket Marketplace Contract.
 * @author reddyismav.
 */
interface ISocketMarketplace {
    // Gateway extract function that sends funds through gateway.
    function batchExtractAndBridge(
        BatchGatewayOrder calldata batchGateway
    ) external payable;

    // RFQ Extract function that uses RFQ order system off chain.
    function batchExtractRFQ(BatchRFQOrder calldata batchRfq) external payable;

    // Fulfill Batch RFQ that fulfills user orders
    function fulfillBatchRFQ(
        FulfillRFQOrder[] calldata fulfillOrders
    ) external payable;

    // Settle RFQ Orders.
    function settleRFQOrders(
        bytes32[] calldata orderHashes,
        uint256 msgValue,
        uint256 destGasLimit,
        uint256 srcChainId
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**
 * @title ISocketWhitelist
 * @notice Interface for Socket Whitelisting Contract.
 * @author reddyismav.
 */
interface ISocketWhitelist {
    // --------------------------------------------------------- RFQ SOLVERS --------------------------------------------------- //
    function addRFQSolver(address _solverAddress) external;

    function disableRFQSolver(address _solverAddress) external;

    function isRFQSolver(address _solverAddress) external view returns (bool);

    // --------------------------------------------------------- GATEWAY SOLVERS --------------------------------------------------- //
    function addGatewaySolver(address _solverAddress) external;

    function disableGatewaySolver(address _solverAddress) external;

    function isGatewaySolver(
        address _solverAddress
    ) external view returns (bool);

    // --------------------------------------------------------- SOCKET SIGNERS --------------------------------------------------- //
    function addSignerAddress(address _signerAddress) external;

    function disableSignerAddress(address _signerAddress) external;

    function isSigner(address _signerAddress) external view returns (bool);

    function isSocketApproved(
        bytes32 _messageHash,
        bytes calldata _sig
    ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Library to authenticate the signer address.
library AuthenticationLib {
    /// @notice authenticate a message hash signed by socketLabs
    /// @param messageHash hash of the message
    /// @param signature signature of the message
    /// @return true if signature is valid
    function authenticate(
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature);
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {BasicInfo} from "../common/SocketStructs.sol";

/// @notice helpers for handling OrderInfo objects
library BasicInfoLib {
    bytes internal constant BASIC_INFO_TYPE =
        "BasicInfo(address sender,address inputToken,uint256 inputAmount,uint256 nonce,uint256 deadline)";
    bytes32 internal constant ORDER_INFO_TYPE_HASH = keccak256(BASIC_INFO_TYPE);

    /// @notice hash an OrderInfo object
    /// @param info The OrderInfo object to hash
    function hash(BasicInfo memory info) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_INFO_TYPE_HASH,
                    info.sender,
                    info.inputToken,
                    info.inputAmount,
                    info.nonce,
                    info.deadline
                )
            );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {SocketOrder, GatewayOrder, BatchGatewayOrder} from "../common/SocketStructs.sol";
import {SocketOrderLib} from "./SocketOrderLib.sol";

/// @notice helpers for handling Gateway Order objects
library GatewayOrderLib {
    using SocketOrderLib for SocketOrder;

    // Gateway Order Type.
    bytes internal constant GATEWAY_ORDER_TYPE =
        abi.encodePacked(
            "GatewayOrder(",
            "SocketOrder order,",
            "uint256 gatewayValue,",
            "bytes gatewayPayload,",
            "bytes userSignature)"
        );

    // Main Order Type.
    bytes internal constant ORDER_TYPE =
        abi.encodePacked(GATEWAY_ORDER_TYPE, SocketOrderLib.SOCKET_ORDER_TYPE);

    // Keccak Hash of Main Order Type.
    bytes32 internal constant ORDER_TYPE_HASH = keccak256(ORDER_TYPE);

    /// @notice hash a gateway order
    /// @param gatewayOrder gateway order to be hashed
    function hash(
        GatewayOrder memory gatewayOrder
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPE_HASH,
                    gatewayOrder.order.hash(),
                    gatewayOrder.gatewayValue,
                    keccak256(gatewayOrder.gatewayPayload),
                    keccak256(gatewayOrder.userSignature)
                )
            );
    }

    /// @notice hash a batch of gateway orders
    /// @param batchOrder batch of gateway orders to be hashed
    function hashBatch(
        BatchGatewayOrder memory batchOrder
    ) internal pure returns (bytes32) {
        unchecked {
            bytes32 outputHash = keccak256(
                "GatewayOrder(SocketOrder order,uint256 gatewayValue,bytes gatewayPayload,bytes userSignature)"
            );
            for (uint256 i = 0; i < batchOrder.orders.length; i++) {
                outputHash = keccak256(
                    abi.encode(outputHash, hash(batchOrder.orders[i]))
                );
            }
            return outputHash;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import {ISignatureTransfer} from "lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {BasicInfo} from "../common/SocketStructs.sol";

// Library to get Permit 2 related data.
library Permit2Lib {
    string public constant TOKEN_PERMISSIONS_TYPE =
        "TokenPermissions(address token,uint256 amount)";

    function toPermit(
        BasicInfo memory info
    ) internal pure returns (ISignatureTransfer.PermitTransferFrom memory) {
        return
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({
                    token: info.inputToken,
                    amount: info.inputAmount
                }),
                nonce: info.nonce,
                deadline: info.deadline
            });
    }

    function transferDetails(
        BasicInfo memory info,
        address spender
    )
        internal
        pure
        returns (ISignatureTransfer.SignatureTransferDetails memory)
    {
        return
            ISignatureTransfer.SignatureTransferDetails({
                to: spender,
                requestedAmount: info.inputAmount
            });
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "lib/solmate/src/utils/SafeTransferLib.sol";

error ZeroAddress();

/**
 * @title RescueFundsLib
 * @dev A library that provides a function to rescue funds from a contract.
 */

library RescueFundsLib {
    /**
     * @dev The address used to identify ETH.
     */
    address public constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /**
     * @dev thrown when the given token address don't have any code
     */
    error InvalidTokenAddress();

    /**
     * @dev Rescues funds from a contract.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address of the user.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) internal {
        if (rescueTo_ == address(0)) revert ZeroAddress();

        if (token_ == ETH_ADDRESS) {
            SafeTransferLib.safeTransferETH(rescueTo_, amount_);
        } else {
            if (token_.code.length == 0) revert InvalidTokenAddress();
            SafeTransferLib.safeTransfer(ERC20(token_), rescueTo_, amount_);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {SocketOrder, RFQOrder, BatchRFQOrder} from "../common/SocketStructs.sol";
import {SocketOrderLib} from "./SocketOrderLib.sol";

/// @notice helpers for handling RFQ Order objects
library RFQOrderLib {
    using SocketOrderLib for SocketOrder;

    // RFQ Order Type.
    bytes internal constant RFQ_ORDER_TYPE =
        abi.encodePacked(
            "RFQOrder(",
            "SocketOrder order,",
            "uint256 promisedAmount,",
            "bytes userSignature)"
        );

    // Main Order Type.
    bytes internal constant ORDER_TYPE =
        abi.encodePacked(RFQ_ORDER_TYPE, SocketOrderLib.SOCKET_ORDER_TYPE);

    // Keccak Hash of Main Order Type.
    bytes32 internal constant ORDER_TYPE_HASH = keccak256(ORDER_TYPE);

    /// @notice hash a rfq order
    /// @param rfqOrder rfq order to be hashed
    function hash(RFQOrder memory rfqOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPE_HASH,
                    rfqOrder.order.hash(),
                    rfqOrder.promisedAmount,
                    keccak256(rfqOrder.userSignature)
                )
            );
    }

    /// @notice hash a batch of rfq orders
    /// @param batchOrder batch of rfq orders to be hashed
    function hashBatch(
        BatchRFQOrder memory batchOrder
    ) internal pure returns (bytes32) {
        unchecked {
            bytes32 outputHash = keccak256(
                "RFQOrder(SocketOrder order,uint256 promisedAmount,bytes userSignature)"
            );
            for (uint256 i = 0; i < batchOrder.orders.length; i++) {
                outputHash = keccak256(
                    abi.encode(outputHash, hash(batchOrder.orders[i]))
                );
            }

            return outputHash;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {BasicInfo, SocketOrder} from "../common/SocketStructs.sol";
import {BasicInfoLib} from "./BasicInfoLib.sol";
import {Permit2Lib} from "./Permit2Lib.sol";

/// @notice helpers for handling OrderInfo objects
library SocketOrderLib {
    // All hashes and encoding done to match EIP 712.

    using BasicInfoLib for BasicInfo;

    // Socket Order Type.
    bytes internal constant SOCKET_ORDER_TYPE =
        abi.encodePacked(
            "SocketOrder(",
            "BasicInfo info,",
            "address receiver,",
            "address outputToken,",
            "uint256 minOutputAmount,",
            "uint256 fromChainId,",
            "uint256 toChainId)"
        );

    // Main Order Type.
    bytes internal constant ORDER_TYPE =
        abi.encodePacked(SOCKET_ORDER_TYPE, BasicInfoLib.BASIC_INFO_TYPE);

    // Keccak Hash of Main Order Type.
    bytes32 internal constant ORDER_TYPE_HASH = keccak256(ORDER_TYPE);

    // Permit 2 Witness Order Type.
    string internal constant PERMIT2_ORDER_TYPE =
        string(
            abi.encodePacked(
                "SocketOrder witness)",
                abi.encodePacked(
                    BasicInfoLib.BASIC_INFO_TYPE,
                    SOCKET_ORDER_TYPE
                ),
                Permit2Lib.TOKEN_PERMISSIONS_TYPE
            )
        );

    /// @notice hash Socket Order.
    /// @param order Socket Order
    function hash(SocketOrder memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPE_HASH,
                    order.info.hash(),
                    order.receiver,
                    order.outputToken,
                    order.minOutputAmount,
                    order.fromChainId,
                    order.toChainId
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {ISocketMarketplace} from "../interfaces/ISocketMarketPlace.sol";
import {Ownable} from "../utils/Ownable.sol";
import {RescueFundsLib} from "../lib/RescueFundsLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract Solver is Ownable {
    using SafeTransferLib for ERC20;
    // -------------------------------------------------- ERRORS AND VARIABLES -------------------------------------------------- //

    error SignerMismatch();
    error InvalidNonce();
    error SocketExtractorFailed();

    // nonce usage data
    mapping(address => mapping(uint256 => bool)) public nonceUsed;

    /// @notice _signer address of the signer
    address signerAddress;

    /// @notice SOCKET_EXTRACTOR address of the socket extractor contract
    address public immutable SOCKET_EXTRACTOR;

    // -------------------------------------------------- CONSTRUCTOR -------------------------------------------------- //

    /**
     * @notice Constructor.
     * @param _socketExtractor address of socket market place.
     * @param _owner address of the contract owner
     * @param _signer address of the signer
     */
    constructor(
        address _socketExtractor,
        address _owner,
        address _signer
    ) Ownable(_owner) {
        SOCKET_EXTRACTOR = _socketExtractor;
        signerAddress = _signer;
    }

    // -------------------------------------------------- CALL SOCKET EXTRACTOR FUNCTION -------------------------------------------------- //

    function callExtractor(
        uint256 nonce,
        uint256 value,
        bytes calldata signature,
        bytes calldata extractorData
    ) external {
        // recovering signer.
        address recoveredSigner = ECDSA.recover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encode(
                            address(this),
                            nonce,
                            block.chainid, // uint256
                            value,
                            extractorData
                        )
                    )
                )
            ),
            signature
        );

        if (signerAddress != recoveredSigner) revert SignerMismatch();
        // nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        if (nonceUsed[signerAddress][nonce]) revert InvalidNonce();

        // Mark nonce for that address as used.
        nonceUsed[signerAddress][nonce] = true;

        (bool success, ) = SOCKET_EXTRACTOR.call{value: value}(extractorData);

        if (!success) revert SocketExtractorFailed();
    }

    // -------------------------------------------------- ADMIN FUNCTION -------------------------------------------------- //

    /**
     * @notice Rescues funds from the contract if they are locked by mistake.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address where rescued tokens need to be sent.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }

    /// @notice Sets the signer address if a new signer is needed.
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    /// @notice Approves the tokens against socket extractor.
    function setApprovalForExtractor(
        address[] memory tokenAddresses,
        bool isMax
    ) external onlyOwner {
        for (uint32 index = 0; index < tokenAddresses.length; ) {
            ERC20(tokenAddresses[index]).safeApprove(
                SOCKET_EXTRACTOR,
                isMax ? type(uint256).max : 0
            );
            unchecked {
                ++index;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {OnlyOwner, OnlyNominee} from "../errors/Errors.sol";

abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    constructor(address owner_) {
        _claimOwner(owner_);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function nominee() public view returns (address) {
        return _nominee;
    }

    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    function claimOwner() external {
        if (msg.sender != _nominee) {
            revert OnlyNominee();
        }
        _claimOwner(msg.sender);
    }

    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
        emit OwnerClaimed(claimer_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "../utils/Ownable.sol";
import {AuthenticationLib} from "../lib/AuthenticationLib.sol";

// TODO - Do we need different signers for different extractors. I think we do not need. But keeping it as todo.
/**
 * @title SocketSigner
 * @notice Handle all socket signer address whitelist
 * @dev All Batch orders will be signed by socket gateway signers, only then they will be executable
 * @author reddyismav.
 */
contract SocketWhitelist is Ownable {
    /// @notice owner owner of the contract
    constructor(address _owner) Ownable(_owner) {}

    // --------------------------------------------------- MAPPINGS -------------------------------------------------- //

    /// @notice Socket signer that signs against the order thats submitted.
    mapping(address => bool) socketSigners;

    /// @notice Socket solvers are the addresses that have the execution rights for user orders.
    mapping(address => bool) public gatewaySolvers;

    /// @notice Socket solvers are the addresses that have the execution rights for user orders.
    mapping(address => bool) public rfqSolvers;

    // -------------------------------------------------- SOCKET SIGNER ADMIN FUNCTIONS -------------------------------------------------- //

    /**
     * @notice Set Signer Addresses.
     * @param _signerAddress address that can sign against a batch.
     */
    function addSignerAddress(address _signerAddress) external onlyOwner {
        socketSigners[_signerAddress] = true;
    }

    /**
     * @notice Disbale Signer Address.
     * @param _signerAddress address that can sign against a batch.
     */
    function disableSignerAddress(address _signerAddress) external onlyOwner {
        socketSigners[_signerAddress] = false;
    }

    // -------------------------------------------------- GATEWAY SOLVERS ADMIN FUNCTIONS -------------------------------------------------- //

    /**
     * @notice Set Solver Address.
     * @param _solverAddress address that has the right to execute a user order.
     */
    function addGatewaySolver(address _solverAddress) external onlyOwner {
        gatewaySolvers[_solverAddress] = true;
    }

    /**
     * @notice Disbale Solver Address.
     * @param _solverAddress address that has the right to execute a user order.
     */
    function disableGatewaySolver(address _solverAddress) external onlyOwner {
        gatewaySolvers[_solverAddress] = false;
    }

    // -------------------------------------------------- RFQ SOLVERS ADMIN FUNCTIONS -------------------------------------------------- //

    /**
     * @notice Set Solver Address.
     * @param _solverAddress address that has the right to execute a user order.
     */
    function addRFQSolver(address _solverAddress) external onlyOwner {
        rfqSolvers[_solverAddress] = true;
    }

    /**
     * @notice Disbale Solver Address.
     * @param _solverAddress address that has the right to execute a user order.
     */
    function disableRFQSolver(address _solverAddress) external onlyOwner {
        rfqSolvers[_solverAddress] = false;
    }

    // -------------------------------------------------- SOCKET SIGNER VIEW FUNCTIONS -------------------------------------------------- //

    /**
     * @notice Check if an messageHash has been approved by Socket
     * @param _messageHash messageHash that has been signed by a socket signer
     * @param _sig is the signature produced by socket signer
     */
    function isSocketApproved(
        bytes32 _messageHash,
        bytes calldata _sig
    ) public view returns (bool) {
        return
            socketSigners[AuthenticationLib.authenticate(_messageHash, _sig)];
    }

    /**
     * @notice Check if an address is a socket permitted signer address.
     * @param _signerAddress address that can sign against a batch.
     */
    function isSigner(address _signerAddress) public view returns (bool) {
        return socketSigners[_signerAddress];
    }

    // -------------------------------------------------- GATEWAY SOLVERS VIEW FUNCTIONS -------------------------------------------------- //

    /**
     * @notice Check if the address given is a Gateway Solver..
     * @param _solverAddress address that has the right to execute a user order.
     */
    function isGatewaySolver(
        address _solverAddress
    ) public view returns (bool) {
        return gatewaySolvers[_solverAddress];
    }

    // -------------------------------------------------- RFQ SOLVERS VIEW FUNCTIONS -------------------------------------------------- //

    /**
     * @notice Check if the address given is a RFQ Solver..
     * @param _solverAddress address that has the right to execute a user order.
     */
    function isRFQSolver(address _solverAddress) public view returns (bool) {
        return rfqSolvers[_solverAddress];
    }
}