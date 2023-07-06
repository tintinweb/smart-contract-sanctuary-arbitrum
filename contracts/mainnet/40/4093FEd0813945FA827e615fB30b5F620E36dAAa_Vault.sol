// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity ^0.8.17;

import {IVault} from "src/interfaces/IVault.sol";
import {BytesCheck} from "src/libraries/BytesCheck.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IOperator} from "src/storage/interfaces/IOperator.sol";

library Generate {

    /// @notice deploys a new clone of `StvAccount`
    /// @param commands command to make sure the type of financial instrument
    /// @param data encoded params to create the stv
    /// @param manager address of the manager
    /// @param operator address of the operator
    /// @param maxFundraisingPeriod max fundraising period for an stv
    function generate(
        uint256 commands,
        bytes calldata data,
        address manager,
        address operator,
        uint40 maxFundraisingPeriod
    ) external returns (IVault.StvInfo memory stv, bytes32 metadataHash) {
        address stvAccountImplementation = IOperator(operator).getAddress("STVACCOUNT");
        address contractAddress;

        // generates new contract for perpetual protocols
        if (BytesCheck.checkFirstDigit0x0(uint8(commands))) {
            address defaultStableCoin = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
            (address tradeToken, uint32 leverage, bool tradeDirection, uint96 capacityOfStv, bytes32 _metadataHash) =
                abi.decode(data, (address, uint32, bool, uint96, bytes32));

            stv.manager = manager;
            stv.tradeToken = tradeToken;
            stv.depositToken = defaultStableCoin;
            stv.leverage = leverage;
            stv.tradeDirection = tradeDirection;
            stv.endTime = uint40(block.timestamp) + maxFundraisingPeriod;
            stv.capacityOfStv = capacityOfStv;

            bytes32 salt = keccak256(
                abi.encodePacked(
                    manager,
                    tradeToken,
                    defaultStableCoin,
                    leverage,
                    tradeDirection,
                    capacityOfStv,
                    block.timestamp,
                    block.chainid
                )
            );
            contractAddress = Clones.cloneDeterministic(stvAccountImplementation, salt);
            stv.stvId = contractAddress;
            metadataHash = _metadataHash;
        } // generates new salt for spot protocols
        else if (BytesCheck.checkFirstDigit0x1(uint8(commands))) {
            (address tradeToken, address depositToken, uint96 capacityOfStv, bytes32 _metadataHash) =
                abi.decode(data, (address, address, uint96, bytes32));

            stv.manager = manager;
            stv.tradeToken = tradeToken;
            stv.depositToken = depositToken;
            stv.leverage = 1;
            stv.tradeDirection = false;
            stv.endTime = uint40(block.timestamp) + maxFundraisingPeriod;
            stv.capacityOfStv = capacityOfStv;

            bytes32 salt = keccak256(
                abi.encodePacked(manager, tradeToken, depositToken, capacityOfStv, block.timestamp, block.chainid)
            );
            contractAddress = Clones.cloneDeterministic(stvAccountImplementation, salt);
            stv.stvId = contractAddress;
            metadataHash = _metadataHash;
        }
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IVault} from "src/interfaces/IVault.sol";

interface IStvAccount {
    function stvInfo() external view returns (IVault.StvInfo memory);
    function stvBalance() external view returns (IVault.StvBalance memory);
    function investorInfo(address investorAccount) external view returns (IVault.InvestorInfo memory);
    function investors() external view returns (address[] memory);
    function execute(address adapter, bytes calldata data) external payable;
    function createStv(IVault.StvInfo memory stv) external;
    function deposit(address investorAccount, uint96 amount, bool isFirstDeposit) external;
    function liquidate() external;
    function execute(uint96 amount, uint96 totalReceived, bool isOpen) external;
    function distribute(uint96 totalRemainingAfterDistribute, uint96 mFee, uint96 pFee) external;
    function distributeOut(bool isCancel, uint256 indexFrom, uint256 indexTo) external;
    function updateStatus(IVault.StvStatus status) external;
    function cancel() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IVault {
    /// @notice Enum to describe the trading status of the vault
    /// @dev NOT_OPENED - Not open
    /// @dev OPEN - opened position
    /// @dev CANCELLED_WITH_ZERO_RAISE - cancelled without any raise
    /// @dev CANCELLED_WITH_NO_FILL - cancelled with raise but not opening a position
    /// @dev CANCELLED_BY_MANAGER - cancelled by the manager after raising
    /// @dev DISTRIBUTED - distributed fees
    /// @dev LIQUIDATED - liquidated position
    enum StvStatus {
        NOT_OPENED,
        OPEN,
        CANCELLED_WITH_ZERO_RAISE,
        CANCELLED_WITH_NO_FILL,
        CANCELLED_BY_MANAGER,
        DISTRIBUTED,
        LIQUIDATED
    }

    struct StvInfo {
        address stvId;
        uint40 endTime;
        bool tradeDirection;
        uint32 leverage;
        StvStatus status;
        address manager;
        address tradeToken;
        uint96 capacityOfStv;
        address depositToken;
    }

    struct StvBalance {
        uint96 totalRaised;
        uint96 totalDepositTokenUsedForOpen;
        uint96 totalTradeTokenUsedForClose;
        uint96 totalReceivedAfterOpen;
        uint96 totalReceivedAfterClose;
        uint96 totalRemainingAfterDistribute;
    }

    struct InvestorInfo {
        uint96 depositAmount;
        uint96 claimedAmount;
        bool claimed;
    }

    function getQ() external view returns (address);
    function maxFundraisingPeriod() external view returns (uint40);
    function distributeOut(address stvId, bool isCancel, uint256 indexFrom, uint256 indexTo) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library BytesCheck {
    /// @notice check if the first digit of the hexadecimal value starts with `0x0`
    function checkFirstDigit0x0(uint8 x) public pure returns (bool) {
        uint8 y = uint8(x & 0xF0);
        uint8 z = y >> 4;
        return (z == 0x0);
    }

    /// @notice check if the first digit of the hexadecimal value starts with `0x1`
    function checkFirstDigit0x1(uint8 x) public pure returns (bool) {
        uint8 y = uint8(x & 0xF0);
        uint8 z = y >> 4;
        return (z == 0x1);
    }

    /// @notice check if the first digit of the hexadecimal value starts with `0x2`
    function checkFirstDigit0x2(uint8 x) public pure returns (bool) {
        uint8 y = uint8(x & 0xF0);
        uint8 z = y >> 4;
        return (z == 0x2);
    }

    /// @notice check if the first digit of the hexadecimal value starts with `0x3`
    function checkFirstDigit0x3(uint8 x) public pure returns (bool) {
        uint8 y = uint8(x & 0xF0);
        uint8 z = y >> 4;
        return (z == 0x3);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @title Commands similar to UniversalRouter
/// @notice Command Flags used to decode commands
/// @notice https://github.com/Uniswap/universal-router/blob/main/contracts/libraries/Commands.sol
library Commands {
    // Masks to extract certain bits of commands
    bytes1 internal constant FLAG_ALLOW_REVERT = 0x80;
    bytes1 internal constant COMMAND_TYPE_MASK = 0x3f;

    // Command Types. Maximum supported command at this moment is 0x3f.

    // Command Types where value >= 0x00, for Perpetuals
    uint256 constant GMX = 0x00;
    uint256 constant PERP = 0x01;
    uint256 constant CAP = 0x02;
    uint256 constant KWENTA = 0x03;
    // COMMAND_PLACEHOLDER = 0x04;
    // Future perpetual protocols can be added below

    // Command Types where value >= 0x10, for Spot
    uint256 constant UNI = 0x10;
    uint256 constant SUSHI = 0x11;
    uint256 constant ONE_INCH = 0x12;
    uint256 constant TRADER_JOE = 0x13;
    uint256 constant PANCAKE = 0x14;
    // COMMAND_PLACEHOLDER = 0x15;
    // Future spot protocols can be added below

    // Future financial services like options can be added with a value >= 0x20

    // Command Types where value >= 0x30, for trade functions
    uint256 constant CROSS_CHAIN = 0x30;
    uint256 constant MODIFY_ORDER = 0x31;
    uint256 constant CLAIM_REWARDS = 0x32;
    // COMMAND_PLACEHOLDER = 0x3d;
    // Future functions to interact with protocols can be added below
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library Errors {
    // Zero Errors
    error ZeroAmount();
    error ZeroAddress();
    error ZeroTotalRaised();
    error ZeroClaimableAmount();

    // Modifier Errors
    error NotOwner();
    error NotAdmin();
    error CallerNotVault();
    error CallerNotTrade();
    error CallerNotVaultOwner();
    error CallerNotGenerate();
    error NoAccess();
    error NotPlugin();

    // State Errors
    error BelowMinFundraisingPeriod();
    error AboveMaxFundraisingPeriod();
    error BelowMinLeverage();
    error AboveMaxLeverage();
    error BelowMinEndTime();
    error TradeTokenNotApplicable();

    // STV errors
    error StvDoesNotExist();
    error AlreadyOpened();
    error MoreThanTotalRaised();
    error MoreThanTotalReceived();
    error StvNotOpen();
    error StvNotClose();
    error ClaimNotApplicable();
    error StvStatusMismatch();

    // General Errors
    error BalanceLessThanAmount();
    error FundraisingPeriodEnded();
    error TotalRaisedMoreThanCapacity();
    error StillFundraising();
    error CommandMisMatch();
    error TradeCommandMisMatch();
    error NotInitialised();
    error Initialised();
    error LengthMismatch();
    error TransferFailed();
    error DelegateCallFailed();
    error CallFailed(bytes);
    error AccountAlreadyExists();
    error SwapFailed();
    error ExchangeDataMismatch();
    error AccountNotExists();
    error InputMismatch();

    // Protocol specific errors
    error GmxFeesMisMatch();
    error UpdateOrderRequestMisMatch();
    error CancelOrderRequestMisMatch();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IPerpTrade {
    function execute(uint256 command, bytes calldata data, bool isOpen) external payable;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IPermit2 {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(
        address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce
    );

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(
        address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration
    );

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address, address, address) external view returns (uint160, uint48, uint48);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(address token, address spender, uint48 newNonce) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title LooksRare Rewards Collector
/// @notice Implements a permissionless call to fetch LooksRare rewards earned by Universal Router users
/// and transfers them to an external rewards distributor contract
interface IRewardsCollector {
    /// @notice Fetches users' LooksRare rewards and sends them to the distributor contract
    /// @param looksRareClaim The data required by LooksRare to claim reward tokens
    function collectRewards(bytes calldata looksRareClaim) external;
}

interface IUniversalRouter is IRewardsCollector, IERC721Receiver, IERC1155Receiver {
    /// @notice Thrown when a required command has failed
    error ExecutionFailed(uint256 commandIndex, bytes message);

    /// @notice Thrown when attempting to send ETH directly to the contract
    error ETHNotAccepted();

    /// @notice Thrown when executing commands with an expired deadline
    error TransactionDeadlinePassed();

    /// @notice Thrown when attempting to execute commands and an incorrect number of inputs are provided
    error LengthMismatch();

    /// @notice Executes encoded commands along with provided inputs. Reverts if deadline has expired.
    /// @param commands A set of concatenated commands, each 1 byte in length
    /// @param inputs An array of byte strings containing abi encoded inputs for each command
    /// @param deadline The deadline by which the transaction must be executed
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable;

    /// @notice Executes encoded commands along with provided inputs.
    /// @param commands A set of concatenated commands, each 1 byte in length
    /// @param inputs An array of byte strings containing abi encoded inputs for each command
    function execute(bytes calldata commands, bytes[] calldata inputs) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IAccount {
    function execute(address adapter, bytes calldata data) external payable returns (bytes memory returnData);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IQ {
    function owner() external view returns (address);
    function admin() external view returns (address);
    function perpTrade() external view returns (address);
    function whitelistedPlugins(address) external view returns (bool);
    function defaultStableCoin() external view returns (address);
    function traderAccount(address) external view returns (address);
    function createAccount(address) external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Commands} from "src/libraries/Commands.sol";
import {Errors} from "src/libraries/Errors.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IUniversalRouter} from "src/protocols/uni/interfaces/IUniversalRouter.sol";
import {IPermit2} from "src/protocols/uni/interfaces/IPermit2.sol";
import {IUniswapV2Router02} from "src/protocols/sushi/interfaces/IUniswapV2Router02.sol";
import {Commands as UniCommands} from "test/libraries/Commands.sol";
import {BytesLib} from "test/libraries/BytesLib.sol";
import {IOperator} from "src/storage/interfaces/IOperator.sol";

library SpotTrade {
    using BytesLib for bytes;

    function uni(
        address tokenIn,
        address tokenOut,
        uint96 amountIn,
        bytes calldata commands,
        bytes[] calldata inputs,
        uint256 deadline,
        bytes memory addresses
    ) external returns (uint96) {
        (address receiver, address operator) = abi.decode(addresses, (address, address));
        address universalRouter = IOperator(operator).getAddress("UNIVERSALROUTER");
        address permit2 = IOperator(operator).getAddress("PERMIT2");
        _check(tokenIn, tokenOut, amountIn, commands, inputs, receiver);

        IERC20(tokenIn).approve(address(permit2), amountIn);
        IPermit2(permit2).approve(tokenIn, address(universalRouter), uint160(amountIn), type(uint48).max);

        uint96 balanceBeforeSwap = uint96(IERC20(tokenOut).balanceOf(receiver));
        if (deadline > 0) IUniversalRouter(universalRouter).execute(commands, inputs, deadline);
        else IUniversalRouter(universalRouter).execute(commands, inputs);
        uint96 balanceAfterSwap = uint96(IERC20(tokenOut).balanceOf(receiver));

        return balanceAfterSwap - balanceBeforeSwap;
    }

    function _check(
        address tokenIn,
        address tokenOut,
        uint96 amountIn,
        bytes calldata commands,
        bytes[] calldata inputs,
        address receiver
    ) internal pure {
        uint256 amount;
        for (uint256 i = 0; i < commands.length;) {
            bytes calldata input = inputs[i];
            // the address of the receiver should be spot when opening and trade when closing
            if (address(bytes20(input[12:32])) != receiver) revert Errors.InputMismatch();
            // since the route can be through v2 and v3, adding the swap amount for each input should be equal to the total swap amount
            amount += uint256(bytes32(input[32:64]));

            if (commands[i] == bytes1(uint8(UniCommands.V2_SWAP_EXACT_IN))) {
                address[] calldata path = input.toAddressArray(3);
                // the first address of the path should be tokenIn
                if (path[0] != tokenIn) revert Errors.InputMismatch();
                // last address of the path should be the tokenOut
                if (path[path.length - 1] != tokenOut) revert Errors.InputMismatch();
            } else if (commands[i] == bytes1(uint8(UniCommands.V3_SWAP_EXACT_IN))) {
                bytes calldata path = input.toBytes(3);
                // the first address of the path should be tokenIn
                if (address(bytes20(path[:20])) != tokenIn) revert Errors.InputMismatch();
                // last address of the path should be the tokenOut
                if (address(bytes20(path[path.length - 20:])) != tokenOut) revert Errors.InputMismatch();
            } else {
                // if its not v2 or v3, then revert
                revert Errors.CommandMisMatch();
            }
            unchecked {
                ++i;
            }
        }
        if (amount != uint256(amountIn)) revert Errors.InputMismatch();
    }

    function sushi(
        address tokenIn,
        address tokenOut,
        uint96 amountIn,
        uint256 amountOutMin,
        address receiver,
        address operator
    ) external returns (uint96) {
        address router = IOperator(operator).getAddress("SUSHIROUTER");
        IERC20(tokenIn).approve(router, amountIn);
        address[] memory tokenPath;
        address wrappedToken = IOperator(operator).getAddress("WRAPPEDTOKEN");

        if (tokenIn == wrappedToken || tokenOut == wrappedToken) {
            tokenPath = new address[](2);
            tokenPath[0] = tokenIn;
            tokenPath[1] = tokenOut;
        } else {
            tokenPath = new address[](3);
            tokenPath[0] = tokenIn;
            tokenPath[1] = wrappedToken;
            tokenPath[2] = tokenOut;
        }

        uint256[] memory amounts = IUniswapV2Router02(router).swapExactTokensForTokens(
            amountIn, amountOutMin, tokenPath, receiver, block.timestamp
        );
        uint256 length = amounts.length;

        // return the last amount received
        return uint96(amounts[length - 1]);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IOperator {
    function getAddress(string calldata adapter) external view returns (address);
    function getAddresses(string[] calldata adapters) external view returns (address[] memory);
    function getTraderAccount(address trader) external view returns (address);
    function getPlugin(address plugin) external view returns (bool);
    function getPlugins(address[] calldata plugins) external view returns (bool[] memory);
    function setAddress(string calldata adapter, address addr) external;
    function setAddresses(string[] calldata adapters, address[] calldata addresses) external;
    function setTraderAccount(address trader, address account) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract VaultEvents {
    event InitVault(address indexed operator, uint40 maxFundraisingPeriod);
    event CreateStv(
        bytes32 indexed metadataHash,
        address indexed stvId,
        address indexed manager,
        address tradeToken,
        address depositToken,
        uint40 endTime,
        bool tradeDirection,
        uint32 leverage,
        uint96 capacityOfStv
    );
    event Deposit(address indexed stvId, address indexed caller, address indexed investor, uint96 amount);
    event Liquidate(address indexed stvId, uint8 status);
    event Execute(
        address indexed stvId,
        uint96 amount,
        uint96 totalReceived,
        uint256 command,
        bytes data,
        uint256 msgValue,
        bool isIncrease
    );
    event Distribute(
        address indexed stvId,
        uint96 totalRemainingAfterDistribute,
        uint96 mFee,
        uint96 pFee,
        uint256 command,
        bytes data
    );
    event Cancel(address indexed stvId, uint8 status);
    event MaxFundraisingPeriod(uint40 maxFundraisingPeriod);
    event ClaimRewards(address indexed stvId, uint256 command, bytes indexed rewardData);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IVault} from "src/interfaces/IVault.sol";
import {Commands} from "src/libraries/Commands.sol";
import {Errors} from "src/libraries/Errors.sol";
import {IStvAccount} from "src/interfaces/IStvAccount.sol";
import {SpotTrade} from "src/SpotTrade/SpotTrade.sol";
import {IOperator} from "src/storage/interfaces/IOperator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAccount} from "src/q/interfaces/IAccount.sol";
import {IPerpTrade} from "src/PerpTrade/interfaces/IPerpTrade.sol";

library Trade {

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice execute the type of trade
    /// @param command the command of the ddex protocol from `Commands` library
    /// @param data encoded data of parameters depending on the ddex
    /// @param isOpen bool to check if the trade is an increase or a decrease trade
    /// @param operator address of the operator
    /// @return totalReceived after executing the trade
    function execute(uint256 command, bytes calldata data, bool isOpen, address operator)
        external
        returns (uint96 totalReceived)
    {
        (address stvId, uint96 amount) = _getAmountAndStvId(data);

        _getStvBalanceCheck(stvId, amount, isOpen);
        (address tokenIn, address tokenOut) = _getTokens(stvId, isOpen);
        _transferTokens(stvId, amount, isOpen, operator);

        if (command == Commands.UNI) {
            (,, bytes memory commands, bytes[] memory inputs, uint256 deadline) =
                abi.decode(data, (address, uint96, bytes, bytes[], uint256));
            bytes memory addresses = abi.encode(stvId, operator);

            totalReceived = SpotTrade.uni(tokenIn, tokenOut, amount, commands, inputs, deadline, addresses);
        } else if (command == Commands.SUSHI) {
            (,, uint256 amountOutMin) = abi.decode(data, (address, uint96, uint256));
            if (amountOutMin < 1) revert Errors.ZeroAmount();

            totalReceived = SpotTrade.sushi(tokenIn, tokenOut, amount, amountOutMin, stvId, operator);
        } else {
            revert Errors.CommandMisMatch();
        }
    }

    /// @notice distribute the fees and the remaining tokens after the stv is closed
    /// @param stvId address of the stv
    /// @param command the command of the ddex protocol from `Commands` library
    /// @param data encoded fees and exchange data
    /// @param operator address of the operator
    /// @return totalRemainingAfterDistribute amount of defaultStableCoin remaining after fees
    /// @return mFee manager fees
    /// @return pFee protocol fees
    function distribute(address stvId, uint8 command, bytes calldata data, address operator)
        external
        returns (uint96 totalRemainingAfterDistribute, uint96 mFee, uint96 pFee)
    {
        (bytes memory feesData, bytes[] memory exchangeData) = abi.decode(data, (bytes, bytes[]));
        IVault.StvInfo memory stv = IStvAccount(stvId).stvInfo();
        address defaultStableCoin = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
        uint96 depositTokenBalance = uint96(IERC20(defaultStableCoin).balanceOf(stvId));
        address stvId = stvId; // stack deep

        if (command == Commands.GMX) {
            address tradeToken = stv.tradeToken;
            uint96 tradeTokenBalance = uint96(IERC20(tradeToken).balanceOf(stvId));

            // after the position is closed from gmx, then the tokens recieved are transferred back to usdc
            if (stvId.balance > 0) _swap(stvId, uint96(stvId.balance), address(0), defaultStableCoin, exchangeData[0]);
            if (tradeTokenBalance > 0) _swap(stvId, tradeTokenBalance, tradeToken, defaultStableCoin, exchangeData[1]);
        } else if (command == Commands.KWENTA) {
            // swap from sUSD to USDC is done in PerpTrade call (withdraw all margin + swap to USDC)
            // exchangeData[0] should be "data" in PerpTrade._kwenta(bytes calldata data, bool isOpen) call
            address perpTrade = IOperator(operator).getAddress("PERPTRADE");
            IPerpTrade(perpTrade).execute(Commands.KWENTA, exchangeData[0], false);
        }
        uint96 depositTokenBalanceAfter = uint96(IERC20(defaultStableCoin).balanceOf(stvId));
        if (depositTokenBalanceAfter > depositTokenBalance) depositTokenBalance = depositTokenBalanceAfter;
        if (depositTokenBalance < 1) revert Errors.ZeroAmount();

        IVault.StvBalance memory stvBalance = IStvAccount(stvId).stvBalance();
        // TODO  to use depositTokenBalance or stvBalance.totalReceivedAfterClose ( effect on Spot/Perp ??)
        (totalRemainingAfterDistribute, mFee, pFee) = _distribute(stvBalance.totalRaised, depositTokenBalance, feesData);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice get the first two params of the encoded data which is the address and the amount
    function _getAmountAndStvId(bytes calldata data) internal pure returns (address stvId, uint96 amount) {
        assembly {
            stvId := calldataload(data.offset)
            amount := calldataload(add(data.offset, 0x20))
        }
    }

    /// @notice get the tokenIn and tokenOut for swapping
    function _getTokens(address stvId, bool isOpen) internal view returns (address tokenIn, address tokenOut) {
        IVault.StvInfo memory stv = IStvAccount(stvId).stvInfo();
        tokenIn = isOpen ? stv.depositToken : stv.tradeToken;
        tokenOut = isOpen ? stv.tradeToken : stv.depositToken;
    }

    /// @notice check the `stvBalance` before executing the trade
    function _getStvBalanceCheck(address stvId, uint96 amount, bool isOpen) internal view {
        if (!isOpen) {
            IVault.StvBalance memory stvBalance = IStvAccount(stvId).stvBalance();
            if (amount + stvBalance.totalTradeTokenUsedForClose > stvBalance.totalReceivedAfterOpen) {
                revert Errors.MoreThanTotalReceived();
            }
        }
    }

    /// @notice transfer the tokens to the `Vault` contract before executing the trade
    function _transferTokens(address stvId, uint96 amount, bool isOpen, address operator) internal {
        address vault = IOperator(operator).getAddress("VAULT");
        (address tokenIn,) = _getTokens(stvId, isOpen);
        bytes memory tradeData = abi.encodeWithSignature("transfer(address,uint256)", vault, amount);
        IStvAccount(stvId).execute(tokenIn, tradeData);
    }

    /// @notice pure function to calculate the manager and the protocol fees
    function _distribute(uint96 totalRaised, uint96 totalReceivedAfterClose, bytes memory feesData)
        internal
        pure
        returns (uint96 totalRemainingAfterDistribute, uint96 mFee, uint96 pFee)
    {
        (uint96 managerFees, uint96 protocolFees) = abi.decode(feesData, (uint96, uint96));
        if (totalReceivedAfterClose > totalRaised) {
            uint96 profits = totalReceivedAfterClose - totalRaised;
            mFee = (profits * (managerFees / 1e18)) / 100;
            pFee = (profits * (protocolFees / 1e18)) / 100;
            totalRemainingAfterDistribute = totalReceivedAfterClose - mFee - pFee;
        } else {
            totalRemainingAfterDistribute = totalReceivedAfterClose;
        }
    }

    /// @notice internal function to swap the tokens when `distribute` is called
    function _swap(address account, uint96 amount, address tokenIn, address tokenOut, bytes memory exchangeData)
        internal
    {
        (address exchangeRouter, bytes memory routerData) = abi.decode(exchangeData, (address, bytes));
        uint256 balanceBefore = IERC20(tokenOut).balanceOf(account);

        if (tokenIn != address(0)) {
            bytes memory tokenApprovalData = abi.encodeWithSignature("approve(address,uint256)", exchangeRouter, amount);
            IAccount(account).execute(tokenIn, tokenApprovalData);
        }

        IAccount(account).execute(exchangeRouter, routerData);
        // (uint256 returnAmount,) = abi.decode(returnData, (uint256, uint256));
        uint256 balanceAfter = IERC20(tokenOut).balanceOf(account);
        if (balanceAfter <= balanceBefore) revert Errors.BalanceLessThanAmount();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IVault} from "src/interfaces/IVault.sol";
import {Errors} from "src/libraries/Errors.sol";
import {BytesCheck} from "src/libraries/BytesCheck.sol";
import {VaultEvents} from "src/storage/VaultEvents.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IAccount} from "src/q/interfaces/IAccount.sol";
import {IStvAccount} from "src/interfaces/IStvAccount.sol";
import {IQ} from "src/q/interfaces/IQ.sol";
import {Generate} from "src/Generate.sol";
import {Trade} from "src/Trade.sol";
import {IOperator} from "src/storage/interfaces/IOperator.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Vault
/// @notice Contract to handle STFX logic
contract Vault is IVault, VaultEvents {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice address of the operator
    address public operator;
    /// @notice max funcraising period for an stv
    uint40 public maxFundraisingPeriod;
    /// @notice nonce variable to maintain the signature check
    uint256 public nonce;
    /// @notice domain separator for the current chain
    bytes32 public DOMAIN_SEPARATOR;
    /// @notice typehash for the current chain
    bytes32 public constant CROSS_CHAIN_TYPEHASH = keccak256("executeData(bytes memory data,uint256 nonce)");

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR/MODIFIERS
    //////////////////////////////////////////////////////////////*/

    constructor(address _operator, uint40 _maxFundraisingPeriod) {
        operator = _operator;
        maxFundraisingPeriod = _maxFundraisingPeriod;
        emit InitVault(_operator, _maxFundraisingPeriod);
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("vault")),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    modifier onlyOwner() {
        address owner = IOperator(operator).getAddress("OWNER");
        if (msg.sender != owner) revert Errors.NotOwner();
        _;
    }

    modifier onlyAdmin() {
        address admin = IOperator(operator).getAddress("ADMIN");
        if (msg.sender != admin) revert Errors.NotAdmin();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        GETTERS/SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the address of Q contract
    /// @return address q
    function getQ() external view returns (address) {
        address q = IOperator(operator).getAddress("Q");
        return q;
    }

    /// @notice Get the stv info
    /// @param stvId address of the stv
    function getStvInfo(address stvId) public view returns (StvInfo memory) {
        return IStvAccount(stvId).stvInfo();
    }

    /// @notice Get the stv's accounting details
    /// @param stvId address of the stv
    function getStvBalance(address stvId) public view returns (StvBalance memory) {
        return IStvAccount(stvId).stvBalance();
    }

    /// @notice Get the investor's details in a particular stv
    /// @param investor address of the investor
    /// @param stvId address of the stv
    function getInvestorInfo(address investor, address stvId) public view returns (InvestorInfo memory) {
        return IStvAccount(stvId).investorInfo(investor);
    }

    /// @notice Get all the addresses invested in the stv
    /// @param stvId address of the stv
    function getInvestors(address stvId) public view returns (address[] memory) {
        return IStvAccount(stvId).investors();
    }

    /// @notice Set the max fundraising period which is used when creating an stv
    /// @dev can only be called by the `owner`
    /// @param _maxFundraisingPeriod the max fundraising period in seconds
    function setMaxFundraisingPeriod(uint40 _maxFundraisingPeriod) external onlyOwner {
        if (_maxFundraisingPeriod == 0) revert Errors.ZeroAmount();
        maxFundraisingPeriod = _maxFundraisingPeriod;
        emit MaxFundraisingPeriod(_maxFundraisingPeriod);
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice creates a new stv by deploying a clone of `StvAccount` contract
    /// @dev the payload has to be signed by the `admin` before sending it as calldata
    /// @param commands get the command of the ddex protocol from `Commands` library
    /// @param data encoded data of parameters depending on the financial instrument
    /// @param signature signature from the `admin`
    /// @return stvId address of the stv
    function createStv(uint256 commands, bytes calldata data, bytes calldata signature)
        external
        returns (address stvId)
    {
        _verifyData(data, signature);
        address traderAccount = IOperator(operator).getTraderAccount(msg.sender);
        address q = IOperator(operator).getAddress("Q");
        if (traderAccount == address(0)) IQ(q).createAccount(msg.sender);
        (StvInfo memory stv, bytes32 metadataHash) =
            Generate.generate(commands, data, msg.sender, operator, maxFundraisingPeriod);
        stvId = stv.stvId;
        IStvAccount(stvId).createStv(stv);

        emit CreateStv(
            metadataHash,
            stvId,
            stv.manager,
            stv.tradeToken,
            stv.depositToken,
            stv.endTime,
            stv.tradeDirection,
            stv.leverage,
            stv.capacityOfStv
        );
    }

    /// @notice creates a new stv by deploying a clone of `StvAccount` contract
    /// @dev the payload has to be signed by the `admin` before sending it as calldata
    /// @param commands the command of the ddex protocol from `Commands` library
    /// @param data encoded data of parameters depending on the financial instrument
    /// @param token address of the token the manager wants to use to deposit
    /// @param amount amount of the token the manager wants to deposit into the stv
    /// @param exchangeData data from `1inch` API
    /// @param signature signature from the `admin`
    /// @return stvId address of the stv
    function createStvWithDeposit(
        uint256 commands,
        bytes calldata data,
        address token,
        uint96 amount,
        bytes calldata exchangeData,
        bytes calldata signature
    ) external returns (address stvId) {
        _verifyData(exchangeData, signature);
        address traderAccount = IOperator(operator).getTraderAccount(msg.sender);
        address q = IOperator(operator).getAddress("Q");
        if (traderAccount == address(0)) traderAccount = IQ(q).createAccount(msg.sender);
        (StvInfo memory stv, bytes32 metadataHash) =
            Generate.generate(commands, data, msg.sender, operator, maxFundraisingPeriod);
        stvId = stv.stvId;
        IStvAccount(stvId).createStv(stv);

        uint256 returnAmount = _swap(token, stvId, amount, exchangeData);
        IStvAccount(stvId).deposit(traderAccount, uint96(returnAmount), true);

        emit CreateStv(
            metadataHash,
            stvId,
            stv.manager,
            stv.tradeToken,
            stv.depositToken,
            stv.endTime,
            stv.tradeDirection,
            stv.leverage,
            stv.capacityOfStv
        );
        emit Deposit(stvId, msg.sender, msg.sender, uint96(returnAmount));
    }

    /// @notice deposits into the stv's contract from the trader's account contract
    /// @param stvId address of the stv
    /// @param amount amount of `defaultStableCoin` to deposit from the trader's Account contract
    function deposit(address stvId, uint96 amount) external {
        address account = IOperator(operator).getTraderAccount(msg.sender);
        StvInfo memory stv = getStvInfo(stvId);
        StvBalance memory sBalance = getStvBalance(stvId);
        InvestorInfo memory investorInfo = getInvestorInfo(account, stvId);
        address defaultStableCoin = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
        uint256 accountBalance = IERC20(defaultStableCoin).balanceOf(account);

        if (account == address(0)) revert Errors.AccountNotExists();
        if (accountBalance < amount) revert Errors.BalanceLessThanAmount();
        if (stv.manager == address(0)) revert Errors.StvDoesNotExist();
        if (uint40(block.timestamp) > stv.endTime) revert Errors.FundraisingPeriodEnded();
        if (stv.status != StvStatus.NOT_OPENED) revert Errors.AlreadyOpened();
        if (sBalance.totalRaised + amount > stv.capacityOfStv) {
            revert Errors.TotalRaisedMoreThanCapacity();
        }
        if (investorInfo.depositAmount == 0) IStvAccount(stvId).deposit(account, amount, true);
        else IStvAccount(stvId).deposit(account, amount, false);

        bytes memory transferData = abi.encodeWithSignature("transfer(address,uint256)", stvId, amount);
        IAccount(payable(account)).execute(defaultStableCoin, transferData);
        emit Deposit(stvId, msg.sender, msg.sender, amount);
    }

    /// @notice deposits into the stv's contract without an Account create
    /// @notice creates an Account contract for `to`
    /// @dev `to` can be `msg.sender` when its the investor
    /// @dev `to` can be trader's address when its called in through a crosschain protocol
    /// @param to address of the trader
    /// @param stvId address of the stv
    /// @param amount amount of the token the investor wants to deposit into the stv
    /// @param token address of the token the investor wants to use to deposit
    /// @param exchangeData data from `1inch` API
    /// @param signature signature from the `admin`
    function depositTo(
        address to,
        address stvId,
        uint96 amount,
        address token,
        bytes memory exchangeData,
        bytes calldata signature
    ) external payable {
        _verifyData(exchangeData, signature);
        address account = IOperator(operator).getTraderAccount(to);
        address q = IOperator(operator).getAddress("Q");
        if (account == address(0)) account = IQ(q).createAccount(to);

        StvInfo memory stv = getStvInfo(stvId);
        StvBalance memory sBalance = getStvBalance(stvId);
        InvestorInfo memory investorInfo = getInvestorInfo(account, stvId);

        if (token == address(0)) {
            if (msg.value != amount) revert Errors.InputMismatch();
        } else {
            uint256 accountBalance = IERC20(token).balanceOf(msg.sender);
            if (amount > accountBalance) revert Errors.BalanceLessThanAmount();
        }

        if (stv.manager == address(0)) revert Errors.StvDoesNotExist();
        if (uint40(block.timestamp) > stv.endTime) revert Errors.FundraisingPeriodEnded();
        if (stv.status != StvStatus.NOT_OPENED) revert Errors.AlreadyOpened();
        if (sBalance.totalRaised + amount > stv.capacityOfStv) {
            revert Errors.TotalRaisedMoreThanCapacity();
        }

        amount = uint96(_swap(token, stvId, amount, exchangeData));
        if (investorInfo.depositAmount == 0) IStvAccount(stvId).deposit(account, amount, true);
        else IStvAccount(stvId).deposit(account, amount, false);

        emit Deposit(stvId, msg.sender, to, amount);
    }

    /// @notice changes the status of the stv to `LIQUIDATED`
    /// @dev can only be called by the `admin`
    /// @param stvId address of the stv
    function liquidate(address stvId) external onlyAdmin {
        IStvAccount(stvId).liquidate();
        emit Liquidate(stvId, uint8(IVault.StvStatus.LIQUIDATED));
    }

    /// @notice execute the type of trade
    /// @dev `totalReceived` will be 0 for perps and will be more than 0 for spot
    /// @dev can only be called by the `admin`
    /// @param command the command of the ddex protocol from `Commands` library
    /// @param data encoded data of parameters depending on the ddex
    /// @param isOpen bool to check if its an increase or decrease trade
    /// @return totalReceived tokens received after trading a spot position
    function execute(uint256 command, bytes calldata data, bool isOpen)
        external
        payable
        onlyAdmin
        returns (uint96 totalReceived)
    {
        (address stvId, uint96 amount) = _getAmountAndStvId(data);
        StvInfo memory stv = getStvInfo(stvId);
        StvBalance memory sBalance = getStvBalance(stvId);

        if (stv.status != IVault.StvStatus.NOT_OPENED && stv.status != IVault.StvStatus.OPEN) {
            revert Errors.StvStatusMismatch();
        }
        if (isOpen) _increaseTrade(amount, sBalance);
        else _decreaseTrade(amount, sBalance, command);

        if (BytesCheck.checkFirstDigit0x0(uint8(command))) {
            address perpTrade = IOperator(operator).getAddress("PERPTRADE");
            bytes memory perpTradeData = abi.encodeWithSignature("execute(uint256,bytes,bool)", command, data, isOpen);
            (bool success,) = perpTrade.call{value: msg.value}(perpTradeData);
            if (!success) revert Errors.CallFailed(perpTradeData);
        } else if (BytesCheck.checkFirstDigit0x1(uint8(command))) {
            totalReceived = Trade.execute(command, data, isOpen, operator);
        } else {
            revert Errors.CommandMisMatch();
        }

        IStvAccount(stvId).execute(amount, totalReceived, isOpen);

        emit Execute(stvId, amount, totalReceived, command, data, msg.value, isOpen);
    }
    
    /// @notice executes many trades in a single function
    /// @dev `totalReceived` will be 0 for perps and will be more than 0 for spot
    /// @dev can only be called by the `admin`
    /// @param commands array of commands of the ddex protocol from `Commands` library
    /// @param data array of encoded data of parameters depending on the ddex
    /// @param msgValue msg.value for each command which has to be transfered when executing the position
    /// @param isOpen array of bool to check if its an increase or decrease trade
    /// @return totalReceived tokens received after trading a spot position
    function multiExecute(
        uint256[] memory commands,
        bytes[] calldata data,
        uint256[] memory msgValue,
        bool[] memory isOpen
    ) external payable onlyAdmin returns (uint96 totalReceived) {
        uint256 length = commands.length;
        if (length != data.length) revert Errors.LengthMismatch();
        if (length != msgValue.length) revert Errors.LengthMismatch();
        (address stvId,) = _getAmountAndStvId(data[0]);

        StvBalance memory sBalance = getStvBalance(stvId);
        uint256 i;
        uint96 amountReceived;

        for (; i < length;) {
            uint256 command = commands[i];
            bytes calldata tradeData = data[i];
            uint256 value = msgValue[i];
            bool openOrClose = isOpen[i];

            (, uint96 amount) = _getAmountAndStvId(tradeData);

            if (openOrClose) _increaseTrade(amount, sBalance);
            else _decreaseTrade(amount, sBalance, command);

            if (BytesCheck.checkFirstDigit0x0(uint8(command))) {
                address perpTrade = IOperator(operator).getAddress("PERPTRADE");
                bytes memory perpTradeData =
                    abi.encodeWithSignature("execute(uint256,bytes,bool)", command, tradeData, openOrClose);
                (bool success,) = perpTrade.call{value: value}(perpTradeData);
                if (!success) revert Errors.CallFailed(perpTradeData);
            } else if (BytesCheck.checkFirstDigit0x1(uint8(command))) {
                amountReceived = Trade.execute(command, tradeData, openOrClose, operator);
                totalReceived += amountReceived;
            } else {
                revert Errors.CommandMisMatch();
            }

            IStvAccount(stvId).execute(amount, amountReceived, openOrClose);
            emit Execute(stvId, amount, amountReceived, command, tradeData, value, openOrClose);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice distributes the fees to the manager and protocol and the remaining in the stv's contract to the investors
    /// @dev can only be called by the admin
    /// @param stvId address of the stv
    /// @param command command of the ddex protocol
    /// @param data encode data which includes the feeData and the exchangeData if there's a swap
    function distribute(address stvId, uint256 command, bytes calldata data) external onlyAdmin {
        StvInfo memory stv = getStvInfo(stvId);

        if (stv.status != StvStatus.OPEN) revert Errors.StvNotClose();

        (uint96 totalRemainingAfterDistribute, uint96 mFee, uint96 pFee) =
            Trade.distribute(stvId, uint8(command), data, operator);

        IStvAccount(stvId).distribute(totalRemainingAfterDistribute, mFee, pFee);

        emit Distribute(stvId, totalRemainingAfterDistribute, mFee, pFee, command, data);
    }

    /// @notice same as `distribute`, but is only called if `distribute` runs out of gas
    function distributeOut(address stvId, bool isCancel, uint256 indexFrom, uint256 indexTo) external onlyAdmin {
        IStvAccount(stvId).distributeOut(isCancel, indexFrom, indexTo);
    }

    /// @notice cancels the stv and transfers the tokens back to the investors
    /// @param stvId address of the stv
    function cancelStv(address stvId) external {
        StvInfo memory stv = getStvInfo(stvId);
        StvBalance memory sBalance = getStvBalance(stvId);
        address admin = IOperator(operator).getAddress("ADMIN");

        if (stv.status != StvStatus.NOT_OPENED) revert Errors.AlreadyOpened();
        if (msg.sender == admin) {
            if (uint40(block.timestamp) <= stv.endTime) revert Errors.BelowMinEndTime();
            if (sBalance.totalRaised == 0) {
                IStvAccount(stvId).updateStatus(StvStatus.CANCELLED_WITH_ZERO_RAISE);
            } else {
                IStvAccount(stvId).updateStatus(StvStatus.CANCELLED_WITH_NO_FILL);
            }
        } else if (msg.sender == stv.manager) {
            IStvAccount(stvId).updateStatus(StvStatus.CANCELLED_BY_MANAGER);
        } else {
            revert Errors.NoAccess();
        }

        IStvAccount(stvId).cancel();

        emit Cancel(stvId, uint8(stv.status));
    }

    /// @notice claims rewards from eligible ddex protocols
    /// @dev can only be called by the admin
    /// @param data array of encoded data to claim rewards from each ddex
    function claimStvTradingReward(
        uint256[] calldata commands, 
        bytes[] calldata data
    ) external onlyAdmin {
        address perpTrade = IOperator(operator).getAddress("PERPTRADE");
        (address stvId,) = _getAmountAndStvId(data[0]);
        uint256 i;
        for (; i < data.length;) {
            uint256 command = commands[i];
            bytes memory rewardData = data[i];
            bytes memory perpTradeData =
                    abi.encodeWithSignature("execute(uint256,bytes,bool)", command, rewardData, false);
            (bool success,) = perpTrade.call(perpTradeData);
            if (!success) revert Errors.CallFailed(perpTradeData);
            emit ClaimRewards(stvId, command, rewardData);
            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice pure function to get the first two params of the calldata
    /// @dev the first 2 params will always be the address and the amount
    function _getAmountAndStvId(bytes calldata data) internal pure returns (address stvId, uint96 amount) {
        assembly {
            stvId := calldataload(data.offset)
            amount := calldataload(add(data.offset, 0x20))
        }
    }

    /// @notice pure function to have the necessary checks when increasing position
    function _increaseTrade(uint96 amount, StvBalance memory sBalance) internal pure {
        if (sBalance.totalRaised < 1) revert Errors.ZeroTotalRaised();
        if (amount == 0) revert Errors.ZeroAmount();
        if (amount + sBalance.totalDepositTokenUsedForOpen > sBalance.totalRaised) revert Errors.MoreThanTotalRaised();
    }

    /// @notice pure function to have the necessary checks when decreasing position
    function _decreaseTrade(uint96 amount, StvBalance memory sBalance, uint256 command) internal pure {
        if (amount == 0) revert Errors.ZeroAmount();
        if (BytesCheck.checkFirstDigit0x0(uint8(command))) {
            if (sBalance.totalTradeTokenUsedForClose + amount > sBalance.totalDepositTokenUsedForOpen) {
                revert Errors.MoreThanTotalRaised();
            }
        } else if (BytesCheck.checkFirstDigit0x1(uint8(command))) {
            if (sBalance.totalTradeTokenUsedForClose + amount > sBalance.totalReceivedAfterOpen) {
                revert Errors.MoreThanTotalRaised();
            }
        }
    }

    /// @notice internal function to swap the amount of token
    /// @param token address of the token to be swapped
    /// @param to address of the receipient
    /// @param amount amount of tokens to be swapped
    /// @param exchangeData calldata to swap
    function _swap(address token, address to, uint96 amount, bytes memory exchangeData)
        internal
        returns (uint256 returnAmount)
    {
        address defaultStableCoin = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
        if (token != defaultStableCoin) {
            if (exchangeData.length == 0) revert Errors.ExchangeDataMismatch();
            (address exchangeRouter, bytes memory data) = abi.decode(exchangeData, (address, bytes));
            uint256 balanceBefore = IERC20(defaultStableCoin).balanceOf(address(this));
            (bool success, bytes memory returnData) = exchangeRouter.call{value: msg.value}(data);
            if (success) {
                (returnAmount,) = abi.decode(returnData, (uint256, uint256));
                uint256 balanceAfter = IERC20(defaultStableCoin).balanceOf(address(this));
                if (balanceAfter <= balanceBefore) revert Errors.BalanceLessThanAmount();
                IERC20(defaultStableCoin).transfer(to, returnAmount);
            } else {
                revert Errors.SwapFailed();
            }
        } else {
            if (exchangeData.length != 0) revert Errors.ExchangeDataMismatch();
            IERC20(defaultStableCoin).transferFrom(msg.sender, to, amount);
            returnAmount = amount;
        }
    }

    /// @notice internal function to verify if the calldata is signed by the `admin` or not
    /// @dev the data has to be signed by the `admin`
    function _verifyData(bytes memory data, bytes calldata signature) internal {
        bytes32 structHash = keccak256(abi.encode(CROSS_CHAIN_TYPEHASH, data, nonce++));
        bytes32 signedData = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);
        address signer = ECDSA.recover(signedData, signature);
        address admin = IOperator(operator).getAddress("ADMIN");
        if (signer != admin) revert Errors.NotAdmin();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/// @title Library for Bytes Manipulation
/// Based on Gonçalo Sá's BytesLib - but updated and heavily editted
pragma solidity ^0.8.0;

library BytesLib {
    /// @notice Returns the address starting at byte 0
    /// @dev length and overflow checks must be carried out before calling
    /// @param _bytes The input bytes string to slice
    /// @return tempAddress The address starting at byte 0
    function toAddress(bytes calldata _bytes) internal pure returns (address tempAddress) {
        assembly {
            tempAddress := shr(96, calldataload(_bytes.offset))
        }
    }

    /// @notice Returns the pool details starting at byte 0
    /// @dev length and overflow checks must be carried out before calling
    /// @param _bytes The input bytes string to slice
    /// @return token0 The address at byte 0
    /// @return fee The uint24 starting at byte 20
    /// @return token1 The address at byte 23
    function toPool(bytes calldata _bytes) internal pure returns (address token0, uint24 fee, address token1) {
        assembly {
            token0 := shr(96, calldataload(_bytes.offset))
            fee := shr(232, calldataload(add(_bytes.offset, 20)))
            token1 := shr(96, calldataload(add(_bytes.offset, 23)))
        }
    }

    /// @notice Decode the `_arg`-th element in `_bytes` as a dynamic array
    /// @dev The decoding of `length` and `offset` is universal,
    /// whereas the type declaration of `res` instructs the compiler how to read it.
    /// @param _bytes The input bytes string to slice
    /// @param _arg The index of the argument to extract
    /// @return length Length of the array
    /// @return offset Pointer to the data part of the array
    function toLengthOffset(bytes calldata _bytes, uint256 _arg)
        internal
        pure
        returns (uint256 length, uint256 offset)
    {
        assembly {
            // The offset of the `_arg`-th element is `32 * arg`, which stores the offset of the length pointer.
            let lengthPtr := add(_bytes.offset, calldataload(add(_bytes.offset, mul(0x20, _arg))))
            length := calldataload(lengthPtr)
            offset := add(lengthPtr, 0x20)
        }
    }

    /// @notice Decode the `_arg`-th element in `_bytes` as `bytes`
    /// @param _bytes The input bytes string to extract a bytes string from
    /// @param _arg The index of the argument to extract
    function toBytes(bytes calldata _bytes, uint256 _arg) internal pure returns (bytes calldata res) {
        (uint256 length, uint256 offset) = toLengthOffset(_bytes, _arg);
        assembly {
            res.length := length
            res.offset := offset
        }
    }

    /// @notice Decode the `_arg`-th element in `_bytes` as `address[]`
    /// @param _bytes The input bytes string to extract an address array from
    /// @param _arg The index of the argument to extract
    function toAddressArray(bytes calldata _bytes, uint256 _arg) internal pure returns (address[] calldata res) {
        (uint256 length, uint256 offset) = toLengthOffset(_bytes, _arg);
        assembly {
            res.length := length
            res.offset := offset
        }
    }

    /// @notice Decode the `_arg`-th element in `_bytes` as `bytes[]`
    /// @param _bytes The input bytes string to extract a bytes array from
    /// @param _arg The index of the argument to extract
    function toBytesArray(bytes calldata _bytes, uint256 _arg) internal pure returns (bytes[] calldata res) {
        (uint256 length, uint256 offset) = toLengthOffset(_bytes, _arg);
        assembly {
            res.length := length
            res.offset := offset
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/// @title Commands
/// @notice Command Flags used to decode commands
library Commands {
    // Masks to extract certain bits of commands
    bytes1 internal constant FLAG_ALLOW_REVERT = 0x80;
    bytes1 internal constant COMMAND_TYPE_MASK = 0x3f;

    // Command Types. Maximum supported command at this moment is 0x3f.

    // Command Types where value<0x08, executed in the first nested-if block
    uint256 constant V3_SWAP_EXACT_IN = 0x00;
    uint256 constant V3_SWAP_EXACT_OUT = 0x01;
    uint256 constant PERMIT2_TRANSFER_FROM = 0x02;
    uint256 constant PERMIT2_PERMIT_BATCH = 0x03;
    uint256 constant SWEEP = 0x04;
    uint256 constant TRANSFER = 0x05;
    uint256 constant PAY_PORTION = 0x06;
    // COMMAND_PLACEHOLDER = 0x07;

    // Command Types where 0x08<=value<=0x0f, executed in the second nested-if block
    uint256 constant V2_SWAP_EXACT_IN = 0x08;
    uint256 constant V2_SWAP_EXACT_OUT = 0x09;
    uint256 constant PERMIT2_PERMIT = 0x0a;
    uint256 constant WRAP_ETH = 0x0b;
    uint256 constant UNWRAP_WETH = 0x0c;
    uint256 constant PERMIT2_TRANSFER_FROM_BATCH = 0x0d;
    // COMMAND_PLACEHOLDER = 0x0e;
    // COMMAND_PLACEHOLDER = 0x0f;

    // Command Types where 0x10<=value<0x18, executed in the third nested-if block
    uint256 constant SEAPORT = 0x10;
    uint256 constant LOOKS_RARE_721 = 0x11;
    uint256 constant NFTX = 0x12;
    uint256 constant CRYPTOPUNKS = 0x13;
    uint256 constant LOOKS_RARE_1155 = 0x14;
    uint256 constant OWNER_CHECK_721 = 0x15;
    uint256 constant OWNER_CHECK_1155 = 0x16;
    uint256 constant SWEEP_ERC721 = 0x17;

    // Command Types where 0x18<=value<=0x1f, executed in the final nested-if block
    uint256 constant X2Y2_721 = 0x18;
    uint256 constant SUDOSWAP = 0x19;
    uint256 constant NFT20 = 0x1a;
    uint256 constant X2Y2_1155 = 0x1b;
    uint256 constant FOUNDATION = 0x1c;
    uint256 constant SWEEP_ERC1155 = 0x1d;
    // COMMAND_PLACEHOLDER = 0x1e
    // COMMAND_PLACEHOLDER = 0x1f

    // Command Types where 0x20<=value
    uint256 constant EXECUTE_SUB_PLAN = 0x20;
    uint256 constant SEAPORT_V2 = 0x21;
    // COMMAND_PLACEHOLDER for 0x22 to 0x3f (all unused)
}