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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Library for errors
/// @author Timeswap Labs
/// @dev Common error messages
library Error {
  /// @dev Reverts when input is zero.
  error ZeroInput();

  /// @dev Reverts when output is zero.
  error ZeroOutput();

  /// @dev Reverts when a value cannot be zero.
  error CannotBeZero();

  /// @dev Reverts when a pool already have liquidity.
  /// @param liquidity The liquidity amount that already existed in the pool.
  error AlreadyHaveLiquidity(uint160 liquidity);

  /// @dev Reverts when a pool requires liquidity.
  error RequireLiquidity();

  /// @dev Reverts when a given address is the zero address.
  error ZeroAddress();

  /// @dev Reverts when the maturity given is not withing uint96.
  /// @param maturity The maturity being inquired.
  error IncorrectMaturity(uint256 maturity);

  /// @dev Reverts when an option of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error InactiveOption(uint256 strike, uint256 maturity);

  /// @dev Reverts when a pool of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error InactivePool(uint256 strike, uint256 maturity);

  /// @dev Reverts when a liquidity token is inactive.
  error InactiveLiquidityTokenChoice();

  /// @dev Reverts when the square root interest rate is zero.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error ZeroSqrtInterestRate(uint256 strike, uint256 maturity);

  /// @dev Reverts when the maturity is already matured.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  error AlreadyMatured(uint256 maturity, uint96 blockTimestamp);

  /// @dev Reverts when the maturity is still active.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  error StillActive(uint256 maturity, uint96 blockTimestamp);

  /// @dev Token amount not received.
  /// @param minuend The amount being subtracted.
  /// @param subtrahend The amount subtracting.
  error NotEnoughReceived(uint256 minuend, uint256 subtrahend);

  /// @dev The deadline of a transaction has been reached.
  /// @param deadline The deadline set.
  error DeadlineReached(uint256 deadline);

  /// @dev Reverts when input is zero.
  function zeroInput() internal pure {
    revert ZeroInput();
  }

  /// @dev Reverts when output is zero.
  function zeroOutput() internal pure {
    revert ZeroOutput();
  }

  /// @dev Reverts when a value cannot be zero.
  function cannotBeZero() internal pure {
    revert CannotBeZero();
  }

  /// @dev Reverts when a pool already have liquidity.
  /// @param liquidity The liquidity amount that already existed in the pool.
  function alreadyHaveLiquidity(uint160 liquidity) internal pure {
    revert AlreadyHaveLiquidity(liquidity);
  }

  /// @dev Reverts when a pool requires liquidity.
  function requireLiquidity() internal pure {
    revert RequireLiquidity();
  }

  /// @dev Reverts when a given address is the zero address.
  function zeroAddress() internal pure {
    revert ZeroAddress();
  }

  /// @dev Reverts when the maturity given is not withing uint96.
  /// @param maturity The maturity being inquired.
  function incorrectMaturity(uint256 maturity) internal pure {
    revert IncorrectMaturity(maturity);
  }

  /// @dev Reverts when the maturity is already matured.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  function alreadyMatured(uint256 maturity, uint96 blockTimestamp) internal pure {
    revert AlreadyMatured(maturity, blockTimestamp);
  }

  /// @dev Reverts when the maturity is still active.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  function stillActive(uint256 maturity, uint96 blockTimestamp) internal pure {
    revert StillActive(maturity, blockTimestamp);
  }

  /// @dev The deadline of a transaction has been reached.
  /// @param deadline The deadline set.
  function deadlineReached(uint256 deadline) internal pure {
    revert DeadlineReached(deadline);
  }

  /// @dev Reverts when an option of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  function inactiveOptionChoice(uint256 strike, uint256 maturity) internal pure {
    revert InactiveOption(strike, maturity);
  }

  /// @dev Reverts when a pool of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  function inactivePoolChoice(uint256 strike, uint256 maturity) internal pure {
    revert InactivePool(strike, maturity);
  }

  /// @dev Reverts when the square root interest rate is zero.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  function zeroSqrtInterestRate(uint256 strike, uint256 maturity) internal pure {
    revert ZeroSqrtInterestRate(strike, maturity);
  }

  /// @dev Reverts when a liquidity token is inactive.
  function inactiveLiquidityTokenChoice() internal pure {
    revert InactiveLiquidityTokenChoice();
  }

  /// @dev Reverts when token amount not received.
  /// @param balance The balance amount being subtracted.
  /// @param balanceTarget The amount target.
  function checkEnough(uint256 balance, uint256 balanceTarget) internal pure {
    if (balance < balanceTarget) revert NotEnoughReceived(balance, balanceTarget);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Math} from "./Math.sol";

/// @title Library for math utils for uint512
/// @author Timeswap Labs
library FullMath {
  using Math for uint256;

  /// @dev Reverts when modulo by zero.
  error ModuloByZero();

  /// @dev Reverts when add512 overflows over uint512.
  /// @param addendA0 The least significant part of first addend.
  /// @param addendA1 The most significant part of first addend.
  /// @param addendB0 The least significant part of second addend.
  /// @param addendB1 The most significant part of second addend.
  error AddOverflow(uint256 addendA0, uint256 addendA1, uint256 addendB0, uint256 addendB1);

  /// @dev Reverts when sub512 underflows.
  /// @param minuend0 The least significant part of minuend.
  /// @param minuend1 The most significant part of minuend.
  /// @param subtrahend0 The least significant part of subtrahend.
  /// @param subtrahend1 The most significant part of subtrahend.
  error SubUnderflow(uint256 minuend0, uint256 minuend1, uint256 subtrahend0, uint256 subtrahend1);

  /// @dev Reverts when div512To256 overflows over uint256.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  error DivOverflow(uint256 dividend0, uint256 dividend1, uint256 divisor);

  /// @dev Reverts when mulDiv overflows over uint256.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @param divisor The divisor.
  error MulDivOverflow(uint256 multiplicand, uint256 multiplier, uint256 divisor);

  /// @dev Calculates the sum of two uint512 numbers.
  /// @notice Reverts on overflow over uint512.
  /// @param addendA0 The least significant part of addendA.
  /// @param addendA1 The most significant part of addendA.
  /// @param addendB0 The least significant part of addendB.
  /// @param addendB1 The most significant part of addendB.
  /// @return sum0 The least significant part of sum.
  /// @return sum1 The most significant part of sum.
  function add512(
    uint256 addendA0,
    uint256 addendA1,
    uint256 addendB0,
    uint256 addendB1
  ) internal pure returns (uint256 sum0, uint256 sum1) {
    uint256 carry;
    assembly {
      sum0 := add(addendA0, addendB0)
      carry := lt(sum0, addendA0)
      sum1 := add(add(addendA1, addendB1), carry)
    }

    if (carry == 0 ? addendA1 > sum1 : (sum1 == 0 || addendA1 > sum1 - 1))
      revert AddOverflow(addendA0, addendA1, addendB0, addendB1);
  }

  /// @dev Calculates the difference of two uint512 numbers.
  /// @notice Reverts on underflow.
  /// @param minuend0 The least significant part of minuend.
  /// @param minuend1 The most significant part of minuend.
  /// @param subtrahend0 The least significant part of subtrahend.
  /// @param subtrahend1 The most significant part of subtrahend.
  /// @return difference0 The least significant part of difference.
  /// @return difference1 The most significant part of difference.
  function sub512(
    uint256 minuend0,
    uint256 minuend1,
    uint256 subtrahend0,
    uint256 subtrahend1
  ) internal pure returns (uint256 difference0, uint256 difference1) {
    assembly {
      difference0 := sub(minuend0, subtrahend0)
      difference1 := sub(sub(minuend1, subtrahend1), lt(minuend0, subtrahend0))
    }

    if (subtrahend1 > minuend1 || (subtrahend1 == minuend1 && subtrahend0 > minuend0))
      revert SubUnderflow(minuend0, minuend1, subtrahend0, subtrahend1);
  }

  /// @dev Calculate the product of two uint256 numbers that may result to uint512 product.
  /// @notice Can never overflow.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @return product0 The least significant part of product.
  /// @return product1 The most significant part of product.
  function mul512(uint256 multiplicand, uint256 multiplier) internal pure returns (uint256 product0, uint256 product1) {
    assembly {
      let mm := mulmod(multiplicand, multiplier, not(0))
      product0 := mul(multiplicand, multiplier)
      product1 := sub(sub(mm, product0), lt(mm, product0))
    }
  }

  /// @dev Divide 2 to 256 power by the divisor.
  /// @dev Rounds down the result.
  /// @notice Reverts when divide by zero.
  /// @param divisor The divisor.
  /// @return quotient The quotient.
  function div256(uint256 divisor) private pure returns (uint256 quotient) {
    if (divisor == 0) revert Math.DivideByZero();
    assembly {
      quotient := add(div(sub(0, divisor), divisor), 1)
    }
  }

  /// @dev Compute 2 to 256 power modulo the given value.
  /// @notice Reverts when modulo by zero.
  /// @param value The given value.
  /// @return result The result.
  function mod256(uint256 value) private pure returns (uint256 result) {
    if (value == 0) revert ModuloByZero();
    assembly {
      result := mod(sub(0, value), value)
    }
  }

  /// @dev Divide a uint512 number by uint256 number to return a uint512 number.
  /// @dev Rounds down the result.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param quotient0 The least significant part of quotient.
  /// @param quotient1 The most significant part of quotient.
  function div512(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor
  ) private pure returns (uint256 quotient0, uint256 quotient1) {
    if (dividend1 == 0) quotient0 = dividend0.div(divisor, false);
    else {
      uint256 q = div256(divisor);
      uint256 r = mod256(divisor);
      while (dividend1 != 0) {
        (uint256 t0, uint256 t1) = mul512(dividend1, q);
        (quotient0, quotient1) = add512(quotient0, quotient1, t0, t1);
        (t0, t1) = mul512(dividend1, r);
        (dividend0, dividend1) = add512(t0, t1, dividend0, 0);
      }
      (quotient0, quotient1) = add512(quotient0, quotient1, dividend0.div(divisor, false), 0);
    }
  }

  /// @dev Divide a uint512 number by a uint256 number.
  /// @dev Reverts when result is greater than uint256.
  /// @notice Skips div512 if dividend1 is zero.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @param quotient The quotient.
  function div512To256(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 quotient) {
    uint256 quotient1;
    (quotient, quotient1) = div512(dividend0, dividend1, divisor);

    if (quotient1 != 0) revert DivOverflow(dividend0, dividend1, divisor);

    if (roundUp) {
      (uint256 productA0, uint256 productA1) = mul512(quotient, divisor);
      if (dividend1 > productA1 || dividend0 > productA0) quotient++;
    }
  }

  /// @dev Divide a uint512 number by a uint256 number.
  /// @notice Skips div512 if dividend1 is zero.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @param quotient0 The least significant part of quotient.
  /// @param quotient1 The most significant part of quotient.
  function div512(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 quotient0, uint256 quotient1) {
    (quotient0, quotient1) = div512(dividend0, dividend1, divisor);

    if (roundUp) {
      (uint256 productA0, uint256 productA1) = mul512(quotient0, divisor);
      productA1 += (quotient1 * divisor);
      if (dividend1 > productA1 || dividend0 > productA0) {
        if (quotient0 == type(uint256).max) {
          quotient0 = 0;
          quotient1++;
        } else quotient0++;
      }
    }
  }

  /// @dev Multiply two uint256 number then divide it by a uint256 number.
  /// @notice Skips mulDiv if product of multiplicand and multiplier is uint256 number.
  /// @dev Reverts when result is greater than uint256.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The result.
  function mulDiv(
    uint256 multiplicand,
    uint256 multiplier,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 result) {
    (uint256 product0, uint256 product1) = mul512(multiplicand, multiplier);

    // Handle non-overflow cases, 256 by 256 division
    if (product1 == 0) return result = product0.div(divisor, roundUp);

    // Make sure the result is less than 2**256.
    // Also prevents divisor == 0
    if (divisor <= product1) revert MulDivOverflow(multiplicand, multiplier, divisor);

    unchecked {
      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [product1 product0]
      // Compute remainder using mulmod
      uint256 remainder;
      assembly {
        remainder := mulmod(multiplicand, multiplier, divisor)
      }
      // Subtract 256 bit number from 512 bit number
      assembly {
        product1 := sub(product1, gt(remainder, product0))
        product0 := sub(product0, remainder)
      }

      // Factor powers of two out of divisor
      // Compute largest power of two divisor of divisor.
      // Always >= 1.
      uint256 twos;
      twos = (0 - divisor) & divisor;
      // Divide denominator by power of two
      assembly {
        divisor := div(divisor, twos)
      }

      // Divide [product1 product0] by the factors of two
      assembly {
        product0 := div(product0, twos)
      }
      // Shift in bits from product1 into product0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      product0 |= product1 * twos;

      // Invert divisor mod 2**256
      // Now that divisor is an odd number, it has an inverse
      // modulo 2**256 such that divisor * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, divisor * inv = 1 mod 2**4
      uint256 inv;
      inv = (3 * divisor) ^ 2;

      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - divisor * inv; // inverse mod 2**8
      inv *= 2 - divisor * inv; // inverse mod 2**16
      inv *= 2 - divisor * inv; // inverse mod 2**32
      inv *= 2 - divisor * inv; // inverse mod 2**64
      inv *= 2 - divisor * inv; // inverse mod 2**128
      inv *= 2 - divisor * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of divisor. This will give us the
      // correct result modulo 2**256. Since the preconditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and product1
      // is no longer required.
      result = product0 * inv;
    }

    if (roundUp && mulmod(multiplicand, multiplier, divisor) != 0) result++;
  }

  /// @dev Get the square root of a uint512 number.
  /// @param value0 The least significant of the number.
  /// @param value1 The most significant of the number.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The result.
  function sqrt512(uint256 value0, uint256 value1, bool roundUp) internal pure returns (uint256 result) {
    if (value1 == 0) result = value0.sqrt(roundUp);
    else {
      uint256 estimate = sqrt512Estimate(value0, value1, type(uint256).max);
      result = type(uint256).max;
      while (estimate < result) {
        result = estimate;
        estimate = sqrt512Estimate(value0, value1, estimate);
      }

      if (roundUp) {
        (uint256 product0, uint256 product1) = mul512(result, result);
        if (value1 > product1 || value0 > product0) result++;
      }
    }
  }

  /// @dev An iterative process of getting sqrt512 following Newtonian method.
  /// @param value0 The least significant of the number.
  /// @param value1 The most significant of the number.
  /// @param currentEstimate The current estimate of the iteration.
  /// @param estimate The new estimate of the iteration.
  function sqrt512Estimate(
    uint256 value0,
    uint256 value1,
    uint256 currentEstimate
  ) private pure returns (uint256 estimate) {
    uint256 r0 = div512To256(value0, value1, currentEstimate, false);
    uint256 r1;
    (r0, r1) = add512(r0, 0, currentEstimate, 0);
    estimate = div512To256(r0, r1, 2, false);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Library for math related utils
/// @author Timeswap Labs
library Math {
  /// @dev Reverts when divide by zero.
  error DivideByZero();
  error Overflow();

  /// @dev Add two uint256.
  /// @notice May overflow.
  /// @param addend1 The first addend.
  /// @param addend2 The second addend.
  /// @return sum The sum.
  function unsafeAdd(uint256 addend1, uint256 addend2) internal pure returns (uint256 sum) {
    unchecked {
      sum = addend1 + addend2;
    }
  }

  /// @dev Subtract two uint256.
  /// @notice May underflow.
  /// @param minuend The minuend.
  /// @param subtrahend The subtrahend.
  /// @return difference The difference.
  function unsafeSub(uint256 minuend, uint256 subtrahend) internal pure returns (uint256 difference) {
    unchecked {
      difference = minuend - subtrahend;
    }
  }

  /// @dev Multiply two uint256.
  /// @notice May overflow.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @return product The product.
  function unsafeMul(uint256 multiplicand, uint256 multiplier) internal pure returns (uint256 product) {
    unchecked {
      product = multiplicand * multiplier;
    }
  }

  /// @dev Divide two uint256.
  /// @notice Reverts when divide by zero.
  /// @param dividend The dividend.
  /// @param divisor The divisor.
  //// @param roundUp Round up the result when true. Round down if false.
  /// @return quotient The quotient.
  function div(uint256 dividend, uint256 divisor, bool roundUp) internal pure returns (uint256 quotient) {
    quotient = dividend / divisor;

    if (roundUp && dividend % divisor != 0) quotient++;
  }

  /// @dev Shift right a uint256 number.
  /// @param dividend The dividend.
  /// @param divisorBit The divisor in bits.
  /// @param roundUp True if ceiling the result. False if floor the result.
  /// @return quotient The quotient.
  function shr(uint256 dividend, uint8 divisorBit, bool roundUp) internal pure returns (uint256 quotient) {
    quotient = dividend >> divisorBit;

    if (roundUp && dividend % (1 << divisorBit) != 0) quotient++;
  }

  /// @dev Gets the square root of a value.
  /// @param value The value being square rooted.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The resulting value of the square root.
  function sqrt(uint256 value, bool roundUp) internal pure returns (uint256 result) {
    if (value == type(uint256).max) return result = type(uint128).max;
    if (value == 0) return 0;
    unchecked {
      uint256 estimate = (value + 1) >> 1;
      result = value;
      while (estimate < result) {
        result = estimate;
        estimate = (value / estimate + estimate) >> 1;
      }
    }

    if (roundUp && result * result < value) result++;
  }

  /// @dev Gets the min of two uint256 number.
  /// @param value1 The first value to be compared.
  /// @param value2 The second value to be compared.
  /// @return result The min result.
  function min(uint256 value1, uint256 value2) internal pure returns (uint256 result) {
    return value1 < value2 ? value1 : value2;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The three type of native token positions.
/// @dev Long0 is denominated as the underlying Token0.
/// @dev Long1 is denominated as the underlying Token1.
/// @dev When strike greater than uint128 then Short is denominated as Token0 (the base token denomination).
/// @dev When strike is uint128 then Short is denominated as Token1 (the base token denomination).
enum TimeswapV2OptionPosition {
  Long0,
  Long1,
  Short
}

/// @title library for position utils
/// @author Timeswap Labs
/// @dev Helper functions for the TimeswapOptionPosition enum.
library PositionLibrary {
  /// @dev Reverts when the given type of position is invalid.
  error InvalidPosition();

  /// @dev Checks that the position input is correct.
  /// @param position The position input.
  function check(TimeswapV2OptionPosition position) internal pure {
    if (uint256(position) >= 3) revert InvalidPosition();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The different input for the mint transaction.
enum TimeswapV2OptionMint {
  GivenTokensAndLongs,
  GivenShorts
}

/// @dev The different input for the burn transaction.
enum TimeswapV2OptionBurn {
  GivenTokensAndLongs,
  GivenShorts
}

/// @dev The different input for the swap transaction.
enum TimeswapV2OptionSwap {
  GivenToken0AndLong0,
  GivenToken1AndLong1
}

/// @dev The different input for the collect transaction.
enum TimeswapV2OptionCollect {
  GivenShort,
  GivenToken0,
  GivenToken1
}

/// @title library for transaction checks
/// @author Timeswap Labs
/// @dev Helper functions for the all enums in this module.
library TransactionLibrary {
  /// @dev Reverts when the given type of transaction is invalid.
  error InvalidTransaction();

  /// @dev checks that the given input is correct.
  /// @param transaction the mint transaction input.
  function check(TimeswapV2OptionMint transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the burn transaction input.
  function check(TimeswapV2OptionBurn transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the swap transaction input.
  function check(TimeswapV2OptionSwap transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the collect transaction input.
  function check(TimeswapV2OptionCollect transaction) internal pure {
    if (uint256(transaction) >= 3) revert InvalidTransaction();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionPosition} from "../enums/Position.sol";
import {TimeswapV2OptionMintParam, TimeswapV2OptionBurnParam, TimeswapV2OptionSwapParam, TimeswapV2OptionCollectParam} from "../structs/Param.sol";
import {StrikeAndMaturity} from "../structs/StrikeAndMaturity.sol";

/// @title An interface for a contract that deploys Timeswap V2 Option pair contracts
/// @notice A Timeswap V2 Option pair facilitates option mechanics between any two assets that strictly conform
/// to the ERC20 specification.
interface ITimeswapV2Option {
  /* ===== EVENT ===== */

  /// @dev Emits when a position is transferred.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param from The address of the caller of the transferPosition function.
  /// @param to The address of the recipient of the position.
  /// @param position The type of position transferred. More information in the Position module.
  /// @param amount The amount of balance transferred.
  event TransferPosition(
    uint256 indexed strike,
    uint256 indexed maturity,
    address from,
    address to,
    TimeswapV2OptionPosition position,
    uint256 amount
  );

  /// @dev Emits when a mint transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param long0To The address of the recipient of long token0 position.
  /// @param long1To The address of the recipient of long token1 position.
  /// @param shortTo The address of the recipient of short position.
  /// @param token0AndLong0Amount The amount of token0 deposited and long0 minted.
  /// @param token1AndLong1Amount The amount of token1 deposited and long1 minted.
  /// @param shortAmount The amount of short minted.
  event Mint(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when a burn transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param token0To The address of the recipient of token0.
  /// @param token1To The address of the recipient of token1.
  /// @param token0AndLong0Amount The amount of token0 withdrawn and long0 burnt.
  /// @param token1AndLong1Amount The amount of token1 withdrawn and long1 burnt.
  /// @param shortAmount The amount of short burnt.
  event Burn(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address token0To,
    address token1To,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when a swap transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param tokenTo The address of the recipient of token0 or token1.
  /// @param longTo The address of the recipient of long token0 or long token1.
  /// @param isLong0toLong1 The direction of the swap. More information in the Transaction module.
  /// @param token0AndLong0Amount If the direction is from long0 to long1, the amount of token0 withdrawn and long0 burnt.
  /// If the direction is from long1 to long0, the amount of token0 deposited and long0 minted.
  /// @param token1AndLong1Amount If the direction is from long0 to long1, the amount of token1 deposited and long1 minted.
  /// If the direction is from long1 to long0, the amount of token1 withdrawn and long1 burnt.
  event Swap(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address tokenTo,
    address longTo,
    bool isLong0toLong1,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount
  );

  /// @dev Emits when a collect transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param token0To The address of the recipient of token0.
  /// @param token1To The address of the recipient of token1.
  /// @param long0AndToken0Amount The amount of token0 withdrawn.
  /// @param long1AndToken1Amount The amount of token1 withdrawn.
  /// @param shortAmount The amount of short burnt.
  event Collect(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address token0To,
    address token1To,
    uint256 long0AndToken0Amount,
    uint256 long1AndToken1Amount,
    uint256 shortAmount
  );

  /* ===== VIEW ===== */

  /// @dev Returns the factory address that deployed this contract.
  function optionFactory() external view returns (address);

  /// @dev Returns the first ERC20 token address of the pair.
  function token0() external view returns (address);

  /// @dev Returns the second ERC20 token address of the pair.
  function token1() external view returns (address);

  /// @dev Get the strike and maturity of the option in the option enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (StrikeAndMaturity memory);

  /// @dev Number of options being interacted.
  function numberOfOptions() external view returns (uint256);

  /// @dev Returns the total position of the option.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param position The type of position inquired. More information in the Position module.
  /// @return balance The total position.
  function totalPosition(
    uint256 strike,
    uint256 maturity,
    TimeswapV2OptionPosition position
  ) external view returns (uint256 balance);

  /// @dev Returns the position of an owner of the option.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param owner The address of the owner of the position.
  /// @param position The type of position inquired. More information in the Position module.
  /// @return balance The user position.
  function positionOf(
    uint256 strike,
    uint256 maturity,
    address owner,
    TimeswapV2OptionPosition position
  ) external view returns (uint256 balance);

  /* ===== UPDATE ===== */

  /// @dev Transfer position to another address.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param to The address of the recipient of the position.
  /// @param position The type of position transferred. More information in the Position module.
  /// @param amount The amount of balance transferred.
  function transferPosition(
    uint256 strike,
    uint256 maturity,
    address to,
    TimeswapV2OptionPosition position,
    uint256 amount
  ) external;

  /// @dev Mint position.
  /// Mint long token0 position when token0 is deposited.
  /// Mint long token1 position when token1 is deposited.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the mint function.
  /// @return token0AndLong0Amount The amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount The amount of token1 deposited and long1 minted.
  /// @return shortAmount The amount of short minted.
  /// @return data The additional data return.
  function mint(
    TimeswapV2OptionMintParam calldata param
  )
    external
    returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data);

  /// @dev Burn short position.
  /// Withdraw token0, when long token0 is burnt.
  /// Withdraw token1, when long token1 is burnt.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the burn function.
  /// @return token0AndLong0Amount The amount of token0 withdrawn and long0 burnt.
  /// @return token1AndLong1Amount The amount of token1 withdrawn and long1 burnt.
  /// @return shortAmount The amount of short burnt.
  function burn(
    TimeswapV2OptionBurnParam calldata param
  )
    external
    returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data);

  /// @dev If the direction is from long token0 to long token1, burn long token0 and mint equivalent long token1,
  /// also deposit token1 and withdraw token0.
  /// If the direction is from long token1 to long token0, burn long token1 and mint equivalent long token0,
  /// also deposit token0 and withdraw token1.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the swap function.
  /// @return token0AndLong0Amount If direction is Long0ToLong1, the amount of token0 withdrawn and long0 burnt.
  /// If direction is Long1ToLong0, the amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount If direction is Long0ToLong1, the amount of token1 deposited and long1 minted.
  /// If direction is Long1ToLong0, the amount of token1 withdrawn and long1 burnt.
  /// @return data The additional data return.
  function swap(
    TimeswapV2OptionSwapParam calldata param
  ) external returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, bytes memory data);

  /// @dev Burn short position, withdraw token0 and token1.
  /// @dev Can only be called after the maturity of the pool.
  /// @param param The parameters for the collect function.
  /// @return token0Amount The amount of token0 withdrawn.
  /// @return token1Amount The amount of token1 withdrawn.
  /// @return shortAmount The amount of short burnt.
  function collect(
    TimeswapV2OptionCollectParam calldata param
  ) external returns (uint256 token0Amount, uint256 token1Amount, uint256 shortAmount, bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title The interface for the contract that deploys Timeswap V2 Option pair contracts
/// @notice The Timeswap V2 Option Factory facilitates creation of Timeswap V2 Options pair.
interface ITimeswapV2OptionFactory {
  /* ===== EVENT ===== */

  /// @dev Emits when a new Timeswap V2 Option contract is created.
  /// @param caller The address of the caller of create function.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the Timeswap V2 Option contract created.
  event Create(address indexed caller, address indexed token0, address indexed token1, address optionPair);

  /* ===== VIEW ===== */

  /// @dev Returns the address of a Timeswap V2 Option.
  /// @dev Returns a zero address if the Timeswap V2 Option does not exist.
  /// @notice The token0 address must be smaller than token1 address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @return optionPair The address of the Timeswap V2 Option contract or a zero address.
  function get(address token0, address token1) external view returns (address optionPair);

  /// @dev Get the address of the option pair in the option pair enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (address optionPair);

  /// @dev The number of option pairs deployed.
  function numberOfPairs() external view returns (uint256);

  /* ===== UPDATE ===== */

  /// @dev Creates a Timeswap V2 Option based on pair parameters.
  /// @dev Cannot create a duplicate Timeswap V2 Option with the same pair parameters.
  /// @notice The token0 address must be smaller than token1 address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the Timeswap V2 Option contract created.
  function create(address token0, address token1) external returns (address optionPair);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {OptionPairLibrary} from "./OptionPair.sol";

import {ITimeswapV2OptionFactory} from "../interfaces/ITimeswapV2OptionFactory.sol";

/// @title library for option utils
/// @author Timeswap Labs
library OptionFactoryLibrary {
  using OptionPairLibrary for address;

  /// @dev reverts if the factory is the zero address.
  error ZeroFactoryAddress();

  /// @dev check if the factory address is not zero.
  /// @param optionFactory The factory address.
  function checkNotZeroFactory(address optionFactory) internal pure {
    if (optionFactory == address(0)) revert ZeroFactoryAddress();
  }

  /// @dev Helper function to get the option pair address.
  /// @param optionFactory The address of the option factory.
  /// @param token0 The smaller ERC20 address of the pair.
  /// @param token1 The larger ERC20 address of the pair.
  /// @return optionPair The result option pair address.
  function get(address optionFactory, address token0, address token1) internal view returns (address optionPair) {
    optionPair = ITimeswapV2OptionFactory(optionFactory).get(token0, token1);
  }

  /// @dev Helper function to get the option pair address.
  /// @notice reverts when the option pair does not exist.
  /// @param optionFactory The address of the option factory.
  /// @param token0 The smaller ERC20 address of the pair.
  /// @param token1 The larger ERC20 address of the pair.
  /// @return optionPair The result option pair address.
  function getWithCheck(
    address optionFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair) {
    optionPair = get(optionFactory, token0, token1);
    if (optionPair == address(0)) Error.zeroAddress();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title library for optionPair utils
/// @author Timeswap Labs
library OptionPairLibrary {
  /// @dev Reverts when option address is zero.
  error ZeroOptionAddress();

  /// @dev Reverts when the pair has incorrect format.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  error InvalidOptionPair(address token0, address token1);

  /// @dev Reverts when the Timeswap V2 Option already exist.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the existed Pair contract.
  error OptionPairAlreadyExisted(address token0, address token1, address optionPair);

  /// @dev Checks if option address is not zero.
  /// @param optionPair The option pair address being inquired.
  function checkNotZeroAddress(address optionPair) internal pure {
    if (optionPair == address(0)) revert ZeroOptionAddress();
  }

  /// @dev Check if the pair tokens is in correct format.
  /// @notice Reverts if token0 is greater than or equal token1.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  function checkCorrectFormat(address token0, address token1) internal pure {
    if (token0 >= token1) revert InvalidOptionPair(token0, token1);
  }

  /// @dev Check if the pair already existed.
  /// @notice Reverts if the pair is not a zero address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the existed Pair contract.
  function checkDoesNotExist(address token0, address token1, address optionPair) internal pure {
    if (optionPair != address(0)) revert OptionPairAlreadyExisted(token0, token1, optionPair);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {TimeswapV2OptionMint, TimeswapV2OptionBurn, TimeswapV2OptionSwap, TimeswapV2OptionCollect, TransactionLibrary} from "../enums/Transaction.sol";

/// @dev The parameter to call the mint function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param shortTo The recipient of short positions.
/// @param transaction The type of mint transaction, more information in Transaction module.
/// @param amount0 If transaction is givenTokensAndLongs, the amount of token0 deposited, and amount of long0 position minted.
/// If transaction is givenShorts, the amount of short minted, where the equivalent strike converted amount is long0 positions.
/// @param amount1 If transaction is givenTokensAndLongs, the amount of token1 deposited, and amount of long1 position minted.
/// If transaction is givenShorts, the amount of short minted, where the equivalent strike converted amount is long1 positions.
/// @param data The data to be sent to the function, which will go to the mint callback.
struct TimeswapV2OptionMintParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  TimeswapV2OptionMint transaction;
  uint256 amount0;
  uint256 amount1;
  bytes data;
}

/// @dev The parameter to call the burn function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param token0To The recipient of token0 withdrawn.
/// @param token1To The recipient of token1 withdrawn.
/// @param transaction The type of burn transaction, more information in Transaction module.
/// @param amount0 If transaction is givenTokensAndLongs, the amount of token0 withdrawn, and amount of long0 position burnt.
/// If transaction is givenShorts, the amount of short burnt, where the equivalent strike converted amount is long0 positions.
/// @param amount1 If transaction is givenTokensAndLongs, the amount of token1 withdrawn, and amount of long1 position burnt.
/// If transaction is givenShorts, the amount of short burnt, where the equivalent strike converted amount is long1 positions.
/// @param data The data to be sent to the function, which will go to the burn callback.
/// @notice If data length is zero, skips the callback.
struct TimeswapV2OptionBurnParam {
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  TimeswapV2OptionBurn transaction;
  uint256 amount0;
  uint256 amount1;
  bytes data;
}

/// @dev The parameter to call the swap function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param tokenTo The recipient of token0 when isLong0ToLong1 or token1 when isLong1ToLong0.
/// @param longTo The recipient of long1 positions when isLong0ToLong1 or long0 when isLong1ToLong0.
/// @param isLong0ToLong1 Transform long0 positions to long1 positions when true. Transform long1 positions to long0 positions when false.
/// @param transaction The type of swap transaction, more information in Transaction module.
/// @param amount If isLong0ToLong1 and transaction is GivenToken0AndLong0, this is the amount of token0 withdrawn, and the amount of long0 position burnt.
/// If isLong1ToLong0 and transaction is GivenToken0AndLong0, this is the amount of token0 to be deposited, and the amount of long0 position minted.
/// If isLong0ToLong1 and transaction is GivenToken1AndLong1, this is the amount of token1 to be deposited, and the amount of long1 position minted.
/// If isLong1ToLong0 and transaction is GivenToken1AndLong1, this is the amount of token1 withdrawn, and the amount of long1 position burnt.
/// @param data The data to be sent to the function, which will go to the swap callback.
struct TimeswapV2OptionSwapParam {
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0ToLong1;
  TimeswapV2OptionSwap transaction;
  uint256 amount;
  bytes data;
}

/// @dev The parameter to call the collect function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param token0To The recipient of token0 withdrawn.
/// @param token1To The recipient of token1 withdrawn.
/// @param transaction The type of collect transaction, more information in Transaction module.
/// @param amount If transaction is GivenShort, the amount of short position burnt.
/// If transaction is GivenToken0, the amount of token0 withdrawn.
/// If transaction is GivenToken1, the amount of token1 withdrawn.
/// @param data The data to be sent to the function, which will go to the collect callback.
/// @notice If data length is zero, skips the callback.
struct TimeswapV2OptionCollectParam {
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  TimeswapV2OptionCollect transaction;
  uint256 amount;
  bytes data;
}

library ParamLibrary {
  /// @dev Sanity checks
  /// @param param the parameter for mint transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionMintParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.shortTo == address(0)) Error.zeroAddress();
    if (param.long0To == address(0)) Error.zeroAddress();
    if (param.long1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount0 == 0 && param.amount1 == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for burn transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionBurnParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.token0To == address(0)) Error.zeroAddress();
    if (param.token1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount0 == 0 && param.amount1 == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for swap transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionSwapParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.tokenTo == address(0)) Error.zeroAddress();
    if (param.longTo == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for collect transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionCollectParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity >= blockTimestamp) Error.stillActive(param.maturity, blockTimestamp);
    if (param.token0To == address(0)) Error.zeroAddress();
    if (param.token1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount == 0) Error.zeroInput();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev A data with strike and maturity data.
/// @param strike The strike.
/// @param maturity The maturity.
struct StrikeAndMaturity {
  uint256 strike;
  uint256 maturity;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The different kind of mint transactions.
enum TimeswapV2PoolMint {
  GivenLiquidity,
  GivenLong,
  GivenShort,
  GivenLarger
}

/// @dev The different kind of burn transactions.
enum TimeswapV2PoolBurn {
  GivenLiquidity,
  GivenLong,
  GivenShort,
  GivenSmaller
}

/// @dev The different kind of deleverage transactions.
enum TimeswapV2PoolDeleverage {
  GivenDeltaSqrtInterestRate,
  GivenLong,
  GivenShort,
  GivenSum
}

/// @dev The different kind of leverage transactions.
enum TimeswapV2PoolLeverage {
  GivenDeltaSqrtInterestRate,
  GivenLong,
  GivenShort,
  GivenSum
}

/// @dev The different kind of rebalance transactions.
enum TimeswapV2PoolRebalance {
  GivenLong0,
  GivenLong1
}

library TransactionLibrary {
  /// @dev Reverts when the given type of transaction is invalid.
  error InvalidTransaction();

  /// @dev Function to revert with the error InvalidTransaction.
  function invalidTransaction() internal pure {
    revert InvalidTransaction();
  }

  /// @dev Sanity checks for the mint parameters.
  function check(TimeswapV2PoolMint transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the burn parameters.
  function check(TimeswapV2PoolBurn transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the deleverage parameters.
  function check(TimeswapV2PoolDeleverage transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the leverage parameters.
  function check(TimeswapV2PoolLeverage transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the rebalance parameters.
  function check(TimeswapV2PoolRebalance transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

interface IOwnableTwoSteps {
  /// @dev Emits when the pending owner is chosen.
  /// @param pendingOwner The new pending owner.
  event SetOwner(address pendingOwner);

  /// @dev Emits when the pending owner accepted and become the new owner.
  /// @param owner The new owner.
  event AcceptOwner(address owner);

  /// @dev The address of the current owner.
  /// @return address
  function owner() external view returns (address);

  /// @dev The address of the current pending owner.
  /// @notice The address can be zero which signifies no pending owner.
  /// @return address
  function pendingOwner() external view returns (address);

  /// @dev The owner sets the new pending owner.
  /// @notice Can only be called by the owner.
  /// @param chosenPendingOwner The newly chosen pending owner.
  function setPendingOwner(address chosenPendingOwner) external;

  /// @dev The pending owner accepts being the new owner.
  /// @notice Can only be called by the pending owner.
  function acceptOwner() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {StrikeAndMaturity} from "@timeswap-labs/v2-option/contracts/structs/StrikeAndMaturity.sol";

import {TimeswapV2PoolCollectProtocolFeesParam, TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam, TimeswapV2PoolMintParam, TimeswapV2PoolBurnParam, TimeswapV2PoolDeleverageParam, TimeswapV2PoolLeverageParam, TimeswapV2PoolRebalanceParam} from "../structs/Param.sol";

/// @title An interface for Timeswap V2 Pool contract.
interface ITimeswapV2Pool {
  /// @dev Emits when liquidity position is transferred.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param from The sender of liquidity position.
  /// @param to The receipeint of liquidity position.
  /// @param liquidityAmount The amount of liquidity position transferred.
  event TransferLiquidity(
    uint256 indexed strike,
    uint256 indexed maturity,
    address from,
    address to,
    uint160 liquidityAmount
  );

  /// @dev Emits when protocol fees are withdrawn by the factory contract owner.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the collectProtocolFees function.
  /// @param long0To The recipient of long0 position fees.
  /// @param long1To The recipient of long1 position fees.
  /// @param shortTo The recipient of short position fees.
  /// @param long0Amount The amount of long0 position fees withdrawn.
  /// @param long1Amount The amount of long1 position fees withdrawn.
  /// @param shortAmount The amount of short position fees withdrawn.
  event CollectProtocolFees(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when transaction fees are withdrawn by a liquidity provider.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the collectTransactionFees function.
  /// @param long0FeesTo The recipient of long0 position fees.
  /// @param long1FeesTo The recipient of long1 position fees.
  /// @param shortFeesTo The recipient of short position fees.
  /// @param shortReturnedTo The recipient of short position returned.
  /// @param long0Fees The amount of long0 position fees withdrawn.
  /// @param long1Fees The amount of long1 position fees withdrawn.
  /// @param shortFees The amount of short position fees withdrawn.
  /// @param shortReturned The amount of short position returned withdrawn.
  event CollectTransactionFeesAndShortReturned(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0FeesTo,
    address long1FeesTo,
    address shortFeesTo,
    address shortReturnedTo,
    uint256 long0Fees,
    uint256 long1Fees,
    uint256 shortFees,
    uint256 shortReturned
  );

  /// @dev Emits when the mint transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the mint function.
  /// @param to The recipient of liquidity positions.
  /// @param liquidityAmount The amount of liquidity positions minted.
  /// @param long0Amount The amount of long0 positions deposited.
  /// @param long1Amount The amount of long1 positions deposited.
  /// @param shortAmount The amount of short positions deposited.
  event Mint(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address to,
    uint160 liquidityAmount,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when the burn transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the burn function.
  /// @param long0To The recipient of long0 positions.
  /// @param long1To The recipient of long1 positions.
  /// @param shortTo The recipient of short positions.
  /// @param liquidityAmount The amount of liquidity positions burnt.
  /// @param long0Amount The amount of long0 positions withdrawn.
  /// @param long1Amount The amount of long1 positions withdrawn.
  /// @param shortAmount The amount of short positions withdrawn.
  event Burn(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint160 liquidityAmount,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when deleverage transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the deleverage function.
  /// @param to The recipient of short positions.
  /// @param long0Amount The amount of long0 positions deposited.
  /// @param long1Amount The amount of long1 positions deposited.
  /// @param shortAmount The amount of short positions withdrawn.
  event Deleverage(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address to,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when leverage transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the leverage function.
  /// @param long0To The recipient of long0 positions.
  /// @param long1To The recipient of long1 positions.
  /// @param long0Amount The amount of long0 positions withdrawn.
  /// @param long1Amount The amount of long1 positions withdrawn.
  /// @param shortAmount The amount of short positions deposited.
  event Leverage(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when rebalance transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the rebalance function.
  /// @param to If isLong0ToLong1 then recipient of long0 positions, ekse recipient of long1 positions.
  /// @param isLong0ToLong1 Long0ToLong1 if true. Long1ToLong0 if false.
  /// @param long0Amount If isLong0ToLong1, amount of long0 positions deposited.
  /// If isLong1ToLong0, amount of long0 positions withdrawn.
  /// @param long1Amount If isLong0ToLong1, amount of long1 positions withdrawn.
  /// If isLong1ToLong0, amount of long1 positions deposited.
  event Rebalance(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address to,
    bool isLong0ToLong1,
    uint256 long0Amount,
    uint256 long1Amount
  );

  error Quote();

  /* ===== VIEW ===== */

  /// @dev Returns the factory address that deployed this contract.
  function poolFactory() external view returns (address);

  /// @dev Returns the Timeswap V2 Option of the pair.
  function optionPair() external view returns (address);

  /// @dev Returns the transaction fee earned by the liquidity providers.
  function transactionFee() external view returns (uint256);

  /// @dev Returns the protocol fee earned by the protocol.
  function protocolFee() external view returns (uint256);

  /// @dev Get the strike and maturity of the pool in the pool enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (StrikeAndMaturity memory);

  /// @dev Get the number of pools being interacted.
  function numberOfPools() external view returns (uint256);

  /// @dev Returns the total amount of liquidity in the pool.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return liquidityAmount The liquidity amount of the pool.
  function totalLiquidity(uint256 strike, uint256 maturity) external view returns (uint160 liquidityAmount);

  /// @dev Returns the square root of the interest rate of the pool.
  /// @dev the square root of interest rate is z/(x+y) where z is the short amount, x+y is the long0 amount, and y is the long1 amount.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return rate The square root of the interest rate of the pool.
  function sqrtInterestRate(uint256 strike, uint256 maturity) external view returns (uint160 rate);

  /// @dev Returns the amount of liquidity owned by the given address.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param owner The address to query the liquidity of.
  /// @return liquidityAmount The amount of liquidity owned by the given address.
  function liquidityOf(uint256 strike, uint256 maturity, address owner) external view returns (uint160 liquidityAmount);

  /// @dev It calculates the global fee and global short returned growth, which is fee increased per unit of liquidity token.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0FeeGrowth The global fee increased per unit of liquidity token for long0.
  /// @return long1FeeGrowth The global fee increased per unit of liquidity token for long1.
  /// @return shortFeeGrowth The global fee increased per unit of liquidity token for short.
  /// @return shortReturnedGrowth The global returned increased per unit of liquidity token for short.
  function feesEarnedAndShortReturnedGrowth(
    uint256 strike,
    uint256 maturity
  )
    external
    view
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth);

  /// @dev It calculates the global fee and global short returned growth, which is fee increased per unit of liquidity token.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param durationForward The duration of time moved forward.
  /// @return long0FeeGrowth The global fee increased per unit of liquidity token for long0.
  /// @return long1FeeGrowth The global fee increased per unit of liquidity token for long1.
  /// @return shortFeeGrowth The global fee increased per unit of liquidity token for short.
  /// @return shortReturnedGrowth The global returned increased per unit of liquidity token for short.
  function feesEarnedAndShortReturnedGrowth(
    uint256 strike,
    uint256 maturity,
    uint96 durationForward
  )
    external
    view
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth);

  /// @dev It calculates the fee earned and global short returned growth, which is short returned per unit of liquidity token.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param owner The address to query the fees earned of.
  /// @return long0Fees The amount of long0 fees owned by the given address.
  /// @return long1Fees The amount of long1 fees owned by the given address.
  /// @return shortFees The amount of short fees owned by the given address.
  /// @return shortReturned The amount of short returned owned by the given address.
  function feesEarnedAndShortReturnedOf(
    uint256 strike,
    uint256 maturity,
    address owner
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned);

  /// @dev It calculates the fee earned and global short returned growth, which is short returned per unit of liquidity token.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param owner The address to query the fees earned of.
  /// @param durationForward The duration of time moved forward.
  /// @return long0Fees The amount of long0 fees owned by the given address.
  /// @return long1Fees The amount of long1 fees owned by the given address.
  /// @return shortFees The amount of short fees owned by the given address.
  /// @return shortReturned The amount of short returned owned by the given address.
  function feesEarnedAndShortReturnedOf(
    uint256 strike,
    uint256 maturity,
    address owner,
    uint96 durationForward
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned);

  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0ProtocolFees The amount of long0 protocol fees owned by the owner of the factory contract.
  /// @return long1ProtocolFees The amount of long1 protocol fees owned by the owner of the factory contract.
  /// @return shortProtocolFees The amount of short protocol fees owned by the owner of the factory contract.
  function protocolFeesEarned(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 long0ProtocolFees, uint256 long1ProtocolFees, uint256 shortProtocolFees);

  /// @dev Returns the amount of long0 and long1 in the pool.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0Amount The amount of long0 in the pool.
  /// @return long1Amount The amount of long1 in the pool.
  function totalLongBalance(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 long0Amount, uint256 long1Amount);

  /// @dev Returns the amount of long0 and long1 adjusted for the protocol and transaction fee.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0Amount The amount of long0 in the pool, adjusted for the protocol and transaction fee.
  /// @return long1Amount The amount of long1 in the pool, adjusted for the protocol and transaction fee.
  function totalLongBalanceAdjustFees(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 long0Amount, uint256 long1Amount);

  /// @dev Returns the amount of sum of long0 and long1 converted to base denomination in the pool.
  /// @dev Returns the amount of short positions in the pool.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return longAmount The amount of sum of long0 and long1 converted to base denomination in the pool.
  /// @return shortAmount The amount of short in the pool.
  function totalPositions(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 longAmount, uint256 shortAmount);

  /* ===== UPDATE ===== */

  /// @dev Transfer liquidity positions to another address.
  /// @notice Does not transfer the transaction fees earned by the sender.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param to The recipient of the liquidity positions.
  /// @param liquidityAmount The amount of liquidity positions transferred
  function transferLiquidity(uint256 strike, uint256 maturity, address to, uint160 liquidityAmount) external;

  /// @dev initializes the pool with the given parameters.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param rate The square root of the interest rate of the pool.
  function initialize(uint256 strike, uint256 maturity, uint160 rate) external;

  /// @dev Collects the protocol fees of the pool.
  /// @dev only protocol owner can call this function.
  /// @dev if the owner enters an amount which is greater than the fee amount they have earned, withdraw only the amount they have.
  /// @param param The parameters of the collectProtocolFees.
  /// @return long0Amount The amount of long0 collected.
  /// @return long1Amount The amount of long1 collected.
  /// @return shortAmount The amount of short collected.
  function collectProtocolFees(
    TimeswapV2PoolCollectProtocolFeesParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount);

  /// @dev Collects the transaction fees of the pool.
  /// @dev only liquidity provider can call this function.
  /// @dev if the owner enters an amount which is greater than the fee amount they have earned, withdraw only the amount they have.
  /// @param param The parameters of the collectTransactionFee.
  /// @return long0Fees The amount of long0 fees collected.
  /// @return long1Fees The amount of long1 fees collected.
  /// @return shortFees The amount of short fees collected.
  /// @return shortReturned The amount of short returned collected.
  function collectTransactionFeesAndShortReturned(
    TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam calldata param
  ) external returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned);

  /// @dev deposit Short and Long tokens and mints Liquidity
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the mint function
  /// @return liquidityAmount The amount of liquidity minted.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function mint(
    TimeswapV2PoolMintParam calldata param
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Short and Long tokens and mints Liquidity
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the mint function.
  /// @param durationForward The duration of time moved forward.
  /// @return liquidityAmount The amount of liquidity minted.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function mint(
    TimeswapV2PoolMintParam calldata param,
    uint96 durationForward
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev burn Liquidity and receive Short and Long tokens
  /// @dev can be only called before the maturity.
  /// @dev after the maturity of the pool, the long0 and long1 tokens are zero. And the short tokens are added into the transaction fees.
  /// @dev if the user wants to burn the liquidity after the maturity, they should call the collectTransactionFee function.
  /// @param param it is a struct that contains the parameters of the burn function
  /// @return liquidityAmount The amount of liquidity burned.
  /// @return long0Amount The amount of long0 withdrawn.
  /// @return long1Amount The amount of long1 withdrawn.
  /// @return shortAmount The amount of short withdrawn.
  /// @return data the data used for the callbacks.
  function burn(
    TimeswapV2PoolBurnParam calldata param
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev burn Liquidity and receive Short and Long tokens
  /// @dev can be only called before the maturity.
  /// @dev after the maturity of the pool, the long0 and long1 tokens are zero. And the short tokens are added into the transaction fees.
  /// @dev if the user wants to burn the liquidity after the maturity, they should call the collectTransactionFee function.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the burn function.
  /// @param durationForward The duration of time moved forward.
  /// @return liquidityAmount The amount of liquidity burned.
  /// @return long0Amount The amount of long0 withdrawn.
  /// @return long1Amount The amount of long1 withdrawn.
  /// @return shortAmount The amount of short withdrawn.
  /// @return data the data used for the callbacks.
  function burn(
    TimeswapV2PoolBurnParam calldata param,
    uint96 durationForward
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Long tokens and receive Short tokens
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the deleverage function
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short received.
  /// @return data the data used for the callbacks.
  function deleverage(
    TimeswapV2PoolDeleverageParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Long tokens and receive Short tokens
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the deleverage function.
  /// @param durationForward The duration of time moved forward.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short received.
  /// @return data the data used for the callbacks.
  function deleverage(
    TimeswapV2PoolDeleverageParam calldata param,
    uint96 durationForward
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Short tokens and receive Long tokens
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the leverage function.
  /// @return long0Amount The amount of long0 received.
  /// @return long1Amount The amount of long1 received.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function leverage(
    TimeswapV2PoolLeverageParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Short tokens and receive Long tokens
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the leverage function.
  /// @param durationForward The duration of time moved forward.
  /// @return long0Amount The amount of long0 received.
  /// @return long1Amount The amount of long1 received.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function leverage(
    TimeswapV2PoolLeverageParam calldata param,
    uint96 durationForward
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev Deposit Long0 to receive Long1 or deposit Long1 to receive Long0.
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the rebalance function
  /// @return long0Amount The amount of long0 received/deposited.
  /// @return long1Amount The amount of long1 deposited/received.
  /// @return data the data used for the callbacks.
  function rebalance(
    TimeswapV2PoolRebalanceParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IOwnableTwoSteps} from "./IOwnableTwoSteps.sol";

/// @title The interface for the contract that deploys Timeswap V2 Pool pair contracts
/// @notice The Timeswap V2 Pool Factory facilitates creation of Timeswap V2 Pool pair.
interface ITimeswapV2PoolFactory is IOwnableTwoSteps {
  /* ===== EVENT ===== */

  /// @dev Emits when a new Timeswap V2 Pool contract is created.
  /// @param caller The address of the caller of create function.
  /// @param option The address of the option contract used by the pool.
  /// @param poolPair The address of the Timeswap V2 Pool contract created.
  event Create(address indexed caller, address indexed option, address indexed poolPair);

  /* ===== VIEW ===== */

  /// @dev Returns the address of the Timeswap V2 Option factory contract utilized by Timeswap V2 Pool factory contract.
  function optionFactory() external view returns (address);

  /// @dev Returns the fixed transaction fee used by all created Timeswap V2 Pool contract.
  function transactionFee() external view returns (uint256);

  /// @dev Returns the fixed protocol fee used by all created Timeswap V2 Pool contract.
  function protocolFee() external view returns (uint256);

  /// @dev Returns the address of a Timeswap V2 Pool.
  /// @dev Returns a zero address if the Timeswap V2 Pool does not exist.
  /// @param option The address of the option contract used by the pool.
  /// @return poolPair The address of the Timeswap V2 Pool contract or a zero address.
  function get(address option) external view returns (address poolPair);

  /// @dev Returns the address of a Timeswap V2 Pool.
  /// @dev Returns a zero address if the Timeswap V2 Pool does not exist.
  /// @param token0 The address of the smaller sized address of ERC20.
  /// @param token1 The address of the larger sized address of ERC20.
  /// @return poolPair The address of the Timeswap V2 Pool contract or a zero address.
  function get(address token0, address token1) external view returns (address poolPair);

  function getByIndex(uint256 id) external view returns (address optionPair);

  function numberOfPairs() external view returns (uint256);

  /* ===== UPDATE ===== */

  /// @dev Creates a Timeswap V2 Pool based on option parameter.
  /// @dev Cannot create a duplicate Timeswap V2 Pool with the same option parameter.
  /// @param token0 The address of the smaller sized address of ERC20.
  /// @param token1 The address of the larger sized address of ERC20.
  /// @param poolPair The address of the Timeswap V2 Pool contract created.
  function create(address token0, address token1) external returns (address poolPair);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";
import {FullMath} from "@timeswap-labs/v2-library/contracts/FullMath.sol";

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

///@title library for fees related calculations
library FeeCalculation {
  using Math for uint256;

  event ReceiveTransactionFees(TimeswapV2OptionPosition position, uint256 fees);

  /// @dev Reverts when fee overflow.
  error FeeOverflow();

  /// @dev reverts to overflow fee.
  function feeOverflow() private pure {
    revert FeeOverflow();
  }

  /// @dev Updates the new fee growth and protocol fee given the current fee growth and protocol fee.
  /// @param position The position to be updated.
  /// @param liquidity The current liquidity in the pool.
  /// @param feeGrowth The current feeGrowth in the pool.
  /// @param protocolFees The current protocolFees in the pool.
  /// @param fees The fees to be earned.
  /// @param protocolFee The protocol fee rate.
  /// @return newFeeGrowth The newly updated fee growth.
  /// @return newProtocolFees The newly updated protocol fees.
  function update(
    TimeswapV2OptionPosition position,
    uint160 liquidity,
    uint256 feeGrowth,
    uint256 protocolFees,
    uint256 fees,
    uint256 protocolFee
  ) internal returns (uint256 newFeeGrowth, uint256 newProtocolFees) {
    uint256 protocolFeesToAdd = getFeesRemoval(fees, protocolFee);
    uint256 transactionFees = fees.unsafeSub(protocolFeesToAdd);

    newFeeGrowth = feeGrowth.unsafeAdd(getFeeGrowth(transactionFees, liquidity));

    newProtocolFees = protocolFees + protocolFeesToAdd;

    emit ReceiveTransactionFees(position, transactionFees);
  }

  /// @dev get the fee given the last fee growth and the global fee growth
  /// @notice returns zero if the last fee growth is equal to the global fee growth
  /// @param liquidity The current liquidity in the pool.
  /// @param lastFeeGrowth The previous global fee growth when owner enters.
  /// @param globalFeeGrowth The current global fee growth.
  function getFees(uint160 liquidity, uint256 lastFeeGrowth, uint256 globalFeeGrowth) internal pure returns (uint256) {
    return
      globalFeeGrowth != lastFeeGrowth
        ? FullMath.mulDiv(liquidity, globalFeeGrowth.unsafeSub(lastFeeGrowth), uint256(1) << 128, false)
        : 0;
  }

  /// @dev Adds the fees to the amount.
  /// @param amount The original amount.
  /// @param fee The transaction fee rate.
  function addFees(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return FullMath.mulDiv(amount, (uint256(1) << 16), (uint256(1) << 16).unsafeSub(fee), true);
  }

  /// @dev Removes the fees from the amount.
  /// @param amount The original amount.
  /// @param fee The transaction fee rate.
  function removeFees(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return FullMath.mulDiv(amount, (uint256(1) << 16).unsafeSub(fee), uint256(1) << 16, false);
  }

  /// @dev Get the fees from an amount with fees.
  /// @param amount The amount with fees.
  /// @param fee The transaction fee rate.
  function getFeesRemoval(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return FullMath.mulDiv(amount, fee, uint256(1) << 16, true);
  }

  /// @dev Get the fees from an amount.
  /// @param amount The amount with fees.
  /// @param fee The transaction fee rate.
  function getFeesAdditional(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return FullMath.mulDiv(amount, fee, (uint256(1) << 16).unsafeSub(fee), true);
  }

  /// @dev Get the fee growth.
  /// @param feeAmount The fee amount.
  /// @param liquidity The current liquidity in the pool.
  function getFeeGrowth(uint256 feeAmount, uint160 liquidity) internal pure returns (uint256) {
    return FullMath.mulDiv(feeAmount, uint256(1) << 128, liquidity, false);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {OptionFactoryLibrary} from "@timeswap-labs/v2-option/contracts/libraries/OptionFactory.sol";

import {ITimeswapV2PoolFactory} from "../interfaces/ITimeswapV2PoolFactory.sol";

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

/// @title library for calculating poolFactory functions
/// @author Timeswap Labs
library PoolFactoryLibrary {
  using OptionFactoryLibrary for address;

  /// @dev Reverts when pool factory address is zero.
  error ZeroFactoryAddress();

  /// @dev Checks if the pool factory address is zero.
  /// @param poolFactory The pool factory address which is needed to be checked.
  function checkNotZeroFactory(address poolFactory) internal pure {
    if (poolFactory == address(0)) revert ZeroFactoryAddress();
  }

  /// @dev Get the option pair address and pool pair address.
  /// @param optionFactory The option factory contract address.
  /// @param poolFactory The pool factory contract address.
  /// @param token0 The address of the smaller address ERC20 token contract.
  /// @param token1 The address of the larger address ERC20 token contract.
  /// @return optionPair The retrieved option pair address. Zero address if not deployed.
  /// @return poolPair The retrieved pool pair address. Zero address if not deployed.
  function get(
    address optionFactory,
    address poolFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair, address poolPair) {
    optionPair = optionFactory.get(token0, token1);

    poolPair = ITimeswapV2PoolFactory(poolFactory).get(optionPair);
  }

  /// @dev Get the option pair address and pool pair address.
  /// @notice Reverts when the option or the pool is not deployed.
  /// @param optionFactory The option factory contract address.
  /// @param poolFactory The pool factory contract address.
  /// @param token0 The address of the smaller address ERC20 token contract.
  /// @param token1 The address of the larger address ERC20 token contract.
  /// @return optionPair The retrieved option pair address.
  /// @return poolPair The retrieved pool pair address.
  function getWithCheck(
    address optionFactory,
    address poolFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair, address poolPair) {
    optionPair = optionFactory.getWithCheck(token0, token1);

    poolPair = ITimeswapV2PoolFactory(poolFactory).get(optionPair);

    if (poolPair == address(0)) Error.zeroAddress();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title library for renentrancy protection
/// @author Timeswap Labs
library ReentrancyGuard {
  /// @dev Reverts when their is a reentrancy to a single option.
  error NoReentrantCall();

  /// @dev Reverts when the option, pool, or token id is not interacted yet.
  error NotInteracted();

  /// @dev The initial state which must be change to NOT_ENTERED when first interacting.
  uint96 internal constant NOT_INTERACTED = 0;

  /// @dev The initial and ending state of balanceTarget in the Option struct.
  uint96 internal constant NOT_ENTERED = 1;

  /// @dev The state where the contract is currently being interacted with.
  uint96 internal constant ENTERED = 2;

  /// @dev Check if there is a reentrancy in an option.
  /// @notice Reverts when balanceTarget is not zero.
  /// @param reentrancyGuard The balance being inquired.
  function check(uint96 reentrancyGuard) internal pure {
    if (reentrancyGuard == NOT_INTERACTED) revert NotInteracted();
    if (reentrancyGuard == ENTERED) revert NoReentrantCall();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {TimeswapV2PoolMint, TimeswapV2PoolBurn, TimeswapV2PoolDeleverage, TimeswapV2PoolLeverage, TimeswapV2PoolRebalance, TransactionLibrary} from "../enums/Transaction.sol";

/// @dev The parameter for collectProtocolFees functions.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param shortTo The recipient of short positions.
/// @param long0Requested The maximum amount of long0 positions wanted.
/// @param long1Requested The maximum amount of long1 positions wanted.
/// @param shortRequested The maximum amount of short positions wanted.
struct TimeswapV2PoolCollectProtocolFeesParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  uint256 long0Requested;
  uint256 long1Requested;
  uint256 shortRequested;
}

/// @dev The parameter for collectTransactionFeesAndShortReturned functions.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0FeesTo The recipient of long0 fees.
/// @param long1FeesTo The recipient of long1 fees.
/// @param shortFeesTo The recipient of short fees.
/// @param shortReturnedTo The recipient of short returned.
/// @param long0FeesRequested The maximum amount of long0 fees wanted.
/// @param long1FeesRequested The maximum amount of long1 fees wanted.
/// @param shortFeesRequested The maximum amount of short fees wanted.
/// @param shortReturnedRequested The maximum amount of short returned wanted.
struct TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam {
  uint256 strike;
  uint256 maturity;
  address long0FeesTo;
  address long1FeesTo;
  address shortFeesTo;
  address shortReturnedTo;
  uint256 long0FeesRequested;
  uint256 long1FeesRequested;
  uint256 shortFeesRequested;
  uint256 shortReturnedRequested;
}

/// @dev The parameter for mint function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param to The recipient of liquidity positions.
/// @param transaction The type of mint transaction, more information in Transaction module.
/// @param delta If transaction is GivenLiquidity, the amount of liquidity minted. Note that this value must be uint160.
/// If transaction is GivenLong, the amount of long position in base denomination to be deposited.
/// If transaction is GivenShort, the amount of short position to be deposited.
/// @param data The data to be sent to the function, which will go to the mint choice callback.
struct TimeswapV2PoolMintParam {
  uint256 strike;
  uint256 maturity;
  address to;
  TimeswapV2PoolMint transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for burn function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param shortTo The recipient of short positions.
/// @param transaction The type of burn transaction, more information in Transaction module.
/// @param delta If transaction is GivenLiquidity, the amount of liquidity burnt. Note that this value must be uint160.
/// If transaction is GivenLong, the amount of long position in base denomination to be withdrawn.
/// If transaction is GivenShort, the amount of short position to be withdrawn.
/// @param data The data to be sent to the function, which will go to the burn choice callback.
struct TimeswapV2PoolBurnParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  TimeswapV2PoolBurn transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for deleverage function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param to The recipient of short positions.
/// @param transaction The type of deleverage transaction, more information in Transaction module.
/// @param delta If transaction is GivenDeltaSqrtInterestRate, the decrease in square root interest rate.
/// If transaction is GivenLong, the amount of long position in base denomination to be deposited.
/// If transaction is GivenShort, the amount of short position to be withdrawn.
/// If transaction is  GivenSum, the sum amount of long position in base denomination to be deposited, and short position to be withdrawn.
/// @param data The data to be sent to the function, which will go to the deleverage choice callback.
struct TimeswapV2PoolDeleverageParam {
  uint256 strike;
  uint256 maturity;
  address to;
  TimeswapV2PoolDeleverage transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for leverage function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param transaction The type of leverage transaction, more information in Transaction module.
/// @param delta If transaction is GivenDeltaSqrtInterestRate, the increase in square root interest rate.
/// If transaction is GivenLong, the amount of long position in base denomination to be withdrawn.
/// If transaction is GivenShort, the amount of short position to be deposited.
/// If transaction is  GivenSum, the sum amount of long position in base denomination to be withdrawn, and short position to be deposited.
/// @param data The data to be sent to the function, which will go to the leverage choice callback.
struct TimeswapV2PoolLeverageParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  TimeswapV2PoolLeverage transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for rebalance function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param to When Long0ToLong1, the recipient of long1 positions.
/// When Long1ToLong0, the recipient of long0 positions.
/// @param isLong0ToLong1 Long0ToLong1 when true. Long1ToLong0 when false.
/// @param transaction The type of rebalance transaction, more information in Transaction module.
/// @param delta If transaction is GivenLong0 and Long0ToLong1, the amount of long0 positions to be deposited.
/// If transaction is GivenLong0 and Long1ToLong0, the amount of long1 positions to be withdrawn.
/// If transaction is GivenLong1 and Long0ToLong1, the amount of long1 positions to be withdrawn.
/// If transaction is GivenLong1 and Long1ToLong0, the amount of long1 positions to be deposited.
/// @param data The data to be sent to the function, which will go to the rebalance callback.
struct TimeswapV2PoolRebalanceParam {
  uint256 strike;
  uint256 maturity;
  address to;
  bool isLong0ToLong1;
  TimeswapV2PoolRebalance transaction;
  uint256 delta;
  bytes data;
}

library ParamLibrary {
  /// @dev Sanity checks
  /// @param param the parameter for collectProtocolFees transaction.
  function check(TimeswapV2PoolCollectProtocolFeesParam memory param) internal pure {
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if ((param.long0Requested == 0 && param.long1Requested == 0 && param.shortRequested == 0) || param.strike == 0)
      Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for collectTransactionFeesAndShortReturned transaction.
  function check(TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam memory param) internal pure {
    if (
      param.long0FeesTo == address(0) ||
      param.long1FeesTo == address(0) ||
      param.shortFeesTo == address(0) ||
      param.shortReturnedTo == address(0)
    ) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (
      (param.long0FeesRequested == 0 &&
        param.long1FeesRequested == 0 &&
        param.shortFeesRequested == 0 &&
        param.shortReturnedRequested == 0) || param.strike == 0
    ) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for mint transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolMintParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.to == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for burn transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolBurnParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();

    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for deleverage transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolDeleverageParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.to == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for leverage transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolLeverageParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.long0To == address(0) || param.long1To == address(0)) Error.zeroAddress();

    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for rebalance transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolRebalanceParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.to == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }
}

// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import {IERC1155Enumerable} from "../interfaces/IERC1155Enumerable.sol";

/// Extension of {ERC1155} that adds
/// enumerability of all the token ids in the contract as well as all token ids owned by each
/// account.
abstract contract ERC1155Enumerable is IERC1155Enumerable, ERC1155 {
  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) private _ownedTokens; // An index of all tokens

  // Mapping from address to token ID to index of the owner tokens list
  mapping(address => mapping(uint256 => uint256)) private _ownedTokensIndex;

  mapping(uint256 => uint256) private _idTotalSupply;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  /// @inheritdoc IERC1155Enumerable
  function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
    return _ownedTokens[owner][index];
  }

  /// @inheritdoc IERC1155Enumerable
  function totalIds() external view override returns (uint256) {
    return _allTokens.length;
  }

  /// @inheritdoc IERC1155Enumerable
  function totalSupply(uint256 id) external view override returns (uint256) {
    return _idTotalSupply[id];
  }

  /// @inheritdoc IERC1155Enumerable
  function tokenByIndex(uint256 index) external view override returns (uint256) {
    return _allTokens[index];
  }

  /// @dev Hook that is called before any token transfer. This includes minting
  /// and burning.
  function _beforeTokenTransfer(
    address,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory
  ) internal virtual override {
    for (uint256 i; i < ids.length; ) {
      if (amounts[i] != 0) _addTokenEnumeration(from, to, ids[i], amounts[i]);

      unchecked {
        ++i;
      }
    }
  }

  /// @dev Add token enumeration list if necessary.
  function _addTokenEnumeration(address from, address to, uint256 id, uint256 amount) internal {
    if (from == address(0)) {
      if (_idTotalSupply[id] == 0 && _additionalConditionAddTokenToAllTokensEnumeration(id))
        _addTokenToAllTokensEnumeration(id);
      _idTotalSupply[id] += amount;
    }

    if (to != address(0) && to != from) {
      if (balanceOf(to, id) == 0 && _additionalConditionAddTokenToOwnerEnumeration(to, id))
        _addTokenToOwnerEnumeration(to, id);
    }
  }

  /// @dev Any additional condition to add token enumeration when overridden.
  function _additionalConditionAddTokenToAllTokensEnumeration(uint256) internal virtual returns (bool) {
    return true;
  }

  /// @dev Any additional condition to add token enumeration when overridden.
  function _additionalConditionAddTokenToOwnerEnumeration(address, uint256) internal virtual returns (bool) {
    return true;
  }

  /// @dev Hook that is called after any token transfer. This includes minting
  /// and burning.
  function _afterTokenTransfer(
    address,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory
  ) internal virtual override {
    for (uint256 i; i < ids.length; ) {
      if (amounts[i] != 0) _removeTokenEnumeration(from, to, ids[i], amounts[i]);

      unchecked {
        ++i;
      }
    }
  }

  /// @dev Remove token enumeration list if necessary.
  function _removeTokenEnumeration(address from, address to, uint256 id, uint256 amount) internal {
    if (to == address(0)) {
      _idTotalSupply[id] -= amount;
      if (_idTotalSupply[id] == 0 && _additionalConditionRemoveTokenFromAllTokensEnumeration(id))
        _removeTokenFromAllTokensEnumeration(id);
    }

    if (from != address(0) && from != to) {
      if (balanceOf(from, id) == 0 && _additionalConditionRemoveTokenFromOwnerEnumeration(from, id))
        _removeTokenFromOwnerEnumeration(from, id);
    }
  }

  /// @dev Any additional condition to remove token enumeration when overridden.
  function _additionalConditionRemoveTokenFromAllTokensEnumeration(uint256) internal virtual returns (bool) {
    return true;
  }

  /// @dev Any additional condition to remove token enumeration when overridden.
  function _additionalConditionRemoveTokenFromOwnerEnumeration(address, uint256) internal virtual returns (bool) {
    return true;
  }

  /// @dev Private function to add a token to this extension's ownership-tracking data structures.
  /// @param to address representing the new owner of the given token ID
  /// @param tokenId uint256 ID of the token to be added to the tokens list of the given address
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    _ownedTokensIndex[to][tokenId] = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
  }

  /// @dev Private function to add a token to this extension's token tracking data structures.
  /// @param tokenId uint256 ID of the token to be added to the tokens list
  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  /// @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
  /// while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
  /// gas optimizations e.g. when performing a transfer operation (avoiding double writes).
  /// This has O(1) time complexity, but alters the order of the _ownedTokens array.
  /// @param from address representing the previous owner of the given token ID
  /// @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    uint256 lastTokenIndex = _ownedTokens[from].length - 1;
    uint256 tokenIndex = _ownedTokensIndex[from][tokenId];

    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId;
      _ownedTokensIndex[from][lastTokenId] = tokenIndex;
    }

    delete _ownedTokensIndex[from][tokenId];
    _ownedTokens[from].pop();
  }

  /// @dev Private function to remove a token from this extension's token tracking data structures.
  /// This has O(1) time complexity, but alters the order of the _allTokens array.
  /// @param tokenId uint256 ID of the token to be removed from the tokens list
  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];

    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _allTokens[lastTokenIndex];

      _allTokens[tokenIndex] = lastTokenId;
      _allTokensIndex[lastTokenId] = tokenIndex;
    }

    delete _allTokensIndex[tokenId];
    _allTokens.pop();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2LiquidityTokenBurnCallbackParam} from "../../structs/CallbackParam.sol";

interface ITimeswapV2LiquidityTokenBurnCallback {
  /// @dev Callback for `ITimeswapV2LiquidityToken.burn`
  function timeswapV2LiquidityTokenBurnCallback(
    TimeswapV2LiquidityTokenBurnCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2LiquidityTokenCollectCallbackParam} from "../../structs/CallbackParam.sol";

interface ITimeswapV2LiquidityTokenCollectCallback {
  /// @dev Callback for `ITimeswapV2LiquidityToken.collect`
  function timeswapV2LiquidityTokenCollectCallback(
    TimeswapV2LiquidityTokenCollectCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2LiquidityTokenMintCallbackParam} from "../../structs/CallbackParam.sol";

interface ITimeswapV2LiquidityTokenMintCallback {
  /// @dev Callback for `ITimeswapV2LiquidityToken.mint`
  function timeswapV2LiquidityTokenMintCallback(
    TimeswapV2LiquidityTokenMintCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title ERC-1155 Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
interface IERC1155Enumerable is IERC1155 {
  /// @dev Returns the total amount of ids with positive supply stored by the contract.
  function totalIds() external view returns (uint256);

  /// @dev Returns the total supply of a token given its id.
  /// @param id The index of the queried token.
  function totalSupply(uint256 id) external view returns (uint256);

  /// @dev Returns a token ID owned by `owner` at a given `index` of its token list.
  /// Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  /// @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
  /// Use along with {totalSupply} to enumerate all tokens.
  function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC1155Enumerable} from "./IERC1155Enumerable.sol";

import {TimeswapV2LiquidityTokenPosition} from "../structs/Position.sol";
import {TimeswapV2LiquidityTokenMintParam, TimeswapV2LiquidityTokenBurnParam, TimeswapV2LiquidityTokenCollectParam} from "../structs/Param.sol";

/// @title An interface for TS-V2 liquidity token system
interface ITimeswapV2LiquidityToken is IERC1155Enumerable {
  error NotApprovedToTransferFees();

  /// @dev Returns the option factory address.
  /// @return optionFactory The option factory address.
  function optionFactory() external view returns (address);

  /// @dev Returns the pool factory address.
  /// @return poolFactory The pool factory address.
  function poolFactory() external view returns (address);

  /// @dev Returns the position Balance of the owner
  /// @param owner The owner of the token
  /// @param position The liquidity position
  function positionOf(
    address owner,
    TimeswapV2LiquidityTokenPosition calldata position
  ) external view returns (uint256 amount);

  /// @dev Returns the fee and short returned growth of the pool
  /// @param position The liquidity position
  /// @return long0FeeGrowth The long0 fee growth
  /// @return long1FeeGrowth The long1 fee growth
  /// @return shortFeeGrowth The short fee growth
  /// @return shortReturnedGrowth The short returned growth
  function feesEarnedAndShortReturnedGrowth(
    TimeswapV2LiquidityTokenPosition calldata position
  )
    external
    view
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth);

  /// @dev Returns the fee and short returned growth of the pool
  /// @param position The liquidity position
  /// @param durationForward The time duration forward
  /// @return long0FeeGrowth The long0 fee growth
  /// @return long1FeeGrowth The long1 fee growth
  /// @return shortFeeGrowth The short fee growth
  /// @return shortReturnedGrowth The short returned growth
  function feesEarnedAndShortReturnedGrowth(
    TimeswapV2LiquidityTokenPosition calldata position,
    uint96 durationForward
  )
    external
    view
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth);

  /// @param owner The address to query the fees earned and short returned of.
  /// @param position The liquidity token position.
  /// @return long0Fees The amount of long0 fees owned by the given address.
  /// @return long1Fees The amount of long1 fees owned by the given address.
  /// @return shortFees The amount of short fees owned by the given address.
  /// @return shortReturned The amount of short returned owned by the given address.
  function feesEarnedAndShortReturnedOf(
    address owner,
    TimeswapV2LiquidityTokenPosition calldata position
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned);

  /// @param owner The address to query the fees earned and short returned of.
  /// @param position The liquidity token position.
  /// @param durationForward The time duration forward
  /// @return long0Fees The amount of long0 fees owned by the given address.
  /// @return long1Fees The amount of long1 fees owned by the given address.
  /// @return shortFees The amount of short fees owned by the given address.
  /// @return shortReturned The amount of short returned owned by the given address.
  function feesEarnedAndShortReturnedOf(
    address owner,
    TimeswapV2LiquidityTokenPosition calldata position,
    uint96 durationForward
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned);

  /// @dev Transfers position token TimeswapV2Token from `from` to `to`
  /// @param from The address to transfer position token from
  /// @param to The address to transfer position token to
  /// @param position The TimeswapV2Token Position to transfer
  /// @param liquidityAmount The amount of TimeswapV2Token Position to transfer
  /// @param erc1155Data Aribtrary custom data for erc1155 transfer
  function transferTokenPositionFrom(
    address from,
    address to,
    TimeswapV2LiquidityTokenPosition calldata position,
    uint160 liquidityAmount,
    bytes calldata erc1155Data
  ) external;

  /// @dev mints TimeswapV2LiquidityToken as per the liqudityAmount
  /// @param param The TimeswapV2LiquidityTokenMintParam
  /// @return data Arbitrary data
  function mint(TimeswapV2LiquidityTokenMintParam calldata param) external returns (bytes memory data);

  /// @dev burns TimeswapV2LiquidityToken as per the liqudityAmount
  /// @param param The TimeswapV2LiquidityTokenBurnParam
  /// @return data Arbitrary data
  function burn(TimeswapV2LiquidityTokenBurnParam calldata param) external returns (bytes memory data);

  /// @dev collects fees as per the fees desired
  /// @param param The TimeswapV2LiquidityTokenBurnParam
  /// @return long0Fees Fees for long0
  /// @return long1Fees Fees for long1
  /// @return shortFees Fees for short
  /// @return shortReturned Short Returned
  function collect(
    TimeswapV2LiquidityTokenCollectParam calldata param
  )
    external
    returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned, bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev parameter for minting Timeswap V2 Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0Amount The amount of long0 deposited.
/// @param long1Amount The amount of long1 deposited.
/// @param shortAmount The amount of short deposited.
/// @param data Arbitrary data passed to the callback.
struct TimeswapV2TokenMintCallbackParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev parameter for burning Timeswap V2 Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0Amount The amount of long0 withdrawn.
/// @param long1Amount The amount of long1 withdrawn.
/// @param shortAmount The amount of short withdrawn.
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2TokenBurnCallbackParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param liquidity The amount of liquidity increase.
/// @param data data
struct TimeswapV2LiquidityTokenMintCallbackParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint160 liquidityAmount;
  bytes data;
}

/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param liquidity The amount of liquidity decrease.
/// @param data data
struct TimeswapV2LiquidityTokenBurnCallbackParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint160 liquidityAmount;
  bytes data;
}

/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0Fees The amount of long0 fees withdrawn.
/// @param long1Fees The amount of long1 fees withdrawn.
/// @param shortFees The amount of short fees withdrawn.
/// @param shortReturned The amount of short returned withdrawn.
/// @param data data
struct TimeswapV2LiquidityTokenCollectCallbackParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  uint256 shortReturned;
  bytes data;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {FeeCalculation} from "@timeswap-labs/v2-pool/contracts/libraries/FeeCalculation.sol";
import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";

struct FeesPosition {
  uint256 long0FeeGrowth;
  uint256 long1FeeGrowth;
  uint256 shortFeeGrowth;
  uint256 shortReturnedGrowth;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  uint256 shortReturned;
}

/// @title library for calulating the fees earned
library FeesPositionLibrary {
  /// @dev returns the fees earned and short returned for a given position, liquidity and respective fee growths
  function feesEarnedAndShortReturnedOf(
    FeesPosition memory feesPosition,
    uint160 liquidity,
    uint256 long0FeeGrowth,
    uint256 long1FeeGrowth,
    uint256 shortFeeGrowth,
    uint256 shortReturnedGrowth
  ) internal pure returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned) {
    long0Fees = feesPosition.long0Fees + FeeCalculation.getFees(liquidity, feesPosition.long0FeeGrowth, long0FeeGrowth);
    long1Fees = feesPosition.long1Fees + FeeCalculation.getFees(liquidity, feesPosition.long1FeeGrowth, long1FeeGrowth);
    shortFees = feesPosition.shortFees + FeeCalculation.getFees(liquidity, feesPosition.shortFeeGrowth, shortFeeGrowth);
    shortReturned =
      feesPosition.shortReturned +
      FeeCalculation.getFees(liquidity, feesPosition.shortReturnedGrowth, shortReturnedGrowth);
  }

  /// @dev update fee for a given position, liquidity and respective feeGrowth
  function update(
    FeesPosition storage feesPosition,
    uint160 liquidity,
    uint256 long0FeeGrowth,
    uint256 long1FeeGrowth,
    uint256 shortFeeGrowth,
    uint256 shortReturnedGrowth
  ) internal {
    if (liquidity != 0) {
      feesPosition.long0Fees += FeeCalculation.getFees(liquidity, feesPosition.long0FeeGrowth, long0FeeGrowth);
      feesPosition.long1Fees += FeeCalculation.getFees(liquidity, feesPosition.long1FeeGrowth, long1FeeGrowth);
      feesPosition.shortFees += FeeCalculation.getFees(liquidity, feesPosition.shortFeeGrowth, shortFeeGrowth);
      feesPosition.shortReturned += FeeCalculation.getFees(
        liquidity,
        feesPosition.shortReturnedGrowth,
        shortReturnedGrowth
      );
    }

    feesPosition.long0FeeGrowth = long0FeeGrowth;
    feesPosition.long1FeeGrowth = long1FeeGrowth;
    feesPosition.shortFeeGrowth = shortFeeGrowth;
    feesPosition.shortReturnedGrowth = shortReturnedGrowth;
  }

  /// @dev get the fees and short returned given the position
  function getFeesAndShortReturned(
    FeesPosition storage feesPosition,
    uint256 long0FeesDesired,
    uint256 long1FeesDesired,
    uint256 shortFeesDesired,
    uint256 shortReturnedDesired
  ) internal view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned) {
    long0Fees = Math.min(feesPosition.long0Fees, long0FeesDesired);
    long1Fees = Math.min(feesPosition.long1Fees, long1FeesDesired);
    shortFees = Math.min(feesPosition.shortFees, shortFeesDesired);
    shortReturned = Math.min(feesPosition.shortReturned, shortReturnedDesired);
  }

  /// @dev remove fees and short returned from the position
  function burn(
    FeesPosition storage feesPosition,
    uint256 long0Fees,
    uint256 long1Fees,
    uint256 shortFees,
    uint256 shortReturned
  ) internal {
    feesPosition.long0Fees -= long0Fees;
    feesPosition.long1Fees -= long1Fees;
    feesPosition.shortFees -= shortFees;
    feesPosition.shortReturned -= shortReturned;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

/// @dev parameter for minting Timeswap V2 Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0To The address of the recipient of TimeswapV2Token representing long0 position.
/// @param long1To The address of the recipient of TimeswapV2Token representing long1 position.
/// @param shortTo The address of the recipient of TimeswapV2Token representing short position.
/// @param long0Amount The amount of long0 deposited.
/// @param long1Amount The amount of long1 deposited.
/// @param shortAmount The amount of short deposited.
/// @param data Arbitrary data passed to the callback.
struct TimeswapV2TokenMintParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev parameter for burning Timeswap V2 Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0To  The address of the recipient of long token0 position.
/// @param long1To The address of the recipient of long token1 position.
/// @param shortTo The address of the recipient of short position.
/// @param long0Amount  The amount of TimeswapV2Token long0  deposited and equivalent long0 position is withdrawn.
/// @param long1Amount The amount of TimeswapV2Token long1 deposited and equivalent long1 position is withdrawn.
/// @param shortAmount The amount of TimeswapV2Token short deposited and equivalent short position is withdrawn,
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2TokenBurnParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev parameter for minting Timeswap V2 Liquidity Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param to The address of the recipient of TimeswapV2LiquidityToken.
/// @param liquidityAmount The amount of liquidity token deposited.
/// @param data Arbitrary data passed to the callback.
/// @param erc1155Data Arbitrary custojm data passed through erc115 minting.
struct TimeswapV2LiquidityTokenMintParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint160 liquidityAmount;
  bytes data;
  bytes erc1155Data;
}

/// @dev parameter for burning Timeswap V2 Liquidity Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param to The address of the recipient of the liquidity token.
/// @param liquidityAmount The amount of liquidity token withdrawn.
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2LiquidityTokenBurnParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev parameter for collecting fees and shortReturned from Timeswap V2 Liquidity Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param from The address of the owner of the fees and shortReturned;
/// @param long0FeesTo The address of the recipient of the long0 fees.
/// @param long1FeesTo The address of the recipient of the long1 fees.
/// @param shortFeesTo The address of the recipient of the short fees.
/// @param shortReturnedTo The address of the recipient of the short returned.
/// @param long0FeesDesired The maximum amount of long0Fees desired to be withdrawn.
/// @param long1FeesDesired The maximum amount of long1Fees desired to be withdrawn.
/// @param shortFeesDesired The maximum amount of shortFees desired to be withdrawn.
/// @param shortReturnedDesired The maximum amount of shortReturned desired to be withdrawn.
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2LiquidityTokenCollectParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address from;
  address long0FeesTo;
  address long1FeesTo;
  address shortFeesTo;
  address shortReturnedTo;
  uint256 long0FeesDesired;
  uint256 long1FeesDesired;
  uint256 shortFeesDesired;
  uint256 shortReturnedDesired;
  bytes data;
}

library ParamLibrary {
  /// @dev Sanity checks for token mint.
  function check(TimeswapV2TokenMintParam memory param) internal pure {
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.long0Amount == 0 && param.long1Amount == 0 && param.shortAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for token burn.
  function check(TimeswapV2TokenBurnParam memory param) internal pure {
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.long0Amount == 0 && param.long1Amount == 0 && param.shortAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity token mint.
  function check(TimeswapV2LiquidityTokenMintParam memory param) internal pure {
    if (param.to == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.liquidityAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity token burn.
  function check(TimeswapV2LiquidityTokenBurnParam memory param) internal pure {
    if (param.to == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.liquidityAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity token collect.
  function check(TimeswapV2LiquidityTokenCollectParam memory param) internal pure {
    if (
      param.from == address(0) ||
      param.long0FeesTo == address(0) ||
      param.long1FeesTo == address(0) ||
      param.shortFeesTo == address(0) ||
      param.shortReturnedTo == address(0)
    ) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (
      param.long0FeesDesired == 0 &&
      param.long1FeesDesired == 0 &&
      param.shortFeesDesired == 0 &&
      param.shortReturnedDesired == 0
    ) Error.zeroInput();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {FeeCalculation} from "@timeswap-labs/v2-pool/contracts/libraries/FeeCalculation.sol";

struct PoolPosition {
  uint256 long0FeeGrowth;
  uint256 long1FeeGrowth;
  uint256 shortFeeGrowth;
  uint256 shortReturnedGrowth;
}

library PoolPositionLibrary {
  /// @dev update fee for a given position, liquidity and respective feeGrowth
  function update(
    PoolPosition storage poolPosition,
    uint160 liquidity,
    uint256 long0Fees,
    uint256 long1Fees,
    uint256 shortFees,
    uint256 shortReturned
  ) internal {
    poolPosition.long0FeeGrowth += FeeCalculation.getFeeGrowth(long0Fees, liquidity);
    poolPosition.long1FeeGrowth += FeeCalculation.getFeeGrowth(long1Fees, liquidity);
    poolPosition.shortFeeGrowth += FeeCalculation.getFeeGrowth(shortFees, liquidity);
    poolPosition.shortReturnedGrowth += FeeCalculation.getFeeGrowth(shortReturned, liquidity);
  }

  function getFeesAndShortReturnedGrowth(
    PoolPosition memory poolPosition,
    uint160 liquidity,
    uint256 long0Fees,
    uint256 long1Fees,
    uint256 shortFees,
    uint256 shortReturned
  )
    internal
    pure
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth)
  {
    long0FeeGrowth = poolPosition.long0FeeGrowth + FeeCalculation.getFeeGrowth(long0Fees, liquidity);
    long1FeeGrowth = poolPosition.long1FeeGrowth + FeeCalculation.getFeeGrowth(long1Fees, liquidity);
    shortFeeGrowth = poolPosition.shortFeeGrowth + FeeCalculation.getFeeGrowth(shortFees, liquidity);
    shortReturnedGrowth = poolPosition.shortReturnedGrowth + FeeCalculation.getFeeGrowth(shortReturned, liquidity);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

/// @dev Struct for Token
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param position The position of the option.
struct TimeswapV2TokenPosition {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  TimeswapV2OptionPosition position;
}

/// @dev Struct for Liquidity Token
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
struct TimeswapV2LiquidityTokenPosition {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
}

library PositionLibrary {
  /// @dev return keccak for key management for Token.
  function toKey(TimeswapV2TokenPosition memory timeswapV2TokenPosition) internal pure returns (bytes32) {
    return keccak256(abi.encode(timeswapV2TokenPosition));
  }

  /// @dev return keccak for key management for Liquidity Token.
  function toKey(
    TimeswapV2LiquidityTokenPosition memory timeswapV2LiquidityTokenPosition
  ) internal pure returns (bytes32) {
    return keccak256(abi.encode(timeswapV2LiquidityTokenPosition));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2Option} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2Option.sol";
import {OptionFactoryLibrary} from "@timeswap-labs/v2-option/contracts/libraries/OptionFactory.sol";
import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {ITimeswapV2Pool} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2Pool.sol";
import {PoolFactoryLibrary} from "@timeswap-labs/v2-pool/contracts/libraries/PoolFactory.sol";
import {ReentrancyGuard} from "@timeswap-labs/v2-pool/contracts/libraries/ReentrancyGuard.sol";

import {TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam} from "@timeswap-labs/v2-pool/contracts/structs/Param.sol";

import {ITimeswapV2LiquidityToken} from "./interfaces/ITimeswapV2LiquidityToken.sol";

import {ITimeswapV2LiquidityTokenMintCallback} from "./interfaces/callbacks/ITimeswapV2LiquidityTokenMintCallback.sol";
import {ITimeswapV2LiquidityTokenBurnCallback} from "./interfaces/callbacks/ITimeswapV2LiquidityTokenBurnCallback.sol";
import {ITimeswapV2LiquidityTokenCollectCallback} from "./interfaces/callbacks/ITimeswapV2LiquidityTokenCollectCallback.sol";

import {ERC1155Enumerable} from "./base/ERC1155Enumerable.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import {TimeswapV2LiquidityTokenPosition, PositionLibrary} from "./structs/Position.sol";
import {FeesPosition, FeesPositionLibrary} from "./structs/FeesPosition.sol";
import {PoolPosition, PoolPositionLibrary} from "./structs/PoolPosition.sol";
import {TimeswapV2LiquidityTokenMintParam, TimeswapV2LiquidityTokenBurnParam, TimeswapV2LiquidityTokenCollectParam, ParamLibrary} from "./structs/Param.sol";
import {TimeswapV2LiquidityTokenMintCallbackParam, TimeswapV2LiquidityTokenBurnCallbackParam, TimeswapV2LiquidityTokenCollectCallbackParam} from "./structs/CallbackParam.sol";
import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

/// @title An implementation for TS-V2 liquidity token system
/// @author Timeswap Labs
contract TimeswapV2LiquidityToken is ITimeswapV2LiquidityToken, ERC1155Enumerable {
  using ReentrancyGuard for uint96;

  using PositionLibrary for TimeswapV2LiquidityTokenPosition;
  using FeesPositionLibrary for FeesPosition;
  using PoolPositionLibrary for PoolPosition;

  address public immutable optionFactory;
  address public immutable poolFactory;

  constructor(
    address chosenOptionFactory,
    address chosenPoolFactory,
    string memory uri
  ) ERC1155("Timeswap V2 Liquidity Token") {
    optionFactory = chosenOptionFactory;
    poolFactory = chosenPoolFactory;
    _setURI(uri);
  }

  mapping(bytes32 => uint96) private reentrancyGuards;

  mapping(uint256 => TimeswapV2LiquidityTokenPosition) private _timeswapV2LiquidityTokenPositions;

  mapping(bytes32 => uint256) private _timeswapV2LiquidityTokenPositionIds;

  mapping(uint256 => PoolPosition) private _poolPositions;

  mapping(uint256 => mapping(address => FeesPosition)) private _feesPositions;

  mapping(uint256 => uint256) private _totalSupply;

  uint256 private counter;

  function changeInteractedIfNecessary(bytes32 key) private {
    if (reentrancyGuards[key] == ReentrancyGuard.NOT_INTERACTED) reentrancyGuards[key] = ReentrancyGuard.NOT_ENTERED;
  }

  /// @dev internal function to start the reentrancy guard
  function raiseGuard(bytes32 key) private {
    reentrancyGuards[key].check();
    reentrancyGuards[key] = ReentrancyGuard.ENTERED;
  }

  /// @dev internal function to end the reentrancy guard
  function lowerGuard(bytes32 key) private {
    reentrancyGuards[key] = ReentrancyGuard.NOT_ENTERED;
  }

  /// @inheritdoc ITimeswapV2LiquidityToken
  function positionOf(
    address owner,
    TimeswapV2LiquidityTokenPosition calldata timeswapV2LiquidityTokenPosition
  ) external view override returns (uint256 amount) {
    amount = balanceOf(owner, _timeswapV2LiquidityTokenPositionIds[timeswapV2LiquidityTokenPosition.toKey()]);
  }

  /// @inheritdoc ITimeswapV2LiquidityToken
  function feesEarnedAndShortReturnedGrowth(
    TimeswapV2LiquidityTokenPosition calldata timeswapV2LiquidityTokenPosition
  )
    external
    view
    override
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth)
  {
    uint256 id = _timeswapV2LiquidityTokenPositionIds[timeswapV2LiquidityTokenPosition.toKey()];

    if (_totalSupply[id] == 0) {
      PoolPosition memory poolPosition = _poolPositions[id];

      long0FeeGrowth = poolPosition.long0FeeGrowth;
      long1FeeGrowth = poolPosition.long1FeeGrowth;
      shortFeeGrowth = poolPosition.shortFeeGrowth;
      shortReturnedGrowth = poolPosition.shortReturnedGrowth;
    } else {
      (, address poolPair) = PoolFactoryLibrary.getWithCheck(
        optionFactory,
        poolFactory,
        timeswapV2LiquidityTokenPosition.token0,
        timeswapV2LiquidityTokenPosition.token1
      );

      (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned) = ITimeswapV2Pool(poolPair)
        .feesEarnedAndShortReturnedOf(
          timeswapV2LiquidityTokenPosition.strike,
          timeswapV2LiquidityTokenPosition.maturity,
          address(this)
        );

      (long0FeeGrowth, long1FeeGrowth, shortFeeGrowth, shortReturnedGrowth) = _poolPositions[id]
        .getFeesAndShortReturnedGrowth(uint160(_totalSupply[id]), long0Fees, long1Fees, shortFees, shortReturned);
    }
  }

  /// @inheritdoc ITimeswapV2LiquidityToken
  function feesEarnedAndShortReturnedGrowth(
    TimeswapV2LiquidityTokenPosition calldata timeswapV2LiquidityTokenPosition,
    uint96 durationForward
  )
    external
    view
    override
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth)
  {
    uint256 id = _timeswapV2LiquidityTokenPositionIds[timeswapV2LiquidityTokenPosition.toKey()];

    if (_totalSupply[id] == 0) {
      PoolPosition memory poolPosition = _poolPositions[id];

      long0FeeGrowth = poolPosition.long0FeeGrowth;
      long1FeeGrowth = poolPosition.long1FeeGrowth;
      shortFeeGrowth = poolPosition.shortFeeGrowth;
      shortReturnedGrowth = poolPosition.shortReturnedGrowth;
    } else {
      (, address poolPair) = PoolFactoryLibrary.getWithCheck(
        optionFactory,
        poolFactory,
        timeswapV2LiquidityTokenPosition.token0,
        timeswapV2LiquidityTokenPosition.token1
      );

      (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned) = ITimeswapV2Pool(poolPair)
        .feesEarnedAndShortReturnedOf(
          timeswapV2LiquidityTokenPosition.strike,
          timeswapV2LiquidityTokenPosition.maturity,
          address(this),
          durationForward
        );

      (long0FeeGrowth, long1FeeGrowth, shortFeeGrowth, shortReturnedGrowth) = _poolPositions[id]
        .getFeesAndShortReturnedGrowth(uint160(_totalSupply[id]), long0Fees, long1Fees, shortFees, shortReturned);
    }
  }

  /// @inheritdoc ITimeswapV2LiquidityToken
  function feesEarnedAndShortReturnedOf(
    address owner,
    TimeswapV2LiquidityTokenPosition calldata timeswapV2LiquidityTokenPosition
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned) {
    uint256 id = _timeswapV2LiquidityTokenPositionIds[timeswapV2LiquidityTokenPosition.toKey()];

    if (_totalSupply[id] == 0) {
      FeesPosition memory feesPosition = _feesPositions[id][owner];

      long0Fees = feesPosition.long0Fees;
      long1Fees = feesPosition.long1Fees;
      shortFees = feesPosition.shortFees;
      shortReturned = feesPosition.shortReturned;
    } else {
      (, address poolPair) = PoolFactoryLibrary.getWithCheck(
        optionFactory,
        poolFactory,
        timeswapV2LiquidityTokenPosition.token0,
        timeswapV2LiquidityTokenPosition.token1
      );

      (long0Fees, long1Fees, shortFees, shortReturned) = ITimeswapV2Pool(poolPair).feesEarnedAndShortReturnedOf(
        timeswapV2LiquidityTokenPosition.strike,
        timeswapV2LiquidityTokenPosition.maturity,
        address(this)
      );

      (
        uint256 long0FeeGrowth,
        uint256 long1FeeGrowth,
        uint256 shortFeeGrowth,
        uint256 shortReturnedGrowth
      ) = _poolPositions[id].getFeesAndShortReturnedGrowth(
          uint160(_totalSupply[id]),
          long0Fees,
          long1Fees,
          shortFees,
          shortReturned
        );

      FeesPosition memory feesPosition = _feesPositions[id][owner];

      (long0Fees, long1Fees, shortFees, shortReturned) = feesPosition.feesEarnedAndShortReturnedOf(
        uint160(balanceOf(owner, id)),
        long0FeeGrowth,
        long1FeeGrowth,
        shortFeeGrowth,
        shortReturnedGrowth
      );
    }
  }

  /// @inheritdoc ITimeswapV2LiquidityToken
  function feesEarnedAndShortReturnedOf(
    address owner,
    TimeswapV2LiquidityTokenPosition calldata timeswapV2LiquidityTokenPosition,
    uint96 durationForward
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned) {
    uint256 id = _timeswapV2LiquidityTokenPositionIds[timeswapV2LiquidityTokenPosition.toKey()];

    if (_totalSupply[id] == 0) {
      FeesPosition memory feesPosition = _feesPositions[id][owner];

      long0Fees = feesPosition.long0Fees;
      long1Fees = feesPosition.long1Fees;
      shortFees = feesPosition.shortFees;
      shortReturned = feesPosition.shortReturned;
    } else {
      (, address poolPair) = PoolFactoryLibrary.getWithCheck(
        optionFactory,
        poolFactory,
        timeswapV2LiquidityTokenPosition.token0,
        timeswapV2LiquidityTokenPosition.token1
      );

      (long0Fees, long1Fees, shortFees, shortReturned) = ITimeswapV2Pool(poolPair).feesEarnedAndShortReturnedOf(
        timeswapV2LiquidityTokenPosition.strike,
        timeswapV2LiquidityTokenPosition.maturity,
        address(this),
        durationForward
      );

      (
        uint256 long0FeeGrowth,
        uint256 long1FeeGrowth,
        uint256 shortFeeGrowth,
        uint256 shortReturnedGrowth
      ) = _poolPositions[id].getFeesAndShortReturnedGrowth(
          uint160(_totalSupply[id]),
          long0Fees,
          long1Fees,
          shortFees,
          shortReturned
        );

      FeesPosition memory feesPosition = _feesPositions[id][owner];

      (long0Fees, long1Fees, shortFees, shortReturned) = feesPosition.feesEarnedAndShortReturnedOf(
        uint160(balanceOf(owner, id)),
        long0FeeGrowth,
        long1FeeGrowth,
        shortFeeGrowth,
        shortReturnedGrowth
      );
    }
  }

  /// @inheritdoc ITimeswapV2LiquidityToken
  function transferTokenPositionFrom(
    address from,
    address to,
    TimeswapV2LiquidityTokenPosition calldata timeswapV2LiquidityTokenPosition,
    uint160 liquidityAmount,
    bytes calldata erc1155Data
  ) external {
    safeTransferFrom(
      from,
      to,
      _timeswapV2LiquidityTokenPositionIds[timeswapV2LiquidityTokenPosition.toKey()],
      liquidityAmount,
      erc1155Data
    );
  }

  /// @inheritdoc ITimeswapV2LiquidityToken
  function mint(TimeswapV2LiquidityTokenMintParam calldata param) external returns (bytes memory data) {
    ParamLibrary.check(param);

    TimeswapV2LiquidityTokenPosition memory timeswapV2LiquidityTokenPosition = TimeswapV2LiquidityTokenPosition({
      token0: param.token0,
      token1: param.token1,
      strike: param.strike,
      maturity: param.maturity
    });

    bytes32 key = timeswapV2LiquidityTokenPosition.toKey();
    uint256 id = _timeswapV2LiquidityTokenPositionIds[key];

    // if the position does not exist, create it
    if (id == 0) {
      id = (++counter);
      _timeswapV2LiquidityTokenPositions[id] = timeswapV2LiquidityTokenPosition;
      _timeswapV2LiquidityTokenPositionIds[key] = id;
    }

    changeInteractedIfNecessary(key);
    raiseGuard(key);

    (, address poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, param.token0, param.token1);

    // calculate the amount of liquidity tokens to mint
    uint160 liquidityBalanceTarget = ITimeswapV2Pool(poolPair).liquidityOf(
      param.strike,
      param.maturity,
      address(this)
    ) + param.liquidityAmount;

    // mint the liquidity tokens to the recipient
    _mint(param.to, id, param.liquidityAmount, param.erc1155Data);

    // ask the msg.sender to transfer the liquidity to this contract
    data = ITimeswapV2LiquidityTokenMintCallback(msg.sender).timeswapV2LiquidityTokenMintCallback(
      TimeswapV2LiquidityTokenMintCallbackParam({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        liquidityAmount: param.liquidityAmount,
        data: param.data
      })
    );

    // check if the enough liquidity amount target is received
    Error.checkEnough(
      ITimeswapV2Pool(poolPair).liquidityOf(param.strike, param.maturity, address(this)),
      liquidityBalanceTarget
    );

    // stop the reentrancy guard
    lowerGuard(key);
  }

  /// @inheritdoc ITimeswapV2LiquidityToken
  function burn(TimeswapV2LiquidityTokenBurnParam calldata param) external returns (bytes memory data) {
    ParamLibrary.check(param);

    bytes32 key = TimeswapV2LiquidityTokenPosition({
      token0: param.token0,
      token1: param.token1,
      strike: param.strike,
      maturity: param.maturity
    }).toKey();

    raiseGuard(key);

    (, address poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, param.token0, param.token1);

    // transfer the equivalent liquidity amount to the recipient from pool
    ITimeswapV2Pool(poolPair).transferLiquidity(param.strike, param.maturity, param.to, param.liquidityAmount);

    if (param.data.length != 0)
      data = ITimeswapV2LiquidityTokenBurnCallback(msg.sender).timeswapV2LiquidityTokenBurnCallback(
        TimeswapV2LiquidityTokenBurnCallbackParam({
          token0: param.token0,
          token1: param.token1,
          strike: param.strike,
          maturity: param.maturity,
          liquidityAmount: param.liquidityAmount,
          data: param.data
        })
      );

    // burn the liquidity tokens from the msg.sender
    _burn(msg.sender, _timeswapV2LiquidityTokenPositionIds[key], param.liquidityAmount);

    // stop the guard for reentrancy
    lowerGuard(key);
  }

  /// @inheritdoc ITimeswapV2LiquidityToken
  function collect(
    TimeswapV2LiquidityTokenCollectParam calldata param
  )
    external
    returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned, bytes memory data)
  {
    ParamLibrary.check(param);

    bytes32 key = TimeswapV2LiquidityTokenPosition({
      token0: param.token0,
      token1: param.token1,
      strike: param.strike,
      maturity: param.maturity
    }).toKey();

    // start the reentrancy guard
    raiseGuard(key);

    uint256 id = _timeswapV2LiquidityTokenPositionIds[key];

    if (!(param.from == msg.sender || isApprovedForAll(param.from, msg.sender))) revert NotApprovedToTransferFees();

    _updateFeesPositions(param.from, address(0), id, 0);

    (long0Fees, long1Fees, shortFees, shortReturned) = _feesPositions[id][param.from].getFeesAndShortReturned(
      param.long0FeesDesired,
      param.long1FeesDesired,
      param.shortFeesDesired,
      param.shortReturnedDesired
    );

    address optionPair = OptionFactoryLibrary.getWithCheck(optionFactory, param.token0, param.token1);

    if (long0Fees != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        param.strike,
        param.maturity,
        param.long0FeesTo,
        TimeswapV2OptionPosition.Long0,
        long0Fees
      );

    if (long1Fees != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        param.strike,
        param.maturity,
        param.long1FeesTo,
        TimeswapV2OptionPosition.Long1,
        long1Fees
      );

    if (shortFees + shortReturned != 0)
      ITimeswapV2Option(optionPair).transferPosition(
        param.strike,
        param.maturity,
        param.shortFeesTo,
        TimeswapV2OptionPosition.Short,
        shortFees + shortReturned
      );

    if (param.data.length != 0)
      data = ITimeswapV2LiquidityTokenCollectCallback(msg.sender).timeswapV2LiquidityTokenCollectCallback(
        TimeswapV2LiquidityTokenCollectCallbackParam({
          token0: param.token0,
          token1: param.token1,
          strike: param.strike,
          maturity: param.maturity,
          long0Fees: long0Fees,
          long1Fees: long1Fees,
          shortFees: shortFees,
          shortReturned: shortReturned,
          data: param.data
        })
      );

    // burn the desired fees and short returned from the fees position
    _feesPositions[id][param.from].burn(long0Fees, long1Fees, shortFees, shortReturned);

    // stop the reentrancy guard
    lowerGuard(key);
  }

  /// @dev utilises the beforeToken transfer hook for updating the fee positions
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i; i < ids.length; ) {
      if (amounts[i] != 0) _updateFeesPositions(from, to, ids[i], amounts[i]);

      unchecked {
        ++i;
      }
    }
  }

  /// @dev updates fee positions
  function _updateFeesPositions(address from, address to, uint256 id, uint256 amount) private {
    if (from != to) {
      TimeswapV2LiquidityTokenPosition memory timeswapV2LiquidityTokenPosition = _timeswapV2LiquidityTokenPositions[id];

      (, address poolPair) = PoolFactoryLibrary.getWithCheck(
        optionFactory,
        poolFactory,
        timeswapV2LiquidityTokenPosition.token0,
        timeswapV2LiquidityTokenPosition.token1
      );

      (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned) = ITimeswapV2Pool(poolPair)
        .collectTransactionFeesAndShortReturned(
          TimeswapV2PoolCollectTransactionFeesAndShortReturnedParam({
            strike: timeswapV2LiquidityTokenPosition.strike,
            maturity: timeswapV2LiquidityTokenPosition.maturity,
            long0FeesTo: address(this),
            long1FeesTo: address(this),
            shortFeesTo: address(this),
            shortReturnedTo: address(this),
            long0FeesRequested: timeswapV2LiquidityTokenPosition.maturity > block.timestamp ? type(uint256).max : 0,
            long1FeesRequested: timeswapV2LiquidityTokenPosition.maturity > block.timestamp ? type(uint256).max : 0,
            shortFeesRequested: type(uint256).max,
            shortReturnedRequested: type(uint256).max
          })
        );

      uint160 totalLiquidity = uint160(_totalSupply[id]);

      PoolPosition storage poolPosition = _poolPositions[id];

      if (totalLiquidity != 0) poolPosition.update(totalLiquidity, long0Fees, long1Fees, shortFees, shortReturned);

      if (from != address(0)) {
        FeesPosition storage feesPosition = _feesPositions[id][from];
        feesPosition.update(
          uint160(balanceOf(from, id)),
          poolPosition.long0FeeGrowth,
          poolPosition.long1FeeGrowth,
          poolPosition.shortFeeGrowth,
          poolPosition.shortReturnedGrowth
        );
      }

      if (to != address(0)) {
        FeesPosition storage feesPosition = _feesPositions[id][to];
        feesPosition.update(
          uint160(balanceOf(to, id)),
          poolPosition.long0FeeGrowth,
          poolPosition.long1FeeGrowth,
          poolPosition.shortFeeGrowth,
          poolPosition.shortReturnedGrowth
        );
      }

      if (from == address(0)) _totalSupply[id] += amount;
      if (to == address(0)) _totalSupply[id] -= amount;
    }
  }
}