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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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

pragma solidity ^0.8.17;

uint64 constant DAILY_EPOCH_DURATION = 1 days;
uint64 constant DAILY_EPOCH_OFFSET = 0 hours;

uint64 constant HOURLY_EPOCH_DURATION = 1 hours;
uint64 constant NO_OFFSET = 0 hours;

uint256 constant ACTION_LOCK = 101;

uint256 constant ACTION_ADVENTURER_HOMAGE = 1001;
uint256 constant ACTION_ADVENTURER_BATTLE_V3 = 1002;
uint256 constant ACTION_ADVENTURER_COLLECT_EPOCH_REWARDS = 1003;
uint256 constant ACTION_ADVENTURER_VOID_CRAFTING = 1004;
uint256 constant ACTION_ADVENTURER_REALM_CRAFTING = 1005;
uint256 constant ACTION_ADVENTURER_ANIMA_REGENERATION = 1006;

uint256 constant ACTION_ARMORY_STAKE_RARITY_ITEM = 2001;
uint256 constant ACTION_ARMORY_UNSTAKE_RARITY_ITEM = 2002;

uint256 constant ACTION_ARMORY_STAKE_RARITY_ITEM_SHARD = 2011;
uint256 constant ACTION_ARMORY_UNSTAKE_RARITY_ITEM_SHARD = 2012;

uint256 constant ACTION_ARMORY_STAKE_MATERIAL_SHARD = 2021;
uint256 constant ACTION_ARMORY_UNSTAKE_MATERIAL_SHARD = 2022;

uint256 constant ACTION_ARMORY_STAKE_LAB = 2031;
uint256 constant ACTION_ARMORY_UNSTAKE_LAB = 2032;

uint256 constant ACTION_ARMORY_STAKE_COLLECTIBLE = 2041;
uint256 constant ACTION_ARMORY_UNSTAKE_COLLECTIBLE = 2042;

uint256 constant ACTION_ARMORY_STAKE_MATERIAL = 2051;
uint256 constant ACTION_ARMORY_UNSTAKE_MATERIAL = 2052;

uint256 constant ACTION_REALM_COLLECT_COLLECTIBLES = 4001;
uint256 constant ACTION_REALM_BUILD_LAB = 4011;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error Unauthorized(address _tokenAddr, uint256 _tokenId);
error EntityLocked(address _tokenAddr, uint256 _tokenId, uint _lockedUntil);
error MinEpochsTooLow(uint256 _minEpochs);
error InsufficientEpochSpan(
  uint256 _minEpochs,
  uint256 _epochs,
  address _tokenAddr,
  uint256 _tokenId
);
error DuplicateActionAttempt(address _tokenAddr, uint256 _tokenId);

interface IActionPermit {
  // Reverts if no permissions or action was already taken in the last _minEpochs
  function checkAndMarkActionComplete(
    address _sender,
    address _tokenAddr,
    uint256 _tokenId,
    bytes32[] calldata _proof,
    uint256 _action,
    uint256 _minEpochs,
    uint128 _epochConfig
  ) external;

  function checkAndMarkActionCompleteMany(
    address _sender,
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    bytes32[][] calldata _proofs,
    uint256 _action,
    uint256 _minEpochs,
    uint128 _epochConfig
  ) external;

  // Marks action complete even if already completed
  function forceMarkActionComplete(address _tokenAddr, uint256 _tokenId, uint256 _action) external;

  // Reverts if no permissions
  function checkPermissions(
    address _sender,
    address _tokenAddr,
    uint256 _tokenId,
    bytes32[] calldata _proof,
    uint256 _action
  ) external view;

  function checkPermissionsMany(
    address _sender,
    address[] calldata _tokenAddr,
    uint256[] calldata _tokenId,
    bytes32[][] calldata _proofs,
    uint256 _action
  ) external view;

  function checkPermissionsMany(
    address _sender,
    address _tokenAddr,
    uint256[] calldata _tokenId,
    bytes32[][] calldata _proofs,
    uint256 _action
  ) external view;

  // Reverts if action already taken this epoch
  function checkIfEnoughEpochsElapsed(
    address _tokenAddr,
    uint256 _tokenId,
    uint256 _action,
    uint256 _minEpochs,
    uint128 _epochConfig
  ) external view;

  function checkIfEnoughEpochsElapsedBatch(
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    uint256 _action,
    uint256 _minEpochs,
    uint128 _epochConfig
  ) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../Item/Material.sol";
import "../Action/Actions.sol";
import "../Armory/BurnMintERC1155ArmoryAdapter.sol";

contract MaterialArmoryAdapter is BurnMintERC1155ArmoryAdapter {
  Material public immutable TOKEN;

  constructor(
    address _manager,
    address _actionPermit,
    address _material
  )
    BurnMintERC1155ArmoryAdapter(
      _manager,
      _actionPermit,
      _material,
      ACTION_ARMORY_STAKE_MATERIAL,
      ACTION_ARMORY_UNSTAKE_MATERIAL,
      false,
      address(0)
    )
  {
    TOKEN = Material(_material);
  }

  function _burnFrom(address _from, uint256 _id, uint256 _amount) internal override {
    TOKEN.safeTransferFrom(_from, address(this), _id, _amount, "");
    TOKEN.burn(_id, _amount);
  }

  function _burnBatchFrom(
    address _staker,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) internal override {
    TOKEN.safeBatchTransferFrom(_staker, address(this), _ids, _amounts, "");
    TOKEN.burnBatch(_ids, _amounts);
  }

  function _burnBatchFrom(
    address _staker,
    uint256[][] calldata _ids,
    uint256[][] calldata _amounts
  ) internal override {
    for (uint i = 0; i < _ids.length; i++) {
      TOKEN.safeBatchTransferFrom(_staker, address(this), _ids[i], _amounts[i], "");
      TOKEN.burnBatch(_ids[i], _amounts[i]);
    }
  }

  function _mintFor(address _for, uint256 _id, uint256 _amount) internal override {
    TOKEN.mintFor(_for, _id, _amount);
  }

  function _mintBatchFor(
    address _staker,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) internal override {
    TOKEN.mintBatchFor(_staker, _ids, _amounts);
  }

  function _mintBatchFor(
    address _staker,
    uint256[][] calldata _ids,
    uint256[][] calldata _amounts
  ) internal override {
    for (uint i = 0; i < _ids.length; i++) {
      TOKEN.mintBatchFor(_staker, _ids[i], _amounts[i]);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IBrokenTokenHandler {
  function handleBrokenToken(
    address _breakerContract,
    address _ownerAddress,
    uint _ownerTokenId,
    address _brokenEntityAddress,
    uint _brokenEntityTokenId,
    uint _brokenAmount
  ) external;

  function handleBrokenTokenBatch(
    address _breakerContract,
    address _ownerAddress,
    uint _ownerTokenId,
    address _brokenEntityAddress,
    uint[] calldata _brokenEntityTokenIds,
    uint[] calldata _brokenAmounts
  ) external;

  function handleBrokenTokenBatch(
    address _breakerContract,
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _brokenEntityAddress,
    uint[][] calldata _brokenEntityTokenIds,
    uint[][] calldata _brokenAmounts
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IDurabilityEnabledAdapter.sol";
import "../lib/FloatingPointConstants.sol";

abstract contract AbstractDurabilityEnabledArmoryAdapter is
  ManagerModifier,
  IDurabilityEnabledAdapter
{
  error DurabilityNotSupported();

  IBrokenTokenHandler public BREAK_HANDLER;
  bool public immutable SUPPORTS_DURABILITY;

  error TokenNotAvailable(
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId
  );

  error InsufficientDurability(
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId,
    uint durabilityLoss
  );

  struct DurabilityReductionRequest {
    address _ownerAddress;
    uint _ownerTokenId;
    address _entityAddress;
    uint _entityTokenId;
    uint _durabilityLoss;
    bool startNewTokenIfUndamaged;
    bool ignoreAvailability;
  }

  struct ProcessingMemory {
    DurabilityReductionRequest request;
    bool anyBroken;
    uint[] brokenAmounts;
    uint[][] nestedBrokenAmounts;
  }

  constructor(
    address _manager,
    address _breakHandler,
    bool _supportsDurability
  ) ManagerModifier(_manager) {
    BREAK_HANDLER = IBrokenTokenHandler(_breakHandler);
    SUPPORTS_DURABILITY = _supportsDurability;
  }

  event EntityDurabilityChanged(
    address adventurerAddress,
    uint adventurerTokenId,
    address entityAddress,
    uint entityTokenId,
    uint durability
  );

  event EntityBroken(
    address adventurerAddress,
    uint adventurerTokenId,
    address entityAddress,
    uint entityTokenId
  );

  // adventurer address -> adventurer token id -> item durability => item id -> durability
  mapping(address => mapping(uint => mapping(address => mapping(uint => uint32))))
    public currentDurabilityStorage;

  function _burnOnBreak(
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId
  ) internal virtual;

  function _isNextAvailable(
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId
  ) internal view virtual returns (bool);

  function _damagedEntityCount(
    mapping(uint => uint32) storage _durabilityMapping,
    uint _tokenId
  ) internal view returns (uint) {
    return _durabilityMapping[_tokenId] > 0 ? 1 : 0;
  }

  function _damagedEntityCount(
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId
  ) internal view returns (uint) {
    return
      currentDurabilityStorage[_ownerAddress][_ownerTokenId][_entityAddress][_entityTokenId] > 0
        ? 1
        : 0;
  }

  function _maximumTokenDurability(
    address _entityAddress,
    uint _entityTokenId
  ) internal virtual returns (uint32) {
    return uint32(ONE_HUNDRED);
  }

  function _maximumTokenDurabilityView(
    address _entityAddress,
    uint _entityTokenId
  ) internal view virtual returns (uint32) {
    return uint32(ONE_HUNDRED);
  }

  function _ownedEntityDurabilityMapping(
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress
  ) internal view returns (mapping(uint => uint32) storage) {
    return currentDurabilityStorage[_ownerAddress][_ownerTokenId][_entityAddress];
  }

  function _break(
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId
  ) internal {
    currentDurabilityStorage[_ownerAddress][_ownerTokenId][_entityAddress][_entityTokenId] = 0;
    _burnOnBreak(_ownerAddress, _ownerTokenId, _entityAddress, _entityTokenId);
    emit EntityBroken(_ownerAddress, _ownerTokenId, _entityAddress, _entityTokenId);
  }

  function currentDurabilityBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityId
  ) public view returns (uint[] memory result) {
    mapping(uint => uint32) storage durabilities = currentDurabilityStorage[_ownerAddress][
      _ownerId
    ][_entityAddress];
    result = new uint[](_entityId.length);
    for (uint i = 0; i < _entityId.length; i++) {
      result[i] = uint(durabilities[_entityId[i]]);
    }
  }

  function currentDurability(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) public view returns (uint) {
    return uint(currentDurabilityStorage[_ownerAddress][_ownerId][_entityAddress][_entityId]);
  }

  function currentDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityId
  ) external view returns (uint[][] memory result) {
    result = new uint[][](_ownerAddresses.length);
    for (uint i = 0; i < _ownerAddresses.length; i++) {
      result[i] = currentDurabilityBatch(
        _ownerAddresses[i],
        _ownerIds[i],
        _entityAddress,
        _entityId[i]
      );
    }
  }

  function currentDurabilityPercentage(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) public view returns (uint result) {
    result =
      (ONE_HUNDRED *
        uint(currentDurabilityStorage[_ownerAddress][_ownerId][_entityAddress][_entityId])) /
      _maximumTokenDurabilityView(_entityAddress, _entityId);
    if (result == 0 && _isNextAvailable(_ownerAddress, _ownerId, _entityAddress, _entityId)) {
      result = ONE_HUNDRED;
    }
  }

  function currentDurabilityBatchPercentage(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityIds
  ) public view returns (uint[] memory result) {
    mapping(uint => uint32) storage durabilities = currentDurabilityStorage[_ownerAddress][
      _ownerId
    ][_entityAddress];
    result = new uint[](_entityIds.length);
    for (uint i = 0; i < _entityIds.length; i++) {
      result[i] =
        (ONE_HUNDRED * uint(durabilities[_entityIds[i]])) /
        _maximumTokenDurabilityView(_entityAddress, _entityIds[i]);
      if (
        result[i] == 0 && _isNextAvailable(_ownerAddress, _ownerId, _entityAddress, _entityIds[i])
      ) {
        result[i] = ONE_HUNDRED;
      }
    }
  }

  function currentDurabilityBatchPercentage(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityId
  ) external view returns (uint[][] memory result) {
    result = new uint[][](_ownerAddresses.length);
    for (uint i = 0; i < _ownerAddresses.length; i++) {
      result[i] = currentDurabilityBatchPercentage(
        _ownerAddresses[i],
        _ownerIds[i],
        _entityAddress,
        _entityId[i]
      );
    }
  }

  function reduceDurability(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external onlyManager {
    if (!SUPPORTS_DURABILITY) {
      revert DurabilityNotSupported();
    }
    mapping(uint => uint32) storage _ownerEntityTokensDurability = currentDurabilityStorage[
      _ownerAddress
    ][_ownerTokenId][_entityAddress];
    if (
      _reduceDurabilityInternal(
        _ownerEntityTokensDurability,
        DurabilityReductionRequest(
          _ownerAddress,
          _ownerTokenId,
          _entityAddress,
          _entityTokenId,
          _durabilityLoss,
          _startNewTokenIfNeeded,
          _ignoreAvailability
        )
      ) && address(BREAK_HANDLER) != address(0)
    ) {
      BREAK_HANDLER.handleBrokenToken(
        _reducer,
        _ownerAddress,
        _ownerTokenId,
        _entityAddress,
        _entityTokenId,
        1
      );
    }
  }

  function reduceDurabilityBatch(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint[] calldata _entityTokenIds,
    uint[] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external onlyManager {
    if (!SUPPORTS_DURABILITY) {
      revert DurabilityNotSupported();
    }

    ProcessingMemory memory mem;

    mem.request._ownerAddress = _ownerAddress;
    mem.request._ownerTokenId = _ownerTokenId;
    mem.request._entityAddress = _entityAddress;
    mem.request.startNewTokenIfUndamaged = _startNewTokenIfNeeded;
    mem.request.ignoreAvailability = _ignoreAvailability;
    mem.brokenAmounts = new uint[](_entityTokenIds.length);
    mapping(uint => uint32) storage _ownerEntityTokensDurability = currentDurabilityStorage[
      _ownerAddress
    ][_ownerTokenId][_entityAddress];
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      mem.request._entityTokenId = _entityTokenIds[i];
      mem.request._durabilityLoss = _durabilityLosses[i];
      if (_reduceDurabilityInternal(_ownerEntityTokensDurability, mem.request)) {
        mem.anyBroken = true;
        mem.brokenAmounts[i] = 1;
      }
    }

    if (mem.anyBroken && address(BREAK_HANDLER) != address(0)) {
      BREAK_HANDLER.handleBrokenTokenBatch(
        _reducer,
        _ownerAddress,
        _ownerTokenId,
        _entityAddress,
        _entityTokenIds,
        mem.brokenAmounts
      );
    }
  }

  function reduceDurabilityBatch(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint[] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external onlyManager {
    if (!SUPPORTS_DURABILITY) {
      revert DurabilityNotSupported();
    }

    uint[] memory brokenAmounts = new uint[](_entityTokenIds.length);
    mapping(uint => uint32) storage _ownerEntityTokensDurability = currentDurabilityStorage[
      _ownerAddress
    ][_ownerTokenId][_entityAddress];
    bool anyBroken = false;

    for (uint i = 0; i < _entityTokenIds.length; i++) {
      DurabilityReductionRequest memory request = DurabilityReductionRequest(
        _ownerAddress,
        _ownerTokenId,
        _entityAddress,
        _entityTokenIds[i],
        _durabilityLoss,
        _startNewTokenIfNeeded,
        _ignoreAvailability
      );
      if (_reduceDurabilityInternal(_ownerEntityTokensDurability, request)) {
        anyBroken = true;
        brokenAmounts[i] = 1;
      }
    }

    if (anyBroken && address(BREAK_HANDLER) != address(0)) {
      BREAK_HANDLER.handleBrokenTokenBatch(
        _reducer,
        _ownerAddress,
        _ownerTokenId,
        _entityAddress,
        _entityTokenIds,
        brokenAmounts
      );
    }
  }

  function reduceDurabilityBatch(
    address _reducer,
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external onlyManager {
    if (!SUPPORTS_DURABILITY) {
      revert DurabilityNotSupported();
    }

    uint[][] memory brokenAmounts = new uint[][](_entityTokenIds.length);

    DurabilityReductionRequest memory request;
    request._durabilityLoss = _durabilityLoss;
    request.startNewTokenIfUndamaged = _startNewTokenIfNeeded;
    request.ignoreAvailability = _ignoreAvailability;
    request._entityAddress = _entityAddress;
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      mapping(uint => uint32) storage _ownerEntityTokensDurability = currentDurabilityStorage[
        _ownerAddresses[i]
      ][_ownerTokenIds[i]][_entityAddress];

      request._ownerAddress = _ownerAddresses[i];
      request._ownerTokenId = _ownerTokenIds[i];
      brokenAmounts[i] = new uint[](_entityTokenIds[i].length);
      for (uint j = 0; j < _entityTokenIds[i].length; j++) {
        request._entityTokenId = _entityTokenIds[i][j];
        if (_reduceDurabilityInternal(_ownerEntityTokensDurability, request)) {
          brokenAmounts[i][j] = 1;
        }
      }
    }

    if (address(BREAK_HANDLER) != address(0)) {
      BREAK_HANDLER.handleBrokenTokenBatch(
        _reducer,
        _ownerAddresses,
        _ownerTokenIds,
        _entityAddress,
        _entityTokenIds,
        brokenAmounts
      );
    }
  }

  function reduceDurabilityBatch(
    address _reducer,
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external onlyManager {
    if (!SUPPORTS_DURABILITY) {
      revert DurabilityNotSupported();
    }

    ProcessingMemory memory mem;
    mem.nestedBrokenAmounts = new uint[][](_entityTokenIds.length);
    mem.request._entityAddress = _entityAddress;
    mem.request.startNewTokenIfUndamaged = _startNewTokenIfNeeded;
    mem.request.ignoreAvailability = _ignoreAvailability;
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      mapping(uint => uint32) storage _ownerEntityTokensDurability = currentDurabilityStorage[
        _ownerAddresses[i]
      ][_ownerTokenIds[i]][_entityAddress];
      mem.nestedBrokenAmounts[i] = new uint[](_entityTokenIds[i].length);
      mem.request._ownerAddress = _ownerAddresses[i];
      mem.request._ownerTokenId = _ownerTokenIds[i];
      for (uint j = 0; j < _entityTokenIds[i].length; j++) {
        mem.request._durabilityLoss = _durabilityLosses[i][j];
        mem.request._entityTokenId = _entityTokenIds[i][j];
        if (_reduceDurabilityInternal(_ownerEntityTokensDurability, mem.request)) {
          mem.anyBroken = true;
          mem.nestedBrokenAmounts[i][j] = 1;
        }
      }
    }

    if (mem.anyBroken && address(BREAK_HANDLER) != address(0)) {
      BREAK_HANDLER.handleBrokenTokenBatch(
        _reducer,
        _ownerAddresses,
        _ownerTokenIds,
        _entityAddress,
        _entityTokenIds,
        mem.nestedBrokenAmounts
      );
    }
  }

  // Returns true if item broke
  // startNewTokenIfUndamaged - won't start breaking another peripheral if it already broke
  // ignoreAvailability - won't revert if ran out of supply to damage
  function _reduceDurabilityInternal(
    mapping(uint => uint32) storage _ownerEntityTokensDurability,
    DurabilityReductionRequest memory _request
  ) internal virtual returns (bool) {
    uint32 durability = _ownerEntityTokensDurability[_request._entityTokenId];
    if (durability == 0) {
      if (_request.startNewTokenIfUndamaged) {
        if (
          _isNextAvailable(
            _request._ownerAddress,
            _request._ownerTokenId,
            _request._entityAddress,
            _request._entityTokenId
          )
        ) {
          durability = _maximumTokenDurability(_request._entityAddress, _request._entityTokenId);
        } else if (_request.ignoreAvailability) {
          return false;
        } else {
          revert InsufficientDurability(
            _request._ownerAddress,
            _request._ownerTokenId,
            _request._entityAddress,
            _request._entityTokenId,
            _request._durabilityLoss
          );
        }
      } else {
        return false;
      }
    }

    if (_request._durabilityLoss >= durability) {
      _break(
        _request._ownerAddress,
        _request._ownerTokenId,
        _request._entityAddress,
        _request._entityTokenId
      );
      return true;
    }

    durability -= uint32(_request._durabilityLoss);
    _ownerEntityTokensDurability[_request._entityTokenId] = durability;
    emit EntityDurabilityChanged(
      _request._ownerAddress,
      _request._ownerTokenId,
      _request._entityAddress,
      _request._entityTokenId,
      durability
    );
    return false;
  }

  function updateBreakHandler(address _handler) external onlyAdmin {
    require(SUPPORTS_DURABILITY);
    BREAK_HANDLER = IBrokenTokenHandler(_handler);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint constant ARMORY_ENTITY_DISABLED = 0;
uint constant ARMORY_ENTITY_ERC20 = 1;
uint constant ARMORY_ENTITY_ERC721 = 2;
uint constant ARMORY_ENTITY_ERC1155 = 3;
uint constant ARMORY_ENTITY_DATA = 4;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./SingleERC1155ArmoryAdapter.sol";

abstract contract BurnMintERC1155ArmoryAdapter is SingleERC1155ArmoryAdapter {
  constructor(
    address _manager,
    address _actionPermit,
    address _collectionAddress,
    uint _requiredStakeActionPermission,
    uint _requiredUnstakeActionPermission,
    bool _supportsDurability,
    address _breakHandler
  )
    SingleERC1155ArmoryAdapter(
      _manager,
      _actionPermit,
      _collectionAddress,
      _requiredStakeActionPermission,
      _requiredUnstakeActionPermission,
      _supportsDurability,
      _breakHandler
    )
  {}

  function _burnFrom(address _from, uint256 _id, uint256 _amount) internal virtual;

  function _burnBatchFrom(
    address _from,
    uint256[] calldata _id,
    uint256[] calldata _amount
  ) internal virtual;

  function _burnBatchFrom(
    address _from,
    uint256[][] calldata _id,
    uint256[][] calldata _amount
  ) internal virtual;

  function _mintFor(address _for, uint256 _id, uint256 _amount) internal virtual;

  function _mintBatchFor(
    address _for,
    uint256[] calldata _id,
    uint256[] calldata _amount
  ) internal virtual;

  function _mintBatchFor(
    address _for,
    uint256[][] calldata _id,
    uint256[][] calldata _amount
  ) internal virtual;

  function _doStake(address _staker, uint256 _ids, uint256 _amounts) internal override {
    _burnFrom(_staker, _ids, _amounts);
  }

  function _doStakeBatch(
    address _staker,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) internal override {
    _burnBatchFrom(_staker, _ids, _amounts);
  }

  function _doStakeBatch(
    address _staker,
    uint256[][] calldata _ids,
    uint256[][] calldata _amounts
  ) internal override {
    _burnBatchFrom(_staker, _ids, _amounts);
  }

  function _doUnstake(address _staker, uint256 _id, uint256 _amount) internal override {
    _mintFor(_staker, _id, _amount);
  }

  function _doUnstakeBatch(
    address _staker,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) internal override {
    _mintBatchFor(_staker, _ids, _amounts);
  }

  function _doUnstakeBatch(
    address _staker,
    uint256[][] calldata _ids,
    uint256[][] calldata _amounts
  ) internal override {
    _mintBatchFor(_staker, _ids, _amounts);
  }

  function _doBurn(uint256 _id, uint256 _amount) internal override {}

  function _doBurnBatch(uint256[] calldata _ids, uint256[] calldata _amounts) internal override {}

  function _doBurnBatch(
    uint256[][] calldata _ids,
    uint256[][] calldata _amounts
  ) internal override {}

  function _doMint(uint256 _id, uint256 _amount) internal override {}

  function _doMintBatch(uint256[] calldata _ids, uint256[] calldata _amounts) internal override {}

  function _doMintBatch(
    uint256[][] calldata _ids,
    uint256[][] calldata _amounts
  ) internal override {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IArmoryEntityStorageAdapter {
  error Unauthorized(address _staker, address _ownerAddress, uint _ownerId);
  error UnsupportedOperation(address _entityAddress, string operation);
  error UnsupportedEntity(address _entityAddress);
  error InsufficientAmountStaked(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint _tokenIds,
    uint _tokenAmounts
  );

  function entityType() external pure returns (uint);

  function stake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) external;

  function stakeBatch(
    address _staker,
    address _ownerAddresses,
    uint256 _ownerIds,
    bytes32[] calldata _proof,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function stakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    bytes32[][] calldata _proofs,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) external;

  function unstakeBatch(
    address _staker,
    address _ownerAddresses,
    uint256 _ownerIds,
    bytes32[] calldata _proof,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function unstakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    bytes32[][] calldata _proofs,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function burn(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256 _entityTokenId, // only used for ERC-721, ERC-1155
    uint256 _entityAmount // only used for ERC-20, ERC-1155
  ) external;

  function burnBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function burnBatch(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function mint(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256 _entityTokenId, // only used for ERC-721, ERC-1155
    uint256 _entityAmount // only used for ERC-20, ERC-1155
  ) external;

  function mintBatch(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function mintBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  // Reverts if not enough tokens
  function batchCheckAmounts(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external view;

  // Reverts if not enough tokens
  function batchCheckAmounts(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external view;

  // Reverts if not enough tokens
  function batchCheckAmounts(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256 _entityAmounts // only used for ERC-20, ERC-1155
  ) external view;

  function balanceOf(
    address _ownerAddress,
    uint _ownerIds,
    address _entityAddress,
    uint _entityTokenId
  ) external view returns (uint);

  function balanceOfBatch(
    address _ownerAddress,
    uint _ownerIds,
    address _entityAddress,
    uint[] calldata _entityTokenIds
  ) external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "../AdventurerEquipment/IBrokenEquipmentHandler.sol";
import "./IArmoryEntityStorageAdapter.sol";

interface IDurabilityEnabledAdapter {
  function currentDurability(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) external view returns (uint);

  function currentDurabilityBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityId
  ) external view returns (uint[] memory);

  function currentDurabilityBatch(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress,
    uint256[][] calldata _entityId
  ) external view returns (uint[][] memory);

  function currentDurabilityPercentage(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) external view returns (uint);

  function currentDurabilityBatchPercentage(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityId
  ) external view returns (uint[] memory);

  function currentDurabilityBatchPercentage(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress,
    uint256[][] calldata _entityId
  ) external view returns (uint[][] memory);

  function reduceDurability(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityBatch(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenIds,
    address _entityAddress,
    uint[] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityBatch(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenIds,
    address _entityAddress,
    uint[] calldata _entityTokenIds,
    uint[] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityBatch(
    address _reducer,
    address[] calldata _ownerAddress,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityBatch(
    address _reducer,
    address[] calldata _ownerAddress,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] calldata _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../Armory/IArmoryEntityStorageAdapter.sol";
import "../Armory/ArmoryConstants.sol";
import "../Action/IActionPermit.sol";
import "../Manager/ManagerModifier.sol";
import "./AbstractDurabilityEnabledArmoryAdapter.sol";

abstract contract SingleERC1155ArmoryAdapter is
  ERC1155Holder,
  ReentrancyGuard,
  ManagerModifier,
  IArmoryEntityStorageAdapter,
  AbstractDurabilityEnabledArmoryAdapter
{
  //=======================================
  // Mappings
  //=======================================

  // Owner address -> Owner Token Id -> Collection Token Id -> Amount staked
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public stakerBalances;

  IActionPermit public ACTION_PERMIT;

  address immutable COLLECTION_ADDRESS;
  uint immutable REQUIRED_STAKE_ACTION_PERMISSION;
  uint immutable REQUIRED_UNSTAKE_ACTION_PERMISSION;

  constructor(
    address _manager,
    address _actionPermit,
    address _collectionAddress,
    uint _requiredStakeActionPermission,
    uint _requiredUnstakeActionPermission,
    bool _supportsDurability,
    address _breakHandler
  ) AbstractDurabilityEnabledArmoryAdapter(_manager, _breakHandler, _supportsDurability) {
    ACTION_PERMIT = IActionPermit(_actionPermit);
    COLLECTION_ADDRESS = _collectionAddress;
    REQUIRED_STAKE_ACTION_PERMISSION = _requiredStakeActionPermission;
    REQUIRED_UNSTAKE_ACTION_PERMISSION = _requiredUnstakeActionPermission;
  }

  function _doStake(address _staker, uint256 _ids, uint256 _amounts) internal virtual;

  function _doStakeBatch(
    address _staker,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) internal virtual;

  function _doStakeBatch(
    address _staker,
    uint256[][] calldata _ids,
    uint256[][] calldata _amounts
  ) internal virtual;

  function _doUnstake(address _staker, uint256 _ids, uint256 _amounts) internal virtual;

  function _doUnstakeBatch(
    address _staker,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) internal virtual;

  function _doUnstakeBatch(
    address _staker,
    uint256[][] calldata _ids,
    uint256[][] calldata _amounts
  ) internal virtual;

  function _doBurn(uint256 _id, uint256 _amount) internal virtual;

  function _doBurnBatch(uint256[] calldata _ids, uint256[] calldata _amounts) internal virtual;

  function _doBurnBatch(uint256[][] calldata _ids, uint256[][] calldata _amounts) internal virtual;

  function _doMint(uint256 _id, uint256 _amount) internal virtual;

  function _doMintBatch(uint256[] calldata _ids, uint256[] calldata _amounts) internal virtual;

  function _doMintBatch(uint256[][] calldata _ids, uint256[][] calldata _amounts) internal virtual;

  function entityType() external pure returns (uint) {
    return ARMORY_ENTITY_ERC1155;
  }

  function stake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) public onlyManager nonReentrant {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    ACTION_PERMIT.checkPermissions(
      _staker,
      _ownerAddress,
      _ownerId,
      _proof,
      REQUIRED_STAKE_ACTION_PERMISSION
    );

    _doStake(_staker, _entityTokenId, _entityAmount);

    stakerBalances[_ownerAddress][_ownerId][_entityTokenId] += _entityAmount;
  }

  function stakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityTokenIds,
    uint256[] calldata _entityAmounts
  ) public onlyManager nonReentrant {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    ACTION_PERMIT.checkPermissions(
      _staker,
      _ownerAddress,
      _ownerId,
      _proof,
      REQUIRED_STAKE_ACTION_PERMISSION
    );

    _doStakeBatch(_staker, _entityTokenIds, _entityAmounts);

    mapping(uint256 => uint256) storage memoryBalances = stakerBalances[_ownerAddress][_ownerId];
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      memoryBalances[_entityTokenIds[i]] += _entityAmounts[i];
    }
  }

  function stakeBatch(
    address _staker,
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityTokenIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    ACTION_PERMIT.checkPermissionsMany(
      _staker,
      _ownerAddress,
      _ownerId,
      _proofs,
      REQUIRED_STAKE_ACTION_PERMISSION
    );

    _doStakeBatch(_staker, _entityTokenIds, _entityAmounts);

    for (uint i = 0; i < _entityTokenIds.length; i++) {
      mapping(uint256 => uint256) storage balance = stakerBalances[_ownerAddress[i]][_ownerId[i]];
      for (uint j = 0; j < _entityTokenIds[i].length; j++) {
        balance[_entityTokenIds[i][j]] += _entityAmounts[i][j];
      }
    }
  }

  function unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proofs,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) public onlyManager nonReentrant {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    ACTION_PERMIT.checkPermissions(
      _staker,
      _ownerAddress,
      _ownerId,
      _proofs,
      REQUIRED_UNSTAKE_ACTION_PERMISSION
    );

    _checkAndDecreaseAmountInternal(_ownerAddress, _ownerId, _entityTokenId, _entityAmount);

    _doUnstake(_staker, _entityTokenId, _entityAmount);
  }

  function unstakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityTokenIds,
    uint256[] calldata _entityAmounts
  ) external onlyManager nonReentrant {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    ACTION_PERMIT.checkPermissions(
      _staker,
      _ownerAddress,
      _ownerId,
      _proof,
      REQUIRED_UNSTAKE_ACTION_PERMISSION
    );

    _checkAndDecreaseAmountsInternal(_ownerAddress, _ownerId, _entityTokenIds, _entityAmounts);

    _doUnstakeBatch(_staker, _entityTokenIds, _entityAmounts);
  }

  function unstakeBatch(
    address _staker,
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityTokenIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    ACTION_PERMIT.checkPermissionsMany(
      _staker,
      _ownerAddress,
      _ownerId,
      _proofs,
      REQUIRED_UNSTAKE_ACTION_PERMISSION
    );

    _checkAndDecreaseAmountsInternal(_ownerAddress, _ownerId, _entityTokenIds, _entityAmounts);

    _doUnstakeBatch(_staker, _entityTokenIds, _entityAmounts);
  }

  function burnBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityTokenIds,
    uint256[] calldata _entityAmounts
  ) external onlyManager nonReentrant {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    mapping(uint256 => uint256) storage ownedEntities = stakerBalances[_ownerAddress][_ownerId];
    mapping(uint256 => uint32) storage ownedEntityDurabilities = _ownedEntityDurabilityMapping(
      _ownerAddress,
      _ownerId,
      _entityAddress
    );

    _checkAndDecreaseAmountsInternal(_ownerAddress, _ownerId, _entityTokenIds, _entityAmounts);

    _doBurnBatch(_entityTokenIds, _entityAmounts);
  }

  function burnBatch(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external onlyManager nonReentrant {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    _checkAndDecreaseAmountsInternal(_ownerAddress, _ownerId, _entityTokenIds, _entityAmounts);

    _doBurnBatch(_entityTokenIds, _entityAmounts);
  }

  function burn(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) public onlyManager nonReentrant {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    _checkAndDecreaseAmountInternal(_ownerAddress, _ownerId, _entityTokenId, _entityAmount);

    _doBurn(_entityTokenId, _entityAmount);
  }

  function mintBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityTokenIds,
    uint256[] calldata _entityAmounts
  ) external onlyManager nonReentrant {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    _doMintBatch(_entityTokenIds, _entityAmounts);

    mapping(uint256 => uint256) storage ownedEntities = stakerBalances[_ownerAddress][_ownerId];
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      ownedEntities[_entityTokenIds[i]] += _entityAmounts[i];
    }
  }

  function mintBatch(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external onlyManager nonReentrant {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    _doMintBatch(_entityTokenIds, _entityAmounts);

    for (uint i = 0; i < _entityTokenIds.length; i++) {
      mapping(uint256 => uint256) storage memoryBalances = stakerBalances[_ownerAddress[i]][
        _ownerId[i]
      ];
      for (uint j = 0; j < _entityTokenIds[i].length; j++) {
        memoryBalances[_entityTokenIds[i][j]] += _entityAmounts[i][j];
      }
    }
  }

  function mint(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) external onlyManager nonReentrant {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    _doMint(_entityTokenId, _entityAmount);
    stakerBalances[_ownerAddress][_ownerId][_entityTokenId] += _entityAmount;
  }

  function batchCheckAmounts(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityTokenIds,
    uint256[] calldata _entityAmounts
  ) public view {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    mapping(uint256 => uint256) storage ownedEntities = stakerBalances[_ownerAddress][_ownerId];
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      _verifyBalance(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        ownedEntities,
        _entityTokenIds[i],
        _entityAmounts[i]
      );
    }
  }

  function batchCheckAmounts(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityTokenIds,
    uint256[][] calldata _entityAmounts
  ) external view {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    for (uint i = 0; i < _entityTokenIds.length; i++) {
      batchCheckAmounts(
        _ownerAddresses[i],
        _ownerIds[i],
        _entityAddress,
        _entityTokenIds[i],
        _entityAmounts[i]
      );
    }
  }

  function batchCheckAmounts(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityTokenIds,
    uint256 _entityAmounts
  ) external view {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    mapping(uint256 => uint256) storage ownedEntities = stakerBalances[_ownerAddress][_ownerId];
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      _verifyBalance(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        ownedEntities,
        _entityTokenIds[i],
        _entityAmounts
      );
    }
  }

  function balanceOf(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint _entityTokenId
  ) external view returns (uint) {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    return stakerBalances[_ownerAddress][_ownerId][_entityTokenId];
  }

  function balanceOfBatch(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint[] calldata _entityTokenIds
  ) external view returns (uint[] memory result) {
    if (_entityAddress != COLLECTION_ADDRESS) {
      revert UnsupportedEntity(_entityAddress);
    }

    mapping(uint256 => uint256) storage ownedEntities = stakerBalances[_ownerAddress][_ownerId];
    result = new uint[](_entityTokenIds.length);
    for (uint i = 0; i < result.length; i++) {
      result[i] = ownedEntities[_entityTokenIds[i]];
    }
  }

  //---------------------------
  // Internal
  //---------------------------

  function _verifyBalance(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    mapping(uint256 => uint256) storage _ownedEntities,
    uint _tokenId,
    uint _requiredAmount
  ) internal view virtual {
    if (_ownedEntities[_tokenId] < _requiredAmount) {
      revert InsufficientAmountStaked(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _tokenId,
        _requiredAmount
      );
    }
  }

  function _checkAndDecreaseAmountInternal(
    address _ownerAddress,
    uint256 _ownerId,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) internal {
    mapping(uint256 => uint256) storage ownedEntities = stakerBalances[_ownerAddress][_ownerId];

    uint damagedEntityCount;
    // If the entity is damaged then we require x more to unstake
    if (SUPPORTS_DURABILITY) {
      damagedEntityCount = _damagedEntityCount(
        _ownerAddress,
        _ownerId,
        COLLECTION_ADDRESS,
        _entityTokenId
      );
    }
    if (
      ownedEntities[_entityTokenId] >= damagedEntityCount &&
      ownedEntities[_entityTokenId] - damagedEntityCount >= _entityAmount
    ) {
      ownedEntities[_entityTokenId] -= _entityAmount;
    } else {
      revert InsufficientAmountStaked(
        _ownerAddress,
        _ownerId,
        COLLECTION_ADDRESS,
        _entityTokenId,
        _entityAmount
      );
    }
  }

  function _checkAndDecreaseAmountsInternal(
    address _ownerAddress,
    uint256 _ownerId,
    uint256[] calldata _entityTokenIds,
    uint256[] calldata _entityAmounts
  ) internal {
    mapping(uint256 => uint256) storage ownedEntities = stakerBalances[_ownerAddress][_ownerId];
    mapping(uint256 => uint32) storage ownedEntityDurabilities = _ownedEntityDurabilityMapping(
      _ownerAddress,
      _ownerId,
      COLLECTION_ADDRESS
    );

    uint damagedEntityCount;
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      // If the entity is damaged then we require x more to unstake
      if (SUPPORTS_DURABILITY) {
        damagedEntityCount = _damagedEntityCount(ownedEntityDurabilities, _entityTokenIds[i]);
      }
      if (
        ownedEntities[_entityTokenIds[i]] >= damagedEntityCount &&
        ownedEntities[_entityTokenIds[i]] - damagedEntityCount >= _entityAmounts[i]
      ) {
        ownedEntities[_entityTokenIds[i]] -= _entityAmounts[i];
      } else {
        revert InsufficientAmountStaked(
          _ownerAddress,
          _ownerId,
          COLLECTION_ADDRESS,
          _entityTokenIds[i],
          _entityAmounts[i]
        );
      }
    }
  }

  function _checkAndDecreaseAmountsInternal(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    uint256[][] calldata _entityTokenIds,
    uint256[][] calldata _entityAmounts
  ) internal {
    for (uint i = 0; i < _ownerAddresses.length; i++) {
      _checkAndDecreaseAmountsInternal(
        _ownerAddresses[i],
        _ownerIds[i],
        _entityTokenIds[i],
        _entityAmounts[i]
      );
    }
  }

  //---------------------------
  // Durability Adapter
  //---------------------------

  function _burnOnBreak(
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId
  ) internal override {
    burn(_ownerAddress, _ownerTokenId, _entityAddress, _entityTokenId, 1);
  }

  function _isNextAvailable(
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId
  ) internal view override returns (bool) {
    require(_entityAddress == COLLECTION_ADDRESS);

    return stakerBalances[_ownerAddress][_ownerTokenId][_entityTokenId] > 0;
  }

  //---------------------------
  // Admin
  //---------------------------
  function updatePermit(address _actionPermit) external onlyAdmin {
    ACTION_PERMIT = IActionPermit(_actionPermit);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../Manager/ManagerModifier.sol";

contract Material is ERC1155, ReentrancyGuard, ManagerModifier {
  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) ERC1155("") ManagerModifier(_manager) {
    UNBOUND = true;
  }

  bool public UNBOUND;

  //=======================================
  // External
  //=======================================
  function mintFor(address _for, uint256 _id, uint256 _amount) external nonReentrant onlyMinter {
    _mint(_for, _id, _amount, "");
  }

  function mintBatchFor(
    address _for,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) external nonReentrant onlyMinter {
    _mintBatch(_for, _ids, _amounts, "");
  }

  function burn(uint256 _id, uint256 _amount) external nonReentrant {
    _burn(msg.sender, _id, _amount);
  }

  function burnBatch(uint256[] memory ids, uint256[] memory amounts) external nonReentrant {
    _burnBatch(msg.sender, ids, amounts);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal view override {
    if (from == address(0) || to == address(0)) {
      return;
    }

    require(UNBOUND, "Material: Token not unbound");
  }

  //=======================================
  // Admin
  //=======================================
  function setUri(string memory _uri) external onlyAdmin {
    _setURI(_uri);
  }

  function bind() external onlyAdmin {
    UNBOUND = false;
  }

  function unbind() external onlyAdmin {
    UNBOUND = true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;

int256 constant SIGNED_ZERO = 0;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/IManager.sol";

abstract contract ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IManager public immutable MANAGER;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) {
    MANAGER = IManager(_manager);
  }

  //=======================================
  // Modifiers
  //=======================================
  modifier onlyAdmin() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not manager");
    _;
  }

  modifier onlyMinter() {
    require(MANAGER.isManager(msg.sender, 1), "Manager: Not minter");
    _;
  }

  modifier onlyTokenMinter() {
    require(MANAGER.isManager(msg.sender, 2), "Manager: Not token minter");
    _;
  }

  modifier onlyBinder() {
    require(MANAGER.isManager(msg.sender, 3), "Manager: Not binder");
    _;
  }
}