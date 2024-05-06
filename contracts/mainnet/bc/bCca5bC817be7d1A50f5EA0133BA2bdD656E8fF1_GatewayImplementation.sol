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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../vault/IVault.sol';
import '../token/IDToken.sol';
import '../token/IIOU.sol';
import '../../oracle/IOracle.sol';
import '../swapper/ISwapper.sol';
import './IGateway.sol';
import '../liqclaim/ILiqClaim.sol';
import '../../library/Bytes32Map.sol';
import '../../library/ETHAndERC20.sol';
import '../../library/SafeMath.sol';
import { GatewayIndex as I } from './GatewayIndex.sol';

library GatewayHelper {

    using Bytes32Map for mapping(uint8 => bytes32);
    using ETHAndERC20 for address;
    using SafeMath for uint256;
    using SafeMath for int256;

    error CannotDelBToken();
    error BTokenDupInitialize();
    error BTokenNoSwapper();
    error BTokenNoOracle();
    error InvalidBToken();

    event AddBToken(address bToken, address vault, bytes32 oracleId, uint256 collateralFactor);

    event DelBToken(address bToken);

    event UpdateBToken(address bToken);

    event SetExecutionFee(uint256 actionId, uint256 executionFee);

    event FinishCollectProtocolFee(
        uint256 amount
    );

    address constant tokenETH = address(1);

    //================================================================================
    // Getters
    //================================================================================

    function getGatewayState(mapping(uint8 => bytes32) storage gatewayStates)
    external view returns (IGateway.GatewayState memory s)
    {
        s.cumulativePnlOnGateway = gatewayStates.getInt(I.S_CUMULATIVEPNLONGATEWAY);
        s.liquidityTime = gatewayStates.getUint(I.S_LIQUIDITYTIME);
        s.totalLiquidity = gatewayStates.getUint(I.S_TOTALLIQUIDITY);
        s.cumulativeTimePerLiquidity = gatewayStates.getInt(I.S_CUMULATIVETIMEPERLIQUIDITY);
        s.gatewayRequestId = gatewayStates.getUint(I.S_GATEWAYREQUESTID);
        s.dChainExecutionFeePerRequest = gatewayStates.getUint(I.S_DCHAINEXECUTIONFEEPERREQUEST);
        s.totalIChainExecutionFee = gatewayStates.getUint(I.S_TOTALICHAINEXECUTIONFEE);
        s.cumulativeCollectedProtocolFee = gatewayStates.getUint(I.S_CUMULATIVECOLLECTEDPROTOCOLFEE);
    }

    function getBTokenState(
        mapping(address => mapping(uint8 => bytes32)) storage bTokenStates,
        address bToken
    ) external view returns (IGateway.BTokenState memory s)
    {
        s.vault = bTokenStates[bToken].getAddress(I.B_VAULT);
        s.oracleId = bTokenStates[bToken].getBytes32(I.B_ORACLEID);
        s.collateralFactor = bTokenStates[bToken].getUint(I.B_COLLATERALFACTOR);
    }

    function getLpState(
        mapping(address => mapping(uint8 => bytes32)) storage bTokenStates,
        mapping(uint256 => mapping(uint8 => bytes32)) storage dTokenStates,
        uint256 lTokenId
    ) external view returns (IGateway.LpState memory s)
    {
        s.requestId = dTokenStates[lTokenId].getUint(I.D_REQUESTID);
        s.bToken = dTokenStates[lTokenId].getAddress(I.D_BTOKEN);
        s.bAmount = IVault(bTokenStates[s.bToken].getAddress(I.B_VAULT)).getBalance(lTokenId);
        s.b0Amount = dTokenStates[lTokenId].getInt(I.D_B0AMOUNT);
        s.lastCumulativePnlOnEngine = dTokenStates[lTokenId].getInt(I.D_LASTCUMULATIVEPNLONENGINE);
        s.liquidity = dTokenStates[lTokenId].getUint(I.D_LIQUIDITY);
        s.cumulativeTime = dTokenStates[lTokenId].getUint(I.D_CUMULATIVETIME);
        s.lastCumulativeTimePerLiquidity = dTokenStates[lTokenId].getUint(I.D_LASTCUMULATIVETIMEPERLIQUIDITY);
        s.lastRequestIChainExecutionFee = dTokenStates[lTokenId].getUint(I.D_LASTREQUESTICHAINEXECUTIONFEE);
        s.cumulativeUnusedIChainExecutionFee = dTokenStates[lTokenId].getUint(I.D_CUMULATIVEUNUSEDICHAINEXECUTIONFEE);
    }

    function getTdState(
        mapping(address => mapping(uint8 => bytes32)) storage bTokenStates,
        mapping(uint256 => mapping(uint8 => bytes32)) storage dTokenStates,
        uint256 pTokenId
    ) external view returns (IGateway.TdState memory s)
    {
        s.requestId = dTokenStates[pTokenId].getUint(I.D_REQUESTID);
        s.bToken = dTokenStates[pTokenId].getAddress(I.D_BTOKEN);
        s.bAmount = IVault(bTokenStates[s.bToken].getAddress(I.B_VAULT)).getBalance(pTokenId);
        s.b0Amount = dTokenStates[pTokenId].getInt(I.D_B0AMOUNT);
        s.lastCumulativePnlOnEngine = dTokenStates[pTokenId].getInt(I.D_LASTCUMULATIVEPNLONENGINE);
        s.singlePosition = dTokenStates[pTokenId].getBool(I.D_SINGLEPOSITION);
        s.lastRequestIChainExecutionFee = dTokenStates[pTokenId].getUint(I.D_LASTREQUESTICHAINEXECUTIONFEE);
        s.cumulativeUnusedIChainExecutionFee = dTokenStates[pTokenId].getUint(I.D_CUMULATIVEUNUSEDICHAINEXECUTIONFEE);
    }

    function getExecutionFees(mapping(uint256 => uint256) storage executionFees)
    external view returns (uint256[] memory fees)
    {
        fees = new uint256[](5);
        fees[0] = executionFees[I.ACTION_REQUESTADDLIQUIDITY];
        fees[1] = executionFees[I.ACTION_REQUESTREMOVELIQUIDITY];
        fees[2] = executionFees[I.ACTION_REQUESTREMOVEMARGIN];
        fees[3] = executionFees[I.ACTION_REQUESTTRADE];
        fees[4] = executionFees[I.ACTION_REQUESTTRADEANDREMOVEMARGIN];
    }

    //================================================================================
    // Setters
    //================================================================================

    function addBToken(
        mapping(address => mapping(uint8 => bytes32)) storage bTokenStates,
        ISwapper swapper,
        IOracle oracle,
        IVault vault0,
        address tokenB0,
        address bToken,
        address vault,
        bytes32 oracleId,
        uint256 collateralFactor
    ) external
    {
        if (bTokenStates[bToken].getAddress(I.B_VAULT) != address(0)) {
            revert BTokenDupInitialize();
        }
        if (IVault(vault).asset() != bToken) {
            revert InvalidBToken();
        }
        if (bToken != tokenETH) {
            if (!swapper.isSupportedToken(bToken)) {
                revert BTokenNoSwapper();
            }
            // Approve for swapper and vault
            bToken.approveMax(address(swapper));
            bToken.approveMax(vault);
            if (bToken == tokenB0) {
                // The reserved portion for B0 will be deposited to vault0
                bToken.approveMax(address(vault0));
            }
        }
        // Check bToken oracle except B0
        if (bToken != tokenB0 && oracle.getValue(oracleId) == 0) {
            revert BTokenNoOracle();
        }
        bTokenStates[bToken].set(I.B_VAULT, vault);
        bTokenStates[bToken].set(I.B_ORACLEID, oracleId);
        bTokenStates[bToken].set(I.B_COLLATERALFACTOR, collateralFactor);

        emit AddBToken(bToken, vault, oracleId, collateralFactor);
    }

    function delBToken(
        mapping(address => mapping(uint8 => bytes32)) storage bTokenStates,
        address bToken
    ) external
    {
        // bToken can only be deleted when there is no deposits
        if (IVault(bTokenStates[bToken].getAddress(I.B_VAULT)).stTotalAmount() != 0) {
            revert CannotDelBToken();
        }

        bTokenStates[bToken].del(I.B_VAULT);
        bTokenStates[bToken].del(I.B_ORACLEID);
        bTokenStates[bToken].del(I.B_COLLATERALFACTOR);

        emit DelBToken(bToken);
    }

    // @dev This function can be used to change bToken collateral factor
    function setBTokenParameter(
        mapping(address => mapping(uint8 => bytes32)) storage bTokenStates,
        address bToken,
        uint8 idx,
        bytes32 value
    ) external
    {
        bTokenStates[bToken].set(idx, value);
        emit UpdateBToken(bToken);
    }

    // @notice Set execution fee for actionId
    function setExecutionFee(
        mapping(uint256 => uint256) storage executionFees,
        uint256 actionId,
        uint256 executionFee
    ) external
    {
        executionFees[actionId] = executionFee;
        emit SetExecutionFee(actionId, executionFee);
    }

    function setDChainExecutionFeePerRequest(
        mapping(uint8 => bytes32) storage gatewayStates,
        uint256 dChainExecutionFeePerRequest
    ) external
    {
        gatewayStates.set(I.S_DCHAINEXECUTIONFEEPERREQUEST, dChainExecutionFeePerRequest);
    }

    // @notic Claim dChain executionFee to account `to`
    function claimDChainExecutionFee(
        mapping(uint8 => bytes32) storage gatewayStates,
        address to
    ) external
    {
        tokenETH.transferOut(to, tokenETH.balanceOfThis() - gatewayStates.getUint(I.S_TOTALICHAINEXECUTIONFEE));
    }

    // @notice Claim unused iChain execution fee for dTokenId
    function claimUnusedIChainExecutionFee(
        mapping(uint8 => bytes32) storage gatewayStates,
        mapping(uint256 => mapping(uint8 => bytes32)) storage dTokenStates,
        IDToken lToken,
        IDToken pToken,
        uint256 dTokenId,
        bool isLp
    ) external
    {
        address owner = isLp ? lToken.ownerOf(dTokenId) : pToken.ownerOf(dTokenId);
        uint256 cumulativeUnusedIChainExecutionFee = dTokenStates[dTokenId].getUint(I.D_CUMULATIVEUNUSEDICHAINEXECUTIONFEE);
        if (cumulativeUnusedIChainExecutionFee > 0) {
            uint256 totalIChainExecutionFee = gatewayStates.getUint(I.S_TOTALICHAINEXECUTIONFEE);
            totalIChainExecutionFee -= cumulativeUnusedIChainExecutionFee;
            gatewayStates.set(I.S_TOTALICHAINEXECUTIONFEE, totalIChainExecutionFee);

            dTokenStates[dTokenId].del(I.D_CUMULATIVEUNUSEDICHAINEXECUTIONFEE);

            tokenETH.transferOut(owner, cumulativeUnusedIChainExecutionFee);
        }
    }

    // @notice Redeem B0 for burning IOU
    function redeemIOU(
        address tokenB0,
        IVault vault0,
        IIOU iou,
        address to,
        uint256 b0Amount
    ) external {
        if (b0Amount > 0) {
            uint256 b0Redeemed = vault0.redeem(uint256(0), b0Amount);
            if (b0Redeemed > 0) {
                iou.burn(to, b0Redeemed);
                tokenB0.transferOut(to, b0Redeemed);
            }
        }
    }


    //================================================================================
    // Interactions
    //================================================================================

    function finishCollectProtocolFee(
        mapping(uint8 => bytes32) storage gatewayStates,
        IVault vault0,
        address tokenB0,
        address protocolFeeManager,
        uint256 cumulativeCollectedProtocolFeeOnEngine
    ) external {
        uint8 decimalsB0 = tokenB0.decimals();
        uint256 cumulativeCollectedProtocolFeeOnGateway = gatewayStates.getUint(I.S_CUMULATIVECOLLECTEDPROTOCOLFEE);
        if (cumulativeCollectedProtocolFeeOnEngine > cumulativeCollectedProtocolFeeOnGateway) {
            uint256 amount = (cumulativeCollectedProtocolFeeOnEngine - cumulativeCollectedProtocolFeeOnGateway).rescaleDown(18, decimalsB0);
            if (amount > 0) {
                amount = vault0.redeem(uint256(0), amount);
                tokenB0.transferOut(protocolFeeManager, amount);
                cumulativeCollectedProtocolFeeOnGateway += amount.rescale(decimalsB0, 18);
                gatewayStates.set(I.S_CUMULATIVECOLLECTEDPROTOCOLFEE, cumulativeCollectedProtocolFeeOnGateway);
                emit FinishCollectProtocolFee(
                    amount
                );
            }
        }
    }

    function liquidateRedeemAndSwap(
        uint8 decimalsB0,
        address bToken,
        address swapper,
        address liqClaim,
        address pToken,
        uint256 pTokenId,
        int256 b0Amount,
        uint256 bAmount,
        int256 maintenanceMarginRequired
    ) external returns (uint256) {
        uint256 b0AmountIn;

        // only swap needed B0 to cover maintenanceMarginRequired
        int256 requiredB0Amount = maintenanceMarginRequired.rescaleUp(18, decimalsB0) - b0Amount;
        if (requiredB0Amount > 0) {
            if (bToken == tokenETH) {
                (uint256 resultB0, uint256 resultBX) = ISwapper(swapper).swapETHForExactB0{value:bAmount}(requiredB0Amount.itou());
                b0AmountIn += resultB0;
                bAmount -= resultBX;
            } else {
                (uint256 resultB0, uint256 resultBX) = ISwapper(swapper).swapBXForExactB0(bToken, requiredB0Amount.itou(), bAmount);
                b0AmountIn += resultB0;
                bAmount -= resultBX;
            }
        }
        if (bAmount > 0) {
            bToken.transferOut(liqClaim, bAmount);
            ILiqClaim(liqClaim).registerDeposit(IDToken(pToken).ownerOf(pTokenId), bToken, bAmount);
        }

        return b0AmountIn;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../vault/IVault.sol';
import './IGateway.sol';
import '../token/IDToken.sol';
import '../token/IIOU.sol';
import '../../oracle/IOracle.sol';
import '../swapper/ISwapper.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '../../library/Bytes32Map.sol';
import '../../library/ETHAndERC20.sol';
import '../../library/SafeMath.sol';
import { GatewayIndex as I } from './GatewayIndex.sol';
import './GatewayHelper.sol';
import './GatewayStorage.sol';

contract GatewayImplementation is GatewayStorage {

    using Bytes32Map for mapping(uint8 => bytes32);
    using ETHAndERC20 for address;
    using SafeMath for uint256;
    using SafeMath for int256;

    error InvalidBToken();
    error InvalidBAmount();
    error InvalidBPrice();
    error InvalidLTokenId();
    error InvalidPTokenId();
    error InvalidRequestId();
    error InsufficientMargin();
    error InvalidSignature();
    error InsufficientB0();
    error InsufficientExecutionFee();

    event RequestUpdateLiquidity(
        uint256 requestId,
        uint256 lTokenId,
        uint256 liquidity,
        int256  lastCumulativePnlOnEngine,
        int256  cumulativePnlOnGateway,
        uint256 removeBAmount
    );

    event RequestRemoveMargin(
        uint256 requestId,
        uint256 pTokenId,
        uint256 realMoneyMargin,
        int256  lastCumulativePnlOnEngine,
        int256  cumulativePnlOnGateway,
        uint256 bAmount
    );

    event RequestTrade(
        uint256 requestId,
        uint256 pTokenId,
        uint256 realMoneyMargin,
        int256  lastCumulativePnlOnEngine,
        int256  cumulativePnlOnGateway,
        bytes32 symbolId,
        int256[] tradeParams
    );

    event RequestLiquidate(
        uint256 requestId,
        uint256 pTokenId,
        uint256 realMoneyMargin,
        int256  lastCumulativePnlOnEngine,
        int256  cumulativePnlOnGateway
    );

    event RequestTradeAndRemoveMargin(
        uint256 requestId,
        uint256 pTokenId,
        uint256 realMoneyMargin,
        int256  lastCumulativePnlOnEngine,
        int256  cumulativePnlOnGateway,
        uint256 bAmount,
        bytes32 symbolId,
        int256[] tradeParams
    );

    event FinishAddLiquidity(
        uint256 requestId,
        uint256 lTokenId,
        uint256 liquidity,
        uint256 totalLiquidity
    );

    event FinishRemoveLiquidity(
        uint256 requestId,
        uint256 lTokenId,
        uint256 liquidity,
        uint256 totalLiquidity,
        address bToken,
        uint256 bAmount
    );

    event FinishAddMargin(
        uint256 requestId,
        uint256 pTokenId,
        address bToken,
        uint256 bAmount
    );

    event FinishRemoveMargin(
        uint256 requestId,
        uint256 pTokenId,
        address bToken,
        uint256 bAmount
    );

    event FinishLiquidate(
        uint256 requestId,
        uint256 pTokenId,
        int256  lpPnl
    );

    uint256 constant UONE = 1e18;
    int256  constant ONE = 1e18;
    address constant tokenETH = address(1);

    IDToken  internal immutable lToken;
    IDToken  internal immutable pToken;
    IOracle  internal immutable oracle;
    ISwapper internal immutable swapper;
    IVault   internal immutable vault0;  // Vault for holding reserved B0, used for payments on regular bases
    IIOU     internal immutable iou;     // IOU ERC20, issued to traders when B0 insufficent
    address  internal immutable tokenB0; // B0, settlement base token, e.g. USDC
    address  internal immutable dChainEventSigner;
    uint8    internal immutable decimalsB0;
    uint256  internal immutable b0ReserveRatio;
    int256   internal immutable liquidationRewardCutRatio;
    int256   internal immutable minLiquidationReward;
    int256   internal immutable maxLiquidationReward;
    address  internal immutable protocolFeeManager;
    address  internal immutable liqClaim;

    constructor (IGateway.GatewayParam memory p) {
        lToken = IDToken(p.lToken);
        pToken = IDToken(p.pToken);
        oracle = IOracle(p.oracle);
        swapper = ISwapper(p.swapper);
        vault0 = IVault(p.vault0);
        iou = IIOU(p.iou);
        tokenB0 = p.tokenB0;
        decimalsB0 = p.tokenB0.decimals();
        dChainEventSigner = p.dChainEventSigner;
        b0ReserveRatio = p.b0ReserveRatio;
        liquidationRewardCutRatio = p.liquidationRewardCutRatio;
        minLiquidationReward = p.minLiquidationReward;
        maxLiquidationReward = p.maxLiquidationReward;
        protocolFeeManager = p.protocolFeeManager;
        liqClaim = p.liqClaim;
    }

    //================================================================================
    // Getters
    //================================================================================

    function getGatewayParam() external view returns (IGateway.GatewayParam memory p) {
        p.lToken = address(lToken);
        p.pToken = address(pToken);
        p.oracle = address(oracle);
        p.swapper = address(swapper);
        p.vault0 = address(vault0);
        p.iou = address(iou);
        p.tokenB0 = tokenB0;
        p.dChainEventSigner = dChainEventSigner;
        p.b0ReserveRatio = b0ReserveRatio;
        p.liquidationRewardCutRatio = liquidationRewardCutRatio;
        p.minLiquidationReward = minLiquidationReward;
        p.maxLiquidationReward = maxLiquidationReward;
        p.protocolFeeManager = protocolFeeManager;
        p.liqClaim = liqClaim;
    }

    function getGatewayState() external view returns (IGateway.GatewayState memory s) {
        return GatewayHelper.getGatewayState(_gatewayStates);
    }

    function getBTokenState(address bToken) external view returns (IGateway.BTokenState memory s) {
        return GatewayHelper.getBTokenState(_bTokenStates, bToken);
    }

    function getLpState(uint256 lTokenId) external view returns (IGateway.LpState memory s) {
        return GatewayHelper.getLpState(_bTokenStates, _dTokenStates, lTokenId);
    }

    function getTdState(uint256 pTokenId) external view returns (IGateway.TdState memory s) {
        return GatewayHelper.getTdState(_bTokenStates, _dTokenStates, pTokenId);
    }

    // @notice Calculate Lp's cumulative time, used in liquidity mining reward distributions
    function getCumulativeTime(uint256 lTokenId)
    public view returns (uint256 cumulativeTimePerLiquidity, uint256 cumulativeTime)
    {
        uint256 liquidityTime = _gatewayStates.getUint(I.S_LIQUIDITYTIME);
        uint256 totalLiquidity = _gatewayStates.getUint(I.S_TOTALLIQUIDITY);
        cumulativeTimePerLiquidity = _gatewayStates.getUint(I.S_CUMULATIVETIMEPERLIQUIDITY);
        uint256 liquidity = _dTokenStates[lTokenId].getUint(I.D_LIQUIDITY);
        cumulativeTime = _dTokenStates[lTokenId].getUint(I.D_CUMULATIVETIME);
        uint256 lastCumulativeTimePerLiquidity = _dTokenStates[lTokenId].getUint(I.D_LASTCUMULATIVETIMEPERLIQUIDITY);

        if (totalLiquidity != 0) {
            uint256 diff1 = (block.timestamp - liquidityTime) * UONE * UONE / totalLiquidity;
            unchecked { cumulativeTimePerLiquidity += diff1; }

            if (liquidity != 0) {
                uint256 diff2;
                unchecked { diff2 = cumulativeTimePerLiquidity - lastCumulativeTimePerLiquidity; }
                cumulativeTime += diff2 * liquidity / UONE;
            }
        }
    }

    function getExecutionFees() public view returns (uint256[] memory fees) {
        return GatewayHelper.getExecutionFees(_executionFees);
    }

    //================================================================================
    // Setters
    //================================================================================

    function addBToken(
        address bToken,
        address vault,
        bytes32 oracleId,
        uint256 collateralFactor
    ) external _onlyAdmin_ {
        GatewayHelper.addBToken(
            _bTokenStates,
            swapper,
            oracle,
            vault0,
            tokenB0,
            bToken,
            vault,
            oracleId,
            collateralFactor
        );
    }

    function delBToken(address bToken) external _onlyAdmin_ {
        GatewayHelper.delBToken(_bTokenStates, bToken);
    }

    // @dev This function can be used to change bToken collateral factor
    function setBTokenParameter(address bToken, uint8 idx, bytes32 value) external _onlyAdmin_ {
        GatewayHelper.setBTokenParameter(_bTokenStates, bToken, idx, value);
    }

    // @notice Set execution fee for actionId
    function setExecutionFee(uint256 actionId, uint256 executionFee) external _onlyAdmin_ {
        GatewayHelper.setExecutionFee(_executionFees, actionId, executionFee);
    }

    function setDChainExecutionFeePerRequest(uint256 dChainExecutionFeePerRequest) external _onlyAdmin_ {
        GatewayHelper.setDChainExecutionFeePerRequest(_gatewayStates, dChainExecutionFeePerRequest);
    }

    // @notic Claim dChain executionFee to account `to`
    function claimDChainExecutionFee(address to) external _onlyAdmin_ {
        GatewayHelper.claimDChainExecutionFee(_gatewayStates, to);
    }

    // @notice Claim unused iChain execution fee for dTokenId
    function claimUnusedIChainExecutionFee(uint256 dTokenId, bool isLp) external {
        GatewayHelper.claimUnusedIChainExecutionFee(
            _gatewayStates,
            _dTokenStates,
            lToken,
            pToken,
            dTokenId,
            isLp
        );
    }

    // @notice Redeem B0 for burning IOU
    function redeemIOU(uint256 b0Amount) external {
        GatewayHelper.redeemIOU(tokenB0, vault0, iou, msg.sender, b0Amount);
    }

    //================================================================================
    // Interactions
    //================================================================================

    function finishCollectProtocolFee(bytes memory eventData, bytes memory signature) external _onlyAdmin_ {
        require(eventData.length == 64);
        _verifyEventData(eventData, signature);
        IGateway.VarOnExecuteCollectProtocolFee memory v = abi.decode(eventData, (IGateway.VarOnExecuteCollectProtocolFee));
        require(v.chainId == block.chainid);

        GatewayHelper.finishCollectProtocolFee(
            _gatewayStates,
            vault0,
            tokenB0,
            protocolFeeManager,
            v.cumulativeCollectedProtocolFeeOnEngine
        );
    }

    /**
     * @notice Request to add liquidity with specified base token.
     * @param lTokenId The unique identifier of the LToken.
     * @param bToken The address of the base token to add as liquidity.
     * @param bAmount The amount of base tokens to add as liquidity.
     */
    function requestAddLiquidity(uint256 lTokenId, address bToken, uint256 bAmount) external payable {
        if (lTokenId == 0) {
            lTokenId = lToken.mint(msg.sender);
        } else {
            _checkLTokenIdOwner(lTokenId, msg.sender);
        }
        _checkBTokenInitialized(bToken);

        Data memory data = _getData(msg.sender, lTokenId, bToken);

        uint256 ethAmount = _receiveExecutionFee(lTokenId, _executionFees[I.ACTION_REQUESTADDLIQUIDITY]);
        if (bToken == tokenETH) {
            bAmount = ethAmount;
        }
        if (bAmount == 0) {
            revert InvalidBAmount();
        }
        if (bToken != tokenETH) {
            bToken.transferIn(data.account, bAmount);
        }

        _deposit(data, bAmount);
        _getExParams(data);
        uint256 newLiquidity = _getDTokenLiquidity(data);

        _saveData(data);

        uint256 requestId = _incrementRequestId(lTokenId);
        emit RequestUpdateLiquidity(
            requestId,
            lTokenId,
            newLiquidity,
            data.lastCumulativePnlOnEngine,
            data.cumulativePnlOnGateway,
            0
        );
    }

    /**
     * @notice Request to remove liquidity with specified base token.
     * @param lTokenId The unique identifier of the LToken.
     * @param bToken The address of the base token to remove as liquidity.
     * @param bAmount The amount of base tokens to remove as liquidity.
     */
    function requestRemoveLiquidity(uint256 lTokenId, address bToken, uint256 bAmount) external payable {
        _checkLTokenIdOwner(lTokenId, msg.sender);

        _receiveExecutionFee(lTokenId, _executionFees[I.ACTION_REQUESTREMOVELIQUIDITY]);
        if (bAmount == 0) {
            revert InvalidBAmount();
        }

        Data memory data = _getData(msg.sender, lTokenId, bToken);
        _getExParams(data);
        uint256 oldLiquidity = _getDTokenLiquidity(data);
        uint256 newLiquidity = _getDTokenLiquidityWithRemove(data, bAmount);
        if (newLiquidity <= oldLiquidity / 100) {
            newLiquidity = 0;
        }

        uint256 requestId = _incrementRequestId(lTokenId);
        emit RequestUpdateLiquidity(
            requestId,
            lTokenId,
            newLiquidity,
            data.lastCumulativePnlOnEngine,
            data.cumulativePnlOnGateway,
            bAmount
        );
    }

    /**
     * @notice Request to add margin with specified base token.
     * @param pTokenId The unique identifier of the PToken.
     * @param bToken The address of the base token to add as margin.
     * @param bAmount The amount of base tokens to add as margin.
     * @param singlePosition The flag whether trader is using singlePosition margin.
     * @return The unique identifier pTokenId.
     */
    function requestAddMargin(uint256 pTokenId, address bToken, uint256 bAmount, bool singlePosition) public payable returns (uint256) {
        if (pTokenId == 0) {
            pTokenId = pToken.mint(msg.sender);
            if (singlePosition) {
                _dTokenStates[pTokenId].set(I.D_SINGLEPOSITION, true);
            }
        } else {
            _checkPTokenIdOwner(pTokenId, msg.sender);
        }
        _checkBTokenInitialized(bToken);

        Data memory data = _getData(msg.sender, pTokenId, bToken);

        if (bToken == tokenETH) {
            if (bAmount > msg.value) {
                revert InvalidBAmount();
            }
        }
        if (bAmount == 0) {
            revert InvalidBAmount();
        }
        if (bToken != tokenETH) {
            bToken.transferIn(data.account, bAmount);
        }

        _deposit(data, bAmount);

        _saveData(data);

        uint256 requestId = _incrementRequestId(pTokenId);
        emit FinishAddMargin(
            requestId,
            pTokenId,
            bToken,
            bAmount
        );

        return pTokenId;
    }

    /**
     * @notice Request to remove margin with specified base token.
     * @param pTokenId The unique identifier of the PToken.
     * @param bToken The address of the base token to remove as margin.
     * @param bAmount The amount of base tokens to remove as margin.
     */
    function requestRemoveMargin(uint256 pTokenId, address bToken, uint256 bAmount) external payable {
        _checkPTokenIdOwner(pTokenId, msg.sender);

        _receiveExecutionFee(pTokenId, _executionFees[I.ACTION_REQUESTREMOVEMARGIN]);
        if (bAmount == 0) {
            revert InvalidBAmount();
        }

        Data memory data = _getData(msg.sender, pTokenId, bToken);
        _getExParams(data);
        uint256 oldMargin = _getDTokenLiquidity(data);
        uint256 newMargin = _getDTokenLiquidityWithRemove(data, bAmount);
        if (newMargin <= oldMargin / 100) {
            newMargin = 0;
        }

        uint256 requestId = _incrementRequestId(pTokenId);
        emit RequestRemoveMargin(
            requestId,
            pTokenId,
            newMargin,
            data.lastCumulativePnlOnEngine,
            data.cumulativePnlOnGateway,
            bAmount
        );
    }

    /**
     * @notice Request to initiate a trade using a specified PToken, symbol identifier, and trade parameters.
     * @param pTokenId The unique identifier of the PToken.
     * @param symbolId The identifier of the trading symbol.
     * @param tradeParams An array of trade parameters for the trade execution.
     */
    function requestTrade(uint256 pTokenId, bytes32 symbolId, int256[] calldata tradeParams) public payable {
        _checkPTokenIdOwner(pTokenId, msg.sender);

        _receiveExecutionFee(pTokenId, _executionFees[I.ACTION_REQUESTTRADE]);

        Data memory data = _getData(msg.sender, pTokenId, _dTokenStates[pTokenId].getAddress(I.D_BTOKEN));
        _getExParams(data);
        uint256 realMoneyMargin = _getDTokenLiquidity(data);

        uint256 requestId = _incrementRequestId(pTokenId);
        emit RequestTrade(
            requestId,
            pTokenId,
            realMoneyMargin,
            data.lastCumulativePnlOnEngine,
            data.cumulativePnlOnGateway,
            symbolId,
            tradeParams
        );
    }

    /**
     * @notice Request to liquidate a specified PToken.
     * @param pTokenId The unique identifier of the PToken.
     */
    function requestLiquidate(uint256 pTokenId) external {
        Data memory data = _getData(pToken.ownerOf(pTokenId), pTokenId, _dTokenStates[pTokenId].getAddress(I.D_BTOKEN));
        _getExParams(data);
        uint256 realMoneyMargin = _getDTokenLiquidity(data);

        uint256 requestId = _incrementRequestId(pTokenId);
        emit RequestLiquidate(
            requestId,
            pTokenId,
            realMoneyMargin,
            data.lastCumulativePnlOnEngine,
            data.cumulativePnlOnGateway
        );
    }

    /**
     * @notice Request to add margin and initiate a trade in a single transaction.
     * @param pTokenId The unique identifier of the PToken.
     * @param bToken The address of the base token to add as margin.
     * @param bAmount The amount of base tokens to add as margin.
     * @param symbolId The identifier of the trading symbol for the trade.
     * @param tradeParams An array of trade parameters for the trade execution.
     * @param singlePosition The flag whether trader is using singlePosition margin.
     */
    function requestAddMarginAndTrade(
        uint256 pTokenId,
        address bToken,
        uint256 bAmount,
        bytes32 symbolId,
        int256[] calldata tradeParams,
        bool singlePosition
    ) external payable {
        if (bToken == tokenETH) {
            uint256 executionFee = _executionFees[I.ACTION_REQUESTTRADE];
            if (bAmount + executionFee > msg.value) { // revert if bAmount > msg.value - executionFee
                revert InvalidBAmount();
            }
        }
        pTokenId = requestAddMargin(pTokenId, bToken, bAmount, singlePosition);
        requestTrade(pTokenId, symbolId, tradeParams);
    }

    /**
     * @notice Request to initiate a trade and simultaneously remove margin from a specified PToken.
     * @param pTokenId The unique identifier of the PToken.
     * @param bToken The address of the base token to remove as margin.
     * @param bAmount The amount of base tokens to remove as margin.
     * @param symbolId The identifier of the trading symbol for the trade.
     * @param tradeParams An array of trade parameters for the trade execution.
     */
    function requestTradeAndRemoveMargin(
        uint256 pTokenId,
        address bToken,
        uint256 bAmount,
        bytes32 symbolId,
        int256[] calldata tradeParams
    ) external payable {
        _checkPTokenIdOwner(pTokenId, msg.sender);

        _receiveExecutionFee(pTokenId, _executionFees[I.ACTION_REQUESTTRADEANDREMOVEMARGIN]);
        if (bAmount == 0) {
            revert InvalidBAmount();
        }

        Data memory data = _getData(msg.sender, pTokenId, bToken);
        _getExParams(data);
        uint256 oldMargin = _getDTokenLiquidity(data);
        uint256 newMargin = _getDTokenLiquidityWithRemove(data, bAmount);
        if (newMargin <= oldMargin / 100) {
            newMargin = 0;
        }

        uint256 requestId = _incrementRequestId(pTokenId);
        emit RequestTradeAndRemoveMargin(
            requestId,
            pTokenId,
            newMargin,
            data.lastCumulativePnlOnEngine,
            data.cumulativePnlOnGateway,
            bAmount,
            symbolId,
            tradeParams
        );
    }

    /**
     * @notice Finalize the liquidity update based on event emitted on d-chain.
     * @param eventData The encoded event data containing information about the liquidity update, emitted on d-chain.
     * @param signature The signature used to verify the event data.
     */
    function finishUpdateLiquidity(bytes memory eventData, bytes memory signature) external _reentryLock_ {
        require(eventData.length == 192);
        _verifyEventData(eventData, signature);
        IGateway.VarOnExecuteUpdateLiquidity memory v = abi.decode(eventData, (IGateway.VarOnExecuteUpdateLiquidity));
        _checkRequestId(v.lTokenId, v.requestId);

        _updateLiquidity(v.lTokenId, v.liquidity, v.totalLiquidity);

        // Cumulate unsettled PNL to b0Amount
        Data memory data = _getData(lToken.ownerOf(v.lTokenId), v.lTokenId, _dTokenStates[v.lTokenId].getAddress(I.D_BTOKEN));
        int256 diff = v.cumulativePnlOnEngine.minusUnchecked(data.lastCumulativePnlOnEngine);
        data.b0Amount += diff.rescaleDown(18, decimalsB0);
        data.lastCumulativePnlOnEngine = v.cumulativePnlOnEngine;

        uint256 bAmountRemoved;
        if (v.bAmountToRemove != 0) {
            _getExParams(data);
            bAmountRemoved = _transferOut(data, v.liquidity == 0 ? type(uint256).max : v.bAmountToRemove, false);
        }

        _saveData(data);

        _transferLastRequestIChainExecutionFee(v.lTokenId, msg.sender);

        if (v.bAmountToRemove == 0) {
            // If bAmountToRemove == 0, it is a AddLiqudiity finalization
            emit FinishAddLiquidity(
                v.requestId,
                v.lTokenId,
                v.liquidity,
                v.totalLiquidity
            );
        } else {
            // If bAmountToRemove != 0, it is a RemoveLiquidity finalization
            emit FinishRemoveLiquidity(
                v.requestId,
                v.lTokenId,
                v.liquidity,
                v.totalLiquidity,
                data.bToken,
                bAmountRemoved
            );
        }
    }

    /**
     * @notice Finalize the remove of margin based on event emitted on d-chain.
     * @param eventData The encoded event data containing information about the margin remove, emitted on d-chain.
     * @param signature The signature used to verify the event data.
     */
    function finishRemoveMargin(bytes memory eventData, bytes memory signature) external _reentryLock_ {
        require(eventData.length == 160);
        _verifyEventData(eventData, signature);
        IGateway.VarOnExecuteRemoveMargin memory v = abi.decode(eventData, (IGateway.VarOnExecuteRemoveMargin));
        _checkRequestId(v.pTokenId, v.requestId);

        // Cumulate unsettled PNL to b0Amount
        Data memory data = _getData(pToken.ownerOf(v.pTokenId), v.pTokenId, _dTokenStates[v.pTokenId].getAddress(I.D_BTOKEN));
        int256 diff = v.cumulativePnlOnEngine.minusUnchecked(data.lastCumulativePnlOnEngine);
        data.b0Amount += diff.rescaleDown(18, decimalsB0);
        data.lastCumulativePnlOnEngine = v.cumulativePnlOnEngine;

        _getExParams(data);
        uint256 bAmount = _transferOut(data, v.bAmountToRemove, true);

        if (_getDTokenLiquidity(data) < v.requiredMargin) {
            revert InsufficientMargin();
        }

        _saveData(data);

        _transferLastRequestIChainExecutionFee(v.pTokenId, msg.sender);

        emit FinishRemoveMargin(
            v.requestId,
            v.pTokenId,
            data.bToken,
            bAmount
        );
    }

    /**
     * @notice Finalize the liquidation based on event emitted on d-chain.
     * @param eventData The encoded event data containing information about the liquidation, emitted on d-chain.
     * @param signature The signature used to verify the event data.
     */
    function finishLiquidate(bytes memory eventData, bytes memory signature) external _reentryLock_ {
        require(eventData.length == 128);
        _verifyEventData(eventData, signature);
        IGateway.VarOnExecuteLiquidate memory v = abi.decode(eventData, (IGateway.VarOnExecuteLiquidate));

        // Cumulate unsettled PNL to b0Amount
        Data memory data = _getData(pToken.ownerOf(v.pTokenId), v.pTokenId, _dTokenStates[v.pTokenId].getAddress(I.D_BTOKEN));
        int256 diff = v.cumulativePnlOnEngine.minusUnchecked(data.lastCumulativePnlOnEngine);
        data.b0Amount += diff.rescaleDown(18, decimalsB0);
        data.lastCumulativePnlOnEngine = v.cumulativePnlOnEngine;

        uint256 b0AmountIn;

        {
            uint256 bAmount = IVault(data.vault).redeem(data.dTokenId, type(uint256).max);
            if (data.bToken == tokenB0) {
                b0AmountIn += bAmount;
            } else {
                b0AmountIn += GatewayHelper.liquidateRedeemAndSwap(
                    decimalsB0,
                    data.bToken,
                    address(swapper),
                    liqClaim,
                    address(pToken),
                    data.dTokenId,
                    data.b0Amount,
                    bAmount,
                    v.maintenanceMarginRequired
                );
            }
        }

        int256 lpPnl = b0AmountIn.utoi() + data.b0Amount; // All Lp's PNL by liquidating this trader
        int256 reward;

        // Calculate liquidator's reward
        {
            if (lpPnl <= minLiquidationReward) {
                reward = minLiquidationReward;
            } else {
                reward = SafeMath.min(
                    (lpPnl - minLiquidationReward) * liquidationRewardCutRatio / ONE + minLiquidationReward,
                    maxLiquidationReward
                );
            }

            uint256 uReward = reward.itou();
            if (uReward <= b0AmountIn) {
                tokenB0.transferOut(msg.sender, uReward);
                b0AmountIn -= uReward;
            } else {
                uint256 b0Redeemed = vault0.redeem(uint256(0), uReward - b0AmountIn);
                tokenB0.transferOut(msg.sender, b0AmountIn + b0Redeemed);
                reward = (b0AmountIn + b0Redeemed).utoi();
                b0AmountIn = 0;
            }

            lpPnl -= reward;
        }

        if (b0AmountIn > 0) {
            vault0.deposit(uint256(0), b0AmountIn);
        }

        // Cumulate lpPnl into cumulativePnlOnGateway,
        // which will be distributed to all LPs on all i-chains with next request process
        data.cumulativePnlOnGateway = data.cumulativePnlOnGateway.addUnchecked(lpPnl.rescale(decimalsB0, 18));
        data.b0Amount = 0;
        _saveData(data);

        {
            uint256 lastRequestIChainExecutionFee = _dTokenStates[v.pTokenId].getUint(I.D_LASTREQUESTICHAINEXECUTIONFEE);
            uint256 cumulativeUnusedIChainExecutionFee = _dTokenStates[v.pTokenId].getUint(I.D_CUMULATIVEUNUSEDICHAINEXECUTIONFEE);
            _dTokenStates[v.pTokenId].del(I.D_LASTREQUESTICHAINEXECUTIONFEE);
            _dTokenStates[v.pTokenId].del(I.D_CUMULATIVEUNUSEDICHAINEXECUTIONFEE);

            uint256 totalIChainExecutionFee = _gatewayStates.getUint(I.S_TOTALICHAINEXECUTIONFEE);
            totalIChainExecutionFee -= lastRequestIChainExecutionFee + cumulativeUnusedIChainExecutionFee;
            _gatewayStates.set(I.S_TOTALICHAINEXECUTIONFEE, totalIChainExecutionFee);
        }

        pToken.burn(v.pTokenId);

        emit FinishLiquidate(
            v.requestId,
            v.pTokenId,
            lpPnl
        );
    }

    //================================================================================
    // Internals
    //================================================================================

    // Temporary struct holding intermediate values passed around functions
    struct Data {
        address account;                   // Lp/Trader account address
        uint256 dTokenId;                  // Lp/Trader dTokenId
        address bToken;                    // Lp/Trader bToken address

        int256  cumulativePnlOnGateway;    // cumulative pnl on Gateway
        address vault;                     // Lp/Trader bToken's vault address

        int256  b0Amount;                  // Lp/Trader b0Amount
        int256  lastCumulativePnlOnEngine; // Lp/Trader last cumulative pnl on engine

        uint256 collateralFactor;          // bToken collateral factor
        uint256 bPrice;                    // bToken price
    }

    function _getData(address account, uint256 dTokenId, address bToken) internal view returns (Data memory data) {
        data.account = account;
        data.dTokenId = dTokenId;
        data.bToken = bToken;

        data.cumulativePnlOnGateway = _gatewayStates.getInt(I.S_CUMULATIVEPNLONGATEWAY);
        data.vault = _bTokenStates[bToken].getAddress(I.B_VAULT);

        data.b0Amount = _dTokenStates[dTokenId].getInt(I.D_B0AMOUNT);
        data.lastCumulativePnlOnEngine = _dTokenStates[dTokenId].getInt(I.D_LASTCUMULATIVEPNLONENGINE);

        _checkBTokenConsistency(dTokenId, bToken);
    }

    function _saveData(Data memory data) internal {
        _gatewayStates.set(I.S_CUMULATIVEPNLONGATEWAY, data.cumulativePnlOnGateway);
        _dTokenStates[data.dTokenId].set(I.D_BTOKEN, data.bToken);
        _dTokenStates[data.dTokenId].set(I.D_B0AMOUNT, data.b0Amount);
        _dTokenStates[data.dTokenId].set(I.D_LASTCUMULATIVEPNLONENGINE, data.lastCumulativePnlOnEngine);
    }

    // @notice Check callback's requestId is the same as the current requestId stored for user
    // If a new request is submitted before the callback for last request, requestId will not match,
    // and this callback cannot be executed anymore
    function _checkRequestId(uint256 dTokenId, uint256 requestId) internal {
        uint128 userRequestId = uint128(requestId);
        if (_dTokenStates[dTokenId].getUint(I.D_REQUESTID) != uint256(userRequestId)) {
            revert InvalidRequestId();
        } else {
            // increment requestId so that callback can only be executed once
            _dTokenStates[dTokenId].set(I.D_REQUESTID, uint256(userRequestId + 1));
        }
    }

    // @notice Increment gateway requestId and user requestId
    // and returns the combined requestId for this request
    // The combined requestId contains 2 parts:
    //   * Lower 128 bits stores user's requestId, only increments when request is from this user
    //   * Higher 128 bits stores gateways's requestId, increments for all new requests in this contract
    function _incrementRequestId(uint256 dTokenId) internal returns (uint256) {
        uint128 gatewayRequestId = uint128(_gatewayStates.getUint(I.S_GATEWAYREQUESTID));
        gatewayRequestId += 1;
        _gatewayStates.set(I.S_GATEWAYREQUESTID, uint256(gatewayRequestId));

        uint128 userRequestId = uint128(_dTokenStates[dTokenId].getUint(I.D_REQUESTID));
        userRequestId += 1;
        _dTokenStates[dTokenId].set(I.D_REQUESTID, uint256(userRequestId));

        uint256 requestId = (uint256(gatewayRequestId) << 128) + uint256(userRequestId);
        return requestId;
    }

    function _checkBTokenInitialized(address bToken) internal view {
        if (_bTokenStates[bToken].getAddress(I.B_VAULT) == address(0)) {
            revert InvalidBToken();
        }
    }

    function _checkBTokenConsistency(uint256 dTokenId, address bToken) internal view {
        address preBToken = _dTokenStates[dTokenId].getAddress(I.D_BTOKEN);
        if (preBToken != address(0) && preBToken != bToken) {
            uint256 stAmount = IVault(_bTokenStates[preBToken].getAddress(I.B_VAULT)).stAmounts(dTokenId);
            if (stAmount != 0) {
                revert InvalidBToken();
            }
        }
    }

    function _checkLTokenIdOwner(uint256 lTokenId, address owner) internal view {
        if (lToken.ownerOf(lTokenId) != owner) {
            revert InvalidLTokenId();
        }
    }

    function _checkPTokenIdOwner(uint256 pTokenId, address owner) internal view {
        if (pToken.ownerOf(pTokenId) != owner) {
            revert InvalidPTokenId();
        }
    }

    function _receiveExecutionFee(uint256 dTokenId, uint256 executionFee) internal returns (uint256) {
        uint256 dChainExecutionFee = _gatewayStates.getUint(I.S_DCHAINEXECUTIONFEEPERREQUEST);
        if (msg.value < executionFee) {
            revert InsufficientExecutionFee();
        }
        uint256 iChainExecutionFee = executionFee - dChainExecutionFee;

        uint256 totalIChainExecutionFee = _gatewayStates.getUint(I.S_TOTALICHAINEXECUTIONFEE) + iChainExecutionFee;
        _gatewayStates.set(I.S_TOTALICHAINEXECUTIONFEE,  totalIChainExecutionFee);

        uint256 lastRequestIChainExecutionFee = _dTokenStates[dTokenId].getUint(I.D_LASTREQUESTICHAINEXECUTIONFEE);
        uint256 cumulativeUnusedIChainExecutionFee = _dTokenStates[dTokenId].getUint(I.D_CUMULATIVEUNUSEDICHAINEXECUTIONFEE);
        cumulativeUnusedIChainExecutionFee += lastRequestIChainExecutionFee;
        lastRequestIChainExecutionFee = iChainExecutionFee;
        _dTokenStates[dTokenId].set(I.D_LASTREQUESTICHAINEXECUTIONFEE, lastRequestIChainExecutionFee);
        _dTokenStates[dTokenId].set(I.D_CUMULATIVEUNUSEDICHAINEXECUTIONFEE, cumulativeUnusedIChainExecutionFee);

        return msg.value - executionFee;
    }

    function _transferLastRequestIChainExecutionFee(uint256 dTokenId, address to) internal {
        uint256 lastRequestIChainExecutionFee = _dTokenStates[dTokenId].getUint(I.D_LASTREQUESTICHAINEXECUTIONFEE);

        if (lastRequestIChainExecutionFee > 0) {
            uint256 totalIChainExecutionFee = _gatewayStates.getUint(I.S_TOTALICHAINEXECUTIONFEE);
            totalIChainExecutionFee -= lastRequestIChainExecutionFee;
            _gatewayStates.set(I.S_TOTALICHAINEXECUTIONFEE, totalIChainExecutionFee);

            _dTokenStates[dTokenId].del(I.D_LASTREQUESTICHAINEXECUTIONFEE);

            tokenETH.transferOut(to, lastRequestIChainExecutionFee);
        }
    }

    // @dev bPrice * bAmount / UONE = b0Amount, b0Amount in decimalsB0
    function _getBPrice(address bToken) internal view returns (uint256 bPrice) {
        if (bToken == tokenB0) {
            bPrice = UONE;
        } else {
            uint8 decimalsB = bToken.decimals();
            bPrice = oracle.getValue(_bTokenStates[bToken].getBytes32(I.B_ORACLEID)).itou().rescale(decimalsB, decimalsB0);
            if (bPrice == 0) {
                revert InvalidBPrice();
            }
        }
    }

    function _getExParams(Data memory data) internal view {
        data.collateralFactor = _bTokenStates[data.bToken].getUint(I.B_COLLATERALFACTOR);
        data.bPrice = _getBPrice(data.bToken);
    }

    // @notice Calculate the liquidity (in 18 decimals) associated with current dTokenId
    function _getDTokenLiquidity(Data memory data) internal view returns (uint256 liquidity) {
        uint256 b0AmountInVault = IVault(data.vault).getBalance(data.dTokenId) * data.bPrice / UONE * data.collateralFactor / UONE;
        uint256 b0Shortage = data.b0Amount >= 0 ? 0 : (-data.b0Amount).itou();
        if (b0AmountInVault >= b0Shortage) {
            liquidity = b0AmountInVault.add(data.b0Amount).rescale(decimalsB0, 18);
        }
    }

    // @notice Calculate the liquidity (in 18 decimals) associated with current dTokenId if `bAmount` in bToken is removed
    function _getDTokenLiquidityWithRemove(Data memory data, uint256 bAmount) internal view returns (uint256 liquidity) {
        if (bAmount < type(uint256).max / data.bPrice) { // make sure bAmount * bPrice won't overflow
            uint256 bAmountInVault = IVault(data.vault).getBalance(data.dTokenId);
            if (bAmount >= bAmountInVault) {
                if (data.b0Amount > 0) {
                    uint256 b0Shortage = (bAmount - bAmountInVault) * data.bPrice / UONE;
                    uint256 b0Amount = data.b0Amount.itou();
                    if (b0Amount > b0Shortage) {
                        liquidity = (b0Amount - b0Shortage).rescale(decimalsB0, 18);
                    }
                }
            } else {
                uint256 b0Excessive = (bAmountInVault - bAmount) * data.bPrice / UONE * data.collateralFactor / UONE; // discounted
                if (data.b0Amount >= 0) {
                    liquidity = b0Excessive.add(data.b0Amount).rescale(decimalsB0, 18);
                } else {
                    uint256 b0Shortage = (-data.b0Amount).itou();
                    if (b0Excessive > b0Shortage) {
                        liquidity = (b0Excessive - b0Shortage).rescale(decimalsB0, 18);
                    }
                }
            }
        }
    }

    // @notice Deposit bToken with `bAmount`
    function _deposit(Data memory data, uint256 bAmount) internal {
        if (data.bToken == tokenB0) {
            uint256 reserved = bAmount * b0ReserveRatio / UONE;
            bAmount -= reserved;
            vault0.deposit(uint256(0), reserved);
            data.b0Amount += reserved.utoi();
        }
        if (data.bToken == tokenETH) {
            IVault(data.vault).deposit{value: bAmount}(data.dTokenId, bAmount);
        } else {
            IVault(data.vault).deposit(data.dTokenId, bAmount);
        }
    }

    /**
     * @notice Transfer a specified amount of bToken, handling various cases.
     * @param data A Data struct containing information about the interaction.
     * @param bAmountOut The intended amount of tokens to transfer out.
     * @param isTd A flag indicating whether the transfer is for a trader (true) or not (false).
     * @return bAmount The amount of tokens actually transferred.
     */
    function _transferOut(Data memory data, uint256 bAmountOut, bool isTd) internal returns (uint256 bAmount) {
        bAmount = bAmountOut;

        // Handle redemption of additional tokens to cover a negative B0 amount.
        if (bAmount < type(uint256).max / UONE && data.b0Amount < 0) {
            if (data.bToken == tokenB0) {
                // Redeem B0 tokens to cover the negative B0 amount.
                bAmount += (-data.b0Amount).itou();
            } else {
                // Swap tokens to B0 to cover the negative B0 amount, with a slight excess to account for possible slippage.
                bAmount += (-data.b0Amount).itou() * UONE / data.bPrice * 105 / 100;
            }
        }

        // Redeem tokens from the vault using IVault interface.
        bAmount = IVault(data.vault).redeem(data.dTokenId, bAmount); // bAmount now represents the actual redeemed bToken.

        uint256 b0AmountIn;  // Amount of B0 tokens going to reserves.
        uint256 b0AmountOut; // Amount of B0 tokens going to the user.
        uint256 iouAmount;   // Amount of IOU tokens going to the trader.

        // Handle excessive tokens (more than bAmountOut).
        if (bAmount > bAmountOut) {
            uint256 bExcessive = bAmount - bAmountOut;
            uint256 b0Excessive;
            if (data.bToken == tokenB0) {
                b0Excessive = bExcessive;
                bAmount -= bExcessive;
            } else if (data.bToken == tokenETH) {
                (uint256 resultB0, uint256 resultBX) = swapper.swapExactETHForB0{value: bExcessive}();
                b0Excessive = resultB0;
                bAmount -= resultBX;
            } else {
                (uint256 resultB0, uint256 resultBX) = swapper.swapExactBXForB0(data.bToken, bExcessive);
                b0Excessive = resultB0;
                bAmount -= resultBX;
            }
            b0AmountIn += b0Excessive;
            data.b0Amount += b0Excessive.utoi();
        }

        // Handle filling the negative B0 balance, by swapping bToken into B0, if necessary.
        if (bAmount > 0 && data.b0Amount < 0) {
            uint256 owe = (-data.b0Amount).itou();
            uint256 b0Fill;
            if (data.bToken == tokenB0) {
                if (bAmount >= owe) {
                    b0Fill = owe;
                    bAmount -= owe;
                } else {
                    b0Fill = bAmount;
                    bAmount = 0;
                }
            } else if (data.bToken == tokenETH) {
                (uint256 resultB0, uint256 resultBX) = swapper.swapETHForExactB0{value: bAmount}(owe);
                b0Fill = resultB0;
                bAmount -= resultBX;
            } else {
                (uint256 resultB0, uint256 resultBX) = swapper.swapBXForExactB0(data.bToken, owe, bAmount);
                b0Fill = resultB0;
                bAmount -= resultBX;
            }
            b0AmountIn += b0Fill;
            data.b0Amount += b0Fill.utoi();
        }

        // Handle reserved portion when withdrawing all or operating token is tokenB0
        if (data.b0Amount > 0) {
            uint256 amount;
            if (bAmountOut >= type(uint256).max / UONE) { // withdraw all
                amount = data.b0Amount.itou();
            } else if (data.bToken == tokenB0 && bAmount < bAmountOut) { // shortage on tokenB0
                amount = SafeMath.min(data.b0Amount.itou(), bAmountOut - bAmount);
            }
            if (amount > 0) {
                uint256 b0Out;
                if (amount > b0AmountIn) {
                    // Redeem B0 tokens from vault0
                    uint256 b0Redeemed = vault0.redeem(uint256(0), amount - b0AmountIn);
                    if (b0Redeemed < amount - b0AmountIn) { // b0 insufficent
                        if (isTd) {
                            iouAmount = amount - b0AmountIn - b0Redeemed; // Issue IOU for trader when B0 insufficent
                        } else {
                            revert InsufficientB0(); // Revert for Lp when B0 insufficent
                        }
                    }
                    b0Out = b0AmountIn + b0Redeemed;
                    b0AmountIn = 0;
                } else {
                    b0Out = amount;
                    b0AmountIn -= amount;
                }
                b0AmountOut += b0Out;
                data.b0Amount -= b0Out.utoi() + iouAmount.utoi();
            }
        }

        // Deposit B0 tokens into the vault0, if any
        if (b0AmountIn > 0) {
            vault0.deposit(uint256(0), b0AmountIn);
        }

        // Transfer B0 tokens or swap them to the current operating token
        if (b0AmountOut > 0) {
            if (isTd) {
                // No swap from B0 to BX for trader
                if (data.bToken == tokenB0) {
                    bAmount += b0AmountOut;
                } else {
                    tokenB0.transferOut(data.account, b0AmountOut);
                }
            } else {
                // Swap B0 into BX for Lp
                if (data.bToken == tokenB0) {
                    bAmount += b0AmountOut;
                } else if (data.bToken == tokenETH) {
                    (, uint256 resultBX) = swapper.swapExactB0ForETH(b0AmountOut);
                    bAmount += resultBX;
                } else {
                    (, uint256 resultBX) = swapper.swapExactB0ForBX(data.bToken, b0AmountOut);
                    bAmount += resultBX;
                }
            }
        }

        // Transfer the remaining bAmount to the user's account.
        if (bAmount > 0) {
            data.bToken.transferOut(data.account, bAmount);
        }

        // Mint IOU tokens for the trader, if any.
        if (iouAmount > 0) {
            iou.mint(data.account, iouAmount);
        }
    }

    /**
     * @dev Update liquidity-related state variables for a specific `lTokenId`.
     * @param lTokenId The ID of the corresponding lToken.
     * @param newLiquidity The new liquidity amount for the lToken.
     * @param newTotalLiquidity The new total liquidity in the engine.
     */
    function _updateLiquidity(uint256 lTokenId, uint256 newLiquidity, uint256 newTotalLiquidity) internal {
        (uint256 cumulativeTimePerLiquidity, uint256 cumulativeTime) = getCumulativeTime(lTokenId);
        _gatewayStates.set(I.S_LIQUIDITYTIME, block.timestamp);
        _gatewayStates.set(I.S_TOTALLIQUIDITY, newTotalLiquidity);
        _gatewayStates.set(I.S_CUMULATIVETIMEPERLIQUIDITY, cumulativeTimePerLiquidity);
        _dTokenStates[lTokenId].set(I.D_LIQUIDITY, newLiquidity);
        _dTokenStates[lTokenId].set(I.D_CUMULATIVETIME, cumulativeTime);
        _dTokenStates[lTokenId].set(I.D_LASTCUMULATIVETIMEPERLIQUIDITY, cumulativeTimePerLiquidity);
    }

    function _verifyEventData(bytes memory eventData, bytes memory signature) internal view {
        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(eventData));
        if (ECDSA.recover(hash, signature) != dChainEventSigner) {
            revert InvalidSignature();
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library GatewayIndex {

    uint8 constant S_CUMULATIVEPNLONGATEWAY       = 1; // Cumulative pnl on Gateway
    uint8 constant S_LIQUIDITYTIME                = 2; // Last timestamp when liquidity updated
    uint8 constant S_TOTALLIQUIDITY               = 3; // Total liquidity on d-chain
    uint8 constant S_CUMULATIVETIMEPERLIQUIDITY   = 4; // Cumulavie time per liquidity
    uint8 constant S_GATEWAYREQUESTID             = 5; // Gateway request id
    uint8 constant S_DCHAINEXECUTIONFEEPERREQUEST = 6; // dChain execution fee for executing request on dChain
    uint8 constant S_TOTALICHAINEXECUTIONFEE      = 7; // Total iChain execution fee paid by all requests
    uint8 constant S_CUMULATIVECOLLECTEDPROTOCOLFEE = 8; // Cumulative collected protocol fee on Gateway

    uint8 constant B_VAULT             = 1; // BToken vault address
    uint8 constant B_ORACLEID          = 2; // BToken oracle id
    uint8 constant B_COLLATERALFACTOR  = 3; // BToken collateral factor

    uint8 constant D_REQUESTID                          = 1;  // Lp/Trader request id
    uint8 constant D_BTOKEN                             = 2;  // Lp/Trader bToken
    uint8 constant D_B0AMOUNT                           = 3;  // Lp/Trader b0Amount
    uint8 constant D_LASTCUMULATIVEPNLONENGINE          = 4;  // Lp/Trader last cumulative pnl on engine
    uint8 constant D_LIQUIDITY                          = 5;  // Lp liquidity
    uint8 constant D_CUMULATIVETIME                     = 6;  // Lp cumulative time
    uint8 constant D_LASTCUMULATIVETIMEPERLIQUIDITY     = 7;  // Lp last cumulative time per liquidity
    uint8 constant D_SINGLEPOSITION                     = 8;  // Td single position flag
    uint8 constant D_LASTREQUESTICHAINEXECUTIONFEE      = 9;  // User last request's iChain execution fee
    uint8 constant D_CUMULATIVEUNUSEDICHAINEXECUTIONFEE = 10; // User cumulaitve iChain execution fee for requests cannot be finished, users can claim back

    uint256 constant ACTION_REQUESTADDLIQUIDITY         = 1;
    uint256 constant ACTION_REQUESTREMOVELIQUIDITY      = 2;
    uint256 constant ACTION_REQUESTREMOVEMARGIN         = 3;
    uint256 constant ACTION_REQUESTTRADE                = 4;
    uint256 constant ACTION_REQUESTTRADEANDREMOVEMARGIN = 5;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../../utils/Admin.sol';
import '../../utils/Implementation.sol';
import '../../utils/ReentryLock.sol';

abstract contract GatewayStorage is Admin, Implementation, ReentryLock {

    // stateId => value
    mapping(uint8 => bytes32) internal _gatewayStates;

    // bToken => stateId => value
    mapping(address => mapping(uint8 => bytes32)) internal _bTokenStates;

    // dTokenId => stateId => value
    mapping(uint256 => mapping(uint8 => bytes32)) internal _dTokenStates;

    // actionId => executionFee
    mapping(uint256 => uint256) internal _executionFees;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IGateway {

    struct GatewayParam {
        address lToken;
        address pToken;
        address oracle;
        address swapper;
        address vault0;
        address iou;
        address tokenB0;
        address dChainEventSigner;
        uint256 b0ReserveRatio;
        int256  liquidationRewardCutRatio;
        int256  minLiquidationReward;
        int256  maxLiquidationReward;
        address protocolFeeManager;
        address liqClaim;
    }

    struct GatewayState {
        int256  cumulativePnlOnGateway;
        uint256 liquidityTime;
        uint256 totalLiquidity;
        int256  cumulativeTimePerLiquidity;
        uint256 gatewayRequestId;
        uint256 dChainExecutionFeePerRequest;
        uint256 totalIChainExecutionFee;
        uint256 cumulativeCollectedProtocolFee;
    }

    struct BTokenState {
        address vault;
        bytes32 oracleId;
        uint256 collateralFactor;
    }

    struct LpState {
        uint256 requestId;
        address bToken;
        uint256 bAmount;
        int256  b0Amount;
        int256  lastCumulativePnlOnEngine;
        uint256 liquidity;
        uint256 cumulativeTime;
        uint256 lastCumulativeTimePerLiquidity;
        uint256 lastRequestIChainExecutionFee;
        uint256 cumulativeUnusedIChainExecutionFee;
    }

    struct TdState {
        uint256 requestId;
        address bToken;
        uint256 bAmount;
        int256  b0Amount;
        int256  lastCumulativePnlOnEngine;
        bool    singlePosition;
        uint256 lastRequestIChainExecutionFee;
        uint256 cumulativeUnusedIChainExecutionFee;
    }

    struct VarOnExecuteUpdateLiquidity {
        uint256 requestId;
        uint256 lTokenId;
        uint256 liquidity;
        uint256 totalLiquidity;
        int256  cumulativePnlOnEngine;
        uint256 bAmountToRemove;
    }

    struct VarOnExecuteRemoveMargin {
        uint256 requestId;
        uint256 pTokenId;
        uint256 requiredMargin;
        int256  cumulativePnlOnEngine;
        uint256 bAmountToRemove;
    }

    struct VarOnExecuteLiquidate {
        uint256 requestId;
        uint256 pTokenId;
        int256  cumulativePnlOnEngine;
        int256  maintenanceMarginRequired;
    }

    struct VarOnExecuteCollectProtocolFee {
        uint256 chainId;
        uint256 cumulativeCollectedProtocolFeeOnEngine;
    }

    function getGatewayState() external view returns (GatewayState memory s);

    function getBTokenState(address bToken) external view returns (BTokenState memory s);

    function getLpState(uint256 lTokenId) external view returns (LpState memory s);

    function getTdState(uint256 pTokenId) external view returns (TdState memory s);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ILiqClaim {

    struct Claimable {
        address bToken;
        uint256 amount;
    }

    function getClaimables(address owner) external view returns (Claimable[] memory);

    function getTotalAmount(address bToken) external view returns (uint256);

    function registerDeposit(address owner, address bToken, uint256 amount) external;

    function redeem() external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ISwapper {

    function isSupportedToken(address tokenBX) external view returns (bool);

    function swapExactB0ForBX(address tokenBX, uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactBXForB0(address tokenBX, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapB0ForExactBX(address tokenBX, uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapBXForExactB0(address tokenBX, uint256 amountB0, uint256 maxAmountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactB0ForETH(uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactETHForB0()
    external payable returns (uint256 resultB0, uint256 resultBX);

    function swapB0ForExactETH(uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapETHForExactB0(uint256 amountB0)
    external payable returns (uint256 resultB0, uint256 resultBX);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IDToken is IERC721 {

    function ownerOf(uint256) external view returns (address);

    function totalMinted() external view returns (uint160);

    function mint(address owner) external returns (uint256 tokenId);

    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IIOU is IERC20 {

    function vault() external view returns (address);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IVault {

    function stAmounts(uint256 dTokenId) external view returns (uint256);

    function stTotalAmount() external view returns (uint256);

    function requester() external view returns (address);

    function asset() external view returns (address);

    function getBalance(uint256 dTokenId) external view returns (uint256 balance);

    function deposit(uint256 dTokenId, uint256 amount) external payable returns (uint256 mintedSt);

    function redeem(uint256 dTokenId, uint256 amount) external returns (uint256 redeemedAmount);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library Bytes32 {

    error StringExceeds31Bytes(string value);

    function toUint(bytes32 value) internal pure returns (uint256) {
        return uint256(value);
    }

    function toInt(bytes32 value) internal pure returns (int256) {
        return int256(uint256(value));
    }

    function toAddress(bytes32 value) internal pure returns (address) {
        return address(uint160(uint256(value)));
    }

    function toBool(bytes32 value) internal pure returns (bool) {
        return value != bytes32(0);
    }

    /**
     * @notice Convert a bytes32 value to a string.
     * @dev This function takes an input bytes32 'value' and converts it into a string.
     *      It dynamically determines the length of the string based on non-null characters in 'value'.
     * @param value The input bytes32 value to be converted.
     * @return The string representation of the input bytes32.
     */
    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            if (value[i] == 0) {
                assembly {
                    mstore(bytesArray, i)
                }
                break;
            } else {
                bytesArray[i] = value[i];
            }
        }
        return string(bytesArray);
    }

    function toBytes32(uint256 value) internal pure returns (bytes32) {
        return bytes32(value);
    }

    function toBytes32(int256 value) internal pure returns (bytes32) {
        return bytes32(uint256(value));
    }

    function toBytes32(address value) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(value)));
    }

    function toBytes32(bool value) internal pure returns (bytes32) {
        return bytes32(uint256(value ? 1 : 0));
    }

    /**
     * @notice Convert a string to a bytes32 value.
     * @dev This function takes an input string 'value' and converts it into a bytes32 value.
     *      It enforces a length constraint of 31 characters or less to ensure it fits within a bytes32.
     *      The function uses inline assembly to efficiently copy the string data into the bytes32.
     * @param value The input string to be converted.
     * @return The bytes32 representation of the input string.
     */
    function toBytes32(string memory value) internal pure returns (bytes32) {
        if (bytes(value).length > 31) {
            revert StringExceeds31Bytes(value);
        }
        bytes32 res;
        assembly {
            res := mload(add(value, 0x20))
        }
        return res;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './Bytes32.sol';

library Bytes32Map {

    function getBytes32(mapping(uint8 => bytes32) storage store, uint8 idx) internal view returns (bytes32) {
        return store[idx];
    }

    function getAddress(mapping(uint8 => bytes32) storage store, uint8 idx) internal view returns (address) {
        return Bytes32.toAddress(store[idx]);
    }

    function getUint(mapping(uint8 => bytes32) storage store, uint8 idx) internal view returns (uint256) {
        return Bytes32.toUint(store[idx]);
    }

    function getInt(mapping(uint8 => bytes32) storage store, uint8 idx) internal view returns (int256) {
        return Bytes32.toInt(store[idx]);
    }

    function getBool(mapping(uint8 => bytes32) storage store, uint8 idx) internal view returns (bool) {
        return Bytes32.toBool(store[idx]);
    }

    function getString(mapping(uint8 => bytes32) storage store, uint8 idx) internal view returns (string memory) {
        return Bytes32.toString(store[idx]);
    }


    function set(mapping(uint8 => bytes32) storage store, uint8 idx, bytes32 value) internal {
        store[idx] = value;
    }

    function set(mapping(uint8 => bytes32) storage store, uint8 idx, address value) internal {
        store[idx] = Bytes32.toBytes32(value);
    }

    function set(mapping(uint8 => bytes32) storage store, uint8 idx, uint256 value) internal {
        store[idx] = Bytes32.toBytes32(value);
    }

    function set(mapping(uint8 => bytes32) storage store, uint8 idx, int256 value) internal {
        store[idx] = Bytes32.toBytes32(value);
    }

    function set(mapping(uint8 => bytes32) storage store, uint8 idx, bool value) internal {
        store[idx] = Bytes32.toBytes32(value);
    }

    function set(mapping(uint8 => bytes32) storage store, uint8 idx, string memory value) internal {
        store[idx] = Bytes32.toBytes32(value);
    }

    function del(mapping(uint8 => bytes32) storage store, uint8 idx) internal {
        delete store[idx];
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/// Library for operating ERC20 and ETH in one logic
/// ETH is represented by address: 0x0000000000000000000000000000000000000001

library ETHAndERC20 {

    using SafeERC20 for IERC20;

    error SendEthFail();
    error WrongTokenInAmount();
    error WrongTokenOutAmount();

    function decimals(address token) internal view returns (uint8) {
        return token == address(1) ? 18 : IERC20Metadata(token).decimals();
    }

    // @notice Get the balance of ERC20 tokens or Ether held by this contract
    function balanceOfThis(address token) internal view returns (uint256) {
        return token == address(1)
            ? address(this).balance
            : IERC20(token).balanceOf(address(this));
    }

    function approveMax(address token, address spender) internal {
        if (token != address(1)) {
            uint256 allowance = IERC20(token).allowance(address(this), spender);
            if (allowance != type(uint256).max) {
                if (allowance != 0) {
                    IERC20(token).safeApprove(spender, 0);
                }
                IERC20(token).safeApprove(spender, type(uint256).max);
            }
        }
    }

    function unapprove(address token, address spender) internal {
        if (token != address(1)) {
            uint256 allowance = IERC20(token).allowance(address(this), spender);
            if (allowance != 0) {
                IERC20(token).safeApprove(spender, 0);
            }
        }
    }

    // @notice Transfer ERC20 tokens or Ether from 'from' to this contract
    function transferIn(address token, address from, uint256 amount) internal {
        if (token == address(1)) {
            if (amount != msg.value) {
                revert WrongTokenInAmount();
            }
        } else {
            uint256 balance1 = balanceOfThis(token);
            IERC20(token).safeTransferFrom(from, address(this), amount);
            uint256 balance2 = balanceOfThis(token);
            if (balance2 != balance1 + amount) {
                revert WrongTokenInAmount();
            }
        }
    }

    // @notice Transfer ERC20 tokens or Ether from this contract to 'to'
    function transferOut(address token, address to, uint256 amount) internal {
        uint256 balance1 = balanceOfThis(token);
        if (token == address(1)) {
            (bool success, ) = payable(to).call{value: amount}('');
            if (!success) {
                revert SendEthFail();
            }
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
        uint256 balance2 = balanceOfThis(token);
        if (balance1 != balance2 + amount) {
            revert WrongTokenOutAmount();
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    error UtoIOverflow(uint256);
    error IToUOverflow(int256);
    error AbsOverflow(int256);

    uint256 constant IMAX = 2**255 - 1;
    int256  constant IMIN = -2**255;

    function utoi(uint256 a) internal pure returns (int256) {
        if (a > IMAX) {
            revert UtoIOverflow(a);
        }
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            revert IToUOverflow(a);
        }
        return uint256(a);
    }

    function abs(int256 a) internal pure returns (int256) {
        if (a == IMIN) {
            revert AbsOverflow(a);
        }
        return a >= 0 ? a : -a;
    }

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return a + uint256(b);
        } else {
            return a - uint256(-b);
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

    function divRoundingUp(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a / b;
        if (b * c != a) {
            c += 1;
        }
    }

    // @notice Rescale a uint256 value from a base of 10^decimals1 to 10^decimals2
    function rescale(uint256 value, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return decimals1 == decimals2 ? value : value * 10**decimals2 / 10**decimals1;
    }

    // @notice Rescale value with rounding down
    function rescaleDown(uint256 value, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return rescale(value, decimals1, decimals2);
    }

    // @notice Rescale value with rounding up
    function rescaleUp(uint256 value, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        uint256 rescaled = rescale(value, decimals1, decimals2);
        if (rescale(rescaled, decimals2, decimals1) != value) {
            rescaled += 1;
        }
        return rescaled;
    }

    function rescale(int256 value, uint256 decimals1, uint256 decimals2) internal pure returns (int256) {
        return decimals1 == decimals2 ? value : value * int256(10**decimals2) / int256(10**decimals1);
    }

    function rescaleDown(int256 value, uint256 decimals1, uint256 decimals2) internal pure returns (int256) {
        int256 rescaled = rescale(value, decimals1, decimals2);
        if (value < 0 && rescale(rescaled, decimals2, decimals1) != value) {
            rescaled -= 1;
        }
        return rescaled;
    }

    function rescaleUp(int256 value, uint256 decimals1, uint256 decimals2) internal pure returns (int256) {
        int256 rescaled = rescale(value, decimals1, decimals2);
        if (value > 0 && rescale(rescaled, decimals2, decimals1) != value) {
            rescaled += 1;
        }
        return rescaled;
    }

    // @notice Calculate a + b with overflow allowed
    function addUnchecked(int256 a, int256 b) internal pure returns (int256 c) {
        unchecked { c = a + b; }
    }

    // @notice Calculate a - b with overflow allowed
    function minusUnchecked(int256 a, int256 b) internal pure returns (int256 c) {
        unchecked { c = a - b; }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/IAdmin.sol';
import '../utils/IImplementation.sol';

interface IOracle is IAdmin, IImplementation {

    struct Signature {
        bytes32 oracleId;
        uint256 timestamp;
        int256  value;
        uint8   v;
        bytes32 r;
        bytes32 s;
    }

    function getValue(bytes32 oracleId) external view returns (int256);

    function getValueCurrentBlock(bytes32 oracleId) external view returns (int256);

    function updateOffchainValue(Signature memory s) external;

    function updateOffchainValues(Signature[] memory ss) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

abstract contract Admin {

    error OnlyAdmin();

    event NewAdmin(address newAdmin);

    address public admin;

    modifier _onlyAdmin_() {
        if (msg.sender != admin) {
            revert OnlyAdmin();
        }
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    /**
     * @notice Set a new admin for the contract.
     * @dev This function allows the current admin to assign a new admin address without performing any explicit verification.
     *      It's the current admin's responsibility to ensure that the 'newAdmin' address is correct and secure.
     * @param newAdmin The address of the new admin.
     */
    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IImplementation {

    function setImplementation(address newImplementation) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './Admin.sol';

abstract contract Implementation is Admin {

    event NewImplementation(address newImplementation);

    address public implementation;

    // @notice Set a new implementation address for the contract
    function setImplementation(address newImplementation) external _onlyAdmin_ {
        implementation = newImplementation;
        emit NewImplementation(newImplementation);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

abstract contract ReentryLock {

    error Reentry();

    bool internal _mutex;

    // @notice Lock for preventing reentrancy attacks
    modifier _reentryLock_() {
        if (_mutex) {
            revert Reentry();
        }
        _mutex = true;
        _;
        _mutex = false;
    }

}