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

    error NotAuthorized(address caller, bytes32 role);

    modifier hasRole(bytes32 role) {
        if (!roles.hasRole(msg.sender, role)) {
            revert NotAuthorized(msg.sender, role);
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "../access/Roles.sol";
import "../interfaces/Types.sol";
import "./interfaces/IEditPosition.sol";
import "./interfaces/IPosition.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IFunding.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IRiskManager.sol";
import "../utils/interfaces/IChainlink.sol";
import "../utils/VerifyEditPosition.sol";
import "../utils/ArbitrumGasInfo.sol";
import "./interfaces/IOpenPosition.sol";
import "./interfaces/IProfitShare.sol";

contract EditPosition is Roles, ERC2771Context, IEditPosition {
    string private constant EIP712_DOMAIN_TYPE =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    bytes32 private constant ORACLE = keccak256("ORACLE");
    bytes32 private constant GOV = keccak256("GOV");
    ArbGasInfo private constant arb =
        ArbGasInfo(0x000000000000000000000000000000000000006C);
    bytes32 private DOMAIN_HASH;
    IFunding immutable funding;
    IPool immutable pool;
    IChainlink immutable chainlink;
    IPosition immutable positionStorage;
    IPair immutable pairs;
    IRiskManager immutable risks;
    IOpenPosition immutable openPosition;
    IProfitShare immutable profitShare;

    mapping(address => uint256) public nonces; //For gasless

    uint256 private constant BPS = 1e6; //Base Percent
    uint256 public minSize = 1e9; //1000 USDC
    uint256 public basePrice = 2e9; //2000 USDC

    constructor(
        IRoleManager _roles,
        IChainlink _chainlink,
        IPosition _position,
        IFunding _funding,
        IPool _pool,
        IPair _pairs,
        IRiskManager _risks,
        IOpenPosition _openPosition,
        IProfitShare _profitShare,
        address _trustedForwarder
    ) Roles(_roles) ERC2771Context(_trustedForwarder) {
        funding = _funding;
        chainlink = _chainlink;
        positionStorage = _position;
        pool = _pool;
        pairs = _pairs;
        risks = _risks;
        profitShare = _profitShare;
        openPosition = _openPosition;
        _setDomain();
    }

    fallback() external {}

    function editParams(
        uint256 _basePrice,
        uint256 _minSize
    ) external hasRole(GOV) {
        minSize = _minSize;
        basePrice = _basePrice;
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

    function executeEditCopy(
        bytes32[] calldata copyIds
    ) external virtual override hasRole(ORACLE) {
        uint length = copyIds.length;
        uint256 oracleFee = _getFeeExecution(200000, length);
        for (uint256 i; i < length; ) {
            (bool success, bytes memory ret) = address(this).call(
                abi.encodeWithSelector(
                    EditPosition.editCopyPosition.selector,
                    copyIds[i],
                    oracleFee
                )
            );
            if (!success) {
                emit EditFailed(copyIds[i], ret);
            }
            unchecked {
                ++i;
            }
        }
    }

    function editCopyPosition(bytes32 copyId, uint256 oracleFee) external {
        require(msg.sender == address(this), "!only-this");
        Types.Position memory position = positionStorage.getPosition(copyId);
        IPair.Pair memory pair = pairs.get(position.pairId);
        uint256 price = _getMarkPrice(
            chainlink.getPrice(position.pairId),
            position.isLong,
            pair.spread
        );
        (
            address user,
            address master,
            int256 amount,
            int256 sizeChange
        ) = positionStorage.updatePositionWithMaster(copyId, int256(price));
        require(user != address(0x0) && amount != 0, "!wrong-copy");
        amount += int256(oracleFee);

        int256 fees;
        if (sizeChange == 0) {
            pool.creditFee(copyId, 0, 0, oracleFee);
        } else {
            if (sizeChange < 0) {
                revert("!updated-position");
            } else {
                fees = (sizeChange * int32(pair.openFee)) / int256(BPS ** 2);
                pool.creditFee(copyId, 1, uint256(fees), oracleFee);
            }
        }
        amount += fees;
        openPosition.changeCopyAmount(amount, master, user);
        if (amount > 0) {
            pool.transferIn(user, uint256(amount));
        }
        if (amount < 0) {
            pool.transferOut(user, uint256(-1 * amount));
        }
    }

    function addCollateral(bytes32 id, uint256 amount) external override {
        _addCollateral(id, amount, _msgSender());
    }

    function addCollateralGasLess(
        bytes32 id,
        uint256 amount,
        Types.GasLess calldata gasLess
    ) external override {
        Verify._verifyAddCollateral(
            DOMAIN_HASH,
            nonces[gasLess.owner],
            id,
            amount,
            gasLess
        );
        ++nonces[gasLess.owner];
        uint256 oracleFee = _getFeeExecution(150000, 1);
        require(amount > oracleFee, "!fee-not-enough");
        _addCollateral(id, amount - oracleFee, gasLess.owner);
        pool.creditFee(id, 0, 0, oracleFee);
    }

    function _addCollateral(bytes32 id, uint256 amount, address user) internal {
        Types.Position memory position = positionStorage.getPosition(id);
        require(user == position.owner, "!owner");
        require(position.amount > 0, "!exists");
        require(amount > 0, "!amount");
        IPair.Pair memory pair = pairs.get(position.pairId);
        position.leverage = uint32(
            (position.leverage * position.amount) / (position.amount + amount)
        );
        require(position.leverage >= pair.minLeverage, "!min-leverage");
        position.amount += amount;
        positionStorage.updatePosition(id, position);
        pool.transferIn(user, amount);
        emit PositionChanged(id);
    }

    function removeCollateral(bytes32 id, uint256 amount) external override {
        _removeCollateral(id, amount, _msgSender(), 0);
    }

    function removeCollateralGasLess(
        bytes32 id,
        uint256 amount,
        Types.GasLess calldata gasLess
    ) external override {
        Verify._verifyRemoveCollateral(
            DOMAIN_HASH,
            nonces[gasLess.owner],
            id,
            amount,
            gasLess
        );
        ++nonces[gasLess.owner];
        uint256 oracleFee = _getFeeExecution(150000, 1);
        require(amount > oracleFee, "!fee-not-enough");
        _removeCollateral(id, amount - oracleFee, gasLess.owner, oracleFee);
    }

    function _removeCollateral(
        bytes32 id,
        uint256 amount,
        address user,
        uint256 oracleFee
    ) internal {
        Types.Position memory position = positionStorage.getPosition(id);
        require(user == position.owner, "!owner");
        require(position.amount > 0, "!exists");
        require(amount > 0, "!amount");
        uint256 remainingCollateral = position.amount - amount;
        uint256 chainlinkPrice = chainlink.getPrice(position.pairId);
        uint256 positionSize = (position.amount * position.leverage) / BPS;
        (int256 pnl, ) = getPnL(
            position.pairId,
            position.isLong,
            chainlinkPrice,
            position.entryPrice,
            positionSize,
            position.fundingTracker
        );
        IPair.Pair memory pair = pairs.get(position.pairId);
        if (pnl < 0) {
            uint256 absPnl = uint256(-1 * pnl);
            require(
                absPnl <
                    ((remainingCollateral * (BPS - pair.liqThreshold)) / BPS),
                "!pnl"
            );
        }
        position.leverage = uint32(
            (position.leverage * position.amount) / remainingCollateral
        );
        require(position.leverage <= pair.maxLeverage, "!max-leverage");

        position.amount -= amount;
        require(
            (position.leverage * position.amount) / BPS >= minSize,
            "!min-size"
        );
        positionStorage.updatePosition(id, position);
        if (oracleFee > 0) {
            pool.creditFee(id, 0, 0, oracleFee);
        }
        pool.transferOut(user, amount - oracleFee);
        emit PositionChanged(id);
    }

    function incPosition(bytes32 id, uint256 amount) external override {
        _incPosition(id, amount, _msgSender(), 0);
    }

    function incPositionGasLess(
        bytes32 id,
        uint256 amount,
        Types.GasLess calldata gasLess
    ) external override {
        Verify._verifyIncPosition(
            DOMAIN_HASH,
            nonces[gasLess.owner],
            id,
            amount,
            gasLess
        );
        ++nonces[gasLess.owner];
        uint256 oracleFee = _getFeeExecution(200000, 1);
        require(amount > oracleFee, "!fee-not-enough");
        _incPosition(id, amount, gasLess.owner, oracleFee);
    }

    function decPosition(bytes32 id, uint256 amount) external override {
        _decPosition(id, amount, _msgSender(), 0);
    }

    function decPositionGasLess(
        bytes32 id,
        uint256 amount,
        Types.GasLess calldata gasLess
    ) external override {
        Verify._verifyDecPosition(
            DOMAIN_HASH,
            nonces[gasLess.owner],
            id,
            amount,
            gasLess
        );
        ++nonces[gasLess.owner];
        uint256 oracleFee = _getFeeExecution(200000, 1);
        require(amount > oracleFee, "!fee-not-enough");
        _decPosition(id, amount, gasLess.owner, oracleFee);
    }

    function _incPosition(
        bytes32 id,
        uint256 amount,
        address user,
        uint256 oracleFee
    ) internal {
        Types.Position memory position = positionStorage.getPosition(id);
        require(user == position.owner, "!owner");
        require(position.amount > 0, "!exists");
        IPair.Pair memory pair = pairs.get(position.pairId);
        funding.updateFunding(position.pairId);
        int256 currentFundingTracker = funding.getFundingTracker(
            position.pairId
        );
        int256 fundingFee = ((position.isLong ? int256(-1) : int256(1)) *
            (int256(position.amount) *
                int256(uint256(uint32(position.leverage))) *
                (currentFundingTracker - position.fundingTracker))) /
            int256(BPS ** 2);
        require(amount > oracleFee, "!fee-not-enough");
        uint256 openFee = ((amount - oracleFee) *
            uint256(position.leverage) *
            uint256(pair.openFee)) /
            (BPS ** 2 + uint256(position.leverage) * uint256(pair.openFee));
        require(amount > openFee + oracleFee, "!fee-not-enough");
        uint256 incAmount = amount - openFee - oracleFee;
        uint256 currentPrice = _getMarkPrice(
            chainlink.getPrice(position.pairId),
            position.isLong,
            pair.spread
        );
        require(
            risks.checkRisk(
                Types.Position(
                    position.owner,
                    position.isLong,
                    position.pairId,
                    position.leverage,
                    uint32(block.timestamp),
                    currentPrice,
                    incAmount,
                    currentFundingTracker
                ),
                0
            ),
            "!risk"
        );
        uint256 avgPrice = (position.amount *
            position.entryPrice +
            incAmount *
            currentPrice) / (position.amount + incAmount);
        position.fundingTracker = currentFundingTracker;
        position.entryPrice = avgPrice;
        position.amount = position.amount + incAmount;
        if (fundingFee < 0) {
            require(
                position.amount > uint256(-1 * fundingFee),
                "!funding-crash"
            );
            position.amount -= uint256(-1 * fundingFee);
        } else {
            position.amount += uint256(fundingFee);
        }
        pool.creditFee(id, 1, openFee, uint256(oracleFee));
        positionStorage.updatePosition(id, position);
        pool.transferIn(user, amount);
        emit PositionChanged(id);
    }

    function _decPosition(
        bytes32 id,
        uint256 amount,
        address user,
        uint256 oracleFee
    ) internal {
        Types.Position memory position = positionStorage.getPosition(id);
        require(
            risks.checkRisk(
                Types.Position(
                    position.owner,
                    position.isLong,
                    position.pairId,
                    position.leverage,
                    uint32(block.timestamp),
                    position.entryPrice,
                    amount,
                    position.fundingTracker
                ),
                chainlink.getPrice(position.pairId)
            ),
            "!risk"
        );
        require(user == position.owner, "!owner");
        require(position.amount > 0, "!exists");
        IPair.Pair memory pair = pairs.get(position.pairId);
        funding.updateFunding(position.pairId);
        require(position.amount > amount, "!amount-dec");
        require(block.timestamp - position.timestamp > pair.minAge, "!min-age");
        uint256 feeClose = (amount * position.leverage * pair.closeFee) /
            (BPS ** 2);
        (int256 pnl, ) = getPnL(
            position.pairId,
            position.isLong,
            chainlink.getPrice(position.pairId),
            position.entryPrice,
            (amount * position.leverage) / BPS,
            position.fundingTracker
        );
        int256 finalAmount = int256(amount) +
            pnl -
            int256(feeClose) -
            int256(oracleFee);
        require(finalAmount > 0, "!dec-zero");
        (address masterAddress, int256 amountShare) = positionStorage
            .closePosition(
                id,
                chainlink.getPrice(position.pairId),
                pnl,
                finalAmount,
                5
            );
        if (masterAddress != address(0x0)) {
            openPosition.changeCopyAmount(
                -finalAmount,
                masterAddress,
                position.owner
            );
            amountShare = profitShare.recordShare(
                masterAddress,
                position.owner,
                amountShare,
                id
            );
        }
        pool.settlePosition(
            position.owner,
            uint256(finalAmount - amountShare),
            pnl
        );
        pool.creditFee(id, 2, feeClose, uint256(oracleFee));
        position.amount = position.amount - amount;
        require(
            (position.leverage * position.amount) / BPS >= minSize,
            "!min-size"
        );
        positionStorage.updatePosition(id, position);
        emit PositionChanged(id);
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

    function _getMarkPrice(
        uint256 price,
        bool isLong,
        uint256 spread
    ) internal pure returns (uint256) {
        if (isLong) {
            return (price * (BPS + spread)) / BPS;
        } else {
            return (price * (BPS - spread)) / BPS;
        }
    }

    function _getFeeExecution(
        uint256 _gasUsedL2,
        uint256 _l1Shared
    ) internal view returns (uint256) {
        return
            (((_gasUsedL2 * tx.gasprice) +
                (arb.getCurrentTxL1GasFees() / _l1Shared)) * basePrice) / 1e18;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/Types.sol";

interface IEditPosition {
    event EditFailed(bytes32 id, bytes reason);
    event PositionChanged(bytes32 id);

    function executeEditCopy(bytes32[] calldata copyIds) external;

    function addCollateral(bytes32 id, uint256 amount) external;

    function addCollateralGasLess(
        bytes32 id,
        uint256 amount,
        Types.GasLess calldata gasLess
    ) external;

    function incPosition(bytes32 id, uint256 amount) external;

    function incPositionGasLess(
        bytes32 id,
        uint256 amount,
        Types.GasLess calldata gasLess
    ) external;

    function removeCollateral(bytes32 id, uint256 amount) external;

    function removeCollateralGasLess(
        bytes32 id,
        uint256 amount,
        Types.GasLess calldata gasLess
    ) external;

    function decPosition(bytes32 id, uint256 amount) external;

    function decPositionGasLess(
        bytes32 id,
        uint256 amount,
        Types.GasLess calldata gasLess
    ) external;
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

    function getFundings(
        uint16[] calldata pairId
    ) external view returns (Funding[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/Types.sol";

interface IOpenPosition {
    event CancelSignature(bytes signature, address owner);
    event CopyFailed(bytes32 id, address copier, bytes reason);
    event PermitFailed(address owner, bytes reason);

    struct CopyRequest {
        address owner;
        address master;
        uint256 maxAmount;
        uint256 fixedAmount;
        uint32 percentAmount;
        uint32 sharePercent;
        uint32 percentTp;
        uint32 percentSl;
        bytes signature;
    }

    function openPosition(
        Types.Order calldata order
    ) external returns (bytes32);

    function openPositionGasLess(
        Types.Order calldata order,
        Types.GasLess calldata gasLess
    ) external returns (bytes32);

    function openLimitPosition(
        Types.OrderLimit calldata order
    ) external returns (bytes32);

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

    function executeCopy(
        bytes32 id,
        CopyRequest[] calldata copyRequest,
        Types.Permit[] calldata permits
    ) external;

    function updateLimit(bytes32 id, uint256 tp, uint256 sl) external;

    function updateLimitGasLess(
        bytes32 id,
        uint256 tp,
        uint256 sl,
        Types.GasLess calldata gasLess
    ) external;

    function cancel(bytes calldata sign) external;

    function cancelGasLess(
        bytes calldata id,
        Types.GasLess calldata gasLess
    ) external;

    function changeCopyAmount(
        int256 amount,
        address master,
        address copier
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPair {
    event PairUpdated(
        uint16 pairId,
        address chainlinkFeed,
        bool isClosed,
        bool allowSelfExecution,
        uint32 maxLeverage,
        uint32 minLeverage,
        uint32 openFee,
        uint32 closeFee,
        uint32 spread,
        uint32 minAge,
        uint256 maxDeviation,
        uint256 liqThreshold
    );

    struct Pair {
        address chainlinkFeed;
        bool isClosed;
        bool allowSelfExecution;
        uint32 maxLeverage;
        uint32 minLeverage;
        uint32 openFee;
        uint32 closeFee;
        uint32 spread;
        uint32 minAge;
        uint256 maxDeviation;
        uint256 liqThreshold;
    }

    function set(uint16 pairId, Pair memory pairInfo) external;

    function setStatus(
        uint16[] calldata pairIds,
        bool[] calldata isClosed
    ) external;

    function get(uint16 pairId) external view returns (Pair memory);

    function getOpenFee(uint16 pairId) external view returns (uint32);

    function getCloseFee(uint16 pairId) external view returns (uint32);

    function getMany(
        uint16[] calldata pairIds
    ) external view returns (Pair[] memory);

    function getChainlinkFeed(uint16 pairId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/Types.sol";

interface IPool {
    event Deposit(address owner, uint256 amount, uint256 amountLp);
    event Withdraw(address owner, uint256 amount, uint256 amountLp);
    event ProtocolWithdraw(address wallet, uint256 amount);
    event OracleWithdraw(address wallet, uint256 amount);
    event FeePaid(bytes32 id, uint8 feeType, uint256 fee, uint256 oracle);

    function changeWithdrawFee(uint256 amount) external;

    function changeLiquidityShare(uint256 percent) external;

    function deposit(uint256 amount) external returns (uint256);

    function depositGasLess(
        uint256 amount,
        Types.GasLess calldata gasLess
    ) external returns (uint256);

    function depositWithPermit(
        uint256 amount,
        Types.Permit calldata permit
    ) external returns (uint256);

    function depositGasLessWithPermit(
        uint256 amount,
        Types.GasLess calldata gasLess,
        Types.Permit calldata permit
    ) external returns (uint256);

    function withdraw(uint256 amountLp) external returns (uint256);

    function withdrawGasLess(
        uint256 amountLp,
        Types.GasLess calldata gasLess
    ) external returns (uint256);

    function creditFee(
        bytes32 id,
        uint8 feeType,
        uint256 fee,
        uint256 oracle
    ) external;

    function transferIn(address from, uint256 amount) external;

    function transferOut(address to, uint256 amount) external;

    function settlePosition(address user, uint256 amount, int256 pnl) external;

    function protocolWithdraw(uint256 amount, address wallet) external;

    function oracleWithdraw(uint256 amount, address wallet) external;

    function getPoolBalance() external view returns (uint256);
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
        uint32 leverage,
        uint32 timestamp,
        uint256 entryPrice,
        uint256 amount,
        int256 fundingTracker,
        bytes32 masterId
    );

    event ClosePosition(
        bytes32 id,
        uint256 closePrice,
        int256 pnl,
        uint16 closeType
    );

    event UpdateTP(bytes32 id, uint256 tp);

    event UpdateSL(bytes32 id, uint256 sl);

    struct Master {
        address owner;
        bytes32 masterId;
        uint256 sharePercent;
    }

    struct OI {
        uint256 long;
        uint256 short;
    }

    //SET
    function addPosition(Types.Position calldata) external returns (bytes32);

    function addPositionWithMaster(
        Types.Position calldata position,
        Master calldata master,
        uint256 percentTp,
        uint256 percentSl
    ) external returns (bytes32);

    function updatePositionWithMaster(
        bytes32 id,
        int256 price
    )
        external
        returns (
            address user,
            address master,
            int256 amount,
            int256 sizeChange
        );

    function updatePosition(
        bytes32 id,
        Types.Position calldata position
    ) external;

    function closePosition(
        bytes32 id,
        uint256 closePrice,
        int256 pnl,
        int256 finalAmount,
        uint16 closeType
    ) external returns (address masterAddress, int256 amountShare);

    function setTp(bytes32 id, uint256 tp) external;

    function setSl(bytes32 id, uint256 sl) external;

    //GET
    function TP(bytes32 id) external view returns (uint256);

    function SL(bytes32 id) external view returns (uint256);

    function getPositionPairId(bytes32 id) external view returns (uint16);

    function getPosition(
        bytes32 id
    ) external view returns (Types.Position memory);

    function getMasterInfo(bytes32 id) external view returns (Master memory);

    function getPositions(
        bytes32[] calldata id
    ) external view returns (Types.Position[] memory _positions);

    function getTP(bytes32 id) external view returns (uint256);

    function getSL(bytes32 id) external view returns (uint256);

    function getIOs(uint16 pairId) external view returns (OI memory);

    function getIO(uint16 pairId) external view returns (uint256);

    function getIOLong(uint16 pairId) external view returns (uint256);

    function getIOShort(uint16 pairId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../../interfaces/Types.sol";

interface IProfitShare {
    event NewShare(
        address master,
        address copier,
        uint256 epoch,
        int256 currentProfit,
        int256 totalMasterShare,
        int256 change,
        bytes32 id
    );

    event NewEpochTime(
        uint256 newEpochTime,
        uint256 startTime,
        uint256 currentEpoch
    );

    event MasterWithdraw(address master, uint256 total, uint256[] epoch);

    function recordShare(
        address master,
        address copier,
        int256 amount,
        bytes32 id
    ) external returns (int256 change);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../../interfaces/Types.sol";

interface IRiskManager {
    struct MarketInfo {
        uint256 tLong;
        uint256 tShort;
    }

    function checkRisk(
        Types.Position calldata position,
        uint256 closePrice
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Types {
    struct Order {
        bool isLong;
        uint16 pairId;
        uint32 leverage;
        uint256 amount;
        uint256 tp;
        uint256 sl;
    }

    struct OrderLimit {
        address owner;
        bool isLong;
        uint8 orderType;
        uint16 pairId;
        uint32 leverage;
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
        uint32 leverage;
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

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/// @title Provides insight into the cost of using the chain.
/// @notice These methods have been adjusted to account for Nitro's heavy use of calldata compression.
/// Of note to end-users, we no longer make a distinction between non-zero and zero-valued calldata bytes.
/// Precompiled contract that exists in every Arbitrum chain at 0x000000000000000000000000000000000000006c.
interface ArbGasInfo {
    /// @notice Get gas prices for a provided aggregator
    /// @return return gas prices in wei
    ///        (
    ///            per L2 tx,
    ///            per L1 calldata byte
    ///            per storage allocation,
    ///            per ArbGas base,
    ///            per ArbGas congestion,
    ///            per ArbGas total
    ///        )
    function getPricesInWeiWithAggregator(
        address aggregator
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256);

    /// @notice Get gas prices. Uses the caller's preferred aggregator, or the default if the caller doesn't have a preferred one.
    /// @return return gas prices in wei
    ///        (
    ///            per L2 tx,
    ///            per L1 calldata byte
    ///            per storage allocation,
    ///            per ArbGas base,
    ///            per ArbGas congestion,
    ///            per ArbGas total
    ///        )
    function getPricesInWei()
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256);

    /// @notice Get prices in ArbGas for the supplied aggregator
    /// @return (per L2 tx, per L1 calldata byte, per storage allocation)
    function getPricesInArbGasWithAggregator(
        address aggregator
    ) external view returns (uint256, uint256, uint256);

    /// @notice Get prices in ArbGas. Assumes the callers preferred validator, or the default if caller doesn't have a preferred one.
    /// @return (per L2 tx, per L1 calldata byte, per storage allocation)
    function getPricesInArbGas()
        external
        view
        returns (uint256, uint256, uint256);

    /// @notice Get the gas accounting parameters. `gasPoolMax` is always zero, as the exponential pricing model has no such notion.
    /// @return (speedLimitPerSecond, gasPoolMax, maxTxGasLimit)
    function getGasAccountingParams()
        external
        view
        returns (uint256, uint256, uint256);

    /// @notice Get the minimum gas price needed for a tx to succeed
    function getMinimumGasPrice() external view returns (uint256);

    /// @notice Get ArbOS's estimate of the L1 basefee in wei
    function getL1BaseFeeEstimate() external view returns (uint256);

    /// @notice Get how slowly ArbOS updates its estimate of the L1 basefee
    function getL1BaseFeeEstimateInertia() external view returns (uint64);

    /// @notice Deprecated -- Same as getL1BaseFeeEstimate()
    function getL1GasPriceEstimate() external view returns (uint256);

    /// @notice Get L1 gas fees paid by the current transaction
    function getCurrentTxL1GasFees() external view returns (uint256);

    /// @notice Get the backlogged amount of gas burnt in excess of the speed limit
    function getGasBacklog() external view returns (uint64);

    /// @notice Get how slowly ArbOS updates the L2 basefee in response to backlogged gas
    function getPricingInertia() external view returns (uint64);

    /// @notice Get the forgivable amount of backlogged gas ArbOS will ignore when raising the basefee
    function getGasBacklogTolerance() external view returns (uint64);

    /// @notice Returns the surplus of funds for L1 batch posting payments (may be negative).
    function getL1PricingSurplus() external view returns (int256);

    /// @notice Returns the base charge (in L1 gas) attributed to each data batch in the calldata pricer
    function getPerBatchGasCharge() external view returns (int64);

    /// @notice Returns the cost amortization cap in basis points
    function getAmortizedCostCapBips() external view returns (uint64);

    /// @notice Returns the available funds from L1 fees
    function getL1FeesAvailable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChainlink {
    function getPrice(uint16 pairId) external view returns (uint256);

    function boundPrice(
        uint16 pairId,
        uint256 price
    ) external view returns (bool, uint256);

    function boundPriceWithChainlink(
        uint16 pairId,
        uint256 price
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "../interfaces/Types.sol";
import "../core/interfaces/IEditPosition.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Verify {
    using ECDSA for bytes32;

    bytes32 private constant ADD_COLLATERAL_HASH =
        keccak256(
            bytes(
                "AddCollateral(address owner,bytes32 id,uint256 amount,uint256 deadline,uint256 nonce)"
            )
        );

    bytes32 private constant REMOVE_COLLATERAL_HASH =
        keccak256(
            bytes(
                "RemoveCollateral(address owner,bytes32 id,uint256 amount,uint256 deadline,uint256 nonce)"
            )
        );

    bytes32 private constant INC_POSITION_HASH =
        keccak256(
            bytes(
                "IncreasePosition(address owner,bytes32 id,uint256 amount,uint256 deadline,uint256 nonce)"
            )
        );

    bytes32 private constant DEC_POSITION_HASH =
        keccak256(
            bytes(
                "DecreasePosition(address owner,bytes32 id,uint256 amount,uint256 deadline,uint256 nonce)"
            )
        );

    function _verifyAddCollateral(
        bytes32 domainHash,
        uint256 nonce,
        bytes32 id,
        uint256 amount,
        Types.GasLess calldata gasLess
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                keccak256(
                    abi.encodePacked(
                        ADD_COLLATERAL_HASH,
                        uint256(uint160(gasLess.owner)),
                        id,
                        amount,
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

    function _verifyRemoveCollateral(
        bytes32 domainHash,
        uint256 nonce,
        bytes32 id,
        uint256 amount,
        Types.GasLess calldata gasLess
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                keccak256(
                    abi.encodePacked(
                        REMOVE_COLLATERAL_HASH,
                        uint256(uint160(gasLess.owner)),
                        id,
                        amount,
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

    function _verifyIncPosition(
        bytes32 domainHash,
        uint256 nonce,
        bytes32 id,
        uint256 amount,
        Types.GasLess calldata gasLess
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                keccak256(
                    abi.encodePacked(
                        INC_POSITION_HASH,
                        uint256(uint160(gasLess.owner)),
                        id,
                        amount,
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

    function _verifyDecPosition(
        bytes32 domainHash,
        uint256 nonce,
        bytes32 id,
        uint256 amount,
        Types.GasLess calldata gasLess
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                keccak256(
                    abi.encodePacked(
                        DEC_POSITION_HASH,
                        uint256(uint160(gasLess.owner)),
                        id,
                        amount,
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
}