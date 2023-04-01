/**
 *Submitted for verification at Arbiscan on 2023-03-28
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File @openzeppelin/contracts/utils/math/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

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


// File @unirep/contracts/libraries/[email protected]

pragma solidity ^0.8.0;

/**
 * From circom using BN128
 * FF exp test values
  R = 28948022309329048855892746252171976963317496166410141009864396001978282409984
  Powers [0-19]
 1
 7059779437489773633646340506914701874769131765994106666166191815402473914367
 12371195157981417840429332247599076334089127903467109501118851908640962647771
 91664821030372581679529607375628823756310439149668501645026407448390597633
 16038164219872748879312642959218862190022861235439020164442255207612871130925
 16782616356586008555702541307566571321530156043407345068293574289799682219660
 19774252239193942055053397695411540560120864151929945406812607060161406974484
 12565986371265850126962811242062249653567082821075564068236826220915416262239
 15609501148448213614522449500500658108549566168199359481845786594163638947641
 20631068592690306338407392191950142757118341468130858982604614960963878215473
 3791600239509551572519234405706855702216993741788790221466416187007632677497
 10815827326662150813626071182635121317639352568885885274309360111072998601528
 15600778020166651892596275860496285275273760257631315438554816757615180856234
 20298753097936865355533241960438718356663309589256341841967409598911021895498
 3724975639185873342521000097021393954118195620533284401633502590886953579843
 13372215639090690721743233990023256146327241960786387108702673553974060503578
 18993237427188252938652200035114407085357284393296647360731174809968242835526
 17903352644817575960330467613456889750459845398329326464233774021612392233415
 3947411764431538711617944989308150320853861220898483040668646843225340304690
 9077311072387902334759390203097943153730624929858882748844779783513425243973
 */

struct PolysumData {
    uint hash;
    uint index;
}

// Calculate a hash of elements using a polynomial equation
library Polysum {
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    function add(PolysumData storage self, uint val, uint R)
        public
        returns (uint)
    {
        require(val < SNARK_SCALAR_FIELD, 'vlarge');
        uint index = self.index++;
        uint coef = rForIndex(index, R);
        uint term = mulmod(coef, val, SNARK_SCALAR_FIELD);
        self.hash = addmod(self.hash, term, SNARK_SCALAR_FIELD);
        return index;
    }

    function add(PolysumData storage self, uint[] memory vals, uint R) public {
        require(vals.length < type(uint8).max, 'alarge');
        require(vals.length > 0, 'asmall');
        uint index = self.index;
        uint hash = self.hash;

        uint Rx = rForIndex(index, R);
        for (uint8 x = 0; x < vals.length; x++) {
            uint term = mulmod(Rx, vals[x], SNARK_SCALAR_FIELD);
            hash = addmod(hash, term, SNARK_SCALAR_FIELD);
            index++;
            Rx = mulmod(Rx, R, SNARK_SCALAR_FIELD);
        }
        self.hash = hash;
        self.index = index;
    }

    /**
     * Update an element in the hash for a degree
     **/
    function update(
        PolysumData storage self,
        uint index,
        uint oldval,
        uint newval,
        uint R
    ) public {
        require(oldval < SNARK_SCALAR_FIELD, 'ofield');
        require(newval < SNARK_SCALAR_FIELD, 'nfield');
        require(index < self.index, 'uindex');
        uint coef = rForIndex(index, R);
        uint oldterm = mulmod(coef, oldval, SNARK_SCALAR_FIELD);
        uint newterm = mulmod(coef, newval, SNARK_SCALAR_FIELD);
        uint diff = oldterm > newterm ? oldterm - newterm : newterm - oldterm;
        uint hash = self.hash;
        if (newterm > oldterm) {
            // we are applying an addition
            self.hash = addmod(hash, diff, SNARK_SCALAR_FIELD);
        } else if (diff <= hash) {
            // we can apply a normal subtraction (no mod)
            self.hash -= diff;
        } else {
            // we need to wrap, we're guaranteed that self.hash < diff < SNARK_SCALAR_FIELD
            self.hash = SNARK_SCALAR_FIELD - (diff - hash);
        }
    }

    /**
     * Calculate R ** degree % SNARK_SCALAR_FIELD
     **/
    function rForIndex(uint _index, uint R) public view returns (uint xx) {
        if (_index == 0) return R;
        uint _F = SNARK_SCALAR_FIELD;
        uint index = _index + 1;
        // modular exponentiation
        assembly {
            let freemem := mload(0x40)
            // length_of_BASE: 32 bytes
            mstore(freemem, 0x20)
            // length_of_EXPONENT: 32 bytes
            mstore(add(freemem, 0x20), 0x20)
            // length_of_MODULUS: 32 bytes
            mstore(add(freemem, 0x40), 0x20)
            // BASE
            mstore(add(freemem, 0x60), R)
            // EXPONENT
            mstore(add(freemem, 0x80), index)
            // MODULUS
            mstore(add(freemem, 0xA0), _F)
            let success := staticcall(
                sub(gas(), 2000),
                // call the address 0x00......05
                5,
                // loads the 6 * 32 bytes inputs from <freemem>
                freemem,
                0xC0,
                // stores the 32 bytes return at <freemem>
                freemem,
                0x20
            )
            xx := mload(freemem)
        }
    }
}


// File @zk-kit/incremental-merkle-tree.sol/[email protected]

pragma solidity ^0.8.4;

library PoseidonT3 {
    function poseidon(uint256[2] memory) public pure returns (uint256) {}
}

library PoseidonT6 {
    function poseidon(uint256[5] memory) public pure returns (uint256) {}
}


// File @zk-kit/incremental-merkle-tree.sol/[email protected]

pragma solidity ^0.8.4;

// Each incremental tree has certain properties and data that will
// be used to add new leaves.
struct IncrementalTreeData {
    uint256 depth; // Depth of the tree (levels - 1).
    uint256 root; // Root hash of the tree.
    uint256 numberOfLeaves; // Number of leaves of the tree.
    mapping(uint256 => uint256) zeroes; // Zero hashes used for empty nodes (level -> zero hash).
    // The nodes of the subtrees used in the last addition of a leaf (level -> [left node, right node]).
    mapping(uint256 => uint256[2]) lastSubtrees; // Caching these values is essential to efficient appends.
}

/// @title Incremental binary Merkle tree.
/// @dev The incremental tree allows to calculate the root hash each time a leaf is added, ensuring
/// the integrity of the tree.
library IncrementalBinaryTree {
    uint8 internal constant MAX_DEPTH = 32;
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /// @dev Initializes a tree.
    /// @param self: Tree data.
    /// @param depth: Depth of the tree.
    /// @param zero: Zero value to be used.
    function init(
        IncrementalTreeData storage self,
        uint256 depth,
        uint256 zero
    ) public {
        require(zero < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(depth > 0 && depth <= MAX_DEPTH, "IncrementalBinaryTree: tree depth must be between 1 and 32");

        self.depth = depth;

        for (uint8 i = 0; i < depth; ) {
            self.zeroes[i] = zero;
            zero = PoseidonT3.poseidon([zero, zero]);

            unchecked {
                ++i;
            }
        }

        self.root = zero;
    }

    /// @dev Inserts a leaf in the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be inserted.
    function insert(IncrementalTreeData storage self, uint256 leaf) public {
        uint256 depth = self.depth;

        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(self.numberOfLeaves < 2**depth, "IncrementalBinaryTree: tree is full");

        uint256 index = self.numberOfLeaves;
        uint256 hash = leaf;

        for (uint8 i = 0; i < depth; ) {
            if (index & 1 == 0) {
                self.lastSubtrees[i] = [hash, self.zeroes[i]];
            } else {
                self.lastSubtrees[i][1] = hash;
            }

            hash = PoseidonT3.poseidon(self.lastSubtrees[i]);
            index >>= 1;

            unchecked {
                ++i;
            }
        }

        self.root = hash;
        self.numberOfLeaves += 1;
    }

    /// @dev Updates a leaf in the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be updated.
    /// @param newLeaf: New leaf.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function update(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256 newLeaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        require(newLeaf != leaf, "IncrementalBinaryTree: new leaf cannot be the same as the old one");
        require(newLeaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: new leaf must be < SNARK_SCALAR_FIELD");
        require(
            verify(self, leaf, proofSiblings, proofPathIndices),
            "IncrementalBinaryTree: leaf is not part of the tree"
        );

        uint256 depth = self.depth;
        uint256 hash = newLeaf;
        uint256 updateIndex;

        for (uint8 i = 0; i < depth; ) {
            updateIndex |= uint256(proofPathIndices[i]) << uint256(i);

            if (proofPathIndices[i] == 0) {
                if (proofSiblings[i] == self.lastSubtrees[i][1]) {
                    self.lastSubtrees[i][0] = hash;
                }

                hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
            } else {
                if (proofSiblings[i] == self.lastSubtrees[i][0]) {
                    self.lastSubtrees[i][1] = hash;
                }

                hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
            }

            unchecked {
                ++i;
            }
        }
        require(updateIndex < self.numberOfLeaves, "IncrementalBinaryTree: leaf index out of range");

        self.root = hash;
    }

    /// @dev Removes a leaf from the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function remove(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        update(self, leaf, self.zeroes[0], proofSiblings, proofPathIndices);
    }

    /// @dev Verify if the path is correct and the leaf is part of the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    /// @return True or false.
    function verify(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) private view returns (bool) {
        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        uint256 depth = self.depth;
        require(
            proofPathIndices.length == depth && proofSiblings.length == depth,
            "IncrementalBinaryTree: length of path is not correct"
        );

        uint256 hash = leaf;

        for (uint8 i = 0; i < depth; ) {
            require(
                proofSiblings[i] < SNARK_SCALAR_FIELD,
                "IncrementalBinaryTree: sibling node must be < SNARK_SCALAR_FIELD"
            );

            require(
                proofPathIndices[i] == 1 || proofPathIndices[i] == 0,
                "IncrementalBinaryTree: path index is neither 0 nor 1"
            );

            if (proofPathIndices[i] == 0) {
                hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
            } else {
                hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
            }

            unchecked {
                ++i;
            }
        }

        return hash == self.root;
    }
}


// File @unirep/contracts/interfaces/[email protected]

pragma solidity ^0.8.0;


interface IUnirep {
    event AttesterSignedUp(
        uint160 indexed attesterId,
        uint256 epochLength,
        uint256 timestamp
    );

    event UserSignedUp(
        uint256 indexed epoch,
        uint256 indexed identityCommitment,
        uint160 indexed attesterId,
        uint256 leafIndex
    );

    event UserStateTransitioned(
        uint256 indexed epoch,
        uint160 indexed attesterId,
        uint256 indexed leafIndex,
        uint256 hashedLeaf,
        uint256 nullifier
    );

    event Attestation(
        uint256 indexed epoch,
        uint256 indexed epochKey,
        uint160 indexed attesterId,
        uint256 fieldIndex,
        uint256 change,
        uint256 timestamp
    );

    event StateTreeLeaf(
        uint256 indexed epoch,
        uint160 indexed attesterId,
        uint256 indexed index,
        uint256 leaf
    );

    event EpochTreeLeaf(
        uint256 indexed epoch,
        uint160 indexed attesterId,
        uint256 indexed index,
        uint256 leaf
    );

    event EpochEnded(uint256 indexed epoch, uint160 indexed attesterId);

    event EpochSealed(uint256 indexed epoch, uint160 indexed attesterId);

    // error
    error UserAlreadySignedUp(uint256 identityCommitment);
    error AttesterAlreadySignUp(uint160 attester);
    error AttesterNotSignUp(uint160 attester);
    error AttesterInvalid();
    error ProofAlreadyUsed(bytes32 nullilier);
    error NullifierAlreadyUsed(uint256 nullilier);
    error AttesterIdNotMatch(uint160 attesterId);
    error OutOfRange();
    error InvalidField();

    error InvalidSignature();
    error InvalidEpochKey();
    error EpochNotMatch();
    error InvalidEpoch(uint256 epoch);
    error MaxAttestations();
    error NoAttestations();
    error DoubleSeal();
    error IncorrectHash();

    error InvalidProof();
    error InvalidStateTreeRoot(uint256 stateTreeRoot);
    error InvalidEpochTreeRoot(uint256 epochTreeRoot);

    error EpochNotSealed();

    struct EpochKeySignals {
        uint256 revealNonce;
        uint256 stateTreeRoot;
        uint256 epochKey;
        uint256 data;
        uint256 nonce;
        uint256 epoch;
        uint256 attesterId;
    }

    struct ReputationSignals {
        uint256 stateTreeRoot;
        uint256 epochKey;
        uint256 graffitiPreImage;
        uint256 proveGraffiti;
        uint256 nonce;
        uint256 epoch;
        uint256 attesterId;
        uint256 revealNonce;
        uint256 proveMinRep;
        uint256 proveMaxRep;
        uint256 proveZeroRep;
        uint256 minRep;
        uint256 maxRep;
    }

    struct AttesterState {
        // latest epoch key balances
        ///// Needs to be manually set to FIELD_COUNT
        mapping(uint256 => PolysumData) epkPolysum;
        mapping(uint256 => uint256[30]) data;
        mapping(uint256 => uint256[30]) dataHashes;
        // epoch key => polyhash degree
        mapping(uint256 => uint256) epochKeyIndex;
        // epoch key => latest leaf (0 if no attestation in epoch)
        mapping(uint256 => uint256) epochKeyLeaves;
        // the attester polysum
        PolysumData polysum;
    }

    struct AttesterData {
        // epoch keyed to tree data
        mapping(uint256 => IncrementalTreeData) stateTrees;
        // epoch keyed to root keyed to whether it's valid
        mapping(uint256 => mapping(uint256 => bool)) stateTreeRoots;
        // epoch keyed to root
        mapping(uint256 => uint256) epochTreeRoots;
        uint256 startTimestamp;
        uint256 currentEpoch;
        uint256 epochLength;
        mapping(uint256 => bool) identityCommitments;
        IncrementalTreeData semaphoreGroup;
        // attestation management
        mapping(uint256 => AttesterState) state;
    }

    struct Config {
        // circuit config
        uint8 stateTreeDepth;
        uint8 epochTreeDepth;
        uint8 epochTreeArity;
        uint8 fieldCount;
        uint8 sumFieldCount;
        uint8 numEpochKeyNoncePerEpoch;
    }
}


// File @unirep/contracts/libraries/[email protected]

pragma solidity ^0.8.0;

// verify signature use for relayer
// NOTE: This method not safe, contract may attack by signature replay.
contract VerifySignature {
    /**
     * Verify if the signer has a valid signature as claimed
     * @param signer The address of user who wants to perform an action
     * @param signature The signature signed by the signer
     */
    function isValidSignature(address signer, bytes memory signature)
        internal
        view
        returns (bool)
    {
        // Attester signs over it's own address concatenated with this contract address
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                '\x19Ethereum Signed Message:\n32',
                keccak256(abi.encodePacked(signer, this))
            )
        );
        return ECDSA.recover(messageHash, signature) == signer;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     * IMPORTANT: because control is transferred to `recipient`, care must be
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


// File @openzeppelin/contracts/utils/math/[email protected]

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


// File @unirep/contracts/interfaces/[email protected]

pragma solidity ^0.8.0;

// Verifier interface
// Verifier should follow IVerifer interface.
interface IVerifier {
    /**
     * @return bool Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[] calldata publicSignals,
        uint256[8] calldata proof
    ) external view returns (bool);
}


// File poseidon-solidity/[email protected]

pragma solidity >=0.7.0;

library PoseidonT2 {
  uint constant F = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

  uint constant M00 = 0x066f6f85d6f68a85ec10345351a23a3aaf07f38af8c952a7bceca70bd2af7ad5;
  uint constant M01 = 0x0cc57cdbb08507d62bf67a4493cc262fb6c09d557013fff1f573f431221f8ff9;
  uint constant M10 = 0x2b9d4b4110c9ae997782e1509b1d0fdb20a7c02bbd8bea7305462b9f8125b1e8;
  uint constant M11 = 0x1274e649a32ed355a31a6ed69724e1adade857e86eb5c3a121bcd147943203c8;

  // See here for a simplified implementation: https://github.com/vimwitch/poseidon-solidity/blob/e57becdabb65d99fdc586fe1e1e09e7108202d53/contracts/Poseidon.sol#L40
  // Based on: https://github.com/iden3/circomlibjs/blob/v0.0.8/src/poseidon_slow.js
  function hash(uint[1] memory) public pure returns (uint) {
    assembly {
      // memory 0x00 to 0x3f (64 bytes) is scratch space for hash algos
      // we can use it in inline assembly because we're not calling e.g. keccak
      //
      // memory 0x80 is the default offset for free memory
      // we take inputs as a memory argument so we simply write over
      // that memory after loading it

      // we have the following variables at memory offsets
      // state0 - 0x00
      // state1 - 0x20
      // state2 - 0x80
      // state3 - 0xa0
      // state4 - ...

      function pRound(c0, c1) {
        let state0 := addmod(mload(0x0), c0, F)
        let state1 := addmod(mload(0x20), c1, F)

        let p := mulmod(state0, state0, F)
        state0 := mulmod(mulmod(p, p, F), state0, F)

        mstore(0x0, addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F))
        mstore(0x20, addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F))
      }

      function fRound(c0, c1) {
        let state0 := addmod(mload(0x0), c0, F)
        let state1 := addmod(mload(0x20), c1, F)

        let p := mulmod(state0, state0, F)
        state0 := mulmod(mulmod(p, p, F), state0, F)
        p := mulmod(state1, state1, F)
        state1 := mulmod(mulmod(p, p, F), state1, F)

        mstore(0x0, addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F))
        mstore(0x20, addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F))
      }

      // scratch variable for exponentiation
      let p

      {
        // load the inputs from memory
        let state1 := addmod(mload(0x80), 0x0c0356530896eec42a97ed937f3135cfc5142b3ae405b8343c1d83ffa604cb81, F)
        mstore(0x20, addmod(mload(0xa0), 0x1e28a1d935698ad1142e51182bb54cf4a00ea5aabd6268bd317ea977cc154a30, F))

        p := mulmod(state1, state1, F)
        state1 := mulmod(mulmod(p, p, F), state1, F)

        // state0 pow5mod and M[] multiplications are pre-calculated

        mstore(0x0, addmod(0x4b87ca7dc8593e8efd436c4e47f32a16e36f24c756ebb53ff0ab98c1608e8f5, mulmod(state1, M10, F), F))
        mstore(0x20, addmod(0x20a7d25895731bd7cf65a14cce92a52ae70d529cd9531696f88536d5859bf85a, mulmod(state1, M11, F), F))
      }

      fRound(0x1e28a1d935698ad1142e51182bb54cf4a00ea5aabd6268bd317ea977cc154a30, 0x27af2d831a9d2748080965db30e298e40e5757c3e008db964cf9e2b12b91251f)

      fRound(0x1e6f11ce60fc8f513a6a3cfe16ae175a41291462f214cd0879aaf43545b74e03, 0x2a67384d3bbd5e438541819cb681f0be04462ed14c3613d8f719206268d142d3)

      fRound(0x0b66fdf356093a611609f8e12fbfecf0b985e381f025188936408f5d5c9f45d0, 0x012ee3ec1e78d470830c61093c2ade370b26c83cc5cebeeddaa6852dbdb09e21)

      pRound(0x0252ba5f6760bfbdfd88f67f8175e3fd6cd1c431b099b6bb2d108e7b445bb1b9, 0x179474cceca5ff676c6bec3cef54296354391a8935ff71d6ef5aeaad7ca932f1)

      pRound(0x2c24261379a51bfa9228ff4a503fd4ed9c1f974a264969b37e1a2589bbed2b91, 0x1cc1d7b62692e63eac2f288bd0695b43c2f63f5001fc0fc553e66c0551801b05)

      pRound(0x255059301aada98bb2ed55f852979e9600784dbf17fbacd05d9eff5fd9c91b56, 0x28437be3ac1cb2e479e1f5c0eccd32b3aea24234970a8193b11c29ce7e59efd9)

      pRound(0x28216a442f2e1f711ca4fa6b53766eb118548da8fb4f78d4338762c37f5f2043, 0x2c1f47cd17fa5adf1f39f4e7056dd03feee1efce03094581131f2377323482c9)

      pRound(0x07abad02b7a5ebc48632bcc9356ceb7dd9dafca276638a63646b8566a621afc9, 0x0230264601ffdf29275b33ffaab51dfe9429f90880a69cd137da0c4d15f96c3c)

      pRound(0x1bc973054e51d905a0f168656497ca40a864414557ee289e717e5d66899aa0a9, 0x2e1c22f964435008206c3157e86341edd249aff5c2d8421f2a6b22288f0a67fc)

      pRound(0x1224f38df67c5378121c1d5f461bbc509e8ea1598e46c9f7a70452bc2bba86b8, 0x02e4e69d8ba59e519280b4bd9ed0068fd7bfe8cd9dfeda1969d2989186cde20e)

      pRound(0x1f1eccc34aaba0137f5df81fc04ff3ee4f19ee364e653f076d47e9735d98018e, 0x1672ad3d709a353974266c3039a9a7311424448032cd1819eacb8a4d4284f582)

      pRound(0x283e3fdc2c6e420c56f44af5192b4ae9cda6961f284d24991d2ed602df8c8fc7, 0x1c2a3d120c550ecfd0db0957170fa013683751f8fdff59d6614fbd69ff394bcc)

      pRound(0x216f84877aac6172f7897a7323456efe143a9a43773ea6f296cb6b8177653fbd, 0x2c0d272becf2a75764ba7e8e3e28d12bceaa47ea61ca59a411a1f51552f94788)

      pRound(0x16e34299865c0e28484ee7a74c454e9f170a5480abe0508fcb4a6c3d89546f43, 0x175ceba599e96f5b375a232a6fb9cc71772047765802290f48cd939755488fc5)

      pRound(0x0c7594440dc48c16fead9e1758b028066aa410bfbc354f54d8c5ffbb44a1ee32, 0x1a3c29bc39f21bb5c466db7d7eb6fd8f760e20013ccf912c92479882d919fd8d)

      pRound(0x0ccfdd906f3426e5c0986ea049b253400855d349074f5a6695c8eeabcd22e68f, 0x14f6bc81d9f186f62bdb475ce6c9411866a7a8a3fd065b3ce0e699b67dd9e796)

      pRound(0x0962b82789fb3d129702ca70b2f6c5aacc099810c9c495c888edeb7386b97052, 0x1a880af7074d18b3bf20c79de25127bc13284ab01ef02575afef0c8f6a31a86d)

      pRound(0x10cba18419a6a332cd5e77f0211c154b20af2924fc20ff3f4c3012bb7ae9311b, 0x057e62a9a8f89b3ebdc76ba63a9eaca8fa27b7319cae3406756a2849f302f10d)

      pRound(0x287c971de91dc0abd44adf5384b4988cb961303bbf65cff5afa0413b44280cee, 0x21df3388af1687bbb3bca9da0cca908f1e562bc46d4aba4e6f7f7960e306891d)

      pRound(0x1be5c887d25bce703e25cc974d0934cd789df8f70b498fd83eff8b560e1682b3, 0x268da36f76e568fb68117175cea2cd0dd2cb5d42fda5acea48d59c2706a0d5c1)

      pRound(0x0e17ab091f6eae50c609beaf5510ececc5d8bb74135ebd05bd06460cc26a5ed6, 0x04d727e728ffa0a67aee535ab074a43091ef62d8cf83d270040f5caa1f62af40)

      pRound(0x0ddbd7bf9c29341581b549762bc022ed33702ac10f1bfd862b15417d7e39ca6e, 0x2790eb3351621752768162e82989c6c234f5b0d1d3af9b588a29c49c8789654b)

      pRound(0x1e457c601a63b73e4471950193d8a570395f3d9ab8b2fd0984b764206142f9e9, 0x21ae64301dca9625638d6ab2bbe7135ffa90ecd0c43ff91fc4c686fc46e091b0)

      pRound(0x0379f63c8ce3468d4da293166f494928854be9e3432e09555858534eed8d350b, 0x002d56420359d0266a744a080809e054ca0e4921a46686ac8c9f58a324c35049)

      pRound(0x123158e5965b5d9b1d68b3cd32e10bbeda8d62459e21f4090fc2c5af963515a6, 0x0be29fc40847a941661d14bbf6cbe0420fbb2b6f52836d4e60c80eb49cad9ec1)

      pRound(0x1ac96991dec2bb0557716142015a453c36db9d859cad5f9a233802f24fdf4c1a, 0x1596443f763dbcc25f4964fc61d23b3e5e12c9fa97f18a9251ca3355bcb0627e)

      pRound(0x12e0bcd3654bdfa76b2861d4ec3aeae0f1857d9f17e715aed6d049eae3ba3212, 0x0fc92b4f1bbea82b9ea73d4af9af2a50ceabac7f37154b1904e6c76c7cf964ba)

      pRound(0x1f9c0b1610446442d6f2e592a8013f40b14f7c7722236f4f9c7e965233872762, 0x0ebd74244ae72675f8cde06157a782f4050d914da38b4c058d159f643dbbf4d3)

      pRound(0x2cb7f0ed39e16e9f69a9fafd4ab951c03b0671e97346ee397a839839dccfc6d1, 0x1a9d6e2ecff022cc5605443ee41bab20ce761d0514ce526690c72bca7352d9bf)

      pRound(0x2a115439607f335a5ea83c3bc44a9331d0c13326a9a7ba3087da182d648ec72f, 0x23f9b6529b5d040d15b8fa7aee3e3410e738b56305cd44f29535c115c5a4c060)

      pRound(0x05872c16db0f72a2249ac6ba484bb9c3a3ce97c16d58b68b260eb939f0e6e8a7, 0x1300bdee08bb7824ca20fb80118075f40219b6151d55b5c52b624a7cdeddf6a7)

      pRound(0x19b9b63d2f108e17e63817863a8f6c288d7ad29916d98cb1072e4e7b7d52b376, 0x015bee1357e3c015b5bda237668522f613d1c88726b5ec4224a20128481b4f7f)

      pRound(0x2953736e94bb6b9f1b9707a4f1615e4efe1e1ce4bab218cbea92c785b128ffd1, 0x0b069353ba091618862f806180c0385f851b98d372b45f544ce7266ed6608dfc)

      pRound(0x304f74d461ccc13115e4e0bcfb93817e55aeb7eb9306b64e4f588ac97d81f429, 0x15bbf146ce9bca09e8a33f5e77dfe4f5aad2a164a4617a4cb8ee5415cde913fc)

      pRound(0x0ab4dfe0c2742cde44901031487964ed9b8f4b850405c10ca9ff23859572c8c6, 0x0e32db320a044e3197f45f7649a19675ef5eedfea546dea9251de39f9639779a)

      pRound(0x0a1756aa1f378ca4b27635a78b6888e66797733a82774896a3078efa516da016, 0x044c4a33b10f693447fd17177f952ef895e61d328f85efa94254d6a2a25d93ef)

      pRound(0x2ed3611b725b8a70be655b537f66f700fe0879d79a496891d37b07b5466c4b8b, 0x1f9ba4e8bab7ce42c8ecc3d722aa2e0eadfdeb9cfdd347b5d8339ea7120858aa)

      pRound(0x1b233043052e8c288f7ee907a84e518aa38e82ac4502066db74056f865c5d3da, 0x2431e1cc164bb8d074031ab72bd55b4c902053bfc0f14db0ca2f97b020875954)

      pRound(0x082f934c91f5aac330cd6953a0a7db45a13e322097583319a791f273965801fd, 0x2b9a0a223e7538b0a34be074315542a3c77245e2ae7cbe999ad6bb930c48997c)

      pRound(0x0e1cd91edd2cfa2cceb85483b887a9be8164163e75a8a00eb0b589cc70214e7d, 0x2e1eac0f2bfdfd63c951f61477e3698999774f19854d00f588d324601cebe2f9)

      pRound(0x0cbfa95f37fb74060c76158e769d6d157345784d8efdb33c23d748115b500b83, 0x08f05b3be923ed44d65ad49d8a61e9a676d991e3a77513d9980c232dfa4a4f84)

      pRound(0x22719e2a070bcd0852bf8e21984d0443e7284925dc0758a325a2dd510c047ef6, 0x041f596a9ee1cb2bc060f7fcc3a1ab4c7bdbf036119982c0f41f62b2f26830c0)

      pRound(0x233fd35de1be520a87628eb06f6b1d4c021be1c2d0dc464a19fcdd0986b10f89, 0x0524b46d1aa87a5e4325e0a423ebc810d31e078aa1b4707eefcb453c61c9c267)

      pRound(0x2c34f424c81e5716ce47fcac894b85824227bb954b0f3199cc4486237c515211, 0x0b5f2a4b63387819207effc2b5541fb72dd2025b5457cc97f33010327de4915e)

      pRound(0x22207856082ccc54c5b72fe439d2cfd6c17435d2f57af6ceaefac41fe05c659f, 0x24d57a8bf5da63fe4e24159b7f8950b5cdfb210194caf79f27854048ce2c8171)

      pRound(0x0afab181fdd5e0583b371d75bd693f98374ad7097bb01a8573919bb23b79396e, 0x2dba9b108f208772998a52efac7cbd5676c0057194c16c0bf16290d62b1128ee)

      pRound(0x26349b66edb8b16f56f881c788f53f83cbb83de0bd592b255aff13e6bce420b3, 0x25af7ce0e5e10357685e95f92339753ad81a56d28ecc193b235288a3e6f137db)

      pRound(0x25b4ce7bd2294390c094d6a55edd68b970eed7aae88b2bff1f7c0187fe35011f, 0x22c543f10f6c89ec387e53f1908a88e5de9cef28ebdf30b18cb9d54c1e02b631)

      pRound(0x0236f93e7789c4724fc7908a9f191e1e425e906a919d7a34df668e74882f87a9, 0x29350b401166ca010e7d27e37d05da99652bdae114eb01659cb497af980c4b52)

      pRound(0x0eed787d65820d3f6bd31bbab547f75a65edb75d844ebb89ee1260916652363f, 0x07cc1170f13b46f2036a753f520b3291fdcd0e99bd94297d1906f656f4de6fad)

      pRound(0x22b939233b1d7205f49bcf613a3d30b1908786d7f9f5d10c2059435689e8acea, 0x01451762a0aab81c8aad1dc8bc33e870740f083a5aa85438add650ace60ae5a6)

      pRound(0x23506bb5d8727d4461fabf1025d46d1fe32eaa61dec7da57e704fec0892fce89, 0x2e484c44e838aea0bac06ae3f71bdd092a3709531e1efea97f8bd68907355522)

      pRound(0x0f4bc7d07ebafd64379e78c50bd2e42baf4a594545cedc2545418da26835b54c, 0x1f4d3c8f6583e9e5fa76637862faaee851582388725df460e620996d50d8e74e)

      pRound(0x093514e0c70711f82660d07be0e4a988fae02abc7b681d9153eb9bcb48fe7389, 0x1adab0c8e2b3bad346699a2b5f3bc03643ee83ece47228f24a58e0a347e153d8)

      pRound(0x1672b1726057d99dd14709ebb474641a378c1b94b8072bac1a22dbef9e80dad2, 0x1dfd53d4576af2e38f44f53fdcab468cc5d8e2fae0acc4ee30d47b239b479c14)

      pRound(0x0c6888a10b75b0f3a70a36263a37e17fe6d77d640f6fc3debc7f207753205c60, 0x1addb933a65be77092b34a7e77d12fe8611a61e00ee6848b85091ecca9d1e508)

      pRound(0x00d7540dcd268a845c10ae18d1de933cf638ff5425f0afff7935628e299d1791, 0x140c0e42687e9ead01b2827a5664ca9c26fedde4acd99db1d316939d20b82c0e)

      pRound(0x2f0c3a115d4317d191ba89b8d13d1806c20a0f9b24f8c5edc091e2ae56565984, 0x0c4ee778ff7c14553006ed220cf9c81008a0cff670b22b82d8c538a1dc958c61)

      pRound(0x1704f2766d46f82c3693f00440ccc3609424ed26c0acc66227c3d7485de74c69, 0x2f2d19cc3ea5d78ea7a02c1b51d244abf0769c9f8544e40239b66fe9009c3cfa)

      fRound(0x1ae03853b75fcaba5053f112e2a8e8dcdd7ee6cb9cfed9c7d6c766a806fc6629, 0x0971aabf795241df51d131d0fa61aa5f3556921b2d6f014e4e41a86ddaf056d5)

      fRound(0x1408c316e6014e1a91d4cf6b6e0de73eda624f8380df1c875f5c29f7bfe2f646, 0x1667f3fe2edbe850248abe42b543093b6c89f1f773ef285341691f39822ef5bd)

      fRound(0x13bf7c5d0d2c4376a48b0a03557cdf915b81718409e5c133424c69576500fe37, 0x07620a6dfb0b6cec3016adf3d3533c24024b95347856b79719bc0ba743a62c2c)

      {
        let state0 := addmod(mload(0x0), 0x1574c7ef0c43545f36a8ca08bdbdd8b075d2959e2f322b731675de3e1982b4d0, F)
        let state1 := addmod(mload(0x20), 0x269e4b5b7a2eb21afd567970a717ceec5bd4184571c254fdc06e03a7ff8378f0, F)

        p := mulmod(state0, state0, F)
        state0 := mulmod(mulmod(p, p, F), state0, F)
        p := mulmod(state1, state1, F)
        state1 := mulmod(mulmod(p, p, F), state1, F)

        mstore(0x0, addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F))
        return(0, 0x20)
      }
    }
  }
}


// File @unirep/contracts/[email protected]

pragma solidity ^0.8.0;




/**
 * @title Unirep
 * @dev Unirep is a reputation which uses ZKP to preserve users' privacy.
 * Attester can give attestations to users, and users can optionally prove that how much reputation they have.
 */
contract Unirep is IUnirep, VerifySignature {
    using SafeMath for uint256;

    // All verifier contracts
    IVerifier public immutable signupVerifier;
    IVerifier public immutable userStateTransitionVerifier;
    IVerifier public immutable reputationVerifier;
    IVerifier public immutable epochKeyVerifier;
    IVerifier public immutable epochKeyLiteVerifier;
    IVerifier public immutable buildOrderedTreeVerifier;

    uint256 public constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 public immutable PoseidonT2_zero = PoseidonT2.hash([uint(0)]);

    uint256 public constant OMT_R =
        19840472963655813647419884432877523255831900116552197704230384899846353674447;
    uint256 public constant EPK_R =
        11105707062209303735980536775061420040143715723438319441848723820903914190159;

    // Attester id == address
    mapping(uint160 => AttesterData) attesters;

    // for cheap initialization
    IncrementalTreeData emptyTree;

    // Mapping of used nullifiers
    mapping(uint256 => bool) public usedNullifiers;

    uint8 public immutable stateTreeDepth;
    uint8 public immutable epochTreeDepth;
    uint8 public immutable epochTreeArity;
    uint8 public immutable fieldCount;
    uint8 public immutable sumFieldCount;
    uint8 public immutable numEpochKeyNoncePerEpoch;

    constructor(
        Config memory _config,
        IVerifier _signupVerifier,
        IVerifier _userStateTransitionVerifier,
        IVerifier _reputationVerifier,
        IVerifier _epochKeyVerifier,
        IVerifier _epochKeyLiteVerifier,
        IVerifier _buildOrderedTreeVerifier
    ) {
        stateTreeDepth = _config.stateTreeDepth;
        epochTreeDepth = _config.epochTreeDepth;
        epochTreeArity = _config.epochTreeArity;
        fieldCount = _config.fieldCount;
        sumFieldCount = _config.sumFieldCount;
        numEpochKeyNoncePerEpoch = _config.numEpochKeyNoncePerEpoch;

        // Set the verifier contracts
        signupVerifier = _signupVerifier;
        userStateTransitionVerifier = _userStateTransitionVerifier;
        reputationVerifier = _reputationVerifier;
        epochKeyVerifier = _epochKeyVerifier;
        epochKeyLiteVerifier = _epochKeyLiteVerifier;
        buildOrderedTreeVerifier = _buildOrderedTreeVerifier;

        // for initializing other trees without using poseidon function
        IncrementalBinaryTree.init(emptyTree, _config.stateTreeDepth, 0);
        emit AttesterSignedUp(0, type(uint64).max, block.timestamp);
        attesters[uint160(0)].epochLength = type(uint64).max;
        attesters[uint160(0)].startTimestamp = block.timestamp;
    }

    function config() public view returns (Config memory) {
        return
            Config({
                stateTreeDepth: stateTreeDepth,
                epochTreeDepth: epochTreeDepth,
                epochTreeArity: epochTreeArity,
                fieldCount: fieldCount,
                sumFieldCount: sumFieldCount,
                numEpochKeyNoncePerEpoch: numEpochKeyNoncePerEpoch
            });
    }

    /**
     * @dev User signs up by provding a zk proof outputting identity commitment and new gst leaf.
     * msg.sender must be attester
     */
    function userSignUp(uint256[] memory publicSignals, uint256[8] memory proof)
        public
    {
        uint256 attesterId = publicSignals[2];
        // only allow attester to sign up users
        if (uint256(uint160(msg.sender)) != attesterId)
            revert AttesterIdNotMatch(uint160(msg.sender));
        // Verify the proof
        if (!signupVerifier.verifyProof(publicSignals, proof))
            revert InvalidProof();

        uint256 identityCommitment = publicSignals[0];
        _updateEpochIfNeeded(attesterId);
        AttesterData storage attester = attesters[uint160(attesterId)];
        if (attester.startTimestamp == 0)
            revert AttesterNotSignUp(uint160(attesterId));

        if (attester.identityCommitments[identityCommitment])
            revert UserAlreadySignedUp(identityCommitment);
        attester.identityCommitments[identityCommitment] = true;

        if (attester.currentEpoch != publicSignals[3]) revert EpochNotMatch();

        emit UserSignedUp(
            attester.currentEpoch,
            identityCommitment,
            uint160(attesterId),
            attester.stateTrees[attester.currentEpoch].numberOfLeaves
        );
        emit StateTreeLeaf(
            attester.currentEpoch,
            uint160(attesterId),
            attester.stateTrees[attester.currentEpoch].numberOfLeaves,
            publicSignals[1]
        );
        IncrementalBinaryTree.insert(
            attester.stateTrees[attester.currentEpoch],
            publicSignals[1]
        );
        attester.stateTreeRoots[attester.currentEpoch][
            attester.stateTrees[attester.currentEpoch].root
        ] = true;
        IncrementalBinaryTree.insert(
            attester.semaphoreGroup,
            identityCommitment
        );
    }

    /**
     * @dev Allow an attester to signup and specify their epoch length
     */
    function _attesterSignUp(address attesterId, uint256 epochLength) private {
        AttesterData storage attester = attesters[uint160(attesterId)];
        if (attester.startTimestamp != 0)
            revert AttesterAlreadySignUp(uint160(attesterId));
        attester.startTimestamp = block.timestamp;

        // initialize the first state tree
        for (uint8 i; i < stateTreeDepth; i++) {
            attester.stateTrees[0].zeroes[i] = emptyTree.zeroes[i];
        }
        attester.stateTrees[0].root = emptyTree.root;
        attester.stateTrees[0].depth = stateTreeDepth;
        attester.stateTreeRoots[0][emptyTree.root] = true;

        // initialize the semaphore group tree
        for (uint8 i; i < stateTreeDepth; i++) {
            attester.semaphoreGroup.zeroes[i] = emptyTree.zeroes[i];
        }
        attester.semaphoreGroup.root = emptyTree.root;
        attester.semaphoreGroup.depth = stateTreeDepth;

        // set the epoch length
        attester.epochLength = epochLength;

        emit AttesterSignedUp(
            uint160(attesterId),
            epochLength,
            attester.startTimestamp
        );
    }

    /**
     * @dev Sign up an attester using the address who sends the transaction
     */
    function attesterSignUp(uint256 epochLength) public {
        _attesterSignUp(msg.sender, epochLength);
    }

    /**
     * @dev Sign up an attester using the claimed address and the signature
     * @param attester The address of the attester who wants to sign up
     * @param signature The signature of the attester
     */
    function attesterSignUpViaRelayer(
        address attester,
        uint256 epochLength,
        bytes calldata signature
    ) public {
        // TODO: verify epoch length in signature
        if (!isValidSignature(attester, signature)) revert InvalidSignature();
        _attesterSignUp(attester, epochLength);
    }

    /**
     * @dev Attest to a change in data for a user that controls `epochKey`
     */
    function attest(uint256 epochKey, uint epoch, uint fieldIndex, uint change)
        public
    {
        {
            uint currentEpoch = updateEpochIfNeeded(uint160(msg.sender));
            if (epoch != currentEpoch) revert EpochNotMatch();
        }
        if (epochKey >= SNARK_SCALAR_FIELD) revert InvalidEpochKey();

        if (fieldIndex >= fieldCount) revert InvalidField();

        AttesterState storage state = attesters[uint160(msg.sender)].state[
            epoch
        ];
        PolysumData storage epkPolysum = state.epkPolysum[epochKey];

        bool newKey;
        {
            uint[30] storage data = state.data[epochKey];
            uint[30] storage dataHashes = state.dataHashes[epochKey];

            // First handle updating the epoch tree leaf polysum
            // lazily initialize the epk polysum state
            newKey = epkPolysum.hash == 0;
            if (newKey) {
                uint[] memory vals = new uint[](fieldCount + 1);
                vals[0] = PoseidonT2.hash([epochKey]);
                for (uint8 x = 0; x < fieldCount; x++) {
                    vals[x + 1] = PoseidonT2_zero;
                }
                Polysum.add(epkPolysum, vals, EPK_R);
            }
            if (fieldIndex < sumFieldCount) {
                // do a sum field change
                uint oldVal = data[fieldIndex];
                uint newVal = addmod(oldVal, change, SNARK_SCALAR_FIELD);
                uint oldHash = oldVal == 0
                    ? PoseidonT2_zero
                    : dataHashes[fieldIndex];
                uint newHash = PoseidonT2.hash([newVal]);
                Polysum.update(
                    epkPolysum,
                    fieldIndex + 1,
                    oldHash,
                    newHash,
                    EPK_R
                );
                data[fieldIndex] = newVal;
                dataHashes[fieldIndex] = newHash;
            } else {
                if (fieldIndex % 2 != sumFieldCount % 2) {
                    // cannot attest to a timestamp
                    revert InvalidField();
                }
                if (change >= SNARK_SCALAR_FIELD) revert OutOfRange();
                {
                    uint oldVal = data[fieldIndex];

                    uint newValHash = PoseidonT2.hash([change]);
                    uint oldValHash = oldVal == 0
                        ? PoseidonT2_zero
                        : dataHashes[fieldIndex];
                    data[fieldIndex] = change;
                    dataHashes[fieldIndex] = newValHash;
                    // update data
                    Polysum.update(
                        epkPolysum,
                        fieldIndex + 1,
                        oldValHash,
                        newValHash,
                        EPK_R
                    );
                }
                {
                    // update timestamp
                    uint oldTimestamp = data[fieldIndex + 1];
                    uint oldTimestampHash = oldTimestamp == 0
                        ? PoseidonT2_zero
                        : dataHashes[fieldIndex + 1];
                    uint newTimestampHash = PoseidonT2.hash([block.timestamp]);
                    data[fieldIndex + 1] = block.timestamp;
                    dataHashes[fieldIndex + 1] = newTimestampHash;
                    Polysum.update(
                        epkPolysum,
                        fieldIndex + 2,
                        oldTimestampHash,
                        newTimestampHash,
                        EPK_R
                    );
                }
            }
        }

        // now handle the epoch tree polysum

        uint256 newLeaf = epkPolysum.hash;

        uint index;
        if (newKey) {
            // check that we're not at max capacity
            if (
                state.polysum.index ==
                uint(epochTreeArity)**uint(epochTreeDepth) - 2 + 1
            ) {
                revert MaxAttestations();
            }
            if (state.polysum.index == 0) {
                state.polysum.index = 1;
            }
            // this epoch key has received no attestations
            index = Polysum.add(state.polysum, newLeaf, OMT_R);
            state.epochKeyIndex[epochKey] = index;
            state.epochKeyLeaves[epochKey] = newLeaf;
        } else {
            index = state.epochKeyIndex[epochKey];
            // we need to update the value in the polysussssssss
            Polysum.update(
                state.polysum,
                index,
                state.epochKeyLeaves[epochKey],
                newLeaf,
                OMT_R
            );
            state.epochKeyLeaves[epochKey] = newLeaf;
        }
        emit EpochTreeLeaf(epoch, uint160(msg.sender), index, newLeaf);
        emit Attestation(
            epoch,
            epochKey,
            uint160(msg.sender),
            fieldIndex,
            change,
            block.timestamp
        );
    }

    function sealEpoch(
        uint256 epoch,
        uint160 attesterId,
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) public {
        if (!buildOrderedTreeVerifier.verifyProof(publicSignals, proof))
            revert InvalidProof();
        AttesterData storage attester = attesters[attesterId];
        AttesterState storage state = attester.state[epoch];
        updateEpochIfNeeded(attesterId);
        if (attester.currentEpoch <= epoch) revert EpochNotMatch();
        // build the epoch tree root
        uint256 root = publicSignals[0];
        uint256 polysum = publicSignals[1];
        //~~ if the hash is 0, don't allow the epoch to be manually sealed
        //~~ no attestations happened
        if (state.polysum.hash == 0) {
            revert NoAttestations();
        }
        //~~ we seal the polysum by adding the largest value possible to
        //~~ tree
        Polysum.add(state.polysum, SNARK_SCALAR_FIELD - 1, OMT_R);
        // otherwise the root was already set
        if (attester.epochTreeRoots[epoch] != 0) {
            revert DoubleSeal();
        }
        // otherwise it's bad data in the proof
        if (polysum != state.polysum.hash) {
            revert IncorrectHash();
        }
        attester.epochTreeRoots[epoch] = root;
        // emit an event sealing the epoch
        emit EpochSealed(epoch, attesterId);
    }

    /**
     * @dev Allow a user to epoch transition for an attester. Accepts a zk proof outputting the new gst leaf
     **/
    function userStateTransition(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) public {
        // Verify the proof
        if (!userStateTransitionVerifier.verifyProof(publicSignals, proof))
            revert InvalidProof();
        if (publicSignals[6] >= type(uint160).max) revert AttesterInvalid();
        uint160 attesterId = uint160(publicSignals[6]);
        updateEpochIfNeeded(attesterId);
        AttesterData storage attester = attesters[attesterId];
        // verify that the transition nullifier hasn't been used
        if (usedNullifiers[publicSignals[2]])
            revert NullifierAlreadyUsed(publicSignals[2]);
        usedNullifiers[publicSignals[2]] = true;

        // verify that we're transition to the current epoch
        if (attester.currentEpoch != publicSignals[5]) revert EpochNotMatch();

        uint256 fromEpoch = publicSignals[4];
        // check for attestation processing
        if (!attesterEpochSealed(attesterId, fromEpoch))
            revert EpochNotSealed();

        // make sure from state tree root is valid
        if (!attester.stateTreeRoots[fromEpoch][publicSignals[0]])
            revert InvalidStateTreeRoot(publicSignals[0]);

        // make sure from epoch tree root is valid
        if (attester.epochTreeRoots[fromEpoch] != publicSignals[3])
            revert InvalidEpochTreeRoot(publicSignals[3]);

        // update the current state tree
        emit StateTreeLeaf(
            attester.currentEpoch,
            attesterId,
            attester.stateTrees[attester.currentEpoch].numberOfLeaves,
            publicSignals[1]
        );
        emit UserStateTransitioned(
            attester.currentEpoch,
            attesterId,
            attester.stateTrees[attester.currentEpoch].numberOfLeaves,
            publicSignals[1],
            publicSignals[2]
        );
        IncrementalBinaryTree.insert(
            attester.stateTrees[attester.currentEpoch],
            publicSignals[1]
        );
        attester.stateTreeRoots[attester.currentEpoch][
            attester.stateTrees[attester.currentEpoch].root
        ] = true;
    }

    /**
     * @dev Update the currentEpoch for an attester, if needed
     * https://github.com/ethereum/solidity/issues/13813
     */
    function _updateEpochIfNeeded(uint256 attesterId)
        public
        returns (uint epoch)
    {
        require(attesterId < type(uint160).max);
        return updateEpochIfNeeded(uint160(attesterId));
    }

    function updateEpochIfNeeded(uint160 attesterId)
        public
        returns (uint epoch)
    {
        AttesterData storage attester = attesters[attesterId];
        epoch = attesterCurrentEpoch(attesterId);
        if (epoch == attester.currentEpoch) return epoch;

        // otherwise initialize the new epoch structures

        for (uint8 i; i < stateTreeDepth; i++) {
            attester.stateTrees[epoch].zeroes[i] = emptyTree.zeroes[i];
        }
        attester.stateTrees[epoch].root = emptyTree.root;
        attester.stateTrees[epoch].depth = stateTreeDepth;
        attester.stateTreeRoots[epoch][emptyTree.root] = true;

        emit EpochEnded(epoch - 1, attesterId);

        attester.currentEpoch = epoch;
    }

    function decodeEpochKeyControl(uint256 control)
        public
        pure
        returns (
            uint256 revealNonce,
            uint256 attesterId,
            uint256 epoch,
            uint256 nonce
        )
    {
        revealNonce = (control >> 232) & 1;
        attesterId = (control >> 72) & ((1 << 160) - 1);
        epoch = (control >> 8) & ((1 << 64) - 1);
        nonce = control & ((1 << 8) - 1);
        return (revealNonce, attesterId, epoch, nonce);
    }

    function decodeReputationControl(uint256 control)
        public
        pure
        returns (
            uint256 minRep,
            uint256 maxRep,
            uint256 proveMinRep,
            uint256 proveMaxRep,
            uint256 proveZeroRep,
            uint256 proveGraffiti
        )
    {
        minRep = control & ((1 << 64) - 1);
        maxRep = (control >> 64) & ((1 << 64) - 1);
        proveMinRep = (control >> 128) & 1;
        proveMaxRep = (control >> 129) & 1;
        proveZeroRep = (control >> 130) & 1;
        proveGraffiti = (control >> 131) & 1;
        return (
            minRep,
            maxRep,
            proveMinRep,
            proveMaxRep,
            proveZeroRep,
            proveGraffiti
        );
    }

    function decodeEpochKeySignals(uint256[] memory publicSignals)
        public
        pure
        returns (EpochKeySignals memory)
    {
        EpochKeySignals memory signals;
        signals.epochKey = publicSignals[0];
        signals.stateTreeRoot = publicSignals[1];
        signals.data = publicSignals[3];
        // now decode the control values
        (
            signals.revealNonce,
            signals.attesterId,
            signals.epoch,
            signals.nonce
        ) = decodeEpochKeyControl(publicSignals[2]);
        return signals;
    }

    function verifyEpochKeyProof(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) public {
        EpochKeySignals memory signals = decodeEpochKeySignals(publicSignals);
        bool valid = epochKeyVerifier.verifyProof(publicSignals, proof);
        // short circuit if the proof is invalid
        if (!valid) revert InvalidProof();
        if (signals.epochKey >= SNARK_SCALAR_FIELD) revert InvalidEpochKey();
        _updateEpochIfNeeded(signals.attesterId);
        AttesterData storage attester = attesters[uint160(signals.attesterId)];
        // epoch check
        if (signals.epoch > attester.currentEpoch)
            revert InvalidEpoch(signals.epoch);
        // state tree root check
        if (!attester.stateTreeRoots[signals.epoch][signals.stateTreeRoot])
            revert InvalidStateTreeRoot(signals.stateTreeRoot);
    }

    function decodeEpochKeyLiteSignals(uint256[] memory publicSignals)
        public
        pure
        returns (EpochKeySignals memory)
    {
        EpochKeySignals memory signals;
        signals.epochKey = publicSignals[1];
        signals.data = publicSignals[2];
        // now decode the control values
        (
            signals.revealNonce,
            signals.attesterId,
            signals.epoch,
            signals.nonce
        ) = decodeEpochKeyControl(publicSignals[0]);
        return signals;
    }

    function verifyEpochKeyLiteProof(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) public {
        EpochKeySignals memory signals = decodeEpochKeyLiteSignals(
            publicSignals
        );
        bool valid = epochKeyLiteVerifier.verifyProof(publicSignals, proof);
        // short circuit if the proof is invalid
        if (!valid) revert InvalidProof();
        if (signals.epochKey >= SNARK_SCALAR_FIELD) revert InvalidEpochKey();
        _updateEpochIfNeeded(signals.attesterId);
        AttesterData storage attester = attesters[uint160(signals.attesterId)];
        // epoch check
        if (signals.epoch > attester.currentEpoch)
            revert InvalidEpoch(signals.epoch);
    }

    function decodeReputationSignals(uint256[] memory publicSignals)
        public
        pure
        returns (ReputationSignals memory)
    {
        ReputationSignals memory signals;
        signals.epochKey = publicSignals[0];
        signals.stateTreeRoot = publicSignals[1];
        signals.graffitiPreImage = publicSignals[4];
        // now decode the control values
        (
            signals.revealNonce,
            signals.attesterId,
            signals.epoch,
            signals.nonce
        ) = decodeEpochKeyControl(publicSignals[2]);

        (
            signals.minRep,
            signals.maxRep,
            signals.proveMinRep,
            signals.proveMaxRep,
            signals.proveZeroRep,
            signals.proveGraffiti
        ) = decodeReputationControl(publicSignals[3]);
        return signals;
    }

    function verifyReputationProof(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) public {
        bool valid = reputationVerifier.verifyProof(publicSignals, proof);
        if (!valid) revert InvalidProof();
        ReputationSignals memory signals = decodeReputationSignals(
            publicSignals
        );
        if (signals.epochKey >= SNARK_SCALAR_FIELD) revert InvalidEpochKey();
        if (signals.attesterId >= type(uint160).max) revert AttesterInvalid();
        _updateEpochIfNeeded(signals.attesterId);
        AttesterData storage attester = attesters[uint160(signals.attesterId)];
        // epoch check
        if (signals.epoch > attester.currentEpoch)
            revert InvalidEpoch(signals.epoch);
        // state tree root check
        if (!attester.stateTreeRoots[signals.epoch][signals.stateTreeRoot])
            revert InvalidStateTreeRoot(signals.stateTreeRoot);
    }

    function attesterStartTimestamp(uint160 attesterId)
        public
        view
        returns (uint256)
    {
        AttesterData storage attester = attesters[attesterId];
        require(attester.startTimestamp != 0); // indicates the attester is signed up
        return attester.startTimestamp;
    }

    function attesterCurrentEpoch(uint160 attesterId)
        public
        view
        returns (uint256)
    {
        uint256 timestamp = attesters[attesterId].startTimestamp;
        uint256 epochLength = attesters[attesterId].epochLength;
        if (timestamp == 0) revert AttesterNotSignUp(attesterId);
        return (block.timestamp - timestamp) / epochLength;
    }

    function attesterEpochRemainingTime(uint160 attesterId)
        public
        view
        returns (uint256)
    {
        uint256 timestamp = attesters[attesterId].startTimestamp;
        uint256 epochLength = attesters[attesterId].epochLength;
        if (timestamp == 0) revert AttesterNotSignUp(attesterId);
        uint256 _currentEpoch = (block.timestamp - timestamp) / epochLength;
        return
            (timestamp + (_currentEpoch + 1) * epochLength) - block.timestamp;
    }

    function attesterEpochLength(uint160 attesterId)
        public
        view
        returns (uint256)
    {
        AttesterData storage attester = attesters[attesterId];
        return attester.epochLength;
    }

    function attesterEpochSealed(uint160 attesterId, uint256 epoch)
        public
        view
        returns (bool)
    {
        uint256 currentEpoch = attesterCurrentEpoch(attesterId);
        AttesterData storage attester = attesters[attesterId];
        if (currentEpoch <= epoch) return false;
        // either the attestations were processed, or no
        // attestations were received
        return
            attester.epochTreeRoots[epoch] != 0 ||
            attester.state[epoch].polysum.hash == 0;
    }

    function attesterStateTreeRootExists(
        uint160 attesterId,
        uint256 epoch,
        uint256 root
    ) public view returns (bool) {
        AttesterData storage attester = attesters[attesterId];
        return attester.stateTreeRoots[epoch][root];
    }

    function attesterStateTreeRoot(uint160 attesterId, uint256 epoch)
        public
        view
        returns (uint256)
    {
        AttesterData storage attester = attesters[attesterId];
        return attester.stateTrees[epoch].root;
    }

    function attesterStateTreeLeafCount(uint160 attesterId, uint256 epoch)
        public
        view
        returns (uint256)
    {
        AttesterData storage attester = attesters[attesterId];
        return attester.stateTrees[epoch].numberOfLeaves;
    }

    function attesterSemaphoreGroupRoot(uint160 attesterId)
        public
        view
        returns (uint256)
    {
        AttesterData storage attester = attesters[attesterId];
        return attester.semaphoreGroup.root;
    }

    function attesterMemberCount(uint160 attesterId)
        public
        view
        returns (uint256)
    {
        AttesterData storage attester = attesters[attesterId];
        return attester.semaphoreGroup.numberOfLeaves;
    }

    function attesterEpochRoot(uint160 attesterId, uint256 epoch)
        public
        view
        returns (uint256)
    {
        AttesterData storage attester = attesters[attesterId];
        return attester.epochTreeRoots[epoch];
    }
}


// File contracts/IGlobalAnonymousFeed.sol

pragma solidity ^0.8.0;


interface IGlobalAnonymousFeed {
    enum MessageType { Post, Comment }

    struct ReputationSignals {
        uint256 stateTreeRoot;
        uint256 epochKey;
        uint256 graffitiPreImage;
        uint256 proveGraffiti;
        uint256 nonce;
        uint256 epoch;
        uint256 attesterId;
        uint256 revealNonce;
        uint256 proveMinRep;
        uint256 proveMaxRep;
        uint256 proveZeroRep;
        uint256 minRep;
        uint256 maxRep;
    }

    struct MessageData {
        MessageType messageType;
        bytes32 hash;
        uint256 epochKey;
        uint256 epoch;
        uint256 personaId;
        bool isAdmin;
    }

    struct VoterData {
        uint256 epochKey;
        uint epoch;
    }

    struct VoteMeta {
        VoterData[] upvoters;
        VoterData[] downvoters;
    }

    struct Persona {
        uint256 personaId;
        string name;
        string profileImage;
        string coverImage;
        bytes32 pitch;
        bytes32 description;
    }
}


// File contracts/GlobalAnonymousFeed.sol

pragma abicoder v2;
pragma solidity ^0.8.4;


contract GlobalAnonymousFeed is IGlobalAnonymousFeed {
    error IdentityNotExist();

    error MemberAlreadyJoined();

    error GroupAlreadyExists();

    error GroupNotCreated();

    error MessageAlreadyExist();

    error MessageNotExist();

    address admin;

    uint160 public attesterId;

    // Positive Reputation field index in Kurate
    uint256 immutable public posRepFieldIndex = 0;

    // Nagative Reputation field index in Kurate
    uint256 immutable public negRepFieldIndex = 1;

    uint256 immutable public createPersonaRep = 10;
    uint256 immutable public postRep = 5;
    uint256 immutable public commentRep = 3;
    uint256 immutable public postReward = 5;
    uint256 immutable public commentReward = 3;
    uint256 immutable public voterReward = 1;

    Unirep public unirep;

    mapping(uint256 => Persona) public personas;
    uint256[] public personaList;

    mapping(uint256 => mapping(uint256 => bool)) public membersByPersona;
    mapping(uint256 => bool) public members;
    mapping(bytes32 => bool) public publishedMessage;

    mapping(uint256 => mapping(bytes32 => MessageData)) public proposedMessageByEpoch;
    mapping(uint256 => bytes32[]) public proposedMessageListByEpoch;
    mapping(bytes32 => VoteMeta) voteMetadataByMessageHash;

    event NewPersona(uint256 personaId);
    event NewPersonaMember(uint256 indexed personaId, uint256 identityCommitment);
    event NewProposedMessage(uint256 indexed personaId, bytes32 messageHash);
    event NewPersonaMessage(uint256 indexed personaId, bytes32 messageHash);

    /// Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(msg.sender == admin, "Restricted to admin.");
        _;
    }

    constructor(
        address _unirepAddress,
        uint256 epochLength
    ) {
        unirep = Unirep(_unirepAddress);
        unirep.attesterSignUp(epochLength); // 86400 (1d) for prod, suggest 120 (2m) for dev on ganache
        attesterId = uint160(address(this));
        admin = msg.sender;
    }

    function changeAdmin(address newAdminAddress) onlyAdmin external {
        admin = newAdminAddress;
    }

    function attesterCurrentEpoch() public view returns (uint256) {
        return unirep.attesterCurrentEpoch(attesterId);
    }

    function attesterEpochRemainingTime() public view returns (uint256) {
        return unirep.attesterEpochRemainingTime(attesterId);
    }

    function numOfPersonas() public view returns (uint256) {
        return personaList.length;
    }

    function sealEpoch(
        uint256 epoch,
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external {
        require(epoch < attesterCurrentEpoch(), 'epoch must be less than current epoch');

        bytes32[] memory messages = proposedMessageListByEpoch[epoch];

        for (uint256 i = 0; i < messages.length; i++) {
            MessageData memory msgData = proposedMessageByEpoch[epoch][messages[i]];
            VoteMeta memory voteMeta = voteMetadataByMessageHash[msgData.hash];

            uint256 totalVotes = voteMeta.downvoters.length + voteMeta.upvoters.length;
            bool isResultPositive = voteMeta.upvoters.length > voteMeta.downvoters.length;

            if (totalVotes >= 3 && isResultPositive) {
                publishedMessage[msgData.hash] = true;
                emit NewPersonaMessage(msgData.personaId, msgData.hash);
            }

            delete voteMetadataByMessageHash[msgData.hash];
            delete proposedMessageByEpoch[epoch][messages[i]];
        }

        delete proposedMessageListByEpoch[epoch];

        unirep.sealEpoch(epoch, attesterId, publicSignals, proof);
    }

    function userStateTransition(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external {
        unirep.userStateTransition(publicSignals, proof);
    }

    function grantReputation(
        uint256 rep,
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) onlyAdmin external {
        IUnirep.ReputationSignals memory signals = unirep.decodeReputationSignals(
            publicSignals
        );

        unirep.verifyReputationProof(publicSignals, proof);

        unirep.attest(
            signals.epochKey,
            signals.epoch,
            posRepFieldIndex,
            rep
        );
    }

    function slashReputation(
        uint256 rep,
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) onlyAdmin external {
        IUnirep.ReputationSignals memory signals = unirep.decodeReputationSignals(
            publicSignals
        );

        unirep.verifyReputationProof(publicSignals, proof);

        unirep.attest(
            signals.epochKey,
            signals.epoch,
            negRepFieldIndex,
            rep
        );
    }

    function createPersona(
        string memory name,
        string memory profileImage,
        string memory coverImage,
        bytes32 pitch,
        bytes32 description,
        bytes32[5] memory seedPosts,
        uint256[] memory publicSignals,
        uint256[8] memory proof,
        uint256[] memory signUpPublicSignals,
        uint256[8] memory signUpProof
    ) onlyAdmin external returns (uint256) {
        uint personaId = personaList.length;

        IUnirep.ReputationSignals memory signals = unirep.decodeReputationSignals(
            publicSignals
        );

        uint256 minRep = signals.minRep;
        require(minRep >= createPersonaRep, "not enough reputation");

        unirep.verifyReputationProof(publicSignals, proof);

        unirep.attest(
            signals.epochKey,
            signals.epoch,
            negRepFieldIndex,
            createPersonaRep
        );

        Persona storage persona = personas[personaId];

        persona.personaId = personaId;
        persona.name = name;
        persona.profileImage = profileImage;
        persona.coverImage = coverImage;
        persona.pitch = pitch;
        persona.description = description;

        personaList.push(personaId);

        emit NewPersona(personaId);

        for (uint256 i = 0; i < seedPosts.length; i++) {
            publishedMessage[seedPosts[i]] = true;
            emit NewPersonaMessage(personaId, seedPosts[i]);
        }

        uint256 identityCommitment = signUpPublicSignals[0];

        if (membersByPersona[personaId][identityCommitment] || members[identityCommitment]) {
            joinPersona(personaId, identityCommitment);
        } else {
            joinPersona(personaId, signUpPublicSignals, signUpProof);
        }

        return personaId;
    }

    function createPersona(
        string memory name,
        string memory profileImage,
        string memory coverImage,
        bytes32 pitch,
        bytes32 description,
        bytes32[5] memory seedPosts,
        uint256[] memory signUpPublicSignals,
        uint256[8] memory signUpProof
    ) onlyAdmin external returns (uint256) {
        uint personaId = personaList.length;

        Persona storage persona = personas[personaId];

        persona.personaId = personaId;
        persona.name = name;
        persona.profileImage = profileImage;
        persona.coverImage = coverImage;
        persona.pitch = pitch;
        persona.description = description;

        personaList.push(personaId);

        emit NewPersona(personaId);

        for (uint256 i = 0; i < seedPosts.length; i++) {
            publishedMessage[seedPosts[i]] = true;
            emit NewPersonaMessage(personaId, seedPosts[i]);
        }

        uint256 identityCommitment = signUpPublicSignals[0];

        if (membersByPersona[personaId][identityCommitment] || members[identityCommitment]) {
            joinPersona(personaId, identityCommitment);
        } else {
            joinPersona(personaId, signUpPublicSignals, signUpProof);
        }

        return personaId;
    }

    // @dev Required ZK Proof for first time joining a group.
    function joinPersona(
        uint256 personaId,
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) public {
        uint256 identityCommitment = publicSignals[0];

        if (membersByPersona[personaId][identityCommitment] || members[identityCommitment]) {
            revert MemberAlreadyJoined();
        }

        unirep.userSignUp(publicSignals, proof);

        members[identityCommitment] = true;
        membersByPersona[personaId][identityCommitment] = true;

        emit NewPersonaMember(personaId, identityCommitment);
    }

    // @dev use this method if the user already joined a persona before
    function joinPersona(
        uint256 personaId,
        uint256 identityCommitment
    ) public {
        require(members[identityCommitment], 'member must join unirep first');

        if (membersByPersona[personaId][identityCommitment]) {
            revert MemberAlreadyJoined();
        }

        membersByPersona[personaId][identityCommitment] = true;

        emit NewPersonaMember(personaId, identityCommitment);
    }

    function proposeMessage(
        uint256 personaId,
        MessageType messageType,
        bytes32 messageHash,
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) onlyAdmin external payable {
        IUnirep.ReputationSignals memory signals = unirep.decodeReputationSignals(
            publicSignals
        );

        uint256 epoch = signals.epoch;

        require(epoch == attesterCurrentEpoch(), 'epoch does not match');

        if (proposedMessageByEpoch[epoch][messageHash].hash != bytes32(0)) {
            revert MessageAlreadyExist();
        }

        if (publishedMessage[messageHash]) {
            revert MessageAlreadyExist();
        }


        uint256 minRep = signals.minRep;

        if (messageType == MessageType.Post) {
            require(minRep >= postRep, "not enough reputation");
        } else if (messageType == MessageType.Comment) {
            require(minRep >= commentRep, "not enough reputation");
        }

        unirep.verifyReputationProof(publicSignals, proof);

        proposedMessageByEpoch[epoch][messageHash] = MessageData(
            messageType,
            messageHash,
            signals.epochKey,
            signals.epoch,
            personaId,
            false
        );

        proposedMessageListByEpoch[epoch].push(messageHash);

        emit NewProposedMessage(personaId, messageHash);
    }

    function proposeMessage(
        uint256 personaId,
        MessageType messageType,
        bytes32 messageHash
    ) onlyAdmin external payable {
        uint256 epoch = attesterCurrentEpoch();

        if (proposedMessageByEpoch[epoch][messageHash].hash != bytes32(0)) {
            revert MessageAlreadyExist();
        }

        if (publishedMessage[messageHash]) {
            revert MessageAlreadyExist();
        }

        proposedMessageByEpoch[epoch][messageHash] = MessageData(
            messageType,
            messageHash,
            0,
            epoch,
            personaId,
            true
        );

        proposedMessageListByEpoch[epoch].push(messageHash);

        emit NewProposedMessage(personaId, messageHash);
    }

    function vote(
        bytes32 messageHash,
        bool isUpvote,
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) onlyAdmin external  {
        IUnirep.ReputationSignals memory signals = unirep.decodeReputationSignals(
            publicSignals
        );

        uint256 epoch = signals.epoch;

        require(epoch == attesterCurrentEpoch(), 'epoch does not match current epoch');

        MessageData memory msgData = proposedMessageByEpoch[epoch][messageHash];

        require(epoch == msgData.epoch, 'epoch does not match message epoch');

        if (msgData.hash == bytes32(0)) {
            revert MessageNotExist();
        }

        unirep.verifyReputationProof(publicSignals, proof);

        VoteMeta storage voteMeta = voteMetadataByMessageHash[messageHash];

        uint256 total = voteMeta.upvoters.length + voteMeta.downvoters.length;

        uint256 newTotal = total + 1;
        uint256 newUpvotes = isUpvote ? voteMeta.upvoters.length + 1 : voteMeta.upvoters.length;
        uint256 newDownvotes = !isUpvote ? voteMeta.downvoters.length + 1 : voteMeta.downvoters.length;

        uint256 reward = msgData.messageType == MessageType.Post ? postReward : commentReward;
        uint256 stake = msgData.messageType == MessageType.Post ? postRep : commentRep;

        // Reward/Slash OP
        if (!msgData.isAdmin) {
            if (newTotal == 3) {
                // if new result is positive - reward rep
                if (newUpvotes > newDownvotes) {
                    unirep.attest(
                        msgData.epochKey,
                        msgData.epoch,
                        posRepFieldIndex,
                        reward
                    );
                // if new result is positive - slash stake
                } else if (newDownvotes > newUpvotes) {
                    unirep.attest(
                        msgData.epochKey,
                        msgData.epoch,
                        negRepFieldIndex,
                        stake
                    );
                }
            } else if (newTotal > 3) {
                // if flip from neutral...
                if (voteMeta.upvoters.length == voteMeta.downvoters.length) {
                    // ...to positive - reward
                    if (newUpvotes > newDownvotes) {
                        unirep.attest(
                            msgData.epochKey,
                            msgData.epoch,
                            posRepFieldIndex,
                            reward
                        );
                    // ...to negative - slash
                    } else if (newDownvotes > newUpvotes) {
                        unirep.attest(
                            msgData.epochKey,
                            msgData.epoch,
                            negRepFieldIndex,
                            stake
                        );
                    }
                }

                // if flip to neutral...
                if (newUpvotes == newDownvotes) {
                    // ...from positive - take back previous rep
                    if (voteMeta.upvoters.length > voteMeta.downvoters.length) {
                        unirep.attest(
                            msgData.epochKey,
                            msgData.epoch,
                            negRepFieldIndex,
                            reward
                        );
                    // ...from negative - give abck previous slash
                    } else if (voteMeta.upvoters.length < voteMeta.downvoters.length) {
                        unirep.attest(
                            msgData.epochKey,
                            msgData.epoch,
                            posRepFieldIndex,
                            stake
                        );
                    }
                }
            }
        }

        // Reward/Slash old voters
        if (newTotal == 3) {
            // if result is positive, reward upvoters
            if (newUpvotes > newDownvotes) {
                attestVoters(voteMeta.upvoters, posRepFieldIndex, voterReward);
            // if result is negative, reward downvoters
            } else if (newUpvotes < newDownvotes) {
                attestVoters(voteMeta.downvoters, posRepFieldIndex, voterReward);
            }
        } else if (newTotal > 3) {
            // if flip from neutral...
            if (voteMeta.upvoters.length == voteMeta.downvoters.length) {
                // ...to positive - reward upvoters
                if (newUpvotes > newDownvotes) {
                    attestVoters(voteMeta.upvoters, posRepFieldIndex, voterReward);
                    // ...to negative - reward downvoters
                } else if (newDownvotes > newUpvotes) {
                    attestVoters(voteMeta.downvoters, posRepFieldIndex, voterReward);
                }
            }

            // if flip to neutral...
            if (newUpvotes == newDownvotes) {
                // ...from positive - take back previous rep from upvoters
                if (voteMeta.upvoters.length > voteMeta.downvoters.length) {
                    attestVoters(voteMeta.upvoters, negRepFieldIndex, voterReward);
                    // ...from negative - take back previous rep from downvoters
                } else if (voteMeta.upvoters.length < voteMeta.downvoters.length) {
                    attestVoters(voteMeta.downvoters, negRepFieldIndex, voterReward);
                }
            }
        }

        if (newTotal >= 3) {
            // vote with majority
            if ((newUpvotes > newDownvotes && isUpvote) || (newUpvotes < newDownvotes && !isUpvote)) {
                unirep.attest(
                    signals.epochKey,
                    signals.epoch,
                    posRepFieldIndex,
                    voterReward
                );
            }
        }

        if (isUpvote) {
            voteMeta.upvoters.push(VoterData(signals.epochKey, signals.epoch));
        } else {
            voteMeta.downvoters.push(VoterData(signals.epochKey, signals.epoch));
        }
    }

    function attestVoters(
        VoterData[] memory voters,
        uint256 fieldIndex,
        uint256 change
    ) internal {
        for (uint256 i = 0; i < voters.length; i++) {
            VoterData memory voter = voters[i];
            unirep.attest(
                voter.epochKey,
                voter.epoch,
                fieldIndex,
                change
            );
        }
    }
}