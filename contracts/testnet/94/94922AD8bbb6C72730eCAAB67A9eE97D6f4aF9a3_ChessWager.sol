// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

/* 
   _____ _                   ______ _     _     
  / ____| |                 |  ____(_)   | |    
 | |    | |__   ___  ___ ___| |__   _ ___| |__  
 | |    | '_ \ / _ \/ __/ __|  __| | / __| '_ \ 
 | |____| | | |  __/\__ \__ \ |    | \__ \ | | |
  \_____|_| |_|\___||___/___/_|    |_|___/_| |_|
                             
*/

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/interfaces.sol";
import "./MoveHelper.sol";

/**
 * @title ChessFish ChessWager Contract
 * @author ChessFish
 * @notice https://github.com/Chess-Fish
 *
 * @dev This contract handles the logic for storing chess wagers between users,
 * storing game moves, and handling the payout of 1v1 matches.
 * The Tournament Contract is able to call into this contract to create tournament matches between users.
 */

contract ChessWager is MoveHelper {
    using SafeERC20 for IERC20;

    struct GameWager {
        address player0;
        address player1;
        address wagerToken;
        uint wager;
        uint numberOfGames;
        bool hasPlayerAccepted;
        uint timeLimit;
        uint timeLastMove;
        uint timePlayer0;
        uint timePlayer1;
        bool isTournament;
        bool isComplete;
    }

    struct WagerStatus {
        bool isPlayer0White;
        uint winsPlayer0;
        uint winsPlayer1;
    }

    struct Game {
        uint16[] moves;
    }

    struct GaslessMoveData {
        address signer;
        address player0;
        address player1;
        uint16 move;
        uint moveNumber;
        uint expiration;
        bytes32 messageHash;
    }

    /// @dev address wager => GameWager
    mapping(address => GameWager) public gameWagers;

    /// @dev address wager => WagerPrize
    mapping(address => uint) public wagerPrizes;

    /// @dev address wager => gameID => Game
    mapping(address => mapping(uint => Game)) games;

    /// @dev address wager => gameIDs
    mapping(address => uint[]) gameIDs;

    /// @dev addres wager => Player Wins
    mapping(address => WagerStatus) public wagerStatus;

    /// @dev player can see game challenges
    mapping(address => address[]) public userGames;

    /// @dev address[] wagers
    address[] public allWagers;

    /// @dev  CFSH Token Address
    address public ChessFishToken;

    /// @dev  Dividend Splitter contract
    address public DividendSplitter;

    /// @dev ChessFish Winner NFT contract
    address public ChessFishNFT;

    constructor(
        address moveVerificationAddress,
        address _ChessFishToken,
        address _DividendSplitter,
        address _ChessFishNFT
    ) {
        moveVerification = MoveVerification(moveVerificationAddress);
        initPieces();

        ChessFishToken = _ChessFishToken;
        DividendSplitter = _DividendSplitter;
        ChessFishNFT = _ChessFishNFT;

        deployer = msg.sender;
    }

    /* 
    //// EVENTS ////
    */

    event createGameWagerEvent(address wager, address wagerToken, uint wagerAmount, uint timeLimit, uint numberOfGames);
    event acceptWagerEvent(address wagerAddress, address userAddress);
    event playMoveEvent(address wagerAddress, uint16 move);
    event payoutWagerEvent(
        address wagerAddress,
        address winner,
        address wagerToken,
        uint wagerAmount,
        uint protocolFee
    );
    event cancelWagerEvent(address wagerAddress, address userAddress);

    /* 
    //// VIEW FUNCTIONS ////
    */

    function getAllWagersCount() external view returns (uint) {
        return allWagers.length;
    }

    function getAllWagerAddresses() external view returns (address[] memory) {
        return allWagers;
    }

    function getAllUserGames(address player) external view returns (address[] memory) {
        return userGames[player];
    }

    function getGameLength(address wagerAddress) external view returns (uint) {
        return gameIDs[wagerAddress].length;
    }

    function getGameMoves(address wagerAddress, uint gameID) external view returns (Game memory) {
        return games[wagerAddress][gameID];
    }

    function getNumberOfGamesPlayed(address wagerAddress) internal view returns (uint) {
        return gameIDs[wagerAddress].length + 1;
    }

    /// @notice Get Wager Status
    /// @dev returns the status of the wager
    /// @return (address, address, uint, uint) address player0, address player1, winsPlayer0, winsPlayer1
    function getWagerStatus(address wagerAddress) external view returns (address, address, uint, uint) {
        return (
            gameWagers[wagerAddress].player0,
            gameWagers[wagerAddress].player1,
            wagerStatus[wagerAddress].winsPlayer0,
            wagerStatus[wagerAddress].winsPlayer1
        );
    }

    /// @notice Checks how much time is remaining in game
    /// @dev using int to quickly check if game lost on time and to prevent underflow revert
    /// @return timeRemainingPlayer0, timeRemainingPlayer1
    function checkTimeRemaining(address wagerAddress) public view returns (int, int) {
        address player0 = gameWagers[wagerAddress].player0;

        uint player0Time = gameWagers[wagerAddress].timePlayer0;
        uint player1Time = gameWagers[wagerAddress].timePlayer1;

        uint elapsedTime = block.timestamp - gameWagers[wagerAddress].timeLastMove;
        int timeLimit = int(gameWagers[wagerAddress].timeLimit);

        address player = getPlayerMove(wagerAddress);

        int timeRemainingPlayer0;
        int timeRemainingPlayer1;

        if (player == player0) {
            timeRemainingPlayer0 = timeLimit - int(elapsedTime + player0Time);
            timeRemainingPlayer1 = timeLimit - int(player1Time);
        } else {
            timeRemainingPlayer0 = timeLimit - int(player0Time);
            timeRemainingPlayer1 = timeLimit - int(elapsedTime + player1Time);
        }

        return (timeRemainingPlayer0, timeRemainingPlayer1);
    }

    /// @notice Gets the address of the player whose turn it is
    /// @param wagerAddress address of the wager
    /// @return user
    function getPlayerMove(address wagerAddress) public view returns (address) {
        uint gameID = gameIDs[wagerAddress].length;
        uint moves = games[wagerAddress][gameID].moves.length;

        bool isPlayer0White = wagerStatus[wagerAddress].isPlayer0White;

        if (isPlayer0White) {
            if (moves % 2 == 1) {
                return gameWagers[wagerAddress].player1;
            } else {
                return gameWagers[wagerAddress].player0;
            }
        } else {
            if (moves % 2 == 1) {
                return gameWagers[wagerAddress].player0;
            } else {
                return gameWagers[wagerAddress].player1;
            }
        }
    }

    /// @notice Returns boolean if player is white or not
    /// @param wagerAddress address of the wager
    /// @param player address player
    /// @return bool
    function isPlayerWhite(address wagerAddress, address player) public view returns (bool) {
        if (gameWagers[wagerAddress].player0 == player) {
            return wagerStatus[wagerAddress].isPlayer0White;
        } else {
            return !wagerStatus[wagerAddress].isPlayer0White;
        }
    }

    /// @notice Gets the game status for the last played game in a wager
    /// @param wagerAddress address of the wager
    /// @return (outcome, gameState, player0State, player1State)
    function getGameStatus(address wagerAddress) public view returns (uint8, uint256, uint32, uint32) {
        uint gameID = gameIDs[wagerAddress].length;
        uint16[] memory moves = games[wagerAddress][gameID].moves;

        if (moves.length == 0) {
            moves = games[wagerAddress][gameID - 1].moves;
        }

        (uint8 outcome, uint256 gameState, uint32 player0State, uint32 player1State) = moveVerification
            .checkGameFromStart(moves);

        return (outcome, gameState, player0State, player1State);
    }

    /// @notice Returns chainId
    /// @dev used for ensuring unique hash independent of chain
    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    /// @notice Generates unique hash for a game wager
    /// @dev using keccak256 to generate a hash which is converted to an address
    /// @return address wagerAddress
    function getWagerAddress(GameWager memory wager) internal view returns (address) {
        require(wager.player0 != wager.player1, "players must be different");
        require(wager.numberOfGames % 2 == 1, "number of games must be odd");

        uint blockNumber = block.number;
        uint chainId = getChainId();
        bytes32 blockHash = blockhash(blockNumber);

        bytes32 salt = keccak256(
            abi.encodePacked(
                wager.player0,
                wager.player1,
                wager.wagerToken,
                wager.wager,
                wager.timeLimit,
                wager.numberOfGames,
                blockNumber,
                chainId,
                blockHash
            )
        );

        address wagerAddress = address(uint160(bytes20(salt)));

        return wagerAddress;
    }

    /* 
    //// TOURNAMENT FUNCTIONS ////
    */

    // Tournament Contract Address
    address public TournamentHandler;

    modifier onlyTournament() {
        require(msg.sender == address(TournamentHandler), "not tournament contract");
        _;
    }

    /// @notice Adds Tournament contract
    function addTournamentHandler(address _tournamentHandler) external OnlyDeployer {
        TournamentHandler = _tournamentHandler;
    }

    /// @notice Starts tournament wagers
    function startWagersInTournament(address wagerAddress) external onlyTournament {
        gameWagers[wagerAddress].timeLastMove = block.timestamp;
    }

    /// @notice Creates a wager between two players
    /// @dev only the tournament contract can call
    /// @return wagerAddress created wager address
    function createGameWagerTournamentSingle(
        address player0,
        address player1,
        address wagerToken,
        uint wagerAmount,
        uint numberOfGames,
        uint timeLimit
    ) external onlyTournament returns (address wagerAddress) {
        GameWager memory gameWager = GameWager(
            player0,
            player1,
            wagerToken,
            wagerAmount,
            numberOfGames,
            true, // hasPlayerAccepted
            timeLimit,
            0, // timeLastMove // setting to zero since tournament hasn't started
            0, // timePlayer0
            0, // timePlayer1
            true, // isTournament
            false // isComplete
        );
        wagerAddress = getWagerAddress(gameWager);

        gameWagers[wagerAddress] = gameWager;

        // player0 is black since randomness is impossible
        // but each subsequent game players switch colors
        WagerStatus memory status = WagerStatus(false, 0, 0);
        wagerStatus[wagerAddress] = status;

        userGames[player0].push(wagerAddress);
        userGames[player1].push(wagerAddress);

        // update global state
        allWagers.push(wagerAddress);

        emit createGameWagerEvent(wagerAddress, wagerToken, wagerAmount, timeLimit, numberOfGames);

        return wagerAddress;
    }

    /*
    //// GASLESS MOVE VERIFICATION FUNCTIONS ////
    */

    /// @notice Generates gasless move message
    function generateMoveMessage(
        address wager,
        uint16 move,
        uint moveNumber,
        uint expiration
    ) public pure returns (bytes memory) {
        return abi.encode(wager, move, moveNumber, expiration);
    }

    /// @notice Generates gasless move hash
    function getMessageHash(
        address wager,
        uint16 move,
        uint moveNumber,
        uint expiration
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(generateMoveMessage(wager, move, moveNumber, expiration)));
    }

    /// @notice Decodes gasless move message
    function decodeMoveMessage(bytes memory message) public pure returns (address, uint16, uint, uint) {
        (address wager, uint16 move, uint moveNumber, uint expiration) = abi.decode(
            message,
            (address, uint16, uint, uint)
        );
        return (wager, move, moveNumber, expiration);
    }

    /// @notice Decodes gasless move message and returns wager address
    function decodeWagerAddress(bytes memory message) internal pure returns (address) {
        (address wager, , , ) = abi.decode(message, (address, uint16, uint, uint));
        return wager;
    }

    /// @notice Gets signed message from gasless move hash
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /// @notice Validates that the signed hash was signed by the player
    function validate(bytes32 messageHash, bytes memory signature, address signer) internal pure {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        require(ECDSA.recover(ethSignedMessageHash, signature) == signer, "invalid sig");
    }

    /// @notice Verifies signed messages and signatures in for loop
    /// @dev returns array of the gasless moves
    function verifyMoves(
        address playerToMove,
        address player0,
        address player1,
        bytes[] memory messages,
        bytes[] memory signatures
    ) internal view returns (uint16[] memory moves) {
        moves = new uint16[](messages.length);
        uint[] memory moveNumbers = new uint[](messages.length);

        GaslessMoveData memory moveData;
        moveData.player0 = player0;
        moveData.player1 = player1;

        for (uint i = 0; i < messages.length; ) {
            // Determine signer based on the move index
            moveData.signer = (i % 2 == 0) == (playerToMove == moveData.player0) ? moveData.player0 : moveData.player1;

            (, moveData.move, moveData.moveNumber, moveData.expiration) = decodeMoveMessage(messages[i]);
            require(moveData.expiration >= block.timestamp, "move expired");

            moveData.messageHash = getMessageHash(
                decodeWagerAddress(messages[i]),
                moveData.move,
                moveData.moveNumber,
                moveData.expiration
            );
            validate(moveData.messageHash, signatures[i], moveData.signer);

            if (i != 0) {
                require(moveNumbers[i - 1] < moveData.moveNumber, "moves must be sequential");
            }
            moveNumbers[i] = moveData.moveNumber;
            moves[i] = moveData.move;

            unchecked {
                i++;
            }
        }

        return moves;
    }

    /// @notice Verifies all signed messages and signatures
    /// @dev appends onchain moves to gasless moves
    /// @dev reverts if invalid signature
    function verifyGameView(
        bytes[] memory messages,
        bytes[] memory signatures
    ) public view returns (address wagerAddress, uint8 outcome, uint16[] memory moves) {
        require(messages.length == signatures.length, "msg.len == sig.len");

        // optimistically use the wagerAddress from the first index
        wagerAddress = decodeWagerAddress(messages[0]);

        address playerToMove = getPlayerMove(wagerAddress);
        address player0 = gameWagers[wagerAddress].player0;
        address player1 = gameWagers[wagerAddress].player1;

        moves = verifyMoves(playerToMove, player0, player1, messages, signatures);

        // appending moves to onChainMoves if they exist
        uint16[] memory onChainMoves = games[wagerAddress][gameIDs[wagerAddress].length].moves;
        if (onChainMoves.length > 0) {
            uint16[] memory combinedMoves = new uint16[](onChainMoves.length + moves.length);
            for (uint i = 0; i < onChainMoves.length; i++) {
                combinedMoves[i] = onChainMoves[i];
            }
            for (uint i = 0; i < moves.length; i++) {
                combinedMoves[i + onChainMoves.length] = moves[i];
            }
            moves = combinedMoves;
        }

        (outcome, , , ) = moveVerification.checkGameFromStart(moves);

        return (wagerAddress, outcome, moves);
    }

    /// @notice Verifies game moves and updates the state of the wager
    function verifyGameUpdateState(bytes[] memory message, bytes[] memory signature) external returns (bool) {
        (address wagerAddress, uint outcome, uint16[] memory moves) = verifyGameView(message, signature);

        uint gameID = gameIDs[wagerAddress].length;
        games[wagerAddress][gameID].moves = moves;

        if (outcome != 0) {
            updateWagerState(wagerAddress);
            return true;
        }
        if (outcome == 0) {
            return updateWagerStateInsufficientMaterial(wagerAddress);
        } else {
            return false;
        }
    }

    /*
    //// WRITE FUNCTIONS ////
    */

    /// @notice Creates a 1v1 chess wager
    function createGameWager(
        address player1,
        address wagerToken,
        uint wager,
        uint timeLimit,
        uint numberOfGames
    ) external payable returns (address wagerAddress) {
        GameWager memory gameWager = GameWager(
            msg.sender, // player0
            player1,
            wagerToken,
            wager,
            numberOfGames,
            false, // hasPlayerAccepted
            timeLimit,
            0, // timeLastMove
            0, // timePlayer0
            0, // timePlayer1
            false, // isTournament
            false // isComplete
        );

        IERC20(wagerToken).safeTransferFrom(msg.sender, address(this), wager);

        wagerAddress = getWagerAddress(gameWager);

        require(gameWagers[wagerAddress].player0 == address(0), "failed to create wager");

        gameWagers[wagerAddress] = gameWager;

        // first player to challenge is black since randomness is impossible
        // each subsequent game players switch colors
        WagerStatus memory status = WagerStatus(false, 0, 0);
        wagerStatus[wagerAddress] = status;

        userGames[msg.sender].push(wagerAddress);
        userGames[player1].push(wagerAddress);

        // update global state
        allWagers.push(wagerAddress);

        emit createGameWagerEvent(wagerAddress, wagerToken, wager, timeLimit, numberOfGames);

        return wagerAddress;
    }

    /// @notice Player1 calls if they accept challenge
    function acceptWager(address wagerAddress) external {
        address player1 = gameWagers[wagerAddress].player1;

        if (player1 == address(0)) {
            gameWagers[wagerAddress].player1 = msg.sender;
            userGames[msg.sender].push(wagerAddress);
        } else {
            require(gameWagers[wagerAddress].player1 == msg.sender, "msg.sender != player1");
        }

        address wagerToken = gameWagers[wagerAddress].wagerToken;
        uint wager = gameWagers[wagerAddress].wager;

        gameWagers[wagerAddress].hasPlayerAccepted = true;
        gameWagers[wagerAddress].timeLastMove = block.timestamp;

        IERC20(wagerToken).safeTransferFrom(msg.sender, address(this), wager);

        emit acceptWagerEvent(wagerAddress, msg.sender);
    }

    /// @notice Plays move on the board
    /// @return bool true if endGame, adds extra game if stalemate
    function playMove(address wagerAddress, uint16 move) external returns (bool) {
        require(getPlayerMove(wagerAddress) == msg.sender, "Not your turn");
        require(getNumberOfGamesPlayed(wagerAddress) <= gameWagers[wagerAddress].numberOfGames, "Wager ended");
        require(gameWagers[wagerAddress].timeLastMove != 0, "Tournament not started yet");

        /// @dev checking if time ran out
        updateTime(wagerAddress, msg.sender);

        bool isEndgameTime = updateWagerStateTime(wagerAddress);
        if (isEndgameTime) {
            return true;
        }

        uint gameID = gameIDs[wagerAddress].length;
        uint size = games[wagerAddress][gameID].moves.length;

        uint16[] memory moves = new uint16[](size + 1);

        /// @dev copy array
        for (uint i = 0; i < size; ) {
            moves[i] = games[wagerAddress][gameID].moves[i];
            unchecked {
                i++;
            }
        }

        /// @dev append move to last place in array
        moves[size] = move;

        /// @dev optimistically write to state
        games[wagerAddress][gameID].moves = moves;

        /// @dev fails on invalid move
        bool isEndgame = updateWagerState(wagerAddress);

        emit playMoveEvent(wagerAddress, move);

        return isEndgame;
    }

    /// @notice Handles payout of wager
    /// @dev smallest wager amount is 18 wei before fees => 0
    function payoutWager(address wagerAddress) external returns (bool) {
        require(
            gameWagers[wagerAddress].player0 == msg.sender || gameWagers[wagerAddress].player1 == msg.sender,
            "not listed"
        );
        require(gameWagers[wagerAddress].isComplete == true, "wager not finished");
        require(gameWagers[wagerAddress].isTournament == false, "tournament payment handled by tournament contract");

        address winner;

        /// @dev if there was a stalemate and now both players have the same score
        /// @dev add another game to play, and return payout successful as false
        if (wagerStatus[wagerAddress].winsPlayer0 == wagerStatus[wagerAddress].winsPlayer1) {
            gameWagers[wagerAddress].numberOfGames++;
            return false;
        }

        if (wagerStatus[wagerAddress].winsPlayer0 > wagerStatus[wagerAddress].winsPlayer1) {
            winner = gameWagers[wagerAddress].player0;
        } else {
            winner = gameWagers[wagerAddress].player1;
        }

        address token = gameWagers[wagerAddress].wagerToken;
        uint wagerAmount = gameWagers[wagerAddress].wager * 2;
        uint prize = wagerPrizes[wagerAddress];

        gameWagers[wagerAddress].wager = 0;
        wagerPrizes[wagerAddress] = 0;

        // 5% shareholder fee
        uint shareHolderFee = ((wagerAmount + prize) * protocolFee) / 10000;
        uint wagerPayout = (wagerAmount + prize) - shareHolderFee;

        IERC20(token).safeTransfer(DividendSplitter, shareHolderFee);
        IERC20(token).safeTransfer(winner, wagerPayout);

        // Mint NFT for Winner
        IChessFishNFT(ChessFishNFT).awardWinner(winner, wagerAddress);

        emit payoutWagerEvent(wagerAddress, winner, token, wagerPayout, protocolFee);

        return true;
    }

    /// @notice Cancel wager
    /// @dev cancel wager only if other player has not yet accepted
    /// @dev && only if msg.sender is one of the players
    function cancelWager(address wagerAddress) external returns (bool) {
        require(gameWagers[wagerAddress].hasPlayerAccepted == false, "in progress");
        require(gameWagers[wagerAddress].player0 == msg.sender, "not listed");
        require(gameWagers[wagerAddress].isTournament == false, "cannot cancel tournament wager");

        address token = gameWagers[wagerAddress].wagerToken;
        uint wagerAmount = gameWagers[wagerAddress].wager;

        gameWagers[wagerAddress].wager = 0;

        IERC20(token).safeTransfer(msg.sender, wagerAmount);

        emit cancelWagerEvent(wagerAddress, msg.sender);

        return true;
    }

    /// @notice Updates the state of the wager if player time is < 0
    /// @dev check when called with timeout w tournament
    /// @dev set to public so that anyone can update time if player disappears
    function updateWagerStateTime(address wagerAddress) public returns (bool) {
        require(getNumberOfGamesPlayed(wagerAddress) <= gameWagers[wagerAddress].numberOfGames, "wager ended");
        require(gameWagers[wagerAddress].timeLastMove != 0, "tournament match not started yet");

        (int timePlayer0, int timePlayer1) = checkTimeRemaining(wagerAddress);

        if (timePlayer0 < 0) {
            wagerStatus[wagerAddress].winsPlayer1 += 1;
            wagerStatus[wagerAddress].isPlayer0White = !wagerStatus[wagerAddress].isPlayer0White;
            gameIDs[wagerAddress].push(gameIDs[wagerAddress].length);
            return true;
        }
        if (timePlayer1 < 0) {
            wagerStatus[wagerAddress].winsPlayer0 += 1;
            wagerStatus[wagerAddress].isPlayer0White = !wagerStatus[wagerAddress].isPlayer0White;
            gameIDs[wagerAddress].push(gameIDs[wagerAddress].length);
            return true;
        }
        return false;
    }

    /// @notice Update wager state if insufficient material
    /// @dev set to public so that anyone can update
    function updateWagerStateInsufficientMaterial(address wagerAddress) public returns (bool) {
        require(getNumberOfGamesPlayed(wagerAddress) <= gameWagers[wagerAddress].numberOfGames, "wager ended");

        uint gameID = gameIDs[wagerAddress].length;
        uint16[] memory moves = games[wagerAddress][gameID].moves;

        (, uint256 gameState, , ) = moveVerification.checkGameFromStart(moves);

        bool isInsufficientMaterial = moveVerification.isStalemateViaInsufficientMaterial(gameState);

        if (isInsufficientMaterial) {
            wagerStatus[wagerAddress].winsPlayer0 += 1;
            wagerStatus[wagerAddress].winsPlayer1 += 1;
            wagerStatus[wagerAddress].isPlayer0White = !wagerStatus[wagerAddress].isPlayer0White;
            gameIDs[wagerAddress].push(gameIDs[wagerAddress].length);
            gameWagers[wagerAddress].numberOfGames += 1;
            return true;
        } else {
            return false;
        }
    }

    /// @notice Deposits prize to wager address
    /// @dev used to deposit prizes to wager
    function depositToWager(address wagerAddress, uint amount) external {
        require(!gameWagers[wagerAddress].isComplete, "wager completed");
        IERC20(gameWagers[wagerAddress].wagerToken).safeTransferFrom(msg.sender, address(this), amount);
        wagerPrizes[wagerAddress] += amount;
    }

    /// @notice Checks the moves of the wager and updates state if neccessary
    function updateWagerState(address wagerAddress) private returns (bool) {
        require(getNumberOfGamesPlayed(wagerAddress) <= gameWagers[wagerAddress].numberOfGames, "wager ended");

        uint gameID = gameIDs[wagerAddress].length;
        uint16[] memory moves = games[wagerAddress][gameID].moves;

        // fails on invalid move
        (uint8 outcome, , , ) = moveVerification.checkGameFromStart(moves);

        // Inconclusive Outcome
        if (outcome == 0) {
            return false;
        }
        // Stalemate
        if (outcome == 1) {
            wagerStatus[wagerAddress].winsPlayer0 += 1;
            wagerStatus[wagerAddress].winsPlayer1 += 1;
            wagerStatus[wagerAddress].isPlayer0White = !wagerStatus[wagerAddress].isPlayer0White;
            gameIDs[wagerAddress].push(gameIDs[wagerAddress].length);
            gameWagers[wagerAddress].numberOfGames += 1;
            return true;
        }
        // Checkmate White
        if (outcome == 2) {
            if (isPlayerWhite(wagerAddress, gameWagers[wagerAddress].player0)) {
                wagerStatus[wagerAddress].winsPlayer0 += 1;
            } else {
                wagerStatus[wagerAddress].winsPlayer1 += 1;
            }
            wagerStatus[wagerAddress].isPlayer0White = !wagerStatus[wagerAddress].isPlayer0White;
            gameIDs[wagerAddress].push(gameIDs[wagerAddress].length);
            if (gameIDs[wagerAddress].length == gameWagers[wagerAddress].numberOfGames) {
                gameWagers[wagerAddress].isComplete = true;
            }
            return true;
        }
        // Checkmate Black
        if (outcome == 3) {
            if (isPlayerWhite(wagerAddress, gameWagers[wagerAddress].player0)) {
                wagerStatus[wagerAddress].winsPlayer1 += 1;
            } else {
                wagerStatus[wagerAddress].winsPlayer0 += 1;
            }
            wagerStatus[wagerAddress].isPlayer0White = !wagerStatus[wagerAddress].isPlayer0White;
            gameIDs[wagerAddress].push(gameIDs[wagerAddress].length);
            if (gameIDs[wagerAddress].length == gameWagers[wagerAddress].numberOfGames) {
                gameWagers[wagerAddress].isComplete = true;
            }
            return true;
        }
        return false;
    }

    /// @notice Updates wager time
    function updateTime(address wagerAddress, address player) private {
        bool isPlayer0 = gameWagers[wagerAddress].player0 == player;
        uint startTime = gameWagers[wagerAddress].timeLastMove;
        uint currentTime = block.timestamp;
        uint dTime = currentTime - startTime;

        if (isPlayer0) {
            gameWagers[wagerAddress].timePlayer0 += dTime;
            gameWagers[wagerAddress].timeLastMove = currentTime; // Update the start time for the next turn
        } else {
            gameWagers[wagerAddress].timePlayer1 += dTime;
            gameWagers[wagerAddress].timeLastMove = currentTime; // Update the start time for the next turn
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IChessFishNFT {
    function awardWinner(address player, address wagerHash) external returns (uint256);
}

interface IChessWager {
    function createGameWagerTournamentSingle(
        address player0,
        address player1,
        address wagerToken,
        uint wagerAmount,
        uint numberOfGames,
        uint timeLimit
    ) external returns (address wagerAddress);

    function startWagersInTournament(address wagerAddress) external;

    function getWagerStatus(address wagerAddress) external view returns (address, address, uint, uint);
}

// SPDX-License-Identifier: MIT

/* 
   _____ _                   ______ _     _     
  / ____| |                 |  ____(_)   | |    
 | |    | |__   ___  ___ ___| |__   _ ___| |__  
 | |    | '_ \ / _ \/ __/ __|  __| | / __| '_ \ 
 | |____| | | |  __/\__ \__ \ |    | \__ \ | | |
  \_____|_| |_|\___||___/___/_|    |_|___/_| |_|
                             
*/

pragma solidity ^0.8.22;

import "./MoveVerification.sol";

/**
 * @title ChessFish MoveHelper Contract
 * @author ChessFish
 * @notice https://github.com/Chess-Fish
 *
 * @dev This contract handles move conversion functionality to the MoveVerifican contract as well as admin functionality.
 */

contract MoveHelper {
    // @dev uint pieces => letter pieces
    mapping(uint8 => string) pieces;

    /// @dev algebraic chess notation string => uint (0-63)
    mapping(string => uint) public coordinates;
    mapping(uint => string) public squareToCoordinate;

    /// @dev address deployer
    address public deployer;

    /// @dev MoveVerification contract
    MoveVerification public moveVerification;

    /// @dev 5% fee to token holders
    uint public protocolFee = 500;

    modifier OnlyDeployer() {
        require(msg.sender == deployer, "Only deployer");
        _;
    }

    /// @dev called from ts since hardcoding the mapping makes the contract too large
    function initCoordinates(string[64] calldata coordinate, uint[64] calldata value) external OnlyDeployer {
        for (int i = 0; i < 64; i++) {
            coordinates[coordinate[uint(i)]] = value[uint(i)];
            squareToCoordinate[value[uint(i)]] = coordinate[uint(i)];
        }
    }

    /// @dev Initialize pieces
    /// @dev This function significantly increases the size of the compiled bytecode...
    function initPieces() internal {
        // blank square
        pieces[0] = ".";

        // white pieces
        pieces[1] = "P";
        pieces[2] = "B";
        pieces[3] = "N";
        pieces[4] = "R";
        pieces[5] = "Q";
        pieces[6] = "K";

        // black pieces
        pieces[9] = "p";
        pieces[10] = "b";
        pieces[11] = "n";
        pieces[12] = "r";
        pieces[13] = "q";
        pieces[14] = "k";
    }

    /**
        @dev Convert the number of a piece to the string character
        @param piece is the number of the piece
        @return string is the letter of the piece
    */
    function getLetter(uint8 piece) public view returns (string memory) {
        string memory letter = pieces[piece];
        return letter;
    }

    /**
        @dev Converts a move from a 16-bit integer to a 2 8-bit integers.
        @param move is the move to convert
        @return fromPos and toPos
    */
    function convertFromMove(uint16 move) public pure returns (uint8, uint8) {
        uint8 fromPos = (uint8)((move >> 6) & 0x3f);
        uint8 toPos = (uint8)(move & 0x3f);
        return (fromPos, toPos);
    }

    /**
        @dev Converts two 8-bit integers to a 16-bit integer
        @param fromPos is the position to move a piece from.
        @param toPos is the position to move a piece to.
        @return move
    */
    function convertToMove(uint8 fromPos, uint8 toPos) public pure returns (uint16) {
        uint16 move = (uint16)(fromPos);
        move = move << 6;
        move = move + (uint16)(toPos);
        return move;
    }

    /**
        @dev Converts an algebraic chess notation string move to uint16 format
        @param move is the move to convert i.e. e2e4 to hex move
        @return hexMove is the resulting uint16 value
    */
    function moveToHex(string memory move) external view returns (uint16 hexMove) {
        bytes memory byteString = bytes(move);

        bytes memory bFromPos = "00";
        bytes memory bToPos = "00";

        bFromPos[0] = byteString[0];
        bFromPos[1] = byteString[1];

        bToPos[0] = byteString[2];
        bToPos[1] = byteString[3];

        string memory sFromPos = string(bFromPos);
        string memory sToPos = string(bToPos);

        uint8 fromPos = uint8(coordinates[sFromPos]);
        uint8 toPos = uint8(coordinates[sToPos]);

        hexMove = convertToMove(fromPos, toPos);

        return hexMove;
    }

    /**
        @dev Converts a uint16 hex value to move in algebraic chess notation
        @param hexMove is the move to convert to string 
        @return move is the resulting string value
    */
    function hexToMove(uint16 hexMove) public view returns (string memory move) {
        uint8 fromPos = uint8(hexMove >> 6);
        uint8 toPos = uint8(hexMove & 0x3f);

        string memory fromCoord = squareToCoordinate[fromPos];
        string memory toCoord = squareToCoordinate[toPos];

        move = string(abi.encodePacked(fromCoord, toCoord));

        return move;
    }

    /**
        @dev returns string of letters representing the board
        @dev only to be called by user or ui
        @param gameState is the uint256 game state of the board 
        @return string[64] is the resulting array 
    */
    function getBoard(uint gameState) external view returns (string[64] memory) {
        string[64] memory board;
        uint j = 0;

        for (uint i = 0; i <= 7; i++) {
            int pos = ((int(i) + 1) * 8) - 1;
            int last = pos - 7;
            for (pos; pos >= last; pos--) {
                uint8 piece = moveVerification.pieceAtPosition(gameState, uint8(uint(pos)));

                board[j] = getLetter(piece);

                j++;
            }
        }
        return board;
    }
}

// SPDX-License-Identifier: MIT

/* 
   _____ _                   ______ _     _     
  / ____| |                 |  ____(_)   | |    
 | |    | |__   ___  ___ ___| |__   _ ___| |__  
 | |    | '_ \ / _ \/ __/ __|  __| | / __| '_ \ 
 | |____| | | |  __/\__ \__ \ |    | \__ \ | | |
  \_____|_| |_|\___||___/___/_|    |_|___/_| |_|
                             
*/

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title ChessFish MoveVerification Contract
 * @author ChessFish
 * @notice https://github.com/Chess-Fish
 * @notice Forked from: https://github.com/marioevz/chess.eth (Updated from Solidity 0.7.6 to 0.8.17 & Added features and functionality)
 *
 * @notice This contract handles the logic for verifying the validity moves on the chessboard. Currently, pawns autoqueen by default.
 */

contract MoveVerification {
    uint8 constant empty_const = 0x0;
    uint8 constant pawn_const = 0x1; // 001
    uint8 constant bishop_const = 0x2; // 010
    uint8 constant knight_const = 0x3; // 011
    uint8 constant rook_const = 0x4; // 100
    uint8 constant queen_const = 0x5; // 101
    uint8 constant king_const = 0x6; // 110
    uint8 constant type_mask_const = 0x7;
    uint8 constant color_const = 0x8;

    uint8 constant piece_bit_size = 4;
    uint8 constant piece_pos_shift_bit = 2;

    uint32 constant en_passant_const = 0x000000ff;
    uint32 constant king_pos_mask = 0x0000ff00;
    uint32 constant king_pos_zero_mask = 0xffff00ff;
    uint16 constant king_pos_bit = 8;

    /**
        @dev For castling masks, mask only the last bit of an uint8, to block any under/overflows.
    */
    uint32 constant rook_king_side_move_mask = 0x00800000;
    uint16 constant rook_king_side_move_bit = 16;
    uint32 constant rook_queen_side_move_mask = 0x80000000;
    uint16 constant rook_queen_side_move_bit = 24;
    uint32 constant king_move_mask = 0x80800000;

    uint16 constant pieces_left_bit = 32;

    uint8 constant king_white_start_pos = 0x04;
    uint8 constant king_black_start_pos = 0x3c;

    uint16 constant pos_move_mask = 0xfff;

    uint16 constant request_draw_const = 0x1000;
    uint16 constant accept_draw_const = 0x2000;
    uint16 constant resign_const = 0x3000;

    uint8 constant inconclusive_outcome = 0x0;
    uint8 constant draw_outcome = 0x1;
    uint8 constant white_win_outcome = 0x2;
    uint8 constant black_win_outcome = 0x3;

    uint256 constant game_state_start = 0xcbaedabc99999999000000000000000000000000000000001111111143265234;

    uint256 constant full_long_word_mask = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 constant invalid_move_constant = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /** @dev    Initial white state:
                0f: 15 (non-king) pieces left
                00: Queen-side rook at a1 position
                07: King-side rook at h1 position
                04: King at e1 position
                ff: En-passant at invalid position
    */
    uint32 constant initial_white_state = 0x000704ff;

    /** @dev    Initial black state:
                0f: 15 (non-king) pieces left
                38: Queen-side rook at a8 position
                3f: King-side rook at h8 position
                3c: King at e8 position
                ff: En-passant at invalid position
    */
    uint32 constant initial_black_state = 0x383f3cff;

    // @dev chess game from start using hex moves
    // @dev returns outcome, gameState, player0State, player1State
    function checkGameFromStart(uint16[] memory moves) public pure returns (uint8, uint256, uint32, uint32) {
        return checkGame(game_state_start, initial_white_state, initial_black_state, false, moves);
    }

    /**
        @dev Calculates the outcome of a game depending on the moves from a starting position.
             Reverts when an invalid move is found.
        @param startingGameState Game state from which start the movements
        @param startingPlayerState State of the first playing player
        @param startingOpponentState State of the other playing player
        @param startingTurnBlack Whether the starting player is the black pieces
        @param moves is the input array containing all the moves in the game
        @return outcome can be 0 for inconclusive, 1 for draw, 2 for white winning, 3 for black winning
     */
    function checkGame(
        uint256 startingGameState,
        uint32 startingPlayerState,
        uint32 startingOpponentState,
        bool startingTurnBlack,
        uint16[] memory moves
    ) public pure returns (uint8 outcome, uint256 gameState, uint32 playerState, uint32 opponentState) {
        gameState = startingGameState;

        playerState = startingPlayerState;
        opponentState = startingOpponentState;

        outcome = inconclusive_outcome;

        bool currentTurnBlack = startingTurnBlack;

        require(moves.length > 0, "inv moves");

        if (moves[moves.length - 1] == accept_draw_const) {
            // Check
            require(moves.length >= 2, "inv draw");
            require(moves[moves.length - 2] == request_draw_const, "inv draw");
            outcome = draw_outcome;
        } else if (moves[moves.length - 1] == resign_const) {
            // Assumes that signatures have been checked and moves are in correct order
            outcome = ((moves.length % 2) == 1) != currentTurnBlack ? black_win_outcome : white_win_outcome;
        } else {
            // Check entire game
            for (uint256 i = 0; i < moves.length; ) {
                (gameState, opponentState, playerState) = verifyExecuteMove(
                    gameState,
                    moves[i],
                    playerState,
                    opponentState,
                    currentTurnBlack
                );
                unchecked {
                    i++;
                }

                require(!checkForCheck(gameState, opponentState), "inv check");
                //require (outcome == 0 || i == (moves.length - 1), "Excesive moves");
                currentTurnBlack = !currentTurnBlack;
            }

            uint8 endgameOutcome = checkEndgame(gameState, playerState, opponentState);

            if (endgameOutcome == 2) {
                outcome = currentTurnBlack ? white_win_outcome : black_win_outcome;
            } else if (endgameOutcome == 1) {
                outcome = draw_outcome;
            }
        }
    }

    /**
        @dev Calculates the outcome of a single move given the current game state.
             Reverts for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param move is the move to execute: 16-bit var, high word = from pos, low word = to pos
                move can also be: resign, request draw, accept draw.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteMove(
        uint256 gameState,
        uint16 move,
        uint32 playerState,
        uint32 opponentState,
        bool currentTurnBlack
    ) public pure returns (uint256 newGameState, uint32 newPlayerState, uint32 newOpponentState) {
        // TODO: check resigns and other stuff first
        uint8 fromPos = (uint8)((move >> 6) & 0x3f);
        uint8 toPos = (uint8)(move & 0x3f);

        require(fromPos != toPos, "inv move stale");

        uint8 fromPiece = pieceAtPosition(gameState, fromPos);

        require(((fromPiece & color_const) > 0) == currentTurnBlack, "inv move color");

        uint8 fromType = fromPiece & type_mask_const;

        newPlayerState = playerState;
        newOpponentState = opponentState;

        if (fromType == pawn_const) {
            (newGameState, newPlayerState) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                (uint8)(move >> 12),
                currentTurnBlack,
                playerState,
                opponentState
            );
        } else if (fromType == knight_const) {
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
        } else if (fromType == bishop_const) {
            newGameState = verifyExecuteBishopMove(gameState, fromPos, toPos, currentTurnBlack);
        } else if (fromType == rook_const) {
            newGameState = verifyExecuteRookMove(gameState, fromPos, toPos, currentTurnBlack);
            // Reset playerState if necessary when one of the rooks move

            if (fromPos == (uint8)(playerState >> rook_king_side_move_bit)) {
                newPlayerState = playerState | rook_king_side_move_mask;
            } else if (fromPos == (uint8)(playerState >> rook_queen_side_move_bit)) {
                newPlayerState = playerState | rook_queen_side_move_mask;
            }
        } else if (fromType == queen_const) {
            newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
        } else if (fromType == king_const) {
            (newGameState, newPlayerState) = verifyExecuteKingMove(
                gameState,
                fromPos,
                toPos,
                currentTurnBlack,
                playerState
            );
        } else {
            revert("inv move type");
        }
        require(newGameState != invalid_move_constant, "inv move");

        // Check for en passant only if the piece moving is a pawn... smh
        if (
            pawn_const == pieceAtPosition(gameState, fromPos) ||
            pawn_const + color_const == pieceAtPosition(gameState, fromPos)
        ) {
            if (toPos == (opponentState & en_passant_const)) {
                if (currentTurnBlack) {
                    newGameState = zeroPosition(newGameState, toPos + 8);
                } else {
                    newGameState = zeroPosition(newGameState, toPos - 8);
                }
            }
        }
        newOpponentState = opponentState | en_passant_const;
    }

    /**
        @dev Calculates the outcome of a single move of a pawn given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecutePawnMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        uint8 moveExtra,
        bool currentTurnBlack,
        uint32 playerState,
        uint32 opponentState
    ) public pure returns (uint256 newGameState, uint32 newPlayerState) {
        newPlayerState = playerState;
        // require ((currentTurnBlack && (toPos < fromPos)) || (!currentTurnBlack && (fromPos < toPos)), "inv move");
        if (currentTurnBlack != (toPos < fromPos)) {
            // newGameState = invalid_move_constant;
            return (invalid_move_constant, 0x0);
        }
        uint8 diff = (uint8)(Math.max(fromPos, toPos) - Math.min(fromPos, toPos));
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);

        if (diff == 8 || diff == 16) {
            if (pieceToPosition != 0) {
                //newGameState = invalid_move_constant;
                return (invalid_move_constant, 0x0);
            }
            if (diff == 16) {
                if ((currentTurnBlack && ((fromPos >> 3) != 0x6)) || (!currentTurnBlack && ((fromPos >> 3) != 0x1))) {
                    return (invalid_move_constant, 0x0);
                }
                uint8 posToInBetween = toPos > fromPos ? fromPos + 8 : toPos + 8;
                if (pieceAtPosition(gameState, posToInBetween) != 0) {
                    return (invalid_move_constant, 0x0);
                }
                newPlayerState = (newPlayerState & (~en_passant_const)) | (uint32)(posToInBetween);
            }
        } else if (diff == 7 || diff == 9) {
            if (getVerticalMovement(fromPos, toPos) != 1) {
                return (invalid_move_constant, 0x0);
            }
            if ((uint8)(opponentState & en_passant_const) != toPos) {
                if (
                    (pieceToPosition == 0) || (currentTurnBlack == ((pieceToPosition & color_const) == color_const)) // Must be moving to occupied square // Must be different color
                ) {
                    return (invalid_move_constant, 0x0);
                }
            }
        } else return (invalid_move_constant, 0x0);

        newGameState = commitMove(gameState, fromPos, toPos);
        if ((currentTurnBlack && ((toPos >> 3) == 0x0)) || (!currentTurnBlack && ((toPos >> 3) == 0x7))) {
            // @dev Handling Promotion:
            // Currently Promotion is set to autoqueen
            /*   
            require ((moveExtra == bishop_const) || (moveExtra == knight_const) ||
                     (moveExtra == rook_const) || (moveExtra == queen_const), "inv prom");
            */
            // auto queen promote
            moveExtra = queen_const;

            newGameState = setPosition(
                zeroPosition(newGameState, toPos),
                toPos,
                currentTurnBlack ? moveExtra | color_const : moveExtra
            );
        }

        require(newPlayerState != 0, "pawn");
    }

    /**
        @dev Calculates the outcome of a single move of a knight given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteKnightMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack
    ) public pure returns (uint256) {
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);

        if (pieceToPosition > 0) {
            if (((pieceToPosition & color_const) == color_const) == currentTurnBlack) {
                return invalid_move_constant;
            }
        }

        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);

        if (!((h == 2 && v == 1) || (h == 1 && v == 2))) {
            return invalid_move_constant;
        }

        return commitMove(gameState, fromPos, toPos);
    }

    /**
        @dev Calculates the outcome of a single move of a bishop given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteBishopMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack
    ) public pure returns (uint256) {
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);

        if (pieceToPosition > 0) {
            if (((pieceToPosition & color_const) == color_const) == currentTurnBlack) {
                return invalid_move_constant;
            }
        }

        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);

        if ((h != v) || ((gameState & getInBetweenMask(fromPos, toPos)) != 0x00)) {
            return invalid_move_constant;
        }

        return commitMove(gameState, fromPos, toPos);
    }

    /**
        @dev Calculates the outcome of a single move of a rook given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteRookMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack
    ) public pure returns (uint256) {
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);
        if (pieceToPosition > 0) {
            if (((pieceToPosition & color_const) == color_const) == currentTurnBlack) {
                return invalid_move_constant;
            }
        }

        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);

        if (((h > 0) == (v > 0)) || (gameState & getInBetweenMask(fromPos, toPos)) != 0x00) {
            return invalid_move_constant;
        }

        return commitMove(gameState, fromPos, toPos);
    }

    /**
        @dev Calculates the outcome of a single move of the queen given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
    */
    function verifyExecuteQueenMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack
    ) public pure returns (uint256) {
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);
        if (pieceToPosition > 0) {
            if (((pieceToPosition & color_const) == color_const) == currentTurnBlack) {
                return invalid_move_constant;
            }
        }
        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);
        if (((h != v) && (h != 0) && (v != 0)) || (gameState & getInBetweenMask(fromPos, toPos)) != 0x00) {
            return invalid_move_constant;
        }

        return commitMove(gameState, fromPos, toPos);
    }

    /**
        @dev Calculates the outcome of a single move of the king given the current game state.
             Returns invalid_move_constant for invalid movement.
        @param gameState current game state on which to perform the movement.
        @param fromPos is position moving from. Behavior is undefined for values >= 0x40.
        @param toPos is position moving to. Behavior is undefined for values >= 0x40.
        @param currentTurnBlack true if it's black turn
        @return newGameState the new game state after it's executed.
     */
    function verifyExecuteKingMove(
        uint256 gameState,
        uint8 fromPos,
        uint8 toPos,
        bool currentTurnBlack,
        uint32 playerState
    ) public pure returns (uint256 newGameState, uint32 newPlayerState) {
        newPlayerState = ((playerState | king_move_mask) & king_pos_zero_mask) | ((uint32)(toPos) << king_pos_bit);
        uint8 pieceToPosition = pieceAtPosition(gameState, toPos);

        if (pieceToPosition > 0) {
            if (((pieceToPosition & color_const) == color_const) == currentTurnBlack) {
                return (invalid_move_constant, newPlayerState);
            }
        }
        if (toPos >= 0x40 || fromPos >= 0x40) {
            return (invalid_move_constant, newPlayerState);
        }

        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);

        if ((h <= 1) && (v <= 1)) {
            return (commitMove(gameState, fromPos, toPos), newPlayerState);
        } else if ((h == 2) && (v == 0)) {
            if (!pieceUnderAttack(gameState, fromPos)) {
                // TODO: must we check king's 'from' position?
                // Reasoning: castilngRookPosition resolves to an invalid toPos when the rook or the king have already moved.
                uint8 castilngRookPosition = (uint8)(playerState >> rook_queen_side_move_bit);
                if (castilngRookPosition + 2 == toPos) {
                    // Queen-side castling
                    // Spaces between king and rook original positions must be empty
                    if ((getInBetweenMask(castilngRookPosition, fromPos) & gameState) == 0) {
                        // Move King 1 space to the left and check for attacks (there must be none)
                        newGameState = commitMove(gameState, fromPos, fromPos - 1);
                        if (!pieceUnderAttack(newGameState, fromPos - 1)) {
                            return (
                                commitMove(
                                    commitMove(newGameState, fromPos - 1, toPos),
                                    castilngRookPosition,
                                    fromPos - 1
                                ),
                                newPlayerState
                            );
                        }
                    }
                } else {
                    castilngRookPosition = (uint8)(playerState >> rook_king_side_move_bit);
                    if (castilngRookPosition - 1 == toPos) {
                        // King-side castling
                        // Spaces between king and rook original positions must be empty
                        if ((getInBetweenMask(castilngRookPosition, fromPos) & gameState) == 0) {
                            // Move King 1 space to the left and check for attacks (there must be none)
                            newGameState = commitMove(gameState, fromPos, fromPos + 1);
                            if (!pieceUnderAttack(newGameState, fromPos + 1)) {
                                return (
                                    commitMove(
                                        commitMove(newGameState, fromPos + 1, toPos),
                                        castilngRookPosition,
                                        fromPos + 1
                                    ),
                                    newPlayerState
                                );
                            }
                        }
                    }
                }
            }
        }

        return (invalid_move_constant, 0x00);
    }

    /**
        @dev Checks if a move is valid for the queen in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the queen is moving.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkQueenValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 kingPos = (uint8)(
            playerState >> king_pos_bit
        ); /* Kings position cannot be affected by Queen's movement */

        unchecked {
            // Check left
            for (toPos = fromPos - 1; (toPos & 0x7) < (fromPos & 0x7); toPos--) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check right
            for (toPos = fromPos + 1; (toPos & 0x7) > (fromPos & 0x7); toPos++) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check up
            for (toPos = fromPos + 8; toPos < 0x40; toPos += 8) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check down
            for (toPos = fromPos - 8; toPos < fromPos; toPos -= 8) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check up-right
            for (toPos = fromPos + 9; (toPos < 0x40) && ((toPos & 0x7) > (fromPos & 0x7)); toPos += 9) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check up-left
            for (toPos = fromPos + 7; (toPos < 0x40) && ((toPos & 0x7) < (fromPos & 0x7)); toPos += 7) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check down-right
            for (toPos = fromPos - 7; (toPos < fromPos) && ((toPos & 0x7) > (fromPos & 0x7)); toPos -= 7) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check down-left
            for (toPos = fromPos - 9; (toPos < fromPos) && ((toPos & 0x7) < (fromPos & 0x7)); toPos -= 9) {
                newGameState = verifyExecuteQueenMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }
        }

        return false;
    }

    /**
        @dev Checks if a move is valid for the bishop in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the bishop is moving. Behavior is undefined for values >= 0x40.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkBishopValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 kingPos = (uint8)(
            playerState >> king_pos_bit
        ); /* Kings position cannot be affected by Bishop's movement */

        unchecked {
            // Check up-right
            for (toPos = fromPos + 9; (toPos < 0x40) && ((toPos & 0x7) > (fromPos & 0x7)); toPos += 9) {
                newGameState = verifyExecuteBishopMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check up-left
            for (toPos = fromPos + 7; (toPos < 0x40) && ((toPos & 0x7) < (fromPos & 0x7)); toPos += 7) {
                newGameState = verifyExecuteBishopMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check down-right
            for (toPos = fromPos - 7; (toPos < fromPos) && ((toPos & 0x7) > (fromPos & 0x7)); toPos -= 7) {
                newGameState = verifyExecuteBishopMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check down-left
            for (toPos = fromPos - 9; (toPos < fromPos) && ((toPos & 0x7) < (fromPos & 0x7)); toPos -= 9) {
                newGameState = verifyExecuteBishopMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }
        }

        return false;
    }

    /**
        @dev Checks if a move is valid for the rook in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the rook is moving. Behavior is undefined for values >= 0x40.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkRookValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 kingPos = (uint8)(playerState >> king_pos_bit); /* Kings position cannot be affected by Rook's movement */

        unchecked {
            // Check left
            for (toPos = fromPos - 1; (toPos & 0x7) < (fromPos & 0x7); toPos--) {
                newGameState = verifyExecuteRookMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check right
            for (toPos = fromPos + 1; (toPos & 0x7) > (fromPos & 0x7); toPos++) {
                newGameState = verifyExecuteRookMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check up
            for (toPos = fromPos + 8; toPos < 0x40; toPos += 8) {
                newGameState = verifyExecuteRookMove(gameState, fromPos, toPos, currentTurnBlack);

                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }

            // Check down
            for (toPos = fromPos - 8; toPos < fromPos; toPos -= 8) {
                newGameState = verifyExecuteRookMove(gameState, fromPos, toPos, currentTurnBlack);
                if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                    return true;
                }
                if (((gameState >> (toPos << piece_pos_shift_bit)) & 0xF) != 0) break;
            }
        }

        return false;
    }

    /**
        @dev Checks if a move is valid for the knight in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the knight is moving. Behavior is undefined for values >= 0x40.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkKnightValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 kingPos = (uint8)(
            playerState >> king_pos_bit
        ); /* Kings position cannot be affected by knight's movement */

        unchecked {
            toPos = fromPos + 6;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos - 6;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos + 10;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos - 10;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos - 17;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos + 17;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos + 15;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = fromPos - 15;
            newGameState = verifyExecuteKnightMove(gameState, fromPos, toPos, currentTurnBlack);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }
        }

        return false;
    }

    /**
        @dev Checks if a move is valid for the pawn in the given game state.
            Returns true if the move is valid, false otherwise.
        @param gameState The current game state on which to perform the movement.
        @param fromPos The position from which the knight is moving. Behavior is undefined for values >= 0x40.
        @param playerState The player's state containing information about the king position.
        @param currentTurnBlack True if it's black's turn, false otherwise.
        @return A boolean indicating whether the move is valid or not.
    */
    function checkPawnValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        uint32 opponentState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;
        uint8 moveExtra = queen_const; /* Since this is supposed to be endgame, movement of promoted piece is irrelevant. */
        uint8 kingPos = (uint8)(playerState >> king_pos_bit); /* Kings position cannot be affected by pawn's movement */

        unchecked {
            toPos = currentTurnBlack ? fromPos - 7 : fromPos + 7;
            (newGameState, ) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                moveExtra,
                currentTurnBlack,
                playerState,
                opponentState
            );
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = currentTurnBlack ? fromPos - 8 : fromPos + 8;
            (newGameState, ) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                moveExtra,
                currentTurnBlack,
                playerState,
                opponentState
            );
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = currentTurnBlack ? fromPos - 9 : fromPos + 9;
            (newGameState, ) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                moveExtra,
                currentTurnBlack,
                playerState,
                opponentState
            );
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }

            toPos = currentTurnBlack ? fromPos - 16 : fromPos + 16;
            (newGameState, ) = verifyExecutePawnMove(
                gameState,
                fromPos,
                toPos,
                moveExtra,
                currentTurnBlack,
                playerState,
                opponentState
            );
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, kingPos))) {
                return true;
            }
        }

        return false;
    }

    function checkKingValidMoves(
        uint256 gameState,
        uint8 fromPos,
        uint32 playerState,
        bool currentTurnBlack
    ) public pure returns (bool) {
        uint256 newGameState;
        uint8 toPos;

        unchecked {
            toPos = fromPos - 9;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos - 8;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos - 7;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos - 1;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos + 1;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos + 7;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos + 8;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }

            toPos = fromPos + 9;
            (newGameState, ) = verifyExecuteKingMove(gameState, fromPos, toPos, currentTurnBlack, playerState);
            if ((newGameState != invalid_move_constant) && (!pieceUnderAttack(newGameState, toPos))) {
                return true;
            }
        }

        /* TODO: Check castling */

        return false;
    }

    /**
        @dev Performs one iteration of recursive search for pieces. 
        @param gameState Game state from which start the movements
        @param playerState State of the player
        @param opponentState State of the opponent
        @return returns true if any of the pieces in the current offest has legal moves
    */
    function searchPiece(
        uint256 gameState,
        uint32 playerState,
        uint32 opponentState,
        uint8 color,
        uint16 pBitOffset,
        uint16 bitSize
    ) public pure returns (bool) {
        if (bitSize > piece_bit_size) {
            uint16 newBitSize = bitSize / 2;
            uint256 m = ~(full_long_word_mask << newBitSize);
            uint256 h = (gameState >> (pBitOffset + newBitSize)) & m;

            if (h != 0) {
                if (searchPiece(gameState, playerState, opponentState, color, pBitOffset + newBitSize, newBitSize)) {
                    return true;
                }
            }

            uint256 l = (gameState >> pBitOffset) & m;

            if (l != 0) {
                if (searchPiece(gameState, playerState, opponentState, color, pBitOffset, newBitSize)) {
                    return true;
                }
            }
        } else {
            uint8 piece = (uint8)((gameState >> pBitOffset) & 0xF);

            if ((piece > 0) && ((piece & color_const) == color)) {
                uint8 pos = uint8(pBitOffset / piece_bit_size);
                bool currentTurnBlack = color != 0;
                uint8 pieceType = piece & type_mask_const;

                if ((pieceType == king_const) && checkKingValidMoves(gameState, pos, playerState, currentTurnBlack)) {
                    return true;
                } else if (
                    (pieceType == pawn_const) &&
                    checkPawnValidMoves(gameState, pos, playerState, opponentState, currentTurnBlack)
                ) {
                    return true;
                } else if (
                    (pieceType == knight_const) && checkKnightValidMoves(gameState, pos, playerState, currentTurnBlack)
                ) {
                    return true;
                } else if (
                    (pieceType == rook_const) && checkRookValidMoves(gameState, pos, playerState, currentTurnBlack)
                ) {
                    return true;
                } else if (
                    (pieceType == bishop_const) && checkBishopValidMoves(gameState, pos, playerState, currentTurnBlack)
                ) {
                    return true;
                } else if (
                    (pieceType == queen_const) && checkQueenValidMoves(gameState, pos, playerState, currentTurnBlack)
                ) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
        @dev Checks the endgame state and determines whether the last user is checkmate'd or
             stalemate'd, or neither.
        @param gameState Game state from which start the movements
        @param playerState State of the player
        @return outcome can be 0 for inconclusive/only check, 1 stalemate, 2 checkmate
     */
    function checkEndgame(uint256 gameState, uint32 playerState, uint32 opponentState) public pure returns (uint8) {
        uint8 kingPiece = (uint8)(gameState >> ((uint8)(playerState >> king_pos_bit) << piece_pos_shift_bit)) & 0xF;

        require((kingPiece & (~color_const)) == king_const, "934");

        bool legalMoves = searchPiece(gameState, playerState, opponentState, color_const & kingPiece, 0, 256);

        // If the player is in check but also
        if (checkForCheck(gameState, playerState)) {
            return legalMoves ? 0 : 2;
        }
        return legalMoves ? 0 : 1;
    }

    /**
        @dev Gets the mask of the in-between squares.
             Basically it performs bit-shifts depending on the movement.
             Down: >> 8
             Up: << 8
             Right: << 1
             Left: >> 1
             UpRight: << 9
             DownLeft: >> 9
             DownRight: >> 7
             UpLeft: << 7
             Reverts for invalid movement.
        @param fromPos is position moving from.
        @param toPos is position moving to.
        @return mask of the in-between squares, can be bit-wise-and with the game state to check squares
     */
    function getInBetweenMask(uint8 fromPos, uint8 toPos) public pure returns (uint256) {
        uint8 h = getHorizontalMovement(fromPos, toPos);
        uint8 v = getVerticalMovement(fromPos, toPos);
        require((h == v) || (h == 0) || (v == 0), "inv move");

        // TODO: Remove this getPositionMask usage
        uint256 startMask = getPositionMask(fromPos);
        uint256 endMask = getPositionMask(toPos);
        int8 x = (int8)(toPos & 0x7) - (int8)(fromPos & 0x7);
        int8 y = (int8)(toPos >> 3) - (int8)(fromPos >> 3);
        uint8 s = 0;

        if (((x > 0) && (y > 0)) || ((x < 0) && (y < 0))) {
            s = 9 * 4;
        } else if ((x == 0) && (y != 0)) {
            s = 8 * 4;
        } else if (((x > 0) && (y < 0)) || ((x < 0) && (y > 0))) {
            s = 7 * 4;
        } else if ((x != 0) && (y == 0)) {
            s = 1 * 4;
        }

        uint256 outMask = 0x00;

        while (endMask != startMask) {
            if (startMask < endMask) {
                startMask <<= s;
            } else {
                startMask >>= s;
            }
            if (endMask != startMask) outMask |= startMask;
        }

        return outMask;
    }

    /**
        @dev Gets the mask (0xF) of a square
        @param pos square position.
        @return mask
    */
    function getPositionMask(uint8 pos) public pure returns (uint256) {
        return (uint256)(0xF) << ((((pos >> 3) & 0x7) * 32) + ((pos & 0x7) * 4));
    }

    /**
        @dev Calculates the horizontal movement between two positions on a chessboard.
        @param fromPos The starting position from which the movement is measured.
        @param toPos The ending position to which the movement is measured.
        @return The horizontal movement between the two positions.
    */
    function getHorizontalMovement(uint8 fromPos, uint8 toPos) public pure returns (uint8) {
        return (uint8)(Math.max(fromPos & 0x7, toPos & 0x7) - Math.min(fromPos & 0x7, toPos & 0x7));
    }

    /**
        @dev Calculates the vertical movement between two positions on a chessboard.
        @param fromPos The starting position from which the movement is measured.
        @param toPos The ending position to which the movement is measured.
        @return The vertical movement between the two positions.
    */
    function getVerticalMovement(uint8 fromPos, uint8 toPos) public pure returns (uint8) {
        return (uint8)(Math.max(fromPos >> 3, toPos >> 3) - Math.min(fromPos >> 3, toPos >> 3));
    }

    /**
        @dev Checks if the king in the given game state is under attack (check condition).
        @param gameState The current game state to analyze.
        @param playerState The player's state containing information about the king position.
        @return A boolean indicating whether the king is under attack (check) or not.
    */
    function checkForCheck(uint256 gameState, uint32 playerState) public pure returns (bool) {
        uint8 kingsPosition = (uint8)(playerState >> king_pos_bit);

        require(king_const == (pieceAtPosition(gameState, kingsPosition) & 0x7), "NOT KING");

        return pieceUnderAttack(gameState, kingsPosition);
    }

    /**
    @dev Checks if a piece at the given position is under attack in the given game state.
    @param gameState The current game state to analyze.
    @param pos The position of the piece to check for attack.
    @return A boolean indicating whether the piece at the given position is under attack.
    */
    function pieceUnderAttack(uint256 gameState, uint8 pos) public pure returns (bool) {
        // When migrating from 0.7.6 to 0.8.17 tests would fail when calling this function
        // this is why this code is left unchecked
        // should find exactly where it phantom overflows / underflows
        // hint: its where things get multiplied...

        unchecked {
            uint8 currPiece = (uint8)(gameState >> (pos * piece_bit_size)) & 0xf;
            uint8 enemyPawn = pawn_const | ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyBishop = bishop_const | ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyKnight = knight_const | ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyRook = rook_const | ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyQueen = queen_const | ((currPiece & color_const) > 0 ? 0x0 : color_const);
            uint8 enemyKing = king_const | ((currPiece & color_const) > 0 ? 0x0 : color_const);

            currPiece = 0x0;

            uint8 currPos;
            bool firstSq;
            // Check up
            firstSq = true;
            currPos = pos + 8;
            while (currPos < 0x40) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (currPiece == enemyRook || currPiece == enemyQueen || (firstSq && (currPiece == enemyKing)))
                        return true;
                    break;
                }
                currPos += 8;
                firstSq = false;
            }

            // Check down
            firstSq = true;
            currPos = pos - 8;
            while (currPos < pos) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (currPiece == enemyRook || currPiece == enemyQueen || (firstSq && (currPiece == enemyKing)))
                        return true;
                    break;
                }
                currPos -= 8;
                firstSq = false;
            }

            // Check right
            firstSq = true;
            currPos = pos + 1;
            while ((pos >> 3) == (currPos >> 3)) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (currPiece == enemyRook || currPiece == enemyQueen || (firstSq && (currPiece == enemyKing)))
                        return true;
                    break;
                }
                currPos += 1;
                firstSq = false;
            }

            // Check left
            firstSq = true;
            currPos = pos - 1;
            while ((pos >> 3) == (currPos >> 3)) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (currPiece == enemyRook || currPiece == enemyQueen || (firstSq && (currPiece == enemyKing)))
                        return true;
                    break;
                }
                currPos -= 1;
                firstSq = false;
            }

            // Check up-right
            firstSq = true;
            currPos = pos + 9;
            while ((currPos < 0x40) && ((currPos & 0x7) > (pos & 0x7))) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyBishop ||
                        currPiece == enemyQueen ||
                        (firstSq &&
                            ((currPiece == enemyKing) ||
                                ((currPiece == enemyPawn) && ((enemyPawn & color_const) == color_const))))
                    ) return true;
                    break;
                }
                currPos += 9;
                firstSq = false;
            }

            // Check up-left
            firstSq = true;
            currPos = pos + 7;
            while ((currPos < 0x40) && ((currPos & 0x7) < (pos & 0x7))) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyBishop ||
                        currPiece == enemyQueen ||
                        (firstSq &&
                            ((currPiece == enemyKing) ||
                                ((currPiece == enemyPawn) && ((enemyPawn & color_const) == color_const))))
                    ) return true;
                    break;
                }
                currPos += 7;
                firstSq = false;
            }

            // Check down-right
            firstSq = true;
            currPos = pos - 7;
            while ((currPos < 0x40) && ((currPos & 0x7) > (pos & 0x7))) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyBishop ||
                        currPiece == enemyQueen ||
                        (firstSq &&
                            ((currPiece == enemyKing) ||
                                ((currPiece == enemyPawn) && ((enemyPawn & color_const) == 0x0))))
                    ) return true;
                    break;
                }
                currPos -= 7;
                firstSq = false;
            }

            // Check down-left
            firstSq = true;
            currPos = pos - 9;
            while ((currPos < 0x40) && ((currPos & 0x7) < (pos & 0x7))) {
                currPiece = (uint8)(gameState >> (currPos * piece_bit_size)) & 0xf;
                if (currPiece > 0) {
                    if (
                        currPiece == enemyBishop ||
                        currPiece == enemyQueen ||
                        (firstSq &&
                            ((currPiece == enemyKing) ||
                                ((currPiece == enemyPawn) && ((enemyPawn & color_const) == 0x0))))
                    ) return true;
                    break;
                }
                currPos -= 9;
                firstSq = false;
            }

            // Check knights
            // 1 right 2 up
            currPos = pos + 17;
            if (
                (currPos < 0x40) &&
                ((currPos & 0x7) > (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;
            // 1 left 2 up
            currPos = pos + 15;
            if (
                (currPos < 0x40) &&
                ((currPos & 0x7) < (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;
            // 2 right 1 up
            currPos = pos + 10;
            if (
                (currPos < 0x40) &&
                ((currPos & 0x7) > (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;
            // 2 left 1 up
            currPos = pos + 6;
            if (
                (currPos < 0x40) &&
                ((currPos & 0x7) < (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;

            // 1 left 2 down
            currPos = pos - 17;
            if (
                (currPos < pos) &&
                ((currPos & 0x7) < (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;

            // 2 left 1 down
            currPos = pos - 10;
            if (
                (currPos < pos) &&
                ((currPos & 0x7) < (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;

            // 1 right 2 down
            currPos = pos - 15;
            if (
                (currPos < pos) &&
                ((currPos & 0x7) > (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;
            // 2 right 1 down
            currPos = pos - 6;
            if (
                (currPos < pos) &&
                ((currPos & 0x7) > (pos & 0x7)) &&
                (((uint8)(gameState >> (currPos * piece_bit_size)) & 0xf) == enemyKnight)
            ) return true;
        }

        return false;
    }

    /**
        @dev Checks if gameState has insufficient material
        @param gameState current game state
        @return isInsufficient returns true if insufficient material
    */
    function isStalemateViaInsufficientMaterial(uint256 gameState) public pure returns (bool) {
        uint8 whiteKingCount = 0;
        uint8 blackKingCount = 0;
        uint8 otherPiecesCount = 0;

        for (uint pos = 0; pos < 64; ) {
            uint8 piece = pieceAtPosition(gameState, uint8(pos));
            uint8 pieceType = piece & type_mask_const;
            bool isWhite = (piece & color_const) == 0;

            if (pieceType == king_const) {
                if (isWhite) {
                    whiteKingCount++;
                } else {
                    blackKingCount++;
                }
            } else if (pieceType != empty_const) {
                otherPiecesCount++;
                if (otherPiecesCount > 1 || (pieceType != knight_const && pieceType != bishop_const)) {
                    return false;
                }
            }
            unchecked {
                pos++;
            }
        }

        return whiteKingCount == 1 && blackKingCount == 1 && otherPiecesCount <= 1;
    }

    /**
        @dev Commits a move into the game state. Validity of the move is not checked.
        @param gameState current game state
        @param fromPos is the position to move a piece from.
        @param toPos is the position to move a piece to.
        @return newGameState
    */
    function commitMove(uint256 gameState, uint8 fromPos, uint8 toPos) public pure returns (uint) {
        uint8 bitpos = fromPos * piece_bit_size;
        uint8 piece = (uint8)((gameState >> bitpos) & 0xF);
        uint newGameState = gameState & ~(0xF << bitpos);

        newGameState = setPosition(newGameState, toPos, piece);

        return newGameState;
    }

    /**
        @dev Zeroes out a piece position in the current game state.
             Behavior is undefined for position values greater than 0x3f
        @param gameState current game state
        @param pos is the position to zero out: 6-bit var, 3-bit word, high word = row, low word = column.
        @return newGameState
    */
    function zeroPosition(uint256 gameState, uint8 pos) public pure returns (uint256) {
        return gameState & ~(0xF << (pos * piece_bit_size));
    }

    /**
        @dev Sets a piece position in the current game state.
             Behavior is undefined for position values greater than 0x3f
        @param gameState current game state
        @param pos is the position to set the piece: 6-bit var, 3-bit word, high word = row, low word = column.
        @param piece to set, including color
        @return newGameState
    */
    function setPosition(uint256 gameState, uint8 pos, uint8 piece) public pure returns (uint256 newGameState) {
        uint8 bitpos;

        unchecked {
            bitpos = pos * piece_bit_size;

            newGameState = (gameState & ~(0xF << bitpos)) | ((uint256)(piece) << bitpos);
        }

        return newGameState;
    }

    /**
        @dev Gets the piece at a given position in the current gameState.
             Behavior is undefined for position values greater than 0x3f
        @param gameState current game state
        @param pos is the position to get the piece: 6-bit var, 3-bit word, high word = row, low word = column.
        @return piece value including color
    */
    function pieceAtPosition(uint256 gameState, uint8 pos) public pure returns (uint8) {
        uint8 piece;

        unchecked {
            piece = (uint8)((gameState >> (pos * piece_bit_size)) & 0xF);
        }

        return piece;
    }
}