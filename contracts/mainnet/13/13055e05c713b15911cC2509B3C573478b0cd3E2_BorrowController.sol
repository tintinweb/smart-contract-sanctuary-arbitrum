// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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

// SPDX-License-Identifier: -
// License: https://license.coupon.finance/LICENSE.pdf

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBorrowController} from "./interfaces/IBorrowController.sol";
import {ILoanPositionManager} from "./interfaces/ILoanPositionManager.sol";
import {LoanPosition} from "./libraries/LoanPosition.sol";
import {Coupon} from "./libraries/Coupon.sol";
import {Epoch, EpochLibrary} from "./libraries/Epoch.sol";
import {Controller} from "./libraries/Controller.sol";
import {IPositionLocker} from "./interfaces/IPositionLocker.sol";

contract BorrowController is IBorrowController, Controller, IPositionLocker {
    using EpochLibrary for Epoch;

    ILoanPositionManager private immutable _loanPositionManager;

    modifier onlyPositionOwner(uint256 positionId) {
        if (_loanPositionManager.ownerOf(positionId) != msg.sender) revert InvalidAccess();
        _;
    }

    constructor(
        address wrapped1155Factory,
        address cloberMarketFactory,
        address couponManager,
        address weth,
        address loanPositionManager
    ) Controller(wrapped1155Factory, cloberMarketFactory, couponManager, weth) {
        _loanPositionManager = ILoanPositionManager(loanPositionManager);
    }

    function positionLockAcquired(bytes memory data) external returns (bytes memory result) {
        if (msg.sender != address(_loanPositionManager)) revert InvalidAccess();

        uint256 positionId;
        address user;
        (positionId, user, data) = abi.decode(data, (uint256, address, bytes));
        if (positionId == 0) {
            address collateralToken;
            address debtToken;
            (collateralToken, debtToken, data) = abi.decode(data, (address, address, bytes));
            positionId = _loanPositionManager.mint(collateralToken, debtToken);
            result = abi.encode(positionId);
        }
        LoanPosition memory position = _loanPositionManager.getPosition(positionId);

        uint256 maxPayInterest;
        uint256 minEarnInterest;
        (position.collateralAmount, position.debtAmount, position.expiredWith, maxPayInterest, minEarnInterest) =
            abi.decode(data, (uint256, uint256, Epoch, uint256, uint256));

        (Coupon[] memory couponsToMint, Coupon[] memory couponsToBurn, int256 collateralDelta, int256 debtDelta) =
        _loanPositionManager.adjustPosition(
            positionId, position.collateralAmount, position.debtAmount, position.expiredWith
        );
        if (collateralDelta < 0) {
            _loanPositionManager.withdrawToken(position.collateralToken, address(this), uint256(-collateralDelta));
        }
        if (debtDelta > 0) _loanPositionManager.withdrawToken(position.debtToken, address(this), uint256(debtDelta));
        if (couponsToMint.length > 0) {
            _loanPositionManager.mintCoupons(couponsToMint, address(this), "");
            _wrapCoupons(couponsToMint);
        }

        _executeCouponTrade(
            user,
            position.debtToken,
            couponsToMint,
            couponsToBurn,
            debtDelta < 0 ? uint256(-debtDelta) : 0,
            maxPayInterest,
            minEarnInterest
        );

        if (collateralDelta > 0) {
            _ensureBalance(position.collateralToken, user, uint256(collateralDelta));
            IERC20(position.collateralToken).approve(address(_loanPositionManager), uint256(collateralDelta));
            _loanPositionManager.depositToken(position.collateralToken, uint256(collateralDelta));
        }
        if (debtDelta < 0) {
            IERC20(position.debtToken).approve(address(_loanPositionManager), uint256(-debtDelta));
            _loanPositionManager.depositToken(position.debtToken, uint256(-debtDelta));
        }
        if (couponsToBurn.length > 0) {
            _unwrapCoupons(couponsToBurn);
            _loanPositionManager.burnCoupons(couponsToBurn);
        }

        _loanPositionManager.settlePosition(positionId);
    }

    function borrow(
        address collateralToken,
        address debtToken,
        uint256 collateralAmount,
        uint256 borrowAmount,
        uint256 maxPayInterest,
        uint16 loanEpochs,
        ERC20PermitParams calldata collateralPermitParams
    ) external payable nonReentrant wrapETH {
        _permitERC20(collateralToken, collateralPermitParams);

        bytes memory lockData =
            abi.encode(collateralAmount, borrowAmount, EpochLibrary.current().add(loanEpochs - 1), maxPayInterest, 0);
        lockData = abi.encode(0, msg.sender, abi.encode(collateralToken, debtToken, lockData));
        bytes memory result = _loanPositionManager.lock(lockData);
        uint256 positionId = abi.decode(result, (uint256));

        _burnAllSubstitute(collateralToken, msg.sender);
        _burnAllSubstitute(debtToken, msg.sender);
        _loanPositionManager.transferFrom(address(this), msg.sender, positionId);
    }

    function borrowMore(
        uint256 positionId,
        uint256 amount,
        uint256 maxPayInterest,
        PermitSignature calldata positionPermitParams
    ) external nonReentrant onlyPositionOwner(positionId) {
        _permitERC721(_loanPositionManager, positionId, positionPermitParams);
        LoanPosition memory position = _loanPositionManager.getPosition(positionId);
        position.debtAmount += amount;

        _loanPositionManager.lock(_encodeAdjustData(positionId, position, maxPayInterest, 0));

        _burnAllSubstitute(position.debtToken, msg.sender);
    }

    function addCollateral(
        uint256 positionId,
        uint256 amount,
        PermitSignature calldata positionPermitParams,
        ERC20PermitParams calldata collateralPermitParams
    ) external payable nonReentrant onlyPositionOwner(positionId) wrapETH {
        _permitERC721(_loanPositionManager, positionId, positionPermitParams);
        LoanPosition memory position = _loanPositionManager.getPosition(positionId);
        _permitERC20(position.collateralToken, collateralPermitParams);
        position.collateralAmount += amount;

        _loanPositionManager.lock(_encodeAdjustData(positionId, position, 0, 0));

        _burnAllSubstitute(position.collateralToken, msg.sender);
    }

    function removeCollateral(uint256 positionId, uint256 amount, PermitSignature calldata positionPermitParams)
        external
        nonReentrant
        onlyPositionOwner(positionId)
    {
        _permitERC721(_loanPositionManager, positionId, positionPermitParams);
        LoanPosition memory position = _loanPositionManager.getPosition(positionId);
        position.collateralAmount -= amount;

        _loanPositionManager.lock(_encodeAdjustData(positionId, position, 0, 0));

        _burnAllSubstitute(position.collateralToken, msg.sender);
    }

    function extendLoanDuration(
        uint256 positionId,
        uint16 epochs,
        uint256 maxPayInterest,
        PermitSignature calldata positionPermitParams,
        ERC20PermitParams calldata debtPermitParams
    ) external payable nonReentrant onlyPositionOwner(positionId) wrapETH {
        _permitERC721(_loanPositionManager, positionId, positionPermitParams);
        LoanPosition memory position = _loanPositionManager.getPosition(positionId);
        _permitERC20(position.debtToken, debtPermitParams);
        position.expiredWith = position.expiredWith.add(epochs);

        _loanPositionManager.lock(_encodeAdjustData(positionId, position, maxPayInterest, 0));

        _burnAllSubstitute(position.debtToken, msg.sender);
    }

    function shortenLoanDuration(
        uint256 positionId,
        uint16 epochs,
        uint256 minEarnInterest,
        PermitSignature calldata positionPermitParams
    ) external nonReentrant onlyPositionOwner(positionId) {
        _permitERC721(_loanPositionManager, positionId, positionPermitParams);
        LoanPosition memory position = _loanPositionManager.getPosition(positionId);
        position.expiredWith = position.expiredWith.sub(epochs);

        _loanPositionManager.lock(_encodeAdjustData(positionId, position, 0, minEarnInterest));

        _burnAllSubstitute(position.debtToken, msg.sender);
    }

    function repay(
        uint256 positionId,
        uint256 amount,
        uint256 minEarnInterest,
        PermitSignature calldata positionPermitParams,
        ERC20PermitParams calldata debtPermitParams
    ) external payable nonReentrant onlyPositionOwner(positionId) wrapETH {
        _permitERC721(_loanPositionManager, positionId, positionPermitParams);
        LoanPosition memory position = _loanPositionManager.getPosition(positionId);
        _permitERC20(position.debtToken, debtPermitParams);
        position.debtAmount -= amount;

        _loanPositionManager.lock(_encodeAdjustData(positionId, position, 0, minEarnInterest));

        _burnAllSubstitute(position.debtToken, msg.sender);
    }

    function _encodeAdjustData(uint256 id, LoanPosition memory p, uint256 maxPay, uint256 minEarn)
        internal
        view
        returns (bytes memory)
    {
        bytes memory data = abi.encode(p.collateralAmount, p.debtAmount, p.expiredWith, maxPay, minEarn);
        return abi.encode(id, msg.sender, data);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberMarketFactory {
    /**
     * @notice Emitted when a new volatile market is created.
     * @param market The address of the new market.
     * @param orderToken The address of the new market's order token.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param nonce The nonce for this market.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The scale factor of the price points.
     * @param r The common ratio between price points.
     */
    event CreateVolatileMarket(
        address indexed market,
        address orderToken,
        address quoteToken,
        address baseToken,
        uint256 quoteUnit,
        uint256 nonce,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 r
    );

    /**
     * @notice Emitted when a new stable market is created.
     * @param market The address of the new market.
     * @param orderToken The address of the new market's order token.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param nonce The nonce for this market.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The starting price point.
     * @param d The common difference between price points.
     */
    event CreateStableMarket(
        address indexed market,
        address orderToken,
        address quoteToken,
        address baseToken,
        uint256 quoteUnit,
        uint256 nonce,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    );

    /**
     * @notice Emitted when the address of the owner has changed.
     * @param previousOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event ChangeOwner(address previousOwner, address newOwner);

    /**
     * @notice Emitted when the DAO Treasury address has changed.
     * @param previousTreasury The address of the previous DAO Treasury.
     * @param newTreasury The address of the new DAO Treasury.
     */
    event ChangeDaoTreasury(address previousTreasury, address newTreasury);

    /**
     * @notice Emitted when the host address has changed.
     * @param market The address of the market that had a change of hosts.
     * @param previousHost The address of the previous host.
     * @param newHost The address of a new host.
     */
    event ChangeHost(address indexed market, address previousHost, address newHost);

    /**
     * @notice Returns the address of the deployed GeometricPriceBook.
     * @return The address of the GeometricPriceBook.
     */
    function deployedGeometricPriceBook(uint128 a, uint128 r) external view returns (address);

    /**
     * @notice Returns the address of the deployed GeometricPriceBook.
     * @return The address of the GeometricPriceBook.
     */
    function deployedArithmeticPriceBook(uint128 a, uint128 d) external view returns (address);

    /**
     * @notice Returns the address of the MarketDeployer.
     * @return The address of the MarketDeployer.
     */
    function marketDeployer() external view returns (address);

    /**
     * @notice Returns the address of the priceBookDeployer.
     * @return The address of the priceBookDeployer.
     */
    function priceBookDeployer() external view returns (address);

    /**
     * @notice Returns the address of the orderTokenDeployer.
     * @return The address of the orderTokenDeployer.
     */
    function orderTokenDeployer() external view returns (address);

    /**
     * @notice Returns the address of the OrderCanceler.
     * @return The address of the OrderCanceler.
     */
    function canceler() external view returns (address);

    /**
     * @notice Returns whether the specified token address has been registered as a quote token.
     * @param token The address of the token to check.
     * @return bool Whether the token is registered as a quote token.
     */
    function registeredQuoteTokens(address token) external view returns (bool);

    /**
     * @notice Returns the address of the factory owner
     * @return The address of the factory owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the address of the factory owner candidate
     * @return The address of the factory owner candidate
     */
    function futureOwner() external view returns (address);

    /**
     * @notice Returns the address of the DAO Treasury
     * @return The address of the DAO Treasury
     */
    function daoTreasury() external view returns (address);

    /**
     * @notice Returns the current nonce
     * @return The current nonce
     */
    function nonce() external view returns (uint256);

    /**
     * @notice Creates a new market with a VolatilePriceBook.
     * @param host The address of the new market's host.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The scale factor of the price points.
     * @param r The common ratio between price points.
     * @return The address of the created market.
     */
    function createVolatileMarket(
        address host,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 r
    ) external returns (address);

    /**
     * @notice Creates a new market with a StablePriceBook
     * @param host The address of the new market's host
     * @param quoteToken The address of the new market's quote token
     * @param baseToken The address of the new market's base token
     * @param quoteUnit The amount that one raw amount represents in quote tokens
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The starting price point.
     * @param d The common difference between price points.
     * @return The address of the created market.
     */
    function createStableMarket(
        address host,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    ) external returns (address);

    /**
     * @notice Change the DAO Treasury address.
     * @dev Only the factory owner can call this function.
     * @param treasury The new address of the DAO Treasury.
     */
    function changeDaoTreasury(address treasury) external;

    /**
     * @notice Sets the new owner address for this contract.
     * @dev Only the factory owner can call this function.
     * @param newOwner The new owner address for this contract.
     */
    function prepareChangeOwner(address newOwner) external;

    /**
     * @notice Changes the owner of this contract to the address set by `prepareChangeOwner`.
     * @dev Only the future owner can call this function.
     */
    function executeChangeOwner() external;

    /**
     * @notice Returns the host address of the given market.
     * @param market The address of the target market.
     * @return The host address of the market.
     */
    function getMarketHost(address market) external view returns (address);

    /**
     * @notice Prepares to set a new host address for the given market address.
     * @dev Only the market host can call this function.
     * @param market The market address for which the host will be changed.
     * @param newHost The new host address for the given market.
     */
    function prepareHandOverHost(address market, address newHost) external;

    /**
     * @notice Changes the host address of the given market to the address set by `prepareHandOverHost`.
     * @dev Only the future market host can call this function.
     * @param market The market address for which the host will be changed.
     */
    function executeHandOverHost(address market) external;

    enum MarketType {
        NONE,
        VOLATILE,
        STABLE
    }

    /**
     * @notice MarketInfo struct that contains information about a market.
     * @param host The address of the market host.
     * @param marketType The market type, either VOLATILE or STABLE.
     * @param a The starting price point.
     * @param factor The either the common ratio or common difference between price points.
     * @param futureHost The address set by `prepareHandOverHost` to change the market host.
     */
    struct MarketInfo {
        address host;
        MarketType marketType;
        uint128 a;
        uint128 factor;
        address futureHost;
    }

    /**
     * @notice Returns key information about the market.
     * @param market The address of the market.
     * @return marketInfo The MarketInfo structure of the given market.
     */
    function getMarketInfo(address market) external view returns (MarketInfo memory marketInfo);

    /**
     * @notice Allows the specified token to be used as the quote token.
     * @dev Only the factory owner can call this function.
     * @param token The address of the token to register.
     */
    function registerQuoteToken(address token) external;

    /**
     * @notice Revokes the token's right to be used as a quote token.
     * @dev Only the factory owner can call this function.
     * @param token The address of the token to unregister.
     */
    function unregisterQuoteToken(address token) external;

    /**
     * @notice Returns the order token name.
     * @param quoteToken The address of the market's quote token.
     * @param baseToken The address of the market's base token.
     * @param marketNonce The market nonce.
     * @return The order token name.
     */
    function formatOrderTokenName(address quoteToken, address baseToken, uint256 marketNonce)
        external
        view
        returns (string memory);

    /**
     * @notice Returns the order token symbol.
     * @param quoteToken The address of a new market's quote token.
     * @param baseToken The address of a new market's base token.
     * @param marketNonce The market nonce.
     * @return The order token symbol.
     */
    function formatOrderTokenSymbol(address quoteToken, address baseToken, uint256 marketNonce)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberMarketSwapCallbackReceiver {
    /**
     * @notice Contracts placing orders on the OrderBook must implement this method.
     * In this method, the contract has to send the required token, or the transaction will revert.
     * If there is a claim bounty to be refunded, it will be transferred via msg.value.
     * @param inputToken The address of the token the user has to send.
     * @param outputToken The address of the token the user has received.
     * @param inputAmount The amount of tokens the user has to send.
     * @param outputAmount The amount of tokens the user has received.
     * @param data The user's custom callback data.
     */
    function cloberMarketSwapCallback(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        bytes calldata data
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./CloberOrderKey.sol";

interface CloberOrderBook {
    /**
     * @notice Emitted when an order is created.
     * @param sender The address who sent the tokens to make the order.
     * @param user The address with the rights to claim the proceeds of the order.
     * @param rawAmount The ordered raw amount.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param options LSB: 0 - Ask, 1 - Bid.
     */
    event MakeOrder(
        address indexed sender,
        address indexed user,
        uint64 rawAmount,
        uint32 claimBounty,
        uint256 orderIndex,
        uint16 priceIndex,
        uint8 options
    );

    /**
     * @notice Emitted when an order takes from the order book.
     * @param sender The address who sent the tokens to take the order.
     * @param user The recipient address of the traded token.
     * @param priceIndex The price book index.
     * @param rawAmount The ordered raw amount.
     * @param options MSB: 0 - Limit, 1 - Market / LSB: 0 - Ask, 1 - Bid.
     */
    event TakeOrder(address indexed sender, address indexed user, uint16 priceIndex, uint64 rawAmount, uint8 options);

    /**
     * @notice Emitted when an order is canceled.
     * @param user The owner of the order.
     * @param rawAmount The raw amount remaining that was canceled.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param isBid The flag indicating whether it's a bid order or an ask order.
     */
    event CancelOrder(address indexed user, uint64 rawAmount, uint256 orderIndex, uint16 priceIndex, bool isBid);

    /**
     * @notice Emitted when the proceeds of an order is claimed.
     * @param claimer The address that initiated the claim.
     * @param user The owner of the order.
     * @param rawAmount The ordered raw amount.
     * @param bountyAmount The size of the claim bounty.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param isBase The flag indicating whether the user receives the base token or the quote token.
     */
    event ClaimOrder(
        address indexed claimer,
        address indexed user,
        uint64 rawAmount,
        uint256 bountyAmount,
        uint256 orderIndex,
        uint16 priceIndex,
        bool isBase
    );

    /**
     * @notice Emitted when a flash-loan is taken.
     * @param caller The caller address of the flash-loan.
     * @param borrower The address of the flash loan token receiver.
     * @param quoteAmount The amount of quote tokens the user has borrowed.
     * @param baseAmount The amount of base tokens the user has borrowed.
     * @param earnedQuote The amount of quote tokens the protocol earned in quote tokens.
     * @param earnedBase The amount of base tokens the protocol earned in base tokens.
     */
    event Flash(
        address indexed caller,
        address indexed borrower,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 earnedQuote,
        uint256 earnedBase
    );

    /**
     * @notice A struct that represents an order.
     * @param amount The raw amount not filled yet. In case of a stale order, the amount not claimed yet.
     * @param claimBounty The bounty amount in gwei that can be collected by the party that fully claims the order.
     * @param owner The address of the order owner.
     */
    struct Order {
        uint64 amount;
        uint32 claimBounty;
        address owner;
    }

    /**
     * @notice A struct that represents a block trade log.
     * @param blockTime The timestamp of the block.
     * @param askVolume The volume taken on the ask side.
     * @param bidVolume The volume taken on the bid side.
     * @param open The price book index on the open.
     * @param high The highest price book index in the block.
     * @param low The lowest price book index in the block.
     * @param close The price book index on the close.
     */
    struct BlockTradeLog {
        uint64 blockTime;
        uint64 askVolume;
        uint64 bidVolume;
        uint16 open;
        uint16 high;
        uint16 low;
        uint16 close;
    }

    /**
     * @notice Take orders better or equal to the given priceIndex and make an order with the remaining tokens.
     * @dev `msg.value` will be used as the claimBounty.
     * @param user The taker/maker address.
     * @param priceIndex The price book index.
     * @param rawAmount The raw quote amount to trade, utilized by bids.
     * @param baseAmount The base token amount to trade, utilized by asks.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - Post only.
     * @param data Custom callback data
     * @return The order index. If an order is not made `type(uint256).max` is returned instead.
     */
    function limitOrder(
        address user,
        uint16 priceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @notice Returns the expected input amount and output amount.
     * @param limitPriceIndex The price index to take until.
     * @param rawAmount The raw amount to trade.
     * Bid & expendInput => Used as input amount.
     * Bid & !expendInput => Not used.
     * Ask & expendInput => Not used.
     * Ask & !expendInput => Used as output amount.
     * @param baseAmount The base token amount to trade.
     * Bid & expendInput => Not used.
     * Bid & !expendInput => Used as output amount.
     * Ask & expendInput => Used as input amount.
     * Ask & !expendInput => Not used.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - expend input.
     */
    function getExpectedAmount(uint16 limitPriceIndex, uint64 rawAmount, uint256 baseAmount, uint8 options)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Take opens orders until certain conditions are met.
     * @param user The taker address.
     * @param limitPriceIndex The price index to take until.
     * @param rawAmount The raw amount to trade.
     * This value is used as the maximum input amount by bids and minimum output amount by asks.
     * @param baseAmount The base token amount to trade.
     * This value is used as the maximum input amount by asks and minimum output amount by bids.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - expend input.
     * @param data Custom callback data.
     */
    function marketOrder(
        address user,
        uint16 limitPriceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external;

    /**
     * @notice Cancel orders.
     * @dev The length of orderKeys must be controlled by the caller to avoid block gas limit exceeds.
     * @param receiver The address to receive canceled tokens.
     * @param orderKeys The order keys of the orders to cancel.
     */
    function cancel(address receiver, OrderKey[] calldata orderKeys) external;

    /**
     * @notice Claim the proceeds of orders.
     * @dev The length of orderKeys must be controlled by the caller to avoid block gas limit exceeds.
     * @param claimer The address to receive the claim bounties.
     * @param orderKeys The order keys of the orders to claim.
     */
    function claim(address claimer, OrderKey[] calldata orderKeys) external;

    /**
     * @notice Get the claimable proceeds of an order.
     * @param orderKey The order key of the order.
     * @return claimableRawAmount The claimable raw amount.
     * @return claimableAmount The claimable amount after fees.
     * @return feeAmount The maker fee to be paid on claim.
     * @return rebateAmount The rebate to be received on claim.
     */
    function getClaimable(OrderKey calldata orderKey)
        external
        view
        returns (uint64 claimableRawAmount, uint256 claimableAmount, uint256 feeAmount, uint256 rebateAmount);

    /**
     * @notice Flash loan the tokens in the OrderBook.
     * @param borrower The address to receive the loan.
     * @param quoteAmount The quote token amount to borrow.
     * @param baseAmount The base token amount to borrow.
     * @param data The user's custom callback data.
     */
    function flash(address borrower, uint256 quoteAmount, uint256 baseAmount, bytes calldata data) external;

    /**
     * @notice Returns the quote unit amount.
     * @return The amount that one raw amount represent in quote tokens.
     */
    function quoteUnit() external view returns (uint256);

    /**
     * @notice Returns the maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @return The maker fee. 100 = 1bp.
     */
    function makerFee() external view returns (int24);

    /**
     * @notice Returns the take fee
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @return The taker fee. 100 = 1bps.
     */
    function takerFee() external view returns (uint24);

    /**
     * @notice Returns the address of the order NFT contract.
     * @return The address of the order NFT contract.
     */
    function orderToken() external view returns (address);

    /**
     * @notice Returns the address of the quote token.
     * @return The address of the quote token.
     */
    function quoteToken() external view returns (address);

    /**
     * @notice Returns the address of the base token.
     * @return The address of the base token.
     */
    function baseToken() external view returns (address);

    /**
     * @notice Returns the current total open amount at the given price.
     * @param isBid The flag to choose which side to check the depth for.
     * @param priceIndex The price book index.
     * @return The total open amount.
     */
    function getDepth(bool isBid, uint16 priceIndex) external view returns (uint64);

    /**
     * @notice Returns the fee balance that has not been collected yet.
     * @return quote The current fee balance for the quote token.
     * @return base The current fee balance for the base token.
     */
    function getFeeBalance() external view returns (uint128 quote, uint128 base);

    /**
     * @notice Returns the amount of tokens that can be collected by the host.
     * @param token The address of the token to be collected.
     * @return The amount of tokens that can be collected by the host.
     */
    function uncollectedHostFees(address token) external view returns (uint256);

    /**
     * @notice Returns the amount of tokens that can be collected by the dao treasury.
     * @param token The address of the token to be collected.
     * @return The amount of tokens that can be collected by the dao treasury.
     */
    function uncollectedProtocolFees(address token) external view returns (uint256);

    /**
     * @notice Returns whether the order book is empty or not.
     * @param isBid The flag to choose which side to check the emptiness of.
     * @return Whether the order book is empty or not on that side.
     */
    function isEmpty(bool isBid) external view returns (bool);

    /**
     * @notice Returns the order information.
     * @param orderKey The order key of the order.
     * @return The order struct of the given order key.
     */
    function getOrder(OrderKey calldata orderKey) external view returns (Order memory);

    /**
     * @notice Returns the lowest ask price index or the highest bid price index.
     * @param isBid Returns the lowest ask price if false, highest bid price if true.
     * @return The current price index. If the order book is empty, it will revert.
     */
    function bestPriceIndex(bool isBid) external view returns (uint16);

    /**
     * @notice Returns the current block trade log index.
     * @return The current block trade log index.
     */
    function blockTradeLogIndex() external view returns (uint16);

    /**
     * @notice Returns the block trade log for a certain index.
     * @param index The block trade log index used to query the block trade log.
     * @return The queried block trade log.
     */
    function blockTradeLogs(uint16 index) external view returns (BlockTradeLog memory);

    /**
     * @notice Converts a raw amount to its corresponding base amount using a given price index.
     * @param rawAmount The raw amount to be converted.
     * @param priceIndex The index of the price to be used for the conversion.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted base amount.
     */
    function rawToBase(uint64 rawAmount, uint16 priceIndex, bool roundingUp) external view returns (uint256);

    /**
     * @notice Converts a raw amount to its corresponding quote amount.
     * @param rawAmount The raw amount to be converted.
     * @return The converted quote amount.
     */
    function rawToQuote(uint64 rawAmount) external view returns (uint256);

    /**
     * @notice Converts a base amount to its corresponding raw amount using a given price index.
     * @param baseAmount The base amount to be converted.
     * @param priceIndex The index of the price to be used for the conversion.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted raw amount.
     */
    function baseToRaw(uint256 baseAmount, uint16 priceIndex, bool roundingUp) external view returns (uint64);

    /**
     * @notice Converts a quote amount to its corresponding raw amount.
     * @param quoteAmount The quote amount to be converted.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted raw amount.
     */
    function quoteToRaw(uint256 quoteAmount, bool roundingUp) external view returns (uint64);

    /**
     * @notice Collects fees for either the protocol or host.
     * @param token The token address to collect. It should be the quote token or the base token.
     * @param destination The destination address to transfer fees.
     * It should be the dao treasury address or the host address.
     */
    function collectFees(address token, address destination) external;

    /**
     * @notice Change the owner of the order.
     * @dev Only the OrderToken contract can call this function.
     * @param orderKey The order key of the order.
     * @param newOwner The new owner address.
     */
    function changeOrderOwner(OrderKey calldata orderKey, address newOwner) external;

    /**
     * @notice Converts the price index into the actual price.
     * @param priceIndex The price book index.
     * @return price The actual price.
     */
    function indexToPrice(uint16 priceIndex) external view returns (uint256);

    /**
     * @notice Returns the price book index closest to the provided price.
     * @param price Provided price.
     * @param roundingUp Determines whether to round up or down.
     * @return index The price book index.
     * @return correctedPrice The actual price for the price book index.
     */
    function priceToIndex(uint256 price, bool roundingUp)
        external
        view
        returns (uint16 index, uint256 correctedPrice);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

/**
 * @notice A struct that represents a unique key for an order.
 * @param isBid The flag indicating whether it's a bid order or an ask order.
 * @param priceIndex The price book index.
 * @param orderIndex The order index.
 */
struct OrderKey {
    bool isBid;
    uint16 priceIndex;
    uint256 orderIndex;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IWETH9 is IERC20Metadata {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

// @author Gnosis (https://github.com/gnosis/1155-to-20)
interface IWrapped1155Factory is IERC1155Receiver {
    function erc20Implementation() external view returns (address);

    function unwrap(address multiToken, uint256 tokenId, uint256 amount, address recipient, bytes calldata data)
        external;

    function batchUnwrap(
        address multiToken,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address recipient,
        bytes calldata data
    ) external;

    function getWrapped1155DeployBytecode(address multiToken, uint256 tokenId, bytes calldata data)
        external
        view
        returns (bytes memory);

    function getWrapped1155(address multiToken, uint256 tokenId, bytes calldata data) external view returns (address);

    function requireWrapped1155(address multiToken, uint256 tokenId, bytes calldata data) external returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IController} from "./IController.sol";

interface IBorrowController is IController {
    error CollateralSwapFailed(string reason);
    error InvalidDebtAmount();

    function borrow(
        address collateralToken,
        address debtToken,
        uint256 collateralAmount,
        uint256 borrowAmount,
        uint256 maxPayInterest,
        uint16 loanEpochs,
        ERC20PermitParams calldata collateralPermitParams
    ) external payable;

    function borrowMore(
        uint256 positionId,
        uint256 amount,
        uint256 maxPayInterest,
        PermitSignature calldata positionPermitParams
    ) external;

    function addCollateral(
        uint256 positionId,
        uint256 amount,
        PermitSignature calldata positionPermitParams,
        ERC20PermitParams calldata collateralPermitParams
    ) external payable;

    function removeCollateral(uint256 positionId, uint256 amount, PermitSignature calldata positionPermitParams)
        external;

    function extendLoanDuration(
        uint256 positionId,
        uint16 epochs,
        uint256 maxPayInterest,
        PermitSignature calldata positionPermitParams,
        ERC20PermitParams calldata debtPermitParams
    ) external payable;

    function shortenLoanDuration(
        uint256 positionId,
        uint16 epochs,
        uint256 minEarnInterest,
        PermitSignature calldata positionPermitParams
    ) external;

    function repay(
        uint256 positionId,
        uint256 amount,
        uint256 minEarnInterest,
        PermitSignature calldata positionPermitParams,
        ERC20PermitParams calldata debtPermitParams
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {Epoch} from "../libraries/Epoch.sol";

interface IController {
    struct ERC20PermitParams {
        uint256 permitAmount;
        PermitSignature signature;
    }

    struct PermitSignature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event SetCouponMarket(address indexed asset, Epoch indexed epoch, address indexed cloberMarket);

    error InvalidAccess();
    error InvalidMarket();
    error ControllerSlippage();
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

import {CouponKey} from "../libraries/CouponKey.sol";
import {Coupon} from "../libraries/Coupon.sol";
import {Epoch} from "../libraries/Epoch.sol";

interface ICouponManager is IERC1155MetadataURI {
    error InvalidAccess();

    // View Functions //
    function isMinter(address account) external view returns (bool);

    function currentEpoch() external view returns (Epoch);

    function epochEndTime(Epoch epoch) external pure returns (uint256);

    function baseURI() external view returns (string memory);

    function contractURI() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function exists(uint256 id) external view returns (bool);

    // User Functions
    function safeBatchTransferFrom(address from, address to, Coupon[] calldata coupons, bytes calldata data) external;

    function burnExpiredCoupons(CouponKey[] calldata couponKeys) external;

    // Admin Functions //
    function mintBatch(address to, Coupon[] calldata coupons, bytes memory data) external;

    function burnBatch(address user, Coupon[] calldata coupons) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Permit is IERC721 {
    error InvalidSignature();
    error PermitExpired();

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function permit(address spender, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function nonces(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IPositionManagerTypes, IPositionManager} from "./IPositionManager.sol";
import {CouponKey} from "../libraries/CouponKey.sol";
import {Coupon} from "../libraries/Coupon.sol";
import {Epoch} from "../libraries/Epoch.sol";
import {LoanPosition} from "../libraries/LoanPosition.sol";

interface ILoanPositionManagerTypes is IPositionManagerTypes {
    // liquidationFee = liquidator fee + protocol fee
    // debt = collateral * (1 - liquidationFee)
    struct LoanConfiguration {
        uint32 collateralDecimal;
        uint32 debtDecimal;
        uint32 liquidationThreshold;
        uint32 liquidationFee;
        uint32 liquidationProtocolFee;
        uint32 liquidationTargetLtv;
    }

    event SetLoanConfiguration(
        address indexed collateral,
        address indexed debt,
        uint32 liquidationThreshold,
        uint32 liquidationFee,
        uint32 liquidationProtocolFee,
        uint32 liquidationTargetLtv,
        address hook
    );
    event UpdatePosition(uint256 indexed positionId, uint256 collateralAmount, uint256 debtAmount, Epoch unlockedAt);
    event LiquidatePosition(
        uint256 indexed positionId,
        address indexed liquidator,
        uint256 liquidationAmount,
        uint256 repayAmount,
        uint256 protocolFeeAmount
    );
    event SetTreasury(address indexed newTreasury);

    error TooSmallDebtLeft();
    error InvalidAccess();
    error FullRepaymentRequired();
    error LiquidationThreshold();
    error InvalidPair();
    error InvalidConfiguration();
    error UnableToLiquidate();
}

interface ILoanPositionManager is ILoanPositionManagerTypes, IPositionManager {
    function treasury() external view returns (address);

    function oracle() external view returns (address);

    function minDebtValueInEth() external view returns (uint256);

    function getPosition(uint256 positionId) external view returns (LoanPosition memory);

    function isPairRegistered(address collateral, address debt) external view returns (bool);

    function getLoanConfiguration(address collateral, address debt) external view returns (LoanConfiguration memory);

    function getOwedCouponAmount(address user, uint256 couponId) external view returns (uint256);

    function getLiquidationStatus(uint256 positionId, uint256 maxRepayAmount)
        external
        view
        returns (uint256 liquidationAmount, uint256 repayAmount, uint256 protocolFeeAmount);

    function mint(address collateralToken, address debtToken) external returns (uint256 positionId);

    function adjustPosition(uint256 positionId, uint256 collateralAmount, uint256 debtAmount, Epoch expiredWith)
        external
        returns (Coupon[] memory couponsToMint, Coupon[] memory couponsToBurn, int256 collateralDelta, int256 debtDelta);

    function liquidate(uint256 positionId, uint256 maxRepayAmount)
        external
        returns (uint256 liquidationAmount, uint256 repayAmount, uint256 protocolFeeAmount);

    function claimOwedCoupons(CouponKey[] memory couponKeys, bytes calldata data) external;

    function setLoanConfiguration(
        address collateral,
        address debt,
        uint32 liquidationThreshold,
        uint32 liquidationFee,
        uint32 liquidationProtocolFee,
        uint32 liquidationTargetLtv,
        address hook
    ) external;

    function setTreasury(address newTreasury) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IPositionLocker {
    function positionLockAcquired(bytes calldata data) external returns (bytes memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import {IERC721Permit} from "./IERC721Permit.sol";
import {Coupon} from "../libraries/Coupon.sol";

interface IPositionManagerTypes {
    error LockedBy(address locker);
    error NotSettled();
}

interface IPositionManager is IERC721Metadata, IERC721Permit, IPositionManagerTypes {
    function baseURI() external view returns (string memory);

    function contractURI() external view returns (string memory);

    function nextId() external view returns (uint256);

    function assetPool() external view returns (address);

    function lockData() external view returns (uint128, uint128);

    function assetDelta(address locker, uint256 assetId) external view returns (int256);

    function lock(bytes calldata data) external returns (bytes memory);

    function settlePosition(uint256 positionId) external;

    function withdrawToken(address token, address to, uint256 amount) external;

    function mintCoupons(Coupon[] calldata coupons, address to, bytes calldata data) external;

    function depositToken(address token, uint256 amount) external;

    function burnCoupons(Coupon[] calldata coupons) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface ISubstitute {
    event SetTreasury(address indexed newTreasury);
    event Claim(address indexed treasury, uint256 adminYield);

    error InvalidToken();
    error ValueTransferFailed();

    function treasury() external view returns (address);

    function underlyingToken() external view returns (address);

    function mint(uint256 amount, address to) external;

    function burn(uint256 amount, address to) external;

    function claim() external;

    function mintableAmount() external view returns (uint256);

    function burnableAmount() external view returns (uint256);

    function setTreasury(address newTreasury) external;

    function withdrawLostToken(address token, address recipient) external;
}

// SPDX-License-Identifier: -
// License: https://license.coupon.finance/LICENSE.pdf

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {CloberMarketSwapCallbackReceiver} from "../external/clober/CloberMarketSwapCallbackReceiver.sol";
import {CloberMarketFactory} from "../external/clober/CloberMarketFactory.sol";
import {IWETH9} from "../external/weth/IWETH9.sol";
import {IWrapped1155Factory} from "../external/wrapped1155/IWrapped1155Factory.sol";
import {CloberOrderBook} from "../external/clober/CloberOrderBook.sol";
import {ICouponManager} from "../interfaces/ICouponManager.sol";
import {Coupon, CouponLibrary} from "./Coupon.sol";
import {CouponKey, CouponKeyLibrary} from "./CouponKey.sol";
import {Wrapped1155MetadataBuilder} from "./Wrapped1155MetadataBuilder.sol";
import {IERC721Permit} from "../interfaces/IERC721Permit.sol";
import {ISubstitute} from "../interfaces/ISubstitute.sol";
import {IController} from "../interfaces/IController.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";

abstract contract Controller is
    IController,
    ERC1155Holder,
    CloberMarketSwapCallbackReceiver,
    Ownable2Step,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using CouponKeyLibrary for CouponKey;
    using CouponLibrary for Coupon;

    IWrapped1155Factory internal immutable _wrapped1155Factory;
    CloberMarketFactory internal immutable _cloberMarketFactory;
    ICouponManager internal immutable _couponManager;
    IWETH9 internal immutable _weth;

    mapping(uint256 couponId => address market) internal _couponMarkets;

    constructor(address wrapped1155Factory, address cloberMarketFactory, address couponManager, address weth) {
        _wrapped1155Factory = IWrapped1155Factory(wrapped1155Factory);
        _cloberMarketFactory = CloberMarketFactory(cloberMarketFactory);
        _couponManager = ICouponManager(couponManager);
        _weth = IWETH9(weth);
    }

    modifier wrapETH() {
        if (address(this).balance > 0) _weth.deposit{value: address(this).balance}();
        _;
    }

    function _executeCouponTrade(
        address user,
        address token,
        Coupon[] memory couponsToMint,
        Coupon[] memory couponsToBurn,
        uint256 amountToPay,
        uint256 maxPayInterest,
        uint256 leftRequiredInterest
    ) internal {
        if (couponsToBurn.length > 0) {
            Coupon memory lastCoupon = couponsToBurn[couponsToBurn.length - 1];
            assembly {
                mstore(couponsToBurn, sub(mload(couponsToBurn), 1))
            }
            bytes memory data = abi.encode(
                user, lastCoupon, couponsToMint, couponsToBurn, amountToPay, maxPayInterest, leftRequiredInterest
            );
            assembly {
                mstore(couponsToBurn, add(mload(couponsToBurn), 1))
            }

            CloberOrderBook market = CloberOrderBook(_couponMarkets[lastCoupon.id()]);
            uint256 dy = lastCoupon.amount - IERC20(market.baseToken()).balanceOf(address(this));
            market.marketOrder(address(this), type(uint16).max, type(uint64).max, dy, 1, data);
        } else if (couponsToMint.length > 0) {
            Coupon memory lastCoupon = couponsToMint[couponsToMint.length - 1];
            assembly {
                mstore(couponsToMint, sub(mload(couponsToMint), 1))
            }
            bytes memory data = abi.encode(
                user, lastCoupon, couponsToMint, couponsToBurn, amountToPay, maxPayInterest, leftRequiredInterest
            );
            assembly {
                mstore(couponsToMint, add(mload(couponsToMint), 1))
            }

            CloberOrderBook market = CloberOrderBook(_couponMarkets[lastCoupon.id()]);
            market.marketOrder(address(this), 0, 0, lastCoupon.amount, 2, data);
        } else {
            if (leftRequiredInterest > 0) revert ControllerSlippage();
            _ensureBalance(token, user, amountToPay);
        }
    }

    function cloberMarketSwapCallback(
        address inputToken,
        address,
        uint256 inputAmount,
        uint256 outputAmount,
        bytes calldata data
    ) external payable {
        // check if caller is registered market
        if (_cloberMarketFactory.getMarketHost(msg.sender) == address(0)) revert InvalidAccess();

        address asset = CloberOrderBook(msg.sender).quoteToken();
        address user;
        Coupon memory lastCoupon;
        unchecked {
            Coupon[] memory couponsToMint;
            Coupon[] memory couponsToBurn;
            uint256 amountToPay;
            uint256 maxPayInterest;
            uint256 leftRequiredInterest;
            (user, lastCoupon, couponsToMint, couponsToBurn, amountToPay, maxPayInterest, leftRequiredInterest) =
                abi.decode(data, (address, Coupon, Coupon[], Coupon[], uint256, uint256, uint256));

            if (asset == inputToken) {
                if (maxPayInterest < inputAmount) revert ControllerSlippage();
                maxPayInterest -= inputAmount;
                amountToPay += inputAmount;
            } else {
                if (leftRequiredInterest > outputAmount) {
                    leftRequiredInterest -= outputAmount;
                } else {
                    leftRequiredInterest = 0;
                }
            }

            _executeCouponTrade(
                user, asset, couponsToMint, couponsToBurn, amountToPay, maxPayInterest, leftRequiredInterest
            );
        }

        // transfer input tokens
        if (inputAmount > 0) IERC20(inputToken).safeTransfer(msg.sender, inputAmount);
        uint256 couponBalance = IERC20(inputToken).balanceOf(address(this));
        if (asset != inputToken && couponBalance > 0) {
            bytes memory metadata = Wrapped1155MetadataBuilder.buildWrapped1155Metadata(lastCoupon.key);
            _wrapped1155Factory.unwrap(address(_couponManager), lastCoupon.id(), couponBalance, user, metadata);
        }
    }

    function _permitERC20(address token, ERC20PermitParams calldata p) internal {
        if (p.signature.deadline > 0) {
            try IERC20Permit(ISubstitute(token).underlyingToken()).permit(
                msg.sender,
                address(this),
                p.permitAmount,
                p.signature.deadline,
                p.signature.v,
                p.signature.r,
                p.signature.s
            ) {} catch {}
        }
    }

    function _permitERC721(IERC721Permit permitNFT, uint256 positionId, PermitSignature calldata p) internal {
        if (p.deadline > 0) try permitNFT.permit(address(this), positionId, p.deadline, p.v, p.r, p.s) {} catch {}
    }

    function _burnAllSubstitute(address substitute, address to) internal {
        uint256 leftAmount = IERC20(substitute).balanceOf(address(this));
        if (leftAmount == 0) return;
        ISubstitute(substitute).burn(leftAmount, to);
    }

    function _ensureBalance(address token, address user, uint256 amount) internal {
        address underlyingToken = ISubstitute(token).underlyingToken();
        uint256 thisBalance = IERC20(token).balanceOf(address(this));
        uint256 underlyingBalance = IERC20(underlyingToken).balanceOf(address(this));
        if (amount > thisBalance + underlyingBalance) {
            unchecked {
                IERC20(underlyingToken).safeTransferFrom(user, address(this), amount - thisBalance - underlyingBalance);
                underlyingBalance = amount - thisBalance;
            }
        }
        if (underlyingBalance > 0) {
            IERC20(underlyingToken).approve(token, underlyingBalance);
            ISubstitute(token).mint(underlyingBalance, address(this));
        }
    }

    function _wrapCoupons(Coupon[] memory coupons) internal {
        // wrap 1155 to 20
        bytes memory metadata = Wrapped1155MetadataBuilder.buildWrapped1155BatchMetadata(coupons);
        _couponManager.safeBatchTransferFrom(address(this), address(_wrapped1155Factory), coupons, metadata);
    }

    function _unwrapCoupons(Coupon[] memory coupons) internal {
        uint256[] memory tokenIds = new uint256[](coupons.length);
        uint256[] memory amounts = new uint256[](coupons.length);
        unchecked {
            for (uint256 i = 0; i < coupons.length; ++i) {
                tokenIds[i] = coupons[i].id();
                amounts[i] = coupons[i].amount;
            }
        }
        bytes memory metadata = Wrapped1155MetadataBuilder.buildWrapped1155BatchMetadata(coupons);
        _wrapped1155Factory.batchUnwrap(address(_couponManager), tokenIds, amounts, address(this), metadata);
    }

    function getCouponMarket(CouponKey memory couponKey) external view returns (address) {
        return _couponMarkets[couponKey.toId()];
    }

    function setCouponMarket(CouponKey memory couponKey, address cloberMarket) public virtual onlyOwner {
        bytes memory metadata = Wrapped1155MetadataBuilder.buildWrapped1155Metadata(couponKey);
        uint256 id = couponKey.toId();
        address wrappedCoupon = _wrapped1155Factory.getWrapped1155(address(_couponManager), id, metadata);
        CloberMarketFactory.MarketInfo memory marketInfo = _cloberMarketFactory.getMarketInfo(cloberMarket);
        if (
            (marketInfo.host == address(0)) || (CloberOrderBook(cloberMarket).baseToken() != wrappedCoupon)
                || (CloberOrderBook(cloberMarket).quoteToken() != couponKey.asset)
        ) {
            revert InvalidMarket();
        }

        _couponMarkets[id] = cloberMarket;
        emit SetCouponMarket(couponKey.asset, couponKey.epoch, cloberMarket);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {Epoch} from "../libraries/Epoch.sol";
import {CouponKey, CouponKeyLibrary} from "./CouponKey.sol";

struct Coupon {
    CouponKey key;
    uint256 amount;
}

library CouponLibrary {
    using CouponKeyLibrary for CouponKey;

    function from(address asset, Epoch epoch, uint256 amount) internal pure returns (Coupon memory) {
        return Coupon({key: CouponKey({asset: asset, epoch: epoch}), amount: amount});
    }

    function from(CouponKey memory couponKey, uint256 amount) internal pure returns (Coupon memory) {
        return Coupon({key: couponKey, amount: amount});
    }

    function id(Coupon memory coupon) internal pure returns (uint256) {
        return coupon.key.toId();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {Epoch} from "./Epoch.sol";

struct CouponKey {
    address asset;
    Epoch epoch;
}

library CouponKeyLibrary {
    function toId(CouponKey memory key) internal pure returns (uint256 id) {
        uint16 epoch = Epoch.unwrap(key.epoch);
        address asset = key.asset;
        assembly {
            id := add(asset, shl(160, epoch))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.19;

type Epoch is uint16;

using {gt as >, gte as >=, lt as <, lte as <=, eq as ==, ne as !=} for Epoch global;

function gt(Epoch a, Epoch b) pure returns (bool) {
    return Epoch.unwrap(a) > Epoch.unwrap(b);
}

function gte(Epoch a, Epoch b) pure returns (bool) {
    return Epoch.unwrap(a) >= Epoch.unwrap(b);
}

function lt(Epoch a, Epoch b) pure returns (bool) {
    return Epoch.unwrap(a) < Epoch.unwrap(b);
}

function lte(Epoch a, Epoch b) pure returns (bool) {
    return Epoch.unwrap(a) <= Epoch.unwrap(b);
}

function eq(Epoch a, Epoch b) pure returns (bool) {
    return Epoch.unwrap(a) == Epoch.unwrap(b);
}

function ne(Epoch a, Epoch b) pure returns (bool) {
    return Epoch.unwrap(a) != Epoch.unwrap(b);
}

library EpochLibrary {
    using EpochLibrary for Epoch;

    error EpochOverflow();

    uint256 internal constant MONTHS_PER_EPOCH = 1;
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    int256 constant OFFSET19700101 = 2440588;

    function startTime(Epoch epoch) internal pure returns (uint256) {
        uint16 currentEpoch = Epoch.unwrap(epoch);
        if (currentEpoch == 0) return 0;
        unchecked {
            return _epochToTimestamp(currentEpoch - 1) + 1;
        }
    }

    function endTime(Epoch epoch) internal pure returns (uint256) {
        return _epochToTimestamp(Epoch.unwrap(epoch));
    }

    function lastExpiredEpoch() internal view returns (Epoch) {
        return current().sub(1);
    }

    function current() internal view returns (Epoch) {
        return Epoch.wrap(_timestampToEpoch(block.timestamp));
    }

    function add(Epoch epoch, uint16 epochs) internal pure returns (Epoch) {
        return Epoch.wrap(Epoch.unwrap(epoch) + epochs);
    }

    function sub(Epoch epoch, uint16 epochs) internal pure returns (Epoch) {
        return Epoch.wrap(Epoch.unwrap(epoch) - epochs);
    }

    function sub(Epoch e1, Epoch e2) internal pure returns (uint16) {
        return Epoch.unwrap(e1) - Epoch.unwrap(e2);
    }

    function max(Epoch a, Epoch b) internal pure returns (Epoch) {
        return a > b ? a : b;
    }

    // Inspired by https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _timestampToEpoch(uint256 timestamp) private pure returns (uint16) {
        unchecked {
            uint256 _days = timestamp / SECONDS_PER_DAY;
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            uint256 epoch = uint256((_year - 1970) * 12 + _month - 1) / MONTHS_PER_EPOCH;
            if (epoch > type(uint16).max) revert EpochOverflow();
            return uint16(epoch);
        }
    }

    function _epochToTimestamp(uint16 epoch) internal pure returns (uint256) {
        unchecked {
            uint256 months = MONTHS_PER_EPOCH + MONTHS_PER_EPOCH * epoch;
            uint256 year = months / 12 + 1970;
            months = (months % 12) << 4;
            if (((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0)) {
                // 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366
                months = 0x016E014F0131011200F400D500B600980079005B003C001F0000 >> months;
            } else {
                // 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365
                months = 0x016D014E0130011100F300D400B500970078005A003B001F0000 >> months;
            }
            return (
                (months & 0xffff) + 365 * (year - 1970) + (year - 1969) / 4 - (year - 1901) / 100 + (year - 1601) / 400
            ) * SECONDS_PER_DAY - 1;
        }
    }
}

// SPDX-License-Identifier: -
// License: https://license.coupon.finance/LICENSE.pdf

pragma solidity ^0.8.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Epoch, EpochLibrary} from "./Epoch.sol";
import {Coupon, CouponLibrary} from "./Coupon.sol";

struct LoanPosition {
    uint64 nonce;
    Epoch expiredWith;
    bool isSettled;
    address collateralToken;
    address debtToken;
    uint256 collateralAmount;
    uint256 debtAmount;
}

library LoanPositionLibrary {
    error UnmatchedPosition();
    error InvalidPositionEpoch();

    using EpochLibrary for Epoch;

    function getAndIncrementNonce(LoanPosition storage positionStorage) internal returns (uint64 nonce) {
        nonce = positionStorage.nonce++;
    }

    function calculateCouponRequirement(LoanPosition memory oldPosition, LoanPosition memory newPosition)
        internal
        view
        returns (Coupon[] memory mintCoupons, Coupon[] memory burnCoupons)
    {
        if (
            !(
                oldPosition.collateralToken == newPosition.collateralToken
                    && oldPosition.debtToken == newPosition.debtToken && oldPosition.nonce == newPosition.nonce
            )
        ) revert UnmatchedPosition();

        Epoch latestExpiredEpoch = EpochLibrary.lastExpiredEpoch();
        if (latestExpiredEpoch > newPosition.expiredWith || latestExpiredEpoch > oldPosition.expiredWith) {
            revert InvalidPositionEpoch();
        }

        uint256 mintCouponsLength = oldPosition.expiredWith.sub(latestExpiredEpoch);
        uint256 burnCouponsLength = newPosition.expiredWith.sub(latestExpiredEpoch);
        unchecked {
            uint256 minCount = Math.min(mintCouponsLength, burnCouponsLength);
            if (newPosition.debtAmount > oldPosition.debtAmount) {
                mintCouponsLength -= minCount;
            } else if (newPosition.debtAmount < oldPosition.debtAmount) {
                burnCouponsLength -= minCount;
            } else {
                burnCouponsLength -= minCount;
                mintCouponsLength -= minCount;
            }
        }

        mintCoupons = new Coupon[](mintCouponsLength);
        burnCoupons = new Coupon[](burnCouponsLength);
        mintCouponsLength = 0;
        burnCouponsLength = 0;
        uint256 farthestExpiredEpochs = newPosition.expiredWith.max(oldPosition.expiredWith).sub(latestExpiredEpoch);
        unchecked {
            Epoch epoch = latestExpiredEpoch;
            for (uint256 i = 0; i < farthestExpiredEpochs; ++i) {
                epoch = epoch.add(1);
                uint256 newAmount = newPosition.expiredWith < epoch ? 0 : newPosition.debtAmount;
                uint256 oldAmount = oldPosition.expiredWith < epoch ? 0 : oldPosition.debtAmount;
                if (newAmount > oldAmount) {
                    burnCoupons[burnCouponsLength++] =
                        CouponLibrary.from(oldPosition.debtToken, epoch, newAmount - oldAmount);
                } else if (newAmount < oldAmount) {
                    mintCoupons[mintCouponsLength++] =
                        CouponLibrary.from(oldPosition.debtToken, epoch, oldAmount - newAmount);
                }
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Clober (https://github.com/clober-dex/coupon-finance/blob/main/contracts/libraries/ReentrancyGuard.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    error Reentrancy();

    uint256 internal _locked = 1;

    modifier nonReentrant() virtual {
        if (_locked != 1) revert Reentrancy();

        _locked = 2;

        _;

        _locked = 1;
    }
}

// SPDX-License-Identifier: -
// License: https://license.coupon.finance/LICENSE.pdf

pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {CouponKey} from "./CouponKey.sol";
import {Coupon} from "./Coupon.sol";
import {Epoch} from "./Epoch.sol";

library Wrapped1155MetadataBuilder {
    function buildWrapped1155Metadata(CouponKey memory couponKey) internal view returns (bytes memory) {
        string memory tokenSymbol = IERC20Metadata(couponKey.asset).symbol();
        string memory epochString = Strings.toString(Epoch.unwrap(couponKey.epoch));
        // @dev assume that tokenSymbol.length <= 12
        bytes32 nameData = bytes32(abi.encodePacked(tokenSymbol, " Bond Coupon (", epochString, ")"));
        bytes32 symbolData = bytes32(abi.encodePacked(tokenSymbol, "-CP", epochString));
        assembly {
            let addLength := mul(2, add(mload(tokenSymbol), mload(epochString)))
            nameData := add(nameData, add(30, addLength))
            symbolData := add(symbolData, add(6, addLength))
        }
        return abi.encodePacked(nameData, symbolData, bytes1(IERC20Metadata(couponKey.asset).decimals()));
    }

    function buildWrapped1155BatchMetadata(Coupon[] memory coupons) internal view returns (bytes memory data) {
        unchecked {
            for (uint256 i = 0; i < coupons.length; ++i) {
                data = bytes.concat(data, buildWrapped1155Metadata(coupons[i].key));
            }
        }
    }
}