/**
 *Submitted for verification at Arbiscan.io on 2023-10-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/*
“Copyright (c) Kyber Network
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

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
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
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

/*
“Copyright (c) Kyber Network
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/

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
        assembly {
            size := extcodesize(account)
        }
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract KyberSwapRole is Ownable, Pausable {
  mapping(address => bool) public operators;
  mapping(address => bool) public guardians;

  /**
   * @dev Emitted when the an user was grant or revoke operator role.
   */
  event UpdateOperator(address user, bool grantOrRevoke);

  /**
   * @dev Emitted when the an user was grant or revoke guardian role.
   */
  event UpdateGuardian(address user, bool grantOrRevoke);

  /**
   * @dev Modifier to make a function callable only when caller is operator.
   *
   * Requirements:
   *
   * - Caller must have operator role.
   */
  modifier onlyOperator() {
    require(operators[msg.sender], 'KyberSwapRole: not operator');
    _;
  }

  /**
   * @dev Modifier to make a function callable only when caller is guardian.
   *
   * Requirements:
   *
   * - Caller must have guardian role.
   */
  modifier onlyGuardian() {
    require(guardians[msg.sender], 'KyberSwapRole: not guardian');
    _;
  }

  /**
   * @dev Update Operator role for user.
   * Can only be called by the current owner.
   */
  function updateOperator(address user, bool grantOrRevoke) external onlyOwner {
    operators[user] = grantOrRevoke;
    emit UpdateOperator(user, grantOrRevoke);
  }

  /**
   * @dev Update Guardian role for user.
   * Can only be called by the current owner.
   */
  function updateGuardian(address user, bool grantOrRevoke) external onlyOwner {
    guardians[user] = grantOrRevoke;
    emit UpdateGuardian(user, grantOrRevoke);
  }

  /**
   * @dev Enable logic for contract.
   * Can only be called by the current owner.
   */
  function enableLogic() external onlyOwner {
    _unpause();
  }

  /**
   * @dev Disable logic for contract.
   * Can only be called by the guardians.
   */
  function disableLogic() external onlyGuardian {
    _pause();
  }
}

/*
“Copyright (c) 2019-2021 1inch 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/

/// @title A helper contract for calculations related to order amounts
contract AmountCalculator {
  using Address for address;

  /// @notice Calculates maker amount
  /// @return Result Floored maker amount
  function getMakerAmount(
    uint256 orderMakerAmount,
    uint256 orderTakerAmount,
    uint256 swapTakerAmount
  ) public pure returns (uint256) {
    return (swapTakerAmount * orderMakerAmount) / orderTakerAmount;
  }

  /// @notice Calculates taker amount
  /// @return Result Ceiled taker amount
  function getTakerAmount(
    uint256 orderMakerAmount,
    uint256 orderTakerAmount,
    uint256 swapMakerAmount
  ) public pure returns (uint256) {
    return (swapMakerAmount * orderTakerAmount + orderMakerAmount - 1) / orderMakerAmount;
  }

  /// @notice Performs an arbitrary call to target with data
  /// @return Result Bytes transmuted to uint256
  function arbitraryStaticCall(address target, bytes memory data) external view returns (uint256) {
    bytes memory result = target.functionStaticCall(data, 'AC: arbitraryStaticCall');
    return abi.decode(result, (uint256));
  }
}

/*
“Copyright (c) 2019-2021 1inch 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/

/// @title A helper contract for managing nonce of tx sender
contract NonceManager {
  event NonceIncreased(address indexed maker, uint256 oldNonce, uint256 newNonce);

  mapping(address => uint256) public nonce;

  /// @notice Advances nonce by one
  function increaseNonce() external {
    advanceNonce(1);
  }

  /// @notice Advances nonce by specified amount
  function advanceNonce(uint8 amount) public {
    uint256 newNonce = nonce[msg.sender] + amount;
    nonce[msg.sender] = newNonce;
    emit NonceIncreased(msg.sender, newNonce - amount, newNonce);
  }

  /// @notice Checks if `makerAddress` has specified `makerNonce`
  /// @return Result True if `makerAddress` has specified nonce. Otherwise, false
  function nonceEquals(address makerAddress, uint256 makerNonce) external view returns (bool) {
    return nonce[makerAddress] == makerNonce;
  }
}

/*
“Copyright (c) 2019-2021 1inch 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/

/// @title A helper contract for executing boolean functions on arbitrary target call results
contract PredicateHelper {
  using Address for address;

  /// @notice Calls every target with corresponding data
  /// @return Result True if call to any target returned True. Otherwise, false
  function or(address[] calldata targets, bytes[] calldata data) external view returns (bool) {
    require(targets.length == data.length, 'PH: input array size mismatch');
    for (uint256 i = 0; i < targets.length; i++) {
      bytes memory result = targets[i].functionStaticCall(data[i], "PH: 'or' subcall failed");
      require(result.length == 32, 'PH: invalid call result');
      if (abi.decode(result, (bool))) {
        return true;
      }
    }
    return false;
  }

  /// @notice Calls every target with corresponding data
  /// @return Result True if calls to all targets returned True. Otherwise, false
  function and(address[] calldata targets, bytes[] calldata data) external view returns (bool) {
    require(targets.length == data.length, 'PH: input array size mismatch');
    for (uint256 i = 0; i < targets.length; i++) {
      bytes memory result = targets[i].functionStaticCall(data[i], "PH: 'and' subcall failed");
      require(result.length == 32, 'PH: invalid call result');
      if (!abi.decode(result, (bool))) {
        return false;
      }
    }
    return true;
  }

  /// @notice Calls target with specified data and tests if it's equal to the value
  /// @param value Value to test
  /// @return Result True if call to target returns the same value as `value`. Otherwise, false
  function eq(uint256 value, address target, bytes memory data) external view returns (bool) {
    bytes memory result = target.functionStaticCall(data, 'PH: eq');
    require(result.length == 32, 'PH: invalid call result');
    return abi.decode(result, (uint256)) == value;
  }

  /// @notice Calls target with specified data and tests if it's lower than value
  /// @param value Value to test
  /// @return Result True if call to target returns value which is lower than `value`. Otherwise, false
  function lt(uint256 value, address target, bytes memory data) external view returns (bool) {
    bytes memory result = target.functionStaticCall(data, 'PH: lt');
    require(result.length == 32, 'PH: invalid call result');
    return abi.decode(result, (uint256)) < value;
  }

  /// @notice Calls target with specified data and tests if it's bigger than value
  /// @param value Value to test
  /// @return Result True if call to target returns value which is bigger than `value`. Otherwise, false
  function gt(uint256 value, address target, bytes memory data) external view returns (bool) {
    bytes memory result = target.functionStaticCall(data, 'PH: gt');
    require(result.length == 32, 'PH: invalid call result');
    return abi.decode(result, (uint256)) > value;
  }

  /// @notice Checks passed time against block timestamp
  /// @return Result True if current block timestamp is lower than `time`. Otherwise, false
  function timestampBelow(uint256 time) external view returns (bool) {
    return block.timestamp < time; // solhint-disable-line not-rely-on-time
  }
}

/// @title Interface for interactor which acts between `maker => taker` and `taker => maker` transfers.
interface InteractiveNotificationReceiver {
  /// @notice Callback method that gets called after taker transferred funds to maker but before
  /// the opposite transfer happened
  function notifyFillOrder(
    address taker,
    address makerAsset,
    address takerAsset,
    uint256 makingAmount,
    uint256 takingAmount,
    bytes memory interactiveData
  ) external;
}

/// @title Interface for DAI-style permits
interface ILimitOrderCallee {
  function limitOrderCall(
    uint256 makingAmount,
    uint256 takingAmount,
    bytes memory callbackData
  ) external;
}

/// @title Interface for Double signature order
interface IDSOrderMixin {
  /// @notice Emitted every time order gets filled, including partial fills
  event OrderFilled(
    address indexed taker,
    bytes32 indexed orderHash,
    uint256 remaining,
    uint256 makingAmount,
    uint256 takingAmount
  );

  /// @notice Emitted when order gets cancelled
  event OrderCanceled(address indexed maker, bytes32 orderHash, uint256 remainingRaw);

  /// @notice Emitted when update interaction target whitelist
  event UpdatedInteractionWhitelist(address _address, bool isWhitelist);

  /// @notice Emitted when update ds order signer
  event UpdatedDSOrderSigner(address _address);

  /// @notice Emitted when collect fee
  event FeeCollected(address indexed recipient, address indexed token, uint256 amount);

  // address feeRecipient;
  //   uint32 amountTokenFeePercent;
  //   bool isTakerAssetFee;

  // Fixed-size order part with core information
  // `feeConfig`
  //      feeRecipient = address(uint160(params.order.feeConfig))
  //      amountTokenFeePercent = uint32(params.order.feeConfig >> 160)
  //      isTakerAssetFee = (params.order.feeConfig >> 192) != 0
  struct StaticOrder {
    uint256 salt;
    address makerAsset;
    address takerAsset;
    address maker;
    address receiver;
    address allowedSender; // equals to Zero address on public orders
    uint256 makingAmount;
    uint256 takingAmount;
    uint256 feeConfig; // bit slot  1 -> 32 -> 160: isTakerAssetFee - amountTokenFeePercent - feeRecipient
  }

  // `StaticOrder` extension including variable-sized additional order meta information
  // `feeConfig`
  //      feeRecipient = address(uint160(params.order.feeConfig))
  //      amountTokenFeePercent = uint32(params.order.feeConfig >> 160)
  //      isTakerAssetFee = (params.order.feeConfig >> 192) != 0
  struct Order {
    uint256 salt;
    address makerAsset;
    address takerAsset;
    address maker;
    address receiver;
    address allowedSender; // equals to Zero address on public orders
    uint256 makingAmount;
    uint256 takingAmount;
    uint256 feeConfig; // bit slot  1 -> 32 -> 160: isTakerAssetFee - amountTokenFeePercent - feeRecipient
    bytes makerAssetData;
    bytes takerAssetData;
    bytes getMakerAmount; // this.staticcall(abi.encodePacked(bytes, swapTakerAmount)) => (swapMakerAmount)
    bytes getTakerAmount; // this.staticcall(abi.encodePacked(bytes, swapMakerAmount)) => (swapTakerAmount)
    bytes predicate; // this.staticcall(bytes) => (bool)
    bytes interaction;
  }

  struct DSOrder {
    bytes32 orderHash;
    uint32 opExpireTime;
  }

  struct Signature {
    bytes orderSignature; // Signature to confirm quote ownership
    bytes opSignature; // OP Signature to confirm quote ownership
  }

  struct AmountData {
    uint256 makingAmount;
    uint256 takingAmount;
    uint256 thresholdAmount;
  }

  struct FillOrderParams {
    Order order;
    Signature signature;
    uint32 opExpireTime;
    address target;
    bytes callbackData;
  }

  struct FillBatchOrdersParams {
    Order[] orders;
    Signature[] signatures;
    uint32[] opExpireTimes;
    uint256 takingAmount;
    uint256 thresholdAmount;
    address target;
  }
}

/*
“Copyright (c) 2019-2021 1inch 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/

/// @title Library with gas efficient alternatives to `abi.decode`
library ArgumentsDecoder {
  function decodeUint256(bytes memory data) internal pure returns (uint256) {
    uint256 value;
    assembly {
      // solhint-disable-line no-inline-assembly
      value := mload(add(data, 0x20))
    }
    return value;
  }

  function decodeBool(bytes memory data) internal pure returns (bool) {
    bool value;
    assembly {
      // solhint-disable-line no-inline-assembly
      value := eq(mload(add(data, 0x20)), 1)
    }
    return value;
  }

  function decodeTargetAndCalldata(bytes memory data) internal pure returns (address, bytes memory) {
    address target;
    bytes memory args;
    assembly {
      // solhint-disable-line no-inline-assembly
      target := mload(add(data, 0x14))
      args := add(data, 0x14)
      mstore(args, sub(mload(data), 0x14))
    }
    return (target, args);
  }

  function decodeTargetAndData(bytes calldata data) internal pure returns (address, bytes calldata) {
    address target;
    bytes calldata args;
    assembly {
      // solhint-disable-line no-inline-assembly
      target := shr(96, calldataload(data.offset))
    }
    args = data[20:];
    return (target, args);
  }
}

/// @title Regular Limit Order mixin
abstract contract DSOrderMixin is
  EIP712,
  AmountCalculator,
  NonceManager,
  PredicateHelper,
  KyberSwapRole,
  IDSOrderMixin
{
  using Address for address;
  using ArgumentsDecoder for bytes;

  bytes32 public constant LIMIT_ORDER_TYPEHASH = keccak256(
    'Order(uint256 salt,address makerAsset,address takerAsset,address maker,address receiver,address allowedSender,uint256 makingAmount,uint256 takingAmount,uint256 feeConfig,bytes makerAssetData,bytes takerAssetData,bytes getMakerAmount,bytes getTakerAmount,bytes predicate,bytes interaction)'
  );

  bytes32 public constant DS_LIMIT_ORDER_TYPEHASH =
    keccak256('DSOrder(bytes32 orderHash,uint32 opExpireTime)');

  uint256 private constant _ORDER_DOES_NOT_EXIST = 0;
  uint256 private constant _ORDER_FILLED = 1;
  uint24 internal constant FEE_UNITS = 100_000;
  address private _dsOrderSigner;

  /// @notice Stores unfilled amounts for each order plus one
  /// Therefore 0 means order doesn't exist and 1 means order was filled
  mapping(bytes32 => uint256) private _remaining;
  mapping(address => bool) interactionWhitelist;

  /// @notice Update interaction target whitelist
  function updateInteractionWhitelist(address _address, bool isWhitelist) external onlyOwner {
    interactionWhitelist[_address] = isWhitelist;
    emit UpdatedInteractionWhitelist(_address, isWhitelist);
  }

  /// @notice Update dsOrderSigner
  function updateDSOrderSigner(address _address) external onlyOwner {
    _dsOrderSigner = _address;
    emit UpdatedDSOrderSigner(_address);
  }

  /// @notice Hard cancels order by setting remaining amount to zero
  function cancelOrder(Order calldata order) public {
    require(order.maker == msg.sender, 'LOP: Access denied');

    bytes32 orderHash = hashOrder(order);
    uint256 orderRemaining = _remaining[orderHash];
    require(orderRemaining != _ORDER_FILLED, 'LOP: already filled');
    emit OrderCanceled(msg.sender, orderHash, orderRemaining);
    _remaining[orderHash] = _ORDER_FILLED;
  }

  /// @notice Cancels multiple orders by setting remaining amount to zero
  function cancelBatchOrders(Order[] calldata orders) external {
    for (uint256 i; i < orders.length;) {
      cancelOrder(orders[i]);
      unchecked {
        ++i;
      }
    }
  }

  /// @notice Same as `fillOrder`
  /// @param params FillOrderParams:
  ///   - Order order: quote to fill
  ///   - Signature signature: Signature to confirm quote ownership
  ///   - uint32 expireTime: OP Signature expire time
  ///   - address target: Maker asset recipient
  ///   - bytes callbackData: CallbackData to callback to the msg.sender after receiving the makingAmount, the msg.sender transfer takingAmount to the maker after this call
  /// @param amountData amount data struct
  /// @param sender if msg.sender is address(this), set msg.sender = sender (msg.sender of the previous call)
  /// @return actualMakingAmount
  /// @return actualTakingAmount
  /// @return feeCollected
  function fillOrderTo(
    FillOrderParams calldata params,
    AmountData memory amountData,
    address sender
  )
    public
    whenNotPaused
    returns (
      uint256, /* actualMakingAmount */
      uint256, /* actualTakingAmount */
      uint256 /* feeCollected */
    )
  {
    require(params.target != address(0), 'LOP: zero target is forbidden');

    address _msgSender = msg.sender;
    if (sender != address(0) && msg.sender == address(this)) {
      _msgSender = sender;
    }
    bytes32 orderHash = hashOrder(params.order);

    // handle double signature
    {
      bytes32 dsOrderHash =
        hashDSOrder(DSOrder({orderHash: orderHash, opExpireTime: params.opExpireTime}));
      require(params.opExpireTime >= block.timestamp, 'LOP: expired');
      require(
        SignatureChecker.isValidSignatureNow(
          _dsOrderSigner, dsOrderHash, params.signature.opSignature
        ),
        'LOP: bad op signature'
      );
    }

    {
      // Stack too deep
      uint256 remainingMakerAmount = _remaining[orderHash];

      if (remainingMakerAmount == _ORDER_FILLED) {
        revert('LOP: invalid order');
      }
      require(
        params.order.allowedSender == address(0) || params.order.allowedSender == _msgSender,
        'LOP: private order'
      );
      if (remainingMakerAmount == _ORDER_DOES_NOT_EXIST) {
        // First fill: validate order
        require(
          SignatureChecker.isValidSignatureNow(
            params.order.maker, orderHash, params.signature.orderSignature
          ),
          'LOP: bad signature'
        );
        remainingMakerAmount = params.order.makingAmount;
      } else {
        unchecked {
          remainingMakerAmount -= 1;
        }
      }

      // Check if order is valid
      if (params.order.predicate.length > 0) {
        bool isValidPredicate = checkPredicate(params.order);

        require(isValidPredicate, 'LOP: predicate returned false');
      }

      // Compute maker and taker assets amount
      if ((amountData.takingAmount == 0) == (amountData.makingAmount == 0)) {
        revert('LOP: only one amount should be 0');
      } else if (amountData.takingAmount == 0) {
        uint256 requestedMakingAmount = amountData.makingAmount;
        if (amountData.makingAmount > remainingMakerAmount) {
          amountData.makingAmount = remainingMakerAmount;
        }

        amountData.takingAmount = _callGetter(
          params.order.getTakerAmount,
          params.order.makingAmount,
          amountData.makingAmount,
          params.order.takingAmount
        );
        // check that actual rate is not worse than what was expected
        // takingAmount / makingAmount <= thresholdAmount / requestedMakingAmount
        require(
          amountData.takingAmount * requestedMakingAmount
            <= amountData.thresholdAmount * amountData.makingAmount,
          'LOP: taking amount too high'
        );
      } else {
        uint256 requestedTakingAmount = amountData.takingAmount;
        amountData.makingAmount = _callGetter(
          params.order.getMakerAmount,
          params.order.takingAmount,
          amountData.takingAmount,
          params.order.makingAmount
        );

        if (amountData.makingAmount > remainingMakerAmount) {
          amountData.makingAmount = remainingMakerAmount;
          amountData.takingAmount = _callGetter(
            params.order.getTakerAmount,
            params.order.makingAmount,
            amountData.makingAmount,
            params.order.takingAmount
          );
        }
        // check that actual rate is not worse than what was expected
        // makingAmount / takingAmount >= thresholdAmount / requestedTakingAmount
        require(
          amountData.makingAmount * requestedTakingAmount
            >= amountData.thresholdAmount * amountData.takingAmount,
          'LOP: making amount too low'
        );
      }

      require(
        amountData.makingAmount > 0 && amountData.takingAmount > 0, "LOP: can't swap 0 amount"
      );

      // Update remaining amount in storage
      unchecked {
        remainingMakerAmount = remainingMakerAmount - amountData.makingAmount;
        _remaining[orderHash] = remainingMakerAmount + 1;
      }
      emit OrderFilled(
        _msgSender,
        orderHash,
        remainingMakerAmount,
        amountData.makingAmount,
        amountData.takingAmount
      );
    }

    // feeRecipient = address(uint160(params.order.feeConfig))
    // amountTokenFeePercent = uint32(params.order.feeConfig >> 160)
    // isTakerAssetFee = (params.order.feeConfig >> 192) != 0
    uint256 feeAmount;
    // feeRecipient != 0 && amountTokenFeePercent != 0 : have fee
    if (
      address(uint160(params.order.feeConfig)) != address(0)
        && uint32(params.order.feeConfig >> 160) != 0
    ) {
      if ((params.order.feeConfig >> 192) != 0) {
        feeAmount = (
          amountData.takingAmount * uint32(params.order.feeConfig >> 160) + FEE_UNITS - 1
        ) / FEE_UNITS;

        // Maker => Taker
        _makeCall(
          params.order.makerAsset,
          abi.encodePacked(
            IERC20.transferFrom.selector,
            uint256(uint160(params.order.maker)),
            uint256(uint160(params.target)),
            amountData.makingAmount,
            params.order.makerAssetData
          )
        );

        // Callback to _msgSender
        if (params.callbackData.length != 0) {
          ILimitOrderCallee(_msgSender).limitOrderCall(
            amountData.makingAmount, amountData.takingAmount + feeAmount, params.callbackData
          );
        }

        // Taker => FeeRecipient
        _makeCall(
          params.order.takerAsset,
          abi.encodePacked(
            IERC20.transferFrom.selector,
            uint256(uint160(_msgSender)),
            uint256(uint160(params.order.feeConfig)),
            feeAmount,
            params.order.takerAssetData
          )
        );
        emit FeeCollected(
          address(uint160(params.order.feeConfig)), params.order.takerAsset, feeAmount
        );
      } else {
        feeAmount = (
          amountData.makingAmount * uint32(params.order.feeConfig >> 160) + FEE_UNITS - 1
        ) / FEE_UNITS;

        // Maker => FeeRecipient
        _makeCall(
          params.order.makerAsset,
          abi.encodePacked(
            IERC20.transferFrom.selector,
            uint256(uint160(params.order.maker)),
            uint256(uint160(params.order.feeConfig)),
            feeAmount,
            params.order.makerAssetData
          )
        );
        emit FeeCollected(
          address(uint160(params.order.feeConfig)), params.order.makerAsset, feeAmount
        );

        // Maker => Taker
        _makeCall(
          params.order.makerAsset,
          abi.encodePacked(
            IERC20.transferFrom.selector,
            uint256(uint160(params.order.maker)),
            uint256(uint160(params.target)),
            amountData.makingAmount - feeAmount,
            params.order.makerAssetData
          )
        );

        // Callback to _msgSender
        if (params.callbackData.length != 0) {
          ILimitOrderCallee(_msgSender).limitOrderCall(
            amountData.makingAmount, amountData.takingAmount, params.callbackData
          );
        }
      }
    } else {
      // no fee
      // Maker => Taker
      _makeCall(
        params.order.makerAsset,
        abi.encodePacked(
          IERC20.transferFrom.selector,
          uint256(uint160(params.order.maker)),
          uint256(uint160(params.target)),
          amountData.makingAmount,
          params.order.makerAssetData
        )
      );

      // Callback to _msgSender
      if (params.callbackData.length != 0) {
        ILimitOrderCallee(_msgSender).limitOrderCall(
          amountData.makingAmount, amountData.takingAmount, params.callbackData
        );
      }
    }

    // Taker => Maker
    _makeCall(
      params.order.takerAsset,
      abi.encodePacked(
        IERC20.transferFrom.selector,
        uint256(uint160(_msgSender)),
        uint256(
          uint160(params.order.receiver == address(0) ? params.order.maker : params.order.receiver)
        ),
        amountData.takingAmount,
        params.order.takerAssetData
      )
    );

    // Maker can handle funds interactively
    if (params.order.interaction.length >= 20) {
      // proceed only if interaction length is enough to store address
      (address interactionTarget, bytes memory interactionData) =
        params.order.interaction.decodeTargetAndCalldata();
      require(
        interactionWhitelist[interactionTarget], 'LOP: the interaction target is not whitelisted'
      );
      InteractiveNotificationReceiver(interactionTarget).notifyFillOrder(
        _msgSender,
        params.order.makerAsset,
        params.order.takerAsset,
        amountData.makingAmount,
        amountData.takingAmount,
        interactionData
      );
    }

    return (params.order.feeConfig >> 192) != 0
      ? (amountData.makingAmount, amountData.takingAmount + feeAmount, feeAmount)
      : (amountData.makingAmount, amountData.takingAmount, feeAmount);
  }

  /// @notice Try to fulfill the takingAmount across multiple orders that have the same makerAsset and takerAsset
  /// Loop through list orders to fill, ignore if some fillOrderTo got reverted.
  /// @param params FillBatchOrdersParams:
  ///   - Order[] orders: Order list to fill one by one until fulfill the takingAmount
  ///   - Signature[] signatures: Signatures to confirm quote ownership
  ///   - uint32[] opExpireTimes: OP Signatures expire time
  ///   - uint256 takingAmount: Taking amount
  ///   - uint256 thresholdAmount: Minimun makingAmount is acceptable
  ///   - address target: Recipient address for maker asset
  /// @return actualMakingAmount
  /// @return actualTakingAmount
  /// @return makerAssetFeeCollected
  /// @return takerAssetFeeCollected
  function fillBatchOrdersTo(FillBatchOrdersParams calldata params)
    external
    returns (
      uint256 actualMakingAmount,
      uint256, /* actualTakingAmount */
      uint256 makerAssetFeeCollected,
      uint256 takerAssetFeeCollected
    )
  {
    // require(params.orders.length > 0, 'LOP: empty array');
    require(params.orders.length == params.signatures.length, 'LOP: array size mismatch');
    require(params.takingAmount != 0, 'LOP: zero takingAmount');

    address makerAsset = params.orders[0].makerAsset;
    address takerAsset = params.orders[0].takerAsset;
    uint256 remainingTakingAmount = params.takingAmount;
    for (uint256 i; i < params.orders.length;) {
      require(
        makerAsset == params.orders[i].makerAsset && takerAsset == params.orders[i].takerAsset,
        'LOP: invalid pair'
      );
      try this.fillOrderTo(
        FillOrderParams(
          params.orders[i], params.signatures[i], params.opExpireTimes[i], params.target, ''
        ),
        AmountData({makingAmount: 0, takingAmount: remainingTakingAmount, thresholdAmount: 0}),
        msg.sender
      ) returns (uint256 _makingAmount, uint256 _takingAmount, uint256 _feeCollected) {
        actualMakingAmount += _makingAmount;
        // if get fee by taker asset
        if ((params.orders[0].feeConfig >> 192) != 0) {
          // taking amount included feeCollected, we should keep remainingTakingAmount without _feeCollected
          remainingTakingAmount = remainingTakingAmount + _feeCollected - _takingAmount;
          takerAssetFeeCollected += _feeCollected;
        } else {
          remainingTakingAmount -= _takingAmount;
          makerAssetFeeCollected += _feeCollected;
        }
      } catch {
        // If got revert from fillOrderTo we continue to loop.
        // Check remainingTakingAmount later to make sure no taking amount left
      }

      if (remainingTakingAmount == 0) break;
      unchecked {
        ++i;
      }
    }
    require(remainingTakingAmount == 0, 'LOP: cannot fulfill');
    require(actualMakingAmount >= params.thresholdAmount, 'LOP: making amount too low');
    return (
      actualMakingAmount,
      params.takingAmount + takerAssetFeeCollected,
      makerAssetFeeCollected,
      takerAssetFeeCollected
    );
  }

  /// @notice Returns unfilled amount for order. Throws if order does not exist
  function remaining(bytes32 orderHash) external view returns (uint256) {
    uint256 amount = _remaining[orderHash];
    require(amount != _ORDER_DOES_NOT_EXIST, 'LOP: Unknown order');
    unchecked {
      amount -= 1;
    }
    return amount;
  }

  /// @notice Returns unfilled amount for order
  /// @return Result Unfilled amount of order plus one if order exists. Otherwise 0
  function remainingRaw(bytes32 orderHash) external view returns (uint256) {
    return _remaining[orderHash];
  }

  /// @notice Same as `remainingRaw` but for multiple orders
  function remainingsRaw(bytes32[] calldata orderHashes) external view returns (uint256[] memory) {
    uint256[] memory results = new uint256[](orderHashes.length);
    for (uint256 i; i < orderHashes.length;) {
      results[i] = _remaining[orderHashes[i]];
      unchecked {
        ++i;
      }
    }
    return results;
  }

  /// @notice Checks order predicate
  function checkPredicate(Order calldata order) public view returns (bool) {
    bytes memory result =
      address(this).functionStaticCall(order.predicate, 'LOP: predicate call failed');
    require(result.length == 32, 'LOP: invalid predicate return');
    return result.decodeBool();
  }

  function hashOrder(Order calldata order) public view returns (bytes32) {
    StaticOrder memory staticOrder = StaticOrder({
      salt: order.salt,
      makerAsset: order.makerAsset,
      takerAsset: order.takerAsset,
      maker: order.maker,
      receiver: order.receiver,
      allowedSender: order.allowedSender,
      makingAmount: order.makingAmount,
      takingAmount: order.takingAmount,
      feeConfig: order.feeConfig
    });

    return _hashTypedDataV4(
      keccak256(
        abi.encode(
          LIMIT_ORDER_TYPEHASH,
          staticOrder,
          keccak256(order.makerAssetData),
          keccak256(order.takerAssetData),
          keccak256(order.getMakerAmount),
          keccak256(order.getTakerAmount),
          keccak256(order.predicate),
          keccak256(order.interaction)
        )
      )
    );
  }

  function hashDSOrder(DSOrder memory dsOrder) public view returns (bytes32) {
    return _hashTypedDataV4(
      keccak256(abi.encode(DS_LIMIT_ORDER_TYPEHASH, dsOrder.orderHash, dsOrder.opExpireTime))
    );
  }

  function _makeCall(address asset, bytes memory assetData) private {
    bytes memory result = asset.functionCall(assetData, 'LOP: asset.call failed');
    if (result.length != 0) {
      require(result.length == 32 && result.decodeBool(), 'LOP: asset.call bad result');
    }
  }

  function _callGetter(
    bytes calldata getter,
    uint256 orderExpectedAmount,
    uint256 amount,
    uint256 orderResultAmount
  ) private view returns (uint256) {
    if (getter.length == 0) {
      // On empty getter calldata only exact amount is allowed
      require(amount == orderExpectedAmount, 'LOP: wrong amount');
      return orderResultAmount;
    } else {
      bytes memory result = address(this).functionStaticCall(
        abi.encodePacked(getter, amount), 'LOP: getAmount call failed'
      );
      require(result.length == 32, 'LOP: invalid getAmount return');
      return result.decodeUint256();
    }
  }
}

/// @title Double Signature Kyber Limit Order Protocol
contract DSLOProtocol is EIP712('Kyber DSLO Protocol', '1'), DSOrderMixin {
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32) {
    return _domainSeparatorV4();
  }
}