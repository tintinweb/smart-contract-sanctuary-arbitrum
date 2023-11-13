// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
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

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
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

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
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

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
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

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
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

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
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

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

//============================================================================================//
//                                        GLOBAL TYPES                                        //
//============================================================================================//

/// @notice Actions to trigger state changes in the kernel. Passed by the executor
enum Actions {
    InstallModule,
    UpgradeModule,
    ActivatePolicy,
    DeactivatePolicy,
    ChangeExecutor,
    MigrateKernel
}

/// @notice Used by executor to select an action and a target contract for a kernel action
struct Instruction {
    Actions action;
    address target;
}

/// @notice Used to define which module functions a policy needs access to
struct Permissions {
    Keycode keycode;
    bytes4 funcSelector;
}

type Keycode is bytes5;

//============================================================================================//
//                                       UTIL FUNCTIONS                                       //
//============================================================================================//

error TargetNotAContract(address target_);
error InvalidKeycode(Keycode keycode_);

// solhint-disable-next-line func-visibility
function toKeycode(bytes5 keycode_) pure returns (Keycode) {
    return Keycode.wrap(keycode_);
}

// solhint-disable-next-line func-visibility
function fromKeycode(Keycode keycode_) pure returns (bytes5) {
    return Keycode.unwrap(keycode_);
}

// solhint-disable-next-line func-visibility
function ensureContract(address target_) view {
    if (target_.code.length == 0) revert TargetNotAContract(target_);
}

// solhint-disable-next-line func-visibility
function ensureValidKeycode(Keycode keycode_) pure {
    bytes5 unwrapped = Keycode.unwrap(keycode_);

    for (uint256 i = 0; i < 5; ) {
        bytes1 char = unwrapped[i];
        if (char < 0x41 || char > 0x5A) revert InvalidKeycode(keycode_); // A-Z only
        unchecked {
            i++;
        }
    }
}

//============================================================================================//
//                                        COMPONENTS                                          //
//============================================================================================//

/// @notice Generic adapter interface for kernel access in modules and policies.
abstract contract KernelAdapter {
    error KernelAdapter_OnlyKernel(address caller_);

    Kernel public kernel;

    constructor(Kernel kernel_) {
        kernel = kernel_;
    }

    /// @notice Modifier to restrict functions to be called only by kernel.
    modifier onlyKernel() {
        if (msg.sender != address(kernel)) revert KernelAdapter_OnlyKernel(msg.sender);
        _;
    }

    /// @notice Function used by kernel when migrating to a new kernel.
    function changeKernel(Kernel newKernel_) external onlyKernel {
        kernel = newKernel_;
    }
}

/// @notice Base level extension of the kernel. Modules act as independent state components to be
///         interacted with and mutated through policies.
/// @dev    Modules are installed and uninstalled via the executor.
abstract contract Module is KernelAdapter {
    error Module_PolicyNotPermitted(address policy_);

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    /// @notice Modifier to restrict which policies have access to module functions.
    modifier permissioned() {
        if (!kernel.modulePermissions(KEYCODE(), Policy(msg.sender), msg.sig))
            revert Module_PolicyNotPermitted(msg.sender);
        _;
    }

    /// @notice 5 byte identifier for a module.
    function KEYCODE() public pure virtual returns (Keycode) {}

    /// @notice Returns which semantic version of a module is being implemented.
    /// @return major - Major version upgrade indicates breaking change to the interface.
    /// @return minor - Minor version change retains backward-compatible interface.
    function VERSION() external pure virtual returns (uint8 major, uint8 minor) {}

    /// @notice Initialization function for the module
    /// @dev    This function is called when the module is installed or upgraded by the kernel.
    /// @dev    MUST BE GATED BY onlyKernel. Used to encompass any initialization or upgrade logic.
    function INIT() external virtual onlyKernel {}
}

/// @notice Policies are application logic and external interface for the kernel and installed modules.
/// @dev    Policies are activated and deactivated in the kernel by the executor.
/// @dev    Module dependencies and function permissions must be defined in appropriate functions.
abstract contract Policy is KernelAdapter {
    error Policy_ModuleDoesNotExist(Keycode keycode_);

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    /// @notice Easily accessible indicator for if a policy is activated or not.
    function isActive() external view returns (bool) {
        return kernel.isPolicyActive(this);
    }

    /// @notice Function to grab module address from a given keycode.
    function getModuleAddress(Keycode keycode_) internal view returns (address) {
        address moduleForKeycode = address(kernel.getModuleForKeycode(keycode_));
        if (moduleForKeycode == address(0)) revert Policy_ModuleDoesNotExist(keycode_);
        return moduleForKeycode;
    }

    /// @notice Define module dependencies for this policy.
    /// @return dependencies - Keycode array of module dependencies.
    function configureDependencies() external virtual returns (Keycode[] memory dependencies) {}

    /// @notice Function called by kernel to set module function permissions.
    /// @return requests - Array of keycodes and function selectors for requested permissions.
    function requestPermissions() external view virtual returns (Permissions[] memory requests) {}
}

/// @notice Main contract that acts as a central component registry for the protocol.
/// @dev    The kernel manages modules and policies. The kernel is mutated via predefined Actions,
/// @dev    which are input from any address assigned as the executor. The executor can be changed as needed.
contract Kernel {
    // =========  EVENTS ========= //

    event PermissionsUpdated(
        Keycode indexed keycode_,
        Policy indexed policy_,
        bytes4 funcSelector_,
        bool granted_
    );
    event ActionExecuted(Actions indexed action_, address indexed target_);

    // =========  ERRORS ========= //

    error Kernel_OnlyExecutor(address caller_);
    error Kernel_ModuleAlreadyInstalled(Keycode module_);
    error Kernel_InvalidModuleUpgrade(Keycode module_);
    error Kernel_PolicyAlreadyActivated(address policy_);
    error Kernel_PolicyNotActivated(address policy_);

    // =========  PRIVILEGED ADDRESSES ========= //

    /// @notice Address that is able to initiate Actions in the kernel. Can be assigned to a multisig or governance contract.
    address public executor;

    // =========  MODULE MANAGEMENT ========= //

    /// @notice Array of all modules currently installed.
    Keycode[] public allKeycodes;

    /// @notice Mapping of module address to keycode.
    mapping(Keycode => Module) public getModuleForKeycode;

    /// @notice Mapping of keycode to module address.
    mapping(Module => Keycode) public getKeycodeForModule;

    /// @notice Mapping of a keycode to all of its policy dependents. Used to efficiently reconfigure policy dependencies.
    mapping(Keycode => Policy[]) public moduleDependents;

    /// @notice Helper for module dependent arrays. Prevents the need to loop through array.
    mapping(Keycode => mapping(Policy => uint256)) public getDependentIndex;

    /// @notice Module <> Policy Permissions.
    /// @dev    Keycode -> Policy -> Function Selector -> bool for permission
    mapping(Keycode => mapping(Policy => mapping(bytes4 => bool))) public modulePermissions;

    // =========  POLICY MANAGEMENT ========= //

    /// @notice List of all active policies
    Policy[] public activePolicies;

    /// @notice Helper to get active policy quickly. Prevents need to loop through array.
    mapping(Policy => uint256) public getPolicyIndex;

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    constructor() {
        executor = msg.sender;
    }

    /// @notice Modifier to check if caller is the executor.
    modifier onlyExecutor() {
        if (msg.sender != executor) revert Kernel_OnlyExecutor(msg.sender);
        _;
    }

    function isPolicyActive(Policy policy_) public view returns (bool) {
        return activePolicies.length > 0 && activePolicies[getPolicyIndex[policy_]] == policy_;
    }

    /// @notice Main kernel function. Initiates state changes to kernel depending on Action passed in.
    function executeAction(Actions action_, address target_) external onlyExecutor {
        if (action_ == Actions.InstallModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _installModule(Module(target_));
        } else if (action_ == Actions.UpgradeModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _upgradeModule(Module(target_));
        } else if (action_ == Actions.ActivatePolicy) {
            ensureContract(target_);
            _activatePolicy(Policy(target_));
        } else if (action_ == Actions.DeactivatePolicy) {
            ensureContract(target_);
            _deactivatePolicy(Policy(target_));
        } else if (action_ == Actions.ChangeExecutor) {
            executor = target_;
        } else if (action_ == Actions.MigrateKernel) {
            ensureContract(target_);
            _migrateKernel(Kernel(target_));
        }

        emit ActionExecuted(action_, target_);
    }

    function _installModule(Module newModule_) internal {
        Keycode keycode = newModule_.KEYCODE();

        if (address(getModuleForKeycode[keycode]) != address(0))
            revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
        allKeycodes.push(keycode);

        newModule_.INIT();
    }

    function _upgradeModule(Module newModule_) internal {
        Keycode keycode = newModule_.KEYCODE();
        Module oldModule = getModuleForKeycode[keycode];

        if (address(oldModule) == address(0) || oldModule == newModule_)
            revert Kernel_InvalidModuleUpgrade(keycode);

        getKeycodeForModule[oldModule] = Keycode.wrap(bytes5(0));
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        newModule_.INIT();

        _reconfigurePolicies(keycode);
    }

    function _activatePolicy(Policy policy_) internal {
        if (isPolicyActive(policy_)) revert Kernel_PolicyAlreadyActivated(address(policy_));

        // Add policy to list of active policies
        activePolicies.push(policy_);
        getPolicyIndex[policy_] = activePolicies.length - 1;

        // Record module dependencies
        Keycode[] memory dependencies = policy_.configureDependencies();
        uint256 depLength = dependencies.length;

        for (uint256 i; i < depLength; ) {
            Keycode keycode = dependencies[i];

            moduleDependents[keycode].push(policy_);
            getDependentIndex[keycode][policy_] = moduleDependents[keycode].length - 1;

            unchecked {
                ++i;
            }
        }

        // Grant permissions for policy to access restricted module functions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, true);
    }

    function _deactivatePolicy(Policy policy_) internal {
        if (!isPolicyActive(policy_)) revert Kernel_PolicyNotActivated(address(policy_));

        // Revoke permissions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, false);

        // Remove policy from all policy data structures
        uint256 idx = getPolicyIndex[policy_];
        Policy lastPolicy = activePolicies[activePolicies.length - 1];

        activePolicies[idx] = lastPolicy;
        activePolicies.pop();
        getPolicyIndex[lastPolicy] = idx;
        delete getPolicyIndex[policy_];

        // Remove policy from module dependents
        _pruneFromDependents(policy_);
    }

    /// @notice All functionality will move to the new kernel. WARNING: ACTION WILL BRICK THIS KERNEL.
    /// @dev    New kernel must add in all of the modules and policies via executeAction.
    /// @dev    NOTE: Data does not get cleared from this kernel.
    function _migrateKernel(Kernel newKernel_) internal {
        uint256 keycodeLen = allKeycodes.length;
        for (uint256 i; i < keycodeLen; ) {
            Module module = Module(getModuleForKeycode[allKeycodes[i]]);
            module.changeKernel(newKernel_);
            unchecked {
                ++i;
            }
        }

        uint256 policiesLen = activePolicies.length;
        for (uint256 j; j < policiesLen; ) {
            Policy policy = activePolicies[j];

            // Deactivate before changing kernel
            policy.changeKernel(newKernel_);
            unchecked {
                ++j;
            }
        }
    }

    function _reconfigurePolicies(Keycode keycode_) internal {
        Policy[] memory dependents = moduleDependents[keycode_];
        uint256 depLength = dependents.length;

        for (uint256 i; i < depLength; ) {
            dependents[i].configureDependencies();

            unchecked {
                ++i;
            }
        }
    }

    function _setPolicyPermissions(
        Policy policy_,
        Permissions[] memory requests_,
        bool grant_
    ) internal {
        uint256 reqLength = requests_.length;
        for (uint256 i = 0; i < reqLength; ) {
            Permissions memory request = requests_[i];
            modulePermissions[request.keycode][policy_][request.funcSelector] = grant_;

            emit PermissionsUpdated(request.keycode, policy_, request.funcSelector, grant_);

            unchecked {
                ++i;
            }
        }
    }

    function _pruneFromDependents(Policy policy_) internal {
        Keycode[] memory dependencies = policy_.configureDependencies();
        uint256 depcLength = dependencies.length;

        for (uint256 i; i < depcLength; ) {
            Keycode keycode = dependencies[i];
            Policy[] storage dependents = moduleDependents[keycode];

            uint256 origIndex = getDependentIndex[keycode][policy_];
            Policy lastPolicy = dependents[dependents.length - 1];

            // Swap with last and pop
            dependents[origIndex] = lastPolicy;
            dependents.pop();

            // Record new index and delete deactivated policy index
            getDependentIndex[keycode][lastPolicy] = origIndex;
            delete getDependentIndex[keycode][policy_];

            unchecked {
                ++i;
            }
        }
    }
}

pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20, SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";

/// @notice contract to burn receipt token in exchange for underlying token 1:1
/// @dev this contract is useful
contract RedeemReceipt is Ownable {
    using SafeTransferLib for ERC20;

    event Redeem(address indexed who, uint256 amount);
    event Paused(bool paused);

    /// @notice pauses redeem functionality
    bool public paused;
    /// @notice receipt token to burn for underlying token 1:1
    ERC20 public immutable receiptToken;
    /// @notice underlying token to credit for burning receipt token 1:1
    ERC20 public immutable underlyingToken;

    constructor(address owner_, ERC20 receiptToken_, ERC20 underlyingToken_) Ownable() {
        _transferOwnership(owner_);
        receiptToken = receiptToken_;
        underlyingToken = underlyingToken_;

        paused = true;

        // sanity check to prevent improper setup
        if (
            receiptToken.totalSupply() > underlyingToken.totalSupply() ||
            receiptToken.decimals() != underlyingToken.decimals()
        ) revert("wrong token order");
    }

    /// @notice burns sender's balance of recipt token and transfers underlying token to sender
    function redeemReceipt() external {
        if (paused) revert("paused");

        uint256 redeemAmount = receiptToken.balanceOf(msg.sender);

        receiptToken.safeTransferFrom(msg.sender, address(0), redeemAmount);
        underlyingToken.safeTransfer(msg.sender, redeemAmount);

        emit Redeem(msg.sender, redeemAmount);
    }

    /// @notice Auth gated function to be able to withdraw an arbitrary ERC20 token
    function ownerWithdrawToken(
        ERC20 token,
        uint256 amount
    ) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
    }

    /// @notice allows owner to pause redeems
    function ownerPause() external onlyOwner {
        paused = true;
        emit Paused(true);
    }

    /// @notice allows owner to unpause redeems
    function ownerUnpause() external onlyOwner {
        paused = false;
        emit Paused(false);
    }
}

// SPDX-License-Identifier: BUSL1.1
pragma solidity ^0.8.0;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {Kernel, Module, Keycode} from "src/Default2/src/Kernel.sol";


contract GMBL is ERC20, Module {
    error GMBL_Mint_MaxSupplyExceeded();

    /// @notice maximum totalSupply
    uint256 public maxSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 maxSupply_,
        Kernel kernel_
    ) ERC20(name_, symbol_, decimals_) Module(kernel_) {
        maxSupply = maxSupply_;
    }

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("GMBLE");
    }

    /// @notice Default-compatible permissioned mint for token module
    /// @param to Address to be credited minted supply
    /// @param amount Amount to credit
    function mint(address to, uint256 amount) external permissioned {
        _mint(to, amount);
    }

    /// @notice Burn `amount` of msg.sender's tokens
    /// @param amount Amount to burn
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @notice Custom implementation of Solmate ERC20 `mint`
    /// @dev totalSupply cannot exceed maximum supply
    /// @param to Address to mint to
    /// @param amount Amount to mint
    function _mint(address to, uint256 amount) internal override {
        totalSupply += amount;

        if (totalSupply > maxSupply) revert GMBL_Mint_MaxSupplyExceeded();

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }
}

// SPDX-License-Identifier: BUSL1.1
pragma solidity ^0.8.0;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {Kernel, Module, Keycode} from "src/Default2/src/Kernel.sol";

/// @notice receipt GMBL token to keep underlying GMBL liquidity pools virgin
contract RGMBL is ERC20, Module {
    error RGMBL_Mint_MaxSupplyExceeded();

    /// @notice maximum totalSupply

    uint256 public maxSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 maxSupply_,
        Kernel kernel_
    ) ERC20(name_, symbol_, decimals_) Module(kernel_) {
        maxSupply = maxSupply_;
    }

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("RGMBL");
    }

    /// @notice Default-compatible permissioned mint for token module
    /// @param to Address to be credited minted supply
    /// @param amount Amount to credit
    function mint(address to, uint256 amount) external permissioned {
        _mint(to, amount);
    }

    /// @notice Burn `amount` of msg.sender's tokens
    /// @param amount Amount to burn

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @notice Custom implementation of Solmate ERC20 `mint`
    /// @dev totalSupply cannot exceed maximum supply
    /// @param to Address to mint to
    /// @param amount Amount to mint
    function _mint(address to, uint256 amount) internal override {
        totalSupply += amount;

        if (totalSupply > maxSupply) revert RGMBL_Mint_MaxSupplyExceeded();

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal override {
        balanceOf[from] -= amount;
        totalSupply -= amount;

        emit Transfer(from, address(0), amount);
    }
}

pragma solidity ^0.8.0;

import {SafeTransferLib, ERC20} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {Kernel, Module, Keycode} from "src/Default2/src/Kernel.sol";

contract HOUSE is Module {
    using SafeTransferLib for ERC20;

    event Deposit(address indexed who, address indexed token, uint256 amount);
    event Withdrawal(address indexed who, address indexed token, uint256 amount);

    constructor(Kernel _kernel) Module(_kernel) {}

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("HOUSE");
    }

    /********************************************/
    /************** USER-FACTING ****************/
    /********************************************/

    /// @notice Deposits `amount` of `token` on behalf of `from`
    /// @dev tracks `balanceBefore` and `balanceAfter` in the event a whitelisted token has fee on transfer enabled
    function depositERC20(
        ERC20 token,
        address from,
        uint256 amount
    ) external permissioned {
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(from, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));

        emit Deposit(from, address(token), balanceAfter - balanceBefore);
    }

    /// @notice Deposits `msg.value` on behalf of `from`
    function depositNative(address from) external payable permissioned {
        emit Deposit(from, address(0), msg.value);
    }

    /// @notice Withdraws `amount` of ERC20 `token` on behalf of `to`
    function withdrawERC20(
        ERC20 token,
        address to,
        uint256 amount
    ) external permissioned {
        token.safeTransfer(to, amount);
        emit Withdrawal(to, address(token), amount);
    }

    /// @notice Withdraws `amount` of native token on behalf of `to`
    /// @dev Only EOAs are reccomended to interact as a user with the house, hence using transfer
    function withdrawNative(
        address payable to,
        uint256 amount
    ) external permissioned {
        to.transfer(amount);
        emit Withdrawal(to, address(0), amount);
    }

    /********************************************/
    /************** OWNER LOGIC *****************/
    /********************************************/

    /// @notice Same as ownerWithdrawERC20(), but does not update internal balance accounting. *unsafe*
    function ownerEmergencyWithdrawERC20(
        ERC20 token,
        address to,
        uint256 amount
    ) external permissioned {
        token.safeTransfer(to, amount);
    }

    /// @notice Same as ownerWithdrawNative(), but does not update internal balance accounting. *unsafe*
    function ownerEmergencyWithdrawalNative(
        address payable to,
        uint256 amount
    ) external permissioned {
        SafeTransferLib.safeTransferETH(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";

interface IRewardsV2 {
  function distributedTokensLength() external view returns (uint256);
  function distributedToken(uint256 index) external view returns (address);
  function isDistributedToken(address token) external view returns (bool);
  function addRewardsToPending(ERC20 token, address distributor, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IxGMBLToken {
  function usageAllocations(address userAddress) external view returns (uint256 allocation);

  function allocateFromUsage(address userAddress, uint256 amount) external;
  function convertTo(uint256 amount, address to) external;
  function deallocateFromUsage(address userAddress, uint256 amount) external;

  function isTransferWhitelisted(address account) external view returns (bool);
  function getGMBL() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IxGMBLTokenUsage {
    function allocate(address userAddress, uint256 amount, bytes calldata data) external;
    function deallocate(address userAddress, uint256 amount, bytes calldata data) external;
    function usersAllocation(address userAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.8.0;

// Math lib for more readable math

library SafeMath {

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeTransferLib, ERC20} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";
import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {SafeMath} from "../libraries/SafeMath.sol";

import "../interfaces/IRewardsV2.sol";
import {IxGMBLToken} from "../interfaces/IxGMBLToken.sol";
import {IxGMBLTokenUsage} from "../interfaces/IxGMBLTokenUsage.sol";

import {Kernel, Module, Keycode} from "src/Default2/src/Kernel.sol";

/*
 * This contract is used to distribute Rewards to users that allocated xGMBL here
 *
 * Rewards can be distributed in the form of one or more tokens
 * They are mainly managed to be received from the FeeManager contract, but other sources can be added (dev wallet for instance)
 *
 * The freshly received Rewards are stored in a pending slot
 *
 * The content of this pending slot will be progressively transferred over time into a distribution slot
 * This distribution slot is the source of the Rewards distribution to xGMBL allocators during the current cycle
 *
 * This transfer from the pending slot to the distribution slot is based on cycleRewardsPercent and CYCLE_PERIOD_SECONDS
 *
 */
contract REWRD is ReentrancyGuard, Module, IxGMBLTokenUsage, IRewardsV2 {
    using SafeTransferLib for ERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct UserInfo {
        uint256 pendingRewards;
        uint256 rewardDebt;
    }

    /// @dev token => user => UserInfo
    mapping(address => mapping(address => UserInfo)) public users;

    struct RewardsInfo {
        uint256 currentDistributionAmount; // total amount to distribute during the current cycle
        uint256 currentCycleDistributedAmount; // amount already distributed for the current cycle (times 1e2)
        uint256 pendingAmount; // total amount in the pending slot, not distributed yet
        uint256 distributedAmount; // total amount that has been distributed since initialization
        uint256 accRewardsPerShare; // accumulated rewards per share (times 1e18)
        uint256 lastUpdateTime; // last time the rewards distribution occurred
        uint256 cycleRewardsPercent; // fixed part of the pending rewards to assign to currentDistributionAmount on every cycle
        uint256 autoLockPercent; // percent of pendingRewards to convertTo xGBML and re-allocate for this usage
        bool distributionDisabled; // deactivate a token distribution (for temporary rewards)
    }

    /// @dev token => RewardsInfo global rewards info for a token
    mapping(address => RewardsInfo) public rewardsInfo;

    /// @dev actively distributed tokens
    EnumerableSet.AddressSet private _distributedTokens;
    uint256 public constant MAX_DISTRIBUTED_TOKENS = 10;

    /// @dev xGMBLToken contract
    address public immutable xGMBLToken;

    /// @dev User's xGMBL allocation
    mapping(address => uint256) public usersAllocation;

    /// @dev Contract's total xGMBL allocation
    uint256 public totalAllocation;

    /// @dev minimum cycle rewards pct can be set to to avoid rounding errors
    uint256 public constant MIN_CYCLE_REWARDS_PERCENT = 1; // 0.01%

    /// @dev default cycle rewards pct
    uint256 public constant DEFAULT_CYCLE_REWARDS_PERCENT = 100; // 1%

    /// @dev maximum cycle rewards pct mathematically allowable
    uint256 public constant MAX_CYCLE_REWARDS_PERCENT = 10000; // 100%

    // Rewards will be added to the currentDistributionAmount on each new cycle
    uint256 internal _cycleDurationSeconds = 15 minutes;
    uint256 public currentCycleStartTime;

    constructor(
        address xGMBLToken_,
        uint256 startTime_,
        Kernel kernel_
    ) Module(kernel_) {
        if (xGMBLToken_ == address(0)) revert REWRD_ZeroAddress();
        xGMBLToken = xGMBLToken_;
        currentCycleStartTime = startTime_;
    }

    /********************************************/
    /****************** ERRORS ******************/
    /********************************************/

    error REWRD_ZeroAddress();
    error REWRD_DistributedTokenIndexExists();
    error REWRD_DistributedTokenDoesNotExist();
    error REWRD_CallerNotXGMBL();
    error REWRD_HarvestRewardsInvalidToken();
    error REWRD_EmergencyWithdraw_TokenBalanceZero();
    error REWRD_TooManyDsitributedTokens();
    error REWRD_RewardsPercentOutOfRange();
    error REWRD_CannotRemoveDistributedToken();
    error REWRD_DistributedTokenAlreadyEnabled();
    error REWRD_DistributedTokenAlreadyDisabled();

    /********************************************/
    /****************** EVENTS ******************/
    /********************************************/

    event UserUpdated(
        address indexed user,
        uint256 previousBalance,
        uint256 newBalance
    );
    event RewardsCollected(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event CycleRewardsPercentUpdated(
        address indexed token,
        uint256 previousValue,
        uint256 newValue
    );
    event RewardsAddedToPending(address indexed token, uint256 amount);
    event DistributedTokenDisabled(address indexed token);
    event DistributedTokenRemoved(address indexed token);
    event DistributedTokenEnabled(address indexed token);

    /***********************************************/
    /****************** MODIFIERS ******************/
    /***********************************************/

    /// @dev Checks if an index exists
    modifier validateDistributedTokensIndex(uint256 index) {
        if (index >= _distributedTokens.length())
            revert REWRD_DistributedTokenIndexExists();
        _;
    }

    /// @dev Checks if token exists
    modifier validateDistributedToken(address token) {
        if (!_distributedTokens.contains(token))
            revert REWRD_DistributedTokenDoesNotExist();
        _;
    }

    /// @dev Checks if caller is the xGMBLToken contract
    modifier xGMBLTokenOnly() {
        if (msg.sender != xGMBLToken) revert REWRD_CallerNotXGMBL();
        _;
    }

    /*******************************************/
    /****************** VIEWS ******************/
    /*******************************************/

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("REWRD");
    }

    /// @notice length of rewards dsitribution cycles in seconds
    function cycleDurationSeconds() external view returns (uint256) {
        return _cycleDurationSeconds;
    }

    /// @notice  Returns the number of Rewards tokens
    function distributedTokensLength()
        external
        view
        override
        returns (uint256)
    {
        return _distributedTokens.length();
    }

    /// @notice Returns rewards token address from given `index`
    function distributedToken(
        uint256 index
    )
        external
        view
        override
        validateDistributedTokensIndex(index)
        returns (address)
    {
        return address(_distributedTokens.at(index));
    }

    /// @notice Returns true if given token is a rewards `token`
    function isDistributedToken(
        address token
    ) external view override returns (bool) {
        return _distributedTokens.contains(token);
    }

    /// @notice Returns time at which the next cycle will start
    function nextCycleStartTime() public view returns (uint256) {
        return currentCycleStartTime + _cycleDurationSeconds;
    }

    /// @notice Returns `userAddress`'s unclaimed rewards of a given `token`
    function pendingRewardsAmount(
        address token,
        address userAddress
    ) external view returns (uint256) {
        if (totalAllocation == 0) {
            return 0;
        }

        RewardsInfo storage RewardsInfo_ = rewardsInfo[token];

        uint256 accRewardsPerShare = RewardsInfo_.accRewardsPerShare;
        uint256 lastUpdateTime = RewardsInfo_.lastUpdateTime;
        uint256 rewardAmountPerSecond_ = _RewardsAmountPerSecond(token);

        // check if the current cycle has changed since last update
        if (_currentBlockTimestamp() > nextCycleStartTime()) {
            accRewardsPerShare = accRewardsPerShare.add(
                (nextCycleStartTime().sub(lastUpdateTime))
                    .mul(rewardAmountPerSecond_)
                    .mul(1e16)
                    .div(totalAllocation)
            );

            lastUpdateTime = nextCycleStartTime();

            // div cycle rewards pct and cycle duration first
            rewardAmountPerSecond_ = RewardsInfo_
                .pendingAmount
                .mul(RewardsInfo_.cycleRewardsPercent)
                .div(100)
                .div(_cycleDurationSeconds);
        }

        // get pending rewards from current cycle
        accRewardsPerShare = accRewardsPerShare.add(
            (_currentBlockTimestamp().sub(lastUpdateTime))
                .mul(rewardAmountPerSecond_)
                .mul(1e16)
                .div(totalAllocation)
        );

        return
            usersAllocation[userAddress]
                .mul(accRewardsPerShare)
                .div(1e18)
                .sub(users[token][userAddress].rewardDebt)
                .add(users[token][userAddress].pendingRewards);
    }

    /**************************************************/
    /**************** PUBLIC FUNCTIONS ****************/
    /**************************************************/

    /// @notice Updates the current cycle start time if previous cycle has ended
    function updateCurrentCycleStartTime() public {
        uint256 nextCycleStartTime_ = nextCycleStartTime();

        if (_currentBlockTimestamp() >= nextCycleStartTime_) {
            currentCycleStartTime = nextCycleStartTime_;
        }
    }

    /// @notice Updates rewards info for a given `token`
    /// @dev anyone can call this to "poke" the state, updating internal accounting
    function updateRewardsInfo(
        address token
    ) external validateDistributedToken(token) {
        _updateRewardsInfo(token);
    }

    /// @notice Updates rewards info for all active distribution tokens
    /// @dev Anyone can call this to "poke" the state, updating internal accounting
    function massUpdateRewardsInfo() external {
        uint256 length = _distributedTokens.length();
        for (uint256 index = 0; index < length; ++index) {
            _updateRewardsInfo(_distributedTokens.at(index));
        }
    }

    /// @notice Harvests caller's pending Rewards of a given `token`
    function harvestRewards(address account, address token) external nonReentrant permissioned {
        if (!_distributedTokens.contains(token)) {
            if (rewardsInfo[token].distributedAmount == 0)
                revert REWRD_HarvestRewardsInvalidToken();
        }

        _harvestRewards(account, token);
    }

    /// @notice Harvests all caller's pending Rewards
    function harvestAllRewards(address account) external nonReentrant permissioned {
        uint256 length = _distributedTokens.length();
        for (uint256 index = 0; index < length; ++index) {
            _harvestRewards(account, _distributedTokens.at(index));
        }
    }

    /**************************************************/
    /*************** OWNABLE FUNCTIONS ****************/
    /**************************************************/

    /**
     * @notice Allocates `userAddress`'s `amount` of xGMBL to this Rewards contract
     * @dev Can only be called by xGMBLToken contract, which is trusted to verify amounts
     *
     * data Unused - to conform to IxGMBLTokenUsage
     */
    function allocate(
        address userAddress,
        uint256 amount,
        bytes calldata /*data*/
    ) external override nonReentrant xGMBLTokenOnly {
        uint256 newUserAllocation = usersAllocation[userAddress] + amount;
        uint256 newTotalAllocation = totalAllocation + amount;

        _updateUser(userAddress, newUserAllocation, newTotalAllocation);
    }

    /**
     * @notice Deallocates `userAddress`'s `amount` of xGMBL allocation from this Rewards contract
     * @dev Can only be called by xGMBLToken contract, which is trusted to verify amounts
     *
     * data Unused - to conform to IxGMBLTokenUsage
     */
    function deallocate(
        address userAddress,
        uint256 amount,
        bytes calldata /*data*/
    ) external override nonReentrant xGMBLTokenOnly {
        uint256 newUserAllocation = usersAllocation[userAddress] - amount;
        uint256 newTotalAllocation = totalAllocation - amount;

        _updateUser(userAddress, newUserAllocation, newTotalAllocation);
    }

    /// @notice Enables a given `token` to be distributed as rewards
    /// @dev Effective from the next cycle
    function enableDistributedToken(address token) external permissioned {
        RewardsInfo storage RewardsInfo_ = rewardsInfo[token];
        if (
            RewardsInfo_.lastUpdateTime > 0 &&
            !RewardsInfo_.distributionDisabled
        ) revert REWRD_DistributedTokenAlreadyEnabled();

        if (_distributedTokens.length() >= MAX_DISTRIBUTED_TOKENS)
            revert REWRD_TooManyDsitributedTokens();

        // initialize lastUpdateTime if never set before
        if (RewardsInfo_.lastUpdateTime == 0) {
            RewardsInfo_.lastUpdateTime = _currentBlockTimestamp();
        }
        // initialize cycleRewardsPercent to the minimum if never set before
        if (RewardsInfo_.cycleRewardsPercent == 0) {
            RewardsInfo_.cycleRewardsPercent = DEFAULT_CYCLE_REWARDS_PERCENT;
        }
        RewardsInfo_.distributionDisabled = false;
        _distributedTokens.add(token);
        emit DistributedTokenEnabled(token);
    }

    /// @notice Disables distribution of a given `token` as rewards
    /// @dev Effective from the next cycle
    function disableDistributedToken(address token) external permissioned {
        RewardsInfo storage RewardsInfo_ = rewardsInfo[token];

        if (
            RewardsInfo_.lastUpdateTime == 0 ||
            RewardsInfo_.distributionDisabled
        ) revert REWRD_DistributedTokenAlreadyDisabled();

        RewardsInfo_.distributionDisabled = true;
        emit DistributedTokenDisabled(token);
    }

    /// @notice Updates the `percent`-age of pending rewards `token` that will be distributed during the next cycle
    /// @dev Must be a value between MIN_CYCLE_REWARDS_PERCENT and MAX_CYCLE_REWARDS_PERCENT bps (1-10000)
    function updateCycleRewardsPercent(
        address token,
        uint256 percent
    ) external permissioned {
        if (
            percent > MAX_CYCLE_REWARDS_PERCENT ||
            percent < MIN_CYCLE_REWARDS_PERCENT
        ) revert REWRD_RewardsPercentOutOfRange();

        RewardsInfo storage RewardsInfo_ = rewardsInfo[token];
        uint256 previousPercent = RewardsInfo_.cycleRewardsPercent;
        RewardsInfo_.cycleRewardsPercent = percent;

        emit CycleRewardsPercentUpdated(
            token,
            previousPercent,
            RewardsInfo_.cycleRewardsPercent
        );
    }

    function updateAutoLockPercent(
        address token,
        uint256 percent
    ) external permissioned validateDistributedToken(token) {
        if (percent > 10000) revert("With custom error here > 100%");

        RewardsInfo storage RewardsInfo_ = rewardsInfo[token];
        uint256 previousPercent = RewardsInfo_.autoLockPercent;
        RewardsInfo_.autoLockPercent = percent;

        // emit AutoLockPercentUpdated(token, previousPercent, percent);
    }


    /// @notice Remove an address `tokenToRemove` from _distributedTokens
    /// @dev Can only be valid for a disabled Rewards token and if the distribution has ended
    function removeTokenFromDistributedTokens(
        address tokenToRemove
    ) external permissioned {
        RewardsInfo storage _RewardsInfo = rewardsInfo[tokenToRemove];

        if (
            !_RewardsInfo.distributionDisabled ||
            _RewardsInfo.currentDistributionAmount > 0
        ) revert REWRD_CannotRemoveDistributedToken();

        _distributedTokens.remove(tokenToRemove);
        emit DistributedTokenRemoved(tokenToRemove);
    }

    /// @notice Transfers the given amount of `token` from `distributor` to pendingAmount on behalf of `distributor`
    function addRewardsToPending(
        ERC20 token,
        address distributor,
        uint256 amount
    ) external override nonReentrant permissioned {
        uint256 prevTokenBalance = token.balanceOf(address(this));
        RewardsInfo storage RewardsInfo_ = rewardsInfo[address(token)];

        token.safeTransferFrom(distributor, address(this), amount);

        // handle tokens with transfer tax
        uint256 receivedAmount = token.balanceOf(address(this)) -
            prevTokenBalance;
        RewardsInfo_.pendingAmount += receivedAmount;

        emit RewardsAddedToPending(address(token), receivedAmount);
    }

    /// @notice Emergency withdraw `token`'s balance on the contract to `receiver`
    function emergencyWithdraw(
        ERC20 token,
        address receiver
    ) public nonReentrant permissioned {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) revert REWRD_EmergencyWithdraw_TokenBalanceZero();
        _safeTokenTransfer(token, receiver, balance);
    }

    /// @notice Emergency withdraw all reward tokens' balances on the contract to `receiver`
    function emergencyWithdrawAll(
        address receiver
    ) external nonReentrant permissioned {
        for (uint256 index = 0; index < _distributedTokens.length(); ++index) {
            emergencyWithdraw(ERC20(_distributedTokens.at(index)), receiver);
        }
    }

    /********************************************************/
    /****************** INTERNAL FUNCTIONS ******************/
    /********************************************************/

    /// @dev Returns the amount of Rewards token distributed every second (times 1e2)
    function _RewardsAmountPerSecond(
        address token
    ) internal view returns (uint256) {
        if (!_distributedTokens.contains(token)) return 0;
        return
            rewardsInfo[token].currentDistributionAmount.mul(1e2).div(
                _cycleDurationSeconds
            );
    }

    /// @dev Updates every user's rewards allocation for each distributed token
    function _updateRewardsInfo(address token) internal {
        uint256 currentBlockTimestamp = _currentBlockTimestamp();
        RewardsInfo storage RewardsInfo_ = rewardsInfo[token];

        updateCurrentCycleStartTime();

        uint256 lastUpdateTime = RewardsInfo_.lastUpdateTime;
        uint256 accRewardsPerShare = RewardsInfo_.accRewardsPerShare;

        if (currentBlockTimestamp <= lastUpdateTime) {
            return;
        }

        // if no xGMBL is allocated or initial distribution has not started yet
        if (
            totalAllocation == 0 ||
            currentBlockTimestamp < currentCycleStartTime
        ) {
            RewardsInfo_.lastUpdateTime = currentBlockTimestamp;
            return;
        }

        uint256 currentDistributionAmount = RewardsInfo_
            .currentDistributionAmount; // gas saving
        uint256 currentCycleDistributedAmount = RewardsInfo_
            .currentCycleDistributedAmount; // gas saving

        // check if the current cycle has changed since last update
        if (lastUpdateTime < currentCycleStartTime) {
            // update accrewardPerShare for the end of the previous cycle
            accRewardsPerShare = accRewardsPerShare.add(
                (
                    currentDistributionAmount.mul(1e2).sub(
                        currentCycleDistributedAmount
                    )
                ).mul(1e16).div(totalAllocation)
            );

            // check if distribution is enabled
            if (!RewardsInfo_.distributionDisabled) {
                // transfer the token's cycleRewardsPercent part from the pending slot to the distribution slot
                RewardsInfo_.distributedAmount += currentDistributionAmount;

                uint256 pendingAmount = RewardsInfo_.pendingAmount;
                currentDistributionAmount = pendingAmount
                    .mul(RewardsInfo_.cycleRewardsPercent)
                    .div(10000);

                RewardsInfo_
                    .currentDistributionAmount = currentDistributionAmount;
                RewardsInfo_.pendingAmount =
                    pendingAmount -
                    currentDistributionAmount;
            } else {
                // stop the token's distribution on next cycle
                RewardsInfo_.distributedAmount += currentDistributionAmount;
                currentDistributionAmount = 0;
                RewardsInfo_.currentDistributionAmount = 0;
            }

            currentCycleDistributedAmount = 0;
            lastUpdateTime = currentCycleStartTime;
        }

        uint256 toDistribute = currentBlockTimestamp.sub(lastUpdateTime).mul(
            _RewardsAmountPerSecond(token)
        );

        // ensure that we can't distribute more than currentDistributionAmount (for instance w/ a > 24h service interruption)
        if (
            currentCycleDistributedAmount + toDistribute >
            currentDistributionAmount * 1e2
        ) {
            toDistribute = currentDistributionAmount.mul(1e2).sub(
                currentCycleDistributedAmount
            );
        }

        RewardsInfo_.currentCycleDistributedAmount =
            currentCycleDistributedAmount +
            toDistribute;
        RewardsInfo_.accRewardsPerShare = accRewardsPerShare.add(
            toDistribute.mul(1e16).div(totalAllocation)
        );
        RewardsInfo_.lastUpdateTime = currentBlockTimestamp;
    }

    /// @dev Updates "userAddress" user's and total allocations for each distributed token
    function _updateUser(
        address userAddress,
        uint256 newUserAllocation,
        uint256 newTotalAllocation
    ) internal {
        uint256 previousUserAllocation = usersAllocation[userAddress];

        // for each distributedToken
        uint256 length = _distributedTokens.length();

        for (uint256 index = 0; index < length; ++index) {
            address token = _distributedTokens.at(index);
            _updateRewardsInfo(token);

            UserInfo storage user = users[token][userAddress];
            uint256 accRewardsPerShare = rewardsInfo[token].accRewardsPerShare;

            uint256 pending = previousUserAllocation
                .mul(accRewardsPerShare)
                .div(1e18)
                .sub(user.rewardDebt);

            user.pendingRewards += pending;
            user.rewardDebt = newUserAllocation.mul(accRewardsPerShare).div(
                1e18
            );
        }

        usersAllocation[userAddress] = newUserAllocation;
        totalAllocation = newTotalAllocation;

        emit UserUpdated(
            userAddress,
            previousUserAllocation,
            newUserAllocation
        );
    }

    /// @dev Harvests msg.sender's pending Rewards of a given token
    function _harvestRewards(address account, address token) internal {
        _updateRewardsInfo(token);

        UserInfo storage user = users[token][account];
        uint256 accRewardsPerShare = rewardsInfo[token].accRewardsPerShare;

        uint256 userxGMBLAllocation = usersAllocation[account];

        uint256 pending = user.pendingRewards.add(
            userxGMBLAllocation.mul(accRewardsPerShare).div(1e18).sub(
                user.rewardDebt
            )
        );

        _safeTokenTransfer(ERC20(token), account, pending);
        // Re-stake current autoLock ratio of pending rewards
        if (token == IxGMBLToken(xGMBLToken).getGMBL()) {
            uint256 relock = pending
                .mul(rewardsInfo[token].autoLockPercent)
                .div(10000);

            if (relock > 0) {
                pending -= relock;

                IxGMBLToken(xGMBLToken).convertTo(relock, account);
                IxGMBLToken(xGMBLToken).allocateFromUsage(account, relock);
            }
        }

        user.pendingRewards = 0;
        user.rewardDebt = userxGMBLAllocation.mul(accRewardsPerShare).div(1e18);


        emit RewardsCollected(account, token, pending);
    }

    /// @dev Safe token transfer function, in case rounding error causes pool to not have enough tokens
    function _safeTokenTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            uint256 tokenBal = token.balanceOf(address(this));
            if (amount > tokenBal) {
                token.safeTransfer(to, tokenBal);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    /// @dev Utility function to get the current block timestamp
    function _currentBlockTimestamp() internal view virtual returns (uint256) {
        /* solhint-disable not-rely-on-time */
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeTransferLib, ERC20} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";
import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {SafeMath} from "../libraries/SafeMath.sol";

import "../interfaces/IRewardsV2.sol";
import {IxGMBLToken} from "../interfaces/IxGMBLToken.sol";
import {IxGMBLTokenUsage} from "../interfaces/IxGMBLTokenUsage.sol";

import {Kernel, Module, Keycode} from "src/Default2/src/Kernel.sol";

/*
 * This contract is used to distribute Rewards to users that allocated xGMBL here
 *
 * Rewards can be distributed in the form of one or more tokens
 * They are mainly managed to be received from the FeeManager contract, but other sources can be added (dev wallet for instance)
 *
 * The freshly received Rewards are stored in a pending slot
 *
 * The content of this pending slot will be progressively transferred over time into a distribution slot
 * This distribution slot is the source of the Rewards distribution to xGMBL allocators during the current cycle
 *
 * This transfer from the pending slot to the distribution slot is based on cycleRewardsPercent and CYCLE_PERIOD_SECONDS
 *
 */
contract REWRDV2 is ReentrancyGuard, Module, IxGMBLTokenUsage, IRewardsV2 {
    using SafeTransferLib for ERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct UserInfo {
        uint256 pendingRewards;
        uint256 rewardDebt;
    }

    /// @dev token => user => UserInfo
    mapping(address => mapping(address => UserInfo)) public users;

    struct RewardsInfo {
        uint256 currentDistributionAmount; // total amount to distribute during the current cycle
        uint256 currentCycleDistributedAmount; // amount already distributed for the current cycle (times 1e2)
        uint256 pendingAmount; // total amount in the pending slot, not distributed yet
        uint256 distributedAmount; // total amount that has been distributed since initialization
        uint256 accRewardsPerShare; // accumulated rewards per share (times 1e18)
        uint256 lastUpdateTime; // last time the rewards distribution occurred
        uint256 cycleRewardsPercent; // fixed part of the pending rewards to assign to currentDistributionAmount on every cycle
        uint256 autoLockPercent; // percent of pendingRewards to convertTo xGBML and re-allocate for this usage
        bool distributionDisabled; // deactivate a token distribution (for temporary rewards)
    }

    /// @dev token => RewardsInfo global rewards info for a token
    mapping(address => RewardsInfo) public rewardsInfo;

    /// @dev actively distributed tokens
    EnumerableSet.AddressSet private _distributedTokens;
    uint256 public constant MAX_DISTRIBUTED_TOKENS = 10;

    /// @dev xGMBLToken contract
    address public immutable xGMBLToken;

    /// @dev User's xGMBL allocation
    mapping(address => uint256) public usersAllocation;

    /// @dev Contract's total xGMBL allocation
    uint256 public totalAllocation;

    /// @dev minimum cycle rewards pct can be set to to avoid rounding errors
    uint256 public constant MIN_CYCLE_REWARDS_PERCENT = 1; // 0.01%

    /// @dev default cycle rewards pct
    uint256 public constant DEFAULT_CYCLE_REWARDS_PERCENT = 100; // 1%

    /// @dev maximum cycle rewards pct mathematically allowable
    uint256 public constant MAX_CYCLE_REWARDS_PERCENT = 10000; // 100%

    // Rewards will be added to the currentDistributionAmount on each new cycle
    uint256 internal _cycleDurationSeconds = 15 minutes;
    uint256 public currentCycleStartTime;

    constructor(
        address xGMBLToken_,
        uint256 startTime_,
        Kernel kernel_
    ) Module(kernel_) {
        if (xGMBLToken_ == address(0)) revert REWRD_ZeroAddress();
        xGMBLToken = xGMBLToken_;
        currentCycleStartTime = startTime_;
    }

    /********************************************/
    /****************** ERRORS ******************/
    /********************************************/

    error REWRD_ZeroAddress();
    error REWRD_DistributedTokenIndexExists();
    error REWRD_DistributedTokenDoesNotExist();
    error REWRD_CallerNotXGMBL();
    error REWRD_HarvestRewardsInvalidToken();
    error REWRD_EmergencyWithdraw_TokenBalanceZero();
    error REWRD_TooManyDsitributedTokens();
    error REWRD_RewardsPercentOutOfRange();
    error REWRD_CannotRemoveDistributedToken();
    error REWRD_DistributedTokenAlreadyEnabled();
    error REWRD_DistributedTokenAlreadyDisabled();

    /********************************************/
    /****************** EVENTS ******************/
    /********************************************/

    event UserUpdated(
        address indexed user,
        uint256 previousBalance,
        uint256 newBalance
    );
    event RewardsCollected(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event CycleRewardsPercentUpdated(
        address indexed token,
        uint256 previousValue,
        uint256 newValue
    );
    event RewardsAddedToPending(address indexed token, uint256 amount);
    event DistributedTokenDisabled(address indexed token);
    event DistributedTokenRemoved(address indexed token);
    event DistributedTokenEnabled(address indexed token);
    event AutoLockPercentUpdated(address indexed token, uint256 previousPercent, uint256 percent);

    /***********************************************/
    /****************** MODIFIERS ******************/
    /***********************************************/

    /// @dev Checks if an index exists
    modifier validateDistributedTokensIndex(uint256 index) {
        if (index >= _distributedTokens.length())
            revert REWRD_DistributedTokenIndexExists();
        _;
    }

    /// @dev Checks if token exists
    modifier validateDistributedToken(address token) {
        if (!_distributedTokens.contains(token))
            revert REWRD_DistributedTokenDoesNotExist();
        _;
    }

    /// @dev Checks if caller is the xGMBLToken contract
    modifier xGMBLTokenOnly() {
        if (msg.sender != xGMBLToken) revert REWRD_CallerNotXGMBL();
        _;
    }

    /*******************************************/
    /****************** VIEWS ******************/
    /*******************************************/

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("RWRD2");
    }

    /// @notice length of rewards dsitribution cycles in seconds
    function cycleDurationSeconds() external view returns (uint256) {
        return _cycleDurationSeconds;
    }

    /// @notice  Returns the number of Rewards tokens
    function distributedTokensLength()
        external
        view
        override
        returns (uint256)
    {
        return _distributedTokens.length();
    }

    /// @notice Returns rewards token address from given `index`
    function distributedToken(
        uint256 index
    )
        external
        view
        override
        validateDistributedTokensIndex(index)
        returns (address)
    {
        return address(_distributedTokens.at(index));
    }

    /// @notice Returns true if given token is a rewards `token`
    function isDistributedToken(
        address token
    ) external view override returns (bool) {
        return _distributedTokens.contains(token);
    }

    /// @notice Returns time at which the next cycle will start
    function nextCycleStartTime() public view returns (uint256) {
        return currentCycleStartTime + _cycleDurationSeconds;
    }

    /// @notice Returns `userAddress`'s unclaimed rewards of a given `token`
    function pendingRewardsAmount(
        address token,
        address userAddress
    ) external view returns (uint256) {
        if (totalAllocation == 0) {
            return 0;
        }

        RewardsInfo storage RewardsInfo_ = rewardsInfo[token];

        uint256 accRewardsPerShare = RewardsInfo_.accRewardsPerShare;
        uint256 lastUpdateTime = RewardsInfo_.lastUpdateTime;
        uint256 rewardAmountPerSecond_ = _RewardsAmountPerSecond(token);

        // check if the current cycle has changed since last update
        if (_currentBlockTimestamp() > nextCycleStartTime()) {
            accRewardsPerShare = accRewardsPerShare.add(
                (nextCycleStartTime().sub(lastUpdateTime))
                    .mul(rewardAmountPerSecond_)
                    .mul(1e16)
                    .div(totalAllocation)
            );

            lastUpdateTime = nextCycleStartTime();

            // div cycle rewards pct and cycle duration first
            rewardAmountPerSecond_ = RewardsInfo_
                .pendingAmount
                .mul(RewardsInfo_.cycleRewardsPercent)
                .div(100)
                .div(_cycleDurationSeconds);
        }

        // get pending rewards from current cycle
        accRewardsPerShare = accRewardsPerShare.add(
            (_currentBlockTimestamp().sub(lastUpdateTime))
                .mul(rewardAmountPerSecond_)
                .mul(1e16)
                .div(totalAllocation)
        );

        return
            usersAllocation[userAddress]
                .mul(accRewardsPerShare)
                .div(1e18)
                .sub(users[token][userAddress].rewardDebt)
                .add(users[token][userAddress].pendingRewards);
    }

    /**************************************************/
    /**************** PUBLIC FUNCTIONS ****************/
    /**************************************************/

    /// @notice Updates the current cycle start time if previous cycle has ended
    function updateCurrentCycleStartTime() public {
        uint256 nextCycleStartTime_ = nextCycleStartTime();

        if (_currentBlockTimestamp() >= nextCycleStartTime_) {
            currentCycleStartTime = nextCycleStartTime_;
        }
    }

    /// @notice Updates rewards info for a given `token`
    /// @dev anyone can call this to "poke" the state, updating internal accounting
    function updateRewardsInfo(
        address token
    ) external validateDistributedToken(token) {
        _updateRewardsInfo(token);
    }

    /// @notice Updates rewards info for all active distribution tokens
    /// @dev Anyone can call this to "poke" the state, updating internal accounting
    function massUpdateRewardsInfo() external {
        uint256 length = _distributedTokens.length();
        for (uint256 index = 0; index < length; ++index) {
            _updateRewardsInfo(_distributedTokens.at(index));
        }
    }

    /// @notice Harvests caller's pending Rewards of a given `token`
    function harvestRewards(address account, address token) external nonReentrant permissioned {
        if (!_distributedTokens.contains(token)) {
            if (rewardsInfo[token].distributedAmount == 0)
                revert REWRD_HarvestRewardsInvalidToken();
        }

        _harvestRewards(account, token);
    }

    /// @notice Harvests all caller's pending Rewards
    function harvestAllRewards(address account) external nonReentrant permissioned {
        uint256 length = _distributedTokens.length();
        for (uint256 index = 0; index < length; ++index) {
            _harvestRewards(account, _distributedTokens.at(index));
        }
    }

    /**************************************************/
    /*************** OWNABLE FUNCTIONS ****************/
    /**************************************************/

    /**
     * @notice Allocates `userAddress`'s `amount` of xGMBL to this Rewards contract
     * @dev Can only be called by xGMBLToken contract, which is trusted to verify amounts
     *
     * data Unused - to conform to IxGMBLTokenUsage
     */
    function allocate(
        address userAddress,
        uint256 amount,
        bytes calldata /*data*/
    ) external override nonReentrant xGMBLTokenOnly {
        uint256 newUserAllocation = usersAllocation[userAddress] + amount;
        uint256 newTotalAllocation = totalAllocation + amount;

        _updateUser(userAddress, newUserAllocation, newTotalAllocation);
    }

    /**
     * @notice Deallocates `userAddress`'s `amount` of xGMBL allocation from this Rewards contract
     * @dev Can only be called by xGMBLToken contract, which is trusted to verify amounts
     *
     * data Unused - to conform to IxGMBLTokenUsage
     */
    function deallocate(
        address userAddress,
        uint256 amount,
        bytes calldata /*data*/
    ) external override nonReentrant xGMBLTokenOnly {
        uint256 newUserAllocation = usersAllocation[userAddress] - amount;
        uint256 newTotalAllocation = totalAllocation - amount;

        _updateUser(userAddress, newUserAllocation, newTotalAllocation);
    }

    /// @notice Enables a given `token` to be distributed as rewards
    /// @dev Effective from the next cycle
    function enableDistributedToken(address token) external permissioned {
        RewardsInfo storage RewardsInfo_ = rewardsInfo[token];
        if (
            RewardsInfo_.lastUpdateTime > 0 &&
            !RewardsInfo_.distributionDisabled
        ) revert REWRD_DistributedTokenAlreadyEnabled();

        if (_distributedTokens.length() >= MAX_DISTRIBUTED_TOKENS)
            revert REWRD_TooManyDsitributedTokens();

        // initialize lastUpdateTime if never set before
        if (RewardsInfo_.lastUpdateTime == 0) {
            RewardsInfo_.lastUpdateTime = _currentBlockTimestamp();
        }
        // initialize cycleRewardsPercent to the minimum if never set before
        if (RewardsInfo_.cycleRewardsPercent == 0) {
            RewardsInfo_.cycleRewardsPercent = DEFAULT_CYCLE_REWARDS_PERCENT;
        }
        RewardsInfo_.distributionDisabled = false;
        _distributedTokens.add(token);
        emit DistributedTokenEnabled(token);
    }

    /// @notice Disables distribution of a given `token` as rewards
    /// @dev Effective from the next cycle
    function disableDistributedToken(address token) external permissioned {
        RewardsInfo storage RewardsInfo_ = rewardsInfo[token];

        if (
            RewardsInfo_.lastUpdateTime == 0 ||
            RewardsInfo_.distributionDisabled
        ) revert REWRD_DistributedTokenAlreadyDisabled();

        RewardsInfo_.distributionDisabled = true;
        emit DistributedTokenDisabled(token);
    }

    /// @notice Updates the `percent`-age of pending rewards `token` that will be distributed during the next cycle
    /// @dev Must be a value between MIN_CYCLE_REWARDS_PERCENT and MAX_CYCLE_REWARDS_PERCENT bps (1-10000)
    function updateCycleRewardsPercent(
        address token,
        uint256 percent
    ) external permissioned {
        if (
            percent > MAX_CYCLE_REWARDS_PERCENT ||
            percent < MIN_CYCLE_REWARDS_PERCENT
        ) revert REWRD_RewardsPercentOutOfRange();

        RewardsInfo storage RewardsInfo_ = rewardsInfo[token];
        uint256 previousPercent = RewardsInfo_.cycleRewardsPercent;
        RewardsInfo_.cycleRewardsPercent = percent;

        emit CycleRewardsPercentUpdated(
            token,
            previousPercent,
            RewardsInfo_.cycleRewardsPercent
        );
    }

    function updateAutoLockPercent(
        address token,
        uint256 percent
    ) external permissioned validateDistributedToken(token) {
        if (percent > 10000) revert("With custom error here > 100%");

        RewardsInfo storage RewardsInfo_ = rewardsInfo[token];
        uint256 previousPercent = RewardsInfo_.autoLockPercent;
        RewardsInfo_.autoLockPercent = percent;

        emit AutoLockPercentUpdated(token, previousPercent, percent);
    }


    /// @notice Remove an address `tokenToRemove` from _distributedTokens
    /// @dev Can only be valid for a disabled Rewards token and if the distribution has ended
    function removeTokenFromDistributedTokens(
        address tokenToRemove
    ) external permissioned {
        RewardsInfo storage _RewardsInfo = rewardsInfo[tokenToRemove];

        if (
            !_RewardsInfo.distributionDisabled ||
            _RewardsInfo.currentDistributionAmount > 0
        ) revert REWRD_CannotRemoveDistributedToken();

        _distributedTokens.remove(tokenToRemove);
        emit DistributedTokenRemoved(tokenToRemove);
    }

    /// @notice Transfers the given amount of `token` from `distributor` to pendingAmount on behalf of `distributor`
    function addRewardsToPending(
        ERC20 token,
        address distributor,
        uint256 amount
    ) external override nonReentrant permissioned {
        uint256 prevTokenBalance = token.balanceOf(address(this));
        RewardsInfo storage RewardsInfo_ = rewardsInfo[address(token)];

        token.safeTransferFrom(distributor, address(this), amount);

        // handle tokens with transfer tax
        uint256 receivedAmount = token.balanceOf(address(this)) -
            prevTokenBalance;
        RewardsInfo_.pendingAmount += receivedAmount;

        emit RewardsAddedToPending(address(token), receivedAmount);
    }

    /// @notice Emergency withdraw `token`'s balance on the contract to `receiver`
    function emergencyWithdraw(
        ERC20 token,
        address receiver
    ) public nonReentrant permissioned {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) revert REWRD_EmergencyWithdraw_TokenBalanceZero();
        _safeTokenTransfer(token, receiver, balance);
    }

    /// @notice Emergency withdraw all reward tokens' balances on the contract to `receiver`
    function emergencyWithdrawAll(
        address receiver
    ) external nonReentrant permissioned {
        for (uint256 index = 0; index < _distributedTokens.length(); ++index) {
            emergencyWithdraw(ERC20(_distributedTokens.at(index)), receiver);
        }
    }

    /********************************************************/
    /****************** INTERNAL FUNCTIONS ******************/
    /********************************************************/

    /// @dev Returns the amount of Rewards token distributed every second (times 1e2)
    function _RewardsAmountPerSecond(
        address token
    ) internal view returns (uint256) {
        if (!_distributedTokens.contains(token)) return 0;
        return
            rewardsInfo[token].currentDistributionAmount.mul(1e2).div(
                _cycleDurationSeconds
            );
    }

    /// @dev Updates every user's rewards allocation for each distributed token
    function _updateRewardsInfo(address token) internal {
        uint256 currentBlockTimestamp = _currentBlockTimestamp();
        RewardsInfo storage RewardsInfo_ = rewardsInfo[token];

        updateCurrentCycleStartTime();

        uint256 lastUpdateTime = RewardsInfo_.lastUpdateTime;
        uint256 accRewardsPerShare = RewardsInfo_.accRewardsPerShare;

        if (currentBlockTimestamp <= lastUpdateTime) {
            return;
        }

        // if no xGMBL is allocated or initial distribution has not started yet
        if (
            totalAllocation == 0 ||
            currentBlockTimestamp < currentCycleStartTime
        ) {
            RewardsInfo_.lastUpdateTime = currentBlockTimestamp;
            return;
        }

        uint256 currentDistributionAmount = RewardsInfo_
            .currentDistributionAmount; // gas saving
        uint256 currentCycleDistributedAmount = RewardsInfo_
            .currentCycleDistributedAmount; // gas saving

        // check if the current cycle has changed since last update
        if (lastUpdateTime < currentCycleStartTime) {
            // update accrewardPerShare for the end of the previous cycle
            accRewardsPerShare = accRewardsPerShare.add(
                (
                    currentDistributionAmount.mul(1e2).sub(
                        currentCycleDistributedAmount
                    )
                ).mul(1e16).div(totalAllocation)
            );

            // check if distribution is enabled
            if (!RewardsInfo_.distributionDisabled) {
                // transfer the token's cycleRewardsPercent part from the pending slot to the distribution slot
                RewardsInfo_.distributedAmount += currentDistributionAmount;

                uint256 pendingAmount = RewardsInfo_.pendingAmount;
                currentDistributionAmount = pendingAmount
                    .mul(RewardsInfo_.cycleRewardsPercent)
                    .div(10000);

                RewardsInfo_
                    .currentDistributionAmount = currentDistributionAmount;
                RewardsInfo_.pendingAmount =
                    pendingAmount -
                    currentDistributionAmount;
            } else {
                // stop the token's distribution on next cycle
                RewardsInfo_.distributedAmount += currentDistributionAmount;
                currentDistributionAmount = 0;
                RewardsInfo_.currentDistributionAmount = 0;
            }

            currentCycleDistributedAmount = 0;
            lastUpdateTime = currentCycleStartTime;
        }

        uint256 toDistribute = currentBlockTimestamp.sub(lastUpdateTime).mul(
            _RewardsAmountPerSecond(token)
        );

        // ensure that we can't distribute more than currentDistributionAmount (for instance w/ a > 24h service interruption)
        if (
            currentCycleDistributedAmount + toDistribute >
            currentDistributionAmount * 1e2
        ) {
            toDistribute = currentDistributionAmount.mul(1e2).sub(
                currentCycleDistributedAmount
            );
        }

        RewardsInfo_.currentCycleDistributedAmount =
            currentCycleDistributedAmount +
            toDistribute;
        RewardsInfo_.accRewardsPerShare = accRewardsPerShare.add(
            toDistribute.mul(1e16).div(totalAllocation)
        );
        RewardsInfo_.lastUpdateTime = currentBlockTimestamp;
    }

    /// @dev Updates "userAddress" user's and total allocations for each distributed token
    function _updateUser(
        address userAddress,
        uint256 newUserAllocation,
        uint256 newTotalAllocation
    ) internal {
        uint256 previousUserAllocation = usersAllocation[userAddress];

        // for each distributedToken
        uint256 length = _distributedTokens.length();

        for (uint256 index = 0; index < length; ++index) {
            address token = _distributedTokens.at(index);
            _updateRewardsInfo(token);

            UserInfo storage user = users[token][userAddress];
            uint256 accRewardsPerShare = rewardsInfo[token].accRewardsPerShare;

            uint256 pending = previousUserAllocation
                .mul(accRewardsPerShare)
                .div(1e18)
                .sub(user.rewardDebt);

            user.pendingRewards += pending;
            user.rewardDebt = newUserAllocation.mul(accRewardsPerShare).div(
                1e18
            );
        }

        usersAllocation[userAddress] = newUserAllocation;
        totalAllocation = newTotalAllocation;

        emit UserUpdated(
            userAddress,
            previousUserAllocation,
            newUserAllocation
        );
    }

    /// @dev Harvests msg.sender's pending Rewards of a given token
    function _harvestRewards(address account, address token) internal {
        _updateRewardsInfo(token);

        UserInfo storage user = users[token][account];
        uint256 accRewardsPerShare = rewardsInfo[token].accRewardsPerShare;

        uint256 userxGMBLAllocation = usersAllocation[account];

        uint256 pending = user.pendingRewards.add(
            userxGMBLAllocation.mul(accRewardsPerShare).div(1e18).sub(
                user.rewardDebt
            )
        );

        _safeTokenTransfer(ERC20(token), account, pending);

        user.pendingRewards = 0;
        user.rewardDebt = userxGMBLAllocation.mul(accRewardsPerShare).div(1e18);

        // Re-stake current autoLock ratio of pending rewards
        if (token == IxGMBLToken(xGMBLToken).getGMBL()) {
            uint256 relock = pending
                .mul(rewardsInfo[token].autoLockPercent)
                .div(10000);

            if (relock > 0) {
                pending -= relock;

                IxGMBLToken(xGMBLToken).convertTo(relock, account);
                IxGMBLToken(xGMBLToken).allocateFromUsage(account, relock);

                // complete logic from misisng line to re-allocate in XGMBL.allocateFromUsage()
                uint256 newUserAllocation = usersAllocation[account] + relock;
                uint256 newTotalAllocation = totalAllocation + relock;

                _updateUser(account, newUserAllocation, newTotalAllocation);
            }
        }

        emit RewardsCollected(account, token, pending);
    }

    /// @dev Safe token transfer function, in case rounding error causes pool to not have enough tokens
    function _safeTokenTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            uint256 tokenBal = token.balanceOf(address(this));
            if (amount > tokenBal) {
                token.safeTransfer(to, tokenBal);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    /// @dev Utility function to get the current block timestamp
    function _currentBlockTimestamp() internal view virtual returns (uint256) {
        /* solhint-disable not-rely-on-time */
        return block.timestamp;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ROLESv1 } from "src/modules/ROLES/ROLES.v1.sol";
import "src/Default2/src/Kernel.sol";

/// @notice Module that holds multisig roles needed by various policies.
contract ROLES is ROLESv1 {
    //============================================================================================//
    //                                        MODULE SETUP                                        //
    //============================================================================================//

    constructor(Kernel kernel_) Module(kernel_) {}

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return toKeycode("ROLES");
    }

    /// @inheritdoc Module
    function VERSION() external pure override returns (uint8 major, uint8 minor) {
        major = 1;
        minor = 0;
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc ROLESv1
    function saveRole(bytes32 role_, address addr_) external override permissioned {
        if (hasRole[addr_][role_]) revert ROLES_AddressAlreadyHasRole(addr_, role_);

        ensureValidRole(role_);

        // Grant role to the address
        hasRole[addr_][role_] = true;

        emit RoleGranted(role_, addr_);
    }

    /// @inheritdoc ROLESv1
    function removeRole(bytes32 role_, address addr_) external override permissioned {
        if (!hasRole[addr_][role_]) revert ROLES_AddressDoesNotHaveRole(addr_, role_);

        hasRole[addr_][role_] = false;

        emit RoleRevoked(role_, addr_);
    }

    //============================================================================================//
    //                                       VIEW FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc ROLESv1
    function requireRole(bytes32 role_, address caller_) external view override {
        if (!hasRole[caller_][role_]) revert ROLES_RequireRole(role_);
    }

    /// @inheritdoc ROLESv1
    function ensureValidRole(bytes32 role_) public pure override {
        for (uint256 i = 0; i < 32; ) {
            bytes1 char = role_[i];
            if ((char < 0x61 || char > 0x7A) && char != 0x5f && char != 0x00) {
                revert ROLES_InvalidRole(role_); // a-z only
            }
            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "src/Default2/src/Kernel.sol";

abstract contract ROLESv1 is Module {
    // =========  EVENTS ========= //

    event RoleGranted(bytes32 indexed role_, address indexed addr_);
    event RoleRevoked(bytes32 indexed role_, address indexed addr_);

    // =========  ERRORS ========= //

    error ROLES_InvalidRole(bytes32 role_);
    error ROLES_RequireRole(bytes32 role_);
    error ROLES_AddressAlreadyHasRole(address addr_, bytes32 role_);
    error ROLES_AddressDoesNotHaveRole(address addr_, bytes32 role_);
    error ROLES_RoleDoesNotExist(bytes32 role_);

    // =========  STATE ========= //

    /// @notice Mapping for if an address has a policy-defined role.
    mapping(address => mapping(bytes32 => bool)) public hasRole;

    // =========  FUNCTIONS ========= //

    /// @notice Function to grant policy-defined roles to some address. Can only be called by admin.
    function saveRole(bytes32 role_, address addr_) external virtual;

    /// @notice Function to revoke policy-defined roles from some address. Can only be called by admin.
    function removeRole(bytes32 role_, address addr_) external virtual;

    /// @notice "Modifier" to restrict policy function access to certain addresses with a role.
    /// @dev    Roles are defined in the policy and granted by the ROLES admin.
    function requireRole(bytes32 role_, address caller_) external virtual;

    /// @notice Function that checks if role is valid (all lower case)
    function ensureValidRole(bytes32 role_) external pure virtual;
}

// SPDX-License-Identifier: BUSL1.1
pragma solidity ^0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {GMBL} from "../GMBL/GMBL.sol";

import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";
import {Kernel, Module, Keycode} from "src/Default2/src/Kernel.sol";
import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/IxGMBLToken.sol";
import "../interfaces/IxGMBLTokenUsage.sol";

import {Address} from "../libraries/Address.sol";

/*
 * xGMBL is escrowed governance token obtainable by converting GMBL to it
 * It's non-transferable, except from/to whitelisted addresses
 * It can be converted back to GMBL through a vesting process
 * This contract is made to receive xGMBL deposits from users in order to allocate them to rewards contracts
 */
contract XGMBL is
    ReentrancyGuard,
    ERC20("GMBL escrowed token", "xGMBL", 18),
    Module,
    IxGMBLToken
{
    using Address for address;
    using SafeTransferLib for ERC20;
    using SafeTransferLib for GMBL;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct xGMBLBalance {
        uint256 allocatedAmount; // Amount of xGMBL allocated to a Usage
        uint256 redeemingAmount; // Total amount of xGMBL currently being redeemed
    }

    mapping(address => xGMBLBalance) public xGMBLBalances;

    // A redeem entry appended for a user
    struct RedeemInfo {
        uint256 GMBLAmount; // GMBL amount to receive when vesting has ended
        uint256 xGMBLAmount; // xGMBL amount to redeem
        uint256 endTime;
        IxGMBLTokenUsage RewardsAddress;
        uint256 RewardsAllocation; // Share of redeeming xGMBL to allocate to the Rewards Usage contract
    }

    mapping(address => RedeemInfo[]) public userRedeems; // User's redeeming instances

    uint256 public constant MAX_FIXED_RATIO = 100; // 100%

    GMBL public immutable GMBLToken; // GMBL token to convert to/from
    IxGMBLTokenUsage public RewardsAddress; // Rewards contract
    mapping(address => uint256) public rewardsAllocations; // Active xGMBL allocations to Rewards

    EnumerableSet.AddressSet private _transferWhitelist; // addresses allowed to send/receive xGMBL

    // Redeeming min/max settings
    uint256 public minRedeemRatio = 50; // 1:0.5
    uint256 public maxRedeemRatio = 100; // 1:1
    uint256 public minRedeemDuration = 0 days; // 0s - instant redeem with burn discount
    uint256 public maxRedeemDuration = 180 days; // 7776000s - full redeem with no burn

    // Adjusted rewards for redeeming xGMBL
    uint256 public redeemRewardsAdjustment = 20; // 20%

    constructor(GMBL GMBLToken_, Kernel kernel_) Module(kernel_) {
        GMBLToken = GMBLToken_;
        _transferWhitelist.add(address(this));
    }

    /********************************************/
    /****************** ERRORS ******************/
    /********************************************/

    error XGMBL_Convert_NullAmount();
    error XGMBL_ConvertTo_SenderIsEOA();
    error XGMBL_ConvertTo_BadSender();
    error XGMBL_Allocate_NullAmount();
    error XGMBL_Redeem_AmountIsZero();
    error XGMBL_Redeem_DurationBelowMinimum();
    error XGMBL_FinalizeReedem_VestingNotOver();
    error XGMBL_ValidateRedeem_NullEntry();
    error XGMBL_Deallocate_NullAmount();
    error XGMBL_Deallocate_UnauthorizedAmount();
    error XGMBL_AllocateFromUsage_BadUsageAddress();
    error XGMBL_DeallocateFromUsage_BadUsageAddress();
    error XGMBL_UpdateRedeemSettings_BadRatio();
    error XGMBL_UpdateRedeemSettings_BadDuration();
    error XMGBL_UpdateTransferWhitelist_CannotRemoveSelf();
    error XGMBL_Transfer_NotPermitted();

    /********************************************/
    /****************** EVENTS ******************/
    /********************************************/

    event Convert(address indexed from, address to, uint256 amount);

    event UpdateRedeemSettings(
        uint256 minRedeemRatio,
        uint256 maxRedeemRatio,
        uint256 minRedeemDuration,
        uint256 maxRedeemDuration,
        uint256 redeemRewardsAdjustment
    );

    event UpdateRewardsAddress(
        address previousRewardsAddress,
        address newRewardsAddress
    );

    event SetTransferWhitelist(address account, bool add);

    event Redeem(
        address indexed account,
        uint256 xGMBLAmount,
        uint256 GMBLAmount,
        uint256 duration
    );

    event FinalizeRedeem(
        address indexed account,
        uint256 xGMBLAmount,
        uint256 GMBLAmount
    );

    event CancelRedeem(address indexed account, uint256 xGMBLAmount);

    event UpdateRedeemRewardsAddress(
        address indexed account,
        uint256 redeemIndex,
        address previousRewardsAddress,
        address newRewardsAddress
    );

    event Allocate(
        address indexed account,
        address indexed rewardsAddress,
        uint256 amount
    );

    event Deallocate(
        address indexed account,
        address indexed rewardsAddress,
        uint256 amount
    );

    event DeallocateAndLock(
        address indexed account,
        address indexed rewardsAddress,
        uint256 amount
    );

    /***********************************************/
    /****************** MODIFIERS ******************/
    /***********************************************/

    /// @dev Check if a redeem entry exists
    modifier validateRedeem(address account, uint256 redeemIndex) {
        if (redeemIndex >= userRedeems[account].length)
            revert XGMBL_ValidateRedeem_NullEntry();
        _;
    }

    /// @dev Hook override to forbid transfers except from whitelisted addresses and minting
    modifier transferWhitelisted(address from, address to) {
        if (
            from != address(0) &&
            !_transferWhitelist.contains(from) &&
            !_transferWhitelist.contains(to)
        ) revert XGMBL_Transfer_NotPermitted();
        _;
    }

    /**************************************************/
    /****************** PUBLIC VIEWS ******************/
    /**************************************************/

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("XGMBL");
    }

    function getGMBL() external view returns (address) {
        return address(GMBLToken);
    }

    /**
     * @notice returns `account`'s `allocatedAmount` and `redeemingAmount` amount
     * @return allocatedAmount Total amount of xGMBL currently allocated to usage address(s) for user
     * @return redeemingAmount Total amount of xGMBL being redeemed for user
     */
    function getxGMBLBalance(
        address account
    ) external view returns (uint256 allocatedAmount, uint256 redeemingAmount) {
        xGMBLBalance storage balance = xGMBLBalances[account];
        return (balance.allocatedAmount, balance.redeemingAmount);
    }

    /// @notice returns redeemable GMBL for `amount` of xGMBL vested for `duration` seconds
    function getGMBLByVestingDuration(
        uint256 amount,
        uint256 duration
    ) public view returns (uint256) {
        // Invalid redeem duration
        if (duration < minRedeemDuration) {
            return 0;
        }

        // Min redeem duration burns (100 - minRedeemRatio)% (default 50%) of gmbl
        if (duration == minRedeemDuration) {
            return (amount * minRedeemRatio) / 100;
        }

        // Max redeem duration burns (100 - maxRedeemRatio)% (default 0%) of gmbl
        if (duration >= maxRedeemDuration) {
            return (amount * maxRedeemRatio) / 100;
        }

        // Min redeem % + reamining % up to max redeem linearly
        uint256 ratio = minRedeemRatio +
            (((duration - minRedeemDuration) *
                (maxRedeemRatio - minRedeemRatio)) /
                (maxRedeemDuration - minRedeemDuration));

        return (amount * ratio) / 100;
    }

    /// @notice returns quantity of `account`'s pending redeems
    function getUserRedeemsLength(
        address account
    ) external view returns (uint256) {
        return userRedeems[account].length;
    }

    /// @notice returns rewards `allocation` of `account`
    function usageAllocations(
        address account
    ) external view returns (uint256 allocation) {
        return rewardsAllocations[account];
    }

    /// @notice returns `account` info for a pending redeem identified by `redeemIndex`
    function getUserRedeem(
        address account,
        uint256 redeemIndex
    )
        external
        view
        validateRedeem(account, redeemIndex)
        returns (
            uint256 GMBLAmount,
            uint256 xGMBLAmount,
            uint256 endTime,
            address RewardsContract,
            uint256 RewardsAllocation
        )
    {
        RedeemInfo storage _redeem = userRedeems[account][redeemIndex];
        return (
            _redeem.GMBLAmount,
            _redeem.xGMBLAmount,
            _redeem.endTime,
            address(_redeem.RewardsAddress),
            _redeem.RewardsAllocation
        );
    }


    /// @notice returns allocated xGMBL from `account` to Rewards
    function getRewardsAllocation(
        address account
    ) external view returns (uint256) {
        return rewardsAllocations[account];
    }

    /// @notice returns length of transferWhitelist array
    function transferWhitelistLength() external view returns (uint256) {
        return _transferWhitelist.length();
    }

    /// @notice returns transferWhitelist array item's address for `index`
    function transferWhitelist(uint256 index) external view returns (address) {
        return _transferWhitelist.at(index);
    }

    /// @dev returns if `account` is allowed to send/receive xGMBL
    function isTransferWhitelisted(
        address account
    ) external view override returns (bool) {
        return _transferWhitelist.contains(account);
    }

    /*****************************************************************/
    /******************  EXTERNAL PUBLIC FUNCTIONS  ******************/
    /*****************************************************************/

    /// @notice Transfers `amount` of xGMBL from msg.sender to `to`
    /// @dev Override ERC20 transfer. Cannot externally transfer staked tokens unless whitelisted
    function transfer(
        address to,
        uint256 amount
    ) public override transferWhitelisted(msg.sender, to) returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` of xGMBL from `from` to `to`
    /// @dev Override ERC20 transferFrom. Cannot externally transfer staked tokens unless whitelisted
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override transferWhitelisted(from, to) returns (bool) {
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

    /// @notice Convert's `account`'s `amount` of GMBL to xGMBL
    /// @dev policy dictates boosted amount for potential stake boost
    function convert(
        uint256 amount,
        uint256 boostedAmount,
        address account
    ) external nonReentrant permissioned {
        _convert(amount, boostedAmount, account);
    }

    /// @notice Convert caller's `amount` of GMBL to xGMBL to `to` address
    function convertTo(
        uint256 amount,
        address to
    ) external override nonReentrant {
        if(msg.sender != address(RewardsAddress))
            revert XGMBL_ConvertTo_BadSender();

        if (!address(msg.sender).isContract())
            revert XGMBL_ConvertTo_SenderIsEOA();

        _convert(amount, amount, to);
    }

    /**
     * @notice Initiates redeem process (xGMBL to GMBL) of `xGMBLAmount` over `duration` period
     * @param xGMBLAmount Amount of xGMBL to redeem (from either sender's balance, their rewards allocation, or a mix)
     * @param duration Time to redeem for...
     *    - minimum redeem duration instantly unlcoks gmbl at the min redeem ratio (default 50%)
     *    - see getGMBLByVestingDuration() for more details
     */
    function redeem(
        address account,
        uint256 xGMBLAmount,
        uint256 duration
    ) external nonReentrant permissioned {
        if (xGMBLAmount == 0) revert XGMBL_Redeem_AmountIsZero();
        if (duration < minRedeemDuration)
            revert XGMBL_Redeem_DurationBelowMinimum();

        // get corresponding GMBL amount
        uint256 GMBLAmount = getGMBLByVestingDuration(xGMBLAmount, duration);
        emit Redeem(account, xGMBLAmount, GMBLAmount, duration);

        // handle Rewards during the vesting process
        uint256 CurrentRewardsAllocation = rewardsAllocations[account];

        if (xGMBLAmount > balanceOf[account] + CurrentRewardsAllocation)
            revert("bad xgmbl amount");

        // Staked balance may be larger than allocated balance
        uint256 RewardsRedeemAmount = xGMBLAmount > CurrentRewardsAllocation
            ? CurrentRewardsAllocation
            : xGMBLAmount;

        xGMBLBalance storage balance = xGMBLBalances[account];

        // if redeeming is not immediate, go through vesting process
        if (duration > 0) {
            // add to SBT total
            balance.redeemingAmount += xGMBLAmount;

            // Rewards discount (deallocation) of redeem amount. max 100% (0 deallocation during redemption), default 20%
            uint256 NewRewardsAllocation = (RewardsRedeemAmount *
                redeemRewardsAdjustment) / 100;

            _deallocateAndLock(
                account,
                RewardsRedeemAmount - NewRewardsAllocation,
                balance
            );

            // lock up
            if (xGMBLAmount > RewardsRedeemAmount) {
                _transferFromSelf(
                    account,
                    address(this),
                    xGMBLAmount - RewardsRedeemAmount
                );
            }

            // add redeeming entry
            userRedeems[account].push(
                RedeemInfo({
                    GMBLAmount: GMBLAmount,
                    xGMBLAmount: xGMBLAmount,
                    endTime: _currentBlockTimestamp() + duration,
                    RewardsAddress: RewardsAddress,
                    RewardsAllocation: NewRewardsAllocation
                })
            );
        }
        // immediately redeem for GMBL
        else {
            // deallocate all rewards <= xGBML redeem amount
            _deallocateAndLock(account, RewardsRedeemAmount, balance);
            // lock up any free xGMBL (xGMBLAmount <= acount's xGMBL)
            _transferFromSelf(
                account,
                address(this),
                xGMBLAmount - RewardsRedeemAmount
            );

            _finalizeRedeem(account, xGMBLAmount, GMBLAmount);
        }
    }

    /// @notice Finalizes redeem process when vesting duration has been reached of `redeemIndex`'s redeem entry
    function finalizeRedeem(
        address account,
        uint256 redeemIndex
    ) external nonReentrant permissioned validateRedeem(account, redeemIndex) {
        xGMBLBalance storage balance = xGMBLBalances[account];
        RedeemInfo storage _redeem = userRedeems[account][redeemIndex];

        if (_currentBlockTimestamp() < _redeem.endTime)
            revert XGMBL_FinalizeReedem_VestingNotOver();

        // remove from SBT total
        balance.redeemingAmount -= _redeem.xGMBLAmount;
        _finalizeRedeem(account, _redeem.xGMBLAmount, _redeem.GMBLAmount);

        // handle Rewards compensation if any was active
        if (_redeem.RewardsAllocation > 0) {
            // deallocate from Rewards
            IxGMBLTokenUsage(_redeem.RewardsAddress).deallocate(
                account,
                _redeem.RewardsAllocation,
                new bytes(0)
            );

            // update internal accounting of deallocation
            balance.allocatedAmount -= _redeem.RewardsAllocation;
            rewardsAllocations[account] -= _redeem.RewardsAllocation;
        }

        // remove redeem entry
        _deleteRedeemEntry(account, redeemIndex);
    }

    /**
     * @notice Updates Rewards address for an existing active redeeming process
     *
     * @dev Can only be called by the involved user
     * Should only be used if Rewards contract was to be migrated
     */
    function updateRedeemRewardsAddress(
        address account,
        uint256 redeemIndex
    ) external nonReentrant permissioned validateRedeem(account, redeemIndex) {
        RedeemInfo storage _redeem = userRedeems[account][redeemIndex];

        // only if the active Rewards contract is not the same anymore
        if (
            RewardsAddress != _redeem.RewardsAddress &&
            address(RewardsAddress) != address(0)
        ) {
            if (_redeem.RewardsAllocation > 0) {
                // deallocate from old Rewards contract
                _redeem.RewardsAddress.deallocate(
                    account,
                    _redeem.RewardsAllocation,
                    new bytes(0)
                );

                // allocate to new used Rewards contract
                RewardsAddress.allocate(
                    account,
                    _redeem.RewardsAllocation,
                    new bytes(0)
                );
            }

            emit UpdateRedeemRewardsAddress(
                account,
                redeemIndex,
                address(_redeem.RewardsAddress),
                address(RewardsAddress)
            );

            _redeem.RewardsAddress = RewardsAddress;
        }
    }

    /// @notice Cancels an ongoing redeem entry at `redeemIndex`
    /// @dev Can only be called by its owner
    function cancelRedeem(
        address account,
        uint256 redeemIndex
    ) external nonReentrant permissioned validateRedeem(account, redeemIndex) {
        xGMBLBalance storage balance = xGMBLBalances[account];
        RedeemInfo storage _redeem = userRedeems[account][redeemIndex];

        // make redeeming xGMBL available again
        balance.redeemingAmount -= _redeem.xGMBLAmount;
        _transferFromSelf(address(this), account, _redeem.xGMBLAmount);

        // handle Rewards compensation if any was active
        if (_redeem.RewardsAllocation > 0) {
            // deallocate from Rewards
            IxGMBLTokenUsage(_redeem.RewardsAddress).deallocate(
                account,
                _redeem.RewardsAllocation,
                new bytes(0)
            );

            // update internal accounting of deallocate
            balance.allocatedAmount -= _redeem.RewardsAllocation;
            rewardsAllocations[account] -= _redeem.RewardsAllocation;
        }

        emit CancelRedeem(account, _redeem.xGMBLAmount);

        // remove redeem entry
        _deleteRedeemEntry(account, redeemIndex);
    }

    /// @notice Allocates caller's `amount` of available xGMBL to `usageAddress` contract
    /// @dev args specific to usage contract must be passed into "usageData"
    function allocate(
        address account,
        uint256 amount,
        bytes calldata usageData
    ) external nonReentrant permissioned {
        _allocate(account, amount);

        // allocates xGMBL to usageContract
        RewardsAddress.allocate(account, amount, usageData);
    }

    /// @notice Allocates `amount` of available xGMBL from `account` to caller (ie usage contract)
    /// @dev Caller must have an allocation approval for the required xGMBL xGMBL from `account`
    function allocateFromUsage(
        address account,
        uint256 amount
    ) external override nonReentrant {
        if (msg.sender != address(RewardsAddress))
            revert XGMBL_AllocateFromUsage_BadUsageAddress();

        _allocate(account, amount);
    }

    /// @notice Deallocates caller's `amount` of available xGMBL from rewards usage contract
    /// @dev args specific to usage contract must be passed into "usageData"
    function deallocate(
        address account,
        uint256 amount,
        bytes calldata usageData
    ) external nonReentrant permissioned {
        _deallocate(account, amount);

        // deallocate xGMBL into usageContract
        RewardsAddress.deallocate(account, amount, usageData);
    }

    /// @notice Deallocates `amount` of allocated xGMBL belonging to `account` from caller (ie usage contract)
    /// @dev Caller can only deallocate xGMBL from itself
    function deallocateFromUsage(
        address account,
        uint256 amount
    ) external override nonReentrant {
        if(msg.sender != address(RewardsAddress))
            revert XGMBL_DeallocateFromUsage_BadUsageAddress();

        _deallocate(account, amount);
    }

    /// @notice Burns `account`'s `amount` of xGMBL with the option of burning the underlying gmbl as well
    function burn(address account, uint256 amount) external permissioned {
        _burn(account, amount);
        GMBLToken.burn(amount);
    }

    /*******************************************************/
    /****************** OWNABLE FUNCTIONS ******************/
    /*******************************************************/

    /// @notice Updates all redeem ratios and durations
    /// @dev Must only be called by owner
    function updateRedeemSettings(
        uint256 minRedeemRatio_,
        uint256 maxRedeemRatio_,
        uint256 minRedeemDuration_,
        uint256 maxRedeemDuration_,
        uint256 redeemRewardsAdjustment_
    ) external permissioned {
        if (minRedeemRatio_ > maxRedeemRatio_)
            revert XGMBL_UpdateRedeemSettings_BadRatio();
        if (minRedeemDuration_ >= maxRedeemDuration_)
            revert XGMBL_UpdateRedeemSettings_BadDuration();
        // should never exceed 100%
        if (
            maxRedeemRatio_ > MAX_FIXED_RATIO ||
            redeemRewardsAdjustment_ > MAX_FIXED_RATIO
        ) revert XGMBL_UpdateRedeemSettings_BadRatio();

        minRedeemRatio = minRedeemRatio_;
        maxRedeemRatio = maxRedeemRatio_;
        minRedeemDuration = minRedeemDuration_;
        maxRedeemDuration = maxRedeemDuration_;
        redeemRewardsAdjustment = redeemRewardsAdjustment_;

        emit UpdateRedeemSettings(
            minRedeemRatio_,
            maxRedeemRatio_,
            minRedeemDuration_,
            maxRedeemDuration_,
            redeemRewardsAdjustment_
        );
    }

    /// @notice Updates Rewards contract address
    /// @dev Must only be called by owner
    function updateRewardsAddress(
        IxGMBLTokenUsage RewardsAddress_
    ) external permissioned {
        // if set to 0, also set divs earnings while redeeming to 0
        if (address(RewardsAddress_) == address(0)) {
            redeemRewardsAdjustment = 0;
        }

        emit UpdateRewardsAddress(
            address(RewardsAddress),
            address(RewardsAddress_)
        );
        RewardsAddress = RewardsAddress_;
    }

    /// @notice Adds or removes `account` from the transferWhitelist
    function updateTransferWhitelist(
        address account,
        bool add
    ) external permissioned {
        if (account == address(this) && !add)
            revert XMGBL_UpdateTransferWhitelist_CannotRemoveSelf();

        if (add) _transferWhitelist.add(account);
        else _transferWhitelist.remove(account);

        emit SetTransferWhitelist(account, add);
    }

    /********************************************************/
    /****************** INTERNAL FUNCTIONS ******************/
    /********************************************************/

    ///  @dev Convert caller's `amount` of GMBL into xGMBL to `to`
    function _convert(
        uint256 amount,
        uint256 boostedAmount,
        address from
    ) internal {
        if (amount == 0) revert XGMBL_Convert_NullAmount();

        // mint new xGMBL
        _mint(from, boostedAmount);

        emit Convert(from, address(this), amount);
        GMBLToken.safeTransferFrom(from, address(this), amount);
    }

    /**
     * @dev Finalizes the redeeming process for `account` by transferring them `GMBLAmount` and removing `xGMBLAmount` from supply
     *
     * Any vesting check should be ran before calling this
     * GMBL excess is automatically burnt
     */
    function _finalizeRedeem(
        address account,
        uint256 xGMBLAmount,
        uint256 GMBLAmount
    ) internal {
        uint256 GMBLExcess = xGMBLAmount - GMBLAmount;

        // sends due GMBL tokens
        GMBLToken.safeTransfer(account, GMBLAmount);

        // burns GMBL excess if any
        GMBLToken.burn(GMBLExcess);

        // burns redeem-locked XGMBL
        _burn(address(this), xGMBLAmount);

        emit FinalizeRedeem(account, xGMBLAmount, GMBLAmount);
    }

    /// @dev Allocates `account` user's `amount` of available xGMBL to `usageAddress` contract
    function _allocate(address account, uint256 amount) internal {
        if (amount == 0) revert XGMBL_Allocate_NullAmount();

        xGMBLBalance storage balance = xGMBLBalances[account];

        // update rewards allocatedAmount for account
        rewardsAllocations[account] += amount;

        // adjust user's xGMBL balances
        balance.allocatedAmount += amount;
        _transferFromSelf(account, address(this), amount);

        emit Allocate(account, address(RewardsAddress), amount);
    }

    /// @dev Deallocates `amount` of available xGMBL of `account`'s xGMBL from rewards contracts
    function _deallocate(address account, uint256 amount) internal {
        if (amount == 0) revert XGMBL_Deallocate_NullAmount();

        // check if there is enough allocated xGMBL to Rewards to deallocate
        uint256 allocatedAmount = rewardsAllocations[account];

        if (amount > allocatedAmount)
            revert XGMBL_Deallocate_UnauthorizedAmount();

        uint256 redeemsAllocations;
        RedeemInfo[] memory redeemEntries = userRedeems[account];
        for(uint256 i = 0; i < redeemEntries.length; ++i) {
            redeemsAllocations += redeemEntries[i].RewardsAllocation;
        }

        if(redeemsAllocations > allocatedAmount - amount)
            revert XGMBL_Deallocate_UnauthorizedAmount();

        // remove deallocated amount from Reward's allocation
        rewardsAllocations[account] = allocatedAmount - amount;

        // adjust user's xGMBL balances
        xGMBLBalance storage balance = xGMBLBalances[account];
        balance.allocatedAmount -= amount;
        _transferFromSelf(address(this), account, amount);

        emit Deallocate(account, address(RewardsAddress), amount);
    }

    /// @dev Deallocates excess from usage to be called during the redeem process
    function _deallocateAndLock(
        address account,
        uint256 rewardsRedeemAmount,
        xGMBLBalance storage balance
    ) internal {
        balance.allocatedAmount -= rewardsRedeemAmount;
        rewardsAllocations[account] -= rewardsRedeemAmount;

        RewardsAddress.deallocate(
            account,
            rewardsRedeemAmount,
            new bytes(0)
        );

        emit DeallocateAndLock(
            account,
            address(RewardsAddress),
            rewardsRedeemAmount
        );
    }

    /// @dev logic to handle deletion of redeem entry
    function _deleteRedeemEntry(address account, uint256 index) internal {
        userRedeems[account][index] = userRedeems[account][
            userRedeems[account].length - 1
        ];
        userRedeems[account].pop();
    }

    /// @dev Utility function to get the current block timestamp
    function _currentBlockTimestamp() internal view virtual returns (uint256) {
        /* solhint-disable not-rely-on-time */
        return block.timestamp;
    }

    /// @dev Utility function to tranfer xGMBL balances without approvals according to the logic of this contract
    function _transferFromSelf(
        address who,
        address to,
        uint256 amount
    ) internal {
        balanceOf[who] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);
    }
}

pragma solidity ^0.8.0;

import { SafeTransferLib, ERC20 } from "lib/solmate/src/utils/SafeTransferLib.sol";

import "src/Default2/src/Kernel.sol";
import "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import { ISwapRouter } from "./interfaces/ISwapRouter.sol";

// module dependancies
import { GMBL } from "../modules/GMBL/GMBL.sol";
import { HOUSE } from "../modules/HOUSE/HOUSE.sol";
import { ROLES } from "../modules/ROLES/ROLES.sol";


contract HousePolicy is Policy {
    using EnumerableSet for EnumerableSet.AddressSet;
    using ECDSA for bytes32;

    event WithdrawalSignerAdded(address indexed prover);
    event WithdrawalSignerRemoved(address indexed prover);
    event MinWithdrawalSignersChanged(uint256 oldMin, uint256 newMin);
    event WithdrawalApproved(address indexed who, address indexed token, uint256 nonce);
    event SwapAndDepositERC20(address indexed who, ERC20 indexed tokenIn, ERC20 indexed tokenOut, uint256 amountIn, uint256 amountOut);

    event ErrorReason(bytes reason);

    error Paused();
    error WithdrawalTokenNotWhitelisted();
    error WithdrawalExpired();
    error WithdrawalProofInvalid();
    error WithdrawalSignerNotFound();
    error WithdrawalNonceInvalid();
    error WithdrawalSignerExists();
    error WithdrawalSignerDoesntExist();
    error MinSignersExceedsProofs();
    error WithdrawalBadReceiver();
    error WithdrawalProofSignerNotUnique();
    error WithdrawalSignersMustHaveOneSigner();
    error WithdrawalMinSignerBadAmount();
    error SwapAndDepositBadTokenOut();
    error SwapAndDepositInvalidWrapDetails();

    /// @notice Roles admin module
    ROLES public roles;

    /// @notice house module
    HOUSE public house;

    /// @notice native token of protocol for direct swap deposits through paraswap
    GMBL public gmbl;

    /// @notice address of the paraswap router
    ISwapRouter public immutable camelotV3Router;

    /// @notice weth to wrap to in swap deposits
    ERC20 public immutable WETH;

    /// @notice pause lock for house actions
    bool public paused;

    /// @notice whitelist of address token -> bool whitelisted for house actions
    mapping(address => bool) public tokenWhitelist;

    /// @notice minimum number of proofs needed to execute a withdrawal (uniqueness is asserted)
    uint256 public minSigners;

    /// @notice Set of addresses that can generate withdrawal proofs
    EnumerableSet.AddressSet private _withdrawalSigners;

    /// @notice Current withdrawal nonce to prevent the re-use of a proof (TODO this might already be baked into ecrevocer sig data)
    mapping(address => uint256) public withdrawalNonces;

    struct WithdrawalProof {
        address proposedSigner;
        bytes signature;
    }

    struct WithdrawalData {
        address token;
        address recipient;
        uint256 amount;
        uint256 nonce;
        uint256 expiryTimestamp;
    }

    constructor(Kernel kernel_, ISwapRouter camelotV3Router_, ERC20 WETH_) Policy(kernel_) {
        camelotV3Router = camelotV3Router_;
        WETH = WETH_;
    }

    modifier unpaused() {
        if (paused) revert Paused();
        _;
    }

    modifier tokenWhitelisted(address token) {
        if (!tokenWhitelist[token]) revert WithdrawalTokenNotWhitelisted();
        _;
    }

    modifier OnlyOwner {
        roles.requireRole("houseowner", msg.sender);
        _;
    }

    modifier OnlyManager {
        roles.requireRole("housemanager", msg.sender);
        _;
    }

    // ######################## ~ KERNEL SETUP ~ ########################

    function configureDependencies() external override onlyKernel returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](3);
        dependencies[0] = toKeycode("HOUSE");
        dependencies[1] = toKeycode("ROLES");
        dependencies[2] = toKeycode("GMBLE");

        house = HOUSE(getModuleAddress(dependencies[0]));
        roles = ROLES(getModuleAddress(dependencies[1]));
        gmbl = GMBL(getModuleAddress(dependencies[2]));
    }

    function requestPermissions()
        external
        pure
        override
        returns (Permissions[] memory requests)
    {
        requests = new Permissions[](6);
        requests[0] = Permissions(toKeycode("HOUSE"), HOUSE.depositERC20.selector);
        requests[1] = Permissions(toKeycode("HOUSE"), HOUSE.depositNative.selector);
        requests[2] = Permissions(toKeycode("HOUSE"), HOUSE.withdrawERC20.selector);
        requests[3] = Permissions(toKeycode("HOUSE"), HOUSE.withdrawNative.selector);
        requests[4] = Permissions(toKeycode("HOUSE"), HOUSE.ownerEmergencyWithdrawERC20.selector);
        requests[5] = Permissions(toKeycode("HOUSE"), HOUSE.ownerEmergencyWithdrawalNative.selector);
    }

    function allWithdrawalSigners() external view returns(address[] memory) {
        return _withdrawalSigners.values();
    }

    function withdrawalSignerAt(uint256 index) external view returns(address) {
        return _withdrawalSigners.at(index);
    }

    function withdrawalSignersContain(address signer) external view returns(bool) {
        return _withdrawalSigners.contains(signer);
    }

    function withdrawalSignersLength() external view returns(uint256) {
        return _withdrawalSigners.length();
    }

    // ######################## ~ MODULE ENTRANCES ~ ########################

    /// @notice Uses camelot V3 router to swap into GMBL to deposit to house
    /// https://github.com/cryptoalgebra/Algebra/blob/62f0ea3ebf38d7fb32cdc4140f06480e26c22dd8/src/periphery/contracts/interfaces/ISwapRouter.sol#L27
    /// @param swapData algebra router ExactInputParams
    /// @dev swapData `recipient` field should be this contract. Will revert otherwise
    function swapDepositERC20(
        ISwapRouter.ExactInputParams calldata swapData
    ) external payable unpaused {
        ERC20 tokenIn = ERC20(getTokenIn(swapData.path));

        if (msg.value > 0) {
            (bool success, ) = address(WETH).call{value: msg.value}("");

            if (
                msg.value != swapData.amountIn ||
                address(tokenIn) != address(WETH) ||
                !success
            ) revert SwapAndDepositInvalidWrapDetails();
        } else {
            tokenIn.transferFrom(msg.sender, address(this), swapData.amountIn);
        }

        tokenIn.approve(address(camelotV3Router), swapData.amountIn);

        uint256 gmblBalanceBefore = gmbl.balanceOf(address(this));

        uint256 amountOut = camelotV3Router.exactInput(swapData);

        // get the GMBL balance after to assert tokenOut was sent here and is GMBL
        uint256 gmblBalanceAfter = gmbl.balanceOf(address(this));

        if (gmblBalanceAfter == 0 || amountOut != gmblBalanceAfter - gmblBalanceBefore)
            revert SwapAndDepositBadTokenOut();

        // It's ok to deposit GMBL dust in this contract above amountOut
        gmbl.approve(address(house), gmblBalanceAfter);
        house.depositERC20(gmbl, address(this), gmblBalanceAfter);

        // provides metadata otherwise a swapAndDeposit depositor looks like address(this) instead of msg.sender
        emit SwapAndDepositERC20(msg.sender, tokenIn, gmbl, swapData.amountIn, gmblBalanceAfter);
    }

    function depositERC20(ERC20 token, uint256 amount) external unpaused tokenWhitelisted(address(token)) {
        house.depositERC20(token, msg.sender, amount);
    }

    function depositNative() external payable unpaused tokenWhitelisted(address(0)) {
        house.depositNative{value: msg.value}(msg.sender);
    }

    function withdrawERC20(
        WithdrawalData calldata proposedWithdrawal,
        WithdrawalProof[] calldata proofs
    ) external unpaused {
        _validateWithdrawal(proposedWithdrawal, proofs);

        house.withdrawERC20(ERC20(proposedWithdrawal.token), payable(msg.sender), proposedWithdrawal.amount);
        emit WithdrawalApproved(msg.sender, proposedWithdrawal.token, withdrawalNonces[msg.sender]++);
    }

    function withdrawNative(
        WithdrawalData calldata proposedWithdrawal,
        WithdrawalProof[] calldata proofs
    ) external unpaused {
        _validateWithdrawal(proposedWithdrawal, proofs);

        house.withdrawNative(payable(msg.sender), proposedWithdrawal.amount);
        emit WithdrawalApproved(msg.sender, proposedWithdrawal.token, withdrawalNonces[msg.sender]++);
    }

    function _validateWithdrawal(
        WithdrawalData memory proposedWithdrawal,
        WithdrawalProof[] calldata proofs
    ) internal view {

        if (!tokenWhitelist[proposedWithdrawal.token])
            revert WithdrawalTokenNotWhitelisted();

        if (proposedWithdrawal.recipient != msg.sender)
            revert WithdrawalBadReceiver();

        if (proposedWithdrawal.nonce != withdrawalNonces[msg.sender])
            revert WithdrawalNonceInvalid();

        if (block.timestamp > proposedWithdrawal.expiryTimestamp)
            revert WithdrawalExpired();

        if (proofs.length < minSigners)
            revert MinSignersExceedsProofs();

        _validateWithdrawalProofs(proposedWithdrawal, proofs);
    }

    function _validateWithdrawalProofs(WithdrawalData memory proposedWithdrawal, WithdrawalProof[] calldata proofs) internal view {
        bytes32 proposedWithdrawalData = keccak256(abi.encode(proposedWithdrawal));
        proposedWithdrawalData = proposedWithdrawalData.toEthSignedMessageHash();

        for(uint i = 0; i < proofs.length; ++i) {

            if (!SignatureChecker.isValidSignatureNow(
                proofs[i].proposedSigner,
                proposedWithdrawalData,
                proofs[i].signature)
            )  revert WithdrawalProofInvalid();

            if(!_withdrawalSigners.contains(proofs[i].proposedSigner))
                revert WithdrawalProofInvalid();

            for(uint j = 0; j < proofs.length; ++j) {
                if(i == j) continue;
                if(proofs[j].proposedSigner == proofs[i].proposedSigner)
                    revert WithdrawalProofSignerNotUnique();
            }
        }
    }

    // ######################## ~ AUTH GATED FNS  ~ ########################

    function ownerEmergencyWithdrawERC20(ERC20 token, address to, uint256 amount) external OnlyOwner {
        house.ownerEmergencyWithdrawERC20(token, to, amount);
    }

    function ownerEmergencyWithdrawNative(address payable to, uint256 amount) external OnlyOwner {
        house.ownerEmergencyWithdrawalNative(to, amount);
    }

    // ######################## ~ POLICY MANAGEMENT  ~ ########################

    function unpause() external OnlyOwner {
        paused = false;
    }

    function pause() external OnlyManager {
        paused = true;
    }

    function whitelistToken(address token) external OnlyOwner {
        tokenWhitelist[token] = true;
    }

    function insertSigner(address signer) external OnlyOwner {
        bool success = _withdrawalSigners.add(signer);
        if(!success) revert WithdrawalSignerExists();
        ++minSigners;
        emit WithdrawalSignerAdded(signer);
    }

    /// @notice Removes a withdrawal prover
    /// @dev Withdrawals must be globally paused, changing prover order affects calldata
    function removeSigner(address signer) external OnlyOwner {
        bool success = _withdrawalSigners.remove(signer);
        if(!success) revert WithdrawalSignerDoesntExist();
        if(_withdrawalSigners.length() == 0) revert WithdrawalSignersMustHaveOneSigner();
        if(minSigners > 1) --minSigners; // TODO get rid of this?

        emit WithdrawalSignerRemoved(signer);
    }

    function changeMinSigners(uint256 newMinSigners) external OnlyOwner {
        if (
            newMinSigners == 0 ||
            newMinSigners > _withdrawalSigners.length()
        ) revert WithdrawalMinSignerBadAmount();

        minSigners = newMinSigners;
        // todo emit event
    }

    function getTokenIn(bytes memory path) internal pure returns (address tokenIn) {
        assembly {
            tokenIn := mload(add(path, 20))
        }
    }
}

pragma solidity ^0.8.0;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface ISwapRouter {
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
}

pragma solidity ^0.8.0;

import { SafeTransferLib, ERC20 } from "lib/solmate/src/utils/SafeTransferLib.sol";

import "src/Default2/src/Kernel.sol";

// module dependancies
import { GMBL } from "../modules/GMBL/GMBL.sol";
import { RGMBL } from "../modules/GMBL/RGMBL.sol";
import { ROLES } from "../modules/ROLES/ROLES.sol";

contract LaunchPolicy is Policy {

    GMBL  public gmbl;
    RGMBL public rgmbl;
    ROLES public roles;

    constructor(Kernel kernel_) Policy(kernel_) {}

    function configureDependencies() external override onlyKernel returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](3);
        dependencies[0] = toKeycode("GMBLE");
        dependencies[1] = toKeycode("RGMBL");
        dependencies[2] = toKeycode("ROLES");

        gmbl = GMBL(getModuleAddress(dependencies[0]));
        rgmbl = RGMBL(getModuleAddress(dependencies[1]));
        roles = ROLES(getModuleAddress(dependencies[2]));
    }

    function requestPermissions()
        external
        pure
        override
        returns (Permissions[] memory requests)
    {
        requests = new Permissions[](2);
        requests[0] = Permissions(toKeycode("GMBLE"), GMBL.mint.selector);
        requests[1] = Permissions(toKeycode("RGMBL"), RGMBL.mint.selector);
    }

    /// @notice Role-gated function to mint GMBL (up to maxSupply)
    /// @param amount Amount to mint to msg.sender
    function mint(uint256 amount) external {
        roles.requireRole("minter", msg.sender);
        gmbl.mint(msg.sender, amount);
    }

    /// @notice Role-gated function to mint rGMBL (up to maxSupply)
    /// @param amount Amount to mint to msg.sender
    function mintReceiptToken(uint256 amount) external {
        roles.requireRole("minter", msg.sender);
        rgmbl.mint(msg.sender, amount);
    }
}

pragma solidity ^0.8.0;

import "src/Default2/src/Kernel.sol";

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";

// Module dependencies
import { REWRD } from "../modules/REWRD/REWRD.sol";
import { ROLES } from "../modules/ROLES/ROLES.sol";
import { IxGMBLTokenUsage } from "../modules/interfaces/IxGMBLTokenUsage.sol"; 

contract RewardPolicy is Policy {
    REWRD public rewrd;
    ROLES public roles;

    constructor(Kernel kernel_) Policy(kernel_) {}

    modifier OnlyOwner {
        roles.requireRole("rewardsmanager", msg.sender);
        _;
    }

    function configureDependencies() external override onlyKernel returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](2);
        dependencies[0] = toKeycode("REWRD");
        dependencies[1] = toKeycode("ROLES");

        rewrd = REWRD(getModuleAddress(dependencies[0]));
        roles = ROLES(getModuleAddress(dependencies[1]));
    }

    function requestPermissions() external pure override returns (Permissions[] memory requests) {
        Keycode REWRD_KEYCODE = toKeycode("REWRD");

        requests = new Permissions[](10);
        requests[0] = Permissions(REWRD_KEYCODE, REWRD.emergencyWithdraw.selector);
        requests[1] = Permissions(REWRD_KEYCODE, REWRD.emergencyWithdrawAll.selector);
        requests[2] = Permissions(REWRD_KEYCODE, REWRD.enableDistributedToken.selector);
        requests[3] = Permissions(REWRD_KEYCODE, REWRD.disableDistributedToken.selector);
        requests[4] = Permissions(REWRD_KEYCODE, REWRD.updateCycleRewardsPercent.selector);
        requests[5] = Permissions(REWRD_KEYCODE, REWRD.removeTokenFromDistributedTokens.selector);
        requests[6] = Permissions(REWRD_KEYCODE, REWRD.addRewardsToPending.selector);
        requests[7] = Permissions(REWRD_KEYCODE, REWRD.updateAutoLockPercent.selector);
        requests[8] = Permissions(REWRD_KEYCODE, REWRD.harvestRewards.selector);
        requests[9] = Permissions(REWRD_KEYCODE, REWRD.harvestAllRewards.selector); 
    }

    function harvestRewards(address token) external {
        rewrd.harvestRewards(msg.sender, token);
    }

    function harvestAllRewards() external {
        rewrd.harvestAllRewards(msg.sender);
    }

    function emergencyWithdraw(ERC20 token) external OnlyOwner {
        rewrd.emergencyWithdraw(token, msg.sender);
    }

    function emergencyWithdrawAll() external OnlyOwner {
        rewrd.emergencyWithdrawAll(msg.sender);
    }

    function enableDistributedToken(address token) external OnlyOwner {
        rewrd.enableDistributedToken(token);
    }

    function addRewardsToPending(ERC20 token, uint256 amount) external OnlyOwner {
        rewrd.addRewardsToPending(token, msg.sender, amount);
    }


    function disableDistributedToken(address token) external OnlyOwner {
        rewrd.disableDistributedToken(token);
    }

    function updateCycleRewardsPercent(address token, uint256 percent) external OnlyOwner {
        rewrd.updateCycleRewardsPercent(token, percent);
    }

    function updateAutoLockPercent(address token, uint256 percent) external OnlyOwner {
        rewrd.updateAutoLockPercent(token, percent);
    }

    function removeTokenFromDistributedTokens(address tokenToRemove) external OnlyOwner {
        rewrd.removeTokenFromDistributedTokens(tokenToRemove);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {ROLESv1} from "../modules/ROLES/ROLES.v1.sol";
import "src/Default2/src/Kernel.sol";

/// @notice The RolesAdmin Policy grants and revokes Roles in the ROLES module.
contract RolesAdmin is Policy {
    // =========  EVENTS ========= //

    event NewAdminPushed(address indexed newAdmin_);
    event NewAdminPulled(address indexed newAdmin_);

    // =========  ERRORS ========= //

    error OnlyAdmin();
    error OnlyNewAdmin();

    // =========  STATE ========= //

    /// @notice Special role that is responsible for assigning policy-defined roles to addresses.
    address public admin;

    /// @notice Proposed new admin. Address must call `pullRolesAdmin` to become the new roles admin.
    address public newAdmin;

    ROLESv1 public ROLES;

    //============================================================================================//
    //                                      POLICY SETUP                                          //
    //============================================================================================//

    constructor(Kernel kernel_) Policy(kernel_) {
        admin = msg.sender;
    }

    function configureDependencies() external override onlyKernel returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](1);
        dependencies[0] = toKeycode("ROLES");

        ROLES = ROLESv1(getModuleAddress(dependencies[0]));
    }

    function requestPermissions() external view override returns (Permissions[] memory requests) {
        Keycode ROLES_KEYCODE = toKeycode("ROLES");

        requests = new Permissions[](2);
        requests[0] = Permissions(ROLES_KEYCODE, ROLES.saveRole.selector);
        requests[1] = Permissions(ROLES_KEYCODE, ROLES.removeRole.selector);
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    modifier onlyAdmin() {
        if (msg.sender != admin) revert OnlyAdmin();
        _;
    }

    function grantRole(bytes32 role_, address wallet_) external onlyAdmin {
        ROLES.saveRole(role_, wallet_);
    }

    function revokeRole(bytes32 role_, address wallet_) external onlyAdmin {
        ROLES.removeRole(role_, wallet_);
    }

    //============================================================================================//
    //                                      ADMIN FUNCTIONS                                       //
    //============================================================================================//

    function pushNewAdmin(address newAdmin_) external onlyAdmin {
        newAdmin = newAdmin_;
        emit NewAdminPushed(newAdmin_);
    }

    function pullNewAdmin() external {
        if (msg.sender != newAdmin) revert OnlyNewAdmin();
        admin = newAdmin;
        newAdmin = address(0);
        emit NewAdminPulled(admin);
    }
}

pragma solidity ^0.8.0;

import { SafeTransferLib, ERC20 } from "lib/solmate/src/utils/SafeTransferLib.sol";

import "src/Default2/src/Kernel.sol";

// Module dependencies
import { XGMBL } from "../modules/XGMBL/XGMBL.sol";
import { GMBL } from "../modules/GMBL/GMBL.sol";
import { ROLES } from "../modules/ROLES/ROLES.sol";
import { REWRD } from "../modules/REWRD/REWRD.sol";
import { REWRDV2 } from "../modules/REWRD/REWRDV2.sol";

import { IxGMBLTokenUsage } from "../modules/interfaces/IxGMBLTokenUsage.sol";

contract StakedPolicy is Policy {

    error StakedPolicy_InvalidStakeBoostMultiplier();
    error StakedPolicy_InvalidStakeBoostPeriod();
    error StakedPolicy_ConversionsPaused();

    event StakeBoostMultiplierSet(uint16 oldMultiplier, uint16 newMultiplier);
    event StakeBoostPeriodSet(uint256 startTime, uint256 endTime);

    XGMBL public xGMBL;
    GMBL public gmbl;
    ROLES public roles;
    REWRD public rewrdV1;
    REWRDV2 public rewrdV2;

    struct StakeBoost {
        uint256 start;
        uint256 end;
    }

    StakeBoost public stakeBoostPeriod;
    uint16 public StakeBoostMultiplier; // 10000 = 100%

    bool public paused;

    mapping(address => uint256) public imbalanceWhitelist;

    constructor(Kernel kernel_) Policy(kernel_) {
        // default staked amount == 100% of GMBL converted
        StakeBoostMultiplier = 10000;
    }

    modifier OnlyOwner {
        roles.requireRole("stakingmanager", msg.sender);
        _;
    }

    function configureDependencies() external override onlyKernel returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](5);
        dependencies[0] = toKeycode("XGMBL");
        dependencies[1] = toKeycode("GMBLE");
        dependencies[2] = toKeycode("ROLES");
        dependencies[3] = toKeycode("REWRD");
        dependencies[4] = toKeycode("RWRD2");

        xGMBL = XGMBL(getModuleAddress(dependencies[0]));
        gmbl = GMBL(getModuleAddress(dependencies[1]));
        roles = ROLES(getModuleAddress(dependencies[2]));
        rewrdV1 = REWRD(getModuleAddress(dependencies[3]));
        rewrdV2 = REWRDV2(getModuleAddress(dependencies[4]));
    }

    function requestPermissions() external pure override returns (Permissions[] memory requests) {
        Keycode XGMBL_KEYCODE = toKeycode("XGMBL");
        Keycode REWRD_KEYCODE = toKeycode("REWRD");
        Keycode REWRDV2_KEYCODE = toKeycode("RWRD2");

        requests = new Permissions[](14);
        requests[0] = Permissions(XGMBL_KEYCODE, XGMBL.convert.selector);
        requests[1] = Permissions(XGMBL_KEYCODE, XGMBL.allocate.selector);
        requests[2] = Permissions(XGMBL_KEYCODE, XGMBL.updateRedeemSettings.selector);
        requests[3] = Permissions(XGMBL_KEYCODE, XGMBL.updateRewardsAddress.selector);
        requests[5] = Permissions(XGMBL_KEYCODE, XGMBL.updateTransferWhitelist.selector);
        requests[6] = Permissions(XGMBL_KEYCODE, XGMBL.deallocate.selector);
        requests[7] = Permissions(XGMBL_KEYCODE, XGMBL.redeem.selector);
        requests[8] = Permissions(XGMBL_KEYCODE, XGMBL.finalizeRedeem.selector);
        requests[9] = Permissions(XGMBL_KEYCODE, XGMBL.updateRedeemRewardsAddress.selector);
        requests[10] = Permissions(XGMBL_KEYCODE, XGMBL.cancelRedeem.selector);
        requests[11] = Permissions(XGMBL_KEYCODE, XGMBL.burn.selector);
        requests[12] = Permissions(REWRD_KEYCODE, REWRD.harvestRewards.selector);
        requests[13] = Permissions(REWRDV2_KEYCODE, REWRDV2.harvestRewards.selector);
    }

    // ######################## ~ MODULE ENTRANCES ~ ########################

    /// @notice Converts `amount` of msg.sender's GMBL to xGMBL, accounting for stake boost
    /// @param amount Amount of GMBL to convert
    function convert(uint256 amount) external {
        if (paused) revert StakedPolicy_ConversionsPaused();

        uint256 boostedAmount = _getStakeBoost(amount);
        _convert(amount, boostedAmount);
    }

    /// @notice Allocates `amount` of msg.sender's xGMBL to the rewards usage
    /// @param amount Amount to allocate
    /// @param usageData Optional calldata to adhere to xGMBL usage interface
    function allocate(uint256 amount, bytes calldata usageData) external {
        _allocate(amount, usageData);
    }

    /// @notice Atomically performs convert() and allocate() for msg.sender
    /// @param amount Amount of GMBL to convert to xGMBL and allocate to rewards
    /// @param usageData Optional calldata to adhere to xGMBL usage interface
    function convertAndAllocate(uint256 amount, bytes calldata usageData) external {
        if (paused) revert StakedPolicy_ConversionsPaused();

        uint256 boostedAmount = _getStakeBoost(amount);
        _convert(amount, boostedAmount);
        _allocate(boostedAmount, usageData);
    }

    /// @notice Deallocates `amount` of msg.sender`s
    /// @dev Attempting to deallocate into any amount allocated in redeem entries will revert
    /// @param amount Amount of xGMBL to deallocate
    /// @param usageData Optional calldata to adhere to xGMBL usage interface
    function deallocate(uint256 amount, bytes calldata usageData) external {
        xGMBL.deallocate(msg.sender, amount, usageData);
    }

    /// @notice Starts redeem process for msg.sender's `amount` of xGMBL
    /// @param amount Amount of xGMBL to redeem
    /// @param duration Duration to linearly redeem % of underlying GMBL for xGMBL
    function redeem(uint256 amount, uint256 duration) external {
        xGMBL.redeem(msg.sender, amount, duration);
    }

    /// @notice Finalizes a redeem entry for msg.sender
    /// @param redeemIndex The redeem entry index of msg.sender to finalize
    function finalizeRedeem(uint256 redeemIndex) external {
        (,,,IxGMBLTokenUsage rewardsAddress,) = xGMBL.userRedeems(msg.sender, redeemIndex);
        if (address(rewardsAddress) != address(rewrdV2))
            xGMBL.updateRedeemRewardsAddress(msg.sender, redeemIndex);

        xGMBL.finalizeRedeem(msg.sender, redeemIndex);
    }

    /// @notice Helper function to migrate msg.sender's rewards allocation to a new address
    /// @param redeemIndex The redeem entry index of msg.sender to migrate
    function updateRedeemRewardsAddress(uint256 redeemIndex) external {
        xGMBL.updateRedeemRewardsAddress(msg.sender, redeemIndex);
    }

    /// @notice Cancels a redeem entry for msg.sender
    /// @param redeemIndex The redeem entry index to cancel
    function cancelRedeem(uint256 redeemIndex) external {
        xGMBL.cancelRedeem(msg.sender, redeemIndex);
    }

    /// @notice Burns `amount` of msg.sender's rewards allocaiton and cooresponding locked GMBL 1:1
    /// @dev must be unallocated xGMBL
    /// @param amount Amount to burn
    function burn(uint256 amount) external {
        xGMBL.burn(msg.sender, amount);
    }

    function _convert(uint256 amount, uint256 boostedAmount) private {
        xGMBL.convert(amount, boostedAmount, msg.sender);
    }

    function _allocate(uint256 amount, bytes calldata usageData) private {
        xGMBL.allocate(msg.sender, amount, usageData);
    }

    function _getStakeBoost(uint256 amount) private view returns (uint256 boost) {
        if (block.timestamp > stakeBoostPeriod.end || block.timestamp < stakeBoostPeriod.start) {
            return amount;
        }
        return amount * StakeBoostMultiplier / 10000;
    }

    function getAllocationImbalance(address account) public view returns (uint256 imbalance) {
        return xGMBL.rewardsAllocations(account) - rewrdV1.usersAllocation(account);
    }

    function getRedeemsAllocationImbalance(address account) public view returns (uint256 imblance, uint256 numRedeems) {
        uint256 redeemsAllocations;
        uint256 rewardsAllocations = rewrdV1.usersAllocation(account);
        numRedeems = xGMBL.getUserRedeemsLength(account);

        for(uint256 i = 0; i < numRedeems; ++i) {
            (,,,,uint256 RewardsAllocation) = xGMBL.userRedeems(account, i);
            redeemsAllocations += RewardsAllocation;
        }

        uint256 imbalance = redeemsAllocations > rewardsAllocations ? redeemsAllocations - rewardsAllocations : 0;
        return (imbalance, numRedeems);
    }

    /// @notice Migrates accounts affected by harvest allocaiton imabalnce bug
    /// by initializing redeems and allocating the difference before transferring the xGMBL to a newAccount
    /// @param newAccount new account to transfer all allocated/unallocated xGMBL to and allocate from
    function migrateImbalancedAccount(address newAccount) external {
        (uint256 redeemsImbalance, uint256 numRedeems) = getRedeemsAllocationImbalance(msg.sender);
        imbalanceWhitelist[msg.sender] -= redeemsImbalance;

        // Tops off rewards allocation so current redeems (if imbalanced) can be cancelled
        if (redeemsImbalance > 0) {
            gmbl.transfer(msg.sender, redeemsImbalance);
            xGMBL.convert(redeemsImbalance, redeemsImbalance, msg.sender);
            xGMBL.allocate(msg.sender, redeemsImbalance, hex"00");
        }

        // pops each redeem entry off to before migrating whole balance in one redeem
        for(uint256 i = 0; i < numRedeems; ++i) {
            xGMBL.cancelRedeem(msg.sender, 0);
        }

        _migrateImblancedAccount(newAccount);
    }

    /// @notice migrates whole balance of allocated/unallocated xgmbl to a newAccount and harvests remaining rewards
    function _migrateImblancedAccount(address newAccount) internal {
        uint256 imbalancedAmount = getAllocationImbalance(msg.sender);
        if (imbalancedAmount == 0) return;

        imbalanceWhitelist[msg.sender] -= imbalancedAmount;

        (uint256 allocatedAmount,) = xGMBL.xGMBLBalances(msg.sender);

        uint256 oldMinRatio = xGMBL.minRedeemRatio();
        uint256 oldMaxRatio = xGMBL.maxRedeemRatio();
        uint256 oldMinDuration = xGMBL.minRedeemDuration();
        uint256 oldMaxDuration = xGMBL.maxRedeemDuration();
        uint256 oldRedeemRewardsPercent = xGMBL.redeemRewardsAdjustment();

        xGMBL.updateRedeemSettings(oldMinRatio, oldMaxRatio, oldMinDuration, oldMaxDuration, 100);
        xGMBL.redeem(msg.sender, allocatedAmount, 180 days);
        xGMBL.updateRedeemSettings(oldMinRatio, oldMaxRatio, oldMinDuration, oldMaxDuration, oldRedeemRewardsPercent);

        gmbl.transfer(msg.sender, imbalancedAmount);

        xGMBL.convert(imbalancedAmount, imbalancedAmount, msg.sender);
        xGMBL.allocate(msg.sender, imbalancedAmount, hex"00");

        xGMBL.cancelRedeem(msg.sender, 0);

        // cancelled redeem is fully unallocated
        uint256 newXgmblBalance = xGMBL.balanceOf(msg.sender);

        xGMBL.updateTransferWhitelist(msg.sender, true);
        xGMBL.transferFrom(msg.sender, newAccount, newXgmblBalance);
        xGMBL.updateTransferWhitelist(msg.sender, false);

        rewrdV1.harvestRewards(msg.sender, address(gmbl));
    }

    // ######################## ~ MODULE MANAGERIAL ENTRANCES ~ ########################

    /**
     * @notice Role-guarded function to update redeem settings
     * @param minRedeemRatio Ratio of GMBL:xGMBL returned for a minimum duration redeem (default 50%)
     * @param maxRedeemRatio Ratio of GMBL:xGMBL returned for a maximum duration redeem (default 100%)
     * @param minRedeemDuration Minumum duration a redeem entry must be (default instant)
     * @param maxRedeemDuration Maximum duration a redeem entry can be to receive `maxRedeemRatio` of GMBL:xGMBL
     * @param redeemRewardsAdjustment Percent of redeeming xGMBL that can still be allocated to rewards during redemption
     */
    function updateRedeemSettings(
        uint256 minRedeemRatio,
        uint256 maxRedeemRatio,
        uint256 minRedeemDuration,
        uint256 maxRedeemDuration,
        uint256 redeemRewardsAdjustment
    ) external OnlyOwner {
        xGMBL.updateRedeemSettings(
            minRedeemRatio,
            maxRedeemRatio,
            minRedeemDuration,
            maxRedeemDuration,
            redeemRewardsAdjustment
        );
    }

    /// @notice Role-guarded function to update the rewards contract
    /// @dev accounts must migrate their existing redeem entries to finalize or cancel
    /// @param RewardsAddress_ new rewards usage contract
    function updateRewardsAddress(IxGMBLTokenUsage RewardsAddress_) external OnlyOwner {
        xGMBL.updateRewardsAddress(RewardsAddress_);
    }

    /// @notice Role-guarded function to update the transfer whitelist of xGMBL
    /// @param account Address that can send or receive xGMBL
    /// @param add Toggle for whitelist
    function updateTransferWhitelist(address account, bool add) external OnlyOwner {
        xGMBL.updateTransferWhitelist(account, add);
    }

    // ######################## ~ POLICY MANAGEMENT ~ ########################

    /// @notice Role-guarded function to sets stake boost multiplier of this policy
    /// @param newMultiplier percent (10000 == 100%) to boost conversions
    function setStakeBoostMultiplier(uint16 newMultiplier) external OnlyOwner {
        if (10000 > newMultiplier) revert StakedPolicy_InvalidStakeBoostMultiplier();

        emit StakeBoostMultiplierSet(StakeBoostMultiplier, newMultiplier);
        StakeBoostMultiplier = newMultiplier;
    }

    /// @notice Role-guarded function to set `start` and `end` of stake boost period
    /// @param start Start timestamp of stake boost period
    /// @param end End timestamp of stake boost period
    function startStakeBoostPeriod(uint256 start, uint256 end) external OnlyOwner {
        if (start > end || block.timestamp > end) revert StakedPolicy_InvalidStakeBoostPeriod();
        if (stakeBoostPeriod.end > start) revert StakedPolicy_InvalidStakeBoostPeriod();

        emit StakeBoostPeriodSet(start, end);
        stakeBoostPeriod.start = start;
        stakeBoostPeriod.end = end;
    }

    /// @notice Role-guarded function to cancel stake boost period
    function cancelStakeBoost() external OnlyOwner {
        emit StakeBoostPeriodSet(0, 0);
        stakeBoostPeriod.start = 0;
        stakeBoostPeriod.end = 0;
    }

    /// @notice Role-guarded function to pause conversion actions
    function pause(bool paused_) external OnlyOwner {
        paused = paused_;
    }

    function setWhitelistImbalancedAccount(address account, uint256 amount) external OnlyOwner {
        imbalanceWhitelist[account] = amount;
    }

    function setWhitelistImbalancedAccounts(address[] calldata accounts, uint256[] calldata amounts) external OnlyOwner {
        for(uint256 i = 0; i <  accounts.length; ++i) {
            imbalanceWhitelist[accounts[i]] = amounts[i];
        }
    }

    function withdrawERC20(ERC20 token, uint256 amount) external OnlyOwner {
        token.transfer(msg.sender, amount);
    }
}