// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
}

//    SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../interfaces/IAggregationExecutor.sol";

enum FeeType {
    BATCH_SWAP,
    BATCH_SWAP_LP,
    BATCH_TRANSFER
}

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}

struct LpSwapDetails {
    address router;
    address token;
    uint256 amount;
    bytes permit;
    address[] tokenAToPath;
    address[] tokenBToPath;
}

struct WNativeSwapDetails {
    address router;
    uint256 sizeBps; // weth %
    uint256 minReturnAmount;
    address[] nativeToOutputPath;
}

// erc + native
struct SwapDetails {
    IAggregationExecutor executor;
    SwapDescription desc;
    bytes routeData;
    bytes permit;
}

// for direct swap using uniswap v2 forks
// even for wNative refund is in native
// even if dstToken is wNative, native token is given
struct UnoSwapDetails {
    address router;
    uint256 amount;
    uint256 minReturnAmount;
    address[] path;
    bytes permit;
}

struct OutputLp {
    address router;
    address lpToken;
    uint256 minReturnAmount;
    address[] nativeToToken0;
    address[] nativeToToken1;
}

struct TransferDetails {
    address recipient;
    InputTokenData[] data;
}

struct Token {
    address token;
    uint256 amount;
}

struct InputTokenData {
    IERC20 token;
    uint256 amount;
    bytes permit;
}

// logs swapTokensToTokens unoSwapTokensToTokens
struct SwapInfo {
    IERC20 srcToken;
    IERC20 dstToken;
    uint256 amount;
    uint256 returnAmount;
}

// logs swapLpToTokens
struct LPSwapInfo {
    Token[] lpInput; // srcToken, amount
    Token[] lpOutput; // dstToken, returnAmount
}

// logs batchTransfer
struct TransferInfo {
    address recipient;
    Token[] data;
}

struct Router {
    bool isSupported;
    uint256 fees;
}

struct NftData {
    uint256 discountedFeeBps;
    uint256 expiry;
}

//    SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./SwapHandler.sol";
import "./FeeModule.sol";
import "../interfaces/IAggregator.sol";

contract Aggregator is SwapHandler, IAggregator {
    using SafeERC20 for IERC20;

    constructor(
        uint256[3] memory fees_,
        address[] memory routers_,
        Router[] memory routerDetails_,
        address governor_,
        address aggregationRouter_,
        address wNative_,
        address protocolFeeVault_,
        address feeDiscountNft_
    )
        SwapHandler(routers_, routerDetails_, aggregationRouter_, wNative_)
        FeeModule(fees_, governor_, protocolFeeVault_, feeDiscountNft_)
    {}

    function rescueFunds(
        IERC20 token_,
        address to_,
        uint256 amount_
    ) external onlyGovernance {
        require(to_ != address(0), "DZ001");

        if (_isNative(token_)) {
            _safeNativeTransfer(to_, amount_);
        } else {
            token_.safeTransfer(to_, amount_);
        }

        emit TokensRescued(to_, address(token_), amount_);
    }

    receive() external payable {}
}

//    SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Router, FeeType } from "../common/Types.sol";

import "../utils/Governable.sol";
import "../tokens/DiscountNft.sol";
import "../interfaces/IFeeModule.sol";

abstract contract FeeModule is Governable, IFeeModule {
    address public protocolFeeVault;

    uint256 public nextProjectId;

    DiscountNft public feeDiscountNft;

    mapping(FeeType => uint256) public protocolFeeBps;
    mapping(uint256 => mapping(FeeType => uint256)) public projectFeeBps; // projectId -> FeeBps
    mapping(uint256 => address) public projectFeeVault; // projectId -> fee vault

    uint256 public constant MAX_FEE = 5000; // 5%, max project fee
    uint256 public constant BPS_DENOMINATOR = 10000;

    /* ========= CONSTRUCTOR ========= */

    constructor(
        uint256[3] memory fees_,
        address governor_,
        address protocolFeeVault_,
        address feeDiscountNft_
    ) Governable(governor_) {
        require(protocolFeeVault_ != address(0) && feeDiscountNft_ != address(0), "DZF001");

        protocolFeeVault = protocolFeeVault_;
        feeDiscountNft = DiscountNft(feeDiscountNft_);

        protocolFeeBps[FeeType.BATCH_SWAP] = fees_[0];
        protocolFeeBps[FeeType.BATCH_SWAP_LP] = fees_[1];
        protocolFeeBps[FeeType.BATCH_TRANSFER] = fees_[2];
    }

    /* ========= RESTRICTED ========= */

    function updateProtocolFee(FeeType[] calldata feeTypes_, uint256[] calldata fees_) external onlyGovernance {
        for (uint256 i; i < feeTypes_.length; i++) {
            protocolFeeBps[feeTypes_[i]] = fees_[i];
        }

        emit ProtocolFeeUpdated();
    }

    function updateProtocolFeeVault(address newProtocolFeeVault_) external onlyGovernance {
        require(newProtocolFeeVault_ != address(0), "DZF001");

        protocolFeeVault = newProtocolFeeVault_;

        emit ProtocolFeeVaultUpdated();
    }

    function addProject(uint256[3] calldata fees_, address feeVault_) external onlyGovernance {
        require(feeVault_ != address(0), "DZF001");
        require(fees_[0] <= MAX_FEE && fees_[1] <= MAX_FEE && fees_[2] <= MAX_FEE, "DZF002");

        projectFeeBps[nextProjectId][FeeType.BATCH_SWAP] = fees_[0];
        projectFeeBps[nextProjectId][FeeType.BATCH_SWAP_LP] = fees_[1];
        projectFeeBps[nextProjectId][FeeType.BATCH_TRANSFER] = fees_[2];

        projectFeeVault[nextProjectId] = feeVault_;

        emit ProjectAdded(nextProjectId++);
    }

    // make fee vault 0
    function disableProject(uint256 projectId_) external onlyGovernance {
        require(projectId_ < nextProjectId, "DZF003");
        require(projectFeeVault[projectId_] != address(0), "DZF004");

        projectFeeVault[projectId_] = address(0);

        emit ProjectStatusDisabled(projectId_);
    }

    function updateProjectFee(
        uint256 projectId_,
        FeeType[] memory feeTypes_,
        uint256[] memory fees_
    ) external onlyGovernance {
        require(projectId_ < nextProjectId, "DZF003");

        for (uint256 i; i < feeTypes_.length; i++) {
            projectFeeBps[projectId_][feeTypes_[i]] = fees_[i];
        }

        emit ProjectFeeUpdated(projectId_);
    }

    // enable a disabled project
    // update vault
    function updateProjectFeeVault(uint256 projectId_, address feeVault_) external onlyGovernance {
        require(projectId_ < nextProjectId, "DZF003");
        require(feeVault_ != address(0), "DZF001");

        projectFeeVault[projectId_] = feeVault_;

        emit ProjectFeeVaultUpdated(projectId_);
    }

    /* ========= internal ========= */

    function _getFeeDetail(
        uint256 projectId_,
        uint256 nftId_,
        FeeType feeType_
    )
        internal
        view
        returns (
            uint256, // protocolFeeBps
            uint256, // projectFeeBps
            address // projectFeeVault
        )
    {
        require(projectId_ < nextProjectId && projectFeeVault[projectId_] != address(0), "DZF003");

        uint256 protocolFee = protocolFeeBps[feeType_];
        if (nftId_ == 0 || protocolFee == 0) {
            return (protocolFee, projectFeeBps[projectId_][feeType_], projectFeeVault[projectId_]);
        }

        require(feeDiscountNft.balanceOf(_msgSender(), nftId_) > 0, "DZF005");

        (uint256 discountedFeeBps, uint256 expiry) = feeDiscountNft.discountDetails(nftId_);

        if (block.timestamp < expiry) {
            protocolFee -= ((protocolFee * discountedFeeBps) / BPS_DENOMINATOR);
        }

        // require(block.timestamp < expiry, "Expired");
        // protocolFee -= ((protocolFee * discountedFeeBps) / BPS_DENOMINATOR);

        return (protocolFee, projectFeeBps[projectId_][feeType_], projectFeeVault[projectId_]);
    }

    function _calculateFeeAmount(
        uint256 amount_,
        uint256 protocolFeeBps_,
        uint256 projectFeeBps_
    )
        internal
        pure
        returns (
            uint256, // returnAmount
            uint256, // protocolFee
            uint256 // projectFee
        )
    {
        uint256 protocolFee = (amount_ * protocolFeeBps_) / BPS_DENOMINATOR;
        uint256 projectFee = (amount_ * projectFeeBps_) / BPS_DENOMINATOR;
        return (amount_ - (protocolFee + projectFee), protocolFee, projectFee);
    }
}

//    SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/IAggregationRouterV4.sol";
import "../interfaces/IWNATIVE.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Pair.sol";

import "./FeeModule.sol";
import "../utils/Permitable.sol";
import "../interfaces/ISwapHandler.sol";

import { Router, FeeType, Token, SwapInfo, SwapDescription, SwapDetails, TransferDetails, TransferInfo, LpSwapDetails, WNativeSwapDetails, LPSwapInfo, OutputLp, UnoSwapDetails, InputTokenData } from "../common/Types.sol";

abstract contract SwapHandler is FeeModule, Permitable, ISwapHandler {
    using SafeERC20 for IERC20;

    mapping(address => Router) public routers;

    address public immutable wNative;
    address public immutable AGGREGATION_ROUTER;

    IERC20 private constant _ZERO_ADDRESS = IERC20(address(0));
    IERC20 private constant _ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint256 private constant _PARTIAL_FILL = 1 << 0;

    /* ========= CONSTRUCTOR ========= */

    constructor(
        address[] memory routers_,
        Router[] memory routerDetails_,
        address aggregationRouter_,
        address wNative_
    ) {
        require(wNative_ != address(0) && aggregationRouter_ != address(0), "DZS0015");

        AGGREGATION_ROUTER = aggregationRouter_;
        wNative = wNative_;

        for (uint256 i; i < routers_.length; ++i) {
            address router = routers_[i];
            require(router != address(0), "DZS0016");
            routers[router] = routerDetails_[i];
        }
    }

    /* ========= VIEWS ========= */

    function calculateOptimalSwapAmount(
        uint256 amountA_,
        uint256 amountB_,
        uint256 reserveA_,
        uint256 reserveB_,
        address router_
    ) public view returns (uint256) {
        require(amountA_ * reserveB_ >= amountB_ * reserveA_, "DZS0014");

        uint256 routerFeeBps = routers[router_].fees;
        uint256 a = BPS_DENOMINATOR - routerFeeBps;
        uint256 b = (((BPS_DENOMINATOR * 2) - routerFeeBps)) * reserveA_;
        uint256 _c = (amountA_ * reserveB_) - (amountB_ * reserveA_);
        uint256 c = ((_c * BPS_DENOMINATOR) / (amountB_ + reserveB_)) * reserveA_;

        uint256 d = a * c * 4;
        uint256 e = Math.sqrt((b * b) + d);

        uint256 numerator = e - b;
        uint256 denominator = a * 2;

        return numerator / denominator;
    }

    /* ========= RESTRICTED ========= */

    function updateRouters(address[] calldata routers_, Router[] calldata routerDetails_) external onlyGovernance {
        for (uint256 i; i < routers_.length; ++i) {
            address router = routers_[i];
            require(router != address(0), "DZS0016");
            routers[router] = routerDetails_[i];
        }

        emit RoutersUpdated(routers_, routerDetails_);
    }

    /* ========= PUBLIC ========= */

    // can return both native and wNative
    function swapTokensToTokens(
        SwapDetails[] calldata data_,
        address recipient_,
        uint256 projectId_,
        uint256 nftId_
    ) external payable {
        require(recipient_ != address(0), "DZS001");
        SwapInfo[] memory swapInfo = new SwapInfo[](data_.length);
        (uint256 tempProtocolFeeBps, uint256 tempProjectFeeBps, address projectFeeVault) = _getFeeDetail(
            projectId_,
            nftId_,
            FeeType.BATCH_SWAP
        );

        for (uint256 i; i < data_.length; ++i) {
            SwapDetails memory data = data_[i];

            require(data.desc.dstReceiver == address(0), "DZS002");
            require(data.desc.flags & _PARTIAL_FILL == 0, "DZS003");

            uint256 value;

            if (_isNative(data.desc.srcToken)) {
                value = data.desc.amount;
            } else {
                _transferAndApprove(data.permit, data.desc.srcToken, AGGREGATION_ROUTER, data.desc.amount);
            }

            try
                IAggregationRouterV4(AGGREGATION_ROUTER).swap{ value: value }(data.executor, data.desc, data.routeData)
            returns (uint256 returnAmount, uint256) {
                require(returnAmount >= data.desc.minReturnAmount, "DZS004");

                swapInfo[i] = SwapInfo(data.desc.srcToken, data.desc.dstToken, data.desc.amount, returnAmount);

                _swapTransferDstTokens(
                    data.desc.dstToken,
                    recipient_,
                    projectFeeVault,
                    returnAmount,
                    tempProtocolFeeBps,
                    tempProjectFeeBps
                );
            } catch Error(string memory) {
                swapInfo[i] = SwapInfo(data.desc.srcToken, data.desc.dstToken, data.desc.amount, 0);
                if (_isNative(data.desc.srcToken)) {
                    _safeNativeTransfer(_msgSender(), data.desc.amount);
                } else {
                    data.desc.srcToken.safeApprove(AGGREGATION_ROUTER, 0);
                    data.desc.srcToken.safeTransfer(_msgSender(), data.desc.amount);
                }
            }
        }

        emit TokensSwapped(_msgSender(), recipient_, swapInfo, [tempProtocolFeeBps, tempProjectFeeBps]);
    }

    // can return only native when dest is wNative
    function unoSwapTokensToTokens(
        UnoSwapDetails[] calldata swapData_,
        address recipient_,
        uint256 projectId_,
        uint256 nftId_
    ) external payable {
        require(recipient_ != address(0), "DZS001");
        SwapInfo[] memory swapInfo = new SwapInfo[](swapData_.length);

        (uint256 tempProtocolFeeBps, uint256 tempProjectFeeBps, address projectFeeVault) = _getFeeDetail(
            projectId_,
            nftId_,
            FeeType.BATCH_SWAP
        );

        _nativeDeposit();

        // lp swap
        for (uint256 i; i < swapData_.length; ++i) {
            UnoSwapDetails memory data = swapData_[i];

            IERC20 srcToken = IERC20(data.path[0]);
            IERC20 dstToken = IERC20(data.path[data.path.length - 1]);

            require(!_isNative(dstToken), "DZS008");

            if (_isNative(srcToken)) {
                data.path[0] = wNative;
                IWNATIVE(wNative).approve(data.router, data.amount);
            } else {
                _transferAndApprove(data.permit, srcToken, data.router, data.amount);
            }

            try
                IUniswapV2Router02(data.router).swapExactTokensForTokens(
                    data.amount,
                    data.minReturnAmount,
                    data.path,
                    address(this),
                    block.timestamp + 60
                )
            returns (uint256[] memory amountOuts) {
                uint256 returnAmount = amountOuts[amountOuts.length - 1];

                require(returnAmount >= data.minReturnAmount, "DZS004");

                swapInfo[i] = SwapInfo(srcToken, dstToken, data.amount, returnAmount);

                _unoSwapTransferDstTokens(
                    dstToken,
                    recipient_,
                    projectFeeVault,
                    returnAmount,
                    tempProtocolFeeBps,
                    tempProjectFeeBps
                );
            } catch Error(string memory) {
                swapInfo[i] = SwapInfo(srcToken, dstToken, data.amount, 0);

                if (_isNative(srcToken)) {
                    IWNATIVE(wNative).withdraw(data.amount);
                    _safeNativeTransfer(_msgSender(), data.amount);
                } else {
                    srcToken.safeApprove(data.router, 0);
                    srcToken.safeTransfer(_msgSender(), data.amount);
                }
            }
        }

        emit TokensSwapped(_msgSender(), recipient_, swapInfo, [tempProtocolFeeBps, tempProjectFeeBps]);
    }

    // can return both native and wNative
    function swapLpToTokens(
        LpSwapDetails[] calldata lpSwapDetails_,
        WNativeSwapDetails[] calldata wEthSwapDetails_,
        address recipient_,
        uint256 projectId_,
        uint256 nftId_
    ) external {
        require(recipient_ != address(0), "DZS001");
        require(wEthSwapDetails_.length > 0, "DZS009");

        // as in the final swap all the wNative tokens are considered
        // require(IWNATIVE(wNative).balanceOf(address(this)) == 0, "DZS0010");

        LPSwapInfo memory swapInfo;
        swapInfo.lpInput = new Token[](lpSwapDetails_.length);
        swapInfo.lpOutput = new Token[](wEthSwapDetails_.length + 1);

        (uint256 tempProtocolFeeBps, uint256 tempProjectFeeBps, address projectFeeVault) = _getFeeDetail(
            projectId_,
            nftId_,
            FeeType.BATCH_SWAP_LP
        );

        // swap lp to weth
        swapInfo.lpInput = _swapLpToWNative(lpSwapDetails_);

        // swap weth to tokens
        swapInfo.lpOutput = _swapWNativeToDstTokens(
            wEthSwapDetails_,
            recipient_,
            projectFeeVault,
            IWNATIVE(wNative).balanceOf(address(this)),
            tempProtocolFeeBps,
            tempProjectFeeBps
        );

        emit LpSwapped(_msgSender(), recipient_, swapInfo, [tempProtocolFeeBps, tempProjectFeeBps]);
    }

    function swapTokensToLp(
        SwapDetails[] calldata data_,
        LpSwapDetails[] calldata lpSwapDetails_,
        OutputLp calldata outputLpDetails_,
        address recipient_,
        uint256 projectId_,
        uint256 nftId_
    ) public payable {
        require(recipient_ != address(0), "DZS001");
        require(routers[outputLpDetails_.router].isSupported, "DZS005");

        Token[] memory input = new Token[](data_.length + lpSwapDetails_.length + 1);
        (uint256 tempProtocolFeeBps, uint256 tempProjectFeeBps, address projectFeeVault) = _getFeeDetail(
            projectId_,
            nftId_,
            FeeType.BATCH_SWAP_LP
        );

        address token0 = IUniswapV2Pair(outputLpDetails_.lpToken).token0();
        address token1 = IUniswapV2Pair(outputLpDetails_.lpToken).token1();
        uint256 i;

        // native to wNative
        if (msg.value > 0) {
            IWNATIVE(wNative).deposit{ value: msg.value }();
            input[input.length - 1] = Token(address(0), msg.value);
        }

        // erc to wNative
        for (i; i < data_.length; ++i) {
            SwapDetails memory data = data_[i];
            address srcToken = address(data.desc.srcToken);

            if (srcToken != wNative && srcToken != token0 && srcToken != token1) {
                require(data.desc.dstReceiver == address(0), "DZS002");
                require(data.desc.flags & _PARTIAL_FILL == 0, "DZS003"); // partial fill not allowed
                require(!_isNative(data.desc.srcToken), "DZS0011"); // src cant be native
                require(data.desc.dstToken == IERC20(wNative), "DZS0012");

                _transferAndApprove(data.permit, data.desc.srcToken, AGGREGATION_ROUTER, data.desc.amount);

                (uint256 returnAmount, ) = IAggregationRouterV4(AGGREGATION_ROUTER).swap(
                    data.executor,
                    data.desc,
                    data.routeData
                );

                require(returnAmount > data.desc.minReturnAmount, "DZS004");
            } else {
                _permit(srcToken, data.permit);
                data.desc.srcToken.safeTransferFrom(_msgSender(), address(this), data.desc.amount);
            }

            input[i] = Token(srcToken, data.desc.amount);
        }

        // lp to wNative
        for (uint256 j; j < lpSwapDetails_.length; ++j) {
            LpSwapDetails memory details = lpSwapDetails_[j];
            require(routers[details.router].isSupported, "DZS0013");
            // require(outputLpDetails_.lpToken != details.token, "DZS0014");

            address tokenA = IUniswapV2Pair(details.token).token0();
            address tokenB = IUniswapV2Pair(details.token).token1();

            (uint256 amountA, uint256 amountB) = _removeLiquidity(details, tokenA, tokenB, details.router);

            _swapExactTokensForTokens(
                tokenA,
                amountA,
                details.tokenAToPath,
                tokenA != wNative && tokenA != token0 && tokenA != token1,
                details.router
            );
            _swapExactTokensForTokens(
                tokenB,
                amountB,
                details.tokenBToPath,
                tokenB != wNative && tokenB != token0 && tokenB != token1,
                details.router
            );

            input[i + j] = Token(details.token, details.amount);
        }

        uint256[3] memory returnAmounts = _addOptimalLiquidity(outputLpDetails_, token0, token1);

        require(returnAmounts[0] >= outputLpDetails_.minReturnAmount, "DZS004");

        _transferOutputLP(
            IERC20(outputLpDetails_.lpToken),
            recipient_,
            projectFeeVault,
            returnAmounts[0],
            tempProtocolFeeBps,
            tempProjectFeeBps
        );

        // Transfer dust
        if (returnAmounts[1] > 0) {
            IERC20(token0).safeTransfer(_msgSender(), returnAmounts[1]);
        }
        if (returnAmounts[2] > 0) {
            IERC20(token1).safeTransfer(_msgSender(), returnAmounts[2]);
        }

        emit LiquidityAdded(
            _msgSender(),
            recipient_,
            input,
            outputLpDetails_.lpToken,
            returnAmounts,
            [tempProtocolFeeBps, tempProjectFeeBps]
        );
    }

    function batchTransfer(
        TransferDetails[] calldata data_,
        uint256 projectId_,
        uint256 nftId_
    ) external payable {
        TransferInfo[] memory transferInfo = new TransferInfo[](data_.length);

        (uint256 tempProtocolFeeBps, uint256 tempProjectFeeBps, address projectFeeVault) = _getFeeDetail(
            projectId_,
            nftId_,
            FeeType.BATCH_TRANSFER
        );
        uint256 availableBalance = msg.value;

        for (uint256 i; i < data_.length; ++i) {
            TransferDetails memory details = data_[i];
            require(details.recipient != address(0), "DZS001");
            Token[] memory tokenInfo = new Token[](details.data.length);

            for (uint256 j; j < details.data.length; ++j) {
                InputTokenData memory data = details.data[j];
                (uint256 amountAfterFee, uint256 protocolFee, uint256 projectFee) = _calculateFeeAmount(
                    data.amount,
                    tempProtocolFeeBps,
                    tempProjectFeeBps
                );

                tokenInfo[j] = Token(address(data.token), data.amount);

                if (_isNative(data.token)) {
                    require(availableBalance >= data.amount, "DZS003");
                    availableBalance -= data.amount;
                    _safeNativeTransfer(details.recipient, amountAfterFee);
                    if (protocolFee > 0) _safeNativeTransfer(protocolFeeVault, protocolFee);
                    if (projectFee > 0) _safeNativeTransfer(projectFeeVault, projectFee);
                } else {
                    _permit(address(data.token), data.permit);

                    data.token.safeTransferFrom(_msgSender(), details.recipient, amountAfterFee);
                    if (protocolFee > 0) data.token.safeTransferFrom(_msgSender(), protocolFeeVault, protocolFee);
                    if (projectFee > 0) data.token.safeTransferFrom(_msgSender(), projectFeeVault, projectFee);
                }
            }
            transferInfo[i] = TransferInfo(details.recipient, tokenInfo);
        }

        require(availableBalance == 0, "DZS006");

        emit TokensTransferred(_msgSender(), transferInfo, [tempProtocolFeeBps, tempProjectFeeBps]);
    }

    /* ========= INTERNAL/PRIVATE ========= */

    function _isNative(IERC20 token_) internal pure returns (bool) {
        return (token_ == _ZERO_ADDRESS || token_ == _ETH_ADDRESS);
    }

    function _safeNativeTransfer(address to_, uint256 amount_) internal {
        (bool sent, ) = to_.call{ value: amount_ }(new bytes(0));
        require(sent, "DZS007");
    }

    function _nativeDeposit() private {
        if (msg.value > 0) {
            IWNATIVE(wNative).deposit{ value: msg.value }();
        }
    }

    function _transferAndApprove(
        bytes memory permit_,
        IERC20 srcToken_,
        address router_,
        uint256 amount_
    ) private {
        _permit(address(srcToken_), permit_);
        srcToken_.safeTransferFrom(_msgSender(), address(this), amount_);
        srcToken_.safeApprove(router_, amount_);
    }

    function _swapTransferDstTokens(
        IERC20 token_,
        address recipient_,
        address projectFeeVault,
        uint256 returnAmount,
        uint256 tempProtocolFeeBps,
        uint256 tempProjectFeeBps
    ) private {
        (uint256 amountAfterFee, uint256 protocolFee, uint256 projectFee) = _calculateFeeAmount(
            returnAmount,
            tempProtocolFeeBps,
            tempProjectFeeBps
        );

        if (_isNative(token_)) {
            _safeNativeTransfer(recipient_, amountAfterFee);
            if (protocolFee > 0) _safeNativeTransfer(protocolFeeVault, protocolFee);
            if (projectFee > 0) _safeNativeTransfer(projectFeeVault, projectFee);
        } else {
            token_.safeTransfer(recipient_, amountAfterFee);
            if (protocolFee > 0) token_.safeTransfer(protocolFeeVault, protocolFee);
            if (projectFee > 0) token_.safeTransfer(projectFeeVault, projectFee);
        }
    }

    function _unoSwapTransferDstTokens(
        IERC20 token_,
        address recipient_,
        address projectFeeVault,
        uint256 returnAmount,
        uint256 tempProtocolFeeBps,
        uint256 tempProjectFeeBps
    ) private {
        (uint256 amountAfterFee, uint256 protocolFee, uint256 projectFee) = _calculateFeeAmount(
            returnAmount,
            tempProtocolFeeBps,
            tempProjectFeeBps
        );

        if (address(token_) == wNative) {
            IWNATIVE(wNative).withdraw(returnAmount);
            _safeNativeTransfer(recipient_, amountAfterFee);
            if (protocolFee > 0) _safeNativeTransfer(protocolFeeVault, protocolFee);
            if (projectFee > 0) _safeNativeTransfer(projectFeeVault, projectFee);
        } else {
            token_.safeTransfer(recipient_, amountAfterFee);
            if (protocolFee > 0) token_.safeTransfer(protocolFeeVault, protocolFee);
            if (projectFee > 0) token_.safeTransfer(projectFeeVault, projectFee);
        }
    }

    function _transferOutputLP(
        IERC20 lpToken,
        address recipient_,
        address projectFeeVault,
        uint256 returnAmount,
        uint256 tempProtocolFeeBps,
        uint256 tempProjectFeeBps
    ) private {
        (uint256 amountAfterFee, uint256 protocolFee, uint256 projectFee) = _calculateFeeAmount(
            returnAmount,
            tempProtocolFeeBps,
            tempProjectFeeBps
        );

        lpToken.safeTransfer(recipient_, amountAfterFee);
        if (protocolFee > 0) lpToken.safeTransfer(protocolFeeVault, protocolFee);
        if (projectFee > 0) lpToken.safeTransfer(projectFeeVault, projectFee);
    }

    function _swapWNativeForToken(
        uint256 amount_,
        address[] memory path_,
        address router_
    ) private returns (uint256) {
        IWNATIVE(wNative).approve(router_, amount_);

        uint256[] memory amountOuts = IUniswapV2Router02(router_).swapExactTokensForTokens(
            amount_,
            0,
            path_,
            address(this),
            block.timestamp + 60
        );
        return amountOuts[amountOuts.length - 1];
    }

    function _swapExactTokensForTokens(
        address token_,
        uint256 amount_,
        address[] memory path_,
        bool executeSwap_,
        address router_
    ) private {
        if (executeSwap_) {
            IERC20(token_).approve(router_, amount_);
            IUniswapV2Router02(router_).swapExactTokensForTokens(
                amount_,
                0,
                path_,
                address(this),
                block.timestamp + 60
            );
        }
    }

    //  used in swapLpToTokens
    function _swapLpToWNative(LpSwapDetails[] calldata lpSwapDetails_) internal returns (Token[] memory) {
        Token[] memory swapInfo = new Token[](lpSwapDetails_.length);

        for (uint256 i; i < lpSwapDetails_.length; ++i) {
            LpSwapDetails memory details = lpSwapDetails_[i];
            require(routers[details.router].isSupported, "DZS005");

            address tokenA = IUniswapV2Pair(details.token).token0();
            address tokenB = IUniswapV2Pair(details.token).token1();

            (uint256 amountA, uint256 amountB) = _removeLiquidity(details, tokenA, tokenB, details.router);

            _swapExactTokensForTokens(tokenA, amountA, details.tokenAToPath, tokenA != wNative, details.router);

            _swapExactTokensForTokens(tokenB, amountB, details.tokenBToPath, tokenB != wNative, details.router);

            swapInfo[i] = Token(details.token, details.amount);
        }

        return swapInfo;
    }

    //  used in swapLpToTokens
    function _swapWNativeToDstTokens(
        WNativeSwapDetails[] calldata wEthSwapDetails_,
        address recipient_,
        address projectFeeVault,
        uint256 wNativeBalance,
        uint256 tempProtocolFeeBps,
        uint256 tempProjectFeeBps
    ) private returns (Token[] memory) {
        Token[] memory swapInfo = new Token[](wEthSwapDetails_.length);

        // swap weth to tokens
        // for last swap all the leftOver tokens are considered
        for (uint256 i; i < wEthSwapDetails_.length; ++i) {
            WNativeSwapDetails memory details = wEthSwapDetails_[i];

            uint256 wNativeAmount = i != wEthSwapDetails_.length - 1
                ? (wNativeBalance * details.sizeBps) / BPS_DENOMINATOR
                : IWNATIVE(wNative).balanceOf(address(this));

            if (details.nativeToOutputPath.length == 0) {
                // native

                require(wNativeAmount >= details.minReturnAmount, "DZS004");

                (uint256 amountAfterFee, uint256 protocolFee, uint256 projectFee) = _calculateFeeAmount(
                    wNativeAmount,
                    tempProtocolFeeBps,
                    tempProjectFeeBps
                );

                IWNATIVE(wNative).withdraw(wNativeAmount);
                _safeNativeTransfer(recipient_, amountAfterFee);
                if (protocolFee > 0) _safeNativeTransfer(protocolFeeVault, protocolFee);
                if (projectFee > 0) _safeNativeTransfer(projectFeeVault, projectFee);

                swapInfo[i] = Token(address(0), wNativeAmount);
            } else {
                // wNative and others
                address destToken = details.nativeToOutputPath[details.nativeToOutputPath.length - 1];

                uint256 amountOut = wNativeAmount;

                if (destToken != wNative) {
                    require(routers[details.router].isSupported, "DZS005");
                    amountOut = _swapWNativeForToken(wNativeAmount, details.nativeToOutputPath, details.router);
                }

                require(amountOut >= details.minReturnAmount, "DZS004");

                (uint256 amountAfterFee, uint256 protocolFee, uint256 projectFee) = _calculateFeeAmount(
                    amountOut,
                    tempProtocolFeeBps,
                    tempProjectFeeBps
                );

                IERC20(destToken).safeTransfer(recipient_, amountAfterFee);
                if (protocolFee > 0) IERC20(destToken).safeTransfer(protocolFeeVault, protocolFee);
                if (projectFee > 0) IERC20(destToken).safeTransfer(projectFeeVault, projectFee);

                swapInfo[i] = Token(destToken, amountOut);
            }
        }

        return swapInfo;
    }

    function _removeLiquidity(
        LpSwapDetails memory details_,
        address tokenA_,
        address tokenB_,
        address router_
    ) private returns (uint256 amountA, uint256 amountB) {
        _transferAndApprove(details_.permit, IERC20(details_.token), router_, details_.amount);

        (amountA, amountB) = IUniswapV2Router02(router_).removeLiquidity(
            tokenA_,
            tokenB_,
            details_.amount,
            0,
            0,
            address(this),
            block.timestamp + 60
        );
    }

    function _addOptimalLiquidity(
        OutputLp calldata lpDetails_,
        address tokenA_,
        address tokenB_
    ) private returns (uint256[3] memory) {
        uint256 wNativeBalance = IWNATIVE(wNative).balanceOf(address(this));

        // swap 50-50
        if (wNativeBalance > 0) {
            if (tokenA_ != wNative)
                _swapWNativeForToken(wNativeBalance / 2, lpDetails_.nativeToToken0, lpDetails_.router);

            if (tokenB_ != wNative)
                _swapWNativeForToken(
                    wNativeBalance - (wNativeBalance / 2),
                    lpDetails_.nativeToToken1,
                    lpDetails_.router
                );
        }

        // do optimal swap
        (uint256 amountA, uint256 amountB) = _optimalSwapForAddingLiquidity(
            lpDetails_.lpToken,
            tokenA_,
            tokenB_,
            IERC20(tokenA_).balanceOf(address(this)),
            IERC20(tokenB_).balanceOf(address(this)),
            lpDetails_.router
        );

        IERC20(tokenA_).approve(lpDetails_.router, amountA);
        IERC20(tokenB_).approve(lpDetails_.router, amountB);

        // add liquidity
        (uint256 addedToken0, uint256 addedToken1, uint256 lpAmount) = IUniswapV2Router02(lpDetails_.router)
            .addLiquidity(tokenA_, tokenB_, amountA, amountB, 0, 0, address(this), block.timestamp + 60);

        return ([lpAmount, amountA - addedToken0, amountB - addedToken1]);
    }

    function _optimalSwapForAddingLiquidity(
        address lp,
        address tokenA_,
        address tokenB_,
        uint256 amountA_,
        uint256 amountB_,
        address router_
    ) private returns (uint256, uint256) {
        (uint256 reserveA, uint256 reserveB, ) = IUniswapV2Pair(lp).getReserves();

        if (reserveA * amountB_ == reserveB * amountA_) {
            return (amountA_, amountB_);
        }

        bool reverse = reserveA * amountB_ > reserveB * amountA_;

        uint256 optimalSwapAmount = reverse
            ? calculateOptimalSwapAmount(amountB_, amountA_, reserveB, reserveA, router_)
            : calculateOptimalSwapAmount(amountA_, amountB_, reserveA, reserveB, router_);

        address[] memory path = new address[](2);
        (path[0], path[1]) = reverse ? (tokenB_, tokenA_) : (tokenA_, tokenB_);

        if (optimalSwapAmount > 0) {
            IERC20(path[0]).approve(router_, optimalSwapAmount);

            uint256[] memory amountOuts = IUniswapV2Router02(router_).swapExactTokensForTokens(
                optimalSwapAmount,
                0,
                path,
                address(this),
                block.timestamp + 60
            );

            if (reverse) {
                amountA_ += amountOuts[amountOuts.length - 1];
                amountB_ -= optimalSwapAmount;
            } else {
                amountA_ -= optimalSwapAmount;
                amountB_ += amountOuts[amountOuts.length - 1];
            }
        }

        return (amountA_, amountB_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IAggregationExecutor {
    /// @notice Make calls on `msgSender` with specified data
    function callBytes(address msgSender, bytes calldata data) external payable; // 0x2636f7f8
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./IAggregationExecutor.sol";

import { SwapDescription } from "./../common/Types.sol";

interface IAggregationRouterV4 {
    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 gasLeft);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./ISwapHandler.sol";

interface IAggregator is ISwapHandler {
    /* ========= EVENTS ========= */

    event TokensRescued(address indexed to, address indexed token, uint256 amount);

    /* ========= RESTRICTED ========= */

    function rescueFunds(
        IERC20 token_,
        address to_,
        uint256 amount_
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IDaiLikePermit {
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { NftData } from "./../common/Types.sol";

interface IDiscountNft {
    /* ========= EVENTS ========= */

    event Created(uint256 starringId, uint256 noCreated);
    event MintersApproved(address[] minters, uint256[] ids, uint256[] amounts);
    event MintersRevoked(address[] minters, uint256[] ids);
    event Minted(address[] to, uint256[] ids, uint256[] amounts);
    event BatchMinted(address to, uint256[] ids, uint256[] amounts);

    /* ========= VIEWS ========= */

    function contractURI() external view returns (string memory);

    function tokenURI(uint256 tokenId_) external view returns (string memory);

    /* ========= FUNCTIONS ========= */

    function setBaseURI(string memory newUri_) external;

    function setContractURI(string memory newContractUri_) external;

    function createNfts(NftData[] calldata nftData_) external;

    function approveMinter(
        address[] calldata minters_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_
    ) external;

    function mint(
        address[] calldata to_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_
    ) external;

    function mintBatch(
        address to_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_,
        bytes calldata data_
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { FeeType } from "../common/Types.sol";

interface IFeeModule {
    /* ========= EVENTS ========= */

    event ProtocolFeeVaultUpdated();

    event ProtocolFeeUpdated();

    event ProjectAdded(uint256 indexed id);

    event ProjectStatusDisabled(uint256 indexed id);

    event ProjectFeeUpdated(uint256 indexed id);

    event ProjectFeeVaultUpdated(uint256 indexed id);

    /* ========= RESTRICTED ========= */

    function updateProtocolFee(FeeType[] calldata feeTypes_, uint256[] calldata fees_) external;

    function updateProtocolFeeVault(address newProtocolFeeVault_) external;

    function addProject(uint256[3] calldata fees_, address feeVault_) external;

    function disableProject(uint256 projectId_) external;

    function updateProjectFee(
        uint256 projectId_,
        FeeType[] memory feeTypes_,
        uint256[] memory fees_
    ) external;

    function updateProjectFeeVault(uint256 projectId_, address feeVault_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { SwapInfo, LPSwapInfo, Token, TransferInfo, Router, SwapDetails, UnoSwapDetails, LpSwapDetails, WNativeSwapDetails, OutputLp, TransferDetails } from "../common/Types.sol";

import "./IFeeModule.sol";

interface ISwapHandler is IFeeModule {
    /* ========= EVENTS ========= */

    event RoutersUpdated(address[] routers, Router[] details);

    event TokensSwapped(address indexed sender, address indexed recipient, SwapInfo[] swapInfo, uint256[2] feeBps); // protocolFeeBps, projectFeeBPS

    event LpSwapped(address indexed sender, address indexed recipient, LPSwapInfo swapInfo, uint256[2] feeBps);

    event LiquidityAdded(
        address indexed sender,
        address indexed recipient,
        Token[] inputTokens, // both erc20 and lp
        address outputLp,
        uint256[3] returnAmounts, // outputLP, unspentAmount0, unspentAmount1
        uint256[2] feeBps
    );

    event TokensTransferred(address indexed sender, TransferInfo[] details, uint256[2] feeBps);

    /* ========= VIEWS ========= */

    function calculateOptimalSwapAmount(
        uint256 amountA_,
        uint256 amountB_,
        uint256 reserveA_,
        uint256 reserveB_,
        address router_
    ) external view returns (uint256);

    /* ========= RESTRICTED ========= */

    function updateRouters(address[] calldata routers_, Router[] calldata routerDetails_) external;

    /* ========= PUBLIC ========= */

    function swapTokensToTokens(
        SwapDetails[] calldata data_,
        address recipient_,
        uint256 projectId_,
        uint256 nftId_
    ) external payable;

    function unoSwapTokensToTokens(
        UnoSwapDetails[] calldata swapData_,
        address recipient_,
        uint256 projectId_,
        uint256 nftId_
    ) external payable;

    function swapLpToTokens(
        LpSwapDetails[] calldata lpSwapDetails_,
        WNativeSwapDetails[] calldata wEthSwapDetails_,
        address recipient_,
        uint256 projectId_,
        uint256 nftId_
    ) external;

    function swapTokensToLp(
        SwapDetails[] calldata data_,
        LpSwapDetails[] calldata lpSwapDetails_,
        OutputLp calldata outputLpDetails_,
        address recipient_,
        uint256 projectId_,
        uint256 nftId_
    ) external payable;

    function batchTransfer(
        TransferDetails[] calldata data_,
        uint256 projectId_,
        uint256 nftId_
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IWNATIVE is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

//    SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./../interfaces/IDiscountNft.sol";

import { NftData } from "./../common/Types.sol";

contract DiscountNft is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, IDiscountNft {
    string public contractUri;

    mapping(uint256 => NftData) public discountDetails;
    mapping(address => mapping(uint256 => uint256)) public minters;

    uint256 public nextId = 1;
    uint256 private constant _BPS_MULTIPLIER = 100;

    /* ========= CONSTRUCTOR ========= */

    constructor(string memory baseUri_, string memory contractUri_) ERC1155(baseUri_) {
        contractUri = contractUri_;
    }

    /* ========= VIEWS ========= */

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function tokenURI(uint256 tokenId_) public view returns (string memory) {
        return string(abi.encodePacked(uri(0), Strings.toString(tokenId_), ".json"));
    }

    /* ========= FUNCTIONS ========= */

    function setBaseURI(string memory newUri_) public onlyOwner {
        _setURI(newUri_);
    }

    function setContractURI(string memory newContractUri_) public onlyOwner {
        contractUri = newContractUri_;
    }

    function createNfts(NftData[] calldata nftData_) public onlyOwner {
        uint256 startingId = nextId;

        for (uint256 i; i < nftData_.length; ++i) {
            NftData memory data = nftData_[i];

            require(data.discountedFeeBps > 0 && data.discountedFeeBps <= 100 * _BPS_MULTIPLIER, "DZN002");
            require(data.expiry > block.timestamp, "DZN003");

            discountDetails[nextId++] = data;
        }

        emit Created(startingId, nftData_.length);
    }

    function createAndMint(
        NftData[] calldata nftData_,
        address[] calldata to_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_
    ) public onlyOwner {
        createNfts(nftData_);

        for (uint256 i; i < to_.length; ++i) {
            uint256 id = ids_[i];
            _isValidNft(id);

            _mint(to_[i], id, amounts_[i], "0x");
        }

        emit Minted(to_, ids_, amounts_);
    }

    function approveMinter(
        address[] calldata minters_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_
    ) public onlyOwner {
        for (uint256 i; i < minters_.length; ++i) {
            _isValidNft(ids_[i]);

            minters[minters_[i]][ids_[i]] += amounts_[i];
        }

        emit MintersApproved(minters_, ids_, amounts_);
    }

    function revokeMinter(address[] calldata minters_, uint256[] calldata ids_) public onlyOwner {
        for (uint256 i; i < minters_.length; ++i) {
            _isValidNft(ids_[i]);

            minters[minters_[i]][ids_[i]] = 0;
        }

        emit MintersRevoked(minters_, ids_);
    }

    function mint(
        address[] calldata to_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_
    ) public {
        for (uint256 i; i < to_.length; ++i) {
            uint256 id = ids_[i];
            _isValidNft(id);

            if (_msgSender() != owner()) {
                require(minters[_msgSender()][id] >= amounts_[i], "DZN001");
                minters[_msgSender()][id] -= amounts_[i];
            }

            _mint(to_[i], id, amounts_[i], "0x");
        }

        emit Minted(to_, ids_, amounts_);
    }

    function mintBatch(
        address to_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_,
        bytes calldata data_
    ) public onlyOwner {
        for (uint256 i; i < ids_.length; ++i) {
            _isValidNft(ids_[i]);
        }

        _mintBatch(to_, ids_, amounts_, data_);

        emit BatchMinted(to_, ids_, amounts_);
    }

    /* ========= INTERNAL/PRIVATE ========= */

    function _isValidNft(uint256 id_) private view {
        require(id_ != 0 && id_ < nextId, "DZN004");
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator_,
        address from,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator_, from, to_, ids_, amounts_, data_);
    }
}

//    SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Governable is Context {
    address private _governance;

    event GovernanceChanged(address indexed formerGov, address indexed newGov);

    /**
     * @dev Throws if called by any account other than the governance.
     */
    modifier onlyGovernance() {
        require(governance() == _msgSender(), "DZG001");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial governance.
     */
    constructor(address governance_) {
        require(governance_ != address(0), "DZG002");
        _governance = governance_;
        emit GovernanceChanged(address(0), governance_);
    }

    /**
     * @dev Returns the address of the current governance.
     */
    function governance() public view virtual returns (address) {
        return _governance;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newGov_`).
     * Can only be called by the current governance.
     */
    function changeGovernance(address newGov_) public virtual onlyGovernance {
        require(newGov_ != address(0), "DZG002");
        emit GovernanceChanged(_governance, newGov_);
        _governance = newGov_;
    }
}

//    SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../interfaces/IDaiLikePermit.sol";

abstract contract Permitable {
    function _permit(address token_, bytes memory permit_) internal {
        if (permit_.length > 0) {
            bool success;
            bytes memory result;
            if (permit_.length == 32 * 7) {
                // solhint-disable-next-line avoid-low-level-calls
                (success, result) = token_.call(abi.encodePacked(IERC20Permit.permit.selector, permit_));
            } else if (permit_.length == 32 * 8) {
                // solhint-disable-next-line avoid-low-level-calls
                (success, result) = token_.call(abi.encodePacked(IDaiLikePermit.permit.selector, permit_));
            } else {
                revert("DZP001");
            }
            require(success, "DZP002");
        }
    }
}