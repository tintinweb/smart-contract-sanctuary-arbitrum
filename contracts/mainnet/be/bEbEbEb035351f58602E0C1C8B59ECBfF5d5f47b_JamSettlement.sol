// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
pragma solidity ^0.8.17;

import "../libraries/JamInteraction.sol";
import "../libraries/JamOrder.sol";
import "../libraries/JamHooks.sol";
import "../libraries/Signature.sol";
import "../libraries/common/BMath.sol";
import "lib/openzeppelin-contracts/contracts/interfaces/IERC1271.sol";

/// @title JamSigning
/// @notice Functions which handles the signing and validation of Jam orders
abstract contract JamSigning {
    mapping(address => mapping(uint256 => uint256)) private standardNonces;
    mapping(address => mapping(uint256 => uint256)) private limitOrdersNonces;
    uint256 private constant INF_EXPIRY = 9999999999; // expiry for limit orders

    bytes32 private constant DOMAIN_NAME = keccak256("JamSettlement");
    bytes32 private constant DOMAIN_VERSION = keccak256("1");

    bytes4 private constant EIP1271_MAGICVALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));
    uint256 private constant ETH_SIGN_HASH_PREFIX = 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000;

    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    ));

    bytes32 public constant JAM_ORDER_TYPE_HASH = keccak256(abi.encodePacked(
        "JamOrder(address taker,address receiver,uint256 expiry,uint256 nonce,address executor,uint16 minFillPercent,bytes32 hooksHash,address[] sellTokens,address[] buyTokens,uint256[] sellAmounts,uint256[] buyAmounts,uint256[] sellNFTIds,uint256[] buyNFTIds,bytes sellTokenTransfers,bytes buyTokenTransfers)"
    ));

    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    constructor(){
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, DOMAIN_NAME, DOMAIN_VERSION, block.chainid, address(this))
        );
    }

    /// @notice The domain separator used in the order validation signature
    /// @return The domain separator used in encoding of order signature
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == _CACHED_CHAIN_ID
            ? _CACHED_DOMAIN_SEPARATOR
            : keccak256(
                abi.encode(EIP712_DOMAIN_TYPEHASH, DOMAIN_NAME, DOMAIN_VERSION, block.chainid, address(this))
            );
    }

    /// @notice Hash beforeSettle and afterSettle interactions
    /// @param hooks pre and post interactions to hash
    /// @return The hash of the interactions
    function hashHooks(JamHooks.Def memory hooks) public pure returns (bytes32) {
        if (hooks.afterSettle.length == 0 && hooks.beforeSettle.length == 0){
            return bytes32(0);
        }
        return keccak256(abi.encode(hooks));
    }

    /// @notice Hash the order info and hooks
    /// @param order The order to hash
    /// @param hooksHash The hash of the hooks
    /// @return The hash of the order
    function hashOrder(JamOrder.Data calldata order, bytes32 hooksHash) public view returns (bytes32) {
        bytes32 dataHash = keccak256(
        // divide order into two parts and encode them separately to avoid stack too deep exception
            bytes.concat(
                abi.encode(
                    JAM_ORDER_TYPE_HASH,
                    order.taker,
                    order.receiver,
                    order.expiry,
                    order.nonce,
                    order.executor,
                    order.minFillPercent,
                    hooksHash
                ),
                abi.encode(
                    keccak256(abi.encodePacked(order.sellTokens)),
                    keccak256(abi.encodePacked(order.buyTokens)),
                    keccak256(abi.encodePacked(order.sellAmounts)),
                    keccak256(abi.encodePacked(order.buyAmounts)),
                    keccak256(abi.encodePacked(order.sellNFTIds)),
                    keccak256(abi.encodePacked(order.buyNFTIds)),
                    keccak256(order.sellTokenTransfers),
                    keccak256(order.buyTokenTransfers)
                )
            )
        );
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                dataHash
            )
        );
    }

    /// @notice Validate the order signature
    /// @param validationAddress The address to validate the signature against
    /// @param hash The hash of the order
    /// @param signature The signature to validate
    function validateSignature(address validationAddress, bytes32 hash, Signature.TypedSignature calldata signature) public view {
        if (signature.signatureType == Signature.Type.EIP712) {
            (bytes32 r, bytes32 s, uint8 v) = Signature.getRsv(signature.signatureBytes);
            address signer = ecrecover(hash, v, r, s);
            require(signer != address(0), "Invalid signer");
            if (signer != validationAddress) {
                revert("Invalid EIP712 order signature");
            }
        } else if (signature.signatureType == Signature.Type.EIP1271) {
            require(
                IERC1271(validationAddress).isValidSignature(hash, signature.signatureBytes) == EIP1271_MAGICVALUE,
                "Invalid EIP1271 order signature"
            );
        } else if (signature.signatureType == Signature.Type.ETHSIGN) {
            bytes32 ethSignHash;
            assembly {
                mstore(0, ETH_SIGN_HASH_PREFIX) // length of 28 bytes
                mstore(28, hash) // length of 32 bytes
                ethSignHash := keccak256(0, 60)
            }
            (bytes32 r, bytes32 s, uint8 v) = Signature.getRsv(signature.signatureBytes);
            address signer = ecrecover(ethSignHash, v, r, s);
            require(signer != address(0), "Invalid signer");
            if (signer != validationAddress) {
                revert("Invalid ETHSIGH order signature");
            }
        } else {
            revert("Invalid Signature Type");
        }
    }

    /// @notice validate all information about the order
    /// @param order The order to validate
    /// @param hooks User's hooks to validate
    /// @param signature The signature to check against
    /// @param curFillPercent Solver/Maker fill percent
    function validateOrder(
        JamOrder.Data calldata order, JamHooks.Def memory hooks, Signature.TypedSignature calldata signature, uint16 curFillPercent
    ) internal {
        // Allow settle from user without sig
        if (order.taker != msg.sender) {
            bytes32 hooksHash = hashHooks(hooks);
            bytes32 orderHash = hashOrder(order, hooksHash);
            validateSignature(order.taker, orderHash, signature);
        }
        require(order.executor == msg.sender || order.executor == address(0), "INVALID_EXECUTOR");
        require(order.buyTokens.length == order.buyAmounts.length, "INVALID_BUY_TOKENS_LENGTH");
        require(order.buyTokens.length == order.buyTokenTransfers.length, "INVALID_BUY_TRANSFERS_LENGTH");
        require(order.sellTokens.length == order.sellAmounts.length, "INVALID_SELL_TOKENS_LENGTH");
        require(order.sellTokens.length == order.sellTokenTransfers.length, "INVALID_SELL_TRANSFERS_LENGTH");
        require(curFillPercent >= order.minFillPercent, "INVALID_FILL_PERCENT");
        invalidateOrderNonce(order.taker, order.nonce, order.expiry == INF_EXPIRY);
        require(block.timestamp < order.expiry, "ORDER_EXPIRED");
    }

    /// @notice Cancel limit order by invalidating nonce for the sender address
    /// @param nonce The nonce to invalidate
    function cancelLimitOrder(uint256 nonce) external {
        invalidateOrderNonce(msg.sender, nonce, true);
    }

    /// @notice Check if taker's limit order nonce is valid
    /// @param taker address
    /// @param nonce to check
    /// @return True if nonce is valid
    function isLimitOrderNonceValid(address taker, uint256 nonce) external view returns (bool) {
        uint256 invalidatorSlot = nonce >> 8;
        uint256 invalidatorBit = 1 << (nonce & 0xff);
        return (limitOrdersNonces[taker][invalidatorSlot] & invalidatorBit) == 0;
    }

    /// @notice Check if nonce is valid and invalidate it
    /// @param taker address
    /// @param nonce The nonce to invalidate
    /// @param isLimitOrder True if it is a limit order
    function invalidateOrderNonce(address taker, uint256 nonce, bool isLimitOrder) private {
        require(nonce != 0, "ZERO_NONCE");
        uint256 invalidatorSlot = nonce >> 8;
        uint256 invalidatorBit = 1 << (nonce & 0xff);
        mapping(uint256 => uint256) storage invalidNonces = isLimitOrder ? limitOrdersNonces[taker] : standardNonces[taker];
        uint256 invalidator = invalidNonces[invalidatorSlot];
        require(invalidator & invalidatorBit != invalidatorBit, "INVALID_NONCE");
        invalidNonces[invalidatorSlot] = invalidator | invalidatorBit;
    }

    /// @notice validate if increased amounts are more than initial amounts that user signed
    /// @param increasedAmounts The increased amounts to validate (if empty, return initial amounts)
    /// @param initialAmounts The initial amounts to validate against
    /// @return The increased amounts if exist, otherwise the initial amounts
    function validateIncreasedAmounts(
        uint256[] calldata increasedAmounts, uint256[] calldata initialAmounts
    ) internal returns (uint256[] calldata){
        if (increasedAmounts.length == 0) {
            return initialAmounts;
        }
        require(increasedAmounts.length == initialAmounts.length, "INVALID_INCREASED_AMOUNTS_LENGTH");
        for (uint256 i; i < increasedAmounts.length; ++i) {
            require(increasedAmounts[i] >= initialAmounts[i], "INVALID_INCREASED_AMOUNTS");
        }
        return increasedAmounts;
    }

    /// @notice validate all information about the batch of orders
    /// @param orders to validate
    /// @param hooks All takers hooks to validate
    /// @param signatures All takers signatures to check against
    /// @param curFillPercents Partial fill percent for each order
    function validateBatchOrders(
        JamOrder.Data[] calldata orders, JamHooks.Def[] calldata hooks, Signature.TypedSignature[] calldata signatures,
        Signature.TakerPermitsInfo[] calldata takersPermitsInfo, bool[] calldata takersPermitsUsage, uint16[] calldata curFillPercents
    ) internal {
        bool isMaxFill = curFillPercents.length == 0;
        bool noHooks = hooks.length == 0;
        bool allTakersWithoutPermits = takersPermitsUsage.length == 0;
        require(orders.length == signatures.length, "INVALID_SIGNATURES_LENGTH");
        require(orders.length == takersPermitsUsage.length || allTakersWithoutPermits, "INVALID_TAKERS_PERMITS_USAGE_LENGTH");
        require(orders.length == hooks.length || noHooks, "INVALID_HOOKS_LENGTH");
        require(orders.length == curFillPercents.length || isMaxFill, "INVALID_FILL_PERCENTS_LENGTH");
        uint takersWithPermits;
        for (uint i; i < orders.length; ++i) {
            require(orders[i].receiver != address(this), "INVALID_RECEIVER_FOR_BATCH_SETTLE");
            validateOrder(
                orders[i], noHooks ? JamHooks.Def(new JamInteraction.Data[](0), new JamInteraction.Data[](0)) : hooks[i],
                signatures[i], isMaxFill ? BMath.HUNDRED_PERCENT : curFillPercents[i]
            );
            if (!allTakersWithoutPermits && takersPermitsUsage[i]){
                ++takersWithPermits;
            }
        }
        require(takersPermitsInfo.length == takersWithPermits, "INVALID_TAKERS_PERMITS_LENGTH");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../libraries/JamOrder.sol";
import "../libraries/common/BMath.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title JamTransfer
/// @notice Functions for transferring tokens from SettlementContract
abstract contract JamTransfer {

    event NativeTransfer(address indexed receiver, uint256 amount);
    using SafeERC20 for IERC20;

    /// @dev Transfer tokens from this contract to receiver
    /// @param tokens tokens' addresses
    /// @param amounts tokens' amounts
    /// @param nftIds NFTs' ids
    /// @param tokenTransferTypes command sequence of transfer types
    /// @param receiver address
    function transferTokensFromContract(
        address[] calldata tokens,
        uint256[] memory amounts,
        uint256[] calldata nftIds,
        bytes calldata tokenTransferTypes,
        address receiver,
        uint16 fillPercent,
        bool transferExactAmounts
    ) internal {
        uint nftInd;
        for (uint i; i < tokens.length; ++i) {
            if (tokenTransferTypes[i] == Commands.SIMPLE_TRANSFER) {
                uint tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
                uint partialFillAmount = BMath.getPercentage(amounts[i], fillPercent);
                require(tokenBalance >= partialFillAmount, "INVALID_OUTPUT_TOKEN_BALANCE");
                IERC20(tokens[i]).safeTransfer(receiver, transferExactAmounts ? partialFillAmount : tokenBalance);
            } else if (tokenTransferTypes[i] == Commands.NATIVE_TRANSFER){
                require(tokens[i] == JamOrder.NATIVE_TOKEN, "INVALID_NATIVE_TOKEN");
                uint tokenBalance = address(this).balance;
                uint partialFillAmount = BMath.getPercentage(amounts[i], fillPercent);
                require(tokenBalance >= partialFillAmount, "INVALID_OUTPUT_NATIVE_BALANCE");
                (bool sent, ) = payable(receiver).call{value: transferExactAmounts ?  partialFillAmount : tokenBalance}("");
                require(sent, "FAILED_TO_SEND_ETH");
                emit NativeTransfer(receiver, transferExactAmounts ? partialFillAmount : tokenBalance);
            } else if (tokenTransferTypes[i] == Commands.NFT_ERC721_TRANSFER) {
                uint tokenBalance = IERC721(tokens[i]).balanceOf(address(this));
                require(amounts[i] == 1 && tokenBalance >= 1, "INVALID_OUTPUT_ERC721_AMOUNT");
                IERC721(tokens[i]).safeTransferFrom(address(this), receiver, nftIds[nftInd++]);
            } else if (tokenTransferTypes[i] == Commands.NFT_ERC1155_TRANSFER) {
                uint tokenBalance = IERC1155(tokens[i]).balanceOf(address(this), nftIds[nftInd]);
                require(tokenBalance >= amounts[i], "INVALID_OUTPUT_ERC1155_BALANCE");
                IERC1155(tokens[i]).safeTransferFrom(
                    address(this), receiver, nftIds[nftInd++], transferExactAmounts ?  amounts[i] : tokenBalance, ""
                );
            } else {
                revert("INVALID_TRANSFER_TYPE");
            }
        }
        require(nftInd == nftIds.length, "INVALID_BUY_NFT_IDS_LENGTH");
    }

    /// @dev Transfer native tokens to receiver from this contract
    /// @param receiver address
    /// @param amount amount of native tokens
    function transferNativeFromContract(address receiver, uint256 amount) public {
        (bool sent, ) = payable(receiver).call{value: amount}("");
        require(sent, "FAILED_TO_SEND_ETH");
    }

    /// @dev Calculate new amounts of tokens if solver transferred excess to contract during settleBatch
    /// @param curInd index of current order
    /// @param orders array of orders
    /// @param fillPercents[] fill percentage
    /// @return array of new amounts
    function calculateNewAmounts(
        uint256 curInd,
        JamOrder.Data[] calldata orders,
        uint16[] memory fillPercents
    ) internal returns (uint256[] memory) {
        JamOrder.Data calldata curOrder = orders[curInd];
        uint256[] memory newAmounts = new uint256[](curOrder.buyTokens.length);
        uint16 curFillPercent = fillPercents.length == 0 ? BMath.HUNDRED_PERCENT : fillPercents[curInd];
        for (uint i; i < curOrder.buyTokens.length; ++i) {
            if (curOrder.buyTokenTransfers[i] == Commands.SIMPLE_TRANSFER || curOrder.buyTokenTransfers[i] == Commands.NATIVE_TRANSFER) {
                uint256 fullAmount;
                for (uint j = curInd; j < orders.length; ++j) {
                    for (uint k; k < orders[j].buyTokens.length; ++k) {
                        if (orders[j].buyTokens[k] == curOrder.buyTokens[i]) {
                            fullAmount += orders[j].buyAmounts[k];
                            require(fillPercents.length == 0 || curFillPercent == fillPercents[j], "DIFF_FILL_PERCENT_FOR_SAME_TOKEN");
                        }
                    }
                }
                uint256 tokenBalance = curOrder.buyTokenTransfers[i] == Commands.NATIVE_TRANSFER ?
                    address(this).balance : IERC20(curOrder.buyTokens[i]).balanceOf(address(this));
                // if at least two takers buy same token, we need to divide the whole tokenBalance among them.
                // for edge case with newAmounts[i] overflow, solver should submit tx with transferExactAmounts=true
                newAmounts[i] = BMath.getInvertedPercentage(tokenBalance * curOrder.buyAmounts[i] / fullAmount, curFillPercent);
                if (newAmounts[i] < curOrder.buyAmounts[i]) {
                    newAmounts[i] = curOrder.buyAmounts[i];
                }
            } else {
                newAmounts[i] = curOrder.buyAmounts[i];
            }
        }
        return newAmounts;
    }


    /// @dev Check if there are duplicate tokens
    /// @param tokens tokens' addresses
    /// @param nftIds NFTs' ids
    /// @param tokenTransferTypes command sequence of transfer types
    /// @return true if there are duplicate tokens
    function hasDuplicate(
        address[] calldata tokens, uint256[] calldata nftIds, bytes calldata tokenTransferTypes
    ) internal pure returns (bool) {
        if (tokens.length == 0) {
            return false;
        }
        uint curNftInd;
        for (uint i; i < tokens.length - 1; ++i) {
            uint tmpNftInd = curNftInd;
            for (uint j = i + 1; j < tokens.length; ++j) {
                if (tokenTransferTypes[j] == Commands.NFT_ERC721_TRANSFER || tokenTransferTypes[j] == Commands.NFT_ERC1155_TRANSFER){
                    ++tmpNftInd;
                }
                if (tokens[i] == tokens[j]) {
                    if (tokenTransferTypes[i] == Commands.NFT_ERC721_TRANSFER ||
                        tokenTransferTypes[i] == Commands.NFT_ERC1155_TRANSFER){
                        if (nftIds[curNftInd] == nftIds[tmpNftInd]){
                            return true;
                        }
                    } else {
                        return true;
                    }
                }
            }
            if (tokenTransferTypes[i] == Commands.NFT_ERC721_TRANSFER || tokenTransferTypes[i] == Commands.NFT_ERC1155_TRANSFER){
                ++curNftInd;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDaiLikePermit {
    /// @param holder The address of the token owner.
    /// @param spender The address of the token spender.
    /// @param nonce The owner's nonce, increases at each call to permit.
    /// @param expiry The timestamp at which the permit is no longer valid.
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0.
    /// @param v Must produce valid secp256k1 signature from the owner along with r and s.
    /// @param r Must produce valid secp256k1 signature from the owner along with v and s.
    /// @param s Must produce valid secp256k1 signature from the owner along with r and v.
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // DAI's Polygon getNonce, instead of `nonces(address)` function
    function getNonce(address user) external view returns (uint256 nonce);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../libraries/Signature.sol";

/// @title IJamBalanceManager
/// @notice User approvals are made here. This handles the complexity of multiple allowance types. 
interface IJamBalanceManager {

    /// @dev All information needed to transfer tokens
    struct TransferData {
        address from;
        address receiver;
        address[] tokens;
        uint256[] amounts;
        uint256[] nftIds;
        bytes tokenTransferTypes;
        uint16 fillPercent;
    }

    /// @dev indices for transferTokensWithPermits function
    struct Indices {
        uint64 batchToApproveInd; // current `batchToApprove` index
        uint64 permitSignaturesInd; // current `takerPermitsInfo.permitSignatures` index
        uint64 nftsInd; // current `data.nftIds` index
        uint64 batchLen; // current length of `batchTransferDetails`
    }

    /// @notice Transfer tokens from taker to solverContract/settlementContract/makerAddress.
    /// Or transfer tokens directly from maker to taker for settleInternal case
    /// @param transferData data for transfer
    function transferTokens(
        TransferData calldata transferData
    ) external;

    /// @notice Transfer tokens from taker to solverContract/settlementContract
    /// @param transferData data for transfer
    /// @param takerPermitsInfo taker permits info
    function transferTokensWithPermits(
        TransferData calldata transferData,
        Signature.TakerPermitsInfo calldata takerPermitsInfo
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../libraries/JamInteraction.sol";
import "../libraries/JamOrder.sol";
import "../libraries/JamHooks.sol";
import "../libraries/Signature.sol";
import "../libraries/ExecInfo.sol";

interface IJamSettlement {

    /// @dev Event emitted when a settlement is executed successfully
    event Settlement(uint256 indexed nonce);

    /// @dev Settle a jam order.
    /// Pulls sell tokens into the contract and ensures that after running interactions receiver has the minimum of buy
    /// @param order user signed order
    /// @param signature user signature
    /// @param interactions list of interactions to settle the order
    /// @param hooks pre and post interactions
    /// @param solverData solver specifies this data by itself
    function settle(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def calldata hooks,
        ExecInfo.SolverData calldata solverData
    ) external payable;

    /// @dev Settle a jam order using taker's Permit/Permit2 signatures
    /// Pulls sell tokens into the contract and ensures that after running interactions receiver has the minimum of buy
    /// @param order user signed order
    /// @param signature user signature
    /// @param takerPermitsInfo taker information about permit and permit2
    /// @param interactions list of interactions to settle the order
    /// @param hooks pre and post interactions
    /// @param solverData solver specifies this data by itself
    function settleWithPermitsSignatures(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        Signature.TakerPermitsInfo calldata takerPermitsInfo,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def calldata hooks,
        ExecInfo.SolverData calldata solverData
    ) external payable;

    /// @dev Settle a jam order.
    /// Pulls sell tokens into the contract and ensures that after running interactions receiver has the minimum of buy
    /// @param order user signed order
    /// @param signature user signature
    /// @param hooks pre and post interactions
    /// @param makerData maker specifies this data by itself
    function settleInternal(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        JamHooks.Def calldata hooks,
        ExecInfo.MakerData calldata makerData
    ) external payable;

    /// @dev Settle a jam order using taker's Permit/Permit2 signatures
    /// Pulls sell tokens into the contract and ensures that after running interactions receiver has the minimum of buy
    /// @param order user signed order
    /// @param signature user signature
    /// @param takerPermitsInfo taker information about permit and permit2
    /// @param hooks pre and post interactions
    /// @param makerData maker specifies this data by itself
    function settleInternalWithPermitsSignatures(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        Signature.TakerPermitsInfo calldata takerPermitsInfo,
        JamHooks.Def calldata hooks,
        ExecInfo.MakerData calldata makerData
    ) external payable;

    /// @dev Settle a batch of orders.
    /// Pulls sell tokens into the contract and ensures that after running interactions receivers have the minimum of buy
    /// @param orders takers signed orders
    /// @param signatures takers signatures
    /// @param takersPermitsInfo takers information about permit and permit2
    /// @param interactions list of interactions to settle the order
    /// @param hooks pre and post takers interactions
    /// @param solverData solver specifies this data by itself
    function settleBatch(
        JamOrder.Data[] calldata orders,
        Signature.TypedSignature[] calldata signatures,
        Signature.TakerPermitsInfo[] calldata takersPermitsInfo,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def[] calldata hooks,
        ExecInfo.BatchSolverData calldata solverData
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


// Part of IAllowanceTransfer(https://github.com/Uniswap/permit2/blob/main/src/interfaces/IAllowanceTransfer.sol)
interface IPermit2 {

    // ------------------
    // IAllowanceTransfer
    // ------------------

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address user, address token, address spender)
    external
    view
    returns (uint160 amount, uint48 expiration, uint48 nonce);

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/IJamBalanceManager.sol";
import "./interfaces/IPermit2.sol";
import "./interfaces/IDaiLikePermit.sol";
import "./libraries/JamOrder.sol";
import "./libraries/Signature.sol";
import "./libraries/common/SafeCast160.sol";
import "./libraries/common/BMath.sol";
import "./base/JamTransfer.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title JamBalanceManager
/// @notice The reason a balance manager exists is to prevent interaction to the settlement contract draining user funds
/// By having another contract that allowances are made to, we can enforce that it is only used to draw in user balances to settlement and not sent out
contract JamBalanceManager is IJamBalanceManager {
    address private immutable operator;

    using SafeERC20 for IERC20;

    IPermit2 private immutable PERMIT2;
    address private immutable DAI_TOKEN;
    uint256 private immutable _chainId;

    constructor(address _operator, address _permit2, address _daiAddress) {
        // Operator can be defined at creation time with `msg.sender`
        // Pass in the settlement - and that can be the only caller.
        operator = _operator;
        _chainId = block.chainid;
        PERMIT2 = IPermit2(_permit2);
        DAI_TOKEN = _daiAddress;
    }

    modifier onlyOperator(address account) {
        require(account == operator, "INVALID_CALLER");
        _;
    }

    /// @inheritdoc IJamBalanceManager
    function transferTokens(
        TransferData calldata data
    ) onlyOperator(msg.sender) external {
        IPermit2.AllowanceTransferDetails[] memory batchTransferDetails;
        uint nftsInd;
        uint batchLen;
        for (uint i; i < data.tokens.length; ++i) {
            if (data.tokenTransferTypes[i] == Commands.SIMPLE_TRANSFER) {
                IERC20(data.tokens[i]).safeTransferFrom(
                    data.from, data.receiver, BMath.getPercentage(data.amounts[i], data.fillPercent)
                );
            } else if (data.tokenTransferTypes[i] == Commands.PERMIT2_TRANSFER) {
                if (batchLen == 0){
                    batchTransferDetails = new IPermit2.AllowanceTransferDetails[](data.tokens.length - i);
                }
                batchTransferDetails[batchLen++] = IPermit2.AllowanceTransferDetails({
                    from: data.from,
                    to: data.receiver,
                    amount: SafeCast160.toUint160(BMath.getPercentage(data.amounts[i], data.fillPercent)),
                    token: data.tokens[i]
                });
                continue;
            } else if (data.tokenTransferTypes[i] == Commands.NATIVE_TRANSFER) {
                require(data.tokens[i] == JamOrder.NATIVE_TOKEN, "INVALID_NATIVE_TOKEN_ADDRESS");
                require(data.fillPercent == BMath.HUNDRED_PERCENT, "INVALID_FILL_PERCENT");
                if (data.receiver != operator){
                    JamTransfer(operator).transferNativeFromContract(
                        data.receiver, BMath.getPercentage(data.amounts[i], data.fillPercent)
                    );
                }
            } else if (data.tokenTransferTypes[i] == Commands.NFT_ERC721_TRANSFER) {
                require(data.fillPercent == BMath.HUNDRED_PERCENT, "INVALID_FILL_PERCENT");
                require(data.amounts[i] == 1, "INVALID_ERC721_AMOUNT");
                IERC721(data.tokens[i]).safeTransferFrom(data.from, data.receiver, data.nftIds[nftsInd++]);
            } else if (data.tokenTransferTypes[i] == Commands.NFT_ERC1155_TRANSFER) {
                require(data.fillPercent == BMath.HUNDRED_PERCENT, "INVALID_FILL_PERCENT");
                IERC1155(data.tokens[i]).safeTransferFrom(data.from, data.receiver, data.nftIds[nftsInd++], data.amounts[i], "");
            } else {
                revert("INVALID_TRANSFER_TYPE");
            }
            if (batchLen != 0){
                assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
            }
        }
        require(nftsInd == data.nftIds.length, "INVALID_NFT_IDS_LENGTH");
        require(batchLen == batchTransferDetails.length, "INVALID_BATCH_PERMIT2_LENGTH");

        if (batchLen != 0){
            PERMIT2.transferFrom(batchTransferDetails);
        }
    }

    /// @inheritdoc IJamBalanceManager
    function transferTokensWithPermits(
        TransferData calldata data,
        Signature.TakerPermitsInfo calldata takerPermitsInfo
    ) onlyOperator(msg.sender) external {
        IPermit2.AllowanceTransferDetails[] memory batchTransferDetails;
        IPermit2.PermitDetails[] memory batchToApprove = new IPermit2.PermitDetails[](takerPermitsInfo.noncesPermit2.length);
        Indices memory indices = Indices(0, 0, 0, 0);
        for (uint i; i < data.tokens.length; ++i) {
            if (data.tokenTransferTypes[i] == Commands.SIMPLE_TRANSFER || data.tokenTransferTypes[i] == Commands.CALL_PERMIT_THEN_TRANSFER) {
                if (data.tokenTransferTypes[i] == Commands.CALL_PERMIT_THEN_TRANSFER){
                    permitToken(
                        data.from, data.tokens[i], takerPermitsInfo.deadline, takerPermitsInfo.permitSignatures[indices.permitSignaturesInd++]
                    );
                }
                IERC20(data.tokens[i]).safeTransferFrom(
                    data.from, data.receiver, BMath.getPercentage(data.amounts[i], data.fillPercent)
                );
            } else if (data.tokenTransferTypes[i] == Commands.PERMIT2_TRANSFER || data.tokenTransferTypes[i] == Commands.CALL_PERMIT2_THEN_TRANSFER) {
                if (data.tokenTransferTypes[i] == Commands.CALL_PERMIT2_THEN_TRANSFER){
                    batchToApprove[indices.batchToApproveInd] = IPermit2.PermitDetails({
                        token: data.tokens[i],
                        amount: type(uint160).max,
                        expiration: takerPermitsInfo.deadline,
                        nonce: takerPermitsInfo.noncesPermit2[indices.batchToApproveInd]
                    });
                    ++indices.batchToApproveInd;
                }

                if (indices.batchLen == 0){
                    batchTransferDetails = new IPermit2.AllowanceTransferDetails[](data.tokens.length - i);
                }
                batchTransferDetails[indices.batchLen++] = IPermit2.AllowanceTransferDetails({
                    from: data.from,
                    to: data.receiver,
                    amount: SafeCast160.toUint160(BMath.getPercentage(data.amounts[i], data.fillPercent)),
                    token: data.tokens[i]
                });
                continue;
            } else if (data.tokenTransferTypes[i] == Commands.NATIVE_TRANSFER) {
                require(data.tokens[i] == JamOrder.NATIVE_TOKEN, "INVALID_NATIVE_TOKEN_ADDRESS");
                require(data.fillPercent == BMath.HUNDRED_PERCENT, "INVALID_FILL_PERCENT");
                if (data.receiver != operator){
                    JamTransfer(operator).transferNativeFromContract(
                        data.receiver, BMath.getPercentage(data.amounts[i], data.fillPercent)
                    );
                }
            } else if (data.tokenTransferTypes[i] == Commands.NFT_ERC721_TRANSFER) {
                require(data.fillPercent == BMath.HUNDRED_PERCENT, "INVALID_FILL_PERCENT");
                require(data.amounts[i] == 1, "INVALID_ERC721_AMOUNT");
                IERC721(data.tokens[i]).safeTransferFrom(data.from, data.receiver, data.nftIds[indices.nftsInd++]);
            } else if (data.tokenTransferTypes[i] == Commands.NFT_ERC1155_TRANSFER) {
                require(data.fillPercent == BMath.HUNDRED_PERCENT, "INVALID_FILL_PERCENT");
                IERC1155(data.tokens[i]).safeTransferFrom(data.from, data.receiver, data.nftIds[indices.nftsInd++], data.amounts[i], "");
            } else {
                revert("INVALID_TRANSFER_TYPE");
            }

            // Shortening array
            if (indices.batchLen != 0){
                assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
            }
        }
        require(indices.batchToApproveInd == batchToApprove.length, "INVALID_NUMBER_OF_TOKENS_TO_APPROVE");
        require(indices.batchLen == batchTransferDetails.length, "INVALID_BATCH_PERMIT2_LENGTH");
        require(indices.permitSignaturesInd == takerPermitsInfo.permitSignatures.length, "INVALID_NUMBER_OF_PERMIT_SIGNATURES");
        require(indices.nftsInd == data.nftIds.length, "INVALID_NFT_IDS_LENGTH");

        if (batchToApprove.length != 0) {
            // Update approvals for new taker's data.tokens
            PERMIT2.permit({
                owner: data.from,
                permitBatch: IPermit2.PermitBatch({
                    details: batchToApprove,
                    spender: address(this),
                    sigDeadline: takerPermitsInfo.deadline
                }),
                signature: takerPermitsInfo.signatureBytesPermit2
            });
        }

        // Batch transfer
        if (indices.batchLen != 0){
            PERMIT2.transferFrom(batchTransferDetails);
        }
    }

    /// @dev Call permit function on token contract, supports both ERC20Permit and DaiPermit formats
    /// @param takerAddress address
    /// @param tokenAddress address
    /// @param deadline timestamp when the signature expires
    /// @param permitSignature signature
    function permitToken(
        address takerAddress, address tokenAddress, uint deadline, bytes calldata permitSignature
    ) private {
        (bytes32 r, bytes32 s, uint8 v) = Signature.getRsv(permitSignature);

        if (tokenAddress == DAI_TOKEN){
            if (_chainId == 137){
                IDaiLikePermit(tokenAddress).permit(
                    takerAddress, address(this), IDaiLikePermit(tokenAddress).getNonce(takerAddress), deadline, true, v, r, s
                );
            } else {
                IDaiLikePermit(tokenAddress).permit(
                    takerAddress, address(this), IERC20Permit(tokenAddress).nonces(takerAddress), deadline, true, v, r, s
                );
            }
        } else {
            IERC20Permit(tokenAddress).permit(takerAddress, address(this), type(uint).max, deadline, v, r, s);
        }

    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./JamBalanceManager.sol";
import "./base/JamSigning.sol";
import "./base/JamTransfer.sol";
import "./interfaces/IJamBalanceManager.sol";
import "./interfaces/IJamSettlement.sol";
import "./libraries/JamInteraction.sol";
import "./libraries/JamOrder.sol";
import "./libraries/JamHooks.sol";
import "./libraries/ExecInfo.sol";
import "./libraries/common/BMath.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @title JamSettlement
/// @notice The settlement contract executes the full lifecycle of a trade on chain.
/// Solvers figure out what "interactions" to pass to this contract such that the user order is fulfilled.
/// The contract ensures that only the user agreed price can be executed and otherwise will fail to execute.
/// As long as the trade is fulfilled, the solver is allowed to keep any potential excess.
contract JamSettlement is IJamSettlement, ReentrancyGuard, JamSigning, JamTransfer, ERC721Holder, ERC1155Holder {

    IJamBalanceManager public immutable balanceManager;

    constructor(address _permit2, address _daiAddress) {
        balanceManager = new JamBalanceManager(address(this), _permit2, _daiAddress);
    }

    receive() external payable {}

    function runInteractions(JamInteraction.Data[] calldata interactions) internal returns (bool result) {
        for (uint i; i < interactions.length; ++i) {
            // Prevent calls to balance manager
            require(interactions[i].to != address(balanceManager));
            bool execResult = JamInteraction.execute(interactions[i]);

            // Return false only if interaction was meant to succeed but failed.
            if (!execResult && interactions[i].result) return false;
        }
        return true;
    }

    /// @inheritdoc IJamSettlement
    function settle(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def calldata hooks,
        ExecInfo.SolverData calldata solverData
    ) external payable nonReentrant {
        validateOrder(order, hooks, signature, solverData.curFillPercent);
        require(runInteractions(hooks.beforeSettle), "BEFORE_SETTLE_HOOKS_FAILED");
        balanceManager.transferTokens(
            IJamBalanceManager.TransferData(
                order.taker, solverData.balanceRecipient, order.sellTokens, order.sellAmounts,
                order.sellNFTIds, order.sellTokenTransfers, solverData.curFillPercent
            )
        );
        _settle(order, interactions, hooks, solverData.curFillPercent);
    }

    /// @inheritdoc IJamSettlement
    function settleWithPermitsSignatures(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        Signature.TakerPermitsInfo calldata takerPermitsInfo,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def calldata hooks,
        ExecInfo.SolverData calldata solverData
    ) external payable nonReentrant {
        validateOrder(order, hooks, signature, solverData.curFillPercent);
        require(runInteractions(hooks.beforeSettle), "BEFORE_SETTLE_HOOKS_FAILED");
        balanceManager.transferTokensWithPermits(
            IJamBalanceManager.TransferData(
                order.taker, solverData.balanceRecipient, order.sellTokens, order.sellAmounts,
                order.sellNFTIds, order.sellTokenTransfers, solverData.curFillPercent
            ), takerPermitsInfo
        );
        _settle(order, interactions, hooks, solverData.curFillPercent);
    }

    /// @inheritdoc IJamSettlement
    function settleInternal(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        JamHooks.Def calldata hooks,
        ExecInfo.MakerData calldata makerData
    ) external payable nonReentrant {
        validateOrder(order, hooks, signature, makerData.curFillPercent);
        require(runInteractions(hooks.beforeSettle), "BEFORE_SETTLE_HOOKS_FAILED");
        balanceManager.transferTokens(
            IJamBalanceManager.TransferData(
                order.taker, msg.sender, order.sellTokens, order.sellAmounts,
                order.sellNFTIds, order.sellTokenTransfers, makerData.curFillPercent
            )
        );
        _settleInternal(order, hooks, makerData);
    }

    /// @inheritdoc IJamSettlement
    function settleInternalWithPermitsSignatures(
        JamOrder.Data calldata order,
        Signature.TypedSignature calldata signature,
        Signature.TakerPermitsInfo calldata takerPermitsInfo,
        JamHooks.Def calldata hooks,
        ExecInfo.MakerData calldata makerData
    ) external payable nonReentrant {
        validateOrder(order, hooks, signature, makerData.curFillPercent);
        require(runInteractions(hooks.beforeSettle), "BEFORE_SETTLE_HOOKS_FAILED");
        balanceManager.transferTokensWithPermits(
            IJamBalanceManager.TransferData(
                order.taker, msg.sender, order.sellTokens, order.sellAmounts,
                order.sellNFTIds, order.sellTokenTransfers, makerData.curFillPercent
            ), takerPermitsInfo
        );
        _settleInternal(order, hooks, makerData);
    }

    /// @inheritdoc IJamSettlement
    function settleBatch(
        JamOrder.Data[] calldata orders,
        Signature.TypedSignature[] calldata signatures,
        Signature.TakerPermitsInfo[] calldata takersPermitsInfo,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def[] calldata hooks,
        ExecInfo.BatchSolverData calldata solverData
    ) external payable nonReentrant {
        validateBatchOrders(orders, hooks, signatures, takersPermitsInfo, solverData.takersPermitsUsage, solverData.curFillPercents);
        bool isMaxFill = solverData.curFillPercents.length == 0;
        bool executeHooks = hooks.length != 0;
        uint takersPermitsInd;
        for (uint i; i < orders.length; ++i) {
            if (executeHooks){
                require(runInteractions(hooks[i].beforeSettle), "BEFORE_SETTLE_HOOKS_FAILED");
            }
            if (solverData.takersPermitsUsage.length != 0 && solverData.takersPermitsUsage[i]){
                balanceManager.transferTokensWithPermits(
                    IJamBalanceManager.TransferData(
                        orders[i].taker, solverData.balanceRecipient, orders[i].sellTokens, orders[i].sellAmounts,
                        orders[i].sellNFTIds, orders[i].sellTokenTransfers, isMaxFill ? BMath.HUNDRED_PERCENT : solverData.curFillPercents[i]
                    ), takersPermitsInfo[takersPermitsInd++]
                );
            } else {
                balanceManager.transferTokens(
                    IJamBalanceManager.TransferData(
                        orders[i].taker, solverData.balanceRecipient, orders[i].sellTokens, orders[i].sellAmounts,
                        orders[i].sellNFTIds, orders[i].sellTokenTransfers, isMaxFill ? BMath.HUNDRED_PERCENT : solverData.curFillPercents[i]
                    )
                );
            }
        }
        require(runInteractions(interactions), "INTERACTIONS_FAILED");
        for (uint i; i < orders.length; ++i) {
            uint256[] memory curBuyAmounts = solverData.transferExactAmounts ?
                orders[i].buyAmounts : calculateNewAmounts(i, orders, solverData.curFillPercents);
            transferTokensFromContract(
                orders[i].buyTokens, curBuyAmounts, orders[i].buyNFTIds, orders[i].buyTokenTransfers,
                orders[i].receiver, isMaxFill ? BMath.HUNDRED_PERCENT : solverData.curFillPercents[i], true
            );
            if (executeHooks){
                require(runInteractions(hooks[i].afterSettle), "AFTER_SETTLE_HOOKS_FAILED");
            }
            emit Settlement(orders[i].nonce);
        }
    }

    function _settle(
        JamOrder.Data calldata order,
        JamInteraction.Data[] calldata interactions,
        JamHooks.Def calldata hooks,
        uint16 curFillPercent
    ) private {
        require(runInteractions(interactions), "INTERACTIONS_FAILED");
        transferTokensFromContract(
            order.buyTokens, order.buyAmounts, order.buyNFTIds, order.buyTokenTransfers, order.receiver, curFillPercent, false
        );
        if (order.receiver == address(this)){
            require(!hasDuplicate(order.buyTokens, order.buyNFTIds, order.buyTokenTransfers), "DUPLICATE_TOKENS");
            require(hooks.afterSettle.length > 0, "AFTER_SETTLE_HOOKS_REQUIRED");
            for (uint i; i < hooks.afterSettle.length; ++i){
                require(hooks.afterSettle[i].result, "POTENTIAL_TOKENS_LOSS");
            }
        }
        require(runInteractions(hooks.afterSettle), "AFTER_SETTLE_HOOKS_FAILED");
        emit Settlement(order.nonce);
    }

    function _settleInternal(
        JamOrder.Data calldata order,
        JamHooks.Def calldata hooks,
        ExecInfo.MakerData calldata makerData
    ) private {
        uint256[] calldata buyAmounts = validateIncreasedAmounts(makerData.increasedBuyAmounts, order.buyAmounts);
        balanceManager.transferTokens(
            IJamBalanceManager.TransferData(
                msg.sender, order.receiver, order.buyTokens, buyAmounts,
                order.buyNFTIds, order.buyTokenTransfers, makerData.curFillPercent
            )
        );
        require(runInteractions(hooks.afterSettle), "AFTER_SETTLE_HOOKS_FAILED");
        emit Settlement(order.nonce);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


import "./libraries/JamInteraction.sol";
import "./libraries/JamOrder.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @title JamSolver
/// @notice This is an example of solver used for tests only
contract JamSolver is ERC721Holder, ERC1155Holder{
    using SafeERC20 for IERC20;
    address public owner;
    address public settlement;
    address private constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _settlement) {
        owner = msg.sender;
        settlement = _settlement;
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlySettlement() {
        require(msg.sender == settlement);
        _;
    }

    modifier onlyOwnerOrigin() {
        require(tx.origin == owner);
        _;
    }

    function withdraw (address receiver) public onlyOwner {
        if (address(this).balance > 0) {
            payable(receiver).call{value: address(this).balance}("");
        }
    }

    function withdrawTokens (address[] calldata tokens, address receiver) public onlyOwner {
        for (uint i; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            if (token.balanceOf(address(this)) > 0) {
                token.safeTransfer(receiver, token.balanceOf(address(this)));
            }
        }
    }

    function execute (
        JamInteraction.Data[] calldata calls, address[] calldata outputTokens, uint256[] calldata outputAmounts,
        uint256[] calldata outputIds, bytes calldata outputTransferTypes, address receiver
    ) public payable onlyOwnerOrigin onlySettlement {
        for(uint i; i < calls.length; i++) {
            JamInteraction.execute(calls[i]);
        }

        for(uint i; i < outputTokens.length; i++) {
            if (outputTransferTypes[i] == Commands.SIMPLE_TRANSFER){
                IERC20 token = IERC20(outputTokens[i]);
                token.safeTransfer(receiver, outputAmounts[i]);
            } else if (outputTransferTypes[i] == Commands.NATIVE_TRANSFER){
                payable(receiver).call{value: outputAmounts[i]}("");
            } else if (outputTransferTypes[i] == Commands.NFT_ERC721_TRANSFER){
                IERC721 token = IERC721(outputTokens[i]);
                token.safeTransferFrom(address(this), receiver, outputIds[i]);
            } else if (outputTransferTypes[i] == Commands.NFT_ERC1155_TRANSFER){
                IERC1155 token = IERC1155(outputTokens[i]);
                token.safeTransferFrom(address(this), receiver, outputIds[i], outputAmounts[i], "");
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library BMath {

    uint16 internal constant HUNDRED_PERCENT = 10000;

    function getPercentage(uint256 value, uint16 percent) internal pure returns (uint256){
        if (percent >= HUNDRED_PERCENT){
            return value;
        }
        return value * percent / HUNDRED_PERCENT;
    }

    function getInvertedPercentage(uint256 value, uint16 percent) internal pure returns (uint256){
        if (percent >= HUNDRED_PERCENT){
            return value;
        }
        return value * HUNDRED_PERCENT / percent;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SafeCast160 {
    /// @notice Thrown when a valude greater than type(uint160).max is cast to uint160
    error UnsafeCast();

    /// @notice Safely casts uint256 to uint160
    /// @param value The uint256 to be cast
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) revert UnsafeCast();
        return uint160(value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library ExecInfo {

    /// @dev Data structure that solvers specify by themselves in settle() function
    struct SolverData {
        address balanceRecipient; // receiver of the initial tokens transfer from taker (usually it is solver contract)
        uint16 curFillPercent; // percentage by which the solver fills the order (curFillPercent >= order.minFillPercent)
    }

    /// @dev Data structure that solvers specify by themselves in settleBatch() function
    struct BatchSolverData {
        address balanceRecipient; // receiver of the initial tokens transfer from taker (usually it is solver contract)
        uint16[] curFillPercents; // if empty array, then all orders will be 100% filled
        bool[] takersPermitsUsage; // indicates whether taker has permit/permit2 signature for each order
                                  // (if empty array, then all orders without permits signatures)
        bool transferExactAmounts; // True - if solver is planning to transfer exact amounts which are specified in order.buyAmounts
                                   // False - if solver is planning to transfer more tokens than in order.buyAmounts,
    }

    /// @dev Data structure that makers specify by themselves in settleInternal() function
    struct MakerData {
        uint256[] increasedBuyAmounts; // if maker wants to increase user's order.buyAmounts,
                                       // then maker can specify new buyAmounts here, otherwise it should be empty array
        uint16 curFillPercent; // percentage by which the maker fills the order (curFillPercent >= order.minFillPercent)
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../libraries/JamInteraction.sol";

/// @title JamHooks
/// @notice JamHooks is a library for managing pre and post interactions
library JamHooks {

    /// @dev Data structure for pre and post interactions
    struct Def {
        JamInteraction.Data[] beforeSettle;
        JamInteraction.Data[] afterSettle;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library JamInteraction {
    /// @dev Data representing an interaction on the chain
    struct Data {
        /// 
        bool result;
        address to;
        uint256 value;
        bytes data;
    }

    /// @dev Execute the interaciton and return the result
    /// 
    /// @param interaction The interaction to execute
    /// @return result Whether the interaction succeeded
    function execute(Data calldata interaction) internal returns (bool result) {
        (bool _result,) = payable(interaction.to).call{ value: interaction.value }(interaction.data);
        return _result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @title Commands
/// @notice Commands are used to specify how tokens are transferred in Data.buyTokenTransfers and Data.sellTokenTransfers
library Commands {
    bytes1 internal constant SIMPLE_TRANSFER = 0x00; // simple transfer with standard transferFrom
    bytes1 internal constant PERMIT2_TRANSFER = 0x01; // transfer using permit2.transfer
    bytes1 internal constant CALL_PERMIT_THEN_TRANSFER = 0x02; // call permit then simple transfer
    bytes1 internal constant CALL_PERMIT2_THEN_TRANSFER = 0x03; // call permit2.permit then permit2.transfer
    bytes1 internal constant NATIVE_TRANSFER = 0x04;
    bytes1 internal constant NFT_ERC721_TRANSFER = 0x05;
    bytes1 internal constant NFT_ERC1155_TRANSFER = 0x06;
}

/// @title JamOrder
library JamOrder {

    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Data representing a Jam Order.
    struct Data {
        address taker;
        address receiver;
        uint256 expiry;
        uint256 nonce;
        address executor; // only msg.sender=executor is allowed to execute (if executor=address(0), then order can be executed by anyone)
        uint16 minFillPercent; // 100% = 10000, if taker allows partial fills, then it could be less than 100%
        bytes32 hooksHash; // keccak256(pre interactions + post interactions)
        address[] sellTokens;
        address[] buyTokens;
        uint256[] sellAmounts;
        uint256[] buyAmounts;
        uint256[] sellNFTIds;
        uint256[] buyNFTIds;
        bytes sellTokenTransfers; // Commands sequence of sellToken transfer types
        bytes buyTokenTransfers; // Commands sequence of buyToken transfer types
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Signature {

    enum Type {
        NONE,    // 0
        EIP712,  //1
        EIP1271, //2
        ETHSIGN  //3
    }

    struct TypedSignature {
        Type signatureType;
        bytes signatureBytes;
    }

    struct TakerPermitsInfo {
        bytes[] permitSignatures;
        bytes signatureBytesPermit2;
        uint48[] noncesPermit2;
        uint48 deadline;
    }

    function getRsv(bytes memory sig) internal pure returns (bytes32, bytes32, uint8){
        require(sig.length == 65, "Invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }
        if (v < 27) v += 27;
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Invalid sig value S");
        require(v == 27 || v == 28, "Invalid sig value V");
        return (r, s, v);
    }
}