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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IAuction Interface
 *
 * @notice This interface defines the essential functions for an auction contract,
 * facilitating token burning, reward distribution, and cycle management. It provides
 * a standardized way to interact with different auction implementations.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IAuction {

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Enables users to recycle their native rewards and claim other rewards.
     */
    function recycle() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim all their pending rewards.
     */
    function claimAll() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim their pending XNF rewards.
     */
    function claimXNF() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim XNF rewards and locks them in the veXNF contract for a year.
     */
    function claimVeXNF() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim their native rewards.
     */
    function claimNative() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Updates the statistics related to the provided user address.
     */
    function updateStats(address) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to recycle native rewards and claim all other rewards.
     */
    function claimAllAndRecycle() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Claims all pending rewards for a specific user.
     * @dev This function aggregates all rewards and claims them in a single transaction.
     * It should be invoked by the veXNF contract before any burn action.
     */
    function claimAllForUser(address) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Claims the accumulated veXNF rewards for a specific user.
     * @dev This function mints and transfers the veXNF tokens to the user.
     * It should be invoked by the veXNF contract.
     */
    function claimVeXNFForUser(address) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns specified batches of vXEN or YSL tokens to earn rewards.
     */
    function burn(bool, uint256) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the current cycle number of the auction.
     * @dev A cycle represents a specific duration or round in the auction process.
     * @return The current cycle number.
     */
    function currentCycle() external returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Updates and retrieves the current cycle number of the auction.
     * @dev A cycle represents a specific duration or round in the auction process.
     * @return The current cycle number.
     */
    function calculateCycle() external returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the number of the last active cycle.
     * @dev Useful for determining the most recent cycle with recorded activity.
     * @return The number of the last active cycle.
     */
    function lastActiveCycle() external returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Registers the caller as a burner by paying in native tokens.
     */
    function participateWithNative(uint256) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the current cycle number based on the time elapsed since the contract's initialization.
     * @return The current cycle number.
     */
    function getCurrentCycle() external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the pending native token rewards for a user based on their NFT ownership and recycling activities.
     * @return The amount of pending native token rewards.
     */
    function pendingNative(address) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Determines the burn and native fee for a given number of batches, adjusting for the time within the current cycle.
     * @return The calculated burn and native fee.
     */
    function coefficientWrapper(uint256) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the reward amount for a given cycle, adjusting for halving events.
     * @return The calculated reward amount.
     */
    function calculateRewardPerCycle(uint256) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the pending native token rewards for a user for the current cycle based on their NFT ownership and recycling activities.
     * @return The amount of pending native token rewards.
     */
    function pendingNativeForCurrentCycle(address) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Computes the pending XNF rewards for a user across various activities.
     * @return pendingXNFRewards An array containing the pending XNF rewards amounts for different activities.
     */
    function pendingXNF(address _user) external view returns (uint256, uint256, uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Registers the caller as a swap user and earns rewards.
     */
    function registerSwapUser(bytes calldata, address, uint256, address) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Computes the pending XNF rewards for a user for the current cycle across various activities.
     * @return pendingXNFRewards An array containing the pending XNF rewards amounts for different activities.
     */
    function pendingXNFForCurrentCycle(address _user) external view returns (uint256, uint256, uint256);

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IVeXNF Interface
 *
 * @notice Interface for querying "time-weighted" supply and balance of NFTs.
 * Provides methods to determine the total supply and user balance at specific points in time.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IVeXNF {

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Merges all NFTs that user has into a single new NFT with 1 year lock period.
     */
    function mergeAll() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Records a global checkpoint for data tracking.
     */
    function checkpoint() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Withdraws all tokens from all expired NFT locks.
     */
    function withdrawAll() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Withdraws all tokens from an expired NFT lock.
     */
    function withdraw(uint) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Merges multiple NFTs into a single new NFT.
     */
    function merge(uint[] memory) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Deposits tokens into a specific NFT lock.
     */
    function depositFor(uint, uint) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Splits a single NFT into multiple new NFTs with specified amounts.
     */
    function split(uint[] calldata, uint) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Extends the unlock time of a specific NFT lock.
     */
    function increaseUnlockTime(uint, uint) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the current total supply of tokens.
     * @return The current total token supply.
     */
    function totalSupply() external view returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the end timestamp of a lock for a specific NFT.
     * @return The timestamp when the NFT's lock expires.
     */
    function lockedEnd(uint) external view returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Creates a lock for a user for a specified amount and duration.
     * @return tokenId The identifier of the newly created NFT.
     */
    function createLock(uint, uint) external returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the total voting power at a specific timestamp.
     * @return The total voting power at the specified timestamp.
     */
    function totalSupplyAtT(uint) external view returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the balance of a specific NFT at a given timestamp.
     * @return The balance of the NFT at the given timestamp.
     */
    function balanceOfNFTAt(uint, uint) external view returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the total token supply at a specific timestamp.
     * @return The total token supply at the given timestamp.
     */
    function getPastTotalSupply(uint256) external view returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the most recent voting power decrease rate for a specific NFT.
     * @return The slope value representing the rate of voting power decrease.
     */
    function get_last_user_slope(uint) external view returns (int128);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Creates a new NFT lock for a specified address, locking a specific amount of tokens.
     * @return tokenId The identifier of the newly created NFT.
     */
    function createLockFor(uint, uint, address) external returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

     /**
     * @notice Retrieves a list of NFT IDs owned by a specific address.
     * @return An array of NFT IDs owned by the specified address.
     */
    function userToIds(address) external view returns (uint256[] memory);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the timestamp of a specific checkpoint for an NFT.
     * @return The timestamp of the specified checkpoint.
     */
    function userPointHistory_ts(uint, uint) external view returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Checks if an address is approved to manage a specific NFT or if it's the owner.
     * @return True if the address is approved or is the owner, false otherwise.
     */
    function isApprovedOrOwner(address, uint) external view returns (bool);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the aggregate balance of NFTs owned by a specific user at a given epoch time.
     * @return totalBalance The total balance of the user's NFTs at the given timestamp.
     */
    function totalBalanceOfNFTAt(address, uint) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IAuction} from "./interfaces/IAuction.sol";
import {IVeXNF} from "./interfaces/IVeXNF.sol";

/*
 * @title veXNF Contract
 *
 * @notice Allows users to lock ERC-20 tokens and receive an ERC-721 NFT in return.
 * The NFT's earning power decays over time and is influenced by the lock duration,
 * with a maximum lock time of 1 year (`_MAXTIME`).
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
contract veXNF is
    IVeXNF,
    IERC721,
    IERC721Metadata,
    ReentrancyGuard
{

    /// ------------------------------------- LIBRARYS ------------------------------------- \\\

    /**
     * @notice Library for converting uint256 to string.
     */
    using Strings for uint256;

    /**
     * @notice Library for safe ERC20 transfers.
     */
    using SafeERC20 for IERC20;

    /// ------------------------------------ VARIABLES ------------------------------------- \\\

    /**
     * @notice Address of the XNF token.
     */
    address public xnf;

    /**
     * @notice Address of the Auction contract, set during deployment and cannot be changed.
     */
    address public Auction;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Name of the NFT token.
     */
    string constant public name = "veXNF";

    /**
     * @notice Symbol of the NFT token.
     */
    string constant public symbol = "veXNF";

    /**
     * @notice Version of the contract.
     */
    string constant public version = "1.0.0";

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Number of decimals the token uses.
     */
    uint8 constant public decimals = 18;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Current epoch number.
     */
    uint public epoch;

    /**
     * @notice Current total supply.
     */
    uint public supply;

    /**
     * @notice Counter for new token ids.
     */
    uint internal _tokenID;

    /**
     * @notice Number of seconds in 1 day.
     */
    uint internal constant _DAY = 1 days;

    /**
     * @notice Number of seconds in 1 week.
     */
    uint internal constant _WEEK = 1 weeks;

    /**
     * @notice Maximum lock duration of 1 year.
     */
    uint internal constant _MAXTIME = 31536000; // 365 * 86400

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Scaled maximum lock duration of 1 year (for calculations).
     */
    int128 internal constant _iMAXTIME = 31536000; // 365 * 86400

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Interface ID for ERC165.
     */
    bytes4 internal constant _ERC165_INTERFACE_ID = 0x01ffc9a7;

    /**
     * @notice Interface ID for ERC721.
     */
    bytes4 internal constant _ERC721_INTERFACE_ID = 0x80ac58cd;

    /// ------------------------------------ MAPPINGS --------------------------------------- \\\

    /**
     * @notice Maps epoch to total supply point.
     */
    mapping (uint => Point) public pointHistory;

    /**
     * @notice Maps time to signed slope change.
     */
    mapping(uint => int128) public slope_changes;

    /**
     * @notice Maps token ID to owner address.
     */
    mapping (uint => address) internal _idToOwner;

    /**
     * @notice Maps token ID to lock info.
     */
    mapping (uint => LockedBalance) public locked;

    /**
     * @notice Maps user address to epoch count.
     */
    mapping (uint => uint) public user_point_epoch;

    /**
     * @notice Maps token ID to approved address.
     */
    mapping (uint => address) internal _idToApprovals;

    /**
     * @notice Maps owner address to token ids owned.
     */
    mapping (address => uint256[]) internal _ownerToIds;

    /**
     * @notice Interface support lookup.
     */
    mapping (bytes4 => bool) internal _supportedInterfaces;

    /**
     * @notice Maps address to number of tokens owned.
     */
    mapping (address => uint) internal _ownerToNFTokenCount;

    /**
     * @notice Maps token ID and epoch to user point.
     */
    mapping (uint => mapping (uint => Point)) public userPointHistory;

    /**
     * @notice Maps owner and operator addresses to approval.
     */
    mapping (address => mapping (address => bool)) internal _ownerToOperators;

    /// -------------------------------------- ERRORS --------------------------------------- \\\

    /**
     * @notice This error is thrown when the lock has already expired.
     */
    error LockExpired();

    /**
     * @notice This error is thrown when sum of weights is zero.
     */
    error WeightIsZero();

    /**
     * @notice This error is thrown when user don't have NFTs to merge.
     */
    error NoNFTsToMerge();

    /**
     * @notice This error is thrown when the caller attempts to clear the allowance from an NFT that does not belong to them.
     */
    error NotOwnerOfNFT();

    /**
     * @notice This error is thrown when NFT does not exist.
     */
    error NFTDoesNotExist();

    /**
     * @notice This error is thrown when trying to mint to the zero address.
     */
    error ZeroAddressMint();

    /**
    * @notice This error is thrown when the locked amount is zero.
    */
    error LockedAmountZero();

    /**
     * @notice This error is thrown when the deposit value is zero.
     */
    error ZeroValueDeposit();

    /**
     * @notice This error is thrown when a contract attempts to record an NFT owner that already exists.
     */
    error NFTAlreadyHasOwner();

    /**
     * @notice This error is thrown when the lock duration is too long.
     */
    error LockDurationTooLong();

    /**
     * @notice This error is thrown when the lock duration is too short.
     */
    error LockDurationTooShort();

    /**
     * @notice This error is thrown when the ERC721 receiver is missing.
     */
    error MissingERC721Receiver();

    /**
     * @notice This error is thrown when the receiver of the NFT does not implement the expected function.
     */
    error InvalidERC721Receiver();

    /**
     * @notice This error is thrown when the owner of the NFT tries to give allowance to his address.
     */
    error ApprovingToSameAddress();

    /**
     * @notice This error is thrown when the token is not owned.
     */
    error TokenNotOwned(uint tokenId);

    /**
     * @notice This error is thrown when not all tokens in the list are owned by the sender.
     */
    error NotAllTokensOwnedBySender();

    /**
     * @notice This error is thrown when trying to withdraw before the lock expires.
     */
    error LockNotExpiredYet(uint lockedEnd);

    /**
     * @notice Error thrown when the contract is already initialised.
     */
    error ContractInitialised(address contractAddress);

    /**
     * @notice This error is thrown when the sender is neither the owner nor an operator for the NFT.
     */
    error NotOwnerOrOperator(address sender, uint tokenId);

    /**
     * @notice This error is thrown when the sender is neither the owner nor approved for the NFT.
     */
    error NotApprovedOrOwner(address sender, uint tokenId);

    /**
     * @notice This error is thrown when the unlock time is set too short.
     */
    error UnlockTimeTooShort(uint unlockTime, uint minTime);

    /**
     * @notice This error is thrown when the token's owner does not match the expected owner.
     */
    error NotTokenOwner(address expectedOwner, uint tokenId);

    /**
     * @notice This error is thrown when the unlock time is set too early.
     */
    error UnlockTimeTooEarly(uint unlockTime, uint lockedEnd);

    /**
     * @notice This error is thrown when the unlock time exceeds the maximum allowed time.
     */
    error UnlockTimeExceedsMax(uint unlockTime, uint maxTime);

    /**
     * @notice This error is thrown when trying to approve the current owner of the NFT.
     */
    error ApprovingCurrentOwner(address approved, uint tokenId);

    /**
     * @notice This error is thrown when the sender is neither the owner nor approved for the NFT.
     */
    error NotTokenOwnerOrApproved(address sender, uint tokenId);

    /**
     * @notice This error is thrown when the sender is neither the owner nor approved for the NFT split.
     */
    error NotApprovedOrOwnerForSplit(address sender, uint tokenId);

    /**
     * @notice This error is thrown when the sender is neither the owner nor approved for the NFT withdrawal.
     */
    error NotApprovedOrOwnerForWithdraw(address sender, uint tokenId);

    /// --------------------------------------- ENUM ---------------------------------------- \\\

    /**
     * @notice Deposit type enum.
     */
    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_UNLOCK_TIME,
        MERGE_TYPE,
        SPLIT_TYPE
    }

    /// ------------------------------------- STRUCTURES ------------------------------------ \\\

    /**
     * @notice Point structure for slope and bias.
     * @param bias Integer bias component.
     * @param slope Integer slope component.
     * @param ts Timestamp.
     */
    struct Point {
        int128 bias;
        int128 slope;
        uint ts;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Represents a locked balance for a user's NFT.
     * @param amount Amount of tokens locked.
     * @param end Timestamp when tokens unlock.
     * @param decayEnd Timestamp when decay ends.
     * @param daysCount Number of days tokens are locked for.
     */
    struct LockedBalance {
        int128 amount;
        uint end;
        uint decayEnd;
        uint256 daysCount;
    }

    /// -------------------------------------- EVENTS --------------------------------------- \\\

    /**
     * @notice Emitted when supply changes.
     * @param prevSupply Previous total supply.
     * @param supply New total supply.
     */
    event Supply(
        uint prevSupply,
        uint supply
    );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Emitted on token deposit.
     * @param provider Account making the deposit.
     * @param tokenId ID of deposited token.
     * @param value Amount deposited.
     * @param locktime New unlock timestamp.
     * @param deposit_type Type of deposit.
     */
    event Deposit(
        address indexed provider,
        uint tokenId,
        uint value,
        uint locktime,
        DepositType deposit_type
    );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Emitted when tokens are withdrawn.
     * @param provider Account making withdrawal.
     * @param tokenId ID of withdrawn token.
     * @param value Amount withdrawn.
     */
    event Withdraw(
        address indexed provider,
        uint tokenId,
        uint value
    );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Emitted when a token is minted.
     * @param to Address minting token.
     * @param id Token id.
     * @param lockedAmount Amount of locked XNF tokens.
     * @param lockEnd Timestamp when lock will be ended.
     */
    event Mint(
        address indexed to,
        uint id,
        uint256 lockedAmount,
        uint256 lockEnd
    );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Emitted when a token is burnt.
     * @param user Address of user.
     * @param tokenID ID of the token that will be burnt.
     */
    event Burn(
        address indexed user,
        uint256 tokenID
    );

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Initialises the contract with the given `XNF` token address and storage contract address.
     * @param _xnf Address of the `XNF` token.
     * @param _Auction Address of the `Auction` contract.
     */
    function initialise(
        address _xnf,
        address _Auction
    ) external {
        if (xnf != address(0))
            revert ContractInitialised(xnf);
        xnf = _xnf;
        pointHistory[0].ts = block.timestamp;
        _supportedInterfaces[_ERC165_INTERFACE_ID] = true;
        _supportedInterfaces[_ERC721_INTERFACE_ID] = true;
        Auction = _Auction;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Sets approval for a third party to manage all of the sender's NFTs.
     * @param _operator The address to grant or revoke operator rights.
     * @param _approved Whether to approve or revoke the operator's rights.
     */
    function setApprovalForAll(
        address _operator,
        bool _approved
    )
        external
        override
    {
        if (_operator == msg.sender) {
            revert ApprovingToSameAddress();
        }
        _ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Transfers a specific NFT from one address to another.
     * @param _from Address currently owning the NFT.
     * @param _to Address to receive the NFT.
     * @param _tokenId ID of the NFT to be transferred.
     */
    function transferFrom(
        address _from,
        address _to,
        uint _tokenId
    )
        external
        override
    {
        _transferFrom(_from, _to, _tokenId, msg.sender);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Safely transfers a specific NFT, ensuring the receiver is capable of handling it.
     * @param _from Address currently owning the NFT.
     * @param _to Address to receive the NFT.
     * @param _tokenId ID of the NFT to be transferred.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint _tokenId
    )
        external
        override
    {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Records a global checkpoint for data tracking.
     */
    function checkpoint() external override {
        _checkpoint(0, LockedBalance(0, 0, 0, 0), LockedBalance(0, 0, 0, 0));
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Deposits tokens into a specific NFT lock.
     * @param _tokenId ID of the NFT where tokens will be deposited.
     * @param _value Amount of tokens to deposit.
     */
    function depositFor(
        uint _tokenId,
        uint _value
    )
        external
        override
        nonReentrant
    {
        if (!_isApprovedOrOwner(msg.sender, _tokenId)) {
            revert NotApprovedOrOwner(msg.sender, _tokenId);
        }
        LockedBalance memory _locked = locked[_tokenId];
        if (_value == 0) {
            revert ZeroValueDeposit();
        }
        if (_locked.end <= block.timestamp) {
            revert LockExpired();
        }
        uint unlock_time = block.timestamp + locked[_tokenId].daysCount * _DAY;
        uint decayEnd = block.timestamp + locked[_tokenId].daysCount * _DAY / 6;
        decayEnd = decayEnd / _DAY * _DAY;
        _depositFor(_tokenId, _value, unlock_time, decayEnd, _locked, DepositType.DEPOSIT_FOR_TYPE);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Creates a new NFT lock for the sender, locking a specific amount of tokens.
     * @param _value Amount of tokens to lock.
     * @param _countOfDays Duration of the lock in days.
     * @return tokenId ID of the newly created NFT lock.
     */
    function createLock(
        uint _value,
        uint _countOfDays
    )
        external
        override
        nonReentrant
        returns (uint)
    {
        return _createLock(_value, _countOfDays, msg.sender);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Creates a new NFT lock for a specified address, locking a specific amount of tokens.
     * @param _value Amount of tokens to lock.
     * @param _countOfDays Duration of the lock in days.
     * @param _to Address for which the lock will be created.
     * @return tokenId ID of the newly created NFT lock.
     */
    function createLockFor(
        uint _value,
        uint _countOfDays,
        address _to
    )
        external
        override
        nonReentrant
        returns (uint)
    {
        return _createLock(_value, _countOfDays, _to);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Extends the unlock time of a specific NFT lock.
     * @param _tokenId ID of the NFT to extend.
     * @param _countOfDays Number of days to extend the unlock time.
     */
    function increaseUnlockTime(
        uint _tokenId,
        uint _countOfDays
    )
        external
        override
        nonReentrant
    {
        if (!_isApprovedOrOwner(msg.sender, _tokenId)) {
            revert NotApprovedOrOwner(msg.sender, _tokenId);
        }
        LockedBalance memory _locked = locked[_tokenId];
        uint unlock_time = block.timestamp + _countOfDays * _DAY;
        uint decayEnd = block.timestamp + _countOfDays * _DAY / 6;
        decayEnd = decayEnd / _DAY * _DAY;
        if (_locked.end <= block.timestamp) {
            revert LockExpired();
        }
        if (unlock_time <= _locked.end) {
            revert UnlockTimeTooEarly(unlock_time, _locked.end);
        }
        if (unlock_time > block.timestamp + _MAXTIME) {
            revert UnlockTimeExceedsMax(unlock_time, block.timestamp + _MAXTIME);
        }
        if (unlock_time < block.timestamp + _WEEK) {
            revert UnlockTimeTooShort(unlock_time, block.timestamp + _WEEK);
        }
        _locked.daysCount = _countOfDays;
        _depositFor(_tokenId, 0, unlock_time, decayEnd, _locked, DepositType.INCREASE_UNLOCK_TIME);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Withdraws all tokens from an expired NFT lock.
     * @param _tokenId ID of the NFT from which to withdraw.
     */
    function withdraw(uint _tokenId)
        external
        override
        nonReentrant
    {
        if (!_isApprovedOrOwner(msg.sender, _tokenId)) {
            revert NotApprovedOrOwnerForWithdraw(msg.sender, _tokenId);
        }
        address owner = _idToOwner[_tokenId];
        LockedBalance memory _locked = locked[_tokenId];
        if (block.timestamp < _locked.end) {
            revert LockNotExpiredYet(_locked.end);
        }
        uint value = uint(int256(_locked.amount));
        locked[_tokenId] = LockedBalance(0,0,0,0);
        uint supply_before = supply;
        supply = supply_before - value;
        _checkpoint(_tokenId, _locked, LockedBalance(0,0,0,0));
        IERC20(xnf).safeTransfer(owner, value);
        IAuction(Auction).claimAllForUser(owner);
        _burn(_tokenId);
        emit Burn(owner, _tokenId);
        emit Withdraw(owner, _tokenId, value);
        emit Supply(supply_before, supply_before - value);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice This function facilitates the withdrawal of all tokens held in expired NFT locks.
     */
    function withdrawAll()
        external
        override
        nonReentrant
    {
        uint[] memory tokens = _ownerToIds[msg.sender];
        uint XNFamount;
        IAuction(Auction).claimAllForUser(msg.sender);
        for (uint256 i; i < tokens.length; i++) {
            LockedBalance memory _locked = locked[tokens[i]];
            if (block.timestamp >= _locked.end) {
                uint value = uint(int256(_locked.amount));
                XNFamount += value;
                locked[tokens[i]] = LockedBalance(0,0,0,0);
                uint supply_before = supply;
                supply = supply_before - value;
                _checkpoint(tokens[i], _locked, LockedBalance(0,0,0,0));
                _burn(tokens[i]);
                emit Burn(msg.sender, tokens[i]);
                emit Withdraw(msg.sender, tokens[i], value);
                emit Supply(supply_before, supply_before - value);
            }
        }
        if (XNFamount > 0) {
            IERC20(xnf).safeTransfer(msg.sender, XNFamount);
        }
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Merges multiple NFTs into a single new NFT.
     * @param _from Array of NFT IDs to be merged.
     */
    function merge(uint[] memory _from)
        external
        override
    {
        address owner = _checkOwner(_from);
        (uint256 maxPeriod) = _getMaxPeriod(_from);
        uint value;
        uint256 length = _from.length;
        IAuction(Auction).claimAllForUser(msg.sender);
        for (uint256 i; i < length; i++) {
            LockedBalance memory _locked = locked[_from[i]];
            value += uint(int256(_locked.amount));
            locked[_from[i]] = LockedBalance(0, 0, 0, 0);
            _checkpoint(_from[i], _locked, LockedBalance(0, 0, 0, 0));
            _burn(_from[i]);
            emit Burn(msg.sender, _from[i]);
        }
        supply -= value;
        uint unlock_time = block.timestamp + maxPeriod * _DAY;
        uint decayEnd = block.timestamp + maxPeriod * _DAY / 6;
        decayEnd = decayEnd / _DAY * _DAY;
        ++_tokenID;
        uint _tokenId = _tokenID;
        _mint(owner, _tokenId);
        emit Mint(msg.sender, _tokenId, value, unlock_time);
        locked[_tokenId].daysCount = maxPeriod;
        _depositFor(_tokenId, value, unlock_time, decayEnd, locked[_tokenId], DepositType.MERGE_TYPE);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Merges all NFTs that user has into a single new NFT with 1 year lock period.
     */
    function mergeAll()
        external
        override
    {
        uint value;
        IAuction(Auction).updateStats(msg.sender);
        IAuction(Auction).claimVeXNFForUser(msg.sender);
        uint[] memory tokens = _ownerToIds[msg.sender];
        uint256 length = tokens.length;
        if (length == 0) {
            revert NoNFTsToMerge();
        }
        for (uint256 i; i < length; i++) {
            LockedBalance memory _locked = locked[tokens[i]];
            value += uint(int256(_locked.amount));
            locked[tokens[i]] = LockedBalance(0, 0, 0, 0);
            _checkpoint(tokens[i], _locked, LockedBalance(0, 0, 0, 0));
            _burn(tokens[i]);
            emit Burn(msg.sender, tokens[i]);
        }
        supply -= value;
        uint unlock_time = block.timestamp + 365 * _DAY;
        uint decayEnd = block.timestamp + 365 * _DAY / 6;
        decayEnd = decayEnd / _DAY * _DAY;
        ++_tokenID;
        uint _tokenId = _tokenID;
        _mint(msg.sender, _tokenId);
        emit Mint(msg.sender, _tokenId, value, unlock_time);
        locked[_tokenId].daysCount = 365;
        _depositFor(_tokenId, value, unlock_time, decayEnd, locked[_tokenId], DepositType.MERGE_TYPE);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Splits a single NFT into multiple new NFTs with specified amounts.
     * @param amounts Array of token amounts for each new NFT.
     * @param _tokenId ID of the NFT to be split.
     */
    function split(
        uint[] calldata amounts,
        uint _tokenId
    )
        external
        override
    {
        if (!_isApprovedOrOwner(msg.sender, _tokenId)) {
            revert NotApprovedOrOwnerForSplit(msg.sender, _tokenId);
        }
        address _to = _idToOwner[_tokenId];
        LockedBalance memory _locked = locked[_tokenId];
        uint value = uint(int256(_locked.amount));
        if (value == 0) {
            revert LockedAmountZero();
        }
        supply = supply - value;
        uint totalWeight;
        uint256 length = amounts.length;
        for (uint i; i < length; i++) {
            totalWeight += amounts[i];
        }
        if (totalWeight == 0) {
            revert WeightIsZero();
        }
        locked[_tokenId] = LockedBalance(0, 0, 0, 0);
        _checkpoint(_tokenId, _locked, LockedBalance(0, 0, 0, 0));
        IAuction(Auction).claimAllForUser(_idToOwner[_tokenId]);
        _burn(_tokenId);
        emit Burn(msg.sender, _tokenId);
        uint unlock_time = _locked.end;
        if (unlock_time <= block.timestamp) {
            revert LockExpired();
        }
        uint _value;
        for (uint j; j < length; j++) {
            ++_tokenID;
            _tokenId = _tokenID;
            _mint(_to, _tokenId);
            _value = value * amounts[j] / totalWeight;
            locked[_tokenId].daysCount = _locked.daysCount;
            emit Mint(msg.sender, _tokenId, _value, unlock_time);
            _depositFor(_tokenId, _value, unlock_time, _locked.decayEnd, locked[_tokenId], DepositType.SPLIT_TYPE);
        }
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Returns the token URI of the specified NFT.
     * @dev This function requires the specified NFT. It returns the token URI,
     * which consists of the base URI concatenated with the token ID and ".json" extension.
     * @param tokenId The ID of the NFT to query the token URI of.
     * @return The token URI of the specified NFT.
     */
    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        string memory baseURI = _baseURI();
        if (_idToOwner[tokenId] == address(0)) {
            revert NFTDoesNotExist();
        }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the total token supply at a specific timestamp.
     * @param timestamp The specific point in time to retrieve the supply.
     * @return The total token supply at the given timestamp.
     */
    function getPastTotalSupply(uint256 timestamp)
        external
        view
        override
        returns (uint)
    {
        return totalSupplyAtT(timestamp);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the count of NFTs owned by a specific address.
     * @param _owner The address whose NFT count is to be determined.
     * @return The number of NFTs owned by the given address.
     */
    function balanceOf(address _owner)
        external
        view
        override
        returns (uint)
    {
        return _balance(_owner);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the approved address for a specific NFT.
     * @param _tokenId The unique identifier of the NFT.
     * @return The address approved to manage the given NFT.
     */
    function getApproved(uint _tokenId)
        external
        view
        override
        returns (address)
    {
        return _idToApprovals[_tokenId];
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Determines if an operator is approved to manage all NFTs of an owner.
     * @param _owner The owner of the NFTs.
     * @param _operator The potential operator.
     * @return True if the operator is approved, false otherwise.
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    )
        external
        view
        override
        returns (bool)
    {
        return (_ownerToOperators[_owner])[_operator];
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Checks if an address is approved to manage a specific NFT or if it's the owner.
     * @param _spender The address in question.
     * @param _tokenId The unique identifier of the NFT.
     * @return True if the address is approved or is the owner, false otherwise.
     */
    function isApprovedOrOwner(
        address _spender,
        uint _tokenId
    )
        external
        view
        override
        returns (bool)
    {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Verifies if the contract supports a specific interface.
     * @param _interfaceID The ID of the interface in question.
     * @return True if the interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        override
        returns (bool)
    {
        return _supportedInterfaces[_interfaceID];
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the most recent voting power decrease rate for a specific NFT.
     * @param _tokenId The unique identifier of the NFT.
     * @return The slope value representing the rate of voting power decrease.
     */
    function get_last_user_slope(uint _tokenId)
        external
        view
        override
        returns (int128)
    {
        uint uepoch = user_point_epoch[_tokenId];
        return userPointHistory[_tokenId][uepoch].slope;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the timestamp of a specific checkpoint for an NFT.
     * @param _tokenId The unique identifier of the NFT.
     * @param _idx The index of the user's epoch.
     * @return The timestamp of the specified checkpoint.
     */
    function userPointHistory_ts(
        uint _tokenId,
        uint _idx
    )
        external
        view
        override
        returns (uint)
    {
        return userPointHistory[_tokenId][_idx].ts;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the end timestamp of a lock for a specific NFT.
     * @param _tokenId The unique identifier of the NFT.
     * @return The timestamp when the NFT's lock expires.
     */
    function lockedEnd(uint _tokenId)
        external
        view
        override
        returns (uint)
    {
        return locked[_tokenId].end;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the balance of a specific NFT at a given timestamp.
     * @param _tokenId The unique identifier of the NFT.
     * @param _t The specific point in time to retrieve the balance.
     * @return The balance of the NFT at the given timestamp.
     */
    function balanceOfNFTAt(
        uint _tokenId,
        uint _t
    )
        external
        view
        override
        returns (uint)
    {
        return _balanceOfNFT(_tokenId, _t);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the combined balance of all NFTs owned by an address at a specific timestamp.
     * @param _user The owner's address.
     * @param _t The specific point in time to retrieve the total balance.
     * @return totalBalanceOf The combined balance of all NFTs owned by the address at the given timestamp.
     */
    function totalBalanceOfNFTAt(
        address _user,
        uint _t
    )
        external
        view
        override
        returns (uint256 totalBalanceOf)
    {
        uint256 length = _ownerToIds[_user].length;
        for (uint256 i; i < length; i++) {
            totalBalanceOf += _balanceOfNFT(_ownerToIds[_user][i], _t);
        }
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves a list of NFT IDs owned by a specific address.
     * @param _user The address whose NFT IDs are to be listed.
     * @return An array of NFT IDs owned by the specified address.
     */
    function userToIds(address _user)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _ownerToIds[_user];
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the current total supply of tokens.
     * @return The current total token supply.
     */
    function totalSupply()
        external
        view
        override
        returns (uint)
    {
        return totalSupplyAtT(block.timestamp);
    }

    /// --------------------------------- PUBLIC FUNCTIONS ---------------------------------- \\\

    /**
     * @notice Grants or changes approval for an address to manage a specific NFT.
     * @param _approved The address to be granted approval.
     * @param _tokenId The ID of the NFT to be approved.
     */
    function approve(
        address _approved,
        uint _tokenId
    )
        public
        override
    {
        address owner = _idToOwner[_tokenId];
        if (owner == address(0)) {
            revert TokenNotOwned(_tokenId);
        }
        if (_approved == owner) {
            revert ApprovingCurrentOwner(_approved, _tokenId);
        }
        bool senderIsOwner = (owner == msg.sender);
        bool senderIsApprovedForAll = (_ownerToOperators[owner])[msg.sender];
        if (!senderIsOwner && !senderIsApprovedForAll) {
            revert NotOwnerOrOperator(msg.sender, _tokenId);
        }
        _idToApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Safely transfers an NFT to another address, ensuring the recipient is capable of receiving it.
     * @param _from The current owner of the NFT.
     * @param _to The address to receive the NFT. If it's a contract, it must implement `onERC721Received`.
     * @param _tokenId The ID of the NFT to be transferred.
     * @param _data Additional data to send with the transfer, used in `onERC721Received` if `_to` is a contract.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint _tokenId,
        bytes memory _data
    )
        public
        override
    {
        _transferFrom(_from, _to, _tokenId, msg.sender);
        if (_isContract(_to)) {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 response) {
                if (response != IERC721Receiver(_to).onERC721Received.selector) {
                    revert InvalidERC721Receiver();
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert MissingERC721Receiver();
                }
                else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the owner of a specific NFT.
     * @param _tokenId The ID of the NFT whose owner is to be determined.
     * @return The address of the owner of the specified NFT.
     */
    function ownerOf(uint _tokenId)
        public
        view
        override
        returns (address)
    {
        return _idToOwner[_tokenId];
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the total voting power at a specific timestamp.
     * @param t The timestamp at which to determine the total voting power.
     * @return The total voting power at the specified timestamp.
     */
    function totalSupplyAtT(uint t)
        public
        view
        override
        returns (uint)
    {
        uint _epoch = epoch;
        Point memory last_point = pointHistory[_epoch];
        return _supply_at(last_point, t);
    }

    /// -------------------------------- INTERNAL FUNCTIONS --------------------------------- \\\

    /**
     * @notice Clears the approval of a specific NFT.
     * @param _owner The address of the current owner of the NFT.
     * @param _tokenId The unique identifier of the NFT.
     */
    function _clearApproval(
        address _owner,
        uint _tokenId
    ) internal {
        if (_idToOwner[_tokenId] != _owner) {
            revert NotOwnerOfNFT();
        }
        if (_idToApprovals[_tokenId] != address(0)) {
            _idToApprovals[_tokenId] = address(0);
        }
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Transfers an NFT from one address to another.
     * @param _from The address of the current owner of the NFT.
     * @param _to The address to receive the NFT.
     * @param _tokenId The unique identifier of the NFT.
     * @param _sender The address initiating the transfer.
     */
    function _transferFrom(
        address _from,
        address _to,
        uint _tokenId,
        address _sender
    ) internal {
        if (!_isApprovedOrOwner(_sender, _tokenId)) {
            revert NotApprovedOrOwner(_sender, _tokenId);
        }
        IAuction(Auction).updateStats(_from);
        IAuction(Auction).updateStats(_to);
        _clearApproval(_from, _tokenId);
        _removeTokenFrom(_from, _tokenId);
        _addTokenTo(_to, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Assigns ownership of an NFT to a specific address.
     * @param _to The address to receive the NFT.
     * @param _tokenId The unique identifier of the NFT.
     */
    function _addTokenTo(
        address _to,
        uint _tokenId
    ) internal {
        if (_idToOwner[_tokenId] != address(0)) {
            revert NFTAlreadyHasOwner();
        }
        _idToOwner[_tokenId] = _to;
        _ownerToIds[_to].push(_tokenId);
        _ownerToNFTokenCount[_to] += 1;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Mints a new NFT and assigns it to a specific address.
     * @param _to The address to receive the minted NFT.
     * @param _tokenId The unique identifier for the new NFT.
     * @return A boolean indicating if the minting was successful.
     */
    function _mint(
        address _to,
        uint _tokenId
    )
        internal
        returns (bool)
    {
        if (_to == address(0)) {
            revert ZeroAddressMint();
        }
        _addTokenTo(_to, _tokenId);
        if (_isContract(_to)) {
            try IERC721Receiver(_to).onERC721Received(address(0), _to, _tokenId, "") returns (bytes4 response) {
                if (response != IERC721Receiver(_to).onERC721Received.selector) {
                    revert InvalidERC721Receiver();
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert MissingERC721Receiver();
                }
                else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        emit Transfer(address(0), _to, _tokenId);
        return true;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Removes an NFT from its owner, effectively clearing its ownership.
     * @param _from The address of the current owner of the NFT.
     * @param _tokenId The unique identifier of the NFT.
     */
    function _removeTokenFrom(
        address _from,
        uint _tokenId
    ) internal {
        if (_idToOwner[_tokenId] != _from) {
            revert NotTokenOwner(_from, _tokenId);
        }
        _idToOwner[_tokenId] = address(0);
        uint256 length = _ownerToIds[_from].length;
        if (length == 1) {
            _ownerToIds[_from].pop();
        } else {
             for (uint256 i; i < length; i++) {
                if (_ownerToIds[_from][i] == _tokenId) {
                    if (i != length - 1) {
                        uint256 tokenIdToChange = _ownerToIds[_from][length - 1];
                        _ownerToIds[_from][i] = tokenIdToChange;
                    }
                    _ownerToIds[_from].pop();
                    break;
                }
            }
        }
        _ownerToNFTokenCount[_from] -= 1;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Permanently destroys an NFT.
     * @param _tokenId The unique identifier of the NFT to be burned.
     */
    function _burn(uint _tokenId) internal {
        if (!_isApprovedOrOwner(msg.sender, _tokenId)) {
            revert NotTokenOwnerOrApproved(msg.sender, _tokenId);
        }
        address owner = ownerOf(_tokenId);
        _clearApproval(owner, _tokenId);
        _removeTokenFrom(owner, _tokenId);
        emit Transfer(owner, address(0), _tokenId);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Records data to a checkpoint for tracking historical data.
     * @param _tokenId The unique identifier of the NFT. If 0, no user checkpoint is created.
     * @param old_locked The previous locked balance details.
     * @param new_locked The new locked balance details.
     */
    function _checkpoint(
        uint _tokenId,
        LockedBalance memory old_locked,
        LockedBalance memory new_locked
    ) internal {
        Point memory u_old;
        Point memory u_new;
        uint _epoch = epoch;
        int128 old_dslope = 0;
        int128 new_dslope = 0;
        if (_tokenId != 0) {
            if (old_locked.decayEnd > block.timestamp && old_locked.amount != 0) {
                u_old.slope = old_locked.amount * 6 / _iMAXTIME;
                u_old.bias = u_old.slope * int128(int256(old_locked.decayEnd) - int256(block.timestamp));
            }
            if (new_locked.decayEnd > block.timestamp && new_locked.amount != 0) {
                u_new.slope = new_locked.amount * 6 / _iMAXTIME;
                u_new.bias = u_new.slope * int128(int256(new_locked.decayEnd) - int256(block.timestamp));
            }
            old_dslope = slope_changes[old_locked.decayEnd];
            if (new_locked.decayEnd != 0) {
                if (new_locked.decayEnd == old_locked.decayEnd) {
                    new_dslope = old_dslope;
                } else {
                    new_dslope = slope_changes[new_locked.decayEnd];
                }
            }
        }
        Point memory last_point = Point({bias: 0, slope: 0, ts: block.timestamp});
        if (_epoch != 0) {
            last_point = pointHistory[_epoch];
        }
        uint last_checkpoint = last_point.ts;
        {
            uint t_i = (last_checkpoint / _DAY) * _DAY;
            for (uint i; i < 61; ++i) {
                t_i += _DAY;
                int128 d_slope = 0;
                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    d_slope = slope_changes[t_i];
                }
                last_point.bias -= last_point.slope * int128(int256(t_i) - int256(last_checkpoint));
                last_point.slope += d_slope;
                if (last_point.bias < 0) {
                    last_point.bias = 0;
                }
                if (last_point.slope < 0) {
                    last_point.slope = 0;
                }
                last_checkpoint = t_i;
                last_point.ts = t_i;
                _epoch += 1;
                if (t_i != block.timestamp) {
                    pointHistory[_epoch] = last_point;
                } else {
                    break;
                }
            }
        }
        epoch = _epoch;
        if (_tokenId != 0) {
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);
            if (last_point.slope < 0) {
                last_point.slope = 0;
            }
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
        }
        pointHistory[_epoch] = last_point;
        if (_tokenId != 0) {
            if (old_locked.decayEnd > block.timestamp) {
                old_dslope += u_old.slope;
                if (new_locked.decayEnd == old_locked.decayEnd) {
                    old_dslope -= u_new.slope;
                }
                slope_changes[old_locked.decayEnd] = old_dslope;
            }
            if (new_locked.decayEnd > block.timestamp) {
                if (new_locked.decayEnd > old_locked.decayEnd) {
                    new_dslope -= u_new.slope;
                    slope_changes[new_locked.decayEnd] = new_dslope;
                }
            }
            uint user_epoch = user_point_epoch[_tokenId] + 1;
            user_point_epoch[_tokenId] = user_epoch;
            u_new.ts = block.timestamp;
            userPointHistory[_tokenId][user_epoch] = u_new;
        }
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Deposits and locks tokens associated with an NFT.
     * @dev This function handles the internal logic for depositing and locking tokens. It updates the user's
     * locked balance, the total supply of locked tokens, and emits the appropriate events. It also
     * ensures the tokens are transferred into the contract when needed.
     * @param _tokenId The unique identifier of the NFT that holds the lock.
     * @param _value The amount of tokens to deposit.
     * @param unlock_time The timestamp when the tokens should be unlocked.
     * @param decayEnd The timestamp when the decay period ends, relevant for certain types of locks.
     * @param locked_balance The previous locked balance details.
     * @param deposit_type The type of deposit being made, defined by the DepositType enum.
     */
    function _depositFor(
        uint _tokenId,
        uint _value,
        uint unlock_time,
        uint decayEnd,
        LockedBalance memory locked_balance,
        DepositType deposit_type
    ) internal {
        LockedBalance memory _locked = locked_balance;
        uint supply_before = supply;
        supply = supply_before + _value;
        LockedBalance memory old_locked;
        (old_locked.amount, old_locked.end, old_locked.decayEnd) = (_locked.amount, _locked.end, _locked.decayEnd);
        _locked.amount += int128(int256(_value));
        if (unlock_time != 0) {
            _locked.end = unlock_time;
            _locked.decayEnd = decayEnd;
        }
        locked[_tokenId] = _locked;
        _checkpoint(_tokenId, old_locked, _locked);
        address from = msg.sender;
        if (_value != 0 && deposit_type != DepositType.MERGE_TYPE && deposit_type != DepositType.SPLIT_TYPE) {
            IERC20(xnf).safeTransferFrom(from, address(this), _value);
        }
        emit Deposit(from, _tokenId, _value, _locked.end, deposit_type);
        emit Supply(supply_before, supply_before + _value);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Creates a lock by depositing tokens for a specified duration.
     * @param _value The amount of tokens to deposit.
     * @param _countOfDays The duration (in days) to lock the tokens.
     * @param _to The address for which the lock is being created.
     * @return The unique identifier of the newly created NFT representing the lock.
     */
    function _createLock(
        uint _value,
        uint _countOfDays,
        address _to
    )
        internal
        returns (uint)
    {
        uint unlock_time = block.timestamp + _countOfDays * _DAY;
        uint decayEnd = ((block.timestamp + _countOfDays * _DAY / 6) /_DAY) * _DAY;
        if (_value == 0) {
            revert ZeroValueDeposit();
        }
        if (unlock_time < block.timestamp + _WEEK) {
            revert LockDurationTooShort();
        }
        if (unlock_time > block.timestamp + _MAXTIME) {
            revert LockDurationTooLong();
        }
        ++_tokenID;
        uint _tokenId = _tokenID;
        _mint(_to, _tokenId);
        emit Mint(msg.sender, _tokenId, _value, unlock_time);
        locked[_tokenId].daysCount = _countOfDays;
        _depositFor(_tokenId, _value, unlock_time, decayEnd, locked[_tokenId], DepositType.CREATE_LOCK_TYPE);
        return _tokenId;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Checks if a given address is authorised to transfer a specific NFT.
     * @param _spender The address attempting the transfer.
     * @param _tokenId The unique identifier of the NFT.
     * @return A boolean indicating if the spender is authorized.
     */
    function _isApprovedOrOwner(
        address _spender,
        uint _tokenId
    )
        internal
        view
        returns (bool)
    {
        address owner = _idToOwner[_tokenId];
        bool spenderIsOwner = owner == _spender;
        bool spenderIsApproved = _spender == _idToApprovals[_tokenId];
        bool spenderIsApprovedForAll = (_ownerToOperators[owner])[_spender];
        return spenderIsOwner || spenderIsApproved || spenderIsApprovedForAll;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the number of NFTs owned by a specific address.
     * @param _owner The address whose balance is being queried.
     * @return The number of NFTs owned by the address.
     */
    function _balance(address _owner)
        internal
        view
        returns (uint)
    {
        return _ownerToNFTokenCount[_owner];
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the voting power of a specific NFT at a given epoch time.
     * @param _tokenId The unique identifier of the NFT.
     * @param _t The epoch time for which the voting power is being queried.
     * @return The voting power of the NFT at the specified time.
     */
    function _balanceOfNFT(
        uint _tokenId,
        uint _t
    )
        internal
        view
        returns (uint)
    {
        uint _epoch = user_point_epoch[_tokenId];
        if (_epoch == 0) {
            return 0;
        }
        else {
            Point memory last_point = userPointHistory[_tokenId][_epoch];
            if (_t < last_point.ts) {
                uint256 left = 0;
                uint256 right = _epoch;
                while (left <= right) {
                    uint256 mid = (left + right + 1) / 2;
                    last_point = userPointHistory[_tokenId][mid];
                    Point memory last_point_right = userPointHistory[_tokenId][mid + 1];
                    if (last_point.ts <= _t && _t < last_point_right.ts) {
                        break;
                    }
                    else if (_t < last_point.ts) {
                        if (mid == 0)
                            return 0;
                        right = mid - 1;
                    } else {
                        left = mid + 1;
                    }
                }
            }
            last_point.bias -= last_point.slope * int128(int256(_t) - int256(last_point.ts));
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
            return uint(int256(last_point.bias));
        }
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Verifies that the msg.sender is the owner of all provided NFT IDs.
     * @param _ids An array of NFT IDs to verify ownership.
     * @return owner The address of the owner if all NFTs in the list are owned by the msg.sender.
     */
    function _checkOwner(uint[] memory _ids)
        internal
        view
        returns (address owner)
    {
        uint256 count;
        uint256 length = _ids.length;
        for (uint256 i; i < length; i++) {
            if (ownerOf(_ids[i]) == msg.sender) {
                count++;
            }
        }
        if (count != length) {
            revert NotAllTokensOwnedBySender();
        }
        owner = _idToOwner[_ids[0]];
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Determines the longest lock duration from a list of NFT IDs.
     * @param _ids An array of NFT IDs to check.
     * @return maxPeriod The maximum lock duration (in days) found among the provided NFTs.
     */
    function _getMaxPeriod(uint[] memory _ids)
        internal
        view
        returns (uint256 maxPeriod)
    {
        maxPeriod = locked[_ids[0]].daysCount;
        uint256 length = _ids.length;
        for (uint256 i = 1; i < length; i++) {
            if (maxPeriod < locked[_ids[i]].daysCount) {
                maxPeriod = locked[_ids[i]].daysCount;
            }
        }
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Checks if a given address is associated with a contract.
     * @param account The address to verify.
     * @return A boolean indicating whether the address is a contract (true) or an externally owned account (false).
     */
    function _isContract(address account)
        internal
        view
        returns (bool)
    {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size != 0;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Computes the total voting power at a specific past time using a given point as a reference.
     * @param point The reference point containing bias and slope values.
     * @param t The epoch time for which the total voting power is being calculated.
     * @return The total voting power at the specified time.
     */
    function _supply_at(
        Point memory point,
        uint t
    )
        internal
        view
        returns (uint)
    {
        Point memory last_point = point;
        if (t < last_point.ts) {
            uint256 left = 0;
            uint256 right = epoch;
            while (left <= right) {
                uint256 mid = (left + right + 1) / 2;
                last_point = pointHistory[mid];
                Point memory last_point_right = pointHistory[mid + 1];
                if (last_point.ts <= t && t < last_point_right.ts) {
                    break;
                }
                else if (t < last_point.ts) {
                    if (mid == 0)
                        return 0;
                    right = mid - 1;
                } else {
                    left = mid + 1;
                }
            }
        }
        uint t_i = (last_point.ts / _DAY) * _DAY;
        for (uint i; i < 61; ++i) {
            t_i += _DAY;
            int128 d_slope = 0;
            if (t_i > t) {
                t_i = t;
            } else {
                d_slope = slope_changes[t_i];
            }
            last_point.bias -= last_point.slope * int128(int256(t_i) - int256(last_point.ts));
            if (t_i == t) {
                break;
            }
            last_point.slope += d_slope;
            last_point.ts = t_i;
        }
        if (last_point.bias < 0) {
            last_point.bias = 0;
        }
        return uint(uint128(last_point.bias));
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Returns the base URI for the veXNF NFT contract.
     * @return Base URI for the veXNF NFT contract.
     * @dev This function is internal and pure, it's used to get the base URI for the veXNF NFT contract.
     */
    function _baseURI()
        internal
        pure
        returns (string memory)
    {
        return "https://xnf-info.xenify.io/arbitrum/metadata/";
    }

    /// ------------------------------------------------------------------------------------- \\\
}