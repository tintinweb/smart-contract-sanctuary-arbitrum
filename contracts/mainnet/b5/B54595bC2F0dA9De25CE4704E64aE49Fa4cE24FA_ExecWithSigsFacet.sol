// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// Four different types of calldata packing
// 1. encodeFeeCollector: append 20 byte feeCollector address
// 2. encodeRelayContext: append 20 byte feeCollector address, 20 byte feeToken address, 32 byte uint256 fee
// 3. encodeFeeCollectorERC2771: append 20 byte feeCollector address, 20 byte _msgSender address
// 4. encodeRelayContextERC2771: append 20 byte feeCollector address, 20 byte feeToken address, 32 byte uint256 fee, 20 byte _msgSender address

function _encodeFeeCollector(bytes calldata _data, address _feeCollector)
    pure
    returns (bytes memory)
{
    return abi.encodePacked(_data, _feeCollector);
}

function _encodeRelayContext(
    bytes calldata _data,
    address _feeCollector,
    address _feeToken,
    uint256 _fee
) pure returns (bytes memory) {
    return abi.encodePacked(_data, _feeCollector, _feeToken, _fee);
}

// ERC2771 Encodings

// vanilla ERC2771 context encoding
// solhint-disable-next-line private-vars-leading-underscore, func-visibility
function _encodeERC2771Context(bytes calldata _data, address _msgSender)
    pure
    returns (bytes memory)
{
    return abi.encodePacked(_data, _msgSender);
}

function _encodeFeeCollectorERC2771(
    bytes calldata _data,
    address _feeCollector,
    address _msgSender
) pure returns (bytes memory) {
    return abi.encodePacked(_data, _feeCollector, _msgSender);
}

function _encodeRelayContextERC2771(
    bytes calldata _data,
    address _feeCollector,
    address _feeToken,
    uint256 _fee,
    address _msgSender
) pure returns (bytes memory) {
    return abi.encodePacked(_data, _feeCollector, _feeToken, _fee, _msgSender);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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
 * ```
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BFacetOwner} from "../facets/base/BFacetOwner.sol";
import {LibDiamond} from "../libraries/diamond/standard/LibDiamond.sol";
import {GelatoBytes} from "../libraries/GelatoBytes.sol";
import {ExecWithSigsBase} from "./base/ExecWithSigsBase.sol";
import {GelatoCallUtils} from "../libraries/GelatoCallUtils.sol";
import {
    _getBalance,
    _simulateAndRevert,
    _revert,
    _revertWithFee,
    _revertWithFeeAndIsFeeCollector
} from "../functions/Utils.sol";
import {
    ExecWithSigs,
    ExecWithSigsTrackFee,
    ExecWithSigsFeeCollector,
    ExecWithSigsRelayContext,
    Message,
    MessageTrackFee,
    MessageFeeCollector,
    MessageRelayContext
} from "../types/CallTypes.sol";
import {_isCheckerSigner} from "./storage/SignerStorage.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {
    _encodeRelayContext,
    _encodeFeeCollector
} from "@gelatonetwork/relay-context/contracts/functions/GelatoRelayUtils.sol";

contract ExecWithSigsFacet is ExecWithSigsBase, BFacetOwner {
    using GelatoCallUtils for address;
    using LibDiamond for address;

    //solhint-disable-next-line const-name-snakecase
    string public constant name = "ExecWithSigsFacet";
    //solhint-disable-next-line const-name-snakecase
    string public constant version = "1";

    address public immutable feeCollector;

    event LogExecWithSigsTrackFee(
        bytes32 correlationId,
        MessageTrackFee msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 observedFee,
        uint256 estimatedGasUsed,
        address sender
    );

    event LogExecWithSigs(
        bytes32 correlationId,
        Message msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 estimatedGasUsed,
        address sender
    );

    event LogExecWithSigsFeeCollector(
        bytes32 correlationId,
        MessageFeeCollector msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 observedFee,
        uint256 estimatedGasUsed,
        address sender
    );

    event LogExecWithSigsRelayContext(
        bytes32 correlationId,
        MessageRelayContext msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 observedFee,
        uint256 estimatedGasUsed,
        address sender
    );

    constructor(address _feeCollector) {
        feeCollector = _feeCollector;
    }

    // solhint-disable function-max-lines
    /// @param _call Execution payload packed into ExecWithSigsTrackFee struct
    /// @return estimatedGasUsed Estimated gas used using gas metering
    /// @return observedFee The fee transferred to the fee collector or diamond
    function execWithSigsTrackFee(
        ExecWithSigsTrackFee calldata _call
    ) external returns (uint256 estimatedGasUsed, uint256 observedFee) {
        uint256 startGas = gasleft();

        require(
            msg.sender == tx.origin,
            "ExecWithSigsFacet.execWithSigsTrackFee: only EOAs"
        );

        _requireSignerDeadline(
            _call.msg.deadline,
            "ExecWithSigsFacet.execWithSigsTrackFee._requireSignerDeadline:"
        );

        bytes32 digest = _getDigestTrackFee(_getDomainSeparator(), _call.msg);

        address executorSigner = _requireExecutorSignerSignature(
            digest,
            _call.executorSignerSig,
            "ExecWithSigsFacet.execWithSigsTrackFee._requireExecutorSignerSignature:"
        );

        address checkerSigner = _requireCheckerSignerSignature(
            digest,
            _call.checkerSignerSig,
            "ExecWithSigsFacet.execWithSigsTrackFee._requireCheckerSignerSignature:"
        );

        address feeRecipient = _call.msg.isFeeCollector
            ? feeCollector
            : address(this);

        {
            uint256 preFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeRecipient
            );

            // call forward
            _call.msg.service.revertingContractCall(
                _call.msg.data,
                "ExecWithSigsFacet.execWithSigsTrackFee:"
            );

            uint256 postFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeRecipient
            );

            observedFee = postFeeTokenBalance - preFeeTokenBalance;
        }

        estimatedGasUsed = startGas - gasleft();

        emit LogExecWithSigsTrackFee(
            _call.correlationId,
            _call.msg,
            executorSigner,
            checkerSigner,
            observedFee,
            estimatedGasUsed,
            msg.sender
        );
    }

    // solhint-disable function-max-lines
    /// @param _call Execution payload packed into ExecWithSigs struct
    /// @return estimatedGasUsed Estimated gas used using gas metering
    function execWithSigs(
        ExecWithSigs calldata _call
    ) external returns (uint256 estimatedGasUsed) {
        uint256 startGas = gasleft();

        require(
            msg.sender == tx.origin,
            "ExecWithSigsFacet.execWithSigs: only EOAs"
        );

        _requireSignerDeadline(
            _call.msg.deadline,
            "ExecWithSigsFacet.execWithSigs._requireSignerDeadline:"
        );

        bytes32 digest = _getDigest(_getDomainSeparator(), _call.msg);

        address executorSigner = _requireExecutorSignerSignature(
            digest,
            _call.executorSignerSig,
            "ExecWithSigsFacet.execWithSigs._requireExecutorSignerSignature:"
        );

        address checkerSigner = _requireCheckerSignerSignature(
            digest,
            _call.checkerSignerSig,
            "ExecWithSigsFacet.execWithSigs._requireCheckerSignerSignature:"
        );

        // call forward
        _call.msg.service.revertingContractCall(
            _call.msg.data,
            "ExecWithSigsFacet.execWithSigs:"
        );

        estimatedGasUsed = startGas - gasleft();

        emit LogExecWithSigs(
            _call.correlationId,
            _call.msg,
            executorSigner,
            checkerSigner,
            estimatedGasUsed,
            msg.sender
        );
    }

    // solhint-disable function-max-lines
    /// @param _call Execution payload packed into ExecWithSigsFeeCollector struct
    /// @return estimatedGasUsed Estimated gas used using gas metering
    /// @return observedFee The fee transferred to the fee collector
    function execWithSigsFeeCollector(
        ExecWithSigsFeeCollector calldata _call
    ) external returns (uint256 estimatedGasUsed, uint256 observedFee) {
        uint256 startGas = gasleft();

        require(
            msg.sender == tx.origin,
            "ExecWithSigsFacet.execWithSigsFeeCollector: only EOAs"
        );

        _requireSignerDeadline(
            _call.msg.deadline,
            "ExecWithSigsFacet.execWithSigsFeeCollector._requireSignerDeadline:"
        );

        bytes32 digest = _getDigestFeeCollector(
            _getDomainSeparator(),
            _call.msg
        );

        address executorSigner = _requireExecutorSignerSignature(
            digest,
            _call.executorSignerSig,
            "ExecWithSigsFacet.execWithSigsFeeCollector._requireExecutorSignerSignature:"
        );

        address checkerSigner = _requireCheckerSignerSignature(
            digest,
            _call.checkerSignerSig,
            "ExecWithSigsFacet.execWithSigsFeeCollector._requireCheckerSignerSignature:"
        );

        {
            uint256 preFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeCollector
            );

            // call forward + append fee collector
            _call.msg.service.revertingContractCall(
                _encodeFeeCollector(_call.msg.data, feeCollector),
                "ExecWithSigsFacet.execWithSigsFeeCollector:"
            );

            uint256 postFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeCollector
            );

            observedFee = postFeeTokenBalance - preFeeTokenBalance;
        }

        estimatedGasUsed = startGas - gasleft();

        emit LogExecWithSigsFeeCollector(
            _call.correlationId,
            _call.msg,
            executorSigner,
            checkerSigner,
            observedFee,
            estimatedGasUsed,
            msg.sender
        );
    }

    // solhint-disable function-max-lines
    /// @param _call Execution payload packed into ExecWithSigsRelayContext struct
    /// @return estimatedGasUsed Estimated gas used using gas metering
    /// @return observedFee The fee transferred to the fee collector
    function execWithSigsRelayContext(
        ExecWithSigsRelayContext calldata _call
    ) external returns (uint256 estimatedGasUsed, uint256 observedFee) {
        uint256 startGas = gasleft();

        require(
            msg.sender == tx.origin,
            "ExecWithSigsFacet.execWithSigsRelayContext: only EOAs"
        );

        _requireSignerDeadline(
            _call.msg.deadline,
            "ExecWithSigsFacet.execWithSigsRelayContext._requireSignerDeadline:"
        );

        bytes32 digest = _getDigestRelayContext(
            _getDomainSeparator(),
            _call.msg
        );

        address executorSigner = _requireExecutorSignerSignature(
            digest,
            _call.executorSignerSig,
            "ExecWithSigsFacet.execWithSigsRelayContext._requireExecutorSignerSignature:"
        );

        address checkerSigner = _requireCheckerSignerSignature(
            digest,
            _call.checkerSignerSig,
            "ExecWithSigsFacet.execWithSigsRelayContext._requireCheckerSignerSignature:"
        );

        {
            uint256 preFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeCollector
            );

            // call forward + append fee collector, feeToken, fee
            _call.msg.service.revertingContractCall(
                _encodeRelayContext(
                    _call.msg.data,
                    feeCollector,
                    _call.msg.feeToken,
                    _call.msg.fee
                ),
                "ExecWithSigsFacet.execWithSigsRelayContext:"
            );

            uint256 postFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeCollector
            );

            observedFee = postFeeTokenBalance - preFeeTokenBalance;
        }

        estimatedGasUsed = startGas - gasleft();

        emit LogExecWithSigsRelayContext(
            _call.correlationId,
            _call.msg,
            executorSigner,
            checkerSigner,
            observedFee,
            estimatedGasUsed,
            msg.sender
        );
    }

    /// @dev Used for off-chain simulation only!
    function simulateExecWithSigsTrackFee(
        address _service,
        bytes calldata _data,
        address _feeToken
    )
        external
        returns (
            uint256 estimatedGasUsed,
            uint256 observedFee,
            bool isFeeCollector
        )
    {
        uint256 startGas = gasleft();

        uint256 preFeeCollectorBalance = _getBalance(_feeToken, feeCollector);
        uint256 preDiamondBalance = _getBalance(_feeToken, address(this));

        (bool success, bytes memory returndata) = _service.call(_data);

        uint256 observedFeeCollectorFee = _getBalance(_feeToken, feeCollector) -
            preFeeCollectorBalance;
        uint256 observedDiamondFee = _getBalance(_feeToken, address(this)) -
            preDiamondBalance;

        if (observedDiamondFee > observedFeeCollectorFee) {
            observedFee = observedDiamondFee;
        } else {
            observedFee = observedFeeCollectorFee;
            isFeeCollector = true;
        }

        estimatedGasUsed = startGas - gasleft();

        if (tx.origin != address(0) || !success) {
            _revertWithFeeAndIsFeeCollector(
                success,
                isFeeCollector,
                returndata,
                estimatedGasUsed,
                observedFee
            );
        }
    }

    /// @dev Used for off-chain simulation only!
    function simulateExecWithSigs(
        address _service,
        bytes memory _data
    ) external returns (uint256 estimatedGasUsed) {
        uint256 startGas = gasleft();

        (bool success, bytes memory returndata) = _service.call(_data);

        estimatedGasUsed = startGas - gasleft();

        if (tx.origin != address(0) || !success) {
            _revert(success, returndata, estimatedGasUsed);
        }
    }

    /// @dev Used for off-chain simulation only!
    function simulateExecWithSigsFeeCollector(
        address _service,
        bytes calldata _data,
        address _feeToken
    ) external returns (uint256 estimatedGasUsed, uint256 observedFee) {
        uint256 startGas = gasleft();

        uint256 preFeeTokenBalance = _getBalance(_feeToken, feeCollector);

        (bool success, bytes memory returndata) = _service.call(
            _encodeFeeCollector(_data, feeCollector)
        );

        uint256 postFeeTokenBalance = _getBalance(_feeToken, feeCollector);
        observedFee = postFeeTokenBalance - preFeeTokenBalance;
        estimatedGasUsed = startGas - gasleft();

        if (tx.origin != address(0) || !success) {
            _revertWithFee(success, returndata, estimatedGasUsed, observedFee);
        }
    }

    /// @dev Used for off-chain simulation only!
    function simulateExecWithSigsRelayContext(
        address _service,
        bytes calldata _data,
        address _feeToken,
        uint256 _fee
    ) external returns (uint256 estimatedGasUsed, uint256 observedFee) {
        uint256 startGas = gasleft();

        uint256 preFeeTokenBalance = _getBalance(_feeToken, feeCollector);

        (bool success, bytes memory returndata) = _service.call(
            _encodeRelayContext(_data, feeCollector, _feeToken, _fee)
        );

        uint256 postFeeTokenBalance = _getBalance(_feeToken, feeCollector);
        observedFee = postFeeTokenBalance - preFeeTokenBalance;
        estimatedGasUsed = startGas - gasleft();

        if (tx.origin != address(0) || !success) {
            _revertWithFee(success, returndata, estimatedGasUsed, observedFee);
        }
    }

    //solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _getDomainSeparator();
    }

    function _getDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        bytes(
                            //solhint-disable-next-line max-line-length
                            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                        )
                    ),
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    block.chainid,
                    address(this)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LibDiamond} from "../../libraries/diamond/standard/LibDiamond.sol";

abstract contract BFacetOwner {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {GelatoString} from "../../libraries/GelatoString.sol";
import {
    _wasSignatureUsedAlready,
    _setWasSignatureUsedAlready
} from "../storage/ExecWithSigsStorage.sol";
import {
    _isExecutorSigner,
    _isCheckerSigner
} from "../storage/SignerStorage.sol";
import {
    ExecWithSigs,
    Message,
    ExecWithSigsFeeCollector,
    MessageFeeCollector,
    MessageTrackFee,
    ExecWithSigsRelayContext,
    MessageRelayContext
} from "../../types/CallTypes.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract ExecWithSigsBase {
    using GelatoString for string;

    bytes32 public constant MESSAGE_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "Message(address service,bytes data,uint256 salt,uint256 deadline)"
            )
        );

    bytes32 public constant MESSAGE_FEE_COLLECTOR_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "MessageFeeCollector(address service,bytes data,uint256 salt,uint256 deadline,address feeToken)"
            )
        );

    bytes32 public constant MESSAGE_TRACK_FEE =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "MessageTrackFee(address service,bytes data,uint256 salt,uint256 deadline,address feeToken,bool isFeeCollector)"
            )
        );

    bytes32 public constant MESSAGE_RELAY_CONTEXT_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "MessageRelayContext(address service,bytes data,uint256 salt,uint256 deadline,address feeToken,uint256 fee)"
            )
        );

    function _requireSignerDeadline(
        uint256 _signerDeadline,
        string memory _errorTrace
    ) internal view {
        require(
            // solhint-disable-next-line not-rely-on-time
            _signerDeadline == 0 || _signerDeadline >= block.timestamp,
            _errorTrace.suffix("deadline")
        );
    }

    function _requireExecutorSignerSignature(
        bytes32 _digest,
        bytes calldata _executorSignerSig,
        string memory _errorTrace
    ) internal returns (address executorSigner) {
        require(
            !_wasSignatureUsedAlready(_executorSignerSig),
            _errorTrace.suffix("replay")
        );

        ECDSA.RecoverError error;
        (executorSigner, error) = ECDSA.tryRecover(_digest, _executorSignerSig);

        require(
            error == ECDSA.RecoverError.NoError &&
                _isExecutorSigner(executorSigner),
            _errorTrace.suffix("ECDSA.RecoverError.NoError && isExecutorSigner")
        );

        _setWasSignatureUsedAlready(_executorSignerSig);
    }

    function _requireCheckerSignerSignature(
        bytes32 _digest,
        bytes calldata _checkerSignerSig,
        string memory _errorTrace
    ) internal returns (address checkerSigner) {
        require(
            !_wasSignatureUsedAlready(_checkerSignerSig),
            _errorTrace.suffix("replay")
        );

        ECDSA.RecoverError error;
        (checkerSigner, error) = ECDSA.tryRecover(_digest, _checkerSignerSig);

        require(
            error == ECDSA.RecoverError.NoError &&
                _isCheckerSigner(checkerSigner),
            _errorTrace.suffix("ECDSA.RecoverError.NoError && isCheckerSigner")
        );

        _setWasSignatureUsedAlready(_checkerSignerSig);
    }

    function _getDigest(
        bytes32 _domainSeparator,
        Message calldata _msg
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeExecWithSigs(_msg))
            )
        );
    }

    function _getDigestFeeCollector(
        bytes32 _domainSeparator,
        MessageFeeCollector calldata _msg
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeExecWithSigsFeeCollector(_msg))
            )
        );
    }

    function _getDigestTrackFee(
        bytes32 _domainSeparator,
        MessageTrackFee calldata _msg
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeExecWithSigsTrackFee(_msg))
            )
        );
    }

    function _getDigestRelayContext(
        bytes32 _domainSeparator,
        MessageRelayContext calldata _msg
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeExecWithSigsRelayContext(_msg))
            )
        );
    }

    function _abiEncodeExecWithSigs(
        Message calldata _msg
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                MESSAGE_TYPEHASH,
                _msg.service,
                keccak256(_msg.data),
                _msg.salt,
                _msg.deadline
            );
    }

    function _abiEncodeExecWithSigsFeeCollector(
        MessageFeeCollector calldata _msg
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                MESSAGE_FEE_COLLECTOR_TYPEHASH,
                _msg.service,
                keccak256(_msg.data),
                _msg.salt,
                _msg.deadline,
                _msg.feeToken
            );
    }

    function _abiEncodeExecWithSigsTrackFee(
        MessageTrackFee calldata _msg
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                MESSAGE_TRACK_FEE,
                _msg.service,
                keccak256(_msg.data),
                _msg.salt,
                _msg.deadline,
                _msg.feeToken,
                _msg.isFeeCollector
            );
    }

    function _abiEncodeExecWithSigsRelayContext(
        MessageRelayContext calldata _msg
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                MESSAGE_RELAY_CONTEXT_TYPEHASH,
                _msg.service,
                keccak256(_msg.data),
                _msg.salt,
                _msg.deadline,
                _msg.feeToken,
                _msg.fee
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct ExecWithSigsStorage {
    mapping(bytes32 => bool) wasSignatureUsedAlready;
}

bytes32 constant _EXEC_WITH_SIGS_STORAGE = keccak256(
    "gelato.diamond.execWithSigs.storage"
);

function _wasSignatureUsedAlready(bytes calldata _signature)
    view
    returns (bool)
{
    return
        _execWithSigsStorage().wasSignatureUsedAlready[keccak256(_signature)];
}

function _setWasSignatureUsedAlready(bytes calldata _signature) {
    _execWithSigsStorage().wasSignatureUsedAlready[
        keccak256(_signature)
    ] = true;
}

//solhint-disable-next-line private-vars-leading-underscore
function _execWithSigsStorage()
    pure
    returns (ExecWithSigsStorage storage ewss)
{
    bytes32 position = _EXEC_WITH_SIGS_STORAGE;
    assembly {
        ewss.slot := position
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

using EnumerableSet for EnumerableSet.AddressSet;

struct SignerStorage {
    EnumerableSet.AddressSet executorSigners;
    EnumerableSet.AddressSet checkerSigners;
}

bytes32 constant _SIGNER_STORAGE_POSITION = keccak256(
    "gelato.diamond.signer.storage"
);

function _addExecutorSigner(address _executor) returns (bool) {
    return _signerStorage().executorSigners.add(_executor);
}

function _removeExecutorSigner(address _executor) returns (bool) {
    return _signerStorage().executorSigners.remove(_executor);
}

function _isExecutorSigner(address _executorSigner) view returns (bool) {
    return _signerStorage().executorSigners.contains(_executorSigner);
}

function _executorSignerAt(uint256 _index) view returns (address) {
    return _signerStorage().executorSigners.at(_index);
}

function _executorSigners() view returns (address[] memory) {
    return _signerStorage().executorSigners.values();
}

function _numberOfExecutorSigners() view returns (uint256) {
    return _signerStorage().executorSigners.length();
}

function _addCheckerSigner(address _checker) returns (bool) {
    return _signerStorage().checkerSigners.add(_checker);
}

function _removeCheckerSigner(address _checker) returns (bool) {
    return _signerStorage().checkerSigners.remove(_checker);
}

function _isCheckerSigner(address _checker) view returns (bool) {
    return _signerStorage().checkerSigners.contains(_checker);
}

function _checkerSignerAt(uint256 _index) view returns (address) {
    return _signerStorage().checkerSigners.at(_index);
}

function _checkerSigners() view returns (address[] memory checkers) {
    return _signerStorage().checkerSigners.values();
}

function _numberOfCheckerSigners() view returns (uint256) {
    return _signerStorage().checkerSigners.length();
}

function _signerStorage() pure returns (SignerStorage storage ess) {
    bytes32 position = _SIGNER_STORAGE_POSITION;
    assembly {
        ess.slot := position
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {NATIVE_TOKEN} from "../constants/Tokens.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

function _getBalance(address token, address user) view returns (uint256) {
    if (token == address(0)) return 0;
    return token == NATIVE_TOKEN ? user.balance : IERC20(token).balanceOf(user);
}

function _simulateAndRevert(
    address _service,
    uint256 _gasleft,
    bytes memory _data
) {
    assembly {
        let success := call(
            gas(),
            _service,
            0,
            add(_data, 0x20),
            mload(_data),
            0,
            0
        )

        mstore(0x00, success) // store success bool in first word
        mstore(0x20, sub(_gasleft, gas())) // store gas after success
        mstore(0x40, returndatasize()) // store length of return data size in third word
        returndatacopy(0x60, 0, returndatasize()) // store actual return data in fourth word and onwards
        revert(0, add(returndatasize(), 0x60))
    }
}

function _revert(
    bool _success,
    bytes memory _returndata,
    uint256 _estimatedGasUsed
) pure {
    bytes memory revertData = bytes.concat(
        abi.encode(_success, _estimatedGasUsed, _returndata.length),
        _returndata
    );
    assembly {
        revert(add(32, revertData), mload(revertData))
    }
}

function _revertWithFee(
    bool _success,
    bytes memory _returndata,
    uint256 _estimatedGasUsed,
    uint256 _observedFee
) pure {
    bytes memory revertData = bytes.concat(
        abi.encode(
            _success,
            _estimatedGasUsed,
            _observedFee,
            _returndata.length
        ),
        _returndata
    );
    assembly {
        revert(add(32, revertData), mload(revertData))
    }
}

function _revertWithFeeAndIsFeeCollector(
    bool _success,
    bool _isFeeCollector,
    bytes memory _returndata,
    uint256 _estimatedGasUsed,
    uint256 _observedFee
) pure {
    bytes memory revertData = bytes.concat(
        abi.encode(
            _success,
            _estimatedGasUsed,
            _observedFee,
            _isFeeCollector,
            _returndata.length
        ),
        _returndata
    );
    assembly {
        revert(add(32, revertData), mload(revertData))
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library GelatoBytes {
    function calldataSliceSelector(
        bytes calldata _bytes
    ) internal pure returns (bytes4 selector) {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(
        bytes memory _bytes
    ) internal pure returns (bytes4 selector) {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithError(
        bytes memory _bytes,
        string memory _tracingInfo
    ) internal pure {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"))
                );
            }
        } else {
            revert(
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"))
            );
        }
    }

    function returnError(
        bytes memory _bytes,
        string memory _tracingInfo
    ) internal pure returns (string memory) {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                return string(abi.encodePacked(_tracingInfo, string(_bytes)));
            } else {
                return
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"));
            }
        } else {
            return
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {GelatoBytes} from "./GelatoBytes.sol";

library GelatoCallUtils {
    using GelatoBytes for bytes;

    function revertingContractCall(
        address _contract,
        bytes memory _data,
        string memory _errorMsg
    ) internal returns (bytes memory returndata) {
        bool success;
        (success, returndata) = _contract.call(_data);

        // solhint-disable-next-line max-line-length
        // https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/f9b6fc3fdab7aca33a9cfa8837c5cd7f67e176be/contracts/utils/AddressUpgradeable.sol#L177
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(
                    isContract(_contract),
                    string(abi.encodePacked(_errorMsg, "Call to non contract"))
                );
            }
        } else {
            returndata.revertWithError(_errorMsg);
        }
    }

    // solhint-disable-next-line max-line-length
    // https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/f9b6fc3fdab7aca33a9cfa8837c5cd7f67e176be/contracts/utils/AddressUpgradeable.sol#L36
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library GelatoString {
    function startsWithOK(string memory _str) internal pure returns (bool) {
        if (
            bytes(_str).length >= 2 &&
            bytes(_str)[0] == "O" &&
            bytes(_str)[1] == "K"
        ) return true;
        return false;
    }

    function revertWithInfo(
        string memory _error,
        string memory _tracingInfo
    ) internal pure {
        revert(string(abi.encodePacked(_tracingInfo, _error)));
    }

    function prefix(
        string memory _second,
        string memory _first
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(_first, _second));
    }

    function suffix(
        string memory _first,
        string memory _second
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(_first, _second));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
// solhint-disable max-line-length
// https://github.com/mudgen/diamond-3/blob/b009cd08b7822bad727bbcc47aa1b50d8b50f7f0/contracts/libraries/LibDiamond.sol#L1

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "../../../interfaces/diamond/standard/IDiamondCut.sol";

// Custom due to incorrect string casting (non UTF-8 formatted)
import {GelatoBytes} from "../../../libraries/GelatoBytes.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
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
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function isContractOwner(address _guy) internal view returns (bool) {
        return _guy == contractOwner();
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(oldFacetAddress, selector);
            // add function
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    GelatoBytes.revertWithError(error, "LibDiamondCut:_init:");
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct Message {
    address service;
    bytes data;
    uint256 salt;
    uint256 deadline;
}

struct MessageFeeCollector {
    address service;
    bytes data;
    uint256 salt;
    uint256 deadline;
    address feeToken;
}

struct MessageTrackFee {
    address service;
    bytes data;
    uint256 salt;
    uint256 deadline;
    address feeToken;
    bool isFeeCollector;
}

struct MessageRelayContext {
    address service;
    bytes data;
    uint256 salt;
    uint256 deadline;
    address feeToken;
    uint256 fee;
}

struct ExecWithSigs {
    bytes32 correlationId;
    Message msg;
    bytes executorSignerSig;
    bytes checkerSignerSig;
}

struct ExecWithSigsFeeCollector {
    bytes32 correlationId;
    MessageFeeCollector msg;
    bytes executorSignerSig;
    bytes checkerSignerSig;
}

struct ExecWithSigsTrackFee {
    bytes32 correlationId;
    MessageTrackFee msg;
    bytes executorSignerSig;
    bytes checkerSignerSig;
}

struct ExecWithSigsRelayContext {
    bytes32 correlationId;
    MessageRelayContext msg;
    bytes executorSignerSig;
    bytes checkerSignerSig;
}