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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../utils/Accessibility.sol";
import "../../utils/Pausable.sol";
import "./IAccountEvents.sol";
import "./AccountFacetImpl.sol";
import "../../storages/GlobalAppStorage.sol";

contract AccountFacet is Accessibility, Pausable, IAccountEvents {
    
    //Party A
    function deposit(uint256 amount) external whenNotAccountingPaused {
        AccountFacetImpl.deposit(msg.sender, amount);
        emit Deposit(msg.sender, msg.sender, amount);
    }

    function depositFor(address user, uint256 amount) external whenNotAccountingPaused {
        AccountFacetImpl.deposit(user, amount);
        emit Deposit(msg.sender, user, amount);
    }

    function withdraw(uint256 amount) external whenNotAccountingPaused notSuspended(msg.sender) {
        AccountFacetImpl.withdraw(msg.sender, amount);
        emit Withdraw(msg.sender, msg.sender, amount);
    }

    function withdrawTo(
        address user,
        uint256 amount
    ) external whenNotAccountingPaused notSuspended(msg.sender) {
        AccountFacetImpl.withdraw(user, amount);
        emit Withdraw(msg.sender, user, amount);
    }

    function allocate(
        uint256 amount
    ) external whenNotAccountingPaused notLiquidatedPartyA(msg.sender) {
        AccountFacetImpl.allocate(amount);
        emit AllocatePartyA(msg.sender, amount);
    }

    function depositAndAllocate(
        uint256 amount
    ) external whenNotAccountingPaused notLiquidatedPartyA(msg.sender) {
        AccountFacetImpl.deposit(msg.sender, amount);
        uint256 amountWith18Decimals = (amount * 1e18) /
            (10 ** IERC20Metadata(GlobalAppStorage.layout().collateral).decimals());
        AccountFacetImpl.allocate(amountWith18Decimals);
        emit Deposit(msg.sender, msg.sender, amount);
        emit AllocatePartyA(msg.sender, amountWith18Decimals);
    }

    function deallocate(
        uint256 amount,
        SingleUpnlSig memory upnlSig
    ) external whenNotAccountingPaused notLiquidatedPartyA(msg.sender) {
        AccountFacetImpl.deallocate(amount, upnlSig);
        emit DeallocatePartyA(msg.sender, amount);
    }

    // PartyB
    function allocateForPartyB(
        uint256 amount,
        address partyA
    ) public whenNotPartyBActionsPaused notLiquidatedPartyB(msg.sender, partyA) onlyPartyB {
        AccountFacetImpl.allocateForPartyB(amount, partyA);
        emit AllocateForPartyB(msg.sender, partyA, amount);
    }

    function deallocateForPartyB(
        uint256 amount,
        address partyA,
        SingleUpnlSig memory upnlSig
    ) external whenNotPartyBActionsPaused notLiquidatedPartyB(msg.sender, partyA) notLiquidatedPartyA(partyA) onlyPartyB {
        AccountFacetImpl.deallocateForPartyB(amount, partyA, upnlSig);
        emit DeallocateForPartyB(msg.sender, partyA, amount);
    }

    function transferAllocation(
        uint256 amount,
        address origin,
        address recipient,
        SingleUpnlSig memory upnlSig
    ) external whenNotPartyBActionsPaused {
        AccountFacetImpl.transferAllocation(amount, origin, recipient, upnlSig);
        emit TransferAllocation(amount, origin, recipient);
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../storages/AccountStorage.sol";
import "../../storages/GlobalAppStorage.sol";
import "../../storages/MAStorage.sol";
import "../../storages/MuonStorage.sol";
import "../../libraries/LibMuon.sol";
import "../../libraries/LibAccount.sol";

library AccountFacetImpl {
    using SafeERC20 for IERC20;

    function deposit(address user, uint256 amount) internal {
        GlobalAppStorage.Layout storage appLayout = GlobalAppStorage.layout();
        IERC20(appLayout.collateral).safeTransferFrom(msg.sender, address(this), amount);
        uint256 amountWith18Decimals = (amount * 1e18) /
        (10 ** IERC20Metadata(appLayout.collateral).decimals());
        AccountStorage.layout().balances[user] += amountWith18Decimals;
    }

    function withdraw(address user, uint256 amount) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        GlobalAppStorage.Layout storage appLayout = GlobalAppStorage.layout();
        require(
            block.timestamp >=
            accountLayout.withdrawCooldown[msg.sender] + MAStorage.layout().deallocateCooldown,
            "AccountFacet: Cooldown hasn't reached"
        );
        uint256 amountWith18Decimals = (amount * 1e18) /
        (10 ** IERC20Metadata(appLayout.collateral).decimals());
        accountLayout.balances[msg.sender] -= amountWith18Decimals;
        IERC20(appLayout.collateral).safeTransfer(user, amount);
    }

    function allocate(uint256 amount) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        require(
            accountLayout.allocatedBalances[msg.sender] + amount <=
            GlobalAppStorage.layout().balanceLimitPerUser,
            "AccountFacet: Allocated balance limit reached"
        );
        require(accountLayout.balances[msg.sender] >= amount, "AccountFacet: Insufficient balance");
        accountLayout.balances[msg.sender] -= amount;
        accountLayout.allocatedBalances[msg.sender] += amount;
    }

    function deallocate(uint256 amount, SingleUpnlSig memory upnlSig) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        require(
            accountLayout.allocatedBalances[msg.sender] >= amount,
            "AccountFacet: Insufficient allocated Balance"
        );
        LibMuon.verifyPartyAUpnl(upnlSig, msg.sender);
        int256 availableBalance = LibAccount.partyAAvailableForQuote(upnlSig.upnl, msg.sender);
        require(availableBalance >= 0, "AccountFacet: Available balance is lower than zero");
        require(uint256(availableBalance) >= amount, "AccountFacet: partyA will be liquidatable");

        accountLayout.partyANonces[msg.sender] += 1;
        accountLayout.allocatedBalances[msg.sender] -= amount;
        accountLayout.balances[msg.sender] += amount;
        accountLayout.withdrawCooldown[msg.sender] = block.timestamp;
    }

    function transferAllocation(
        uint256 amount,
        address origin,
        address recipient,
        SingleUpnlSig memory upnlSig
    ) internal {
        MAStorage.Layout storage maLayout = MAStorage.layout();
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        require(
            !maLayout.partyBLiquidationStatus[msg.sender][origin],
            "PartyBFacet: PartyB isn't solvent"
        );
        require(
            !maLayout.partyBLiquidationStatus[msg.sender][recipient],
            "PartyBFacet: PartyB isn't solvent"
        );
        require(
            !MAStorage.layout().liquidationStatus[origin],
            "PartyBFacet: Origin isn't solvent"
        );
        require(
            !MAStorage.layout().liquidationStatus[recipient],
            "PartyBFacet: Recipient isn't solvent"
        );
        // deallocate from origin
        require(
            accountLayout.partyBAllocatedBalances[msg.sender][origin] >= amount,
            "PartyBFacet: Insufficient locked balance"
        );
        LibMuon.verifyPartyBUpnl(upnlSig, msg.sender, origin);
        int256 availableBalance = LibAccount.partyBAvailableForQuote(
            upnlSig.upnl,
            msg.sender,
            origin
        );
        require(availableBalance >= 0, "PartyBFacet: Available balance is lower than zero");
        require(uint256(availableBalance) >= amount, "PartyBFacet: Will be liquidatable");

        accountLayout.partyBNonces[msg.sender][origin] += 1;
        accountLayout.partyBAllocatedBalances[msg.sender][origin] -= amount;
        // allocate for recipient
        accountLayout.partyBAllocatedBalances[msg.sender][recipient] += amount;
    }

    function allocateForPartyB(uint256 amount, address partyA) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();

        require(accountLayout.balances[msg.sender] >= amount, "PartyBFacet: Insufficient balance");
        require(
            !MAStorage.layout().partyBLiquidationStatus[msg.sender][partyA],
            "PartyBFacet: PartyB isn't solvent"
        );
        accountLayout.balances[msg.sender] -= amount;
        accountLayout.partyBAllocatedBalances[msg.sender][partyA] += amount;
    }

    function deallocateForPartyB(
        uint256 amount,
        address partyA,
        SingleUpnlSig memory upnlSig
    ) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        require(
            accountLayout.partyBAllocatedBalances[msg.sender][partyA] >= amount,
            "PartyBFacet: Insufficient allocated balance"
        );
        LibMuon.verifyPartyBUpnl(upnlSig, msg.sender, partyA);
        int256 availableBalance = LibAccount.partyBAvailableForQuote(
            upnlSig.upnl,
            msg.sender,
            partyA
        );
        require(availableBalance >= 0, "PartyBFacet: Available balance is lower than zero");
        require(uint256(availableBalance) >= amount, "PartyBFacet: Will be liquidatable");

        accountLayout.partyBNonces[msg.sender][partyA] += 1;
        accountLayout.partyBAllocatedBalances[msg.sender][partyA] -= amount;
        accountLayout.balances[msg.sender] += amount;
        accountLayout.withdrawCooldown[msg.sender] = block.timestamp;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

interface IAccountEvents {
    event Deposit(address sender, address user, uint256 amount);
    event Withdraw(address sender, address user, uint256 amount);
    event AllocatePartyA(address user, uint256 amount);
    event DeallocatePartyA(address user, uint256 amount);

    event AllocateForPartyB(address partyB, address partyA, uint256 amount);
    event DeallocateForPartyB(address partyB, address partyA, uint256 amount);
    event TransferAllocation(uint256 amount, address origin, address recipient);
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/GlobalAppStorage.sol";

library LibAccessibility {
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant MUON_SETTER_ROLE = keccak256("MUON_SETTER_ROLE");
    bytes32 public constant SYMBOL_MANAGER_ROLE = keccak256("SYMBOL_MANAGER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 public constant PARTY_B_MANAGER_ROLE = keccak256("PARTY_B_MANAGER_ROLE");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    bytes32 public constant SUSPENDER_ROLE = keccak256("SUSPENDER_ROLE");
    bytes32 public constant DISPUTE_ROLE = keccak256("DISPUTE_ROLE");

    function hasRole(address user, bytes32 role) internal view returns (bool) {
        GlobalAppStorage.Layout storage layout = GlobalAppStorage.layout();
        return layout.hasRole[user][role];
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "./LibLockedValues.sol";
import "../storages/AccountStorage.sol";

library LibAccount {
    using LockedValuesOps for LockedValues;

    function partyATotalLockedBalances(address partyA) internal view returns (uint256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        return
            accountLayout.pendingLockedBalances[partyA].totalForPartyA() +
            accountLayout.lockedBalances[partyA].totalForPartyA();
    }

    function partyBTotalLockedBalances(
        address partyB,
        address partyA
    ) internal view returns (uint256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        return
            accountLayout.partyBPendingLockedBalances[partyB][partyA].totalForPartyB() +
            accountLayout.partyBLockedBalances[partyB][partyA].totalForPartyB();
    }

    function partyAAvailableForQuote(int256 upnl, address partyA) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 available;
        if (upnl >= 0) {
            available =
                int256(accountLayout.allocatedBalances[partyA]) +
                upnl -
                int256(
                    (accountLayout.lockedBalances[partyA].totalForPartyA() +
                        accountLayout.pendingLockedBalances[partyA].totalForPartyA())
                );
        } else {
            int256 mm = int256(accountLayout.lockedBalances[partyA].partyAmm);
            int256 considering_mm = -upnl > mm ? -upnl : mm;
            available =
                int256(accountLayout.allocatedBalances[partyA]) -
                int256(
                    (accountLayout.lockedBalances[partyA].cva +
                        accountLayout.lockedBalances[partyA].lf +
                        accountLayout.pendingLockedBalances[partyA].totalForPartyA())
                ) -
                considering_mm;
        }
        return available;
    }

    function partyAAvailableBalance(int256 upnl, address partyA) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 available;
        if (upnl >= 0) {
            available =
                int256(accountLayout.allocatedBalances[partyA]) +
                upnl -
                int256(accountLayout.lockedBalances[partyA].totalForPartyA());
        } else {
            int256 mm = int256(accountLayout.lockedBalances[partyA].partyAmm);
            int256 considering_mm = -upnl > mm ? -upnl : mm;
            available =
                int256(accountLayout.allocatedBalances[partyA]) -
                int256(
                    accountLayout.lockedBalances[partyA].cva +
                        accountLayout.lockedBalances[partyA].lf
                ) -
                considering_mm;
        }
        return available;
    }

    function partyAAvailableBalanceForLiquidation(
        int256 upnl,
        address partyA
    ) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 freeBalance = int256(accountLayout.allocatedBalances[partyA]) -
            int256(accountLayout.lockedBalances[partyA].cva + accountLayout.lockedBalances[partyA].lf);
        return freeBalance + upnl;
    }

    function partyBAvailableForQuote(
        int256 upnl,
        address partyB,
        address partyA
    ) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 available;
        if (upnl >= 0) {
            available =
                int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) +
                upnl -
                int256(
                    (accountLayout.partyBLockedBalances[partyB][partyA].totalForPartyB() +
                        accountLayout.partyBPendingLockedBalances[partyB][partyA].totalForPartyB())
                );
        } else {
            int256 mm = int256(accountLayout.partyBLockedBalances[partyB][partyA].partyBmm);
            int256 considering_mm = -upnl > mm ? -upnl : mm;
            available =
                int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) -
                int256(
                    (accountLayout.partyBLockedBalances[partyB][partyA].cva +
                        accountLayout.partyBLockedBalances[partyB][partyA].lf +
                        accountLayout.partyBPendingLockedBalances[partyB][partyA].totalForPartyB())
                ) -
                considering_mm;
        }
        return available;
    }

    function partyBAvailableBalance(
        int256 upnl,
        address partyB,
        address partyA
    ) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 available;
        if (upnl >= 0) {
            available =
                int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) +
                upnl -
                int256(accountLayout.partyBLockedBalances[partyB][partyA].totalForPartyB());
        } else {
            int256 mm = int256(accountLayout.partyBLockedBalances[partyB][partyA].partyBmm);
            int256 considering_mm = -upnl > mm ? -upnl : mm;
            available =
                int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) -
                int256(
                    accountLayout.partyBLockedBalances[partyB][partyA].cva +
                        accountLayout.partyBLockedBalances[partyB][partyA].lf
                ) -
                considering_mm;
        }
        return available;
    }

    function partyBAvailableBalanceForLiquidation(
        int256 upnl,
        address partyB,
        address partyA
    ) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 a = int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) -
            int256(accountLayout.partyBLockedBalances[partyB][partyA].cva +
                accountLayout.partyBLockedBalances[partyB][partyA].lf);
        return a + upnl;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../storages/QuoteStorage.sol";

struct LockedValues {
    uint256 cva;
    uint256 lf;
    uint256 partyAmm;
    uint256 partyBmm;
}

library LockedValuesOps {
    using SafeMath for uint256;

    function add(LockedValues storage self, LockedValues memory a)
        internal
        returns (LockedValues storage)
    {
        self.cva = self.cva.add(a.cva);
        self.partyAmm = self.partyAmm.add(a.partyAmm);
        self.partyBmm = self.partyBmm.add(a.partyBmm);
        self.lf = self.lf.add(a.lf);
        return self;
    }

    function addQuote(LockedValues storage self, Quote storage quote)
        internal
        returns (LockedValues storage)
    {
        return add(self, quote.lockedValues);
    }

    function sub(LockedValues storage self, LockedValues memory a)
        internal
        returns (LockedValues storage)
    {
        self.cva = self.cva.sub(a.cva);
        self.partyAmm = self.partyAmm.sub(a.partyAmm);
        self.partyBmm = self.partyBmm.sub(a.partyBmm);
        self.lf = self.lf.sub(a.lf);
        return self;
    }

    function subQuote(LockedValues storage self, Quote storage quote)
        internal
        returns (LockedValues storage)
    {
        return sub(self, quote.lockedValues);
    }

    function makeZero(LockedValues storage self) internal returns (LockedValues storage) {
        self.cva = 0;
        self.partyAmm = 0;
        self.partyBmm = 0;
        self.lf = 0;
        return self;
    }

    function totalForPartyA(LockedValues memory self) internal pure returns (uint256) {
        return self.cva + self.partyAmm + self.lf;
    }

    function totalForPartyB(LockedValues memory self) internal pure returns (uint256) {
        return self.cva + self.partyBmm + self.lf;
    }

    function mul(LockedValues storage self, uint256 a) internal returns (LockedValues storage) {
        self.cva = self.cva.mul(a);
        self.partyAmm = self.partyAmm.mul(a);
        self.partyBmm = self.partyBmm.mul(a);
        self.lf = self.lf.mul(a);
        return self;
    }

    function mulMem(LockedValues memory self, uint256 a)
        internal
        pure
        returns (LockedValues memory)
    {
        LockedValues memory lockedValues = LockedValues(
            self.cva.mul(a),
            self.lf.mul(a),
            self.partyAmm.mul(a),
            self.partyBmm.mul(a)
        );
        return lockedValues;
    }

    function div(LockedValues storage self, uint256 a) internal returns (LockedValues storage) {
        self.cva = self.cva.div(a);
        self.partyAmm = self.partyAmm.div(a);
        self.partyBmm = self.partyBmm.div(a);
        self.lf = self.lf.div(a);
        return self;
    }

    function divMem(LockedValues memory self, uint256 a)
        internal
        pure
        returns (LockedValues memory)
    {
        LockedValues memory lockedValues = LockedValues(
            self.cva.div(a),
            self.lf.div(a),
            self.partyAmm.div(a),
            self.partyBmm.div(a)
        );
        return lockedValues;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../libraries/LibMuonV04ClientBase.sol";
import "../storages/MuonStorage.sol";
import "../storages/AccountStorage.sol";

library LibMuon {
    using ECDSA for bytes32;

    function getChainId() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    // CONTEXT for commented out lines
    // We're utilizing muon signatures for asset pricing and user uPNLs calculations. 
    // Even though these signatures are necessary for full testing of the system, particularly when invoking various methods.
    // The process of creating automated functional signature for tests has proven to be either impractical or excessively time-consuming. therefore, we've established commenting out the necessary code as a workaround specifically for testing.
    // Essentially, during testing, we temporarily disable the code sections responsible for validating these signatures. The sections I'm referring to are located within the LibMuon file. Specifically, the body of the 'verifyTSSAndGateway' method is a prime candidate for temporary disablement. In addition, several 'require' statements within other functions of this file, which examine the signatures' expiration status, also need to be temporarily disabled.
    // However, it is crucial to note that these lines should not be disabled in the production deployed version. 
    // We emphasize this because they are only disabled for testing purposes.

    function verifyTSSAndGateway(
        bytes32 hash,
        SchnorrSign memory sign,
        bytes memory gatewaySignature
    ) internal view {
        // == SignatureCheck( ==
        bool verified = LibMuonV04ClientBase.muonVerify(
            uint256(hash),
            sign,
            MuonStorage.layout().muonPublicKey
        );
        require(verified, "LibMuon: TSS not verified");

        hash = hash.toEthSignedMessageHash();
        address gatewaySignatureSigner = hash.recover(gatewaySignature);

        require(
            gatewaySignatureSigner == MuonStorage.layout().validGateway,
            "LibMuon: Gateway is not valid"
        );
        // == ) ==
    }

    function verifyLiquidationSig(LiquidationSig memory liquidationSig, address partyA) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        require(liquidationSig.prices.length == liquidationSig.symbolIds.length, "LibMuon: Invalid length");
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                liquidationSig.reqId,
                liquidationSig.liquidationId,
                address(this),
                "verifyLiquidationSig",
                partyA,
                AccountStorage.layout().partyANonces[partyA],
                liquidationSig.upnl,
                liquidationSig.totalUnrealizedLoss,
                liquidationSig.symbolIds,
                liquidationSig.prices,
                liquidationSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, liquidationSig.sigs, liquidationSig.gatewaySignature);
    }

    function verifyQuotePrices(QuotePriceSig memory priceSig) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        require(priceSig.prices.length == priceSig.quoteIds.length, "LibMuon: Invalid length");
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                priceSig.reqId,
                address(this),
                priceSig.quoteIds,
                priceSig.prices,
                priceSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, priceSig.sigs, priceSig.gatewaySignature);
    }

    function verifyPartyAUpnl(SingleUpnlSig memory upnlSig, address partyA) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyA,
                AccountStorage.layout().partyANonces[partyA],
                upnlSig.upnl,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }

    function verifyPartyAUpnlAndPrice(
        SingleUpnlAndPriceSig memory upnlSig,
        address partyA,
        uint256 symbolId
    ) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyA,
                AccountStorage.layout().partyANonces[partyA],
                upnlSig.upnl,
                symbolId,
                upnlSig.price,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }

    function verifyPartyBUpnl(
        SingleUpnlSig memory upnlSig,
        address partyB,
        address partyA
    ) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyB,
                partyA,
                AccountStorage.layout().partyBNonces[partyB][partyA],
                upnlSig.upnl,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }

    function verifyPairUpnlAndPrice(
        PairUpnlAndPriceSig memory upnlSig,
        address partyB,
        address partyA,
        uint256 symbolId
    ) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyB,
                partyA,
                AccountStorage.layout().partyBNonces[partyB][partyA],
                AccountStorage.layout().partyANonces[partyA],
                upnlSig.upnlPartyB,
                upnlSig.upnlPartyA,
                symbolId,
                upnlSig.price,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }

    function verifyPairUpnl(
        PairUpnlSig memory upnlSig,
        address partyB,
        address partyA
    ) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyB,
                partyA,
                AccountStorage.layout().partyBNonces[partyB][partyA],
                AccountStorage.layout().partyANonces[partyA],
                upnlSig.upnlPartyB,
                upnlSig.upnlPartyA,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "../storages/MuonStorage.sol";

library LibMuonV04ClientBase {
    // See https://en.bitcoin.it/wiki/Secp256k1 for this constant.
    uint256 constant public Q = // Group order of secp256k1
    // solium-disable-next-line indentation
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    // solium-disable-next-line zeppelin/no-arithmetic-operations
    uint256 constant public HALF_Q = (Q >> 1) + 1;

    /** **************************************************************************
@notice verifySignature returns true iff passed a valid Schnorr signature.

      @dev See https://en.wikipedia.org/wiki/Schnorr_signature for reference.

      @dev In what follows, let d be your secret key, PK be your public key,
      PKx be the x ordinate of your public key, and PKyp be the parity bit for
      the y ordinate (i.e., 0 if PKy is even, 1 if odd.)
      **************************************************************************
      @dev TO CREATE A VALID SIGNATURE FOR THIS METHOD

      @dev First PKx must be less than HALF_Q. Then follow these instructions
           (see evm/test/schnorr_test.js, for an example of carrying them out):
      @dev 1. Hash the target message to a uint256, called msgHash here, using
              keccak256

      @dev 2. Pick k uniformly and cryptographically securely randomly from
              {0,...,Q-1}. It is critical that k remains confidential, as your
              private key can be reconstructed from k and the signature.

      @dev 3. Compute k*g in the secp256k1 group, where g is the group
              generator. (This is the same as computing the public key from the
              secret key k. But it's OK if k*g's x ordinate is greater than
              HALF_Q.)

      @dev 4. Compute the ethereum address for k*g. This is the lower 160 bits
              of the keccak hash of the concatenated affine coordinates of k*g,
              as 32-byte big-endians. (For instance, you could pass k to
              ethereumjs-utils's privateToAddress to compute this, though that
              should be strictly a development convenience, not for handling
              live secrets, unless you've locked your javascript environment
              down very carefully.) Call this address
              nonceTimesGeneratorAddress.

      @dev 5. Compute e=uint256(keccak256(PKx as a 32-byte big-endian
                                        ‖ PKyp as a single byte
                                        ‖ msgHash
                                        ‖ nonceTimesGeneratorAddress))
              This value e is called "msgChallenge" in verifySignature's source
              code below. Here "‖" means concatenation of the listed byte
              arrays.

      @dev 6. Let x be your secret key. Compute s = (k - d * e) % Q. Add Q to
              it, if it's negative. This is your signature. (d is your secret
              key.)
      **************************************************************************
      @dev TO VERIFY A SIGNATURE

      @dev Given a signature (s, e) of msgHash, constructed as above, compute
      S=e*PK+s*generator in the secp256k1 group law, and then the ethereum
      address of S, as described in step 4. Call that
      nonceTimesGeneratorAddress. Then call the verifySignature method as:

      @dev    verifySignature(PKx, PKyp, s, msgHash,
                              nonceTimesGeneratorAddress)
      **************************************************************************
      @dev This signging scheme deviates slightly from the classical Schnorr
      signature, in that the address of k*g is used in place of k*g itself,
      both when calculating e and when verifying sum S as described in the
      verification paragraph above. This reduces the difficulty of
      brute-forcing a signature by trying random secp256k1 points in place of
      k*g in the signature verification process from 256 bits to 160 bits.
      However, the difficulty of cracking the public key using "baby-step,
      giant-step" is only 128 bits, so this weakening constitutes no compromise
      in the security of the signatures or the key.

      @dev The constraint signingPubKeyX < HALF_Q comes from Eq. (281), p. 24
      of Yellow Paper version 78d7b9a. ecrecover only accepts "s" inputs less
      than HALF_Q, to protect against a signature- malleability vulnerability in
      ECDSA. Schnorr does not have this vulnerability, but we must account for
      ecrecover's defense anyway. And since we are abusing ecrecover by putting
      signingPubKeyX in ecrecover's "s" argument the constraint applies to
      signingPubKeyX, even though it represents a value in the base field, and
      has no natural relationship to the order of the curve's cyclic group.
      **************************************************************************
      @param signingPubKeyX is the x ordinate of the public key. This must be
             less than HALF_Q.
      @param pubKeyYParity is 0 if the y ordinate of the public key is even, 1
             if it's odd.
      @param signature is the actual signature, described as s in the above
             instructions.
      @param msgHash is a 256-bit hash of the message being signed.
      @param nonceTimesGeneratorAddress is the ethereum address of k*g in the
             above instructions
      **************************************************************************
      @return True if passed a valid signature, false otherwise. */
    function verifySignature(
        uint256 signingPubKeyX,
        uint8 pubKeyYParity,
        uint256 signature,
        uint256 msgHash,
        address nonceTimesGeneratorAddress) public pure returns (bool) {
        require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
        // Avoid signature malleability from multiple representations for ℤ/Qℤ elts
        require(signature < Q, "signature must be reduced modulo Q");

        // Forbid trivial inputs, to avoid ecrecover edge cases. The main thing to
        // avoid is something which causes ecrecover to return 0x0: then trivial
        // signatures could be constructed with the nonceTimesGeneratorAddress input
        // set to 0x0.
        //
        // solium-disable-next-line indentation
        require(nonceTimesGeneratorAddress != address(0) && signingPubKeyX > 0 &&
        signature > 0 && msgHash > 0, "no zero inputs allowed");

        // solium-disable-next-line indentation
        uint256 msgChallenge = // "e"
        // solium-disable-next-line indentation
                            uint256(keccak256(abi.encodePacked(signingPubKeyX, pubKeyYParity,
                msgHash, nonceTimesGeneratorAddress))
            );

        // Verify msgChallenge * signingPubKey + signature * generator ==
        //        nonce * generator
        //
        // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
        // The point corresponding to the address returned by
        // ecrecover(-s*r,v,r,e*r) is (r⁻¹ mod Q)*(e*r*R-(-s)*r*g)=e*R+s*g, where R
        // is the (v,r) point. See https://crypto.stackexchange.com/a/18106
        //
        // solium-disable-next-line indentation
        address recoveredAddress = ecrecover(
        // solium-disable-next-line zeppelin/no-arithmetic-operations
            bytes32(Q - mulmod(signingPubKeyX, signature, Q)),
            // https://ethereum.github.io/yellowpaper/paper.pdf p. 24, "The
            // value 27 represents an even y value and 28 represents an odd
            // y value."
            (pubKeyYParity == 0) ? 27 : 28,
            bytes32(signingPubKeyX),
            bytes32(mulmod(msgChallenge, signingPubKeyX, Q)));
        return nonceTimesGeneratorAddress == recoveredAddress;
    }

    function validatePubKey(uint256 signingPubKeyX) public pure {
        require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
    }

    function muonVerify(
        uint256 hash,
        SchnorrSign memory signature,
        PublicKey memory pubKey
    ) internal pure returns (bool) {
        if (!verifySignature(pubKey.x, pubKey.parity,
            signature.signature,
            hash, signature.nonce)) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

enum LiquidationType {
    NONE,
    NORMAL,
    LATE,
    OVERDUE
}

struct SettlementState {
    int256 actualAmount; 
    int256 expectedAmount; 
    uint256 cva;
    bool pending;
}

struct LiquidationDetail {
    bytes liquidationId;
    LiquidationType liquidationType;
    int256 upnl;
    int256 totalUnrealizedLoss;
    uint256 deficit;
    uint256 liquidationFee;
    uint256 timestamp;
    uint256 involvedPartyBCounts;
    int256 partyAAccumulatedUpnl;
    bool disputed;
}

struct Price {
    uint256 price;
    uint256 timestamp;
}

library AccountStorage {
    bytes32 internal constant ACCOUNT_STORAGE_SLOT = keccak256("diamond.standard.storage.account");

    struct Layout {
        // Users deposited amounts
        mapping(address => uint256) balances;
        mapping(address => uint256) allocatedBalances;
        // position value will become pending locked before openPosition and will be locked after that
        mapping(address => LockedValues) pendingLockedBalances;
        mapping(address => LockedValues) lockedBalances;
        mapping(address => mapping(address => uint256)) partyBAllocatedBalances;
        mapping(address => mapping(address => LockedValues)) partyBPendingLockedBalances;
        mapping(address => mapping(address => LockedValues)) partyBLockedBalances;
        mapping(address => uint256) withdrawCooldown;
        mapping(address => uint256) partyANonces;
        mapping(address => mapping(address => uint256)) partyBNonces;
        mapping(address => bool) suspendedAddresses;
        mapping(address => LiquidationDetail) liquidationDetails;
        mapping(address => mapping(uint256 => Price)) symbolsPrices;
        mapping(address => address[]) liquidators;
        mapping(address => uint256) partyAReimbursement;
        // partyA => partyB => SettlementState
        mapping(address => mapping(address => SettlementState)) settlementStates;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = ACCOUNT_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

library GlobalAppStorage {
    bytes32 internal constant GLOBAL_APP_STORAGE_SLOT =
        keccak256("diamond.standard.storage.global");

    struct Layout {
        address collateral;
        address feeCollector;
        bool globalPaused;
        bool liquidationPaused;
        bool accountingPaused;
        bool partyBActionsPaused;
        bool partyAActionsPaused;
        bool emergencyMode;
        uint256 balanceLimitPerUser;
        mapping(address => bool) partyBEmergencyStatus;
        mapping(address => mapping(bytes32 => bool)) hasRole;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = GLOBAL_APP_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

library MAStorage {
    bytes32 internal constant MA_STORAGE_SLOT =
        keccak256("diamond.standard.storage.masteragreement");

    struct Layout {
        uint256 deallocateCooldown;
        uint256 forceCancelCooldown;
        uint256 forceCancelCloseCooldown;
        uint256 forceCloseCooldown;
        uint256 liquidationTimeout;
        uint256 liquidatorShare; // in 18 decimals
        uint256 pendingQuotesValidLength;
        uint256 forceCloseGapRatio;
        mapping(address => bool) partyBStatus;
        mapping(address => bool) liquidationStatus;
        mapping(address => mapping(address => bool)) partyBLiquidationStatus;
        mapping(address => mapping(address => uint256)) partyBLiquidationTimestamp;
        mapping(address => mapping(address => uint256)) partyBPositionLiquidatorsShare;
        address[] partyBList;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = MA_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

struct PublicKey {
    uint256 x;
    uint8 parity;
}

struct SingleUpnlSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnl;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct SingleUpnlAndPriceSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnl;
    uint256 price;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct PairUpnlSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnlPartyA;
    int256 upnlPartyB;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct PairUpnlAndPriceSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnlPartyA;
    int256 upnlPartyB;
    uint256 price;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct LiquidationSig {
    bytes reqId;
    uint256 timestamp;
    bytes liquidationId;
    int256 upnl;
    int256 totalUnrealizedLoss; 
    uint256[] symbolIds;
    uint256[] prices;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct QuotePriceSig {
    bytes reqId;
    uint256 timestamp;
    uint256[] quoteIds;
    uint256[] prices;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

library MuonStorage {
    bytes32 internal constant MUON_STORAGE_SLOT = keccak256("diamond.standard.storage.muon");

    struct Layout {
        uint256 upnlValidTime;
        uint256 priceValidTime;
        uint256 priceQuantityValidTime;
        uint256 muonAppId;
        PublicKey muonPublicKey;
        address validGateway;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = MUON_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

enum PositionType {
    LONG,
    SHORT
}

enum OrderType {
    LIMIT,
    MARKET
}

enum QuoteStatus {
    PENDING, //0
    LOCKED, //1
    CANCEL_PENDING, //2
    CANCELED, //3
    OPENED, //4
    CLOSE_PENDING, //5
    CANCEL_CLOSE_PENDING, //6
    CLOSED, //7
    LIQUIDATED, //8
    EXPIRED //9
}

struct Quote {
    uint256 id;
    address[] partyBsWhiteList;
    uint256 symbolId;
    PositionType positionType;
    OrderType orderType;
    // Price of quote which PartyB opened in 18 decimals
    uint256 openedPrice;
    uint256 initialOpenedPrice;
    // Price of quote which PartyA requested in 18 decimals
    uint256 requestedOpenPrice;
    uint256 marketPrice;
    // Quantity of quote which PartyA requested in 18 decimals
    uint256 quantity;
    // Quantity of quote which PartyB has closed until now in 18 decimals
    uint256 closedAmount;
    LockedValues initialLockedValues;
    LockedValues lockedValues;
    uint256 maxFundingRate;
    address partyA;
    address partyB;
    QuoteStatus quoteStatus;
    uint256 avgClosedPrice;
    uint256 requestedClosePrice;
    uint256 quantityToClose;
    // handle partially open position
    uint256 parentId;
    uint256 createTimestamp;
    uint256 statusModifyTimestamp;
    uint256 lastFundingPaymentTimestamp;
    uint256 deadline;
    uint256 tradingFee;
}

library QuoteStorage {
    bytes32 internal constant QUOTE_STORAGE_SLOT = keccak256("diamond.standard.storage.quote");

    struct Layout {
        mapping(address => uint256[]) quoteIdsOf;
        mapping(uint256 => Quote) quotes;
        mapping(address => uint256) partyAPositionsCount;
        mapping(address => mapping(address => uint256)) partyBPositionsCount;
        mapping(address => uint256[]) partyAPendingQuotes;
        mapping(address => mapping(address => uint256[])) partyBPendingQuotes;
        mapping(address => uint256[]) partyAOpenPositions;
        mapping(uint256 => uint256) partyAPositionsIndex;
        mapping(address => mapping(address => uint256[])) partyBOpenPositions;
        mapping(uint256 => uint256) partyBPositionsIndex;
        uint256 lastId;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = QUOTE_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/MAStorage.sol";
import "../storages/AccountStorage.sol";
import "../storages/QuoteStorage.sol";
import "../libraries/LibAccessibility.sol";

abstract contract Accessibility {
    modifier onlyPartyB() {
        require(MAStorage.layout().partyBStatus[msg.sender], "Accessibility: Should be partyB");
        _;
    }

    modifier notPartyB() {
        require(!MAStorage.layout().partyBStatus[msg.sender], "Accessibility: Shouldn't be partyB");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(LibAccessibility.hasRole(msg.sender, role), "Accessibility: Must has role");
        _;
    }

    modifier notLiquidatedPartyA(address partyA) {
        require(
            !MAStorage.layout().liquidationStatus[partyA],
            "Accessibility: PartyA isn't solvent"
        );
        _;
    }

    modifier notLiquidatedPartyB(address partyB, address partyA) {
        require(
            !MAStorage.layout().partyBLiquidationStatus[partyB][partyA],
            "Accessibility: PartyB isn't solvent"
        );
        _;
    }

    modifier notLiquidated(uint256 quoteId) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(
            !MAStorage.layout().liquidationStatus[quote.partyA],
            "Accessibility: PartyA isn't solvent"
        );
        require(
            !MAStorage.layout().partyBLiquidationStatus[quote.partyB][quote.partyA],
            "Accessibility: PartyB isn't solvent"
        );
        require(
            quote.quoteStatus != QuoteStatus.LIQUIDATED && quote.quoteStatus != QuoteStatus.CLOSED,
            "Accessibility: Invalid state"
        );
        _;
    }

    modifier onlyPartyAOfQuote(uint256 quoteId) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(quote.partyA == msg.sender, "Accessibility: Should be partyA of quote");
        _;
    }

    modifier onlyPartyBOfQuote(uint256 quoteId) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(quote.partyB == msg.sender, "Accessibility: Should be partyB of quote");
        _;
    }

    modifier notSuspended(address user) {
        require(
            !AccountStorage.layout().suspendedAddresses[user],
            "Accessibility: Sender is Suspended"
        );
        _;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/GlobalAppStorage.sol";

abstract contract Pausable {
    modifier whenNotGlobalPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        _;
    }

    modifier whenNotLiquidationPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        require(!GlobalAppStorage.layout().liquidationPaused, "Pausable: Liquidation paused");
        _;
    }

    modifier whenNotAccountingPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        require(!GlobalAppStorage.layout().accountingPaused, "Pausable: Accounting paused");
        _;
    }

    modifier whenNotPartyAActionsPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        require(!GlobalAppStorage.layout().partyAActionsPaused, "Pausable: PartyA actions paused");
        _;
    }

    modifier whenNotPartyBActionsPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        require(!GlobalAppStorage.layout().partyBActionsPaused, "Pausable: PartyB actions paused");
        _;
    }

    modifier whenEmergencyMode(address partyB) {
        require(
            GlobalAppStorage.layout().emergencyMode ||
                GlobalAppStorage.layout().partyBEmergencyStatus[partyB],
            "Pausable: It isn't emergency mode"
        );
        _;
    }
}