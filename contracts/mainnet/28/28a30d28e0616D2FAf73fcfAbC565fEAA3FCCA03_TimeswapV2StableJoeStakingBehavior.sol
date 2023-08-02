// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

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
            "ERC1155: caller is not token owner nor approved"
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
            "ERC1155: caller is not token owner nor approved"
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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

pragma solidity =0.8.8;

interface IStableJoeStaking {
    event ClaimReward(address indexed user, address indexed rewardToken, uint256 amount);
    event Deposit(address indexed user, uint256 amount, uint256 fee);
    event DepositFeeChanged(uint256 newFee, uint256 oldFee);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RewardTokenAdded(address token);
    event RewardTokenRemoved(address token);
    event Withdraw(address indexed user, uint256 amount);

    function deposit(uint256 _amount) external;

    function emergencyWithdraw() external;

    function withdraw(uint256 _amount) external;

    function ACC_REWARD_PER_SHARE_PRECISION() external view returns (uint256);

    function DEPOSIT_FEE_PERCENT_PRECISION() external view returns (uint256);

    function accRewardPerShare(address) external view returns (uint256);

    function addRewardToken(address _rewardToken) external;

    function depositFeePercent() external view returns (uint256);

    function feeCollector() external view returns (address);

    function getUserInfo(address _user, address _rewardToken) external view returns (uint256, uint256);

    function initialize(address _rewardToken, address _joe, address _feeCollector, uint256 _depositFeePercent)
        external;

    function internalJoeBalance() external view returns (uint256);

    function isRewardToken(address) external view returns (bool);

    function joe() external view returns (address);

    function lastRewardBalance(address) external view returns (uint256);

    function owner() external view returns (address);

    function pendingReward(address _user, address _token) external view returns (uint256);

    function removeRewardToken(address _rewardToken) external;

    function renounceOwnership() external;

    function rewardTokens(uint256) external view returns (address);

    function rewardTokensLength() external view returns (uint256);

    function setDepositFeePercent(uint256 _depositFeePercent) external;

    function transferOwnership(address newOwner) external;

    function updateReward(address _token) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ITimeswapV2Behavior} from "../../../interfaces/ITimeswapV2Behavior.sol";

interface ITimeswapV2StableJoeStakingBehavior is ITimeswapV2Behavior {
    function stablJoeStakingProxy() external view returns (address);

    function rewardToken() external view returns (IERC20);

    function joeToken() external view returns (address);

    function pendingReward(address token, uint256 strike, uint256 maturity) external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function harvest(address token, uint256 strike, uint256 maturity, address to) external returns (uint256 amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {FullMath} from "@timeswap-labs/v2-library/contracts/FullMath.sol";

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {TimeswapV2TokenPosition} from "@timeswap-labs/v2-token/contracts/structs/Position.sol";
import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";

import {IStableJoeStaking} from "./interfaces/IStableJoeStaking.sol";
import {ITimeswapV2StableJoeStakingBehavior} from "./interfaces/ITimeswapV2StableJoeStakingBehavior.sol";
// import "forge-std/console.sol";

import {TimeswapV2Behavior} from "../../TimeswapV2Behavior.sol";

contract TimeswapV2StableJoeStakingBehavior is ITimeswapV2StableJoeStakingBehavior, TimeswapV2Behavior {
  using SafeERC20 for IERC20;

  /// @notice The farming master contract
  address public immutable stablJoeStakingProxy;
  /// @notice The reward token
  IERC20 public immutable rewardToken;
  // /// @notice The tranche id for level
  // uint256 public immutable pid;
  /// @notice The staking token for joe
  address public immutable joeToken;
  /// @notice The reward growth
  uint256 private _rewardGrowth;

  uint256 public immutable ACC_REWARD_PER_SHARE_PRECISION;

  /// @notice The reward position to accumulate the rewards from staked level tokens
  struct RewardPosition {
    uint256 rewardGrowth;
    uint256 rewardAccumulated;
  }

  /// @notice The reward positions mapping to a user
  mapping(bytes32 => RewardPosition) private _rewardPositions;

  struct PoolRewardGrowth {
    bool hasMatured;
    uint256 rewardGrowth;
  }

  mapping(bytes32 => PoolRewardGrowth) private _poolRewardGrowths;

  constructor(
    address _timeswapV2Token,
    address _timeswapV2LendGivenPrincipal,
    address _timeswapV2CloseLendGivenPosition,
    address _timeswapV2Withdraw,
    address _timeswapV2BorrowGivenPrincipal,
    address _timeswapV2CloseBorrowGivenPosition,
    address _stablJoeStakingProxy,
    address _rewardToken
  )
    TimeswapV2Behavior(
      _timeswapV2Token,
      _timeswapV2LendGivenPrincipal,
      _timeswapV2CloseLendGivenPosition,
      _timeswapV2Withdraw,
      _timeswapV2BorrowGivenPrincipal,
      _timeswapV2CloseBorrowGivenPosition
    )
    ERC1155("")
    ERC20("ts-v2-joe", "joeYBT")
  {
    stablJoeStakingProxy = _stablJoeStakingProxy;
    rewardToken = IERC20(_rewardToken);
    joeToken = IStableJoeStaking(_stablJoeStakingProxy).joe();
    ACC_REWARD_PER_SHARE_PRECISION = IStableJoeStaking(_stablJoeStakingProxy).ACC_REWARD_PER_SHARE_PRECISION();
  }

  function mint(address to, uint256 amount) external {
    // Perform the mint requirement checks and actions
    _mintRequirement(amount);
    // Mint the tokens to the specified address
    _mint(to, amount);
  }

  function burn(address to, uint256 amount) external {
    // Burn the tokens from the caller
    _burn(msg.sender, amount);
    // Perform the burn requirement checks and actions
    _burnRequirement(to, amount);
  }

  /// @notice Get the reward amount for a user
  function pendingReward(address token, uint256 strike, uint256 maturity) external view returns (uint256 amount) {
    bytes32 poolKey = keccak256(abi.encodePacked(token, strike, maturity));

    uint256 rewardGrowth;
    uint256 poolRewardGrowth;

    if ((maturity > block.timestamp) || ((maturity <= block.timestamp) && (!_poolRewardGrowths[poolKey].hasMatured))) {
      // Get the pending reward from the farming contract
      //   pending reward = (user.amount * accRewardPerShare) - user.rewardDebt[token]

      {
        // Calculate the total staked LP tokens
        (uint256 totalStakedLPToken, uint256 rewardDebt) = IStableJoeStaking(stablJoeStakingProxy).getUserInfo(
          address(this),
          address(rewardToken)
        );
        uint256 accRewardPerShare = IStableJoeStaking(stablJoeStakingProxy).accRewardPerShare(address(rewardToken));

        uint256 rewardHarvested = FullMath.mulDiv(
          totalStakedLPToken,
          accRewardPerShare,
          ACC_REWARD_PER_SHARE_PRECISION,
          false
        ) - rewardDebt;

        if (totalStakedLPToken != 0) {
          // Calculate the updated reward growth based on the harvested reward
          rewardGrowth = _rewardGrowth + FullMath.mulDiv(rewardHarvested, 1 << 128, totalStakedLPToken, false);
        }
      }
      if ((maturity <= block.timestamp) && (!_poolRewardGrowths[poolKey].hasMatured)) {
        // If the pool has matured and not marked as matured yet, use the current reward growth
        poolRewardGrowth = rewardGrowth;
      } else {
        // Otherwise, use the reward growth stored in the pool reward growth mapping
        poolRewardGrowth = _poolRewardGrowths[poolKey].rewardGrowth;
      }
    }

    if (maturity <= block.timestamp) {
      // If the maturity has passed, use the pool reward growth for the reward calculation
      rewardGrowth = poolRewardGrowth;
    }

    {
      // Generate a unique key for the reward position
      bytes32 key = keccak256(abi.encodePacked(token, strike, maturity, msg.sender));
      // Get the reward position for the user
      RewardPosition memory rewardPosition = _rewardPositions[key];

      // Generate a unique ID for the position
      uint256 id = uint256(
        keccak256(
          abi.encodePacked(token, strike, maturity, address(this) < token ? PositionType.Long0 : PositionType.Long1)
        )
      );

      // Calculate the accumulated reward amount for the user
      amount =
        rewardPosition.rewardAccumulated +
        FullMath.mulDiv(rewardGrowth - rewardPosition.rewardGrowth, balanceOf(msg.sender, id), 1 << 128, false);
    }
  }

  function harvest(address token, uint256 strike, uint256 maturity, address to) external returns (uint256 amount) {
    // Generate a unique key for the pool using keccak256 hash function
    bytes32 poolKey = keccak256(abi.encodePacked(token, strike, maturity));

    // Check if the maturity timestamp is in the future or if the pool has not matured yet
    if ((maturity > block.timestamp) || ((maturity <= block.timestamp) && (!_poolRewardGrowths[poolKey].hasMatured))) {
      uint256 rewardHarvested;
      {
        // Get the balance of the reward token before harvesting
        uint256 rewardBefore = rewardToken.balanceOf(address(this));

        // Call the `harvest` function on the `IFarmingLevelMasterV2` contract
        IStableJoeStaking(stablJoeStakingProxy).deposit(0);

        // Calculate the harvested reward amount
        rewardHarvested = rewardToken.balanceOf(address(this)) - rewardBefore;
      }

      {
        // Get the total amount of staked LP tokens
        (uint256 totalStakedLPToken, ) = IStableJoeStaking(stablJoeStakingProxy).getUserInfo(
          address(this),
          address(rewardToken)
        );

        // Update the reward growth based on the harvested reward and staked LP tokens
        if (totalStakedLPToken != 0) {
          _rewardGrowth += FullMath.mulDiv(rewardHarvested, 1 << 128, totalStakedLPToken, false);
        }
      }

      // If the pool has matured and not marked as matured yet, perform additional actions
      if ((maturity <= block.timestamp) && (!_poolRewardGrowths[poolKey].hasMatured)) {
        // Mark the pool as matured and set the reward growth
        _poolRewardGrowths[poolKey].hasMatured = true;
        _poolRewardGrowths[poolKey].rewardGrowth = _rewardGrowth;

        {
          TimeswapV2TokenPosition memory position;
          // Determine the token order for the position
          position.token0 = address(this) < token ? address(this) : token;
          position.token1 = address(this) > token ? address(this) : token;
          position.strike = strike;
          position.maturity = maturity;
          // Determine the position type based on the token order
          position.position = address(this) < token ? TimeswapV2OptionPosition.Long0 : TimeswapV2OptionPosition.Long1;

          // Get the long position ID from the TimeswapV2Token contract
          uint256 longPosition = ITimeswapV2Token(timeswapV2Token).positionOf(address(this), position);

          // Withdraw the long position from the farming contract
          IStableJoeStaking(stablJoeStakingProxy).withdraw(longPosition);
        }
      }
    }

    {
      uint256 rewardGrowth;
      // Determine the reward growth based on the maturity timestamp
      if (maturity > block.timestamp) {
        rewardGrowth = _rewardGrowth;
      } else {
        rewardGrowth = _poolRewardGrowths[poolKey].rewardGrowth;
      }

      {
        // Generate a unique key for the reward position using keccak256 hash function
        bytes32 key = keccak256(abi.encodePacked(token, strike, maturity, msg.sender));

        // Retrieve the reward position from the mapping
        RewardPosition storage rewardPosition = _rewardPositions[key];

        // Generate a unique ID for the position using keccak256 hash function
        uint256 id = uint256(
          keccak256(
            abi.encodePacked(token, strike, maturity, address(this) < token ? PositionType.Long0 : PositionType.Long1)
          )
        );

        // Update the reward accumulation based on the reward growth, user balance, and scaling factor
        rewardPosition.rewardAccumulated += FullMath.mulDiv(
          rewardGrowth - rewardPosition.rewardGrowth,
          balanceOf(msg.sender, id),
          1 << 128,
          false
        );
        rewardPosition.rewardGrowth = rewardGrowth;

        // Set the `amount` to the accumulated reward
        amount = rewardPosition.rewardAccumulated;
        delete rewardPosition.rewardAccumulated;

        // Transfer the accumulated reward to the specified address
        rewardToken.safeTransfer(to, amount);
      }
    }
  }

  function _mintRequirement(uint256 tokenAmount) internal override {
    // Transfer `tokenAmount` of LP tokens from the caller to the contract
    IERC20(joeToken).safeTransferFrom(msg.sender, address(this), tokenAmount);
  }

  function _burnRequirement(address to, uint256 tokenAmount) internal override {
    // Transfer `tokenAmount` of LP tokens from the contract to the specified address
    IERC20(joeToken).safeTransfer(to, tokenAmount);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override {
    // Call the base contract's `_beforeTokenTransfer` function
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    // Loop through the `ids` array
    for (uint256 i; i < ids.length; ) {
      // If the `amounts[i]` is not zero, update the reward positions
      if (amounts[i] != 0) _updateRewardPositions(from, to, ids[i], amounts[i]);

      unchecked {
        ++i;
      }
    }
  }

  // function to update reward positions
  function _updateRewardPositions(address from, address to, uint256 id, uint256 tokenAmount) private {
    // Retrieve the position parameters for the given `id`
    PositionParam memory positionParam = positionParams(id);
    // Generate a unique key for the pool using keccak256 hash function
    bytes32 poolKey = keccak256(abi.encodePacked(positionParam.token, positionParam.strike, positionParam.maturity));
    // Check if the position is eligible for reward updates
    if (
      ((positionParam.maturity > block.timestamp) &&
        (positionParam.positionType ==
          (address(this) < positionParam.token ? PositionType.Long0 : PositionType.Long1))) ||
      ((positionParam.maturity <= block.timestamp) && (!_poolRewardGrowths[poolKey].hasMatured))
    ) {
      uint256 rewardHarvested;
      {
        uint256 rewardBefore = rewardToken.balanceOf(address(this));
        // Harvest rewards from the farming contract to the contract ie deposit(0)
        IStableJoeStaking(stablJoeStakingProxy).deposit(0);
        rewardHarvested = rewardToken.balanceOf(address(this)) - rewardBefore;
      }
      {
        (uint256 totalStakedLPToken, ) = IStableJoeStaking(stablJoeStakingProxy).getUserInfo(
          address(this),
          address(rewardToken)
        );
        if (totalStakedLPToken != 0) {
          _rewardGrowth += FullMath.mulDiv(rewardHarvested, 1 << 128, totalStakedLPToken, false);
        }
      }
      // If the pool has matured and not marked as matured yet, perform additional actions
      if ((positionParam.maturity <= block.timestamp) && (!_poolRewardGrowths[poolKey].hasMatured)) {
        _poolRewardGrowths[poolKey].hasMatured = true;
        _poolRewardGrowths[poolKey].rewardGrowth = _rewardGrowth;
        {
          TimeswapV2TokenPosition memory position;
          // Determine the token order for the position
          position.token0 = address(this) < positionParam.token ? address(this) : positionParam.token;
          position.token1 = address(this) > positionParam.token ? address(this) : positionParam.token;
          position.strike = positionParam.strike;
          position.maturity = positionParam.maturity;
          // Determine the position type based on the token order
          position.position = address(this) < positionParam.token
            ? TimeswapV2OptionPosition.Long0
            : TimeswapV2OptionPosition.Long1;
          // Get the long position ID from the TimeswapV2Token contract
          uint256 longPosition = ITimeswapV2Token(timeswapV2Token).positionOf(address(this), position);
          //  Withdraw the long position from the farming contract
          IStableJoeStaking(stablJoeStakingProxy).withdraw(longPosition);
        }
      }
    }
    //     // If the position type matches the token order, update the reward positions
    if (positionParam.positionType == (address(this) < positionParam.token ? PositionType.Long0 : PositionType.Long1)) {
      uint256 rewardGrowth;
      if (positionParam.maturity > block.timestamp) {
        rewardGrowth = _rewardGrowth;
        // Check if the `from` address is the zero address (mint)
        if (from == address(0)) {
          // Check the allowance and approve the farming contract if needed
          uint256 allowance = IERC20(joeToken).allowance(address(this), stablJoeStakingProxy);
          if (allowance < tokenAmount) IERC20(joeToken).approve(stablJoeStakingProxy, type(uint256).max);
          // Deposit the LP tokens to the farming contract
          IStableJoeStaking(stablJoeStakingProxy).deposit(tokenAmount);
          //   console.log("tokenAmount", tokenAmount);
        }
        // Check if the `to` address is the zero address (burn)
        if (to == address(0)) {
          // Withdraw the LP tokens from the farming contract to the contract
          IStableJoeStaking(stablJoeStakingProxy).withdraw(tokenAmount);
        }
      } else {
        rewardGrowth = _poolRewardGrowths[poolKey].rewardGrowth;
      }
      // Update the reward positions for the `from` address
      if (from != address(0)) {
        bytes32 key = keccak256(
          abi.encodePacked(positionParam.token, positionParam.strike, positionParam.maturity, from)
        );
        RewardPosition storage rewardPosition = _rewardPositions[key];
        rewardPosition.rewardAccumulated += FullMath.mulDiv(
          rewardGrowth - rewardPosition.rewardGrowth,
          balanceOf(from, id),
          1 << 128,
          false
        );
        rewardPosition.rewardGrowth = rewardGrowth;
      }
      // Update the reward positions for the `to` address
      if (to != address(0)) {
        bytes32 key = keccak256(
          abi.encodePacked(positionParam.token, positionParam.strike, positionParam.maturity, to)
        );
        RewardPosition storage rewardPosition = _rewardPositions[key];
        rewardPosition.rewardAccumulated += FullMath.mulDiv(
          rewardGrowth - rewardPosition.rewardGrowth,
          balanceOf(to, id),
          1 << 128,
          false
        );
        rewardPosition.rewardGrowth = rewardGrowth;
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {FeesPosition} from "@timeswap-labs/v2-token/contracts/structs/FeesPosition.sol";

/// Remove?
import {FeesAndReturnedDelta, ExcessDelta} from "@timeswap-labs/v2-periphery/contracts/structs/Param.sol";

interface ITimeswapV2Behavior is IERC1155, IERC20 {
    struct Pool {
        uint256 shortId;
        uint256 long0Id;
        uint256 long1Id;
        uint256 liquidityId;
        mapping(address => FeesPosition) feesPositions;
    }

    struct PositionParam {
        address token;
        uint256 strike;
        uint256 maturity;
        PositionType positionType;
    }

    enum PositionType {
        Short,
        Long0,
        Long1,
        Liquidity
    }

    function timeswapV2Token() external view returns (address);

    function timeswapV2LendGivenPrincipal() external view returns (address);

    function timeswapV2CloseLendGivenPosition() external view returns (address);

    function timeswapV2Withdraw() external view returns (address);

    function timeswapV2BorrowGivenPrincipal() external view returns (address);

    function timeswapV2CloseBorrowGivenPosition() external view returns (address);

    function positionId(address token, uint256 strike, uint256 maturity, PositionType positionType)
        external
        pure
        returns (uint256 id);

    function positionParams(uint256 id) external view returns (PositionParam memory positionParam);

    function initialize() external;

    struct LendGivenPrincipalParam {
        address token;
        uint256 strike;
        uint256 maturity;
        address to;
        bool isToken0;
        uint256 tokenAmount;
        uint256 minPositionAmount;
        uint256 deadline;
        bytes erc1155Data;
    }

    function lendGivenPrincipal(LendGivenPrincipalParam calldata param) external returns (uint256 positionAmount);

    struct CloseLendGivenPositionParam {
        address token;
        uint256 strike;
        uint256 maturity;
        address token0To;
        address token1To;
        bool preferToken0;
        uint256 positionAmount;
        uint256 minToken0Amount;
        uint256 minToken1Amount;
        uint256 deadline;
    }

    function closeLendGivenPosition(CloseLendGivenPositionParam calldata param)
        external
        returns (uint256 token0Amount, uint256 token1Amount);

    struct WithdrawParam {
        address token;
        uint256 strike;
        uint256 maturity;
        address to;
        uint256 positionAmount;
        uint256 minToken0Amount;
        uint256 minToken1Amount;
        uint256 deadline;
    }

    function withdraw(WithdrawParam calldata param) external returns (uint256 token0Amount, uint256 token1Amount);

    struct BorrowGivenPrincipalParam {
        address token;
        uint256 strike;
        uint256 maturity;
        address tokenTo;
        address longTo;
        bool isToken0;
        bool isLong0;
        uint256 tokenAmount;
        uint256 maxPositionAmount;
        uint256 deadline;
        bytes erc1155Data;
    }

    function borrowGivenPrincipal(BorrowGivenPrincipalParam calldata param) external returns (uint256 positionAmount);

    struct CloseBorrowGivenPositionParam {
        address token;
        uint256 strike;
        uint256 maturity;
        address to;
        bool isToken0;
        bool isLong0;
        uint256 positionAmount;
        uint256 maxTokenAmount;
        uint256 deadline;
    }

    function closeBorrowGivenPosition(CloseBorrowGivenPositionParam calldata param)
        external
        returns (uint256 tokenAmount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";
import {FeesPositionLibrary, FeesPosition} from "@timeswap-labs/v2-token/contracts/structs/FeesPosition.sol";
import {TimeswapV2LiquidityTokenPosition} from "@timeswap-labs/v2-token/contracts/structs/Position.sol";

import {ITimeswapV2PeripheryNoDexLendGivenPrincipal} from
    "@timeswap-labs/v2-periphery-nodex/contracts/interfaces/ITimeswapV2PeripheryNoDexLendGivenPrincipal.sol";
import {ITimeswapV2PeripheryNoDexCloseLendGivenPosition} from
    "@timeswap-labs/v2-periphery-nodex/contracts/interfaces/ITimeswapV2PeripheryNoDexCloseLendGivenPosition.sol";
import {ITimeswapV2PeripheryNoDexWithdraw} from
    "@timeswap-labs/v2-periphery-nodex/contracts/interfaces/ITimeswapV2PeripheryNoDexWithdraw.sol";
import {ITimeswapV2PeripheryNoDexBorrowGivenPrincipal} from
    "@timeswap-labs/v2-periphery-nodex/contracts/interfaces/ITimeswapV2PeripheryNoDexBorrowGivenPrincipal.sol";
import {ITimeswapV2PeripheryNoDexCloseBorrowGivenPosition} from
    "@timeswap-labs/v2-periphery-nodex/contracts/interfaces/ITimeswapV2PeripheryNoDexCloseBorrowGivenPosition.sol";
import {
    TimeswapV2PeripheryNoDexLendGivenPrincipalParam,
    TimeswapV2PeripheryNoDexCloseLendGivenPositionParam,
    TimeswapV2PeripheryNoDexWithdrawParam,
    TimeswapV2PeripheryNoDexBorrowGivenPrincipalParam,
    TimeswapV2PeripheryNoDexCloseBorrowGivenPositionParam
} from "@timeswap-labs/v2-periphery-nodex/contracts/structs/Param.sol";

import {ITimeswapV2Behavior} from "./interfaces/ITimeswapV2Behavior.sol";

abstract contract TimeswapV2Behavior is ITimeswapV2Behavior, ERC1155, ERC20 {
    using SafeERC20 for IERC20;
    using FeesPositionLibrary for FeesPosition;

    address public immutable override timeswapV2Token;

    address public immutable override timeswapV2LendGivenPrincipal;
    address public immutable override timeswapV2CloseLendGivenPosition;
    address public immutable override timeswapV2Withdraw;
    address public immutable override timeswapV2BorrowGivenPrincipal;
    address public immutable override timeswapV2CloseBorrowGivenPosition;

    mapping(uint256 => PositionParam) private _positionParams;

    /// todo update the constructor
    constructor(
        address _timeswapV2Token,
        address _timeswapV2LendGivenPrincipal,
        address _timeswapV2CloseLendGivenPosition,
        address _timeswapV2Withdraw,
        address _timeswapV2BorrowGivenPrincipal,
        address _timeswapV2CloseBorrowGivenPosition
    ) {
        timeswapV2Token = _timeswapV2Token;
        timeswapV2LendGivenPrincipal = _timeswapV2LendGivenPrincipal;
        timeswapV2CloseLendGivenPosition = _timeswapV2CloseLendGivenPosition;
        timeswapV2Withdraw = _timeswapV2Withdraw;
        timeswapV2BorrowGivenPrincipal = _timeswapV2BorrowGivenPrincipal;
        timeswapV2CloseBorrowGivenPosition = _timeswapV2CloseBorrowGivenPosition;
    }

    function initialize() external override {
        IERC20(address(this)).approve(timeswapV2LendGivenPrincipal, type(uint256).max);
        IERC20(address(this)).approve(timeswapV2BorrowGivenPrincipal, type(uint256).max);
        IERC20(address(this)).approve(timeswapV2CloseBorrowGivenPosition, type(uint256).max);
        IERC1155(timeswapV2Token).setApprovalForAll(timeswapV2CloseLendGivenPosition, true);
        IERC1155(timeswapV2Token).setApprovalForAll(timeswapV2CloseBorrowGivenPosition, true);
        IERC1155(timeswapV2Token).setApprovalForAll(timeswapV2Withdraw, true);
    }

    function positionId(address token, uint256 strike, uint256 maturity, PositionType positionType)
        public
        pure
        override
        returns (uint256 id)
    {
        id = uint256(keccak256(abi.encodePacked(token, strike, maturity, positionType)));
    }

    function positionParams(uint256 id) public view override returns (PositionParam memory positionParam) {
        positionParam = _positionParams[id];
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) external view returns (bytes4) {
        if (msg.sender == timeswapV2Token) return this.onERC1155Received.selector;
        revert();
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        external
        view
        returns (bytes4)
    {
        if (msg.sender == timeswapV2Token) return this.onERC1155BatchReceived.selector;
        revert();
    }

    function lendGivenPrincipal(LendGivenPrincipalParam calldata param)
        external
        override
        returns (uint256 positionAmount)
    {
        if (_check(param.token, param.isToken0)) {
            _mint(address(this), param.tokenAmount);
        } else {
            IERC20(param.token).safeTransferFrom(msg.sender, address(this), param.tokenAmount);
            _approveIfNeeded(param.token, timeswapV2LendGivenPrincipal, param.tokenAmount);
        }

        TimeswapV2PeripheryNoDexLendGivenPrincipalParam memory callParam;
        callParam.token0 = address(this) < param.token ? address(this) : param.token;
        callParam.token1 = address(this) > param.token ? address(this) : param.token;
        callParam.strike = param.strike;
        callParam.maturity = param.maturity;
        callParam.to = address(this);
        callParam.isToken0 = param.isToken0;
        callParam.tokenAmount = param.tokenAmount;
        callParam.minReturnAmount = param.minPositionAmount;
        callParam.deadline = param.deadline;
        positionAmount =
            ITimeswapV2PeripheryNoDexLendGivenPrincipal(timeswapV2LendGivenPrincipal).lendGivenPrincipal(callParam);

        uint256 id = positionId(param.token, param.strike, param.maturity, PositionType.Short);
        PositionParam storage positionParam = _positionParams[id];
        if (positionParam.token == address(0)) {
            positionParam.token = param.token;
            positionParam.strike = param.strike;
            positionParam.maturity = param.maturity;
            positionParam.positionType = PositionType.Short;
        }

        if (_check(param.token, param.isToken0)) _mintRequirement(param.tokenAmount);

        _mint(param.to, id, positionAmount, param.erc1155Data);
    }

    function closeLendGivenPosition(CloseLendGivenPositionParam calldata param)
        external
        override
        returns (uint256 token0Amount, uint256 token1Amount)
    {
        TimeswapV2PeripheryNoDexCloseLendGivenPositionParam memory callParam;
        callParam.token0 = address(this) < param.token ? address(this) : param.token;
        callParam.token1 = address(this) > param.token ? address(this) : param.token;
        callParam.strike = param.strike;
        callParam.maturity = param.maturity;
        callParam.to = address(this);
        callParam.isToken0 = param.preferToken0;
        callParam.positionAmount = param.positionAmount;
        callParam.minToken0Amount = param.minToken0Amount;
        callParam.minToken1Amount = param.minToken1Amount;
        callParam.deadline = param.deadline;
        (token0Amount, token1Amount) = ITimeswapV2PeripheryNoDexCloseLendGivenPosition(timeswapV2CloseLendGivenPosition)
            .closeLendGivenPosition(callParam);

        uint256 id = positionId(param.token, param.strike, param.maturity, PositionType.Short);
        // uint256 id = uint256(keccak256(abi.encodePacked(param.token, param.strike, param.maturity, PositionType.Short)));

        _burn(msg.sender, id, param.positionAmount);

        if (token0Amount != 0) {
            if (address(this) < param.token) _burnRequirement(param.token0To, token0Amount);
            else IERC20(param.token).safeTransfer(param.token0To, token0Amount);
        }

        if (token1Amount != 0) {
            if (address(this) > param.token) _burnRequirement(param.token1To, token1Amount);
            else IERC20(param.token).safeTransfer(param.token1To, token1Amount);
        }
    }

    function withdraw(WithdrawParam calldata param)
        external
        override
        returns (uint256 token0Amount, uint256 token1Amount)
    {
        TimeswapV2PeripheryNoDexWithdrawParam memory callParam;
        callParam.token0 = address(this) < param.token ? address(this) : param.token;
        callParam.token1 = address(this) > param.token ? address(this) : param.token;
        callParam.strike = param.strike;
        callParam.maturity = param.maturity;
        callParam.to = address(this);
        callParam.positionAmount = param.positionAmount;
        callParam.minToken0Amount = param.minToken0Amount;
        callParam.minToken1Amount = param.minToken1Amount;
        callParam.deadline = param.deadline;
        (token0Amount, token1Amount) = ITimeswapV2PeripheryNoDexWithdraw(timeswapV2Withdraw).withdraw(callParam);

        uint256 id = positionId(param.token, param.strike, param.maturity, PositionType.Short);
        // uint256 id = uint256(keccak256(abi.encodePacked(param.token, param.strike, param.maturity, PositionType.Short)));

        _burn(msg.sender, id, param.positionAmount);

        if (token0Amount != 0) {
            if (address(this) < param.token) _burnRequirement(param.to, token0Amount);
            else IERC20(param.token).safeTransfer(param.to, token0Amount);
        }

        if (token1Amount != 0) {
            if (address(this) > param.token) _burnRequirement(param.to, token1Amount);
            else IERC20(param.token).safeTransfer(param.to, token1Amount);
        }
    }

    function borrowGivenPrincipal(BorrowGivenPrincipalParam calldata param)
        external
        override
        returns (uint256 positionAmount)
    {
        if (param.isLong0 == param.isToken0) {
            if (_check(param.token, param.isLong0)) {
                _mint(address(this), param.maxPositionAmount - param.tokenAmount);
            } else {
                IERC20(param.token).safeTransferFrom(
                    msg.sender, address(this), param.maxPositionAmount - param.tokenAmount
                );
                _approveIfNeeded(
                    param.token, timeswapV2BorrowGivenPrincipal, param.maxPositionAmount - param.tokenAmount
                );
            }
        } else {
            if (_check(param.token, param.isLong0)) {
                _mint(address(this), param.maxPositionAmount);
            } else {
                IERC20(param.token).safeTransferFrom(msg.sender, address(this), param.maxPositionAmount);
                _approveIfNeeded(param.token, timeswapV2BorrowGivenPrincipal, param.maxPositionAmount);
            }
        }

        TimeswapV2PeripheryNoDexBorrowGivenPrincipalParam memory callParam;
        callParam.token0 = address(this) < param.token ? address(this) : param.token;
        callParam.token1 = address(this) > param.token ? address(this) : param.token;
        callParam.strike = param.strike;
        callParam.maturity = param.maturity;
        callParam.tokenTo = address(this);
        callParam.longTo = address(this);
        callParam.isToken0 = param.isToken0;
        callParam.isLong0 = param.isLong0;
        callParam.tokenAmount = param.tokenAmount;
        callParam.maxPositionAmount = param.maxPositionAmount;
        callParam.deadline = param.deadline;
        positionAmount = ITimeswapV2PeripheryNoDexBorrowGivenPrincipal(timeswapV2BorrowGivenPrincipal)
            .borrowGivenPrincipal(callParam);

        if (_check(param.token, param.isLong0)) _burn(address(this), param.maxPositionAmount - positionAmount);
        else IERC20(param.token).safeTransfer(msg.sender, param.maxPositionAmount - positionAmount);

        if (param.isLong0 == param.isToken0) {
            if (_check(param.token, param.isLong0)) _mintRequirement(positionAmount - param.tokenAmount);
        } else {
            if (_check(param.token, param.isLong0)) _mintRequirement(positionAmount);

            if (_check(param.token, param.isToken0)) _burnRequirement(param.tokenTo, param.tokenAmount);
            else IERC20(param.token).safeTransfer(param.tokenTo, param.tokenAmount);
        }

        uint256 id = positionId(
            param.token, param.strike, param.maturity, param.isLong0 ? PositionType.Long0 : PositionType.Long1
        );
        // uint256 id = uint256(
        //   keccak256(
        //     abi.encodePacked(
        //       param.token,
        //       param.strike,
        //       param.maturity,
        //       param.isLong0 ? PositionType.Long0 : PositionType.Long1
        //     )
        //   )
        // );

        PositionParam storage positionParam = _positionParams[id];
        if (positionParam.token == address(0)) {
            positionParam.token = param.token;
            positionParam.strike = param.strike;
            positionParam.maturity = param.maturity;
            positionParam.positionType = param.isLong0 ? PositionType.Long0 : PositionType.Long1;
        }

        _mint(param.longTo, id, positionAmount, param.erc1155Data);
    }

    function closeBorrowGivenPosition(CloseBorrowGivenPositionParam calldata param)
        external
        override
        returns (uint256 tokenAmount)
    {
        if (param.isLong0 != param.isToken0) {
            if (_check(param.token, param.isToken0)) {
                _mint(address(this), param.maxTokenAmount);
            } else {
                IERC20(param.token).safeTransferFrom(msg.sender, address(this), param.maxTokenAmount);
                _approveIfNeeded(param.token, timeswapV2CloseBorrowGivenPosition, param.maxTokenAmount);
            }
        }

        TimeswapV2PeripheryNoDexCloseBorrowGivenPositionParam memory callParam;
        callParam.token0 = address(this) < param.token ? address(this) : param.token;
        callParam.token1 = address(this) > param.token ? address(this) : param.token;
        callParam.strike = param.strike;
        callParam.maturity = param.maturity;
        callParam.to = address(this);
        callParam.isToken0 = param.isToken0;
        callParam.isLong0 = param.isLong0;
        callParam.positionAmount = param.positionAmount;
        callParam.maxTokenAmount = param.maxTokenAmount;
        callParam.deadline = param.deadline;
        tokenAmount = ITimeswapV2PeripheryNoDexCloseBorrowGivenPosition(timeswapV2CloseBorrowGivenPosition)
            .closeBorrowGivenPosition(callParam);

        uint256 id = positionId(
            param.token, param.strike, param.maturity, param.isLong0 ? PositionType.Long0 : PositionType.Long1
        );
        // uint256 id = uint256(
        //   keccak256(
        //     abi.encodePacked(
        //       param.token,
        //       param.strike,
        //       param.maturity,
        //       param.isLong0 ? PositionType.Long0 : PositionType.Long1
        //     )
        //   )
        // );

        _burn(msg.sender, id, param.positionAmount);

        if (param.isLong0 == param.isToken0) {
            if (_check(param.token, param.isLong0)) _burnRequirement(param.to, param.positionAmount - tokenAmount);
            else IERC20(param.token).safeTransfer(param.to, param.positionAmount - tokenAmount);
        } else {
            if (_check(param.token, param.isToken0)) _burn(address(this), param.maxTokenAmount - tokenAmount);
            else IERC20(param.token).safeTransfer(msg.sender, param.maxTokenAmount - tokenAmount);

            if (_check(param.token, param.isLong0)) {
                _mintRequirement(tokenAmount);
                _burnRequirement(param.to, param.positionAmount);
            } else {
                IERC20(param.token).safeTransfer(param.to, param.positionAmount);
            }
        }
    }

    function _mintRequirement(uint256 tokenAmount) internal virtual;

    function _burnRequirement(address to, uint256 tokenAmount) internal virtual;

    function _check(address otherToken, bool isZero) private view returns (bool) {
        return (isZero && (address(this) < otherToken)) || (!isZero && (address(this) > otherToken));
    }

    function _approveIfNeeded(address otherToken, address spender, uint256 amount) private {
        uint256 allowance = IERC20(otherToken).allowance(address(this), spender);
        if (allowance < amount) IERC20(otherToken).approve(spender, type(uint256).max);
    }
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

import {TimeswapV2OptionMintCallbackParam} from "../../structs/CallbackParam.sol";

/// @title Callback for ITimeswapV2Option#mint
/// @notice Any contract that calls ITimeswapV2Option#mint must implement this interface.
interface ITimeswapV2OptionMintCallback {
  /// @notice Called to `msg.sender` after initiating a mint from ITimeswapV2Option#mint.
  /// @dev In the implementation, you must transfer token0 and token1 for the mint transaction.
  /// The caller of this method must be checked to be a Timeswap V2 Option pair deployed by the canonical Timeswap V2 Factory.
  /// @dev The long0 positions, long1 positions, and/or short positions will already minted to the recipients.
  /// @param param The parameter of the callback.
  /// @return data The bytes code returned from the callback.
  function timeswapV2OptionMintCallback(
    TimeswapV2OptionMintCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionSwapCallbackParam} from "../../structs/CallbackParam.sol";

/// @title Callback for ITimeswapV2Option#swap
/// @notice Any contract that calls ITimeswapV2Option#swap must implement this interface.
interface ITimeswapV2OptionSwapCallback {
  /// @notice Called to `msg.sender` after initiating a swap from ITimeswapV2Option#swap.
  /// @dev In the implementation, you must transfer token0 for the swap transaction.
  /// The caller of this method must be checked to be a Timeswap V2 Option pair deployed by the canonical Timeswap V2 Factory.
  /// @dev The long0 positions or long1 positions will already minted to the recipients.
  /// @param param The param of the swap callback.
  /// @return data The bytes code returned from the callback.
  function timeswapV2OptionSwapCallback(
    TimeswapV2OptionSwapCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev Parameter for the mint callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0AndLong0Amount The token0 amount to be deposited and the long0 amount minted.
/// @param token1AndLong1Amount The token1 amount to be deposited and the long1 amount minted.
/// @param shortAmount The short amount minted.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionMintCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev Parameter for the burn callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0AndLong0Amount The token0 amount to be withdrawn and the long0 amount burnt.
/// @param token1AndLong1Amount The token1 amount to be withdrawn and the long1 amount burnt.
/// @param shortAmount The short amount burnt.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionBurnCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev Parameter for the swap callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param isLong0ToLong1 True when swapping long0 for long1. False when swapping long1 for long0.
/// @param token0AndLong0Amount If isLong0ToLong1 is true, the amount of long0 burnt and token0 to be withdrawn.
/// If isLong0ToLong1 is false, the amount of long0 minted and token0 to be deposited.
/// @param token1AndLong1Amount If isLong0ToLong1 is true, the amount of long1 withdrawn and token0 to be deposited.
/// If isLong0ToLong1 is false, the amount of long1 burnt and token1 to be withdrawn.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionSwapCallbackParam {
  uint256 strike;
  uint256 maturity;
  bool isLong0ToLong1;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  bytes data;
}

/// @dev Parameter for the collect callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0Amount The token0 amount to be withdrawn.
/// @param token1Amount The token1 amount to be withdrawn.
/// @param shortAmount The short amount burnt.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionCollectCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 shortAmount;
  bytes data;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

  error MulticallFailed(string revertString);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title NativePayments interface
/// @notice Functions to ease payments of native tokens
interface INativePayments {
  /// @notice Refunds any Native Token balance held by this contract to the `msg.sender`
  function refundNatives() external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title NativeWithdraws interface

interface INativeWithdraws {
  /// @notice Unwraps the contract's Wrapped Native token balance and sends it to recipient as Native token.
  /// @dev The amountMinimum parameter prevents malicious contracts from stealing Wrapped Native from users.
  /// @param amountMinimum The minimum amount of Wrapped Native to unwrap
  /// @param recipient The address receiving Native token
  function unwrapWrappedNatives(uint256 amountMinimum, address recipient) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2PeripheryBorrowGivenPrincipal} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryBorrowGivenPrincipal.sol";

import {TimeswapV2PeripheryNoDexBorrowGivenPrincipalParam} from "../structs/Param.sol";

import {INativeWithdraws} from "./INativeWithdraws.sol";
import {INativePayments} from "./INativePayments.sol";
import {IMulticall} from "./IMulticall.sol";

/// @title An interface for TS-V2 Periphery No Dex Borrow Given Pricipal.
interface ITimeswapV2PeripheryNoDexBorrowGivenPrincipal is
  ITimeswapV2PeripheryBorrowGivenPrincipal,
  INativeWithdraws,
  INativePayments,
  IMulticall
{
  event BorrowGivenPrincipal(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
    address from,
    address tokenTo,
    address longTo,
    bool isToken0,
    bool isLong0,
    uint256 tokenAmount,
    uint256 positionAmount
  );

  error MaxPositionReached(uint256 positionAmount, uint256 maxPositionAmount);

  /// @dev The borrow given principal function.
  /// @param param Borrow given principal param.
  /// @return positionAmount
  function borrowGivenPrincipal(
    TimeswapV2PeripheryNoDexBorrowGivenPrincipalParam calldata param
  ) external payable returns (uint256 positionAmount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2PeripheryCloseBorrowGivenPosition} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryCloseBorrowGivenPosition.sol";

import {INativeWithdraws} from "./INativeWithdraws.sol";
import {INativePayments} from "./INativePayments.sol";
import {IMulticall} from "./IMulticall.sol";

import {TimeswapV2PeripheryNoDexCloseBorrowGivenPositionParam} from "../structs/Param.sol";

/// @title An interface for TS-v2 Periphery No Dex Close Borrow Given Position.
interface ITimeswapV2PeripheryNoDexCloseBorrowGivenPosition is
  ITimeswapV2PeripheryCloseBorrowGivenPosition,
  INativeWithdraws,
  INativePayments,
  IMulticall
{
  event CloseBorrowGivenPosition(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
    address from,
    address to,
    bool isToken0,
    bool isLong0,
    uint256 tokenAmount,
    uint256 positionAmount
  );

  error MaxTokenReached(uint256 tokenAmount, uint256 maxTokenAmount);

  /// @dev The close borrow given position function.
  /// @param param Close borrow given position param.
  /// @return tokenAmount
  function closeBorrowGivenPosition(
    TimeswapV2PeripheryNoDexCloseBorrowGivenPositionParam calldata param
  ) external payable returns (uint256 tokenAmount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2PeripheryCloseLendGivenPosition} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryCloseLendGivenPosition.sol";

import {INativeWithdraws} from "./INativeWithdraws.sol";
import {IMulticall} from "./IMulticall.sol";

import {TimeswapV2PeripheryNoDexCloseLendGivenPositionParam} from "../structs/Param.sol";

/// @title An interface for TS-V2 Periphery No Dex Close Lend Given Position.
interface ITimeswapV2PeripheryNoDexCloseLendGivenPosition is
  ITimeswapV2PeripheryCloseLendGivenPosition,
  INativeWithdraws,
  IMulticall
{
  event CloseLendGivenPosition(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
    address from,
    address to,
    uint256 token0Amount,
    uint256 token1Amount,
    uint256 positionAmount
  );

  error MinTokenReached(uint256 tokenAmount, uint256 minTokenAmount);

  /// @dev The close lend given position function.
  /// @param param Close lend given position param.
  /// @return token0Amount
  /// @return token1Amount
  function closeLendGivenPosition(
    TimeswapV2PeripheryNoDexCloseLendGivenPositionParam calldata param
  ) external returns (uint256 token0Amount, uint256 token1Amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2PeripheryLendGivenPrincipal} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryLendGivenPrincipal.sol";

import {TimeswapV2PeripheryNoDexLendGivenPrincipalParam} from "../structs/Param.sol";

import {INativePayments} from "./INativePayments.sol";
import {IMulticall} from "./IMulticall.sol";

/// @title An interface for TS-V2 Periphery No Dex Lend Given Principal.
interface ITimeswapV2PeripheryNoDexLendGivenPrincipal is
  ITimeswapV2PeripheryLendGivenPrincipal,
  INativePayments,
  IMulticall
{
  event LendGivenPrincipal(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
    address from,
    address to,
    bool isToken0,
    uint256 tokenAmount,
    uint256 positionAmount
  );

  error MinPositionReached(uint256 positionAmount, uint256 minReturnAmount);

  /// @dev The lend given principal function.
  /// @param param Lend given principal param.
  /// @return positionAmount
  function lendGivenPrincipal(
    TimeswapV2PeripheryNoDexLendGivenPrincipalParam calldata param
  ) external payable returns (uint256 positionAmount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2PeripheryWithdraw} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryWithdraw.sol";

import {INativeWithdraws} from "./INativeWithdraws.sol";
import {IMulticall} from "./IMulticall.sol";

import {TimeswapV2PeripheryNoDexWithdrawParam} from "../structs/Param.sol";

/// @title An interface for TS-V2 Periphery No Dex Withdraw.
interface ITimeswapV2PeripheryNoDexWithdraw is ITimeswapV2PeripheryWithdraw, INativeWithdraws, IMulticall {
  event Withdraw(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
    address to,
    uint256 token0Amount,
    uint256 token1Amount,
    uint256 positionAmount
  );

  error MinTokenReached(uint256 tokenAmount, uint256 minTokenAmount);

  /// @dev The withdraw function.
  /// @param param Withdraw param.
  /// @return token0Amount
  /// @return token1Amount
  function withdraw(
    TimeswapV2PeripheryNoDexWithdrawParam calldata param
  ) external returns (uint256 token0Amount, uint256 token1Amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

struct TimeswapV2PeripheryNoDexAddLiquidityGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address liquidityTo;
  bool isToken0;
  uint256 tokenAmount;
  uint160 minLiquidityAmount;
  uint160 minSqrtInterestRate;
  uint160 maxSqrtInterestRate;
  uint256 deadline;
  bytes erc1155Data;
}

struct TimeswapV2PeripheryNoDexRemoveLiquidityGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  bool isToken0;
  uint160 liquidityAmount;
  uint256 long0FeesRequested;
  uint256 long1FeesRequested;
  uint256 shortFeesRequested;
  uint256 shortReturnedRequested;
  uint256 excessLong0Amount;
  uint256 excessLong1Amount;
  uint256 excessShortAmount;
  uint256 minToken0Amount;
  uint256 minToken1Amount;
  uint160 minSqrtInterestRate;
  uint160 maxSqrtInterestRate;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexCollectParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  uint256 shortFeesRequested;
  uint256 shortReturnedRequested;
  uint256 excessShortAmount;
  uint256 minToken0Amount;
  uint256 minToken1Amount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexLendGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  uint256 tokenAmount;
  uint256 minReturnAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexBorrowGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isToken0;
  bool isLong0;
  uint256 tokenAmount;
  uint256 maxPositionAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexBorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isToken0;
  bool isLong0;
  uint256 positionAmount;
  uint256 minTokenAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexCloseBorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  bool isLong0;
  uint256 positionAmount;
  uint256 maxTokenAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexCloseLendGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  uint256 positionAmount;
  uint256 minToken0Amount;
  uint256 minToken1Amount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexWithdrawParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint256 positionAmount;
  uint256 minToken0Amount;
  uint256 minToken1Amount;
  uint256 deadline;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2OptionMintCallback} from "@timeswap-labs/v2-option/contracts/interfaces/callbacks/ITimeswapV2OptionMintCallback.sol";
import {ITimeswapV2OptionSwapCallback} from "@timeswap-labs/v2-option/contracts/interfaces/callbacks/ITimeswapV2OptionSwapCallback.sol";

import {ITimeswapV2PoolLeverageCallback} from "@timeswap-labs/v2-pool/contracts/interfaces/callbacks/ITimeswapV2PoolLeverageCallback.sol";

import {ITimeswapV2TokenMintCallback} from "@timeswap-labs/v2-token/contracts/interfaces/callbacks/ITimeswapV2TokenMintCallback.sol";

/// @title An interface for TS-V2 Periphery Borrow Given Position
interface ITimeswapV2PeripheryBorrowGivenPrincipal is
  ITimeswapV2OptionMintCallback,
  ITimeswapV2OptionSwapCallback,
  ITimeswapV2PoolLeverageCallback,
  ITimeswapV2TokenMintCallback
{
  /// @dev Returns the option factory address.
  /// @return optionFactory The option factory address.
  function optionFactory() external returns (address);

  /// @dev Returns the pool factory address.
  /// @return poolFactory The pool factory address.
  function poolFactory() external returns (address);

  /// @dev Return the tokens address
  function tokens() external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import {ITimeswapV2OptionSwapCallback} from "@timeswap-labs/v2-option/contracts/interfaces/callbacks/ITimeswapV2OptionSwapCallback.sol";

import {ITimeswapV2PoolDeleverageCallback} from "@timeswap-labs/v2-pool/contracts/interfaces/callbacks/ITimeswapV2PoolDeleverageCallback.sol";

/// @title An interface for TS-V2 Periphery Close Borrow Given Position
interface ITimeswapV2PeripheryCloseBorrowGivenPosition is
  ITimeswapV2OptionSwapCallback,
  ITimeswapV2PoolDeleverageCallback,
  IERC1155Receiver
{
  /// @dev Returns the option factory address.
  /// @return optionFactory The option factory address.
  function optionFactory() external returns (address);

  /// @dev Returns the pool factory address.
  /// @return poolFactory The pool factory address.
  function poolFactory() external returns (address);

  /// @dev Return the tokens address
  function tokens() external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import {ITimeswapV2PoolLeverageCallback} from "@timeswap-labs/v2-pool/contracts/interfaces/callbacks/ITimeswapV2PoolLeverageCallback.sol";

/// @title An interface for TS-V2 Periphery Close Lend Given Position
interface ITimeswapV2PeripheryCloseLendGivenPosition is ITimeswapV2PoolLeverageCallback, IERC1155Receiver {
  /// @dev Returns the option factory address.
  /// @return optionFactory The option factory address.
  function optionFactory() external returns (address);

  /// @dev Returns the pool factory address.
  /// @return poolFactory The pool factory address.
  function poolFactory() external returns (address);

  /// @dev Return the tokens address
  function tokens() external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2OptionMintCallback} from "@timeswap-labs/v2-option/contracts/interfaces/callbacks/ITimeswapV2OptionMintCallback.sol";

import {ITimeswapV2PoolDeleverageCallback} from "@timeswap-labs/v2-pool/contracts/interfaces/callbacks/ITimeswapV2PoolDeleverageCallback.sol";

import {ITimeswapV2TokenMintCallback} from "@timeswap-labs/v2-token/contracts/interfaces/callbacks/ITimeswapV2TokenMintCallback.sol";

/// @title An interface for TS-V2 Periphery Lend Given Principal
interface ITimeswapV2PeripheryLendGivenPrincipal is
  ITimeswapV2OptionMintCallback,
  ITimeswapV2PoolDeleverageCallback,
  ITimeswapV2TokenMintCallback
{
  /// @dev Returns the option factory address.
  /// @return optionFactory The option factory address.
  function optionFactory() external returns (address);

  /// @dev Returns the pool factory address.
  /// @return poolFactory The pool factory address.
  function poolFactory() external returns (address);

  /// @dev Return the tokens address
  function tokens() external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title An interface for TS-V2 Periphery Withdraw
interface ITimeswapV2PeripheryWithdraw is IERC1155Receiver {
  /// @dev Returns the option factory address.
  /// @return optionFactory The option factory address.
  function optionFactory() external returns (address);

  /// @dev Return the tokens address
  function tokens() external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The parameter for calling the collect protocol fees function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param excessLong0To The receiver of any excess long0 ERC1155 tokens.
/// @param excessLong1To The receiver of any excess long1 ERC1155 tokens.
/// @param excessShortTo The receiver of any excess short ERC1155 tokens.
/// @param long0Requested The maximum amount of long0 fees.
/// @param long1Requested The maximum amount of long1 fees.
/// @param shortRequested The maximum amount of short fees.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryCollectProtocolFeesParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  address excessLong0To;
  address excessLong1To;
  address excessShortTo;
  uint256 long0Requested;
  uint256 long1Requested;
  uint256 shortRequested;
  bytes data;
}

/// @dev The parameter for calling the add liquidity function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param liquidityTo The receiver of the liquidity position ERC1155 tokens.
/// @param token0Amount The amount of token0 ERC20 tokens to deposit.
/// @param token1Amount The amount of token1 ERC20 tokens to deposit.
/// @param data The bytes data passed to callback.
/// @param erc1155Data The bytes data passed to the receiver of liquidity position ERC1155 tokens.
struct TimeswapV2PeripheryAddLiquidityGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address liquidityTo;
  uint256 token0Amount;
  uint256 token1Amount;
  bytes data;
  bytes erc1155Data;
}

/// @dev The parameter for calling the remove liquidity function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param liquidityAmount The amount of liquidity ERC1155 tokens to burn.
/// @param long0FeesRequested The amount of long0 fees to withdraw.
/// @param long1FeesRequested The amount of long1 fees to withdraw.
/// @param shortFeesRequested The amount of short fees to withdraw.
/// @param shortReturnedRequested The amount of short returned to withdraw.
/// @param excessLong0Amount The amount of long0 ERC1155 tokens to include in matching long and short positions.
/// @param excessLong1Amount The amount of long1 ERC1155 tokens to include in matching long and short positions.
/// @param excessShortAmount The amount of short ERC1155 tokens to include in matching long and short positions.
struct TimeswapV2PeripheryRemoveLiquidityGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint160 liquidityAmount;
  uint256 long0FeesRequested;
  uint256 long1FeesRequested;
  uint256 shortFeesRequested;
  uint256 shortReturnedRequested;
  uint256 excessLong0Amount;
  uint256 excessLong1Amount;
  uint256 excessShortAmount;
  bytes data;
}

/// @dev A struct describing how much fees and short returned are withdrawn from the pool.
/// @param long0Fees The number of long0 fees withdrwan from the pool.
/// @param long1Fees The number of long1 fees withdrwan from the pool.
/// @param shortFees The number of short fees withdrwan from the pool.
/// @param shortReturned The number of short returned withdrwan from the pool.
struct FeesAndReturnedDelta {
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  uint256 shortReturned;
}

/// @dev A struct describing how much long and short position are removed or added.
/// @param isRemoveLong0 True if long0 excess is removed from the user.
/// @param isRemoveLong1 True if long1 excess is removed from the user.
/// @param isRemoveShort True if short excess is removed from the user.
/// @param long0Amount The number of excess long0 is removed or added.
/// @param long1Amount The number of excess long1 is removed or added.
/// @param shortAmount The number of excess short is removed or added.
struct ExcessDelta {
  bool isRemoveLong0;
  bool isRemoveLong1;
  bool isRemoveShort;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
}

/// @dev The parameter for calling the collect function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param shortFeesRequested The amount of short fees to withdraw.
/// @param shortReturnedRequested The amount of short returned to withdraw.
/// @param excessShortAmount The amount of short ERC1155 tokens to burn.
struct TimeswapV2PeripheryCollectParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint256 shortFeesRequested;
  uint256 shortReturnedRequested;
  uint256 excessShortAmount;
}

/// @dev The parameter for calling the lend given principal function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param to The receiver of short position.
/// @param token0Amount The amount of token0 ERC20 tokens to deposit.
/// @param token1Amount The amount of token1 ERC20 tokens to deposit.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryLendGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint256 token0Amount;
  uint256 token1Amount;
  bytes data;
}

/// @dev The parameter for calling the close borrow given position function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param to The receiver of the ERC20 tokens.
/// @param isLong0 True if the caller wants to close long0 positions, false if the caller wants to close long1 positions.
/// @param positionAmount The amount of chosen long positions to close.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryCloseBorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isLong0;
  uint256 positionAmount;
  bytes data;
}

/// @dev The parameter for calling the borrow given principal function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param tokenTo The receiver of the ERC20 tokens.
/// @param longTo The receiver of the long ERC1155 positions.
/// @param isLong0 True if the caller wants to receive long0 positions, false if the caller wants to receive long1 positions.
/// @param token0Amount The amount of token0 ERC20 to borrow.
/// @param token1Amount The amount of token1 ERC20 to borrow.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryBorrowGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0;
  uint256 token0Amount;
  uint256 token1Amount;
  bytes data;
}

/// @dev The parameter for calling the borrow given position function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param tokenTo The receiver of the ERC20 tokens.
/// @param longTo The receiver of the long ERC1155 positions.
/// @param isLong0 True if the caller wants to receive long0 positions, false if the caller wants to receive long1 positions.
/// @param positionAmount The amount of long position to receive.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryBorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0;
  uint256 positionAmount;
  bytes data;
}

/// @dev The parameter for calling the close lend given position function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param positionAmount The amount of long position to receive.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryCloseLendGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint256 positionAmount;
  bytes data;
}

/// @dev The parameter for calling the rebalance function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param tokenTo The receiver of the ERC20 tokens.
/// @param excessShortTo The receiver of any excess short ERC1155 tokens.
/// @param isLong0ToLong1 True if transforming long0 position to long1 position, false if transforming long1 position to long0 position.
/// @param givenLong0 True if the amount is in long0 position, false if the amount is in long1 position.
/// @param tokenAmount The amount of token amount given isLong0ToLong1 and givenLong0.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryRebalanceParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address excessShortTo;
  bool isLong0ToLong1;
  bool givenLong0;
  uint256 tokenAmount;
  bytes data;
}

/// @dev The parameter for calling the redeem function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param token0AndLong0Amount The amount of token0 to receive and long0 to burn.
/// @param token1AndLong1Amount The amount of token1 to receive and long1 to burn.
struct TimeswapV2PeripheryRedeemParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
}

/// @dev The parameter for calling the transform function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param tokenTo The receiver of the ERC20 tokens.
/// @param longTo The receiver of the ERC1155 long positions.
/// @param isLong0ToLong1 True if transforming long0 position to long1 position, false if transforming long1 position to long0 position.
/// @param positionAmount The amount of long amount given isLong0ToLong1 and givenLong0.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryTransformParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0ToLong1;
  uint256 positionAmount;
  bytes data;
}

/// @dev The parameter for calling the withdraw function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param positionAmount The amount of short ERC1155 tokens to burn.
struct TimeswapV2PeripheryWithdrawParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint256 positionAmount;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PoolDeleverageChoiceCallbackParam, TimeswapV2PoolDeleverageCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the deleverage function.
interface ITimeswapV2PoolDeleverageCallback {
  /// @dev Returns the amount of long0 position and long1 positions chosen to be deposited to the pool.
  /// @notice The StrikeConversion.combine of long0 position and long1 position must be greater than or equal to long amount.
  /// @dev The short positions will already be minted to the recipient.
  /// @return long0Amount Amount of long0 position to be deposited.
  /// @return long1Amount Amount of long1 position to be deposited.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolDeleverageChoiceCallback(
    TimeswapV2PoolDeleverageChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);

  /// @dev Require the transfer of long0 position and long1 position into the pool.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolDeleverageCallback(
    TimeswapV2PoolDeleverageCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PoolLeverageChoiceCallbackParam, TimeswapV2PoolLeverageCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the leverage function.
interface ITimeswapV2PoolLeverageCallback {
  /// @dev Returns the amount of long0 position and long1 positions chosen to be withdrawn.
  /// @notice The StrikeConversion.combine of long0 position and long1 position must be less than or equal to long amount.
  /// @dev The long0 positions and long1 positions will already be minted to the recipients.
  /// @return long0Amount Amount of long0 position to be withdrawn.
  /// @return long1Amount Amount of long1 position to be withdrawn.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolLeverageChoiceCallback(
    TimeswapV2PoolLeverageChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);

  /// @dev Require the transfer of short position into the pool.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolLeverageCallback(
    TimeswapV2PoolLeverageCallbackParam calldata param
  ) external returns (bytes memory data);
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

/// @dev The parameters for the add fees callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Fees The amount of long0 position required by the pool from msg.sender.
/// @param long1Fees The amount of long1 position required by the pool from msg.sender.
/// @param shortFees The amount of short position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolAddFeesCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  bytes data;
}

/// @dev The parameters for the mint choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param longAmount The amount of long position in base denomination required by the pool from msg.sender.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param liquidityAmount The amount of liquidity position minted.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolMintChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 longAmount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the mint callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position required by the pool from msg.sender.
/// @param long1Amount The amount of long1 position required by the pool from msg.sender.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param liquidityAmount The amount of liquidity position minted.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolMintCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the burn choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Balance The amount of long0 position that can be withdrawn from the pool.
/// @param long1Balance The amount of long1 position that can be withdrawn from the pool.
/// @param longAmount The amount of long position in base denomination that will be withdrawn.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param liquidityAmount The amount of liquidity position burnt.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolBurnChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Balance;
  uint256 long1Balance;
  uint256 longAmount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the burn callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position that will be withdrawn.
/// @param long1Amount The amount of long1 position that will be withdrawn.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param liquidityAmount The amount of liquidity position burnt.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolBurnCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the deleverage choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position required by the pool from msg.sender.
/// @param long1Amount The amount of long1 position required by the pool from msg.sender.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolDeleverageChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 longAmount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the deleverage callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param longAmount The amount of long position in base denomination required by the pool from msg.sender.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolDeleverageCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the leverage choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Balance The amount of long0 position that can be withdrawn from the pool.
/// @param long1Balance The amount of long1 position that can be withdrawn from the pool.
/// @param longAmount The amount of long position in base denomination that will be withdrawn.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolLeverageChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Balance;
  uint256 long1Balance;
  uint256 longAmount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the leverage choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position that can be withdrawn.
/// @param long1Amount The amount of long1 position that can be withdrawn.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolLeverageCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the rebalance callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param isLong0ToLong1 Long0ToLong1 when true. Long1ToLong0 when false.
/// @param long0Amount When Long0ToLong1, the amount of long0 position required by the pool from msg.sender.
/// When Long1ToLong0, the amount of long0 position that can be withdrawn.
/// @param long1Amount When Long0ToLong1, the amount of long1 position that can be withdrawn.
/// When Long1ToLong0, the amount of long1 position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolRebalanceCallbackParam {
  uint256 strike;
  uint256 maturity;
  bool isLong0ToLong1;
  uint256 long0Amount;
  uint256 long1Amount;
  bytes data;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2TokenMintCallbackParam} from "../../structs/CallbackParam.sol";

interface ITimeswapV2TokenMintCallback {
  /// @dev Callback for `ITimeswapV2Token.mint`
  function timeswapV2TokenMintCallback(
    TimeswapV2TokenMintCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {TimeswapV2TokenPosition} from "../structs/Position.sol";
import {TimeswapV2TokenMintParam, TimeswapV2TokenBurnParam} from "../structs/Param.sol";

/// @title An interface for TS-V2 token system
/// @notice This interface is used to interact with TS-V2 positions
interface ITimeswapV2Token is IERC1155 {
  /// @dev Returns the factory address that deployed this contract.
  function optionFactory() external view returns (address);

  /// @dev Returns the position Balance of the owner
  /// @param owner The owner of the token
  /// @param position type of option position (long0, long1, short)
  function positionOf(address owner, TimeswapV2TokenPosition calldata position) external view returns (uint256 amount);

  /// @dev Transfers position token TimeswapV2Token from `from` to `to`
  /// @param from The address to transfer position token from
  /// @param to The address to transfer position token to
  /// @param position The TimeswapV2Token Position to transfer
  /// @param amount The amount of TimeswapV2Token Position to transfer
  function transferTokenPositionFrom(
    address from,
    address to,
    TimeswapV2TokenPosition calldata position,
    uint256 amount
  ) external;

  /// @dev mints TimeswapV2Token as per postion and amount
  /// @param param The TimeswapV2TokenMintParam
  /// @return data Arbitrary data
  function mint(TimeswapV2TokenMintParam calldata param) external returns (bytes memory data);

  /// @dev burns TimeswapV2Token as per postion and amount
  /// @param param The TimeswapV2TokenBurnParam
  function burn(TimeswapV2TokenBurnParam calldata param) external returns (bytes memory data);
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
/// @param data data
struct TimeswapV2LiquidityTokenCollectCallbackParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
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