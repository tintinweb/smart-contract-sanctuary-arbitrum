// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// interface for the FeeDistributor
interface IFeeDistributor {
    /// deposits Fees
    /// @dev deposits fees into the fee distributor
    /// @param _tokenAddress the token address
    /// @param _amount the amount
    function receiveERC20Fees(address _tokenAddress, uint256 _amount) external;

    /// getNftAddress
    /// @dev gets the address of the NFT contract
    /// returns NFT address
    function getNftAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// interface for the MasterChef
interface IMasterChefV3 {
    /// @notice harvest cake from pool.
    /// @param _tokenId Token Id of NFT.
    /// @param _to Address to.
    /// @return reward Cake reward.
    function harvest(uint256 _tokenId, address _to) external returns (uint256 reward);

    /// @notice Withdraw LP tokens from pool.
    /// @param _tokenId Token Id of NFT to deposit.
    /// @param _to Address to which NFT token to withdraw.
    /// @return reward Cake reward.
    function withdraw(uint256 _tokenId, address _to) external returns (uint256 reward);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
IPoolInitializer,
IPeripheryPayments,
IPeripheryImmutableState,
IERC721Metadata,
IERC721Enumerable,
IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
    external
    view
    returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
    external
    payable
    returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// interface for the MasterChef
interface IRangeMaster {
    function getYieldManager() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3Pool {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// interface for the YieldManager
interface IYieldManager {

    /// Sets the wanted affiliate
    /// @dev sets the value of the sponsor variable at a client object
    /// @param client the mapping entry point
    /// @param sponsor the address to set as a sponsor
    function setAffiliate(address client, address sponsor) external;

    /// Gets the factors for user and sponsor
    /// @dev returns the client and sponsor factors
    /// @param user the client to look up
    /// @param typer the type (sponsor or client mode)
    function getUserFactors(
        address user,
        uint typer
    ) external view returns (uint, uint, uint, uint);

    /// Gets the wanted affiliate
    /// @dev gets the value of the sponsor variable at a client object
    /// @param client the mapping entry point
    function getAffiliate(address client) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0 = a * b; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
            require(denominator > prod1);

        // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        // Subtract 256 bit remainder from 512 bit number
            assembly {
                let remainder := mulmod(a, b, denominator)
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
        // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

        // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the preconditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            if (a == 0 || ((result = a * b) / a == b)) {
                require(denominator > 0);
                assembly {
                    result := add(div(result, denominator), gt(mod(result, denominator), 0))
                }
            } else {
                result = mulDiv(a, b, denominator);
                if (mulmod(a, b, denominator) > 0) {
                    require(result < type(uint256).max);
                    result++;
                }
            }
        }
    }

    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function unsafeDivRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './FullMath.sol';
import './FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './interfaces/INonfungiblePositionManager.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/IUniswapV3Factory.sol";
import "./interfaces/IYieldManager.sol";
import "./interfaces/IFeeDistributor.sol";
import "./interfaces/IRangeMaster.sol";
import "./interfaces/IMasterChefV3.sol";
import './libraries/TickMath.sol';
import "./libraries/LiquidityAmounts.sol";

contract RangePositionManager is ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public currentTokenId;
    uint128 public totalLiquidity;

    int24 internal currentTickLower;
    int24 internal currentTickUpper;

    address internal WETH;
    address internal token0;
    address internal token1;
    uint24 internal fee;

    // Maximum acceptable price deviation threshold in basis points (1 basis point = 0.01%, 50 basis points = 0.5%, 100 basis points = 1%)
    int24 public tickMoveThreshold;

    // indicates if the mint and increase liquidity is locked
    bool public isLocked;

    // indicates if moveRange check is on
    bool public checkMoveRangeDisabled;

    address public owner;
    address private _pendingOwner;
    address public feeReceiver;
    address private _pendingFeeReceiver;
    INonfungiblePositionManager public positionManager;
    IUniswapV3Pool internal uniswapV3Pool;
    IUniswapV3Factory internal uniswapV3Factory;
    IAggregatorSwapper internal aggregatorSwapper;

    uint internal productLock;

    IFeeDistributor internal feeDistributor;
    uint internal distributionFee;

    IMasterChefV3 public masterChef;
    address internal cakeToken;

    address[] public userList;
    uint public maxUsers;

    address internal rangeMaster;

    // structs
    struct UserInfo {
        uint liquidity;
        uint token0Balance;
        uint token1Balance;
        uint cakeTokenBalance;
    }

    // struct for handling the variables in moveRange
    struct MoveRangeParams {
        uint160 sqrtPriceX96;
        uint decreaseAmount0;
        uint decreaseAmount1;
        uint amount0;
        uint amount1;
        int24 currentTick;
        int24 tickSpace;
        int24 currentTickLowerInterpolated;
        int24 currentTickUpperInterpolated;
        int24 newTickUpper;
        int24 newTickLower;
        uint160 sqrtPriceLimitX96;
        uint160 sqrtRatioA;
        uint160 sqrtRatioB;
        address tokenIn;
        address tokenOut;
        uint amountIn;
        uint amountOutQuote;
        uint amountOutMinimum;
        uint returnFromSwap;
        uint returnFromSwapFinal;
    }

    // mappings
    mapping(address => UserInfo) public userMapping;
    mapping(address => bool) internal isUser;
    mapping(address => bool) public moveRangeAddresses;

    // only owner modifier
    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // only owner view
    function _onlyOwner() private view {
        require(msg.sender == owner || msg.sender == address(this), "Only the contract owner may perform this action");
    }

    // only rangeMaster modifier
    modifier onlyRangeMaster {
        _onlyRangeMaster();
        _;
    }

    // only rangeMaster view
    function _onlyRangeMaster() private view {
        require(msg.sender == rangeMaster, "Only the range master may perform this action");
    }

    // events
    event Mint(uint amount0, uint amount1, uint liquidity, uint tokenId, address user);
    event IncreaseLiquidity(uint amount0, uint amount1, uint liquidity, address user);
    event RemovedLiquidity(uint amount0, uint amount1, uint liquidity, address user);
    event FeesWithdrawn(uint amount0, uint amount1, address user);
    event NewOwner(address owner);
    event Locked(bool locked);
    event MovedRange(int24 tickLower, int24 tickUpper);
    event NewTickMoveThreshold(int24 tickMove);
    event CheckMoveRangeDisabled(bool checkDisabled);
    event MoveAddressUpdated(address mover, bool status);
    event NewFeeReceiver(address newFeeReceiver);
    event NewRangeMaster(address newRangeMaster);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event FeeReceiverTransferStarted(address indexed previousFeeReceiver, address indexed newFeeReceiver);
    event NewMaxUsers(uint maxUsers);
    event NewMasterChef(address newMasterChef);

    constructor(
        address _positionManager,
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickMoveThreshold,
        uint _productLock,
        address _feeDistributor,
        uint _distributionFee,
        address _masterChef,
        address _cakeAddress,
        address _aggregatorSwapper
    ){
        require(_feeDistributor != address(0), "feeDistributor cant be zero address");
        require(_token1 != address(0) && _token0 != address(0), "Zero address for tokens");
        require(_tickMoveThreshold <= 10000, "_tickMoveThreshold too big");

        owner = msg.sender;
        feeReceiver = msg.sender;
        token0 = _token0;
        token1 = _token1;
        fee = _fee;

        positionManager = INonfungiblePositionManager(_positionManager);
        uniswapV3Factory = IUniswapV3Factory(positionManager.factory());
        uniswapV3Pool = IUniswapV3Pool(uniswapV3Factory.getPool(token0, token1, fee));
        WETH = positionManager.WETH9();

        tickMoveThreshold = _tickMoveThreshold;
        maxUsers = 10000;

        productLock = _productLock;
        feeDistributor = IFeeDistributor(_feeDistributor);
        distributionFee = _distributionFee;

        masterChef = IMasterChefV3(_masterChef);
        cakeToken = _cakeAddress;

        aggregatorSwapper = IAggregatorSwapper(_aggregatorSwapper);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// Function for the first mint of the initial position nft
    /// @dev mints the first initial position NFT, can only be called by the owner
    /// @dev this contract accepts native ETH and converts it to WETH
    /// @dev WETH deposits are not allowed (only ETH)
    /// @param tickLower the lower tick
    /// @param tickUpper the upper tick
    /// @param amountDesired0 the amount of token0 desired
    /// @param amountDesired1 the amount of token1 desired
    /// @param amount0Min the min amount of token0 desired
    /// @param amount1Min the min amount of token1 desired
    function mintOwner(
        int24 tickLower,
        int24 tickUpper,
        uint amountDesired0,
        uint amountDesired1,
        uint amount0Min,
        uint amount1Min
    )
    external payable onlyOwner nonReentrant {
        require(totalLiquidity == 0, "owner mint can only be triggered with 0 liquidity");
        mint(tickLower, tickUpper, amountDesired0, amountDesired1, amount0Min,amount1Min, false);
    }

    /// Checks if range can be moved
    /// @dev checks if the range position can be moved
    /// returns a bool indicating if position can be moved or not
    function canMoveRange() public view returns (bool) {
        // if check is disabled we can always move
        if (checkMoveRangeDisabled) {
            return true;
        }

        // get the current tick
        (,int24 currentTick,,,,,) = uniswapV3Pool.slot0();

        // delta can never be a negative number
        int256 delta = int256(currentTickUpper) - int256(currentTickLower);
        int256 hardLimitTickUpper = int256(currentTickUpper) - (tickMoveThreshold * delta / 10000);
        int256 hardLimitTickLower = int256(currentTickLower) + (tickMoveThreshold * delta / 10000);

        return currentTick > hardLimitTickUpper || currentTick < hardLimitTickLower;
    }

    /// View function to get the amount for ticks onchain
    /// @dev checks for liquidity amount s on chain
    /// @param tickLower the lower tick
    /// @param tickUpper the upper tick
    /// @param liquidity the amount of liquidity
    /// returns the output amount for token0 and token1
    function getAmountsForTicks(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external view returns (uint256 amount0, uint256 amount1) {
        (uint160 sqrtPriceX96,,,,,,) = uniswapV3Pool.slot0();
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickUpper), liquidity);
    }

    /// function for moving range
    /// @dev this function is used to move the liquidity ranges (lower tick, upper tick). If possible (within the threshold)
    /// @dev it is possible to call this function. It will decrease all liquidity from the position, swap tokens in a ratio given in the parameter
    /// @dev and then mint a new position using this tokens swapped. Users will get the share of the new liquidity pro rata
    /// @param tickLower the new lower tick
    /// @param tickUpper the new upper tick
    /// @param tokenForRatios the token to be swapped in firstly
    /// @param amountToSwap the amount to be swapped from the tokenForRatios
    /// @param slippagePercent the slippage setting
    function moveRange
    (
        int24 tickLower,
        int24 tickUpper,
        address tokenForRatios,
        uint amountToSwap,
        uint amountDecrease0Min,
        uint amountDecrease1Min,
        uint amount0Min,
        uint amount1Min,
        uint slippagePercent,
        bool uniSwap,
        bytes calldata data
    )
    external nonReentrant
    {
        require(moveRangeAddresses[msg.sender], "not allowed to move range");
        require(canMoveRange(), "Not allowed to move range");
        require(slippagePercent <= 10000, "slippage setting too high");
        require(tokenForRatios == token0 || tokenForRatios == token1, "wrong token argument");

        // if rewards are active
        if (address(masterChef) != address(0)) {
            //get back from masterChef
            updateUserCakeBalance(masterChef.withdraw(currentTokenId, address(this)));
        }

        // collect fees
        collect(0, 0);

        MoveRangeParams memory params;

        // calculate the amount of token0 and token1 based on the percentage of liquidity to be removed
        (params.sqrtPriceX96,params.currentTick,,,,,) = uniswapV3Pool.slot0();

        params.sqrtRatioA = TickMath.getSqrtRatioAtTick(currentTickLower);
        params.sqrtRatioB = TickMath.getSqrtRatioAtTick(currentTickUpper);
        (params.decreaseAmount0, params.decreaseAmount1) = LiquidityAmounts.getAmountsForLiquidity(params.sqrtPriceX96, params.sqrtRatioA, params.sqrtRatioB, totalLiquidity);

        // decrease to 0 with 0.05% slippage
        (params.amount0, params.amount1) = decreaseLiquidity(amountDecrease0Min, amountDecrease1Min, totalLiquidity, address(this), true);

        // burn the position
        positionManager.burn(currentTokenId);
        // get correct input params
        params.tokenIn = (tokenForRatios == token0) ? token1 : token0; // Token to swap from (depends on the token we get from the input)
        params.tokenOut = (tokenForRatios == token0) ? token0 : token1; // Token to receive (opposite of tokenIn)
        params.amountIn = (tokenForRatios == token0) ? params.amount1 : params.amount0; // Amount to swap from (either amount0 or amount1)

        // first swap if needed
        if (params.amountIn > 0) {
            IERC20(params.tokenIn).safeApprove(address(aggregatorSwapper), 0);
            IERC20(params.tokenIn).safeApprove(address(aggregatorSwapper), params.amountIn);

            params.returnFromSwap = aggregatorSwapper.swap{value: params.tokenIn == WETH ? params.amountIn : 0}(params.tokenIn, params.tokenOut, params.amountIn, slippagePercent, fee);
        }

        if (tokenForRatios == token0) {
            params.returnFromSwap = params.returnFromSwap + params.amount0;
        }
        else {
            params.returnFromSwap = params.returnFromSwap + params.amount1;
        }

        // The call to `exactInputSingle` executes the swap.
        // approvals
        IERC20(params.tokenOut).safeApprove(address(aggregatorSwapper), 0);
        IERC20(params.tokenOut).safeApprove(address(aggregatorSwapper), amountToSwap);

        // check if normal swap or aggregator swap
        if (uniSwap) {
            params.returnFromSwapFinal = aggregatorSwapper.swap{value: params.tokenOut == WETH ? amountToSwap : 0}(params.tokenOut, params.tokenIn, amountToSwap, slippagePercent, fee);
        } else {
            params.returnFromSwapFinal =aggregatorSwapper.aggregatorSwap(params.tokenOut, params.tokenIn, amountToSwap, data);
        }

        uint token0check = tokenForRatios == token0 ? params.returnFromSwap - amountToSwap : params.returnFromSwapFinal;
        uint token1check = tokenForRatios == token0 ? params.returnFromSwapFinal : params.returnFromSwap - amountToSwap;

        // mint new position
        mint(
            tickLower,
            tickUpper,
            token0check,
            token1check,
            amount0Min,
            amount1Min,
            true
        );

        emit MovedRange(tickLower, tickUpper);
    }


    /// Internal mint function
    /// @dev mints position NFTs according to the params. Can be a first time mint from the owner, or moveRange mint
    /// @param tickLower the lower tick
    /// @param tickUpper the upper tick
    /// @param amountDesired0 the amount of token0 desired
    /// @param amountDesired1 the amount of token1 desired
    /// @param amount0Min the min amount of token0 desired
    /// @param amount1Min the min amount of token1 desired
    /// @param contractCall indicated if it is a moveRange call (coming from the contract itself)
    function mint(
        int24 tickLower,
        int24 tickUpper,
        uint amountDesired0,
        uint amountDesired1,
        uint amount0Min,
        uint amount1Min,
        bool contractCall
    ) internal {

        // get mint decreaseParams
        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager.MintParams(
        {
            token0 : token0,
            token1 : token1,
            fee : fee,
            tickLower : tickLower,
            tickUpper : tickUpper,
            amount0Desired : amountDesired0,
            amount1Desired : amountDesired1,
            amount0Min : amount0Min,
            amount1Min : amount1Min,
            recipient : address(this),
            deadline : block.timestamp
        }
        );

        // handle the approvals for ERC20 tokens
        if (mintParams.token0 != WETH) {
            IERC20(mintParams.token0).safeApprove(address(positionManager), 0);
            IERC20(mintParams.token0).safeApprove(address(positionManager), mintParams.amount0Desired);
        }

        if (mintParams.token1 != WETH) {
            IERC20(mintParams.token1).safeApprove(address(positionManager), 0);
            IERC20(mintParams.token1).safeApprove(address(positionManager), mintParams.amount1Desired);
        }

        // define output variables for later usage
        uint256 tokenId;
        uint256 amount0;
        uint256 amount1;
        uint128 liquidity;

        // call this if it is a reposition call
        if (contractCall) {

            (tokenId, liquidity, amount0, amount1) = positionManager.mint{value : token0 == WETH ? mintParams.amount0Desired : (token1 == WETH ? mintParams.amount1Desired : 0)}(mintParams);
            positionManager.refundETH();

            uint amount0Diff = amountDesired0 - amount0;
            uint amount1Diff = amountDesired1 - amount1;

            require(totalLiquidity != 0, "totalLiquidity divisor is zero");
            require(liquidity != 0, "liquidity divisor is zero");

            // update user percentages
            uint userListLength = userList.length;
            for (uint i = 0; i < userListLength; i++) {
                UserInfo storage userElement = userMapping[userList[i]];
                userElement.liquidity = userElement.liquidity * liquidity / totalLiquidity;

                if (amount0Diff > 0) {
                    userElement.token0Balance += amount0Diff * userElement.liquidity / liquidity;
                }
                if (amount1Diff > 0) {
                    userElement.token1Balance += amount1Diff * userElement.liquidity / liquidity;
                }
            }
        }

        // sender is not the contract, first owner call
        else {
            (tokenId, liquidity, amount0, amount1) = positionManager.mint{value : msg.value}(mintParams);
            // housekeeping for first mint
            positionManager.refundETH();

            // sweep the remaining tokens
            positionManager.sweepToken(token0, 0, address(this));
            positionManager.sweepToken(token1, 0, address(this));

            // refunds
            if (token0 == WETH && (address(this).balance > 0)) {
                payable(msg.sender).sendValue(address(this).balance);
            }
            if (token1 == WETH && (address(this).balance > 0)) {
                payable(msg.sender).sendValue(address(this).balance);
            }
            if (token0 != WETH && IERC20(token0).balanceOf(address(this)) > 0) {
                IERC20(token0).safeTransfer(msg.sender, IERC20(token0).balanceOf(address(this)));
            }
            if (token1 != WETH && IERC20(token1).balanceOf(address(this)) > 0) {
                IERC20(token1).safeTransfer(msg.sender, IERC20(token1).balanceOf(address(this)));
            }

            //add owner init as user used for owner decrease after potential lock
            if (!isUser[msg.sender]) {
                // update user mapping
                UserInfo storage userElement = userMapping[msg.sender];
                userElement.liquidity += liquidity;

                // push the unique item to the array
                userList.push(msg.sender);
                isUser[msg.sender] = true;
            }
        }

        totalLiquidity = liquidity;
        currentTokenId = tokenId;
        currentTickUpper = tickUpper;
        currentTickLower = tickLower;

        // if rewards are active
        if (address(masterChef) != address(0)) {
            //send to stake in masterChef
            IERC721(positionManager).safeTransferFrom(address(this), address(masterChef), currentTokenId);
        }

        emit Mint(amount0, amount1, liquidity, currentTokenId, msg.sender);
    }

    /// function to check if holder is eligible
    /// @dev checking if an address has enough NFTs to use the product
    /// @param sender the sender address to check
    function showEligible(address sender) public view returns (bool) {
        return IERC721(feeDistributor.getNftAddress()).balanceOf(sender) >= productLock;
    }

    /// public function for increasing liquidity
    /// @dev for increasing liquidity, also sets the sponsor if new user
    /// @param amountDesired0 the desired amount to use of token0
    /// @param amountDesired1 the desired amount to use of token1
    /// @param amount0Min the minimum amount of token0
    /// @param amount1Min the minimum amount of token1
    /// @param userToIncrease the user to increase
    function increaseLiquidityUser(
        uint amountDesired0,
        uint amountDesired1,
        uint amount0Min,
        uint amount1Min,
        address userToIncrease
    )
    external payable nonReentrant onlyRangeMaster
    {
        if(token0 == WETH) {
            require(amountDesired0 == msg.value, "ETH amount mismatch");
        }
        if(token1 == WETH) {
            require(amountDesired1 == msg.value, "ETH amount mismatch");
        }

        // increase the liquidity of the user
        increaseLiquidity(
            amountDesired0,
            amountDesired1,
            amount0Min,
            amount1Min,
            userToIncrease,
            false
        );
    }

    /// public function for increasing liquidity automatically
    /// @dev for increasing liquidity auto
    /// @param amountDesired0 the desired amount to use of token0
    /// @param amountDesired1 the desired amount to use of token1
    /// @param amount0Min the minimum amount of token0
    /// @param amount1Min the minimum amount of token1
    /// @param userToIncrease the address of the user to increase
    function increaseLiquidityAuto(
        uint amountDesired0,
        uint amountDesired1,
        uint amount0Min,
        uint amount1Min,
        address userToIncrease
    )
    external nonReentrant
    {
        require(moveRangeAddresses[msg.sender], "not allowed to auto increase user");

        // get user element
        UserInfo storage userElement = userMapping[userToIncrease];

        require(userElement.token0Balance >= amountDesired0, "token0 amount not sufficient");
        require(userElement.token1Balance >= amountDesired0, "token1 amount not sufficient");

        increaseLiquidity(
            amountDesired0,
            amountDesired1,
            amount0Min,
            amount1Min,
            userToIncrease,
            true
        );
    }

    /// internal function for increasing liquidity
    /// @dev for increasing liquidity, also sets the sponsor if new user
    /// @param amountDesired0 the desired amount to use of token0
    /// @param amountDesired1 the desired amount to use of token1
    /// @param amount0Min the minimum amount of token0
    /// @param amount1Min the minimum amount of token1
    /// @param userToIncrease the user to be increased
    /// @param autoCall indicates if this call is from a bot account
    function increaseLiquidity(
        uint amountDesired0,
        uint amountDesired1,
        uint amount0Min,
        uint amount1Min,
        address userToIncrease,
        bool autoCall
    )
    internal
    {
        // check if locked
        require(!isLocked, "Locked for increasing liquidity");
        require(isUser[userToIncrease] || userList.length < maxUsers, "Max users reached");
        require(showEligible(userToIncrease), "Not eligible to enter the product");

        // if rewards are active
        if (address(masterChef) != address(0)) {
            //get back from masterChef
            updateUserCakeBalance(masterChef.withdraw(currentTokenId, address(this)));
        }

        // get increase params
        INonfungiblePositionManager.IncreaseLiquidityParams memory increaseParams = INonfungiblePositionManager.IncreaseLiquidityParams({
            tokenId : currentTokenId,
            amount0Desired : amountDesired0,
            amount1Desired : amountDesired1,
            amount0Min : amount0Min,
            amount1Min : amount1Min,
            deadline : block.timestamp
        });

        // handle approvals
        if (token0 != WETH) {
            if (!autoCall) {
                IERC20(token0).safeTransferFrom(userToIncrease, address(this), amountDesired0);
            }

            IERC20(token0).safeApprove(address(positionManager), 0);
            IERC20(token0).safeApprove(address(positionManager), amountDesired0);
        }

        if (token1 != WETH) {
            if (!autoCall) {
                IERC20(token1).safeTransferFrom(userToIncrease, address(this), amountDesired1);
            }

            IERC20(token1).safeApprove(address(positionManager), 0);
            IERC20(token1).safeApprove(address(positionManager), amountDesired1);
        }

        uint ETHValue;
        // calculate the ETH value
        if (token0 == WETH) {
            ETHValue = amountDesired0;
        }
        if (token1 == WETH) {
            ETHValue = amountDesired1;
        }

        // increase call
        (uint128 liquidity, uint256 amount0, uint256 amount1) = positionManager.increaseLiquidity{value : ETHValue}(increaseParams);
        positionManager.refundETH();

        // update user mapping
        UserInfo storage userElement = userMapping[userToIncrease];
        userElement.liquidity += liquidity;

        // check against the mapping
        if (!isUser[userToIncrease]) {
            // push the unique item to the array
            userList.push(userToIncrease);
            isUser[userToIncrease] = true;
        }

        // check if user or bot call
        if (!autoCall) {
            // send back tokens
            if (token0 == WETH && (ETHValue - amount0 > 0)) {
                payable(userToIncrease).sendValue(ETHValue - amount0);
            }
            if (token1 == WETH && (ETHValue - amount1 > 0)) {
                payable(userToIncrease).sendValue(ETHValue - amount1);
            }
            if (token0 != WETH && amountDesired0 - amount0 > 0) {
                IERC20(token0).safeTransfer(userToIncrease, amountDesired0 - amount0);
            }
            if (token1 != WETH && amountDesired1 - amount1 > 0) {
                IERC20(token1).safeTransfer(userToIncrease, amountDesired1 - amount1);
            }
        } else {
            userElement.token0Balance -= amount0;
            userElement.token1Balance -= amount1;
        }

        // if rewards are active
        if (address(masterChef) != address(0)) {
            //send to stake in masterChef
            IERC721(positionManager).safeTransferFrom(address(this), address(masterChef), currentTokenId);
        }

        totalLiquidity += liquidity;
        emit IncreaseLiquidity(amount0, amount1, liquidity, userToIncrease);
    }


    /// function for decreasing liquidity, for msg.sender
    /// @dev for decreasing liquidity, for msg.sender
    /// @param amount0Min the minimum amount to receive of token0
    /// @param amount1Min the minimum amount to receive of token1
    /// @param liquidity the amount of liquidity to be decreased
    /// @param liquidity the userToDecrease to decrease
    function decreaseLiquidityUser(
        uint amount0Min,
        uint amount1Min,
        uint128 liquidity,
        address userToDecrease
    )
    external
    nonReentrant
    onlyRangeMaster
    {
        //get user element
        UserInfo storage userElement = userMapping[userToDecrease];

        // check for liquidity
        require(liquidity <= userElement.liquidity);

        // perform decrease liquidity
        decreaseLiquidity(amount0Min, amount1Min, liquidity, userToDecrease, false);
    }

    /// function for decreasing liquidity, used by governance to force decrease of a specific user after x amount of time
    /// @dev for decreasing liquidity, used by governance to force decrease of a specific user after x amount of time
    /// @param amount0Min the minimum amount to receive of token0
    /// @param amount1Min the minimum amount to receive of token1
    /// @param liquidity the amount of liquidity to be decreased
    /// @param userToDecrease the user address to be decreased
    function decreaseLiquidityUserForce(
        uint amount0Min,
        uint amount1Min,
        uint128 liquidity,
        address userToDecrease
    )
    external
    onlyOwner
    nonReentrant
    {
        //get user element
        UserInfo storage userElement = userMapping[userToDecrease];

        // check for liquidity
        require(liquidity <= userElement.liquidity);

        // perform decrease liquidity
        decreaseLiquidity(amount0Min, amount1Min, liquidity, userToDecrease, false);
    }

    /// function for decreasing liquidity, internal, can be used for user decrease, forced decrease or internal new mint decrease
    /// @dev for decreasing liquidity, internal, can be used for user decrease, forced decrease or internal new mint decrease
    /// @param amount0Min the minimum amount to receive of token0
    /// @param amount1Min the minimum amount to receive of token1
    /// @param liquidity the amount of liquidity to be decreased
    /// @param userToDecrease the user address to be decreased
    /// @param contractCall indicated if call comes from inside the contract or user action
    /// @return amount0 the amount how much token0 we got as return
    /// @return amount1 the amount how much token1 we got as return
    function decreaseLiquidity(
        uint amount0Min,
        uint amount1Min,
        uint128 liquidity,
        address userToDecrease,
        bool contractCall
    )
    internal
    returns
    (
        uint amount0,
        uint amount1
    )
    {
        // if rewards are active
        if (address(masterChef) != address(0)) {
            //get back from masterChef
            updateUserCakeBalance(masterChef.withdraw(currentTokenId, address(this)));
        }

        // build decrease params
        INonfungiblePositionManager.DecreaseLiquidityParams memory decreaseParams = INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId : currentTokenId,
            liquidity : liquidity,
            amount0Min : amount0Min,
            amount1Min : amount1Min,
            deadline : block.timestamp
        });

        (amount0, amount1) = positionManager.decreaseLiquidity(decreaseParams);

        collect(amount0, amount1);

        if (!contractCall) {
            //get user element
            UserInfo storage userElement = userMapping[userToDecrease];
            // housekeeping
            userElement.liquidity -= liquidity;

            // if no liquidity we remove user
            if (userElement.liquidity == 0) {
                uint userListLength = userList.length;
                for (uint i = 0; i < userListLength; i++) {
                    if (userList[i] == userToDecrease) {
                        // Move the last element into the place to delete
                        userList[i] = userList[userListLength - 1];
                        // Remove the last element
                        userList.pop();
                        break;
                    }
                }
                isUser[userToDecrease] = false;
            }

            totalLiquidity -= liquidity;

            IYieldManager yieldManager = IYieldManager(IRangeMaster(rangeMaster).getYieldManager());

            // fees
            // get user stats
            (, , uint val3,) = yieldManager.getUserFactors(
                userToDecrease,
                0
            );

            uint mgmtFee0 = (val3 * amount0) / 100 / 100;
            uint sponsorFee0;
            uint mgmtFee1 = (val3 * amount1) / 100 / 100;
            uint sponsorFee1;

            // get sponsor
            address sponsor = yieldManager.getAffiliate(userToDecrease);
            // get sponsor stats
            if (sponsor != address(0)) {
                (, uint sval2,,) = yieldManager
                .getUserFactors(sponsor, 1);
                sponsorFee0 = (mgmtFee0 * sval2) / 100 / 100;
                mgmtFee0 -= sponsorFee0;
                sponsorFee1 = (mgmtFee1 * sval2) / 100 / 100;
                mgmtFee1 -= sponsorFee1;
            }
            // update user mapping
            UserInfo storage userElementOwner = userMapping[owner];

            // send back tokens
            if (token0 == WETH && (amount0 - mgmtFee0 - sponsorFee0 > 0)) {
                payable(userToDecrease).sendValue(amount0 - mgmtFee0 - sponsorFee0);
                userElementOwner.token0Balance += mgmtFee0;

                if (sponsor != address(0) && sponsorFee0 != 0) {
                    payable(sponsor).sendValue(sponsorFee0);
                }
            }
            if (token1 == WETH && (amount1 - mgmtFee1 - sponsorFee1 > 0)) {
                payable(userToDecrease).sendValue(amount1 - mgmtFee1 - sponsorFee1);
                userElementOwner.token1Balance += mgmtFee1;

                if (sponsor != address(0) && sponsorFee1 != 0) {
                    payable(sponsor).sendValue(sponsorFee1);
                }
            }
            if (token0 != WETH && amount0 - mgmtFee0 - sponsorFee0 > 0) {
                IERC20(token0).safeTransfer(userToDecrease, amount0 - mgmtFee0 - sponsorFee0);
                userElementOwner.token0Balance += mgmtFee0;

                if (sponsor != address(0) && sponsorFee0 != 0) {
                    IERC20(token0).safeTransfer(sponsor, sponsorFee0);
                }
            }
            if (token1 != WETH && amount1 - mgmtFee1 - sponsorFee1 > 0) {
                IERC20(token1).safeTransfer(userToDecrease, amount1 - mgmtFee1 - sponsorFee1);
                userElementOwner.token1Balance += mgmtFee1;
                if (sponsor != address(0) && sponsorFee1 != 0) {
                    IERC20(token1).safeTransfer(sponsor, sponsorFee1);
                }
            }
        }

        // if rewards are active
        if (address(masterChef) != address(0)) {
            //send to stake in masterChef
            IERC721(positionManager).safeTransferFrom(address(this), address(masterChef), currentTokenId);
        }

        emit RemovedLiquidity(amount0, amount1, liquidity, userToDecrease);
    }

    /// function for handling the cake rewards
    /// @dev allocates cake token rewards
    /// @param amount the amount how much token we got
    function updateUserCakeBalance(uint amount) internal {
        require(totalLiquidity != 0, "totalLiquidity divisor is zero");

        if(amount == 0) {
            return;
        }

        // get owner
        UserInfo storage ownerUserElement = userMapping[owner];
        IYieldManager yieldManager = IYieldManager(IRangeMaster(rangeMaster).getYieldManager());

        // check for every user and allocate fee rewards
        uint userListLength = userList.length;
        for (uint i = 0; i < userListLength; i++) {
            UserInfo storage userElement = userMapping[userList[i]];

            uint cakeTokenShare = amount * userElement.liquidity / totalLiquidity;

            (, uint val2,,) = yieldManager.getUserFactors(
                userList[i],
                0
            );

            uint perfFeeCake = (val2 * cakeTokenShare) / 100 / 100;
            uint sPerfFeeCake;

            // sponsor lookup
            address sponsor = yieldManager.getAffiliate(userList[i]);

            // get sponsor stats
            if (sponsor != address(0)) {
                (uint sval1,,,) = yieldManager
                    .getUserFactors(sponsor, 1);
                sPerfFeeCake = (perfFeeCake * sval1) / 100 / 100;
                perfFeeCake -= sPerfFeeCake;

                // get sponsor
                UserInfo storage sponsorElement = userMapping[sponsor];
                sponsorElement.cakeTokenBalance += sPerfFeeCake;
            }

            // allocate performance fee
            ownerUserElement.cakeTokenBalance += sPerfFeeCake;
            userElement.cakeTokenBalance += cakeTokenShare - perfFeeCake - sPerfFeeCake;
        }
    }

    /// function for handling the collect
    /// @dev collects from a public address, can be called by anyone - used to collect fees
    /// @return amount0 the amount how much token0 we got as fees
    /// @return amount1 the amount how much token1 we got as fees
    function publicCollect() external nonReentrant returns
    (
        uint256 amount0,
        uint256 amount1
    )
    {
        // if rewards are active
        if (address(masterChef) == address(0)) {
            // redeem token
            uint rewards = masterChef.withdraw(currentTokenId, address(this));

            if (rewards > 0) {
                updateUserCakeBalance(rewards);
            }
        }

        (amount0, amount1) = collect(0, 0);

        // if rewards are active
        if (address(masterChef) == address(0)) {
            //send to stake in masterChef
            IERC721(positionManager).safeTransferFrom(address(this), address(masterChef), currentTokenId);
        }
    }

    /// function for handling the collect from the position manager contract
    /// @dev collects the accrued fees from the position manager contract and withdraws them to this contract
    /// @param decrease0 the amount how much token0 are currently in the contract after a decrease
    /// @param decrease0 the amount how much token1 are currently in the contract after a decrease
    /// @return amount0 the amount how much token0 we got as fees
    /// @return amount1 the amount how much token1 we got as fees
    function collect(uint decrease0, uint decrease1) internal returns
    (
        uint256 amount0,
        uint256 amount1
    )
    {
        // prepare collect params
        INonfungiblePositionManager.CollectParams memory collectParams = INonfungiblePositionManager.CollectParams(
            {
                tokenId : currentTokenId,
                recipient : address(this),
                amount0Max : type(uint128).max,
                amount1Max : type(uint128).max
            }
        );

        (amount0, amount1) = positionManager.collect(collectParams);

        // we need to account the tokens and then account fees
        amount0 -= decrease0;
        amount1 -= decrease1;

        positionManager.unwrapWETH9(0, address(this));

        // convert weth9
        IWETH9(WETH).approve(WETH, 0);
        IWETH9(WETH).approve(WETH, IERC20(WETH).balanceOf(address(this)));
        IWETH9(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));

        // sweep the remaining tokens
        positionManager.sweepToken(token0, 0, address(this));
        positionManager.sweepToken(token1, 0, address(this));

        // get owner
        UserInfo storage ownerUserElement = userMapping[owner];

        require(totalLiquidity != 0, "totalLiquidity divisor is zero");

        // check for every user and allocate fee rewards
        uint userListLength = userList.length;
        IYieldManager yieldManager = IYieldManager(IRangeMaster(rangeMaster).getYieldManager());

        for (uint i = 0; i < userListLength; i++) {
            UserInfo storage userElement = userMapping[userList[i]];

            uint share0 = amount0 * userElement.liquidity / totalLiquidity;
            uint share1 = amount1 * userElement.liquidity / totalLiquidity;

            (, uint val2,,) = yieldManager.getUserFactors(
                userList[i],
                0
            );

            uint perfFee0 = (val2 * share0) / 100 / 100;
            uint sPerfFee0;

            uint perfFee1 = (val2 * share1) / 100 / 100;
            uint sPerfFee1;

            // sponsor lookup
            address sponsor = yieldManager.getAffiliate(userList[i]);

            // get sponsor stats
            if (sponsor != address(0)) {
                (uint sval1,,,) = yieldManager
                    .getUserFactors(sponsor, 1);
                sPerfFee0 = (perfFee0 * sval1) / 100 / 100;
                perfFee0 -= sPerfFee0;
                sPerfFee1 = (perfFee1 * sval1) / 100 / 100;
                perfFee1 -= sPerfFee1;

                // get sponsor
                UserInfo storage sponsorElement = userMapping[sponsor];
                sponsorElement.token0Balance += sPerfFee0;
                sponsorElement.token1Balance += sPerfFee1;
            }

            // allocate performance fee
            ownerUserElement.token0Balance += perfFee0;
            ownerUserElement.token1Balance += perfFee1;

            userElement.token0Balance += share0 - perfFee0 - sPerfFee0;
            userElement.token1Balance += share1 - perfFee1 - sPerfFee1;

        }
    }

    /// function to collect the accrued fees
    /// @dev used to collect the earned fees from the contract (as a user)
    function userCollect(
        address userToCollect
    )
    external nonReentrant onlyRangeMaster
    {
        // get user
        UserInfo storage userElement = userMapping[userToCollect];
        uint token0Balance = userElement.token0Balance;
        uint token1Balance = userElement.token1Balance;
        uint cakeBalance = userElement.cakeTokenBalance;

        // check if no owner
        if (userToCollect != owner) {
            // send tokens
            if (token0 == WETH && (token0Balance > 0)) {
                payable(userToCollect).sendValue(token0Balance);
            }
            if (token1 == WETH && (token1Balance > 0)) {
                payable(userToCollect).sendValue(token1Balance);
            }
            if (token0 != WETH && token0Balance > 0) {
                IERC20(token0).safeTransfer(userToCollect, token0Balance);
            }
            if (token1 != WETH && token1Balance > 0) {
                IERC20(token1).safeTransfer(userToCollect, token1Balance);
            }
            if (cakeBalance > 0) {
                IERC20(cakeToken).safeTransfer(userToCollect, cakeBalance);
            }
        }
        // user is owner
        else {
            // send tokens
            uint distributorFees0 = token0Balance * distributionFee / 10000;
            uint distributorFees1 = token1Balance * distributionFee / 10000;
            uint distributorFeesCake = cakeBalance * distributionFee / 10000;

            if (token0 == WETH && (token0Balance > 0)) {
                payable(feeReceiver).sendValue(token0Balance - distributorFees0);
                payable(address(feeDistributor)).sendValue(distributorFees0);
            }
            if (token1 == WETH && (token1Balance > 0)) {
                payable(feeReceiver).sendValue(token1Balance - distributorFees1);
                payable(address(feeDistributor)).sendValue(distributorFees0);
            }
            if (token0 != WETH && token0Balance > 0) {
                IERC20(token0).safeTransfer(feeReceiver, token0Balance - distributorFees0);
                feeDistributor.receiveERC20Fees(token0, distributorFees0);
            }
            if (token1 != WETH && token1Balance > 0) {
                IERC20(token1).safeTransfer(feeReceiver, token1Balance - distributorFees1);
                feeDistributor.receiveERC20Fees(token1, distributorFees1);
            }
            if (cakeBalance > 0) {
                IERC20(cakeToken).safeTransfer(feeReceiver, cakeBalance - distributorFeesCake);
                feeDistributor.receiveERC20Fees(cakeToken, distributorFeesCake);
            }
        }

        // set fees to 0 since withdrawn
        userElement.token0Balance = 0;
        userElement.token1Balance = 0;
        userElement.cakeTokenBalance = 0;

        emit FeesWithdrawn(token0Balance, token1Balance, userToCollect);
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address for newOwner");

        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwner() external {
        require(_pendingOwner == msg.sender, "Unauthorized Account");
        owner = _pendingOwner;
        delete _pendingOwner;
        emit NewOwner(owner);
    }

    /**
     * @dev Starts the fee receiver transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function changeFeeReceiver(address newFeeReceiver) external {
        require(newFeeReceiver != address(0), "Zero address for newFeeReceiver");
        require(msg.sender == feeReceiver, "not fee receiver");

        _pendingFeeReceiver = newFeeReceiver;
        emit FeeReceiverTransferStarted(feeReceiver, newFeeReceiver);
    }

    /**
    * @dev The new fee receiver accepts the fee receiver transfer.
     */
    function acceptFeeReceiver() external {
        require(_pendingFeeReceiver == msg.sender, "Unauthorized Account");
        feeReceiver = _pendingFeeReceiver;
        delete _pendingFeeReceiver;
        emit NewFeeReceiver(owner);
    }

    /// sets multiple values
    /// @dev used to set various config values
    /// @param _newPositionManager the new value for _newPositionManager
    function changePositionParameter(address _newPositionManager) external onlyOwner nonReentrant {
        require(_newPositionManager != address(0), "Zero address for _newPositionManager");

        positionManager = INonfungiblePositionManager(_newPositionManager);
        uniswapV3Factory = IUniswapV3Factory(positionManager.factory());
    }

    /// sets the new range master contract
    /// @dev sets the range master
    /// @param _newRangeMaster the new value for _newRangeMaster
    function changeRangeMaster(address _newRangeMaster) external onlyOwner nonReentrant {
        require(_newRangeMaster != address(0), "Zero address for _newPositionManager");
        rangeMaster = _newRangeMaster;
        emit NewRangeMaster(rangeMaster);
    }

    /// sets the tick tickMoveThreshold
    /// @dev sets the value of the tickMoveThreshold
    /// @param _tickMoveThreshold the new value for _tickMoveThreshold
    function setTickMoveThreshold(int24 _tickMoveThreshold) external onlyOwner {
        require(_tickMoveThreshold <= 10000, "_tickMoveThreshold too big");
        tickMoveThreshold = _tickMoveThreshold;
        emit NewTickMoveThreshold(tickMoveThreshold);
    }

    /// sets the locked value
    /// @dev sets the value of isLocked and controls minting and increasing liquidity
    /// @param _locked the new value for _locked
    function setLocked(bool _locked) external onlyOwner {
        isLocked = _locked;
        emit Locked(_locked);
    }

    /// sets the checkMoveRangeDisabled value
    /// @dev sets the value of _checkMoveRangeDisabled and controls moving the range
    /// @param _checkMoveRangeDisabled the new value for _checkMoveRangeDisabled
    function setCheckMoveRangeDisabled(bool _checkMoveRangeDisabled) external onlyOwner {
        checkMoveRangeDisabled = _checkMoveRangeDisabled;
        emit CheckMoveRangeDisabled(_checkMoveRangeDisabled);
    }

    /// sets the move range addresses
    /// @dev sets the value of the addresses which can move the range
    /// @param moveAddress the address to be updated
    /// @param allowed the bool to set
    function setMoveRangeAddress(address moveAddress, bool allowed) external onlyOwner {
        moveRangeAddresses[moveAddress] = allowed;
        emit MoveAddressUpdated(moveAddress, allowed);
    }

    /// sets the newMaxUsers value
    /// @dev sets the value of maxUsers
    /// @param newMaxUsers the new value for newMaxUsers
    function setMaxUsers(uint newMaxUsers) external onlyOwner {
        maxUsers = newMaxUsers;
        emit NewMaxUsers(newMaxUsers);
    }

    /// sets the masterChef value
    /// @dev sets the value of masterChef
    /// @dev if set to address(0) no more rewards
    /// @param newMasterChef the new value for masterChef
    function setMasterChef(address newMasterChef) external onlyOwner {

        masterChef = IMasterChefV3(newMasterChef);
        emit NewMasterChef(address(newMasterChef));
    }

    // default fallback and receive functions
    fallback() external payable {}
    receive() external payable {}
}

interface IAggregatorSwapper {
    function swap(address tokenIn, address tokenOut, uint amountIn, uint slippagePercent, uint24 fee) external payable returns (uint256 amountOut);
    function aggregatorSwap(address tokenIn, address tokenOut, uint amountIn, bytes calldata data) external payable returns (uint256 amountOut);
}