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

import "../solv/interfaces/IVNFT.sol";
import "../solv/openzeppelin/token/ERC721/IERC721Upgradeable.sol";

interface ISurfVoucher is IERC721Upgradeable, IVNFT {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);
    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    function slotAdminOf(uint256 slot) external view returns (address);

    function mint(uint256 slot, address user, uint256 units) external returns (uint256);

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVoucherSVG {
  
  function generateSVG(address voucher_, uint256 tokenId_) external view returns (bytes memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* is ERC721, ERC165 */
interface IVNFT {
    event TransferUnits(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        uint256 targetTokenId,
        uint256 transferUnits
    );

    event Split(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 newTokenId,
        uint256 splitUnits
    );

    event Merge(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed targetTokenId,
        uint256 mergeUnits
    );

    event ApprovalUnits(
        address indexed approval,
        uint256 indexed tokenId,
        uint256 allowance
    );

    function slotOf(uint256 tokenId) external view returns (uint256 slot);

    function unitDecimals() external view returns (uint8);

    function unitsInSlot(uint256 slot) external view returns (uint256);

    function tokensInSlot(uint256 slot)
        external
        view
        returns (uint256 tokenCount);

    function tokenOfSlotByIndex(uint256 slot, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function unitsInToken(uint256 tokenId)
        external
        view
        returns (uint256 units);

    function approve(
        address to,
        uint256 tokenId,
        uint256 units
    ) external;

    function allowance(uint256 tokenId, address spender)
        external
        view
        returns (uint256 allowed);

    function split(uint256 tokenId, uint256[] calldata units)
        external
        returns (uint256[] memory newTokenIds);

    function merge(uint256[] calldata tokenIds, uint256 targetTokenId) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 units
    ) external returns (uint256 newTokenId);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 units,
        bytes calldata data
    ) external returns (uint256 newTokenId);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 units
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 units,
        bytes calldata data
    ) external;
}

interface IVNFTReceiver {
    function onVNFTReceived(
        address operator,
        address from,
        uint256 tokenId,
        uint256 units,
        bytes calldata data
    ) external returns (bytes4);
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// DateTime Library v1.01 by BokkyPooBah's 
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./DateTime.sol";

library StringConverter {
  using Strings for uint256;

  function toString(uint256 value) internal pure returns (string memory) {
    return value.toString();
  }

  function addressToString(address self) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(uint160(self)));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42);
    str[0] = "0";
    str[1] = "x";
    for (uint256 i = 0; i < 20; i++) {
      str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
      str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    return string(str);
  }

  function uint2decimal(uint256 self, uint8 decimals) internal pure returns (bytes memory) {
    uint256 base = 10**decimals;
    string memory round = uint256(self / base).toString();
    string memory fraction = uint256(self % base).toString();
    uint256 fractionLength = bytes(fraction).length;

    bytes memory fullStr = abi.encodePacked(round, ".");
    if (fractionLength < decimals) {
      for (uint8 i = 0; i < decimals - fractionLength; i++) {
        fullStr = abi.encodePacked(fullStr, "0");
      }
    }

    return abi.encodePacked(fullStr, fraction);
  }

  function trim(bytes memory self, uint256 cutLength) internal pure returns (bytes memory newString) {
    newString = new bytes(self.length - cutLength);
    uint256 nlength = newString.length;
    for(uint i = 0; i < nlength;) {
      newString[i] = self[i];
      unchecked {
        ++i;
      }
    }
  }

  function addThousandsSeparator(bytes memory self) internal pure returns (bytes memory newString) {
    if (self.length <= 6) {
      return self;
    }
    newString = new bytes(self.length + (self.length - 4) / 3);
    uint256 oriIndex = self.length - 1;
    uint256 newIndex = newString.length - 1;
    for(uint256 i = 0; i < newString.length;){
      unchecked{
        newString[newIndex] = self[oriIndex];
        if( i >= 5 && i % 4 == 1 && newString.length - i > 1) {
          newIndex--;
          newString[newIndex] = 0x2c;
          i++;
        }
        i++;
        newIndex--;
        oriIndex--;
        }
    }
  }

  function datetimeToString(uint256 timestamp) internal pure returns (string memory) {
    (
      uint256 year,
      uint256 month,
      uint256 day,
      uint256 hour,
      uint256 minute,
      uint256 second
    ) = DateTime.timestampToDateTime(timestamp);
    return
      string(
        abi.encodePacked(
          year.toString(),
          "/",
          month < 10 ? "0" : "",
          month.toString(),
          "/",
          day < 10 ? "0" : "",
          day.toString(),
          " ",
          hour < 10 ? "0" : "",
          hour.toString(),
          ":",
          minute < 10 ? "0" : "",
          minute.toString(),
          ":",
          second < 10 ? "0" : "",
          second.toString()
        )
      );
  }

  function dateToString(uint256 timestamp) internal pure returns (string memory) {
    (uint256 year, uint256 month, uint256 day) = DateTime.timestampToDate(timestamp);
    return
      string(
        abi.encodePacked(
          year.toString(),
          "/",
          month < 10 ? "0" : "",
          month.toString(),
          "/",
          day < 10 ? "0" : "",
          day.toString()
        )
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/IVoucherSVG.sol";
import "./interfaces/ISurfVoucher.sol";
import "./utils/StringConverter.sol";

contract VoucherSVG1 is IVoucherSVG {
  using StringConverter for uint256;
  using StringConverter for uint128;
  using StringConverter for bytes;

  struct SVGParams {
    uint256 bondsAmount;
    uint128 tokenId;
    uint128 slotId;
    uint8 bondsDecimals;
  }

  /// Admin functions

  /// View functions

  function generateSVG(address _voucher, uint256 _tokenId) external view override returns (bytes memory) {
    ISurfVoucher voucher = ISurfVoucher(_voucher);
    uint128 slotId = uint128(voucher.slotOf(_tokenId));

    SVGParams memory svgParams;
    svgParams.bondsAmount = voucher.unitsInToken(_tokenId);
    svgParams.tokenId = uint128(_tokenId);
    svgParams.slotId = slotId;
    svgParams.bondsDecimals = uint8(voucher.unitDecimals());

    return _generateSVG(svgParams);
  }

  /// Internal functions

  function _generateSVG(SVGParams memory params) internal view virtual returns (bytes memory) {
    return
        abi.encodePacked(
          '<svg width="600px" height="400px" viewBox="0 0 600 400" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          '<g stroke-width="1" fill="none" fill-rule="evenodd" font-family="Arial">',
          _generateBackground(),
          _generateTitle(params),
          _generateLogo(),
          "</g>",
          "</svg>"
      );
  }

  function _generateBackground() internal pure returns (string memory) {
    return 
        string(
            abi.encodePacked(
              '<path d="M400.8 142.367c-3.961 1.603-10.472 4.858-15.401 7.702-2.859 1.65-7.899 4.414-11.198 6.143-6.998 3.665-14.509 8.027-22.481 13.058-3.124 1.972-7.715 4.446-10.2 5.501-17.061 7.23-51.506 27.742-63.104 37.578-8.095 6.864-17.003 14.935-19.177 17.376-1.408 1.581-3.478 3.537-4.601 4.345-8.373 6.04-7.715 7.853 7.161 19.776 1.321 1.06 3.838 3.182 5.593 4.718s8.055 6.435 13.999 10.887c5.944 4.452 12.159 9.161 13.809 10.462 1.65 1.304 7.77 5.572 13.6 9.482 5.83 3.912 12.669 8.595 15.2 10.405 4.698 3.363 21.577 14.021 27.381 17.288 1.77.997 4.029 2.387 5.019 3.087 6.575 4.654 10.461 6.2 10.735 4.266.212-1.494-4.058-5.267-11.164-9.861-16.82-10.877-46.75-31.393-52.929-36.282-3.635-2.875-10.948-8.535-18.442-14.271-2.86-2.188-7.899-6.354-11.2-9.255-3.299-2.902-7.35-6.363-9-7.689-9.961-8.008-10.585-10.983-3.249-15.481 1.898-1.163 5.983-3.962 9.08-6.221 12.985-9.471 24.642-17.162 37.569-24.785 4.4-2.594 10.07-6.097 12.6-7.783 4.648-3.097 12.75-7.972 15.928-9.582 1.091-.552 2.272-.831 3.2-.753l1.472.122.201 4.471c.35 7.868.925 8.202 14.789 8.605 29.273.853 41.467 3.564 58.826 13.088 8.925 4.895 27.5 18.534 34.968 25.677 6.817 6.521 7.748 6.486 14.516-.544 4.105-4.264 3.95-5.401-1.247-9.171-1.569-1.137-5.082-3.881-7.806-6.097-16.038-13.045-17.43-14.041-30.188-21.597-14.523-8.602-25.208-12.31-42.059-14.597-10.457-1.419-14.13-1.704-25.439-1.973-11.838-.281-12.361-.381-12.361-2.35 0-1.557 2.239-3.439 5.6-4.706 1.651-.622 5.52-2.293 8.6-3.714 4.97-2.291 15.579-6.873 28.8-12.44 6.591-2.775 9.371-2.713 14.4.318 6.914 4.168 15.24 10.001 20.41 14.298 11.432 9.506 23.993 18.526 26.879 19.303 2.234.601 3.801.012 7.738-2.912 5.782-4.291 5.708-6.052-.427-10.272-1.21-.831-4.72-3.617-7.8-6.188-10.307-8.604-29.39-22.615-35.898-26.359-6.927-3.984-9.133-4.518-12.702-3.073m121.99 29.414c-.943.513-18.688 18.894-22.172 22.969-.872 1.017-4.022 4.627-7.001 8.02-24.996 28.472-23.772 34.551 2.183 10.838 1.76-1.608 6.26-5.398 10-8.422 3.739-3.022 8.869-7.419 11.4-9.771 2.531-2.35 7.215-6.42 10.411-9.042 7.835-6.426 8.633-7.938 5.662-10.735-3.826-3.602-8.076-5.166-10.483-3.857m-199.444 49.386c-4.989 3.043-5.488 11.097-.828 13.374 3.076 1.503 7.221-1.003 8.304-5.02 1.493-5.543-3.301-10.899-7.476-8.354m145.742 19.828c-2.953 1.013-7.888 5.788-7.888 7.628 0 1.585 6.473 7.333 16.073 14.271 8.76 6.334 15.129 11.184 19.328 14.72a477.316 477.316 0 0 0 8.199 6.737c5.332 4.252 10.294 8.846 18.4 17.035 9.79 9.891 10.842 10.21 15.486 4.703 3.216-3.814 3.891-5.72 2.925-8.261-1.332-3.504-24.357-24.873-37.81-35.092a1371.302 1371.302 0 0 1-10.402-7.973c-3.108-2.426-12.34-8.841-18.004-12.515-2.214-1.435-4.473-1.885-6.307-1.253M446.516 257.5a1312.53 1312.53 0 0 0-9.799 6.065c-23.077 14.395-37.505 17.914-80.717 19.69-13.778.566-14.4.865-14.4 6.918 0 6.724.559 6.916 18.343 6.308 19.271-.659 30.72-2.356 44.081-6.54 15.424-4.829 15.295-4.312-2.472 9.903-18.851 15.081-16.903 16.43 4.862 3.366 11.247-6.748 10.361-6.462 21.187-6.837 20.877-.724 36.935-5.244 34.855-9.81-.93-2.04-2.628-2.322-10.855-1.804-17.476 1.096-20.426 1.239-24.794 1.193-9.965-.101-9.933-.177 4.796-11.421 9.468-7.226 15.622-12.66 17.608-15.545 2.271-3.302 1.243-3.867-2.695-1.486" fill="#0d0592"/>',
              '<path d="M0 200v200h600V0H0v200m407.496-57.659c2.937 1.142 9.634 5.119 14.58 8.659 8.864 6.343 21.835 16.217 27.324 20.799 3.08 2.571 6.59 5.357 7.8 6.188 6.135 4.22 6.209 5.981.427 10.272-3.937 2.924-5.504 3.513-7.738 2.912-2.886-.777-15.447-9.797-26.879-19.303-5.17-4.297-13.496-10.13-20.41-14.298-5.029-3.031-7.809-3.093-14.4-.318-13.221 5.567-23.83 10.149-28.8 12.44-3.08 1.421-6.949 3.092-8.6 3.714-3.361 1.267-5.6 3.149-5.6 4.706 0 1.969.523 2.069 12.361 2.35 38.1.903 61.578 9.003 88.086 30.389 2.556 2.062 6.876 5.562 9.6 7.778 2.724 2.216 6.237 4.96 7.806 6.097 5.197 3.77 5.352 4.907 1.247 9.171-6.768 7.03-7.699 7.065-14.516.544-7.468-7.143-26.043-20.782-34.968-25.677-17.359-9.524-29.553-12.235-58.826-13.088-13.864-.403-14.439-.737-14.789-8.605L341 182.6l-1.472-.122c-.928-.078-2.109.201-3.2.753-3.178 1.61-11.28 6.485-15.928 9.582-2.53 1.686-8.2 5.189-12.6 7.783-12.927 7.623-24.584 15.314-37.569 24.785-3.097 2.259-7.182 5.058-9.08 6.221-7.336 4.498-6.712 7.473 3.249 15.481 1.65 1.326 5.701 4.787 9 7.689 3.301 2.901 8.34 7.067 11.2 9.255 7.494 5.736 14.807 11.396 18.442 14.271 6.179 4.889 36.109 25.405 52.929 36.282 7.106 4.594 11.376 8.367 11.164 9.861-.274 1.934-4.16.388-10.735-4.266-.99-.7-3.249-2.09-5.019-3.087-5.804-3.267-22.683-13.925-27.381-17.288-2.531-1.81-9.37-6.493-15.2-10.405-5.83-3.91-11.95-8.178-13.6-9.482-1.65-1.301-7.865-6.01-13.809-10.462-5.944-4.452-12.244-9.351-13.999-10.887-1.755-1.536-4.272-3.658-5.593-4.718-14.876-11.923-15.534-13.736-7.161-19.776 1.123-.808 3.193-2.764 4.601-4.345 2.174-2.441 11.082-10.512 19.177-17.376 11.598-9.836 46.043-30.348 63.104-37.578 2.485-1.055 7.076-3.529 10.2-5.501 7.972-5.031 15.483-9.393 22.481-13.058 3.299-1.729 8.339-4.493 11.198-6.143 4.929-2.844 11.44-6.099 15.401-7.702 2.324-.941 4.325-.949 6.696-.026M529.182 172.7c7.795 4.561 7.614 6.141-1.571 13.673-3.196 2.622-7.88 6.692-10.411 9.042-2.531 2.352-7.661 6.749-11.4 9.771-3.74 3.024-8.24 6.814-10 8.422-25.955 23.713-27.179 17.634-2.183-10.838 2.979-3.393 6.129-7.003 7.001-8.02 3.484-4.075 21.229-22.456 22.172-22.969 1.772-.964 3.632-.696 6.392.919m-201.795 48.268c4.264 1.782 4.956 8.193 1.295 12.009-5.927 6.176-12.821-2.658-7.58-9.711 1.927-2.595 3.872-3.306 6.285-2.298m148.008 21.28c5.664 3.674 14.896 10.089 18.004 12.515 1.981 1.544 6.66 5.131 10.402 7.973 13.453 10.219 36.478 31.588 37.81 35.092.966 2.541.291 4.447-2.925 8.261-4.644 5.507-5.696 5.188-15.486-4.703-8.106-8.189-13.068-12.783-18.4-17.035a477.316 477.316 0 0 1-8.199-6.737c-4.199-3.536-10.568-8.386-19.328-14.72-4.484-3.241-12.276-9.521-14.573-11.747-2.11-2.044-2.005-3.06.599-5.814 4.774-5.049 7.855-5.834 12.096-3.085M450.4 256.627c0 2.3-6.645 8.628-18.797 17.904-14.729 11.244-14.761 11.32-4.796 11.421 4.368.046 7.318-.097 24.794-1.193 8.227-.518 9.925-.236 10.855 1.804 2.08 4.566-13.978 9.086-34.855 9.81-10.826.375-9.94.089-21.187 6.837-11.116 6.672-17.614 9.708-17.614 8.229 0-1.145 2.275-3.214 12.752-11.595 17.767-14.215 17.896-14.732 2.472-9.903-13.361 4.184-24.81 5.881-44.081 6.54-17.784.608-18.343.416-18.343-6.308 0-6.053.622-6.352 14.4-6.918 43.212-1.776 57.64-5.295 80.717-19.69 13.102-8.172 13.683-8.468 13.683-6.938" fill="#7347f4"/>'
            )
        );
  }

  function _generateTitle(SVGParams memory params) internal pure returns (string memory) {
    string memory tokenIdStr = params.tokenId.toString();
    uint256 tokenIdLeftMargin = 488 - 20 * bytes(tokenIdStr).length;

    bytes memory amount = _formatValue(params.bondsAmount, params.bondsDecimals).trim(3);
    uint256 amountLeftMargin = 280 - 20 * amount.length;

    return 
      string(
        abi.encodePacked(
          '<g transform="translate(30, 30)" fill="#FFFFFF" fill-rule="nonzero">',
              '<text font-family="Arial" font-size="32">',
                  abi.encodePacked(
                      '<tspan x="', tokenIdLeftMargin.toString(), '" y="25"># ', tokenIdStr, '</tspan>'
                  ),
              '</text>',
              '<text font-family="Arial" font-size="64">',
                  abi.encodePacked(
                      '<tspan x="', amountLeftMargin.toString(), '" y="185">', amount, '</tspan>'
                  ),
              '</text>',
              '<text font-family="Arial" font-size="24"><tspan x="460" y="185">Points</tspan></text>',
              '<text font-family="Arial" font-size="24" font-weight="500"><tspan x="60" y="25"> SURF Game Points</tspan></text>',
          '</g>'
        )
      );
  }

  function _generateLogo() internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
            '<g transform="translate(20, 20)" fill-rule="evenodd">',
            '<path d="M23.2.403c-4.876.398-10.899 2.96-14.234 6.056C4.067 11.006 1.71 15.488.671 22.225c-.051.333-.069 1.03-.07 2.671L.6 27.116l.201 1.105c.456 2.507.669 3.324 1.324 5.106 1.485 4.028 3.81 7.335 7.175 10.202 2.755 2.347 5.765 3.915 9.444 4.921 1.921.525 2.566.639 4.431.78 5.183.394 10.191-.853 14.85-3.694 2.686-1.638 5.48-4.38 7.351-7.212 1.487-2.251 1.296-2.664-.79-1.704-2.284 1.05-6.29 2.577-9.111 3.474-5.071 1.611-8.317 2.164-12.775 2.172-5.646.012-10.194-1.271-13.278-3.744-2.404-1.929-3.661-4.031-3.926-6.571-.461-4.409 2.314-7.837 6.904-8.524 2.594-.389 3.633.111 1.901.913-2.864 1.326-3.918 2.161-4.648 3.681-.651 1.354-.512 3.253.341 4.673 1.489 2.479 6.026 4.6 11.306 5.288 1.398.181 1.531.091 2.771-1.891a56.576 56.576 0 0 1 1.299-1.967l1.348-1.934a132.466 132.466 0 0 1 2.744-3.751c1.026-1.345.993-1.429-1.011-2.636-3.084-1.859-5.809-3.551-6.758-4.199a154.481 154.481 0 0 0-1.506-1.014c-4.556-3.008-4.784-3.214-4.313-3.909.736-1.084 8.467-8.582 10.149-9.842 1.141-.856 1.479-.611.823.596-.607 1.119-3.456 5.464-4.472 6.819-1.551 2.072-1.532 2.172.651 3.336.359.191.955.539 1.325.773.37.234 1.022.629 1.449.877a103.515 103.515 0 0 1 1.85 1.115c.59.364 1.466.903 1.948 1.197.787.481 2.509 1.594 3.5 2.263 2.948 1.989 2.938 1.981 2.888 2.496-.044.45-.823 1.331-4.059 4.584-2.531 2.544-3.222 3.213-5.13 4.956-1.881 1.719-1.91 1.752-1.827 2.08.098.39 2.269.453 4.954.143l1.3-.151c1.748-.204 4.724-.729 6.1-1.077.22-.056.908-.211 1.529-.344a41.794 41.794 0 0 0 1.875-.449 85.531 85.531 0 0 1 1.946-.501c3.449-.849 4.479-1.187 4.829-1.586.751-.855 1.816-5.044 1.954-7.688.106-2.039.026-3.154-.411-5.7-1.205-7.014-5.678-13.329-12.022-16.974-1.868-1.073-3.825-1.846-6.4-2.527A57.674 57.674 0 0 0 28.098.55c-.971-.178-3.551-.254-4.9-.144" fill="#fbc33c"/>',
            '</g>'
        )
      );
  }

  function _formatValue(uint256 value, uint8 decimals) private pure returns (bytes memory) {
    return value.uint2decimal(decimals).trim(decimals - 2).addThousandsSeparator();
  }
}