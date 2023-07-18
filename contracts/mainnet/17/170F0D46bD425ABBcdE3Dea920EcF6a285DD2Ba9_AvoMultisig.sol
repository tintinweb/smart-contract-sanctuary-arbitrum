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
pragma solidity >=0.8.17;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import { InstaFlashReceiverInterface } from "../external/InstaFlashReceiverInterface.sol";
import { IAvoVersionsRegistry } from "../interfaces/IAvoVersionsRegistry.sol";
import { Initializable } from "./lib/Initializable.sol";
import { AvoCoreVariables } from "./AvoCoreVariables.sol";
import { AvoCoreEvents } from "./AvoCoreEvents.sol";
import { AvoCoreErrors } from "./AvoCoreErrors.sol";
import { AvoCoreStructs } from "./AvoCoreStructs.sol";

abstract contract AvoCore is
    AvoCoreErrors,
    AvoCoreVariables,
    AvoCoreEvents,
    AvoCoreStructs,
    Initializable,
    ERC721Holder,
    ERC1155Holder,
    InstaFlashReceiverInterface,
    IERC1271
{
    /// @dev ensures the method can only be called by the same contract itself.
    modifier onlySelf() {
        _requireSelfCalled();
        _;
    }

    /// @dev internal method for modifier logic to reduce bytecode size of contract.
    function _requireSelfCalled() internal view {
        if (msg.sender != address(this)) {
            revert AvoCore__Unauthorized();
        }
    }

    /// @dev sets the initial state of the contract for `owner_` as owner
    function _initializeOwner(address owner_) internal {
        // owner must be EOA
        if (Address.isContract(owner_) || owner_ == address(0)) {
            revert AvoCore__InvalidParams();
        }

        owner = owner_;
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
        // set status verified to 1 for call to _callTargets to avoid having to check signature etc. again
        _status = 1;

        // nonce must be used *always* if signature is valid
        if (nonSequentialNonce_ == bytes32(0)) {
            // use sequential nonce, already validated in `_validateParams()`
            avoSafeNonce++;
        } else {
            // use non-sequential nonce, already validated in `_verifySig()`
            nonSequentialNonces[nonSequentialNonce_] = 1;
        }

        // execute _callTargets via a low-level call to create a separate execution frame
        // this is used to revert all the actions if one action fails without reverting the whole transaction
        bytes memory calldata_ = abi.encodeCall(AvoCoreProtected._callTargets, (params_.actions, params_.id));
        bytes memory result_;
        // using inline assembly for delegatecall to define custom gas amount that should stay here in caller
        assembly {
            success_ := delegatecall(
                // reserve some gas to make sure we can emit CastFailed event even for out of gas cases
                // and execute fee paying logic for `castAuthorized()`
                sub(gas(), reserveGas_),
                sload(_avoImplementation.slot),
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

        // reset _status flag to 0 in all cases. cost 200 gas
        _status = 0;

        // @dev starting point for measuring reserve gas should be here right after actions execution.
        // on changes in code after execution (below here or below `_executeCast()` call in calling method),
        // measure the needed reserve gas via `gasleft()` anew and update `CAST_AUTHORIZED_RESERVE_GAS`
        // and `CAST_EVENTS_RESERVE_GAS` accordingly. use a method that forces maximum logic execution,
        // e.g. `castAuthorized()` with failing action in gas-usage-report.
        if (!success_) {
            if (result_.length == 0) {
                // @dev this case might be caused by edge-case out of gas errors that we were unable to catch,
                // but could potentially also have other reasons
                revertReason_ = "AVO__REASON_NOT_DEFINED";
            } else if (bytes4(result_) == bytes4(0x30e4191c)) {
                // 0x30e4191c = selector for custom error AvoCore__OutOfGas()
                revertReason_ = "AVO__OUT_OF_GAS";
            } else {
                assembly {
                    result_ := add(result_, 0x04)
                }
                revertReason_ = abi.decode(result_, (string));
            }
        }
    }

    /// @dev executes `actions_` with respective target, calldata, operation etc.
    /// IMPORTANT: Validation of `id_` and `_status` is expected to happen in `executeOperation()` and `_callTargets()`.
    /// catches out of gas errors (as well as possible), reverting with `AvoCore__OutOfGas()`.
    /// reverts with action index + error code in case of failure (e.g. "1_SOME_ERROR").
    function _executeActions(Action[] memory actions_, uint256 id_, bool isFlashloanCallback_) internal {
        // reset status immediately to avert reentrancy etc.
        _status = 0;

        uint256 storageSlot0Snapshot_;
        uint256 storageSlot1Snapshot_;
        uint256 storageSlot54Snapshot_;
        // delegate call = ids 1 and 21
        if (id_ == 1 || id_ == 21) {
            // store values before execution to make sure core storage vars are not modified by a delegatecall.
            // this ensures the smart wallet does not end up in a corrupted state.
            // for mappings etc. it is hard to protect against storage changes, so we must rely on the owner / signer
            // to know what is being triggered and the effects of a tx
            assembly {
                storageSlot0Snapshot_ := sload(0x0) // avoImpl, nonce, status
                storageSlot1Snapshot_ := sload(0x1) // owner, _initialized, _initializing
            }

            if (IS_MULTISIG) {
                assembly {
                    storageSlot54Snapshot_ := sload(0x36) // storage slot 54 related variables such as signers for Multisig
                }
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

                (success_, result_) = action_.target.call{ value: action_.value }(action_.data);
            } else if (action_.operation == 1 && storageSlot0Snapshot_ > 0) {
                // delegatecall (operation = 1 & id = mixed(1 / 21))
                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    // -> as close as possible to actual call
                    actionMinGasLeft_ = gasleft() / 64;
                }

                // storageSlot0Snapshot_ is only set if id is set for a delegateCall
                (success_, result_) = action_.target.delegatecall(action_.data);
            } else if (action_.operation == 2 && (id_ == 20 || id_ == 21)) {
                // flashloan (operation = 2 & id = flashloan(20 / 21))
                if (isFlashloanCallback_) {
                    revert(string.concat(Strings.toString(i), "_AVO__NO_FLASHLOAN_IN_FLASHLOAN"));
                }
                // flashloan is always executed via .call, flashloan aggregator uses `msg.sender`, so .delegatecall
                // wouldn't send funds to this contract but rather to the original sender.

                // store `id_` temporarily as `_status` as flag to allow the flashloan callback (`executeOperation()`)
                _status = uint8(id_);

                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    // -> as close as possible to actual call
                    actionMinGasLeft_ = gasleft() / 64;
                }

                (success_, result_) = action_.target.call{ value: action_.value }(action_.data);

                // reset _status flag to 0 in all cases. cost 200 gas
                _status = 0;
            } else {
                // either operation does not exist or the id was not set according to what the action wants to execute
                if (action_.operation > 2) {
                    revert(string.concat(Strings.toString(i), "_AVO__OPERATION_NOT_EXIST"));
                } else {
                    // enforce that id must be set according to operation
                    revert(string.concat(Strings.toString(i), "_AVO__ID_ACTION_MISMATCH"));
                }
            }

            if (!success_) {
                if (gasleft() < actionMinGasLeft_) {
                    // action ran out of gas, trigger revert with specific custom error
                    revert AvoCore__OutOfGas();
                }

                revert(string.concat(Strings.toString(i), _getRevertReasonFromReturnedData(result_)));
            }

            unchecked {
                ++i;
            }
        }

        // if actions include delegatecall (if snapshot is set), make sure storage was not modified
        if (storageSlot0Snapshot_ > 0) {
            uint256 storageSlot0_;
            uint256 storageSlot1_;
            assembly {
                storageSlot0_ := sload(0x0)
                storageSlot1_ := sload(0x1)
            }

            uint256 storageSlot54_;
            if (IS_MULTISIG) {
                assembly {
                    storageSlot54_ := sload(0x36) // storage slot 54 related variables such as signers for Multisig
                }
            }

            if (
                !(storageSlot0_ == storageSlot0Snapshot_ &&
                    storageSlot1_ == storageSlot1Snapshot_ &&
                    storageSlot54_ == storageSlot54Snapshot_)
            ) {
                revert("AVO__MODIFIED_STORAGE");
            }
        }
    }

    /// @dev                   Validates input params, reverts on invalid values.
    /// @param actionsLength_  the length of the actions array to execute
    /// @param avoSafeNonce_   the avoSafeNonce from input CastParams
    /// @param validAfter_     timestamp after which the request is valid
    /// @param validUntil_     timestamp before which the request is valid
    function _validateParams(
        uint256 actionsLength_,
        int256 avoSafeNonce_,
        uint256 validAfter_,
        uint256 validUntil_
    ) internal view {
        // make sure actions are defined and nonce is valid:
        // must be -1 to use a non-sequential nonce or otherwise it must match the avoSafeNonce
        if (!(actionsLength_ > 0 && (avoSafeNonce_ == -1 || uint256(avoSafeNonce_) == avoSafeNonce))) {
            revert AvoCore__InvalidParams();
        }

        // make sure request is within valid timeframe
        if ((validAfter_ > 0 && validAfter_ > block.timestamp) || (validUntil_ > 0 && validUntil_ < block.timestamp)) {
            revert AvoCore__InvalidTiming();
        }
    }

    /// @dev pays the fee for `castAuthorized()` calls via the AvoVersionsRegistry (or fallback)
    /// @param gasUsedFrom_ `gasleft()` snapshot at gas measurement starting point
    /// @param maxFee_      maximum acceptable fee to be paid, revert if fee is bigger than this value
    function _payAuthorizedFee(uint256 gasUsedFrom_, uint256 maxFee_) internal {
        // @dev part below costs ~24k gas for if `feeAmount_` and `maxFee_` is set
        uint256 feeAmount_;
        address payable feeCollector_;
        {
            uint256 gasUsed_;
            unchecked {
                // gas can not underflow
                // gasUsed already includes everything at this point except for paying fee logic
                gasUsed_ = gasUsedFrom_ - gasleft();
            }

            // Using a low-level function call to prevent reverts (making sure the contract is truly non-custodial)
            (bool success_, bytes memory result_) = address(avoVersionsRegistry).staticcall(
                abi.encodeWithSignature("calcFee(uint256)", gasUsed_)
            );

            if (success_) {
                (feeAmount_, feeCollector_) = abi.decode(result_, (uint256, address));
                if (feeAmount_ > AUTHORIZED_MAX_FEE) {
                    // make sure AvoVersionsRegistry fee is capped
                    feeAmount_ = AUTHORIZED_MAX_FEE;
                }
            } else {
                // registry calcFee failed. Use local backup minimum fee
                feeCollector_ = AUTHORIZED_FEE_COLLECTOR;
                feeAmount_ = AUTHORIZED_MIN_FEE;
            }
        }

        // pay fee, if any
        if (feeAmount_ > 0) {
            if (maxFee_ > 0 && feeAmount_ > maxFee_) {
                revert AvoCore__MaxFee(feeAmount_, maxFee_);
            }

            // sending fee based on OZ Address.sendValue, but modified to properly act based on actual error case
            // (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/utils/Address.sol#L60)
            if (address(this).balance < feeAmount_) {
                revert AvoCore__InsufficientBalance(feeAmount_);
            }

            // send along enough gas (22_000) to make any gas griefing attacks impossible. This should be enough for any
            // normal transfer to an EOA or an Avocado Multisig
            (bool success_, ) = feeCollector_.call{ value: feeAmount_, gas: 22_000 }("");

            if (success_) {
                emit FeePaid(feeAmount_);
            } else {
                // do not revert, as an error on the feeCollector_ side should not be the "fault" of the Avo contract.
                // Letting this case pass ensures that the contract is truly non-custodial (not blockable by feeCollector)
                emit FeePayFailed(feeAmount_);
            }
        } else {
            emit FeePaid(feeAmount_);
        }
    }

    /// @notice                  gets the digest (hash) used to verify an EIP712 signature
    /// @param params_           Cast params such as id, avoSafeNonce and actions to execute
    /// @param functionTypeHash_ whole function type hash, e.g. CAST_TYPE_HASH or CAST_AUTHORIZED_TYPE_HASH
    /// @param customStructHash_ struct hash added after CastParams hash, e.g. CastForwardParams or CastAuthorizedParams hash
    /// @return                  bytes32 digest e.g. for signature or non-sequential nonce
    function _getSigDigest(
        CastParams memory params_,
        bytes32 functionTypeHash_,
        bytes32 customStructHash_
    ) internal view returns (bytes32) {
        bytes32[] memory keccakActions_;

        {
            // get keccak256s for actions
            uint256 actionsLength_ = params_.actions.length;
            keccakActions_ = new bytes32[](actionsLength_);
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
        }

        return
            ECDSA.toTypedDataHash(
                // domain separator
                _domainSeparatorV4(),
                // structHash
                keccak256(
                    abi.encode(
                        functionTypeHash_,
                        // CastParams hash
                        keccak256(
                            abi.encode(
                                CAST_PARAMS_TYPE_HASH,
                                // actions
                                keccak256(abi.encodePacked(keccakActions_)),
                                params_.id,
                                params_.avoSafeNonce,
                                params_.salt,
                                params_.source,
                                keccak256(params_.metadata)
                            )
                        ),
                        // CastForwardParams or CastAuthorizedParams hash
                        customStructHash_
                    )
                )
            );
    }

    /// @notice Returns the domain separator for the chain with id `DEFAULT_CHAIN_ID`
    function _domainSeparatorV4() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TYPE_HASH,
                    DOMAIN_SEPARATOR_NAME_HASHED,
                    DOMAIN_SEPARATOR_VERSION_HASHED,
                    DEFAULT_CHAIN_ID,
                    address(this),
                    keccak256(abi.encodePacked(block.chainid)) // in salt: ensure tx replay is not possible
                )
            );
    }

    /// @dev Get the revert reason from the returnedData (supports Panic, Error & Custom Errors).
    /// Based on https://github.com/superfluid-finance/protocol-monorepo/blob/dev/packages/ethereum-contracts/contracts/libs/CallUtils.sol
    /// This is needed in order to provide some human-readable revert message from a call.
    /// @param returnedData_ revert data of the call
    /// @return reason_      revert reason
    function _getRevertReasonFromReturnedData(
        bytes memory returnedData_
    ) internal pure returns (string memory reason_) {
        if (returnedData_.length < 4) {
            // case 1: catch all
            return "_REASON_NOT_DEFINED";
        } else {
            bytes4 errorSelector;
            assembly {
                errorSelector := mload(add(returnedData_, 0x20))
            }
            if (errorSelector == bytes4(0x4e487b71) /* `seth sig "Panic(uint256)"` */) {
                // case 2: Panic(uint256) (Defined since 0.8.0)
                // ref: https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require)
                reason_ = "_TARGET_PANICKED: 0x__";
                uint256 errorCode;
                assembly {
                    errorCode := mload(add(returnedData_, 0x24))
                    let reasonWord := mload(add(reason_, 0x20))
                    // [0..9] is converted to ['0'..'9']
                    // [0xa..0xf] is not correctly converted to ['a'..'f']
                    // but since panic code doesn't have those cases, we will ignore them for now!
                    let e1 := add(and(errorCode, 0xf), 0x30)
                    let e2 := shl(8, add(shr(4, and(errorCode, 0xf0)), 0x30))
                    reasonWord := or(
                        and(reasonWord, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000),
                        or(e2, e1)
                    )
                    mstore(add(reason_, 0x20), reasonWord)
                }
            } else {
                if (returnedData_.length > 68) {
                    // case 3: Error(string) (Defined at least since 0.7.0)
                    assembly {
                        returnedData_ := add(returnedData_, 0x04)
                    }
                    reason_ = string.concat("_", abi.decode(returnedData_, (string)));
                } else {
                    // case 4: Custom errors (Defined since 0.8.0)

                    // convert bytes4 selector to string
                    // based on https://ethereum.stackexchange.com/a/111876
                    bytes memory result = new bytes(10);
                    result[0] = bytes1("0");
                    result[1] = bytes1("x");
                    for (uint256 i; i < 4; ) {
                        result[2 * i + 2] = _toHexDigit(uint8(errorSelector[i]) / 16);
                        result[2 * i + 3] = _toHexDigit(uint8(errorSelector[i]) % 16);

                        unchecked {
                            ++i;
                        }
                    }

                    reason_ = string.concat("_CUSTOM_ERROR:", string(result));
                }
            }
        }
    }

    /// @dev used to convert bytes4 selector to string
    function _toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        revert();
    }
}

abstract contract AvoCoreEIP1271 is AvoCore {
    /// @inheritdoc IERC1271
    function isValidSignature(bytes32 hash, bytes calldata signature) external view virtual returns (bytes4 magicValue);

    /// @notice Marks a bytes32 `message_` (signature digest) as signed, making it verifiable by EIP-1271 `isValidSignature()`.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param message_ data hash to be allow-listed as signed
    function signMessage(bytes32 message_) external onlySelf {
        _signedMessages[message_] = 1;

        emit SignedMessage(message_);
    }

    /// @notice Removes a previously `signMessage()` signed bytes32 `message_` (signature digest).
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param message_ data hash to be removed from allow-listed signatures
    function removeSignedMessage(bytes32 message_) external onlySelf {
        _signedMessages[message_] = 0;

        emit RemoveSignedMessage(message_);
    }
}

/// @dev Simple contract to upgrade the implementation address stored at storage slot 0x0.
///      Mostly based on OpenZeppelin ERC1967Upgrade contract, adapted with onlySelf etc.
///      IMPORTANT: For any new implementation, the upgrade method MUST be in the implementation itself,
///      otherwise it can not be upgraded anymore!
abstract contract AvoCoreSelfUpgradeable is AvoCore {
    /// @notice upgrade the contract to a new implementation address.
    ///         - Must be a valid version at the AvoVersionsRegistry.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param avoImplementation_   New contract address
    function upgradeTo(address avoImplementation_) public virtual;

    /// @notice upgrade the contract to a new implementation address and call a function afterwards.
    ///         - Must be a valid version at the AvoVersionsRegistry.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param avoImplementation_   New contract address
    /// @param data_                callData for function call on avoImplementation_ after upgrading
    /// @param forceCall_           optional flag to force send call even if callData (data_) is empty
    function upgradeToAndCall(
        address avoImplementation_,
        bytes calldata data_,
        bool forceCall_
    ) external payable virtual onlySelf {
        upgradeTo(avoImplementation_);
        if (data_.length > 0 || forceCall_) {
            Address.functionDelegateCall(avoImplementation_, data_);
        }
    }
}

abstract contract AvoCoreProtected is AvoCore {
    /***********************************|
    |             ONLY SELF             |
    |__________________________________*/

    /// @notice occupies the sequential `avoSafeNonces_` in storage. This can be used to cancel / invalidate
    ///         a previously signed request(s) because the nonce will be "used" up.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param  avoSafeNonces_ sequential ascending ordered nonces to be occupied in storage.
    ///         E.g. if current AvoSafeNonce is 77 and txs are queued with avoSafeNonces 77, 78 and 79,
    ///         then you would submit [78, 79] here because 77 will be occupied by the tx executing
    ///         `occupyAvoSafeNonces()` as an action itself. If executing via non-sequential nonces, you would
    ///         submit [77, 78, 79].
    ///         - Maximum array length is 5.
    ///         - gap from the current avoSafeNonce will revert (e.g. [79, 80] if current one is 77)
    function occupyAvoSafeNonces(uint88[] calldata avoSafeNonces_) external onlySelf {
        uint256 avoSafeNoncesLength_ = avoSafeNonces_.length;
        if (avoSafeNoncesLength_ == 0) {
            // in case to cancel just one nonce via normal sequential nonce execution itself
            return;
        }

        if (avoSafeNoncesLength_ > 5) {
            revert AvoCore__InvalidParams();
        }

        uint256 nextAvoSafeNonce_ = avoSafeNonce;

        for (uint256 i; i < avoSafeNoncesLength_; ) {
            if (avoSafeNonces_[i] == nextAvoSafeNonce_) {
                // nonce to occupy is valid -> must match the current avoSafeNonce
                emit AvoSafeNonceOccupied(nextAvoSafeNonce_);
                nextAvoSafeNonce_++;
            } else if (avoSafeNonces_[i] > nextAvoSafeNonce_) {
                // input nonce is not smaller or equal current nonce -> invalid sorted ascending input params
                revert AvoCore__InvalidParams();
            }
            // else while nonce to occupy is < current nonce, skip ahead

            unchecked {
                ++i;
            }
        }

        avoSafeNonce = uint88(nextAvoSafeNonce_);
    }

    /// @notice occupies the `nonSequentialNonces_` in storage. This can be used to cancel / invalidate
    ///         previously signed request(s) because the nonce will be "used" up.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param  nonSequentialNonces_ the non-sequential nonces to occupy
    function occupyNonSequentialNonces(bytes32[] calldata nonSequentialNonces_) external onlySelf {
        uint256 nonSequentialNoncesLength_ = nonSequentialNonces_.length;

        for (uint256 i; i < nonSequentialNoncesLength_; ) {
            nonSequentialNonces[nonSequentialNonces_[i]] = 1;

            emit NonSequentialNonceOccupied(nonSequentialNonces_[i]);

            unchecked {
                ++i;
            }
        }
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
        uint256 status_ = _status;

        // @dev using the valid case inverted via one ! instead of invalid case with 3 ! to optimize gas usage
        if (!((status_ == 20 || status_ == 21) && initiator_ == address(this))) {
            revert AvoCore__Unauthorized();
        }

        _executeActions(
            // decode actions to be executed after getting the flashloan
            abi.decode(data_, (Action[])),
            // _status is set to `CastParams.id` pre-flashloan trigger in `_executeActions()`
            status_,
            true
        );

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
        // status must be verified or 0x000000000000000000000000000000000000dEaD used for backend gas estimations
        if (!(_status == 1 || tx.origin == 0x000000000000000000000000000000000000dEaD)) {
            revert AvoCore__Unauthorized();
        }

        _executeActions(actions_, id_, false);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

abstract contract AvoCoreErrors {
    /// @notice thrown when a signature has expired or when a request isn't valid yet
    error AvoCore__InvalidTiming();

    /// @notice thrown when someone is trying to execute a in some way auth protected logic
    error AvoCore__Unauthorized();

    /// @notice thrown when actions execution runs out of gas
    error AvoCore__OutOfGas();

    /// @notice thrown when a method is called with invalid params (e.g. a zero address as input param)
    error AvoCore__InvalidParams();

    /// @notice thrown when an EIP1271 signature is invalid
    error AvoCore__InvalidEIP1271Signature();

    /// @notice thrown when a `castAuthorized()` `fee` is bigger than the `maxFee` given through the input param
    error AvoCore__MaxFee(uint256 fee, uint256 maxFee);

    /// @notice thrown when `castAuthorized()` fee can not be covered by available contract funds
    error AvoCore__InsufficientBalance(uint256 fee);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

abstract contract AvoCoreEvents {
    /// @notice Emitted when the implementation is upgraded to a new logic contract
    event Upgraded(address indexed newImplementation);

    /// @notice Emitted when a message is marked as allowed smart contract signature
    event SignedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a previously allowed signed message is removed
    event RemoveSignedMessage(bytes32 indexed messageHash);

    /// @notice emitted when the avoSafeNonce in storage is increased through an authorized call to
    /// `occupyAvoSafeNonces()`, which can be used to cancel a previously signed request
    event AvoSafeNonceOccupied(uint256 indexed occupiedAvoSafeNonce);

    /// @notice emitted when a non-sequential nonce is occupied in storage through an authorized call to
    /// `useNonSequentialNonces()`, which can be used to cancel a previously signed request
    event NonSequentialNonceOccupied(bytes32 indexed occupiedNonSequentialNonce);

    /// @notice Emitted when a fee is paid through use of the `castAuthorized()` method
    event FeePaid(uint256 indexed fee);

    /// @notice Emitted when paying a fee reverts at the recipient
    event FeePayFailed(uint256 indexed fee);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface AvoCoreStructs {
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
        /// @param avoSafeNonce   Required:
        ///                       avoSafeNonce to be used for this tx. Must equal the avoSafeNonce value on smart
        ///                       wallet or alternatively it must be set to -1 to use a non-sequential nonce instead
        int256 avoSafeNonce;
        ///
        /// @param salt           Optional:
        ///                       Salt to customize non-sequential nonce (if `avoSafeNonce` is set to -1)
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
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig.
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       can be forwarded, or 0 if request should be valid forever.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig.
        uint256 validUntil;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { AvoCoreErrors } from "./AvoCoreErrors.sol";
import { IAvoVersionsRegistry } from "../interfaces/IAvoVersionsRegistry.sol";
import { IAvoAuthoritiesList } from "../interfaces/IAvoAuthoritiesList.sol";

// --------------------------- DEVELOPER NOTES -----------------------------------------
// @dev IMPORTANT: Contracts using AvoCore must inherit this contract and define the immutables
// -------------------------------------------------------------------------------------
abstract contract AvoCoreConstantsOverride is AvoCoreErrors {
    // @dev: MUST SET DOMAIN_SEPARATOR_NAME & DOMAIN_SEPARATOR_VERSION IN CONTRACTS USING AvoCore.
    // Solidity offers no good way to create this inheritance or forcing implementation without increasing gas cost:
    // strings are not supported as immutable.
    // string public constant DOMAIN_SEPARATOR_NAME = "Avocado-Safe";
    // string public constant DOMAIN_SEPARATOR_VERSION = "3.0.0";

    // hashed EIP712 values
    bytes32 internal immutable DOMAIN_SEPARATOR_NAME_HASHED;
    bytes32 internal immutable DOMAIN_SEPARATOR_VERSION_HASHED;

    /// @dev amount of gas to keep in castAuthorized caller method as reserve for emitting event + paying fee
    uint256 internal immutable CAST_AUTHORIZED_RESERVE_GAS;
    /// @dev amount of gas to keep in cast caller method as reserve for emitting CastFailed / CastExecuted event
    uint256 internal immutable CAST_EVENTS_RESERVE_GAS;

    /// @dev flag for internal use to detect if current AvoCore is multisig logic
    bool internal immutable IS_MULTISIG;

    /// @dev minimum fee for fee charged via `castAuthorized()` to charge if `AvoVersionsRegistry.calcFee()` would fail
    uint256 public immutable AUTHORIZED_MIN_FEE;
    /// @dev global maximum for fee charged via `castAuthorized()`. If AvoVersionsRegistry returns a fee higher than this,
    /// then MAX_AUTHORIZED_FEE is charged as fee instead (capping)
    uint256 public immutable AUTHORIZED_MAX_FEE;
    /// @dev address that the fee charged via `castAuthorized()` is sent to in the fallback case
    address payable public immutable AUTHORIZED_FEE_COLLECTOR;

    constructor(
        string memory domainSeparatorName_,
        string memory domainSeparatorVersion_,
        uint256 castAuthorizedReserveGas_,
        uint256 castEventsReserveGas_,
        uint256 authorizedMinFee_,
        uint256 authorizedMaxFee_,
        address authorizedFeeCollector_,
        bool isMultisig
    ) {
        DOMAIN_SEPARATOR_NAME_HASHED = keccak256(bytes(domainSeparatorName_));
        DOMAIN_SEPARATOR_VERSION_HASHED = keccak256(bytes(domainSeparatorVersion_));

        CAST_AUTHORIZED_RESERVE_GAS = castAuthorizedReserveGas_;
        CAST_EVENTS_RESERVE_GAS = castEventsReserveGas_;

        // min & max fee settings, fee collector adress are required
        if (
            authorizedMinFee_ == 0 ||
            authorizedMaxFee_ == 0 ||
            authorizedFeeCollector_ == address(0) ||
            authorizedMinFee_ > authorizedMaxFee_
        ) {
            revert AvoCore__InvalidParams();
        }

        AUTHORIZED_MIN_FEE = authorizedMinFee_;
        AUTHORIZED_MAX_FEE = authorizedMaxFee_;
        AUTHORIZED_FEE_COLLECTOR = payable(authorizedFeeCollector_);

        IS_MULTISIG = isMultisig;
    }
}

abstract contract AvoCoreConstants is AvoCoreErrors {
    /***********************************|
    |              CONSTANTS            |
    |__________________________________*/

    /// @notice overwrite chain id for EIP712 is always set to 63400 for the Avocado RPC / network
    uint256 public constant DEFAULT_CHAIN_ID = 63400;

    /// @notice _TYPE_HASH is copied from OpenZeppelin EIP712 but with added salt as last param (we use it for `block.chainid`)
    bytes32 public constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");

    /// @notice EIP712 typehash for `cast()` calls, including structs
    bytes32 public constant CAST_TYPE_HASH =
        keccak256(
            "Cast(CastParams params,CastForwardParams forwardParams)Action(address target,bytes data,uint256 value,uint256 operation)CastForwardParams(uint256 gas,uint256 gasPrice,uint256 validAfter,uint256 validUntil)CastParams(Action[] actions,uint256 id,int256 avoSafeNonce,bytes32 salt,address source,bytes metadata)"
        );

    /// @notice EIP712 typehash for Action struct
    bytes32 public constant ACTION_TYPE_HASH =
        keccak256("Action(address target,bytes data,uint256 value,uint256 operation)");

    /// @notice EIP712 typehash for CastParams struct
    bytes32 public constant CAST_PARAMS_TYPE_HASH =
        keccak256(
            "CastParams(Action[] actions,uint256 id,int256 avoSafeNonce,bytes32 salt,address source,bytes metadata)Action(address target,bytes data,uint256 value,uint256 operation)"
        );
    /// @notice EIP712 typehash for CastForwardParams struct
    bytes32 public constant CAST_FORWARD_PARAMS_TYPE_HASH =
        keccak256("CastForwardParams(uint256 gas,uint256 gasPrice,uint256 validAfter,uint256 validUntil)");

    /// @dev "magic value" according to EIP1271 https://eips.ethereum.org/EIPS/eip-1271#specification
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x1626ba7e;

    /// @notice EIP712 typehash for `castAuthorized()` calls, including structs
    bytes32 public constant CAST_AUTHORIZED_TYPE_HASH =
        keccak256(
            "CastAuthorized(CastParams params,CastAuthorizedParams authorizedParams)Action(address target,bytes data,uint256 value,uint256 operation)CastAuthorizedParams(uint256 maxFee,uint256 gasPrice,uint256 validAfter,uint256 validUntil)CastParams(Action[] actions,uint256 id,int256 avoSafeNonce,bytes32 salt,address source,bytes metadata)"
        );

    /// @notice EIP712 typehash for CastAuthorizedParams struct
    bytes32 public constant CAST_AUTHORIZED_PARAMS_TYPE_HASH =
        keccak256("CastAuthorizedParams(uint256 maxFee,uint256 gasPrice,uint256 validAfter,uint256 validUntil)");

    /***********************************|
    |             IMMUTABLES            |
    |__________________________________*/

    /// @notice  registry holding the valid versions (addresses) for Avocado smart wallet implementation contracts
    ///          The registry is used to verify a valid version before upgrading & to pay fees for `castAuthorized()`
    IAvoVersionsRegistry public immutable avoVersionsRegistry;

    /// @notice address of the AvoForwarder (proxy) that is allowed to forward tx with valid signatures
    address public immutable avoForwarder;

    /***********************************|
    |            CONSTRUCTOR            |
    |__________________________________*/

    constructor(IAvoVersionsRegistry avoVersionsRegistry_, address avoForwarder_) {
        if (address(avoVersionsRegistry_) == address(0)) {
            revert AvoCore__InvalidParams();
        }
        avoVersionsRegistry = avoVersionsRegistry_;

        avoVersionsRegistry.requireValidAvoForwarderVersion(avoForwarder_);
        avoForwarder = avoForwarder_;
    }
}

abstract contract AvoCoreVariablesSlot0 {
    /// @notice address of the smart wallet logic / implementation contract.
    //  @dev    IMPORTANT: SAME STORAGE SLOT AS FOR PROXY. DO NOT MOVE THIS VARIABLE.
    //         _avoImplementation MUST ALWAYS be the first declared variable here in the logic contract and in the proxy!
    //         When upgrading, the storage at memory address 0x0 is upgraded (first slot).
    //         Note immutable and constants do not take up storage slots so they can come before.
    address internal _avoImplementation;

    /// @notice nonce that is incremented for every `cast` / `castAuthorized` transaction (unless it uses a non-sequential nonce)
    uint88 public avoSafeNonce;

    /// @dev flag set temporarily to signal various cases:
    /// 0 -> default state
    /// 1 -> triggered request had valid signatures, `_callTargets` can be executed
    /// 20 / 21 -> flashloan receive can be executed (set to original `CastParams.id` input param)
    uint8 internal _status;
}

abstract contract AvoCoreVariablesSlot1 {
    /// @notice owner of the Avocado smart wallet
    //  @dev theoretically immutable, can only be set in initialize (at proxy clone AvoFactory deployment)
    address public owner;

    /// @dev Initializable.sol variables (modified from OpenZeppelin), see ./lib folder
    /// @dev Indicates that the contract has been initialized.
    uint8 internal _initialized;
    /// @dev Indicates that the contract is in the process of being initialized.
    bool internal _initializing;

    // 10 bytes empty
}

abstract contract AvoCoreVariablesSlot2 {
    // contracts deployed before V2 contain two more variables from EIP712Upgradeable: hashed domain separator
    // name and version which were set at initialization (Now we do this in logic contract at deployment as constant)
    // https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/cryptography/EIP712Upgradeable.sol#L32

    // BEFORE VERSION 2.0.0:
    // bytes32 private _HASHED_NAME;

    /// @dev allow-listed signed messages, e.g. for Permit2 Uniswap interaction
    /// mappings are not in sequential storage slot, thus not influenced by previous storage variables
    /// (but consider the slot number in calculating the hash of the key to store).
    mapping(bytes32 => uint256) internal _signedMessages;
}

abstract contract AvoCoreVariablesSlot3 {
    // BEFORE VERSION 2.0.0:
    // bytes32 private _HASHED_VERSION; see comment in storage slot 2

    /// @notice used non-sequential nonces (which can not be used again)
    mapping(bytes32 => uint256) public nonSequentialNonces;
}

abstract contract AvoCoreSlotGaps {
    // create some storage slot gaps for future expansion of AvoCore variables before the customized variables
    // of AvoWallet & AvoMultisig
    uint256[50] private __gaps;
}

abstract contract AvoCoreVariables is
    AvoCoreConstants,
    AvoCoreConstantsOverride,
    AvoCoreVariablesSlot0,
    AvoCoreVariablesSlot1,
    AvoCoreVariablesSlot2,
    AvoCoreVariablesSlot3,
    AvoCoreSlotGaps
{}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { AvoCoreVariables } from "../AvoCoreVariables.sol";

/// @dev contract copied from OpenZeppelin Initializable but with storage vars moved to AvoCoreVariables.sol
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
abstract contract Initializable is AvoCoreVariables {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    // uint8 private _initialized; // -> in AvoCoreVariables

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    // bool private _initializing; // -> in AvoCoreVariables

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
pragma solidity >=0.8.17;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";

import { IAvoVersionsRegistry } from "../interfaces/IAvoVersionsRegistry.sol";
import { IAvoSignersList } from "../interfaces/IAvoSignersList.sol";
import { AvoCore, AvoCoreEIP1271, AvoCoreSelfUpgradeable, AvoCoreProtected } from "../AvoCore/AvoCore.sol";
import { IAvoMultisigV3Base } from "../interfaces/IAvoMultisigV3.sol";
import { AvoMultisigVariables } from "./AvoMultisigVariables.sol";
import { AvoMultisigEvents } from "./AvoMultisigEvents.sol";
import { AvoMultisigErrors } from "./AvoMultisigErrors.sol";

// --------------------------- DEVELOPER NOTES -----------------------------------------
// @dev IMPORTANT: all storage variables go into AvoMultisigVariables.sol
// -------------------------------------------------------------------------------------

// empty interface used for Natspec docs for nice layout in automatically generated docs:
//
/// @title  AvoMultisig v3.0.0
/// @notice Smart wallet enabling meta transactions through multiple EIP712 signatures (Multisig n out of m).
///
/// Supports:
/// - Executing arbitrary actions
/// - Receiving NFTs (ERC721)
/// - Receiving ERC1155 tokens
/// - ERC1271 smart contract signatures
/// - Instadapp Flashloan callbacks
///
/// The `cast` method allows the AvoForwarder (relayer) to execute multiple arbitrary actions authorized by signature.
///
/// Broadcasters are expected to call the AvoForwarder contract `execute()` method, which also automatically
/// deploys an AvoMultisig if necessary first.
///
/// Upgradeable by calling `upgradeTo` (or `upgradeToAndCall`) through a `cast` / `castAuthorized` call.
///
/// The `castAuthorized` method allows the signers of the wallet to execute multiple arbitrary actions with signatures
/// without the AvoForwarder in between, to guarantee the smart wallet is truly non-custodial.
///
/// [email protected] Notes:_
/// - This contract implements parts of EIP-2770 in a minimized form. E.g. domainSeparator is immutable etc.
/// - This contract does not implement ERC2771, because trusting an upgradeable "forwarder" bears a security
/// risk for this non-custodial wallet.
/// - Signature related logic is based off of OpenZeppelin EIP712Upgradeable.
/// - All signatures are validated for defaultChainId of `63400` instead of `block.chainid` from opcode (EIP-1344).
/// - For replay protection, the current `block.chainid` instead is used in the EIP-712 salt.
interface AvoMultisig_V3 {

}

abstract contract AvoMultisigCore is
    AvoMultisigErrors,
    AvoMultisigVariables,
    AvoCore,
    AvoMultisigEvents,
    IAvoMultisigV3Base
{
    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    constructor(
        IAvoVersionsRegistry avoVersionsRegistry_,
        address avoForwarder_,
        IAvoSignersList avoSignersList_,
        uint256 authorizedMinFee_,
        uint256 authorizedMaxFee_,
        address authorizedFeeCollector_
    )
        AvoMultisigVariables(
            avoVersionsRegistry_,
            avoForwarder_,
            avoSignersList_,
            authorizedMinFee_,
            authorizedMaxFee_,
            authorizedFeeCollector_
        )
    {
        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /// @dev sets the initial state of the Multisig for `owner_` as owner and first and only required signer
    function _initialize(address owner_) internal {
        _initializeOwner(owner_);

        // set initial signers state
        requiredSigners = 1;
        address[] memory signers_ = new address[](1);
        signers_[0] = owner_;
        _setSigners(signers_); // also updates signersCount

        emit SignerAdded(owner_);

        // add owner as signer at AvoSignersList
        avoSignersList.syncAddAvoSignerMappings(address(this), signers_);
    }

    /***********************************|
    |               INTERNAL            |
    |__________________________________*/

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
    /// @param  isNonSequentialNonce_ flag to sginal verify with non sequential nonce or not
    /// @return isValid_              true if the signature is valid, false otherwise
    /// @return recoveredSigners_     recovered valid signer addresses of the signatures. In case that `isValid_` is
    ///                               false, the last element in the array with a value is the invalid signer
    function _verifySig(
        bytes32 digest_,
        SignatureParams[] memory signaturesParams_,
        bool isNonSequentialNonce_
    ) internal view returns (bool isValid_, address[] memory recoveredSigners_) {
        uint256 signaturesLength_ = signaturesParams_.length;

        if (
            // enough signatures must be submitted to reach quorom of `requiredSigners`
            signaturesLength_ < requiredSigners ||
            // for non sequential nonce, if nonce is already used, the signature has already been used and is invalid
            (isNonSequentialNonce_ && nonSequentialNonces[digest_] == 1)
        ) {
            revert AvoMultisig__InvalidParams();
        }

        // fill recovered signers array for use in event emit
        recoveredSigners_ = new address[](signaturesLength_);

        // get current signers from storage
        address[] memory allowedSigners_ = _getSigners(); // includes owner
        uint256 allowedSignersLength_ = allowedSigners_.length;
        // track last allowed signer index for loop performance improvements
        uint256 lastAllowedSignerIndex_;

        bool isContract_; // keeping this variable outside the loop so it is not re-initialized in each loop -> cheaper
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
                    revert AvoMultisig__InvalidParams();
                }
            }

            bool isAllowedSigner_;
            // because signers in storage and signers from signatures input params must be ordered ascending,
            // the for loop can be optimized each new cycle to start from the position where the last signer
            // has been found.
            // this also ensures that input params signers must be ordered ascending off-chain
            // (which again is used to improve performance and simplifies ensuring unique signers)
            for (uint256 j = lastAllowedSignerIndex_; j < allowedSignersLength_; ) {
                if (allowedSigners_[j] == recoveredSigners_[i]) {
                    isAllowedSigner_ = true;
                    lastAllowedSignerIndex_ = j + 1; // set to j+1 so that next cycle starts at next array position
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
}

abstract contract AvoMultisigEIP1271 is AvoCoreEIP1271, AvoMultisigCore {
    /// @inheritdoc IERC1271
    /// @param signature This can be one of the following:
    ///         - empty: `hash` must be a previously signed message in storage then.
    ///         - a multiple of 85 bytes, through grouping of 65 bytes signature + 20 bytes signer address each.
    ///           To signal decoding this way, the signature bytes must be prefixed with `0xDEC0DE6520`.
    ///         - the `abi.encode` result for `SignatureParams` struct array.
    /// @dev reverts with `AvoCore__InvalidEIP1271Signature` or `AvoMultisig__InvalidParams` if signature is invalid.
    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    ) external view override(AvoCoreEIP1271, IERC1271) returns (bytes4 magicValue) {
        // @dev function params without _ for inheritdoc
        if (signature.length == 0) {
            // must be pre-allow-listed via `signMessage` method
            if (_signedMessages[hash] != 1) {
                revert AvoCore__InvalidEIP1271Signature();
            }
        } else {
            // decode signaturesParams_ from bytes signature
            SignatureParams[] memory signaturesParams_;

            uint256 signatureLength_ = signature.length;

            if (signatureLength_ < 90) {
                revert AvoCore__InvalidEIP1271Signature();
            }

            // check if signature is prefixed with "0xDEC0DE6520" (appending 000000 to get to bytes8)
            if (bytes8(signature[0:5]) == bytes8(uint64(0xdec0de6520000000))) {
                // signature after the prefix should be divisible by 85
                // (65 bytes signature and 20 bytes signer address) each

                uint256 signaturesCount_ = (signatureLength_ - 5) / 85; // -5 to not count prefix
                signaturesParams_ = new SignatureParams[](signaturesCount_);

                for (uint256 i; i < signaturesCount_; ) {
                    uint256 signerOffset_ = (i * 85) + 65 + 5; // +5 to start after prefix

                    bytes memory signerBytes_ = signature[signerOffset_:signerOffset_ + 20];
                    address signer_;
                    // cast bytes to address in the easiest way via assembly
                    assembly {
                        signer_ := shr(96, mload(add(signerBytes_, 0x20)))
                    }

                    signaturesParams_[i] = SignatureParams({
                        signature: signature[(signerOffset_ - 65):signerOffset_],
                        signer: signer_
                    });

                    unchecked {
                        ++i;
                    }
                }
            } else {
                // multiple signatures are present that should form `SignatureParams[]` through abi.decode
                // @dev this will fail and revert if invalid typed data is passed in
                signaturesParams_ = abi.decode(signature, (SignatureParams[]));
            }

            (bool validSignature_, ) = _verifySig(
                hash,
                signaturesParams_,
                // we have no way to know nonce type, so make sure validity test covers everything.
                // setting this flag true will check that the digest is not a used non-sequential nonce.
                // unfortunately, for sequential nonces it adds unneeded verification and gas cost,
                // because the check will always pass, but there is no way around it.
                true
            );
            if (!validSignature_) {
                revert AvoCore__InvalidEIP1271Signature();
            }
        }

        return EIP1271_MAGIC_VALUE;
    }
}

/// @dev See contract AvoCoreSelfUpgradeable
abstract contract AvoMultisigSelfUpgradeable is AvoCoreSelfUpgradeable {
    /// @inheritdoc AvoCoreSelfUpgradeable
    function upgradeTo(address avoImplementation_) public override onlySelf {
        avoVersionsRegistry.requireValidAvoMultisigVersion(avoImplementation_);

        _avoImplementation = avoImplementation_;
        emit Upgraded(avoImplementation_);
    }
}

abstract contract AvoMultisigProtected is AvoCoreProtected {}

abstract contract AvoMultisigSigners is AvoMultisigCore {
    /// @inheritdoc IAvoMultisigV3Base
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

    /// @notice adds `addSigners_` to allowed signers
    /// Note the `addSigners_` to be added must:
    ///     - NOT be duplicates (already present in current allowed signers)
    ///     - NOT be the zero address
    ///     - be sorted ascending
    function addSigners(address[] calldata addSigners_) external onlySelf {
        uint256 addSignersLength_ = addSigners_.length;

        // check array length and make sure signers can not be zero address
        // (only check for first elem needed, rest is checked through sort)
        if (addSignersLength_ == 0 || addSigners_[0] == address(0)) {
            revert AvoMultisig__InvalidParams();
        }

        address[] memory currentSigners_ = _getSigners();
        uint256 currentSignersLength_ = currentSigners_.length;

        uint256 newSignersLength_ = currentSignersLength_ + addSignersLength_;
        if (newSignersLength_ > MAX_SIGNERS_COUNT) {
            revert AvoMultisig__InvalidParams();
        }
        address[] memory newSigners_ = new address[](newSignersLength_);

        uint256 currentSignersPos_; // index of position of loop in currentSigners_ array
        uint256 addedCount_; // keep track of number of added signers of current signers array
        for (uint256 i; i < newSignersLength_; ) {
            unchecked {
                currentSignersPos_ = i - addedCount_;
            }

            if (
                addedCount_ == addSignersLength_ ||
                (currentSignersPos_ < currentSignersLength_ &&
                    currentSigners_[currentSignersPos_] < addSigners_[addedCount_])
            ) {
                // if already added all signers or if current signer is <  next signer, keep the current one
                newSigners_[i] = currentSigners_[currentSignersPos_];
            } else {
                //  add signer
                newSigners_[i] = addSigners_[addedCount_];

                emit SignerAdded(addSigners_[addedCount_]);

                unchecked {
                    ++addedCount_;
                }
            }

            if (i > 0 && newSigners_[i] <= newSigners_[i - 1]) {
                // make sure input signers are ordered ascending and no duplicate signers are added
                revert AvoMultisig__InvalidParams();
            }

            unchecked {
                ++i;
            }
        }

        // update values in storage
        _setSigners(newSigners_); // automatically updates `signersCount`

        // sync mappings at AvoSignersList -> must happen *after* storage write update
        avoSignersList.syncAddAvoSignerMappings(address(this), addSigners_);
    }

    /// @notice removes `removeSigners_` from allowed signers
    /// Note the `removeSigners_` to be removed must:
    ///     - NOT be the owner
    ///     - be sorted ascending
    ///     - be present in current allowed signers
    function removeSigners(address[] calldata removeSigners_) external onlySelf {
        uint256 removeSignersLength_ = removeSigners_.length;
        if (removeSignersLength_ == 0) {
            revert AvoMultisig__InvalidParams();
        }

        address[] memory currentSigners_ = _getSigners();
        uint256 currentSignersLength_ = currentSigners_.length;

        uint256 newSignersLength_ = currentSignersLength_ - removeSignersLength_;
        if (newSignersLength_ < requiredSigners) {
            // ensure contract can not end up in an invalid state where requiredSigners > signersCount
            revert AvoMultisig__InvalidParams();
        }

        address owner_ = owner;

        address[] memory newSigners_ = new address[](newSignersLength_);

        uint256 currentInsertPos_; // index of position of loop in `newSigners_` array
        uint256 removedCount_; // keep track of number of removed signers of current signers array
        for (uint256 i; i < currentSignersLength_; ) {
            unchecked {
                currentInsertPos_ = i - removedCount_;
            }
            if (removedCount_ == removeSignersLength_ || currentSigners_[i] != removeSigners_[removedCount_]) {
                // if already removed all signers or if current signer is not a signer to be removed, keep the current one
                if (currentInsertPos_ < newSignersLength_) {
                    // make sure index to insert is within bounds of newSigners_ array
                    newSigners_[currentInsertPos_] = currentSigners_[i];
                } else {
                    // a signer has been passed in that was not found and thus we would be inserting at a position
                    // in newSigners_ array that overflows its length
                    revert AvoMultisig__InvalidParams();
                }
            } else {
                // remove signer, i.e. do not insert the current signer in the newSigners_ array

                // make sure signer to be removed is not the owner
                if (removeSigners_[removedCount_] == owner_) {
                    revert AvoMultisig__InvalidParams();
                }

                emit SignerRemoved(removeSigners_[removedCount_]);

                unchecked {
                    ++removedCount_;
                }
            }

            unchecked {
                ++i;
            }
        }

        if (removedCount_ != removeSignersLength_) {
            // this case should not be possible but it is a good cheap extra check to make sure nothing goes wrong
            // and the contract does not end up in an invalid signers state
            revert AvoMultisig__InvalidParams();
        }

        // update values in storage
        _setSigners(newSigners_); // automatically updates `signersCount`

        // sync mappings at AvoSignersList -> must happen *after* storage write update
        avoSignersList.syncRemoveAvoSignerMappings(address(this), removeSigners_);
    }

    /// @notice sets number of required signers for a valid request to `requiredSigners_`
    function setRequiredSigners(uint8 requiredSigners_) external onlySelf {
        // check if number of actual signers is > `requiredSigners_` because otherwise
        // the multisig would end up in a broken state where no execution is possible anymore
        if (requiredSigners_ == 0 || requiredSigners_ > signersCount) {
            revert AvoMultisig__InvalidParams();
        }

        requiredSigners = requiredSigners_;

        emit RequiredSignersSet(requiredSigners_);
    }
}

abstract contract AvoMultisigCast is AvoMultisigCore {
    /// @inheritdoc IAvoMultisigV3Base
    function getSigDigest(
        CastParams memory params_,
        CastForwardParams memory forwardParams_
    ) public view returns (bytes32) {
        return
            _getSigDigest(
                params_,
                CAST_TYPE_HASH,
                // CastForwardParams hash
                keccak256(
                    abi.encode(
                        CAST_FORWARD_PARAMS_TYPE_HASH,
                        forwardParams_.gas,
                        forwardParams_.gasPrice,
                        forwardParams_.validAfter,
                        forwardParams_.validUntil
                    )
                )
            );
    }

    /// @inheritdoc IAvoMultisigV3Base
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool) {
        _validateParams(
            params_.actions.length,
            params_.avoSafeNonce,
            forwardParams_.validAfter,
            forwardParams_.validUntil
        );

        (bool validSignature_, ) = _verifySig(
            getSigDigest(params_, forwardParams_),
            signaturesParams_,
            params_.avoSafeNonce == -1
        );

        // signature must be valid
        if (!validSignature_) {
            revert AvoMultisig__InvalidSignature();
        }

        return true;
    }

    /// @inheritdoc IAvoMultisigV3Base
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] memory signaturesParams_
    ) external payable returns (bool success_, string memory revertReason_) {
        {
            if (msg.sender != avoForwarder) {
                // sender must be the allowed AvoForwarder
                revert AvoMultisig__Unauthorized();
            }

            // compare actual sent gas to user instructed gas, adding 500 to `gasleft()` for approx. already used gas
            if ((gasleft() + 500) < forwardParams_.gas) {
                // relayer has not sent enough gas to cover gas limit as user instructed.
                // this error should not be blamed on the user but rather on the relayer
                revert AvoMultisig__InsufficientGasSent();
            }

            _validateParams(
                params_.actions.length,
                params_.avoSafeNonce,
                forwardParams_.validAfter,
                forwardParams_.validUntil
            );
        }

        bytes32 digest_ = getSigDigest(params_, forwardParams_);
        address[] memory signers_;
        {
            bool validSignature_;
            (validSignature_, signers_) = _verifySig(digest_, signaturesParams_, params_.avoSafeNonce == -1);

            // signature must be valid
            if (!validSignature_) {
                revert AvoMultisig__InvalidSignature();
            }
        }

        (success_, revertReason_) = _executeCast(
            params_,
            // the gas usage for the emitting the CastExecuted/CastFailed events depends on the signers count
            // the cost per signer is PER_SIGNER_RESERVE_GAS. We calculate this dynamically to ensure
            // enough reserve gas is reserved in Multisigs with a higher signersCount
            CAST_EVENTS_RESERVE_GAS + (PER_SIGNER_RESERVE_GAS * signers_.length),
            params_.avoSafeNonce == -1 ? digest_ : bytes32(0)
        );

        // @dev on changes in the code below this point, measure the needed reserve gas via `gasleft()` anew
        // and update the reserve gas constant amounts
        if (success_ == true) {
            emit CastExecuted(params_.source, msg.sender, signers_, params_.metadata);
        } else {
            emit CastFailed(params_.source, msg.sender, signers_, revertReason_, params_.metadata);
        }
        // @dev ending point for measuring reserve gas should be here. Also see comment in `AvoCore._executeCast()`
    }
}

abstract contract AvoMultisigCastAuthorized is AvoMultisigCore {
    /// @inheritdoc IAvoMultisigV3Base
    function getSigDigestAuthorized(
        CastParams memory params_,
        CastAuthorizedParams memory authorizedParams_
    ) public view returns (bytes32) {
        return
            _getSigDigest(
                params_,
                CAST_AUTHORIZED_TYPE_HASH,
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
            );
    }

    /// @inheritdoc IAvoMultisigV3Base
    function verifyAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool) {
        {
            // make sure actions are defined and nonce is valid
            _validateParams(
                params_.actions.length,
                params_.avoSafeNonce,
                authorizedParams_.validAfter,
                authorizedParams_.validUntil
            );
        }

        (bool validSignature_, ) = _verifySig(
            getSigDigestAuthorized(params_, authorizedParams_),
            signaturesParams_,
            params_.avoSafeNonce == -1
        );

        // signature must be valid
        if (!validSignature_) {
            revert AvoMultisig__InvalidSignature();
        }

        return true;
    }

    /// @inheritdoc IAvoMultisigV3Base
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] memory signaturesParams_
    ) external payable returns (bool success_, string memory revertReason_) {
        uint256 gasSnapshot_ = gasleft();

        {
            // make sure actions are defined and nonce is valid
            _validateParams(
                params_.actions.length,
                params_.avoSafeNonce,
                authorizedParams_.validAfter,
                authorizedParams_.validUntil
            );
        }

        bytes32 digest_ = getSigDigestAuthorized(params_, authorizedParams_);
        address[] memory signers_;
        {
            bool validSignature_;
            (validSignature_, signers_) = _verifySig(digest_, signaturesParams_, params_.avoSafeNonce == -1);

            // signature must be valid
            if (!validSignature_) {
                revert AvoMultisig__InvalidSignature();
            }
        }

        {
            (success_, revertReason_) = _executeCast(
                params_,
                // the gas usage for the emitting the CastExecuted/CastFailed events depends on the signers count
                // the cost per signer is PER_SIGNER_RESERVE_GAS. We calculate this dynamically to ensure
                // enough reserve gas is reserved in Multisigs with a higher signersCount
                CAST_AUTHORIZED_RESERVE_GAS + (PER_SIGNER_RESERVE_GAS * signers_.length),
                params_.avoSafeNonce == -1 ? digest_ : bytes32(0)
            );

            // @dev on changes in the code below this point, measure the needed reserve gas via `gasleft()` anew
            // and update reserve gas constant amounts
            if (success_ == true) {
                emit CastExecuted(params_.source, msg.sender, signers_, params_.metadata);
            } else {
                emit CastFailed(params_.source, msg.sender, signers_, revertReason_, params_.metadata);
            }
        }

        // @dev `_payAuthorizedFee()` costs ~24k gas for if a fee is configured and maxFee is set
        _payAuthorizedFee(gasSnapshot_, authorizedParams_.maxFee);

        // @dev ending point for measuring reserve gas should be here. Also see comment in `AvoCore._executeCast()`
    }
}

contract AvoMultisig is
    AvoMultisigCore,
    AvoMultisigSelfUpgradeable,
    AvoMultisigProtected,
    AvoMultisigEIP1271,
    AvoMultisigSigners,
    AvoMultisigCast,
    AvoMultisigCastAuthorized
{
    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    /// @notice                        constructor sets multiple immutable values for contracts and payFee fallback logic.
    /// @param avoVersionsRegistry_    address of the avoVersionsRegistry (proxy) contract
    /// @param avoForwarder_           address of the avoForwarder (proxy) contract
    ///                                to forward tx with valid signatures. must be valid version in AvoVersionsRegistry.
    /// @param avoSignersList_         address of the AvoSignersList (proxy) contract
    /// @param authorizedMinFee_       minimum for fee charged via `castAuthorized()` to charge if
    ///                                `AvoVersionsRegistry.calcFee()` would fail.
    /// @param authorizedMaxFee_       maximum for fee charged via `castAuthorized()`. If AvoVersionsRegistry
    ///                                returns a fee higher than this, then `authorizedMaxFee_` is charged as fee instead.
    /// @param authorizedFeeCollector_ address that the fee charged via `castAuthorized()` is sent to in the fallback case.
    constructor(
        IAvoVersionsRegistry avoVersionsRegistry_,
        address avoForwarder_,
        IAvoSignersList avoSignersList_,
        uint256 authorizedMinFee_,
        uint256 authorizedMaxFee_,
        address authorizedFeeCollector_
    )
        AvoMultisigCore(
            avoVersionsRegistry_,
            avoForwarder_,
            avoSignersList_,
            authorizedMinFee_,
            authorizedMaxFee_,
            authorizedFeeCollector_
        )
    {}

    /// @inheritdoc IAvoMultisigV3Base
    function initialize(address owner_) public initializer {
        _initialize(owner_);
    }

    /// @inheritdoc IAvoMultisigV3Base
    function initializeWithVersion(address owner_, address avoMultisigVersion_) public initializer {
        _initialize(owner_);

        // set current avo implementation logic address
        _avoImplementation = avoMultisigVersion_;
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    receive() external payable {}

    /// @inheritdoc IAvoMultisigV3Base
    function domainSeparatorV4() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @inheritdoc IAvoMultisigV3Base
    function signers() public view returns (address[] memory signers_) {
        return _getSigners();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

abstract contract AvoMultisigErrors {
    /// @notice thrown when a method is called with invalid params (e.g. a zero address as input param)
    error AvoMultisig__InvalidParams();

    /// @notice thrown when a signature is not valid (e.g. not signed by enough allowed signers)
    error AvoMultisig__InvalidSignature();

    /// @notice thrown when someone is trying to execute a in some way auth protected logic
    error AvoMultisig__Unauthorized();

    /// @notice thrown when forwarder/relayer does not send enough gas as the user has defined.
    ///         this error should not be blamed on the user but rather on the relayer
    error AvoMultisig__InsufficientGasSent();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

abstract contract AvoMultisigEvents {
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
pragma solidity >=0.8.17;

import { SSTORE2 } from "solmate/src/utils/SSTORE2.sol";

import { IAvoVersionsRegistry } from "../interfaces/IAvoVersionsRegistry.sol";
import { IAvoSignersList } from "../interfaces/IAvoSignersList.sol";
import { AvoMultisigErrors } from "./AvoMultisigErrors.sol";
import { AvoCoreConstants, AvoCoreConstantsOverride, AvoCoreVariablesSlot0, AvoCoreVariablesSlot1, AvoCoreVariablesSlot2, AvoCoreVariablesSlot3, AvoCoreSlotGaps } from "../AvoCore/AvoCoreVariables.sol";

abstract contract AvoMultisigConstants is AvoCoreConstants, AvoCoreConstantsOverride, AvoMultisigErrors {
    // constants for EIP712 values (can't be overriden as immutables as other AvoCore constants, strings not supported)
    string public constant DOMAIN_SEPARATOR_NAME = "Avocado-Multisig";
    string public constant DOMAIN_SEPARATOR_VERSION = "3.0.0";

    /************************************|
    |            CUSTOM CONSTANTS        |
    |___________________________________*/

    /// @notice Signers <> AvoMultiSafes mapping list contract for easy on-chain tracking
    IAvoSignersList public immutable avoSignersList;

    /// @notice defines the max signers count for the Multisig. This is chosen deliberately very high, as there shouldn't
    /// really be a limit on signers count in practice. It is extremely unlikely that anyone runs into this very high
    /// limit but it helps to implement test coverage within this given limit
    uint256 public constant MAX_SIGNERS_COUNT = 90;

    /// @dev each additional signer costs ~358 gas to emit in the CastFailed / CastExecuted event. this amount must be
    /// factored in dynamically depending on the number of signers (PER_SIGNER_RESERVE_GAS * number of signers)
    uint256 internal constant PER_SIGNER_RESERVE_GAS = 370;

    /***********************************|
    |            CONSTRUCTOR            |
    |__________________________________*/

    // @dev use 52_000 as reserve gas for `castAuthorized()`. Usually it will cost less but 52_000 is the maximum amount
    // pay fee logic etc. could cost on maximum logic execution
    constructor(
        IAvoVersionsRegistry avoVersionsRegistry_,
        address avoForwarder_,
        IAvoSignersList avoSignersList_,
        uint256 authorizedMinFee_,
        uint256 authorizedMaxFee_,
        address authorizedFeeCollector_
    )
        AvoCoreConstants(avoVersionsRegistry_, avoForwarder_)
        AvoCoreConstantsOverride(
            DOMAIN_SEPARATOR_NAME,
            DOMAIN_SEPARATOR_VERSION,
            52_000,
            12_000,
            authorizedMinFee_,
            authorizedMaxFee_,
            authorizedFeeCollector_,
            true
        )
    {
        if (address(avoSignersList_) == address(0)) {
            revert AvoMultisig__InvalidParams();
        }
        avoSignersList = avoSignersList_;
    }
}

/// @notice Defines storage variables for AvoMultisig
abstract contract AvoMultisigVariables is
    AvoMultisigConstants,
    AvoCoreVariablesSlot0,
    AvoCoreVariablesSlot1,
    AvoCoreVariablesSlot2,
    AvoCoreVariablesSlot3,
    AvoCoreSlotGaps
{
    // ----------- storage slot 0 to 53 through inheritance, see respective contracts -----------

    /***********************************|
    |        CUSTOM STORAGE VARS        |
    |__________________________________*/

    // ----------- storage slot 54 -----------

    /// @dev signers are stored with SSTORE2 to save gas, especially for storage checks at delegateCalls.
    /// getter and setter is implemented below
    address internal _signersPointer;

    /// @notice signers count required to reach quorom and be able to execute actions
    uint8 public requiredSigners;

    /// @notice number of signers currently listed as allowed signers
    //
    // @dev should be updated directly via `_setSigners()`
    uint8 public signersCount;

    /***********************************|
    |            CONSTRUCTOR            |
    |__________________________________*/

    constructor(
        IAvoVersionsRegistry avoVersionsRegistry_,
        address avoForwarder_,
        IAvoSignersList avoSignersList_,
        uint256 authorizedMinFee_,
        uint256 authorizedMaxFee_,
        address authorizedFeeCollector_
    )
        AvoMultisigConstants(
            avoVersionsRegistry_,
            avoForwarder_,
            avoSignersList_,
            authorizedMinFee_,
            authorizedMaxFee_,
            authorizedFeeCollector_
        )
    {}

    /***********************************|
    |      SIGNERS GETTER / SETTER      |
    |__________________________________*/

    /// @dev writes `signers_` to storage with SSTORE2 and updates `signersCount`
    function _setSigners(address[] memory signers_) internal {
        signersCount = uint8(signers_.length);

        _signersPointer = SSTORE2.write(abi.encode(signers_));
    }

    /// @dev reads signers from storage with SSTORE2
    function _getSigners() internal view returns (address[] memory) {
        address pointer_ = _signersPointer;
        if (pointer_ == address(0)) {
            return new address[](0);
        }

        return abi.decode(SSTORE2.read(_signersPointer), (address[]));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

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
pragma solidity >=0.8.17;

interface IAvoAuthoritiesList {
    /// @notice syncs mappings of `authorities_` to an AvoSafe `avoSafe_` based on the data present at the wallet.
    /// If `trackInStorage` flag is set to false, then only an event will be emitted for off-chain tracking.
    /// The contract itself will not track avoSafes per authority on-chain!
    ///
    /// Silently ignores `authorities_` that are already mapped correctly.
    ///
    /// There is expectedly no need for this method to be called by anyone other than the AvoSafe itself.
    ///
    /// @dev Note that in off-chain tracking make sure to check for duplicates (i.e. mapping already exists).
    /// This should not happen but when not tracking the data on-chain there is no way to be sure.
    function syncAvoAuthorityMappings(address avoSafe_, address[] calldata authorities_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { AvoCoreStructs } from "../AvoCore/AvoCoreStructs.sol";

// @dev base interface without getters for storage variables (to avoid overloads issues)
interface IAvoMultisigV3Base is AvoCoreStructs {
    /// @notice        initializer called by AvoFactory after deployment, sets the `owner_` as owner and as only signer
    /// @param owner_  the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                     initialize contract same as `initialize()` but also sets a different
    ///                             logic contract implementation address `avoMultisigVersion_`
    /// @param owner_               the owner (immutable) of this smart wallet
    /// @param avoMultisigVersion_  version of AvoMultisig logic contract to initialize
    function initializeWithVersion(address owner_, address avoMultisigVersion_) external;

    /// @notice returns the domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice               gets the digest (hash) used to verify an EIP712 signature for `cast()`.
    ///
    ///                       This is also used as the non-sequential nonce that will be marked as used when the
    ///                       request with the matching `params_` and `forwardParams_` is executed via `cast()`.
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
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
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @return                   bytes32 digest to verify signature (or used as non-sequential nonce)
    function getSigDigestAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice                   Verify the signatures for a `cast()' call are valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
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
    ///                           Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
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

    /// @notice                   Executes arbitrary `actions_` with valid signatures. Only executable by AvoForwarder.
    ///                           If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           In that case, all previous actions are reverted.
    ///                           On success, emits CastExecuted event.
    /// @dev                      validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
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

    /// @notice                   Executes arbitrary `actions_` through authorized transaction sent with valid signatures.
    ///                           Includes a fee in native network gas token, amount depends on registry `calcFee()`.
    ///                           If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           In that case, all previous actions are reverted.
    ///                           On success, emits CastExecuted event.
    /// @dev                      executes a .call or .delegateCall for every action (depending on params)
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
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

    /// @notice checks if an address `signer_` is an allowed signer (returns true if allowed)
    function isSigner(address signer_) external view returns (bool);

    /// @notice returns allowed signers on AvoMultisig wich can trigger actions if reaching quorum `requiredSigners`.
    ///         signers automatically include owner.
    function signers() external view returns (address[] memory signers);
}

// @dev full interface with some getters for storage variables
interface IAvoMultisigV3 is IAvoMultisigV3Base {
    /// @notice AvoMultisig Owner
    function owner() external view returns (address);

    /// @notice Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice incrementing nonce for each valid tx executed (to ensure uniqueness)
    function avoSafeNonce() external view returns (uint88);

    /// @notice returns the number of allowed signers
    function signersCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoSignersList {
    /// @notice adds mappings of `addSigners_` to an AvoMultiSafe `avoMultiSafe_`.
    ///         checks the data present at the AvoMultisig to validate input data.
    ///
    /// If `trackInStorage` flag is set to false, then only an event will be emitted for off-chain tracking.
    /// The contract itself will not track avoMultiSafes per signer on-chain!
    ///
    /// Silently ignores `addSigners_` that are already added
    ///
    /// There is expectedly no need for this method to be called by anyone other than the AvoMultisig itself.
    function syncAddAvoSignerMappings(address avoMultiSafe_, address[] calldata addSigners_) external;

    /// @notice removes mappings of `removeSigners_` from an AvoMultiSafe `avoMultiSafe_`.
    ///         checks the data present at the AvoMultisig to validate input data.
    ///
    /// If `trackInStorage` flag is set to false, then only an event will be emitted for off-chain tracking.
    /// The contract itself will not track avoMultiSafes per signer on-chain!
    ///
    /// Silently ignores `addSigners_` that are already removed
    ///
    /// There is expectedly no need for this method to be called by anyone other than the AvoMultisig itself.
    function syncRemoveAvoSignerMappings(address avoMultiSafe_, address[] calldata removeSigners_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

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

    /// @notice calculates the `feeAmount_` for an AvoSafe (`msg.sender`) transaction `gasUsed_` based on
    ///         fee configuration present on the contract
    /// @param gasUsed_       amount of gas used, required if mode is percentage. not used if mode is static fee.
    /// @return feeAmount_    calculate fee amount to be paid
    /// @return feeCollector_ address to send the fee to
    function calcFee(uint256 gasUsed_) external view returns (uint256 feeAmount_, address payable feeCollector_);
}

interface IAvoVersionsRegistry is IAvoFeeCollector {
    /// @notice                   checks if an address is listed as allowed AvoWallet version, reverts if not.
    /// @param avoWalletVersion_  address of the Avo wallet logic contract to check
    function requireValidAvoWalletVersion(address avoWalletVersion_) external view;

    /// @notice                      checks if an address is listed as allowed AvoForwarder version, reverts if not.
    /// @param avoForwarderVersion_  address of the AvoForwarder logic contract to check
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) external view;

    /// @notice                     checks if an address is listed as allowed AvoMultisig version, reverts if not.
    /// @param avoMultisigVersion_  address of the AvoMultisig logic contract to check
    function requireValidAvoMultisigVersion(address avoMultisigVersion_) external view;
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