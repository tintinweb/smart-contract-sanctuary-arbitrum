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

interface IAdmin {

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IImplementation {

    function setImplementation(address newImplementation) external;

}