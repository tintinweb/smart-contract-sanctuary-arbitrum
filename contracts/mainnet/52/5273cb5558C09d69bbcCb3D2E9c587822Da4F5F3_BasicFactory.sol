// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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
pragma solidity 0.8.20;

interface IMarketConfig {
    function burnFee() external view returns (uint256);

    function config()
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    function fees() external view returns (uint256, uint256, uint256, uint256);

    function periods() external view returns (uint256, uint256);

    function disputePeriod() external view returns (uint256);

    function disputePrice() external view returns (uint256);

    function feesSum() external view returns (uint256);

    function foundationFee() external view returns (uint256);

    function marketCreatorFee() external view returns (uint256);

    function verificationFee() external view returns (uint256);

    function verificationPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IProtocolConfig {
    function marketConfig() external view returns (address);

    function foreToken() external view returns (address);

    function foreVerifiers() external view returns (address);

    function foundationWallet() external view returns (address);

    function highGuard() external view returns (address);

    function marketplace() external view returns (address);

    function owner() external view returns (address);

    function getTier(
        uint256 tierIndex
    ) external view returns (uint256, uint256);

    function getTierMultiplier(
        uint256 tierIndex
    ) external view returns (uint256);

    function renounceOwnership() external;

    function revenueWallet() external view returns (address);

    function verifierMintPrice() external view returns (uint256);

    function marketCreationPrice() external view returns (uint256);

    function addresses()
        external
        view
        returns (address, address, address, address, address, address, address);

    function roleAddresses() external view returns (address, address, address);

    function isFactoryWhitelisted(address adr) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IForeProtocol is IERC721 {
    function allMarketLength() external view returns (uint256);

    function allMarkets(uint256) external view returns (address);

    function burn(uint256 tokenId) external;

    function buyPower(uint256 id, uint256 amount) external;

    function config() external view returns (address);

    function market(bytes32 mHash) external view returns (address);

    function createMarket(
        bytes32 marketHash,
        address creator,
        address receiver,
        address marketAddress
    ) external returns (uint256);

    function foreToken() external view returns (address);

    function foreVerifiers() external view returns (address);

    function isForeMarket(address market) external view returns (bool);

    function isForeOperator(address addr) external view returns (bool);

    function mintVerifier(address receiver) external;

    event MarketCreated(
        address indexed factory,
        address indexed creator,
        bytes32 marketHash,
        address market,
        uint256 marketIdx
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./BasicMarket.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../verifiers/IForeVerifiers.sol";
import "../../config/IProtocolConfig.sol";

contract BasicFactory {
    using SafeERC20 for IERC20;

    /// @notice Init creatin code
    /// @dev Needed to calculate market address
    bytes32 public constant INIT_CODE_PAIR_HASH =
        keccak256(abi.encodePacked(type(BasicMarket).creationCode));

    /// @notice Protocol Contract
    IForeProtocol public immutable foreProtocol;

    /// @notice ForeToken
    IERC20 public immutable foreToken;

    /// @notice Protocol Config
    IProtocolConfig public immutable config;

    /// @notice ForeVerifiers
    IForeVerifiers public immutable foreVerifiers;

    /// @param protocolAddress Protocol Contract address
    constructor(IForeProtocol protocolAddress) {
        foreProtocol = protocolAddress;
        config = IProtocolConfig(protocolAddress.config());
        foreToken = IERC20(protocolAddress.foreToken());
        foreVerifiers = IForeVerifiers(protocolAddress.foreVerifiers());
    }

    /// @notice Creates Market
    /// @param marketHash market hash
    /// @param receiver market creator nft receiver
    /// @param amountA initial prediction for side A
    /// @param amountB initial prediction for side B
    /// @param endPredictionTimestamp End predictions unix timestamp
    /// @param startVerificationTimestamp Start Verification unix timestamp
    /// @return createdMarket Address of created market
    function createMarket(
        bytes32 marketHash,
        address receiver,
        uint256 amountA,
        uint256 amountB,
        uint64 endPredictionTimestamp,
        uint64 startVerificationTimestamp
    ) external returns (address createdMarket) {
        if (endPredictionTimestamp > startVerificationTimestamp) {
            revert("BasicFactory: Date error");
        }

        BasicMarket createdMarketContract = new BasicMarket{salt: marketHash}();

        createdMarket = address(createdMarketContract);

        uint256 creationFee = config.marketCreationPrice();
        if (creationFee != 0) {
            foreToken.safeTransferFrom(
                msg.sender,
                address(0x000000000000000000000000000000000000dEaD),
                creationFee
            );
        }

        uint256 amountSum = amountA + amountB;
        if (amountSum != 0) {
            foreToken.safeTransferFrom(msg.sender, createdMarket, amountSum);
        }

        uint256 marketIdx = foreProtocol.createMarket(
            marketHash,
            msg.sender,
            receiver,
            createdMarket
        );

        createdMarketContract.initialize(
            marketHash,
            receiver,
            amountA,
            amountB,
            address(foreProtocol),
            endPredictionTimestamp,
            startVerificationTimestamp,
            uint64(marketIdx)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../IForeProtocol.sol";
import "../../../verifiers/IForeVerifiers.sol";
import "../../config/IProtocolConfig.sol";
import "../../config/IMarketConfig.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./library/MarketLib.sol";

contract BasicMarket is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Market hash (ipfs hash without first 2 bytes)
    bytes32 public marketHash;

    /// @notice Market token id
    uint256 public marketId;

    /// @notice Protocol
    IForeProtocol public protocol;

    /// @notice Factory
    address public immutable factory;

    /// @notice Protocol config
    IProtocolConfig public protocolConfig;

    /// @notice Market config
    IMarketConfig public marketConfig;

    /// @notice Verifiers NFT
    IForeVerifiers public foreVerifiers;

    /// @notice Fore Token
    IERC20 public foreToken;

    /// @notice Market info
    MarketLib.Market internal _market;

    /// @notice Positive result predictions amount of address
    mapping(address => uint256) public predictionsA;

    /// @notice Negative result predictions amount of address
    mapping(address => uint256) public predictionsB;

    /// @notice Is prediction reward withdrawn for address
    mapping(address => bool) public predictionWithdrawn;

    /// @notice Verification info for verificatioon id
    MarketLib.Verification[] public verifications;

    bytes32 public disputeMessage;

    ///EVENTS
    event MarketInitialized(uint256 marketId);
    event OpenDispute(address indexed creator);
    event CloseMarket(MarketLib.ResultType result);
    event Verify(
        address indexed verifier,
        uint256 power,
        uint256 verificationId,
        uint256 indexed tokenId,
        bool side
    );
    event WithdrawReward(
        address indexed receiver,
        uint256 indexed rewardType,
        uint256 amount
    );
    event Predict(address indexed sender, bool side, uint256 amount);

    /// @notice Verification array size
    function verificationHeight() external view returns (uint256) {
        return verifications.length;
    }

    constructor() {
        factory = msg.sender;
    }

    /// @notice Returns market info
    function marketInfo() external view returns (MarketLib.Market memory) {
        return _market;
    }

    /// @notice Initialization function
    /// @param mHash _market hash
    /// @param receiver _market creator nft receiver
    /// @param amountA initial prediction for side A
    /// @param amountB initial prediction for side B
    /// @param endPredictionTimestamp End Prediction Timestamp
    /// @param startVerificationTimestamp Start Verification Timestamp
    /// @param tokenId _market creator token id (ForeMarkets)
    /// @dev Possible to call only via the factory
    function initialize(
        bytes32 mHash,
        address receiver,
        uint256 amountA,
        uint256 amountB,
        address protocolAddress,
        uint64 endPredictionTimestamp,
        uint64 startVerificationTimestamp,
        uint64 tokenId
    ) external {
        if (msg.sender != address(factory)) {
            revert("BasicMarket: Only Factory");
        }

        protocol = IForeProtocol(protocolAddress);
        protocolConfig = IProtocolConfig(protocol.config());
        marketConfig = IMarketConfig(protocolConfig.marketConfig());
        foreToken = IERC20(protocol.foreToken());
        foreVerifiers = IForeVerifiers(protocol.foreVerifiers());

        marketHash = mHash;
        MarketLib.init(
            _market,
            predictionsA,
            predictionsB,
            receiver,
            amountA,
            amountB,
            endPredictionTimestamp,
            startVerificationTimestamp,
            tokenId
        );
        marketId = tokenId;
    }

    /// @notice Add new prediction
    /// @param amount Amount of ForeToken
    /// @param side Predicition side (true - positive result, false - negative result)
    function predict(uint256 amount, bool side) external {
        foreToken.safeTransferFrom(msg.sender, address(this), amount);
        MarketLib.predict(
            _market,
            predictionsA,
            predictionsB,
            amount,
            side,
            msg.sender
        );
    }

    ///@notice Doing new verification
    ///@param tokenId vNFT token id
    ///@param side side of verification
    function verify(uint256 tokenId, bool side) external nonReentrant {
        if (foreVerifiers.ownerOf(tokenId) != msg.sender) {
            revert("BasicMarket: Incorrect owner");
        }

        MarketLib.Market memory m = _market;

        if (
            (m.sideA == 0 || m.sideB == 0) &&
            m.endPredictionTimestamp < block.timestamp
        ) {
            _closeMarket(MarketLib.ResultType.INVALID);
            return;
        }

        (, uint256 verificationPeriod) = marketConfig.periods();

        foreVerifiers.transferFrom(msg.sender, address(this), tokenId);

        uint256 multipliedPower = foreVerifiers.multipliedPowerOf(tokenId);

        MarketLib.verify(
            _market,
            verifications,
            msg.sender,
            verificationPeriod,
            multipliedPower,
            tokenId,
            side
        );
    }

    /// @notice Opens dispute
    function openDispute(bytes32 messageHash) external {
        MarketLib.Market memory m = _market;
        (
            uint256 disputePrice,
            uint256 disputePeriod,
            uint256 verificationPeriod,
            ,
            ,
            ,

        ) = marketConfig.config();
        if (
            MarketLib.calculateMarketResult(m) ==
            MarketLib.ResultType.INVALID &&
            (m.startVerificationTimestamp + verificationPeriod <
                block.timestamp)
        ) {
            _closeMarket(MarketLib.ResultType.INVALID);
            return;
        }
        foreToken.safeTransferFrom(msg.sender, address(this), disputePrice);
        disputeMessage = messageHash;
        MarketLib.openDispute(
            _market,
            disputePeriod,
            verificationPeriod,
            msg.sender
        );
    }

    ///@notice Resolves Dispute
    ///@param result Dipsute result type
    ///@dev Only HighGuard
    function resolveDispute(MarketLib.ResultType result) external {
        address highGuard = protocolConfig.highGuard();
        address receiver = MarketLib.resolveDispute(
            _market,
            result,
            highGuard,
            msg.sender
        );
        foreToken.safeTransfer(receiver, marketConfig.disputePrice());
        _closeMarket(result);
    }

    ///@dev Closes market
    ///@param result Market close result type
    ///Is not best optimized becouse of deep stack
    function _closeMarket(MarketLib.ResultType result) private {
        (
            uint256 burnFee,
            uint256 foundationFee,
            ,
            uint256 verificationFee
        ) = marketConfig.fees();
        (
            uint256 toBurn,
            uint256 toFoundation,
            uint256 toHighGuard,
            uint256 toDisputeCreator,
            address disputeCreator
        ) = MarketLib.closeMarket(
                _market,
                burnFee,
                verificationFee,
                foundationFee,
                result
            );

        if (result != MarketLib.ResultType.INVALID) {
            MarketLib.Market memory m = _market;
            uint256 verificatorsFees = ((m.sideA + m.sideB) * verificationFee) /
                10000;
            if (
                ((m.verifiedA == 0) && (result == MarketLib.ResultType.AWON)) ||
                ((m.verifiedB == 0) && (result == MarketLib.ResultType.BWON))
            ) {
                toBurn += verificatorsFees;
            }
            if (toBurn != 0) {
                foreToken.safeTransfer(
                    address(0x000000000000000000000000000000000000dEaD),
                    toBurn
                );
            }
            if (toFoundation != 0) {
                foreToken.safeTransfer(
                    protocolConfig.foundationWallet(),
                    toFoundation
                );
            }
            if (toHighGuard != 0) {
                foreToken.safeTransfer(protocolConfig.highGuard(), toHighGuard);
            }
            if (toDisputeCreator != 0) {
                foreToken.safeTransfer(disputeCreator, toDisputeCreator);
            }
        }
    }

    ///@notice Closes _market
    function closeMarket() external {
        MarketLib.Market memory m = _market;
        (uint256 disputePeriod, uint256 verificationPeriod) = marketConfig
            .periods();
        bool isInvalid = MarketLib.beforeClosingCheck(
            m,
            verificationPeriod,
            disputePeriod
        );
        if (isInvalid) {
            _closeMarket(MarketLib.ResultType.INVALID);
            return;
        }
        _closeMarket(MarketLib.calculateMarketResult(m));
    }

    ///@notice Returns prediction reward in ForeToken
    ///@dev Returns full available amount to withdraw(Deposited fund + reward of winnings - Protocol fees)
    ///@param predictor Predictior address
    ///@return 0 Amount to withdraw
    function calculatePredictionReward(
        address predictor
    ) external view returns (uint256) {
        if (predictionWithdrawn[predictor]) return (0);
        MarketLib.Market memory m = _market;
        return (
            MarketLib.calculatePredictionReward(
                m,
                predictionsA[predictor],
                predictionsB[predictor],
                marketConfig.feesSum()
            )
        );
    }

    ///@notice Withdraw prediction rewards
    ///@dev predictor Predictor Address
    ///@param predictor Predictor address
    function withdrawPredictionReward(address predictor) external {
        MarketLib.Market memory m = _market;
        uint256 toWithdraw = MarketLib.withdrawPredictionReward(
            m,
            marketConfig.feesSum(),
            predictionWithdrawn,
            predictionsA[predictor],
            predictionsB[predictor],
            predictor
        );
        uint256 ownBalance = foreToken.balanceOf(address(this));
        if (toWithdraw > ownBalance) {
            toWithdraw = ownBalance;
        }
        foreToken.safeTransfer(predictor, toWithdraw);
    }

    ///@notice Calculates Verification Reward
    ///@param verificationId Id of Verification
    function calculateVerificationReward(
        uint256 verificationId
    )
        external
        view
        returns (
            uint256 toVerifier,
            uint256 toDisputeCreator,
            uint256 toHighGuard,
            bool vNftBurn
        )
    {
        MarketLib.Market memory m = _market;
        MarketLib.Verification memory v = verifications[verificationId];
        uint256 power = foreVerifiers.powerOf(
            verifications[verificationId].tokenId
        );
        (toVerifier, toDisputeCreator, toHighGuard, vNftBurn) = MarketLib
            .calculateVerificationReward(
                m,
                v,
                power,
                marketConfig.verificationFee()
            );
    }

    ///@notice Withdrawss Verification Reward
    ///@param verificationId Id of verification
    ///@param withdrawAsTokens If true witdraws tokens, false - withraws power
    function withdrawVerificationReward(
        uint256 verificationId,
        bool withdrawAsTokens
    ) external nonReentrant {
        MarketLib.Market memory m = _market;
        MarketLib.Verification memory v = verifications[verificationId];

        require(
            msg.sender == v.verifier ||
                msg.sender == protocolConfig.highGuard(),
            "BasicMarket: Only Verifier or HighGuard"
        );

        uint256 power = foreVerifiers.powerOf(
            verifications[verificationId].tokenId
        );
        (
            uint256 toVerifier,
            uint256 toDisputeCreator,
            uint256 toHighGuard,
            bool vNftBurn
        ) = MarketLib.withdrawVerificationReward(
                m,
                v,
                power,
                marketConfig.verificationFee()
            );
        verifications[verificationId].withdrawn = true;
        if (toVerifier != 0) {
            uint256 ownBalance = foreToken.balanceOf(address(this));
            if (toVerifier > ownBalance) {
                toVerifier = ownBalance;
            }
            if (withdrawAsTokens) {
                foreToken.safeTransfer(v.verifier, toVerifier);
                foreVerifiers.increaseValidation(v.tokenId);
            } else {
                foreVerifiers.increasePower(v.tokenId, toVerifier, true);
                foreToken.safeTransfer(address(foreVerifiers), toVerifier);
            }
        }
        if (toDisputeCreator != 0) {
            foreVerifiers.marketTransfer(m.disputeCreator, toDisputeCreator);
            foreVerifiers.marketTransfer(
                protocolConfig.highGuard(),
                toHighGuard
            );
        }

        if (vNftBurn) {
            foreVerifiers.marketBurn(power - toDisputeCreator - toHighGuard);
            foreVerifiers.burn(v.tokenId);
        } else {
            foreVerifiers.transferFrom(address(this), v.verifier, v.tokenId);
        }
    }

    ///@notice Withdraw Market Creators Reward
    function marketCreatorFeeWithdraw() external {
        MarketLib.Market memory m = _market;
        uint256 tokenId = marketId;

        require(
            protocol.ownerOf(tokenId) == msg.sender,
            "BasicMarket: Only Market Creator"
        );

        if (m.result == MarketLib.ResultType.NULL) {
            revert("MarketIsNotClosedYet");
        }

        if (m.result == MarketLib.ResultType.INVALID) {
            revert("OnlyForValidMarkets");
        }

        protocol.burn(tokenId);

        uint256 toWithdraw = ((m.sideA + m.sideB) *
            marketConfig.marketCreatorFee()) / 10000;
        uint256 ownBalance = foreToken.balanceOf(address(this));
        if (toWithdraw > ownBalance) {
            toWithdraw = ownBalance;
        }
        foreToken.safeTransfer(msg.sender, toWithdraw);

        emit WithdrawReward(msg.sender, 3, toWithdraw);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library MarketLib {
    ///EVENTS
    event MarketInitialized(uint256 marketId);
    event OpenDispute(address indexed creator);
    event CloseMarket(MarketLib.ResultType result);
    event Verify(
        address indexed verifier,
        uint256 power,
        uint256 verificationId,
        uint256 indexed tokenId,
        bool side
    );
    event WithdrawReward(
        address indexed receiver,
        uint256 indexed rewardType,
        uint256 amount
    );
    event Predict(address indexed sender, bool side, uint256 amount);

    //STRUCTS
    /// @notice Market closing types
    enum ResultType {
        NULL,
        AWON,
        BWON,
        DRAW,
        INVALID
    }

    struct Verification {
        /// @notice Address of verifier
        address verifier;
        /// @notice Verficaton power
        uint256 power;
        /// @notice Token id used for verification
        uint256 tokenId;
        /// @notice Verification side (true - positive / false - negative)
        bool side;
        /// @notice Is reward + staked token withdrawn
        bool withdrawn;
    }

    struct Market {
        /// @notice Predctioons token pool for positive result
        uint256 sideA;
        /// @notice Predictions token pool for negative result
        uint256 sideB;
        /// @notice Verification power for positive result
        uint256 verifiedA;
        /// @notice Verification power for positive result
        uint256 verifiedB;
        /// @notice Dispute Creator address
        address disputeCreator;
        /// @notice End predictions unix timestamp
        uint64 endPredictionTimestamp;
        /// @notice Start verifications unix timestamp
        uint64 startVerificationTimestamp;
        /// @notice Market result
        ResultType result;
        /// @notice Wrong result confirmed by HG
        bool confirmed;
        /// @notice Dispute solved by HG
        bool solved;
    }

    uint256 constant DIVIDER = 10000;

    /// FUNCTIONS
    /// @dev Checks if one side of the market verifies more than the total market size
    /// @param m Market info
    /// @return 0 true if verified
    function _isVerified(Market memory m) internal pure returns (bool) {
        uint256 totalMarketSize = m.sideA + m.sideB;
        return
            totalMarketSize > 0 &&
            ((totalMarketSize <= m.verifiedB) ||
                (totalMarketSize <= m.verifiedA));
    }

    /// @notice Checks if one side of the market is fully verified
    /// @param m Market info
    /// @return 0 true if verified
    function isVerified(Market memory m) external pure returns (bool) {
        return _isVerified(m);
    }

    /// @notice Returns the maximum value(power) available for verification for side
    /// @param m Market info
    /// @param side Side of market (true/false)
    /// @return 0 Maximum amount to verify for side
    function maxAmountToVerifyForSide(
        Market memory m,
        bool side
    ) external pure returns (uint256) {
        return (_maxAmountToVerifyForSide(m, side));
    }

    /// @dev Returns the maximum value(power) available for verification for side
    /// @param m Market info
    /// @param side Side of market (true/false)
    /// @return 0 Maximum amount to verify for side
    function _maxAmountToVerifyForSide(
        Market memory m,
        bool side
    ) internal pure returns (uint256) {
        if (_isVerified(m)) {
            return 0;
        }
        uint256 totalMarketSize = m.sideA + m.sideB;
        if (side) {
            return totalMarketSize - m.verifiedA;
        } else {
            return totalMarketSize - m.verifiedB;
        }
    }

    ///@dev Returns prediction reward in ForeToken
    ///@param m Market Info
    ///@param pA Prediction contribution for side A
    ///@param pB Prediction contribution for side B
    ///@param feesSum Sum of all fees im perc
    ///@return toWithdraw amount to withdraw
    function calculatePredictionReward(
        Market memory m,
        uint256 pA,
        uint256 pB,
        uint256 feesSum
    ) internal pure returns (uint256 toWithdraw) {
        if (m.result == ResultType.INVALID) {
            return pA + pB;
        }
        uint256 fullMarketSize = m.sideA + m.sideB;
        uint256 _marketSubFee = fullMarketSize -
            (fullMarketSize * feesSum) /
            DIVIDER;
        if (m.result == MarketLib.ResultType.DRAW) {
            toWithdraw = (_marketSubFee * (pA + pB)) / fullMarketSize;
        } else if (m.result == MarketLib.ResultType.AWON) {
            toWithdraw = (_marketSubFee * pA) / m.sideA;
        } else if (m.result == MarketLib.ResultType.BWON) {
            toWithdraw = (_marketSubFee * pB) / m.sideB;
        }
    }

    ///@notice Calculates Result for market
    ///@param m Market Info
    ///@return 0 Type of result
    function calculateMarketResult(
        Market memory m
    ) external pure returns (ResultType) {
        return _calculateMarketResult(m);
    }

    ///@dev Calculates Result for market
    ///@param m Market Info
    ///@return 0 Type of result
    function _calculateMarketResult(
        Market memory m
    ) internal pure returns (ResultType) {
        if (
            m.sideA == 0 ||
            m.sideB == 0 ||
            (m.verifiedA == 0 && m.verifiedB == 0)
        ) {
            return ResultType.INVALID;
        } else if (m.verifiedA == m.verifiedB) {
            return ResultType.DRAW;
        } else if (m.verifiedA > m.verifiedB) {
            return ResultType.AWON;
        } else {
            return ResultType.BWON;
        }
    }

    /// @notice initiates market
    /// @param market Market storage
    /// @param predictionsA Storage of predictionsA
    /// @param predictionsB Storage of predictionsB
    /// @param receiver Init prediction(s) creator
    /// @param amountA Init size of side A
    /// @param amountB Init size of side B
    /// @param endPredictionTimestamp End Prediction Unix Timestamp
    /// @param startVerificationTimestamp Start Verification Unix Timestamp
    /// @param tokenId mNFT token id
    function init(
        Market storage market,
        mapping(address => uint256) storage predictionsA,
        mapping(address => uint256) storage predictionsB,
        address receiver,
        uint256 amountA,
        uint256 amountB,
        uint64 endPredictionTimestamp,
        uint64 startVerificationTimestamp,
        uint256 tokenId
    ) external {
        market.endPredictionTimestamp = endPredictionTimestamp;
        market.startVerificationTimestamp = startVerificationTimestamp;
        if (amountA != 0) {
            _predict(
                market,
                predictionsA,
                predictionsB,
                amountA,
                true,
                receiver
            );
        }
        if (amountB != 0) {
            _predict(
                market,
                predictionsA,
                predictionsB,
                amountB,
                false,
                receiver
            );
        }

        emit MarketInitialized(tokenId);
    }

    /// @notice Add new prediction
    /// @param market Market storage
    /// @param predictionsA Storage of predictionsA
    /// @param predictionsB Storage of predictionsB
    /// @param amount Amount of ForeToken
    /// @param side Predicition side (true - positive result, false - negative result)
    /// @param receiver Prediction creator
    function predict(
        Market storage market,
        mapping(address => uint256) storage predictionsA,
        mapping(address => uint256) storage predictionsB,
        uint256 amount,
        bool side,
        address receiver
    ) external {
        _predict(market, predictionsA, predictionsB, amount, side, receiver);
    }

    /// @dev Add new prediction
    /// @param market Market storage
    /// @param predictionsA Storage of predictionsA
    /// @param predictionsB Storage of predictionsB
    /// @param amount Amount of ForeToken
    /// @param side Predicition side (true - positive result, false - negative result)
    /// @param receiver Prediction creator
    function _predict(
        Market storage market,
        mapping(address => uint256) storage predictionsA,
        mapping(address => uint256) storage predictionsB,
        uint256 amount,
        bool side,
        address receiver
    ) internal {
        if (amount == 0) {
            revert("AmountCantBeZero");
        }

        if (block.timestamp >= market.endPredictionTimestamp) {
            revert("PredictionPeriodIsAlreadyClosed");
        }

        if (side) {
            market.sideA += amount;
            predictionsA[receiver] += amount;
        } else {
            market.sideB += amount;
            predictionsB[receiver] += amount;
        }

        emit Predict(receiver, side, amount);
    }

    /// @dev Verifies the side with maximum available power
    /// @param market Market storage
    /// @param verifications Verifications array storage
    /// @param verifier Verification creator
    /// @param verificationPeriod Verification Period is sec
    /// @param power Power of vNFT
    /// @param tokenId vNFT token id
    /// @param side Marketd side (true - positive / false - negative);
    function _verify(
        Market storage market,
        Verification[] storage verifications,
        address verifier,
        uint256 verificationPeriod,
        uint256 power,
        uint256 tokenId,
        bool side
    ) internal {
        MarketLib.Market memory m = market;
        if (block.timestamp < m.startVerificationTimestamp) {
            revert("VerificationHasNotStartedYet");
        }
        uint256 verificationEndTime = m.startVerificationTimestamp +
            verificationPeriod;
        if (block.timestamp > verificationEndTime) {
            revert("VerificationAlreadyClosed");
        }

        if (side) {
            market.verifiedA += power;
        } else {
            market.verifiedB += power;
        }

        uint256 verifyId = verifications.length;

        verifications.push(Verification(verifier, power, tokenId, side, false));

        emit Verify(verifier, power, verifyId, tokenId, side);
    }

    /// @notice Verifies the side with maximum available power
    /// @param market Market storage
    /// @param verifications Verifications array storage
    /// @param verifier Verification creator
    /// @param verificationPeriod Verification Period is sec
    /// @param power Power of vNFT
    /// @param tokenId vNFT token id
    /// @param side Marketd side (true - positive / false - negative);
    function verify(
        Market storage market,
        Verification[] storage verifications,
        address verifier,
        uint256 verificationPeriod,
        uint256 power,
        uint256 tokenId,
        bool side
    ) external {
        MarketLib.Market memory m = market;
        uint256 powerAvailable = _maxAmountToVerifyForSide(m, side);
        if (powerAvailable == 0) {
            revert("MarketIsFullyVerified");
        }
        if (power > powerAvailable) {
            power = powerAvailable;
        }
        _verify(
            market,
            verifications,
            verifier,
            verificationPeriod,
            power,
            tokenId,
            side
        );
    }

    /// @notice Opens a dispute
    /// @param market Market storage
    /// @param disputePeriod Dispute period in seconds
    /// @param verificationPeriod Verification Period in seconds
    /// @param creator Dispute creator
    function openDispute(
        Market storage market,
        uint256 disputePeriod,
        uint256 verificationPeriod,
        address creator
    ) external {
        Market memory m = market;

        bool isDisputeStarted = ((block.timestamp >=
            m.startVerificationTimestamp + verificationPeriod) ||
            _isVerified(m));

        if (!isDisputeStarted) {
            revert("DisputePeriodIsNotStartedYet");
        }

        if (m.result == ResultType.INVALID) {
            revert("MarketClosedWithInvalidStatus");
        }

        if (
            block.timestamp >=
            m.startVerificationTimestamp + verificationPeriod + disputePeriod
        ) {
            revert("DisputePeriodIsEnded");
        }

        if (m.disputeCreator != address(0)) {
            revert("DisputeAlreadyExists");
        }

        market.disputeCreator = creator;
        emit OpenDispute(creator);
    }

    /// @notice Resolves a dispute
    /// @param market Market storage
    /// @param result Result type
    /// @param highGuard High Guard address
    /// @param requester Function rerquester address
    /// @return receiverAddress Address receives dispute creration tokens
    function resolveDispute(
        Market storage market,
        MarketLib.ResultType result,
        address highGuard,
        address requester
    ) external returns (address receiverAddress) {
        if (highGuard != requester) {
            revert("HighGuardOnly");
        }
        if (result == MarketLib.ResultType.NULL) {
            revert("ResultCantBeNull");
        }
        if (result == MarketLib.ResultType.INVALID) {
            revert("ResultCantBeInvalid");
        }
        MarketLib.Market memory m = market;
        if (m.disputeCreator == address(0)) {
            revert("DisputePeriodIsNotStartedYet");
        }

        if (m.solved) {
            revert("DisputeAlreadySolved");
        }

        market.solved = true;

        if (_calculateMarketResult(m) != result) {
            market.confirmed = true;
            return (m.disputeCreator);
        } else {
            return (requester);
        }
    }

    /// @notice Resolves a dispute
    /// @param market Market storage
    /// @param burnFee Burn fee
    /// @param verificationFee Verification Fee
    /// @param foundationFee Foundation Fee
    /// @param result Result type
    /// @return toBurn Token to burn
    /// @return toFoundation Token to foundation
    /// @return toHighGuard Token to HG
    /// @return toDisputeCreator Token to dispute creator
    /// @return disputeCreator Dispute creator address
    function closeMarket(
        Market storage market,
        uint256 burnFee,
        uint256 verificationFee,
        uint256 foundationFee,
        MarketLib.ResultType result
    )
        external
        returns (
            uint256 toBurn,
            uint256 toFoundation,
            uint256 toHighGuard,
            uint256 toDisputeCreator,
            address disputeCreator
        )
    {
        Market memory m = market;
        if (m.result != ResultType.NULL) {
            revert("MarketIsClosed");
        }
        market.result = result;
        m.result = result;
        emit CloseMarket(m.result);

        if (m.result == MarketLib.ResultType.INVALID) {
            return (0, 0, 0, 0, m.disputeCreator);
        }

        uint256 fullMarketSize = m.sideA + m.sideB;
        toBurn = (fullMarketSize * burnFee) / DIVIDER;
        uint256 toVerifiers = (fullMarketSize * verificationFee) / DIVIDER;
        toFoundation = (fullMarketSize * foundationFee) / DIVIDER;

        if (
            m.result == MarketLib.ResultType.DRAW &&
            m.disputeCreator != address(0) &&
            !m.confirmed
        ) {
            // draw with dispute rejected - result set to draw
            toBurn += toVerifiers / 2;
            toHighGuard = toVerifiers / 2;
        } else if (m.result == MarketLib.ResultType.DRAW && m.confirmed) {
            // dispute confirmed - result set to draw
            toHighGuard = toVerifiers / 2;
            toDisputeCreator = toVerifiers - toHighGuard;
            disputeCreator = m.disputeCreator;
        } else if (
            m.result == MarketLib.ResultType.DRAW &&
            m.disputeCreator == address(0)
        ) {
            // draw with no dispute
            toBurn += toVerifiers;
        }
    }

    /// @notice Check market status before closing
    /// @param m Market info
    /// @param verificationPeriod Verification Period
    /// @param disputePeriod Dispute Period
    /// @return Is invalid market
    function beforeClosingCheck(
        Market memory m,
        uint256 verificationPeriod,
        uint256 disputePeriod
    ) external view returns (bool) {
        if (
            (m.sideA == 0 || m.sideB == 0) &&
            block.timestamp > m.endPredictionTimestamp
        ) {
            return true;
        }

        uint256 verificationPeriodEnds = m.startVerificationTimestamp +
            verificationPeriod;
        if (
            block.timestamp > verificationPeriodEnds &&
            m.verifiedA == 0 &&
            m.verifiedB == 0
        ) {
            return true;
        }

        if (m.disputeCreator != address(0)) {
            revert("DisputeNotSolvedYet");
        }

        uint256 disputePeriodEnds = m.startVerificationTimestamp +
            verificationPeriod +
            disputePeriod;
        if (block.timestamp < disputePeriodEnds) {
            revert("DisputePeriodIsNotEndedYet");
        }

        return false;
    }

    /// @notice Withdraws Prediction Reward
    /// @param m Market info
    /// @param feesSum Sum of all fees
    /// @param predictionWithdrawn Storage of withdraw statuses
    /// @param predictionsA PredictionsA of predictor
    /// @param predictionsB PredictionsB of predictor
    /// @param predictor Predictor address
    /// @return 0 Amount to withdraw(transfer)
    function withdrawPredictionReward(
        Market memory m,
        uint256 feesSum,
        mapping(address => bool) storage predictionWithdrawn,
        uint256 predictionsA,
        uint256 predictionsB,
        address predictor
    ) external returns (uint256) {
        if (m.result == MarketLib.ResultType.NULL) {
            revert("MarketIsNotClosedYet");
        }
        if (predictionWithdrawn[predictor]) {
            revert("AlreadyWithdrawn");
        }

        predictionWithdrawn[predictor] = true;

        uint256 toWithdraw = calculatePredictionReward(
            m,
            predictionsA,
            predictionsB,
            feesSum
        );
        if (toWithdraw == 0) {
            revert("NothingToWithdraw");
        }

        emit WithdrawReward(predictor, 1, toWithdraw);

        return toWithdraw;
    }

    /// @notice Calculates Verification Reward
    /// @param m Market info
    /// @param v Verification info
    /// @param power Power of vNFT used for verification
    /// @param verificationFee Verification Fee
    /// @return toVerifier Amount of tokens for verifier
    /// @return toDisputeCreator Amount of tokens for dispute creator
    /// @return toHighGuard Amount of tokens for HG
    /// @return vPenalty If penalty need to be applied
    function calculateVerificationReward(
        Market memory m,
        Verification memory v,
        uint256 power,
        uint256 verificationFee
    )
        public
        pure
        returns (
            uint256 toVerifier,
            uint256 toDisputeCreator,
            uint256 toHighGuard,
            bool vPenalty
        )
    {
        if (
            m.result == MarketLib.ResultType.DRAW ||
            m.result == MarketLib.ResultType.INVALID ||
            m.result == MarketLib.ResultType.NULL ||
            v.withdrawn
        ) {
            // draw - withdraw verifier token
            return (0, 0, 0, false);
        }

        uint256 verificatorsFees = ((m.sideA + m.sideB) * verificationFee) /
            DIVIDER;
        if (v.side == (m.result == MarketLib.ResultType.AWON)) {
            // verifier voted properly
            uint256 reward = (v.power * verificatorsFees) /
                (v.side ? m.verifiedA : m.verifiedB);
            return (reward, 0, 0, false);
        } else {
            // verifier voted wrong
            if (m.confirmed) {
                toDisputeCreator = power / 2;
                toHighGuard = power - toDisputeCreator;
            }
            return (0, toDisputeCreator, toHighGuard, true);
        }
    }

    /// @notice Withdraws Verification Reward
    /// @param m Market info
    /// @param v Verification info
    /// @param power Power of vNFT used for verification
    /// @param verificationFee Verification Fee
    /// @return toVerifier Amount of tokens for verifier
    /// @return toDisputeCreator Amount of tokens for dispute creator
    /// @return toHighGuard Amount of tokens for HG
    /// @return vPenalty If penalty need to be applied
    function withdrawVerificationReward(
        Market memory m,
        Verification memory v,
        uint256 power,
        uint256 verificationFee
    )
        external
        returns (
            uint256 toVerifier,
            uint256 toDisputeCreator,
            uint256 toHighGuard,
            bool vPenalty
        )
    {
        if (m.result == MarketLib.ResultType.NULL) {
            revert("MarketIsNotClosedYet");
        }

        if (v.withdrawn) {
            revert("AlreadyWithdrawn");
        }

        (
            toVerifier,
            toDisputeCreator,
            toHighGuard,
            vPenalty
        ) = calculateVerificationReward(m, v, power, verificationFee);

        if (toVerifier != 0) {
            emit WithdrawReward(v.verifier, 2, toVerifier);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IForeVerifiers is IERC721 {
    function decreasePower(uint256 id, uint256 amount) external;

    function protocol() external view returns (address);

    function height() external view returns (uint256);

    function increasePower(
        uint256 id,
        uint256 amount,
        bool increaseValidationNum
    ) external;

    function mintWithPower(
        address to,
        uint256 amount,
        uint256 tier,
        uint256 validationNum
    ) external returns (uint256 mintedId);

    function increaseValidation(uint256 id) external;

    function initialPowerOf(uint256 id) external view returns (uint256);

    function powerOf(uint256 id) external view returns (uint256);

    function burn(uint256 tokenId) external;

    function nftTier(uint256 id) external view returns (uint256);

    function verificationsSum(uint256 id) external view returns (uint256);

    function multipliedPowerOf(uint256 id) external view returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function marketTransfer(address from, uint256 amount) external;

    function marketBurn(uint256 amount) external;
}