// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * - The `operator` cannot be the caller.
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {
    PermitC, PermitC__SignatureTransferExceededPermitExpired, PackedApproval, ZERO_BYTES32
} from "permitc/PermitC.sol";

// Tapioca
import {PearlmitHash} from "./PearlmitHash.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/**
 * @title Pearlmit
 * @author Limit Break Inc., Tapioca
 * @notice Pearlmit inherit PermitC and implements a new `permitBatchTransferFrom()` function
 * to allow batch transfer of multiple token types.
 */
contract Pearlmit is PermitC {
    error Pearlmit__BadHashedData();

    constructor(string memory name, string memory version, address owner, uint256 nativeValueToCheckPauseState)
        PermitC(name, version, owner, nativeValueToCheckPauseState)
    {}

    /**
     * @notice Permit batch approve of multiple token types.
     * @dev Check the validity of a permit batch transfer.
     *      - Reverts if the permit is invalid.
     *      - Reverts if the permit is expired.
     * @dev Invalidate the nonce after checking it.
     * @dev If past allowances for the token still exist, bypass the permit check.
     * @dev When performing the hash check, it uses the msg.sender as the expected operator,
     * countering the possibility of grief.
     * @dev If past allowances for the token still exist, bypass the permit check.
     *
     * @param batch PermitBatchTransferFrom struct containing all necessary data for batch transfer.
     * batch.approvals - array of SignatureApproval structs.
     *      * batch.approvals.tokenType - type of token (20 = ERC20, 721 = ERC721, 1155 = ERC1155).
     *      * batch.approvals.token - address of the token.
     *      * batch.approvals.id - id of the token (0 if ERC20).
     *      * batch.approvals.amount - amount of the token (0 if ERC721).
     *      * batch.approvals.operator - address of the operator to transfer the tokens to.
     *      * batch.approvals.approvalExpiration - expiration of the approval.
     * batch.owner - address of the owner of the tokens.
     * batch.nonce - nonce of the owner.
     * batch.sigDeadline - deadline for the signature.
     * batch.signedPermit - signature of the permit.
     *
     * @param hashedData Hashed data that comes with the permit execution. Will be `msg.sender` -> `srcMsgSender` from an LZ perspective.
     * This is useful in an async scenario
     * where the permit is signed to execute some certain actions. The payload can be hashed and used
     * in `hashedData` to trust that the permit is being used for the intended purpose, from the intended executor.
     * The source needs to be trusted to pass a valid `hashedData`, in the case of Pearlmit usage, this'll be
     * a TapiocaOmnichainReceiver contract.
     *
     */
    function permitBatchApprove(IPearlmit.PermitBatchTransferFrom calldata batch, bytes32 hashedData) external {
        _checkPermitBatchApproval(batch, hashedData);

        uint256 numPermits = batch.approvals.length;
        for (uint256 i = 0; i < numPermits; ++i) {
            IPearlmit.SignatureApproval calldata approval = batch.approvals[i];
            _storeApproval(
                approval.tokenType,
                approval.token,
                approval.id,
                approval.amount,
                batch.sigDeadline,
                batch.owner,
                approval.operator
            );
        }
    }

    /**
     * @notice Clear the allowance of an owner if it is called by the approved operator
     */
    function clearAllowance(address owner, uint256 tokenType, address token, uint256 id) external {
        (uint256 allowedAmount,) = _allowance(_transferApprovals, owner, msg.sender, tokenType, token, id, ZERO_BYTES32);
        if (allowedAmount > 0) {
            _clearAllowance(owner, tokenType, token, msg.sender, id);
        }
    }

    /**
     * @dev Clear the allowance of an owner to a given operator by setting the amount to 0 and expiring it.
     */
    function _clearAllowance(address owner, uint256 tokenType, address token, address operator, uint256 id) internal {
        _storeApproval(tokenType, token, id, 0, 0, owner, operator);
    }

    /**
     * @dev Generate the digest and check its validity against the permit.
     * @dev If past allowances for the token still exist, bypass the permit check.
     */
    function _checkPermitBatchApproval(IPearlmit.PermitBatchTransferFrom calldata batch, bytes32 hashedData) internal {
        bytes32 digest = _hashTypedDataV4(PearlmitHash.hashBatchTransferFrom(batch, _masterNonces[batch.owner]));

        if (batch.hashedData != hashedData) {
            revert Pearlmit__BadHashedData();
        }
        _checkBatchPermitData(batch.nonce, batch.sigDeadline, batch.owner, digest, batch.signedPermit);
    }

    /**
     * @dev Check the validity of a permit batch transfer.
     *      - Reverts if the permit is invalid.
     *      - Reverts if the permit is expired.
     * @dev Invalidate the nonce after checking it.
     */
    function _checkBatchPermitData(
        uint256 nonce,
        uint256 expiration,
        address owner,
        bytes32 digest,
        bytes calldata signedPermit
    ) internal {
        if (block.timestamp > expiration) {
            revert PermitC__SignatureTransferExceededPermitExpired();
        }

        _verifyPermitSignature(digest, signedPermit, owner);
        _checkAndInvalidateNonce(owner, nonce);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

library PearlmitHash {
    // Batch transfer
    bytes32 public constant _PERMIT_SIGNATURE_APPROVAL_TYPEHASH =
        keccak256("SignatureApproval(uint256 tokenType,address token,uint256 id,uint200 amount,address operator)");

    // Only `signedPermit` is not present, otherwise should be 1:1 with `IPearlmit.PermitBatchTransferFrom`
    bytes32 public constant _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitBatchTransferFrom(SignatureApproval[] approvals,address owner,uint256 nonce,uint48 sigDeadline,uint256 masterNonce,address executor,bytes32 hashedData)SignatureApproval(uint256 tokenType,address token,uint256 id,uint200 amount,address operator)"
    );

    /**
     * @dev Hashes the permit batch transfer from.
     */
    function hashBatchTransferFrom(IPearlmit.PermitBatchTransferFrom calldata batch, uint256 masterNonce)
        internal
        view
        returns (bytes32)
    {
        IPearlmit.SignatureApproval[] memory approvals = batch.approvals;
        uint256 numPermits = approvals.length;
        bytes32[] memory permitHashes = new bytes32[](numPermits);
        for (uint256 i = 0; i < numPermits; ++i) {
            permitHashes[i] = _hashPermitSignatureApproval(approvals[i]);
        }

        return keccak256(
            abi.encode(
                _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                keccak256(abi.encodePacked(permitHashes)),
                batch.owner,
                batch.nonce,
                batch.sigDeadline,
                masterNonce,
                msg.sender, // executor
                batch.hashedData
            )
        );
    }

    /**
     * @dev Hashes the permit signature approval.
     */
    function _hashPermitSignatureApproval(IPearlmit.SignatureApproval memory approval)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                _PERMIT_SIGNATURE_APPROVAL_TYPEHASH,
                approval.tokenType,
                approval.token,
                approval.id,
                approval.amount,
                approval.operator
            )
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/*
                                                     @@@@@@@@@@@@@@             
                                                    @@@@@@@@@@@@@@@@@@(         
                                                   @@@@@@@@@@@@@@@@@@@@@        
                                                  @@@@@@@@@@@@@@@@@@@@@@@@      
                                                           #@@@@@@@@@@@@@@      
                                                               @@@@@@@@@@@@     
                            @@@@@@@@@@@@@@*                    @@@@@@@@@@@@     
                           @@@@@@@@@@@@@@@     @               @@@@@@@@@@@@     
                          @@@@@@@@@@@@@@@     @                @@@@@@@@@@@      
                         @@@@@@@@@@@@@@@     @@               @@@@@@@@@@@@      
                        @@@@@@@@@@@@@@@     #@@             @@@@@@@@@@@@/       
                        @@@@@@@@@@@@@@.     @@@@@@@@@@@@@@@@@@@@@@@@@@@         
                       @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@            
                      @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@             
                     @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@           
                    @@@@@@@@@@@@@@@     @@@@@&%%%%%%%%&&@@@@@@@@@@@@@@          
                    @@@@@@@@@@@@@@      @@@@@               @@@@@@@@@@@         
                   @@@@@@@@@@@@@@@     @@@@@                 @@@@@@@@@@@        
                  @@@@@@@@@@@@@@@     @@@@@@                 @@@@@@@@@@@        
                 @@@@@@@@@@@@@@@     @@@@@@@                 @@@@@@@@@@@        
                @@@@@@@@@@@@@@@     @@@@@@@                 @@@@@@@@@@@&        
                @@@@@@@@@@@@@@     *@@@@@@@               (@@@@@@@@@@@@         
               @@@@@@@@@@@@@@@     @@@@@@@@             @@@@@@@@@@@@@@          
              @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           
             @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            
            @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              
           .@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 
           @@@@@@@@@@@@@@%     @@@@@@@@@@@@@@@@@@@@@@@@(                        
          @@@@@@@@@@@@@@@                                                       
         @@@@@@@@@@@@@@@                                                        
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                         
       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                          
       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&                                          
      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                           
 
* @title CollateralizedPausableFlags
* @custom:version 1.0.0
* @author Limit Break, Inc.
* @description Collateralized Pausable Flags is an extension for contracts
*              that require features to be pausable in the event of potential
*              or actual threats without incurring a storage read overhead cost
*              during normal operations by using contract starting balance as
*              a signal for checking the paused state.
*
*              Using contract balance to enable checking paused state creates an
*              economic penalty for developers that deploy code that can be 
*              exploited as well as an economic incentive (recovery of collateral)
*              for them to mitigate the threat.
*
*              Developers implementing Collateralized Pausable Flags should consider
*              their risk mitigation strategy and ensure funds are readily available
*              for pausing if ever necessary by setting an appropriate threshold 
*              value and considering use of an escrow contract that can initiate the
*              pause with funds.
*
*              There is no restriction on the depositor as this can be easily 
*              circumvented through a `SELFDESTRUCT` opcode.
*
*              Developers must be aware of potential outflows from the contract that
*              could reduce collateral below the pausable check threshold and protect
*              against those methods when pausing is required.
*/
abstract contract CollateralizedPausableFlags {
    /// @dev Emitted when the pausable flags are updated
    event PausableFlagsUpdated(uint256 previousFlags, uint256 newFlags);

    /// @dev Thrown when an execution path requires a flag to not be paused but it is paused
    error CollateralizedPausableFlags__Paused();
    /// @dev Thrown when an executin path requires a flag to be paused but it is not paused
    error CollateralizedPausableFlags__NotPaused();
    /// @dev Thrown when a call to withdraw funds fails
    error CollateralizedPausableFlags__WithdrawFailed();

    /// @dev Immutable variable that defines the native funds threshold before flags are checked
    uint256 private immutable nativeValueToCheckPauseState;
    /// @dev Flags for current pausable state, each bit is considered a separate flag
    uint256 private pausableFlags;

    /// @dev Immutable pointer for the _requireNotPaused function to use based on value threshold
    function(uint256) internal view immutable _requireNotPaused;
    /// @dev Immutable pointer for the _requirePaused function to use based on value threshold
    function(uint256) internal view immutable _requirePaused;
    /// @dev Immutable pointer for the _getPausableFlags function to use based on value threshold
    function() internal view returns (uint256) immutable _getPausableFlags;

    constructor(uint256 _nativeValueToCheckPauseState) {
        // Optimizes value check at runtime by reducing the stored immutable
        // value by 1 so that greater than can be used instead of greater
        // than or equal while allowing the deployment parameter to reflect
        // the value at which the deployer wants to trigger pause checking.
        // Example:
        //     Constructed with a value of 1000
        //     Immutable value stored is 999
        //     State checking enabled at 1000 units deposited because
        //     1000 > 999 evaluates true
        if (_nativeValueToCheckPauseState > 0) {
            unchecked {
                _nativeValueToCheckPauseState -= 1;
            }
            _requireNotPaused = _requireNotPausedWithCollateralCheck;
            _requirePaused = _requirePausedWithCollateralCheck;
            _getPausableFlags = _getPausableFlagsWithCollateralCheck;
        } else {
            _requireNotPaused = _requireNotPausedWithoutCollateralCheck;
            _requirePaused = _requirePausedWithoutCollateralCheck;
            _getPausableFlags = _getPausableFlagsWithoutCollateralCheck;
        }

        nativeValueToCheckPauseState = _nativeValueToCheckPauseState;
    }

    /**
     * @dev  Modifier to make a function callable only when the specified flags are not paused
     * @dev  Throws when any of the flags specified are paused
     *
     * @param _flags  The flags to check for pause state
     */
    modifier whenNotPaused(uint256 _flags) {
        _requireNotPaused(_flags);
        _;
    }

    /**
     * @dev  Modifier to make a function callable only when the specified flags are paused
     * @dev  Throws when any of the flags specified are not paused
     *
     * @param _flags  The flags to check for pause state
     */
    modifier whenPaused(uint256 _flags) {
        _requirePaused(_flags);
        _;
    }

    /**
     * @dev  Modifier to make a function callable only by a permissioned account
     * @dev  Throws when the caller does not have permission
     */
    modifier onlyPausePermissionedCaller() {
        _requireCallerHasPausePermissions();
        _;
    }

    /**
     * @notice  Updates the pausable flags settings
     *
     * @dev     Throws when the caller does not have permission
     * @dev     **NOTE:** Pausable flag settings will only take effect if contract balance exceeds
     * @dev     `nativeValueToPause`
     *
     * @dev     <h4>Postconditions:</h4>
     * @dev     1. address(this).balance increases by msg.value
     * @dev     2. `pausableFlags` is set to the new value
     * @dev     3. Emits a PausableFlagsUpdated event
     *
     * @param _pausableFlags  The new pausable flags to set
     */
    function pause(uint256 _pausableFlags) external payable onlyPausePermissionedCaller {
        _setPausableFlags(_pausableFlags);
    }

    /**
     * @notice  Allows any account to supply funds for enabling the pausable checks
     *
     * @dev     **NOTE:** The threshold check for pausable collateral does not pause
     * @dev     any functions unless the associated pausable flag is set.
     */
    function pausableDepositCollateral() external payable {
        // thank you for your contribution to safety
    }

    /**
     * @notice  Resets all pausable flags to unpaused and withdraws funds
     *
     * @dev     Throws when the caller does not have permission
     *
     * @dev     <h4>Postconditions:</h4>
     * @dev     1. `pausableFlags` is set to zero
     * @dev     2. Emits a PausableFlagsUpdated event
     * @dev     3. Transfers `withdrawAmount` of native funds to `withdrawTo` if non-zero
     *
     * @param withdrawTo      The address to withdraw the collateral to
     * @param withdrawAmount  The amount of collateral to withdraw
     */
    function unpause(address withdrawTo, uint256 withdrawAmount) external onlyPausePermissionedCaller {
        _setPausableFlags(0);

        if (withdrawAmount > 0) {
            (bool success,) = withdrawTo.call{value: withdrawAmount}("");
            if (!success) revert CollateralizedPausableFlags__WithdrawFailed();
        }
    }

    /**
     * @notice  Returns collateralized pausable configuration information
     *
     * @return _nativeValueToCheckPauseState  The collateral required to enable pause state checking
     * @return _pausableFlags                 The current pausable flags set, only checked when collateral met
     */
    function pausableConfigurationSettings()
        external
        view
        returns (uint256 _nativeValueToCheckPauseState, uint256 _pausableFlags)
    {
        unchecked {
            _nativeValueToCheckPauseState = nativeValueToCheckPauseState + 1;
            _pausableFlags = pausableFlags;
        }
    }

    /**
     * @notice  Updates the `pausableFlags` variable and emits a PausableFlagsUpdated event
     *
     * @param _pausableFlags  The new pausable flags to set
     */
    function _setPausableFlags(uint256 _pausableFlags) internal {
        uint256 previousFlags = pausableFlags;

        pausableFlags = _pausableFlags;

        emit PausableFlagsUpdated(previousFlags, _pausableFlags);
    }

    /**
     * @notice  Checks the current pause state of the supplied flags and reverts if any are paused
     *
     * @dev     *Should* be called prior to any transfers of native funds out of the contract for efficiency
     * @dev     Throws when the native funds balance is greater than the value to enable pausing AND
     * @dev     one or more of the supplied `_flags` is paused.
     *
     * @param _flags  The flags to check for pause state
     */
    function _requireNotPausedWithCollateralCheck(uint256 _flags) private view {
        if (_nativeBalanceSubMsgValue() > nativeValueToCheckPauseState) {
            if (pausableFlags & _flags > 0) {
                revert CollateralizedPausableFlags__Paused();
            }
        }
    }

    /**
     * @notice  Checks the current pause state of the supplied flags and reverts if any are paused
     *
     * @dev     Throws when one or more of the supplied `_flags` is paused.
     *
     * @param _flags  The flags to check for pause state
     */
    function _requireNotPausedWithoutCollateralCheck(uint256 _flags) private view {
        if (pausableFlags & _flags > 0) {
            revert CollateralizedPausableFlags__Paused();
        }
    }

    /**
     * @notice  Checks the current pause state of the supplied flags and reverts if none are paused
     *
     * @dev     *Should* be called prior to any transfers of native funds out of the contract for efficiency
     * @dev     Throws when the native funds balance is not greater than the value to enable pausing OR
     * @dev     none of the supplied `_flags` are paused.
     *
     * @param _flags  The flags to check for pause state
     */
    function _requirePausedWithCollateralCheck(uint256 _flags) private view {
        if (_nativeBalanceSubMsgValue() <= nativeValueToCheckPauseState) {
            revert CollateralizedPausableFlags__NotPaused();
        } else if (pausableFlags & _flags == 0) {
            revert CollateralizedPausableFlags__NotPaused();
        }
    }

    /**
     * @notice  Checks the current pause state of the supplied flags and reverts if none are paused
     *
     * @dev     Throws when none of the supplied `_flags` are paused.
     *
     * @param _flags  The flags to check for pause state
     */
    function _requirePausedWithoutCollateralCheck(uint256 _flags) private view {
        if (pausableFlags & _flags == 0) {
            revert CollateralizedPausableFlags__NotPaused();
        }
    }

    /**
     * @notice  Returns the current state of the pausable flags
     *
     * @dev     Will return zero if the native funds balance is not greater than the value to enable pausing
     *
     * @return _pausableFlags  The current state of the pausable flags
     */
    function _getPausableFlagsWithCollateralCheck() private view returns (uint256 _pausableFlags) {
        if (_nativeBalanceSubMsgValue() > nativeValueToCheckPauseState) {
            _pausableFlags = pausableFlags;
        }
    }

    /**
     * @notice  Returns the current state of the pausable flags
     *
     * @return _pausableFlags  The current state of the pausable flags
     */
    function _getPausableFlagsWithoutCollateralCheck() private view returns (uint256 _pausableFlags) {
        _pausableFlags = pausableFlags;
    }

    /**
     * @notice  Returns the current contract balance minus the value sent with the call
     *
     * @dev     This is expected to be the contract balance at the beginning of a function call
     * @dev     to efficiently determine whether a contract has the necessary collateral to enable
     * @dev     the pausable flags checking for contracts that hold native token funds.
     * @dev     This should **NOT** be used in any way to determine current balance for contract logic
     * @dev     other than its intended purpose for pause state checking activation.
     */
    function _nativeBalanceSubMsgValue() private view returns (uint256 _value) {
        unchecked {
            _value = address(this).balance - msg.value;
        }
    }

    /**
     * @dev  To be implemented by an inheriting contract for authorization to `pause` and `unpause`
     * @dev  functions as well as any functions in the inheriting contract that utilize the
     * @dev  `onlyPausePermissionedCaller` modifier.
     *
     * @dev  Implementing contract function **MUST** throw when the caller is not permissioned
     */
    function _requireCallerHasPausePermissions() internal view virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev Constant bytes32 value of 0x000...000
bytes32 constant ZERO_BYTES32 = bytes32(0);

/// @dev Constant value of 0
uint256 constant ZERO = 0;
/// @dev Constant value of 1
uint256 constant ONE = 1;

/// @dev Constant value representing an open order in storage
uint8 constant ORDER_STATE_OPEN = 0;
/// @dev Constant value representing a filled order in storage
uint8 constant ORDER_STATE_FILLED = 1;
/// @dev Constant value representing a cancelled order in storage
uint8 constant ORDER_STATE_CANCELLED = 2;

/// @dev Constant value representing the ERC721 token type for signatures and transfer hooks
uint256 constant TOKEN_TYPE_ERC721 = 721;
/// @dev Constant value representing the ERC1155 token type for signatures and transfer hooks
uint256 constant TOKEN_TYPE_ERC1155 = 1155;
/// @dev Constant value representing the ERC20 token type for signatures and transfer hooks
uint256 constant TOKEN_TYPE_ERC20 = 20;

/// @dev Constant value to mask the upper bits of a signature that uses a packed `vs` value to extract `s`
bytes32 constant UPPER_BIT_MASK = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

/// @dev EIP-712 typehash used for validating signature based stored approvals
bytes32 constant UPDATE_APPROVAL_TYPEHASH =
    keccak256("UpdateApprovalBySignature(uint256 tokenType,address token,uint256 id,uint256 amount,uint256 nonce,address operator,uint256 approvalExpiration,uint256 sigDeadline,uint256 masterNonce)");

/// @dev EIP-712 typehash used for validating a single use permit without additional data
bytes32 constant SINGLE_USE_PERMIT_TYPEHASH =
    keccak256("PermitTransferFrom(uint256 tokenType,address token,uint256 id,uint256 amount,uint256 nonce,address operator,uint256 expiration,uint256 masterNonce)");

/// @dev EIP-712 typehash used for validating a single use permit with additional data
string constant SINGLE_USE_PERMIT_TRANSFER_ADVANCED_TYPEHASH_STUB =
    "PermitTransferFromWithAdditionalData(uint256 tokenType,address token,uint256 id,uint256 amount,uint256 nonce,address operator,uint256 expiration,uint256 masterNonce,";

/// @dev EIP-712 typehash used for validating an order permit that updates storage as it fills
string constant PERMIT_ORDER_ADVANCED_TYPEHASH_STUB =
    "PermitOrderWithAdditionalData(uint256 tokenType,address token,uint256 id,uint256 amount,uint256 salt,address operator,uint256 expiration,uint256 masterNonce,";

/// @dev Pausable flag for stored approval transfers of ERC721 assets
uint256 constant PAUSABLE_APPROVAL_TRANSFER_FROM_ERC721 = 1 << 0;
/// @dev Pausable flag for stored approval transfers of ERC1155 assets
uint256 constant PAUSABLE_APPROVAL_TRANSFER_FROM_ERC1155 = 1 << 1;
/// @dev Pausable flag for stored approval transfers of ERC20 assets
uint256 constant PAUSABLE_APPROVAL_TRANSFER_FROM_ERC20 = 1 << 2;

/// @dev Pausable flag for single use permit transfers of ERC721 assets
uint256 constant PAUSABLE_PERMITTED_TRANSFER_FROM_ERC721 = 1 << 3;
/// @dev Pausable flag for single use permit transfers of ERC1155 assets
uint256 constant PAUSABLE_PERMITTED_TRANSFER_FROM_ERC1155 = 1 << 4;
/// @dev Pausable flag for single use permit transfers of ERC20 assets
uint256 constant PAUSABLE_PERMITTED_TRANSFER_FROM_ERC20 = 1 << 5;

/// @dev Pausable flag for order fill transfers of ERC1155 assets
uint256 constant PAUSABLE_ORDER_TRANSFER_FROM_ERC1155 = 1 << 6;
/// @dev Pausable flag for order fill transfers of ERC20 assets
uint256 constant PAUSABLE_ORDER_TRANSFER_FROM_ERC20 = 1 << 7;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev Storage data struct for stored approvals and order approvals
struct PackedApproval {
    // Only used for partial fill position 1155 transfers
    uint8 state;
    // Amount allowed
    uint200 amount;
    // Permission expiry
    uint48 expiration;
}

/// @dev Calldata data struct for order fill amounts
struct OrderFillAmounts {
    uint256 orderStartAmount;
    uint256 requestedFillAmount;
    uint256 minimumFillAmount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev Thrown when a stored approval exceeds type(uint200).max
error PermitC__AmountExceedsStorageMaximum();

/// @dev Thrown when a transfer amount requested exceeds the permitted amount
error PermitC__ApprovalTransferExceededPermittedAmount();

/// @dev Thrown when a transfer is requested after the permit has expired
error PermitC__ApprovalTransferPermitExpiredOrUnset();

/// @dev Thrown when attempting to close an order by an account that is not the owner or operator
error PermitC__CallerMustBeOwnerOrOperator();

/// @dev Thrown when attempting to approve a token type that is not valid for PermitC
error PermitC__InvalidTokenType();

/// @dev Thrown when attempting to invalidate a nonce that has already been used
error PermitC__NonceAlreadyUsedOrRevoked();

/// @dev Thrown when attempting to restore a nonce that has not been used
error PermitC__NonceNotUsedOrRevoked();

/// @dev Thrown when attempting to fill an order that has already been filled or cancelled
error PermitC__OrderIsEitherCancelledOrFilled();

/// @dev Thrown when a transfer amount requested exceeds the permitted amount
error PermitC__SignatureTransferExceededPermittedAmount();

/// @dev Thrown when a transfer is requested after the permit has expired
error PermitC__SignatureTransferExceededPermitExpired();

/// @dev Thrown when attempting to use an advanced permit typehash that is not registered
error PermitC__SignatureTransferPermitHashNotRegistered();

/// @dev Thrown when a permit signature is invalid
error PermitC__SignatureTransferInvalidSignature();

/// @dev Thrown when the remaining fill amount is less than the requested minimum fill
error PermitC__UnableToFillMinimumRequestedQuantity();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import {OrderFillAmounts} from "../DataTypes.sol";

interface IPermitC {

    /**
     * =================================================
     * ==================== Events =====================
     * =================================================
     */

    /// @dev Emitted when an approval is stored
    event Approval(
        address indexed owner,
        address indexed token,
        address indexed operator,
        uint256 id,
        uint200 amount,
        uint48 expiration
    );

    /// @dev Emitted when a user increases their master nonce
    event Lockdown(address indexed owner);

    /// @dev Emitted when an order is opened
    event OrderOpened(
        bytes32 indexed orderId,
        address indexed owner,
        address indexed operator,
        uint256 fillableQuantity
    );

    /// @dev Emitted when an order has a fill
    event OrderFilled(
        bytes32 indexed orderId,
        address indexed owner,
        address indexed operator,
        uint256 amount
    );

    /// @dev Emitted when an order has been fully filled or cancelled
    event OrderClosed(
        bytes32 indexed orderId, 
        address indexed owner, 
        address indexed operator, 
        bool wasCancellation);

    /// @dev Emitted when an order has an amount restored due to a failed transfer
    event OrderRestored(
        bytes32 indexed orderId,
        address indexed owner,
        uint256 amountRestoredToOrder
    );

    /**
     * =================================================
     * ============== Approval Transfers ===============
     * =================================================
     */
    function approve(uint256 tokenType, address token, uint256 id, address operator, uint200 amount, uint48 expiration) external;

    function updateApprovalBySignature(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 nonce,
        uint200 amount,
        address operator,
        uint48 approvalExpiration,
        uint48 sigDeadline,
        address owner,
        bytes calldata signedPermit
    ) external;

    function allowance(
        address owner, 
        address operator, 
        uint256 tokenType,
        address token, 
        uint256 id
    ) external view returns (uint256 amount, uint256 expiration);

    /**
     * =================================================
     * ================ Signed Transfers ===============
     * =================================================
     */
    function registerAdditionalDataHash(string memory additionalDataTypeString) external;

    function permitTransferFromERC721(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 expiration,
        address owner,
        address to,
        bytes calldata signedPermit
    ) external returns (bool isError);

    function permitTransferFromWithAdditionalDataERC721(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 expiration,
        address owner,
        address to,
        bytes32 additionalData,
        bytes32 advancedPermitHash,
        bytes calldata signedPermit
    ) external returns (bool isError);

    function permitTransferFromERC1155(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes calldata signedPermit
    ) external returns (bool isError);

    function permitTransferFromWithAdditionalDataERC1155(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes32 additionalData,
        bytes32 advancedPermitHash,
        bytes calldata signedPermit
    ) external returns (bool isError);

    function permitTransferFromERC20(
        address token,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes calldata signedPermit
    ) external returns (bool isError);

    function permitTransferFromWithAdditionalDataERC20(
        address token,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes32 additionalData,
        bytes32 advancedPermitHash,
        bytes calldata signedPermit
    ) external returns (bool isError);

    function isRegisteredTransferAdditionalDataHash(bytes32 hash) external view returns (bool isRegistered);

    function isRegisteredOrderAdditionalDataHash(bytes32 hash) external view returns (bool isRegistered);

    /**
     * =================================================
     * =============== Order Transfers =================
     * =================================================
     */
    function fillPermittedOrderERC1155(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        uint256 id,
        address owner,
        address to,
        uint256 nonce,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) external returns (uint256 quantityFilled, bool isError);

    function fillPermittedOrderERC20(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        address owner,
        address to,
        uint256 nonce,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) external returns (uint256 quantityFilled, bool isError);

    function closePermittedOrder(
        address owner,
        address operator,
        uint256 tokenType,
        address token,
        uint256 id,
        bytes32 orderId
    ) external;

    function allowance(
        address owner, 
        address operator, 
        uint256 tokenType,
        address token, 
        uint256 id,
        bytes32 orderId
    ) external view returns (uint256 amount, uint256 expiration);


    /**
     * =================================================
     * ================ Nonce Management ===============
     * =================================================
     */
    function invalidateUnorderedNonce(uint256 nonce) external;

    function isValidUnorderedNonce(address owner, uint256 nonce) external view returns (bool isValid);

    function lockdown() external;

    function masterNonce(address owner) external view returns (uint256);

    /**
     * =================================================
     * ============== Transfer Functions ===============
     * =================================================
     */
    function transferFromERC721(
        address from,
        address to,
        address token,
        uint256 id
    ) external returns (bool isError);

    function transferFromERC1155(
        address from,
        address to,
        address token,
        uint256 id,
        uint256 amount
    ) external returns (bool isError);

    function transferFromERC20(
        address from,
        address to,
        address token,
        uint256 amount
    ) external returns (bool isError);

    /**
     * =================================================
     * ============ Signature Verification =============
     * =================================================
     */
    function domainSeparatorV4() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {SINGLE_USE_PERMIT_TYPEHASH, UPDATE_APPROVAL_TYPEHASH} from "../Constants.sol";

library PermitHash {
    /**
     * @notice  Hashes the permit data for a stored approval
     *
     * @param tokenType           The type of token
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param amount              The amount authorized by the owner signature
     * @param nonce               The nonce for the permit
     * @param operator            The account that is allowed to use the permit
     * @param approvalExpiration  The time the permit approval expires
     * @param sigDeadline         The deadline for submitting the permit onchain
     * @param masterNonce         The signers master nonce
     *
     * @return hash  The hash of the permit data
     */
    function hashOnChainApproval(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 amount,
        uint256 nonce,
        address operator,
        uint256 approvalExpiration,
        uint256 sigDeadline,
        uint256 masterNonce
    ) internal pure returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                UPDATE_APPROVAL_TYPEHASH,
                tokenType,
                token,
                id,
                amount,
                nonce,
                operator,
                approvalExpiration,
                sigDeadline,
                masterNonce
            )
        );
    }

    /**
     * @notice  Hashes the permit data with the single user permit without additional data typehash
     *
     * @param tokenType               The type of token
     * @param token                   The address of the token
     * @param id                      The id of the token
     * @param amount                  The amount authorized by the owner signature
     * @param nonce                   The nonce for the permit
     * @param expiration              The time the permit expires
     * @param masterNonce             The signers master nonce
     *
     * @return hash  The hash of the permit data
     */
    function hashSingleUsePermit(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 amount,
        uint256 nonce,
        uint256 expiration,
        uint256 masterNonce
    ) internal view returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                SINGLE_USE_PERMIT_TYPEHASH, tokenType, token, id, amount, nonce, msg.sender, expiration, masterNonce
            )
        );
    }

    /**
     * @notice  Hashes the permit data with the supplied typehash
     *
     * @param tokenType               The type of token
     * @param token                   The address of the token
     * @param id                      The id of the token
     * @param amount                  The amount authorized by the owner signature
     * @param nonce                   The nonce for the permit
     * @param expiration              The time the permit expires
     * @param additionalData          The additional data to validate with the permit signature
     * @param additionalDataTypeHash  The typehash of the permit to use for validating the signature
     * @param masterNonce             The signers master nonce
     *
     * @return hash  The hash of the permit data with the supplied typehash
     */
    function hashSingleUsePermitWithAdditionalData(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 amount,
        uint256 nonce,
        uint256 expiration,
        bytes32 additionalData,
        bytes32 additionalDataTypeHash,
        uint256 masterNonce
    ) internal view returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                additionalDataTypeHash,
                tokenType,
                token,
                id,
                amount,
                nonce,
                msg.sender,
                expiration,
                masterNonce,
                additionalData
            )
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 {
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

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
    error Ownable__CallerIsNotOwner();
    error Ownable__NewOwnerIsZeroAddress();

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
        if(owner() != _msgSender()) revert Ownable__CallerIsNotOwner();
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
        if(newOwner == address(0)) revert Ownable__NewOwnerIsZeroAddress();
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
pragma solidity ^0.8.22;

import "./Errors.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {Ownable} from "./openzeppelin-optimized/Ownable.sol";
import {EIP712} from "./openzeppelin-optimized/EIP712.sol";
import {
    ZERO_BYTES32,
    ZERO,
    ONE,
    ORDER_STATE_OPEN,
    ORDER_STATE_FILLED,
    ORDER_STATE_CANCELLED,
    SINGLE_USE_PERMIT_TRANSFER_ADVANCED_TYPEHASH_STUB,
    PERMIT_ORDER_ADVANCED_TYPEHASH_STUB,
    UPPER_BIT_MASK,
    TOKEN_TYPE_ERC1155,
    TOKEN_TYPE_ERC20,
    TOKEN_TYPE_ERC721,
    PAUSABLE_APPROVAL_TRANSFER_FROM_ERC721,
    PAUSABLE_APPROVAL_TRANSFER_FROM_ERC1155,
    PAUSABLE_APPROVAL_TRANSFER_FROM_ERC20,
    PAUSABLE_PERMITTED_TRANSFER_FROM_ERC721,
    PAUSABLE_PERMITTED_TRANSFER_FROM_ERC1155,
    PAUSABLE_PERMITTED_TRANSFER_FROM_ERC20,
    PAUSABLE_ORDER_TRANSFER_FROM_ERC1155,
    PAUSABLE_ORDER_TRANSFER_FROM_ERC20
} from "./Constants.sol";
import {PackedApproval, OrderFillAmounts} from "./DataTypes.sol";
import {PermitHash} from "./libraries/PermitHash.sol";
import {IPermitC} from "./interfaces/IPermitC.sol";
import {CollateralizedPausableFlags} from "./CollateralizedPausableFlags.sol";

/*
                                                     @@@@@@@@@@@@@@             
                                                    @@@@@@@@@@@@@@@@@@(         
                                                   @@@@@@@@@@@@@@@@@@@@@        
                                                  @@@@@@@@@@@@@@@@@@@@@@@@      
                                                           #@@@@@@@@@@@@@@      
                                                               @@@@@@@@@@@@     
                            @@@@@@@@@@@@@@*                    @@@@@@@@@@@@     
                           @@@@@@@@@@@@@@@     @               @@@@@@@@@@@@     
                          @@@@@@@@@@@@@@@     @                @@@@@@@@@@@      
                         @@@@@@@@@@@@@@@     @@               @@@@@@@@@@@@      
                        @@@@@@@@@@@@@@@     #@@             @@@@@@@@@@@@/       
                        @@@@@@@@@@@@@@.     @@@@@@@@@@@@@@@@@@@@@@@@@@@         
                       @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@            
                      @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@             
                     @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@           
                    @@@@@@@@@@@@@@@     @@@@@&%%%%%%%%&&@@@@@@@@@@@@@@          
                    @@@@@@@@@@@@@@      @@@@@               @@@@@@@@@@@         
                   @@@@@@@@@@@@@@@     @@@@@                 @@@@@@@@@@@        
                  @@@@@@@@@@@@@@@     @@@@@@                 @@@@@@@@@@@        
                 @@@@@@@@@@@@@@@     @@@@@@@                 @@@@@@@@@@@        
                @@@@@@@@@@@@@@@     @@@@@@@                 @@@@@@@@@@@&        
                @@@@@@@@@@@@@@     *@@@@@@@               (@@@@@@@@@@@@         
               @@@@@@@@@@@@@@@     @@@@@@@@             @@@@@@@@@@@@@@          
              @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           
             @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            
            @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              
           .@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 
           @@@@@@@@@@@@@@%     @@@@@@@@@@@@@@@@@@@@@@@@(                        
          @@@@@@@@@@@@@@@                                                       
         @@@@@@@@@@@@@@@                                                        
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                         
       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                          
       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&                                          
      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                           
 
* @title PermitC
* @custom:version 1.0.0
* @author Limit Break, Inc.
* @description Advanced approval management for ERC20, ERC721 and ERC1155 tokens
*              allowing for single use permit transfers, time-bound approvals
*              and order ID based transfers.
*/
contract PermitC is Ownable, CollateralizedPausableFlags, EIP712, IPermitC {
    /**
     * @notice Map of approval details for the provided bytes32 hash to allow for multiple accessors
     *
     * @dev    keccak256(abi.encode(owner, tokenType, token, id, orderId, masterNonce)) =>
     * @dev        operator => (state, amount, expiration)
     * @dev    Utilized for stored approvals by an owner's direct call to `approve` and
     * @dev    approvals by signature in `updateApprovalBySignature`. Both methods use a
     * @dev    bytes32(0) value for the `orderId`.
     */
    mapping(bytes32 => mapping(address => PackedApproval)) internal _transferApprovals;

    /**
     * @notice Map of approval details for the provided bytes32 hash to allow for multiple accessors
     *
     * @dev    keccak256(abi.encode(owner, tokenType, token, id, orderId, masterNonce)) =>
     * @dev        operator => (state, amount, expiration)
     * @dev    Utilized for order approvals by `fillPermittedOrderERC20` and `fillPermittedOrderERC1155`
     * @dev    with the `orderId` provided by the sender.
     */
    mapping(bytes32 => mapping(address => PackedApproval)) internal _orderApprovals;

    /**
     * @notice Map of registered additional data hashes for transfer permits.
     *
     * @dev    This is used to prevent someone from providing an invalid EIP712 envelope label
     * @dev    and tricking a user into signing a different message than they expect.
     */
    mapping(bytes32 => bool) internal _registeredTransferHashes;

    /**
     * @notice Map of registered additional data hashes for order permits.
     *
     * @dev    This is used to prevent someone from providing an invalid EIP712 envelope label
     * @dev    and tricking a user into signing a different message than they expect.
     */
    mapping(bytes32 => bool) internal _registeredOrderHashes;

    /// @dev Map of an address to a bitmap (slot => status)
    mapping(address => mapping(uint256 => uint256)) internal _unorderedNonces;

    /**
     * @notice Master nonce used to invalidate all outstanding approvals for an owner
     *
     * @dev    owner => masterNonce
     * @dev    This is incremented when the owner calls lockdown()
     */
    mapping(address => uint256) internal _masterNonces;

    constructor(
        string memory name,
        string memory version,
        address _defaultContractOwner,
        uint256 _nativeValueToCheckPauseState
    ) CollateralizedPausableFlags(_nativeValueToCheckPauseState) EIP712(name, version) {
        _transferOwnership(_defaultContractOwner);
    }

    /**
     * =================================================
     * ================= Modifiers =====================
     * =================================================
     */
    modifier onlyRegisteredTransferAdvancedTypeHash(bytes32 advancedPermitHash) {
        _requireTransferAdvancedPermitHashIsRegistered(advancedPermitHash);
        _;
    }

    modifier onlyRegisteredOrderAdvancedTypeHash(bytes32 advancedPermitHash) {
        _requireOrderAdvancedPermitHashIsRegistered(advancedPermitHash);
        _;
    }

    /**
     * =================================================
     * ============== Approval Transfers ===============
     * =================================================
     */

    /**
     * @notice Approve an operator to spend a specific token / ID combination
     * @notice This function is compatible with ERC20, ERC721 and ERC1155
     * @notice To give unlimited approval for ERC20 and ERC1155, set amount to type(uint200).max
     * @notice When approving an ERC721, you MUST set amount to `1`
     * @notice When approving an ERC20, you MUST set id to `0`
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Updates the approval for an operator to use an amount of a specific token / ID combination
     * @dev    2. If the expiration is 0, the approval is valid only in the context of the current block
     * @dev    3. If the expiration is not 0, the approval is valid until the expiration timestamp
     * @dev    4. If the provided amount is type(uint200).max, the approval is unlimited
     *
     * @param  tokenType  The type of token being approved - must be 20, 721 or 1155.
     * @param  token      The address of the token contract
     * @param  id         The token ID
     * @param  operator   The address of the operator
     * @param  amount     The amount of tokens to approve
     * @param  expiration The expiration timestamp of the approval
     */
    function approve(uint256 tokenType, address token, uint256 id, address operator, uint200 amount, uint48 expiration)
        external
    {
        _requireValidTokenType(tokenType);
        _storeApproval(tokenType, token, id, amount, expiration, msg.sender, operator);
    }

    /**
     * @notice Use a signed permit to increase the allowance for a provided operator
     * @notice This function is compatible with ERC20, ERC721 and ERC1155
     * @notice To give unlimited approval for ERC20 and ERC1155, set amount to type(uint200).max
     * @notice When approving an ERC721, you MUST set amount to `1`
     * @notice When approving an ERC20, you MUST set id to `0`
     * @notice An `approvalExpiration` of zero is considered an atomic permit which will use the
     * @notice current block time as the expiration time when storing the permit data.
     *
     * @dev    - Throws if the permit has expired
     * @dev    - Throws if the permit's nonce has already been used
     * @dev    - Throws if the permit signature is does not recover to the provided owner
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Updates the approval for an operator to use an amount of a specific token / ID combination
     * @dev    3. Sets the expiration of the approval to the expiration timestamp of the permit
     * @dev    4. If the provided amount is type(uint200).max, the approval is unlimited
     *
     * @param  tokenType            The type of token being approved - must be 20, 721 or 1155.
     * @param  token                Address of the token to approve
     * @param  id                   The token ID
     * @param  nonce                The nonce of the permit
     * @param  amount               The amount of tokens to approve
     * @param  operator             The address of the operator
     * @param  approvalExpiration   The expiration timestamp of the approval
     * @param  sigDeadline          The deadline timestamp for the permit signature
     * @param  owner                The owner of the tokens
     * @param  signedPermit         The permit signature, signed by the owner
     */
    function updateApprovalBySignature(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 nonce,
        uint200 amount,
        address operator,
        uint48 approvalExpiration,
        uint48 sigDeadline,
        address owner,
        bytes calldata signedPermit
    ) external {
        if (block.timestamp > sigDeadline) {
            revert PermitC__ApprovalTransferPermitExpiredOrUnset();
        }
        _requireValidTokenType(tokenType);
        _checkAndInvalidateNonce(owner, nonce);
        _verifyPermitSignature(
            _hashTypedDataV4(
                PermitHash.hashOnChainApproval(
                    tokenType, token, id, amount, nonce, operator, approvalExpiration, sigDeadline, _masterNonces[owner]
                )
            ),
            signedPermit,
            owner
        );

        // Expiration of zero is considered an atomic permit which is only valid in the
        // current block.
        approvalExpiration = approvalExpiration == 0 ? uint48(block.timestamp) : approvalExpiration;

        _storeApproval(tokenType, token, id, amount, approvalExpiration, owner, operator);
    }

    /**
     * @notice Returns the amount of allowance an operator has and it's expiration for a specific token and id
     * @notice If the expiration on the allowance has expired, returns 0
     * @notice To retrieve allowance for ERC20, set id to `0`
     *
     * @param  owner     The owner of the token
     * @param  operator  The operator of the token
     * @param  tokenType The type of token the allowance is for
     * @param  token     The address of the token contract
     * @param  id        The token ID
     *
     * @return allowedAmount The amount of allowance the operator has
     * @return expiration    The expiration timestamp of the allowance
     */
    function allowance(address owner, address operator, uint256 tokenType, address token, uint256 id)
        external
        view
        returns (uint256 allowedAmount, uint256 expiration)
    {
        return _allowance(_transferApprovals, owner, operator, tokenType, token, id, ZERO_BYTES32);
    }

    /**
     * =================================================
     * ================ Signed Transfers ===============
     * =================================================
     */

    /**
     * @notice Registers the combination of a provided string with the `SINGLE_USE_PERMIT_TRANSFER_ADVANCED_TYPEHASH_STUB`
     * @notice and `PERMIT_ORDER_ADVANCED_TYPEHASH_STUB` to create valid additional data hashes
     *
     * @dev    This function prevents malicious actors from changing the label of the EIP712 hash
     * @dev    to a value that would fool an external user into signing a different message.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The provided string is combined with the `SINGLE_USE_PERMIT_TRANSFER_ADVANCED_TYPEHASH_STUB` string
     * @dev    2. The combined string is hashed using keccak256
     * @dev    3. The resulting hash is added to the `_registeredTransferHashes` mapping
     * @dev    4. The provided string is combined with the `PERMIT_ORDER_ADVANCED_TYPEHASH_STUB` string
     * @dev    5. The combined string is hashed using keccak256
     * @dev    6. The resulting hash is added to the `_registeredOrderHashes` mapping
     *
     * @param  additionalDataTypeString The string to register as a valid additional data hash
     */
    function registerAdditionalDataHash(string calldata additionalDataTypeString) external {
        _registeredTransferHashes[keccak256(
            bytes(string.concat(SINGLE_USE_PERMIT_TRANSFER_ADVANCED_TYPEHASH_STUB, additionalDataTypeString))
        )] = true;

        _registeredOrderHashes[keccak256(
            bytes(string.concat(PERMIT_ORDER_ADVANCED_TYPEHASH_STUB, additionalDataTypeString))
        )] = true;
    }

    /**
     * @notice Transfer an ERC721 token from the owner to the recipient using a permit signature.
     *
     * @dev    Be advised that the permitted amount for ERC721 is always inferred to be 1, so signed permitted amount
     * @dev    MUST always be set to 1.
     *
     * @dev    - Throws if the permit is expired
     * @dev    - Throws if the nonce has already been used
     * @dev    - Throws if the permit is not signed by the owner
     * @dev    - Throws if the requested amount exceeds the permitted amount
     * @dev    - Throws if the provided token address does not implement ERC721 transferFrom function
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token from the owner to the recipient
     * @dev    2. The nonce of the permit is marked as used
     * @dev    3. Performs any additional checks in the before and after hooks
     *
     * @param token         The address of the token
     * @param id            The ID of the token
     * @param nonce         The nonce of the permit
     * @param expiration    The expiration timestamp of the permit
     * @param owner         The owner of the token
     * @param to            The address to transfer the tokens to
     * @param signedPermit  The permit signature, signed by the owner
     *
     * @return isError      True if the transfer failed, false otherwise
     */
    function permitTransferFromERC721(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 expiration,
        address owner,
        address to,
        bytes calldata signedPermit
    ) external returns (bool isError) {
        _requireNotPaused(PAUSABLE_PERMITTED_TRANSFER_FROM_ERC721);

        _checkPermitApproval(TOKEN_TYPE_ERC721, token, id, ONE, nonce, expiration, owner, ONE, signedPermit);
        isError = _transferFromERC721(owner, to, token, id);

        if (isError) {
            _restoreNonce(owner, nonce);
        }
    }

    /**
     * @notice Transfers an ERC721 token from the owner to the recipient using a permit signature
     * @notice This function includes additional data to verify on the signature, allowing
     * @notice protocols to extend the validation in one function call. NOTE: before calling this
     * @notice function you MUST register the stub end of the additional data typestring using
     * @notice the `registerAdditionalDataHash` function.
     *
     * @dev    Be advised that the permitted amount for ERC721 is always inferred to be 1, so signed permitted amount
     * @dev    MUST always be set to 1.
     *
     * @dev    - Throws for any reason permitTransferFromERC721 would.
     * @dev    - Throws if the additional data does not match the signature
     * @dev    - Throws if the provided hash has not been registered as a valid additional data hash
     * @dev    - Throws if the provided hash does not match the provided additional data
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token from the owner to the recipient
     * @dev    2. Performs any additional checks in the before and after hooks
     * @dev    3. The nonce of the permit is marked as used
     *
     * @param  token                    The address of the token
     * @param  id                       The ID of the token
     * @param  nonce                    The nonce of the permit
     * @param  expiration               The expiration timestamp of the permit
     * @param  owner                    The owner of the token
     * @param  to                       The address to transfer the tokens to
     * @param  additionalData           The additional data to verify on the signature
     * @param  advancedPermitHash       The hash of the additional data
     * @param  signedPermit             The permit signature, signed by the owner
     *
     * @return isError                  True if the transfer failed, false otherwise
     */
    function permitTransferFromWithAdditionalDataERC721(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 expiration,
        address owner,
        address to,
        bytes32 additionalData,
        bytes32 advancedPermitHash,
        bytes calldata signedPermit
    ) external onlyRegisteredTransferAdvancedTypeHash(advancedPermitHash) returns (bool isError) {
        _requireNotPaused(PAUSABLE_PERMITTED_TRANSFER_FROM_ERC721);

        _checkPermitApprovalWithAdditionalDataERC721(
            token, id, ONE, nonce, expiration, owner, ONE, signedPermit, additionalData, advancedPermitHash
        );
        isError = _transferFromERC721(owner, to, token, id);

        if (isError) {
            _restoreNonce(owner, nonce);
        }
    }

    /**
     * @notice Transfer an ERC1155 token from the owner to the recipient using a permit signature
     *
     * @dev    - Throws if the permit is expired
     * @dev    - Throws if the nonce has already been used
     * @dev    - Throws if the permit is not signed by the owner
     * @dev    - Throws if the requested amount exceeds the permitted amount
     * @dev    - Throws if the provided token address does not implement ERC1155 safeTransferFrom function
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. The nonce of the permit is marked as used
     * @dev    3. Performs any additional checks in the before and after hooks
     *
     * @param token           The address of the token
     * @param id              The ID of the token
     * @param nonce           The nonce of the permit
     * @param permitAmount    The amount of tokens permitted by the owner
     * @param expiration      The expiration timestamp of the permit
     * @param owner           The owner of the token
     * @param to              The address to transfer the tokens to
     * @param transferAmount  The amount of tokens to transfer
     * @param signedPermit    The permit signature, signed by the owner
     *
     * @return isError        True if the transfer failed, false otherwise
     */
    function permitTransferFromERC1155(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes calldata signedPermit
    ) external returns (bool isError) {
        _requireNotPaused(PAUSABLE_PERMITTED_TRANSFER_FROM_ERC1155);

        _checkPermitApproval(
            TOKEN_TYPE_ERC1155, token, id, permitAmount, nonce, expiration, owner, transferAmount, signedPermit
        );
        isError = _transferFromERC1155(token, owner, to, id, transferAmount);

        if (isError) {
            _restoreNonce(owner, nonce);
        }
    }

    /**
     * @notice Transfers a token from the owner to the recipient using a permit signature
     * @notice This function includes additional data to verify on the signature, allowing
     * @notice protocols to extend the validation in one function call. NOTE: before calling this
     * @notice function you MUST register the stub end of the additional data typestring using
     * @notice the `registerAdditionalDataHash` function.
     *
     * @dev    - Throws for any reason permitTransferFrom would.
     * @dev    - Throws if the additional data does not match the signature
     * @dev    - Throws if the provided hash has not been registered as a valid additional data hash
     * @dev    - Throws if the provided hash does not match the provided additional data
     * @dev    - Throws if the provided hash has not been registered as a valid additional data hash
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Performs any additional checks in the before and after hooks
     * @dev    3. The nonce of the permit is marked as used
     *
     * @param  token                    The address of the token
     * @param  id                       The ID of the token
     * @param  nonce                    The nonce of the permit
     * @param  permitAmount             The amount of tokens permitted by the owner
     * @param  expiration               The expiration timestamp of the permit
     * @param  owner                    The owner of the token
     * @param  to                       The address to transfer the tokens to
     * @param  transferAmount           The amount of tokens to transfer
     * @param  additionalData           The additional data to verify on the signature
     * @param  advancedPermitHash       The hash of the additional data
     * @param  signedPermit             The permit signature, signed by the owner
     *
     * @return isError                  True if the transfer failed, false otherwise
     */
    function permitTransferFromWithAdditionalDataERC1155(
        address token,
        uint256 id,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes32 additionalData,
        bytes32 advancedPermitHash,
        bytes calldata signedPermit
    ) external onlyRegisteredTransferAdvancedTypeHash(advancedPermitHash) returns (bool isError) {
        _requireNotPaused(PAUSABLE_PERMITTED_TRANSFER_FROM_ERC1155);

        _checkPermitApprovalWithAdditionalDataERC1155(
            token,
            id,
            permitAmount,
            nonce,
            expiration,
            owner,
            transferAmount,
            signedPermit,
            additionalData,
            advancedPermitHash
        );

        // copy id to top of stack to avoid stack too deep
        uint256 tmpId = id;
        isError = _transferFromERC1155(token, owner, to, tmpId, transferAmount);

        if (isError) {
            _restoreNonce(owner, nonce);
        }
    }

    /**
     * @notice Transfer an ERC20 token from the owner to the recipient using a permit signature.
     *
     * @dev    Be advised that the token ID for ERC20 is always inferred to be 0, so signed token ID
     * @dev    MUST always be set to 0.
     *
     * @dev    - Throws if the permit is expired
     * @dev    - Throws if the nonce has already been used
     * @dev    - Throws if the permit is not signed by the owner
     * @dev    - Throws if the requested amount exceeds the permitted amount
     * @dev    - Throws if the provided token address does not implement ERC20 transferFrom function
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token in the requested amount from the owner to the recipient
     * @dev    2. The nonce of the permit is marked as used
     * @dev    3. Performs any additional checks in the before and after hooks
     *
     * @param token         The address of the token
     * @param nonce         The nonce of the permit
     * @param permitAmount  The amount of tokens permitted by the owner
     * @param expiration    The expiration timestamp of the permit
     * @param owner         The owner of the token
     * @param to            The address to transfer the tokens to
     * @param signedPermit  The permit signature, signed by the owner
     *
     * @return isError      True if the transfer failed, false otherwise
     */
    function permitTransferFromERC20(
        address token,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes calldata signedPermit
    ) external returns (bool isError) {
        _requireNotPaused(PAUSABLE_PERMITTED_TRANSFER_FROM_ERC20);

        _checkPermitApproval(
            TOKEN_TYPE_ERC20, token, ZERO, permitAmount, nonce, expiration, owner, transferAmount, signedPermit
        );
        isError = _transferFromERC20(token, owner, to, ZERO, transferAmount);

        if (isError) {
            _restoreNonce(owner, nonce);
        }
    }

    /**
     * @notice Transfers an ERC20 token from the owner to the recipient using a permit signature
     * @notice This function includes additional data to verify on the signature, allowing
     * @notice protocols to extend the validation in one function call. NOTE: before calling this
     * @notice function you MUST register the stub end of the additional data typestring using
     * @notice the `registerAdditionalDataHash` function.
     *
     * @dev    Be advised that the token ID for ERC20 is always inferred to be 0, so signed token ID
     * @dev    MUST always be set to 0.
     *
     * @dev    - Throws for any reason permitTransferFromERC20 would.
     * @dev    - Throws if the additional data does not match the signature
     * @dev    - Throws if the provided hash has not been registered as a valid additional data hash
     * @dev    - Throws if the provided hash does not match the provided additional data
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Performs any additional checks in the before and after hooks
     * @dev    3. The nonce of the permit is marked as used
     *
     * @param  token                    The address of the token
     * @param  nonce                    The nonce of the permit
     * @param  permitAmount             The amount of tokens permitted by the owner
     * @param  expiration               The expiration timestamp of the permit
     * @param  owner                    The owner of the token
     * @param  to                       The address to transfer the tokens to
     * @param  transferAmount           The amount of tokens to transfer
     * @param  additionalData           The additional data to verify on the signature
     * @param  advancedPermitHash       The hash of the additional data
     * @param  signedPermit             The permit signature, signed by the owner
     *
     * @return isError                  True if the transfer failed, false otherwise
     */
    function permitTransferFromWithAdditionalDataERC20(
        address token,
        uint256 nonce,
        uint256 permitAmount,
        uint256 expiration,
        address owner,
        address to,
        uint256 transferAmount,
        bytes32 additionalData,
        bytes32 advancedPermitHash,
        bytes calldata signedPermit
    ) external onlyRegisteredTransferAdvancedTypeHash(advancedPermitHash) returns (bool isError) {
        _requireNotPaused(PAUSABLE_PERMITTED_TRANSFER_FROM_ERC20);

        _checkPermitApprovalWithAdditionalDataERC20(
            token,
            ZERO,
            permitAmount,
            nonce,
            expiration,
            owner,
            transferAmount,
            signedPermit,
            additionalData,
            advancedPermitHash
        );
        isError = _transferFromERC20(token, owner, to, ZERO, transferAmount);

        if (isError) {
            _restoreNonce(owner, nonce);
        }
    }

    /**
     * @notice Returns true if the provided hash has been registered as a valid additional data hash for transfers.
     *
     * @param  hash The hash to check
     *
     * @return isRegistered true if the hash is valid, false otherwise
     */
    function isRegisteredTransferAdditionalDataHash(bytes32 hash) external view returns (bool isRegistered) {
        isRegistered = _registeredTransferHashes[hash];
    }

    /**
     * @notice Returns true if the provided hash has been registered as a valid additional data hash for orders.
     *
     * @param  hash The hash to check
     *
     * @return isRegistered true if the hash is valid, false otherwise
     */
    function isRegisteredOrderAdditionalDataHash(bytes32 hash) external view returns (bool isRegistered) {
        isRegistered = _registeredOrderHashes[hash];
    }

    /**
     * =================================================
     * =============== Order Transfers =================
     * =================================================
     */

    /**
     * @notice Transfers an ERC1155 token from the owner to the recipient using a permit signature
     * @notice Order transfers are used to transfer a specific amount of a token from a specific order
     * @notice and allow for multiple uses of the same permit up to the allocated amount. NOTE: before calling this
     * @notice function you MUST register the stub end of the additional data typestring using
     * @notice the `registerAdditionalDataHash` function.
     *
     * @dev    - Throws if the permit is expired
     * @dev    - Throws if the permit is not signed by the owner
     * @dev    - Throws if the requested amount + amount already filled exceeds the permitted amount
     * @dev    - Throws if the requested amount is less than the minimum fill amount
     * @dev    - Throws if the provided token address does not implement ERC1155 safeTransferFrom function
     * @dev    - Throws if the provided advanced permit hash has not been registered
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Updates the amount filled for the order ID
     * @dev    3. If completely filled, marks the order as filled
     *
     * @param  signedPermit         The permit signature, signed by the owner
     * @param  orderFillAmounts     The amount of tokens to transfer
     * @param  token                The address of the token
     * @param  id                   The ID of the token
     * @param  owner                The owner of the token
     * @param  to                   The address to transfer the tokens to
     * @param  salt                 The salt of the permit
     * @param  expiration           The expiration timestamp of the permit
     * @param  orderId              The order ID
     * @param  advancedPermitHash   The hash of the additional data
     *
     * @return quantityFilled       The amount of tokens filled
     * @return isError              True if the transfer failed, false otherwise
     */
    function fillPermittedOrderERC1155(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        uint256 id,
        address owner,
        address to,
        uint256 salt,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) external onlyRegisteredOrderAdvancedTypeHash(advancedPermitHash) returns (uint256 quantityFilled, bool isError) {
        _requireNotPaused(PAUSABLE_ORDER_TRANSFER_FROM_ERC1155);

        PackedApproval storage orderStatus = _checkOrderTransferERC1155(
            signedPermit, orderFillAmounts, token, id, owner, salt, expiration, orderId, advancedPermitHash
        );

        (quantityFilled, isError) =
            _orderTransfer(orderStatus, orderFillAmounts, token, id, owner, to, orderId, _transferFromERC1155);

        if (isError) {
            _restoreFillableItems(orderStatus, owner, orderId, quantityFilled, true);
        }
    }

    /**
     * @notice Transfers an ERC20 token from the owner to the recipient using a permit signature
     * @notice Order transfers are used to transfer a specific amount of a token from a specific order
     * @notice and allow for multiple uses of the same permit up to the allocated amount. NOTE: before calling this
     * @notice function you MUST register the stub end of the additional data typestring using
     * @notice the `registerAdditionalDataHash` function.
     *
     * @dev    - Throws if the permit is expired
     * @dev    - Throws if the permit is not signed by the owner
     * @dev    - Throws if the requested amount + amount already filled exceeds the permitted amount
     * @dev    - Throws if the requested amount is less than the minimum fill amount
     * @dev    - Throws if the provided token address does not implement ERC20 transferFrom function
     * @dev    - Throws if the provided advanced permit hash has not been registered
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Updates the amount filled for the order ID
     * @dev    3. If completely filled, marks the order as filled
     *
     * @param  signedPermit         The permit signature, signed by the owner
     * @param  orderFillAmounts     The amount of tokens to transfer
     * @param  token                The address of the token
     * @param  owner                The owner of the token
     * @param  to                   The address to transfer the tokens to
     * @param  salt                 The salt of the permit
     * @param  expiration           The expiration timestamp of the permit
     * @param  orderId              The order ID
     * @param  advancedPermitHash   The hash of the additional data
     *
     * @return quantityFilled       The amount of tokens filled
     * @return isError              True if the transfer failed, false otherwise
     */
    function fillPermittedOrderERC20(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        address owner,
        address to,
        uint256 salt,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) external onlyRegisteredOrderAdvancedTypeHash(advancedPermitHash) returns (uint256 quantityFilled, bool isError) {
        _requireNotPaused(PAUSABLE_ORDER_TRANSFER_FROM_ERC20);

        PackedApproval storage orderStatus = _checkOrderTransferERC20(
            signedPermit, orderFillAmounts, token, ZERO, owner, salt, expiration, orderId, advancedPermitHash
        );

        (quantityFilled, isError) =
            _orderTransfer(orderStatus, orderFillAmounts, token, ZERO, owner, to, orderId, _transferFromERC20);

        if (isError) {
            _restoreFillableItems(orderStatus, owner, orderId, quantityFilled, true);
        }
    }

    /**
     * @notice Closes an outstanding order to prevent further execution of transfers.
     *
     * @dev    - Throws if the order is not in the open state
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Marks the order as cancelled
     * @dev    2. Sets the order amount to 0
     * @dev    3. Sets the order expiration to 0
     * @dev    4. Emits a OrderClosed event
     *
     * @param  owner      The owner of the token
     * @param  operator   The operator allowed to transfer the token
     * @param  tokenType  The type of token the order is for - must be 20, 721 or 1155.
     * @param  token      The address of the token contract
     * @param  id         The token ID
     * @param  orderId    The order ID
     */
    function closePermittedOrder(
        address owner,
        address operator,
        uint256 tokenType,
        address token,
        uint256 id,
        bytes32 orderId
    ) external {
        if (!(msg.sender == owner || msg.sender == operator)) {
            revert PermitC__CallerMustBeOwnerOrOperator();
        }
        _requireValidTokenType(tokenType);
        PackedApproval storage orderStatus =
            _getPackedApprovalPtr(_orderApprovals, owner, tokenType, token, id, orderId, operator);

        if (orderStatus.state == ORDER_STATE_OPEN) {
            orderStatus.state = ORDER_STATE_CANCELLED;
            orderStatus.amount = 0;
            orderStatus.expiration = 0;
            emit OrderClosed(orderId, owner, operator, true);
        } else {
            revert PermitC__OrderIsEitherCancelledOrFilled();
        }
    }

    /**
     * @notice Returns the amount of allowance an operator has for a specific token and id
     * @notice If the expiration on the allowance has expired, returns 0
     *
     * @dev    Overload of the on chain allowance function for approvals with a specified order ID
     *
     * @param  owner    The owner of the token
     * @param  operator The operator of the token
     * @param  token    The address of the token contract
     * @param  id       The token ID
     *
     * @return allowedAmount The amount of allowance the operator has
     */
    function allowance(address owner, address operator, uint256 tokenType, address token, uint256 id, bytes32 orderId)
        external
        view
        returns (uint256 allowedAmount, uint256 expiration)
    {
        return _allowance(_orderApprovals, owner, operator, tokenType, token, id, orderId);
    }

    /**
     * =================================================
     * ================ Nonce Management ===============
     * =================================================
     */

    /**
     * @notice Invalidates the provided nonce
     *
     * @dev    - Throws if the provided nonce has already been used
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Sets the provided nonce as used for the sender
     *
     * @param  nonce Nonce to invalidate
     */
    function invalidateUnorderedNonce(uint256 nonce) external {
        _checkAndInvalidateNonce(msg.sender, nonce);
    }

    /**
     * @notice Returns if the provided nonce has been used
     *
     * @param  owner The owner of the token
     * @param  nonce The nonce to check
     *
     * @return isValid true if the nonce is valid, false otherwise
     */
    function isValidUnorderedNonce(address owner, uint256 nonce) external view returns (bool isValid) {
        isValid = ((_unorderedNonces[owner][uint248(nonce >> 8)] >> uint8(nonce)) & ONE) == ZERO;
    }

    /**
     * @notice Revokes all outstanding approvals for the sender
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Increments the master nonce for the sender
     * @dev    2. All outstanding approvals for the sender are invalidated
     */
    function lockdown() external {
        unchecked {
            _masterNonces[msg.sender]++;
        }

        emit Lockdown(msg.sender);
    }

    /**
     * @notice Returns the master nonce for the provided owner address
     *
     * @param  owner The owner address
     *
     * @return The master nonce
     */
    function masterNonce(address owner) external view returns (uint256) {
        return _masterNonces[owner];
    }

    /**
     * =================================================
     * ============== Transfer Functions ===============
     * =================================================
     */

    /**
     * @notice Transfer an ERC721 token from the owner to the recipient using on chain approvals
     *
     * @dev    Public transfer function overload for approval transfers
     * @dev    - Throws if the provided token address does not implement ERC721 transferFrom function
     * @dev    - Throws if the requested amount exceeds the approved amount
     * @dev    - Throws if the approval is expired
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Decrements the approval amount by the requested amount
     * @dev    3. Performs any additional checks in the before and after hooks
     *
     * @param  owner    The owner of the token
     * @param  to       The recipient of the token
     * @param  token    The address of the token
     * @param  id       The id of the token
     *
     * @return isError  True if the transfer failed, false otherwise
     */
    function transferFromERC721(address owner, address to, address token, uint256 id) external returns (bool isError) {
        _requireNotPaused(PAUSABLE_APPROVAL_TRANSFER_FROM_ERC721);

        PackedApproval storage approval = _checkAndUpdateApproval(owner, TOKEN_TYPE_ERC721, token, id, ONE, true);
        isError = _transferFromERC721(owner, to, token, id);

        if (isError) {
            _restoreFillableItems(approval, owner, ZERO_BYTES32, ONE, false);
        }
    }

    /**
     * @notice Transfer an ERC1155 token from the owner to the recipient using on chain approvals
     *
     * @dev    Public transfer function overload for approval transfers
     * @dev    - Throws if the provided token address does not implement ERC1155 safeTransferFrom function
     * @dev    - Throws if the requested amount exceeds the approved amount
     * @dev    - Throws if the approval is expired
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Decrements the approval amount by the requested amount
     * @dev    3. Performs any additional checks in the before and after hooks
     *
     * @param  owner     The owner of the token
     * @param  to       The recipient of the token
     * @param  amount   The amount of the token to transfer
     * @param  token    The address of the token
     * @param  id       The id of the token
     *
     * @return isError  True if the transfer failed, false otherwise
     */
    function transferFromERC1155(address owner, address to, address token, uint256 id, uint256 amount)
        external
        returns (bool isError)
    {
        _requireNotPaused(PAUSABLE_APPROVAL_TRANSFER_FROM_ERC1155);

        PackedApproval storage approval = _checkAndUpdateApproval(owner, TOKEN_TYPE_ERC1155, token, id, amount, false);
        isError = _transferFromERC1155(token, owner, to, id, amount);

        if (isError) {
            _restoreFillableItems(approval, owner, ZERO_BYTES32, amount, false);
        }
    }

    /**
     * @notice Transfer an ERC20 token from the owner to the recipient using on chain approvals
     *
     * @dev    Public transfer function overload for approval transfers
     * @dev    - Throws if the provided token address does not implement ERC20 transferFrom function
     * @dev    - Throws if the requested amount exceeds the approved amount
     * @dev    - Throws if the approval is expired
     * @dev    - Returns `false` if the transfer fails
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. Transfers the token (in the requested amount) from the owner to the recipient
     * @dev    2. Decrements the approval amount by the requested amount
     * @dev    3. Performs any additional checks in the before and after hooks
     *
     * @param  owner     The owner of the token
     * @param  to       The recipient of the token
     * @param  amount   The amount of the token to transfer
     * @param  token    The address of the token
     *
     * @return isError  True if the transfer failed, false otherwise
     */
    function transferFromERC20(address owner, address to, address token, uint256 amount)
        external
        returns (bool isError)
    {
        _requireNotPaused(PAUSABLE_APPROVAL_TRANSFER_FROM_ERC20);

        PackedApproval storage approval = _checkAndUpdateApproval(owner, TOKEN_TYPE_ERC20, token, ZERO, amount, false);
        isError = _transferFromERC20(token, owner, to, ZERO, amount);

        if (isError) {
            _restoreFillableItems(approval, owner, ZERO_BYTES32, amount, false);
        }
    }

    /**
     * @notice  Performs a transfer of an ERC721 token.
     *
     * @dev     Will **NOT** attempt transfer if `_beforeTransferFrom` hook returns false.
     * @dev     Will **NOT** revert if the transfer is unsucessful.
     * @dev     Invokers **MUST** check `isError` return value to determine success.
     *
     * @param owner  The owner of the token being transferred
     * @param to     The address to transfer the token to
     * @param token  The token address of the token being transferred
     * @param id     The token id being transferred
     *
     * @return isError True if the token was not transferred, false if token was transferred
     */
    function _transferFromERC721(address owner, address to, address token, uint256 id)
        internal
        returns (bool isError)
    {
        isError = _beforeTransferFrom(TOKEN_TYPE_ERC721, token, owner, to, id, ONE);

        if (!isError) {
            try IERC721(token).transferFrom(owner, to, id) {}
            catch {
                isError = true;
            }
        }
    }

    /**
     * @notice  Performs a transfer of an ERC1155 token.
     *
     * @dev     Will **NOT** attempt transfer if `_beforeTransferFrom` hook returns false.
     * @dev     Will **NOT** revert if the transfer is unsucessful.
     * @dev     Invokers **MUST** check `isError` return value to determine success.
     *
     * @param token  The token address of the token being transferred
     * @param owner  The owner of the token being transferred
     * @param to     The address to transfer the token to
     * @param id     The token id being transferred
     * @param amount The quantity of token id to transfer
     *
     * @return isError True if the token was not transferred, false if token was transferred
     */
    function _transferFromERC1155(address token, address owner, address to, uint256 id, uint256 amount)
        internal
        returns (bool isError)
    {
        isError = _beforeTransferFrom(TOKEN_TYPE_ERC1155, token, owner, to, id, amount);

        if (!isError) {
            try IERC1155(token).safeTransferFrom(owner, to, id, amount, "") {}
            catch {
                isError = true;
            }
        }
    }

    /**
     * @notice  Performs a transfer of an ERC20 token.
     *
     * @dev     Will **NOT** attempt transfer if `_beforeTransferFrom` hook returns false.
     * @dev     Will **NOT** revert if the transfer is unsucessful.
     * @dev     Invokers **MUST** check `isError` return value to determine success.
     *
     * @param token  The token address of the token being transferred
     * @param owner  The owner of the token being transferred
     * @param to     The address to transfer the token to
     * @param amount The quantity of token id to transfer
     *
     * @return isError True if the token was not transferred, false if token was transferred
     */
    function _transferFromERC20(address token, address owner, address to, uint256, /*id*/ uint256 amount)
        internal
        returns (bool isError)
    {
        isError = _beforeTransferFrom(TOKEN_TYPE_ERC20, token, owner, to, ZERO, amount);

        if (!isError) {
            (bool success, bytes memory data) =
                token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, owner, to, amount));
            if (!success) {
                isError = true;
            } else if (data.length > 0) {
                isError = !abi.decode(data, (bool));
            }
        }
    }

    /**
     * =================================================
     * ============ Signature Verification =============
     * =================================================
     */

    /**
     * @notice Returns the domain separator used in the permit signature
     *
     * @return domainSeparator The domain separator
     */
    function domainSeparatorV4() external view returns (bytes32 domainSeparator) {
        domainSeparator = _domainSeparatorV4();
    }

    /**
     * @notice  Verifies a permit signature based on the bytes length of the signature provided.
     *
     * @dev     Throws when -
     * @dev         The bytes signature length is 64 or 65 bytes AND
     * @dev         The ECDSA recovered signer is not the owner AND
     * @dev         The owner's code length is zero OR the owner does not return a valid EIP-1271 response
     * @dev
     * @dev         OR
     * @dev
     * @dev         The bytes signature length is not 64 or 65 bytes AND
     * @dev         The owner's code length is zero OR the owner does not return a valid EIP-1271 response
     */
    function _verifyPermitSignature(bytes32 digest, bytes calldata signature, address owner) internal view {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // Divide the signature in r, s and v variables
            /// @solidity memory-safe-assembly
            assembly {
                r := calldataload(signature.offset)
                s := calldataload(add(signature.offset, 32))
                v := byte(0, calldataload(add(signature.offset, 64)))
            }
            (bool isError, address signer) = _ecdsaRecover(digest, v, r, s);
            if (owner != signer || isError) {
                _verifyEIP1271Signature(owner, digest, signature);
            }
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // Divide the signature in r and vs variables
            /// @solidity memory-safe-assembly
            assembly {
                r := calldataload(signature.offset)
                vs := calldataload(add(signature.offset, 32))
            }
            (bool isError, address signer) = _ecdsaRecover(digest, r, vs);
            if (owner != signer || isError) {
                _verifyEIP1271Signature(owner, digest, signature);
            }
        } else {
            _verifyEIP1271Signature(owner, digest, signature);
        }
    }

    /**
     * @notice Verifies an EIP-1271 signature.
     *
     * @dev    Throws when `signer` code length is zero OR the EIP-1271 call does not
     * @dev    return the correct magic value.
     *
     * @param signer     The signer address to verify a signature with
     * @param hash       The hash digest to verify with the signer
     * @param signature  The signature to verify
     */
    function _verifyEIP1271Signature(address signer, bytes32 hash, bytes calldata signature) internal view {
        if (signer.code.length == 0) {
            revert PermitC__SignatureTransferInvalidSignature();
        }

        if (!_safeIsValidSignature(signer, hash, signature)) {
            revert PermitC__SignatureTransferInvalidSignature();
        }
    }

    /**
     * @notice  Overload of the `_ecdsaRecover` function to unpack the `v` and `s` values
     *
     * @param digest    The hash digest that was signed
     * @param r         The `r` value of the signature
     * @param vs        The packed `v` and `s` values of the signature
     *
     * @return isError  True if the ECDSA function is provided invalid inputs
     * @return signer   The recovered address from ECDSA
     */
    function _ecdsaRecover(bytes32 digest, bytes32 r, bytes32 vs)
        internal
        pure
        returns (bool isError, address signer)
    {
        unchecked {
            bytes32 s = vs & UPPER_BIT_MASK;
            uint8 v = uint8(uint256(vs >> 255)) + 27;

            (isError, signer) = _ecdsaRecover(digest, v, r, s);
        }
    }

    /**
     * @notice  Recovers the signer address using ECDSA
     *
     * @dev     Does **NOT** revert if invalid input values are provided or `signer` is recovered as address(0)
     * @dev     Returns an `isError` value in those conditions that is handled upstream
     *
     * @param digest    The hash digest that was signed
     * @param v         The `v` value of the signature
     * @param r         The `r` value of the signature
     * @param s         The `s` value of the signature
     *
     * @return isError  True if the ECDSA function is provided invalid inputs
     * @return signer   The recovered address from ECDSA
     */
    function _ecdsaRecover(bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool isError, address signer)
    {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            // Invalid signature `s` value - return isError = true and signer = address(0) to check EIP-1271
            return (true, address(0));
        }

        signer = ecrecover(digest, v, r, s);
        isError = (signer == address(0));
    }

    /**
     * @notice A gas efficient, and fallback-safe way to call the isValidSignature function for EIP-1271.
     *
     * @param signer     The EIP-1271 signer to call to check for a valid signature.
     * @param hash       The hash digest to verify with the EIP-1271 signer.
     * @param signature  The supplied signature to verify.
     *
     * @return isValid   True if the EIP-1271 signer returns the EIP-1271 magic value.
     */
    function _safeIsValidSignature(address signer, bytes32 hash, bytes calldata signature)
        internal
        view
        returns (bool isValid)
    {
        assembly {
            function _callIsValidSignature(_signer, _hash, _signatureOffset, _signatureLength) -> _isValid {
                let ptr := mload(0x40)
                // store isValidSignature(bytes32,bytes) selector
                mstore(ptr, hex"1626ba7e")
                // store bytes32 hash value in abi encoded location
                mstore(add(ptr, 0x04), _hash)
                // store abi encoded location of the bytes signature data
                mstore(add(ptr, 0x24), 0x40)
                // store bytes signature length
                mstore(add(ptr, 0x44), _signatureLength)
                // copy calldata bytes signature to memory
                calldatacopy(add(ptr, 0x64), _signatureOffset, _signatureLength)
                // calculate data length based on abi encoded data with rounded up signature length
                let dataLength := add(0x64, and(add(_signatureLength, 0x1F), not(0x1F)))
                // update free memory pointer
                mstore(0x40, add(ptr, dataLength))

                // static call _signer with abi encoded data
                // skip return data check if call failed or return data size is not at least 32 bytes
                if and(iszero(lt(returndatasize(), 0x20)), staticcall(gas(), _signer, ptr, dataLength, 0x00, 0x20)) {
                    // check if return data is equal to isValidSignature magic value
                    _isValid := eq(mload(0x00), hex"1626ba7e")
                    leave
                }
            }
            isValid := _callIsValidSignature(signer, hash, signature.offset, signature.length)
        }
    }

    /**
     * =================================================
     * ===================== Hooks =====================
     * =================================================
     */

    /**
     * @dev    This function is empty by default. Override it to add additional logic after the approval transfer.
     * @dev    The function returns a boolean value instead of reverting to indicate if there is an error for more granular control in inheriting protocols.
     */
    function _beforeTransferFrom(
        uint256 tokenType,
        address token,
        address owner,
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual returns (bool isError) {}

    /**
     * =================================================
     * ==================== Internal ===================
     * =================================================
     */

    /**
     * @notice Checks if an advanced permit typehash has been registered with PermitC
     *
     * @dev    Throws when the typehash has not been registered
     *
     * @param advancedPermitHash  The permit typehash to check
     */
    function _requireTransferAdvancedPermitHashIsRegistered(bytes32 advancedPermitHash) internal view {
        if (!_registeredTransferHashes[advancedPermitHash]) {
            revert PermitC__SignatureTransferPermitHashNotRegistered();
        }
    }

    /**
     * @notice Checks if an advanced permit typehash has been registered with PermitC
     *
     * @dev    Throws when the typehash has not been registered
     *
     * @param advancedPermitHash  The permit typehash to check
     */
    function _requireOrderAdvancedPermitHashIsRegistered(bytes32 advancedPermitHash) internal view {
        if (!_registeredOrderHashes[advancedPermitHash]) {
            revert PermitC__SignatureTransferPermitHashNotRegistered();
        }
    }

    /**
     * @notice  Invalidates an account nonce if it has not been previously used
     *
     * @dev     Throws when the nonce was previously used
     *
     * @param account  The account to invalidate the nonce of
     * @param nonce    The nonce to invalidate
     */
    function _checkAndInvalidateNonce(address account, uint256 nonce) internal {
        unchecked {
            if (
                uint256(_unorderedNonces[account][uint248(nonce >> 8)] ^= (ONE << uint8(nonce))) & (ONE << uint8(nonce))
                    == ZERO
            ) {
                revert PermitC__NonceAlreadyUsedOrRevoked();
            }
        }
    }

    /**
     * @notice Checks an approval to ensure it is sufficient for the `amount` to send
     *
     * @dev    Throws when the approval is expired
     * @dev    Throws when the approved amount is insufficient
     *
     * @param owner            The owner of the token
     * @param tokenType        The type of token
     * @param token            The address of the token
     * @param id               The id of the token
     * @param amount           The amount to deduct from the approval
     * @param zeroOutApproval  True if the approval should be set to zero
     *
     * @return approval  Storage pointer for the approval data
     */
    function _checkAndUpdateApproval(
        address owner,
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 amount,
        bool zeroOutApproval
    ) internal returns (PackedApproval storage approval) {
        approval = _getPackedApprovalPtr(_transferApprovals, owner, tokenType, token, id, ZERO_BYTES32, msg.sender);

        if (approval.expiration < block.timestamp) {
            revert PermitC__ApprovalTransferPermitExpiredOrUnset();
        }
        if (approval.amount < amount) {
            revert PermitC__ApprovalTransferExceededPermittedAmount();
        }

        if (zeroOutApproval) {
            approval.amount = 0;
        } else if (approval.amount < type(uint200).max) {
            unchecked {
                approval.amount -= uint200(amount);
            }
        }
    }

    /**
     * @notice  Gets the storage pointer for an approval
     *
     * @param _approvals  The mapping to retrieve the approval from
     * @param account     The account the approval is from
     * @param tokenType   The type of token the approval is for
     * @param token       The address of the token
     * @param id          The id of the token
     * @param orderId     The order id for the approval
     * @param operator    The operator for the approval
     *
     * @return approval  Storage pointer for the approval data
     */
    function _getPackedApprovalPtr(
        mapping(bytes32 => mapping(address => PackedApproval)) storage _approvals,
        address account,
        uint256 tokenType,
        address token,
        uint256 id,
        bytes32 orderId,
        address operator
    ) internal view returns (PackedApproval storage approval) {
        approval = _approvals[_getPackedApprovalKey(account, tokenType, token, id, orderId)][operator];
    }

    /**
     * @notice  Gets the storage key for the mapping for a specific approval
     *
     * @param owner      The owner of the token
     * @param tokenType  The type of token
     * @param token      The address of the token
     * @param id         The id of the token
     * @param orderId    The order id of the approval
     *
     * @return key  The key value to use to access the approval in the mapping
     */
    function _getPackedApprovalKey(address owner, uint256 tokenType, address token, uint256 id, bytes32 orderId)
        internal
        view
        returns (bytes32 key)
    {
        key = keccak256(abi.encode(owner, tokenType, token, id, orderId, _masterNonces[owner]));
    }

    /**
     * @notice Checks the permit approval for a single use permit without additional data
     *
     * @dev    Throws when the `nonce` has already been consumed
     * @dev    Throws when the permit amount is less than the transfer amount
     * @dev    Throws when the permit is expired
     * @dev    Throws when the signature is invalid
     *
     * @param tokenType       The type of token
     * @param token           The address of the token
     * @param id              The id of the token
     * @param permitAmount    The amount authorized by the owner signature
     * @param nonce           The nonce of the permit
     * @param expiration      The time the permit expires
     * @param owner           The owner of the token
     * @param transferAmount  The amount of tokens requested to transfer
     * @param signedPermit    The signature for the permit
     */
    function _checkPermitApproval(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 permitAmount,
        uint256 nonce,
        uint256 expiration,
        address owner,
        uint256 transferAmount,
        bytes calldata signedPermit
    ) internal {
        bytes32 digest = _hashTypedDataV4(
            PermitHash.hashSingleUsePermit(tokenType, token, id, permitAmount, nonce, expiration, _masterNonces[owner])
        );

        _checkPermitData(nonce, expiration, transferAmount, permitAmount, owner, digest, signedPermit);
    }

    /**
     * @notice  Overload of `_checkPermitApprovalWithAdditionalData` to supply TOKEN_TYPE_ERC1155
     *
     * @dev     Prevents stack too deep in `permitTransferFromWithAdditionalDataERC1155`
     * @dev     Throws when the `nonce` has already been consumed
     * @dev     Throws when the permit amount is less than the transfer amount
     * @dev     Throws when the permit is expired
     * @dev     Throws when the signature is invalid
     *
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param permitAmount        The amount authorized by the owner signature
     * @param nonce               The nonce of the permit
     * @param expiration          The time the permit expires
     * @param owner               The owner of the token
     * @param transferAmount      The amount of tokens requested to transfer
     * @param signedPermit        The signature for the permit
     * @param additionalData      The additional data to validate with the permit signature
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     */
    function _checkPermitApprovalWithAdditionalDataERC1155(
        address token,
        uint256 id,
        uint256 permitAmount,
        uint256 nonce,
        uint256 expiration,
        address owner,
        uint256 transferAmount,
        bytes calldata signedPermit,
        bytes32 additionalData,
        bytes32 advancedPermitHash
    ) internal {
        _checkPermitApprovalWithAdditionalData(
            TOKEN_TYPE_ERC1155,
            token,
            id,
            permitAmount,
            nonce,
            expiration,
            owner,
            transferAmount,
            signedPermit,
            additionalData,
            advancedPermitHash
        );
    }

    /**
     * @notice  Overload of `_checkPermitApprovalWithAdditionalData` to supply TOKEN_TYPE_ERC20
     *
     * @dev     Prevents stack too deep in `permitTransferFromWithAdditionalDataERC220`
     * @dev     Throws when the `nonce` has already been consumed
     * @dev     Throws when the permit amount is less than the transfer amount
     * @dev     Throws when the permit is expired
     * @dev     Throws when the signature is invalid
     *
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param permitAmount        The amount authorized by the owner signature
     * @param nonce               The nonce of the permit
     * @param expiration          The time the permit expires
     * @param owner               The owner of the token
     * @param transferAmount      The amount of tokens requested to transfer
     * @param signedPermit        The signature for the permit
     * @param additionalData      The additional data to validate with the permit signature
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     */
    function _checkPermitApprovalWithAdditionalDataERC20(
        address token,
        uint256 id,
        uint256 permitAmount,
        uint256 nonce,
        uint256 expiration,
        address owner,
        uint256 transferAmount,
        bytes calldata signedPermit,
        bytes32 additionalData,
        bytes32 advancedPermitHash
    ) internal {
        _checkPermitApprovalWithAdditionalData(
            TOKEN_TYPE_ERC20,
            token,
            id,
            permitAmount,
            nonce,
            expiration,
            owner,
            transferAmount,
            signedPermit,
            additionalData,
            advancedPermitHash
        );
    }

    /**
     * @notice  Overload of `_checkPermitApprovalWithAdditionalData` to supply TOKEN_TYPE_ERC721
     *
     * @dev     Prevents stack too deep in `permitTransferFromWithAdditionalDataERC721`
     * @dev     Throws when the `nonce` has already been consumed
     * @dev     Throws when the permit amount is less than the transfer amount
     * @dev     Throws when the permit is expired
     * @dev     Throws when the signature is invalid
     *
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param permitAmount        The amount authorized by the owner signature
     * @param nonce               The nonce of the permit
     * @param expiration          The time the permit expires
     * @param owner               The owner of the token
     * @param transferAmount      The amount of tokens requested to transfer
     * @param signedPermit        The signature for the permit
     * @param additionalData      The additional data to validate with the permit signature
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     */
    function _checkPermitApprovalWithAdditionalDataERC721(
        address token,
        uint256 id,
        uint256 permitAmount,
        uint256 nonce,
        uint256 expiration,
        address owner,
        uint256 transferAmount,
        bytes calldata signedPermit,
        bytes32 additionalData,
        bytes32 advancedPermitHash
    ) internal {
        _checkPermitApprovalWithAdditionalData(
            TOKEN_TYPE_ERC721,
            token,
            id,
            permitAmount,
            nonce,
            expiration,
            owner,
            transferAmount,
            signedPermit,
            additionalData,
            advancedPermitHash
        );
    }

    /**
     * @notice Checks the permit approval for a single use permit with additional data
     *
     * @dev    Throws when the `nonce` has already been consumed
     * @dev    Throws when the permit amount is less than the transfer amount
     * @dev    Throws when the permit is expired
     * @dev    Throws when the signature is invalid
     *
     * @param tokenType           The type of token
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param permitAmount        The amount authorized by the owner signature
     * @param nonce               The nonce of the permit
     * @param expiration          The time the permit expires
     * @param owner               The owner of the token
     * @param transferAmount      The amount of tokens requested to transfer
     * @param signedPermit        The signature for the permit
     * @param additionalData      The additional data to validate with the permit signature
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     */
    function _checkPermitApprovalWithAdditionalData(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 permitAmount,
        uint256 nonce,
        uint256 expiration,
        address owner,
        uint256 transferAmount,
        bytes calldata signedPermit,
        bytes32 additionalData,
        bytes32 advancedPermitHash
    ) internal {
        bytes32 digest = _getAdvancedTypedDataV4PermitHash(
            tokenType, token, id, permitAmount, owner, nonce, expiration, additionalData, advancedPermitHash
        );

        _checkPermitData(nonce, expiration, transferAmount, permitAmount, owner, digest, signedPermit);
    }

    /**
     * @notice  Checks that a single use permit has not expired, was authorized for the amount
     * @notice  being transferred, has a valid nonce and has a valid signature.
     *
     * @dev    Throws when the `nonce` has already been consumed
     * @dev    Throws when the permit amount is less than the transfer amount
     * @dev    Throws when the permit is expired
     * @dev    Throws when the signature is invalid
     *
     * @param nonce           The nonce of the permit
     * @param expiration      The time the permit expires
     * @param transferAmount  The amount of tokens requested to transfer
     * @param permitAmount    The amount authorized by the owner signature
     * @param owner           The owner of the token
     * @param digest          The digest that was signed by the owner
     * @param signedPermit    The signature for the permit
     */
    function _checkPermitData(
        uint256 nonce,
        uint256 expiration,
        uint256 transferAmount,
        uint256 permitAmount,
        address owner,
        bytes32 digest,
        bytes calldata signedPermit
    ) internal {
        if (block.timestamp > expiration) {
            revert PermitC__SignatureTransferExceededPermitExpired();
        }

        if (transferAmount > permitAmount) {
            revert PermitC__SignatureTransferExceededPermittedAmount();
        }

        _checkAndInvalidateNonce(owner, nonce);
        _verifyPermitSignature(digest, signedPermit, owner);
    }

    /**
     * @notice  Stores an approval for future use by `operator` to move tokens on behalf of `owner`
     *
     * @param tokenType           The type of token
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param amount              The amount authorized by the owner
     * @param expiration          The time the permit expires
     * @param owner               The owner of the token
     * @param operator            The account allowed to transfer the tokens
     */
    function _storeApproval(
        uint256 tokenType,
        address token,
        uint256 id,
        uint200 amount,
        uint48 expiration,
        address owner,
        address operator
    ) internal {
        PackedApproval storage approval =
            _getPackedApprovalPtr(_transferApprovals, owner, tokenType, token, id, ZERO_BYTES32, operator);

        approval.expiration = expiration;
        approval.amount = amount;

        emit Approval(owner, token, operator, id, amount, expiration);
    }

    /**
     * @notice  Overload of `_checkOrderTransfer` to supply TOKEN_TYPE_ERC1155
     *
     * @dev     Prevents stack too deep in `fillPermittedOrderERC1155`
     * @dev     Throws when the order start amount is greater than type(uint200).max
     * @dev     Throws when the order status is not open
     * @dev     Throws when the signature is invalid
     * @dev     Throws when the permit is expired
     *
     * @param signedPermit        The signature for the permit
     * @param orderFillAmounts    A struct containing the order start, requested fill and minimum fill amounts
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param owner               The owner of the token
     * @param salt                The salt value for the permit
     * @param expiration          The time the permit expires
     * @param orderId             The order id for the permit
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     *
     * @return orderStatus  Storage pointer for the approval data
     */
    function _checkOrderTransferERC1155(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        uint256 id,
        address owner,
        uint256 salt,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) internal returns (PackedApproval storage orderStatus) {
        orderStatus = _checkOrderTransfer(
            signedPermit,
            orderFillAmounts,
            TOKEN_TYPE_ERC1155,
            token,
            id,
            owner,
            salt,
            expiration,
            orderId,
            advancedPermitHash
        );
    }

    /**
     * @notice  Overload of `_checkOrderTransfer` to supply TOKEN_TYPE_ERC20
     *
     * @dev     Prevents stack too deep in `fillPermittedOrderERC20`
     * @dev     Throws when the order start amount is greater than type(uint200).max
     * @dev     Throws when the order status is not open
     * @dev     Throws when the signature is invalid
     * @dev     Throws when the permit is expired
     *
     * @param signedPermit        The signature for the permit
     * @param orderFillAmounts    A struct containing the order start, requested fill and minimum fill amounts
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param owner               The owner of the token
     * @param salt                The salt value for the permit
     * @param expiration          The time the permit expires
     * @param orderId             The order id for the permit
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     *
     * @return orderStatus  Storage pointer for the approval data
     */
    function _checkOrderTransferERC20(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        uint256 id,
        address owner,
        uint256 salt,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) internal returns (PackedApproval storage orderStatus) {
        orderStatus = _checkOrderTransfer(
            signedPermit,
            orderFillAmounts,
            TOKEN_TYPE_ERC20,
            token,
            id,
            owner,
            salt,
            expiration,
            orderId,
            advancedPermitHash
        );
    }

    /**
     * @notice  Validates an order transfer to check order start amount, status, signature if not previously
     * @notice  opened, and expiration.
     *
     * @dev     Throws when the order start amount is greater than type(uint200).max
     * @dev     Throws when the order status is not open
     * @dev     Throws when the signature is invalid
     * @dev     Throws when the permit is expired
     *
     * @param signedPermit        The signature for the permit
     * @param orderFillAmounts    A struct containing the order start, requested fill and minimum fill amounts
     * @param tokenType           The type of token
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param owner               The owner of the token
     * @param salt                The salt value for the permit
     * @param expiration          The time the permit expires
     * @param orderId             The order id for the permit
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     *
     * @return orderStatus  Storage pointer for the approval data
     */
    function _checkOrderTransfer(
        bytes calldata signedPermit,
        OrderFillAmounts calldata orderFillAmounts,
        uint256 tokenType,
        address token,
        uint256 id,
        address owner,
        uint256 salt,
        uint48 expiration,
        bytes32 orderId,
        bytes32 advancedPermitHash
    ) internal returns (PackedApproval storage orderStatus) {
        if (orderFillAmounts.orderStartAmount > type(uint200).max) {
            revert PermitC__AmountExceedsStorageMaximum();
        }

        orderStatus = _getPackedApprovalPtr(_orderApprovals, owner, tokenType, token, id, orderId, msg.sender);

        if (orderStatus.state == ORDER_STATE_OPEN) {
            if (orderStatus.amount == 0) {
                _verifyPermitSignature(
                    _getAdvancedTypedDataV4PermitHash(
                        tokenType,
                        token,
                        id,
                        orderFillAmounts.orderStartAmount,
                        owner,
                        salt,
                        expiration,
                        orderId,
                        advancedPermitHash
                    ),
                    signedPermit,
                    owner
                );

                orderStatus.amount = uint200(orderFillAmounts.orderStartAmount);
                orderStatus.expiration = expiration;
                emit OrderOpened(orderId, owner, msg.sender, orderFillAmounts.orderStartAmount);
            }

            if (block.timestamp > orderStatus.expiration) {
                revert PermitC__SignatureTransferExceededPermitExpired();
            }
        } else {
            revert PermitC__OrderIsEitherCancelledOrFilled();
        }
    }

    /**
     * @notice  Checks the order fill amounts against approval data and transfers tokens, updates
     * @notice  approval if the fill results in the order being closed.
     *
     * @dev     Throws when the amount to fill is less than the minimum fill amount
     *
     * @param orderStatus         Storage pointer for the approval data
     * @param orderFillAmounts    A struct containing the order start, requested fill and minimum fill amounts
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param owner               The owner of the token
     * @param to                  The address to send the tokens to
     * @param orderId             The order id for the permit
     * @param _transferFrom       Function pointer of the transfer function to send tokens with
     *
     * @return quantityFilled     The number of tokens filled in the order
     * @return isError            True if there was an error transferring tokens, false otherwise
     */
    function _orderTransfer(
        PackedApproval storage orderStatus,
        OrderFillAmounts calldata orderFillAmounts,
        address token,
        uint256 id,
        address owner,
        address to,
        bytes32 orderId,
        function (address, address, address, uint256, uint256) internal returns (bool) _transferFrom
    ) internal returns (uint256 quantityFilled, bool isError) {
        quantityFilled = orderFillAmounts.requestedFillAmount;

        if (quantityFilled > orderStatus.amount) {
            quantityFilled = orderStatus.amount;
        }

        if (quantityFilled < orderFillAmounts.minimumFillAmount) {
            revert PermitC__UnableToFillMinimumRequestedQuantity();
        }

        unchecked {
            orderStatus.amount -= uint200(quantityFilled);
            emit OrderFilled(orderId, owner, msg.sender, quantityFilled);
        }

        if (orderStatus.amount == 0) {
            orderStatus.state = ORDER_STATE_FILLED;
            emit OrderClosed(orderId, owner, msg.sender, false);
        }

        isError = _transferFrom(token, owner, to, id, quantityFilled);
    }

    /**
     * @notice  Restores an account's nonce when a transfer was not successful
     *
     * @dev     Throws when the nonce was not already consumed
     *
     * @param account  The account to restore the nonce of
     * @param nonce    The nonce to restore
     */
    function _restoreNonce(address account, uint256 nonce) internal {
        unchecked {
            if (
                uint256(_unorderedNonces[account][uint248(nonce >> 8)] ^= (ONE << uint8(nonce))) & (ONE << uint8(nonce))
                    != ZERO
            ) {
                revert PermitC__NonceNotUsedOrRevoked();
            }
        }
    }

    /**
     * @notice  Restores an approval amount when a transfer was not successful
     *
     * @param approval        Storage pointer for the approval data
     * @param owner           The owner of the tokens
     * @param orderId         The order id to restore approval amount on
     * @param unfilledAmount  The amount that was not filled on the order
     * @param isOrderPermit   True if the fill restoration is for an permit order
     */
    function _restoreFillableItems(
        PackedApproval storage approval,
        address owner,
        bytes32 orderId,
        uint256 unfilledAmount,
        bool isOrderPermit
    ) internal {
        if (unfilledAmount > 0) {
            if (isOrderPermit) {
                // Order permits always deduct amount and must be restored
                unchecked {
                    approval.amount += uint200(unfilledAmount);
                }

                approval.state = ORDER_STATE_OPEN;
                emit OrderRestored(orderId, owner, unfilledAmount);
            } else if (approval.amount < type(uint200).max) {
                // Stored approvals only deduct amount
                unchecked {
                    approval.amount += uint200(unfilledAmount);
                }
            }
        }
    }

    function _requireValidTokenType(uint256 tokenType) internal pure {
        if (!(tokenType == TOKEN_TYPE_ERC721 || tokenType == TOKEN_TYPE_ERC1155 || tokenType == TOKEN_TYPE_ERC20)) {
            revert PermitC__InvalidTokenType();
        }
    }

    /**
     * @notice  Generates an EIP-712 digest for a permit
     *
     * @param tokenType           The type of token
     * @param token               The address of the token
     * @param id                  The id of the token
     * @param amount              The amount authorized by the owner signature
     * @param owner               The owner of the token
     * @param nonce               The nonce for the permit
     * @param expiration          The time the permit expires
     * @param additionalData      The additional data to validate with the permit signature
     * @param advancedPermitHash  The typehash of the permit to use for validating the signature
     *
     * @return digest  The EIP-712 digest of the permit data
     */
    function _getAdvancedTypedDataV4PermitHash(
        uint256 tokenType,
        address token,
        uint256 id,
        uint256 amount,
        address owner,
        uint256 nonce,
        uint256 expiration,
        bytes32 additionalData,
        bytes32 advancedPermitHash
    ) internal view returns (bytes32 digest) {
        // cache masterNonce on stack to avoid stack too deep
        uint256 masterNonce_ = _masterNonces[owner];
        digest = _hashTypedDataV4(
            PermitHash.hashSingleUsePermitWithAdditionalData(
                tokenType, token, id, amount, nonce, expiration, additionalData, advancedPermitHash, masterNonce_
            )
        );
    }

    /**
     * @notice  Returns the current allowed amount and expiration for a stored permit
     *
     * @dev     Returns zero allowed if the permit has expired
     *
     * @param _approvals  The mapping to retrieve the approval from
     * @param owner       The account the approval is from
     * @param operator    The operator for the approval
     * @param tokenType   The type of token the approval is for
     * @param token       The address of the token
     * @param id          The id of the token
     * @param orderId     The order id for the approval
     *
     * @return allowedAmount  The amount authorized by the approval, zero if the permit has expired
     * @return expiration     The expiration of the approval
     */
    function _allowance(
        mapping(bytes32 => mapping(address => PackedApproval)) storage _approvals,
        address owner,
        address operator,
        uint256 tokenType,
        address token,
        uint256 id,
        bytes32 orderId
    ) internal view returns (uint256 allowedAmount, uint256 expiration) {
        PackedApproval storage allowed =
            _getPackedApprovalPtr(_approvals, owner, tokenType, token, id, orderId, operator);
        allowedAmount = allowed.expiration < block.timestamp ? 0 : allowed.amount;
        expiration = allowed.expiration;
    }

    /**
     * @notice  Allows the owner of the PermitC contract to access pausable admin functions
     *
     * @dev     May be overriden by an inheriting contract to provide alternative permission structure
     */
    function _requireCallerHasPausePermissions() internal view virtual override {
        _checkOwner();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IPearlmit {
    struct SignatureApproval {
        uint256 tokenType; // 20 = ERC20, 721 = ERC721, 1155 = ERC1155.
        address token; // Address of the token.
        uint256 id; // ID of the token (0 if ERC20).
        uint200 amount; // Amount of the token (0 if ERC721).
        address operator; // Address of the operator to transfer the tokens to.
    }

    struct PermitBatchTransferFrom {
        SignatureApproval[] approvals; // Array of SignatureApproval structs.
        address owner; // Address of the owner of the tokens.
        uint256 nonce; // Nonce of the owner.
        uint48 sigDeadline; // Deadline for the signature.
        uint256 masterNonce; // Master nonce of the owner.
        bytes signedPermit; // Signature of the permit. (Not present in the TYPEHASH)
        address executor; // Address of the allowed executor of the permit.
        // In the case of Tapioca, it'll be the `msg.sender` from src chain, checked against `TOE` trusted `srcChainSender`.
        bytes32 hashedData; // Hashed data that comes with the permit execution. See more in Pearlmit.sol.
    }

    function approve(uint256 tokenType, address token, uint256 id, address operator, uint200 amount, uint48 expiration)
        external;

    function allowance(address owner, address operator, uint256 tokenType, address token, uint256 id)
        external
        view
        returns (uint256 allowedAmount, uint256 expiration);

    function clearAllowance(address owner, uint256 tokenType, address token, uint256 id) external;

    function permitBatchTransferFrom(PermitBatchTransferFrom calldata batch, bytes32 hashedData)
        external
        returns (bool[] memory errorStatus);

    function permitBatchApprove(PermitBatchTransferFrom calldata batch, bytes32 hashedData) external;

    function transferFromERC1155(address owner, address to, address token, uint256 id, uint256 amount)
        external
        returns (bool isError);

    function transferFromERC20(address owner, address to, address token, uint256 amount)
        external
        returns (bool isError);

    function transferFromERC721(address owner, address to, address token, uint256 id) external returns (bool isError);
}