// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Context.sol";

/**
    https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IWorldModule {
    function moduleID() external view returns (uint256);

    function tokenSVG(uint256 _actor, uint256 _startY, uint256 _lineHeight) external view returns (string memory, uint256 _endY);
    function tokenJSON(uint256 _actor) external view returns (string memory);
}

interface IWorldRandom is IWorldModule {
    function dn(uint256 _actor, uint256 _number) external view returns (uint256);
    function d20(uint256 _actor) external view returns (uint256);
}

interface IActors is IERC721, IWorldModule {

    struct Actor 
    {
        address owner;
        address account;
        uint256 actorId;
    }

    event TaiyiDAOUpdated(address taiyiDAO);
    event ActorMinted(address indexed owner, uint256 indexed actorId, uint256 indexed time);
    event ActorPurchased(address indexed payer, uint256 indexed actorId, uint256 price);

    function actor(uint256 _actor) external view returns (uint256 _mintTime, uint256 _status);
    function nextActor() external view returns (uint256);
    function mintActor(uint256 maxPrice) external returns(uint256 actorId);
    function changeActorRenderMode(uint256 _actor, uint256 _mode) external;
    function setTaiyiDAO(address _taiyiDAO) external;

    function actorPrice() external view returns (uint256);
    function getActor(uint256 _actor) external view returns (Actor memory);
    function getActorByHolder(address _holder) external view returns (Actor memory);
    function getActorsByOwner(address _owner) external view returns (Actor[] memory);
    function isHolderExist(address _holder) external view returns (bool);
}

interface IWorldYemings is IWorldModule {
    event TaiyiDAOUpdated(address taiyiDAO);

    function setTaiyiDAO(address _taiyiDAO) external;

    function YeMings(uint256 _actor) external view returns (address);
    function isYeMing(uint256 _actor) external view returns (bool);
}

interface IWorldTimeline is IWorldModule {

    event AgeEvent(uint256 indexed actor, uint256 indexed age, uint256 indexed eventId);
    event BranchEvent(uint256 indexed actor, uint256 indexed age, uint256 indexed eventId);
    event ActiveEvent(uint256 indexed actor, uint256 indexed age, uint256 indexed eventId);

    function name() external view returns (string memory);
    function description() external view returns (string memory);
    function operator() external view returns (uint256);
    function events() external view returns (IWorldEvents);

    function grow(uint256 _actor) external;
    function activeTrigger(uint256 _eventId, uint256 _actor, uint256[] memory _uintParams, string[] memory _stringParams) external;
}

interface IActorAttributes is IWorldModule {

    event Created(address indexed creator, uint256 indexed actor, uint256[] attributes);
    event Updated(address indexed executor, uint256 indexed actor, uint256[] attributes);

    function setAttributes(uint256 _operator, uint256 _actor, uint256[] memory _attributes) external;
    function pointActor(uint256 _operator, uint256 _actor) external;

    function attributeLabels(uint256 _attributeId) external view returns (string memory);
    function attributesScores(uint256 _attributeId, uint256 _actor) external view returns (uint256);
    function characterPointsInitiated(uint256 _actor) external view returns (bool);
    function applyModified(uint256 _actor, int[] memory _modifiers) external view returns (uint256[] memory, bool);
}

interface IActorBehaviorAttributes is IActorAttributes {

    event ActRecovered(uint256 indexed actor, uint256 indexed act);

    function canRecoverAct(uint256 _actor) external view returns (bool);
    function recoverAct(uint256 _actor) external;
}

interface IActorTalents is IWorldModule {

    event Created(address indexed creator, uint256 indexed actor, uint256[] ids);

    function talents(uint256 _id) external view returns (string memory _name, string memory _description);
    function talentAttributeModifiers(uint256 _id) external view returns (int256[] memory);
    function talentAttrPointsModifiers(uint256 _id, uint256 _attributeModuleId) external view returns (int256);
    function setTalent(uint256 _id, string memory _name, string memory _description, int[] memory _modifiers, int256[] memory _attr_point_modifiers) external;
    function setTalentExclusive(uint256 _id, uint256[] memory _exclusive) external;
    function setTalentProcessor(uint256 _id, address _processorAddress) external;
    function talentProcessors(uint256 _id) external view returns(address);
    function talentExclusivity(uint256 _id) external view returns (uint256[] memory);

    function setActorTalent(uint256 _operator, uint256 _actor, uint256 _tid) external;
    function talentActor(uint256 _operator, uint256 _actor) external; 
    function actorAttributePointBuy(uint256 _actor, uint256 _attributeModuleId) external view returns (uint256);
    function actorTalents(uint256 _actor) external view returns (uint256[] memory);
    function actorTalentsInitiated(uint256 _actor) external view returns (bool);
    function actorTalentsExist(uint256 _actor, uint256[] memory _talents) external view returns (bool[] memory);
    function canOccurred(uint256 _actor, uint256 _id, uint256 _age) external view returns (bool);
}

interface IActorTalentProcessor {
    function checkOccurrence(uint256 _actor, uint256 _age) external view returns (bool);
    function process(uint256 _operator, uint256 _actor, uint256 _age) external;
}

interface IWorldEvents is IWorldModule {

    event Born(uint256 indexed actor);

    function ages(uint256 _actor) external view returns (uint256); //current age
    function actorBorn(uint256 _actor) external view returns (bool);
    function actorBirthday(uint256 _actor) external view returns (bool);
    function expectedAge(uint256 _actor) external view returns (uint256); //age should be
    function actorEvent(uint256 _actor, uint256 _age) external view returns (uint256[] memory);
    function actorEventCount(uint256 _actor, uint256 _eventId) external view returns (uint256);

    function eventInfo(uint256 _id, uint256 _actor) external view returns (string memory);
    function eventAttributeModifiers(uint256 _id, uint256 _actor) external view returns (int256[] memory);
    function eventProcessors(uint256 _id) external view returns(address);
    function setEventProcessor(uint256 _id, address _address) external;
    function canOccurred(uint256 _actor, uint256 _id, uint256 _age) external view returns (bool);
    function checkBranch(uint256 _actor, uint256 _id, uint256 _age) external view returns (uint256);

    function bornActor(uint256 _operator, uint256 _actor) external;
    function grow(uint256 _operator, uint256 _actor) external;
    function changeAge(uint256 _operator, uint256 _actor, uint256 _age) external;
    function addActorEvent(uint256 _operator, uint256 _actor, uint256 _age, uint256 _eventId) external;
}

interface IWorldEventProcessor {
    function eventInfo(uint256 _actor) external view returns (string memory);
    function eventAttributeModifiers(uint256 _actor) external view returns (int[] memory);
    function trigrams(uint256 _actor) external view returns (uint256[] memory);
    function checkOccurrence(uint256 _actor, uint256 _age) external view returns (bool);
    function process(uint256 _operator, uint256 _actor, uint256 _age) external;
    function activeTrigger(uint256 _operator, uint256 _actor, uint256[] memory _uintParams, string[] memory _stringParams) external;

    function checkBranch(uint256 _actor, uint256 _age) external view returns (uint256);
    function setDefaultBranch(uint256 _enentId) external;
}

interface IWorldFungible is IWorldModule {
    event FungibleTransfer(uint256 indexed from, uint256 indexed to, uint256 amount);
    event FungibleApproval(uint256 indexed from, uint256 indexed to, uint256 amount);

    function balanceOfActor(uint256 _owner) external view returns (uint256);
    function allowanceActor(uint256 _owner, uint256 _spender) external view returns (uint256);

    function approveActor(uint256 _from, uint256 _spender, uint256 _amount) external;
    function transferActor(uint256 _from, uint256 _to, uint256 _amount) external;
    function transferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _amount) external;
    function claim(uint256 _operator, uint256 _actor, uint256 _amount) external;
    function withdraw(uint256 _operator, uint256 _actor, uint256 _amount) external;
}

interface IWorldNonfungible {
    event NonfungibleTransfer(uint256 indexed from, uint256 indexed to, uint256 indexed tokenId);
    event NonfungibleApproval(uint256 indexed owner, uint256 indexed approved, uint256 indexed tokenId);
    event NonfungibleApprovalForAll(uint256 indexed owner, uint256 indexed operator, bool approved);

    function tokenOfActorByIndex(uint256 _owner, uint256 _index) external view returns (uint256);
    function balanceOfActor(uint256 _owner) external view returns (uint256);
    function ownerActorOf(uint256 _tokenId) external view returns (uint256);
    function getApprovedActor(uint256 _tokenId) external view returns (uint256);
    function isApprovedForAllActor(uint256 _owner, uint256 _operator) external view returns (bool);

    function approveActor(uint256 _from, uint256 _to, uint256 _tokenId) external;
    function setApprovalForAllActor(uint256 _from, uint256 _operator, bool _approved) external;
    function safeTransferActor(uint256 _from, uint256 _to, uint256 _tokenId, bytes calldata _data) external;
    function safeTransferActor(uint256 _from, uint256 _to, uint256 _tokenId) external;
    function transferActor(uint256 _from, uint256 _to, uint256 _tokenId) external;
    function safeTransferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _tokenId, bytes calldata _data) external;
    function safeTransferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _tokenId) external;
    function transferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _tokenId) external;
}

interface IActorNames is IWorldNonfungible, IERC721Enumerable, IWorldModule {

    event NameClaimed(address indexed owner, uint256 indexed actor, uint256 indexed nameId, string name, string firstName, string lastName);
    event NameUpdated(uint256 indexed nameId, string oldName, string newName);
    event NameAssigned(uint256 indexed nameId, uint256 indexed previousActor, uint256 indexed newActor);

    function nextName() external view returns (uint256);
    function actorName(uint256 _actor) external view returns (string memory _name, string memory _firstName, string memory _lastName);

    function claim(string memory _firstName, string memory _lastName, uint256 _actor) external returns (uint256 _nameId);
    function assignName(uint256 _nameId, uint256 _actor) external;
    function withdraw(uint256 _operator, uint256 _actor) external;
}

interface IWorldZones is IWorldNonfungible, IERC721Enumerable, IWorldModule {

    event ZoneClaimed(uint256 indexed actor, uint256 indexed zoneId, string name);
    event ZoneUpdated(uint256 indexed zoneId, string oldName, string newName);
    event ZoneAssigned(uint256 indexed zoneId, uint256 indexed previousActor, uint256 indexed newActor);

    function nextZone() external view returns (uint256);
    function names(uint256 _zoneId) external view returns (string memory);
    function timelines(uint256 _zoneId) external view returns (address);

    function claim(uint256 _operator, string memory _name, address _timelineAddress, uint256 _actor) external returns (uint256 _zoneId);
    function withdraw(uint256 _operator, uint256 _zoneId) external;
}

interface IActorBornPlaces is IWorldModule {
    function bornPlaces(uint256 _actor) external view returns (uint256);
    function bornActor(uint256 _operator, uint256 _actor, uint256 _zoneId) external;
}

interface IActorSocialIdentity is IWorldNonfungible, IERC721Enumerable, IWorldModule {
    event SIDClaimed(uint256 indexed actor, uint256 indexed sid, string name);
    event SIDDestroyed(uint256 indexed actor, uint256 indexed sid, string name);

    function nextSID() external view returns (uint256);
    function names(uint256 _nameid) external view returns (string memory);
    function claim(uint256 _operator, uint256 _nameid, uint256 _actor) external returns (uint256 _sid);
    function burn(uint256 _operator, uint256 _sid) external;
    function sidName(uint256 _sid) external view returns (uint256 _nameid, string memory _name);
    function haveName(uint256 _actor, uint256 _nameid) external view returns (bool);
}

interface IActorRelationship is IWorldModule {
    event RelationUpdated(uint256 indexed actor, uint256 indexed target, uint256 indexed rsid, string rsname);

    function relations(uint256 _rsid) external view returns (string memory);
    function setRelation(uint256 _rsid, string memory _name) external;
    function setRelationProcessor(uint256 _rsid, address _processorAddress) external;
    function relationProcessors(uint256 _id) external view returns(address);

    function setActorRelation(uint256 _operator, uint256 _actor, uint256 _target, uint256 _rsid) external;
    function actorRelations(uint256 _actor, uint256 _target) external view returns (uint256);
    function actorRelationPeople(uint256 _actor, uint256 _rsid) external view returns (uint256[] memory);
}

interface IActorRelationshipProcessor {
    function process(uint256 _actor, uint256 _age) external;
}

struct SItem 
{
    uint256 typeId;
    string typeName;
    uint256 shapeId;
    string shapeName;
    uint256 wear;
}

interface IWorldItems is IWorldNonfungible, IERC721Enumerable, IWorldModule {
    event ItemCreated(uint256 indexed actor, uint256 indexed item, uint256 indexed typeId, string typeName, uint256 wear, uint256 shape, string shapeName);
    event ItemChanged(uint256 indexed actor, uint256 indexed item, uint256 indexed typeId, string typeName, uint256 wear, uint256 shape, string shapeName);
    event ItemDestroyed(uint256 indexed item, uint256 indexed typeId, string typeName);

    function nextItemId() external view returns (uint256);
    function typeNames(uint256 _typeId) external view returns (string memory);
    function itemTypes(uint256 _itemId) external view returns (uint256);
    function itemWears(uint256 _itemId) external view returns (uint256);  //耐久
    function shapeNames(uint256 _shapeId) external view returns (string memory);
    function itemShapes(uint256 _itemId) external view returns (uint256); //品相

    function item(uint256 _itemId) external view returns (SItem memory);

    function mint(uint256 _operator, uint256 _typeId, uint256 _wear, uint256 _shape, uint256 _actor) external returns (uint256);
    function modify(uint256 _operator, uint256 _itemId, uint256 _wear) external;
    function burn(uint256 _operator, uint256 _itemId) external;
    function withdraw(uint256 _operator, uint256 _itemId) external;
}

interface IActorPrelifes is IWorldModule {

    event Reincarnation(uint256 indexed actor, uint256 indexed postLife);

    function preLifes(uint256 _actor) external view returns (uint256);
    function postLifes(uint256 _actor) external view returns (uint256);

    function setPrelife(uint256 _operator, uint256 _actor, uint256 _prelife) external;
}

interface IWorldSeasons is IWorldModule {

    function seasonLabels(uint256 _seasonId) external view returns (string memory);
    function actorBornSeasons(uint256 _actor) external view returns (uint256); // =0 means not born

    function bornActor(uint256 _operator, uint256 _actor, uint256 _seasonId) external;
}

interface IWorldZoneBaseResources is IWorldModule {

    event ZoneAssetGrown(uint256 indexed zone, uint256 gold, uint256 food, uint256 herb, uint256 fabric, uint256 wood);
    event ActorAssetCollected(uint256 indexed actor, uint256 gold, uint256 food, uint256 herb, uint256 fabric, uint256 wood);

    function ACTOR_GUANGONG() external view returns (uint256);

    function growAssets(uint256 _operator, uint256 _zoneId) external;
    function collectAssets(uint256 _operator, uint256 _actor, uint256 _zoneId) external;
}

interface IActorLocations is IWorldModule {

    event ActorLocationChanged(uint256 indexed actor, uint256 indexed oldA, uint256 indexed oldB, uint256 newA, uint256 newB);

    function locationActors(uint256 _A, uint256 _B) external view returns (uint256[] memory);
    function actorLocations(uint256 _actor) external view returns (uint256[] memory); //return 2 items array
    function actorFreeTimes(uint256 _actor) external view returns (uint256);
    function isActorLocked(uint256 _actor) external view returns (bool);
    function isActorUnlocked(uint256 _actor) external view returns (bool);

    function setActorLocation(uint256 _operator, uint256 _actor, uint256 _A, uint256 _B) external;
    function lockActor(uint256 _operator, uint256 _actor, uint256 _freeTime) external;
    function unlockActor(uint256 _operator, uint256 _actor) external;
    function finishActorTravel(uint256 _actor) external;
}

interface IWorldVillages is IWorldModule {
    function isZoneVillage(uint256 _zoneId) external view returns (bool);
    function villageCreators(uint256 _zoneId) external view returns (uint256);

    function createVillage(uint256 _operator, uint256 _actor, uint256 _zoneId) external;
}

//building is an item
interface IWorldBuildings is IWorldModule {

    function typeNames(uint256 _typeId) external view returns (string memory);
    function buildingTypes(uint256 _zoneId) external view returns (uint256);
    function isZoneBuilding(uint256 _zoneId) external view returns (bool);

    function createBuilding(uint256 _operator, uint256 _actor, uint256 _typeId, uint256 _zoneId) external;
}

interface ITrigramsRender is IWorldModule {
}

interface ITrigrams is IWorldModule {
    
    event TrigramsOut(uint256 indexed actor, uint256 indexed trigram);

    function addActorTrigrams(uint256 _operator, uint256 _actor, uint256[] memory _trigramsData) external;
    function actorTrigrams(uint256 _actor) external view returns (int256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library WorldConstants {

    //special actors ID
    uint256 public constant ACTOR_PANGU = 1;

    //actor attributes ID
    uint256 public constant ATTR_BASE = 0;
    uint256 public constant ATTR_AGE = 0; // 年龄
    uint256 public constant ATTR_HLH = 1; // 健康，生命

    //module ID
    uint256 public constant WORLD_MODULE_ACTORS       = 0;  //角色
    uint256 public constant WORLD_MODULE_RANDOM       = 1;  //随机数
    uint256 public constant WORLD_MODULE_NAMES        = 2;  //姓名
    uint256 public constant WORLD_MODULE_COIN         = 3;  //通货
    uint256 public constant WORLD_MODULE_YEMINGS      = 4;  //噎明权限
    uint256 public constant WORLD_MODULE_ZONES        = 5;  //区域
    uint256 public constant WORLD_MODULE_SIDS         = 6;  //身份
    uint256 public constant WORLD_MODULE_ITEMS        = 7;  //物品
    uint256 public constant WORLD_MODULE_PRELIFES     = 8;  //前世
    uint256 public constant WORLD_MODULE_ACTOR_LOCATIONS    = 9;  //角色定位

    uint256 public constant WORLD_MODULE_TRIGRAMS_RENDER    = 10; //角色符文渲染器
    uint256 public constant WORLD_MODULE_TRIGRAMS           = 11; //角色符文数据

    uint256 public constant WORLD_MODULE_SIFUS        = 12; //师傅令牌
    uint256 public constant WORLD_MODULE_ATTRIBUTES   = 13; //角色基本属性
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../../interfaces/WorldInterfaces.sol";
import "../WorldConfigurable.sol";
import "../../libs/Base64.sol";
//import "hardhat/console.sol";

contract ActorPrelifes is IActorPrelifes, WorldConfigurable {

    /* *******
     * Globals
     * *******
     */

    mapping(uint256 => uint256) public override preLifes;  //前世
    mapping(uint256 => uint256) public override postLifes; //后世
    
    /* *********
     * Modifiers
     * *********
     */

    /* ****************
     * Public Functions
     * ****************
     */

    constructor(WorldContractRoute _route) WorldConfigurable(_route) {
    }

    /* *****************
     * Internal Functions
     * *****************
     */

    function _tokenSVG(uint256 _actor, uint256 _startY, uint256 _lineHeight) internal view returns (string memory, uint256 _endY) {
        _endY = _startY;
        string[7] memory parts;
        //前世：
        if(preLifes[_actor] > 0) {        
            parts[0] = string(abi.encodePacked('<text x="10" y="', Strings.toString(_endY), '" class="base">',
                '\xE5\x89\x8D\xE4\xB8\x96\xEF\xBC\x9A', Strings.toString(preLifes[_actor]), '</text>'));
            _endY += _lineHeight;
        }
        return (string(abi.encodePacked(parts[0])), _endY);
    }

    function _tokenJSON(uint256 _actor) internal view returns (string memory) {
        string[7] memory parts;
        parts[0] = string(abi.encodePacked('{', '"prelife": ', Strings.toString(preLifes[_actor]), '}'));
        return string(abi.encodePacked(parts[0]));
    }

    /* ****************
     * External Functions
     * ****************
     */

    function moduleID() external override pure returns (uint256) { return WorldConstants.WORLD_MODULE_PRELIFES; }

    function setPrelife(uint256 _operator, uint256 _actor, uint256 _prelife) external override
        onlyYeMing(_operator)
    {
        IActors actors = worldRoute.actors();
        uint256 mt; uint256 st;
        (mt , st) = actors.actor(_actor);
        require(st != 0, "non exist actor");

        (mt , st) = actors.actor(_prelife);
        require(st != 0, "non exist prelife");
        require(postLifes[_prelife] == 0, "prelife is reincarnation.");
        IActorAttributes attributes = IActorAttributes(worldRoute.modules(WorldConstants.WORLD_MODULE_ATTRIBUTES));
        require(attributes.attributesScores(WorldConstants.ATTR_HLH, _prelife) == 0, "prelife actor is alive.");

        preLifes[_actor] = _prelife;
        postLifes[_prelife] = _actor;

        emit Reincarnation(_prelife, _actor);
    }

    /* **************
     * View Functions
     * **************
     */

    function tokenSVG(uint256 _actor, uint256 _startY, uint256 _lineHeight) external override view returns (string memory, uint256 _endY) {
        return _tokenSVG(_actor, _startY, _lineHeight);
    }

    function tokenJSON(uint256 _actor) external override view returns (string memory) {
        return _tokenJSON(_actor);
    }

    /* ****************
     * Private Functions
     * ****************
     */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./WorldContractRoute.sol";

contract WorldConfigurable
{
    WorldContractRoute internal worldRoute;

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "not approved or owner of actor");
        _;
    }

    modifier onlyPanGu() {
        require(_isActorApprovedOrOwner(WorldConstants.ACTOR_PANGU), "only PanGu");
        _;
    }

    modifier onlyYeMing(uint256 _actor) {
        require(IWorldYemings(worldRoute.modules(WorldConstants.WORLD_MODULE_YEMINGS)).isYeMing(_actor), "only YeMing");
        require(_isActorApprovedOrOwner(_actor), "not YeMing's operator");
        _;
    }

    constructor(WorldContractRoute _route) {
        worldRoute = _route;
    }

    function _isActorApprovedOrOwner(uint _actor) internal view returns (bool) {
        IActors actors = worldRoute.actors();
        return (actors.getApproved(_actor) == msg.sender || actors.ownerOf(_actor) == msg.sender) || actors.isApprovedForAll(actors.ownerOf(_actor), msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/WorldInterfaces.sol";
import "../libs/WorldConstants.sol";
import "../base/Ownable.sol";

contract WorldContractRoute is Ownable
{ 
    uint256 public constant ACTOR_PANGU = 1;
    
    mapping(uint256 => address) public modules;
    address                     public actorsAddress;
    IActors                     public actors;
 
    /* *********
     * Modifiers
     * *********
     */

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "cannot set zero address");
        _;
    }

    modifier onlyPanGu() {
        require(_isActorApprovedOrOwner(ACTOR_PANGU), "only PanGu");
        _;
    }

    /* ****************
     * Internal Functions
     * ****************
     */

    function _isActorApprovedOrOwner(uint256 _actor) internal view returns (bool) {
        return (actors.getApproved(_actor) == msg.sender || actors.ownerOf(_actor) == msg.sender) || actors.isApprovedForAll(actors.ownerOf(_actor), msg.sender);
    }

    /* ****************
     * External Functions
     * ****************
     */

    function registerActors(address _address) external 
        onlyOwner
        onlyValidAddress(_address)
    {
        require(actorsAddress == address(0), "Actors address already registered.");
        actorsAddress = _address;
        actors = IActors(_address);
        modules[WorldConstants.WORLD_MODULE_ACTORS] = _address;
    }

    function registerModule(uint256 id, address _address) external 
        onlyPanGu
        onlyValidAddress(_address)
    {
        //require(modules[id] == address(0), "module address already registered.");
        require(IWorldModule(_address).moduleID() == id, "module id is not match.");
        modules[id] = _address;
    }
}