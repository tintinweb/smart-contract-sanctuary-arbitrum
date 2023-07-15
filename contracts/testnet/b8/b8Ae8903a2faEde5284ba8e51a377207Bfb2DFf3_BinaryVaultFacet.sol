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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IReentrancyGuard } from './IReentrancyGuard.sol';
import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard is IReentrancyGuard {
    uint256 internal constant REENTRANCY_STATUS_LOCKED = 2;
    uint256 internal constant REENTRANCY_STATUS_UNLOCKED = 1;

    modifier nonReentrant() {
        if (ReentrancyGuardStorage.layout().status == REENTRANCY_STATUS_LOCKED)
            revert ReentrancyGuard__ReentrantCall();
        _lockReentrancyGuard();
        _;
        _unlockReentrancyGuard();
    }

    /**
     * @notice lock functions that use the nonReentrant modifier
     */
    function _lockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_LOCKED;
    }

    /**
     * @notice unlock funtions that use the nonReentrant modifier
     */
    function _unlockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_UNLOCKED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Base } from './base/IERC721Base.sol';
import { IERC721Enumerable } from './enumerable/IERC721Enumerable.sol';
import { IERC721Metadata } from './metadata/IERC721Metadata.sol';

interface ISolidStateERC721 is IERC721Base, IERC721Enumerable, IERC721Metadata {
    error SolidStateERC721__PayableApproveNotSupported();
    error SolidStateERC721__PayableTransferNotSupported();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721 } from '../../../interfaces/IERC721.sol';
import { IERC721BaseInternal } from './IERC721BaseInternal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721Base is IERC721BaseInternal, IERC721 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Internal } from '../../../interfaces/IERC721Internal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721BaseInternal is IERC721Internal {
    error ERC721Base__NotOwnerOrApproved();
    error ERC721Base__SelfApproval();
    error ERC721Base__BalanceQueryZeroAddress();
    error ERC721Base__ERC721ReceiverNotImplemented();
    error ERC721Base__InvalidOwner();
    error ERC721Base__MintToZeroAddress();
    error ERC721Base__NonExistentToken();
    error ERC721Base__NotTokenOwner();
    error ERC721Base__TokenAlreadyMinted();
    error ERC721Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Enumerable {
    /**
     * @notice get total token supply
     * @return total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice get token of given owner at given internal storage index
     * @param owner token holder to query
     * @param index position in owner's token list to query
     * @return tokenId id of retrieved token
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    /**
     * @notice get token at given internal storage index
     * @param index position in global token list to query
     * @return tokenId id of retrieved token
     */
    function tokenByIndex(
        uint256 index
    ) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721MetadataInternal } from './IERC721MetadataInternal.sol';

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata is IERC721MetadataInternal {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721BaseInternal } from '../base/IERC721BaseInternal.sol';

/**
 * @title ERC721Metadata internal interface
 */
interface IERC721MetadataInternal is IERC721BaseInternal {
    error ERC721Metadata__NonExistentToken();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library BinaryVaultDataType {
    struct WithdrawalRequest {
        uint256 tokenId; // nft id
        uint256 shareAmount; // share amount
        uint256 underlyingTokenAmount; // underlying token amount
        uint256 timestamp; // request block time
        uint256 minExpectAmount; // Minimum underlying amount which user will receive
        uint256 fee;
    }

    struct BetData {
        uint256 bullAmount;
        uint256 bearAmount;
    }

    struct WhitelistedMarket {
        bool whitelisted;
        uint256 exposureBips; // % 10_000 based value. 100% => 10_000
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IBinaryVaultFacet, IBinaryVault} from "../../interfaces/binary/IBinaryVaultFacet.sol";
import {Strings} from "../../utils/StringUtils.sol";
import {IBinaryConfig} from "../../interfaces/binary/IBinaryConfig.sol";
import {IBinaryVaultNFTFacet} from "../../interfaces/binary/IBinaryVaultNFTFacet.sol";
import {IBinaryVaultPluginImpl} from "../../interfaces/binary/IBinaryVaultPluginImpl.sol";
import {BinaryVaultDataType} from "./BinaryVaultDataType.sol";

library BinaryVaultFacetStorage {
    struct Layout {
        IBinaryConfig config;
        address underlyingTokenAddress;
        /// @notice Whitelisted markets, only whitelisted markets can take money out from the vault.
        mapping(address => BinaryVaultDataType.WhitelistedMarket) whitelistedMarkets;
        /// @notice share balances (token id => share balance)
        mapping(uint256 => uint256) shareBalances;
        /// @notice initial investment (tokenId => initial underlying token balance)
        mapping(uint256 => uint256) initialInvestments;
        /// @notice latest balance (token id => underlying token)
        /// @dev This should be updated when user deposits/withdraw or when take monthly management fee
        mapping(uint256 => uint256) recentSnapshots;
        // For risk management
        mapping(uint256 => BinaryVaultDataType.BetData) betData;
        // token id => request
        mapping(uint256 => BinaryVaultDataType.WithdrawalRequest) withdrawalRequests;
        mapping(address => bool) whitelistedUser;
        uint256 totalShareSupply;
        /// @notice TVL of vault. This should be updated when deposit(+), withdraw(-), trader lose (+), trader win (-), trading fees(+)
        uint256 totalDepositedAmount;
        /// @notice Watermark for risk management. This should be updated when deposit(+), withdraw(-), trading fees(+). If watermark < TVL, then set watermark = tvl
        uint256 watermark;
        // @notice Current pending withdrawal share amount. Plus when new withdrawal request, minus when cancel or execute withdraw.
        uint256 pendingWithdrawalTokenAmount;
        uint256 pendingWithdrawalShareAmount;
        uint256 withdrawalDelayTime;
        bool pauseNewDeposit;
        bool useWhitelist;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("balancecapital.ryze.storage.BinaryVaultFacet");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

interface IVaultDiamond {
    function owner() external view returns (address);
}

contract BinaryVaultFacet is
    ReentrancyGuard,
    IBinaryVaultFacet,
    IBinaryVaultPluginImpl
{
    using SafeERC20 for IERC20;
    using Strings for uint256;
    using Strings for string;

    uint256 private constant MAX_DELAY = 1 weeks;

    event LiquidityAdded(
        address indexed user,
        uint256 oldTokenId,
        uint256 newTokenId,
        uint256 amount,
        uint256 newShareAmount
    );
    event PositionMerged(
        address indexed user,
        uint256[] tokenIds,
        uint256 newTokenId
    );
    event LiquidityRemoved(
        address indexed user,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount,
        uint256 shareAmount,
        uint256 newShares
    );
    event WithdrawalRequested(
        address indexed user,
        uint256 shareAmount,
        uint256 tokenId
    );
    event WithdrawalRequestCanceled(
        address indexed user,
        uint256 tokenId,
        uint256 shareAmount,
        uint256 underlyingTokenAmount
    );
    event VaultChangedFromMarket(
        uint256 prevTvl,
        uint256 totalDepositedAmount,
        uint256 watermark
    );
    event ManagementFeeWithdrawed();
    event ConfigChanged(address indexed config);
    event WhitelistMarketChanged(address indexed market, bool enabled);

    modifier onlyMarket() {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        require(s.whitelistedMarkets[msg.sender].whitelisted, "ONLY_MARKET");
        _;
    }

    modifier onlyOwner() {
        require(
            IVaultDiamond(address(this)).owner() == msg.sender,
            "Ownable: caller is not the owner"
        );
        _;
    }

    function initialize(address underlyingToken_, address config_)
        external
        onlyOwner
    {
        require(underlyingToken_ != address(0), "ZERO_ADDRESS");
        require(config_ != address(0), "ZERO_ADDRESS");
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        s.underlyingTokenAddress = underlyingToken_;
        s.config = IBinaryConfig(config_);
        s.withdrawalDelayTime = 24 hours;
    }

    /// @notice Whitelist market on the vault
    /// @dev Only owner can call this function
    /// @param market Market contract address
    /// @param whitelist Whitelist or Blacklist
    /// @param exposureBips Exposure percent based 10_000. So 100% is 10_000
    function setWhitelistMarket(
        address market,
        bool whitelist,
        uint256 exposureBips
    ) external virtual onlyOwner {
        require(market != address(0), "ZERO_ADDRESS");

        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        require(exposureBips <= s.config.FEE_BASE(), "INVALID_BIPS");

        s.whitelistedMarkets[market].whitelisted = whitelist;
        s.whitelistedMarkets[market].exposureBips = exposureBips;

        emit WhitelistMarketChanged(market, whitelist);
    }

    /// @notice Add liquidity. Burn existing token, mint new one.
    /// @param tokenId if isNew = false, nft id to be added liquidity..
    /// @param amount Underlying token amount
    /// @param isNew adding new liquidity or adding liquidity to existing position.
    function addLiquidity(
        uint256 tokenId,
        uint256 amount,
        bool isNew
    ) external virtual nonReentrant returns (uint256 newShares) {
        require(amount > 0, "ZERO_AMOUNT");
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        require(!s.pauseNewDeposit, "DEPOSIT_PAUSED");
        if (s.useWhitelist)
            require(s.whitelistedUser[msg.sender], "NOT_WHITELISTED");

        if (!isNew) {
            require(
                IBinaryVaultNFTFacet(address(this)).ownerOf(tokenId) ==
                    msg.sender,
                "NOT_OWNER"
            );

            BinaryVaultDataType.WithdrawalRequest memory withdrawalRequest = s
                .withdrawalRequests[tokenId];
            require(withdrawalRequest.timestamp == 0, "TOKEN_IN_ACTION");
        }

        // Transfer underlying token from user to the vault
        IERC20(s.underlyingTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        // Calculate new share amount base on current share price
        if (s.totalShareSupply > 0) {
            newShares = (amount * s.totalShareSupply) / s.totalDepositedAmount;
        } else {
            newShares = amount;
        }

        s.totalShareSupply += newShares;
        s.totalDepositedAmount += amount;
        s.watermark += amount;

        if (isNew) {
            tokenId = IBinaryVaultNFTFacet(address(this)).nextTokenId();
            // Mint new position with that amount
            s.shareBalances[tokenId] = newShares;
            s.initialInvestments[tokenId] = amount;
            s.recentSnapshots[tokenId] = amount;
            IBinaryVaultNFTFacet(address(this)).mint(msg.sender);

            emit LiquidityAdded(
                msg.sender,
                tokenId,
                tokenId,
                amount,
                newShares
            );
        } else {
            // Current share amount of this token ID;
            uint256 currentShares = s.shareBalances[tokenId];
            uint256 currentInitialInvestments = s.initialInvestments[tokenId];
            uint256 currentSnapshot = s.recentSnapshots[tokenId];
            // Burn existing one
            __burn(tokenId);
            // Mint New position.
            uint256 newTokenId = IBinaryVaultNFTFacet(address(this))
                .nextTokenId();

            s.shareBalances[newTokenId] = currentShares + newShares;
            s.initialInvestments[newTokenId] =
                currentInitialInvestments +
                amount;
            s.recentSnapshots[newTokenId] = currentSnapshot + amount;

            IBinaryVaultNFTFacet(address(this)).mint(msg.sender);

            emit LiquidityAdded(
                msg.sender,
                tokenId,
                newTokenId,
                amount,
                newShares
            );
        }
    }

    function __burn(uint256 tokenId) internal virtual {
        IBinaryVaultNFTFacet(address(this)).burn(tokenId);
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        delete s.shareBalances[tokenId];
        delete s.initialInvestments[tokenId];
        delete s.recentSnapshots[tokenId];
        if (s.withdrawalRequests[tokenId].timestamp > 0) {
            delete s.withdrawalRequests[tokenId];
        }
    }

    /// @notice Merge tokens into one, Burn existing ones and mint new one
    /// @param tokenIds Token ids which will be merged
    function mergePositions(uint256[] memory tokenIds)
        external
        virtual
        nonReentrant
    {
        uint256 shareAmounts = 0;
        uint256 initialInvests = 0;
        uint256 snapshots = 0;
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        uint256 withdrawalShareAmount;
        uint256 withdrawalTokenAmount;
        for (uint256 i; i < tokenIds.length; i = i + 1) {
            uint256 tokenId = tokenIds[i];
            require(
                IBinaryVaultNFTFacet(address(this)).ownerOf(tokenId) ==
                    msg.sender,
                "NOT_OWNER"
            );

            shareAmounts += s.shareBalances[tokenId];
            initialInvests += s.initialInvestments[tokenId];
            snapshots += s.recentSnapshots[tokenId];

            BinaryVaultDataType.WithdrawalRequest memory request = s
                .withdrawalRequests[tokenId];
            if (request.timestamp > 0) {
                withdrawalTokenAmount += request.underlyingTokenAmount;
                withdrawalShareAmount += request.shareAmount;
            }

            __burn(tokenId);
        }

        uint256 _newTokenId = IBinaryVaultNFTFacet(address(this)).nextTokenId();
        s.shareBalances[_newTokenId] = shareAmounts;
        s.initialInvestments[_newTokenId] = initialInvests;
        s.recentSnapshots[_newTokenId] = snapshots;

        if (withdrawalTokenAmount > 0) {
            s.pendingWithdrawalShareAmount -= withdrawalShareAmount;
            s.pendingWithdrawalTokenAmount -= withdrawalTokenAmount;
        }

        IBinaryVaultNFTFacet(address(this)).mint(msg.sender);

        emit PositionMerged(msg.sender, tokenIds, _newTokenId);
    }

    /// @notice Request withdrawal (This request will be delayed for withdrawalDelayTime)
    /// @param shareAmount share amount to be burnt
    /// @param tokenId This is available when fromPosition is true
    function requestWithdrawal(uint256 shareAmount, uint256 tokenId)
        external
        virtual
    {
        require(shareAmount > 0, "TOO_SMALL_AMOUNT");
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        require(
            IBinaryVaultNFTFacet(address(this)).ownerOf(tokenId) == msg.sender,
            "NOT_OWNER"
        );
        BinaryVaultDataType.WithdrawalRequest memory r = s.withdrawalRequests[
            tokenId
        ];

        require(r.timestamp == 0, "ALREADY_REQUESTED");

        // We decrease tvl once user requests withdrawal. so this liquidity won't be affected by user's betting.
        (
            uint256 shareBalance,
            uint256 tokenValue,
            ,
            uint256 fee
        ) = getSharesOfToken(tokenId);

        require(shareBalance >= shareAmount, "INSUFFICIENT_AMOUNT");

        uint256 underlyingTokenAmount = (tokenValue * shareAmount) /
            shareBalance;
        uint256 feeAmount = (fee * shareAmount) / shareBalance;

        // Get total pending risk
        uint256 pendingRisk = getPendingRiskFromBet();

        pendingRisk = (pendingRisk * shareAmount) / s.totalShareSupply;

        uint256 minExpectAmount = underlyingTokenAmount > pendingRisk
            ? underlyingTokenAmount - pendingRisk
            : 0;
        BinaryVaultDataType.WithdrawalRequest
            memory _request = BinaryVaultDataType.WithdrawalRequest(
                tokenId,
                shareAmount,
                underlyingTokenAmount,
                block.timestamp,
                minExpectAmount,
                feeAmount
            );

        s.withdrawalRequests[tokenId] = _request;

        s.pendingWithdrawalTokenAmount += underlyingTokenAmount;
        s.pendingWithdrawalShareAmount += shareAmount;

        emit WithdrawalRequested(msg.sender, shareAmount, tokenId);
    }

    /// @notice Execute withdrawal request if it passed enough time.
    /// @param tokenId withdrawal request id to be executed.
    function executeWithdrawalRequest(uint256 tokenId)
        external
        virtual
        nonReentrant
    {
        address user = msg.sender;

        require(
            user == IBinaryVaultNFTFacet(address(this)).ownerOf(tokenId),
            "NOT_REQUEST_OWNER"
        );
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        BinaryVaultDataType.WithdrawalRequest memory _request = s
            .withdrawalRequests[tokenId];
        // Check if time is passed enough
        require(
            block.timestamp >= _request.timestamp + s.withdrawalDelayTime,
            "TOO_EARLY"
        );

        uint256 shareAmount = _request.shareAmount;

        (
            uint256 shareBalance,
            ,
            uint256 netValue,
            uint256 fee
        ) = getSharesOfToken(tokenId);

        if (shareAmount > shareBalance) {
            shareAmount = shareBalance;
        }

        fee = (fee * shareAmount) / shareBalance;
        if (fee > 0) {
            // Send fee to treasury
            IERC20(s.underlyingTokenAddress).safeTransfer(
                s.config.treasury(),
                fee
            );
        }

        uint256 redeemAmount = (netValue * shareAmount) / shareBalance;
        // Send money to user
        IERC20(s.underlyingTokenAddress).safeTransfer(user, redeemAmount);

        // Mint dust
        uint256 initialInvest = s.initialInvestments[tokenId];

        uint256 newTokenId;
        if (shareAmount < shareBalance) {
            // Mint new one for dust
            newTokenId = IBinaryVaultNFTFacet(address(this)).nextTokenId();
            s.shareBalances[newTokenId] = shareBalance - shareAmount;
            s.initialInvestments[newTokenId] =
                ((shareBalance - shareAmount) * initialInvest) /
                shareBalance;

            s.recentSnapshots[newTokenId] =
                s.recentSnapshots[tokenId] -
                (shareAmount * s.recentSnapshots[tokenId]) /
                shareBalance;
            IBinaryVaultNFTFacet(address(this)).mint(user);
        }

        // deduct
        s.totalDepositedAmount -= (redeemAmount + fee);
        s.watermark -= (redeemAmount + fee);
        s.totalShareSupply -= shareAmount;

        s.pendingWithdrawalTokenAmount -= _request.underlyingTokenAmount;
        s.pendingWithdrawalShareAmount -= _request.shareAmount;

        delete s.withdrawalRequests[tokenId];
        __burn(tokenId);

        emit LiquidityRemoved(
            user,
            tokenId,
            newTokenId,
            redeemAmount,
            shareAmount,
            shareBalance - shareAmount
        );
    }

    /// @notice Cancel withdrawal request
    /// @param tokenId nft id
    function cancelWithdrawalRequest(uint256 tokenId) external virtual {
        require(
            msg.sender == IBinaryVaultNFTFacet(address(this)).ownerOf(tokenId),
            "NOT_REQUEST_OWNER"
        );
        _cancelWithdrawalRequest(tokenId);
    }

    function _cancelWithdrawalRequest(uint256 tokenId) internal {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        BinaryVaultDataType.WithdrawalRequest memory request = s
            .withdrawalRequests[tokenId];
        require(request.timestamp > 0, "NOT_EXIST_REQUEST");

        s.pendingWithdrawalTokenAmount -= request.underlyingTokenAmount;
        s.pendingWithdrawalShareAmount -= request.shareAmount;

        emit WithdrawalRequestCanceled(
            msg.sender,
            tokenId,
            request.shareAmount,
            request.underlyingTokenAmount
        );

        delete s.withdrawalRequests[tokenId];
    }

    /// @notice Check if future betting is available based on current pending withdrawal request amount
    /// @return future betting is available
    function isFutureBettingAvailable() external view returns (bool) {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        if (
            s.pendingWithdrawalTokenAmount >=
            (s.totalDepositedAmount *
                s.config.maxWithdrawalBipsForFutureBettingAvailable()) /
                s.config.FEE_BASE()
        ) {
            return false;
        } else {
            return true;
        }
    }

    /// @notice Claim winning rewards from the vault
    /// In this case, we charge fee from win traders.
    /// @dev Only markets can call this function
    /// @param user Address of winner
    /// @param amount Amount of rewards to claim
    /// @param isRefund whether its refund
    /// @return claim amount
    function claimBettingRewards(
        address user,
        uint256 amount,
        bool isRefund
    ) external virtual onlyMarket returns (uint256) {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        uint256 claimAmount = isRefund
            ? amount
            : ((2 * amount * (s.config.FEE_BASE() - s.config.tradingFee())) /
                s.config.FEE_BASE());
        IERC20(s.underlyingTokenAddress).safeTransfer(user, claimAmount);

        return claimAmount;
    }

    /// @notice Get shares of user.
    /// @param user address
    /// @return shares underlyingTokenAmount netValue fee their values
    function getSharesOfUser(address user)
        public
        view
        virtual
        returns (
            uint256 shares,
            uint256 underlyingTokenAmount,
            uint256 netValue,
            uint256 fee
        )
    {
        uint256[] memory tokenIds = IBinaryVaultNFTFacet(address(this))
            .tokensOfOwner(user);

        if (tokenIds.length == 0) {
            return (0, 0, 0, 0);
        }

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            (
                uint256 shareAmount,
                uint256 uTokenAmount,
                uint256 net,
                uint256 _fee
            ) = getSharesOfToken(tokenIds[i]);
            shares += shareAmount;
            underlyingTokenAmount += uTokenAmount;
            netValue += net;
            fee += _fee;
        }
    }

    /// @notice Get shares and underlying token amount of token
    /// @return shares tokenValue netValue fee - their values
    function getSharesOfToken(uint256 tokenId)
        public
        view
        virtual
        returns (
            uint256 shares,
            uint256 tokenValue,
            uint256 netValue,
            uint256 fee
        )
    {
        if (!IBinaryVaultNFTFacet(address(this)).exists(tokenId)) {
            return (0, 0, 0, 0);
        }
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        shares = s.shareBalances[tokenId];
        fee = 0;

        uint256 lastSnapshot = s.recentSnapshots[tokenId];

        uint256 totalShareSupply_ = s.totalShareSupply;
        uint256 totalDepositedAmount_ = s.totalDepositedAmount;

        tokenValue = (shares * totalDepositedAmount_) / totalShareSupply_;

        netValue = tokenValue;

        if (tokenValue > lastSnapshot) {
            // This token got profit. In this case, we should deduct fee (30%)
            fee =
                ((tokenValue - lastSnapshot) * s.config.treasuryBips()) /
                s.config.FEE_BASE();
            netValue = tokenValue - fee;
        }
    }

    /// @dev set config
    function setConfig(address _config) external virtual onlyOwner {
        require(_config != address(0), "ZERO_ADDRESS");
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        s.config = IBinaryConfig(_config);

        emit ConfigChanged(_config);
    }

    function enableUseWhitelist(bool value) external onlyOwner {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();
        require(s.useWhitelist != value, "ALREADY_SET");
        s.useWhitelist = value;
    }

    function enablePauseDeposit(bool value) external onlyOwner {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();
        require(s.pauseNewDeposit != value, "ALREADY_SET");
        s.pauseNewDeposit = value;
    }

    function setWhitelistUser(address user, bool value) external onlyOwner {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();
        require(s.whitelistedUser[user] != value, "ALREADY_SET");
        s.whitelistedUser[user] = value;
    }

    /// @dev This function is used to update total deposited amount from user betting
    /// @param wonAmount amount won from user perspective (lost from vault perspective)
    /// @param loseAmount amount lost from user perspective (won from vault perspective)
    function onRoundExecuted(uint256 wonAmount, uint256 loseAmount)
        external
        virtual
        override
        onlyMarket
    {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        uint256 tradingFeeBips = s.config.tradingFee();
        uint256 fee1 = (wonAmount * 2 * tradingFeeBips) / s.config.FEE_BASE();
        uint256 fee2 = (loseAmount * tradingFeeBips) / s.config.FEE_BASE();

        uint256 tradingFee = fee1 + fee2;

        uint256 prevTvl = s.totalDepositedAmount;

        if (loseAmount - fee2 > wonAmount) {
            s.totalDepositedAmount += (loseAmount - wonAmount) - fee2;
        } else if (loseAmount < wonAmount) {
            uint256 escapeAmount = wonAmount - loseAmount + fee2;
            s.totalDepositedAmount = s.totalDepositedAmount >= escapeAmount
                ? s.totalDepositedAmount - escapeAmount
                : 0;
        }

        // Update watermark
        if (s.totalDepositedAmount > s.watermark) {
            s.watermark = s.totalDepositedAmount;
        }

        if (tradingFee > 0) {
            IERC20(s.underlyingTokenAddress).safeTransfer(
                s.config.treasuryForReferrals(),
                tradingFee
            );
        }

        emit VaultChangedFromMarket(
            prevTvl,
            s.totalDepositedAmount,
            s.watermark
        );
    }

    /// @notice Set withdrawal delay time
    /// @param _time time in seconds
    function setWithdrawalDelayTime(uint256 _time) external virtual onlyOwner {
        require(_time <= MAX_DELAY, "INVALID_TIME");
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        s.withdrawalDelayTime = _time;
    }

    /// @return Get vault risk
    function getVaultRiskBips() internal view virtual returns (uint256) {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        if (s.watermark < s.totalDepositedAmount) {
            return 0;
        }

        return
            ((s.watermark - s.totalDepositedAmount) * s.config.FEE_BASE()) /
            s.totalDepositedAmount;
    }

    /// @return Get max hourly vault exposure based on current risk. if current risk is high, hourly vault exposure should be decreased.
    function getMaxHourlyExposure() external view virtual returns (uint256) {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        uint256 tvl = s.totalDepositedAmount - s.pendingWithdrawalTokenAmount;

        if (tvl == 0) {
            return 0;
        }

        uint256 currentRiskBips = getVaultRiskBips();
        uint256 _maxHourlyExposureBips = s.config.maxHourlyExposure();
        uint256 _maxVaultRiskBips = s.config.maxVaultRiskBips();

        if (currentRiskBips >= _maxVaultRiskBips) {
            // Risk is too high. Stop accepting bet
            return 0;
        }

        uint256 exposureBips = (_maxHourlyExposureBips *
            (_maxVaultRiskBips - currentRiskBips)) / _maxVaultRiskBips;

        return (exposureBips * tvl) / s.config.FEE_BASE();
    }

    function getShareBipsExpression(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        uint256 percent = (s.shareBalances[tokenId] * 10_000) /
            s.totalShareSupply;
        string memory percentString = percent.getFloatExpression();
        return string(abi.encodePacked(percentString, " %"));
    }

    function getInitialInvestExpression(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        uint256 _value = s.initialInvestments[tokenId];
        string memory floatExpression = ((_value * 10**2) /
            10**IERC20Metadata(s.underlyingTokenAddress).decimals())
            .getFloatExpression();
        return
            string(
                abi.encodePacked(
                    floatExpression,
                    " ",
                    IERC20Metadata(s.underlyingTokenAddress).symbol()
                )
            );
    }

    function getCurrentValueExpression(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        (, , uint256 netValue, ) = getSharesOfToken(tokenId);
        string memory floatExpression = ((netValue * 10**2) /
            10**IERC20Metadata(s.underlyingTokenAddress).decimals())
            .getFloatExpression();
        return
            string(
                abi.encodePacked(
                    floatExpression,
                    " ",
                    IERC20Metadata(s.underlyingTokenAddress).symbol()
                )
            );
    }

    function getWithdrawalExpression(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        BinaryVaultDataType.WithdrawalRequest memory withdrawalRequest = s
            .withdrawalRequests[tokenId];
        if (withdrawalRequest.timestamp == 0) {
            return "Active";
        } else if (
            withdrawalRequest.timestamp + s.withdrawalDelayTime <=
            block.timestamp
        ) {
            return "Executable";
        } else {
            return "Pending";
        }
    }

    function getImagePlainText(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        string memory template = s.config.binaryVaultImageTemplate();

        string memory result = template.replaceString(
            "<!--TOKEN_ID-->",
            tokenId.toString()
        );
        result = result.replaceString(
            "<!--SHARE_BIPS-->",
            getShareBipsExpression(tokenId)
        );
        result = result.replaceString(
            "<!--VAULT_NAME-->",
            IERC20Metadata(s.underlyingTokenAddress).symbol()
        );
        result = result.replaceString(
            "<!--VAULT_STATUS-->",
            getWithdrawalExpression(tokenId)
        );
        result = result.replaceString(
            "<!--DEPOSIT_AMOUNT-->",
            getInitialInvestExpression(tokenId)
        );
        result = result.replaceString(
            "<!--VAULT_LOGO_IMAGE-->",
            s.config.tokenLogo(s.underlyingTokenAddress)
        );
        result = result.replaceString(
            "<!--VAULT_VALUE-->",
            getCurrentValueExpression(tokenId)
        );

        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(result)))
        );

        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    /// @notice constructs manifest metadata in plaintext for base64 encoding
    /// @param _tokenId token id
    /// @return _manifest manifest for base64 encoding
    function getManifestPlainText(uint256 _tokenId)
        internal
        view
        virtual
        returns (string memory _manifest)
    {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        string memory image = getImagePlainText(_tokenId);

        _manifest = string(
            abi.encodePacked(
                '{"name": ',
                '"',
                IBinaryVaultNFTFacet(address(this)).name(),
                '", "description": "',
                s.config.vaultDescription(),
                '", "image": "',
                image,
                '"}'
            )
        );
    }

    function generateTokenURI(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory output = getManifestPlainText(tokenId);
        string memory json = Base64.encode(bytes(output));

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function cancelExpiredWithdrawalRequest(uint256 tokenId)
        external
        onlyOwner
    {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        BinaryVaultDataType.WithdrawalRequest memory request = s
            .withdrawalRequests[tokenId];
        require(
            block.timestamp > request.timestamp + s.withdrawalDelayTime * 2,
            "INVALID"
        );
        _cancelWithdrawalRequest(tokenId);
    }

    /// @notice Transfer underlying token from user to vault. Update vault state for risk management
    /// @param amount bet amount
    /// @param from originating user
    /// @param endTime round close time
    /// @param position bull if 0, bear if 1 for binary options
    function onPlaceBet(
        uint256 amount,
        address from,
        uint256 endTime,
        uint8 position
    ) external virtual onlyMarket {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        IERC20(s.underlyingTokenAddress).safeTransferFrom(
            from,
            address(this),
            amount
        );
        BinaryVaultDataType.BetData storage data = s.betData[endTime];

        if (position == 0) {
            data.bullAmount += amount;
        } else {
            data.bearAmount += amount;
        }
    }

    function getExposureAmountAt(uint256 endTime)
        public
        view
        virtual
        returns (uint256 exposureAmount, uint8 direction)
    {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        BinaryVaultDataType.BetData memory data = s.betData[endTime];

        if (data.bullAmount > data.bearAmount) {
            exposureAmount = data.bullAmount - data.bearAmount;
            direction = 0;
        } else {
            exposureAmount = data.bearAmount - data.bullAmount;
            direction = 1;
        }
    }

    function getPendingRiskFromBet() public view returns (uint256 riskAmount) {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        uint256 nextMinuteTimestamp = block.timestamp -
            (block.timestamp % 60) +
            60;
        uint256 futureBettingTimeUpTo = s.config.futureBettingTimeUpTo();

        for (
            uint256 i = nextMinuteTimestamp;
            i <= nextMinuteTimestamp + futureBettingTimeUpTo;
            i += 60
        ) {
            (uint256 exposureAmount, ) = getExposureAmountAt(i);
            riskAmount += exposureAmount;
        }
    }

    /// @notice This is function for withdraw management fee - Ryze Fee
    /// We run this function at certain day, for example 25th in every month.
    /// @dev We set from and to parameter so that we can avoid falling in gas limitation issue
    /// @param from tokenId where we will start to get management fee
    /// @param to tokenId where we will end to get management fee
    function withdrawManagementFee(uint256 from, uint256 to)
        external
        virtual
        onlyOwner
    {
        _withdrawManagementFee(from, to);
        emit ManagementFeeWithdrawed();
    }

    function _withdrawManagementFee(uint256 from, uint256 to) internal virtual {
        uint256 feeAmount;
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        for (uint256 tokenId = from; tokenId <= to; tokenId++) {
            (, , uint256 netValue, uint256 fee) = getSharesOfToken(tokenId);
            if (fee > 0) {
                feeAmount += fee;
                uint256 feeShare = (fee * s.totalShareSupply) /
                    s.totalDepositedAmount;
                if (s.shareBalances[tokenId] >= feeShare) {
                    s.shareBalances[tokenId] =
                        s.shareBalances[tokenId] -
                        feeShare;
                }
                // We will set recent snapshot so that we will prevent to charge duplicated fee.
                s.recentSnapshots[tokenId] = netValue;
            }
        }
        if (feeAmount > 0) {
            uint256 feeShare = (feeAmount * s.totalShareSupply) /
                s.totalDepositedAmount;

            IERC20(s.underlyingTokenAddress).safeTransfer(
                s.config.treasury(),
                feeAmount
            );
            s.totalDepositedAmount -= feeAmount;
            s.watermark -= feeAmount;
            s.totalShareSupply -= feeShare;

            uint256 sharePrice = (s.totalDepositedAmount * 10**18) /
                s.totalShareSupply;
            if (sharePrice > 10**18) {
                s.totalShareSupply = s.totalDepositedAmount;
                for (uint256 tokenId = from; tokenId <= to; tokenId++) {
                    s.shareBalances[tokenId] =
                        (s.shareBalances[tokenId] * sharePrice) /
                        10**18;
                }
            }
        }
    }

    function getManagementFee() external view returns (uint256 feeAmount) {
        uint256 to = IBinaryVaultNFTFacet(address(this)).nextTokenId();
        for (uint256 tokenId = 0; tokenId < to; tokenId++) {
            (, , , uint256 fee) = getSharesOfToken(tokenId);
            feeAmount += fee;
        }
    }

    // getter functions
    function config() external view returns (address) {
        return address(BinaryVaultFacetStorage.layout().config);
    }

    function underlyingTokenAddress() external view returns (address) {
        return BinaryVaultFacetStorage.layout().underlyingTokenAddress;
    }

    function whitelistMarkets(address market)
        external
        view
        returns (bool, uint256)
    {
        return (
            BinaryVaultFacetStorage
                .layout()
                .whitelistedMarkets[market]
                .whitelisted,
            BinaryVaultFacetStorage
                .layout()
                .whitelistedMarkets[market]
                .exposureBips
        );
    }

    function shareBalances(uint256 tokenId) external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().shareBalances[tokenId];
    }

    function initialInvestments(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return BinaryVaultFacetStorage.layout().initialInvestments[tokenId];
    }

    function recentSnapshots(uint256 tokenId) external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().recentSnapshots[tokenId];
    }

    function withdrawalRequests(uint256 tokenId)
        external
        view
        returns (BinaryVaultDataType.WithdrawalRequest memory)
    {
        return BinaryVaultFacetStorage.layout().withdrawalRequests[tokenId];
    }

    function totalShareSupply() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().totalShareSupply;
    }

    function totalDepositedAmount() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().totalDepositedAmount;
    }

    function watermark() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().watermark;
    }

    function pendingWithdrawalShareAmount() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().pendingWithdrawalShareAmount;
    }

    function pendingWithdrawalTokenAmount() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().pendingWithdrawalTokenAmount;
    }

    function withdrawalDelayTime() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().withdrawalDelayTime;
    }

    function isDepositPaused() external view returns (bool) {
        return BinaryVaultFacetStorage.layout().pauseNewDeposit;
    }

    function isWhitelistedUser(address user) external view returns (bool) {
        return BinaryVaultFacetStorage.layout().whitelistedUser[user];
    }

    function isUseWhitelist() external view returns (bool) {
        return BinaryVaultFacetStorage.layout().useWhitelist;
    }

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](40);
        s[0] = IBinaryVault.claimBettingRewards.selector;
        s[1] = IBinaryVault.onRoundExecuted.selector;
        s[2] = IBinaryVault.getMaxHourlyExposure.selector;
        s[3] = IBinaryVault.isFutureBettingAvailable.selector;
        s[4] = IBinaryVault.onPlaceBet.selector;
        s[5] = IBinaryVault.getExposureAmountAt.selector;
        s[6] = IBinaryVaultFacet.setWhitelistMarket.selector;
        s[7] = IBinaryVaultFacet.addLiquidity.selector;
        s[8] = IBinaryVaultFacet.mergePositions.selector;
        s[9] = IBinaryVaultFacet.requestWithdrawal.selector;
        s[10] = IBinaryVaultFacet.executeWithdrawalRequest.selector;
        s[11] = IBinaryVaultFacet.cancelWithdrawalRequest.selector;
        s[12] = IBinaryVaultFacet.getSharesOfUser.selector;
        s[13] = IBinaryVaultFacet.getSharesOfToken.selector;
        s[14] = IBinaryVaultFacet.setConfig.selector;
        s[15] = IBinaryVaultFacet.setWithdrawalDelayTime.selector;
        s[16] = IBinaryVaultFacet.cancelExpiredWithdrawalRequest.selector;
        s[17] = IBinaryVaultFacet.getPendingRiskFromBet.selector;
        s[18] = IBinaryVaultFacet.withdrawManagementFee.selector;
        s[19] = IBinaryVaultFacet.getManagementFee.selector;
        s[20] = IBinaryVaultFacet.generateTokenURI.selector;

        s[21] = IBinaryVaultFacet.config.selector;
        s[22] = IBinaryVaultFacet.underlyingTokenAddress.selector;
        s[23] = IBinaryVault.whitelistMarkets.selector;
        s[24] = IBinaryVaultFacet.shareBalances.selector;
        s[25] = IBinaryVaultFacet.initialInvestments.selector;
        s[26] = IBinaryVaultFacet.recentSnapshots.selector;
        s[27] = IBinaryVaultFacet.withdrawalRequests.selector;
        s[28] = IBinaryVaultFacet.totalShareSupply.selector;
        s[29] = IBinaryVaultFacet.totalDepositedAmount.selector;
        s[30] = IBinaryVaultFacet.watermark.selector;
        s[31] = IBinaryVaultFacet.pendingWithdrawalShareAmount.selector;
        s[32] = IBinaryVaultFacet.pendingWithdrawalTokenAmount.selector;
        s[33] = IBinaryVaultFacet.withdrawalDelayTime.selector;

        s[34] = IBinaryVaultFacet.isDepositPaused.selector;
        s[35] = IBinaryVaultFacet.isWhitelistedUser.selector;
        s[36] = IBinaryVaultFacet.isUseWhitelist.selector;
        s[37] = IBinaryVaultFacet.enableUseWhitelist.selector;
        s[38] = IBinaryVaultFacet.enablePauseDeposit.selector;
        s[39] = IBinaryVaultFacet.setWhitelistUser.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(IBinaryVaultFacet).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBinaryConfig {
    // solhint-disable-next-line
    function FEE_BASE() external view returns (uint256);

    function treasury() external view returns (address);

    function treasuryForReferrals() external view returns (address);

    function tradingFee() external view returns (uint256);

    function treasuryBips() external view returns (uint256);

    function maxVaultRiskBips() external view returns (uint256);

    function maxHourlyExposure() external view returns (uint256);

    function maxWithdrawalBipsForFutureBettingAvailable()
        external
        view
        returns (uint256);

    function binaryVaultImageTemplate() external view returns (string memory);

    function tokenLogo(address _token) external view returns (string memory);

    function vaultDescription() external view returns (string memory);

    function futureBettingTimeUpTo() external view returns (uint256);

    function bettingAmountBips() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBinaryVault {
    function claimBettingRewards(
        address to,
        uint256 amount,
        bool isRefund
    ) external returns (uint256);

    function onRoundExecuted(uint256 wonAmount, uint256 loseAmount) external;

    function getMaxHourlyExposure() external view returns (uint256);

    function isFutureBettingAvailable() external view returns (bool);

    function onPlaceBet(
        uint256 amount,
        address from,
        uint256 endTime,
        uint8 position
    ) external;

    function getExposureAmountAt(uint256 endTime)
        external
        view
        returns (uint256 exposureAmount, uint8 direction);

    function whitelistMarkets(address) external view returns (bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IBinaryVault.sol";
import {BinaryVaultDataType} from "../../binary/vault/BinaryVaultDataType.sol";

interface IBinaryVaultFacet is IBinaryVault {
    function setWhitelistMarket(
        address market,
        bool whitelist,
        uint256 exposureBips
    ) external;

    function addLiquidity(
        uint256 tokenId,
        uint256 amount,
        bool isNew
    ) external returns (uint256);

    function mergePositions(uint256[] memory tokenIds) external;

    function requestWithdrawal(uint256 shareAmount, uint256 tokenId) external;

    function executeWithdrawalRequest(uint256 tokenId) external;

    function cancelWithdrawalRequest(uint256 tokenId) external;

    function getSharesOfUser(address user)
        external
        view
        returns (
            uint256 shares,
            uint256 underlyingTokenAmount,
            uint256 netValue,
            uint256 fee
        );

    function getSharesOfToken(uint256 tokenId)
        external
        view
        returns (
            uint256 shares,
            uint256 tokenValue,
            uint256 netValue,
            uint256 fee
        );

    function setConfig(address _config) external;

    function setWithdrawalDelayTime(uint256 _time) external;

    function cancelExpiredWithdrawalRequest(uint256 tokenId) external;

    function getPendingRiskFromBet() external view returns (uint256 riskAmount);

    function withdrawManagementFee(uint256 from, uint256 to) external;

    function getManagementFee() external view returns (uint256 feeAmount);

    function generateTokenURI(uint256 tokenId)
        external
        view
        returns (string memory);

    function config() external view returns (address);

    function underlyingTokenAddress() external view returns (address);

    function shareBalances(uint256) external view returns (uint256);

    function initialInvestments(uint256) external view returns (uint256);

    function recentSnapshots(uint256) external view returns (uint256);

    function withdrawalRequests(uint256)
        external
        view
        returns (BinaryVaultDataType.WithdrawalRequest memory);

    function totalShareSupply() external view returns (uint256);

    function totalDepositedAmount() external view returns (uint256);

    function watermark() external view returns (uint256);

    function pendingWithdrawalTokenAmount() external view returns (uint256);

    function pendingWithdrawalShareAmount() external view returns (uint256);

    function withdrawalDelayTime() external view returns (uint256);

    function isDepositPaused() external view returns (bool);

    function isWhitelistedUser(address user) external view returns (bool);

    function isUseWhitelist() external view returns (bool);

    function enableUseWhitelist(bool value) external;

    function enablePauseDeposit(bool value) external;

    function setWhitelistUser(address user, bool value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {ISolidStateERC721} from "@solidstate/contracts/token/ERC721/ISolidStateERC721.sol";

interface IBinaryVaultNFTFacet is ISolidStateERC721 {
    function nextTokenId() external view returns (uint256);

    function mint(address owner) external;

    function exists(uint256 tokenId) external view returns (bool);

    function burn(uint256 tokenId) external;

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBinaryVaultPluginImpl {
    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

    /// @dev Copy cat from https://gist.github.com/Vectorized/56ac210117f9baa15ac74a9ae779cd1f
    function replaceString(
        string memory subject,
        string memory search,
        string memory replacement
    ) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)
            let replacementLength := mload(replacement)

            // Store the mask for sub-word comparisons in the scratch space.
            mstore(0x00, not(0))
            mstore(0x20, 0)

            subject := add(subject, 0x20)
            search := add(search, 0x20)
            replacement := add(replacement, 0x20)
            result := add(mload(0x40), 0x20)

            let k := 0

            let subjectEnd := add(subject, subjectLength)
            if iszero(gt(searchLength, subjectLength)) {
                let subjectSearchEnd := add(sub(subjectEnd, searchLength), 1)
                for {

                } lt(subject, subjectSearchEnd) {

                } {
                    let o := and(searchLength, 31)
                    // Whether the first `searchLength % 32` bytes of
                    // `subject` and `search` matches.
                    let l := iszero(
                        and(
                            xor(mload(subject), mload(search)),
                            mload(sub(0x20, o))
                        )
                    )
                    // Iterate through the rest of `search` and check if any word mismatch.
                    // If any mismatch is detected, `l` is set to 0.
                    for {

                    } and(lt(o, searchLength), l) {

                    } {
                        l := eq(mload(add(subject, o)), mload(add(search, o)))
                        o := add(o, 0x20)
                    }
                    // If `l` is one, there is a match, and we have to copy the `replacement`.
                    if l {
                        // Copy the `replacement` one word at a time.
                        for {
                            o := 0
                        } lt(o, replacementLength) {
                            o := add(o, 0x20)
                        } {
                            mstore(
                                add(result, add(k, o)),
                                mload(add(replacement, o))
                            )
                        }
                        k := add(k, replacementLength)
                        subject := add(subject, searchLength)
                    }
                    // If `l` or `searchLength` is zero.
                    if iszero(mul(l, searchLength)) {
                        mstore(add(result, k), mload(subject))
                        k := add(k, 1)
                        subject := add(subject, 1)
                    }
                }
            }

            let resultRemainder := add(result, k)
            k := add(k, sub(subjectEnd, subject))
            // Copy the rest of the string one word at a time.
            for {

            } lt(subject, subjectEnd) {

            } {
                mstore(resultRemainder, mload(subject))
                resultRemainder := add(resultRemainder, 0x20)
                subject := add(subject, 0x20)
            }
            // Allocate memory for the length and the bytes, rounded up to a multiple of 32.
            mstore(0x40, add(result, and(add(k, 64), not(31))))
            result := sub(result, 0x20)
            mstore(result, k)
        }
    }

    /// @notice Generate string expression with floating number - 123 => 1.23%. Base number is 10_000
    /// @param percent percent with 2 decimals
    /// @return string representation
    function getFloatExpression(uint256 percent)
        internal
        pure
        returns (string memory)
    {
        string memory percentString = toString(percent / 100);
        uint256 decimal = percent % 100;
        if (decimal > 0) {
            percentString = string(
                abi.encodePacked(
                    percentString,
                    ".",
                    toString(decimal / 10),
                    toString(decimal % 10)
                )
            );
        }
        return percentString;
    }
}