// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/IERC1155MetadataURI.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/ERC1155.sol)

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
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
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
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
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
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
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
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
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
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/DoubleEndedQueue.sol)
pragma solidity ^0.8.4;

import "../math/SafeCast.sol";

/**
 * @dev A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 *
 * The struct is called `Bytes32Deque`. Other types can be cast to and from `bytes32`. This data structure can only be
 * used in storage, and not in memory.
 * ```solidity
 * DoubleEndedQueue.Bytes32Deque queue;
 * ```
 *
 * _Available since v4.6._
 */
library DoubleEndedQueue {
    /**
     * @dev An operation (e.g. {front}) couldn't be completed due to the queue being empty.
     */
    error Empty();

    /**
     * @dev An operation (e.g. {at}) couldn't be completed due to an index being out of bounds.
     */
    error OutOfBounds();

    /**
     * @dev Indices are signed integers because the queue can grow in any direction. They are 128 bits so begin and end
     * are packed in a single storage slot for efficient access. Since the items are added one at a time we can safely
     * assume that these 128-bit indices will not overflow, and use unchecked arithmetic.
     *
     * Struct members have an underscore prefix indicating that they are "private" and should not be read or written to
     * directly. Use the functions provided below instead. Modifying the struct manually may violate assumptions and
     * lead to unexpected behavior.
     *
     * Indices are in the range [begin, end) which means the first item is at data[begin] and the last item is at
     * data[end - 1].
     */
    struct Bytes32Deque {
        int128 _begin;
        int128 _end;
        mapping(int128 => bytes32) _data;
    }

    /**
     * @dev Inserts an item at the end of the queue.
     */
    function pushBack(Bytes32Deque storage deque, bytes32 value) internal {
        int128 backIndex = deque._end;
        deque._data[backIndex] = value;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    /**
     * @dev Removes the item at the end of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popBack(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        value = deque._data[backIndex];
        delete deque._data[backIndex];
        deque._end = backIndex;
    }

    /**
     * @dev Inserts an item at the beginning of the queue.
     */
    function pushFront(Bytes32Deque storage deque, bytes32 value) internal {
        int128 frontIndex;
        unchecked {
            frontIndex = deque._begin - 1;
        }
        deque._data[frontIndex] = value;
        deque._begin = frontIndex;
    }

    /**
     * @dev Removes the item at the beginning of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popFront(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        value = deque._data[frontIndex];
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

    /**
     * @dev Returns the item at the beginning of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function front(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    /**
     * @dev Returns the item at the end of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function back(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        return deque._data[backIndex];
    }

    /**
     * @dev Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
     * `length(deque) - 1`.
     *
     * Reverts with `OutOfBounds` if the index is out of bounds.
     */
    function at(Bytes32Deque storage deque, uint256 index) internal view returns (bytes32 value) {
        // int256(deque._begin) is a safe upcast
        int128 idx = SafeCast.toInt128(int256(deque._begin) + SafeCast.toInt256(index));
        if (idx >= deque._end) revert OutOfBounds();
        return deque._data[idx];
    }

    /**
     * @dev Resets the queue back to being empty.
     *
     * NOTE: The current items are left behind in storage. This does not affect the functioning of the queue, but misses
     * out on potential gas refunds.
     */
    function clear(Bytes32Deque storage deque) internal {
        deque._begin = 0;
        deque._end = 0;
    }

    /**
     * @dev Returns the number of items in the queue.
     */
    function length(Bytes32Deque storage deque) internal view returns (uint256) {
        // The interface preserves the invariant that begin <= end so we assume this will not overflow.
        // We also assume there are at most int256.max items in the queue.
        unchecked {
            return uint256(int256(deque._end) - int256(deque._begin));
        }
    }

    /**
     * @dev Returns true if the queue is empty.
     */
    function empty(Bytes32Deque storage deque) internal view returns (bool) {
        return deque._end <= deque._begin;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {IDiamondCut} from "@chromatic-protocol/contracts/core/interfaces/IDiamondCut.sol";
import {DiamondStorage, DiamondStorageLib} from "@chromatic-protocol/contracts/core/libraries/DiamondStorage.sol";

abstract contract Diamond {
    constructor(address _diamondCutFacet) payable {
        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        DiamondStorageLib.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        DiamondStorage storage ds;
        bytes32 position = DiamondStorageLib.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IChromaticLiquidator} from "@chromatic-protocol/contracts/core/interfaces/IChromaticLiquidator.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";
import {CLBTokenDeployerLib} from "@chromatic-protocol/contracts/core/libraries/deployer/CLBTokenDeployer.sol";
import {MarketStorage, MarketStorageLib} from "@chromatic-protocol/contracts/core/libraries/MarketStorage.sol";
import {Diamond} from "@chromatic-protocol/contracts/core/base/Diamond.sol";

/**
 * @title ChromaticMarket
 * @dev A contract that represents a Chromatic market, combining trade and liquidity functionalities.
 */
contract ChromaticMarket is Diamond {
    constructor(address diamondCutFacet) Diamond(diamondCutFacet) {
        IChromaticMarketFactory factory = IChromaticMarketFactory(msg.sender);

        (address _oracleProvider, address _settlementToken) = factory.parameters();
        MarketStorage storage ms = MarketStorageLib.marketStorage();

        ms.factory = factory;
        ms.oracleProvider = IOracleProvider(_oracleProvider);
        ms.settlementToken = IERC20Metadata(_settlementToken);
        ms.clbToken = ICLBToken(CLBTokenDeployerLib.deploy());
        ms.liquidator = IChromaticLiquidator(factory.liquidator());
        ms.vault = IChromaticVault(factory.vault());
        ms.keeperFeePayer = IKeeperFeePayer(factory.keeperFeePayer());

        ms.liquidityPool.initialize();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IInterestCalculator} from "@chromatic-protocol/contracts/core/interfaces/IInterestCalculator.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";
import {IMarketDeployer} from "@chromatic-protocol/contracts/core/interfaces/factory/IMarketDeployer.sol";
import {IOracleProviderRegistry} from "@chromatic-protocol/contracts/core/interfaces/factory/IOracleProviderRegistry.sol";
import {ISettlementTokenRegistry} from "@chromatic-protocol/contracts/core/interfaces/factory/ISettlementTokenRegistry.sol";
import {IMarketState} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketState.sol";
import {OracleProviderRegistry, OracleProviderRegistryLib} from "@chromatic-protocol/contracts/core/libraries/registry/OracleProviderRegistry.sol";
import {SettlementTokenRegistry, SettlementTokenRegistryLib} from "@chromatic-protocol/contracts/core/libraries/registry/SettlementTokenRegistry.sol";
import {InterestRate} from "@chromatic-protocol/contracts/core/libraries/InterestRate.sol";
import {MarketDeployer, MarketDeployerLib, Parameters} from "@chromatic-protocol/contracts/core/libraries/deployer/MarketDeployer.sol";

/**
 * @title ChromaticMarketFactory
 * @dev Contract for managing the creation and registration of Chromatic markets.
 */
contract ChromaticMarketFactory is IChromaticMarketFactory {
    using OracleProviderRegistryLib for OracleProviderRegistry;
    using SettlementTokenRegistryLib for SettlementTokenRegistry;
    using MarketDeployerLib for MarketDeployer;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public override dao;

    address public override liquidator;
    address public override vault;
    address public override keeperFeePayer;
    address public override treasury;

    address private immutable marketDiamondCutFacet;
    address private immutable marketLoupeFacet;
    address private immutable marketStateFacet;
    address private immutable marketLiquidityFacet;
    address private immutable marketLiquidityLensFacet;
    address private immutable marketTradeFacet;
    address private immutable marketLiquidateFacet;
    address private immutable marketSettleFacet;

    OracleProviderRegistry private _oracleProviderRegistry;
    SettlementTokenRegistry private _settlementTokenRegistry;

    MarketDeployer private _deployer;
    mapping(address => mapping(address => bool)) private _registered;
    mapping(address => address[]) private _marketsBySettlementToken;
    EnumerableSet.AddressSet private _markets;

    /**
     * @dev Throws an error indicating that the caller is not the DAO.
     */
    error OnlyAccessableByDao();

    /**
     * @dev Throws an error indicating that the chromatic liquidator address is already set.
     */
    error AlreadySetLiquidator();

    /**
     * @dev Throws an error indicating that the chromatic vault address is already set.
     */
    error AlreadySetVault();

    /**
     * @dev Throws an error indicating that the keeper fee payer address is already set.
     */
    error AlreadySetKeeperFeePayer();

    /**
     * @dev Throws an error indicating that the oracle provider is not registered.
     */
    error NotRegisteredOracleProvider();

    /**
     * @dev Throws an error indicating that the settlement token is not registered.
     */
    error NotRegisteredSettlementToken();

    /**
     * @dev Throws an error indicating that a market already exists for the given oracle provider and settlement token.
     */
    error ExistMarket();

    /**
     * @dev Modifier to restrict access to only the DAO address
     *      Throws an `OnlyAccessableByDao` error if the caller is not the DAO.
     */
    modifier onlyDao() {
        if (msg.sender != dao) revert OnlyAccessableByDao();
        _;
    }

    /**
     * @dev Modifier to ensure that the specified oracle provider is registered.
     *      Throws a `NotRegisteredOracleProvider` error if the oracle provider is not registered.
     *
     * @param oracleProvider The address of the oracle provider to check.
     *
     * Requirements:
     * - The `oracleProvider` address must be registered in the `_oracleProviderRegistry`.
     */
    modifier onlyRegisteredOracleProvider(address oracleProvider) {
        if (!_oracleProviderRegistry.isRegistered(oracleProvider))
            revert NotRegisteredOracleProvider();
        _;
    }

    /**
     * @dev Initializes the ChromaticMarketFactory contract.
     * @param _marketDiamondCutFacet The market diamond cut facet address.
     * @param _marketLoupeFacet The market loupe facet address.
     * @param _marketStateFacet The market state facet address.
     * @param _marketLiquidityFacet The market liquidity facet address.
     * @param _marketLiquidityLensFacet The market liquidity lens facet address.
     * @param _marketTradeFacet The market trade facet address.
     * @param _marketLiquidateFacet The market liquidate facet address.
     * @param _marketSettleFacet The market settle facet address.
     */
    constructor(
        address _marketDiamondCutFacet,
        address _marketLoupeFacet,
        address _marketStateFacet,
        address _marketLiquidityFacet,
        address _marketLiquidityLensFacet,
        address _marketTradeFacet,
        address _marketLiquidateFacet,
        address _marketSettleFacet
    ) {
        require(_marketDiamondCutFacet != address(0));
        require(_marketLoupeFacet != address(0));
        require(_marketStateFacet != address(0));
        require(_marketLiquidityFacet != address(0));
        require(_marketLiquidityLensFacet != address(0));
        require(_marketTradeFacet != address(0));
        require(_marketLiquidateFacet != address(0));
        require(_marketSettleFacet != address(0));

        dao = msg.sender;
        treasury = dao;

        marketDiamondCutFacet = _marketDiamondCutFacet;
        marketLoupeFacet = _marketLoupeFacet;
        marketStateFacet = _marketStateFacet;
        marketLiquidityFacet = _marketLiquidityFacet;
        marketLiquidityLensFacet = _marketLiquidityLensFacet;
        marketTradeFacet = _marketTradeFacet;
        marketLiquidateFacet = _marketLiquidateFacet;
        marketSettleFacet = _marketSettleFacet;
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     * @dev This function can only be called by the DAO address.
     */
    function updateDao(address _dao) external override onlyDao {
        require(_dao != address(0));
        dao = _dao;
        emit UpdateDao(dao);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     * @dev This function can only be called by the DAO address.
     */
    function updateTreasury(address _treasury) external override onlyDao {
        require(_treasury != address(0));
        treasury = _treasury;
        emit UpdateTreasury(treasury);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     * @dev This function can only be called by the DAO address.
     *      Throws an `AlreadySetLiquidator` error if the liquidator address has already been set.
     */
    function setLiquidator(address _liquidator) external override onlyDao {
        require(_liquidator != address(0));
        if (liquidator != address(0)) revert AlreadySetLiquidator();

        liquidator = _liquidator;
        emit SetLiquidator(liquidator);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     * @dev This function can only be called by the DAO address.
     *      Throws an `AlreadySetVault` error if the vault address has already been set.
     */
    function setVault(address _vault) external override onlyDao {
        require(_vault != address(0));
        if (vault != address(0)) revert AlreadySetVault();

        vault = _vault;
        emit SetVault(vault);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     * @dev This function can only be called by the DAO address.
     *      Throws an `AlreadySetKeeperFeePayer` error if the keeper fee payer address has already been set.
     */
    function setKeeperFeePayer(address _keeperFeePayer) external override onlyDao {
        require(_keeperFeePayer != address(0));
        if (keeperFeePayer != address(0)) revert AlreadySetKeeperFeePayer();

        keeperFeePayer = _keeperFeePayer;
        emit SetKeeperFeePayer(keeperFeePayer);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     */
    function getMarkets() external view override returns (address[] memory) {
        return _markets.values();
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     */
    function getMarketsBySettlmentToken(
        address settlementToken
    ) external view override returns (address[] memory) {
        return _marketsBySettlementToken[settlementToken];
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     */
    function getMarket(
        address oracleProvider,
        address settlementToken
    ) external view override returns (address) {
        if (!_registered[oracleProvider][settlementToken]) return address(0);

        address[] memory markets = _marketsBySettlementToken[settlementToken];
        for (uint i; i < markets.length; ) {
            //slither-disable-next-line calls-loop
            if (address(IMarketState(markets[i]).oracleProvider()) == oracleProvider) {
                return markets[i];
            }

            unchecked {
                i++;
            }
        }
        return address(0);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     */
    function isRegisteredMarket(address market) external view override returns (bool) {
        return _markets.contains(market);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     * @dev This function creates a new market using the specified oracle provider and settlement token addresses.
     *      Throws a `NotRegisteredSettlementToken` error if the settlement token is not registered.
     *      Throws an `ExistMarket` error if the market already exists for the given oracle provider and settlement token.
     */
    function createMarket(
        address oracleProvider,
        address settlementToken
    ) external override onlyRegisteredOracleProvider(oracleProvider) {
        if (!_settlementTokenRegistry.isRegistered(settlementToken))
            revert NotRegisteredSettlementToken();

        if (_registered[oracleProvider][settlementToken]) revert ExistMarket();
        _registered[oracleProvider][settlementToken] = true;

        address market = _deployer.deploy(
            oracleProvider,
            settlementToken,
            marketDiamondCutFacet,
            marketLoupeFacet,
            marketStateFacet,
            marketLiquidityFacet,
            marketLiquidityLensFacet,
            marketTradeFacet,
            marketLiquidateFacet,
            marketSettleFacet
        );

        //slither-disable-next-line reentrancy-benign
        _marketsBySettlementToken[settlementToken].push(market);
        //slither-disable-next-line unused-return
        _markets.add(market);

        //slither-disable-next-line reentrancy-events
        emit MarketCreated(oracleProvider, settlementToken, market);

        IChromaticVault(vault).createMarketEarningDistributionTask(market);
    }

    /**
     * @inheritdoc IMarketDeployer
     */
    function parameters()
        external
        view
        override
        returns (address oracleProvider, address settlementToken)
    {
        Parameters memory params = _deployer.parameters;
        return (params.oracleProvider, params.settlementToken);
    }

    // implement IOracleProviderRegistry

    /**
     * @inheritdoc IOracleProviderRegistry
     * @dev This function can only be called by the DAO address.
     */
    function registerOracleProvider(
        address oracleProvider,
        OracleProviderProperties memory properties
    ) external override onlyDao {
        _oracleProviderRegistry.register(
            oracleProvider,
            properties.minTakeProfitBPS,
            properties.maxTakeProfitBPS,
            properties.leverageLevel
        );
        emit OracleProviderRegistered(oracleProvider, properties);
    }

    /**
     * @inheritdoc IOracleProviderRegistry
     * @dev This function can only be called by the DAO address.
     */
    function unregisterOracleProvider(address oracleProvider) external override onlyDao {
        _oracleProviderRegistry.unregister(oracleProvider);
        emit OracleProviderUnregistered(oracleProvider);
    }

    /**
     * @inheritdoc IOracleProviderRegistry
     */
    function registeredOracleProviders() external view override returns (address[] memory) {
        return _oracleProviderRegistry.oracleProviders();
    }

    /**
     * @inheritdoc IOracleProviderRegistry
     */
    function isRegisteredOracleProvider(
        address oracleProvider
    ) external view override returns (bool) {
        return _oracleProviderRegistry.isRegistered(oracleProvider);
    }

    /**
     * @inheritdoc IOracleProviderRegistry
     */
    function getOracleProviderProperties(
        address oracleProvider
    )
        external
        view
        override
        onlyRegisteredOracleProvider(oracleProvider)
        returns (OracleProviderProperties memory)
    {
        (
            uint32 minTakeProfitBPS,
            uint32 maxTakeProfitBPS,
            uint8 leverageLevel
        ) = _oracleProviderRegistry.getOracleProviderProperties(oracleProvider);

        return
            OracleProviderProperties({
                minTakeProfitBPS: minTakeProfitBPS,
                maxTakeProfitBPS: maxTakeProfitBPS,
                leverageLevel: leverageLevel
            });
    }

    /**
     * @inheritdoc IOracleProviderRegistry
     * @dev This function can only be called by the DAO and registered oracle providers.
     */
    function updateTakeProfitBPSRange(
        address oracleProvider,
        uint32 minTakeProfitBPS,
        uint32 maxTakeProfitBPS
    ) external override onlyDao onlyRegisteredOracleProvider(oracleProvider) {
        _oracleProviderRegistry.setTakeProfitBPSRange(
            oracleProvider,
            minTakeProfitBPS,
            maxTakeProfitBPS
        );
        emit UpdateTakeProfitBPSRange(oracleProvider, minTakeProfitBPS, maxTakeProfitBPS);
    }

    /**
     * @inheritdoc IOracleProviderRegistry
     * @dev This function can only be called by the DAO and registered oracle providers.
     */
    function updateLeverageLevel(
        address oracleProvider,
        uint8 level
    ) external override onlyDao onlyRegisteredOracleProvider(oracleProvider) {
        require(level <= 1);
        _oracleProviderRegistry.setLeverageLevel(oracleProvider, level);
        emit UpdateLeverageLevel(oracleProvider, level);
    }

    // implement ISettlementTokenRegistry

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function registerSettlementToken(
        address token,
        uint256 minimumMargin,
        uint256 interestRate,
        uint256 flashLoanFeeRate,
        uint256 earningDistributionThreshold,
        uint24 uniswapFeeTier
    ) external override onlyDao {
        _settlementTokenRegistry.register(
            token,
            minimumMargin,
            interestRate,
            flashLoanFeeRate,
            earningDistributionThreshold,
            uniswapFeeTier
        );

        emit SettlementTokenRegistered(
            token,
            minimumMargin,
            interestRate,
            flashLoanFeeRate,
            earningDistributionThreshold,
            uniswapFeeTier
        );

        IKeeperFeePayer(keeperFeePayer).approveToRouter(token, true);
        IChromaticVault(vault).createMakerEarningDistributionTask(token);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function registeredSettlementTokens() external view override returns (address[] memory) {
        return _settlementTokenRegistry.settlementTokens();
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function isRegisteredSettlementToken(address token) external view override returns (bool) {
        return _settlementTokenRegistry.isRegistered(token);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function getMinimumMargin(address token) external view returns (uint256) {
        return _settlementTokenRegistry.getMinimumMargin(token);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function setMinimumMargin(address token, uint256 minimumMargin) external onlyDao {
        _settlementTokenRegistry.setMinimumMargin(token, minimumMargin);
        emit SetMinimumMargin(token, minimumMargin);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function getFlashLoanFeeRate(address token) external view returns (uint256) {
        return _settlementTokenRegistry.getFlashLoanFeeRate(token);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function setFlashLoanFeeRate(address token, uint256 flashLoanFeeRate) external onlyDao {
        _settlementTokenRegistry.setFlashLoanFeeRate(token, flashLoanFeeRate);
        emit SetFlashLoanFeeRate(token, flashLoanFeeRate);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function getEarningDistributionThreshold(address token) external view returns (uint256) {
        return _settlementTokenRegistry.getEarningDistributionThreshold(token);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function setEarningDistributionThreshold(
        address token,
        uint256 earningDistributionThreshold
    ) external onlyDao {
        _settlementTokenRegistry.setEarningDistributionThreshold(
            token,
            earningDistributionThreshold
        );
        emit SetEarningDistributionThreshold(token, earningDistributionThreshold);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function getUniswapFeeTier(address token) external view returns (uint24) {
        return _settlementTokenRegistry.getUniswapFeeTier(token);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function setUniswapFeeTier(address token, uint24 uniswapFeeTier) external onlyDao {
        _settlementTokenRegistry.setUniswapFeeTier(token, uniswapFeeTier);
        emit SetUniswapFeeTier(token, uniswapFeeTier);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function appendInterestRateRecord(
        address token,
        uint256 annualRateBPS,
        uint256 beginTimestamp
    ) external override onlyDao {
        _settlementTokenRegistry.appendInterestRateRecord(token, annualRateBPS, beginTimestamp);
        emit InterestRateRecordAppended(token, annualRateBPS, beginTimestamp);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function removeLastInterestRateRecord(address token) external override onlyDao {
        (bool removed, InterestRate.Record memory record) = _settlementTokenRegistry
            .removeLastInterestRateRecord(token);

        if (removed) {
            emit LastInterestRateRecordRemoved(token, record.annualRateBPS, record.beginTimestamp);
        }
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function getInterestRateRecords(
        address token
    ) external view returns (InterestRate.Record[] memory) {
        return _settlementTokenRegistry.getInterestRateRecords(token);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function currentInterestRate(
        address token
    ) external view override returns (uint256 annualRateBPS) {
        return _settlementTokenRegistry.currentInterestRate(token);
    }

    // implement IInterestCalculator

    /**
     * @inheritdoc IInterestCalculator
     */
    function calculateInterest(
        address token,
        uint256 amount,
        uint256 from, // timestamp (inclusive)
        uint256 to // timestamp (exclusive)
    ) external view override returns (uint256) {
        return _settlementTokenRegistry.calculateInterest(token, amount, from, to);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/interfaces/IERC1155MetadataURI.sol";
import {ERC1155Supply, ERC1155} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {BPS} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";

/**
 * @title CLBToken
 * @dev CLBToken is an ERC1155 token contract that represents Liquidity Bin tokens.
 *      CLBToken allows minting and burning of tokens by the Chromatic Market contract.
 */
contract CLBToken is ERC1155Supply, ICLBToken {
    using Strings for uint256;
    using Strings for uint128;
    using SafeCast for uint256;
    using SignedMath for int256;

    IChromaticMarket public immutable market;

    /**
     * @dev Throws an error indicating that the caller is not a registered market.
     */
    error OnlyAccessableByMarket();

    /**
     * @dev Modifier to restrict access to the Chromatic Market contract.
     *      Only the market contract is allowed to call functions with this modifier.
     *      Reverts with an error if the caller is not the market contract.
     */
    modifier onlyMarket() {
        if (address(market) != (msg.sender)) revert OnlyAccessableByMarket();
        _;
    }

    /**
     * @dev Initializes the CLBToken contract.
     *      The constructor sets the market contract address as the caller.
     */
    constructor() ERC1155("") {
        market = IChromaticMarket(msg.sender);
    }

    /**
     * @inheritdoc ICLBToken
     */
    function decimals() public view override returns (uint8) {
        return market.settlementToken().decimals();
    }

    /**
     * @inheritdoc ICLBToken
     */
    function totalSupply(
        uint256 id
    ) public view virtual override(ERC1155Supply, ICLBToken) returns (uint256) {
        return super.totalSupply(id);
    }

    /**
     * @inheritdoc ICLBToken
     */
    function totalSupplyBatch(
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        uint256[] memory supplies = new uint256[](ids.length);
        for (uint256 i; i < ids.length; ) {
            supplies[i] = super.totalSupply(ids[i]);

            unchecked {
                i++;
            }
        }
        return supplies;
    }

    /**
     * @inheritdoc ICLBToken
     * @dev This function can only be called by the Chromatic Market contract.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override onlyMarket {
        _mint(to, id, amount, data);
    }

    /**
     * @inheritdoc ICLBToken
     * @dev This function can only be called by the Chromatic Market contract.
     */
    function burn(address from, uint256 id, uint256 amount) external override onlyMarket {
        _burn(from, id, amount);
    }

    /**
     * @inheritdoc ICLBToken
     */
    function name(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked("CLB - ", description(id)));
    }

    /**
     * @inheritdoc ICLBToken
     */
    function description(uint256 id) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _tokenSymbol(),
                    " - ",
                    _indexName(),
                    " ",
                    _formattedFeeRate(decodeId(id))
                )
            );
    }

    /**
     * @inheritdoc ICLBToken
     */
    function image(uint256 id) public view override returns (string memory) {
        int16 tradingFeeRate = decodeId(id);
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(_svg(tradingFeeRate, _tokenSymbol(), _indexName()))
                )
            );
    }

    /**
     * @inheritdoc IERC1155MetadataURI
     */
    function uri(
        uint256 id
    ) public view override(ERC1155, IERC1155MetadataURI) returns (string memory) {
        bytes memory metadata = abi.encodePacked(
            '{"name": "',
            name(id),
            '", "description": "',
            description(id),
            '", "decimals": "',
            uint256(decimals()).toString(),
            '", "image":"',
            image(id),
            '"',
            "}"
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    /**
     * @dev Decodes a token ID into a trading fee rate.
     * @param id The token ID to decode.
     * @return tradingFeeRate The decoded trading fee rate.
     */
    function decodeId(uint256 id) internal pure returns (int16 tradingFeeRate) {
        tradingFeeRate = CLBTokenLib.decodeId(id);
    }

    /**
     * @dev Retrieves the symbol of the settlement token.
     * @return The symbol of the settlement token.
     */
    function _tokenSymbol() private view returns (string memory) {
        return market.settlementToken().symbol();
    }

    /**
     * @dev Retrieves the name of the index.
     * @return The name of the index.
     */
    function _indexName() private view returns (string memory) {
        return market.oracleProvider().description();
    }

    /**
     * @dev Formats a fee rate into a human-readable string.
     * @param feeRate The fee rate to format.
     * @return The formatted fee rate as a bytes array.
     */
    function _formattedFeeRate(int16 feeRate) private pure returns (bytes memory) {
        uint256 absFeeRate = uint16(feeRate < 0 ? -(feeRate) : feeRate);

        uint256 pct = BPS / 100;
        uint256 integerPart = absFeeRate / pct;
        uint256 fractionalPart = absFeeRate % pct;

        //slither-disable-next-line uninitialized-local
        bytes memory fraction;
        if (fractionalPart != 0) {
            uint256 fractionalPart1 = fractionalPart / (pct / 10);
            uint256 fractionalPart2 = fractionalPart % (pct / 10);

            fraction = bytes(".");
            if (fractionalPart2 == 0) {
                fraction = abi.encodePacked(fraction, fractionalPart1.toString());
            } else {
                fraction = abi.encodePacked(
                    fraction,
                    fractionalPart1.toString(),
                    fractionalPart2.toString()
                );
            }
        }

        return abi.encodePacked(feeRate < 0 ? "-" : "+", integerPart.toString(), fraction, "%");
    }

    uint256 private constant _W = 480;
    uint256 private constant _H = 480;
    string private constant _WS = "480";
    string private constant _HS = "480";
    uint256 private constant _BARS = 9;

    function _svg(
        int16 feeRate,
        string memory symbol,
        string memory index
    ) private pure returns (bytes memory) {
        bytes memory formattedFeeRate = _formattedFeeRate(feeRate);
        string memory color = _color(feeRate);
        bool long = feeRate > 0;

        bytes memory text = abi.encodePacked(
            '<text class="st13 st14" font-size="64" transform="translate(440 216.852)" text-anchor="end">',
            formattedFeeRate,
            "</text>"
            '<text class="st13 st16" font-size="28" transform="translate(440 64.036)" text-anchor="end">',
            symbol,
            "</text>"
            '<path d="M104.38 40 80.74 51.59V40L63.91 52.17v47.66L80.74 112v-11.59L104.38 112zm-43.34 0L50.87 52.17v47.66L61.04 112zm-16.42 0L40 52.17v47.66L44.62 112z" class="st13" />'
            '<text class="st13 st14 st18" transform="translate(440 109.356)" text-anchor="end">',
            index,
            " Market</text>"
            '<path fill="none" stroke="#fff" stroke-miterlimit="10" d="M440 140H40" opacity=".5" />'
            '<text class="st13 st14 st18" transform="translate(40 438.578)">CLB</text>'
            '<text class="st13 st16" font-size="22" transform="translate(107.664 438.578)">Chromatic Liquidity Bin Token</text>'
            '<text class="st13 st16" font-size="16" transform="translate(54.907 390.284)">ERC-1155</text>'
            '<path fill="none" stroke="#fff" stroke-miterlimit="10" d="M132.27 399.77h-84c-4.42 0-8-3.58-8-8v-14c0-4.42 3.58-8 8-8h84c4.42 0 8 3.58 8 8v14c0 4.42-3.58 8-8 8z" />'
        );

        return
            abi.encodePacked(
                '<?xml version="1.0" encoding="utf-8"?>'
                '<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" x="0" y="0" version="1.1" viewBox="0 0 ',
                _WS,
                " ",
                _HS,
                '">'
                "<style>"
                "  .st13 {"
                "    fill: #fff"
                "  }"
                "  .st14 {"
                '    font-family: "NotoSans-Bold";'
                "  }"
                "  .st16 {"
                '    font-family: "NotoSans-Regular";'
                "  }"
                "  .st18 {"
                "    font-size: 32px"
                "  }"
                "</style>",
                _background(long),
                _bars(long, color, _activeBar(feeRate)),
                text,
                "</svg>"
            );
    }

    function _background(bool long) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<linearGradient id="bg" x1="',
                long ? "0" : _WS,
                '" x2="',
                long ? _WS : "0",
                '" y1="',
                _HS,
                '" y2="0" gradientUnits="userSpaceOnUse">',
                long
                    ? '<stop offset="0" />'
                    '<stop offset=".3" stop-color="#010302" />'
                    '<stop offset=".5" stop-color="#040b07" />'
                    '<stop offset=".6" stop-color="#0a1910" />'
                    '<stop offset=".7" stop-color="#132e1d" />'
                    '<stop offset=".8" stop-color="#1d482e" />'
                    '<stop offset=".9" stop-color="#2b6843" />'
                    '<stop offset="1" stop-color="#358153" />'
                    : '<stop offset="0" style="stop-color:#000" />'
                    '<stop offset=".3" style="stop-color:#030101" />'
                    '<stop offset=".4" style="stop-color:#0b0605" />'
                    '<stop offset=".6" style="stop-color:#190f0b" />'
                    '<stop offset=".7" style="stop-color:#2e1a13" />'
                    '<stop offset=".8" style="stop-color:#482a1f" />'
                    '<stop offset=".9" style="stop-color:#683c2c" />'
                    '<stop offset="1" style="stop-color:#8e523c" />',
                "</linearGradient>"
                '<path fill="url(#bg)" d="M0 0h',
                _WS,
                "v",
                _HS,
                'H0z" />'
            );
    }

    function _activeBar(int16 feeRate) private pure returns (uint256) {
        uint256 absFeeRate = uint16(feeRate < 0 ? -(feeRate) : feeRate);

        if (absFeeRate >= BPS / 10) {
            return (absFeeRate / (BPS / 10 / 2)) - 2;
        } else if (absFeeRate >= BPS / 100) {
            return (absFeeRate / (BPS / 100)) - 1;
        } else if (absFeeRate >= BPS / 1000) {
            return (absFeeRate / (BPS / 1000)) - 1;
        } else if (absFeeRate >= BPS / 10000) {
            return (absFeeRate / (BPS / 10000)) - 1;
        }
        return 0;
    }

    function _bars(
        bool long,
        string memory color,
        uint256 activeBar
    ) private pure returns (bytes memory bars) {
        for (uint256 i; i < _BARS; ) {
            bars = abi.encodePacked(bars, _bar(i, long, color, i == activeBar));

            unchecked {
                i++;
            }
        }
    }

    function _bar(
        uint256 barIndex,
        bool long,
        string memory color,
        bool active
    ) private pure returns (bytes memory) {
        (uint256 pos, uint256 width, uint256 height, uint256 hDelta) = _barAttributes(
            barIndex,
            long
        );

        string memory gX = _gradientX(barIndex, long);
        string memory gY = (_H - height).toString();

        bytes memory stop = abi.encodePacked(
            '<stop offset="0" stop-color="',
            color,
            '" stop-opacity="0"/>'
            '<stop offset="1" stop-color="',
            color,
            '"/>'
        );
        bytes memory path = _path(barIndex, long, pos, width, height, hDelta);
        bytes memory bar = abi.encodePacked(
            '<linearGradient id="bar',
            barIndex.toString(),
            '" x1="',
            gX,
            '" x2="',
            gX,
            '" y1="',
            gY,
            '" y2="',
            _HS,
            '" gradientUnits="userSpaceOnUse">',
            stop,
            "</linearGradient>",
            path
        );

        if (active) {
            bytes memory edge = _edge(long, pos, width, height);
            return abi.encodePacked(bar, bar, bar, edge);
        }
        return bar;
    }

    function _edge(
        bool long,
        uint256 pos,
        uint256 width,
        uint256 height
    ) private pure returns (bytes memory) {
        string memory _epos = (long ? pos + width : pos - width).toString();

        bytes memory path = abi.encodePacked(
            '<path fill="url(#edge)" d="M',
            _epos,
            " ",
            _HS,
            "h",
            long ? "-" : "",
            "2v-",
            height.toString(),
            "H",
            _epos,
            'z"/>'
        );
        return
            abi.encodePacked(
                '<linearGradient id="edge" x1="',
                _epos,
                '" x2="',
                _epos,
                '" y1="',
                _HS,
                '" y2="',
                (_H - height).toString(),
                '" gradientUnits="userSpaceOnUse">'
                '<stop offset="0" stop-color="#fff" stop-opacity="0"/>'
                '<stop offset=".5" stop-color="#fff" stop-opacity=".5"/>'
                '<stop offset="1" stop-color="#fff" stop-opacity="0"/>'
                "</linearGradient>",
                path
            );
    }

    function _path(
        uint256 barIndex,
        bool long,
        uint256 pos,
        uint256 width,
        uint256 height,
        uint256 hDelta
    ) private pure returns (bytes memory) {
        string memory _w = width.toString();
        bytes memory _h = abi.encodePacked("h", long ? "" : "-", _w);
        bytes memory _l = abi.encodePacked("l", long ? "-" : "", _w, " ", hDelta.toString());
        return
            abi.encodePacked(
                '<path fill="url(#bar',
                barIndex.toString(),
                ')" d="M',
                pos.toString(),
                " ",
                _HS,
                _h,
                "v-",
                height.toString(),
                _l,
                'z"/>'
            );
    }

    function _barAttributes(
        uint256 barIndex,
        bool long
    ) private pure returns (uint256 pos, uint256 width, uint256 height, uint256 hDelta) {
        uint256[_BARS] memory widths = [uint256(44), 45, 48, 51, 53, 55, 58, 62, 64];
        uint256[_BARS] memory heights = [uint256(480), 415, 309, 240, 185, 144, 111, 86, 67];
        uint256[_BARS] memory hDeltas = [uint256(33), 27, 19, 14, 10, 8, 5, 4, 3];

        width = widths[barIndex];
        height = heights[barIndex];
        hDelta = hDeltas[barIndex];
        pos = long ? 0 : _W;
        for (uint256 i; i < barIndex; ) {
            pos = long ? pos + widths[i] : pos - widths[i];

            unchecked {
                i++;
            }
        }
    }

    function _gradientX(uint256 barIndex, bool long) private pure returns (string memory) {
        string[_BARS] memory longXs = [
            "-1778",
            "-1733.4",
            "-1686.6",
            "-1637.4",
            "-1585.7",
            "-1531.5",
            "-1474.6",
            "-1414.8",
            "-1352"
        ];
        string[_BARS] memory shortXs = [
            "-12373.4",
            "-12328.8",
            "-12281.9",
            "-12232.8",
            "-12181.1",
            "-12126.9",
            "-12069.9",
            "-12010.1",
            "-11947.3"
        ];

        return long ? longXs[barIndex] : shortXs[barIndex];
    }

    function _color(int16 feeRate) private pure returns (string memory) {
        bool long = feeRate > 0;
        uint256 absFeeRate = uint16(feeRate < 0 ? -(feeRate) : feeRate);

        if (absFeeRate >= BPS / 10) {
            // feeRate >= 10%  or feeRate <= -10%
            return long ? "#FFCE94" : "#A0DC50";
        } else if (absFeeRate >= BPS / 100) {
            // 10% > feeRate >= 1% or -1% >= feeRate > -10%
            return long ? "#FFAB5E" : "#82E664";
        } else if (absFeeRate >= BPS / 1000) {
            // 1% > feeRate >= 0.1% or -0.1% >= feeRate > -1%
            return long ? "#FF966E" : "#5ADC8C";
        } else if (absFeeRate >= BPS / 10000) {
            // 0.1% > feeRate >= 0.01% or -0.01% >= feeRate > -0.1%
            return long ? "#FE8264" : "#3CD2AA";
        }
        // feeRate == 0%
        return "#000000";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title An interface for a contract that is capable of deploying Chromatic markets
 * @notice A contract that constructs a market must implement this to pass arguments to the market
 * @dev This is used to avoid having constructor arguments in the market contract, which results in the init code hash
 * of the market being constant allowing the CREATE2 address of the market to be cheaply computed on-chain
 */
interface IMarketDeployer {
    /**
     * @notice Get the parameters to be used in constructing the market, set transiently during market creation.
     * @dev Called by the market constructor to fetch the parameters of the market
     * Returns underlyingAsset The underlying asset of the market
     * Returns settlementToken The settlement token of the market
     * Returns vPoolCapacity Capacity of virtual future pool
     * Returns vPoolA Amplification coefficient of virtual future pool, precise value
     */
    function parameters() external view returns (address oracleProvider, address settlementToken);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IOracleProviderRegistry
 * @dev Interface for the Oracle Provider Registry contract.
 */
interface IOracleProviderRegistry {
    
    /**
     * @dev The OracleProviderProperties struct represents properties of the oracle provider.
     * @param minTakeProfitBPS The minimum take-profit basis points.
     * @param maxTakeProfitBPS The maximum take-profit basis points.
     * @param leverageLevel The leverage level of the oracle provider.
     */
    struct OracleProviderProperties {
        uint32 minTakeProfitBPS;
        uint32 maxTakeProfitBPS;
        uint8 leverageLevel;
    }

    /**
     * @dev Emitted when a new oracle provider is registered.
     * @param oracleProvider The address of the registered oracle provider.
     * @param properties The properties of the registered oracle provider.
     */
    event OracleProviderRegistered(
        address indexed oracleProvider,
        OracleProviderProperties properties
    );

    /**
     * @dev Emitted when an oracle provider is unregistered.
     * @param oracleProvider The address of the unregistered oracle provider.
     */
    event OracleProviderUnregistered(address indexed oracleProvider);

    /**
     * @dev Emitted when the take-profit basis points range of an oracle provider is updated.
     * @param oracleProvider The address of the oracle provider.
     * @param minTakeProfitBPS The new minimum take-profit basis points.
     * @param maxTakeProfitBPS The new maximum take-profit basis points.
     */
    event UpdateTakeProfitBPSRange(
        address indexed oracleProvider,
        uint32 indexed minTakeProfitBPS,
        uint32 indexed maxTakeProfitBPS
    );

    /**
     * @dev Emitted when the level of an oracle provider is set.
     * @param oracleProvider The address of the oracle provider.
     * @param level The new level set for the oracle provider.
     */
    event UpdateLeverageLevel(address indexed oracleProvider, uint8 indexed level);

    /**
     * @notice Registers an oracle provider.
     * @param oracleProvider The address of the oracle provider to register.
     * @param properties The properties of the oracle provider.
     */
    function registerOracleProvider(
        address oracleProvider,
        OracleProviderProperties memory properties
    ) external;

    /**
     * @notice Unregisters an oracle provider.
     * @param oracleProvider The address of the oracle provider to unregister.
     */
    function unregisterOracleProvider(address oracleProvider) external;

    /**
     * @notice Gets the registered oracle providers.
     * @return An array of registered oracle provider addresses.
     */
    function registeredOracleProviders() external view returns (address[] memory);

    /**
     * @notice Checks if an oracle provider is registered.
     * @param oracleProvider The address of the oracle provider to check.
     * @return A boolean indicating if the oracle provider is registered.
     */
    function isRegisteredOracleProvider(address oracleProvider) external view returns (bool);

    /**
     * @notice Retrieves the properties of an oracle provider.
     * @param oracleProvider The address of the oracle provider.
     * @return The properties of the oracle provider.
     */
    function getOracleProviderProperties(
        address oracleProvider
    ) external view returns (OracleProviderProperties memory);

    /**
     * @notice Updates the take-profit basis points range of an oracle provider.
     * @param oracleProvider The address of the oracle provider.
     * @param minTakeProfitBPS The new minimum take-profit basis points.
     * @param maxTakeProfitBPS The new maximum take-profit basis points.
     */
    function updateTakeProfitBPSRange(
        address oracleProvider,
        uint32 minTakeProfitBPS,
        uint32 maxTakeProfitBPS
    ) external;

    /**
     * @notice Updates the leverage level of an oracle provider in the registry.
     * @dev The level must be either 0 or 1, and the max leverage must be x10 for level 0 or x20 for level 1.
     * @param oracleProvider The address of the oracle provider.
     * @param level The new leverage level to be set for the oracle provider.
     */
    function updateLeverageLevel(address oracleProvider, uint8 level) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {InterestRate} from "@chromatic-protocol/contracts/core/libraries/InterestRate.sol";

/**
 * @title ISettlementTokenRegistry
 * @dev Interface for the Settlement Token Registry contract.
 */
interface ISettlementTokenRegistry {
    /**
     * @dev Emitted when a new settlement token is registered.
     * @param token The address of the registered settlement token.
     * @param minimumMargin The minimum margin for the markets using this settlement token.
     * @param interestRate The interest rate for the settlement token.
     * @param flashLoanFeeRate The flash loan fee rate for the settlement token.
     * @param earningDistributionThreshold The earning distribution threshold for the settlement token.
     * @param uniswapFeeTier The Uniswap fee tier for the settlement token.
     */
    event SettlementTokenRegistered(
        address indexed token,
        uint256 indexed minimumMargin,
        uint256 indexed interestRate,
        uint256 flashLoanFeeRate,
        uint256 earningDistributionThreshold,
        uint24 uniswapFeeTier
    );

    /**
     * @dev Emitted when the minimum margin for a settlement token is set.
     * @param token The address of the settlement token.
     * @param minimumMargin The new minimum margin for the settlement token.
     */
    event SetMinimumMargin(address indexed token, uint256 indexed minimumMargin);

    /**
     * @dev Emitted when the flash loan fee rate for a settlement token is set.
     * @param token The address of the settlement token.
     * @param flashLoanFeeRate The new flash loan fee rate for the settlement token.
     */
    event SetFlashLoanFeeRate(address indexed token, uint256 indexed flashLoanFeeRate);

    /**
     * @dev Emitted when the earning distribution threshold for a settlement token is set.
     * @param token The address of the settlement token.
     * @param earningDistributionThreshold The new earning distribution threshold for the settlement token.
     */
    event SetEarningDistributionThreshold(
        address indexed token,
        uint256 indexed earningDistributionThreshold
    );

    /**
     * @dev Emitted when the Uniswap fee tier for a settlement token is set.
     * @param token The address of the settlement token.
     * @param uniswapFeeTier The new Uniswap fee tier for the settlement token.
     */
    event SetUniswapFeeTier(address indexed token, uint24 indexed uniswapFeeTier);

    /**
     * @dev Emitted when an interest rate record is appended for a settlement token.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points (BPS).
     * @param beginTimestamp The timestamp when the interest rate record begins.
     */
    event InterestRateRecordAppended(
        address indexed token,
        uint256 indexed annualRateBPS,
        uint256 indexed beginTimestamp
    );

    /**
     * @dev Emitted when the last interest rate record is removed for a settlement token.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points (BPS).
     * @param beginTimestamp The timestamp when the interest rate record begins.
     */
    event LastInterestRateRecordRemoved(
        address indexed token,
        uint256 indexed annualRateBPS,
        uint256 indexed beginTimestamp
    );

    /**
     * @notice Registers a new settlement token.
     * @param token The address of the settlement token to register.
     * @param minimumMargin The minimum margin for the settlement token.
     * @param interestRate The interest rate for the settlement token.
     * @param flashLoanFeeRate The flash loan fee rate for the settlement token.
     * @param earningDistributionThreshold The earning distribution threshold for the settlement token.
     * @param uniswapFeeTier The Uniswap fee tier for the settlement token.
     */
    function registerSettlementToken(
        address token,
        uint256 minimumMargin,
        uint256 interestRate,
        uint256 flashLoanFeeRate,
        uint256 earningDistributionThreshold,
        uint24 uniswapFeeTier
    ) external;

    /**
     * @notice Gets the list of registered settlement tokens.
     * @return An array of addresses representing the registered settlement tokens.
     */
    function registeredSettlementTokens() external view returns (address[] memory);

    /**
     * @notice Checks if a settlement token is registered.
     * @param token The address of the settlement token to check.
     * @return True if the settlement token is registered, false otherwise.
     */
    function isRegisteredSettlementToken(address token) external view returns (bool);

    /**
     * @notice Gets the minimum margin for a settlement token.
     * @dev The minimumMargin is used as the minimum value for the taker margin of a position
     *      or as the minimum value for the maker margin of each bin.
     * @param token The address of the settlement token.
     * @return The minimum margin for the settlement token.
     */
    function getMinimumMargin(address token) external view returns (uint256);

    /**
     * @notice Sets the minimum margin for a settlement token.
     * @param token The address of the settlement token.
     * @param minimumMargin The new minimum margin for the settlement token.
     */
    function setMinimumMargin(address token, uint256 minimumMargin) external;

    /**
     * @notice Gets the flash loan fee rate for a settlement token.
     * @param token The address of the settlement token.
     * @return The flash loan fee rate for the settlement token.
     */
    function getFlashLoanFeeRate(address token) external view returns (uint256);

    /**
     * @notice Sets the flash loan fee rate for a settlement token.
     * @param token The address of the settlement token.
     * @param flashLoanFeeRate The new flash loan fee rate for the settlement token.
     */
    function setFlashLoanFeeRate(address token, uint256 flashLoanFeeRate) external;

    /**
     * @notice Gets the earning distribution threshold for a settlement token.
     * @param token The address of the settlement token.
     * @return The earning distribution threshold for the settlement token.
     */
    function getEarningDistributionThreshold(address token) external view returns (uint256);

    /**
     * @notice Sets the earning distribution threshold for a settlement token.
     * @param token The address of the settlement token.
     * @param earningDistributionThreshold The new earning distribution threshold for the settlement token.
     */
    function setEarningDistributionThreshold(
        address token,
        uint256 earningDistributionThreshold
    ) external;

    /**
     * @notice Gets the Uniswap fee tier for a settlement token.
     * @param token The address of the settlement token.
     * @return The Uniswap fee tier for the settlement token.
     */
    function getUniswapFeeTier(address token) external view returns (uint24);

    /**
     * @notice Sets the Uniswap fee tier for a settlement token.
     * @param token The address of the settlement token.
     * @param uniswapFeeTier The new Uniswap fee tier for the settlement token.
     */
    function setUniswapFeeTier(address token, uint24 uniswapFeeTier) external;

    /**
     * @notice Appends an interest rate record for a settlement token.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points (BPS).
     * @param beginTimestamp The timestamp when the interest rate record begins.
     */
    function appendInterestRateRecord(
        address token,
        uint256 annualRateBPS,
        uint256 beginTimestamp
    ) external;

    /**
     * @notice Removes the last interest rate record for a settlement token.
     * @param token The address of the settlement token.
     */
    function removeLastInterestRateRecord(address token) external;

    /**
     * @notice Gets the current interest rate for a settlement token.
     * @param token The address of the settlement token.
     * @return The current interest rate for the settlement token.
     */
    function currentInterestRate(address token) external view returns (uint256);

    /**
     * @notice Gets all the interest rate records for a settlement token.
     * @param token The address of the settlement token.
     * @return An array of interest rate records for the settlement token.
     */
    function getInterestRateRecords(
        address token
    ) external view returns (InterestRate.Record[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IChromaticLiquidator
 * @dev Interface for the Chromatic Liquidator contract.
 */
interface IChromaticLiquidator {
    /**
     * @notice Emitted when the liquidation task interval is updated.
     * @param interval The new liquidation task interval.
     */
    event UpdateLiquidationInterval(uint256 indexed interval);

    /**
     * @notice Emitted when the claim task interval is updated.
     * @param interval The new claim task interval.
     */
    event UpdateClaimInterval(uint256 indexed interval);

    /**
     * @notice Updates the liquidation task interval.
     * @param interval The new liquidation task interval.
     */
    function updateLiquidationInterval(uint256 interval) external;

    /**
     * @notice Updates the claim task interval.
     * @param interval The new claim task interval.
     */
    function updateClaimInterval(uint256 interval) external;

    /**
     * @notice Creates a liquidation task for a given position.
     * @param positionId The ID of the position to be liquidated.
     */
    function createLiquidationTask(uint256 positionId) external;

    /**
     * @notice Cancels a liquidation task for a given position.
     * @param positionId The ID of the position for which to cancel the liquidation task.
     */
    function cancelLiquidationTask(uint256 positionId) external;

    /**
     * @notice Resolves the liquidation of a position.
     * @dev This function is called by the Gelato automation system.
     * @param market The address of the market contract.
     * @param positionId The ID of the position to be liquidated.
     * @return canExec Whether the liquidation can be executed.
     * @return execPayload The encoded function call to execute the liquidation.
     */
    function resolveLiquidation(
        address market,
        uint256 positionId
    ) external view returns (bool canExec, bytes memory execPayload);

    /**
     * @notice Liquidates a position in a market.
     * @param market The address of the market contract.
     * @param positionId The ID of the position to be liquidated.
     */
    function liquidate(address market, uint256 positionId) external;

    /**
     * @notice Creates a claim position task for a given position.
     * @param positionId The ID of the position to be claimed.
     */
    function createClaimPositionTask(uint256 positionId) external;

    /**
     * @notice Cancels a claim position task for a given position.
     * @param positionId The ID of the position for which to cancel the claim position task.
     */
    function cancelClaimPositionTask(uint256 positionId) external;

    /**
     * @notice Resolves the claim of a position.
     * @dev This function is called by the Gelato automation system.
     * @param market The address of the market contract.
     * @param positionId The ID of the position to be claimed.
     * @return canExec Whether the claim can be executed.
     * @return execPayload The encoded function call to execute the claim.
     */
    function resolveClaimPosition(
        address market,
        uint256 positionId
    ) external view returns (bool canExec, bytes memory execPayload);

    /**
     * @notice Claims a position in a market.
     * @param market The address of the market contract.
     * @param positionId The ID of the position to be claimed.
     */
    function claimPosition(address market, uint256 positionId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IMarketTrade} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketTrade.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {IMarketLiquidityLens} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidityLens.sol";
import {IMarketState} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketState.sol";
import {IMarketLiquidate} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidate.sol";
import {IMarketSettle} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketSettle.sol";

/**
 * @title IChromaticMarket
 * @dev Interface for the Chromatic Market contract, which combines trade and liquidity functionalities.
 */
interface IChromaticMarket is
    IMarketTrade,
    IMarketLiquidity,
    IMarketLiquidityLens,
    IMarketState,
    IMarketLiquidate,
    IMarketSettle
{

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IInterestCalculator} from "@chromatic-protocol/contracts/core/interfaces/IInterestCalculator.sol";
import {IMarketDeployer} from "@chromatic-protocol/contracts/core/interfaces/factory/IMarketDeployer.sol";
import {ISettlementTokenRegistry} from "@chromatic-protocol/contracts/core/interfaces/factory/ISettlementTokenRegistry.sol";
import {IOracleProviderRegistry} from "@chromatic-protocol/contracts/core/interfaces/factory/IOracleProviderRegistry.sol";

/**
 * @title IChromaticMarketFactory
 * @dev Interface for the Chromatic Market Factory contract.
 */
interface IChromaticMarketFactory is
    IMarketDeployer,
    IOracleProviderRegistry,
    ISettlementTokenRegistry,
    IInterestCalculator
{
    /**
     * @notice Emitted when the DAO address is updated.
     * @param dao The new DAO address.
     */
    event UpdateDao(address indexed dao);

    /**
     * @notice Emitted when the DAO treasury address is updated.
     * @param treasury The new DAO treasury address.
     */
    event UpdateTreasury(address indexed treasury);

    /**
     * @notice Emitted when the liquidator address is set.
     * @param liquidator The liquidator address.
     */
    event SetLiquidator(address indexed liquidator);

    /**
     * @notice Emitted when the vault address is set.
     * @param vault The vault address.
     */
    event SetVault(address indexed vault);

    /**
     * @notice Emitted when the keeper fee payer address is set.
     * @param keeperFeePayer The keeper fee payer address.
     */
    event SetKeeperFeePayer(address indexed keeperFeePayer);

    /**
     * @notice Emitted when a market is created.
     * @param oracleProvider The address of the oracle provider.
     * @param settlementToken The address of the settlement token.
     * @param market The address of the created market.
     */
    event MarketCreated(
        address indexed oracleProvider,
        address indexed settlementToken,
        address indexed market
    );

    /**
     * @notice Returns the address of the DAO.
     * @return The address of the DAO.
     */
    function dao() external view returns (address);

    /**
     * @notice Returns the address of the DAO treasury.
     * @return The address of the DAO treasury.
     */
    function treasury() external view returns (address);

    /**
     * @notice Returns the address of the liquidator.
     * @return The address of the liquidator.
     */
    function liquidator() external view returns (address);

    /**
     * @notice Returns the address of the vault.
     * @return The address of the vault.
     */
    function vault() external view returns (address);

    /**
     * @notice Returns the address of the keeper fee payer.
     * @return The address of the keeper fee payer.
     */
    function keeperFeePayer() external view returns (address);

    /**
     * @notice Updates the DAO address.
     * @param _dao The new DAO address.
     */
    function updateDao(address _dao) external;

    /**
     * @notice Updates the DAO treasury address.
     * @param _treasury The new DAO treasury address.
     */
    function updateTreasury(address _treasury) external;

    /**
     * @notice Sets the liquidator address.
     * @param _liquidator The liquidator address.
     */
    function setLiquidator(address _liquidator) external;

    /**
     * @notice Sets the vault address.
     * @param _vault The vault address.
     */
    function setVault(address _vault) external;

    /**
     * @notice Sets the keeper fee payer address.
     * @param _keeperFeePayer The keeper fee payer address.
     */
    function setKeeperFeePayer(address _keeperFeePayer) external;

    /**
     * @notice Returns an array of all market addresses.
     * @return markets An array of all market addresses.
     */
    function getMarkets() external view returns (address[] memory markets);

    /**
     * @notice Returns an array of market addresses associated with a settlement token.
     * @param settlementToken The address of the settlement token.
     * @return An array of market addresses.
     */
    function getMarketsBySettlmentToken(
        address settlementToken
    ) external view returns (address[] memory);

    /**
     * @notice Returns the address of a market associated with an oracle provider and settlement token.
     * @param oracleProvider The address of the oracle provider.
     * @param settlementToken The address of the settlement token.
     * @return The address of the market.
     */
    function getMarket(
        address oracleProvider,
        address settlementToken
    ) external view returns (address);

    /**
     * @notice Creates a new market associated with an oracle provider and settlement token.
     * @param oracleProvider The address of the oracle provider.
     * @param settlementToken The address of the settlement token.
     */
    function createMarket(address oracleProvider, address settlementToken) external;

    /**
     * @notice Checks if a market is registered.
     * @param market The address of the market.
     * @return True if the market is registered, false otherwise.
     */
    function isRegisteredMarket(address market) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {ILendingPool} from "@chromatic-protocol/contracts/core/interfaces/vault/ILendingPool.sol";
import {IVault} from "@chromatic-protocol/contracts/core/interfaces/vault/IVault.sol";

/**
 * @title IChromaticVault
 * @notice Interface for the Chromatic Vault contract.
 */
interface IChromaticVault is IVault, ILendingPool {
    /**
     * @dev Emitted when market earning is accumulated.
     * @param market The address of the market.
     * @param earning The amount of earning accumulated.
     */
    event MarketEarningAccumulated(address indexed market, uint256 earning);

    /**
     * @dev Emitted when maker earning is distributed.
     * @param token The address of the settlement token.
     * @param earning The amount of earning distributed.
     * @param usedKeeperFee The amount of keeper fee used.
     */
    event MakerEarningDistributed(
        address indexed token,
        uint256 indexed earning,
        uint256 indexed usedKeeperFee
    );

    /**
     * @dev Emitted when market earning is distributed.
     * @param market The address of the market.
     * @param earning The amount of earning distributed.
     * @param usedKeeperFee The amount of keeper fee used.
     * @param marketBalance The balance of the market.
     */
    event MarketEarningDistributed(
        address indexed market,
        uint256 indexed earning,
        uint256 indexed usedKeeperFee,
        uint256 marketBalance
    );

    /**
     * @notice Creates a maker earning distribution task for a token.
     * @param token The address of the settlement token.
     */
    function createMakerEarningDistributionTask(address token) external;

    /**
     * @notice Cancels a maker earning distribution task for a token.
     * @param token The address of the settlement token.
     */
    function cancelMakerEarningDistributionTask(address token) external;

    /**
     * @notice Creates a market earning distribution task for a market.
     * @param market The address of the market.
     */
    function createMarketEarningDistributionTask(address market) external;

    /**
     * @notice Cancels a market earning distribution task for a market.
     * @param market The address of the market.
     */
    function cancelMarketEarningDistributionTask(address market) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/interfaces/IERC1155MetadataURI.sol";

/**
 * @title ICLBToken
 * @dev Interface for CLBToken contract, which represents Liquidity Bin tokens.
 */
interface ICLBToken is IERC1155, IERC1155MetadataURI {
    /**
     * @dev Total amount of tokens in with a given id.
     * @param id The token ID for which to retrieve the total supply.
     * @return The total supply of tokens for the given token ID.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Total amounts of tokens in with the given ids.
     * @param ids The token IDs for which to retrieve the total supply.
     * @return The total supples of tokens for the given token IDs.
     */
    function totalSupplyBatch(uint256[] memory ids) external view returns (uint256[] memory);

    /**
     * @dev Mints new tokens and assigns them to the specified address.
     * @param to The address to which the minted tokens will be assigned.
     * @param id The token ID to mint.
     * @param amount The amount of tokens to mint.
     * @param data Additional data to pass during the minting process.
     */
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev Burns tokens from a specified address.
     * @param from The address from which to burn tokens.
     * @param id The token ID to burn.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 id, uint256 amount) external;

    /**
     * @dev Retrieves the number of decimals used for token amounts.
     * @return The number of decimals used for token amounts.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Retrieves the name of a token.
     * @param id The token ID for which to retrieve the name.
     * @return The name of the token.
     */
    function name(uint256 id) external view returns (string memory);

    /**
     * @dev Retrieves the description of a token.
     * @param id The token ID for which to retrieve the description.
     * @return The description of the token.
     */
    function description(uint256 id) external view returns (string memory);

    /**
     * @dev Retrieves the image URI of a token.
     * @param id The token ID for which to retrieve the image URI.
     * @return The image URI of the token.
     */
    function image(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IInterestCalculator
 * @dev Interface for an interest calculator contract.
 */
interface IInterestCalculator {
    /**
     * @notice Calculates the interest accrued for a given token and amount within a specified time range.
     * @param token The address of the token.
     * @param amount The amount of the token.
     * @param from The starting timestamp (inclusive) of the time range.
     * @param to The ending timestamp (exclusive) of the time range.
     * @return The accrued interest for the specified token and amount within the given time range.
     */
    function calculateInterest(
        address token,
        uint256 amount,
        uint256 from, // timestamp (inclusive)
        uint256 to // timestamp (exclusive)
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IKeeperFeePayer
 * @dev Interface for a contract that pays keeper fees.
 */
interface IKeeperFeePayer {
    event SetRouter(address indexed);

    /**
     * @notice Approves or revokes approval to the Uniswap router for a given token.
     * @param token The address of the token.
     * @param approve A boolean indicating whether to approve or revoke approval.
     */
    function approveToRouter(address token, bool approve) external;

    /**
     * @notice Pays the keeper fee using Uniswap swaps.
     * @param tokenIn The address of the token being swapped.
     * @param amountOut The desired amount of output tokens.
     * @param keeperAddress The address of the keeper to receive the fee.
     * @return amountIn The actual amount of input tokens used for the swap.
     */
    function payKeeperFee(
        address tokenIn,
        uint256 amountOut,
        address keeperAddress
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";

/**
 * @title IMarketLiquidate
 * @dev Interface for liquidating and claiming positions in a market.
 */
interface IMarketLiquidate {
    /**
     * @dev Emitted when a position is claimed by keeper.
     * @param account The address of the account claiming the position.
     * @param pnl The profit or loss of the claimed position.
     * @param interest The interest paid for the claimed position.
     * @param usedKeeperFee The amount of keeper fee used for the liquidation.
     * @param position The claimed position.
     */
    event ClaimPositionByKeeper(
        address indexed account,
        int256 indexed pnl,
        uint256 indexed interest,
        uint256 usedKeeperFee,
        Position position
    );

    /**
     * @dev Emitted when a position is liquidated.
     * @param account The address of the account being liquidated.
     * @param pnl The profit or loss of the claimed position.
     * @param interest The interest paid for the claimed position.
     * @param usedKeeperFee The amount of keeper fee used for the liquidation.
     * @param position The liquidated position.
     */
    event Liquidate(
        address indexed account,
        int256 indexed pnl,
        uint256 indexed interest,
        uint256 usedKeeperFee,
        Position position
    );

    /**
     * @dev Checks if a position is eligible for liquidation.
     * @param positionId The ID of the position to check.
     * @return A boolean indicating if the position is eligible for liquidation.
     */
    function checkLiquidation(uint256 positionId) external view returns (bool);

    /**
     * @dev Liquidates a position.
     * @param positionId The ID of the position to liquidate.
     * @param keeper The address of the keeper performing the liquidation.
     * @param keeperFee The native token amount of the keeper's fee.
     */
    function liquidate(uint256 positionId, address keeper, uint256 keeperFee) external;

    /**
     * @dev Checks if a position is eligible for claim.
     * @param positionId The ID of the position to check.
     * @return A boolean indicating if the position is eligible for claim.
     */
    function checkClaimPosition(uint256 positionId) external view returns (bool);

    /**
     * @dev Claims a closed position on behalf of a keeper.
     * @param positionId The ID of the position to claim.
     * @param keeper The address of the keeper claiming the position.
     * @param keeperFee The native token amount of the keeper's fee.
     */
    function claimPosition(uint256 positionId, address keeper, uint256 keeperFee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";

/**
 * @title IMarketLiquidity
 * @dev The interface for liquidity operations in a market.
 */
interface IMarketLiquidity {
    /**
     * @dev A struct representing pending liquidity information.
     * @param oracleVersion The oracle version of pending liqudity.
     * @param mintingTokenAmountRequested The amount of settlement tokens requested for minting.
     * @param burningCLBTokenAmountRequested The amount of CLB tokens requested for burning.
     */
    struct PendingLiquidity {
        uint256 oracleVersion;
        uint256 mintingTokenAmountRequested;
        uint256 burningCLBTokenAmountRequested;
    }

    /**
     * @dev A struct representing claimable liquidity information.
     * @param mintingTokenAmountRequested The amount of settlement tokens requested for minting.
     * @param mintingCLBTokenAmount The actual amount of CLB tokens minted.
     * @param burningCLBTokenAmountRequested The amount of CLB tokens requested for burning.
     * @param burningCLBTokenAmount The actual amount of CLB tokens burned.
     * @param burningTokenAmount The amount of settlement tokens equal in value to the burned CLB tokens.
     */
    struct ClaimableLiquidity {
        uint256 mintingTokenAmountRequested;
        uint256 mintingCLBTokenAmount;
        uint256 burningCLBTokenAmountRequested;
        uint256 burningCLBTokenAmount;
        uint256 burningTokenAmount;
    }

    /**
     * @dev A struct representing status of the liquidity bin.
     * @param liquidity The total liquidity amount in the bin
     * @param freeLiquidity The amount of free liquidity available in the bin.
     * @param binValue The current value of the bin.
     * @param tradingFeeRate The trading fee rate for the liquidity.
     */
    struct LiquidityBinStatus {
        uint256 liquidity;
        uint256 freeLiquidity;
        uint256 binValue;
        int16 tradingFeeRate;
    }

    /**
     * @dev Emitted when liquidity is added to the market.
     * @param receipt The liquidity receipt.
     */
    event AddLiquidity(LpReceipt receipt);

    /**
     * @dev Emitted when liquidity is added to the market.
     * @param receipts An array of LP receipts.
     */
    event AddLiquidityBatch(LpReceipt[] receipts);

    /**
     * @dev Emitted when liquidity is claimed from the market.
     * @param clbTokenAmount The amount of CLB tokens claimed.
     * @param receipt The liquidity receipt.
     */
    event ClaimLiquidity(LpReceipt receipt, uint256 indexed clbTokenAmount);

    /**
     * @dev Emitted when liquidity is claimed from the market.
     * @param receipts An array of LP receipts.
     * @param clbTokenAmounts The amount list of CLB tokens claimed.
     */
    event ClaimLiquidityBatch(LpReceipt[] receipts, uint256[] clbTokenAmounts);

    /**
     * @dev Emitted when liquidity is removed from the market.
     * @param receipt The liquidity receipt.
     */
    event RemoveLiquidity(LpReceipt receipt);

    /**
     * @dev Emitted when liquidity is removed from the market.
     * @param receipts An array of LP receipts.
     */
    event RemoveLiquidityBatch(LpReceipt[] receipts);

    /**
     * @dev Emitted when liquidity is withdrawn from the market.
     * @param receipt The liquidity receipt.
     * @param amount The amount of liquidity withdrawn.
     * @param burnedCLBTokenAmount The amount of burned CLB tokens.
     */
    event WithdrawLiquidity(
        LpReceipt receipt,
        uint256 indexed amount,
        uint256 indexed burnedCLBTokenAmount
    );

    /**
     * @dev Emitted when liquidity is withdrawn from the market.
     * @param receipts An array of LP receipts.
     * @param amounts The amount list of liquidity withdrawn.
     * @param burnedCLBTokenAmounts The amount list of burned CLB tokens.
     */
    event WithdrawLiquidityBatch(
        LpReceipt[] receipts,
        uint256[] amounts,
        uint256[] burnedCLBTokenAmounts
    );

    /**
     * @dev Adds liquidity to the market.
     * @param recipient The address to receive the liquidity tokens.
     * @param tradingFeeRate The trading fee rate for the liquidity.
     * @param data Additional data for the liquidity callback.
     * @return The liquidity receipt.
     */
    function addLiquidity(
        address recipient,
        int16 tradingFeeRate,
        bytes calldata data
    ) external returns (LpReceipt memory);

    /**
     * @notice Adds liquidity to multiple liquidity bins of the market in a batch.
     * @param recipient The address of the recipient for each liquidity bin.
     * @param tradingFeeRates An array of fee rates for each liquidity bin.
     * @param amounts An array of amounts to add as liquidity for each bin.
     * @param data Additional data for the liquidity callback.
     * @return An array of LP receipts.
     */
    function addLiquidityBatch(
        address recipient,
        int16[] calldata tradingFeeRates,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (LpReceipt[] memory);

    /**
     * @dev Claims liquidity from a liquidity receipt.
     * @param receiptId The ID of the liquidity receipt.
     * @param data Additional data for the liquidity callback.
     */
    function claimLiquidity(uint256 receiptId, bytes calldata data) external;

    /**
     * @dev Claims liquidity from a liquidity receipt.
     * @param receiptIds The array of the liquidity receipt IDs.
     * @param data Additional data for the liquidity callback.
     */
    function claimLiquidityBatch(uint256[] calldata receiptIds, bytes calldata data) external;

    /**
     * @dev Removes liquidity from the market.
     * @param recipient The address to receive the removed liquidity.
     * @param tradingFeeRate The trading fee rate for the liquidity.
     * @param data Additional data for the liquidity callback.
     * @return The liquidity receipt.
     */
    function removeLiquidity(
        address recipient,
        int16 tradingFeeRate,
        bytes calldata data
    ) external returns (LpReceipt memory);

    /**
     * @dev Removes liquidity from the market.
     * @param recipient The address to receive the removed liquidity.
     * @param tradingFeeRates An array of fee rates for each liquidity bin.
     * @param clbTokenAmounts An array of clb token amounts to remove as liquidity for each bin.
     * @param data Additional data for the liquidity callback.
     * @return The liquidity receipt.
     */
    function removeLiquidityBatch(
        address recipient,
        int16[] calldata tradingFeeRates,
        uint256[] calldata clbTokenAmounts,
        bytes calldata data
    ) external returns (LpReceipt[] memory);

    /**
     * @dev Withdraws liquidity from a liquidity receipt.
     * @param receiptId The ID of the liquidity receipt.
     * @param data Additional data for the liquidity callback.
     */
    function withdrawLiquidity(uint256 receiptId, bytes calldata data) external;

    /**
     * @dev Withdraws liquidity from a liquidity receipt.
     * @param receiptIds The array of the liquidity receipt IDs.
     * @param data Additional data for the liquidity callback.
     */
    function withdrawLiquidityBatch(uint256[] calldata receiptIds, bytes calldata data) external;

    /**
     * @dev Distributes earning to the liquidity bins.
     * @param earning The amount of earning to distribute.
     * @param marketBalance The balance of the market.
     */
    function distributeEarningToBins(uint256 earning, uint256 marketBalance) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";

/**
 * @title IMarketLiquidityLens
 * @dev The interface for liquidity information retrieval in a market.
 */
interface IMarketLiquidityLens {
    /**
     * @dev Retrieves the total liquidity amount for a specific trading fee rate in the liquidity pool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the liquidity amount.
     * @return amount The total liquidity amount for the specified trading fee rate.
     */
    function getBinLiquidity(int16 tradingFeeRate) external view returns (uint256 amount);

    /**
     * @dev Retrieves the available (free) liquidity amount for a specific trading fee rate in the liquidity pool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the available liquidity amount.
     * @return amount The available (free) liquidity amount for the specified trading fee rate.
     */
    function getBinFreeLiquidity(int16 tradingFeeRate) external view returns (uint256 amount);

    /**
     * @dev Retrieves the values of a specific trading fee rate's bins in the liquidity pool.
     *      The value of a bin represents the total valuation of the liquidity in the bin.
     * @param tradingFeeRates The list of trading fee rate for which to retrieve the bin value.
     * @return values The value list of the bins for the specified trading fee rates.
     */
    function getBinValues(
        int16[] memory tradingFeeRates
    ) external view returns (uint256[] memory values);

    /**
     * @dev Retrieves the liquidity receipt with the given receipt ID.
     *      It throws NotExistLpReceipt if the specified receipt ID does not exist.
     * @param receiptId The ID of the liquidity receipt to retrieve.
     * @return receipt The liquidity receipt with the specified ID.
     */
    function getLpReceipt(uint256 receiptId) external view returns (LpReceipt memory);

    /**
     * @dev Retrieves the pending liquidity information for a specific trading fee rate from the associated LiquidityPool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the pending liquidity.
     * @return pendingLiquidity An instance of PendingLiquidity representing the pending liquidity information.
     */
    function pendingLiquidity(
        int16 tradingFeeRate
    ) external view returns (IMarketLiquidity.PendingLiquidity memory);

    /**
     * @dev Retrieves the pending liquidity information for multiple trading fee rates from the associated LiquidityPool.
     * @param tradingFeeRates The list of trading fee rates for which to retrieve the pending liquidity.
     * @return pendingLiquidityBatch An array of PendingLiquidity instances representing the pending liquidity information for each trading fee rate.
     */
    function pendingLiquidityBatch(
        int16[] calldata tradingFeeRates
    ) external view returns (IMarketLiquidity.PendingLiquidity[] memory);

    /**
     * @dev Retrieves the claimable liquidity information for a specific trading fee rate and oracle version from the associated LiquidityPool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the claimable liquidity.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        int16 tradingFeeRate,
        uint256 oracleVersion
    ) external view returns (IMarketLiquidity.ClaimableLiquidity memory);

    /**
     * @dev Retrieves the claimable liquidity information for multiple trading fee rates and a specific oracle version from the associated LiquidityPool.
     * @param tradingFeeRates The list of trading fee rates for which to retrieve the claimable liquidity.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidityBatch An array of ClaimableLiquidity instances representing the claimable liquidity information for each trading fee rate.
     */
    function claimableLiquidityBatch(
        int16[] calldata tradingFeeRates,
        uint256 oracleVersion
    ) external view returns (IMarketLiquidity.ClaimableLiquidity[] memory);

    /**
     * @dev Retrieves the liquidity bin statuses for the caller's liquidity pool.
     * @return statuses An array of LiquidityBinStatus representing the liquidity bin statuses.
     */
    function liquidityBinStatuses()
        external
        view
        returns (IMarketLiquidity.LiquidityBinStatus[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IMarketSettle
 * @dev Interface for market settlement.
 */
interface IMarketSettle {
    /**
     * @notice Executes the settlement process for the Chromatic market.
     * @dev This function is called to settle the market.
     */
    function settle() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IChromaticLiquidator} from "@chromatic-protocol/contracts/core/interfaces/IChromaticLiquidator.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";

/**
 * @title IMarketState
 * @dev Interface for accessing the state of a market contract.
 */
interface IMarketState {
    /**
     * @notice Emitted when the protocol fee is changed by the market
     * @param feeProtocolOld The previous value of the protocol fee
     * @param feeProtocolNew The updated value of the protocol fee
     */
    event SetFeeProtocol(uint8 feeProtocolOld, uint8 feeProtocolNew);

    /**
     * @dev Returns the factory contract for the market.
     * @return The factory contract.
     */
    function factory() external view returns (IChromaticMarketFactory);

    /**
     * @dev Returns the settlement token of the market.
     * @return The settlement token.
     */
    function settlementToken() external view returns (IERC20Metadata);

    /**
     * @dev Returns the oracle provider contract for the market.
     * @return The oracle provider contract.
     */
    function oracleProvider() external view returns (IOracleProvider);

    /**
     * @dev Returns the CLB token contract for the market.
     * @return The CLB token contract.
     */
    function clbToken() external view returns (ICLBToken);

    /**
     * @dev Returns the liquidator contract for the market.
     * @return The liquidator contract.
     */
    function liquidator() external view returns (IChromaticLiquidator);

    /**
     * @dev Returns the vault contract for the market.
     * @return The vault contract.
     */
    function vault() external view returns (IChromaticVault);

    /**
     * @dev Returns the keeper fee payer contract for the market.
     * @return The keeper fee payer contract.
     */
    function keeperFeePayer() external view returns (IKeeperFeePayer);

    /**
     * @notice Returns the denominator of the protocol's % share of the fees
     * @return The protocol fee for the market
     */
    function feeProtocol() external view returns (uint8);

    /**
     * @notice Set the denominator of the protocol's % share of the fees
     * @param _feeProtocol new protocol fee for the market
     */
    function setFeeProtocol(uint8 _feeProtocol) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";

/**
 * @title IMarketTrade
 * @dev Interface for trading positions in a market.
 */
interface IMarketTrade {
    /**
     * @dev Emitted when a position is opened.
     * @param account The address of the account opening the position.
     * @param position The opened position.
     */
    event OpenPosition(address indexed account, Position position);

    /**
     * @dev Emitted when a position is closed.
     * @param account The address of the account closing the position.
     * @param position The closed position.
     */
    event ClosePosition(address indexed account, Position position);

    /**
     * @dev Emitted when a position is claimed.
     * @param account The address of the account claiming the position.
     * @param pnl The profit or loss of the claimed position.
     * @param interest The interest paid for the claimed position.
     * @param position The claimed position.
     */
    event ClaimPosition(
        address indexed account,
        int256 indexed pnl,
        uint256 indexed interest,
        Position position
    );

    /**
     * @dev Emitted when protocol fees are transferred.
     * @param positionId The ID of the position for which the fees are transferred.
     * @param amount The amount of fees transferred.
     */
    event TransferProtocolFee(uint256 indexed positionId, uint256 indexed amount);

    /**
     * @dev Opens a new position in the market.
     * @param qty The quantity of the position.
     * @param takerMargin The margin amount provided by the taker.
     * @param makerMargin The margin amount provided by the maker.
     * @param maxAllowableTradingFee The maximum allowable trading fee for the position.
     * @param data Additional data for the position callback.
     * @return The opened position.
     */
    function openPosition(
        int256 qty,
        uint256 takerMargin,
        uint256 makerMargin,
        uint256 maxAllowableTradingFee,
        bytes calldata data
    ) external returns (Position memory);

    /**
     * @dev Closes a position in the market.
     * @param positionId The ID of the position to close.
     */
    function closePosition(uint256 positionId) external;

    /**
     * @dev Claims a closed position in the market.
     * @param positionId The ID of the position to claim.
     * @param recipient The address of the recipient of the claimed position.
     * @param data Additional data for the claim callback.
     */
    function claimPosition(
        uint256 positionId,
        address recipient, // EOA or account contract
        bytes calldata data
    ) external;

    /**
     * @dev Retrieves multiple positions by their IDs.
     * @param positionIds The IDs of the positions to retrieve.
     * @return positions An array of retrieved positions.
     */
    function getPositions(
        uint256[] calldata positionIds
    ) external view returns (Position[] memory positions);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ILendingPool
 * @dev Interface for a lending pool contract.
 */
interface ILendingPool {
    /**
     * @notice Emitted when a flash loan is executed.
     * @param sender The address initiating the flash loan.
     * @param recipient The address receiving the flash loan.
     * @param amount The amount of the flash loan.
     * @param paid The amount paid back after the flash loan.
     * @param paidToTakerPool The amount paid to the taker pool after the flash loan.
     * @param paidToMakerPool The amount paid to the maker pool after the flash loan.
     */
    event FlashLoan(
        address indexed sender,
        address indexed recipient,
        uint256 indexed amount,
        uint256 paid,
        uint256 paidToTakerPool,
        uint256 paidToMakerPool
    );

    /**
     * @notice Executes a flash loan.
     * @param token The address of the token for the flash loan.
     * @param amount The amount of the flash loan.
     * @param recipient The address to receive the flash loan.
     * @param data Additional data for the flash loan.
     */
    function flashLoan(
        address token,
        uint256 amount,
        address recipient,
        bytes calldata data
    ) external;

    /**
     * @notice Retrieves the pending share of earnings for a specific bin (subset) of funds in a market.
     * @param market The address of the market.
     * @param settlementToken The settlement token address.
     * @param binBalance The balance of funds in the bin.
     * @return The pending share of earnings for the specified bin.
     */
    function getPendingBinShare(
        address market,
        address settlementToken,
        uint256 binBalance
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IVault
 * @dev Interface for the Vault contract, responsible for managing positions and liquidity.
 */
interface IVault {
    /**
     * @notice Emitted when a position is opened.
     * @param market The address of the market.
     * @param positionId The ID of the opened position.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param tradingFee The trading fee associated with the position.
     * @param protocolFee The protocol fee associated with the position.
     */
    event OnOpenPosition(
        address indexed market,
        uint256 indexed positionId,
        uint256 indexed takerMargin,
        uint256 tradingFee,
        uint256 protocolFee
    );

    /**
     * @notice Emitted when a position is claimed.
     * @param market The address of the market.
     * @param positionId The ID of the claimed position.
     * @param recipient The address of the recipient of the settlement amount.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param settlementAmount The settlement amount received by the recipient.
     */
    event OnClaimPosition(
        address indexed market,
        uint256 indexed positionId,
        address indexed recipient,
        uint256 takerMargin,
        uint256 settlementAmount
    );

    /**
     * @notice Emitted when liquidity is added to the vault.
     * @param market The address of the market.
     * @param amount The amount of liquidity added.
     */
    event OnAddLiquidity(address indexed market, uint256 indexed amount);

    /**
     * @notice Emitted when pending liquidity is settled.
     * @param market The address of the market.
     * @param pendingDeposit The amount of pending deposit being settled.
     * @param pendingWithdrawal The amount of pending withdrawal being settled.
     */
    event OnSettlePendingLiquidity(
        address indexed market,
        uint256 indexed pendingDeposit,
        uint256 indexed pendingWithdrawal
    );

    /**
     * @notice Emitted when liquidity is withdrawn from the vault.
     * @param market The address of the market.
     * @param amount The amount of liquidity withdrawn.
     * @param recipient The address of the recipient of the withdrawn liquidity.
     */
    event OnWithdrawLiquidity(
        address indexed market,
        uint256 indexed amount,
        address indexed recipient
    );

    /**
     * @notice Emitted when the keeper fee is transferred.
     * @param fee The amount of the transferred keeper fee as native token.
     * @param amount The amount of settlement token to be used for paying keeper fee.
     */
    event TransferKeeperFee(uint256 indexed fee, uint256 indexed amount);

    /**
     * @notice Emitted when the keeper fee is transferred for a specific market.
     * @param market The address of the market.
     * @param fee The amount of the transferred keeper fee as native token.
     * @param amount The amount of settlement token to be used for paying keeper fee.
     */
    event TransferKeeperFee(address indexed market, uint256 indexed fee, uint256 indexed amount);

    /**
     * @notice Emitted when the protocol fee is transferred for a specific position.
     * @param market The address of the market.
     * @param positionId The ID of the position.
     * @param amount The amount of the transferred fee.
     */
    event TransferProtocolFee(
        address indexed market,
        uint256 indexed positionId,
        uint256 indexed amount
    );

    /**
     * @notice Called when a position is opened by a market contract.
     * @param settlementToken The settlement token address.
     * @param positionId The ID of the opened position.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param tradingFee The trading fee associated with the position.
     * @param protocolFee The protocol fee associated with the position.
     */
    function onOpenPosition(
        address settlementToken,
        uint256 positionId,
        uint256 takerMargin,
        uint256 tradingFee,
        uint256 protocolFee
    ) external;

    /**
     * @notice Called when a position is claimed by a market contract.
     * @param settlementToken The settlement token address.
     * @param positionId The ID of the claimed position.
     * @param recipient The address that will receive the settlement amount.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param settlementAmount The amount to be settled for the position.
     */
    function onClaimPosition(
        address settlementToken,
        uint256 positionId,
        address recipient,
        uint256 takerMargin,
        uint256 settlementAmount
    ) external;

    /**
     * @notice Called when liquidity is added to the vault by a market contract.
     * @param settlementToken The settlement token address.
     * @param amount The amount of liquidity being added.
     */
    function onAddLiquidity(address settlementToken, uint256 amount) external;

    /**
     * @notice Called when pending liquidity is settled in the vault by a market contract.
     * @param settlementToken The settlement token address.
     * @param pendingDeposit The amount of pending deposits being settled.
     * @param pendingWithdrawal The amount of pending withdrawals being settled.
     */
    function onSettlePendingLiquidity(
        address settlementToken,
        uint256 pendingDeposit,
        uint256 pendingWithdrawal
    ) external;

    /**
     * @notice Called when liquidity is withdrawn from the vault by a market contract.
     * @param settlementToken The settlement token address.
     * @param recipient The address that will receive the withdrawn liquidity.
     * @param amount The amount of liquidity to be withdrawn.
     */
    function onWithdrawLiquidity(
        address settlementToken,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Transfers the keeper fee from the market to the specified keeper.
     * @param settlementToken The settlement token address.
     * @param keeper The address of the keeper to receive the fee.
     * @param fee The amount of the fee to transfer as native token.
     * @param margin The margin amount used for the fee payment.
     * @return usedFee The actual settlement token amount of fee used for the transfer.
     */
    function transferKeeperFee(
        address settlementToken,
        address keeper,
        uint256 fee,
        uint256 margin
    ) external returns (uint256 usedFee);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @dev The BinMargin struct represents the margin information for an LP bin.
 * @param tradingFeeRate The trading fee rate associated with the LP bin
 * @param amount The maker margin amount specified for the LP bin
 */
struct BinMargin {
    uint16 tradingFeeRate;
    uint256 amount;
}

using BinMarginLib for BinMargin global;

/**
 * @title BinMarginLib
 * @dev The BinMarginLib library provides functions to operate on BinMargin structs.
 */
library BinMarginLib {
    using Math for uint256;

    uint256 constant TRADING_FEE_RATE_PRECISION = 10000;

    /**
     * @notice Calculates the trading fee based on the margin amount and the trading fee rate.
     * @param self The BinMargin struct
     * @param _feeProtocol The protocol fee for the market
     * @return The trading fee amount
     */
    function tradingFee(BinMargin memory self, uint8 _feeProtocol) internal pure returns (uint256) {
        uint256 _tradingFee = self.amount.mulDiv(self.tradingFeeRate, TRADING_FEE_RATE_PRECISION);
        return _tradingFee - _protocolFee(_tradingFee, _feeProtocol);
    }

    /**
     * @notice Calculates the protocol fee based on the margin amount and the trading fee rate.
     * @param self The BinMargin struct
     * @param _feeProtocol The protocol fee for the market
     * @return The protocol fee amount
     */
    function protocolFee(
        BinMargin memory self,
        uint8 _feeProtocol
    ) internal pure returns (uint256) {
        return
            _protocolFee(
                self.amount.mulDiv(self.tradingFeeRate, TRADING_FEE_RATE_PRECISION),
                _feeProtocol
            );
    }

    function _protocolFee(uint256 _tradingFee, uint8 _feeProtocol) private pure returns (uint256) {
        return _feeProtocol != 0 ? _tradingFee / _feeProtocol : 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {FEE_RATES_LENGTH} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";

/**
 * @title CLBTokenLib
 * @notice Provides utility functions for working with CLB tokens.
 */
library CLBTokenLib {
    using SignedMath for int256;
    using SafeCast for uint256;

    uint256 private constant DIRECTION_PRECISION = 10 ** 10;
    uint16 private constant MIN_FEE_RATE = 1;

    /**
     * @notice Encode the CLB token ID of ERC1155 token type
     * @dev If `tradingFeeRate` is negative, it adds `DIRECTION_PRECISION` to the absolute fee rate.
     *      Otherwise it returns the fee rate directly.
     * @return id The ID of ERC1155 token
     */
    function encodeId(int16 tradingFeeRate) internal pure returns (uint256) {
        bool long = tradingFeeRate > 0;
        return _encodeId(uint16(long ? tradingFeeRate : -tradingFeeRate), long);
    }

    /**
     * @notice Decode the trading fee rate from the CLB token ID of ERC1155 token type
     * @dev If `id` is greater than or equal to `DIRECTION_PRECISION`,
     *      then it substracts `DIRECTION_PRECISION` from `id`
     *      and returns the negation of the substracted value.
     *      Otherwise it returns `id` directly.
     * @return tradingFeeRate The trading fee rate
     */
    function decodeId(uint256 id) internal pure returns (int16 tradingFeeRate) {
        if (id >= DIRECTION_PRECISION) {
            tradingFeeRate = -int16((id - DIRECTION_PRECISION).toUint16());
        } else {
            tradingFeeRate = int16(id.toUint16());
        }
    }

    /**
     * @notice Retrieves the array of supported trading fee rates.
     * @dev This function returns the array of supported trading fee rates,
     *      ranging from the minimum fee rate to the maximum fee rate with step increments.
     * @return tradingFeeRates The array of supported trading fee rates.
     */
    function tradingFeeRates() internal pure returns (uint16[FEE_RATES_LENGTH] memory) {
        // prettier-ignore
        return [
            MIN_FEE_RATE, 2, 3, 4, 5, 6, 7, 8, 9, // 0.01% ~ 0.09%, step 0.01%
            10, 20, 30, 40, 50, 60, 70, 80, 90, // 0.1% ~ 0.9%, step 0.1%
            100, 200, 300, 400, 500, 600, 700, 800, 900, // 1% ~ 9%, step 1%
            1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000 // 10% ~ 50%, step 5%
        ];
    }

    function tokenIds() internal pure returns (uint256[] memory) {
        uint16[FEE_RATES_LENGTH] memory feeRates = tradingFeeRates();

        uint256[] memory ids = new uint256[](FEE_RATES_LENGTH * 2);
        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            ids[i] = _encodeId(feeRates[i], true);
            ids[i + FEE_RATES_LENGTH] = _encodeId(feeRates[i], false);

            unchecked {
                i++;
            }
        }

        return ids;
    }

    function _encodeId(uint16 tradingFeeRate, bool long) private pure returns (uint256 id) {
        id = long ? tradingFeeRate : tradingFeeRate + DIRECTION_PRECISION;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

uint256 constant BPS = 10000;
uint256 constant FEE_RATES_LENGTH = 36;

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {CLBToken} from "@chromatic-protocol/contracts/core/CLBToken.sol";

/**
 * @title CLBTokenDeployerLib
 * @notice Library for deploying CLB tokens
 */
library CLBTokenDeployerLib {
    /**
     * @notice Deploys a new CLB token
     * @return clbToken The address of the deployed CLB token
     */
    function deploy() external returns (address clbToken) {
        clbToken = address(new CLBToken());
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";
import {IDiamondCut} from "@chromatic-protocol/contracts/core/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "@chromatic-protocol/contracts/core/interfaces/IDiamondLoupe.sol";
import {IMarketState} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketState.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {IMarketLiquidityLens} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidityLens.sol";
import {IMarketTrade} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketTrade.sol";
import {IMarketLiquidate} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidate.sol";
import {IMarketSettle} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketSettle.sol";
import {ChromaticMarket} from "@chromatic-protocol/contracts/core/ChromaticMarket.sol";

/**
 * @dev Storage struct for deploying a ChromaticMarket contract
 */
struct MarketDeployer {
    Parameters parameters;
}

/**
 * @dev Struct for storing deployment parameters
 */
struct Parameters {
    address oracleProvider;
    address settlementToken;
}

/**
 * @title MarketDeployerLib
 * @notice Library for deploying a ChromaticMarket contract
 */
library MarketDeployerLib {
    /**
     * @notice Deploys a ChromaticMarket contract
     * @param self The MarketDeployer storage
     * @param oracleProvider The address of the oracle provider
     * @param settlementToken The address of the settlement token
     * @param marketDiamondCutFacet The market diamond cut facet address.
     * @param marketLoupeFacet The market loupe facet address.
     * @param marketStateFacet The market state facet address.
     * @param marketLiquidityFacet The market liquidity facet address.
     * @param marketLiquidityLensFacet The market liquidity lens facet address.
     * @param marketTradeFacet The market trade facet address.
     * @param marketLiquidateFacet The market liquidate facet address.
     * @param marketSettleFacet The market settle facet address.
     * @return market The address of the deployed ChromaticMarket contract
     */
    function deploy(
        MarketDeployer storage self,
        address oracleProvider,
        address settlementToken,
        address marketDiamondCutFacet,
        address marketLoupeFacet,
        address marketStateFacet,
        address marketLiquidityFacet,
        address marketLiquidityLensFacet,
        address marketTradeFacet,
        address marketLiquidateFacet,
        address marketSettleFacet
    ) external returns (address market) {
        self.parameters = Parameters({
            oracleProvider: oracleProvider,
            settlementToken: settlementToken
        });
        market = address(
            new ChromaticMarket{salt: keccak256(abi.encode(oracleProvider, settlementToken))}(
                marketDiamondCutFacet
            )
        );
        delete self.parameters;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](7);
        cut[0] = _marketLoupeFacetCut(marketLoupeFacet);
        cut[1] = _marketStateFacetCut(marketStateFacet);
        cut[2] = _marketLiquidityFacetCut(marketLiquidityFacet);
        cut[3] = _marketLiquidityLensFacetCut(marketLiquidityLensFacet);
        cut[4] = _marketTradeFacetCut(marketTradeFacet);
        cut[5] = _marketLiquidateFacetCut(marketLiquidateFacet);
        cut[6] = _marketSettleFacetCut(marketSettleFacet);
        IDiamondCut(market).diamondCut(cut, address(0), "");
    }

    function _marketLoupeFacetCut(
        address marketLoupeFacet
    ) private pure returns (IDiamondCut.FacetCut memory cut) {
        bytes4[] memory functionSelectors = new bytes4[](4);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;

        cut = IDiamondCut.FacetCut({
            facetAddress: marketLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }

    function _marketStateFacetCut(
        address marketStateFacet
    ) private pure returns (IDiamondCut.FacetCut memory cut) {
        bytes4[] memory functionSelectors = new bytes4[](9);
        functionSelectors[0] = IMarketState.factory.selector;
        functionSelectors[1] = IMarketState.settlementToken.selector;
        functionSelectors[2] = IMarketState.oracleProvider.selector;
        functionSelectors[3] = IMarketState.clbToken.selector;
        functionSelectors[4] = IMarketState.liquidator.selector;
        functionSelectors[5] = IMarketState.vault.selector;
        functionSelectors[6] = IMarketState.keeperFeePayer.selector;
        functionSelectors[7] = IMarketState.feeProtocol.selector;
        functionSelectors[8] = IMarketState.setFeeProtocol.selector;

        cut = IDiamondCut.FacetCut({
            facetAddress: marketStateFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }

    function _marketLiquidityFacetCut(
        address marketLiquidityFacet
    ) private pure returns (IDiamondCut.FacetCut memory cut) {
        bytes4[] memory functionSelectors = new bytes4[](12);
        functionSelectors[0] = IMarketLiquidity.addLiquidity.selector;
        functionSelectors[1] = IMarketLiquidity.addLiquidityBatch.selector;
        functionSelectors[2] = IMarketLiquidity.claimLiquidity.selector;
        functionSelectors[3] = IMarketLiquidity.claimLiquidityBatch.selector;
        functionSelectors[4] = IMarketLiquidity.removeLiquidity.selector;
        functionSelectors[5] = IMarketLiquidity.removeLiquidityBatch.selector;
        functionSelectors[6] = IMarketLiquidity.withdrawLiquidity.selector;
        functionSelectors[7] = IMarketLiquidity.withdrawLiquidityBatch.selector;
        functionSelectors[8] = IMarketLiquidity.distributeEarningToBins.selector;
        functionSelectors[9] = IERC1155Receiver.onERC1155Received.selector;
        functionSelectors[10] = IERC1155Receiver.onERC1155BatchReceived.selector;
        functionSelectors[11] = IERC165.supportsInterface.selector;

        cut = IDiamondCut.FacetCut({
            facetAddress: marketLiquidityFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }

    function _marketLiquidityLensFacetCut(
        address marketLiquidityLensFacet
    ) private pure returns (IDiamondCut.FacetCut memory cut) {
        bytes4[] memory functionSelectors = new bytes4[](9);
        functionSelectors[0] = IMarketLiquidityLens.getBinLiquidity.selector;
        functionSelectors[1] = IMarketLiquidityLens.getBinFreeLiquidity.selector;
        functionSelectors[2] = IMarketLiquidityLens.getBinValues.selector;
        functionSelectors[3] = IMarketLiquidityLens.getLpReceipt.selector;
        functionSelectors[4] = IMarketLiquidityLens.pendingLiquidity.selector;
        functionSelectors[5] = IMarketLiquidityLens.pendingLiquidityBatch.selector;
        functionSelectors[6] = IMarketLiquidityLens.claimableLiquidity.selector;
        functionSelectors[7] = IMarketLiquidityLens.claimableLiquidityBatch.selector;
        functionSelectors[8] = IMarketLiquidityLens.liquidityBinStatuses.selector;

        cut = IDiamondCut.FacetCut({
            facetAddress: marketLiquidityLensFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }

    function _marketTradeFacetCut(
        address marketTradeFacet
    ) private pure returns (IDiamondCut.FacetCut memory cut) {
        bytes4[] memory functionSelectors = new bytes4[](4);
        functionSelectors[0] = IMarketTrade.openPosition.selector;
        functionSelectors[1] = IMarketTrade.closePosition.selector;
        functionSelectors[2] = IMarketTrade.claimPosition.selector;
        functionSelectors[3] = IMarketTrade.getPositions.selector;

        cut = IDiamondCut.FacetCut({
            facetAddress: marketTradeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }

    function _marketLiquidateFacetCut(
        address marketLiquidateFacet
    ) private pure returns (IDiamondCut.FacetCut memory cut) {
        bytes4[] memory functionSelectors = new bytes4[](4);
        functionSelectors[0] = IMarketLiquidate.checkLiquidation.selector;
        functionSelectors[1] = IMarketLiquidate.liquidate.selector;
        functionSelectors[2] = IMarketLiquidate.checkClaimPosition.selector;
        functionSelectors[3] = IMarketLiquidate.claimPosition.selector;

        cut = IDiamondCut.FacetCut({
            facetAddress: marketLiquidateFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }

    function _marketSettleFacetCut(
        address marketSettleFacet
    ) private pure returns (IDiamondCut.FacetCut memory cut) {
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IMarketSettle.settle.selector;

        cut = IDiamondCut.FacetCut({
            facetAddress: marketSettleFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "@chromatic-protocol/contracts/core/interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

struct DiamondStorage {
    // maps function selectors to the facets that execute the functions.
    // and maps the selectors to their position in the selectorSlots array.
    // func selector => address facet, selector position
    mapping(bytes4 => bytes32) facets;
    // array of slots of function selectors.
    // each slot holds 8 function selectors.
    mapping(uint256 => bytes32) selectorSlots;
    // The number of function selectors in selectorSlots
    uint16 selectorCount;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
}

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library DiamondStorageLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("protocol.chromatic.diamond.storage");

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );

            unchecked {
                facetIndex++;
            }
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "DiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "DiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "DiamondCut: Can't add function that already exists"
                );
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                // " << 5 is the same as multiplying by 32 ( * 32)
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "DiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(
                    oldFacetAddress != address(this),
                    "DiamondCut: Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "DiamondCut: Can't replace function with same function"
                );
                require(
                    oldFacetAddress != address(0),
                    "DiamondCut: Can't replace function that doesn't exist"
                );
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "DiamondCut: Remove facet address must be address(0)"
            );
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "DiamondCut: Can't remove function that doesn't exist"
                    );
                    // only useful if immutable functions exist
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "DiamondCut: Can't remove immutable function"
                    );
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }

                unchecked {
                    selectorIndex++;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("DiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "DiamondCut: _init address has no code");
        //slither-disable-next-line low-level-calls
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Errors
 * @dev This library provides a set of error codes as string constants for handling exceptions and revert messages in the library.
 */
library Errors {
    /**
     * @dev Error code indicating that there is not enough free liquidity available in liquidity pool when open a new poisition.
     */
    string constant NOT_ENOUGH_FREE_LIQUIDITY = "NEFL";

    /**
     * @dev Error code indicating that the specified amount is too small when add liquidity to each bin.
     */
    string constant TOO_SMALL_AMOUNT = "TSA";

    /**
     * @dev Error code indicating that the provided oracle version is invalid or unsupported.
     */
    string constant INVALID_ORACLE_VERSION = "IOV";

    /**
     * @dev Error code indicating that the specified value exceeds the allowed margin range when claim a position.
     */
    string constant EXCEED_MARGIN_RANGE = "IOV";

    /**
     * @dev Error code indicating that the provided trading fee rate is not supported.
     */
    string constant UNSUPPORTED_TRADING_FEE_RATE = "UTFR";

    /**
     * @dev Error code indicating that the oracle provider is already registered.
     */
    string constant ALREADY_REGISTERED_ORACLE_PROVIDER = "ARO";

    /**
     * @dev Error code indicating that the settlement token is already registered.
     */
    string constant ALREADY_REGISTERED_TOKEN = "ART";

    /**
     * @dev Error code indicating that the settlement token is not registered.
     */
    string constant UNREGISTERED_TOKEN = "URT";

    /**
     * @dev Error code indicating that the interest rate has not been initialized.
     */
    string constant INTEREST_RATE_NOT_INITIALIZED = "IRNI";

    /**
     * @dev Error code indicating that the provided interest rate exceeds the maximum allowed rate.
     */
    string constant INTEREST_RATE_OVERFLOW = "IROF";

    /**
     * @dev Error code indicating that the provided timestamp for an interest rate is in the past.
     */
    string constant INTEREST_RATE_PAST_TIMESTAMP = "IRPT";

    /**
     * @dev Error code indicating that the provided interest rate record cannot be appended to the existing array.
     */
    string constant INTEREST_RATE_NOT_APPENDABLE = "IRNA";

    /**
     * @dev Error code indicating that an interest rate has already been applied and cannot be modified further.
     */
    string constant INTEREST_RATE_ALREADY_APPLIED = "IRAA";

    /**
     * @dev Error code indicating that the position is unsettled.
     */
    string constant UNSETTLED_POSITION = "USP";

    /**
     * @dev Error code indicating that the position quantity is invalid.
     */
    string constant INVALID_POSITION_QTY = "IPQ";

    /**
     * @dev Error code indicating that the oracle price is not positive.
     */
    string constant NOT_POSITIVE_PRICE = "NPP";
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {BPS} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title InterestRate
 * @notice Provides functions for managing interest rates.
 * @dev The library allows for the initialization, appending, and removal of interest rate records,
 *      as well as calculating interest based on these records.
 */
library InterestRate {
    using Math for uint256;

    /**
     * @dev Record type
     * @param annualRateBPS Annual interest rate in BPS
     * @param beginTimestamp Timestamp when the interest rate becomes effective
     */
    struct Record {
        uint256 annualRateBPS;
        uint256 beginTimestamp;
    }

    uint256 private constant MAX_RATE_BPS = BPS; // max interest rate is 100%
    uint256 private constant YEAR = 365 * 24 * 3600;

    /**
     * @dev Ensure that the interest rate records have been initialized before certain functions can be called.
     *      It checks whether the length of the Record array is greater than 0.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty (it indicates that the interest rate has not been initialized).
     */
    modifier initialized(Record[] storage self) {
        require(self.length != 0, Errors.INTEREST_RATE_NOT_INITIALIZED);
        _;
    }

    /**
     * @notice Initialize the interest rate records.
     * @param self The stored record array
     * @param initialInterestRate The initial interest rate
     */
    function initialize(Record[] storage self, uint256 initialInterestRate) internal {
        self.push(Record({annualRateBPS: initialInterestRate, beginTimestamp: 0}));
    }

    /**
     * @notice Add a new interest rate record to the array.
     * @dev Annual rate is not greater than the maximum rate and that the begin timestamp is in the future,
     *      and the new record's begin timestamp is greater than the previous record's timestamp.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty.
     *      Throws an error with the code `Errors.INTEREST_RATE_OVERFLOW` if the rate exceed the maximum allowed rate (100%).
     *      Throws an error with the code `Errors.INTEREST_RATE_PAST_TIMESTAMP` if the timestamp is in the past, ensuring that the interest rate period has not already started.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_APPENDABLE` if the timestamp is greater than the last recorded timestamp, ensuring that the new record is appended in chronological order.
     * @param self The stored record array
     * @param annualRateBPS The annual interest rate in BPS
     * @param beginTimestamp Begin timestamp of this record
     */
    function appendRecord(
        Record[] storage self,
        uint256 annualRateBPS,
        uint256 beginTimestamp
    ) internal initialized(self) {
        require(annualRateBPS <= MAX_RATE_BPS, Errors.INTEREST_RATE_OVERFLOW);
        //slither-disable-next-line timestamp
        require(beginTimestamp > block.timestamp, Errors.INTEREST_RATE_PAST_TIMESTAMP);

        Record memory lastRecord = self[self.length - 1];
        require(beginTimestamp > lastRecord.beginTimestamp, Errors.INTEREST_RATE_NOT_APPENDABLE);

        self.push(Record({annualRateBPS: annualRateBPS, beginTimestamp: beginTimestamp}));
    }

    /**
     * @notice Remove the last interest rate record from the array.
     * @dev The current time must be less than the begin timestamp of the last record.
     *      If the array has only one record, it returns false along with an empty record.
     *      Otherwise, it removes the last record from the array and returns true along with the removed record.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty.
     *      Throws an error with the code `Errors.INTEREST_RATE_ALREADY_APPLIED` if the `beginTimestamp` of the last record is not in the future.
     * @param self The stored record array
     * @return removed Whether the last record is removed
     * @return record The removed record
     */
    function removeLastRecord(
        Record[] storage self
    ) internal initialized(self) returns (bool removed, Record memory record) {
        if (self.length <= 1) {
            // empty
            return (false, Record(0, 0));
        }

        Record memory lastRecord = self[self.length - 1];
        //slither-disable-next-line timestamp
        require(block.timestamp < lastRecord.beginTimestamp, Errors.INTEREST_RATE_ALREADY_APPLIED);

        self.pop();

        return (true, lastRecord);
    }

    /**
     * @notice Find the interest rate record that applies to a given timestamp.
     * @dev It iterates through the array from the end to the beginning
     *      and returns the first record with a begin timestamp less than or equal to the provided timestamp.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty.
     * @param self The stored record array
     * @param timestamp Given timestamp
     * @return interestRate The record which is found
     * @return index The index of record
     */
    function findRecordAt(
        Record[] storage self,
        uint256 timestamp
    ) internal view initialized(self) returns (Record memory interestRate, uint256 index) {
        for (uint256 i = self.length; i != 0; ) {
            unchecked {
                index = i - 1;
            }
            interestRate = self[index];

            if (interestRate.beginTimestamp <= timestamp) {
                return (interestRate, index);
            }

            unchecked {
                i--;
            }
        }

        return (self[0], 0); // empty result (this line is not reachable)
    }

    /**
     * @notice Calculate the interest
     * @dev Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty.
     * @param self The stored record array
     * @param amount Token amount
     * @param from Begin timestamp (inclusive)
     * @param to End timestamp (exclusive)
     */
    function calculateInterest(
        Record[] storage self,
        uint256 amount,
        uint256 from, // timestamp (inclusive)
        uint256 to // timestamp (exclusive)
    ) internal view initialized(self) returns (uint256) {
        if (from >= to) {
            return 0;
        }

        uint256 interest = 0;

        uint256 endTimestamp = type(uint256).max;
        for (uint256 idx = self.length; idx != 0; ) {
            Record memory record = self[idx - 1];
            if (endTimestamp <= from) {
                break;
            }

            interest += _interest(
                amount,
                record.annualRateBPS,
                Math.min(to, endTimestamp) - Math.max(from, record.beginTimestamp)
            );
            endTimestamp = record.beginTimestamp;

            unchecked {
                idx--;
            }
        }
        return interest;
    }

    function _interest(
        uint256 amount,
        uint256 rateBPS, // annual rate
        uint256 period // in seconds
    ) private pure returns (uint256) {
        return amount.mulDiv(rateBPS * period, BPS * YEAR, Math.Rounding.Up);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";

/**
 * @dev Structure for tracking accumulated interest
 * @param accumulatedAt The timestamp at which the interest was last accumulated.
 * @param accumulatedAmount The total amount of interest accumulated.
 */
struct AccruedInterest {
    uint256 accumulatedAt;
    uint256 accumulatedAmount;
}

/**
 * @title AccruedInterestLib
 * @notice Tracks the accumulated interest for a given token amount and period of time
 */
library AccruedInterestLib {
    /**
     * @notice Accumulates interest for a given token amount and period of time
     * @param self The AccruedInterest storage
     * @param ctx The LpContext instance for interest calculation
     * @param tokenAmount The amount of tokens to calculate interest for
     * @param until The timestamp until which interest should be accumulated
     */
    function accumulate(
        AccruedInterest storage self,
        LpContext memory ctx,
        uint256 tokenAmount,
        uint256 until
    ) internal {
        uint256 accumulatedAt = self.accumulatedAt;
        // check if the interest is already accumulated for the given period of time.
        if (until <= accumulatedAt) return;

        if (tokenAmount != 0) {
            // calculate the interest for the given period of time and accumulate it
            self.accumulatedAmount += ctx.calculateInterest(tokenAmount, accumulatedAt, until);
        }
        // update the timestamp at which the interest was last accumulated.
        self.accumulatedAt = until;
    }

    /**
     * @notice Deducts interest from the accumulated interest.
     * @param self The AccruedInterest storage.
     * @param amount The amount of interest to deduct.
     */
    function deduct(AccruedInterest storage self, uint256 amount) internal {
        uint256 accumulatedAmount = self.accumulatedAmount;
        // check if the amount is greater than the accumulated interest.
        if (amount >= accumulatedAmount) {
            self.accumulatedAmount = 0;
        } else {
            self.accumulatedAmount = accumulatedAmount - amount;
        }
    }

    /**
     * @notice Calculates the accumulated interest for a given token amount and period of time
     * @param self The AccruedInterest storage
     * @param ctx The LpContext instance for interest calculation
     * @param tokenAmount The amount of tokens to calculate interest for
     * @param until The timestamp until which interest should be accumulated
     * @return The accumulated interest amount
     */
    function calculateInterest(
        AccruedInterest storage self,
        LpContext memory ctx,
        uint256 tokenAmount,
        uint256 until
    ) internal view returns (uint256) {
        if (tokenAmount == 0) return 0;

        uint256 accumulatedAt = self.accumulatedAt;
        uint256 accumulatedAmount = self.accumulatedAmount;
        if (until <= accumulatedAt) return accumulatedAmount;

        return accumulatedAmount + ctx.calculateInterest(tokenAmount, accumulatedAt, until);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {AccruedInterest, AccruedInterestLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/AccruedInterest.sol";
import {BinClosingPosition, BinClosingPositionLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinClosingPosition.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";

/**
 * @dev Represents a closed position within an LiquidityBin.
 */
struct BinClosedPosition {
    uint256 _totalMakerMargin;
    uint256 _totalTakerMargin;
    BinClosingPosition _closing;
    EnumerableSet.UintSet _waitingVersions;
    mapping(uint256 => _ClaimWaitingPosition) _waitingPositions;
    AccruedInterest _accruedInterest;
}

/**
 * @dev Represents the accumulated values of the waiting positions to be claimed
 *      for a specific version within BinClosedPosition.
 */
struct _ClaimWaitingPosition {
    int256 totalQty;
    uint256 totalEntryAmount;
    uint256 totalMakerMargin;
    uint256 totalTakerMargin;
}

/**
 * @title BinClosedPositionLib
 * @notice A library that provides functions to manage the closed position within an LiquidityBin.
 */
library BinClosedPositionLib {
    using EnumerableSet for EnumerableSet.UintSet;
    using AccruedInterestLib for AccruedInterest;
    using BinClosingPositionLib for BinClosingPosition;

    /**
     * @notice Settles the closing position within the BinClosedPosition.
     * @dev If the closeVersion is not set or is equal to the current oracle version, no action is taken.
     *      Otherwise, the waiting position is stored and the accrued interest is accumulated.
     * @param self The BinClosedPosition storage.
     * @param ctx The LpContext memory.
     */
    function settleClosingPosition(BinClosedPosition storage self, LpContext memory ctx) internal {
        uint256 closeVersion = self._closing.closeVersion;
        if (!ctx.isPastVersion(closeVersion)) return;

        _ClaimWaitingPosition memory waitingPosition = _ClaimWaitingPosition({
            totalQty: self._closing.totalQty,
            totalEntryAmount: self._closing.totalEntryAmount,
            totalMakerMargin: self._closing.totalMakerMargin,
            totalTakerMargin: self._closing.totalTakerMargin
        });

        // accumulate interest before update `_totalMakerMargin`
        self._accruedInterest.accumulate(ctx, self._totalMakerMargin, block.timestamp);

        self._totalMakerMargin += waitingPosition.totalMakerMargin;
        self._totalTakerMargin += waitingPosition.totalTakerMargin;
        //slither-disable-next-line unused-return
        self._waitingVersions.add(closeVersion);
        self._waitingPositions[closeVersion] = waitingPosition;

        self._closing.settleAccruedInterest(ctx);
        self._accruedInterest.accumulatedAmount += self._closing.accruedInterest.accumulatedAmount;

        delete self._closing;
    }

    /**
     * @notice Closes the position within the BinClosedPosition.
     * @dev Delegates the onClosePosition function call to the underlying BinClosingPosition.
     * @param self The BinClosedPosition storage.
     * @param ctx The LpContext memory.
     * @param param The PositionParam memory.
     */
    function onClosePosition(
        BinClosedPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        self._closing.onClosePosition(ctx, param);
    }

    /**
     * @notice Claims the position within the BinClosedPosition.
     * @dev If the closeVersion is equal to the BinClosingPosition's closeVersion, the claim is made directly.
     *      Otherwise, the claim is made from the waiting position, and if exhausted, the waiting position is removed.
     *      The accrued interest is accumulated and deducted accordingly.
     * @param self The BinClosedPosition storage.
     * @param ctx The LpContext memory.
     * @param param The PositionParam memory.
     */
    function onClaimPosition(
        BinClosedPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        uint256 closeVersion = param.closeVersion;

        if (closeVersion == self._closing.closeVersion) {
            self._closing.onClaimPosition(ctx, param);
        } else {
            bool exhausted = _onClaimPosition(self._waitingPositions[closeVersion], ctx, param);

            // accumulate interest before update `_totalMakerMargin`
            self._accruedInterest.accumulate(ctx, self._totalMakerMargin, block.timestamp);

            self._totalMakerMargin -= param.makerMargin;
            self._totalTakerMargin -= param.takerMargin;
            self._accruedInterest.deduct(param.calculateInterest(ctx, block.timestamp));

            if (exhausted) {
                //slither-disable-next-line unused-return
                self._waitingVersions.remove(closeVersion);
                delete self._waitingPositions[closeVersion];
            }
        }
    }

    /**
     * @dev Claims the position from the waiting position within the BinClosedPosition.
     *      Updates the waiting position and returns whether the waiting position is exhausted.
     * @param waitingPosition The waiting position storage.
     * @param ctx The LpContext memory.
     * @param param The PositionParam memory.
     * @return exhausted Whether the waiting position is exhausted.
     */
    function _onClaimPosition(
        _ClaimWaitingPosition storage waitingPosition,
        LpContext memory ctx,
        PositionParam memory param
    ) private returns (bool exhausted) {
        int256 totalQty = waitingPosition.totalQty;
        int256 qty = param.qty;
        PositionUtil.checkRemovePositionQty(totalQty, qty);
        if (totalQty == qty) return true;

        waitingPosition.totalQty = totalQty - qty;
        waitingPosition.totalEntryAmount -= param.entryAmount(ctx);
        waitingPosition.totalMakerMargin -= param.makerMargin;
        waitingPosition.totalTakerMargin -= param.takerMargin;

        return false;
    }

    /**
     * @notice Returns the total maker margin for a liquidity bin closed position.
     * @param self The BinClosedPosition storage struct.
     * @return uint256 The total maker margin.
     */
    function totalMakerMargin(BinClosedPosition storage self) internal view returns (uint256) {
        return self._totalMakerMargin + self._closing.totalMakerMargin;
    }

    /**
     * @notice Returns the total taker margin for a liquidity bin closed position.
     * @param self The BinClosedPosition storage struct.
     * @return uint256 The total taker margin.
     */
    function totalTakerMargin(BinClosedPosition storage self) internal view returns (uint256) {
        return self._totalTakerMargin + self._closing.totalTakerMargin;
    }

    /**
     * @dev Calculates the current interest for a liquidity bin closed position.
     * @param self The BinClosedPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return uint256 The current interest.
     */
    function currentInterest(
        BinClosedPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return _currentInterest(self, ctx) + self._closing.currentInterest(ctx);
    }

    /**
     * @dev Calculates the current interest for a liquidity bin closed position without closing position.
     * @param self The BinClosedPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return uint256 The current interest.
     */
    function _currentInterest(
        BinClosedPosition storage self,
        LpContext memory ctx
    ) private view returns (uint256) {
        return
            self._accruedInterest.calculateInterest(ctx, self._totalMakerMargin, block.timestamp);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {AccruedInterest, AccruedInterestLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/AccruedInterest.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @dev Represents the closing position within an LiquidityBin.
 * @param closeVersion The oracle version when the position was closed.
 * @param totalQty The total quantity of the closing position.
 * @param totalEntryAmount The total entry amount of the closing position.
 * @param totalMakerMargin The total maker margin of the closing position.
 * @param totalTakerMargin The total taker margin of the closing position.
 * @param accruedInterest The accumulated interest of the closing position.
 */
struct BinClosingPosition {
    uint256 closeVersion;
    int256 totalQty;
    uint256 totalEntryAmount;
    uint256 totalMakerMargin;
    uint256 totalTakerMargin;
    AccruedInterest accruedInterest;
}

/**
 * @title BinClosingPositionLib
 * @notice A library that provides functions to manage the closing position within an LiquidityBin.
 */
library BinClosingPositionLib {
    using AccruedInterestLib for AccruedInterest;

    /**
     * @notice Settles the accumulated interest of the closing position.
     * @param self The BinClosingPosition storage.
     * @param ctx The LpContext.
     */
    function settleAccruedInterest(BinClosingPosition storage self, LpContext memory ctx) internal {
        self.accruedInterest.accumulate(ctx, self.totalMakerMargin, block.timestamp);
    }

    /**
     * @notice Handles the closing of a position.
     * @dev Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if the `closeVersion` is not valid.
     * @param self The BinClosingPosition storage.
     * @param ctx The LpContext.
     * @param param The position parameters.
     */
    function onClosePosition(
        BinClosingPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        uint256 closeVersion = self.closeVersion;
        require(
            closeVersion == 0 || closeVersion == param.closeVersion,
            Errors.INVALID_ORACLE_VERSION
        );

        int256 totalQty = self.totalQty;
        int256 qty = param.qty;
        PositionUtil.checkAddPositionQty(totalQty, qty);

        // accumulate interest before update `totalMakerMargin`
        settleAccruedInterest(self, ctx);

        self.closeVersion = param.closeVersion;
        self.totalQty = totalQty + qty;
        self.totalEntryAmount += param.entryAmount(ctx);
        self.totalMakerMargin += param.makerMargin;
        self.totalTakerMargin += param.takerMargin;
        self.accruedInterest.accumulatedAmount += param.calculateInterest(ctx, block.timestamp);
    }

    /**
     * @notice Handles the claiming of a position.
     * @dev Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if the `closeVersion` is not valid.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @param param The position parameters.
     */
    function onClaimPosition(
        BinClosingPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        require(self.closeVersion == param.closeVersion, Errors.INVALID_ORACLE_VERSION);

        int256 totalQty = self.totalQty;
        int256 qty = param.qty;
        PositionUtil.checkRemovePositionQty(totalQty, qty);

        // accumulate interest before update `totalMakerMargin`
        settleAccruedInterest(self, ctx);

        self.totalQty = totalQty - qty;
        self.totalEntryAmount -= param.entryAmount(ctx);
        self.totalMakerMargin -= param.makerMargin;
        self.totalTakerMargin -= param.takerMargin;
        self.accruedInterest.deduct(param.calculateInterest(ctx, block.timestamp));
    }

    /**
     * @notice Calculates the current accrued interest of the closing position.
     * @param self The BinClosingPosition storage.
     * @param ctx The LpContext.
     * @return uint256 The current accrued interest.
     */
    function currentInterest(
        BinClosingPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return self.accruedInterest.calculateInterest(ctx, self.totalMakerMargin, block.timestamp);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {DoubleEndedQueue} from "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @dev Represents the liquidity information within an LiquidityBin.
 */
struct BinLiquidity {
    uint256 total;
    IMarketLiquidity.PendingLiquidity _pending;
    mapping(uint256 => _ClaimMinting) _claimMintings;
    mapping(uint256 => _ClaimBurning) _claimBurnings;
    DoubleEndedQueue.Bytes32Deque _burningVersions;
}

/**
 * @dev Represents the accumulated values of minting claims
 *      for a specific oracle version within BinLiquidity.
 */
struct _ClaimMinting {
    uint256 tokenAmountRequested;
    uint256 clbTokenAmount;
}

/**
 * @dev Represents the accumulated values of burning claims
 *      for a specific oracle version within BinLiquidity.
 */
struct _ClaimBurning {
    uint256 clbTokenAmountRequested;
    uint256 clbTokenAmount;
    uint256 tokenAmount;
}

/**
 * @title BinLiquidityLib
 * @notice A library that provides functions to manage the liquidity within an LiquidityBin.
 */
library BinLiquidityLib {
    using Math for uint256;
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;

    /// @dev Minimum amount constant to prevent division by zero.
    uint256 private constant MIN_AMOUNT = 1000;

    /**
     * @notice Settles the pending liquidity within the BinLiquidity.
     * @dev This function settles pending liquidity in the BinLiquidity storage by performing the following steps:
     *      1. Settles pending liquidity
     *          - If the pending oracle version is not set or is greater than or equal to the current oracle version,
     *            no action is taken.
     *          - Otherwise, the pending liquidity and burning CLB tokens are settled by following steps:
     *              a. If there is a pending deposit,
     *                 it calculates the minting amount of CLB tokens
     *                 based on the pending deposit, bin value, and CLB token total supply.
     *                 It updates the total liquidity and adds the pending deposit to the claim mintings.
     *              b. If there is a pending CLB token burning,
     *                 it adds the oracle version to the burning versions list
     *                 and initializes the claim burning details.
     *      2. Settles bunding CLB tokens
     *          a. It trims all completed burning versions from the burning versions list.
     *          b. For each burning version in the list,
     *             it calculates the pending CLB token amount and the pending withdrawal amount
     *             based on the bin value and CLB token total supply.
     *             - If there is sufficient free liquidity, it calculates the burning amount of CLB tokens.
     *             - If there is insufficient free liquidity, it calculates the burning amount
     *               based on the available free liquidity and updates the pending withdrawal accordingly.
     *          c. It updates the burning amount and pending withdrawal,
     *             and reduces the free liquidity accordingly.
     *          d. Finally, it updates the total liquidity by subtracting the pending withdrawal.
     *      And the CLB tokens are minted or burned accordingly.
     *      The pending deposit and withdrawal amounts are passed to the vault for further processing.
     * @param self The BinLiquidity storage.
     * @param ctx The LpContext memory.
     * @param binValue The current value of the bin.
     * @param freeLiquidity The amount of free liquidity available in the bin.
     * @param clbTokenId The ID of the CLB token.
     */
    function settlePendingLiquidity(
        BinLiquidity storage self,
        LpContext memory ctx,
        uint256 binValue,
        uint256 freeLiquidity,
        uint256 clbTokenId
    ) internal {
        ICLBToken clbToken = ctx.clbToken;
        //slither-disable-next-line calls-loop
        uint256 totalSupply = clbToken.totalSupply(clbTokenId);

        (uint256 pendingDeposit, uint256 mintingAmount) = _settlePending(
            self,
            ctx,
            binValue,
            totalSupply
        );
        (uint256 burningAmount, uint256 pendingWithdrawal) = _settleBurning(
            self,
            freeLiquidity + pendingDeposit,
            binValue,
            totalSupply
        );

        if (mintingAmount > burningAmount) {
            //slither-disable-next-line calls-loop
            clbToken.mint(ctx.market, clbTokenId, mintingAmount - burningAmount, bytes(""));
        } else if (mintingAmount < burningAmount) {
            //slither-disable-next-line calls-loop
            clbToken.burn(ctx.market, clbTokenId, burningAmount - mintingAmount);
        }

        if (pendingDeposit != 0 || pendingWithdrawal != 0) {
            //slither-disable-next-line calls-loop
            ctx.vault.onSettlePendingLiquidity(
                ctx.settlementToken,
                pendingDeposit,
                pendingWithdrawal
            );
        }
    }

    /**
     * @notice Adds liquidity to the BinLiquidity.
     * @dev Sets the pending liquidity with the specified amount and oracle version.
     *      Throws an error with the code `Errors.TOO_SMALL_AMOUNT` if the amount is too small.
     *      Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if there is already pending liquidity with a different oracle version, it reverts with an error.
     * @param self The BinLiquidity storage.
     * @param amount The amount of tokens to add for liquidity.
     * @param oracleVersion The oracle version associated with the liquidity.
     */
    function onAddLiquidity(
        BinLiquidity storage self,
        uint256 amount,
        uint256 oracleVersion
    ) internal {
        require(amount > MIN_AMOUNT, Errors.TOO_SMALL_AMOUNT);

        uint256 pendingOracleVersion = self._pending.oracleVersion;
        require(
            pendingOracleVersion == 0 || pendingOracleVersion == oracleVersion,
            Errors.INVALID_ORACLE_VERSION
        );

        self._pending.oracleVersion = oracleVersion;
        self._pending.mintingTokenAmountRequested += amount;
    }

    /**
     * @notice Claims liquidity from the BinLiquidity by minting CLB tokens.
     * @dev Retrieves the minting details for the specified oracle version
     *      and calculates the CLB token amount to be claimed.
     *      Updates the claim minting details and returns the CLB token amount to be claimed.
     *      If there are no more tokens remaining for the claim, it is removed from the mapping.
     * @param self The BinLiquidity storage.
     * @param amount The amount of tokens to claim.
     * @param oracleVersion The oracle version associated with the claim.
     * @return clbTokenAmount The amount of CLB tokens to be claimed.
     */
    function onClaimLiquidity(
        BinLiquidity storage self,
        uint256 amount,
        uint256 oracleVersion
    ) internal returns (uint256 clbTokenAmount) {
        _ClaimMinting memory _cm = self._claimMintings[oracleVersion];
        clbTokenAmount = amount.mulDiv(_cm.clbTokenAmount, _cm.tokenAmountRequested);

        _cm.clbTokenAmount -= clbTokenAmount;
        _cm.tokenAmountRequested -= amount;
        if (_cm.tokenAmountRequested == 0) {
            delete self._claimMintings[oracleVersion];
        } else {
            self._claimMintings[oracleVersion] = _cm;
        }
    }

    /**
     * @notice Removes liquidity from the BinLiquidity by setting pending CLB token amount.
     * @dev Sets the pending liquidity with the specified CLB token amount and oracle version.
     *      Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if there is already pending liquidity with a different oracle version, it reverts with an error.
     * @param self The BinLiquidity storage.
     * @param clbTokenAmount The amount of CLB tokens to remove liquidity.
     * @param oracleVersion The oracle version associated with the liquidity.
     */
    function onRemoveLiquidity(
        BinLiquidity storage self,
        uint256 clbTokenAmount,
        uint256 oracleVersion
    ) internal {
        uint256 pendingOracleVersion = self._pending.oracleVersion;
        require(
            pendingOracleVersion == 0 || pendingOracleVersion == oracleVersion,
            Errors.INVALID_ORACLE_VERSION
        );

        self._pending.oracleVersion = oracleVersion;
        self._pending.burningCLBTokenAmountRequested += clbTokenAmount;
    }

    /**
     * @notice Withdraws liquidity from the BinLiquidity by burning CLB tokens and withdrawing tokens.
     * @dev Retrieves the burning details for the specified oracle version
     *      and calculates the CLB token amount and token amount to burn and withdraw, respectively.
     *      Updates the claim burning details and returns the token amount to withdraw and the burned CLB token amount.
     *      If there are no more CLB tokens remaining for the claim, it is removed from the mapping.
     * @param self The BinLiquidity storage.
     * @param clbTokenAmount The amount of CLB tokens to withdraw.
     * @param oracleVersion The oracle version associated with the claim.
     * @return amount The amount of tokens to be withdrawn for the claim.
     * @return burnedCLBTokenAmount The amount of CLB tokens to be burned for the claim.
     */
    function onWithdrawLiquidity(
        BinLiquidity storage self,
        uint256 clbTokenAmount,
        uint256 oracleVersion
    ) internal returns (uint256 amount, uint256 burnedCLBTokenAmount) {
        _ClaimBurning memory _cb = self._claimBurnings[oracleVersion];
        amount = clbTokenAmount.mulDiv(_cb.tokenAmount, _cb.clbTokenAmountRequested);
        burnedCLBTokenAmount = clbTokenAmount.mulDiv(
            _cb.clbTokenAmount,
            _cb.clbTokenAmountRequested
        );

        _cb.clbTokenAmount -= burnedCLBTokenAmount;
        _cb.tokenAmount -= amount;
        _cb.clbTokenAmountRequested -= clbTokenAmount;
        if (_cb.clbTokenAmountRequested == 0) {
            delete self._claimBurnings[oracleVersion];
        } else {
            self._claimBurnings[oracleVersion] = _cb;
        }
    }

    /**
     * @notice Calculates the amount of CLB tokens to be minted
     *         for a given token amount, bin value, and CLB token total supply.
     * @dev If the CLB token total supply is zero, returns the token amount as is.
     *      Otherwise, calculates the minting amount
     *      based on the token amount, bin value, and CLB token total supply.
     * @param amount The amount of tokens to be minted.
     * @param binValue The current bin value.
     * @param clbTokenTotalSupply The total supply of CLB tokens.
     * @return The amount of CLB tokens to be minted.
     */
    function calculateCLBTokenMinting(
        uint256 amount,
        uint256 binValue,
        uint256 clbTokenTotalSupply
    ) internal pure returns (uint256) {
        return
            clbTokenTotalSupply == 0
                ? amount
                : amount.mulDiv(clbTokenTotalSupply, binValue < MIN_AMOUNT ? MIN_AMOUNT : binValue);
    }

    /**
     * @notice Calculates the value of CLB tokens
     *         for a given CLB token amount, bin value, and CLB token total supply.
     * @dev If the CLB token total supply is zero, returns zero.
     *      Otherwise, calculates the value based on the CLB token amount, bin value, and CLB token total supply.
     * @param clbTokenAmount The amount of CLB tokens.
     * @param binValue The current bin value.
     * @param clbTokenTotalSupply The total supply of CLB tokens.
     * @return The value of the CLB tokens.
     */
    function calculateCLBTokenValue(
        uint256 clbTokenAmount,
        uint256 binValue,
        uint256 clbTokenTotalSupply
    ) internal pure returns (uint256) {
        return clbTokenTotalSupply == 0 ? 0 : clbTokenAmount.mulDiv(binValue, clbTokenTotalSupply);
    }

    /**
     * @dev Settles the pending deposit and pending CLB token burning.
     * @param self The BinLiquidity storage.
     * @param ctx The LpContext.
     * @param binValue The current value of the bin.
     * @param totalSupply The total supply of CLB tokens.
     * @return pendingDeposit The amount of pending deposit to be settled.
     * @return mintingAmount The calculated minting amount of CLB tokens for the pending deposit.
     */
    function _settlePending(
        BinLiquidity storage self,
        LpContext memory ctx,
        uint256 binValue,
        uint256 totalSupply
    ) private returns (uint256 pendingDeposit, uint256 mintingAmount) {
        uint256 oracleVersion = self._pending.oracleVersion;
        if (!ctx.isPastVersion(oracleVersion)) return (0, 0);

        pendingDeposit = self._pending.mintingTokenAmountRequested;
        uint256 pendingCLBTokenAmount = self._pending.burningCLBTokenAmountRequested;

        if (pendingDeposit != 0) {
            mintingAmount = calculateCLBTokenMinting(pendingDeposit, binValue, totalSupply);

            self.total += pendingDeposit;
            self._claimMintings[oracleVersion] = _ClaimMinting({
                tokenAmountRequested: pendingDeposit,
                clbTokenAmount: mintingAmount
            });
        }

        if (pendingCLBTokenAmount != 0) {
            self._burningVersions.pushBack(bytes32(oracleVersion));
            self._claimBurnings[oracleVersion] = _ClaimBurning({
                clbTokenAmountRequested: pendingCLBTokenAmount,
                clbTokenAmount: 0,
                tokenAmount: 0
            });
        }

        delete self._pending;
    }

    /**
     * @dev Settles the pending CLB token burning and calculates the burning amount and pending withdrawal.
     * @param self The BinLiquidity storage.
     * @param freeLiquidity The amount of free liquidity available for burning.
     * @param binValue The current value of the bin.
     * @param totalSupply The total supply of CLB tokens.
     * @return burningAmount The calculated burning amount of CLB tokens.
     * @return pendingWithdrawal The calculated pending withdrawal amount.
     */
    function _settleBurning(
        BinLiquidity storage self,
        uint256 freeLiquidity,
        uint256 binValue,
        uint256 totalSupply
    ) private returns (uint256 burningAmount, uint256 pendingWithdrawal) {
        // trim all claim completed burning versions
        while (!self._burningVersions.empty()) {
            uint256 _ov = uint256(self._burningVersions.front());
            _ClaimBurning memory _cb = self._claimBurnings[_ov];
            if (_cb.clbTokenAmount >= _cb.clbTokenAmountRequested) {
                //slither-disable-next-line unused-return
                self._burningVersions.popFront();
                if (_cb.clbTokenAmountRequested == 0) {
                    delete self._claimBurnings[_ov];
                }
            } else {
                break;
            }
        }

        uint256 length = self._burningVersions.length();
        for (uint256 i; i < length && freeLiquidity != 0; ) {
            uint256 _ov = uint256(self._burningVersions.at(i));
            _ClaimBurning storage _cb = self._claimBurnings[_ov];

            uint256 _pendingCLBTokenAmount = _cb.clbTokenAmountRequested - _cb.clbTokenAmount;
            if (_pendingCLBTokenAmount != 0) {
                uint256 _burningAmount;
                uint256 _pendingWithdrawal = calculateCLBTokenValue(
                    _pendingCLBTokenAmount,
                    binValue,
                    totalSupply
                );

                if (freeLiquidity >= _pendingWithdrawal) {
                    _burningAmount = _pendingCLBTokenAmount;
                } else {
                    _burningAmount = calculateCLBTokenMinting(freeLiquidity, binValue, totalSupply);
                    require(_burningAmount < _pendingCLBTokenAmount);
                    _pendingWithdrawal = freeLiquidity;
                }

                _cb.clbTokenAmount += _burningAmount;
                _cb.tokenAmount += _pendingWithdrawal;
                burningAmount += _burningAmount;
                pendingWithdrawal += _pendingWithdrawal;
                freeLiquidity -= _pendingWithdrawal;
            }

            unchecked {
                i++;
            }
        }

        self.total -= pendingWithdrawal;
    }

    /**
     * @dev Retrieves the pending liquidity information.
     * @param self The reference to the BinLiquidity struct.
     * @return pendingLiquidity An instance of IMarketLiquidity.PendingLiquidity representing the pending liquidity information.
     */
    function pendingLiquidity(
        BinLiquidity storage self
    ) internal view returns (IMarketLiquidity.PendingLiquidity memory) {
        return self._pending;
    }

    /**
     * @dev Retrieves the claimable liquidity information for a specific oracle version.
     * @param self The reference to the BinLiquidity struct.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of IMarketLiquidity.ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        BinLiquidity storage self,
        uint256 oracleVersion
    ) internal view returns (IMarketLiquidity.ClaimableLiquidity memory) {
        _ClaimMinting memory _cm = self._claimMintings[oracleVersion];
        _ClaimBurning memory _cb = self._claimBurnings[oracleVersion];

        return
            IMarketLiquidity.ClaimableLiquidity({
                mintingTokenAmountRequested: _cm.tokenAmountRequested,
                mintingCLBTokenAmount: _cm.clbTokenAmount,
                burningCLBTokenAmountRequested: _cb.clbTokenAmountRequested,
                burningCLBTokenAmount: _cb.clbTokenAmount,
                burningTokenAmount: _cb.tokenAmount
            });
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {AccruedInterest, AccruedInterestLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/AccruedInterest.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @dev Represents a pending position within the LiquidityBin
 * @param openVersion The oracle version when the position was opened.
 * @param totalQty The total quantity of the pending position.
 * @param totalMakerMargin The total maker margin of the pending position.
 * @param totalTakerMargin The total taker margin of the pending position.
 * @param accruedInterest The accumulated interest of the pending position.
 */
struct BinPendingPosition {
    uint256 openVersion;
    int256 totalQty;
    uint256 totalMakerMargin;
    uint256 totalTakerMargin;
    AccruedInterest accruedInterest;
}

/**
 * @title BinPendingPositionLib
 * @notice Library for managing pending positions in the `LiquidityBin`
 */
library BinPendingPositionLib {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;
    using AccruedInterestLib for AccruedInterest;

    /**
     * @notice Settles the accumulated interest of the pending position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     */
    function settleAccruedInterest(BinPendingPosition storage self, LpContext memory ctx) internal {
        self.accruedInterest.accumulate(ctx, self.totalMakerMargin, block.timestamp);
    }

    /**
     * @notice Handles the opening of a position.
     * @dev Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if the `openVersion` is not valid.
     * @param self The BinPendingPosition storage.
     * @param param The position parameters.
     */
    function onOpenPosition(
        BinPendingPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        uint256 openVersion = self.openVersion;
        require(
            openVersion == 0 || openVersion == param.openVersion,
            Errors.INVALID_ORACLE_VERSION
        );

        int256 totalQty = self.totalQty;
        int256 qty = param.qty;
        PositionUtil.checkAddPositionQty(totalQty, qty);

        // accumulate interest before update `totalMakerMargin`
        settleAccruedInterest(self, ctx);

        self.openVersion = param.openVersion;
        self.totalQty = totalQty + qty;
        self.totalMakerMargin += param.makerMargin;
        self.totalTakerMargin += param.takerMargin;
    }

    /**
     * @notice Handles the closing of a position.
     * @dev Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if the `openVersion` is not valid.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @param param The position parameters.
     */
    function onClosePosition(
        BinPendingPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        require(self.openVersion == param.openVersion, Errors.INVALID_ORACLE_VERSION);

        int256 totalQty = self.totalQty;
        int256 qty = param.qty;
        PositionUtil.checkRemovePositionQty(totalQty, qty);

        // accumulate interest before update `totalMakerMargin`
        settleAccruedInterest(self, ctx);

        self.totalQty = totalQty - qty;
        self.totalMakerMargin -= param.makerMargin;
        self.totalTakerMargin -= param.takerMargin;
        self.accruedInterest.deduct(param.calculateInterest(ctx, block.timestamp));
    }

    /**
     * @notice Calculates the unrealized profit or loss (PnL) of the pending position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @return uint256 The unrealized PnL.
     */
    function unrealizedPnl(
        BinPendingPosition storage self,
        LpContext memory ctx
    ) internal view returns (int256) {
        uint256 openVersion = self.openVersion;
        if (!ctx.isPastVersion(openVersion)) return 0;

        IOracleProvider.OracleVersion memory currentVersion = ctx.currentOracleVersion();
        uint256 _entryPrice = PositionUtil.settlePrice(
            ctx.oracleProvider,
            openVersion,
            ctx.currentOracleVersion()
        );
        uint256 _exitPrice = PositionUtil.oraclePrice(currentVersion);

        int256 pnl = PositionUtil.pnl(self.totalQty, _entryPrice, _exitPrice) +
            currentInterest(self, ctx).toInt256();
        uint256 absPnl = pnl.abs();

        //slither-disable-next-line timestamp
        if (pnl >= 0) {
            return Math.min(absPnl, self.totalTakerMargin).toInt256();
        } else {
            return -(Math.min(absPnl, self.totalMakerMargin).toInt256());
        }
    }

    /**
     * @notice Calculates the current accrued interest of the pending position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @return uint256 The current accrued interest.
     */
    function currentInterest(
        BinPendingPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return self.accruedInterest.calculateInterest(ctx, self.totalMakerMargin, block.timestamp);
    }

    /**
     * @notice Calculates the entry price of the pending position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @return uint256 The entry price.
     */
    function entryPrice(
        BinPendingPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return
            PositionUtil.settlePrice(
                ctx.oracleProvider,
                self.openVersion,
                ctx.currentOracleVersion()
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {AccruedInterest, AccruedInterestLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/AccruedInterest.sol";
import {BinPendingPosition, BinPendingPositionLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinPendingPosition.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";

/**
 * @dev Represents a position in the LiquidityBin
 * @param totalQty The total quantity of the `LiquidityBin`
 * @param totalEntryAmount The total entry amount of the `LiquidityBin`
 * @param _totalMakerMargin The total maker margin of the `LiquidityBin`
 * @param _totalTakerMargin The total taker margin of the `LiquidityBin`
 * @param _pending The pending position of the `LiquidityBin`
 * @param _accruedInterest The accumulated interest of the `LiquidityBin`
 */
struct BinPosition {
    int256 totalQty;
    uint256 totalEntryAmount;
    uint256 _totalMakerMargin;
    uint256 _totalTakerMargin;
    BinPendingPosition _pending;
    AccruedInterest _accruedInterest;
}

/**
 * @title BinPositionLib
 * @notice Library for managing positions in the `LiquidityBin`
 */
library BinPositionLib {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;
    using AccruedInterestLib for AccruedInterest;
    using BinPendingPositionLib for BinPendingPosition;

    /**
     * @notice Settles pending positions for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     */
    function settlePendingPosition(BinPosition storage self, LpContext memory ctx) internal {
        uint256 openVersion = self._pending.openVersion;
        if (!ctx.isPastVersion(openVersion)) return;

        // accumulate interest before update `_totalMakerMargin`
        self._accruedInterest.accumulate(ctx, self._totalMakerMargin, block.timestamp);

        int256 pendingQty = self._pending.totalQty;
        self.totalQty += pendingQty;
        self.totalEntryAmount += PositionUtil.transactionAmount(
            pendingQty,
            self._pending.entryPrice(ctx)
        );
        self._totalMakerMargin += self._pending.totalMakerMargin;
        self._totalTakerMargin += self._pending.totalTakerMargin;

        self._pending.settleAccruedInterest(ctx);
        self._accruedInterest.accumulatedAmount += self._pending.accruedInterest.accumulatedAmount;

        delete self._pending;
    }

    /**
     * @notice Handles the opening of a position for a liquidity bin.
     * @param self The BinPosition storage.
     * @param ctx The LpContext data struct.
     * @param param The PositionParam containing the position parameters.
     */
    function onOpenPosition(
        BinPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        self._pending.onOpenPosition(ctx, param);
    }

    /**
     * @notice Handles the closing of a position for a liquidity bin.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     * @param param The PositionParam data struct containing the position parameters.
     */
    function onClosePosition(
        BinPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        if (param.openVersion == self._pending.openVersion) {
            self._pending.onClosePosition(ctx, param);
        } else {
            int256 totalQty = self.totalQty;
            int256 qty = param.qty;
            PositionUtil.checkRemovePositionQty(totalQty, qty);

            // accumulate interest before update `_totalMakerMargin`
            self._accruedInterest.accumulate(ctx, self._totalMakerMargin, block.timestamp);

            self.totalQty = totalQty - qty;
            self.totalEntryAmount -= param.entryAmount(ctx);
            self._totalMakerMargin -= param.makerMargin;
            self._totalTakerMargin -= param.takerMargin;
            self._accruedInterest.deduct(param.calculateInterest(ctx, block.timestamp));
        }
    }

    /**
     * @notice Returns the total maker margin for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @return uint256 The total maker margin.
     */
    function totalMakerMargin(BinPosition storage self) internal view returns (uint256) {
        return self._totalMakerMargin + self._pending.totalMakerMargin;
    }

    /**
     * @notice Returns the total taker margin for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @return uint256 The total taker margin.
     */
    function totalTakerMargin(BinPosition storage self) internal view returns (uint256) {
        return self._totalTakerMargin + self._pending.totalTakerMargin;
    }

    /**
     * @notice Calculates the unrealized profit or loss for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return int256 The unrealized profit or loss.
     */
    function unrealizedPnl(
        BinPosition storage self,
        LpContext memory ctx
    ) internal view returns (int256) {
        IOracleProvider.OracleVersion memory currentVersion = ctx.currentOracleVersion();

        int256 qty = self.totalQty;
        int256 sign = qty < 0 ? int256(-1) : int256(1);
        uint256 exitPrice = PositionUtil.oraclePrice(currentVersion);

        int256 entryAmount = self.totalEntryAmount.toInt256() * sign;
        int256 exitAmount = PositionUtil.transactionAmount(qty, exitPrice).toInt256() * sign;

        int256 rawPnl = exitAmount - entryAmount;
        int256 pnl = rawPnl +
            self._pending.unrealizedPnl(ctx) +
            _currentInterest(self, ctx).toInt256();
        uint256 absPnl = pnl.abs();

        //slither-disable-next-line timestamp
        if (pnl >= 0) {
            return Math.min(absPnl, totalTakerMargin(self)).toInt256();
        } else {
            return -(Math.min(absPnl, totalMakerMargin(self)).toInt256());
        }
    }

    /**
     * @dev Calculates the current interest for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return uint256 The current interest.
     */
    function currentInterest(
        BinPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return _currentInterest(self, ctx) + self._pending.currentInterest(ctx);
    }

    /**
     * @dev Calculates the current interest for a liquidity bin position without pending position.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return uint256 The current interest.
     */
    function _currentInterest(
        BinPosition storage self,
        LpContext memory ctx
    ) private view returns (uint256) {
        return
            self._accruedInterest.calculateInterest(ctx, self._totalMakerMargin, block.timestamp);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {BinLiquidity, BinLiquidityLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinLiquidity.sol";
import {BinPosition, BinPositionLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinPosition.sol";
import {BinClosedPosition, BinClosedPositionLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinClosedPosition.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";
/**
 * @dev Structure representing a liquidity bin
 * @param clbTokenId The ID of the CLB token
 * @param _liquidity The liquidity data for the bin
 * @param _position The position data for the bin
 * @param _closedPosition The closed position data for the bin
 */
struct LiquidityBin {
    uint256 clbTokenId;
    BinLiquidity _liquidity;
    BinPosition _position;
    BinClosedPosition _closedPosition;
}

/**
 * @title LiquidityBinLib
 * @notice Library for managing liquidity bin
 */
library LiquidityBinLib {
    using Math for uint256;
    using SignedMath for int256;
    using LiquidityBinLib for LiquidityBin;
    using BinLiquidityLib for BinLiquidity;
    using BinPositionLib for BinPosition;
    using BinClosedPositionLib for BinClosedPosition;

    /**
     * @notice Modifier to settle the pending positions, closing positions,
     *         and pending liquidity of the bin before executing a function.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext data struct.
     */
    modifier _settle(LiquidityBin storage self, LpContext memory ctx) {
        self.settle(ctx);
        _;
    }

    /**
     * @notice Settles the pending positions, closing positions, and pending liquidity of the bin.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext data struct.
     */
    function settle(LiquidityBin storage self, LpContext memory ctx) internal {
        self._closedPosition.settleClosingPosition(ctx);
        self._position.settlePendingPosition(ctx);
        self._liquidity.settlePendingLiquidity(
            ctx,
            self.value(ctx),
            self.freeLiquidity(),
            self.clbTokenId
        );
    }

    /**
     * @notice Initializes the liquidity bin with the given trading fee rate
     * @param self The LiquidityBin storage
     * @param tradingFeeRate The trading fee rate to set
     */
    function initialize(LiquidityBin storage self, int16 tradingFeeRate) internal {
        self.clbTokenId = CLBTokenLib.encodeId(tradingFeeRate);
    }

    /**
     * @notice Opens a new position in the liquidity bin
     * @dev Throws an error with the code `Errors.NOT_ENOUGH_FREE_LIQUIDITY` if there is not enough free liquidity.
     * @param self The LiquidityBin storage
     * @param ctx The LpContext data struct
     * @param param The position parameters
     * @param tradingFee The trading fee amount
     */
    function openPosition(
        LiquidityBin storage self,
        LpContext memory ctx,
        PositionParam memory param,
        uint256 tradingFee
    ) internal {
        require(param.makerMargin <= self.freeLiquidity(), Errors.NOT_ENOUGH_FREE_LIQUIDITY);

        self._position.onOpenPosition(ctx, param);
        self._liquidity.total += tradingFee;
    }

    /**
     * @notice Closes a position in the liquidity bin
     * @param self The LiquidityBin storage
     * @param ctx The LpContext data struct
     * @param param The position parameters
     */
    function closePosition(
        LiquidityBin storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal _settle(self, ctx) {
        self._position.onClosePosition(ctx, param);
        if (param.closeVersion > param.openVersion) {
            self._closedPosition.onClosePosition(ctx, param);
        }
    }

    /**
     * @notice Claims an existing liquidity position in the bin.
     * @dev This function claims the position using the specified parameters
     *      and updates the total by subtracting the absolute value
     *      of the taker's profit or loss (takerPnl) from it.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param param The PositionParam memory.
     * @param takerPnl The taker's profit/loss.
     */
    function claimPosition(
        LiquidityBin storage self,
        LpContext memory ctx,
        PositionParam memory param,
        int256 takerPnl
    ) internal _settle(self, ctx) {
        if (param.closeVersion == 0) {
            // called when liquidate
            self._position.onClosePosition(ctx, param);
        } else if (param.closeVersion > param.openVersion) {
            self._closedPosition.onClaimPosition(ctx, param);
        }

        uint256 absTakerPnl = takerPnl.abs();
        if (takerPnl < 0) {
            self._liquidity.total += absTakerPnl;
        } else {
            self._liquidity.total -= absTakerPnl;
        }
    }

    /**
     * @notice Retrieves the total liquidity in the bin
     * @param self The LiquidityBin storage
     * @return uint256 The total liquidity in the bin
     */
    function liquidity(LiquidityBin storage self) internal view returns (uint256) {
        return self._liquidity.total;
    }

    /**
     * @notice Retrieves the free liquidity in the bin (liquidity minus total maker margin)
     * @param self The LiquidityBin storage
     * @return uint256 The free liquidity in the bin
     */
    function freeLiquidity(LiquidityBin storage self) internal view returns (uint256) {
        return
            self._liquidity.total -
            self._position.totalMakerMargin() -
            self._closedPosition.totalMakerMargin();
    }

    /**
     * @notice Applies earnings to the liquidity bin
     * @param self The LiquidityBin storage
     * @param earning The earning amount to apply
     */
    function applyEarning(LiquidityBin storage self, uint256 earning) internal {
        self._liquidity.total += earning;
    }

    /**
     * @notice Calculates the value of the bin.
     * @dev This function considers the unrealized profit or loss of the position
     *      and adds it to the total value.
     *      Additionally, it includes the pending bin share from the market's vault.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @return uint256 The value of the bin.
     */
    function value(
        LiquidityBin storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        int256 unrealizedPnl = self._position.unrealizedPnl(ctx);

        uint256 absPnl = unrealizedPnl.abs();

        uint256 _liquidity = self.liquidity();
        uint256 _value = unrealizedPnl < 0 ? _liquidity - absPnl : _liquidity + absPnl;
        return
            _value +
            self._closedPosition.currentInterest(ctx) +
            ctx.vault.getPendingBinShare(ctx.market, ctx.settlementToken, _liquidity);
    }

    /**
     * @notice Accepts an add liquidity request.
     * @dev This function adds liquidity to the bin by calling the `onAddLiquidity` function
     *      of the liquidity component.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param amount The amount of liquidity to add.
     */
    function acceptAddLiquidity(
        LiquidityBin storage self,
        LpContext memory ctx,
        uint256 amount
    ) internal _settle(self, ctx) {
        self._liquidity.onAddLiquidity(amount, ctx.currentOracleVersion().version);
    }

    /**
     * @notice Accepts a claim liquidity request.
     * @dev This function claims liquidity from the bin by calling the `onClaimLiquidity` function
     *      of the liquidity component.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param amount The amount of liquidity to claim.
     *        (should be the same as the one used in acceptAddLiquidity)
     * @param oracleVersion The oracle version used for the claim.
     *        (should be the oracle version when call acceptAddLiquidity)
     * @return The amount of liquidity (CLB tokens) received as a result of the liquidity claim.
     */
    function acceptClaimLiquidity(
        LiquidityBin storage self,
        LpContext memory ctx,
        uint256 amount,
        uint256 oracleVersion
    ) internal _settle(self, ctx) returns (uint256) {
        return self._liquidity.onClaimLiquidity(amount, oracleVersion);
    }

    /**
     * @notice Accepts a remove liquidity request.
     * @dev This function removes liquidity from the bin by calling the `onRemoveLiquidity` function
     *      of the liquidity component.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param clbTokenAmount The amount of CLB tokens to remove.
     */
    function acceptRemoveLiquidity(
        LiquidityBin storage self,
        LpContext memory ctx,
        uint256 clbTokenAmount
    ) internal _settle(self, ctx) {
        self._liquidity.onRemoveLiquidity(clbTokenAmount, ctx.currentOracleVersion().version);
    }

    /**
     * @notice Accepts a withdraw liquidity request.
     * @dev This function withdraws liquidity from the bin by calling the `onWithdrawLiquidity` function
     *      of the liquidity component.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param clbTokenAmount The amount of CLB tokens to withdraw.
     *        (should be the same as the one used in acceptRemoveLiquidity)
     * @param oracleVersion The oracle version used for the withdrawal.
     *        (should be the oracle version when call acceptRemoveLiquidity)
     * @return amount The amount of liquidity withdrawn
     * @return burnedCLBTokenAmount The amount of CLB tokens burned during the withdrawal.
     */
    function acceptWithdrawLiquidity(
        LiquidityBin storage self,
        LpContext memory ctx,
        uint256 clbTokenAmount,
        uint256 oracleVersion
    ) internal _settle(self, ctx) returns (uint256 amount, uint256 burnedCLBTokenAmount) {
        (amount, burnedCLBTokenAmount) = self._liquidity.onWithdrawLiquidity(
            clbTokenAmount,
            oracleVersion
        );
    }

    /**
     * @dev Retrieves the pending liquidity information from a LiquidityBin.
     * @param self The reference to the LiquidityBin struct.
     * @return pendingLiquidity An instance of IMarketLiquidity.PendingLiquidity representing the pending liquidity information.
     */
    function pendingLiquidity(
        LiquidityBin storage self
    ) internal view returns (IMarketLiquidity.PendingLiquidity memory) {
        return self._liquidity.pendingLiquidity();
    }

    /**
     * @dev Retrieves the claimable liquidity information for a specific oracle version from a LiquidityBin.
     * @param self The reference to the LiquidityBin struct.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of IMarketLiquidity.ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        LiquidityBin storage self,
        uint256 oracleVersion
    ) internal view returns (IMarketLiquidity.ClaimableLiquidity memory) {
        return self._liquidity.claimableLiquidity(oracleVersion);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {LiquidityBin, LiquidityBinLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/LiquidityBin.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {FEE_RATES_LENGTH} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";
import {BinMargin} from "@chromatic-protocol/contracts/core/libraries/BinMargin.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @dev Represents a collection of long and short liquidity bins
 */
struct LiquidityPool {
    mapping(uint16 => LiquidityBin) _longBins;
    mapping(uint16 => LiquidityBin) _shortBins;
}

using LiquidityPoolLib for LiquidityPool global;

/**
 * @title LiquidityPoolLib
 * @notice Library for managing liquidity bins in an LiquidityPool
 */
library LiquidityPoolLib {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;
    using LiquidityBinLib for LiquidityBin;

    /**
     * @notice Emitted when earning is accumulated for a liquidity bin.
     * @param feeRate The fee rate of the bin.
     * @param binType The type of the bin ("L" for long, "S" for short).
     * @param earning The accumulated earning.
     */
    event LiquidityBinEarningAccumulated(
        uint16 indexed feeRate,
        bytes1 indexed binType,
        uint256 indexed earning
    );

    struct _proportionalPositionParamValue {
        int256 qty;
        uint256 takerMargin;
    }

    /**
     * @notice Modifier to validate the trading fee rate.
     * @param tradingFeeRate The trading fee rate to validate.
     */
    modifier _validTradingFeeRate(int16 tradingFeeRate) {
        validateTradingFeeRate(tradingFeeRate);

        _;
    }

    /**
     * @notice Initializes the LiquidityPool.
     * @param self The reference to the LiquidityPool.
     */
    function initialize(LiquidityPool storage self) internal {
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();
        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            uint16 feeRate = _tradingFeeRates[i];
            self._longBins[feeRate].initialize(int16(feeRate));
            self._shortBins[feeRate].initialize(-int16(feeRate));

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Settles the liquidity bins in the LiquidityPool.
     * @param self The reference to the LiquidityPool.
     * @param ctx The LpContext object.
     */
    function settle(LiquidityPool storage self, LpContext memory ctx) internal {
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();
        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            uint16 feeRate = _tradingFeeRates[i];
            self._longBins[feeRate].settle(ctx);
            self._shortBins[feeRate].settle(ctx);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Prepares bin margins based on the given quantity and maker margin.
     * @dev This function prepares bin margins by performing the following steps:
     *      1. Calculates the appropriate bin margins
     *         for each trading fee rate based on the provided quantity and maker margin.
     *      2. Iterates through the target bins based on the quantity,
     *         finds the minimum available fee rate,
     *         and determines the upper bound for calculating bin margins.
     *      3. Iterates from the minimum fee rate until the upper bound,
     *         assigning the remaining maker margin to the bins until it is exhausted.
     *      4. Creates an array of BinMargin structs
     *         containing the trading fee rate and corresponding margin amount for each bin.
     *      Throws an error with the code `Errors.NOT_ENOUGH_FREE_LIQUIDITY` if there is not enough free liquidity.
     * @param self The reference to the LiquidityPool.
     * @param ctx The LpContext data struct
     * @param qty The quantity of the position.
     * @param makerMargin The maker margin of the position.
     * @return binMargins An array of BinMargin representing the calculated bin margins.
     */
    function prepareBinMargins(
        LiquidityPool storage self,
        LpContext memory ctx,
        int256 qty,
        uint256 makerMargin,
        uint256 minimumBinMargin
    ) internal returns (BinMargin[] memory) {
        // Retrieve the target liquidity bins based on the position quantity
        mapping(uint16 => LiquidityBin) storage _bins = targetBins(self, qty);

        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();
        //slither-disable-next-line uninitialized-local
        uint256[FEE_RATES_LENGTH] memory _binMargins;

        //slither-disable-next-line uninitialized-local
        uint256 to;
        //slither-disable-next-line uninitialized-local
        uint256 cnt;
        uint256 remain = makerMargin;
        for (; to < FEE_RATES_LENGTH; to++) {
            if (remain == 0) break;

            LiquidityBin storage _bin = _bins[_tradingFeeRates[to]];
            _bin.settle(ctx);

            uint256 freeLiquidity = _bin.freeLiquidity();
            if (freeLiquidity >= minimumBinMargin) {
                if (remain <= freeLiquidity) {
                    _binMargins[to] = remain;
                    remain = 0;
                } else {
                    _binMargins[to] = freeLiquidity;
                    remain -= freeLiquidity;
                }
                cnt++;
            }
        }

        require(remain == 0, Errors.NOT_ENOUGH_FREE_LIQUIDITY);

        BinMargin[] memory binMargins = new BinMargin[](cnt);
        for ((uint256 i, uint256 idx) = (0, 0); i < to; i++) {
            if (_binMargins[i] != 0) {
                binMargins[idx] = BinMargin({
                    tradingFeeRate: _tradingFeeRates[i],
                    amount: _binMargins[i]
                });

                unchecked {
                    idx++;
                }
            }
        }

        return binMargins;
    }

    /**
     * @notice Accepts an open position and opens corresponding liquidity bins.
     * @dev This function calculates the target liquidity bins based on the position quantity.
     *      It prepares the bin margins and divides the position parameters accordingly.
     *      Then, it opens the liquidity bins with the corresponding parameters and trading fees.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param position The Position object representing the open position.
     */
    function acceptOpenPosition(
        LiquidityPool storage self,
        LpContext memory ctx,
        Position memory position
    ) internal {
        // Retrieve the target liquidity bins based on the position quantity
        mapping(uint16 => LiquidityBin) storage _bins = targetBins(self, position.qty);

        uint256 makerMargin = position.makerMargin();
        BinMargin[] memory binMargins = position.binMargins();

        // Divide the position parameters to match the bin margins
        _proportionalPositionParamValue[] memory paramValues = divideToPositionParamValue(
            position.qty,
            makerMargin,
            position.takerMargin,
            binMargins
        );

        PositionParam memory param = newPositionParam(position.openVersion, position.openTimestamp);
        for (uint256 i; i < binMargins.length; ) {
            BinMargin memory binMargin = binMargins[i];

            if (binMargin.amount != 0) {
                param.qty = paramValues[i].qty;
                param.takerMargin = paramValues[i].takerMargin;
                param.makerMargin = binMargin.amount;

                _bins[binMargins[i].tradingFeeRate].openPosition(
                    ctx,
                    param,
                    binMargin.tradingFee(position._feeProtocol)
                );
            }

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Accepts a close position request and closes the corresponding liquidity bins.
     * @dev This function calculates the target liquidity bins based on the position quantity.
     *      It retrieves the maker margin and bin margins from the position.
     *      Then, it divides the position parameters to match the bin margins.
     *      Finally, it closes the liquidity bins with the provided parameters.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param position The Position object representing the close position request.
     */
    function acceptClosePosition(
        LiquidityPool storage self,
        LpContext memory ctx,
        Position memory position
    ) internal {
        // Retrieve the target liquidity bins based on the position quantity
        mapping(uint16 => LiquidityBin) storage _bins = targetBins(self, position.qty);

        uint256 makerMargin = position.makerMargin();
        BinMargin[] memory binMargins = position.binMargins();

        // Divide the position parameters to match the bin margins
        _proportionalPositionParamValue[] memory paramValues = divideToPositionParamValue(
            position.qty,
            makerMargin,
            position.takerMargin,
            binMargins
        );

        PositionParam memory param = newPositionParam(
            position.openVersion,
            position.closeVersion,
            position.openTimestamp,
            position.closeTimestamp
        );

        for (uint256 i; i < binMargins.length; ) {
            if (binMargins[i].amount != 0) {
                LiquidityBin storage _bin = _bins[binMargins[i].tradingFeeRate];

                param.qty = paramValues[i].qty;
                param.takerMargin = paramValues[i].takerMargin;
                param.makerMargin = binMargins[i].amount;

                _bin.closePosition(ctx, param);
            }

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Accepts a claim position request and processes the corresponding liquidity bins
     *         based on the realized position pnl.
     * @dev This function verifies if the absolute value of the realized position pnl is within the acceptable margin range.
     *      It retrieves the target liquidity bins based on the position quantity and the bin margins from the position.
     *      Then, it divides the position parameters to match the bin margins.
     *      Depending on the value of the realized position pnl, it either claims the position fully or partially.
     *      The claimed pnl is distributed among the liquidity bins according to their respective margins.
     *      Throws an error with the code `Errors.EXCEED_MARGIN_RANGE` if the realized profit or loss does not falls within the acceptable margin range.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param position The Position object representing the position to claim.
     * @param realizedPnl The realized position pnl (taker side).
     */
    function acceptClaimPosition(
        LiquidityPool storage self,
        LpContext memory ctx,
        Position memory position,
        int256 realizedPnl // realized position pnl (taker side)
    ) internal {
        uint256 absRealizedPnl = realizedPnl.abs();
        uint256 makerMargin = position.makerMargin();
        // Ensure that the realized position pnl is within the acceptable margin range
        require(
            !((realizedPnl > 0 && absRealizedPnl > makerMargin) ||
                (realizedPnl < 0 && absRealizedPnl > position.takerMargin)),
            Errors.EXCEED_MARGIN_RANGE
        );

        // Retrieve the target liquidity bins based on the position quantity
        mapping(uint16 => LiquidityBin) storage _bins = targetBins(self, position.qty);
        BinMargin[] memory binMargins = position.binMargins();

        // Divide the position parameters to match the bin margins
        _proportionalPositionParamValue[] memory paramValues = divideToPositionParamValue(
            position.qty,
            makerMargin,
            position.takerMargin,
            binMargins
        );

        PositionParam memory param = newPositionParam(
            position.openVersion,
            position.closeVersion,
            position.openTimestamp,
            position.closeTimestamp
        );

        if (realizedPnl == 0) {
            for (uint256 i; i < binMargins.length; ) {
                if (binMargins[i].amount != 0) {
                    LiquidityBin storage _bin = _bins[binMargins[i].tradingFeeRate];

                    param.qty = paramValues[i].qty;
                    param.takerMargin = paramValues[i].takerMargin;
                    param.makerMargin = binMargins[i].amount;

                    _bin.claimPosition(ctx, param, 0);
                }

                unchecked {
                    i++;
                }
            }
        } else if (realizedPnl > 0 && absRealizedPnl == makerMargin) {
            for (uint256 i; i < binMargins.length; ) {
                if (binMargins[i].amount != 0) {
                    LiquidityBin storage _bin = _bins[binMargins[i].tradingFeeRate];

                    param.qty = paramValues[i].qty;
                    param.takerMargin = paramValues[i].takerMargin;
                    param.makerMargin = binMargins[i].amount;

                    _bin.claimPosition(ctx, param, param.makerMargin.toInt256());
                }

                unchecked {
                    i++;
                }
            }
        } else {
            uint256 remainMakerMargin = makerMargin;
            uint256 remainRealizedPnl = absRealizedPnl;

            for (uint256 i; i < binMargins.length; ) {
                if (binMargins[i].amount != 0) {
                    LiquidityBin storage _bin = _bins[binMargins[i].tradingFeeRate];

                    param.qty = paramValues[i].qty;
                    param.takerMargin = paramValues[i].takerMargin;
                    param.makerMargin = binMargins[i].amount;

                    uint256 absTakerPnl = remainRealizedPnl.mulDiv(
                        param.makerMargin,
                        remainMakerMargin
                    );
                    if (realizedPnl < 0) {
                        // maker profit
                        absTakerPnl = Math.min(absTakerPnl, param.takerMargin);
                    } else {
                        // taker profit
                        absTakerPnl = Math.min(absTakerPnl, param.makerMargin);
                    }

                    int256 takerPnl = realizedPnl < 0
                        ? -(absTakerPnl.toInt256())
                        : absTakerPnl.toInt256();

                    _bin.claimPosition(ctx, param, takerPnl);

                    remainMakerMargin -= param.makerMargin;
                    remainRealizedPnl -= absTakerPnl;
                }

                unchecked {
                    i++;
                }
            }

            require(remainRealizedPnl == 0, Errors.EXCEED_MARGIN_RANGE);
        }
    }

    /**
     * @notice Accepts an add liquidity request
     *         and processes the liquidity bin corresponding to the given trading fee rate.
     * @dev This function validates the trading fee rate
     *      and calls the acceptAddLiquidity function on the target liquidity bin.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @param amount The amount of liquidity to add.
     */
    function acceptAddLiquidity(
        LiquidityPool storage self,
        LpContext memory ctx,
        int16 tradingFeeRate,
        uint256 amount
    ) internal _validTradingFeeRate(tradingFeeRate) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Process the add liquidity request on the liquidity bin
        bin.acceptAddLiquidity(ctx, amount);
    }

    /**
     * @notice Accepts a claim liquidity request
     *         and processes the liquidity bin corresponding to the given trading fee rate.
     * @dev This function validates the trading fee rate
     *      and calls the acceptClaimLiquidity function on the target liquidity bin.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @param amount The amount of liquidity to claim.
     *        (should be the same as the one used in acceptAddLiquidity)
     * @param oracleVersion The oracle version used for the claim.
     *        (should be the oracle version when call acceptAddLiquidity)
     * @return The amount of liquidity (CLB tokens) received as a result of the liquidity claim.
     */
    function acceptClaimLiquidity(
        LiquidityPool storage self,
        LpContext memory ctx,
        int16 tradingFeeRate,
        uint256 amount,
        uint256 oracleVersion
    ) internal _validTradingFeeRate(tradingFeeRate) returns (uint256) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Process the claim liquidity request on the liquidity bin and return the actual claimed amount
        return bin.acceptClaimLiquidity(ctx, amount, oracleVersion);
    }

    /**
     * @notice Accepts a remove liquidity request
     *         and processes the liquidity bin corresponding to the given trading fee rate.
     * @dev This function validates the trading fee rate
     *      and calls the acceptRemoveLiquidity function on the target liquidity bin.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @param clbTokenAmount The amount of CLB tokens to remove.
     */
    function acceptRemoveLiquidity(
        LiquidityPool storage self,
        LpContext memory ctx,
        int16 tradingFeeRate,
        uint256 clbTokenAmount
    ) internal _validTradingFeeRate(tradingFeeRate) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Process the remove liquidity request on the liquidity bin
        bin.acceptRemoveLiquidity(ctx, clbTokenAmount);
    }

    /**
     * @notice Accepts a withdraw liquidity request
     *         and processes the liquidity bin corresponding to the given trading fee rate.
     * @dev This function validates the trading fee rate
     *      and calls the acceptWithdrawLiquidity function on the target liquidity bin.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @param clbTokenAmount The amount of CLB tokens to withdraw.
     *        (should be the same as the one used in acceptRemoveLiquidity)
     * @param oracleVersion The oracle version used for the withdrawal.
     *        (should be the oracle version when call acceptRemoveLiquidity)
     * @return amount The amount of base tokens withdrawn
     * @return burnedCLBTokenAmount the amount of CLB tokens burned.
     */
    function acceptWithdrawLiquidity(
        LiquidityPool storage self,
        LpContext memory ctx,
        int16 tradingFeeRate,
        uint256 clbTokenAmount,
        uint256 oracleVersion
    )
        internal
        _validTradingFeeRate(tradingFeeRate)
        returns (uint256 amount, uint256 burnedCLBTokenAmount)
    {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Process the withdraw liquidity request on the liquidity bin
        // and get the amount of base tokens withdrawn and CLB tokens burned
        (amount, burnedCLBTokenAmount) = bin.acceptWithdrawLiquidity(
            ctx,
            clbTokenAmount,
            oracleVersion
        );
    }

    /**
     * @notice Retrieves the total liquidity amount in base tokens for the specified trading fee rate.
     * @dev This function retrieves the liquidity bin based on the trading fee rate
     *      and calls the liquidity function on it.
     * @param self The reference to the LiquidityPool storage.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @return amount The total liquidity amount in base tokens.
     */
    function getBinLiquidity(
        LiquidityPool storage self,
        int16 tradingFeeRate
    ) internal view returns (uint256 amount) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Get the total liquidity amount in base tokens from the liquidity bin
        return bin.liquidity();
    }

    /**
     * @notice Retrieves the free liquidity amount in base tokens for the specified trading fee rate.
     * @dev This function retrieves the liquidity bin based on the trading fee rate
     *      and calls the freeLiquidity function on it.
     * @param self The reference to the LiquidityPool storage.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @return amount The free liquidity amount in base tokens.
     */
    function getBinFreeLiquidity(
        LiquidityPool storage self,
        int16 tradingFeeRate
    ) internal view returns (uint256 amount) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Get the free liquidity amount in base tokens from the liquidity bin
        return bin.freeLiquidity();
    }

    /**
     * @notice Retrieves the target bins based on the sign of the given value.
     * @dev This function retrieves the target bins mapping (short or long) based on the sign of the given value.
     * @param self The storage reference to the LiquidityPool.
     * @param sign The sign of the value (-1 for negative, 1 for positive).
     * @return _bins The target bins mapping associated with the sign of the value.
     */
    function targetBins(
        LiquidityPool storage self,
        int256 sign
    ) private view returns (mapping(uint16 => LiquidityBin) storage) {
        return sign < 0 ? self._shortBins : self._longBins;
    }

    /**
     * @notice Retrieves the target bin based on the trading fee rate.
     * @dev This function retrieves the target bin based on the sign of the trading fee rate and returns it.
     * @param self The storage reference to the LiquidityPool.
     * @param tradingFeeRate The trading fee rate associated with the bin.
     * @return bin The target bin associated with the trading fee rate.
     */
    function targetBin(
        LiquidityPool storage self,
        int16 tradingFeeRate
    ) private view returns (LiquidityBin storage) {
        return
            tradingFeeRate < 0
                ? self._shortBins[abs(tradingFeeRate)]
                : self._longBins[abs(tradingFeeRate)];
    }

    /**
     * @notice Divides the quantity, maker margin, and taker margin into proportional position parameter values.
     * @dev This function divides the quantity, maker margin, and taker margin
     *      into proportional position parameter values based on the bin margins.
     *      It calculates the proportional values for each bin margin and returns them in an array.
     * @param qty The position quantity.
     * @param makerMargin The maker margin amount.
     * @param takerMargin The taker margin amount.
     * @param binMargins The array of bin margins.
     * @return values The array of proportional position parameter values.
     */
    function divideToPositionParamValue(
        int256 qty,
        uint256 makerMargin,
        uint256 takerMargin,
        BinMargin[] memory binMargins
    ) private pure returns (_proportionalPositionParamValue[] memory) {
        uint256 remainQty = qty.abs();
        uint256 remainTakerMargin = takerMargin;

        _proportionalPositionParamValue[] memory values = new _proportionalPositionParamValue[](
            binMargins.length
        );

        for (uint256 i; i < binMargins.length - 1; ) {
            uint256 _qty = remainQty.mulDiv(binMargins[i].amount, makerMargin);
            uint256 _takerMargin = remainTakerMargin.mulDiv(binMargins[i].amount, makerMargin);

            values[i] = _proportionalPositionParamValue({
                qty: qty < 0 ? _qty.toInt256() : -(_qty.toInt256()), // opposit side
                takerMargin: _takerMargin
            });

            remainQty -= _qty;
            remainTakerMargin -= _takerMargin;

            unchecked {
                i++;
            }
        }

        values[binMargins.length - 1] = _proportionalPositionParamValue({
            qty: qty < 0 ? remainQty.toInt256() : -(remainQty.toInt256()), // opposit side
            takerMargin: remainTakerMargin
        });

        return values;
    }

    /**
     * @notice Creates a new PositionParam struct with the given oracle version and timestamp.
     * @param openVersion The version of the oracle when the position was opened
     * @param openTimestamp The timestamp when the position was opened
     * @return param The new PositionParam struct.
     */
    function newPositionParam(
        uint256 openVersion,
        uint256 openTimestamp
    ) private pure returns (PositionParam memory param) {
        param.openVersion = openVersion;
        param.openTimestamp = openTimestamp;
    }

    /**
     * @notice Creates a new PositionParam struct with the given oracle version and timestamp.
     * @param openVersion The version of the oracle when the position was opened
     * @param closeVersion The version of the oracle when the position was closed
     * @param openTimestamp The timestamp when the position was opened
     * @param closeTimestamp The timestamp when the position was closed
     * @return param The new PositionParam struct.
     */
    function newPositionParam(
        uint256 openVersion,
        uint256 closeVersion,
        uint256 openTimestamp,
        uint256 closeTimestamp
    ) private pure returns (PositionParam memory param) {
        param.openVersion = openVersion;
        param.closeVersion = closeVersion;
        param.openTimestamp = openTimestamp;
        param.closeTimestamp = closeTimestamp;
    }

    /**
     * @notice Validates the trading fee rate.
     * @dev This function validates the trading fee rate by checking if it is supported.
     *      It compares the absolute value of the fee rate with the predefined trading fee rates
     *      to determine if it is a valid rate.
     *      Throws an error with the code `Errors.UNSUPPORTED_TRADING_FEE_RATE` if the trading fee rate is not supported.
     * @param tradingFeeRate The trading fee rate to be validated.
     */
    function validateTradingFeeRate(int16 tradingFeeRate) private pure {
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();

        uint16 absFeeRate = abs(tradingFeeRate);

        uint256 idx = findUpperBound(_tradingFeeRates, absFeeRate);
        require(
            idx < _tradingFeeRates.length && absFeeRate == _tradingFeeRates[idx],
            Errors.UNSUPPORTED_TRADING_FEE_RATE
        );
    }

    /**
     * @notice Calculates the absolute value of an int16 number.
     * @param i The int16 number.
     * @return absValue The absolute value of the input number.
     */
    function abs(int16 i) private pure returns (uint16) {
        return i < 0 ? uint16(-i) : uint16(i);
    }

    /**
     * @notice Finds the upper bound index of an element in a sorted array.
     * @dev This function performs a binary search on the sorted array
     *      to find * the index of the upper bound of the given element.
     *      It returns the index as the exclusive upper bound,
     *      or the inclusive upper bound if the element is found at the end of the array.
     * @param array The sorted array.
     * @param element The element to find the upper bound for.
     * @return uint256 The index of the upper bound of the element in the array.
     */
    function findUpperBound(
        uint16[FEE_RATES_LENGTH] memory array,
        uint16 element
    ) private pure returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low != 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @notice Distributes earnings among the liquidity bins.
     * @dev This function distributes the earnings among the liquidity bins,
     *      proportional to their total balances.
     *      It iterates through the trading fee rates
     *      and distributes the proportional amount of earnings to each bin
     *      based on its total balance relative to the market balance.
     * @param self The LiquidityPool storage.
     * @param earning The total earnings to be distributed.
     * @param marketBalance The market balance.
     */
    function distributeEarning(
        LiquidityPool storage self,
        uint256 earning,
        uint256 marketBalance
    ) internal {
        uint256 remainEarning = earning;
        uint256 remainBalance = marketBalance;
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();

        (remainEarning, remainBalance) = distributeEarning(
            self._longBins,
            remainEarning,
            remainBalance,
            _tradingFeeRates,
            "L"
        );
        (remainEarning, remainBalance) = distributeEarning(
            self._shortBins,
            remainEarning,
            remainBalance,
            _tradingFeeRates,
            "S"
        );
    }

    /**
     * @notice Distributes earnings among the liquidity bins of a specific type.
     * @dev This function distributes the earnings among the liquidity bins of
     *      the specified type, proportional to their total balances.
     *      It iterates through the trading fee rates
     *      and distributes the proportional amount of earnings to each bin
     *      based on its total balance relative to the market balance.
     * @param bins The liquidity bins mapping.
     * @param earning The total earnings to be distributed.
     * @param marketBalance The market balance.
     * @param _tradingFeeRates The array of supported trading fee rates.
     * @param binType The type of liquidity bin ("L" for long, "S" for short).
     * @return remainEarning The remaining earnings after distribution.
     * @return remainBalance The remaining market balance after distribution.
     */
    function distributeEarning(
        mapping(uint16 => LiquidityBin) storage bins,
        uint256 earning,
        uint256 marketBalance,
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates,
        bytes1 binType
    ) private returns (uint256 remainEarning, uint256 remainBalance) {
        remainBalance = marketBalance;
        remainEarning = earning;

        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            uint16 feeRate = _tradingFeeRates[i];
            LiquidityBin storage bin = bins[feeRate];
            uint256 binLiquidity = bin.liquidity();

            if (binLiquidity == 0) {
                unchecked {
                    i++;
                }
                continue;
            }

            uint256 binEarning = remainEarning.mulDiv(binLiquidity, remainBalance);

            bin.applyEarning(binEarning);

            remainBalance -= binLiquidity;
            remainEarning -= binEarning;

            emit LiquidityBinEarningAccumulated(feeRate, binType, binEarning);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Retrieves the value of a specific bin in the LiquidityPool storage for the provided trading fee rate.
     * @param self The reference to the LiquidityPool storage.
     * @param _tradingFeeRate The trading fee rate for which to calculate the bin value.
     * @param ctx The LP context containing relevant information for the calculation.
     * @return value The value of the specified bin.
     */
    function binValue(
        LiquidityPool storage self,
        int16 _tradingFeeRate,
        LpContext memory ctx
    ) internal view returns (uint256 value) {
        value = targetBin(self, _tradingFeeRate).value(ctx);
    }

    /**
     * @dev Retrieves the pending liquidity information for a specific trading fee rate from a LiquidityPool.
     * @param self The reference to the LiquidityPool struct.
     * @param tradingFeeRate The trading fee rate for which to retrieve the pending liquidity.
     * @return pendingLiquidity An instance of IMarketLiquidity.PendingLiquidity representing the pending liquidity information.
     */
    function pendingLiquidity(
        LiquidityPool storage self,
        int16 tradingFeeRate
    )
        internal
        view
        _validTradingFeeRate(tradingFeeRate)
        returns (IMarketLiquidity.PendingLiquidity memory)
    {
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        return bin.pendingLiquidity();
    }

    /**
     * @dev Retrieves the claimable liquidity information for a specific trading fee rate and oracle version from a LiquidityPool.
     * @param self The reference to the LiquidityPool struct.
     * @param tradingFeeRate The trading fee rate for which to retrieve the claimable liquidity.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of IMarketLiquidity.ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        LiquidityPool storage self,
        int16 tradingFeeRate,
        uint256 oracleVersion
    )
        internal
        view
        _validTradingFeeRate(tradingFeeRate)
        returns (IMarketLiquidity.ClaimableLiquidity memory)
    {
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        return bin.claimableLiquidity(oracleVersion);
    }

    /**
     * @dev Retrieves the liquidity bin statuses for the LiquidityPool using the provided context.
     * @param self The LiquidityPool storage instance.
     * @param ctx The LpContext containing the necessary context for calculating the bin statuses.
     * @return stats An array of IMarketLiquidity.LiquidityBinStatus representing the liquidity bin statuses.
     */
    function liquidityBinStatuses(
        LiquidityPool storage self,
        LpContext memory ctx
    ) internal view returns (IMarketLiquidity.LiquidityBinStatus[] memory) {
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();

        IMarketLiquidity.LiquidityBinStatus[]
            memory stats = new IMarketLiquidity.LiquidityBinStatus[](FEE_RATES_LENGTH * 2);
        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            uint16 _feeRate = _tradingFeeRates[i];
            LiquidityBin storage longBin = targetBin(self, int16(_feeRate));
            LiquidityBin storage shortBin = targetBin(self, -int16(_feeRate));

            stats[i] = IMarketLiquidity.LiquidityBinStatus({
                tradingFeeRate: int16(_feeRate),
                liquidity: longBin.liquidity(),
                freeLiquidity: longBin.freeLiquidity(),
                binValue: longBin.value(ctx)
            });
            stats[i + FEE_RATES_LENGTH] = IMarketLiquidity.LiquidityBinStatus({
                tradingFeeRate: -int16(_feeRate),
                liquidity: shortBin.liquidity(),
                freeLiquidity: shortBin.freeLiquidity(),
                binValue: shortBin.value(ctx)
            });

            unchecked {
                i++;
            }
        }

        return stats;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";

/**
 * @dev A struct representing the parameters of a position.
 * @param openVersion The version of the position's open transaction
 * @param closeVersion The version of the position's close transaction
 * @param qty The quantity of the position
 * @param takerMargin The margin amount provided by the taker
 * @param makerMargin The margin amount provided by the maker
 * @param openTimestamp The timestamp of the position's open transaction
 * @param closeTimestamp The timestamp of the position's close transaction
 * @param _entryVersionCache Caches the settle oracle version for the position's entry
 * @param _exitVersionCache Caches the settle oracle version for the position's exit
 */
struct PositionParam {
    uint256 openVersion;
    uint256 closeVersion;
    int256 qty;
    uint256 takerMargin;
    uint256 makerMargin;
    uint256 openTimestamp;
    uint256 closeTimestamp;
    IOracleProvider.OracleVersion _entryVersionCache;
    IOracleProvider.OracleVersion _exitVersionCache;
}

using PositionParamLib for PositionParam global;

/**
 * @title PositionParamLib
 * @notice Library for manipulating PositionParam struct.
 */
library PositionParamLib {
    using Math for uint256;
    using SignedMath for int256;

    /**
     * @notice Returns the settle version for the position's entry.
     * @param self The PositionParam struct.
     * @return uint256 The settle version for the position's entry.
     */
    function entryVersion(PositionParam memory self) internal pure returns (uint256) {
        return PositionUtil.settleVersion(self.openVersion);
    }

    /**
     * @notice Calculates the entry price for a PositionParam.
     * @param self The PositionParam struct.
     * @param ctx The LpContext struct.
     * @return uint256 The entry price.
     */
    function entryPrice(
        PositionParam memory self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return
            PositionUtil.settlePrice(
                ctx.oracleProvider,
                self.openVersion,
                self.entryOracleVersion(ctx)
            );
    }

    /**
     * @notice Calculates the entry amount for a PositionParam.
     * @param self The PositionParam struct.
     * @param ctx The LpContext struct.
     * @return uint256 The entry amount.
     */
    function entryAmount(
        PositionParam memory self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return PositionUtil.transactionAmount(self.qty, self.entryPrice(ctx));
    }

    /**
     * @notice Retrieves the settle oracle version for the position's entry.
     * @param self The PositionParam struct.
     * @param ctx The LpContext struct.
     * @return OracleVersion The settle oracle version for the position's entry.
     */
    function entryOracleVersion(
        PositionParam memory self,
        LpContext memory ctx
    ) internal view returns (IOracleProvider.OracleVersion memory) {
        if (self._entryVersionCache.version == 0) {
            self._entryVersionCache = ctx.oracleVersionAt(self.entryVersion());
        }
        return self._entryVersionCache;
    }

    /**
     * @dev Calculates the interest for a PositionParam until a specified timestamp.
     * @dev It is used only to deduct accumulated accrued interest when close position
     * @param self The PositionParam struct.
     * @param ctx The LpContext struct.
     * @param until The timestamp until which to calculate the interest.
     * @return uint256 The calculated interest.
     */
    function calculateInterest(
        PositionParam memory self,
        LpContext memory ctx,
        uint256 until
    ) internal view returns (uint256) {
        return ctx.calculateInterest(self.makerMargin, self.openTimestamp, until);
    }

    /**
     * @notice Creates a clone of a PositionParam.
     * @param self The PositionParam data struct.
     * @return PositionParam The cloned PositionParam.
     */
    function clone(PositionParam memory self) internal pure returns (PositionParam memory) {
        return
            PositionParam({
                openVersion: self.openVersion,
                closeVersion: self.closeVersion,
                qty: self.qty,
                takerMargin: self.takerMargin,
                makerMargin: self.makerMargin,
                openTimestamp: self.openTimestamp,
                closeTimestamp: self.closeTimestamp,
                _entryVersionCache: self._entryVersionCache,
                _exitVersionCache: self._exitVersionCache
            });
    }

    /**
     * @notice Creates the inverse of a PositionParam by negating the qty.
     * @param self The PositionParam data struct.
     * @return PositionParam The inverted PositionParam.
     */
    function inverse(PositionParam memory self) internal pure returns (PositionParam memory) {
        PositionParam memory param = self.clone();
        param.qty *= -1;
        return param;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {IInterestCalculator} from "@chromatic-protocol/contracts/core/interfaces/IInterestCalculator.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";

/**
 * @dev Represents the context information required for LP bin operations.
 * @param oracleProvider The Oracle Provider contract used for price feed
 * @param interestCalculator The Interest Calculator contract used for interest calculations
 * @param vault The Chromatic Vault contract responsible for managing liquidity and margin
 * @param clbToken The CLB token contract that represents LP ownership in the pool
 * @param market The address of market contract
 * @param settlementToken The address of the settlement token used in the market
 * @param tokenPrecision The precision of the settlement token used in the market
 * @param _currentVersionCache Cached instance of the current oracle version
 */
struct LpContext {
    IOracleProvider oracleProvider;
    IInterestCalculator interestCalculator;
    IChromaticVault vault;
    ICLBToken clbToken;
    address market;
    address settlementToken;
    uint256 tokenPrecision;
    IOracleProvider.OracleVersion _currentVersionCache;
}

using LpContextLib for LpContext global;

/**
 * @title LpContextLib
 * @notice Provides functions that operate on the `LpContext` struct
 */
library LpContextLib {
    /**
     * @notice Syncs the oracle version used by the market.
     * @param self The memory instance of `LpContext` struct
     */
    function syncOracleVersion(LpContext memory self) internal {
        self._currentVersionCache = self.oracleProvider.sync();
    }

    /**
     * @notice Retrieves the current oracle version used by the market
     * @dev If the `_currentVersionCache` has been initialized, then returns it.
     *      If not, it calls the `currentVersion` function on the `oracleProvider of the market
     *      to fetch the current version and stores it in the cache,
     *      and then returns the current version.
     * @param self The memory instance of `LpContext` struct
     * @return OracleVersion The current oracle version
     */
    function currentOracleVersion(
        LpContext memory self
    ) internal view returns (IOracleProvider.OracleVersion memory) {
        if (self._currentVersionCache.version == 0) {
            //slither-disable-next-line calls-loop
            self._currentVersionCache = self.oracleProvider.currentVersion();
        }

        return self._currentVersionCache;
    }

    /**
     * @notice Retrieves the oracle version at a specific version number
     * @dev If the `_currentVersionCache` matches the requested version, then returns it.
     *      Otherwise, it calls the `atVersion` function on the `oracleProvider` of the market
     *      to fetch the desired version.
     * @param self The memory instance of `LpContext` struct
     * @param version The requested version number
     * @return OracleVersion The oracle version at the requested version number
     */
    function oracleVersionAt(
        LpContext memory self,
        uint256 version
    ) internal view returns (IOracleProvider.OracleVersion memory) {
        if (self._currentVersionCache.version == version) {
            return self._currentVersionCache;
        }
        return self.oracleProvider.atVersion(version);
    }

    /**
     * @notice Calculates the interest accrued for a given amount of settlement tokens
               within a specified time range.
     * @dev This function internally calls the `calculateInterest` function on the `interestCalculator` contract.
     * @param self The memory instance of the `LpContext` struct.
     * @param amount The amount of settlement tokens for which the interest needs to be calculated.
     * @param from The starting timestamp of the time range (inclusive).
     * @param to The ending timestamp of the time range (exclusive).
     * @return The accrued interest as a `uint256` value.
     */
    function calculateInterest(
        LpContext memory self,
        uint256 amount,
        uint256 from,
        uint256 to
    ) internal view returns (uint256) {
        //slither-disable-next-line calls-loop
        return
            amount == 0 || from >= to
                ? 0
                : self.interestCalculator.calculateInterest(self.settlementToken, amount, from, to);
    }

    /**
     * @notice Checks if an oracle version is in the past.
     * @param self The memory instance of the `LpContext` struct.
     * @param oracleVersion The oracle version to check.
     * @return A boolean value indicating whether the oracle version is in the past.
     */
    function isPastVersion(
        LpContext memory self,
        uint256 oracleVersion
    ) internal view returns (bool) {
        return oracleVersion != 0 && oracleVersion < self.currentOracleVersion().version;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";

/**
 * @dev The LpAction enum represents the types of LP actions that can be performed.
 */
enum LpAction {
    ADD_LIQUIDITY,
    REMOVE_LIQUIDITY
}

/**
 * @dev The LpReceipt struct represents a receipt of an LP action performed.
 * @param id An identifier for the receipt
 * @param oracleVersion The oracle version associated with the action
 * @param amount The amount involved in the action,
 *        when the action is `ADD_LIQUIDITY`, this value represents the amount of settlement tokens
 *        when the action is `REMOVE_LIQUIDITY`, this value represents the amount of CLB tokens
 * @param recipient The address of the recipient of the action
 * @param action An enumeration representing the type of LP action performed (ADD_LIQUIDITY or REMOVE_LIQUIDITY)
 * @param tradingFeeRate The trading fee rate associated with the LP action
 */
struct LpReceipt {
    uint256 id;
    uint256 oracleVersion;
    uint256 amount;
    address recipient;
    LpAction action;
    int16 tradingFeeRate;
}

using LpReceiptLib for LpReceipt global;

/**
 * @title LpReceiptLib
 * @notice Provides functions that operate on the `LpReceipt` struct
 */
library LpReceiptLib {
    /**
     * @notice Computes the ID of the CLBToken contract based on the trading fee rate.
     * @param self The LpReceipt struct.
     * @return The ID of the CLBToken contract.
     */
    function clbTokenId(LpReceipt memory self) internal pure returns (uint256) {
        return CLBTokenLib.encodeId(self.tradingFeeRate);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IChromaticLiquidator} from "@chromatic-protocol/contracts/core/interfaces/IChromaticLiquidator.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";
import {LiquidityPool} from "@chromatic-protocol/contracts/core/libraries/liquidity/LiquidityPool.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {BinMargin} from "@chromatic-protocol/contracts/core/libraries/BinMargin.sol";

struct MarketStorage {
    IChromaticMarketFactory factory;
    IOracleProvider oracleProvider;
    IERC20Metadata settlementToken;
    ICLBToken clbToken;
    IChromaticLiquidator liquidator;
    IChromaticVault vault;
    IKeeperFeePayer keeperFeePayer;
    LiquidityPool liquidityPool;
    uint8 feeProtocol;
}

struct LpReceiptStorage {
    uint256 lpReceiptId;
    mapping(uint256 => LpReceipt) lpReceipts;
}

struct PositionStorage {
    uint256 positionId;
    mapping(uint256 => Position) positions;
}

library MarketStorageLib {
    bytes32 constant MARKET_STORAGE_POSITION = keccak256("protocol.chromatic.market.storage");

    function marketStorage() internal pure returns (MarketStorage storage ms) {
        bytes32 position = MARKET_STORAGE_POSITION;
        assembly {
            ms.slot := position
        }
    }
}

using LpReceiptStorageLib for LpReceiptStorage global;

library LpReceiptStorageLib {
    bytes32 constant LP_RECEIPT_STORAGE_POSITION =
        keccak256("protocol.chromatic.lpreceipt.storage");

    function lpReceiptStorage() internal pure returns (LpReceiptStorage storage ls) {
        bytes32 position = LP_RECEIPT_STORAGE_POSITION;
        assembly {
            ls.slot := position
        }
    }

    function nextId(LpReceiptStorage storage self) internal returns (uint256 id) {
        id = ++self.lpReceiptId;
    }

    function setReceipt(LpReceiptStorage storage self, LpReceipt memory receipt) internal {
        self.lpReceipts[receipt.id] = receipt;
    }

    function getReceipt(
        LpReceiptStorage storage self,
        uint256 receiptId
    ) internal view returns (LpReceipt memory receipt) {
        receipt = self.lpReceipts[receiptId];
    }

    function deleteReceipt(LpReceiptStorage storage self, uint256 receiptId) internal {
        delete self.lpReceipts[receiptId];
    }

    function deleteReceipts(LpReceiptStorage storage self, uint256[] memory receiptIds) internal {
        for (uint256 i; i < receiptIds.length; ) {
            delete self.lpReceipts[receiptIds[i]];

            unchecked {
                i++;
            }
        }
    }
}

using PositionStorageLib for PositionStorage global;

library PositionStorageLib {
    bytes32 constant POSITION_STORAGE_POSITION = keccak256("protocol.chromatic.position.storage");

    function positionStorage() internal pure returns (PositionStorage storage ls) {
        bytes32 position = POSITION_STORAGE_POSITION;
        assembly {
            ls.slot := position
        }
    }

    function nextId(PositionStorage storage self) internal returns (uint256 id) {
        id = ++self.positionId;
    }

    function setPosition(PositionStorage storage self, Position memory position) internal {
        Position storage _p = self.positions[position.id];

        _p.id = position.id;
        _p.openVersion = position.openVersion;
        _p.closeVersion = position.closeVersion;
        _p.qty = position.qty;
        _p.openTimestamp = position.openTimestamp;
        _p.closeTimestamp = position.closeTimestamp;
        _p.takerMargin = position.takerMargin;
        _p.owner = position.owner;
        _p._feeProtocol = position._feeProtocol;
        // can not convert memory array to storage array
        delete _p._binMargins;
        for (uint i; i < position._binMargins.length; ) {
            BinMargin memory binMargin = position._binMargins[i];
            if (binMargin.amount != 0) {
                _p._binMargins.push(position._binMargins[i]);
            }

            unchecked {
                i++;
            }
        }
    }

    function getPosition(
        PositionStorage storage self,
        uint256 positionId
    ) internal view returns (Position memory position) {
        position = self.positions[positionId];
    }

    function getStoragePosition(
        PositionStorage storage self,
        uint256 positionId
    ) internal view returns (Position storage position) {
        position = self.positions[positionId];
    }

    function deletePosition(PositionStorage storage self, uint256 positionId) internal {
        delete self.positions[positionId];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {BinMargin} from "@chromatic-protocol/contracts/core/libraries/BinMargin.sol";

/**
 * @dev The Position struct represents a trading position.
 * @param id The position identifier
 * @param openVersion The version of the oracle when the position was opened
 * @param closeVersion The version of the oracle when the position was closed
 * @param qty The quantity of the position
 * @param openTimestamp The timestamp when the position was opened
 * @param closeTimestamp The timestamp when the position was closed
 * @param takerMargin The amount of collateral that a trader must provide
 * @param owner The owner of the position, usually it is the account address of trader
 * @param _binMargins The bin margins for the position, it represents the amount of collateral for each bin
 * @param _feeProtocol The protocol fee for the market
 */
struct Position {
    uint256 id;
    uint256 openVersion;
    uint256 closeVersion;
    int256 qty;
    uint256 openTimestamp;
    uint256 closeTimestamp;
    uint256 takerMargin;
    address owner;
    BinMargin[] _binMargins;
    uint8 _feeProtocol;
}

using PositionLib for Position global;

/**
 * @title PositionLib
 * @notice Provides functions that operate on the `Position` struct
 */
library PositionLib {
    // using Math for uint256;
    // using SafeCast for uint256;
    // using SignedMath for int256;

    /**
     * @notice Calculates the entry price of the position based on the position's open oracle version
     * @dev It fetches oracle price from `IOracleProvider`
     *      at the settle version calculated based on the position's open oracle version
     * @param self The memory instance of the `Position` struct
     * @param ctx The context object for this transaction
     * @return uint256 The entry price
     */
    function entryPrice(
        Position memory self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return PositionUtil.settlePrice(ctx.oracleProvider, self.openVersion);
    }

    /**
     * @notice Calculates the exit price of the position based on the position's close oracle version
     * @dev It fetches oracle price from `IOracleProvider`
     *      at the settle version calculated based on the position's close oracle version
     * @param self The memory instance of the `Position` struct
     * @param ctx The context object for this transaction
     * @return uint256 The exit price
     */
    function exitPrice(Position memory self, LpContext memory ctx) internal view returns (uint256) {
        return PositionUtil.settlePrice(ctx.oracleProvider, self.closeVersion);
    }

    /**
     * @notice Calculates the profit or loss of the position based on the close oracle version and the qty
     * @param self The memory instance of the `Position` struct
     * @param ctx The context object for this transaction
     * @return int256 The profit or loss
     */
    function pnl(Position memory self, LpContext memory ctx) internal view returns (int256) {
        return
            self.closeVersion > self.openVersion
                ? PositionUtil.pnl(self.qty, self.entryPrice(ctx), self.exitPrice(ctx))
                : int256(0);
    }

    /**
     * @notice Calculates the total margin required for the makers of the position
     * @dev The maker margin is calculated by summing up the amounts of all bin margins
     *      in the `_binMargins` array
     * @param self The memory instance of the `Position` struct
     * @return margin The maker margin
     */
    function makerMargin(Position memory self) internal pure returns (uint256 margin) {
        for (uint256 i; i < self._binMargins.length; ) {
            margin += self._binMargins[i].amount;

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Calculates the total trading fee for the position
     * @dev The trading fee is calculated by summing up the trading fees of all bin margins
     *      in the `_binMargins` array
     * @param self The memory instance of the `Position` struct
     * @return fee The trading fee
     */
    function tradingFee(Position memory self) internal pure returns (uint256 fee) {
        for (uint256 i; i < self._binMargins.length; ) {
            fee += self._binMargins[i].tradingFee(self._feeProtocol);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Calculates the total protocol fee for a position.
     * @param self The Position struct representing the position.
     * @return fee The total protocol fee amount.
     */
    function protocolFee(Position memory self) internal pure returns (uint256 fee) {
        for (uint256 i; i < self._binMargins.length; ) {
            fee += self._binMargins[i].protocolFee(self._feeProtocol);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Returns an array of BinMargin instances
     *         representing the bin margins for the position
     * @param self The memory instance of the `Position` struct
     * @return margins The bin margins for the position
     */
    function binMargins(Position memory self) internal pure returns (BinMargin[] memory margins) {
        margins = self._binMargins;
    }

    /**
     * @notice Sets the `_binMargins` array for the position
     * @param self The memory instance of the `Position` struct
     * @param margins The bin margins for the position
     */
    function setBinMargins(Position memory self, BinMargin[] memory margins) internal pure {
        self._binMargins = margins;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title PositionUtil
 * @notice Provides utility functions for managing positions
 */
library PositionUtil {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;

    uint256 private constant PRICE_PRECISION = 1e18;

    /**
     * @notice Returns next oracle version to settle
     * @dev It adds 1 to the `oracleVersion`
     *      and ensures that the `oracleVersion` is greater than 0 using a require statement.
     *      Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if the `oracleVersion` is not valid.
     * @param oracleVersion Input oracle version
     * @return uint256 Next oracle version to settle
     */
    function settleVersion(uint256 oracleVersion) internal pure returns (uint256) {
        require(oracleVersion != 0, Errors.INVALID_ORACLE_VERSION);
        return oracleVersion + 1;
    }

    /**
     * @notice Calculates the price of the position based on the `oracleVersion` to settle
     * @dev It calls another overloaded `settlePrice` function
     *      with an additional `OracleVersion` parameter,
     *      passing the `currentVersion` obtained from the `provider`
     * @param provider The oracle provider
     * @param oracleVersion The oracle version of position
     * @return uint256 The calculated price to settle
     */
    function settlePrice(
        IOracleProvider provider,
        uint256 oracleVersion
    ) internal view returns (uint256) {
        return settlePrice(provider, oracleVersion, provider.currentVersion());
    }

    /**
     * @notice Calculates the price of the position based on the `oracleVersion` to settle
     * @dev It calculates the price by considering the `settleVersion`
     *      and the `currentVersion` obtained from the `IOracleProvider`.
     *      It ensures that the settle version is not greater than the current version;
     *      otherwise, it triggers an error with the message `Errors.UNSETTLED_POSITION`.
     *      It retrieves the corresponding `OracleVersion` using `atVersion` from the `IOracleProvider`,
     *      and then calls `oraclePrice` to obtain the price.
     * @param provider The oracle provider
     * @param oracleVersion The oracle version of position
     * @param currentVersion The current oracle version
     * @return uint256 The calculated entry price to settle
     */
    function settlePrice(
        IOracleProvider provider,
        uint256 oracleVersion,
        IOracleProvider.OracleVersion memory currentVersion
    ) internal view returns (uint256) {
        uint256 _settleVersion = settleVersion(oracleVersion);
        require(_settleVersion <= currentVersion.version, Errors.UNSETTLED_POSITION);

        //slither-disable-next-line calls-loop
        IOracleProvider.OracleVersion memory _oracleVersion = _settleVersion ==
            currentVersion.version
            ? currentVersion
            : provider.atVersion(_settleVersion);
        return oraclePrice(_oracleVersion);
    }

    /**
     * @notice Extracts the price value from an `OracleVersion` struct
     * @dev If the price is not positive value, it triggers an error with the message `Errors.NOT_POSITIVE_PRICE`.
     * @param oracleVersion The memory instance of `OracleVersion` struct
     * @return uint256 The price value of `oracleVersion`
     */
    function oraclePrice(
        IOracleProvider.OracleVersion memory oracleVersion
    ) internal pure returns (uint256) {
        require(oracleVersion.price > 0, Errors.NOT_POSITIVE_PRICE);
        return oracleVersion.price.abs();
    }

    /**
     * @notice Calculates the profit or loss (PnL) for a position based on the quantity, entry price, and exit price
     * @dev It first calculates the price difference (`delta`) between the exit price and the entry price.
     *      If the quantity is negative, indicating short position, it adjusts the `delta` to reflect a negative change.
     *      The function then calculates the absolute PnL by multiplying the absolute value of the quantity
     *          with the absolute value of the `delta`, divided by the entry price.
     *      Finally, if `delta` is negative, indicating a loss, the absolute PnL is negated to represent a negative value.
     * @param qty The quantity of the position
     * @param _entryPrice The entry price of the position
     * @param _exitPrice The exit price of the position
     * @return int256 The profit or loss
     */
    function pnl(
        int256 qty, // as token precision
        uint256 _entryPrice,
        uint256 _exitPrice
    ) internal pure returns (int256) {
        int256 delta = _exitPrice > _entryPrice
            ? (_exitPrice - _entryPrice).toInt256()
            : -(_entryPrice - _exitPrice).toInt256();
        if (qty < 0) delta *= -1;

        int256 absPnl = qty.abs().mulDiv(delta.abs(), _entryPrice).toInt256();

        return delta < 0 ? -absPnl : absPnl;
    }

    /**
     * @notice Verifies the validity of a position quantity added to the bin
     * @dev It ensures that the sign of the current quantity of the bin's position
     *      and the added quantity are same or zero.
     *      If the condition is not met, it triggers an error with the message `Errors.INVALID_POSITION_QTY`.
     * @param currentQty The current quantity of the bin's pending position
     * @param addedQty The position quantity added
     */
    function checkAddPositionQty(int256 currentQty, int256 addedQty) internal pure {
        require(
            !((currentQty > 0 && addedQty <= 0) || (currentQty < 0 && addedQty >= 0)),
            Errors.INVALID_POSITION_QTY
        );
    }

    /**
     * @notice Verifies the validity of a position quantity removed from the bin
     * @dev It ensures that the sign of the current quantity of the bin's position
     *      and the removed quantity are same or zero,
     *      and the absolute removed quantity is not greater than the absolute current quantity.
     *      If the condition is not met, it triggers an error with the message `Errors.INVALID_POSITION_QTY`.
     * @param currentQty The current quantity of the bin's position
     * @param removeQty The position quantity removed
     */
    function checkRemovePositionQty(int256 currentQty, int256 removeQty) internal pure {
        require(
            !((currentQty == 0) ||
                (removeQty == 0) ||
                (currentQty > 0 && removeQty > currentQty) ||
                (currentQty < 0 && removeQty < currentQty)),
            Errors.INVALID_POSITION_QTY
        );
    }

    /**
     * @notice Calculates the transaction amount based on the quantity and price
     * @param qty The quantity of the position
     * @param price The price of the position
     * @return uint256 The transaction amount
     */
    function transactionAmount(int256 qty, uint256 price) internal pure returns (uint256) {
        return qty.abs().mulDiv(price, PRICE_PRECISION);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @dev A registry for managing oracle providers.
 * @param _oracleProviders Set of registered oracle providers
 */
struct OracleProviderRegistry {
    EnumerableSet.AddressSet _oracleProviders;
    mapping(address => uint32) _minTakeProfitBPSs;
    mapping(address => uint32) _maxTakeProfitBPSs;
    mapping(address => uint8) _leverageLevels;
}

/**
 * @title OracleProviderRegistryLib
 * @notice Library for managing a registry of oracle providers.
 */
library OracleProviderRegistryLib {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Registers an oracle provider in the registry.
     * @dev Throws an error with the code `Errors.ALREADY_REGISTERED_ORACLE_PROVIDER` if the oracle provider is already registered.
     * @param self The OracleProviderRegistry storage.
     * @param oracleProvider The address of the oracle provider to register.
     * @param minTakeProfitBPS The minimum take-profit basis points.
     * @param maxTakeProfitBPS The maximum take-profit basis points.
     * @param leverageLevel The leverage level of the oracle provider.
     */
    function register(
        OracleProviderRegistry storage self,
        address oracleProvider,
        uint32 minTakeProfitBPS,
        uint32 maxTakeProfitBPS,
        uint8 leverageLevel
    ) internal {
        require(
            !self._oracleProviders.contains(oracleProvider),
            Errors.ALREADY_REGISTERED_ORACLE_PROVIDER
        );

        //slither-disable-next-line unused-return
        self._oracleProviders.add(oracleProvider);
        self._minTakeProfitBPSs[oracleProvider] = minTakeProfitBPS;
        self._maxTakeProfitBPSs[oracleProvider] = maxTakeProfitBPS;
        self._leverageLevels[oracleProvider] = leverageLevel;
    }

    /**
     * @notice Unregisters an oracle provider from the registry.
     * @param self The OracleProviderRegistry storage.
     * @param oracleProvider The address of the oracle provider to unregister.
     */
    function unregister(OracleProviderRegistry storage self, address oracleProvider) internal {
        //slither-disable-next-line unused-return
        self._oracleProviders.remove(oracleProvider);
    }

    /**
     * @notice Returns an array of all registered oracle providers.
     * @param self The OracleProviderRegistry storage.
     * @return oracleProviders An array of addresses representing the registered oracle providers.
     */
    function oracleProviders(
        OracleProviderRegistry storage self
    ) internal view returns (address[] memory) {
        return self._oracleProviders.values();
    }

    /**
     * @notice Checks if an oracle provider is registered in the registry.
     * @param self The OracleProviderRegistry storage.
     * @param oracleProvider The address of the oracle provider to check.
     * @return bool Whether the oracle provider is registered.
     */
    function isRegistered(
        OracleProviderRegistry storage self,
        address oracleProvider
    ) internal view returns (bool) {
        return self._oracleProviders.contains(oracleProvider);
    }

    /**
     * @notice Retrieves the properties of an oracle provider.
     * @param self The OracleProviderRegistry storage.
     * @param oracleProvider The address of the oracle provider.
     * @return minTakeProfitBPS The minimum take-profit basis points.
     * @return maxTakeProfitBPS The maximum take-profit basis points.
     * @return leverageLevel The leverage level of the oracle provider.
     */
    function getOracleProviderProperties(
        OracleProviderRegistry storage self,
        address oracleProvider
    )
        internal
        view
        returns (uint32 minTakeProfitBPS, uint32 maxTakeProfitBPS, uint8 leverageLevel)
    {
        minTakeProfitBPS = self._minTakeProfitBPSs[oracleProvider];
        maxTakeProfitBPS = self._maxTakeProfitBPSs[oracleProvider];
        leverageLevel = self._leverageLevels[oracleProvider];
    }

    /**
     * @notice Sets the range for take-profit basis points for an oracle provider.
     * @param self The OracleProviderRegistry storage.
     * @param oracleProvider The address of the oracle provider.
     * @param minTakeProfitBPS The minimum take-profit basis points.
     * @param maxTakeProfitBPS The maximum take-profit basis points.
     */
    function setTakeProfitBPSRange(
        OracleProviderRegistry storage self,
        address oracleProvider,
        uint32 minTakeProfitBPS,
        uint32 maxTakeProfitBPS
    ) internal {
        self._minTakeProfitBPSs[oracleProvider] = minTakeProfitBPS;
        self._maxTakeProfitBPSs[oracleProvider] = maxTakeProfitBPS;
    }

    /**
     * @notice Sets the leverage level of an oracle provider in the registry.
     * @dev The leverage level must be either 0 or 1, and the max leverage must be x10 for level 0 or x20 for level 1.
     * @param self The storage reference to the OracleProviderRegistry.
     * @param oracleProvider The address of the oracle provider.
     * @param leverageLevel The new leverage level to be set for the oracle provider.
     */
    function setLeverageLevel(
        OracleProviderRegistry storage self,
        address oracleProvider,
        uint8 leverageLevel
    ) internal {
        self._leverageLevels[oracleProvider] = leverageLevel;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {InterestRate} from "@chromatic-protocol/contracts/core/libraries/InterestRate.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @dev A registry for managing settlement tokens and their associated parameters.
 * @param _tokens Set of registered settlement tokens
 * @param _interestRateRecords Mapping of settlement tokens to their interest rate records
 * @param _minimumMargins Mapping of settlement tokens to their minimum margins
 * @param _flashLoanFeeRates Mapping of settlement tokens to their flash loan fee rates
 * @param _earningDistributionThresholds Mapping of settlement tokens to their earning distribution thresholds
 * @param _uniswapFeeTiers Mapping of settlement tokens to their Uniswap fee tiers
 */
struct SettlementTokenRegistry {
    EnumerableSet.AddressSet _tokens;
    mapping(address => InterestRate.Record[]) _interestRateRecords;
    mapping(address => uint256) _minimumMargins;
    mapping(address => uint256) _flashLoanFeeRates;
    mapping(address => uint256) _earningDistributionThresholds;
    mapping(address => uint24) _uniswapFeeTiers;
}

/**
 * @title SettlementTokenRegistryLib
 * @notice Library for managing the settlement token registry.
 */
library SettlementTokenRegistryLib {
    using EnumerableSet for EnumerableSet.AddressSet;
    using InterestRate for InterestRate.Record[];

    /**
     * @notice Modifier to check if a token is registered in the settlement token registry.
     * @dev Throws an error with the code `Errors.UNREGISTERED_TOKEN` if the settlement token is not registered.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the token to check.
     */
    modifier registeredOnly(SettlementTokenRegistry storage self, address token) {
        require(self._tokens.contains(token), Errors.UNREGISTERED_TOKEN);
        _;
    }

    /**
     * @notice Registers a token in the settlement token registry.
     * @dev Throws an error with the code `Errors.ALREADY_REGISTERED_TOKEN` if the settlement token is already registered.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the token to register.
     * @param minimumMargin The minimum margin for the token.
     * @param interestRate The initial interest rate for the token.
     * @param flashLoanFeeRate The flash loan fee rate for the token.
     * @param earningDistributionThreshold The earning distribution threshold for the token.
     * @param uniswapFeeTier The Uniswap fee tier for the token.
     */
    function register(
        SettlementTokenRegistry storage self,
        address token,
        uint256 minimumMargin,
        uint256 interestRate,
        uint256 flashLoanFeeRate,
        uint256 earningDistributionThreshold,
        uint24 uniswapFeeTier
    ) internal {
        require(self._tokens.add(token), Errors.ALREADY_REGISTERED_TOKEN);

        self._interestRateRecords[token].initialize(interestRate);
        self._minimumMargins[token] = minimumMargin;
        self._flashLoanFeeRates[token] = flashLoanFeeRate;
        self._earningDistributionThresholds[token] = earningDistributionThreshold;
        self._uniswapFeeTiers[token] = uniswapFeeTier;
    }

    /**
     * @notice Returns an array of all registered settlement tokens.
     * @param self The SettlementTokenRegistry storage.
     * @return An array of addresses representing the registered settlement tokens.
     */
    function settlementTokens(
        SettlementTokenRegistry storage self
    ) internal view returns (address[] memory) {
        return self._tokens.values();
    }

    /**
     * @notice Checks if a token is registered in the settlement token registry.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the token to check.
     * @return bool Whether the token is registered.
     */
    function isRegistered(
        SettlementTokenRegistry storage self,
        address token
    ) internal view returns (bool) {
        return self._tokens.contains(token);
    }

    /**
     * @notice Retrieves the minimum margin for a asettlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the asettlement token.
     * @return uint256 The minimum margin for the asettlement token.
     */
    function getMinimumMargin(
        SettlementTokenRegistry storage self,
        address token
    ) internal view returns (uint256) {
        return self._minimumMargins[token];
    }

    /**
     * @notice Sets the minimum margin for asettlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @param minimumMargin The new minimum margin for the settlement token.
     */
    function setMinimumMargin(
        SettlementTokenRegistry storage self,
        address token,
        uint256 minimumMargin
    ) internal {
        self._minimumMargins[token] = minimumMargin;
    }

    /**
     * @notice Retrieves the flash loan fee rate for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @return uint256 The flash loan fee rate for the settlement token.
     */
    function getFlashLoanFeeRate(
        SettlementTokenRegistry storage self,
        address token
    ) internal view returns (uint256) {
        return self._flashLoanFeeRates[token];
    }

    /**
     * @notice Sets the flash loan fee rate for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @param flashLoanFeeRate The new flash loan fee rate for the settlement token.
     */
    function setFlashLoanFeeRate(
        SettlementTokenRegistry storage self,
        address token,
        uint256 flashLoanFeeRate
    ) internal {
        self._flashLoanFeeRates[token] = flashLoanFeeRate;
    }

    /**
     * @notice Retrieves the earning distribution threshold for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @return uint256 The earning distribution threshold for the token.
     */
    function getEarningDistributionThreshold(
        SettlementTokenRegistry storage self,
        address token
    ) internal view returns (uint256) {
        return self._earningDistributionThresholds[token];
    }

    /**
     * @notice Sets the earning distribution threshold for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @param earningDistributionThreshold The new earning distribution threshold for the settlement token.
     */
    function setEarningDistributionThreshold(
        SettlementTokenRegistry storage self,
        address token,
        uint256 earningDistributionThreshold
    ) internal {
        self._earningDistributionThresholds[token] = earningDistributionThreshold;
    }

    /**
     * @notice Retrieves the Uniswap fee tier for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @return uint24 The Uniswap fee tier for the settlement token.
     */
    function getUniswapFeeTier(
        SettlementTokenRegistry storage self,
        address token
    ) internal view returns (uint24) {
        return self._uniswapFeeTiers[token];
    }

    /**
     * @notice Sets the Uniswap fee tier for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @param uniswapFeeTier The new Uniswap fee tier for the settlement token.
     */
    function setUniswapFeeTier(
        SettlementTokenRegistry storage self,
        address token,
        uint24 uniswapFeeTier
    ) internal {
        self._uniswapFeeTiers[token] = uniswapFeeTier;
    }

    /**
     * @notice Appends an interest rate record for a settlement token.
     * @dev Throws an error if the settlement token is not registered.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points.
     * @param beginTimestamp The timestamp when the interest rate begins.
     */
    function appendInterestRateRecord(
        SettlementTokenRegistry storage self,
        address token,
        uint256 annualRateBPS,
        uint256 beginTimestamp
    ) internal registeredOnly(self, token) {
        getInterestRateRecords(self, token).appendRecord(annualRateBPS, beginTimestamp);
    }

    /**
     * @notice Removes the last interest rate record for a settlement token.
     * @dev The current time must be less than the begin timestamp of the last record.
     *      Throws an error with the code `Errors.INTEREST_RATE_ALREADY_APPLIED` if not.
     * @dev Throws an error if the settlement token is not registered.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @return removed Whether the removal was successful
     * @return record The removed interest rate record.
     */
    function removeLastInterestRateRecord(
        SettlementTokenRegistry storage self,
        address token
    )
        internal
        registeredOnly(self, token)
        returns (bool removed, InterestRate.Record memory record)
    {
        (removed, record) = getInterestRateRecords(self, token).removeLastRecord();
    }

    /**
     * @notice Retrieves the current interest rate for a settlement token.
     * @dev Throws an error if the settlement token is not registered.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @return annualRateBPS The current annual interest rate in basis points.
     */
    function currentInterestRate(
        SettlementTokenRegistry storage self,
        address token
    ) internal view registeredOnly(self, token) returns (uint256 annualRateBPS) {
        //slither-disable-next-line unused-return
        (InterestRate.Record memory record, ) = getInterestRateRecords(self, token).findRecordAt(
            block.timestamp
        );
        annualRateBPS = record.annualRateBPS;
    }

    /**
     * @notice Calculates the interest accrued for a settlement token within a specified time range.
     * @dev Throws an error if the token is not registered.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @param amount The amount of settlement tokens to calculate interest for.
     * @param from The starting timestamp of the interest calculation (inclusive).
     * @param to The ending timestamp of the interest calculation (exclusive).
     * @return uint256 The calculated interest amount.
     */
    function calculateInterest(
        SettlementTokenRegistry storage self,
        address token,
        uint256 amount,
        uint256 from, // timestamp (inclusive)
        uint256 to // timestamp (exclusive)
    ) internal view registeredOnly(self, token) returns (uint256) {
        return getInterestRateRecords(self, token).calculateInterest(amount, from, to);
    }

    /**
     * @notice Retrieves the array of interest rate records for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @return The array of interest rate records.
     */
    function getInterestRateRecords(
        SettlementTokenRegistry storage self,
        address token
    ) internal view returns (InterestRate.Record[] storage) {
        return self._interestRateRecords[token];
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

interface IOracleProvider {
    /// @dev Error for invalid oracle round
    error InvalidOracleRound();

    /**
     * @dev A singular oracle version with its corresponding data
     * @param version The iterative version
     * @param timestamp the timestamp of the oracle update
     * @param price The oracle price of the corresponding version
     */
    struct OracleVersion {
        uint256 version;
        uint256 timestamp;
        int256 price;
    }

    /**
     * @notice Checks for a new price and updates the internal phase annotation state accordingly
     * @dev `sync` is expected to be called soon after a phase update occurs in the underlying proxy.
     *      Phase updates should be detected using off-chain mechanism and should trigger a `sync` call
     *      This is feasible in the short term due to how infrequent phase updates are, but phase update
     *      and roundCount detection should eventually be implemented at the contract level.
     *      Reverts if there is more than 1 phase to update in a single sync because we currently cannot
     *      determine the startingRoundId for the intermediary phase.
     * @return The current oracle version after sync
     */
    function sync() external returns (OracleVersion memory);

    /**
     * @notice Returns the current oracle version
     * @return oracleVersion Current oracle version
     */
    function currentVersion() external view returns (OracleVersion memory);

    /**
     * @notice Returns the current oracle version
     * @param version The version of which to lookup
     * @return oracleVersion Oracle version at version `version`
     */
    function atVersion(uint256 version) external view returns (OracleVersion memory);

    /**
     * @notice Retrieves the description of the Oracle Provider.
     * @return A string representing the description of the Oracle Provider.
     */
    function description() external view returns (string memory);
}