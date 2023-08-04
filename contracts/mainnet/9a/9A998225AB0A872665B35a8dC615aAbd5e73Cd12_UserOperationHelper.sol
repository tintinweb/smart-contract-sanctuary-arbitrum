// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../library/UserOperation.sol";

import "../wallet/SmartAccount.sol";
import "../interfaces/IEntryPointSimulations.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract UserOperationHelper is Ownable {
    using UserOperationLib for UserOperation;

    mapping(address => bool) public tokenPaymasters;
    mapping(address => bool) public entryPoints;

    receive() external payable {}

    constructor(address _tokenPaymaster, address _entryPoint, address _owner) {
        tokenPaymasters[_tokenPaymaster] = true;
        entryPoints[_entryPoint] = true;
        _transferOwnership(_owner);
    }

    function getUserOpHash(
        UserOperation calldata userOp,
        address entrypoint
    ) external view returns (bytes32) {
        return keccak256(abi.encode(userOp.hash(), entrypoint, block.chainid));
    }

    function gasEstimate(
        UserOperation calldata userOp,
        address entryPoint,
        bool preTransfer
    ) external {
        require(
            entryPoints[entryPoint],
            "UserOperationHelper: invalid entrypoint"
        );

        UserOperation memory mUserOp = modifyCalldata(userOp);

        if (preTransfer) {
            transferPaymaster(userOp);
        }

        IEntryPointSimulations(entryPoint).simulateHandleOpWithoutSig(mUserOp);
    }

    function modifyCalldata(
        UserOperation calldata userOp
    ) public pure returns (UserOperation memory mUserOp) {
        // no function call
        if (userOp.callData.length == 0) {
            return userOp;
        }

        if (userOp.callData.length < 4) {
            revert("UserOperationHelper: invalid callData");
        }

        bytes4 callSelector = bytes4(userOp.callData[:4]);

        // function not overrided
        if (
            callSelector == SmartAccount.execTransactionFromEntrypoint.selector
        ) {
            return userOp;
        }

        // function override
        if (
            callSelector ==
            SmartAccount.execTransactionFromEntrypointBatch.selector
        ) {
            mUserOp = userOp;
            mUserOp.callData = replaceSelector(
                SmartAccount
                    .execTransactionFromEntrypointBatchRevertOnFail
                    .selector,
                userOp.callData
            );

            return mUserOp;
        }

        // function not found
        revert("UserOperationHelper: unsupported selector");
    }

    function replaceSelector(
        bytes4 newSelector,
        bytes memory data
    ) public pure returns (bytes memory) {
        for (uint256 i = 0; i < 4; i++) {
            data[i] = newSelector[i];
        }

        return data;
    }

    function transferPaymaster(UserOperation calldata userOp) internal {
        uint256 gasPrice = userOp.maxFeePerGas == userOp.maxPriorityFeePerGas
            ? userOp.maxFeePerGas
            : min(
                userOp.maxFeePerGas,
                userOp.maxPriorityFeePerGas + block.basefee
            );

        // if pay with native
        if (userOp.paymasterAndData.length == 0) {
            (bool success, ) = userOp.sender.call{
                value: (userOp.callGasLimit +
                    userOp.verificationGasLimit +
                    userOp.preVerificationGas) * gasPrice
            }("");
            require(success, "UserOperationHelper: transfer failed");
            return;
        }

        if (userOp.paymasterAndData.length < 20) {
            revert("UserOperationHelper: invalid paymasterAndData");
        }

        address paymaster = address(bytes20(userOp.paymasterAndData[:20]));
        // other paymasters not concerning in this matter
        if (!tokenPaymasters[paymaster]) {
            return;
        }

        if (userOp.paymasterAndData.length < 104) {
            revert("UserOperationHelper: invalid tokenPaymasterAndData");
        }

        address token = address(bytes20(userOp.paymasterAndData[20:40]));
        uint256 exchangeRate = uint256(bytes32(userOp.paymasterAndData[40:72]));

        if (token == address(0)) {
            revert("UserOperationHelper: invalid token");
        }

        // calculating amount of ERC20 to transfer
        uint256 requiredGas = userOp.callGasLimit +
            userOp.verificationGasLimit *
            3 +
            userOp.preVerificationGas;

        uint256 requiredPrefund = (requiredGas * gasPrice * exchangeRate) /
            1e18;

        IERC20(token).transfer(userOp.sender, requiredPrefund);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function setEntryPoint(address entryPoint, bool status) external onlyOwner {
        entryPoints[entryPoint] = status;
    }

    function setPaymaster(address paymaster, bool status) external onlyOwner {
        tokenPaymasters[paymaster] = status;
    }

    function withdrawNative(address to, uint256 amount) external onlyOwner {
        (bool success, ) = to.call{value: amount}("");
        require(success, "UserOperationHelper: transfer failed");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../library/UserOperation.sol";

interface IAccount {
    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     * signature failure should be reported by returning SIG_VALIDATION_FAILED (1).
     * This allows making a "simulation call" without a valid signature
     * Other failures (e.g. nonce mismatch, or invalid signature format) should still revert to signal failure.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param userOpHash hash of the user's request data. can be used as the basis for signature.
     * @param aggregator the aggregator used to validate the signature. NULL for non-aggregated signature accounts.
     * @param missingAccountFunds missing funds on the account's deposit in the entrypoint.
     *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     * @return deadline the last block timestamp this operation is valid, or zero if it is valid indefinitely.
     *      signature failure is returned as SIG_VALIDATION_FAILED value (1)
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        address aggregator,
        uint256 missingAccountFunds
    ) external returns (uint256 deadline);

    function validateUserOpWithoutSig(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        address aggregator,
        uint256 missingAccountFunds
    ) external returns (uint256 deadline);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../library/UserOperation.sol";

/**
 * Aggregated Signatures validator.
 */
interface IAggregator {
    /**
     * validate aggregated signature.
     * revert if the aggregated signature does not match the given list of operations.
     */
    function validateSignatures(
        UserOperation[] calldata userOps,
        bytes calldata signature
    ) external view;

    /**
     * validate signature of a single userOp
     * This method is should be called by bundler after EntryPoint.simulateValidation() returns (reverts) with ValidationResultWithAggregation
     * First it validates the signature over the userOp. then it return data to be used when creating the handleOps:
     * @param userOp the userOperation received from the user.
     * @return sigForUserOp the value to put into the signature field of the userOp when calling handleOps.
     *    (usually empty, unless account and aggregator support some kind of "multisig"
     */
    function validateUserOpSignature(
        UserOperation calldata userOp
    ) external view returns (bytes memory sigForUserOp);

    /**
     * aggregate multiple signatures into a single value.
     * This method is called off-chain to calculate the signature to pass with handleOps()
     * bundler MAY use optimized custom code perform this aggregation
     * @param userOps array of UserOperations to collect the signatures from.
     * @return aggregatesSignature the aggregated signature
     */
    function aggregateSignatures(
        UserOperation[] calldata userOps
    ) external view returns (bytes memory aggregatesSignature);
}

// SPDX-License-Identifier: GPL-3.0
// Modified version of a Implementation of contracts for ERC-4337 account abstraction via alternative mempool.
// Original code: https://github.com/eth-infinitism/account-abstraction/tree/releases/v0.4
pragma solidity ^0.8.12;

import "../library/UserOperation.sol";
import "./IStakeManager.sol";
import "./IAggregator.sol";

interface IEntryPoint is IStakeManager {
    /***
     * An event emitted after each successful request
     * @param userOpHash - unique identifier for the request (hash its entire content, except signature).
     * @param sender - the account that generates this request.
     * @param paymaster - if non-null, the paymaster that pays for this request.
     * @param nonce - the nonce value from the request
     * @param actualGasCost - actual amount paid (by account or paymaster) for this UserOperation
     * @param actualGasUsed - total gas used by this UserOperation (including preVerification, creation, validation and execution)
     * @param success - true if the sender transaction succeeded, false if reverted.
     */
    event UserOperationEvent(
        bytes32 indexed userOpHash,
        address indexed sender,
        address indexed paymaster,
        uint256 nonce,
        bool success,
        uint256 actualGasCost,
        uint256 actualGasUsed
    );

    /**
     * account "sender" was deployed.
     * @param userOpHash the userOp that deployed this account. UserOperationEvent will follow.
     * @param sender the account that is deployed
     * @param factory the factory used to deploy this account (in the initCode)
     * @param paymaster the paymaster used by this UserOp
     */
    event AccountDeployed(
        bytes32 indexed userOpHash,
        address indexed sender,
        address factory,
        address paymaster
    );

    /**
     * An event emitted if the UserOperation "callData" reverted with non-zero length
     * @param userOpHash the request unique identifier.
     * @param sender the sender of this request
     * @param nonce the nonce used in the request
     * @param revertReason - the return bytes from the (reverted) call to "callData".
     */
    event UserOperationRevertReason(
        bytes32 indexed userOpHash,
        address indexed sender,
        uint256 nonce,
        bytes revertReason
    );

    /**
     * signature aggregator used by the following UserOperationEvents within this bundle.
     */
    event SignatureAggregatorChanged(address aggregator);

    /**
     * a custom revert error of handleOps, to identify the offending op.
     *  NOTE: if simulateValidation passes successfully, there should be no reason for handleOps to fail on it.
     *  @param opIndex - index into the array of ops to the failed one (in simulateValidation, this is always zero)
     *  @param paymaster - if paymaster.validatePaymasterUserOp fails, this will be the paymaster's address. if validateUserOp failed,
     *       this value will be zero (since it failed before accessing the paymaster)
     *  @param reason - revert reason
     *   Should be caught in off-chain handleOps simulation and not happen on-chain.
     *   Useful for mitigating DoS attempts against batchers or for troubleshooting of account/paymaster reverts.
     */
    error FailedOp(uint256 opIndex, address paymaster, string reason);

    /**
     * error case when a signature aggregator fails to verify the aggregated signature it had created.
     */
    error SignatureValidationFailed(address aggregator);

    //UserOps handled, per aggregator
    struct UserOpsPerAggregator {
        UserOperation[] userOps;
        // aggregator address
        IAggregator aggregator;
        // aggregated signature
        bytes signature;
    }

    /**
     * Execute a batch of UserOperation.
     * no signature aggregator is used.
     * if any account requires an aggregator (that is, it returned an "actualAggregator" when
     * performing simulateValidation), then handleAggregatedOps() must be used instead.
     * @param ops the operations to execute
     * @param beneficiary the address to receive the fees
     */
    function handleOps(
        UserOperation[] calldata ops,
        address payable beneficiary
    ) external;

    /**
     * Execute a batch of UserOperation with Aggregators
     * @param opsPerAggregator the operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts)
     * @param beneficiary the address to receive the fees
     */
    function handleAggregatedOps(
        UserOpsPerAggregator[] calldata opsPerAggregator,
        address payable beneficiary
    ) external;

    /**
     * generate a request Id - unique identifier for this request.
     * the request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
     */
    function getUserOpHash(
        UserOperation calldata userOp
    ) external view returns (bytes32);

    /**
     * Simulate a call to account.validateUserOp and paymaster.validatePaymasterUserOp.
     * @dev this method always revert. Successful result is ValidationResult error. other errors are failures.
     * @dev The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the account's data.
     * @param userOp the user operation to validate.
     */
    function simulateValidation(UserOperation calldata userOp) external;

    /**
     * Successful result from simulateValidation.
     * @param returnInfo gas and deadlines returned values
     * @param senderInfo stake information about the sender
     * @param factoryInfo stake information about the factor (if any)
     * @param paymasterInfo stake information about the paymaster (if any)
     */
    error ValidationResult(
        ReturnInfo returnInfo,
        StakeInfo senderInfo,
        StakeInfo factoryInfo,
        StakeInfo paymasterInfo
    );

    /**
     * Successful result from simulateValidation, if the account returns a signature aggregator
     * @param returnInfo gas and deadlines returned values
     * @param senderInfo stake information about the sender
     * @param factoryInfo stake information about the factor (if any)
     * @param paymasterInfo stake information about the paymaster (if any)
     * @param aggregatorInfo signature aggregation info (if the account requires signature aggregator)
     *      bundler MUST use it to verify the signature, or reject the UserOperation
     */
    error ValidationResultWithAggregation(
        ReturnInfo returnInfo,
        StakeInfo senderInfo,
        StakeInfo factoryInfo,
        StakeInfo paymasterInfo,
        AggregatorStakeInfo aggregatorInfo
    );

    /**
     * gas and deadlines returned during simulation
     * @param preOpGas the gas used for validation (including preValidationGas)
     * @param prefund the required prefund for this operation
     * @param deadline validateUserOp's deadline (or SIG_VALIDATION_FAILED for signature failure)
     * @param paymasterDeadline validatePaymasterUserOp's deadline (or SIG_VALIDATION_FAILED for signature failure)
     * @param paymasterContext returned by validatePaymasterUserOp (to be passed into postOp)
     */
    struct ReturnInfo {
        uint256 preOpGas;
        uint256 prefund;
        uint256 deadline;
        uint256 paymasterDeadline;
        bytes paymasterContext;
    }

    /**
     * returned aggregated signature info.
     * the aggregator returned by the account, and its current stake.
     */
    struct AggregatorStakeInfo {
        address actualAggregator;
        StakeInfo stakeInfo;
    }

    /**
     * Get counterfactual sender address.
     *  Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
     * this method always revert, and returns the address in SenderAddressResult error
     * @param initCode the constructor code to be passed into the UserOperation.
     */
    function getSenderAddress(bytes memory initCode) external;

    /**
     * return value of getSenderAddress
     */
    error SenderAddressResult(address sender);

    /**
     * simulate full execution of a UserOperation (including both validation and target execution)
     * this method will always revert. it performs full validation of the UserOperation, but ignores
     * signature error.
     * Note that in order to collect the the success/failure of the target call, it must be executed
     * with trace enabled to track the emitted events.
     */
    function simulateHandleOp(UserOperation calldata op) external;

    error ExecutionResult(
        uint256 preOpGas,
        uint256 paid,
        uint256 deadline,
        uint256 paymasterDeadline
    );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./IEntryPoint.sol";
import "./IPaymaster.sol";

interface IEntryPointSimulations {
    function simulateHandleOpWithoutSig(UserOperation calldata op) external;

    error SimulateHandleOpResult(
        uint256 preOpGas,
        IPaymaster.PostOpMode,
        bytes result,
        uint256 paid,
        uint256 callGasCost,
        uint256 gasPrice,
        uint256 deadline,
        uint256 paymasterDeadline
    );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../library/UserOperation.sol";

/**
 * the interface exposed by a paymaster contract, who agrees to pay the gas for user's operations.
 * a paymaster must hold a stake to cover the required entrypoint stake and also the gas for the transaction.
 */
interface IPaymaster {
    /**
     * payment validation: check if paymaster agree to pay.
     * Must verify sender is the entryPoint.
     * Revert to reject this request.
     * Note that bundlers will reject this method if it changes the state, unless the paymaster is trusted (whitelisted)
     * The paymaster pre-pays using its deposit, and receive back a refund after the postOp method returns.
     * @param userOp the user operation
     * @param userOpHash hash of the user's request data.
     * @param maxCost the maximum cost of this transaction (based on maximum gas and gas price from userOp)
     * @return context value to send to a postOp
     *  zero length to signify postOp is not required.
     * @return sigTimeRange signature and time-range of this operation, encoded the same as the return value of validateUserOperation
     *      <byte> sigFailure - (1) to mark signature failure (needed only if paymaster uses signature-based validation,)
     *      <4-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *      <4-byte> validAfter - first timestamp this operation is valid
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external returns (bytes memory context, uint256 sigTimeRange);

    function validatePaymasterUserOpWithoutSig(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external returns (bytes memory context, uint256 sigTimeRange);

    /**
     * post-operation handler.
     * Must verify sender is the entryPoint
     * @param mode enum with the following options:
     *      opSucceeded - user operation succeeded.
     *      opReverted  - user op reverted. still has to pay for gas.
     *      postOpReverted - user op succeeded, but caused postOp (in mode=opSucceeded) to revert.
     *                       Now this is the 2nd call, after user's op was deliberately reverted.
     * @param context - the context value returned by validatePaymasterUserOp
     * @param actualGasCost - actual gas used so far (without this postOp call).
     */
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external;

    enum PostOpMode {
        opSucceeded, // user op succeeded
        opReverted, // user op reverted. still has to pay for gas.
        postOpReverted //user op succeeded, but caused postOp to revert. Now its a 2nd call, after user's op was deliberately reverted.
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _data Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(
        bytes memory _data,
        bytes memory _signature
    ) public view virtual returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

/**
 * manage deposits and stakes.
 * deposit is just a balance used to pay for UserOperations (either by a paymaster or an account)
 * stake is value locked for at least "unstakeDelay" by a paymaster.
 */
interface IStakeManager {
    event Deposited(
        address from,
        address to,
        address account,
        uint256 increaseDeposit,
        uint256 totalDeposit
    );

    event Withdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    event RefundDeposit(address from, address to, uint256 refundAmount);

    /// Emitted once a stake is scheduled for withdrawal
    event StakeLocked(
        address indexed account,
        uint256 totalStaked,
        uint256 withdrawTime
    );

    /// Emitted once a stake is scheduled for withdrawal
    event StakeUnlocked(address indexed account, uint256 withdrawTime);

    event StakeWithdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /**
     * @param deposit the account's deposit
     * @param staked true if this account is staked as a paymaster
     * @param stake actual amount of ether staked for this paymaster.
     * @param unstakeDelaySec minimum delay to withdraw the stake. must be above the global unstakeDelaySec
     * @param withdrawTime - first block timestamp where 'withdrawStake' will be callable, or zero if already locked
     * @dev sizes were chosen so that (deposit,staked) fit into one cell (used during handleOps)
     *    and the rest fit into a 2nd cell.
     *    112 bit allows for 2^15 eth
     *    64 bit for full timestamp
     *    32 bit allow 150 years for unstake delay
     */
    struct DepositInfo {
        uint112 deposit;
        bool staked;
        uint112 stake;
        uint32 unstakeDelaySec;
        uint64 withdrawTime;
    }

    //API struct used by getStakeInfo and simulateValidation
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelaySec;
    }

    function getDepositInfo(
        address account
    ) external view returns (DepositInfo memory info);

    /// return the deposit (for gas payment) of the account
    function balanceOf(address account) external view returns (uint256);

    /**
     * add to the deposit of the given account
     */
    function depositTo(address account) external payable;

    /**
     * withdraw from the deposit.
     * @param withdrawAddress the address to send withdrawn value.
     * @param withdrawAmount the amount to withdraw.
     */
    function withdrawTo(
        address payable withdrawAddress,
        uint256 withdrawAmount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IStorage {
    struct bundlerInformation {
        address bundler;
        uint256 registeTime;
    }
    event UnrestrictedWalletSet(bool allowed);
    event UnrestrictedBundlerSet(bool allowed);
    event UnrestrictedModuleSet(bool allowed);
    event WalletFactoryWhitelistSet(address walletProxyFactory);
    event BundlerWhitelistSet(address indexed bundler, bool allowed);
    event ModuleWhitelistSet(address indexed module, bool allowed);

    function officialBundlerWhiteList(
        address bundler
    ) external view returns (bool);

    function moduleWhiteList(address module) external view returns (bool);

    function setUnrestrictedWallet(bool allowed) external;

    function setUnrestrictedBundler(bool allowed) external;

    function setUnrestrictedModule(bool allowed) external;

    function setBundlerOfficialWhitelist(
        address bundler,
        bool allowed
    ) external;

    function setWalletProxyFactoryWhitelist(address walletFactory) external;

    function setModuleWhitelist(address module, bool allowed) external;

    function validateModuleWhitelist(address module) external;

    function validateWalletWhitelist(address sender) external view;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

/**
 * User Operation struct
 * @param sender the sender account of this request
 * @param nonce unique value the sender uses to verify it is not a replay.
 * @param initCode if set, the account contract will be created by this constructor
 * @param callData the method call to execute on this account.
 * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp
 * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
 * @param maxFeePerGas same as EIP-1559 gas parameter
 * @param maxPriorityFeePerGas same as EIP-1559 gas parameter
 * @param paymasterAndData if set, this field hold the paymaster address and "paymaster-specific-data". the paymaster will pay for the transaction instead of the sender
 * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
 */
struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}

library UserOperationLib {
    function getSender(
        UserOperation calldata userOp
    ) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {
            data := calldataload(userOp)
        }
        return address(uint160(data));
    }

    //relayer/block builder might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(
        UserOperation calldata userOp
    ) internal view returns (uint256) {
        unchecked {
            uint256 maxFeePerGas = userOp.maxFeePerGas;
            uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
            if (maxFeePerGas == maxPriorityFeePerGas) {
                //legacy mode (for networks that don't support basefee opcode)
                return maxFeePerGas;
            }
            return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
        }
    }

    function pack(
        UserOperation calldata userOp
    ) internal pure returns (bytes memory ret) {
        address sender = getSender(userOp);
        uint256 nonce = userOp.nonce;
        bytes32 hashInitCode = calldataKeccak(userOp.initCode);
        bytes32 hashCallData = calldataKeccak(userOp.callData);
        uint256 callGasLimit = userOp.callGasLimit;
        uint256 verificationGasLimit = userOp.verificationGasLimit;
        uint256 preVerificationGas = userOp.preVerificationGas;
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        bytes32 hashPaymasterAndData = calldataKeccak(userOp.paymasterAndData);

        return
            abi.encode(
                sender,
                nonce,
                hashInitCode,
                hashCallData,
                callGasLimit,
                verificationGasLimit,
                preVerificationGas,
                maxFeePerGas,
                maxPriorityFeePerGas,
                hashPaymasterAndData
            );
    }

    function calldataKeccak(
        bytes calldata data
    ) internal pure returns (bytes32 ret) {
        assembly {
            let mem := mload(0x40)
            let len := data.length
            calldatacopy(mem, data.offset, len)
            ret := keccak256(mem, len)
        }
    }

    function hash(
        UserOperation calldata userOp
    ) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;
import "../common/Enum.sol";

/// @title Executor - A contract that can execute transactions
contract Executor {
    struct ExecuteParams {
        bool allowFailed;
        address to;
        uint256 value;
        bytes data;
        bytes nestedCalls; // ExecuteParams encoded as bytes
    }

    event HandleSuccessExternalCalls();
    event HandleFailedExternalCalls(bytes revertReason);

    function execute(
        ExecuteParams memory params,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        bytes memory result;

        if (operation == Enum.Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            (success, result) = params.to.delegatecall{gas: txGas}(params.data);
        } else {
            // solhint-disable-next-line no-inline-assembly
            (success, result) = payable(params.to).call{
                gas: txGas,
                value: params.value
            }(params.data);
        }

        if (!success) {
            if (!params.allowFailed) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;

import "../common/SelfAuthorized.sol";

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
contract FallbackManager is SelfAuthorized {
    event ChangedFallbackHandler(address handler);

    // keccak256("fallback_manager.handler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT =
        0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;

    function getFallbackHandler()
        public
        view
        returns (address fallbackHandler)
    {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded := sload(slot)
            fallbackHandler := shr(96, encoded)
        }
    }

    /// @dev Allows to add a contract to handle fallback calls.
    ///      Only fallback calls without value and with data will be forwarded.
    ///      This can only be done via a Safe transaction.
    /// @param handler contract to handle fallbacks calls.
    function setFallbackHandler(address handler) external authorized {
        setFallbackHandler(handler, false);
        emit ChangedFallbackHandler(handler);
    }

    function setFallbackHandler(address handler, bool delegate) internal {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded := or(shl(96, handler), delegate)
            sstore(slot, encoded)
        }
    }

    function initializeFallbackHandler(address handler) internal {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded := shl(96, handler)
            sstore(slot, encoded)
        }
    }

    // solhint-disable-next-line payable-fallback,no-complex-fallback
    fallback() external {
        assembly {
            // Load handler and delegate flag from storage
            let encoded := sload(FALLBACK_HANDLER_STORAGE_SLOT)
            let handler := shr(96, encoded)
            let delegate := and(encoded, 1)

            // Copy calldata to memory
            calldatacopy(0, 0, calldatasize())

            // If delegate flag is set, delegate the call to the handler
            switch delegate
            case 0 {
                mstore(calldatasize(), shl(96, caller()))
                let success := call(
                    gas(),
                    handler,
                    0,
                    0,
                    add(calldatasize(), 20),
                    0,
                    0
                )
                returndatacopy(0, 0, returndatasize())
                if iszero(success) {
                    revert(0, returndatasize())
                }
                return(0, returndatasize())
            }
            case 1 {
                let result := delegatecall(
                    gas(),
                    handler,
                    0,
                    calldatasize(),
                    0,
                    0
                )

                returndatacopy(0, 0, returndatasize())

                switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "./Executor.sol";

interface Guard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external;

    function checkAfterExecution(bool success) external;
}

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
contract GuardManager is SelfAuthorized, Executor {
    event ChangedGuard(address guard);

    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT =
        0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    function getGuard() public view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
        }
    }

    function setGuard(address guard) external authorized {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }

    // execute from this contract
    function execTransactionBatch(
        bytes memory executeParamBytes
    ) external authorized {
        executeWithGuardBatch(abi.decode(executeParamBytes, (ExecuteParams[])));
    }

    function execTransactionRevertOnFail(
        bytes memory executeParamBytes
    ) external authorized {
        execTransactionBatchRevertOnFail(
            abi.decode(executeParamBytes, (ExecuteParams[]))
        );
    }

    function executeWithGuard(
        address to,
        uint256 value,
        bytes calldata data
    ) internal {
        address guard = getGuard();
        if (guard != address(0)) {
            Guard(guard).checkTransaction(to, value, data, Enum.Operation.Call);
            Guard(guard).checkAfterExecution(
                execute(
                    ExecuteParams(false, to, value, data, ""),
                    Enum.Operation.Call,
                    gasleft()
                )
            );
        } else {
            execute(
                ExecuteParams(false, to, value, data, ""),
                Enum.Operation.Call,
                gasleft()
            );
        }
    }

    function execTransactionBatchRevertOnFail(
        ExecuteParams[] memory _params
    ) internal {
        address guard = getGuard();
        uint256 length = _params.length;

        if (guard == address(0)) {
            for (uint256 i = 0; i < length; ) {
                ExecuteParams memory param = _params[i];
                execute(param, Enum.Operation.Call, gasleft());

                if (param.nestedCalls.length > 0) {
                    try
                        this.execTransactionRevertOnFail(param.nestedCalls)
                    {} catch (bytes memory returnData) {
                        revert(string(returnData));
                    }
                }

                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i = 0; i < length; ) {
                ExecuteParams memory param = _params[i];

                Guard(guard).checkTransaction(
                    param.to,
                    param.value,
                    param.data,
                    Enum.Operation.Call
                );

                Guard(guard).checkAfterExecution(
                    execute(param, Enum.Operation.Call, gasleft())
                );

                if (param.nestedCalls.length > 0) {
                    try
                        this.execTransactionRevertOnFail(param.nestedCalls)
                    {} catch (bytes memory returnData) {
                        revert(string(returnData));
                    }
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    function executeWithGuardBatch(ExecuteParams[] memory _params) internal {
        address guard = getGuard();
        uint256 length = _params.length;

        if (guard == address(0)) {
            for (uint256 i = 0; i < length; ) {
                ExecuteParams memory param = _params[i];
                bool success = execute(param, Enum.Operation.Call, gasleft());
                if (success) {
                    emit HandleSuccessExternalCalls();
                }

                if (param.nestedCalls.length > 0) {
                    try this.execTransactionBatch(param.nestedCalls) {} catch (
                        bytes memory returnData
                    ) {
                        emit HandleFailedExternalCalls(returnData);
                    }
                }

                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i = 0; i < length; ) {
                ExecuteParams memory param = _params[i];

                Guard(guard).checkTransaction(
                    param.to,
                    param.value,
                    param.data,
                    Enum.Operation.Call
                );

                bool success = execute(param, Enum.Operation.Call, gasleft());
                if (success) {
                    emit HandleSuccessExternalCalls();
                }

                Guard(guard).checkAfterExecution(success);

                if (param.nestedCalls.length > 0) {
                    try this.execTransactionBatch(param.nestedCalls) {} catch (
                        bytes memory returnData
                    ) {
                        emit HandleFailedExternalCalls(returnData);
                    }
                }

                unchecked {
                    ++i;
                }
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;
import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "./Executor.sol";

/// @title Module Manager - A contract that manages modules that can execute transactions via this contract
contract ModuleManager is SelfAuthorized, Executor {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address module);
    event ExecutionFromModuleFailure(address module);

    address internal constant SENTINEL_MODULES = address(0x1);
    mapping(address => address) internal modules;

    function initializeModules() internal {
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
    }

    function enableModule(address module) public authorized {
        // Module address cannot be null or sentinel.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        // Module cannot be added twice.
        require(modules[module] == address(0), "GS102");

        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

    /// @dev Allows to remove a module from the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Disables the module `module` for the Safe.
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(
        address prevModule,
        address module
    ) public authorized {
        // Validate module address and check that it corresponds to module index.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        require(modules[prevModule] == module, "GS103");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) public view returns (bool) {
        return SENTINEL_MODULES != module && modules[module] != address(0);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) public virtual {
        // Only whitelisted modules are allowed.
        require(modules[msg.sender] != address(0), "GS104");
        // Execute transaction without further confirmations.
        if (
            execute(
                ExecuteParams(false, to, value, data, ""),
                operation,
                gasleft()
            )
        ) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) public returns (bytes memory returnData) {
        execTransactionFromModule(to, value, data, operation);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load free memory location
            let ptr := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // Point the return data to the correct memory location
            returnData := ptr
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;

contract OwnerManager {
    event AAOwnerSet(address owner);

    address internal owner;

    uint256 public nonce;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "not call by owner");
        _;
    }

    function initializeOwners(address _owner) internal {
        owner = _owner;

        emit AAOwnerSet(_owner);
    }

    function isOwner(address _owner) public view returns (bool) {
        return owner == _owner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ISignatureValidator.sol";
import "../../interfaces/IAccount.sol";
import "../common/Enum.sol";
import "../common/SignatureDecoder.sol";
import "./OwnerManager.sol";

contract SignatureManager is
    IAccount,
    ISignatureValidatorConstants,
    Enum,
    OwnerManager,
    SignatureDecoder
{
    using UserOperationLib for UserOperation;

    uint256 internal constant NONCE_VALIDATION_FAILED = 2;

    bytes32 internal immutable HASH_NAME;

    bytes32 internal immutable HASH_VERSION;

    bytes32 internal immutable TYPE_HASH;

    address internal immutable ADDRESS_THIS;

    bytes32 internal immutable EIP712_ORDER_STRUCT_SCHEMA_HASH;

    uint256 internal constant SIG_VALIDATION_FAILED = 1;

    struct SignMessage {
        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        address EntryPoint;
        uint256 sigTime;
    }

    /* solhint-enable var-name-mixedcase */

    constructor(string memory name, string memory version) {
        HASH_NAME = keccak256(bytes(name));
        HASH_VERSION = keccak256(bytes(version));
        TYPE_HASH = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        ADDRESS_THIS = address(this);

        EIP712_ORDER_STRUCT_SCHEMA_HASH = keccak256(
            abi.encodePacked(
                "SignMessage(",
                "address sender,",
                "uint256 nonce,",
                "bytes initCode,",
                "bytes callData,",
                "uint256 callGasLimit,",
                "uint256 verificationGasLimit,",
                "uint256 preVerificationGas,",
                "uint256 maxFeePerGas,",
                "uint256 maxPriorityFeePerGas,",
                "bytes paymasterAndData,",
                "address EntryPoint,",
                "uint256 sigTime",
                ")"
            )
        );
    }

    function getUOPHash(
        SignatureType sigType,
        address EntryPoint,
        UserOperation calldata userOp
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    sigType == SignatureType.EIP712Type
                        ? EIP712_ORDER_STRUCT_SCHEMA_HASH
                        : bytes32(block.chainid),
                    userOp.getSender(),
                    userOp.nonce,
                    keccak256(userOp.initCode),
                    keccak256(userOp.callData),
                    userOp.callGasLimit,
                    userOp.verificationGasLimit,
                    userOp.preVerificationGas,
                    userOp.maxFeePerGas,
                    userOp.maxPriorityFeePerGas,
                    keccak256(userOp.paymasterAndData),
                    EntryPoint,
                    uint256(bytes32(userOp.signature[1:33]))
                )
            );
    }

    function getUOPSignedHash(
        SignatureType sigType,
        address EntryPoint,
        UserOperation calldata userOp
    ) public view returns (bytes32) {
        return
            sigType == SignatureType.EIP712Type
                ? ECDSA.toTypedDataHash(
                    keccak256(
                        abi.encode(
                            TYPE_HASH,
                            HASH_NAME,
                            HASH_VERSION,
                            block.chainid,
                            ADDRESS_THIS
                        )
                    ),
                    keccak256(
                        abi.encode(
                            EIP712_ORDER_STRUCT_SCHEMA_HASH,
                            userOp.getSender(),
                            userOp.nonce,
                            keccak256(userOp.initCode),
                            keccak256(userOp.callData),
                            userOp.callGasLimit,
                            userOp.verificationGasLimit,
                            userOp.preVerificationGas,
                            userOp.maxFeePerGas,
                            userOp.maxPriorityFeePerGas,
                            keccak256(userOp.paymasterAndData),
                            EntryPoint,
                            uint256(bytes32(userOp.signature[1:33]))
                        )
                    )
                )
                : ECDSA.toEthSignedMessageHash(
                    keccak256(
                        abi.encode(
                            bytes32(block.chainid),
                            userOp.getSender(),
                            userOp.nonce,
                            keccak256(userOp.initCode),
                            keccak256(userOp.callData),
                            userOp.callGasLimit,
                            userOp.verificationGasLimit,
                            userOp.preVerificationGas,
                            userOp.maxFeePerGas,
                            userOp.maxPriorityFeePerGas,
                            keccak256(userOp.paymasterAndData),
                            EntryPoint,
                            uint256(bytes32(userOp.signature[1:33]))
                        )
                    )
                );
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32,
        address,
        uint256 missingAccountFunds
    ) public virtual returns (uint256) {
        if (missingAccountFunds != 0) {
            payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }("");
        }

        unchecked {
            if (userOp.nonce != nonce++) {
                return NONCE_VALIDATION_FAILED;
            }
        }

        if (
            ECDSA.recover(
                getUOPSignedHash(
                    SignatureType(uint8(bytes1(userOp.signature[0:1]))),
                    msg.sender,
                    userOp
                ),
                userOp.signature[33:]
            ) != owner
        ) {
            return SIG_VALIDATION_FAILED;
        } else {
            return uint256(bytes32(userOp.signature[1:33]));
        }
    }

    function validateUserOpWithoutSig(
        UserOperation calldata userOp,
        bytes32,
        address,
        uint256 missingAccountFunds
    ) public virtual returns (uint256) {
        if (missingAccountFunds != 0) {
            payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }("");
        }

        unchecked {
            if (userOp.nonce != nonce++) {
                return NONCE_VALIDATION_FAILED;
            }
        }

        if (
            ECDSA.recover(
                getUOPSignedHash(
                    SignatureType(uint8(bytes1(userOp.signature[0:1]))),
                    msg.sender,
                    userOp
                ),
                userOp.signature[33:]
            ) != owner
        ) {
            return uint256(bytes32(userOp.signature[1:33]));
        } else {
            return uint256(bytes32(userOp.signature[1:33]));
        }
    }

    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view returns (bytes4) {
        if (isOwner(ECDSA.recover(_hash, _signature))) {
            return 0x1626ba7e;
        } else {
            return 0xffffffff;
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;

/// @title Enum - Collection of enums
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
    enum SignatureType {
        EIP712Type,
        EIP191Type
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;

/// @title EtherPaymentFallback - A contract that has a fallback to accept ether payments
/// @author Richard Meissner - <[email protected]>
contract EtherPaymentFallback {
    event SafeReceived(address indexed sender, uint256 value);

    /// @dev Fallback function accepts Ether transactions.
    receive() external payable {
        emit SafeReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;

/// @title SecuredTokenTransfer - Secure token transfer
/// @author Richard Meissner - <[email protected]>
contract SecuredTokenTransfer {
    /// @dev Transfers a token and returns if it was a success
    /// @param token Token that should be transferred
    /// @param receiver Receiver to whom the token should be transferred
    /// @param amount The amount of tokens that should be transferred
    function transferToken(
        address token,
        address receiver,
        uint256 amount
    ) internal returns (bool transferred) {
        // 0xa9059cbb - keccack("transfer(address,uint256)")
        bytes memory data = abi.encodeWithSelector(
            0xa9059cbb,
            receiver,
            amount
        );
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We write the return value to scratch space.
            // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
            let success := call(
                sub(gas(), 10000),
                token,
                0,
                add(data, 0x20),
                mload(data),
                0,
                0x20
            )
            switch returndatasize()
            case 0 {
                transferred := success
            }
            case 0x20 {
                transferred := iszero(or(iszero(success), iszero(mload(0))))
            }
            default {
                transferred := 0
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;
import "../common/SelfAuthorized.sol";

/// @title SelfAuthorized - authorizes current contract to perform actions
/// @author Richard Meissner - <[email protected]>
contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
/// @author Richard Meissner - <[email protected]>
contract SignatureDecoder {
    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to peform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(
        bytes memory signatures,
        uint256 pos
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;
import "./SelfAuthorized.sol";

/// @title Singleton - Base for singleton contracts (should always be first super contract)
///         This contract is tightly coupled to our proxy contract
contract Singleton is SelfAuthorized {
    event ImplementUpdated(address indexed implement);
    address internal singleton;

    function updateImplement(address implement) external authorized {
        singleton = implement;
        emit ImplementUpdated(implement);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;

import "../interfaces/IStorage.sol";
import "./base/SignatureManager.sol";
import "./base/ModuleManager.sol";
import "./base/OwnerManager.sol";
import "./base/FallbackManager.sol";
import "./base/GuardManager.sol";
import "./common/EtherPaymentFallback.sol";
import "./common/Singleton.sol";
import "./common/SignatureDecoder.sol";
import "./common/SecuredTokenTransfer.sol";

contract SmartAccount is
    EtherPaymentFallback,
    Singleton,
    ModuleManager,
    OwnerManager,
    SignatureDecoder,
    SecuredTokenTransfer,
    FallbackManager,
    GuardManager,
    SignatureManager
{
    address public immutable EntryPoint;
    address public immutable FallbackHandler;

    constructor(
        address _EntryPoint,
        address _FallbackHandler,
        string memory _name,
        string memory _version
    ) SignatureManager(_name, _version) {
        EntryPoint = _EntryPoint;
        FallbackHandler = _FallbackHandler;
    }

    modifier onlyEntryPoint() {
        require(msg.sender == EntryPoint, "Not from entrypoint");
        _;
    }

    function Initialize(address _owner) external {
        require(getOwner() == address(0), "account: have set up");
        initializeOwners(_owner);
        initializeFallbackHandler(FallbackHandler);
        initializeModules();
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        address aggregatorAddress,
        uint256 missingAccountFunds
    ) public override onlyEntryPoint returns (uint256 deadline) {
        deadline = super.validateUserOp(
            userOp,
            userOpHash,
            aggregatorAddress,
            missingAccountFunds
        );
    }

    function validateUserOpWithoutSig(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        address aggregatorAddress,
        uint256 missingAccountFunds
    ) public override onlyEntryPoint returns (uint256 deadline) {
        deadline = super.validateUserOpWithoutSig(
            userOp,
            userOpHash,
            aggregatorAddress,
            missingAccountFunds
        );
    }

    function execTransactionFromEntrypoint(
        address to,
        uint256 value,
        bytes calldata data
    ) public onlyEntryPoint {
        executeWithGuard(to, value, data);
    }

    function execTransactionFromEntrypointBatch(
        ExecuteParams[] calldata _params
    ) external onlyEntryPoint {
        executeWithGuardBatch(_params);
    }

    function execTransactionFromEntrypointBatchRevertOnFail(
        ExecuteParams[] calldata _params
    ) external onlyEntryPoint {
        execTransactionBatchRevertOnFail(_params);
    }

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) public override {
        IStorage(EntryPoint).validateModuleWhitelist(msg.sender);

        if (operation == Enum.Operation.Call) {
            ModuleManager.execTransactionFromModule(to, value, data, operation);
        } else {
            address originalFallbackHandler = getFallbackHandler();

            setFallbackHandler(msg.sender, true);
            ModuleManager.execTransactionFromModule(to, value, data, operation);
            setFallbackHandler(originalFallbackHandler, false);
        }
    }
}