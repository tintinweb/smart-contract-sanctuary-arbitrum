// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
pragma solidity ^0.8.0;

contract Governable {
    address public gov;
    event GovChange(address pre, address next);

    constructor() {
        gov = msg.sender;
        emit GovChange(address(0x0), msg.sender);
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        emit GovChange(gov, _gov);
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRoleManager {
    function grantRole(address account, bytes32 key) external;

    function revokeRole(address account, bytes32 key) external;

    function hasRole(address account, bytes32 key) external view returns (bool);

    function getRoleCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Governable.sol";
import "./interfaces/IRoleManager.sol";

contract Roles {
    IRoleManager public roles;

    constructor(IRoleManager rs) {
        roles = rs;
    }

    modifier hasRole(bytes32 role) {
        require(roles.hasRole(msg.sender, role), "!role");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/Types.sol";

interface IFunding {
    event FundingUpdated(
        uint16 pairId,
        int256 fundingTracker,
        int256 fundingIncrement
    );

    struct Funding {
        int256 fundingTracker;
        uint32 lastUpdated;
    }

    //SET
    function setFundingInterval(uint32 amount) external;

    function setFundingFactor(uint16 pairId, uint256 amount) external;

    function updateFunding(uint16 pairId) external;

    //GET
    function getLastUpdated(uint16 pairId) external view returns (uint32);

    function getFundingFactor(uint16 pairId) external view returns (uint256);

    function getFundingTracker(uint16 pairId) external view returns (int256);

    function getFunding(uint16 pairId) external view returns (Funding memory);

    function getFundings(uint16[] calldata pairId)
        external
        view
        returns (Funding[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPair {
    event PairUpdated(
        uint16 pairId,
        address chainlinkFeed,
        bool isClosed,
        bool allowSelfExecution,
        uint16 maxLeverage,
        uint256 maxDeviation
    );

    struct Pair {
        address chainlinkFeed;
        bool isClosed;
        bool allowSelfExecution;
        uint16 maxLeverage;
        uint256 maxDeviation;
    }

    function set(uint16 pairId, Pair memory pairInfo) external;

    function setStatus(uint16[] calldata pairIds, bool[] calldata isClosed)
        external;

    function get(uint16 pairId) external view returns (Pair memory);

    function getMany(uint16[] calldata pairIds)
        external
        view
        returns (Pair[] memory);

    function getChainlinkFeed(uint16 pairId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/Types.sol";

interface IPool {
    event Deposit(address owner, uint256 amount, uint256 amountLp);
    event Withdraw(address owner, uint256 amount, uint256 amountLp);
    event FeePaid(bytes32 id, uint256 fee, uint256 oracle);

    function changeWithdrawFee(uint256 amount) external;

    function deposit(uint256 amount) external returns (uint256);

    function depositGasLess(uint256 amount, Types.GasLess calldata gasLess)
        external
        returns (uint256);

    function depositWithPermit(uint256 amount, Types.Permit calldata permit)
        external
        returns (uint256);

    function depositGasLessWithPermit(
        uint256 amount,
        Types.GasLess calldata gasLess,
        Types.Permit calldata permit
    ) external returns (uint256);

    function withdraw(uint256 amountLp) external returns (uint256);

    function withdrawGasLess(uint256 amountLp, Types.GasLess calldata gasLess)
        external
        returns (uint256);

    function creditFee(
        bytes32 id,
        uint256 fee,
        uint256 oracle
    ) external;

    function transferIn(address from, uint256 amount) external;

    function transferOut(address to, uint256 amount) external;

    function settlePosition(
        address user,
        uint256 amount,
        int256 pnl
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/Types.sol";

interface IPosition {
    event OpenPosition(
        bytes32 id,
        address owner,
        bool isLong,
        uint16 pairId,
        uint16 leverage,
        uint32 timestamp,
        uint256 entryPrice,
        uint256 amount,
        int256 fundingTracker
    );

    event ClosePosition(
        bytes32 id,
        uint256 closePrice,
        int256 pnl,
        uint16 closeType
    );

    event UpdateTP(bytes32 id, uint256 tp);

    event UpdateSL(bytes32 id, uint256 sl);

    struct OI {
        uint256 long;
        uint256 short;
    }

    //SET
    function addPosition(Types.Position calldata) external returns (bytes32);

    function updatePosition(bytes32 id, Types.Position calldata position)
        external;

    function closePosition(
        bytes32 id,
        uint256 closePrice,
        int256 pnl,
        uint16 closeType
    ) external;

    function setTp(bytes32 id, uint256 tp) external;

    function setSl(bytes32 id, uint256 sl) external;

    //GET
    function TP(bytes32 id) external view returns (uint256);

    function SL(bytes32 id) external view returns (uint256);

    function getPosition(bytes32 id)
        external
        view
        returns (Types.Position memory);

    function getPositions(bytes32[] calldata id)
        external
        view
        returns (Types.Position[] memory _positions);

    function getIOs(uint16 pairId) external view returns (OI memory);

    function getIO(uint16 pairId) external view returns (uint256);

    function getIOLong(uint16 pairId) external view returns (uint256);

    function getIOShort(uint16 pairId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/Types.sol";

interface ITrading {
    function openPosition(Types.Order calldata order)
        external
        returns (bytes32);

    function openPositionGasLess(
        Types.Order calldata order,
        Types.GasLess calldata gasLess
    ) external returns (bytes32);

    function openLimitPosition(Types.OrderLimit calldata order)
        external
        returns (bytes32);

    function openPositionWithPermit(
        Types.Order calldata order,
        Types.Permit calldata permit
    ) external returns (bytes32);

    function openPositionGasLessWithPermit(
        Types.Order calldata order,
        Types.GasLess calldata gasLess,
        Types.Permit calldata permit
    ) external returns (bytes32);

    function openLimitPositionWithPermit(
        Types.OrderLimit calldata order,
        Types.Permit calldata permit
    ) external returns (bytes32);

    function selfClosePosition(bytes32 orderId) external;

    function closePosition(
        bytes32 orderId,
        uint256 price,
        uint16 closeType
    ) external;

    // function closePositions(
    //     bytes32[] calldata Ids,
    //     uint256[] calldata prices,
    //     uint16[] calldata closeType
    // ) external;

    function selfLiquidatePosition(bytes32 orderId) external;

    function liquidatePositions(
        bytes32[] calldata orderIds,
        uint256[] calldata prices
    ) external;

    // function updateLimit(
    //     bytes32 id,
    //     uint256 tp,
    //     uint256 sl
    // ) external;

    function updateLimitGasLess(
        bytes32 id,
        uint256 tp,
        uint256 sl,
        Types.GasLess calldata gasLess
    ) external;

    // function updateMargin(bytes32 id, uint256 leverage) external;

    // function increasePosition(bytes32 id, uint256 price) external;

    // function decreasePosition(bytes32 id, uint256 price) external;

    function cancelOrder(bytes calldata sign) external;

    function cancelOrderGasLess(
        bytes calldata orderId,
        Types.GasLess calldata gasLess
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../access/Roles.sol";
import "../interfaces/Types.sol";
import "./interfaces/ITrading.sol";
import "./interfaces/IPosition.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IFunding.sol";
import "./interfaces/IPair.sol";
import "../utils/interfaces/IChainlink.sol";
import "../utils/Verify.sol";

contract Trading is Roles, ERC2771Context, ITrading {
    string constant EIP712_DOMAIN_TYPE =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    bytes32 public constant ORACLE = keccak256("ORACLE");
    bytes32 public DOMAIN_HASH;
    IFunding public funding;
    IPool public pool;
    IERC20Permit public usdc;
    IChainlink public chainlink;
    IPosition public positionStorage;
    IPair public pairs;

    mapping(address => uint256) public nonces; //For gasless
    mapping(address => mapping(bytes32 => bool)) public signUsed;

    uint256 public constant BPS = 1e6; //Base Percent
    uint256 public minSize = 25e8; //2500 USDC
    uint256 public openFee = 1000; //0,1% => 1=1e6
    uint256 public closeFee = 1000; //0,1% =>1=1e6
    uint256 public excutionFee = 2e5; //0.2 USDC
    uint256 public permitFee = 1e5; //O.1 USDC
    uint256 public fixSpread = 400; //0.04% =>1e6
    uint256 public liqThreshold = 10000; // 1% (-99%)

    constructor(
        IRoleManager _roles,
        IERC20Permit _usdc,
        IChainlink _chainlink,
        IPosition _position,
        IFunding _funding,
        IPool _pool,
        IPair _pairs,
        address _trustedForwarder
    ) Roles(_roles) ERC2771Context(_trustedForwarder) {
        usdc = _usdc;
        funding = _funding;
        chainlink = _chainlink;
        positionStorage = _position;
        pool = _pool;
        pairs = _pairs;
        _setDomain();
    }

    function _setDomain() internal {
        uint256 chainId;
        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            chainId := chainid()
        }

        bytes memory domainValue = abi.encode(
            keccak256(bytes(EIP712_DOMAIN_TYPE)),
            keccak256(bytes("Smurfi")),
            keccak256(bytes("1")),
            chainId,
            address(this)
        );
        DOMAIN_HASH = keccak256(domainValue);
    }

    function openPosition(Types.Order calldata order)
        external
        virtual
        override
        returns (bytes32)
    {
        return _openPosition(_msgSender(), order, 0);
    }

    function openPositionGasLess(
        Types.Order calldata order,
        Types.GasLess calldata gasLess
    ) external virtual override returns (bytes32) {
        Verify._verifyGasLess(
            DOMAIN_HASH,
            nonces[gasLess.owner],
            order,
            gasLess
        );
        nonces[gasLess.owner]++;
        return _openPosition(gasLess.owner, order, excutionFee);
    }

    function openPositionWithPermit(
        Types.Order calldata order,
        Types.Permit calldata permit
    ) external virtual override returns (bytes32) {
        require(permit.owner == _msgSender(), "!permit-sender");
        usdc.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        return _openPosition(_msgSender(), order, 0);
    }

    function openPositionGasLessWithPermit(
        Types.Order calldata order,
        Types.GasLess calldata gasLess,
        Types.Permit calldata permit
    ) external virtual override returns (bytes32) {
        require(gasLess.owner == permit.owner, "!permit-sender");
        Verify._verifyGasLess(
            DOMAIN_HASH,
            nonces[gasLess.owner],
            order,
            gasLess
        );
        nonces[gasLess.owner]++;
        usdc.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        return _openPosition(gasLess.owner, order, excutionFee + permitFee);
    }

    function openLimitPosition(Types.OrderLimit calldata order)
        external
        virtual
        override
        returns (bytes32)
    {
        return _openLimitPosition(order);
    }

    function openLimitPositionWithPermit(
        Types.OrderLimit calldata order,
        Types.Permit calldata permit
    ) external virtual override returns (bytes32) {
        require(order.owner == permit.owner, "!permit-owner");
        usdc.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        return _openLimitPosition(order);
    }

    function _openLimitPosition(Types.OrderLimit calldata order)
        internal
        returns (bytes32)
    {
        Verify._verifyLimitOpenPosition(DOMAIN_HASH, order);
        require(
            !signUsed[order.owner][keccak256(order.signature)],
            "!sign-used"
        );
        uint256 chainlinkPrice = chainlink.getPrice(order.pairId);
        if (
            ((order.orderType == 1 && order.isLong) ||
                (order.orderType == 2 && !order.isLong)) &&
            chainlinkPrice > order.limitPrice
        ) {
            revert("!price-not-match");
        }

        if (
            ((order.orderType == 1 && !order.isLong) ||
                (order.orderType == 2 && order.isLong)) &&
            chainlinkPrice < order.limitPrice
        ) {
            revert("!price-not-match");
        }
        signUsed[order.owner][keccak256(order.signature)] = true;
        return
            _openPosition(
                order.owner,
                Types.Order(
                    order.isLong,
                    order.pairId,
                    order.leverage,
                    order.amount,
                    order.tp,
                    order.sl
                ),
                excutionFee
            );
    }

    function _openPosition(
        address owner,
        Types.Order memory order,
        uint256 fees
    ) internal returns (bytes32) {
        require(order.amount * order.leverage >= minSize, "!min-size");
        IPair.Pair memory pair = pairs.get(order.pairId);
        require(
            pair.chainlinkFeed != address(0x0) && !pair.isClosed,
            "!closed"
        );

        require(
            order.leverage > 0 && order.leverage <= pair.maxLeverage,
            "!leverage"
        );
        pool.transferIn(owner, order.amount);
        uint256 chainlinkPrice = chainlink.getPrice(order.pairId);
        uint256 feeOpen = (order.amount * order.leverage * openFee) / BPS;
        require(order.amount > feeOpen + fees, "!fee-not-enough");
        Types.Position memory position = Types.Position(
            owner,
            order.isLong,
            order.pairId,
            order.leverage,
            uint32(block.timestamp),
            _getMarkPrice(chainlinkPrice, order.isLong),
            order.amount - feeOpen - fees,
            funding.getFundingTracker(order.pairId)
        );
        bytes32 id = positionStorage.addPosition(position);
        if (order.tp > 0) positionStorage.setTp(id, order.tp);
        if (order.sl > 0) positionStorage.setSl(id, order.sl);
        pool.creditFee(id, feeOpen, fees);
        return id;
    }

    function selfClosePosition(bytes32 orderId) external virtual override {
        Types.Position memory position = positionStorage.getPosition(orderId);
        require(position.owner == _msgSender(), "!owner-call");
        uint256 chainlinkPrice = chainlink.getPrice(position.pairId);
        _excutePostion(
            orderId,
            _getMarkPrice(chainlinkPrice, position.isLong),
            true,
            1
        );
    }

    function closePosition(
        bytes32 id,
        uint256 price,
        uint16 closeType
    ) external virtual override hasRole(ORACLE) {
        _excutePostion(id, price, false, closeType);
    }

    function selfLiquidatePosition(bytes32 orderId) external virtual override {
        Types.Position memory position = positionStorage.getPosition(orderId);
        require(position.owner == _msgSender(), "!owner-call");
        uint256 chainlinkPrice = chainlink.getPrice(position.pairId);
        _excutePostion(
            orderId,
            _getMarkPrice(chainlinkPrice, position.isLong),
            true,
            0
        );
    }

    // function closePositions(
    //     bytes32[] calldata Ids,
    //     uint256[] calldata prices,
    //     uint16[] calldata closeType
    // ) external virtual override hasRole(ORACLE) {
    //     require(Ids.length == prices.length, "!length");
    //     for (uint256 i = 0; i < Ids.length; i++) {
    //         _excutePostion(Ids[i], prices[i], false, closeType[i]);
    //     }
    // }

    function liquidatePositions(
        bytes32[] calldata Ids,
        uint256[] calldata prices
    ) external virtual override hasRole(ORACLE) {
        require(Ids.length == prices.length, "!length");
        for (uint256 i = 0; i < Ids.length; i++) {
            _excutePostion(Ids[i], prices[i], false, 0);
        }
    }

    //closeType
    //0: liquidation
    //1: market
    //2: tp
    //3: sl

    function _excutePostion(
        bytes32 id,
        uint256 price,
        bool isSelf,
        uint16 closeType
    ) internal {
        Types.Position memory position = positionStorage.getPosition(id);
        if (price == 0 || position.amount == 0 || position.leverage == 0)
            return;
        uint256 positionSize = position.amount * position.leverage;
        uint256 feeClose = (positionSize * closeFee) / BPS;
        (int256 pnl, ) = getPnL(
            position.pairId,
            position.isLong,
            price,
            position.entryPrice,
            positionSize,
            funding.getFundingTracker(position.pairId)
        );
        int256 finalAmount = int256(position.amount) +
            pnl -
            int256(feeClose) -
            (isSelf ? int256(0) : int256(excutionFee));
        uint256 liqAmount = (position.amount * liqThreshold) / BPS;
        if (finalAmount <= 0) {
            pnl =
                -int256(position.amount) +
                int256(feeClose) +
                (isSelf ? int256(0) : int256(excutionFee));
            finalAmount = 0;
        }
        position.amount = 0;
        if (closeType == 0 && finalAmount > int256(liqAmount)) {
            //skip if not liquidation
            return;
        }
        if (closeType == 2) {
            //TP
            uint256 tp = positionStorage.TP(id);
            if (
                (position.isLong && price < tp) ||
                (!position.isLong && price > tp)
            ) return;
        }
        if (closeType == 3) {
            //SL
            uint256 sl = positionStorage.SL(id);
            if (
                (position.isLong && price > sl) ||
                (!position.isLong && price < sl)
            ) return;
        }
        positionStorage.updatePosition(id, position);
        positionStorage.closePosition(id, price, pnl, closeType);
        pool.settlePosition(position.owner, uint256(finalAmount), pnl);
        pool.creditFee(id, feeClose, isSelf ? 0 : excutionFee);
    }

    // function updateLimit(
    //     bytes32 id,
    //     uint256 tp,
    //     uint256 sl
    // ) external virtual override {
    //     Types.Position memory position = positionStorage.getPosition(id);
    //     require(position.owner == _msgSender(), "!owner");
    //     if (tp > 0) positionStorage.setTp(id, tp);
    //     if (sl > 0) positionStorage.setSl(id, sl);
    // }

    function updateLimitGasLess(
        bytes32 id,
        uint256 tp,
        uint256 sl,
        Types.GasLess calldata gasLess
    ) external virtual override {
        Verify._verifyUpdateLimit(DOMAIN_HASH, id, tp, sl, gasLess);
        Types.Position memory position = positionStorage.getPosition(id);
        require(position.owner == gasLess.owner, "!owner");
        if (tp > 0) positionStorage.setTp(id, tp);
        if (sl > 0) positionStorage.setSl(id, sl);
        signUsed[gasLess.owner][keccak256(gasLess.signature)] = true;
    }

    // function updateMargin(bytes32 orderId, uint256 leverage)
    //     external
    //     virtual
    //     override
    // {}

    // function increasePosition(bytes32 orderId, uint256 price)
    //     external
    //     virtual
    //     override
    // {}

    // function decreasePosition(bytes32 orderId, uint256 price)
    //     external
    //     virtual
    //     override
    // {}

    function cancelOrder(bytes calldata sign) external virtual override {
        signUsed[_msgSender()][keccak256(sign)] = true;
    }

    function cancelOrderGasLess(
        bytes calldata sign,
        Types.GasLess calldata gasLess
    ) external virtual override {
        Verify._verifyCancel(DOMAIN_HASH, sign, gasLess);
        signUsed[gasLess.owner][keccak256(sign)] = true;
    }

    function getPnL(
        uint16 pairId,
        bool isLong,
        uint256 price,
        uint256 entryPrice,
        uint256 positionSize,
        int256 fundingTracker
    ) public view returns (int256 pnl, int256 fundingFee) {
        if (price == 0 || entryPrice == 0 || positionSize == 0) return (0, 0);

        if (isLong) {
            pnl =
                (int256(positionSize) * (int256(price) - int256(entryPrice))) /
                int256(entryPrice);
        } else {
            pnl =
                (int256(positionSize) * (int256(entryPrice) - int256(price))) /
                int256(entryPrice);
        }

        int256 currentFundingTracker = funding.getFundingTracker(pairId);
        fundingFee =
            (int256(positionSize) * (currentFundingTracker - fundingTracker)) /
            int256(BPS);

        if (isLong) {
            pnl -= fundingFee;
        } else {
            pnl += fundingFee;
        }

        return (pnl, fundingFee);
    }

    function _getMarkPrice(uint256 price, bool isLong)
        internal
        view
        returns (uint256)
    {
        if (isLong) {
            return (price * (BPS + fixSpread)) / BPS;
        } else {
            return (price * (BPS - fixSpread)) / BPS;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Types {
    struct Order {
        bool isLong;
        uint16 pairId;
        uint16 leverage;
        uint256 amount;
        uint256 tp;
        uint256 sl;
    }

    struct OrderLimit {
        address owner;
        bool isLong;
        uint8 orderType;
        uint16 pairId;
        uint16 leverage;
        uint32 expire;
        uint256 amount;
        uint256 limitPrice;
        uint256 tp;
        uint256 sl;
        bytes signature;
    }

    struct Position {
        address owner;
        bool isLong;
        uint16 pairId;
        uint16 leverage;
        uint32 timestamp;
        uint256 entryPrice;
        uint256 amount;
        int256 fundingTracker;
    }

    struct GasLess {
        address owner;
        uint256 deadline;
        bytes signature;
    }

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChainlink {
    function getPrice(uint16 pairId) external view returns (uint256);

    function boundPrice(uint16 pairId, uint256 price)
        external
        view
        returns (bool, uint256);

    function boundPriceWithChainlink(uint16 pairId, uint256 price)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "../interfaces/Types.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Verify {
    using ECDSA for bytes32;

    bytes32 public constant OPEN_POSITION_HASH =
        keccak256(
            bytes(
                "OpenPosition(address owner,bool isLong,uint16 pairId,uint16 leverage,uint256 amount,uint256 tp,uint256 sl,uint256 deadline,uint256 nonce)"
            )
        );

    bytes32 public constant LIMIT_POSITION_HASH =
        keccak256(
            bytes(
                "LimitPosition(address owner,bool isLong,uint8 orderType,uint16 pairId,uint16 leverage,uint32 expire,uint256 amount,uint256 limitPrice,uint256 tp,uint256 sl)"
            )
        );

    bytes32 public constant UPDATE_LIMIT_HASH =
        keccak256(
            bytes(
                "UpdateLimit(address owner,bytes32 id,uint256 tp,uint256 sl,uint256 deadline)"
            )
        );

    bytes32 public constant CANCEL_ORDER_HASH =
        keccak256(
            bytes("CancelOrder(address owner,bytes sign,uint256 deadline)")
        );

    function _verifyGasLess(
        bytes32 domainHash,
        uint256 nonce,
        Types.Order calldata order,
        Types.GasLess calldata gasLess
    ) internal view {
        //  "OpenPosition(address owner,bool isLong,uint16 pairId,uint16 leverage,uint256 amount,uint256 tp,uint256 sl,uint256 deadline,uint256 nonce)"
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                keccak256(
                    abi.encodePacked(
                        OPEN_POSITION_HASH,
                        uint256(uint160(gasLess.owner)),
                        order.isLong ? uint256(1) : uint256(0),
                        uint256(order.pairId),
                        uint256(order.leverage),
                        order.amount,
                        order.tp,
                        order.sl,
                        gasLess.deadline,
                        nonce
                    )
                )
            )
        );
        require(
            digest.recover(gasLess.signature) == gasLess.owner,
            "!signature"
        );
        require(gasLess.deadline > block.timestamp, "!deadline");
    }

    function _verifyLimitOpenPosition(
        bytes32 domainHash,
        Types.OrderLimit calldata order
    ) internal view {
        // "LimitPosition(address owner,bool isLong,uint8 orderType,uint16 pairId,uint16 leverage,uint32 expire,uint256 amount,uint256 limitPrice,uint256 tp,uint256 sl)";
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                keccak256(
                    abi.encodePacked(
                        LIMIT_POSITION_HASH,
                        uint256(uint160(order.owner)),
                        order.isLong ? uint256(1) : uint256(0),
                        uint256(order.orderType),
                        uint256(order.pairId),
                        uint256(order.leverage),
                        uint256(order.expire),
                        order.amount,
                        order.limitPrice,
                        order.tp,
                        order.sl
                    )
                )
            )
        );
        require(digest.recover(order.signature) == order.owner, "!signature");
        require(order.expire > block.timestamp, "!expire");
    }

    function _verifyUpdateLimit(
        bytes32 domainHash,
        bytes32 id,
        uint256 tp,
        uint256 sl,
        Types.GasLess calldata gasLess
    ) internal view {
        //"UpdateLimit(address owner,bytes32 id,uint256 tp,uint256 sl,uint256 deadline)"
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                keccak256(
                    abi.encodePacked(
                        UPDATE_LIMIT_HASH,
                        uint256(uint160(gasLess.owner)),
                        id,
                        tp,
                        sl,
                        gasLess.deadline
                    )
                )
            )
        );
        require(
            digest.recover(gasLess.signature) == gasLess.owner,
            "!signature"
        );
        require(gasLess.deadline > block.timestamp, "!deadline");
    }

    function _verifyCancel(
        bytes32 domainHash,
        bytes calldata sign,
        Types.GasLess calldata gasLess
    ) internal view {
        //CancelOrder(address owner,bytes sign,uint256 deadline)
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                keccak256(
                    abi.encodePacked(
                        CANCEL_ORDER_HASH,
                        uint256(uint160(gasLess.owner)),
                        keccak256(sign),
                        gasLess.deadline
                    )
                )
            )
        );
        require(
            digest.recover(gasLess.signature) == gasLess.owner,
            "!signature"
        );
        require(gasLess.deadline > block.timestamp, "!deadline");
    }
}