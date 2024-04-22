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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
pragma solidity >=0.8.18;

/// @title   IAvocado
/// @notice  interface to access internal vars on-chain
interface IAvocado {
    function _avoImpl() external view returns (address);

    function _data() external view returns (uint256);

    function _owner() external view returns (address);
}

/// @title      Avocado
/// @notice     Proxy for Avocados as deployed by the AvoFactory.
///             Basic Proxy with fallback to delegate and address for implementation contract at storage 0x0
//
// @dev        If this contract changes then the deployment addresses for new Avocados through factory change too!!
//             Relayers might want to pass in version as new param then to forward to the correct factory
contract Avocado {
    /// @notice flexible immutable data slot.
    /// first 20 bytes: address owner
    /// next 4 bytes: uint32 index
    /// next 1 byte: uint8 type
    /// next 9 bytes: used flexible for use-cases found in the future
    uint256 internal immutable _data;

    /// @notice address of the Avocado logic / implementation contract. IMPORTANT: SAME STORAGE SLOT AS FOR PROXY
    //
    // @dev    _avoImpl MUST ALWAYS be the first declared variable here in the proxy and in the logic contract
    //         when upgrading, the storage at memory address 0x0 is upgraded (first slot).
    //         To reduce deployment costs this variable is internal but can still be retrieved with
    //         _avoImpl(), see code and comments in fallback below
    address internal _avoImpl;

    /// @notice   sets _avoImpl & immutable _data, fetching it from msg.sender.
    //
    // @dev      those values are not input params to not influence the deterministic Create2 address!
    constructor() {
        // "\x8c\x65\x73\x89" is hardcoded bytes of function selector for transientDeployData()
        (, bytes memory deployData_) = msg.sender.staticcall(bytes("\x8c\x65\x73\x89"));

        address impl_;
        uint256 data_;
        assembly {
            // cast first 20 bytes to version address (_avoImpl)
            impl_ := mload(add(deployData_, 0x20))

            // cast bytes in position 0x40 to uint256 data; deployData_ plus 0x40 due to padding
            data_ := mload(add(deployData_, 0x40))
        }

        _data = data_;
        _avoImpl = impl_;
    }

    /// @notice Delegates the current call to `_avoImpl` unless one of the view methods is called:
    ///         `_avoImpl()` returns the address for `_avoImpl`, `_owner()` returns the first
    ///         20 bytes of `_data`, `_data()` returns `_data`.
    //
    // @dev    Mostly based on OpenZeppelin Proxy.sol
    // logic contract must not implement a function `_avoImpl()`, `_owner()` or  `_data()`
    // as they will not be callable due to collision
    fallback() external payable {
        uint256 data_ = _data;
        assembly {
            let functionSelector_ := calldataload(0)

            // 0xb2bdfa7b = function selector for _owner()
            if eq(functionSelector_, 0xb2bdfa7b00000000000000000000000000000000000000000000000000000000) {
                // store address owner at memory address 0x0, loading only last 20 bytes through the & mask
                mstore(0, and(data_, 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff))
                return(0, 0x20) // send 32 bytes of memory slot 0 as return value
            }

            // 0x68beab3f = function selector for _data()
            if eq(functionSelector_, 0x68beab3f00000000000000000000000000000000000000000000000000000000) {
                mstore(0, data_) // store uint256 _data at memory address 0x0
                return(0, 0x20) // send 32 bytes of memory slot 0 as return value
            }

            // load address avoImpl_ from storage
            let avoImpl_ := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)

            // first 4 bytes of calldata specify which function to call.
            // if those first 4 bytes == 874095c6 (function selector for _avoImpl()) then we return the _avoImpl address
            // The value is right padded to 32-bytes with 0s
            if eq(functionSelector_, 0x874095c600000000000000000000000000000000000000000000000000000000) {
                mstore(0, avoImpl_) // store address avoImpl_ at memory address 0x0
                return(0, 0x20) // send 32 bytes of memory slot 0 as return value
            }

            // @dev code below is taken from OpenZeppelin Proxy.sol _delegate function

            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), avoImpl_, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";

import { IAvoRegistry } from "../interfaces/IAvoRegistry.sol";
import { IAvoSignersList } from "../interfaces/IAvoSignersList.sol";
import { IAvocadoMultisigV1Base } from "../interfaces/IAvocadoMultisigV1.sol";
import { IAvocadoMultisigV1Secondary } from "../interfaces/IAvocadoMultisigV1Secondary.sol";
import { IAvocado } from "../Avocado.sol";
import { IAvoConfigV1 } from "../interfaces/IAvoConfigV1.sol";
import { AvocadoMultisigBase, AvocadoMultisigCore } from "./AvocadoMultisigCore.sol";

// --------------------------- DEVELOPER NOTES -----------------------------------------
// @dev IMPORTANT: all storage variables go into AvocadoMultisigVariables.sol
// -------------------------------------------------------------------------------------

// empty interface used for Natspec docs for nice layout in automatically generated docs:
//
/// @title  AvocadoMultisig v1.1.0
/// @notice Smart wallet enabling meta transactions through multiple EIP712 signatures (Multisig n out of m).
///
/// Supports:
/// - Executing arbitrary actions
/// - Receiving NFTs (ERC721)
/// - Receiving ERC1155 tokens
/// - ERC1271 smart contract signatures
/// - Instadapp Flashloan callbacks
/// - chain-agnostic signatures, user can sign once for execution of actions on different chains.
///
/// The `cast` method allows the AvoForwarder (relayer) to execute multiple arbitrary actions authorized by signature.
///
/// Broadcasters are expected to call the AvoForwarder contract `execute()` method, which also automatically
/// deploys an AvocadoMultisig if necessary first.
///
/// Upgradeable by calling `upgradeTo` through a `cast` / `castAuthorized` call.
///
/// The `castAuthorized` method allows the signers of the wallet to execute multiple arbitrary actions with signatures
/// without the AvoForwarder in between, to guarantee the smart wallet is truly non-custodial.
///
/// _@dev Notes:_
/// - This contract implements parts of EIP-2770 in a minimized form. E.g. domainSeparator is immutable etc.
/// - This contract does not implement ERC2771, because trusting an upgradeable "forwarder" bears a security
/// risk for this non-custodial wallet.
/// - Signature related logic is based off of OpenZeppelin EIP712Upgradeable.
/// - All signatures are validated for defaultChainId of `63400` instead of `block.chainid` from opcode (EIP-1344).
/// - For replay protection, the current `block.chainid` instead is used in the EIP-712 salt.
interface AvocadoMultisig_V1 {}

/// @dev Simple contract to upgrade the implementation address stored at storage slot 0x0.
///      Mostly based on OpenZeppelin ERC1967Upgrade contract, adapted with onlySelf etc.
///      IMPORTANT: For any new implementation, the upgrade method MUST be in the implementation itself,
///      otherwise it can not be upgraded anymore!
abstract contract AvocadoMultisigSelfUpgradeable is AvocadoMultisigCore {
    /// @notice upgrade the contract to a new implementation address.
    ///         - Must be a valid version at the AvoRegistry.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param avoImplementation_       New contract address
    /// @param afterUpgradeHookData_    flexible bytes for custom usage in after upgrade hook logic
    //
    // Implementation must call `_afterUpgradeHook()`
    function upgradeTo(address avoImplementation_, bytes calldata afterUpgradeHookData_) public onlySelf {
        _spell(address(avoSecondary), msg.data);
    }

    /// @notice hook called after executing an upgrade from previous `fromImplementation_`, with flexible bytes `data_`
    function _afterUpgradeHook(address fromImplementation_, bytes calldata data_) public virtual onlySelf {}
}

abstract contract AvocadoMultisigProtected is AvocadoMultisigCore {
    /***********************************|
    |             ONLY SELF             |
    |__________________________________*/

    /// @notice occupies the sequential `avoNonces_` in storage. This can be used to cancel / invalidate
    ///         a previously signed request(s) because the nonce will be "used" up.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param  avoNonces_ sequential ascending ordered nonces to be occupied in storage.
    ///         E.g. if current AvoNonce is 77 and txs are queued with avoNonces 77, 78 and 79,
    ///         then you would submit [78, 79] here because 77 will be occupied by the tx executing
    ///         `occupyAvoNonces()` as an action itself. If executing via non-sequential nonces, you would
    ///         submit [77, 78, 79].
    ///         - Maximum array length is 5.
    ///         - gap from the current avoNonce will revert (e.g. [79, 80] if current one is 77)
    function occupyAvoNonces(uint88[] calldata avoNonces_) external onlySelf {
        _spell(address(avoSecondary), msg.data);
    }

    /// @notice occupies the `nonSequentialNonces_` in storage. This can be used to cancel / invalidate
    ///         previously signed request(s) because the nonce will be "used" up.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param  nonSequentialNonces_ the non-sequential nonces to occupy
    function occupyNonSequentialNonces(bytes32[] calldata nonSequentialNonces_) external onlySelf {
        _spell(address(avoSecondary), msg.data);
    }

    /***********************************|
    |         FLASHLOAN CALLBACK        |
    |__________________________________*/

    /// @dev                    callback used by Instadapp Flashloan Aggregator, executes operations while owning
    ///                         the flashloaned amounts. `data_` must contain actions, one of them must pay back flashloan
    // /// @param assets_       assets_ received a flashloan for
    // /// @param amounts_      flashloaned amounts for each asset
    // /// @param premiums_     fees to pay for the flashloan
    /// @param initiator_       flashloan initiator -> must be this contract
    /// @param data_            data bytes containing the `abi.encoded()` actions that are executed like in `CastParams.actions`
    function executeOperation(
        address[] calldata /*  assets_ */,
        uint256[] calldata /*  amounts_ */,
        uint256[] calldata /*  premiums_ */,
        address initiator_,
        bytes calldata data_
    ) external returns (bool) {
        // @dev using the valid case inverted via one ! to optimize gas usage
        // data_ includes id and actions
        if (
            !(_transientAllowHash ==
                bytes31(keccak256(abi.encode(data_, block.timestamp, EXECUTE_OPERATION_SELECTOR))) &&
                initiator_ == address(this))
        ) {
            revert AvocadoMultisig__Unauthorized();
        }

        // get and reset transient id
        uint256 id_ = uint256(_transientId);
        _transientId = 0;

        if (tx.origin == 0x000000000000000000000000000000000000dEaD) {
            // tx origin 0x000000000000000000000000000000000000dEaD used for backend gas estimations -> forward to simulate
            _spell(
                address(avoSecondary),
                abi.encodeCall(avoSecondary._simulateExecuteActions, (abi.decode(data_, (Action[])), id_, true))
            );
        } else {
            // decode actions to be executed after getting the flashloan and id_ packed into the data_
            _executeActions(abi.decode(data_, (Action[])), id_, true);
        }

        return true;
    }

    /***********************************|
    |         INDIRECT INTERNAL         |
    |__________________________________*/

    /// @dev             executes a low-level .call or .delegateCall on all `actions_`.
    ///                  Can only be self-called by this contract under certain conditions, essentially internal method.
    ///                  This is called like an external call to create a separate execution frame.
    ///                  This way we can revert all the `actions_` if one fails without reverting the whole transaction.
    /// @param actions_  the actions to execute (target, data, value, operation)
    /// @param id_       id for `actions_`, see `CastParams.id`
    function _callTargets(Action[] calldata actions_, uint256 id_) external payable {
        if (tx.origin == 0x000000000000000000000000000000000000dEaD) {
            // tx origin 0x000000000000000000000000000000000000dEaD used for backend gas estimations -> forward to simulate
            _spell(address(avoSecondary), abi.encodeCall(avoSecondary._simulateExecuteActions, (actions_, id_, false)));
        } else {
            // _transientAllowHash must be set
            if (
                (_transientAllowHash !=
                    bytes31(keccak256(abi.encode(actions_, id_, block.timestamp, _CALL_TARGETS_SELECTOR))))
            ) {
                revert AvocadoMultisig__Unauthorized();
            }

            _executeActions(actions_, id_, false);
        }
    }
}

abstract contract AvocadoMultisigEIP1271 is AvocadoMultisigCore {
    /// @inheritdoc IERC1271
    /// @param signature This can be one of the following:
    ///         - empty: `hash` must be a previously signed message in storage then.
    ///         - 65 bytes: owner signature for a Multisig with only owner as signer (requiredSigners = 1, signers=[owner]).
    ///         - a multiple of 85 bytes, through grouping of 65 bytes signature + 20 bytes signer address each.
    ///           To signal decoding this way, the signature bytes must be prefixed with `0xDEC0DE6520`.
    ///         - the `abi.encode` result for `SignatureParams` struct array.
    /// @dev reverts with `AvocadoMultisig__InvalidEIP1271Signature` or `AvocadoMultisig__InvalidParams` if signature is invalid.
    /// @dev input `message_` is hashed with `domainSeparatorV4()` according to EIP712 typed data (`EIP1271_TYPE_HASH`)
    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    ) external view override returns (bytes4 magicValue) {
        // hashing with domain separator mitigates any potential replaying on other networks or other Avocados of the same owner
        hash = ECDSA.toTypedDataHash(
            _domainSeparatorV4(
                DOMAIN_SEPARATOR_SALT_HASHED // includes block.chainid
            ),
            keccak256(abi.encode(EIP1271_TYPE_HASH, hash))
        );

        // @dev function params without _ for inheritdoc
        if (signature.length == 0) {
            // must be pre-allow-listed via `signMessage` method
            if (_signedMessages[hash] != 1) {
                revert AvocadoMultisig__InvalidEIP1271Signature();
            }
        } else {
            (bool validSignature_, ) = _verifySig(
                hash,
                // decode signaturesParams_ from bytes signature
                avoSecondary.decodeEIP1271Signature(signature, IAvocado(address(this))._owner()),
                // we have no way to know nonce type, so make sure validity test covers everything.
                // setting this flag true will check that the digest is not a used non-sequential nonce.
                // unfortunately, for sequential nonces it adds unneeded verification and gas cost,
                // because the check will always pass, but there is no way around it.
                true
            );
            if (!validSignature_) {
                revert AvocadoMultisig__InvalidEIP1271Signature();
            }
        }

        return EIP1271_MAGIC_VALUE;
    }

    /// @notice Marks a bytes32 `message_` (signature digest) as signed, making it verifiable by EIP-1271 `isValidSignature()`.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param message_ data hash to be allow-listed as signed
    /// @dev input `message_` is hashed with `domainSeparatorV4()` according to EIP712 typed data (`EIP1271_TYPE_HASH`)
    function signMessage(bytes32 message_) external onlySelf {
        _spell(address(avoSecondary), msg.data);
    }

    /// @notice Removes a previously `signMessage()` signed bytes32 `message_` (signature digest).
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param message_ data hash to be removed from allow-listed signatures
    function removeSignedMessage(bytes32 message_) external onlySelf {
        _spell(address(avoSecondary), msg.data);
    }
}

abstract contract AvocadoMultisigSigners is AvocadoMultisigCore {
    /// @notice adds `addSigners_` to allowed signers and sets required signers count to `requiredSigners_`
    /// Note the `addSigners_` to be added must:
    ///     - NOT be duplicates (already present in current allowed signers)
    ///     - NOT be the zero address
    ///     - be sorted ascending
    function addSigners(address[] calldata addSigners_, uint8 requiredSigners_) external onlySelf {
        _spell(address(avoSecondary), msg.data);
    }

    /// @notice removes `removeSigners_` from allowed signers and sets required signers count to `requiredSigners_`
    /// Note the `removeSigners_` to be removed must:
    ///     - NOT be the owner
    ///     - be sorted ascending
    ///     - be present in current allowed signers
    function removeSigners(address[] calldata removeSigners_, uint8 requiredSigners_) external onlySelf {
        _spell(address(avoSecondary), msg.data);
    }

    /// @notice sets number of required signers for a valid request to `requiredSigners_`
    function setRequiredSigners(uint8 requiredSigners_) external onlySelf {
        _spell(address(avoSecondary), msg.data);
    }
}

abstract contract AvocadoMultisigCast is AvocadoMultisigCore {
    /// @inheritdoc IAvocadoMultisigV1Base
    function getSigDigest(
        CastParams memory params_,
        CastForwardParams memory forwardParams_
    ) public view returns (bytes32) {
        return _getSigDigest(params_, forwardParams_);
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool) {
        _validateParams(
            params_.actions.length,
            params_.avoNonce,
            forwardParams_.validAfter,
            forwardParams_.validUntil,
            forwardParams_.value
        );

        _verifySigWithRevert(_getSigDigest(params_, forwardParams_), signaturesParams_, params_.avoNonce == -1);

        return true;
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] memory signaturesParams_
    ) external payable returns (bool success_, string memory revertReason_) {
        return _cast(params_, forwardParams_, signaturesParams_, new bytes32[](0));
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function simulateCast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] memory signaturesParams_
    ) external payable returns (bool success_, string memory revertReason_) {
        return _simulateCast(params_, forwardParams_, signaturesParams_, new bytes32[](0));
    }
}

abstract contract AvocadoMultisigCastChainAgnostic is AvocadoMultisigCore {
    /// @inheritdoc IAvocadoMultisigV1Base
    function castChainAgnostic(
        CastChainAgnosticParams calldata params_,
        SignatureParams[] memory signaturesParams_,
        bytes32[] calldata chainAgnosticHashes_
    ) external payable returns (bool success_, string memory revertReason_) {
        if (params_.chainId != block.chainid) {
            revert AvocadoMultisig__InvalidParams();
        }

        return _cast(params_.params, params_.forwardParams, signaturesParams_, chainAgnosticHashes_);
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function getChainAgnosticHashes(
        CastChainAgnosticParams[] calldata params_
    ) public pure returns (bytes32[] memory chainAgnosticHashes_) {
        uint256 length_ = params_.length;
        chainAgnosticHashes_ = new bytes32[](length_);
        for (uint256 i; i < length_; ) {
            chainAgnosticHashes_[i] = _castChainAgnosticParamsHash(
                params_[i].params,
                params_[i].forwardParams,
                params_[i].chainId
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function getSigDigestChainAgnostic(CastChainAgnosticParams[] calldata params_) public view returns (bytes32) {
        return _getSigDigestChainAgnostic(getChainAgnosticHashes(params_));
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function verifyChainAgnostic(
        CastChainAgnosticParams calldata params_,
        SignatureParams[] calldata signaturesParams_,
        bytes32[] calldata chainAgnosticHashes_
    ) public view returns (bool) {
        if (params_.chainId != block.chainid) {
            revert AvocadoMultisig__InvalidParams();
        }

        _validateParams(
            params_.params.actions.length,
            params_.params.avoNonce,
            params_.forwardParams.validAfter,
            params_.forwardParams.validUntil,
            params_.forwardParams.value
        );

        _validateChainAgnostic(
            _castChainAgnosticParamsHash(params_.params, params_.forwardParams, block.chainid),
            chainAgnosticHashes_
        );

        _verifySigWithRevert(
            _getSigDigestChainAgnostic(chainAgnosticHashes_),
            signaturesParams_,
            params_.params.avoNonce == -1
        );

        return true;
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function simulateCastChainAgnostic(
        CastChainAgnosticParams calldata params_,
        SignatureParams[] memory signaturesParams_,
        bytes32[] calldata chainAgnosticHashes_
    ) external payable returns (bool success_, string memory revertReason_) {
        if (params_.chainId != block.chainid) {
            revert AvocadoMultisig__InvalidParams();
        }

        return _simulateCast(params_.params, params_.forwardParams, signaturesParams_, chainAgnosticHashes_);
    }
}

abstract contract AvocadoMultisigCastAuthorized is AvocadoMultisigCore {
    /// @inheritdoc IAvocadoMultisigV1Base
    function getSigDigestAuthorized(
        CastParams memory params_,
        CastAuthorizedParams memory authorizedParams_
    ) public view returns (bytes32) {
        return _getSigDigestAuthorized(params_, authorizedParams_);
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function verifyAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool) {
        // make sure actions are defined and nonce is valid
        _validateParams(
            params_.actions.length,
            params_.avoNonce,
            authorizedParams_.validAfter,
            authorizedParams_.validUntil,
            0 // no value param in authorized interaction
        );

        _verifySigWithRevert(
            _getSigDigestAuthorized(params_, authorizedParams_),
            signaturesParams_,
            params_.avoNonce == -1
        );

        return true;
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] memory signaturesParams_
    ) external payable returns (bool success_, string memory revertReason_) {
        uint256 gasSnapshot_ = gasleft();

        // make sure actions are defined and nonce is valid
        _validateParams(
            params_.actions.length,
            params_.avoNonce,
            authorizedParams_.validAfter,
            authorizedParams_.validUntil,
            0 // no value param in authorized interaction
        );

        bytes32 digest_ = _getSigDigestAuthorized(params_, authorizedParams_);
        address[] memory signers_ = _verifySigWithRevert(digest_, signaturesParams_, params_.avoNonce == -1);

        (success_, revertReason_) = _executeCast(
            params_,
            _dynamicReserveGas(CAST_AUTHORIZED_RESERVE_GAS, signers_.length, params_.metadata.length),
            params_.avoNonce == -1 ? digest_ : bytes32(0)
        );

        // @dev on changes in the code below this point, measure the needed reserve gas via `gasleft()` anew
        // and update reserve gas constant amounts
        if (success_) {
            emit CastExecuted(params_.source, msg.sender, signers_, params_.metadata);
        } else {
            emit CastFailed(params_.source, msg.sender, signers_, revertReason_, params_.metadata);
        }

        // @dev `_payAuthorizedFee()` costs ~24.5k gas for if a fee is configured and maxFee is set
        _spell(
            address(avoSecondary),
            abi.encodeCall(avoSecondary.payAuthorizedFee, (gasSnapshot_, authorizedParams_.maxFee))
        );
        // @dev ending point for measuring reserve gas should be here. Also see comment in `AvocadoMultisigCore._executeCast()`
    }
}

contract AvocadoMultisig is
    AvocadoMultisigBase,
    AvocadoMultisigCore,
    AvocadoMultisigSelfUpgradeable,
    AvocadoMultisigProtected,
    AvocadoMultisigEIP1271,
    AvocadoMultisigSigners,
    AvocadoMultisigCast,
    AvocadoMultisigCastAuthorized,
    AvocadoMultisigCastChainAgnostic
{
    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    /// @notice                        constructor sets multiple immutable values for contracts and payFee fallback logic.
    /// @param avoRegistry_            address of the avoRegistry (proxy) contract
    /// @param avoForwarder_           address of the avoForwarder (proxy) contract
    ///                                to forward tx with valid signatures. must be valid version in AvoRegistry.
    /// @param avoSignersList_         address of the AvoSignersList (proxy) contract
    /// @param avoConfigV1_            AvoConfigV1 contract holding values for authorizedFee values
    /// @param secondary_              AvocadoMultisigSecondary contract for extended logic
    constructor(
        IAvoRegistry avoRegistry_,
        address avoForwarder_,
        IAvoSignersList avoSignersList_,
        IAvoConfigV1 avoConfigV1_,
        IAvocadoMultisigV1Secondary secondary_
    ) AvocadoMultisigBase(avoRegistry_, avoForwarder_, avoSignersList_, avoConfigV1_) AvocadoMultisigCore(secondary_) {}

    /// @inheritdoc IAvocadoMultisigV1Base
    function initialize() public initializer {
        _spell(address(avoSecondary), msg.data);
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    receive() external payable {}

    /// @inheritdoc IAvocadoMultisigV1Base
    function domainSeparatorV4() public view returns (bytes32) {
        return
            _domainSeparatorV4(
                DOMAIN_SEPARATOR_SALT_HASHED // includes block.chainid
            );
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function domainSeparatorV4ChainAgnostic() public view returns (bytes32) {
        return
            _domainSeparatorV4(
                DOMAIN_SEPARATOR_CHAIN_AGNOSTIC_SALT_HASHED // includes default chain id (634)
            );
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function isSigner(address signer_) public view returns (bool) {
        address[] memory allowedSigners_ = _getSigners(); // includes owner

        uint256 allowedSignersLength_ = allowedSigners_.length;
        for (uint256 i; i < allowedSignersLength_; ) {
            if (allowedSigners_[i] == signer_) {
                return true;
            }

            unchecked {
                ++i;
            }
        }

        return false;
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function signers() public view returns (address[] memory signers_) {
        return _getSigners();
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function requiredSigners() public view returns (uint8) {
        return _getRequiredSigners();
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function signersCount() public view returns (uint8) {
        return _getSignersCount();
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function owner() public view returns (address) {
        return IAvocado(address(this))._owner();
    }

    /// @inheritdoc IAvocadoMultisigV1Base
    function index() public view returns (uint32) {
        return uint32(IAvocado(address(this))._data() >> 160);
    }

    /// @notice incrementing nonce for each valid tx executed (to ensure uniqueness)
    function avoNonce() public view returns (uint256) {
        return uint256(_avoNonce);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import { InstaFlashReceiverInterface } from "../external/InstaFlashReceiverInterface.sol";
import { IAvoRegistry } from "../interfaces/IAvoRegistry.sol";
import { IAvoSignersList } from "../interfaces/IAvoSignersList.sol";
import { IAvocadoMultisigV1Base } from "../interfaces/IAvocadoMultisigV1.sol";
import { IAvocadoMultisigV1Secondary } from "../interfaces/IAvocadoMultisigV1Secondary.sol";
import { IAvoConfigV1 } from "../interfaces/IAvoConfigV1.sol";
import { IAvocado } from "../Avocado.sol";
import { AvocadoMultisigErrors } from "./AvocadoMultisigErrors.sol";
import { AvocadoMultisigEvents } from "./AvocadoMultisigEvents.sol";
import { AvocadoMultisigVariables } from "./AvocadoMultisigVariables.sol";
import { AvocadoMultisigInitializable } from "./lib/AvocadoMultisigInitializable.sol";
import { AvocadoMultisigStructs } from "./AvocadoMultisigStructs.sol";
import { AvocadoMultisigProtected } from "./AvocadoMultisig.sol";

/// @dev AvocadoMultisigBase contains all internal helper and base state needed for AvocadoMultisig main AND
///      secondary contract logic.
abstract contract AvocadoMultisigBase is
    AvocadoMultisigErrors,
    AvocadoMultisigEvents,
    AvocadoMultisigVariables,
    AvocadoMultisigStructs,
    AvocadoMultisigInitializable
{
    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    constructor(
        IAvoRegistry avoRegistry_,
        address avoForwarder_,
        IAvoSignersList avoSignersList_,
        IAvoConfigV1 avoConfigV1_
    ) AvocadoMultisigVariables(avoRegistry_, avoForwarder_, avoSignersList_, avoConfigV1_) {
        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /***********************************|
    |               INTERNAL            |
    |__________________________________*/

    /// @dev returns the dynamic reserve gas to be kept back for emitting the CastExecuted or CastFailed event
    function _dynamicReserveGas(
        uint256 fixedReserveGas_,
        uint256 signersCount_,
        uint256 metadataLength_
    ) internal pure returns (uint256 reserveGas_) {
        unchecked {
            // the gas usage for the emitting the CastExecuted/CastFailed events depends on the signers count
            // the cost per signer is PER_SIGNER_RESERVE_GAS. We calculate this dynamically to ensure
            // enough reserve gas is reserved in Multisigs with a higher signersCount.
            // same for metadata bytes length, dynamically calculated with cost per byte for emit event
            reserveGas_ =
                fixedReserveGas_ +
                (PER_SIGNER_RESERVE_GAS * signersCount_) +
                (EMIT_EVENT_COST_PER_BYTE * metadataLength_);
        }
    }

    /// @dev Returns the domain separator for the chain with id `DEFAULT_CHAIN_ID` and `salt_`
    function _domainSeparatorV4(bytes32 salt_) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TYPE_HASH,
                    DOMAIN_SEPARATOR_NAME_HASHED,
                    DOMAIN_SEPARATOR_VERSION_HASHED,
                    DEFAULT_CHAIN_ID,
                    address(this),
                    salt_
                )
            );
    }

    /// @dev returns the EIP712 `CAST_PARAMS_TYPE_HASH` hash for `params_`.
    function _castParamsHash(CastParams memory params_) internal pure returns (bytes32) {
        // get keccak256s for actions
        uint256 actionsLength_ = params_.actions.length;
        bytes32[] memory keccakActions_ = new bytes32[](actionsLength_);
        for (uint256 i; i < actionsLength_; ) {
            keccakActions_[i] = keccak256(
                abi.encode(
                    ACTION_TYPE_HASH,
                    params_.actions[i].target,
                    keccak256(params_.actions[i].data),
                    params_.actions[i].value,
                    params_.actions[i].operation
                )
            );

            unchecked {
                ++i;
            }
        }

        return
            keccak256(
                abi.encode(
                    CAST_PARAMS_TYPE_HASH,
                    // actions[]
                    keccak256(abi.encodePacked(keccakActions_)),
                    params_.id,
                    params_.avoNonce,
                    params_.salt,
                    params_.source,
                    keccak256(params_.metadata)
                )
            );
    }

    /// @dev returns the EIP712 `CAST_FORWARD_PARAMS_TYPE_HASH` hash for `forwardParams_`.
    function _castForwardParamsHash(CastForwardParams memory forwardParams_) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CAST_FORWARD_PARAMS_TYPE_HASH,
                    forwardParams_.gas,
                    forwardParams_.gasPrice,
                    forwardParams_.validAfter,
                    forwardParams_.validUntil,
                    forwardParams_.value
                )
            );
    }

    /// @dev returns the EIP712 `CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH` hash for `params_`, `forwardParams_`, `chainId_`.
    function _castChainAgnosticParamsHash(
        CastParams memory params_,
        CastForwardParams memory forwardParams_,
        uint256 chainId_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH,
                    _castParamsHash(params_),
                    _castForwardParamsHash(forwardParams_),
                    chainId_
                )
            );
    }

    /// @dev                        gets the digest (hash) used to verify an EIP712 signature for `chainAgnosticHashes_`.
    /// @param chainAgnosticHashes_ EIP712 type hashes of `CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH` for all `CastChainAgnosticParams`
    ///                             struct array elements as used when creating the signature. Result of `getChainAgnosticHashes()`.
    ///                             must be set in the same order as when creating the signature.
    /// @return                     bytes32 digest e.g. for signature or non-sequential nonce
    function _getSigDigestChainAgnostic(bytes32[] memory chainAgnosticHashes_) internal view returns (bytes32) {
        return
            ECDSA.toTypedDataHash(
                // domain separator without chain id as salt for chain agnofstic actions (chain id is in signed params instead)
                _domainSeparatorV4(
                    DOMAIN_SEPARATOR_CHAIN_AGNOSTIC_SALT_HASHED // includes default chain id (634)
                ),
                // structHash according to CAST_CHAIN_AGNOSTIC_TYPE_HASH
                keccak256(
                    abi.encode(
                        CAST_CHAIN_AGNOSTIC_TYPE_HASH,
                        // hash for castChainAgnostic() params[]
                        keccak256(abi.encodePacked(chainAgnosticHashes_))
                    )
                )
            );
    }

    /// @dev                     gets the digest (hash) used to verify an EIP712 signature for `forwardParams_`
    /// @param params_           Cast params such as id, avoNonce and actions to execute
    /// @param forwardParams_    Cast params related to validity of forwarding as instructed and signed
    /// @return                  bytes32 digest e.g. for signature or non-sequential nonce
    function _getSigDigest(
        CastParams memory params_,
        CastForwardParams memory forwardParams_
    ) internal view returns (bytes32) {
        return
            ECDSA.toTypedDataHash(
                // domain separator
                _domainSeparatorV4(
                    DOMAIN_SEPARATOR_SALT_HASHED // includes block.chainid
                ),
                // structHash according to CAST_TYPE_HASH
                keccak256(abi.encode(CAST_TYPE_HASH, _castParamsHash(params_), _castForwardParamsHash(forwardParams_)))
            );
    }

    /// @dev                          Verifies a EIP712 signature, returning valid status in `isValid_` or reverting
    ///                               in case the params for the signatures / digest are wrong
    /// @param digest_                the EIP712 digest for the signature
    /// @param signaturesParams_      SignatureParams structs array for signature and signer:
    ///                               - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                                 For smart contract signatures it must fulfill the requirements for the relevant
    ///                                 smart contract `.isValidSignature()` EIP1271 logic
    ///                               - signer: address of the signature signer.
    ///                                 Must match the actual signature signer or refer to the smart contract
    ///                                 that must be an allowed signer and validates signature via EIP1271
    /// @param  isNonSequentialNonce_ flag to signal verify with non sequential nonce or not
    /// @return isValid_              true if the signature is valid, false otherwise
    /// @return recoveredSigners_     recovered valid signer addresses of the signatures. In case that `isValid_` is
    ///                               false, the last element in the array with a value is the invalid signer
    function _verifySig(
        bytes32 digest_,
        SignatureParams[] memory signaturesParams_,
        bool isNonSequentialNonce_
    ) internal view returns (bool isValid_, address[] memory recoveredSigners_) {
        // gas measurements:
        // cost until the for loop in verify signature is:
        // 1 signer 3374 (_getSigners() with only owner is cheaper)
        // 2 signers 6473
        // every additional allowedSigner (!) + 160 gas (additional SSTORE2 load cost)
        // For non-sequential nonce additional cold SLOAD + check cost is ~2200
        // dynamic cost for verifying any additional signer ~6900
        // So formula:
        // Avoado signersCount == 1 ? -> 11_000 gas
        // Avoado signersCount > 1 ? -> 6400  + allowedSignersCount * 160 + signersLength * 6900
        // is non Sequential nonce? + 2200
        // is smart contract signer? + buffer amount. A very basic ECDSA verify call like with e.g. MockSigner costs ~9k.
        uint256 signaturesLength_ = signaturesParams_.length;

        if (
            // enough signatures must be submitted to reach quorom of `requiredSigners`
            signaturesLength_ < _getRequiredSigners() ||
            // for non sequential nonce, if nonce is already used, the signature has already been used and is invalid
            (isNonSequentialNonce_ && nonSequentialNonces[digest_] == 1)
        ) {
            revert AvocadoMultisig__InvalidParams();
        }

        // fill recovered signers array for use in event emit
        recoveredSigners_ = new address[](signaturesLength_);

        // get current signers from storage
        address[] memory allowedSigners_ = _getSigners(); // includes owner
        uint256 allowedSignersLength_ = allowedSigners_.length;
        // track last allowed signer index for loop performance improvements
        uint256 lastAllowedSignerIndex_ = 0;

        bool isContract_ = false; // keeping this variable outside the loop so it is not re-initialized in each loop -> cheaper
        bool isAllowedSigner_ = false;
        for (uint256 i; i < signaturesLength_; ) {
            if (Address.isContract(signaturesParams_[i].signer)) {
                recoveredSigners_[i] = signaturesParams_[i].signer;
                // set flag that the signer is a contract so we don't have to check again in code below
                isContract_ = true;
            } else {
                // recover signer from signature
                recoveredSigners_[i] = ECDSA.recover(digest_, signaturesParams_[i].signature);

                if (signaturesParams_[i].signer != recoveredSigners_[i]) {
                    // signer does not match recovered signer. Either signer param is wrong or params used to
                    // build digest are not the same as for the signature
                    revert AvocadoMultisig__InvalidParams();
                }
            }

            // because signers in storage and signers from signatures input params must be ordered ascending,
            // the for loop can be optimized each new cycle to start from the position where the last signer
            // has been found.
            // this also ensures that input params signers must be ordered ascending off-chain
            // (which again is used to improve performance and simplifies ensuring unique signers)
            for (uint256 j = lastAllowedSignerIndex_; j < allowedSignersLength_; ) {
                if (allowedSigners_[j] == recoveredSigners_[i]) {
                    isAllowedSigner_ = true;
                    unchecked {
                        lastAllowedSignerIndex_ = j + 1; // set to j+1 so that next cycle starts at next array position
                    }
                    break;
                }

                // could be optimized by checking if allowedSigners_[j] > recoveredSigners_[i]
                // and immediately skipping with a `break;` if so. Because that implies that the recoveredSigners_[i]
                // can not be present in allowedSigners_ due to ascending sort.
                // But that would optimize the failing invalid case and increase cost for the default case where
                // the input data is valid -> skip.

                unchecked {
                    ++j;
                }
            }

            // validate if signer is allowed
            if (!isAllowedSigner_) {
                return (false, recoveredSigners_);
            } else {
                // reset `isAllowedSigner_` for next loop
                isAllowedSigner_ = false;
            }

            if (isContract_) {
                // validate as smart contract signature
                if (
                    IERC1271(signaturesParams_[i].signer).isValidSignature(digest_, signaturesParams_[i].signature) !=
                    EIP1271_MAGIC_VALUE
                ) {
                    // return value is not EIP1271_MAGIC_VALUE -> smart contract returned signature is invalid
                    return (false, recoveredSigners_);
                }

                // reset isContract for next loop (because defined outside of the loop to save gas)
                isContract_ = false;
            }
            // else already everything validated through recovered signer must be an allowed signer etc. in logic above

            unchecked {
                ++i;
            }
        }

        return (true, recoveredSigners_);
    }

    /// @dev                          Verifies a EIP712 signature, reverting if it is not valid.
    /// @param digest_                the EIP712 digest for the signature
    /// @param signaturesParams_      SignatureParams structs array for signature and signer:
    ///                               - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                                 For smart contract signatures it must fulfill the requirements for the relevant
    ///                                 smart contract `.isValidSignature()` EIP1271 logic
    ///                               - signer: address of the signature signer.
    ///                                 Must match the actual signature signer or refer to the smart contract
    ///                                 that must be an allowed signer and validates signature via EIP1271
    /// @param  isNonSequentialNonce_ flag to signal verify with non sequential nonce or not
    /// @return recoveredSigners_     recovered valid signer addresses of the signatures. In case that `isValid_` is
    ///                               false, the last element in the array with a value is the invalid signer
    function _verifySigWithRevert(
        bytes32 digest_,
        SignatureParams[] memory signaturesParams_,
        bool isNonSequentialNonce_
    ) internal view returns (address[] memory recoveredSigners_) {
        bool validSignature_;
        (validSignature_, recoveredSigners_) = _verifySig(digest_, signaturesParams_, isNonSequentialNonce_);

        // signature must be valid
        if (!validSignature_) {
            revert AvocadoMultisig__InvalidSignature();
        }
    }
}

/// @dev AvocadoMultisigCore contains all internal helper and base state needed for AvocadoMultisig.sol main logic
abstract contract AvocadoMultisigCore is
    AvocadoMultisigBase,
    ERC721Holder,
    ERC1155Holder,
    InstaFlashReceiverInterface,
    IAvocadoMultisigV1Base,
    IERC1271
{
    IAvocadoMultisigV1Secondary public immutable avoSecondary;

    constructor(IAvocadoMultisigV1Secondary secondary_) {
        if (address(secondary_) == address(0)) {
            revert AvocadoMultisig__InvalidParams();
        }

        avoSecondary = secondary_;
    }

    /// @dev ensures the method can only be called by the same contract itself.
    modifier onlySelf() {
        _requireSelfCalled();
        _;
    }

    /// @dev internal method for modifier logic to reduce bytecode size of contract.
    function _requireSelfCalled() internal view {
        if (msg.sender != address(this)) {
            revert AvocadoMultisig__Unauthorized();
        }
    }

    /// @dev method used to trigger a delegatecall with `data_` to `target_`.
    function _spell(address target_, bytes memory data_) internal returns (bytes memory response_) {
        assembly {
            let succeeded := delegatecall(gas(), target_, add(data_, 0x20), mload(data_), 0, 0)
            let size := returndatasize()

            response_ := mload(0x40)
            mstore(0x40, add(response_, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response_, size)
            returndatacopy(add(response_, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }

    /// @dev executes multiple cast actions according to CastParams `params_`, reserving `reserveGas_` in this contract.
    /// Uses a sequential nonce unless `nonSequentialNonce_` is set.
    /// @return success_ boolean flag indicating whether all actions have been executed successfully.
    /// @return revertReason_ if `success_` is false, then revert reason is returned as string here.
    function _executeCast(
        CastParams calldata params_,
        uint256 reserveGas_,
        bytes32 nonSequentialNonce_
    ) internal returns (bool success_, string memory revertReason_) {
        // set allowHash to signal allowed entry into _callTargets with actions in current block only
        _transientAllowHash = bytes31(
            keccak256(abi.encode(params_.actions, params_.id, block.timestamp, _CALL_TARGETS_SELECTOR))
        );

        // nonce must be used *always* if signature is valid
        if (nonSequentialNonce_ == bytes32(0)) {
            // use sequential nonce, already validated in `_validateParams()`
            _avoNonce++;
        } else {
            // use non-sequential nonce, already validated in `_verifySig()`
            nonSequentialNonces[nonSequentialNonce_] = 1;
        }

        // execute _callTargets via a low-level call to create a separate execution frame
        // this is used to revert all the actions if one action fails without reverting the whole transaction
        bytes memory calldata_ = abi.encodeCall(AvocadoMultisigProtected._callTargets, (params_.actions, params_.id));
        bytes memory result_;
        unchecked {
            if (gasleft() < reserveGas_ + 150) {
                // catch out of gas issues when available gas does not even cover reserveGas
                // -> immediately return with out of gas. + 150 to cover sload, sub etc.
                _resetTransientStorage();
                return (false, "AVO__OUT_OF_GAS");
            }
        }
        // using inline assembly for delegatecall to define custom gas amount that should stay here in caller
        assembly {
            success_ := delegatecall(
                // reserve some gas to make sure we can emit CastFailed event even for out of gas cases
                // and execute fee paying logic for `castAuthorized()`.
                // if gasleft() is less than the amount wanted to be sent along, sub would overflow and send all gas
                // that's why there is the explicit check a few lines up.
                sub(gas(), reserveGas_),
                // load _avoImpl from slot 0 and explicitly convert to address with bit mask
                and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff),
                add(calldata_, 0x20),
                mload(calldata_),
                0,
                0
            )
            let size := returndatasize()

            result_ := mload(0x40)
            mstore(0x40, add(result_, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(result_, size)
            returndatacopy(add(result_, 0x20), 0, size)
        }

        // @dev starting point for measuring reserve gas should be here right after actions execution.
        // on changes in code after execution (below here or below `_executeCast()` call in calling method),
        // measure the needed reserve gas via `gasleft()` anew and update `CAST_AUTHORIZED_RESERVE_GAS`
        // and `CAST_EVENTS_RESERVE_GAS` accordingly. use a method that forces maximum logic execution,
        // e.g. `castAuthorized()` with failing action.
        // gas measurement currently: ~1400 gas for logic in this method below
        if (!success_) {
            if (result_.length == 0) {
                if (gasleft() < reserveGas_ - 150) {
                    // catch out of gas errors where not the action ran out of gas but the logic around execution
                    // of the action itself. -150 to cover gas cost until here
                    revertReason_ = "AVO__OUT_OF_GAS";
                } else {
                    // @dev this case might be caused by edge-case out of gas errors that we were unable to catch,
                    // but could potentially also have other reasons
                    revertReason_ = "AVO__REASON_NOT_DEFINED";
                }
            } else {
                assembly {
                    result_ := add(result_, 0x04)
                }
                revertReason_ = abi.decode(result_, (string));
            }
        }

        // reset all transient variables to get the gas refund (4800)
        _resetTransientStorage();
    }

    function _handleActionFailure(uint256 actionMinGasLeft_, uint256 i_, bytes memory result_) internal view {
        if (gasleft() < actionMinGasLeft_) {
            // action ran out of gas. can not add action index as that again might run out of gas. keep revert minimal
            revert("AVO__OUT_OF_GAS");
        }
        revert(string.concat(Strings.toString(i_), avoSecondary.getRevertReasonFromReturnedData(result_)));
    }

    function _simulateCast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] memory signaturesParams_,
        bytes32[] memory chainAgnosticHashes_
    ) internal returns (bool success_, string memory revertReason_) {
        if (msg.sender != avoForwarder || tx.origin != 0x000000000000000000000000000000000000dEaD) {
            // sender must be the allowed AvoForwarder and tx origin must be dead address
            revert AvocadoMultisig__Unauthorized();
        }

        (success_, revertReason_) = abi.decode(
            _spell(
                address(avoSecondary),
                abi.encodeCall(
                    avoSecondary.simulateCast,
                    (params_, forwardParams_, signaturesParams_, chainAgnosticHashes_)
                )
            ),
            (bool, string)
        );
    }

    /// @dev                        executes a cast process for `cast()` or `castChainAgnostic()`
    /// @param params_              Cast params such as id, avoNonce and actions to execute
    /// @param forwardParams_       Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_    SignatureParams structs array for signature and signer:
    ///                              - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                                For smart contract signatures it must fulfill the requirements for the relevant
    ///                                smart contract `.isValidSignature()` EIP1271 logic
    ///                              - signer: address of the signature signer.
    ///                                Must match the actual signature signer or refer to the smart contract
    ///                                that must be an allowed signer and validates signature via EIP1271
    /// @param chainAgnosticHashes_ EIP712 type hashes of `CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH` for all `CastChainAgnosticParams`
    ///                             struct array elements as used when creating the signature. Result of `getChainAgnosticHashes()`.
    ///                             must be set in the same order as when creating the signature.
    /// @return success_            true if all actions were executed succesfully, false otherwise.
    /// @return revertReason_       revert reason if one of the actions fails in the following format:
    ///                             The revert reason will be prefixed with the index of the action.
    ///                             e.g. if action 1 fails, then the reason will be "1_reason".
    ///                             if an action in the flashloan callback fails (or an otherwise nested action),
    ///                             it will be prefixed with with two numbers: "1_2_reason".
    ///                             e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                             the reason will be 1_2_reason.
    function _cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] memory signaturesParams_,
        bytes32[] memory chainAgnosticHashes_
    ) internal returns (bool success_, string memory revertReason_) {
        if (msg.sender != avoForwarder) {
            // sender must be the allowed AvoForwarder
            revert AvocadoMultisig__Unauthorized();
        }

        unchecked {
            // compare actual sent gas to user instructed gas, adding 500 to `gasleft()` for approx. already used gas
            if ((gasleft() + 500) < forwardParams_.gas) {
                // relayer has not sent enough gas to cover gas limit as user instructed.
                // this error should not be blamed on the user but rather on the relayer
                revert AvocadoMultisig__InsufficientGasSent();
            }
        }

        // @dev gas measurement: uses maximum 685 gas when all params must be validated
        _validateParams(
            params_.actions.length,
            params_.avoNonce,
            forwardParams_.validAfter,
            forwardParams_.validUntil,
            forwardParams_.value
        );

        if (chainAgnosticHashes_.length > 0) {
            // validate that input `CastParams` and `CastForwardParams` are present in `chainAgnosticHashes_`
            _validateChainAgnostic(
                _castChainAgnosticParamsHash(params_, forwardParams_, block.chainid),
                chainAgnosticHashes_
            );
        }

        bytes32 digest_ = chainAgnosticHashes_.length > 0
            ? _getSigDigestChainAgnostic(chainAgnosticHashes_)
            : _getSigDigest(params_, forwardParams_);

        address[] memory signers_ = _verifySigWithRevert(digest_, signaturesParams_, params_.avoNonce == -1);

        (success_, revertReason_) = _executeCast(
            params_,
            _dynamicReserveGas(CAST_EVENTS_RESERVE_GAS, signers_.length, params_.metadata.length),
            params_.avoNonce == -1 ? digest_ : bytes32(0)
        );

        // @dev on changes in the code below this point, measure the needed reserve gas via `gasleft()` anew
        // and update the reserve gas constant amounts.
        // gas measurement currently: ~7500 gas for emit event with max revertReason length
        if (success_) {
            emit CastExecuted(params_.source, msg.sender, signers_, params_.metadata);
        } else {
            emit CastFailed(params_.source, msg.sender, signers_, revertReason_, params_.metadata);
        }
        // @dev ending point for measuring reserve gas should be here. Also see comment in `AvocadoMultisigCore._executeCast()`
    }

    /// @dev executes `actions_` with respective target, calldata, operation etc.
    /// IMPORTANT: Validation of `id_` and `_transientAllowHash` is expected to happen in `executeOperation()` and `_callTargets()`.
    /// catches out of gas errors (as well as possible), reverting with `AVO__OUT_OF_GAS`.
    /// reverts with action index + error code in case of failure (e.g. "1_SOME_ERROR").
    function _executeActions(Action[] memory actions_, uint256 id_, bool isFlashloanCallback_) internal {
        // reset _transientAllowHash immediately to avert reentrancy etc. & get the gas refund (4800)
        _resetTransientStorage();

        uint256 storageSlot0Snapshot_; // avoImpl, nonce, initialized vars
        uint256 storageSlot1Snapshot_; // signers related variables
        // delegate call = ids 1 and 21
        bool isDelegateCallId_ = id_ == 1 || id_ == 21;
        if (isDelegateCallId_) {
            // store values before execution to make sure core storage vars are not modified by a delegatecall.
            // this ensures the smart wallet does not end up in a corrupted state.
            // for mappings etc. it is hard to protect against storage changes, so we must rely on the owner / signer
            // to know what is being triggered and the effects of a tx
            assembly {
                storageSlot0Snapshot_ := sload(0x0) // avoImpl, nonce & initialized vars
                storageSlot1Snapshot_ := sload(0x1) // signers related variables
            }
        }

        uint256 actionsLength_ = actions_.length;
        for (uint256 i; i < actionsLength_; ) {
            Action memory action_ = actions_[i];

            // execute action
            bool success_;
            bytes memory result_;
            uint256 actionMinGasLeft_;
            if (action_.operation == 0 && (id_ < 2 || id_ == 20 || id_ == 21)) {
                // call (operation = 0 & id = call(0 / 20) or mixed(1 / 21))
                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    // -> as close as possible to actual call
                    actionMinGasLeft_ = gasleft() / 64;
                }

                // low-level call will return success true also if action target is not even a contract.
                // we do not explicitly check for this, default interaction is via UI which can check and handle this.
                // Also applies to delegatecall etc.
                (success_, result_) = action_.target.call{ value: action_.value }(action_.data);

                // handle action failure right after external call to better detect out of gas errors
                if (!success_) {
                    _handleActionFailure(actionMinGasLeft_, i, result_);
                }
            } else if (action_.operation == 1 && isDelegateCallId_) {
                // delegatecall (operation = 1 & id = mixed(1 / 21))
                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    // -> as close as possible to actual call
                    actionMinGasLeft_ = gasleft() / 64;
                }

                (success_, result_) = action_.target.delegatecall(action_.data);

                // handle action failure right after external call to better detect out of gas errors
                if (!success_) {
                    _handleActionFailure(actionMinGasLeft_, i, result_);
                }

                // reset _transientAllowHash to make sure it can not be set up in any way for reentrancy
                _resetTransientStorage();

                // for delegatecall, make sure storage was not modified. After every action, to also defend reentrancy
                uint256 storageSlot0_;
                uint256 storageSlot1_;
                assembly {
                    storageSlot0_ := sload(0x0) // avoImpl, nonce & initialized vars
                    storageSlot1_ := sload(0x1) // signers related variables
                }

                if (!(storageSlot0_ == storageSlot0Snapshot_ && storageSlot1_ == storageSlot1Snapshot_)) {
                    revert(string.concat(Strings.toString(i), "_AVO__MODIFIED_STORAGE"));
                }
            } else if (action_.operation == 2 && (id_ == 20 || id_ == 21)) {
                // flashloan (operation = 2 & id = flashloan(20 / 21))
                if (isFlashloanCallback_) {
                    revert(string.concat(Strings.toString(i), "_AVO__NO_FLASHLOAN_IN_FLASHLOAN"));
                }
                // flashloan is always executed via .call, flashloan aggregator uses `msg.sender`, so .delegatecall
                // wouldn't send funds to this contract but rather to the original sender.

                bytes memory data_ = action_.data;
                assembly {
                    data_ := add(data_, 4) // Skip function selector (4 bytes)
                }
                // get actions data from calldata action_.data. Only supports InstaFlashAggregatorInterface
                (, , , data_, ) = abi.decode(data_, (address[], uint256[], uint256, bytes, bytes));

                // set allowHash to signal allowed entry into executeOperation()
                _transientAllowHash = bytes31(
                    keccak256(abi.encode(data_, block.timestamp, EXECUTE_OPERATION_SELECTOR))
                );
                // store id_ in transient storage slot
                _transientId = uint8(id_);

                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    // -> as close as possible to actual call
                    actionMinGasLeft_ = gasleft() / 64;
                }

                // handle action failure right after external call to better detect out of gas errors
                (success_, result_) = action_.target.call{ value: action_.value }(action_.data);

                if (!success_) {
                    _handleActionFailure(actionMinGasLeft_, i, result_);
                }

                // reset _transientAllowHash to prevent reentrancy during actions execution
                _resetTransientStorage();
            } else {
                // either operation does not exist or the id was not set according to what the action wants to execute
                revert(string.concat(Strings.toString(i), "_AVO__INVALID_ID_OR_OPERATION"));
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @dev                   Validates input params, reverts on invalid values.
    /// @param actionsLength_  the length of the actions array to execute
    /// @param avoNonce_   the avoNonce from input CastParams
    /// @param validAfter_     timestamp after which the request is valid
    /// @param validUntil_     timestamp before which the request is valid
    function _validateParams(
        uint256 actionsLength_,
        int256 avoNonce_,
        uint256 validAfter_,
        uint256 validUntil_,
        uint256 value_
    ) internal view {
        // make sure actions are defined and nonce is valid:
        // must be -1 to use a non-sequential nonce or otherwise it must match the avoNonce
        if (!(actionsLength_ > 0 && (avoNonce_ == -1 || uint256(avoNonce_) == _avoNonce))) {
            revert AvocadoMultisig__InvalidParams();
        }

        // make sure request is within valid timeframe
        if ((validAfter_ > block.timestamp) || (validUntil_ > 0 && validUntil_ < block.timestamp)) {
            revert AvocadoMultisig__InvalidTiming();
        }

        // make sure msg.value matches value_ (if set)
        if (value_ > 0 && msg.value != value_) {
            revert AvocadoMultisig__InvalidParams();
        }
    }

    /// @dev Validates input params for `castChainAgnostic`: verifies that the `curCastChainAgnosticHash_` is present in
    ///      the `castChainAgnosticHashes_` array of hashes. Reverts with `AvocadoMultisig__InvalidParams` if not.
    function _validateChainAgnostic(
        bytes32 curCastChainAgnosticHash_,
        bytes32[] memory castChainAgnosticHashes_
    ) internal pure {
        bool invalid_ = true;

        uint256 length_ = castChainAgnosticHashes_.length;
        for (uint256 i; i < length_; ) {
            if (curCastChainAgnosticHash_ == castChainAgnosticHashes_[i]) {
                // found -> valid
                invalid_ = false;
                break;
            }

            unchecked {
                ++i;
            }
        }

        if (invalid_) {
            // `_castChainAgnosticParamsHash()` of current input params is not present in castChainAgnosticHashes_ -> revert
            revert AvocadoMultisig__InvalidParams();
        }
    }

    /// @dev                      gets the digest (hash) used to verify an EIP712 signature for `authorizedParams_`
    /// @param params_            Cast params such as id, avoNonce and actions to execute
    /// @param authorizedParams_  Cast params related to execution through owner such as maxFee
    /// @return                   bytes32 digest e.g. for signature or non-sequential nonce
    function _getSigDigestAuthorized(
        CastParams memory params_,
        CastAuthorizedParams memory authorizedParams_
    ) internal view returns (bytes32) {
        return
            ECDSA.toTypedDataHash(
                // domain separator
                _domainSeparatorV4(
                    DOMAIN_SEPARATOR_SALT_HASHED // includes block.chainid
                ),
                // structHash according to CAST_AUTHORIZED_TYPE_HASH
                keccak256(
                    abi.encode(
                        CAST_AUTHORIZED_TYPE_HASH,
                        _castParamsHash(params_),
                        // CastAuthorizedParams hash
                        keccak256(
                            abi.encode(
                                CAST_AUTHORIZED_PARAMS_TYPE_HASH,
                                authorizedParams_.maxFee,
                                authorizedParams_.gasPrice,
                                authorizedParams_.validAfter,
                                authorizedParams_.validUntil
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

abstract contract AvocadoMultisigErrors {
    /// @notice thrown when a method is called with invalid params (e.g. a zero address as input param)
    error AvocadoMultisig__InvalidParams();

    /// @notice thrown when a signature is not valid (e.g. not signed by enough allowed signers)
    error AvocadoMultisig__InvalidSignature();

    /// @notice thrown when someone is trying to execute a in some way auth protected logic
    error AvocadoMultisig__Unauthorized();

    /// @notice thrown when forwarder/relayer does not send enough gas as the user has defined.
    ///         this error should not be blamed on the user but rather on the relayer
    error AvocadoMultisig__InsufficientGasSent();

    /// @notice thrown when a signature has expired or when a request isn't valid yet
    error AvocadoMultisig__InvalidTiming();

    /// @notice thrown when _toHexDigit() fails
    error AvocadoMultisig__ToHexDigit();

    /// @notice thrown when an EIP1271 signature is invalid
    error AvocadoMultisig__InvalidEIP1271Signature();

    /// @notice thrown when a `castAuthorized()` `fee` is bigger than the `maxFee` given through the input param
    error AvocadoMultisig__MaxFee(uint256 fee, uint256 maxFee);

    /// @notice thrown when `castAuthorized()` fee can not be covered by available contract funds
    error AvocadoMultisig__InsufficientBalance(uint256 fee);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

abstract contract AvocadoMultisigEvents {
    /// @notice Emitted when the implementation is upgraded to a new logic contract
    event Upgraded(address indexed newImplementation);

    /// @notice Emitted when a message is marked as allowed smart contract signature
    event SignedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a previously allowed signed message is removed
    event RemoveSignedMessage(bytes32 indexed messageHash);

    /// @notice emitted when the avoNonce in storage is increased through an authorized call to
    /// `occupyAvoNonces()`, which can be used to cancel a previously signed request
    event AvoNonceOccupied(uint256 indexed occupiedAvoNonce);

    /// @notice emitted when a non-sequential nonce is occupied in storage through an authorized call to
    /// `useNonSequentialNonces()`, which can be used to cancel a previously signed request
    event NonSequentialNonceOccupied(bytes32 indexed occupiedNonSequentialNonce);

    /// @notice Emitted when a fee is paid through use of the `castAuthorized()` method
    event FeePaid(uint256 indexed fee);

    /// @notice Emitted when paying a fee reverts at the recipient
    event FeePayFailed(uint256 indexed fee);

    /// @notice emitted when syncing to the AvoSignersList fails
    event ListSyncFailed();

    /// @notice emitted when all actions are executed successfully.
    /// caller = owner / AvoForwarder address. signers = addresses that triggered this execution
    event CastExecuted(address indexed source, address indexed caller, address[] signers, bytes metadata);

    /// @notice emitted if one of the executed actions fails. The reason will be prefixed with the index of the action.
    /// e.g. if action 1 fails, then the reason will be 1_reason
    /// if an action in the flashloan callback fails, it will be prefixed with with two numbers:
    /// e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails, the reason will be 1_2_reason.
    /// caller = owner / AvoForwarder address. signers = addresses that triggered this execution
    /// Note If the signature was invalid, the `signers` array last set element is the signer that is not allowed
    event CastFailed(address indexed source, address indexed caller, address[] signers, string reason, bytes metadata);

    /// @notice emitted when a signer is added as Multisig signer
    event SignerAdded(address indexed signer);

    /// @notice emitted when a signer is removed as Multisig signer
    event SignerRemoved(address indexed signer);

    /// @notice emitted when the required signers count is updated
    event RequiredSignersSet(uint8 indexed requiredSigners);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface AvocadoMultisigStructs {
    /// @notice a combination of a bytes signature and its signer.
    struct SignatureParams {
        ///
        /// @param signature ECDSA signature of `getSigDigest()` for default flow or EIP1271 smart contract signature
        bytes signature;
        ///
        /// @param signer signer of the signature. Can be set to smart contract address that supports EIP1271
        address signer;
    }

    /// @notice an arbitrary executable action
    struct Action {
        ///
        /// @param target the target address to execute the action on
        address target;
        ///
        /// @param data the calldata to be passed to the call for each target
        bytes data;
        ///
        /// @param value the msg.value to be passed to the call for each target. set to 0 if none
        uint256 value;
        ///
        /// @param operation type of operation to execute:
        /// 0 -> .call; 1 -> .delegateCall, 2 -> flashloan (via .call)
        uint256 operation;
    }

    /// @notice common params for both `cast()` and `castAuthorized()`
    struct CastParams {
        Action[] actions;
        ///
        /// @param id             Required:
        ///                       id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall),
        ///                                           20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
        uint256 id;
        ///
        /// @param avoNonce   Required:
        ///                       avoNonce to be used for this tx. Must equal the avoNonce value on smart
        ///                       wallet or alternatively it must be set to -1 to use a non-sequential nonce instead
        int256 avoNonce;
        ///
        /// @param salt           Optional:
        ///                       Salt to customize non-sequential nonce (if `avoNonce` is set to -1)
        bytes32 salt;
        ///
        /// @param source         Optional:
        ///                       Source / referral for this tx
        address source;
        ///
        /// @param metadata       Optional:
        ///                       metadata for any potential additional data to be tracked in the tx
        bytes metadata;
    }

    /// @notice `cast()` input params related to forwarding validity
    struct CastForwardParams {
        ///
        /// @param gas            Optional:
        ///                       As EIP-2770: user instructed minimum amount of gas that the relayer (AvoForwarder)
        ///                       must send for the execution. Sending less gas will fail the tx at the cost of the relayer.
        ///                       Also protects against potential gas griefing attacks
        ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        uint256 gas;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be forwarded in,
        ///                       or 0 if the request is not time-limited to occur after a certain time.
        ///                       Protects against relayers executing a certain transaction at an earlier moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       can be forwarded, or 0 if request should be valid forever.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validUntil;
        ///
        /// @param value          Optional:
        ///                       Not implemented / used yet (msg.value broadcaster should send along)
        uint256 value;
    }

    /// @notice `castAuthorized()` input params
    struct CastAuthorizedParams {
        ///
        /// @param maxFee         Optional:
        ///                       the maximum Avocado charge-up allowed to be paid for tx execution
        uint256 maxFee;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be forwarded in,
        ///                       or 0 if the request is not time-limited to occur after a certain time.
        ///                       Protects against relayers executing a certain transaction at an earlier moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       can be forwarded, or 0 if request should be valid forever.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validUntil;
    }

    /// @notice params for `castChainAgnostic()` to be used when casting txs on multiple chains with one signature
    struct CastChainAgnosticParams {
        ///
        /// @param params cast params containing actions to be executed etc.
        CastParams params;
        ///
        /// @param forwardParams params related to forwarding validity
        CastForwardParams forwardParams;
        ///
        /// @param chainId chainId where these actions are valid
        uint256 chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { SSTORE2 } from "solmate/src/utils/SSTORE2.sol";

import { IAvoRegistry } from "../interfaces/IAvoRegistry.sol";
import { IAvoSignersList } from "../interfaces/IAvoSignersList.sol";
import { IAvoConfigV1 } from "../interfaces/IAvoConfigV1.sol";
import { IAvocado } from "../Avocado.sol";
import { AvocadoMultisigErrors } from "./AvocadoMultisigErrors.sol";
import { AvocadoMultisigEvents } from "./AvocadoMultisigEvents.sol";

abstract contract AvocadoMultisigConstants is AvocadoMultisigErrors {
    /************************************|
    |               CONSTANTS            |
    |___________________________________*/

    /// @notice overwrite chain id for EIP712 is always set to 63400 for the Avocado RPC / network
    uint256 public constant DEFAULT_CHAIN_ID = 63400;

    // constants for EIP712 values
    string public constant DOMAIN_SEPARATOR_NAME = "Avocado-Multisig";
    string public constant DOMAIN_SEPARATOR_VERSION = "1.1.0";
    // hashed EIP712 values
    bytes32 internal constant DOMAIN_SEPARATOR_NAME_HASHED = keccak256(bytes(DOMAIN_SEPARATOR_NAME));
    bytes32 internal constant DOMAIN_SEPARATOR_VERSION_HASHED = keccak256(bytes(DOMAIN_SEPARATOR_VERSION));

    /// @notice _TYPE_HASH is copied from OpenZeppelin EIP712 but with added salt as last param (we use it for `block.chainid`)
    bytes32 public constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");

    /// @notice EIP712 typehash for `cast()` calls, including structs
    bytes32 public constant CAST_TYPE_HASH =
        keccak256(
            "Cast(CastParams params,CastForwardParams forwardParams)Action(address target,bytes data,uint256 value,uint256 operation)CastForwardParams(uint256 gas,uint256 gasPrice,uint256 validAfter,uint256 validUntil,uint256 value)CastParams(Action[] actions,uint256 id,int256 avoNonce,bytes32 salt,address source,bytes metadata)"
        );

    /// @notice EIP712 typehash for Action struct
    bytes32 public constant ACTION_TYPE_HASH =
        keccak256("Action(address target,bytes data,uint256 value,uint256 operation)");

    /// @notice EIP712 typehash for CastParams struct
    bytes32 public constant CAST_PARAMS_TYPE_HASH =
        keccak256(
            "CastParams(Action[] actions,uint256 id,int256 avoNonce,bytes32 salt,address source,bytes metadata)Action(address target,bytes data,uint256 value,uint256 operation)"
        );
    /// @notice EIP712 typehash for CastForwardParams struct
    bytes32 public constant CAST_FORWARD_PARAMS_TYPE_HASH =
        keccak256(
            "CastForwardParams(uint256 gas,uint256 gasPrice,uint256 validAfter,uint256 validUntil,uint256 value)"
        );

    /// @notice EIP712 typehash for `castAuthorized()` calls, including structs
    bytes32 public constant CAST_AUTHORIZED_TYPE_HASH =
        keccak256(
            "CastAuthorized(CastParams params,CastAuthorizedParams authorizedParams)Action(address target,bytes data,uint256 value,uint256 operation)CastAuthorizedParams(uint256 maxFee,uint256 gasPrice,uint256 validAfter,uint256 validUntil)CastParams(Action[] actions,uint256 id,int256 avoNonce,bytes32 salt,address source,bytes metadata)"
        );
    /// @notice EIP712 typehash for CastAuthorizedParams struct
    bytes32 public constant CAST_AUTHORIZED_PARAMS_TYPE_HASH =
        keccak256("CastAuthorizedParams(uint256 maxFee,uint256 gasPrice,uint256 validAfter,uint256 validUntil)");

    /// @notice EIP712 typehash for `castChainAgnostic()` calls, bytes32 hashes array made up of `getSigDigest()` for
    ///         action on the respective chain.
    bytes32 public constant CAST_CHAIN_AGNOSTIC_TYPE_HASH =
        keccak256(
            "CastChainAgnostic(CastChainAgnosticParams[] params)Action(address target,bytes data,uint256 value,uint256 operation)CastChainAgnosticParams(CastParams params,CastForwardParams forwardParams,uint256 chainId)CastForwardParams(uint256 gas,uint256 gasPrice,uint256 validAfter,uint256 validUntil,uint256 value)CastParams(Action[] actions,uint256 id,int256 avoNonce,bytes32 salt,address source,bytes metadata)"
        );
    /// @notice EIP712 typehash for CastChainAgnosticParams struct
    bytes32 public constant CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH =
        keccak256(
            "CastChainAgnosticParams(CastParams params,CastForwardParams forwardParams,uint256 chainId)Action(address target,bytes data,uint256 value,uint256 operation)CastForwardParams(uint256 gas,uint256 gasPrice,uint256 validAfter,uint256 validUntil,uint256 value)CastParams(Action[] actions,uint256 id,int256 avoNonce,bytes32 salt,address source,bytes metadata)"
        );

    /// @notice EIP712 typehash for signed hashes used for EIP1271 (`isValidSignature()`)
    bytes32 public constant EIP1271_TYPE_HASH = keccak256("AvocadoHash(bytes32 hash)");

    /// @notice defines the max signers count for the Multisig. This is chosen deliberately very high, as there shouldn't
    /// really be a limit on signers count in practice. It is extremely unlikely that anyone runs into this very high
    /// limit but it helps to implement test coverage within this given limit
    uint256 public constant MAX_SIGNERS_COUNT = 90;

    /// @dev "magic value" according to EIP1271 https://eips.ethereum.org/EIPS/eip-1271#specification
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x1626ba7e;

    /// @dev constants for _transientAllowHash functionality: function selectors
    bytes4 internal constant _CALL_TARGETS_SELECTOR = bytes4(keccak256(bytes("_callTargets()")));
    bytes4 internal constant EXECUTE_OPERATION_SELECTOR = bytes4(keccak256(bytes("executeOpeartion()")));

    /// @dev amount of gas to keep in castAuthorized caller method as reserve for emitting event + paying fee.
    /// the dynamic part is covered with PER_SIGNER_RESERVE_GAS.
    /// use 48_500 as reserve gas for `castAuthorized()`. Usually it will cost less but 48_500 is the maximum amount
    /// with buffer (~32_000 + 1_400 base) pay fee logic etc. could cost on maximum logic execution.
    uint256 internal constant CAST_AUTHORIZED_RESERVE_GAS = 48_500;
    /// @dev amount of gas to keep in cast caller method as reserve for emitting CastFailed / CastExecuted event.
    /// ~7500 gas + ~1400 gas + buffer. the dynamic part is covered with PER_SIGNER_RESERVE_GAS.
    uint256 internal constant CAST_EVENTS_RESERVE_GAS = 10_000;

    /// @dev emitting one byte in an event costs 8 byte see https://github.com/wolflo/evm-opcodes/blob/main/gas.md#a8-log-operations
    uint256 internal constant EMIT_EVENT_COST_PER_BYTE = 8;

    /// @dev maximum length of revert reason, longer will be truncated. necessary to reserve enugh gas for event emit
    uint256 internal constant REVERT_REASON_MAX_LENGTH = 250;

    /// @dev each additional signer costs ~358 gas to emit in the CastFailed / CastExecuted event. this amount must be
    /// factored in dynamically depending on the number of signers (PER_SIGNER_RESERVE_GAS * number of signers)
    uint256 internal constant PER_SIGNER_RESERVE_GAS = 370;

    /************************************|
    |             IMMUTABLES             |
    |___________________________________*/
    // hashed EIP712 value to reduce gas usage
    bytes32 internal immutable DOMAIN_SEPARATOR_SALT_HASHED = keccak256(abi.encodePacked(block.chainid));
    // hashed EIP712 value to reduce gas usage
    bytes32 internal immutable DOMAIN_SEPARATOR_CHAIN_AGNOSTIC_SALT_HASHED =
        keccak256(abi.encodePacked(DEFAULT_CHAIN_ID));

    /// @notice  registry holding the valid versions (addresses) for Avocado smart wallet implementation contracts
    ///          The registry is used to verify a valid version before upgrading & to pay fees for `castAuthorized()`
    IAvoRegistry public immutable avoRegistry;

    /// @notice address of the AvoForwarder (proxy) that is allowed to forward tx with valid signatures
    address public immutable avoForwarder;

    /// @notice Signers <> Avocados mapping list contract for easy on-chain tracking
    IAvoSignersList public immutable avoSignersList;

    // @dev Note that AvocadoMultisig.sol (main) also has an immutable for avoSecondary in AvocadoMultisigCore.sol

    // backup fee logic
    /// @dev minimum fee for fee charged via `castAuthorized()` to charge if `AvoRegistry.calcFee()` would fail
    uint256 public immutable AUTHORIZED_MIN_FEE;
    /// @dev global maximum for fee charged via `castAuthorized()`. If AvoRegistry returns a fee higher than this,
    /// then MAX_AUTHORIZED_FEE is charged as fee instead (capping)
    uint256 public immutable AUTHORIZED_MAX_FEE;
    /// @dev address that the fee charged via `castAuthorized()` is sent to in the fallback case
    address payable public immutable AUTHORIZED_FEE_COLLECTOR;

    /***********************************|
    |            CONSTRUCTOR            |
    |__________________________________*/

    constructor(
        IAvoRegistry avoRegistry_,
        address avoForwarder_,
        IAvoSignersList avoSignersList_,
        IAvoConfigV1 avoConfigV1_
    ) {
        if (
            address(avoRegistry_) == address(0) ||
            avoForwarder_ == address(0) ||
            address(avoSignersList_) == address(0) ||
            address(avoConfigV1_) == address(0)
        ) {
            revert AvocadoMultisig__InvalidParams();
        }

        avoRegistry = avoRegistry_;
        avoForwarder = avoForwarder_;
        avoSignersList = avoSignersList_;

        // get values from AvoConfigV1 contract
        IAvoConfigV1.AvocadoMultisigConfig memory avoConfig_ = avoConfigV1_.avocadoMultisigConfig();

        // min & max fee settings, fee collector address are required
        if (
            avoConfig_.authorizedMinFee == 0 ||
            avoConfig_.authorizedMaxFee == 0 ||
            avoConfig_.authorizedFeeCollector == address(0) ||
            avoConfig_.authorizedMinFee > avoConfig_.authorizedMaxFee
        ) {
            revert AvocadoMultisig__InvalidParams();
        }

        AUTHORIZED_MIN_FEE = avoConfig_.authorizedMinFee;
        AUTHORIZED_MAX_FEE = avoConfig_.authorizedMaxFee;
        AUTHORIZED_FEE_COLLECTOR = payable(avoConfig_.authorizedFeeCollector);
    }
}

abstract contract AvocadoMultisigVariablesSlot0 {
    /// @notice address of the smart wallet logic / implementation contract.
    //  @dev    IMPORTANT: SAME STORAGE SLOT AS FOR PROXY. DO NOT MOVE THIS VARIABLE.
    //         _avoImpl MUST ALWAYS be the first declared variable here in the logic contract and in the proxy!
    //         When upgrading, the storage at memory address 0x0 is upgraded (first slot).
    //         Note immutable and constants do not take up storage slots so they can come before.
    address internal _avoImpl;

    /// @dev nonce that is incremented for every `cast` / `castAuthorized` transaction (unless it uses a non-sequential nonce)
    uint80 internal _avoNonce;

    /// @dev AvocadoMultisigInitializable.sol variables (modified from OpenZeppelin), see ./lib folder
    /// @dev Indicates that the contract has been initialized.
    uint8 internal _initialized;
    /// @dev Indicates that the contract is in the process of being initialized.
    bool internal _initializing;
}

abstract contract AvocadoMultisigVariablesSlot1 is AvocadoMultisigConstants, AvocadoMultisigEvents {
    /// @dev signers are stored with SSTORE2 to save gas, especially for storage checks at delegateCalls.
    /// getter and setter are implemented below
    address internal _signersPointer;

    /// @notice signers count required to reach quorom and be able to execute actions
    uint8 internal _requiredSigners;

    /// @notice number of signers currently listed as allowed signers
    //
    // @dev should be updated directly via `_setSigners()` in AvocadoMultisigSecondary
    uint8 internal _signersCount;

    // 10 bytes empty

    /***********************************|
    |           SIGNERS GETTERS         |
    |__________________________________*/

    /// @dev reads signers from storage with SSTORE2
    function _getSigners() internal view returns (address[] memory signers_) {
        address pointer_ = _signersPointer;
        if (pointer_ == address(0)) {
            // signers not set yet -> only owner is signer currently.
            signers_ = new address[](1);
            signers_[0] = IAvocado(address(this))._owner();
            return signers_;
        }

        return abi.decode(SSTORE2.read(pointer_), (address[]));
    }

    /// @dev reads required signers (and returns 1 if it is not set)
    function _getRequiredSigners() internal view returns (uint8 requiredSigners_) {
        requiredSigners_ = _requiredSigners;
        if (requiredSigners_ == 0) {
            requiredSigners_ = 1;
        }
    }

    /// @dev reads signers count (and returns 1 if it is not set)
    function _getSignersCount() internal view returns (uint8 signersCount_) {
        signersCount_ = _signersCount;
        if (signersCount_ == 0) {
            signersCount_ = 1;
        }
    }
}

abstract contract AvocadoMultisigVariablesSlot2 {
    /// @dev allow-listed signed messages, e.g. for Permit2 Uniswap interaction
    /// mappings are not in sequential storage slot, thus not influenced by previous storage variables
    /// (but consider the slot number in calculating the hash of the key to store).
    mapping(bytes32 => uint256) internal _signedMessages;
}

abstract contract AvocadoMultisigVariablesSlot3 {
    /// @notice used non-sequential nonces (which can not be used again)
    mapping(bytes32 => uint256) public nonSequentialNonces;
}

abstract contract AvocadoMultisigSlotGaps {
    // slots 4 to 53

    // create some storage slot gaps for future expansion before the transient storage slot
    uint256[50] private __gaps;
}

abstract contract AvocadoMultisigTransient {
    // slot 54

    /// @dev transient allow hash used to signal allowing certain entry into methods such as _callTargets etc.
    bytes31 internal _transientAllowHash;
    /// @dev transient id used for passing id to flashloan callback
    uint8 internal _transientId;
}

/// @notice Defines storage variables for AvocadoMultisig
abstract contract AvocadoMultisigVariables is
    AvocadoMultisigConstants,
    AvocadoMultisigVariablesSlot0,
    AvocadoMultisigVariablesSlot1,
    AvocadoMultisigVariablesSlot2,
    AvocadoMultisigVariablesSlot3,
    AvocadoMultisigSlotGaps,
    AvocadoMultisigTransient
{
    constructor(
        IAvoRegistry avoRegistry_,
        address avoForwarder_,
        IAvoSignersList avoSignersList_,
        IAvoConfigV1 avoConfigV1_
    ) AvocadoMultisigConstants(avoRegistry_, avoForwarder_, avoSignersList_, avoConfigV1_) {}

    /// @dev resets transient storage to default value (1). 1 is better than 0 for optimizing gas refunds
    function _resetTransientStorage() internal {
        assembly {
            sstore(54, 1) // Store 1 in the transient storage 54
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { AvocadoMultisigVariables } from "../AvocadoMultisigVariables.sol";

/// @dev contract copied from OpenZeppelin Initializable but with storage vars moved to AvocadoMultisigVariables.sol
/// from OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)
/// see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.1/contracts/proxy/utils/Initializable.sol

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract AvocadoMultisigInitializable is AvocadoMultisigVariables {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    // uint8 private _initialized; // -> in AvocadoMultisigVariables

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    // bool private _initializing; // -> in AvocadoMultisigVariables

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface InstaFlashReceiverInterface {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata _data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { AvocadoMultisigStructs } from "../AvocadoMultisig/AvocadoMultisigStructs.sol";

// @dev base interface without getters for storage variables (to avoid overloads issues)
interface IAvocadoMultisigV1Base is AvocadoMultisigStructs {
    /// @notice initializer called by AvoFactory after deployment, sets the `owner_` as the only signer
    function initialize() external;

    /// @notice returns the domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice returns the domainSeparator for EIP712 signature for `castChainAgnostic`
    function domainSeparatorV4ChainAgnostic() external view returns (bytes32);

    /// @notice               gets the digest (hash) used to verify an EIP712 signature for `cast()`.
    ///
    ///                       This is also used as the non-sequential nonce that will be marked as used when the
    ///                       request with the matching `params_` and `forwardParams_` is executed via `cast()`.
    /// @param params_        Cast params such as id, avoNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 digest to verify signature (or used as non-sequential nonce)
    function getSigDigest(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                   gets the digest (hash) used to verify an EIP712 signature for `castAuthorized()`.
    ///
    ///                           This is also the non-sequential nonce that will be marked as used when the request
    ///                           with the matching `params_` and `authorizedParams_` is executed via `castAuthorized()`.
    /// @param params_            Cast params such as id, avoNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @return                   bytes32 digest to verify signature (or used as non-sequential nonce)
    function getSigDigestAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice                   Verify the signatures for a `cast()' call are valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  SignatureParams structs array for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                             For smart contract signatures it must fulfill the requirements for the relevant
    ///                             smart contract `.isValidSignature()` EIP1271 logic
    ///                           - signer: address of the signature signer.
    ///                             Must match the actual signature signer or refer to the smart contract
    ///                             that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   Verify the signatures for a `castAuthorized()' call are valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  SignatureParams structs array for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                             For smart contract signatures it must fulfill the requirements for the relevant
    ///                             smart contract `.isValidSignature()` EIP1271 logic
    ///                           - signer: address of the signature signer.
    ///                             Must match the actual signature signer or refer to the smart contract
    ///                             that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verifyAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   Executes arbitrary actions with valid signatures. Only executable by AvoForwarder.
    ///                           If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           In that case, all previous actions are reverted.
    ///                           On success, emits CastExecuted event.
    /// @dev                      validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_            Cast params such as id, avoNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  SignatureParams structs array for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                             For smart contract signatures it must fulfill the requirements for the relevant
    ///                             smart contract `.isValidSignature()` EIP1271 logic
    ///                           - signer: address of the signature signer.
    ///                             Must match the actual signature signer or refer to the smart contract
    ///                             that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails in the following format:
    ///                           The revert reason will be prefixed with the index of the action.
    ///                           e.g. if action 1 fails, then the reason will be "1_reason".
    ///                           if an action in the flashloan callback fails (or an otherwise nested action),
    ///                           it will be prefixed with with two numbers: "1_2_reason".
    ///                           e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                           the reason will be 1_2_reason.
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                   Simulates a `cast()` call with exact same params and execution logic except for:
    ///                           - any `gasleft()` use removed to remove potential problems when estimating gas.
    ///                           - reverts on param validations removed (verify validity with `verify` instead).
    ///                           - signature validation is skipped (must be manually added to gas estimations).
    /// @dev                      tx.origin must be dead address, msg.sender must be AvoForwarder.
    /// @dev                      - set `signaturesParams_` to empty to automatically simulate with required signers length.
    ///                           - if `signaturesParams_` first element signature is not set, or if first signer is set to
    ///                             0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF, then gas usage burn is simulated
    ///                             for verify signature functionality. DO NOT set signature to non-empty for subsequent
    ///                             elements then; set all signatures to empty!
    ///                           - if `signaturesParams_` is set normally, signatures are verified as in actual execute
    ///                           - buffer amounts for mock smart contract signers signature verification must be added
    ///                             off-chain as this varies on a case per case basis.
    function simulateCast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] memory signaturesParams_
    ) external payable returns (bool success_, string memory revertReason_);

    /// @notice                   Executes arbitrary actions through authorized transaction sent with valid signatures.
    ///                           Includes a fee in native network gas token, amount depends on registry `calcFee()`.
    ///                           If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           In that case, all previous actions are reverted.
    ///                           On success, emits CastExecuted event.
    /// @dev                      executes a .call or .delegateCall for every action (depending on params)
    /// @param params_            Cast params such as id, avoNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  SignatureParams structs array for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                             For smart contract signatures it must fulfill the requirements for the relevant
    ///                             smart contract `.isValidSignature()` EIP1271 logic
    ///                           - signer: address of the signature signer.
    ///                             Must match the actual signature signer or refer to the smart contract
    ///                             that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails in the following format:
    ///                           The revert reason will be prefixed with the index of the action.
    ///                           e.g. if action 1 fails, then the reason will be "1_reason".
    ///                           if an action in the flashloan callback fails (or an otherwise nested action),
    ///                           it will be prefixed with with two numbers: "1_2_reason".
    ///                           e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                           the reason will be 1_2_reason.
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice returns the hashes for each `CastChainAgnosticParams` element of `params_`. The returned array must be
    ///         passed into `castChainAgnostic()` as the param `chainAgnosticHashes_` there (order must be the same).
    ///         The returned hash for each element is the EIP712 type hash for `CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH`,
    ///         as used when the signature digest is built.
    function getChainAgnosticHashes(
        CastChainAgnosticParams[] calldata params_
    ) external pure returns (bytes32[] memory chainAgnosticHashes_);

    /// @notice                   gets the digest (hash) used to verify an EIP712 signature for `castChainAgnostic()`.
    ///
    ///                           This is also the non-sequential nonce that will be marked as used when the request
    ///                           with the matching `params_` is executed via `castChainAgnostic()`.
    /// @param params_            Cast params such as id, avoNonce and actions to execute
    /// @return                   bytes32 digest to verify signature (or used as non-sequential nonce)
    function getSigDigestChainAgnostic(CastChainAgnosticParams[] calldata params_) external view returns (bytes32);

    /// @notice                     Executes arbitrary actions with valid signatures. Only executable by AvoForwarder.
    ///                             If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                             In that case, all previous actions are reverted.
    ///                             On success, emits CastExecuted event.
    /// @dev                        validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_              params containing info and intents regarding actions to be executed. Made up of
    ///                             same params as for `cast()` plus chain id.
    /// @param signaturesParams_    SignatureParams structs array for signature and signer:
    ///                             - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                               For smart contract signatures it must fulfill the requirements for the relevant
    ///                               smart contract `.isValidSignature()` EIP1271 logic
    ///                             - signer: address of the signature signer.
    ///                               Must match the actual signature signer or refer to the smart contract
    ///                               that must be an allowed signer and validates signature via EIP1271
    /// @param chainAgnosticHashes_ EIP712 type hashes of `CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH` for all `CastChainAgnosticParams`
    ///                             struct array elements as used when creating the signature. Result of `getChainAgnosticHashes()`.
    ///                             must be set in the same order as when creating the signature.
    /// @return success             true if all actions were executed succesfully, false otherwise.
    /// @return revertReason        revert reason if one of the actions fails in the following format:
    ///                             The revert reason will be prefixed with the index of the action.
    ///                             e.g. if action 1 fails, then the reason will be "1_reason".
    ///                             if an action in the flashloan callback fails (or an otherwise nested action),
    ///                             it will be prefixed with with two numbers: "1_2_reason".
    ///                             e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                             the reason will be 1_2_reason.
    function castChainAgnostic(
        CastChainAgnosticParams calldata params_,
        SignatureParams[] memory signaturesParams_,
        bytes32[] calldata chainAgnosticHashes_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                   Simulates a `castChainAgnostic()` call with exact same params and execution logic except for:
    ///                           - any `gasleft()` use removed to remove potential problems when estimating gas.
    ///                           - reverts on param validations removed (verify validity with `verify` instead).
    ///                           - signature validation is skipped (must be manually added to gas estimations).
    /// @dev                      tx.origin must be dead address, msg.sender must be AvoForwarder.
    /// @dev                      - set `signaturesParams_` to empty to automatically simulate with required signers length.
    ///                           - if `signaturesParams_` first element signature is not set, or if first signer is set to
    ///                             0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF, then gas usage burn is simulated
    ///                             for verify signature functionality. DO NOT set signature to non-empty for subsequent
    ///                             elements then; set all signatures to empty!
    ///                           - if `signaturesParams_` is set normally, signatures are verified as in actual execute
    ///                           - buffer amounts for mock smart contract signers signature verification must be added
    ///                             off-chain as this varies on a case per case basis.
    function simulateCastChainAgnostic(
        CastChainAgnosticParams calldata params_,
        SignatureParams[] memory signaturesParams_,
        bytes32[] calldata chainAgnosticHashes_
    ) external payable returns (bool success_, string memory revertReason_);

    /// @notice                     Verify the signatures for a `castChainAgnostic()' call are valid and can be executed.
    ///                             This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                             Does not revert and returns successfully if the input is valid.
    ///                             Reverts if input params, signature or avoNonce etc. are invalid.
    /// @param params_              params containing info and intents regarding actions to be executed. Made up of
    ///                             same params as for `cast()` plus chain id.
    /// @param signaturesParams_    SignatureParams structs array for signature and signer:
    ///                             - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                               For smart contract signatures it must fulfill the requirements for the relevant
    ///                               smart contract `.isValidSignature()` EIP1271 logic
    ///                             - signer: address of the signature signer.
    ///                               Must match the actual signature signer or refer to the smart contract
    ///                               that must be an allowed signer and validates signature via EIP1271
    /// @param chainAgnosticHashes_ EIP712 type hashes of `CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH` for all `CastChainAgnosticParams`
    ///                             struct array elements as used when creating the signature. Result of `getChainAgnosticHashes()`.
    ///                             must be set in the same order as when creating the signature.
    /// @return                     returns true if everything is valid, otherwise reverts
    function verifyChainAgnostic(
        CastChainAgnosticParams calldata params_,
        SignatureParams[] calldata signaturesParams_,
        bytes32[] calldata chainAgnosticHashes_
    ) external view returns (bool);

    /// @notice checks if an address `signer_` is an allowed signer (returns true if allowed)
    function isSigner(address signer_) external view returns (bool);

    /// @notice returns allowed signers on Avocado wich can trigger actions if reaching quorum `requiredSigners`.
    ///         signers automatically include owner.
    function signers() external view returns (address[] memory signers_);

    /// @notice returns the number of required signers
    function requiredSigners() external view returns (uint8);

    /// @notice returns the number of allowed signers
    function signersCount() external view returns (uint8);

    /// @notice Avocado owner
    function owner() external view returns (address);

    /// @notice Avocado index (number of Avocado for EOA owner)
    function index() external view returns (uint32);
}

// @dev full interface with some getters for storage variables
interface IAvocadoMultisigV1 is IAvocadoMultisigV1Base {
    /// @notice Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice incrementing nonce for each valid tx executed (to ensure uniqueness)
    function avoNonce() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { AvocadoMultisigStructs } from "../AvocadoMultisig/AvocadoMultisigStructs.sol";

interface IAvocadoMultisigV1Secondary {
    /// @notice             pays the fee for `castAuthorized()` calls via the AvoRegistry (or fallback)
    /// @param gasUsedFrom_ `gasleft()` snapshot at gas measurement starting point
    /// @param maxFee_      maximum acceptable fee to be paid, revert if fee is bigger than this value
    function payAuthorizedFee(uint256 gasUsedFrom_, uint256 maxFee_) external payable;

    /// @notice decodes `signature` for EIP1271 into `signaturesParams_`
    function decodeEIP1271Signature(
        bytes calldata signature,
        address owner_
    ) external pure returns (AvocadoMultisigStructs.SignatureParams[] memory signaturesParams_);

    /// @notice Get the revert reason from the returnedData (supports Panic, Error & Custom Errors).
    /// @param returnedData_ revert data of the call
    /// @return reason_      revert reason
    function getRevertReasonFromReturnedData(bytes memory returnedData_) external pure returns (string memory reason_);

    /// @notice upgrade the contract to a new implementation address.
    ///         - Must be a valid version at the AvoRegistry.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param avoImplementation_       New contract address
    /// @param afterUpgradeHookData_    flexible bytes for custom usage in after upgrade hook logic
    //
    // Implementation must call `_afterUpgradeHook()`
    function upgradeTo(address avoImplementation_, bytes calldata afterUpgradeHookData_) external;

    /// @notice                     executes a SIMULATE cast process for `cast()` or `castChainAgnostic()` for gas estimations.
    /// @param params_              Cast params such as id, avoNonce and actions to execute
    /// @param forwardParams_       Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_    SignatureParams structs array for signature and signer:
    ///                              - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                                For smart contract signatures it must fulfill the requirements for the relevant
    ///                                smart contract `.isValidSignature()` EIP1271 logic
    ///                              - signer: address of the signature signer.
    ///                                Must match the actual signature signer or refer to the smart contract
    ///                                that must be an allowed signer and validates signature via EIP1271
    /// @param chainAgnosticHashes_ EIP712 type hashes of `CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH` for all `CastChainAgnosticParams`
    ///                             struct array elements as used when creating the signature. Result of `getChainAgnosticHashes()`.
    ///                             must be set in the same order as when creating the signature.
    /// @return success_            true if all actions were executed succesfully, false otherwise.
    /// @return revertReason_       revert reason if one of the actions fails in the following format:
    ///                             The revert reason will be prefixed with the index of the action.
    ///                             e.g. if action 1 fails, then the reason will be "1_reason".
    ///                             if an action in the flashloan callback fails (or an otherwise nested action),
    ///                             it will be prefixed with with two numbers: "1_2_reason".
    ///                             e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                             the reason will be 1_2_reason.
    function simulateCast(
        AvocadoMultisigStructs.CastParams calldata params_,
        AvocadoMultisigStructs.CastForwardParams calldata forwardParams_,
        AvocadoMultisigStructs.SignatureParams[] memory signaturesParams_,
        bytes32[] memory chainAgnosticHashes_
    ) external returns (bool success_, string memory revertReason_);

    /// @notice SIMULATES: executes `actions_` with respective target, calldata, operation etc.
    function _simulateExecuteActions(
        AvocadoMultisigStructs.Action[] memory actions_,
        uint256 id_,
        bool isFlashloanCallback_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface IAvoConfigV1 {
    struct AvocadoMultisigConfig {
        uint256 authorizedMinFee;
        uint256 authorizedMaxFee;
        address authorizedFeeCollector;
    }

    struct AvoDepositManagerConfig {
        address depositToken;
    }

    struct AvoSignersListConfig {
        bool trackInStorage;
    }

    /// @notice config for AvocadoMultisig
    function avocadoMultisigConfig() external view returns (AvocadoMultisigConfig memory);

    /// @notice config for AvoDepositManager
    function avoDepositManagerConfig() external view returns (AvoDepositManagerConfig memory);

    /// @notice config for AvoSignersList
    function avoSignersListConfig() external view returns (AvoSignersListConfig memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface IAvoFeeCollector {
    /// @notice fee config params used to determine the fee for Avocado smart wallet `castAuthorized()` calls
    struct FeeConfig {
        /// @param feeCollector address that the fee should be paid to
        address payable feeCollector;
        /// @param mode current fee mode: 0 = percentage fee (gas cost markup); 1 = static fee (better for L2)
        uint8 mode;
        /// @param fee current fee amount:
        /// - for mode percentage: fee in 1e6 percentage (1e8 = 100%, 1e6 = 1%)
        /// - for static mode: absolute amount in native gas token to charge
        ///                    (max value 30_9485_009,821345068724781055 in 1e18)
        uint88 fee;
    }

    /// @notice calculates the `feeAmount_` for an Avocado (`msg.sender`) transaction `gasUsed_` based on
    ///         fee configuration present on the contract
    /// @param  gasUsed_       amount of gas used, required if mode is percentage. not used if mode is static fee.
    /// @return feeAmount_    calculate fee amount to be paid
    /// @return feeCollector_ address to send the fee to
    function calcFee(uint256 gasUsed_) external view returns (uint256 feeAmount_, address payable feeCollector_);
}

interface IAvoRegistry is IAvoFeeCollector {
    /// @notice                      checks if an address is listed as allowed AvoForwarder version, reverts if not.
    /// @param avoForwarderVersion_  address of the AvoForwarder logic contract to check
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) external view;

    /// @notice                     checks if an address is listed as allowed Avocado version, reverts if not.
    /// @param avoVersion_          address of the Avocado logic contract to check
    function requireValidAvoVersion(address avoVersion_) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface IAvoSignersList {
    /// @notice adds mappings of `addSigners_` to an Avocado `avocado_`.
    ///         checks the data present at the Avocado to validate input data.
    ///
    /// If `trackInStorage` flag is set to false, then only an event will be emitted for off-chain tracking.
    /// The contract itself will not track avocados per signer on-chain!
    ///
    /// Silently ignores `addSigners_` that are already added
    ///
    /// There is expectedly no need for this method to be called by anyone other than the Avocado itself.
    function syncAddAvoSignerMappings(address avocado_, address[] calldata addSigners_) external;

    /// @notice removes mappings of `removeSigners_` from an Avocado `avocado_`.
    ///         checks the data present at the Avocado to validate input data.
    ///
    /// If `trackInStorage` flag is set to false, then only an event will be emitted for off-chain tracking.
    /// The contract itself will not track avocados per signer on-chain!
    ///
    /// Silently ignores `addSigners_` that are already removed
    ///
    /// There is expectedly no need for this method to be called by anyone other than the Avocado itself.
    function syncRemoveAvoSignerMappings(address avocado_, address[] calldata removeSigners_) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}