// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IConfigStructures} from "../Global/IConfigStructures.sol";
import {IErrors} from "../Global/IErrors.sol";

interface IDropFactory is IConfigStructures, IErrors {
  /** ====================================================================================================================
   *                                                     EVENTS
   * =====================================================================================================================
   */

  event DefaultMetadropPrimaryShareBasisPointsSet(
    uint256 defaultPrimaryFeeBasisPoints
  );
  event DefaultMetadropRoyaltyBasisPointsSet(
    uint256 defaultMetadropRoyaltyBasisPoints
  );
  event PrimaryFeeOverrideByDropSet(string dropId, uint256 percentage);
  event RoyaltyBasisPointsOverrideByDropSet(
    string dropId,
    uint256 royaltyBasisPoints
  );
  event PlatformTreasurySet(address platformTreasury);
  event TemplateAdded(
    TemplateStatus status,
    uint256 templateNumber,
    uint256 loadedDate,
    address templateAddress,
    string templateDescription
  );
  event TemplateUpdated(
    uint256 templateNumber,
    address oldTemplateAddress,
    address newTemplateAddress
  );
  event TemplateTerminated(uint16 templateNumber);

  event PauseCutOffInDaysSet(uint16 cutOffInDays);
  event SubmissionFeeUpdated(uint256 oldFee, uint256 newFee);
  event DropDeployed(
    string dropId,
    address nftInstance,
    PrimarySaleModuleInstance[],
    address royaltySplitterInstance
  );
  event VRFModeSet(uint8 mode);
  event VRFSubscriptionIdSet(uint64 vrfSubscriptionId_);
  event VRFKeyHashSet(bytes32 vrfKeyHash);
  event VRFCallbackGasLimitSet(uint32 vrfCallbackGasLimit);
  event VRFRequestConfirmationsSet(uint16 vrfRequestConfirmations);
  event VRFNumWordsSet(uint32 vrfNumWords);
  event MetadropOracleAddressSet(address metadropOracleAddress);
  event MessageValidityInSecondsSet(uint256 messageValidityInSeconds);
  event ModuleETHBalancesTransferred(address[] modules);
  event ModuleERC20BalancesTransferred(
    address[] modules,
    address erc20Contract
  );
  event ModulePhaseTimesUpdated(
    address[] modules,
    uint256[] startTimes,
    uint256[] endTimes
  );
  event ModulePhaseMaxSupplysUpdated(address[] modules, uint256[] maxSupplys);
  event ModuleOracleAddressUpdated(address[] modules, address oracle);
  event ModuleAntiSybilOff(address[] modules);
  event ModuleEPSOff(address[] modules);
  event ModuleEPSOn(address[] modules);
  event ModulePublicMintPricesUpdated(
    address[] modules,
    uint256[] publicMintPrice
  );
  event ModuleMerkleRootsUpdated(address[] modules, bytes32[] merkleRoot);
  event AuxCallSucceeded(
    address[] modules,
    uint256 value,
    bytes data,
    uint256 txGas
  );
  event PreviousRootValidityPeriodSet(uint32 validityInSeconds);

  /** ====================================================================================================================
   *                                                    FUNCTIONS
   * =====================================================================================================================
   */

  /** ====================================================================================================================
   *                                                      GETTERS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getPlatformTreasury  return the treasury address (provided as explicit method rather than public var)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return platformTreasury_  Treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPlatformTreasury()
    external
    view
    returns (address platformTreasury_);

  /** ====================================================================================================================
   *                                                 PRIVILEGED ACCESS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFMode    Set VRF source to chainlink (0) or arrng (1)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfMode_    The VRF mode.

   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFMode(uint8 vrfMode_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFSubscriptionId    Set the chainlink subscription id..
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfSubscriptionId_    The VRF subscription that this contract will consume chainlink from.

   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFSubscriptionId(uint64 vrfSubscriptionId_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFKeyHash   Set the chainlink keyhash (gas lane).
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfKeyHash_  The desired VRF keyhash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFKeyHash(bytes32 vrfKeyHash_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFCallbackGasLimit  Set the chainlink callback gas limit
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfCallbackGasLimit_  Callback gas limit
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFCallbackGasLimit(uint32 vrfCallbackGasLimit_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFRequestConfirmations  Set the chainlink number of confirmations required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfRequestConfirmations_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFRequestConfirmations(uint16 vrfRequestConfirmations_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFNumWords  Set the chainlink number of words required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfNumWords_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFNumWords(uint32 vrfNumWords_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMetadropOracleAddress  Set the metadrop trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_   Trusted metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropOracleAddress(address metadropOracleAddress_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMessageValidityInSeconds  Set the validity period of signed messages
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageValidityInSeconds_   Validity period in seconds for messages signed by the trusted oracle
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMessageValidityInSeconds(
    uint256 messageValidityInSeconds_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->PAUSABLE
   * @dev (function) setPauseCutOffInDays    Set the number of days from the start date that a contract can be paused for
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutOffInDays_    Default pause cutoff in days
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPauseCutOffInDays(uint16 pauseCutOffInDays_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setDropFee    Set drop fee (if any)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fee_    New drop fee
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDropFee(uint256 fee_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setPlatformTreasury    Set the platform treasury address
   *
   * Set the address that platform fees will be paid to / can be withdrawn to.
   * Note that this is restricted to the highest authority level, the super
   * admin. Platform admins can trigger a withdrawal to the treasury, but only
   * the default admin can set or alter the treasury address. It is recommended
   * that the default admin is highly secured and restrited e.g. a multi-sig.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformTreasury_    New treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPlatformTreasury(address platformTreasury_) external;

  /** ====================================================================================================================
   *                                                  MODULE MAINTENANCE
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) withdrawETHFromModules   A withdraw function to allow ETH to be withdrawn from n modules to the
   *                                          treasury address set on the factory (this contract)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawETHFromModules(address[] calldata moduleAddresses_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) withdrawERC20FromModules   A withdraw function to allow ERC20s to be withdrawn from n modules to the
   *                                            treasury address set on the modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenContract_         The token contract for withdrawal
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawERC20FromModules(
    address[] calldata moduleAddresses_,
    address tokenContract_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updatePhaseTimesOnModules   Update the phase start and/or end on the provided module(s). Note that
   *                                             sending a 0 means you are NOT updating that time.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param startTimes_            An array of start times
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endTimes_              An array of end times
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updatePhaseTimesOnModules(
    address[] calldata moduleAddresses_,
    uint256[] calldata startTimes_,
    uint256[] calldata endTimes_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updatePhaseMaxSupplyOnModules   Update the phase max supply on the provided module(s)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param maxSupplys_            An array of max supply integers
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updatePhaseMaxSupplyOnModules(
    address[] calldata moduleAddresses_,
    uint256[] calldata maxSupplys_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateMetadropOracleAddressOnModules   Allow platform admin to update trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_        An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_  The new metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateMetadropOracleAddressOnModules(
    address[] calldata moduleAddresses_,
    address metadropOracleAddress_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateAntiSybilOffOnModules     Allow platform admin to turn off anti-sybil protection on modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateAntiSybilOffOnModules(
    address[] calldata moduleAddresses_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateEPSOffOnModules     Allow platform admin to turn off EPS on modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateEPSOffOnModules(address[] calldata moduleAddresses_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateEPSOnOnModules     Allow platform admin to turn on EPS on modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateEPSOnOnModules(address[] calldata moduleAddresses_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->MODULES
   * @dev (function) updatePublicMintPriceOnModules  Update the price per NFT for the specified drops
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_        An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newPublicMintPrices_    An array of the new price per mint
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updatePublicMintPriceOnModules(
    address[] calldata moduleAddresses_,
    uint256[] calldata newPublicMintPrices_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->MODULES
   * @dev (function) updateMerkleRootsOnModules  Set the merkleroot on the specified modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param merkleRoots_           An array of the bytes32 merkle roots to set
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateMerkleRootsOnModules(
    address[] calldata moduleAddresses_,
    bytes32[] calldata merkleRoots_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) pauseDeployedContract   Call pause on deployed contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function pauseDeployedContract(address[] calldata moduleAddresses_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) unpauseDeployedContract   Call unpause on deployed contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function unpauseDeployedContract(
    address[] calldata moduleAddresses_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->AUCTION
   * @dev (function) updateAuctionFinalFloorDetails   set final auction floor details
   *
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param module_                                      An single module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionFloorPrice_                        The floor price at the end of the auction
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionAboveFloorBidQuantity_             Items above the floor price
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionLastFloorPosition_                 The last floor position for the auction
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionRunningTotalAtLastFloorPosition_   Running total at the last floor position
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateAuctionFinalFloorDetails(
    address module_,
    uint80 endAuctionFloorPrice_,
    uint56 endAuctionAboveFloorBidQuantity_,
    uint56 endAuctionLastFloorPosition_,
    uint56 endAuctionRunningTotalAtLastFloorPosition_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) auxCall      Make a previously undefined external call
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param value_                 The value for the auxilliary call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param data_                  The data for the auxilliary call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param txGas_                 The gas for the auxilliary call
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function auxCall(
    address[] calldata moduleAddresses_,
    uint256 value_,
    bytes memory data_,
    uint256 txGas_
  ) external returns (bool success);

  /** ====================================================================================================================
   *                                                 FACTORY BALANCES
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawETH   A withdraw function to allow ETH to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawETH(uint256 amount_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawERC20   A withdraw function to allow ERC20s to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param token_   The contract address of the token being withdrawn
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external;

  /** ====================================================================================================================
   *                                                    VRF SERVER
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) requestVRFRandomness  Get the metadata start position for use on reveal of the calling collection
   * _____________________________________________________________________________________________________________________
   */
  function requestVRFRandomness() external payable;

  /** ====================================================================================================================
   *                                                    TEMPLATES
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) addTemplate  Add a contract to the template library
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param contractAddress_              The address of the deployed contract that will be a template
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateDescription_          The description of the template
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function addTemplate(
    address payable contractAddress_,
    string calldata templateDescription_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) updateTemplate  Update an existing contract in the template library
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateId_                   The Id of the existing template that we are updating
   * ---------------------------------------------------------------------------------------------------------------------
   * @param contractAddress_              The address of the deployed contract that will be the new template
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateTemplate(
    uint256 templateId_,
    address payable contractAddress_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) terminateTemplate  Mark a template as terminated
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateNumber_              The number of the template to be marked as terminated
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function terminateTemplate(uint16 templateNumber_) external;

  /** ====================================================================================================================
   *                                                    DROP CREATION
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createDrop     Create a drop using the stored and approved configuration if called by the address
   *                                that the user has designated as project admin
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @param collectionURIs_                An array of collection URIs (pre-reveal, ipfs and arweave)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param signedMessage_                 The signed message object
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createDrop(
    string calldata dropId_,
    NFTModuleConfig calldata nftModule_,
    PrimarySaleModuleConfig[] calldata primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig calldata royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_,
    string[2] calldata collectionURIs_,
    SignedDropMessageDetails calldata signedMessage_
  ) external payable;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) configHashMatches  Check the passed config against the stored config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @param signedMessage_                 The signed message object
   * ---------------------------------------------------------------------------------------------------------------------
   * @return matches_                      Whether the hash matches (true) or not (false)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function configHashMatches(
    string calldata dropId_,
    NFTModuleConfig calldata nftModule_,
    PrimarySaleModuleConfig[] calldata primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig calldata royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_,
    SignedDropMessageDetails calldata signedMessage_
  ) external view returns (bool matches_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createConfigHash  Create the config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageTimeStamp_              When the message for this config hash was signed
   * ---------------------------------------------------------------------------------------------------------------------
   * @return configHash_                   The bytes32 config hash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createConfigHash(
    string calldata dropId_,
    NFTModuleConfig calldata nftModule_,
    PrimarySaleModuleConfig[] calldata primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig calldata royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_,
    uint256 messageTimeStamp_
  ) external pure returns (bytes32 configHash_);
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

/**
 *
 * @title IConfigStructures.sol. Interface for common config structures used accross the platform
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

interface IConfigStructures {
  enum DropStatus {
    approved,
    deployed,
    cancelled
  }

  enum TemplateStatus {
    live,
    terminated
  }

  // The current status of the mint:
  //   - notEnabled: This type of mint is not part of this drop
  //   - notYetOpen: This type of mint is part of the drop, but it hasn't started yet
  //   - open: it's ready for ya, get in there.
  //   - finished: been and gone.
  //   - unknown: theoretically impossible.
  enum MintStatus {
    notEnabled,
    notYetOpen,
    open,
    finished,
    unknown
  }

  struct SubListConfig {
    uint256 start;
    uint256 end;
    uint256 phaseMaxSupply;
  }

  struct PrimarySaleModuleInstance {
    address instanceAddress;
    string instanceDescription;
  }

  struct NFTModuleConfig {
    uint256 templateId;
    bytes configData;
    bytes vestingData;
  }

  struct PrimarySaleModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct ProjectBeneficiary {
    address payable payeeAddress;
    uint256 payeeShares;
  }

  struct VestingConfig {
    uint256 start;
    uint256 projectUpFrontShare;
    uint256 projectVestedShare;
    uint256 vestingPeriodInDays;
    uint256 vestingCliff;
    ProjectBeneficiary[] projectPayees;
  }

  struct RoyaltySplitterModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct InLifeModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct InLifeModules {
    InLifeModuleConfig[] modules;
  }

  struct NFTConfig {
    uint256 supply;
    string name;
    string symbol;
    bytes32 positionProof;
    bool includePriorPhasesInMintTracking;
    bool singleMetadataCollection;
    uint256 reservedAllocation;
    uint256 assistanceRequestWindowInSeconds;
  }

  struct Template {
    TemplateStatus status;
    uint16 templateNumber;
    uint32 loadedDate;
    address payable templateAddress;
    string templateDescription;
  }

  struct RoyaltyDetails {
    address newRoyaltyPaymentSplitterInstance;
    uint96 royaltyFromSalesInBasisPoints;
  }

  struct SignedDropMessageDetails {
    uint256 messageTimeStamp;
    bytes32 messageHash;
    bytes messageSignature;
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

/**
 *
 * @title IErrors.sol. Interface for error definitions used across the platform
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

interface IErrors {
  enum BondingCurveErrorType {
    OK, //                                                  No error
    INVALID_NUMITEMS, //                                    The numItem value is 0
    SPOT_PRICE_OVERFLOW //                                  The updated spot price doesn't fit into 128 bits
  }

  error AdapterParamsMustBeEmpty(); //                      The adapter parameters on this LZ call must be empty.

  error AddressAlreadySet(); //                             The address being set can only be set once, and is already non-0.

  error AlreadyInitialised(); //                            The contract is already initialised: it cannot be initialised twice!

  error ApprovalCallerNotOwnerNorApproved(); //             The caller must own the token or be an approved operator.

  error ApprovalQueryForNonexistentToken(); //              The token does not exist.

  error AuctionStatusIsNotEnded(); //                       Throw if the action required the auction to be closed, and it isn't.

  error AuctionStatusIsNotOpen(); //                        Throw if the action requires the auction to be open, and it isn't.

  error AuxCallFailed(
    address[] modules,
    uint256 value,
    bytes data,
    uint256 txGas
  ); //                                                     An auxilliary call from the drop factory failed.

  error BalanceQueryForZeroAddress(); //                    Cannot query the balance for the zero address.

  error BidMustBeBelowTheFloorWhenReducingQuantity(); //    Only bids that are below the floor can reduce the quantity of the bid.

  error BidMustBeBelowTheFloorForRefundDuringAuction(); //  Only bids that are below the floor can be refunded during the auction.

  error BondingCurveError(BondingCurveErrorType error); //  An error of the type specified has occured in bonding curve processing.

  error CallerIsNotFactory(); //                            The caller of this function must match the factory address in storage.

  error CallerIsNotFactoryOrProjectOwner(); //              The caller of this function must match the factory address OR project owner address.

  error CallerIsNotTheOwner(); //                           The caller is not the owner of this contract.

  error CallerMustBeLzApp(); //                             The caller must be an LZ application.

  error CallerIsNotPlatformAdmin(address caller); //        The caller of this function must be part of the platformAdmin group.

  error CallerIsNotSuperAdmin(address caller); //           The caller of this function must match the superAdmin address in storage.

  error CannotSetNewOwnerToTheZeroAddress(); //             You can't set the owner of this contract to the zero address (address(0)).

  error CannotSetToZeroAddress(); //                        The corresponding address cannot be set to the zero address (address(0)).

  error CollectionAlreadyRevealed(); //                     The collection is already revealed; you cannot call reveal again.

  error ContractIsPaused(); //                              The call requires the contract to be unpaused, and it is paused.

  error ContractIsNotPaused(); //                           The call required the contract to be paused, and it is NOT paused.

  error DecreasedAllowanceBelowZero(); //                   The request would decrease the allowance below zero, and that is not allowed.

  error DestinationIsNotTrustedSource(); //                 The destination that is being called through LZ has not been set as trusted.

  error GasLimitIsTooLow(); //                              The gas limit for the LayerZero call is too low.

  error IncorrectConfirmationValue(); //                    You need to enter the right confirmation value to call this funtion (usually 69420).

  error IncorrectPayment(); //                              The function call did not include passing the correct payment.

  error InvalidAdapterParams(); //                          The current adapter params for LayerZero on this contract won't work :(.

  error InvalidAddress(); //                                An address being processed in the function is not valid.

  error InvalidEndpointCaller(); //                         The calling address is not a valid LZ endpoint. The LZ endpoint was set at contract creation
  //                                                        and cannot be altered after. Check the address LZ endpoint address on the contract.

  error InvalidMinGas(); //                                 The minimum gas setting for LZ in invalid.

  error InvalidOracleSignature(); //                        The signature provided with the contract call is not valid, either in format or signer.

  error InvalidPayload(); //                                The LZ payload is invalid

  error InvalidReceiver(); //                               The address used as a target for funds is not valid.

  error InvalidSourceSendingContract(); //                  The LZ message is being related from a source contract on another chain that is NOT trusted.

  error InvalidTotalShares(); //                            Total shares must equal 100 percent in basis points.

  error ListLengthMismatch(); //                            Two or more lists were compared and they did not match length.

  error NoTrustedPathRecord(); //                           LZ needs a trusted path record for this to work. What's that, you ask?

  error MaxBidQuantityIs255(); //                           Validation: as we use a uint8 array to track bid positions the max bid quantity is 255.

  error MaxPublicMintAllowanceExceeded(
    uint256 requested,
    uint256 alreadyMinted,
    uint256 maxAllowance
  ); //                                                     The calling address has requested a quantity that would exceed the max allowance.

  error MetadataIsLocked(); //                              The metadata on this contract is locked; it cannot be altered!

  error MetadropFactoryOnlyOncePerReveal(); //              This function can only be called (a) by the factory and, (b) just one time!

  error MetadropModulesOnly(); //                           Can only be called from a metadrop contract.

  error MetadropOracleCannotBeAddressZero(); //             The metadrop Oracle cannot be the zero address (address(0)).

  error MinGasLimitNotSet(); //                             The minimum gas limit for LayerZero has not been set.

  error MintERC2309QuantityExceedsLimit(); //               The `quantity` minted with ERC2309 exceeds the safety limit.

  error MintingIsClosedForever(); //                        Minting is, as the error suggests, so over (and locked forever).

  error MintToZeroAddress(); //                             Cannot mint to the zero address.

  error MintZeroQuantity(); //                              The quantity of tokens minted must be more than zero.

  error NoPaymentDue(); //                                  No payment is due for this address.

  error NoRefundForCaller(); //                             Error thrown when the calling address has no refund owed.

  error NoStoredMessage(); //                               There is no stored message matching the passed parameters.

  error OperationDidNotSucceed(); //                        The operation failed (vague much?).

  error OracleSignatureHasExpired(); //                     A signature has been provided but it is too old.

  error OwnershipNotInitializedForExtraData(); //           The `extraData` cannot be set on an uninitialized ownership slot.

  error OwnerQueryForNonexistentToken(); //                 The token does not exist.

  error ParametersDoNotMatchSignedMessage(); //             The parameters passed with the signed message do not match the message itself.

  error PauseCutOffHasPassed(); //                          The time period in which we can pause has passed; this contract can no longer be paused.

  error PaymentMustCoverPerMintFee(); //                    The payment passed must at least cover the per mint fee for the quantity requested.

  error PermitDidNotSucceed(); //                           The safeERC20 permit failed.

  error PlatformAdminCannotBeAddressZero(); //              We cannot use the zero address (address(0)) as a platformAdmin.

  error PlatformTreasuryCannotBeAddressZero(); //           The treasury address cannot be set to the zero address.

  error ProjectOwnerCannotBeAddressZero(); //               The project owner has to be a non zero address.

  error ProofInvalid(); //                                  The provided proof is not valid with the provided arguments.

  error QuantityExceedsRemainingCollectionSupply(); //      The requested quantity would breach the collection supply.

  error QuantityExceedsRemainingPhaseSupply(); //           The requested quantity would breach the phase supply.

  error QuantityExceedsMaxPossibleCollectionSupply(); //    The requested quantity would breach the maximum trackable supply

  error ReferralIdAlreadyUsed(); //                         This referral ID has already been used; they are one use only.

  error RequestingMoreThanRemainingAllocation(
    uint256 previouslyMinted,
    uint256 requested,
    uint256 remainingAllocation
  ); //                                                     Number of tokens requested for this mint exceeds the remaining allocation (taking the
  //                                                        original allocation from the list and deducting minted tokens).

  error RoyaltyFeeWillExceedSalePrice(); //                 The ERC2981 royalty specified will exceed the sale price.

  error ShareTotalCannotBeZero(); //                        The total of all the shares cannot be nothing.

  error SliceOutOfBounds(); //                              The bytes slice operation was out of bounds.

  error SliceOverflow(); //                                 The bytes slice operation overlowed.

  error SuperAdminCannotBeAddressZero(); //                 The superAdmin cannot be the sero address (address(0)).

  error SupportWindowIsNotOpen(); //                        The project owner has not requested support within the support request expiry window.

  error TemplateCannotBeAddressZero(); //                   The address for a template cannot be address zero (address(0)).

  error TemplateNotFound(); //                              There is no template that matches the passed template Id.

  error ThisMintIsClosed(); //                              It's over (well, this mint is, anyway).

  error TotalSharesMustMatchDenominator(); //               The total of all shares must equal the denominator value.

  error TransferCallerNotOwnerNorApproved(); //             The caller must own the token or be an approved operator.

  error TransferFailed(); //                                The transfer has, you may be surprised to learn, failed.

  error TransferFromIncorrectOwner(); //                    The token must be owned by `from`.

  error TransferToNonERC721ReceiverImplementer(); //        Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.

  error TransferToZeroAddress(); //                         Cannot transfer to the zero address.

  error UnrecognisedVRFMode(); //                           Currently supported VRF modes are 0: chainlink and 1: arrng

  error URIQueryForNonexistentToken(); //                   The token does not exist.

  error ValueExceedsMaximum(); //                           The value sent exceeds the maximum allowed (super useful explanation huh?).

  error VRFCoordinatorCannotBeAddressZero(); //             The VRF coordinator cannot be the zero address (address(0)).
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

/**
 *
 * @title IPausable.sol. Interface for common external implementation of Pausable.sol
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

interface IPausable {
  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) pause    Allow platform admin to pause
   * _____________________________________________________________________________________________________________________
   */
  function pause() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) unpause    Allow platform admin to unpause
   * _____________________________________________________________________________________________________________________
   */
  function unpause() external;
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.19;

import {ILayerZeroUserApplicationConfig} from "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
  // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
  // @param _dstChainId - the destination chain identifier
  // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
  // @param _payload - a custom bytes payload to send to the destination contract
  // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
  // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
  // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
  function send(
    uint16 _dstChainId,
    bytes calldata _destination,
    bytes calldata _payload,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes calldata _adapterParams
  ) external payable;

  // @notice used by the messaging library to publish verified payload
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source contract (as bytes) at the source chain
  // @param _dstAddress - the address on destination chain
  // @param _nonce - the unbound message ordering nonce
  // @param _gasLimit - the gas limit for external contract execution
  // @param _payload - verified payload to send to the destination contract
  function receivePayload(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    address _dstAddress,
    uint64 _nonce,
    uint _gasLimit,
    bytes calldata _payload
  ) external;

  // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  function getInboundNonce(
    uint16 _srcChainId,
    bytes calldata _srcAddress
  ) external view returns (uint64);

  // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
  // @param _srcAddress - the source chain contract address
  function getOutboundNonce(
    uint16 _dstChainId,
    address _srcAddress
  ) external view returns (uint64);

  // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
  // @param _dstChainId - the destination chain identifier
  // @param _userApplication - the user app address on this EVM chain
  // @param _payload - the custom message to send over LayerZero
  // @param _payInZRO - if false, user app pays the protocol fee in native token
  // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
  function estimateFees(
    uint16 _dstChainId,
    address _userApplication,
    bytes calldata _payload,
    bool _payInZRO,
    bytes calldata _adapterParam
  ) external view returns (uint nativeFee, uint zroFee);

  // @notice get this Endpoint's immutable source identifier
  function getChainId() external view returns (uint16);

  // @notice the interface to retry failed message on this Endpoint destination
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  // @param _payload - the payload to be retried
  function retryPayload(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    bytes calldata _payload
  ) external;

  // @notice query if any STORED payload (message blocking) at the endpoint.
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  function hasStoredPayload(
    uint16 _srcChainId,
    bytes calldata _srcAddress
  ) external view returns (bool);

  // @notice query if the _libraryAddress is valid for sending msgs.
  // @param _userApplication - the user app address on this EVM chain
  function getSendLibraryAddress(
    address _userApplication
  ) external view returns (address);

  // @notice query if the _libraryAddress is valid for receiving msgs.
  // @param _userApplication - the user app address on this EVM chain
  function getReceiveLibraryAddress(
    address _userApplication
  ) external view returns (address);

  // @notice query if the non-reentrancy guard for send() is on
  // @return true if the guard is on. false otherwise
  function isSendingPayload() external view returns (bool);

  // @notice query if the non-reentrancy guard for receive() is on
  // @return true if the guard is on. false otherwise
  function isReceivingPayload() external view returns (bool);

  // @notice get the configuration of the LayerZero messaging library of the specified version
  // @param _version - messaging library version
  // @param _chainId - the chainId for the pending config change
  // @param _userApplication - the contract address of the user application
  // @param _configType - type of configuration. every messaging library has its own convention.
  function getConfig(
    uint16 _version,
    uint16 _chainId,
    address _userApplication,
    uint _configType
  ) external view returns (bytes memory);

  // @notice get the send() LayerZero messaging library version
  // @param _userApplication - the contract address of the user application
  function getSendVersion(
    address _userApplication
  ) external view returns (uint16);

  // @notice get the lzReceive() LayerZero messaging library version
  // @param _userApplication - the contract address of the user application
  function getReceiveVersion(
    address _userApplication
  ) external view returns (uint16);
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.19;

interface ILayerZeroReceiver {
  // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
  // @param _srcChainId - the source endpoint identifier
  // @param _srcAddress - the source sending contract address from the source chain
  // @param _nonce - the ordered message nonce
  // @param _payload - the signed payload is the UA bytes has encoded to be sent
  function lzReceive(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    uint64 _nonce,
    bytes calldata _payload
  ) external;
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.19;

interface ILayerZeroUserApplicationConfig {
  // @notice set the configuration of the LayerZero messaging library of the specified version
  // @param _version - messaging library version
  // @param _chainId - the chainId for the pending config change
  // @param _configType - type of configuration. every messaging library has its own convention.
  // @param _config - configuration in the bytes. can encode arbitrary content.
  function setConfig(
    uint16 _version,
    uint16 _chainId,
    uint _configType,
    bytes calldata _config
  ) external;

  // @notice set the send() LayerZero messaging library version to _version
  // @param _version - new messaging library version
  function setSendVersion(uint16 _version) external;

  // @notice set the lzReceive() LayerZero messaging library version to _version
  // @param _version - new messaging library version
  function setReceiveVersion(uint16 _version) external;

  // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
  // @param _srcChainId - the chainId of the source chain
  // @param _srcAddress - the contract address of the source contract at the source chain
  function forceResumeReceive(
    uint16 _srcChainId,
    bytes calldata _srcAddress
  ) external;
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.19;

import {ILayerZeroReceiver} from "../interfaces/ILayerZeroReceiver.sol";
import {ILayerZeroUserApplicationConfig} from "../interfaces/ILayerZeroUserApplicationConfig.sol";
import {IErrors} from "../../IErrors.sol";

interface ILzApp is
  IErrors,
  ILayerZeroReceiver,
  ILayerZeroUserApplicationConfig
{
  event SetPrecrime(address precrime);
  event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
  event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
  event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint256 _minDstGas);
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ILzApp} from "./ILzApp.sol";
import {ILayerZeroEndpoint} from "../interfaces/ILayerZeroEndpoint.sol";
import {BytesLib} from "../util/BytesLib.sol";
import {Ownable} from "../../OZ/Ownable.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Context, ILzApp, Ownable {
  using BytesLib for bytes;

  ILayerZeroEndpoint internal immutable lzEndpoint;
  mapping(uint16 => bytes) private trustedRemoteLookup;
  mapping(uint16 => mapping(uint16 => uint256)) private minDstGasLookup;
  address private precrime;

  constructor(address _endpoint) {
    lzEndpoint = ILayerZeroEndpoint(_endpoint);
  }

  function lzReceive(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    uint64 _nonce,
    bytes calldata _payload
  ) public virtual override {
    // lzReceive must be called by the endpoint for security
    if (_msgSender() != address(lzEndpoint)) {
      _revert(InvalidEndpointCaller.selector);
    }

    bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
    // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
    if (
      !(_srcAddress.length == trustedRemote.length &&
        trustedRemote.length > 0 &&
        keccak256(_srcAddress) == keccak256(trustedRemote))
    ) {
      _revert(InvalidSourceSendingContract.selector);
    }

    _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }

  // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
  function _blockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual;

  function _lzSend(
    uint16 _dstChainId,
    bytes memory _payload,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams,
    uint256 _nativeFee
  ) internal virtual {
    bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];

    if (trustedRemote.length == 0) {
      _revert(DestinationIsNotTrustedSource.selector);
    }

    lzEndpoint.send{value: _nativeFee}(
      _dstChainId,
      trustedRemote,
      _payload,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams
    );
  }

  function _checkGasLimit(
    uint16 _dstChainId,
    uint16 _type,
    bytes memory _adapterParams,
    uint256 _extraGas
  ) internal view virtual {
    uint256 providedGasLimit = _getGasLimit(_adapterParams);
    uint256 minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;

    if (minGasLimit == 0) {
      _revert(MinGasLimitNotSet.selector);
    }

    if (providedGasLimit < minGasLimit) {
      _revert(GasLimitIsTooLow.selector);
    }
  }

  function _getGasLimit(
    bytes memory _adapterParams
  ) internal pure virtual returns (uint256 gasLimit) {
    if (_adapterParams.length < 34) {
      _revert(InvalidAdapterParams.selector);
    }

    assembly {
      gasLimit := mload(add(_adapterParams, 34))
    }
  }

  //---------------------------UserApplication config----------------------------------------
  function getConfig(
    uint16 _version,
    uint16 _chainId,
    address,
    uint256 _configType
  ) external view returns (bytes memory) {
    return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
  }

  // generic config for LayerZero user Application
  function setConfig(
    uint16 _version,
    uint16 _chainId,
    uint256 _configType,
    bytes calldata _config
  ) external override onlyOwner {
    lzEndpoint.setConfig(_version, _chainId, _configType, _config);
  }

  function setSendVersion(uint16 _version) external override onlyOwner {
    lzEndpoint.setSendVersion(_version);
  }

  function setReceiveVersion(uint16 _version) external override onlyOwner {
    lzEndpoint.setReceiveVersion(_version);
  }

  function forceResumeReceive(
    uint16 _srcChainId,
    bytes calldata _srcAddress
  ) external override onlyOwner {
    lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
  }

  // _path = abi.encodePacked(remoteAddress, localAddress)
  // this function set the trusted path for the cross-chain communication
  function setTrustedRemote(
    uint16 _srcChainId,
    bytes calldata _path
  ) external onlyOwner {
    trustedRemoteLookup[_srcChainId] = _path;
    emit SetTrustedRemote(_srcChainId, _path);
  }

  function setTrustedRemoteAddress(
    uint16 _remoteChainId,
    bytes calldata _remoteAddress
  ) external onlyOwner {
    trustedRemoteLookup[_remoteChainId] = abi.encodePacked(
      _remoteAddress,
      address(this)
    );
    emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
  }

  function getTrustedRemoteAddress(
    uint16 _remoteChainId
  ) external view returns (bytes memory) {
    bytes memory path = trustedRemoteLookup[_remoteChainId];
    if (path.length == 0) {
      _revert(NoTrustedPathRecord.selector);
    }

    return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
  }

  function setPrecrime(address _precrime) external onlyOwner {
    precrime = _precrime;
    emit SetPrecrime(_precrime);
  }

  function setMinDstGas(
    uint16 _dstChainId,
    uint16 _packetType,
    uint256 _minGas
  ) external onlyOwner {
    if (_minGas == 0) {
      _revert(InvalidMinGas.selector);
    }

    minDstGasLookup[_dstChainId][_packetType] = _minGas;
    emit SetMinDstGas(_dstChainId, _packetType, _minGas);
  }

  //--------------------------- VIEW FUNCTION ----------------------------------------
  function isTrustedRemote(
    uint16 _srcChainId,
    bytes calldata _srcAddress
  ) external view returns (bool) {
    bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
    return keccak256(trustedSource) == keccak256(_srcAddress);
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

pragma solidity ^0.8.0;

import {LzApp} from "./LzApp.sol";
import {ExcessivelySafeCall} from "../util/ExcessivelySafeCall.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
  using ExcessivelySafeCall for address;

  constructor(address _endpoint) LzApp(_endpoint) {}

  mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
    private failedMessages;

  event MessageFailed(
    uint16 _srcChainId,
    bytes _srcAddress,
    uint64 _nonce,
    bytes _payload,
    bytes _reason
  );
  event RetryMessageSuccess(
    uint16 _srcChainId,
    bytes _srcAddress,
    uint64 _nonce,
    bytes32 _payloadHash
  );

  // overriding the virtual function in LzReceiver
  function _blockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual override {
    (bool success, bytes memory reason) = address(this).excessivelySafeCall(
      gasleft(),
      150,
      abi.encodeWithSelector(
        this.nonblockingLzReceive.selector,
        _srcChainId,
        _srcAddress,
        _nonce,
        _payload
      )
    );
    // try-catch all errors/exceptions
    if (!success) {
      failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
      emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, reason);
    }
  }

  function nonblockingLzReceive(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    uint64 _nonce,
    bytes calldata _payload
  ) public virtual {
    // only internal transaction
    if (_msgSender() != address(this)) {
      _revert(CallerMustBeLzApp.selector);
    }
    _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }

  //@notice override this function
  function _nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual;

  function retryMessage(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    uint64 _nonce,
    bytes calldata _payload
  ) public payable virtual {
    // assert there is message to retry
    bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
    if (payloadHash == bytes32(0)) {
      _revert(NoStoredMessage.selector);
    }
    if (keccak256(_payload) != payloadHash) {
      _revert(InvalidPayload.selector);
    }
    failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
    // execute the message. revert if it fails again
    _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

pragma solidity >=0.5.0;

/**
 * @dev Interface of the ONFT Core standard
 */
interface IONFT721Core {
  event SetUseCustomAdapterParams(bool _useCustomAdapterParams);

  /**
   * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
   * _dstChainId - L0 defined chain id to send tokens too
   * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
   * _tokenId - token Id to transfer
   * _useZro - indicates to use zro to pay L0 fees
   * _adapterParams - flexible bytes array to indicate messaging adapter services in L0
   */
  function estimateSendFee(
    uint16 _dstChainId,
    bytes calldata _toAddress,
    uint256 _tokenId,
    bool _useZro,
    bytes calldata _adapterParams
  ) external view returns (uint256 nativeFee, uint256 zroFee);

  /**
   * @dev send token `_tokenId` to (`_dstChainId`, `_toAddress`) from `_from`
   * `_toAddress` can be any size depending on the `dstChainId`.
   * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
   * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
   */
  function sendFrom(
    address _from,
    uint16 _dstChainId,
    bytes calldata _toAddress,
    uint256 _tokenId,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes calldata _adapterParams
  ) external payable;

  /**
   * @dev Emitted when `_tokenId` are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
   * `_nonce` is the outbound nonce from
   */
  event SendToChain(
    uint16 indexed _dstChainId,
    address indexed _from,
    bytes indexed _toAddress,
    uint256 _tokenId
  );

  /**
   * @dev Emitted when `_tokenId` are sent from `_srcChainId` to the `_toAddress` at this chain. `_nonce` is the inbound nonce.
   */
  event ReceiveFromChain(
    uint16 indexed _srcChainId,
    bytes indexed _srcAddress,
    address indexed _toAddress,
    uint256 _tokenId
  );
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

pragma solidity ^0.8.0;

import {IONFT721Core} from "./IONFT721Core.sol";
import {NonblockingLzApp} from "../../LayerZero/lzApp/NonblockingLzApp.sol";

abstract contract ONFT721Core is NonblockingLzApp, IONFT721Core {
  uint256 private constant NO_EXTRA_GAS = 0;
  uint16 private constant FUNCTION_TYPE_SEND = 1;
  bool private useCustomAdapterParams;

  constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

  function estimateSendFee(
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _tokenId,
    bool _useZro,
    bytes memory _adapterParams
  ) public view virtual override returns (uint256 nativeFee, uint256 zroFee) {
    // mock the payload for send()
    bytes memory payload = abi.encode(_toAddress, _tokenId);
    return
      lzEndpoint.estimateFees(
        _dstChainId,
        address(this),
        payload,
        _useZro,
        _adapterParams
      );
  }

  function sendFrom(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _tokenId,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams
  ) public payable virtual override {
    _send(
      _from,
      _dstChainId,
      _toAddress,
      _tokenId,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams
    );
  }

  function _send(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _tokenId,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams
  ) internal virtual {
    _debitFrom(_from, _dstChainId, _toAddress, _tokenId);

    bytes memory payload = abi.encode(_toAddress, _tokenId);

    if (useCustomAdapterParams) {
      _checkGasLimit(
        _dstChainId,
        FUNCTION_TYPE_SEND,
        _adapterParams,
        NO_EXTRA_GAS
      );
    } else {
      if (_adapterParams.length != 0) {
        _revert(AdapterParamsMustBeEmpty.selector);
      }
    }
    _lzSend(
      _dstChainId,
      payload,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams,
      msg.value
    );

    emit SendToChain(_dstChainId, _from, _toAddress, _tokenId);
  }

  function _nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 /*_nonce*/,
    bytes memory _payload
  ) internal virtual override {
    (bytes memory toAddressBytes, uint256 tokenId) = abi.decode(
      _payload,
      (bytes, uint256)
    );
    address toAddress;
    assembly {
      toAddress := mload(add(toAddressBytes, 20))
    }

    _creditTo(_srcChainId, toAddress, tokenId);

    emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, tokenId);
  }

  function setUseCustomAdapterParams(
    bool _useCustomAdapterParams
  ) external onlyOwner {
    useCustomAdapterParams = _useCustomAdapterParams;
    emit SetUseCustomAdapterParams(_useCustomAdapterParams);
  }

  function _debitFrom(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _tokenId
  ) internal virtual;

  function _creditTo(
    uint16 _srcChainId,
    address _toAddress,
    uint256 _tokenId
  ) internal virtual;
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity 0.8.19;

import {IErrors} from "../../IErrors.sol";

library BytesLib {
  function concat(
    bytes memory _preBytes,
    bytes memory _postBytes
  ) internal pure returns (bytes memory) {
    bytes memory tempBytes;

    assembly {
      // Get a location of some free memory and store it in tempBytes as
      // Solidity does for memory variables.
      tempBytes := mload(0x40)

      // Store the length of the first bytes array at the beginning of
      // the memory for tempBytes.
      let length := mload(_preBytes)
      mstore(tempBytes, length)

      // Maintain a memory counter for the current write location in the
      // temp bytes array by adding the 32 bytes for the array length to
      // the starting location.
      let mc := add(tempBytes, 0x20)
      // Stop copying when the memory counter reaches the length of the
      // first bytes array.
      let end := add(mc, length)

      for {
        // Initialize a copy counter to the start of the _preBytes data,
        // 32 bytes into its memory.
        let cc := add(_preBytes, 0x20)
      } lt(mc, end) {
        // Increase both counters by 32 bytes each iteration.
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } {
        // Write the _preBytes data into the tempBytes memory 32 bytes
        // at a time.
        mstore(mc, mload(cc))
      }

      // Add the length of _postBytes to the current length of tempBytes
      // and store it as the new length in the first 32 bytes of the
      // tempBytes memory.
      length := mload(_postBytes)
      mstore(tempBytes, add(length, mload(tempBytes)))

      // Move the memory counter back from a multiple of 0x20 to the
      // actual end of the _preBytes data.
      mc := end
      // Stop copying when the memory counter reaches the new combined
      // length of the arrays.
      end := add(mc, length)

      for {
        let cc := add(_postBytes, 0x20)
      } lt(mc, end) {
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } {
        mstore(mc, mload(cc))
      }

      // Update the free-memory pointer by padding our last write location
      // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
      // next 32 byte block, then round down to the nearest multiple of
      // 32. If the sum of the length of the two arrays is zero then add
      // one before rounding down to leave a blank 32 bytes (the length block with 0).
      mstore(
        0x40,
        and(
          add(add(end, iszero(add(length, mload(_preBytes)))), 31),
          not(31) // Round down to the nearest 32 bytes.
        )
      )
    }

    return tempBytes;
  }

  function concatStorage(
    bytes storage _preBytes,
    bytes memory _postBytes
  ) internal {
    assembly {
      // Read the first 32 bytes of _preBytes storage, which is the length
      // of the array. (We don't need to use the offset into the slot
      // because arrays use the entire slot.)
      let fslot := sload(_preBytes.slot)
      // Arrays of 31 bytes or less have an even value in their slot,
      // while longer arrays have an odd value. The actual length is
      // the slot divided by two for odd values, and the lowest order
      // byte divided by two for even values.
      // If the slot is even, bitwise and the slot with 255 and divide by
      // two to get the length. If the slot is odd, bitwise and the slot
      // with -1 and divide by two.
      let slength := div(
        and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
        2
      )
      let mlength := mload(_postBytes)
      let newlength := add(slength, mlength)
      // slength can contain both the length and contents of the array
      // if length < 32 bytes so let's prepare for that
      // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
      switch add(lt(slength, 32), lt(newlength, 32))
      case 2 {
        // Since the new array still fits in the slot, we just need to
        // update the contents of the slot.
        // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
        sstore(
          _preBytes.slot,
          // all the modifications to the slot are inside this
          // next block
          add(
            // we can just add to the slot contents because the
            // bytes we want to change are the LSBs
            fslot,
            add(
              mul(
                div(
                  // load the bytes from memory
                  mload(add(_postBytes, 0x20)),
                  // zero all bytes to the right
                  exp(0x100, sub(32, mlength))
                ),
                // and now shift left the number of bytes to
                // leave space for the length in the slot
                exp(0x100, sub(32, newlength))
              ),
              // increase length by the double of the memory
              // bytes length
              mul(mlength, 2)
            )
          )
        )
      }
      case 1 {
        // The stored value fits in the slot, but the combined value
        // will exceed it.
        // get the keccak hash to get the contents of the array
        mstore(0x0, _preBytes.slot)
        let sc := add(keccak256(0x0, 0x20), div(slength, 32))

        // save new length
        sstore(_preBytes.slot, add(mul(newlength, 2), 1))

        // The contents of the _postBytes array start 32 bytes into
        // the structure. Our first read should obtain the `submod`
        // bytes that can fit into the unused space in the last word
        // of the stored array. To get this, we read 32 bytes starting
        // from `submod`, so the data we read overlaps with the array
        // contents by `submod` bytes. Masking the lowest-order
        // `submod` bytes allows us to add that value directly to the
        // stored value.

        let submod := sub(32, slength)
        let mc := add(_postBytes, submod)
        let end := add(_postBytes, mlength)
        let mask := sub(exp(0x100, submod), 1)

        sstore(
          sc,
          add(
            and(
              fslot,
              0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
            ),
            and(mload(mc), mask)
          )
        )

        for {
          mc := add(mc, 0x20)
          sc := add(sc, 1)
        } lt(mc, end) {
          sc := add(sc, 1)
          mc := add(mc, 0x20)
        } {
          sstore(sc, mload(mc))
        }

        mask := exp(0x100, sub(mc, end))

        sstore(sc, mul(div(mload(mc), mask), mask))
      }
      default {
        // get the keccak hash to get the contents of the array
        mstore(0x0, _preBytes.slot)
        // Start copying to the last used word of the stored array.
        let sc := add(keccak256(0x0, 0x20), div(slength, 32))

        // save new length
        sstore(_preBytes.slot, add(mul(newlength, 2), 1))

        // Copy over the first `submod` bytes of the new data as in
        // case 1 above.
        let slengthmod := mod(slength, 32)
        let mlengthmod := mod(mlength, 32)
        let submod := sub(32, slengthmod)
        let mc := add(_postBytes, submod)
        let end := add(_postBytes, mlength)
        let mask := sub(exp(0x100, submod), 1)

        sstore(sc, add(sload(sc), and(mload(mc), mask)))

        for {
          sc := add(sc, 1)
          mc := add(mc, 0x20)
        } lt(mc, end) {
          sc := add(sc, 1)
          mc := add(mc, 0x20)
        } {
          sstore(sc, mload(mc))
        }

        mask := exp(0x100, sub(mc, end))

        sstore(sc, mul(div(mload(mc), mask), mask))
      }
    }
  }

  function slice(
    bytes memory _bytes,
    uint256 _start,
    uint256 _length
  ) internal pure returns (bytes memory) {
    if (_length + 31 < _length) {
      revert IErrors.SliceOverflow();
    }
    // require(_length + 31 >= _length, "1");

    if (_bytes.length < _start + _length) {
      revert IErrors.SliceOutOfBounds();
    }

    // require(_bytes.length >= _start + _length, "2");

    bytes memory tempBytes;

    assembly {
      switch iszero(_length)
      case 0 {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
        tempBytes := mload(0x40)

        // The first word of the slice result is potentially a partial
        // word read from the original array. To read it, we calculate
        // the length of that partial word and start copying that many
        // bytes into the array. The first word we copy will start with
        // data we don't care about, but the last `lengthmod` bytes will
        // land at the beginning of the contents of the new array. When
        // we're done copying, we overwrite the full first word with
        // the actual length of the slice.
        let lengthmod := and(_length, 31)

        // The multiplication in the next line is necessary
        // because when slicing multiples of 32 bytes (lengthmod == 0)
        // the following copy loop was copying the origin's length
        // and then ending prematurely not copying everything it should.
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          // The multiplication in the next line has the same exact purpose
          // as the one above.
          let cc := add(
            add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))),
            _start
          )
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }

        mstore(tempBytes, _length)

        //update free-memory pointer
        //allocating the array padded to 32 bytes like the compiler does now
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      //if we want a zero-length slice let's just return a zero-length array
      default {
        tempBytes := mload(0x40)
        //zero out the 32 bytes slice we are about to return
        //we need to do it because Solidity does not garbage collect
        mstore(tempBytes, 0)

        mstore(0x40, add(tempBytes, 0x20))
      }
    }

    return tempBytes;
  }

  function toAddress(
    bytes memory _bytes,
    uint256 _start
  ) internal pure returns (address) {
    require(_bytes.length >= _start + 20, "A_1");
    address tempAddress;

    assembly {
      tempAddress := div(
        mload(add(add(_bytes, 0x20), _start)),
        0x1000000000000000000000000
      )
    }

    return tempAddress;
  }

  function toUint8(
    bytes memory _bytes,
    uint256 _start
  ) internal pure returns (uint8) {
    require(_bytes.length >= _start + 1, "8_OOB");
    uint8 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x1), _start))
    }

    return tempUint;
  }

  function toUint16(
    bytes memory _bytes,
    uint256 _start
  ) internal pure returns (uint16) {
    require(_bytes.length >= _start + 2, "16_OOB");
    uint16 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x2), _start))
    }

    return tempUint;
  }

  function toUint32(
    bytes memory _bytes,
    uint256 _start
  ) internal pure returns (uint32) {
    require(_bytes.length >= _start + 4, "32_OOB");
    uint32 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x4), _start))
    }

    return tempUint;
  }

  function toUint64(
    bytes memory _bytes,
    uint256 _start
  ) internal pure returns (uint64) {
    require(_bytes.length >= _start + 8, "64_OOB");
    uint64 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x8), _start))
    }

    return tempUint;
  }

  function toUint96(
    bytes memory _bytes,
    uint256 _start
  ) internal pure returns (uint96) {
    require(_bytes.length >= _start + 12, "96_OOB");
    uint96 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0xc), _start))
    }

    return tempUint;
  }

  function toUint128(
    bytes memory _bytes,
    uint256 _start
  ) internal pure returns (uint128) {
    require(_bytes.length >= _start + 16, "128_OOB");
    uint128 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x10), _start))
    }

    return tempUint;
  }

  function toUint256(
    bytes memory _bytes,
    uint256 _start
  ) internal pure returns (uint256) {
    require(_bytes.length >= _start + 32, "256_OOB");
    uint256 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x20), _start))
    }

    return tempUint;
  }

  function toBytes32(
    bytes memory _bytes,
    uint256 _start
  ) internal pure returns (bytes32) {
    require(_bytes.length >= _start + 32, "B32_OOB");
    bytes32 tempBytes32;

    assembly {
      tempBytes32 := mload(add(add(_bytes, 0x20), _start))
    }

    return tempBytes32;
  }

  function equal(
    bytes memory _preBytes,
    bytes memory _postBytes
  ) internal pure returns (bool) {
    bool success = true;

    assembly {
      let length := mload(_preBytes)

      // if lengths don't match the arrays are not equal
      switch eq(length, mload(_postBytes))
      case 1 {
        // cb is a circuit breaker in the for loop since there's
        //  no said feature for inline assembly loops
        // cb = 1 - don't breaker
        // cb = 0 - break
        let cb := 1

        let mc := add(_preBytes, 0x20)
        let end := add(mc, length)

        for {
          let cc := add(_postBytes, 0x20)
          // the next line is the loop condition:
          // while(uint256(mc < end) + cb == 2)
        } eq(add(lt(mc, end), cb), 2) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          // if any of these checks fails then arrays are not equal
          if iszero(eq(mload(mc), mload(cc))) {
            // unsuccess:
            success := 0
            cb := 0
          }
        }
      }
      default {
        // unsuccess:
        success := 0
      }
    }

    return success;
  }

  function equalStorage(
    bytes storage _preBytes,
    bytes memory _postBytes
  ) internal view returns (bool) {
    bool success = true;

    assembly {
      // we know _preBytes_offset is 0
      let fslot := sload(_preBytes.slot)
      // Decode the length of the stored array like in concatStorage().
      let slength := div(
        and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
        2
      )
      let mlength := mload(_postBytes)

      // if lengths don't match the arrays are not equal
      switch eq(slength, mlength)
      case 1 {
        // slength can contain both the length and contents of the array
        // if length < 32 bytes so let's prepare for that
        // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
        if iszero(iszero(slength)) {
          switch lt(slength, 32)
          case 1 {
            // blank the last byte which is the length
            fslot := mul(div(fslot, 0x100), 0x100)

            if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
              // unsuccess:
              success := 0
            }
          }
          default {
            // cb is a circuit breaker in the for loop since there's
            //  no said feature for inline assembly loops
            // cb = 1 - don't breaker
            // cb = 0 - break
            let cb := 1

            // get the keccak hash to get the contents of the array
            mstore(0x0, _preBytes.slot)
            let sc := keccak256(0x0, 0x20)

            let mc := add(_postBytes, 0x20)
            let end := add(mc, mlength)

            // the next line is the loop condition:
            // while(uint256(mc < end) + cb == 2)
            for {

            } eq(add(lt(mc, end), cb), 2) {
              sc := add(sc, 1)
              mc := add(mc, 0x20)
            } {
              if iszero(eq(sload(sc), mload(mc))) {
                // unsuccess:
                success := 0
                cb := 0
              }
            }
          }
        }
      }
      default {
        // unsuccess:
        success := 0
      }
    }

    return success;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.19;

library ExcessivelySafeCall {
  uint256 private constant LOW_28_MASK =
    0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  /// @notice Use when you _really_ really _really_ don't trust the called
  /// contract. This prevents the called contract from causing reversion of
  /// the caller in as many ways as we can.
  /// @dev The main difference between this and a solidity low-level call is
  /// that we limit the number of bytes that the callee can cause to be
  /// copied to caller memory. This prevents stupid things like malicious
  /// contracts returning 10,000,000 bytes causing a local OOG when copying
  /// to memory.
  /// @param _target The address to call
  /// @param _gas The amount of gas to forward to the remote contract
  /// @param _maxCopy The maximum number of bytes of returndata to copy
  /// to memory.
  /// @param _calldata The data to send to the remote contract
  /// @return success and returndata, as `.call()`. Returndata is capped to
  /// `_maxCopy` bytes.
  function excessivelySafeCall(
    address _target,
    uint256 _gas,
    uint16 _maxCopy,
    bytes memory _calldata
  ) internal returns (bool, bytes memory) {
    // set up for assembly call
    uint256 _toCopy;
    bool _success;
    bytes memory _returnData = new bytes(_maxCopy);
    // dispatch message to recipient
    // by assembly calling "handle" function
    // we call via assembly to avoid memcopying a very large returndata
    // returned by a malicious contract
    assembly {
      _success := call(
        _gas, // gas
        _target, // recipient
        0, // ether value
        add(_calldata, 0x20), // inloc
        mload(_calldata), // inlen
        0, // outloc
        0 // outlen
      )
      // limit our copy to 256 bytes
      _toCopy := returndatasize()
      if gt(_toCopy, _maxCopy) {
        _toCopy := _maxCopy
      }
      // Store the length of the copied bytes
      mstore(_returnData, _toCopy)
      // copy the bytes from returndata[0:_toCopy]
      returndatacopy(add(_returnData, 0x20), 0, _toCopy)
    }
    return (_success, _returnData);
  }

  /// @notice Use when you _really_ really _really_ don't trust the called
  /// contract. This prevents the called contract from causing reversion of
  /// the caller in as many ways as we can.
  /// @dev The main difference between this and a solidity low-level call is
  /// that we limit the number of bytes that the callee can cause to be
  /// copied to caller memory. This prevents stupid things like malicious
  /// contracts returning 10,000,000 bytes causing a local OOG when copying
  /// to memory.
  /// @param _target The address to call
  /// @param _gas The amount of gas to forward to the remote contract
  /// @param _maxCopy The maximum number of bytes of returndata to copy
  /// to memory.
  /// @param _calldata The data to send to the remote contract
  /// @return success and returndata, as `.call()`. Returndata is capped to
  /// `_maxCopy` bytes.
  function excessivelySafeStaticCall(
    address _target,
    uint256 _gas,
    uint16 _maxCopy,
    bytes memory _calldata
  ) internal view returns (bool, bytes memory) {
    // set up for assembly call
    uint256 _toCopy;
    bool _success;
    bytes memory _returnData = new bytes(_maxCopy);
    // dispatch message to recipient
    // by assembly calling "handle" function
    // we call via assembly to avoid memcopying a very large returndata
    // returned by a malicious contract
    assembly {
      _success := staticcall(
        _gas, // gas
        _target, // recipient
        add(_calldata, 0x20), // inloc
        mload(_calldata), // inlen
        0, // outloc
        0 // outlen
      )
      // limit our copy to 256 bytes
      _toCopy := returndatasize()
      if gt(_toCopy, _maxCopy) {
        _toCopy := _maxCopy
      }
      // Store the length of the copied bytes
      mstore(_returnData, _toCopy)
      // copy the bytes from returndata[0:_toCopy]
      returndatacopy(add(_returnData, 0x20), 0, _toCopy)
    }
    return (_success, _returnData);
  }

  /**
   * @notice Swaps function selectors in encoded contract calls
   * @dev Allows reuse of encoded calldata for functions with identical
   * argument types but different names. It simply swaps out the first 4 bytes
   * for the new selector. This function modifies memory in place, and should
   * only be used with caution.
   * @param _newSelector The new 4-byte selector
   * @param _buf The encoded contract args
   */
  function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
    require(_buf.length >= 4);
    uint256 _mask = LOW_28_MASK;
    assembly {
      // load the first word of
      let _word := mload(add(_buf, 0x20))
      // mask out the top 4 bytes
      // /x
      _word := and(_word, _mask)
      _word := or(_newSelector, _word)
      mstore(add(_buf, 0x20), _word)
    }
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)
// Metadrop based on OpenZeppelin Contracts (last updated v4.9.0) (token/common/ERC2981.sol)

pragma solidity 0.8.19;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165, ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IErrors} from "../IErrors.sol";
import {Revert} from "../Revert.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IErrors, IERC2981, ERC165, Revert {
  struct RoyaltyInfo {
    address receiver;
    uint96 royaltyFraction;
  }

  RoyaltyInfo private _defaultRoyaltyInfo;
  mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(IERC165, ERC165) returns (bool) {
    return
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @inheritdoc IERC2981
   */
  function royaltyInfo(
    uint256 tokenId,
    uint256 salePrice
  ) public view virtual returns (address, uint256) {
    RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];

    if (royalty.receiver == address(0)) {
      royalty = _defaultRoyaltyInfo;
    }

    uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) /
      _feeDenominator();

    return (royalty.receiver, royaltyAmount);
  }

  /**
   * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
   * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
   * override.
   */
  function _feeDenominator() internal pure virtual returns (uint96) {
    return 10000;
  }

  /**
   * @dev Sets the royalty information that all ids in this contract will default to.
   *
   * Requirements:
   *
   * - `receiver` cannot be the zero address.
   * - `feeNumerator` cannot be greater than the fee denominator.
   */
  function _setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) internal virtual {
    if (feeNumerator > _feeDenominator()) {
      _revert(RoyaltyFeeWillExceedSalePrice.selector);
    }
    if (receiver == address(0)) {
      _revert(InvalidReceiver.selector);
    }

    _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
  }

  /**
   * @dev Removes default royalty information.
   */
  function _deleteDefaultRoyalty() internal virtual {
    delete _defaultRoyaltyInfo;
  }

  /**
   * @dev Sets the royalty information for a specific token id, overriding the global default.
   *
   * Requirements:
   *
   * - `receiver` cannot be the zero address.
   * - `feeNumerator` cannot be greater than the fee denominator.
   */
  function _setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) internal virtual {
    if (feeNumerator > _feeDenominator()) {
      _revert(RoyaltyFeeWillExceedSalePrice.selector);
    }
    if (receiver == address(0)) {
      _revert(InvalidReceiver.selector);
    }

    _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
  }

  /**
   * @dev Resets royalty information for the token id back to the global default.
   */
  function _resetTokenRoyalty(uint256 tokenId) internal virtual {
    delete _tokenRoyaltyInfo[tokenId];
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)
// Metadrop based on OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity 0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IErrors} from "../IErrors.sol";
import {Revert} from "../Revert.sol";

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
abstract contract Ownable is IErrors, Revert, Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {}

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if the sender is not the owner.
   */
  function _checkOwner() internal view virtual {
    if (owner() != _msgSender()) {
      _revert(CallerIsNotTheOwner.selector);
    }
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby disabling any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    if (newOwner == address(0)) {
      _revert(CannotSetNewOwnerToTheZeroAddress.selector);
    }
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)
// Metadrop based on OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IErrors} from "../IErrors.sol";

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
    _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
  }

  /**
   * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
   * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
   */
  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeCall(token.transferFrom, (from, to, value))
    );
  }

  /**
   * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
   * non-reverting calls are assumed to be successful.
   */
  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 oldAllowance = token.allowance(address(this), spender);
    forceApprove(token, spender, oldAllowance + value);
  }

  /**
   * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
   * non-reverting calls are assumed to be successful.
   */
  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      if (oldAllowance < value) {
        revert IErrors.DecreasedAllowanceBelowZero();
      }
      forceApprove(token, spender, oldAllowance - value);
    }
  }

  /**
   * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
   * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
   * 0 before setting it to a non-zero value.
   */
  function forceApprove(IERC20 token, address spender, uint256 value) internal {
    bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

    if (!_callOptionalReturnBool(token, approvalCall)) {
      _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
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
    if (nonceAfter != (nonceBefore + 1)) {
      revert IErrors.PermitDidNotSucceed();
    }
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

    bytes memory returndata = address(token).functionCall(data, "call fail");
    if ((returndata.length != 0) && !abi.decode(returndata, (bool))) {
      revert IErrors.OperationDidNotSucceed();
    }
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   *
   * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
   */
  function _callOptionalReturnBool(
    IERC20 token,
    bytes memory data
  ) private returns (bool) {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
    // and not revert is the subcall reverts.

    (bool success, bytes memory returndata) = address(token).call(data);
    return
      success &&
      (returndata.length == 0 || abi.decode(returndata, (bool))) &&
      address(token).code.length > 0;
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

/**
 *
 * @title Revert.sol. For efficient reverts
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

abstract contract Revert {
  /**
   * @dev For more efficient reverts.
   */
  function _revert(bytes4 errorSelector) internal pure {
    assembly {
      mstore(0x00, errorSelector)
      revert(0x00, 0x04)
    }
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

/**
 *
 * @title ERC721AM.sol. Metadrop implementation of ERC721A
 *
 * CREDIT: Small modifications on ERC721A from Chiru Labs, ERC721A Contracts v4.2.3, to allow:
 *         - deployment of minimal contract clones (e.g. including initialise)
 *         - allow mint phase tracking
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import {IERC721AM} from "./IERC721AM.sol";
import {IErrors} from "../Global/IErrors.sol";
import {Revert} from "../Global/Revert.sol";

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

/**
 * @title ERC721AM
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AM is IERC721AM, IErrors, Revert {
  // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
  struct TokenApprovalRef {
    address value;
  }

  // =============================================================
  //                           CONSTANTS
  // =============================================================

  // Mask of an entry in packed address data.
  uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

  // The bit position of `numberMinted` in packed address data.
  uint256 private constant _BITPOS_NUMBER_MINTED = 64;

  // The bit position of `numberBurned` in packed address data.
  uint256 private constant _BITPOS_NUMBER_BURNED = 128;

  // The bit position of `aux` in packed address data.
  uint256 private constant _BITPOS_AUX = 192;

  // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
  uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

  // The bit position of `startTimestamp` in packed ownership.
  uint256 private constant _BITPOS_START_TIMESTAMP = 160;

  // The bit mask of the `burned` bit in packed ownership.
  uint256 private constant _BITMASK_BURNED = 1 << 224;

  // The bit position of the `nextInitialized` bit in packed ownership.
  uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

  // The bit mask of the `nextInitialized` bit in packed ownership.
  uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

  // The bit position of `extraData` in packed ownership.
  uint256 private constant _BITPOS_EXTRA_DATA = 232;

  // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
  uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

  // The mask of the lower 160 bits for addresses.
  uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

  // The `Transfer` event signature is given by:
  // `keccak256(bytes("Transfer(address,address,uint256)"))`.
  bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
    0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

  // =============================================================
  //                            STORAGE
  // =============================================================

  // Track the tokens minted for the collection [0] and by phase [1 to 39].
  uint32[40] internal currentIndexes;

  // Do we track number of mints for just this phase or include all mints up to this phase:
  /**
   *      If our phase allowance is against ALL previous minting we set this to TRUE and we will compare
   *      phase allowance with thetotal collection quantity minted. If it is just for this phase we set this to
   *      FALSE and look at the number of mints in just this phase.
   *
   *      An example:
   *      We have three phases and a total collection supply of 100. We have the following allowances per phase,
   *      with each phase setup to track only that phases allowance: (i.e. this parameter is FALSE).
   *        - phase 1: 50
   *        - phase 2: 25
   *        - phase 3: 25
   *
   *      In phase 1 we mint 40 NFTs. In phase 2, the most we can mint is 25. The fact that phase 1 minted
   *      10 less than it's allowance isn't taken into consideration.
   *
   *      Alternatively, we could setup the mint to track phase allowances based on the total collection
   *      minted quantity. (i.e. this parameter is TRUE).
   *      To achieve the same general effect as the above we could then set these limits:
   *        - phase 1: 50
   *        - phase 2: 75
   *        - phase 3: 100
   *
   *      As with the above, we are allowing phase 2 to mint 25 NFTs in addition to the 50 in phase 1, BUT
   *      if phase 1 mints fewer than 50 phase 2 can soak up this allowance. If we mint just 40 in phase 1, phase 2
   *      can still mint up to a total collection size of 75, therefore we can mint 35 NFTs in that phase.
   *
   *      Likewise phase 3 can always mint out the collection, whatever has occured in phase 1 and 2.
   */
  bool private includePriorPhasesInMintTracking;

  // The max supply for this collection:
  uint80 public maxSupply;

  // The portion of supply making up the reserved allocation:
  uint80 private _reservedAllocation;

  // The number of mints from the reservedAllocation:
  uint80 private _reservedAllocationMinted;

  // The number of tokens burned.
  uint256 private _burnCounter;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned.
  // See {_packedOwnershipOf} implementation for details.
  //
  // Bits Layout:
  // - [0..159]   `addr`
  // - [160..223] `startTimestamp`
  // - [224]      `burned`
  // - [225]      `nextInitialized`
  // - [232..255] `extraData`
  mapping(uint256 => uint256) private _packedOwnerships;

  // Mapping owner address to address data.
  //
  // Bits Layout:
  // - [0..63]    `balance`
  // - [64..127]  `numberMinted`
  // - [128..191] `numberBurned`
  // - [192..255] `aux`
  mapping(address => uint256) private _packedAddressData;

  // Mapping from token ID to approved address.
  mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /** ====================================================================================================================
   *                                                   INTIIALISE
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) _initialiseERC721AM  Load configuration into storage for a new instance.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param name_               The name of the NFT
   * ---------------------------------------------------------------------------------------------------------------------
   * @param symbol_             The symbol of the NFT
   * ---------------------------------------------------------------------------------------------------------------------
   * @param maxSupply_          The maximum supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param includePriorPhasesInMintTracking_   Are we tracking phase allowances by the total collection (true) or on a
   *                                            phase by phase basis (false)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param reservedAllocation_ The amount of NFTs in the reserved allocation for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _initialiseERC721AM(
    string memory name_,
    string memory symbol_,
    uint256 maxSupply_,
    bool includePriorPhasesInMintTracking_,
    uint256 reservedAllocation_
  ) internal {
    _name = name_;
    _symbol = symbol_;
    maxSupply = uint80(maxSupply_);
    _reservedAllocation = uint80(reservedAllocation_);
    includePriorPhasesInMintTracking = includePriorPhasesInMintTracking_;
    currentIndexes[0] = _startTokenId();
  }

  // =============================================================
  //                   TOKEN COUNTING OPERATIONS
  // =============================================================

  /**
   * @dev Returns the starting token ID.
   * To change the starting token ID, please override this function.
   */
  function _startTokenId() internal view virtual returns (uint32) {
    return 1;
  }

  /**
   * @dev Returns the next token ID to be minted.
   */
  function _nextTokenId() internal view virtual returns (uint256) {
    return currentIndexes[0];
  }

  /**
   * @dev Returns the total number of tokens in existence.
   * Burned tokens will reduce the count.
   * To get the total number of tokens minted, please see {_totalMinted}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    // Counter underflow is impossible as _burnCounter cannot be incremented
    // more than `_currentIndex - _startTokenId()` times.
    unchecked {
      return currentIndexes[0] - _burnCounter - _startTokenId();
    }
  }

  /**
   * @dev Returns the total amount of tokens minted in the contract.
   */
  function _totalMinted() internal view virtual returns (uint256) {
    // Counter underflow is impossible as `_currentIndex` does not decrement,
    // and it is initialized to `_startTokenId()`.
    unchecked {
      return currentIndexes[0] - _startTokenId();
    }
  }

  /**
   * @dev Returns the total number of tokens burned.
   */
  function _totalBurned() internal view virtual returns (uint256) {
    return _burnCounter;
  }

  /**
   * @dev Returns the max mintable supply taking into consideration the reserved supply:
   */
  function maxSupplyLessReserve() public view virtual returns (uint256) {
    return maxSupply - (_reservedAllocation - _reservedAllocationMinted);
  }

  // =============================================================
  //                    ADDRESS DATA OPERATIONS
  // =============================================================

  /**
   * @dev Returns the number of tokens in `owner`'s account.
   */
  function balanceOf(
    address owner
  ) public view virtual override returns (uint256) {
    if (owner == address(0)) _revert(BalanceQueryForZeroAddress.selector);
    return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
  }

  /**
   * Returns the number of tokens minted by `owner`.
   */
  function _numberMinted(address owner) internal view returns (uint256) {
    return
      (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) &
      _BITMASK_ADDRESS_DATA_ENTRY;
  }

  /**
   * Returns the number of tokens burned by or on behalf of `owner`.
   */
  function _numberBurned(address owner) internal view returns (uint256) {
    return
      (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) &
      _BITMASK_ADDRESS_DATA_ENTRY;
  }

  /**
   * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
   */
  function _getAux(address owner) internal view returns (uint64) {
    return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
  }

  /**
   * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
   * If there are multiple variables, please pack them into a uint64.
   */
  function _setAux(address owner, uint64 aux) internal virtual {
    uint256 packed = _packedAddressData[owner];
    uint256 auxCasted;
    // Cast `aux` with assembly to avoid redundant masking.
    assembly {
      auxCasted := aux
    }
    packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
    _packedAddressData[owner] = packed;
  }

  // =============================================================
  //                            IERC165
  // =============================================================

  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30000 gas.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override returns (bool) {
    // The interface IDs are constants representing the first 4 bytes
    // of the XOR of all function selectors in the interface.
    // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
    // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
    return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
      interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata
  }

  // =============================================================
  //                        IERC721Metadata
  // =============================================================

  /**
   * @dev Returns the token collection name.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, _toString(tokenId)))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, it can be overridden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  // =============================================================
  //                     OWNERSHIPS OPERATIONS
  // =============================================================

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(
    uint256 tokenId
  ) public view virtual override returns (address) {
    return address(uint160(_packedOwnershipOf(tokenId)));
  }

  /**
   * @dev Gas spent here starts off proportional to the maximum mint batch size.
   * It gradually moves to O(1) as tokens get transferred around over time.
   */
  function _ownershipOf(
    uint256 tokenId
  ) internal view virtual returns (TokenOwnership memory) {
    return _unpackedOwnership(_packedOwnershipOf(tokenId));
  }

  /**
   * @dev Returns the unpacked `TokenOwnership` struct at `index`.
   */
  function _ownershipAt(
    uint256 index
  ) internal view virtual returns (TokenOwnership memory) {
    return _unpackedOwnership(_packedOwnerships[index]);
  }

  /**
   * @dev Returns whether the ownership slot at `index` is initialized.
   * An uninitialized slot does not necessarily mean that the slot has no owner.
   */
  function _ownershipIsInitialized(
    uint256 index
  ) internal view virtual returns (bool) {
    return _packedOwnerships[index] != 0;
  }

  /**
   * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
   */
  function _initializeOwnershipAt(uint256 index) internal virtual {
    if (_packedOwnerships[index] == 0) {
      _packedOwnerships[index] = _packedOwnershipOf(index);
    }
  }

  /**
   * Returns the packed ownership data of `tokenId`.
   */
  function _packedOwnershipOf(
    uint256 tokenId
  ) private view returns (uint256 packed) {
    if (_startTokenId() <= tokenId) {
      packed = _packedOwnerships[tokenId];
      // If the data at the starting slot does not exist, start the scan.
      if (packed == 0) {
        if (tokenId >= currentIndexes[0])
          _revert(OwnerQueryForNonexistentToken.selector);
        // Invariant:
        // There will always be an initialized ownership slot
        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
        // before an uninitialized ownership slot
        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
        // Hence, `tokenId` will not underflow.
        //
        // We can directly compare the packed value.
        // If the address is zero, packed will be zero.
        for (;;) {
          unchecked {
            packed = _packedOwnerships[--tokenId];
          }
          if (packed == 0) continue;
          if (packed & _BITMASK_BURNED == 0) return packed;
          // Otherwise, the token is burned, and we must revert.
          // This handles the case of batch burned tokens, where only the burned bit
          // of the starting slot is set, and remaining slots are left uninitialized.
          _revert(OwnerQueryForNonexistentToken.selector);
        }
      }
      // Otherwise, the data exists and we can skip the scan.
      // This is possible because we have already achieved the target condition.
      // This saves 2143 gas on transfers of initialized tokens.
      // If the token is not burned, return `packed`. Otherwise, revert.
      if (packed & _BITMASK_BURNED == 0) return packed;
    }
    _revert(OwnerQueryForNonexistentToken.selector);
  }

  /**
   * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
   */
  function _unpackedOwnership(
    uint256 packed
  ) private pure returns (TokenOwnership memory ownership) {
    ownership.addr = address(uint160(packed));
    ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
    ownership.burned = packed & _BITMASK_BURNED != 0;
    ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
  }

  /**
   * @dev Packs ownership data into a single uint256.
   */
  function _packOwnershipData(
    address owner,
    uint256 flags
  ) private view returns (uint256 result) {
    assembly {
      // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
      owner := and(owner, _BITMASK_ADDRESS)
      // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
      result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
    }
  }

  /**
   * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
   */
  function _nextInitializedFlag(
    uint256 quantity
  ) private pure returns (uint256 result) {
    // For branchless setting of the `nextInitialized` flag.
    assembly {
      // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
      result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
    }
  }

  // =============================================================
  //                      APPROVAL OPERATIONS
  // =============================================================

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account. See {ERC721A-_approve}.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    _approve(to, tokenId, true);
  }

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(
    uint256 tokenId
  ) public view virtual override returns (address) {
    if (!_exists(tokenId)) _revert(ApprovalQueryForNonexistentToken.selector);

    return _tokenApprovals[tokenId].value;
  }

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom}
   * for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public virtual override {
    _operatorApprovals[_msgSenderERC721A()][operator] = approved;
    emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
  }

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(
    address owner,
    address operator
  ) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted. See {_mint}.
   */
  function _exists(
    uint256 tokenId
  ) internal view virtual returns (bool result) {
    if (_startTokenId() <= tokenId) {
      if (tokenId < currentIndexes[0]) {
        uint256 packed;
        while ((packed = _packedOwnerships[tokenId]) == 0) --tokenId;
        result = packed & _BITMASK_BURNED == 0;
      }
    }
  }

  /**
   * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
   */
  function _isSenderApprovedOrOwner(
    address approvedAddress,
    address owner,
    address msgSender
  ) private pure returns (bool result) {
    assembly {
      // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
      owner := and(owner, _BITMASK_ADDRESS)
      // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
      msgSender := and(msgSender, _BITMASK_ADDRESS)
      // `msgSender == owner || msgSender == approvedAddress`.
      result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
    }
  }

  /**
   * @dev Returns the storage slot and value for the approved address of `tokenId`.
   */
  function _getApprovedSlotAndAddress(
    uint256 tokenId
  )
    private
    view
    returns (uint256 approvedAddressSlot, address approvedAddress)
  {
    TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
    // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
    assembly {
      approvedAddressSlot := tokenApproval.slot
      approvedAddress := sload(approvedAddressSlot)
    }
  }

  // =============================================================
  //                      TRANSFER OPERATIONS
  // =============================================================

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token
   * by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

    // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
    from = address(uint160(uint256(uint160(from)) & _BITMASK_ADDRESS));

    if (address(uint160(prevOwnershipPacked)) != from)
      _revert(TransferFromIncorrectOwner.selector);

    (
      uint256 approvedAddressSlot,
      address approvedAddress
    ) = _getApprovedSlotAndAddress(tokenId);

    // The nested ifs save around 20+ gas over a compound boolean condition.
    if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
      if (!isApprovedForAll(from, _msgSenderERC721A()))
        _revert(TransferCallerNotOwnerNorApproved.selector);

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner.
    assembly {
      if approvedAddress {
        // This is equivalent to `delete _tokenApprovals[tokenId]`.
        sstore(approvedAddressSlot, 0)
      }
    }

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
    unchecked {
      // We can directly increment and decrement the balances.
      --_packedAddressData[from]; // Updates: `balance -= 1`.
      ++_packedAddressData[to]; // Updates: `balance += 1`.

      // Updates:
      // - `address` to the next owner.
      // - `startTimestamp` to the timestamp of transfering.
      // - `burned` to `false`.
      // - `nextInitialized` to `true`.
      _packedOwnerships[tokenId] = _packOwnershipData(
        to,
        _BITMASK_NEXT_INITIALIZED |
          _nextExtraData(from, to, prevOwnershipPacked)
      );

      // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 nextTokenId = tokenId + 1;
        // If the next slot's address is zero and not burned (i.e. packed value is zero).
        if (_packedOwnerships[nextTokenId] == 0) {
          // If the next slot is within bounds.
          if (nextTokenId != currentIndexes[0]) {
            // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
            _packedOwnerships[nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
    uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;
    assembly {
      // Emit the `Transfer` event.
      log4(
        0, // Start of data (0, since no data).
        0, // End of data (0, since no data).
        _TRANSFER_EVENT_SIGNATURE, // Signature.
        from, // `from`.
        toMasked, // `to`.
        tokenId // `tokenId`.
      )
    }
    if (toMasked == 0) _revert(TransferToZeroAddress.selector);

    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token
   * by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement
   * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    transferFrom(from, to, tokenId);
    if (to.code.length != 0)
      if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
        _revert(TransferToNonERC721ReceiverImplementer.selector);
      }
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token IDs
   * are about to be transferred. This includes minting.
   * And also called before burning one token.
   *
   * `startTokenId` - the first token ID to be transferred.
   * `quantity` - the amount to be transferred.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, `tokenId` will be burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token IDs
   * have been transferred. This includes minting.
   * And also called after one token has been burned.
   *
   * `startTokenId` - the first token ID to be transferred.
   * `quantity` - the amount to be transferred.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
   * transferred to `to`.
   * - When `from` is zero, `tokenId` has been minted for `to`.
   * - When `to` is zero, `tokenId` has been burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
   *
   * `from` - Previous owner of the given token ID.
   * `to` - Target address that will receive the token.
   * `tokenId` - Token ID to be transferred.
   * `_data` - Optional data to send along with the call.
   *
   * Returns whether the call correctly returned the expected magic value.
   */
  function _checkContractOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try
      ERC721A__IERC721Receiver(to).onERC721Received(
        _msgSenderERC721A(),
        from,
        tokenId,
        _data
      )
    returns (bytes4 retval) {
      return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        _revert(TransferToNonERC721ReceiverImplementer.selector);
      }
      assembly {
        revert(add(32, reason), mload(reason))
      }
    }
  }

  // =============================================================
  //                        MINT OPERATIONS
  // =============================================================

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` must be greater than 0.
   *
   * Emits a {Transfer} event for each mint.
   */
  function _mint(
    address to,
    uint256 quantity,
    uint256 phaseId,
    uint256 phaseMaxSupply,
    bool reservedAllocationPhase
  ) internal virtual returns (uint256[] memory mintedTokenIds_) {
    (uint256 startTokenId, uint256 endTokenId) = _checksAndEffects(
      quantity,
      phaseId,
      phaseMaxSupply,
      reservedAllocationPhase
    );
    uint256 tokenId = startTokenId;

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    mintedTokenIds_ = new uint256[](quantity);

    // Overflows are incredibly unrealistic.
    // `balance` and `numberMinted` have a maximum limit of 2**64.
    // `tokenId` has a maximum limit of 2**256.
    unchecked {
      // Updates:
      // - `address` to the owner.
      // - `startTimestamp` to the timestamp of minting.
      // - `burned` to `false`.
      // - `nextInitialized` to `quantity == 1`.
      _packedOwnerships[startTokenId] = _packOwnershipData(
        to,
        _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
      );

      // Updates:
      // - `balance += quantity`.
      // - `numberMinted += quantity`.
      //
      // We can directly add to the `balance` and `numberMinted`.
      _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

      // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
      uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;

      if (toMasked == 0) _revert(MintToZeroAddress.selector);

      do {
        uint256 i;
        assembly {
          // Emit the `Transfer` event.
          log4(
            0, // Start of data (0, since no data).
            0, // End of data (0, since no data).
            _TRANSFER_EVENT_SIGNATURE, // Signature.
            0, // `address(0)`.
            toMasked, // `to`.
            tokenId // `tokenId`.
          )
        }
        mintedTokenIds_[i] = tokenId;
        i++;
        // The `!=` check ensures that large values of `quantity`
        // that overflows uint256 will make the loop run out of gas.
      } while (++tokenId != endTokenId);
    }
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
    return (mintedTokenIds_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MINTING
   * @dev (function) _checksAndEffects     Performs checks and effects for minting
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantity_         The quantity of tokens to be minted
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseId_          The ID of this phase
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseMaxSupply_   The max limit for this phase
   * ---------------------------------------------------------------------------------------------------------------------
   * @param reservedAllocationPhase_   This phase draws from the reserved allocation for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _checksAndEffects(
    uint256 quantity_,
    uint256 phaseId_,
    uint256 phaseMaxSupply_,
    bool reservedAllocationPhase_
  ) internal virtual returns (uint256 startTokenId_, uint256 endTokenId_) {
    startTokenId_ = currentIndexes[0];
    if (quantity_ == 0) _revert(MintZeroQuantity.selector);

    if (maxSupply == 0) {
      // Unlimited collection, but limited by the max size that we can track,
      // i.e. a max uint32, therefore 4,294,967,295
      if ((quantity_ + currentIndexes[0]) > type(uint32).max) {
        _revert(QuantityExceedsMaxPossibleCollectionSupply.selector);
      }
    } else {
      if (reservedAllocationPhase_) {
        if (quantity_ > (maxSupply - _totalMinted())) {
          _revert(QuantityExceedsRemainingCollectionSupply.selector);
        }
        _reservedAllocationMinted += uint80(quantity_);
      } else {
        if (quantity_ > (maxSupplyLessReserve() - _totalMinted())) {
          _revert(QuantityExceedsRemainingCollectionSupply.selector);
        }
      }
    }

    // If our phase allowance is against ALL previous minting we need to compare with the
    // total collection quantity minted. If it is just for this phase we look at the number
    // of mints in just this phase.
    //
    // An example:
    // We have three phases and a total collection supply of 100. We have the following allowances per phase,
    // with each phase setup to track only that phases allowance:
    // - phase 1: 50
    // - phase 2: 25
    // - phase 3: 25
    //
    // In phase 1 we mint 40 NFTs. In phase 2, the most we can mint is 25. The fact that phase 1 minted
    // 10 less than it's allowance isn't taken into consideration.
    //
    // Alternatively, we could setup the mint to track phase allowances based on the total collection
    // minted quantity. To achieve the same general effect as the above we could then set these limits:
    // - phase 1: 50
    // - phase 2: 75
    // - phase 3: 100
    //
    // As with the above, we are allowing phase 2 to mint 25 NFTs in addition to the 50 in phase 1, BUT
    // if phase 1 mints fewer than 50 phase 2 can soak up this allowance. If we mint just 40 in phase 1, phase 2
    // can still mint up to a total collection size of 75, therefore we can mint 35 NFTs in that phase.
    //
    // Likewise phase 3 can always mint out the collection, whatever has occured in phase 1 and 2.

    if (phaseMaxSupply_ != 0) {
      uint256 mintCountToTrack;
      if (includePriorPhasesInMintTracking) {
        mintCountToTrack = _totalMinted();
      } else {
        mintCountToTrack = currentIndexes[phaseId_];
      }

      if (
        quantity_ > (phaseMaxSupply_ - mintCountToTrack) ||
        (mintCountToTrack > phaseMaxSupply_)
      ) {
        _revert(QuantityExceedsRemainingPhaseSupply.selector);
      }
    }

    endTokenId_ = startTokenId_ + quantity_;

    currentIndexes[0] = uint32(endTokenId_);
    currentIndexes[phaseId_] += uint32(quantity_);

    return (startTokenId_, endTokenId_);
  }

  /**
   * @dev Safely mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement
   * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
   * - `quantity` must be greater than 0.
   *
   * See {_mint}.
   *
   * Emits a {Transfer} event for each mint.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    uint256 phaseId,
    uint256 phaseMaxSupply,
    bool reservedAllocationPhase,
    bytes memory _data
  ) internal virtual {
    _mint(to, quantity, phaseId, phaseMaxSupply, reservedAllocationPhase);

    unchecked {
      if (to.code.length != 0) {
        uint256 end = currentIndexes[0];
        uint256 index = end - quantity;
        do {
          if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
            _revert(TransferToNonERC721ReceiverImplementer.selector);
          }
        } while (index < end);
        // Reentrancy protection.
        if (currentIndexes[0] != end) _revert(bytes4(0));
      }
    }
  }

  /**
   * @dev Equivalent to `_safeMint(to, quantity, '')`.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    uint256 phaseId,
    uint256 phaseMaxSupply,
    bool reservedAllocationPhase
  ) internal virtual {
    _safeMint(
      to,
      quantity,
      phaseId,
      phaseMaxSupply,
      reservedAllocationPhase,
      ""
    );
  }

  // =============================================================
  //                       APPROVAL OPERATIONS
  // =============================================================

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the
   * zero address clears previous approvals.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    bool approvalCheck
  ) internal virtual {
    address owner = ownerOf(tokenId);

    if (approvalCheck && _msgSenderERC721A() != owner)
      if (!isApprovedForAll(owner, _msgSenderERC721A())) {
        _revert(ApprovalCallerNotOwnerNorApproved.selector);
      }

    _tokenApprovals[tokenId].value = to;
    emit Approval(owner, to, tokenId);
  }

  // =============================================================
  //                        BURN OPERATIONS
  // =============================================================

  /**
   * @dev Burns `tokenId`. See {ERC721A-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public virtual override {
    _burn(tokenId, true);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

    address from = address(uint160(prevOwnershipPacked));

    (
      uint256 approvedAddressSlot,
      address approvedAddress
    ) = _getApprovedSlotAndAddress(tokenId);

    if (approvalCheck) {
      // The nested ifs save around 20+ gas over a compound boolean condition.
      if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
        if (!isApprovedForAll(from, _msgSenderERC721A()))
          _revert(TransferCallerNotOwnerNorApproved.selector);
    }

    _beforeTokenTransfers(from, address(0), tokenId, 1);

    // Clear approvals from the previous owner.
    assembly {
      if approvedAddress {
        // This is equivalent to `delete _tokenApprovals[tokenId]`.
        sstore(approvedAddressSlot, 0)
      }
    }

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
    unchecked {
      // Updates:
      // - `balance -= 1`.
      // - `numberBurned += 1`.
      //
      // We can directly decrement the balance, and increment the number burned.
      // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
      _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

      // Updates:
      // - `address` to the last owner.
      // - `startTimestamp` to the timestamp of burning.
      // - `burned` to `true`.
      // - `nextInitialized` to `true`.
      _packedOwnerships[tokenId] = _packOwnershipData(
        from,
        (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) |
          _nextExtraData(from, address(0), prevOwnershipPacked)
      );

      // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 nextTokenId = tokenId + 1;
        // If the next slot's address is zero and not burned (i.e. packed value is zero).
        if (_packedOwnerships[nextTokenId] == 0) {
          // If the next slot is within bounds.
          if (nextTokenId != currentIndexes[0]) {
            // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
            _packedOwnerships[nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, address(0), tokenId);
    _afterTokenTransfers(from, address(0), tokenId, 1);

    // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
    unchecked {
      _burnCounter++;
    }
  }

  // =============================================================
  //                     EXTRA DATA OPERATIONS
  // =============================================================

  /**
   * @dev Directly sets the extra data for the ownership data `index`.
   */
  function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
    uint256 packed = _packedOwnerships[index];
    if (packed == 0) _revert(OwnershipNotInitializedForExtraData.selector);
    uint256 extraDataCasted;
    // Cast `extraData` with assembly to avoid redundant masking.
    assembly {
      extraDataCasted := extraData
    }
    packed =
      (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) |
      (extraDataCasted << _BITPOS_EXTRA_DATA);
    _packedOwnerships[index] = packed;
  }

  /**
   * @dev Called during each token transfer to set the 24bit `extraData` field.
   * Intended to be overridden by the cosumer contract.
   *
   * `previousExtraData` - the value of `extraData` before transfer.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, `tokenId` will be burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _extraData(
    address from,
    address to,
    uint24 previousExtraData
  ) internal view virtual returns (uint24) {}

  /**
   * @dev Returns the next extra data for the packed ownership data.
   * The returned result is shifted into position.
   */
  function _nextExtraData(
    address from,
    address to,
    uint256 prevOwnershipPacked
  ) private view returns (uint256) {
    uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
    return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
  }

  // =============================================================
  //                       OTHER OPERATIONS
  // =============================================================

  /**
   * @dev Returns the message sender (defaults to `msg.sender`).
   *
   * If you are writing GSN compatible contracts, you need to override this function.
   */
  function _msgSenderERC721A() internal view virtual returns (address) {
    return msg.sender;
  }

  /**
   * @dev Converts a uint256 to its ASCII string decimal representation.
   */
  function _toString(
    uint256 value
  ) internal pure virtual returns (string memory str) {
    assembly {
      // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
      // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
      // We will need 1 word for the trailing zeros padding, 1 word for the length,
      // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
      let m := add(mload(0x40), 0xa0)
      // Update the free memory pointer to allocate.
      mstore(0x40, m)
      // Assign the `str` to the end.
      str := sub(m, 0x20)
      // Zeroize the slot after the string.
      mstore(str, 0)

      // Cache the end of the memory to calculate the length later.
      let end := str

      // We write the string from rightmost digit to leftmost digit.
      // The following is essentially a do-while loop that also handles the zero case.
      // prettier-ignore
      for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

      let length := sub(end, str)
      // Move the pointer 32 bytes leftwards to make room for the length.
      str := sub(str, 0x20)
      // Store the length.
      mstore(str, length)
    }
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

/**
 *
 * @title IERC721AM.sol. Metadrop implementation of IERC721A
 *
 * CREDIT: Small modifications on IERC721A from Chiru Labs, ERC721A Contracts v4.2.3, to allow:
 *         - deployment of minimal contract clones (e.g. including initialise)
 *         - allow mint phase tracking
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721AM {
  // =============================================================
  //                            STRUCTS
  // =============================================================

  struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Stores the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Whether the token has been burned.
    bool burned;
    // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
    uint24 extraData;
  }

  // =============================================================
  //                         TOKEN COUNTERS
  // =============================================================

  /**
   * @dev Returns the total number of tokens in existence.
   * Burned tokens will reduce the count.
   * To get the total number of tokens minted, please see {_totalMinted}.
   */
  function totalSupply() external view returns (uint256);

  // =============================================================
  //                            IERC165
  // =============================================================

  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  // =============================================================
  //                            IERC721
  // =============================================================

  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables or disables
   * (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  /**
   * @dev Returns the max mintable supply taking into consideration the reserved supply:
   */
  function maxSupplyLessReserve() external view returns (uint256);

  /**
   * @dev Returns the number of tokens in `owner`'s account.
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
   * @dev Burns `tokenId`. See {ERC721A-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) external;

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`,
   * checking first that contract recipients are aware of the ERC721 protocol
   * to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move
   * this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement
   * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
   * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) external;

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
   * whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token
   * by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address from, address to, uint256 tokenId) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the
   * zero address clears previous approvals.
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
   * Operators can call {transferFrom} or {safeTransferFrom}
   * for any token owned by the caller.
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
  function getApproved(
    uint256 tokenId
  ) external view returns (address operator);

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(
    address owner,
    address operator
  ) external view returns (bool);

  // =============================================================
  //                        IERC721Metadata
  // =============================================================

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
// Metadrop Contracts (v2.1.0)

/**
 *
 * @title INFTByMetadrop.sol. Interface for metadrop NFT standard
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IConfigStructures} from "../Global/IConfigStructures.sol";

interface INFTByMetadrop is IConfigStructures {
  /** ====================================================================================================================
   *                                                     EVENTS
   * =====================================================================================================================
   */
  event Revealed();
  event RandomNumberReceived(uint256 indexed requestId, uint256 randomNumber);
  event VRFPositionSet(uint256 VRFPosition);
  event PositionProofSet(bytes32 positionProof);
  event MetadropMint(
    address indexed allowanceAddress,
    address indexed recipientAddress,
    address callerAddress,
    address primarySaleModuleAddress,
    uint256 unitPrice,
    uint256[] tokenIds
  );
  event SupportRequested(string supportReason);

  /** ====================================================================================================================
   *                                                    FUNCTIONS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialiseNFT  Load configuration into storage for a new instance.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_            The project owner for this drop. Sets the project admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModules_      The primary sale modules for this drop. These are the contract addresses that are
   *                                 authorised to call mint on this contract.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_               Configuration of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyInfo_             Details of royalties for this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param collectionURIs_          The URIs for this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialiseNFT(
    address projectOwner_,
    PrimarySaleModuleInstance[] calldata primarySaleModules_,
    NFTModuleConfig calldata nftModule_,
    RoyaltyDetails memory royaltyInfo_,
    string[2] calldata collectionURIs_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) metadropCustom  Returns if this contract is a custom NFT (true) or is a standard metadrop
   *                                 ERC721M (false)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isMetadropCustom_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropCustom() external pure returns (bool isMetadropCustom_);

  /** ____________________________________________________________________________________________________________________
   *
   * @dev (function) totalSupply  Returns total supply (minted - burned)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalSupply_   The total supply of this collection (minted - burned)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalSupply() external view returns (uint256 totalSupply_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalUnminted  Returns the remaining unminted supply
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalUnminted_   The total unminted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalUnminted() external view returns (uint256 totalUnminted_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalMinted  Returns the total number of tokens ever minted
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalMinted_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalMinted() external view returns (uint256 totalMinted_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalBurned  Returns the count of tokens sent to the burn address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalBurned_   The total burned supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalBurned() external view returns (uint256 totalBurned_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) phaseMintCount  Number of tokens minted for the queried phase
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return phaseQuantityMinted_   The total minting for this phase
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function phaseMintCount(
    uint256 index_
  ) external view returns (uint256 phaseQuantityMinted_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) setURIs  Set the URI data for this contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param uris_[0]   The URI to use pre-reveal
   * ---------------------------------------------------------------------------------------------------------------------
   * @param uris_[1]    The URI when revealed
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setURIs(string[] calldata uris_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                       -->LOCK MINTING
   * @dev (function) setMintingCompleteForeverCannotBeUndone  Allow project owner to set minting complete
   *
   * _____________________________________________________________________________________________________________________
   */
  function setMintingCompleteForeverCannotBeUndone() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) lockURIsCannotBeUndone  Lock the URI data for this contract
   *
   * _____________________________________________________________________________________________________________________
   */
  function lockURIsCannotBeUndone() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) revealCollection  Set the collection to revealed
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param uris_  The metadata proof
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function revealCollection(string[] calldata uris_) external payable;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) setPositionProof  Set the metadata position proof
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param positionProof_  The metadata proof
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPositionProof(bytes32 positionProof_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) setDefaultRoyalty  Set the royalty percentage
   *
   * @notice - we have specifically NOT implemented the ability to have different royalties on a token by token basis.
   * This reduces the complexity of processing on multi-buys, and also avoids challenges to decentralisation (e.g. the
   * project targetting one users tokens with larger royalties)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_   Royalty receiver
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fraction_   Royalty fraction
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDefaultRoyalty(address recipient_, uint96 fraction_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) deleteDefaultRoyalty  Delete the royalty percentage claimed
   *
   * _____________________________________________________________________________________________________________________
   */
  function deleteDefaultRoyalty() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->SUPPORT
   * @dev (function) requestAssistance  Request assistance. Submitting this transaction unlocks the platform admin
   *                                    functions on the sales modules associated with this NFT. Note, the platform admin
   *                                    has no privilidged access to this NFT, but there are admin methods on the sale
   *                                    modules that they can call IF you provide authorisation by calling this method.
   *
   *                                    This authorisation automatically expires after the support window period
   *                                    (assistanceRequestWindowInSeconds), which is set when this contract is initialised
   *                                    and cannot be changed.
   *
   *                                    Only call this method if you require support from the platform admin and
   *                                    understand what this entails. You must provide a text reason as to your request
   *                                    for support. This reason is emitted on an event from this method
   * _____________________________________________________________________________________________________________________
   */
  function requestAssistance(string memory supportReason_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->SUPPORT
   * @dev (function) assistanceWindowOpen  Returns if the owner of this contract has requested admin assistance using the
   *                                       requestAssistance onlyOwner method on this contract. This value is read by
   *                                       sales modules associated with this NFT to determine if admin support actions
   *                                       can be taken. If the admin support window is not open admin support calls to
   *                                       sale modules cannot be made.
   * _____________________________________________________________________________________________________________________
   */
  function assistanceWindowOpen()
    external
    view
    returns (bool adminAssistanceWindowOpen_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) metadropMint  Mint tokens. Can only be called from a valid primary market contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param caller_                The address that has called mint through the primary sale module.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_             The address that will receive new assets.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param allowanceAddress_      The address that has an allowance being used in this mint. This will be the same as the
   *                               calling address in almost all cases. An example of when they may differ is in a list
   *                               mint where the caller is a delegate of another address with an allowance in the list.
   *                               The caller is performing the mint, but it is the allowance for the allowance address
   *                               that is being checked and decremented in this mint.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_        The quantity of tokens to be minted
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_             The unit price for each token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseId_               The ID of this phase
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseMintLimit_        The max limit for this phase
   * ---------------------------------------------------------------------------------------------------------------------
   * @param reservedAllocationPhase_    If the calling phase draws from a reserved allocation
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropMint(
    address caller_,
    address recipient_,
    address allowanceAddress_,
    uint256 quantityToMint_,
    uint256 unitPrice_,
    uint256 phaseId_,
    uint256 phaseMintLimit_,
    bool reservedAllocationPhase_
  ) external payable;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) fulfillRandomWords  Callback from the chainlinkv2 oracle (on factory) with randomness
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param requestId_      The Id of this request (this contract will submit a single request)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param randomWords_   The random words returned from chainlink
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function fulfillRandomWords(
    uint256 requestId_,
    uint256[] memory randomWords_
  ) external;
}

// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v2.1.0)

/**
 *
 * @title NFTByMetadrop.sol. This contract is the clonable template contract for
 * all metadrop NFT deployments.
 *
 * @author metadrop https://metadrop.com/
 *
 * @notice This contract does not include logic associated with the primary
 * sale of the NFT, that functionality being provided by other contracts within
 * the metadrop platform (e.g. an auction, or a public and list based sale) that
 * form a suite of primary sale modules.
 *
 */

pragma solidity 0.8.19;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer, CANONICAL_CORI_SUBSCRIPTION} from "../ThirdParty/OperatorFilterer/DefaultOperatorFilterer.sol";
import {ERC2981} from "../Global/OZ/ERC2981.sol";
import {ERC721AM} from "./ERC721AM.sol";
import {INFTByMetadrop} from "./INFTByMetadrop.sol";
import {IDropFactory} from "../DropFactory/IDropFactory.sol";
import {PrimaryVestingByMetadrop} from "../PrimaryVesting/PrimaryVestingByMetadrop.sol";
import {ONFT721Core} from "../Global/LayerZero/onft/ONFT721Core.sol";
import {IPrimarySaleModule} from "../PrimarySaleModules/IPrimarySaleModule.sol";
import {EPS4907} from "../ThirdParty/EPS/EPSDelegationRegister/EPS4907.sol";

contract NFTByMetadrop is
  ERC721AM,
  INFTByMetadrop,
  DefaultOperatorFilterer,
  PrimaryVestingByMetadrop,
  ERC2981,
  ONFT721Core,
  EPS4907
{
  using Strings for uint256;

  // Slot 1:
  //    160
  //     32
  //     24
  //      8
  //      8
  //      8
  //      8
  //      8
  // ------
  //    256
  // ------
  //
  // Factory address
  address public factory;
  // The most recent assistance request timestamp (note default is 0):
  uint32 public assistanceRequestTimeStamp;
  // The period of time (in seconds) that an assistance request is open for:
  uint24 public assistanceRequestWindowInSeconds;
  // Bool that controls initialisation and only allows it to occur ONCE. This is
  // needed as this contract is clonable, threfore the constructor is not called
  // on cloned instances. We setup state of this contract through the initialise
  // function.
  bool public initialised;
  // Is metadata locked?:
  bool public metadataLocked;
  // Minting complete confirmation
  bool public mintingComplete;
  // Are we revealed:
  bool public collectionRevealed;
  // Is this a single metadata collection (e.g. an open edition with one json / image):
  bool public singleMetadataCollection;

  //Slots 2 to n: 256
  //
  // URI details:
  string public preRevealURI;
  string public revealedURI;
  // Proof and VRF results for metadata reveal:
  bytes32 public positionProof;
  uint256 public vrfStartPosition;

  // Valid primary market addresses
  mapping(address => bool) public validPrimaryMarketAddress;

  /** ====================================================================================================================
   *                                              CONSTRUCTOR AND INTIIALISE
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                        -->CONSTRUCTOR
   * @dev constructor           The constructor is not called when the contract is cloned. In this
   *                            constructor we just setup default values and set the template contract to initialised.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param epsRegister_        The EPS register address (0x888888888888660F286A7C06cfa3407d09af44B2 on most chains)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param lzEndpoint_         The LZ endpoint for this chain
   *                            (see https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param wethAddress_        WETH address on this chain
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  constructor(
    address epsRegister_,
    address lzEndpoint_,
    address wethAddress_
  )
    PrimaryVestingByMetadrop(wethAddress_)
    ONFT721Core(lzEndpoint_)
    EPS4907(epsRegister_)
  {
    // Initialise this template instance:
    _initialiseERC721AM("", "", 0, false, 0);

    initialised = true;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialiseNFT  Load configuration into storage for a new instance.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_            The project owner for this drop. Sets the project admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModules_      The primary sale modules for this drop. These are the contract addresses that are
   *                                 authorised to call mint on this contract.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_               Configuration of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyInfo_             Details of royalties for this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param collectionURIs_          The URIs for this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialiseNFT(
    address projectOwner_,
    PrimarySaleModuleInstance[] calldata primarySaleModules_,
    NFTModuleConfig calldata nftModule_,
    RoyaltyDetails memory royaltyInfo_,
    string[2] calldata collectionURIs_
  ) public {
    // This clone instance can only be initialised ONCE
    if (initialised) _revert(AlreadyInitialised.selector);
    // Set this clone to initialised
    initialised = true;

    // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
    // will not revert, but the contract will need to be registered with the registry once it is deployed in
    // order for the modifier to filter addresses.
    if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
      OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
        address(this),
        CANONICAL_CORI_SUBSCRIPTION
      );
    }

    _decodeAndSetParams(projectOwner_, nftModule_);

    _initialisePrimaryVesting(nftModule_.vestingData);

    // Load the primary sale modules to the mappings
    for (uint256 i = 0; i < primarySaleModules_.length; ) {
      validPrimaryMarketAddress[primarySaleModules_[i].instanceAddress] = true;
      unchecked {
        i++;
      }
    }

    // Royalty setup
    // If the royalty contract is address(0) then the royalty module
    // has been flagged as not required for this drop.
    // To avoid any possible loss of funds from incorrect configuation we don't
    // set the royalty receiver address to address(0), but rather to the first
    // platform admin
    if (royaltyInfo_.newRoyaltyPaymentSplitterInstance == address(0)) {
      _setDefaultRoyalty(
        projectOwner_,
        royaltyInfo_.royaltyFromSalesInBasisPoints
      );
    } else {
      _setDefaultRoyalty(
        royaltyInfo_.newRoyaltyPaymentSplitterInstance,
        royaltyInfo_.royaltyFromSalesInBasisPoints
      );
    }

    preRevealURI = collectionURIs_[0];
    revealedURI = collectionURIs_[1];

    factory = msg.sender;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) _decodeAndSetParams  Decode NFT Parameters
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_     The project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_        NFT module data
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _decodeAndSetParams(
    address projectOwner_,
    NFTModuleConfig calldata nftModule_
  ) internal {
    // Decode the NFT config
    (
      uint256 decodedSupply,
      string memory decodedName,
      string memory decodedSymbol,
      bytes32 decodedPositionProof,
      bool includePriorPhasesInMintTracking,
      bool singleMetadataCollectionFlag,
      uint256 reservedAllocation,
      uint256 assistanceRequestWindow
    ) = abi.decode(
        nftModule_.configData,
        (uint256, string, string, bytes32, bool, bool, uint256, uint256)
      );

    // Initialise values on ERC721M
    _initialiseERC721AM(
      decodedName,
      decodedSymbol,
      decodedSupply,
      includePriorPhasesInMintTracking,
      reservedAllocation
    );

    singleMetadataCollection = singleMetadataCollectionFlag;
    assistanceRequestWindowInSeconds = uint24(assistanceRequestWindow);

    positionProof = decodedPositionProof;

    _transferOwnership(projectOwner_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->LAYERZERO
   * @dev (function) _debitFrom  debit an item from a holder on layerzero call. While off-chain the NFT is custodied in
   * this contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param from_               The current owner of the asset
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId_            The tokenId being sent via LayerZero
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _debitFrom(
    address from_,
    uint16,
    bytes memory,
    uint256 tokenId_
  ) internal virtual override {
    transferFrom(from_, address(this), tokenId_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->LAYERZERO
   * @dev (function) _creditTo  credit an item to a holder on layerzero call. While off-chain the NFT is custodied in
   * this contract, this transfers it back to the holder
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param toAddress_          The recipient of the asset
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId_            The tokenId that has been sent via LayerZero
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _creditTo(
    uint16,
    address toAddress_,
    uint256 tokenId_
  ) internal virtual override {
    if (!(_exists(tokenId_) && ownerOf(tokenId_) == address(this))) {
      _revert(OwnerQueryForNonexistentToken.selector);
    }

    transferFrom(address(this), toAddress_, tokenId_);
  }

  /** ====================================================================================================================
   *                                            OPERATOR FILTER REGISTRY
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) setApprovalForAll  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param operator            The operator for the approval
   * ---------------------------------------------------------------------------------------------------------------------
   * @param approved            If the operator is approved
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) approve  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param operator            The operator for the approval
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId             The tokenId for this approval
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function approve(
    address operator,
    uint256 tokenId
  ) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) transferFrom  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param from                The sender of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param to                  The recipient of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId             The tokenId for this approval
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) safeTransferFrom  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param from                The sender of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param to                  The recipient of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId             The tokenId for this approval
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) safeTransferFrom  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param from                The sender of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param to                  The recipient of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId             The tokenId for this approval
   * ---------------------------------------------------------------------------------------------------------------------
   * @param data                bytes data accompanying this transfer operation
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  /** ====================================================================================================================
   *                                                 PRIVILEGED ACCESS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                       -->LOCK MINTING
   * @dev (function) setMintingCompleteForeverCannotBeUndone  Allow project owner to set minting complete
   *
   * _____________________________________________________________________________________________________________________
   */
  function setMintingCompleteForeverCannotBeUndone() external onlyOwner {
    mintingComplete = true;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) lockURIsCannotBeUndone  Lock the URI data for this contract
   *
   * _____________________________________________________________________________________________________________________
   */
  function lockURIsCannotBeUndone() external onlyOwner {
    metadataLocked = true;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) setURIs  Set the URI data for this contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param uris_[0]   The URI to use pre-reveal
   * ---------------------------------------------------------------------------------------------------------------------
   * @param uris_[1]   The URI for arweave
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setURIs(string[] calldata uris_) public onlyOwner {
    if (metadataLocked) {
      _revert(MetadataIsLocked.selector);
    }

    preRevealURI = uris_[0];
    revealedURI = uris_[1];
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) revealCollection  Set the collection to revealed
   *
   * _____________________________________________________________________________________________________________________
   */
  function revealCollection(
    string[] calldata uris_
  ) external payable onlyOwner {
    if (collectionRevealed) {
      _revert(CollectionAlreadyRevealed.selector);
    }
    setURIs(uris_);
    if (singleMetadataCollection) {
      // Open edition, no VRF call
      collectionRevealed = true;
      emit Revealed();
    } else {
      // Standard edition. Reveal will occur in fulfillRandomness
      IDropFactory(factory).requestVRFRandomness{value: msg.value}();
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) setPositionProof  Set the metadata position proof
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param positionProof_  The metadata proof
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPositionProof(bytes32 positionProof_) external onlyOwner {
    positionProof = positionProof_;

    emit PositionProofSet(positionProof_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) setDefaultRoyalty  Set the royalty percentage
   *
   * @notice - we have specifically NOT implemented the ability to have different royalties on a token by token basis.
   * This reduces the complexity of processing on multi-buys, and also avoids challenges to decentralisation (e.g. the
   * project targetting one users tokens with larger royalties)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_   Royalty receiver
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fraction_   Royalty fraction
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDefaultRoyalty(
    address recipient_,
    uint96 fraction_
  ) public onlyOwner {
    _setDefaultRoyalty(recipient_, fraction_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) deleteDefaultRoyalty  Delete the royalty percentage claimed
   *
   * _____________________________________________________________________________________________________________________
   */
  function deleteDefaultRoyalty() public onlyOwner {
    _deleteDefaultRoyalty();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->SUPPORT
   * @dev (function) requestAssistance  Request assistance. Submitting this transaction unlocks the platform admin
   *                                    functions on the sales modules associated with this NFT. Note, the platform admin
   *                                    has no privilidged access to this NFT, but there are admin methods on the sale
   *                                    modules that they can call IF you provide authorisation by calling this method.
   *
   *                                    This authorisation automatically expires after the support window period
   *                                    (assistanceRequestWindowInSeconds), which is set when this contract is initialised
   *                                    and cannot be changed.
   *
   *                                    Only call this method if you require support from the platform admin and
   *                                    understand what this entails. You must provide a text reason as to your request
   *                                    for support. This reason is emitted on an event from this method
   * _____________________________________________________________________________________________________________________
   */
  function requestAssistance(string memory supportReason_) public onlyOwner {
    assistanceRequestTimeStamp = uint32(block.timestamp);
    emit SupportRequested(supportReason_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->SUPPORT
   * @dev (function) assistanceWindowOpen  Returns if the owner of this contract has requested admin assistance using the
   *                                       requestAssistance onlyOwner method on this contract. This value is read by
   *                                       sales modules associated with this NFT to determine if admin support actions
   *                                       can be taken. If the admin support window is not open admin support calls to
   *                                       sale modules cannot be made.
   * _____________________________________________________________________________________________________________________
   */
  function assistanceWindowOpen()
    external
    view
    returns (bool adminAssistanceWindowOpen_)
  {
    return
      block.timestamp <=
      assistanceRequestTimeStamp + assistanceRequestWindowInSeconds;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) fulfillRandomWords  Callback from the VRF oracle (on factory) with randomness
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param requestId_      The Id of this request (this contract will submit a single request)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param randomWords_   The random words returned from chainlink
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function fulfillRandomWords(
    uint256 requestId_,
    uint256[] memory randomWords_
  ) external {
    if (msg.sender == factory && !collectionRevealed) {
      unchecked {
        vrfStartPosition = (randomWords_[0] % maxSupply);
      }
      collectionRevealed = true;
      emit RandomNumberReceived(requestId_, randomWords_[0]);
      emit VRFPositionSet(vrfStartPosition);
      emit Revealed();
    } else {
      _revert(MetadropFactoryOnlyOncePerReveal.selector);
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) fallback  Explicitly revert on fallback()
   *
   * _____________________________________________________________________________________________________________________
   */
  fallback() external payable {
    revert();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) receive   Reject eth of unkown source
   * _____________________________________________________________________________________________________________________
   */
  receive() external payable onlyOwner {}

  /** ====================================================================================================================
   *                                             COLLECTION INFORMATION GETTERS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) metadropCustom  Returns if this contract is a custom NFT (true) or is a standard metadrop
   *                                 ERC721M (false)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isMetadropCustom_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropCustom() external pure returns (bool isMetadropCustom_) {
    return (false);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalSupply  Returns total supply (minted - burned)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalSupply_   The total supply of this collection (minted - burned)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalSupply()
    public
    view
    override(ERC721AM, INFTByMetadrop)
    returns (uint256 totalSupply_)
  {
    return super.totalSupply();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalUnminted  Returns the remaining unminted supply
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalUnminted_   The total unminted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalUnminted() public view returns (uint256 totalUnminted_) {
    return maxSupply - _totalMinted();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalMinted  Returns the total number of tokens ever minted
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalMinted_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalMinted() public view returns (uint256 totalMinted_) {
    return _totalMinted();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalBurned  Returns the count of tokens sent to the burn address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalBurned_   The total burned supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalBurned() public view returns (uint256 totalBurned_) {
    return _totalBurned();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) phaseMintCount  Number of tokens minted for the queried phase
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return phaseQuantityMinted_   The total minting for this phase
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function phaseMintCount(
    uint256 index_
  ) external view returns (uint256 phaseQuantityMinted_) {
    return currentIndexes[index_];
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) tokenURI  Returns the URI for the passed token
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return tokenURI_   The token URI
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory tokenURI_) {
    if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

    unchecked {
      if (!collectionRevealed) {
        return preRevealURI;
      } else {
        if (singleMetadataCollection) {
          // single metadata collection, just return the revealed URI:
          return revealedURI;
        } else {
          // Standard edition, append the tokenId:
          return
            string.concat(
              revealedURI,
              ((tokenId + vrfStartPosition) % maxSupply).toString(),
              ".json"
            );
        }
      }
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) supportsInterface   Override is required by Solidity.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return bool    If the interface is supported
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721AM, ERC2981, EPS4907) returns (bool) {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    // - IERC4907: 0xad092b5c
    // - IEPS4907: 0xd50ef07c
    // - IONFT721Core: 0x7bb0080b
    return
      ERC721AM.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId) ||
      EPS4907.supportsInterface(interfaceId) ||
      interfaceId == 0x7bb0080b; // IONFT721Core
  }

  /** ====================================================================================================================
   *                                                    MINTING
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) metadropMint  Mint tokens. Can only be called from a valid primary market contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param caller_                The address that has called mint through the primary sale module.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_             The address that will receive new assets.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param allowanceAddress_      The address that has an allowance being used in this mint. This will be the same as the
   *                               calling address in almost all cases. An example of when they may differ is in a list
   *                               mint where the caller is a delegate of another address with an allowance in the list.
   *                               The caller is performing the mint, but it is the allowance for the allowance address
   *                               that is being checked and decremented in this mint.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_        The quantity of tokens to be minted
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_             The unit price for each token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseId_               The ID of this phase
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseMintLimit_        The max limit for this phase
   * ---------------------------------------------------------------------------------------------------------------------
   * @param reservedAllocationPhase_    If the calling phase draws from a reserved allocation
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropMint(
    address caller_,
    address recipient_,
    address allowanceAddress_,
    uint256 quantityToMint_,
    uint256 unitPrice_,
    uint256 phaseId_,
    uint256 phaseMintLimit_,
    bool reservedAllocationPhase_
  ) external payable {
    if (mintingComplete) {
      _revert(MintingIsClosedForever.selector);
    }

    if (!validPrimaryMarketAddress[msg.sender])
      _revert(InvalidAddress.selector);

    uint256[] memory tokenIds = _mint(
      recipient_,
      quantityToMint_,
      phaseId_,
      phaseMintLimit_,
      reservedAllocationPhase_
    );

    emit MetadropMint(
      allowanceAddress_,
      recipient_,
      caller_,
      msg.sender,
      unitPrice_,
      tokenIds
    );
  }
  /** ====================================================================================================================
   */
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

/**
 *
 * @title IPrimarySaleModule.sol. Interface for base primary sale module contract
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IConfigStructures} from "../Global/IConfigStructures.sol";
import {IPausable} from "../Global/IPausable.sol";
import {IErrors} from "../Global/IErrors.sol";

interface IPrimarySaleModule is IErrors, IConfigStructures, IPausable {
  /** ====================================================================================================================
   *                                                       EVENTS
   * =====================================================================================================================
   */
  event TreasuryAddressUpdated(address oldTreasury, address newTreasury);

  /** ====================================================================================================================
   *                                                      FUNCTIONS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialisePrimarySaleModule  Defined here and must be overriden in child contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param configData_               The drop specific configuration for this module. This is decoded and used to set
   *                                  configuration for this metadrop drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutoffInDays_        The maximum number of days after drop deployment that this contract can be paused
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_    The trusted metadrop signer. This is used with anti-bot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageValidityInSeconds_ The validity period of a signed message. This is used with anti-bot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param previousRootValidityInSeconds_ The validity period of the previous merkle root.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseId_                  The ID of this phase, used for tracking supply
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialisePrimarySaleModule(
    bytes calldata configData_,
    uint256 pauseCutoffInDays_,
    address metadropOracleAddress_,
    uint256 messageValidityInSeconds_,
    uint256 previousRootValidityInSeconds_,
    uint256 phaseId_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) getPhaseStartAndEnd  Get the start and end times for this phase
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return phaseStart_             The phase start time
   * ---------------------------------------------------------------------------------------------------------------------
   * @return phaseEnd_               The phase end time
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPhaseStartAndEnd()
    external
    view
    returns (uint256 phaseStart_, uint256 phaseEnd_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) setPhaseStart  Set the phase start for this drop (platform admin only)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseStart_             The phase start time
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPhaseStart(uint32 phaseStart_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) setPhaseEnd    Set the phase start for this drop (platform admin only)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseEnd_               The phase end time
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPhaseEnd(uint32 phaseEnd_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) setPhaseMaxSupply     Set the phase start for this drop (platform admin only)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseMaxSupply_                The phase supply
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPhaseMaxSupply(uint32 phaseMaxSupply_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->SETUP
   * @dev (function) setNFTAddress    Set the NFT contract for this drop
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftContract_           The deployed NFT contract
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setNFTAddress(address nftContract_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->SETUP
   * @dev (function) phaseMintStatus    The status of the deployed primary sale module
   * _____________________________________________________________________________________________________________________
   */
  function phaseMintStatus() external view returns (MintStatus status);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) transferETHBalanceToTreasury        A transfer function to allow  all ETH to be withdrawn
   *                                                     to vesting.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param treasury_           The treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferETHBalanceToTreasury(address treasury_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) transferERC20BalanceToTreasury     A transfer function to allow ERC20s to be withdrawn to the
   *                                             treasury.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param treasury_          The treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * @param token_             The token to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferERC20BalanceToTreasury(
    address treasury_,
    IERC20 token_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setMetadropOracleAddress   Allow platform admin to update trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_         The new metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropOracleAddress(address metadropOracleAddress_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setAntiSybilOff     Allow platform admin to turn off anti-sybil protection
   * _____________________________________________________________________________________________________________________
   */
  function setAntiSybilOff() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setEPSOff    Allow platform admin to turn off EPS
   * _____________________________________________________________________________________________________________________
   */
  function setEPSOff() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setEPSOff    Allow platform admin to turn ON EPS
   * _____________________________________________________________________________________________________________________
   */
  function setEPSOn() external;
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

/**
 *
 * @title IPrimaryVestingByMetadrop.sol. Interface for base primary vesting module contract
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IConfigStructures} from "../Global/IConfigStructures.sol";
import {IErrors} from "../Global/IErrors.sol";

interface IPrimaryVestingByMetadrop is IErrors, IConfigStructures {
  /** ====================================================================================================================
   *                                                        EVENTS
   * =====================================================================================================================
   */
  event PayeeAdded(
    address account,
    uint256 shares,
    uint256 vestingPeriodInDays
  );
  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  /** ====================================================================================================================
   *                                                      FUNCTIONS
   * =====================================================================================================================
   */

  /**
   * @dev Getter for the total shares held by payees.
   */
  function sharesTotal() external view returns (uint256);

  /**
   * @dev Getter for the amount of shares held by the project that are vested.
   */
  function sharesProjectVested() external view returns (uint256);

  /**
   * @dev Getter for the amount of shares held by the project that are upfront.
   */
  function sharesProjectUpfront() external view returns (uint256);

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function releasedETHTotal() external view returns (uint256);

  /**
   * @dev Getter for the amount of ETH release for the project vested.
   */
  function releasedETHProjectVested() external view returns (uint256);

  /**
   * @dev Getter for the amount of ETH release for the project upfront.
   */
  function releasedETHProjectUpfront() external view returns (uint256);

  /**
   * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
   * contract.
   */
  function releasedERC20Total(IERC20 token) external view returns (uint256);

  /**
   * @dev Getter for the amount of `token` tokens already released to the project vested. `token` should be the address of an
   * IERC20 contract.
   */
  function releasedERC20ProjectVested(
    IERC20 token
  ) external view returns (uint256);

  /**
   * @dev Getter for the amount of `token` tokens already released to the project upfront. `token` should be the address of an
   * IERC20 contract.
   */
  function releasedERC20ProjectUpfront(
    IERC20 token
  ) external view returns (uint256);

  /**
   * @dev Getter for project address
   */
  function projectAddresses()
    external
    view
    returns (ProjectBeneficiary[] memory);

  /**
   * @dev Calculates the amount of ether that has already vested. Default implementation is a linear vesting curve.
   */
  function vestedAmountEth(
    uint256 balance,
    uint256 timestamp
  ) external view returns (uint256);

  /**
   * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
   */
  function vestedAmountERC20(
    uint256 balance,
    uint256 timestamp
  ) external view returns (uint256);

  /**
   * @dev Getter for the amount of project's vested releasable Ether.
   */
  function releasableETHProjectVested() external view returns (uint256);

  /**
   * @dev Getter for the amount of the project's upfront releasable Ether.
   */
  function releasableETHProjectUpfront() external view returns (uint256);

  /**
   * @dev Getter for the amount of project's vested releasable `token` tokens. `token` should be the address of an
   * IERC20 contract.
   */
  function releasableERC20ProjectVested(
    IERC20 token
  ) external view returns (uint256);

  /**
   * @dev Getter for the amount of project's releasable upfront `token` tokens. `token` should be the address of an
   * IERC20 contract.
   */
  function releasableERC20ProjectUpfront(
    IERC20 token
  ) external view returns (uint256);

  /**
   * @dev Triggers a transfer to the project of the amount of Ether they are owed, according to their percentage of the
   * total shares and their previous withdrawals.
   */
  function releaseProjectETH(uint256 gasLimit_) external;

  /**
   * @dev Triggers a transfer to the project of the amount of `token` tokens they are owed, according to their
   * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
   * contract.
   */
  function releaseProjectERC20(IERC20 token) external;
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

/**
 *
 * @title PrimaryVestingByMetadrop.sol. This contract is the primary sale proceeds vesting contract
 * from the metadrop deployment platform
 *
 * It performs vesting of project funds (if configured) and splits payments between the project team
 * recipients
 *
 * Primary vesting looks to address the disconnect between primary sales volume and the
 * need for project teams to continue to deliver value to holders.
 * Note this contract is both a vesting contract and payment splitter, allowing disbursement
 * of funds to n parties with vesting for each
 * Note based on OpenZeppelin contracts but modified to a) combine vesting and payment split and
 * b) allow this contract to be cloned, i.e. set state initialise not in the constructor.
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import {SafeERC20, IERC20} from "../Global/OZ/SafeERC20.sol";
import {IPrimaryVestingByMetadrop} from "./IPrimaryVestingByMetadrop.sol";
import {IWETH} from "../ThirdParty/WETH/IWETH.sol";
import {Revert} from "../Global/Revert.sol";

contract PrimaryVestingByMetadrop is IPrimaryVestingByMetadrop, Revert {
  using SafeERC20 for IERC20;

  // Default for any percentages, which must be held as basis points, i.e. 5% is 500
  uint256 private constant PERCENTAGE_DENOMINATOR = 10000; //10,000 i.e. 100.00

  IWETH public immutable weth;

  // Beneficiary addresses
  address payable private _platformAddress;

  // Shares
  uint256 private _totalShares;
  uint256 private _projectUpfrontShare;
  uint256 private _projectVestedShare;

  // Project share splits: project allocation can be split amoung n addresses:
  uint256 private _totalProjectShares;
  ProjectBeneficiary[] private _projectBeneficiaries;

  // ETH Release tracking
  uint256 private _totalETHReleased;
  uint256 private _projectUpFrontETHReleased;
  uint256 private _projectVestedETHReleased;

  // ERC20 Release tracking
  mapping(IERC20 => uint256) private _erc20TotalReleased;
  mapping(IERC20 => uint256) private _projectUpfrontERC20Released;
  mapping(IERC20 => uint256) private _projectVestedERC20Released;

  // Vesting details
  uint256 private _vestingStart;
  uint256 private _vestingCliff;
  uint256 private _vestingPeriod;

  /** ====================================================================================================================
   *                                              CONSTRUCTOR AND INTIIALISE
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                        -->CONSTRUCTOR
   * @dev constructor           The constructor is not called when the contract is cloned. In this
   *                            constructor we just setup default values and set the template contract to initialised.
   * _____________________________________________________________________________________________________________________
   */
  constructor(address wethAddress_) {
    weth = IWETH(wethAddress_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) _initialisePrimaryVesting  Initialise data on the vesting contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_    Configuration object for this instance of vesting
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _initialisePrimaryVesting(bytes calldata vestingModule_) internal {
    // Decode the config:
    VestingConfig memory vestingConfig = abi.decode(
      vestingModule_,
      (VestingConfig)
    );

    if (
      (vestingConfig.projectUpFrontShare + vestingConfig.projectVestedShare) !=
      PERCENTAGE_DENOMINATOR
    ) {
      _revert(TotalSharesMustMatchDenominator.selector);
    }

    // Add the project beneficiaries:
    uint256 totalProjectShares;
    for (uint256 i = 0; i < vestingConfig.projectPayees.length; ) {
      _projectBeneficiaries.push(vestingConfig.projectPayees[i]);
      totalProjectShares += vestingConfig.projectPayees[i].payeeShares;

      unchecked {
        i++;
      }
    }

    if (totalProjectShares == 0) {
      _revert(ShareTotalCannotBeZero.selector);
    }
    _totalProjectShares = totalProjectShares;

    _projectUpfrontShare = vestingConfig.projectUpFrontShare;
    _projectVestedShare = vestingConfig.projectVestedShare;

    _totalShares = _projectUpfrontShare + _projectVestedShare;

    // Set vesting details:
    _vestingPeriod = vestingConfig.vestingPeriodInDays * 1 days;
    _vestingStart = vestingConfig.start;
    _vestingCliff = (vestingConfig.vestingCliff * 1 days);
  }

  /** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   *
   * Getters: Shares
   *
   *  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   */

  /**
   * @dev Getter for the total shares held by payees.
   */
  function sharesTotal() public view returns (uint256) {
    return _totalShares;
  }

  /**
   * @dev Getter for the amount of shares held by the project that are vested.
   */
  function sharesProjectVested() public view returns (uint256) {
    return _projectVestedShare;
  }

  /**
   * @dev Getter for the amount of shares held by the project that are upfront.
   */
  function sharesProjectUpfront() public view returns (uint256) {
    return _projectUpfrontShare;
  }

  /** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   *
   * Getters: Released Amounts, ETH
   *
   *  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   */

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function releasedETHTotal() public view returns (uint256) {
    return _totalETHReleased;
  }

  /**
   * @dev Getter for the amount of ETH release for the project vested.
   */
  function releasedETHProjectVested() public view returns (uint256) {
    return _projectVestedETHReleased;
  }

  /**
   * @dev Getter for the amount of ETH release for the project upfront.
   */
  function releasedETHProjectUpfront() public view returns (uint256) {
    return _projectUpFrontETHReleased;
  }

  /** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   *
   * Getters: Released Amounts, ERC20
   *
   *  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   */

  /**
   * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
   * contract.
   */
  function releasedERC20Total(IERC20 token) public view returns (uint256) {
    return _erc20TotalReleased[token];
  }

  /**
   * @dev Getter for the amount of `token` tokens already released to the project vested. `token` should be the address of an
   * IERC20 contract.
   */
  function releasedERC20ProjectVested(
    IERC20 token
  ) public view returns (uint256) {
    return _projectVestedERC20Released[token];
  }

  /**
   * @dev Getter for the amount of `token` tokens already released to the project upfront. `token` should be the address of an
   * IERC20 contract.
   */
  function releasedERC20ProjectUpfront(
    IERC20 token
  ) public view returns (uint256) {
    return _projectUpfrontERC20Released[token];
  }

  /** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   *
   * Getters: Addresses
   *
   *  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   */

  /**
   * @dev Getter for platform address
   */
  function platformAddress() public view returns (address) {
    return _platformAddress;
  }

  /**
   * @dev Getter for project addresses
   */
  function projectAddresses()
    public
    view
    returns (ProjectBeneficiary[] memory)
  {
    return _projectBeneficiaries;
  }

  /**
   * @dev Calculates the amount of ether that has already vested. Default implementation is a linear vesting curve.
   */
  function vestedAmountEth(
    uint256 balance,
    uint256 timestamp
  ) public view virtual returns (uint256) {
    return _vestingSchedule(balance, timestamp);
  }

  /**
   * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
   */
  function vestedAmountERC20(
    uint256 balance,
    uint256 timestamp
  ) public view virtual returns (uint256) {
    return _vestingSchedule(balance, timestamp);
  }

  /**
   * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
   * an asset given its total historical allocation.
   */
  function _vestingSchedule(
    uint256 totalAllocation,
    uint256 timestamp
  ) internal view virtual returns (uint256) {
    if (timestamp < (_vestingStart + _vestingCliff)) {
      return 0;
    } else if (timestamp > _vestingStart + _vestingPeriod) {
      return totalAllocation;
    } else {
      return (totalAllocation * (timestamp - _vestingStart)) / _vestingPeriod;
    }
  }

  /**
   * @dev Getter for the amount of project's vested releasable Ether.
   */
  function releasableETHProjectVested() public view returns (uint256) {
    uint256 totalReceived = address(this).balance + releasedETHTotal();
    uint256 pendingPaymentByShares = _pendingPaymentVested(
      _projectVestedShare,
      totalReceived,
      releasedETHProjectVested()
    );
    return (pendingPaymentByShares);
  }

  /**
   * @dev Getter for the amount of the project's upfront releasable Ether.
   */
  function releasableETHProjectUpfront() public view returns (uint256) {
    uint256 totalReceived = address(this).balance + releasedETHTotal();
    uint256 pendingPaymentByShares = _pendingPayment(
      _projectUpfrontShare,
      totalReceived,
      releasedETHProjectUpfront()
    );
    return (pendingPaymentByShares);
  }

  /**
   * @dev Getter for the amount of project's vested releasable `token` tokens. `token` should be the address of an
   * IERC20 contract.
   */
  function releasableERC20ProjectVested(
    IERC20 token
  ) public view returns (uint256) {
    uint256 totalReceived = token.balanceOf(address(this)) +
      releasedERC20Total(token);
    uint256 pendingPaymentByShares = _pendingPayment(
      _projectVestedShare,
      totalReceived,
      releasedERC20ProjectVested(token)
    );

    uint256 releasable = vestedAmountERC20(
      pendingPaymentByShares,
      block.timestamp
    );
    return (releasable);
  }

  /**
   * @dev Getter for the amount of project's releasable upfront `token` tokens. `token` should be the address of an
   * IERC20 contract.
   */
  function releasableERC20ProjectUpfront(
    IERC20 token
  ) public view returns (uint256) {
    uint256 totalReceived = token.balanceOf(address(this)) +
      releasedERC20Total(token);
    uint256 pendingPaymentByShares = _pendingPayment(
      _projectUpfrontShare,
      totalReceived,
      releasedERC20ProjectUpfront(token)
    );
    return (pendingPaymentByShares);
  }

  /**
   * @dev Triggers a transfer to the project of the amount of Ether they are owed, according to their percentage of the
   * total shares and their previous withdrawals.
   */
  function releaseProjectETH(uint256 gasLimit_) public virtual {
    uint256 upfrontPayment = releasableETHProjectUpfront();
    uint256 vestedPayment = releasableETHProjectVested();

    if ((upfrontPayment + vestedPayment) == 0) {
      _revert(NoPaymentDue.selector);
    }

    _projectUpFrontETHReleased += upfrontPayment;
    _projectVestedETHReleased += vestedPayment;
    _totalETHReleased += (upfrontPayment + vestedPayment);

    // Distribute funds according to the project shares:
    for (uint256 i = 0; i < _projectBeneficiaries.length; ) {
      address payable payee = _projectBeneficiaries[i].payeeAddress;
      uint256 amount = ((upfrontPayment + vestedPayment) *
        _projectBeneficiaries[i].payeeShares) / _totalProjectShares;

      // If no gas limit was provided or provided gas limit greater than gas left, just use the remaining gas.
      uint256 gas = (gasLimit_ == 0 || gasLimit_ > gasleft())
        ? gasleft()
        : gasLimit_;

      (bool success, ) = payee.call{value: amount, gas: gas}("");
      // If the ETH transfer fails, wrap the ETH and try send it as WETH.
      if (!success) {
        weth.deposit{value: amount}();
        IERC20(address(weth)).safeTransfer(payee, amount);
      }

      emit PaymentReleased(payee, amount);

      unchecked {
        i++;
      }
    }
  }

  /**
   * @dev Triggers a transfer to the project of the amount of `token` tokens they are owed, according to their
   * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
   * contract.
   */
  function releaseProjectERC20(IERC20 token) public virtual {
    uint256 upfrontPayment = releasableERC20ProjectUpfront(token);
    uint256 vestedPayment = releasableERC20ProjectVested(token);

    if ((upfrontPayment + vestedPayment) == 0) {
      _revert(NoPaymentDue.selector);
    }

    _projectUpfrontERC20Released[token] += upfrontPayment;
    _projectVestedERC20Released[token] += vestedPayment;
    _erc20TotalReleased[token] += (upfrontPayment + vestedPayment);

    // Distribute funds according to the project shares:
    for (uint256 i = 0; i < _projectBeneficiaries.length; ) {
      address payee = _projectBeneficiaries[i].payeeAddress;
      uint256 amount = ((upfrontPayment + vestedPayment) *
        _projectBeneficiaries[i].payeeShares) / _totalProjectShares;

      SafeERC20.safeTransfer(token, payee, amount);

      emit ERC20PaymentReleased(token, payee, amount);

      emit PaymentReleased(payee, amount);

      unchecked {
        i++;
      }
    }
  }

  /**
   * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
   * already released amounts.
   */
  function _pendingPayment(
    uint256 shares_,
    uint256 totalReceived_,
    uint256 alreadyReleased_
  ) private view returns (uint256) {
    return ((totalReceived_ * shares_) / _totalShares) - alreadyReleased_;
  }

  /**
   * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
   * already released amounts including vesting
   */
  function _pendingPaymentVested(
    uint256 shares_,
    uint256 totalReceived_,
    uint256 alreadyReleased_
  ) private view returns (uint256) {
    return (
      (vestedAmountEth(
        (totalReceived_ * shares_) / _totalShares,
        block.timestamp
      ) - alreadyReleased_)
    );
  }
}

// SPDX-License-Identifier: CC0-1.0
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev EPS4907. Implement ERC4907 using EPS.

*/

import "./IEPS4907.sol";

pragma solidity 0.8.19;

abstract contract EPS4907 is IEPS4907 {
  uint256 private constant ERC4907_USAGE_TYPE = 16;

  // EPS Register
  IEPSDelegationRegister internal immutable epsRegister;

  /** ====================================================================================================================
   *                                                     CONSTRUCTOR
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                        -->CONSTRUCTOR
   * @dev constructor           Initalise the EPS register address
   * ---------------------------------------------------------------------------------------------------------------------
   * @param epsRegister_        The EPS register address (0x888888888888660F286A7C06cfa3407d09af44B2 on most chains)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  constructor(address epsRegister_) {
    epsRegister = IEPSDelegationRegister(epsRegister_);
  }

  /** ====================================================================================================================
   *                                                   IMPLEMENTATION
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                      -->IMPLEMENATION
   * @dev userOf                Return an ERC4907 compliant user for this tokenId
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId_            The tokenId being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @return userOf_            The user for this tokenID, as per the EPS register
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function userOf(
    uint256 tokenId_
  ) public view virtual returns (address userOf_) {
    (address primaryBeneficiary, ) = beneficiaryOf(
      tokenId_,
      ERC4907_USAGE_TYPE,
      false,
      true
    );
    // If there is no delegation in place then the beneficiary that is returned
    // will be the owner. For consistency with the returned result for ERC4907
    // we want to return the zero address under these circumstances (i.e. there
    // is no "_user" for this tokenId at this time)
    if (primaryBeneficiary == IERC721(address(this)).ownerOf(tokenId_)) {
      return (address(0));
    } else {
      return primaryBeneficiary;
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                      -->IMPLEMENATION
   * @dev beneficiaryOf              Returns the EPS beneficiary (or beneficiaries) of the `tokenId` token.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId_                 The tokenId being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @param usageType_               The usage ID being queried (e.g. 0 for all, 6 for social media).
   * ---------------------------------------------------------------------------------------------------------------------
   * @param includeSecondary_        Include secondary (i.e. non-unique) results?
   * ---------------------------------------------------------------------------------------------------------------------
   * @param includeRental_           Include rental (these ARE unique) results?
   * ---------------------------------------------------------------------------------------------------------------------
   * @return primaryBeneficiary_     The primary (and unique) beneficiary for this token ID
   * ---------------------------------------------------------------------------------------------------------------------
   * @return secondaryBeneficiaries_  An array of secondary beneficiaries (if any)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function beneficiaryOf(
    uint256 tokenId_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  )
    public
    view
    returns (
      address primaryBeneficiary_,
      address[] memory secondaryBeneficiaries_
    )
  {
    return (
      epsRegister.beneficiaryOf(
        address(this),
        tokenId_,
        usageType_,
        includeSecondary_,
        includeRental_
      )
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                      -->IMPLEMENATION
   * @dev beneficiaryBalanceOf       Returns the EPS beneficiary balance of the `beneficiary` address.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param beneficiary_             The address being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @param usageType_               The usage ID being queried (e.g. 0 for all, 6 for social media).
   * ---------------------------------------------------------------------------------------------------------------------
   * @param includeSecondary_        Include secondary (i.e. non-unique) results?
   * ---------------------------------------------------------------------------------------------------------------------
   * @param includeRental_           Include rental (these ARE unique) results?
   * ---------------------------------------------------------------------------------------------------------------------
   * @return beneficaryBalance       The balance for this beneficiary address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */

  function beneficiaryBalanceOf(
    address beneficiary_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  ) public view returns (uint256 beneficaryBalance) {
    return
      epsRegister.beneficiaryBalanceOf(
        beneficiary_,
        address(this),
        usageType_,
        false,
        0,
        includeSecondary_,
        includeRental_
      );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                      -->IMPLEMENATION
   * @dev supportsInterface
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30000 gas.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param interfaceId              The interface ID being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @return bool                    True if supported
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual returns (bool) {
    // The interface IDs are constants representing the first 4 bytes
    // of the XOR of all function selectors in the interface.
    // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
    // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
    return
      interfaceId == 0xad092b5c || // ERC165 interface ID for IERC4907.
      interfaceId == 0xd50ef07c; // ERC165 interface ID for IEPS4907
  }
}

// SPDX-License-Identifier: CC0-1.0
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev EPS4907. Implement ERC4907 using EPS.

*/

import "./IEPSDelegationRegister.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

pragma solidity 0.8.19;

interface IEPS4907 {
  /** ____________________________________________________________________________________________________________________
   *                                                                                                      -->IMPLEMENATION
   * @dev userOf                Return an ERC4907 compliant user for this tokenId
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId_            The tokenId being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @return userOf_            The user for this tokenID, as per the EPS register
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function userOf(uint256 tokenId_) external view returns (address userOf_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                      -->IMPLEMENATION
   * @dev beneficiaryOf              Returns the EPS beneficiary (or beneficiaries) of the `tokenId` token.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId_                 The tokenId being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @param usageType_               The usage ID being queried (e.g. 0 for all, 6 for social media).
   * ---------------------------------------------------------------------------------------------------------------------
   * @param includeSecondary_        Include secondary (i.e. non-unique) results?
   * ---------------------------------------------------------------------------------------------------------------------
   * @param includeRental_           Include rental (these ARE unique) results?
   * ---------------------------------------------------------------------------------------------------------------------
   * @return primaryBeneficiary_     The primary (and unique) beneficiary for this token ID
   * ---------------------------------------------------------------------------------------------------------------------
   * @return secondaryBeneficiaries_  An array of secondary beneficiaries (if any)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function beneficiaryOf(
    uint256 tokenId_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  )
    external
    view
    returns (
      address primaryBeneficiary_,
      address[] memory secondaryBeneficiaries_
    );

  /**
   * @dev Returns the EPS beneficiary balance of the `beneficiary` address.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                      -->IMPLEMENATION
   * @dev beneficiaryBalanceOf       Returns the EPS beneficiary balance of the `beneficiary` address.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param beneficiary_             The address being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @param usageType_               The usage ID being queried (e.g. 0 for all, 6 for social media).
   * ---------------------------------------------------------------------------------------------------------------------
   * @param includeSecondary_        Include secondary (i.e. non-unique) results?
   * ---------------------------------------------------------------------------------------------------------------------
   * @param includeRental_           Include rental (these ARE unique) results?
   * ---------------------------------------------------------------------------------------------------------------------
   * @return beneficaryBalance       The balance for this beneficiary address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */

  function beneficiaryBalanceOf(
    address beneficiary_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  ) external view returns (uint256 beneficaryBalance);
}

// SPDX-License-Identifier: CC0-1.0
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev EPS Delegation Register - Interface

 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../EPSRewardToken/IOAT.sol";
import "../EPSRewardToken/IERCOmnReceiver.sol";

/**
 *
 * @dev Implementation of the EPS proxy register interface.
 *
 */
interface IEPSDelegationRegister {
  // ======================================================
  // ENUMS and STRUCTS
  // ======================================================

  // Scope of a delegation: global, collection or token
  enum DelegationScope {
    global,
    collection,
    token
  }

  // Time limit of a delegation: eternal or time limited
  enum DelegationTimeLimit {
    eternal,
    limited
  }

  // The Class of a delegation: primary, secondary or rental
  enum DelegationClass {
    primary,
    secondary,
    rental
  }

  // The status of a delegation:
  enum DelegationStatus {
    live,
    pending
  }

  // Data output format for a report (used to output both hot and cold
  // delegation details)
  struct DelegationReport {
    address hot;
    address cold;
    DelegationScope scope;
    DelegationClass class;
    DelegationTimeLimit timeLimit;
    address collection;
    uint256 tokenId;
    uint40 startDate;
    uint40 endDate;
    bool validByDate;
    bool validBilaterally;
    bool validTokenOwnership;
    bool[25] usageTypes;
    address key;
    uint96 controlInteger;
    bytes data;
    DelegationStatus status;
  }

  // Delegation record
  struct DelegationRecord {
    address hot;
    uint96 controlInteger;
    address cold;
    uint40 startDate;
    uint40 endDate;
    DelegationStatus status;
  }

  // If a delegation is for a collection, or has additional data, it will need to read the delegation metadata
  struct DelegationMetadata {
    address collection;
    uint256 tokenId;
    bytes data;
  }

  // Details of a hot wallet lock
  struct LockDetails {
    uint40 lockStart;
    uint40 lockEnd;
  }

  // Validity dates when checking a delegation
  struct ValidityDates {
    uint40 start;
    uint40 end;
  }

  // Delegation struct to hold details of a new delegation
  struct Delegation {
    address hot;
    address cold;
    address[] targetAddresses;
    uint256 tokenId;
    bool tokenDelegation;
    uint8[] usageTypes;
    uint40 startDate;
    uint40 endDate;
    uint16 providerCode;
    DelegationClass delegationClass;
    uint96 subDelegateKey;
    bytes data;
    DelegationStatus status;
  }

  // Addresses associated with a delegation check
  struct DelegationCheckAddresses {
    address hot;
    address cold;
    address targetCollection;
  }

  // Classes associated with a delegation check
  struct DelegationCheckClasses {
    bool secondary;
    bool rental;
    bool token;
  }

  // Migrated record data
  struct MigratedRecord {
    address hot;
    address cold;
  }

  // ======================================================
  // CUSTOM ERRORS
  // ======================================================

  error UsageTypeAlreadyDelegated(uint256 usageType);
  error CannotDeleteValidDelegation();
  error CannotDelegatedATokenYouDontOwn();
  error IncorrectAdminLevel(uint256 requiredLevel);
  error OnlyParticipantOrAuthorisedSubDelegate();
  error HotAddressIsLockedAndCannotBeDelegatedTo();
  error InvalidDelegation();
  error ToMuchETHForPendingPayments(uint256 sent, uint256 required);
  error UnknownAmount();
  error InvalidERC20Payment();
  error IncorrectProxyRegisterFee();
  error UnrecognisedEPSAPIAmount();
  error CannotRevokeAllForRegisterAdminHierarchy();

  // ======================================================
  // EVENTS
  // ======================================================

  event DelegationMade(
    address indexed hot,
    address indexed cold,
    address targetAddress,
    uint256 tokenId,
    bool tokenDelegation,
    uint8[] usageTypes,
    uint40 startDate,
    uint40 endDate,
    uint16 providerCode,
    DelegationClass delegationClass,
    uint96 subDelegateKey,
    bytes data,
    DelegationStatus status
  );
  event DelegationRevoked(address hot, address cold, address delegationKey);
  event DelegationPaid(address delegationKey);
  event AllDelegationsRevokedForHot(address hot);
  event AllDelegationsRevokedForCold(address cold);
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   *
   *
   * @dev getDelegationRecord
   *
   *
   */
  function getDelegationRecord(address delegationKey_)
    external
    view
    returns (DelegationRecord memory);

  /**
   *
   *
   * @dev isValidDelegation
   *
   *
   */
  function isValidDelegation(
    address hot_,
    address cold_,
    address collection_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  ) external view returns (bool isValid_);

  /**
   *
   *
   * @dev getAddresses - Get all currently valid addresses for a hot address.
   * - Pass in address(0) to return records that are for ALL collections
   * - Pass in a collection address to get records for just that collection
   * - Usage type must be supplied. Only records that match usage type will be returned
   *
   *
   */
  function getAddresses(
    address hot_,
    address collection_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  ) external view returns (address[] memory addresses_);

  /**
   *
   *
   * @dev beneficiaryBalanceOf: Returns the beneficiary balance
   *
   *
   */
  function beneficiaryBalanceOf(
    address queryAddress_,
    address contractAddress_,
    uint256 usageType_,
    bool erc1155_,
    uint256 id_,
    bool includeSecondary_,
    bool includeRental_
  ) external view returns (uint256 balance_);

  /**
   *
   *
   * @dev beneficiaryOf
   *
   *
   */
  function beneficiaryOf(
    address collection_,
    uint256 tokenId_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  )
    external
    view
    returns (
      address primaryBeneficiary_,
      address[] memory secondaryBeneficiaries_
    );

  /**
   *
   *
   * @dev delegationFromColdExists - check a cold delegation exists
   *
   *
   */
  function delegationFromColdExists(address cold_, address delegationKey_)
    external
    view
    returns (bool);

  /**
   *
   *
   * @dev delegationFromHotExists - check a hot delegation exists
   *
   *
   */
  function delegationFromHotExists(address hot_, address delegationKey_)
    external
    view
    returns (bool);

  /**
   *
   *
   * @dev getAllForHot - Get all delegations at a hot address, formatted nicely
   *
   *
   */
  function getAllForHot(address hot_)
    external
    view
    returns (DelegationReport[] memory);

  /**
   *
   *
   * @dev getAllForCold - Get all delegations at a cold address, formatted nicely
   *
   *
   */
  function getAllForCold(address cold_)
    external
    view
    returns (DelegationReport[] memory);

  /**
   *
   *
   * @dev makeDelegation - A direct call to setup a new proxy record
   *
   *
   */
  function makeDelegation(
    address hot_,
    address cold_,
    address[] memory targetAddresses_,
    uint256 tokenId_,
    bool tokenDelegation_,
    uint8[] memory usageTypes_,
    uint40 startDate_,
    uint40 endDate_,
    uint16 providerCode_,
    DelegationClass delegationClass_, //0 = primary, 1 = secondary, 2 = rental
    uint96 subDelegateKey_,
    bytes memory data_
  ) external payable;

  /**
   *
   *
   * @dev getDelegationKey - get the link hash to the delegation metadata
   *
   *
   */
  function getDelegationKey(
    address hot_,
    address cold_,
    address targetAddress_,
    uint256 tokenId_,
    bool tokenDelegation_,
    uint96 controlInteger_,
    uint40 startDate_,
    uint40 endDate_
  ) external pure returns (address);

  /**
   *
   *
   * @dev getHotAddressLockDetails
   *
   *
   */
  function getHotAddressLockDetails(address hot_)
    external
    view
    returns (LockDetails memory, address[] memory);

  /**
   *
   *
   * @dev lockAddressUntilDate
   *
   *
   */
  function lockAddressUntilDate(uint40 unlockDate_) external;

  /**
   *
   *
   * @dev lockAddress
   *
   *
   */
  function lockAddress() external;

  /**
   *
   *
   * @dev unlockAddress
   *
   *
   */
  function unlockAddress() external;

  /**
   *
   *
   * @dev addLockBypassAddress
   *
   *
   */
  function addLockBypassAddress(address bypassAddress_) external;

  /**
   *
   *
   * @dev removeLockBypassAddress
   *
   *
   */
  function removeLockBypassAddress(address bypassAddress_) external;

  /**
   *
   *
   * @dev revokeRecord: Revoking a single record with Key
   *
   *
   */
  function revokeRecord(address delegationKey_, uint96 subDelegateKey_)
    external;

  /**
   *
   *
   * @dev revokeGlobalAll
   *
   *
   */
  function revokeRecordOfGlobalScopeForAllUsages(address participant2_)
    external;

  /**
   *
   *
   * @dev revokeAllForCold: Cold calls and revokes ALL
   *
   *
   */
  function revokeAllForCold(address cold_, uint96 subDelegateKey_) external;

  /**
   *
   *
   * @dev revokeAllForHot: Hot calls and revokes ALL
   *
   *
   */
  function revokeAllForHot() external;

  /**
   *
   *
   * @dev deleteExpired: ANYONE can delete expired records
   *
   *
   */
  function deleteExpired(address delegationKey_) external;

  /**
   *
   *
   * @dev setRegisterFee: set the fee for accepting a registration:
   *
   *
   */
  function setRegisterFees(
    uint256 registerFee_,
    address erc20_,
    uint256 erc20Fee_
  ) external;

  /**
   *
   *
   * @dev setRewardTokenAndRate
   *
   *
   */
  function setRewardTokenAndRate(address rewardToken_, uint88 rewardRate_)
    external;

  /**
   *
   *
   * @dev lockRewardRate
   *
   *
   */
  function lockRewardRate() external;

  /**
   *
   *
   * @dev setLegacyOff
   *
   *
   */
  function setLegacyOff() external;

  /**
   *
   *
   * @dev setENSName (used to set reverse record so interactions with this contract are easy to
   * identify)
   *
   *
   */
  function setENSName(string memory ensName_) external;

  /**
   *
   *
   * @dev setENSReverseRegistrar
   *
   *
   */
  function setENSReverseRegistrar(address ensReverseRegistrar_) external;

  /**
   *
   *
   * @dev setTreasuryAddress: set the treasury address:
   *
   *
   */
  function setTreasuryAddress(address treasuryAddress_) external;

  /**
   *
   *
   * @dev setDecimalsAndBalance
   *
   *
   */
  function setDecimalsAndBalance(uint8 decimals_, uint256 balance_) external;

  /**
   *
   *
   * @dev withdrawETH: withdraw eth to the treasury:
   *
   *
   */
  function withdrawETH(uint256 amount_) external returns (bool success_);

  /**
   *
   *
   * @dev withdrawERC20: Allow any ERC20s to be withdrawn Note, this is provided to enable the
   * withdrawal of payments using valid ERC20s. Assets sent here in error are retrieved with
   * rescueERC20
   *
   *
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external;

  /**
   *
   *
   * @dev isLevelAdmin
   *
   *
   */
  function isLevelAdmin(
    address receivedAddress_,
    uint256 level_,
    uint96 key_
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev IERCOmnReceiver - Interface

 */

pragma solidity 0.8.19;

interface IERCOmnReceiver {
  function onTokenTransfer(
    address sender,
    uint256 value,
    bytes memory data
  ) external payable;
}

// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev IOAT - Interface

 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev OAT interface
 */
interface IOAT is IERC20 {
  /**
   *
   * @dev emitToken
   *
   */
  function emitToken(address receiver_, uint256 amount_) external;

  /**
   *
   * @dev addEmitter
   *
   */
  function addEmitter(address emitter_) external;

  /**
   *
   * @dev removeEmitter
   *
   */
  function removeEmitter(address emitter_) external;

  /**
   *
   * @dev setTreasury
   *
   */
  function setTreasury(address treasury_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";

/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
  /// @dev The constructor that is called when the contract is being deployed.
  constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./lib/Constants.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
  /// @dev Emitted when an operator is not allowed.
  error OperatorNotAllowed(address operator);

  IOperatorFilterRegistry internal constant OPERATOR_FILTER_REGISTRY =
    IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

  /// @dev The constructor that is called when the contract is being deployed.
  constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
    // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
    // will not revert, but the contract will need to be registered with the registry once it is deployed in
    // order for the modifier to filter addresses.
    if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
      if (subscribe) {
        OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
          address(this),
          subscriptionOrRegistrantToCopy
        );
      } else {
        if (subscriptionOrRegistrantToCopy != address(0)) {
          OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(
            address(this),
            subscriptionOrRegistrantToCopy
          );
        } else {
          OPERATOR_FILTER_REGISTRY.register(address(this));
        }
      }
    }
  }

  /**
   * @dev A helper function to check if an operator is allowed.
   */
  modifier onlyAllowedOperator(address from) virtual {
    // Allow spending tokens from addresses with balance
    // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
    // from an EOA.
    if (from != msg.sender) {
      _checkFilterOperator(msg.sender);
    }
    _;
  }

  /**
   * @dev A helper function to check if an operator approval is allowed.
   */
  modifier onlyAllowedOperatorApproval(address operator) virtual {
    _checkFilterOperator(operator);
    _;
  }

  /**
   * @dev A helper function to check if an operator is allowed.
   */
  function _checkFilterOperator(address operator) internal view virtual {
    // Check registry code length to facilitate testing in environments without a deployed registry.
    if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
      // under normal circumstances, this function will revert rather than return false, but inheriting contracts
      // may specify their own OperatorFilterRegistry implementations, which may behave differently
      if (
        !OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)
      ) {
        revert OperatorNotAllowed(operator);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}