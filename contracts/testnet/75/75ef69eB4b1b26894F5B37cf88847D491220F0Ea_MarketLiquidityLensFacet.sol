// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/IERC1155MetadataURI.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/DoubleEndedQueue.sol)
pragma solidity ^0.8.4;

import "../math/SafeCast.sol";

/**
 * @dev A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 *
 * The struct is called `Bytes32Deque`. Other types can be cast to and from `bytes32`. This data structure can only be
 * used in storage, and not in memory.
 * ```solidity
 * DoubleEndedQueue.Bytes32Deque queue;
 * ```
 *
 * _Available since v4.6._
 */
library DoubleEndedQueue {
    /**
     * @dev An operation (e.g. {front}) couldn't be completed due to the queue being empty.
     */
    error Empty();

    /**
     * @dev An operation (e.g. {at}) couldn't be completed due to an index being out of bounds.
     */
    error OutOfBounds();

    /**
     * @dev Indices are signed integers because the queue can grow in any direction. They are 128 bits so begin and end
     * are packed in a single storage slot for efficient access. Since the items are added one at a time we can safely
     * assume that these 128-bit indices will not overflow, and use unchecked arithmetic.
     *
     * Struct members have an underscore prefix indicating that they are "private" and should not be read or written to
     * directly. Use the functions provided below instead. Modifying the struct manually may violate assumptions and
     * lead to unexpected behavior.
     *
     * Indices are in the range [begin, end) which means the first item is at data[begin] and the last item is at
     * data[end - 1].
     */
    struct Bytes32Deque {
        int128 _begin;
        int128 _end;
        mapping(int128 => bytes32) _data;
    }

    /**
     * @dev Inserts an item at the end of the queue.
     */
    function pushBack(Bytes32Deque storage deque, bytes32 value) internal {
        int128 backIndex = deque._end;
        deque._data[backIndex] = value;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    /**
     * @dev Removes the item at the end of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popBack(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        value = deque._data[backIndex];
        delete deque._data[backIndex];
        deque._end = backIndex;
    }

    /**
     * @dev Inserts an item at the beginning of the queue.
     */
    function pushFront(Bytes32Deque storage deque, bytes32 value) internal {
        int128 frontIndex;
        unchecked {
            frontIndex = deque._begin - 1;
        }
        deque._data[frontIndex] = value;
        deque._begin = frontIndex;
    }

    /**
     * @dev Removes the item at the beginning of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popFront(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        value = deque._data[frontIndex];
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

    /**
     * @dev Returns the item at the beginning of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function front(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    /**
     * @dev Returns the item at the end of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function back(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        return deque._data[backIndex];
    }

    /**
     * @dev Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
     * `length(deque) - 1`.
     *
     * Reverts with `OutOfBounds` if the index is out of bounds.
     */
    function at(Bytes32Deque storage deque, uint256 index) internal view returns (bytes32 value) {
        // int256(deque._begin) is a safe upcast
        int128 idx = SafeCast.toInt128(int256(deque._begin) + SafeCast.toInt256(index));
        if (idx >= deque._end) revert OutOfBounds();
        return deque._data[idx];
    }

    /**
     * @dev Resets the queue back to being empty.
     *
     * NOTE: The current items are left behind in storage. This does not affect the functioning of the queue, but misses
     * out on potential gas refunds.
     */
    function clear(Bytes32Deque storage deque) internal {
        deque._begin = 0;
        deque._end = 0;
    }

    /**
     * @dev Returns the number of items in the queue.
     */
    function length(Bytes32Deque storage deque) internal view returns (uint256) {
        // The interface preserves the invariant that begin <= end so we assume this will not overflow.
        // We also assume there are at most int256.max items in the queue.
        unchecked {
            return uint256(int256(deque._end) - int256(deque._begin));
        }
    }

    /**
     * @dev Returns true if the queue is empty.
     */
    function empty(Bytes32Deque storage deque) internal view returns (bool) {
        return deque._end <= deque._begin;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {MarketStorage, MarketStorageLib} from "@chromatic-protocol/contracts/core/libraries/MarketStorage.sol";

abstract contract MarketFacetBase {
    /**
     * @dev Throws an error indicating that the caller is not the DAO.
     */
    error OnlyAccessableByDao();

    /**
     * @dev Throws an error indicating that the caller is not the chromatic liquidator contract.
     */

    error OnlyAccessableByLiquidator();

    /**
     * @dev Throws an error indicating that the caller is not the chromatch vault contract.
     */
    error OnlyAccessableByVault();

    /**
     * @dev Modifier to restrict access to only the DAO.
     *      Throws an `OnlyAccessableByDao` error if the caller is not the DAO.
     */
    modifier onlyDao() {
        if (msg.sender != MarketStorageLib.marketStorage().factory.dao())
            revert OnlyAccessableByDao();
        _;
    }

    /**
     * @dev Modifier to restrict access to only the liquidator contract.
     *      Throws an `OnlyAccessableByLiquidator` error if the caller is not the chromatic liquidator contract.
     */
    modifier onlyLiquidator() {
        if (msg.sender != address(MarketStorageLib.marketStorage().liquidator))
            revert OnlyAccessableByLiquidator();
        _;
    }

    /**
     * @dev Modifier to restrict a function to be called only by the vault contract.
     *      Throws an `OnlyAccessableByVault` error if the caller is not the chromatic vault contract.
     */
    modifier onlyVault() {
        if (msg.sender != address(MarketStorageLib.marketStorage().vault))
            revert OnlyAccessableByVault();
        _;
    }

    /**
     * @dev Creates a new LP context.
     * @return The LP context.
     */
    function newLpContext(MarketStorage storage ms) internal view returns (LpContext memory) {
        
        //slither-disable-next-line uninitialized-local
        IOracleProvider.OracleVersion memory _currentVersionCache;
        return
            LpContext({
                oracleProvider: ms.oracleProvider,
                interestCalculator: ms.factory,
                vault: ms.vault,
                clbToken: ms.clbToken,
                market: address(this),
                settlementToken: address(ms.settlementToken),
                tokenPrecision: 10 ** ms.settlementToken.decimals(),
                _currentVersionCache: _currentVersionCache
            });
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {LpReceipt, LpAction} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";
import {LpReceiptStorage, LpReceiptStorageLib} from "@chromatic-protocol/contracts/core/libraries/MarketStorage.sol";
import {MarketFacetBase} from "@chromatic-protocol/contracts/core/facets/market/MarketFacetBase.sol";

abstract contract MarketLiquidityFacetBase is MarketFacetBase {
    /**
     * @dev Throws an error indicating that the specified liquidity receipt does not exist.
     */
    error NotExistLpReceipt();

    function _getLpReceipt(
        LpReceiptStorage storage ls,
        uint256 receiptId
    ) internal view returns (LpReceipt memory receipt) {
        receipt = ls.getReceipt(receiptId);
        if (receipt.id == 0) revert NotExistLpReceipt();
    }

    /**
     * @dev Creates a new liquidity receipt.
     * @param ctx The liquidity context.
     * @param action The liquidity action.
     * @param amount The amount of liquidity.
     * @param recipient The address to receive the liquidity.
     * @param tradingFeeRate The trading fee rate for the liquidity.
     * @return The new liquidity receipt.
     */
    function _newLpReceipt(
        LpContext memory ctx,
        LpAction action,
        uint256 amount,
        address recipient,
        int16 tradingFeeRate
    ) internal returns (LpReceipt memory) {
        return
            LpReceipt({
                id: LpReceiptStorageLib.lpReceiptStorage().nextId(),
                oracleVersion: ctx.currentOracleVersion().version,
                action: action,
                amount: amount,
                recipient: recipient,
                tradingFeeRate: tradingFeeRate
            });
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {IMarketLiquidityLens} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidityLens.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";
import {LiquidityPool} from "@chromatic-protocol/contracts/core/libraries/liquidity/LiquidityPool.sol";
import {MarketStorage, MarketStorageLib, LpReceiptStorageLib} from "@chromatic-protocol/contracts/core/libraries/MarketStorage.sol";
import {MarketLiquidityFacetBase} from "@chromatic-protocol/contracts/core/facets/market/MarketLiquidityFacetBase.sol";

/**
 * @title MarketLiquidityLensFacet
 * @dev Contract for liquidity information retrieval in a market.
 */
contract MarketLiquidityLensFacet is MarketLiquidityFacetBase, IMarketLiquidityLens {
    /**
     * @inheritdoc IMarketLiquidityLens
     */
    function getBinLiquidity(int16 tradingFeeRate) external view override returns (uint256 amount) {
        amount = MarketStorageLib.marketStorage().liquidityPool.getBinLiquidity(tradingFeeRate);
    }

    /**
     * @inheritdoc IMarketLiquidityLens
     */
    function getBinFreeLiquidity(
        int16 tradingFeeRate
    ) external view override returns (uint256 amount) {
        amount = MarketStorageLib.marketStorage().liquidityPool.getBinFreeLiquidity(tradingFeeRate);
    }

    /**
     * @inheritdoc IMarketLiquidityLens
     */
    function getBinValues(
        int16[] memory tradingFeeRates
    ) external view override returns (uint256[] memory) {
        MarketStorage storage ms = MarketStorageLib.marketStorage();
        LiquidityPool storage liquidityPool = ms.liquidityPool;

        LpContext memory ctx = newLpContext(ms);
        uint256[] memory values = new uint256[](tradingFeeRates.length);
        for (uint256 i; i < tradingFeeRates.length; ) {
            values[i] = liquidityPool.binValue(tradingFeeRates[i], ctx);

            unchecked {
                i++;
            }
        }
        return values;
    }

    /**
     * @inheritdoc IMarketLiquidityLens
     * @dev Throws a `NotExistLpReceipt` error if the liquidity receipt does not exist.
     */
    function getLpReceipt(uint256 receiptId) external view returns (LpReceipt memory receipt) {
        receipt = _getLpReceipt(LpReceiptStorageLib.lpReceiptStorage(), receiptId);
    }

    /**
     * @inheritdoc IMarketLiquidityLens
     */
    function pendingLiquidity(
        int16 tradingFeeRate
    ) external view returns (IMarketLiquidity.PendingLiquidity memory) {
        return MarketStorageLib.marketStorage().liquidityPool.pendingLiquidity(tradingFeeRate);
    }

    /**
     * @inheritdoc IMarketLiquidityLens
     */
    function pendingLiquidityBatch(
        int16[] calldata tradingFeeRates
    ) external view returns (IMarketLiquidity.PendingLiquidity[] memory) {
        IMarketLiquidity.PendingLiquidity[]
            memory liquidities = new IMarketLiquidity.PendingLiquidity[](tradingFeeRates.length);

        LiquidityPool storage pool = MarketStorageLib.marketStorage().liquidityPool;
        for (uint256 i; i < tradingFeeRates.length; ) {
            liquidities[i] = pool.pendingLiquidity(tradingFeeRates[i]);

            unchecked {
                i++;
            }
        }

        return liquidities;
    }

    /**
     * @inheritdoc IMarketLiquidityLens
     */
    function claimableLiquidity(
        int16 tradingFeeRate,
        uint256 oracleVersion
    ) external view returns (IMarketLiquidity.ClaimableLiquidity memory) {
        return
            MarketStorageLib.marketStorage().liquidityPool.claimableLiquidity(
                tradingFeeRate,
                oracleVersion
            );
    }

    /**
     * @inheritdoc IMarketLiquidityLens
     */
    function claimableLiquidityBatch(
        int16[] calldata tradingFeeRates,
        uint256 oracleVersion
    ) external view returns (IMarketLiquidity.ClaimableLiquidity[] memory) {
        IMarketLiquidity.ClaimableLiquidity[]
            memory liquidities = new IMarketLiquidity.ClaimableLiquidity[](tradingFeeRates.length);

        LiquidityPool storage pool = MarketStorageLib.marketStorage().liquidityPool;
        for (uint256 i; i < tradingFeeRates.length; ) {
            liquidities[i] = pool.claimableLiquidity(tradingFeeRates[i], oracleVersion);

            unchecked {
                i++;
            }
        }

        return liquidities;
    }

    /**
     * @inheritdoc IMarketLiquidityLens
     */
    function liquidityBinStatuses()
        external
        view
        returns (IMarketLiquidity.LiquidityBinStatus[] memory)
    {
        MarketStorage storage ms = MarketStorageLib.marketStorage();
        return ms.liquidityPool.liquidityBinStatuses(newLpContext(ms));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title An interface for a contract that is capable of deploying Chromatic markets
 * @notice A contract that constructs a market must implement this to pass arguments to the market
 * @dev This is used to avoid having constructor arguments in the market contract, which results in the init code hash
 * of the market being constant allowing the CREATE2 address of the market to be cheaply computed on-chain
 */
interface IMarketDeployer {
    /**
     * @notice Get the parameters to be used in constructing the market, set transiently during market creation.
     * @dev Called by the market constructor to fetch the parameters of the market
     * Returns underlyingAsset The underlying asset of the market
     * Returns settlementToken The settlement token of the market
     * Returns vPoolCapacity Capacity of virtual future pool
     * Returns vPoolA Amplification coefficient of virtual future pool, precise value
     */
    function parameters() external view returns (address oracleProvider, address settlementToken);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IOracleProviderRegistry
 * @dev Interface for the Oracle Provider Registry contract.
 */
interface IOracleProviderRegistry {
    
    /**
     * @dev The OracleProviderProperties struct represents properties of the oracle provider.
     * @param minTakeProfitBPS The minimum take-profit basis points.
     * @param maxTakeProfitBPS The maximum take-profit basis points.
     * @param leverageLevel The leverage level of the oracle provider.
     */
    struct OracleProviderProperties {
        uint32 minTakeProfitBPS;
        uint32 maxTakeProfitBPS;
        uint8 leverageLevel;
    }

    /**
     * @dev Emitted when a new oracle provider is registered.
     * @param oracleProvider The address of the registered oracle provider.
     * @param properties The properties of the registered oracle provider.
     */
    event OracleProviderRegistered(
        address indexed oracleProvider,
        OracleProviderProperties properties
    );

    /**
     * @dev Emitted when an oracle provider is unregistered.
     * @param oracleProvider The address of the unregistered oracle provider.
     */
    event OracleProviderUnregistered(address indexed oracleProvider);

    /**
     * @dev Emitted when the take-profit basis points range of an oracle provider is updated.
     * @param oracleProvider The address of the oracle provider.
     * @param minTakeProfitBPS The new minimum take-profit basis points.
     * @param maxTakeProfitBPS The new maximum take-profit basis points.
     */
    event UpdateTakeProfitBPSRange(
        address indexed oracleProvider,
        uint32 indexed minTakeProfitBPS,
        uint32 indexed maxTakeProfitBPS
    );

    /**
     * @dev Emitted when the level of an oracle provider is set.
     * @param oracleProvider The address of the oracle provider.
     * @param level The new level set for the oracle provider.
     */
    event UpdateLeverageLevel(address indexed oracleProvider, uint8 indexed level);

    /**
     * @notice Registers an oracle provider.
     * @param oracleProvider The address of the oracle provider to register.
     * @param properties The properties of the oracle provider.
     */
    function registerOracleProvider(
        address oracleProvider,
        OracleProviderProperties memory properties
    ) external;

    /**
     * @notice Unregisters an oracle provider.
     * @param oracleProvider The address of the oracle provider to unregister.
     */
    function unregisterOracleProvider(address oracleProvider) external;

    /**
     * @notice Gets the registered oracle providers.
     * @return An array of registered oracle provider addresses.
     */
    function registeredOracleProviders() external view returns (address[] memory);

    /**
     * @notice Checks if an oracle provider is registered.
     * @param oracleProvider The address of the oracle provider to check.
     * @return A boolean indicating if the oracle provider is registered.
     */
    function isRegisteredOracleProvider(address oracleProvider) external view returns (bool);

    /**
     * @notice Retrieves the properties of an oracle provider.
     * @param oracleProvider The address of the oracle provider.
     * @return The properties of the oracle provider.
     */
    function getOracleProviderProperties(
        address oracleProvider
    ) external view returns (OracleProviderProperties memory);

    /**
     * @notice Updates the take-profit basis points range of an oracle provider.
     * @param oracleProvider The address of the oracle provider.
     * @param minTakeProfitBPS The new minimum take-profit basis points.
     * @param maxTakeProfitBPS The new maximum take-profit basis points.
     */
    function updateTakeProfitBPSRange(
        address oracleProvider,
        uint32 minTakeProfitBPS,
        uint32 maxTakeProfitBPS
    ) external;

    /**
     * @notice Updates the leverage level of an oracle provider in the registry.
     * @dev The level must be either 0 or 1, and the max leverage must be x10 for level 0 or x20 for level 1.
     * @param oracleProvider The address of the oracle provider.
     * @param level The new leverage level to be set for the oracle provider.
     */
    function updateLeverageLevel(address oracleProvider, uint8 level) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {InterestRate} from "@chromatic-protocol/contracts/core/libraries/InterestRate.sol";

/**
 * @title ISettlementTokenRegistry
 * @dev Interface for the Settlement Token Registry contract.
 */
interface ISettlementTokenRegistry {
    /**
     * @dev Emitted when a new settlement token is registered.
     * @param token The address of the registered settlement token.
     * @param minimumMargin The minimum margin for the markets using this settlement token.
     * @param interestRate The interest rate for the settlement token.
     * @param flashLoanFeeRate The flash loan fee rate for the settlement token.
     * @param earningDistributionThreshold The earning distribution threshold for the settlement token.
     * @param uniswapFeeTier The Uniswap fee tier for the settlement token.
     */
    event SettlementTokenRegistered(
        address indexed token,
        uint256 indexed minimumMargin,
        uint256 indexed interestRate,
        uint256 flashLoanFeeRate,
        uint256 earningDistributionThreshold,
        uint24 uniswapFeeTier
    );

    /**
     * @dev Emitted when the minimum margin for a settlement token is set.
     * @param token The address of the settlement token.
     * @param minimumMargin The new minimum margin for the settlement token.
     */
    event SetMinimumMargin(address indexed token, uint256 indexed minimumMargin);

    /**
     * @dev Emitted when the flash loan fee rate for a settlement token is set.
     * @param token The address of the settlement token.
     * @param flashLoanFeeRate The new flash loan fee rate for the settlement token.
     */
    event SetFlashLoanFeeRate(address indexed token, uint256 indexed flashLoanFeeRate);

    /**
     * @dev Emitted when the earning distribution threshold for a settlement token is set.
     * @param token The address of the settlement token.
     * @param earningDistributionThreshold The new earning distribution threshold for the settlement token.
     */
    event SetEarningDistributionThreshold(
        address indexed token,
        uint256 indexed earningDistributionThreshold
    );

    /**
     * @dev Emitted when the Uniswap fee tier for a settlement token is set.
     * @param token The address of the settlement token.
     * @param uniswapFeeTier The new Uniswap fee tier for the settlement token.
     */
    event SetUniswapFeeTier(address indexed token, uint24 indexed uniswapFeeTier);

    /**
     * @dev Emitted when an interest rate record is appended for a settlement token.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points (BPS).
     * @param beginTimestamp The timestamp when the interest rate record begins.
     */
    event InterestRateRecordAppended(
        address indexed token,
        uint256 indexed annualRateBPS,
        uint256 indexed beginTimestamp
    );

    /**
     * @dev Emitted when the last interest rate record is removed for a settlement token.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points (BPS).
     * @param beginTimestamp The timestamp when the interest rate record begins.
     */
    event LastInterestRateRecordRemoved(
        address indexed token,
        uint256 indexed annualRateBPS,
        uint256 indexed beginTimestamp
    );

    /**
     * @notice Registers a new settlement token.
     * @param token The address of the settlement token to register.
     * @param minimumMargin The minimum margin for the settlement token.
     * @param interestRate The interest rate for the settlement token.
     * @param flashLoanFeeRate The flash loan fee rate for the settlement token.
     * @param earningDistributionThreshold The earning distribution threshold for the settlement token.
     * @param uniswapFeeTier The Uniswap fee tier for the settlement token.
     */
    function registerSettlementToken(
        address token,
        uint256 minimumMargin,
        uint256 interestRate,
        uint256 flashLoanFeeRate,
        uint256 earningDistributionThreshold,
        uint24 uniswapFeeTier
    ) external;

    /**
     * @notice Gets the list of registered settlement tokens.
     * @return An array of addresses representing the registered settlement tokens.
     */
    function registeredSettlementTokens() external view returns (address[] memory);

    /**
     * @notice Checks if a settlement token is registered.
     * @param token The address of the settlement token to check.
     * @return True if the settlement token is registered, false otherwise.
     */
    function isRegisteredSettlementToken(address token) external view returns (bool);

    /**
     * @notice Gets the minimum margin for a settlement token.
     * @dev The minimumMargin is used as the minimum value for the taker margin of a position
     *      or as the minimum value for the maker margin of each bin.
     * @param token The address of the settlement token.
     * @return The minimum margin for the settlement token.
     */
    function getMinimumMargin(address token) external view returns (uint256);

    /**
     * @notice Sets the minimum margin for a settlement token.
     * @param token The address of the settlement token.
     * @param minimumMargin The new minimum margin for the settlement token.
     */
    function setMinimumMargin(address token, uint256 minimumMargin) external;

    /**
     * @notice Gets the flash loan fee rate for a settlement token.
     * @param token The address of the settlement token.
     * @return The flash loan fee rate for the settlement token.
     */
    function getFlashLoanFeeRate(address token) external view returns (uint256);

    /**
     * @notice Sets the flash loan fee rate for a settlement token.
     * @param token The address of the settlement token.
     * @param flashLoanFeeRate The new flash loan fee rate for the settlement token.
     */
    function setFlashLoanFeeRate(address token, uint256 flashLoanFeeRate) external;

    /**
     * @notice Gets the earning distribution threshold for a settlement token.
     * @param token The address of the settlement token.
     * @return The earning distribution threshold for the settlement token.
     */
    function getEarningDistributionThreshold(address token) external view returns (uint256);

    /**
     * @notice Sets the earning distribution threshold for a settlement token.
     * @param token The address of the settlement token.
     * @param earningDistributionThreshold The new earning distribution threshold for the settlement token.
     */
    function setEarningDistributionThreshold(
        address token,
        uint256 earningDistributionThreshold
    ) external;

    /**
     * @notice Gets the Uniswap fee tier for a settlement token.
     * @param token The address of the settlement token.
     * @return The Uniswap fee tier for the settlement token.
     */
    function getUniswapFeeTier(address token) external view returns (uint24);

    /**
     * @notice Sets the Uniswap fee tier for a settlement token.
     * @param token The address of the settlement token.
     * @param uniswapFeeTier The new Uniswap fee tier for the settlement token.
     */
    function setUniswapFeeTier(address token, uint24 uniswapFeeTier) external;

    /**
     * @notice Appends an interest rate record for a settlement token.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points (BPS).
     * @param beginTimestamp The timestamp when the interest rate record begins.
     */
    function appendInterestRateRecord(
        address token,
        uint256 annualRateBPS,
        uint256 beginTimestamp
    ) external;

    /**
     * @notice Removes the last interest rate record for a settlement token.
     * @param token The address of the settlement token.
     */
    function removeLastInterestRateRecord(address token) external;

    /**
     * @notice Gets the current interest rate for a settlement token.
     * @param token The address of the settlement token.
     * @return The current interest rate for the settlement token.
     */
    function currentInterestRate(address token) external view returns (uint256);

    /**
     * @notice Gets all the interest rate records for a settlement token.
     * @param token The address of the settlement token.
     * @return An array of interest rate records for the settlement token.
     */
    function getInterestRateRecords(
        address token
    ) external view returns (InterestRate.Record[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IChromaticLiquidator
 * @dev Interface for the Chromatic Liquidator contract.
 */
interface IChromaticLiquidator {
    /**
     * @notice Emitted when the liquidation task interval is updated.
     * @param interval The new liquidation task interval.
     */
    event UpdateLiquidationInterval(uint256 indexed interval);

    /**
     * @notice Emitted when the claim task interval is updated.
     * @param interval The new claim task interval.
     */
    event UpdateClaimInterval(uint256 indexed interval);

    /**
     * @notice Updates the liquidation task interval.
     * @param interval The new liquidation task interval.
     */
    function updateLiquidationInterval(uint256 interval) external;

    /**
     * @notice Updates the claim task interval.
     * @param interval The new claim task interval.
     */
    function updateClaimInterval(uint256 interval) external;

    /**
     * @notice Creates a liquidation task for a given position.
     * @param positionId The ID of the position to be liquidated.
     */
    function createLiquidationTask(uint256 positionId) external;

    /**
     * @notice Cancels a liquidation task for a given position.
     * @param positionId The ID of the position for which to cancel the liquidation task.
     */
    function cancelLiquidationTask(uint256 positionId) external;

    /**
     * @notice Resolves the liquidation of a position.
     * @dev This function is called by the Gelato automation system.
     * @param market The address of the market contract.
     * @param positionId The ID of the position to be liquidated.
     * @return canExec Whether the liquidation can be executed.
     * @return execPayload The encoded function call to execute the liquidation.
     */
    function resolveLiquidation(
        address market,
        uint256 positionId
    ) external view returns (bool canExec, bytes memory execPayload);

    /**
     * @notice Liquidates a position in a market.
     * @param market The address of the market contract.
     * @param positionId The ID of the position to be liquidated.
     */
    function liquidate(address market, uint256 positionId) external;

    /**
     * @notice Creates a claim position task for a given position.
     * @param positionId The ID of the position to be claimed.
     */
    function createClaimPositionTask(uint256 positionId) external;

    /**
     * @notice Cancels a claim position task for a given position.
     * @param positionId The ID of the position for which to cancel the claim position task.
     */
    function cancelClaimPositionTask(uint256 positionId) external;

    /**
     * @notice Resolves the claim of a position.
     * @dev This function is called by the Gelato automation system.
     * @param market The address of the market contract.
     * @param positionId The ID of the position to be claimed.
     * @return canExec Whether the claim can be executed.
     * @return execPayload The encoded function call to execute the claim.
     */
    function resolveClaimPosition(
        address market,
        uint256 positionId
    ) external view returns (bool canExec, bytes memory execPayload);

    /**
     * @notice Claims a position in a market.
     * @param market The address of the market contract.
     * @param positionId The ID of the position to be claimed.
     */
    function claimPosition(address market, uint256 positionId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IMarketTrade} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketTrade.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {IMarketLiquidityLens} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidityLens.sol";
import {IMarketState} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketState.sol";
import {IMarketLiquidate} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidate.sol";
import {IMarketSettle} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketSettle.sol";

/**
 * @title IChromaticMarket
 * @dev Interface for the Chromatic Market contract, which combines trade and liquidity functionalities.
 */
interface IChromaticMarket is
    IMarketTrade,
    IMarketLiquidity,
    IMarketLiquidityLens,
    IMarketState,
    IMarketLiquidate,
    IMarketSettle
{

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IInterestCalculator} from "@chromatic-protocol/contracts/core/interfaces/IInterestCalculator.sol";
import {IMarketDeployer} from "@chromatic-protocol/contracts/core/interfaces/factory/IMarketDeployer.sol";
import {ISettlementTokenRegistry} from "@chromatic-protocol/contracts/core/interfaces/factory/ISettlementTokenRegistry.sol";
import {IOracleProviderRegistry} from "@chromatic-protocol/contracts/core/interfaces/factory/IOracleProviderRegistry.sol";

/**
 * @title IChromaticMarketFactory
 * @dev Interface for the Chromatic Market Factory contract.
 */
interface IChromaticMarketFactory is
    IMarketDeployer,
    IOracleProviderRegistry,
    ISettlementTokenRegistry,
    IInterestCalculator
{
    /**
     * @notice Emitted when the DAO address is updated.
     * @param dao The new DAO address.
     */
    event UpdateDao(address indexed dao);

    /**
     * @notice Emitted when the DAO treasury address is updated.
     * @param treasury The new DAO treasury address.
     */
    event UpdateTreasury(address indexed treasury);

    /**
     * @notice Emitted when the liquidator address is set.
     * @param liquidator The liquidator address.
     */
    event SetLiquidator(address indexed liquidator);

    /**
     * @notice Emitted when the vault address is set.
     * @param vault The vault address.
     */
    event SetVault(address indexed vault);

    /**
     * @notice Emitted when the keeper fee payer address is set.
     * @param keeperFeePayer The keeper fee payer address.
     */
    event SetKeeperFeePayer(address indexed keeperFeePayer);

    /**
     * @notice Emitted when a market is created.
     * @param oracleProvider The address of the oracle provider.
     * @param settlementToken The address of the settlement token.
     * @param market The address of the created market.
     */
    event MarketCreated(
        address indexed oracleProvider,
        address indexed settlementToken,
        address indexed market
    );

    /**
     * @notice Returns the address of the DAO.
     * @return The address of the DAO.
     */
    function dao() external view returns (address);

    /**
     * @notice Returns the address of the DAO treasury.
     * @return The address of the DAO treasury.
     */
    function treasury() external view returns (address);

    /**
     * @notice Returns the address of the liquidator.
     * @return The address of the liquidator.
     */
    function liquidator() external view returns (address);

    /**
     * @notice Returns the address of the vault.
     * @return The address of the vault.
     */
    function vault() external view returns (address);

    /**
     * @notice Returns the address of the keeper fee payer.
     * @return The address of the keeper fee payer.
     */
    function keeperFeePayer() external view returns (address);

    /**
     * @notice Updates the DAO address.
     * @param _dao The new DAO address.
     */
    function updateDao(address _dao) external;

    /**
     * @notice Updates the DAO treasury address.
     * @param _treasury The new DAO treasury address.
     */
    function updateTreasury(address _treasury) external;

    /**
     * @notice Sets the liquidator address.
     * @param _liquidator The liquidator address.
     */
    function setLiquidator(address _liquidator) external;

    /**
     * @notice Sets the vault address.
     * @param _vault The vault address.
     */
    function setVault(address _vault) external;

    /**
     * @notice Sets the keeper fee payer address.
     * @param _keeperFeePayer The keeper fee payer address.
     */
    function setKeeperFeePayer(address _keeperFeePayer) external;

    /**
     * @notice Returns an array of all market addresses.
     * @return markets An array of all market addresses.
     */
    function getMarkets() external view returns (address[] memory markets);

    /**
     * @notice Returns an array of market addresses associated with a settlement token.
     * @param settlementToken The address of the settlement token.
     * @return An array of market addresses.
     */
    function getMarketsBySettlmentToken(
        address settlementToken
    ) external view returns (address[] memory);

    /**
     * @notice Returns the address of a market associated with an oracle provider and settlement token.
     * @param oracleProvider The address of the oracle provider.
     * @param settlementToken The address of the settlement token.
     * @return The address of the market.
     */
    function getMarket(
        address oracleProvider,
        address settlementToken
    ) external view returns (address);

    /**
     * @notice Creates a new market associated with an oracle provider and settlement token.
     * @param oracleProvider The address of the oracle provider.
     * @param settlementToken The address of the settlement token.
     */
    function createMarket(address oracleProvider, address settlementToken) external;

    /**
     * @notice Checks if a market is registered.
     * @param market The address of the market.
     * @return True if the market is registered, false otherwise.
     */
    function isRegisteredMarket(address market) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {ILendingPool} from "@chromatic-protocol/contracts/core/interfaces/vault/ILendingPool.sol";
import {IVault} from "@chromatic-protocol/contracts/core/interfaces/vault/IVault.sol";

/**
 * @title IChromaticVault
 * @notice Interface for the Chromatic Vault contract.
 */
interface IChromaticVault is IVault, ILendingPool {
    /**
     * @dev Emitted when market earning is accumulated.
     * @param market The address of the market.
     * @param earning The amount of earning accumulated.
     */
    event MarketEarningAccumulated(address indexed market, uint256 earning);

    /**
     * @dev Emitted when maker earning is distributed.
     * @param token The address of the settlement token.
     * @param earning The amount of earning distributed.
     * @param usedKeeperFee The amount of keeper fee used.
     */
    event MakerEarningDistributed(
        address indexed token,
        uint256 indexed earning,
        uint256 indexed usedKeeperFee
    );

    /**
     * @dev Emitted when market earning is distributed.
     * @param market The address of the market.
     * @param earning The amount of earning distributed.
     * @param usedKeeperFee The amount of keeper fee used.
     * @param marketBalance The balance of the market.
     */
    event MarketEarningDistributed(
        address indexed market,
        uint256 indexed earning,
        uint256 indexed usedKeeperFee,
        uint256 marketBalance
    );

    /**
     * @notice Creates a maker earning distribution task for a token.
     * @param token The address of the settlement token.
     */
    function createMakerEarningDistributionTask(address token) external;

    /**
     * @notice Cancels a maker earning distribution task for a token.
     * @param token The address of the settlement token.
     */
    function cancelMakerEarningDistributionTask(address token) external;

    /**
     * @notice Creates a market earning distribution task for a market.
     * @param market The address of the market.
     */
    function createMarketEarningDistributionTask(address market) external;

    /**
     * @notice Cancels a market earning distribution task for a market.
     * @param market The address of the market.
     */
    function cancelMarketEarningDistributionTask(address market) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/interfaces/IERC1155MetadataURI.sol";

/**
 * @title ICLBToken
 * @dev Interface for CLBToken contract, which represents Liquidity Bin tokens.
 */
interface ICLBToken is IERC1155, IERC1155MetadataURI {
    /**
     * @dev Total amount of tokens in with a given id.
     * @param id The token ID for which to retrieve the total supply.
     * @return The total supply of tokens for the given token ID.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Total amounts of tokens in with the given ids.
     * @param ids The token IDs for which to retrieve the total supply.
     * @return The total supples of tokens for the given token IDs.
     */
    function totalSupplyBatch(uint256[] memory ids) external view returns (uint256[] memory);

    /**
     * @dev Mints new tokens and assigns them to the specified address.
     * @param to The address to which the minted tokens will be assigned.
     * @param id The token ID to mint.
     * @param amount The amount of tokens to mint.
     * @param data Additional data to pass during the minting process.
     */
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev Burns tokens from a specified address.
     * @param from The address from which to burn tokens.
     * @param id The token ID to burn.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 id, uint256 amount) external;

    /**
     * @dev Retrieves the number of decimals used for token amounts.
     * @return The number of decimals used for token amounts.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Retrieves the name of a token.
     * @param id The token ID for which to retrieve the name.
     * @return The name of the token.
     */
    function name(uint256 id) external view returns (string memory);

    /**
     * @dev Retrieves the description of a token.
     * @param id The token ID for which to retrieve the description.
     * @return The description of the token.
     */
    function description(uint256 id) external view returns (string memory);

    /**
     * @dev Retrieves the image URI of a token.
     * @param id The token ID for which to retrieve the image URI.
     * @return The image URI of the token.
     */
    function image(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IInterestCalculator
 * @dev Interface for an interest calculator contract.
 */
interface IInterestCalculator {
    /**
     * @notice Calculates the interest accrued for a given token and amount within a specified time range.
     * @param token The address of the token.
     * @param amount The amount of the token.
     * @param from The starting timestamp (inclusive) of the time range.
     * @param to The ending timestamp (exclusive) of the time range.
     * @return The accrued interest for the specified token and amount within the given time range.
     */
    function calculateInterest(
        address token,
        uint256 amount,
        uint256 from, // timestamp (inclusive)
        uint256 to // timestamp (exclusive)
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IKeeperFeePayer
 * @dev Interface for a contract that pays keeper fees.
 */
interface IKeeperFeePayer {
    event SetRouter(address indexed);

    /**
     * @notice Approves or revokes approval to the Uniswap router for a given token.
     * @param token The address of the token.
     * @param approve A boolean indicating whether to approve or revoke approval.
     */
    function approveToRouter(address token, bool approve) external;

    /**
     * @notice Pays the keeper fee using Uniswap swaps.
     * @param tokenIn The address of the token being swapped.
     * @param amountOut The desired amount of output tokens.
     * @param keeperAddress The address of the keeper to receive the fee.
     * @return amountIn The actual amount of input tokens used for the swap.
     */
    function payKeeperFee(
        address tokenIn,
        uint256 amountOut,
        address keeperAddress
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";

/**
 * @title IMarketLiquidate
 * @dev Interface for liquidating and claiming positions in a market.
 */
interface IMarketLiquidate {
    /**
     * @dev Emitted when a position is claimed by keeper.
     * @param account The address of the account claiming the position.
     * @param pnl The profit or loss of the claimed position.
     * @param interest The interest paid for the claimed position.
     * @param usedKeeperFee The amount of keeper fee used for the liquidation.
     * @param position The claimed position.
     */
    event ClaimPositionByKeeper(
        address indexed account,
        int256 indexed pnl,
        uint256 indexed interest,
        uint256 usedKeeperFee,
        Position position
    );

    /**
     * @dev Emitted when a position is liquidated.
     * @param account The address of the account being liquidated.
     * @param pnl The profit or loss of the claimed position.
     * @param interest The interest paid for the claimed position.
     * @param usedKeeperFee The amount of keeper fee used for the liquidation.
     * @param position The liquidated position.
     */
    event Liquidate(
        address indexed account,
        int256 indexed pnl,
        uint256 indexed interest,
        uint256 usedKeeperFee,
        Position position
    );

    /**
     * @dev Checks if a position is eligible for liquidation.
     * @param positionId The ID of the position to check.
     * @return A boolean indicating if the position is eligible for liquidation.
     */
    function checkLiquidation(uint256 positionId) external view returns (bool);

    /**
     * @dev Liquidates a position.
     * @param positionId The ID of the position to liquidate.
     * @param keeper The address of the keeper performing the liquidation.
     * @param keeperFee The native token amount of the keeper's fee.
     */
    function liquidate(uint256 positionId, address keeper, uint256 keeperFee) external;

    /**
     * @dev Checks if a position is eligible for claim.
     * @param positionId The ID of the position to check.
     * @return A boolean indicating if the position is eligible for claim.
     */
    function checkClaimPosition(uint256 positionId) external view returns (bool);

    /**
     * @dev Claims a closed position on behalf of a keeper.
     * @param positionId The ID of the position to claim.
     * @param keeper The address of the keeper claiming the position.
     * @param keeperFee The native token amount of the keeper's fee.
     */
    function claimPosition(uint256 positionId, address keeper, uint256 keeperFee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";

/**
 * @title IMarketLiquidity
 * @dev The interface for liquidity operations in a market.
 */
interface IMarketLiquidity {
    /**
     * @dev A struct representing pending liquidity information.
     * @param oracleVersion The oracle version of pending liqudity.
     * @param mintingTokenAmountRequested The amount of settlement tokens requested for minting.
     * @param burningCLBTokenAmountRequested The amount of CLB tokens requested for burning.
     */
    struct PendingLiquidity {
        uint256 oracleVersion;
        uint256 mintingTokenAmountRequested;
        uint256 burningCLBTokenAmountRequested;
    }

    /**
     * @dev A struct representing claimable liquidity information.
     * @param mintingTokenAmountRequested The amount of settlement tokens requested for minting.
     * @param mintingCLBTokenAmount The actual amount of CLB tokens minted.
     * @param burningCLBTokenAmountRequested The amount of CLB tokens requested for burning.
     * @param burningCLBTokenAmount The actual amount of CLB tokens burned.
     * @param burningTokenAmount The amount of settlement tokens equal in value to the burned CLB tokens.
     */
    struct ClaimableLiquidity {
        uint256 mintingTokenAmountRequested;
        uint256 mintingCLBTokenAmount;
        uint256 burningCLBTokenAmountRequested;
        uint256 burningCLBTokenAmount;
        uint256 burningTokenAmount;
    }

    /**
     * @dev A struct representing status of the liquidity bin.
     * @param liquidity The total liquidity amount in the bin
     * @param freeLiquidity The amount of free liquidity available in the bin.
     * @param binValue The current value of the bin.
     * @param tradingFeeRate The trading fee rate for the liquidity.
     */
    struct LiquidityBinStatus {
        uint256 liquidity;
        uint256 freeLiquidity;
        uint256 binValue;
        int16 tradingFeeRate;
    }

    /**
     * @dev Emitted when liquidity is added to the market.
     * @param receipt The liquidity receipt.
     */
    event AddLiquidity(LpReceipt receipt);

    /**
     * @dev Emitted when liquidity is added to the market.
     * @param receipts An array of LP receipts.
     */
    event AddLiquidityBatch(LpReceipt[] receipts);

    /**
     * @dev Emitted when liquidity is claimed from the market.
     * @param clbTokenAmount The amount of CLB tokens claimed.
     * @param receipt The liquidity receipt.
     */
    event ClaimLiquidity(LpReceipt receipt, uint256 indexed clbTokenAmount);

    /**
     * @dev Emitted when liquidity is claimed from the market.
     * @param receipts An array of LP receipts.
     * @param clbTokenAmounts The amount list of CLB tokens claimed.
     */
    event ClaimLiquidityBatch(LpReceipt[] receipts, uint256[] clbTokenAmounts);

    /**
     * @dev Emitted when liquidity is removed from the market.
     * @param receipt The liquidity receipt.
     */
    event RemoveLiquidity(LpReceipt receipt);

    /**
     * @dev Emitted when liquidity is removed from the market.
     * @param receipts An array of LP receipts.
     */
    event RemoveLiquidityBatch(LpReceipt[] receipts);

    /**
     * @dev Emitted when liquidity is withdrawn from the market.
     * @param receipt The liquidity receipt.
     * @param amount The amount of liquidity withdrawn.
     * @param burnedCLBTokenAmount The amount of burned CLB tokens.
     */
    event WithdrawLiquidity(
        LpReceipt receipt,
        uint256 indexed amount,
        uint256 indexed burnedCLBTokenAmount
    );

    /**
     * @dev Emitted when liquidity is withdrawn from the market.
     * @param receipts An array of LP receipts.
     * @param amounts The amount list of liquidity withdrawn.
     * @param burnedCLBTokenAmounts The amount list of burned CLB tokens.
     */
    event WithdrawLiquidityBatch(
        LpReceipt[] receipts,
        uint256[] amounts,
        uint256[] burnedCLBTokenAmounts
    );

    /**
     * @dev Adds liquidity to the market.
     * @param recipient The address to receive the liquidity tokens.
     * @param tradingFeeRate The trading fee rate for the liquidity.
     * @param data Additional data for the liquidity callback.
     * @return The liquidity receipt.
     */
    function addLiquidity(
        address recipient,
        int16 tradingFeeRate,
        bytes calldata data
    ) external returns (LpReceipt memory);

    /**
     * @notice Adds liquidity to multiple liquidity bins of the market in a batch.
     * @param recipient The address of the recipient for each liquidity bin.
     * @param tradingFeeRates An array of fee rates for each liquidity bin.
     * @param amounts An array of amounts to add as liquidity for each bin.
     * @param data Additional data for the liquidity callback.
     * @return An array of LP receipts.
     */
    function addLiquidityBatch(
        address recipient,
        int16[] calldata tradingFeeRates,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (LpReceipt[] memory);

    /**
     * @dev Claims liquidity from a liquidity receipt.
     * @param receiptId The ID of the liquidity receipt.
     * @param data Additional data for the liquidity callback.
     */
    function claimLiquidity(uint256 receiptId, bytes calldata data) external;

    /**
     * @dev Claims liquidity from a liquidity receipt.
     * @param receiptIds The array of the liquidity receipt IDs.
     * @param data Additional data for the liquidity callback.
     */
    function claimLiquidityBatch(uint256[] calldata receiptIds, bytes calldata data) external;

    /**
     * @dev Removes liquidity from the market.
     * @param recipient The address to receive the removed liquidity.
     * @param tradingFeeRate The trading fee rate for the liquidity.
     * @param data Additional data for the liquidity callback.
     * @return The liquidity receipt.
     */
    function removeLiquidity(
        address recipient,
        int16 tradingFeeRate,
        bytes calldata data
    ) external returns (LpReceipt memory);

    /**
     * @dev Removes liquidity from the market.
     * @param recipient The address to receive the removed liquidity.
     * @param tradingFeeRates An array of fee rates for each liquidity bin.
     * @param clbTokenAmounts An array of clb token amounts to remove as liquidity for each bin.
     * @param data Additional data for the liquidity callback.
     * @return The liquidity receipt.
     */
    function removeLiquidityBatch(
        address recipient,
        int16[] calldata tradingFeeRates,
        uint256[] calldata clbTokenAmounts,
        bytes calldata data
    ) external returns (LpReceipt[] memory);

    /**
     * @dev Withdraws liquidity from a liquidity receipt.
     * @param receiptId The ID of the liquidity receipt.
     * @param data Additional data for the liquidity callback.
     */
    function withdrawLiquidity(uint256 receiptId, bytes calldata data) external;

    /**
     * @dev Withdraws liquidity from a liquidity receipt.
     * @param receiptIds The array of the liquidity receipt IDs.
     * @param data Additional data for the liquidity callback.
     */
    function withdrawLiquidityBatch(uint256[] calldata receiptIds, bytes calldata data) external;

    /**
     * @dev Distributes earning to the liquidity bins.
     * @param earning The amount of earning to distribute.
     * @param marketBalance The balance of the market.
     */
    function distributeEarningToBins(uint256 earning, uint256 marketBalance) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";

/**
 * @title IMarketLiquidityLens
 * @dev The interface for liquidity information retrieval in a market.
 */
interface IMarketLiquidityLens {
    /**
     * @dev Retrieves the total liquidity amount for a specific trading fee rate in the liquidity pool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the liquidity amount.
     * @return amount The total liquidity amount for the specified trading fee rate.
     */
    function getBinLiquidity(int16 tradingFeeRate) external view returns (uint256 amount);

    /**
     * @dev Retrieves the available (free) liquidity amount for a specific trading fee rate in the liquidity pool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the available liquidity amount.
     * @return amount The available (free) liquidity amount for the specified trading fee rate.
     */
    function getBinFreeLiquidity(int16 tradingFeeRate) external view returns (uint256 amount);

    /**
     * @dev Retrieves the values of a specific trading fee rate's bins in the liquidity pool.
     *      The value of a bin represents the total valuation of the liquidity in the bin.
     * @param tradingFeeRates The list of trading fee rate for which to retrieve the bin value.
     * @return values The value list of the bins for the specified trading fee rates.
     */
    function getBinValues(
        int16[] memory tradingFeeRates
    ) external view returns (uint256[] memory values);

    /**
     * @dev Retrieves the liquidity receipt with the given receipt ID.
     *      It throws NotExistLpReceipt if the specified receipt ID does not exist.
     * @param receiptId The ID of the liquidity receipt to retrieve.
     * @return receipt The liquidity receipt with the specified ID.
     */
    function getLpReceipt(uint256 receiptId) external view returns (LpReceipt memory);

    /**
     * @dev Retrieves the pending liquidity information for a specific trading fee rate from the associated LiquidityPool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the pending liquidity.
     * @return pendingLiquidity An instance of PendingLiquidity representing the pending liquidity information.
     */
    function pendingLiquidity(
        int16 tradingFeeRate
    ) external view returns (IMarketLiquidity.PendingLiquidity memory);

    /**
     * @dev Retrieves the pending liquidity information for multiple trading fee rates from the associated LiquidityPool.
     * @param tradingFeeRates The list of trading fee rates for which to retrieve the pending liquidity.
     * @return pendingLiquidityBatch An array of PendingLiquidity instances representing the pending liquidity information for each trading fee rate.
     */
    function pendingLiquidityBatch(
        int16[] calldata tradingFeeRates
    ) external view returns (IMarketLiquidity.PendingLiquidity[] memory);

    /**
     * @dev Retrieves the claimable liquidity information for a specific trading fee rate and oracle version from the associated LiquidityPool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the claimable liquidity.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        int16 tradingFeeRate,
        uint256 oracleVersion
    ) external view returns (IMarketLiquidity.ClaimableLiquidity memory);

    /**
     * @dev Retrieves the claimable liquidity information for multiple trading fee rates and a specific oracle version from the associated LiquidityPool.
     * @param tradingFeeRates The list of trading fee rates for which to retrieve the claimable liquidity.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidityBatch An array of ClaimableLiquidity instances representing the claimable liquidity information for each trading fee rate.
     */
    function claimableLiquidityBatch(
        int16[] calldata tradingFeeRates,
        uint256 oracleVersion
    ) external view returns (IMarketLiquidity.ClaimableLiquidity[] memory);

    /**
     * @dev Retrieves the liquidity bin statuses for the caller's liquidity pool.
     * @return statuses An array of LiquidityBinStatus representing the liquidity bin statuses.
     */
    function liquidityBinStatuses()
        external
        view
        returns (IMarketLiquidity.LiquidityBinStatus[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IMarketSettle
 * @dev Interface for market settlement.
 */
interface IMarketSettle {
    /**
     * @notice Executes the settlement process for the Chromatic market.
     * @dev This function is called to settle the market.
     */
    function settle() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IChromaticLiquidator} from "@chromatic-protocol/contracts/core/interfaces/IChromaticLiquidator.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";

/**
 * @title IMarketState
 * @dev Interface for accessing the state of a market contract.
 */
interface IMarketState {
    /**
     * @notice Emitted when the protocol fee is changed by the market
     * @param feeProtocolOld The previous value of the protocol fee
     * @param feeProtocolNew The updated value of the protocol fee
     */
    event SetFeeProtocol(uint8 feeProtocolOld, uint8 feeProtocolNew);

    /**
     * @dev Returns the factory contract for the market.
     * @return The factory contract.
     */
    function factory() external view returns (IChromaticMarketFactory);

    /**
     * @dev Returns the settlement token of the market.
     * @return The settlement token.
     */
    function settlementToken() external view returns (IERC20Metadata);

    /**
     * @dev Returns the oracle provider contract for the market.
     * @return The oracle provider contract.
     */
    function oracleProvider() external view returns (IOracleProvider);

    /**
     * @dev Returns the CLB token contract for the market.
     * @return The CLB token contract.
     */
    function clbToken() external view returns (ICLBToken);

    /**
     * @dev Returns the liquidator contract for the market.
     * @return The liquidator contract.
     */
    function liquidator() external view returns (IChromaticLiquidator);

    /**
     * @dev Returns the vault contract for the market.
     * @return The vault contract.
     */
    function vault() external view returns (IChromaticVault);

    /**
     * @dev Returns the keeper fee payer contract for the market.
     * @return The keeper fee payer contract.
     */
    function keeperFeePayer() external view returns (IKeeperFeePayer);

    /**
     * @notice Returns the denominator of the protocol's % share of the fees
     * @return The protocol fee for the market
     */
    function feeProtocol() external view returns (uint8);

    /**
     * @notice Set the denominator of the protocol's % share of the fees
     * @param _feeProtocol new protocol fee for the market
     */
    function setFeeProtocol(uint8 _feeProtocol) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";

/**
 * @title IMarketTrade
 * @dev Interface for trading positions in a market.
 */
interface IMarketTrade {
    /**
     * @dev Emitted when a position is opened.
     * @param account The address of the account opening the position.
     * @param position The opened position.
     */
    event OpenPosition(address indexed account, Position position);

    /**
     * @dev Emitted when a position is closed.
     * @param account The address of the account closing the position.
     * @param position The closed position.
     */
    event ClosePosition(address indexed account, Position position);

    /**
     * @dev Emitted when a position is claimed.
     * @param account The address of the account claiming the position.
     * @param pnl The profit or loss of the claimed position.
     * @param interest The interest paid for the claimed position.
     * @param position The claimed position.
     */
    event ClaimPosition(
        address indexed account,
        int256 indexed pnl,
        uint256 indexed interest,
        Position position
    );

    /**
     * @dev Emitted when protocol fees are transferred.
     * @param positionId The ID of the position for which the fees are transferred.
     * @param amount The amount of fees transferred.
     */
    event TransferProtocolFee(uint256 indexed positionId, uint256 indexed amount);

    /**
     * @dev Opens a new position in the market.
     * @param qty The quantity of the position.
     * @param takerMargin The margin amount provided by the taker.
     * @param makerMargin The margin amount provided by the maker.
     * @param maxAllowableTradingFee The maximum allowable trading fee for the position.
     * @param data Additional data for the position callback.
     * @return The opened position.
     */
    function openPosition(
        int256 qty,
        uint256 takerMargin,
        uint256 makerMargin,
        uint256 maxAllowableTradingFee,
        bytes calldata data
    ) external returns (Position memory);

    /**
     * @dev Closes a position in the market.
     * @param positionId The ID of the position to close.
     */
    function closePosition(uint256 positionId) external;

    /**
     * @dev Claims a closed position in the market.
     * @param positionId The ID of the position to claim.
     * @param recipient The address of the recipient of the claimed position.
     * @param data Additional data for the claim callback.
     */
    function claimPosition(
        uint256 positionId,
        address recipient, // EOA or account contract
        bytes calldata data
    ) external;

    /**
     * @dev Retrieves multiple positions by their IDs.
     * @param positionIds The IDs of the positions to retrieve.
     * @return positions An array of retrieved positions.
     */
    function getPositions(
        uint256[] calldata positionIds
    ) external view returns (Position[] memory positions);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ILendingPool
 * @dev Interface for a lending pool contract.
 */
interface ILendingPool {
    /**
     * @notice Emitted when a flash loan is executed.
     * @param sender The address initiating the flash loan.
     * @param recipient The address receiving the flash loan.
     * @param amount The amount of the flash loan.
     * @param paid The amount paid back after the flash loan.
     * @param paidToTakerPool The amount paid to the taker pool after the flash loan.
     * @param paidToMakerPool The amount paid to the maker pool after the flash loan.
     */
    event FlashLoan(
        address indexed sender,
        address indexed recipient,
        uint256 indexed amount,
        uint256 paid,
        uint256 paidToTakerPool,
        uint256 paidToMakerPool
    );

    /**
     * @notice Executes a flash loan.
     * @param token The address of the token for the flash loan.
     * @param amount The amount of the flash loan.
     * @param recipient The address to receive the flash loan.
     * @param data Additional data for the flash loan.
     */
    function flashLoan(
        address token,
        uint256 amount,
        address recipient,
        bytes calldata data
    ) external;

    /**
     * @notice Retrieves the pending share of earnings for a specific bin (subset) of funds in a market.
     * @param market The address of the market.
     * @param settlementToken The settlement token address.
     * @param binBalance The balance of funds in the bin.
     * @return The pending share of earnings for the specified bin.
     */
    function getPendingBinShare(
        address market,
        address settlementToken,
        uint256 binBalance
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IVault
 * @dev Interface for the Vault contract, responsible for managing positions and liquidity.
 */
interface IVault {
    /**
     * @notice Emitted when a position is opened.
     * @param market The address of the market.
     * @param positionId The ID of the opened position.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param tradingFee The trading fee associated with the position.
     * @param protocolFee The protocol fee associated with the position.
     */
    event OnOpenPosition(
        address indexed market,
        uint256 indexed positionId,
        uint256 indexed takerMargin,
        uint256 tradingFee,
        uint256 protocolFee
    );

    /**
     * @notice Emitted when a position is claimed.
     * @param market The address of the market.
     * @param positionId The ID of the claimed position.
     * @param recipient The address of the recipient of the settlement amount.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param settlementAmount The settlement amount received by the recipient.
     */
    event OnClaimPosition(
        address indexed market,
        uint256 indexed positionId,
        address indexed recipient,
        uint256 takerMargin,
        uint256 settlementAmount
    );

    /**
     * @notice Emitted when liquidity is added to the vault.
     * @param market The address of the market.
     * @param amount The amount of liquidity added.
     */
    event OnAddLiquidity(address indexed market, uint256 indexed amount);

    /**
     * @notice Emitted when pending liquidity is settled.
     * @param market The address of the market.
     * @param pendingDeposit The amount of pending deposit being settled.
     * @param pendingWithdrawal The amount of pending withdrawal being settled.
     */
    event OnSettlePendingLiquidity(
        address indexed market,
        uint256 indexed pendingDeposit,
        uint256 indexed pendingWithdrawal
    );

    /**
     * @notice Emitted when liquidity is withdrawn from the vault.
     * @param market The address of the market.
     * @param amount The amount of liquidity withdrawn.
     * @param recipient The address of the recipient of the withdrawn liquidity.
     */
    event OnWithdrawLiquidity(
        address indexed market,
        uint256 indexed amount,
        address indexed recipient
    );

    /**
     * @notice Emitted when the keeper fee is transferred.
     * @param fee The amount of the transferred keeper fee as native token.
     * @param amount The amount of settlement token to be used for paying keeper fee.
     */
    event TransferKeeperFee(uint256 indexed fee, uint256 indexed amount);

    /**
     * @notice Emitted when the keeper fee is transferred for a specific market.
     * @param market The address of the market.
     * @param fee The amount of the transferred keeper fee as native token.
     * @param amount The amount of settlement token to be used for paying keeper fee.
     */
    event TransferKeeperFee(address indexed market, uint256 indexed fee, uint256 indexed amount);

    /**
     * @notice Emitted when the protocol fee is transferred for a specific position.
     * @param market The address of the market.
     * @param positionId The ID of the position.
     * @param amount The amount of the transferred fee.
     */
    event TransferProtocolFee(
        address indexed market,
        uint256 indexed positionId,
        uint256 indexed amount
    );

    /**
     * @notice Called when a position is opened by a market contract.
     * @param settlementToken The settlement token address.
     * @param positionId The ID of the opened position.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param tradingFee The trading fee associated with the position.
     * @param protocolFee The protocol fee associated with the position.
     */
    function onOpenPosition(
        address settlementToken,
        uint256 positionId,
        uint256 takerMargin,
        uint256 tradingFee,
        uint256 protocolFee
    ) external;

    /**
     * @notice Called when a position is claimed by a market contract.
     * @param settlementToken The settlement token address.
     * @param positionId The ID of the claimed position.
     * @param recipient The address that will receive the settlement amount.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param settlementAmount The amount to be settled for the position.
     */
    function onClaimPosition(
        address settlementToken,
        uint256 positionId,
        address recipient,
        uint256 takerMargin,
        uint256 settlementAmount
    ) external;

    /**
     * @notice Called when liquidity is added to the vault by a market contract.
     * @param settlementToken The settlement token address.
     * @param amount The amount of liquidity being added.
     */
    function onAddLiquidity(address settlementToken, uint256 amount) external;

    /**
     * @notice Called when pending liquidity is settled in the vault by a market contract.
     * @param settlementToken The settlement token address.
     * @param pendingDeposit The amount of pending deposits being settled.
     * @param pendingWithdrawal The amount of pending withdrawals being settled.
     */
    function onSettlePendingLiquidity(
        address settlementToken,
        uint256 pendingDeposit,
        uint256 pendingWithdrawal
    ) external;

    /**
     * @notice Called when liquidity is withdrawn from the vault by a market contract.
     * @param settlementToken The settlement token address.
     * @param recipient The address that will receive the withdrawn liquidity.
     * @param amount The amount of liquidity to be withdrawn.
     */
    function onWithdrawLiquidity(
        address settlementToken,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Transfers the keeper fee from the market to the specified keeper.
     * @param settlementToken The settlement token address.
     * @param keeper The address of the keeper to receive the fee.
     * @param fee The amount of the fee to transfer as native token.
     * @param margin The margin amount used for the fee payment.
     * @return usedFee The actual settlement token amount of fee used for the transfer.
     */
    function transferKeeperFee(
        address settlementToken,
        address keeper,
        uint256 fee,
        uint256 margin
    ) external returns (uint256 usedFee);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @dev The BinMargin struct represents the margin information for an LP bin.
 * @param tradingFeeRate The trading fee rate associated with the LP bin
 * @param amount The maker margin amount specified for the LP bin
 */
struct BinMargin {
    uint16 tradingFeeRate;
    uint256 amount;
}

using BinMarginLib for BinMargin global;

/**
 * @title BinMarginLib
 * @dev The BinMarginLib library provides functions to operate on BinMargin structs.
 */
library BinMarginLib {
    using Math for uint256;

    uint256 constant TRADING_FEE_RATE_PRECISION = 10000;

    /**
     * @notice Calculates the trading fee based on the margin amount and the trading fee rate.
     * @param self The BinMargin struct
     * @param _feeProtocol The protocol fee for the market
     * @return The trading fee amount
     */
    function tradingFee(BinMargin memory self, uint8 _feeProtocol) internal pure returns (uint256) {
        uint256 _tradingFee = self.amount.mulDiv(self.tradingFeeRate, TRADING_FEE_RATE_PRECISION);
        return _tradingFee - _protocolFee(_tradingFee, _feeProtocol);
    }

    /**
     * @notice Calculates the protocol fee based on the margin amount and the trading fee rate.
     * @param self The BinMargin struct
     * @param _feeProtocol The protocol fee for the market
     * @return The protocol fee amount
     */
    function protocolFee(
        BinMargin memory self,
        uint8 _feeProtocol
    ) internal pure returns (uint256) {
        return
            _protocolFee(
                self.amount.mulDiv(self.tradingFeeRate, TRADING_FEE_RATE_PRECISION),
                _feeProtocol
            );
    }

    function _protocolFee(uint256 _tradingFee, uint8 _feeProtocol) private pure returns (uint256) {
        return _feeProtocol != 0 ? _tradingFee / _feeProtocol : 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {FEE_RATES_LENGTH} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";

/**
 * @title CLBTokenLib
 * @notice Provides utility functions for working with CLB tokens.
 */
library CLBTokenLib {
    using SignedMath for int256;
    using SafeCast for uint256;

    uint256 private constant DIRECTION_PRECISION = 10 ** 10;
    uint16 private constant MIN_FEE_RATE = 1;

    /**
     * @notice Encode the CLB token ID of ERC1155 token type
     * @dev If `tradingFeeRate` is negative, it adds `DIRECTION_PRECISION` to the absolute fee rate.
     *      Otherwise it returns the fee rate directly.
     * @return id The ID of ERC1155 token
     */
    function encodeId(int16 tradingFeeRate) internal pure returns (uint256) {
        bool long = tradingFeeRate > 0;
        return _encodeId(uint16(long ? tradingFeeRate : -tradingFeeRate), long);
    }

    /**
     * @notice Decode the trading fee rate from the CLB token ID of ERC1155 token type
     * @dev If `id` is greater than or equal to `DIRECTION_PRECISION`,
     *      then it substracts `DIRECTION_PRECISION` from `id`
     *      and returns the negation of the substracted value.
     *      Otherwise it returns `id` directly.
     * @return tradingFeeRate The trading fee rate
     */
    function decodeId(uint256 id) internal pure returns (int16 tradingFeeRate) {
        if (id >= DIRECTION_PRECISION) {
            tradingFeeRate = -int16((id - DIRECTION_PRECISION).toUint16());
        } else {
            tradingFeeRate = int16(id.toUint16());
        }
    }

    /**
     * @notice Retrieves the array of supported trading fee rates.
     * @dev This function returns the array of supported trading fee rates,
     *      ranging from the minimum fee rate to the maximum fee rate with step increments.
     * @return tradingFeeRates The array of supported trading fee rates.
     */
    function tradingFeeRates() internal pure returns (uint16[FEE_RATES_LENGTH] memory) {
        // prettier-ignore
        return [
            MIN_FEE_RATE, 2, 3, 4, 5, 6, 7, 8, 9, // 0.01% ~ 0.09%, step 0.01%
            10, 20, 30, 40, 50, 60, 70, 80, 90, // 0.1% ~ 0.9%, step 0.1%
            100, 200, 300, 400, 500, 600, 700, 800, 900, // 1% ~ 9%, step 1%
            1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000 // 10% ~ 50%, step 5%
        ];
    }

    function tokenIds() internal pure returns (uint256[] memory) {
        uint16[FEE_RATES_LENGTH] memory feeRates = tradingFeeRates();

        uint256[] memory ids = new uint256[](FEE_RATES_LENGTH * 2);
        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            ids[i] = _encodeId(feeRates[i], true);
            ids[i + FEE_RATES_LENGTH] = _encodeId(feeRates[i], false);

            unchecked {
                i++;
            }
        }

        return ids;
    }

    function _encodeId(uint16 tradingFeeRate, bool long) private pure returns (uint256 id) {
        id = long ? tradingFeeRate : tradingFeeRate + DIRECTION_PRECISION;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

uint256 constant BPS = 10000;
uint256 constant FEE_RATES_LENGTH = 36;

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Errors
 * @dev This library provides a set of error codes as string constants for handling exceptions and revert messages in the library.
 */
library Errors {
    /**
     * @dev Error code indicating that there is not enough free liquidity available in liquidity pool when open a new poisition.
     */
    string constant NOT_ENOUGH_FREE_LIQUIDITY = "NEFL";

    /**
     * @dev Error code indicating that the specified amount is too small when add liquidity to each bin.
     */
    string constant TOO_SMALL_AMOUNT = "TSA";

    /**
     * @dev Error code indicating that the provided oracle version is invalid or unsupported.
     */
    string constant INVALID_ORACLE_VERSION = "IOV";

    /**
     * @dev Error code indicating that the specified value exceeds the allowed margin range when claim a position.
     */
    string constant EXCEED_MARGIN_RANGE = "IOV";

    /**
     * @dev Error code indicating that the provided trading fee rate is not supported.
     */
    string constant UNSUPPORTED_TRADING_FEE_RATE = "UTFR";

    /**
     * @dev Error code indicating that the oracle provider is already registered.
     */
    string constant ALREADY_REGISTERED_ORACLE_PROVIDER = "ARO";

    /**
     * @dev Error code indicating that the settlement token is already registered.
     */
    string constant ALREADY_REGISTERED_TOKEN = "ART";

    /**
     * @dev Error code indicating that the settlement token is not registered.
     */
    string constant UNREGISTERED_TOKEN = "URT";

    /**
     * @dev Error code indicating that the interest rate has not been initialized.
     */
    string constant INTEREST_RATE_NOT_INITIALIZED = "IRNI";

    /**
     * @dev Error code indicating that the provided interest rate exceeds the maximum allowed rate.
     */
    string constant INTEREST_RATE_OVERFLOW = "IROF";

    /**
     * @dev Error code indicating that the provided timestamp for an interest rate is in the past.
     */
    string constant INTEREST_RATE_PAST_TIMESTAMP = "IRPT";

    /**
     * @dev Error code indicating that the provided interest rate record cannot be appended to the existing array.
     */
    string constant INTEREST_RATE_NOT_APPENDABLE = "IRNA";

    /**
     * @dev Error code indicating that an interest rate has already been applied and cannot be modified further.
     */
    string constant INTEREST_RATE_ALREADY_APPLIED = "IRAA";

    /**
     * @dev Error code indicating that the position is unsettled.
     */
    string constant UNSETTLED_POSITION = "USP";

    /**
     * @dev Error code indicating that the position quantity is invalid.
     */
    string constant INVALID_POSITION_QTY = "IPQ";

    /**
     * @dev Error code indicating that the oracle price is not positive.
     */
    string constant NOT_POSITIVE_PRICE = "NPP";
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {BPS} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title InterestRate
 * @notice Provides functions for managing interest rates.
 * @dev The library allows for the initialization, appending, and removal of interest rate records,
 *      as well as calculating interest based on these records.
 */
library InterestRate {
    using Math for uint256;

    /**
     * @dev Record type
     * @param annualRateBPS Annual interest rate in BPS
     * @param beginTimestamp Timestamp when the interest rate becomes effective
     */
    struct Record {
        uint256 annualRateBPS;
        uint256 beginTimestamp;
    }

    uint256 private constant MAX_RATE_BPS = BPS; // max interest rate is 100%
    uint256 private constant YEAR = 365 * 24 * 3600;

    /**
     * @dev Ensure that the interest rate records have been initialized before certain functions can be called.
     *      It checks whether the length of the Record array is greater than 0.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty (it indicates that the interest rate has not been initialized).
     */
    modifier initialized(Record[] storage self) {
        require(self.length != 0, Errors.INTEREST_RATE_NOT_INITIALIZED);
        _;
    }

    /**
     * @notice Initialize the interest rate records.
     * @param self The stored record array
     * @param initialInterestRate The initial interest rate
     */
    function initialize(Record[] storage self, uint256 initialInterestRate) internal {
        self.push(Record({annualRateBPS: initialInterestRate, beginTimestamp: 0}));
    }

    /**
     * @notice Add a new interest rate record to the array.
     * @dev Annual rate is not greater than the maximum rate and that the begin timestamp is in the future,
     *      and the new record's begin timestamp is greater than the previous record's timestamp.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty.
     *      Throws an error with the code `Errors.INTEREST_RATE_OVERFLOW` if the rate exceed the maximum allowed rate (100%).
     *      Throws an error with the code `Errors.INTEREST_RATE_PAST_TIMESTAMP` if the timestamp is in the past, ensuring that the interest rate period has not already started.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_APPENDABLE` if the timestamp is greater than the last recorded timestamp, ensuring that the new record is appended in chronological order.
     * @param self The stored record array
     * @param annualRateBPS The annual interest rate in BPS
     * @param beginTimestamp Begin timestamp of this record
     */
    function appendRecord(
        Record[] storage self,
        uint256 annualRateBPS,
        uint256 beginTimestamp
    ) internal initialized(self) {
        require(annualRateBPS <= MAX_RATE_BPS, Errors.INTEREST_RATE_OVERFLOW);
        //slither-disable-next-line timestamp
        require(beginTimestamp > block.timestamp, Errors.INTEREST_RATE_PAST_TIMESTAMP);

        Record memory lastRecord = self[self.length - 1];
        require(beginTimestamp > lastRecord.beginTimestamp, Errors.INTEREST_RATE_NOT_APPENDABLE);

        self.push(Record({annualRateBPS: annualRateBPS, beginTimestamp: beginTimestamp}));
    }

    /**
     * @notice Remove the last interest rate record from the array.
     * @dev The current time must be less than the begin timestamp of the last record.
     *      If the array has only one record, it returns false along with an empty record.
     *      Otherwise, it removes the last record from the array and returns true along with the removed record.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty.
     *      Throws an error with the code `Errors.INTEREST_RATE_ALREADY_APPLIED` if the `beginTimestamp` of the last record is not in the future.
     * @param self The stored record array
     * @return removed Whether the last record is removed
     * @return record The removed record
     */
    function removeLastRecord(
        Record[] storage self
    ) internal initialized(self) returns (bool removed, Record memory record) {
        if (self.length <= 1) {
            // empty
            return (false, Record(0, 0));
        }

        Record memory lastRecord = self[self.length - 1];
        //slither-disable-next-line timestamp
        require(block.timestamp < lastRecord.beginTimestamp, Errors.INTEREST_RATE_ALREADY_APPLIED);

        self.pop();

        return (true, lastRecord);
    }

    /**
     * @notice Find the interest rate record that applies to a given timestamp.
     * @dev It iterates through the array from the end to the beginning
     *      and returns the first record with a begin timestamp less than or equal to the provided timestamp.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty.
     * @param self The stored record array
     * @param timestamp Given timestamp
     * @return interestRate The record which is found
     * @return index The index of record
     */
    function findRecordAt(
        Record[] storage self,
        uint256 timestamp
    ) internal view initialized(self) returns (Record memory interestRate, uint256 index) {
        for (uint256 i = self.length; i != 0; ) {
            unchecked {
                index = i - 1;
            }
            interestRate = self[index];

            if (interestRate.beginTimestamp <= timestamp) {
                return (interestRate, index);
            }

            unchecked {
                i--;
            }
        }

        return (self[0], 0); // empty result (this line is not reachable)
    }

    /**
     * @notice Calculate the interest
     * @dev Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty.
     * @param self The stored record array
     * @param amount Token amount
     * @param from Begin timestamp (inclusive)
     * @param to End timestamp (exclusive)
     */
    function calculateInterest(
        Record[] storage self,
        uint256 amount,
        uint256 from, // timestamp (inclusive)
        uint256 to // timestamp (exclusive)
    ) internal view initialized(self) returns (uint256) {
        if (from >= to) {
            return 0;
        }

        uint256 interest = 0;

        uint256 endTimestamp = type(uint256).max;
        for (uint256 idx = self.length; idx != 0; ) {
            Record memory record = self[idx - 1];
            if (endTimestamp <= from) {
                break;
            }

            interest += _interest(
                amount,
                record.annualRateBPS,
                Math.min(to, endTimestamp) - Math.max(from, record.beginTimestamp)
            );
            endTimestamp = record.beginTimestamp;

            unchecked {
                idx--;
            }
        }
        return interest;
    }

    function _interest(
        uint256 amount,
        uint256 rateBPS, // annual rate
        uint256 period // in seconds
    ) private pure returns (uint256) {
        return amount.mulDiv(rateBPS * period, BPS * YEAR, Math.Rounding.Up);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";

/**
 * @dev Structure for tracking accumulated interest
 * @param accumulatedAt The timestamp at which the interest was last accumulated.
 * @param accumulatedAmount The total amount of interest accumulated.
 */
struct AccruedInterest {
    uint256 accumulatedAt;
    uint256 accumulatedAmount;
}

/**
 * @title AccruedInterestLib
 * @notice Tracks the accumulated interest for a given token amount and period of time
 */
library AccruedInterestLib {
    /**
     * @notice Accumulates interest for a given token amount and period of time
     * @param self The AccruedInterest storage
     * @param ctx The LpContext instance for interest calculation
     * @param tokenAmount The amount of tokens to calculate interest for
     * @param until The timestamp until which interest should be accumulated
     */
    function accumulate(
        AccruedInterest storage self,
        LpContext memory ctx,
        uint256 tokenAmount,
        uint256 until
    ) internal {
        uint256 accumulatedAt = self.accumulatedAt;
        // check if the interest is already accumulated for the given period of time.
        if (until <= accumulatedAt) return;

        if (tokenAmount != 0) {
            // calculate the interest for the given period of time and accumulate it
            self.accumulatedAmount += ctx.calculateInterest(tokenAmount, accumulatedAt, until);
        }
        // update the timestamp at which the interest was last accumulated.
        self.accumulatedAt = until;
    }

    /**
     * @notice Deducts interest from the accumulated interest.
     * @param self The AccruedInterest storage.
     * @param amount The amount of interest to deduct.
     */
    function deduct(AccruedInterest storage self, uint256 amount) internal {
        uint256 accumulatedAmount = self.accumulatedAmount;
        // check if the amount is greater than the accumulated interest.
        if (amount >= accumulatedAmount) {
            self.accumulatedAmount = 0;
        } else {
            self.accumulatedAmount = accumulatedAmount - amount;
        }
    }

    /**
     * @notice Calculates the accumulated interest for a given token amount and period of time
     * @param self The AccruedInterest storage
     * @param ctx The LpContext instance for interest calculation
     * @param tokenAmount The amount of tokens to calculate interest for
     * @param until The timestamp until which interest should be accumulated
     * @return The accumulated interest amount
     */
    function calculateInterest(
        AccruedInterest storage self,
        LpContext memory ctx,
        uint256 tokenAmount,
        uint256 until
    ) internal view returns (uint256) {
        if (tokenAmount == 0) return 0;

        uint256 accumulatedAt = self.accumulatedAt;
        uint256 accumulatedAmount = self.accumulatedAmount;
        if (until <= accumulatedAt) return accumulatedAmount;

        return accumulatedAmount + ctx.calculateInterest(tokenAmount, accumulatedAt, until);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {AccruedInterest, AccruedInterestLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/AccruedInterest.sol";
import {BinClosingPosition, BinClosingPositionLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinClosingPosition.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";

/**
 * @dev Represents a closed position within an LiquidityBin.
 */
struct BinClosedPosition {
    uint256 _totalMakerMargin;
    uint256 _totalTakerMargin;
    BinClosingPosition _closing;
    EnumerableSet.UintSet _waitingVersions;
    mapping(uint256 => _ClaimWaitingPosition) _waitingPositions;
    AccruedInterest _accruedInterest;
}

/**
 * @dev Represents the accumulated values of the waiting positions to be claimed
 *      for a specific version within BinClosedPosition.
 */
struct _ClaimWaitingPosition {
    int256 totalQty;
    uint256 totalEntryAmount;
    uint256 totalMakerMargin;
    uint256 totalTakerMargin;
}

/**
 * @title BinClosedPositionLib
 * @notice A library that provides functions to manage the closed position within an LiquidityBin.
 */
library BinClosedPositionLib {
    using EnumerableSet for EnumerableSet.UintSet;
    using AccruedInterestLib for AccruedInterest;
    using BinClosingPositionLib for BinClosingPosition;

    /**
     * @notice Settles the closing position within the BinClosedPosition.
     * @dev If the closeVersion is not set or is equal to the current oracle version, no action is taken.
     *      Otherwise, the waiting position is stored and the accrued interest is accumulated.
     * @param self The BinClosedPosition storage.
     * @param ctx The LpContext memory.
     */
    function settleClosingPosition(BinClosedPosition storage self, LpContext memory ctx) internal {
        uint256 closeVersion = self._closing.closeVersion;
        if (!ctx.isPastVersion(closeVersion)) return;

        _ClaimWaitingPosition memory waitingPosition = _ClaimWaitingPosition({
            totalQty: self._closing.totalQty,
            totalEntryAmount: self._closing.totalEntryAmount,
            totalMakerMargin: self._closing.totalMakerMargin,
            totalTakerMargin: self._closing.totalTakerMargin
        });

        // accumulate interest before update `_totalMakerMargin`
        self._accruedInterest.accumulate(ctx, self._totalMakerMargin, block.timestamp);

        self._totalMakerMargin += waitingPosition.totalMakerMargin;
        self._totalTakerMargin += waitingPosition.totalTakerMargin;
        //slither-disable-next-line unused-return
        self._waitingVersions.add(closeVersion);
        self._waitingPositions[closeVersion] = waitingPosition;

        self._closing.settleAccruedInterest(ctx);
        self._accruedInterest.accumulatedAmount += self._closing.accruedInterest.accumulatedAmount;

        delete self._closing;
    }

    /**
     * @notice Closes the position within the BinClosedPosition.
     * @dev Delegates the onClosePosition function call to the underlying BinClosingPosition.
     * @param self The BinClosedPosition storage.
     * @param ctx The LpContext memory.
     * @param param The PositionParam memory.
     */
    function onClosePosition(
        BinClosedPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        self._closing.onClosePosition(ctx, param);
    }

    /**
     * @notice Claims the position within the BinClosedPosition.
     * @dev If the closeVersion is equal to the BinClosingPosition's closeVersion, the claim is made directly.
     *      Otherwise, the claim is made from the waiting position, and if exhausted, the waiting position is removed.
     *      The accrued interest is accumulated and deducted accordingly.
     * @param self The BinClosedPosition storage.
     * @param ctx The LpContext memory.
     * @param param The PositionParam memory.
     */
    function onClaimPosition(
        BinClosedPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        uint256 closeVersion = param.closeVersion;

        if (closeVersion == self._closing.closeVersion) {
            self._closing.onClaimPosition(ctx, param);
        } else {
            bool exhausted = _onClaimPosition(self._waitingPositions[closeVersion], ctx, param);

            // accumulate interest before update `_totalMakerMargin`
            self._accruedInterest.accumulate(ctx, self._totalMakerMargin, block.timestamp);

            self._totalMakerMargin -= param.makerMargin;
            self._totalTakerMargin -= param.takerMargin;
            self._accruedInterest.deduct(param.calculateInterest(ctx, block.timestamp));

            if (exhausted) {
                //slither-disable-next-line unused-return
                self._waitingVersions.remove(closeVersion);
                delete self._waitingPositions[closeVersion];
            }
        }
    }

    /**
     * @dev Claims the position from the waiting position within the BinClosedPosition.
     *      Updates the waiting position and returns whether the waiting position is exhausted.
     * @param waitingPosition The waiting position storage.
     * @param ctx The LpContext memory.
     * @param param The PositionParam memory.
     * @return exhausted Whether the waiting position is exhausted.
     */
    function _onClaimPosition(
        _ClaimWaitingPosition storage waitingPosition,
        LpContext memory ctx,
        PositionParam memory param
    ) private returns (bool exhausted) {
        int256 totalQty = waitingPosition.totalQty;
        int256 qty = param.qty;
        PositionUtil.checkRemovePositionQty(totalQty, qty);
        if (totalQty == qty) return true;

        waitingPosition.totalQty = totalQty - qty;
        waitingPosition.totalEntryAmount -= param.entryAmount(ctx);
        waitingPosition.totalMakerMargin -= param.makerMargin;
        waitingPosition.totalTakerMargin -= param.takerMargin;

        return false;
    }

    /**
     * @notice Returns the total maker margin for a liquidity bin closed position.
     * @param self The BinClosedPosition storage struct.
     * @return uint256 The total maker margin.
     */
    function totalMakerMargin(BinClosedPosition storage self) internal view returns (uint256) {
        return self._totalMakerMargin + self._closing.totalMakerMargin;
    }

    /**
     * @notice Returns the total taker margin for a liquidity bin closed position.
     * @param self The BinClosedPosition storage struct.
     * @return uint256 The total taker margin.
     */
    function totalTakerMargin(BinClosedPosition storage self) internal view returns (uint256) {
        return self._totalTakerMargin + self._closing.totalTakerMargin;
    }

    /**
     * @dev Calculates the current interest for a liquidity bin closed position.
     * @param self The BinClosedPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return uint256 The current interest.
     */
    function currentInterest(
        BinClosedPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return _currentInterest(self, ctx) + self._closing.currentInterest(ctx);
    }

    /**
     * @dev Calculates the current interest for a liquidity bin closed position without closing position.
     * @param self The BinClosedPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return uint256 The current interest.
     */
    function _currentInterest(
        BinClosedPosition storage self,
        LpContext memory ctx
    ) private view returns (uint256) {
        return
            self._accruedInterest.calculateInterest(ctx, self._totalMakerMargin, block.timestamp);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {AccruedInterest, AccruedInterestLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/AccruedInterest.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @dev Represents the closing position within an LiquidityBin.
 * @param closeVersion The oracle version when the position was closed.
 * @param totalQty The total quantity of the closing position.
 * @param totalEntryAmount The total entry amount of the closing position.
 * @param totalMakerMargin The total maker margin of the closing position.
 * @param totalTakerMargin The total taker margin of the closing position.
 * @param accruedInterest The accumulated interest of the closing position.
 */
struct BinClosingPosition {
    uint256 closeVersion;
    int256 totalQty;
    uint256 totalEntryAmount;
    uint256 totalMakerMargin;
    uint256 totalTakerMargin;
    AccruedInterest accruedInterest;
}

/**
 * @title BinClosingPositionLib
 * @notice A library that provides functions to manage the closing position within an LiquidityBin.
 */
library BinClosingPositionLib {
    using AccruedInterestLib for AccruedInterest;

    /**
     * @notice Settles the accumulated interest of the closing position.
     * @param self The BinClosingPosition storage.
     * @param ctx The LpContext.
     */
    function settleAccruedInterest(BinClosingPosition storage self, LpContext memory ctx) internal {
        self.accruedInterest.accumulate(ctx, self.totalMakerMargin, block.timestamp);
    }

    /**
     * @notice Handles the closing of a position.
     * @dev Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if the `closeVersion` is not valid.
     * @param self The BinClosingPosition storage.
     * @param ctx The LpContext.
     * @param param The position parameters.
     */
    function onClosePosition(
        BinClosingPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        uint256 closeVersion = self.closeVersion;
        require(
            closeVersion == 0 || closeVersion == param.closeVersion,
            Errors.INVALID_ORACLE_VERSION
        );

        int256 totalQty = self.totalQty;
        int256 qty = param.qty;
        PositionUtil.checkAddPositionQty(totalQty, qty);

        // accumulate interest before update `totalMakerMargin`
        settleAccruedInterest(self, ctx);

        self.closeVersion = param.closeVersion;
        self.totalQty = totalQty + qty;
        self.totalEntryAmount += param.entryAmount(ctx);
        self.totalMakerMargin += param.makerMargin;
        self.totalTakerMargin += param.takerMargin;
        self.accruedInterest.accumulatedAmount += param.calculateInterest(ctx, block.timestamp);
    }

    /**
     * @notice Handles the claiming of a position.
     * @dev Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if the `closeVersion` is not valid.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @param param The position parameters.
     */
    function onClaimPosition(
        BinClosingPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        require(self.closeVersion == param.closeVersion, Errors.INVALID_ORACLE_VERSION);

        int256 totalQty = self.totalQty;
        int256 qty = param.qty;
        PositionUtil.checkRemovePositionQty(totalQty, qty);

        // accumulate interest before update `totalMakerMargin`
        settleAccruedInterest(self, ctx);

        self.totalQty = totalQty - qty;
        self.totalEntryAmount -= param.entryAmount(ctx);
        self.totalMakerMargin -= param.makerMargin;
        self.totalTakerMargin -= param.takerMargin;
        self.accruedInterest.deduct(param.calculateInterest(ctx, block.timestamp));
    }

    /**
     * @notice Calculates the current accrued interest of the closing position.
     * @param self The BinClosingPosition storage.
     * @param ctx The LpContext.
     * @return uint256 The current accrued interest.
     */
    function currentInterest(
        BinClosingPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return self.accruedInterest.calculateInterest(ctx, self.totalMakerMargin, block.timestamp);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {DoubleEndedQueue} from "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @dev Represents the liquidity information within an LiquidityBin.
 */
struct BinLiquidity {
    uint256 total;
    IMarketLiquidity.PendingLiquidity _pending;
    mapping(uint256 => _ClaimMinting) _claimMintings;
    mapping(uint256 => _ClaimBurning) _claimBurnings;
    DoubleEndedQueue.Bytes32Deque _burningVersions;
}

/**
 * @dev Represents the accumulated values of minting claims
 *      for a specific oracle version within BinLiquidity.
 */
struct _ClaimMinting {
    uint256 tokenAmountRequested;
    uint256 clbTokenAmount;
}

/**
 * @dev Represents the accumulated values of burning claims
 *      for a specific oracle version within BinLiquidity.
 */
struct _ClaimBurning {
    uint256 clbTokenAmountRequested;
    uint256 clbTokenAmount;
    uint256 tokenAmount;
}

/**
 * @title BinLiquidityLib
 * @notice A library that provides functions to manage the liquidity within an LiquidityBin.
 */
library BinLiquidityLib {
    using Math for uint256;
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;

    /// @dev Minimum amount constant to prevent division by zero.
    uint256 private constant MIN_AMOUNT = 1000;

    /**
     * @notice Settles the pending liquidity within the BinLiquidity.
     * @dev This function settles pending liquidity in the BinLiquidity storage by performing the following steps:
     *      1. Settles pending liquidity
     *          - If the pending oracle version is not set or is greater than or equal to the current oracle version,
     *            no action is taken.
     *          - Otherwise, the pending liquidity and burning CLB tokens are settled by following steps:
     *              a. If there is a pending deposit,
     *                 it calculates the minting amount of CLB tokens
     *                 based on the pending deposit, bin value, and CLB token total supply.
     *                 It updates the total liquidity and adds the pending deposit to the claim mintings.
     *              b. If there is a pending CLB token burning,
     *                 it adds the oracle version to the burning versions list
     *                 and initializes the claim burning details.
     *      2. Settles bunding CLB tokens
     *          a. It trims all completed burning versions from the burning versions list.
     *          b. For each burning version in the list,
     *             it calculates the pending CLB token amount and the pending withdrawal amount
     *             based on the bin value and CLB token total supply.
     *             - If there is sufficient free liquidity, it calculates the burning amount of CLB tokens.
     *             - If there is insufficient free liquidity, it calculates the burning amount
     *               based on the available free liquidity and updates the pending withdrawal accordingly.
     *          c. It updates the burning amount and pending withdrawal,
     *             and reduces the free liquidity accordingly.
     *          d. Finally, it updates the total liquidity by subtracting the pending withdrawal.
     *      And the CLB tokens are minted or burned accordingly.
     *      The pending deposit and withdrawal amounts are passed to the vault for further processing.
     * @param self The BinLiquidity storage.
     * @param ctx The LpContext memory.
     * @param binValue The current value of the bin.
     * @param freeLiquidity The amount of free liquidity available in the bin.
     * @param clbTokenId The ID of the CLB token.
     */
    function settlePendingLiquidity(
        BinLiquidity storage self,
        LpContext memory ctx,
        uint256 binValue,
        uint256 freeLiquidity,
        uint256 clbTokenId
    ) internal {
        ICLBToken clbToken = ctx.clbToken;
        //slither-disable-next-line calls-loop
        uint256 totalSupply = clbToken.totalSupply(clbTokenId);

        (uint256 pendingDeposit, uint256 mintingAmount) = _settlePending(
            self,
            ctx,
            binValue,
            totalSupply
        );
        (uint256 burningAmount, uint256 pendingWithdrawal) = _settleBurning(
            self,
            freeLiquidity + pendingDeposit,
            binValue,
            totalSupply
        );

        if (mintingAmount > burningAmount) {
            //slither-disable-next-line calls-loop
            clbToken.mint(ctx.market, clbTokenId, mintingAmount - burningAmount, bytes(""));
        } else if (mintingAmount < burningAmount) {
            //slither-disable-next-line calls-loop
            clbToken.burn(ctx.market, clbTokenId, burningAmount - mintingAmount);
        }

        if (pendingDeposit != 0 || pendingWithdrawal != 0) {
            //slither-disable-next-line calls-loop
            ctx.vault.onSettlePendingLiquidity(
                ctx.settlementToken,
                pendingDeposit,
                pendingWithdrawal
            );
        }
    }

    /**
     * @notice Adds liquidity to the BinLiquidity.
     * @dev Sets the pending liquidity with the specified amount and oracle version.
     *      Throws an error with the code `Errors.TOO_SMALL_AMOUNT` if the amount is too small.
     *      Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if there is already pending liquidity with a different oracle version, it reverts with an error.
     * @param self The BinLiquidity storage.
     * @param amount The amount of tokens to add for liquidity.
     * @param oracleVersion The oracle version associated with the liquidity.
     */
    function onAddLiquidity(
        BinLiquidity storage self,
        uint256 amount,
        uint256 oracleVersion
    ) internal {
        require(amount > MIN_AMOUNT, Errors.TOO_SMALL_AMOUNT);

        uint256 pendingOracleVersion = self._pending.oracleVersion;
        require(
            pendingOracleVersion == 0 || pendingOracleVersion == oracleVersion,
            Errors.INVALID_ORACLE_VERSION
        );

        self._pending.oracleVersion = oracleVersion;
        self._pending.mintingTokenAmountRequested += amount;
    }

    /**
     * @notice Claims liquidity from the BinLiquidity by minting CLB tokens.
     * @dev Retrieves the minting details for the specified oracle version
     *      and calculates the CLB token amount to be claimed.
     *      Updates the claim minting details and returns the CLB token amount to be claimed.
     *      If there are no more tokens remaining for the claim, it is removed from the mapping.
     * @param self The BinLiquidity storage.
     * @param amount The amount of tokens to claim.
     * @param oracleVersion The oracle version associated with the claim.
     * @return clbTokenAmount The amount of CLB tokens to be claimed.
     */
    function onClaimLiquidity(
        BinLiquidity storage self,
        uint256 amount,
        uint256 oracleVersion
    ) internal returns (uint256 clbTokenAmount) {
        _ClaimMinting memory _cm = self._claimMintings[oracleVersion];
        clbTokenAmount = amount.mulDiv(_cm.clbTokenAmount, _cm.tokenAmountRequested);

        _cm.clbTokenAmount -= clbTokenAmount;
        _cm.tokenAmountRequested -= amount;
        if (_cm.tokenAmountRequested == 0) {
            delete self._claimMintings[oracleVersion];
        } else {
            self._claimMintings[oracleVersion] = _cm;
        }
    }

    /**
     * @notice Removes liquidity from the BinLiquidity by setting pending CLB token amount.
     * @dev Sets the pending liquidity with the specified CLB token amount and oracle version.
     *      Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if there is already pending liquidity with a different oracle version, it reverts with an error.
     * @param self The BinLiquidity storage.
     * @param clbTokenAmount The amount of CLB tokens to remove liquidity.
     * @param oracleVersion The oracle version associated with the liquidity.
     */
    function onRemoveLiquidity(
        BinLiquidity storage self,
        uint256 clbTokenAmount,
        uint256 oracleVersion
    ) internal {
        uint256 pendingOracleVersion = self._pending.oracleVersion;
        require(
            pendingOracleVersion == 0 || pendingOracleVersion == oracleVersion,
            Errors.INVALID_ORACLE_VERSION
        );

        self._pending.oracleVersion = oracleVersion;
        self._pending.burningCLBTokenAmountRequested += clbTokenAmount;
    }

    /**
     * @notice Withdraws liquidity from the BinLiquidity by burning CLB tokens and withdrawing tokens.
     * @dev Retrieves the burning details for the specified oracle version
     *      and calculates the CLB token amount and token amount to burn and withdraw, respectively.
     *      Updates the claim burning details and returns the token amount to withdraw and the burned CLB token amount.
     *      If there are no more CLB tokens remaining for the claim, it is removed from the mapping.
     * @param self The BinLiquidity storage.
     * @param clbTokenAmount The amount of CLB tokens to withdraw.
     * @param oracleVersion The oracle version associated with the claim.
     * @return amount The amount of tokens to be withdrawn for the claim.
     * @return burnedCLBTokenAmount The amount of CLB tokens to be burned for the claim.
     */
    function onWithdrawLiquidity(
        BinLiquidity storage self,
        uint256 clbTokenAmount,
        uint256 oracleVersion
    ) internal returns (uint256 amount, uint256 burnedCLBTokenAmount) {
        _ClaimBurning memory _cb = self._claimBurnings[oracleVersion];
        amount = clbTokenAmount.mulDiv(_cb.tokenAmount, _cb.clbTokenAmountRequested);
        burnedCLBTokenAmount = clbTokenAmount.mulDiv(
            _cb.clbTokenAmount,
            _cb.clbTokenAmountRequested
        );

        _cb.clbTokenAmount -= burnedCLBTokenAmount;
        _cb.tokenAmount -= amount;
        _cb.clbTokenAmountRequested -= clbTokenAmount;
        if (_cb.clbTokenAmountRequested == 0) {
            delete self._claimBurnings[oracleVersion];
        } else {
            self._claimBurnings[oracleVersion] = _cb;
        }
    }

    /**
     * @notice Calculates the amount of CLB tokens to be minted
     *         for a given token amount, bin value, and CLB token total supply.
     * @dev If the CLB token total supply is zero, returns the token amount as is.
     *      Otherwise, calculates the minting amount
     *      based on the token amount, bin value, and CLB token total supply.
     * @param amount The amount of tokens to be minted.
     * @param binValue The current bin value.
     * @param clbTokenTotalSupply The total supply of CLB tokens.
     * @return The amount of CLB tokens to be minted.
     */
    function calculateCLBTokenMinting(
        uint256 amount,
        uint256 binValue,
        uint256 clbTokenTotalSupply
    ) internal pure returns (uint256) {
        return
            clbTokenTotalSupply == 0
                ? amount
                : amount.mulDiv(clbTokenTotalSupply, binValue < MIN_AMOUNT ? MIN_AMOUNT : binValue);
    }

    /**
     * @notice Calculates the value of CLB tokens
     *         for a given CLB token amount, bin value, and CLB token total supply.
     * @dev If the CLB token total supply is zero, returns zero.
     *      Otherwise, calculates the value based on the CLB token amount, bin value, and CLB token total supply.
     * @param clbTokenAmount The amount of CLB tokens.
     * @param binValue The current bin value.
     * @param clbTokenTotalSupply The total supply of CLB tokens.
     * @return The value of the CLB tokens.
     */
    function calculateCLBTokenValue(
        uint256 clbTokenAmount,
        uint256 binValue,
        uint256 clbTokenTotalSupply
    ) internal pure returns (uint256) {
        return clbTokenTotalSupply == 0 ? 0 : clbTokenAmount.mulDiv(binValue, clbTokenTotalSupply);
    }

    /**
     * @dev Settles the pending deposit and pending CLB token burning.
     * @param self The BinLiquidity storage.
     * @param ctx The LpContext.
     * @param binValue The current value of the bin.
     * @param totalSupply The total supply of CLB tokens.
     * @return pendingDeposit The amount of pending deposit to be settled.
     * @return mintingAmount The calculated minting amount of CLB tokens for the pending deposit.
     */
    function _settlePending(
        BinLiquidity storage self,
        LpContext memory ctx,
        uint256 binValue,
        uint256 totalSupply
    ) private returns (uint256 pendingDeposit, uint256 mintingAmount) {
        uint256 oracleVersion = self._pending.oracleVersion;
        if (!ctx.isPastVersion(oracleVersion)) return (0, 0);

        pendingDeposit = self._pending.mintingTokenAmountRequested;
        uint256 pendingCLBTokenAmount = self._pending.burningCLBTokenAmountRequested;

        if (pendingDeposit != 0) {
            mintingAmount = calculateCLBTokenMinting(pendingDeposit, binValue, totalSupply);

            self.total += pendingDeposit;
            self._claimMintings[oracleVersion] = _ClaimMinting({
                tokenAmountRequested: pendingDeposit,
                clbTokenAmount: mintingAmount
            });
        }

        if (pendingCLBTokenAmount != 0) {
            self._burningVersions.pushBack(bytes32(oracleVersion));
            self._claimBurnings[oracleVersion] = _ClaimBurning({
                clbTokenAmountRequested: pendingCLBTokenAmount,
                clbTokenAmount: 0,
                tokenAmount: 0
            });
        }

        delete self._pending;
    }

    /**
     * @dev Settles the pending CLB token burning and calculates the burning amount and pending withdrawal.
     * @param self The BinLiquidity storage.
     * @param freeLiquidity The amount of free liquidity available for burning.
     * @param binValue The current value of the bin.
     * @param totalSupply The total supply of CLB tokens.
     * @return burningAmount The calculated burning amount of CLB tokens.
     * @return pendingWithdrawal The calculated pending withdrawal amount.
     */
    function _settleBurning(
        BinLiquidity storage self,
        uint256 freeLiquidity,
        uint256 binValue,
        uint256 totalSupply
    ) private returns (uint256 burningAmount, uint256 pendingWithdrawal) {
        // trim all claim completed burning versions
        while (!self._burningVersions.empty()) {
            uint256 _ov = uint256(self._burningVersions.front());
            _ClaimBurning memory _cb = self._claimBurnings[_ov];
            if (_cb.clbTokenAmount >= _cb.clbTokenAmountRequested) {
                //slither-disable-next-line unused-return
                self._burningVersions.popFront();
                if (_cb.clbTokenAmountRequested == 0) {
                    delete self._claimBurnings[_ov];
                }
            } else {
                break;
            }
        }

        uint256 length = self._burningVersions.length();
        for (uint256 i; i < length && freeLiquidity != 0; ) {
            uint256 _ov = uint256(self._burningVersions.at(i));
            _ClaimBurning storage _cb = self._claimBurnings[_ov];

            uint256 _pendingCLBTokenAmount = _cb.clbTokenAmountRequested - _cb.clbTokenAmount;
            if (_pendingCLBTokenAmount != 0) {
                uint256 _burningAmount;
                uint256 _pendingWithdrawal = calculateCLBTokenValue(
                    _pendingCLBTokenAmount,
                    binValue,
                    totalSupply
                );

                if (freeLiquidity >= _pendingWithdrawal) {
                    _burningAmount = _pendingCLBTokenAmount;
                } else {
                    _burningAmount = calculateCLBTokenMinting(freeLiquidity, binValue, totalSupply);
                    require(_burningAmount < _pendingCLBTokenAmount);
                    _pendingWithdrawal = freeLiquidity;
                }

                _cb.clbTokenAmount += _burningAmount;
                _cb.tokenAmount += _pendingWithdrawal;
                burningAmount += _burningAmount;
                pendingWithdrawal += _pendingWithdrawal;
                freeLiquidity -= _pendingWithdrawal;
            }

            unchecked {
                i++;
            }
        }

        self.total -= pendingWithdrawal;
    }

    /**
     * @dev Retrieves the pending liquidity information.
     * @param self The reference to the BinLiquidity struct.
     * @return pendingLiquidity An instance of IMarketLiquidity.PendingLiquidity representing the pending liquidity information.
     */
    function pendingLiquidity(
        BinLiquidity storage self
    ) internal view returns (IMarketLiquidity.PendingLiquidity memory) {
        return self._pending;
    }

    /**
     * @dev Retrieves the claimable liquidity information for a specific oracle version.
     * @param self The reference to the BinLiquidity struct.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of IMarketLiquidity.ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        BinLiquidity storage self,
        uint256 oracleVersion
    ) internal view returns (IMarketLiquidity.ClaimableLiquidity memory) {
        _ClaimMinting memory _cm = self._claimMintings[oracleVersion];
        _ClaimBurning memory _cb = self._claimBurnings[oracleVersion];

        return
            IMarketLiquidity.ClaimableLiquidity({
                mintingTokenAmountRequested: _cm.tokenAmountRequested,
                mintingCLBTokenAmount: _cm.clbTokenAmount,
                burningCLBTokenAmountRequested: _cb.clbTokenAmountRequested,
                burningCLBTokenAmount: _cb.clbTokenAmount,
                burningTokenAmount: _cb.tokenAmount
            });
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {AccruedInterest, AccruedInterestLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/AccruedInterest.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @dev Represents a pending position within the LiquidityBin
 * @param openVersion The oracle version when the position was opened.
 * @param totalQty The total quantity of the pending position.
 * @param totalMakerMargin The total maker margin of the pending position.
 * @param totalTakerMargin The total taker margin of the pending position.
 * @param accruedInterest The accumulated interest of the pending position.
 */
struct BinPendingPosition {
    uint256 openVersion;
    int256 totalQty;
    uint256 totalMakerMargin;
    uint256 totalTakerMargin;
    AccruedInterest accruedInterest;
}

/**
 * @title BinPendingPositionLib
 * @notice Library for managing pending positions in the `LiquidityBin`
 */
library BinPendingPositionLib {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;
    using AccruedInterestLib for AccruedInterest;

    /**
     * @notice Settles the accumulated interest of the pending position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     */
    function settleAccruedInterest(BinPendingPosition storage self, LpContext memory ctx) internal {
        self.accruedInterest.accumulate(ctx, self.totalMakerMargin, block.timestamp);
    }

    /**
     * @notice Handles the opening of a position.
     * @dev Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if the `openVersion` is not valid.
     * @param self The BinPendingPosition storage.
     * @param param The position parameters.
     */
    function onOpenPosition(
        BinPendingPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        uint256 openVersion = self.openVersion;
        require(
            openVersion == 0 || openVersion == param.openVersion,
            Errors.INVALID_ORACLE_VERSION
        );

        int256 totalQty = self.totalQty;
        int256 qty = param.qty;
        PositionUtil.checkAddPositionQty(totalQty, qty);

        // accumulate interest before update `totalMakerMargin`
        settleAccruedInterest(self, ctx);

        self.openVersion = param.openVersion;
        self.totalQty = totalQty + qty;
        self.totalMakerMargin += param.makerMargin;
        self.totalTakerMargin += param.takerMargin;
    }

    /**
     * @notice Handles the closing of a position.
     * @dev Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if the `openVersion` is not valid.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @param param The position parameters.
     */
    function onClosePosition(
        BinPendingPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        require(self.openVersion == param.openVersion, Errors.INVALID_ORACLE_VERSION);

        int256 totalQty = self.totalQty;
        int256 qty = param.qty;
        PositionUtil.checkRemovePositionQty(totalQty, qty);

        // accumulate interest before update `totalMakerMargin`
        settleAccruedInterest(self, ctx);

        self.totalQty = totalQty - qty;
        self.totalMakerMargin -= param.makerMargin;
        self.totalTakerMargin -= param.takerMargin;
        self.accruedInterest.deduct(param.calculateInterest(ctx, block.timestamp));
    }

    /**
     * @notice Calculates the unrealized profit or loss (PnL) of the pending position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @return uint256 The unrealized PnL.
     */
    function unrealizedPnl(
        BinPendingPosition storage self,
        LpContext memory ctx
    ) internal view returns (int256) {
        uint256 openVersion = self.openVersion;
        if (!ctx.isPastVersion(openVersion)) return 0;

        IOracleProvider.OracleVersion memory currentVersion = ctx.currentOracleVersion();
        uint256 _entryPrice = PositionUtil.settlePrice(
            ctx.oracleProvider,
            openVersion,
            ctx.currentOracleVersion()
        );
        uint256 _exitPrice = PositionUtil.oraclePrice(currentVersion);

        int256 pnl = PositionUtil.pnl(self.totalQty, _entryPrice, _exitPrice) +
            currentInterest(self, ctx).toInt256();
        uint256 absPnl = pnl.abs();

        //slither-disable-next-line timestamp
        if (pnl >= 0) {
            return Math.min(absPnl, self.totalTakerMargin).toInt256();
        } else {
            return -(Math.min(absPnl, self.totalMakerMargin).toInt256());
        }
    }

    /**
     * @notice Calculates the current accrued interest of the pending position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @return uint256 The current accrued interest.
     */
    function currentInterest(
        BinPendingPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return self.accruedInterest.calculateInterest(ctx, self.totalMakerMargin, block.timestamp);
    }

    /**
     * @notice Calculates the entry price of the pending position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @return uint256 The entry price.
     */
    function entryPrice(
        BinPendingPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return
            PositionUtil.settlePrice(
                ctx.oracleProvider,
                self.openVersion,
                ctx.currentOracleVersion()
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {AccruedInterest, AccruedInterestLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/AccruedInterest.sol";
import {BinPendingPosition, BinPendingPositionLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinPendingPosition.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";

/**
 * @dev Represents a position in the LiquidityBin
 * @param totalQty The total quantity of the `LiquidityBin`
 * @param totalEntryAmount The total entry amount of the `LiquidityBin`
 * @param _totalMakerMargin The total maker margin of the `LiquidityBin`
 * @param _totalTakerMargin The total taker margin of the `LiquidityBin`
 * @param _pending The pending position of the `LiquidityBin`
 * @param _accruedInterest The accumulated interest of the `LiquidityBin`
 */
struct BinPosition {
    int256 totalQty;
    uint256 totalEntryAmount;
    uint256 _totalMakerMargin;
    uint256 _totalTakerMargin;
    BinPendingPosition _pending;
    AccruedInterest _accruedInterest;
}

/**
 * @title BinPositionLib
 * @notice Library for managing positions in the `LiquidityBin`
 */
library BinPositionLib {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;
    using AccruedInterestLib for AccruedInterest;
    using BinPendingPositionLib for BinPendingPosition;

    /**
     * @notice Settles pending positions for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     */
    function settlePendingPosition(BinPosition storage self, LpContext memory ctx) internal {
        uint256 openVersion = self._pending.openVersion;
        if (!ctx.isPastVersion(openVersion)) return;

        // accumulate interest before update `_totalMakerMargin`
        self._accruedInterest.accumulate(ctx, self._totalMakerMargin, block.timestamp);

        int256 pendingQty = self._pending.totalQty;
        self.totalQty += pendingQty;
        self.totalEntryAmount += PositionUtil.transactionAmount(
            pendingQty,
            self._pending.entryPrice(ctx)
        );
        self._totalMakerMargin += self._pending.totalMakerMargin;
        self._totalTakerMargin += self._pending.totalTakerMargin;

        self._pending.settleAccruedInterest(ctx);
        self._accruedInterest.accumulatedAmount += self._pending.accruedInterest.accumulatedAmount;

        delete self._pending;
    }

    /**
     * @notice Handles the opening of a position for a liquidity bin.
     * @param self The BinPosition storage.
     * @param ctx The LpContext data struct.
     * @param param The PositionParam containing the position parameters.
     */
    function onOpenPosition(
        BinPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        self._pending.onOpenPosition(ctx, param);
    }

    /**
     * @notice Handles the closing of a position for a liquidity bin.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     * @param param The PositionParam data struct containing the position parameters.
     */
    function onClosePosition(
        BinPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        if (param.openVersion == self._pending.openVersion) {
            self._pending.onClosePosition(ctx, param);
        } else {
            int256 totalQty = self.totalQty;
            int256 qty = param.qty;
            PositionUtil.checkRemovePositionQty(totalQty, qty);

            // accumulate interest before update `_totalMakerMargin`
            self._accruedInterest.accumulate(ctx, self._totalMakerMargin, block.timestamp);

            self.totalQty = totalQty - qty;
            self.totalEntryAmount -= param.entryAmount(ctx);
            self._totalMakerMargin -= param.makerMargin;
            self._totalTakerMargin -= param.takerMargin;
            self._accruedInterest.deduct(param.calculateInterest(ctx, block.timestamp));
        }
    }

    /**
     * @notice Returns the total maker margin for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @return uint256 The total maker margin.
     */
    function totalMakerMargin(BinPosition storage self) internal view returns (uint256) {
        return self._totalMakerMargin + self._pending.totalMakerMargin;
    }

    /**
     * @notice Returns the total taker margin for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @return uint256 The total taker margin.
     */
    function totalTakerMargin(BinPosition storage self) internal view returns (uint256) {
        return self._totalTakerMargin + self._pending.totalTakerMargin;
    }

    /**
     * @notice Calculates the unrealized profit or loss for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return int256 The unrealized profit or loss.
     */
    function unrealizedPnl(
        BinPosition storage self,
        LpContext memory ctx
    ) internal view returns (int256) {
        IOracleProvider.OracleVersion memory currentVersion = ctx.currentOracleVersion();

        int256 qty = self.totalQty;
        int256 sign = qty < 0 ? int256(-1) : int256(1);
        uint256 exitPrice = PositionUtil.oraclePrice(currentVersion);

        int256 entryAmount = self.totalEntryAmount.toInt256() * sign;
        int256 exitAmount = PositionUtil.transactionAmount(qty, exitPrice).toInt256() * sign;

        int256 rawPnl = exitAmount - entryAmount;
        int256 pnl = rawPnl +
            self._pending.unrealizedPnl(ctx) +
            _currentInterest(self, ctx).toInt256();
        uint256 absPnl = pnl.abs();

        //slither-disable-next-line timestamp
        if (pnl >= 0) {
            return Math.min(absPnl, totalTakerMargin(self)).toInt256();
        } else {
            return -(Math.min(absPnl, totalMakerMargin(self)).toInt256());
        }
    }

    /**
     * @dev Calculates the current interest for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return uint256 The current interest.
     */
    function currentInterest(
        BinPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return _currentInterest(self, ctx) + self._pending.currentInterest(ctx);
    }

    /**
     * @dev Calculates the current interest for a liquidity bin position without pending position.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return uint256 The current interest.
     */
    function _currentInterest(
        BinPosition storage self,
        LpContext memory ctx
    ) private view returns (uint256) {
        return
            self._accruedInterest.calculateInterest(ctx, self._totalMakerMargin, block.timestamp);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {BinLiquidity, BinLiquidityLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinLiquidity.sol";
import {BinPosition, BinPositionLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinPosition.sol";
import {BinClosedPosition, BinClosedPositionLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinClosedPosition.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";
/**
 * @dev Structure representing a liquidity bin
 * @param clbTokenId The ID of the CLB token
 * @param _liquidity The liquidity data for the bin
 * @param _position The position data for the bin
 * @param _closedPosition The closed position data for the bin
 */
struct LiquidityBin {
    uint256 clbTokenId;
    BinLiquidity _liquidity;
    BinPosition _position;
    BinClosedPosition _closedPosition;
}

/**
 * @title LiquidityBinLib
 * @notice Library for managing liquidity bin
 */
library LiquidityBinLib {
    using Math for uint256;
    using SignedMath for int256;
    using LiquidityBinLib for LiquidityBin;
    using BinLiquidityLib for BinLiquidity;
    using BinPositionLib for BinPosition;
    using BinClosedPositionLib for BinClosedPosition;

    /**
     * @notice Modifier to settle the pending positions, closing positions,
     *         and pending liquidity of the bin before executing a function.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext data struct.
     */
    modifier _settle(LiquidityBin storage self, LpContext memory ctx) {
        self.settle(ctx);
        _;
    }

    /**
     * @notice Settles the pending positions, closing positions, and pending liquidity of the bin.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext data struct.
     */
    function settle(LiquidityBin storage self, LpContext memory ctx) internal {
        self._closedPosition.settleClosingPosition(ctx);
        self._position.settlePendingPosition(ctx);
        self._liquidity.settlePendingLiquidity(
            ctx,
            self.value(ctx),
            self.freeLiquidity(),
            self.clbTokenId
        );
    }

    /**
     * @notice Initializes the liquidity bin with the given trading fee rate
     * @param self The LiquidityBin storage
     * @param tradingFeeRate The trading fee rate to set
     */
    function initialize(LiquidityBin storage self, int16 tradingFeeRate) internal {
        self.clbTokenId = CLBTokenLib.encodeId(tradingFeeRate);
    }

    /**
     * @notice Opens a new position in the liquidity bin
     * @dev Throws an error with the code `Errors.NOT_ENOUGH_FREE_LIQUIDITY` if there is not enough free liquidity.
     * @param self The LiquidityBin storage
     * @param ctx The LpContext data struct
     * @param param The position parameters
     * @param tradingFee The trading fee amount
     */
    function openPosition(
        LiquidityBin storage self,
        LpContext memory ctx,
        PositionParam memory param,
        uint256 tradingFee
    ) internal {
        require(param.makerMargin <= self.freeLiquidity(), Errors.NOT_ENOUGH_FREE_LIQUIDITY);

        self._position.onOpenPosition(ctx, param);
        self._liquidity.total += tradingFee;
    }

    /**
     * @notice Closes a position in the liquidity bin
     * @param self The LiquidityBin storage
     * @param ctx The LpContext data struct
     * @param param The position parameters
     */
    function closePosition(
        LiquidityBin storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal _settle(self, ctx) {
        self._position.onClosePosition(ctx, param);
        if (param.closeVersion > param.openVersion) {
            self._closedPosition.onClosePosition(ctx, param);
        }
    }

    /**
     * @notice Claims an existing liquidity position in the bin.
     * @dev This function claims the position using the specified parameters
     *      and updates the total by subtracting the absolute value
     *      of the taker's profit or loss (takerPnl) from it.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param param The PositionParam memory.
     * @param takerPnl The taker's profit/loss.
     */
    function claimPosition(
        LiquidityBin storage self,
        LpContext memory ctx,
        PositionParam memory param,
        int256 takerPnl
    ) internal _settle(self, ctx) {
        if (param.closeVersion == 0) {
            // called when liquidate
            self._position.onClosePosition(ctx, param);
        } else if (param.closeVersion > param.openVersion) {
            self._closedPosition.onClaimPosition(ctx, param);
        }

        uint256 absTakerPnl = takerPnl.abs();
        if (takerPnl < 0) {
            self._liquidity.total += absTakerPnl;
        } else {
            self._liquidity.total -= absTakerPnl;
        }
    }

    /**
     * @notice Retrieves the total liquidity in the bin
     * @param self The LiquidityBin storage
     * @return uint256 The total liquidity in the bin
     */
    function liquidity(LiquidityBin storage self) internal view returns (uint256) {
        return self._liquidity.total;
    }

    /**
     * @notice Retrieves the free liquidity in the bin (liquidity minus total maker margin)
     * @param self The LiquidityBin storage
     * @return uint256 The free liquidity in the bin
     */
    function freeLiquidity(LiquidityBin storage self) internal view returns (uint256) {
        return
            self._liquidity.total -
            self._position.totalMakerMargin() -
            self._closedPosition.totalMakerMargin();
    }

    /**
     * @notice Applies earnings to the liquidity bin
     * @param self The LiquidityBin storage
     * @param earning The earning amount to apply
     */
    function applyEarning(LiquidityBin storage self, uint256 earning) internal {
        self._liquidity.total += earning;
    }

    /**
     * @notice Calculates the value of the bin.
     * @dev This function considers the unrealized profit or loss of the position
     *      and adds it to the total value.
     *      Additionally, it includes the pending bin share from the market's vault.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @return uint256 The value of the bin.
     */
    function value(
        LiquidityBin storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        int256 unrealizedPnl = self._position.unrealizedPnl(ctx);

        uint256 absPnl = unrealizedPnl.abs();

        uint256 _liquidity = self.liquidity();
        uint256 _value = unrealizedPnl < 0 ? _liquidity - absPnl : _liquidity + absPnl;
        return
            _value +
            self._closedPosition.currentInterest(ctx) +
            ctx.vault.getPendingBinShare(ctx.market, ctx.settlementToken, _liquidity);
    }

    /**
     * @notice Accepts an add liquidity request.
     * @dev This function adds liquidity to the bin by calling the `onAddLiquidity` function
     *      of the liquidity component.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param amount The amount of liquidity to add.
     */
    function acceptAddLiquidity(
        LiquidityBin storage self,
        LpContext memory ctx,
        uint256 amount
    ) internal _settle(self, ctx) {
        self._liquidity.onAddLiquidity(amount, ctx.currentOracleVersion().version);
    }

    /**
     * @notice Accepts a claim liquidity request.
     * @dev This function claims liquidity from the bin by calling the `onClaimLiquidity` function
     *      of the liquidity component.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param amount The amount of liquidity to claim.
     *        (should be the same as the one used in acceptAddLiquidity)
     * @param oracleVersion The oracle version used for the claim.
     *        (should be the oracle version when call acceptAddLiquidity)
     * @return The amount of liquidity (CLB tokens) received as a result of the liquidity claim.
     */
    function acceptClaimLiquidity(
        LiquidityBin storage self,
        LpContext memory ctx,
        uint256 amount,
        uint256 oracleVersion
    ) internal _settle(self, ctx) returns (uint256) {
        return self._liquidity.onClaimLiquidity(amount, oracleVersion);
    }

    /**
     * @notice Accepts a remove liquidity request.
     * @dev This function removes liquidity from the bin by calling the `onRemoveLiquidity` function
     *      of the liquidity component.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param clbTokenAmount The amount of CLB tokens to remove.
     */
    function acceptRemoveLiquidity(
        LiquidityBin storage self,
        LpContext memory ctx,
        uint256 clbTokenAmount
    ) internal _settle(self, ctx) {
        self._liquidity.onRemoveLiquidity(clbTokenAmount, ctx.currentOracleVersion().version);
    }

    /**
     * @notice Accepts a withdraw liquidity request.
     * @dev This function withdraws liquidity from the bin by calling the `onWithdrawLiquidity` function
     *      of the liquidity component.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param clbTokenAmount The amount of CLB tokens to withdraw.
     *        (should be the same as the one used in acceptRemoveLiquidity)
     * @param oracleVersion The oracle version used for the withdrawal.
     *        (should be the oracle version when call acceptRemoveLiquidity)
     * @return amount The amount of liquidity withdrawn
     * @return burnedCLBTokenAmount The amount of CLB tokens burned during the withdrawal.
     */
    function acceptWithdrawLiquidity(
        LiquidityBin storage self,
        LpContext memory ctx,
        uint256 clbTokenAmount,
        uint256 oracleVersion
    ) internal _settle(self, ctx) returns (uint256 amount, uint256 burnedCLBTokenAmount) {
        (amount, burnedCLBTokenAmount) = self._liquidity.onWithdrawLiquidity(
            clbTokenAmount,
            oracleVersion
        );
    }

    /**
     * @dev Retrieves the pending liquidity information from a LiquidityBin.
     * @param self The reference to the LiquidityBin struct.
     * @return pendingLiquidity An instance of IMarketLiquidity.PendingLiquidity representing the pending liquidity information.
     */
    function pendingLiquidity(
        LiquidityBin storage self
    ) internal view returns (IMarketLiquidity.PendingLiquidity memory) {
        return self._liquidity.pendingLiquidity();
    }

    /**
     * @dev Retrieves the claimable liquidity information for a specific oracle version from a LiquidityBin.
     * @param self The reference to the LiquidityBin struct.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of IMarketLiquidity.ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        LiquidityBin storage self,
        uint256 oracleVersion
    ) internal view returns (IMarketLiquidity.ClaimableLiquidity memory) {
        return self._liquidity.claimableLiquidity(oracleVersion);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {LiquidityBin, LiquidityBinLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/LiquidityBin.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {FEE_RATES_LENGTH} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";
import {BinMargin} from "@chromatic-protocol/contracts/core/libraries/BinMargin.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @dev Represents a collection of long and short liquidity bins
 */
struct LiquidityPool {
    mapping(uint16 => LiquidityBin) _longBins;
    mapping(uint16 => LiquidityBin) _shortBins;
}

using LiquidityPoolLib for LiquidityPool global;

/**
 * @title LiquidityPoolLib
 * @notice Library for managing liquidity bins in an LiquidityPool
 */
library LiquidityPoolLib {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;
    using LiquidityBinLib for LiquidityBin;

    /**
     * @notice Emitted when earning is accumulated for a liquidity bin.
     * @param feeRate The fee rate of the bin.
     * @param binType The type of the bin ("L" for long, "S" for short).
     * @param earning The accumulated earning.
     */
    event LiquidityBinEarningAccumulated(
        uint16 indexed feeRate,
        bytes1 indexed binType,
        uint256 indexed earning
    );

    struct _proportionalPositionParamValue {
        int256 qty;
        uint256 takerMargin;
    }

    /**
     * @notice Modifier to validate the trading fee rate.
     * @param tradingFeeRate The trading fee rate to validate.
     */
    modifier _validTradingFeeRate(int16 tradingFeeRate) {
        validateTradingFeeRate(tradingFeeRate);

        _;
    }

    /**
     * @notice Initializes the LiquidityPool.
     * @param self The reference to the LiquidityPool.
     */
    function initialize(LiquidityPool storage self) internal {
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();
        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            uint16 feeRate = _tradingFeeRates[i];
            self._longBins[feeRate].initialize(int16(feeRate));
            self._shortBins[feeRate].initialize(-int16(feeRate));

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Settles the liquidity bins in the LiquidityPool.
     * @param self The reference to the LiquidityPool.
     * @param ctx The LpContext object.
     */
    function settle(LiquidityPool storage self, LpContext memory ctx) internal {
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();
        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            uint16 feeRate = _tradingFeeRates[i];
            self._longBins[feeRate].settle(ctx);
            self._shortBins[feeRate].settle(ctx);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Prepares bin margins based on the given quantity and maker margin.
     * @dev This function prepares bin margins by performing the following steps:
     *      1. Calculates the appropriate bin margins
     *         for each trading fee rate based on the provided quantity and maker margin.
     *      2. Iterates through the target bins based on the quantity,
     *         finds the minimum available fee rate,
     *         and determines the upper bound for calculating bin margins.
     *      3. Iterates from the minimum fee rate until the upper bound,
     *         assigning the remaining maker margin to the bins until it is exhausted.
     *      4. Creates an array of BinMargin structs
     *         containing the trading fee rate and corresponding margin amount for each bin.
     *      Throws an error with the code `Errors.NOT_ENOUGH_FREE_LIQUIDITY` if there is not enough free liquidity.
     * @param self The reference to the LiquidityPool.
     * @param ctx The LpContext data struct
     * @param qty The quantity of the position.
     * @param makerMargin The maker margin of the position.
     * @return binMargins An array of BinMargin representing the calculated bin margins.
     */
    function prepareBinMargins(
        LiquidityPool storage self,
        LpContext memory ctx,
        int256 qty,
        uint256 makerMargin,
        uint256 minimumBinMargin
    ) internal returns (BinMargin[] memory) {
        // Retrieve the target liquidity bins based on the position quantity
        mapping(uint16 => LiquidityBin) storage _bins = targetBins(self, qty);

        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();
        //slither-disable-next-line uninitialized-local
        uint256[FEE_RATES_LENGTH] memory _binMargins;

        //slither-disable-next-line uninitialized-local
        uint256 to;
        //slither-disable-next-line uninitialized-local
        uint256 cnt;
        uint256 remain = makerMargin;
        for (; to < FEE_RATES_LENGTH; to++) {
            if (remain == 0) break;

            LiquidityBin storage _bin = _bins[_tradingFeeRates[to]];
            _bin.settle(ctx);

            uint256 freeLiquidity = _bin.freeLiquidity();
            if (freeLiquidity >= minimumBinMargin) {
                if (remain <= freeLiquidity) {
                    _binMargins[to] = remain;
                    remain = 0;
                } else {
                    _binMargins[to] = freeLiquidity;
                    remain -= freeLiquidity;
                }
                cnt++;
            }
        }

        require(remain == 0, Errors.NOT_ENOUGH_FREE_LIQUIDITY);

        BinMargin[] memory binMargins = new BinMargin[](cnt);
        for ((uint256 i, uint256 idx) = (0, 0); i < to; i++) {
            if (_binMargins[i] != 0) {
                binMargins[idx] = BinMargin({
                    tradingFeeRate: _tradingFeeRates[i],
                    amount: _binMargins[i]
                });

                unchecked {
                    idx++;
                }
            }
        }

        return binMargins;
    }

    /**
     * @notice Accepts an open position and opens corresponding liquidity bins.
     * @dev This function calculates the target liquidity bins based on the position quantity.
     *      It prepares the bin margins and divides the position parameters accordingly.
     *      Then, it opens the liquidity bins with the corresponding parameters and trading fees.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param position The Position object representing the open position.
     */
    function acceptOpenPosition(
        LiquidityPool storage self,
        LpContext memory ctx,
        Position memory position
    ) internal {
        // Retrieve the target liquidity bins based on the position quantity
        mapping(uint16 => LiquidityBin) storage _bins = targetBins(self, position.qty);

        uint256 makerMargin = position.makerMargin();
        BinMargin[] memory binMargins = position.binMargins();

        // Divide the position parameters to match the bin margins
        _proportionalPositionParamValue[] memory paramValues = divideToPositionParamValue(
            position.qty,
            makerMargin,
            position.takerMargin,
            binMargins
        );

        PositionParam memory param = newPositionParam(position.openVersion, position.openTimestamp);
        for (uint256 i; i < binMargins.length; ) {
            BinMargin memory binMargin = binMargins[i];

            if (binMargin.amount != 0) {
                param.qty = paramValues[i].qty;
                param.takerMargin = paramValues[i].takerMargin;
                param.makerMargin = binMargin.amount;

                _bins[binMargins[i].tradingFeeRate].openPosition(
                    ctx,
                    param,
                    binMargin.tradingFee(position._feeProtocol)
                );
            }

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Accepts a close position request and closes the corresponding liquidity bins.
     * @dev This function calculates the target liquidity bins based on the position quantity.
     *      It retrieves the maker margin and bin margins from the position.
     *      Then, it divides the position parameters to match the bin margins.
     *      Finally, it closes the liquidity bins with the provided parameters.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param position The Position object representing the close position request.
     */
    function acceptClosePosition(
        LiquidityPool storage self,
        LpContext memory ctx,
        Position memory position
    ) internal {
        // Retrieve the target liquidity bins based on the position quantity
        mapping(uint16 => LiquidityBin) storage _bins = targetBins(self, position.qty);

        uint256 makerMargin = position.makerMargin();
        BinMargin[] memory binMargins = position.binMargins();

        // Divide the position parameters to match the bin margins
        _proportionalPositionParamValue[] memory paramValues = divideToPositionParamValue(
            position.qty,
            makerMargin,
            position.takerMargin,
            binMargins
        );

        PositionParam memory param = newPositionParam(
            position.openVersion,
            position.closeVersion,
            position.openTimestamp,
            position.closeTimestamp
        );

        for (uint256 i; i < binMargins.length; ) {
            if (binMargins[i].amount != 0) {
                LiquidityBin storage _bin = _bins[binMargins[i].tradingFeeRate];

                param.qty = paramValues[i].qty;
                param.takerMargin = paramValues[i].takerMargin;
                param.makerMargin = binMargins[i].amount;

                _bin.closePosition(ctx, param);
            }

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Accepts a claim position request and processes the corresponding liquidity bins
     *         based on the realized position pnl.
     * @dev This function verifies if the absolute value of the realized position pnl is within the acceptable margin range.
     *      It retrieves the target liquidity bins based on the position quantity and the bin margins from the position.
     *      Then, it divides the position parameters to match the bin margins.
     *      Depending on the value of the realized position pnl, it either claims the position fully or partially.
     *      The claimed pnl is distributed among the liquidity bins according to their respective margins.
     *      Throws an error with the code `Errors.EXCEED_MARGIN_RANGE` if the realized profit or loss does not falls within the acceptable margin range.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param position The Position object representing the position to claim.
     * @param realizedPnl The realized position pnl (taker side).
     */
    function acceptClaimPosition(
        LiquidityPool storage self,
        LpContext memory ctx,
        Position memory position,
        int256 realizedPnl // realized position pnl (taker side)
    ) internal {
        uint256 absRealizedPnl = realizedPnl.abs();
        uint256 makerMargin = position.makerMargin();
        // Ensure that the realized position pnl is within the acceptable margin range
        require(
            !((realizedPnl > 0 && absRealizedPnl > makerMargin) ||
                (realizedPnl < 0 && absRealizedPnl > position.takerMargin)),
            Errors.EXCEED_MARGIN_RANGE
        );

        // Retrieve the target liquidity bins based on the position quantity
        mapping(uint16 => LiquidityBin) storage _bins = targetBins(self, position.qty);
        BinMargin[] memory binMargins = position.binMargins();

        // Divide the position parameters to match the bin margins
        _proportionalPositionParamValue[] memory paramValues = divideToPositionParamValue(
            position.qty,
            makerMargin,
            position.takerMargin,
            binMargins
        );

        PositionParam memory param = newPositionParam(
            position.openVersion,
            position.closeVersion,
            position.openTimestamp,
            position.closeTimestamp
        );

        if (realizedPnl == 0) {
            for (uint256 i; i < binMargins.length; ) {
                if (binMargins[i].amount != 0) {
                    LiquidityBin storage _bin = _bins[binMargins[i].tradingFeeRate];

                    param.qty = paramValues[i].qty;
                    param.takerMargin = paramValues[i].takerMargin;
                    param.makerMargin = binMargins[i].amount;

                    _bin.claimPosition(ctx, param, 0);
                }

                unchecked {
                    i++;
                }
            }
        } else if (realizedPnl > 0 && absRealizedPnl == makerMargin) {
            for (uint256 i; i < binMargins.length; ) {
                if (binMargins[i].amount != 0) {
                    LiquidityBin storage _bin = _bins[binMargins[i].tradingFeeRate];

                    param.qty = paramValues[i].qty;
                    param.takerMargin = paramValues[i].takerMargin;
                    param.makerMargin = binMargins[i].amount;

                    _bin.claimPosition(ctx, param, param.makerMargin.toInt256());
                }

                unchecked {
                    i++;
                }
            }
        } else {
            uint256 remainMakerMargin = makerMargin;
            uint256 remainRealizedPnl = absRealizedPnl;

            for (uint256 i; i < binMargins.length; ) {
                if (binMargins[i].amount != 0) {
                    LiquidityBin storage _bin = _bins[binMargins[i].tradingFeeRate];

                    param.qty = paramValues[i].qty;
                    param.takerMargin = paramValues[i].takerMargin;
                    param.makerMargin = binMargins[i].amount;

                    uint256 absTakerPnl = remainRealizedPnl.mulDiv(
                        param.makerMargin,
                        remainMakerMargin
                    );
                    if (realizedPnl < 0) {
                        // maker profit
                        absTakerPnl = Math.min(absTakerPnl, param.takerMargin);
                    } else {
                        // taker profit
                        absTakerPnl = Math.min(absTakerPnl, param.makerMargin);
                    }

                    int256 takerPnl = realizedPnl < 0
                        ? -(absTakerPnl.toInt256())
                        : absTakerPnl.toInt256();

                    _bin.claimPosition(ctx, param, takerPnl);

                    remainMakerMargin -= param.makerMargin;
                    remainRealizedPnl -= absTakerPnl;
                }

                unchecked {
                    i++;
                }
            }

            require(remainRealizedPnl == 0, Errors.EXCEED_MARGIN_RANGE);
        }
    }

    /**
     * @notice Accepts an add liquidity request
     *         and processes the liquidity bin corresponding to the given trading fee rate.
     * @dev This function validates the trading fee rate
     *      and calls the acceptAddLiquidity function on the target liquidity bin.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @param amount The amount of liquidity to add.
     */
    function acceptAddLiquidity(
        LiquidityPool storage self,
        LpContext memory ctx,
        int16 tradingFeeRate,
        uint256 amount
    ) internal _validTradingFeeRate(tradingFeeRate) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Process the add liquidity request on the liquidity bin
        bin.acceptAddLiquidity(ctx, amount);
    }

    /**
     * @notice Accepts a claim liquidity request
     *         and processes the liquidity bin corresponding to the given trading fee rate.
     * @dev This function validates the trading fee rate
     *      and calls the acceptClaimLiquidity function on the target liquidity bin.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @param amount The amount of liquidity to claim.
     *        (should be the same as the one used in acceptAddLiquidity)
     * @param oracleVersion The oracle version used for the claim.
     *        (should be the oracle version when call acceptAddLiquidity)
     * @return The amount of liquidity (CLB tokens) received as a result of the liquidity claim.
     */
    function acceptClaimLiquidity(
        LiquidityPool storage self,
        LpContext memory ctx,
        int16 tradingFeeRate,
        uint256 amount,
        uint256 oracleVersion
    ) internal _validTradingFeeRate(tradingFeeRate) returns (uint256) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Process the claim liquidity request on the liquidity bin and return the actual claimed amount
        return bin.acceptClaimLiquidity(ctx, amount, oracleVersion);
    }

    /**
     * @notice Accepts a remove liquidity request
     *         and processes the liquidity bin corresponding to the given trading fee rate.
     * @dev This function validates the trading fee rate
     *      and calls the acceptRemoveLiquidity function on the target liquidity bin.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @param clbTokenAmount The amount of CLB tokens to remove.
     */
    function acceptRemoveLiquidity(
        LiquidityPool storage self,
        LpContext memory ctx,
        int16 tradingFeeRate,
        uint256 clbTokenAmount
    ) internal _validTradingFeeRate(tradingFeeRate) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Process the remove liquidity request on the liquidity bin
        bin.acceptRemoveLiquidity(ctx, clbTokenAmount);
    }

    /**
     * @notice Accepts a withdraw liquidity request
     *         and processes the liquidity bin corresponding to the given trading fee rate.
     * @dev This function validates the trading fee rate
     *      and calls the acceptWithdrawLiquidity function on the target liquidity bin.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @param clbTokenAmount The amount of CLB tokens to withdraw.
     *        (should be the same as the one used in acceptRemoveLiquidity)
     * @param oracleVersion The oracle version used for the withdrawal.
     *        (should be the oracle version when call acceptRemoveLiquidity)
     * @return amount The amount of base tokens withdrawn
     * @return burnedCLBTokenAmount the amount of CLB tokens burned.
     */
    function acceptWithdrawLiquidity(
        LiquidityPool storage self,
        LpContext memory ctx,
        int16 tradingFeeRate,
        uint256 clbTokenAmount,
        uint256 oracleVersion
    )
        internal
        _validTradingFeeRate(tradingFeeRate)
        returns (uint256 amount, uint256 burnedCLBTokenAmount)
    {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Process the withdraw liquidity request on the liquidity bin
        // and get the amount of base tokens withdrawn and CLB tokens burned
        (amount, burnedCLBTokenAmount) = bin.acceptWithdrawLiquidity(
            ctx,
            clbTokenAmount,
            oracleVersion
        );
    }

    /**
     * @notice Retrieves the total liquidity amount in base tokens for the specified trading fee rate.
     * @dev This function retrieves the liquidity bin based on the trading fee rate
     *      and calls the liquidity function on it.
     * @param self The reference to the LiquidityPool storage.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @return amount The total liquidity amount in base tokens.
     */
    function getBinLiquidity(
        LiquidityPool storage self,
        int16 tradingFeeRate
    ) internal view returns (uint256 amount) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Get the total liquidity amount in base tokens from the liquidity bin
        return bin.liquidity();
    }

    /**
     * @notice Retrieves the free liquidity amount in base tokens for the specified trading fee rate.
     * @dev This function retrieves the liquidity bin based on the trading fee rate
     *      and calls the freeLiquidity function on it.
     * @param self The reference to the LiquidityPool storage.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @return amount The free liquidity amount in base tokens.
     */
    function getBinFreeLiquidity(
        LiquidityPool storage self,
        int16 tradingFeeRate
    ) internal view returns (uint256 amount) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Get the free liquidity amount in base tokens from the liquidity bin
        return bin.freeLiquidity();
    }

    /**
     * @notice Retrieves the target bins based on the sign of the given value.
     * @dev This function retrieves the target bins mapping (short or long) based on the sign of the given value.
     * @param self The storage reference to the LiquidityPool.
     * @param sign The sign of the value (-1 for negative, 1 for positive).
     * @return _bins The target bins mapping associated with the sign of the value.
     */
    function targetBins(
        LiquidityPool storage self,
        int256 sign
    ) private view returns (mapping(uint16 => LiquidityBin) storage) {
        return sign < 0 ? self._shortBins : self._longBins;
    }

    /**
     * @notice Retrieves the target bin based on the trading fee rate.
     * @dev This function retrieves the target bin based on the sign of the trading fee rate and returns it.
     * @param self The storage reference to the LiquidityPool.
     * @param tradingFeeRate The trading fee rate associated with the bin.
     * @return bin The target bin associated with the trading fee rate.
     */
    function targetBin(
        LiquidityPool storage self,
        int16 tradingFeeRate
    ) private view returns (LiquidityBin storage) {
        return
            tradingFeeRate < 0
                ? self._shortBins[abs(tradingFeeRate)]
                : self._longBins[abs(tradingFeeRate)];
    }

    /**
     * @notice Divides the quantity, maker margin, and taker margin into proportional position parameter values.
     * @dev This function divides the quantity, maker margin, and taker margin
     *      into proportional position parameter values based on the bin margins.
     *      It calculates the proportional values for each bin margin and returns them in an array.
     * @param qty The position quantity.
     * @param makerMargin The maker margin amount.
     * @param takerMargin The taker margin amount.
     * @param binMargins The array of bin margins.
     * @return values The array of proportional position parameter values.
     */
    function divideToPositionParamValue(
        int256 qty,
        uint256 makerMargin,
        uint256 takerMargin,
        BinMargin[] memory binMargins
    ) private pure returns (_proportionalPositionParamValue[] memory) {
        uint256 remainQty = qty.abs();
        uint256 remainTakerMargin = takerMargin;

        _proportionalPositionParamValue[] memory values = new _proportionalPositionParamValue[](
            binMargins.length
        );

        for (uint256 i; i < binMargins.length - 1; ) {
            uint256 _qty = remainQty.mulDiv(binMargins[i].amount, makerMargin);
            uint256 _takerMargin = remainTakerMargin.mulDiv(binMargins[i].amount, makerMargin);

            values[i] = _proportionalPositionParamValue({
                qty: qty < 0 ? _qty.toInt256() : -(_qty.toInt256()), // opposit side
                takerMargin: _takerMargin
            });

            remainQty -= _qty;
            remainTakerMargin -= _takerMargin;

            unchecked {
                i++;
            }
        }

        values[binMargins.length - 1] = _proportionalPositionParamValue({
            qty: qty < 0 ? remainQty.toInt256() : -(remainQty.toInt256()), // opposit side
            takerMargin: remainTakerMargin
        });

        return values;
    }

    /**
     * @notice Creates a new PositionParam struct with the given oracle version and timestamp.
     * @param openVersion The version of the oracle when the position was opened
     * @param openTimestamp The timestamp when the position was opened
     * @return param The new PositionParam struct.
     */
    function newPositionParam(
        uint256 openVersion,
        uint256 openTimestamp
    ) private pure returns (PositionParam memory param) {
        param.openVersion = openVersion;
        param.openTimestamp = openTimestamp;
    }

    /**
     * @notice Creates a new PositionParam struct with the given oracle version and timestamp.
     * @param openVersion The version of the oracle when the position was opened
     * @param closeVersion The version of the oracle when the position was closed
     * @param openTimestamp The timestamp when the position was opened
     * @param closeTimestamp The timestamp when the position was closed
     * @return param The new PositionParam struct.
     */
    function newPositionParam(
        uint256 openVersion,
        uint256 closeVersion,
        uint256 openTimestamp,
        uint256 closeTimestamp
    ) private pure returns (PositionParam memory param) {
        param.openVersion = openVersion;
        param.closeVersion = closeVersion;
        param.openTimestamp = openTimestamp;
        param.closeTimestamp = closeTimestamp;
    }

    /**
     * @notice Validates the trading fee rate.
     * @dev This function validates the trading fee rate by checking if it is supported.
     *      It compares the absolute value of the fee rate with the predefined trading fee rates
     *      to determine if it is a valid rate.
     *      Throws an error with the code `Errors.UNSUPPORTED_TRADING_FEE_RATE` if the trading fee rate is not supported.
     * @param tradingFeeRate The trading fee rate to be validated.
     */
    function validateTradingFeeRate(int16 tradingFeeRate) private pure {
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();

        uint16 absFeeRate = abs(tradingFeeRate);

        uint256 idx = findUpperBound(_tradingFeeRates, absFeeRate);
        require(
            idx < _tradingFeeRates.length && absFeeRate == _tradingFeeRates[idx],
            Errors.UNSUPPORTED_TRADING_FEE_RATE
        );
    }

    /**
     * @notice Calculates the absolute value of an int16 number.
     * @param i The int16 number.
     * @return absValue The absolute value of the input number.
     */
    function abs(int16 i) private pure returns (uint16) {
        return i < 0 ? uint16(-i) : uint16(i);
    }

    /**
     * @notice Finds the upper bound index of an element in a sorted array.
     * @dev This function performs a binary search on the sorted array
     *      to find * the index of the upper bound of the given element.
     *      It returns the index as the exclusive upper bound,
     *      or the inclusive upper bound if the element is found at the end of the array.
     * @param array The sorted array.
     * @param element The element to find the upper bound for.
     * @return uint256 The index of the upper bound of the element in the array.
     */
    function findUpperBound(
        uint16[FEE_RATES_LENGTH] memory array,
        uint16 element
    ) private pure returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low != 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @notice Distributes earnings among the liquidity bins.
     * @dev This function distributes the earnings among the liquidity bins,
     *      proportional to their total balances.
     *      It iterates through the trading fee rates
     *      and distributes the proportional amount of earnings to each bin
     *      based on its total balance relative to the market balance.
     * @param self The LiquidityPool storage.
     * @param earning The total earnings to be distributed.
     * @param marketBalance The market balance.
     */
    function distributeEarning(
        LiquidityPool storage self,
        uint256 earning,
        uint256 marketBalance
    ) internal {
        uint256 remainEarning = earning;
        uint256 remainBalance = marketBalance;
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();

        (remainEarning, remainBalance) = distributeEarning(
            self._longBins,
            remainEarning,
            remainBalance,
            _tradingFeeRates,
            "L"
        );
        (remainEarning, remainBalance) = distributeEarning(
            self._shortBins,
            remainEarning,
            remainBalance,
            _tradingFeeRates,
            "S"
        );
    }

    /**
     * @notice Distributes earnings among the liquidity bins of a specific type.
     * @dev This function distributes the earnings among the liquidity bins of
     *      the specified type, proportional to their total balances.
     *      It iterates through the trading fee rates
     *      and distributes the proportional amount of earnings to each bin
     *      based on its total balance relative to the market balance.
     * @param bins The liquidity bins mapping.
     * @param earning The total earnings to be distributed.
     * @param marketBalance The market balance.
     * @param _tradingFeeRates The array of supported trading fee rates.
     * @param binType The type of liquidity bin ("L" for long, "S" for short).
     * @return remainEarning The remaining earnings after distribution.
     * @return remainBalance The remaining market balance after distribution.
     */
    function distributeEarning(
        mapping(uint16 => LiquidityBin) storage bins,
        uint256 earning,
        uint256 marketBalance,
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates,
        bytes1 binType
    ) private returns (uint256 remainEarning, uint256 remainBalance) {
        remainBalance = marketBalance;
        remainEarning = earning;

        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            uint16 feeRate = _tradingFeeRates[i];
            LiquidityBin storage bin = bins[feeRate];
            uint256 binLiquidity = bin.liquidity();

            if (binLiquidity == 0) {
                unchecked {
                    i++;
                }
                continue;
            }

            uint256 binEarning = remainEarning.mulDiv(binLiquidity, remainBalance);

            bin.applyEarning(binEarning);

            remainBalance -= binLiquidity;
            remainEarning -= binEarning;

            emit LiquidityBinEarningAccumulated(feeRate, binType, binEarning);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Retrieves the value of a specific bin in the LiquidityPool storage for the provided trading fee rate.
     * @param self The reference to the LiquidityPool storage.
     * @param _tradingFeeRate The trading fee rate for which to calculate the bin value.
     * @param ctx The LP context containing relevant information for the calculation.
     * @return value The value of the specified bin.
     */
    function binValue(
        LiquidityPool storage self,
        int16 _tradingFeeRate,
        LpContext memory ctx
    ) internal view returns (uint256 value) {
        value = targetBin(self, _tradingFeeRate).value(ctx);
    }

    /**
     * @dev Retrieves the pending liquidity information for a specific trading fee rate from a LiquidityPool.
     * @param self The reference to the LiquidityPool struct.
     * @param tradingFeeRate The trading fee rate for which to retrieve the pending liquidity.
     * @return pendingLiquidity An instance of IMarketLiquidity.PendingLiquidity representing the pending liquidity information.
     */
    function pendingLiquidity(
        LiquidityPool storage self,
        int16 tradingFeeRate
    )
        internal
        view
        _validTradingFeeRate(tradingFeeRate)
        returns (IMarketLiquidity.PendingLiquidity memory)
    {
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        return bin.pendingLiquidity();
    }

    /**
     * @dev Retrieves the claimable liquidity information for a specific trading fee rate and oracle version from a LiquidityPool.
     * @param self The reference to the LiquidityPool struct.
     * @param tradingFeeRate The trading fee rate for which to retrieve the claimable liquidity.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of IMarketLiquidity.ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        LiquidityPool storage self,
        int16 tradingFeeRate,
        uint256 oracleVersion
    )
        internal
        view
        _validTradingFeeRate(tradingFeeRate)
        returns (IMarketLiquidity.ClaimableLiquidity memory)
    {
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        return bin.claimableLiquidity(oracleVersion);
    }

    /**
     * @dev Retrieves the liquidity bin statuses for the LiquidityPool using the provided context.
     * @param self The LiquidityPool storage instance.
     * @param ctx The LpContext containing the necessary context for calculating the bin statuses.
     * @return stats An array of IMarketLiquidity.LiquidityBinStatus representing the liquidity bin statuses.
     */
    function liquidityBinStatuses(
        LiquidityPool storage self,
        LpContext memory ctx
    ) internal view returns (IMarketLiquidity.LiquidityBinStatus[] memory) {
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();

        IMarketLiquidity.LiquidityBinStatus[]
            memory stats = new IMarketLiquidity.LiquidityBinStatus[](FEE_RATES_LENGTH * 2);
        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            uint16 _feeRate = _tradingFeeRates[i];
            LiquidityBin storage longBin = targetBin(self, int16(_feeRate));
            LiquidityBin storage shortBin = targetBin(self, -int16(_feeRate));

            stats[i] = IMarketLiquidity.LiquidityBinStatus({
                tradingFeeRate: int16(_feeRate),
                liquidity: longBin.liquidity(),
                freeLiquidity: longBin.freeLiquidity(),
                binValue: longBin.value(ctx)
            });
            stats[i + FEE_RATES_LENGTH] = IMarketLiquidity.LiquidityBinStatus({
                tradingFeeRate: -int16(_feeRate),
                liquidity: shortBin.liquidity(),
                freeLiquidity: shortBin.freeLiquidity(),
                binValue: shortBin.value(ctx)
            });

            unchecked {
                i++;
            }
        }

        return stats;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";

/**
 * @dev A struct representing the parameters of a position.
 * @param openVersion The version of the position's open transaction
 * @param closeVersion The version of the position's close transaction
 * @param qty The quantity of the position
 * @param takerMargin The margin amount provided by the taker
 * @param makerMargin The margin amount provided by the maker
 * @param openTimestamp The timestamp of the position's open transaction
 * @param closeTimestamp The timestamp of the position's close transaction
 * @param _entryVersionCache Caches the settle oracle version for the position's entry
 * @param _exitVersionCache Caches the settle oracle version for the position's exit
 */
struct PositionParam {
    uint256 openVersion;
    uint256 closeVersion;
    int256 qty;
    uint256 takerMargin;
    uint256 makerMargin;
    uint256 openTimestamp;
    uint256 closeTimestamp;
    IOracleProvider.OracleVersion _entryVersionCache;
    IOracleProvider.OracleVersion _exitVersionCache;
}

using PositionParamLib for PositionParam global;

/**
 * @title PositionParamLib
 * @notice Library for manipulating PositionParam struct.
 */
library PositionParamLib {
    using Math for uint256;
    using SignedMath for int256;

    /**
     * @notice Returns the settle version for the position's entry.
     * @param self The PositionParam struct.
     * @return uint256 The settle version for the position's entry.
     */
    function entryVersion(PositionParam memory self) internal pure returns (uint256) {
        return PositionUtil.settleVersion(self.openVersion);
    }

    /**
     * @notice Calculates the entry price for a PositionParam.
     * @param self The PositionParam struct.
     * @param ctx The LpContext struct.
     * @return uint256 The entry price.
     */
    function entryPrice(
        PositionParam memory self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return
            PositionUtil.settlePrice(
                ctx.oracleProvider,
                self.openVersion,
                self.entryOracleVersion(ctx)
            );
    }

    /**
     * @notice Calculates the entry amount for a PositionParam.
     * @param self The PositionParam struct.
     * @param ctx The LpContext struct.
     * @return uint256 The entry amount.
     */
    function entryAmount(
        PositionParam memory self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return PositionUtil.transactionAmount(self.qty, self.entryPrice(ctx));
    }

    /**
     * @notice Retrieves the settle oracle version for the position's entry.
     * @param self The PositionParam struct.
     * @param ctx The LpContext struct.
     * @return OracleVersion The settle oracle version for the position's entry.
     */
    function entryOracleVersion(
        PositionParam memory self,
        LpContext memory ctx
    ) internal view returns (IOracleProvider.OracleVersion memory) {
        if (self._entryVersionCache.version == 0) {
            self._entryVersionCache = ctx.oracleVersionAt(self.entryVersion());
        }
        return self._entryVersionCache;
    }

    /**
     * @dev Calculates the interest for a PositionParam until a specified timestamp.
     * @dev It is used only to deduct accumulated accrued interest when close position
     * @param self The PositionParam struct.
     * @param ctx The LpContext struct.
     * @param until The timestamp until which to calculate the interest.
     * @return uint256 The calculated interest.
     */
    function calculateInterest(
        PositionParam memory self,
        LpContext memory ctx,
        uint256 until
    ) internal view returns (uint256) {
        return ctx.calculateInterest(self.makerMargin, self.openTimestamp, until);
    }

    /**
     * @notice Creates a clone of a PositionParam.
     * @param self The PositionParam data struct.
     * @return PositionParam The cloned PositionParam.
     */
    function clone(PositionParam memory self) internal pure returns (PositionParam memory) {
        return
            PositionParam({
                openVersion: self.openVersion,
                closeVersion: self.closeVersion,
                qty: self.qty,
                takerMargin: self.takerMargin,
                makerMargin: self.makerMargin,
                openTimestamp: self.openTimestamp,
                closeTimestamp: self.closeTimestamp,
                _entryVersionCache: self._entryVersionCache,
                _exitVersionCache: self._exitVersionCache
            });
    }

    /**
     * @notice Creates the inverse of a PositionParam by negating the qty.
     * @param self The PositionParam data struct.
     * @return PositionParam The inverted PositionParam.
     */
    function inverse(PositionParam memory self) internal pure returns (PositionParam memory) {
        PositionParam memory param = self.clone();
        param.qty *= -1;
        return param;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {IInterestCalculator} from "@chromatic-protocol/contracts/core/interfaces/IInterestCalculator.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";

/**
 * @dev Represents the context information required for LP bin operations.
 * @param oracleProvider The Oracle Provider contract used for price feed
 * @param interestCalculator The Interest Calculator contract used for interest calculations
 * @param vault The Chromatic Vault contract responsible for managing liquidity and margin
 * @param clbToken The CLB token contract that represents LP ownership in the pool
 * @param market The address of market contract
 * @param settlementToken The address of the settlement token used in the market
 * @param tokenPrecision The precision of the settlement token used in the market
 * @param _currentVersionCache Cached instance of the current oracle version
 */
struct LpContext {
    IOracleProvider oracleProvider;
    IInterestCalculator interestCalculator;
    IChromaticVault vault;
    ICLBToken clbToken;
    address market;
    address settlementToken;
    uint256 tokenPrecision;
    IOracleProvider.OracleVersion _currentVersionCache;
}

using LpContextLib for LpContext global;

/**
 * @title LpContextLib
 * @notice Provides functions that operate on the `LpContext` struct
 */
library LpContextLib {
    /**
     * @notice Syncs the oracle version used by the market.
     * @param self The memory instance of `LpContext` struct
     */
    function syncOracleVersion(LpContext memory self) internal {
        self._currentVersionCache = self.oracleProvider.sync();
    }

    /**
     * @notice Retrieves the current oracle version used by the market
     * @dev If the `_currentVersionCache` has been initialized, then returns it.
     *      If not, it calls the `currentVersion` function on the `oracleProvider of the market
     *      to fetch the current version and stores it in the cache,
     *      and then returns the current version.
     * @param self The memory instance of `LpContext` struct
     * @return OracleVersion The current oracle version
     */
    function currentOracleVersion(
        LpContext memory self
    ) internal view returns (IOracleProvider.OracleVersion memory) {
        if (self._currentVersionCache.version == 0) {
            //slither-disable-next-line calls-loop
            self._currentVersionCache = self.oracleProvider.currentVersion();
        }

        return self._currentVersionCache;
    }

    /**
     * @notice Retrieves the oracle version at a specific version number
     * @dev If the `_currentVersionCache` matches the requested version, then returns it.
     *      Otherwise, it calls the `atVersion` function on the `oracleProvider` of the market
     *      to fetch the desired version.
     * @param self The memory instance of `LpContext` struct
     * @param version The requested version number
     * @return OracleVersion The oracle version at the requested version number
     */
    function oracleVersionAt(
        LpContext memory self,
        uint256 version
    ) internal view returns (IOracleProvider.OracleVersion memory) {
        if (self._currentVersionCache.version == version) {
            return self._currentVersionCache;
        }
        return self.oracleProvider.atVersion(version);
    }

    /**
     * @notice Calculates the interest accrued for a given amount of settlement tokens
               within a specified time range.
     * @dev This function internally calls the `calculateInterest` function on the `interestCalculator` contract.
     * @param self The memory instance of the `LpContext` struct.
     * @param amount The amount of settlement tokens for which the interest needs to be calculated.
     * @param from The starting timestamp of the time range (inclusive).
     * @param to The ending timestamp of the time range (exclusive).
     * @return The accrued interest as a `uint256` value.
     */
    function calculateInterest(
        LpContext memory self,
        uint256 amount,
        uint256 from,
        uint256 to
    ) internal view returns (uint256) {
        //slither-disable-next-line calls-loop
        return
            amount == 0 || from >= to
                ? 0
                : self.interestCalculator.calculateInterest(self.settlementToken, amount, from, to);
    }

    /**
     * @notice Checks if an oracle version is in the past.
     * @param self The memory instance of the `LpContext` struct.
     * @param oracleVersion The oracle version to check.
     * @return A boolean value indicating whether the oracle version is in the past.
     */
    function isPastVersion(
        LpContext memory self,
        uint256 oracleVersion
    ) internal view returns (bool) {
        return oracleVersion != 0 && oracleVersion < self.currentOracleVersion().version;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";

/**
 * @dev The LpAction enum represents the types of LP actions that can be performed.
 */
enum LpAction {
    ADD_LIQUIDITY,
    REMOVE_LIQUIDITY
}

/**
 * @dev The LpReceipt struct represents a receipt of an LP action performed.
 * @param id An identifier for the receipt
 * @param oracleVersion The oracle version associated with the action
 * @param amount The amount involved in the action,
 *        when the action is `ADD_LIQUIDITY`, this value represents the amount of settlement tokens
 *        when the action is `REMOVE_LIQUIDITY`, this value represents the amount of CLB tokens
 * @param recipient The address of the recipient of the action
 * @param action An enumeration representing the type of LP action performed (ADD_LIQUIDITY or REMOVE_LIQUIDITY)
 * @param tradingFeeRate The trading fee rate associated with the LP action
 */
struct LpReceipt {
    uint256 id;
    uint256 oracleVersion;
    uint256 amount;
    address recipient;
    LpAction action;
    int16 tradingFeeRate;
}

using LpReceiptLib for LpReceipt global;

/**
 * @title LpReceiptLib
 * @notice Provides functions that operate on the `LpReceipt` struct
 */
library LpReceiptLib {
    /**
     * @notice Computes the ID of the CLBToken contract based on the trading fee rate.
     * @param self The LpReceipt struct.
     * @return The ID of the CLBToken contract.
     */
    function clbTokenId(LpReceipt memory self) internal pure returns (uint256) {
        return CLBTokenLib.encodeId(self.tradingFeeRate);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IChromaticLiquidator} from "@chromatic-protocol/contracts/core/interfaces/IChromaticLiquidator.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";
import {LiquidityPool} from "@chromatic-protocol/contracts/core/libraries/liquidity/LiquidityPool.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {BinMargin} from "@chromatic-protocol/contracts/core/libraries/BinMargin.sol";

struct MarketStorage {
    IChromaticMarketFactory factory;
    IOracleProvider oracleProvider;
    IERC20Metadata settlementToken;
    ICLBToken clbToken;
    IChromaticLiquidator liquidator;
    IChromaticVault vault;
    IKeeperFeePayer keeperFeePayer;
    LiquidityPool liquidityPool;
    uint8 feeProtocol;
}

struct LpReceiptStorage {
    uint256 lpReceiptId;
    mapping(uint256 => LpReceipt) lpReceipts;
}

struct PositionStorage {
    uint256 positionId;
    mapping(uint256 => Position) positions;
}

library MarketStorageLib {
    bytes32 constant MARKET_STORAGE_POSITION = keccak256("protocol.chromatic.market.storage");

    function marketStorage() internal pure returns (MarketStorage storage ms) {
        bytes32 position = MARKET_STORAGE_POSITION;
        assembly {
            ms.slot := position
        }
    }
}

using LpReceiptStorageLib for LpReceiptStorage global;

library LpReceiptStorageLib {
    bytes32 constant LP_RECEIPT_STORAGE_POSITION =
        keccak256("protocol.chromatic.lpreceipt.storage");

    function lpReceiptStorage() internal pure returns (LpReceiptStorage storage ls) {
        bytes32 position = LP_RECEIPT_STORAGE_POSITION;
        assembly {
            ls.slot := position
        }
    }

    function nextId(LpReceiptStorage storage self) internal returns (uint256 id) {
        id = ++self.lpReceiptId;
    }

    function setReceipt(LpReceiptStorage storage self, LpReceipt memory receipt) internal {
        self.lpReceipts[receipt.id] = receipt;
    }

    function getReceipt(
        LpReceiptStorage storage self,
        uint256 receiptId
    ) internal view returns (LpReceipt memory receipt) {
        receipt = self.lpReceipts[receiptId];
    }

    function deleteReceipt(LpReceiptStorage storage self, uint256 receiptId) internal {
        delete self.lpReceipts[receiptId];
    }

    function deleteReceipts(LpReceiptStorage storage self, uint256[] memory receiptIds) internal {
        for (uint256 i; i < receiptIds.length; ) {
            delete self.lpReceipts[receiptIds[i]];

            unchecked {
                i++;
            }
        }
    }
}

using PositionStorageLib for PositionStorage global;

library PositionStorageLib {
    bytes32 constant POSITION_STORAGE_POSITION = keccak256("protocol.chromatic.position.storage");

    function positionStorage() internal pure returns (PositionStorage storage ls) {
        bytes32 position = POSITION_STORAGE_POSITION;
        assembly {
            ls.slot := position
        }
    }

    function nextId(PositionStorage storage self) internal returns (uint256 id) {
        id = ++self.positionId;
    }

    function setPosition(PositionStorage storage self, Position memory position) internal {
        Position storage _p = self.positions[position.id];

        _p.id = position.id;
        _p.openVersion = position.openVersion;
        _p.closeVersion = position.closeVersion;
        _p.qty = position.qty;
        _p.openTimestamp = position.openTimestamp;
        _p.closeTimestamp = position.closeTimestamp;
        _p.takerMargin = position.takerMargin;
        _p.owner = position.owner;
        _p._feeProtocol = position._feeProtocol;
        // can not convert memory array to storage array
        delete _p._binMargins;
        for (uint i; i < position._binMargins.length; ) {
            BinMargin memory binMargin = position._binMargins[i];
            if (binMargin.amount != 0) {
                _p._binMargins.push(position._binMargins[i]);
            }

            unchecked {
                i++;
            }
        }
    }

    function getPosition(
        PositionStorage storage self,
        uint256 positionId
    ) internal view returns (Position memory position) {
        position = self.positions[positionId];
    }

    function getStoragePosition(
        PositionStorage storage self,
        uint256 positionId
    ) internal view returns (Position storage position) {
        position = self.positions[positionId];
    }

    function deletePosition(PositionStorage storage self, uint256 positionId) internal {
        delete self.positions[positionId];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {BinMargin} from "@chromatic-protocol/contracts/core/libraries/BinMargin.sol";

/**
 * @dev The Position struct represents a trading position.
 * @param id The position identifier
 * @param openVersion The version of the oracle when the position was opened
 * @param closeVersion The version of the oracle when the position was closed
 * @param qty The quantity of the position
 * @param openTimestamp The timestamp when the position was opened
 * @param closeTimestamp The timestamp when the position was closed
 * @param takerMargin The amount of collateral that a trader must provide
 * @param owner The owner of the position, usually it is the account address of trader
 * @param _binMargins The bin margins for the position, it represents the amount of collateral for each bin
 * @param _feeProtocol The protocol fee for the market
 */
struct Position {
    uint256 id;
    uint256 openVersion;
    uint256 closeVersion;
    int256 qty;
    uint256 openTimestamp;
    uint256 closeTimestamp;
    uint256 takerMargin;
    address owner;
    BinMargin[] _binMargins;
    uint8 _feeProtocol;
}

using PositionLib for Position global;

/**
 * @title PositionLib
 * @notice Provides functions that operate on the `Position` struct
 */
library PositionLib {
    // using Math for uint256;
    // using SafeCast for uint256;
    // using SignedMath for int256;

    /**
     * @notice Calculates the entry price of the position based on the position's open oracle version
     * @dev It fetches oracle price from `IOracleProvider`
     *      at the settle version calculated based on the position's open oracle version
     * @param self The memory instance of the `Position` struct
     * @param ctx The context object for this transaction
     * @return uint256 The entry price
     */
    function entryPrice(
        Position memory self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return PositionUtil.settlePrice(ctx.oracleProvider, self.openVersion);
    }

    /**
     * @notice Calculates the exit price of the position based on the position's close oracle version
     * @dev It fetches oracle price from `IOracleProvider`
     *      at the settle version calculated based on the position's close oracle version
     * @param self The memory instance of the `Position` struct
     * @param ctx The context object for this transaction
     * @return uint256 The exit price
     */
    function exitPrice(Position memory self, LpContext memory ctx) internal view returns (uint256) {
        return PositionUtil.settlePrice(ctx.oracleProvider, self.closeVersion);
    }

    /**
     * @notice Calculates the profit or loss of the position based on the close oracle version and the qty
     * @param self The memory instance of the `Position` struct
     * @param ctx The context object for this transaction
     * @return int256 The profit or loss
     */
    function pnl(Position memory self, LpContext memory ctx) internal view returns (int256) {
        return
            self.closeVersion > self.openVersion
                ? PositionUtil.pnl(self.qty, self.entryPrice(ctx), self.exitPrice(ctx))
                : int256(0);
    }

    /**
     * @notice Calculates the total margin required for the makers of the position
     * @dev The maker margin is calculated by summing up the amounts of all bin margins
     *      in the `_binMargins` array
     * @param self The memory instance of the `Position` struct
     * @return margin The maker margin
     */
    function makerMargin(Position memory self) internal pure returns (uint256 margin) {
        for (uint256 i; i < self._binMargins.length; ) {
            margin += self._binMargins[i].amount;

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Calculates the total trading fee for the position
     * @dev The trading fee is calculated by summing up the trading fees of all bin margins
     *      in the `_binMargins` array
     * @param self The memory instance of the `Position` struct
     * @return fee The trading fee
     */
    function tradingFee(Position memory self) internal pure returns (uint256 fee) {
        for (uint256 i; i < self._binMargins.length; ) {
            fee += self._binMargins[i].tradingFee(self._feeProtocol);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Calculates the total protocol fee for a position.
     * @param self The Position struct representing the position.
     * @return fee The total protocol fee amount.
     */
    function protocolFee(Position memory self) internal pure returns (uint256 fee) {
        for (uint256 i; i < self._binMargins.length; ) {
            fee += self._binMargins[i].protocolFee(self._feeProtocol);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Returns an array of BinMargin instances
     *         representing the bin margins for the position
     * @param self The memory instance of the `Position` struct
     * @return margins The bin margins for the position
     */
    function binMargins(Position memory self) internal pure returns (BinMargin[] memory margins) {
        margins = self._binMargins;
    }

    /**
     * @notice Sets the `_binMargins` array for the position
     * @param self The memory instance of the `Position` struct
     * @param margins The bin margins for the position
     */
    function setBinMargins(Position memory self, BinMargin[] memory margins) internal pure {
        self._binMargins = margins;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title PositionUtil
 * @notice Provides utility functions for managing positions
 */
library PositionUtil {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;

    uint256 private constant PRICE_PRECISION = 1e18;

    /**
     * @notice Returns next oracle version to settle
     * @dev It adds 1 to the `oracleVersion`
     *      and ensures that the `oracleVersion` is greater than 0 using a require statement.
     *      Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if the `oracleVersion` is not valid.
     * @param oracleVersion Input oracle version
     * @return uint256 Next oracle version to settle
     */
    function settleVersion(uint256 oracleVersion) internal pure returns (uint256) {
        require(oracleVersion != 0, Errors.INVALID_ORACLE_VERSION);
        return oracleVersion + 1;
    }

    /**
     * @notice Calculates the price of the position based on the `oracleVersion` to settle
     * @dev It calls another overloaded `settlePrice` function
     *      with an additional `OracleVersion` parameter,
     *      passing the `currentVersion` obtained from the `provider`
     * @param provider The oracle provider
     * @param oracleVersion The oracle version of position
     * @return uint256 The calculated price to settle
     */
    function settlePrice(
        IOracleProvider provider,
        uint256 oracleVersion
    ) internal view returns (uint256) {
        return settlePrice(provider, oracleVersion, provider.currentVersion());
    }

    /**
     * @notice Calculates the price of the position based on the `oracleVersion` to settle
     * @dev It calculates the price by considering the `settleVersion`
     *      and the `currentVersion` obtained from the `IOracleProvider`.
     *      It ensures that the settle version is not greater than the current version;
     *      otherwise, it triggers an error with the message `Errors.UNSETTLED_POSITION`.
     *      It retrieves the corresponding `OracleVersion` using `atVersion` from the `IOracleProvider`,
     *      and then calls `oraclePrice` to obtain the price.
     * @param provider The oracle provider
     * @param oracleVersion The oracle version of position
     * @param currentVersion The current oracle version
     * @return uint256 The calculated entry price to settle
     */
    function settlePrice(
        IOracleProvider provider,
        uint256 oracleVersion,
        IOracleProvider.OracleVersion memory currentVersion
    ) internal view returns (uint256) {
        uint256 _settleVersion = settleVersion(oracleVersion);
        require(_settleVersion <= currentVersion.version, Errors.UNSETTLED_POSITION);

        //slither-disable-next-line calls-loop
        IOracleProvider.OracleVersion memory _oracleVersion = _settleVersion ==
            currentVersion.version
            ? currentVersion
            : provider.atVersion(_settleVersion);
        return oraclePrice(_oracleVersion);
    }

    /**
     * @notice Extracts the price value from an `OracleVersion` struct
     * @dev If the price is not positive value, it triggers an error with the message `Errors.NOT_POSITIVE_PRICE`.
     * @param oracleVersion The memory instance of `OracleVersion` struct
     * @return uint256 The price value of `oracleVersion`
     */
    function oraclePrice(
        IOracleProvider.OracleVersion memory oracleVersion
    ) internal pure returns (uint256) {
        require(oracleVersion.price > 0, Errors.NOT_POSITIVE_PRICE);
        return oracleVersion.price.abs();
    }

    /**
     * @notice Calculates the profit or loss (PnL) for a position based on the quantity, entry price, and exit price
     * @dev It first calculates the price difference (`delta`) between the exit price and the entry price.
     *      If the quantity is negative, indicating short position, it adjusts the `delta` to reflect a negative change.
     *      The function then calculates the absolute PnL by multiplying the absolute value of the quantity
     *          with the absolute value of the `delta`, divided by the entry price.
     *      Finally, if `delta` is negative, indicating a loss, the absolute PnL is negated to represent a negative value.
     * @param qty The quantity of the position
     * @param _entryPrice The entry price of the position
     * @param _exitPrice The exit price of the position
     * @return int256 The profit or loss
     */
    function pnl(
        int256 qty, // as token precision
        uint256 _entryPrice,
        uint256 _exitPrice
    ) internal pure returns (int256) {
        int256 delta = _exitPrice > _entryPrice
            ? (_exitPrice - _entryPrice).toInt256()
            : -(_entryPrice - _exitPrice).toInt256();
        if (qty < 0) delta *= -1;

        int256 absPnl = qty.abs().mulDiv(delta.abs(), _entryPrice).toInt256();

        return delta < 0 ? -absPnl : absPnl;
    }

    /**
     * @notice Verifies the validity of a position quantity added to the bin
     * @dev It ensures that the sign of the current quantity of the bin's position
     *      and the added quantity are same or zero.
     *      If the condition is not met, it triggers an error with the message `Errors.INVALID_POSITION_QTY`.
     * @param currentQty The current quantity of the bin's pending position
     * @param addedQty The position quantity added
     */
    function checkAddPositionQty(int256 currentQty, int256 addedQty) internal pure {
        require(
            !((currentQty > 0 && addedQty <= 0) || (currentQty < 0 && addedQty >= 0)),
            Errors.INVALID_POSITION_QTY
        );
    }

    /**
     * @notice Verifies the validity of a position quantity removed from the bin
     * @dev It ensures that the sign of the current quantity of the bin's position
     *      and the removed quantity are same or zero,
     *      and the absolute removed quantity is not greater than the absolute current quantity.
     *      If the condition is not met, it triggers an error with the message `Errors.INVALID_POSITION_QTY`.
     * @param currentQty The current quantity of the bin's position
     * @param removeQty The position quantity removed
     */
    function checkRemovePositionQty(int256 currentQty, int256 removeQty) internal pure {
        require(
            !((currentQty == 0) ||
                (removeQty == 0) ||
                (currentQty > 0 && removeQty > currentQty) ||
                (currentQty < 0 && removeQty < currentQty)),
            Errors.INVALID_POSITION_QTY
        );
    }

    /**
     * @notice Calculates the transaction amount based on the quantity and price
     * @param qty The quantity of the position
     * @param price The price of the position
     * @return uint256 The transaction amount
     */
    function transactionAmount(int256 qty, uint256 price) internal pure returns (uint256) {
        return qty.abs().mulDiv(price, PRICE_PRECISION);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

interface IOracleProvider {
    /// @dev Error for invalid oracle round
    error InvalidOracleRound();

    /**
     * @dev A singular oracle version with its corresponding data
     * @param version The iterative version
     * @param timestamp the timestamp of the oracle update
     * @param price The oracle price of the corresponding version
     */
    struct OracleVersion {
        uint256 version;
        uint256 timestamp;
        int256 price;
    }

    /**
     * @notice Checks for a new price and updates the internal phase annotation state accordingly
     * @dev `sync` is expected to be called soon after a phase update occurs in the underlying proxy.
     *      Phase updates should be detected using off-chain mechanism and should trigger a `sync` call
     *      This is feasible in the short term due to how infrequent phase updates are, but phase update
     *      and roundCount detection should eventually be implemented at the contract level.
     *      Reverts if there is more than 1 phase to update in a single sync because we currently cannot
     *      determine the startingRoundId for the intermediary phase.
     * @return The current oracle version after sync
     */
    function sync() external returns (OracleVersion memory);

    /**
     * @notice Returns the current oracle version
     * @return oracleVersion Current oracle version
     */
    function currentVersion() external view returns (OracleVersion memory);

    /**
     * @notice Returns the current oracle version
     * @param version The version of which to lookup
     * @return oracleVersion Oracle version at version `version`
     */
    function atVersion(uint256 version) external view returns (OracleVersion memory);

    /**
     * @notice Retrieves the description of the Oracle Provider.
     * @return A string representing the description of the Oracle Provider.
     */
    function description() external view returns (string memory);
}