// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.20;

import {IERC721} from "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

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
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

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
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
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
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
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
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.22;

// Created By: Art Blocks Inc.

import "../../interfaces/v0.8.x/IRandomizer_V3CoreBase.sol";
import "../../interfaces/v0.8.x/IAdminACLV0_Extended.sol";
import "../../interfaces/v0.8.x/IGenArt721CoreContractV3_Engine.sol";
import {IGenArt721CoreContractV3_ProjectFinance} from "../../interfaces/v0.8.x/IGenArt721CoreContractV3_ProjectFinance.sol";
import "../../interfaces/v0.8.x/IGenArt721CoreContractExposesHashSeed.sol";
import "../../interfaces/v0.8.x/IDependencyRegistryCompatibleV0.sol";
import {ISplitProviderV0} from "../../interfaces/v0.8.x/ISplitProviderV0.sol";
import {IBytecodeStorageReader_Base} from "../../interfaces/v0.8.x/IBytecodeStorageReader_Base.sol";

import "@openzeppelin-5.0/contracts/utils/Strings.sol";
import "@openzeppelin-5.0/contracts/access/Ownable.sol";
import {IERC2981} from "@openzeppelin-5.0/contracts/interfaces/IERC2981.sol";
import "../../libs/v0.8.x/ERC721_PackedHashSeedV1.sol";
import {BytecodeStorageWriter, BytecodeStorageReader} from "../../libs/v0.8.x/BytecodeStorageV2.sol";
import "../../libs/v0.8.x/Bytes32Strings.sol";

/**
 * @title Art Blocks Engine ERC-721 core contract, V3.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract is designed to be managed, with progressively limited powers
 * as a project progresses from active to locked.
 * Privileged roles and abilities are controlled by the admin ACL contract and
 * artists. Both of these roles hold extensive power and can arbitrarily
 * control and modify portions of projects, dependent upon project state. After
 * a project is locked, important project metadata fields are locked including
 * the project name, artist name, and script and display details. Edition size
 * can never be increased.
 * Care must be taken to ensure that the admin ACL contract and artist
 * addresses are secure behind a multi-sig or other access control mechanism.
 * ----------------------------------------------------------------------------
 * The following functions are restricted to the Admin ACL contract:
 * - updateArtblocksDependencyRegistryAddress
 * - updateArtblocksOnChainGeneratorAddress
 * - updateNextCoreContract
 * - updateProviderSalesAddresses
 * - updateProviderPrimarySalesPercentages (up to 100%)
 * - updateProviderDefaultSecondarySalesBPS (up to 100%)
 * - syncProviderSecondaryForProjectToDefaults
 * - updateMinterContract
 * - updateRandomizerAddress
 * - toggleProjectIsActive (note: artist may be configured to activate projects)
 * - addProject
 * - forbidNewProjects (forever forbidding new projects)
 * - updateDefaultBaseURI (used to initialize new project base URIs)
 * - updateSplitProvider
 * - updateBytecodeStorageReaderContract
 * ----------------------------------------------------------------------------
 * The following functions are restricted to either the Artist address or
 * the Admin ACL contract, only when the project is not locked:
 * - updateProjectName
 * - updateProjectArtistName
 * - updateProjectLicense
 * - Change project script via addProjectScript, addProjectScriptCompressed,
 *   updateProjectScript, updateProjectScriptCompressed,
 *   and removeProjectLastScript
 * - updateProjectScriptType
 * - updateProjectAspectRatio
 * ----------------------------------------------------------------------------
 * The following functions are restricted to only the Artist address:
 * - proposeArtistPaymentAddressesAndSplits (Note that this has to be accepted
 *   by adminAcceptArtistAddressesAndSplits to take effect, which is restricted
 *   to the Admin ACL contract, or the artist if the core contract owner has
 *   renounced ownership. Also note that a proposal will be automatically
 *   accepted if the artist only proposes changed payee percentages without
 *   modifying any payee addresses, or is only removing payee addresses, or
 *   if the global config `autoApproveArtistSplitProposals` is set to `true`.)
 * - toggleProjectIsPaused (note the artist can still mint while paused)
 * - updateProjectSecondaryMarketRoyaltyPercentage (up to
     ARTIST_MAX_SECONDARY_ROYALTY_PERCENTAGE percent)
 * - updateProjectWebsite
 * - updateProjectMaxInvocations (to a number greater than or equal to the
 *   current number of invocations, and less than current project maximum
 *   invocations)
 * - updateProjectBaseURI (controlling the base URI for tokens in the project)
 * ----------------------------------------------------------------------------
 * The following function is restricted to either the Admin ACL contract, or
 * the Artist address if the core contract owner has renounced ownership:
 * - adminAcceptArtistAddressesAndSplits
 * - updateProjectArtistAddress (owner ultimately controlling the project and
 *   its and-on revenue, unless owner has renounced ownership)
 * ----------------------------------------------------------------------------
 * The following function is restricted to the artist when a project is
 * unlocked, and only callable by Admin ACL contract when a project is locked:
 * - updateProjectDescription
 * ----------------------------------------------------------------------------
 * The following function is restricted to owner calling directly:
 * - transferOwnership
 * - renounceOwnership
 * ----------------------------------------------------------------------------
 * The following configuration variables are set at time of contract deployment,
 * and not modifiable thereafter (immutable after the point of deployment):
 * - (bool) autoApproveArtistSplitProposals
 * ----------------------------------------------------------------------------
 * Additional admin and artist privileged roles may be described on minters,
 * registries, and other contracts that may interact with this core contract.
 */
contract GenArt721CoreV3_Engine is
    ERC721_PackedHashSeedV1,
    Ownable,
    IERC2981,
    IDependencyRegistryCompatibleV0,
    IGenArt721CoreContractV3_Engine,
    IGenArt721CoreContractV3_ProjectFinance,
    IGenArt721CoreContractExposesHashSeed
{
    using BytecodeStorageWriter for string;
    using BytecodeStorageWriter for bytes;
    using Bytes32Strings for bytes32;
    using Strings for uint256;
    using Strings for address;
    uint256 constant ONE_HUNDRED = 100;
    uint256 constant ONE_MILLION = 1_000_000;
    uint24 constant ONE_MILLION_UINT24 = 1_000_000;
    uint256 constant FOUR_WEEKS_IN_SECONDS = 2_419_200;
    uint8 constant AT_CHARACTER_CODE = uint8(bytes1("@")); // 0x40

    // numeric constants
    uint256 constant MAX_PROVIDER_SECONDARY_SALES_BPS = 10000; // 10_000 BPS = 100%
    uint256 constant ARTIST_MAX_SECONDARY_ROYALTY_PERCENTAGE = 95; // 95%

    /// pointer to next core contract associated with this contract
    address public nextCoreContract;

    /// Dependency registry managed by Art Blocks
    address public artblocksDependencyRegistryAddress;
    /// On chain generator managed by Art Blocks
    address public artblocksOnChainGeneratorAddress;

    /// ensure initialization can only be performed once
    bool private _initialized;

    /// current randomizer contract
    IRandomizer_V3CoreBase public randomizerContract;

    /// append-only array of all randomizer contract addresses ever used by
    /// this contract
    address[] private _historicalRandomizerAddresses;

    /// admin ACL contract
    IAdminACLV0 public adminACLContract;

    struct Project {
        uint24 invocations;
        uint24 maxInvocations;
        uint24 scriptCount;
        // max uint64 ~= 1.8e19 sec ~= 570 billion years
        uint64 completedTimestamp;
        bool active;
        bool paused;
        string name;
        string artist;
        address descriptionAddress;
        string website;
        string license;
        string projectBaseURI;
        bytes32 scriptTypeAndVersion;
        string aspectRatio;
        // mapping from script index to address storing script in bytecode
        mapping(uint256 => address) scriptBytecodeAddresses;
    }

    mapping(uint256 => Project) projects;

    /// private mapping from project ID to project financial information. See
    /// `projectIdToFinancials` getter for public access.
    mapping(uint256 _projectId => ProjectFinance)
        private _projectIdToFinancials;

    /// hash of artist's proposed payment updates to be approved by admin
    mapping(uint256 => bytes32) public proposedArtistAddressesAndSplitsHash;

    /// The render provider payment address for all primary sales revenues
    /// (packed)
    address payable public renderProviderPrimarySalesAddress;
    /// Percentage of primary sales revenue allocated to the render provider
    /// (packed)
    // packed uint: max of 100, max uint8 = 255
    uint8 private _renderProviderPrimarySalesPercentage;
    /// The platform provider payment address for all primary sales revenues
    /// (packed)
    address payable public platformProviderPrimarySalesAddress;
    /// Percentage of primary sales revenue allocated to the platform provider
    /// (packed)
    // packed uint: max of 100, max uint8 = 255
    uint8 private _platformProviderPrimarySalesPercentage;

    /// @dev Note on "default" provider secondary values - the only way these can
    /// be different on a per project basis is if admin updates these and then
    /// does not call syncProviderSecondaryForProjectToDefaults for the project.
    /// -----------------------------------------------------------------------
    /// The default render provider payment address for all secondary sales royalty
    /// revenues, for all new projects. Individual project payment info is defined
    /// in each project's ProjectFinance struct.
    /// Projects can be updated to this value by calling the
    /// `syncProviderSecondaryForProjectToDefaults` function for each project.
    address payable public defaultRenderProviderSecondarySalesAddress;
    /// The default basis points allocated to render provider for all secondary
    /// sales royalty revenues, for all new projects. Individual project
    /// payment info is defined in each project's ProjectFinance struct.
    /// Projects can be updated to this value by calling the
    /// `syncProviderSecondaryForProjectToDefaults` function for each project.
    uint256 public defaultRenderProviderSecondarySalesBPS;
    /// The default platform provider payment address for all secondary sales royalty
    /// revenues, for all new projects. Individual project payment info is defined
    /// in each project's ProjectFinance struct.
    /// Projects can be updated to this value by calling the
    /// `syncProviderSecondaryForProjectToDefaults` function for each project.
    address payable public defaultPlatformProviderSecondarySalesAddress;
    /// The default basis points allocated to platform provider for all secondary
    /// sales royalty revenues, for all new projects. Individual project
    /// payment info is defined in each project's ProjectFinance struct.
    /// Projects can be updated to this value by calling the
    /// `syncProviderSecondaryForProjectToDefaults` function for each project.
    uint256 public defaultPlatformProviderSecondarySalesBPS;
    /// -----------------------------------------------------------------------

    /// single minter allowed for this core contract
    address public minterContract;

    /// starting (initial) project ID on this contract configured
    /// at time of deployment and intended to be immutable after initialization.
    /// Not marked as immutable due to initialization requirements
    /// under the ERC-1167 minimal proxy pattern, which necessitates
    /// setting this value post-deployment.
    uint256 public startingProjectId;

    /// next project ID to be created
    uint248 private _nextProjectId;

    /// bool indicating if adding new projects is forbidden;
    /// default behavior is to allow new projects
    bool public newProjectsForbidden;

    /// configuration variable set at time of deployment, intended to be
    /// immutable after initialization, that determines whether or not
    /// admin approval^ should be required to accept artist address change
    /// proposals, or if these proposals should always auto-approve, as
    /// determined by the business process requirements of the Engine
    /// partner using this contract.
    ///
    /// ^does not apply in the case where contract-ownership itself is revoked
    /// Not marked as immutable due to initialization requirements
    /// under the ERC-1167 minimal proxy pattern, which necessitates
    /// setting this value post-deployment.
    bool public autoApproveArtistSplitProposals;

    /// configuration variable set at time of deployment, intended to be
    /// immutable after initialization, that determines if platform provider
    /// fees and addresses are always required to be set to zero.
    /// Not marked as immutable due to initialization requirements
    /// under the ERC-1167 minimal proxy pattern, which necessitates
    /// setting this value post-deployment.
    bool public nullPlatformProvider;

    /// configuration variable set at time of deployment, intended to be
    /// immutable after initialization, that determines if artists are allowed
    /// to activate their own projects.
    /// Not marked as immutable due to initialization requirements
    /// under the ERC-1167 minimal proxy pattern, which necessitates
    /// setting this value post-deployment.
    bool public allowArtistProjectActivation;

    /// version & type of this core contract
    bytes32 constant CORE_VERSION = "v3.2.4";

    function coreVersion() external pure returns (string memory) {
        return CORE_VERSION.toString();
    }

    bytes32 constant CORE_TYPE = "GenArt721CoreV3_Engine";

    function coreType() external pure returns (string memory) {
        return CORE_TYPE.toString();
    }

    /// default base URI to initialize all new project projectBaseURI values to
    string public defaultBaseURI;

    // ERC2981 royalty support and default royalty values
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint8 private constant _DEFAULT_ARTIST_SECONDARY_ROYALTY_PERCENTAGE = 5;

    // royalty split provider
    ISplitProviderV0 public splitProvider;

    // bytecode storage reader contract; may be universal or specific version reader contract
    IBytecodeStorageReader_Base public bytecodeStorageReaderContract;

    /**
     * @dev This constructor sets the owner to a non-functional address as a formality.
     * It is only ever ran on the implementation contract. The `Ownable` constructor is
     * called to satisfy the contract's inheritance requirements. This owner has no
     * operational significance and should not be considered secure or meaningful.
     * The true ownership will be set in the `initialize` function post-deployment to
     * ensure correct owner management in the proxy architecture.
     * Explicitly setting the owner to '0xdead' to indicate non-operational use.
     */
    constructor() Ownable(0x000000000000000000000000000000000000dEaD) {}

    function _onlyNonZeroAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert GenArt721Error(ErrorCodes.OnlyNonZeroAddress);
        }
    }

    function _onlyNonEmptyString(string memory _string) internal pure {
        if (bytes(_string).length == 0) {
            revert GenArt721Error(ErrorCodes.OnlyNonEmptyString);
        }
    }

    function _onlyNonEmptyBytes(bytes memory _bytes) internal pure {
        if (_bytes.length == 0) {
            revert GenArt721Error(ErrorCodes.OnlyNonEmptyBytes);
        }
    }

    function _onlyValidTokenId(uint256 _tokenId) internal view {
        if (_ownerOf(_tokenId) == address(0)) {
            revert GenArt721Error(ErrorCodes.TokenDoesNotExist);
        }
    }

    function _onlyValidProjectId(uint256 _projectId) internal view {
        if (_projectId < startingProjectId || _projectId >= _nextProjectId) {
            revert GenArt721Error(ErrorCodes.ProjectDoesNotExist);
        }
    }

    function _onlyUnlocked(uint256 _projectId) internal view {
        // Note: calling `_projectUnlocked` enforces that the `_projectId`
        //       passed in is valid.`
        if (!_projectUnlocked(_projectId)) {
            revert GenArt721Error(ErrorCodes.OnlyUnlockedProjects);
        }
    }

    function _onlyAdminACL(bytes4 _selector) internal {
        if (!adminACLAllowed(msg.sender, address(this), _selector)) {
            revert GenArt721Error(ErrorCodes.OnlyAdminACL);
        }
    }

    function _onlyArtist(uint256 _projectId) internal view {
        if (msg.sender != _projectIdToFinancials[_projectId].artistAddress) {
            revert GenArt721Error(ErrorCodes.OnlyArtist);
        }
    }

    function _onlyArtistOrAdminACL(
        uint256 _projectId,
        bytes4 _selector
    ) internal {
        if (
            !(msg.sender == _projectIdToFinancials[_projectId].artistAddress ||
                adminACLAllowed(msg.sender, address(this), _selector))
        ) {
            revert GenArt721Error(ErrorCodes.OnlyArtistOrAdminACL);
        }
    }

    /**
     * This modifier allows the artist of a project to call a function if the
     * owner of the contract has renounced ownership. This is to allow the
     * contract to continue to function if the owner decides to renounce
     * ownership.
     */
    function _onlyAdminACLOrRenouncedArtist(
        uint256 _projectId,
        bytes4 _selector
    ) internal {
        // check if Admin ACL is allowed to call this function
        if (adminACLAllowed(msg.sender, address(this), _selector)) {
            return;
        }
        // check if the owner has renounced ownership and the caller is the
        // artist of the project
        if (
            owner() == address(0) &&
            msg.sender == _projectIdToFinancials[_projectId].artistAddress
        ) {
            return;
        }
        // neither of the above conditions were met, revert
        revert GenArt721Error(ErrorCodes.OnlyAdminACLOrRenouncedArtist);
    }

    /**
     * @notice Initializes the contract with the provided `engineConfiguration`.
     * This function should be called atomically, immediately after deployment.
     * Only callable once. Validation on `engineConfiguration` is performed by caller.
     * @dev This function is intentionally unpermissioned to allow for the
     * initialization of the contract post-deployment. It is expected that this
     * function will be called atomically by the factory contract that deploys this
     * contract, after which it will be initialized and uncallable.
     * @param engineConfiguration EngineConfiguration to configure the contract with.
     * @param adminACLContract_ Address of admin access control contract, to be
     * set as contract owner.
     * @param defaultBaseURIHost Base URI prefix to initialize default base URI with.
     * @param bytecodeStorageReaderContract_ Address of the bytecode storage reader contract.
     */
    function initialize(
        EngineConfiguration memory engineConfiguration,
        address adminACLContract_,
        string memory defaultBaseURIHost,
        address bytecodeStorageReaderContract_
    ) external virtual {
        // @dev internal function call so derived contracts have access to initialization logic
        _initialize({
            engineConfiguration: engineConfiguration,
            adminACLContract_: adminACLContract_,
            defaultBaseURIHost: defaultBaseURIHost,
            bytecodeStorageReaderContract_: bytecodeStorageReaderContract_
        });
    }

    /**
     * @notice Mints a token from project `_projectId` and sets the
     * token's owner to `_to`. Hash may or may not be assigned to the token
     * during the mint transaction, depending on the randomizer contract.
     * @param _to Address to be the minted token's owner.
     * @param _projectId Project ID to mint a token on.
     * @param _by Purchaser of minted token.
     * @return _tokenId The ID of the minted token.
     * @dev sender must be the allowed minterContract
     * @dev name of function is optimized for gas usage
     */
    function mint_Ecf(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 _tokenId) {
        // CHECKS
        if (msg.sender != minterContract) {
            revert GenArt721Error(ErrorCodes.OnlyMinterContract);
        }
        Project storage project = projects[_projectId];
        // load invocations into memory
        uint24 invocationsBefore = project.invocations;
        uint24 invocationsAfter;
        unchecked {
            // invocationsBefore guaranteed <= maxInvocations <= 1_000_000,
            // 1_000_000 << max uint24, so no possible overflow
            invocationsAfter = invocationsBefore + 1;
        }
        uint24 maxInvocations = project.maxInvocations;
        if (invocationsBefore >= maxInvocations) {
            revert GenArt721Error(ErrorCodes.MaxInvocationsReached);
        }
        if (
            !(project.active ||
                _by == _projectIdToFinancials[_projectId].artistAddress)
        ) {
            revert GenArt721Error(ErrorCodes.ProjectMustExistAndBeActive);
        }
        if (
            project.paused &&
            _by != _projectIdToFinancials[_projectId].artistAddress
        ) {
            revert GenArt721Error(ErrorCodes.PurchasesPaused);
        }

        // EFFECTS
        // increment project's invocations
        project.invocations = invocationsAfter;
        uint256 thisTokenId;
        unchecked {
            // invocationsBefore is uint24 << max uint256. In production use,
            // _projectId * ONE_MILLION must be << max uint256, otherwise
            // tokenIdToProjectId function become invalid.
            // Therefore, no risk of overflow
            thisTokenId = (_projectId * ONE_MILLION) + invocationsBefore;
        }

        // mark project as completed if hit max invocations
        if (invocationsAfter == maxInvocations) {
            _completeProject(_projectId);
        }

        // INTERACTIONS
        _mint(_to, thisTokenId);

        // token hash is updated by the randomizer contract on V3
        randomizerContract.assignTokenHash(thisTokenId);

        // Do not need to also log `projectId` in event, as the `projectId` for
        // a given token can be derived from the `tokenId` with:
        //   projectId = tokenId / 1_000_000
        emit Mint(_to, thisTokenId);

        return thisTokenId;
    }

    /**
     * @notice Sets the hash seed for a given token ID `_tokenId`.
     * May only be called by the current randomizer contract.
     * May only be called for tokens that have not already been assigned a
     * non-zero hash.
     * @param _tokenId Token ID to set the hash for.
     * @param _hashSeed Hash seed to set for the token ID. Only last 12 bytes
     * will be used.
     * @dev gas-optimized function name because called during mint sequence
     * @dev if a separate event is required when the token hash is set, e.g.
     * for indexing purposes, it must be emitted by the randomizer. This is to
     * minimize gas when minting.
     */
    function setTokenHash_8PT(uint256 _tokenId, bytes32 _hashSeed) external {
        _onlyValidTokenId(_tokenId);

        OwnerAndHashSeed storage ownerAndHashSeed = _ownersAndHashSeeds[
            _tokenId
        ];
        if (msg.sender != address(randomizerContract)) {
            revert GenArt721Error(ErrorCodes.OnlyRandomizer);
        }
        if (ownerAndHashSeed.hashSeed != bytes12(0)) {
            revert GenArt721Error(ErrorCodes.TokenHashAlreadySet);
        }
        if (_hashSeed == bytes12(0)) {
            revert GenArt721Error(ErrorCodes.NoZeroHashSeed);
        }
        ownerAndHashSeed.hashSeed = bytes12(_hashSeed);
    }

    /**
     * @notice Allows owner (AdminACL) to revoke ownership of the contract.
     * Note that the contract is intended to continue to function after the
     * owner renounces ownership, but no new projects will be able to be added.
     * Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the
     * owner/AdminACL contract. The same is true for any dependent contracts
     * that also integrate with the owner/AdminACL contract (e.g. potentially
     * minter suite contracts, registry contracts, etc.).
     * After renouncing ownership, artists will be in control of updates to
     * their payment addresses and splits (see modifier
     * onlyAdminACLOrRenouncedArtist`).
     * While there is no currently intended reason to call this method based on
     * typical Engine partner business practices, this method exists to allow
     * artists to continue to maintain the limited set of contract
     * functionality that exists post-project-lock in an environment in which
     * there is no longer an admin maintaining this smart contract.
     * @dev This function is intended to be called directly by the AdminACL,
     * not by an address allowed by the AdminACL contract.
     */
    function renounceOwnership() public override onlyOwner {
        // broadcast that new projects are no longer allowed (if not already)
        _forbidNewProjects();
        // renounce ownership viw Ownable
        Ownable.renounceOwnership();
    }

    /**
     * @notice Updates reference to next core contract, associated with this contract.
     * @param _nextCoreContract Address of the next core contract
     */
    function updateNextCoreContract(address _nextCoreContract) external {
        _onlyAdminACL(this.updateNextCoreContract.selector);
        nextCoreContract = _nextCoreContract;
        emit PlatformUpdated(
            bytes32(uint256(PlatformUpdatedFields.FIELD_NEXT_CORE_CONTRACT))
        );
    }

    /**
     * @notice Updates reference to Art Blocks Dependency Registry contract.
     * @param _artblocksDependencyRegistryAddress Address of new Dependency
     * Registry.
     */
    function updateArtblocksDependencyRegistryAddress(
        address _artblocksDependencyRegistryAddress
    ) external {
        _onlyAdminACL(this.updateArtblocksDependencyRegistryAddress.selector);
        _onlyNonZeroAddress(_artblocksDependencyRegistryAddress);
        artblocksDependencyRegistryAddress = _artblocksDependencyRegistryAddress;
        emit PlatformUpdated(
            bytes32(
                uint256(
                    PlatformUpdatedFields
                        .FIELD_ARTBLOCKS_DEPENDENCY_REGISTRY_ADDRESS
                )
            )
        );
    }

    /**
     * @notice Updates reference to Art Blocks On Chain Generator contract.
     * @param _artblocksOnChainGeneratorAddress Address of new on chain generator.
     */
    function updateArtblocksOnChainGeneratorAddress(
        address _artblocksOnChainGeneratorAddress
    ) external {
        _onlyAdminACL(this.updateArtblocksOnChainGeneratorAddress.selector);
        _onlyNonZeroAddress(_artblocksOnChainGeneratorAddress);
        artblocksOnChainGeneratorAddress = _artblocksOnChainGeneratorAddress;
        emit PlatformUpdated(
            bytes32(
                uint256(
                    PlatformUpdatedFields
                        .FIELD_ARTBLOCKS_ON_CHAIN_GENERATOR_ADDRESS
                )
            )
        );
    }

    /**
     * @notice Updates sales addresses for the platform and render providers to
     * the input parameters.
     * note: This does not update splitter contracts for all projects on
     * this core contract. If updated splitter contracts are desired, they must be
     * updated after this update via the `syncProviderSecondaryForProjectToDefaults` function.
     * @param _renderProviderPrimarySalesAddress Address of new primary sales
     * payment address.
     * @param _defaultRenderProviderSecondarySalesAddress Default address of new secondary sales
     * payment address.
     * @param _platformProviderPrimarySalesAddress Address of new primary sales
     * payment address.
     * @param _defaultPlatformProviderSecondarySalesAddress Default address of new secondary sales
     * payment address.
     */
    function updateProviderSalesAddresses(
        address payable _renderProviderPrimarySalesAddress,
        address payable _defaultRenderProviderSecondarySalesAddress,
        address payable _platformProviderPrimarySalesAddress,
        address payable _defaultPlatformProviderSecondarySalesAddress
    ) external {
        _onlyAdminACL(this.updateProviderSalesAddresses.selector);
        _onlyNonZeroAddress(_renderProviderPrimarySalesAddress);
        _onlyNonZeroAddress(_defaultRenderProviderSecondarySalesAddress);
        // @dev checks on platform provider addresses performed in _updateProviderSalesAddresses
        _updateProviderSalesAddresses(
            _renderProviderPrimarySalesAddress,
            _defaultRenderProviderSecondarySalesAddress,
            _platformProviderPrimarySalesAddress,
            _defaultPlatformProviderSecondarySalesAddress
        );
    }

    /**
     * @notice Updates the render and platform provider primary sales revenue percentage to
     * the provided inputs.
     * If contract is configured to have a null platform provider, the platform provider
     * primary sales percentage must be set to zero.
     * @param renderProviderPrimarySalesPercentage_ New primary sales revenue % for the render provider
     * @param platformProviderPrimarySalesPercentage_ New primary sales revenue % for the platform provider
     * percentage.
     */
    function updateProviderPrimarySalesPercentages(
        uint256 renderProviderPrimarySalesPercentage_,
        uint256 platformProviderPrimarySalesPercentage_
    ) external {
        _onlyAdminACL(this.updateProviderPrimarySalesPercentages.selector);
        // require no platform provider payment if null platform provider
        if (
            nullPlatformProvider && platformProviderPrimarySalesPercentage_ != 0
        ) {
            revert GenArt721Error(ErrorCodes.OnlyNullPlatformProvider);
        }

        // Validate that the sum of the proposed %s, does not exceed 100%.
        if (
            (renderProviderPrimarySalesPercentage_ +
                platformProviderPrimarySalesPercentage_) > ONE_HUNDRED
        ) {
            revert GenArt721Error(ErrorCodes.OverMaxSumOfPercentages);
        }
        // Casting to `uint8` here is safe due check above, which does not allow
        // overflow as of solidity version ^0.8.0.
        _renderProviderPrimarySalesPercentage = uint8(
            renderProviderPrimarySalesPercentage_
        );
        _platformProviderPrimarySalesPercentage = uint8(
            platformProviderPrimarySalesPercentage_
        );
        emit PlatformUpdated(
            bytes32(
                uint256(
                    PlatformUpdatedFields
                        .FIELD_PROVIDER_PRIMARY_SALES_PERCENTAGES
                )
            )
        );
    }

    /**
     * @notice Updates default render and platform provider secondary sales royalty
     * Basis Points to the provided inputs.
     * If contract is configured to have a null platform provider, the platform provider
     * secondary sales BPS must be set to zero.
     * note: This does not update splitter contracts for all projects on
     * this core contract. If updated splitter contracts are desired, they must be
     * updated after this update via the `syncProviderSecondaryForProjectToDefaults` function.
     * @param _defaultRenderProviderSecondarySalesBPS New default secondary sales royalty Basis
     * points.
     * @param _defaultPlatformProviderSecondarySalesBPS New default secondary sales royalty Basis
     * points.
     * @dev Due to secondary royalties being ultimately enforced via social
     * consensus, no hard upper limit is imposed on the BPS value, other than
     * <= 100% royalty, which would not make mathematical sense. Realistically,
     * changing this value is expected to either never occur, or be a rare
     * occurrence.
     */
    function updateProviderDefaultSecondarySalesBPS(
        uint256 _defaultRenderProviderSecondarySalesBPS,
        uint256 _defaultPlatformProviderSecondarySalesBPS
    ) external {
        _onlyAdminACL(this.updateProviderDefaultSecondarySalesBPS.selector);
        // require no platform provider payment if null platform provider
        if (
            nullPlatformProvider &&
            _defaultPlatformProviderSecondarySalesBPS != 0
        ) {
            revert GenArt721Error(ErrorCodes.OnlyNullPlatformProvider);
        }
        // Validate that the sum of the proposed provider BPS, does not exceed 10_000 BPS.
        if (
            _defaultRenderProviderSecondarySalesBPS +
                _defaultPlatformProviderSecondarySalesBPS >
            MAX_PROVIDER_SECONDARY_SALES_BPS
        ) {
            revert GenArt721Error(ErrorCodes.OverMaxSumOfBPS);
        }
        defaultRenderProviderSecondarySalesBPS = _defaultRenderProviderSecondarySalesBPS;
        defaultPlatformProviderSecondarySalesBPS = _defaultPlatformProviderSecondarySalesBPS;
        emit PlatformUpdated(
            bytes32(
                uint256(
                    PlatformUpdatedFields.FIELD_PROVIDER_SECONDARY_SALES_BPS
                )
            )
        );
    }

    /**
     * @notice Updates minter to `_address`.
     * @param _address Address of new minter.
     */
    function updateMinterContract(address _address) external {
        _onlyAdminACL(this.updateMinterContract.selector);
        _onlyNonZeroAddress(_address);
        _updateMinterContract(_address);
    }

    /**
     * @notice Updates randomizer to `_randomizerAddress`.
     * @param _randomizerAddress Address of new randomizer.
     */
    function updateRandomizerAddress(address _randomizerAddress) external {
        _onlyAdminACL(this.updateRandomizerAddress.selector);
        _onlyNonZeroAddress(_randomizerAddress);
        _updateRandomizerAddress(_randomizerAddress);
    }

    /**
     * @notice Updates split provider address to `_splitProviderAddress`.
     * Reverts if `_splitProviderAddress` is zero address.
     * @param _splitProviderAddress New split provider address.
     */
    function updateSplitProvider(address _splitProviderAddress) external {
        _onlyAdminACL(this.updateSplitProvider.selector);
        _updateSplitProvider(_splitProviderAddress);
    }

    /**
     * @notice Updates bytecode storage reader contract to `_bytecodeStorageReaderContract`.
     * Reverts if `_bytecodeStorageReaderContract` is zero address.
     * Updating the active Bytecode Storage Reader contract may affect the ability to read
     * data related to existing projects. Care should be taken to ensure that the new
     * contract is compatible with the existing project data.
     * @param _bytecodeStorageReaderContract New bytecode storage reader contract address.
     */
    function updateBytecodeStorageReaderContract(
        address _bytecodeStorageReaderContract
    ) external {
        _onlyAdminACL(this.updateBytecodeStorageReaderContract.selector);
        _onlyNonZeroAddress(_bytecodeStorageReaderContract);
        _updateBytecodeStorageReaderContract(_bytecodeStorageReaderContract);
    }

    /**
     * @notice Toggles project `_projectId` as active/inactive.
     * @param _projectId Project ID to be toggled.
     */
    function toggleProjectIsActive(uint256 _projectId) external {
        if (allowArtistProjectActivation) {
            _onlyArtistOrAdminACL(
                _projectId,
                this.toggleProjectIsActive.selector
            );
        } else {
            _onlyAdminACL(this.toggleProjectIsActive.selector);
        }
        _onlyValidProjectId(_projectId);
        projects[_projectId].active = !projects[_projectId].active;
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_ACTIVE))
        );
    }

    /**
     * @notice Artist proposes updated set of artist address, additional payee
     * addresses, and percentage splits for project `_projectId`. Addresses and
     * percentages do not have to all be changed, but they must all be defined
     * as a complete set.
     * Note that if the artist is only proposing a change to the payee percentage
     * splits, without modifying the payee addresses, the proposal will be
     * automatically approved and the new splits will become active immediately.
     * Automatic approval will also be granted if the artist is only removing
     * additional payee addresses, without adding any new ones.
     * Also note that if `autoApproveArtistSplitProposals` is true, proposals
     * will always be auto-approved, regardless of what is being changed.
     * Also note that if the artist is proposing sending funds to the zero
     * address, this function will revert and the proposal will not be created.
     * @param _projectId Project ID.
     * @param _artistAddress Artist address that controls the project, and may
     * receive payments.
     * @param _additionalPayeePrimarySales Address that may receive a
     * percentage split of the artist's primary sales revenue.
     * @param _additionalPayeePrimarySalesPercentage Percent of artist's
     * portion of primary sale revenue that will be split to address
     * `_additionalPayeePrimarySales`.
     * @param _additionalPayeeSecondarySales Address that may receive a percentage
     * split of the secondary sales royalties.
     * @param _additionalPayeeSecondarySalesPercentage Percent of artist's portion
     * of secondary sale royalties that will be split to address
     * `_additionalPayeeSecondarySales`.
     * @dev `_artistAddress` must be a valid address (non-zero-address), but it
     * is intentionally allowable for `_additionalPayee{Primary,Secondaary}Sales`
     * and their associated percentages to be zero'd out by the controlling artist.
     */
    function proposeArtistPaymentAddressesAndSplits(
        uint256 _projectId,
        address payable _artistAddress,
        address payable _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address payable _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    ) external {
        _onlyValidProjectId(_projectId);
        _onlyArtist(_projectId);
        _onlyNonZeroAddress(_artistAddress);
        ProjectFinance storage projectFinance = _projectIdToFinancials[
            _projectId
        ];
        // checks
        if (
            _additionalPayeePrimarySalesPercentage > ONE_HUNDRED ||
            _additionalPayeeSecondarySalesPercentage > ONE_HUNDRED
        ) {
            revert GenArt721Error(ErrorCodes.MaxOf100Percent);
        }
        if (
            _additionalPayeePrimarySalesPercentage > 0 &&
            _additionalPayeePrimarySales == address(0)
        ) {
            revert GenArt721Error(ErrorCodes.PrimaryPayeeIsZeroAddress);
        }
        if (
            _additionalPayeeSecondarySalesPercentage > 0 &&
            _additionalPayeeSecondarySales == address(0)
        ) {
            revert GenArt721Error(ErrorCodes.SecondaryPayeeIsZeroAddress);
        }
        // effects
        // emit event for off-chain indexing
        // note: always emit a proposal event, even in the pathway of
        // automatic approval, to simplify indexing expectations
        emit ProposedArtistAddressesAndSplits(
            _projectId,
            _artistAddress,
            _additionalPayeePrimarySales,
            _additionalPayeePrimarySalesPercentage,
            _additionalPayeeSecondarySales,
            _additionalPayeeSecondarySalesPercentage
        );
        // automatically accept if no proposed addresses modifications, or if
        // the proposal only removes payee addresses, or if contract is set to
        // always auto-approve.
        // store proposal hash on-chain, only if not automatic accept
        bool automaticAccept = autoApproveArtistSplitProposals;
        if (!automaticAccept) {
            // block scope to avoid stack too deep error
            bool artistUnchanged = _artistAddress ==
                projectFinance.artistAddress;
            bool additionalPrimaryUnchangedOrRemoved = (_additionalPayeePrimarySales ==
                    projectFinance.additionalPayeePrimarySales) ||
                    (_additionalPayeePrimarySales == address(0));
            bool additionalSecondaryUnchangedOrRemoved = (_additionalPayeeSecondarySales ==
                    projectFinance.additionalPayeeSecondarySales) ||
                    (_additionalPayeeSecondarySales == address(0));
            automaticAccept =
                artistUnchanged &&
                additionalPrimaryUnchangedOrRemoved &&
                additionalSecondaryUnchangedOrRemoved;
        }
        if (automaticAccept) {
            // clear any previously proposed values
            proposedArtistAddressesAndSplitsHash[_projectId] = bytes32(0);

            // update storage
            // artist address can change during automatic accept if
            // autoApproveArtistSplitProposals is true
            projectFinance.artistAddress = _artistAddress;
            projectFinance
                .additionalPayeePrimarySales = _additionalPayeePrimarySales;
            // safe to cast as uint8 as max is 100%, max uint8 is 255
            projectFinance.additionalPayeePrimarySalesPercentage = uint8(
                _additionalPayeePrimarySalesPercentage
            );
            projectFinance
                .additionalPayeeSecondarySales = _additionalPayeeSecondarySales;
            // safe to cast as uint8 as max is 100%, max uint8 is 255
            projectFinance.additionalPayeeSecondarySalesPercentage = uint8(
                _additionalPayeeSecondarySalesPercentage
            );

            // assign project's splitter
            // @dev only call after all previous storage updates
            _assignSplitter(_projectId);

            // emit event for off-chain indexing
            emit AcceptedArtistAddressesAndSplits(_projectId);
        } else {
            proposedArtistAddressesAndSplitsHash[_projectId] = keccak256(
                abi.encode(
                    _artistAddress,
                    _additionalPayeePrimarySales,
                    _additionalPayeePrimarySalesPercentage,
                    _additionalPayeeSecondarySales,
                    _additionalPayeeSecondarySalesPercentage
                )
            );
        }
    }

    /**
     * @notice Admin accepts a proposed set of updated artist address,
     * additional payee addresses, and percentage splits for project
     * `_projectId`. Addresses and percentages do not have to all be changed,
     * but they must all be defined as a complete set.
     * @param _projectId Project ID.
     * @param _artistAddress Artist address that controls the project, and may
     * receive payments.
     * @param _additionalPayeePrimarySales Address that may receive a
     * percentage split of the artist's primary sales revenue.
     * @param _additionalPayeePrimarySalesPercentage Percent of artist's
     * portion of primary sale revenue that will be split to address
     * `_additionalPayeePrimarySales`.
     * @param _additionalPayeeSecondarySales Address that may receive a percentage
     * split of the secondary sales royalties.
     * @param _additionalPayeeSecondarySalesPercentage Percent of artist's portion
     * of secondary sale royalties that will be split to address
     * `_additionalPayeeSecondarySales`.
     * @dev this must be called by the Admin ACL contract, and must only accept
     * the most recent proposed values for a given project (validated on-chain
     * by comparing the hash of the proposed and accepted values).
     * @dev `_artistAddress` must be a valid address (non-zero-address), but it
     * is intentionally allowable for `_additionalPayee{Primary,Secondaary}Sales`
     * and their associated percentages to be zero'd out by the controlling artist.
     */
    function adminAcceptArtistAddressesAndSplits(
        uint256 _projectId,
        address payable _artistAddress,
        address payable _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address payable _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    ) external {
        _onlyValidProjectId(_projectId);
        _onlyAdminACLOrRenouncedArtist(
            _projectId,
            this.adminAcceptArtistAddressesAndSplits.selector
        );
        _onlyNonZeroAddress(_artistAddress);
        // checks
        if (
            proposedArtistAddressesAndSplitsHash[_projectId] !=
            keccak256(
                abi.encode(
                    _artistAddress,
                    _additionalPayeePrimarySales,
                    _additionalPayeePrimarySalesPercentage,
                    _additionalPayeeSecondarySales,
                    _additionalPayeeSecondarySalesPercentage
                )
            )
        ) {
            revert GenArt721Error(ErrorCodes.MustMatchArtistProposal);
        }
        // effects
        ProjectFinance storage projectFinance = _projectIdToFinancials[
            _projectId
        ];
        projectFinance.artistAddress = _artistAddress;
        projectFinance
            .additionalPayeePrimarySales = _additionalPayeePrimarySales;
        projectFinance.additionalPayeePrimarySalesPercentage = uint8(
            _additionalPayeePrimarySalesPercentage
        );
        projectFinance
            .additionalPayeeSecondarySales = _additionalPayeeSecondarySales;
        projectFinance.additionalPayeeSecondarySalesPercentage = uint8(
            _additionalPayeeSecondarySalesPercentage
        );
        // clear proposed values
        proposedArtistAddressesAndSplitsHash[_projectId] = bytes32(0);

        // assign project's splitter
        // @dev only call after all previous storage updates
        _assignSplitter(_projectId);

        // emit event for off-chain indexing
        emit AcceptedArtistAddressesAndSplits(_projectId);
    }

    /**
     * @notice Updates artist of project `_projectId` to `_artistAddress`.
     * This is to only be used in the event that the artist address is
     * compromised or sanctioned.
     * @param _projectId Project ID.
     * @param _artistAddress New artist address.
     */
    function updateProjectArtistAddress(
        uint256 _projectId,
        address payable _artistAddress
    ) external {
        _onlyValidProjectId(_projectId);
        _onlyAdminACLOrRenouncedArtist(
            _projectId,
            this.updateProjectArtistAddress.selector
        );
        _onlyNonZeroAddress(_artistAddress);

        _projectIdToFinancials[_projectId].artistAddress = _artistAddress;

        // assign project's splitter
        // @dev only call after all previous storage updates
        _assignSplitter(_projectId);

        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_ARTIST_ADDRESS))
        );
    }

    /**
     * @notice Toggles paused state of project `_projectId`.
     * @param _projectId Project ID to be toggled.
     */
    function toggleProjectIsPaused(uint256 _projectId) external {
        _onlyArtist(_projectId);
        projects[_projectId].paused = !projects[_projectId].paused;
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_PAUSED))
        );
    }

    /**
     * @notice Adds new project `_projectName` by `_artistAddress`.
     * @param _projectName Project name.
     * @param _artistAddress Artist's address.
     * @dev token price now stored on minter
     */
    function addProject(
        string memory _projectName,
        address payable _artistAddress
    ) external {
        _onlyAdminACL(this.addProject.selector);
        _onlyNonEmptyString(_projectName);
        _onlyNonZeroAddress(_artistAddress);
        if (newProjectsForbidden) {
            revert GenArt721Error(ErrorCodes.NewProjectsForbidden);
        }
        uint256 projectId = _nextProjectId;
        ProjectFinance storage projectFinance = _projectIdToFinancials[
            projectId
        ];
        projectFinance.artistAddress = _artistAddress;
        projects[projectId].name = _projectName;
        projects[projectId].paused = true;
        projects[projectId].maxInvocations = ONE_MILLION_UINT24;
        projects[projectId].projectBaseURI = defaultBaseURI;
        // assign default artist royalty to artist
        projectFinance
            .secondaryMarketRoyaltyPercentage = _DEFAULT_ARTIST_SECONDARY_ROYALTY_PERCENTAGE;
        // copy default platform and render provider royalties to ProjectFinance
        projectFinance
            .platformProviderSecondarySalesAddress = defaultPlatformProviderSecondarySalesAddress;
        projectFinance.platformProviderSecondarySalesBPS = uint16(
            defaultPlatformProviderSecondarySalesBPS
        );
        projectFinance
            .renderProviderSecondarySalesAddress = defaultRenderProviderSecondarySalesAddress;
        projectFinance.renderProviderSecondarySalesBPS = uint16(
            defaultRenderProviderSecondarySalesBPS
        );

        _nextProjectId = uint248(projectId) + 1;

        // @dev emit initial project created event before splitter event
        emit ProjectUpdated(
            projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_CREATED))
        );

        // assign project's splitter
        // @dev only call after all previous storage updates
        _assignSplitter(projectId);
    }

    /**
     * @notice Forever forbids new projects from being added to this contract.
     */
    function forbidNewProjects() external {
        _onlyAdminACL(this.forbidNewProjects.selector);
        if (newProjectsForbidden) {
            revert GenArt721Error(ErrorCodes.NewProjectsAlreadyForbidden);
        }
        _forbidNewProjects();
    }

    /**
     * @notice Updates name of project `_projectId` to be `_projectName`.
     * @param _projectId Project ID.
     * @param _projectName New project name.
     */
    function updateProjectName(
        uint256 _projectId,
        string memory _projectName
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(_projectId, this.updateProjectName.selector);
        _onlyNonEmptyString(_projectName);
        projects[_projectId].name = _projectName;
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_NAME))
        );
    }

    /**
     * @notice Updates artist name for project `_projectId` to be
     * `_projectArtistName`.
     * @dev allows admin to update after project is locked, due to our
     * experiences of artist name changes being requested post-lock.
     * @param _projectId Project ID.
     * @param _projectArtistName New artist name.
     */
    function updateProjectArtistName(
        uint256 _projectId,
        string memory _projectArtistName
    ) external {
        // if unlocked, only artist may update, if locked, only admin may update
        // @dev valid project checked in _projectUnlocked function
        if (_projectUnlocked(_projectId)) {
            if (
                msg.sender != _projectIdToFinancials[_projectId].artistAddress
            ) {
                revert GenArt721Error(ErrorCodes.OnlyArtistOrAdminIfLocked);
            }
        } else {
            if (
                !adminACLAllowed(
                    msg.sender,
                    address(this),
                    this.updateProjectArtistName.selector
                )
            ) {
                revert GenArt721Error(ErrorCodes.OnlyArtistOrAdminIfLocked);
            }
        }
        _onlyNonEmptyString(_projectArtistName);
        projects[_projectId].artist = _projectArtistName;
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_ARTIST_NAME))
        );
    }

    /**
     * @notice Updates artist secondary market royalties for project
     * `_projectId` to be `_secondaryMarketRoyalty` percent.
     * This deploys a new splitter contract if needed.
     * This DOES NOT include the secondary market royalty percentages collected
     * by the issuing platform; it is only the total percentage of royalties
     * that will be split to artist and additionalSecondaryPayee.
     * @param _projectId Project ID.
     * @param _secondaryMarketRoyalty Percent of secondary sales revenue that will
     * be split to artist and additionalSecondaryPayee. This must be less than
     * or equal to ARTIST_MAX_SECONDARY_ROYALTY_PERCENTAGE percent.
     */
    function updateProjectSecondaryMarketRoyaltyPercentage(
        uint256 _projectId,
        uint256 _secondaryMarketRoyalty
    ) external {
        _onlyArtist(_projectId);
        if (_secondaryMarketRoyalty > ARTIST_MAX_SECONDARY_ROYALTY_PERCENTAGE) {
            revert GenArt721Error(ErrorCodes.OverMaxSecondaryRoyaltyPercentage);
        }
        _projectIdToFinancials[_projectId]
            .secondaryMarketRoyaltyPercentage = uint8(_secondaryMarketRoyalty);

        // assign project's splitter
        // @dev only call after all previous storage updates
        _assignSplitter(_projectId);

        emit ProjectUpdated(
            _projectId,
            bytes32(
                uint256(
                    ProjectUpdatedFields
                        .FIELD_PROJECT_SECONDARY_MARKET_ROYALTY_PERCENTAGE
                )
            )
        );
    }

    /**
     * @notice Updates platform and render provider secondary market royalty addresses
     * and BPS to the contract-level default values for project `_projectId`.
     * This updates the splitter parameters on the existing splitter for the project.
     * Reverts if called by a non-admin address.
     * @param _projectId Project ID.
     */
    function syncProviderSecondaryForProjectToDefaults(
        uint256 _projectId
    ) external {
        _onlyAdminACL(this.syncProviderSecondaryForProjectToDefaults.selector);
        _onlyValidProjectId(_projectId);
        ProjectFinance storage projectFinance = _projectIdToFinancials[
            _projectId
        ];
        // update project finance for project in storage
        projectFinance
            .platformProviderSecondarySalesAddress = defaultPlatformProviderSecondarySalesAddress;
        projectFinance.platformProviderSecondarySalesBPS = uint16(
            defaultPlatformProviderSecondarySalesBPS
        );
        projectFinance
            .renderProviderSecondarySalesAddress = defaultRenderProviderSecondarySalesAddress;
        projectFinance.renderProviderSecondarySalesBPS = uint16(
            defaultRenderProviderSecondarySalesBPS
        );

        emit ProjectUpdated(
            _projectId,
            bytes32(
                uint256(
                    ProjectUpdatedFields
                        .FIELD_PROJECT_PROVIDER_SECONDARY_FINANCIALS
                )
            )
        );

        // assign project's splitter
        // @dev only call after all previous storage updates
        _assignSplitter(_projectId);
    }

    /**
     * @notice Updates description of project `_projectId`.
     * Only artist may call when unlocked, only admin may call when locked.
     * Note: The BytecodeStorage library is used to store the description to
     * reduce initial upload cost, however, even minor edits will require an
     * expensive, entirely new bytecode storage contract to be deployed instead
     * of relatively cheap updates to already-warm storage slots. This results
     * in an increased gas cost for minor edits to the description after the
     * initial upload, but an overall decrease in gas cost for projects with
     * less than ~3-5 edits (depending on the length of the description).
     * @param _projectId Project ID.
     * @param _projectDescription New project description.
     */
    function updateProjectDescription(
        uint256 _projectId,
        string memory _projectDescription
    ) external {
        // checks
        // if unlocked, only artist may update, if locked, only admin may update
        if (_projectUnlocked(_projectId)) {
            if (
                msg.sender != _projectIdToFinancials[_projectId].artistAddress
            ) {
                revert GenArt721Error(ErrorCodes.OnlyArtistOrAdminIfLocked);
            }
        } else {
            if (
                !adminACLAllowed(
                    msg.sender,
                    address(this),
                    this.updateProjectDescription.selector
                )
            ) {
                revert GenArt721Error(ErrorCodes.OnlyArtistOrAdminIfLocked);
            }
        }
        // effects
        // store description in contract bytecode, replacing reference address from
        // the old storage description with the newly created one
        projects[_projectId].descriptionAddress = _projectDescription
            .writeToBytecode();
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_DESCRIPTION))
        );
    }

    /**
     * @notice Updates website of project `_projectId` to be `_projectWebsite`.
     * @param _projectId Project ID.
     * @param _projectWebsite New project website.
     * @dev It is intentionally allowed for this to be set to the empty string.
     */
    function updateProjectWebsite(
        uint256 _projectId,
        string memory _projectWebsite
    ) external {
        _onlyArtist(_projectId);
        projects[_projectId].website = _projectWebsite;
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_WEBSITE))
        );
    }

    /**
     * @notice Updates license for project `_projectId`.
     * @param _projectId Project ID.
     * @param _projectLicense New project license.
     */
    function updateProjectLicense(
        uint256 _projectId,
        string memory _projectLicense
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(_projectId, this.updateProjectLicense.selector);
        _onlyNonEmptyString(_projectLicense);
        projects[_projectId].license = _projectLicense;
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_LICENSE))
        );
    }

    /**
     * @notice Updates maximum invocations for project `_projectId` to
     * `_maxInvocations`. Maximum invocations may only be decreased by the
     * artist, and must be greater than or equal to current invocations.
     * New projects are created with maximum invocations of 1 million by
     * default.
     * @param _projectId Project ID.
     * @param _maxInvocations New maximum invocations.
     */
    function updateProjectMaxInvocations(
        uint256 _projectId,
        uint24 _maxInvocations
    ) external {
        _onlyArtist(_projectId);
        // CHECKS
        Project storage project = projects[_projectId];
        uint256 _invocations = project.invocations;
        if (_maxInvocations >= project.maxInvocations) {
            revert GenArt721Error(ErrorCodes.OnlyMaxInvocationsDecrease);
        }
        if (_maxInvocations < _invocations) {
            revert GenArt721Error(ErrorCodes.OnlyGteInvocations);
        }
        // EFFECTS
        project.maxInvocations = _maxInvocations;
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_MAX_INVOCATIONS))
        );

        // register completed timestamp if action completed the project
        if (_maxInvocations == _invocations) {
            _completeProject(_projectId);
        }
    }

    /**
     * @notice Adds a script to project `_projectId`.
     * @param _projectId Project to be updated.
     * @param _script Script to be added. Required to be a non-empty string,
     * but no further validation is performed.
     */
    function addProjectScript(
        uint256 _projectId,
        string memory _script
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(_projectId, this.addProjectScript.selector);
        _onlyNonEmptyString(_script);
        Project storage project = projects[_projectId];
        // store script in contract bytecode
        project.scriptBytecodeAddresses[project.scriptCount] = _script
            .writeToBytecode();
        project.scriptCount = project.scriptCount + 1;
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_SCRIPT))
        );
    }

    /**
     * @notice Adds a pre-compressed script to project `_projectId`. The script
     * should be compressed using `getCompressed`. This function stores the script
     * in a compressed format on-chain. For reads, the compressed script is
     * decompressed on-chain, ensuring the original text is reconstructed without
     * external dependencies.
     * @param _projectId Project to be updated.
     * @param _compressedScript Pre-compressed script to be added.
     * Required to be non-empty, but no further validation is performed.
     */
    function addProjectScriptCompressed(
        uint256 _projectId,
        bytes memory _compressedScript
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(
            _projectId,
            this.addProjectScriptCompressed.selector
        );
        _onlyNonEmptyBytes(_compressedScript);
        Project storage project = projects[_projectId];
        // store compressed script in contract bytecode
        project.scriptBytecodeAddresses[project.scriptCount] = _compressedScript
            .writeToBytecodeCompressed();
        project.scriptCount = project.scriptCount + 1;
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_SCRIPT))
        );
    }

    /**
     * @notice Updates script for project `_projectId` at script ID `_scriptId`.
     * @param _projectId Project to be updated.
     * @param _scriptId Script ID to be updated.
     * @param _script The updated script value. Required to be a non-empty
     *                string, but no further validation is performed.
     */
    function updateProjectScript(
        uint256 _projectId,
        uint256 _scriptId,
        string memory _script
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(_projectId, this.updateProjectScript.selector);
        _onlyNonEmptyString(_script);
        Project storage project = projects[_projectId];
        if (_scriptId >= project.scriptCount) {
            revert GenArt721Error(ErrorCodes.ScriptIdOutOfRange);
        }
        // store script in contract bytecode, replacing reference address from
        // the old storage contract with the newly created one
        project.scriptBytecodeAddresses[_scriptId] = _script.writeToBytecode();
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_SCRIPT))
        );
    }

    /**
     * @notice Updates script for project `_projectId` at script ID `_scriptId`
     * with a pre-compressed script. The script should be compressed using
     * `getCompressed`. This function stores the script in a compressed format
     * on-chain. For reads, the compressed script is decompressed on-chain, ensuring
     * the original text is reconstructed without external dependencies.
     * @param _projectId Project to be updated.
     * @param _scriptId Script ID to be updated.
     * @param _compressedScript The updated pre-compressed script value.
     * Required to be non-empty, but no further validation is performed.
     */
    function updateProjectScriptCompressed(
        uint256 _projectId,
        uint256 _scriptId,
        bytes memory _compressedScript
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(
            _projectId,
            this.updateProjectScriptCompressed.selector
        );
        _onlyNonEmptyBytes(_compressedScript);
        Project storage project = projects[_projectId];
        if (_scriptId >= project.scriptCount) {
            revert GenArt721Error(ErrorCodes.ScriptIdOutOfRange);
        }
        // store script in contract bytecode, replacing reference address from
        // the old storage contract with the newly created one
        project.scriptBytecodeAddresses[_scriptId] = _compressedScript
            .writeToBytecodeCompressed();
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_SCRIPT))
        );
    }

    /**
     * @notice Removes last script from project `_projectId`.
     * @param _projectId Project to be updated.
     */
    function removeProjectLastScript(uint256 _projectId) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(
            _projectId,
            this.removeProjectLastScript.selector
        );
        Project storage project = projects[_projectId];
        if (project.scriptCount == 0) {
            revert GenArt721Error(ErrorCodes.NoScriptsToRemove);
        }
        // delete reference to old storage contract address
        delete project.scriptBytecodeAddresses[project.scriptCount - 1];
        unchecked {
            project.scriptCount = project.scriptCount - 1;
        }
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_SCRIPT))
        );
    }

    /**
     * @notice Updates script type for project `_projectId`.
     * @param _projectId Project to be updated.
     * @param _scriptTypeAndVersion Script type and version e.g. "[email protected]",
     * as bytes32 encoded string.
     */
    function updateProjectScriptType(
        uint256 _projectId,
        bytes32 _scriptTypeAndVersion
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(
            _projectId,
            this.updateProjectScriptType.selector
        );
        Project storage project = projects[_projectId];
        // require exactly one @ symbol in _scriptTypeAndVersion
        if (
            !_scriptTypeAndVersion.containsExactCharacterQty(
                AT_CHARACTER_CODE,
                uint8(1)
            )
        ) {
            revert GenArt721Error(ErrorCodes.ScriptTypeAndVersionFormat);
        }
        project.scriptTypeAndVersion = _scriptTypeAndVersion;
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_SCRIPT_TYPE))
        );
    }

    /**
     * @notice Updates project's aspect ratio.
     * @param _projectId Project to be updated.
     * @param _aspectRatio Aspect ratio to be set. Intended to be string in the
     * format of a decimal, e.g. "1" for square, "1.77777778" for 16:9, etc.,
     * allowing for a maximum of 10 digits and one (optional) decimal separator.
     */
    function updateProjectAspectRatio(
        uint256 _projectId,
        string memory _aspectRatio
    ) external {
        _onlyUnlocked(_projectId);
        _onlyArtistOrAdminACL(
            _projectId,
            this.updateProjectAspectRatio.selector
        );
        _onlyNonEmptyString(_aspectRatio);
        // Perform more detailed input validation for aspect ratio.
        bytes memory aspectRatioBytes = bytes(_aspectRatio);
        uint256 bytesLength = aspectRatioBytes.length;
        if (bytesLength > 11) {
            revert GenArt721Error(ErrorCodes.AspectRatioTooLong);
        }
        bool hasSeenDecimalSeparator = false;
        bool hasSeenNumber = false;
        for (uint256 i; i < bytesLength; i++) {
            bytes1 character = aspectRatioBytes[i];
            // Allow as many #s as desired.
            if (character >= 0x30 && character <= 0x39) {
                // 9-0
                // We need to ensure there is at least 1 `9-0` occurrence.
                hasSeenNumber = true;
                continue;
            }
            if (character == 0x2E) {
                // .
                // Allow no more than 1 `.` occurrence.
                if (!hasSeenDecimalSeparator) {
                    hasSeenDecimalSeparator = true;
                    continue;
                }
            }
            revert GenArt721Error(ErrorCodes.AspectRatioImproperFormat);
        }
        if (!hasSeenNumber) {
            revert GenArt721Error(ErrorCodes.AspectRatioNoNumbers);
        }

        projects[_projectId].aspectRatio = _aspectRatio;
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_ASPECT_RATIO))
        );
    }

    /**
     * @notice Updates base URI for project `_projectId` to `_newBaseURI`.
     * This is the controlling base URI for all tokens in the project. The
     * contract-level defaultBaseURI is only used when initializing new
     * projects.
     * @param _projectId Project to be updated.
     * @param _newBaseURI New base URI.
     */
    function updateProjectBaseURI(
        uint256 _projectId,
        string memory _newBaseURI
    ) external {
        _onlyArtist(_projectId);
        _onlyNonEmptyString(_newBaseURI);
        projects[_projectId].projectBaseURI = _newBaseURI;
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_BASE_URI))
        );
    }

    /**
     * @notice Updates default base URI to `_defaultBaseURI`. The
     * contract-level defaultBaseURI is only used when initializing new
     * projects. Token URIs are determined by their project's `projectBaseURI`.
     * @param _defaultBaseURI New default base URI.
     */
    function updateDefaultBaseURI(string memory _defaultBaseURI) external {
        _onlyAdminACL(this.updateDefaultBaseURI.selector);
        _onlyNonEmptyString(_defaultBaseURI);
        _updateDefaultBaseURI(_defaultBaseURI);
    }

    /**
     * @notice Next project ID to be created on this contract.
     * @return uint256 Next project ID.
     */
    function nextProjectId() external view returns (uint256) {
        return _nextProjectId;
    }

    /**
     * @notice Returns token hash for token ID `_tokenId`. Returns null if hash
     * has not been set.
     * @param _tokenId Token ID to be queried.
     * @return bytes32 Token hash.
     * @dev token hash is the keccak256 hash of the stored hash seed
     */
    function tokenIdToHash(uint256 _tokenId) external view returns (bytes32) {
        bytes12 _hashSeed = _ownersAndHashSeeds[_tokenId].hashSeed;
        if (_hashSeed == 0) {
            return 0;
        }
        return keccak256(abi.encode(_hashSeed));
    }

    /**
     * @notice Returns token hash **seed** for token ID `_tokenId`. Returns
     * null if hash seed has not been set. The hash seed id the bytes12 value
     * which is hashed to produce the token hash.
     * @param _tokenId Token ID to be queried.
     * @return bytes12 Token hash seed.
     * @dev token hash seed is keccak256 hashed to give the token hash
     */
    function tokenIdToHashSeed(
        uint256 _tokenId
    ) external view returns (bytes12) {
        return _ownersAndHashSeeds[_tokenId].hashSeed;
    }

    /**
     * @notice View function returning the render provider portion of
     * primary sales, in percent.
     * @return uint256 The render provider portion of primary sales,
     * in percent.
     */
    function renderProviderPrimarySalesPercentage()
        external
        view
        returns (uint256)
    {
        return _renderProviderPrimarySalesPercentage;
    }

    /**
     * @notice View function returning the platform provider portion of
     * primary sales, in percent.
     * @return uint256 The platform provider portion of primary sales,
     * in percent.
     */
    function platformProviderPrimarySalesPercentage()
        external
        view
        returns (uint256)
    {
        return _platformProviderPrimarySalesPercentage;
    }

    /**
     * @notice View function returning Artist's address for project
     * `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return address Artist's address.
     */
    function projectIdToArtistAddress(
        uint256 _projectId
    ) external view returns (address payable) {
        return _projectIdToFinancials[_projectId].artistAddress;
    }

    /**
     * @notice View function returning Artist's secondary market royalty
     * percentage for project `_projectId`.
     * This does not include render/platform providers portions of secondary
     * market royalties.
     * @param _projectId Project ID to be queried.
     * @return uint256 Artist's secondary market royalty percentage.
     */
    function projectIdToSecondaryMarketRoyaltyPercentage(
        uint256 _projectId
    ) external view returns (uint256) {
        return
            _projectIdToFinancials[_projectId].secondaryMarketRoyaltyPercentage;
    }

    /**
     * @notice View function returning project financial details for project
     * `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return ProjectFinance Project financial details.
     */
    function projectIdToFinancials(
        uint256 _projectId
    ) external view returns (ProjectFinance memory) {
        return _projectIdToFinancials[_projectId];
    }

    /**
     * @notice Returns project details for project `_projectId`.
     * @param _projectId Project to be queried.
     * @return projectName Name of project
     * @return artist Artist of project
     * @return description Project description
     * @return website Project website
     * @return license Project license
     * @dev this function was named projectDetails prior to V3 core contract.
     */
    function projectDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory projectName,
            string memory artist,
            string memory description,
            string memory website,
            string memory license
        )
    {
        Project storage project = projects[_projectId];
        projectName = project.name;
        artist = project.artist;
        address projectDescriptionBytecodeAddress = project.descriptionAddress;
        if (projectDescriptionBytecodeAddress == address(0)) {
            description = "";
        } else {
            description = _readFromBytecode(projectDescriptionBytecodeAddress);
        }
        website = project.website;
        license = project.license;
    }

    /**
     * @notice Returns project state data for project `_projectId`.
     * @param _projectId Project to be queried
     * @return invocations Current number of invocations
     * @return maxInvocations Maximum allowed invocations
     * @return active Boolean representing if project is currently active
     * @return paused Boolean representing if project is paused
     * @return completedTimestamp zero if project not complete, otherwise
     * timestamp of project completion.
     * @return locked Boolean representing if project is locked
     * @dev price and currency info are located on minter contracts
     */
    function projectStateData(
        uint256 _projectId
    )
        external
        view
        returns (
            uint256 invocations,
            uint256 maxInvocations,
            bool active,
            bool paused,
            uint256 completedTimestamp,
            bool locked
        )
    {
        Project storage project = projects[_projectId];
        invocations = project.invocations;
        maxInvocations = project.maxInvocations;
        active = project.active;
        paused = project.paused;
        completedTimestamp = project.completedTimestamp;
        locked = !_projectUnlocked(_projectId);
    }

    /**
     * @notice Returns script information for project `_projectId`.
     * @param _projectId Project to be queried.
     * @return scriptTypeAndVersion Project's script type and version
     * (e.g. "p5js(atSymbol)1.0.0")
     * @return aspectRatio Aspect ratio of project (e.g. "1" for square,
     * "1.77777778" for 16:9, etc.)
     * @return scriptCount Count of scripts for project
     */
    function projectScriptDetails(
        uint256 _projectId
    )
        external
        view
        override(IGenArt721CoreContractV3_Base, IDependencyRegistryCompatibleV0)
        returns (
            string memory scriptTypeAndVersion,
            string memory aspectRatio,
            uint256 scriptCount
        )
    {
        Project storage project = projects[_projectId];
        scriptTypeAndVersion = project.scriptTypeAndVersion.toString();
        aspectRatio = project.aspectRatio;
        scriptCount = project.scriptCount;
    }

    /**
     * @notice Returns address with bytecode containing project script for
     * project `_projectId` at script index `_index`.
     */
    function projectScriptBytecodeAddressByIndex(
        uint256 _projectId,
        uint256 _index
    ) external view returns (address) {
        return projects[_projectId].scriptBytecodeAddresses[_index];
    }

    /**
     * @notice Returns the compressed form of a string in bytes using solady LibZip's flz compress algorithm. The bytes output from this function are intended to be used as input to `addProjectScriptCompressed` and `updateProjectScriptCompressed`.
     * @param _script Script to be compressed. Required to be a non-empty string, but no further validaton is performed.
     * @return bytes compressed bytes
     */
    function getCompressed(
        string memory _script
    ) external pure returns (bytes memory) {
        _onlyNonEmptyString(_script);
        // @dev want a potentially version-specific compression algorithm, so use version-specific library here
        return BytecodeStorageReader.getCompressed(_script);
    }

    /**
     * @notice Returns script for project `_projectId` at script index `_index`.
     * @param _projectId Project to be queried.
     * @param _index Index of script to be queried.
     */
    function projectScriptByIndex(
        uint256 _projectId,
        uint256 _index
    ) external view returns (string memory) {
        Project storage project = projects[_projectId];
        // If trying to access an out-of-index script, return the empty string.
        if (_index >= project.scriptCount) {
            return "";
        }
        return _readFromBytecode(project.scriptBytecodeAddresses[_index]);
    }

    /**
     * @notice Returns base URI for project `_projectId`.
     * @param _projectId Project to be queried.
     * @return projectBaseURI Base URI for project
     */
    function projectURIInfo(
        uint256 _projectId
    ) external view returns (string memory projectBaseURI) {
        projectBaseURI = projects[_projectId].projectBaseURI;
    }

    /**
     * @notice Backwards-compatible (pre-V3) function returning if `_minter` is
     * minterContract.
     * @param _minter Address to be queried.
     * @return bool Boolean representing if `_minter` is minterContract.
     */
    function isMintWhitelisted(address _minter) external view returns (bool) {
        return (minterContract == _minter);
    }

    /**
     * @notice Gets qty of randomizers in history of all randomizers used by
     * this core contract. If a randomizer is switched away from then back to,
     * it will show up in the history twice.
     * @return randomizerHistoryCount Count of randomizers in history
     */
    function numHistoricalRandomizers() external view returns (uint256) {
        return _historicalRandomizerAddresses.length;
    }

    /**
     * @notice Gets address of randomizer at index `_index` in history of all
     * randomizers used by this core contract. Index is zero-based.
     * @param _index Historical index of randomizer to be queried.
     * @return randomizerAddress Address of randomizer at index `_index`.
     * @dev If a randomizer is switched away from and then switched back to, it
     * will show up in the history twice.
     */
    function getHistoricalRandomizerAt(
        uint256 _index
    ) external view returns (address) {
        if (_index >= _historicalRandomizerAddresses.length) {
            revert GenArt721Error(ErrorCodes.IndexOutOfBounds);
        }
        return _historicalRandomizerAddresses[_index];
    }

    /**
     * @notice Gets ERC-2981 royalty information for token with ID `_tokenId`
     * and sale price `_salePrice`.
     * @param _tokenId Token ID to be queried for royalty information
     * @param _salePrice the sale price of the NFT asset specified by _tokenId
     * @return receiver address that should be sent the royalty payment
     * @return royaltyAmount the royalty payment amount for `_salePrice
     * @dev reverts if invalid _tokenId
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        _onlyValidTokenId(_tokenId);

        // populate receiver with project's royalty splitter
        // @dev royalty splitter created upon project creation, so will always exist
        // for valid token ID
        uint256 projectId = tokenIdToProjectId(_tokenId);
        ProjectFinance storage projectFinance = _projectIdToFinancials[
            projectId
        ];
        receiver = projectFinance.royaltySplitter;

        // populate royaltyAmount with calculated royalty amount
        // @dev important to cast to uint256 before multiplying to avoid overflow
        uint256 totalRoyaltyBPS = (100 *
            uint256(projectFinance.secondaryMarketRoyaltyPercentage)) +
            projectFinance.platformProviderSecondarySalesBPS +
            projectFinance.renderProviderSecondarySalesBPS;
        // @dev totalRoyaltyBPS guaranteed to be <= 10,000,
        if (totalRoyaltyBPS > 10_000) {
            revert GenArt721Error(ErrorCodes.OverMaxSumOfBPS);
        }
        // @dev overflow automatically checked in solidity 0.8
        // @dev totalRoyaltyBPS guaranteed to be <= 10_000,
        // so overflow only possible with unreasonably high _salePrice values near uint256 max
        royaltyAmount = (_salePrice * totalRoyaltyBPS) / 10_000;
    }

    /**
     * @notice View function that returns appropriate revenue splits between
     * different render provider, platform provider, Artist, and Artist's
     * additional primary sales payee given a sale price of `_price` on
     * project `_projectId`.
     * This always returns four revenue amounts and four addresses, but if a
     * revenue is zero for either Artist or additional payee, the corresponding
     * address returned will also be null (for gas optimization).
     * Does not account for refund if user overpays for a token (minter should
     * handle a refund of the difference, if appropriate).
     * Some minters may have alternative methods of splitting payments, in
     * which case they should implement their own payment splitting logic.
     * @param _projectId Project ID to be queried.
     * @param _price Sale price of token.
     * @return renderProviderRevenue_ amount of revenue to be sent to the
     * render provider
     * @return renderProviderAddress_ address to send render provider revenue to
     * @return platformProviderRevenue_ amount of revenue to be sent to the
     * platform provider
     * @return platformProviderAddress_ address to send platform provider revenue to
     * @return artistRevenue_ amount of revenue to be sent to Artist
     * @return artistAddress_ address to send Artist revenue to. Will be null
     * if no revenue is due to artist (gas optimization).
     * @return additionalPayeePrimaryRevenue_ amount of revenue to be sent to
     * additional payee for primary sales
     * @return additionalPayeePrimaryAddress_ address to send Artist's
     * additional payee for primary sales revenue to. Will be null if no
     * revenue is due to additional payee for primary sales (gas optimization).
     * @dev this always returns four addresses and four revenues, but if the
     * revenue is zero, the corresponding address will be address(0). It is up
     * to the contract performing the revenue split to handle this
     * appropriately.
     */
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 renderProviderRevenue_,
            address payable renderProviderAddress_,
            uint256 platformProviderRevenue_,
            address payable platformProviderAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        )
    {
        ProjectFinance storage projectFinance = _projectIdToFinancials[
            _projectId
        ];
        // calculate revenues – this is a three-way split between the
        // render provider, the platform provider, and the artist, and
        // is safe to perform this given that in the case of loss of
        // precision Solidity will round down.
        uint256 projectFunds = _price;
        renderProviderRevenue_ =
            (_price * uint256(_renderProviderPrimarySalesPercentage)) /
            ONE_HUNDRED;
        // renderProviderRevenue_ percentage is always <=100, so guaranteed to never underflow
        projectFunds -= renderProviderRevenue_;
        platformProviderRevenue_ =
            (_price * uint256(_platformProviderPrimarySalesPercentage)) /
            ONE_HUNDRED;
        // platformProviderRevenue_ percentage is always <=100, so guaranteed to never underflow
        projectFunds -= platformProviderRevenue_;
        additionalPayeePrimaryRevenue_ =
            (projectFunds *
                projectFinance.additionalPayeePrimarySalesPercentage) /
            ONE_HUNDRED;
        // projectIdToAdditionalPayeePrimarySalesPercentage is always
        // <=100, so guaranteed to never underflow
        artistRevenue_ = projectFunds - additionalPayeePrimaryRevenue_;
        // set addresses from storage
        renderProviderAddress_ = renderProviderPrimarySalesAddress;
        platformProviderAddress_ = platformProviderPrimarySalesAddress;
        if (artistRevenue_ > 0) {
            artistAddress_ = projectFinance.artistAddress;
        }
        if (additionalPayeePrimaryRevenue_ > 0) {
            additionalPayeePrimaryAddress_ = projectFinance
                .additionalPayeePrimarySales;
        }
    }

    /**
     * @notice Backwards-compatible (pre-V3) getter returning contract admin
     * @return address Address of contract admin (same as owner)
     */
    function admin() external view returns (address) {
        return owner();
    }

    /**
     * @notice Gets the project ID for a given `_tokenId`.
     * @param _tokenId Token ID to be queried.
     * @return _projectId Project ID for given `_tokenId`.
     */
    function tokenIdToProjectId(
        uint256 _tokenId
    ) public pure returns (uint256 _projectId) {
        return _tokenId / ONE_MILLION;
    }

    /**
     * @notice Convenience function that returns whether `_sender` is allowed
     * to call function with selector `_selector` on contract `_contract`, as
     * determined by this contract's current Admin ACL contract. Expected use
     * cases include minter contracts checking if caller is allowed to call
     * admin-gated functions on minter contracts.
     * @param _sender Address of the sender calling function with selector
     * `_selector` on contract `_contract`.
     * @param _contract Address of the contract being called by `_sender`.
     * @param _selector Function selector of the function being called by
     * `_sender`.
     * @return bool Whether `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`.
     * @dev assumes the Admin ACL contract is the owner of this contract, which
     * is expected to always be true.
     * @dev adminACLContract is expected to either be null address (if owner
     * has renounced ownership), or conform to IAdminACLV0 interface. Check for
     * null address first to avoid revert when admin has renounced ownership.
     */
    function adminACLAllowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) public returns (bool) {
        return
            owner() != address(0) &&
            adminACLContract.allowed(_sender, _contract, _selector);
    }

    /**
     * @notice Returns contract owner. Set to deployer's address by default on
     * contract deployment.
     * @return address Address of contract owner.
     * @dev ref: https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable
     * @dev owner role was called `admin` prior to V3 core contract
     */
    function owner()
        public
        view
        override(Ownable, IGenArt721CoreContractV3_Base)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * @notice Gets token URI for token ID `_tokenId`.
     * @param _tokenId Token ID to be queried.
     * @return string URI of token ID `_tokenId`.
     * @dev token URIs are the concatenation of the project base URI and the
     * token ID.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        _onlyValidTokenId(_tokenId);
        string memory _projectBaseURI = projects[tokenIdToProjectId(_tokenId)]
            .projectBaseURI;
        return string.concat(_projectBaseURI, _tokenId.toString());
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721_PackedHashSeedV1, IERC165)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Forbids new projects from being created
     * @dev only performs operation and emits event if contract is not already
     * forbidding new projects.
     */
    function _forbidNewProjects() internal {
        if (!newProjectsForbidden) {
            newProjectsForbidden = true;
            emit PlatformUpdated(
                bytes32(
                    uint256(PlatformUpdatedFields.FIELD_NEW_PROJECTS_FORBIDDEN)
                )
            );
        }
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     * @param newOwner New owner.
     * @dev owner role was called `admin` prior to V3 core contract.
     * @dev Overrides and wraps OpenZeppelin's _transferOwnership function to
     * also update adminACLContract for improved introspection.
     */
    function _transferOwnership(address newOwner) internal override {
        Ownable._transferOwnership(newOwner);
        adminACLContract = IAdminACLV0(newOwner);
    }

    /**
     * @notice Updates sales addresses for the platform and render providers to
     * the input parameters.
     * Reverts if invalid platform provider addresses are provided given the
     * contract's immutably configured nullPlatformProvider state.
     * Does not check render provider addresses in any way.
     * @param _renderProviderPrimarySalesAddress Address of new primary sales
     * payment address.
     * @param _defaultRenderProviderSecondarySalesAddress Address of new secondary sales
     * payment address.
     * @param _platformProviderPrimarySalesAddress Address of new primary sales
     * payment address.
     * @param _defaultPlatformProviderSecondarySalesAddress Address of new secondary sales
     * payment address.
     */
    function _updateProviderSalesAddresses(
        address _renderProviderPrimarySalesAddress,
        address _defaultRenderProviderSecondarySalesAddress,
        address _platformProviderPrimarySalesAddress,
        address _defaultPlatformProviderSecondarySalesAddress
    ) internal {
        if (nullPlatformProvider) {
            // require null platform provider address
            if (
                _platformProviderPrimarySalesAddress != address(0) ||
                _defaultPlatformProviderSecondarySalesAddress != address(0)
            ) {
                revert GenArt721Error(ErrorCodes.OnlyNullPlatformProvider);
            }
        } else {
            _onlyNonZeroAddress(_platformProviderPrimarySalesAddress);
            _onlyNonZeroAddress(_defaultPlatformProviderSecondarySalesAddress);
        }
        platformProviderPrimarySalesAddress = payable(
            _platformProviderPrimarySalesAddress
        );
        defaultPlatformProviderSecondarySalesAddress = payable(
            _defaultPlatformProviderSecondarySalesAddress
        );
        renderProviderPrimarySalesAddress = payable(
            _renderProviderPrimarySalesAddress
        );
        defaultRenderProviderSecondarySalesAddress = payable(
            _defaultRenderProviderSecondarySalesAddress
        );
        emit PlatformUpdated(
            bytes32(
                uint256(PlatformUpdatedFields.FIELD_PROVIDER_SALES_ADDRESSES)
            )
        );
    }

    /**
     * @notice Updates minter address to `_minterAddress`.
     * @param _minterAddress New minter address.
     * @dev Note that this method does not check that the input address is
     * not `address(0)`, as it is expected that callers of this method should
     * perform input validation where applicable.
     */
    function _updateMinterContract(address _minterAddress) internal {
        minterContract = _minterAddress;
        emit MinterUpdated(_minterAddress);
    }

    /**
     * @notice Updates randomizer address to `_randomizerAddress`.
     * @param _randomizerAddress New randomizer address.
     * @dev Note that this method does not check that the input address is
     * not `address(0)`, as it is expected that callers of this method should
     * perform input validation where applicable.
     */
    function _updateRandomizerAddress(address _randomizerAddress) internal {
        randomizerContract = IRandomizer_V3CoreBase(_randomizerAddress);
        // populate historical randomizer array
        _historicalRandomizerAddresses.push(_randomizerAddress);
        emit PlatformUpdated(
            bytes32(uint256(PlatformUpdatedFields.FIELD_RANDOMIZER_ADDRESS))
        );
    }

    /**
     * @notice Updates split provider address to `_splitProviderAddress`.
     * Reverts if `_splitProviderAddress` is the zero address.
     * @param _splitProviderAddress New split provider address.
     * @dev Note that this method does not check that the input address is
     * not `address(0)`, as it is expected that callers of this method should
     * perform input validation where applicable.
     */
    function _updateSplitProvider(address _splitProviderAddress) internal {
        // require non-zero split provider address
        _onlyNonZeroAddress(_splitProviderAddress);
        splitProvider = ISplitProviderV0(_splitProviderAddress);
        emit PlatformUpdated(
            bytes32(uint256(PlatformUpdatedFields.FIELD_SPLIT_PROVIDER))
        );
    }

    /**
     * @notice Update the bytecode storage reader contract address, and emit corresponding event.
     * @param _bytecodeStorageReaderContract New bytecode storage reader contract address.
     */
    function _updateBytecodeStorageReaderContract(
        address _bytecodeStorageReaderContract
    ) internal {
        bytecodeStorageReaderContract = IBytecodeStorageReader_Base(
            _bytecodeStorageReaderContract
        );
        emit PlatformUpdated(
            bytes32(
                uint256(PlatformUpdatedFields.FIELD_BYTECODE_STORAGE_READER)
            )
        );
    }

    /**
     * @notice internal function to update a splitter contract for a project,
     * based on the project's financials in this contract's storage.
     * @dev Warning: this function uses storage reads to get the project's
     * financials, so ensure storage has been updated before calling this
     * @dev This function includes a trusted interaction that is entrusted to
     * not reenter this contract.
     * @param projectId Project ID to be updated.
     */
    function _assignSplitter(uint256 projectId) internal {
        ProjectFinance storage projectFinance = _projectIdToFinancials[
            projectId
        ];
        // assign project's royalty splitter
        // @dev loads values from storage, so need to ensure storage has been updated
        address royaltySplitter = splitProvider.getOrCreateSplitter(
            ISplitProviderV0.SplitInputs({
                platformProviderSecondarySalesAddress: projectFinance
                    .platformProviderSecondarySalesAddress,
                platformProviderSecondarySalesBPS: projectFinance
                    .platformProviderSecondarySalesBPS,
                renderProviderSecondarySalesAddress: projectFinance
                    .renderProviderSecondarySalesAddress,
                renderProviderSecondarySalesBPS: projectFinance
                    .renderProviderSecondarySalesBPS,
                artistTotalRoyaltyPercentage: projectFinance
                    .secondaryMarketRoyaltyPercentage,
                artist: projectFinance.artistAddress,
                additionalPayee: projectFinance.additionalPayeeSecondarySales,
                additionalPayeePercentage: projectFinance
                    .additionalPayeeSecondarySalesPercentage
            })
        );

        projectFinance.royaltySplitter = royaltySplitter;

        emit ProjectRoyaltySplitterUpdated({
            projectId: projectId,
            royaltySplitter: royaltySplitter
        });
    }

    /**
     * @notice Updates default base URI to `_defaultBaseURI`.
     * When new projects are added, their `projectBaseURI` is automatically
     * initialized to `_defaultBaseURI`.
     * @param _defaultBaseURI New default base URI.
     * @dev Note that this method does not check that the input string is not
     * the empty string, as it is expected that callers of this method should
     * perform input validation where applicable.
     */
    function _updateDefaultBaseURI(string memory _defaultBaseURI) internal {
        defaultBaseURI = _defaultBaseURI;
        emit PlatformUpdated(
            bytes32(uint256(PlatformUpdatedFields.FIELD_DEFAULT_BASE_URI))
        );
    }

    /**
     * @notice Internal function to complete a project.
     * @param _projectId Project ID to be completed.
     */
    function _completeProject(uint256 _projectId) internal {
        projects[_projectId].completedTimestamp = uint64(block.timestamp);
        emit ProjectUpdated(
            _projectId,
            bytes32(uint256(ProjectUpdatedFields.FIELD_PROJECT_COMPLETED))
        );
    }

    /**
     * @notice Initializes the contract with the provided `engineConfiguration`.
     * This function should be called atomically, immediately after deployment.
     * Only callable once. Validation on `engineConfiguration` is performed by caller.
     * @param engineConfiguration EngineConfiguration to configure the contract with.
     * @param adminACLContract_ Address of admin access control contract, to be
     * set as contract owner.
     * @param defaultBaseURIHost Base URI prefix to initialize default base URI with.
     * @param bytecodeStorageReaderContract_ Address of bytecode storage reader contract.
     */
    function _initialize(
        EngineConfiguration memory engineConfiguration,
        address adminACLContract_,
        string memory defaultBaseURIHost,
        address bytecodeStorageReaderContract_
    ) internal {
        // can only be initialized once
        if (_initialized) {
            revert GenArt721Error(ErrorCodes.ContractInitialized);
        }
        // immediately mark as initialized
        _initialized = true;
        // @dev assume renderProviderAddress, randomizer, and AdminACL non-zero
        // checks on platform provider addresses performed in _updateProviderSalesAddresses
        // initialize default sales revenue percentages and basis points
        _renderProviderPrimarySalesPercentage = 10;
        defaultRenderProviderSecondarySalesBPS = 250;
        _platformProviderPrimarySalesPercentage = engineConfiguration
            .nullPlatformProvider
            ? 0
            : 10;
        defaultPlatformProviderSecondarySalesBPS = engineConfiguration
            .nullPlatformProvider
            ? 0
            : 250;

        // set token name and token symbol
        ERC721_PackedHashSeedV1.initialize(
            engineConfiguration.tokenName,
            engineConfiguration.tokenSymbol
        );
        // update minter if populated
        if (engineConfiguration.minterFilterAddress != address(0)) {
            _updateMinterContract(engineConfiguration.minterFilterAddress);
        }
        _updateSplitProvider(engineConfiguration.splitProviderAddress);
        _updateBytecodeStorageReaderContract(bytecodeStorageReaderContract_);
        // setup immutable `autoApproveArtistSplitProposals` config
        autoApproveArtistSplitProposals = engineConfiguration
            .autoApproveArtistSplitProposals;
        // setup immutable `nullPlatformProvider` config
        nullPlatformProvider = engineConfiguration.nullPlatformProvider;
        // setup immutable `allowArtistProjectActivation` config
        allowArtistProjectActivation = engineConfiguration
            .allowArtistProjectActivation;
        // record contracts starting project ID
        // casting-up is safe
        startingProjectId = uint256(engineConfiguration.startingProjectId);
        // @dev nullPlatformProvider must be set before calling _updateProviderSalesAddresses
        _updateProviderSalesAddresses(
            engineConfiguration.renderProviderAddress,
            engineConfiguration.renderProviderAddress,
            engineConfiguration.platformProviderAddress,
            engineConfiguration.platformProviderAddress
        );
        _updateRandomizerAddress(engineConfiguration.randomizerContract);
        // set AdminACL management contract as owner
        _transferOwnership(adminACLContract_);
        // initialize default base URI
        _updateDefaultBaseURI(
            string.concat(defaultBaseURIHost, address(this).toHexString(), "/")
        );
        // initialize next project ID
        _nextProjectId = engineConfiguration.startingProjectId;
        emit PlatformUpdated(
            bytes32(uint256(PlatformUpdatedFields.FIELD_NEXT_PROJECT_ID))
        );
        // @dev This contract is registered on the core registry in a
        // subsequent call by the factory.
    }

    /**
     * @notice Internal function that returns whether a project is unlocked.
     * Projects automatically lock four weeks after they are completed.
     * Projects are considered completed when they have been invoked the
     * maximum number of times.
     * @param _projectId Project ID to be queried.
     * @return bool true if project is unlocked, false otherwise.
     * @dev This also enforces that the `_projectId` passed in is valid.
     */
    function _projectUnlocked(uint256 _projectId) internal view returns (bool) {
        _onlyValidProjectId(_projectId);

        uint256 projectCompletedTimestamp = projects[_projectId]
            .completedTimestamp;
        bool projectOpen = projectCompletedTimestamp == 0;
        return
            projectOpen ||
            (block.timestamp - projectCompletedTimestamp <
                FOUR_WEEKS_IN_SECONDS);
    }

    /**
     * @notice Helper for calling bytecodeStorageReaderContract reader method;
     * added for bytecode size reduction purposes.
     */
    function _readFromBytecode(
        address _address
    ) internal view returns (string memory) {
        return bytecodeStorageReaderContract.readFromBytecode(_address);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";

interface IAdminACLV0_Extended is IAdminACLV0 {
    /**
     * @notice Allows superAdmin change the superAdmin address.
     * @param _newSuperAdmin The new superAdmin address.
     * @param _genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     * @dev this function is gated to only superAdmin address.
     */
    function changeSuperAdmin(
        address _newSuperAdmin,
        address[] calldata _genArt721CoreAddressesToUpdate
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IAdminACLV0 {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     * @param previousSuperAdmin The previous superAdmin address.
     * @param newSuperAdmin The new superAdmin address.
     * @param genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     */
    event SuperAdminTransferred(
        address indexed previousSuperAdmin,
        address indexed newSuperAdmin,
        address[] genArt721CoreAddressesToUpdate
    );

    /// Type of the Admin ACL contract, e.g. "AdminACLV0"
    function AdminACLType() external view returns (string memory);

    /// super admin address
    function superAdmin() external view returns (address);

    /**
     * @notice Calls transferOwnership on other contract from this contract.
     * This is useful for updating to a new AdminACL contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function transferOwnershipOn(
        address _contract,
        address _newAdminACL
    ) external;

    /**
     * @notice Calls renounceOwnership on other contract from this contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function renounceOwnershipOn(address _contract) external;

    /**
     * @notice Checks if sender `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`.
     */
    function allowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

/**
 * @title Art Blocks Script Storage Library - Minimal Interface for Reader Contracts
 * @notice This interface defines the minimal expected read function(s) for a Bytecode Storage Reader contract.
 */
interface IBytecodeStorageReader_Base {
    /**
     * @notice Read a string from a data contract deployed via BytecodeStorage.
     * @dev may also support reading additional stored data formats in the future.
     * @param address_ address of contract deployed via BytecodeStorage to be read
     * @return data The string data stored at the specific address.
     */
    function readFromBytecode(
        address address_
    ) external view returns (string memory data);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
pragma solidity ^0.8.19;

interface IDependencyRegistryCompatibleV0 {
    /// Dependency registry managed by Art Blocks
    function artblocksDependencyRegistryAddress()
        external
        view
        returns (address);

    /**
     * @notice Returns script information for project `_projectId`.
     * @param _projectId Project to be queried.
     * @return scriptTypeAndVersion Project's script type and version
     * (e.g. "p5js(atSymbol)1.0.0")
     * @return aspectRatio Aspect ratio of project (e.g. "1" for square,
     * "1.77777778" for 16:9, etc.)
     * @return scriptCount Count of scripts for project
     */
    function projectScriptDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory scriptTypeAndVersion,
            string memory aspectRatio,
            uint256 scriptCount
        );
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IGenArt721CoreContractExposesHashSeed {
    // function to read the hash-seed for a given tokenId
    function tokenIdToHashSeed(
        uint256 _tokenId
    ) external view returns (bytes12);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";

/**
 * @title This interface is intended to house interface items that are common
 * across all GenArt721CoreContractV3 flagship and derivative implementations.
 * This interface extends the IManifold royalty interface in order to
 * add support the Royalty Registry by default.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_Base {
    // This interface emits generic events that contain fields that indicate
    // which parameter has been updated. This is sufficient for application
    // state management, while also simplifying the contract and indexing code.
    // This was done as an alternative to having custom events that emit what
    // field-values have changed for each event, given that changed values can
    // be introspected by indexers due to the design of this smart contract
    // exposing these state changes via publicly viewable fields.

    /**
     * @notice Project's royalty splitter was updated to `_splitter`.
     * @dev New event in v3.2
     * @param projectId The project ID.
     * @param royaltySplitter The new splitter address to receive royalties.
     */
    event ProjectRoyaltySplitterUpdated(
        uint256 indexed projectId,
        address indexed royaltySplitter
    );

    // The following fields are used to indicate which contract-level parameter
    // has been updated in the `PlatformUpdated` event:
    // @dev only append to the end of this enum in the case of future updates
    enum PlatformUpdatedFields {
        FIELD_NEXT_PROJECT_ID, // 0
        FIELD_NEW_PROJECTS_FORBIDDEN, // 1
        FIELD_DEFAULT_BASE_URI, // 2
        FIELD_RANDOMIZER_ADDRESS, // 3
        FIELD_NEXT_CORE_CONTRACT, // 4
        FIELD_ARTBLOCKS_DEPENDENCY_REGISTRY_ADDRESS, // 5
        FIELD_ARTBLOCKS_ON_CHAIN_GENERATOR_ADDRESS, // 6
        FIELD_PROVIDER_SALES_ADDRESSES, // 7
        FIELD_PROVIDER_PRIMARY_SALES_PERCENTAGES, // 8
        FIELD_PROVIDER_SECONDARY_SALES_BPS, // 9
        FIELD_SPLIT_PROVIDER, // 10
        FIELD_BYTECODE_STORAGE_READER // 11
    }

    // The following fields are used to indicate which project-level parameter
    // has been updated in the `ProjectUpdated` event:
    // @dev only append to the end of this enum in the case of future updates
    enum ProjectUpdatedFields {
        FIELD_PROJECT_COMPLETED, // 0
        FIELD_PROJECT_ACTIVE, // 1
        FIELD_PROJECT_ARTIST_ADDRESS, // 2
        FIELD_PROJECT_PAUSED, // 3
        FIELD_PROJECT_CREATED, // 4
        FIELD_PROJECT_NAME, // 5
        FIELD_PROJECT_ARTIST_NAME, // 6
        FIELD_PROJECT_SECONDARY_MARKET_ROYALTY_PERCENTAGE, // 7
        FIELD_PROJECT_DESCRIPTION, // 8
        FIELD_PROJECT_WEBSITE, // 9
        FIELD_PROJECT_LICENSE, // 10
        FIELD_PROJECT_MAX_INVOCATIONS, // 11
        FIELD_PROJECT_SCRIPT, // 12
        FIELD_PROJECT_SCRIPT_TYPE, // 13
        FIELD_PROJECT_ASPECT_RATIO, // 14
        FIELD_PROJECT_BASE_URI, // 15
        FIELD_PROJECT_PROVIDER_SECONDARY_FINANCIALS // 16
    }

    /**
     * @notice Error codes for the GenArt721 contract. Used by the GenArt721Error
     * custom error.
     * @dev only append to the end of this enum in the case of future updates
     */
    enum ErrorCodes {
        OnlyNonZeroAddress, // 0
        OnlyNonEmptyString, // 1
        OnlyNonEmptyBytes, // 2
        TokenDoesNotExist, // 3
        ProjectDoesNotExist, // 4
        OnlyUnlockedProjects, // 5
        OnlyAdminACL, // 6
        OnlyArtist, // 7
        OnlyArtistOrAdminACL, // 8
        OnlyAdminACLOrRenouncedArtist, // 9
        OnlyMinterContract, // 10
        MaxInvocationsReached, // 11
        ProjectMustExistAndBeActive, // 12
        PurchasesPaused, // 13
        OnlyRandomizer, // 14
        TokenHashAlreadySet, // 15
        NoZeroHashSeed, // 16
        OverMaxSumOfPercentages, // 17
        IndexOutOfBounds, // 18
        OverMaxSumOfBPS, // 19
        MaxOf100Percent, // 20
        PrimaryPayeeIsZeroAddress, // 21
        SecondaryPayeeIsZeroAddress, // 22
        MustMatchArtistProposal, // 23
        NewProjectsForbidden, // 24
        NewProjectsAlreadyForbidden, // 25
        OnlyArtistOrAdminIfLocked, // 26
        OverMaxSecondaryRoyaltyPercentage, // 27
        OnlyMaxInvocationsDecrease, // 28
        OnlyGteInvocations, // 29
        ScriptIdOutOfRange, // 30
        NoScriptsToRemove, // 31
        ScriptTypeAndVersionFormat, // 32
        AspectRatioTooLong, // 33
        AspectRatioNoNumbers, // 34
        AspectRatioImproperFormat, // 35
        OnlyNullPlatformProvider, // 36
        ContractInitialized // 37
    }

    /**
     * @notice Emits an error code `_errorCode` in the GenArt721Error event.
     * @dev Emitting error codes instead of error strings saves significant
     * contract bytecode size, allowing for more contract functionality within
     * the 24KB contract size limit.
     * @param _errorCode The error code to emit. See ErrorCodes enum.
     */
    error GenArt721Error(ErrorCodes _errorCode);

    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     */
    event Mint(address indexed _to, uint256 indexed _tokenId);

    /**
     * @notice currentMinter updated to `_currentMinter`.
     * @dev Implemented starting with V3 core
     */
    event MinterUpdated(address indexed _currentMinter);

    /**
     * @notice Platform updated on bytes32-encoded field `_field`.
     */
    event PlatformUpdated(bytes32 indexed _field);

    /**
     * @notice Project ID `_projectId` updated on bytes32-encoded field
     * `_update`.
     */
    event ProjectUpdated(uint256 indexed _projectId, bytes32 indexed _update);

    event ProposedArtistAddressesAndSplits(
        uint256 indexed _projectId,
        address _artistAddress,
        address _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    );

    event AcceptedArtistAddressesAndSplits(uint256 indexed _projectId);

    // version and type of the core contract
    // coreVersion is a string of the form "0.x.y"
    function coreVersion() external view returns (string memory);

    // coreType is a string of the form "GenArt721CoreV3"
    function coreType() external view returns (string memory);

    // owner (pre-V3 was named admin) of contract
    // this is expected to be an Admin ACL contract for V3
    function owner() external view returns (address);

    // Admin ACL contract for V3, will be at the address owner()
    function adminACLContract() external returns (IAdminACLV0);

    // backwards-compatible (pre-V3) admin - equal to owner()
    function admin() external view returns (address);

    /**
     * Function determining if _sender is allowed to call function with
     * selector _selector on contract `_contract`. Intended to be used with
     * peripheral contracts such as minters, as well as internally by the
     * core contract itself.
     */
    function adminACLAllowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);

    /// getter function of public variable
    function startingProjectId() external view returns (uint256);

    // getter function of public variable
    function nextProjectId() external view returns (uint256);

    // getter function of public mapping
    function tokenIdToProjectId(
        uint256 tokenId
    ) external view returns (uint256 projectId);

    // @dev this is not available in V0
    function isMintWhitelisted(address minter) external view returns (bool);

    function projectIdToArtistAddress(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToSecondaryMarketRoyaltyPercentage(
        uint256 _projectId
    ) external view returns (uint256);

    function projectURIInfo(
        uint256 _projectId
    ) external view returns (string memory projectBaseURI);

    // @dev new function in V3
    function projectStateData(
        uint256 _projectId
    )
        external
        view
        returns (
            uint256 invocations,
            uint256 maxInvocations,
            bool active,
            bool paused,
            uint256 completedTimestamp,
            bool locked
        );

    function projectDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory projectName,
            string memory artist,
            string memory description,
            string memory website,
            string memory license
        );

    function projectScriptDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory scriptTypeAndVersion,
            string memory aspectRatio,
            uint256 scriptCount
        );

    function projectScriptByIndex(
        uint256 _projectId,
        uint256 _index
    ) external view returns (string memory);

    function tokenIdToHash(uint256 _tokenId) external view returns (bytes32);

    // function to set a token's hash (must be guarded)
    function setTokenHash_8PT(uint256 _tokenId, bytes32 _hash) external;

    // @dev gas-optimized signature in V3 for `mint`
    function mint_Ecf(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Base.sol";
import "./ISplitProviderV0.sol";

/**
 * @notice Struct representing Engine contract configuration.
 * @param tokenName Name of token.
 * @param tokenSymbol Token symbol.
 * @param renderProviderAddress address to send render provider revenue to
 * @param randomizerContract Randomizer contract.
 * @param splitProviderAddress Address to use as royalty splitter provider for the contract.
 * @param minterFilterAddress Address of the Minter Filter to set as the Minter
 * on the contract.
 * @param startingProjectId The initial next project ID.
 * @param autoApproveArtistSplitProposals Whether or not to always
 * auto-approve proposed artist split updates.
 * @param nullPlatformProvider Enforce always setting zero platform provider fees and addresses.
 * @param allowArtistProjectActivation Allow artist to activate their own projects.
 * @dev _startingProjectId should be set to a value much, much less than
 * max(uint248), but an explicit input type of `uint248` is used as it is
 * safer to cast up to `uint256` than it is to cast down for the purposes
 * of setting `_nextProjectId`.
 */
struct EngineConfiguration {
    string tokenName;
    string tokenSymbol;
    address renderProviderAddress;
    address platformProviderAddress;
    address newSuperAdminAddress;
    address randomizerContract;
    address splitProviderAddress;
    address minterFilterAddress;
    uint248 startingProjectId;
    bool autoApproveArtistSplitProposals;
    bool nullPlatformProvider;
    bool allowArtistProjectActivation;
}

interface IGenArt721CoreContractV3_Engine is IGenArt721CoreContractV3_Base {
    // @dev new function in V3.2
    /**
     * @notice Initializes the contract with the provided `engineConfiguration`.
     * This function should be called atomically, immediately after deployment.
     * Only callable once. Validation on `engineConfiguration` is performed by caller.
     * @param engineConfiguration EngineConfiguration to configure the contract with.
     * @param adminACLContract_ Address of admin access control contract, to be
     * set as contract owner.
     * @param defaultBaseURIHost Base URI prefix to initialize default base URI with.
     * @param bytecodeStorageReaderContract_ Address of the bytecode storage reader contract.
     */
    function initialize(
        EngineConfiguration calldata engineConfiguration,
        address adminACLContract_,
        string memory defaultBaseURIHost,
        address bytecodeStorageReaderContract_
    ) external;

    // @dev new function in V3
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 renderProviderRevenue_,
            address payable renderProviderAddress_,
            uint256 platformProviderRevenue_,
            address payable platformProviderAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        );

    // @dev The render provider primary sales payment address
    function renderProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider primary sales payment address
    function platformProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Percentage of primary sales allocated to the render provider
    function renderProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    // @dev Percentage of primary sales allocated to the platform provider
    function platformProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    /** @notice The default render provider payment address for all secondary sales royalty
     * revenues, for all new projects. Individual project payment info is defined
     * in each project's ProjectFinance struct.
     * @return The default render provider payment address for secondary sales royalties.
     */
    function defaultRenderProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    /** @notice The default platform provider payment address for all secondary sales royalty
     * revenues, for all new projects. Individual project payment info is defined
     * in each project's ProjectFinance struct.
     * @return The default platform provider payment address for secondary sales royalties.
     */
    function defaultPlatformProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    /** @notice The default render provider payment basis points for all secondary sales royalty
     * revenues, for all new projects. Individual project payment info is defined
     * in each project's ProjectFinance struct.
     * @return The default render provider payment basis points for secondary sales royalties.
     */
    function defaultRenderProviderSecondarySalesBPS()
        external
        view
        returns (uint256);

    /** @notice The default platform provider payment basis points for all secondary sales royalty
     * revenues, for all new projects. Individual project payment info is defined
     * in each project's ProjectFinance struct.
     * @return The default platform provider payment basis points for secondary sales royalties.
     */
    function defaultPlatformProviderSecondarySalesBPS()
        external
        view
        returns (uint256);

    /**
     * @notice The address of the current split provider being used by the contract.
     * @return The address of the current split provider.
     */
    function splitProvider() external view returns (ISplitProviderV0);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";

/**
 * @title This interface defines a project finance struct that is used in the
 * GenArt721CoreContractV3 flagship and derivative implementations beginning
 * with v3.2.0. This struct is intended to house all financial information
 * related to a project, including royalties, artist splits, and platform
 * provider splits.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_ProjectFinance {
    /// packed struct containing project financial information
    struct ProjectFinance {
        address payable additionalPayeePrimarySales;
        // packed uint: max of 95, max uint8 = 255
        uint8 secondaryMarketRoyaltyPercentage;
        address payable additionalPayeeSecondarySales;
        // packed uint: max of 100, max uint8 = 255
        uint8 additionalPayeeSecondarySalesPercentage;
        address payable artistAddress;
        // packed uint: max of 100, max uint8 = 255
        uint8 additionalPayeePrimarySalesPercentage;
        address platformProviderSecondarySalesAddress;
        // packed uint: max of 10_000 max uint16 = 65_535
        uint16 platformProviderSecondarySalesBPS;
        address renderProviderSecondarySalesAddress;
        // packed uint: max of 10_000 max uint16 = 65_535
        uint16 renderProviderSecondarySalesBPS;
        // address to send ERC-2981 royalties to
        address royaltySplitter;
    }

    /**
     * @notice View function returning project financial details for project
     * `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return ProjectFinance Project financial details.
     */
    function projectIdToFinancials(
        uint256 _projectId
    ) external view returns (ProjectFinance memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc. to support the 0xSplits V2 integration
// Sourced from:
//  - https://github.com/0xSplits/splits-contracts-monorepo/blob/main/packages/splits-v2/src/libraries/SplitV2.sol
//  - https://github.com/0xSplits/splits-contracts-monorepo/blob/main/packages/splits-v2/src/splitters/SplitFactoryV2.sol

pragma solidity ^0.8.0;

interface ISplitFactoryV2 {
    /* -------------------------------------------------------------------------- */
    /*                                   STRUCTS                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Split struct
     * @dev This struct is used to store the split information.
     * @dev There are no hard caps on the number of recipients/totalAllocation/allocation unit. Thus the chain and its
     * gas limits will dictate these hard caps. Please double check if the split you are creating can be distributed on
     * the chain.
     * @param recipients The recipients of the split.
     * @param allocations The allocations of the split.
     * @param totalAllocation The total allocation of the split.
     * @param distributionIncentive The incentive for distribution. Limits max incentive to 6.5%.
     */
    struct Split {
        address[] recipients;
        uint256[] allocations;
        uint256 totalAllocation;
        uint16 distributionIncentive;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 FUNCTIONS                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Create a new split with params and owner.
     * @param _splitParams Params to create split with.
     * @param _owner Owner of created split.
     * @param _creator Creator of created split.
     * @param _salt Salt for create2.
     * @return split Address of the created split.
     */
    function createSplitDeterministic(
        Split calldata _splitParams,
        address _owner,
        address _creator,
        bytes32 _salt
    ) external returns (address split);

    /**
     * @notice Predict the address of a new split and check if it is deployed.
     * @param _splitParams Params to create split with.
     * @param _owner Owner of created split.
     * @param _salt Salt for create2.
     */
    function isDeployed(
        Split calldata _splitParams,
        address _owner,
        bytes32 _salt
    ) external view returns (address split, bool exists);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IRandomizer_V3CoreBase {
    /**
     * @notice This function is intended to be called by a core contract, and
     * the core contract can be assured that the randomizer will call back to
     * the calling contract to set the token hash seed for `_tokenId` via
     * `setTokenHash_8PT`.
     * @dev This function may revert if hash seed generation is improperly
     * configured (for example, if in polyptych mode, but no hash seed has been
     * previously configured).
     * @dev This function is not specifically gated to any specific caller, but
     * will only call back to the calling contract, `msg.sender`, to set the
     * specified token's hash seed.
     * A third party contract calling this function will not be able to set the
     * token hash seed on a different core contract.
     * @param _tokenId The token ID must be assigned a hash.
     */
    function assignTokenHash(uint256 _tokenId) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

import {ISplitFactoryV2} from "./integration-refs/splits-0x-v2/ISplitFactoryV2.sol";

interface ISplitProviderV0 {
    /**
     * @notice SplitInputs struct defines the inputs for requested splitters.
     * It is defined in a way easily communicated from the Art Blocks GenArt721V3 contract,
     * to allow for easy integration and minimal additional bytecode in the GenArt721V3 contract.
     */
    struct SplitInputs {
        address platformProviderSecondarySalesAddress;
        uint16 platformProviderSecondarySalesBPS;
        address renderProviderSecondarySalesAddress;
        uint16 renderProviderSecondarySalesBPS;
        uint8 artistTotalRoyaltyPercentage;
        address artist;
        address additionalPayee;
        uint8 additionalPayeePercentage;
    }

    /**
     * @notice Emitted when a new splitter contract is created.
     * @param splitter address of the splitter contract
     */
    event SplitterCreated(address indexed splitter);

    /**
     * @notice Gets or creates an immutable splitter contract at a deterministic address.
     * Splits in the splitter contract are determined by the input split parameters,
     * so we can safely create the splitter contract at a deterministic address (or use
     * the existing splitter contract if it already exists at that address).
     * @dev Uses the 0xSplits v2 implementation to create a splitter contract
     * @param splitInputs The split input parameters.
     * @return splitter The newly created splitter contract address.
     */
    function getOrCreateSplitter(
        SplitInputs calldata splitInputs
    ) external returns (address);

    /**
     * @notice Indicates the type of the contract, e.g. `SplitProviderV0`.
     * @return type_ The type of the contract.
     */
    function type_() external pure returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import {LibZip} from "solady/src/utils/LibZip.sol";

pragma solidity ^0.8.0;

/**
 * @title Art Blocks Script Storage Library
 * @notice Utilize contract bytecode as persistent storage for large chunks of script string data.
 *         V2 includes optional on-chain compression/decompression via solady LibZip.
 *         This library is intended to have an external deployed copy that is released in the future,
 *         and, as such, has been designed to support both updated V2 and V1 (versioned, with purging removed)
 *         reads as well as backwards-compatible reads for both a) the unversioned "V0" storage contracts
 *         which were deployed by the original version of this libary and b) contracts that were deployed
 *         using one of the SSTORE2 implementations referenced below.
 *         For these pre-V1 storage contracts (which themselves did not have any explicit versioning semantics)
 *         backwards-compatible reads are optimistic, and only expected to work for contracts actually
 *         deployed by the original version of this library – and may fail ungracefully if attempted to be
 *         used to read from other contracts.
 *         This library is split into two components, intended to be updated in tandem, and thus included
 *         here in the same source file. One component is an internal library that is intended to be embedded
 *         directly into other contracts and provides all _write_ functionality. The other is a public library
 *         that is intended to be deployed as a standalone contract and provides all _read_ functionality.
 *
 * @author Art Blocks Inc.
 * @author Modified from 0xSequence (https://github.com/0xsequence/sstore2/blob/master/contracts/SSTORE2.sol)
 * @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
 * @author Utilizes LibZip from solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibZip.sol)
 *
 * @dev Compared to the above two rerferenced libraries, this contracts-as-storage implementation makes a few
 *      notably different design decisions:
 *      - uses the `string` data type for input/output on reads, rather than speaking in bytes directly,
 *        with an exception for optionally compressed data which are input as bytes
 *      - stores the "writer" address (library user) in the deployed contract bytes, which is useful for
 *        on-chain introspection and provenance purposes
 *      - stores a very simple versioning string in the deployed contract bytes, which captures the version
 *        of the library that was used to deploy the storage contract and useful for supporting future
 *        compatibility management as this library evolves (e.g. in response to EOF v1 migration plans)
 *      - stores a bool indicating if the stored data are compressed.
 *      Also, given that much of this library is written in assembly, this library makes use of a slightly
 *      different convention (when compared to the rest of the Art Blocks smart contract repo) around
 *      pre-defining return values in some cases in order to simplify need to directly memory manage these
 *      return values.
 */

/**
 * @title Art Blocks Script Storage Library (Public, Reads)
 * @author Art Blocks Inc.
 * @notice The public library for reading from storage contracts. This library is intended to be deployed as a
 *         standalone contract, and provides all _read_ functionality.
 */
library BytecodeStorageReader {
    // Define the set of known valid version strings that may be stored in the deployed storage contract bytecode
    // note: These are all intentionally exactly 32-bytes and are null-terminated. Null-termination is used due
    //       to this being the standard expected formatting in common web3 tooling such as ethers.js. Please see
    //       the following for additional context: https://docs.ethers.org/v5/api/utils/strings/#Bytes32String
    // Used for storage contracts that were deployed by an unknown source
    bytes32 public constant UNKNOWN_VERSION_STRING =
        "UNKNOWN_VERSION_STRING_________ ";
    // Pre-dates versioning string, so this doesn't actually exist in any deployed contracts,
    // but is useful for backwards-compatible semantics with original version of this library
    bytes32 public constant V0_VERSION_STRING =
        "BytecodeStorage_V0.0.0_________ ";
    // The first versioned storage contract, deployed by an updated version of this library
    bytes32 public constant V1_VERSION_STRING =
        "BytecodeStorage_V1.0.0_________ ";
    // The first versioned storage contract, deployed by an updated version of this library
    bytes32 public constant V2_VERSION_STRING =
        "BytecodeStorage_V2.0.0_________ ";
    // The current version of this library.
    bytes32 public constant CURRENT_VERSION = V2_VERSION_STRING;

    //---------------------------------------------------------------------------------------------------------------//
    // Starting Index | Size | Ending Index | Description                                                            //
    //---------------------------------------------------------------------------------------------------------------//
    // 0              | N/A  | 0            |                                                                        //
    // 0              | 1    | 1            | single byte opcode for making the storage contract non-executable      //
    // 1              | 32   | 33           | the 32 byte slot used for storing a basic versioning string            //
    // 33             | 32   | 65           | the 32 bytes for storing the deploying contract's (0-padded) address   //
    // 65             | 1    | 66           | single byte indicating if the stored data are compressed               //
    //---------------------------------------------------------------------------------------------------------------//
    // Define the offset for where the "meta bytes" end, and the "data bytes" begin. Note that this is a manually
    // calculated value, and must be updated if the above table is changed. It is expected that tests will fail
    // loudly if these values are not updated in-step with eachother.
    uint256 private constant VERSION_OFFSET = 1;
    uint256 private constant ADDRESS_OFFSET = 33;
    uint256 private constant COMPRESSION_OFFSET = 65;
    uint256 private constant DATA_OFFSET = 66;

    // Define the set of known *historic* offset values for where the "meta bytes" end, and the "data bytes" begin.
    // SSTORE2 deployed storage contracts take the general format of:
    // concat(0x00, data)
    // note: this is true for both variants of the SSTORE2 library
    uint256 private constant SSTORE2_DATA_OFFSET = 1;
    // V0 deployed storage contracts take the general format of:
    // concat(gated-cleanup-logic, deployer-address, data)
    uint256 private constant V0_ADDRESS_OFFSET = 72;
    uint256 private constant V0_DATA_OFFSET = 104;
    // V1 deployed storage contracts take the general format of:
    // concat(invalid opcode, version, deployer-address, data)
    uint256 private constant V1_ADDRESS_OFFSET = 33;
    uint256 private constant V1_DATA_OFFSET = 65;
    // V2 deployed storage contracts take the general format of:
    // concat(invalid opcode, version, deployer-address, compression-bool, data)
    uint256 private constant V2_ADDRESS_OFFSET = ADDRESS_OFFSET;
    uint256 private constant V2_DATA_OFFSET = DATA_OFFSET;

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Read a string from contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 or V2 format
     * @return data string read from contract bytecode
     * @dev This function performs input validation that the contract to read is in an expected format
     */
    function readFromBytecode(
        address _address
    ) public view returns (string memory data) {
        (
            uint256 dataOffset,
            bool isCompressed
        ) = _bytecodeDataOffsetAndIsCompressedAt(_address);
        if (isCompressed) {
            return
                string(
                    LibZip.flzDecompress(
                        readBytesFromBytecode(_address, dataOffset)
                    )
                );
        } else {
            return string(readBytesFromBytecode(_address, dataOffset));
        }
    }

    /**
     * @notice Read the bytes from contract bytecode that was written to the EVM using SSTORE2
     * @param _address address of deployed contract with bytecode stored in the SSTORE2 format
     * @return data bytes read from contract bytecode
     * @dev This function performs no input validation on the provided contract,
     *      other than that there is content to read (but not that its a "storage contract")
     */
    function readBytesFromSSTORE2Bytecode(
        address _address
    ) public view returns (bytes memory data) {
        return readBytesFromBytecode(_address, SSTORE2_DATA_OFFSET);
    }

    /**
     * @notice Read the bytes from contract bytecode, with an explicitly provided starting offset
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @param _offset offset to read from in contract bytecode, explicitly provided (not calculated)
     * @return data bytes read from contract bytecode
     * @dev This function performs no input validation on the provided contract,
     *      other than that there is content to read (but not that its a "storage contract")
     */
    function readBytesFromBytecode(
        address _address,
        uint256 _offset
    ) public view returns (bytes memory data) {
        // get the size of the bytecode
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // handle case where address contains code < _offset
        if (bytecodeSize < _offset) {
            revert("ContractAsStorage: Read Error");
        }

        // handle case where address contains code >= dataOffset
        // decrement by dataOffset to account for header info
        uint256 size;
        unchecked {
            size = bytecodeSize - _offset;
        }

        assembly {
            // allocate free memory
            data := mload(0x40)
            // update free memory pointer
            // use and(x, not(0x1f) as cheaper equivalent to sub(x, mod(x, 0x20)).
            // adding 0x1f to size + logic above ensures the free memory pointer
            // remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length of data in first 32 bytes
            mstore(data, size)
            // copy code to memory, excluding the deployer-address
            extcodecopy(_address, add(data, 0x20), _offset, size)
        }
    }

    /**
     * @notice Get address for deployer for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @return writerAddress address read from contract bytecode
     */
    function getWriterAddressForBytecode(
        address _address
    ) public view returns (address) {
        // get the size of the data
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // the dataOffset for the bytecode
        uint256 addressOffset = _bytecodeAddressOffsetAt(_address);
        // handle case where address contains code < addressOffset + 32 (address takes a whole slot)
        if (bytecodeSize < (addressOffset + 32)) {
            revert("ContractAsStorage: Read Error");
        }

        assembly {
            // allocate free memory
            let writerAddress := mload(0x40)
            // shift free memory pointer by one slot
            mstore(0x40, add(mload(0x40), 0x20))
            // copy the 32-byte address of the data contract writer to memory
            // note: this relies on the assumption noted at the top-level of
            //       this file that the storage layout for the deployed
            //       contracts-as-storage contract looks like::
            //       | invalid opcode | version-string (unless v0) | deployer-address (padded) | data |
            extcodecopy(
                _address,
                writerAddress,
                addressOffset,
                0x20 // full 32-bytes, as address is expected to be zero-padded
            )
            return(
                writerAddress,
                0x20 // return size is entire slot, as it is zero-padded
            )
        }
    }

    /**
     * @notice Get version for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @return version version read from contract bytecode
     */
    function getLibraryVersionForBytecode(
        address _address
    ) public view returns (bytes32) {
        return _bytecodeVersionAt(_address);
    }

    /**
     * @notice Get if data are stored in compressed format for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0, V1, or V2 format
     * @return isCompressed boolean indicating if the stored data are compressed
     */
    function getIsCompressedForBytecode(
        address _address
    ) public view returns (bool) {
        (, bool isCompressed) = _bytecodeDataOffsetAndIsCompressedAt(_address);
        return isCompressed;
    }

    /**
     * Utility function to get the compressed form of a message string using solady LibZip's
     * flz compress algorithm.
     * The compressed message is returned as bytes, which may be used as the input to
     * the function `BytecodeStorageWriter.writeToBytecodeCompressed`.
     * @param _data string to be compressed
     * @return bytes compressed bytes
     */
    function getCompressed(
        string memory _data
    ) public pure returns (bytes memory) {
        return LibZip.flzCompress(bytes(_data));
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the size of the bytecode at address `_address`
     * @param _address address that may or may not contain bytecode
     * @return size size of the bytecode code at `_address`
     */
    function _bytecodeSizeAt(
        address _address
    ) private view returns (uint256 size) {
        assembly {
            size := extcodesize(_address)
        }
        if (size == 0) {
            revert("ContractAsStorage: Read Error");
        }
    }

    /**
     * @notice Returns the offset of the data in the bytecode at address `_address`
     * @param _address address that may or may not contain bytecode
     * @return dataOffset offset of data in bytecode if a known version, otherwise 0
     * @return isCompressed bool indicating if the stored data are compressed
     */
    function _bytecodeDataOffsetAndIsCompressedAt(
        address _address
    ) private view returns (uint256 dataOffset, bool isCompressed) {
        bytes32 version = _bytecodeVersionAt(_address);
        if (version == V2_VERSION_STRING) {
            dataOffset = V2_DATA_OFFSET;
            isCompressed = _isCompressedAt(_address, version);
        } else if (version == V1_VERSION_STRING) {
            dataOffset = V1_DATA_OFFSET;
            // isCompressed remains false, as V1 contracts do not support compression
        } else if (version == V0_VERSION_STRING) {
            dataOffset = V0_DATA_OFFSET;
            // isCompressed remains false, as V0 contracts do not support compression
        } else {
            // unknown version, revert
            revert("ContractAsStorage: Unsupported Version");
        }
    }

    /**
     * @notice Returns the offset of the address in the bytecode at address `_address`
     * @param _address address that may or may not contain bytecode
     * @return addressOffset offset of address in bytecode if a known version, otherwise 0
     */
    function _bytecodeAddressOffsetAt(
        address _address
    ) private view returns (uint256 addressOffset) {
        bytes32 version = _bytecodeVersionAt(_address);
        if (version == V2_VERSION_STRING) {
            addressOffset = V2_ADDRESS_OFFSET;
        } else if (version == V1_VERSION_STRING) {
            addressOffset = V1_ADDRESS_OFFSET;
        } else if (version == V0_VERSION_STRING) {
            addressOffset = V0_ADDRESS_OFFSET;
        } else {
            // unknown version, revert
            revert("ContractAsStorage: Unsupported Version");
        }
    }

    /**
     * @notice Get version string for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @return version version string read from contract bytecode
     */
    function _bytecodeVersionAt(
        address _address
    ) private view returns (bytes32 version) {
        // get the size of the data
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // handle case where address contains code < minimum expected version string size,
        // by returning early with the unknown version string
        if (bytecodeSize < (VERSION_OFFSET + 32)) {
            return UNKNOWN_VERSION_STRING;
        }

        assembly {
            // allocate free memory
            let versionString := mload(0x40)
            // shift free memory pointer by one slot
            mstore(0x40, add(mload(0x40), 0x20))
            // copy the 32-byte version string of the bytecode library to memory
            // note: this relies on the assumption noted at the top-level of
            //       this file that the storage layout for the deployed
            //       contracts-as-storage contract looks like:
            //       | invalid opcode | version-string (unless v0) | deployer-address (padded) | data |
            extcodecopy(
                _address,
                versionString,
                VERSION_OFFSET,
                0x20 // 32-byte version string
            )
            // note: must check against literal strings, as Yul does not allow for
            //       dynamic strings in switch statements.
            switch mload(versionString)
            case "BytecodeStorage_V2.0.0_________ " {
                version := V2_VERSION_STRING
            }
            case "BytecodeStorage_V1.0.0_________ " {
                version := V1_VERSION_STRING
            }
            case 0x2060486000396000513314601057fe5b60013614601957fe5b6000357fff0000 {
                // the v0 variant of this library pre-dates formal versioning w/ version strings,
                // so we check the first 32 bytes of the execution bytecode itself which
                // is static and known across all storage contracts deployed with the first version
                // of this library.
                version := V0_VERSION_STRING
            }
            default {
                version := UNKNOWN_VERSION_STRING
            }
        }
    }

    /**
     * @notice Get if stored data are compressed for given contract bytecode
     * @param _address address of deployed contract with bytecode stored
     * @param _version version string of the bytecode library used to deploy the contract at `_address`
     * @return isCompressed bool indicating if the stored data are compressed
     */
    function _isCompressedAt(
        address _address,
        bytes32 _version
    ) private view returns (bool isCompressed) {
        // @dev if branch no coverage - unreachable as used, remains for redundant safety
        if (_version == V0_VERSION_STRING || _version == V1_VERSION_STRING) {
            // V0 and V1 and unknown contracts do not support compression
            return false;
        }
        // @dev if branch no coverage - unreachable as used, remains for redundant safety
        if (_version != V2_VERSION_STRING) {
            // unsupported version, throw error
            revert("ContractAsStorage: Unsupported Version");
        }
        // get the size of the data
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // handle case where address contains code < minimum expected version string size,
        // by returning early with false
        if (bytecodeSize < (COMPRESSION_OFFSET + 1)) {
            return false;
        }

        assembly {
            // allocate free memory
            let compressedByte := mload(0x40)
            // shift free memory pointer by one slot
            mstore(0x40, add(mload(0x40), 0x20))
            // zero out word at compressedByte (solidity does not guarantee zeroed memory beyond free memory pointer)
            mstore(compressedByte, 0x00)
            // copy the 1-byte compressed flag of the bytecode library to memory
            // note: this relies on the assumption noted at the top-level of
            //       this file that the storage layout for the deployed
            //       contracts-as-storage contract looks like:
            //       | invalid opcode | version-string (unless v0) | deployer-address (padded) | isCompressed | data |
            extcodecopy(
                _address,
                compressedByte,
                COMPRESSION_OFFSET,
                0x1 // 1-byte version string
            )
            // check if the compressed flag is set
            switch mload(compressedByte)
            case 0x00 {
                isCompressed := false
            }
            default {
                isCompressed := true
            }
        }
    }
}

/**
 * @title Art Blocks Script Storage Library (Internal, Writes)
 * @author Art Blocks Inc.
 * @notice The internal library for writing to storage contracts. This library is intended to be deployed
 *         within library client contracts that use this library to perform _write_ operations on storage.
 */
library BytecodeStorageWriter {
    /*//////////////////////////////////////////////////////////////
                           WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Write a string to contract bytecode
     * @param _data string to be written to contract. No input validation is performed on this parameter.
     * @return address_ address of deployed contract with bytecode stored in the V2 format
     */
    function writeToBytecode(
        string memory _data
    ) internal returns (address address_) {
        // prefix bytecode with
        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // a.) creation code returns all code in the contract except for the first 11 (0B in hex) bytes, as these 11
            //     bytes are the creation code itself which we do not want to store in the deployed storage contract result
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x60_0B            | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xF3    |  0xF3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (11 bytes)
            hex"60_0B_59_81_38_03_80_92_59_39_F3",
            //---------------------------------------------------------------------------------------------------------------//
            // b.) ensure that the deployed storage contract is non-executeable (first opcode is the `invalid` opcode)
            //---------------------------------------------------------------------------------------------------------------//
            //---------------------------------------------------------------------------------------------------------------//
            // 0xFE    |  0xFE               | INVALID      |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (1 byte)
            hex"FE",
            //---------------------------------------------------------------------------------------------------------------//
            // c.) store the version string, which is already represented as a 32-byte value
            //---------------------------------------------------------------------------------------------------------------//
            // (32 bytes)
            BytecodeStorageReader.CURRENT_VERSION,
            //---------------------------------------------------------------------------------------------------------------//
            // d.) store the deploying-contract's address with 0-padding to fit a 20-byte address into a 32-byte slot
            //---------------------------------------------------------------------------------------------------------------//
            // (12 bytes)
            hex"00_00_00_00_00_00_00_00_00_00_00_00",
            // (20 bytes)
            address(this),
            //---------------------------------------------------------------------------------------------------------------//
            // e.) store the bool indicating if the data is compressed. true for this function.
            //---------------------------------------------------------------------------------------------------------------//
            // (1 byte)
            hex"00",
            // uploaded data (stored as bytecode) comes last
            _data
        );

        assembly {
            // deploy a new contract with the generated creation code.
            // start 32 bytes into creationCode to avoid copying the byte length.
            address_ := create(0, add(creationCode, 0x20), mload(creationCode))
        }

        // address must be non-zero if contract was deployed successfully
        require(address_ != address(0), "ContractAsStorage: Write Error");
    }

    /**
     * @notice Write a string to contract bytecode, input as compressed bytes from solady LibZip
     * @param _dataCompressed compressed bytes to be written to contract. No input validation is performed on this parameter.
     * @return address_ address of deployed contract with bytecode stored in the V2 format
     */
    function writeToBytecodeCompressed(
        bytes memory _dataCompressed
    ) internal returns (address address_) {
        // prefix bytecode with
        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // a.) creation code returns all code in the contract except for the first 11 (0B in hex) bytes, as these 11
            //     bytes are the creation code itself which we do not want to store in the deployed storage contract result
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x60_0B            | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xF3    |  0xF3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (11 bytes)
            hex"60_0B_59_81_38_03_80_92_59_39_F3",
            //---------------------------------------------------------------------------------------------------------------//
            // b.) ensure that the deployed storage contract is non-executeable (first opcode is the `invalid` opcode)
            //---------------------------------------------------------------------------------------------------------------//
            //---------------------------------------------------------------------------------------------------------------//
            // 0xFE    |  0xFE               | INVALID      |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (1 byte)
            hex"FE",
            //---------------------------------------------------------------------------------------------------------------//
            // c.) store the version string, which is already represented as a 32-byte value
            //---------------------------------------------------------------------------------------------------------------//
            // (32 bytes)
            BytecodeStorageReader.CURRENT_VERSION,
            //---------------------------------------------------------------------------------------------------------------//
            // d.) store the deploying-contract's address with 0-padding to fit a 20-byte address into a 32-byte slot
            //---------------------------------------------------------------------------------------------------------------//
            // (12 bytes)
            hex"00_00_00_00_00_00_00_00_00_00_00_00",
            // (20 bytes)
            address(this),
            //---------------------------------------------------------------------------------------------------------------//
            // e.) store the bool indicating if the data is compressed. true for this function.
            //---------------------------------------------------------------------------------------------------------------//
            // (1 byte)
            hex"01",
            // uploaded compressed data (stored as bytecode) comes last
            _dataCompressed
        );

        assembly {
            // deploy a new contract with the generated creation code.
            // start 32 bytes into creationCode to avoid copying the byte length.
            address_ := create(0, add(creationCode, 0x20), mload(creationCode))
        }

        // address must be non-zero if contract was deployed successfully
        require(address_ != address(0), "ContractAsStorage: Write Error");
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
// Inspired by: https://ethereum.stackexchange.com/a/123950/103422

pragma solidity ^0.8.0;

/**
 * @dev Operations on bytes32 data type, dealing with conversion to string.
 */
library Bytes32Strings {
    /**
     * @notice Intended to convert a `bytes32`-encoded string literal to `string`.
     * Trims zero padding to arrive at original string literal.
     */
    function toString(
        bytes32 source
    ) internal pure returns (string memory result) {
        uint8 length;
        while (source[length] != 0 && length < 32) {
            length++;
        }
        assembly {
            // free memory pointer
            result := mload(0x40)
            // update free memory pointer to new "memory end"
            // (offset is 64-bytes: 32 for length, 32 for data)
            mstore(0x40, add(result, 0x40))
            // store length in first 32-byte memory slot
            mstore(result, length)
            // write actual data in second 32-byte memory slot
            mstore(add(result, 0x20), source)
        }
    }

    /**
     * @notice Intended to check if a `bytes32`-encoded string contains a given
     * character with UTF-8 character code `utf8CharCode exactly `targetQty`
     * times. Does not support searching for multi-byte characters, only
     * characters with UTF-8 character codes < 0x80.
     */
    function containsExactCharacterQty(
        bytes32 source,
        uint8 utf8CharCode,
        uint8 targetQty
    ) internal pure returns (bool) {
        uint8 _occurrences;
        uint8 i;
        for (i; i < 32; ) {
            uint8 _charCode = uint8(source[i]);
            // if not a null byte, or a multi-byte UTF-8 character, check match
            if (_charCode != 0 && _charCode < 0x80) {
                if (_charCode == utf8CharCode) {
                    unchecked {
                        // no risk of overflow since max 32 iterations < max uin8=255
                        ++_occurrences;
                    }
                }
            }
            unchecked {
                // no risk of overflow since max 32 iterations < max uin8=255
                ++i;
            }
        }
        return _occurrences == targetQty;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin-5.0/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin-5.0/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721Metadata} from "@openzeppelin-5.0/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Context} from "@openzeppelin-5.0/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin-5.0/contracts/utils/Strings.sol";
import {IERC165, ERC165} from "@openzeppelin-5.0/contracts/utils/introspection/ERC165.sol";
import {IERC721Errors} from "@openzeppelin-5.0/contracts/interfaces/draft-IERC6093.sol";

/**
 * @dev Forked version of the OpenZeppelin v5.0.1 ERC721 contract. Updated
 * with an initialize function to ensure EIP 1167 compatibility. Utilizes
 * a struct to pack owner and hash seed into a single storage slot.
 * ---------------------
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721_PackedHashSeedV1 is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Errors
{
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    /// ensure initialization can only be performed once
    bool private _initialized;

    /// struct to pack a token owner and hash seed into same storage slot
    struct OwnerAndHashSeed {
        // 20 bytes for address of token's owner
        address owner;
        // remaining 12 bytes allocated to token hash seed
        bytes12 hashSeed;
    }

    /// mapping of token ID to OwnerAndHashSeed
    /// @dev visibility internal so inheriting contracts can access
    mapping(uint256 tokenId => OwnerAndHashSeed) internal _ownersAndHashSeeds;

    mapping(address owner => uint256) private _balances;

    mapping(uint256 tokenId => address) private _tokenApprovals;

    mapping(address owner => mapping(address operator => bool))
        private _operatorApprovals;

    // @dev constructor intentionally removed to allow for EIP 1167 compatibility,
    // see `initialize` function for contract initialization

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string.concat(baseURI, tokenId.toString())
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, _msgSender());
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual returns (address) {
        _requireOwned(tokenId);

        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @notice Initializes the contract by setting a `name` and a `symbol` to the token collection.
     * This function should be called atomically, immediately after deployment.
     * Only callable once.
     * @param name_ Name for the token collection.
     * @param symbol_ Symbol for the token collection.
     */
    function initialize(string memory name_, string memory symbol_) internal {
        require(!_initialized, "Already initialized");
        _name = name_;
        _symbol = symbol_;
        _initialized = true;
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     *
     * IMPORTANT: Any overrides to this function that add ownership of tokens not tracked by the
     * core ERC721 logic MUST be matched with the use of {_increaseBalance} to keep balances
     * consistent with ownership. The invariant to preserve is that for any address `a` the value returned by
     * `balanceOf(a)` must be equal to the number of tokens such that `_ownerOf(tokenId)` is `a`.
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _ownersAndHashSeeds[tokenId].owner;
    }

    /**
     * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
     */
    function _getApproved(
        uint256 tokenId
    ) internal view virtual returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
     * particular (ignoring whether it is owned by `owner`).
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _isAuthorized(
        address owner,
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender ||
                isApprovedForAll(owner, spender) ||
                _getApproved(tokenId) == spender);
    }

    /**
     * @dev Checks if `spender` can operate on `tokenId`, assuming the provided `owner` is the actual owner.
     * Reverts if `spender` does not have approval from the provided `owner` for the given token or for all its assets
     * the `spender` for the specific `tokenId`.
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _checkAuthorized(
        address owner,
        address spender,
        uint256 tokenId
    ) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * NOTE: the value is limited to type(uint128).max. This protect against _balance overflow. It is unrealistic that
     * a uint256 would ever overflow from increments when these increments are bounded to uint128 values.
     *
     * WARNING: Increasing an account's balance using this function tends to be paired with an override of the
     * {_ownerOf} function to resolve the ownership of the corresponding tokens so that balances and ownership
     * remain consistent with one another.
     */
    function _increaseBalance(address account, uint128 value) internal virtual {
        unchecked {
            _balances[account] += value;
        }
    }

    /**
     * @dev Transfers `tokenId` from its current owner to `to`, or alternatively mints (or burns) if the current owner
     * (or `to`) is the zero address. Returns the owner of the `tokenId` before the update.
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that
     * `auth` is either the owner of the token, or approved to operate on the token (by the owner).
     *
     * Emits a {Transfer} event.
     *
     * NOTE: If overriding this function in a way that tracks balances, see also {_increaseBalance}.
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual returns (address) {
        address from = _ownerOf(tokenId);

        // Perform (optional) operator check
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        // Execute the update
        if (from != address(0)) {
            // Clear approval. No need to re-authorize or emit the Approval event
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                _balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                _balances[to] += 1;
            }
        }

        _ownersAndHashSeeds[tokenId].owner = to;

        emit Transfer(from, to, tokenId);

        return from;
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
    }

    /**
     * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        _checkOnERC721Received(address(0), to, tokenId, data);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal {
        address previousOwner = _update(address(0), tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        } else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking that contract recipients
     * are aware of the ERC721 standard to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is like {safeTransferFrom} in the sense that it invokes
     * {IERC721Receiver-onERC721Received} on the receiver, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `tokenId` token must exist and be owned by `from`.
     * - `to` cannot be the zero address.
     * - `from` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeTransfer-address-address-uint256-}[`_safeTransfer`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that `auth` is
     * either the owner of the token, or approved to operate on all tokens held by this owner.
     *
     * Emits an {Approval} event.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }

    /**
     * @dev Variant of `_approve` with an optional flag to enable or disable the {Approval} event. The event is not
     * emitted in the context of transfers.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address auth,
        bool emitEvent
    ) internal virtual {
        // Avoid reading the owner unless necessary
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);

            // We do not use _isAuthorized because single-token approvals should not be able to call approve
            if (
                auth != address(0) &&
                owner != auth &&
                !isApprovedForAll(owner, auth)
            ) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        _tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Requirements:
     * - operator can't be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` doesn't have a current owner (it hasn't been minted, or it has been burned).
     * Returns the owner.
     *
     * Overrides to ownership logic should be done to {_ownerOf}.
     */
    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address. This will revert if the
     * recipient doesn't accept the token transfer. The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for compressing and decompressing bytes.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibZip.sol)
/// @author Calldata compression by clabby (https://github.com/clabby/op-kompressor)
/// @author FastLZ by ariya (https://github.com/ariya/FastLZ)
///
/// @dev Note:
/// The accompanying solady.js library includes implementations of
/// FastLZ and calldata operations for convenience.
library LibZip {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     FAST LZ OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // LZ77 implementation based on FastLZ.
    // Equivalent to level 1 compression and decompression at the following commit:
    // https://github.com/ariya/FastLZ/commit/344eb4025f9ae866ebf7a2ec48850f7113a97a42
    // Decompression is backwards compatible.

    /// @dev Returns the compressed `data`.
    function flzCompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function ms8(d_, v_) -> _d {
                mstore8(d_, v_)
                _d := add(d_, 1)
            }
            function u24(p_) -> _u {
                _u := mload(p_)
                _u := or(shl(16, byte(2, _u)), or(shl(8, byte(1, _u)), byte(0, _u)))
            }
            function cmp(p_, q_, e_) -> _l {
                for { e_ := sub(e_, q_) } lt(_l, e_) { _l := add(_l, 1) } {
                    e_ := mul(iszero(byte(0, xor(mload(add(p_, _l)), mload(add(q_, _l))))), e_)
                }
            }
            function literals(runs_, src_, dest_) -> _o {
                for { _o := dest_ } iszero(lt(runs_, 0x20)) { runs_ := sub(runs_, 0x20) } {
                    mstore(ms8(_o, 31), mload(src_))
                    _o := add(_o, 0x21)
                    src_ := add(src_, 0x20)
                }
                if iszero(runs_) { leave }
                mstore(ms8(_o, sub(runs_, 1)), mload(src_))
                _o := add(1, add(_o, runs_))
            }
            function mt(l_, d_, o_) -> _o {
                for { d_ := sub(d_, 1) } iszero(lt(l_, 263)) { l_ := sub(l_, 262) } {
                    o_ := ms8(ms8(ms8(o_, add(224, shr(8, d_))), 253), and(0xff, d_))
                }
                if iszero(lt(l_, 7)) {
                    _o := ms8(ms8(ms8(o_, add(224, shr(8, d_))), sub(l_, 7)), and(0xff, d_))
                    leave
                }
                _o := ms8(ms8(o_, add(shl(5, l_), shr(8, d_))), and(0xff, d_))
            }
            function setHash(i_, v_) {
                let p_ := add(mload(0x40), shl(2, i_))
                mstore(p_, xor(mload(p_), shl(224, xor(shr(224, mload(p_)), v_))))
            }
            function getHash(i_) -> _h {
                _h := shr(224, mload(add(mload(0x40), shl(2, i_))))
            }
            function hash(v_) -> _r {
                _r := and(shr(19, mul(2654435769, v_)), 0x1fff)
            }
            function setNextHash(ip_, ipStart_) -> _ip {
                setHash(hash(u24(ip_)), sub(ip_, ipStart_))
                _ip := add(ip_, 1)
            }
            result := mload(0x40)
            codecopy(result, codesize(), 0x8000) // Zeroize the hashmap.
            let op := add(result, 0x8000)
            let a := add(data, 0x20)
            let ipStart := a
            let ipLimit := sub(add(ipStart, mload(data)), 13)
            for { let ip := add(2, a) } lt(ip, ipLimit) {} {
                let r := 0
                let d := 0
                for {} 1 {} {
                    let s := u24(ip)
                    let h := hash(s)
                    r := add(ipStart, getHash(h))
                    setHash(h, sub(ip, ipStart))
                    d := sub(ip, r)
                    if iszero(lt(ip, ipLimit)) { break }
                    ip := add(ip, 1)
                    if iszero(gt(d, 0x1fff)) { if eq(s, u24(r)) { break } }
                }
                if iszero(lt(ip, ipLimit)) { break }
                ip := sub(ip, 1)
                if gt(ip, a) { op := literals(sub(ip, a), a, op) }
                let l := cmp(add(r, 3), add(ip, 3), add(ipLimit, 9))
                op := mt(l, d, op)
                ip := setNextHash(setNextHash(add(ip, l), ipStart), ipStart)
                a := ip
            }
            // Copy the result to compact the memory, overwriting the hashmap.
            let end := sub(literals(sub(add(ipStart, mload(data)), a), a, op), 0x7fe0)
            let o := add(result, 0x20)
            mstore(result, sub(end, o)) // Store the length.
            for {} iszero(gt(o, end)) { o := add(o, 0x20) } { mstore(o, mload(add(o, 0x7fe0))) }
            mstore(end, 0) // Zeroize the slot after the string.
            mstore(0x40, add(end, 0x20)) // Allocate the memory.
        }
    }

    /// @dev Returns the decompressed `data`.
    function flzDecompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let op := add(result, 0x20)
            let end := add(add(data, 0x20), mload(data))
            for { data := add(data, 0x20) } lt(data, end) {} {
                let w := mload(data)
                let c := byte(0, w)
                let t := shr(5, c)
                if iszero(t) {
                    mstore(op, mload(add(data, 1)))
                    data := add(data, add(2, c))
                    op := add(op, add(1, c))
                    continue
                }
                for {
                    let g := eq(t, 7)
                    let l := add(2, xor(t, mul(g, xor(t, add(7, byte(1, w)))))) // M
                    let s := add(add(shl(8, and(0x1f, c)), byte(add(1, g), w)), 1) // R
                    let r := sub(op, s)
                    let f := xor(s, mul(gt(s, 0x20), xor(s, 0x20)))
                    let j := 0
                } 1 {} {
                    mstore(add(op, j), mload(add(r, j)))
                    j := add(j, f)
                    if lt(j, l) { continue }
                    data := add(data, add(2, g))
                    op := add(op, l)
                    break
                }
            }
            mstore(result, sub(op, add(result, 0x20))) // Store the length.
            mstore(op, 0) // Zeroize the slot after the string.
            mstore(0x40, add(op, 0x20)) // Allocate the memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    CALLDATA OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Calldata compression and decompression using selective run length encoding:
    // - Sequences of 0x00 (up to 128 consecutive).
    // - Sequences of 0xff (up to 32 consecutive).
    //
    // A run length encoded block consists of two bytes:
    // (0) 0x00
    // (1) A control byte with the following bit layout:
    //     - [7]     `0: 0x00, 1: 0xff`.
    //     - [0..6]  `runLength - 1`.
    //
    // The first 4 bytes are bitwise negated so that the compressed calldata
    // can be dispatched into the `fallback` and `receive` functions.

    /// @dev Returns the compressed `data`.
    function cdCompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function rle(v_, o_, d_) -> _o, _d {
                mstore(o_, shl(240, or(and(0xff, add(d_, 0xff)), and(0x80, v_))))
                _o := add(o_, 2)
            }
            result := mload(0x40)
            let o := add(result, 0x20)
            let z := 0 // Number of consecutive 0x00.
            let y := 0 // Number of consecutive 0xff.
            for { let end := add(data, mload(data)) } iszero(eq(data, end)) {} {
                data := add(data, 1)
                let c := byte(31, mload(data))
                if iszero(c) {
                    if y { o, y := rle(0xff, o, y) }
                    z := add(z, 1)
                    if eq(z, 0x80) { o, z := rle(0x00, o, 0x80) }
                    continue
                }
                if eq(c, 0xff) {
                    if z { o, z := rle(0x00, o, z) }
                    y := add(y, 1)
                    if eq(y, 0x20) { o, y := rle(0xff, o, 0x20) }
                    continue
                }
                if y { o, y := rle(0xff, o, y) }
                if z { o, z := rle(0x00, o, z) }
                mstore8(o, c)
                o := add(o, 1)
            }
            if y { o, y := rle(0xff, o, y) }
            if z { o, z := rle(0x00, o, z) }
            // Bitwise negate the first 4 bytes.
            mstore(add(result, 4), not(mload(add(result, 4))))
            mstore(result, sub(o, add(result, 0x20))) // Store the length.
            mstore(o, 0) // Zeroize the slot after the string.
            mstore(0x40, add(o, 0x20)) // Allocate the memory.
        }
    }

    /// @dev Returns the decompressed `data`.
    function cdDecompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(data) {
                result := mload(0x40)
                let o := add(result, 0x20)
                let s := add(data, 4)
                let v := mload(s)
                let end := add(data, mload(data))
                mstore(s, not(v)) // Bitwise negate the first 4 bytes.
                for {} lt(data, end) {} {
                    data := add(data, 1)
                    let c := byte(31, mload(data))
                    if iszero(c) {
                        data := add(data, 1)
                        let d := byte(31, mload(data))
                        // Fill with either 0xff or 0x00.
                        mstore(o, not(0))
                        if iszero(gt(d, 0x7f)) { codecopy(o, codesize(), add(d, 1)) }
                        o := add(o, add(and(d, 0x7f), 1))
                        continue
                    }
                    mstore8(o, c)
                    o := add(o, 1)
                }
                mstore(s, v) // Restore the first 4 bytes.
                mstore(result, sub(o, add(result, 0x20))) // Store the length.
                mstore(o, 0) // Zeroize the slot after the string.
                mstore(0x40, add(o, 0x20)) // Allocate the memory.
            }
        }
    }

    /// @dev To be called in the `fallback` function.
    /// ```
    ///     fallback() external payable { LibZip.cdFallback(); }
    ///     receive() external payable {} // Silence compiler warning to add a `receive` function.
    /// ```
    /// For efficiency, this function will directly return the results, terminating the context.
    /// If called internally, it must be called at the end of the function.
    function cdFallback() internal {
        assembly {
            if iszero(calldatasize()) { return(calldatasize(), calldatasize()) }
            let o := 0
            let f := not(3) // For negating the first 4 bytes.
            for { let i := 0 } lt(i, calldatasize()) {} {
                let c := byte(0, xor(add(i, f), calldataload(i)))
                i := add(i, 1)
                if iszero(c) {
                    let d := byte(0, xor(add(i, f), calldataload(i)))
                    i := add(i, 1)
                    // Fill with either 0xff or 0x00.
                    mstore(o, not(0))
                    if iszero(gt(d, 0x7f)) { codecopy(o, codesize(), add(d, 1)) }
                    o := add(o, add(and(d, 0x7f), 1))
                    continue
                }
                mstore8(o, c)
                o := add(o, 1)
            }
            let success := delegatecall(gas(), address(), 0x00, o, codesize(), 0x00)
            returndatacopy(0x00, 0x00, returndatasize())
            if iszero(success) { revert(0x00, returndatasize()) }
            return(0x00, returndatasize())
        }
    }
}