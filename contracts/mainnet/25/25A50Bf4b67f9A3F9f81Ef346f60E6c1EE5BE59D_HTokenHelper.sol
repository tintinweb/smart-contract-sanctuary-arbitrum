// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "./HTokenI.sol";
import "./PermissionlessOracleI.sol";

/**
 * @title   Interface of Controller
 * @author  Honey Labs Inc.
 * @custom:coauthor     m4rio
 * @custom:contributor  BowTiedPickle
 */
interface ControllerI {
  /**
   * @notice returns the oracle per market
   */
  function oracle(HTokenI _hToken) external view returns (PermissionlessOracleI);

  /**
   * @notice Add assets to be included in account liquidity calculation
   * @param _hTokens The list of addresses of the hToken markets to be enabled
   */
  function enterMarkets(HTokenI[] calldata _hTokens) external;

  /**
   * @notice Removes asset from sender's account liquidity calculation
   * @dev Sender must not have an outstanding borrow balance in the asset,
   *  or be providing necessary collateral for an outstanding borrow.
   * @param _hToken The address of the asset to be removed
   */
  function exitMarket(HTokenI _hToken) external;

  /**
   * @notice Checks if the account should be allowed to deposit underlying in the market
   * @param _hToken The market to verify the redeem against
   * @param _depositor The account which that wants to deposit
   * @param _amount The number of underlying it wants to deposit
   */
  function depositUnderlyingAllowed(
    HTokenI _hToken,
    address _depositor,
    uint256 _amount
  ) external;

  /**
   * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
   * @param _hToken The market to verify the borrow against
   * @param _borrower The account which would borrow the asset
   * @param _collateralId collateral Id, aka the NFT token Id
   * @param _borrowAmount The amount of underlying the account would borrow
   */
  function borrowAllowed(
    HTokenI _hToken,
    address _borrower,
    uint256 _collateralId,
    uint256 _borrowAmount
  ) external;

  /**
   * @notice Checks if the account should be allowed to deposit a collateral
   * @param _hToken The market to verify the deposit of the collateral
   * @param _depositor The account which deposits the collateral
   * @param _collateralId The collateral token id
   */
  function depositCollateralAllowed(
    HTokenI _hToken,
    address _depositor,
    uint256 _collateralId
  ) external;

  /**
   * @notice Checks if the account should be allowed to redeem tokens in the given market
   * @param _hToken The market to verify the redeem against
   * @param _redeemer The account which would redeem the tokens
   * @param _redeemTokens The number of hTokens to exchange for the underlying asset in the market
   */
  function redeemAllowed(
    HTokenI _hToken,
    address _redeemer,
    uint256 _redeemTokens
  ) external view;

  /**
   * @notice Checks if the collateral is at risk of being liquidated
   * @param _hToken The market to verify the liquidation
   * @param _collateralId collateral Id, aka the NFT token Id
   */
  function liquidationAllowed(HTokenI _hToken, uint256 _collateralId) external view;

  /**
   * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
   * @param _hToken The market to hypothetically redeem/borrow in
   * @param _account The account to determine liquidity for
   * @param _redeemTokens The number of tokens to hypothetically redeem
   * @param _borrowAmount The amount of underlying to hypothetically borrow
   * @param _collateralId collateral Id, aka the NFT token Id
   * @return liquidity - hypothetical account liquidity in excess of collateral requirements
   * @return shortfall - hypothetical account shortfall below collateral requirements
   * @return ltvShortfall - Loan to value shortfall, this is the max a user can borrow
   */
  function getHypotheticalAccountLiquidity(
    HTokenI _hToken,
    address _account,
    uint256 _collateralId,
    uint256 _redeemTokens,
    uint256 _borrowAmount
  )
    external
    view
    returns (
      uint256 liquidity,
      uint256 shortfall,
      uint256 ltvShortfall
    );

  /**
   * @notice Returns whether the given account is entered in the given asset
   * @param _hToken The hToken to check
   * @param _account The address of the account to check
   * @return True if the account is in the asset, otherwise false.
   */
  function checkMembership(HTokenI _hToken, address _account) external view returns (bool);

  /**
   * @notice Checks if the account should be allowed to transfer tokens in the given market
   * @param _hToken The market to verify the transfer against
   */
  function transferAllowed(HTokenI _hToken) external;

  /**
   * @notice Checks if the account should be allowed to repay a borrow in the given market
   * @param _hToken The market to verify the repay against
   * @param _repayAmount The amount of the underlying asset the account would repay
   * @param _collateralId collateral Id, aka the NFT token Id
   */
  function repayBorrowAllowed(
    HTokenI _hToken,
    uint256 _repayAmount,
    uint256 _collateralId
  ) external view;

  /**
   * @notice checks if withdrawal are allowed for this token id
   * @param _hToken The market to verify the withdrawal from
   * @param _collateralId what to pay for
   */
  function withdrawCollateralAllowed(HTokenI _hToken, uint256 _collateralId) external view;

  /**
   * @notice checks if a market exists and it's listed
   * @param _hToken the market we check to see if it exists
   * @return bool true or false
   */
  function marketExists(HTokenI _hToken) external view returns (bool);

  /**
   * @notice Returns market data for a specific market
   * @param _hToken the market we want to retrieved Controller data
   * @return bool If the market is listed
   * @return uint256 MAX Factor Mantissa
   * @return uint256 Collateral Factor Mantissa
   */
  function getMarketData(HTokenI _hToken)
    external
    view
    returns (
      bool,
      uint256,
      uint256
    );

  /**
   * @notice checks if an underlying exists in the market
   * @param _underlying the underlying to check if exists
   * @return bool true or false
   */
  function underlyingExistsInMarkets(address _underlying) external view returns (bool);

  /**
   * @notice checks if a collateral exists in the market
   * @param _collateral the collateral to check if exists
   * @return bool true or false
   */
  function collateralExistsInMarkets(address _collateral) external view returns (bool);

  /**
   * @notice  Checks if a certain action is paused within a market
   * @param   _hToken   The market we want to check if an action is paused
   * @param   _target   The action we want to check if it's paused
   * @return  bool true or false
   */
  function isActionPaused(HTokenI _hToken, uint256 _target) external view returns (bool);

  /**
   * @notice returns the borrow fee per market, accounts for referral
   * @param _hToken the market we want the borrow fee for
   * @param _referral referral code for Referral program of Honey Labs
   * @param _signature signed message provided by Honey Labs
   */
  function getBorrowFeePerMarket(
    HTokenI _hToken,
    string calldata _referral,
    bytes calldata _signature
  ) external view returns (uint256, bool);

  /**
   * @notice returns the borrow fee per market if provided a referral code, accounts for referral
   * @param _hToken the market we want the borrow fee for
   */
  function getReferralBorrowFeePerMarket(HTokenI _hToken) external view returns (uint256);

  // ---------- Permissioned Functions ----------

  function _supportMarket(HTokenI _hToken) external;

  function _setPriceOracle(HTokenI _hToken, PermissionlessOracleI _newOracle) external;

  function _setFactors(
    HTokenI _hToken,
    uint256 _newMaxLTVFactorMantissa,
    uint256 _newCollateralFactorMantissa
  ) external;

  function _setBorrowFeePerMarket(
    HTokenI _market,
    uint256 _fee,
    uint256 _referralFee
  ) external;

  function _pauseComponent(
    HTokenI _hToken,
    bool _state,
    uint256 _target
  ) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import ".././interfaces/HTokenI.sol";
import ".././interfaces/PriceOracleI.sol";
import ".././interfaces/ControllerI.sol";

/**
 * @title   Interface for HTokenHelper
 * @author  Honey Labs Inc.
 * @custom:coauthor     m4rio
 * @custom:contributor  BowTiedPickle
 */
interface HTokenHelperI {
  /**
   * @notice Get underlying balance that is available for withdrawal or borrow
   * @return The quantity of underlying not tied up
   */
  function getAvailableUnderlying(HTokenI _hToken) external view returns (uint256);

  /**
   * @notice Get underlying balance for an account
   * @param _account the account to check the balance for
   * @return The quantity of underlying asset owned by this account
   */
  function getAvailableUnderlyingForUser(HTokenI _hToken, address _account) external view returns (uint256);

  /**
   * @notice returns different assets per a hToken, helper method to reduce frontend calls
   * @param _hToken the hToken to get the assets for
   * @return total borrows
   * @return total reserves
   * @return total underlying balance
   * @return active coupons
   */
  function getAssets(HTokenI _hToken) external view returns (uint256, uint256, uint256, HTokenI.Coupon[] memory);

  /**
   * @notice Get all a user's coupons
   * @param _hToken The HToken we want to get the user's coupons from
   * @param _user The user to search for
   * @return Array of all coupons belonging to the user
   */
  function getUserCoupons(HTokenI _hToken, address _user) external view returns (HTokenI.Coupon[] memory);

  /**
   * @notice Get the number of coupons deposited aka active
   * @param _hToken The HToken we want to get the active User Coupons
   * @param _hasDebt if the coupon has debt or not
   * @return Array of all active coupons
   */
  function getActiveCoupons(HTokenI _hToken, bool _hasDebt) external view returns (HTokenI.Coupon[] memory);

  /**
   * @notice Get tokenIds of all a user's coupons
   * @param _hToken The HToken we want to get the User Coupon Indices
   * @param _user The user to search for
   * @return Array of indices of all coupons belonging to the user
   */
  function getUserCouponIndices(HTokenI _hToken, address _user) external view returns (uint256[] memory);

  /**
   * @notice returns prices for a market to reduce frontend calls
   * @param _hToken the hToken to get the prices for
   * @return collection floor price in underlying value
   * @return underlying price in usd
   */
  function getMarketOraclePrices(HTokenI _hToken) external view returns (uint256, uint256);

  /**
   * @notice Returns the borrow fee for a market, it can also return the discounted fee for referred borrow
   * @param _hToken The market we want to get the borrow fee for
   * @param _referred Flag that needs to be true in case we want to get the referred borrow fee
   * @return fee - The borrow fee mantissa denominated in 1e18
   */
  function getMarketBorrowFee(HTokenI _hToken, bool _referred) external view returns (uint256 fee);

  /**
   * @notice returns the collection price floor in usd
   * @param _hToken the hToken to get the price for
   * @return collection floor price in usd
   */
  function getFloorPriceInUSD(HTokenI _hToken) external view returns (uint256);

  /**
   * @notice returns the collection price floor in underlying value
   * @param _hToken the hToken to get the price for
   * @return collection floor price in underlying
   */
  function getFloorPriceInUnderlying(HTokenI _hToken) external view returns (uint256);

  /**
   * @notice get the underlying price in usd for a hToken
   * @param _hToken the hToken to get the price for
   * @return underlying price in usd
   */
  function getUnderlyingPriceInUSD(HTokenI _hToken) external view returns (uint256);

  /**
   * @notice get the max borrowable amount for a market
   * @notice it computes the floor price in usd and take the % of collateral factor that can be max borrowed
   *         then it divides it by the underlying price in usd.
   * @param _hToken the hToken to get the price for
   * @param _hivemind the controller used to get the collateral factor
   * @return underlying price in underlying
   */
  function getMaxBorrowableAmountInUnderlying(HTokenI _hToken, ControllerI _hivemind) external view returns (uint256);

  /**
   * @notice get the max borrowable amount for a market
   * @notice it computes the floor price in usd and take the % of collateral factor that can be max borrowed
   * @param _hToken the hToken to get the price for
   * @param _hivemind the controller used to get the collateral factor
   * @return underlying price in usd
   */
  function getMaxBorrowableAmountInUSD(HTokenI _hToken, ControllerI _hivemind) external view returns (uint256);

  /**
   * @notice get's all the coupons that have deposited collateral
   * @param _hToken market to get the collateral from
   * @param _startTokenId start token id of the collateral collection, as we don't know how big the collection will be we have
   * to do pagination
   * @param _endTokenId end of token id we want to get.
   * @return coupons list of coupons that are active
   */
  function getAllCollateralPerHToken(
    HTokenI _hToken,
    uint256 _startTokenId,
    uint256 _endTokenId
  ) external view returns (HTokenI.Coupon[] memory coupons);

  /**
   * @notice Gets data about a market for frontend display
   * @param _hToken the market we want the data for
   * @return interest rate of the market
   * @return total underlying supplied in a market
   * @return total underlying available to be borrowed
   */
  function getFrontendMarketData(HTokenI _hToken) external view returns (uint256, uint256, uint256);

  /**
   * @notice Gets data about a coupon for frontend display
   * @param _hToken   The market we want the coupon for
   * @param _couponId The coupon id we want to get the data for
   * @return debt of this coupon
   * @return allowance - how much liquidity can borrow till hitting LTV
   * @return nft floor price
   */
  function getFrontendCouponData(HTokenI _hToken, uint256 _couponId) external view returns (uint256, uint256, uint256);

  /**
   * @notice Gets Liquidation data for a market, for frontend purposes
   * @param _hToken the market we want the data for
   * @return Liquidation threshold of a market (collateral factor)
   * @return Total debt of the market
   * @return TVL of a market which consists of the total coupons that have debt
   */
  function getFrontendLiquidationData(HTokenI _hToken) external view returns (uint256, uint256, uint256);

  /**
   * @notice uri function called from the HToken that returns the uri metadata for a coupon
   * @param _id id of the hToken
   * @param _hTokenAddress address of the hToken
   */
  function uri(uint256 _id, address _hTokenAddress) external view returns (string memory);
}

//SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.4;
import "./HTokenInternalI.sol";

/**
 * @title   Interface of HToken
 * @author  Honey Labs Inc.
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
interface HTokenI is HTokenInternalI {
  /**
   * @notice  Deposit underlying ERC-20 asset and mint hTokens
   * @dev     Pull pattern, user must approve the contract before calling. If _to is address(0) then it becomes msg.sender
   * @param   _amount   Quantity of underlying ERC-20 to transfer in
   * @param   _to       Target address to mint hTokens to
   */
  function depositUnderlying(uint256 _amount, address _to) external;

  /**
   * @notice  Redeem a specified amount of hTokens for their underlying ERC-20 asset
   * @param   _amount   Quantity of hTokens to redeem for underlying ERC-20
   */
  function redeem(uint256 _amount) external;

  /**
   * @notice  Withdraws the specified amount of underlying ERC-20 asset, consuming the minimum amount of hTokens necessary
   * @param   _amount   Quantity of underlying ERC-20 tokens to withdraw
   */
  function withdraw(uint256 _amount) external;

  /**
   * @notice  Deposit multiple specified tokens of the underlying ERC-721 asset and mint ERC-1155 deposit coupon NFTs
   * @dev     Pull pattern, user must approve the contract before calling.
   * @param   _collateralIds  Token IDs of underlying ERC-721 to be transferred in
   */
  function depositCollateral(uint256[] calldata _collateralIds) external;

  /**
   * @notice  Sender borrows assets from the protocol against the specified collateral asset, without a referral code
   * @dev     Collateral must be deposited first.
   * @param   _borrowAmount   Amount of underlying ERC-20 to borrow
   * @param   _collateralId   Token ID of underlying ERC-721 to be borrowed against
   */
  function borrow(uint256 _borrowAmount, uint256 _collateralId) external;

  /**
   * @notice  Sender borrows assets from the protocol against the specified collateral asset, using a referral code
   * @param   _borrowAmount   Amount of underlying ERC-20 to borrow
   * @param   _collateralId   Token ID of underlying ERC-721 to be borrowed against
   * @param   _referral       Referral code as a plain string
   * @param   _signature      Signed message authorizing the referral, provided by Honey Labs
   */
  function borrowReferred(
    uint256 _borrowAmount,
    uint256 _collateralId,
    string calldata _referral,
    bytes calldata _signature
  ) external;

  /**
   * @notice  Sender repays a borrow taken against the specified collateral asset
   * @dev     Pull pattern, user must approve the contract before calling.
   * @param   _repayAmount    Amount of underlying ERC-20 to repay
   * @param   _collateralId   Token ID of underlying ERC-721 to be repaid against
   */
  function repayBorrow(
    uint256 _repayAmount,
    uint256 _collateralId,
    address _to
  ) external;

  /**
   * @notice  Burn deposit coupon NFTs and withdraw the associated underlying ERC-721 NFTs
   * @param   _collateralIds  Token IDs of underlying ERC-721 to be withdrawn
   */
  function withdrawCollateral(uint256[] calldata _collateralIds) external;

  /**
   * @notice  Trigger transfer of an NFT to the liquidation contract
   * @param   _collateralId   Token ID of underlying ERC-721 to be liquidated
   */
  function liquidateBorrow(uint256 _collateralId) external;

  /**
   * @notice  Pay off the entirety of a liquidated debt position and burn the coupon
   * @dev     May only be called by the liquidator
   * @param   _borrower       Owner of the debt position
   * @param   _collateralId   Token ID of underlying ERC-721 to be closed out
   */
  function closeoutLiquidation(address _borrower, uint256 _collateralId) external;

  /**
   * @notice  Accrues all interest due to the protocol
   * @dev     Call this before performing calculations using 'totalBorrows' or other contract-wide quantities
   */
  function accrueInterest() external;

  // ----- Utility functions -----

  /**
   * @notice  Sweep accidental ERC-20 transfers to this contract.
   * @dev     Tokens are sent to the DAO for later distribution
   * @param   _token  The address of the ERC-20 token to sweep
   */
  function sweepToken(IERC20 _token) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title   Interface of HToken Internal
 * @author  Honey Labs Inc.
 * @custom:coauthor m4rio
 * @custom:coauthor BowTiedPickle
 */
interface HTokenInternalI is IERC1155, IAccessControl {
  struct Coupon {
    uint32 id; //Coupon's id
    uint8 active; // Coupon activity status
    address owner; // Who is the current owner of this coupon
    uint256 collateralId; // tokenId of the collateral collection that is borrowed against
    uint256 borrowAmount; // Principal borrow balance, denominated in underlying ERC20 token.
    uint256 debtShares; // Debt shares, keeps the shares of total debt by the protocol
  }

  struct Collateral {
    uint256 collateralId; // TokenId of the collateral
    bool active; // Collateral activity status
  }

  // ----- Informational -----

  function decimals() external view returns (uint8);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  // ----- Addresses -----

  function collateralToken() external view returns (IERC721);

  function underlyingToken() external view returns (IERC20);

  // ----- Protocol Accounting -----

  function totalBorrows() external view returns (uint256);

  function totalReserves() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function totalFuseFees() external view returns (uint256);

  function totalAdminCommission() external view returns (uint256);

  function accrualBlockNumber() external view returns (uint256);

  function interestIndexStored() external view returns (uint256);

  function totalProtocolCommission() external view returns (uint256);

  function userToCoupons(address _user) external view returns (uint256);

  function collateralPerBorrowCouponId(uint256 _couponId) external view returns (Collateral memory);

  function borrowCoupons(uint256 _collateralId) external view returns (Coupon memory);

  // ----- Views -----

  /**
   * @notice  Get the outstanding debt of a collateral
   * @dev     Simulates accrual of interest
   * @param   _collateralId   Token ID of underlying ERC-721
   * @return  Outstanding debt in units of underlying ERC-20
   */
  function getDebtForCollateral(uint256 _collateralId) external view returns (uint256);

  /**
   * @notice  Returns the current per-block borrow interest rate for this hToken
   * @return  The borrow interest rate per block, scaled by 1e18
   */
  function borrowRatePerBlock() external view returns (uint256);

  /**
   * @notice  Get the outstanding debt of a coupon
   * @dev     Simulates accrual of interest
   * @param   _couponId   ID of the coupon
   * @return  Outstanding debt in units of underlying ERC-20
   */
  function getDebtForCoupon(uint256 _couponId) external view returns (uint256);

  /**
   * @notice  Gets balance of this contract in terms of the underlying excluding the fees
   * @dev     This excludes the value of the current message, if any
   * @return  The quantity of underlying ERC-20 tokens owned by this contract
   */
  function getCashPrior() external view returns (uint256);

  /**
   * @notice  Get a snapshot of the account's balances, and the cached exchange rate
   * @dev     This is used by controller to more efficiently perform liquidity checks.
   * @param   _account  Address of the account to snapshot
   * @return  (token balance, borrow balance, exchange rate mantissa)
   */
  function getAccountSnapshot(address _account) external view returns (uint256, uint256, uint256);

  /**
   * @notice  Get the outstanding debt of the protocol
   * @return  Protocol debt
   */
  function getDebt() external view returns (uint256);

  /**
   * @notice  Returns protocol fees
   * @return  Reserve factor mantissa
   * @return  Admin fee mantissa
   * @return  Hive fee mantissa
   * @return  Initial exchange rate mantissa
   * @return  Maximum borrow rate mantissa
   */
  function getProtocolFees() external view returns (uint256, uint256, uint256, uint256, uint256);

  /**
   * @notice  Returns different addresses of the protocol
   * @return  Liquidator address
   * @return  HTokenHelper address
   * @return  Controller address
   * @return  Admin Fee Receiver address
   * @return  Hive Fee Receiver address
   * @return  Interest Model address
   * @return  Referral Pool address
   * @return  DAO address
   */
  function getAddresses()
    external
    view
    returns (address, address, address, address, address, address, address, address);

  /**
   * @notice  Get the last minted coupon ID
   * @return  The last minted coupon ID
   */
  function idCounter() external view returns (uint256);

  /**
   * @notice  Get the coupon for a specific collateral NFT
   * @param   _collateralId   Token ID of underlying ERC-721
   * @return  Coupon
   */
  function getSpecificCouponByCollateralId(uint256 _collateralId) external view returns (Coupon memory);

  /**
   * @notice  Calculate the prevailing interest due per token of debt principal
   * @return  Mantissa formatted interest rate per token of debt
   */
  function interestIndex() external view returns (uint256);

  /**
   * @notice  Accrue interest then return the up-to-date exchange rate from the ERC-20 underlying to the HToken
   * @return  Calculated exchange rate scaled by 1e18
   */
  function exchangeRateCurrent() external returns (uint256);

  /**
   * @notice  Calculates the exchange rate from the ERC-20 underlying to the HToken
   * @dev     This function does not accrue interest before calculating the exchange rate
   * @return  Calculated exchange rate scaled by 1e18
   */
  function exchangeRateStored() external view returns (uint256);

  /**
   * @notice  Add to or take away from reserves
   * @dev     Accrues interest
   * @param   _amount  Quantity of underlying ERC-20 token to change the reserves by
   */
  function _modifyReserves(uint256 _amount, bool _add) external;

  /**
   * @notice  Set new admin fee mantissas
   * @dev     Accrues interest
   * @param   _newAdminCommissionMantissa        New admin fee mantissa
   */
  function _setAdminCommission(uint256 _newAdminCommissionMantissa) external;

  /**
   * @notice  Set new protocol commission and reserve factor mantissas
   * @dev     Accrues interest
   * @param   _newProtocolCommissionMantissa         New protocol commission mantissa
   * @param   _newReserveFactorMantissa   New reserve factor mantissa
   */
  function _setProtocolFees(uint256 _newProtocolCommissionMantissa, uint256 _newReserveFactorMantissa) external;

  /**
   * @notice  Sets a new admin fee receiver
   * @param   _newAddress   Address of the new admin fee receiver
   * @param   _target       Target ID of the address to be set
   */
  function _setAddressMarketAdmin(address _newAddress, uint256 _target) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "./HTokenI.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title   PermissionlessOracleI interface for the Permissionless oracle
 * @author  Honey Labs Inc.
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
interface PermissionlessOracleI {
  /**
   * @notice returns the price (in eth) for the floor of a collection
   * @param _collection address of the collection
   * @param _decimals adjust decimals of the returned price
   */
  function getFloorPrice(address _collection, uint256 _decimals) external view returns (uint128, uint128);

  /**
   * @notice returns the latest price for a given pair
   * @param _erc20 the erc20 we want to get the price for in USD
   * @param _decimals decimals to denote the result in
   */
  function getUnderlyingPriceInUSD(IERC20 _erc20, uint256 _decimals) external view returns (uint256);

  /**
   * @notice get price of eth
   * @param _decimals adjust decimals of the returned price
   */
  function getEthPrice(uint256 _decimals) external view returns (uint256);

  /**
   * @notice get price feeds for a token
   * @return returns the Chainlink Aggregator interface
   */
  function priceFeeds(IERC20 _token) external view returns (AggregatorV3Interface);

  /**
   * @notice returns the update threshold for a specific _collection
   */
  function updateThreshold(address _collection) external view returns (uint256);

  /**
   * @notice returns the number of floors for a specific _collection
   * @param _address address of the collection
   *
   */
  function getNoOfFloors(address _address) external view returns (uint256);

  /**
   * @notice returns the last updated timestamp for a specific _collection
   * @param _collection address of the collection
   *
   */
  function getLastUpdated(address _collection) external view returns (uint256);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "./HTokenI.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title   PriceOracle interface for Chainlink oracles
 * @author  Honey Labs Inc.
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
interface PriceOracleI {
  /**
   * @notice returns the underlying price for the floor of a collection
   * @param _collection address of the collection
   * @param _decimals adjust decimals of the returned price
   */
  function getFloorPrice(address _collection, uint256 _decimals) external view returns (uint128, uint128);

  /**
   * @notice returns the underlying price for an individual token id
   * @param _collection address of the collection
   * @param _tokenId token id within this collection
   * @param _decimals adjust decimals of the returned price
   */
  function getUnderlyingIndividualNFTPrice(
    address _collection,
    uint256 _tokenId,
    uint256 _decimals
  ) external view returns (uint256);

  /**
   * @notice returns the latest price for a given pair
   * @param _erc20 the erc20 we want to get the price for in USD
   * @param _decimals decimals to denote the result in
   */
  function getUnderlyingPriceInUSD(IERC20 _erc20, uint256 _decimals) external view returns (uint256);

  /**
   * @notice get price of eth
   * @param _decimals adjust decimals of the returned price
   */
  function getEthPrice(uint256 _decimals) external view returns (uint256);

  /**
   * @notice get price feeds for a token
   * @return returns the Chainlink Aggregator interface
   */
  function priceFeeds(IERC20 _token) external view returns (AggregatorV3Interface);

  /**
   * @notice returns the update threshold
   */
  function updateThreshold() external view returns (uint256);
}

//SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

error Unauthorized();
error AccrueInterestError(Error error);
error WrongParams();
error Unexpected(string error);
error InvalidCoupon();
error ControllerError(Error error);
error AdminError(Error error);
error MarketError(Error error);
error HTokenError(Error error);
error LiquidatorError(Error error);
error ControlPanelError(Error error);
error HTokenFactoryError(Error error);
error PausedAction();
error NotOwner();
error ExternalFailure(string error);
error Initialized();
error Uninitialized();
error OracleNotUpdated();
error TransferError();
error StalePrice();

/**
 * @title   Errors reported across Honey Labs Inc. contracts
 * @author  Honey Labs Inc.
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
enum Error {
  UNAUTHORIZED, //0
  INSUFFICIENT_LIQUIDITY,
  INVALID_COLLATERAL_FACTOR,
  MAX_MARKETS_IN,
  MARKET_NOT_LISTED,
  MARKET_ALREADY_LISTED, //5
  MARKET_CAP_BORROW_REACHED,
  MARKET_NOT_FRESH,
  PRICE_ERROR,
  BAD_INPUT,
  AMOUNT_ZERO, //10
  NO_DEBT,
  LIQUIDATION_NOT_ALLOWED,
  WITHDRAW_NOT_ALLOWED,
  INITIAL_EXCHANGE_MANTISSA,
  TRANSFER_ERROR, //15
  COUPON_LOOKUP,
  TOKEN_INSUFFICIENT_CASH,
  BORROW_RATE_TOO_BIG,
  NONZERO_BORROW_BALANCE,
  AMOUNT_TOO_BIG, //20
  AUCTION_NOT_ACTIVE,
  AUCTION_FINISHED,
  AUCTION_NOT_FINISHED,
  AUCTION_BID_TOO_LOW,
  AUCTION_NO_BIDS, //25
  CLAWBACK_WINDOW_EXPIRED,
  CLAWBACK_WINDOW_NOT_EXPIRED,
  REFUND_NOT_OWED,
  TOKEN_LOOKUP_ERROR,
  INSUFFICIENT_WINNING_BID, //30
  TOKEN_DEBT_NONEXISTENT,
  AUCTION_SETTLE_FORBIDDEN,
  NFT20_PAIR_NOT_FOUND,
  NFTX_PAIR_NOT_FOUND,
  TOKEN_NOT_PRESENT, //35
  CANCEL_TOO_SOON,
  AUCTION_USER_NOT_FOUND,
  NOT_FOUND,
  INVALID_MAX_LTV_FACTOR,
  BALANCE_INSUFFICIENT, //40
  ORACLE_NOT_SET,
  MARKET_INVALID,
  FACTORY_INVALID_COLLATERAL,
  FACTORY_INVALID_UNDERLYING,
  FACTORY_INVALID_ORACLE, //45
  FACTORY_DEPLOYMENT_FAILED,
  REPAY_NOT_ALLOWED,
  NONZERO_UNDERLYING_BALANCE,
  INVALID_ACTION,
  ORACLE_IS_PRESENT, //50
  FACTORY_INVALID_UNDERLYING_DECIMALS,
  FACTORY_INVALID_INTEREST_RATE_MODEL
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "solidity-json-writer/contracts/JsonWriter.sol";

import ".././interfaces/HTokenI.sol";
import ".././interfaces/ControllerI.sol";
import ".././interfaces/PermissionlessOracleI.sol";
import ".././interfaces/HTokenHelperI.sol";
import ".././utils/ErrorReporter.sol";

/**
 * @title   A hToken helper as the contract started to get big.
 * @notice  This deals with different frontend functions for easy computation on the frontend
 * @dev     Do not use these functions in any contract as they are only created for the frontend purposes
 * @author  Honey Labs Inc.
 * @custom:coauthor     m4rio
 * @custom:contributor  BowTiedPickle
 */
contract HTokenHelper is HTokenHelperI {
  using Strings for uint256;
  using JsonWriter for JsonWriter.Json;

  /// @notice Version of the contract 1_000_002 corresponds to 1.0.002
  uint256 public constant version = 1_000_002;

  uint256 public constant DENOMINATOR = 10_000;

  /**
   * @notice  Get underlying balance that is available for withdrawal or borrow
   * @return  The quantity of underlying not tied up
   */
  function getAvailableUnderlying(HTokenI _hToken) external view override returns (uint256) {
    return _hToken.getCashPrior() - _hToken.totalReserves();
  }

  /**
   * @notice  Get underlying balance for an account
   * @param   _account the account to check the balance for
   * @return  The quantity of underlying asset owned by this account
   */
  function getAvailableUnderlyingForUser(HTokenI _hToken, address _account) external view override returns (uint256) {
    return (_hToken.balanceOf(_account, 0) * _hToken.exchangeRateStored()) / 1e18;
  }

  /**
   * @notice  returns different assets per a hToken, helper method to reduce frontend calls
   * @param   _hToken the hToken to get the assets for
   * @return  total borrows
   * @return  total reserves
   * @return  total underlying balance
   * @return  active coupons
   */
  function getAssets(
    HTokenI _hToken
  ) external view override returns (uint256, uint256, uint256, HTokenI.Coupon[] memory) {
    uint256 totalBorrow = _hToken.totalBorrows();
    uint256 totalReserves = _hToken.totalReserves();
    uint256 underlyingBalance = _hToken.underlyingToken().balanceOf(address(_hToken));
    HTokenI.Coupon[] memory activeCoupons = getActiveCoupons(_hToken, false);
    return (totalBorrow, totalReserves, underlyingBalance, activeCoupons);
  }

  /**
   * @notice  Get all a user's coupons
   * @param   _hToken The HToken we want to get the user's coupons from
   * @param   _user   The user to search for
   * @return  Array of all coupons belonging to the user
   */
  function getUserCoupons(HTokenI _hToken, address _user) external view returns (HTokenI.Coupon[] memory) {
    unchecked {
      HTokenI.Coupon[] memory userCoupons = new HTokenI.Coupon[](_hToken.userToCoupons(_user));
      uint256 length = _hToken.idCounter();
      uint256 counter;
      for (uint256 i; i < length; ++i) {
        HTokenI.Collateral memory collateral = _hToken.collateralPerBorrowCouponId(i);
        if (!collateral.active) continue;
        HTokenI.Coupon memory coupon = _hToken.borrowCoupons(collateral.collateralId);

        if (coupon.owner == _user) {
          userCoupons[counter++] = coupon;
        }
      }

      return userCoupons;
    }
  }

  /**
   * @notice  Get the number of coupons deposited aka active
   * @param   _hToken The HToken we want to get the active User Coupons
   * @param   _hasDebt if the coupon has debt or not
   * @return  Array of all active coupons
   */
  function getActiveCoupons(HTokenI _hToken, bool _hasDebt) public view returns (HTokenI.Coupon[] memory) {
    unchecked {
      HTokenI.Coupon[] memory depositedCoupons;
      uint256 length = _hToken.idCounter();
      uint256 deposited;
      for (uint256 i; i < length; ++i) {
        HTokenI.Collateral memory collateral = _hToken.collateralPerBorrowCouponId(i);
        HTokenI.Coupon memory coupon = _hToken.getSpecificCouponByCollateralId(collateral.collateralId);
        if (collateral.active && ((_hasDebt && coupon.borrowAmount > 0) || !_hasDebt)) {
          ++deposited;
        }
      }
      depositedCoupons = new HTokenI.Coupon[](deposited);
      uint256 j;
      for (uint256 i; i < length; ++i) {
        HTokenI.Collateral memory collateral = _hToken.collateralPerBorrowCouponId(i);
        HTokenI.Coupon memory coupon = _hToken.getSpecificCouponByCollateralId(collateral.collateralId);

        if (collateral.active && ((_hasDebt && coupon.borrowAmount > 0) || !_hasDebt)) {
          depositedCoupons[j] = coupon;

          // This condition means "if j == deposited then break, else continue the loop with j + 1".
          // This is a gas optimization to avoid potentially unnecessary storage readings
          if (j++ == deposited) {
            break;
          }
        }
      }
      return depositedCoupons;
    }
  }

  /**
   * @notice  Get tokenIds of all a user's coupons
   * @param   _hToken The HToken we want to get the User Coupon Indices
   * @param   _user The user to search for
   * @return  Array of indices of all coupons belonging to the user
   */
  function getUserCouponIndices(HTokenI _hToken, address _user) external view returns (uint256[] memory) {
    unchecked {
      uint256[] memory userCoupons = new uint256[](_hToken.userToCoupons(_user));
      uint256 length = _hToken.idCounter();
      uint256 counter;
      for (uint256 i; i < length; ++i) {
        HTokenI.Collateral memory collateral = _hToken.collateralPerBorrowCouponId(i);
        if (!collateral.active) continue;
        HTokenI.Coupon memory coupon = _hToken.borrowCoupons(collateral.collateralId);

        if (coupon.owner == _user) {
          userCoupons[counter++] = i;
        }
      }

      return userCoupons;
    }
  }

  /**
   * @notice  returns prices of floor and underlying for a market to reduce frontend calls
   * @param   _hToken the hToken to get the prices for
   * @return  collection floor price in underlying value
   * @return  underlying price in usd
   */
  function getMarketOraclePrices(HTokenI _hToken) external view override returns (uint256, uint256) {
    uint8 decimals = _hToken.decimals();
    address controller;
    (, , controller, , , , , ) = _hToken.getAddresses();
    PermissionlessOracleI cachedOracle = ControllerI(controller).oracle(_hToken);

    (uint128 floorPriceInETH, ) = cachedOracle.getFloorPrice(address(_hToken.collateralToken()), decimals);

    uint256 underlyingPriceInUSD = internalUnderlyingPriceInUSD(_hToken);
    uint256 ethPrice = uint256(cachedOracle.getEthPrice(decimals));

    return (
      ((floorPriceInETH * ethPrice) * DENOMINATOR) / underlyingPriceInUSD / 10 ** decimals,
      (underlyingPriceInUSD * DENOMINATOR) / 10 ** decimals
    );
  }

  /**
   * @notice  Returns the borrow fee for a market, it can also return the discounted fee for referred borrow
   * @param   _hToken The market we want to get the borrow fee for
   * @param   _referred Flag that needs to be true in case we want to get the referred borrow fee
   * @return  fee - The borrow fee mantissa denominated in 1e18
   */
  function getMarketBorrowFee(HTokenI _hToken, bool _referred) external view override returns (uint256 fee) {
    address controller;
    (, , controller, , , , , ) = _hToken.getAddresses();
    if (!_referred) {
      (fee, ) = ControllerI(controller).getBorrowFeePerMarket(_hToken, "", "");
    } else fee = ControllerI(controller).getReferralBorrowFeePerMarket(_hToken);
  }

  /**
   * @notice  returns the collection price floor in usd
   * @param   _hToken the hToken to get the price for
   * @return  collection floor price in usd
   */
  function getFloorPriceInUSD(HTokenI _hToken) public view override returns (uint256) {
    uint256 floorPrice = internalFloorPriceInUSD(_hToken);
    return (floorPrice * DENOMINATOR) / 1e18;
  }

  /**
   * @notice  returns the collection price floor in underlying value
   * @param   _hToken the hToken to get the price for
   * @return  collection floor price in underlying
   */
  function getFloorPriceInUnderlying(HTokenI _hToken) public view returns (uint256) {
    uint256 floorPrice = internalFloorPriceInUSD(_hToken);
    uint256 underlyingPriceInUSD = internalUnderlyingPriceInUSD(_hToken);
    return (floorPrice * DENOMINATOR) / underlyingPriceInUSD;
  }

  /**
   * @notice  get the underlying price in usd for a hToken
   * @param   _hToken the hToken to get the price for
   * @return  underlying price in usd
   */
  function getUnderlyingPriceInUSD(HTokenI _hToken) public view override returns (uint256) {
    return (internalUnderlyingPriceInUSD(_hToken) * DENOMINATOR) / 10 ** _hToken.decimals();
  }

  /**
   * @notice  get the max borrowable amount for a market
   * @notice  it computes the floor price in usd and take the % of collateral factor that can be max borrowed
   *          then it divides it by the underlying price in usd.
   * @param   _hToken the hToken to get the price for
   * @param   _controller the controller used to get the collateral factor
   * @return  underlying price in underlying
   */
  function getMaxBorrowableAmountInUnderlying(
    HTokenI _hToken,
    ControllerI _controller
  ) external view returns (uint256) {
    uint256 floorPrice = internalFloorPriceInUSD(_hToken);
    uint256 underlyingPriceInUSD = internalUnderlyingPriceInUSD(_hToken);
    (, uint256 LTVfactor, ) = _controller.getMarketData(_hToken);
    // removing mantissa of 1e18
    return ((LTVfactor * floorPrice) * DENOMINATOR) / underlyingPriceInUSD / 1e18;
  }

  /**
   * @notice  get the max borrowable amount for a market
   * @notice  it computes the floor price in usd and take the % of collateral factor that can be max borrowed
   * @param   _hToken the hToken to get the price for
   * @param   _controller the controller used to get the collateral factor
   * @return  underlying price in usd
   */
  function getMaxBorrowableAmountInUSD(HTokenI _hToken, ControllerI _controller) external view returns (uint256) {
    uint256 floorPrice = internalFloorPriceInUSD(_hToken);
    (, , uint256 collateralFactor) = _controller.getMarketData(_hToken);
    return ((collateralFactor * floorPrice) * DENOMINATOR) / 1e18 / 10 ** _hToken.decimals();
  }

  /**
   * @notice  get's all the coupons that have deposited collateral
   * @param   _hToken market to get the collateral from
   * @param   _startTokenId start token id of the collateral collection, as we don't know how big the collection will be we have
   *          to do pagination
   * @param   _endTokenId end of token id we want to get.
   * @return  coupons list of coupons that are active
   */
  function getAllCollateralPerHToken(
    HTokenI _hToken,
    uint256 _startTokenId,
    uint256 _endTokenId
  ) external view returns (HTokenI.Coupon[] memory coupons) {
    unchecked {
      coupons = new HTokenI.Coupon[](_endTokenId - _startTokenId);
      for (uint256 i = _startTokenId; i <= _endTokenId; ++i) {
        HTokenI.Coupon memory coupon = _hToken.borrowCoupons(i);
        if (coupon.active == 2) coupons[i - _startTokenId] = coupon;
      }
    }
  }

  /**
   * @notice  Gets data about a market for frontend display
   * @param   _hToken the market we want the data for
   * @return  interest rate of the market
   * @return  total underlying supplied in a market
   * @return  total underlying available to be borrowed
   */
  function getFrontendMarketData(HTokenI _hToken) external view returns (uint256, uint256, uint256) {
    uint256 hTokenSupply = _hToken.totalSupply();
    uint256 exchangeRate = _hToken.exchangeRateStored();
    return (5_000, (hTokenSupply * exchangeRate) / 1e18, _hToken.getCashPrior() - _hToken.totalReserves());
  }

  /**
   * @notice  Gets data about a coupon for frontend display
   * @param   _hToken   The market we want the coupon for
   * @param   _couponId The coupon id we want to get the data for
   * @return  debt of this coupon
   * @return  allowance - how much liquidity can borrow till hitting LTV
   * @return  nft floor price
   */
  function getFrontendCouponData(HTokenI _hToken, uint256 _couponId) external view returns (uint256, uint256, uint256) {
    address controller;
    (, , controller, , , , , ) = _hToken.getAddresses();
    HTokenInternalI.Collateral memory collateral = _hToken.collateralPerBorrowCouponId(_couponId);
    HTokenInternalI.Coupon memory coupon = _hToken.borrowCoupons(collateral.collateralId);

    uint256 liquidityTillLTV;
    (, , liquidityTillLTV) = ControllerI(controller).getHypotheticalAccountLiquidity(
      _hToken,
      coupon.owner,
      collateral.collateralId,
      0,
      0
    );
    return (_hToken.getDebtForCoupon(_couponId), liquidityTillLTV, getFloorPriceInUnderlying(_hToken));
  }

  /**
   * @notice  Gets Liquidation data for a market, for frontend purposes
   * @param   _hToken the market we want the data for
   * @return  Liquidation threshold of a market (collateral factor)
   * @return  Total debt of the market
   * @return  TVL is an aproximate value of the NFTs deposited within a market, we only count the NFTs that have debt
   */
  function getFrontendLiquidationData(HTokenI _hToken) external view returns (uint256, uint256, uint256) {
    address controller;
    (, , controller, , , , , ) = _hToken.getAddresses();
    uint256 floorPrice = getFloorPriceInUnderlying(_hToken);
    (, , uint256 collateralFactor) = ControllerI(controller).getMarketData(_hToken);
    uint256 length = _hToken.idCounter();
    uint256 debtCoupons;
    for (uint256 i; i < length; ++i) {
      HTokenI.Collateral memory collateral = _hToken.collateralPerBorrowCouponId(i);
      HTokenI.Coupon memory coupon = _hToken.getSpecificCouponByCollateralId(collateral.collateralId);
      if (collateral.active && coupon.borrowAmount > 0) {
        ++debtCoupons;
      }
    }
    return (collateralFactor, _hToken.totalBorrows(), debtCoupons * floorPrice);
  }

  /**
   * @notice  uri function called from the HToken that returns the uri metadata for a coupon
   * @param   _id id of the hToken
   * @param   _hTokenAddress address of the hToken
   */
  function uri(uint256 _id, address _hTokenAddress) external view override returns (string memory) {
    HTokenI _hToken = HTokenI(_hTokenAddress);

    JsonWriter.Json memory writer;
    writer = writer.writeStartObject();
    if (_id > 0) {
      HTokenI.Collateral memory collateral = _hToken.collateralPerBorrowCouponId(_id);

      if (!collateral.active) revert WrongParams();

      HTokenI.Coupon memory coupon = _hToken.borrowCoupons(collateral.collateralId);

      writer = writer.writeStringProperty("name", string.concat("Honey Coupon ", _id.toString()));
      writer = writer.writeStringProperty("description", string.concat("Honey Coupon for Market ", _hToken.symbol()));
      writer = writer.writeStringProperty("external_url", "https://honey.finance");
      writer = writer.writeStringProperty("image", "https://honey.finance");
      writer = writer.writeStartArray("attributes");

      writer = writer.writeStartObject();
      writer = writer.writeStringProperty("trait_type", "BORROW_AMOUNT");
      writer = writer.writeStringProperty("value", coupon.borrowAmount.toString());
      writer = writer.writeEndObject();

      writer = writer.writeStartObject();
      writer = writer.writeStringProperty("trait_type", "DEBT_SHARES");
      writer = writer.writeStringProperty("value", coupon.debtShares.toString());
      writer = writer.writeEndObject();

      writer = writer.writeStartObject();
      writer = writer.writeStringProperty("trait_type", "COLLATERAL_ID");
      writer = writer.writeStringProperty("value", coupon.collateralId.toString());
      writer = writer.writeEndObject();

      writer = writer.writeStartObject();
      writer = writer.writeStringProperty("trait_type", "COLLATERAL_ADDRESS");
      writer = writer.writeStringProperty("value", toString(abi.encodePacked(address(_hToken.collateralToken()))));
      writer = writer.writeEndObject();
    } else {
      writer = writer.writeStringProperty(
        "name",
        string.concat(HTokenInternalI(_hToken).name(), " ", HTokenInternalI(_hToken).symbol())
      );
      writer = writer.writeStringProperty(
        "description",
        string.concat(
          "Honey Market with underlying ",
          IERC20Metadata(address(_hToken.underlyingToken())).name(),
          " and collateral ",
          IERC721Metadata(address(_hToken.collateralToken())).name()
        )
      );
      writer = writer.writeStringProperty("external_url", "https://honey.finance");
      writer = writer.writeStringProperty("image", "https://honey.finance");
      writer = writer.writeStartArray("attributes");

      writer = writer.writeStartObject();
      writer = writer.writeStringProperty("trait_type", "SUPPLY");
      writer = writer.writeStringProperty("value", _hToken.totalSupply().toString());
      writer = writer.writeEndObject();
    }

    writer = writer.writeEndArray();
    writer = writer.writeEndObject();
    return writer.value;
  }

  function toString(bytes memory data) internal pure returns (string memory) {
    bytes memory alphabet = "0123456789abcdef";

    uint256 len = data.length;

    bytes memory str = new bytes(2 + len * 2);
    str[0] = "0";
    str[1] = "x";

    for (uint256 i; i < len; ) {
      str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
      str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
      unchecked {
        ++i;
      }
    }
    return string(str);
  }

  function internalFloorPriceInUSD(HTokenI _hToken) internal view returns (uint256) {
    uint8 decimals = _hToken.decimals();
    address controller;
    (, , controller, , , , , ) = _hToken.getAddresses();
    PermissionlessOracleI cachedOracle = ControllerI(controller).oracle(_hToken);
    (uint128 floorPriceInETH, ) = cachedOracle.getFloorPrice(address(_hToken.collateralToken()), decimals);

    uint256 ethPrice = uint256(cachedOracle.getEthPrice(decimals));

    return (floorPriceInETH * ethPrice) / 10 ** decimals;
  }

  function internalUnderlyingPriceInUSD(HTokenI _hToken) internal view returns (uint256) {
    address controller;
    (, , controller, , , , , ) = _hToken.getAddresses();
    PermissionlessOracleI cachedOracle = ControllerI(controller).oracle(_hToken);

    return uint256(cachedOracle.getUnderlyingPriceInUSD(_hToken.underlyingToken(), _hToken.decimals()));
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JsonWriter {

    using JsonWriter for string;

    struct Json {
        int256 depthBitTracker;
        string value;
    }

    bytes1 constant BACKSLASH = bytes1(uint8(92));
    bytes1 constant BACKSPACE = bytes1(uint8(8));
    bytes1 constant CARRIAGE_RETURN = bytes1(uint8(13));
    bytes1 constant DOUBLE_QUOTE = bytes1(uint8(34));
    bytes1 constant FORM_FEED = bytes1(uint8(12));
    bytes1 constant FRONTSLASH = bytes1(uint8(47));
    bytes1 constant HORIZONTAL_TAB = bytes1(uint8(9));
    bytes1 constant NEWLINE = bytes1(uint8(10));

    string constant TRUE = "true";
    string constant FALSE = "false";
    bytes1 constant OPEN_BRACE = "{";
    bytes1 constant CLOSED_BRACE = "}";
    bytes1 constant OPEN_BRACKET = "[";
    bytes1 constant CLOSED_BRACKET = "]";
    bytes1 constant LIST_SEPARATOR = ",";

    int256 constant MAX_INT256 = type(int256).max;

    /**
     * @dev Writes the beginning of a JSON array.
     */
    function writeStartArray(Json memory json) 
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, OPEN_BRACKET);
    }

    /**
     * @dev Writes the beginning of a JSON array with a property name as the key.
     */
    function writeStartArray(Json memory json, string memory propertyName)
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, propertyName, OPEN_BRACKET);
    }

    /**
     * @dev Writes the beginning of a JSON object.
     */
    function writeStartObject(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, OPEN_BRACE);
    }

    /**
     * @dev Writes the beginning of a JSON object with a property name as the key.
     */
    function writeStartObject(Json memory json, string memory propertyName)
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, propertyName, OPEN_BRACE);
    }

    /**
     * @dev Writes the end of a JSON array.
     */
    function writeEndArray(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        return writeEnd(json, CLOSED_BRACKET);
    }

    /**
     * @dev Writes the end of a JSON object.
     */
    function writeEndObject(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        return writeEnd(json, CLOSED_BRACE);
    }

    /**
     * @dev Writes the property name and address value (as a JSON string) as part of a name/value pair of a JSON object.
     */
    function writeAddressProperty(
        Json memory json,
        string memory propertyName,
        address value
    ) internal pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": "', addressToString(value), '"'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": "', addressToString(value), '"'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the address value (as a JSON string) as an element of a JSON array.
     */
    function writeAddressValue(Json memory json, address value)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', addressToString(value), '"'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', addressToString(value), '"'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and boolean value (as a JSON literal "true" or "false") as part of a name/value pair of a JSON object.
     */
    function writeBooleanProperty(
        Json memory json,
        string memory propertyName,
        bool value
    ) internal pure returns (Json memory) {
        string memory strValue;
        if (value) {
            strValue = TRUE;
        } else {
            strValue = FALSE;
        }

        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', strValue));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', strValue));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the boolean value (as a JSON literal "true" or "false") as an element of a JSON array.
     */
    function writeBooleanValue(Json memory json, bool value)
        internal
        pure
        returns (Json memory)
    {
        string memory strValue;
        if (value) {
            strValue = TRUE;
        } else {
            strValue = FALSE;
        }

        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, strValue));
        } else {
            json.value = string(abi.encodePacked(json.value, strValue));
        }
        
        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and int value (as a JSON number) as part of a name/value pair of a JSON object.
     */
    function writeIntProperty(
        Json memory json,
        string memory propertyName,
        int256 value
    ) internal pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', intToString(value)));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', intToString(value)));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the int value (as a JSON number) as an element of a JSON array.
     */
    function writeIntValue(Json memory json, int256 value)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, intToString(value)));
        } else {
            json.value = string(abi.encodePacked(json.value, intToString(value)));
        }
        
        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and value of null as part of a name/value pair of a JSON object.
     */
    function writeNullProperty(Json memory json, string memory propertyName)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": null'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": null'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the value of null as an element of a JSON array.
     */
    function writeNullValue(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, "null"));
        } else {
            json.value = string(abi.encodePacked(json.value, "null"));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the string text value (as a JSON string) as an element of a JSON array.
     */
    function writeStringProperty(
        Json memory json,
        string memory propertyName,
        string memory value
    ) internal pure returns (Json memory) {
        string memory jsonEscapedString = escapeJsonString(value);
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": "', jsonEscapedString, '"'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": "', jsonEscapedString, '"'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and string text value (as a JSON string) as part of a name/value pair of a JSON object.
     */
    function writeStringValue(Json memory json, string memory value)
        internal
        pure
        returns (Json memory)
    {
        string memory jsonEscapedString = escapeJsonString(value);
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', jsonEscapedString, '"'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', jsonEscapedString, '"'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and uint value (as a JSON number) as part of a name/value pair of a JSON object.
     */
    function writeUintProperty(
        Json memory json,
        string memory propertyName,
        uint256 value
    ) internal pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', uintToString(value)));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', uintToString(value)));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the uint value (as a JSON number) as an element of a JSON array.
     */
    function writeUintValue(Json memory json, uint256 value)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, uintToString(value)));
        } else {
            json.value = string(abi.encodePacked(json.value, uintToString(value)));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the beginning of a JSON array or object based on the token parameter.
     */
    function writeStart(Json memory json, bytes1 token)
        private
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, token));
        } else {
            json.value = string(abi.encodePacked(json.value, token));
        }

        json.depthBitTracker &= MAX_INT256;
        json.depthBitTracker++;

        return json;
    }

    /**
     * @dev Writes the beginning of a JSON array or object based on the token parameter with a property name as the key.
     */
    function writeStart(
        Json memory json,
        string memory propertyName,
        bytes1 token
    ) private pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', token));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', token));
        }

        json.depthBitTracker &= MAX_INT256;
        json.depthBitTracker++;

        return json;
    }

    /**
     * @dev Writes the end of a JSON array or object based on the token parameter.
     */
    function writeEnd(Json memory json, bytes1 token)
        private
        pure
        returns (Json memory)
    {
        json.value = string(abi.encodePacked(json.value, token));
        json.depthBitTracker = setListSeparatorFlag(json);
        
        if (getCurrentDepth(json) != 0) {
            json.depthBitTracker--;
        }

        return json;
    }

    /**
     * @dev Escapes any characters that required by JSON to be escaped.
     */
    function escapeJsonString(string memory value)
        private
        pure
        returns (string memory str)
    {
        bytes memory b = bytes(value);
        bool foundEscapeChars;

        for (uint256 i; i < b.length; i++) {
            if (b[i] == BACKSLASH) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == DOUBLE_QUOTE) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == FRONTSLASH) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == HORIZONTAL_TAB) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == FORM_FEED) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == NEWLINE) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == CARRIAGE_RETURN) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == BACKSPACE) {
                foundEscapeChars = true;
                break;
            }
        }

        if (!foundEscapeChars) {
            return value;
        }

        for (uint256 i; i < b.length; i++) {
            if (b[i] == BACKSLASH) {
                str = string(abi.encodePacked(str, "\\\\"));
            } else if (b[i] == DOUBLE_QUOTE) {
                str = string(abi.encodePacked(str, '\\"'));
            } else if (b[i] == FRONTSLASH) {
                str = string(abi.encodePacked(str, "\\/"));
            } else if (b[i] == HORIZONTAL_TAB) {
                str = string(abi.encodePacked(str, "\\t"));
            } else if (b[i] == FORM_FEED) {
                str = string(abi.encodePacked(str, "\\f"));
            } else if (b[i] == NEWLINE) {
                str = string(abi.encodePacked(str, "\\n"));
            } else if (b[i] == CARRIAGE_RETURN) {
                str = string(abi.encodePacked(str, "\\r"));
            } else if (b[i] == BACKSPACE) {
                str = string(abi.encodePacked(str, "\\b"));
            } else {
                str = string(abi.encodePacked(str, b[i]));
            }
        }

        return str;
    }

    /**
     * @dev Tracks the recursive depth of the nested objects / arrays within the JSON text
     * written so far. This provides the depth of the current token.
     */
    function getCurrentDepth(Json memory json) private pure returns (int256) {
        return json.depthBitTracker & MAX_INT256;
    }

    /**
     * @dev The highest order bit of json.depthBitTracker is used to discern whether we are writing the first item in a list or not.
     * if (json.depthBitTracker >> 255) == 1, add a list separator before writing the item
     * else, no list separator is needed since we are writing the first item.
     */
    function setListSeparatorFlag(Json memory json)
        private
        pure
        returns (int256)
    {
        return json.depthBitTracker | (int256(1) << 255);
    }

        /**
     * @dev Converts an address to a string.
     */
    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes16 alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }

        return string(str);
    }

    /**
     * @dev Converts an int to a string.
     */
    function intToString(int256 i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }

        if (i == type(int256).min) {
            // hard-coded since int256 min value can't be converted to unsigned
            return "-57896044618658097711785492504343953926634992332820282019728792003956564819968"; 
        }

        bool negative = i < 0;
        uint256 len;
        uint256 j;
        if(!negative) {
            j = uint256(i);
        } else {
            j = uint256(-i);
            ++len; // make room for '-' sign
        }
        
        uint256 l = j;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (l != 0) {
            bstr[--k] = bytes1((48 + uint8(l - (l / 10) * 10)));
            l /= 10;
        }

        if (negative) {
            bstr[0] = "-"; // prepend '-'
        }

        return string(bstr);
    }

    /**
     * @dev Converts a uint to a string.
     */
    function uintToString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            bstr[--k] = bytes1((48 + uint8(_i - (_i / 10) * 10)));
            _i /= 10;
        }

        return string(bstr);
    }
}