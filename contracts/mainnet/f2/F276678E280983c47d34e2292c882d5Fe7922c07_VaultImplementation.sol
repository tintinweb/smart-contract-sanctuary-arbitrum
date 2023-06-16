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

pragma solidity >=0.8.0 <0.9.0;

interface ISwapper {
	function swap(
        address inToken,
        address outToken,
        uint256 inAmount,
        address caller,
        bytes calldata data
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../utils/SafeMath.sol";
import "../utils/RevertReasonParser.sol";
import "../utils/SafeERC20.sol";

contract MegaSwapper {
    using SafeMath for uint256;

    using SafeERC20 for IERC20;

    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant ZERO_ADDRESS =
        0x0000000000000000000000000000000000000000;

    event Swap(
        address indexed inToken,
        address indexed outToken,
        uint256 inAmount,
        uint256 outAmount,
        address recipient
    );

    function isETH(address token) internal pure returns (bool) {
        return (token == ZERO_ADDRESS || token == ETH_ADDRESS);
    }

    function swap(
        address inToken,
        address outToken,
        uint256 inAmount,
        address caller,
        bytes calldata data
    ) external payable returns (uint256) {
        address recipient = msg.sender;
        if (isETH(inToken)) {
            (bool success, bytes memory result) = address(caller).call{
                value: msg.value
            }(data);
            if (!success) {
                revert(RevertReasonParser.parse(result, "callBytes failed: "));
            }
        } else {
            IERC20(inToken).approve(caller, type(uint256).max);
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = address(caller).call(data);
            if (!success) {
                revert(RevertReasonParser.parse(result, "callBytes failed: "));
            }
            IERC20(inToken).approve(caller, 0);
        }

        bool outETH = isETH(outToken);
        uint256 outAmount;
        if (!outETH) {
            outAmount = IERC20(outToken).balanceOf(address(this));
            if (outAmount > 0) {
                IERC20(outToken).safeTransfer(recipient, outAmount);
            }
        } else {
            outAmount = address(this).balance;
            if (outAmount > 0) {
                _transferOutETH(recipient, outAmount);
            }
        }
        emit Swap(inToken, outToken, inAmount, outAmount, recipient);
        return outAmount;
    }

    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

    function _transferOutETH(address receiver, uint256 amountOut) internal {
        (bool success, ) = payable(receiver).call{value: amountOut}("");
        require(success, "vault: send ETH fail");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../utils/INameVersion.sol";
import "../utils/IAdmin.sol";

interface IUpdateState is INameVersion, IAdmin {
    function resetFreezeStart() external;

    function balances(
        address account,
        address asset
    ) external view returns (int256);

    struct AccountPosition {
        int64 volume;
        int64 lastCumulativeFundingPerVolume;
        int128 entryCost;
    }

    function accountPositions(
        address account,
        bytes32 symbolId
    ) external view returns (AccountPosition memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../utils/Admin.sol";

abstract contract UpdateStateStorage is Admin {

    address public implementation;

    bool internal _mutex;

    modifier _reentryLock_() {
        require(!_mutex, "update: reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    uint256 public lastUpdateTimestamp;

    uint256 public lastBatchId;

    uint256 public lastEndTimestamp;

    bool public isFreezed;

    bool public isFreezeStart;

    uint256 public freezeStartTimestamp;

    modifier _notFreezed() {
        require(!isFreezed, "update: freezed");
        _;
    }

    modifier _onlyOperator() {
        require(isOperator[msg.sender], "update: only operator");
        _;
    }

    struct SymbolInfo {
        string symbolName;
        bytes32 symbolId;
        uint256 minVolume;
        uint256 pricePrecision;
        uint256 volumePrecision;
        address marginAsset;
        bool delisted;
    }

    struct SymbolStats {
        int64 indexPrice;
        int64 cumulativeFundingPerVolume;
    }

    struct AccountPosition {
        int64 volume;
        int64 lastCumulativeFundingPerVolume;
        int128 entryCost;
    }

    mapping(address => bool) public isOperator;

    // indexed symbols for looping
    SymbolInfo[] public indexedSymbols;

    // symbolId => symbolInfo
    mapping (bytes32 => SymbolInfo) public symbols;

    // symbolId => symbolStats
    mapping(bytes32 => SymbolStats) public symbolStats;

    // user => asset => balance
    mapping(address => mapping(address => int256)) public balances;

    // account => symbolId => AccountPosition
    mapping(address => mapping(bytes32 => AccountPosition)) public accountPositions;

    // account => hold position #
    mapping(address => int256) public holdPositions;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IAdmin.sol";

abstract contract Admin is IAdmin {
    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, "Admin: only admin");
        _;
    }

    constructor() {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        require(newAdmin != address(0), "Admin: set to zero address");
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './INameVersion.sol';

/**
 * @dev Convenience contract for name and version information
 */
abstract contract NameVersion is INameVersion {

    bytes32 public immutable nameId;
    bytes32 public immutable versionId;

    constructor (string memory name, string memory version) {
        nameId = keccak256(abi.encodePacked(name));
        versionId = keccak256(abi.encodePacked(version));
    }

}

// File contracts/helpers/RevertReasonParser.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/// @title Library that allows to parse unsuccessful arbitrary calls revert reasons.
/// See https://solidity.readthedocs.io/en/latest/control-structures.html#revert for details.
/// Note that we assume revert reason being abi-encoded as Error(string) so it may fail to parse reason
/// if structured reverts appear in the future.
///
/// All unsuccessful parsings get encoded as Unknown(data) string
library RevertReasonParser {
    bytes4 private constant _PANIC_SELECTOR =
        bytes4(keccak256("Panic(uint256)"));
    bytes4 private constant _ERROR_SELECTOR =
        bytes4(keccak256("Error(string)"));

    function parse(
        bytes memory data,
        string memory prefix
    ) internal pure returns (string memory) {
        if (data.length >= 4) {
            bytes4 selector;
            assembly {
                // solhint-disable-line no-inline-assembly
                selector := mload(add(data, 0x20))
            }

            // 68 = 4-byte selector + 32 bytes offset + 32 bytes length
            if (selector == _ERROR_SELECTOR && data.length >= 68) {
                uint256 offset;
                bytes memory reason;
                // solhint-disable no-inline-assembly
                assembly {
                    // 36 = 32 bytes data length + 4-byte selector
                    offset := mload(add(data, 36))
                    reason := add(data, add(36, offset))
                }
                /*
                    revert reason is padded up to 32 bytes with ABI encoder: Error(string)
                    also sometimes there is extra 32 bytes of zeros padded in the end:
                    https://github.com/ethereum/solidity/issues/10170
                    because of that we can't check for equality and instead check
                    that offset + string length + extra 36 bytes is less than overall data length
                */
                require(
                    data.length >= 36 + offset + reason.length,
                    "Invalid revert reason"
                );
                return string(abi.encodePacked(prefix, "Error(", reason, ")"));
            }
            // 36 = 4-byte selector + 32 bytes integer
            else if (selector == _PANIC_SELECTOR && data.length == 36) {
                uint256 code;
                // solhint-disable no-inline-assembly
                assembly {
                    // 36 = 32 bytes data length + 4-byte selector
                    code := mload(add(data, 36))
                }
                return
                    string(
                        abi.encodePacked(prefix, "Panic(", _toHex(code), ")")
                    );
            }
        }

        return string(abi.encodePacked(prefix, "Unknown(", _toHex(data), ")"));
    }

    function _toHex(uint256 value) private pure returns (string memory) {
        return _toHex(abi.encodePacked(value));
    }

    function _toHex(bytes memory data) private pure returns (string memory) {
        bytes16 alphabet = 0x30313233343536373839616263646566;
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; ++i) {
            str[2 * i + 2] = alphabet[uint8(data[i] >> 4)];
            str[2 * i + 3] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";
import "./Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    uint256 constant UMAX = 2 ** 255 - 1;
    int256  constant IMIN = -2 ** 255;

    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, 'SafeMath.utoi: overflow');
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'SafeMath.itou: underflow');
        return uint256(a);
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, 'SafeMath.abs: overflow');
        return a >= 0 ? a : -a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

    // rescale a uint256 from base 10**decimals1 to 10**decimals2
    function rescale(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return decimals1 == decimals2 ? a : a * 10**decimals2 / 10**decimals1;
    }

    // rescale towards zero
    // b: rescaled value in decimals2
    // c: the remainder
    function rescaleDown(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        c = a - rescale(b, decimals2, decimals1);
    }

    // rescale towards infinity
    // b: rescaled value in decimals2
    // c: the excessive
    function rescaleUp(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        uint256 d = rescale(b, decimals2, decimals1);
        if (d != a) {
            b += 1;
            c = rescale(b, decimals2, decimals1) - a;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../utils/IERC20.sol";
import "../utils/NameVersion.sol";
import "../utils/SafeMath.sol";
import "../swapper/MegaSwapper.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../swapper/ISwapper.sol";
import "../update/IUpdateState.sol";
import "../update/UpdateStateStorage.sol";
import "./VaultStorage.sol";
import "../utils/SafeERC20.sol";

contract VaultImplementation is VaultStorage, NameVersion {
    using SafeERC20 for IERC20;

    event AddSigner(address signer);

    event RemoveSigner(address signer);

    event AddAsset(address asset);

    event RemoveAsset(address asset);

    event Deposit(
        address indexed token,
        address indexed account,
        uint256 amount
    );

    event Withdraw(
        address indexed token,
        address indexed account,
        uint256 amount,
        uint256 expiry,
        uint256 nonce,
        bytes signatures
    );

    using SafeMath for uint256;

    using SafeMath for int256;

    string public constant name = "Vault";

    uint256 public immutable chainId;

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    bytes32 public constant WITHDRAW_TYPEHASH =
        keccak256(
            "Withdraw(address token,address account,uint256 amount,uint256 expiry,uint256 nonce)"
        );

    ISwapper public immutable swapper;

    address public immutable update;

    address public immutable marketVault;

    constructor(
        address _swapper,
        address _update,
        address _marketVault
    ) NameVersion("VaultImplementation", "1.0.0") {
        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }
        chainId = _chainId;
        swapper = ISwapper(_swapper);
        update = _update;
        marketVault = _marketVault;
    }

    function initializeDomain() external {
        domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                chainId,
                address(this)
            )
        );
    }

    // ========================================================
    // balance update
    // ========================================================
    function setOperator(
        address operator_,
        bool isActive
    ) external _onlyAdmin_ {
        isOperator[operator_] = isActive;
    }

    // ONLY AVAILABLE ON ARBITRUM
    function transferOut(
        address account,
        address asset,
        uint256 amount
    ) external _notPaused_ _reentryLock_ {
        require(msg.sender == update, "vault: only update contract");
        if (asset == address(0)) {
            _transferOutETH(account, amount);
        } else {
            IERC20(asset).safeTransfer(account, amount);
        }
    }

    function settleMarketVault(
        address asset,
        uint256 amount
    ) external _notPaused_ {
        require(msg.sender == marketVault, "vault: only market maker vault");
        if (asset == address(0)) {
            uint256 balance = address(this).balance;
            if (amount > balance) {
                _transferOutETH(marketVault, balance);
                uint256 debtAmount = amount - balance;
                debtToMarketVault[asset] += debtAmount;
            } else {
                _transferOutETH(marketVault, amount);
            }
        } else {
            uint256 balance = IERC20(asset).balanceOf(address(this));
            if (amount > balance) {
                IERC20(asset).safeTransfer(marketVault, balance);
                uint256 debtAmount = amount - balance;
                debtToMarketVault[asset] += debtAmount;
            } else {
                IERC20(asset).safeTransfer(marketVault, amount);
            }
        }
    }

    function repayMarketVault(
        address asset
    ) external _notPaused_ _reentryLock_ {
        uint256 debtAmount = debtToMarketVault[asset];
        require(debtAmount > 0, "vault: no debt");
        if (asset == address(0)) {
            require(
                debtAmount <= address(this).balance,
                "vault: transfer exceed balance"
            );
            debtToMarketVault[asset] = 0;
            _transferOutETH(marketVault, debtAmount);
        } else {
            require(
                debtAmount <= IERC20(asset).balanceOf(address(this)),
                "vault: transfer exceed balance"
            );
            debtToMarketVault[asset] = 0;
            IERC20(asset).safeTransfer(marketVault, debtAmount);
        }
    }

    function pause() external _onlyAdmin_ _notPaused_ {
        _paused = true;
    }

    function unpause() external _onlyAdmin_ {
        _paused = false;
    }

    // ========================================================
    // udpate signers
    // ========================================================
    function addSigner(address newSigner) external _onlyAdmin_ {
        require(!isValidSigner[newSigner], "vault: duplicate signer");
        validSigners.push(newSigner);
        isValidSigner[newSigner] = true;
        validatorIndex[newSigner] = validSigners.length;
        emit AddSigner(newSigner);
    }

    function removeSigner(address removedSigner) external _onlyAdmin_ {
        require(isValidSigner[removedSigner], "vault: not a valid signer");
        uint256 length = validSigners.length;
        for (uint256 i = 0; i < length; ++i) {
            if (validSigners[i] == removedSigner) {
                validSigners[i] = validSigners[length - 1];
                break;
            }
        }
        validSigners.pop();
        validatorIndex[removedSigner] = 0;
        isValidSigner[removedSigner] = false;

        uint256 len = validSigners.length;
        for (uint i = 0; i < len; ++i) {
            validatorIndex[validSigners[i]] = i + 1;
        }
        emit RemoveSigner(removedSigner);
    }

    function setSignatureThreshold(
        uint256 newSignatureThreshold
    ) external _onlyAdmin_ {
        signatureThreshold = newSignatureThreshold;
    }

    // ========================================================
    // Asset Management
    // ========================================================
    function addAsset(address asset) external {
        require(isOperator[msg.sender], "vault: only operator");
        require(!supportedAsset[asset], "vault: asset already added");
        indexedAssets.push(asset);
        supportedAsset[asset] = true;
        emit AddAsset(asset);
    }

    function removeAsset(address asset) external {
        require(isOperator[msg.sender], "vault: only operator");
        require(supportedAsset[asset], "vault: asset not found");
        uint256 length = indexedAssets.length;
        for (uint256 i = 0; i < length; ++i) {
            if (indexedAssets[i] == asset) {
                indexedAssets[i] = indexedAssets[length - 1];
                break;
            }
        }
        indexedAssets.pop();
        supportedAsset[asset] = false;
        emit RemoveAsset(asset);
    }

    // ========================================================
    // deposit&withdraw
    // ========================================================
    function swapAndDeposit(
        address inToken,
        address outToken,
        uint256 inAmount,
        address caller,
        bytes calldata data
    ) external payable _reentryLock_ _notPaused_ {
        require(supportedAsset[outToken], "vault: unsupported asset");
        address account = msg.sender;
        uint256 outAmount;
        if (inToken == address(0)) {
            require(
                msg.value > 0 && msg.value == inAmount,
                "vault: wrong ETH amount"
            );
            outAmount = swapper.swap{value: msg.value}(
                inToken,
                outToken,
                inAmount,
                caller,
                data
            );
        } else {
            require(inAmount > 0, "vault: amount should be greater than 0");
            IERC20(inToken).safeTransferFrom(
                account,
                address(swapper),
                inAmount
            );
            outAmount = swapper.swap(inToken, outToken, inAmount, caller, data);
        }

        if (outToken == address(0)) {
            emit Deposit(address(0), account, outAmount);
        } else {
            emit Deposit(outToken, account, outAmount);
        }
    }

    function deposit(
        address token,
        uint256 amount
    ) public payable _reentryLock_ _notPaused_ {
        address account = msg.sender;
        require(supportedAsset[token], "vault: unsupported asset");
        if (token == address(0)) {
            require(
                msg.value > 0 && msg.value == amount,
                "vault: wrong ETH amount"
            );
            emit Deposit(address(0), account, amount);
        } else {
            require(amount > 0, "vault: amount should be greater than 0");
            IERC20(token).safeTransferFrom(account, address(this), amount);
            emit Deposit(token, account, amount);
        }
    }

    function withdraw(
        address token,
        uint256 amount,
        uint256 expiry,
        uint256 nonce,
        bytes calldata signatures
    ) external _reentryLock_ _notPaused_ {
        address account = msg.sender;
        require(expiry >= block.timestamp, "vault: withdraw expired");
        _checkSignature(token, amount, expiry, nonce, signatures);
        // reset freeze start
        if (update != address(0)) IUpdateState(update).resetFreezeStart();

        if (token == address(0)) {
            _transferOutETH(account, amount);
        } else {
            IERC20(token).safeTransfer(account, amount);
        }
        emit Withdraw(token, account, amount, expiry, nonce, signatures);
    }

    function swapAndWithdraw(
        address inToken,
        uint256 inAmount,
        uint256 expiry,
        uint256 nonce,
        bytes calldata signatures,
        address outToken,
        address caller,
        bytes calldata data
    ) external _reentryLock_ _notPaused_ {
        address account = msg.sender;
        require(expiry >= block.timestamp, "vault: withdraw expired");
        _checkSignature(inToken, inAmount, expiry, nonce, signatures);
        // reset freeze start
        if (update != address(0)) IUpdateState(update).resetFreezeStart();

        uint256 outAmount;
        if (inToken == address(0)) {
            outAmount = swapper.swap{value: inAmount}(
                inToken,
                outToken,
                inAmount,
                caller,
                data
            );
        } else {
            IERC20(inToken).safeTransfer(address(swapper), inAmount);
            outAmount = swapper.swap(inToken, outToken, inAmount, caller, data);
        }
        if (outToken == address(0)) {
            _transferOutETH(account, outAmount);
        } else {
            IERC20(outToken).safeTransfer(account, outAmount);
        }
        emit Withdraw(inToken, account, inAmount, expiry, nonce, signatures);
    }

    function _checkSignature(
        address token,
        uint256 amount,
        uint256 expiry,
        uint256 nonce,
        bytes calldata signatures
    ) internal {
        bytes32 structHash = keccak256(
            abi.encode(
                WITHDRAW_TYPEHASH,
                token,
                msg.sender,
                amount,
                expiry,
                nonce
            )
        );
        require(!usedHash[structHash], "vault: withdraw replay");
        usedHash[structHash] = true;

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        require(signatures.length % 65 == 0, "vault: invalid signature length");
        uint256 signatureCount = signatures.length / 65;
        require(
            signatureCount >= signatureThreshold,
            "vault: wrong number of signatures"
        );

        address recovered;
        uint256 validCount;
        bool[] memory signerIndexVisited = new bool[](validSigners.length);

        for (uint i = 0; i < signatureCount; ++i) {
            recovered = ECDSA.recover(digest, signatures[i * 65:(i + 1) * 65]);
            if (
                isValidSigner[recovered] &&
                !signerIndexVisited[_validatorRealIndex(recovered)]
            ) {
                validCount++;
                signerIndexVisited[_validatorRealIndex(recovered)] = true;
            }
        }
        require(
            validCount >= signatureThreshold,
            "vault:number of signers not reach limit"
        );
    }

    function _transferOutETH(address receiver, uint256 amountOut) internal {
        (bool success, ) = payable(receiver).call{value: amountOut}("");
        require(success, "vault: send ETH fail");
    }

    function _validatorRealIndex(
        address validator
    ) internal view returns (uint256) {
        uint256 idx = validatorIndex[validator];
        require(idx > 0, "validator is not valid");
        return idx - 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../utils/Admin.sol";

abstract contract VaultStorage is Admin {
    address public implementation;

    bool internal _mutex;

    bool public _paused;

    modifier _reentryLock_() {
        require(!_mutex, "Vault: reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _notPaused_() {
        require(!_paused, "Vault: paused");
        _;
    }

    bytes32 public domainSeparator;

    address[] public indexedAssets;

    mapping(address => bool) public supportedAsset;

    uint256 public signatureThreshold;

    address[] public validSigners;

    mapping(address => bool) public isValidSigner;

    mapping(address => uint256) public validatorIndex;

    mapping(bytes32 => bool) public usedHash;

    mapping(address => bool) public isOperator;

    mapping(address => uint256) public debtToMarketVault;
}