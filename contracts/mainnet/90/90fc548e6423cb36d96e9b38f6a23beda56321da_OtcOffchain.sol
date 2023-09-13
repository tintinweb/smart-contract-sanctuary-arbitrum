/**
 *Submitted for verification at Arbiscan.io on 2023-09-13
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
     * ////IMPORTANT: `hash` _must_ be the result of a hash operation for the
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
     * ////IMPORTANT: `hash` _must_ be the result of a hash operation for the
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

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
     * ////IMPORTANT: The same issues {IERC20-approve} has related to transaction
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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

abstract contract TokenFeesManager is ReentrancyGuard, Ownable {
    /// @notice The divisor for fees
    uint256 internal constant _FEES_DIVISOR = 1e8; // Percent with 6 decimals places (2 + 6 = 1e8)

    // The fee applicable to a specific token
    struct FeeEntry {
        uint256 makerFee;  // The fee applied to the maker
        uint256 takerFee;  // The fee applied to the taker
        bool enabled;      // Indicates whether the token is whitelisted or not
    }

    /// @notice The default fee applicable to market makers.
    uint256 public globalMakerFeePercent;

    /// @notice The default fee applicable to market takers.
    uint256 public globalTakerFeePercent;

    /// @notice The fees applicable to a specific token.
    mapping (address => FeeEntry) public fees;

    event OnTokenDisabled(address tokenAddr);
    event OnTokenEnabled(address tokenAddr, uint256 makerFeePercent, uint256 takerFeePercent);
    event OnTokenFeesUpdated(address tokenAddr, uint256 makerFeePercent, uint256 takerFeePercent);
    event OnGlobalFeesUpdated(uint256 newGlobalMakerFeePercent, uint256 newGlobalTakerFeePercent);

    /**
     * @notice Enables the token address specified using the default fees.
     * @param tokenAddr The token address.
     */
    function enableToken(address tokenAddr) external nonReentrant onlyOwner {
        require(tokenAddr != address(0), "Token address required");
        require(!fees[tokenAddr].enabled, "Token already enabled");

        fees[tokenAddr] = FeeEntry(globalMakerFeePercent, globalTakerFeePercent, true);
        emit OnTokenEnabled(tokenAddr, globalMakerFeePercent, globalTakerFeePercent);
    }

    /**
     * @notice Enables a token using the fees specified.
     * @param tokenAddr The token address.
     * @param newMakerFeePercent The fee applied to the market maker, as a percentage with 6 decimal places.
     * @param newTakerFeePercent The fee applied to the market taker, as a percentage with 6 decimal places.
     */
    function enableTokenWithFees(address tokenAddr, uint256 newMakerFeePercent, uint256 newTakerFeePercent) external nonReentrant onlyOwner {
        require(tokenAddr != address(0), "Token address required");
        require(!fees[tokenAddr].enabled, "Token already enabled");
        require(newMakerFeePercent < 100_000000, "Invalid maker fee");
        require(newTakerFeePercent < 100_000000, "Invalid taker fee");

        fees[tokenAddr] = FeeEntry(newMakerFeePercent, newTakerFeePercent, true);
        emit OnTokenEnabled(tokenAddr, newMakerFeePercent, newTakerFeePercent);
    }

    /**
     * @notice Disables the token address specified.
     * @param tokenAddr The token address.
     */
    function disableToken(address tokenAddr) external nonReentrant onlyOwner {
        require(fees[tokenAddr].enabled, "Token not whitelisted");
        delete fees[tokenAddr];
        emit OnTokenDisabled(tokenAddr);
    }

    /**
     * @notice Sets the fees.
     * @param tokenAddr The token address.
     * @param newMakerFeePercent The fee applied to the market maker, as a percentage with 6 decimal places.
     * @param newTakerFeePercent The fee applied to the market taker, as a percentage with 6 decimal places.
     */
    function setTokenFees(address tokenAddr, uint256 newMakerFeePercent, uint256 newTakerFeePercent) external nonReentrant onlyOwner {
        require(fees[tokenAddr].enabled, "Token not whitelisted");
        require(newMakerFeePercent < 100_000000, "Invalid maker fee");
        require(newTakerFeePercent < 100_000000, "Invalid taker fee");

        fees[tokenAddr] = FeeEntry(newMakerFeePercent, newTakerFeePercent, true);
        emit OnTokenFeesUpdated(tokenAddr, newMakerFeePercent, newTakerFeePercent);
    }
    
    /**
     * @notice Indicates if the token specified is whitelisted.
     * @param tokenAddr The token address.
     */
    function isWhitelistedToken(address tokenAddr) public view returns (bool) {
        return fees[tokenAddr].enabled;
    }

    function _setGlobalFees(uint256 newGlobalMakerFeePercent, uint256 newGlobalTakerFeePercent) internal {
        require(newGlobalMakerFeePercent < 100_000000, "Invalid maker fee");
        require(newGlobalTakerFeePercent < 100_000000, "Invalid taker fee");
        
        globalMakerFeePercent = newGlobalMakerFeePercent;
        globalTakerFeePercent = newGlobalTakerFeePercent;
        emit OnGlobalFeesUpdated(newGlobalMakerFeePercent, newGlobalTakerFeePercent);
    }
}

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

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
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
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
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @title OTC contract based on off-chain interactions.
 */
contract OtcOffchain is TokenFeesManager, EIP712 {
    /// @notice The maximum duration of an OTC order.
    /// @dev The order cannot be longer than this.
    uint256 public constant MAX_ORDER_DURATION = 3 days;

    bytes32 private constant _UNSIGNED_ORDER_TYPEHASH = keccak256("UnsignedOrder(bytes32 makerOrderId,uint256 makerAmount,address makerAddress,address makerAsset,uint256 takerAmount,uint256 expiryDate,address takerAddress,address takerAsset)");
    bytes32 private constant _SIGNED_ORDER_TYPEHASH = keccak256("SignedOrderType(bytes32 unsignedOrderHashed,bytes32 rMaker,bytes32 sMaker,uint8 vMaker)");

    // Represents an unsigned order
    struct UnsignedOrder {
        bytes32 makerOrderId;
        uint256 makerAmount;
        address makerAddress;
        address makerAsset;
        uint256 takerAmount;
        uint256 expiryDate;
        address takerAddress;
        address takerAsset;
    }

    // Represents an order signed by the market maker
    struct SignedOrder {
        UnsignedOrder unsignedOrder;
        bytes32 rMaker;
        bytes32 sMaker; 
        uint8 vMaker;
    }

    struct SignedOrderType {
        bytes32 unsignedOrderHashed;
        bytes32 rMaker;
        bytes32 sMaker; 
        uint8 vMaker;
    }

    /// @notice The address of the fees collector
    address public feesAddress;

    /// @notice Indicates whether the contract is paused or not.
    bool public isPaused;

    // Keeps track of the Order IDs used by a given sender.
    mapping (address => mapping (bytes32 => bool)) private _makerIdsUsed;

    // Keeps track of the unsigned hashes submitted to this contract.
    mapping (bytes32 => bool) private _unsignedHashesUsed;

    /// @notice Fires when this contract is paused.
    event OnContractPaused();

    /// @notice Fires when this contract is unpaused.
    event OnContractUnpaused();

    /// @notice Fires when the address for fees gets updated
    event OnFeesAddressUpdated();

    event OnOrderCancelled(bytes32 unsignedOrderHash);

    /**
     * @notice Fires when an OTC swap takes place.
     * @param unsignedOrderHash The unsigned hash of the swap that took place on-chain.
     */
    event OnSwap(bytes32 unsignedOrderHash);

    constructor(
        uint256 newGlobalMakerFeePercent, 
        uint256 newGlobalTakerFeePercent, 
        address newFeesAddress, 
        string memory newDomainName, 
        string memory newDomainVersion
    ) EIP712(newDomainName, newDomainVersion) {
        require(newFeesAddress != address(0), "Invalid Fees address");

        _setGlobalFees(newGlobalMakerFeePercent, newGlobalTakerFeePercent);
        feesAddress = newFeesAddress;
    }

    /// @notice Throws an error if the contract is paused.
    modifier ifPaused() {
        require(isPaused, "Contract not paused");
        _;
    }

    /// @notice Throws an error if the contract is not paused.
    modifier ifNotPaused() {
        require(!isPaused, "Contract paused");
        _;
    }

    /// @notice Pauses the smart contract.
    /// @dev No trades take place until the contract gets unpaused. The contract can be paused/unpaused by the owner only.
    function pause() external nonReentrant ifNotPaused onlyOwner {
        isPaused = true; 
        emit OnContractPaused();
    }

    /// @notice Unpauses the smart contract.
    /// @dev Trading gets resumed as soon as this function is called. The contract can be paused/unpaused by the owner only.
    function unpause() external nonReentrant ifPaused onlyOwner {
        isPaused = false; 
        emit OnContractUnpaused();
    }

    /**
     * @notice Updates the fees address
     * @param newFeesAddress The new address for fees
     */
    function updateFeesAddress(address newFeesAddress) external nonReentrant ifNotPaused onlyOwner {
        require(newFeesAddress != address(0) && newFeesAddress != address(this), "Invalid Fees address");
        require(newFeesAddress != feesAddress, "Fees address already set");

        feesAddress = newFeesAddress;
        emit OnFeesAddressUpdated();
    }

    /**
     * @notice Updates the global fees.
     * @param newGlobalMakerFeePercent The fee applicable to the market maker, as a percentage with 6 decimal places.
     * @param newGlobalTakerFeePercent The fee applicable to the market taker, as a percentage with 6 decimal places.
     */
    function updateGlobalFees(uint256 newGlobalMakerFeePercent, uint256 newGlobalTakerFeePercent) external nonReentrant ifNotPaused onlyOwner {
        _setGlobalFees(newGlobalMakerFeePercent, newGlobalTakerFeePercent);
    }

    /**
     * @notice Takes the order specified.
     * @dev Throws if the the contract is paused.
     * @param order The order to execute. This order was previously signed by the market maker, off-chain.
     * @param rTaker The signature of the taker (R)
     * @param sTaker The signature of the taker (S)
     * @param vTaker The signature of the taker (V)
     */
    function takeOrder(
        SignedOrder calldata order, 
        bytes32 rTaker, 
        bytes32 sTaker, 
        uint8 vTaker
    ) external nonReentrant ifNotPaused {
        // Validate the order
        (bytes32 unsignedOrderHash, address expectedTakerAddress) = _validateOrderParams(order, msg.sender, rTaker, sTaker, vTaker);

        // Calculate the fees applicable to the market maker
        uint256 makerFeePercent = fees[order.unsignedOrder.makerAsset].makerFee;
        uint256 makerFeeAmount = (makerFeePercent == 0) ? 0 : (makerFeePercent * order.unsignedOrder.makerAmount) / _FEES_DIVISOR;
        uint256 requiredMakerAmount = order.unsignedOrder.makerAmount + makerFeeAmount;

        // Calculate the fees applicable to the market taker
        uint256 takerFeePercent = fees[order.unsignedOrder.takerAsset].takerFee;
        uint256 takerFeeAmount = (takerFeePercent == 0) ? 0 : (takerFeePercent * order.unsignedOrder.takerAmount) / _FEES_DIVISOR;
        uint256 requiredTakerAmount = order.unsignedOrder.takerAmount + takerFeeAmount;

        // Mark the hash as "used"
        _unsignedHashesUsed[unsignedOrderHash] = true;
        _makerIdsUsed[order.unsignedOrder.makerAddress][order.unsignedOrder.makerOrderId] = true;

        // Run the atomic swap
        _runSwap(order.unsignedOrder, requiredMakerAmount, requiredTakerAmount, makerFeeAmount, takerFeeAmount, expectedTakerAddress);

        // Emit the event
        emit OnSwap(unsignedOrderHash);
    }

    /**
     * @notice Cancels the signed order specified.
     * @dev Throws if the sender is not the market maker.
     * @param order The order signed by the market maker.
     */
    function cancelOrder(SignedOrder calldata order) external nonReentrant ifNotPaused {
        // Validate the sender
        require(msg.sender == order.unsignedOrder.makerAddress, "Invalid maker");

        // Build the EIP-712 hash of the unsigned order
        bytes32 unsignedOrderHash = hashUnsignedOrder(
            order.unsignedOrder.makerAddress, 
            order.unsignedOrder.makerAsset, 
            order.unsignedOrder.makerAmount, 
            order.unsignedOrder.makerOrderId,
            order.unsignedOrder.takerAddress, 
            order.unsignedOrder.takerAsset, 
            order.unsignedOrder.takerAmount, 
            order.unsignedOrder.expiryDate
        );

        // Make sure the order was signed by the market maker
        require(
            order.unsignedOrder.makerAddress == ECDSA.recover(unsignedOrderHash, order.vMaker, order.rMaker, order.sMaker), 
            "Invalid maker signature"
        );

        require(!_unsignedHashesUsed[unsignedOrderHash], "Order already taken");
        require(!_makerIdsUsed[order.unsignedOrder.makerAddress][order.unsignedOrder.makerOrderId], "Maker ID already used");

        // Make sure the order has not expired
        require(order.unsignedOrder.expiryDate > block.timestamp, "Order expired");

        _unsignedHashesUsed[unsignedOrderHash] = true;
        _makerIdsUsed[order.unsignedOrder.makerAddress][order.unsignedOrder.makerOrderId] = true;

        emit OnOrderCancelled(unsignedOrderHash);
    }

    /**
     * @notice Transfers the ownership of this contract to the address specified.
     * @dev Throws if the contract is paused and/or the address specified is considered invalid.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public override nonReentrant ifNotPaused onlyOwner {
        require(newOwner != address(0) && newOwner != address(this), "Invalid owner");
        _transferOwnership(newOwner);
    }

    /**
     * @notice Lets a maket maker know if a given brand new order is valid at this point in time.
     * @dev Throws an error if the unsigned order is invalid.
     * @param makerAddress The address of the market maker.
     * @param makerAsset The address of the market asset.
     * @param makerAmount The amount to be swapped by the market maker.
     * @param makerOrderId The uniquely identifiable ID of the order provided by the market maker. Fails if the order is already used.
     * @param takerAddress The address of the market taker. Use the zero address if the order can be taken by anyone.
     * @param takerAsset The address of the taker asset.
     * @param takerAmount The amount to be swapped by the market taker.
     * @param expiryDate The expiry date of the OTC order.
     * @return Returns the unsigned hash of the order.
     */
    function canCreateUnsignedOrder(
        address makerAddress,
        address makerAsset,
        uint256 makerAmount,
        bytes32 makerOrderId,
        address takerAddress,
        address takerAsset,
        uint256 takerAmount,
        uint256 expiryDate
    ) external view returns (bytes32) {
        // Validate amounts
        require(makerAmount > 0 && takerAmount > 0, "Order amounts required");

        // Validate the address of both maker and taker
        require(makerAddress == msg.sender && msg.sender != address(this) && msg.sender != address(0), "Invalid maker address");
        require(takerAddress != address(this), "Invalid taker address");
        require(makerAddress != takerAddress, "Maker and taker cannot be the same");

        // Validate the synthetic pair
        require(makerAsset != takerAsset, "Invalid synthetic pair");

        // Make sure the synthetic pair is whitelisted
        require(fees[makerAsset].enabled, "Maker asset not whitelisted");
        require(fees[takerAsset].enabled, "Taker asset not whitelisted");

        // Make sure the order has not expired
        require(expiryDate > block.timestamp, "Order expired");
        require(expiryDate - block.timestamp <= MAX_ORDER_DURATION, "Expiry date too long");

        // Replay protection
        require(makerOrderId != bytes32(0), "Maker Order ID required");
        require(!_makerIdsUsed[makerAddress][makerOrderId], "Maker ID already used");

        // Build the EIP-712 hash of the unsigned order
        bytes32 unsignedOrderHash = hashUnsignedOrder(
            makerAddress, 
            makerAsset, 
            makerAmount, 
            makerOrderId,
            takerAddress, 
            takerAsset, 
            takerAmount, 
            expiryDate
        );

        require(!_unsignedHashesUsed[unsignedOrderHash], "Order already taken");

        return unsignedOrderHash;
    }

    /**
     * @notice Indicates if the signed order specified can be taken.
     * @dev Throws an error if the order cannot be taken.
     * @param order The order signed by the market maker.
     * @param rTaker The signature of the taker (R)
     * @param sTaker The signature of the taker (S)
     * @param vTaker The signature of the taker (V)
     * @return Returns true if the order can be taken. Throws an error otherwise.
     */
    function canTakeOrder(SignedOrder calldata order, bytes32 rTaker, bytes32 sTaker, uint8 vTaker) external view ifNotPaused returns (bool) {
        // Validate the order
        (, address expectedTakerAddress) = _validateOrderParams(order, msg.sender, rTaker, sTaker, vTaker);

        // Calculate the fees applicable to the market maker
        uint256 makerFeeAmount = calculateMakerFees(order.unsignedOrder.makerAsset, order.unsignedOrder.makerAmount);
        uint256 requiredMakerAmount = order.unsignedOrder.makerAmount + makerFeeAmount;

        // Calculate the fees applicable to the market taker
        uint256 takerFeeAmount = calculateTakerFees(order.unsignedOrder.takerAsset, order.unsignedOrder.takerAmount);
        uint256 requiredTakerAmount = order.unsignedOrder.takerAmount + takerFeeAmount;

        _enforceBalanceAndAllowance(order.unsignedOrder, requiredMakerAmount, requiredTakerAmount, expectedTakerAddress);

        return true;
    }

    /**
     * @notice Calculates the fees applicable to the market maker for a given asset, if any.
     * @dev The fee amount can be zero.
     * @param makerAsset The asset offered by the market maker.
     * @param makerAmount The asset amount offered by the market maker.
     * @return Returns the fee applicable to the market maker, per maker asset decimals.
     */
    function calculateMakerFees(address makerAsset, uint256 makerAmount) public view returns (uint256) {
        uint256 makerFeePercent = fees[makerAsset].makerFee;
        return (makerFeePercent == 0) ? 0 : (makerFeePercent * makerAmount) / _FEES_DIVISOR;
    }

    /**
     * @notice Calculates the fees applicable to the market taker for a given asset, if any.
     * @dev The fee amount can be zero.
     * @param takerAsset The asset provided by the market taker.
     * @param takerAmount The asset amount provided by the market taker.
     * @return Returns the fee applicable to the market taker, per taker asset decimals.
     */
    function calculateTakerFees(address takerAsset, uint256 takerAmount) public view returns (uint256) {
        uint256 takerFeePercent = fees[takerAsset].takerFee;
        return (takerFeePercent == 0) ? 0 : (takerFeePercent * takerAmount) / _FEES_DIVISOR;
    }

    /**
     * @notice Builds the EIP-712 hash of the unsigned order specified.
     * @param makerAddress The address of the market maker.
     * @param makerAsset The address of the market asset.
     * @param makerAmount The amount to be swapped by the market maker.
     * @param makerOrderId The uniquely identifiable ID of the order provided by the market maker. Fails if the order is already used.
     * @param takerAddress The address of the market taker. Use the zero address if the order can be taken by anyone.
     * @param takerAsset The address of the taker asset.
     * @param takerAmount The amount to be swapped by the market taker.
     * @param expiryDate The expiry date of the OTC order.
     * @return Returns the hash of the unsigned order, per EIP-712.
     */
    function hashUnsignedOrder(
        address makerAddress,
        address makerAsset,
        uint256 makerAmount,
        bytes32 makerOrderId,
        address takerAddress,
        address takerAsset,
        uint256 takerAmount,
        uint256 expiryDate
    ) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _UNSIGNED_ORDER_TYPEHASH,
                    makerOrderId,
                    makerAmount,
                    makerAddress,
                    makerAsset,
                    takerAmount,
                    expiryDate,
                    takerAddress,
                    takerAsset
                )
            )
        );
    }

    /**
     * @notice Builds the EIP-712 hash of the signed order specified.
     * @param unsignedOrder The unsigned order forged by the market maker.
     * @param rMaker The signature of the market maker (R)
     * @param sMaker The signature of the market maker (S)
     * @param vMaker The signature of the market maker (V)
     * @return Returns the hash of the signed order, per EIP-712.
     */
    function hashSignedOrder(
        UnsignedOrder calldata unsignedOrder,
        bytes32 rMaker, 
        bytes32 sMaker, 
        uint8 vMaker
    ) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _SIGNED_ORDER_TYPEHASH,
                    hashUnsignedOrder(unsignedOrder.makerAddress, unsignedOrder.makerAsset, unsignedOrder.makerAmount, unsignedOrder.makerOrderId, unsignedOrder.takerAddress, unsignedOrder.takerAsset, unsignedOrder.takerAmount, unsignedOrder.expiryDate),
                    rMaker,
                    sMaker,
                    vMaker
                )
            )
        );
    }

    function _ensureDeposit(IERC20 token, address fromAddr, uint256 amount, string memory errorMsg) private {
        uint256 balanceBefore = token.balanceOf(address(this));
        SafeERC20.safeTransferFrom(token, fromAddr, address(this), amount);
        require(token.balanceOf(address(this)) == balanceBefore + amount, errorMsg);
    }

    // Runs the atomic swap of the OTC order specified.
    function _runSwap(
        UnsignedOrder calldata unsignedOrder, 
        uint256 requiredMakerAmount, 
        uint256 requiredTakerAmount, 
        uint256 makerFeeAmount, 
        uint256 takerFeeAmount,
        address expectedTakerAddress
    ) private {
        // Check balance and allowance on the maker and taker sides
        _enforceBalanceAndAllowance(unsignedOrder, requiredMakerAmount, requiredTakerAmount, expectedTakerAddress);

        // Make sure the maker and taker deposit the respective asset/funds into this contract
        _ensureDeposit(IERC20(unsignedOrder.makerAsset), unsignedOrder.makerAddress, requiredMakerAmount, "Maker deposit failed");
        _ensureDeposit(IERC20(unsignedOrder.takerAsset), expectedTakerAddress, requiredTakerAmount, "Taker deposit failed");

        // Apply fees
        if (makerFeeAmount > 0) SafeERC20.safeTransfer(IERC20(unsignedOrder.makerAsset), feesAddress, makerFeeAmount);
        if (takerFeeAmount > 0) SafeERC20.safeTransfer(IERC20(unsignedOrder.takerAsset), feesAddress, takerFeeAmount);

        // Transfer the respective asset/funds to the maker and taker
        SafeERC20.safeTransfer(IERC20(unsignedOrder.takerAsset), unsignedOrder.makerAddress, unsignedOrder.takerAmount);
        SafeERC20.safeTransfer(IERC20(unsignedOrder.makerAsset), expectedTakerAddress, unsignedOrder.makerAmount);
    }

    function _validateOrderParams(
        SignedOrder calldata order, 
        address senderAddr, 
        bytes32 rTaker, 
        bytes32 sTaker, 
        uint8 vTaker
    ) private view returns (bytes32 unsignedOrderHash, address expectedTakerAddress) {
        // Validate the sender
        require(senderAddr != address(0) && senderAddr != address(this) && senderAddr != order.unsignedOrder.makerAddress, "Invalid sender");
        expectedTakerAddress = (order.unsignedOrder.takerAddress == address(0)) ? senderAddr : order.unsignedOrder.takerAddress;

        // Validate amounts
        require(order.unsignedOrder.makerAmount > 0 && order.unsignedOrder.takerAmount > 0, "Order amounts required");

        // Validate the address of both maker and taker
        require(order.unsignedOrder.makerAddress != address(this) && order.unsignedOrder.makerAddress != address(0), "Invalid maker address");
        require(senderAddr == expectedTakerAddress, "Invalid taker address");
        require(order.unsignedOrder.makerAddress != order.unsignedOrder.takerAddress, "Maker and taker cannot be the same");

        // Validate the synthetic pair
        require(order.unsignedOrder.makerAsset != order.unsignedOrder.takerAsset, "Invalid synthetic pair");

        // Make sure the synthetic pair is whitelisted
        require(fees[order.unsignedOrder.makerAsset].enabled, "Maker asset not whitelisted");
        require(fees[order.unsignedOrder.takerAsset].enabled, "Taker asset not whitelisted");

        // Build the EIP-712 hash of the unsigned order
        unsignedOrderHash = hashUnsignedOrder(
            order.unsignedOrder.makerAddress, 
            order.unsignedOrder.makerAsset, 
            order.unsignedOrder.makerAmount, 
            order.unsignedOrder.makerOrderId,
            order.unsignedOrder.takerAddress, 
            order.unsignedOrder.takerAsset, 
            order.unsignedOrder.takerAmount, 
            order.unsignedOrder.expiryDate
        );

        // Make sure the order was signed by the market maker
        require(
            order.unsignedOrder.makerAddress == ECDSA.recover(unsignedOrderHash, order.vMaker, order.rMaker, order.sMaker), 
            "Invalid maker signature"
        );

        // Make sure the order has not expired
        require(order.unsignedOrder.expiryDate > block.timestamp, "Order expired");
        require(order.unsignedOrder.expiryDate - block.timestamp <= MAX_ORDER_DURATION, "Expiry date too long");

        // Replay protection
        require(order.unsignedOrder.makerOrderId != bytes32(0), "Maker Order ID required");
        require(!_unsignedHashesUsed[unsignedOrderHash], "Order already taken");
        require(!_makerIdsUsed[order.unsignedOrder.makerAddress][order.unsignedOrder.makerOrderId], "Maker ID already used");

        if (order.unsignedOrder.takerAddress != address(0)) {
            // Build the EIP-712 hash of the maker order. This hash must be signed by the market taker.
            bytes32 makerOrderHash = hashSignedOrder(order.unsignedOrder, order.rMaker, order.sMaker, order.vMaker);

            // Make sure the order was signed by the market taker
            require(
                order.unsignedOrder.takerAddress == ECDSA.recover(makerOrderHash, vTaker, rTaker, sTaker), 
                "Invalid taker signature"
            );
        }

        return (unsignedOrderHash, expectedTakerAddress);
    }

    function _enforceBalanceAndAllowance(
        UnsignedOrder calldata unsignedOrder,
        uint256 requiredMakerAmount, 
        uint256 requiredTakerAmount,
        address expectedTakerAddress
    ) private view {
        require(
            IERC20(unsignedOrder.makerAsset).allowance(unsignedOrder.makerAddress, address(this)) >= requiredMakerAmount, 
            "Insufficient allowance: maker"
        );

        require(
            IERC20(unsignedOrder.takerAsset).allowance(expectedTakerAddress, address(this)) >= requiredTakerAmount, 
            "Insufficient allowance: taker"
        );

        require(IERC20(unsignedOrder.makerAsset).balanceOf(unsignedOrder.makerAddress) >= requiredMakerAmount, "Insufficient balance: maker");
        require(IERC20(unsignedOrder.takerAsset).balanceOf(expectedTakerAddress) >= requiredTakerAmount, "Insufficient balance: taker");
    }
}